import os
import time
import uuid
import structlog
import logging
from datetime import datetime
from pydantic import BaseModel
from pythonjsonlogger import jsonlogger
import fastapi

# LiteLLM for provider-agnostic LLM calls
import litellm

# Configure structured logging
logging.basicConfig(level=logging.INFO)
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter(
    fmt="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logHandler.setFormatter(formatter)
logger = logging.getLogger("llm-proxy")
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Structured logger for metrics
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

metrics_logger = structlog.get_logger("llm-metrics")

# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")
AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY")
AZURE_OPENAI_DEPLOYMENT_NAME = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")
AZURE_OPENAI_API_VERSION = os.getenv("AZURE_OPENAI_API_VERSION", "2024-08-01-preview")

# LLM Provider Configuration
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "azure")

# Configure LiteLLM for Azure OpenAI
if LLM_PROVIDER == "azure":
    # Enable debug mode to see what's happening
    os.environ['LITELLM_LOG'] = 'DEBUG'
    
    # Model mapping for Azure deployments - use the deployment name directly
    model_name = f"azure/{AZURE_OPENAI_DEPLOYMENT_NAME}"
else:
    # For other providers (OpenAI, Anthropic, etc.)
    litellm.api_key = os.getenv("OPENAI_API_KEY")
    model_name = "gpt-4"

# Validation
if not AZURE_OPENAI_ENDPOINT or not AZURE_OPENAI_API_KEY:
    raise RuntimeError(
        "Environment variables AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY must be set "
        "for llm-proxy to start."
    )

logger.info("LLM-Proxy starting", extra={
           "provider": LLM_PROVIDER,
           "endpoint": AZURE_OPENAI_ENDPOINT,
           "deployment": AZURE_OPENAI_DEPLOYMENT_NAME,
           "model": model_name
})

app = fastapi.FastAPI(title="LLM Proxy", description="Multi-Provider LLM Proxy with Analytics")

# Request Models  
class ChatMessage(BaseModel):
    role: str  # "user", "assistant", "system"
    content: str

class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    max_tokens: int = 4096
    temperature: float = 0.7

@app.post("/chat")
async def chat(req: ChatRequest):
    request_id = str(uuid.uuid4())
    start_time = time.time()
    
    # Log request start
    logger.info("LLM request started", extra={
        "request_id": request_id,
        "model": model_name,
        "max_tokens": req.max_tokens,
        "temperature": req.temperature,
        "message_count": len(req.messages)
    })
    
    try:
        # Prepare messages for LiteLLM
        messages = [{"role": msg.role, "content": msg.content} for msg in req.messages]
        
        # Calculate input tokens using LiteLLM (temporarily skip due to error)
        logger.info("Calling token_counter", extra={"request_id": request_id, "model": model_name})
        try:
            input_tokens = litellm.token_counter(model=model_name, messages=messages)
        except Exception as token_error:
            logger.warning("Token counter failed, using estimate", extra={
                "request_id": request_id, 
                "token_error": str(token_error)
            })
            # Simple token estimation fallback
            input_tokens = sum(len(msg["content"].split()) * 1.3 for msg in messages)
        
        # Make LLM call using LiteLLM with explicit Azure parameters
        response = litellm.completion(
            model=model_name,
            messages=messages,
            max_tokens=req.max_tokens,
            temperature=req.temperature,
            # Explicitly pass Azure parameters to ensure LiteLLM uses Azure
            api_key=AZURE_OPENAI_API_KEY,
            api_base=AZURE_OPENAI_ENDPOINT,
            api_version=AZURE_OPENAI_API_VERSION,
        )
        
        # Extract response data
        response_content = response.choices[0].message.content
        output_tokens = response.usage.completion_tokens
        total_tokens = response.usage.total_tokens
        processing_time = time.time() - start_time
        
        # Calculate cost using LiteLLM's built-in cost tracking
        cost = litellm.completion_cost(completion_response=response)
        
        # Energy estimation (simplified)
        energy_consumption = (total_tokens / 1000) * float(os.getenv("ENERGY_PER_1K_TOKENS_KWH", "0.001"))
        
        # Log comprehensive metrics
        metrics_logger.info("llm_request_completed", 
            request_id=request_id,
            model=model_name,
            provider=LLM_PROVIDER,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            total_tokens=total_tokens,
            processing_time_seconds=round(processing_time, 3),
            energy_consumption_kwh=round(energy_consumption, 6),
            cost_usd=round(cost, 4),
            temperature=req.temperature,
            max_tokens=req.max_tokens,
            timestamp=datetime.utcnow().isoformat(),
            status="success"
        )
        
        # Log business metrics
        logger.info("LLM request completed successfully", extra={
            "request_id": request_id,
            "processing_time": round(processing_time, 3),
            "total_tokens": total_tokens,
            "cost": round(cost, 4),
            "energy_kwh": round(energy_consumption, 6)
        })
        
        return {
            "id": response.id,
            "object": response.object,
            "created": response.created,
            "model": response.model,
            "choices": response.choices,
            "usage": response.usage,
            "analytics": {
                "request_id": request_id,
                "processing_time_seconds": round(processing_time, 3),
                "energy_consumption_kwh": round(energy_consumption, 6),
                "cost_usd": round(cost, 4),
                "provider": LLM_PROVIDER
            }
        }
        
    except Exception as e:
        processing_time = time.time() - start_time
        
        # Log error
        logger.error("LLM request failed", extra={
            "request_id": request_id,
            "error": str(e),
            "processing_time": round(processing_time, 3)
        })
        
        metrics_logger.error("llm_request_failed",
            request_id=request_id,
            model=model_name,
            provider=LLM_PROVIDER,
            error=str(e),
            processing_time_seconds=round(processing_time, 3),
            timestamp=datetime.utcnow().isoformat(),
            status="error"
        )
        
        raise fastapi.HTTPException(status_code=500, detail=f"LLM request failed: {str(e)}")

@app.get("/healthz")
async def health() -> dict[str, str]:
    return {"status": "ok", "provider": LLM_PROVIDER, "model": model_name}

@app.get("/providers")
async def get_providers():
    """Get information about supported providers and current configuration"""
    return {
        "current_provider": LLM_PROVIDER,
        "current_model": model_name,
        "supported_providers": {
            "azure": {
                "description": "Azure OpenAI Service",
                "models": ["gpt-4o", "gpt-4", "gpt-35-turbo"],
                "required_env_vars": ["AZURE_OPENAI_ENDPOINT", "AZURE_OPENAI_API_KEY"]
            },
            "openai": {
                "description": "OpenAI API",
                "models": ["gpt-4", "gpt-3.5-turbo", "gpt-4-turbo"],
                "required_env_vars": ["OPENAI_API_KEY"]
            },
            "anthropic": {
                "description": "Anthropic Claude",
                "models": ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"],
                "required_env_vars": ["ANTHROPIC_API_KEY"]
            }
        },
        "configuration": {
            "azure_endpoint": AZURE_OPENAI_ENDPOINT if LLM_PROVIDER == "azure" else None,
            "azure_deployment": AZURE_OPENAI_DEPLOYMENT_NAME if LLM_PROVIDER == "azure" else None
        }
    }
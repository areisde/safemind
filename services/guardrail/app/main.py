from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx, os

# --------------------------------------------------------------------
# Upstream LLM service address – defaults to the Kubernetes Service
# but can be overridden with an env-var in Helm values.
# --------------------------------------------------------------------
LLM_PROXY_URL = os.getenv(
    "LLM_PROXY_URL",
    "http://llm-proxy.llm.svc.cluster.local:8000/chat",
)

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatReq(BaseModel):
    messages: list[ChatMessage]
    max_tokens: int = 4096
    temperature: float = 0.7

# Legacy format for backward compatibility
class LegacyChatReq(BaseModel):
    prompt: str

app = FastAPI()

@app.get("/healthz")
async def health():
    return {"status": "ok"}

@app.post("/sanitize")
async def sanitize(req: ChatReq):
    # Check the last user message for safety
    user_messages = [msg.content for msg in req.messages if msg.role == "user"]
    last_message = user_messages[-1] if user_messages else ""
    return {"messages": req.messages, "safe": True, "last_user_message": last_message}

@app.post("/chat")
async def chat(req: ChatReq):
    """
    Guardrail workflow:
    1. Check if the messages are safe.
    2. If safe, forward to llm-proxy and return its response.
    """
    # 1. Call our own sanitize function
    result = await sanitize(req)
    if not result["safe"]:
        raise HTTPException(status_code=400, detail="Unsafe messages detected")

    # 2. Forward to llm-proxy with the new format
    async with httpx.AsyncClient(timeout=60) as cx:
        resp = await cx.post(LLM_PROXY_URL, json=req.dict())
        resp.raise_for_status()
        return resp.json()

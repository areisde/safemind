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

class ChatReq(BaseModel):
    prompt: str

app = FastAPI()

@app.get("/healthz")
async def health():
    return {"status": "ok"}

@app.post("/sanitize")
async def sanitize(req: ChatReq):
    return {"prompt": req.prompt, "safe": True}

@app.post("/chat")
async def chat(req: ChatReq):
    """
    Placeholder workflow:
    1. Ask /sanitize if the prompt is safe.
    2. If safe, forward to llm‑proxy and return its response.
    """
    # 1  Call our own sanitize function
    result = await sanitize(req)
    if not result["safe"]:
        raise HTTPException(status_code=400, detail="Unsafe prompt")

    # 2  Forward to llm‑proxy
    async with httpx.AsyncClient(timeout=60) as cx:
        resp = await cx.post(LLM_PROXY_URL, json=req.dict())
        resp.raise_for_status()
        return resp.json()

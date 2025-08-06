import httpx, pytest

@pytest.mark.asyncio
async def test_sanitize_and_chat(forwarded_proxy):
    async with httpx.AsyncClient() as cx:
        r = await cx.post("http://localhost:9010/sanitize",
                          json={"prompt": "hello"},
                          headers={"kong-api-key": "demo",
                                   "Content-Type": "application/json"})
        assert r.status_code == 200
        r = await cx.post("http://localhost:9010/chat",
                          json={"prompt": "hello"},
                          headers={"kong-api-key": "demo",
                                   "Content-Type": "application/json"})
        assert r.status_code == 200
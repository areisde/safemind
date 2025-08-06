import httpx, pytest

@pytest.mark.asyncio
async def test_size_limit(forwarded_proxy):
    big_payload = "x" * 300_000  # 300 kB
    async with httpx.AsyncClient() as cx:
        r = await cx.post("http://localhost:9010/chat",
                          headers={"kong-api-key": "demo",
                                   "Content-Type": "text/plain"},
                          content=big_payload)
        assert r.status_code == 413
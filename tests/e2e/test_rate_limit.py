import httpx, pytest, asyncio, itertools, collections

BASE = "http://localhost:9010"
HEADERS = {"kong-api-key": "demo",
           "Content-Type": "application/json"}

@pytest.mark.asyncio
async def test_rate_limit(forwarded_proxy):
    async with httpx.AsyncClient(timeout=5) as cx:
        codes = collections.Counter()
        for _ in range(105):
            r = await cx.post(f"{BASE}/chat", headers=HEADERS,
                              json={"prompt": "hi"})
            codes[r.status_code] += 1
        assert codes[200] >= 95
        assert codes[429] >= 1
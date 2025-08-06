import subprocess, pytest, httpx, time, os, signal

@pytest.fixture(scope="session")
def forwarded_proxy():
    # Port-forward Kong proxy once for the whole session
    pf = subprocess.Popen(
        ["kubectl", "-n", "llm", "port-forward", "svc/kong-kong-proxy", "9010:80"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    time.sleep(3)  # give it time
    yield
    os.kill(pf.pid, signal.SIGTERM)
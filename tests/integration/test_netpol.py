import kubernetes as k8s
import pytest


@pytest.fixture(scope="session")
def k8s_api():
    k8s.config.load_kube_config()          # uses $KUBECONFIG
    return k8s.client.NetworkingV1Api()


def test_east_west_netpol(k8s_api):
    np = k8s_api.read_namespaced_network_policy(
        name="allow-guardrail-to-llmproxy", namespace="llm")
    assert np.spec.policy_types == ["Ingress"]
    # Only llm-proxy selected
    assert np.spec.pod_selector.match_labels["app.kubernetes.io/name"] == "llm-proxy"
    # Exactly one ingress rule
    assert len(np.spec.ingress) == 1
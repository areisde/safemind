from kubernetes import config, client

def test_rate_limit_plugin_present():
    config.load_kube_config()
    api = client.CustomObjectsApi()
    plugin = api.get_cluster_custom_object(
        group="configuration.konghq.com", version="v1",
        plural="kongclusterplugins", name="ratelimit-global")
    
    assert plugin["plugin"] == "rate-limiting"
    assert plugin["metadata"]["labels"].get("global") == "true"
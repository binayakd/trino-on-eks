resource "kubernetes_manifest" "pod_trino_test_pod" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Pod"
    "metadata" = {
      "name" = "test-pod"
      "namespace" = "trino"
    }
    "spec" = {
      "containers" = [
        {
          "args" = [
            "while true; do sleep 30; done;",
          ]
          "command" = [
            "/bin/bash",
            "-c",
            "--",
          ]
          "image" = "amazon/aws-cli:latest"
          "name" = "test"
        },
      ]
      "serviceAccountName" = "s3-access"
    }
  }
}

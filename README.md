# Trino on EKS with IAM/IRSA Integration

## Introduction
This is an example implementation of running a Trino cluster in EKS, and using IAM/IRSA to authenticate the connection to the S3 bucket.

## Repo Structure



## References

https://shipit.dev/posts/setting-up-eks-with-irsa-using-terraform.html

https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest#input_enable_cluster_creator_admin_permissions
https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-assumable-role-with-oidc#input_role_policy_arns

https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

https://github.com/hashicorp/terraform-provider-kubernetes/blob/main/_examples/eks/kubernetes-config/main.tf


creating service account
https://stackoverflow.com/questions/72256006/service-account-secret-is-not-listed-how-to-fix-it
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.24.md#urgent-upgrade-notes
https://github.com/hashicorp/terraform-provider-kubernetes/issues/1943


AWS samples - hive emr on eks:
https://github.com/aws-samples/hive-emr-on-eks

Latest on connecting hive to S3
https://hadoop.apache.org/docs/current/hadoop-aws/tools/hadoop-aws/index.html#Authenticating_with_S3


Trino s3 file system support:
https://trino.io/docs/current/object-storage/file-system-s3.html
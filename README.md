# Trino on EKS with IAM/IRSA Integration Demo

## Introduction
This is an example implementation of running a Trino cluster in EKS, and using IAM/IRSA to authenticate the connection to the S3 bucket.

Detailed code walkthrough can be found [here](https://binayakd.tech/posts/2024-05-30-trino-on-eks-with-oicd/)

## How to run this Demo

0. (Optional): The folder build the Hive Standalone Metastore image from the Dockerfile in `metastore/image` folder, and push it to your container registry of choice.

1. Setup the AWS resources from the OpenTofu (Terraform) files in the folder `terraform/aws-resources`, with the appropriate variables. 
Example variables:
```terraform
name                                 = "trino-on-eks"
region                               = "ap-southeast-1"
vpc_cidr                             = "10.0.0.0/24"
kube_namespace_name                  = "trino"
kube_sa_name                         = "s3-access"
cluster_endpoint_public_access_cidrs = ["your_ip_here/32"]
kubeconfig_location                  = "../../local/kubeconfig.yaml"
enable_eks                           = true
enable_rds                           = true
```

The resources that will be setup are:
   - S3 bucket
   - IAM policies and Roles for access to the S3 bucket based on IAM/IRSA Integration 
   - VPC
   - EKS cluster
   - Postgres RDS instance for the Metastore

2. Deploy the Kubernetes resources from the folder  `terraform/kube-resources`, with appropriate variables.
Example variables:
```terraform
name                = "trino-on-eks"
region              = "ap-southeast-1"
kube_namespace_name = "trino"
kube_sa_name        = "s3-access"
```

 The kube resources that would be deployed are:
   - Kube Namespace
   - Service Account for S3 access using IAM/IRSA Integration
   - Hive Metastore deployment and service using the helm chart in the folder: `metastore/helm-chart`
   - Trino deployment using the official Helm chart, using the values file: `terraform/kube-resources/trino-helm-values.yaml`

This should have you up and running.
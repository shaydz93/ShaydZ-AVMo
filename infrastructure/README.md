# Infrastructure as Code for ShaydZ AVMo

This directory contains Infrastructure as Code (IaC) templates for deploying ShaydZ AVMo to various cloud providers.

## Supported Cloud Providers

- AWS (Amazon Web Services)
- Azure (Microsoft Azure)
- GCP (Google Cloud Platform)

## Directory Structure

```
infrastructure/
├── aws/            # AWS CloudFormation templates
├── azure/          # Azure ARM templates
├── gcp/            # GCP Deployment Manager templates
├── kubernetes/     # Kubernetes manifests
└── terraform/      # Terraform modules
```

## Deployment Instructions

See [PRODUCTION_DEPLOYMENT.md](../docs/PRODUCTION_DEPLOYMENT.md) for detailed deployment instructions.

## Quick Start

1. Choose your preferred cloud provider
2. Navigate to the corresponding directory
3. Follow the README.md in that directory for specific instructions

## Requirements

- AWS CLI, Azure CLI, or Google Cloud CLI (depending on your cloud provider)
- Terraform v1.0.0 or later (if using Terraform)
- kubectl v1.20.0 or later (if using Kubernetes)

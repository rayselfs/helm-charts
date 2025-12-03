# Helm Charts Repository

This repository contains multiple Helm Charts for deploying various Kubernetes applications.

## 📦 Available Charts

- **thanos** - Managed Thanos deployment for compactor, query, query-frontend and storegateway components
- **aws-ec2-runtime-checker** - AWS EC2 Long-Running Checker

## 🚀 Quick Start

### Add Rayselfs Helm repository

```bash
# Add repository (replace with your actual repository URL)
helm repo add rayselfs https://rayselfs.github.io/helm-charts
helm repo update
```

### Example for install chart

```bash
# Install chart
helm install thanos rayselfs/thanos
```

## 📝 License

This project is licensed under the [Apache License 2.0](LICENSE).
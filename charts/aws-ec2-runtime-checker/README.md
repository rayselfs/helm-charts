# AWS EC2 Runtime Checker Helm Chart

A Helm chart for deploying the AWS EC2 Runtime Checker on Kubernetes. This tool monitors EC2 instances and automatically terminates those exceeding configured runtime thresholds.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- AWS credentials configured (IRSA recommended for EKS)

## Installing the Chart

### Add the Helm repository

```bash
helm repo add aws-ec2-runtime-checker https://rayselfs.github.io/aws-ec2-runtime-checker
helm repo update
```

### Install the chart

```bash
helm install aws-ec2-runtime-checker aws-ec2-runtime-checker/aws-ec2-runtime-checker
```

### Install with custom values

```bash
helm install aws-ec2-runtime-checker aws-ec2-runtime-checker/aws-ec2-runtime-checker \
  --set aws.region=us-west-2 \
  --set dryRun=false \
  --set 'targets[0].instanceType=t3.micro' \
  --set 'targets[0].maxRuntimeHours=24'
```

## Configuration

See [values.yaml](values.yaml) for the full list of configuration options.

## Parameters

### Global Parameters

| Parameter          | Description                                        | Default       |
| ------------------ | -------------------------------------------------- | ------------- |
| `kind`             | Deployment type: `Deployment` or `CronJob`         | `Deployment`  |
| `schedule`         | Cron schedule expression (required for both modes) | `"0 * * * *"` |
| `replicaCount`     | Number of replicas (Deployment mode only)          | `1`           |
| `nameOverride`     | Override the name of the chart                     | `""`          |
| `fullnameOverride` | Override the full name of the release              | `""`          |

### Image Parameters

| Parameter          | Description                               | Default                            |
| ------------------ | ----------------------------------------- | ---------------------------------- |
| `image.repository` | Container image repository                | `rayselfs/aws-ec2-runtime-checker` |
| `image.pullPolicy` | Image pull policy                         | `IfNotPresent`                     |
| `image.tag`        | Image tag (overrides chart appVersion)    | `""`                               |
| `imagePullSecrets` | Image pull secrets for private registries | `[]`                               |

### AWS Configuration

| Parameter             | Description                                       | Default     |
| --------------------- | ------------------------------------------------- | ----------- |
| `aws.region`          | AWS region where EC2 instances are located        | `us-east-1` |
| `aws.accessKeyId`     | AWS Access Key ID (not recommended, use IRSA)     | `""`        |
| `aws.secretAccessKey` | AWS Secret Access Key (not recommended, use IRSA) | `""`        |
| `snsTopicArn`         | SNS topic ARN for notifications (optional)        | `""`        |
| `dryRun`              | Enable dry run mode (no actual termination)       | `true`      |

### Target Configuration

| Parameter                   | Description                                  | Default         |
| --------------------------- | -------------------------------------------- | --------------- |
| `targets`                   | List of instance types and max runtime hours | See values.yaml |
| `targets[].instanceType`    | EC2 instance type to monitor                 | `t2.micro`      |
| `targets[].maxRuntimeHours` | Maximum allowed runtime in hours             | `24`            |

### Service Account Parameters

| Parameter                    | Description                                      | Default |
| ---------------------------- | ------------------------------------------------ | ------- |
| `serviceAccount.create`      | Create a service account                         | `true`  |
| `serviceAccount.annotations` | Annotations for the service account (e.g., IRSA) | `{}`    |
| `serviceAccount.name`        | Name of the service account                      | `""`    |

### Leader Election Parameters

| Parameter                  | Description                                        | Default |
| -------------------------- | -------------------------------------------------- | ------- |
| `leaderElection.enabled`   | Enable leader election (required for replicas > 1) | `false` |
| `leaderElection.leaseName` | Name of the lease resource                         | `""`    |

### Pod Disruption Budget Parameters

| Parameter            | Description                                    | Default |
| -------------------- | ---------------------------------------------- | ------- |
| `pdb.create`         | Create a PodDisruptionBudget                   | `false` |
| `pdb.minAvailable`   | Minimum number of pods that must be available  | `1`     |
| `pdb.maxUnavailable` | Maximum number of pods that can be unavailable | `nil`   |

### Security Parameters

| Parameter            | Description                | Default |
| -------------------- | -------------------------- | ------- |
| `podSecurityContext` | Pod security context       | `{}`    |
| `securityContext`    | Container security context | `{}`    |
| `podAnnotations`     | Annotations to add to pods | `{}`    |

### Resource Parameters

| Parameter                   | Description    | Default |
| --------------------------- | -------------- | ------- |
| `resources.limits.cpu`      | CPU limit      | `nil`   |
| `resources.limits.memory`   | Memory limit   | `nil`   |
| `resources.requests.cpu`    | CPU request    | `nil`   |
| `resources.requests.memory` | Memory request | `nil`   |

### Scheduling Parameters

| Parameter      | Description                       | Default |
| -------------- | --------------------------------- | ------- |
| `nodeSelector` | Node selector for pod assignment  | `{}`    |
| `tolerations`  | Tolerations for pod assignment    | `[]`    |
| `affinity`     | Affinity rules for pod assignment | `{}`    |

### Example: Setting Parameters via CLI

```bash
helm install aws-ec2-runtime-checker aws-ec2-runtime-checker/aws-ec2-runtime-checker \
  --set aws.region=us-west-2 \
  --set dryRun=false \
  --set replicaCount=2 \
  --set leaderElection.enabled=true \
  --set 'targets[0].instanceType=t3.micro' \
  --set 'targets[0].maxRuntimeHours=24'
```

### Example: Production Configuration

```yaml
# production-values.yaml
kind: Deployment
replicaCount: 2
schedule: "*/30 * * * *" # Every 30 minutes

aws:
  region: us-east-1

dryRun: false # Enable actual termination

snsTopicArn: "arn:aws:sns:us-east-1:123456789012:ec2-alerts"

targets:
  - instanceType: "t2.micro"
    maxRuntimeHours: 24
  - instanceType: "t3.micro"
    maxRuntimeHours: 48
  - instanceType: "c5.large"
    maxRuntimeHours: 72

leaderElection:
  enabled: true
  leaseName: "ec2-checker-leader"

pdb:
  create: true
  minAvailable: 1

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ec2-checker-role
```

Install with:

```bash
helm install aws-ec2-runtime-checker aws-ec2-runtime-checker/aws-ec2-runtime-checker \
  -f production-values.yaml
```

## AWS IAM Permissions

The application requires specific IAM permissions to function properly.

### Required IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2DescribeInstances",
      "Effect": "Allow",
      "Action": ["ec2:DescribeInstances"],
      "Resource": "*"
    },
    {
      "Sid": "EC2TerminateInstances",
      "Effect": "Allow",
      "Action": ["ec2:TerminateInstances"],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "ec2:InstanceType": ["t2.micro", "t3.micro"]
        }
      }
    }
  ]
}
```

### Optional: SNS Notification Policy

If using SNS notifications, add:

```json
{
  "Sid": "SNSPublish",
  "Effect": "Allow",
  "Action": ["sns:Publish"],
  "Resource": "arn:aws:sns:*:*:ec2-checker-*"
}
```

### Setting up IRSA (IAM Roles for Service Accounts) on EKS

1. **Create IAM Policy**

```bash
aws iam create-policy \
  --policy-name EC2RuntimeCheckerPolicy \
  --policy-document file://iam-policy.json
```

2. **Create IAM Role with OIDC Provider**

```bash
eksctl create iamserviceaccount \
  --name ec2-checker \
  --namespace default \
  --cluster YOUR_CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/EC2RuntimeCheckerPolicy \
  --approve \
  --override-existing-serviceaccounts
```

3. **Install Helm Chart with IRSA**

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/eksctl-CLUSTER-addon-iamserviceaccount-Role
  name: ec2-checker
```

### Alternative: Using AWS Access Keys (Not Recommended)

For non-EKS clusters or testing:

```yaml
aws:
  region: us-east-1
  accessKeyId: "AKIAIOSFODNN7EXAMPLE"
  secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

> ⚠️ **Security Warning**: Using access keys is not recommended for production. Use IRSA or IAM instance profiles instead.

## Deployment Modes

### Deployment Mode (Recommended)

Runs continuously with internal cron scheduling:

```yaml
kind: Deployment
replicaCount: 2
schedule: "*/30 * * * *"
leaderElection:
  enabled: true
```

**Advantages:**

- High availability with leader election
- Immediate feedback on deployment
- Better for frequent checks

### CronJob Mode

Kubernetes manages the scheduling:

```yaml
kind: CronJob
schedule: "0 */6 * * *" # Every 6 hours
```

**Advantages:**

- Simpler resource management
- Better for infrequent checks
- No need for leader election

## Uninstalling the Chart

```bash
helm uninstall aws-ec2-runtime-checker
```

## Upgrading the Chart

```bash
helm upgrade aws-ec2-runtime-checker aws-ec2-runtime-checker/aws-ec2-runtime-checker \
  -f values.yaml
```

## Troubleshooting

### Check Pod Logs

```bash
kubectl logs -l app.kubernetes.io/name=aws-ec2-runtime-checker
```

### Verify AWS Permissions

```bash
kubectl exec -it deployment/aws-ec2-runtime-checker -- \
  aws ec2 describe-instances --max-results 1
```

### Test Dry Run Mode

Always test with `dryRun: true` first to verify the configuration without terminating instances.

## License

Apache License 2.0

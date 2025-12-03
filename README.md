# Helm Charts Repository

This repository contains multiple Helm Charts for deploying various Kubernetes applications.

## 📦 Available Charts

- **thanos** - Managed Thanos deployment for compactor, query, query-frontend and storegateway components
- **aws-ec2-runtime-checker** - AWS EC2 Long-Running Checker

## 🚀 Quick Start

### Install Chart

```bash
helm repo add rayselfs https://rayselfs.github.io/helm-charts
helm repo update

# Install chart
helm install thanos rayselfs/thanos
```

## 📁 Folder Structure

This repository uses a unified structure where all Helm Charts are located under the `charts/` directory:

```
helm-charts/
├── .github/
│   └── workflows/
│       └── release.yml          # GitHub Actions workflow (lint + release)
├── charts/                       # All Helm Charts directory
│   ├── thanos/                  # Thanos Helm Chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── prometheus/              # Prometheus Helm Chart (example)
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── <chart-name>/            # Other Helm Charts
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── artifacthub-repo.yml         # Artifact Hub configuration
└── README.md                     # This file
```

## ➕ Adding a New Helm Chart

### 1. Create Chart Directory

Create a new folder under the `charts/` directory. The folder name should match the `name` field in Chart.yaml:

```bash
mkdir -p charts/<chart-name>
cd charts/<chart-name>
```

### 2. Initialize Chart

Create a new chart using Helm:

```bash
helm create <chart-name>
```

Or manually create the necessary files:
- `Chart.yaml` - Chart metadata
- `values.yaml` - Default configuration values
- `templates/` - Kubernetes template files directory

### 3. Chart.yaml Example

```yaml
apiVersion: v2
name: <chart-name>
description: Description of your chart
type: application
version: 0.1.0
appVersion: "1.0.0"
home: https://example.com
icon: https://example.com/icon.png
keywords:
  - keyword1
  - keyword2
sources:
  - https://github.com/example/repo
```

### 4. Important Notes

- **Directory name must match the `name` field in Chart.yaml**
- Each chart must contain a valid `Chart.yaml` file
- Version numbers should follow [Semantic Versioning](https://semver.org/) specification
- **Version numbers need to be manually updated**: Remember to update the `version` field in Chart.yaml before committing
- All charts must be located under the `charts/` directory

## 🔄 Publishing New Versions

### Automatic Publishing (Recommended)

When you push code to the `main` branch (with changes to `Chart.yaml` files), GitHub Actions will **automatically detect modified charts** and publish them.

**Publishing Process:**

```bash
# 1. Update version number in Chart.yaml
vim charts/thanos/Chart.yaml  # Change version: 0.1.0 -> 0.1.1

# 2. Modify chart files
# ... make your changes ...

# 3. Commit and push
git add charts/thanos/
git commit -m "Update thanos chart to v0.1.1"
git push origin main

# 4. GitHub Actions will automatically:
#    - Run lint checks
#    - Detect and publish the chart
```

**Important Notes:**
- ✅ The workflow will **automatically detect** which charts have been modified
- ✅ Version numbers are **read** from the `version` field in `Chart.yaml` (not automatically updated)
- ✅ You need to **manually update** the version number in Chart.yaml before committing
- ✅ **Lint checks run first**: Charts must pass lint validation before release
- ⚠️ If a release with the same version already exists, it will be automatically skipped

**Example: Publishing Multiple Charts Simultaneously**
```bash
# Modified thanos and prometheus
vim charts/thanos/Chart.yaml      # version: 0.1.0 -> 0.1.1
vim charts/prometheus/Chart.yaml  # version: 1.0.0 -> 1.0.1

git add charts/thanos/ charts/prometheus/
git commit -m "Update multiple charts"
git push origin main

# The workflow will automatically detect and publish both charts
```

### Manual Trigger

1. Go to [GitHub Actions](https://github.com/YOUR_ORG/helm-charts/actions)
2. Select the "Release Helm Chart" workflow
3. Click "Run workflow"
4. The workflow will automatically detect all modified charts

## 🔧 Workflow Description

The GitHub Actions workflow consists of two sequential jobs:

### Job 1: lint-test
1. Checkout code (with full git history)
2. Set up Helm and chart-testing tools
3. Detect changed charts using `ct list-changed`
4. Run `ct lint` on all changed charts
5. **Only proceed to release if lint passes**

### Job 2: release
Runs only after `lint-test` succeeds:

1. Checkout code (with full git history)
2. Configure Git user
3. Run `helm/chart-releaser-action` which:
   - Scans all charts in the `charts/` directory
   - Detects charts with version changes (by comparing Chart.yaml with git history)
   - Checks if a GitHub Release already exists for each chart version
   - Packages charts as `.tgz` files
   - Creates GitHub Releases and uploads packaged charts
   - Updates `index.yaml` in the `gh-pages` branch
   - Tag format: `<chart-name>-<version>` (e.g., `thanos-0.1.1`)

### Detection Logic

The workflow uses `helm/chart-releaser-action` which:

- **Scans all charts**: Automatically detects all charts in the `charts/` directory
- **Version detection**: Compares Chart.yaml versions with git history to detect changes
- **Duplicate prevention**: Skips charts if a GitHub Release with the same version already exists
- **Automatic packaging**: Creates `.tgz` packages and uploads to GitHub Releases
- **Index management**: Automatically updates `index.yaml` in the `gh-pages` branch

## 🔗 Artifact Hub Integration

This repository is configured to work with Artifact Hub. Charts are automatically published to GitHub Pages and can be indexed by Artifact Hub.

### Setup Instructions

#### 1. Update artifacthub-repo.yml

Edit `artifacthub-repo.yml` in the root directory and update:
- `owners[0].email`: Your email address
- `homeURL`: Your GitHub repository URL (e.g., `https://github.com/YOUR_USERNAME/helm-charts`)
- `logoURL`: Your GitHub avatar URL (replace `<github_user_id>` with your GitHub user ID)

**Note**: Leave `repositoryID` blank initially. Artifact Hub will generate it after first registration.

#### 2. Enable GitHub Pages

1. Go to your repository → ⚙️ **Settings** → **Pages**
2. Configure:
   - **Source**: Deploy from a branch
   - **Branch**: `gh-pages` (or `main`), **Folder**: `/ (root)**
3. Save and wait for GitHub Pages to be enabled
4. You'll get a URL like: `https://YOUR_USERNAME.github.io/helm-charts`

#### 3. Verify GitHub Pages

After the first workflow run, verify you can access:
- `https://YOUR_USERNAME.github.io/helm-charts/index.yaml`

#### 4. Register on Artifact Hub

1. Visit [Artifact Hub](https://artifacthub.io/)
2. Log in with your GitHub account
3. Click your profile icon → **Control Panel** → **Repositories** → **Add repository**
4. Fill in:
   - **Kind**: Helm
   - **URL**: `https://YOUR_USERNAME.github.io/helm-charts`
   - **Repository name**: e.g., `your-charts`
   - **Public**: ✅ (if you want it public)
5. After saving, Artifact Hub will generate a `repositoryID`
6. **Important**: Copy the `repositoryID` and update it in `artifacthub-repo.yml`
7. Commit and push the updated `artifacthub-repo.yml`

Artifact Hub will automatically sync and index your charts from GitHub Pages.

## 🔍 Workflow Triggers

The workflow is triggered when:
- **Push to `main` branch**: Only if files under `charts/**/Chart.yaml` are modified
- **Manual dispatch**: Can be manually triggered from GitHub Actions UI

The workflow will **not** trigger for changes to:
- `README.md` files
- `.github/**` files
- `LICENSE` file
- `.gitignore` file

## 🤝 Contributing

Contributions of new Helm Charts are welcome!

1. Create a new chart directory under `charts/`
2. Ensure the directory name matches the `name` field in Chart.yaml
3. Submit a Pull Request

## 📝 License

This project is licensed under the [Apache License 2.0](LICENSE).

# Helm Charts Repository

This repository contains multiple Helm Charts for deploying various Kubernetes applications.

## 📦 Available Charts

- **thanos** - Managed Thanos deployment for compactor, query, query-frontend and storegateway components

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
│       └── release.yml          # GitHub Actions automation workflow
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

When you push code to the `main` branch, GitHub Actions will **automatically detect modified charts** and read the version number from `Chart.yaml` to publish.

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

# 4. GitHub Actions will automatically detect and publish
```

**Important Notes:**
- ✅ The workflow will **automatically detect** which charts have been modified
- ✅ Version numbers are **read** from the `version` field in `Chart.yaml` (not automatically updated)
- ✅ You need to **manually update** the version number in Chart.yaml before committing
- ✅ Multiple modified charts can be published simultaneously (parallel processing)
- ⚠️ If a release with the same version already exists, it will be automatically skipped

**Example: Publishing Multiple Charts Simultaneously**
```bash
# Modified thanos and prometheus
vim charts/thanos/Chart.yaml      # version: 0.1.0 -> 0.1.1
vim charts/prometheus/Chart.yaml  # version: 1.0.0 -> 1.0.1

git add charts/thanos/ charts/prometheus/
git commit -m "Update multiple charts"
git push origin main

# The workflow will automatically detect and publish both charts in parallel
```

### Manual Trigger

1. Go to [GitHub Actions](https://github.com/YOUR_ORG/helm-charts/actions)
2. Select the "Release Helm Chart" workflow
3. Click "Run workflow"
4. The workflow will automatically detect all modified charts

## 🔧 Workflow Description

The GitHub Actions workflow consists of two jobs:

### Job 1: detect-charts
1. Checkout code (with full git history)
2. Scan all charts under the `charts/` directory
3. For each chart:
   - Read `name` and `version` from `Chart.yaml`
   - Check if release tag `<name>-<version>` already exists
   - If the tag doesn't exist, add it to the release list
4. Output the list of charts to be released (JSON format)

### Job 2: release (Matrix Strategy)
For each modified chart, execute in parallel:

1. Validate chart directory and Chart.yaml exist (located at `charts/<chart-name>/`)
2. **Read version number from Chart.yaml** (not automatically updated)
3. Check if release tag already exists
4. Run `helm lint` check
5. Package chart as `.tgz` file
6. Create GitHub Release and upload the packaged chart
   - Tag format: `<chart-name>-<version>` (e.g., `thanos-0.1.1`)

### Detection Logic

The workflow will:

- **Directly scan all charts**: Iterate through all subdirectories under `charts/`
- **Check Chart.yaml**: Verify each directory contains a valid `Chart.yaml` file
- **Read version information**: Read `name` and `version` fields from `Chart.yaml`
- **Check existing releases**: Use GitHub CLI to check if release `<name>-<version>` already exists
- **Filter published versions**: If a release with that version already exists, skip that chart
- **Support first-time publishing**: Can correctly handle the first publish even without git history

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

## 📚 Detailed Documentation

- [GitHub Actions Workflow Documentation](.github/workflows/README.md) - Details about the automated publishing process

## 🤝 Contributing

Contributions of new Helm Charts are welcome!

1. Create a new chart directory under `charts/`
2. Ensure the directory name matches the `name` field in Chart.yaml
3. Submit a Pull Request

## 📝 License

This project is licensed under the [Apache License 2.0](LICENSE).

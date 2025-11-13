# Helm Charts Repository

本倉庫包含多個 Helm Charts，用於部署各種 Kubernetes 應用程式。

## 📦 可用的 Charts

- **thanos** - Managed Thanos deployment for compactor, query, query-frontend and storegateway components

## 🚀 快速開始

### 安裝 Chart

```bash
# 添加倉庫（請替換為實際的倉庫 URL）
helm repo add <repo-name> <repo-url>
helm repo update

# 安裝 chart
helm install <release-name> <repo-name>/<chart-name>
```

### 範例：安裝 Thanos

```bash
helm repo add my-charts https://github.com/YOUR_ORG/helm-charts/releases/download/thanos-0.1.0/
helm install thanos my-charts/thanos
```

## 📁 資料夾結構

本倉庫採用統一結構，所有 Helm Charts 位於 `charts/` 目錄下：

```
helm-charts/
├── .github/
│   └── workflows/
│       └── release.yml          # GitHub Actions 自動化工作流程
├── scripts/
│   └── detect-changed-charts.sh  # 偵測修改的 charts 腳本
├── charts/                       # 所有 Helm Charts 目錄
│   ├── thanos/                  # Thanos Helm Chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── prometheus/              # Prometheus Helm Chart (範例)
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── <chart-name>/            # 其他 Helm Charts
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── artifacthub-repo.yml         # Artifact Hub 配置
└── README.md                     # 本文件
```

## ➕ 新增 Helm Chart

### 1. 創建 Chart 目錄

在 `charts/` 目錄下創建新的資料夾，名稱應與 Chart.yaml 中的 `name` 欄位一致：

```bash
mkdir -p charts/<chart-name>
cd charts/<chart-name>
```

### 2. 初始化 Chart

使用 Helm 創建新的 chart：

```bash
helm create <chart-name>
```

或者手動創建必要的文件：
- `Chart.yaml` - Chart 元數據
- `values.yaml` - 預設配置值
- `templates/` - Kubernetes 模板文件目錄

### 3. Chart.yaml 範例

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

### 4. 重要注意事項

- **目錄名稱必須與 Chart.yaml 中的 `name` 欄位一致**
- 每個 chart 必須包含有效的 `Chart.yaml` 文件
- 版本號應遵循[語義化版本](https://semver.org/)規範
- **版本號需要手動更新**：在提交前記得更新 Chart.yaml 中的 `version` 欄位
- 所有 charts 必須位於 `charts/` 目錄下

## 🔄 發布新版本

### 自動發布（推薦）

當你推送代碼到 `main` 分支時，GitHub Actions 會**自動偵測修改的 charts**並從 `Chart.yaml` 中讀取版本號來發布。

**發布流程：**

```bash
# 1. 更新 Chart.yaml 中的版本號
vim charts/thanos/Chart.yaml  # 修改 version: 0.1.0 -> 0.1.1

# 2. 修改 chart 文件
# ... 進行你的修改 ...

# 3. 提交並推送
git add charts/thanos/
git commit -m "Update thanos chart to v0.1.1"
git push origin main

# 4. GitHub Actions 會自動偵測並發布
```

**重要提示：**
- ✅ 工作流程會**自動偵測**哪些 charts 有修改
- ✅ 版本號從 `Chart.yaml` 的 `version` 欄位**讀取**（不會自動更新）
- ✅ 需要在提交前**手動更新** Chart.yaml 中的版本號
- ✅ 可以同時發布多個修改的 charts（並行處理）
- ⚠️ 如果相同版本的 release 已存在，會自動跳過

**範例：同時發布多個 charts**
```bash
# 修改了 thanos 和 prometheus
vim charts/thanos/Chart.yaml      # version: 0.1.0 -> 0.1.1
vim charts/prometheus/Chart.yaml  # version: 1.0.0 -> 1.0.1

git add charts/thanos/ charts/prometheus/
git commit -m "Update multiple charts"
git push origin main

# 工作流程會自動偵測並並行發布兩個 charts
```

### 手動觸發

1. 前往 [GitHub Actions](https://github.com/YOUR_ORG/helm-charts/actions)
2. 選擇 "Release Helm Chart" 工作流程
3. 點擊 "Run workflow"
4. 工作流程會自動偵測所有修改的 charts

## 🔧 工作流程說明

GitHub Actions 工作流程包含兩個 jobs：

### Job 1: detect-charts
1. 檢出代碼（包含完整 git 歷史）
2. 執行 `scripts/detect-changed-charts.sh` 偵測修改的 charts
3. 比較當前 commit 與基礎分支的差異
4. 輸出修改的 charts 列表（JSON 格式）

### Job 2: release (Matrix Strategy)
對每個修改的 chart 並行執行：

1. 驗證 chart 目錄和 Chart.yaml 存在（位於 `charts/<chart-name>/`）
2. **從 Chart.yaml 讀取版本號**（不會自動更新）
3. 檢查 release tag 是否已存在
4. 執行 `helm lint` 檢查
5. 打包 chart 為 `.tgz` 文件
6. 創建 GitHub Release 並上傳打包的 chart
   - Tag 格式：`<chart-name>-<version>`（例如：`thanos-0.1.1`）

### 偵測邏輯

`scripts/detect-changed-charts.sh` 會：

- 比較當前 commit 與 `origin/main` 的差異
- 遍歷所有修改的檔案
- 只處理 `charts/` 目錄下的檔案
- 提取檔案的第二個路徑段作為 chart 目錄名稱（例如：`charts/thanos/templates/deployment.yaml` → `thanos`）
- 驗證該目錄包含 `Chart.yaml` 文件
- 過濾掉非 chart 相關的檔案（.github/, scripts/, *.md 等）
- 輸出所有修改的 chart 名稱（每行一個）

## 🔗 Artifact Hub 集成

發布完成後，Artifact Hub 會自動從 GitHub Releases 中索引你的 charts。

### 在 Artifact Hub 註冊

1. 訪問 [Artifact Hub](https://artifacthub.io/)
2. 登錄並點擊 "Add repository"
3. 選擇 "Helm" 類型
4. 填寫倉庫信息：
   - **Repository URL**: `https://github.com/YOUR_ORG/YOUR_REPO`
   - **Repository name**: 你的倉庫名稱
5. Artifact Hub 會自動從 GitHub Releases 中索引所有發布的 charts

## 📚 詳細文檔

- [GitHub Actions 工作流程說明](.github/workflows/README.md) - 自動化發布流程詳情

## 🤝 貢獻

歡迎貢獻新的 Helm Charts！

1. 在 `charts/` 目錄下創建新的 chart 目錄
2. 確保目錄名稱與 Chart.yaml 中的 `name` 欄位一致
3. 提交 Pull Request

## 📝 授權

本專案採用 [Apache License 2.0](LICENSE) 授權。

# GitHub Actions 工作流程說明

## Release Workflow

這個工作流程會**自動偵測 git 中有修改的 Helm Charts**，並從 Chart.yaml 中讀取版本號來創建 GitHub Release，以便 Artifact Hub 可以自動索引。**支援多個 Helm Charts**，可以同時處理多個修改的 charts。

### 觸發方式

#### 自動觸發：Push 到主分支

當你推送代碼到 `main` 分支時，工作流程會自動：

1. **偵測修改的 charts** - 使用 `scripts/detect-changed-charts.sh` 找出所有有修改的 chart 目錄
2. **讀取版本號** - 從每個修改的 chart 的 `Chart.yaml` 中讀取版本號
3. **並行發布** - 使用 matrix strategy 並行處理所有修改的 charts

```bash
# 修改 chart 後，直接 push 到 main 分支
git add charts/thanos/
git commit -m "Update thanos chart"
git push origin main
```

工作流程會自動：
- 偵測到 `charts/thanos/` 目錄有修改
- 從 `charts/thanos/Chart.yaml` 讀取版本號（例如：`0.1.0`）
- 創建 release tag：`thanos-0.1.0`
- 打包並發布 chart

#### 手動觸發

1. 前往 GitHub Actions 頁面
2. 選擇 "Release Helm Chart" 工作流程
3. 點擊 "Run workflow"
4. 工作流程會自動偵測所有修改的 charts

### 工作流程步驟

#### Job 1: detect-charts
1. **檢查代碼** - 檢出倉庫代碼（包含完整 git 歷史）
2. **安裝 jq** - 用於處理 JSON 輸出
3. **偵測修改的 charts** - 執行 `scripts/detect-changed-charts.sh`
   - 比較當前 commit 與基礎分支（main）的差異
   - 找出所有有修改的 chart 目錄
   - 過濾掉非 chart 相關的檔案（.github/, scripts/, *.md 等）
4. **輸出 charts 列表** - 將修改的 charts 轉換為 JSON 陣列

#### Job 2: release (Matrix Strategy)
對每個修改的 chart 並行執行：

1. **檢查代碼** - 檢出倉庫代碼
2. **設置 Helm** - 安裝最新版本的 Helm
3. **安裝 yq** - 用於讀取 Chart.yaml
4. **驗證 Chart** - 檢查 chart 目錄和 Chart.yaml 是否存在
5. **讀取 Chart 元數據** - 從 Chart.yaml 讀取：
   - Chart 名稱
   - **版本號**（從 Chart.yaml 的 `version` 欄位）
   - 描述
   - App 版本
6. **檢查 Release 是否存在** - 如果 tag 已存在，跳過發布
7. **Lint 檢查** - 執行 `helm lint` 驗證 chart
8. **打包 Chart** - 使用 `helm package` 打包為 `.tgz` 文件
9. **創建 Release** - 創建 GitHub Release 並上傳打包的 chart
   - Tag 格式：`<chart-name>-<version>`（例如：`thanos-0.1.0`）

### 偵測修改的 Charts

工作流程使用 `scripts/detect-changed-charts.sh` 來偵測修改：

- **比較範圍**：當前 commit 與 `origin/main` 的差異
- **偵測邏輯**：
  - 遍歷所有修改的檔案
  - 只處理 `charts/` 目錄下的檔案
  - 提取檔案的第二個路徑段作為 chart 目錄名稱（例如：`charts/thanos/templates/deployment.yaml` → `thanos`）
  - 驗證該目錄包含 `Chart.yaml` 文件
  - 過濾掉非 chart 相關的檔案
- **輸出**：每行一個 chart 名稱

**範例：**
- 修改 `charts/thanos/templates/deployment.yaml` → 偵測到 `thanos`
- 修改 `charts/prometheus/values.yaml` → 偵測到 `prometheus`
- 修改 `README.md` → 忽略（非 chart 檔案）

### 版本號管理

**重要：版本號從 Chart.yaml 讀取，不會自動更新**

- 工作流程會從 `Chart.yaml` 的 `version` 欄位讀取版本號
- **你需要在提交前手動更新 Chart.yaml 中的版本號**
- 如果 tag 已存在（相同版本已發布），會跳過發布

**建議工作流程：**
```bash
# 1. 更新 Chart.yaml 中的版本號
vim charts/thanos/Chart.yaml  # 修改 version: 0.1.0 -> 0.1.1

# 2. 提交修改
git add charts/thanos/Chart.yaml charts/thanos/templates/
git commit -m "Update thanos chart to v0.1.1"

# 3. Push 到 main 分支
git push origin main

# 4. GitHub Actions 會自動偵測並發布
```

### 支援多個 Charts

本工作流程支援倉庫中的多個 Helm Charts：

- **自動偵測**：一次 push 可以同時處理多個修改的 charts
- **並行處理**：使用 matrix strategy 並行發布多個 charts
- **獨立發布**：每個 chart 的發布是獨立的，互不影響

**範例：同時修改多個 charts**
```bash
# 修改了 thanos 和 prometheus
git add charts/thanos/ charts/prometheus/
git commit -m "Update multiple charts"
git push origin main

# 工作流程會自動：
# 1. 偵測到 thanos 和 prometheus 都有修改
# 2. 並行處理兩個 charts
# 3. 分別從各自的 Chart.yaml 讀取版本號
# 4. 創建兩個獨立的 releases
```

### 發布到 Artifact Hub

發布完成後，Artifact Hub 會自動從 GitHub Releases 中發現並索引你的 charts。

#### 在 Artifact Hub 註冊倉庫

1. 訪問 [Artifact Hub](https://artifacthub.io/)
2. 登錄並點擊 "Add repository"
3. 選擇 "Helm" 類型
4. 填寫倉庫信息：
   - **Repository URL**: `https://github.com/YOUR_ORG/YOUR_REPO`
   - **Repository name**: 你的倉庫名稱
5. Artifact Hub 會自動從 GitHub Releases 中索引所有發布的 charts

### 注意事項

- **所有 charts 必須位於 `charts/` 目錄下**
- **Chart 目錄名稱**必須與 Chart.yaml 中的 `name` 欄位一致
- **版本號格式**必須遵循[語義化版本](https://semver.org/)規範
- **手動更新版本號**：在提交前記得更新 Chart.yaml 中的 `version` 欄位
- 需要確保 **GitHub token** 有足夠的權限來創建 releases
- 如果相同版本的 tag 已存在，會**跳過發布**（避免重複發布）
- 每個 chart 的發布是**獨立的**，不會影響其他 charts

### 錯誤處理

如果遇到以下錯誤：

- **No charts changed**: 沒有偵測到修改的 charts，可能是只修改了非 chart 檔案
- **Chart directory does not exist**: 檢查 chart 目錄名稱是否正確
- **Chart.yaml not found**: 確保 chart 目錄中包含 Chart.yaml 文件
- **Version not found in Chart.yaml**: Chart.yaml 中缺少 `version` 欄位
- **Release tag already exists**: 該版本的 release 已存在，需要更新 Chart.yaml 中的版本號
- **Lint failed**: 檢查 chart 的語法和配置是否正確

### 偵測腳本說明

`scripts/detect-changed-charts.sh` 腳本會：

1. 比較當前 commit 與基礎分支的差異
2. 過濾出 chart 相關的檔案（只處理 `charts/` 目錄下的檔案，排除 .github/, scripts/, *.md 等）
3. 提取 chart 目錄名稱（從 `charts/<chart-name>/...` 中提取 `<chart-name>`）
4. 驗證目錄包含 Chart.yaml（位於 `charts/<chart-name>/Chart.yaml`）
5. 輸出所有修改的 chart 名稱（每行一個）

你可以手動執行來測試：
```bash
./scripts/detect-changed-charts.sh
```

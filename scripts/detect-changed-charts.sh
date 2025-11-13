#!/bin/bash
# 偵測 git 中有修改的 Helm Charts
# 輸出格式：每行一個 chart 名稱

set -e

# 獲取基礎分支（用於比較）
BASE_BRANCH="${1:-origin/main}"

# 嘗試獲取所有修改的檔案
# 優先使用與基礎分支的差異，如果失敗則使用與前一個 commit 的差異
CHANGED_FILES=""
if git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
  # 基礎分支存在，比較與基礎分支的差異
  CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH" HEAD 2>/dev/null || echo "")
else
  # 基礎分支不存在，嘗試其他方法
  COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
  if [ "$COMMIT_COUNT" -gt 1 ]; then
    # 有多個 commits，比較與前一個 commit 的差異
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")
  elif [ "$COMMIT_COUNT" -eq 1 ]; then
    # 只有一個 commit，比較與空 tree 的差異（初始 commit）
    CHANGED_FILES=$(git diff --name-only 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD 2>/dev/null || echo "")
  fi
fi

if [ -z "$CHANGED_FILES" ]; then
  # 沒有修改的檔案，正常退出（不輸出任何內容）
  exit 0
fi

# 找出所有 chart 目錄（包含 Chart.yaml 的目錄）
declare -A CHANGED_CHARTS

# 遍歷所有修改的檔案
while IFS= read -r file; do
  # 跳過非 chart 相關的檔案
  if [[ "$file" == .github/* ]] || [[ "$file" == scripts/* ]] || [[ "$file" == *.md ]] || [[ "$file" == artifacthub-repo.yml ]]; then
    continue
  fi
  
  # 檢查是否在 charts/ 目錄下
  if [[ "$file" == charts/* ]]; then
    # 提取 chart 目錄名稱（第二個路徑段，因為第一個是 charts）
    CHART_DIR=$(echo "$file" | cut -d'/' -f2)
    
    # 檢查是否為有效的 chart 目錄（包含 Chart.yaml）
    if [ -d "charts/$CHART_DIR" ] && [ -f "charts/$CHART_DIR/Chart.yaml" ]; then
      CHANGED_CHARTS["$CHART_DIR"]=1
    fi
  fi
done <<< "$CHANGED_FILES"

# 輸出所有修改的 chart 名稱（每行一個）
for chart in "${!CHANGED_CHARTS[@]}"; do
  echo "$chart"
done | sort


#!/usr/bin/env bash
# 实例销毁重启后一键恢复 Git：用户名/邮箱、origin、本机代理、safe.directory
# 用法：
#   bash scripts/setup_git.sh
#   bash scripts/setup_git.sh --push          # 配置后尝试 push 当前分支
#   GIT_USER_NAME=xxx GIT_USER_EMAIL=yyy bash scripts/setup_git.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# ---- defaults（可用环境变量覆盖）----
GIT_USER_NAME="${GIT_USER_NAME:-Cgxiaoxin}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-178176916@qq.com}"
GIT_REMOTE_URL="${GIT_REMOTE_URL:-https://github.com/Cgxiaoxin/Lingbo_VLA.git}"
GIT_REMOTE_NAME="${GIT_REMOTE_NAME:-origin}"
GIT_HTTP_PROXY="${GIT_HTTP_PROXY:-http://127.0.0.1:17890}"
DO_PUSH=0

for arg in "$@"; do
  case "${arg}" in
    --push) DO_PUSH=1 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "[fail] unknown arg: ${arg}" >&2
      exit 1
      ;;
  esac
done

echo "[info] repo: ${ROOT}"

# 1) identity（global，重启后 ~/.gitconfig 常丢失）
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
echo "[ok] user.name=${GIT_USER_NAME}"
echo "[ok] user.email=${GIT_USER_EMAIL}"

# 2) 避免 “dubious ownership”
git config --global --add safe.directory "${ROOT}" 2>/dev/null || true
# 去重（多次运行 safe.directory 可能重复）
if git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "${ROOT}"; then
  :
fi
echo "[ok] safe.directory=${ROOT}"

# 3) remote
if git remote get-url "${GIT_REMOTE_NAME}" >/dev/null 2>&1; then
  current="$(git remote get-url "${GIT_REMOTE_NAME}")"
  if [[ "${current}" != "${GIT_REMOTE_URL}" ]]; then
    git remote set-url "${GIT_REMOTE_NAME}" "${GIT_REMOTE_URL}"
    echo "[ok] ${GIT_REMOTE_NAME} url updated: ${current} -> ${GIT_REMOTE_URL}"
  else
    echo "[ok] ${GIT_REMOTE_NAME} already -> ${GIT_REMOTE_URL}"
  fi
else
  git remote add "${GIT_REMOTE_NAME}" "${GIT_REMOTE_URL}"
  echo "[ok] added ${GIT_REMOTE_NAME} -> ${GIT_REMOTE_URL}"
fi

# 4) 本仓库走反向隧道代理（与 docs/AMD_ROCm_环境手册.md 一致）
git config --local http.proxy "${GIT_HTTP_PROXY}"
git config --local https.proxy "${GIT_HTTP_PROXY}"
echo "[ok] local http(s).proxy=${GIT_HTTP_PROXY}"

# 5) 当前分支跟踪 origin（若尚未设置）
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "${branch}" != "HEAD" ]]; then
  if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    if git ls-remote --exit-code --heads "${GIT_REMOTE_NAME}" "${branch}" >/dev/null 2>&1; then
      git branch --set-upstream-to="${GIT_REMOTE_NAME}/${branch}" "${branch}" || true
    fi
  fi
  echo "[ok] branch=${branch}"
fi

echo
echo "---- summary ----"
echo "  name : $(git config --global --get user.name)"
echo "  email: $(git config --global --get user.email)"
echo "  remote $(git remote get-url "${GIT_REMOTE_NAME}")"
echo "  proxy: $(git config --local --get http.proxy)"
echo

if [[ "${DO_PUSH}" -eq 1 ]]; then
  echo "[info] pushing ${branch} -> ${GIT_REMOTE_NAME} ..."
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    # 临时用带 token 的 URL 推送，不把 token 写进 .git/config
    auth_url="https://x-access-token:${GITHUB_TOKEN}@github.com/Cgxiaoxin/Lingbo_VLA.git"
    git push "${auth_url}" "HEAD:refs/heads/${branch}"
    git branch --set-upstream-to="${GIT_REMOTE_NAME}/${branch}" "${branch}" 2>/dev/null || true
  else
    echo "[hint] 未设置 GITHUB_TOKEN。可："
    echo "       export GITHUB_TOKEN=ghp_xxx   # GitHub → Settings → Developer settings → PAT"
    echo "       bash scripts/setup_git.sh --push"
    echo "  或交互输入用户名 + PAT："
    git push -u "${GIT_REMOTE_NAME}" "${branch}"
  fi
  echo "[ok] push done"
else
  echo "[hint] 仅完成配置。要推送请执行："
  echo "       export GITHUB_TOKEN=ghp_xxx"
  echo "       bash scripts/setup_git.sh --push"
  echo "       # 或: git push -u origin ${branch}"
fi

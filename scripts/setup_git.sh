#!/usr/bin/env bash
# 实例销毁重启后一键恢复 Git：用户名/邮箱、origin、本机代理、Deploy Key(SSH)
#
# 用法：
#   bash scripts/setup_git.sh                 # 只配置
#   bash scripts/setup_git.sh --ssh           # 强制用 SSH + Deploy Key
#   bash scripts/setup_git.sh --ssh --push    # 配置后 push
#   bash scripts/setup_git.sh --https --push  # HTTPS（需 GITHUB_TOKEN）
#
# 密钥默认放持久盘（不进 git）：
#   /workspace/.secrets/github_deploy_ed25519[.pub]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# ---- defaults（可用环境变量覆盖）----
GIT_USER_NAME="${GIT_USER_NAME:-Cgxiaoxin}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-178176916@qq.com}"
GIT_REMOTE_NAME="${GIT_REMOTE_NAME:-origin}"
GIT_HTTP_PROXY="${GIT_HTTP_PROXY:-http://127.0.0.1:17890}"
GIT_SSH_KEY="${GIT_SSH_KEY:-/workspace/.secrets/github_deploy_ed25519}"
GIT_HTTPS_URL="${GIT_HTTPS_URL:-https://github.com/Cgxiaoxin/Lingbo_VLA.git}"
GIT_SSH_URL="${GIT_SSH_URL:-git@github.com:Cgxiaoxin/Lingbo_VLA.git}"
SSH_PROXY_HELPER="${ROOT}/scripts/ssh_http_proxy.py"

DO_PUSH=0
MODE="auto" # auto | ssh | https

for arg in "$@"; do
  case "${arg}" in
    --push) DO_PUSH=1 ;;
    --ssh) MODE="ssh" ;;
    --https) MODE="https" ;;
    -h|--help)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *)
      echo "[fail] unknown arg: ${arg}" >&2
      exit 1
      ;;
  esac
done

if [[ "${MODE}" == "auto" ]]; then
  if [[ -f "${GIT_SSH_KEY}" ]]; then
    MODE="ssh"
  else
    MODE="https"
  fi
fi

if [[ "${MODE}" == "ssh" ]]; then
  GIT_REMOTE_URL="${GIT_REMOTE_URL:-${GIT_SSH_URL}}"
else
  GIT_REMOTE_URL="${GIT_REMOTE_URL:-${GIT_HTTPS_URL}}"
fi

echo "[info] repo: ${ROOT}"
echo "[info] mode: ${MODE}"

# 1) identity（global，重启后 ~/.gitconfig 常丢失）
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
echo "[ok] user.name=${GIT_USER_NAME}"
echo "[ok] user.email=${GIT_USER_EMAIL}"

# 2) 避免 “dubious ownership”
git config --global --add safe.directory "${ROOT}" 2>/dev/null || true
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

# 4) HTTPS 代理（SSH 模式也保留，clone/fetch 混用时有用）
git config --local http.proxy "${GIT_HTTP_PROXY}"
git config --local https.proxy "${GIT_HTTP_PROXY}"
echo "[ok] local http(s).proxy=${GIT_HTTP_PROXY}"

# 5) SSH Deploy Key + 经 17890 的 CONNECT 代理
if [[ "${MODE}" == "ssh" ]]; then
  if [[ ! -f "${GIT_SSH_KEY}" ]]; then
    echo "[fail] missing private key: ${GIT_SSH_KEY}" >&2
    echo "       先生成: ssh-keygen -t ed25519 -f ${GIT_SSH_KEY} -N '' -C lingbo-vla-deploy" >&2
    exit 1
  fi
  if [[ ! -f "${SSH_PROXY_HELPER}" ]]; then
    echo "[fail] missing ${SSH_PROXY_HELPER}" >&2
    exit 1
  fi
  chmod 600 "${GIT_SSH_KEY}" 2>/dev/null || true
  chmod +x "${SSH_PROXY_HELPER}" 2>/dev/null || true

  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  # 幂等写入 github.com Host 块
  cfg="${HOME}/.ssh/config"
  block_begin="# BEGIN lingbo-vla-github"
  block_end="# END lingbo-vla-github"
  tmp="$(mktemp)"
  if [[ -f "${cfg}" ]]; then
    awk -v b="${block_begin}" -v e="${block_end}" '
      $0==b {skip=1; next}
      $0==e {skip=0; next}
      !skip {print}
    ' "${cfg}" > "${tmp}"
  else
    : > "${tmp}"
  fi
  {
    cat "${tmp}"
    echo "${block_begin}"
    echo "Host github.com"
    echo "  HostName ssh.github.com"
    echo "  Port 443"
    echo "  User git"
    echo "  IdentityFile ${GIT_SSH_KEY}"
    echo "  IdentitiesOnly yes"
    echo "  StrictHostKeyChecking accept-new"
    echo "  ProxyCommand /usr/bin/python3 ${SSH_PROXY_HELPER} %h %p"
    echo "${block_end}"
  } > "${cfg}"
  chmod 600 "${cfg}"
  rm -f "${tmp}"
  echo "[ok] ssh config -> IdentityFile ${GIT_SSH_KEY} via proxy 17890"

  if [[ -f "${GIT_SSH_KEY}.pub" ]]; then
    echo
    echo "[action] 若尚未添加 Deploy Key，打开："
    echo "  https://github.com/Cgxiaoxin/Lingbo_VLA/settings/keys"
    echo "  Add deploy key → 勾选 Allow write access → 粘贴公钥："
    echo
    cat "${GIT_SSH_KEY}.pub"
    echo
    echo "  fingerprint: $(ssh-keygen -lf "${GIT_SSH_KEY}.pub" 2>/dev/null | awk '{print $2}')"
    echo
  fi
fi

# 6) 当前分支
branch="$(git rev-parse --abbrev-ref HEAD)"
echo "[ok] branch=${branch}"

echo
echo "---- summary ----"
echo "  name : $(git config --global --get user.name)"
echo "  email: $(git config --global --get user.email)"
echo "  remote $(git remote get-url "${GIT_REMOTE_NAME}")"
echo "  proxy: $(git config --local --get http.proxy)"
echo "  mode : ${MODE}"
echo

if [[ "${DO_PUSH}" -eq 1 ]]; then
  echo "[info] pushing ${branch} -> ${GIT_REMOTE_NAME} ..."
  if [[ "${MODE}" == "ssh" ]]; then
    # GitHub SSH 成功时仍常返回 exit 1，不能 set -e 直接拦
    ssh_msg="$(ssh -o BatchMode=yes -T git@github.com 2>&1 || true)"
    echo "[info] ssh probe: ${ssh_msg}"
    if ! grep -qiE 'successfully authenticated' <<<"${ssh_msg}"; then
      echo "[fail] SSH 未认证成功。请确认已把公钥加到 Deploy keys 并勾选 Allow write access。" >&2
      echo "       https://github.com/Cgxiaoxin/Lingbo_VLA/settings/keys" >&2
      exit 1
    fi
    git push -u "${GIT_REMOTE_NAME}" "${branch}"
  elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
    auth_url="https://x-access-token:${GITHUB_TOKEN}@github.com/Cgxiaoxin/Lingbo_VLA.git"
    git push "${auth_url}" "HEAD:refs/heads/${branch}"
    git branch --set-upstream-to="${GIT_REMOTE_NAME}/${branch}" "${branch}" 2>/dev/null || true
  else
    echo "[fail] HTTPS 需要有效 PAT：" >&2
    echo "       export GITHUB_TOKEN=ghp_xxx && bash scripts/setup_git.sh --https --push" >&2
    echo "  或改用 SSH Deploy Key： bash scripts/setup_git.sh --ssh --push" >&2
    exit 1
  fi
  echo "[ok] push done"
else
  echo "[hint] 配置完成。推送："
  echo "       bash scripts/setup_git.sh --ssh --push"
fi

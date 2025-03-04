#!/bin/bash

# --- 获取 utils.sh 所在的目录 ---
UTILS_DIR="$(dirname "$(readlink -f "$0")")"

# --- ANSI 颜色定义 (可选) ---
# 取消注释以启用彩色输出
readonly COLOR_RED='\033[1;31m'     # 红色加粗
readonly COLOR_GREEN='\033[1;32m'   # 绿色加粗
readonly COLOR_YELLOW='\033[1;33m'  # 黄色加粗
readonly COLOR_BLUE='\033[1;34m'    # 蓝色加粗
readonly COLOR_RESET='\033[0m'

# --- 函数：输出信息 (蓝色) ---
info() {
  echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
}

# --- 函数：输出成功信息 (绿色) ---
success() {
  echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

# --- 函数：输出警告信息 (黄色) ---
warning() {
  echo -e "${COLOR_YELLOW}$1${COLOR_RESET}"
}

# --- 函数：检查命令是否可用 ---
# 参数：
#   $1: 要检查的命令名
# 返回值：
#   如果命令存在，则无返回值 (正常退出)；
#   如果命令不存在，则输出错误信息并退出脚本 (exit 1)。
check_command() {
  if ! command -v "$1" &> /dev/null; then
    error_exit "命令 '$1' 不可用。请确保已安装。"
  fi
}

# --- 函数：错误处理 ---
# 参数：
#   $1: 错误信息
# 返回值：
#   无 (退出脚本，exit 1)
error_exit() {
  echo -e "${COLOR_RED}错误：$1${COLOR_RESET}" >&2
  exit 1
}

# --- 函数：检测操作系统类型和版本 ---
# 设置全局变量：
#   OS_ID: 操作系统 ID (例如 centos, ubuntu, alpine, arch)
#   OS_VERSION: 操作系统版本号
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION=$VERSION_ID
  elif [ -f /etc/alpine-release ]; then
    OS_ID="alpine"
    . /etc/alpine-release
    OS_VERSION=$version
  elif [ -f /etc/arch-release ]; then
    OS_ID="arch"
    OS_VERSION="rolling"
   elif [ -f /etc/SuSE-release ]; then
    OS_ID="opensuse"
    . /etc/SuSE-release
    OS_VERSION=$VERSION
  else
    OS_ID="unknown"
    OS_VERSION="unknown"
  fi
}

# --- 函数：检测是否位于中国大陆 ---
# 设置全局变量：
#   USE_CN_MIRRORS: 如果位于中国大陆，则为 true；否则为 false。
detect_cn_mirrors() {
  local PUBLIC_IP
  # 获取公网 IP 地址
  PUBLIC_IP=$(curl -s https://api.ipify.org)

  # 检查 curl 是否执行成功
  if [[ "$?" -ne 0 ]] || [[ -z "$PUBLIC_IP" ]]; then
    warning "无法获取公网 IP 地址，将默认使用国外镜像源。"
    USE_CN_MIRRORS=false
    return
  fi

  # 使用淘宝 IP 地址库判断是否位于中国大陆
  if curl -s "http://ip.taobao.com/service/getIpInfo.php?ip=$PUBLIC_IP" | grep -q '"country":"中国"'; then
    USE_CN_MIRRORS=true
  else
    USE_CN_MIRRORS=false
  fi
}

# 日志记录函数 (可选，暂不实现)
# log() {
#   :
# }
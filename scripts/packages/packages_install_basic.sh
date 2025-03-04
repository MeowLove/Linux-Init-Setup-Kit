#!/bin/bash

# --- 脚本说明：安装常用的基础软件包 ---

# --- 导入工具函数 ---
source "$UTILS_DIR/cxt-utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 安装基础软件 ---

case "$OS_ID" in
  centos|rhel|rocky|almalinux|oraclelinux|fedora)
    # RHEL 系列 (包括 Fedora)
    check_command dnf
    # 启用 EPEL 源 (如果需要)
    dnf install -y epel-release
    # 安装软件包
    if ! dnf install -y sudo wget curl nano vim tar zip openssl traceroute parted lrzsz screen socat rsync; then
      error_exit "基础软件安装失败 (dnf)。"
    fi
    ;;
  debian|ubuntu)
    # Debian 系列
    check_command apt
    if ! apt install -y sudo wget curl nano vim tar zip openssl traceroute parted lrzsz screen socat rsync; then
      error_exit "基础软件安装失败 (apt)。"
    fi
    ;;
  opensuse-leap|opensuse-tumbleweed|sles)
    # openSUSE/SLES
    check_command zypper
    if ! zypper install -y sudo wget curl nano vim tar zip openssl traceroute parted lrzsz screen socat rsync; then
      error_exit "基础软件安装失败 (zypper)。"
    fi
    ;;
  alpine)
    # Alpine Linux
    check_command apk
    # lrzsz 依赖 bash, Alpine 默认 shell 不是 bash
    if ! apk add bash sudo wget curl nano vim tar zip openssl traceroute parted lrzsz screen socat rsync; then
      error_exit "基础软件安装失败 (apk)。"
    fi
    ;;
  arch)
    # Arch Linux
    check_command pacman
    if ! pacman -S --noconfirm sudo wget curl nano vim tar zip openssl traceroute parted lrzsz screen socat rsync; then
      error_exit "基础软件安装失败 (pacman)。"
    fi
    ;;
  *)
    error_exit "不支持的发行版 '$OS_ID'。"
    ;;
esac

echo "基础软件已成功安装。"
exit 0
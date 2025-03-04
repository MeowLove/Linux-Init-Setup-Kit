#!/bin/bash

# --- 脚本说明：更新系统软件包到最新版本 ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 更新系统 ---

case "$OS_ID" in
  centos|rhel|rocky|almalinux|oraclelinux|fedora)
    # RHEL 系列 (包括 Fedora)
    check_command dnf
    if ! dnf update -y; then
      error_exit "系统更新失败 (dnf)。"
    fi
    ;;
  debian|ubuntu)
    # Debian 系列
    check_command apt
    if ! apt update -y || ! apt upgrade -y; then
      error_exit "系统更新失败 (apt)。"
    fi
    ;;
  opensuse-leap|opensuse-tumbleweed|sles)
    # openSUSE/SLES
    check_command zypper
    if ! zypper refresh -y || ! zypper update -y; then
      error_exit "系统更新失败 (zypper)。"
    fi
    ;;
  alpine)
    # Alpine Linux
    check_command apk
    if ! apk update || ! apk upgrade; then
      error_exit "系统更新失败 (apk)。"
    fi
    ;;
  arch)
    # Arch Linux
    check_command pacman
    if ! pacman -Syu --noconfirm; then
      error_exit "系统更新失败 (pacman)。"
    fi
    ;;
  *)
    error_exit "不支持的发行版 '$OS_ID'。"
    ;;
esac

echo "系统已成功更新。"
exit 0
#!/bin/bash

# --- 脚本说明：安装 ZeroTier 和 Tailscale (非 Alpine Linux) ---

# --- 导入工具函数 ---
source "$(dirname "$(dirname "$(readlink -f "$0")")")/utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 安装 ZeroTier (官方脚本) ---

if [[ "$OS_ID" != "alpine" ]]; then
  check_command curl
  info "安装 ZeroTier..."
  if ! curl -fsSL https://install.zerotier.com/ | bash; then
    error_exit "ZeroTier 安装失败。"
  fi

  check_command systemctl
  systemctl start zerotier-one
  systemctl enable zerotier-one

  echo "ZeroTier 已安装。请手动加入网络："
  echo "sudo zerotier-cli join <network_id>"
else
  echo "跳过 ZeroTier 安装 (Alpine Linux 请使用 install_alpine_net_tools.sh 脚本安装)。"
fi

# --- 安装 Tailscale (官方脚本) ---

if [[ "$OS_ID" != "alpine" ]]; then
  check_command curl
  info "安装 Tailscale..."
  if ! curl -fsSL https://tailscale.com/install.sh | sh; then
    error_exit "Tailscale 安装失败。"
  fi

  check_command systemctl
  systemctl start tailscaled
  systemctl enable tailscaled

  echo "Tailscale 已安装。请手动加入网络："
  echo "sudo tailscale up"
else
  echo "跳过 Tailscale 安装 (Alpine Linux 请使用 install_alpine_net_tools.sh 脚本安装)。"
fi

exit 0
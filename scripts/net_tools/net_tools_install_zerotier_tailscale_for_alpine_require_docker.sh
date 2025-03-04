#!/bin/bash

# --- 脚本说明：在 Alpine Linux 上使用 Docker 安装 ZeroTier 和 Tailscale ---
# 注意：此脚本仅适用于 Alpine Linux，并且需要先安装 Docker。

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 仅在 Alpine Linux 上执行 ---
if [[ "$OS_ID" != "alpine" ]]; then
  echo "此脚本仅适用于 Alpine Linux，将跳过执行。"
  exit 0
fi

# --- 检查 Docker 是否已安装 ---
if ! command -v docker &> /dev/null; then
  echo "警告：Docker 未安装。请先安装 Docker，然后再运行此脚本。"
  exit 0
fi

# --- 安装 ZeroTier (Docker) ---
info "安装 ZeroTier (Docker)..."
if docker run -d --name zerotier-one --net=host --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v /var/lib/zerotier-one:/var/lib/zerotier-one zyclonite/zerotier; then
  success "ZeroTier (Docker) 已安装。"
  echo "请手动加入网络："
  echo "docker exec zerotier-one zerotier-cli join <network_id>"
else
  error_exit "ZeroTier (Docker) 安装失败。"
fi

# --- 安装 Tailscale (Docker) ---
info "安装 Tailscale (Docker)..."
if docker run -d --name tailscaled --net=host --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v /var/lib/tailscale:/var/lib/tailscale -v /dev/net/tun:/dev/net/tun tailscale/tailscale tailscaled; then
  success "Tailscale (Docker) 已安装。"
  echo "请手动启动并加入网络："
  echo "docker exec tailscaled tailscale up"
else
  error_exit "Tailscale (Docker) 安装失败。"
fi

exit 0
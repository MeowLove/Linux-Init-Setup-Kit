#!/bin/bash

# --- 脚本说明：设置 DNS 解析器 ---

# --- 导入工具函数 ---
source "$UTILS_DIR/cxt-utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 设置 DNS ---

# 根据 USE_CN_MIRRORS 变量选择 DNS 服务器
if [[ "$USE_CN_MIRRORS" == "true" ]]; then
  # 国内 DNS 服务器 (阿里 DNS, DNSPod)
  dns_servers=(
    "nameserver 223.5.5.5"
    "nameserver 119.29.29.29"
    "nameserver 2400:3200::1"
    "nameserver 2402:4e00::"
  )
else
  # 国际 DNS 服务器 (Cloudflare, Google)
  dns_servers=(
    "nameserver 1.1.1.1"
    "nameserver 8.8.8.8"
    "nameserver 2606:4700:4700::1111"
    "nameserver 2001:4860:4860::8888"
  )
fi

# 写入 /etc/resolv.conf 文件
if ! { for server in "${dns_servers[@]}"; do echo "$server"; done; } > /etc/resolv.conf; then
  error_exit "无法写入 /etc/resolv.conf 文件。"
fi

echo "DNS 已配置。"

exit 0
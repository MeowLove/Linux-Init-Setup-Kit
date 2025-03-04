#!/bin/bash

# --- 脚本说明：配置 IPv6 地址 (可选) ---

# --- 导入工具函数 ---
source "$(dirname "$(dirname "$(readlink -f "$0")")")/utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 配置 IPv6 地址 ---

read -p "您要配置 IPv6 地址吗？ (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # 1. 选择网络接口
  read -p "您要自动检测接口 (auto) 还是手动指定接口 (manual)？ (auto/manual) " auto_or_manual
  if [[ "$auto_or_manual" == "auto" ]]; then
      interface=$(ip -o -4 route show to default | awk '{print $5}')
  elif [[ "$auto_or_manual" == "manual" ]]; then
      read -p "请输入要配置 IPv6 的网络接口名称: " interface
  else
      error_exit "无效的选择。请输入 'auto' 或 'manual'。"
  fi

  if [[ -z "$interface" ]]; then
    error_exit "未找到网络接口。"
  fi

  # 2. 输入 IPv6 地址和前缀长度
  read -p "请输入要添加的 IPv6 地址 (例如 2001:db8::1/64): " ipv6_address
  if ! [[ "$ipv6_address" =~ ^([0-9a-fA-F:]+:+)+[0-9a-fA-F:.]+(/[0-9]+)?$ ]]; then
      error_exit "IPv6 地址格式无效。"
  fi

  # 3. 添加 IPv6 地址
  if ! ip addr add "$ipv6_address" dev "$interface"; then
    error_exit "添加 IPv6 地址失败。"
  fi

  # 4. (可选) 配置 IPv6 网关
  read -p "您要配置默认的 IPv6 网关吗？ (y/N) " config_gateway
  if [[ "$config_gateway" =~ ^[Yy]$ ]]; then
    read -p "请输入 IPv6 网关地址: " ipv6_gateway
    if ! [[ "$ipv6_gateway" =~ ^([0-9a-fA-F:]+:+)+[0-9a-fA-F:.]+$ ]]; then
      error_exit "IPv6 网关地址格式无效。"
    fi
    if ! ip -6 route add default via "$ipv6_gateway" dev "$interface"; then
      error_exit "配置 IPv6 网关失败。"
    fi
    echo "IPv6 网关已配置。"
  fi

  echo "IPv6 地址已添加到接口 $interface。"
fi

exit 0
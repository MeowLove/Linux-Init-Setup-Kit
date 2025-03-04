#!/bin/bash

# --- 脚本说明：设置 Linux 系统的主机名 ---

# --- 导入工具函数 ---
source "$(dirname "$(dirname "$(readlink -f "$0")")")/utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 设置主机名 ---

read -p "请输入新的主机名: " hostname

# 验证主机名 (简单示例，可以根据需要扩展)
if [[ -z "$hostname" ]] || ! [[ "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]] || [[ "${#hostname}" -gt 255 ]]; then
  error_exit "主机名无效。请确保主机名不为空，只包含字母、数字、点 (.) 和短横线 (-)，且长度不超过 255 个字符。"
fi

if [[ "$OS_ID" == "alpine" ]]; then
    # Alpine Linux
    echo "$hostname" > /etc/hostname
else
    # 其他支持 hostnamectl 的发行版
    hostnamectl set-hostname "$hostname"
fi

echo "主机名已设置为: $(hostname)"

exit 0 # 成功退出
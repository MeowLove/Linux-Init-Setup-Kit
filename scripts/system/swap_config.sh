#!/bin/bash

# --- 脚本说明：配置 Swap 分区/文件 ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 配置 Swap ---

# 获取 Swap 大小
read -p "请输入 Swap 分区/文件大小 (例如 2G, 512M): " swap_size

# 验证 Swap 大小
if [[ -z "$swap_size" ]] || ! [[ "$swap_size" =~ ^[0-9]+[GMK]?$ ]]; then
  error_exit "Swap 大小无效。请输入一个有效的数字和单位 (例如 2G, 512M, 1024K)。"
fi

# 检查 /swapfile 是否已存在，如果存在则先卸载、删除并移除 fstab 中的条目
if [[ -f /swapfile ]]; then
  info "检测到已存在的 /swapfile，将先卸载、删除并更新 /etc/fstab。"
  swapoff /swapfile || error_exit "卸载 /swapfile 失败。"
  rm -f /swapfile || error_exit "删除 /swapfile 失败。"
  sed -i '/\/swapfile/d' /etc/fstab || error_exit "更新 /etc/fstab 失败。"
fi

# 根据发行版创建 Swap 文件
case "$OS_ID" in
  centos|rhel|rocky|almalinux|oraclelinux|fedora|debian|ubuntu|opensuse-leap|opensuse-tumbleweed|sles)
    # 多数发行版
    fallocate -l "$swap_size" /swapfile || error_exit "创建 /swapfile 失败 (fallocate)。"
    chmod 600 /swapfile || error_exit "设置 /swapfile 权限失败。"
    mkswap /swapfile || error_exit "格式化 /swapfile 失败。"
    swapon /swapfile || error_exit "启用 /swapfile 失败。"
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab || error_exit "写入 /etc/fstab 失败。"
    ;;
  alpine)
    # Alpine Linux
    fallocate -l "$swap_size" /swapfile || error_exit "创建 /swapfile 失败 (fallocate)。"
    chmod 600 /swapfile || error_exit "设置 /swapfile 权限失败。"
    mkswap /swapfile || error_exit "格式化 /swapfile 失败。"
    swapon /swapfile || error_exit "启用 /swapfile 失败。"
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab || error_exit "写入 /etc/fstab 失败。"
    rc-update add swap boot || error_exit "将 swap 添加到启动服务失败。"
    ;;
  arch)
    # Arch Linux
    dd if=/dev/zero of=/swapfile bs=1M count=$(echo "$swap_size" | sed 's/[^0-9]//g') || error_exit "创建 /swapfile 失败 (dd)。"
    chmod 600 /swapfile || error_exit "设置 /swapfile 权限失败。"
    mkswap /swapfile || error_exit "格式化 /swapfile 失败。"
    swapon /swapfile || error_exit "启用 /swapfile 失败。"
    echo "/swapfile none swap sw 0 0" >> /etc/fstab || error_exit "写入 /etc/fstab 失败。"
    ;;
  *)
    error_exit "不支持的发行版 '$OS_ID'。"
    ;;
esac

echo "Swap 已配置成功。"
exit 0
#!/bin/bash

# --- 脚本说明：关闭系统防火墙 (带警告) ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 关闭防火墙（带警告） ---

read -p "警告：关闭防火墙会降低系统安全性。您确定要关闭防火墙吗？ (y/N) " -n 1 -r
echo    # 换行
if [[ $REPLY =~ ^[Yy]$ ]]; then
    case "$OS_ID" in
        centos|rhel|rocky|almalinux|oraclelinux|fedora)
            # RHEL 系列 (包括 Fedora)
            check_command systemctl
            if ! systemctl stop firewalld; then
              error_exit "停止 firewalld 服务失败。"
            fi
            if ! systemctl disable firewalld; then
              error_exit "禁用 firewalld 服务失败。"
            fi
            ;;
        debian|ubuntu)
            # Debian 系列 (ufw)
            check_command ufw
            if ! ufw disable; then
              error_exit "禁用 ufw 防火墙失败。"
            fi
            ;;
        opensuse-leap|opensuse-tumbleweed|sles)
            # openSUSE/SLES (SuSEfirewall2)
            check_command systemctl
            if ! systemctl stop SuSEfirewall2; then
              error_exit "停止 SuSEfirewall2 服务失败。"
            fi
            if ! systemctl disable SuSEfirewall2; then
              error_exit "禁用 SuSEfirewall2 服务失败。"
            fi
            ;;
        alpine)
            # Alpine Linux (iptables)
            check_command rc-service
            if ! rc-service iptables stop; then
              error_exit "停止 iptables 服务失败。"
            fi
            if ! rc-update del iptables; then
              error_exit "从启动项中删除 iptables 服务失败。"
            fi
            ;;
        arch)
            # Arch Linux (iptables)
            check_command systemctl
            if ! systemctl stop iptables.service; then
              error_exit "停止 iptables.service 服务失败。"
            fi
            if ! systemctl disable iptables.service; then
              error_exit "禁用 iptables.service 服务失败。"
            fi
            ;;
        *)
            error_exit "不支持的发行版 '$OS_ID'。"
            ;;
    esac
    echo "防火墙已关闭。"
else
    echo "防火墙未关闭。"
fi

exit 0
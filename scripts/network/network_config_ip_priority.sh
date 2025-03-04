#!/bin/bash

# --- 脚本说明：配置网络优先级 (IPv4/IPv6 优先) ---

# --- 导入工具函数 ---
source "$(dirname "$(dirname "$(readlink -f "$0")")")/utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 配置网络优先级 ---

# 检查 /etc/gai.conf 是否存在，如果不存在则创建并写入默认配置
if [[ ! -f /etc/gai.conf ]]; then
  cat <<EOF > /etc/gai.conf
#
#  Configuration for getaddrinfo(3)
#

# The *order* in which queries are carried out is determined by
# the /etc/nsswitch.conf file.
#
# An example:
#
# hosts: files dns
#
# will query the /etc/hosts file first and then query the
# nameserver.
#

#
# The *default* precedence is
#
#label  ::1/128       0
#label  ::/0          1
#label  2002::/16     2
#label ::/96         3
#label ::ffff:0:0/96  4
#label fec0::/10     5
#label fc00::/7      6
#label 2001:0::/32    7

#
# This is the IPv4 precedence.
#
precedence ::ffff:0:0/96  100
EOF
  echo "创建了 /etc/gai.conf 文件并写入了默认配置。"
fi

read -p "您要将 IPv4 还是 IPv6 设置为优先？ (ipv4/ipv6) " priority

case "$priority" in
  ipv4)
    # IPv4 优先 (取消注释或修改 precedence ::ffff:0:0/96  100 这一行)
    sed -i 's/^#\?precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf
    echo "已将 IPv4 设置为优先。"
    ;;
  ipv6)
    # IPv6 优先 (注释掉 precedence ::ffff:0:0/96  100 这一行)
    sed -i 's/^precedence ::ffff:0:0\/96  100/#precedence ::ffff:0:0\/96  100/' /etc/gai.conf
    echo "已将 IPv6 设置为优先。"
    ;;
  *)
    error_exit "无效的选择。请输入 'ipv4' 或 'ipv6'。"
    ;;
esac

exit 0
#!/bin/bash

# --- 脚本说明：为使用 odhcp6c 获取 IPv6 地址的服务器 (如 Scaleway、Online.net) 配置 IPv6 ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 明确告知用户适用场景并要求确认 ---
echo "此脚本仅适用于使用 odhcp6c 获取 IPv6 地址的服务器，例如 Scaleway 和 Online.net 的部分专用服务器。"
echo "如果您不确定您的服务器是否使用 odhcp6c，请不要运行此脚本。"
read -p "您确定要继续吗？ (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "操作已取消。"
  exit 0
fi

# --- 安装依赖 ---
info "安装编译 odhcp6c 所需的依赖..."
case "$OS_ID" in
  debian|ubuntu)
    apt update
    if ! apt install -y cmake git build-essential; then
        error_exit "安装依赖失败 (Debian/Ubuntu)。"
    fi
    ;;
  centos|rhel|rocky|almalinux|oraclelinux|fedora)
    if ! dnf install -y cmake git make gcc;
    then
        error_exit "安装依赖失败 (RHEL/CentOS/Fedora)。"
    fi
    ;;
  opensuse-leap|opensuse-tumbleweed|sles)
     if ! zypper install -y cmake git make gcc;
     then
        error_exit "安装依赖失败 (openSUSE/SLES)。"
     fi
    ;;
  alpine)
    if ! apk add cmake git make musl-dev;
    then
        error_exit "安装依赖失败 (Alpine)。"
    fi
    ;;
  arch)
    if ! pacman -S --noconfirm cmake git make;
    then
        error_exit "安装依赖失败 (Arch Linux)。"
    fi
    ;;
  *)
    error_exit "不支持的发行版 '$OS_ID'。"
    ;;
esac

# --- 下载、编译和安装 odhcp6c ---
info "下载、编译和安装 odhcp6c..."
git clone --depth=1 https://github.com/openwrt/odhcp6c
cd odhcp6c
if ! cmake .; then
    error_exit "cmake 失败。"
fi

if ! make;
then
    error_exit "编译失败。"
fi
if ! make install;
then
    error_exit "安装失败"
fi
cd ..
rm -rf odhcp6c

# --- 获取用户输入 ---
read -p "请输入您的网络接口名称 (例如 enp1s0): " interface
if [[ -z "$interface" ]]; then
  error_exit "网络接口名称不能为空。"
fi

read -p "请输入您的客户端 DUID (例如 00:03:00:01:xx:xx:xx:xx:xx:xx): " client_duid
if [[ -z "$client_duid" ]]; then
  error_exit "客户端 DUID 不能为空。"
fi

read -p "请输入您的 IPv6 前缀长度 (例如 56): " prefix_length
if [[ -z "$prefix_length" ]] || ! [[ "$prefix_length" =~ ^[0-9]+$ ]] || (( prefix_length < 1 || prefix_length > 128 )); then
  error_exit "IPv6 前缀长度无效。请输入一个 1 到 128 之间的数字。"
fi

# --- 运行 odhcp6c (您可能需要根据实际情况调整参数) ---
info "运行 odhcp6c... (此过程可能需要一些时间)"
if ! odhcp6c -c "$client_duid" -P "$prefix_length" -d "$interface";
then
 error_exit "odhcp6c 运行失败，退出"
fi

# --- 获取并配置 IPv6 地址和路由 ---
read -p "请输入您的完整 IPv6 地址和前缀长度 (例如 2001:bc8:xxxx:yyyy::/56): " ipv6_address
if [[ -z "$ipv6_address" ]] || ! [[ "$ipv6_address" =~ ^([0-9a-fA-F:]+:+)+[0-9a-fA-F:.]+(/[0-9]+)?$ ]]; then
  error_exit "IPv6 地址和前缀长度无效。"
fi

if ! ip -6 addr add "$ipv6_address" dev "$interface"; then
  error_exit "添加 IPv6 地址失败。"
fi

if ! ip -6 route add "$ipv6_address" dev "$interface"; then
  warning "添加 IPv6 路由失败 (可能不需要，请手动检查)。"
fi

# --- (可选) 设置开机自启 ---
# 将以下命令添加到 /etc/rc.local (如果文件不存在，则创建)
# (您可能需要根据实际情况调整命令)
cat >> /etc/rc.local <<EOF
sleep 3s
odhcp6c -c $client_duid -P $prefix_length -d $interface
ip -6 a a $ipv6_address dev $interface
ip -6 r a $ipv6_address dev $interface
EOF

echo "Online.net IPv6 配置完成 (可能需要手动调整)。"
echo "请务必检查您的 IPv6 地址和路由是否已正确配置。"
exit 0
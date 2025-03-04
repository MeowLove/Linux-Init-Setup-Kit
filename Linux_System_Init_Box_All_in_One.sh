#!/bin/bash

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   echo "此脚本必须以 root 权限运行。" >&2
   exit 1
fi

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/utils.sh"

# --- 全局变量 ---
detect_os       # 检测操作系统
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# LOG_FILE="$SCRIPT_DIR/init.log"  # 可选
SCRIPT_VERSION="1.0.2"  # 设置版本号

# --- 检查并安装必要的工具 ---
# 检查并安装 dialog
if ! command -v dialog &> /dev/null; then
  echo "安装 dialog..."
  case "$OS_ID" in
    centos|rhel|rocky|almalinux|oraclelinux|fedora)
      dnf install -y dialog
      ;;
    debian|ubuntu)
      apt update && apt install -y dialog
      ;;
    opensuse-leap|opensuse-tumbleweed|sles)
      zypper install -y dialog
      ;;
    alpine)
      apk add dialog
      ;;
    arch)
      pacman -S --noconfirm dialog
      ;;
    *)
      echo "错误：不支持的发行版 '$OS_ID'，无法安装 dialog。" >&2
      exit 1
      ;;
  esac
fi
 case "$OS_ID" in
    centos|rhel|rocky|almalinux|oraclelinux)
      # RHEL 系列 (CentOS 8 及以上, RHEL 8 及以上)
      command -v dnf &> /dev/null || (echo "错误: 没有可用包管理器,将退出" && exit 1)
      dnf install -y curl grep
      ;;
    fedora)
      # Fedora
      command -v dnf &> /dev/null || (echo "错误: 没有可用包管理器,将退出" && exit 1)
      dnf install -y curl grep
      ;;
    debian|ubuntu)
      # Debian 系列
      command -v apt &> /dev/null || (echo "错误: 没有可用包管理器,将退出" && exit 1)
      apt update -y && apt install -y curl grep
      ;;
    opensuse-leap|opensuse-tumbleweed|sles)
      # openSUSE/SLES
      command -v zypper &> /dev/null || (echo "错误: 没有可用包管理器,将退出" && exit 1)
      zypper refresh -y && zypper install -y curl grep
      ;;
    alpine)
      # Alpine Linux
      command -v apk &> /dev/null || (echo "错误: 没有可用包管理器,将退出" && exit 1)
      apk update && apk add curl grep
      ;;
    arch)
      # Arch Linux
      command -v pacman &> /dev/null || (echo "错误: 没有可用包管理器,将退出" && exit 1)
      pacman -Syu --noconfirm curl grep
      ;;
    *)
      echo "错误：不支持的发行版 '$OS_ID'。" >&2
      exit 1
      ;;
  esac
# --- 检测是否使用国内镜像 ---
detect_cn_mirrors

# --- 函数：下载脚本文件 ---
download_script() {
  local script_name="$1"
  local script_path="$SCRIPT_DIR/scripts/$script_name"

  # 检查脚本文件是否已存在
  if [[ -f "$script_path" ]]; then
    return 0  # 文件已存在，直接返回
  fi

  info "下载脚本文件：$script_name"

  # 根据 USE_CN_MIRRORS 选择下载源
  local download_url
  if [[ "$USE_CN_MIRRORS" == "true" ]]; then
    # 使用国内镜像 (您的博客)
    download_url="https://www.cxthhhhh.com/Linux-System-Init-Box/scripts/$script_name"
  else
    # 使用 GitHub
    download_url="https://raw.githubusercontent.com/MeowLove/Linux-System-Init-Box/main/scripts/$script_name"
  fi

  # 下载脚本文件
  if ! curl -fsSL "$download_url" -o "$script_path"; then
    error_exit "下载脚本文件 '$script_name' 失败。请检查网络连接或手动下载脚本。"
  fi

  # 设置脚本文件的执行权限
  chmod +x "$script_path"
}

# --- 定义菜单项 ---
menu_items=(
  "设置主机名"
  "设置 DNS 解析器（自动区分 Global 和 CN）"
  "设置时区"
  "更新系统软件包"
  "安装基础软件"
  "配置 Swap"
  "配置 BBR 拥塞控制"
  "配置 SSH 密钥登录"
  "安装内网穿透工具"
  "关闭防火墙"
  "安装 Docker"
  "修改 Docker 数据目录"
  "配置 iSCSI"
  "配置 IPv6 地址"
  "为 odhcp6c 服务器配置 IPv6 (Online.net、Scaleway)"
  "配置网络优先级 (IPv4/IPv6)"
  "清理系统历史记录"
  "Alpine 安装内网穿透 (Docker)"
  "退出脚本"
)

# --- 创建菜单项编号与脚本文件名的映射 ---
declare -A script_map
script_map=(
  ["1"]="system/hostname_set.sh"
  ["2"]="network/dns_set_resolver.sh"
  ["3"]="system/timezone_set.sh"
  ["4"]="system/system_update.sh"
  ["5"]="packages/packages_install_basic.sh"
  ["6"]="system/swap_config.sh"
  ["7"]="network/network_bbr_config.sh"
  ["8"]="security/ssh_config_password_or_certificate_login.sh"
  ["9"]="net_tools/net_tools_install_zerotier_tailscale.sh"
  ["10"]="security/firewall_disable.sh"
  ["11"]="docker/docker_install.sh"
  ["12"]="docker/docker_modify_data_dir.sh"
  ["13"]="iscsi/iscsi_config_partition_mount.sh"
  ["14"]="network/ipv6_config_add_address.sh"
  ["15"]="network/ipv6_config_online_odhcp6c.sh"
  ["16"]="network/network_config_ip_priority.sh"
  ["17"]="system/system_clear_history.sh"
  ["18"]="net_tools/net_tools_install_zerotier_tailscale_for_alpine_require_docker.sh"
  ["19"]=""
)

# --- 主循环 ---
while true; do
  # --- 构建 dialog 命令 ---
  dialog_options=()
  for i in "${!menu_items[@]}"; do
    tag=$((i + 1))  # 菜单项编号从 1 开始
    item="${menu_items[i]}"
    dialog_options+=("$tag" "$item")
  done

  # 获取镜像源信息
  local mirror_info
  if [[ "$USE_CN_MIRRORS" == "true" ]]; then
    mirror_info="使用国内镜像源"
  else
    mirror_info="使用官方源/国外镜像"
  fi

  # 创建菜单
  choice=$(dialog --clear \
                  --title "Linux 系统初始化脚本 (All in One) 版本：$SCRIPT_VERSION" \
                  --menu "请选择要执行的操作：\n\n作者：CXT\n网址：www.cxthhhhh.com\n镜像源：$mirror_info" 22 70 16 \
                  "${dialog_options[@]}" \
                  2>&1 >/dev/tty)

  # --- 根据选择执行操作 ---
  if [[ -n "$choice" ]]; then
    script_to_run="${script_map[$choice]}"
    if [[ "$script_to_run" != "" ]] && [[ -f "$SCRIPT_DIR/scripts/$script_to_run" ]]; then
      # 先删除本地脚本文件 (如果存在)
      rm -f "$SCRIPT_DIR/scripts/$script_to_run"

      # 下载脚本文件
      download_script "$script_to_run"

      info "执行 $script_to_run..."
      bash "$SCRIPT_DIR/scripts/$script_to_run" < /dev/tty

      # 执行完脚本后，等待用户按键
      echo
      echo "操作完成，请按任意键返回主菜单..."
      read -n 1 -s -r
      # sleep 3 # 可选：暂停 3 秒

    elif [[ "$script_to_run" == "" ]]; then
      # 用户选择了退出选项
      info "退出脚本。"
      break # 退出循环
    else
      error_exit "错误：未找到脚本文件 '$script_to_run'。"
    fi
  else
    # 用户取消了操作 (例如按下了 Esc 键)
    info "用户取消操作。"
    break # 退出循环
  fi
done

exit 0
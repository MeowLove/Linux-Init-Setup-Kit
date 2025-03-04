#!/bin/bash

# --- 脚本说明：配置 iSCSI 启动器、连接、分区、格式化和挂载 ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 配置 iSCSI 启动器 ---

read -p "您要配置 iSCSI 启动器吗？ (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # 1. 安装 iSCSI 启动器软件包
  case "$OS_ID" in
    centos|rhel|rocky|almalinux|oraclelinux|fedora)
      # RHEL 系列
      check_command dnf
      if ! dnf install -y iscsi-initiator-utils; then
        error_exit "安装 iscsi-initiator-utils 软件包失败。"
      fi
      ;;
    debian|ubuntu)
      # Debian 系列
      check_command apt
      if ! apt-get install -y open-iscsi; then
        error_exit "安装 open-iscsi 软件包失败。"
      fi
      ;;
    opensuse-leap|opensuse-tumbleweed|sles)
      # openSUSE/SLES
      check_command zypper
      if ! zypper install -y open-iscsi; then
        error_exit "安装 open-iscsi 软件包失败。"
      fi
      ;;
    alpine)
      # Alpine Linux
      check_command apk
      if ! apk add open-iscsi; then
        error_exit "安装 open-iscsi 软件包失败。"
      fi
      ;;
    arch)
      # Arch Linux
      check_command pacman
      if ! pacman -S --noconfirm open-iscsi; then
        error_exit "安装 open-iscsi 软件包失败。"
      fi
      ;;
    *)
      error_exit "不支持的发行版 '$OS_ID'。"
      ;;
  esac

  # 2. 启动并启用 iSCSI 服务
  if [[ "$OS_ID" == "alpine" ]]; then
    if ! rc-service iscsid start; then
      error_exit "启动 iscsid 服务失败。"
    fi
    if ! rc-update add iscsid default; then
      error_exit "将 iscsid 服务添加到默认运行级别失败。"
    fi
    if ! rc-service iscsi start; then  # Alpine 需要单独启动 iscsi 服务
      error_exit "启动 iscsi 服务失败。"
    fi
    if ! rc-update add iscsi boot; then
      error_exit "将 iscsi 服务添加到启动运行级别失败。"
    fi
  else
    if ! systemctl start iscsid; then
      error_exit "启动 iscsid 服务失败。"
    fi
    if ! systemctl enable iscsid; then
      error_exit "启用 iscsid 服务失败。"
    fi
    if ! systemctl start iscsi; then
      error_exit "启动 iscsi 服务失败。"
    fi
    if ! systemctl enable iscsi; then
      error_exit "启用 iscsi 服务失败。"
    fi
  fi

  # 3. 获取 InitiatorName
  local initiator_name
  if [[ "$OS_ID" == "alpine" ]]; then
    initiator_name=$(cat /etc/iscsi/initiatorname.iscsi | awk -F '=' '{print $2}')
  else
    initiator_name=$(cat /etc/iscsi/initiatorname.iscsi | awk -F '=' '{print $2}')
  fi

  echo "iSCSI 启动器已安装并启动。您的 InitiatorName 为：$initiator_name"
  echo "请提供以下信息以连接到 iSCSI 目标："
  read -p "  iSCSI 目标 IP 地址或域名: " target_ip
  read -p "  iSCSI 目标端口 (默认为 3260): " target_port
  read -p "  iSCSI 目标 IQN: " target_iqn

  # 4. 发现 iSCSI 目标
  if [[ -z "$target_port" ]]; then
    target_port=3260
  fi
  if ! iscsiadm -m discovery -t st -p "$target_ip:$target_port"; then
    error_exit "发现 iSCSI 目标失败。"
  fi

  # 5. 登录 iSCSI 目标
  if ! iscsiadm -m node -T "$target_iqn" -p "$target_ip:$target_port" -l; then
    error_exit "登录 iSCSI 目标失败。"
  fi

  # 6. 查找 iSCSI 设备
  sleep 5 # 等待设备出现
  local iscsi_device=$(lsblk -o NAME,TYPE | grep 'disk' | awk '{print $1}' | tail -n 1)

  if [[ -z "$iscsi_device" ]]; then
    error_exit "错误：未找到 iSCSI 设备。请检查 iSCSI 连接和目标配置。"
  fi

  echo "检测到 iSCSI 设备: /dev/$iscsi_device"

  # 7. 分区 iSCSI 设备 (使用 parted)
  read -p "您要对 iSCSI 设备 (/dev/$iscsi_device) 进行分区吗？ (y/N) " -n 1 -r
  echo
  local iscsi_partition
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! parted -s /dev/$iscsi_device mklabel gpt; then
      error_exit "创建 GPT 分区表失败。"
    fi
    if ! parted -s /dev/$iscsi_device mkpart primary 0% 100%; then
      error_exit "创建主分区失败。"
    fi
    iscsi_partition="${iscsi_device}1" # 假设分区为 1
    echo "iSCSI 设备已分区：/dev/$iscsi_partition"
  else
    iscsi_partition=$iscsi_device # 不分区，直接使用整个磁盘
  fi

  # 8. 格式化 iSCSI 分区/设备
  read -p "请输入要使用的文件系统类型 (例如 ext4, xfs, 留空则不格式化): " fs_type
  if [[ -n "$fs_type" ]]; then
    case "$fs_type" in
      ext4)
        if ! mkfs.ext4 /dev/$iscsi_partition; then
          error_exit "格式化 iSCSI 分区/设备为 ext4 失败。"
        fi
        ;;
      xfs)
        if ! mkfs.xfs /dev/$iscsi_partition; then
          error_exit "格式化 iSCSI 分区/设备为 xfs 失败。"
        fi
        ;;
      *)
        error_exit "错误：不支持的文件系统类型 '$fs_type'。"
        ;;
    esac
    echo "iSCSI 分区/设备已格式化为 $fs_type。"
  fi

  # 9. 挂载 iSCSI 分区/设备
  read -p "请输入挂载点目录（例如 /mnt/iscsi, 留空则不挂载）: " mount_point
  if [[ -n "$mount_point" ]]; then
    if [[ ! -d "$mount_point" ]]; then
      # 不存在则创建
      mkdir -p "$mount_point"
    fi
    if ! mount /dev/$iscsi_partition "$mount_point"; then
      error_exit "挂载 iSCSI 分区/设备失败。"
    fi

    # 10. 添加到 /etc/fstab
    if ! echo "UUID=$(blkid -s UUID -o value /dev/$iscsi_partition) $mount_point $fs_type defaults,_netdev 0 0" >> /etc/fstab; then
      error_exit "将 iSCSI 挂载信息写入 /etc/fstab 失败。"
    fi

    echo "iSCSI 分区/设备已挂载到 $mount_point 并已添加到 /etc/fstab。"
  else
    echo "未挂载。"
  fi
fi

exit 0
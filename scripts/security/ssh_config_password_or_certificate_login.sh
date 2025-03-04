#!/bin/bash

# --- 脚本说明：设置密码登录 或 证书登录 ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
  error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 函数：更新 cloud-init 配置 ---
update_cloud_init_config() {
  local permit_root_login password_auth config_file

  # 函数：从配置文件中读取值
  get_config_value() {
    local file="$1"
    local key="$2"
    # 使用 grep 和 awk 获取配置值，忽略注释和空行
    grep -i "^[[:space:]]*${key}[[:space:]]" "$file" | awk '{print $2}' | head -n 1
  }

  # 从 /etc/ssh/sshd_config 读取默认值
  permit_root_login=$(get_config_value "/etc/ssh/sshd_config" "PermitRootLogin")
  password_auth=$(get_config_value "/etc/ssh/sshd_config" "PasswordAuthentication")

  # 遍历 /etc/ssh/sshd_config.d/*.conf 并覆盖默认值
  for config_file in /etc/ssh/sshd_config.d/*.conf; do
    if [[ -f "$config_file" ]]; then
      # 获取当前文件的配置值, 只有值存在时，才更新.
      local current_permit_root_login=$(get_config_value "$config_file" "PermitRootLogin")
      local current_password_auth=$(get_config_value "$config_file" "PasswordAuthentication")

      [[ -n "$current_permit_root_login" ]] && permit_root_login="$current_permit_root_login"
      [[ -n "$current_password_auth" ]] && password_auth="$current_password_auth"

    fi
  done

  # 根据配置推断 cloud-init 配置 (cloud-init 的 disable_root 与 sshd 的 PermitRootLogin 相反)
  if [[ "$permit_root_login" == "yes" ]]; then
    permit_root_login="false"  # cloud-init 中 disable_root 为 false 时才允许 root 登录
  else
    permit_root_login="true"
  fi
  if [[ "$password_auth" == "yes" ]]; then
    password_auth="true"
  else
    password_auth="false"
  fi

    # 修改 /etc/cloud/cloud.cfg (如果存在)
  if [[ -f /etc/cloud/cloud.cfg ]]; then
    # 备份 (如果备份不存在)
    if [[ ! -f /etc/cloud/cloud.cfg.bak ]]; then
      cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak
    fi
    sed -i "s/^#\?disable_root:.*$/disable_root: $permit_root_login/" /etc/cloud/cloud.cfg
    sed -i "s/^#\?ssh_pwauth:.*$/ssh_pwauth: $password_auth/" /etc/cloud/cloud.cfg
  fi

  # 遍历 /etc/cloud/cloud.cfg.d/*.cfg (如果存在)
  for cloud_config in /etc/cloud/cloud.cfg.d/*.cfg; do
    if [[ -f "$cloud_config" ]]; then
      # 备份 (如果备份不存在)
      if [[ ! -f "$cloud_config.bak" ]]; then
        cp "$cloud_config" "$cloud_config.bak"
      fi
      sed -i "s/^#\?disable_root:.*$/disable_root: $permit_root_login/" "$cloud_config"
      sed -i "s/^#\?ssh_pwauth:.*$/ssh_pwauth: $password_auth/" "$cloud_config"
    fi
  done
}

# --- 配置 SSH ---
# 1. 允许 root 账号 SSH 登录
# 1.1 备份文件
if [[ ! -f /etc/ssh/sshd_config.bak ]]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
fi
# 1.2 修改主配置文件
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# 1.3 检查并修改 sshd_config.d 目录下的配置文件 (如果存在)
for sshd_config in /etc/ssh/sshd_config.d/*.conf; do
  if [[ -f "$sshd_config" ]]; then
    # 备份 (如果备份不存在)
    if [[ ! -f "$sshd_config.bak" ]]; then
      cp "$sshd_config" "$sshd_config.bak"
    fi
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' "$sshd_config"
  fi
done

# 1.4 同步更新 cloud-init 配置
update_cloud_init_config

# 2. 询问用户要配置的登录方式
read -p "您要配置为密码登录 (password) 还是证书登录 (pubkey)？ (password/pubkey) " auth_method

# 使用 case 语句处理用户输入
case "$auth_method" in
  password)
    # --- 场景：配置为密码登录 ---
    echo "将配置为密码登录。"

    # 强制要求用户设置/修改当前用户密码
    echo "请为当前用户 ($USER) 设置密码："
    passwd "$USER"

    # 启用密码登录
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    # 同步修改 sshd_config.d 中的配置
    for sshd_config in /etc/ssh/sshd_config.d/*.conf; do
      if [[ -f "$sshd_config" ]]; then
        sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$sshd_config"
      fi
    done
    # 同步更新 cloud-init 配置
    update_cloud_init_config

    # 禁用证书登录 (可选)
    read -p "是否要禁用证书登录并删除现有公钥？ (y/N) " disable_pubkey
    if [[ "$disable_pubkey" =~ ^[Yy]$ ]]; then
      sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' /etc/ssh/sshd_config
      # 同步修改 sshd_config.d 中的配置
      for sshd_config in /etc/ssh/sshd_config.d/*.conf; do
        if [[ -f "$sshd_config" ]]; then
          sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' "$sshd_config"
        fi
      done
      # 同步更新 cloud-init 配置 (即使禁用了证书登录也要更新)
      update_cloud_init_config
      rm -rf "$HOME/.ssh"  # 删除当前用户的 .ssh 目录
      echo "证书登录已禁用，公钥已删除。"
    fi
    ;;

  pubkey)
    # --- 场景：配置为证书登录 ---
    echo "将配置为证书登录。"

    # 启用证书登录
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    # 同步修改 sshd_config.d 中的配置
    for sshd_config in /etc/ssh/sshd_config.d/*.conf; do
      if [[ -f "$sshd_config" ]]; then
        sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$sshd_config"
      fi
    done
    # 同步更新 cloud-init 配置
    update_cloud_init_config

    # 提示用户粘贴公钥或自动生成密钥对
    read -p "您要粘贴公钥 (paste) 还是自动生成密钥对 (generate)？ (paste/generate) " key_method
    case "$key_method" in
      paste)
        # 粘贴公钥
        if [[ ! -d "$HOME/.ssh" ]]; then
          mkdir -p "$HOME/.ssh"
          chmod 700 "$HOME/.ssh"
        fi
        # 检查 authorized_keys 文件是否存在
        if [[ -f "$HOME/.ssh/authorized_keys" ]]; then
          read -p "检测到已存在的 authorized_keys 文件。您要追加公钥 (append) 还是覆盖文件 (overwrite)？ (append/overwrite) " append_or_overwrite
          case "$append_or_overwrite" in
            append)
              echo "请粘贴您的 SSH 公钥 (以 ssh-rsa 或 ssh-ed25519 开头)，然后按 Ctrl+D："
              cat >> "$HOME/.ssh/authorized_keys"
              ;;
            overwrite)
              echo "请粘贴您的 SSH 公钥 (以 ssh-rsa 或 ssh-ed25519 开头)，然后按 Ctrl+D："
              cat > "$HOME/.ssh/authorized_keys"  # 使用 > 覆盖
              ;;
            *)
              error_exit "无效的选择。"
              ;;
          esac
        else
          echo "请粘贴您的 SSH 公钥 (以 ssh-rsa 或 ssh-ed25519 开头)，然后按 Ctrl+D："
          cat >> "$HOME/.ssh/authorized_keys"  # 追加到新文件
        fi
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "公钥已添加。"
        ;;

      generate)
        # 自动生成密钥对
        echo "将自动生成 SSH 密钥对。请记住保存私钥！"
        ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
        cat "$HOME/.ssh/id_ed25519.pub" >> "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "密钥对已生成。"
        echo "私钥路径：$HOME/.ssh/id_ed25519"
        echo "请务必保存好您的私钥！"
        ;;

      *)
        error_exit "无效的选择。"
        ;;
    esac

    # 禁用密码登录 (可选)
    read -p "是否要禁用密码登录？ (y/N) " disable_password
    if [[ "$disable_password" =~ ^[Yy]$ ]]; then
      sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
      # 同步修改 sshd_config.d 中的配置
      for sshd_config in /etc/ssh/sshd_config.d/*.conf; do
        if [[ -f "$sshd_config" ]]; then
          sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"
        fi
      done
      # 同步更新 cloud-init 配置 (即使禁用了密码登录也要更新)
      update_cloud_init_config
      echo "密码登录已禁用。"
    else
      echo "密码登录未禁用。"
    fi
    ;;

  *)
    error_exit "无效的选择。"
    ;;
esac

# 4. 重启 SSHD 服务 (可选)
read -p "是否要立即重启 SSHD 服务以使配置生效？ (y/N) " restart_sshd
if [[ "$restart_sshd" =~ ^[Yy]$ ]]; then
  # 根据不同的操作系统使用不同的重启命令
  case "$OS_ID" in
    centos|rhel|rocky|almalinux|oraclelinux|fedora)
      systemctl restart sshd
      ;;
    debian|ubuntu)
      systemctl restart ssh.service
      ;;
    opensuse-leap|opensuse-tumbleweed|sles)
      systemctl restart sshd
      ;;
    alpine)
      rc-service sshd restart
      ;;
    arch)
      systemctl restart sshd.service
      ;;
    *)
      error_exit "不支持的发行版 '$OS_ID'。"
      ;;
  esac
  echo "SSHD 服务已重启。"
fi

exit 0
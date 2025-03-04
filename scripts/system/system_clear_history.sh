#!/bin/bash

# --- 脚本说明：清除系统日志和用户命令历史记录 ---
# 警告：此操作会删除日志和历史记录，请谨慎操作！

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 清理历史记录 ---

read -p "警告：此操作将清除系统日志和用户命令历史记录。您确定要继续吗？ (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  info "开始清除系统日志..."

  # 清除系统日志
  case "$OS_ID" in
    centos|rhel|rocky|almalinux|oraclelinux|fedora)
      # RHEL 系列
      check_command journalctl
      if ! journalctl --vacuum-time=1s; then
        warning "清理 systemd 日志失败 (journalctl)。"
      fi
      # 清空传统日志文件
      echo > /var/log/wtmp
      echo > /var/log/btmp
      echo > /var/log/lastlog
      echo > /var/log/secure
      echo > /var/log/messages
      cat /dev/null > /var/log/maillog
      ;;

    debian|ubuntu)
      # Debian 系列
      # 删除 /var/log 下的日志文件
      rm -rf /var/log/*.log /var/log/**/*.log
      # 清空传统日志文件
      echo > /var/log/wtmp
      echo > /var/log/btmp
      echo > /var/log/lastlog
      echo > /var/log/auth.log
      echo > /var/log/user.log
      cat /dev/null > /var/log/syslog # 兼容处理
      # 清理 /var/tmp 和 /tmp
      rm -rf /var/tmp/* /tmp/*
      ;;

    opensuse-leap|opensuse-tumbleweed|sles)
      # openSUSE/SLES
      # 删除 /var/log 下的日志文件
      rm -rf /var/log/*.log /var/log/**/*.log
      # 清空传统日志文件
      echo > /var/log/wtmp
      echo > /var/log/btmp
      echo > /var/log/lastlog
      echo > /var/log/messages
      cat /dev/null > /var/log/mail.info  # 可能需要根据实际情况调整
      cat /dev/null > /var/log/mail.log   # 可能需要根据实际情况调整
      # 清理 /var/tmp 和 /tmp
      rm -rf /var/tmp/* /tmp/*
      ;;

    alpine)
      # Alpine Linux
      # 删除 /var/log 下的所有文件
      rm -rf /var/log/*
      # 清空传统日志文件 (Alpine 可能没有这些文件，但为了兼容性，保留这些命令)
      echo > /var/log/wtmp
      echo > /var/log/btmp
      echo > /var/log/lastlog
      ;;

    arch)
      # Arch Linux
      check_command journalctl
      if ! journalctl --vacuum-time=1s; then
        warning "清理 systemd 日志失败 (journalctl)。"
      fi
      # 删除 /var/log/journal 下的日志
      rm -rf /var/log/journal/*
      # 清空传统日志文件
      echo > /var/log/wtmp
      echo > /var/log/btmp
      echo > /var/log/lastlog
      ;;

    *)
      error_exit "不支持的发行版 '$OS_ID'。"
      ;;
  esac

  info "清除用户命令历史记录..."

  # 清除用户命令历史记录
  HISTFILE=~/.bash_history
  if [ -f "$HISTFILE" ]; then
    echo > "$HISTFILE"
  fi
  history -c
  # echo > .bash_history  # 移除这行，避免重复清空
  history -cw          # 将当前会话的历史记录写入文件 (此时文件为空)

  success "历史记录已清除。"
else
  echo "历史记录清除操作已取消。"
fi

exit 0
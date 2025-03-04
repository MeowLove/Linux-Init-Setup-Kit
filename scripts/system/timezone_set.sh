#!/bin/bash

# --- 脚本说明：设置 Linux 系统的时区 ---

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 设置时区 ---

# 常用时区列表 (调整顺序)
declare -A timezones
# 亚洲
timezones["亚洲/香港"]="Asia/Hong_Kong"
timezones["亚洲/北京/上海"]="Asia/Shanghai"
timezones["亚洲/东京"]="Asia/Tokyo"
timezones["亚洲/首尔"]="Asia/Seoul"
timezones["亚洲/新加坡"]="Asia/Singapore"
# 美洲
timezones["美洲/纽约"]="America/New_York"
timezones["美洲/洛杉矶"]="America/Los_Angeles"
timezones["美洲/芝加哥"]="America/Chicago"
timezones["美洲/墨西哥城"]="America/Mexico_City"
timezones["美洲/圣保罗"]="America/Sao_Paulo"
# 欧洲
timezones["欧洲/伦敦"]="Europe/London"
timezones["欧洲/巴黎"]="Europe/Paris"
timezones["欧洲/柏林"]="Europe/Berlin"
timezones["欧洲/莫斯科"]="Europe/Moscow"
# 大洋洲
timezones["大洋洲/悉尼"]="Australia/Sydney"
#非洲
timezones["非洲/约翰内斯堡"]="Africa/Johannesburg"
# UTC
timezones["UTC"]="UTC"

# 用于菜单显示的有序数组
timezone_keys=(
  "亚洲/香港"
  "亚洲/北京/上海"
  "亚洲/东京"
  "亚洲/首尔"
  "亚洲/新加坡"
  "美洲/纽约"
  "美洲/洛杉矶"
  "美洲/芝加哥"
  "美洲/墨西哥城"
  "美洲/圣保罗"
  "欧洲/伦敦"
  "欧洲/巴黎"
  "欧洲/柏林"
  "欧洲/莫斯科"
  "大洋洲/悉尼"
  "非洲/约翰内斯堡"
  "UTC"
)

# 手动构建菜单
echo "请选择时区："
i=1
for tz in "${timezone_keys[@]}"; do
  echo "$i) $tz"
  i=$((i + 1))
done

read -p "请选择时区编号: " choice

# 验证用户输入
if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#timezone_keys[@]}" ]]; then
  error_exit "无效的选择。"
fi

# 获取选择的时区 ID
selected_tz="${timezone_keys[$((choice - 1))]}"
timezone="${timezones[$selected_tz]}"

# 根据选择设置时区
case "$OS_ID" in
    centos|rhel|rocky|almalinux|oraclelinux|fedora|debian|ubuntu|opensuse-leap|opensuse-tumbleweed|sles)
      # 大部分发行版 (使用 timedatectl)
      timedatectl set-timezone "$timezone"
      ;;
    alpine)
      # Alpine Linux
      apk add tzdata
      if [[ $? -eq 0 ]];then
        cp /usr/share/zoneinfo/$timezone /etc/localtime
      else
        error_exit "安装tzdata失败,退出"
      fi
      ;;
    arch)
      # Arch Linux
      ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
      ;;
    *)
      error_exit "不支持的发行版 '$OS_ID'。"
      ;;
esac

echo "时区已设置为：$(timedatectl status | grep 'Time zone' | awk '{print $3}')"
exit 0
#!/bin/bash

# --- 脚本说明：配置 BBR (Bottleneck Bandwidth and Round-trip propagation time) 拥塞控制算法 ---

# --- 导入工具函数 ---
source "$(dirname "$(dirname "$(readlink -f "$0")")")/utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 检查 BBR 支持 ---

# 检查内核版本 (需要 >= 4.9)
kernel_version=$(uname -r | cut -d '.' -f 1,2)
if [[ "$(echo "$kernel_version < 4.9" | bc)" -eq 1 ]]; then
  warning "您的内核版本 ($kernel_version) 可能不支持 BBR。建议升级内核至 4.9 或更高版本。"
  exit 0 # 退出，不进行后续操作
fi

# 检查 tcp_bbr 模块是否已加载
if ! lsmod | grep -q "tcp_bbr"; then
  warning "tcp_bbr 模块未加载。BBR 可能无法正常工作。"
  # 尝试加载模块 (可选)
  # modprobe tcp_bbr
fi

# --- 配置 BBR ---

# 检查是否已启用 (避免重复配置)
# current_cc=$(sysctl -n net.ipv4.tcp_congestion_control) # 注释掉旧的
if sysctl -n net.ipv4.tcp_congestion_control | grep -q "bbr"; then  # 使用 grep 检查
  info "BBR 已启用 (当前拥塞控制算法：$(sysctl -n net.ipv4.tcp_congestion_control))。无需重复配置。"
  exit 0
fi

# 添加 BBR 配置到 /etc/sysctl.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

# 使配置生效
if sysctl -p &> /dev/null; then
  success "BBR 已配置。"
  info "当前拥塞控制算法：$(sysctl -n net.ipv4.tcp_congestion_control)"
else
  error_exit "BBR 配置失败 (sysctl -p 执行出错)。"
fi

exit 0
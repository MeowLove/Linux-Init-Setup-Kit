#!/bin/bash

# --- 脚本说明：修改 Docker 数据目录 (可选) ---
# 警告：修改 Docker 数据目录可能会导致现有容器和镜像无法访问！

# --- 导入工具函数 ---
source "$(dirname "$(readlink -f "$0")")/../../cxt-utils.sh" # 已修改

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 修改 Docker 数据目录 (可选) ---

read -p "您要修改 Docker 数据目录吗？ (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # 再次警告用户
  warning "警告：修改 Docker 数据目录可能会导致现有容器和镜像无法访问！"
  read -p "请再次确认您要修改 Docker 数据目录吗？ (y/N) " -n 1 -r
  echo
  if [[ $REPLY != [Yy] ]]; then
    echo "Docker 数据目录未修改。"
    exit 0
  fi

  read -p "请输入新的 Docker 数据目录路径（例如 /data/docker）: " new_docker_dir

  # 验证新路径 (简单示例，可以根据需要扩展)
  if [[ -z "$new_docker_dir" ]] || [[ ! "$new_docker_dir" =~ ^/.*$ ]]; then
    error_exit "错误：Docker 数据目录路径无效。请输入一个绝对路径。"
  fi

  # 1. 停止 Docker 服务
  info "停止 Docker 服务..."
  if [[ "$OS_ID" == "alpine" ]]; then
    if ! /etc/init.d/docker stop; then
      error_exit "停止 Docker 服务失败 (Alpine)。"
    fi
  else
    if ! systemctl stop docker; then
      error_exit "停止 Docker 服务失败。"
    fi
  fi

  # 2. 创建新的数据目录
  info "创建新的数据目录..."
  if ! mkdir -p "$new_docker_dir"; then
    error_exit "创建目录 '$new_docker_dir' 失败。"
  fi

  # 3. 迁移现有数据（如果存在）
  if [[ -d "/var/lib/docker" ]]; then
    info "迁移现有数据..."
    if ! rsync -avz /var/lib/docker/ "$new_docker_dir"; then
      error_exit "迁移 Docker 数据失败。"
    fi

    # 4. 删除旧的 Docker 数据目录
    info "删除旧的 Docker 数据目录..."
    if ! rm -rf /var/lib/docker; then
      warning "删除旧的 Docker 数据目录失败。请手动删除。"
    fi
  fi

  # 5. 修改 Docker 配置文件
  info "修改 Docker 配置文件..."
  if [[ -f /etc/docker/daemon.json ]];
  then
      #已存在配置文件
      if ! grep -q '"data-root"' /etc/docker/daemon.json;
  then
          #不存在data-root
          if ! sed -i '/^{'/'a\  "data-root": "'"$new_docker_dir"'",' /etc/docker/daemon.json; then
            error_exit "修改 /etc/docker/daemon.json 文件失败 (添加 data-root)。"
          fi
      else
          #存在data-root,则修改
          if ! sed -i "s|\"data-root\": \".*\"|\"data-root\": \"$new_docker_dir\"|g" /etc/docker/daemon.json; then
            error_exit "修改 /etc/docker/daemon.json 文件失败 (更新 data-root)。"
          fi
      fi
  else
      #不存在配置文件
      if ! echo '{
  "data-root": "'"$new_docker_dir"'"
}' > /etc/docker/daemon.json; then
        error_exit "创建 /etc/docker/daemon.json 文件失败。"
      fi
  fi

  # 6. 启动 Docker 服务
  info "启动 Docker 服务..."
  if [[ "$OS_ID" == "alpine" ]]; then
     if !  /etc/init.d/docker start;
     then
        error_exit "启动docker失败"
     fi
  else
    if ! systemctl start docker; then
      error_exit "启动 Docker 服务失败。"
    fi
  fi

  success "Docker 数据目录已修改为 $new_docker_dir"
else
  echo "Docker 数据目录未修改。"
fi

exit 0
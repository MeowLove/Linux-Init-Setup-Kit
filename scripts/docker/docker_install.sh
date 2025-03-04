#!/bin/bash

# --- 脚本说明：安装 Docker Engine 及其相关组件 ---

# --- 导入工具函数 ---
source "$(dirname "$(dirname "$(readlink -f "$0")")")/utils.sh"

# --- 确保以 root 权限运行 ---
if [[ "$EUID" -ne 0 ]]; then
   error_exit "此脚本必须以 root 权限运行。"
fi

# --- 获取全局变量 ---
detect_os

# --- 函数：安装依赖包 (添加重试机制) ---
# 参数：
#   $1: 要安装的软件包名
install_dependency() {
  local retry_count=3
  local retry_delay=5

  if ! command -v "$1" &> /dev/null; then
    info "安装依赖：$1"
    while [[ $retry_count -gt 0 ]]; do
      case "$OS_ID" in
        debian|ubuntu)
          apt-get update && apt-get install -y "$1" && return 0
          ;;
        rhel|centos|rocky|almalinux|oraclelinux|fedora)
          dnf install -y "$1" && return 0
          ;;
        opensuse-leap|opensuse-tumbleweed|sles)
          zypper --non-interactive install "$1" && return 0
          ;;
        alpine)
          apk add "$1" && return 0
          ;;
        arch)
          pacman -Syu --noconfirm "$1" && return 0
          ;;
        *)
          error_exit "不支持的操作系统：$OS_ID"
          ;;
      esac

      retry_count=$((retry_count - 1))
      if [[ $retry_count -gt 0 ]]; then
        warning "安装失败，${retry_delay} 秒后重试（剩余 ${retry_count} 次）..."
        sleep "$retry_delay"
      fi
    done
    error_exit "无法安装依赖 $1"
  fi
}

# --- 函数：卸载旧版本 Docker ---
uninstall_old_docker() {
  info "卸载旧版本 Docker..."
  case "$OS_ID" in
    debian|ubuntu)
      dpkg -l | grep -E 'docker|containerd|runc' | awk '{print $2}' | xargs -r apt-get remove -y || true
      ;;
    rhel|centos|rocky|almalinux|oraclelinux|fedora)
      rpm -qa | grep -E 'docker|containerd|podman|buildah' | xargs -r dnf remove -y || true
      ;;
    opensuse-leap|opensuse-tumbleweed|sles)
      rpm -qa | grep -E 'docker|containerd' | xargs -r zypper --non-interactive remove -y || true
      ;;
    alpine)
      apk info -e | grep -E 'docker|containerd' | xargs -r apk del || true
      ;;
    arch)
      pacman -Rns $(pacman -Qq | grep -E 'docker|containerd') || true
      ;;
    *)
      error_exit "不支持的操作系统：$OS_ID"
      ;;
  esac
}

# --- 函数: 设置 Debian/Ubuntu 的仓库 ---
setup_debian_ubuntu_repo() {
  # 添加 Docker 的官方 GPG 密钥
  info "添加 Docker GPG 密钥..."
  local gpg_url="https://$(if [[ "$USE_CN_MIRRORS" == "true" ]]; then echo 'mirrors.aliyun.com/docker-ce'; else echo 'download.docker.com'; fi)/linux/$OS_ID/gpg"
  curl -fsSL "$gpg_url" | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # 设置稳定存储库
  local repo_url="https://$(if [[ "$USE_CN_MIRRORS" == "true" ]]; then echo 'mirrors.aliyun.com/docker-ce'; else echo 'download.docker.com'; fi)/linux/$OS_ID"
  local repo_config="deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $repo_url $(lsb_release -cs) stable"
  echo "$repo_config" | tee /etc/apt/sources.list.d/docker.list > /dev/null
}

# --- 函数: 设置 RHEL 系列的仓库 ---
setup_rhel_repo() {
  # 导入 Docker 镜像源
  local repo_url="https://$(if [[ "$USE_CN_MIRRORS" == "true" ]]; then echo 'mirrors.aliyun.com/docker-ce'; else echo 'download.docker.com'; fi)/linux/rhel/docker-ce.repo"
  dnf config-manager --add-repo "$repo_url"
}

# --- 函数: 设置 Fedora 的仓库 ---
setup_fedora_repo() {
  # 导入源
  local repo_url="https://$(if [[ "$USE_CN_MIRRORS" == "true" ]]; then echo 'mirrors.aliyun.com/docker-ce'; else echo 'download.docker.com'; fi)/linux/fedora/docker-ce.repo"
  dnf config-manager --add-repo "$repo_url"
}

# --- 函数: 设置 SLES/OpenSUSE 的仓库 ---
setup_sles_repo() {
  local repo_url="https://$(if [[ "$USE_CN_MIRRORS" == "true" ]]; then echo 'mirror.azure.cn/docker-ce'; else echo 'download.docker.com'; fi)/linux/suse/docker-ce.repo"
  zypper addrepo -f -g "$repo_url"
}

# --- 函数：安装 Docker (Debian/Ubuntu) ---
install_docker_debian_ubuntu() {
  # 1. 安装必要的软件包以允许 apt 通过 HTTPS 使用存储库
  if ! apt-get install -y \
    apt-transport-https \
    ca-certificates \
    lsb-release; then
    error_exit "安装依赖包失败 (Debian/Ubuntu)。"
  fi

  # 2. 设置仓库
  setup_debian_ubuntu_repo

  # 3. 更新 apt 软件包索引
  if ! apt-get update; then
    error_exit "更新 apt 软件包索引失败 (Debian/Ubuntu)。"
  fi

  # 4. 安装 Docker Engine、containerd 和 Docker Compose
  if ! apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
    error_exit "安装 Docker 失败 (Debian/Ubuntu)。"
  fi
}

# --- 函数：安装 Docker (RHEL/CentOS/Rocky/Alma/Oracle) ---
install_docker_rhel() {
  # 1. 安装 yum-utils (dnf-utils)
  if ! dnf install -y dnf-utils; then
    error_exit "安装 dnf-utils 失败 (RHEL 系列)。"
  fi

  # 2. 设置仓库
  setup_rhel_repo

  # 3. 安装 Docker 全部软件包
  if ! dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin; then
    error_exit "安装 Docker 失败 (RHEL 系列)。"
  fi
}

# --- 函数：安装 Docker (Fedora) ---
install_docker_fedora() {
  # 1. 安装 dnf-plugins-core
  if ! dnf install -y dnf-plugins-core; then
    error_exit "安装 dnf-plugins-core 失败 (Fedora)。"
  fi

  # 2. 设置仓库
  setup_fedora_repo

  # 3. 安装 docker
  if ! dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
    error_exit "安装 Docker 失败 (Fedora)。"
  fi
}

# --- 函数：安装 Docker (openSUSE/SLES) ---
install_docker_sles() {
  # 1. 设置仓库
  setup_sles_repo

  # 2. 安装 docker
  if ! zypper --non-interactive install docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
    error_exit "安装 Docker 失败 (openSUSE/SLES)。"
  fi
}

# --- 函数：安装 Docker (Alpine) ---
install_docker_alpine() {
  # 1. 更新软件源
  if ! apk update; then
    error_exit "更新 Alpine 软件源失败。"
  fi

  # 2. 安装 docker
  if ! apk add docker docker-compose; then
    error_exit "安装 Docker 失败 (Alpine)。"
  fi
}

# --- 函数：安装 Docker (Arch Linux) ---
install_docker_arch() {
  # 1. 更新 pacman 数据库
  if ! pacman -Syu --noconfirm; then
    error_exit "更新 pacman 数据库失败 (Arch Linux)。"
  fi

  # 2. 安装 Docker 和 Docker Compose
  if ! pacman -S --noconfirm docker docker-compose; then
    error_exit "安装 Docker 失败 (Arch Linux)。"
  fi
}

# --- 函数: 启动 Docker ---
# 启动 Docker 服务，并设置开机自启
start_docker() {
  info "启动 Docker 服务..."
  if [[ "$OS_ID" == "alpine" ]]; then
    if [[ $(apk info -v | grep 'musl-' | cut -d '-' -f 2 | cut -d '.' -f 1) -ge 3 ]] && [[ $(apk info -v | grep 'musl-' | cut -d '-' -f 2 | cut -d '.' -f 2) -ge 2 ]]; then
      # 较新的版本
      if ! systemctl start docker; then
        error_exit "启动 Docker 服务失败 (Alpine, systemctl)。"
      fi
      if ! systemctl enable docker; then
        error_exit "设置 Docker 开机自启失败 (Alpine, systemctl)。"
      fi
    else
      # 旧的版本
      if ! /etc/init.d/docker start; then
        error_exit "启动 Docker 服务失败 (Alpine, /etc/init.d/docker)。"
      fi
      if ! rc-update add docker default; then
        error_exit "设置 Docker 开机自启失败 (Alpine, rc-update)。"
      fi
    fi
  else
    if ! systemctl start docker; then
      error_exit "启动 Docker 服务失败 (systemctl)。"
    fi
    if ! systemctl enable docker; then
      error_exit "设置 Docker 开机自启失败 (systemctl)。"
    fi
  fi
}

# --- 函数: 验证安装 ---
# 验证 Docker 是否已正确安装，并根据情况启动 Watchtower 容器
verify_installation() {
  info "验证 Docker 安装..."
  if [[ "$USE_CN_MIRRORS" == "true" ]]; then
    info "使用国内镜像加速，建议您手动访问 Docker Hub 安装 Watchtower 容器，以实现 Docker 容器和镜像的自动更新。"
    info "安装命令示例：docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup"
  else
    # 启动 Watchtower 容器 (可选，仅在使用 Docker 官方源时推荐)
    info "启动 Watchtower 容器以自动更新 Docker 容器和镜像..."
    docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup
  fi

  # 运行 docker ps -a 命令 (无论是否启动 Watchtower)
  docker ps -a
}

# --- 主函数：安装 Docker ---
install_docker() {
  # 卸载旧版本
  uninstall_old_docker

  # 安装依赖
  install_dependency curl
  install_dependency gpg

  # 根据操作系统执行不同的安装步骤
  case "$OS_ID" in
    debian|ubuntu)
      info "安装 Docker (Debian/Ubuntu)..."
      install_docker_debian_ubuntu
      ;;
    centos|rhel|rocky|almalinux|oraclelinux)
      info "安装 Docker (RHEL/CentOS/Rocky/Alma/Oracle)..."
      install_docker_rhel
      ;;
    fedora)
      info "安装 Docker (Fedora)..."
      install_docker_fedora
      ;;
    opensuse-leap|opensuse-tumbleweed|sles)
      info "安装 Docker (openSUSE/SLES)..."
      install_docker_sles
      ;;
    alpine)
      info "安装 Docker (Alpine)..."
      install_docker_alpine
      ;;
    arch)
      info "安装 Docker (Arch Linux)..."
      install_docker_arch
      ;;
    *)
      error_exit "不支持的操作系统：$OS_ID"
      ;;
  esac

  # 启动 Docker，并设置开机自启
  start_docker

  # 验证安装
  verify_installation

  echo "Docker 已安装并启动。"
}

# --- 调用主函数 ---
install_docker
exit 0
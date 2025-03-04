# Linux System Init Box (Linux系统初始化宝箱)

[![GitHub license](https://img.shields.io/badge/license-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)

这是一个多功能的 Linux 系统初始化宝库工具集，旨在简化新服务器的配置和管理流程。它提供了一个交互式菜单，让您可以轻松选择和执行各种常见的系统设置和软件安装任务。

Linux System Initialization Box (All in One). Quick System Setup and Software Installation or Config tasks.

Linux系统初始化宝箱 (All in One)。快速系统设置和软件安装或配置任务。

## 功能特性

* **模块化设计：** 每个功能都作为一个独立的脚本，易于理解、维护和扩展。
* **交互式菜单：** 使用 `dialog` 工具提供了一个基于文本的菜单界面，方便用户选择要执行的操作。
* **多发行版支持：** 兼容多种主流 Linux 发行版，包括：
  * RHEL 系列 (CentOS, RHEL, Rocky Linux, AlmaLinux, Oracle Linux)
  * Fedora
  * Debian 系列 (Debian, Ubuntu)
  * openSUSE/SLES
  * Alpine Linux
  * Arch Linux
* **自动检测：** 自动检测操作系统类型、是否在中国大陆 (用于选择镜像源) 等。
* **详细提示：** 在执行每个操作前，都会提供详细的提示信息，并在必要时要求用户确认。
* **错误处理：** 对关键步骤进行了错误检查，并在出错时给出提示或中止执行。
* **可定制性：** 您可以根据自己的需求，选择要执行的功能模块，或者修改脚本中的配置 (例如，软件包列表、时区、网络设置等)。
* **国内镜像加速：** 自动检测并使用国内镜像源 (如果可用)，加快软件包下载和安装速度。
* **安全增强：** 提供配置 SSH 密钥登录、禁用密码登录、关闭防火墙等选项，帮助您提高系统安全性 (请谨慎使用)。
* **支持 Online.net/Scaleway 特殊 IPv6 配置：** 包含一个专门的脚本 (`ipv6_config_online_odhcp6c.sh`)，用于为使用 `odhcp6c` 获取 IPv6 地址的服务器 (如 Online.net 和 Scaleway 的部分专用服务器) 配置 IPv6。
* **持续更新：** 脚本会不断更新和完善，添加新功能，修复 bug，并支持更多发行版。

## 功能列表


| 编号 | 功能                                                            | 脚本文件                                                            | 优先级 |
| :--: | :-------------------------------------------------------------- | :------------------------------------------------------------------ | :----: |
|  1  | 设置主机名                                                      | `hostname_set.sh`                                                   |   1   |
|  2  | 设置 DNS 解析器（自动区分 Global 和 CN）                        | `dns_set_resolver.sh`                                               |   1   |
|  3  | 设置时区                                                        | `timezone_set.sh`                                                   |   1   |
|  4  | 更新系统软件包                                                  | `system_update.sh`                                                  |   1   |
|  5  | 安装基础软件                                                    | `packages_install_basic.sh`                                         |   1   |
|  6  | 配置 Swap                                                       | `swap_config.sh`                                                    |   2   |
|  7  | 配置 BBR 拥塞控制                                               | `network_bbr_config.sh`                                             |   2   |
|  8  | 配置 SSH 密钥登录并禁用密码登录                                 | `ssh_config_password_or_certificate_login.sh`                       |   2   |
|  9  | 安装内网穿透工具 (ZeroTier 和 Tailscale)                        | `net_tools_install_zerotier_tailscale.sh`                           |   2   |
|  10  | 关闭防火墙 (带警告)                                             | `firewall_disable.sh`                                               |   2   |
|  11  | 安装 Docker                                                     | `docker_install.sh`                                                 |   3   |
|  12  | 修改 Docker 数据目录 (可选)                                     | `docker_modify_data_dir.sh`                                         |   3   |
|  13  | 配置 iSCSI                                                      | `iscsi_config_partition_mount.sh`                                   |   3   |
|  14  | 配置 IPv6 地址                                                  | `ipv6_config_add_address.sh`                                        |   3   |
|  15  | 为 odhcp6c 服务器配置 IPv6 (Online.net、Scaleway)               | `ipv6_config_online_odhcp6c.sh`                                     |   3   |
|  16  | 配置网络优先级 (IPv4/IPv6)                                      | `network_config_ip_priority.sh`                                     |   3   |
|  17  | 清理系统历史记录                                                | `system_clear_history.sh`                                           |   3   |
|  18  | 在 Alpine Linux 上使用 Docker 安装 ZeroTier 和 Tailscale (可选) | `net_tools_install_zerotier_tailscale_for_alpine_require_docker.sh` |   3   |
|  19  | 退出脚本                                                        |                                                                     |        |

## 使用方法

您可以通过以下两种方式之一使用此脚本：

**方法一：**

```bash
# 1. 创建 Linux-System-Init-Box 目录，并进入
mkdir -p Linux-System-Init-Box && cd Linux-System-Init-Box

# 2. 下载 核心工具 (utils和Linux_System_Init_Box)
curl -fsSL https://raw.githubusercontent.com/MeowLove/Linux-System-Init-Box/main/utils.sh -o utils.sh
curl -fsSL https://raw.githubusercontent.com/MeowLove/Linux-System-Init-Box/main/Linux_System_Init_Box.sh -o Linux_System_Init_Box.sh

# 3. 赋予 main.sh 执行权限
chmod a+x ./Linux_System_Init_Box.sh && bash ./Linux_System_Init_Box.sh

```

## 注意事项

**以 root 权限运行：** 脚本中的大多数操作都需要 root 权限，请使用 `sudo` 运行。

* **谨慎操作：** 某些操作 (例如，关闭防火墙、修改 Docker 数据目录、清理系统历史记录) 可能会影响系统的安全性或可用性，请谨慎操作。
* **备份数据：** 在执行任何可能导致数据丢失的操作之前，请务必备份重要数据。
* **网络连接：** 脚本中的某些操作 (例如，更新系统、安装软件) 需要网络连接，请确保您的系统已连接到互联网。
* **Online.net/Scaleway 服务器：** 如果您使用的是 Online.net 或 Scaleway 的某些专用服务器，并且需要配置 IPv6，请务必阅读 `ipv6_config_online_odhcp6c.sh` 脚本中的说明。
* **Alpine Linux：** 如果您使用的是 Alpine Linux，并且需要安装 ZeroTier 和 Tailscale，请确保已安装 Docker，然后选择菜单中的 "Alpine 安装内网穿透 (Docker)" 选项。
* **仔细阅读每个脚本的说明：** 在执行每个操作之前，请仔细阅读脚本开头的注释，了解其具体功能和注意事项。

## 自定义

您可以根据自己的需求，修改以下内容：

* **`packages_install_basic.sh`:** 修改要安装的基础软件包列表。
* **`timezone_set.sh`:** 修改默认时区或添加更多时区选项。
* **`swap_config.sh`:** 修改默认的 Swap 文件大小。
* **`ipv6_config_online_odhcp6c.sh`:** 修改默认的 DUID、前缀长度、IPv6 地址等 (如果您使用的是 Online.net 或 Scaleway 服务器)。
* **其他脚本：** 根据需要修改其他脚本中的配置。

## 常见问题解答 (FAQ)

* **Q: 脚本支持哪些 Linux 发行版？**

  A: 脚本目前支持以下发行版：

  * RHEL 系列 (CentOS, RHEL, Rocky Linux, AlmaLinux, Oracle Linux)
  * Fedora
  * Debian 系列 (Debian, Ubuntu)
  * openSUSE/SLES
  * Alpine Linux
  * Arch Linux
* **Q: 我可以在非 root 用户下运行脚本吗？**

  A: 不可以。脚本中的大多数操作都需要 root 权限才能执行。
* **Q: 我可以选择只执行部分功能吗？**

  A: 可以。脚本提供了一个菜单界面，您可以选择要执行的特定功能。
* **Q: 如果脚本执行过程中出现错误怎么办？**

  A: 脚本会对一些关键步骤进行错误检查，并在出错时给出提示。如果遇到错误，请仔细阅读错误信息，并根据提示进行操作。如果问题仍然无法解决，请联系脚本作者或在 GitHub 上提交 issue。
* **Q: 我可以在已经配置好的系统上运行这个脚本吗？**

  A: 可以，但请谨慎操作。某些操作 (例如，修改 Docker 数据目录、关闭防火墙) 可能会影响现有系统的配置。在运行脚本之前，请务必备份重要数据，并仔细阅读每个脚本的说明。
* **Q: 如何自定义脚本？**

  A: 您可以根据自己的需求修改脚本中的配置，例如软件包列表、时区、网络设置等。每个脚本的开头都有详细的注释，说明了其功能和可配置的选项。
* **Q: 如何贡献代码？**

  A: 欢迎您通过提交 issue 或 pull request 的方式来贡献代码。在提交 pull request 之前，请确保您的代码符合脚本的编码风格，并通过了测试。

## 贡献

欢迎提交 issue 或 pull request，帮助我们改进这个脚本。

## 许可证

本项目采用 [GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html) 许可证。

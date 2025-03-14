# Linux-Init-Setup-Kit (LISK 开发仓库)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/MeowLove/Linux-Init-Setup-Kit/actions)  <!-- 如果你设置了 CI，请替换为实际的构建状态徽章 -->
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

[**简体中文**](README_zh-CN.md) | [English](./README.md)

这是 [LISK](https://github.com/MeowLove/LISK) (Linux Init Setup Kit) 的开发和测试仓库。它包含实验性功能和可能不稳定的代码。

**对于普通用户，建议使用 LISK 主仓库中的稳定版本：** [https://github.com/MeowLove/LISK](https://github.com/MeowLove/LISK)

此仓库主要面向希望执行以下操作的开发人员和贡献者：

*   为 LISK 贡献代码。
*   测试即将推出的功能。
*   尝试新想法。

**请注意，此仓库中的代码可能不稳定，不能保证正常工作。使用风险自负。**

## 贡献

我们欢迎贡献！请遵循以下准则：

1.  Fork 此仓库。
2.  为您的功能或错误修复创建一个新分支：`git checkout -b feature/your-feature-name` 或 `git checkout -b bugfix/your-bug-fix-name`
3.  进行更改并使用清晰、描述性的提交消息提交它们。
4.  将您的分支推送到您 Fork 的仓库。
5.  向此仓库（Linux-Init-Setup-Kit）的 `main` 分支提交拉取请求。

请确保您的代码符合项目的编码风格（Bash 风格指南，如果可用）。包括对任何新功能的测试。更详细的贡献指南将很快提供。

## 入门（适用于开发人员）

1.  克隆此仓库：`git clone https://github.com/MeowLove/Linux-Init-Setup-Kit.git`
2.  创建 feature/bugfix 分支。
3.  以 root 身份运行 `./LISK.sh` 以测试当前的开发版本。运行开发代码时要*非常小心*。使用虚拟机或非关键系统。

## 许可证

本项目根据 GNU General Public License v3.0 授权 - 有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
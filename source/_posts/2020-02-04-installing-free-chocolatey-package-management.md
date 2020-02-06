---
layout: post
date: 2020-02-04 00:00:00
title: "PowerShell 技能连载 - 安装免费的 Chocolatey 包管理器"
description: PowerTip of the Day - Installing Free Chocolatey Package Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Chocolatey 是一个软件包管理系统，可以帮助您下​​载和安装软件包。与 PowerShell Gallery 不同，Chocolatey 不仅限于 PowerShell 模块和脚本，还可以安装各种软件，包括 Notepad ++、Acrobat Reader 或 Chrome 浏览器之类的工具。

如果您准备在具有提升至完整管理员权限的 Shell 中运行 Chocolatey，则很简单。尽管有说明如何在没有完全特权的情况下使 Chocolatey 工作，但几乎肯定会遇到问题。

要在 PowerShell 中使用Chocolatey，请下载其安装脚本并运行它。这需要管理员特权：

```powershell
# download installation code
$code = Invoke-WebRequest -Uri 'https://chocolatey.org/install.ps1' -UseBasicParsing

# invoke installation code
Invoke-Expression $code
```

这步之后，您可以在 PowerShell 中使用新的“choco”命令。只需确保在提升权限的 Shell 中运行即可。

A list of installable packages (like Acrobat Reader or Google Chrome) can be found here:
可以在此处找到可安装软件包的列表（例如 Acrobat Reader 或 Google Chrome）：

[https://chocolatey.org/packages](https://chocolatey.org/packages)

例如，要安装 Chrome 浏览器，请运行以下命令：

```bash
choco install googlechrome -y
```

同样，当您从未提升的 PowerShell 中运行“choco”时，您会收到一条警告消息，并且大多数软件包将无法正确安装。

<!--本文国际来源：[Installing Free Chocolatey Package Management](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-free-chocolatey-package-management)-->


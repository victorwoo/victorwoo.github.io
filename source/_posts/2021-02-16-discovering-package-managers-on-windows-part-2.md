---
layout: post
date: 2021-02-16 00:00:00
title: "PowerShell 技能连载 - 探索 Windows 上的程序包管理器（第 2 部分）"
description: PowerTip of the Day - Discovering Package Managers on Windows (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们讨论了 "Chocolatey" 程序包管理器，如果您想为所有用户安装软件（需要管理员权限），该程序最有效。

另一个出色的软件包管理器是 "Scoop"，它针对没有管理员权限的普通用户。Scoop 严格为当前用户下载并安装软件，并且是便携式应用程序。

注意：为了能够运行脚本和下载代码，您可能必须先运行以下代码：

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor
[System.Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

要安装此程序包管理器，请在 PowerShell中运行以下几行（无需管理员权限）：

```powershell
Invoke-RestMethod -UseBasicParsing -Uri 'https://get.scoop.sh' | Invoke-Expression
scoop install git
scoop bucket add extras
```

安装后，会生成一个名为 "Scoop" 的新命令。

现在，您可以安装可能需要的所有工具。以下几行安装 PowerShell 7、Windows Terminal、7Zip、Notepad ++ 和 Visual Studio Code 编辑器：

```bash
scoop install pwsh
scoop install windows-terminal
scoop install 7zip
scoop install notepadplusplus
scoop install vscode-portable
```

使用命令 "`scoop search [phrase]`"，您可以搜索其他可用的安装软件包。

Scoop 将所有软件作为便携式应用程序安装在其自己的文件夹中，您可以这样打开：

```bash
explorer $home\Scoop\Apps
```

某些安装包可能会向您的桌面和任务栏添加链接.但是通常您需要访问 scoop 安装文件夹，手动启动应用程序，然后将其固定到任务栏或开始菜单以方便访问。

重要说明："Scoop" 下载并安装软件包，并尝试解决依赖关系。但是，"Windows Terminal" 之类的某些软件包可能有其他要求（例如Windows Build 1903 或更高版本），因此，如果软件在安装后无法启动，则可能需要检查其他要求。

<!--本文国际来源：[Discovering Package Managers on Windows (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discovering-package-managers-on-windows-part-2)-->


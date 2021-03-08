---
layout: post
date: 2021-03-02 00:00:00
title: "PowerShell 技能连载 - 修复 VSCode PowerShell 问题（第 2 部分）"
description: PowerTip of the Day - Fixing VSCode PowerShell Issues (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果在编辑 PowerShell 脚本时 VSCode 不会启动 PowerShell 引擎，而状态栏中的黄色消息“正在启动 PowerShell”不会消失，则可能的解决方法是使用全新独立的可移植 PowerShell 7 安装作为 VSCode 中的默认 PowerShell 引擎。

首先，运行以下这行代码以创建 `Install-PowerShell` cmdlet ：

```powershell
Invoke-RestMethod -Uri https://aka.ms/install-powershell.ps1 | New-Item -Path function: -Name Install-PowerShell | Out-Null
```

接下来，在本地文件夹中安装 PowerShell 7 的新副本，例如：

```powershell
Install-PowerShell -Destination c:\portablePowerShell
```

安装完成后，请确保可以手动启动新的 PowerShell 实例：

```powershell
c:\portablePowerShell\pwsh
```

现在，继续告诉 VSCode，您要在编辑 PowerShell 脚本时使用此新的 PowerShell 实例运行：在 VSCode 中，选择“文件/首选项/设置”，单击设置左栏中的“扩展”，然后单击子菜单中的“PowerShell 配置”。

接下来，搜索设置“PowerShell 默认版本”，然后输入任何名称，即“portable PowerShell 7”。在上面的“PowerShell Additional Exe Paths”部分中，单击链接“Edit in settings.json”。这将以 JSON 格式打开原始设置文件。

其中，新设置部分已经插入，需要像这样完成：

```json
"powershell.powerShellAdditionalExePaths": [
        {
            "exePath": "c:\\portablePowerShell\\pwsh.exe",
            "versionName": "portable PowerShell 7"
        }
    ]
```

注意：所有标记和关键字均区分大小写，并且在路径中，反斜杠需要由另一个反斜杠转义。在 "exePath" 中，在下载的可移植 PowerShell 文件夹中指定 `pwsh.exe` 文件的路径。确保路径不仅指向文件夹，而且指向 `pwsh.exe`。

在 "versionName" 中，使用之前在 "PowerShell Default Version" 中指定的相同标签名称。

Once you save the JSON file, restart VSCode. The editor now uses your portable PowerShell 7, and in many instances, this solves stalled PowerShell startup problems.
保存 JSON 文件后，重新启动 VSCode。该编辑器现在使用您的 portable PowerShell 7，并且在许多情况下，这解决了 PowerShell 启动卡住的问题。

如果您想手动将其他 PowerShell 版本添加到 VSCode，则上面的方法也很有用。当您单击 VSCode 状态栏中的绿色 PowerShell 版本时，任何手动添加的 PowerShell 将出现在选择对话框中（除非已被使用，在这种情况下，该菜单将显示 PowerShell 类型和版本，而不是您的标签名称）。

<!--本文国际来源：[Fixing VSCode PowerShell Issues (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/fixing-vscode-powershell-issues-part-2)-->

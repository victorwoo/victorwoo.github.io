---
layout: post
date: 2020-11-10 00:00:00
title: "PowerShell 技能连载 - 调优 Windows Terminal"
description: PowerTip of the Day - Fine-Tuning Windows Terminal
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技能中，我们介绍了如何通过 Microsoft Store 在 Windows 10 上安装 "Windows Terminal"。Windows Terminal 将 PowerShell 控制台放在单独的标签页中，非常实用。

您可以通过编辑设置文件来控制选项卡下拉列表中可用的控制台类型：在 Windows Terminal 中，在标题栏中单击向下箭头按钮，然后选择“设置”。这将在关联的编辑器中打开一个 JSON 文件。如果没有与 JSON 文件关联的编辑器，则可以选择一个或使用记事本。

“配置文件”部分列出了您可以使用“向下箭头”按钮在 Windows Terminal 中打开的控制台类型。这是一个例子：

```json
"profiles":
    {
        "defaults":
        {
            // Put settings here that you want to apply to all profiles.
        },
        "list":
        [
            {
                // Make changes here to the powershell.exe profile.
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "name": "Windows PowerShell",
                "commandline": "powershell.exe",
                "hidden": false,
                "useAcrylic": true,
        "acrylicOpacity" : 0.8,
            },
            {
                // Make changes here to the cmd.exe profile.
                "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "name": "Command Shell",
                "commandline": "cmd.exe",
                "hidden": false,
                "useAcrylic": true,
        "acrylicOpacity" : 0.8,
            },
            {
                "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                "hidden": false,
                "name": "PowerShell",
                "source": "Windows.Terminal.PowershellCore",
                "useAcrylic": true,
        "acrylicOpacity" : 0.8,
            },
            {
                "guid": "{2595cd9c-8f05-55ff-a1d4-93f3041ca67f}",
                "hidden": false,
                "name": "PowerShell Preview (msix)",
                "source": "Windows.Terminal.PowershellCore",
                "useAcrylic": true,
        "acrylicOpacity" : 0.8,
            },
            {
                "guid": "{b453ae62-4e3d-5e58-b989-0a998ec441b8}",
                "hidden": false,
                "name": "Azure Cloud Shell",
                "source": "Windows.Terminal.Azure",
                "useAcrylic": true,
        "acrylicOpacity" : 0.8,
            },
            {
                "guid": "{0caa0dae-35be-5f56-a8ff-afceeeaa6101}",
                "name": "Terminal As Admin",
                "commandline": "powershell.exe -command start 'C:/wt/wt.exe' -verb runas",
                "icon": "ms-appx:///Images/Square44x44Logo.targetsize-32.png",
                "hidden": false
            },
            {
                "guid": "{0ca30dae-35be-5f56-a8ff-afceeeaa6101}",
                "name": "ISE Editor",
                "commandline": "powershell.exe -command powershell_ise",
                "icon": "c:/wt/ise.ico",
                "hidden": false
            },
            {
                "guid": "{b39ac7db-ace0-4165-b312-5f2dfbbe4e4d}",
                "name": "VSCode",
                "commandline": "cmd.exe /c \"%LOCALAPPDATA%/Programs/Microsoft VS Code/code.exe\"",
                "icon": "c:/wt/vscode.ico",
                "hidden": false
            }
        ]
    }
```

如您所见，您可以定义任何可执行文件的路径，使用 "useAcrylic" 和 "acrylicOpacity" 等选项可以控制透明度。

看一下列表末尾的条目：它们说明了如何使用下拉菜单启动外部程序，例如编辑器（VSCode、ISE），甚至使用管理员权限打开 Windows Terminal。

诀窍是使用 "`cmd.exe /c`" 或 "`powershell`" 启动外部应用程序。如果直接启动外部应用程序，这将导致空白的选项卡窗口保持打开状态，直到再次关闭外部应用程序。

还要注意如何将喜欢的图标添加到列表项：使用 "icon" 并提交位图或 ico 文件。在即将发布的技巧中，我们将展示如何通过 PowerShell 代码创建此类图标文件。

如果您打算将新条目添加到列表中，请记住每个条目都需要一个唯一的 GUID。在 PowerShell 中，可以使用 `New-Guid` 来创建一个。

保存 JSON 文件后，修改立即生效。如果您进行的 JSON 编辑损坏了文件或引入了语法错误（例如不匹配的引号等），则 Windows Terminal 会报错。最好在编辑之前制作备份副本，并使用像 VSCode 这样的编辑器来支持 JSON 格式，并通过语法错误提示来帮助您。

<!--本文国际来源：[Fine-Tuning Windows Terminal](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/fine-tuning-windows-terminal)-->


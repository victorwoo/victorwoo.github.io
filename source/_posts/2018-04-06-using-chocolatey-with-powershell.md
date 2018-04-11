---
layout: post
date: 2018-04-06 00:00:00
title: "PowerShell 技能连载 - 用 PowerShell 操作 Chocolatey"
description: PowerTip of the Day - Using Chocolatey with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
Chocolatey 是一个 Windows 平台上免费的包管理器，可以用来下载和安装软件。

在用 PowerShell 操作 Chocolatey 之前，您需要下载和安装它。如果您没有管理员特权，请使用以下代码。它将下载安装脚本，检测它的数字签名并确保它是合法的，然后运行它：

```powershell
# download and save installation script, then check signature
$url = 'https://chocolatey.org/install.ps1'
$outPath = "$env:temp\installChocolatey.ps1"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $outPath

# test signature
$result = Get-AuthenticodeSignature -FilePath $outPath
if ($result.Status -ne 'Valid')
{
    Write-Warning "Installation Script Damaged/Malware?"
    exit 1
}

# install chocolatey for current user
$env:ChocolateyInstall='C:\ProgramData\chocoportable'

Start-Process -FilePath powershell -ArgumentList "-noprofile -noExit -ExecutionPolicy Bypass -File ""$outPath""" -Wait

# clean up
Remove-Item -Path $outPath
```

要查看更多的安装选项，请访问 [https://chocolatey.org/install](https://chocolatey.org/install)。

以上脚本不需要管理员权限，以便携应用的方式安装 Chocolatey。要使用它，您需要临时将安装文件夹添加到 Windows 的 `Path` 环境变量。然后输入 `choco` 来测试安装情况。该命令将汇报它的版本号：

```powershell
PS> $env:path += ";C:\ProgramData\chocoportable"

PS> choco
Chocolatey v0.10.8
Please run 'choco -?' or 'choco  -?' for help menu.

PS>
```

我们将看看如何使用 Chocolatey 自动下载和安装 PowerShell Core 6，然后和您当前 Windows PowerShell 安装并行地使用它。

同时，访问 https://chocolatey.org/packages?q=notepadplusplus 来查看您是否可以通过 Chocolatey 来安装。以下是使用 Chocolatey 需要考虑的关键步骤：


* 使用 PowerShell 控制台窗口。不要使用没有真正控制台窗口的 PowerShell 宿主（例如 ISE）
* 如果可能，使用管理员权限运行 PowerShell。许多包需要完整的 Administrator 权限来安装软件
* 将 Chocolatey 安装路径添加到 `Path` 环境变量

当您的环境准备好后，可以试试下载和安装一个工具，例如 Notepad++ 是多么简单：

    PS C:\> $env:path += ";C:\ProgramData\chocoportable"
    PS C:\> choco install notepadplusplus -y
    Chocolatey v0.10.8
    [Pending] Removing incomplete install for 'notepadplusplus'
    Installing the following packages:
    notepadplusplus
    By installing you accept licenses for the packages.

    notepadplusplus.install v7.5.6 [Approved]
    notepadplusplus.install package files install completed. Performing ot
    her installation steps.
    Installing 64-bit notepadplusplus.install...
    notepadplusplus.install has been installed.
    notepadplusplus.install installed to 'C:\Program Files\Notepad++'
    Added C:\ProgramData\chocoportable\bin\notepad++.exe shim pointed to '
    c:\program files\notepad++\notepad++.exe'.
      notepadplusplus.install may be able to be automatically uninstalled.

     The install of notepadplusplus.install was successful.
      Software installed as 'exe', install location is likely default.

    notepadplusplus v7.5.6 [Approved]
    notepadplusplus package files install completed. Performing other inst
    allation steps.
     The install of notepadplusplus was successful.
      Software install location not explicitly set, could be in package or

      default install location if installer.

    Chocolatey installed 2/2 packages.
     See the log for details (C:\ProgramData\chocoportable\logs\chocolatey
    .log).
    PS C:\>

当 Chocolatey 完成安装 Notepad++ 的安装后，只需要按下 `Win` + `R` 键，然后在“运行”对话框中输入

    Notepad++

编辑器就启动了。

<!--more-->
本文国际来源：[Using Chocolatey with PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/using-chocolatey-with-powershell)

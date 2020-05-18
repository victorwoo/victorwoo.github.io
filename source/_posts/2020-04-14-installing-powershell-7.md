---
layout: post
date: 2020-04-14 00:00:00
title: "PowerShell 技能连载 - 安装 PowerShell 7"
description: PowerTip of the Day - Installing PowerShell 7
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 7 是便携式应用程序，可以与 Windows PowerShell 平行运行。您只需要下载并安装它。

This part is easy because the PowerShell team provides an automatic installation script. With a little trick, you can download this code and tie it to a fresh new PowerShell function, making it super easy to install PowerShell 7 from the existing Windows PowerShell:
这部分很容易，因为 PowerShell 团队提供了自动安装脚本。只需一点技巧，您就可以下载此代码并将其绑定到新的 PowerShell 功能，从而可以非常容易地从现有 Windows PowerShell 安装 PowerShell 7：

```powershell
# Download installation script
$code = Invoke-RestMethod -Uri https://aka.ms/install-powershell.ps1

# Dynamically create PowerShell function
New-Item -Path function: -Name Install-PowerShell -Value $code

# Run PowerShel function and install the latest PowerShell
Install-PowerShell -UseMSI -Preview
```

<!--本文国际来源：[Installing PowerShell 7](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-powershell-7)-->


---
layout: post
date: 2015-08-28 11:00:00
title: "PowerShell 技能连载 - 映射网络驱动器（第 2 部分）"
description: PowerTip of the Day - Mapping Network Drives (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 3.0 开始，您可以使用 `New-PSDrive` 命令来映射网络驱动器。它们也可以在文件管理器中显示。以下是一些示例代码：

    #requires -Version 3

    New-PSDrive -Name N -PSProvider FileSystem -Root '\\dc-01\somefolder' -Persist

    Test-Path -Path N:\
    explorer.exe N:\
    Get-PSDrive -Name N

    Remove-PSDrive -Name N -Force

如果您希望提供登录凭据，请在 `New-PSDrive` 命令后添加 `-Credential` 参数，并且以 **domain\username** 的方式提交用户名。密码将会以安全的方式提示输入。

<!--本文国际来源：[Mapping Network Drives (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/mapping-network-drives-part-2)-->

---
layout: post
date: 2020-09-15 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell ISE 中使用 PowerShell 7"
description: PowerTip of the Day - Using PowerShell 7 inside PowerShell ISE
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 内置的 PowerShell ISE 仅能与 Windows PowerShell 一起使用，并且停留在 PowerShell 5.1 版。通常，当您想使用编辑器编写 PowerShell 7 代码时，可以使用 Visual Studio Code 和 PowerShell 扩展。

尽管如此，您仍可以使 PowerShell ISE 兼容 PowerShell 7。然后，它为 PowerShell 7 提供了丰富的 IntelliSense，并包含 PowerShell 7 中引入的所有语言功能。

为此，您可以从 PowerShell ISE 中启动本地远程会话，并指定配置名称 "powershell.7"。

```powershell
PS> Enter-PSSession -ComputerName localhost -ConfigurationName powershell.7
```

当然，这需要满足一些先决条件：

* 您需要先安装 PowerShell 7，然后才能使用它。 Windows 7 并不附带 PowerShell 7。
* 您需要在 PowerShell 7中启用远程处理。您可以在安装期间通过选中安装对话框中的相应框来执行此操作。或者，您从提升权限的 PowerShell 7 控制台运行此命令：`Enable-PSRemoting -SkipNetworkProfileCheck -Force`
* 您可能需要在提升权限的 Windows PowerShell 中再次运行此行命令：`Enable-PSRemoting -SkipNetworkProfileCheck -Force`

现在您已经准备就绪，并使用上述参数运行 `Enter-PSSession` 时，您将远程连接到 PowerShell 7。

如果您当前的用户不是管理员，或者您使用电子邮件地址和 Microsoft 帐户登录，则需要创建一个具有管理员权限的本地用户帐户，并将其明确用于身份验证：

```powershell
PS> Enter-PSSession -ComputerName localhost -ConfigurationName powershell.7 -Credential localAdminUser
```

<!--本文国际来源：[Using PowerShell 7 inside PowerShell ISE](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-powershell-7-inside-powershell-ise)-->


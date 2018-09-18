---
layout: post
date: 2018-08-23 00:00:00
title: "PowerShell 技能连载 - 使用 profile 脚本"
description: PowerTip of the Day - Using Profile Scripts
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
默认情况下，PowerShell 在重新运行时会自动“忘记”某些设置。如果您需要“保持”设置，您需要使用 profile 脚本。当 PowerShell 在任何情况下启动时，会运行一段脚本。您可以向该脚本中添加任何命令。

这行代码将会打开当前的 PowerShell profile 脚本，而如果目前该脚本不存在，将会用 notepad 创建一个：

```
PS C:\> notepad $profile
```

您现在可以向 profile 脚本增加这段代码：

```powershell
"Hello $env:username!"
Set-Alias -Name web -Value "$env:ProgramFiles\Internet Explorer\iexplore.exe"
```

您也可以运行这段代码来确保允许 PowerShell 执行本地脚本：

```powershell
PS  C:\> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

下一次您运行 PowerShell 时，它将会向您致礼，并且创建一个新的名为 "`web`" 的别名。该别名可以在 Internet Explorer 中打开网页：

```powershell
PS C:\> web www.powershellmagazine.com
```

<!--more-->
本文国际来源：[Using Profile Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/using-profile-scripts1)

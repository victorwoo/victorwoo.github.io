---
layout: post
date: 2019-04-03 00:00:00
title: "PowerShell 技能连载 - 禁止用户输入"
description: PowerTip of the Day - Blocking User Input
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果一个 PowerShell 脚本需要进行危险的操作，而且用户操作必须被禁止，那么您可以使用 API 来临时禁止所有键盘输入。锁定键盘输入不需要管理员权限。

以下是一个演示如何阻止所有键盘输入 4 秒钟的脚本：

```powershell
#requires -RunAsAdministrator
# when run without administrator privileges, the keyboard will not be blocked!

# get access to API functions that block user input
# blocking of keyboard input requires administrator privileges
$code = @'
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
'@

$userInput = Add-Type -MemberDefinition $code -Name Blocker -Namespace UserInput -PassThru

# block user input
$null = $userInput::BlockInput($true)

Write-Warning "Your input has been disabled for 4 seconds..."
Start-Sleep -Seconds 4

# unblock user input
$null = $userInput::BlockInput($false)
```

<!--本文国际来源：[Blocking User Input](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/blocking-user-input)-->


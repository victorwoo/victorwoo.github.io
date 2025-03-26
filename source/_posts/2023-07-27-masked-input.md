---
layout: post
date: 2023-07-27 08:00:40
title: "PowerShell 技能连载 - 带有掩码的输入"
description: PowerTip of the Day - Masked Input
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
为了安全地输入信息，脚本需要显示一个掩码输入。最简单的方法是使用 `Read-Host -AsSecureString` 命令：

```powershell
# Read-Host
$entered = Read-Host -Prompt 'Enter secret info' -AsSecureString
```

或者，你可以使用一个带有 `[SecureString]` 类型参数的函数，并将该参数设置为强制性：

```powershell
# mandatory parameter
function test([Parameter(Mandatory)][SecureString]$Secret)
{
    "You entered secret: $Secret"
    return $Secret
}

# run function with mandatory parameter
$entered = test
```

这样，您可以免费获得一个屏蔽的输入（在控制台窗口显示为“星号”，在ISE中显示为单独的输入框），但最终得到的是安全字符串，而不是明文。以下是一个简单的函数，可用于将安全字符串转换回纯文本：

```powershell
filter Convert-SecureStringToString
{
   param([Parameter(Mandatory,ValueFromPipeline)][SecureString]$SecureString)
   [Runtime.InteropServices.Marshal]::
    PtrToStringAuto(
     [Runtime.InteropServices.Marshal]::
     SecureStringToBSTR($SecureString)
    )
}
```

现在您可以使用屏蔽输入来询问敏感用户信息，并在内部将其作为纯文本使用：

```powershell
# Read-Host
$entered = Read-Host -Prompt 'Enter secret info' -AsSecureString |
             Convert-SecureStringToString
```
<!--本文国际来源：[Masked Input](https://blog.idera.com/database-tools/powershell/powertips/masked-input/)-->


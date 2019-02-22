---
layout: post
date: 2018-02-27 00:00:00
title: "PowerShell 技能连载 - 永久性设置环境变量"
description: PowerTip of the Day - Permanently Setting Environment Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 只能在它的进程空间里设置环境变量，所以这些改变无法保存，并且在 PowerShell 之外不可见。

要永久性地设置环境变量，可以编写一个简单的函数：

```powershell
function Set-EnvironmentVariable
{
    param
    (
        [string]
        [Parameter(Mandatory)]
        $Name,

        [string]
        [AllowEmptyString()]
        [Parameter(Mandatory)]
        $Value,

        [System.EnvironmentVariableTarget]
        [Parameter(Mandatory)]
        $Target
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
}
```

现在您可以这样设置环境变量：

```powershell
PS> Set-EnvironmentVariable -Name test -Value 123 -Target User
```

您也可以传入空字符串来移除一个环境变量。

```powershell
PS> Set-EnvironmentVariable -Name test -Value "" -Target User
```

这是为什么 `-Value` 参数定义加上 `[AllowEmptyString()]` 属性的原因。如果没有这个属性，一个必选参数不能接受一个空字符串，那么该函数就无法移除环境变量。

另一个值得注意的地方是 `-Target` 参数的类型定义：因为制定了一个枚举类型，所以当您在 PowerShell ISE 或其它带有智能提示的编辑器中使用这个函数时，该编辑器将会贴心地提供智能提示选择。

<!--本文国际来源：[Permanently Setting Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/permanently-setting-environment-variables)-->

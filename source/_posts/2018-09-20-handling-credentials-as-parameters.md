---
layout: post
date: 2018-09-20 00:00:00
title: "PowerShell 技能连载 - 用参数的方式解决凭据"
description: PowerTip of the Day - Handling Credentials as Parameters
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
凭据是包含用户名和加密的密码的对象。如果您的 PowerShell 函数可以接受凭据，那么加上 `PSCredential` 类型：

```powershell
function Connect-Server
{
    param
    (
        [Parameter(Mandatory)]
        [pscredential]
        $Credential
    )

    "You entered a credential for {0}." -f $Credential.UserName
    # now you could do something with $Credential, i.e. submit it to
    # other cmdlets that support the -Credential parameter
    # i.e.
    # Get-WmiObject -Class Win32_BIOS -ComputerName SomeComputer -Credential $Credential

}
```

当您运行以上代码后，再调用您的函数，将会显示一个对话框，显示用户名和密码。当指定一个用户名时，情况也是一样：也是打开一个对话框提示输入密码，然后将您的输入转换为一个合适的 `PSCredential` 对象:

```powershell
PS> Connect-Server -Credential tobias
```

这个自动转换过程只在 PowerShell 5.1 及以上的版本中有效。在之前的 PowerShell 版本中，您可以先传入一个凭据对象。要在旧版的 PowerShell 中也启用该转换过程，您可以可以增加一个额外的转换属性：

```powershell
function Connect-Server
{
    param
    (
        [Parameter(Mandatory)]
        [pscredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    "You entered a credential for {0}." -f $Credential.UserName
    # now you could do something with $Credential, i.e. submit it to
    # other cmdlets that support the -Credential parameter
    # i.e.
    # Get-WmiObject -Class Win32_BIOS -ComputerName SomeComputer -Credential $Credential

}
```

<!--more-->
本文国际来源：[Handling Credentials as Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/handling-credentials-as-parameters)

---
layout: post
date: 2018-09-21 00:00:00
title: "PowerShell 技能连载 - 从 PowerShell 函数中窃取敏感数据"
description: PowerTip of the Day - Stealing Sensitive Data from PowerShell Functions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 函数常常处理敏感的信息，例如包含密码的登录信息，并且将这些信息存储在变量中。让我们假设有这样一个函数：

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
    # now you could do something with $Credential
}
```

当运行这个函数时，会弹出提示输入凭据和密码。您的信息在函数中体现在 `$Credential` 变量中，并且当函数完成时，内部信息自动从内存中移除：

```powershell
PS> Connect-Server -Credential tobias
You entered a credential for Tobias.

PS> $Credential

PS>
```

然而，任何攻击者都可以通过 dot-sourced 方式运行该函数。当函数执行完毕之后，所有内部变量都还在内存中：

```powershell
PS> . Connect-Server -Credential tobias
You entered a credential for Tobias.

PS> $Credential

UserName                     Password
--------                     --------
Tobias   System.Security.SecureString



PS> $Credential.GetNetworkCredential().Password
test

PS>
```

如您所见，攻击者现在可以访问凭据对象，并且也可以看到原始的密码。

要防止这种情况，您可以再次从内存中手动移除敏感的数据。您可以用 `Remove-Variable` 移除变量：

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

    Remove-Variable -Name Credential
}
```

现在不再能获取到变量：

```powershell
PS> Remove-Variable -Name Credential

PS> . Connect-Server -Credential tobias
You entered a credential for Tobias.

PS> $credential

PS>
```

<!--本文国际来源：[Stealing Sensitive Data from PowerShell Functions](http://community.idera.com/powershell/powertips/b/tips/posts/stealing-sensitive-data-from-powershell-functions)-->

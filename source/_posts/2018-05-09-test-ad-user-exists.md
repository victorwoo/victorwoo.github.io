---
layout: post
date: 2018-05-09 00:00:00
title: "PowerShell 技能连载 - 测试 AD 用户是否存在"
description: PowerTip of the Day - Test AD User Exists
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要查看一个指定的域用户是否存在，并且假设您已经安装了 ActiveDirectory PowerShell 模块，它是 RSAT（远程服务器管理工具）的一部分，那么有一个更巧的方法：

```powershell
function Test-UserExists
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $SAMAccountName
    )

    @(Get-ADUser -LDAPFilter "(samaccountname=$SAMAccountName)").Count -ne 0

}
```

您也可以调整 LDAP 查询来基于其它属性检查用户。

<!--本文国际来源：[Test AD User Exists](http://community.idera.com/powershell/powertips/b/tips/posts/test-ad-user-exists)-->

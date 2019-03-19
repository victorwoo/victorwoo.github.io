---
layout: post
date: 2014-12-22 12:00:00
title: "PowerShell 技能连载 - 设置 AD 或 Windows 的权限"
description: PowerTip of the Day - Setting Permissions in AD or Windows Registry
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_需要 ActiveDirectory 模块_

我们之前已经演示了如何用 `Get/Set-Acl` 来读写文件和文件夹的权限。

实际上这两个 cmdlet 可以处理所有合法的 PowerShell 路径。说以您可以同样地在 Windows 注册表中使用相同的方法来读取、克隆和写入属性。

这个例子从一个注册表键中读取已有的安全信息，并应用到另一个键上：

    # both Registry keys must exist
    $KeyToCopySecurityFrom = 'HKLM:\Software\Key1'
    $KeyToCopySecurityTo = 'HKLM:\Software\Key1'

    $securityDescriptor = Get-Acl -Path $KeyToCopySecurityFrom
    Set-Acl -Path $KeyToCopySecurityTo -AclObject $securityDescriptor

类似地，如果您从微软安装了 RSAT 工具并启用了 ActiveDirectory PowerShell 模块，您就可以使用它的 PowerShell 驱动器 AD: 来对 AD 对象做类似的操作，例如，从一个 OU 克隆委派权限到另一个 OU 上。

您现在可以根据需要读取、修改或重新应用如委派控制、防止意外删除等 Active Directory 特性。

    Import-Module ActiveDirectory

    # both OUs must exist
    $OUtoCopyFrom = 'AD:\OU=Employees,DC=TRAINING,DC=POWERSHELL'
    $OUtoCopyTo = 'AD:\OU=TestEmployees,DC=TRAINING,DC=POWERSHELL'

    $securityDescriptor = Get-Acl -Path $OUtoCopyFrom
    Set-Acl -Path $OUtoCopyTo -AclObject $securityDescriptor

您现在可以对任何 AD 对象通过这种方式读取和写入安全信息，包括 DNS 信息。您所需要的只是知道您想读写的对象的 LDAP 路径。

<!--本文国际来源：[Setting Permissions in AD or Windows Registry](http://community.idera.com/powershell/powertips/b/tips/posts/setting-permissions-in-ad-or-windows-registry)-->

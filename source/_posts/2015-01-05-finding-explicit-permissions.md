---
layout: post
date: 2015-01-05 12:00:00
title: "PowerShell 技能连载 - 查找非继承的权限"
description: PowerTip of the Day - Finding Explicit Permissions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

通常，文件系统的 NTFS 权限是继承的。然而，您可以显式地为文件和文件夹添加权限。

您可以使用这段示例代码查找何处禁用了继承以及何处添加了权限项目：

    Get-ChildItem c:\Windows -Recurse -Directory -ErrorAction SilentlyContinue |
      Where-Object { (Get-Acl -Path $_.FullName -ErrorAction SilentlyContinue).Access | 
      Where-Object { $_.isInherited -eq $false } } 

在这个例子中，`Get-ChildItem` 在 Windows 文件夹中搜索所有子文件夹。您可以将“C:\Windows”改为您想测试的任意文件夹。

然后，该脚本读取每个文件夹的安全描述符并查看是否有 `isInherited` 属性被设为 `$false` 的存取控制记录。

如果结果为真，该文件夹会汇报给您。

<!--本文国际来源：[Finding Explicit Permissions](http://community.idera.com/powershell/powertips/b/tips/posts/finding-explicit-permissions)-->

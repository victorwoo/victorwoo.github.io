---
layout: post
date: 2018-07-31 00:00:00
title: "PowerShell 技能连载 - 使用 AD 过滤器配合 cmdlet（第 1 部分）"
description: PowerTip of the Day - Using AD Filters with Cmdlets (Part 1)
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
ActiveDirectory Powershell 模块中包含了免费的 RSAT 工具。您可以使用这个模块中的 cmdlet 来获取 AD 信息，例如用户或者组名。例如 `Get-ADUser` 和 `Get-ADComputer` 等 cmdlet 支持服务端过滤器。不过，它们的工作方式可能和您设想的略有不同。

对于简单的查询，这些过滤器使用起来很容易。例如，这行代码筛选出前五个名字以 "A" 开头的用户，而且过滤器的语法看起来很像 PowerShell 代码：

```powershell
Get-ADUser -Filter { name -like 'A*' } -ResultSetSize 5
```

不过它还不是真的 PowerShell 语法：`-Filter` 参数接受的是纯文本，所以您也可以使用引号代替大括号：

```powershell
Get-ADUser -Filter " name -like 'A*' " -ResultSetSize 5
```

使用大括号（脚本块）仍是一个好主意，因为大括号包括的是 PowerShell 代码，所以在大括号内写代码时可以获得代码高亮和语法错误特性。脚本块稍后可以方便地转换为字符串（`Get-ADUser` 会自动处理）。

<!--more-->
本文国际来源：[Using AD Filters with Cmdlets (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/using-ad-filters-with-cmdlets-part-1)

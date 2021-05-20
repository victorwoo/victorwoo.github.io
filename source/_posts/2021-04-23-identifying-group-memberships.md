---
layout: post
date: 2021-04-23 00:00:00
title: "PowerShell 技能连载 - 识别组成员身份"
description: PowerTip of the Day - Identifying Group Memberships
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的脚本需要知道当前用户是否是给定组的成员，那么最快且耗费最少资源的方法是使用如下代码：

```powershell
$token = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$xy = 'S-1-5-64-36'
if ($token.Groups -contains $xy)
{
  "You're in this group."
}
```

当当前用户是由 SID S-1-5-64-36 标识的组的直接或间接成员时，该示例将执行代码（将该 SID 替换为所需的组的 SID）。

这段代码访问用户已经存在并且始终有权访问的访问令牌。无需额外耗时进行 AD 查询，并且嵌套组成员身份也没有问题。访问令牌具有当前用户所属的直接和间接组的完整列表。

所有组均按 SID 列出，这很有意义。再次解析 SID 名称既耗时又毫无意义。如果您只想知道用户是否是组的成员，则只需找出该组的 SID（即使用 `Get-AdGroup`），然后在上述方法中使用此 SID 即可。

<!--本文国际来源：[Identifying Group Memberships](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-group-memberships)-->

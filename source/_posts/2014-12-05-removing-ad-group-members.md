---
layout: post
date: 2014-12-05 12:00:00
title: "PowerShell 技能连载 - PowerShell 技能连载 - 移除 AD 组成员"
description: PowerTip of the Day - Removing AD Group Members
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_需要 ActiveDirectory Module_

要从 Active Directory 组中移除一个或多个用户，尝试以下方法：

```
$user = @()
$user += Get-ADUser -Filter { Name -like 'H*'} 
$user += Get-ADUser -Filter { Name -like '*ll*'} 
$user.Name

Remove-ADGroupMember -Identity 'SomeGroup' -Members $user
```

这段代码将查找名字符合指定模式的所有用户，然后将用户列表传递给 `Remove-ADGroupMember` 来将用户从该组中移除掉。

请注意空数组的使用。一个空数组可以通过“`+=`”运算符一次或多次加入元素，并且该操作符可以接受单个用户也可以接受一个数组。所以您可以向列表添加一个或多个用户——例如过滤查询的结果。

<!--本文国际来源：[Removing AD Group Members](http://community.idera.com/powershell/powertips/b/tips/posts/removing-ad-group-members)-->

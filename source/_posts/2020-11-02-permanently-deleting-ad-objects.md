---
layout: post
date: 2020-11-02 00:00:00
title: "PowerShell 技能连载 - 彻底删除 AD 对象"
description: PowerTip of the Day - Permanently Deleting AD Objects
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多 Active Directory 对象都受到保护，无法删除。尝试删除它们时，会出现错误，从而防止您意外删除无法还原的用户帐户。

当然，这可以防止您合法删除甚至将对象移动到新的 OU。

若要确定是否防止意外删除 AD 对象，请使用以下命令：

```powershell
Get-ADObject ‹DN of object› -Properties ProtectedFromAccidentalDeletion
```

要关闭保护，即在您计划移动或删除对象时，请将属性设置为 `$false`：

```powershell
Set-ADObject ‹DN of object› -ProtectedFromAccidentalDeletion $false
```

<!--本文国际来源：[Permanently Deleting AD Objects](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/permanently-deleting-ad-objects)-->


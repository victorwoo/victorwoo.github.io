---
layout: post
date: 2023-04-27 00:00:09
title: "PowerShell 技能连载 - Office365邮箱恢复删除（第 1 部分）"
description: PowerTip of the Day - Undeleting Office365 Mailboxes (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您已删除 Office365 用户帐户，但后来意识到仍需要其邮箱中的数据，则可能可以恢复该邮箱。

首先，请检查邮箱是否已“软删除”。下一个命令列出了所有可恢复的邮箱：

```powershell
Get-Mailbox -SoftDeletedMailbox | Select UserPrincipalName, WhenSoftDeleted
```

每个邮箱都与用户主体名称相关联。要取消删除邮箱，您需要临时重新创建此帐户。接下来，您可以撤消邮件箱的删除操作。只需在以下命令中替换主体名称即可：

```powershell
Undo-SoftDeletedMailbox -SoftDeletedObject username@company.onmicrosoft.com
```
<!--本文国际来源：[Undeleting Office365 Mailboxes (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/undeleting-office365-mailboxes-part-1/)-->


---
layout: post
date: 2023-05-01 00:00:25
title: "PowerShell 技能连载 - Office365邮箱恢复删除（第 2 部分）"
description: PowerTip of the Day - Undeleting Office365 Mailboxes (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设有人离开了公司，您删除了其Office365用户帐户。事实证明，这也会删除附加的邮箱。如果您想将此邮箱附加到其他人身上，即仍然能够访问重要的公司或客户数据，则可以按照以下步骤操作。

首先，请检查邮箱是否已“软删除”并且仍然可以恢复：

```powershell
Get-Mailbox -SoftDeletedMailbox | Select-Object Name,ExchangeGUID
```

此列表中每个可恢复的邮箱都具有唯一的GUID。要将此邮箱附加到其他人身上，还需要找出要将已删除的邮箱附加到其中的仍处于活动状态的邮箱的GUID：

```powershell
$liveMailbox = Get-Mailbox existingPerson@somecompany.onmicrosoft.com | Select-Object Name,ExchangeGUID
```
接下来，在获取两个GUID后，发出请求以将旧邮件箱数据连接到新邮件箱，并指定目标根文件夹（例如“旧邮件内容”）。这将是新邮件箱显示在其下面的电子邮件文件夹：

```powershell
New-MailboxRestoreRequest -SourceMailbox [ENTER_GUID_OF_SOFTDELETED_MAILBOX] -TargetMailbox $liveMailbox.ExchangeGUID -AllowLegacyDNMismatch -TargetRootFolder "Old Mailbox Content
```
<!--本文国际来源：[Undeleting Office365 Mailboxes (Part 2)](https://blog.idera.com/database-tools/powershell/powertips/undeleting-office365-mailboxes-part-2/)-->


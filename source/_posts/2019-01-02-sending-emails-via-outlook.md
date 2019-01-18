---
layout: post
date: 2019-01-02 00:00:00
title: "PowerShell 技能连载 - 通过 Outlook 发送邮件"
description: PowerTip of the Day - Sending Emails via Outlook
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
您可以用 `Send-MailMessage` 通过任何 SMTP 服务器放松右键。不过，如果您希望使用 Outlook 客户端，例如要访问地址簿、使用公司的 Exchange 服务器，或者将邮件保存到邮件历史中，那么可以通过这个快速方法来实现：

```powershell
function Send-OutlookMail
{
    param
    (
        [Parameter(Mandatory=$true)]
        $To,

        [Parameter(Mandatory=$true)]
        $Subject,

        [Parameter(Mandatory=$true)]
        $BodyText,

        [Parameter(Mandatory=$true)]
        $AttachmentPath
    )

    
    $outlook = New-Object -ComObject Outlook.Application
    $mail = $outlook.CreateItem(0)
    $mail.Subject = $Subject
    $mail.to = $To

    $mail.BodyFormat = 1  # use 2 for HTML mails
    $mail.Attachments.Add([object]$AttachmentPath, 1)
    $mail.building = $BodyText
    $mail.Display($false)
}
```

这只是一个基本的模板，您可以投入一些时间使它变得更好。例如，当前版本总是需要一个附件。在更复杂的版本中，您可以使附件变成可选的，并且支持多个附件。或者寻找一种方法发送邮件而不需要用户交互。

<!--more-->
本文国际来源：[Sending Emails via Outlook](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sending-emails-via-outlook)

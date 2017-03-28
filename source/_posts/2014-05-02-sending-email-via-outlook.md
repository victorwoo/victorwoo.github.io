layout: post
title: "PowerShell 技能连载 - 通过 Outlook 发送电子邮件"
date: 2014-05-02 00:00:00
description: PowerTip of the Day - Sending Email via Outlook
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
您显然可以通过 `Send-MailMessage` 直接发送邮件。但如果您希望通过缺省的 MAPI 客户端发送电子邮件，也不会太麻烦：

    $subject = 'Sending via MAPI client'
    $body = 'My Message'
    $to = 'tobias@powertheshell.com'
    
    $mail = "mailto:$to&subject=$subject&body=$body"
    
    Start-Process -FilePath $mail 

这个脚本利用了 mailto: 语法。如果您已安装了一个 MAPI 客户端，这将打开一个电子邮件表单并且将脚本指定的内容填充进去。不过您需要手工发送邮件。

<!--more-->
本文国际来源：[Sending Email via Outlook](http://community.idera.com/powershell/powertips/b/tips/posts/sending-email-via-outlook)

layout: post
date: 2016-12-28 16:00:00
title: "PowerShell 技能连载 - 调整简单界面"
description: PowerTip of the Day - Adjusting Simple UIs
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
在前一个技能中您学到了如何使用 `Show-Command` 为基于文本的命令创建简单的 UI：

```powershell
#requires -Version 3.0

function Send-MailMessageUI
{
  Show-Command -Name Send-MailMessage
}

Send-MailMessageUI
```

如果您想调整 UI 中显示的参数的个数，只需要编写您自己的函数即可。

在下面的例子中，`Send-MailMessage` 被包裹在一个自定义的函数中，并只暴露其中的某些属性，然后在内部初始化其它的属性（例如 SMTP 服务器和凭据）。

以下是一个非常简单的 email 发送函数，只显示发送 email 的文本框：

```powershell
#requires -Version 3.0

function Send-MailMessageCustomized
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $From,

    [Parameter(Mandatory)]
    [string]
    $To,

    [Parameter(Mandatory)]
    [string]
    $Subject,

    [Parameter(Mandatory)]
    [string]
    $building,

    [switch]
    $BodyAsHTML
  )
  $username = 'mymailusername'
  $password = 'mymailpassword' # Dangerous, never hardcode! Consider using Get-Credential instead.
  $myServer = 'mail.mymailserver.mycompany.com'

  $passwordSecure = $password | ConvertTo-SecureString -AsPlainText -Force
  $myCred = New-Object -TypeName PSCredential($username, $passwordSecure)

  Send-MailMessage -From $From -To $To -Subject $Subject -building $building -BodyAsHtml:$BodyAsHTML -SmtpServer $myServer -Encoding UTF8 -Credential $myCred
}

function Send-MailMessageUI
{
  Show-Command -Name Send-MailMessageCustomized
}

Send-MailMessageUI
```

<!--more-->
本文国际来源：[Adjusting Simple UIs](http://community.idera.com/powershell/powertips/b/tips/posts/adjusting-simple-uis)

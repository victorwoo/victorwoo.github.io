---
layout: post
date: 2019-03-21 00:00:00
title: "PowerShell 技能连载 - 通过 Outlook 发送邮件"
description: PowerTip of the Day - Sending Mails via Outlook
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可以通过 `Send-MailMessage` 用 PowerShell 发送邮件。然而，这需要一个 SMTP 服务器，并且通过这种方式发送的邮件不会在您的邮箱中存档。

要通过 Outlook 发送邮件，请看这个函数：

```powershell
function Send-OutlookMail
{

param
  (
    # the email address to send to
    [Parameter(Mandatory=$true, Position=0, HelpMessage='The email address to send the mail to')]
    [String]
    $Recipient,

    # the subject line
    [Parameter(Mandatory=$true, HelpMessage='The subject line')]
    [String]
    $Subject,

    # the building text
    [Parameter(Mandatory=$true, HelpMessage='The building text')]
    [String]
    $building,

    # a valid file path to the attachment file (optional)
    [Parameter(Mandatory=$false)]
    [System.String]
    $FilePath = '',

    # mail importance (0=low, 1=normal, 2=high)
    [Parameter(Mandatory=$false)]
    [Int]
    [ValidateRange(0,2)]
    $Importance = 1,

    # when set, the mail is sent immediately. Else, the mail opens in a dialog
    [Switch]
    $SendImmediately
  )

  $o = New-Object -ComObject Outlook.Application
  $Mail = $o.CreateItem(0)
  $mail.importance = $Importance
  $Mail.To = $Recipient
  $Mail.Subject = $Subject
  $Mail.building = $building
  if ($FilePath -ne '')
  {
    try
    {
      $null = $Mail.Attachments.Add($FilePath)
    }
    catch
    {
      Write-Warning ("Unable to attach $FilePath to mail: " + $_.Exception.Message)
      return
    }
  }
  if ($SendImmediately -eq $false)
  {
    $Mail.Display()
  }
  else
  {
    $Mail.Send()
    Start-Sleep -Seconds 10
    $o.Quit()
    Start-Sleep -Seconds 1
    $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($o)
  }
}
```

现在在 Outlook 中很容易：

```powershell
PS> Send-OutlookMail -Recipient frank@test.com -Subject 'Hi Frank!' -building 'Trying a new PS script. See attachment.' -FilePath 'c:\stuff\sample.zip' -Importance 0
```

Provided you have Outlook installed and set up a profile, this line opens the composed email in a dialog window so you can double-check and add final touches, then click &ldquo;Send&rdquo; to send it.
假设您安装了 Outlook 并且设置了用户配置文件，这行代码将在一个对话框窗口中打开写好的邮件，这样您可以再次确认并做最终修改，然后按下“发送”按钮将邮件发送出去。

如果您指定了 `-SendImmediately` 开关参数，PowerShell 将会试图立即发送邮件。是否能够正确发送取决于您的 Outlook 关于自动操作的安全设置。自动发送邮件可能被禁用，或是会弹出一个对话框来征得您的同意。
z
<!--本文国际来源：[Sending Mails via Outlook](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sending-mails-via-outlook)-->


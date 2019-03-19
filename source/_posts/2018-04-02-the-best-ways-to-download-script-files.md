---
layout: post
date: 2018-04-02 00:00:00
title: "PowerShell 技能连载 - 下载脚本文件的最佳方式"
description: PowerTip of the Day - The Best Ways to Download Script Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时候，PowerShell 脚本的作者将脚本放在直接下载的服务器上。让我们寻找一种最有效的通过 PowerShell 下载文本文件的方法。我们将以 PowerShell Team 成员 Lee Holmes 发布的著名的 "Dancing Rick ASCII" 脚本作为我们的例子。它的下载地址位于这里（需要翻墙）：

http://bit.ly/e0Mw9w

当在浏览器中打开时，您将会见到以纯文本方式显示的 PowerShell 源代码，并且原始的 URL 将会显示在浏览器的地址栏里：

http://www.leeholmes.com/projects/ps_html5/Invoke-PSHtml5.ps1

许多用户像这样使用 .NET 方法来下载文本文件：

```powershell
# download code
$url = "http://bit.ly/e0Mw9w"
$webclient = New-Object Net.WebClient
$code = $webclient.DownloadString($url)

# output code
$code
```

其实并不需要这样，因为 `Invoke-WebRequest` 是对该对象的更好的封装：

```powershell
# download code
$url = "http://bit.ly/e0Mw9w"
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$code = $page.Content
```

通过它的参数，它能直接支持代理并且支持凭据。

还有一个更方便的 cmdlet `Invoke-RestMethod`。它基本上做的是相同的是，不过返回的数据是文本，JSON，或 XML：

```powershell
# download code
$url = "http://bit.ly/e0Mw9w"
$code = Invoke-RestMethod -Uri $url -UseBasicParsing
```

假设您信任这段代码，相信它不会损害您的系统，您可以这样执行它：

```powershell
# invoke the code
Invoke-Expression -Command $code
```

或者，您可以将它保存到磁盘，并且以一个普通的 PowerShell 脚本的方式执行它：

```powershell
# download code
$url = "http://bit.ly/e0Mw9w"
$code = Invoke-RestMethod -Uri $url -UseBasicParsing

# save to file and run
$outPath = "$home\Desktop\dancingRick.ps1"
$code | Set-Content -Path $outPath -Encoding UTF8
Start-Process -FilePath powershell -ArgumentList "-noprofile -noexit -executionpolicy bypass -file ""$outPath"""
```

如果您打算先将内容保存到一个文件，那么 `Invoke-WebRequest` 是一个更好的选择，因为它可以直接将内容保存到文件：

```powershell
# download code
$url = "http://bit.ly/e0Mw9w"
$outPath = "$home\Desktop\dancingRick.ps1"
$code = Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $outPath
& $outPath
```

您可以通过调用操作符 (`&`) 在您自己的 PowerShell 会话中运行下载的文件，而不是使用 `Start-Process`。如果执行失败，通常是因为您的执行策略不允许 PowerShell 脚本。请按如下方法改变设置，然后重试：

```powershell
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

<!--本文国际来源：[The Best Ways to Download Script Files](http://community.idera.com/powershell/powertips/b/tips/posts/the-best-ways-to-download-script-files)-->

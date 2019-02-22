---
layout: post
date: 2017-03-01 00:00:00
title: "PowerShell 技能连载 - Power Shell 5 的类继承（第二部分）"
description: PowerTip of the Day - Inheriting Classes in PowerShell 5 (part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是在 PowerShell 5 中使用新的类特性的另一个用例。在前一个例子中，我们演示了如何从 `System.Diagnostics.Process` 派生一个新类，从而获得代表进程的功能更强大的对象。

以下是一个从 `WebClient` 派生的类，`WebClient` 主要是用来连接网站。当您使用标准的 `WebClient` 对象是，它拒绝连接到证书错误的 HTTPS 网站。这是一件好事，但是有时候您仍需要连接这类网站。

```powershell
#requires -Version 5

class MyWebClient : System.Net.WebClient
{
  MyWebClient() : base()
  {
    # with SSL certificate errors, connect anyway
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    $proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    $this.Proxy = $proxy
    $this.UseDefaultCredentials = $true
    $this.Proxy.Credentials = $this.Credentials
  }
}

$client = [mywebclient]::new()
$client.DownloadString('http://www.psconf.eu')
```

这样，"`“MyWebClient”`" 类继承于 `WebClient()` 并改变了 `ServerCertificateValidationCallBack` 的行为。它只是返回 `$true`，所以所有的连接都是成功的，而且证书检验变得无关紧要。

<!--本文国际来源：[Inheriting Classes in PowerShell 5 (part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/inheriting-classes-in-powershell-5-part-2)-->

---
layout: post
date: 2021-09-08 00:00:00
title: "PowerShell 技能连载 - 从网站读取 HTTP 消息头"
description: PowerTip of the Day - Reading HTTP Headers from Websites
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您导航到一个网页时，您的浏览器会静默地接收 HTTP 标头中的元信息，而这些元信息通常是不可见的。

要显示任何网站的 HTTP 消息头，请尝试以下操作：

```powershell
# replace URL with any web page you like:
$url = 'www.tagesschau.de'
(Invoke-WebRequest -Method Head -Uri $url -UseBasicParsing).RawContent
```

诀窍是使用 `-Method` 参数并提交 `Head` 值来获取消息头而不是网页内容。

结果类似于：

    HTTP/1.1 200 OK
    Connection: keep-alive
    Access-Control-Allow-Origin: *
    Cache-Control: max-age=14
    Content-Type: text/html; charset=utf-8
    Date: Tue, 10 Aug 2021 12:06:37 GMT

The header info returned by a web page can vary greatly. When you replace the URL in above example with ‘www.google.de’, for example, you see many more instructions being sent to your browser, and you can actually “see” how the web page instructs your browser to set new cookies – so you can check whether the web page sets cookies before asking for consent or not:
网页返回的标题信息可能会有很大差异。例如，当您将上面示例中的 URL 替换为 "www.google.de" 时，您会看到更多的指令被发送到您的浏览器，您实际上可以“看到”网页如何指示您的浏览器设置新的 cookie——因此您可以在征求同意之前检查网页是否设置了 cookie：

    HTTP/1.1 200 OK
    X-XSS-Protection: 0
    X-Frame-Options: SAMEORIGIN
    Transfer-Encoding: chunked
    Cache-Control: private
    Content-Type: text/html; charset=UTF-8
    Date: Tue, 10 Aug 2021 12:07:06 GMT
    Expires: Tue, 10 Aug 2021 12:07:06 GMT
    P3P: CP="This is not a P3P policy! See g.co/p3phelp for more info."
    Set-Cookie: NID=221=C8RdXG_2bB_MwOG33_lS0hx3P5TF5_vaamoT0xj3yKgZPzCjr_g70NvJXkhenV_GMt1TYYU6XwmNOtlkRKRADiXgYJWWYp671M3DFL8DCxM_J1Cl01r39-jfA7sIxu1C
    -0B7CHI-8WfXj5IGZ5dHtRxndNA84cpQov5phLhi7l8; expires=Wed, 09-Feb-2022 12:07:06 GMT; path=/; domain=.google.de; HttpOnly
    Server: gws

如果您愿意，您也可以以表格形式获取消息头 —— 只需将 `RawContent` 替换为 `Headers`：

```powershell
# replace URL with any web page you like:
$url = 'www.google.de'
(Invoke-WebRequest -Method Head -Uri $url -UseBasicParsing).Headers
```

<!--本文国际来源：[Reading HTTP Headers from Websites](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-http-headers-from-websites)-->


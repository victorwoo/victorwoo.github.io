---
layout: post
date: 2019-06-20 00:00:00
title: "PowerShell 技能连载 - 在 Web Request 中使用会话变量"
description: PowerTip of the Day - Using Session Variables in Web Requests
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，Web Request 在浏览器中可以正常工作，但是在 PowerShell 中却不能。例如，当您在浏览器中导航到 [http://www.geocode.xyz/Bahnhofstrasse,Hannover?json=1](http://www.geocode.xyz/Bahnhofstrasse,Hannover?json=1)，可以获得 JSON 格式的坐标地址。

而当在 PowerShell 中做同样操作时，会得到奇怪的异常：

```powershell
$url = 'http://www.geocode.xyz/Bahnhofstrasse,Hannover?json=1'
Invoke-RestMethod -Uri $url
```

结果如下：

```powershell
Invoke-RestMethod : { "success": false, "error": { "code": "006", "message": "Request Throttled." } }
```

这里的秘密是需要先获取会话状态，会话状态包括 cookie 和其它细节，然后再根据会话状态重新提交 Web Service 请求。以下是它的工作方式：

```powershell
$url = 'http://www.geocode.xyz'
$urlLocation = "$url/Bahnhofstrasse,Hannover?json=1"

$null = Invoke-RestMethod -Uri $url -SessionVariable session
Invoke-RestMethod -Uri $urlLocation -WebSession $session
```

现在结果看起来正确了：

```powershell
standard  : @{stnumber=1; addresst=Bahnhofstrasse; postal=30159; region=DE; prov=DE; city=Hannover;
            countryname=Germany; confidence=0.8}
longt     : 9.73885
alt       :
elevation :
latt      : 52.37418
```

<!--本文国际来源：[Using Session Variables in Web Requests](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-session-variables-in-web-requests)-->


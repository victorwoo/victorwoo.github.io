---
layout: post
date: 2019-06-26 00:00:00
title: "PowerShell 技能连载 - 使用 GeoCoding：文本扫描（第 4 部分）"
description: 'PowerTip of the Day - Geocoding: Text Scanning (Part 4)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
地理编码可以自动从文本中提取地理信息。这个例子还展示了向服务器提交信息的一种新方法：在下面的例子中，数据用的是 HTML 表单中使用的相同机制发布到服务器。这样做通常是为了避免使用 URL 编码大量数据，因为当使用 POST 时，数据在 request 的 header 而不是 URL 中传输。这也允许发送更多的数据：

```powershell
'Ma io stasera volevo cenare al lume di candela, non cucinarci! #Milano #blackout' |
  ForEach-Object -Begin {$url='https://geocode.xyz'
    $null = Invoke-RestMethod $url -S session
  } -Process {
    Invoke-RestMethod $url -W $session -Method Post -Body @{scantext=$_;geoit='json'}

  }
```

结果如下：

    longt   matches match
    -----   ------- -----
    9.18067 1       {@{longt=9.18067; location=MILANO,IT; matchtype=locality; confidence=0.9; MentionIndices...

<!--本文国际来源：[Geocoding: Text Scanning (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/geocoding-text-scanning-part-4)-->


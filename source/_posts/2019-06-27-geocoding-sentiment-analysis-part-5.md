---
layout: post
date: 2019-06-27 00:00:00
title: "PowerShell 技能连载 - 使用 GeoCoding：情感分析（第 5 部分）"
description: 'PowerTip of the Day - Geocoding: Sentiment Analysis (Part 5)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
某些地理编码 API 提供了复杂的情感分析，如下面的示例所示：

```powershell
"Most important museums of Amsterdam are located on the Museumplein, located at the southwestern side of the Rijksmuseum." |
  ForEach-Object -Begin {$url='https://geocode.xyz'
    $null = Invoke-RestMethod $url -S session
  } -Process {
    Invoke-RestMethod $url -W $session -Method Post -Body @{scantext=$_;geoit='json';sentiment='analysis'}
  }
```

一段文本被发送到 API，并且 API 分析了地理内容且输出文本中找到的地理位置的详细信息：

```powershell
sentimentanalysis : @{allsentiments=; sentimentwords=; mainsentiment=}
longt             : 4.88702
matches           : 3
match             : {@{longt=4.88355; location=RIJKSMUSEUM, AMSTERDAM, NL; matchtype=street;
                    confidence=1.0; MentionIndices=108,26; latt=52.35976}, @{longt=4.88334;
                    location=MUSEUMPLEIN, AMSTERDAM, NL; matchtype=street; confidence=1.0;
                    MentionIndices=55,26; latt=52.35747}, @{longt=4.89416; location=Amsterdam,NL;
                    matchtype=locality; confidence=0.4; MentionIndices=26; latt=52.36105}}
latt              : 52.35943
```

<!--本文国际来源：[Geocoding: Sentiment Analysis (Part 5)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/geocoding-sentiment-analysis-part-5)-->


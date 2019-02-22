---
layout: post
date: 2016-12-12 00:00:00
title: "PowerShell 技能连载 - 分析结果出现次数（不浪费内存）"
description: PowerTip of the Day - Analyzing Result Frequencies (without Wasting Memory)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
用 `Group-Object` 可以基于共享的属性值对对象分组，但请不要忘记使用 `-NoElement` 参数来忽略实际的对象而只返回出现次数。

这行简单的代码告诉您指定文件夹中有哪些文件类型：

```powershell
Get-ChildItem -Path c:\Windows -File | Group-Object -Property Extension -NoElement
```

结果看起来如下：

```
Count Name                     
----- ----                     
   11 .exe                     
    1 .dat                     
    9 .log                     
    4 .xml                     
    1 .txt     
...
```

指定了 `-NoElement` 之后，您可以节约相当客观的内存，因为原对象不再包括在结果中。

<!--本文国际来源：[Analyzing Result Frequencies (without Wasting Memory)](http://community.idera.com/powershell/powertips/b/tips/posts/analyzing-result-frequencies-without-wasting-memory)-->

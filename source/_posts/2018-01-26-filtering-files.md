---
layout: post
date: 2018-01-26 00:00:00
title: "PowerShell 技能连载 - 过滤文件"
description: PowerTip of the Day - Filtering Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可能还没有注意到，`Get-ChildItem`（也叫做 `dir` 或者 `ls`） 的 `-Filter` 参数并不是像您所想的方式工作。以下代码的本意是只查找 PowerShell 脚本，但实际上找到的结果更多：

```powershell
  Get-ChildItem -Path $env:windir -Filter *.ps1 -Recurse -ErrorAction Silent |
    Group-Object -Property Extension -NoElement
```

以下是查找结果：

```
Count Name
----- ----
  800 .ps1
  372 .ps1xml
```

`-Filter` 参数的作用和传统的 `dir` 命令的行为类似。要真正起到您想要的效果，您应该使用以下代码：

```powershell
Get-ChildItem -Path $env:windir -Filter *.ps1 -Include *.ps1 -Recurse -ErrorAction SilentlyContinue |
  Group-Object -Property Extension -NoElement
```

以下是正确的结果：

```powershell
Count Name
----- ----
  800 .ps1
```

虽然您可以省略 `-Filter` 参数，但强烈建议保留着它。首先，`-Include` 只能和 `-Recurse` 配合使用；其次，`-Include` 速度很慢。先用一个粗略（但是快速）的 `-Filter` 过滤，然后用 `Include` 是最佳实践。

<!--本文国际来源：[Filtering Files](http://community.idera.com/powershell/powertips/b/tips/posts/filtering-files)-->

---
layout: post
date: 2019-09-17 00:00:00
title: "PowerShell 技能连载 - 实时日志处理"
description: PowerTip of the Day - Real-Time Log Processing
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 提供了一种强大而简单的方法来监视文件更改。假设您有一个经常更改的日志文件。以下是一个PowerShell脚本，用于监视日志文件的更改。每当发生更改时，都会执行一些代码:

```powershell
# make sure this points to a log file
$Path = '\\myserver\report2.txt'

Get-Content -Path $Path -Tail 0 -Wait |
ForEach-Object {
    "Detected $_"
}
```

只要确保修改 `$path` 指向某个实际的日志文件。每当向文件附加文本（并且保存更改），`ForEach-Object` 循环都会执行脚本块并输出 "Detected "。通过这种方式，您可以方便地响应实际的改变。

`Get-Content` 完成繁重的工作：`-Wait` 启用内容监视，`-Tail 0` 确保忽略现有内容，只查找新添加的文本。

<!--本文国际来源：[Real-Time Log Processing](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/real-time-log-processing)-->


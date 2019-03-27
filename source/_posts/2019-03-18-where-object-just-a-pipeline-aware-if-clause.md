---
layout: post
date: 2019-03-18 00:00:00
title: "PowerShell 技能连载 - Where-Object: 只是一个带管道的 IF 语句"
description: 'PowerTip of the Day - Where-Object: Just A Pipeline-Aware If-Clause'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Where-Object` 是一个最常用的 PowerShell 命令，不过新手可能对它不太熟悉。对于熟悉 "SQL" 数据库查询语言的人可以像 SQL 中的 `Where` 从句一样使用它；它是一个客户端的过滤器，能去除不需要的项目。以下这行代码将处理所有服务并只显示当前正在运行的服务：

```powershell
Get-Service | Where-Object { $_.Status -eq "Running" }
```

要更好地理解 `Where-Object` 如何工作，实际上它只是一个对管道发生作用的 IF 语句。以上代码等同于这个：

```powershell
Get-Service | ForEach-Object {
    if ($_.Status -eq &#39;Running&#39;)
    { $_ }
}
```

或者，完全不用代码的传统实现方式：

```powershell
$services = Get-Service
Foreach ($_ in $services)
{
  if ($_.Status -eq &#39;Running&#39;)
  {
    $_
  }
}
```

<!--本文国际来源：[Where-Object: Just A Pipeline-Aware If-Clause](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/where-object-just-a-pipeline-aware-if-clause)-->


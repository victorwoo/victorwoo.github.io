---
layout: post
date: 2019-03-04 00:00:00
title: "PowerShell 技能连载 - 创建对齐的标题"
description: PowerTip of the Day - Creating Aligned Headers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中常常需要创建报表和日志。以下是一个创建漂亮的居中标题的函数。只需要将 `$width` 改为期望的宽度：

```powershell
function Show-Header($Text)
{
  $Width=80
  $padLeft = [int]($width / 2) + ($text.Length / 2)
  $text.PadLeft($padLeft, "=").PadRight($Width, "=")
  }
```

以下是执行结果：

```powershell
PS> Show-Header Starting
====================================Starting====================================

PS> Show-Header "Processing Input Values"
=============================Processing Input Values============================

PS> Show-Header "Calculating..."
=================================Calculating...=================================

PS> Show-Header "OK"
=======================================OK=======================================
```

额外的知识点如下：

* 使用 `PadLeft()` 和 `PadRight()` 来填充（扩展）两端，并且是使用您希望的字符来填充空白。

基于这个知识点，现在可以做许多相关的事情，例如创建一个固定宽度的服务器名称列表：

```powershell
1,4,12,888 | ForEach-Object { 'Server_' + "$_".PadLeft(8, "0") }

Server_00000001
Server_00000004
Server_00000012
  Server_00000888
```

<!--本文国际来源：[Creating Aligned Headers](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-aligned-headers)-->

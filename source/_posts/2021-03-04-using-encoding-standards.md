---
layout: post
date: 2021-03-04 00:00:00
title: "PowerShell 技能连载 - 使用编码标准"
description: PowerTip of the Day - Using Encoding Standards
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用文本文件时，务必始终使用相同的文本编码进行读取和写入，否则特殊字符可能会损坏，或者文本文件可能变得不可读，这一点很重要。

在 PowerShell 7 中，除非您指定其他编码，否则所有 cmdlet 以及重定向操作符都将使用默认的 UTF8 文本编码。那挺好的。

在W indows PowerShell 中，不同的 cmdlet 使用不同的默认编码。所以，要为所有 cmdlet 和重定向操作符建立通用的默认默认编码，您应该为带有参数 `-Encoding` 的任何命令设置默认参数值。

将以下行放入您的配置文件脚本中：

```powershell
$PSDefaultParameterValues.Add('*:Encoding', 'UTF8')
```

此外，在 Windows PowerShell 中，无论 cmdlet 是否具有参数 `-Encoding`，都指定一个唯一的值。当前推荐的编码为UTF8。

<!--本文国际来源：[Using Encoding Standards](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-encoding-standards)-->

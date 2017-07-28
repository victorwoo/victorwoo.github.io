---
layout: post
date: 2017-07-27 00:00:00
title: "PowerShell 技能连载 - 简单解析设置文件（第二部分）"
description: PowerTip of the Day - Easy Parsing of Setting Files (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
在前一个技能中我们使用了 `ConvertFrom-StringData` 来将纯文本键值对转换为哈希表。

以下是一个转换失败的例子：

```powershell
$settings = @'
Machine=Server12
Path=c:\test
'@

$settings | ConvertFrom-StringData
```

当您查看结果时，很快能发现失败的原因：

```powershell
Name                           Value
----                           -----
Machine                        Server12
Path                           c:	est
```

显然，`ConvertFrom-StringData` 将 "`\`" 视为一个转义符，在上述例子中增加了一个制表符 ("`\t`")，并吃掉了字面量 "t"。

要解决这个问题，请始终将 "`\`" 转义为 "`\\`"。以下是正确的代码：

```powershell
$settings = @'
Machine=Server12
Path=c:\\test
'@

$settings | ConvertFrom-StringData
```

现在结果看起来正确了：

```powershell
Name                           Value
----                           -----
Machine                        Server12
Path                           c:\test
```

<!--more-->
本文国际来源：[Easy Parsing of Setting Files (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/easy-parsing-of-setting-files-part-2)

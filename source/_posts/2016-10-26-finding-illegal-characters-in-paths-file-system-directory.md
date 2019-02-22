---
layout: post
date: 2016-10-26 00:00:00
title: "PowerShell 技能连载 - 查找文件路径中的非法字符（基于文件系统）"
description: PowerTip of the Day - Finding Illegal Characters in Paths (File System)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
之前我们演示了如何使用简易的基于正则表达式的方法来查找字符串中的非法字符。我们鼓励您将这种策略运用到各种需要验证的字符串中。

如果您希望检测文件系统中的非法字符，以下是一个简单的适配：

```powershell
# check path:
$pathToCheck = 'c:\test\<somefolder>\f|le.txt'

# get invalid characters and escape them for use with RegEx
$illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
$pattern = "[$illegal]"

# find illegal characters
$invalid = [regex]::Matches($pathToCheck, $pattern, 'IgnoreCase').Value | Sort-Object -Unique 

$hasInvalid = $invalid -ne $null
if ($hasInvalid)
{
  "Do not use these characters in paths: $invalid"
}
else
{
  'OK!'
}
```

非法的字符是从 `GetInvalidPathChars()` 中提取的并且用正则表达式转换为转义字符串。这个列表放在方括号中，所以当其中任一字符匹配成功时，`RegEx` 将能够报告匹配结果。

以下是结果：

    Do not use these characters in paths: | < >


<!--本文国际来源：[Finding Illegal Characters in Paths (File System)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-illegal-characters-in-paths-file-system-directory)-->

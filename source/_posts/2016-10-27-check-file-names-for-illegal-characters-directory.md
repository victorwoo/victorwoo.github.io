---
layout: post
date: 2016-10-27 00:00:00
title: "PowerShell 技能连载 - 检查文件名的非法字符"
description: PowerTip of the Day - Check File Names for Illegal Characters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
文件的命名是十分敏感的，不能包含某些特定的保留字符。要验证文件名并确保这些字符是合法的，以下对昨天的脚本（检查文件系统路径）做了一点改进。这个脚本检查文件名的合法性：

```powershell
# check path:
$filenameToCheck = 'testfile:?.txt'

# get invalid characters and escape them for use with RegEx
$illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
$pattern = "[$illegal]"

# find illegal characters
$invalid = [regex]::Matches($filenameToCheck, $pattern, 'IgnoreCase').Value | Sort-Object -Unique

$hasInvalid = $invalid -ne $null
if ($hasInvalid)
{
  "Do not use these characters in file names: $invalid"
}
else
{
  'OK!'
}
```

结果如下：

    Do not use these characters in file names: : ?


<!--本文国际来源：[Check File Names for Illegal Characters](http://community.idera.com/powershell/powertips/b/tips/posts/check-file-names-for-illegal-characters-directory)-->

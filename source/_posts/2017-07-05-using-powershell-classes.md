---
layout: post
date: 2017-07-05 00:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 类（一）"
description: PowerTip of the Day - Using PowerShell Classes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5 开始，您可以定义类。它们有许多应用场景。一个是为有用的工具函数创建一个库来更好地整理它们。要实现这个功能，这个类要定义一些 "static" 方法。以下是一个简单的例子：

```powershell
class HelperStuff
{
    # get first character of string and throw exception
    # when string is empty or multi-line
    static [char] GetFirstCharacter([string]$Text)
    {
        if ($Text.Length -eq 0) { throw 'String is empty' }
        if ($Text.Contains("`n")) { throw 'String contains multiple lines' }
        return $Text[0]
    }

    # get file extension in lower case
    static [string] GetFileExtension([string]$Path)
    {
        return [Io.Path]::GetExtension($Path).ToLower()
    }
}
```

"HelperStuff" 类定义了 "`GetFirstCharacter`" 和 "`GetFileExtension`" 两个静态方法。现在查找和使用这些工具函数非常方便：

```powershell
PS> [HelperStuff]::GetFirstCharacter('Tobias')
T

PS> [HelperStuff]::GetFileExtension('c:\TEST.TxT')
.txt

PS> [HelperStuff]::GetFileExtension($profile)
.ps1

PS>
```

<!--本文国际来源：[Using PowerShell Classes](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-classes)-->

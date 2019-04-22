---
layout: post
date: 2019-04-15 00:00:00
title: "PowerShell 技能连载 - 向字符串添加数字（第 2 部分）"
description: PowerTip of the Day - Adding Numbers to a String (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
In the previous tip we illustrated a number of ways how to safely add variables to string content. Adding variables to double-quoted text can expose yet another issue with automatic variable detection. Have a look:
在前一个技能中我们演示了一系列安全地将变量加入到字符串中的方法。将变量变量添加到双引号包围的文本中会导致

    # this is the desired output:
    # PowerShell Version is 5.1.17763.316

    # this DOES NOT WORK:
    "PowerShell Version is $PSVersionTable.PSVersion"

当您运行这段代码，输出结果并不是大多数人想象的那样。语法着色已经暗示了错误的地方：双引号括起来的字符串只会解析变量。他们不关心后续的任何信息。所以由于 `$PSVersionTable` 是一个哈希表对象，PowerShell 输出的是对象类型名称，然后在后面加上 ".PSVersion"：

```powershell
PS> "PowerShell Version is $PSVersionTable.PSVersion"
PowerShell Version is System.Collections.Hashtable.PSVersion
```

以下是四种有效的实现：

```powershell
# use a subexpression
"PowerShell Version is $($PSVersionTable.PSVersion)"

# use the format (-f) operator
'PowerShell Version is {0}' -f $PSVersionTable.PSVersion


# concatenate (provided the first element is a string)
'PowerShell Version is ' + $PSVersionTable.PSVersion

# use simple variables
$PSVersion = $PSVersionTable.PSVersion
"PowerShell Version is $PSVersion"
```

<!--本文国际来源：[Adding Numbers to a String (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-numbers-to-a-string-part-2)-->


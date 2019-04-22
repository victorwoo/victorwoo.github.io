---
layout: post
date: 2019-04-12 00:00:00
title: "PowerShell 技能连载 - 向字符串添加数字（第 1 部分）"
description: PowerTip of the Day - Adding Numbers to a String (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
双引号括起来的字符串可以方便地扩展变量，但是这个概念并不是万无一失的：

```powershell
$id = 123

# this is the desired output:
# Number is 123:
# this DOES NOT WORK:
"Number is $id:"
```

如您所见的上述例子中，当您在双引号中放置变量时，PowerShell 自动判断变量的起止位置。而 `:` 被当成变量的一部分。要修复这个问题，您需要某种方法来明确地标记变量的起止位置。以下是一些修复这类问题的方法：

```powershell
$id = 123

# PowerShell escape character ends the variable
"Number is $id`:"
# braces "embrace" the variable name
"Number is ${id}:"
# subexpressions execute the code in the parenthesis
"Number is $($id):"
# the format operator inserts the array on the right into the
# placeholders in the template on the left
'Number is {0}:' -f $id
# which is essentially this:
'Number is ' + @($id)[0] + ':'

# careful with "addition": this requires the first
# element to be a string. So this works:
'Number is ' + $id + ':'
# this won't:
$id + " is the number"
# whereas this will again:
'' + $id + " is the number"
```

<!--本文国际来源：[Adding Numbers to a String (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-numbers-to-a-string-part-1)-->


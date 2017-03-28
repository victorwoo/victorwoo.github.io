layout: post
title: "在 PowerShell 中利用正则表达式来解析文本块"
date: 2014-10-11 16:51:28
description: "Use Regular Expression to Extract Text Blocks in PowerShell"
categories:
- powershell
- text
tags:
- powershell
- regex
- text
---
# 需求
给定一段文本，如：

    1, abcd [xxxx]
    vkjl gas kje asld
    gew wef
    2, bbb [wefs]
    oioias wmfjalkjs
    3, ccc [wegas]
    kzxlj kjlwiewe ii

要求分割成多段以数字开头的文本块，如：

第一块：

    1, abcd [xxxx]
    vkjl gas kje asld
    gew wef

第二块：

    2, bbb [wefs]
    oioias wmfjalkjs

第三块：

    3, ccc [wegas]
    kzxlj kjlwiewe ii

# 思路
- 定义我们要东西为 n 个“block”。
- 每个“block”的特征是：
    * 以数字开头
    * block 之前可能是整段文本的起始；也有可能是一个回车符。
    * block 之后可能是一个回车符+下一行的数字；也有可能是整段文本的结束。
- block 之前和之后的回车符是不需要的
- block 应该尽可能“非贪婪”，遇到下一个符合条件的，算作一个新的 block 开始。

其中，“block 之前和之后的回车符是不需要的”可以用正则表达式的“零宽断言”来解决。

# 代码

    $subject = @'
    1, abcd [xxxx]
    vkjl gas kje asld
    gew wef
    2, bbb [wefs]
    oioias wmfjalkjs
    3, ccc [wegas]
    kzxlj kjlwiewe ii
    '@

    $resultlist = new-object System.Collections.Specialized.StringCollection
    $regex = [regex]@'
    (?snx)(^|(?<=\n))
    (?<block>\d, .*?)
    ((?=\n\d, )|$)
    '@
    $match = $regex.Match($subject)
    while ($match.Success) {
        $resultlist.Add($match.Groups['block'].Value) | out-null
        $match = $match.NextMatch()
    } 

    $resultlist | ForEach-Object {
        echo $_
        echo ---
    }

# 输出结果

    1, abcd [xxxx]
    vkjl gas kje asld
    gew wef
    ---
    2, bbb [wefs]
    oioias wmfjalkjs
    ---
    3, ccc [wegas]
    kzxlj kjlwiewe ii
    ---

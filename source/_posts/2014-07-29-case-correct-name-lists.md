layout: post
date: 2014-07-29 11:00:00
title: "PowerShell 技能连载 - 修正名单中的大小写"
description: PowerTip of the Day - Case-Correct Name Lists
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
_适用于所有 PowerShell 版本_

假设您的工作是更新一份名单。以下方法可以确保只有名字的第一个字母改成大写。这个方法对于**姓-名**的方式也是有效的：

    $names = 'some-wILD-casING','frank-PETER','fred'
    
    Foreach ($name in $names)
    {
      $corrected = foreach ($part in $name.Split('-'))
      {
        $firstChar = $part.Substring(0,1).ToUpper()
        $remaining = $part.Substring(1).ToLower()
        
        "$firstChar$remaining"
      }  
      $corrected -join '-'
    }
    
    Some-Wild-Casing
    Frank-Peter
    Fred

<!--more-->
本文国际来源：[Case-Correct Name Lists](http://community.idera.com/powershell/powertips/b/tips/posts/case-correct-name-lists)

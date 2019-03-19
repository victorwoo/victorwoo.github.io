---
layout: post
date: 2015-08-21 11:00:00
title: "PowerShell 技能连载 - 快速设置多个环境变量"
description: PowerTip of the Day - Quickly Setting Multiple Environment Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一种快速（并且永久地）设置一系列环境变量的很棒的方法：

    $hashtable = @{
        Name = 'Weltner'
        ID = 12
        Ort = 'Hannover'
        Type = 'Notebook'
        ABC = 123
    }

    $hashtable.Keys | ForEach-Object {
        $Name = $_
        $Value = $hashtable.$Name
        [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    }

只需要在一个哈希表中定义变量。该脚本将为每个键值对创建一个环境变量。将“`User`”替换为“`Machine`”，就可以创建系统级别的环境变量。不过这将需要管理员权限。

通过类似的方法，您也可以删除环境变量。只需要将空字符串赋值给哈希表中的值即可。

<!--本文国际来源：[Quickly Setting Multiple Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/quickly-setting-multiple-environment-variables)-->

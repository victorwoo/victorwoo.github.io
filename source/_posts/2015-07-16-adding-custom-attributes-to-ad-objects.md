---
layout: post
date: 2015-07-16 11:00:00
title: "PowerShell 技能连载 - 向 AD 对象增加自定义属性"
description: PowerTip of the Day - Adding Custom Attributes to AD Objects
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想向一个 AD 对象增加自定义属性，只需要用一个哈希表，然后增加期望的属性名和属性值。然后用 `Set-ADUser`（在随微软免费的 RSAT 工具发布的 ActiveDirectory 模块中）。

这个例子将想当前的用户账户增加两个扩展属性（请确保不要破坏基础环境的属性！请使用测试环境来学习）：

    #requires -Version 1 -Modules ActiveDirectory
    # create an empty hash table
    $custom = @{}

    # add the attribute names and values
    $custom.ExtensionAttribute3 = 12
    $custom.ExtensionAttribute4 = 'Hello'

    # assign the attributes to your current user object
    $user = $env:USERNAME
    Set-ADUser -Identity $user -Add $custom

选择正确的参数很重要。用 `-Add` 参数向属性增加新的值用 `-Remove` 移除一个已有的值用 `-Replace` 将属性替换为一个新的值。

<!--本文国际来源：[Adding Custom Attributes to AD Objects](http://community.idera.com/powershell/powertips/b/tips/posts/adding-custom-attributes-to-ad-objects)-->

---
layout: post
date: 2015-09-11 11:00:00
title: "PowerShell 技能连载 - 创建真实的类"
description: PowerTip of the Day - Creating Real Classes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 5.0 开始引入了类的概念，不过您也可以在 PowerShell 的其它版本中使用自定义类。只需要用 C# 代码来定义真正的类，然后用 `Add-Type` 来编译这些类。

以下是一个创建一个名为“myClass”，包含三个属性的新类。PowerShell 接下来可以用 `New-Object` 命令创建对象。

    $code = '
        using System;
        public class myClass
        {
            public bool Enabled { get; set; }
            public string Name { get; set; }
            public DateTime Time { get; set; }


        }

    '

    Add-Type -TypeDefinition $code
    $instance = New-Object -TypeName myClass
    $instance.Enabled = $true
    $instance.Time = Get-Date
    $instance.Name = $env:username
    $instance

为什么需要这么做呢？自定义的类可以包含来自多个来源的信息，而且您可以使用 C# 的各种复杂特性来定义您的类，包括方法、动态和静态成员等。

显然，拥有一些技术背景的开发人员对这种技术最感兴趣。

<!--本文国际来源：[Creating Real Classes](http://community.idera.com/powershell/powertips/b/tips/posts/creating-real-classes)-->

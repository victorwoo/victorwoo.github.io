---
layout: post
date: 2014-07-28 11:00:00
title: "PowerShell 技能连载 - 使系统休眠"
description: PowerTip of the Day - Hibernate System
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

以下是一个简单的系统调用，可以使系统休眠（当然，前提是启用了休眠功能）：

    function Start-Hibernation
    {
      rundll32.exe PowrProf.dll, SetSuspendState 0,1,0
    }

请注意这个函数调用是大小写敏感的！

<!--本文国际来源：[Hibernate System](http://community.idera.com/powershell/powertips/b/tips/posts/hibernate-system)-->

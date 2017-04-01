layout: post
date: 2016-02-19 12:00:00
title: "PowerShell 技能连载 - 用 #requires 语句装饰脚本"
description: 'PowerTip of the Day - Decorate Scripts with #requires Statements'
categories:
- powershell
- tip
tags:
- powershell
- tip个
- powertip
- series
- translation
---
PowerShell 支持一系列 `#requires` 语句。技术上它们是注释，但是 PowerShell 会检查这些语句所申明的必要条件，并且如果条件不满足，它将不会执行这个脚本。另外，`#requires` 语句能快速地告知您运行脚本的前提条件。

    #requires -Modules PrintManagement
    #requires -Version 3
    #Requires -RunAsAdministrator
    

`#requires` 语句必须是一个脚本的第一条语句，并且它只对保存的脚本有效。

<!--more-->
本文国际来源：[Decorate Scripts with #requires Statements](http://community.idera.com/powershell/powertips/b/tips/posts/decorate-scripts-with-requires-statements)

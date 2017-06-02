---
layout: post
title: 从命令行运行 PowerShell
date: 2014-08-03 21:31:42
description: Run PowerShell from command line
categories: powershell
tags:
- powershell
---
从命令行运行 PowerShell 命令最精炼的代码：

    @powershell -nop -ex unrestricted -c "Get-ChildItem"

最后一个参数可以换成别的命令。另外，从命令行运行 .ps1 脚本的方式是：

    @powershell -nop -ex unrestricted .\something.ps1

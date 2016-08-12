layout: post
title: "PowerShell 技能连载 - 验证 UNC 路径"
date: 2014-04-02 00:00:00
description: PowerTip of the Day - Testing UNC Paths
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
`Test-Path` 命令可以检测指定的文件或文件夹是否存在。它对于使用盘符的路径工作正常，但是对于纯 UNC 路径则不可用。

最简单的情况下，这应该返回 $true，并且它的确返回了 $true（假设您没有禁用管理员共享）：

    $path = '\\127.0.0.1\c$'
    
    Test-Path -Path $path 

现在，同样的代码却返回 $false：

    Set-Location -Path HKCU:\
    $path = '\\127.0.0.1\c$'
    
    Test-Path -Path $path 

如果路径不是使用一个盘符，PowerShell 将使用当前路径，如果该路径指向一个非文件系统位置，`Test-Path` 将在该 provider 的上下文中解析 UNC 路径。由于注册表中没有这个路径，`Test-Path` 返回 $false。

要让 `Test-Path` 在 UNC 路径下可靠地工作，请确保您在 UNC 路径之前添加了 `FileSystem` provider。现在，无论当前位于哪个驱动器路径，结果都是正确的：

    Set-Location -Path HKCU:\
    $path = 'filesystem::\\127.0.0.1\c$'
    
    Test-Path -Path $path 

<!--more-->
本文国际来源：[Testing UNC Paths](http://powershell.com/cs/blogs/tips/archive/2014/04/02/testing-unc-paths.aspx)

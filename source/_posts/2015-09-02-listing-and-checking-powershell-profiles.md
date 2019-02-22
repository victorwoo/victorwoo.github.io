---
layout: post
date: 2015-09-02 11:00:00
title: "PowerShell 技能连载 - 列出（并检查）PowerShell 用户配置"
description: PowerTip of the Day - Listing (and Checking) PowerShell Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
用户配置脚本指的是当 PowerShell 启动时自动执行的 PowerShell 脚本。主用户配置脚本的路径可以通过 `$profile` 获得。

要获得所有可能的用户配置脚本路径，可以使用以下代码：

    #requires -Version 1
    ($profile | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $profile.$_ }

要检查您机器上的所有用户配置，请使用这段示例代码：

    #requires -Version 3
    ($profile | Get-Member -MemberType NoteProperty).Name |
      ForEach-Object {
          $path = $profile.$_
          New-Object PSObject -Property ([Ordered]@{Path=$Path; Exists=(Test-Path $Path) })
    
      }

输出结果类似如下：

    Path                                                                            Exists
    ----                                                                            ------
    C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1                           False
    C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1   False
    C:\Users\user09\Documents\WindowsPowerShell\profile.ps1                           True
    C:\Users\user09\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1   True

这个例子有趣的地方是如何编程获取对象的属性。您可以使用 `Get-Member` 来查找某个对象的属性名。我们将在接下来的文章中介绍这个隐藏的技能。

<!--本文国际来源：[Listing (and Checking) PowerShell Profiles](http://community.idera.com/powershell/powertips/b/tips/posts/listing-and-checking-powershell-profiles)-->

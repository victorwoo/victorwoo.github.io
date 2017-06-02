---
layout: post
date: 2014-08-05 11:00:00
title: "PowerShell 技能连载 - 编辑“hosts”文件"
description: "PowerTip of the Day - Edit Network “hosts” File"
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

如果您常常需要修改“hosts”文件，那么手工用提升权限的记事本实例来打开文件是相当乏味的事情。这是因为该文件只能被 Administrators 用户修改，所以普通的记事本实例无法修改它。

以下是一段您可以直接使用，或者调整一下用来打开任何需要提升权限的程序的脚本。

    function Show-HostsFile
    {
      $Path = "$env:windir\system32\drivers\etc\hosts"
      Start-Process -FilePath notepad -ArgumentList $Path -Verb runas
    }

<!--more-->
本文国际来源：[Edit Network “hosts” File](http://community.idera.com/powershell/powertips/b/tips/posts/edit-network-hosts-file)

---
layout: post
date: 2015-08-27 11:00:00
title: "PowerShell 技能连载 - 映射网络驱动器（第 1 部分）"
description: PowerTip of the Day - Mapping Network Drives (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 支持控制台命令，所以如果您需要映射一个网络驱动器，通常最可靠的方式是使用传统好用的 `net.exe`，类似这样：

    #requires -Version 1
    net.exe use M: '\\dc-01\somefolder' /PERSISTENT:YES
    
    Test-Path -Path M:\
    
    explorer.exe M:\
    

如果您忽略“`/PERSISTENT:YES`”参数，那么映射的驱动器将只是临时的，注销并登录后将不会自动重连。

请注意如果驱动器号 M: 已在使用中，将会收到一个错误。将 M: 换成一个星号，将自动使用下一个可用的驱动器号。

要提交登录凭据，请使用这种方法：

    net.exe use * '\\dc-01\somefolder' /PERSISTENT:YES /USER:training\user03 *

这将以 _training\user03_ 的身份登录，并使用下一个可用的驱动器号，并且交互式地询问密码。请注意这只能在普通的 PowerShell 控制台中使用。它不能在 PowerShell ISE 中使用，因为 PowerShell ISE 并没有一个真实的控制台，所以无法交互式地询问密码。

要提交密码，将用户名之后的星号替换为密码。这当然不是很好的实践，因为这将把密码透露给所有可以查看代码的人。

<!--本文国际来源：[Mapping Network Drives (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/mapping-network-drives-part-1)-->

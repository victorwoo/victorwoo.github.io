layout: post
date: 2016-10-17 16:00:00
title: "PowerShell 技能连载 - 理解二次远程连接问题"
description: PowerTip of the Day - Understanding the Double-Hop Problem in Remoting
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
当您用 `Invoke-Command` 远程执行 PowerShell 代码时，您的凭据将会锁定在首个连接的机器上。

PowerShell 远程连接默认情况下不会传递您的凭据，不会使用您的凭据来登录别的系统。这听起来是个好主意，不过在某些情况也严重限制了您的代码。

这是一个典型的错误代码：

```powershell
$code = 
{
  Get-ChildItem -Path  \\fls01\#TRAIN1\PowerShell\Class  
}

Invoke-Command -ScriptBlock $code -ComputerName server1
```

这段代码试图在远程访问一个文件共享。但是即便您有权限访问该共享，这段远程代码也无法使用您的身份进行第三方验证（在这个例子中是文件服务器）。

<!--more-->
本文国际来源：[Understanding the Double-Hop Problem in Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-the-double-hop-problem-in-remoting)

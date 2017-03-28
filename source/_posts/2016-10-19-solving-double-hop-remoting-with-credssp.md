layout: post
date: 2016-10-19 00:00:00
title: "PowerShell 技能连载 - 用 CredSSP 解决二次远程连接"
description: PowerTip of the Day - Solving Double Hop Remoting with CredSSP
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
在钱一个技能中我们演示了当您的远程代码试图通过第三方身份认证时会遇到的二次远程连接问题。

在您在客户端和服务端之间创建了一个可信的连接之后，可以传递您的凭据（只需要做一次，并且需要管理员权限）。

在客户端，运行这段代码：

```powershell
Enable-WSManCredSSP -Role Client -DelegateComputer nameOfServer
```

在服务端，运行这段代码：

```
Enable-WSManCredSSP -Role Server
```

现在将 PowerShell 代码从客户端发送到服务端并执行时，服务端能够将您的凭据送给第三方验证通过，所以远程代码可以通过文件服务器的身份认证并访问共享文件夹：

```powershell
#requires -Version 3.0

$code = 
{
  Get-ChildItem -Path  \\fls01\#TRAIN1\PowerShell\Class  
}

Invoke-Command -Authentication Credssp -ScriptBlock $code -ComputerName nameOfServer -Credential myCompany\myName
```

请注意当您使用 CredSSP 验证时，您必须提交显式的凭据（用 `-Credential`）且无法通过 Kerberos 透明传输当前的身份。

<!--more-->
本文国际来源：[Solving Double Hop Remoting with CredSSP](http://community.idera.com/powershell/powertips/b/tips/posts/solving-double-hop-remoting-with-credssp)

layout: post
date: 2016-11-27 16:00:00
title: "PowerShell 技能连载 - 用其他身份启动程序"
description: PowerTip of the Day - Launching Applications as Someone Else
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
假设您想以不同的身份打开多个 PowerShell 控制台，或以其他人的身份打开任何程序。

要实现这个目标，您需要以其他人的身份登录，这很明显是个负担。以下是将凭据以安全的方式保存到文件的方法：密码采用您的身份和您的机器加密成密文。只有保存它们的那个人可以取回它，而且只能在保存该文件的机器上操作：

```powershell
# saving credential securely to file
Get-Credential | Export-Clixml -Path "$home\login.xml"
```

这个凭据将保存到用户配置中。如果您希望保存到其它地方，请改变路径。喜欢保存多少份，就调用多少次该方法。

下一步，假设您加载了一个保存的凭据，并且使用该身份启动了一个程序：

```powershell
# getting back saved credential
$cred = Import-Clixml -Path "$home\login.xml"
# launch application
Start-Process -FilePath powershell -Credential $cred -Work c:\ -LoadUserProfile
```

这将以您之前指定的用户身份创建一个新的 PowerShell 实例——无需手动登录。

<!--more-->
本文国际来源：[Launching Applications as Someone Else](http://community.idera.com/powershell/powertips/b/tips/posts/launching-applications-as-someone-else)

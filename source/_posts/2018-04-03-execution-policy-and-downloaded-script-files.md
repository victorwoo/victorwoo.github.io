---
layout: post
date: 2018-04-03 00:00:00
title: "PowerShell 技能连载 - 执行策略和下载的脚本文件"
description: PowerTip of the Day - Execution Policy and Downloaded Script Files
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
当您从 internet 下载了一个文件，它可能会被 Windows 标记（通过 NTFS 流），并且 PowerShell 可能会拒绝执行它：

```powershell
PS> & "$home\desktop\Rick.ps1"
& : File C:\Users\tobwe\desktop\Rick.ps1 cannot be loaded. The file C:\Users\tobwe\desktop\Rick.ps1 is not digitally signed. You cannot run this script on the 
current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at 
https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:3
+ & "$home\desktop\Rick.ps1"
+   ~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess 
```

通常，当执行策略没有设置，或者设成 "RemoteSigned" 的时候会出现这种情况。这是普通 PowerShell 用户推荐的设置。以下是启用设置的方法：

```powershell
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned  
```

当启用以后，您可以运行任何本地脚本文件，或域之内的网络文件，但您不再能运行标记为“下载”的脚本，或从您域之外的网络位置下载的脚本。

要运行屏蔽的脚本，以下是您的选项：

* 取消对该文件的屏蔽，主要是通过打开它的属性对话框，单击“解除锁定”
* 使用 `Unblock-File`
* 将文件内容拷贝到一个新的文件
* 将执行策略设为 "Bypass"
* 用不会标记下载文件的浏览器来下载，或用 `Invoke-WebRequest` 来下载：

```powershell
PS> Invoke-WebRequest -Uri "http://bit.ly/e0Mw9w" -UseBasicParsing -OutFile  "$home\Desktop\Rick.ps1"  
```

`Invoke-WebRequest` 不会对下载的文件做标记，而且允许通过执行策略，这是挺令人意外的行为。

<!--more-->
本文国际来源：[Execution Policy and Downloaded Script Files](http://community.idera.com/powershell/powertips/b/tips/posts/execution-policy-and-downloaded-script-files)

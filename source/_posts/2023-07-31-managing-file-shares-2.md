---
layout: post
date: 2023-07-31 08:00:01
title: "PowerShell 技能连载 - 管理文件共享"
description: PowerTip of the Day - Managing File Shares
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在您的网络上创建新的文件共享需要管理员权限以及以下 PowerShell 代码：

```powershell
$Parameters = @{
Name = "Packages"
Path = "C:\Repo1"
FullAccess = "{0}\{1}" -f $env:userdomain, $env:username
}

New-SmbShare @Parameters
```

或使用经典参数：

```powershell
PS> New-SmbShare -Name Packages -Path c:\repo1 -FullAccess 'domain\username'
```

只需确保以管理员权限运行此程序，并确保本地文件夹（在 `-Path` 中指定）确实存在。

<!--本文国际来源：[Managing File Shares](https://blog.idera.com/database-tools/managing-file-shares-2/)-->


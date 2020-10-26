---
layout: post
date: 2020-09-23 00:00:00
title: "PowerShell 技能连载 - 识别用户 Profile"
description: PowerTip of the Day - Identifying User Profile
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 `$envuserprofile` 或 `$home` 创建用户文件的路径时要小心。当使用了 OneDrive，文档文件夹可能已重定向到名为“ OneDrive”的子文件夹。这里有些例子：

```powershell
PS> $env:USERPROFILE
C:\Users\tobia

PS> $HOME
C:\Users\tobia

PS> $profile
C:\Users\tobia\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

PS>
```

如您所见，PowerShell 配置文件脚本并不直接位于用户配置文件内的 Documents 文件夹中。而是将其改为名为 “OneDrive” 的子文件夹。

要查找当前的 Documents 文件夹，请改用 `GetFolderPath()`：

```powershell
PS> [Environment]::GetFolderPath('MyDocuments')
C:\Users\tobia\OneDrive\Documents
```

您甚至可以使用它来确定 OneDrive 是否重定向了用户文件：

```powershell
$redirected = [Environment]::GetFolderPath('MyDocuments') -like '*\OneDrive\*'
$redirected
```

当 OneDrive 重定向文件夹时，此命令返回 `$true`，否则返回 `$false`。

<!--本文国际来源：[Identifying User Profile](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-user-profile)-->


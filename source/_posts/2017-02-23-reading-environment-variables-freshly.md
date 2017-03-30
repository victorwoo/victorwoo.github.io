layout: post
date: 2017-02-23 00:00:00
title: "PowerShell 技能连载 - 读取最新的环境变量"
description: PowerTip of the Day - Reading Environment Variables Freshly
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
当您在 PowerShell 中读取环境变量时，您可能会使用 "`env:`" 驱动器。例如这行代码使用 `%USERNAME%` 环境变量，告知您执行这段代码的用户名：

```powershell
PS C:\> $env:USERNAME
tobwe

PS C:\>
```

`env:` 驱动器总是存取环境变量的操作集合。所以大多数情况所有环境变量（例如 "UserName"）都定义在这个集合之中。基本上，环境变量的操作集合是当一个应用程序启动时所有环境变量的“快照”，加上一些额外的信息（例如 "UserName"）。

要从系统或用户集合中读取最新的环境变量，请使用类似如下的代码：

```powershell
$name = 'temp'
$scope = [EnvironmentVariableTarget]::Machine

$content = [Environment]::GetEnvironmentVariable($name, $scope)
"Content: $content"
```

例如您可以使用这个技术在两个进程间通信。实践方法是，打开两个 PowerShell 控制台。现在在第一个控制台中键入以下信息：

```powershell
[Environment]::SetEnvironmentVariable("PS_Info", "Hello", "user")
```

在第二个 PowerShell 控制台中，键入这行代码来接收信息：

```powershell
[Environment]::GetEnvironmentVariable("PS_Info", "user")
```

要清除环境变量，请在任意一个控制台中输入这行代码：

```powershell
[Environment]::SetEnvironmentVariable("PS_Info", "", "user")
```

<!--more-->
本文国际来源：[Reading Environment Variables Freshly](http://community.idera.com/powershell/powertips/b/tips/posts/reading-environment-variables-freshly)

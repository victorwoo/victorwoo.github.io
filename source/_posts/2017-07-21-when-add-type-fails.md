---
layout: post
date: 2017-07-21 00:00:00
title: "PowerShell 技能连载 - 当 Add-Type 失败之后"
description: "PowerTip of the Day - When Add-Type Fails…"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Add-Type` 可以将外部 DLL 文件中的 .NET 程序集载入 PowerShell 中。这在大多数情况下工作量好，以下是一个调用示例（当然，需要 SharePoint DLL 可用）：

```powershell
PS> Add-Type -Path "C:\SharepointCSMO\Microsoft.SharePoint.Client.dll"
```

但是对某些 DLL 文件，这个命令会执行失败，PowerShell 返回一个““Unable to load one or more of the requested types. Retrieve the LoaderExceptions property for more information.”异常。

如果发生这种情况，一种解决办法是使用过时的（但是仍然可用的）`LoadFrom()` 方法：

```powershell
PS> [Reflection.Assembly]::LoadFrom("C:\SharepointCSMO\Microsoft.SharePoint.Client.dll")
```

为什么 `Add-Type` 方法会失败？`Add-Type` 维护着一个定制的和程序集相关的版本号。所以如果您试图加载的文件版本比期望的低，`Add-Type` 会拒绝加载它。相比之下，`LoadFrom()` 不关心版本号，所以和旧版本兼容。

<!--本文国际来源：[When Add-Type Fails…](http://community.idera.com/powershell/powertips/b/tips/posts/when-add-type-fails)-->

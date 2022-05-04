---
layout: post
date: 2022-04-28 00:00:00
title: "PowerShell 技能连载 - 2022 年的 PowerShell 计划"
description: PowerTip of the Day - PowerShell Plans for 2022
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Microsoft PowerShell 团队刚刚发布了 2022 年的计划和投资：[https://devblogs.microsoft.com/powershell/powershell-and-openssh-team-investments-for-2022/](https://devblogs.microsoft.com/powershell/powershell-and-openssh-team-investments-for-2022/)

简而言之，这些投资围绕着更高的安全性。此外，自定义远程连接可能会成为一个有趣的补充：您为访问远程系统而编写的代码随后可以被其他 cmdlet 使用，实质上形成了一个远程基础架构。

此外，该团队希望让现有的 Windows PowerShell 用户更容易获得 PowerShell 7。我们可能会在 2022 年看到 Windows PowerShell 多年来的第一次更新：团队讨论向 Windows PowerShell 添加一个新的 cmdlet，以在其上安装 PowerShell 7。

为了让 IntelliSense 更加智能，该团队已经引入了 "CompleterPredictors"，它可以“猜测”你将要输入的内容。虽然这些最初仅限于 Azure cmdlet，但该技术现在将向任何开发人员广泛开放。

通过添加为每个模块单独加载 .NET 程序集的方法，模块将变得更加健壮。目前，当一个模块加载具有给定版本的 .NET 程序集，而另一个模块需要不同版本的相同 .NET 程序集时，任何时候都只能加载一个版本，从而导致失败。

PowerShell 的内部包管理系统 PowerShellGet 将升级到 3.0 版，该版本之前仅作为预览版提供。它解决了从 powershellgallery.com 等存储库上传和安装模块的常见功能请求。

团队在 2022 年将关注更多感兴趣的领域，即适用于 Windows 的 OpenSSH。在此处阅读完整的声明：[https://devblogs.microsoft.com/powershell/powershell-and-openssh-team-investments-for-2022/](https://devblogs.microsoft.com/powershell/powershell-and-openssh-team-investments-for-2022/)

<!--本文国际来源：[PowerShell Plans for 2022](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/powershell-plans-for-2022)-->


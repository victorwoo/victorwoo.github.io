---
layout: post
date: 2016-09-09 00:00:00
title: "PowerShell 技能连载 - Saving PowerShell User Defaults"
description: PowerTip of the Day - Saving PowerShell User Defaults
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我们将要进入的“色彩之周”将带来许多改变 PowerShell ISE 编辑器和控制台颜色的技能。多数应用到 PowerShell 的改变并没有保存。PowerShell ISE 并不会保存一些颜色设置，但一个更健壮的方法是在 PowerShell 的一个描述脚本中改变您的自定义设置。

任何一个 PowerShell 宿主（控制台或 PowerShell ISE 或其它支持 PowerShell 的程序）都会执行的脚本如下：


```shell
PS C:\> $profile.CurrentUserAllHosts
C:\Users\Tobias\Documents\WindowsPowerShell\profile.ps1
```

Anything that applies to a specific host like the console only, or the PowerShell ISE only, goes here:

任何一个特定的 PowerShell 宿主，例如特指控制台或特指 PowerShell ISE 启动执行的脚本如下：

```shell
PS C:\>  $profile.CurrentUserCurrentHost  
C:\Users\Tobias\Documents\WindowsPowerShell\XXXXXXXXXXXXXX_profile.ps1
```

请注意路径中的 "XXX"。需要在指定的宿主内运行上面的代码才有效。根据不同的宿主，这行代码会返回不同的路径。

另外请注意这些调用只是返回描述脚本的路径。它缺省情况下并不存在。您可能需要自己创建它，包括 "WindowsPowerShell" 文件夹。当描述脚本存在时，PowerShell 宿主启动的时候就会执行它。

请注意需要打开脚本执行功能。所以您可能需要一次性地允许脚本执行，比如：

```shell
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

<!--本文国际来源：[Saving PowerShell User Defaults](http://community.idera.com/powershell/powertips/b/tips/posts/saving-powershell-user-defaults)-->

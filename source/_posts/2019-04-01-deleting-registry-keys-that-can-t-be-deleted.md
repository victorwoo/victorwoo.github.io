---
layout: post
date: 2019-04-01 00:00:00
title: "PowerShell 技能连载 - 删除无法删除的注册表键"
description: "PowerTip of the Day - Deleting Registry Keys that can’t be Deleted"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
删除注册表键通常很简单，用 `Remove-Item` 就可以了。然而，有时你会遇到一些无法删除的注册表键。在这个技能中我们将演示一个例子，并且提供一个解决方案。

在前一个技能中我们解释了当定义了一个非缺省的打开方式之后，PowerShell 文件的“使用 PowerShell 运行”上下文命令可能会丢失，而且出现了这个注册表键：

`HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice`

当您在文件管理器中右键点击一个 PowerShell 脚本，然后通过“选择其他应用”，选择一个 ISE 或 VSCode 之外的非缺省应用，并选中“始终使用此应用打开 .ps1 文件”复选框，来使用其他应用来打开 PowerShell 文件，那么注册表中就会创建上述注册表键。

当上述注册表键存在时，上下文菜单中缺省的 PowerShell 命令，例如“使用 PowerShell 运行”将不可见。用注册表删除这个键修复它很容易，但出于某种未知原因用 PowerShell 命令来删除会失败。所有 .NET 的方法也会失败。

以下命令会执行失败：

```powershell
Remove-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice
```

以下命令也会执行失败（这是 .NET 的等价代码）：

```powershell
$parent = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1', $true)
$parent.DeleteSubKeyTree('UserChoice',$true)
$parent.Close()
```

要删除这个键，您需要显示地调用 `DeleteSubKey()` 方法来代替 `DeleteSubKeyTree()`。明显地，在那个键中有一些不可见的异常子键导致该键无法删除。

当您只是删除该键（不包含它的子键，虽然子键并不存在），该键可以正常删除，并且 PowerShell 的“使用 PowerShell 运行“命令就恢复了：

```powershell
$parent = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1', $true)
$parent.DeleteSubKey('UserChoice', $true)
$parent.Close()
```

另一方面：由于这段代码只操作了用户配置单元，所以不需要任何特权，然而在 regedit.exe 中修复则需要管理员特权。

<!--本文国际来源：[Deleting Registry Keys that can’t be Deleted](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deleting-registry-keys-that-can-t-be-deleted)-->


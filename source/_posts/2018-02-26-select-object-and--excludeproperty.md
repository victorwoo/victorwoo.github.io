---
layout: post
date: 2018-02-26 00:00:00
title: "PowerShell 技能连载 - Select-Object 和 -ExcludeProperty"
description: PowerTip of the Day - Select-Object and -ExcludeProperty
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一行常常迷惑 PowerShell 用户的代码：

```powershell
Get-Service | Select-Object -ExcludeProperty Name
```

当您使用 `Select-Object` 时，它的 `-ExcludeProperty` 参数并没有做任何事情。实际上，`ExcludeProperty` 只在使用 `-Property` 的时候才有效。所以这行代码是可以用的：

```powershell
Get-Service | Select-Object -ExcludeProperty Name -Property Status, DisplayName, Name
```

然而，这看起来很荒谬：为什么通过 `-Property` 指定了属性，又还要用 `ExcludeProperty` 来排除它们呢？这样不是更简单吗：

```powershell
Get-Service | Select-Object -Property Status, DisplayName
```

实际上，`-ExcludeProperty` 只在使用通配符的时候有意义：

```powershell
PS> Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property *BIOS* -ExcludeProperty *major*, *minor*


PrimaryBIOS         : True
BiosCharacteristics : {7, 9, 11, 12...}
BIOSVersion         : {DELL   - 1072009, 1.6.1, American Megatrends - 5000B}
SMBIOSBIOSVersion   : 1.6.1
SMBIOSPresent       : True
```

<!--本文国际来源：[Select-Object and -ExcludeProperty](http://community.idera.com/powershell/powertips/b/tips/posts/select-object-and--excludeproperty)-->

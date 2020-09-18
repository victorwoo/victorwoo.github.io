---
layout: post
date: 2020-09-07 00:00:00
title: "PowerShell 技能连载 - 检测防病毒引擎状态"
description: PowerTip of the Day - Identifying Antivirus Engine State
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们学习了如何查询 WMI 来查找 Windows 计算机上存在的防病毒产品：

```powershell
$info = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct

$info
```

`ProductState` 属性对其他信息进行编码，告诉您防病毒引擎是否可运行并使用最新的签名。不过该信息是一个数字，并且是一个位标记：

```powershell
PS> $info = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct

PS> $info.productState
397568
```

要解密数字中各个位的含义，可以使用 PowerShell 对枚举类型新支持。定义好位及其含义，并用 `[Flags()]` 属性修饰枚举（表明可以设置多个位）：

```powershell
# define bit flags

[Flags()] enum ProductState
{
      Off         = 0x0000
      On          = 0x1000
      Snoozed     = 0x2000
      Expired     = 0x3000
}

[Flags()] enum SignatureStatus
{
      UpToDate     = 0x00
      OutOfDate    = 0x10
}

[Flags()] enum ProductOwner
{
      NonMs        = 0x000
      Windows      = 0x100
}

# define bit masks

[Flags()] enum ProductFlags
{
      SignatureStatus = 0x00F0
      ProductOwner    = 0x0F00
      ProductState    = 0xF000
}

# get bits
$info = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
[UInt32]$state = $info.productState

# decode bit flags by masking the relevant bits, then converting
[PSCustomObject]@{
      ProductState = [ProductState]($state -band [ProductFlags]::ProductState)
      SignatureStatus = [SignatureStatus]($state -band [ProductFlags]::SignatureStatus)
      Owner = [ProductOwner]($state -band [ProductFlags]::ProductOwner)
}
```

要检查位组的状态，请屏蔽与您要执行的操作相关的位，然后将这些位转换为枚举。结果是当前设置的位的明文名称。结果看起来像这样：

    ProductState SignatureStatus   Owner
    ------------ ---------------   -----
              On        UpToDate Windows

如果您使用的是 Windows 10 上内置的防病毒引擎 “Defender”，则无需使用上面的通用防病毒界面。而是使用内置的 `Get-MpPreference` cmdlet，它提供了更多详细信息。

<!--本文国际来源：[Identifying Antivirus Engine State](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-antivirus-engine-state)-->


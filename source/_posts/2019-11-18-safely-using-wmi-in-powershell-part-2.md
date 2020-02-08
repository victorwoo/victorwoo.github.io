---
layout: post
date: 2019-11-18 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中安全地使用 WMI（第 2 部分）"
description: PowerTip of the Day - Safely Using WMI in PowerShell (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在这个迷你系列中，我们在探索 `Get-WmiObject` 和 `Get-CimInstance` 之间的差异。未来的 PowerShell 版本不再支持 `Get-WMIObject`，因此，如果您尚未加入，则需要切换到 `Get-CimInstance`。

在前面的部分中，您了解到两个 cmdlet 都返回相同的 WMI 类的基本信息，但是两个 cmdlet 添加的元数据属性有很大不同。现在让我们仔细看看它们返回的基本信息。

我们细化了测试脚本，也可以考虑数据类型，因此我们不仅查找属性名称，而且还考虑了这些属性返回的数据的类型。为此，我们检查属性“TypeNameOfValue”。

由于这是一个字符串，类型名并不一定是一致的。它们可能显示为 "Bool" 与 "Boolean"，或者 "String" 与 "System.String"。要使结果可以用来对比，代码使用了一个位于 `$typeName` 的计算属性来忽略类型命名空间，并且在一个 switch 语句中人工做调整。如果您恰好发现另一个名字显示不正确，只需要扩展 switch 语句。

```powershell
# we are comparing this WMI class (feel free to adjust)
$wmiClass = 'Win32_OperatingSystem'

# get information about the WMI class Win32_OperatingSystem with both cmdlets
$a = Get-WmiObject -Class $wmiClass | Select-Object -First 1
$b = Get-CimInstance -ClassName $wmiClass | Select-Object -First 1

# create a calculated property that returns only the basic type name
# and omits the namespace
$typeName = @{
    Name = 'Type'
    Expression = {
        $type = $_.TypeNameOfValue.Split('.')[-1].ToLower()
        switch ($type)
        {
            'boolean' { 'bool' }
            default   { $type }
        }
        }
}

# ignore the metadata properties which we already know are different
$meta = '__CLASS','__DERIVATION','__DYNASTY','__GENUS','__NAMESPACE','__PATH','__PROPERTY_COUNT','__RELPATH','__SERVER','__SUPERCLASS','CimClass','CimInstanceProperties','CimSystemProperties','ClassPath','Container','Options','Properties','Qualifiers','Scope','Site','SystemProperties'

# return the properties and their data type. Add the origin so we later know
# which cmdlet emitted them
$aDetail = $a.PSObject.Properties |
    # exclude the metadata we already know is different
    Where-Object { $_.Name -notin $meta } |
    # add the origin command as new property "Origin"
    Select-Object -Property Name, $typeName, @{N='Origin';E={'Get-WmiObject'}}
$bDetail = $b.PSObject.Properties |
    # exclude the metadata we already know is different
    Where-Object { $_.Name -notin $meta } |
    # add the origin command as new property "Origin"
    Select-Object -Property Name, $typeName, @{N='Origin';E={'Get-CimInstance'}}

# compare differences
Compare-Object -ReferenceObject $aDetail -DifferenceObject $bDetail -Property Name, Type -PassThru |
    Select-Object -Property Name, Origin, Type |
    Sort-Object -Property Name
```

以下是执行结果：

    Name           Origin          Type
    ----           ------          ----
    InstallDate    Get-CimInstance ciminstance#datetime
    InstallDate    Get-WmiObject   string
    LastBootUpTime Get-CimInstance ciminstance#datetime
    LastBootUpTime Get-WmiObject   string
    LocalDateTime  Get-CimInstance ciminstance#datetime
    LocalDateTime  Get-WmiObject   string
    Path           Get-WmiObject   managementpath

* `Get-CimInstance` 以 `DateTime` 对象的形式返回日期和时间，而 `Get-WmiObject` 以字符串的形式返回它们，字符串格式是内部的 WMI 格式
* `Get-WmiObject` 增加了另一个名为 "Path" 的元数据属性

`Get-CimInstance` 处理日期和时间比 `Get-WmiObject` 更简单得多：

```powershell
PS> $a.InstallDate
20190903124241.000000+120

PS> $b.InstallDate

Tuesday, September 3, 2019 12:42:41
```

通过以上代码，您现在有了一个方便的工具来测试您脚本使用的 WMI 类，并在从 `Get-WmiObject` 迁移到 `Get-CimInstance` 时标识可能返回不同数据类型的属性。

<!--本文国际来源：[Safely Using WMI in PowerShell (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/safely-using-wmi-in-powershell-part-2)-->

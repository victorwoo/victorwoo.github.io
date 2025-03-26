---
layout: post
date: 2023-07-05 12:00:17
title: "PowerShell 技能连载 - 选择最佳的文件格式（第 3 部分）"
description: PowerTip of the Day - Choosing Best File Format (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 支持多种文本文件格式，那么保存和读取数据的最佳方法是什么呢？

在本系列的前两部分中，我们提供了一个实用的指南，帮助您根据数据的性质选择最佳文件格式（和适当的 cmdlet）。

当您决定使用 XML 作为数据格式时，您会发现内置的 `Export/Import-CliXml` cmdlet 是将 *您自己的对象* 保存到 XML 文件和反向操作的简单方法。但是如果您需要处理来自您自己未创建的源的 XML 数据，该怎么办呢？让我们来看一下名为“Xml”的 cmdlet：`ConvertTo-Xml`。它可以将任何对象转换为 XML 格式：

```powershell
PS> Get-Process -Id $pid | ConvertTo-Xml

xml                            Objects
---                            -------
version="1.0" encoding="utf-8" Objects
```

结果是XML，只有在将其存储在变量中时才有意义，这样您可以检查XML对象并输出XML字符串表示：

```powershell
PS> $xml = Get-Process -Id $pid | ConvertTo-Xml
PS> $xml.OuterXml
<?xml version="1.0" encoding="utf-8"?><Objects><Object Type="System.Diagnostics.Process"><Property Name="Name"
 Type="System.String">powershell_ise</Property><Property Name="SI" Type="System.Int32">1</Property><Property N
ame="Handles" Type="System.Int32">920</Property><Property Name="VM" Type="System.Int64">5597831168</Property><
Property Name="WS" Type="System.Int64">265707520</Property><Property Name="PM" Type="System.Int64">229797888</
Property><Property Name="NPM" Type="System.Int64">53904</Property><Property Name="Path" Type="System.String">C
:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe</Property><Property Name="Company" Type="System.S
tring">Microsoft Corporation</Property><Property Name="CPU" Type="System.Double">3,984375</Property><Property
Name="FileVersion" Type="System.String">10.0.19041.1 (WinBuild.160101.0800)</Property><Property Name="Produc...
```

虽然没有 `Export-Xml` 的命令，但你可以轻松地创建自己的 `Export-CliXml`，将对象持久化到文件中，而无需使用专有的“CliXml”结构。

```powershell
# data to be persisted in XML:
$Data = Get-Process | Select-Object -First 10 # let's take 10 random processes,
                                              # can be any data
# destination path for XML file:
$Path = "$env:temp\result.xml"

# take original data
$Data |
    # convert each item into an XML object but limit to 2 levels deep
    ConvertTo-Xml -Depth 2 |
    # pass the string XML representation which is found in property
    # OuterXml
    Select-Object -ExpandProperty OuterXml |
    # save to plain text file with appropriate encoding
    Set-Content -Path $Path -Encoding UTF8

notepad $Path
```

要走相反的路线，将XML转换回对象，没有 `ConvertFrom-Xml`` - 因为这个功能已经内置在类型 `[Xml]` 中。要将上面的示例文件转换回对象，您可以执行以下操作（假设您使用上面的示例代码创建了result.xml文件）：

```powershell
# path to XML file:
$Path = "$env:temp\result.xml"

# read file and convert to XML:
[xml]$xml = Get-Content -Path $Path -Raw -Encoding UTF8

# dive into the XML object model (which happens to start
# in this case with root properties named "Objects", then
# "Object":
$xml.Objects.Object |
  # next, examine each object found here:
  ForEach-Object {
    # each object describes all serialized properties
    # in the form of an array of objects with properties
    # "Name" (property name), "Type" (used data type),
    # and "#text" (property value).
    # One simple way of finding a specific entry
    # in this array is to use .Where{}:
    $Name = $_.Property.Where{$_.Name -eq 'Name'}.'#text'
    $Id = $_.Property.Where{$_.Name -eq 'Id'}.'#text'
    $_.Property | Out-GridView -Title "Process $Name (ID $Id)"
  }
```

这段代码可以读取（任何）XML文件并将XML转换为对象。你可以使用这个模板来读取和处理几乎任何XML文件。

话虽如此，要使用这些数据，你需要了解它的内部结构。在我们的示例中，我们"序列化"了10个进程对象。结果发现，`Convert-Xml` 通过描述所有属性来保存这些对象。上面的代码演示了如何首先获取序列化对象（在 ``.Objects.Object` 中找到），然后如何读取属性信息（在 ``.Property` 中作为对象数组，每个属性一个对象）。

<!--本文国际来源：[Choosing Best File Format (Part 3)](https://blog.idera.com/database-tools/powershell/powertips/choosing-best-file-format-part-3/)-->


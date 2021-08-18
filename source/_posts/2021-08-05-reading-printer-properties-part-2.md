---
layout: post
date: 2021-08-05 00:00:00
title: "PowerShell 技能连载 - 读取打印机属性（第 2 部分）"
description: PowerTip of the Day - Reading Printer Properties (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们查看了 `Get-PrinterProperty`，它是 `PrintManagement` 模块的一部分，可在 Windows 操作系统上使用。

在这个技能中，让我们看看如何在自己的脚本中实际使用打印机值，以及与使用简单数组相比，如何将它们存储在哈希表中使访问打印机属性更容易。

重要提示：实际的打印机属性及其名称取决于您的打印机型号和打印机驱动程序。上面示例中使用的属性名称可能因打印机而异。

当您将 `Get-PrinterProperty` 返回的结果存储在一个变量中时，该变量包含一个简单的数组，您的工作是使用您所追求的属性来标识数组元素。下面是一个例子：

```powershell
PS> $info = Get-PrinterProperty -PrinterName 'S/W Laser HP'

# return result is an array
PS> $info -is [Array]
True

# array elements can only be accessed via numeric index
PS> $info.Count
64

# the number of returned properties depends on the printer model
# the index of given properties may change so accessing a property by
# index works but can be unreliable:
PS> $info[0]

ComputerName         PrinterName          PropertyName         Type       Value
------------         -----------          ------------         ----       -----
                        S/W Laser HP         Config:AccessoryO... String     500Stapler


# the actual property value is stored in the property “Value”
PS> $info[0].Value
500Stapler

# using comparison operators, you can convert string content to Boolean
# for example to check whether a printer has a certain feature installed
PS> $info[2]

ComputerName         PrinterName          PropertyName         Type       Value
------------         -----------          ------------         ----       -----
                        S/W Laser HP         Config:AutoConfig... String     NotInstalled

PS> $info[2].Value
NotInstalled

PS> $info[2].Value -eq 'NotInstalled'
True
```

更安全的方法是将结果存储在哈希表中并使用原始属性名称作为键。众所周知，`Group-Object` 可以自动为您创建哈希表。只需告诉 `Group-Object` 要用于分组的属性的名称，并要求取回哈希表并将字符串用作哈希表键：

```powershell
$info = Get-PrinterProperty -PrinterName 'S/W Laser HP' | Group-Object -Property PropertyName -AsHashTable -AsString
```

这一次，`$info` 包含一个哈希表，如果您使用带有 IntelliSense 的 PowerShell 编辑器（如 ISE 或 VSCode），一旦您在输入变量名时按下键盘上的点，就会获得丰富的 IntelliSense，显示可用的属性名称。在控制台中，您可以按 TAB 以使用自动完成功能。

由于 IntelliSense 菜单和 TAB 自动完成还包含一些与哈希表相关的属性和方法，因此您可能需要向下滚动一点或分别按 TAB 几次。

要查询打印机属性的值，选择属性名称后，您需要在属性名称周围添加引号，因为通常打印机属性名称包含特殊字符，如冒号：

```powershell
# hash table keys need to be quoted
PS> $info.Config:AccessoryOutputBins
At line:1 char:13
+ $info.Config:AccessoryOutputBins
+             ~~~~~~~~~~~~~~~~~~~~
Unexpected token ':AccessoryOutputBins' in expression or statement.
        + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
        + FullyQualifiedErrorId : UnexpectedToken


# once you add quotes, all is fine
PS> $info.'Config:AccessoryOutputBins'

ComputerName         PrinterName          PropertyName         Type       Value
------------         -----------          ------------         ----       -----
                     S/W Laser HP         Config:AccessoryO... String     500Stapler

PS> $info.'Config:AccessoryOutputBins'.Value
500Stapler
```

<!--本文国际来源：[Reading Printer Properties (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-printer-properties-part-2)-->


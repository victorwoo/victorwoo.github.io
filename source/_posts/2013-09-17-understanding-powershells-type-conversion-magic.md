layout: post
title: "理解PowerShell的类型转换魔法"
date: 2013-09-17 00:00:00
description: Understanding PowerShell's Type Conversion Magic
categories: powershell
tags:
- powershell
- script
- translation
---
毫无疑问地，PowerShell中的类型转换是它最有用的“魔法”功能之一。如果您执行一个需要特定参数类型（例如：`DateTime` 或 `TimeSpan`）的命令，情况似乎“一切正常”。

例如，Twitter上的这条问题：

> PowerShell 的 `TimeSpan` 参数将10理解为10个计时周期，10:00理解为10小时，"10"理解为10天。
> 
> 译者注：计时周期的概念请参见 [TimeSpan.Ticks 属性](http://msdn.microsoft.com/zh-cn/library/system.timespan.ticks.aspx)。

但是，这是怎么做到的呢？

以下是PowerShell根据您的需要将输入值转换为所需要的类型的步骤——例如 `TimeSpan`。和许多事情一样，并不是什么魔法——只是一堆繁琐的工作。
<!--more-->

### 1. 直接赋值
如果您的输入值是[可直接赋值的](http://msdn.microsoft.com/en-us/library/system.type.isassignablefrom.aspx)，那么直接将您的输入值转型为该类型。

### 2. 基于语言的转换
这些基于语言的转换适用于目标类型是 `void`、`Boolean`、`String`、`Array`、`Hashtable`、`PSReference（例如：[ref]）`、`XmlDocument（例如：[xml]）`、`Delegate（用于支持代码块转换到Delegate）` 和 `Enum` 类型。

### 3. 解析转换
如果目标类型定义了一个 `Parse()` 方法接受该输入值，那么将使用它来做转换。

### 4. 静态创建转换
如果目标类型定义了一个静态的 `::Create()` 方法并接受该输入值，那么将使用它来转做换。

### 5. 构造函数转换
如果目标类型定义了一个构造函数接受该输入值，那么将用它来做转换。

### 6. 强制类型转换
如果目标类型针对源类型 [隐式或显示地](http://msdn.microsoft.com/en-us/library/39bb81c3.aspx) 定义了一个强制类型转换操作符，那么将用它来做转换。如果源类型定义了一个隐式或显式转换到目标类型的前置类型转换操作符，那么使用它来做转换。

### 7. IConvertible转换
如果源类型定义了一个知道如何转换为目标类型的 `IConvertible` 的实现，那么将使用它来做转换。

### 8. IDictionary转换
如果源类型是一个 `IDictionary（例如：Hashtable）` 类型，则尝试用目标类型的缺省构造函数创建一个实例，并且使用 `IDictionary` 中的同名键值对为源对象的属性赋值。

### 9. PSObject属性转换
如果源类型是 `PSObject`，那么用目标类型的缺省构造函数创建一个实例，然后用 `PSObject` 中的属性名和属性值为源对象赋值。如果某个名字对应的是一个方法而不是一个属性，则以该值作为实参执行该方法。

### 10. TypeConverter 转换
如果注册了一个可以处理该转换的 `TypeConverter` 或 `PSTypeConverter`，则用它来做转换。您可以在 `types.ps1xml` 文件中注册一个 `TypeConverter`（参见：`$pshome\Types.ps1xml`），或通过 `Update-TypeData` 来注册。

好了，现在考考您能不能指出这些分别是什么类型的转换，以及为什么？

	[TimeSpan] 10 
	[TimeSpan] "10" 
	[TimeSpan] "0:10" 

希望本文对您有所帮助！

Lee Holmes \[MSFT\]   
Windows PowerShell开发团队

本文国际来源：[Understanding PowerShell's Type Conversion Magic](http://blogs.msdn.com/b/powershell/archive/2013/06/11/understanding-powershell-s-type-conversion-magic.aspx)

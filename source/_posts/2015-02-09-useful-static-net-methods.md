---
layout: post
date: 2015-02-09 12:00:00
title: "PowerShell 技能连载 - 有用的静态 .NET 方法"
description: PowerTip of the Day - Useful Static .NET Methods
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

PowerShell 可以调用 .NET 类型的静态方法。以下是一些很好用的单行代码：

    [Math]::Round(7.9)

    [Convert]::ToString(576255753217, 8)

    [Guid]::NewGuid()

    [Net.Dns]::GetHostByName('schulung12')

    [IO.Path]::GetExtension('c:\test.txt')

    [IO.Path]::ChangeExtension('c:\test.txt', 'bak')


要查看更多的用法，请删除类型（方括号中的文字）后的代码，然后键入两个冒号。PowerShell ISE 将会自动弹出一个快捷菜单列出该类型可用的方法。在 PowerShell 控制台中，只需要按下 `TAB` 键即可得到自动完成的建议。

您也可以将一个类型通过管道输出到 `Get-Member` 命令：

    PS> [Math] | Get-Member -MemberType *Method -Static


       TypeName: System.Math

    Name            MemberType Definition
    ----            ---------- ----------
    Abs             Method     static sbyte Abs(sbyte value), static int16 Abs(int16 value), static int Abs(int value), sta...
    Acos            Method     static double Acos(double d)
    Asin            Method     static double Asin(double d)
    Atan            Method     static double Atan(double d)
    Atan2           Method     static double Atan2(double y, double x)
    BigMul          Method     static long BigMul(int a, int b)
    Ceiling         Method     static decimal Ceiling(decimal d), static double Ceiling(double a)
    Cos             Method     static double Cos(double d)
    Cosh            Method     static double Cosh(double value
    DivRem          Method     static int DivRem(int a, int b, [ref] int result), static long DivRem(long a, long b, [ref] ...
    Equals          Method     static bool Equals(System.Object objA, System.Object objB)
    Exp             Method     static double Exp(double d)
    Floor           Method     static decimal Floor(decimal d), static double Floor(double d)
    IEEERemainder   Method     static double IEEERemainder(double x, double y)
    Log             Method     static double Log(double d), static double Log(double a, double newBase)
    Log10           Method     static double Log10(double d)
    Max             Method     static sbyte Max(sbyte val1, sbyte val2), static byte Max(byte val1, byte val2), static int1...
    Min             Method     static sbyte Min(sbyte val1, sbyte val2), static byte Min(byte val1, byte val2), static int1...
    Pow             Method     static double Pow(double x, double y)
    ReferenceEquals Method     static bool ReferenceEquals(System.Object objA, System.Object objB)
    Round           Method     static double Round(double a), static double Round(double value, int digits), static double ...
    Sign            Method     static int Sign(sbyte value), static int Sign(int16 value), static int Sign(int value), stat...
    Sin             Method     static double Sin(double a)
    Sinh            Method     static double Sinh(double value)
    Sqrt            Method     static double Sqrt(double d)
    Tan             Method     static double Tan(double a)
    Tanh            Method     static double Tanh(double value)
    Truncate        Method     static decimal Truncate(decimal d), static double Truncate(double d)

要查看某个方法的所有重载的签名，请去掉圆括号：


    PS> Get-Something -Path test
    You entered test.

    PS> [Math]::Round

    OverloadDefinitions
    -------------------
    static double Round(double a
    static double Round(double value, int digits)
    static double Round(double value, System.MidpointRounding mode)
    static double Round(double value, int digits, System.MidpointRounding mode
    static decimal Round(decimal d
    static decimal Round(decimal d, int decimals)
    static decimal Round(decimal d, System.MidpointRounding mode)
    static decimal Round(decimal d, int decimals, System.MidpointRounding mode)

<!--本文国际来源：[Useful Static .NET Methods](http://community.idera.com/powershell/powertips/b/tips/posts/useful-static-net-methods)-->

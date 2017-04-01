layout: post
date: 2015-03-27 11:00:00
title: "PowerShell 技能连载 - 查找只读型和常量型变量"
description: PowerTip of the Day - Finding Read-Only and Constant Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
_适用于 PowerShell 所有版本_

有些变量是受保护且不可改变的。要查这些变量，请看如下代码：

    Get-Variable |   
      Where-Object { $_.Options -like '*Constant*' -or $_.Options -like '*ReadOnly*' } |
      Select-Object -Property Name, Options, Description

执行的结果类似这样：

    Name                                           Options Description               
    ----                                           ------- -----------               
    ?                                   ReadOnly, AllScope Status des letzten Befehls
    ConsoleFileName                     ReadOnly, AllScope Name der aktuellen Kons...
    Error                                         Constant                           
    ExecutionContext                    Constant, AllScope Die für Cmdlets verfügb...
    false                               Constant, AllScope Boolean False             
    HOME                                ReadOnly, AllScope Ordner mit dem Profil d...
    Host                                Constant, AllScope Ein Verweis auf den Hos...
    PID                                 Constant, AllScope Aktuelle Prozess-ID       
    PSCulture                           ReadOnly, AllScope Die Kultur der aktuelle...
    PSHOME                              Constant, AllScope Der übergeordnete Ordne...
    psISE                                         Constant                           
    PSUICulture                         ReadOnly, AllScope Die Benutzeroberflächen...
    psUnsupportedConsoleAppl...                   Constant                           
    PSVersionTable                      Constant, AllScope Versionsinformationen f...
    ShellId                             Constant, AllScope "ShellID" gibt die aktu...
    true                                Constant, AllScope Boolean True            

有意思的地方是如何用 `Where-Object` 来过滤这些变量。这段代码使用了字符串对比和 `-like`。这是因为变量选项是各种标志，并且标志可以组合使用。通过使用 `-like` 和占位符，您可以基本安全地用您希望的标志来过滤，即便设置了其它标志。

<!--more-->
本文国际来源：[Finding Read-Only and Constant Variables](http://community.idera.com/powershell/powertips/b/tips/posts/finding-read-only-and-constant-variables)

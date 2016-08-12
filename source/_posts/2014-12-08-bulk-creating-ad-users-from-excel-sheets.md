layout: post
date: 2014-12-08 12:00:00
title: "PowerShell 技能连载 - 根据 Excel 表批量创建 AD 用户"
description: PowerTip of the Day - Bulk Creating AD Users from Excel Sheets
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
_需要 ActiveDirectory Module_

为了创建大量新的 Active Directory 用户，您可以从 CSV 文件中导入用户信息，这个 CSV 可以由 Excel 表导出。

下一步，这段代码将会把 CSV 数据转为真实的 Active Directory 用户账户。

    Import-Csv -Path F:\userlist.csv -UseCulture -Encoding Default |
    ForEach-Object {
      
      $_.AccountPassword = $_.AccountPassword | 
                               ConvertTo-SecureString -Force -AsPlainText
      $_ 
    
    } |
    New-ADUser -WhatIf 

CSV 文件所需的只是 `New-ADUser` 所需要的参数作为列名。一个详尽的列表可能包含以下列名：`Name`、`SamAccountName`、`Description`、`Company`、`City`、`Path`、`AccountPassword`。

请注意 CSV 文件天生只能包含字符串数据类型。由于 `AccountPassword` 属性需要一个 `SecureString` 数据类型的值，所以 PowerShell 代码将从 CSV 文件中读取字符串转换为 `SecureString` 之后再传递给 `New-ADUser`。

这个技术可以用于创建用户前预处理任何原始数据。

<!--more-->
本文国际来源：[Bulk Creating AD Users from Excel Sheets](http://powershell.com/cs/blogs/tips/archive/2014/12/08/bulk-creating-ad-users-from-excel-sheets.aspx)

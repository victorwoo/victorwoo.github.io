layout: post
date: 2014-10-28 11:00:00
title: "PowerShell 技能连载 - 存取 SQLServer 数据库"
description: PowerTip of the Day - Accessing SQLServer Database
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
_适用于 PowerShell 所有版本及 SQLServer_

您在使用 SQL Server 吗？以下是一段可以进行 SQL 查询并获取数据的 PowerShell 脚本模板。只需要确保填写了正确的用户信息、服务器地址和 SQL 语句即可：

    $Database                       = 'Name_Of_SQLDatabase'
    $Server                         = '192.168.100.200'
    $UserName                         = 'DatabaseUserName'
    $Password                       = 'SecretPassword'
    
    $SqlQuery                       = 'Select * FROM TestTable'
    
    # Accessing Data Base
    $SqlConnection                  = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Data Source=$Server;Initial Catalog=$Database;user id=$UserName;pwd=$Password"
    $SqlCmd                         = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText             = $SqlQuery
    $SqlCmd.Connection              = $SqlConnection
    $SqlAdapter                     = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand       = $SqlCmd
    $set                            = New-Object data.dataset
    
    # Filling Dataset
    $SqlAdapter.Fill($set)
    
    # Consuming Data
    $Path = "$env:temp\report.hta"
    $set.Tables[0] | ConvertTo-Html | Out-File -FilePath $Path
    
    Invoke-Item -Path $Path

<!--more-->
本文国际来源：[Accessing SQLServer Database](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-sqlserver-database)

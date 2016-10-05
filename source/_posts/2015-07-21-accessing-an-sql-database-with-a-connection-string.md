layout: post
date: 2015-07-21 11:00:00
title: "PowerShell 技能连载 - 通过连接字符串访问 SQL 数据库"
description: PowerTip of the Day - Accessing an SQL Database with a Connection String
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
在前一个技能中我们揭示了如何创建一个 SQL Server 的连接字符串。无论您用什么方式创建了这个字符串——假设您已拥有了一个合法的数据库连接字符串，这个例子将演示如何对数据库执行 SQL 命令。

    #requires -Version 2
    
    # make sure this is a valid connection string to your database
    # see www.connectionstrings.com for reference
    $connectionString = 'Provider=SQLOLEDB.1;Password=.topSecret!;Persist Security
     Info=True;User ID=sa;Initial Catalog=test;Data Source=myDBServer\SQLEXPRESS2012'
    
    # make sure this is valid SQL for your database
    # so in this case, make sure there is a table called "test"
    $sql = 'select * from test'
    
    $db = New-Object -ComObject ADODB.Connection
    $db.Open($connectionString)
    $rs = $db.Execute($sql)
    
    $results = While ($rs.EOF -eq $false)
    {
        $CustomObject = New-Object -TypeName PSObject
        $rs.Fields | ForEach-Object -Process {
            $CustomObject | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
        }
        $CustomObject
        $rs.MoveNext()
    }
    $results | Out-GridView

<!--more-->
本文国际来源：[Accessing an SQL Database with a Connection String](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-an-sql-database-with-a-connection-string)

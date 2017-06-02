---
layout: post
date: 2014-11-04 12:00:00
title: "PowerShell 技能连载 - 导入及安装证书"
description: PowerTip of the Day - Importing and Installing Certificate
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

若要以编程的方式从文件中加载证书并将它安装到证书管理其的指定位置，请看以下脚本：

    $pfxpath = 'C:\temp\test.pfx'
    $password = 'test'
    [System.Security.Cryptography.X509Certificates.StoreLocation]$Store = 'CurrentUser'
    $StoreName = 'root'
    
    Add-Type -AssemblyName System.Security
    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certificate.Import($pfxpath, $password, 'Exportable')
    
    $Store = New-Object system.security.cryptography.X509Certificates.x509Store($StoreName, $StoreLocation)
    $Store.Open('ReadWrite')
    $Store.Add($certificate)
    $Store.Close()

您可以配置这个脚本并指定待导入的证书文件的路径和密码。您还可以指定其存储的位置（当前用户或本地计算机），以及将其放入的容器（例如“root”代表受信任的根证书颁发机构，“my”代表个人）。

<!--more-->
本文国际来源：[Importing and Installing Certificate](http://community.idera.com/powershell/powertips/b/tips/posts/importing-and-installing-certificate)

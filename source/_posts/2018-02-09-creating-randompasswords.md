---
layout: post
date: 2018-02-09 00:00:00
title: "PowerShell 技能连载 - 创建随机的密码"
description: PowerTip of the Day - Creating Random Passwords
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
以下是另一小段用于生成由指定数量的大小写字母、数字，和特殊字符组成的随机密码：

```powershell
$length = 10
$length_small = $length - 3
$numbers = '2,3,4,5,6,7,8,9' -split ','
$large = 'A,B,C,D,E,F,G,H,K,L,M,N,P,R,S,T,U,V,W,X,Y,Z' -split ','
$small = 'A,B,C,D,E,F,G,H,K,L,M,N,P,R,S,T,U,V,W,X,Y,Z'.ToLower() -split ','
$special = '!,§,$,='.Split(',')

$password = @()
$password = @($numbers | Get-Random)
$password += @($large | Get-Random)
$password += @($small | Get-Random -Count $length_small)
$password += @($special | Get-Random)

$password = $password | Get-Random -Count $length

$password -join ''
```

<!--more-->
本文国际来源：[Creating Random Passwords](http://community.idera.com/powershell/powertips/b/tips/posts/creating-randompasswords)

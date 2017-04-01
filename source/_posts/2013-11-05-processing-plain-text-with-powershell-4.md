layout: post
title: "用 PowerShell 处理纯文本 - 4"
date: 2013-11-05 00:00:00
description: Processing Plain Text with PowerShell - 4
categories:
- powershell
- text
tags:
- powershell
- learning
- skill
- script
---
命题
----
QQ 群里的史瑞克朋友提出的一个命题：

	$txt="192.168.1
	192.168.2
	192.168.3
	172.19.3
	192.16.1
	192.16.2
	192.16.11
	192.16.3
	10.0.4
	192.16.29
	192.16.9
	192.16.99
	192.16.100"

要求输出：

	10.0.4
	172.19.3
	192.16.1-192.16.3
	192.16.9
	192.16.11
	192.16.29
	192.16.99-192.16.100
	192.168.1-192.168.3

问题解析
--------
	* 将各个 IP 段补充为三位的格式
	* 按字符串排序
	* 遍历每一行，按照以下规则处理：
		* 如果和上一行连续，则上一段可能没有结束，更新 `$endIP`
		* 如果和上一行不连续
			* 若 `$startIP` 和 `$endIP` 相同，说明是单个 IP，将单个 IP 加入 $result
			* 若 `$startIP` 和 `$endIP` 不同，说明是一段 IP，将一段 IP 加入 $result
			* 更新 `$startIP` 和 `$endIP`
	* 最后一行需要特殊处理

PowerShell 实现
---------------

	$DebugPreference = "Continue"
	
	$txt="192.168.1
	192.168.2
	192.168.3
	172.19.3
	192.16.1
	192.16.2
	192.16.11
	192.16.3
	10.0.4
	192.16.29
	192.16.9
	192.16.99
	192.16.100"
	$txt += "`n999.999.999"
	
	$startIP = @(0, 0, 0)
	$endIP = @(0, 0, 0)
	$result = @()
	
	-split $txt | % {
	    $fullSegments = ($_ -split "\." | % {
	        "{0:D3}" -f [int]$_
	    })
	    $fullSegments -join "."
	} | sort | % {
	    Write-Debug "Processing $_"
	    $segments = @($_ -split "\." | % {
	        [int]$_
	    })
	
	    if ($endIP[0] -eq $segments[0] -and
	        $endIP[1] -eq $segments[1] -and
	        $endIP[2] + 1 -eq $segments[2]) {
	        Write-Debug '和上一个IP连续'
	        $endIP = $segments
	    } else {
	        Write-Debug '和上一个IP不连续'
	        if (($startIP -join ".") -eq ($endIP -join ".")) {
	            Write-Debug '单个IP'
	            $result += $startIP -join "."
	        } else {
	            Write-Debug '一段IP'
	            $result += ($startIP -join ".") + "-" + ($endIP -join ".")
	        }
	
	        $startIP = $segments
	        $endIP = $segments
	    }
	}
	
	$result | select -Skip 1

源代码请在[这里下载](/assets/download/Sort-IP.ps1)。

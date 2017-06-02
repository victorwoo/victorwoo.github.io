---
layout: post
title: "用脚本批量下载www.cheat-sheets.org中的所有pdf文件"
date: 2013-06-08 00:00:00
description: batch downloading www cheat sheets org
categories: powershell
tags:
- powershell
- script
- batch
- cheatsheet
- download
- resource
---
流水不腐，户枢不蠹。虽然批量下载有很多工具能做到，但是为了提高，我们尽量动手编写脚本吧。
[http://www.cheat-sheets.org](http://www.cheat-sheets.org) 里有很多好东西，我们把它批量下载下来。

<!--more-->
![下载的PDF截图](/img/2013-06-08-batch-downloading-www-cheat-sheets-org-001.jpg)

PowerShell代码：

	Add-Type -AssemblyName System.Web
	$baseUrl = 'http://www.cheat-sheets.org'
	$result = Invoke-WebRequest $baseUrl
	$result.Links | 
	    ? {$_.href -Like '*.pdf'} |
	    select -ExpandProperty href |
	    sort |
	    % { 
	        if ($_ -like '/*')
	        {
	            $baseUrl + $_ 
	        } else {
	            $_
	        }
	      } |
	     % {
	        echo "Downloading $_"
	        $fileName = $_.Substring($_.LastIndexOf("/") + 1)
	        $localFileName = [System.Web.HttpUtility]::UrlDecode($fileName)
	
	        if (Test-Path $localFileName) {
	            return
	        }
	        Invoke-WebRequest -Uri $_ -OutFile $localFileName
	        if (Test-Path $localFileName) {
	            Unblock-File $localFileName
	        }
	     }

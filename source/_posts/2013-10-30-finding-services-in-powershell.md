---
layout: post
title: "PowerShell 技能连载 - 在 PowerShell 中查找服务"
date: 2013-10-30 00:00:00
description: PowerTip of the Day - Finding Services in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Service` 可以列出计算机上的所有服务，但是返回的信息十分少。您无法很容易地看出一个服务做什么、它是一个 Microsoft 服务还是一个第三方服务，以及服务所对应的可执行程序。

通过合并一些信息，您可以获取许多更丰富的信息。以下是一个 `Find-Service` 函数，可以返回一系列丰富的信息：

	function Find-Service
	{
	    param
	    (
	        $Name = '*',
	        $DisplayName = '*',
	        $Started 
	    )
	    $pattern = '^.*\.exe\b'
	
	    $Name = $Name.Replace('*','%')
	    $DisplayName = $DisplayName.Replace('*','%')
	
	    Get-WmiObject -Class Win32_Service -Filter "Name like '$Name' and DisplayName like '$DisplayName'"|
	      ForEach-Object {
	
	        if ($_.PathName -match $pattern)
	        {
	            $Path = $matches[0].Trim('"')
	            $file = Get-Item -Path $Path
	            $rv = $_ | Select-Object -Property Name, DisplayName, isMicrosoft, Started, StartMode, Description, CompanyName, ProductName, FileDescription, ServiceType, ExitCode, InstallDate, DesktopInteract, ErrorControl, ExecutablePath, PathName
	            $rv.CompanyName = $file.VersionInfo.CompanyName
	            $rv.ProductName = $file.VersionInfo.ProductName
	            $rv.FileDescription = $file.VersionInfo.FileDescription
	            $rv.ExecutablePath = $path
	            $rv.isMicrosoft = $file.VersionInfo.CompanyName -like '*Microsoft*'
	            $rv
	        }
	        else
	        {
	            Write-Warning ("Service {0} has no EXE attached. PathName='{1}'" -f $_.PathName)
	        }
	      }
	}
	 
	Find-Service | Out-GridView

<!--本文国际来源：[Finding Services in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/finding-services-in-powershell)-->

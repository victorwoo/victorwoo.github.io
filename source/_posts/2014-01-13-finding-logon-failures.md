---
layout: post
title: "PowerShell 技能连载 - 查询登录失败记录"
date: 2014-01-13 00:00:00
description: PowerTip of the Day - Finding Logon Failures
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
只要有人使用错误的凭据登录，就会在安全日志中产生一条日志记录。以下是一个可以从安全日志中读取这些事件的函数（需要管理员特权）。它能够列出所有日志中非法的登录信息：

	# requires Admin privileges!
	function Get-LogonFailure
	{
	      param($ComputerName)
	      try
	      {
	          Get-EventLog -LogName security -EntryType FailureAudit -InstanceId 4625 -ErrorAction Stop @PSBoundParameters |
	                  ForEach-Object {
	                    $domain, $user = $_.ReplacementStrings[5,6]
	                    $time = $_.TimeGenerated
	                    "Logon Failure: $domain\$user at $time"
	                }
	      }
	      catch
	      {
	            if ($_.CategoryInfo.Category -eq 'ObjectNotFound')
	            {
	                  Write-Host "No logon failures found." -ForegroundColor Green
	            }
	            else
	            {
	                  Write-Warning "Error occured: $_"
	            }
	
	      }
	
	}

请注意这个函数还可以在远程主机上运行。请使用 `-ComputerName` 参数来查询一台远程主机。远程主机需要运行 RemoteRegistry 服务，并且您需要在目标机器上的本地管理员权限。

<!--本文国际来源：[Finding Logon Failures](http://community.idera.com/powershell/powertips/b/tips/posts/finding-logon-failures)-->

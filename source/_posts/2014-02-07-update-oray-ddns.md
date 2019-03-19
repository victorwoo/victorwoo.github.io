---
layout: post
title: "用 PowerShell 更新 Oray 花生壳动态 IP"
date: 2014-02-07 00:00:00
description: Update Oray DDNS with PowerShell
categories: powershell
tags:
- powershell
- geek
- ddns
- ip
- oray
---
[花生壳][花生壳]是 [oray][oray] 公司提供的 [DDNS][DDNS] 客户端。官方的客户端庞大臃肿：

![](/img/2014-02-07-update-oray-ddns-001.jpg)

不过好在花生壳开放了基于 http 的 [API]。这样我们可以很容易地用 PowerShell 实现更新动态 IP 的功能：

	param (
	    $UserName = 'xxx',
	    $Password = 'yyy',
	    $HostName,
	    $IP
	)

	function Get-ExternalIP {
	    #(Invoke-WebRequest 'http://myip.dnsomatic.com' -UseBasicParsing).Content
	    ((Invoke-WebRequest 'http://ddns.oray.com/checkip').ParsedHtml.body.innerText -split ':')[1].Trim()
	}

	function Update-OrayDdns {
	    param (
	        [parameter(Mandatory = $true)]
	        [string]$UserName,

	        [parameter(Mandatory = $true)]
	        [string]$Password,

	        [parameter(HelpMessage = '需要更新的域名，此域名必须是开通花生壳服务。多个域名使用,分隔，默认为空，则更新护照下所有激活的域名。')]
	        [string]$HostName,

	        [parameter(HelpMessage = '需要更新的IP地址，可以不填。如果不指定，则由服务器获取到的IP地址为准。')]
	        [string]$IP
	    )

	    $request = 'http://ddns.oray.com/ph/update?hostname={0}' -f ($HostName -join ',')
	    if ($IP) {
	        $request = $request + '&myip=' + $IP
	    }
	    $encoded =  [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserName+":"+$Password ))
	    $headers = @{Authorization = "Basic "+$encoded}
	    $response = Invoke-WebRequest $request -Headers $headers -UseBasicParsing

	    $codes = @{
	        good = '更新成功，域名的IP地址已经更新。'
	        nochg = '更新成功，但没有改变IP。一般这种情况为本次提交的IP跟上一次的一样。'
	        notfqdn = '未有激活花生壳的域名。'
	        nohost = '域名不存在或未激活花生壳。'
	        abuse = '请求失败，频繁请求或验证失败时会出现。'
	        '!donator' = '表示此功能需要付费用户才能使用，如https。'
	        911 = '系统错误'
	    }

	    $code = ($response.Content -split ' ')[0]
	    $message = $codes[$code]

	    if ($code -eq 'good' -or $code -eq 'nochg') {
	        Write-Output $message
	    } elseif ($code -eq 'notfqdn' -or $code -eq 'nohost') {
	        Write-Warning $message
	    } else {
	        Write-Error $message
	    }
	}

	Update-OrayDdns $UserName $Password $HostName

[花生壳]: http://hsk.oray.com/
[oray]: http://www.oray.com/
[DDNS]: http://baike.baidu.com/link?url=Gx6l-OhNyttNMCeDpf4q-ntOP9p6g1Pcbzqj1IwmBra77c-HEVBTiiAVVR3Orl60
[API]: http://open.oray.com/wiki/doku.php?id=%E6%96%87%E6%A1%A3:%E8%8A%B1%E7%94%9F%E5%A3%B3:http%E5%8D%8F%E8%AE%AE%E8%AF%B4%E6%98%8E (花生壳http协议说明)

您也可以从这里 [下载](/assets/download/Update-OrayDdns.ps1) 写好的脚本。

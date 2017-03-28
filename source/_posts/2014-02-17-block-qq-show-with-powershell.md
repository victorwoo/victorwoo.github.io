layout: post
title: "用 PowerShell 屏蔽腾讯 QQ 秀"
date: 2014-02-17 00:00:00
description: Block QQ Show with PowerShel
categories: powershell
tags:
- powershell
- geek
- qq
- ad
- block
---
我们在 [用 PowerShell 屏蔽腾讯 QQ 的广告][用 PowerShell 屏蔽腾讯 QQ 的广告] 这篇文章中介绍过了如何屏蔽 QQ 聊天窗口的横幅广告，那么如何屏蔽 QQ 秀的广告呢？请参见 [QQ2013 删除QQ秀广告][QQ2013 删除QQ秀广告]。

但是其中的步骤有点繁琐。我们把整个流程用 PowerShell 写一遍，对于用户只要执行一下即可：

	$folder = "${env:ProgramFiles}\Tencent\QQ\Plugin\Com.Tencent.QQShow\"
	$folder
	$rdbFile = Join-Path $folder 'Bundle.rdb'
	$rdbDir = Join-Path $folder 'Bundle'
	
	$xmlPath = Join-Path $folder 'Bundle\I18N\2052\UrlBundle.xml'
	
	if (Test-Path "$rdbFile.bak") {
	    Write-Warning "$rdbFile.bak 文件已存在，请确认是否已经替换？"
	    Write-Warning "程序退出。"
	    return
	}
	
	$rdbFile
	.\RDB.exe """$rdbFile"""
	move $rdbFile "$rdbFile.bak"
	.\D4QQenc.exe (Join-Path $folder 'Bundle\I18N\2052\UrlBundle.xml.enc')
	
	del (Join-Path $folder 'Bundle\I18N\2052\UrlBundle.xml.enc')
	
	[xml]$urlBundle = Get-Content $xmlPath -Encoding UTF8 | where { $_ -ne '' }
	
	@('IDS_QQSHOW_MARKET', 'IDS_3DSHOW_MARKET', 'IDS_FLASHSHOW_MARKET') | foreach {
	    $id = $_
	    ($urlBundle.StringBundle.String | where { $_.id -eq $id })."#text" = ''
	}
	$urlBundle.OuterXml | Set-Content $xmlPath -Encoding UTF8
	
	.\RDB.exe """$rdbDir"""

您也可以从这里 [下载](/assets/download/Disable-QQShow.zip) 写好的脚本，祝您使用愉快。
本方法在 QQ2013（SP6） 上验证通过。

[用 PowerShell 屏蔽腾讯 QQ 的广告]: /powershell/2014/01/10/block-ad-of-tencent-qq-with-powershell/
[QQ2013 删除QQ秀广告]: http://cleris.diandian.com/QQ2013-QQShow-ADS

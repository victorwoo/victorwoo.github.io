layout: post
title: "用 PowerShell 屏蔽腾讯 QQ 的广告"
date: 2014-01-10 00:00:00
description: Block AD of Tencent QQ with PowerShell
categories: powershell
tags:
- powershell
- geek
- qq
- ad
- block
---
非会员 QQ，在对话窗口的右上角会显示一个广告横幅，如图所示：

![](/img/2014-01-10-block-ad-of-tencent-qq-with-powershell-001.png)

我们可以将 %appdata%\Tencent\Users\QQ号\QQ\Misc.db 文件删除并且替换成一个同名文件夹，就可以屏蔽该广告：

![](/img/2014-01-10-block-ad-of-tencent-qq-with-powershell-002.png)

如果您有多个 QQ 号的话，我们可以用 PowerShell 来批量完成该任务：

	echo '本脚本用于屏蔽 QQ 对话窗口右上方的广告条。'
	Read-Host '请关闭所有 QQ，按回车键继续' | Out-Null
	
	$usersDir = "$($env:AppData)\Tencent\Users\"
	dir $usersDir -Directory | foreach {
	    $qq = $_
	    $qqDir = Join-Path $_.FullName 'QQ'
	    $miscDb = Join-Path $qqDir Misc.db
	    if (Test-Path -PathType Leaf $miscDb) {
	        echo "正在禁用 $qq 的广告"
	        del $miscDb
	        md $miscDb | Out-Null
	    }
	}
	exit
	echo '处理完毕。'

您也可以从这里 [下载](/assets/download/Block-QQAd.ps1) 写好的脚本，祝您使用愉快。
本方法在 QQ2013（SP6） 上验证通过。

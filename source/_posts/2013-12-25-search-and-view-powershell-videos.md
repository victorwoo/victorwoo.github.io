---
layout: post
title: "PowerShell 技能连载 - 搜索并观看 PowerShell 视频"
date: 2013-12-25 00:00:00
description: PowerTip of the Day - Search and View PowerShell Videos
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是令人惊叹的。它可以根据您选择的关键词搜索 YouTube 视频，然后为您呈现视频，以及根据选择播放视频。

以下这段简单的脚本（需要 Internet 连接）可以列出 YouTube 上最新的“Learn PowerShell”视频。该列表使用一个 Grid View 窗口呈现，您可以在顶部使用全文搜索或者按列排序，来查找您需要的视频。

下一步，单击视频项选中它，然后单击网格右下角的“确定”按钮。

PowerShell 将会启动您的 Web 浏览器并且播放视频。太棒了！

	$keyword = "Learn PowerShell"

	Invoke-RestMethod -Uri "https://gdata.youtube.com/feeds/api/videos?v=2&q=$($keyword.Replace(' ','+'))" |
	Select-Object -Property Title, @{N='Author';E={$_.Author.Name}}, @{N='Link';E={$_.Content.src}}, @{N='Updated';E={[DateTime]$_.Updated}} |
	Sort-Object -Property Updated -Descending |
	Out-GridView -Title "Select your '$Keyword' video, then click OK to view." -PassThru |
	ForEach-Object { Start-Process $_.Link }

只需要改变第一行的 `$keyword` 变量就可以搜索不同的视频或者主题。

请注意由于 PowerShell 3.0 的一个 bug，`Invoke-RestMethod` 只会返回一部分结果。PowerShell 4.0 修复了这个 bug。

> 译者注：由于国内暂时不可直接访问 YouTube 服务，验证本脚本需要合适的代理服务器或 VPN。

<!--本文国际来源：[Search and View PowerShell Videos](http://community.idera.com/powershell/powertips/b/tips/posts/search-and-view-powershell-videos)-->

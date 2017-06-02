---
layout: post
title: "用 PowerShell 脚本来清除您 Delicious 账户下的所有书签"
date: 2013-11-01 00:00:00
description: Use PowerShell to Clear All Bookmarks in Your Delicious Account
categories: powershell
tags:
- powershell
- script
- geek
- delicious
- web
---
前言
====
[美味书签][美味书签]是 [Delicious][Delicious] 在线书签服务的中国本地化版本。由于各方面原因，美味书签实现的功能有限，远远达不到 Delicious 的功能。所以我希望将美味书签中的使用记录迁移回 Delicious。

经过一年使用，我在美味书签中已经积累了 5000+ 条书签记录。由于[美味书签][美味书签]不支持书签导出功能，所以将美味书签中的书签导出至 Delicious 是一件需要动手动脑的事。幸好我们有 PowerShell 脚本，可以助我们完成这项单调枯燥的事。

这是一个系列文章，一共分为 3 部分：
1. [用 PowerShell 脚本来导出美味书签][用 PowerShell 脚本来导出美味书签]
2. [用 PowerShell 脚本来清除 Delicious 账户下的所有书签][用 PowerShell 脚本来批量删除 Delicious 账户下的所有书签]
3. [用 PowerShell 脚本将书签批量导入 Delicious][用 PowerShell 脚本将书签批量导入 Delicious]

原理分析
========

Delicious API
-------------

通过阅读 [Delicious API][Delicious API]，我们找出需要的 API 来：

| API                  | 功能                     |
|----------------------|--------------------------|
| /v1/posts/all?       | 列出所有书签             |
| /v1/posts/all?hashes | 以哈希的形式列出所有书签 |
| /v1/posts/delete?    | 删除一条书签             |

其中 `/v1/posts/all?hashes` 这条 API 暂时用不到。

身份验证
--------
在 Delicious API 文档中提到了在 URL 中包含用户和密码的方式来验证身份：

	$ curl https://user:passwd@api.delicious.com/v1/posts/get?tag=webdev&meta=yes

但在实际中这个方法行不通。我们还是通过 PowerShell 的 `Get-Credential` 命令来实现：

	$credential = Get-Credential -UserName $userName -Message '请输入密码'

这段代码的执行效果是弹出一个身份验证框

![](/img/2013-11-01-use-powershell-to-clear-all-bookmarks-in-your-delicious-account-001.png)

当然，您也可以把身份信息硬编码的方式写在脚本中，在调试期可以提高效率。但在脚本发布时，可以采用 `Get-Credential` 这种优雅的方式来提示用户输入。

调用 API
--------
调用 Delicious API 的方法十分简单，由于返回的是一个 XML 文档，我们可以显式地将 $listResponse 返回值的数据类型声明为 `[xml]`。

	[xml]$listResponse = Invoke-WebRequest -Uri 'https://api.del.icio.us/v1/posts/all?red=api' -Credential $credential

解析执行结果
------------
我们可以在浏览器中试着敲入 `https://api.delicious.com/v1/posts/all?red=api` 来观察执行结果，浏览器将会要求您输入 Delicious 的用户名与密码：

![](/img/2013-11-01-use-powershell-to-clear-all-bookmarks-in-your-delicious-account-002.png)

通过观察 XML 的结构，我们可以从 API 响应中取得所有书签的链接，用 XPATH 表达为 `posts/post/@href`。用 PowerShell 来表达，代码如下：

	$links = $listResponse.posts.post | select -exp href -Unique

考虑到有些链接可能重复，我们加了个 `-Unique` 参数，取得不重复的唯一结果。

删除链接
--------
通过上述方法得到所有的书签链接之后，我们可以循环调用 `/v1/posts/delete?` API 来删除它们。根据文档，若删除成功，将返回：

	<result code="done" />

所以我们可以这样设计脚本：

	if ($response.result.code -eq 'done') {
		#
	}

吝啬地休眠
----------
API 文档中有一句严厉的警告，原文如下：

> Please wait **at least one second** between HTTP queries, or you are likely to get automatically throttled. If you are releasing a library to access the API, you **must** do this.

意思是说 HTTP 请求不能太频繁，**至少**要间隔 1 秒。但我觉得时间是珍贵的，如果每次 `Start-Sleep -Seconds 1` 的话，每一次加上网络传输时间，就不止 1 秒了。时间浪费在 sleep 上十分可惜，特别是在大量的循环中更是如此。我希望 sleep 的时间恰好是 1 秒。所以我设计了一个函数，计算当前时间与上一次 sleep 时的时间差。然后**精确地** sleep 这个时间差值，一点也不多睡 ;-)

	function Invoke-StingySleep ($seconds) {
	    if (!$lastSleepTime) {
	        $lastSleepTime = Get-Date
	    }
	
	    $span = $lastSleepTime + (New-TimeSpan -Seconds 1) - (Get-Date)
	    Start-Sleep -Milliseconds $span.TotalMilliseconds
	}

不过实际使用中，似乎 Delicious 的开发者比较仁慈。如果我把 `Start-Sleep` 这行去掉，服务器并没有因为我们连续不断地请求而把我们的程序给屏蔽掉。当然也有可能是我所在的地方网络延迟太大了。

容错技巧
========
其实这个程序还有很多地方可以改进，例如每次调用删除 API 后判断服务器的 HTTP 响应是否正确，但可以不去改进它。理由是：既然我们的目的是删除所有的书签，那么如果有某一些漏网之鱼没有删掉，那么在下一轮循环中会被查询出来，重新删除。只要脚本工作得不离谱的话，一定能删到完为止。

[Delicious]:     http://delicious.com                  "Delicious官方网站"
[美味书签]:      http://meiweisq.com                   "Delicious的中国版"
[Delicious API]: https://github.com/avos/delicious-api "在 github 上的Delicious API说明"

[用 PowerShell 脚本来导出美味书签]: /powershell/2013/11/01/use-powershell-to-export-bookmarks-in-meiweisq
[用 PowerShell 脚本来清除 Delicious 账户下的所有书签]: /powershell/2013/11/01/use-powershell-to-clear-all-bookmarks-in-your-delicious-account
[用 PowerShell 脚本将书签批量导入 Delicious]: /powershell/2013/11/01/use-powershell-to-batch-import-bookmarks-into-delicious

源代码
======
<!--more-->

	$userName = 'vichamp'
	
	Add-Type -AssemblyName 'System.Web'
	#$password = ConvertTo-SecureString –String "xxx" –AsPlainText -Force
	
	$credential = Get-Credential -UserName $userName -Message '请输入密码'
	
	function Invoke-StingySleep ($seconds) {
	    if (!$lastSleepTime) {
	        $lastSleepTime = Get-Date
	    }
	
	    $span = $lastSleepTime + (New-TimeSpan -Seconds 1) - (Get-Date)
	    #Start-Sleep -Milliseconds $span.TotalMilliseconds
	}
	
	while ($true) {
	    Invoke-StingySleep 1
	    [xml]$listResponse = Invoke-WebRequest -Uri 'https://api.delicious.com/v1/posts/all?red=api' -Credential $credential
	    #[xml]$response = Invoke-WebRequest -Uri 'https://api.del.icio.us/v1/posts/all?hashes' -Credential $credential
	    if (!$listResponse.posts.post) {
	        break
	    }
	    $links = $listResponse.posts.post | select -exp href -Unique
	
	    $links | foreach {
	        $encodedLink = [System.Web.HttpUtility]::UrlEncode($_)
	
	        Invoke-StingySleep 1
	        [xml]$response = Invoke-WebRequest -Uri "https://api.delicious.com/v1/posts/delete?url=$encodedLink"  -Credential $credential
	        if ($response.result.code -eq 'done') {
	            Write-Output "[$($response.result.code)] $_"
	        } else {
	            Write-Warning "[$($response.result.code)] $_"
	        }
	    }
	}
	
	echo 'Done'

您也可以[点击这里下载](/assets/download/Clear-Delicious.ps1)源代码。

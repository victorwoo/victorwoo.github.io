---
layout: post
title: "用 PowerShell 脚本将书签批量导入 Delicious"
date: 2013-11-01 00:00:00
description: Use PowerShell to Batch Import Bookmarks into Delicious
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

通过阅读 [Delicious API][Delicious API]，可以知道我们只需要这样一条 API `/v1/posts/add?`，它的参数为：

- `&url={URL}` (required) — The url of the item.
- `&description={...}` (required) — The description of the item.
- `&extended={...}` (optional) — Botes for the item.
- `&tags={...}` (optional) — Tags for the item (comma delimited).
- `&dt={CCYY-MM-DDThh:mm:ssZ}` (optional) — Datestamp of the item (format “CCYY-MM-DDThh:mm:ssZ”). Requires a LITERAL “T” and “Z” like in ISO8601 at http://www.cl.cam.ac.uk/~mgk25/iso-time.html for Example: `1984-09-01T14:21:31Z`
- `&replace=no` (optional) — Don’t replace post if given url has already been posted.
- `&shared=no` (optional) — Make the item private

关于身份验证，请参考本系列的另一篇文章 [用 PowerShell 脚本来清除 Delicious 账户下的所有书签][用 PowerShell 脚本来清除 Delicious 账户下的所有书签] 。

URL 编码
--------
我们需要提交的书签中，`description` 字段和 `tags` 字段是有可能出现 URL 中不允许的字符的，例如 `?`、`&`，以及中文字符等。我们需要将它们进行 URL 编码以后，才可以拼接到 URL 字符串中。在 PowerShell 中进行 URL 编码的方法如下：

	Add-Type -AssemblyName 'System.Web'
	[System.Web.HttpUtility]::UrlEncode('中文')

其中第一行是为了加载 System.Web 程序集。还可以用以下两种方法来实现：

	[void][system.Reflection.Assembly]::LoadWithPartialName("System.Web")

以及：

	[Reflection.Assembly]::LoadFile('C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727\System.Web.dll') | Out-Null

生成查询字符串
--------------
我们要在查询字符串中包含 API 文档中提到的那 7 个参数。用 `string -f` 的方式显得有点笨拙。于是我们编写这样一个函数：

	function Get-QueryString ($params) {
	    $keyValuePairs = ($params.Keys | % {
	        write ('{0}={1}' -f $_, $params[$_])
	    })
	    return $keyValuePairs -join '&'
	}

这个函数接收一个哈希表作为参数，也可以是 `[ordered]` （即`OrderedDictionary`）。函数中循环地取出所有键，将它们的值用 `&` 符号拼接在一起。

容错设计
========
若是 `Invoke-WebRequest` 命令抛出异常，或是 HTTP 响应码不为 200，或是 XML 中不是 `<result code="done" />` 这样的返回，那么表示添加书签失败。我们可以把这些书签收集起来，输出到 *failed_import.csv* 文件中。然后下次可以再对这个文件进行导入。直到这个文件中没有记录为止。当然，您也可以将脚本改进一下，全自动地做完上述的事情。那么您一定是懒（勤劳）到家了 ;-)

[Delicious]:     http://delicious.com                  "Delicious官方网站"
[美味书签]:      http://meiweisq.com                   "Delicious的中国版"
[Delicious API]: https://github.com/avos/delicious-api "在 github 上的Delicious API说明"

[用 PowerShell 脚本来导出美味书签]: /powershell/2013/11/01/use-powershell-to-export-bookmarks-in-meiweisq
[用 PowerShell 脚本来清除 Delicious 账户下的所有书签]: /powershell/2013/11/01/use-powershell-to-clear-all-bookmarks-in-your-delicious-account
[用 PowerShell 脚本将书签批量导入 Delicious]: /powershell/2013/11/01/use-powershell-to-batch-import-bookmarks-into-delicious

源代码
======

	$userName = 'vichamp'
	$importFileName = 'meiweisq-export-20131030.csv'
	#$importFileName = 'failed_import.csv'

	Add-Type -AssemblyName 'System.Web'
	#$password = ConvertTo-SecureString –String "xxx" –AsPlainText -Force

	$credential = Get-Credential -UserName $userName -Message '请输入密码'

	function Get-QueryString ($params) {
	    $keyValuePairs = ($params.Keys | % {
	        write ('{0}={1}' -f $_, $params[$_])
	    })
	    return $keyValuePairs -join '&'
	}

	$startTime = [datetime]::Now
	$template = 'https://api.del.icio.us/v1/posts/add?{0}'

	$bookmarks = Import-Csv $importFileName
	$failedBookmarks = @()
	$index = 0
	$bookmarks | foreach {
	    $params = @{}
	    $params.Add('description', [System.Web.HttpUtility]::UrlEncode($_.Title))
	    if ($false) {
	        $params.Add('extended', [System.Web.HttpUtility]::UrlEncode(''))
	    }
	    $params.Add('tags', [System.Web.HttpUtility]::UrlEncode([string]::Join(',', $_.Tags -split ', ')))
	    $params.Add('dt', ("{0}T00:00:00Z" -f ($_.LinkTime -creplace '/', '-')))
	    $params.Add('replace', 'no')
	    $params.Add('shared', 'yes')
	    $params.Add('url', $_.Url)

	    $queryString = Get-QueryString $params
	    $url = $template -f $queryString

	    $message = "Bookmark: {0} / {1}, Elapsed: {2}" -f @(
	        $($index + 1),
	        $bookmarks.Length,
	        ([datetime]::Now - $startTime).ToString()
	    )
	    Write-Progress -Activity 'Adding bookmarks' -PercentComplete (100 * $index / $bookmarks.Length) -CurrentOperation $message
	    #echo "Requesting $_.Url"

	    $isSuccess = $false
	    try {
	        [xml]$response = Invoke-WebRequest -Uri $url -Credential $credential
	        $isSuccess = $response.StatusCode -eq 200 -and $response.result.code -eq 'done'
	    } catch { }

	    if ($isSuccess) {
	        Write-Output "[SUCC] $($_.Url)"
	    } else {
	        Write-Warning "[FAIL] $($_.Url)"
	        $failedBookmarks += $_
	    }

	    $index++
	}

	$failedBookmarks | Export-Csv 'failed_import.csv' -Encoding UTF8 -NoTypeInformation

您也可以[点击这里下载](/assets/download/Import-Delicious.ps1)源代码。

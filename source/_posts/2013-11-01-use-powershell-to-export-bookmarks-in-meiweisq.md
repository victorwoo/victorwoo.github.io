layout: post
title: "用 PowerShell 脚本来导出美味书签"
date: 2013-11-01 00:00:00
description: Use PowerShell to Export Bookmarks in meiweisq
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
2. [用 PowerShell 脚本来清除 Delicious 账户下的所有书签][用 PowerShell 脚本来清除 Delicious 账户下的所有书签]
3. [用 PowerShell 脚本将书签批量导入 Delicious][用 PowerShell 脚本将书签批量导入 Delicious]

原理分析
========

模拟美味书签的登录过程
----------------------
美味书签的登录页面地址为 [http://meiweisq.com/login](http://meiweisq.com/login "登录美味书签") 。我们可以使用 `Invoke-WebRequest` 获取登录页面，同时把会话信息记录到 *$rb* 变量中。

![](/img/2013-11-01-use-powershell-to-export-bookmarks-in-meiweisq-001.png)

相应的 PowerShell 代码如下：

	$response = Invoke-WebRequest -Uri $homeUrl -Method Default -SessionVariable rb -ContentType application/html

得到的响应中其中包含多个表单。通过查看网页源代码，我们可以确定 Action 为“/login”的那个表单是我们所要的：

![](/img/2013-11-01-use-powershell-to-export-bookmarks-in-meiweisq-002.png)

相应的 PowerShell 代码为：

	$loginForm = ($response.Forms | where { $_.Action -eq '/login' })[0]

我们在 Chrome 浏览器中登录一下，通过“开发者工具”的“Network”选项卡查看提交的数据：

![](/img/2013-11-01-use-powershell-to-export-bookmarks-in-meiweisq-003.png)

根据提交的数据，我们可以编写 PowerShell 代码来提交表单，模拟登录按钮的动作。注意传入会话变量 *$rb*，以在后续的过程中保持会话身份，否则下次提交又会提示需要登录：

	$loginForm.Fields['email'] = $email
	$loginForm.Fields['password'] = $password
	$loginForm.Fields['type'] = '登录'
	$loginForm.Fields['return-url'] = '/home'
	$loginForm.Fields['remember'] = 'off'
	$response = Invoke-WebRequest -Uri $loginAction -WebSession $rb -Method POST -Body $loginForm

取得书签总数
------------

在登录后的页面底部有“*1 - 30 共 5126 个书签*”的字样，其中 *30* 和 *5126* 两个数字是我们关心的。我们用正则表达式 `1 - (\d+) 共 (\d+) 个书签` 从整个网页中提取书签的总数量。在 PowerShell 使用正则表达式：

	$response.Content -cmatch '1 - (\d+) 共 (\d+) 个书签'
	$page1Count = $Matches[1]
	$totalCount = $Matches[2]
	echo "1 - $page1Count 共 $totalCount 个书签"

根据 *$page1Count* 和 *$totalCount*，就可以计算总页数了：

	$pageCount = [math]::Ceiling($totalCount / $bookmarksPerPage)

遍历每一页
----------
知道了总页数，自然想到用 for 循环来遍历它们。我们观察每一页的规律，发现页码是通过 URL 的 page 参数指定的。我们用 PowerShell 来拼接 URL 字符串：

	$uri = 'http://meiweisq.com/home?page=' + $page

对于每一页，继续用 `Invoke-WebRequest` 来获取它的内容：

	$response = Invoke-WebRequest -Uri $uri -Method Default -WebSession $rb

分析书签
--------
在每一页中，含有不超过 30 个书签，其中包含了书签的标题、URL、标签、时间等信息。

![](/img/2013-11-01-use-powershell-to-export-bookmarks-in-meiweisq-004.png)

接下来是一些 DOM 的分析，需要一点耐心。我们先把它输出为 .html 文件，以便分析：

	$response.Content > current_page.html

从 Chrome 的开发者工具中，可以观察到 DOM 的结构。和我们有关系的是 class 为 links、link、tags、tag这些元素。我们用 jQuery 的语法来表达它们，整理成一个表格如下：

| 选择器                             | 含义               |
|------------------------------------|--------------------|
| div.links                          | 本页所有书签的集合 |
| div.links > div.link               | 一个书签           |
| div.links > div.link a.link-title  | 书签标题、URL      |
| div.links > div.link a.link-time   | 时间               |
| div.links > div.link ul.tags > tag | 标签               |

请注意一下，在 `Invoke-WebRequest` 的结果（COM 对象）中做 DOM 查询，是有点慢的，不像 WEB 中的 jQuery 那么高效。在我们需要做一定的优化，以缩短大量的查询的总时间。我的优化原则如下：

1. 能用 id 过滤的，不用 tag。
2. 如果需要查询一个节点的子节点，则把前者保存到临时变量中，不要每次都从根对象（document）开始查询。

以下是 DOM 查询的相关代码：

    $html = $response.ParsedHtml
    $linksDiv = ($html.getElementsByTagName('div') | where { $_.classname -eq 'links' })[0]
	$linksDiv.getElementsByTagName('div') | where { $_.classname -cmatch '\blink[\s,$]' }

	$linkTitle = $div.getElementsByTagName('a') | where { $_.className -eq 'link-title' }
	$title = $linkTitle | select -exp innerText
	$url = $linkTitle | select -exp href

	$linkTime = $div.getElementsByTagName('p') | where { $_.className -eq 'link-time' } | select -exp innerText

	$ul = $div.getElementsByTagName('ul') | where { $_.className -cmatch '\btags[\s,$]' }
    $tags = $ul.getElementsByTagName('a') | where { $_.className -cmatch 'tag' }
    $tagNames = $tags | foreach { $_.getAttribute('tag') }

Javascript 的时间转换
-------------------
美味书签的时间以 `yyyy/MM/dd` 的形式表达，而 Delicious 导入/导出文件的时间以 Javascript 格式表达。它们之间的转换方法是，前者减去1970年1月1日0时整的时间差，得到的总秒数，即得到其 Javascript 的格式表达。PowerShell 实现代码如下：

	$jsTime = ([datetime]::ParseExact($_.LinkTime, 'yyyy/MM/dd', $null) - [datetime]'1970-01-01').TotalSeconds

输出
----
经过上面的步骤，我们已将所有的书签以 PSObject 的形式存放在 $bookmarks 数组中。现在可以随心所欲地将 $bookmarks 输出为我们所希望的格式了：

这是输出为 CSV 格式的代码：

	$bookmarks | Export-Csv ("meiweisq-export-{0:yyyyMMdd}.csv" -f [datetime]::Now) -Encoding UTF8 -NoTypeInformation

这是输出到 GUI 界面的代码：

	$bookmarks | Out-GridView

另外，我们可以导出为 [Delicious][Delicious] 的专用格式。由于格式比较简单，我们就不用 `ConvertTo-HTML` 之类的函数了。

[Delicious]:     http://delicious.com                  "Delicious官方网站"
[美味书签]:      http://meiweisq.com                   "Delicious的中国版"
[Delicious API]: https://github.com/avos/delicious-api "在 github 上的Delicious API说明"

[用 PowerShell 脚本来导出美味书签]: /powershell/2013/11/01/use-powershell-to-export-bookmarks-in-meiweisq
[用 PowerShell 脚本来清除 Delicious 账户下的所有书签]: /powershell/2013/11/01/use-powershell-to-clear-all-bookmarks-in-your-delicious-account
[用 PowerShell 脚本将书签批量导入 Delicious]: /powershell/2013/11/01/use-powershell-to-batch-import-bookmarks-into-delicious

源代码
======
<!--more-->

	$email = 'victorwoo@gmail.com'
	$password = 'xxx'
	
	$homeUrl = 'http://meiweisq.com/home'
	$loginAction = 'http://meiweisq.com/login'
	
	$bookmarksPerPage = 30
	$countPerExport = 10
	
	function Get-DeliciousHtml($bookmarks) {
	    $pre = @"
	<!DOCTYPE NETSCAPE-Bookmark-file-1>
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
	<!-- This is an automatically generated file.
	It will be read and overwritten.
	Do Not Edit! -->
	<TITLE>Bookmarks</TITLE>
	<H1>Bookmarks</H1>
	<DL><p>
	
	"@
	
	    $post = @"
	</DL><p>
	"@
	
	    $bookmarkTemplate = @"
	<DT><A HREF="{0}" ADD_DATE="{1}" PRIVATE="{2}" TAGS="{3}">{4}</A>
	<DD>{5}
	
	"@
	    $result = $pre
	    $bookmarks | foreach {
	        $jsTime = ([datetime]::ParseExact($_.LinkTime, 'yyyy/MM/dd', $null) - [datetime]'1970-01-01').TotalSeconds
	        $tags = [string]::Join(',', $_.Tags -split ', ')
	        $bookmarkString = $bookmarkTemplate -f $_.Url, $jsTime, 0, $tags, $_.Title, ''
	        $result += $bookmarkString
	    }
	    $result += $post
	    return $result
	}
	
	$startTime = [datetime]::Now
	
	echo 'Requesting home'
	$response = Invoke-WebRequest -Uri $homeUrl -Method Default -SessionVariable rb -ContentType application/html
	if ($response.StatusCode -ne 200) {
	    Write-Warning "[$response.StatusCode] $homeUrl"
	    return
	}
	$response.Content > mwsq_login.html
	
	echo 'Logining'
	$loginForm = ($response.Forms | where { $_.Action -eq '/login' })[0]
	$loginForm.Fields['email'] = $email
	$loginForm.Fields['password'] = $password
	$loginForm.Fields['type'] = '登录'
	$loginForm.Fields['return-url'] = '/home'
	$loginForm.Fields['remember'] = 'off'
	
	$response = Invoke-WebRequest -Uri $loginAction -WebSession $rb -Method POST -Body $loginForm
	if ($response.StatusCode -ne 200) {
	    Write-Warning "[$response.StatusCode] $loginAction"
	    return
	}
	$response.Content > mwsq_home.html
	
	if ($response.Content -cnotmatch '1 - (\d+) 共 (\d+) 个书签') {
	    Write-Warning '找不到书签个数'
	    return
	}
	
	$page1Count = $Matches[1]
	$totalCount = $Matches[2]
	echo "1 - $page1Count 共 $totalCount 个书签"
	$pageCount = [math]::Ceiling($totalCount / $bookmarksPerPage)
	echo "共 $pageCount 页"
	echo ''
	
	$bookmarks = @()
	for ($page = 1; $page -le $pageCount; $page++) {
	    $uri = 'http://meiweisq.com/home?page=' + $page
	    echo "Requesting $uri"
	
	    $isSuccess = $false
	    while (!$isSuccess) {
	        try {
	            $response = Invoke-WebRequest -Uri $uri -Method Default -WebSession $rb
	            if ($response.StatusCode -ne 200) {
	                Write-Warning "[$response.StatusCode] $loginAction"
	                continue
	            }
	            $isSuccess = $true
	        } catch { }
	    }
	
	    $response.Content > current_page.html
	    $html = $response.ParsedHtml
	    $linksDiv = ($html.getElementsByTagName('div') | where { $_.classname -eq 'links' })[0]
	    $linksDiv.getElementsByTagName('div') | where { $_.classname -cmatch '\blink[\s,$]' } | foreach {
	        $message = "Bookmark: {0} / {1}, Page: {2} / {3}, Elapsed: {4}" -f @(
	            $($bookmarks.Length + 1),
	            $totalCount,
	            $page
	            $pageCount,
	            ([datetime]::Now - $startTime).ToString()
	        )
	        Write-Progress -Activity 'Getting bookmarks' -PercentComplete (100 * ($bookmarks.Length + 1) / $totalCount) -CurrentOperation $message
	        echo "$($bookmarks.Length + 1) of $totalCount"
	        $div = $_
	        $linkTitle = $div.getElementsByTagName('a') | where { $_.className -eq 'link-title' }
	
	        $title = $linkTitle | select -exp innerText
	        $title = $title.Trim()
	        echo $title
	
	        $url = $linkTitle | select -exp href
	        echo $url
	        
	        $linkTime = $div.getElementsByTagName('p') | where { $_.className -eq 'link-time' } | select -exp innerText
	        $linkTime = $linkTime.Trim()
	        echo $linkTime
	
	        $ul = $div.getElementsByTagName('ul') | where { $_.className -cmatch '\btags[\s,$]' }
	        $tags = $ul.getElementsByTagName('a') | where { $_.className -cmatch 'tag' }
	        $tagNames = $tags | foreach { $_.getAttribute('tag') }
	        if ($tagNames -eq $null) {
	            $tagNames = @()
	        }
	        
	        
	        echo "[$([string]::Join(' | ', $tagNames))]"
	        echo ''
	
	        $bookmark = [PSObject]@{
	            Title = $title
	            Url = $url
	            LinkTime = $linkTime
	            Tags = [string]::Join(', ', $tagNames)
	        }
	
	        $bookmarks += New-Object -TypeName PSObject -Property $bookmark
	    }   
	}
	
	echo 'Exporting html thant you can import into del.icio.us'
	$index = 0
	while ($index -lt $totalCount) {
	    $currentCountInExport = [math]::Min($countPerExport, $totalCount - $index)
	    $endIndex = $index + $currentCountInExport
	
	    $deliciousHtml = Get-DeliciousHtml ($bookmarks | select -Skip $index -First $currentCountInExport)
	    $deliciousHtml | sc -Encoding UTF8 ("meiweisq-export-{0:yyyyMMdd}-{1}-{2}.html" -f [datetime]::Now, $index, $endIndex)
	    $index += $currentCountInExport
	}
	
	$deliciousHtml = Get-DeliciousHtml $bookmarks
	$deliciousHtml | sc -Encoding UTF8 ("meiweisq-export-{0:yyyyMMdd}-all.html" -f [datetime]::Now)
	
	echo 'Exporting CSV.'
	$bookmarks | Export-Csv ("meiweisq-export-{0:yyyyMMdd}.csv" -f [datetime]::Now) -Encoding UTF8 -NoTypeInformation
	
	echo 'Exporting GUI.'
	$bookmarks | Out-GridView
	
	echo 'All done.'

您也可以[点击这里下载](/assets/download/Export-Meiweisq.ps1)源代码。

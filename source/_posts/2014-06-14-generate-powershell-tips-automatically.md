---
layout: post
title: "自动生成 PowerShell 技能连载"
date: 2014-06-14 00:00:00
description: Generate PowerShell tips automatically
categories: powershell
tags:
- powershell
- node.js
- regex
---
[Tobias Weltner][Tobias Weltner] 博士每个工作日都在 [www.powershell.com][www.powershell.com] 发布一篇 PowerShell 技能。这个系列在 PowerShell 的技术社区里已是家喻户晓，成为关注 PowerShell 技术动态的一扇窗口。

这个套技能连载在中国有两个版本的翻译。一套是由荔非苔创立的 [Powershell小技巧][Powershell小技巧]，现由荔非苔和 CodeCook 两人维护；另一套是本站的 [PowerShell 技能连载][PowerShell 技能连载]。

本站是采用 [JekyllBootstrap][JekyllBootstrap] 系统搭建，使用 [markdown][markdown] 编辑文章，并使用 [git][git] 发布到 [GitHub Pages][GitHub Pages] 上。采用这些略带 geek 感的技术来做这个站点，是因为：

- 用 markdown 可以使我关注文案的内容，而不是格式。并且它十分适合编写技术文章。
- git 很酷，可以多人协作，可以像写代码一样写文章。
- 可以自由地调整源代码，加入新奇的功能，甚至可以用脚本来做站点搬家。
- GitHub Pages 可以为我们提供免费的服务器。
- 一切都是开源的，您可以查看到这个站点的一切源代码、文章源文件，甚至所有的维护脚本。
- 我本身是一个 geek。

我已翻译了[PowerShell 技能连载][PowerShell 技能连载]的 200 多篇文章。与此同时，我也采用各种技术方法提升翻译工作的效率。翻译一篇文章所占用的时间已从最初的 30 分钟缩短到现在的 10 分钟。以下部分将演示我是如何做到的。翻译一篇文章，需要经历以下步骤：

- 从 [www.powershell.com][www.powershell.com] 搜集新文章。
- 创建新的 markdown 文件。文件名对应原文的 url 地址。
- 编辑文件头的元数据。
- 将英文的内容转换成 markdown 格式，贴到文件正文部分。
- 在文本编辑器中，将英文内容逐段翻译成中文，并将原文逐段删除。
- 处理文章中的图片。
	- 将它下载到本地。
	- 以文章的文件名作为前缀，并加上序号作为文件名。
	- 修正文章中的图片地址。
- 在浏览器中打开原文，以供对照参考。

我们可以用 PowerShell 逐一解决这些问题：

# 搜集新文章
## 获取更新列表

浏览 [www.powershell.com][www.powershell.com] 的源代码，发现该网站有提供 PowerShell tips 的 RSS 订阅：

	<link rel="alternate" type="application/atom+xml" title="Power Tips (Atom 1.0)" href="http://powershell.com/cs/blogs/tips/atom.aspx"  />

通过 RSS 服务，我们就可以通过编程的方式，自动化地获取文章的内容。

	$atomUrl = 'http://powershell.com/cs/blogs/tips/atom.aspx'
	$feed = Invoke-RestMethod $atomUrl

获取到的 `$feed` 变量大概是这样的一个数组：

	title     : Using Profile Scripts
	link      : link
	id        : /cs/blogs/tips/archive/2014/06/13/using-profile-scripts.aspx
	published : 2014-06-13T11:00:00Z
	updated   : 2014-06-13T11:00:00Z
	content   : content
	author    : author
	
	title     : Be Aware of Side Effects
	link      : link
	id        : /cs/blogs/tips/archive/2014/06/12/be-aware-of-side-effects.aspx
	published : 2014-06-12T11:00:00Z
	updated   : 2014-06-12T11:00:00Z
	content   : content
	author    : author

其中 `link`、`id`、`content` 对我们有用。`content` 是 `XmlElement` 类型的对象，我们一会儿会用到。

## 从更新列表中提取文章信息
由于 `id` 的变化部分是以 yyyy/mm/dd 开头的，所以我们可以放心地用 `Sort-Object` 直接进行字符串排序。这个 cmdlet 有个常用的别名，叫做 `sort`。

接下来用正则表达式提取 `year`、`month`、`day`、`name` 这几个元素。通过这些元素，我们就可以组织目标文件名：

	$feed | sort { $_.id } | foreach {
	    $entry = $_
	
	    if ($entry.id -cmatch '^/cs/blogs/tips/archive/(?<year>\d{4})/(?<month>\d{2})/(?<day>\d{2})/(?<name>.+)\.aspx$') {
		    $year = $matches['year']
	        $month = $matches['month']
	        $day = $matches['day']
	        $name = $matches['name']
	    }
	
	    $targetFile = Join-Path $folder "$year-$month-$day-$name.md"

## 跳过已有的文件
由于 RSS 中返回的是最后 15 篇文章，也就是近 3 周来的文章列表，如果遇到已翻译过的文章，需要自动跳过：

    if (Test-Path $targetFile) {
        echo "[文件已存在] $year-$month-$day-$name.md"
    } else {

# 生成 markdown 文件
## 模板方法
每篇文章对应一个 markdown 文件。在文件的头部，有一段用 yaml 描述的元数据，也就是用两条 `---` 分隔的部分：

	function Get-Post ($enty) {
	    $postTemplate = @'
	layout: post
	title: "PowerShell 技能连载 - ___"
	description: "PowerTip of the Day - {0}"
	categories: [powershell, tip]
	tags: [powershell, tip, powertip, series, translation]
	{1}
	
	<!--more-->
	本文国际来源：[{2}]({3})
	'@
	    $entryUrl = 'http://powershell.com' + $entry.link.href
	    $htmlContent = $entry.content.'#text'
	
	    $htmlDoc = Get-Document $htmlContent
	    $htmlContent = $htmlDoc.documentElement.innerHTML
	    $htmlDoc.Close()
	
	    $markdown = Get-Markdown $htmlContent
	    return $postTemplate -f $entry.title, $markdown, $entry.title, $entryUrl
	}

代码中的 `$postTemplate` 是一个用 here string 描述的文件模板，其中所有的变量都用 `{x}` 占位符来代替。而 `title` 部分的 `___` 是为中文名称预留的位置。由于程序无法自动填充中文名，所以这个位置需要在人工翻译阶段手动填充。

函数尾部的 `$postTemplate -f $entry.title, $markdown, $entry.title, $entryUrl` 是采用字符串的 `-f` 运算符进行格式化，将各个变量填充到 `{x}` 占位符处。`-f` 的本质是调用了 String 类的 Format() 静态方法。

## 解析 DOM 结构
上述代码调用了一个 `Get-Document` 函数，将 `$htmlContent` 字符串转换为一个 DOM 对象。它的实现方法如下：

	function Get-Document($text) {
	    $htmlDoc= New-Object -com "HTMLFILE"
	    if ($htmlDoc.IHTMLDocument2_write) {
	        $htmlDoc.IHTMLDocument2_write($text)
	    } else {
	        $htmlDoc.write($text)
	    }
	
	    return $htmlDoc
	}

这里采用了 `HTMLFILE` COM 对象的 `IHTMLDocument2_write()` 或 `write()` 方法，来返回一个 HtmlDocument 对象。因为我发现不同的机器上，存在不同的版本。很遗憾关于这块的 MSDN 文档不太好找，这是我自创的方式，有效果，不知有没有更好的方法实现。

拿到 HtmlDocument 以后，就可以进行 DOM 操作了。这里我们简单地获取 Document 对象的 `innerHTML` 属性，并且注意及时关闭 COM 对象以释放资源：

	$htmlContent = $htmlDoc.documentElement.innerHTML
	$htmlDoc.Close()

## 将 HTML 转换为 markdown
### 编写 Node.js 程序
在 PowerShell 和 .NET 的世界里，目前没有很理想的 HTML 转 markdown 库可用。不过 [Node.js][Node.js] 中有一个不错的库 [html2markdown][html2markdown]。

由于 node.exe 传入太长的参数可能会有意想不到的问题，所以直接向 Node.js 程序传递 HTML 字符串不可靠。更可靠的方式是将 HTML 字符串保存到临时文件中，将临时文件的文件名传递给 Node.js 程序。

我们可以写一个 Node.js 的小程序，目的是让 PowerShell 以这种方式调用：

	node.exe index.js htmlFilePath markdownFilePath

其中 `htmlFilePath` 为输入的 HTML 文件路径，`markdownFilePath` 为输出的 markdown 文件路径。

接下来用 npm 快速创建一个 Node.js 工程（暂时也叫 html2markdown，虽然和库的名字相同，不过影响使用）：

	npm init html2markdown

对向导的提示一路回车即可。然后添加 [html2markdown][html2markdown] 库的引用：

	npm install html2markdown --save

生成好的 package.json 文件如下：

	{
	  "name": "html2markdown",
	  "version": "0.0.0",
	  "description": "",
	  "main": "index.js",
	  "dependencies": {
	    "html2markdown": "~1.1.0"
	  },
	  "devDependencies": {},
	  "scripts": {
	    "test": "echo \"Error: no test specified\" && exit 1"
	  },
	  "author": "",
	  "license": "ISC"
	}

接下来编写 index.js 脚本。这个脚本的原理是：

- 解析 node.exe 进程的参数，提取输入的 HTML 文件路径和输出的 markdown 文件路径
- 读入 HTML 文件内容
- 调用 html2markdown 将 HTML 转换为 markdown
- 写入 markdown 文件内容

index.js 脚本的内容如下：

	var html2markdown = require('html2markdown'),
	    fs = require('fs'),
	    args = process.argv.splice(2),
	    htmlFile = args[0],
	    markdownFile = args[1],
	    html,
	    markdown;
	
	html = fs.readFileSync(htmlFile, { encoding: 'utf8' });
	markdown = html2markdown(html, { inlineStyle: true });
	fs.writeFileSync(markdownFile, markdown);

## 通过 PowerShell 调用 Node.js

以下代码是生成 `$htmlFile`、`$markdownFile` 两个临时文件，然后通过 `node .\html2markdown\index.js $htmlFile $markdownFile` 调用 Node.js 程序。当 Node.js 程序执行完毕以后，通过 `gc` 命令从输出的临时文件中获取 markdown 内容字符串，然后删除所有临时文件。

代码的第一行用正则表达把 HTML 中的 Twitter 回访链接给清理掉：

	function Get-Markdown ($html) {
	    $html = $html -creplace '(?sm)^<P><A href="http://twitter\.com/home/\?status=.*$', ''
	    $htmlFile = [System.IO.Path]::GetTempFileName()
	    $markdownFile = [System.IO.Path]::GetTempFileName()
	    sc $htmlFile $html
	    node .\html2markdown\index.js $htmlFile $markdownFile
	    $markdown = gc -Raw $markdownFile
	    del $htmlFile
	    del $markdownFile
	    $markdown = $markdown.Trim()
	    return $markdown
	}

到此为止，markdown 形式的文章内容已经生成好了。

# 下载文章中的图片

到目前为止，文章中的图片都可以正常显示，不过它们都是位于 www.powershell.com 服务器上。从翻译的角度来说，图片最好保存一份到自己的服务器上，图片跟着文章走。这样就不会因为源网站服务器宕机或其它原因导致译文中的图片出问题。

markdown 中的图片是这样表示的：

	![description](http://www.xxx.com/yyy.png)

我们假设文章的文件名是 *aaa.md*，那么需要做的事情是把 http://www.xxx.com/yyy.png 下载下来，保存在网站的 *..\assets\post_img* 目录下，并且按 *aaa-001.png*、*aaa-002.png* 这样的方式重命名。这样就能很清楚地体现哪个图片是属于哪篇文章。

## 分析文章中的图片

代码中采用这个正则表达式来提取图片的描述和 URL：

	[regex] '!\[(?<desc>.*?)\]\((?<url>.*?)\)'

这句代码是用来生成新的图片文件名：

	$targetPath = "$fileBaseName-{0:d3}$extension" -f $index++

我们可以用一个泛型的哈希表（字典）来保存源路径和替换后的目标路径：

	[System.Collections.Generic.Dictionary[[string],[string]]] $dict = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]'

它等效于 C# 中的这行代码：

	var dict = new Dictionary<string, string>();

这里的 PowerShell 代码就显得不如 C# 直观了。

以下是实现代码：

	function Get-Picture($file) {
	    $index = 1
	    $fileBaseName = ([System.IO.FileInfo]$file).BaseName
	    [System.Collections.Generic.Dictionary[[string],[string]]] $dict = New-Object 'System.Collections.Generic.Dictionary[[string], [string]]'
    
	    cat $file -Encoding UTF8 -Raw | % {
	        $regex = [regex] '!\[(?<desc>.*?)\]\((?<url>.*?)\)'
	        $matches = $regex.Matches($_)
	        
	        if ($matches.Count) {
	            $matches.ForEach({
	                $fullMatch = $_.Value
	                $desc = $_.Groups['desc'].Value
	                $url = $_.Groups['url'].Value
	                if ($url -like 'http*') {
	                    $extension = [System.IO.Path]::GetExtension($url)
	                    $targetPath = "$fileBaseName-{0:d3}$extension" -f $index++
	                    $result = Download-Picture $url $targetPath
	                    if ($result) {
	                        $dict.Add($url, $targetPath)
	                    }
	                }
	            })
	        }
	    }
    
	    $newContent = cat $file -Encoding UTF8 -Raw | % {
	        $line = $_
	        $dict.Keys | % {
	            $url = $_
	            $newPath = $relateUrl + $dict[$url]
	            $line = [string]$line.Replace($url, $newPath)
	        }
	        $line
	    }
    
	    $bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
	    sc $file $bytes -Encoding Byte
	    #[IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
	}

这里为什么用字典来保存源地址和目标地址呢？主要是因为我们不仅需要把每个匹配成功的结果替换成新的文本，还需要针对每个结果执行一段自定义的代码。利用字典先把匹配的结果保存起来，然后遍历字典项，对它们进行进一步的处理。

实际上有个更简单的办法。C# 中 `Regex` 对象的 `Replace()` 方法支持 lambda 表达式，对应的 PowerShell 方法支持用代码块的方式。MSDN 链接为 [Regex.Replace 方法 (String, MatchEvaluator)](http://technet.microsoft.com/zh-cn/library/cft8645c.aspx)。可以一边匹配一边做处理。

只是由于我先写出了文中的版本，所以没有去改进。

## 下载文章中的图片

`Invoke-WebRequest` 可以方便地下载 HTTP 文件，这和 Linux 系统中的 wget 命令十分相似。实际上，`Invoke-WebRequest` 命令有个别名，就叫做 `wget`。下载图片的代码如下：

	function Download-Picture($url, $fileName) {
	    echo "downloading $url to $fileName"
	    $fullPath = Join-Path $downloadPath $fileName
	    Invoke-WebRequest -Uri $url -OutFile $fullPath
	    return $?
	}

# 综述

到此为止，我已完整地介绍了《PowerShell 技能连载》翻译工作中采用脚本进行自动化的全部原理。相应的代码可以在 [这里][utils] 找到。

读者也许会觉得为这些小小的功能用手工操作也可以完成。不过，简单计算一下就能够体现出产生的红利。目前已翻译了 200 多篇文章，按照每篇文章节约 3 分钟计算，自动化操作总共为我节约了 600 分钟，也就是节约了 10 个小时的机械劳动。用这宝贵的一个多工作日来开发脚本、撰写心得，做些动脑筋的事情，不亦是一种提升么？

[Tobias Weltner]: https://mvp.microsoft.com/en-us/mvp/Tobias%20Weltner-9199
[www.powershell.com]: http://powershell.com/cs/blogs/tips/default.aspx
[Powershell小技巧]: http://www.pstips.net/cat/powershell/powershell-tips
[PowerShell 技能连载]: http://blog.vichamp.com/powershell/tip/2013/09/09/index/
[JekyllBootstrap]: http://www.jekyllbootstrap.com/
[markdown]: http://baike.baidu.com/view/2311114.htm
[git]: http://www.git-scm.com/
[GitHub Pages]: https://pages.github.com/
[Node.js]: http://nodejs.org
[html2markdown]: https://www.npmjs.org/package/html2markdown
[utils]: https://github.com/victorwoo/victorwoo.github.io/tree/master/utils

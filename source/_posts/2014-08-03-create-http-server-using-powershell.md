layout: post
title: 用 PowerShell 创建一个 HTTP 服务器
date: 2014-08-03 21:36:14
description:
categories:
tags:
---
用 PowerShell 创建一个 HTTP 服务器其实非常简单，只要 0.8 KB 的代码就搞定了。只要将以下代码保存成 httpd.ps1 并在您的 www 资源目录里执行即可：

    param($Root=".", $Port=8080, $HostName="localhost")
    
    pushd $Root
    $Root = pwd
    
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://$HostName`:$Port/")
    $listener.Start()
    
    echo ("Start {0} at `"$Root`"" -f ($listener.Prefixes | select -f 1))
    echo "Enter Ctrl + C to stop."
    
    while ($true) {
        $context = $listener.GetContext()
    
        $url = $context.Request.Url.LocalPath.TrimStart('/')
        $res = $context.Response
        $path = Join-Path $Root ($url -replace "/","\")
        echo $path
    
        if ((Test-Path $path -PathType Leaf) -eq $true) {
            $content = [IO.File]::ReadAllBytes($path)
            $res.OutputStream.Write($content, 0, $content.Length)
        }
        else {
            $res.StatusCode = 404
        }
        $res.Close()
    }

您也可以从[这儿](/download/httpd.ps1)下载完整的文件。

这是从一个开源项目中看到的：
[MarkdownPresenter/httpd.ps1 at master · jsakamoto/MarkdownPresenter](https://github.com/jsakamoto/MarkdownPresenter/blob/master/httpd.ps1)

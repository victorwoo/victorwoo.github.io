---
layout: post
title: "用 PowerShell 下载 imooc.com 的视频教程"
date: 2014-09-26 17:39:12
description: Download Videos from imooc.com by PowerShell
categories: powershell
tags:
- powershell
- geek
- video
---
这是一个从 http://www.imooc.com 教学网站批量下载视频的 PowerShell 脚本。默认下载的是最高清晰度的视频。

按课程专辑 URL 下载
---------------
您可以传入课程专辑的 URL 作为下载参数：

    .\Download-Imooc.ps1 http://www.imooc.com/learn/197

按课程专辑 ID 下载
------------------
可以一口气传入多个课程专辑的 ID 作为参数：

    .\Download-Imooc.ps1 75,197

自动续传
--------
如果不传任何参数的话，将在当前文件夹中搜索已下载的课程，并自动续传。

    .\Download-Imooc.ps1

自动合并视频
------------
如果希望自动合并所有视频，请使用 `-Combine` 参数。该参数可以和其它参数同时使用。

    .\Download-Imooc.ps1 -Combine

关于
----
代码中用到了参数分组、`-WhatIf` 处理等技术，供参考。

以下是源代码：
<!--more-->

    # Require PowerShell 3.0 or higher.

    [CmdletBinding(DefaultParameterSetName='URI', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    Param
    (
        [Parameter(ParameterSetName='URI',Position = 0)]
        [string]
        $Uri, # 'http://www.imooc.com/learn/197'

        [Parameter(ParameterSetName='ID', Position = 0)]
        [int[]]
        $ID, # @(75, 197)

        [Switch]
        $Combine, # = $true

        [Switch]
        $RemoveOriginal
    )

    # $DebugPreference = 'Continue' # Continue, SilentlyContinue
    # $WhatIfPreference = $true # $true, $false

    # 修正文件名，将文件系统不支持的字符替换成“.”
    function Fix-FileName {
        Param (
            $FileName
        )

        [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object {
            $FileName = $FileName.Replace($_, '.')
        }

        return $FileName
    }

    # 修正目录名，将文件系统不支持的字符替换成“.”
    function Fix-FolderName {
        Param (
            $FolderName
        )

        [System.IO.Path]::GetInvalidPathChars() | ForEach-Object {
            $FolderName = $FolderName.Replace($_, '.')
        }

        return $FolderName
    }

    # 从专辑页面中分析标题和视频页面的 ID。
    function Get-ID {
        Param (
            $Uri
        )
        
        $Uri = $Uri.Replace('/view/', '/learn/')
        $Uri = $Uri.Replace('/qa/', '/learn/')
        $Uri = $Uri.Replace('/note/', '/learn/')
        $Uri = $Uri.Replace('/wiki/', '/learn/')
        $response = Invoke-WebRequest $Uri
        $title = $response.ParsedHtml.title

        echo $title
        $links = $response.Links
        $links | ForEach-Object {
            if ($_.href -cmatch '(?m)^/video/(\d+)$') {
                return [PSCustomObject][Ordered]@{
                    Title = $_.InnerText;
                    ID = $Matches[1]
                }
            }
        }
    }

    # 获取视频下载地址。
    function Get-VideoUri {
        Param (
            [Parameter(ValueFromPipeline=$true)]
            $ID
        )

        $template = 'http://www.imooc.com/course/ajaxmediainfo/?mid={0}&mode=flash'
        $uri = $template -f $ID
        Write-Debug $uri
        $result = Invoke-RestMethod $uri
        if ($result.result -ne 0) {
            Write-Warning $result.result
        }

        $uri = $result.data.result.mpath.'0'

        # 取最高清晰度的版本。
        $uri = $uri.Replace('L.flv', 'H.flv').Replace('M.flv', 'H.flv')
        return $uri
    }

    # 创建“.url”快捷方式。
    function New-ShortCut {
        Param (
            $Title,
            $Uri
        )

        $shell = New-Object -ComObject 'wscript.shell'
        $dir = pwd
        $path = Join-Path $dir "$Title\$Title.url"
        $lnk = $shell.CreateShortcut($path)
        $lnk.TargetPath = $Uri
        $lnk.Save()
    }

    function Assert-PSVersion {
        if (($PSVersionTable.PSCompatibleVersions | Where-Object Major -ge 3).Count -eq 0) {
            Write-Error '请安装 PowerShell 3.0 以上的版本。'
            exit
        }
    }

    function Get-ExistingCourses {
        Get-ChildItem -Directory | ForEach-Object {
            $folder = $_
            $expectedFilePath = (Join-Path $folder $folder.Name) + '.url'
            if (Test-Path -PathType Leaf $expectedFilePath) {
                $shell = New-Object -ComObject 'wscript.shell'
                $lnk = $shell.CreateShortcut($expectedFilePath)
                $targetPath = $lnk.TargetPath
                if ($targetPath -cmatch '(?m)\A^http://www\.imooc\.com/\w+/\d+$\z') {
                    echo $targetPath
                }
            }
        }
    }

    # 下载课程。
    function Download-Course {
        Param (
            [string]$Uri
        )

        Write-Progress -Activity '下载视频' -Status '分析视频 ID'
        $title, $ids = Get-ID -Uri $Uri
        Write-Output "课程名称：$title"
        Write-Debug $title
        $folderName = Fix-FolderName $title
        Write-Debug $folderName
        if (-not (Test-Path $folderName)) { $null = mkdir $folderName }
        New-ShortCut -Title $title -Uri $Uri

        $outputPathes = New-Object System.Collections.ArrayList
        $actualDownloadAny = $false
        #$ids = $ids | Select-Object -First 3
        $ids | ForEach-Object {
            if ($_.Title -cnotmatch '(?m)^\d') {
                return
            }
        
            $title = $_.Title
            Write-Progress -Activity '下载视频' -Status '获取视频地址'
            $videoUrl = Get-VideoUri $_.ID
            $extension = ($videoUrl -split '\.')[-1]

            $title = Fix-FileName $title
            $outputPath = "$folderName\$title.$extension"
            $null = $outputPathes.Add($outputPath)
            Write-Output $title
            Write-Debug $videoUrl
            Write-Debug $outputPath

            if (Test-Path $outputPath) {
                Write-Debug "目标文件 $outputPath 已存在，自动跳过"
            } else {
                Write-Progress -Activity '下载视频' -Status "下载《$title》视频文件"
                if ($PSCmdlet.ShouldProcess("$videoUrl", 'Invoke-WebRequest')) {
                    Invoke-WebRequest -Uri $videoUrl -OutFile $outputPath
                    $actualDownloadAny = $true
                }
            }
        }

        $targetFile = "$folderName\$folderName.flv"
        #if ($Combine -and ($actualDownloadAny -or -not (Test-Path $targetFile))) {
        if ($Combine) {
            # -and ($actualDownloadAny -or -not (Test-Path $targetFile))) {
            if ($actualDownloadAny -or -not (Test-Path $targetFile) -or (Test-Path $targetFile) -and $PSCmdlet.ShouldProcess('分段视频', '合并')) {
                Write-Progress -Activity '下载视频' -Status '合并视频'    
                Write-Output ("合并视频（共 {0:N0} 个）" -f $outputPathes.Count)
                $outputPathes.Insert(0, $targetFile)
            
                $eap = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"
                .\FlvBind.exe $outputPathes.ToArray()
                $ErrorActionPreference = $eap

                <#
                $outputPathes = $outputPathes | ForEach-Object {
                    "`"$_`""
                }
                Start-Process `
                    -WorkingDirectory (pwd) `
                    -FilePath .\FlvBind.exe `
                    -ArgumentList $outputPathes `
                    -NoNewWindow `
                    -Wait `
                    -ErrorAction SilentlyContinue `
                    -WindowStyle Hidden
                #>
                if ($?) {
                    Write-Output '视频合并成功'
                    if ($RemoveOriginal -and $PSCmdlet.ShouldProcess('分段视频', '删除')) {
                        $outputPathes.RemoveAt(0)
                        $outputPathes | ForEach-Object {
                            Remove-Item $_
                        }
                        Write-Output '原始视频删除完毕'
                    }
                } else {
                    Write-Warning '视频合并失败'
                }
            }
        }
    }

    Assert-PSVersion

    # 判断参数集
    $chosen= $PSCmdlet.ParameterSetName
    if ($chosen -eq 'URI') {
        if ($Uri) {
            Download-Course $Uri
        } else {
            Get-ExistingCourses | ForEach-Object {
                Download-Course $_
            }
        }
    }
    if ($chosen -eq 'ID') {
        $template = 'http://www.imooc.com/learn/{0}'
        $ID | ForEach-Object {
            $Uri = $template -f $_
            Download-Course $Uri
        }
    }

您也可以从这里[下载](https://raw.githubusercontent.com/victorwoo/Download-Imooc/master/Download-Imooc.ps1)完整的代码。

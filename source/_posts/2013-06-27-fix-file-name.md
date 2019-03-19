---
layout: post
title: "修正文件名/目录名的PowerShell脚本"
date: 2013-06-27 00:00:00
categories: powershell
tags:
- powershell
- script
- geek
---
计划写一系列整理文件用的脚本。例如根据id3来对mp3文件归档、根据exif信息来对照片归档、根据verycd上的资源名称对下载的文件归档……
这时候会遇到一个问题：Windows的文件系统是不允许某些特殊字符，以及设备文件名的。详细的限制请参见：http://zh.wikipedia.org/wiki/%E6%AA%94%E6%A1%88%E5%90%8D%E7%A8%B1。

这个PowerShell脚本帮助你避开这些坑。具体的做法是将特殊字符替换成'.'，对于恰好是设备名称的主文件名或扩展名之前添加'_'。

	function Get-ValidFileSystemName
	{
		[CmdletBinding()]
		param(
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			[string]$FileSystemName
		)

		process{
			$deviceFiles = 'CON', 'PRN', 'AUX', 'CLOCK$', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
			$fileName = [System.IO.Path]::GetFileNameWithoutExtension($FileSystemName)
			$extension = [System.IO.Path]::GetExtension($FileSystemName)
			if ($extension.StartsWith('.'))
			{
				$extension = $extension.Substring(1)
			}

			if ($deviceFiles -contains $fileName)
			{
				$fileName = "_$fileName"
			}

			if ($deviceFiles -contains $extension)
			{
				$extension = "_$extension"
			}

			if ($extension -eq '')
			{
				$FileSystemName = "$fileName$extension"
			}
			else
			{
				$FileSystemName = "$fileName.$extension"
			}

			$FileSystemName = $FileSystemName -creplace '[\\/|?"*:<>\x00\x1F\t\r\n]', '.'
			return $FileSystemName
		}
	}

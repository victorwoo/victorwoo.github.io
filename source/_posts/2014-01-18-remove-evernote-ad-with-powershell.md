layout: post
title: "用 PowerShell 移除 Evernote 的广告"
date: 2014-01-18 00:00:00
description: Remove Evernote AD with PowerShell
categories: powershell
tags:
- powershell
- geek
---
破解过程
--------
Evernote（印象笔记）免费用户的左下角有个正方形的广告，点击关闭按钮反而会出来一个对话框：
![](/img/2014-01-18-remove-evernote-ad-with-powershell-001.png)

虽然破解 + 写脚本 + 写这篇博客花了一两个小时，但是如果能节约更多读者的时间，并且提高一点技术水平，也算有益了吧。

我们用 Visual Studio 中的 Spy++ 查看一下控件的窗口类名：
![](/img/2014-01-18-remove-evernote-ad-with-powershell-002.png)

得到的结果是“ENAdBrowserCtrl”，从窗口类名来看，似乎是为了广告而设计的。出于保险起见，用 WinHex 搜索了一下，这个字符串只出现一次，并且是采用双字节编码的“45004E0041006400420072006F0077007300650072004300740072006C”。

我们尝试破坏这个字符串试试：用 WinHex 的“填充选块”功能，将这块区域替换成 00，然后保存运行，广告果然没有了。

但是手工修改毕竟比较麻烦，而且未来版本更新以后还要再次破解。所以简单写了个 PowerShell 脚本来自动完成破解。

PowerShell 自动化脚本
---------------------
请将以下代码保存成 `Remove-EvernoteAD.ps1` 并以管理员身份执行 :)
脚本的思路是以二进制的方式搜索指定的模式（pattern），并替换成新的模式。涉及到一些字节操作和进制转换。

	$pattern = '45004E0041006400420072006F0077007300650072004300740072006C'
	$replacement = $pattern -replace '.', '0'
	
	function Replace-Pattern ($buffer, $pattern, $replacement) {
	    $isPatternMatched = $false
	    for ($offset = 6220000; $offset -lt $buffer.Length - $pattern.Length; $offset++) {
	        $isByteMatched = $true
	        for ($patternOffset = 0; $patternOffset -lt $pattern.Length; $patternOffset++) {
	            if ($buffer[$offset + $patternOffset] -ne $pattern[$patternOffset]) {
	                $isByteMatched = $false
	                break
	            }
	        }
	        if ($isByteMatched) {
	            $isPatternMatched = $true
	            break
	        }
	    }
	
	    if ($isPatternMatched) {
	        for ($index = 0; $index -lt $pattern.Length; $index++) {
	            $buffer[$offset + $index] = [byte]0
	        }
	
	        return $true
	    } else {
	        return $false
	    }
	}
	
	function Convert-HexStringToByteArray
	{
	    ################################################################
	    #.Synopsis
	    # Convert a string of hex data into a System.Byte[] array. An
	    # array is always returned, even if it contains only one byte.
	    #.Parameter String
	    # A string containing hex data in any of a variety of formats,
	    # including strings like the following, with or without extra
	    # tabs, spaces, quotes or other non-hex characters:
	    # 0x41,0x42,0x43,0x44
	    # x41x42x43x44
	    # 41-42-43-44
	    # 41424344
	    # The string can be piped into the function too.
	    ################################################################
	    [CmdletBinding()]
	    Param ( [Parameter(Mandatory = $True, ValueFromPipeline = $True)] [String] $String )
	 
	    #Clean out whitespaces and any other non-hex crud.
	    $String = $String.ToLower() -replace '[^a-f0-9\\\,x\-\:]',''
	 
	    #Try to put into canonical colon-delimited format.
	    $String = $String -replace '0x|\\x|\-|,',':'
	 
	    #Remove beginning and ending colons, and other detritus.
	    $String = $String -replace '^:+|:+$|x|\\',''
	 
	    #Maybe there's nothing left over to convert...
	    if ($String.Length -eq 0) { ,@() ; return }
	 
	    #Split string with or without colon delimiters.
	    if ($String.Length -eq 1)
	    { ,@([System.Convert]::ToByte($String,16)) }
	    elseif (($String.Length % 2 -eq 0) -and ($String.IndexOf(":") -eq -1))
	    { ,@($String -split '([a-f0-9]{2})' | foreach-object { if ($_) {[System.Convert]::ToByte($_,16)}}) }
	    elseif ($String.IndexOf(":") -ne -1)
	    { ,@($String -split ':+' | foreach-object {[System.Convert]::ToByte($_,16)}) }
	    else
	    { ,@() }
	    #The strange ",@(...)" syntax is needed to force the output into an
	    #array even if there is only one element in the output (or none).
	}
	
	echo '本程序用于去除 Evernote 非会员左下角的正方形广告。'
	echo '请稍候……'
	
	$patternArray = Convert-HexStringToByteArray $pattern
	$replacementArray = Convert-HexStringToByteArray $replacement
	
	
	$path = "${Env:ProgramFiles}\Evernote\Evernote\Evernote.exe"
	$path86 = "${Env:ProgramFiles(x86)}\Evernote\Evernote\Evernote.exe"
	if (Test-Path $path) {
	    $execute = Get-Item $path
	} elseif (Test-Path $path86) {
	    $execute = Get-Item $path86
	} else {
	    Write-Warning '没有找到 Evernote.exe。'
	    exit
	}
	
	$exe = gc $execute -ReadCount 0 -Encoding byte
	
	if (Replace-Pattern $exe $patternArray $replacementArray) {
	    $newFileName = $execute.Name + '.bak'
	    $newPath = Join-Path $execute.DirectoryName $newFileName
	    Stop-Process -Name Evernote -ErrorAction SilentlyContinue
	    Move-Item $execute $newPath
	    Set-Content $execute -Value $exe -Encoding Byte
	    echo '广告去除成功！Evernote 未来升级后需重新运行本程序。'
	    Start-Process $execute
	} else {
	    Write-Warning '无法去除广告，是否已经去除过了？'
	    if (!(Get-Process -Name Evernote -ErrorAction SilentlyContinue)) {
	        Start-Process $execute
	    }
	}

您也可以从这里 [下载](/assets/download/Remove-EvernoteAD.ps1) 写好的脚本。

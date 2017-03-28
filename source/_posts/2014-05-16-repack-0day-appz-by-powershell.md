layout: post
title: "用 PowerShell 重新打包 0day appz"
date: 2014-05-16 00:00:00
description: Repack 0day appz by PowerShell
categories: powershell
tags:
- powershell
- script
- batch
- 0day
- appz
- repack
---
从 0day 服务器下载下来的 appz 文件夹是这样的形态： 

![](/img/2014-05-16-repack-0day-appz-by-powershell-001.png)

每个文件夹代表一个 appz 软件，打开是这个样子的：

![](/img/2014-05-16-repack-0day-appz-by-powershell-002.png)

里面是一系列 .zip 文件以及说明文件。这些 .zip 文件却**不是**使用 zip 的分卷压缩出来的，它们的内容如下：

![](/img/2014-05-16-repack-0day-appz-by-powershell-003.png)

![](/img/2014-05-16-repack-0day-appz-by-powershell-004.png)

要把这些 .zip 文件全部解压到同一个目录下，才可以得到一系列 rar 的分卷压缩文件。我们打开一个 .rar 文件，这才看到真正的内容：

![](/img/2014-05-16-repack-0day-appz-by-powershell-005.png)

软件数量大的时候，人工重复进行上述操作就不合适了。机械的劳动应该交给程序。我们可以设计一个 PowerShell 脚本，完成一系列功能：

- 遍历 0day appz 的下载目录。
- 解压所有 .zip 文件。
- 解压 .rar 文件。
- 将说明文件复制到一起。
- 将最终的文件重打包为 .zip 文件。
- 如果上述的解压有问题，则不打包，并输出错误日志。
- 清理临时文件。
- 清理成功的原始文件夹，保留失败的原始文件夹。

按照这个需求，我们可以编写如下 PowerShell 脚本：

	$DebugPreference = 'Continue'
	
	$incoming = 'd:\0day\incoming'
	$temp1 = 'd:\0day\temp1'
	$temp2 = 'd:\0day\temp2'
	$output = 'd:\0day\output'
	
	if (Test-Path $temp1) { del $temp1 -r }
	if (Test-Path $temp2) { del $temp2 -r }
	
	$apps = dir $incoming -Directory
	$count = 0
	$hasFailed = $false
	$apps | foreach {
	    $name = $_.Name
	    Write-Progress -Activity 'Repacking apps' -PercentComplete ($count / $apps.Length * 100) -CurrentOperation $name
	    echo "Repacking $name"
	
	    md $temp1 | Out-Null
	    md $temp2 | Out-Null
	
	    # d:\0day\util\7z x -o"d:\0day\temp1" "d:\0day\incoming\VanDyke.SecureCRT.v7.2.2.491.Incl.Patch.And.Keymaker-ZWT\*.zip"
	    $arguments = 'x', "-o""$temp1""", '-y', (Join-Path $_.FullName *.zip)
	    .\7z $arguments | Out-Null
	
	    if (!$?) {
	        Write-Warning "Repacking $name failed."
	        echo "$name" >> "$output\fail.log"
	
	        del $temp1 -r
	        del $temp2 -r
	
	        $count++
	        $hasFailed = $true
	        return
	    }
	
	    # d:\0day\util\7z x -o"d:\0day\temp2" "d:\0day\temp1\*.rar" -y
	    $arguments = 'x', "-o""$temp2""", '-y', "$temp1\*.rar"
	    .\7z $arguments | Out-Null
	    if (!$?) {
	        Write-Warning "Repacking $name failed."
	        echo "$name" >> "$output\fail.log"
	
	        del $temp1 -r
	        del $temp2 -r
	
	        $count++
	        $hasFailed = $true
	        return
	    }
	
	    # copy d:\0day\temp1\*.diz d:\0day\temp2
	    # copy d:\0day\temp1\*.nfo d:\0day\temp2
	
	    dir $temp1 | where {
	        $_.Extension -notmatch 'rar|r\d*'
	    } | copy -Destination $temp2
	
	    #d:\0day\util\7z a "d:\0day\output\VanDyke.SecureCRT.v7.2.2.491.Incl.Patch.And.Keymaker-ZWT.zip" "d:\0day\temp2\*.*" -r
	    $arguments = 'a', "$output\$name.zip", "$temp2\*.*", '-r'
	    .\7z $arguments | Out-Null
	    if (!$?) {
	        Write-Warning "Repacking $name failed."
	        echo "$name" >> "$output\fail.log"
	
	        del $temp1 -r
	        del $temp2 -r
	
	        $count++
	        $hasFailed = $true
	        return
	    }
	
	    del $temp1 -r
	    del $temp2 -r
	
	    Remove-Item -LiteralPath $_.FullName -r
	
	    $count++
	}
	
	if ($hasFailed) {
	    echo '' >> "$output\fail.log"
	}
	
	echo 'Press any key to continue...'
	[Console]::ReadKey() | Out-Null
	
	# del 'd:\0day\output\*.*' -r

您也可以在这里[下载](/assets/download/0day.zip)写好的脚本，包括完整的目录结构和 7z 软件包。请解压到 d:\ 中使用，或者自行调整脚本头部的路径。

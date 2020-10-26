---
layout: post
date: 2020-10-19 00:00:00
title: "PowerShell 技能连载 - 将文件路径转为 8.3 格式（第 2 部分）"
description: PowerTip of the Day - Converting File Paths to 8.3 (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一篇文章中，我们解释了如何使用旧的 COM 组件将默认的长路径名转换为短的 8.3 路径名。虽然可以偶尔进行转换，但使用 COM 组件的速度很慢且占用大量资源。

一种“清洁”的方法是直接使用 Windows API 调用。您可以通过以下方法访问将长文件路径转换为短文件路径的内部方法：

```powershell
# this is the long path to convert
$path = "C:\Program Files\PowerShell\7\pwsh.exe"


# signature of internal API call
$signature = '[DllImport("kernel32.dll", SetLastError=true)]
public static extern int GetShortPathName(String pathName, StringBuilder shortName, int cbShortName);'
# turn signature into .NET type
$type = Add-Type -MemberDefinition $signature -Namespace Tools -Name Path -UsingNamespace System.Text

# create empty string builder with 300-character capacity
$sb = [System.Text.StringBuilder]::new(300)
# ask Windows to convert long path to short path with a max of 300 characters
$rv = [Tools.Path]::GetShortPathName($path, $sb, 300)

# output result
if ($rv -ne 0)
{
    $shortPath = $sb.ToString()
}
else
{
    $shortPath = $null
    Write-Warning "Shoot. Could not convert $path"
}


"Short path: $shortPath"
```

<!--本文国际来源：[Converting File Paths to 8.3 (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-file-paths-to-8-3-part-2)-->


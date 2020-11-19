---
layout: post
date: 2020-10-27 00:00:00
title: "PowerShell 技能连载 - 以可点击图标的方式部署 PowerShell（第 1 部分）"
description: PowerTip of the Day - Deploy PowerShell as Clickable Icons (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可以使用 .lnk 文件将小型 PowerShell 解决方案部署到最终用户。以下是实现方法：

使用以下代码，然后将 `$code` 中的有效负载代码替换为您希望点击图标时执行的任意 PowerShell 代码。只要确保代码总数少于 4096 个字符即可。然后运行脚本。

```powershell
$code = {
    # place your code here (must be less than 4096 characters)
    # (this example generates a battery report on notebooks
    #  and opens it in your default browser)
    $r = "$env:temp\report.html"
    powercfg /batteryreport /duration 14 /output $r
    Invoke-Item -Path $r
    Start-Sleep -Seconds 2
    Remove-Item -Path $r
}

# turn code into a one-liner, remove comments, escape double-quotes
# NOTE: this is a very simplistic conversion. Does not support block comments
#  or quoted double quotes or any edgy stuff
#  USE with simple staight-forward code only
$oneliner = $code.ToString().Trim().Replace('"','\"').
                Replace([Char[]]10,'').Split([Char[]]13).
                Trim().Where{!$_.StartsWith('#')} -join ';'

# create path to a link file. It is always placed on your desktop
# and named "clickme.lnk"
$desktop = [Environment]::GetFolderPath('Desktop')
$linkpath = Join-Path -Path $desktop -ChildPath 'ClickMe.lnk'

# create a shortcut file
$com = New-Object -ComObject WScript.Shell
$shortcut = $com.CreateShortcut($linkpath)
# minimize window so PowerShell won't pop up
$shortcut.WindowStyle = 7
# use a different icon. Adjust icon index if you want
$shortcut.IconLocation = 'shell32.dll,8'
# run PowerShell
$shortcut.TargetPath = "powershell.exe"
# submit code as an argument
$shortcut.Arguments = "-noprofile $oneliner"

# save and create the shortcut file
$shortcut.Save()
```

结果是在桌面上出现一个名为 "clickme" 的图标。当双击该图标时，将运行嵌入的 PowerShell 代码。如果您没有在上面的示例中更改有效负载脚本，它将生成电池报告并将其显示在默认浏览器中。

由于有效载荷代码已嵌入图标文件中，因此您可以方便地将其地传递给其他人或进行部署。

在 $code 中调整嵌入式有效负载脚本时，需要考虑以下几点：

1. 代码必须少于 4096 个字符
2. 不要使用块注释，或最好删除所有注释行（以减小有效负载大小）
3. 不要使用带引号的双引号，因为必须将双引号转义，而脚本不是很智能。它只是转义找到的所有双引号。

<!--本文国际来源：[Deploy PowerShell as Clickable Icons (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deploy-powershell-as-clickable-icons-part-1)-->


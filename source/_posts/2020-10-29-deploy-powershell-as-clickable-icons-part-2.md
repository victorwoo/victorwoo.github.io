---
layout: post
date: 2020-10-29 00:00:00
title: "PowerShell 技能连载 - 以可点击图标的方式部署 PowerShell（第 2 部分）"
description: PowerTip of the Day - Deploy PowerShell as Clickable Icons (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们说明了如何在Windows资源管理器快捷方式文件中嵌入多达 4096 个字符的PowerShell代码并生成可单击的PowerShell代码。

只需右键单击链接文件并打开属性对话框，即可轻松查看嵌入的 PowerShell 代码。

通过非常简单的调整，您就可以隐藏有效的负载代码。运行以下代码以在桌面上生成示例可单击的 PowerShell 图标：

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

# turn code into a one-liner, remove comments, escape double quotes
# NOTE: this is a very simplistic conversion. Does not support block comments
#  or quoted double quotes or any edgy stuff
#  USE with simple staight-forward code only
$oneliner = $code.ToString().Trim().Replace('"','\"').Replace([Char[]]10,'').
                Split([Char[]]13).Trim().Where{!$_.StartsWith('#')} -join ';'

# create path to a link file. It is always placed on your desktop
# and named "clickme.lnk"
$desktop = [Environment]::GetFolderPath('Desktop')
$linkpath = Join-Path -Path $desktop -ChildPath 'ClickMe.lnk'

# create a blank string of 260 chars
$blanker = " " * 260

# create a shortcut file
$com = New-Object -ComObject WScript.Shell
$shortcut = $com.CreateShortcut($linkpath)
# minimize window so PowerShell won't pop up
$shortcut.WindowStyle = 7
# use a different icon. Adjust icon index if you want
$shortcut.IconLocation = 'shell32.dll,8'
# run PowerShell
$shortcut.TargetPath = "powershell.exe"
# submit code as an argument and prepend with a blank string
# so payload is hidden in the properties dialog
$shortcut.Arguments = "$blanker-noprofile $oneliner"

# save and create the shortcut file
$shortcut.Save()
```

当您双击桌面上的 "clickme" 图标时，嵌入的负载代码将运行并创建电池报告，然后将其显示在默认浏览器中。

右键单击图标并选择“属性”时，将不会显示嵌入式 PowerShell 代码。该对话框仅显示powershell.exe的路径，但不显示任何参数。

这是通过在参数前面加上 260 个空白字符来实现的。快捷方式文件最多支持 4096 个字符的命令行，而 Windows 资源管理器及其对话框仅显示前 260 个字符。要查看嵌入式有效负载，用户必须使用上面的 PowerShell 代码以编程方式读取快捷方式文件并转储 arguments 属性。

<!--本文国际来源：[Deploy PowerShell as Clickable Icons (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deploy-powershell-as-clickable-icons-part-2)-->


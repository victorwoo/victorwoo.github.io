---
layout: post
date: 2018-12-19 00:00:00
title: "PowerShell 技能连载 - 在打印机上打印测试页"
description: PowerTip of the Day - Printing Test Pages on Printers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
感谢 `PrintManagement` 模块为 Windows 10 和 Windows Server 2016 提供了大量的打印功能支持。如果希望打印官方的测试页，您还需要动用 WMI。

```powershell
#requires -Version 3.0 -Modules CimCmdlets, PrintManagement

Get-Printer |
    Out-GridView -Title 'Print test page on selected printers' -OutputMode Multiple |
    ForEach-Object {
        $printerName = $_.Name
        $result = Get-CimInstance Win32_Printer -Filter "name LIKE '$printerName'" |
            Invoke-CimMethod -MethodName printtestpage
        if ($result.ReturnValue -eq 0)
        {
            "Test page printed on $printerName."
        }
        else
        {
            "Unable to print test page on $printerName."
            "Error code $($result.ReturnValue)."
        }
    }
```

当这段代码运行时，将弹出一个对话框显示所有的打印机。请选择一个（或按住 `CTRL` 选择多个），将在选中的打印机上打印测试页。

<!--本文国际来源：[Printing Test Pages on Printers](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/printing-test-pages-on-printers)-->

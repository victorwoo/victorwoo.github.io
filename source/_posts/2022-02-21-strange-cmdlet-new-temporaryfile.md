---
layout: post
date: 2022-02-21 00:00:00
title: "PowerShell 技能连载 - 奇怪的 Cmdlet：New-TemporaryFile"
description: 'PowerTip of the Day - Strange Cmdlet: New-TemporaryFile'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个 PowerShell（和 Windows PowerShell）中比较隐藏的 cmdlet：`New-TemporaryFile`。看到这样一个相对无用的 cmdlet 成为 PowerShell 的一部分，真是令人惊讶。当你查看它的源代码时，实际上它内部只是调用了一个简单的方法：

```powershell
# load module that defines the function:
PS C:\> New-TemporaryFile -WhatIf
What if: Performing the operation "New-TemporaryFile" on target "C:\Users\tobia\AppData\Local\Temp".

# dump function source code:
PS C:\> ${function:New-TemporaryFile}

    [CmdletBinding(
        HelpURI='https://go.microsoft.com/fwlink/?LinkId=526726',
        SupportsShouldProcess=$true)]
    [OutputType([System.IO.FileInfo])]
    Param()

    Begin
    {
        try
        {
            if($PSCmdlet.ShouldProcess($env:TEMP))
            {
                $tempFilePath = [System.IO.Path]::GetTempFileName()
            }
        }
        catch
        {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($_.Exception,"NewTemporaryFileWriteError", "WriteError", $env:TEMP)
            Write-Error -ErrorRecord $errorRecord
            return
        }

        if($tempFilePath)
        {
            Get-Item $tempFilePath
        }
    }
```

它的核心是这样的：

```powershell
PS> [System.IO.Path]::GetTempFileName()
C:\Users\tobia\AppData\Local\Temp\tmp671.tmp
```

```GetTempFileName()``` 方法具有误导性，因为它实际上在您每次调用它时都会创建一个新的临时文件。`New-TemporaryFile` 返回的是临时文件对象，而不是字符串路径，这更好地说明了上面的问题。它的本质上是这样的：

```powershell
PS C:\> Get-Item ([System.IO.Path]::GetTempFileName())


    Directory: C:\Users\tobia\AppData\Local\Temp


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        26.01.2022     12:48              0 tmpC6DF.tmp
```

<!--本文国际来源：[Strange Cmdlet: New-TemporaryFile](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/strange-cmdlet-new-temporaryfile)-->


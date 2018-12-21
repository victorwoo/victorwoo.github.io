---
layout: post
date: 2018-12-18 00:00:00
title: "PowerShell 技能连载 - 正确使用 FileSystemWatcher（第 2 部分）"
description: PowerTip of the Day - Using FileSystemWatcher Correctly (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
在前一个技能中我们介绍了 `FileSystemWatcher` 并演示了当事件处理代码执行事件过长时会丢失文件系统改变事件。

要正确地使用 `FileSystemWatcher`，您需要异步地使用它并使用队列。这样即便脚本正忙于处理文件系统变更，也能够继续记录新的文件系统变更，并在一旦 PowerShell 处理完之前的变更时处理新的变更。

```powershell
# make sure you adjust this to point to the folder you want to monitor
$PathToMonitor = "c:\test"

explorer $PathToMonitor

$FileSystemWatcher = New-Object System.IO.FileSystemWatcher
$FileSystemWatcher.Path  = $PathToMonitor
$FileSystemWatcher.IncludeSubdirectories = $true

# make sure the watcher emits events
$FileSystemWatcher.EnableRaisingEvents = $true

# define the code that should execute when a file change is detected
$Action = {
    $details = $event.SourceEventArgs
    $Name = $details.Name
    $FullPath = $details.FullPath
    $OldFullPath = $details.OldFullPath
    $OldName = $details.OldName
    $ChangeType = $details.ChangeType
    $Timestamp = $event.TimeGenerated
    $text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp
    Write-Host ""
    Write-Host $text -ForegroundColor Green
    
    # you can also execute code based on change type here
    switch ($ChangeType)
    {
        'Changed' { "CHANGE" }
        'Created' { "CREATED"}
        'Deleted' { "DELETED"
            # uncomment the below to mimick a time intensive handler
            <#
            Write-Host "Deletion Handler Start" -ForegroundColor Gray
            Start-Sleep -Seconds 4    
            Write-Host "Deletion Handler End" -ForegroundColor Gray
            #>
        }
        'Renamed' { 
            # this executes only when a file was renamed
            $text = "File {0} was renamed to {1}" -f $OldName, $Name
            Write-Host $text -ForegroundColor Yellow
        }
        default { Write-Host $_ -ForegroundColor Red -BackgroundColor White }
    }
}

# add event handlers
$handlers = . {
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Changed -Action $Action -SourceIdentifier FSChange
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Created -Action $Action -SourceIdentifier FSCreate
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Deleted -Action $Action -SourceIdentifier FSDelete
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Renamed -Action $Action -SourceIdentifier FSRename
}

Write-Host "Watching for changes to $PathToMonitor"

try
{
    do
    {
        Wait-Event -Timeout 1
        Write-Host "." -NoNewline
        
    } while ($true)
}
finally
{
    # this gets executed when user presses CTRL+C
    # remove the event handlers
    Unregister-Event -SourceIdentifier FSChange
    Unregister-Event -SourceIdentifier FSCreate
    Unregister-Event -SourceIdentifier FSDelete
    Unregister-Event -SourceIdentifier FSRename
    # remove background jobs
    $handlers | Remove-Job
    # remove filesystemwatcher
    $FileSystemWatcher.EnableRaisingEvents = $false
    $FileSystemWatcher.Dispose()
    "Event Handler disabled."
}
```

当您运行这段代码时，将监控 `$PathToMonitor` 中定义的文件夹的改变，并且当变更发生时，会触发一条消息。当您按下 `CTRL`+`C` 时，脚本停止执行，并且所有事件处理器将在 finally 代码块中清理。

更重要的是：这段代码内部使用队列，所以当短时间内有大量修改发生时，它们将会等到 PowerShell 不忙碌的时候立即执行。您可以取消代码中的注释来演唱处理时间。现在，当一个文件删除后，处理器需要 4 秒钟的额外处理时间。

即便删除了大量文件，它们最终仍将显示出来。这里展示的方式比起前一个技能中基于 `WaitForChanged()` 的同步处理器更可靠。

<!--more-->
本文国际来源：[Using FileSystemWatcher Correctly (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-filesystemwatcher-correctly-part-2)

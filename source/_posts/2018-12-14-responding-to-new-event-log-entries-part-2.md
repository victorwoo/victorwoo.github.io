---
layout: post
date: 2018-12-14 00:00:00
title: "PowerShell 技能连载 - 响应新的事件日志条目（第 2 部分）"
description: PowerTip of the Day - Responding to New Event Log Entries (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是另一个文件系统任务，听起来复杂，实际并没有那么复杂。假设您需要移除一个文件夹结构中指定层次之下的所有文件夹。以下是实现方法：

```powershell
# set the event log name you want to subscribe to
# (use Get-EventLog -AsString for a list of available event log names)
$Name = 'Application'

# get an instance
$Log = [System.Diagnostics.EventLog]$Name

# determine what to do when an event occurs
$Action = {
    # get the original event entry that triggered the event
    $entry = $event.SourceEventArgs.Entry

    # log all events
    Write-Host "Received from $($entry.Source): $($entry.Message)"

    # do something based on a specific event
    if ($entry.EventId -eq 1 -and $entry.Source -eq 'WinLogon')
    {
        Write-Host "Test event was received!" -ForegroundColor Red
    }

}

# subscribe to its "EntryWritten" event
$job = Register-ObjectEvent -InputObject $log -EventName EntryWritten -SourceIdentifier 'NewEventHandler' -Action $Action

# now whenever an event is written to the log, $Action is executed
# use a loop to keep PowerShell busy. You can abort via CTRL+C

Write-Host "Listening to events" -NoNewline

try
{
    do
    {
        Wait-Event -SourceIdentifier NewEventHandler -Timeout 1
        Write-Host "." -NoNewline

    } while ($true)
}
finally
{
    # this executes when CTRL+C is pressed
    Unregister-Event -SourceIdentifier NewEventHandler
    Remove-Job -Name NewEventHandler
    Write-Host ""
    Write-Host "Event handler stopped."
}
```

由于事件处理器是活跃的，PowerShell 每秒输出一个“点”，表示它仍在监听。现在打开另一个 PowerShell 窗口，并且运行以下代码：

```powershell
Write-EventLog -LogName Application -Source WinLogon -EntryType Information -Message test -EventId 1
```

当写入一个新的应用程序事件日志条目时，事件处理器显示事件的详情。如果事件的 `EventID` 等于 1 并且事件源为 "`WinLogon`"，例如我们的测试事件条目，那么将会输出一条红色的信息。

要停止事件监听器，请按 `CTRL`+`C`。代码将自动清理并从内存中移除事件监听器。

这都是通过 `Wait-Event` 实现的：这个 cmdlet 可以等待特定的事件发生。并且当它等待时，PowerShell 可以继续执行事件处理器。当您指定一个超时（以秒为单位），该 cmdlet 将控制权返回给脚本。在我们的栗子中，控制权每秒钟都会返回，使脚本有机会以点的方式输出进度指示器。

如果用户按下 `CTRL`+`C`，该脚本并不会立即停止。相反，它会先执行 `finally` 语句块并确保该事件处理器已清除和移除。

<!--本文国际来源：[Responding to New Event Log Entries (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/responding-to-new-event-log-entries-part-2)-->

---
layout: post
date: 2018-12-13 00:00:00
title: "PowerShell 技能连载 - 响应新的事件日志条目（第 1 部分）"
description: PowerTip of the Day - Responding to New Event Log Entries (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望实时处理新的事件日志条目，以下是当新的事件条目写入时，PowerShell 代码能自动收到通知的方法：

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

    # do something based on the event
    if ($entry.EventId -eq 1 -and $entry.Source -eq 'WinLogon') 
    {
        Write-Host "Test event was received!"
    }

}

# subscribe to its "EntryWritten" event
$job = Register-ObjectEvent -InputObject $log -EventName EntryWritten -SourceIdentifier 'NewEventHandler' -Action $Action
```

这段代码片段安装了一个后台的事件监听器，每当事件日志产生一个 "EntryWritten" 事件时会触发。当发生该事件时，`$Action` 中的代码就会执行。它通过查询 `$event` 变量获取触发该操作的事件。在我们的示例中，当 `EventId` 等于 1，并且事件源是 "`WinLogon`" 时，会写入一条信息。当然，您可以发送一封邮件，写入一条日志，或做任何其它有用的事情。

要查看事件处理器的效果，只需要写一个符合所有要素的测试事件：

```powershell
# write a fake test event to trigger
Write-EventLog -LogName Application -Source WinLogon -EntryType Information -Message test -EventId 1
```

当您运行这段代码时，事件处理器将自动执行并向控制台输出自己的信息。

请注意这个例子将安装一个异步的处理器，并且当 PowerShell 不忙碌的时候会在后台执行，并且在 PowerShell 运行期间都有效。您不能通过 `Start-Sleep` 或一个循环来保持 PowerShell 忙碌（因为 PowerShell 会忙碌而无法在后台处理事件处理器）。要保持这个事件处理器可响应，您可以通过 `-noexit` 参数启动脚本：

```powershell
Powershell.exe -noprofile -noexit -file “c:\yourpath.ps1”
```

要移除事件处理器，请运行以下代码：

```powershell
PS> Unregister-Event -SourceIdentifier NewEventHandler 
PS> Remove-Job -Name NewEventHandler
```

<!--本文国际来源：[Responding to New Event Log Entries (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/responding-to-new-event-log-entries-part-1)-->

---
layout: post
date: 2020-01-15 00:00:00
title: "PowerShell 技能连载 - 杀死无响应的进程"
description: PowerTip of the Day - Killing Non-Responding Processes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
由 `Get-Process` 返回的进程对象可以判断该进程当前是否正在响应窗口消息，从而是否正在响应用户请求。此行代码返回当前的 PowerShell 进程的 "Responding" 属性：

```powershell
PS> Get-Process -Id $Pid | Select-Object *respond*

Responding
----------
      True
```

进程偶尔会变得无响应是很常见的，例如由于高负载和较弱的软件体系结构。当某个进程在较长时间内没有响应时，就会“挂起”，会让用户发疯。

这行代码列出了当前未响应的进程：

```powershell
PS> Get-Process | Where-Object { !$_.Responding }

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    560      28    21752        580       0.38  18544   1 Calculator
    915      65    26660       2528       0.39  14244   1 MicrosoftEdge
    488      21     7108       7988       0.09  13400   1 MicrosoftEdgeCP
    543      27    16148        520       0.31  21200   1 Time
    1132      77    63544        836       1.55  15212   1 WinStore.App
```

请注意，此列表可能包括已启动但不再使用的 Windows 应用程序。由于属性“正在响应”仅描述当前状态，因此它无法确定进程多长时间未响应。

如果您想汇报（或杀死）一段时间未响应的所有进程，则需要自己进行反复检查并跟踪结果。

下面的代码在网格视图窗口中列出了 3 秒钟没有响应的所有进程。然后，用户可以选择一个或多个要杀死的进程（按住 CTRL 键选择多个进程）。

```powershell
# report processes hanging for more than 3 seconds
$timeout = 3

# use a hash table to keep track of processes
$hash = @{}

# use an endless loop and test processes
do
{
  Get-Process |
  # look at processes with a window only
  Where-Object MainWindowTitle |
  ForEach-Object {
    # use process ID as key to the hash table
    $key = $_.id
    # if the process is responding, reset the counter
    if ($_.Responding)
    {
      $hash[$key] = 0
    }
    # else, increment the counter by one
    else
    {
      $hash[$key]++
    }
  }

  # copy the hash table keys so that the collection can be
  # modified
  $keys = @($hash.Keys).Clone()

  # emit all processes hanging for longer than $timeout seconds
  # look at all processes monitored
  $keys |
  # take the ones not responding for the time specified in $timeout
  Where-Object { $hash[$_] -gt $timeout } |
  ForEach-Object {
    # reset the counter (in case you choose not to kill them)
    $hash[$_] = 0
    # emit the process for the process ID on record
    Get-Process -id $_
  } |
  # exclude those that already exited
  Where-Object { $_.HasExited -eq $false } |
  # show properties
  Select-Object -Property Id, Name, StartTime, HasExited |
  # show hanging processes. The process(es) selected by the user will be killed
  Out-GridView -Title "Select apps to kill that are hanging for more than $timeout seconds" -PassThru |
  # kill selected processes
  Stop-Process -Force

  # sleep for a second
  Start-Sleep -Seconds 1

} while ($true)
```

当然，您可以轻松更改代码以生成挂起的进程报表。只需将 `Stop-Process` 替换为您想要执行的任何操作，即可使用 `Add-Content` 将流程写入日志文件。要避免一次次地记录相同的进程，您可能想要添加某种黑名单，以跟踪已经记录的进程。

<!--本文国际来源：[Killing Non-Responding Processes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/killing-non-responding-processes)-->


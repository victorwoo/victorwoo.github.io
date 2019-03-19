---
layout: post
date: 2019-01-07 00:00:00
title: "PowerShell 技能连载 - 删除日期最早的日志文件"
description: PowerTip of the Day - Deleting the Oldest Log File
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您正在将日志活动写入文件，可能需要清除一些东西，例如在增加一个新文件的时候总是需要删除最旧的日志文件。

以下是一个简单的实现：

```powershell
# this is the folder keeping the log files
$LogFileDir = "c:\myLogFiles"

# find all log files...
Get-ChildItem -Path $LogFileDir -Filter *.log |
  # sort by last change ascending
  # (oldest first)...
  Sort-Object -Property LastWriteTime |
  # take the first (oldest) one
  Select-Object -First 1 |
  # remove it (remove -whatif to actually delete)
  Remove-Item -WhatIf
```

如果只希望保留最新的 5 个文件，请像这样更改：

```powershell
# this is the folder keeping the log files
$LogFileDir = "c:\myLogFiles"
$Keep = 5

# find all log files...
$files = @(Get-ChildItem -Path $LogFileDir -Filter *.log)
$NumberToDelete = $files.Count - $Keep

if ($NumberToDelete -gt 0)
{
    $files |
      # sort by last change ascending
      # (oldest first)...
      Sort-Object -Property LastWriteTime |
      # take the first (oldest) one
      Select-Object -First $NumberToDelete |
      # remove it (remove -whatif to actually delete)
      Remove-Item -WhatIf
}
```

<!--本文国际来源：[Deleting the Oldest Log File](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deleting-the-oldest-log-file)-->

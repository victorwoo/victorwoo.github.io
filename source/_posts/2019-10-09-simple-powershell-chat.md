---
layout: post
date: 2019-10-09 00:00:00
title: "PowerShell 技能连载 - 简易的 PowerShell 聊天室"
description: PowerTip of the Day - Simple PowerShell Chat
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个有趣的 PowerShell 脚本，您可以用它来创建一个简易的多频道聊天室。您所需的只是一个所有人都有读写权限的网络共享目录。

该聊天室是基于文件的，并且使用 PowerShell 的功能来监视文件的改变。所以基本上，每个聊天频道是一个文本文件，并且无论何时，如果某人想“说”一些内容，那么就会向文件中添加一行。任何连接到该聊天频道的人实际上都在监视这个文件的改变。

显然，这个“聊天室”只适用于试验，并且有许多限制。例如，当某人在写文件时，其他人无法同时写入。但是，它很好地说明了 PowerShell 如何监视文件并在添加新文本时采取行动。您也可以将这个技术用在日志文件上：PowerShell 可以在日志文件有新内容的时候通知您，并且甚至自动过滤新增加的文本并根据触发关键字发出警告或采取行动。

在开始之前，请确保调整 `ServerShare` 并将它设置为一个可读写的网络共享目录。

下一步，您可以这样进入聊天室：

```powershell
Enter-Chat -ChatChannelName lunchbreak -Name Tobias -ShowOldPosts
```

`-ShowOldPosts` 显示已有的聊天信息。如果没有添加这个参数，那么只能看见新的信息。无论何时运行 `Enter-Chat`，它都会检查在 `-ChatChannelName` 中指定名称的文件，如果该文件不存在，就会创建它。

`Get-ChatChannel` 列出共享目录中的所有聊天文件，以及聊天室最后使用的时间。该信息完全取自文件属性 (`LastWriteTime`)。

```powershell
# make sure you adjust this path
# it must point to a network share where you have read and write permissions
$ServerShare = "\\myserver\chathome"

function Enter-Chat
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $ChatChannelName,

    [string]
    $Name = $env:USERNAME,

    [Switch]
    $ShowOldPosts,

    $HomeShare = $ServerShare

  )

  if ($ShowOldPosts)
  {
    $Option = ''
  }
  else
  {
    $Option = '-Tail 0'
  }

  $Path = Join-Path -Path $HomeShare -ChildPath "$ChatChannelName.txt"
  $exists = Test-Path -Path $Path
  if ($exists -eq $false)
  {
    $null = New-Item -Path $Path -Force -ItemType File
  }

  $process = Start-Process -FilePath powershell -ArgumentList "-noprofile -windowstyle hidden -command Get-COntent -Path '$Path' $Option -Wait | Out-GridView -Title 'Chat: [$ChatChannelName]'" -PassThru

  Write-Host "To exit, enter: quit"
  "[$Name entered the chat]" | Add-Content -Path $Path
  do
  {
    Write-Host "[$ChatChannelName]: " -ForegroundColor Green -NoNewline
    $inputText = Read-Host

    $isStopCommand = 'quit','exit','stop','leave' -contains $inputText
    if ($isStopCommand -eq $false)
    {
      "[$Name] $inputText" | Add-Content -Path $Path
    }


  } until ($isStopCommand -eq $true)
  "[$Name left the chat]" | Add-Content -Path $Path

  $process | Stop-Process
}



function Get-ChatChannel
{
  param
  (
    $HomeShare = $ServerShare

  )

  Get-ChildItem -Path $HomeShare -Filter *.txt -File |
    ForEach-Object {
      [PSCustomObject]@{
        ChannelName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        LastActive = $_.LastWriteTime
        Started = $_.CreationTime
      }
    }
}
```

<!--本文国际来源：[Simple PowerShell Chat](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/simple-powershell-chat)-->


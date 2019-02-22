---
layout: post
date: 2018-06-28 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 5 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 5)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是关于 PowerShell 脚本块日志的迷你系列的第 5 部分。我们已经几乎达到目标了，缺少的是一个更好的方式来读取记录的代码。在我们之前的方法中，执行代码的用户收到一个晦涩的 SID 而不是一个清晰的名称。以下是一个将用户 SID 转为真实名称的函数，并且使用智能缓存来加速 SID 的查询过程：

```powershell
function Get-LoggedCode
{
  # to speed up SID-to-user translation,
  # we use a hash table with already translated SIDs
  # it is empty at first
  $translateTable = @{}

  # read all raw events
  $logInfo = @{ ProviderName="Microsoft-Windows-PowerShell"; Id = 4104 }
  Get-WinEvent -FilterHashtable $logInfo | 
  # take each raw set of data...
  ForEach-Object {
    # turn SID into user
    $userSID = $_.UserId

    # if the cache does not contain the user SID yet...
    if (!$translateTable.ContainsKey($userSid))
    {
      try
      {
        # ...try and turn it into a real name, and add it
        # to the cache
        $identifier = New-Object System.Security.Principal.SecurityIdentifier($userSID)
        $result = $identifier.Translate( [System.Security.Principal.NTAccount]).Value
        $translateTable[$userSid] = $result
      }
      catch
      {
        # if this fails, use the SID instead of a real name
        $translateTable[$userSid] = $userSID
      }
    }
    else
    {
    
    }
  
    # create a new object and extract the interesting
    # parts from the raw data to compose a "cooked"
    # object with useful data
    [PSCustomObject]@{
      # when this was logged
      Time = $_.TimeCreated
      # script code that was logged
      Code = $_.Properties[2].Value
      # if code was split into multiple log entries,
      # determine current and total part
      PartCurrent = $_.Properties[0].Value
      PartTotal = $_.Properties[1].Value
                
      # if total part is 1, code is not fragmented
      IsMultiPart = $_.Properties[1].Value -ne 1
      # path of script file (this is empty for interactive
      # commands)
      Path = $_.Properties[4].Value
      # log level
      # by default, only level "Warning" will be logged
      Level = $_.LevelDisplayName
      # user who executed the code 
      # take the real user name from the cache of translated
      # user names
      User = $translateTable[$userSID]
    }
  } 
}
```

<!--本文国际来源：[Understanding Script Block Logging (Part 5)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-5)-->

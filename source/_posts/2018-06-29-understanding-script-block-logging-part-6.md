---
layout: post
date: 2018-06-29 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 6 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 6)
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
这是关于 PowerShell 脚本块日志的迷你系列的第 6 部分。该是时候介绍最后的部分了：当您执行一段非常大的 PowerShell 脚本时，它们是分块记录的。还缺少的部分是整理代码片段的逻辑：

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
    # store the code in this entry
    
    # if this is the first part, take it
    if ($_.Properties[0].Value -eq 1)
    {
      $code = $_.Properties[2].Value
    }
    # else, add it to the $code variable
    else
    {
      $code += $_.Properties[2].Value
    }
  
    # return the object when all parts have been processed
    if ($_.Properties[0].Value -eq $_.Properties[1].Value)
    {
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
        Code = $code
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
}
```

本质上，这个函数检查该脚本是否是由多段组成。如果是，它将代码添加到 `$code` 中，直到当前块等于 最后一块。就是这么简单。

<!--more-->
本文国际来源：[Understanding Script Block Logging (Part 6)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-6)

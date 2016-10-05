layout: post
title: "PowerShell 技能连载 - 远程读取已安装的软件"
date: 2014-06-09 00:00:00
description: PowerTip of the Day - Reading Installed Software Remotely
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
大多数软件都会在注册表中登记自己。以下是一段从能从本地和远程的 32 位及 64 位注册表中读取已安装的软件列表的代码。它还是一个演示如何读取远程注册表的不错的例子。

    # NOTE: RemoteRegistry Service needs to run on a target system!
    $Hive = 'LocalMachine'
    
    # you can specify as many keys as you want as long as they are all in the same hive
    $Key = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    
    # you can specify as many value names as you want
    $Value = 'DisplayName', 'DisplayVersion', 'UninstallString'
    
    # you can specify a remote computer name as long as the RemoteRegistry service runs on the target machine,
    # you have admin permissions on the target, and the firewall does not block you. Default is the local machine:
    $ComputerName = $env:COMPUTERNAME
    
    # add the value "RegPath" which will contain the actual Registry path the value came from (since you can specify more than one key)
    $Value = @($Value) + 'RegPath'
        
    # now for each regkey you specified...
    $Key | ForEach-Object {
      # ...open the hive on the appropriate machine
      $RegHive = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
      
      # ...open the key in that hive...
      $RegKey = $RegHive.OpenSubKey($_)
      
      # ...find names of all subkeys...
      $RegKey.GetSubKeyNames() | ForEach-Object {
        # ...open subkeys...
        $SubKey = $RegKey.OpenSubKey($_)
        # ...and read all the requested values from each subkey
        # ...to store them, use Select-Object to create a simple new object
        $returnValue = 1 | Select-Object -Property $Value
        
        $Value | ForEach-Object {
          $returnValue.$_ = $subkey.GetValue($_)
        }
    
        # ...add the current regkey path name
        $returnValue.RegPath = $SubKey.Name
    
        # return the values:
        $returnValue
    
        # close the subkey
        $SubKey.Close()
      }
      
      # close the regkey
      $RegKey.Close()
      # close the hive
      $RegHive.Close()
    
    } | Out-GridView

<!--more-->
本文国际来源：[Reading Installed Software Remotely](http://community.idera.com/powershell/powertips/b/tips/posts/reading-installed-software-remotely)

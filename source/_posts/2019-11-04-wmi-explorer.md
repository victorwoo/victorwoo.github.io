---
layout: post
date: 2019-11-04 00:00:00
title: "PowerShell 技能连载 - WMI Explorer"
description: PowerTip of the Day - WMI Explorer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI (Windows Management Instrumentation) is a great information source: you can find almost any information about your computer somewhere. The hard part isn’t the WMI query itself. The hard part is finding out the appropriate WMI class names and properties:

To get information about your BIOS, for example, run this:


    PS> Get-CimInstance -ClassName Win32_BIOS


    SMBIOSBIOSVersion : 1.0.9
    Manufacturer      : Dell Inc.
    Name              : 1.0.9
    SerialNumber      : 4ZKM0Z2
    Version           : DELL   - 20170001


Getting other information is just a question of replacing the class name you are querying, so to get information about your operating system instead, for example, run this:


    PS> Get-CimInstance -ClassName Win32_OperatingSystem


    SystemDirectory : C:\Windows\system32
    Organization    :
    BuildNumber     : 18362
    RegisteredUser  : tobias.weltner@email.de
    SerialNumber    : 00330-50000-00000-AAOEM
    Version         : 10.0.18362


To find just about any information and discover the appropriate WMI class names to use, we have created a smart “WMI Explorer” which really is just a simple function. It requires Windows PowerShell (PowerShell 3-5):

    function Find-WmiClass
    {
      # show all properties, not just 4
      $oldLimit = $FormatEnumerationLimit
      $global:FormatEnumerationLimit = -1
      # list all WMI classes...
      Get-WmiObject -Class * -List |
      # ...with at least 4 properties
      Where-Object { $_.Properties.Count -gt 4 } |
      # let the user select one
      Out-GridView -Title 'Select a class that seems interesting' -OutputMode Single |
      ForEach-Object {
        # query the selected class
        $Name = $_.name
        $props = Get-WmiObject -Class $Name |
        # take the first instance
        Select-Object -Property * -First 1 |
        ForEach-Object {
          # turn the object into a hash table, and exclude empty properties
          $_ | & {
                  $_.PSObject.Properties |
            Sort-Object -Property Name |
            Where-Object { $_.Value -ne $null } |
            ForEach-Object {
                $hashtable = [Ordered]@{}} { $hashtable[$_.Name] = $_.Value } { $hashtable }
            } |
            # show the properties and let the user select
            Out-GridView -Title "$name : Select all properties you need (hold CTRL)" -PassThru |
            ForEach-Object {
              # return the selected property names
              $_.Name
            }
        }
        # take all selected properties
        $prop = $props -join ', '
        # create the command for it:
        $a = "Get-CimInstance -Class $Name | Select-Object -Property $prop"
        # place it into the clipboard
        $a | Set-Clipboard
        Write-Warning "Command is also available from the clipboard"
        $a
      }
      # reset format limit
      $global:FormatEnumerationLimit = $oldLimit
    }


Here is how it works:

* Run the code above which adds a new command called Find-WmiClass
* Run Find-WmiClass to run the function
* A grid view window opens and displays all WMI classes available in the standard namespace root\cimv2 (if you want to search a different namespace, adjust the code and add the -Namespace parameter to Get-WmiObject calls)
* Now enter something that you are looking for into the top text field in the grid view window which acts like a filter. If you enter UserName for example, the grid view limits the list to all classes that have “UserName” anywhere in its name or in the name of any of their properties. You now have just a few classes to select from.
* Select the class you want to investigate, for example “Win32_ComputerSystem”, and click OK in the bottom right corner of the grid.
* Now the selected class is queried, and the first instance of it displays in another grid view. Each property is displayed on its own line, so you can again filter the display. Hold CTRL to select all properties you want to keep. Then click OK again.
* The command is created for you and displays in the console. It is also placed into the clipboard, so to test drive it, press CTRL+V, then ENTER.

Thanks to Find-WmiClass, exploring the WMI and finding useful WMI classes and properties has just become very easy.

- - -

[![Twitter This Tip!](/img/2019-11-04-wmi-explorer-001.gif)](http://twitter.com/home/?status=RT+%40PowerTip+%20WMI%20Explorer%20with%20%23PowerShell+http://bit.ly/2N5Mz17)[ReTweet this Tip!](http://twitter.com/home/?status=RT+%40%20WMI%20Explorer%20with%20%23PowerShell+http://bit.ly/2N5Mz17)

<!--本文国际来源：[WMI Explorer](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/wmi-explorer)-->


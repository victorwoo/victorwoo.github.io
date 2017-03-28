layout: post
date: 2017-02-23 00:00:00
title: "PowerShell 技能连载 - Reading Environment Variables Freshly"
description: PowerTip of the Day - Reading Environment Variables Freshly
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
When you read environment variables in PowerShell, you probably make use of the “env:” drive. This line retrieves the environment variable %USERNAME%, for example, telling you the name of the user executing the script:

     
    PS C:\> $env:USERNAME
    tobwe
    
    PS C:\>
     

The “env:” drive always accesses the process set of environment variables. This makes sense in most cases as many of the environment variables (like “UserName”) are defined in this set. Basically, the process set of environment variables is a “snapshot” of all environment variables at the time of when an application starts, plus a number of additional pieces of information (like “UserName”).

To read environment variables freshly and explicitly from the system or user set, use code like this:

    $name = 'temp'
    $scope = [EnvironmentVariableTarget]::Machine
    
    $content = [Environment]::GetEnvironmentVariable($name, $scope)
    "Content: $content"
    

You could use this technique, for example, to communicate between two processes. To play with this, open two PowerShell consoles. Now, in the first console, enter this:

    [Environment]::SetEnvironmentVariable("PS_Info", "Hello", "user")
    

In the second PowerShell console, enter this line to receive the information:

    [Environment]::GetEnvironmentVariable("PS_Info", "user") 
    

To clean up the environment variable, enter this line in either console:

    [Environment]::SetEnvironmentVariable("PS_Info", "", "user")

<!--more-->
本文国际来源：[Reading Environment Variables Freshly](http://community.idera.com/powershell/powertips/b/tips/posts/reading-environment-variables-freshly)

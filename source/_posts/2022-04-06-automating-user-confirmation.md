---
layout: post
date: 2022-04-06 00:00:00
title: "PowerShell 技能连载 - Automating User Confirmation"
description: PowerTip of the Day - Automating User Confirmation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Some commands seem to require user input no matter what. While you can try parameters such as -Confirm:$false to get rid of default confirmations, some commands either do not support that parameter, or show their very own user requests. Here is an example:


    PS> Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All


When you run this command (elevated) on Windows 10 or 11, at the end of the process the cmdlet wants to know whether a restart is OK:


    Do you want to restart the computer to complete this operation now?
    [Y] Yes  [N] No  [?] Help (default is "Y"):


The cmdlet halts until the user either enters “Y” or “N”.

To fully automate cmdlets like this, either take a closer look at its remaining parameters. Often, there are ways to articulate your choice and leave no room for ambiguities that need manual resolution. In the example above, by adding “-NoRestart”, you could deny automatic restarts and then explicitly restart the machine using Restart-Computer.

Or, you can pipe user input to a new PowerShell instance. PowerShell takes the input and places it into the keyboard input buffer. Whenever a command requests user input, it is taken from this buffer. Use comma-separated values to submit multiple items of user input to PowerShell.

Here is an example illustrating how you can submit a “N” to the command above:


    PS> "N" | powershell.exe -noprofile -command Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All






<!--本文国际来源：[Automating User Confirmation](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/automating-user-confirmation)-->


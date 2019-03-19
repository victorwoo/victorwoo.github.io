---
layout: post
date: 2018-10-11 00:00:00
title: "PowerShell 技能连载 - Adding New Incrementing Number Column in a Grid View Window"
description: PowerTip of the Day - Adding New Incrementing Number Column in a Grid View Window
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Maybe you’d like to add a column with incrementing indices to your objects. Try this:

    $startcount = 0
    Get-Service |
      Select-Object -Property @{N='ID#';E={$script:startcount++;$startcount}}, * |
      Out-GridView


When you run this chunk of code, you get a list of services in a grid view window, and the first column “ID#” is added with incrementing ID numbers.

The technique can be used to add arbitrary columns. Simply use a hash table with key N[ame] for the column name, and key E[xpression] with the script block that generates the column content.

<!--本文国际来源：[Adding New Incrementing Number Column in a Grid View Window](http://community.idera.com/powershell/powertips/b/tips/posts/adding-new-incrementing-number-column-in-a-grid-view-window)-->

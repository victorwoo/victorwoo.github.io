---
layout: post
date: 2019-04-26 00:00:00
title: "PowerShell 技能连载 - Real-Time Processing for Language Structures"
description: PowerTip of the Day - Real-Time Processing for Language Structures
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
In the previous tip we looked at queues and how they can search the entire file system:

    # create a new queue
    $dirs = [System.Collections.Queue]::new()

    # add an initial path to the queue
    # any folder path in the queue will later be processed
    $dirs.Enqueue('c:\windows')

    # process all elements on the queue until all are taken
    While ($current = $dirs.Dequeue())
    {
        # find subfolders of current folder, and if present,
        # add them all to the queue
        try
        {
            foreach ($_ in [IO.Directory]::GetDirectories($current))
            {
                    $dirs.Enqueue($_)
            }
        } catch {}

        try
        {
            # find all files in the folder currently processed
            [IO.Directory]::GetFiles($current, "*.exe")
            [IO.Directory]::GetFiles($current, "*.ps1")
        } catch { }
    }


How would you process the data created by the loop though, i.e. to display it in a grid view window? You cannot pipe it in real-time, so this fails:

    $dirs = [System.Collections.Queue]::new()
    $dirs.Enqueue('c:\windows')

    While ($current = $dirs.Dequeue())
    {
        try
        {
            foreach ($_ in [IO.Directory]::GetDirectories($current))
            {
                    $dirs.Enqueue($_)
            }
        } catch {}

        try
        {
            [IO.Directory]::GetFiles($current, "*.exe")
            [IO.Directory]::GetFiles($current, "*.ps1")
        } catch { }
    # this fails
    } | Out-GridView


You can save the results produced by do-while to a variable. That works but takes forever because you’d have to wait for the loop to complete until you can do something with the variable:

    $dirs = [System.Collections.Queue]::new()
    $dirs.Enqueue('c:\windows')

    # save results to variable...
    $all = while ($current = $dirs.Dequeue())
    {
        try
        {
            foreach ($_ in [IO.Directory]::GetDirectories($current))
            {
                    $dirs.Enqueue($_)
            }
        } catch {}

        try
        {
            [IO.Directory]::GetFiles($current, "*.exe")
            [IO.Directory]::GetFiles($current, "*.ps1")
        } catch { }
    }

    # then process or output
    $all | Out-GridView


The same limitation applies when you use $() or other constructs. To process the results emitted by do-while in true real-time, use a script block instead:

    $dirs = [System.Collections.Queue]::new()
    $dirs.Enqueue('c:\windows')

    # run the code in a script block
    & { while ($current = $dirs.Dequeue())
        {
            try
            {
                foreach ($_ in [IO.Directory]::GetDirectories($current))
                {
                        $dirs.Enqueue($_)
                }
            } catch {}

            try
            {
                [IO.Directory]::GetFiles($current, "*.exe")
                [IO.Directory]::GetFiles($current, "*.ps1")
            } catch { }
        }
    } | Out-GridView


With this approach, results start to show in the grid view window almost momentarily, and you don’t have to wait for the loop to complete.

- - -

_[psconf.eu](http://www.psconf.eu/) – PowerShell Conference EU 2019 – June 4-7, Hannover Germany – visit [www.psconf.eu](http://www.psconf.eu/) There aren’t too many trainings around for experienced PowerShell scripters where you really still learn something new. But there’s one place you don’t want to miss: PowerShell Conference EU - with 40 renown international speakers including PowerShell team members and MVPs, plus 350 professional and creative PowerShell scripters. Registration is open at www.psconf.eu, and the full 3-track 4-days agenda becomes available soon. Once a year it’s just a smart move to come together, update know-how, learn about security and mitigations, and bring home fresh ideas and authoritative guidance. We’d sure love to see and hear from you!_

[![Twitter This Tip!](/img/2019-04-26-real-time-processing-for-language-structures-001.gif)](http://twitter.com/home/?status=RT+%40PowerTip+%20Real-Time%20Processing%20for%20Language%20Structures%20with%20%23PowerShell+http://bit.ly/2Dp5Cyv)[ReTweet this Tip!](http://twitter.com/home/?status=RT+%40%20Real-Time%20Processing%20for%20Language%20Structures%20with%20%23PowerShell+http://bit.ly/2Dp5Cyv)

<!--本文国际来源：[Real-Time Processing for Language Structures](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/real-time-processing-for-language-structures)-->


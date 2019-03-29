---
layout: post
date: 2019-03-25 00:00:00
title: "PowerShell 技能连载 - Splitting Large Files in Smaller Parts (Part 2)"
description: PowerTip of the Day - Splitting Large Files in Smaller Parts (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
In our previous tip we explained how you can split large files into smaller chunks. Today, we complete this with a function that takes these file parts and joins them back to recreate the original file.

Let’s consider you have split a large file into many smaller file chunks using the Split-File function that we presented in our last tip. Now you have a bunch of files with the extension “.part”. This is the result we ended with in our last tip:


    PS> dir "C:\Users\tobwe\Downloads\*.part"


        Folder: C:\Users\tobwe\Downloads


    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       03.03.2019     16:25        6291456 Woman tries putting gas in a Tesla.mp4.00.part
    -a----       03.03.2019     16:25        6291456 Woman tries putting gas in a Tesla.mp4.01.part
    -a----       03.03.2019     16:25        6291456 Woman tries putting gas in a Tesla.mp4.02.part
    -a----       03.03.2019     16:25        5207382 Woman tries putting gas in a Tesla.mp4.03.part


To join these parts, use our new Join-File function (don’t confuse it with the built-in Join-Path command). Let’s first see how joining works:


    PS C:\> Join-File -Path "C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4" -DeletePartFiles -Verbose
    VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.00.part...
    VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.01.part...
    VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.02.part...
    VERBOSE: processing C:\Users\tobwe\Downloads\Woman tries putting gas in a Tesla.mp4.03.part...
    VERBOSE: Deleting part files...

    PS C:\>


Simply submit the file name (without the part number and the part extension). When you specify -DeletePartFiles, then the function will clean up and delete the part files once the original file is created.

To be able to use Join-File, you need to run this code:

    function Join-File
    {

        param
        (
            [Parameter(Mandatory)]
            [String]
            $Path,

            [Switch]
            $DeletePartFiles
        )

        try
        {
            # get the file parts
            $files = Get-ChildItem -Path "$Path.*.part" |
            # sort by part
            Sort-Object -Property {
                # get the part number which is the "extension" of the
                # file name without extension
                $baseName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
                $part = [IO.Path]::GetExtension($baseName)
                if ($part -ne $null -and $part -ne '')
                {
                    $part = $part.Substring(1)
                }
                [int]$part
            }
            # append part content to file
            $writer = [IO.File]::OpenWrite($Path)
            $files |
            ForEach-Object {
                Write-Verbose "processing $_..."
                $bytes = [IO.File]::ReadAllBytes($_)
                $writer.Write($bytes, 0, $bytes.Length)
            }
            $writer.Close()

            if ($DeletePartFiles)
            {
                Write-Verbose "Deleting part files..."
                $files | Remove-Item
            }
        }
        catch
        {
            throw "Unable to join part files: $_"
        }
    }


Learning points for today:

- - -

* * Use the [IO.Path] class to split file paths
  * Use the [IO.File] class to access file content on byte level
  * Use OpenWrite() to write to files on byte level
- - -

- - -

_[psconf.eu](http://www.psconf.eu/) – PowerShell Conference EU 2019 – June 4-7, Hannover Germany – visit [www.psconf.eu](http://www.psconf.eu/) There aren’t too many trainings around for experienced PowerShell scripters where you really still learn something new. But there’s one place you don’t want to miss: PowerShell Conference EU - with 40 renown international speakers including PowerShell team members and MVPs, plus 350 professional and creative PowerShell scripters. Registration is open at www.psconf.eu, and the full 3-track 4-days agenda becomes available soon. Once a year it’s just a smart move to come together, update know-how, learn about security and mitigations, and bring home fresh ideas and authoritative guidance. We’d sure love to see and hear from you!_

[![Twitter This Tip!](/img/2019-03-25-splitting-large-files-in-smaller-parts-part-2-001.gif)](http://twitter.com/home/?status=RT+%40PowerTip+%20Splitting%20Large%20Files%20in%20Smaller%20Parts%20(Part%202)%20with%20%23PowerShell+http://bit.ly/2HOKbtC)[ReTweet this Tip!](http://twitter.com/home/?status=RT+%40%20Splitting%20Large%20Files%20in%20Smaller%20Parts%20(Part%202)%20with%20%23PowerShell+http://bit.ly/2HOKbtC)

<!--本文国际来源：[Splitting Large Files in Smaller Parts (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-large-files-in-smaller-parts-part-2)-->


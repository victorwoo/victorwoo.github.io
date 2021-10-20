---
layout: post
date: 2021-10-08 00:00:00
title: "PowerShell 技能连载 - Turning Text into Individual Lines (Part 3)"
description: PowerTip of the Day - Turning Text into Individual Lines (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
In the previous tip we split a chunk of multi-line text into individual lines and removed any empty lines.

However, when a line isn’t really empty but contains whitespace (spaces or tabulators), it is still returned:

    # $data is a single string and contains blank lines
    $data = @'

    Server1


    Server2
    Cluster4


    '@

    $data = $data.Trim()

    # split in single lines and remove empty lines
    $regex = '[\r\n]{1,}'
    $array = $data -split $regex

    $array.Count

    $c = 0
    Foreach ($_ in $array)
    {
        '{0:d2} {1}' -f $c, $_
        $c++
    }


Here, we have added a few spaces to the line right above “Server2” (which you obviously can’t see in the listing). This is the result:


    00 Server1
    01
    02 Server2
    03 Cluster4


Since we are splitting at any number of CR and LF characters, a space would break that pattern.

Rather than turning the regular expression in an even more complex beast, for such things you may want to append a simple Where-Object to do the fine polishing:

    # $data is a single string and contains blank lines
    $data = @'

    Server1


    Server2
    Cluster4


    '@

    $data = $data.Trim()

    # split in single lines and remove empty lines
    $regex = '[\r\n]{1,}'
    $array = $data -split $regex |
      Where-Object { [string]::IsNullOrWhiteSpace($_) -eq $false }

    $array.Count

    $c = 0
    Foreach ($_ in $array)
    {
        '{0:d2} {1}' -f $c, $_
        $c++
    }


[string]::IsNullOrEmpty() identifies the situation we are after, so lines that qualify are removed by Where-Object. The result is what is needed:


    00 Server1
    01 Server2
    02 Cluster4






<!--本文国际来源：[Turning Text into Individual Lines (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-text-into-individual-lines-part-3)-->


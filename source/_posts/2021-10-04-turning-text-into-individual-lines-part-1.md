---
layout: post
date: 2021-10-04 00:00:00
title: "PowerShell 技能连载 - Turning Text into Individual Lines (Part 1)"
description: PowerTip of the Day - Turning Text into Individual Lines (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Occasionally, you need to process multi-line text line by line. Here is an example of a multi-line string to start with:

    # working with 1-dimensional input

    # $data is a single string
    $data = @'
    Server1
    Server2
    Cluster4
    '@

    $data.GetType().FullName
    $data.Count


An efficient way to split the text into individual lines is using the -split operator with a regular expression that can deal with the variety of platform-dependent line terminators:

    # split the string in individual lines
    # $array is an array with individual lines now

    $regex = '[\r\n]{1,}'
    $array = $data -split $regex

    $array.GetType().FullName
    $array.Count

    $array


Here are a few alternatives for the regular expression found in $regex that you encounter in scripts:

<table><tbody><tr>Regular expression for splittingRemarks</tr><tr><td>/r</td><td>Resembles “Carriage Return” (ASCII 13). If the OS does not use this for new lines, split fails. If OS uses this plus “Line Feed” (ASCII 10), remaining invisible line feed characters damage the strings.</td></tr><tr><td>/n</td><td>Same as above, just the opposite</td></tr><tr><td>[\r\n]+</td><td>Same as in the example code above. PowerShell splits at both characters provided there are one or more. This way, CR, LF, or CRLF, LFCR, are all removed while splitting. However, multiple consecutive new lines will all be removed, too: CRCRCR or CRLFCRLF</td></tr><tr><td>(\r\n|\r|\n)</td><td>This will correctly split a single line break, regardless of which characters a particular OS uses. It leaves consecutive blank lines intact.</td></tr></tbody></table>If you read text from a text file, Get-Content automatically splits the text into lines. To read the entire text content as a single string, you’d need to add the -Raw parameter.





<!--本文国际来源：[Turning Text into Individual Lines (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-text-into-individual-lines-part-1)-->


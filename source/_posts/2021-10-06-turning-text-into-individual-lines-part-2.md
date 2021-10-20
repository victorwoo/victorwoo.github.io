---
layout: post
date: 2021-10-06 00:00:00
title: "PowerShell 技能连载 - Turning Text into Individual Lines (Part 2)"
description: PowerTip of the Day - Turning Text into Individual Lines (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Let’s assume your script gets text input data, and you need to split the text into individual lines. In the previous tip we suggested a number of regular expressions to do the job. But what if the input text contains blank lines?

    # $data is a single string and contains blank lines
    $data = @'

    Server1


    Server2
    Cluster4


    '@

    # split in single lines and remove empty lines
    $regex = '[\r\n]{1,}'


As you see, the regular expression we used automatically takes care of blank lines in the middle of the text, however blank lines at the beginning or end of the text stay put.


    00
    01 Server1
    02 Server2
    03 Cluster4
    04


That’s because we are splitting at any number of new lines, so we are also splitting right at the beginning and end of the text. We are actually producing these two remaining blank lines ourselves.

To get rid of these, we must ensure that no line feed characters are present at the beginning and end of the text. That’s something Trim() can do:

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



    00 Server1
    01 Server2
    02 Cluster4






<!--本文国际来源：[Turning Text into Individual Lines (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turning-text-into-individual-lines-part-2)-->


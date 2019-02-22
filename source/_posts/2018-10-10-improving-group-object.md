---
layout: post
date: 2018-10-10 00:00:00
title: "PowerShell 技能连载 - 改进 Group-Object"
description: PowerTip of the Day - Improving Group-Object
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在每一个技能中我们解释了 `Group-Object` 能为您做什么，以及它有多么好用。不幸的是，`Group-Object` 的性能不理想。如果您试图对大量对象分组，该 cmdlet 可能会消耗大量时间。

以下是一行按文件大小对您的用户文件夹中所有文件排序的代码。当您希望检测重复的文件时，这将是一个十分重要的先决条件。由于这行代码将在最终返回结果，所以将会消耗大量的时间，甚至数小时：

```powershell
$start = Get-Date
$result = Get-ChildItem -Path $home -Recurse -ErrorAction SilentlyContinue -File |
    Group-Object -Property Length
$stop = Get-Date

($stop - $start).TotalSeconds
```

由于这些限制，我们创建了一个基于 PowerShell 的 `Group-Object` 的实现，并称它为 `Group-ObjectFast`。它基本上做相同的事请，只是速度更快。

```powershell
function Group-ObjectFast
{
    param
    (
        [Parameter(Mandatory,Position=0)]
        [Object]
        $Property,

        [Parameter(ParameterSetName='HashTable')]
        [Alias('AHT')]
        [switch]
        $AsHashTable,

        [Parameter(ValueFromPipeline)]
        [psobject[]]
        $InputObject,

        [switch]
        $NoElement,

        [Parameter(ParameterSetName='HashTable')]
        [switch]
        $AsString,

        [switch]
        $CaseSensitive
    )


    begin
    {
        # if comparison needs to be case-sensitive, use a
        # case-sensitive hash table,
        if ($CaseSensitive)
        {
            $hash = [System.Collections.Hashtable]::new()
        }
        # else, use a default case-insensitive hash table
        else
        {
            $hash = @{}
        }
    }

    process
    {
        foreach ($element in $InputObject)
        {
            # take the key from the property that was requested
            # via -Property

            # if the user submitted a script block, evaluate it
            if ($Property -is [ScriptBlock])
            {
                $key = & $Property
            }
            else
            {
                $key = $element.$Property
            }
            # convert the key into a string if requested
            if ($AsString)
            {
                $key = "$key"
            }

            # make sure NULL values turn into empty string keys
            # because NULL keys are illegal
            if ($key -eq $null) { $key = '' }

            # if there was already an element with this key previously,
            # add this element to the collection
            if ($hash.ContainsKey($key))
            {
                $null = $hash[$key].Add($element)
            }
            # if this was the first occurrence, add a key to the hash table
            # and store the object inside an arraylist so that objects
            # with the same key can be added later
            else
            {
                $hash[$key] = [System.Collections.ArrayList]@($element)
            }
        }
    }

    end
    {
        # default output are objects with properties
        # Count, Name, Group
        if ($AsHashTable -eq $false)
        {
            foreach ($key in $hash.Keys)
            {
                $content = [Ordered]@{
                    Count = $hash[$key].Count
                    Name = $key
                }
                # include the group only if it was requested
                if ($NoElement -eq $false)
                {
                    $content["Group"] = $hash[$key]
                }

                # return the custom object
                [PSCustomObject]$content
            }
        }
        else
        {
            # if a hash table was requested, return the hash table as-is
            $hash
        }
    }
}
```

只需要将上述例子中的 `Group-Object` 替换为 `Group-ObjectFast`，就可以体验它的速度：

```powershell
$start = Get-Date
$result = Get-ChildItem -Path $home -Recurse -ErrorAction SilentlyContinue -File |
    Group-ObjectFast -Property Length
$stop = Get-Date

($stop - $start).TotalSeconds
```

在我们的测试中，`Group-ObjectFast` 比 `Group-Object` 快了大约 10 倍。

<!--本文国际来源：[Improving Group-Object](http://community.idera.com/powershell/powertips/b/tips/posts/improving-group-object)-->

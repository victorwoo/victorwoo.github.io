layout: post
date: 2016-01-01 12:00:00
title: "PowerShell 技能连载 - ___"
description: 'PowerTip of the Day - Encode and Decode Text as Base64 '
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
Here is a simple way to encode text as a Base64 string:

    #requires -Version 1
    
    $text = 'Hello World!'
    [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($text), 'InsertLineBreaks')
    

The resulting text looks similar to this:

     
    SABlAGwAbABvACAAVwBvAHIAbABkACEA 
     

Text encoding is used whenever you want to simply obfuscate text, or when you want to protect text against accidental formatting changes. PowerShell.exe, for example, can run commands that are Base64-encoded. Here is an example (make sure you enable sound output on your machine):

    powershell.exe -EncodedCommand ZgBvAHIAKAAkAHgAIAA9ACAAMQAwADAAMAA7ACAAJAB4ACAALQBsAHQAIAAxADIAMAAwADAAOwAgACQAeAArAD0AMQAwADAAMAApACAAewAgAFsAUwB5AHMAdABlAG0ALgBDAG8AbgBzAG8AbABlAF0AOgA6AEIAZQBlAHAAKAAkAHgALAAgADMAMAAwACkAOwAgACIAJAB4ACAASAB6ACIAfQA=
        
To decode a Base64-encoded string, you can use the code below.

    #requires -Version 1
    
    $text = 'SABlAGwAbABvACAAVwBvAHIAbABkACEA'
    [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($text))
    

You can also use this code to decode encoded commands and see what they do. Simply assign the encoded command to $test instead.

<!--more-->
本文国际来源：[Encode and Decode Text as Base64 ](http://powershell.com/cs/blogs/tips/archive/2016/01/01/encode-and-decode-text-as-base64.aspx)

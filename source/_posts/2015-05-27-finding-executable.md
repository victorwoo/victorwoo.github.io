layout: post
date: 2015-05-27 11:00:00
title: "PowerShell 技能连载 - 查找可执行程序"
description: PowerTip of the Day - Finding Executable
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
许多文件扩展名都被关联为可执行程序。您可以使用 `Invoke-Item` 来打开一个可执行的文件。

然而，查找哪些文件扩展名是可执行程序却不是那么简单。您可以读取 Windows 注册表，然后自己查找这些值。如果您采用这种方法，请注意 32/64 位的问题。

另外一个方法是使用 Windows API。以下示例代码演示了它是如何工作的。如果您使用了这种方法，您可以将重活交给操作系统做。付出的代价是一堆调用内部 API 函数的 C# 代码。


    $Source = @"
    
    using System;
    using System.Text;
    using System.Runtime.InteropServices;
    public class Win32API
        {
            [DllImport("shell32.dll", EntryPoint="FindExecutable")] 
    
            public static extern long FindExecutableA(string lpFile, string lpDirectory, StringBuilder lpResult);
    
            public static string FindExecutable(string pv_strFilename)
            {
                StringBuilder objResultBuffer = new StringBuilder(1024);
                long lngResult = 0;
    
                lngResult = FindExecutableA(pv_strFilename, string.Empty, objResultBuffer);
    
                if(lngResult >= 32)
                {
                    return objResultBuffer.ToString();
                }
    
                return string.Format("Error: ({0})", lngResult);
            }
        }
    
    "@
    
    Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
    
    $FullName = 'c:\Windows\windowsupdate.log'
    $Executable = [Win32API]::FindExecutable($FullName)
        
    "$FullName will be launched by $Executable"

一个已知的限制是 `FindExecutable()` 的使用前提是该文件必须存在。您无法只通过文件扩展名来断定是否为一个可执行文件。

<!--more-->
本文国际来源：[Finding Executable](http://community.idera.com/powershell/powertips/b/tips/posts/finding-executable)

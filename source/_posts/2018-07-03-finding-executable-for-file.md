---
layout: post
date: 2018-07-03 00:00:00
title: "PowerShell 技能连载 - 查看文件对应的可执行程序"
description: PowerTip of the Day - Finding Executable for File
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
多数事情可以由 PowerShell 的内置指令完成，但是那还不够，您总是可以借助内置的 Windows API。例如，如果您想查看某个文件关联的应用程序，请试试这段代码：

```powershell
function Get-ExecutableForFile
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path
    )

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
    [Win32API]::FindExecutable($Path)
}
```

以下是使用这个函数的方法：

```powershell
PS> Set-EnvironmentVariable -Name test -Value 123 -Target User
```

<!--more-->
本文国际来源：[Finding Executable for File](http://community.idera.com/powershell/powertips/b/tips/posts/finding-executable-for-file)

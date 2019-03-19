---
layout: post
date: 2014-12-26 12:00:00
title: "PowerShell 技能连载 - 压缩路径"
description: PowerTip of the Day - Compacting Paths
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 2.0 及以上版本_

有些时候报表中的路径名太长了。要缩短一个路径，您当然可以将字符串截断成指定的长度，但是这将导致路径丧失可读性。一个更好的办法是使用内置的 Windows API 函数来更智能地缩短路径。

以下例子也演示了如何在 PowerShell 脚本中使用 C# 代码：

    $newType = @'
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    namespace WindowsAPILib
    {
        public class Helper
        {
            [DllImport("shlwapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
            internal static extern bool PathCompactPathEx(System.Text.StringBuilder pszOut, string pszSrc, Int32 cchMax, Int32 dwFlags);

            public static string CompactPath(string Path, int DesiredLength)
            {
                StringBuilder sb = new StringBuilder(260);
                if (PathCompactPathEx(sb, Path, DesiredLength + 1, 0))
                { return sb.ToString(); }
                else
                { return Path; }
            }
        }
    }
    '@

    Add-Type -TypeDefinition $newType

当您执行了该代码，就创建了一个名为 `WindowsAPILib` 的新的 .NET 类型，从而得到一个新的名为 `CompactPath` 的新的静态方法。您现在可以这样的使用：


    PS> $pshome
    C:\Windows\System32\WindowsPowerShell\v1.0

    PS> [WindowsAPILib.Helper]::CompactPath($pshome, 12)
    C:\W...\v1.0

    PS> [WindowsAPILib.Helper]::CompactPath($pshome, 18)
    C:\Windows...\v1.0

    PS> [WindowsAPILib.Helper]::CompactPath($pshome, 22)
    C:\Windows\Sys...\v1.0

<!--本文国际来源：[Compacting Paths](http://community.idera.com/powershell/powertips/b/tips/posts/compacting-paths)-->

---
layout: post
date: 2016-02-12 12:00:00
title: "PowerShell 技能连载 - 将对象发送到记事本"
description: PowerTip of the Day - Sending Objects to Notepad
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能里我们演示了如何将文本发送到一个全新的记事本实例中。今天，您会获得一个增强版的 `Out-Notepad`：您现在可以通过管道传输任何东西到记事本了。如果内容不是字符串，`Out-Notepad` 会使用内置的 PowerShell ETS 将它转换为文本并且合适地显示出来：

```powershell
#requires -Version 2
function Out-Notepad
{
  param
  (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Object]
    [AllowEmptyString()]
    $Object,

    [Int]
    $Width = 150
  )

  begin
  {
    $al = New-Object System.Collections.ArrayList
  }

  process
  {
    $null = $al.Add($Object)
  }
  end
  {
    $text = $al |
    Format-Table -AutoSize -Wrap |
    Out-String -Width $Width

    $process = Start-Process notepad -PassThru
    $null = $process.WaitForInputIdle()


    $sig = '
      [DllImport("user32.dll", EntryPoint = "FindWindowEx")]public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
      [DllImport("User32.dll")]public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);
    '

    $type = Add-Type -MemberDefinition $sig -Name APISendMessage2 -PassThru
    $hwnd = $process.MainWindowHandle
    [IntPtr]$child = $type::FindWindowEx($hwnd, [IntPtr]::Zero, "Edit", $null)
    $null = $type::SendMessage($child, 0x000C, 0, $text)
  }
}
```

您现在可以通过管道传输任何东西到 `Out-Notepad`。它将原样显示：

    PS C:\> Get-Content $env:windir\system32\drivers\etc\hosts | Out-Notepad

如果您通过管道传送对象，`Out-Notepad` 会将它们转换为文本并且不会截断任何东西。您可能会希望用 `-Width` 参数来确定页宽，以便正常显示：

    PS C:\> Get-EventLog -LogName System -EntryType Error, Warning -Newest 10 | Out-Notepad -Width 130

另外您可能需要最大化记事本或禁用换行来查看正确的格式。

<!--本文国际来源：[Sending Objects to Notepad](http://community.idera.com/powershell/powertips/b/tips/posts/sending-objects-to-notepad)-->

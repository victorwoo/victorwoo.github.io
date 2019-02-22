---
layout: post
date: 2018-06-08 00:00:00
title: "PowerShell 技能连载 - Out-Notepad: Send Information to Notepad"
description: 'PowerTip of the Day - Out-Notepad: Send Information to Notepad'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您是否曾希望将文本直接发送到记事本，而并不将它保存到文件中？

通常，您需要将文本保存到一个文件，然后通知它读取文件。还有一个更特别的方法：通过 Windows 消息和记事本通信，将文字发送到记事本。这是 `Out-Notepad` 函数的代码：

```powershell
#requires -Version 2
function Out-Notepad
{
  param
  (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String]
    [AllowEmptyString()] 
    $Text
  )

  begin
  {
    $sb = New-Object System.Text.StringBuilder
  }

  process
  {
    $null = $sb.AppendLine($Text)
  }
  end
  {
    $text = $sb.ToString()

    $process = Start-Process notepad -PassThru
    $null = $process.WaitForInputIdle()


    $sig = '
      [DllImport("user32.dll", EntryPoint = "FindWindowEx")]public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
      [DllImport("User32.dll")]public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);
    '

    $type = Add-Type -MemberDefinition $sig -Name APISendMessage -PassThru
    $hwnd = $process.MainWindowHandle
    [IntPtr]$child = $type::FindWindowEx($hwnd, [IntPtr]::Zero, "Edit", $null)
    $null = $type::SendMessage($child, 0x000C, 0, $text)
  }
}
```

这是它的使用方法：

```powershell
PS> Get-Service | Out-Notepad

PS> Get-Service | Out-String | Out-Notepad 
```

这两行代码，都能打开一个全新的 Notepad 实例，所有服务信息都写入 Notepad。请注意它们的不同：第一行代码创建一个对象名称的列表。如果您希望对象的显示像在 PowerShell 中那样详细，请确保将他们通过管道送给 Notepad 之前先将它们用管道送给 `Out-String`。

<!--本文国际来源：[Out-Notepad: Send Information to Notepad](http://community.idera.com/powershell/powertips/b/tips/posts/out-notepad-send-information-to-notepad)-->

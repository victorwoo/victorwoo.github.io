---
layout: post
date: 2016-02-11 12:00:00
title: "PowerShell 技能连载 - 发送文本到记事本"
description: PowerTip of the Day - Send Text to Notepad
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
记事本可以用来显示文本结果。通常，您需要将文本保存到文件，然后用记事本打开该文件。不过还有一个更好的办法：打开一个空白的记事本，然后用 Windows 消息直接把文本发送到未命名的记事本编辑器中。

这个函数称为 `Out-Notepad`。无论您传给这个函数什么文本，它都会在记事本的一个未命名实例中显示：

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

这是一些示例调用：

    PS C:\> Get-Content $env:windir\system32\drivers\etc\hosts | Out-Notepad

    PS C:\> Get-Process | Out-String | Out-Notepad 


<!--本文国际来源：[Send Text to Notepad](http://community.idera.com/powershell/powertips/b/tips/posts/send-text-to-notepad)-->

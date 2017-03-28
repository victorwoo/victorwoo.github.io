layout: post
date: 2015-05-29 11:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 的帮助窗口作为通用输出"
description: "PowerTip of the Day - Using PowerShell’s Help Window for General Output"
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
要显示文本信息，您当然可以启动 noteapd.exe，并且用编辑器来显示文本。不过，在编辑器中显示文本并不是一个好主意，如果您不希望文本被改变。

PowerShell 给我们带来了一个很棒的窗体，用来显示一小段或者中等长度的文本：内置的帮助窗口。

通过一些调整，该窗口可以重新编程，显示任意的文本信息。而且，您可以使用内置的全文搜索功能在您的文本中导航，甚至可以根据你的喜好设置前景色和背景色。

只需要将任意的文本通过管道传递给 `Out-Window`，并且根据需要可选地指定颜色、搜索词和标题。以下是 `Out-Window` 函数：

    function Out-Window
    {
      param
      (
        [String]
        $Title = 'PowerShell Output',
    
        [String]
        $FindText = '',
    
        [String]
        $ForegroundColor = 'Black',
    
        [String]
        $BackgroundColor = 'White'
      )
      
      # take all pipeline input:
      $allData = @($Input)
      
      if ($allData.Count -gt 0)
      {
        # open window in new thread to keep PS responsive
        $code = {
          param($textToDisplay, $FindText, $Title, $ForegroundColor, $BackgroundColor)
    
          $dialog = (New-Object –TypeName Microsoft.Management.UI.HelpWindow($textToDisplay))
          $dialog.Title = $Title
          $type = $dialog.GetType()
          $field = $type.GetField('Settings', 'NonPublic,Instance')
          $button = $field.GetValue($dialog)
          $button.Visibility = 'Collapsed'
          $dialog.Show()
          $dialog.Hide()
          $field = $type.GetField('Find', 'NonPublic,Instance')
          $textbox = $field.GetValue($dialog)
          $textbox.Text = $FindText
          $field = $type.GetField('HelpText', 'NonPublic,Instance')
          $RTB = $field.GetValue($dialog)
          $RTB.Background = $BackgroundColor
          $RTB.Foreground = $ForegroundColor
          $method = $type.GetMethod('MoveToNextMatch', [System.Reflection.BindingFlags]'NonPublic,Instance')
          $method.Invoke($dialog, @($true))
          $dialog.ShowDialog()
        }
    
        $ps = [PowerShell]::Create()
        $newRunspace = [RunSpaceFactory]::CreateRunspace()
        $newRunspace.ApartmentState = 'STA'
        $newRunspace.Open()
    
        $ps.Runspace = $newRunspace
        $null = $ps.AddScript($code).AddArgument(($allData | Format-Table -AutoSize -Wrap | Out-String -Width 100)).AddArgument($FindText).AddArgument($Title).AddArgument($ForegroundColor).AddArgument($BackgroundColor)
        $null = $ps.BeginInvoke()
      }
    }

调用的示例如下：

    Get-Content C:\Windows\windowsupdate.log  |
      # limit to first 100 lines (help window is not designed to work with huge texts)
      Select-Object -First 100 |
      Out-Window -Find Success -Title 'My Output' -Background Blue -Foreground White

请记住两件事：

* 帮助窗口并不是设计为显示大量文本的。请确保使用该方法显示不超过几 KB 的文本。
* 这只是试验性的代码。它并没有清除 PowerShell 用来显示窗体所创建的线程。当您关闭该线程时，该 PowerShell 线程将保持在后台运行，直到您关闭 PowerShell。我们需要为帮助窗口关闭事件增加一个事件处理器。该事件处理器可以清理该 PowerShell 线程。

<!--more-->
本文国际来源：[Using PowerShell’s Help Window for General Output](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-s-help-window-for-general-output)

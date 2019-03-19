---
title: PowerShell ISE 4.0 完整快捷键清单
description: The Complete List of PowerShell ISE 4.0 Keyboard Shortcuts
date: 2017-06-03 13:34:54
tags: [powershell]
categories: [powershell]
---
PowerShell ISE 是编写 PowerShell 脚本最重要的环境。熟练掌握 ISE 的快捷键有以下好处：

1. 逼格高（这个很重要）
1. 提高效率
1. 预防腕管炎
1. ……（请自行脑补）

其实，所有快捷键的定义都在 ISE 的 `Microsoft.PowerShell.GPowerShell`（DLL）中。我们首先需要获取这个 DLL 的引用。

```powershell
PS> $gps = $psISE.GetType().Assembly
PS> $gps

GAC    Version        Location
---    -------        --------
True   v4.0.30319     C:\Windows\Microsoft.Net\assembly\GAC_MSIL\Microsoft.PowerShell.GPowerShell\...
```

然后我们可以获取这个程序集的资源列表：

```powershell
PS> $gps.GetManifestResourceNames()

Microsoft.PowerShell.GPowerShell.g.resources
GuiStrings.resources
```

然后我们创建一个 `ResourceManager` 对象来存取程序集中的资源。在构造函数中将需要打开的资源名（去掉 _.resources_ 扩展名）以及包含资源的程序集对象传给它。

```powershell
$rm = New-Object System.Resources.ResourceManager GuiStrings,$gps
```

剩下只要调用 `GetResourceSet()` 方法根据特定的文化信息获取资源。

```powershell
      $rs = $rm.GetResourceSet((Get-Culture),$true,$true)
      $rs

      Name                           Value
      ----                           -----
      SnippetToolTipPath             路径: {0}
      MediumSlateBlueColorName       中石板蓝色
    > EditorBoxSelectLineDownShor... Alt+Shift+Down
      NewRunspace                    新建 PowerShell 选项卡(_E)
    > EditorSelectToPreviousChara... Shift+Left
    > RemoveAllBreakpointsShortcut   Ctrl+Shift+F9
      SaveScriptQuestion             是否保存 {0}?
```

查看输出结果，我们可以发现包含“>”的几行类似按键组合信息。如果您仔细查看输出结果，将会发现规律是 `Name` 以 `Shortcut` 结尾（有可能包含数字），以及以 `F` 开头加 1 至 2 位数字并带有 `Keyboard` 关键字的。通过下面一行代码，我们可以过滤出所有和键盘有关系的项目并对它们进行排序。

```powershell
$rs | where Name -match 'Shortcut\d?$|^F\d+Keyboard' | Sort-Object Value
```

以下是完整的代码片段和完整的结果：

```powershell
$gps = $psISE.GetType().Assembly
$rm = New-Object System.Resources.ResourceManager GuiStrings,$gps
$rs = $rm.GetResourceSet((Get-Culture),$true,$true)
$rs | where Name -match 'Shortcut\d?$|^F\d+Keyboard' | Sort-Object Value | Format-Table -AutoSize

Name                                            Value
----                                            -----
EditorUndoShortcut2                             Alt+Backspace
EditorSelectNextSiblingShortcut                 Alt+Down
ExitShortcut                                    Alt+F4
EditorSelectEnclosingShortcut                   Alt+Left
EditorSelectFirstChildShortcut                  Alt+Right
EditorRedoShortcut2                             Alt+Shift+Backspace
EditorBoxSelectLineDownShortcut                 Alt+Shift+Down
ToggleHorizontalAddOnPaneShortcut               Alt+Shift+H
EditorBoxSelectToPreviousCharacterShortcut      Alt+Shift+Left
EditorBoxSelectToNextCharacterShortcut          Alt+Shift+Right
EditorTransposeLineShortcut                     Alt+Shift+T
EditorBoxSelectLineUpShortcut                   Alt+Shift+Up
ToggleVerticalAddOnPaneShortcut                 Alt+Shift+V
EditorSelectPreviousSiblingShortcut             Alt+Up
ShowScriptPaneTopShortcut                       Ctrl+1
ShowScriptPaneRightShortcut                     Ctrl+2
ShowScriptPaneMaximizedShortcut                 Ctrl+3
EditorSelectAllShortcut                         Ctrl+A
ZoomIn1Shortcut                                 Ctrl+Add
EditorMoveCurrentLineToBottomShortcut           Ctrl+Alt+End
EditorMoveCurrentLineToTopShortcut              Ctrl+Alt+Home
EditorDeleteWordToLeftShortcut                  Ctrl+Backspace
StopExecutionShortcut                           Ctrl+Break
StopAndCopyShortcut                             Ctrl+C
GoToConsoleShortcut                             Ctrl+D
EditorDeleteWordToRightShortcut                 Ctrl+Del
EditorScrollDownAndMoveCaretIfNecessaryShortcut Ctrl+Down
EditorMoveToEndOfDocumentShortcut               Ctrl+End
FindShortcut                                    Ctrl+F
ShowCommandShortcut                             Ctrl+F1
CloseScriptShortcut                             Ctrl+F4
GoToLineShortcut                                Ctrl+G
ReplaceShortcut                                 Ctrl+H
EditorMoveToStartOfDocumentShortcut             Ctrl+Home
GoToEditorShortcut                              Ctrl+I
Copy2Shortcut                                   Ctrl+Ins
ShowSnippetShortcut                             Ctrl+J
EditorMoveToPreviousWordShortcut                Ctrl+Left
ToggleOutliningExpansionShortcut                Ctrl+M
ZoomOut3Shortcut                                Ctrl+Minus
NewScriptShortcut                               Ctrl+N
OpenScriptShortcut                              Ctrl+O
GoToMatchShortcut                               Ctrl+Oem6
ZoomIn3Shortcut                                 Ctrl+Plus
ToggleScriptPaneShortcut                        Ctrl+R
EditorMoveToNextWordShortcut                    Ctrl+Right
SaveScriptShortcut                              Ctrl+S
ZoomIn2Shortcut                                 Ctrl+Shift+Add
GetCallStackShortcut                            Ctrl+Shift+D
EditorSelectToEndOfDocumentShortcut             Ctrl+Shift+End
RemoveAllBreakpointsShortcut                    Ctrl+Shift+F9
HideHorizontalAddOnToolShortcut                 Ctrl+Shift+H
EditorSelectToStartOfDocumentShortcut           Ctrl+Shift+Home
ListBreakpointsShortcut                         Ctrl+Shift+L
EditorSelectToPreviousWordShortcut              Ctrl+Shift+Left
ZoomOut4Shortcut                                Ctrl+Shift+Minus
StartPowerShellShortcut                         Ctrl+Shift+P
ZoomIn4Shortcut                                 Ctrl+Shift+Plus
NewRemotePowerShellTabShortcut                  Ctrl+Shift+R
EditorSelectToNextWordShortcut                  Ctrl+Shift+Right
ZoomOut2Shortcut                                Ctrl+Shift+Subtract
EditorMakeUppercaseShortcut                     Ctrl+Shift+U
HideVerticalAddOnToolShortcut                   Ctrl+Shift+V
IntellisenseShortcut                            Ctrl+Space
ZoomOut1Shortcut                                Ctrl+Subtract
NewRunspaceShortcut                             Ctrl+T
EditorMakeLowercaseShortcut                     Ctrl+U
EditorScrollUpAndMoveCaretIfNecessaryShortcut   Ctrl+Up
Paste1Shortcut                                  Ctrl+V
CloseRunspaceShortcut                           Ctrl+W
Cut1Shortcut                                    Ctrl+X
EditorRedoShortcut1                             Ctrl+Y
EditorUndoShortcut1                             Ctrl+Z
F1KeyboardDisplayName                           F1
HelpShortcut                                    F1
StepOverShortcut                                F10
F10KeyboardDisplayName                          F10
StepIntoShortcut                                F11
F11KeyboardDisplayName                          F11
F12KeyboardDisplayName                          F12
F2KeyboardDisplayName                           F2
FindNextShortcut                                F3
F3KeyboardDisplayName                           F3
F4KeyboardDisplayName                           F4
RunScriptShortcut                               F5
F5KeyboardDisplayName                           F5
F6KeyboardDisplayName                           F6
F7KeyboardDisplayName                           F7
RunSelectionShortcut                            F8
F8KeyboardDisplayName                           F8
F9KeyboardDisplayName                           F9
ToggleBreakpointShortcut                        F9
EditorDeleteCharacterToLeftShortcut             Shift+Backspace
Cut2Shortcut                                    Shift+Del
EditorSelectLineDownShortcut                    Shift+Down
EditorSelectToEndOfLineShortcut                 Shift+End
EditorInsertNewLineShortcut                     Shift+Enter
StepOutShortcut                                 Shift+F11
FindPreviousShortcut                            Shift+F3
StopDebuggerShortcut                            Shift+F5
EditorSelectToStartOfLineShortcut               Shift+Home
Paste2Shortcut                                  Shift+Ins
EditorSelectToPreviousCharacterShortcut         Shift+Left
EditorSelectPageDownShortcut                    Shift+PgDn
EditorSelectPageUpShortcut                      Shift+PgUp
EditorSelectToNextCharacterShortcut             Shift+Right
EditorSelectLineUpShortcut                      Shift+Up
```

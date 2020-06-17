---
layout: post
date: 2020-06-11 00:00:00
title: "PowerShell 技能连载 - 自学习参数完成"
description: PowerTip of the Day - Auto-Learning Argument Completion
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
对于用户而言，参数完成非常棒，因为始终建议使用有效的参数。许多内置的 PowerShell 命令带有参数完成功能。当您输入以下内容时，您可以看到该效果：

```powershell
PS> Get-EventLog -LogName
```

在 `-LogName` 之后输入一个空格，以在 PowerShell ISE 编辑器中触发自动参数完成。在 PowerShell 控制台中，按 TAB 键。而在 Visual Studio Code 中，按 CTRL + SPACE。`Get-EventLog` 会自动建议计算机上实际存在的日志的日志名称。

您可以将相同的参数完成功能添加到自己的函数参数中。在前面的技巧中，我们解释了如何添加静态建议。现在让我们来看看如何添加自学习参数完成功能！

假设您使用 `-Co​​mputerName` 参数编写 PowerShell 函数。为了使您的函数更易于使用，请添加参数完成，以便自动向用户建议计算机名称和 IP 地址。

显然，您无法知道对用户很重要的计算机名称和IP地址，因此您无法添加静态列表。而是使用两个自定义属性：

```powershell
# define [AutoLearn()]
class AutoLearnAttribute : System.Management.Automation.ArgumentTransformationAttribute
{
    # define path to store hint lists
    [string]$Path = "$env:temp\hints"

    # define ID to manage multiple hint lists
    [string]$Id = 'default'

    # define prefix character used to delete the hint list
    [char]$ClearKey = '!'

    # define parameterless constructor
    AutoLearnAttribute() : base()
    {}

    # define constructor with parameter for ID
    AutoLearnAttribute([string]$Id) : base()
    {
        $this.Id = $Id
    }

    # Transform() is called whenever there is a variable or parameter assignment,
    # and returns the value that is actually assigned
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData)
    {
        # make sure the folder with hints exists
        $exists = Test-Path -Path $this.Path
        if (!$exists) { $null = New-Item -Path $this.Path -ItemType Directory }

        # create a filename for hint list
        $filename = '{0}.hint' -f $this.Id
        $hintPath = Join-Path -Path $this.Path -ChildPath $filename

        # use a hash table to keep hint list
        $hints = @{}

        # read hint list if it exists
        $exists = Test-Path -Path $hintPath
        if ($exists)
        {
            Get-Content -Path $hintPath -Encoding Default |
                # remove leading and trailing blanks
                ForEach-Object { $_.Trim() } |
                # remove empty lines
                Where-Object { ![string]::IsNullOrEmpty($_) } |
                # add to hash table
                ForEach-Object {
                # value is not used, set it to $true
                $hints[$_] = $true
                }
        }

        # does the user input start with the clearing key?
        if ($inputData.StartsWith($this.ClearKey))
        {
            # remove the prefix
            $inputData = $inputData.SubString(1)

            # clear the hint list
            $hints.Clear()
        }

        # add new value to hint list
        if(![string]::IsNullOrWhiteSpace($inputData))
        {
            $hints[$inputData] = $true
        }
        # save hints list
        $hints.Keys | Sort-Object | Set-Content -Path $hintPath -Encoding Default

        # return the user input (if there was a clearing key at its start,
        # it is now stripped)
        return $inputData
    }
}

# define [AutoComplete()]
class AutoCompleteAttribute : System.Management.Automation.ArgumentCompleterAttribute
{
    # define path to store hint lists
    [string]$Path = "$env:temp\hints"

    # define ID to manage multiple hint lists
    [string]$Id = 'default'

    # define parameterless constructor
    AutoCompleteAttribute() : base([AutoCompleteAttribute]::_createScriptBlock($this))
    {}

    # define constructor with parameter for ID
    AutoCompleteAttribute([string]$Id) : base([AutoCompleteAttribute]::_createScriptBlock($this))
    {
        $this.Id = $Id
    }

    # create a static helper method that creates the script block that the base constructor needs
    # this is necessary to be able to access the argument(s) submitted to the constructor
    # the method needs a reference to the object instance to (later) access its optional parameters
    hidden static [ScriptBlock] _createScriptBlock([AutoCompleteAttribute] $instance)
    {
    $scriptblock = {
        # receive information about current state
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        # create filename for hint list
        $filename = '{0}.hint' -f $instance.Id
        $hintPath = Join-Path -Path $instance.Path -ChildPath $filename

        # use a hash table to keep hint list
        $hints = @{}

        # read hint list if it exists
        $exists = Test-Path -Path $hintPath
        if ($exists)
        {
            Get-Content -Path $hintPath -Encoding Default |
                # remove leading and trailing blanks
                ForEach-Object { $_.Trim() } |
                # remove empty lines
                Where-Object { ![string]::IsNullOrEmpty($_) } |
                # filter completion items based on existing text
                Where-Object { $_.LogName -like "$wordToComplete*" } |
                # create argument completion results
                Foreach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
        }
    }.GetNewClosure()
    return $scriptblock
    }
}
```

这就是您想要为自己的 PowerShell 函数添加尽可能多的自学习自动完成功能所需要的全部。

这是一个利用这两个属性的新的 PowerShell 函数：

```powershell
function Connect-MyServer
{
    param
    (
        [string]
        [Parameter(Mandatory)]
        # auto-learn user names to user.hint
        [AutoLearn('user')]
        # auto-complete user names from user.hint
        [AutoComplete('user')]
        $UserName,

        [string]
        [Parameter(Mandatory)]
        # auto-learn computer names to server.hint
        [AutoLearn('server')]
        # auto-complete computer names from server.hint
        [AutoComplete('server')]
        $ComputerName
    )

    "Hello $Username, connecting you to $ComputerName"
}
```

运行代码后，会产生一个新的 `Connect-MyServer` 命令。`-UserName` 和 `-ComputerName` 参数均提供自学习自动补全功能：每当您为这些参数之一分配值时，该参数都会“记住”该参数，并在下次向您建议记住的值。

首次调用 `Connect-MyServer` 时，没有参数完成。再次调用它时，系统会建议您以前的输入，并且随着时间的推移，您的函数会“学习”对用户重要的参数。

这两个参数使用独立的建议。只需确保在两个属性中都为建议列表提供名称即可。在上面的示例中，`-UserName` 参数使用 "user" 建议列表，而 `-ComputerName` 参数使用 "server" 建议列表。

如果要清除有关参数的建议，请在参数前添加一个感叹号。该调用将清除 `-ComputerName` 参数的建议：

```powershell
PS> Connect-MyServer -UserName tobias -ComputerName !server12
Hello tobias, connecting you to server12
```

重要说明：由于 PowerShell 中存在一个长期存在的错误，参数定义完成在定义实际功能的编辑器脚本窗格中不起作用。它始终可以在交互式控制台（这是最重要的用例）和任何其他脚本窗格中使用。

有关此处使用的技术的更多详细信息，请访问 [https://powershell.one/powershell-internals/attributes/custom-attributes](https://powershell.one/powershell-internals/attributes/custom-attributes)。

<!--本文国际来源：[Auto-Learning Argument Completion](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/auto-learning-argument-completion)-->


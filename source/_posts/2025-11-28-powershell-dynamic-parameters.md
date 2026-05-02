---
layout: post
date: 2025-11-28 08:00:00
updated: 2025-11-28 08:00:00
title: "PowerShell 技能连载 - 动态参数"
description: PowerTip of the Day - Dynamic Parameters in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dynamic-parameters
- advanced-function
- runtime
- parameters
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## 背景

在编写 PowerShell 高级函数时，我们通常使用 `param()` 块声明静态参数。这些参数在函数定义时就已确定，无论调用时传入什么值，参数集合始终不变。然而，有些场景需要根据运行时条件动态地添加参数——例如根据用户选择的路径类型显示不同的验证集，或者仅在指定了某个开关参数后才暴露额外的配置选项。

PowerShell 提供了"动态参数"（Dynamic Parameters）机制来满足这一需求。动态参数是通过实现 `IDynamicParameters` 接口或使用 `<DynamicParam>` 块来定义的，它们在运行时根据函数内其他参数的值决定是否出现。这意味着用户在 Tab 补全时只会看到当前上下文中有效的参数，从而获得更精准的智能提示。

本文将从基础到进阶，逐步介绍如何在 PowerShell 中创建和使用动态参数，涵盖 `[DynamicParam()]` 块的写法、`RuntimeDefinedParameter` 对象的构造、参数验证属性的添加，以及在高级函数中结合 `$PSBoundParameters` 判断上下文的实战技巧。

## 基础：第一个动态参数

动态参数的核心是 `[DynamicParam()]` 块。在这个块中，我们使用 `RuntimeDefinedParameterDictionary` 和 `RuntimeDefinedParameter` 来构造参数。下面是一个最简单的例子：当用户指定了 `-Path` 参数后，动态暴露一个 `-Encoding` 参数供选择。

```powershell
function Get-FileContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # 定义动态参数块
    DynamicParam {
        # 创建参数字典
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # 只有当 Path 被指定时，才添加 Encoding 参数
        if ($PSBoundParameters.ContainsKey('Path')) {
            # 定义验证集
            $validateSet = [System.Management.Automation.ValidateSetAttribute]::new(
                @('UTF8', 'ASCII', 'Unicode', 'UTF32')
            )

            # 创建参数属性集合
            $attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $attributes.Add([System.Management.Automation.ParameterAttribute]::new())
            $attributes.Add($validateSet)

            # 构造 RuntimeDefinedParameter
            $encodingParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                'Encoding',
                [string],
                $attributes
            )

            $paramDictionary.Add('Encoding', $encodingParam)
        }

        return $paramDictionary
    }

    Process {
        # 从动态参数中取值
        $encoding = if ($PSBoundParameters.ContainsKey('Encoding')) {
            $PSBoundParameters['Encoding']
        } else {
            'UTF8'
        }

        Write-Output "正在以 $encoding 编码读取文件: $Path"

        if (Test-Path -Path $Path) {
            $content = Get-Content -Path $Path -Encoding $encoding -Raw
            Write-Output "文件大小: $($content.Length) 字符"
        } else {
            Write-Warning "文件不存在: $Path"
        }
    }
}

# 调用示例
Get-FileContent -Path "C:\temp\test.txt" -Encoding UTF8
```

执行结果示例：

```text
正在以 UTF8 编码读取文件: C:\temp\test.txt
文件大小: 2048 字符
```

这段代码的关键在于 `DynamicParam` 块。它通过 `$PSBoundParameters` 检查 `-Path` 是否已被赋值，只有在确认后才创建 `-Encoding` 参数。`RuntimeDefinedParameter` 的构造函数接收三个参数：参数名、类型和属性集合。我们为它添加了 `ParameterAttribute`（使其成为函数参数）和 `ValidateSetAttribute`（限制可选值）。在 `Process` 块中，同样通过 `$PSBoundParameters` 来获取动态参数的值。

## 进阶：根据参数值动态生成验证集

静态的 `ValidateSet` 只能硬编码可选值，而动态参数的真正威力在于可以根据运行时数据生成验证集。下面的例子演示了：当用户输入一个目录路径后，动态参数会扫描该目录下的子文件夹，并将其作为 `-SubFolder` 参数的可选值。

```powershell
function Get-ProjectArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    DynamicParam {
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # 获取 ProjectRoot 的值
        $projectRootValue = $PSBoundParameters['ProjectRoot']

        if ($projectRootValue -and (Test-Path -Path $projectRootValue -PathType Container)) {
            # 扫描目录下的子文件夹
            $subFolders = @(Get-ChildItem -Path $projectRootValue -Directory -ErrorAction SilentlyContinue)

            $folderNames = @()
            foreach ($folder in $subFolders) {
                $folderNames += $folder.Name
            }

            if ($folderNames.Count -gt 0) {
                # 用扫描结果构造验证集
                $validateSet = [System.Management.Automation.ValidateSetAttribute]::new($folderNames)

                $attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                $paramAttr = [System.Management.Automation.ParameterAttribute]::new()
                $paramAttr.Mandatory = $true
                $paramAttr.HelpMessage = "选择项目中的子目录"
                $attributes.Add($paramAttr)
                $attributes.Add($validateSet)

                $subFolderParam = [System.Management.Automation.RuntimeDefinedParameter]::new(
                    'SubFolder',
                    [string],
                    $attributes
                )

                $paramDictionary.Add('SubFolder', $subFolderParam)
            }
        }

        return $paramDictionary
    }

    Process {
        $subFolder = $PSBoundParameters['SubFolder']
        $targetPath = Join-Path -Path $ProjectRoot -ChildPath $subFolder

        Write-Output "项目根目录: $ProjectRoot"
        Write-Output "选择子目录: $subFolder"
        Write-Output "完整路径:   $targetPath"
        Write-Output ""

        $files = @(Get-ChildItem -Path $targetPath -File -ErrorAction SilentlyContinue)
        Write-Output "该目录包含 $($files.Count) 个文件:"

        foreach ($file in $files) {
            $sizeKB = [math]::Round($file.Length / 1KB, 2)
            Write-Output ("  {0,-40} {1,10} KB" -f $file.Name, $sizeKB)
        }
    }
}

# 调用示例（假设 C:\MyProject 下有 src、docs、tests 子目录）
Get-ProjectArtifact -ProjectRoot "C:\MyProject" -SubFolder src
```

执行结果示例：

```text
项目根目录: C:\MyProject
选择子目录: src
完整路径:   C:\MyProject\src

该目录包含 5 个文件:
  index.ts                                   2.34 KB
  utils.ts                                   1.87 KB
  config.json                                0.52 KB
  main.ts                                    4.15 KB
  types.d.ts                                 0.98 KB
```

这个例子展示了动态参数的核心优势——Tab 补全会根据实际文件系统状态提供候选项。当你输入 `-SubFolder` 后按 Tab，PowerShell 会自动列出 `src`、`docs`、`tests` 等实际存在的目录名。代码中通过 `Get-ChildItem -Directory` 获取子目录列表，再将名称数组传给 `ValidateSetAttribute`，实现运行时验证集的动态生成。注意 `Mandatory = $true` 的设置方式——通过操作 `ParameterAttribute` 对象的属性来控制参数行为。

## 实战：构建条件化的动态参数集

在实际开发中，我们经常需要根据多个条件组合来决定暴露哪些参数。例如，一个数据导出工具可能需要根据 `-Format` 参数的值（CSV、JSON、XML）来动态显示不同的配置选项。下面演示如何构建多条件联动的动态参数集。

```powershell
function Export-DataReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('CSV', 'JSON', 'XML')]
        [string]$Format,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    DynamicParam {
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $formatValue = $PSBoundParameters['Format']

        # 创建动态参数的辅助函数
        function Add-DynamicParam {
            param(
                [string]$Name,
                [type]$Type,
                [System.Collections.ObjectModel.Collection[System.Attribute]]$Attributes
            )
            $rp = [System.Management.Automation.RuntimeDefinedParameter]::new($Name, $Type, $Attributes)
            $paramDictionary.Add($Name, $rp)
        }

        function New-ParamAttributes {
            param([bool]$Mandatory = $false, [string]$HelpMessage = '')
            $attrs = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $p = [System.Management.Automation.ParameterAttribute]::new()
            $p.Mandatory = $Mandatory
            if ($HelpMessage) { $p.HelpMessage = $HelpMessage }
            $attrs.Add($p)
            return $attrs
        }

        # CSV 格式的专有参数
        if ($formatValue -eq 'CSV') {
            $csvAttrs = New-ParamAttributes -Mandatory $false -HelpMessage 'CSV 分隔符'
            $csvAttrs.Add([System.Management.Automation.ValidateSetAttribute]::new(@(',', ';', '`t', '|')))
            Add-DynamicParam -Name 'Delimiter' -Type [string] -Attributes $csvAttrs

            $noHeaderAttrs = New-ParamAttributes -HelpMessage '是否包含表头'
            Add-DynamicParam -Name 'NoHeader' -Type [switch] -Attributes $noHeaderAttrs
        }

        # JSON 格式的专有参数
        if ($formatValue -eq 'JSON') {
            $indentAttrs = New-ParamAttributes -HelpMessage 'JSON 缩进层级'
            $indentAttrs.Add([System.Management.Automation.ValidateRangeAttribute]::new(0, 8))
            Add-DynamicParam -Name 'Indent' -Type [int] -Attributes $indentAttrs

            $compressAttrs = New-ParamAttributes -HelpMessage '压缩输出'
            Add-DynamicParam -Name 'Compress' -Type [switch] -Attributes $compressAttrs
        }

        # XML 格式的专有参数
        if ($formatValue -eq 'XML') {
            $rootAttrs = New-ParamAttributes -Mandatory $false -HelpMessage 'XML 根节点名称'
            Add-DynamicParam -Name 'RootName' -Type [string] -Attributes $rootAttrs

            $indentXmlAttrs = New-ParamAttributes -HelpMessage 'XML 缩进'
            Add-DynamicParam -Name 'IndentXml' -Type [switch] -Attributes $indentXmlAttrs
        }

        return $paramDictionary
    }

    Process {
        # 构造模拟数据
        $data = @(
            [PSCustomObject]@{ Name = '服务器A'; IP = '192.168.1.10'; Status = '运行中'; CPU = '45%' }
            [PSCustomObject]@{ Name = '服务器B'; IP = '192.168.1.11'; Status = '已停止'; CPU = '0%' }
            [PSCustomObject]@{ Name = '服务器C'; IP = '192.168.1.12'; Status = '运行中'; CPU = '78%' }
        )

        Write-Output "导出格式: $Format"
        Write-Output "输出路径: $OutputPath"

        # 获取所有动态参数的值
        $delimiter = if ($PSBoundParameters.ContainsKey('Delimiter')) { $PSBoundParameters['Delimiter'] } else { ',' }
        $noHeader = $PSBoundParameters.ContainsKey('NoHeader') -and $PSBoundParameters['NoHeader'].IsPresent
        $indent = if ($PSBoundParameters.ContainsKey('Indent')) { $PSBoundParameters['Indent'] } else { 2 }
        $compress = $PSBoundParameters.ContainsKey('Compress') -and $PSBoundParameters['Compress'].IsPresent
        $rootName = if ($PSBoundParameters.ContainsKey('RootName')) { $PSBoundParameters['RootName'] } else { 'Data' }
        $indentXml = $PSBoundParameters.ContainsKey('IndentXml') -and $PSBoundParameters['IndentXml'].IsPresent

        switch ($Format) {
            'CSV' {
                Write-Output "分隔符: $delimiter"
                Write-Output "包含表头: $(-not $noHeader)"
                Write-Output ""
                $csvLines = @()
                if (-not $noHeader) {
                    $csvLines += ($data[0].PSObject.Properties.Name -join $delimiter)
                }
                foreach ($item in $data) {
                    $values = @()
                    foreach ($prop in $item.PSObject.Properties) {
                        $values += $prop.Value
                    }
                    $csvLines += ($values -join $delimiter)
                }
                $csvLines | Out-String | Write-Output
            }
            'JSON' {
                Write-Output "缩进层级: $indent"
                Write-Output "压缩模式: $compress"
                Write-Output ""
                $jsonDepth = 5
                if ($compress) {
                    $data | ConvertTo-Json -Compress -Depth $jsonDepth | Write-Output
                } else {
                    $data | ConvertTo-Json -Depth $jsonDepth | Write-Output
                }
            }
            'XML' {
                Write-Output "根节点: $rootName"
                Write-Output "缩进: $indentXml"
                Write-Output ""
                foreach ($item in $data) {
                    $line = "<Item"
                    foreach ($prop in $item.PSObject.Properties) {
                        $line += " $($prop.Name)=`"$($prop.Value)`""
                    }
                    $line += " />"
                    Write-Output $line
                }
            }
        }

        Write-Output ""
        Write-Output "数据已准备完毕，共 $($data.Count) 条记录"
    }
}

# 调用示例：CSV 格式
Export-DataReport -Format CSV -OutputPath "C:\Reports\servers.csv" -Delimiter ','

Write-Output "`n" + ("=" * 60) + "`n"

# 调用示例：JSON 格式
Export-DataReport -Format JSON -OutputPath "C:\Reports\servers.json" -Indent 4 -Compress:$false
```

执行结果示例：

```text
导出格式: CSV
输出路径: C:\Reports\servers.csv
分隔符: ,
包含表头: True

Name,IP,Status,CPU
服务器A,192.168.1.10,运行中,45%
服务器B,192.168.1.11,已停止,0%
服务器C,192.168.1.12,运行中,78%

数据已准备完毕，共 3 条记录


============================================================

导出格式: JSON
输出路径: C:\Reports\servers.json
缩进层级: 4
压缩模式: False

[
    {
        "Name": "服务器A",
        "IP": "192.168.1.10",
        "Status": "运行中",
        "CPU": "45%"
    },
    {
        "Name": "服务器B",
        "IP": "192.168.1.11",
        "Status": "已停止",
        "CPU": "0%"
    },
    {
        "Name": "服务器C",
        "IP": "192.168.1.12",
        "Status": "运行中",
        "CPU": "78%"
    }
]

数据已准备完毕，共 3 条记录
```

这段代码根据 `$Format` 的值动态注册不同的参数组。CSV 格式下出现 `-Delimiter` 和 `-NoHeader`；JSON 格式下出现 `-Indent` 和 `-Compress`；XML 格式下出现 `-RootName` 和 `-IndentXml`。为了提高代码可读性，我们在 `DynamicParam` 块内定义了两个辅助函数 `Add-DynamicParam` 和 `New-ParamAttributes`，将样板代码封装起来。在 `Process` 块中，通过 `$PSBoundParameters.ContainsKey()` 逐一检查每个动态参数是否被传入，并提供合理的默认值。注意 switch 类型的动态参数需要通过 `.IsPresent` 来判断。

## 注意事项

1. **`$PSBoundParameters` 在 DynamicParam 块中是只读快照**。`DynamicParam` 块执行时，PowerShell 尚未完成所有参数的绑定，因此 `$PSBoundParameters` 只包含在该时刻已经绑定的参数。如果函数有多个参数且存在依赖关系，务必考虑参数解析的顺序——位置参数先于命名参数被绑定。

2. **动态参数不会出现在 `Get-Help` 的输出中**。由于动态参数在运行时才生成，`Get-Help` 无法静态分析到它们。如果需要让用户了解动态参数的存在，应在函数的 `.EXTERNALHELP` 或基于注释的帮助中手动记录，或者在 `ParameterAttribute` 的 `HelpMessage` 属性中写清楚说明文字。

3. **`ValidateSet` 的候选项不宜过多**。当动态参数基于文件系统或数据库查询生成验证集时，如果候选项数量达到数百甚至数千，Tab 补全体验会变得很差，验证集的构造也会带来性能开销。建议对候选项数量设置上限，或者改用 `ArgumentCompleter` 进行异步补全。

4. **动态参数的类型必须精确匹配**。`RuntimeDefinedParameter` 的第二个参数是参数的 .NET 类型。如果你希望接受数组输入，应使用 `[string[]]` 而非 `[string]`；如果是开关参数，必须使用 `[switch]` 类型，否则参数绑定器无法正确解析 `-ParamName` 这种无值的写法。

5. **在 `Begin`、`Process`、`End` 块中访问动态参数需要通过 `$PSBoundParameters`**。动态参数不会像静态参数那样自动赋值给同名变量。你需要手动从 `$PSBoundParameters` 字典中提取值，或者使用 `$MyInvocation.MyCommand.Parameters` 来遍历所有参数（包括动态参数）的元数据。

6. **调试动态参数时善用 `Get-Command -Syntax`**。在控制台中输入 `Get-Command Export-DataReport -Syntax` 可以看到当前函数的完整参数签名，包括动态参数。但由于动态参数依赖于运行时状态，你无法在不提供前置参数的情况下看到动态参数。因此，在开发阶段，建议在 `DynamicParam` 块中加入 `Write-Debug` 语句，通过 `-Debug` 开关观察参数字典的构建过程。

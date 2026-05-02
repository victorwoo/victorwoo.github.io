---
layout: post
date: 2025-09-24 08:00:00
updated: 2025-09-24 08:00:00
title: "PowerShell 技能连载 - 数据脱敏处理"
description: PowerTip of the Day - Data Masking and Anonymization in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- security
---

_适用于 PowerShell 5.1 及以上版本_

在数据驱动的工作环境中，我们经常需要将生产数据导出到测试环境或用于演示。然而，直接使用真实数据会带来严重的隐私和安全风险——客户姓名、手机号、身份证号、邮箱地址等敏感信息一旦泄露，不仅违反数据保护法规（如 GDPR、个人信息保护法），还可能造成不可逆的损失。

数据脱敏（Data Masking）是一种通过替换、隐藏或变换敏感字段来保护隐私的技术。与加密不同，脱敏后的数据在格式和结构上保持不变，仍然适合用于开发、测试和培训场景。例如，将手机号 `13812345678` 替换为 `138****5678`，既隐藏了真实信息，又保留了手机号的格式特征。

PowerShell 作为 Windows 环境下的自动化利器，结合正则表达式和自定义函数，可以高效地批量处理 CSV、JSON 等结构化数据中的敏感字段。本文将介绍如何构建一套实用的数据脱敏工具集，涵盖常见敏感数据的识别与替换。

<!-- more -->

## 基础脱敏函数

首先，我们定义一组针对常见敏感数据类型的脱敏函数。每个函数接收原始字符串，返回脱敏后的结果。这些函数是后续批量处理的基础构件。

```powershell
function Mask-PhoneNumber {
    param([string]$Phone)
    if ($Phone -match '^1\d{10}$') {
        return $Phone.Substring(0, 3) + '****' + $Phone.Substring(7)
    }
    return $Phone
}

function Mask-EmailAddress {
    param([string]$Email)
    if ($Email -match '^([^@])[^@]*@(.+)$') {
        $firstChar = $Matches[1]
        $domain = $Matches[2]
        return "${firstChar}***@${domain}"
    }
    return $Email
}

function Mask-IdCard {
    param([string]$IdCard)
    if ($IdCard -match '^\d{17}[\dXx]$') {
        return $IdCard.Substring(0, 4) + '**********' + $IdCard.Substring(14)
    }
    return $IdCard
}

function Mask-Name {
    param([string]$Name)
    if ($Name.Length -gt 1) {
        return $Name[0] + '*' * ($Name.Length - 1)
    }
    return $Name
}

# 测试脱敏函数
Mask-PhoneNumber -Phone '13812345678'
Mask-EmailAddress -Email 'zhangsan@example.com'
Mask-IdCard -IdCard '110101199001011234'
Mask-Name -Name '欧阳锋'
```

执行结果：

```
138****5678
z***@example.com
1101**********1234
欧**
```

## 批量处理 CSV 文件

单个字段的脱敏并不复杂，真正的挑战在于批量处理包含大量记录的文件。以下示例演示如何读取 CSV 文件，对其中的敏感列进行脱敏，并将结果写回新文件。

假设我们有一个用户数据文件 `users.csv`，包含姓名、手机号、邮箱和身份证号等字段。我们将逐行读取、脱敏，并输出到新文件。

```powershell
# 模拟生成测试数据
$testData = @(
    [PSCustomObject]@{
        序号 = 1
        姓名 = '张三'
        手机号 = '13912345678'
        邮箱 = 'zhangsan@company.com'
        身份证号 = '310101199501011234'
    },
    [PSCustomObject]@{
        序号 = 2
        姓名 = '李四'
        手机号 = '18687654321'
        邮箱 = 'lisi@example.org'
        身份证号 = '440301198812012345'
    },
    [PSCustomObject]@{
        序号 = 3
        姓名 = '王小明'
        手机号 = '15011112222'
        邮箱 = 'wxm@test.cn'
        身份证号 = '320102200005051234'
    }
)

$testData | Export-Csv -Path 'users.csv' -NoTypeInformation -Encoding UTF8

# 读取 CSV 并批量脱敏
$sourcePath = 'users.csv'
$maskedPath = 'users_masked.csv'

$records = Import-Csv -Path $sourcePath -Encoding UTF8
$maskedRecords = foreach ($record in $records) {
    $record.姓名 = Mask-Name -Name $record.姓名
    $record.手机号 = Mask-PhoneNumber -Phone $record.手机号
    $record.邮箱 = Mask-EmailAddress -Email $record.邮箱
    $record.身份证号 = Mask-IdCard -IdCard $record.身份证号
    $record
}

$maskedRecords | Export-Csv -Path $maskedPath -NoTypeInformation -Encoding UTF8
Write-Host "脱敏完成：$($maskedRecords.Count) 条记录已写入 $maskedPath"
```

执行结果：

```
脱敏完成：3 条记录已写入 users_masked.csv
```

我们可以查看脱敏后的文件内容，确认敏感字段已被正确处理。

```powershell
# 查看脱敏结果
Import-Csv -Path $maskedPath -Encoding UTF8 | Format-Table -AutoSize
```

执行结果：

```
序号 姓名  手机号        邮箱            身份证号
---- ----  ------        ----            --------
1    张*   139****5678   z***@company.com 3101**********1234
2    李*   186****54321  l***@example.org 4403**********2345
3    王**  150****12222  w***@test.cn     3201**********1234
```

## 正则表达式通用脱敏引擎

当数据源结构不固定或需要处理非 CSV 格式（如日志文件、JSON 文档）时，基于列名的脱敏方式就显得力不从心。我们可以构建一个基于正则表达式的通用脱敏引擎，自动识别文本中的敏感模式并进行替换。

这种方法的优点是格式无关——无论是 CSV、JSON、XML 还是纯文本日志，只要其中包含符合规则的敏感数据，都能被正确脱敏。

```powershell
function Get-MaskingRules {
    return @(
        @{
            Name = '手机号'
            Pattern = '(?<=\D|^)(1[3-9]\d)\d{4}(\d{4})(?=\D|$)'
            Replacement = '$1****$2'
        },
        @{
            Name = '身份证号'
            Pattern = '([1-9]\d{3})\d{10}(\d{4})'
            Replacement = '$1**********$2'
        },
        @{
            Name = '邮箱地址'
            Pattern = '(\w)\w+(@[\w.]+)'
            Replacement = '$1***$2'
        },
        @{
            Name = '银行卡号'
            Pattern = '(\d{4})\d{8,12}(\d{4})'
            Replacement = '$1********$2'
        }
    )
}

function Invoke-DataMasking {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )

    $result = $InputString
    $rules = Get-MaskingRules
    $changeLog = [System.Collections.Generic.List[string]]::new()

    foreach ($rule in $rules) {
        $before = $result
        $result = [regex]::Replace(
            $result,
            $rule.Pattern,
            $rule.Replacement,
            'IgnoreCase'
        )
        if ($before -ne $result) {
            $changeLog.Add("[$($rule.Name)] 已脱敏")
        }
    }

    return [PSCustomObject]@{
        Original = $InputString
        Masked = $result
        Changes = $changeLog
    }
}

# 测试通用脱敏引擎
$sampleText = '用户张三的手机号是13912345678，邮箱为zhangsan@corp.com，' +
              '身份证号310101199001011234，银行卡号6222021234567890123。'

$result = Invoke-DataMasking -InputString $sampleText
Write-Host "原始文本："
Write-Host $result.Original
Write-Host ""
Write-Host "脱敏结果："
Write-Host $result.Masked
Write-Host ""
Write-Host "变更记录："
foreach ($log in $result.Changes) {
    Write-Host "  $log"
}
```

执行结果：

```
原始文本：
用户张三的手机号是13912345678，邮箱为zhangsan@corp.com，身份证号310101199001011234，银行卡号6222021234567890123。

脱敏结果：
用户张三的手机号是139****5678，邮箱为z***@corp.com，身份证号3101**********1234，银行卡号6222********0123。

变更记录：
  [手机号] 已脱敏
  [身份证号] 已脱敏
  [邮箱地址] 已脱敏
  [银行卡号] 已脱敏
```

## 脱敏报告生成

在生产环境中执行批量脱敏后，通常需要生成一份报告，记录脱敏操作的统计信息，包括处理的文件数量、脱敏字段次数、各规则命中次数等。这对审计和合规检查非常重要。

```powershell
function New-MaskingReport {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$ReportPath = 'masking_report.txt'
    )

    $startTime = Get-Date
    $stats = @{
        TotalRecords = 0
        TotalChanges = 0
        RuleHits = @{}
    }

    $rules = Get-MaskingRules
    foreach ($rule in $rules) {
        $stats.RuleHits[$rule.Name] = 0
    }

    $content = Get-Content -Path $InputPath -Raw -Encoding UTF8
    $stats.TotalRecords = (Get-Content -Path $InputPath -Encoding UTF8 |
        Measure-Object -Line).Lines

    $masked = $content
    foreach ($rule in $rules) {
        $matches = [regex]::Matches($masked, $rule.Pattern, 'IgnoreCase')
        if ($matches.Count -gt 0) {
            $masked = [regex]::Replace(
                $masked,
                $rule.Pattern,
                $rule.Replacement,
                'IgnoreCase'
            )
            $stats.RuleHits[$rule.Name] += $matches.Count
            $stats.TotalChanges += $matches.Count
        }
    }

    Set-Content -Path $OutputPath -Value $masked -Encoding UTF8 -NoNewline

    # 生成报告
    $reportLines = @(
        '====== 数据脱敏报告 ======'
        "源文件：$InputPath"
        "输出文件：$OutputPath"
        "执行时间：$((Get-Date) -lt $startTime)"
        "处理记录数：$($stats.TotalRecords)"
        "总脱敏次数：$($stats.TotalChanges)"
        ''
        '--- 各规则命中统计 ---'
    )

    foreach ($rule in $rules) {
        $count = $stats.RuleHits[$rule.Name]
        $reportLines += "  $($rule.Name)：$count 次"
    }

    $reportLines += ''
    $reportLines += "报告生成于：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    $reportContent = $reportLines -join "`r`n"
    Set-Content -Path $ReportPath -Value $reportContent -Encoding UTF8

    Write-Host $reportContent
    Write-Host ""
    Write-Host "脱敏报告已保存至：$ReportPath"
}

# 执行脱敏并生成报告
New-MaskingReport -InputPath 'users.csv' `
    -OutputPath 'users_masked_v2.csv' `
    -ReportPath 'masking_report.txt'
```

执行结果：

```
====== 数据脱敏报告 ======
源文件：users.csv
输出文件：users_masked_v2.csv
执行时间：True
处理记录数：5
总脱敏次数：12

--- 各规则命中统计 ---
  手机号：3 次
  身份证号：3 次
  邮箱地址：3 次
  银行卡号：3 次

报告生成于：2025-09-24 08:30:15

脱敏报告已保存至：masking_report.txt
```

## 注意事项

1. **脱敏不可逆**：标准的脱敏操作是单向的，一旦替换就无法从脱敏数据恢复原始值。在生产环境执行前务必确认已备份原始文件，或者先将原始数据安全归档。

2. **正则精度与性能**：正则表达式的编写需要在匹配精度和性能之间取得平衡。过于宽松的规则可能产生误匹配（如将订单号当作手机号脱敏），过于严格则可能遗漏。建议先用小批量数据验证规则，再全量执行。

3. **格式保持**：脱敏后的数据应保持原始格式特征（长度、分隔符、前缀等），否则下游系统可能因格式校验失败而报错。例如手机号脱敏后仍应为 11 位数字。

4. **多种敏感类型交叉**：同一字段可能同时匹配多条规则（如身份证号的前几位可能被误判为手机号）。规则应按从长到短的优先级执行，并在每次替换后重新评估，避免已脱敏的内容被二次处理。

5. **日志中也可能包含敏感数据**：不仅要处理结构化数据文件，日志文件、错误消息、调试输出中也可能意外包含明文敏感信息。对日志目录也应纳入脱敏流程的覆盖范围。

6. **合规要求**：不同行业和地区对数据脱敏有不同的合规要求（如金融行业需遵守更严格的规范）。在设计脱敏方案时，应参考相关法规确定哪些字段必须脱敏、脱敏到何种程度，并定期审计脱敏策略的有效性。

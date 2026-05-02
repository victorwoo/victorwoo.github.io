---
layout: post
date: 2025-08-06 08:00:00
updated: 2025-08-06 08:00:00
title: "PowerShell 技能连载 - 数据迁移与转换技巧"
description: PowerTip of the Day - Data Migration and Conversion Techniques in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- data-migration
- etl
- csv
- json
- conversion
---

_适用于 PowerShell 5.1 及以上版本_

在 IT 运维和开发工作中，数据迁移和格式转换是高频需求。系统升级时需要将用户数据从旧格式迁移到新格式，报表汇总时需要合并多个 CSV 文件并转换字段，跨系统对接时需要在 JSON、CSV、XML、YAML 之间来回转换。这些任务看似简单，但涉及编码问题、类型映射、空值处理、增量同步等细节时往往让人头疼。

PowerShell 内置了 `ConvertTo-Csv`、`ConvertFrom-Json`、`ConvertTo-Xml` 等丰富的转换 cmdlet，配合管道操作可以快速构建 ETL（Extract-Transform-Load）流程。本文将从实际场景出发，讲解数据迁移和转换中的常用技巧。

## CSV 数据读取与清洗

```powershell
# 场景：从遗留系统导出的 CSV 数据质量差，需要清洗后再导入新系统

$rawCsv = @"
EmployeeID,Name,Department,Salary,HireDate,Status
E001,张三,技术部,15000.50,2020-03-15,Active
E002,李四,市场部,,2021-07-20,Active
E003,王五,技术部,18000,2022-01-10,Inactive
E004,,财务部,12000,2023/06/01,Active
E005,赵六,技术部,20000.99,invalid,Active
E006,钱七,,16500,2020-11-30,Active
"@

function Import-AndCleanCsv {
    param(
        [Parameter(Mandatory)]
        [string[]]$CsvLines,

        [string]$DefaultDepartment = "未分配",

        [decimal]$DefaultSalary = 0
    )

    # 导入 CSV
    $data = $CsvLines | ConvertFrom-Csv

    $cleaned = foreach ($row in $data) {
        # 清洗姓名：去除空值
        $name = if ([string]::IsNullOrWhiteSpace($row.Name)) {
            "未知员工($($row.EmployeeID))"
        } else {
            $row.Name.Trim()
        }

        # 清洗部门：空值使用默认值
        $dept = if ([string]::IsNullOrWhiteSpace($row.Department)) {
            $DefaultDepartment
        } else {
            $row.Department.Trim()
        }

        # 清洗薪资：非数字使用默认值
        $salary = if ($row.Salary -match '^\d+\.?\d*$') {
            [decimal]$row.Salary
        } else {
            $DefaultSalary
        }

        # 清洗日期：多种格式统一转换
        $hireDate = $null
        if ($row.HireDate -match '^\d{4}-\d{2}-\d{2}$') {
            $hireDate = [datetime]::ParseExact($row.HireDate, "yyyy-MM-dd", $null)
        } elseif ($row.HireDate -match '^\d{4}/\d{2}/\d{2}$') {
            $hireDate = [datetime]::ParseExact($row.HireDate, "yyyy/MM/dd", $null)
        }

        # 输出清洗后的对象
        [PSCustomObject]@{
            EmployeeID = $row.EmployeeID
            Name       = $name
            Department = $dept
            Salary     = $salary
            HireDate   = if ($hireDate) { $hireDate.ToString("yyyy-MM-dd") } else { "N/A" }
            Status     = $row.Status
            Cleaned    = $true
        }
    }

    return $cleaned
}

$cleanData = Import-AndCleanCsv -CsvLines ($rawCsv -split "`n")
$cleanData | Format-Table -AutoSize
```

执行结果示例：

```
EmployeeID Name          Department Salary   HireDate   Status  Cleaned
---------- ----          ---------- ------   --------   ------  -------
E001       张三          技术部     15000.50 2020-03-15 Active  True
E002       李四          市场部     0.00     2021-07-20 Active  True
E003       王五          技术部     18000.00 2022-01-10 Inactive True
E004       未知员工(E004) 财务部     12000.00 2023-06-01 Active  True
E005       赵六          技术部     20000.99 N/A        Active  True
E006       钱七          未分配     16500.00 2020-11-30 Active  True
```

## CSV 转 JSON 与嵌套结构

```powershell
# 场景：将扁平的 CSV 数据转换为嵌套的 JSON 结构供 API 消费

$flatData = @"
ID,Name,Email,DeptID,DeptName,RoleID,RoleName
U001,张三,zhangsan@contoso.com,D001,技术部,R001,开发工程师
U002,李四,lisi@contoso.com,D001,技术部,R002,测试工程师
U003,王五,wangwu@contoso.com,D002,市场部,R003,市场经理
U004,赵六,zhaoliu@contoso.com,D002,市场部,R003,市场经理
"@

function ConvertFrom-FlatToNestedJson {
    param(
        [Parameter(Mandatory)]
        [string[]]$CsvLines
    )

    $data = $CsvLines | ConvertFrom-Csv

    # 按部门分组，构建嵌套结构
    $nested = $data | Group-Object -Property DeptID | ForEach-Object {
        $deptGroup = $_

        # 按角色分组
        $roles = $deptGroup.Group | Group-Object -Property RoleID | ForEach-Object {
            $roleGroup = $_
            $members = $roleGroup.Group | ForEach-Object {
                @{
                    id    = $_.ID
                    name  = $_.Name
                    email = $_.Email
                }
            }

            @{
                roleId   = $roleGroup.Name
                roleName = ($roleGroup.Group | Select-Object -First 1).RoleName
                members  = @($members)
            }
        }

        @{
            departmentId   = $deptGroup.Name
            departmentName = ($deptGroup.Group | Select-Object -First 1).DeptName
            roles          = @($roles)
        }
    }

    $result = @{
        exportDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        totalCount = $data.Count
        departments = @($nested)
    }

    return $result | ConvertTo-Json -Depth 5
}

$jsonOutput = ConvertFrom-FlatToNestedJson -CsvLines ($flatData -split "`n")
Write-Host $jsonOutput
```

执行结果示例：

```
{
    "exportDate": "2025-08-06T08:30:00",
    "totalCount": 4,
    "departments": [
        {
            "departmentId": "D001",
            "departmentName": "技术部",
            "roles": [
                {
                    "roleId": "R001",
                    "roleName": "开发工程师",
                    "members": [
                        {
                            "id": "U001",
                            "name": "张三",
                            "email": "zhangsan@contoso.com"
                        }
                    ]
                },
                {
                    "roleId": "R002",
                    "roleName": "测试工程师",
                    "members": [
                        {
                            "id": "U002",
                            "name": "李四",
                            "email": "lisi@contoso.com"
                        }
                    ]
                }
            ]
        },
        {
            "departmentId": "D002",
            "departmentName": "市场部",
            "roles": [
                {
                    "roleId": "R003",
                    "roleName": "市场经理",
                    "members": [
                        { "id": "U003", "name": "王五", "email": "wangwu@contoso.com" },
                        { "id": "U004", "name": "赵六", "email": "zhaoliu@contoso.com" }
                    ]
                }
            ]
        }
    ]
}
```

## JSON 转 CSV 与字段展开

```powershell
# 场景：从 API 获取的嵌套 JSON 需要展开为扁平的 CSV 供报表使用

$apiJson = @"
{
    "users": [
        {
            "id": "U001",
            "profile": {
                "name": "张三",
                "age": 28,
                "address": {
                    "city": "北京",
                    "district": "海淀区"
                }
            },
            "skills": ["PowerShell", "Python", "Docker"],
            "active": true
        },
        {
            "id": "U002",
            "profile": {
                "name": "李四",
                "age": 32,
                "address": {
                    "city": "上海",
                    "district": "浦东新区"
                }
            },
            "skills": ["C#", "SQL Server"],
            "active": false
        }
    ]
}
"@

function Expand-NestedJsonToCsv {
    param(
        [Parameter(Mandatory)]
        [string]$JsonString
    )

    $data = $JsonString | ConvertFrom-Json

    $flatRows = foreach ($user in $data.users) {
        [PSCustomObject]@{
            ID       = $user.id
            Name     = $user.profile.name
            Age      = $user.profile.age
            City     = $user.profile.address.city
            District = $user.profile.address.district
            Skills   = ($user.skills -join "; ")
            SkillCount = $user.skills.Count
            Active   = $user.active
        }
    }

    return $flatRows
}

$flatRows = Expand-NestedJsonToCsv -JsonString $apiJson
$flatRows | Export-Csv -Path "$env:TEMP\users_flat.csv" -NoTypeInformation -Encoding UTF8
Write-Host "已导出到 $env:TEMP\users_flat.csv"
Get-Content "$env:TEMP\users_flat.csv"
```

执行结果示例：

```
已导出到 C:\Users\admin\AppData\Local\Temp\users_flat.csv
"ID","Name","Age","City","District","Skills","SkillCount","Active"
"U001","张三","28","北京","海淀区","PowerShell; Python; Docker","3","True"
"U002","李四","32","上海","浦东新区","C#; SQL Server","2","False"
```

## 增量数据迁移与变更追踪

```powershell
# 场景：定期从源系统迁移数据到目标系统，只迁移新增或变更的记录

function Start-IncrementalMigration {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [Parameter(Mandatory)]
        [string]$KeyField,

        [string]$CompareField = "UpdatedAt"
    )

    # 加载源数据
    $source = Import-Csv -Path $SourcePath -Encoding UTF8
    $target = if (Test-Path $TargetPath) {
        Import-Csv -Path $TargetPath -Encoding UTF8
    } else {
        @()
    }

    # 构建目标数据的索引
    $targetIndex = @{}
    foreach ($row in $target) {
        $targetIndex[$row.$KeyField] = $row
    }

    $stats = @{
        Total    = $source.Count
        Inserted = 0
        Updated  = 0
        Skipped  = 0
    }

    $result = foreach ($srcRow in $source) {
        $key = $srcRow.$KeyField

        if ($targetIndex.ContainsKey($key)) {
            # 记录已存在，检查是否需要更新
            $tgtRow = $targetIndex[$key]
            $srcVal = $srcRow.$CompareField
            $tgtVal = $tgtRow.$CompareField

            if ($srcVal -gt $tgtVal) {
                # 源数据更新，覆盖目标
                $srcRow | Add-Member -MemberType NoteProperty -Name "_action" -Value "UPDATE" -Force
                $stats.Updated++
                $srcRow
            } else {
                # 无变化，跳过
                $stats.Skipped++
            }
        } else {
            # 新记录，插入
            $srcRow | Add-Member -MemberType NoteProperty -Name "_action" -Value "INSERT" -Force
            $stats.Inserted++
            $srcRow
        }
    }

    # 合并数据：保留未变更的目标记录 + 更新/新增的记录
    $unchanged = $target | Where-Object {
        $key = $_.$KeyField
        $srcKeys = $source | ForEach-Object { $_.$KeyField }
        $key -in $srcKeys -and -not ($result | Where-Object { $_.$KeyField -eq $key })
    }

    $finalData = @($unchanged) + @($result | Where-Object { $_._action -eq "UPDATE" }) +
                  @($result | Where-Object { $_._action -eq "INSERT" })

    # 移除内部字段后导出
    $finalData | ForEach-Object { $_.PSObject.Properties.Remove("_action") }
    $finalData | Export-Csv -Path $TargetPath -NoTypeInformation -Encoding UTF8

    Write-Host "迁移完成：" -ForegroundColor Green
    Write-Host "  总记录数：$($stats.Total)"
    Write-Host "  新增：$($stats.Inserted)" -ForegroundColor Cyan
    Write-Host "  更新：$($stats.Updated)" -ForegroundColor Yellow
    Write-Host "  跳过（无变化）：$($stats.Skipped)" -ForegroundColor Gray

    return $stats
}

# 使用示例（模拟源数据）
$sourceData = @"
ID,Name,Department,UpdatedAt
E001,张三,技术部,2025-08-01
E002,李四,市场部,2025-08-05
E003,王五,财务部,2025-08-06
"@

$targetData = @"
ID,Name,Department,UpdatedAt
E001,张三,技术部,2025-07-15
E002,李四,市场部,2025-08-05
"@

$sourceData | Set-Content "$env:TEMP\source.csv" -Encoding UTF8
$targetData | Set-Content "$env:TEMP\target.csv" -Encoding UTF8

Start-IncrementalMigration -SourcePath "$env:TEMP\source.csv" `
    -TargetPath "$env:TEMP\target.csv" `
    -KeyField "ID" `
    -CompareField "UpdatedAt"
```

执行结果示例：

```
迁移完成：
  总记录数：3
  新增：1
  更新：1
  跳过（无变化）：1
```

## 多文件合并与格式批量转换

```powershell
# 场景：批量合并多个 CSV 文件，统一格式后输出为 JSON

function Merge-MultipleCsv {
    param(
        [Parameter(Mandatory)]
        [string]$InputFolder,

        [string]$Filter = "*.csv",

        [string]$OutputPath,

        [string[]]$FieldMapping
    )

    $allData = @()
    $files = Get-ChildItem -Path $InputFolder -Filter $Filter -File

    Write-Host "找到 $($files.Count) 个文件待合并" -ForegroundColor Cyan

    foreach ($file in $files) {
        Write-Host "  处理：$($file.Name)" -ForegroundColor Gray

        $csv = Import-Csv -Path $file.FullName -Encoding UTF8

        foreach ($row in $csv) {
            # 如果指定了字段映射，只提取需要的字段
            if ($FieldMapping) {
                $mappedRow = @{}
                foreach ($field in $FieldMapping) {
                    if ($row.PSObject.Properties[$field]) {
                        $mappedRow[$field] = $row.$field
                    }
                }
                $mappedRow["_sourceFile"] = $file.Name
                $allData += [PSCustomObject]$mappedRow
            } else {
                $row | Add-Member -MemberType NoteProperty -Name "_sourceFile" `
                    -Value $file.Name -Force
                $allData += $row
            }
        }
    }

    Write-Host "合并完成，共 $($allData.Count) 条记录" -ForegroundColor Green

    # 根据输出路径的扩展名决定格式
    if ($OutputPath) {
        $ext = [System.IO.Path]::GetExtension($OutputPath).ToLower()
        switch ($ext) {
            ".json" {
                $allData | ConvertTo-Json -Depth 3 | Set-Content $OutputPath -Encoding UTF8
            }
            ".csv" {
                $allData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            ".xml" {
                $allData | ConvertTo-Xml -NoTypeInformation | Select-Object -ExpandProperty OuterXml |
                    Set-Content $OutputPath -Encoding UTF8
            }
            default {
                $allData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
        }
        Write-Host "已输出到：$OutputPath" -ForegroundColor Green
    }

    return $allData
}

# 批量格式转换工具
function Convert-DataFormat {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $ext = [System.IO.Path]::GetExtension($InputPath).ToLower()

    # 读取数据
    $data = switch ($ext) {
        ".csv"  { Import-Csv -Path $InputPath -Encoding UTF8 }
        ".json" { Get-Content $InputPath -Raw | ConvertFrom-Json }
        default { throw "不支持的输入格式：$ext" }
    }

    # 如果 JSON 顶层是数组，ConvertFrom-Json 已经返回数组
    # 如果是单个对象，包装为数组
    if ($data -isnot [System.Array]) {
        $data = @($data)
    }

    # 写入目标格式
    $outExt = [System.IO.Path]::GetExtension($OutputPath).ToLower()
    switch ($outExt) {
        ".json" {
            $data | ConvertTo-Json -Depth 5 | Set-Content $OutputPath -Encoding UTF8
        }
        ".csv" {
            $data | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
        default {
            throw "不支持的输出格式：$outExt"
        }
    }

    Write-Host "转换完成：$InputPath -> $OutputPath" -ForegroundColor Green
}

# 示例
Convert-DataFormat -InputPath "$env:TEMP\source.csv" -OutputPath "$env:TEMP\source.json"
```

执行结果示例：

```
找到 3 个文件待合并
  处理：employees_dept_a.csv
  处理：employees_dept_b.csv
  处理：employees_dept_c.csv
合并完成，共 15 条记录
转换完成：C:\Users\admin\AppData\Local\Temp\source.csv -> C:\Users\admin\AppData\Local\Temp\source.json
```

## 注意事项

1. **编码一致性**：读写文件时始终显式指定 `-Encoding UTF8`，避免中文乱码，尤其在不同 Windows 版本间迁移时
2. **大文件性能**：超过 10 万行的 CSV 不要用 `Import-Csv` 一次性加载到内存，应逐行流式处理或使用 `StreamReader`
3. **日期格式标准化**：迁移前统一日期格式（推荐 ISO 8601），避免 `2025/08/06` 与 `2025-08-06` 混用导致比较失败
4. **空值策略**：明确区分空字符串、`$null` 和缺失值，迁移前定义好每种情况的处理规则（跳过、默认值、报错）
5. **事务性保证**：关键数据迁移应在导入前备份目标数据，失败时能回滚到迁移前的状态
6. **字段映射验证**：源和目标的字段名、类型、长度可能不同，迁移前应做字段映射表并逐条校验

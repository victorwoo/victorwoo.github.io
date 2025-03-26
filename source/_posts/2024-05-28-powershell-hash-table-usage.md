---
layout: post
date: 2024-05-28 08:00:00
title: "PowerShell 哈希表实战技巧"
description: "掌握键值对数据结构的高级应用场景"
categories:
- powershell
- scripting
tags:
- hashtable
- data-structures
---

### 基础操作演示
```powershell
# 创建带类型约束的哈希表
$userProfile = [ordered]@{
    Name = '张三'
    Age  = 28
    Role = '管理员'
}

# 动态参数生成
function New-Service {
    param($ServiceParams)
    Start-Process -FilePath 'notepad.exe' @ServiceParams
}

$params = @{
    WindowStyle = 'Maximized'
    PassThru    = $true
}
New-Service -ServiceParams $params
```

### 数据筛选应用
```powershell
# 构建商品库存系统
$inventory = @{
    '笔记本' = @{ Price=5999; Stock=15 }
    '手机'   = @{ Price=3999; Stock=30 }
    '耳机'   = @{ Price=299; Stock=100 }
}

# 实时库存查询
$inventory.Keys | Where-Object { 
    $inventory[$_].Price -lt 5000 -and
    $inventory[$_].Stock -gt 20
} | ForEach-Object {
    [PSCustomObject]@{
        商品 = $_
        价格 = $inventory[$_].Price
        库存 = $inventory[$_].Stock
    }
}
```

### 最佳实践
1. 使用[ordered]创建有序字典
2. 通过嵌套哈希表构建层级数据
3. 用ConvertTo-Json实现数据序列化
4. 结合Splatting传递动态参数
5. 使用ContainsKey方法进行安全校验
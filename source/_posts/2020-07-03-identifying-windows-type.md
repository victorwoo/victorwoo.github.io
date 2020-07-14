---
layout: post
date: 2020-07-03 00:00:00
title: "PowerShell 技能连载 - 识别 Windows 类型"
description: PowerTip of the Day - Identifying Windows Type
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 返回每个不同的 Windows SKU 的密码编号：

```powershell
PS> Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty OperatingSystemSKU
48
```

要将此数字转换为有意义的文本（例如出于报告目的），请尝试以下操作：

```powershell
$OperatingSystemSKU = @{
  Name = 'OperatingSystemSKUText'
  Expression = {
    $value = $_.OperatingSystemSKU

    switch([int]$value)
      {
        0          {'PRODUCT_UNDEFINED'}
        1          {'PRODUCT_ULTIMATE'}
        2          {'PRODUCT_HOME_BASIC'}
        3          {'PRODUCT_HOME_PREMIUM'}
        4          {'PRODUCT_ENTERPRISE'}
        5          {'PRODUCT_HOME_BASIC_N'}
        6          {'PRODUCT_BUSINESS'}
        7          {'PRODUCT_STANDARD_SERVER'}
        8          {'PRODUCT_DATACENTER_SERVER'}
        9          {'PRODUCT_SMALLBUSINESS_SERVER'}
        10         {'PRODUCT_ENTERPRISE_SERVER'}
        11         {'PRODUCT_STARTER'}
        12         {'PRODUCT_DATACENTER_SERVER_CORE'}
        13         {'PRODUCT_STANDARD_SERVER_CORE'}
        14         {'PRODUCT_ENTERPRISE_SERVER_CORE'}
        15         {'PRODUCT_ENTERPRISE_SERVER_IA64'}
        16         {'PRODUCT_BUSINESS_N'}
        17         {'PRODUCT_WEB_SERVER'}
        18         {'PRODUCT_CLUSTER_SERVER'}
        19         {'PRODUCT_HOME_SERVER'}
        20         {'PRODUCT_STORAGE_EXPRESS_SERVER'}
        21         {'PRODUCT_STORAGE_STANDARD_SERVER'}
        22         {'PRODUCT_STORAGE_WORKGROUP_SERVER'}
        23         {'PRODUCT_STORAGE_ENTERPRISE_SERVER'}
        24         {'PRODUCT_SERVER_FOR_SMALLBUSINESS'}
        25         {'PRODUCT_SMALLBUSINESS_SERVER_PREMIUM'}
        26         {'PRODUCT_HOME_PREMIUM_N'}
        27         {'PRODUCT_ENTERPRISE_N'}
        28         {'PRODUCT_ULTIMATE_N'}
        29         {'PRODUCT_WEB_SERVER_CORE'}
        30         {'PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT'}
        31         {'PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY'}
        32         {'PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING'}
        33         {'PRODUCT_SERVER_FOUNDATION'}
        34         {'PRODUCT_HOME_PREMIUM_SERVER'}
        35         {'PRODUCT_SERVER_FOR_SMALLBUSINESS_V'}
        36         {'PRODUCT_STANDARD_SERVER_V'}
        37         {'PRODUCT_DATACENTER_SERVER_V'}
        38         {'PRODUCT_ENTERPRISE_SERVER_V'}
        39         {'PRODUCT_DATACENTER_SERVER_CORE_V'}
        40         {'PRODUCT_STANDARD_SERVER_CORE_V'}
        41         {'PRODUCT_ENTERPRISE_SERVER_CORE_V'}
        42         {'PRODUCT_HYPERV'}
        43         {'PRODUCT_STORAGE_EXPRESS_SERVER_CORE'}
        44         {'PRODUCT_STORAGE_STANDARD_SERVER_CORE'}
        45         {'PRODUCT_STORAGE_WORKGROUP_SERVER_CORE'}
        46         {'PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE'}
        47         {'PRODUCT_STARTER_N'}
        48         {'PRODUCT_PROFESSIONAL'}
        49         {'PRODUCT_PROFESSIONAL_N'}
        50         {'PRODUCT_SB_SOLUTION_SERVER'}
        51         {'PRODUCT_SERVER_FOR_SB_SOLUTIONS'}
        52         {'PRODUCT_STANDARD_SERVER_SOLUTIONS'}
        53         {'PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE'}
        54         {'PRODUCT_SB_SOLUTION_SERVER_EM'}
        55         {'PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM'}
        56         {'PRODUCT_SOLUTION_EMBEDDEDSERVER'}
        57         {'PRODUCT_SOLUTION_EMBEDDEDSERVER_CORE'}
        58         {'PRODUCT_PROFESSIONAL_EMBEDDED'}
        59         {'PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT'}
        60         {'PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL'}
        61         {'PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC'}
        62         {'PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC'}
        63         {'PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE'}
        64         {'PRODUCT_CLUSTER_SERVER_V'}
        65         {'PRODUCT_EMBEDDED'}
        66         {'PRODUCT_STARTER_E'}
        67         {'PRODUCT_HOME_BASIC_E'}
        68         {'PRODUCT_HOME_PREMIUM_E'}
        69         {'PRODUCT_PROFESSIONAL_E'}
        70         {'PRODUCT_ENTERPRISE_E'}
        71         {'PRODUCT_ULTIMATE_E'}
        72         {'PRODUCT_ENTERPRISE_EVALUATION'}
        76         {'PRODUCT_MULTIPOINT_STANDARD_SERVER'}
        77         {'PRODUCT_MULTIPOINT_PREMIUM_SERVER'}
        79         {'PRODUCT_STANDARD_EVALUATION_SERVER'}
        80         {'PRODUCT_DATACENTER_EVALUATION_SERVER'}
        84         {'PRODUCT_ENTERPRISE_N_EVALUATION'}
        85         {'PRODUCT_EMBEDDED_AUTOMOTIVE'}
        86         {'PRODUCT_EMBEDDED_INDUSTRY_A'}
        87         {'PRODUCT_THINPC'}
        88         {'PRODUCT_EMBEDDED_A'}
        89         {'PRODUCT_EMBEDDED_INDUSTRY'}
        90         {'PRODUCT_EMBEDDED_E'}
        91         {'PRODUCT_EMBEDDED_INDUSTRY_E'}
        92         {'PRODUCT_EMBEDDED_INDUSTRY_A_E'}
        95         {'PRODUCT_STORAGE_WORKGROUP_EVALUATION_SERVE'}
        96         {'PRODUCT_STORAGE_STANDARD_EVALUATION_SERVER'}
        97         {'PRODUCT_CORE_ARM'}
        98         {'PRODUCT_CORE_N'}
        99         {'PRODUCT_CORE_COUNTRYSPECIFIC'}
        100        {'PRODUCT_CORE_SINGLELANGUAGE'}
        101        {'PRODUCT_CORE'}
        103        {'PRODUCT_PROFESSIONAL_WMC'}
        105        {'PRODUCT_EMBEDDED_INDUSTRY_EVAL'}
        106        {'PRODUCT_EMBEDDED_INDUSTRY_E_EVAL'}
        107        {'PRODUCT_EMBEDDED_EVAL'}
        108        {'PRODUCT_EMBEDDED_E_EVAL'}
        109        {'PRODUCT_NANO_SERVER'}
        110        {'PRODUCT_CLOUD_STORAGE_SERVER'}
        111        {'PRODUCT_CORE_CONNECTED'}
        112        {'PRODUCT_PROFESSIONAL_STUDENT'}
        113        {'PRODUCT_CORE_CONNECTED_N'}
        114        {'PRODUCT_PROFESSIONAL_STUDENT_N'}
        115        {'PRODUCT_CORE_CONNECTED_SINGLELANGUAGE'}
        116        {'PRODUCT_CORE_CONNECTED_COUNTRYSPECIFIC'}
        117        {'PRODUCT_CONNECTED_CAR'}
        118        {'PRODUCT_INDUSTRY_HANDHELD'}
        119        {'PRODUCT_PPI_PRO'}
        120        {'PRODUCT_ARM64_SERVER'}
        121        {'PRODUCT_EDUCATION'}
        122        {'PRODUCT_EDUCATION_N'}
        123        {'PRODUCT_IOTUAP'}
        124        {'PRODUCT_CLOUD_HOST_INFRASTRUCTURE_SERVER'}
        125        {'PRODUCT_ENTERPRISE_S'}
        126        {'PRODUCT_ENTERPRISE_S_N'}
        127        {'PRODUCT_PROFESSIONAL_S'}
        128        {'PRODUCT_PROFESSIONAL_S_N'}
        129        {'PRODUCT_ENTERPRISE_S_EVALUATION'}
        130        {'PRODUCT_ENTERPRISE_S_N_EVALUATION'}
        135        {'PRODUCT_HOLOGRAPHIC'}
        138        {'PRODUCT_PRO_SINGLE_LANGUAGE'}
        139        {'PRODUCT_PRO_CHINA'}
        140        {'PRODUCT_ENTERPRISE_SUBSCRIPTION'}
        141        {'PRODUCT_ENTERPRISE_SUBSCRIPTION_N'}
        143        {'PRODUCT_DATACENTER_NANO_SERVER'}
        144        {'PRODUCT_STANDARD_NANO_SERVER'}
        145        {'PRODUCT_DATACENTER_A_SERVER_CORE'}
        146        {'PRODUCT_STANDARD_A_SERVER_CORE'}
        147        {'PRODUCT_DATACENTER_WS_SERVER_CORE'}
        148        {'PRODUCT_STANDARD_WS_SERVER_CORE'}
        149        {'PRODUCT_UTILITY_VM'}
        159        {'PRODUCT_DATACENTER_EVALUATION_SERVER_CORE'}
        160        {'PRODUCT_STANDARD_EVALUATION_SERVER_CORE'}
        161        {'PRODUCT_PRO_WORKSTATION'}
        162        {'PRODUCT_PRO_WORKSTATION_N'}
        164        {'PRODUCT_PRO_FOR_EDUCATION'}
        165        {'PRODUCT_PRO_FOR_EDUCATION_N'}
        168        {'PRODUCT_AZURE_SERVER_CORE'}
        169        {'PRODUCT_AZURE_NANO_SERVER'}
        171        {'PRODUCT_ENTERPRISEG'}
        172        {'PRODUCT_ENTERPRISEGN'}
        175        {'PRODUCT_SERVERRDSH'}
        178        {'PRODUCT_CLOUD'}
        179        {'PRODUCT_CLOUDN'}
        180        {'PRODUCT_HUBOS'}
        182        {'PRODUCT_ONECOREUPDATEOS'}
        183        {'PRODUCT_CLOUDE'}
        184        {'PRODUCT_ANDROMEDA'}
        185        {'PRODUCT_IOTOS'}
        186        {'PRODUCT_CLOUDEN'}
        default    {"$value"}
      }

  }
}

Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, OperatingSystemSKU, $OperatingSystemSKU
```

输出将添加一个具有友好名称的新 `OperatingSystemSKUText` 属性：

    Caption                  OperatingSystemSKU OperatingSystemSKUText
    -------                  ------------------ ----------------------
    Microsoft Windows 10 Pro                 48 PRODUCT_PROFESSIONAL

<!--本文国际来源：[Identifying Windows Type](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-windows-type)-->


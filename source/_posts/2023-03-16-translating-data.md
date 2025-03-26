---
layout: post
date: 2023-03-16 00:00:50
title: "PowerShell 技能连载 - 翻译数据"
description: PowerTip of the Day - Translating Data
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
哈希表和字典是完美的查找表：每当您的原始数据包含难以理解的数字或命令返回仅为数值返回值时，哈希表可以将这些数字转换为友好的文本。

由于您可以自由地向哈希表添加任何键，因此要翻译的数字也不必是连续的数字范围。

以下是一个示例，从 WMI 查询操作系统信息，然后将您的 Windows SKU 从数字转换为描述性文本：

```powershell
# get any info, i.e. some WMI information about your OS
$info = Get-CimInstance -ClassName Win32_OperatingSystem
# it may include information that is cryptically encoded as some number:
$rawData = $info.OperatingSystemSKU
# by using a hash table, you can easily translate the numbers to text:
$translation = @{
      0 = 'UNDEFINED'
      1 = 'ULTIMATE'
      2 = 'HOME_BASIC'
      3 = 'HOME_PREMIUM'
      4 = 'ENTERPRISE'
      5 = 'HOME_BASIC_N'
      6 = 'BUSINESS'
      7 = 'STANDARD_SERVER'
      8 = 'DATACENTER_SERVER'
      9 = 'SMALLBUSINESS_SERVER'
     10 = 'ENTERPRISE_SERVER'
     11 = 'STARTER'
     12 = 'DATACENTER_SERVER_CORE'
     13 = 'STANDARD_SERVER_CORE'
     14 = 'ENTERPRISE_SERVER_CORE'
     15 = 'ENTERPRISE_SERVER_IA64'
     16 = 'BUSINESS_N'
     17 = 'WEB_SERVER'
     18 = 'CLUSTER_SERVER'
     19 = 'HOME_SERVER'
     20 = 'STORAGE_EXPRESS_SERVER'
     21 = 'STORAGE_STANDARD_SERVER'
     22 = 'STORAGE_WORKGROUP_SERVER'
     23 = 'STORAGE_ENTERPRISE_SERVER'
     24 = 'SERVER_FOR_SMALLBUSINESS'
     25 = 'SMALLBUSINESS_SERVER_PREMIUM'
     26 = 'HOME_PREMIUM_N'
     27 = 'ENTERPRISE_N'
     28 = 'ULTIMATE_N'
     29 = 'WEB_SERVER_CORE'
     30 = 'MEDIUMBUSINESS_SERVER_MANAGEMENT'
     31 = 'MEDIUMBUSINESS_SERVER_SECURITY'
     32 = 'MEDIUMBUSINESS_SERVER_MESSAGING'
     33 = 'SERVER_FOUNDATION'
     34 = 'HOME_PREMIUM_SERVER'
     35 = 'SERVER_FOR_SMALLBUSINESS_V'
     36 = 'STANDARD_SERVER_V'
     37 = 'DATACENTER_SERVER_V'
     38 = 'ENTERPRISE_SERVER_V'
     39 = 'DATACENTER_SERVER_CORE_V'
     40 = 'STANDARD_SERVER_CORE_V'
     41 = 'ENTERPRISE_SERVER_CORE_V'
     42 = 'HYPERV'
     43 = 'STORAGE_EXPRESS_SERVER_CORE'
     44 = 'STORAGE_STANDARD_SERVER_CORE'
     45 = 'STORAGE_WORKGROUP_SERVER_CORE'
     46 = 'STORAGE_ENTERPRISE_SERVER_CORE'
     47 = 'STARTER_N'
     48 = 'PROFESSIONAL'
     49 = 'PROFESSIONAL_N'
     50 = 'SB_SOLUTION_SERVER'
     51 = 'SERVER_FOR_SB_SOLUTIONS'
     52 = 'STANDARD_SERVER_SOLUTIONS'
     53 = 'STANDARD_SERVER_SOLUTIONS_CORE'
     54 = 'SB_SOLUTION_SERVER_EM'
     55 = 'SERVER_FOR_SB_SOLUTIONS_EM'
     56 = 'SOLUTION_EMBEDDEDSERVER'
     57 = 'SOLUTION_EMBEDDEDSERVER_CORE'
     58 = 'PROFESSIONAL_EMBEDDED'
     59 = 'ESSENTIALBUSINESS_SERVER_MGMT'
     60 = 'ESSENTIALBUSINESS_SERVER_ADDL'
     61 = 'ESSENTIALBUSINESS_SERVER_MGMTSVC'
     62 = 'ESSENTIALBUSINESS_SERVER_ADDLSVC'
     63 = 'SMALLBUSINESS_SERVER_PREMIUM_CORE'
     64 = 'CLUSTER_SERVER_V'
     65 = 'EMBEDDED'
     66 = 'STARTER_E'
     67 = 'HOME_BASIC_E'
     68 = 'HOME_PREMIUM_E'
     69 = 'PROFESSIONAL_E'
     70 = 'ENTERPRISE_E'
     71 = 'ULTIMATE_E'
     72 = 'ENTERPRISE_EVALUATION'
     76 = 'MULTIPOINT_STANDARD_SERVER'
     77 = 'MULTIPOINT_PREMIUM_SERVER'
     79 = 'STANDARD_EVALUATION_SERVER'
     80 = 'DATACENTER_EVALUATION_SERVER'
     84 = 'ENTERPRISE_N_EVALUATION'
     85 = 'EMBEDDED_AUTOMOTIVE'
     86 = 'EMBEDDED_INDUSTRY_A'
     87 = 'THINPC'
     88 = 'EMBEDDED_A'
     89 = 'EMBEDDED_INDUSTRY'
     90 = 'EMBEDDED_E'
     91 = 'EMBEDDED_INDUSTRY_E'
     92 = 'EMBEDDED_INDUSTRY_A_E'
     95 = 'STORAGE_WORKGROUP_EVALUATION_SERVE'
     96 = 'STORAGE_STANDARD_EVALUATION_SERVER'
     97 = 'CORE_ARM'
     98 = 'CORE_N'
     99 = 'CORE_COUNTRYSPECIFIC'
    100 = 'CORE_SINGLELANGUAGE'
    101 = 'CORE'
    103 = 'PROFESSIONAL_WMC'
    105 = 'EMBEDDED_INDUSTRY_EVAL'
    106 = 'EMBEDDED_INDUSTRY_E_EVAL'
    107 = 'EMBEDDED_EVAL'
    108 = 'EMBEDDED_E_EVAL'
    109 = 'NANO_SERVER'
    110 = 'CLOUD_STORAGE_SERVER'
    111 = 'CORE_CONNECTED'
    112 = 'PROFESSIONAL_STUDENT'
    113 = 'CORE_CONNECTED_N'
    114 = 'PROFESSIONAL_STUDENT_N'
    115 = 'CORE_CONNECTED_SINGLELANGUAGE'
    116 = 'CORE_CONNECTED_COUNTRYSPECIFIC'
    117 = 'CONNECTED_CAR'
    118 = 'INDUSTRY_HANDHELD'
    119 = 'PPI_PRO'
    120 = 'ARM64_SERVER'
    121 = 'EDUCATION'
    122 = 'EDUCATION_N'
    123 = 'IOTUAP'
    124 = 'CLOUD_HOST_INFRASTRUCTURE_SERVER'
    125 = 'ENTERPRISE_S'
    126 = 'ENTERPRISE_S_N'
    127 = 'PROFESSIONAL_S'
    128 = 'PROFESSIONAL_S_N'
    129 = 'ENTERPRISE_S_EVALUATION'
    130 = 'ENTERPRISE_S_N_EVALUATION'
    135 = 'HOLOGRAPHIC'
    138 = 'PRO_SINGLE_LANGUAGE'
    139 = 'PRO_CHINA'
    140 = 'ENTERPRISE_SUBSCRIPTION'
    141 = 'ENTERPRISE_SUBSCRIPTION_N'
    143 = 'DATACENTER_NANO_SERVER'
    144 = 'STANDARD_NANO_SERVER'
    145 = 'DATACENTER_A_SERVER_CORE'
    146 = 'STANDARD_A_SERVER_CORE'
    147 = 'DATACENTER_WS_SERVER_CORE'
    148 = 'STANDARD_WS_SERVER_CORE'
    149 = 'UTILITY_VM'
    159 = 'DATACENTER_EVALUATION_SERVER_CORE'
    160 = 'STANDARD_EVALUATION_SERVER_CORE'
    161 = 'PRO_WORKSTATION'
    162 = 'PRO_WORKSTATION_N'
    164 = 'PRO_FOR_EDUCATION'
    165 = 'PRO_FOR_EDUCATION_N'
    168 = 'AZURE_SERVER_CORE'
    169 = 'AZURE_NANO_SERVER'
    171 = 'ENTERPRISEG'
    172 = 'ENTERPRISEGN'
    175 = 'SERVERRDSH'
    178 = 'CLOUD'
    179 = 'CLOUDN'
    180 = 'HUBOS'
    182 = 'ONECOREUPDATEOS'
    183 = 'CLOUDE'
    184 = 'ANDROMEDA'
    185 = 'IOTOS'
    186 = 'CLOUDEN'
}
# use the raw data as key to the hash table
# AND MAKE SURE you convert numeric data to [int]!
# (WMI returns unusual data types like [byte] and [UInt16],
#  and hash table keys are type-aware)
$translation[$rawData -as [int]]
```

这个基本的概念适用于所有类型的翻译。以下是一个示例，可以将 ping.exe 提供的返回值进行翻译：

```powershell
$translation = @{
    0 = 'SUCCESS'
    1 = 'FAILURE'
    2 = 'ERROR'
}

1..255 | ForEach-Object {
    # create the IP address to ping
    # make sure you adjust this to your segment!
    $ip = "192.168.2.$_"
    # execute ping.exe and disregard the text output
    ping -n 1 -w 500 $ip > $null
    # instead return the translated return value found in $LASTEXITCODE
    [PSCustomObject]@{
        IpAddress = $ip
        Status    = $translation[$LASTEXITCODE]
    }
}
```

以下是执行结果：

    IpAddress   Status
    ---------   ------
    192.168.2.1 SUCCESS
    192.168.2.2 FAILURE
    192.168.2.3 FAILURE
    192.168.2.4 FAILURE
    192.168.2.5 FAILURE
    192.168.2.6 FAILURE
    ...

<!--本文国际来源：[Translating Data](https://blog.idera.com/database-tools/powershell/powertips/translating-data/)-->


---
layout: post
date: 2023-06-02 00:00:12
title: "PowerShell 技能连载 - 获取父级文化"
description: PowerTip of the Day - Getting Parent Culture
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大部分情况下，本地化资源都会标有类似 "en-us" 或 "de-de" 这样的文化名称。如果你想知道这种标识代表什么，只需将其转换为 `[System.Globalization.CultureInfo]` 对象：

```powershell
PS> [System.Globalization.CultureInfo]'en-us'

LCID             Name             DisplayName
----             ----             -----------
1033             en-US            English (United States)



PS> [System.Globalization.CultureInfo]'de-de'

LCID             Name             DisplayName
----             ----             -----------
1031             de-DE            German (Germany)
```

正如你所见，文化名称非常细致。例如，有 106 个子文化都属于同一个英语基础文化：

```powershell
PS> [System.Globalization.CultureInfo]::GetCultures( [System.Globalization.CultureTypes]::AllCultures) | Where-Object Parent -eq 'en'

LCID             Name             DisplayName
----             ----             -----------
4096             en-001           English (World)
9225             en-029           English (Caribbean)
4096             en-150           English (Europe)
19465            en-AE            English (United Arab Emirates)
4096             en-AG            English (Antigua and Barbuda)
4096             en-AI            English (Anguilla)
4096             en-AS            English (American Samoa)
4096             en-AT            English (Austria)
3081             en-AU            English (Australia)
4096             en-BB            English (Barbados)
4096             en-BE            English (Belgium)
4096             en-BI            English (Burundi)
4096             en-BM            English (Bermuda)
4096             en-BS            English (Bahamas)
4096             en-BW            English (Botswana)
10249            en-BZ            English (Belize)
4105             en-CA            English (Canada)
4096             en-CC            English (Cocos [Keeling] Islands)
4096             en-CH            English (Switzerland)
4096             en-CK            English (Cook Islands)
4096             en-CM            English (Cameroon)
4096             en-CX            English (Christmas Island)
4096             en-CY            English (Cyprus)
4096             en-DE            English (Germany)
4096             en-DK            English (Denmark)
4096             en-DM            English (Dominica)
4096             en-ER            English (Eritrea)
4096             en-FI            English (Finland)
4096             en-FJ            English (Fiji)
4096             en-FK            English (Falkland Islands)
4096             en-FM            English (Micronesia)
2057             en-GB            English (United Kingdom)
4096             en-GD            English (Grenada)
4096             en-GG            English (Guernsey)
4096             en-GH            English (Ghana)
4096             en-GI            English (Gibraltar)
4096             en-GM            English (Gambia)
4096             en-GU            English (Guam)
4096             en-GY            English (Guyana)
15369            en-HK            English (Hong Kong SAR)
14345            en-ID            English (Indonesia)
6153             en-IE            English (Ireland)
4096             en-IL            English (Israel)
4096             en-IM            English (Isle of Man)
16393            en-IN            English (India)
4096             en-IO            English (British Indian Ocean Territory)
4096             en-JE            English (Jersey)
8201             en-JM            English (Jamaica)
4096             en-KE            English (Kenya)
4096             en-KI            English (Kiribati)
4096             en-KN            English (Saint Kitts and Nevis)
4096             en-KY            English (Cayman Islands)
4096             en-LC            English (Saint Lucia)
4096             en-LR            English (Liberia)
4096             en-LS            English (Lesotho)
4096             en-MG            English (Madagascar)
4096             en-MH            English (Marshall Islands)
4096             en-MO            English (Macao SAR)
4096             en-MP            English (Northern Mariana Islands)
4096             en-MS            English (Montserrat)
4096             en-MT            English (Malta)
4096             en-MU            English (Mauritius)
4096             en-MW            English (Malawi)
17417            en-MY            English (Malaysia)
4096             en-NA            English (Namibia)
4096             en-NF            English (Norfolk Island)
4096             en-NG            English (Nigeria)
4096             en-NL            English (Netherlands)
4096             en-NR            English (Nauru)
4096             en-NU            English (Niue)
5129             en-NZ            English (New Zealand)
4096             en-PG            English (Papua New Guinea)
13321            en-PH            English (Republic of the Philippines)
4096             en-PK            English (Pakistan)
4096             en-PN            English (Pitcairn Islands)
4096             en-PR            English (Puerto Rico)
4096             en-PW            English (Palau)
4096             en-RW            English (Rwanda)
4096             en-SB            English (Solomon Islands)
4096             en-SC            English (Seychelles)
4096             en-SD            English (Sudan)
4096             en-SE            English (Sweden)
18441            en-SG            English (Singapore)
4096             en-SH            English (St Helena, Ascension, Tristan da Cunha)
4096             en-SI            English (Slovenia)
4096             en-SL            English (Sierra Leone)
4096             en-SS            English (South Sudan)
4096             en-SX            English (Sint Maarten)
4096             en-SZ            English (Swaziland)
4096             en-TC            English (Turks and Caicos Islands)
4096             en-TK            English (Tokelau)
4096             en-TO            English (Tonga)
11273            en-TT            English (Trinidad and Tobago)
4096             en-TV            English (Tuvalu)
4096             en-TZ            English (Tanzania)
4096             en-UG            English (Uganda)
4096             en-UM            English (US Minor Outlying Islands)
1033             en-US            English (United States)
4096             en-VC            English (Saint Vincent and the Grenadines)
4096             en-VG            English (British Virgin Islands)
4096             en-VI            English (US Virgin Islands)
4096             en-VU            English (Vanuatu)
4096             en-WS            English (Samoa)
7177             en-ZA            English (South Africa)
4096             en-ZM            English (Zambia)
12297            en-ZW            English (Zimbabwe)
```

如果您的代码最终需要检查给定的资源区域设置是否与您的兴趣相匹配，而不是将资源区域设置与您的用户界面区域设置进行比较，您可能希望获取您的用户界面区域设置和资源的*父级*区域设置，并查看它们是否匹配。

这样，英国用户（en-GB）也将找到美国的文档（en-us）。同样，瑞士用户（de-ch）将找到德国的资源（de-de）。
<!--本文国际来源：[Getting Parent Culture](https://blog.idera.com/database-tools/powershell/powertips/getting-parent-culture/)-->


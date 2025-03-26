---
layout: post
date: 2023-03-08 00:00:24
title: "PowerShell 技能连载 - 将波长转换为 RGB"
description: PowerTip of the Day - Converting Wavelength to RGB
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是一种通用脚本语言，因此您可以使用它来完成各种任务。以下是一个将光波长转换为相应 RGB 颜色值的函数：

```powershell
function Convert-WavelengthToRgb
{
  # derived from http://www.physics.sfasu.edu/astro/color/spectra.html

  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [ValidateRange(380,780)]
    [int]
    $Wavelength,

    [double]
    $Gamma = 0.8,

    [int]
    [ValidateRange(1,255)]
    $Intensity = 255,

    [switch]
    $AdjustHumanSensitivity
  )

  process
  {
    #from: https://www.codedrome.com/exploring-the-visible-spectrum-in-python/
    $factor = 0

    $result = [PSCustomObject]@{
      Wavelength = $Wavelength
      R = 0
      G = 0
      B = 0
    }

    switch($Wavelength)
    {

      { $_ -lt 420 }  {
        $result.R = -($_ - 440) / 60
        $result.B = 1
        $factor = 0.3 + 0.7 * ($_ - 380) / 40
        break
      }

      { $_ -lt 440 }  {
        $result.R = -($_ - 440) / 60
        $result.B = 1
        $factor = 1
        break
      }

      { $_ -lt 490 }  {
        $result.G = ($_ - 440) / 50
        $result.B = 1
        $factor = 1
        break
      }

      { $_ -lt 510 }  {
        $result.B = -($_ - 510) / 20
        $result.G = 1
        $factor = 1
        break
      }

      { $_ -lt 580 }  {
        $result.R = ($_ - 510) / 70
        $result.G = 1
        $factor = 1
        break
      }

      { $_ -lt 645 }  {
        $result.G = -($_ - 645) / 65
        $result.R = 1
        $factor = 1
        break
      }
      { $_ -le 700    }  {
        $result.R = 1
        $factor = 1
        break
      }


      { $_ -le 780 }  {
        $result.R = 1
        $factor = 0.3 + 0.7 * (780 - $_) / 80
        break
      }
    }

    if ($AdjustHumanSensitivity.IsPresent -eq $false) { $factor = 1 }

    $result.R = [Math]::Pow( ($result.R * $factor), $gamma)    * $Intensity -as [int]
    $result.G = [Math]::Pow( ($result.G * $factor), $gamma)    * $Intensity -as [int]
    $result.B = [Math]::Pow( ($result.B * $factor), $gamma)    * $Intensity -as [int]

    return $result
  }
}
```

现在，将整个可见光谱转换为相应的 RGB 值就变得简单了：

```powershell
# Calculate RGB values for the visible light spectrum (wavelengths)

380..780 |
  Convert-WavelengthToRgb |
  Out-GridView -Title 'Without Correction'
```

由于人眼对不同颜色的敏感度不同，该函数甚至可以考虑此敏感度并自动应用校正：

```powershell
380..780 |
  Convert-WavelengthToRgb -AdjustHumanSensitivity |
  Out-GridView -Title 'With Correction'
```
<!--本文国际来源：[Converting Wavelength to RGB](https://blog.idera.com/database-tools/powershell/powertips/converting-wavelength-to-rgb/)-->


---
layout: post
date: 2022-07-19 00:00:00
title: "PowerShell 技能连载 - 创建世界地图图像"
description: PowerTip of the Day - Creating World Map Graphs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您有与国家/地区有关的数据，则可能需要可视化并突出显示此地理数据。经典的数据图标在这里不起作用。

幸运的是，PowerShell 可以使用免费的在线地理图表。这是您可以试试这个函数：

```powershell
function Show-MapGraph
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        $InputObject,

        [Parameter(Mandatory)]
        [string]
        $Property,

        [string]
        $Label = 'Items'
    )

    begin
    {

        $bucket = [System.Collections.ArrayList]::new()
    }
    process
    {
        $null = $bucket.Add($_)
    }
    end
    {
        $groups = $bucket | Where-Object { $_.$Property } | Group-Object -Property $Property -NoElement
        $data = foreach ($group in $groups)
        {
            "['{0}',{1}]" -f $group.Name, $group.Count
        }

        $datastring = $data -join "`r`n,"

        $HTMLPage = @"
      google.charts.load('current', {
        'packages':['geochart'],
      });
      google.charts.setOnLoadCallback(drawRegionsMap);

      function drawRegionsMap() {
        var data = google.visualization.arrayToDataTable([
          ['Country', '$Label'],
          $datastring
        ]);

        var options = {

          colorAxis: {colors: ['#00FF00', '#004400']},
          backgroundColor: '#81d4fa',
          datalessRegionColor: '#AAAABB',
          defaultColor: '#f5f5f5',
        };

        var chart = new google.visualization.GeoChart(document.getElementById('regions_div'));

        chart.draw(data, options);
      }
"@

        $timestamp = Get-Date -Format 'HHmmss'
        $OutPath = "$env:temp\Graph$timestamp.html"
        $HTMLPage | Out-File -FilePath $OutPath -Encoding utf8
        Start-Process $outpath
    }
}
```

`Show-MapGraph` 基本原理是创建一个 HTML 网页，并通过适当的脚本调用填充它，然后显示它。您需要做的就是通过管道传入您的国家数据，并使用 `-Property` 指示对象的哪个属性包含国家名称。

<!--本文国际来源：[Creating World Map Graphs](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-world-map-graphs)-->


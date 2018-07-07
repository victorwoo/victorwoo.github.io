# 这是 XML 例子文件的存储路径：
$Path = ".\GBT2260-1999.xml"

# 将它加载入 XML 对象：
$xml = New-Object -TypeName XML
$xml.Load($Path)

$i = 0
$sb = New-Object -TypeName System.Text.StringBuilder
$xml.country.province | foreach {
    if ($_.city) {
        $_.city | foreach {
            if ($_.county) {
                $_.county[0]
            }
        }
    }
} | where { $_ -ne $null } | Get-Random -Count 200 | select -exp code -Unique code | foreach {
    $null = $sb.Append($_ + ' ');
    $i++
    if ($i % 11 -eq 0) {
        $null = $sb.AppendLine()
    }
}

$sb.ToString()
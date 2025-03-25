function ConvertFrom-ExcelColumn ($column) {
    $result = 0
    $ids = [System.Text.Encoding]::ASCII.GetBytes($column) | foreach {
        $result = $result * 26 + $_ - 64
    }
    return $result
}

function ConvertTo-ExcelColumn ($number) {
    $ids = while ($number -gt 0) {
        ($number - 1) % 26 + 1 + 64
        $number = [math]::Truncate(($number - 1) / 26)
    }

    [array]::Reverse($ids)
    return [System.Text.Encoding]::ASCII.GetString([array]$ids)
}

echo "A`t$(ConvertFrom-ExcelColumn A)"
echo "AB`t$(ConvertFrom-ExcelColumn AB)"
echo "AC`t$(ConvertFrom-ExcelColumn AC)"

echo ''

@(1..2) + @(25..28) | foreach {
    echo "$_`t$(ConvertTo-ExcelColumn $_)"
}
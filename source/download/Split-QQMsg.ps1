function Get-Status($status, $textLine, $lineNumber, $block) {
    $splitter = '================================================================'
    switch ($status) {
        'INIT' {
            if ($textLine -eq $splitter) {
                $status = 'ENTER_BLOCK'
            }
        }
        'ENTER_BLOCK' {
            if ($textLine -cmatch '消息分组:(.*)') {
	            $block.Group = $matches[1]
                $block.Target = $null
                $status = 'ENTER_GROUP'
                break
            } else {
	            Write-Error "[$lineNumber] [$status] $textLine"
                exit
            }
        }
        'ENTER_GROUP' {
            if ($textLine -eq $splitter) {
                $status = 'ENTER_SPLITTER'
                break
            } else {
                Write-Error "[$lineNumber] [$status] $textLine"
                exit
            }
        }
        'ENTER_SPLITTER' {
            if ($textLine -cmatch '消息对象:(.*)') {
	            $block.Target = $matches[1]
                $status = 'ENTER_TARGET'
                break
            } else {
	            Write-Error "[$lineNumber] [$status] $textLine"
                exit
            }
        }
        'ENTER_TARGET' {
            if ($textLine -eq $splitter) {
                $status = 'LEAVE_BLOCK'
                break
            } else {
                Write-Error "[$lineNumber] [$status] $textLine"
                exit
            }
        }
        'LEAVE_BLOCK' {
            if ($textLine -eq $splitter) {
                $status = 'ENTER_BLOCK'
                break
            } else {
                $status = 'CONTENT'
            }
        }
        'CONTENT' {
            if ($textLine -eq $splitter) {
                $status = 'ENTER_BLOCK'
                break
            } else {
                $status = 'CONTENT'
            }
        }
    }

    return $status
}

$status = 'INIT'
$lineNumber = 0
$block = @{}
$targetPath = $null
cat 全部消息记录.txt -Encoding UTF8 | foreach {
    $textLine = $_
    $lineNumber++
    $status = Get-Status $status $textLine $lineNumber $block
    switch ($status) {
        'LEAVE_BLOCK' {
            if ($block.Target -eq '最近联系人') {
                break
            }
            $dirName = $block.Group.Replace('*', '.')
            if (!(Test-Path $dirName)) {
                md $dirName | Out-Null
            }

            $fileName = $block.Target.Replace('*', '.')

            $targetPath = (Join-Path $dirName $fileName) + '.txt'
            if (Test-Path $targetPath) {
                del $targetPath
            }

            echo $targetPath
        }
        'CONTENT' {
            #echo $textLine
            if ($block.Target -eq '最近联系人') {
                break
            }
            Out-File -InputObject $textLine -Encoding utf8 -LiteralPath $targetPath -Append
        }
    }
}
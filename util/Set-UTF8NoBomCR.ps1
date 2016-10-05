.\Out-FileUtf8NoBom.ps1

dir ..\source\_posts\*.md | ForEach-Object {
    del temp.txt -ErrorAction SilentlyContinue
    $file = $_
    $encoding = .\Get-FileEncoding.ps1 $file.FullName
    echo $encoding
    gc $file -Encoding $encoding | ForEach-Object {
        Out-FileUtf8NoBom temp.txt $True $False $null $_
    }

    .\Set-Eol.ps1 'unix' temp.txt
}
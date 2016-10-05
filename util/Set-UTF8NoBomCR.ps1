dir ..\source\_posts\*.md | ForEach-Object {
    # del D:\temp.txt -ErrorAction SilentlyContinue
    $file = $_
    $encoding = .\Get-FileEncoding.ps1 $file.FullName
    if ($encoding.BodyName.StartsWith('utf-')) { $encoding = $encoding.BodyName.Replace('utf-', 'UTF') }
    if ($encoding.BodyName -eq 'ASCII') { $encoding = 'Ascii' }
    echo $encoding
    gc $file -Encoding $encoding | ForEach-Object {
        .\Out-FileUtf8NoBom.ps1 D:\temp.txt $False $False $null $_
    }

    .\Set-Eol.ps1 'unix' 'D:\temp.txt'
}
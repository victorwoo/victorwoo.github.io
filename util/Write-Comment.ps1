$downloadPath = '../source/img'
$relateUrl = '/img/'
$sourcePath = '../source/_posts'

function Replace-Comment($file) {
    $content = (Get-Content $file -Encoding UTF8 | % {
        $line = $PSItem
        #$line = $line -creplace '<!--more-->', '<!--'
        $line = $line -creplace '^本文国际来源.*$', '<!--$0-->'
        if ($line -cnotcontains '<!--more-->' -and $line -ne '- translation') {
            $line
        }
    })
    Set-Content -Encoding UTF8 $file -Value $content
    #Set-Content -Encoding UTF8 -NoNewline 'temp.md' -Value $content
    #Remove-Item $file
    #Rename-Item 'temp.md' $file
}

dir "$sourcePath/*.md" | % {
    Replace-Comment $_
}
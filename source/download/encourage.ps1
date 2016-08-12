function Get-Weight([string]$word) {
    $word = $word.ToLower()
    #Write-Host ([System.Text.Encoding]::ASCII.GetBytes($word) |
    #    ForEach-Object { $_ - 96 }) 
    return ([System.Text.Encoding]::ASCII.GetBytes($word) |
        ForEach-Object { $_ - 96 } |
        Measure-Object -Sum).Sum
}

# Test
# Get-Weight 'abc'

if (!$resp) {
    $resp = Invoke-WebRequest 'http://shakespeare.mit.edu/hamlet/full.html'
}

$fullText = $resp.ParsedHtml.documentElement.innerText
$words = [regex]::Matches($fullText, '\b\w+\b') |
    ForEach-Object { $_.Value } |
    Sort-Object -Unique

# The following code will procuce output:
# Luck
# Love
# Money
# Knowledge
# Leadership
# Workhard
# ATTITUDE
'Knowledge', 'Workhard', 'Luck', 'Love', 'Money', 'Leadership', 'ATTITUDE' |
    Sort-Object -Property @{Expression = { Get-Weight $_ }}

$words |
    Sort-Object -Property @{Expression = { Get-Weight $_ }} |
    ForEach-Object {
        "$_`t$(Get-Weight $_)"
    }
$file = "c:\Users\reyca\Downloads\SCIMATHIX\frontend\lib\data\services\api_service.dart"
$lines = Get-Content $file

$newLines = @()
foreach ($line in $lines) {
    if ($line -match "^\s+print\('(.+?) Error: \\\$e'\);$") {
        $label = $Matches[1]
        $indent = $line -replace "^(\s+).*", '$1'
        $newLines += "${indent}AppLogger.error('$label', e);"
    }
    elseif ($line -match "^\s+print\('(.+?) Failed \[") {
        $indent = $line -replace "^(\s+).*", '$1'
        $replaced = $line.Trim() -replace "^print\(", "AppLogger.warning("
        $newLines += "${indent}$replaced"
    }
    elseif ($line -match "^\s+print\('(.+?) Failed:") {
        $indent = $line -replace "^(\s+).*", '$1'
        $replaced = $line.Trim() -replace "^print\(", "AppLogger.warning("
        $newLines += "${indent}$replaced"
    }
    elseif ($line -match "^\s+print\('(.+?) Failed with") {
        $indent = $line -replace "^(\s+).*", '$1'
        $replaced = $line.Trim() -replace "^print\(", "AppLogger.warning("
        $newLines += "${indent}$replaced"
    }
    else {
        $newLines += $line
    }
}

$newLines | Set-Content $file

# wrap_qstr.ps1
# Wraps hardcoded QML string literals with qsTr().
# Usage from project root:
#   .\scripts\wrap_qstr.ps1 -DryRun   # preview
#   .\scripts\wrap_qstr.ps1           # apply
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'

# Patterns for values that must NOT be wrapped
$skipPatterns = @(
    '^\s*$',
    '^https?://',
    '^qrc:/',
    '^v\d+\.\d+',
    '^\d+(\.\d+)?$',
    '^#[0-9a-fA-F]{3,8}$',
    '^[a-z][a-zA-Z0-9_]*$',
    '^\w+\.\w+(\.\w+)*$',
    '^(true|false|null|undefined)$',
    '^[a-z]+(-[a-z]+)+$',
    '^en$|^pt_BR$|^es$|^fr$|^de$'
)

# Property names whose values are user-visible text
$props = 'text|title|label|placeholder|placeholderText|tooltip|description|emptyText|headerText|footerText|buttonText|confirmText|hint|statusText'

# Regex: property: "value" where value is not already wrapped in qsTr(
$lineRegex = [regex]('(\b(?:' + $props + ')):\s+(?!qsTr\()(?!i18n\()(?!Qt\.)\"([^\"\\]+)\"')

$qmlRoot = Join-Path $PSScriptRoot '..\valkyrieGUI\resources\qml'
$qmlRoot = (Resolve-Path $qmlRoot).Path

$qmlFiles = Get-ChildItem -Path $qmlRoot -Recurse -Filter '*.qml'
$totalFiles  = 0
$totalWraps  = 0

foreach ($file in $qmlFiles) {
    $content  = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $original = $content
    $wrapCount = 0

    $content = $lineRegex.Replace($content, {
        param($m)
        $propName = $m.Groups[1].Value
        $val      = $m.Groups[2].Value

        # Skip strings preceding this match that are in a comment or console.log
        $idx  = $m.Index
        $line = $content.Substring([Math]::Max(0, $idx - 200), [Math]::Min(200, $idx))
        $lineStart = $line.LastIndexOfAny([char[]]@([char]"`n", [char]"`r"))
        if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart++ }
        $lineCtx = $line.Substring($lineStart)
        if ($lineCtx -match '//|console\.(log|warn|error)|qDebug') {
            return $m.Value
        }

        # Check skip patterns
        foreach ($pattern in $skipPatterns) {
            if ($val -match $pattern) { return $m.Value }
        }

        $script:wrapCount++
        return ($propName + ': qsTr("' + $val + '")')
    })

    if ($content -ne $original) {
        $totalFiles++
        $totalWraps += $wrapCount
        $relPath = $file.FullName.Replace($qmlRoot, '').TrimStart('\/')

        if ($DryRun) {
            Write-Host "[DryRun] $relPath — $wrapCount string(s) would be wrapped" -ForegroundColor Yellow
        } else {
            [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "Updated: $relPath" -ForegroundColor Green
        }
    }
}

Write-Host ''
if ($DryRun) {
    Write-Host "DRY RUN: $totalWraps string(s) in $totalFiles file(s) would be wrapped." -ForegroundColor Cyan
    Write-Host "Run without -DryRun to apply."
} else {
    Write-Host "Done: $totalWraps string(s) wrapped in $totalFiles file(s)." -ForegroundColor Cyan
    Write-Host "Review with: git diff valkyrieGUI/resources/qml/"
    Write-Host "Then run:    cmake --build build --target update_translations"
}

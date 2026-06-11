$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'assets/logo/omnigo-logo.jpg'

function Save-Png {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Size
    )

    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $root $Path }
    $dir = Split-Path $fullPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    $src = [System.Drawing.Image]::FromFile($source)
    try {
        $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.Clear([System.Drawing.Color]::White)

                $scale = [Math]::Max($Size / $src.Width, $Size / $src.Height)
                $width = [int][Math]::Ceiling($src.Width * $scale)
                $height = [int][Math]::Ceiling($src.Height * $scale)
                $x = [int](($Size - $width) / 2)
                $y = [int](($Size - $height) / 2)

                $graphics.DrawImage($src, $x, $y, $width, $height)
            }
            finally {
                $graphics.Dispose()
            }

            $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $src.Dispose()
    }
}

function Save-Ico {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Join-Path $root $Path
    $tempPng = [System.IO.Path]::GetTempFileName() + '.png'
    Save-Png $tempPng 256
    $pngBytes = [System.IO.File]::ReadAllBytes($tempPng)

    $stream = [System.IO.File]::Create($fullPath)
    try {
        $writer = New-Object System.IO.BinaryWriter($stream)
        try {
            $writer.Write([UInt16]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]1)
            $writer.Write([Byte]0)
            $writer.Write([Byte]0)
            $writer.Write([Byte]0)
            $writer.Write([Byte]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]32)
            $writer.Write([UInt32]$pngBytes.Length)
            $writer.Write([UInt32]22)
            $writer.Write($pngBytes)
        }
        finally {
            $writer.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }

    Remove-Item $tempPng -Force
}

Copy-Item $source (Join-Path $root 'apps/admin/assets/logo/omnigo-logo.jpg') -Force
Copy-Item $source (Join-Path $root 'apps/pos/assets/logo/omnigo-logo.jpg') -Force
Copy-Item $source (Join-Path $root 'apps/customer/assets/logo/omnigo-logo.jpg') -Force

$androidIcons = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($app in @('pos', 'customer')) {
    foreach ($entry in $androidIcons.GetEnumerator()) {
        Save-Png "apps/$app/android/app/src/main/res/$($entry.Key)/ic_launcher.png" $entry.Value
    }
}

$iosIcons = @{
    'Icon-App-20x20@1x.png' = 20
    'Icon-App-20x20@2x.png' = 40
    'Icon-App-20x20@3x.png' = 60
    'Icon-App-29x29@1x.png' = 29
    'Icon-App-29x29@2x.png' = 58
    'Icon-App-29x29@3x.png' = 87
    'Icon-App-40x40@1x.png' = 40
    'Icon-App-40x40@2x.png' = 80
    'Icon-App-40x40@3x.png' = 120
    'Icon-App-60x60@2x.png' = 120
    'Icon-App-60x60@3x.png' = 180
    'Icon-App-76x76@1x.png' = 76
    'Icon-App-76x76@2x.png' = 152
    'Icon-App-83.5x83.5@2x.png' = 167
    'Icon-App-1024x1024@1x.png' = 1024
}
foreach ($app in @('pos', 'customer')) {
    foreach ($entry in $iosIcons.GetEnumerator()) {
        Save-Png "apps/$app/ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.Key)" $entry.Value
    }
}

$macIcons = @{
    'app_icon_16.png' = 16
    'app_icon_32.png' = 32
    'app_icon_64.png' = 64
    'app_icon_128.png' = 128
    'app_icon_256.png' = 256
    'app_icon_512.png' = 512
    'app_icon_1024.png' = 1024
}
foreach ($entry in $macIcons.GetEnumerator()) {
    Save-Png "apps/admin/macos/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.Key)" $entry.Value
}

foreach ($app in @('admin', 'pos', 'customer')) {
    Save-Png "apps/$app/web/favicon.png" 32
    Save-Png "apps/$app/web/icons/Icon-192.png" 192
    Save-Png "apps/$app/web/icons/Icon-512.png" 512
    Save-Png "apps/$app/web/icons/Icon-maskable-192.png" 192
    Save-Png "apps/$app/web/icons/Icon-maskable-512.png" 512
    Save-Ico "apps/$app/windows/runner/resources/app_icon.ico"
}

Write-Host 'OMNIGO icons generated.'

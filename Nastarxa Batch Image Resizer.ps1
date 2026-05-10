param(
    [string]$InputPath,
    [string]$OutputPath,
    [int]$Scale,
    [int]$Dpi,
    [int]$JpegQuality = 85
)

Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Image]::FromFile($InputPath)
$w = [int]($img.Width * $Scale / 100)
$h = [int]($img.Height * $Scale / 100)

$bmp = New-Object System.Drawing.Bitmap($w, $h)
$bmp.SetResolution($Dpi, $Dpi)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$g.DrawImage($img, 0, 0, $w, $h)
$g.Dispose()
$img.Dispose()

$ext = [System.IO.Path]::GetExtension($OutputPath).ToLower()

if ($ext -in '.jpg','.jpeg') {
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $JpegQuality)
    $bmp.Save($OutputPath, $codec, $ep)
} else {
    $fmt = @{
        '.png'  = [System.Drawing.Imaging.ImageFormat]::Png
        '.bmp'  = [System.Drawing.Imaging.ImageFormat]::Bmp
        '.tif'  = [System.Drawing.Imaging.ImageFormat]::Tiff
        '.tiff' = [System.Drawing.Imaging.ImageFormat]::Tiff
        '.webp' = [System.Drawing.Imaging.ImageFormat]::Png
    }
    $bmp.Save($OutputPath, $fmt[$ext])
}
$bmp.Dispose()

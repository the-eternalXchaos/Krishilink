# Debug export shims
$files = @(
    "lib\services\auth_services.dart",
    "lib\services\farmer_api_service.dart", 
    "lib\services\payment_service.dart"
)

foreach ($file in $files) {
    Write-Host "=== $file ===" -ForegroundColor Yellow
    if (Test-Path $file) {
        Write-Host "File exists" -ForegroundColor Green
        $content = Get-Content $file -Raw
        Write-Host "Content length: $($content.Length)"
        Write-Host "Content: $content"
        
        if ($content -match "export") {
            Write-Host "Contains export: YES" -ForegroundColor Green
        } else {
            Write-Host "Contains export: NO" -ForegroundColor Red
        }
        
        if ($content -match "src/") {
            Write-Host "Contains src/: YES" -ForegroundColor Green
        } else {
            Write-Host "Contains src/: NO" -ForegroundColor Red
        }
        
        if ($content -match "package:krishi_link/src/") {
            Write-Host "Contains package:krishi_link/src/: YES" -ForegroundColor Green
        } else {
            Write-Host "Contains package:krishi_link/src/: NO" -ForegroundColor Red
        }
    } else {
        Write-Host "File does not exist" -ForegroundColor Red
    }
    Write-Host ""
}

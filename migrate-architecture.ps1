# Feature-First Architecture Migration Script
# PowerShell version for Windows development

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

Write-Host "🏗️  Feature-First Architecture Migration" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    Write-Host ""
}

# Configuration
$srcRoot = "lib/src"
$legacyRoot = "lib"

# Ensure src structure exists
$directories = @(
    "$srcRoot/core/networking",
    "$srcRoot/core/errors", 
    "$srcRoot/core/storage",
    "$srcRoot/core/models",
    "$srcRoot/features/auth/data",
    "$srcRoot/features/auth/presentation",
    "$srcRoot/features/payment/data",
    "$srcRoot/features/payment/presentation", 
    "$srcRoot/features/marketplace/data",
    "$srcRoot/features/marketplace/presentation",
    "$srcRoot/features/farmer/data",
    "$srcRoot/features/farmer/presentation",
    "$srcRoot/features/weather/data",
    "$srcRoot/features/weather/presentation",
    "$srcRoot/features/chat/data",
    "$srcRoot/features/chat/presentation",
    "$srcRoot/features/notification/data",
    "$srcRoot/features/notification/presentation"
)

Write-Host "📁 Creating directory structure..." -ForegroundColor Green
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        if (!$DryRun) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Write-Host "   Created: $dir" -ForegroundColor Gray
    } else {
        if ($Verbose) {
            Write-Host "   Exists:  $dir" -ForegroundColor DarkGray
        }
    }
}

# Function to create export shim
function New-ExportShim {
    param(
        [string]$LegacyPath,
        [string]$NewPath,
        [string]$Description
    )
    
    $relativePath = [System.IO.Path]::GetRelativePath([System.IO.Path]::GetDirectoryName($LegacyPath), $NewPath)
    $relativePath = $relativePath.Replace('\', '/')
    
    $shimContent = @"
// Legacy $Description - now exports the new feature-first architecture
export '$relativePath';
"@

    if (!$DryRun) {
        Set-Content -Path $LegacyPath -Value $shimContent -Encoding UTF8
    }
    
    Write-Host "   📎 Created shim: $LegacyPath → $NewPath" -ForegroundColor Blue
}

# Services to migrate/create shims for
$serviceShims = @(
    @{
        Legacy = "lib/services/auth_services.dart"
        New = "lib/src/features/auth/data/auth_service.dart"
        Description = "authentication service"
    },
    @{
        Legacy = "lib/services/farmer_api_service.dart" 
        New = "lib/src/features/farmer/data/farmer_api_service.dart"
        Description = "farmer API service"
    },
    @{
        Legacy = "lib/services/payment_service.dart"
        New = "lib/src/features/payment/data/payment_service.dart" 
        Description = "payment service"
    },
    @{
        Legacy = "lib/features/weather/weather_api_services.dart"
        New = "lib/src/features/weather/data/weather_api_service.dart"
        Description = "weather API service" 
    },
    @{
        Legacy = "lib/core/components/product/management/unified_product_api_services.dart"
        New = "lib/src/features/marketplace/data/marketplace_service.dart"
        Description = "marketplace service"
    }
)

Write-Host ""
Write-Host "🔗 Creating export shims..." -ForegroundColor Green

foreach ($shim in $serviceShims) {
    if (Test-Path $shim.Legacy) {
        # Check if it's already a shim
        $content = Get-Content $shim.Legacy -Raw
        if ($content -match "export\s+[`"'].*src/") {
            if ($Verbose) {
                Write-Host "   ✅ Already a shim: $($shim.Legacy)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "   🔄 Converting to shim: $($shim.Legacy)" -ForegroundColor Yellow
            if (!$DryRun) {
                # Backup original file
                $backupPath = "$($shim.Legacy).backup"
                Copy-Item $shim.Legacy $backupPath
                Write-Host "      💾 Backup created: $backupPath" -ForegroundColor Gray
            }
            New-ExportShim -LegacyPath $shim.Legacy -NewPath $shim.New -Description $shim.Description
        }
    } else {
        Write-Host "   ❓ Legacy file not found: $($shim.Legacy)" -ForegroundColor Yellow
    }
}

# Check for BaseService compliance
Write-Host ""
Write-Host "🔍 Checking BaseService compliance..." -ForegroundColor Green

$serviceFiles = Get-ChildItem -Path "$srcRoot/features" -Filter "*.dart" -Recurse | Where-Object { $_.FullName -like "*data*" }

foreach ($file in $serviceFiles) {
    $content = Get-Content $file.FullName -Raw
    $hasServiceClass = $content -match "class\s+\w*Service"
    $extendsBaseService = $content -match "extends\s+BaseService"
    $importsBaseService = $content -match "import.*base_service"
    
    if ($hasServiceClass -and !$extendsBaseService) {
        Write-Host "   ⚠️  $($file.Name): Should extend BaseService" -ForegroundColor Yellow
    } elseif ($hasServiceClass -and $extendsBaseService -and !$importsBaseService) {
        Write-Host "   ❌ $($file.Name): Extends BaseService but missing import" -ForegroundColor Red
    } elseif ($hasServiceClass -and $extendsBaseService -and $importsBaseService) {
        if ($Verbose) {
            Write-Host "   ✅ $($file.Name): Properly extends BaseService" -ForegroundColor DarkGray
        }
    }
}

# Generate architecture report
Write-Host ""
Write-Host "📊 Architecture Status Report" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$srcCoreFiles = @(Get-ChildItem -Path "$srcRoot/core" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue).Count
$srcFeatureFiles = @(Get-ChildItem -Path "$srcRoot/features" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue).Count
$legacyServiceFiles = @(Get-ChildItem -Path "lib/services" -Filter "*.dart" -ErrorAction SilentlyContinue).Count
$legacyFeatureFiles = @(Get-ChildItem -Path "lib/features" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue).Count

$exportShims = 0
Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "export\s+[`"'].*src/") {
        $exportShims++
    }
}

Write-Host ""
Write-Host "🏗️  New Architecture (lib/src/):" -ForegroundColor Green
Write-Host "   Core files: $srcCoreFiles" -ForegroundColor Gray
Write-Host "   Feature files: $srcFeatureFiles" -ForegroundColor Gray
Write-Host ""
Write-Host "🔗 Export Shims: $exportShims" -ForegroundColor Blue
Write-Host ""
Write-Host "📁 Legacy Structure:" -ForegroundColor Yellow
Write-Host "   Services: $legacyServiceFiles" -ForegroundColor Gray
Write-Host "   Features: $legacyFeatureFiles" -ForegroundColor Gray
Write-Host ""

$totalNew = $srcCoreFiles + $srcFeatureFiles
$totalLegacy = $legacyServiceFiles + $legacyFeatureFiles

if (($totalNew + $totalLegacy) -gt 0) {
    $progress = [math]::Round(100 * $totalNew / ($totalNew + $totalLegacy), 1)
    Write-Host "📈 Migration Progress: $progress% ($totalNew/$($totalNew + $totalLegacy) files)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Magenta
Write-Host "   • Migrate controllers to src/features/**/presentation/" -ForegroundColor Gray
Write-Host "   • Migrate screens to src/features/**/presentation/" -ForegroundColor Gray  
Write-Host "   • Create remaining export shims" -ForegroundColor Gray
Write-Host "   • Ensure all services extend BaseService" -ForegroundColor Gray
Write-Host "   • Run tests to verify migration" -ForegroundColor Gray

Write-Host ""
if ($DryRun) {
    Write-Host "🔍 Dry run completed - no files were modified" -ForegroundColor Yellow
} else {
    Write-Host "✅ Migration script completed successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "📚 For detailed guidelines, see ARCHITECTURE.md" -ForegroundColor Cyan

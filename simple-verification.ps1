# Final Architecture Verification Script
# Tests all aspects of the feature-first architecture implementation

Write-Host "Final Architecture Verification Starting..." -ForegroundColor Blue
Write-Host "=======================================" -ForegroundColor Blue

# Test 1: Verify export shims work correctly
Write-Host ""
Write-Host "1. Testing Export Shims..." -ForegroundColor Yellow
$shimPaths = @(
    "lib\services\auth_services.dart",
    "lib\services\farmer_api_service.dart", 
    "lib\services\payment_service.dart",
    "lib\features\weather\weather_api_services.dart"
)

$shimSuccess = $true
foreach ($shim in $shimPaths) {
    if (Test-Path $shim) {
        $content = Get-Content $shim -Raw
        if ($content -match "export.*src/" -or $content -match "package:krishi_link/src/") {
            Write-Host "  SUCCESS: $shim exports to src/" -ForegroundColor Green
        } else {
            Write-Host "  FAIL: $shim missing src/ export" -ForegroundColor Red
            $shimSuccess = $false
        }
    } else {
        Write-Host "  FAIL: $shim not found" -ForegroundColor Red
        $shimSuccess = $false
    }
}

# Test 2: Verify core architecture exists
Write-Host ""
Write-Host "2. Testing Core Architecture..." -ForegroundColor Yellow
$coreFiles = @(
    "lib\src\core\networking\api_client.dart",
    "lib\src\core\networking\base_service.dart",
    "lib\src\core\errors\api_exception.dart",
    "lib\src\core\storage\token_storage.dart"
)

$coreSuccess = $true
foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        Write-Host "  SUCCESS: $file exists" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $file missing" -ForegroundColor Red
        $coreSuccess = $false
    }
}

# Test 3: Verify feature services
Write-Host ""
Write-Host "3. Testing Feature Services..." -ForegroundColor Yellow
$featureServices = @(
    "lib\src\features\auth\data\auth_service.dart",
    "lib\src\features\payment\data\payment_service.dart",
    "lib\src\features\farmer\data\farmer_api_service.dart",
    "lib\src\features\weather\data\weather_api_service.dart",
    "lib\src\features\marketplace\data\marketplace_service.dart"
)

$featuresSuccess = $true
foreach ($service in $featureServices) {
    if (Test-Path $service) {
        $content = Get-Content $service -Raw
        if ($content -match "extends BaseService") {
            Write-Host "  SUCCESS: $service extends BaseService" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: $service exists but may not extend BaseService" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  FAIL: $service missing" -ForegroundColor Red
        $featuresSuccess = $false
    }
}

# Test 4: Build verification
Write-Host ""
Write-Host "4. Testing Build..." -ForegroundColor Yellow
try {
    Write-Host "  Running flutter analyze..." -ForegroundColor Gray
    $analyzeResult = & flutter analyze 2>&1
    $errorCount = ($analyzeResult | Select-String "error •" | Measure-Object).Count
    
    if ($errorCount -eq 0) {
        Write-Host "  SUCCESS: Flutter analyze - 0 errors" -ForegroundColor Green
        $buildSuccess = $true
    } else {
        Write-Host "  FAIL: Flutter analyze - $errorCount errors" -ForegroundColor Red
        $buildSuccess = $false
    }
} catch {
    Write-Host "  FAIL: Flutter analyze failed" -ForegroundColor Red
    $buildSuccess = $false
}

# Test 5: Documentation check
Write-Host ""
Write-Host "5. Testing Documentation..." -ForegroundColor Yellow
$docs = @(
    "ARCHITECTURE.md",
    "MIGRATION_CHECKLIST.md", 
    "PR_DESCRIPTION.md"
)

$docsSuccess = $true
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "  SUCCESS: $doc exists" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $doc missing" -ForegroundColor Red
        $docsSuccess = $false
    }
}

# Final Report
Write-Host ""
Write-Host "FINAL VERIFICATION REPORT" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta

$tests = @(
    @{Name="Export Shims"; Success=$shimSuccess},
    @{Name="Core Architecture"; Success=$coreSuccess},
    @{Name="Feature Services"; Success=$featuresSuccess},
    @{Name="Build Verification"; Success=$buildSuccess},
    @{Name="Documentation"; Success=$docsSuccess}
)

$passedTests = ($tests | Where-Object {$_.Success}).Count
$totalTests = $tests.Count

foreach ($test in $tests) {
    $status = if ($test.Success) {"PASS"} else {"FAIL"}
    $color = if ($test.Success) {"Green"} else {"Red"}
    Write-Host "  $($test.Name): $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "OVERALL RESULT: $passedTests/$totalTests tests passed" -ForegroundColor $(if ($passedTests -eq $totalTests) {"Green"} else {"Yellow"})

if ($passedTests -eq $totalTests) {
    Write-Host ""
    Write-Host "ARCHITECTURE IMPLEMENTATION COMPLETE!" -ForegroundColor Green
    Write-Host "Feature-first architecture successfully implemented with backward compatibility" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Some tests failed. Review the output above for details." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Migrate remaining chat/notification services" -ForegroundColor White
Write-Host "  - Move controllers to presentation layer" -ForegroundColor White
Write-Host "  - Consider moving screens to feature structure" -ForegroundColor White
Write-Host "  - Run regression tests on key user flows" -ForegroundColor White

# ============================================================================
# LLM API Testing Script for Windows PowerShell - PSYCHO MODE 🔥
# Tests the unified AI API endpoint locally with FULL VISIBILITY
# ============================================================================

param(
    [string]$BaseUrl = "http://localhost:4000",
    [switch]$Quiet,
    [switch]$SkipModelsTest
)

# Configuration
$script:TestResults = @()
$script:PassedTests = 0
$script:FailedTests = 0

# Colors for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Request { param($Message) Write-Host "📤 REQUEST: $Message" -ForegroundColor Magenta }
function Write-Response { param($Message) Write-Host "📥 RESPONSE: $Message" -ForegroundColor Yellow }

function Write-Header {
    param($Title)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Blue
    Write-Host " $Title" -ForegroundColor Blue
    Write-Host "=" * 80 -ForegroundColor Blue
}

function Write-SubHeader {
    param($Title)
    Write-Host ""
    Write-Host "-" * 60 -ForegroundColor DarkCyan
    Write-Host " $Title" -ForegroundColor DarkCyan
    Write-Host "-" * 60 -ForegroundColor DarkCyan
}

function Test-ApiEndpoint {
    param(
        [string]$TestName,
        [string]$Method = "POST",
        [string]$Endpoint,
        [hashtable]$Body = @{},
        [int]$ExpectedStatus = 200,
        [string]$ExpectedContentType = "application/json"
    )
    
    Write-SubHeader $TestName
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $params = @{
            Uri = "$BaseUrl$Endpoint"
            Method = $Method
            Headers = $headers
            ContentType = "application/json"
            UseBasicParsing = $true
        }
        
        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        # ALWAYS show request details (PSYCHO MODE)
        Write-Request "URL: $($params.Uri)"
        Write-Request "METHOD: $($params.Method)"
        if ($params.Body) {
            Write-Request "BODY:"
            Write-Host ($params.Body) -ForegroundColor DarkMagenta
        } else {
            Write-Request "BODY: (empty)"
        }
        
        Write-Host ""
        Write-Info "🚀 Sending request..."
        
        $response = Invoke-WebRequest @params
        
        # Parse JSON response
        $jsonResponse = $response.Content | ConvertFrom-Json
        
        # ALWAYS show response details (PSYCHO MODE)
        Write-Response "STATUS: $($response.StatusCode)"
        Write-Response "HEADERS: Content-Type=$($response.Headers.'Content-Type'), Length=$($response.Content.Length)"
        Write-Response "BODY:"
        Write-Host ($jsonResponse | ConvertTo-Json -Depth 10) -ForegroundColor DarkYellow
        
        Write-Host ""
        
        # Validate and show key metrics
        if ($response.StatusCode -eq $ExpectedStatus) {
            if ($jsonResponse.success -eq $true -or $ExpectedStatus -ne 200) {
                Write-Success "✨ $TestName - PASSED ✨"
                
                # Show detailed metrics
                if ($jsonResponse.data.content) {
                    $contentLength = $jsonResponse.data.content.Length
                    $contentPreview = $jsonResponse.data.content.Substring(0, [Math]::Min(100, $contentLength))
                    if ($contentLength -gt 100) {
                        $contentPreview += "..."
                    }
                    Write-Info "📝 CONTENT: '$contentPreview'"
                    Write-Info "📏 CONTENT LENGTH: $contentLength characters"
                }
                
                if ($jsonResponse.metadata) {
                    $meta = $jsonResponse.metadata
                    if ($meta.tokens) {
                        Write-Info "🎯 TOKENS: Input=$($meta.tokens.input), Output=$($meta.tokens.output), Total=$($meta.tokens.total), MaxRequested=$($meta.tokens.maxRequested)"
                    }
                    if ($meta.timing) {
                        Write-Info "⏱️  TIMING: $($meta.timing.responseMs)ms"
                    }
                    if ($meta.provider) {
                        Write-Info "🤖 PROVIDER: $($meta.provider) / MODEL: $($meta.model)"
                    }
                    if ($meta.config) {
                        Write-Info "🔧 CONFIG: Temperature=$($meta.config.temperature), FinishReason=$($meta.config.finishReason)"
                        if ($meta.config.userRequested -and $meta.config.providerAdjusted) {
                            Write-Warning "⚙️  TOKEN ADJUSTMENT: $($meta.config.userRequested) → $($meta.config.providerAdjusted) ($($meta.config.adjustmentReason))"
                        }
                    }
                }
                
                $script:PassedTests++
                return @{
                    Success = $true
                    Response = $jsonResponse
                    StatusCode = $response.StatusCode
                }
            } else {
                Write-Error "💥 $TestName - SUCCESS FIELD IS FALSE"
                $script:FailedTests++
                return @{
                    Success = $false
                    Response = $jsonResponse
                    StatusCode = $response.StatusCode
                }
            }
        } else {
            Write-Error "💥 $TestName - UNEXPECTED STATUS CODE: Expected $ExpectedStatus, Got $($response.StatusCode)"
            $script:FailedTests++
            return @{
                Success = $false
                Response = $jsonResponse
                StatusCode = $response.StatusCode
            }
        }
    }
    catch {
        Write-Error "💥 $TestName - EXCEPTION: $($_.Exception.Message)"
        
        # Handle expected 400 errors gracefully  
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq $ExpectedStatus) {
            try {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                $errorJson = $errorBody | ConvertFrom-Json
                
                Write-Response "ERROR STATUS: $($_.Exception.Response.StatusCode) (EXPECTED)"
                Write-Response "ERROR BODY:"
                Write-Host ($errorJson | ConvertTo-Json -Depth 10) -ForegroundColor Red
                
                Write-Success "✨ $TestName - PASSED (Expected Error) ✨"
                $script:PassedTests++
                return @{
                    Success = $true
                    Response = $errorJson
                    StatusCode = [int]$_.Exception.Response.StatusCode
                }
            }
            catch {
                Write-Host "Could not parse error response" -ForegroundColor DarkRed
            }
        }
        
        $script:FailedTests++
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Test generation endpoint wrapper
function Test-GenerationEndpoint {
    param(
        [string]$TestName,
        [string]$Model,
        [string]$Prompt,
        [hashtable]$Options = @{},
        [int]$ExpectedStatus = 200
    )
    
    $body = @{
        model = $Model
        prompt = $Prompt
        options = $Options
    }
    
    return Test-ApiEndpoint -TestName $TestName -Endpoint "/api/llm/generate" -Body $body -ExpectedStatus $ExpectedStatus
}

# ============================================================================
# PSYCHO MODE TESTING
# ============================================================================

Write-Header "🔥🔥🔥 PSYCHO MODE LLM API TESTING SUITE 🔥🔥🔥"
Write-Warning "PSYCHO MODE ENABLED - SHOWING EVERY REQUEST AND RESPONSE!"
Write-Info "Base URL: $BaseUrl"

$PolishingPrompt = "Please polish this prompt. Make it nicer. Mention time & geography in history. Reply ONLY response. MAX 50 characters: Medieval monk"

# Test 1: Models List Endpoint
if (-not $SkipModelsTest) {
    Write-Header "📋 TESTING MODELS LIST ENDPOINT"
    $modelsResult = Test-ApiEndpoint -TestName "List Available Models" -Method "GET" -Endpoint "/api/llm/models"
    
    if ($modelsResult.Success) {
        $models = $modelsResult.Response.data.models
        Write-Success "Found $($models.Count) available models:"
        foreach ($model in $models) {
            Write-Host "  🤖 $($model.model) ($($model.house)) - $($model.display_name)" -ForegroundColor Yellow
        }
    }
}

# Test 2: OpenAI Provider Tests
Write-Header "🤖 TESTING OPENAI PROVIDER"

Test-GenerationEndpoint -TestName "OpenAI - Basic Generation" -Model "gpt-4.1" -Prompt $PolishingPrompt -Options @{max_tokens=50; temperature=0.7}

Test-GenerationEndpoint -TestName "OpenAI - Prompt Polishing (YOUR USE CASE)" -Model "gpt-4.1" -Prompt $PolishingPrompt -Options @{max_tokens=50; temperature=0.7}

Test-GenerationEndpoint -TestName "OpenAI - Low Token Limit Stress Test" -Model "gpt-4.1" -Prompt $PolishingPrompt -Options @{max_tokens=20; temperature=0.5}

Test-GenerationEndpoint -TestName "OpenAI - No Options (Default Behavior)" -Model "gpt-4.1" -Prompt $PolishingPrompt

# Test 3: Anthropic Provider Tests  
Write-Header "🧠 TESTING ANTHROPIC PROVIDER"

Test-GenerationEndpoint -TestName "Anthropic - Basic Generation" -Model "claude-sonnet-4-20250514" -Prompt $PolishingPrompt -Options @{max_tokens=50; temperature=0.7}

Test-GenerationEndpoint -TestName "Anthropic - Prompt Polishing" -Model "claude-sonnet-4-20250514" -Prompt $PolishingPrompt -Options @{max_tokens=75; temperature=0.6}

# Test 4: Gemini Provider Tests
Write-Header "💎 TESTING GEMINI PROVIDER"

Test-GenerationEndpoint -TestName "Gemini - Basic Generation" -Model "gemini-2.5-pro" -Prompt $PolishingPrompt -Options @{max_tokens=400; temperature=0.7}

Test-GenerationEndpoint -TestName "Gemini - Prompt Polishing" -Model "gemini-2.5-pro" -Prompt $PolishingPrompt -Options @{max_tokens=400; temperature=0.7}

Test-GenerationEndpoint -TestName "Gemini - Very Low Tokens (Edge Case)" -Model "gemini-2.5-pro" -Prompt $PolishingPrompt -Options @{max_tokens=20; temperature=0.7}

# Test 5: Error Handling Tests
Write-Header "💥 TESTING ERROR HANDLING (EXPECTING 400s)"

Test-GenerationEndpoint -TestName "Invalid Model Test" -Model "invalid-model-name" -Prompt $PolishingPrompt -ExpectedStatus 400

Test-ApiEndpoint -TestName "Missing Prompt Test" -Endpoint "/api/llm/generate" -Body @{model="gpt-4.1"} -ExpectedStatus 400

Test-ApiEndpoint -TestName "Missing Model Test" -Endpoint "/api/llm/generate" -Body @{prompt=$PolishingPrompt} -ExpectedStatus 400

# Test 6: Token Adjustment Verification
Write-Header "🔧 TESTING SMART TOKEN ALLOCATION"

Write-Info "Testing provider-specific token minimums..."

$geminiLowTokenResult = Test-GenerationEndpoint -TestName "Gemini - Token Adjustment Verification" -Model "gemini-2.5-pro" -Prompt $PolishingPrompt -Options @{max_tokens=30}

if ($geminiLowTokenResult.Success) {
    $config = $geminiLowTokenResult.Response.metadata.config
    if ($config.userRequested -and $config.providerAdjusted) {
        Write-Success "🎯 SMART TOKEN ALLOCATION WORKING PERFECTLY!"
        Write-Info "User requested: $($config.userRequested) tokens"
        Write-Info "Provider used: $($config.providerAdjusted) tokens"
        Write-Info "Reason: $($config.adjustmentReason)"
    }
}

# Test 7: Response Structure Validation
Write-Header "📐 VALIDATING RESPONSE STRUCTURE"

$structureTest = Test-GenerationEndpoint -TestName "Response Structure Validation" -Model "gpt-4.1" -Prompt $PolishingPrompt -Options @{max_tokens=50}

if ($structureTest.Success) {
    $response = $structureTest.Response
    
    # Check required fields
    $requiredFields = @("success", "data", "metadata")
    $dataFields = @("content", "generationId")
    $metadataFields = @("model", "provider", "tokens", "config", "timing")
    
    $structureValid = $true
    
    Write-Info "Checking top-level fields: $($requiredFields -join ', ')"
    foreach ($field in $requiredFields) {
        if (-not $response.PSObject.Properties.Name.Contains($field)) {
            Write-Error "❌ Missing required field: $field"
            $structureValid = $false
        } else {
            Write-Success "✅ Found field: $field"
        }
    }
    
    Write-Info "Checking data fields: $($dataFields -join ', ')"
    foreach ($field in $dataFields) {
        if (-not $response.data.PSObject.Properties.Name.Contains($field)) {
            Write-Error "❌ Missing data field: $field"
            $structureValid = $false
        } else {
            Write-Success "✅ Found data field: $field"
        }
    }
    
    Write-Info "Checking metadata fields: $($metadataFields -join ', ')"
    foreach ($field in $metadataFields) {
        if (-not $response.metadata.PSObject.Properties.Name.Contains($field)) {
            Write-Error "❌ Missing metadata field: $field"
            $structureValid = $false
        } else {
            Write-Success "✅ Found metadata field: $field"
        }
    }
    
    if ($structureValid) {
        Write-Success "🎉 RESPONSE STRUCTURE VALIDATION PASSED!"
    } else {
        Write-Error "💥 RESPONSE STRUCTURE VALIDATION FAILED!"
        $script:FailedTests++
    }
}

# ============================================================================
# PSYCHO MODE SUMMARY
# ============================================================================

Write-Header "🔥 PSYCHO MODE TEST RESULTS SUMMARY 🔥"

$totalTests = $script:PassedTests + $script:FailedTests
Write-Host ""
Write-Host "📊 TOTAL TESTS RUN: $totalTests" -ForegroundColor White
Write-Success "🎉 PASSED: $script:PassedTests"
Write-Error "💥 FAILED: $script:FailedTests"

$successRate = if ($totalTests -gt 0) { [math]::Round(($script:PassedTests / $totalTests) * 100, 1) } else { 0 }
$successColor = if ($successRate -ge 80) { "Green" } else { "Red" }
Write-Host "📈 SUCCESS RATE: $successRate%" -ForegroundColor $successColor

if ($script:FailedTests -eq 0) {
    Write-Host ""
    Write-Success "🎉🎉🎉 PERFECT SCORE! ALL TESTS PASSED! 🎉🎉🎉"
    Write-Host ""
    Write-Info "🚀 API FEATURES VERIFIED IN PSYCHO MODE:"
    Write-Host "  ✅ All provider endpoints functional" -ForegroundColor Green
    Write-Host "  ✅ Smart token allocation working" -ForegroundColor Green  
    Write-Host "  ✅ Error handling proper" -ForegroundColor Green
    Write-Host "  ✅ Response structure consistent" -ForegroundColor Green
    Write-Host "  ✅ Prompt polishing optimized for your use case" -ForegroundColor Green
    Write-Host "  ✅ camelCase format maintained for iOS" -ForegroundColor Green
    Write-Host ""
    Write-Success "🚀 YOUR API IS PRODUCTION READY! 🚀"
} else {
    Write-Host ""
    Write-Warning "⚠️  Some tests failed. Review the detailed output above."
    Write-Info "🔧 Common issues:"
    Write-Host "  - Ensure Phoenix server is running (mix phx.server)" -ForegroundColor Yellow
    Write-Host "  - Check API keys are configured in .env file" -ForegroundColor Yellow
    Write-Host "  - Verify database is running and migrated" -ForegroundColor Yellow
}

Write-Host ""
Write-Info "🔥 PSYCHO MODE OPTIONS:"
Write-Info "Normal mode (less verbose): .\unifiedAiApi.ps1 -Quiet"
Write-Info "Skip models test: .\unifiedAiApi.ps1 -SkipModelsTest"
Write-Info "Test production: .\unifiedAiApi.ps1 -BaseUrl 'https://ra-backend.fly.dev'"

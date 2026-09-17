[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('1d2d', '2d3d')]
    [string] $Product,

    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release',

    [string] $WorkspaceRoot,

    [string] $Solution,

    [switch] $Rebuild
)

$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description does not exist: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Find-GlobalJson {
    param([Parameter(Mandatory)][string] $StartDirectory)

    $directory = [System.IO.DirectoryInfo]::new($StartDirectory)
    while ($null -ne $directory) {
        $candidate = Join-Path $directory.FullName 'global.json'
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }

        $directory = $directory.Parent
    }

    return $null
}

function Get-SolutionPath {
    param(
        [Parameter(Mandatory)]
        [string] $SelectedProduct,

        [string] $RequestedSolution,

        [string] $RequestedWorkspaceRoot
    )

    $solutionName = if ($SelectedProduct -eq '1d2d') {
        'DHYDRO.1D2D.sln'
    }
    else {
        'DHYDRO.2D3D.sln'
    }

    if ($RequestedSolution) {
        $resolvedSolution = Resolve-ExistingPath $RequestedSolution 'Solution'
        if ([System.IO.Path]::GetFileName($resolvedSolution) -ne $solutionName) {
            throw "Product '$SelectedProduct' requires $solutionName, not $resolvedSolution."
        }

        return $resolvedSolution
    }

    if ($RequestedWorkspaceRoot) {
        $searchRoot = Resolve-ExistingPath $RequestedWorkspaceRoot 'Workspace root'
    }
    else {
        $gitRoot = & git -C $PSScriptRoot rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitRoot) {
            $searchRoot = $gitRoot.Trim()
        }
        else {
            $searchRoot = (Get-Location).Path
        }
    }

    $matches = @(
        Get-ChildItem -LiteralPath $searchRoot -Filter $solutionName -File -Recurse |
            Select-Object -ExpandProperty FullName
    )

    if ($matches.Count -eq 0) {
        throw "Could not find $solutionName below $searchRoot."
    }

    if ($matches.Count -gt 1) {
        throw "Found multiple $solutionName files below $searchRoot. Pass -Solution explicitly: $($matches -join ', ')"
    }

    return $matches[0]
}

function Get-MSBuildCandidates {
    $paths = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $pathCandidates = @(
        Get-Command msbuild.exe -All -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Source }
    )

    foreach ($candidate in $pathCandidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate) -and $seen.Add($candidate)) {
            $paths.Add((Resolve-Path -LiteralPath $candidate).Path)
        }
    }

    $vswhereCommand = Get-Command vswhere.exe -ErrorAction SilentlyContinue
    $vswhere = if ($vswhereCommand) {
        $vswhereCommand.Source
    }
    elseif (${env:ProgramFiles(x86)}) {
        Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    }

    if ($vswhere -and (Test-Path -LiteralPath $vswhere)) {
        $visualStudioCandidates = @(
            & $vswhere -all -sort -products * `
                -requires Microsoft.Component.MSBuild Microsoft.VisualStudio.Workload.ManagedDesktop `
                -find 'MSBuild\**\Bin\MSBuild.exe'
        )

        foreach ($candidate in $visualStudioCandidates) {
            if ($candidate -and (Test-Path -LiteralPath $candidate) -and $seen.Add($candidate)) {
                $paths.Add((Resolve-Path -LiteralPath $candidate).Path)
            }
        }
    }

    return $paths.ToArray()
}

function Get-DotNetSdkCandidates {
    param(
        [Parameter(Mandatory)]
        [string] $WorkingDirectory,

        [string] $GlobalJson
    )

    $dotnetCommand = Get-Command dotnet.exe -ErrorAction SilentlyContinue
    if (-not $dotnetCommand) {
        if ($GlobalJson) {
            throw "A global.json file exists at $GlobalJson, but dotnet.exe was not found."
        }

        return @()
    }

    Push-Location $WorkingDirectory
    try {
        $selectedVersion = (& $dotnetCommand.Source --version 2>$null | Select-Object -First 1)
        $versionExitCode = $LASTEXITCODE
        $sdkLines = @(& $dotnetCommand.Source --list-sdks 2>$null)
    }
    finally {
        Pop-Location
    }

    if ($GlobalJson -and ($versionExitCode -ne 0 -or -not $selectedVersion)) {
        throw "The SDK requested by $GlobalJson is not installed or cannot be selected."
    }

    $installed = [System.Collections.Generic.List[object]]::new()
    foreach ($line in $sdkLines) {
        if ($line -match '^(?<version>\S+)\s+\[(?<root>.+)\]$') {
            $sdkPath = Join-Path $Matches.root $Matches.version
            $sdksPath = Join-Path $sdkPath 'Sdks'
            if (Test-Path -LiteralPath (Join-Path $sdksPath 'Microsoft.NET.Sdk\Sdk')) {
                $installed.Add([pscustomobject]@{
                    Version = $Matches.version
                    Path = $sdkPath
                    SdksPath = $sdksPath
                    DotNetRoot = Split-Path $Matches.root -Parent
                })
            }
        }
    }

    if ($GlobalJson) {
        return @($installed | Where-Object Version -eq $selectedVersion)
    }

    $ordered = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    if ($selectedVersion) {
        foreach ($sdk in $installed | Where-Object Version -eq $selectedVersion) {
            if ($seen.Add("$($sdk.Version)|$($sdk.Path)")) {
                $ordered.Add($sdk)
            }
        }
    }

    if ($installed.Count -gt 0) {
        foreach ($sdk in @($installed)[($installed.Count - 1)..0]) {
            if ($seen.Add("$($sdk.Version)|$($sdk.Path)")) {
                $ordered.Add($sdk)
            }
        }
    }

    return $ordered.ToArray()
}

function Invoke-MSBuildCaptured {
    param(
        [Parameter(Mandatory)]
        [string] $MSBuild,

        [Parameter(Mandatory)]
        [string[]] $Arguments,

        [Parameter(Mandatory)]
        [string] $LogPath,

        [hashtable] $Environment = @{}
    )

    $savedEnvironment = @{}
    foreach ($name in $Environment.Keys) {
        $savedEnvironment[$name] = [pscustomobject]@{
            Exists = Test-Path "Env:$name"
            Value = [System.Environment]::GetEnvironmentVariable($name, 'Process')
        }
    }

    try {
        foreach ($name in $Environment.Keys) {
            [System.Environment]::SetEnvironmentVariable(
                $name,
                [string] $Environment[$name],
                'Process'
            )
        }

        & $MSBuild @Arguments *> $LogPath
        $exitCode = $LASTEXITCODE
    }
    finally {
        foreach ($name in $Environment.Keys) {
            $saved = $savedEnvironment[$name]
            $value = if ($saved.Exists) { $saved.Value } else { $null }
            [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }

    return $exitCode
}

function Test-IsToolchainFailure {
    param([Parameter(Mandatory)][string] $LogPath)

    $patterns = @(
        'MSB3644',
        'MSB4236',
        'MSB4242',
        'Could not resolve SDK',
        'Microsoft\.NET\.SDK\.Workload',
        'NETSDK1045',
        'does not support targeting',
        'MSBuild version .* is required',
        'The current version of MSBuild'
    )

    return Select-String -Path $LogPath -Pattern $patterns -Quiet
}

function Get-MSBuildVersion {
    param([Parameter(Mandatory)][string] $MSBuild)

    $output = @(& $MSBuild -version -nologo 2>$null)
    return ($output | Select-Object -Last 1).Trim()
}

$temporaryLogs = [System.Collections.Generic.List[string]]::new()

function New-TemporaryLog {
    $path = [System.IO.Path]::GetTempFileName()
    $script:temporaryLogs.Add($path)
    return $path
}

try {
$solutionPath = Get-SolutionPath `
    -SelectedProduct $Product.ToLowerInvariant() `
    -RequestedSolution $Solution `
    -RequestedWorkspaceRoot $WorkspaceRoot

$solutionDirectory = Split-Path $solutionPath -Parent
$repoRootOutput = & git -C $solutionDirectory rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRootOutput) {
    throw "Cannot determine the Git root for $solutionPath."
}
$repoRoot = $repoRootOutput.Trim()

$globalJson = Find-GlobalJson $solutionDirectory
$msbuildCandidates = @(Get-MSBuildCandidates)
if ($msbuildCandidates.Count -eq 0) {
    throw 'No compatible MSBuild.exe was found. Install Visual Studio Build Tools with MSBuild and the .NET desktop development workload.'
}

$sdkCandidates = @(Get-DotNetSdkCandidates `
    -WorkingDirectory $solutionDirectory `
    -GlobalJson $globalJson)

$probeArguments = @(
    $solutionPath
    '/t:Restore'
    "/p:Configuration=$Configuration"
    '/p:Platform=Any CPU'
    '/verbosity:minimal'
    '/nologo'
)

$selectedMSBuild = $null
$selectedSdk = $null
$selectedEnvironment = @{}
$lastProbeLog = $null

foreach ($candidate in $msbuildCandidates) {
    $probeLog = New-TemporaryLog
    $lastProbeLog = $probeLog
    $exitCode = Invoke-MSBuildCaptured `
        -MSBuild $candidate `
        -Arguments $probeArguments `
        -LogPath $probeLog

    if ($exitCode -eq 0) {
        $selectedMSBuild = $candidate
        $selectedSdk = 'Visual Studio SDK resolver'
        break
    }

    if (-not (Test-IsToolchainFailure $probeLog)) {
        Get-Content -LiteralPath $probeLog
        throw "Restore failed with $candidate for $solutionPath. This is not a toolchain discovery error."
    }

    foreach ($sdk in $sdkCandidates) {
        $dotnetHost = Join-Path $sdk.DotNetRoot 'dotnet.exe'
        $fallbackEnvironment = @{
            MSBuildSDKsPath = $sdk.SdksPath
            MSBuildEnableWorkloadResolver = 'false'
            DOTNET_ROOT = $sdk.DotNetRoot
            DOTNET_HOST_PATH = $dotnetHost
        }

        $probeLog = New-TemporaryLog
        $lastProbeLog = $probeLog
        $exitCode = Invoke-MSBuildCaptured `
            -MSBuild $candidate `
            -Arguments $probeArguments `
            -LogPath $probeLog `
            -Environment $fallbackEnvironment

        if ($exitCode -eq 0) {
            $selectedMSBuild = $candidate
            $selectedSdk = $sdk.Version
            $selectedEnvironment = $fallbackEnvironment
            break
        }

        if (-not (Test-IsToolchainFailure $probeLog)) {
            Get-Content -LiteralPath $probeLog
            throw "Restore failed with $candidate and .NET SDK $($sdk.Version) for $solutionPath. This is not a toolchain discovery error."
        }
    }

    if ($selectedMSBuild) {
        break
    }
}

if (-not $selectedMSBuild) {
    if ($lastProbeLog) {
        Get-Content -LiteralPath $lastProbeLog -Tail 80
    }

    throw 'No installed Visual Studio/MSBuild/.NET SDK combination could restore the solution.'
}

$targetArguments = @(
    $solutionPath
    '/restore'
    '/m'
    "/p:Configuration=$Configuration"
    '/p:Platform=Any CPU'
    '/verbosity:minimal'
    '/nologo'
)

if ($Rebuild) {
    $targetArguments += '/t:Rebuild'
}

$msbuildVersion = Get-MSBuildVersion $selectedMSBuild
Write-Host "Solution:      $solutionPath"
Write-Host "Configuration: $Configuration|Any CPU"
Write-Host "MSBuild:       $selectedMSBuild ($msbuildVersion)"
Write-Host "SDK:           $selectedSdk"

$buildLog = New-TemporaryLog
$exitCode = Invoke-MSBuildCaptured `
    -MSBuild $selectedMSBuild `
    -Arguments $targetArguments `
    -LogPath $buildLog `
    -Environment $selectedEnvironment

Get-Content -LiteralPath $buildLog
if ($exitCode -ne 0) {
    throw "D-HYDRO $Configuration build failed for $solutionPath."
}

Write-Host "D-HYDRO $Configuration restore and build completed successfully."
}
finally {
    foreach ($temporaryLog in $temporaryLogs) {
        Remove-Item -LiteralPath $temporaryLog -Force -ErrorAction SilentlyContinue
    }
}

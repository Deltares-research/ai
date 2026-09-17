[CmdletBinding()]
param(
    [ValidateSet('1d2d', '2d3d', 'Both')]
    [string] $Product = 'Both',

    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release',

    [string[]] $Variant = @('all')
)

$repoRoot = (git -C (Get-Location) rev-parse --show-toplevel).Trim()
if (-not $repoRoot) {
    throw 'Run from within the D-HYDRO-GUI Git checkout.'
}

$targetsPath = Join-Path $repoRoot 'build\targets\'
if (-not (Test-Path -LiteralPath $targetsPath)) {
    throw "Build targets were not found: $targetsPath"
}

$variantsByProduct = @{
    '1d2d' = @('fm', 'rws', 'fmo')
    '2d3d' = @('fm', 'rws', 'fmo', 'fmwaq')
}

$products = if ($Product -eq 'Both') { @('1d2d', '2d3d') } else { @($Product) }
$Variant = $Variant | ForEach-Object {
    if ($_ -eq 'open') { 'fmo' } else { $_.ToLowerInvariant() }
}

foreach ($currentProduct in $products) {
    $projectDir = Join-Path $repoRoot $currentProduct
    $project = Join-Path $projectDir 'setup\DHYDRO.wixproj'

    if (-not (Test-Path -LiteralPath $project)) {
        throw "Installer project was not found: $project"
    }

    $solutionDir = "$projectDir\"
    $buildArgs = @(
        'build', $project,
        '-t:Rebuild',
        '-c', $Configuration,
        '-p:Platform=x64',
        "-p:SolutionDir=$solutionDir",
        "-p:TargetsPath=$targetsPath"
    )

    if ($Variant -contains 'all') {
        if ($Variant.Count -ne 1) {
            throw 'Use either "all" or explicit variants, not both.'
        }

        & dotnet @buildArgs '-p:BuildAllVariants=true'
        if ($LASTEXITCODE -ne 0) { throw "$currentProduct all-variant build failed." }
        continue
    }

    foreach ($currentVariant in $Variant) {
        if ($currentVariant -notin $variantsByProduct[$currentProduct]) {
            throw "Variant '$currentVariant' is unsupported for $currentProduct."
        }

        # %2c preserves the culture/value comma through dotnet/MSBuild parsing.
        & dotnet @buildArgs "-p:Cultures=$currentVariant%2cen-US"
        if ($LASTEXITCODE -ne 0) {
            throw "$currentProduct/$currentVariant build failed."
        }
    }
}
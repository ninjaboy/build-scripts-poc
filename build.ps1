Param(
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryDir,

    [ValidateNotNullOrEmpty()]
    [string]$SolutionName,

    [ValidateNotNullOrEmpty()]
    [string]$Target="Default",

    [ValidateNotNullOrEmpty()]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration="Release",

    [ValidateNotNullOrEmpty()]
    [ValidateSet("win-x64", "linux-x64")]
    [string]$Runtime="win-x64",

    [ValidateNotNullOrEmpty()]
    [string]$BuildVersion="0.0.0-unversioned"
)

$buildDir=$PSScriptRoot
$buildScript=[System.IO.Path]::Combine($buildDir, "build.fsx")
$buildHelpersModule=[System.IO.Path]::Combine($buildDir, "BuildHelpers", "BuildHelpers.psm1")

Import-Module $buildHelpersModule

Write-Host -ForegroundColor Green "*** Building $SolutionName ($Configuration) in $RepositoryDir"

Install-Fake
Invoke-Fake -BuildScript $buildScript -RepositoryDir $RepositoryDir -SolutionName $SolutionName -Target $Target -Configuration $Configuration -Runtime $Runtime -BuildVersion $BuildVersion

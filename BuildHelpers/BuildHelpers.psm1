$fakeVersion="4.64.13"
$nugetVersion="4.6.2"

$moduleDirectory=$PSScriptRoot

$buildDir=(Get-Item $moduleDirectory).Parent.FullName

$toolsDir=[System.IO.Path]::Combine($buildDir, "tools")
$nuget=[System.IO.Path]::Combine($toolsDir, "NuGet-$nugetVersion", "nuget.exe")
$nugetPackagesDir=[System.IO.Path]::Combine($buildDir, "packages")

$fake=[System.IO.Path]::Combine($nugetPackagesDir, "FAKE.$fakeVersion", "tools", "FAKE.exe")

Function Install-Fake
{
<#
    .SYNOPSIS
        Fetches the FAKE package using NuGet.

    .DESCRIPTION
        Fetches the FAKE package using NuGet.

    .EXAMPLE
        Install-Fake
#>
    Write-Host -ForegroundColor Green "***    Getting build tools"
    & "$nuget" install FAKE -OutputDirectory $nugetPackagesDir -Version $FakeVersion -Verbosity quiet
    if ($LASTEXITCODE -ne 0)
    {
        Exit $LASTEXITCODE
    }
}

Function Invoke-Fake
{
<#
    .SYNOPSIS
        Invokes FAKE build script.

    .DESCRIPTION
        Invokes FAKE build script.

    .EXAMPLE
        Invoke-Fake
#>
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$BuildScript,

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

    Write-Host -ForegroundColor Green "***    FAKE it"
    & "$fake" "$BuildScript" "$Target" RepositoryDir="$RepositoryDir" SolutionName="$SolutionName" Configuration="$Configuration" Runtime="$Runtime" BuildVersion="$BuildVersion"
    if ($LASTEXITCODE -ne 0)
    {
        Exit $LASTEXITCODE
    }
}

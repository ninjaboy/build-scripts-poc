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

$fakeVersion="4.64.13"
$nugetVersion="4.6.2"

$buildDir=$PSScriptRoot
$buildScript=[System.IO.Path]::Combine($buildDir, "build.fsx")

$toolsDir=[System.IO.Path]::Combine($buildDir, "tools")
$nuget=[System.IO.Path]::Combine($toolsDir, "NuGet-$nugetVersion", "nuget.exe")
$nugetPackagesDir=[System.IO.Path]::Combine($buildDir, "packages")

$fake=[System.IO.Path]::Combine($nugetPackagesDir, "FAKE.$fakeVersion", "tools", "FAKE.exe")

Write-Host -ForegroundColor Green "*** Building $SolutionName ($Configuration) in $RepositoryDir"

Write-Host -ForegroundColor Green "***    Getting build tools"
& "$nuget" install FAKE -OutputDirectory $nugetPackagesDir -Version $fakeVersion -Verbosity quiet
if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}

Write-Host -ForegroundColor Green "***    FAKE it"
& "$fake" "$buildScript" "$Target" RepositoryDir="$RepositoryDir" SolutionName="$SolutionName" Configuration="$Configuration" Runtime="$Runtime" BuildVersion="$BuildVersion"
if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}

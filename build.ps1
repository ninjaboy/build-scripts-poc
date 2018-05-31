Param(
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
$buildLog=[System.IO.Path]::Combine($buildDir, "reports", "build.log")

$buildScript=[System.IO.Path]::Combine($buildDir, "build.fsx")

$repositoryDir=(Get-Item $buildDir).Parent.FullName
$toolsDir=[System.IO.Path]::Combine($repositoryDir, "tools")
$nuget=[System.IO.Path]::Combine($toolsDir, "NuGet-$nugetVersion", "nuget.exe")
$nugetPackagesDir=[System.IO.Path]::Combine($repositoryDir, "packages")

$fake=[System.IO.Path]::Combine($nugetPackagesDir, "FAKE.$fakeVersion", "tools", "FAKE.exe")

Write-Host -ForegroundColor Green "*** Building $Configuration in $repositoryDir"

Write-Host -ForegroundColor Green "***    Getting build tools"
& "$nuget" install FAKE -OutputDirectory $nugetPackagesDir -Version $fakeVersion -Verbosity quiet
if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}

Write-Host -ForegroundColor Green "***    FAKE it"
& "$fake" "$buildScript" "$Target" --logfile "$buildLog" Configuration="$Configuration" Runtime="$Runtime" BuildVersion="$BuildVersion"
if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}

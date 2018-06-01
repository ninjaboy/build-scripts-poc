Param(
    [ValidateNotNullOrEmpty()]
    [string]$FakeVersion="4.64.13",

    [ValidateNotNullOrEmpty()]
    [string]$NugetVersion="4.6.2"
)

$buildDir=$PSScriptRoot
$toolsDir=[System.IO.Path]::Combine($buildDir, "tools")
$nuget=[System.IO.Path]::Combine($toolsDir, "NuGet-$nugetVersion", "nuget.exe")
$nugetPackagesDir=[System.IO.Path]::Combine($buildDir, "packages")

Write-Host -ForegroundColor Green "***    Getting build tools"
& "$nuget" install FAKE -OutputDirectory $nugetPackagesDir -Version $fakeVersion -Verbosity quiet
if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}

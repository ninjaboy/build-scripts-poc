Param(
    [ValidateNotNullOrEmpty()]
    [string]$Target="Default",

    [ValidateNotNullOrEmpty()]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration="Release",

    [ValidateNotNullOrEmpty()]
    [string]$BuildVersion="0.0.0-unversioned",

    [ValidateNotNullOrEmpty()]
    [ValidateSet("any", "win-x64", "win", "linux-x64")]
    [string]$Runtime="linux-x64", 

    [ValidateNotNullOrEmpty()]
    [ValidateSet("AppDomain", "Docker")]
    [string]$SutStartMode="AppDomain"

)

$scriptDir=$PSScriptRoot

Write-Host -ForegroundColor Green "Script dir: " + $scriptDir

$buildDir=(Get-Item $scriptDir).Parent.Parent.Parent.FullName

Write-Host -ForegroundColor Green "Build dir: " + $buildDir

$buildLog=[System.IO.Path]::Combine($buildDir, "reports", "build.log")

$repositoryDir=(Get-Item $scriptDir).Parent.Parent.Parent.Parent.FullName

Write-Host -ForegroundColor Green "Repository dir: " + $buildDir

$solutionName="Paket.Build.Demo"

$paketDir=[System.IO.Path]::Combine($buildDir, ".paket")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")

$packagesDir =[System.IO.Path]::Combine($buildDir, "packages")
$fake=[System.IO.Path]::Combine($packagesDir, "FAKE", "tools", "FAKE.exe")

# Default script is used for now
$buildScript=[System.IO.Path]::Combine($scriptDir, "build-runner.fsx" )

try {
    Push-Location -Path $buildDir

    Write-Host -ForegroundColor Green "*** Building $Configuration in $repositoryDir for solution $solutionName***"

    Write-Host -ForegroundColor Green "*** Getting build tools ***"
    & "$paket" update

    if ($LASTEXITCODE -ne 0)
    {
        trace "Could not resolve some of the Paket dependencies"
        Exit $LASTEXITCODE
    }


    Write-Host -ForegroundColor Green "*** FAKE it ***"
    & "$fake" "$buildScript" "$Target" `
                RepositoryDir="$repositoryDir" `
                SolutionName="$solutionName" `
                Configuration="$Configuration" `
                BuildVersion="$BuildVersion" `
                Runtime="$Runtime" `
                SutStartMode="$SutStartMode" `
                --logfile "$buildLog"
    
    if ($LASTEXITCODE -ne 0)
    {
        Exit $LASTEXITCODE
    }    
}
finally {
    Pop-Location
}

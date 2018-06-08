#r @"./packages/FAKE/tools/FakeLib.dll"


open Fake
open Fake.Testing
open Fake.DotNetCli
open Fake.NuGetHelper
open Fake.XMLHelper

open System
open System.Diagnostics
open System.IO


module Properties =
    let buildRepositoryDir = getBuildParam "RepositoryDir"
    let buildSolutionName = getBuildParam "SolutionName"
    let buildConfiguration = getBuildParamOrDefault "Configuration" "Release"
    let buildRuntime = getBuildParamOrDefault "Runtime" "win-x64"
    let buildVersion = getBuildParamOrDefault "BuildVersion" "0.0.0-unversioned"

    module Internal =
        // Timestamp used for unique filenames etc.
        let buildTimestamp = DateTime.Now.ToString("yyyyMMdd-HHmmss")

        // Absolute path to solution directories
        let repositoryDir = buildRepositoryDir
        let sourceDir = Path.Combine(repositoryDir, "src")
        let buildDir = Path.Combine(repositoryDir, "build")
        let buildReportsDir = Path.Combine(buildDir, "reports")
        let packagesDir = Path.Combine(repositoryDir, "packages")

        // Absolute path to the main SLN file
        let solutionFile = Path.Combine(sourceDir, (sprintf "%s.sln" buildSolutionName))
        let fullProjectPath p = Path.Combine(sourceDir, p, (sprintf "%s.csproj" p))

        // Tests
        let testsProjectPathPatternByType = fun t -> sprintf @"%s\**\*.Test.%s.csproj" sourceDir t
        let runTestsInProject = fun x -> DotNetCli.Test (fun p ->
            {   p with
                    Project = x
                    Configuration = buildConfiguration
                    AdditionalArgs = [ "--no-build"; "--logger"; "trx"; ]
            })

        // NUGET packages related configs
        let artifactsDir = Path.Combine(repositoryDir, "pvr-packages") //.nupkg will be expected to be found in "Willow\src\pvr-packages\" by TeamCity custom nuget feed publisher

module Functions =
    let runProcess exe args =
        let p = new Process()
        p.StartInfo.FileName <- exe
        p.StartInfo.Arguments <- args
        p.StartInfo.RedirectStandardOutput <- true
        p.StartInfo.RedirectStandardError <- true
        p.StartInfo.UseShellExecute <- false
        p.Start() |> ignore

        printfn "Result of command:%s" (p.StandardOutput.ReadToEnd())
        p.WaitForExit()

        if p.ExitCode <> 0 then
            printfn "Errors output stream of command:%s" (p.StandardError.ReadToEnd())
            failwithf "Process failed with exit code: %d" p.ExitCode

    let runViaCmd script =
        runProcess "cmd.exe" script

    let RunProcess exe args description =
        printfn "Running (%s) executable: %s with args: %s" description exe args
        runProcess exe args
    let RunCmd script description =
        let scriptWrapper = sprintf "/c %s" script
        printfn "Running cmd.exe script (%s): %s" description scriptWrapper
        runViaCmd scriptWrapper
    let RunPowerShell script description =
        let powershellWrapper = sprintf """/c powershell -ExecutionPolicy Unrestricted -Command "%s" """ script
        printfn "Running powershell script (%s): %s" description powershellWrapper
        runViaCmd powershellWrapper

module Targets =
    open Properties
    open Properties.Internal
    open Functions

    Target "Purge" (fun _ ->
        let script = sprintf "$startPath = '%s'; Get-ChildItem -Path $startPath -Filter 'bin' -Directory -Recurse | Foreach { $_.Delete($true) }; Get-ChildItem -Path $startPath -Filter 'obj' -Directory -Recurse | Foreach { $_.Delete($true) }" repositoryDir
        RunPowerShell script "Purge build artefacts (bin/ and obj/)"
    )

    Target "Clean" (fun _ ->
        DotNetCli.RunCommand (fun p ->
             { p with
                 TimeOut = TimeSpan.FromMinutes 10.
             }) (sprintf "clean \"%s\"" solutionFile)
    )

    Target "Restore" (fun _ ->
        DotNetCli.Restore (fun p ->
            { p with
                Project = solutionFile
            })
    )

    Target "Build" (fun _ ->
        DotNetCli.Build (fun p ->
            { p with
                Project = solutionFile
                Configuration = buildConfiguration
            })
    )

    Target "UnitTests" (fun _ ->
        !! (testsProjectPathPatternByType "Unit")
        |> Seq.iter runTestsInProject
    )

    Target "AcceptanceTests" (fun _ ->
        !! (testsProjectPathPatternByType "Acceptance")
        |> Seq.iter runTestsInProject
    )

    Target "IntegrationTests" (fun _ ->
        !! (testsProjectPathPatternByType "Integration")
        |> Seq.iter runTestsInProject
    )

    Target "Pack" (fun _ ->
        let version = sprintf "/p:Version=%s" buildVersion
        DotNetCli.Pack (fun p ->
        {
            p with
                Project = solutionFile
                OutputPath = artifactsDir
                AdditionalArgs = [ "--no-build"; version; ]
        })
    )

    // Labels to manage dependencies
    Target "FullBuild" DoNothing
    Target "ValidationBuild" DoNothing
    Target "Default" DoNothing

// Dependencies
open Targets

"Build" ==> "UnitTests"
"Build" ==> "AcceptanceTests"
"Build" ==> "IntegrationTests"
"Build" ==> "Pack"

"UnitTests" ?=> "Pack"
"AcceptanceTests" ?=> "Pack"
"IntegrationTests" ?=> "Pack"

// Validation build dependencies
"UnitTests" ==> "ValidationBuild"
"AcceptanceTests" ==> "ValidationBuild"
"IntegrationTests" ==> "ValidationBuild"
"Pack" ==> "ValidationBuild"

// Full build dependencies
"ValidationBuild" ==> "FullBuild"

// Default target
"FullBuild" ==> "Default"

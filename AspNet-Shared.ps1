# Shared functions used by various scripts

# Creates a directory if it doesn't exist, returns the fully qualified path
function New-InstallDirectory(
    [string] $Directory,
    [string] $Default,
    [switch] $Clean = $false,
    [switch] $Create = $false)
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference="Stop"
    $ProgressPreference="SilentlyContinue"

    if (-not $Directory)
    {
        throw "Directory is required. Use <auto> to generate a default."
    }

    if (-not $Default)
    {
        throw "Default is required."
    }

    if ($Directory -eq "<auto>")
    {
        $Directory = Join-Path "$(Split-Path $script:MyInvocation.MyCommand.Path -Parent)" $Default
    }

    if ($Clean -and (Test-Path $Directory))
    {
        Remove-Item $Directory -Recurse -Force | Out-Null
    }

    if ($Create -and (-not (Test-Path $Directory)))
    {
        New-Item -ItemType Directory -Force -Path $Directory | Out-Null
    }

    $Directory = [System.IO.Path]::Combine($pwd, $Directory)
    return $Directory
}

# Finds the latests installed shared framework
function Get-FrameworkVersion()
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference="Stop"
    $ProgressPreference="SilentlyContinue"

    Write-Host -ForegroundColor Green "Autodetecting .NET version"

    $dotnet = [System.IO.Path]::GetDirectoryName((Get-Command dotnet).Path)
    $shared_framework_root = [System.IO.Path]::Combine($dotnet, "shared\Microsoft.NETCore.App")

    $versions = @(Get-ChildItem $shared_framework_root | Sort-Object Name)

    foreach ($version in $versions)
    {
        Write-Host -ForegroundColor Green "Found version: $version"
    }
    
    Write-Host -ForegroundColor Green "Choosing version: $($versions[-1])"
    return $version[-1]
}

function Get-LatestAspNetVersion(
    [string] $Feed = "https://dotnet.myget.org/F/aspnetcore-ci-dev/api/v3/index.json",
    [string] $Package = "Microsoft.AspNetCore.All")
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference="Stop"
    $ProgressPreference="SilentlyContinue"

    Write-Host -ForegroundColor Green "Autodetecting ASP.NET version"

    $index = Invoke-WebRequest -Uri $Feed | ConvertFrom-Json
    $root = $index| ForEach-Object { $_.Resources } | Where-Object { $_.'@type' -eq "PackageBaseAddress/3.0.0" } | ForEach-Object { $_.'@id' }

    $versions = @(Invoke-WebRequest -Uri ($root + $Package.ToLowerInvariant() + "/index.json") | ConvertFrom-Json | ForEach-Object { $_.versions } | Sort-Object)
    if ($versions.Count -eq 0)
    {
        throw "No versions of $Package found."
    }

    Write-Host -ForegroundColor Green "Choosing version: $($versions[-1])"
    
    return $versions[-1]
}

# Downloads NuGet.exe
function Get-NuGet(
    [string] $InstallDir,
    [string] $Url = "https://dist.nuget.org/win-x86-commandline/v4.1.0/NuGet.exe")
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference="Stop"
    $ProgressPreference="SilentlyContinue"

    if (-not $InstallDir)
    {
        throw "InstallDir is required."
    }

    if (-not (Test-Path $InstallDir))
    {
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    }

    $nuget = Join-Path $InstallDir "NuGet.exe"

    if (-not (Test-Path $nuget))
    {
        Write-Host -ForegroundColor Green "Getting NuGet from $Url"

        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $nuget)
    }
    
    return $nuget
}


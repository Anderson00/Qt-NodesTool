$Version = "3.11.9"
$Url = "https://www.nuget.org/api/v2/package/python/$Version"
$ZipFile = "python.zip"
$OutDir = "python_env"

if (-not (Test-Path $OutDir)) {
    Write-Host "Downloading Python $Version NuGet package..."
    Invoke-WebRequest -Uri $Url -OutFile $ZipFile
    Write-Host "Extracting..."
    Expand-Archive -Path $ZipFile -DestinationPath "python_nuget" -Force
    
    Write-Host "Setting up python_env..."
    Rename-Item -Path "python_nuget\tools" -NewName $OutDir
    
    Remove-Item -Path "python_nuget" -Recurse -Force
    Remove-Item -Path $ZipFile -Force

    Write-Host "Installing dependencies (numpy, scipy)..."
    & ".\$OutDir\python.exe" -m pip install numpy scipy
    
    Write-Host "Python environment setup complete in .\$OutDir"
} else {
    Write-Host "python_env already exists."
}

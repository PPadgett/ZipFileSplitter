<#
.SYNOPSIS
    Prepares the test environment by loading the script under test and performing AST analysis.

.DESCRIPTION
    This BeforeAll block is essential for setting up the testing environment. It:
      - Derives the base name from the test script.
      - Constructs potential file paths for a .ps1 or .psm1 script.
      - Detects if the tests are running in an Azure DevOps (ADO) or GitHub Actions pipeline.
      - Determines the testing environment (Sandbox, Dev, NonProd, or default).
      - Loads the target script:
            • Imports it as a module if it's a .psm1 file.
            • Dot-sources it if it's a .ps1 file.
      - Reads the script content and performs AST analysis to locate function definitions.
    This setup enables thorough troubleshooting and ensures consistency between local and pipeline environments.

.NOTES
    - Verbose messages help track the setup progress and identify potential issues.
    - Ensure that the module file does not include blocking or interactive code at the top level.
#>

BeforeAll {
    # Set verbose output preference for detailed logging.
    $VerbosePreference = 'Continue'
    Write-Verbose "Initializing test environment setup." -Verbose

    # Extract the base name from the current test script (removes '.Tests' suffix).
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath).Replace('.Tests','')
    Write-Verbose "Base name for testing: $baseName" -Verbose

    # Determine the directory containing the script under test.
    $directoryPath = Split-Path -Path (Split-Path -Path $PSCommandPath -Parent) -Parent
    Write-Verbose "Script directory determined as: $directoryPath" -Verbose

    # Build potential file paths for the .ps1 and .psm1 versions of the script.
    $ps1FilePath = Join-Path -Path $directoryPath -ChildPath "$baseName.ps1"
    $psm1FilePath = Join-Path -Path $directoryPath -ChildPath "$baseName.psm1"
    Write-Verbose "Looking for files: '$ps1FilePath' or '$psm1FilePath'" -Verbose

    # Check for pipeline environments.
    $runningInAdoPipeline = (($null -ne $env:SYSTEM_DEFINITIONID -or $null -ne $env:BUILD_BUILDID) -and ($null -ne $env:AGENT_NAME))
    $runningInGithubPipeline = $env:GITHUB_ACTIONS -eq 'true'
    Write-Verbose "Running in ADO Pipeline: $runningInAdoPipeline" -Verbose
    Write-Verbose "Running in GitHub Actions Pipeline: $runningInGithubPipeline" -Verbose

    # Identify the testing environment (Sandbox, Dev, NonProd, or default).
    $testEnvironment = $env:TEST_ENVIRONMENT
    Write-Verbose "Testing environment: $testEnvironment" -Verbose

    # Configure environment-specific settings.
    try {
        switch ($testEnvironment) {
            "Sandbox" {
                Write-Verbose "Configuring tests for the Sandbox environment." -Verbose
                if ($runningInAdoPipeline -or $runningInGithubPipeline) { 
                    Write-Verbose "Using pipeline variables for Sandbox." 
                } else { 
                    Write-Verbose "Using local variables for Sandbox." 
                }
            }
            "Dev" {
                Write-Verbose "Configuring tests for the Development environment." -Verbose
                if ($runningInAdoPipeline -or $runningInGithubPipeline) { 
                    Write-Verbose "Using pipeline variables for Development." 
                } else { 
                    Write-Verbose "Using local variables for Development." 
                }
            }
            "NonProd" {
                Write-Verbose "Configuring tests for the Non-Production environment." -Verbose
                if ($runningInAdoPipeline -or $runningInGithubPipeline) { 
                    Write-Verbose "Using pipeline variables for Non-Production." 
                } else { 
                    Write-Verbose "Using local variables for Non-Production." 
                }
            }
            default {
                Write-Verbose "No specific environment set. Using default configuration." -Verbose
                if ($runningInAdoPipeline -or $runningInGithubPipeline) { 
                    Write-Verbose "Using pipeline variables in default configuration." 
                } else { 
                    Write-Verbose "Using local variables in default configuration." 
                }
            }
        }
    }
    catch {
        Write-Error "Error during environment configuration: $_. Review the environment settings and try again." -ErrorAction Stop -ErrorId 'EnvironmentSetupError'
    }

    try {
        # Identify which file exists: prefer .ps1 over .psm1.
        if (Test-Path -Path $ps1FilePath) {
            $filePath = $ps1FilePath
            Write-Verbose ".ps1 file detected at: $filePath" -Verbose
        }
        elseif (Test-Path -Path $psm1FilePath) {
            $filePath = $psm1FilePath
            Write-Verbose ".psm1 file detected at: $filePath" -Verbose
        }
        else {
            throw "Neither file found: '$ps1FilePath' nor '$psm1FilePath'. Verify file paths."
        }

        # Load the script: import as a module if .psm1; dot-source if .ps1.
        try {
            if ($filePath -match '\.psm1$') {
                Write-Verbose "Importing module from: $filePath" -Verbose
                Import-Module $filePath -Force -Verbose
            }
            else {
                Write-Verbose "Dot-sourcing script from: $filePath" -Verbose
                . $filePath
            }
        }
        catch {
            throw "Error loading file '$filePath': $_. Check the file for issues."
        }

        # Read the script content for AST analysis.
        Write-Verbose "Reading content of '$filePath' for AST analysis." -Verbose
        try {
            $scriptContent = Get-Content -Path $filePath -Raw
            $scriptBlockAst = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)
        }
        catch {
            throw "Error reading file content for AST analysis: $_. Ensure the file is accessible and valid."
        }

        # Perform AST analysis to extract function definitions.
        Write-Verbose "Performing AST analysis to extract function definitions." -Verbose
        try {
            $functionDefinitions = $scriptBlockAst.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        }
        catch {
            throw "AST analysis error: $_. Unable to extract function definitions."
        }

        # Report identified functions, if any.
        Write-Verbose "AST analysis results:" -Verbose
        if ($functionDefinitions.Count -gt 0) {
            foreach ($function in $functionDefinitions) {
                Write-Verbose "Function detected: $($function.Name)" -Verbose
            }
        }
        else {
            Write-Verbose "No functions found in the script via AST analysis." -Verbose
        }
    }
    catch {
        Write-Error "Error during script processing: $_. Verify the target script and its configuration." -ErrorAction Stop -ErrorId 'ScriptProcessingError'
    }
}


# ZipFileSplitter.Tests.ps1
# Pester tests for the ZipFileSplitter module.

Describe 'ZipFileSplitter Module' {

    BeforeAll {
        # Create a temporary folder for testing and a test file to simulate a ZIP file
        $script:tempRoot = Join-Path -Path $env:TEMP -ChildPath ("ZipFileSplitterTests_{0}" -f ([System.Guid]::NewGuid()))
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        $script:testFilePath = Join-Path -Path $script:tempRoot -ChildPath 'TestFile.zip'
        # Create file content that is large enough to be split into multiple parts
        $fileContent = [System.Text.Encoding]::UTF8.GetBytes(("ABCDEFGHIJKLMNOPQRSTUVWXYZ" * 100))
        [System.IO.File]::WriteAllBytes($script:testFilePath, $fileContent)

        # Import the module under test from the parent folder
        Import-Module "$PSScriptRoot\..\ZipFileSplitter.psm1" -Force
    }

    AfterAll {
        # Clean up the temporary folder after all tests
        Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'Split-ZipFile Function' {
        It 'Creates the output folder if it does not exist' {
            $nonExistentOutput = Join-Path -Path $script:tempRoot -ChildPath 'NonExistentFolder'
            if (Test-Path $nonExistentOutput) { Remove-Item -Path $nonExistentOutput -Recurse -Force }
            { Split-ZipFile -InputZip $script:testFilePath -OutputFolder $nonExistentOutput -ChunkSize 500 } | Should -Not -Throw
            (Test-Path $nonExistentOutput) | Should -BeTrue
        }

        It 'Splits the file into the correct number of parts' {
            $outputFolder = Join-Path -Path $script:tempRoot -ChildPath 'SplitParts'
            New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
            $chunkSize = 500
            Split-ZipFile -InputZip $script:testFilePath -OutputFolder $outputFolder -ChunkSize $chunkSize | Out-Null
            $parts = Get-ChildItem -Path $outputFolder -Filter "*.zippart"
            $fileSize = (Get-Item $script:testFilePath).Length
            $expectedParts = [Math]::Ceiling($fileSize / $chunkSize)
            $parts.Count | Should -BeExactly $expectedParts
        }

        It 'Writes a smaller last part if file size is not a multiple of chunk size' {
            $outputFolder = Join-Path -Path $script:tempRoot -ChildPath 'SplitParts_LastChunk'
            New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
            $chunkSize = 500
            Split-ZipFile -InputZip $script:testFilePath -OutputFolder $outputFolder -ChunkSize $chunkSize | Out-Null
            $parts = Get-ChildItem -Path $outputFolder -Filter "*.zippart" | Sort-Object Name
            $lastPart = $parts[-1]
            $lastPartSize = $lastPart.Length
            $fileSize = (Get-Item $script:testFilePath).Length
            $expectedRemainder = $fileSize % $chunkSize
            if ($expectedRemainder -eq 0) { $expectedRemainder = $chunkSize }
            $lastPartSize | Should -BeExactly $expectedRemainder
        }
    }

    Context 'Merge-ZipPart Function' {
        BeforeEach {
            $script:currentPartsFolder = Join-Path -Path $script:tempRoot -ChildPath ("MergeParts_{0}" -f ([System.Guid]::NewGuid()))
            New-Item -ItemType Directory -Path $script:currentPartsFolder -Force | Out-Null
            Split-ZipFile -InputZip $script:testFilePath -OutputFolder $script:currentPartsFolder -ChunkSize 500 | Out-Null
        }

        It 'Merges parts correctly to re-create the original file' {
            $mergedFile = Join-Path -Path $script:tempRoot -ChildPath 'Merged.zip'
            Merge-ZipPart -PartsFolder $script:currentPartsFolder -OutputZip $mergedFile | Out-Null
            $originalBytes = [System.IO.File]::ReadAllBytes($script:testFilePath)
            $mergedBytes = [System.IO.File]::ReadAllBytes($mergedFile)
            $mergedBytes.Length | Should -Be $originalBytes.Length
            for ($i = 0; $i -lt $originalBytes.Length; $i++) {
                $mergedBytes[$i] | Should -Be $originalBytes[$i]
            }
        }

        It 'Returns an error when no .zippart files are found' {
            $emptyFolder = Join-Path -Path $script:tempRoot -ChildPath ("EmptyParts_{0}" -f ([System.Guid]::NewGuid()))
            New-Item -ItemType Directory -Path $emptyFolder -Force | Out-Null
            { Merge-ZipPart -PartsFolder $emptyFolder -ErrorAction Stop } | Should -Throw
        }

        It 'Merges parts in sorted order' {
            $partsFolder = Join-Path -Path $script:tempRoot -ChildPath ("UnorderedParts_{0}" -f ([System.Guid]::NewGuid()))
            New-Item -ItemType Directory -Path $partsFolder -Force | Out-Null

            # Manually split the file into parts
            $fileContent = [System.IO.File]::ReadAllBytes($script:testFilePath)
            $chunkSize = 500
            $partNumber = 1
            while ($fileContent.Length -gt 0) {
                $length = [Math]::Min($chunkSize, $fileContent.Length)
                $chunk = $fileContent[0..($length - 1)]
                $partPath = Join-Path -Path $partsFolder -ChildPath ("Part_{0:D3}.zippart" -f $partNumber)
                [System.IO.File]::WriteAllBytes($partPath, $chunk)
                $fileContent = $fileContent[$length..($fileContent.Length - 1)]
                $partNumber++
            }

            # Shuffle the parts to simulate unordered file retrieval
            $shuffledParts = Get-ChildItem -Path $partsFolder -Filter "*.zippart" | Get-Random -Count (Get-ChildItem -Path $partsFolder -Filter "*.zippart").Count
            foreach ($file in $shuffledParts) {
                Rename-Item -Path $file.FullName -NewName ("zz_{0}" -f $file.Name)
            }
            Get-ChildItem -Path $partsFolder -Filter "zz_*.zippart" | ForEach-Object {
                Rename-Item -Path $_.FullName -NewName ($_.Name.Substring(3))
            }

            $mergedFile = Join-Path -Path $script:tempRoot -ChildPath 'Merged_Unordered.zip'
            Merge-ZipPart -PartsFolder $partsFolder -OutputZip $mergedFile | Out-Null
            $originalBytes = [System.IO.File]::ReadAllBytes($script:testFilePath)
            $mergedBytes = [System.IO.File]::ReadAllBytes($mergedFile)
            $mergedBytes.Length | Should -Be $originalBytes.Length
            for ($i = 0; $i -lt $originalBytes.Length; $i++) {
                $mergedBytes[$i] | Should -Be $originalBytes[$i]
            }
        }
    }
}


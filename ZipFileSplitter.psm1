# ZipFileSplitter.psm1
# This module provides functions to split a large ZIP file into smaller parts
# and to merge those parts back into a single ZIP file.

#region Function: Split-ZipFile
<#
.SYNOPSIS
    Splits a ZIP file into multiple parts.
.DESCRIPTION
    This function reads an input ZIP file and writes it out as multiple parts,
    each with a maximum size defined by the ChunkSize parameter. The default chunk size is 15MB.
.PARAMETER InputZip
    The full path to the input ZIP file.
.PARAMETER OutputFolder
    The folder where the split parts will be saved. Defaults to the current directory.
.PARAMETER ChunkSize
    The maximum size in bytes for each part. The default is 15MB (15 * 1024 * 1024 bytes).
.EXAMPLE
    Split-ZipFile -InputZip "C:\Files\LargeArchive.zip" -OutputFolder "C:\Files\Parts" -ChunkSize 15728640
#>
function Split-ZipFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputZip,

        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".",

        # Specify the chunk size in bytes (default 15MB)
        [Parameter(Mandatory = $false)]
        [int64]$ChunkSize = 15MB
    )

    # Resolve the full path of the input file and ensure the output directory exists
    $resolvedInput = Resolve-Path -Path $InputZip
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }
    
    # Resolve output folder to an absolute path for consistent usage
    $resolvedOutputFolder = (Resolve-Path -Path $OutputFolder).Path

    Write-Output "Splitting file: $($resolvedInput.Path)"
    Write-Output "Chunk size: $ChunkSize bytes"
    Write-Output "Output folder: $resolvedOutputFolder"

    # Open the input file for reading
    $fileStream = [System.IO.File]::OpenRead($resolvedInput)
    $buffer = New-Object byte[] $ChunkSize
    $partNumber = 1

    # Read the file in chunks until the end is reached
    while (($bytesRead = $fileStream.Read($buffer, 0, $ChunkSize)) -gt 0) {
        # Create the output file name for the current part using the resolved absolute path
        $outputFile = Join-Path -Path $resolvedOutputFolder -ChildPath ("Part_{0:D3}.zippart" -f $partNumber)
        Write-Output "Writing part ${partNumber}: $outputFile"
        $fs = [System.IO.File]::OpenWrite($outputFile)
        # Write only the number of bytes read (handles the last chunk)
        $fs.Write($buffer, 0, $bytesRead)
        $fs.Close()
        $partNumber++
    }
    $fileStream.Close()
    Write-Output "Splitting complete. Total parts: $(($partNumber - 1))"
}

#endregion Function: Split-ZipFile

#region Function: Merge-ZipPart
<#
.SYNOPSIS
    Merges split ZIP file parts into a single ZIP file.
.DESCRIPTION
    This function takes all files with the extension .zippart from a specified folder,
    sorts them by name, and concatenates them back into a single ZIP file.
.PARAMETER PartsFolder
    The folder containing the .zippart files.
.PARAMETER OutputZip
    The path and filename for the output ZIP file. Defaults to "merged.zip" in the current directory.
.EXAMPLE
    Merge-ZipPart -PartsFolder "C:\Files\Parts" -OutputZip "C:\Files\MergedArchive.zip"
#>
function Merge-ZipPart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PartsFolder,
        [Parameter(Mandatory = $true)]
        [string]$OutputZip
    )

    # Retrieve and naturally sort the .zippart files based on the numeric portion in the filename.
    $parts = Get-ChildItem -Path $PartsFolder -Filter '*.zippart' |
        Sort-Object {
            if ($_ -match 'Part_(\d+)\.zippart') { [int]$matches[1] } else { 0 }
        }

    if ($parts.Count -eq 0) {
        throw "No .zippart files found in $PartsFolder"
    }

    # Remove the output file if it already exists.
    if (Test-Path $OutputZip) { Remove-Item $OutputZip -Force }

    Write-Verbose "Merging $($parts.Count) parts into $OutputZip"

    # Open a FileStream for the output file (create new or overwrite).
    $fs = [System.IO.File]::Open($OutputZip, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)

    try {
        # Process each part in order using the pipeline.
        $parts | ForEach-Object {
            Write-Verbose "Appending part: $($_.Name)"
            $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
            $fs.Write($bytes, 0, $bytes.Length)
        }
    }
    finally {
        # Ensure the file stream is closed even if an error occurs.
        $fs.Close()
    }
}


#endregion Function: Merge-ZipPart

# Export the functions for module users.
Export-ModuleMember -Function Split-ZipFile, Merge-ZipPart

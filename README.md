# ZipFileSplitter PowerShell Module

## Overview

**ZipFileSplitter** is a PowerShell module that provides functions to split large ZIP files into smaller parts and to merge these parts back into a single ZIP file. This is especially useful when you need to send large files over email or other services that enforce file size limits.

## Features

- **Split-ZipFile**: Splits a specified ZIP file into multiple parts of a defined chunk size (default is 15MB).
- **Merge-ZipParts**: Merges multiple `.zippart` files back into a single ZIP file.

## Installation

1. **Clone or Download the Repository:**

   ```powershell
   git clone https://github.com/YourUsername/ZipFileSplitter.git
   ```

2. **Copy the Module File:**

   Place the `ZipFileSplitter.psm1` file in one of your PowerShell module directories or keep it in a folder of your choice.

3. **Import the Module in PowerShell:**

   ```powershell
   Import-Module -Name "C:\Path\To\ZipFileSplitter.psm1"
   ```

   Replace `C:\Path\To\ZipFileSplitter.psm1` with the actual path where you saved the file.

## Usage

### Splitting a ZIP File

To split a large ZIP file into smaller parts (15MB by default):

```powershell
Split-ZipFile -InputZip "C:\Path\To\LargeArchive.zip" -OutputFolder "C:\Path\To\OutputFolder" -ChunkSize 15728640
```

### Merging ZIP Parts

To merge the split parts back into a single ZIP file:

```powershell
Merge-ZipParts -PartsFolder "C:\Path\To\OutputFolder" -OutputZip "C:\Path\To\MergedArchive.zip"
```

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests. If you find any issues, feel free to [open an issue](https://github.com/YourUsername/ZipFileSplitter/issues).

## Contact

For any questions or feedback, please open an issue in this repository or contact [Your Name] at [your.email@example.com].


```powershell
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
```

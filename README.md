![Build Status](https://github.com/PPadgett/ZipFileSplitter/actions/workflows/Pipeline.yml/badge.svg?branch=main)
![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=PPadgett_ZipFileSplitter&metric=alert_status)
![Codecov](https://img.shields.io/codecov/c/github/PPadgett/ZipFileSplitter.svg)
![GitHub issues](https://img.shields.io/github/issues/PPadgett/ZipFileSplitter.svg)
![Gitleaks Badge](https://img.shields.io/badge/Protected%20by-Gitleaks-blue?style=flat)
![PowerShell](https://img.shields.io/badge/PowerShell-Module-blue)

# ZipFileSplitter PowerShell Module

## Overview

**ZipFileSplitter** is a PowerShell module that provides functions to split large ZIP files into smaller parts and to merge these parts back into a single ZIP file. This is especially useful when you need to send large files over email or other services that enforce file size limits.

## Features

- **Split-ZipFile**: Splits a specified ZIP file into multiple parts of a defined chunk size (default is 15MB).
- **Merge-ZipPart**: Merges multiple `.zippart` files back into a single ZIP file.

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
Merge-ZipPart -PartsFolder "C:\Path\To\OutputFolder" -OutputZip "C:\Path\To\MergedArchive.zip"
```

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests. If you find any issues, feel free to [open an issue](https://github.com/YourUsername/ZipFileSplitter/issues).

<#
.SYNOPSIS
    Change VM disks to StandardHDD, StandardSSD, or PremiumSSD.
.DESCRIPTION
    Change VM disks to StandardHDD, StandardSSD, or PremiumSSD. 
    The VM is stopped during execution to allow us to change the disks. 
    You can optionally start the VM once disk adjustments are complete.
.PARAMETER SubscriptionId
    The Subscription ID, where the RG lives
.PARAMETER ResourceGroupName
    The Resource Group Name where the VM lives
.PARAMETER VmName
    The Name of the target VM
.PARAMETER MakeDisksStandard
    Changes the VM's disks to Standard_LRS SKUs
.PARAMETER MakeDisksStandardSSD
    Changes the VM's disks to StandardSSD_LRS SKUs
.PARAMETER MakeDisksPremium
    Changes the VM's disks to Premium_LRS SKUs
.PARAMETER StartVmAfter
    Starts the VM after disk adjustments
.EXAMPLE
    PS> AdjustVmDisk.ps1 -SubscriptionId 123-abc-xyz -ResourceGroupName app505-jmd-rg -VmName jmddev001 -MakeDisksStandardSSD -StartVmAfter
    1. Prompts user to confirm the action
    2. Stops VM jmddev001, in the app505-jmd-rg Resource Group, in the 123-abc-xyz subscription ID
    3. Changes its disks to StandardSSD
    4. Starts the VM once complete
.EXAMPLE
    PS> AdjustVmDisk.ps1 -SubscriptionId 123-abc-xyz -ResourceGroupName app505-jmd-rg -VmName jmddev001 -MakeDisksPremium
    1. Prompts user to confirm the action
    2. Stops VM jmddev001, in the app505-jmd-rg Resource Group, in the 123-abc-xyz subscription ID
    3. Changes its disks to Premium
    4. Leaves the VM deallocated once complete
.EXAMPLE
    PS> AdjustVmDisk.ps1 -SubscriptionId 123-abc-xyz -ResourceGroupName app505-jmd-rg -VmName jmddev001 -MakeDisksPremium -Force
    1. Stops VM jmddev001, in the app505-jmd-rg Resource Group, in the 123-abc-xyz subscription ID
    2. Changes its disks to Premium
    3. Leaves the VM deallocated once complete
.NOTES
    Author: John Delisle
    Date:   Sept. 2021    
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)][String]$SubscriptionId,
    [Parameter(Mandatory)][String]$ResourceGroupName,
    [Parameter(Mandatory)][String]$VmName,

    [Parameter(Mandatory, ParameterSetName = "Standard_LRS")][Switch]$MakeDisksStandard,
    [Parameter(Mandatory, ParameterSetName = "StandardSSD_LRS")][Switch]$MakeDisksStandardSSD,
    [Parameter(Mandatory, ParameterSetName = "Premium_LRS")][Switch]$MakeDisksPremium,

    [Switch]$StartVmAfter,

    [Parameter()][Switch]$Force
)

$ErrorActionPreference = "Stop"

# Set up some warning text
$afterDiskChange = if ($StartVmAfter) { "start the VM once complete" } else { "leave the VM stopped once complete" }

switch ($true) {
    $MakeDisksStandard { $actionMsg = "Stop (deallocate) VM, change its disks to Standard_LRS, and $afterDiskChange."; $newSku = "Standard_LRS" }
    $MakeDisksStandardSSD { $actionMsg = "Stop (deallocate) VM, change its disks to StandardSSD_LRS, and $afterDiskChange."; $newSku = "StandardSSD_LRS" }
    $MakeDisksPremium { $actionMsg = "Stop (deallocate) VM, change its disks to Premium_LRS, and $afterDiskChange."; $newSku = "Premium_LRS" }
}


# Select the sub and grab the VM
$sub = Select-AzSubscription -SubscriptionId $SubscriptionId
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Enumerate the VM's disks
$disks = @()
foreach ($diskName in @($vm.StorageProfile.OsDisk.Name) + @($vm.StorageProfile.DataDisks.Name)) {
    $disks += Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $diskName
}

# Infor the user of what we're doing
Write-Output "In-scope VMs:"
$vm | Sort-Object -Property ResourceGroupName | Format-Table -Property ResourceGroupName, @{name = 'VM Name'; expression = { $_.Name } }

Write-Output "In-scope Disks:"
$disks | Sort-Object -Property ResourceGroupName | Format-Table -Property ResourceGroupName, @{name = 'Disk Name'; expression = { $_.Name } }, @{name = 'Associated to VM Name'; expression = { $_.ManagedBy.split("/")[-1] } }, @{name = 'Current SKU'; expression = { $_.Sku.Name } }


# Warn the user
if (-not $Force) {
    Write-Warning "This operation will affect the above VMs and Disks as follows: $actionMsg" -WarningAction Inquire
}

# Stop the VM
Write-Output "Stopping VM..."
$vm | Stop-AzVM -Force
Write-Output "Done stopping VM"

# change the disks
Write-Output "Changing disks to $newSku"
foreach ($disk in $disks) {
    $disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($newSku)
    $jobs = $disk | Update-AzDisk -AsJob
}
Write-Output "Waiting for all disks to change..."
$jobs = Get-Job | Wait-Job
Write-Output "Done changing disks"

# optionally start the VM
if ($StartVmAfter) {
Write-Output "Starting VM..."
    $vm | Start-AzVM
Write-Output "Done starting VM"
} else {
Write-Output "Leaving VM in a deallocated state"
}

Write-Output "All done!"
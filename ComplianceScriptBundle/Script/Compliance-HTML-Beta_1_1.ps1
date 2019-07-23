#BETA 1.0
#Added SMTP compliance for vCenters
#Added SVC_automation acount and login encryption
#Added Root Folder Variable
#BETA 1.1
#Modified 20% Free to run faster
#Added power state to Off on global VM filter
#Added exclusion for GuestToolsUnmanaged. This will no longer show up in the script
#Added VMX and VMDK Mismatch portion
#Filtered out ILM from any datastores in 20% Free (check Exceptions Script)
#added Zerto VRA exclusions from global exclusions list


cls
""
Write-Host "Script to check top issues in Centura's VMware Environment"
Write-Host "Created: 04/05/2017"
Write-host "Last Modified: 1/16/19"
""
Start-Sleep -s 3
cls


#Root Folder
$RootFolder = "C:\scripts\ComplianceScriptBundle\"

#outfile Variable
$outfile = "$RootFolder\Output\Compliance Script.html"


#Connecting to all vCenters
$vcenterlist = get-content "$RootFolder\vCenters\vcentersPROD.txt"

foreach ($myvcenter in $vcenterlist) {

Write-Host Connecting to $myvcenter
Try {connect-viserver $myvcenter -User centura\svc_automation -Password @ut0m@t10n} Catch {Connection-Alert $myvcenter ;break}
}

#HTML Framework
$Style = "
<style>
    BODY{background-color:#b0c4de;}
    TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
    TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
    TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
    tr:nth-child(odd) { background-color:#d3d3d3;}
</style>
"



#Get all VM an Host Variables
Write-host "Defining all Variables"
$GetallIBMClusters = Get-Cluster
$GetAllHosts = Get-VMHost
$getHostsCount = $GetAllHosts.count
$GetAllVms = Get-VM | where {($_.ExtensionData.Config.ManagedBy.ExtensionKey -ne 'com.vmware.vcDr')}
$GetVmsCount = $GetAllVms.count
$datastores = Get-Datastore
Write-Host "done"

#Execute Wildcard script for all wildcard exceptions

Write-Host "Running exceptions script"
& "$RootFolder\ExceptionFiles\ExceptionScript\WildCardExceptionScript.ps1"

start-sleep -Seconds 10

Write-Host "done"


#One-off Exception Variables
$AllHostsException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\AllHosts.txt"
$VMXNET3Exception = get-content "$rootfolder\ExceptionFiles\OneOffExceptions\VMXNET3.txt"
$CBlockTrackingException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\CBlockTracking.txt"
$ThkPvsnLzyZroException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\ThkPvsnLzyZro.txt"
$NUMAException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\NUMA.txt"
$ToolsVersionStatusException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\ToolsVersionStatus.txt"
$SCSIParaVirtualException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\SCSIParaVirtual.txt"
$DatastoresException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\Datastores.txt"
$GlobalVMException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\GlobalVM.txt"
$SnapshotHostException = get-content "$RootFolder\ExceptionFiles\OneOffExceptions\SnapshotHost.txt"

#Wildcard Exception Variables
$allVmsWildcardException = Get-Content "$RootFolder\ExceptionFiles\WildcardExceptions\GlobalVMWildcardException.txt"
$AllHostsWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\AllHostsWildcardException.txt"
$VMXNET3WildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\Vmxnet3WildcardException.txt"
$CBlockTrackingWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\CBlockTrackingWildcardExceptions.txt"
$ThkPvsnLzyZroWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\ThkPvsnLzyZroWildcardExceptions.txt"
$NUMAWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\NUMAWildcardException.txt"
$ToolsVersionStatusWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\ToolsVersionStatusWildcardException.txt"
$SCSIParaVirtualWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\SCSIParaVirtualWildcardException.txt"
$DatastoresWildcardException = get-content "$RootFolder\ExceptionFiles\WildcardExceptions\DatastoresWildcardExceptions.txt"
$VMDKMismatchWildcardException = Get-Content "$RootFolder\ExceptionFiles\WildcardExceptions\VMDKMismatch.txt"



#All Current VMs and Hosts in environment Script
Write-Host "Adding up all Hosts and vCenters"
$outObj = New-Object -TypeName PSObject
Add-Member -InputObject $outObj -MemberType NoteProperty -Name VMCount -Value $GetVmsCount
Add-Member -InputObject $outObj -MemberType NoteProperty -Name VMHostCount -Value $getHostsCount

Write-host "There are $GetVmsCount Virtual Machines in our environment."
Write-host "There are $getHostsCount Hosts in our environment" 

$VmsAndHosts = $outObj | Select VMCount, VMHostCount | ConvertTo-Html -As:LIST -Fragment -PreContent '<h3>Total Hosts and VMs</h3>' | Out-String



#Defining vCenter Variable for array

foreach ($vm0 in $GetAllVMs){
$VCTR0 = (($vm0.uid).split("@")[1]).split(":")[0]
$VM0 | Add-Member -type NoteProperty -name vCenter -value $VCTR0 -Force
}   

Write-Host "Running VMXNET3 Portion"
#Displaying VMXNET3 Compliance information - Any VM that is not a VMXNET3 adapter for the NIC will show up in this list

$VMXNET3 = $GetAllVMs | Get-NetworkAdapter | Where-object {($_.Type -ne "Vmxnet3")`
 -and ($_.Type -ne "EnhancedVmxnet")`
  -and ($VMXNET3Exception -notcontains $_.parent)`
   -and ($VMXNET3WildcardException -notcontains $_.parent)`
    -and ($allVmsWildcardException -notcontains $_.parent)`
   } | select parent, type, @{N="vCenter";E={(($_.uid).split("@")[1]).split(":")[0]}} | ConvertTo-Html -Fragment -PreContent '<h3>Show any NIC that is not VMXNET3</h3>' | Out-String
Write-Host "done"  


Write-Host "Running ATSHeartbeat portion"
#Hosts with IBM storage should have Advanced Setting for ATS Heartbeat set to 0

$IBMoutput = Foreach ($currentCluster in $allclusters) {

    $Firstvmhost = Get-cluster $currentCluster | Get-VMHost | Select-Object -First 1

    foreach ($CurrentVMHost in $Firstvmhost) {
         
        $FirstHostsLuns = $CurrentVMHost | get-scsilun | select vendor
        
        $containsIBMStorage = $false

        foreach ($scsilun in $AllHostsLuns){
            If ($scsilun.vendor -like "*ibm*") {$containsIBMStorage = $true} 
        }       
        
        if ($containsIBMStorage){
           $ScanWholeCluster = $currentCluster | Get-VMHost
           foreach ($ScannedHost in $ScanWholeCluster){
            (Get-AdvancedSetting -entity $ScannedHost -name VMFS3.UseATSForHBOnVMFS5).value -eq "0"
        }
     }
     }
}

$IBMOutputString = $IBMOutput | select Parent | ConvertTo-Html -Fragment -PreContent '<h3> ATS Heartbeat setting on these hosts should be set to 1</h3>' | Out-String
Write-Host "done"



#Change Block Tracking Compliance Information - If change block tracking is not enabled it will show up in this list
#Write-Host "Running Change Block Tracking portion"
#$CBlockTracking = $GetAllVMs | Where-Object {($CBlockTrackingException -notcontains $_.name) -and ($CBlockTrackingWildcardException -notcontains $_.Name) -and ($allVmsWildcardException -notcontains $_.Name)
#  } | Select Name, @{N="CBT";E={(Get-View $_).Config.ChangeTrackingEnabled}}, vCenter | WHERE {$_.CBT -eq "$False"} | ConvertTo-Html -AS Table -Fragment -PreContent '<h3>Showing any Change Block Tracking that is Disabled</h3>' | Out-String
#Write-Host "done"

#VM name and VMX file are mismatched - this requires a svMotion to remediate and will show up on the list
Write-Host "Running VMX to VMname mismatch"
$mismatch = @()

$VMDKMismatchVMs = $GetAllVms | where {($VMDKMismatchWildcardException -notcontains $_.name)}

$VMDKMismatch = foreach ($singlevm in $VMDKMismatchVMs){
    $VMDKs = ($singlevm | Get-HardDisk) | where {($_.disktype -ne "Rawphysical")}
    foreach ($vmdk in $VMDKs){     
        $temparray = "" | select name, vCenter, DatastorePath
        $TempArray.Name = $VMDk.Parent
        $temparray.vCenter = $singlevm.uid.Split("@").split(":")[1]
        $TempArray.DatastorePath = $vmdk.Filename
        $vmdkname = $vmdk.Filename.Split(" ").Split("/")[1]
        if ($vmdkname -ne $singlevm.name){ 
            $mismatch += $TempArray
            }
    }  
}
$vmxmismatch = foreach ($singlevm in $VMDKMismatchVMs){
    $Temparray2 = "" | select Name, vCenter, DatastorePath
    $Temparray2.name = $singlevm.Name
    $temparray2.vCenter = $singlevm.uid.Split("@").split(":")[1]
    $Temparray2.DatastorePath = ($singlevm.ExtensionData.LayoutEx.File | where {($_.type -eq "config")}).name
    $GetVMname = $singlevm.name
    $VMXname = ($singlevm.ExtensionData.LayoutEx.File | where {($_.type -eq "config")}).name.split("/").split(".")[1]
    if ($GetVMname -ne $VMXname){
      $mismatch += $Temparray2
    }
}
$Mismatchstring = $mismatch | where {($allVmsWildcardException -notcontains $_.Name)} | select Name, vCenter, Datastorepath | sort vCenter, Name | ConvertTo-Html -Fragment -PreContent '<h3>Show all VMDK and VMX Mismatches</h3>' | Out-String
Write-Host "done"


#Thick Provision Lazy Zeroed - Any VM that is not a Thick Provision Lazy Zeroed will show up in this list
Write-Host "Running Thin Provisoned portion"
$ThkPvsnLzyZro = $GetAllVMs | Get-HardDisk | where {($_.StorageFormat -ne "Thick")`
 -and ($_.StorageFormat -ne $null)`
  -and ($_.StorageFormat -ne "EagerZeroedThick")`
   -and ($ThkPvsnLzyZroException -notcontains $_.parent)`
    -and ($ThkPvsnLzyZroWildcardException -notcontains $_.parent)`
     -and ($allVmsWildcardException -notcontains $_.parent)
    } | select Parent, StorageFormat, CapacityGB , Filename, @{N="vCenter";E={(($_.uid).split("@")[1]).split(":")[0]}} | ConvertTo-Html -Fragment -PreContent '<h3>Showing Any VMDK that is NOT Thick Provision Lazy Zeroed and is not an RDM</h3>' | Out-String           
    Write-Host "done"


#CPU and Memeory Hot-Add Compliance information - If Hot add is enabled for a VM AND the VM has more than than 9 vCPU Then it will show up in this list
Write-Host "Running NUMA compliance portion"
$NUMASettings = $GetAllVMs | where {($_.NumCpu -ge 9)`
  -and ($_.ExtensionData.Config.CpuHotAddEnabled -eq "$True")`
   -and ($_.ExtensionData.Config.MemoryHotAddEnabled -eq "$True")`
    -and ($NUMAException -notcontains $_.name)`
     -and ($NUMAWildcardException -notcontains $_.name)`
      -and ($allVmsWildcardException -notcontains $_.Name)
    } | Select Name,@{N="CpuHotAddEnabled";E={$_.ExtensionData.Config.CpuHotAddEnabled}}, @{N="MemoryHotAddEnabled";E={$_.ExtensionData.Config.MemoryHotAddEnabled}}, vCenter | ConvertTo-Html -Fragment -PreContent '<h3>VMs with CPU Greater than 9 and CPU/Memory Hot Add Enabled</h3>' | Out-String
Write-Host "done" 
 
    
#VMTools Compliance Information - if the VM is not showing as VMtools being current it will show up on this list
Write-Host "Running VMware Tools compliance portion"
$ToolsVersionStatus = $GetAllVMs |  Where-Object {($_.Extensiondata.guest.toolsVersionStatus -notlike "guestToolsCurrent")`
 -and ($_.Extensiondata.guest.toolsVersionStatus -notlike "guestToolsUnmanaged")`
  -and ($ToolsVersionStatusException -notcontains $_.name)`
   -and ($ToolsVersionStatusWildcardException -notcontains $_.name)`
    -and ($allVmsWildcardException -notcontains $_.Name)
    } | Select Name, @{N="VMToolsStatus";E={($_.Extensiondata.Guest.toolsVersionStatus)}}, vCenter | ConvertTo-Html -Fragment -PreContent '<h3>Showing VM Tools that are not Current</h3>' | Out-String
Write-Host "done"

#Shows all SCSI Controllers that are Not paravirtual
Write-Host "Running scsi controller portion"
$SCSIParaVirtual = $GetAllVMs | Get-ScsiController | where {($_.type -notlike "ParaVirtual")`
 -and ($_.bussharingmode -ne "Physical")`
  -and ($SCSIParaVirtualException -notcontains $_.parent)`
   -and ($SCSIParaVirtualWildcardException -notcontains $_.parent)`
    -and ($allVmsWildcardException -notcontains $_.Name)
  } | Select Parent, Type, @{N="vCenter";E={(($_.uid).split("@")[1]).split(":")[0]}} | ConvertTo-Html -Fragment -PreContent '<h3>Show SCSI Controllers That are Not ParaVirtual</h3>' | Out-String
Write-host "done"

#Alarms are NOT enabled on these hosts
Write-Host "Checking for all disabled alarms on hosts"
$AlarmActions = $GetAllHosts | Where-Object {$_.ExtensionData.AlarmActionsEnabled -eq $false} | Select Name, @{N="vCenter";E={(($_.uid).split("@")[1]).split(":")[0]}} | ConvertTo-Html -Fragment -PreContent '<h3>Show Hosts that do not have alarms enabled</h3>' | Out-String
Write-Host "done"

#Show all vCenters without proper SMTP Settings

Write-Host "Checking for SMTP Settings on all vCenters"
$SMTPoutput = foreach ($vCenter1 in $vcenterlist){

$SMTPadvancedsetting = Get-AdvancedSetting -Entity $vCenter1 -Name 'mail.smtp.server'

if ($SMTPadvancedsetting.value -ne "mail.centura.org"){
    $SMTPadvancedsetting
    }
 } 
 $smtpstring = $SMTPoutput | Select Entity | ConvertTo-Html -Fragment -PreContent '<h3>Show all vCenters with bad SMTP Settings</h3>' | Out-String
 Write-Host "done"

 
 #Current Snapshot information in environment
 Write-host "Running Snapshot Portion"
$myCollection = @()

$VMSnapshot = $GetAllVms | sort | get-view | ? {$_.snapshot -ne $null}


$i = 0;

foreach ($vm in $VMSnapshot) 
{

	
	$myObject = “” | Select-Object VMGuest,GuestState,SnapshotName,SnapshotCreatedTime,vCenter,SnapshotDescription,NeedsConsolidation

	
	$myObject.VMGuest = $vm.name
    $myObject.NeedsConsolidation = $vm.Runtime.consolidationNeeded
    
	
	
	$strVC = $null ; $strVC = $vm.client.serviceurl.split("/", [StringSplitOptions]'RemoveEmptyEntries')[1].toUpper()
				
		
	foreach ($snap in $vm.snapshot.rootsnapshotlist)
	{
	
    $myObject.GuestState = $vm.guest.gueststate
	$myObject.SnapshotName = $snap.name 
	$myObject.SnapshotCreatedTime = $snap.createTime
	$myObject.vCenter = $strVC 
	$myObject.SnapshotDescription = $snap.description
    
	}
	
	
	$myCollection += $myObject   

	$i++;



} 

$SnapshotString = $myCollection | where {($SnapshotHostException -notcontains $_.VMGuest)} | select VMGuest, GuestState, SnapshotName, SnapshotCreatedTime, vCenter, SnapshotDescription, NeedsConsolidation | ConvertTo-Html -Fragment -PreContent '<h3>Show all Snapshots</h3>' | Out-String

Write-Host "done"

#Snapshot Consolidation

Write-host "Running Consolidation Portion"

$ConsolidateString = $GetAllVms | where {($_.ExtensionData.Runtime.consolidationNeeded -eq "True")} | Select Name, @{N="vCenter";E={(($_.uid).split("@")[1]).split(":")[0]}} | ConvertTo-Html -Fragment -PreContent '<h3>Show all Consolidations that need to be performed</h3>' | Out-String

Write-host "done"

#Datastores not 20% Free
Write-Host "Running datastore 20% Free portion"
function CalcPercent {
param(
[parameter(Mandatory = $true)]
[int]$InputNum1,
[parameter(Mandatory = $true)]
[int]$InputNum2)
      
      [decimal]$per = ($InputNum1 / $InputNum2)*100
      $per = "{0:N2}" -f $per
      return $per
}


ForEach ($ds in $datastores)
{
      if (($ds.Type -notlike "NFS") -and ($DatastoresException -notcontains $_.name) -and ($DatastoresWildcardException -notcontains $_.name))
      {
          [decimal]$PercentFree = CalcPercent $ds.FreeSpaceMB $ds.CapacityMB
          $ds | Add-Member -type NoteProperty -name PercentFree -value $PercentFree
           
          if (($PercentFree -le 20.00) -or ($ds.CapacityMB -le 2000000)){
                
                $FSGBRounded = [math]::Round($ds.FreespaceGB)
                $CapGBRounded = [math]::Round($ds.CapacityGB)
                $UsedSpaceGB = [math]::Round(($CapGBRounded) - ($FSGBRounded))
                $TargetSizeGB = [math]::Round( ($UsedSpaceGB/.8),2 )
                $GetScsiCanonical = $ds.ExtensionData.Info.Vmfs.Extent.Diskname | Out-String
                $ds | Add-Member -type NoteProperty -name UsedSpaceGB -value $UsedSpaceGB
                $ds | Add-Member -type NoteProperty -name FreeSpaceGBRounded -value $FSGBRounded
                $ds | Add-Member -type NoteProperty -name CapacityGBRounded -value $CapGBRounded
                $ds | Add-Member -type NoteProperty -name TargetSizeGB -value $TargetSizeGB
                $ds | Add-Member -type NoteProperty -name CanonicalName -value $GetScsiCanonicalName
          }
      }
}

$datastoresString = $datastores | where-object {($_.PercentFree -le 20.00)`
-and ($_.FreeSpaceGB -le 200)`
-and ($DatastoresException -notcontains $_.name)`
-and ($DatastoresWildcardException -notcontains $_.name)`
-and ($allVmsWildcardException -notcontains $_.Name)
  } | Select Name,FreeSpaceGBRounded,PercentFree,UsedSpaceGB,CapacityGBRounded,TargetSizeGB,CanonicalName | ConvertTo-Html -Fragment -PreContent '<h3>Datastores with less than 20% free</h3>' | Out-String
  
Write-Host "done"





#Output Table

ConvertTo-HTML -head $Style -PostContent $VmsAndHosts, $AlarmActions, $SnapshotString, $ConsolidateString, $datastoresString, $smtpstring, $mismatchstring , $VMXNET3, $ThkPvsnLzyZro, $NUMASettings, $SCSIParaVirtual, $IBMOutputString, $ToolsVersionStatus -PreContent '</h1><font Face="verdana" size="6" color="#0066ff">Centura VMware Compliance Script</font></h1>' | Out-File $outfile



Invoke-Item "$RootFolder\Output\Compliance Script.html"

#command to Disconnect from vCenter

Disconnect-VIServer * -Confirm:$False

#Send email with attachment

$to = "CEITVMWareAlert@Centura.Org","ericwarne@centura.org"
$from = "svc_automation@centura.org"
$body = "Attached is the Centura Compliance Report `
`
Please review and fix issues as they are found `
"
$smtp = "mail.centura.org"

Send-MailMessage -To $to -From $from -Subject "Compliance Report" -Body $body -SmtpServer $smtp -Attachments $outfile

#Remove Large Variables and clean memory
if ($DatastoresString) { try { Remove-Variable -Name DatastoresString -Scope Global -Force } catch { } }
if ($outfile) { try { Remove-Variable -Name outfile -Scope Global -Force } catch { } }
if ($ibmoutput) { try { Remove-Variable -Name IBMoutput -Scope Global -Force } catch { } } 
if ($GetAllIBMClusters) { try { Remove-Variable -Name GetAllIBMClusters -Scope Global -Force } catch { } } 
if ($GetAllHosts) { try { Remove-Variable -Name GetAllHosts -Scope Global -Force } catch { } }
if ($GetAllVMs) { try { Remove-Variable -Name GetAllVMs -Scope Global -Force } catch { } } 
$mismatch = $null


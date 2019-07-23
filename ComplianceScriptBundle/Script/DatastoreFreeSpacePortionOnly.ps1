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
$outfile = "$RootFolder\Output\Compliance Script Modified.html"


#Connecting to all vCenters
$vcenterlist = get-content "$RootFolder\vCenters\vcentersPROD.txt"


foreach ($myvcenter in $vcenterlist) {
    $logincred = Get-VICredentialStoreItem -Host $myvCenter -File C:\Scripts\ComplianceScriptBundle\Creds\credfile.xml
    Write-Host Connecting to $myvcenter
    Try {connect-viserver $myvcenter -User $logincred.User -Password $logincred.Password} Catch {Connection-Alert $myvcenter ;break}
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
$GetAllVms = Get-VM | where {($_.ExtensionData.Config.ManagedBy.ExtensionKey -notlike 'com.vmware.vcDr*')}
$GetVmsCount = $GetAllVms.count
$datastores = Get-Datastore
$ClusteredDatastores = (Get-DatastoreCluster | Get-Datastore).Name
Write-Host "done"

#Execute Wildcard script for all wildcard exceptions
Write-Host "Running exceptions script"
& "$RootFolder\ExceptionFiles\ExceptionScript\WildCardExceptionScript.ps1"

#give Wildcard script extra time to run
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
                $ds | Add-Member -type NoteProperty -name CanonicalName -value $GetScsiCanonical
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

ConvertTo-HTML -head $Style -PostContent $datastoresString -PreContent '</h1><font Face="verdana" size="6" color="#0066ff">Centura VMware Compliance Script</font></h1>' | Out-File $outfile

Invoke-Item "$RootFolder\Output\Compliance Script Modified.html"

#command to Disconnect from vCenter
Disconnect-VIServer * -Confirm:$False
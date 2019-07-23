#Global VM Exceptions____________________________________________________________

$GetAllVms | where {($_.name -like "*z-vra*")} | select -ExpandProperty name | ft -hide -autosize | out-file "$RootFolder\ExceptionFiles\WildcardExceptions\GlobalVMWildcardException.txt"


#AllHosts________________________________________________________________________
$GetAllhosts | where {`
($_.name -like "*z-vra*")`
  } | select name | ft -hide -autosize | out-file "$RootFolder\ExceptionFiles\WildcardExceptions\AllHostsWildcardException.txt"



#ToolsVersionStaus_______________________________________________________________
$GetAllVms | where {($_.name -like "*xa*")`
 -or ($_.name -like "CEVDIN*")`
  -or ($_.name -like "CEVDIG*")`
   -or ($_.name -like "LVSI*")`
    -or ($_.name -like "launcher*")`
     -or ($_.name -like "*uc*")
       } | select -ExpandProperty name | ft -hide | out-file "$RootFolder\ExceptionFiles\WildcardExceptions\ToolsVersionStatusWildcardException.txt"


#SCSI Paravirtual Exceptions_____________________________________________________
$GetAllVMs | Where-object {($_.name -like "*ATM*")`
 -or ($_.name -like "*uc*")`
  -or ($_.name -like "*SEC*")`
   -or ($_.name -like "*VMA*")`
    -or ($_.name -like "*SSO*")`
   } | select -ExpandProperty name | ft -hide -autosize | out-file "$RootFolder\ExceptionFiles\WildcardExceptions\SCSIParaVirtualWildcardException.txt"



#VMXNET3_________________________________________________________________________
$GetAllVMs | Where-object {($_.name -like "*VMA*")`
 -or ($_.name -like "*uc*")
   } | select -ExpandProperty name | ft -hide -autosize | out-file "$RootFolder\ExceptionFiles\WildcardExceptions\Vmxnet3WildcardException.txt"



#Change Block Tracking___________________________________________________________
$GetAllVMs | Where-Object {($_.name -like "*xa*")`
  -or ($_.name -like "lvsi*")`
   -or ($_.name -like "cet*")`
    -or ($_.name -like "cev*")`
     -or ($_.name -like "ced*")`
      -or ($_.name -like "LAUNCHER*")`
       -or ($_.name -like "V1PASCATV*")`
        -or ($_.name -like "V1PINVATV*")`
         -or ($_.name -like "cepascspk*")`
          -or ($_.name -like "cepinvspk*")`
           -or ($_.name -like "*uc*")
         } | Select -ExpandProperty Name | ft -hide -AutoSize | Out-File "$RootFolder\ExceptionFiles\WildcardExceptions\CBlockTrackingWildcardExceptions.txt"



#Thick Provision Lazy Zero_______________________________________________________
$GetAllVMs | where {($_.name -like "*xa*")`
     -or ($_.name -like "lvsi*")`
      -or ($_.name -like "cet*")`
       -or ($_.name -like "cev*")`
        -or ($_.name -like "ced*")`
         -or ($_.name -like "vRealize*")`
          -or ($_.name -like "V1PASCATV*")`
           -or ($_.name -like "V1PINVATV*")`
            -or ($_.name -like "LAUNCHER*")  
           } | select -ExpandProperty name | ft -hide -AutoSize | Out-File "$RootFolder\ExceptionFiles\WildcardExceptions\ThkPvsnLzyZroWildcardExceptions.txt"



#Datastores under 20% Free___________________________________________________
$datastores | where {($_.name -like "*ilm*")`
  -or ($_.name -like "V1PASCATV*")`
   -or ($_.name -like "V1PINVATV*")`
    -or ($_.name -like "*LNL*")`
     -or ($_.name -like "*_local")  } | Select -ExpandProperty Name | ft -hide -AutoSize | Out-File "$RootFolder\ExceptionFiles\WildcardExceptions\DatastoresWildcardExceptions.txt"


#VM to VMDK name Mismatch_____________________________________________________________
$GetAllVMs | where {($_.name -like "*_*")} | Select -ExpandProperty Name | ft -hide -AutoSize | Out-File "$RootFolder\ExceptionFiles\WildcardExceptions\VMDKMismatch.txt"
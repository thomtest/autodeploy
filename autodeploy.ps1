Import-Module ActiveDirectory

CLS
#Write-Host "Disconnecting from vCenters"
#Disconnect-VIServer -Server * -Force -Confirm:$false

$vmlist = Import-Csv -Path 'C:\users\thom\Documents\autodeploy\autodeploy.csv'


foreach ($vm in $vmlist){
	$vcenter = $vm.Vcenter
	$vmname = $vm.Name
	$template = $vm.Template
	$cluster = $vm.Cluster
	$resourcepool = $vm.ResourcePool
	$datastore = $vm.Datastore
	$vcpu = $vm.vCPU
	$memory = $vm.Memory
	$HD = $vm.HardDrive
	$HD2 = $vm.HardDrive2
	$portgroup = $vm.Portgroup
	$IPAddress = $vm.IpAddress
	$Subnet = $vm.Subnet
	$Gateway = $vm.Gateway
	$diskformat = $vm.DiskFormat
	$datastore2 = $vm.DataStore2
	$location = $vm.Location
	$contact = $vm.Contact
	$description = $vm.Description

	#Write-Host "Connecting to vCenter $vcenter"

	#Connect-VIServer $vcenter



	if (($IPAddress -eq '') -and ($Subnet -eq '') -and ($Gateway -eq '')){$Customization = Get-OSCustomizationSpec 'AutoDeploy_DHCP'}
		else {$Customization = Get-OSCustomizationSpec 'AutoDeploy'
			  $Customization | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $Subnet -DefaultGateway $Gateway -Dns 128.163.111.54,128.163.111.55,128.163.111.167,128.163.111.166 -Wins 128.163.111.170,128.163.111.171
		     }


	New-VM -Name $vmname -Template $template -VMHost (Get-Cluster $cluster | Get-VMHost | Get-Random) -Datastore $datastore -OSCustomizationSpec $Customization
	Start-Sleep -Seconds 10

	$NewVM = Get-VM $vmname
	$NewVM | Set-VM -MemoryGB $memory -NumCpu $vcpu -Confirm:$false

	if ($location -eq ''){Write-Host "No VM Folder specified. VM will be placed under the root of the datacenter"}
	else {Move-VM $NewVM -Destination $location -Confirm:$false}


		if ($resourcepool -eq ''){Write-Host "No Resource Pool specified. VM will be placed under the root of the cluster"}
	else {$rpool = Get-ResourcePool -Name $resourcepool -Location $cluster
		  Move-VM $NewVM -Destination $rpool -Confirm:$false}


	$hostname = $NewVM | Get-VMHost
	$switches = Get-VMHost $hostname | Get-VirtualSwitch -Standard
	$localswitch = 0

	foreach ($switch in $switches){
		if($switch.Name -eq "vSwitch1"){$localswitch = 1}}

	if($localswitch -eq 1){$vlan = Get-VirtualPortGroup -VMHost $hostname -VirtualSwitch "vSwitch1" -Name $portgroup
		$NewVM | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $vlan -Confirm:$false}
	else{$NewVM | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $portgroup -Confirm:$false}


	$NewVm | Get-HardDisk -Name "Hard Disk 1" | set-HardDisk -CapacityGB $HD -Confirm:$false
	if ($HD2 -ne ''){$NewVm | New-HardDisk -CapacityGB $HD2 -Datastore $datastore2 -StorageFormat $diskformat -Confirm:$false}

	#Set VM Annotation Notes
	$NewVM | Set-VM -Notes "Contact: $contact `rDescription: $description"  -Confirm:$false

	Start-VM -VM $NewVM
	Start-Sleep -Seconds 10

	#Write-Host "Disconnecting from $vcenter"
	#Disconnect-VIServer -Server $vcenter -Force -Confirm:$false

	}

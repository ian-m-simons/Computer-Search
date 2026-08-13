#created by Ian Simons

param(
    [string]$user
    )

function pingComputer($computerName){
    ping $computerName
}

function continuousPing($computerName){
    ping $computerName -t
}

function saveName($computerName){
    set-clipboard $computerName
}

function saveIP($computerName){
    $rawLookupData = nslookup $computerName
    $sdata = $rawLookupData.split("`n")
    $ip = $sdata[4]
    set-clipboard $ip.substring(10)
}

function getADGroups($computerName){
    $ADobject = get-adcomputer $computerName -properties memberof
    $rawData = $ADobject.memberof
    $array = $rawData.split("`n")
    $outputArray = @()
    foreach ($i in $array){
        $workingdata = $i.split(",")
        $outputArray += $workingdata[0].substring(3)
    }
    $outputArray | sort-object
}

function getCurrentUser($computerName){
    try{
        $lastLogin = quser /server:$computerName
        $lastLogin = $lastLogin[1]
        $lastLogin = $lastLogin.split(" ")
        $lastLogin = $lastLogin[1]
        write-host "last login by $lastLogin `n`n"
    }
    catch{write-host "no login detected"}
}

function getUpTime($computerName){
    try{
            $uptimeObject = get-wmiobject -Class Win32_OperatingSystem -ComputerName $computerName -ErrorAction silentlyContinue
            $uptime = (get-Date) - [System.Management.managementDateTimeConverter]::ToDateTime($uptimeObject.lastbootuptime)
            write-host "uptime: $uptime`n`n"
    }catch{write-host "Unable to determine uptime`n`n"}
}

function offerRA($computerName){
    msra /offerra $computerName
}

function getDiskUsage($computerName){
    $data = get-wmiobject -ComputerName $computerName -class Win32_logicalDisk -ErrorAction silentlyContinue | ? {$_.deviceID -eq "C:"} | select freeSpace,size
    $free = [float]$data.freeSpace
    $total = [float]$data.size
    $percentfree = [Math]::Round((($free / $total)*100),2)
    $percentUsed = 100-$percentfree
    $freeGigs = [Math]::Round(($free / 1000000000),2)
    $totalAvail = [Math]::Round(($total /1000000000),2)
    $used = $totalAvail - $freeGigs
    write-host "$used / $totalAvail GB used ($percentUsed% used)`n$freeGigs remaining ($percentfree%)"
}

function getOS($computerName){
    get-adcomputer $computerName -properties operatingSystem | select operatingsystem
}

function getRecoveryKey($computerName){
    $finalComputer = get-adcomputer $computerName
    get-adobject -filter * -SearchBase $finalComputer.distinguishedname -properties whencreated, msfve-recoverypassword | sort whenCreated -Descending | select whencreated, msfve-recoverypassword
}

function saveMACaddress($computerName){
    $data = getmac /s $computerName | sls -pattern "disconnected" -notMatch | sls -pattern "======" -notMatch | sls -Pattern "physical address" -notMatch
    $line = $data[1]
    $line = [String]$line
    $line = $line.split(" ")
    $rawMAC = $line[0]
    $MACArray = $rawMAC.split("-")
    $finalMAC = ""
    for ($i = 0; $i -lt $MACArray.length; $i++){
        $finalMAC += $MACArray[$i].ToLower()
        if ($i %2 -ne 0 -and $i -ne 5){
            $finalMAC += "."
        }

    }
    set-clipboard $finalMAC
}

function reboot($computerName){
    shutdown /r /m \\$computerName /t 000 /f
}

function NetworkMenu($computerName){
    $option = read-host "select from options:`n1)ping computer`n2)ping computer continuously`n3)copy IP address to clipboard`n4)copy MAC address to clipboard`n0)exit`noption >"
    try{$option = [int]$option}
    catch{write-host "[ERROR] Invalid input, please try again";exit}
    if ($option -gt 4 -or $option -lt 0){write-host "[ERROR] Invalid selection, please try again";exit}
    elseif ($option -eq 1){pingComputer($computerName)}
    elseif ($option -eq 2){continuousPing($computerName)}
    elseif ($option -eq 3){saveIP($computerName)}
    elseif ($option -eq 4){saveMACaddress($computername)}
    elseif ($option -eq 0){exit}
    else{write-host "unspecified error, exiting";exit}
}

function SystemsMenu($computerName){
    $option = read-host "select from options:`n1)copy computer name to clipboard`n2)get computer AD groups`n3)get uptime`n4)check disk usage`n5)check operating system`n6)get bitlocker recovery keys`n7)remotely reboot machine`n0)exit`noption >"
    try{$option = [int]$option}
    catch{write-host "[ERROR] Invalid input, please try again";exit}
    if ($option -gt 7 -or $option -lt 0){write-host "[ERROR] Invalid selection, please try again";exit}
    elseif ($option -eq 1){saveName($computerName)}
    elseif ($option -eq 2){write-host $option;getADGroups($computerName)}
    elseif ($option -eq 3){getUpTime($computerName)}
    elseif ($option -eq 4){getDiskUsage($computerName)}
    elseif ($option -eq 5){getOS($computerName)}
    elseif ($option -eq 6){getRecoveryKey($computerName)}
    elseif ($option -eq 7){reboot($computerName);write-host "reboot initiated"}
    elseif ($option -eq 0){exit}
    else{write-host "unspecified error, exiting";exit}
}

function SecurityMenu{
    param(
        [string]$computerName
       # [string]$url,
       # [string]$key
    )
    $key = read-host -Prompt "Please enter your API key (if you do not have one but feel that you should, reach out to the Network Team) `n" 
    write-host "`n"
    $keyID = read-host -prompt "please enter your key ID (if you do not know your key ID, it can be found in the XDR management portal) `n"
    $keyID = [string]$keyID
    $scriptUrl = "[redacted]"
    $endpointDataUrl = "[redacted]"
    $isolateUrl = "[redacted]"
    $unisolateUrl = "[redacted]"
    #json of headers
    $Headers = @{
        'Authorization' = $key;
        'x-xdr-auth-id' = $keyID;
        'Accept-Encoding' = "*";
        'content-type' = "application/json"
    }

    $endpointDataPayload = "{
        `"request_data`":{
            `"filters`":[{`"field`":`"hostname`",
                    `"operator`":`"in`",
                    `"value`":[`"$computerName`"]
                }],
            `"parameters_values`":{}
        }
    }"
    $endpointdataPayload | convertTo-Json
    $response = invoke-restmethod -Uri $endpointDataURL -Method Post -Headers $Headers -Body $endpointDataPayload -contentType "application/json"  
    
    $endpointID = $response.reply.endpoints.endpoint_id
    $endpointStatus = $response.reply.endpoints.endpoint_status -eq "CONNECTED"

    write-host "`n`nstarting security menu with endpointID of: $endpointID"
    write-host "This Menu is currently under construction, options may not currently work"
    $option = read-host "select from options:`n1)logoff current user(s)`n2)check XDR connection status`n3)isolate endpoint`n4)unisolate endpoint`n0)exit`noption >"
    try{$option = [int]$option}
    catch{write-host "[ERROR] Invalid input, please try again";exit}
    if ($option -gt 4 -or $option -lt 0){write-host "[ERROR] Invalid selection, please try again";exit}
    elseif ($option -eq 1){
        $logoutPayload = "{
            `"request_data`":{
                `"filters`":[{`"field`":`"Endpoint_id_list`",
                    `"operator`":`"in`",
                    `"value`":[`"$endpointID`"]}],
                    `"script_uid`":`"[redacted]`",
                    `"parameters_values`":{}
                }
        }"

        write-host "are you sure you want to logout users on $computerName?"
        $confirm = read-host -Prompt "To confirm, please enter the word `"logout`"`n>"
        if ($confirm = "logout"){
            invoke-restmethod -Uri $scriptUrl -Method Post -Headers $Headers -Body $logoutPayload -contentType "application/json"
        }
        else{write-host "logout not confirmed, aborting";exit}

    }
    elseif ($option -eq 2){if ($endpointStatus){write-host "Endpoint is connected to XDR"}else{write-host "Endpoint is disconnected from XDR"}}
    elseif ($option -eq 3){$isolatePayload = "{
            `"request_data`":{`"endpoint_id`":`"$endpointID`"}
        }"
        write-host "are you sure you want to isolate this endpoint? it will be unable to communicate with anything except for XDR"
        $confirm = read-host -Prompt "To confirm, please enter the word `"isolate`"`n"
        if ($confirm -eq "isolate"){
            invoke-restmethod -Uri $isolateUrl -Method Post -Headers $Headers -Body $isolatePayload -contentType "application/json"
        }
        else{write-host "isolation not confirmed, aborting";exit}
        }
    elseif ($option -eq 4){
        $unisolatePayload = "{
            `"request_data`":{`"endpoint_id`":`"$endpointID`"}
        }"
        write-host "unisolating endpoint"
        invoke-restmethod -Uri $unisolateUrl -Method Post -Headers $Headers -Body $unisolatePayload -contentType "application/json"
    }
    elseif ($option -eq 0){exit}
    else {write-host "unspecified error, exiting";exit}
}


function Menu{
    param(
        [string]$computerName
       # [string]$url,
       # [string]$key
    )
    $option = read-host "select from options:`n1)network menu`n2)systems menu`n3)security menu`n4)get current logins`n5)offer remote assistance`n0)exit`noption >"
    try{
        $option = [int]$option
    }
    catch {write-host "[Error] Invalid option, please try again";exit}
    if ($option -gt 5 -or $option -lt 0){write-host "[ERROR] Invalid selection, please try again";exit}
    elseif ($option -eq 1){NetworkMenu($computerName)}
    elseif ($option -eq 2){SystemsMenu($computerName)}
    elseif ($option -eq 3){
        if ($url -ne "NONE" -and $key -ne "NONE"){
            SecurityMenu -computerName $computerName #-url $url -key $key
        }
        else {
            write-host "no valid API URL or Key, I will take you there for testing, but nothing will work"
            SecurityMenu -computerName $computerName #-url $url -key $key 
        }
    }
    elseif ($option -eq 4){getCurrentUser($computerName)}
    elseif ($option -eq 5){offerRA($computerName)}
    elseif ($option -eq 0) {exit}
    else{write-host "unspecified error, exiting";exit}
}

function main{
    param(
        [string]$search

    )
   
    #TODO Ensure that selection is within provided options
    $computer = get-adComputer -filter * -properties Description | where-object {$_.Description -match $search}
    if ($computer -is [array]){
        write-host "More than 1 computer found, please select the correct computer"
        $optionCount = 1
        foreach ($i in $computer){
            $option = $i.Description
            write-host "$optionCount) $option `n"
            $optionCount++
        }
        write-host "0) exit `n"
        $selection = read-host "> "
        $selection = [int]$selection
        $selection--
        if ($selection -eq -1){exit}
        $computer[$selection]
        Menu -computerName $computer[$selection].name
    }
        

    elseif ($computer -eq $null){
        try{
            $computer = get-adcomputer $search -properties Description 
            $computer
            Menu -computerName $computer.name
        }
        catch{
            write-host "[ERROR] Computer not found"
            exit
        }
    }
    elseif ($computer -is [Microsoft.ActiveDirectory.Management.ADAccount]){
        $target = $computer.name
        $computer
        Menu -computerName $computer.name 
    }
    else{write-host "idk what you just did, but I'm out";exit}
}


main -search $user 


# SRC: https://cloudbrothers.info/en/test-udp-connection-powershell/
# Author: Fabian Bader, Laszlo Scherman
# License: Public domain (was not marked on the source)


<#

.EXAMPLE
```
    . .\UDPmessages.ps1
    Start-UDPServer -Port 5004
    # ------------
    Stop with CRTL + C
    Server is waiting for connections - 0.0.0.0:5004

    remote          recv                send                data
    ------          ----                ----                ----
    127.0.0.1:50000 2022-06-18 13:14:00 2022-06-18 13:14:00 @{a=Hello; b=World}
    127.0.0.1:50000 2022-06-18 13:14:49 2022-06-18 13:14:49 Hello
    127.0.0.1:50000 2022-06-18 13:14:49 2022-06-18 13:14:49 World
    127.0.0.1:50000 2022-06-18 13:15:18 2022-06-18 13:15:18
    Close UDP connection
```
#>
function Start-UDPServer {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory = $false)]
        $Port = 10000
    )
    
    # Create a endpoint that represents the remote host from which the data was sent.
    $remoteComputer = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
    Write-Host "Stop with CRTL + C"

    # Create a UDP listener on Port $Port
    $udpObject = [System.Net.Sockets.UdpClient]::new($Port)
    if ($udpObject -eq $null) {
        throw "Failed to bind to port $Port. Try again later."
    }
    
    try {
        
        Write-Host "Server is waiting for connections - $($udpObject.Client.LocalEndPoint)"

        # Convert received UDP datagram from bytes to String
        $ASCIIEncoding = [System.Text.ASCIIEncoding]::new()

        # Loop de Loop
        do {
            $receiveBytes = $udpObject.Receive([ref]$RemoteComputer)

            if ($receiveBytes -and $receiveBytes.Count -gt 1) {
                [string]$returnString = $ASCIIEncoding.GetString($receiveBytes)

                # Output information
                ($returnString | ConvertFrom-Json) | Select-Object `
                    @{N='remote'; E={"$($remoteComputer.address.ToString()):$($remoteComputer.Port.ToString())"}}, `
                    @{N='recv'; E={"$(Get-Date -UFormat '%Y-%m-%d %T')"}}, `
                    *

        
            }

            Start-Sleep -Milliseconds 200

        } while (1)

    } 
    finally {

        Write-Host "Close UDP connection"
        $udpObject.Close()

    }


}

<#

.EXAMPLE
Start-UDPServer -Port 5004
```
    . .\UDPmessages.ps1
    @{a="Hello"; b="World"} | Test-NetConnectionUDP -ComputerName 127.0.0.1 -Port 5004
    ("Hello", "World") | Test-NetConnectionUDP -ComputerputerName 127.0.0.1 -Port 5004
    @($null) | Test-NetConnectionUDP -ComputerName 127.0.0.1 -Port 5004
```
#>

function Test-NetConnectionUDP {
    [CmdletBinding()]
    param (
        # Desit
        [Parameter(Mandatory = $true)]
        [int32]$Port,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        # Parameter help description
        [Parameter(Mandatory = $false)]
        [int32]$SourcePort = 50000,

        [Parameter(ValueFromPipeline, ValueFromRemainingArguments)]
        $inputData
    )

    begin {
        # Create a UDP client object
        $udpObject = [system.Net.Sockets.Udpclient]::new($SourcePort)
        # Define connect parameters
        $udpObject.Connect($ComputerName, $Port)
        $ASCIIEncoding = New-Object System.Text.ASCIIEncoding
    }

    process {
        
        $inputData | ForEach-Object {
            $data = @{ 
                send="$(Get-Date -UFormat "%Y-%m-%d %T")";
                data=$_
            }

            # Convert current time string to byte array
            $bytes = $ASCIIEncoding.GetBytes( ($data | ConvertTo-Json ) )

            # Send data to server
            [void]$udpObject.Send($bytes, $bytes.length)
        }
    }

    end {
        # Cleanup
        $udpObject.Close()
    }
}

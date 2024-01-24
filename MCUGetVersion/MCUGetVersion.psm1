
$pipename = "MCUGetVersion-$PID"

function Start-MCUVersionBroker {
    [CmdletBinding()]param()
    $script:pipe = [System.IO.Pipes.NamedPipeServerStream]::new($pipename, [System.IO.Pipes.PipeDirection]::InOut, 1, [System.IO.Pipes.PipeTransmissionMode]::Message)
    $env:_MCUGetVersion_PipeName = $pipename
    $process = Start-Process cmd -ArgumentList "/c start /b /wait /machine amd64 powershell -ExecutionPolicy Bypass `"$PSScriptRoot\mcugetversion-server.ps1`"" -WindowStyle Hidden -PassThru
    $script:pipe.WaitForConnection()
}
function ReadPipeMessage([System.IO.Pipes.PipeStream]$pipe) {
    $buf = [byte[]]::new(4096)
    $ms = [System.IO.MemoryStream]::new()
    do {
        $len = $pipe.Read($buf, 0, 4096)
        $ms.Write($buf, 0, $len)
    } while (-not $pipe.IsMessageComplete)
    return $ms.ToArray()
}

function Get-MCUDriverVersion {
    [CmdletBinding()]param([string]$Name)
    $jdoc = $Name | ConvertTo-Json -Compress
    $buf = [System.Text.Encoding]::UTF8.GetBytes($jdoc)
    $script:pipe.Write($buf, 0, $buf.Length)
    $message = ReadPipeMessage($script:pipe)
    $obj = [System.Text.Encoding]::UTF8.GetString($message) | ConvertFrom-Json
    return $obj
}

function Stop-MCUVersionBroker {
    $script:pipe.Close()
}

Export-ModuleMember -Function "Get-MCUDriverVersion", "Start-MCUVersionBroker", "Stop-MCUVersionBroker"

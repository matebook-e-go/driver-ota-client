$ErrorActionPreference = 'Stop'

$PipeName = $env:_MCUGetVersion_PipeName

$env:PATH = "$PSScriptRoot;$env:PATH"

Add-Type @"
using System;
using System.Text;
using System.Threading;
using System.Runtime.InteropServices;

namespace FuckHW {
    public class InteractInfoWithMCU {
        [DllImport("InteractInfoWithMCU.dll", CharSet = CharSet.Ansi)]
        public static extern int GetDriverVersion(string dev, ref byte buf, int bufsize, out int retsize);

        public static string GetDriverVersion(string dev) {
            var buf = new byte[64];
            int s;
            GetDriverVersion(dev, ref buf[0], 64, out s);
            return Encoding.Default.GetString(buf, 0, s);
        }
    }
}
"@

$pipe = [System.IO.Pipes.NamedPipeClientStream]::new($PipeName)
$pipe.Connect()
$pipe.ReadMode = [System.IO.Pipes.PipeTransmissionMode]::Message

function ReadPipeMessage([System.IO.Pipes.PipeStream]$pipe) {
    $buf = [byte[]]::new(4096)
    $ms = [System.IO.MemoryStream]::new()
    do {
        $len = $pipe.Read($buf, 0, 4096)
        $ms.Write($buf, 0, $len)
    } while (-not $pipe.IsMessageComplete)
    return $ms.ToArray()
}

function write-jobject($obj) {
    $jdoc = $obj | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jdoc)
    $pipe.Write($bytes, 0, $bytes.Length)
}

function write-null() {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("null")
    $pipe.Write($bytes, 0, $bytes.Length)
}

while ($pipe.IsConnected) {
    $message = ReadPipeMessage($pipe)
    try {
        $json = [System.Text.Encoding]::UTF8.GetString($message)
        $request = $json | ConvertFrom-Json
        if ($null -eq $request -or $request.GetType() -ne [string]) {
            write-null
            continue
        }
        $response = [FuckHW.InteractInfoWithMCU]::GetDriverVersion($request)
        write-jobject($response)
    } catch {
        write-null
        continue
    }
}

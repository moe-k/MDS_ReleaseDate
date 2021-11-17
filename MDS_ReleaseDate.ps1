$uri = "https://mds-scheduling-prod.umusic.com/releaseearliestreleasedates?upcs=";
$headers = @{ 'x-api-key' = "InputAPIKeyHere" };
$error.clear(); # clear errors for a blank try/catch so previous runs errors are not visible

function ReadUPCFile() { 
    try{
        [string] $upcFileName = $(Read-Host -Prompt "Please provide the file name to read from which contains your upc list. Before running this script, please make sure the file is located at $PSScriptRoot");
        [string[]] $upcs = Get-Content -ErrorAction Stop -Path "$PSScriptRoot\$upcFileName";  # use "-ErrorAction -Stop" to force into try/catch block
        $upcs = $upcs -join ",";
        $uri = $uri + $upcs;
    }
    catch [System.Management.Automation.ItemNotFoundException]{
        Write-Output("");
        Write-Output("The Specificed File was not found at path $PSScriptRoot");
        Write-Output("");
        exit;
    }
    catch {
         Write-Output($errors);
         exit;
    }
    return $uri;
}

function Progress () {
    $range = Get-Random -Maximum 10;
    for($i=1; $i -le $range; $i++)
    {
        Write-Progress -Activity "Calling MDS WebService and exporting to CSV" -status "Calling MDS WebService and exporting to CSV (Progress: Seconds $i)";
        Start-Sleep 1;
    }
}

function CallWebService() {
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -Body $jsonbody -ContentType 'application/JSON';
    } catch {
        Write-Host "Invoke-RestMethod on $uri returned StatusCode:" $_.Exception.Response.StatusCode.value__ ;
        exit;
    }
    return $response;
}

function ExportToCsv($response) {
   try{
      $response | Select-Object upc, EarliestReleaseDate | Export-Csv -ErrorAction Stop -Path "$PSScriptRoot\ReleaseDates_$((Get-Date).ToString('yyyy-MM-dd hh mm')).csv" -NoTypeInformation; 
      Invoke-Item $PSScriptRoot;
   } catch {
         Write-Host "Something went wrong when attempting to export to CSV";
         exit;
   }
}

# Main 
Clear-Host; 
$uri = ReadUPCFile;
Progress;
$response = CallWebService;
ExportToCsv($response);

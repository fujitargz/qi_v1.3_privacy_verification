<#
 # Run ProVerif
 #
 # > powershell.exe -ExecutionPolicy RemoteSigned -File .\Invoke-ProVerif.ps1
 #>

Workflow Invoke-ProVerif
{
    $authflow = @(
        'baseline'
        'extended'
        'simpleflow'
        'flowwithcaching'
        'flowwithcaching_cached'
        'flowwithcachingandrevocation'
        'flowwithcachingandrevocation_cached'
        'flowwithcachingandrevocation_revoked'
        'flowwithcachingandrevocation_cached_revoked'
        'challengefirstflow'
        'challengefirstflow_cached'
        'challengefirstflow_revoked'
        'challengefirstflow_cached_revoked'
    )

    $bdidgen = @(
        'static'
        'dynamic'
        'dynamic_within2s'
    )

    $resultdir = ".\results"
    $privacyresultdir = "$resultdir\privacy"
    Remove-Item -Path ".\results" -Recurse
    New-Item -Force -ItemType "directory" -Path "." -Name $resultdir
    New-Item -Force -ItemType "directory" -Path "$resultdir" -Name "privacy"

    $processes = @()

    foreach ( $bdid in $bdidgen )
    {
        New-Item -ItemType "directory" -Path "$privacyresultdir" -Name $bdid
        $main = ".\privacy_authentication_$bdid.pv"
        foreach ( $flow1 in $authflow )
        {
            New-Item -ItemType "directory" -Path "$privacyresultdir\$bdid" -Name $flow1
            $A1 = ".\lib\privacy\PRx_A\1\$flow1.pvl"
            foreach ( $flow2 in $authflow )
            {
                New-Item -ItemType "directory" -Path "$privacyresultdir\$bdid\$flow1" -Name $flow2
                $outdir = "$privacyresultdir\$bdid\$flow1\$flow2"
                $A2 = ".\lib\privacy\PRx_A\2\$flow2.pvl"
                $B = ".\lib\privacy\PRx_B\$flow2.pvl"
                $command = "proverif -graph $outdir -lib .\lib\decl.pvl -lib $A1 -lib $A2 -lib $B $main"
                $out = "$command | Out-File -FilePath $outdir\result.txt"
                $p = Start-Process -PassThru -WindowStyle Hidden -Filepath "powershell" -ArgumentList "-Command", "$out"
                $processes += $p.Id
            }
        }
    }

    foreach ( $id in $processes)
    {
        Wait-Process -Id $id -ErrorAction SilentlyContinue
    }

    Get-ChildItem -Path $resultdir -Recurse -Include *.dot | Remove-Item
}

Invoke-ProVerif
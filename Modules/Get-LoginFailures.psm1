function Get-LoginFailures {
    <#
    .SYNOPSIS
        Gets login failures events within specified time frame. Defaults to now and the last 60 days.

    .DESCRIPTION
        Gets login failures events within specified time frame. Defaults to now and the last 60 days.

    .PARAMETER StartTime
        Specify when to begin event log collection. Defaults to 60 days ago based on system time.
        
    .PARAMETER EndTime
        Specify when to end login failures event collection. Defaults to current time on system time.

    .EXAMPLE 
        Get-LoginFailures

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-LoginFailures} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\LoginFailures.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-LoginFailures} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_LoginFailures.csv")
        }

    .NOTES
        Updated: 2019-03-28

        Contributing Authors:
            Anthony Phipps, Jack Smith
            
        LEGAL: Copyright (C) 2019
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
        
    .LINK
       https://github.com/TonyPhipps/Meerkat
       https://github.com/TonyPhipps/Meerkat/wiki/LoginFailures
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-LoginFailures at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        if(!($StartTime)){
            $StartTime = (Get-Date) - (New-TimeSpan -Days 60)
        }

        if(!($EndTime)){
            $EndTime = (Get-Date)
        }
    }

    process{

        $UserSID = @{
            Name = 'UserSID'
            Expression = { $_.Properties[4].Value  }
        }
        
        $UserName = @{
            Name = 'UserName'
            Expression = { $_.Properties[5].Value  }
        }
        
        $UserDomainName = @{
            Name = 'UserDomainName'
            Expression = { $_.Properties[6].Value  }
        }
        
        $Status = @{
            Name = 'Status'
            Expression = { $_.Properties[7].Value  }
        }
        
        $LogonType = @{
            Name = 'LogonType'
            Expression = { $_.Properties[10].Value  }
        }
        
        $WorkStationName = @{
            Name = 'WorkStationName'
            Expression = { $_.Properties[13].Value  }
        }
        
        $IPAddress = @{
            Name = 'IPAddress'
            Expression = { $_.Properties[19].Value  }
        }
        
        $AuthenticationPackageName = @{
            Name = 'AuthenticationPackageName'
            Expression = { $_.Properties[12].Value  }
        }
        
        $ProcessId = @{
            Name = 'ProcessId'
            Expression = { $_.Properties[17].Value  }
        }
        
        $ProcessName = @{
            Name = 'ProcessName'
            Expression = { $_.Properties[18].Value  }
        }
        
        $ResultsArray = Get-WinEvent -FilterHashtable @{ LogName="Security"; ID=4625; StartTime=$StartTime; EndTime=$EndTime } 
        
            foreach ($Result in $ResultsArray) {
                $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
                $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            }
        
        return $ResultsArray | Select-Object -Property Host, DateScanned, TimeCreated, $UserSID, $UserName, $UserDomainName, $Status, $LogonType, $WorkStationName, $IPAddress, $AuthenticationPackageName, $ProcessId, $ProcessName, ActivityID

        }
    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}
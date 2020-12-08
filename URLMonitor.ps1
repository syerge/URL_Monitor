$URLListFile = "D:\URL_Monitoring\URLList.txt"  #Change the File location if needed
$cc = "syerge@outlook.com" #Update the Email CC'd list
$Down= 000
$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue 
  $Result = @() 
   
  Foreach($Uri in $URLList) { 
  $time = try{ 
  $request = $null 
  add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12
   ## Request the URI, and measure how long the response took. 
  $result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri -UseDefaultCredentials} 
  $result1.TotalMilliseconds 
  }  
  catch 
  { 
   <# If the request generated an exception (i.e.: 500 server 
   error or 404 not found), we can pull the status code from the 
   Exception.Response property #> 
   $request = $_.Exception.Response
   $time = -1 
  }   
  $result += [PSCustomObject] @{ 
  Time = Get-Date; 
  Uri = $uri; 
  StatusCode = [int] $request.StatusCode; 
  StatusDescription = $request.StatusDescription; 
  ResponseLength = $request.RawContentLength; 
  TimeTaken =  $time;  
  } 
 
} 
    #Prepare email body in HTML format 
if($result -ne $null) 
{ 
    $Outputreport = "<HTML><TITLE>Website Availability Report Unhealthy</TITLE><BODY background-color:white><font color =""#99000"" face=""Microsoft Tai le""><H2> Website Availability Report </H2></font><Table border=1 cellpadding=0 cellspacing=0><TR bgcolor=#ccd1d1 align=center><TD align=center><B>URL</B></TD><TD align=center><B>StatusCode</B></TD><TD align=center><B>StatusDescription</B></TD><TD><B>ResponseLength</B></TD><TD><B>TimeTaken</B></TD></TR>" 
    Foreach($Entry in $Result) 
    { 
        if($Entry.StatusCode -ne "200") 
        { 
            $Outputreport += "<TR bgcolor=red>" 
            $Down= 404
        } 
        else 
        { 
            $Outputreport += "<TR>" 
        } 
        $Outputreport += "<TD>$($Entry.uri)</TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.timetaken)</TD></TR>" 
    } 
    $Outputreport += "</Table></BODY></HTML>" 
} 
 
$Outputreport | out-file D:\URL_Monitoring\URLMonitor.html 

$Outputreport | Export-Csv -Path "D:\URL_Monitoring\URLMonitoring.csv" -Encoding ascii -NoTypeInformation


If($Down -eq "404")
{
Send-MailMessage -To "<YourEmail or TeamsEmail>" -From "<YourEmail or MonitoringMailID>" -cc $cc.Split(';')  -Subject "WEBSITE DOWN" -Body "$Outputreport" -bodyashtml -SmtpServer "<Add your SMTP SeverName>" 
}
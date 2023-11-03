#Variável constante  
$OutputFile = "DistributionGroupMembers.csv"  
$arrDLMembers = @{}   

#Instalar Modulo ExchangeOnline no Powershell
Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5
Import-Module ExchangeOnlineManagement

#Coleta credenciais
Write-Host 'INFORME O E-MAIL DO ADMINISTRADOR DO TENANT:' -ForegroundColor white -BackgroundColor red
Connect-ExchangeOnline
  
#Prepara a saída com os cabeçalhos  
Out-File -FilePath $OutputFile -InputObject "Distribution Group DisplayName,Distribution Group Email,Member DisplayName, Member Email, Member Type" -Encoding UTF8  
  
#Coleta todos os grupos do 365
$objDistributionGroups = Get-DistributionGroup -ResultSize Unlimited  
  
#Verificar todos os grupos, um a um    
Foreach ($objDistributionGroup in $objDistributionGroups)  
{      
     
    write-host "Processing $($objDistributionGroup.DisplayName)..."  
  
    #Coletar os membros 
    $objDGMembers = Get-DistributionGroupMember -Identity $($objDistributionGroup.PrimarySmtpAddress)  
      
    write-host "Found $($objDGMembers.Count) members..."  
      
    #Associar todos os membros  
    Foreach ($objMember in $objDGMembers)  
    {  
        Out-File -FilePath $OutputFile -InputObject "$($objDistributionGroup.DisplayName),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType)" -Encoding UTF8 -append  
        write-host "`t$($objDistributionGroup.DisplayName),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType)" 
    }  
}  
 
#Finalizando a sessão
Disconnect-ExchangeOnline
Write-Host 'GRUPOS EXPORTADOS. O RESULTADO ESTÁ NA MESMA PASTA DO SCRIPT DENOMINADO DistributionGroupMembers.csv.' -ForegroundColor white -BackgroundColor green
pause
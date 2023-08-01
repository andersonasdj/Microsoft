<#
================================================================================================

Nome:           Relatório completo de contas do Office 365
Descrição:      Esse relatório coleta todoas as informações importantes das contas do Office 365
Version:        2.0
Criado por:     Anderson de Araujo Santos
Observação:     Antes de usar, instalar os modulos e importar
Observação:     Contas não licenciadas apresentarão uma exception durante a execução, porém,
                isso não influenciará no resultado.

===============================================================================================
 
 Set-ExecutionPolicy Unrestricted
 Install-Module MSOnline
 Install-Module AzureAD
 Install-Module ExchangeOnlineManagement
 Import-Module AzureAD
 Import-Module MSOnline
 Import-Module ExchangeOnlineManagement

#>

Connect-MsolService
Connect-ExchangeOnline

Write-Host "Encontrando contas do Azure Active Directory ..."
$Usuarios = Get-MsolUser -All | Where-Object { $_.UserType -ne "Guest" }
$Report = [System.Collections.Generic.List[Object]]::new() # Criação do arquivo de saída
Write-Host "Processando" $Usuarios.Count "contas ..."
$Contagem=0
ForEach ($Usuario in $Usuarios) {

    $UsuarioTemporario = $Usuario.UserPrincipalName

    if($Usuario.isLicensed -eq $false){
        $StatusCaixa = "Não Licenciado"
    }else{
        $StatusCaixa = "Licenciado"
    }
    
    $UsuarioExchange = Get-Mailbox -Identity $UsuarioTemporario
    Write-Progress -Activity "`n     Processando : $Contagem "`n"  Processando a caixa: $UsuarioTemporario"

    $MetodoPadraoMFA = ($Usuario.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq "True" }).MethodType
    $MfaCelular = $Usuario.StrongAuthenticationUserDetails.PhoneNumber
    $PrimarySMTP = $Usuario.ProxyAddresses | Where-Object { $_ -clike "SMTP*" } | ForEach-Object { $_ -replace "SMTP:", "" }
    $Aliases = $Usuario.ProxyAddresses | Where-Object { $_ -clike "smtp*" } | ForEach-Object { $_ -replace "smtp:", "" }
    $UltimoLoginData = Get-MailboxStatistics -Identity $Usuario.UserPrincipalName | Select LastLogonTime
    
    if ($UltimoLoginData -eq $null){
        if ($UltimoLoginData.LastLogonTime -eq $null){
            $UltimoLogin = "Não Licenciado"
        }
    }
    else{
        $UltimoLogin = $UltimoLoginData.LastLogonTime 
    }

    if($Usuario.StrongAuthenticationRequirements){
        $StatusMFA = $Usuario.StrongAuthenticationRequirements.State
    }else{
        $StatusMFA = 'Disabled'
    }

    if($MetodoPadraoMFA){
        Switch ($MetodoPadraoMFA){
            "OneWaySMS" { $MetodoPadraoMFA = "Text code authentication phone" }
            "TwoWayVoiceMobile" { $MetodoPadraoMFA = "Call authentication phone" }
            "TwoWayVoiceOffice" { $MetodoPadraoMFA = "Call office phone" }
            "PhoneAppOTP" { $MetodoPadraoMFA = "Authenticator app or hardware token" }
            "PhoneAppNotification" { $MetodoPadraoMFA = "Microsoft authenticator app" }
        }
    }else{
        $MetodoPadraoMFA = "Não cadastrado"
    }
  
    if($UsuarioExchange.ProhibitSendQuota -eq $null){
        $TipoDeCaixa = "Não Licenciado"
    }else{
        $TipoDeCaixa = $UsuarioExchange.RecipientTypeDetails
    }

    if(($UsuarioExchange.ArchiveDatabase -eq $null) -and ($UsuarioExchange.ArchiveDatabaseGuid -eq $UsuarioExchange.ArchiveGuid))
    {
        $StatusArquivoMorto = "Desativado"
        $VolumeArquivoMorto = "Desativado"
        $MarcaRetencao = "Desativado"
    }else{
        $StatusArquivoMorto = "Ativado"
        $MarcaRetencao = $UsuarioExchange.RetentionPolicy
        $VolumeArquivoMorto = ((Get-MailboxStatistics -Identity $UsuarioExchange.UserPrincipalName -Archive -WarningAction SilentlyContinue).TotalItemSize.value -replace "\(.*","")
    }

    if($UsuarioExchange.UserPrincipalName -ne $null){
        $Stats=Get-MailboxStatistics -Identity $UsuarioExchange.UserPrincipalName
        $QtdItens = $Stats.ItemCount
        $VolumeCaixa = $stats.TotalItemSize.value -replace "\(.*",""
    }else{
        $QtdItens = "Não Licenciado"
        $VolumeCaixa = "Não Licenciado"
    }
   
   

   if($UsuarioExchange.ProhibitSendReceiveQuota -eq $null){
       $CotaCaixa = "Não Licenciado"
   }else{
       $CotaCaixa = $UsuarioExchange.ProhibitSendReceiveQuota -replace "\(.*",""
   }

   if($UsuarioExchange.AutoExpandingArchiveEnabled -eq $True)
   {
      $StatusAutoExpanssaoMorto = "Habilitado"
   }else{
      $StatusAutoExpanssaoMorto = "Desabilitado" 
   }
   $id = "";

   $ReportLine = [PSCustomObject] @{
        Id                  = $id
        NomeExibicao        = $Usuario.DisplayName
        Email               = $Usuario.UserPrincipalName
        StatusCaixa         = $StatusCaixa
        TipoDeCaixa         = $TipoDeCaixa
        LoginBloqueado      = $Usuario.BlockCredential
        StatusMFA           = $StatusMFA 
        MetodoPadraoMFA     = $MetodoPadraoMFA
        MfaCelular          = $MfaCelular
        Criacao             = $Usuario.WhenCreated
        AlteracaoSenha      = $Usuario.LastPasswordChangeTimestamp
        UltimoLogin         = $UltimoLogin    
        SMTP                = ($PrimarySMTP -join ',')
        Aliases             = ($Aliases -join ',')
        Licenca             = $Usuario.Licenses.AccountSkuId
        QtdItens            = $QtdItens
        VolumeCaixa         = $VolumeCaixa
        StatusArquivoMorto  = $StatusArquivoMorto
        VolumeArquivoMorto  = $VolumeArquivoMorto
        MarcaRetencao       = $MarcaRetencao
        StatusAutoExpanssaoMorto = $StatusAutoExpanssaoMorto
        CotaCaixa           = $CotaCaixa
    }                
    $Report.Add($ReportLine)
    $Contagem++
}

Write-Host "Report está na mesma pasta onde foi executado o script com o nome de RelatorioExchange + a data e hora atual"
$Report | Select-Object Id, NomeExibicao, Email, StatusCaixa, TipoDeCaixa, LoginBloqueado, StatusMFA, MetodoPadraoMFA, MfaCelular, Criacao, AlteracaoSenha, UltimoLogin, SMTP, Aliases, Licenca, QtdItens, VolumeCaixa, StatusArquivoMorto, VolumeArquivoMorto, MarcaRetencao, StatusAutoExpanssaoMorto, CotaCaixa | Sort-Object UserPrincipalName | Out-GridView
$Report | Sort-Object UserPrincipalName | Export-CSV -Encoding UTF8 -NoTypeInformation ".\RelatorioExchange_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
Disconnect-ExchangeOnline -Confirm:$false

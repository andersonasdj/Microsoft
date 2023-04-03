<#
==========================================================================================================
Nome:           Arquivamento force 
Descrição:      Procedimento para (forçar) inicialização do processo de arquivamento.
Version:        1.0
Criado por:     Anderson de Araujo Santos
Observação1:    Antes de usar, instalar o modulo, importar e liberar execução de script não assinado.
Observação2:    Caso tenha acabado de ativar o arquivo morto, pode ser necessário aguardar alguns minutos.

==========================================================================================================
 
 Install-Module ExchangeOnlineManagement
 Import-Module ExchangeOnlineManagement
 Set-ExecutionPolicy Unrestricted

#>

#Conectar powershell:
Connect-ExchangeOnline -UserPrincipalName navin@contoso.com


#Forçar Arquivamento
Start-ManagedFolderAssistant -Identity email@contoso.com.br
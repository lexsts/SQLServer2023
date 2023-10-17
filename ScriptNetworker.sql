/** Script para gerar a string de restore do Networker
Author: L.Munhoz
Date: 12/06/2023

*** Executar o script abaixo alterando as variaveis devidas, no servidor de origem 
*/


/*******  Variáveis iniciais
@db         = Informar o banco de dados a ser restaurado
@DataPath   = Informar o caminho do(s) arquivo(s) de dados no servidor de destino, para o remap 
@LogPath    = Informar o caminho do(s) arquivo(s) de Log no servidor de destino, para o remap
@dataBackup = Informar a data que deseja restaurar, se deixar null, será realizado o restore do ultimo backup FULL realizado 
*****/
------------------------------------------------
declare @db varchar(150)       = 'HFSMP' 
declare @DataPath varchar(255) = 'R:\HFSMP\Data'
declare @LogPath varchar(255)  = 'R:\HFSMP\Log' 
declare @dataBackup datetime   = null
------------------------------------------------

declare @command varchar(8000)
declare @hostname varchar(150)  = ''  --// Informe o Alias do Server no Networker aqui, normalmente é o NetworkName, confirmar o MachineName antes, se for o caso coloque na mao aqui e comente a linha a baixo-- 'sqlpos022dp-adm.intraservice.corp'

set @hostname = cast(SERVERPROPERTY('MachineName') as varchar(150)) + '-adm.intraservice.corp' --// Ainda é possivel verificar no log do Networker a ultima execução com sucesso.


--// lista de parametros do Networker
declare @s varchar(255), @c varchar(255),@d varchar(255), @CC varchar(8000), @t varchar(255)

/* 
-s : Datazone onde o backup é realizado. Produção: bkpcor1p,bkpcor70003p, bkpcor8000p, bkpcor9000p //
-c : Alias do servidor cadastrado no Networker, costuma ser o Network Name //
-d : destino: NomeDoServiço$Instancia:NomeDoBancoNovo //
-C : --> @CC : Remap dos Datafiles no servidor de destino //
-t : Recovery Point Time // 
************ IMPORTANTE informar o banco de Origem no final da string ex: MSSQL:BDCADASTRO ****************
*/

set @s = ' -s bkpcor70003p-adm.intraservice.corp '  --// outras opções de datazone : bkpcor1p / bkpcor70003p / bkpcor8000p / bkpcor9000p
set @c = ' -c ' + @hostname                         --// Informe o alias aqui, se @hostname estiver errado verifique no log do Networker a ultima execução com sucesso.
set @d = ' -d "MSSQL$SQL2019:HFSMP_REQXXXXX"'       --// informar aqui NomeDoServiço$Instancia:NomeDoBancoNovo de destino (verificar o nome em propriedades do serviço).


--// @t =  DATA ULTIMO BACKUP FULL se nao informado no inicio do script
if @dataBackup is null
begin
    SELECT @dataBackup = MAX(msdb.dbo.backupset.backup_finish_date)
    FROM msdb.dbo.backupmediafamily 
    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
    WHERE msdb.dbo.backupset.database_name =  @db
    AND backupset.type = 'd' --// backup full
end

-- Monta a data na seguinte formatação: "Fri Jun 02 02:43:00 2023
Select @t = ' -t "'+
substring(DATENAME(dw,@dataBackup),1,3) + ' ' +
substring(DATENAME(mm,@dataBackup),1,3) + ' ' +
 case when  Day(@dataBackup) < 10 then 
   '0'+ cast(Day(@dataBackup)as varchar(2))
   else cast(Day(@dataBackup) as varchar(2))
   end + ' '+
CONVERT(VARCHAR,@dataBackup,108) + ' ' +
cast(YEAR(@dataBackup) as varchar(4))
+'"'

-- @C -->@CC:  monta a string de caminhos dos arquivos de dados para o remap
select 
  name
, physical_name
, case when type = 1 
     then '"'+name+'" = "' + @LogPath + reverse(substring(reverse(physical_name),1,charindex('\',reverse(physical_name)))) +'"'
  else 
          '"'+name+'" = "' + @DataPath +reverse(substring(reverse(physical_name),1,charindex('\',reverse(physical_name)))) +'"'
end as data_path 
into #files
from sys.master_files
where database_id = db_ID(@db)
order by type, file_id
select distinct @cc =   
    STUFF(( SELECT N'', ' ,' + [data_path] 
    FROM #files x
        FOR XML PATH(''), TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
from #files t

--// Monta a string concatenando os parametros
set @command = 'nsrsqlrc ' + @s + @c + @d + ' -C "'+@cc+'"' + @t +' "MSSQL:'+@DB+'"'
select @command as [Executar no Servidor Destino]


/* o Resultado esperado é:
 -- nsrsqlrc -s bkpcor70003p-adm.intraservice.corp  -c sqlpos022dp-adm.intraservice.corp -d  "MSSQL$SQL2019:HFSMP_CRQXXXX" -C ""HFSMP" = "R:\HFSMP\Data\HFSMP.mdf", "HFSMP_1" = "R:\HFSMP\Data\HFSMP_1.ndf", "HFSMP_2" = "R:\HFSMP\Data\HFSMP_2.ndf", "HFSMP_3" = "R:\HFSMP\Data\HFSMP_3.ndf", "HFSMP_4" = "R:\HFSMP\Data\HFSMP_4.ndf", "HFSMP_DATA5" = "R:\HFSMP\Data\HFSMP_DATA5_REMEDIACAO.ndf", "HFSMP_DATA6" = "R:\HFSMP\Data\HFSMP_DATA6_REMEDIACAO.ndf", "HFSMP_DATA7" = "R:\HFSMP\Data\HFSMP_DATA7_REMEDIACAO.ndf", "HFSMP_DATA8" = "R:\HFSMP\Data\HFSMP_DATA8_REMEDIACAO.ndf", "HFSMP_DATA9" = "R:\HFSMP\Data\HFSMP_DATA9.ndf", "HFSMP_log" = "R:\HFSMP\Log\HFSMP_log.ldf" " -t "sat jun 10 23:17:13 2023" "MSSQL:HFSMP"
 
 Acessar o servidor de destino, abrir um prompt de comando(Adm) e executar o codigo resultante
 */

drop table #files
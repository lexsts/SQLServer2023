sqlcmd -S [server] -d [database] -U [usuario] -P [senha] -i [script.sql] -o [log.txt]

bcp TESTE.dbo.updatec3 in "C:\spool\updates.sql" -c -T -S SAOSHDBD0051 > C:\spool\updateC3_01.log

sqlcmd -S SAOSHDBD0051 -d master -U sa -P lamina -i atualiza.sql -o atualiza.log
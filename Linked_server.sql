SELECT 'Linked Server: ' + name + ' - Inst�ncia: ' + data_source + '- Base: ' + catalog
FROM sys.servers
WHERE is_linked = 1
AND CATALOG IS NOT NULL
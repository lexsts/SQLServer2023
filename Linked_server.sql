SELECT 'Linked Server: ' + name + ' - Instância: ' + data_source + '- Base: ' + catalog
FROM sys.servers
WHERE is_linked = 1
AND CATALOG IS NOT NULL
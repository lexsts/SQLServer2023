SELECT 'sp_change_users_login '+'''Update_one'''+','''+NAME+''','''+NAME+''';' FROM SYS.SYSUSERS
WHERE NAME NOT LIKE 'DB_%'
AND NAME NOT IN ('SYS','GUEST','PUBLIC');
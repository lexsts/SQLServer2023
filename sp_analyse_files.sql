exec sp_analyse_files

/*
exec sp_analyse_files_ex 'G:\'

use SMS_S02
    go
    dbcc shrinkfile (SMS_S02_log,1024) 

SP_FIXEDDRIVES_EX
*/
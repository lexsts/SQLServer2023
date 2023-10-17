SELECT B.NAME, 
                A.DBID, 
                A.STATUS, 
                A.LOGINAME, 
                A.NT_USERNAME, 
                A.HOSTNAME, 
                A.PROGRAM_NAME, 
                A.CMD, 
                A.LOGIN_TIME, 
                A.LAST_BATCH, 
                B.CRDATE 
  FROM SYSPROCESSES A, 
           SYSDATABASES B 
 WHERE A.DBID = B.DBID 
   --AND A.STATUS NOT IN ('sleeping') 
ORDER BY B.NAME, A.LOGINAME; 

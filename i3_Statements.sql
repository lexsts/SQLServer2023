USE I3
GO

with intab as (
SELECT   CONVERT(DATETIME,CONVERT(VARCHAR, SQSE_TIMESTAMP, 10),10)  c6
			, SQSE_PROGRAM_ID 
			, SQSE_LOGIN_ID 
			, SQSE_MACHINE_ID 
			, SUBSTRING(STMT_TXT.SQBX_BATCH_TEXT , SQSM_STATEMENT_OFFSET+1 	, case when SQSM_STATEMENT_LENGTH < 1000 then SQSM_STATEMENT_LENGTH else 1000 end) c4
			, SQSE_DATABASE_ID 
		FROM 
			  PW_SQBX_BATCH_TEXT STMT_TXT
			, PW_SQSM_STATEMENTS
			, PW_SQLN_LOGIN_NAMES_N
			, PS_INAP_APP_TIER
			, PS_INII_INSTANCE_APPTIER
			, PW_SQSE_SESSIONS_STMT_STATS_D
			, PS_INCE_INSTANCE
			, PW_SQUN_USER_NAMES_N
			, PW_SQDN_DATABASE_NAMES_N
			, PS_INEN_ENVIRONMENT
		WHERE SQSE_PWII_INSTANCE_ID = PS_INCE_INSTANCE.INCE_ID 
			AND INII_INAP_ID = INAP_ID 
			AND INII_INCE_ID = PS_INCE_INSTANCE.INCE_ID 
			AND INAP_INEN_ID=INEN_ID 
			AND SQSE_PWII_INSTANCE_ID = SQSM_PWII_INSTANCE_ID 
			AND SQSE_DATABASE_ID = SQDN_ID 
			AND SQDN_STRING_VALUE = SQSM_DATABASE_NAME 
			AND SQSE_USER_ID = SQUN_ID 
			AND SQUN_STRING_VALUE = SQSM_PARSING_USER 
			AND SQSE_STATEMENT_HV = SQSM_STATEMENT_HV 
			AND SQSM_BATCH_HV = STMT_TXT.SQBX_BATCH_HV 
			AND SQSE_PWII_INSTANCE_ID = PS_INCE_INSTANCE.INCE_ID 
			AND INCE_INTE_CODE='SQ' 
			AND INCE_DELETED='F' 
			AND INCE_NAME = 'BMFSB801CIFP\SQL1' -- NETWORKNAME da instancia
			AND SQSM_DATABASE_NAME = 'RP_ADA' -- NOME DO BANCO                               
			AND CONVERT(DATETIME,CONVERT(VARCHAR, SQSE_TIMESTAMP, 10),10)  > CONVERT (datetime, '2015-01-01 12:00:00', 120) 
			--AND SQSE_TIMESTAMP > '2014-01-01 12:00:00'
			AND SQSE_LOGIN_ID = SQLN_ID AND SQLN_ID <>0 
		GROUP BY SQDN_STRING_VALUE, 
			  SQSE_LOGIN_ID
			, SUBSTRING(STMT_TXT.SQBX_BATCH_TEXT , SQSM_STATEMENT_OFFSET+1 , case when SQSM_STATEMENT_LENGTH < 1000 then SQSM_STATEMENT_LENGTH else 1000 end)
			, SQSE_DATABASE_ID
			, SQSE_MACHINE_ID
			,  CONVERT(DATETIME,CONVERT(VARCHAR, SQSE_TIMESTAMP, 10),10) 
			, SQSE_PROGRAM_ID
			, SQLN_STRING_VALUE
	)


SELECT SQDN_STRING_VALUE as SQDatabase
, SQLN_STRING_VALUE as SQLogin
, intab.c6 as Date
, SQMN_STRING_VALUE as SQMachine
, SQPN_STRING_VALUE as SQProgram
, intab.c4 as SQStatementText
FROM 
  intab 
, PW_SQMN_MACHINE_NAMES_N
, PW_SQLN_LOGIN_NAMES_N
, PW_SQPN_PROGRAM_NAMES_N
, PW_SQDN_DATABASE_NAMES_N
WHERE SQSE_DATABASE_ID = SQDN_ID 
AND SQDN_ID <>0 
AND SQSE_LOGIN_ID = SQLN_ID 
AND SQLN_ID <>0 
AND SQSE_MACHINE_ID = SQMN_ID 
AND SQMN_ID <>0 
AND SQSE_PROGRAM_ID = SQPN_ID 
AND SQPN_ID <>0
--ORDER BY "SQDatabase" asc, "Date" asc
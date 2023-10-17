--Command to stop the xevent session
ALTER EVENT SESSION [telemetry_xevents] ON SERVER STATE = stop;
     
--Command to start the xevent session
ALTER EVENT SESSION [telemetry_xevents] ON SERVER STATE = start;



Go to Start > Programs > Select SQL Server 2016 Error and Usage Reporting
Unselect “Send Windows Error and SQL Error Reports…”
Unselect “Send Feature Usage Reports…”
Click on the options, make sure all components are unselected
Click OK
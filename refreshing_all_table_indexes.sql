/*
You should rebuild your indexes whose fragmentation ratio is greater than 30%;
I recommend that you reorganize your indexes that are between 10% and 30%.
*/


select * from sys.dm_db_index_physical_stats (DB_ID(),null,null,null,'LIMITED') WHERE avg_fragmentation_in_percent >10.0 and index_id>0


/*Create Function.*/
CREATE FUNCTION dbo.index_name (@object_id int, @index_id int)
RETURNS sysname
AS
BEGIN
RETURN(SELECT name FROM sys.indexes WHERE
 
 object_id = @object_id and index_id = @index_id)
END;
GO




/*After the function is created, it is selected in this way and index corruption rates are read..*/
SELECT
OBJECT_NAME(object_id) AS tabloadi
,dbo.index_name(object_id, index_id) AS indexadi
,avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL)
WHERE avg_fragmentation_in_percent > 20
AND index_type_desc IN('CLUSTERED INDEX', 'NONCLUSTERED INDEX')



/*Refreshes all indexes in the database*/
DECLARE @Database VARCHAR(255)
DECLARE @Table VARCHAR(255)
DECLARE @cmd NVARCHAR(500)
DECLARE @fillfactor INT
 
SET @fillfactor = 90
 
DECLARE DatabaseCursor CURSOR FOR
SELECT name FROM MASTER.dbo.sysdatabases
WHERE name NOT IN ('master','msdb','tempdb','model','distribution')
ORDER BY 1
 
OPEN DatabaseCursor
 
FETCH NEXT FROM DatabaseCursor INTO @Database
WHILE @@FETCH_STATUS = 0
BEGIN
 
SET @cmd = 'DECLARE TableCursor CURSOR FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +
table_name + '']'' as tableName FROM ' + @Database + '.INFORMATION_SCHEMA.TABLES
WHERE table_type = ''BASE TABLE'''
 
/* create table cursor  */
EXEC (@cmd)
OPEN TableCursor
 
FETCH NEXT FROM TableCursor INTO @Table
WHILE @@FETCH_STATUS = 0
BEGIN
 
IF (@@MICROSOFTVERSION / POWER(2, 24) >= 9)
BEGIN

SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'
EXEC (@cmd)
END
ELSE
BEGIN

DBCC DBREINDEX(@Table,' ',@fillfactor)
END
 
FETCH NEXT FROM TableCursor INTO @Table
END
 
CLOSE TableCursor
DEALLOCATE TableCursor
 
FETCH NEXT FROM DatabaseCursor INTO @Database
END
CLOSE DatabaseCursor
DEALLOCATE DatabaseCursor

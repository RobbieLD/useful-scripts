

DECLARE @TableName as NVARCHAR(255)
DECLARE @SQL as NVARCHAR(255)
DECLARE Shadow_Cursor CURSOR FOR
	SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME LIKE '%_Test';
OPEN Shadow_Cursor;
FETCH NEXT FROM Shadow_Cursor INTO @TableName;  
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'select ''' + @TableName + ''' as TableName , count(1) as Count from ' + @TableName
	EXECUTE sp_executesql @Sql
	FETCH NEXT FROM Shadow_Cursor INTO @TableName;
END;  
CLOSE Shadow_Cursor;
DEALLOCATE Shadow_Cursor; 
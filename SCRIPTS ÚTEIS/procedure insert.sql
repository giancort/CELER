CREATE PROC [dbo].[InsertGenerator]
(
@schemaName varchar(100)
,@tableName varchar(100)
,@IncludePrimaryKeyIdentity bit=0
,@IncludeNonPrimaryKeyIdentity bit=1
,@IncludeIfNotExists bit=0		
) 
AS

DECLARE @string nvarchar(MAX) --for storing the first half of INSERT statement
DECLARE @stringData nvarchar(MAX) --for storing the data (VALUES) related statement
DECLARE @dataType nvarchar(1000) --data types returned for respective columns
DECLARE @IfNotExistsString nvarchar(MAX) --for storing the NOT EXISTS string and be concatenated on each loop
DECLARE @IdentityExists bit -- flag to see if need to turn on IDENTITY_INSERT"
	
--Declare a cursor to retrieve column specific information for the specified table
DECLARE cursCol CURSOR FAST_FORWARD FOR 
	SELECT column_name,data_type 
	FROM information_schema.columns 
	WHERE table_name = @tableName AND Table_Schema=@schemaName
	AND column_name NOT IN ('InsertedOn')--Used to exclude any columns that may be standard to exclude.  For Example a default timestamp field.
OPEN cursCol
	
	SET @string='INSERT ['+@schemaName+'].['+@tableName+']('
	SET @stringData=''
	SET @IfNotExistsString='''IF NOT EXISTS(SELECT 1 FROM ['+@schemaName+'].['+@tableName+'] WHERE '

	DECLARE @colName nvarchar(50)

FETCH NEXT FROM cursCol INTO @colName,@dataType

IF @@fetch_status<>0
	begin
	print 'Table '+@schemaName+'.'+@tableName+' not found, processing skipped.'
	close curscol
	deallocate curscol
	return
END

WHILE @@FETCH_STATUS=0
BEGIN

IF (
		(	
			--IF NOT IDENTITY THEN PROCESS
			EXISTS
				(
				SELECT * FROM sys.columns a
				INNER JOIN sys.tables b on a.object_id=b.object_id
				--LEFT JOIN sys.index_columns c ON c.object_id=b.object_id and a.column_id=c.column_id
				--LEFT JOIN sys.key_constraints d ON c.object_id=d.parent_object_id
				--							AND c.index_id = d.unique_index_id 
				WHERE 
				a.Is_Identity<>1
				AND b.object_id=Object_id(@schemaName+'.'+@tableName)
				AND a.name=@colName
				)
		)
	OR 
		(
			--IF PRIMARY KEY AND @IncludePrimaryKeyIdentity =1 THEN PROCESS IT
			EXISTS
				(
				SELECT * FROM sys.columns a
				INNER JOIN sys.tables b on a.object_id=b.object_id
				INNER JOIN sys.index_columns c ON c.object_id=b.object_id and a.column_id=c.column_id
				INNER JOIN sys.key_constraints d ON c.object_id=d.parent_object_id
											AND c.index_id = d.unique_index_id 
				WHERE a.Is_Identity=1
				AND b.object_id=Object_id(@schemaName+'.'+@tableName)
				AND a.name=@colName
				) 
			AND @IncludePrimaryKeyIdentity=1
		)
	OR 
		(
			--IF IDENTITY COLUMN (Not-Primary key) and @IncludeNonPrimaryKeyIdentity=1 THEN PROCESS IT
			EXISTS
				(
				SELECT * FROM sys.columns a
				INNER JOIN sys.tables b on a.object_id=b.object_id
				LEFT JOIN sys.index_columns c ON c.object_id=b.object_id and a.column_id=c.column_id
				LEFT JOIN sys.key_constraints d ON c.object_id=d.parent_object_id
											AND c.index_id = d.unique_index_id 
				WHERE d.parent_object_id IS NULL
				AND a.Is_Identity=1
				AND b.object_id=Object_id(@schemaName+'.'+@tableName)
				AND a.name=@colName
				) 
			AND @IncludeNonPrimaryKeyIdentity=1
			
		)
	)
	BEGIN	
		
	IF (
		(
			--IF PRIMARY KEY AND @IncludePrimaryKeyIdentity =1 THEN PROCESS IT
			EXISTS
				(
				SELECT * FROM sys.columns a
				INNER JOIN sys.tables b on a.object_id=b.object_id
				INNER JOIN sys.index_columns c ON c.object_id=b.object_id and a.column_id=c.column_id
				INNER JOIN sys.key_constraints d ON c.object_id=d.parent_object_id
											AND c.index_id = d.unique_index_id 
				WHERE a.Is_Identity=1
				AND b.object_id=Object_id(@schemaName+'.'+@tableName)
				AND a.name=@colName
				) 
			AND @IncludePrimaryKeyIdentity=1
		)
	OR 
		(
			--IF IDENTITY COLUMN (Not-Primary key) and @IncludeNonPrimaryKeyIdentity=1 THEN PROCESS IT
			EXISTS
				(
				SELECT * FROM sys.columns a
				INNER JOIN sys.tables b on a.object_id=b.object_id
				LEFT JOIN sys.index_columns c ON c.object_id=b.object_id and a.column_id=c.column_id
				LEFT JOIN sys.key_constraints d ON c.object_id=d.parent_object_id
											AND c.index_id = d.unique_index_id 
				WHERE d.parent_object_id IS NULL
				AND a.Is_Identity=1
				AND b.object_id=Object_id(@schemaName+'.'+@tableName)
				AND a.name=@colName
				) 
			AND @IncludeNonPrimaryKeyIdentity=1
			
		)
	)
		BEGIN
			SET @IdentityExists=1
		END
			
		IF @dataType in ('varchar','char','nchar','nvarchar')
		BEGIN
			SET @stringData=@stringData+''''+'''+isnull('''''+'''''+REPLACE(['+@colName+'],'''''''','''''''''''')+'''''+''''',''NULL'')+'',''+'
			SET @IfNotExistsString=@IfNotExistsString+'['+@colName+']='+'''+isnull('''''+'''''+REPLACE(['+@colName+'],'''''''','''''''''''')+'''''+''''',''NULL'')+'' and ''+'''
			
		--PRINT @stringData
		END
		ELSE 
		IF @dataType IN ('datetime','smalldatetime','date','datetime2','time')
		BEGIN
			SET @stringData=@stringData+'''convert(datetime,'+'''+isnull('''''+'''''+convert(varchar(200),'+@colName+',121)+'''''+''''',''NULL'')+'',121),''+'
		  	SET @IfNotExistsString=@IfNotExistsString+'['+@colName+']='+'''+isnull('''''+'''''+CONVERT(VARCHAR(30),['+@colName+'],121)+'''''+''''',''NULL'')+'' and ''+'''
		END
		ELSE 
		IF @dataType IN ('tinyint','smallint','int','money','bit','decimal','numeric','smallmoney','bigint') 
		BEGIN
			SET @stringData=@stringData+''''+'''+isnull('''''+'''''+convert(varchar(200),'+@colName+')+'''''+''''',''NULL'')+'',''+'
			SET @IfNotExistsString=@IfNotExistsString+'['+@colName+']='+'''+isnull('''''+'''''+convert(varchar(200),'+@colName+')+'''''+''''',''NULL'')+'' and ''+'''
		END
		ELSE
		RAISERROR ('There is a datatype present in the table that is not accounted for in the procedure',16,1)
		--BUILD COLUMN LIST
		SET @string=@string+'['+@colName+'],'
		
	END
FETCH NEXT FROM cursCol INTO @colName,@dataType
END

CLOSE cursCol
DEALLOCATE cursCol

 
--REMOVE ENDING "AND" FROM LINE AND ADD ENDING PARENTHESIS TO CLOSE OUT "IF NOT EXISTS" STATEMENT
SET @IfNotExistsString = LEFT(@IfNotExistsString,LEN(@IfNotExistsString)-10)
SET @IfNotExistsString = @IfNotExistsString +'+'')'''
----------------------------------------------------------------------------------------------------
 
DECLARE @Query nvarchar(4000)

IF @IncludeIfNotExists = 1 AND @IdentityExists=1
	BEGIN
		SET @query ='SELECT ''SET IDENTITY_INSERT ['+@schemaName+'].['+@tableName+'] ON'' UNION ALL SELECT  REPLACE('+@IfNotExistsString+'+'''+substring(@string,0,len(@string)) + ') VALUES(''+ ' + substring(@stringData,0,len(@stringData)-2)+'''+'')'',''=NULL'','' IS NULL'')+CHAR(13)+CHAR(10) FROM ['+@schemaName+'].['+@tableName+'] UNION ALL SELECT ''SET IDENTITY_INSERT ['+@schemaName+'].['+@tableName+'] OFF'''
	END
ELSE IF @IncludeIfNotExists = 1
	BEGIN 
		SET @query ='SELECT  REPLACE('+@IfNotExistsString+'+'''+substring(@string,0,len(@string)) + ') VALUES(''+ ' + substring(@stringData,0,len(@stringData)-2)+'''+'')'',''=NULL'','' IS NULL'')+CHAR(13)+CHAR(10) FROM ['+@schemaName+'].['+@tableName+']'
	END

IF @IncludeIfNotExists = 0 AND @IdentityExists=1
	BEGIN
		SET @query ='SELECT ''SET IDENTITY_INSERT ['+@schemaName+'].['+@tableName+'] ON'' UNION ALL SELECT  '''+substring(@string,0,len(@string)) + ') VALUES(''+ ' + substring(@stringData,0,len(@stringData)-2)+'''+'')'' FROM ['+@schemaName+'].['+@tableName+'] UNION ALL SELECT ''SET IDENTITY_INSERT ['+@schemaName+'].['+@tableName+'] OFF'''
	END
ELSE IF @IncludeIfNotExists = 0
	BEGIN
		SET @query ='SELECT  '''+substring(@string,0,len(@string)) + ') VALUES(''+ ' + substring(@stringData,0,len(@stringData)-2)+'''+'')'' FROM ['+@schemaName+'].['+@tableName+']'
	END
	
--PRINT @query

BEGIN TRY
	exec sp_executesql @query
END TRY

BEGIN CATCH
	RAISERROR ('Unexpected error occured while trying to generate the insert script.',16,1)
	PRINT 'Error Message: '+ERROR_MESSAGE()
	PRINT 'Error Line: '+CONVERT(VARCHAR(20),ERROR_LINE())
	PRINT 'Error Number: '+CONVERT(VARCHAR(20),ERROR_NUMBER())
END CATCH
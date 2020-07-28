  
  DECLARE @TABLENAME VARCHAR(100) = 'PROFILE_ACCESS'
  	DECLARE @INSERTSQL VARCHAR(MAX) = ''
	DECLARE @QUERY NVARCHAR(MAX) = ''
  
  SET @INSERTSQL = CONCAT(@INSERTSQL, '''',  CONCAT('INSERT INTO ', @TABLENAME, ' ( ',
  (SELECT SUBSTRING(
	  (
		  SELECT ',[' + [name] + ']' AS 'data()' 
		  FROM sys.columns WHERE object_id = object_id(@TABLENAME)
		  for XML PATH('')
	  ), 2, 9999
  ))
  , ' ) VALUES ( '), '''')

	SET @QUERY = CONCAT('SELECT CONCAT(', @INSERTSQL, ',',
		  (SELECT SUBSTRING(
			  (
				  SELECT ', '','' + ( CASE WHEN [' + [name] + '] IS NOT NULL THEN CONCAT('''''''', CAST([' + [name] + '] AS VARCHAR(200)), '''''''') ELSE ''NULL'' END) ' AS 'data()' 
				  FROM sys.columns WHERE object_id = object_id(@TABLENAME)
				  for XML PATH('')
			  ), 9, 9999
		  ))
	  , ', '')'') FROM ', @TABLENAME
		,'');


		--SELECT @QUERY

exec sp_executesql @QUERY


--select * from PLAN_TAX_AFFILIATOR


--SELECT * from ROUTE_ACQUIRER


--select * from DOC_TYPES
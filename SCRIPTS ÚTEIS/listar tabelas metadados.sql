SELECT
   SCHEMA_NAME(tbl.schema_id) AS SchemaName,	
   tbl.name AS TableName, 
   --clmns.name AS ColumnName,
   p.name AS ExtendedPropertyName,
   CAST(p.value AS sql_variant) AS ExtendedPropertyValue
FROM
   sys.tables AS tbl
   --JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id
   JOIN sys.extended_properties AS p ON p.major_id=tbl.object_id --AND p.minor_id=clmns.column_id --AND p.class=1
WHERE
   SCHEMA_NAME(tbl.schema_id)='dbo'
   --and tbl.name='SITUATION' 
   and 
   P.name='METADATA'
   --and p.name='METADATA'

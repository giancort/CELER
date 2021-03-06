UPDATE ROUTE_ACQUIRER
SET ACTIVE = 0
FROM ROUTE_ACQUIRER ra
INNER JOIN EQUIPMENT e
	ON ra.COD_EQUIP = e.COD_EQUIP
WHERE e.SERIAL IN
(
'68977762',
'68873563',
'6G260559',
'6G173927'
)
GO
INSERT INTO ROUTE_ACQUIRER (CREATED_AT, COD_COMP, COD_EQUIP, COD_USER, ACTIVE, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
SELECT
	CREATED_AT
   ,COD_COMP
   ,(SELECT COD_EQUIP FROM EQUIPMENT e WHERE e.SERIAL = '6G333627')
   ,COD_USER
   ,ACTIVE
   ,CONF_TYPE
   ,COD_BRAND
   ,COD_AC
   ,COD_SOURCE_TRAN
FROM ROUTE_ACQUIRER ra
WHERE ra.COD_EQUIP = 40753
AND ra.ACTIVE = 1
AND ra.COD_AC = 26
GO

EXEC SP_LOAD_TABLES_EQUIP 30691

SELECT * FROM ROUTE_ACQUIRER ra WHERE ra.COD_AC = 30691


SELECT * FROM ROUTE_ACQUIRER ra
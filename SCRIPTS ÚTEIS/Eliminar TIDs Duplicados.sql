	DECLARE @QTD INT;
	DECLARE @COD_EQUIP INT;
	DECLARE @COD_AC INT;
	DECLARE @DUPLICATED_TIDS AS CURSOR;
	DECLARE @SERIAL_NEW_TID AS CURSOR;

	DECLARE @COD_DAT_EQUIP_AC INT;

--  Cria um Cursor = retorna os TIDs repetidos X quantidade

SET @DUPLICATED_TIDS = CURSOR FOR SELECT
	COUNT(*)	
   ,COD_EQUIP
   ,COD_AC
FROM DATA_EQUIPMENT_AC
WHERE COD_AC IN (SELECT
		COD_AC
	FROM ACQUIRER
	WHERE [GROUP] = 'PAGSEGURO')
AND ACTIVE = 1
GROUP BY COD_EQUIP
		,COD_AC
HAVING COUNT(CODE) > 1;

OPEN @DUPLICATED_TIDS;

FETCH NEXT FROM @DUPLICATED_TIDS INTO @QTD, @COD_EQUIP, @COD_AC;

WHILE @@fetch_status = 0
BEGIN

	UPDATE DATA_EQUIPMENT_AC SET ACTIVE = 0 WHERE COD_DAT_EQUIP_AC IN (SELECT TOP (@QTD - 1) COD_DAT_EQUIP_AC FROM DATA_EQUIPMENT_AC WHERE COD_EQUIP = @COD_EQUIP AND ACTIVE = 1 AND COD_AC = @COD_AC);	
	FETCH NEXT FROM @DUPLICATED_TIDS INTO @QTD, @COD_EQUIP, @COD_AC;
END; 



DECLARE @COD_EQUIP INT;
DECLARE @COD_AC_CORRECT INT;
DECLARE @COD_AC_INCORRECT INT;
DECLARE @TID_INCORRECT varchar(100);
DECLARE @TID_CORRECT VARCHAR(100);
DECLARE @COD_DATA_TID_AVAILABLE_EC INT;
DECLARE @COD_AC_ROUTE INT;
DECLARE @CURSOR_EQUIPMENTS AS CURSOR;

SET @CURSOR_EQUIPMENTS = CURSOR FOR SELECT DISTINCT --TOP 43
	ACQUIRER.COD_AC AS COD_AC_CORRECT
   ,EQUIPMENT.COD_EQUIP
   ,DATA_EQUIPMENT_AC.COD_AC AS COD_AC_INCORRECT
   ,DATA_EQUIPMENT_AC.CODE AS TID_INCORRECT
   ,ACQUIRER_ROUTE.COD_AC AS COD_AC_ROUTE
FROM COMMERCIAL_ESTABLISHMENT
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
INNER JOIN SEGMENTS_GROUP
	ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
INNER JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
INNER JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP
INNER JOIN ROUTE_ACQUIRER
	ON ROUTE_ACQUIRER.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
	AND ROUTE_ACQUIRER.ACTIVE = 1
INNER JOIN ACQUIRER AS ACQUIRER_ROUTE
	ON ACQUIRER_ROUTE.COD_AC = ROUTE_ACQUIRER.COD_AC
	AND ACQUIRER_ROUTE.SUBTITLE = ACQUIRER.SUBTITLE
	AND ACQUIRER_ROUTE.COD_AC <> ACQUIRER.COD_AC
INNER JOIN ACQUIRER AS ACQUIRER_TID
	ON ACQUIRER_TID.COD_AC = ROUTE_ACQUIRER.COD_AC
	AND ACQUIRER_TID.SUBTITLE = ACQUIRER.SUBTITLE
	AND ACQUIRER_TID.COD_AC <> ACQUIRER.COD_AC
INNER JOIN DATA_EQUIPMENT_AC
	ON (DATA_EQUIPMENT_AC.COD_AC = ACQUIRER.COD_AC
	OR DATA_EQUIPMENT_AC.COD_AC = ACQUIRER_ROUTE.COD_AC
	OR DATA_EQUIPMENT_AC.COD_AC = ACQUIRER_TID.COD_AC
	)
	AND DATA_EQUIPMENT_AC.ACTIVE = 1
	AND DATA_EQUIPMENT_AC.COD_EQUIP = EQUIPMENT.COD_EQUIP
WHERE ASS_DEPTO_EQUIP.ACTIVE = 1
AND SEGMENTS_GROUP.ACTIVE = 1;

OPEN @CURSOR_EQUIPMENTS;

FETCH NEXT FROM @CURSOR_EQUIPMENTS INTO @COD_AC_CORRECT, @COD_EQUIP, @COD_AC_INCORRECT, @TID_INCORRECT, @COD_AC_ROUTE;

WHILE @@fetch_status = 0
BEGIN
	IF (@COD_AC_CORRECT <> @COD_AC_INCORRECT)
	BEGIN
	--INATIVA O TID DE SEGMENTO INCORRETO
	UPDATE DATA_EQUIPMENT_AC
	SET ACTIVE = 0
	WHERE COD_AC = @COD_AC_INCORRECT
	AND COD_EQUIP = @COD_EQUIP
	AND ACTIVE = 1;
	UPDATE DATA_TID_AVAILABLE_EC
	SET AVAILABLE = 1
	   ,ACTIVE = 1
	   ,COD_EC = NULL
	WHERE COD_AC = @COD_AC_INCORRECT
	AND TID = @TID_INCORRECT;

	SELECT TOP 1
		@COD_DATA_TID_AVAILABLE_EC = COD_DATA_EQUIP
	   ,@TID_CORRECT = DATA_TID_AVAILABLE_EC.TID
	FROM DATA_TID_AVAILABLE_EC
	WHERE COD_AC = @COD_AC_CORRECT
	AND AVAILABLE = 1
	AND ACTIVE = 1;

	INSERT INTO DATA_EQUIPMENT_AC ([CREATED_AT], COD_EQUIP, COD_COMP, COD_AC, NAME, CODE, ACTIVE)
		VALUES (current_timestamp, @COD_EQUIP, 8, @COD_AC_CORRECT, 'TID', @TID_CORRECT, 1);
	UPDATE DATA_TID_AVAILABLE_EC
	SET AVAILABLE = 0
	WHERE COD_DATA_EQUIP = @COD_DATA_TID_AVAILABLE_EC;
END;
SELECT
	CREATED_AT
   ,COD_EQUIP AS COD_EQUIP
   ,COD_USER
   ,ACTIVE
   ,CONF_TYPE
   ,COD_BRAND
   ,COD_AC AS COD_AC_CORRECT
   ,COD_SOURCE_TRAN INTO #ROUTE_ACQUIRER_CORRECT
FROM ROUTE_ACQUIRER
WHERE COD_EQUIP = @COD_EQUIP
AND ROUTE_ACQUIRER.COD_AC = @COD_AC_ROUTE
AND ACTIVE = 1;

UPDATE ROUTE_ACQUIRER
SET ACTIVE = 0
WHERE COD_EQUIP = @COD_EQUIP
AND ACTIVE = 1;

INSERT INTO ROUTE_ACQUIRER_HIST (CREATED_AT
, COD_EQUIP
, COD_USER
, ACTIVE
, CONF_TYPE
, COD_BRAND
, COD_AC
, COD_SOURCE_TRAN)
	SELECT
		CREATED_AT
	   ,@COD_EQUIP
	   ,COD_USER
	   ,ACTIVE
	   ,CONF_TYPE
	   ,COD_BRAND
	   ,@COD_AC_CORRECT
	   ,COD_SOURCE_TRAN
	FROM #ROUTE_ACQUIRER_CORRECT;


INSERT INTO ROUTE_ACQUIRER (CREATED_AT
, COD_EQUIP
, COD_USER
, ACTIVE
, CONF_TYPE
, COD_BRAND
, COD_AC
, COD_SOURCE_TRAN)
	SELECT
		CREATED_AT
	   ,@COD_EQUIP
	   ,COD_USER
	   ,ACTIVE
	   ,CONF_TYPE
	   ,COD_BRAND
	   ,@COD_AC_CORRECT
	   ,COD_SOURCE_TRAN
	FROM #ROUTE_ACQUIRER_CORRECT;

	DROP TABLE #ROUTE_ACQUIRER_CORRECT;

FETCH NEXT FROM @CURSOR_EQUIPMENTS INTO @COD_AC_CORRECT, @COD_EQUIP, @COD_AC_INCORRECT, @TID_INCORRECT, @COD_AC_ROUTE;
END;

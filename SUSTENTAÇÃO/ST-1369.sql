
IF OBJECT_ID('[SP_REG_ROUTE_ACQ]') IS NOT NULL
	DROP PROCEDURE [SP_REG_ROUTE_ACQ];
GO
CREATE PROCEDURE [dbo].[SP_REG_ROUTE_ACQ] (@Routes TVP_REG_ROUTE_ACQ READONLY)
AS
BEGIN



	DECLARE @COD_AC INT;
	DECLARE @GROUP VARCHAR(200);
	SELECT
		@GROUP = ACQUIRER.[GROUP]
	   ,@COD_AC = ACQUIRER.COD_AC
	FROM @Routes [routes]
	INNER JOIN ACQUIRER
		ON ACQUIRER.COD_AC = [routes].COD_ACQ


	IF (@GROUP = 'PAGSEGURO')
	BEGIN
		SELECT
			@COD_AC =
			(CASE
				WHEN TYPE_ESTAB.CODE = 'PF' THEN 10
				ELSE ACQ_SEGMENT.COD_AC
			END)
		FROM @Routes AS R
		INNER JOIN EQUIPMENT
			ON EQUIPMENT.SERIAL = R.SERIAL
		INNER JOIN ASS_DEPTO_EQUIP
			ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
		INNER JOIN DEPARTMENTS_BRANCH
			ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
		INNER JOIN BRANCH_EC
			ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
		INNER JOIN COMMERCIAL_ESTABLISHMENT
			ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
		INNER JOIN SEGMENTS
			ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
		INNER JOIN SEGMENTS_GROUP
			ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
		LEFT JOIN ACQUIRER AS ACQ_SEGMENT
			ON ((SEGMENTS_GROUP.COD_SEG_GROUP = ACQ_SEGMENT.COD_SEG_GROUP)
					OR ACQ_SEGMENT.COD_SEG_GROUP IS NULL)
		INNER JOIN TYPE_ESTAB
			ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB
		WHERE ASS_DEPTO_EQUIP.ACTIVE = 1
		AND ACQ_SEGMENT.[GROUP] = R.GROUP_ACQ
		AND ACQ_SEGMENT.LOGICAL_NUMBER = 1;
	END

	INSERT INTO ROUTE_ACQUIRER (COD_COMP, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			r.COD_COMP
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,r.COD_ACQ
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		WHERE r.CONF_TYPE = 4

	INSERT INTO ROUTE_ACQUIRER (COD_AFFILIATOR, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			r.COD_AFF
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,r.COD_ACQ
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		WHERE r.CONF_TYPE = 3

	INSERT INTO ROUTE_ACQUIRER (COD_EC, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			r.COD_EC
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,r.COD_ACQ
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		WHERE r.CONF_TYPE = 2

	INSERT INTO ROUTE_ACQUIRER (COD_EQUIP, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			eqp.COD_EQUIP
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,@COD_AC
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		JOIN EQUIPMENT eqp
			ON eqp.SERIAL = r.SERIAL
		WHERE r.CONF_TYPE = 1

	--------------------------------------------------------------------------------------------------        
	-- History Info        
	--------------------------------------------------------------------------------------------------        

	INSERT INTO [ROUTE_ACQUIRER_HIST] (COD_COMP, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			r.COD_COMP
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,r.COD_ACQ
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		WHERE r.CONF_TYPE = 4

	INSERT INTO [ROUTE_ACQUIRER_HIST] (COD_AFFILIATOR, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			r.COD_AFF
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,r.COD_ACQ
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		WHERE r.CONF_TYPE = 3

	INSERT INTO [ROUTE_ACQUIRER_HIST] (COD_EC, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			r.COD_EC
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,r.COD_ACQ
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		WHERE r.CONF_TYPE = 2

	INSERT INTO [ROUTE_ACQUIRER_HIST] (COD_EQUIP, COD_USER, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
		SELECT
			eqp.COD_EQUIP
		   ,r.COD_USER
		   ,r.CONF_TYPE
		   ,b.COD_BRAND
		   ,@COD_AC
		   ,r.COD_SOURCE
		FROM @Routes r
		JOIN BRAND b
			ON b.[GROUP] = r.BRAND_GROUP
				AND b.COD_TTYPE = r.COD_TTYPE
		JOIN EQUIPMENT eqp
			ON eqp.SERIAL = r.SERIAL
		WHERE r.CONF_TYPE = 1


END



GO
IF OBJECT_ID('SP_VAL_REG_ROUTE_ACQ') IS NOT NULL
	DROP PROCEDURE SP_VAL_REG_ROUTE_ACQ;
GO

CREATE PROCEDURE [SP_VAL_REG_ROUTE_ACQ] (@Routes TVP_REG_ROUTE_ACQ READONLY)
AS
BEGIN

	DECLARE @COD_AC INT;
	DECLARE @GROUP VARCHAR(200);

	CREATE TABLE #ERRORS (
		[Reason] VARCHAR(100)
	   ,COD_SEQ INT
	   ,[COD_ROUTE] INT
	   ,COD_AC INT
	   ,[Priority] INT
	);
	DECLARE @VALIDATE_ROUTES AS CURSOR
	SET @VALIDATE_ROUTES = CURSOR FOR SELECT
		ACQUIRER.COD_AC
	   ,ACQUIRER.[GROUP]
	FROM @Routes [routes]
	INNER JOIN ACQUIRER
		ON ACQUIRER.COD_AC = [routes].COD_ACQ

	OPEN @VALIDATE_ROUTES;

	FETCH NEXT FROM @VALIDATE_ROUTES INTO @COD_AC, @GROUP;

	WHILE @@fetch_status = 0
	BEGIN
	IF (@GROUP = 'PAGSEGURO')
	BEGIN

		SELECT
			@COD_AC =
			(CASE
				WHEN TYPE_ESTAB.CODE = 'PF' THEN 10
				ELSE ACQ_SEGMENT.COD_AC
			END)
		FROM @Routes AS R
		INNER JOIN EQUIPMENT
			ON EQUIPMENT.SERIAL = R.SERIAL
		INNER JOIN ASS_DEPTO_EQUIP
			ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
		INNER JOIN DEPARTMENTS_BRANCH
			ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
		INNER JOIN BRANCH_EC
			ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
		INNER JOIN COMMERCIAL_ESTABLISHMENT
			ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
		INNER JOIN SEGMENTS
			ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
		INNER JOIN SEGMENTS_GROUP
			ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
		LEFT JOIN ACQUIRER AS ACQ_SEGMENT
			ON ((SEGMENTS_GROUP.COD_SEG_GROUP = ACQ_SEGMENT.COD_SEG_GROUP)
					OR ACQ_SEGMENT.COD_SEG_GROUP IS NULL)
		INNER JOIN TYPE_ESTAB
			ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB
		WHERE ASS_DEPTO_EQUIP.ACTIVE = 1
		AND ACQ_SEGMENT.[GROUP] = R.GROUP_ACQ
		AND ACQ_SEGMENT.LOGICAL_NUMBER = 1;

		IF (SELECT
					COUNT(*)
				FROM @Routes R
				JOIN EQUIPMENT EQUIP
					ON EQUIP.SERIAL = R.SERIAL
					AND EQUIP.ACTIVE = 1
				JOIN DATA_EQUIPMENT_AC
					ON DATA_EQUIPMENT_AC.COD_EQUIP = EQUIP.COD_EQUIP
				WHERE COD_AC = @COD_AC
				AND DATA_EQUIPMENT_AC.ACTIVE = 1)
			= 0
		BEGIN

			INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
				SELECT
					'EQUIPAMENTO SEM TID DA PAGSEGURO'
				   ,r.COD_SEQ
				   ,0
				   ,ACQ.COD_AC
				   ,10
				FROM @Routes r
				JOIN ACQUIRER ACQ
					ON ACQ.COD_AC = @COD_AC
						AND ACQ.[GROUP] = 'Pagseguro'
				JOIN EQUIPMENT EQUIP
					ON EQUIP.SERIAL = r.SERIAL
						AND EQUIP.ACTIVE = 1

		END
	END
	INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
		SELECT
			'Rota j� Existe'
		   ,r.COD_SEQ
		   ,raq.[COD_ROUTE]
		   ,raq.COD_AC
		   ,10
		FROM @Routes r
		JOIN ROUTE_ACQUIRER raq
			ON raq.COD_COMP = r.COD_COMP
				AND raq.CONF_TYPE = r.CONF_TYPE
				AND raq.COD_SOURCE_TRAN = r.COD_SOURCE
				AND raq.ACTIVE = 1
		JOIN BRAND b
			ON b.COD_BRAND = raq.COD_BRAND
		WHERE r.CONF_TYPE = 4
		AND b.[GROUP] = r.BRAND_GROUP
		AND b.COD_TTYPE = r.COD_TTYPE

	INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
		SELECT
			'Rota j� Existe'
		   ,r.COD_SEQ
		   ,raq.[COD_ROUTE]
		   ,raq.COD_AC
		   ,10
		FROM @Routes r
		JOIN ROUTE_ACQUIRER raq
			ON raq.COD_AFFILIATOR = r.COD_AFF
				AND raq.CONF_TYPE = r.CONF_TYPE
				AND raq.COD_SOURCE_TRAN = r.COD_SOURCE
				AND raq.ACTIVE = 1
		JOIN BRAND b
			ON b.COD_BRAND = raq.COD_BRAND
		WHERE r.CONF_TYPE = 3
		AND b.[GROUP] = r.BRAND_GROUP
		AND b.COD_TTYPE = r.COD_TTYPE

	INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
		SELECT
			'Rota j� Existe'
		   ,r.COD_SEQ
		   ,raq.[COD_ROUTE]
		   ,raq.COD_AC
		   ,10
		FROM @Routes r
		JOIN ROUTE_ACQUIRER raq
			ON raq.COD_EC = r.COD_EC
				AND raq.CONF_TYPE = r.CONF_TYPE
				AND raq.COD_SOURCE_TRAN = r.COD_SOURCE
				AND raq.ACTIVE = 1
		JOIN BRAND b
			ON b.COD_BRAND = raq.COD_BRAND
		WHERE r.CONF_TYPE = 2
		AND b.[GROUP] = r.BRAND_GROUP
		AND b.COD_TTYPE = r.COD_TTYPE


	INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
		SELECT
			'Rota j� Existe'
		   ,r.COD_SEQ
		   ,raq.[COD_ROUTE]
		   ,raq.COD_AC
		   ,10
		FROM @Routes r
		JOIN EQUIPMENT eqp
			ON eqp.SERIAL = r.SERIAL
				AND eqp.ACTIVE = 1
		JOIN ROUTE_ACQUIRER raq
			ON raq.COD_EQUIP = eqp.COD_EQUIP
				AND raq.CONF_TYPE = r.CONF_TYPE
				AND raq.COD_SOURCE_TRAN = r.COD_SOURCE
				AND raq.ACTIVE = 1
		JOIN BRAND b
			ON b.COD_BRAND = raq.COD_BRAND
		WHERE r.CONF_TYPE = 1
		AND b.[GROUP] = r.BRAND_GROUP
		AND b.COD_TTYPE = r.COD_TTYPE

	INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
		SELECT
			'Serial n�o consta na base de dados'
		   ,r.COD_SEQ
		   ,0
		   ,0
		   ,1
		FROM @Routes r
		LEFT JOIN EQUIPMENT eqp
			ON eqp.SERIAL = r.SERIAL
				AND eqp.ACTIVE = 1
		WHERE r.CONF_TYPE = 1
		AND eqp.SERIAL IS NULL

	INSERT INTO #ERRORS (Reason, COD_SEQ, COD_ROUTE, COD_AC, Priority)
		SELECT
			'Produto indispon�vel para o adquirente'
		   ,r.COD_SEQ
		   ,0
		   ,0
		   ,1
		FROM @Routes r
		LEFT JOIN SOURCE_TRANSACTION st
			ON st.COD_SOURCE_TRAN = r.COD_SOURCE
		LEFT JOIN BRAND b
			ON b.COD_TTYPE = r.COD_TTYPE
				AND b.[GROUP] = r.BRAND_GROUP
				AND (b.AVAILABLE_ONLINE = 1
					OR st.[DESCRIPTION] != 'ONLINE')
		LEFT JOIN PRODUCTS_ACQUIRER pa
			ON pa.COD_AC = @COD_AC
				AND pa.COD_BRAND = b.COD_BRAND
		WHERE pa.COD_PR_ACQ IS NULL
	FETCH NEXT FROM @VALIDATE_ROUTES INTO @COD_AC, @GROUP;
	END


	SELECT
		Reason
	   ,COD_SEQ
	   ,COD_ROUTE
	   ,COD_AC
	   ,Priority
	FROM #ERRORS

END
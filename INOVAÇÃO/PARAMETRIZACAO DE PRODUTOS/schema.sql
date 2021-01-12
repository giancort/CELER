IF OBJECT_ID('PRODUCT_ACQUIRE_FILTER') IS NULL BEGIN
    CREATE TABLE PRODUCT_ACQUIRE_FILTER
    (
        COD_PRD_ACQ_FILTER INT IDENTITY NOT NULL PRIMARY KEY,
        COD_AFFILIATOR INT NULL REFERENCES AFFILIATOR,
        COD_EC INT NULL REFERENCES COMMERCIAL_ESTABLISHMENT, 
        COD_ASS_DEPTO_TERMINAL INT NULL REFERENCES ASS_DEPTO_EQUIP,
        COD_AC INT NULL REFERENCES ACQUIRER,
        COD_MODEL INT NULL REFERENCES EQUIPMENT_MODEL,
        COD_BRAND INT NULL REFERENCES BRAND,
        ONLINE INT NOT NULL DEFAULT(0),
        PRESENTIAL INT NOT NULL DEFAULT (0),
        DEBIT INT NOT NULL DEFAULT(0),
        CREDIT INT NOT NULL DEFAULT (0),
        CREDIT_INSTALLMENTS INT NOT NULL DEFAULT(0),
        CLIENT_INSTALLMENT INT NOT NULL DEFAULT (0),
        CLIENT_DEBIT INT NOT NULL DEFAULT(0),
        CLIENT_CREDIT INT NOT NULL DEFAULT(0),
        RATE_FREE INT NOT NULL DEFAULT (0),
        CREATED_AT DATETIME NOT NULL DEFAULT(GETDATE()),
        COD_USER INT NULL REFERENCES USERS
    )
END
GO

CREATE NONCLUSTERED INDEX IX_PRD_ACQ_FILTER_AF ON PRODUCT_ACQUIRE_FILTER (COD_AFFILIATOR, COD_AC, COD_MODEL, COD_BRAND)
GO
CREATE NONCLUSTERED INDEX IX_PRD_ACQ_FILTER_EC ON PRODUCT_ACQUIRE_FILTER (COD_EC, COD_AC, COD_MODEL, COD_BRAND)
GO
CREATE NONCLUSTERED INDEX IX_PRD_ACQ_FILTER_EQP ON PRODUCT_ACQUIRE_FILTER (COD_ASS_DEPTO_TERMINAL, COD_AC, COD_MODEL, COD_BRAND)
GO
CREATE NONCLUSTERED INDEX IX_PRD_ACQ_FILTER_SUB ON PRODUCT_ACQUIRE_FILTER (COD_AFFILIATOR, COD_EC, COD_ASS_DEPTO_TERMINAL, COD_AC, COD_MODEL, COD_BRAND)
GO

CREATE INDEX IX_RA_EC ON ROUTE_ACQUIRER (COD_EC, ACTIVE) INCLUDE (COD_BRAND, COD_SOURCE_TRAN, CONF_TYPE, COD_AC)
GO
CREATE INDEX IX_RA_AF ON ROUTE_ACQUIRER (COD_AFFILIATOR, ACTIVE) INCLUDE (COD_BRAND, COD_SOURCE_TRAN, CONF_TYPE, COD_AC)
GO
CREATE INDEX IX_RA_EQP ON ROUTE_ACQUIRER (COD_EQUIP, ACTIVE) INCLUDE (COD_BRAND, COD_SOURCE_TRAN, CONF_TYPE, COD_AC)
GO
CREATE INDEX IX_RA_COMP ON ROUTE_ACQUIRER (COD_COMP, ACTIVE) INCLUDE (COD_BRAND, COD_SOURCE_TRAN, CONF_TYPE, COD_AC)
GO

UPDATE PRODUCTS_ACQUIRER
SET PLOT_VALUE = 1
WHERE PLOT_VALUE = 2
AND CHARINDEX('� vista', NAME) > 0
GO

IF OBJECT_ID('SP_LOAD_TABLES_EQUIP') IS NOT NULL DROP PROCEDURE SP_LOAD_TABLES_EQUIP
GO
CREATE PROCEDURE [DBO].[SP_LOAD_TABLES_EQUIP]
(
    @TERMINALID INT
)
AS BEGIN

    DECLARE @COD_EC INT,
        @COD_AFF INT, 
        @COD_SUB INT, 
        @DATE_PLAN DATETIME, 
        @EQUIP_MODEL VARCHAR(100),
        @TODAY DATETIME = CAST(CONVERT(VARCHAR, GETDATE(), 101) AS DATETIME),
        @COD_DPTO_TERM INT;
--@TERMINALID INT = 19886;

WITH CTE_DATA
AS
(SELECT
		ISNULL(CE.COD_AFFILIATOR, 0) AS COD_AFFILIATOR
	   ,E.COD_COMP
	   ,BE.COD_EC
	   ,MAX(ATD.CREATED_AT) AS DATE_PLAN
	   ,E.COD_MODEL
	   ,ADE.COD_ASS_DEPTO_TERMINAL
	FROM ASS_DEPTO_EQUIP ADE
	JOIN EQUIPMENT E
		ON E.COD_EQUIP = ADE.COD_EQUIP
		AND E.ACTIVE = 1
	JOIN DEPARTMENTS_BRANCH DB
		ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
	JOIN BRANCH_EC BE
		ON BE.COD_BRANCH = DB.COD_BRANCH
	JOIN COMMERCIAL_ESTABLISHMENT CE
		ON BE.COD_EC = CE.COD_EC
	JOIN ASS_TAX_DEPART ATD
		ON DB.COD_DEPTO_BRANCH = ATD.COD_DEPTO_BRANCH
		AND ATD.ACTIVE = 1
	WHERE ADE.COD_EQUIP = @TERMINALID
	AND ADE.ACTIVE = 1
	GROUP BY E.COD_COMP
			,ISNULL(CE.COD_AFFILIATOR, 0)
			,BE.COD_EC
			,E.COD_EQUIP
			,E.COD_MODEL
			,ADE.COD_ASS_DEPTO_TERMINAL)
SELECT
	@COD_AFF = COD_AFFILIATOR
   ,@COD_SUB = COD_COMP
   ,@COD_EC = COD_EC
   ,@DATE_PLAN = IIF(DATE_PLAN > @TODAY, DATE_PLAN, @TODAY)
   ,@EQUIP_MODEL = COD_MODEL
   ,@COD_DPTO_TERM = COD_ASS_DEPTO_TERMINAL
FROM CTE_DATA;

SELECT
	COD_BRAND INTO #BRAND_EQP
FROM ROUTE_ACQUIRER
WHERE COD_EQUIP = @TERMINALID
AND ACTIVE = 1
AND COD_SOURCE_TRAN = 2

SELECT
	RA.COD_BRAND INTO #BRAND_EC
FROM ROUTE_ACQUIRER RA
LEFT JOIN #BRAND_EQP EQP
	ON EQP.COD_BRAND = RA.COD_BRAND
WHERE RA.COD_EC = @COD_EC
AND RA.ACTIVE = 1
AND EQP.COD_BRAND IS NULL

SELECT
	RA.COD_BRAND INTO #BRAND_AFF
FROM ROUTE_ACQUIRER RA
LEFT JOIN #BRAND_EQP EQP
	ON EQP.COD_BRAND = RA.COD_BRAND
LEFT JOIN #BRAND_EC EC
	ON EC.COD_BRAND = RA.COD_BRAND
WHERE RA.COD_AFFILIATOR = @COD_AFF
AND RA.ACTIVE = 1
AND EQP.COD_BRAND IS NULL
AND EC.COD_BRAND IS NULL

SELECT
	RA.COD_BRAND INTO #BRAND_SUB
FROM ROUTE_ACQUIRER RA
LEFT JOIN #BRAND_EQP EQP
	ON EQP.COD_BRAND = RA.COD_BRAND
LEFT JOIN #BRAND_EC EC
	ON EC.COD_BRAND = RA.COD_BRAND
LEFT JOIN #BRAND_AFF AF
	ON AF.COD_BRAND = RA.COD_BRAND
WHERE RA.COD_COMP = @COD_SUB
AND RA.ACTIVE = 1
AND EQP.COD_BRAND IS NULL
AND EC.COD_BRAND IS NULL
AND AF.COD_BRAND IS NULL

CREATE TABLE #ROUTES_TERMINAL (
	ACQUIRER_NAME VARCHAR(128)
   ,PRODUCT_ID INT
   ,PRODUCT_NAME VARCHAR(64)
   ,PRODUCT_EXT_CODE VARCHAR(64)
   ,TRAN_TYPE INT
   ,TRAN_TYPE_NAME VARCHAR(32)
   ,CODE_EC_ACQ VARCHAR(10)
   ,BRAND VARCHAR(64)
   ,CONF_TYPE INT
   ,IS_SIMULATED INT
   ,DATE_PLAN DATETIME
   ,COD_AC INT
   ,COD_BRAND INT
   ,DEBIT INT
   ,CREDIT INT
   ,CREDIT_INSTALLMENTS INT
   ,CLIENT_INSTALLMENT INT
   ,CLIENT_DEBIT INT
   ,CLIENT_CREDIT INT
   ,ONLINE INT
   ,PRESENTIAL INT
   ,RATE_FREE INT
)

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
	SELECT
		ACQUIRER.[GROUP] AS ACQUIRER_NAME
	   ,PA.COD_PR_ACQ AS PRODUCT_ID
	   ,PA.NAME AS PRODUCT_NAME
	   ,PA.EXTERNALCODE AS PRODUCT_EXT_CODE
	   ,[TT].COD_TTYPE AS TRAN_TYPE
	   ,[TT].NAME AS TRAN_TYPE_NAME
	   ,'0' AS CODE_EC_ACQ
	   ,B.NAME AS BRAND
	   ,RA.CONF_TYPE
	   ,PA.IS_SIMULATED
	   ,@DATE_PLAN AS DATE_PLAN
	   ,PA.COD_AC
	   ,B.COD_BRAND
	   ,IIF(PA.COD_TTYPE = 2 AND PA.IS_SIMULATED != 1, 1, NULL) DEBIT
	   ,IIF(PA.COD_TTYPE = 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT
	   ,IIF(PA.PLOT_VALUE > 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE > 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 2, 1, NULL) CLIENT_DEBIT
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_CREDIT
	   ,IIF(PA.COD_SOURCE_TRAN = 1, 1, NULL) ONLINE
	   ,IIF(PA.COD_SOURCE_TRAN = 2, 1, NULL) PRESENTIAL
	   ,IIF(CHARINDEX('SEM JUROS', PA.NAME) > 0, 1, NULL) RATE_FREE
	FROM #BRAND_SUB CTE_SUB
	INNER JOIN ROUTE_ACQUIRER RA
		ON RA.COD_BRAND = CTE_SUB.COD_BRAND
			AND RA.ACTIVE = 1
			AND RA.COD_SOURCE_TRAN = 2
			AND RA.COD_COMP = @COD_SUB
			AND RA.CONF_TYPE = 4
	INNER JOIN BRAND B
		ON B.COD_BRAND = CTE_SUB.COD_BRAND
	INNER JOIN [TRANSACTION_TYPE] TT
		ON [TT].COD_TTYPE = B.COD_TTYPE
	INNER JOIN ACQUIRER
		ON ACQUIRER.COD_AC = RA.COD_AC
	INNER JOIN PRODUCTS_ACQUIRER PA
		ON PA.COD_BRAND = CTE_SUB.COD_BRAND
			AND PA.COD_AC = RA.COD_AC
			AND PA.COD_SOURCE_TRAN = 2
			AND PA.VISIBLE = 1

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
	SELECT
		ACQUIRER.[GROUP] AS ACQUIRER_NAME
	   ,PA.COD_PR_ACQ AS PRODUCT_ID
	   ,PA.NAME AS PRODUCT_NAME
	   ,PA.EXTERNALCODE AS PRODUCT_EXT_CODE
	   ,[TT].COD_TTYPE AS TRAN_TYPE
	   ,[TT].NAME AS TRAN_TYPE_NAME
	   ,'0' AS CODE_EC_ACQ
	   ,B.NAME AS BRAND
	   ,RA.CONF_TYPE
	   ,PA.IS_SIMULATED
	   ,@DATE_PLAN AS DATE_PLAN
	   ,PA.COD_AC
	   ,B.COD_BRAND
	   ,IIF(PA.COD_TTYPE = 2 AND PA.IS_SIMULATED != 1, 1, NULL) DEBIT
	   ,IIF(PA.COD_TTYPE = 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT
	   ,IIF(PA.PLOT_VALUE > 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE > 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 2, 1, NULL) CLIENT_DEBIT
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_CREDIT
	   ,IIF(PA.COD_SOURCE_TRAN = 1, 1, NULL) ONLINE
	   ,IIF(PA.COD_SOURCE_TRAN = 2, 1, NULL) PRESENTIAL
	   ,IIF(CHARINDEX('SEM JUROS', PA.NAME) > 0, 1, NULL) RATE_FREE
	FROM #BRAND_AFF CTE_AFF
	INNER JOIN ROUTE_ACQUIRER RA
		ON RA.COD_BRAND = CTE_AFF.COD_BRAND
			AND RA.ACTIVE = 1
			AND RA.COD_SOURCE_TRAN = 2
			AND RA.COD_AFFILIATOR = @COD_AFF
			AND RA.CONF_TYPE = 3
	INNER JOIN BRAND B
		ON B.COD_BRAND = CTE_AFF.COD_BRAND
	INNER JOIN [TRANSACTION_TYPE] TT
		ON [TT].COD_TTYPE = B.COD_TTYPE
	INNER JOIN ACQUIRER
		ON ACQUIRER.COD_AC = RA.COD_AC
	INNER JOIN PRODUCTS_ACQUIRER PA
		ON PA.COD_BRAND = CTE_AFF.COD_BRAND
			AND PA.COD_AC = RA.COD_AC
			AND PA.COD_SOURCE_TRAN = 2
			AND PA.VISIBLE = 1

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
	SELECT
		ACQUIRER.[GROUP] AS ACQUIRER_NAME
	   ,PA.COD_PR_ACQ AS PRODUCT_ID
	   ,PA.NAME AS PRODUCT_NAME
	   ,PA.EXTERNALCODE AS PRODUCT_EXT_CODE
	   ,[TT].COD_TTYPE AS TRAN_TYPE
	   ,[TT].NAME AS TRAN_TYPE_NAME
	   ,'0' AS CODE_EC_ACQ
	   ,B.NAME AS BRAND
	   ,RA.CONF_TYPE
	   ,PA.IS_SIMULATED
	   ,@DATE_PLAN AS DATE_PLAN
	   ,PA.COD_AC
	   ,B.COD_BRAND
	   ,IIF(PA.COD_TTYPE = 2 AND PA.IS_SIMULATED != 1, 1, NULL) DEBIT
	   ,IIF(PA.COD_TTYPE = 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT
	   ,IIF(PA.PLOT_VALUE > 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE > 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 2, 1, NULL) CLIENT_DEBIT
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_CREDIT
	   ,IIF(PA.COD_SOURCE_TRAN = 1, 1, NULL) ONLINE
	   ,IIF(PA.COD_SOURCE_TRAN = 2, 1, NULL) PRESENTIAL
	   ,IIF(CHARINDEX('SEM JUROS', PA.NAME) > 0, 1, NULL) RATE_FREE
	FROM #BRAND_EC [CTE_EC]
	INNER JOIN ROUTE_ACQUIRER RA
		ON RA.COD_BRAND = [CTE_EC].COD_BRAND
			AND RA.ACTIVE = 1
			AND RA.COD_SOURCE_TRAN = 2
			AND RA.COD_EC = @COD_EC
			AND RA.CONF_TYPE = 2
	INNER JOIN BRAND B
		ON B.COD_BRAND = [CTE_EC].COD_BRAND
	INNER JOIN [TRANSACTION_TYPE] TT
		ON [TT].COD_TTYPE = B.COD_TTYPE
	INNER JOIN ACQUIRER
		ON ACQUIRER.COD_AC = RA.COD_AC
	INNER JOIN PRODUCTS_ACQUIRER PA
		ON PA.COD_BRAND = [CTE_EC].COD_BRAND
			AND PA.COD_AC = RA.COD_AC
			AND PA.COD_SOURCE_TRAN = 2
			AND PA.VISIBLE = 1

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
	SELECT
		ACQUIRER.[GROUP] AS ACQUIRER_NAME
	   ,PA.COD_PR_ACQ AS PRODUCT_ID
	   ,PA.NAME AS PRODUCT_NAME
	   ,PA.EXTERNALCODE AS PRODUCT_EXT_CODE
	   ,[TT].COD_TTYPE AS TRAN_TYPE
	   ,[TT].NAME AS TRAN_TYPE_NAME
	   ,'0' AS CODE_EC_ACQ
	   ,B.NAME AS BRAND
	   ,RA.CONF_TYPE
	   ,PA.IS_SIMULATED
	   ,@DATE_PLAN AS DATE_PLAN
	   ,PA.COD_AC
	   ,B.COD_BRAND
	   ,IIF(PA.COD_TTYPE = 2 AND PA.IS_SIMULATED != 1, 1, NULL) DEBIT
	   ,IIF(PA.COD_TTYPE = 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT
	   ,IIF(PA.PLOT_VALUE > 1 AND PA.IS_SIMULATED != 1, 1, NULL) CREDIT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE > 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_INSTALLMENTS
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 2, 1, NULL) CLIENT_DEBIT
	   ,IIF(PA.IS_SIMULATED = 1 AND PLOT_VALUE = 1 AND PA.COD_TTYPE = 1, 1, NULL) CLIENT_CREDIT
	   ,IIF(PA.COD_SOURCE_TRAN = 1, 1, NULL) ONLINE
	   ,IIF(PA.COD_SOURCE_TRAN = 2, 1, NULL) PRESENTIAL
	   ,IIF(CHARINDEX('SEM JUROS', PA.NAME) > 0, 1, NULL) RATE_FREE
	FROM #BRAND_EQP [CTE_EQUIP]
	INNER JOIN ROUTE_ACQUIRER RA
		ON RA.COD_BRAND = [CTE_EQUIP].COD_BRAND
			AND RA.ACTIVE = 1
			AND RA.COD_SOURCE_TRAN = 2
			AND RA.COD_EQUIP = @TERMINALID
			AND RA.CONF_TYPE = 1
	INNER JOIN BRAND B
		ON B.COD_BRAND = [CTE_EQUIP].COD_BRAND
	INNER JOIN [TRANSACTION_TYPE] TT
		ON [TT].COD_TTYPE = B.COD_TTYPE
	INNER JOIN ACQUIRER
		ON ACQUIRER.COD_AC = RA.COD_AC
	INNER JOIN PRODUCTS_ACQUIRER PA
		ON PA.COD_BRAND = [CTE_EQUIP].COD_BRAND
			AND PA.COD_AC = RA.COD_AC
			AND PA.COD_SOURCE_TRAN = 2
			AND PA.VISIBLE = 1

CREATE TABLE #TERMINAL_FILTER (
	COD_AC INT
   ,COD_MODEL INT
   ,COD_BRAND INT
   ,ONLINE INT
   ,PRESENTIAL INT
   ,CREDIT INT
   ,DEBIT INT
   ,CREDIT_INSTALLMENTS INT
   ,CLIENT_INSTALLMENT INT
   ,CLIENT_CREDIT INT
   ,CLIENT_DEBIT INT
   ,RATE_FREE INT
)

IF EXISTS (SELECT
			COD_PRD_ACQ_FILTER
		FROM PRODUCT_ACQUIRE_FILTER
		WHERE COD_ASS_DEPTO_TERMINAL = @COD_DPTO_TERM)
BEGIN
INSERT INTO #TERMINAL_FILTER (COD_AC, COD_MODEL, COD_BRAND, ONLINE, PRESENTIAL, CREDIT, DEBIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_CREDIT, CLIENT_DEBIT, RATE_FREE)
	SELECT
		COD_AC
	   ,COD_MODEL
	   ,COD_BRAND
	   ,ONLINE
	   ,PRESENTIAL
	   ,CREDIT
	   ,DEBIT
	   ,CREDIT_INSTALLMENTS
	   ,CLIENT_INSTALLMENT
	   ,CLIENT_CREDIT
	   ,CLIENT_DEBIT
	   ,RATE_FREE
	FROM PRODUCT_ACQUIRE_FILTER
	WHERE COD_ASS_DEPTO_TERMINAL = @COD_DPTO_TERM
END
ELSE
IF EXISTS (SELECT
			COD_PRD_ACQ_FILTER
		FROM PRODUCT_ACQUIRE_FILTER
		WHERE COD_EC = @COD_EC)
BEGIN
INSERT INTO #TERMINAL_FILTER (COD_AC, COD_MODEL, COD_BRAND, ONLINE, PRESENTIAL, CREDIT, DEBIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_CREDIT, CLIENT_DEBIT, RATE_FREE)
	SELECT
		COD_AC
	   ,COD_MODEL
	   ,COD_BRAND
	   ,ONLINE
	   ,PRESENTIAL
	   ,CREDIT
	   ,DEBIT
	   ,CREDIT_INSTALLMENTS
	   ,CLIENT_INSTALLMENT
	   ,CLIENT_CREDIT
	   ,CLIENT_DEBIT
	   ,RATE_FREE
	FROM PRODUCT_ACQUIRE_FILTER
	WHERE COD_EC = @COD_EC
END
ELSE
IF EXISTS (SELECT
			COD_PRD_ACQ_FILTER
		FROM PRODUCT_ACQUIRE_FILTER
		WHERE COD_AFFILIATOR = @COD_AFF)
BEGIN
INSERT INTO #TERMINAL_FILTER (COD_AC, COD_MODEL, COD_BRAND, ONLINE, PRESENTIAL, CREDIT, DEBIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_CREDIT, CLIENT_DEBIT, RATE_FREE)
	SELECT
		COD_AC
	   ,COD_MODEL
	   ,COD_BRAND
	   ,ONLINE
	   ,PRESENTIAL
	   ,CREDIT
	   ,DEBIT
	   ,CREDIT_INSTALLMENTS
	   ,CLIENT_INSTALLMENT
	   ,CLIENT_CREDIT
	   ,CLIENT_DEBIT
	   ,RATE_FREE
	FROM PRODUCT_ACQUIRE_FILTER
	WHERE COD_AFFILIATOR = @COD_AFF
END
ELSE
BEGIN
INSERT INTO #TERMINAL_FILTER (COD_AC, COD_MODEL, COD_BRAND, ONLINE, PRESENTIAL, CREDIT, DEBIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_CREDIT, CLIENT_DEBIT, RATE_FREE)
	SELECT
		COD_AC
	   ,COD_MODEL
	   ,COD_BRAND
	   ,ONLINE
	   ,PRESENTIAL
	   ,CREDIT
	   ,DEBIT
	   ,CREDIT_INSTALLMENTS
	   ,CLIENT_INSTALLMENT
	   ,CLIENT_CREDIT
	   ,CLIENT_DEBIT
	   ,RATE_FREE
	FROM PRODUCT_ACQUIRE_FILTER
	WHERE COD_AFFILIATOR IS NULL
	AND COD_EC IS NULL
	AND COD_ASS_DEPTO_TERMINAL IS NULL
END

DELETE RT
	FROM #ROUTES_TERMINAL RT
	JOIN #TERMINAL_FILTER PAF
		ON (PAF.COD_AC IS NULL
		OR PAF.COD_AC = RT.COD_AC)
		AND (PAF.COD_MODEL IS NULL
		OR PAF.COD_MODEL = @EQUIP_MODEL)
		AND (PAF.COD_BRAND IS NULL
		OR PAF.COD_BRAND = RT.COD_BRAND)
		AND (
		PAF.ONLINE = RT.ONLINE
		OR PAF.PRESENTIAL = RT.PRESENTIAL
		OR PAF.CREDIT = RT.CREDIT
		OR PAF.DEBIT = RT.DEBIT
		OR PAF.CREDIT_INSTALLMENTS = RT.CREDIT_INSTALLMENTS
		OR PAF.CLIENT_INSTALLMENT = RT.CLIENT_INSTALLMENT
		OR PAF.CLIENT_CREDIT = RT.CLIENT_CREDIT
		OR PAF.CLIENT_DEBIT = RT.CLIENT_DEBIT
		OR PAF.RATE_FREE = RT.RATE_FREE
		)

SELECT
	ACQUIRER_NAME
   ,PRODUCT_ID
   ,PRODUCT_NAME
   ,PRODUCT_EXT_CODE
   ,TRAN_TYPE
   ,TRAN_TYPE_NAME
   ,CODE_EC_ACQ
   ,BRAND
   ,CONF_TYPE
   ,IS_SIMULATED
   ,DATE_PLAN
FROM #ROUTES_TERMINAL

END;
GO

IF OBJECT_ID('SP_LS_SOURCE_TRANSACTION') IS NOT NULL
DROP PROCEDURE SP_LS_SOURCE_TRANSACTION
GO
CREATE PROCEDURE SP_LS_SOURCE_TRANSACTION
AS
BEGIN

SELECT
	COD_SOURCE_TRAN
   ,CODE
FROM SOURCE_TRANSACTION

END;
GO


IF OBJECT_ID('SP_LS_FILTER_PRDCT_ACQ') IS NOT NULL
DROP PROCEDURE SP_LS_FILTER_PRDCT_ACQ
GO
CREATE PROCEDURE SP_LS_FILTER_PRDCT_ACQ
(
    @COD_AFF INT = NULL,
    @COD_EC INT = NULL,
    @SERIAL VARCHAR(96) = NULL,
    @COD_AC INT = NULL,
    @COD_MODEL INT = NULL,
    @BRANDGROUP VARCHAR(64) = NULL,
    @ONLINE INT = 0,
    @PRESENTIAL INT = 0,
    @PAGE INT = 1,
    @PAGESIZE INT = 10,
    @SEARCH_TYPE INT = 1,
    @QtyRows INT OUTPUT
) AS BEGIN
SET NOCOUNT ON
SET ARITHABORT ON

    DECLARE @Skip INT = (@PAGE - 1) * @PAGESIZE;
    DECLARE @Sql NVARCHAR(MAX)

SET @Sql = ' 
    SELECT 
        COD_PRD_ACQ_FILTER
         , PAF.COD_AFFILIATOR
         , A.NAME AF_NAME
         , PAF.COD_EC
         , CE.NAME EC_NAME
         , PAF.COD_ASS_DEPTO_TERMINAL
         , E.SERIAL
         , PAF.COD_AC
         , ACQ.NAME ACQ_NAME
         , PAF.COD_MODEL
         , EM.CODIGO MODEL
         , CONCAT(B.[GROUP], '' '', TT.CODE)  BRAND_GROUP
         , PAF.ONLINE
         , PAF.PRESENTIAL
         , PAF.DEBIT
         , PAF.CREDIT
         , PAF.CREDIT_INSTALLMENTS
         , PAF.CLIENT_INSTALLMENT
         , PAF.CLIENT_DEBIT
         , PAF.CLIENT_CREDIT
         , PAF.RATE_FREE
    FROM PRODUCT_ACQUIRE_FILTER PAF 
    LEFT JOIN AFFILIATOR A ON A.COD_AFFILIATOR = PAF.COD_AFFILIATOR
    LEFT JOIN COMMERCIAL_ESTABLISHMENT CE ON CE.COD_EC = PAF.COD_EC
    LEFT JOIN ACQUIRER ACQ ON ACQ.COD_AC = PAF.COD_AC
    LEFT JOIN EQUIPMENT_MODEL EM ON EM.COD_MODEL = PAF.COD_MODEL
    LEFT JOIN BRAND B ON B.COD_BRAND = PAF.COD_BRAND
    LEFT JOIN TRANSACTION_TYPE TT ON TT.COD_TTYPE = B.COD_TTYPE
    LEFT JOIN ASS_DEPTO_EQUIP ADE on PAF.COD_ASS_DEPTO_TERMINAL = ADE.COD_ASS_DEPTO_TERMINAL
    LEFT JOIN EQUIPMENT E ON E.COD_EQUIP = ADE.COD_EQUIP
    WHERE '

    IF @COD_AFF IS NOT NULL BEGIN
SET @Sql = @Sql + ' PAF.COD_AFFILIATOR = @COD_AFF';
    END ELSE IF @SEARCH_TYPE = 2 BEGIN
SET @Sql = @Sql + ' PAF.COD_AFFILIATOR IS NOT NULL '
    END
    ELSE IF @COD_EC IS NOT NULL BEGIN
SET @Sql = @Sql + ' PAF.COD_EC = @COD_EC ';
    END ELSE IF @SEARCH_TYPE = 3 BEGIN
SET @Sql = @Sql + ' PAF.COD_EC IS NOT NULL '
    END
    ELSE IF @SERIAL IS NOT NULL BEGIN
SET @Sql = @Sql + ' E.SERIAL = @SERIAL '
    END ELSE IF @SEARCH_TYPE = 4 BEGIN
SET @Sql = @Sql + ' PAF.COD_ASS_DEPTO_TERMINAL IS NOT NULL '
    END
    ELSE BEGIN
SET @Sql = @Sql + ' PAF.COD_AFFILIATOR IS NULL AND PAF.COD_EC IS NULL AND PAF.COD_ASS_DEPTO_TERMINAL IS NULL '
    END

    IF @ONLINE = 1 BEGIN
SET @Sql = @Sql + ' AND PAF.ONLINE = 1 ';
    END

    IF @PRESENTIAL = 1 BEGIN
SET @Sql = @Sql + ' AND PAF.PRESENTIAL = 1 ';
    END

    IF @COD_AC IS NOT NULL BEGIN
SET @Sql = @Sql + ' AND PAF.COD_AC = @COD_AC ';
    END

    IF @COD_MODEL IS NOT NULL BEGIN
SET @Sql = @Sql + ' AND PAF.COD_MODEL = @COD_MODEL '
    END

    IF @BRANDGROUP IS NOT NULL BEGIN
SET @Sql = @Sql + ' AND B.[GROUP] = @BRANDGROUP '
    END

    DECLARE @CTQUERY NVARCHAR(MAX) = N'SELECT @QtyRows=COUNT(*) FROM (' + @Sql + ') r ';

EXEC SP_EXECUTESQL @CTQUERY
				  ,N'@COD_AFF INT,
    @COD_EC INT,
    @SERIAL VARCHAR(96),
    @COD_AC INT,
    @COD_MODEL INT,
    @BRANDGROUP VARCHAR(64),
    @ONLINE INT,
    @PRESENTIAL INT,
    @PAGE INT,
    @PAGESIZE INT,
    @Skip INT,
    @QtyRows INT OUTPUT
    '
				  ,@COD_AFF = @COD_AFF
				  ,@COD_EC = @COD_EC
				  ,@SERIAL = @SERIAL
				  ,@COD_AC = @COD_AC
				  ,@COD_MODEL = @COD_MODEL
				  ,@BRANDGROUP = @BRANDGROUP
				  ,@ONLINE = @ONLINE
				  ,@PRESENTIAL = @PRESENTIAL
				  ,@PAGE = @PAGE
				  ,@PAGESIZE = @PAGESIZE
				  ,@Skip = @Skip
				  ,@QtyRows = @QtyRows OUTPUT;

SET @Sql = @Sql + ' ORDER BY COD_PRD_ACQ_FILTER DESC
    OFFSET @Skip ROWS
    FETCH NEXT @PAGESIZE ROWS ONLY 
    '

EXEC SP_EXECUTESQL @Sql
				  ,N'@COD_AFF INT,
    @COD_EC INT,
    @SERIAL VARCHAR(96),
    @COD_AC INT,
    @COD_MODEL INT,
    @BRANDGROUP VARCHAR(64),
    @ONLINE INT,
    @PRESENTIAL INT,
    @PAGE INT,
    @PAGESIZE INT,
    @Skip INT
    '
				  ,@COD_AFF = @COD_AFF
				  ,@COD_EC = @COD_EC
				  ,@SERIAL = @SERIAL
				  ,@COD_AC = @COD_AC
				  ,@COD_MODEL = @COD_MODEL
				  ,@BRANDGROUP = @BRANDGROUP
				  ,@ONLINE = @ONLINE
				  ,@PRESENTIAL = @PRESENTIAL
				  ,@PAGE = @PAGE
				  ,@PAGESIZE = @PAGESIZE
				  ,@Skip = @Skip;

END
GO

IF OBJECT_ID('SP_RM_FILTER_PRDCT_ACQ') IS NOT NULL BEGIN
DROP PROCEDURE SP_RM_FILTER_PRDCT_ACQ
END
GO
CREATE PROCEDURE SP_RM_FILTER_PRDCT_ACQ
(
    @Ids CODE_TYPE READONLY 
) AS BEGIN

DELETE PRODUCT_ACQUIRE_FILTER
	FROM PRODUCT_ACQUIRE_FILTER
	JOIN @Ids i
		ON i.CODE = PRODUCT_ACQUIRE_FILTER.COD_PRD_ACQ_FILTER

END
GO


IF OBJECT_ID('SP_CREATE_FILTER_PRDCT_ACQ') IS NOT NULL
DROP PROCEDURE SP_CREATE_FILTER_PRDCT_ACQ
GO
IF OBJECT_ID('SP_FD_CONFLICT_FILTER_PRDT_ACQ') IS NOT NULL
DROP PROCEDURE SP_FD_CONFLICT_FILTER_PRDT_ACQ
GO
IF TYPE_ID('PRD_ACQ_FILTER_TP') IS NOT NULL BEGIN
DROP TYPE PRD_ACQ_FILTER_TP
END
GO
CREATE TYPE PRD_ACQ_FILTER_TP AS table
(
    [COD_AF] INT,
    [COD_EC] INT,
    [COD_EQP] INT,
    [COD_ACQ] INT,
    [ONLINE] INT,
    [PRESENTIAL] INT,
    [COD_MODEL] INT,
    [BRAND_GROUP] VARCHAR(64),
    [CREDIT] INT,
    [DEBIT] INT,
    [CREDIT_INSTALLMENTS] INT,
    [CLIENT_INSTALLMENTS] INT,
    [CLIENT_CREDIT] INT,
    [CLIENT_DEBIT] INT,
    [RATE_FREE] INT
)
GO
CREATE PROCEDURE SP_CREATE_FILTER_PRDCT_ACQ
/*----------------------------------------------------------------------------------------        
    Project.......: TKPP        
------------------------------------------------------------------------------------------        
    Author                  VERSION        Date             Description        
------------------------------------------------------------------------------------------        
    Luiz Aquino              V1            2020-11-25       CREATED  
------------------------------------------------------------------------------------------*/
(
@ITEMS PRD_ACQ_FILTER_TP READONLY,
@COD_USER INT = null
) AS BEGIN

DELETE PAF
	FROM PRODUCT_ACQUIRE_FILTER PAF
	LEFT JOIN ASS_DEPTO_EQUIP ADE
		ON ADE.COD_ASS_DEPTO_TERMINAL = PAF.COD_ASS_DEPTO_TERMINAL
	LEFT JOIN BRAND B
		ON B.COD_BRAND = PAF.COD_BRAND
	JOIN @ITEMS I
		ON ((PAF.COD_AFFILIATOR = I.COD_AF)
		OR (PAF.COD_EC = I.COD_EC)
		OR (ADE.COD_EQUIP = I.COD_EQP)
		OR (PAF.COD_AFFILIATOR IS NULL
		AND PAF.COD_EC IS NULL
		AND PAF.COD_ASS_DEPTO_TERMINAL IS NULL))
		AND ((PAF.COD_MODEL IS NULL
		AND I.COD_MODEL IS NULL)
		OR PAF.COD_MODEL = I.COD_MODEL)
		AND ((PAF.COD_AC IS NULL
		AND I.COD_ACQ IS NULL)
		OR PAF.COD_AC = I.COD_ACQ)
		AND (PAF.PRESENTIAL = I.PRESENTIAL)
		AND (PAF.ONLINE = I.ONLINE)
		AND ((B.[GROUP] IS NULL
		AND I.BRAND_GROUP IS NULL)
		OR B.[GROUP] = I.BRAND_GROUP)

INSERT INTO PRODUCT_ACQUIRE_FILTER (COD_AFFILIATOR,
COD_EC,
COD_ASS_DEPTO_TERMINAL,
COD_AC,
COD_MODEL,
COD_BRAND,
ONLINE,
PRESENTIAL,
DEBIT,
CREDIT,
CREDIT_INSTALLMENTS,
CLIENT_INSTALLMENT,
CLIENT_DEBIT,
CLIENT_CREDIT,
RATE_FREE,
CREATED_AT,
COD_USER)
	SELECT
		COD_AF
	   ,COD_EC
	   ,ADE.COD_ASS_DEPTO_TERMINAL
	   ,COD_ACQ
	   ,COD_MODEL
	   ,B.COD_BRAND
	   ,ONLINE
	   ,PRESENTIAL
	   ,DEBIT
	   ,CREDIT
	   ,CREDIT_INSTALLMENTS
	   ,CLIENT_INSTALLMENTS
	   ,CLIENT_DEBIT
	   ,CLIENT_CREDIT
	   ,RATE_FREE
	   ,GETDATE()
	   ,@COD_USER
	FROM @ITEMS I
	LEFT JOIN ASS_DEPTO_EQUIP ADE
		ON ADE.COD_EQUIP = I.COD_EQP
			AND ACTIVE = 1
	LEFT JOIN BRAND B
		ON B.[GROUP] = I.BRAND_GROUP
			AND ((COD_TTYPE = 1
					AND (CREDIT = 1
						OR CREDIT_INSTALLMENTS = 1
						OR CLIENT_INSTALLMENTS = 1
						OR CLIENT_CREDIT = 1
						OR RATE_FREE = 1))
				OR (COD_TTYPE = 2
					AND (DEBIT = 1
						OR CLIENT_DEBIT = 1)))
END
GO
CREATE PROCEDURE SP_FD_CONFLICT_FILTER_PRDT_ACQ
/*----------------------------------------------------------------------------------------        
    Project.......: TKPP        
------------------------------------------------------------------------------------------        
    Author                  VERSION        Date             Description        
------------------------------------------------------------------------------------------        
    Luiz Aquino              V1            2020-11-25       CREATED  
------------------------------------------------------------------------------------------*/
(
    @ITEMS PRD_ACQ_FILTER_TP READONLY
) AS BEGIN

SELECT
	PAF.*
FROM PRODUCT_ACQUIRE_FILTER PAF
LEFT JOIN ASS_DEPTO_EQUIP ADE
	ON ADE.COD_ASS_DEPTO_TERMINAL = PAF.COD_ASS_DEPTO_TERMINAL
LEFT JOIN BRAND B
	ON B.COD_BRAND = PAF.COD_BRAND
JOIN @ITEMS I
	ON ((PAF.COD_AFFILIATOR = I.COD_AF)
			OR (PAF.COD_EC = I.COD_EC)
			OR (ADE.COD_EQUIP = I.COD_EQP)
			OR (PAF.COD_AFFILIATOR IS NULL
				AND PAF.COD_EC IS NULL
				AND PAF.COD_ASS_DEPTO_TERMINAL IS NULL))
		AND ((PAF.COD_MODEL IS NULL
				AND I.COD_MODEL IS NULL)
			OR PAF.COD_MODEL = I.COD_MODEL)
		AND ((PAF.COD_AC IS NULL
				AND I.COD_ACQ IS NULL)
			OR PAF.COD_AC = I.COD_ACQ)
		AND (PAF.PRESENTIAL = I.PRESENTIAL)
		AND (PAF.ONLINE = I.ONLINE)
		AND ((B.[GROUP] IS NULL
				AND I.BRAND_GROUP IS NULL)
			OR B.[GROUP] = I.BRAND_GROUP)

END

GO
IF OBJECT_ID('SP_LS_SERIAL') IS NOT NULL DROP PROCEDURE SP_LS_SERIAL
GO
CREATE PROCEDURE [dbo].[SP_LS_SERIAL]    
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_LS_SERIAL]    
Project.......: TKPP    
----------------------------------------------------------
--------------------------------    
Author                          VERSION        Date                            Description    
------------------------------------------------------------------------------------------    
Lucas Aguiar     v1      09/
11/2018      Creation    
------------------------------------------------------------------------------------------*/    
(    
@COD_COMP INT,    
@SERIAL VARCHAR(255) = NULL    
)    
AS    
DECLARE @QUERY NVARCHAR(MAX);
        
BEGIN

 

SET @QUERY = 
'      
 SELECT     
  EQ.COD_EQUIP,  
  EQ.SERIAL,    
  EQM.CODIGO,    
  EQ.CHIP,  
  EQ.ACTIVE,
  IIF(ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = 1, 1, 0) AS IS_ASSOCIATED
 FROM    
   EQUIPMENT EQ     
 INNER JOIN    
  EQUIPMENT_MODEL EQM ON EQM.COD_MODEL = EQ.COD_MODEL       
LEFT JOIN ASS_DEPTO_EQUIP ON 
    ASS_DEPTO_EQUIP.COD_EQUIP = EQ.COD_EQUIP AND ASS_DEPTO_EQUIP.ACTIVE = 1
 WHERE COD_COMP = @COD_COMP    
 '
    
IF @SERIAL IS NOT NULL
SET @QUERY = @QUERY + 'AND EQ.SERIAL = @SERIAL'

 

SET @QUERY = @QUERY + ' ORDER BY 1 DESC'



EXEC sp_executesql @QUERY
				  ,N'                      
   @COD_COMP INT        
  ,@SERIAL VARCHAR(255)                
  '
				  ,@COD_COMP = @COD_COMP
				  ,@SERIAL = @SERIAL


 

END
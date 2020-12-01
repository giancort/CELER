
IF OBJECT_ID('CUSTOMIZED_UNAVAILABLE_PRODUCTS') IS NOT NULL
DROP TABLE CUSTOMIZED_UNAVAILABLE_PRODUCTS;
GO
IF OBJECT_ID('PRODUCTS_UNAVAILABLE_EC') IS NOT NULL
DROP TABLE PRODUCTS_UNAVAILABLE_EC;
GO
CREATE TABLE [PRODUCTS_UNAVAILABLE_EC]
(
	COD_PR_UN_EC INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	COD_EC INT FOREIGN KEY REFERENCES COMMERCIAL_ESTABLISHMENT (COD_EC),
	COD_AFFILIATOR INT FOREIGN KEY REFERENCES AFFILIATOR (COD_AFFILIATOR),
	IS_SIMULATED INT DEFAULT 0,
	NOT_SIMULATED INT DEFAULT 0,
	PRODUCTS_CUSTOMIZED INT DEFAULT 0,
	AUX INT DEFAULT 0
)

GO

CREATE TABLE [CUSTOMIZED_UNAVAILABLE_PRODUCTS]
(
	COD_UN_PR_CUST INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	COD_PR_UN_EC INT NOT NULL FOREIGN KEY REFERENCES [PRODUCTS_UNAVAILABLE_EC] (COD_PR_UN_EC),
	COD_PR_ACQ INT NOT NULL FOREIGN KEY REFERENCES PRODUCTS_ACQUIRER (COD_PR_ACQ),
	COD_MODEL INT FOREIGN KEY REFERENCES EQUIPMENT_MODEL (COD_MODEL)
)

GO

IF OBJECT_ID('SP_LOAD_TABLES_EQUIP') IS NOT NULL DROP PROCEDURE SP_LOAD_TABLES_EQUIP
GO
CREATE PROCEDURE [DBO].[SP_LOAD_TABLES_EQUIP] (@TERMINALID INT)                   
AS                   
   DECLARE @COD_EC INT;
    DECLARE @COD_AFF INT;
    DECLARE @COD_SUB INT;
    DECLARE @DATE_PLAN DATETIME;
    DECLARE @EQUIP_MODEL VARCHAR(100);

BEGIN

WITH CTE_DATA
AS
(SELECT

		ISNULL(COD_AFFILIATOR, 0) AS COD_AFFILIATOR
	   ,COD_COMP AS COD_COMP
	   ,COD_DEPTO_BR
	   ,COD_EC
	   ,MAX(ASS_TAX_DEPART.CREATED_AT) AS DATE_PLAN
	   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_MODEL
	FROM VW_COMPANY_EC_AFF_BR_DEP_EQUIP
	JOIN ASS_TAX_DEPART
		ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_DEPTO_BR
	WHERE ASS_TAX_DEPART.ACTIVE = 1
	AND COD_EQUIP = @TERMINALID
	GROUP BY COD_COMP
			,COD_DEPTO_BR
			,ISNULL(COD_AFFILIATOR, 0)
			,COD_EC
			,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.
			 COD_MODEL)
SELECT
	@COD_AFF = COD_AFFILIATOR
   ,@COD_SUB = COD_COMP
   ,@COD_EC = COD_EC
   ,@DATE_PLAN = (CASE
		WHEN dbo.FN_FUS_UTF(DATE_PLAN) > CAST(CONVERT(VARCHAR, GETDATE(), 101) AS DATETIME) THEN dbo.FN_FUS_UTF(DATE_PLAN)
		ELSE CAST(CONVERT(VARCHAR, GETDATE(), 101) AS DATETIME)
	END)
   ,@EQUIP_MODEL = COD_MODEL
FROM CTE_DATA;

WITH [CTE_BLOCKED_AFF]
AS
(SELECT
		AUX
	FROM PRODUCTS_UNAVAILABLE_EC
	WHERE COD_AFFILIATOR = @COD_AFF
	EXCEPT
	SELECT
		AUX
	FROM PRODUCTS_UNAVAILABLE_EC
	WHERE COD_EC = @COD_EC),
[CTE_BLOCKED_EC]
AS
(SELECT
		AUX
	FROM PRODUCTS_UNAVAILABLE_EC
	WHERE COD_EC = @COD_EC)
SELECT
	PRODUCTS_UNAVAILABLE_EC.COD_PR_UN_EC
   ,PRODUCTS_UNAVAILABLE_EC.IS_SIMULATED
   ,PRODUCTS_UNAVAILABLE_EC.PRODUCTS_CUSTOMIZED
   ,PRODUCTS_UNAVAILABLE_EC.NOT_SIMULATED
   ,PRODUCTS_UNAVAILABLE_EC.COD_EC
   ,PRODUCTS_UNAVAILABLE_EC.COD_AFFILIATOR
   ,CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_PR_ACQ
   ,CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_MODEL INTO #PRODUCTS_TO_ASSOCIATE
FROM [CTE_BLOCKED_AFF]
JOIN PRODUCTS_UNAVAILABLE_EC
	ON CTE_BLOCKED_AFF.AUX = PRODUCTS_UNAVAILABLE_EC.AUX
LEFT JOIN CUSTOMIZED_UNAVAILABLE_PRODUCTS
	ON CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_PR_UN_EC = PRODUCTS_UNAVAILABLE_EC.COD_PR_UN_EC
WHERE PRODUCTS_UNAVAILABLE_EC.COD_AFFILIATOR = @COD_AFF
UNION
SELECT
	PRODUCTS_UNAVAILABLE_EC.COD_PR_UN_EC
   ,PRODUCTS_UNAVAILABLE_EC.IS_SIMULATED
   ,PRODUCTS_UNAVAILABLE_EC.PRODUCTS_CUSTOMIZED
   ,PRODUCTS_UNAVAILABLE_EC.NOT_SIMULATED
   ,PRODUCTS_UNAVAILABLE_EC.COD_EC
   ,PRODUCTS_UNAVAILABLE_EC.COD_AFFILIATOR
   ,CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_PR_ACQ
   ,CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_MODEL
FROM [CTE_BLOCKED_EC]
JOIN PRODUCTS_UNAVAILABLE_EC
	ON CTE_BLOCKED_EC.AUX = PRODUCTS_UNAVAILABLE_EC.AUX
LEFT JOIN CUSTOMIZED_UNAVAILABLE_PRODUCTS
	ON CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_PR_UN_EC = PRODUCTS_UNAVAILABLE_EC.COD_PR_UN_EC
WHERE PRODUCTS_UNAVAILABLE_EC.COD_EC = @COD_EC;

WITH [CTE_SUB]
AS
(SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_COMP = @COD_SUB
	AND ACTIVE = 1
	EXCEPT
	SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_AFFILIATOR = @COD_AFF
	AND ACTIVE = 1
	EXCEPT
	SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EC = @COD_EC
	AND ACTIVE = 1
	EXCEPT
	SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EQUIP = @TERMINALID
	AND ACTIVE = 1),
[CTE_AFF]
AS
(SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_AFFILIATOR = @COD_AFF
	AND ROUTE_ACQUIRER.ACTIVE = 1
	EXCEPT
	SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EC = @COD_EC
	AND ROUTE_ACQUIRER.ACTIVE = 1
	EXCEPT
	SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EQUIP = @TERMINALID
	AND ROUTE_ACQUIRER.ACTIVE = 1),
[CTE_EC]
AS
(SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EC = @COD_EC
	AND ROUTE_ACQUIRER.ACTIVE = 1
	EXCEPT
	SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EQUIP = @TERMINALID
	AND ROUTE_ACQUIRER.ACTIVE = 1),
[CTE_EQUIP]
AS
(SELECT
		ROUTE_ACQUIRER.COD_BRAND
	FROM ROUTE_ACQUIRER
	WHERE COD_EQUIP = @TERMINALID
	AND ROUTE_ACQUIRER.ACTIVE = 1
	AND COD_SOURCE_TRAN = 2)
SELECT
	ACQUIRER.[GROUP] AS ACQUIRER_NAME
   ,PRODUCTS_ACQUIRER.COD_PR_ACQ AS PRODUCT_ID
   ,PRODUCTS_ACQUIRER.NAME AS PRODUCT_NAME
   ,PRODUCTS_ACQUIRER.EXTERNALCODE AS PRODUCT_EXT_CODE
   ,[TRANSACTION_TYPE].COD_TTYPE AS TRAN_TYPE
   ,[TRANSACTION_TYPE].NAME AS TRAN_TYPE_NAME
   ,'0' AS CODE_EC_ACQ
   ,BRAND.NAME AS BRAND
   ,ROUTE_ACQUIRER.CONF_TYPE
   ,PRODUCTS_ACQUIRER.IS_SIMULATED
   ,@DATE_PLAN AS DATE_PLAN
FROM CTE_SUB
INNER JOIN ROUTE_ACQUIRER
	ON ROUTE_ACQUIRER.COD_BRAND = CTE_SUB.COD_BRAND
INNER JOIN BRAND
	ON BRAND.COD_BRAND = CTE_SUB.COD_BRAND
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].COD_TTYPE = BRAND.COD_TTYPE
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
INNER JOIN PRODUCTS_ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_BRAND = CTE_SUB.COD_BRAND
		AND PRODUCTS_ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
		AND PRODUCTS_ACQUIRER.COD_SOURCE_TRAN = 2
		AND PRODUCTS_ACQUIRER.VISIBLE = 1
LEFT JOIN #PRODUCTS_TO_ASSOCIATE PRODUCTS_TO_ASSOCIATE
	ON PRODUCTS_TO_ASSOCIATE.COD_EC = @COD_EC
		OR PRODUCTS_TO_ASSOCIATE.COD_AFFILIATOR = @COD_AFF
WHERE COD_COMP = @COD_SUB
AND CONF_TYPE = 4
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND (PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1) <> 1, 12, ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1))
OR PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.NOT_SIMULATED, 1) <> 1, 12, 0))
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		ISNULL(COD_PR_ACQ, 0)
	FROM #PRODUCTS_TO_ASSOCIATE PROD
	WHERE ISNULL(PROD.COD_MODEL, @EQUIP_MODEL) = @EQUIP_MODEL)


UNION
SELECT
	ACQUIRER.[GROUP] AS ACQUIRER_NAME
   ,PRODUCTS_ACQUIRER.COD_PR_ACQ AS PRODUCT_ID
   ,PRODUCTS_ACQUIRER.NAME AS PRODUCT_NAME
   ,PRODUCTS_ACQUIRER.EXTERNALCODE AS PRODUCT_EXT_CODE
   ,[TRANSACTION_TYPE].COD_TTYPE AS TRAN_TYPE
   ,[TRANSACTION_TYPE].NAME AS TRAN_TYPE_NAME
   ,'0' AS CODE_EC_ACQ
   ,BRAND.NAME AS BRAND
   ,ROUTE_ACQUIRER.CONF_TYPE
   ,PRODUCTS_ACQUIRER.IS_SIMULATED
   ,@DATE_PLAN AS DATE_PLAN

FROM CTE_AFF
INNER JOIN ROUTE_ACQUIRER
	ON ROUTE_ACQUIRER.COD_BRAND = CTE_AFF.COD_BRAND
INNER JOIN BRAND
	ON BRAND.COD_BRAND = CTE_AFF.COD_BRAND
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].COD_TTYPE = BRAND.COD_TTYPE
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
INNER JOIN PRODUCTS_ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_BRAND = CTE_AFF.COD_BRAND
		AND PRODUCTS_ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
		AND PRODUCTS_ACQUIRER.COD_SOURCE_TRAN = 2
		AND PRODUCTS_ACQUIRER.VISIBLE = 1

LEFT JOIN #PRODUCTS_TO_ASSOCIATE PRODUCTS_TO_ASSOCIATE
	ON PRODUCTS_TO_ASSOCIATE.COD_EC = @COD_EC
		OR PRODUCTS_TO_ASSOCIATE.COD_AFFILIATOR = @COD_AFF
WHERE ROUTE_ACQUIRER.COD_AFFILIATOR = @COD_AFF
AND CONF_TYPE = 3
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND (PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1) <> 1, 12, ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1))
OR PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.NOT_SIMULATED, 1) <> 1, 12, 0))
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		ISNULL(COD_PR_ACQ, 0)
	FROM #PRODUCTS_TO_ASSOCIATE PROD
	WHERE ISNULL(PROD.COD_MODEL, @EQUIP_MODEL) = @EQUIP_MODEL)

UNION
SELECT
	ACQUIRER.[GROUP] AS ACQUIRER_NAME
   ,PRODUCTS_ACQUIRER.COD_PR_ACQ AS PRODUCT_ID
   ,PRODUCTS_ACQUIRER.NAME AS PRODUCT_NAME
   ,PRODUCTS_ACQUIRER.EXTERNALCODE AS PRODUCT_EXT_CODE
   ,[TRANSACTION_TYPE].COD_TTYPE AS TRAN_TYPE
   ,[TRANSACTION_TYPE].NAME AS TRAN_TYPE_NAME
   ,'0' AS CODE_EC_ACQ
   ,BRAND.NAME AS BRAND
   ,ROUTE_ACQUIRER.CONF_TYPE
   ,PRODUCTS_ACQUIRER.IS_SIMULATED
   ,@DATE_PLAN AS DATE_PLAN

FROM [CTE_EC]
INNER JOIN ROUTE_ACQUIRER
	ON ROUTE_ACQUIRER.COD_BRAND = [CTE_EC].COD_BRAND
INNER JOIN BRAND
	ON BRAND.COD_BRAND = [CTE_EC].COD_BRAND
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].COD_TTYPE = BRAND.COD_TTYPE
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
INNER JOIN PRODUCTS_ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_BRAND = [CTE_EC].COD_BRAND
		AND PRODUCTS_ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
		AND PRODUCTS_ACQUIRER.COD_SOURCE_TRAN = 2
		AND PRODUCTS_ACQUIRER.VISIBLE = 1
LEFT JOIN #PRODUCTS_TO_ASSOCIATE PRODUCTS_TO_ASSOCIATE
	ON PRODUCTS_TO_ASSOCIATE.COD_EC = @COD_EC
		OR PRODUCTS_TO_ASSOCIATE.COD_AFFILIATOR = @COD_AFF
WHERE ROUTE_ACQUIRER.COD_EC = @COD_EC
AND CONF_TYPE = 2
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND (PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1) <> 1, 12, ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1))
OR PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.NOT_SIMULATED, 1) <> 1, 12, 0))
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		ISNULL(COD_PR_ACQ, 0)
	FROM #PRODUCTS_TO_ASSOCIATE PROD
	WHERE ISNULL(PROD.COD_MODEL, @EQUIP_MODEL) = @EQUIP_MODEL)



UNION
SELECT
	ACQUIRER.[GROUP] AS ACQUIRER_NAME
   ,PRODUCTS_ACQUIRER.COD_PR_ACQ AS PRODUCT_ID
   ,PRODUCTS_ACQUIRER.NAME AS PRODUCT_NAME
   ,PRODUCTS_ACQUIRER.EXTERNALCODE AS PRODUCT_EXT_CODE
   ,[TRANSACTION_TYPE].COD_TTYPE AS TRAN_TYPE
   ,[TRANSACTION_TYPE].NAME AS TRAN_TYPE_NAME
   ,'0' AS CODE_EC_ACQ
   ,BRAND.NAME AS BRAND
   ,ROUTE_ACQUIRER.CONF_TYPE
   ,PRODUCTS_ACQUIRER.IS_SIMULATED
   ,@DATE_PLAN AS DATE_PLAN

FROM [CTE_EQUIP]
INNER JOIN ROUTE_ACQUIRER
	ON ROUTE_ACQUIRER.COD_BRAND = [CTE_EQUIP].COD_BRAND
INNER
JOIN BRAND
	ON BRAND.COD_BRAND = [CTE_EQUIP].COD_BRAND
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].COD_TTYPE = BRAND.COD_TTYPE
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
INNER JOIN PRODUCTS_ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_BRAND = [CTE_EQUIP].COD_BRAND
		AND PRODUCTS_ACQUIRER.COD_AC = ROUTE_ACQUIRER.COD_AC
		AND PRODUCTS_ACQUIRER.COD_SOURCE_TRAN = 2
		AND PRODUCTS_ACQUIRER.VISIBLE = 1
LEFT JOIN #PRODUCTS_TO_ASSOCIATE PRODUCTS_TO_ASSOCIATE
	ON PRODUCTS_TO_ASSOCIATE.COD_EC = @COD_EC
		OR PRODUCTS_TO_ASSOCIATE.COD_AFFILIATOR = @COD_AFF
WHERE COD_EQUIP = @TERMINALID
AND CONF_TYPE = 1
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND (PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1) <> 1, 12, ISNULL(PRODUCTS_TO_ASSOCIATE.IS_SIMULATED, 1))
OR PRODUCTS_ACQUIRER.IS_SIMULATED = IIF(ISNULL(PRODUCTS_TO_ASSOCIATE.NOT_SIMULATED, 1) <> 1, 12, 0))
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		ISNULL(COD_PR_ACQ, 0)
	FROM #PRODUCTS_TO_ASSOCIATE PROD
	WHERE ISNULL(PROD.COD_MODEL, @EQUIP_MODEL) = @EQUIP_MODEL)
END;


GO


INSERT INTO PRODUCTS_UNAVAILABLE_EC (COD_AFFILIATOR, IS_SIMULATED, NOT_SIMULATED, PRODUCTS_CUSTOMIZED, AUX)
	SELECT DISTINCT
		COD_AFFILIATOR
	   ,1
	   ,1
	   ,1
	   ,1
	FROM PRODUCT_UNAVAILABLE_MODEL
	WHERE COD_AFFILIATOR IS NOT NULL
	ORDER BY COD_AFFILIATOR

GO

INSERT INTO PRODUCTS_UNAVAILABLE_EC (COD_EC, IS_SIMULATED, NOT_SIMULATED, PRODUCTS_CUSTOMIZED, AUX)
	SELECT
		COD_EC
	   ,0
	   ,1
	   ,0
	   ,1
	FROM COMMERCIAL_ESTABLISHMENT
	WHERE COD_EC IN
	(
	15583
	, 15875
	, 15617
	, 16335
	, 16329
	, 16323
	, 20110
	, 18353
	)

GO


INSERT INTO [CUSTOMIZED_UNAVAILABLE_PRODUCTS] (COD_PR_UN_EC
, COD_PR_ACQ
, COD_MODEL)
	SELECT DISTINCT
		PRODUCTS_UNAVAILABLE_EC.COD_PR_UN_EC
	   ,PRODUCT_UNAVAILABLE_MODEL.COD_PR_ACQ
	   ,COD_MODEL
	FROM PRODUCT_UNAVAILABLE_MODEL
	JOIN PRODUCTS_ACQUIRER
		ON PRODUCT_UNAVAILABLE_MODEL.COD_PR_ACQ = PRODUCTS_ACQUIRER.COD_PR_ACQ
	JOIN PRODUCTS_UNAVAILABLE_EC
		ON PRODUCTS_UNAVAILABLE_EC.COD_AFFILIATOR = PRODUCT_UNAVAILABLE_MODEL.COD_AFFILIATOR
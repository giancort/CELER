--AS
                   
    DECLARE @COD_EC INT;
    DECLARE @COD_AFF INT;
    DECLARE @COD_SUB INT;
    DECLARE @DATE_PLAN DATETIME;
    DECLARE @EQUIP_MODEL VARCHAR(100)
	DECLARE @TERMINALID INT = 3;

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
			,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_MODEL)
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

SELECT
	IS_SIMULATED
   ,NOT_SIMULATED
   ,COD_EC
   ,COD_PR_ACQ
   ,COD_MODEL INTO #PRODUCTS_TO_ASSOCIATE
FROM PRODUCTS_UNAVAILABLE_EC
LEFT JOIN CUSTOMIZED_UNAVAILABLE_PRODUCTS
	ON CUSTOMIZED_UNAVAILABLE_PRODUCTS.COD_PR_UN_EC = PRODUCTS_UNAVAILABLE_EC.COD_PR_UN_EC
WHERE COD_EC = @COD_EC;


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
LEFT JOIN PRODUCTS_UNAVAILABLE_EC
	ON PRODUCTS_UNAVAILABLE_EC.COD_EC = @COD_EC
WHERE COD_COMP = @COD_SUB
AND CONF_TYPE = 4
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		COD_PR_ACQ
	FROM PRODUCT_UNAVAILABLE_MODEL
	WHERE PRODUCT_UNAVAILABLE_MODEL.COD_MODEL = @EQUIP_MODEL
	AND PRODUCT_UNAVAILABLE_MODEL.COD_AFFILIATOR = @COD_AFF)
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
	ON ROUTE_ACQUIRER.COD_BRAND
		= CTE_AFF.COD_BRAND
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

WHERE COD_AFFILIATOR = @COD_AFF
AND CONF_TYPE = 3
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		COD_PR_ACQ
	FROM PRODUCT_UNAVAILABLE_MODEL
	WHERE PRODUCT_UNAVAILABLE_MODEL.COD_MODEL = @EQUIP_MODEL
	AND PRODUCT_UNAVAILABLE_MODEL.COD_AFFILIATOR = @COD_AFF)

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
WHERE COD_EC = @COD_EC
AND CONF_TYPE = 2
AND ROUTE_ACQUIRER.ACTIVE = 1
AND ROUTE_ACQUIRER.COD_SOURCE_TRAN = 2
AND PRODUCTS_ACQUIRER.COD_PR_ACQ NOT IN (SELECT
		COD_PR_ACQ
	FROM PRODUCT_UNAVAILABLE_MODEL
	WHERE PRODUCT_UNAVAILABLE_MODEL.COD_MODEL = @EQUIP_MODEL
	AND PRODUCT_UNAVAILABLE_MODEL.COD_AFFILIATOR = @COD_AFF)
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

DROP TABLE #PRODUCTS_TO_ASSOCIATE


--SELECT
--	IIF(ISNULL(IS_SIMULATED, 1) <> 1, 12, ISNULL(IS_SIMULATED, 1)),
--	IIF(ISNULL(NOT_SIMULATED, 1) <> 1, 12, 0)
--FROM PRODUCTS_UNAVAILABLE_EC

--INSERT PRODUCTS_UNAVAILABLE_EC (COD_EC, IS_SIMULATED, NOT_SIMULATED, PRODUCTS_CUSTOMIZED) VALUES (17497, 0, 0, 0)
--UPDATE PRODUCTS_UNAVAILABLE_EC SET NOT_SIMULATED = 1, IS_SIMULATED = 0
--UPDATE PRODUCTS_UNAVAILABLE_EC SET NOT_SIMULATED = 1, IS_SIMULATED = 1
--UPDATE PRODUCTS_UNAVAILABLE_EC SET NOT_SIMULATED = 1, IS_SIMULATED = 1, PRODUCTS_CUSTOMIZED = 1


--INSERT INTO CUSTOMIZED_UNAVAILABLE_PRODUCTS (COD_PR_UN_EC, COD_PR_ACQ)
--	VALUES (1, 465),
--	(1, 509),
--	(1, 510),
--	(1, 511),
--	(1, 512),
--	(1, 513),
--	(1, 514),
--	(1, 600),
--	(1, 601),
--	(1, 602),
--	(1, 603)
--INSERT INTO CUSTOMIZED_UNAVAILABLE_PRODUCTS (COD_PR_UN_EC, COD_PR_ACQ, COD_MODEL)
--	VALUES (1, 50, 2),
--	(1, 52, 2),
--	(1, 53, 2),
--	(1, 54, 2),
--	(1, 56, 2),
--	(1, 57, 2),
--	(1, 58, 2),
--	(1, 60, 2),
--	(1, 61, 2),
--	(1, 77, 2),
--	(1, 78, 2),
--	(1, 79, 2),
--	(1, 80, 2)

--DELETE FROM CUSTOMIZED_UNAVAILABLE_PRODUCTS

--SELECT * FROM EQUIPMENT_MODEL


--2
--SELECT * FROM CUSTOMIZED_UNAVAILABLE_PRODUCTS WHERE COD_EQUIP = 3


--UPDATE CUSTOMIZED_UNAVAILABLE_PRODUCTS SET COD_MODEL = 4 WHERE COD_MODEL IS NULL
/****** Object:  UserDefinedTableType [dbo].[TP_THEMES_IMG]    Script Date: 27/04/2020 11:19:14 ******/
CREATE TYPE [dbo].[TP_THEMES_IMG] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[COD_WL_CONT_TYPE] [int] NULL,
	[PATH_CONTENT] [varchar](400) NULL,
	[COD_MODEL] [int] NULL
)
GO

/****** Object:  UserDefinedTableType [dbo].[WL_PRODUCTS]    Script Date: 27/04/2020 11:19:31 ******/
CREATE TYPE [dbo].[WL_PRODUCTS] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[PRODUCT_NAME] [varchar](255) NULL,
	[SKU] [varchar](255) NULL,
	[PRICE] [decimal](22, 8) NULL,
	[COD_MODEL] [int] NULL
)
GO

/****** Object:  UserDefinedTableType [dbo].[TP_REG_EQUIP_PICKING]    Script Date: 27/04/2020 11:20:15 ******/
CREATE TYPE [dbo].[TP_REG_EQUIP_PICKING] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_DEPTO] [int] NULL,
	[COD_COMP] [int] NULL,
	[SERIAL] [varchar](100) NULL,
	[CHIP] [varchar](100) NULL,
	[PUK] [varchar](100) NULL,
	[OPERATOR] [int] NULL,
	[CODMODEL] [int] NULL,
	[COMPANY] [int] NULL,
	[ORDER_NUMBER] [varchar](150) NULL,
	[ORDER_CODE] [int] NULL,
	[PARTNUMBER] [varchar](150) NULL
)
GO
GO
IF OBJECT_ID('SP_FD_ORDERS') IS NOT NULL DROP PROCEDURE SP_FD_ORDERS;
GO
CREATE PROCEDURE [DBO].[SP_FD_ORDERS]             /*************************************************************************************************************************  ----------------------------------------------------------------------------------------                           Procedure Name: [[SP_LS_DATA_ORDER]]                           Project.......: TKPP                           ------------------------------------------------------------------------------------------                           Author                          VERSION        Date                            Description                                  ------------------------------------------------------------------------------------------                           Lucas Aguiar     V1    2020-01-31       Creation                                 ------------------------------------------------------------------------------------------        *************************************************************************************************************************/            (   @COD_EC       INT,    @ORDER_NUMBER INT = NULL)  AS  BEGIN
SELECT
	[ODR].[COD_ODR]
   ,[ODR].[CODE]
   ,[ODR].[CREATED_AT]
   ,[ODR].[AMOUNT]
   ,[ORDER_SITUATION].[CODE] AS [SITUATION]
   ,[ORDER_ITEM].[QUANTITY]
   ,[PRODUCTS].[PRODUCT_NAME]
   ,[ECOMMERCE_THEMES_IMG].[PATH_CONTENT]
FROM [ORDER] AS [ODR]
JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ODR].[COD_ORDER_SIT]
JOIN [ORDER_ITEM]
	ON [ORDER_ITEM].[COD_ODR] = [ODR].[COD_ODR]
JOIN [PRODUCTS]
	ON [PRODUCTS].[COD_PRODUCT] = [ORDER_ITEM].[COD_PRODUCT]
JOIN [ECOMMERCE_THEMES_IMG]
	ON [ECOMMERCE_THEMES_IMG].[COD_AFFILIATOR] = [PRODUCTS].[COD_AFFILIATOR]
		AND [ECOMMERCE_THEMES_IMG].[COD_MODEL] = [PRODUCTS].[COD_MODEL]
		AND [ECOMMERCE_THEMES_IMG].[ACTIVE] = 1
WHERE [COD_EC] = @COD_EC
AND (@ORDER_NUMBER IS NULL
OR @ORDER_NUMBER = [ODR].[CODE])
GROUP BY [ODR].[COD_ODR]
		,[ODR].[CODE]
		,[ODR].[CREATED_AT]
		,[ODR].[AMOUNT]
		,[ORDER_SITUATION].[CODE]
		,[ORDER_ITEM].[QUANTITY]
		,[PRODUCTS].[PRODUCT_NAME]
		,[ECOMMERCE_THEMES_IMG].[PATH_CONTENT]
ORDER BY [CREATED_AT] DESC;
END;

GO
IF OBJECT_ID('SP_GET_DATA_ORDER') IS NOT NULL DROP PROCEDURE SP_GET_DATA_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_GET_DATA_ORDER]     /*********************************************************************************************************************  ----------------------------------------------------------------------------------------                       Procedure Name: [SP_GET_DATA_ORDER]                       Project.......: TKPP                       ------------------------------------------------------------------------------------------                       Author                          VERSION        Date                            Description                              ------------------------------------------------------------------------------------------                       Lucas Aguiar     V1    2020-01-31       Creation                             ------------------------------------------------------------------------------------------    *********************************************************************************************************************/    (   @ORDER VARCHAR(255))  AS  BEGIN
SELECT
	[ODR].[CODE] AS [ORDER_NUMBER]
   ,[U].[IDENTIFICATION] AS [NAME]
   ,[U].[COD_ACCESS]
   ,[ODR].[AMOUNT] AS [TOTAL]
   ,[T].[CODE] AS [NSU]
   ,[ODR_SIT].[NAME] AS [SITUATION]
   ,[P].[COD_PRODUCT]
   ,[P].[PRODUCT_NAME]
   ,[ODR_ITEM].[PRICE]
   ,[ODR_ITEM].[QUANTITY]
   ,[ETI].[PATH_CONTENT]
   ,[CELL].[NAME] AS [OPERATOR]
   ,[ODR].[COMMENT]
FROM [ORDER] AS [ODR]
LEFT JOIN [ORDER_ITEM] AS [ODR_ITEM]
	ON [ODR_ITEM].[COD_ODR] = [ODR].[COD_ODR]
JOIN [ORDER_SITUATION] AS [ODR_SIT]
	ON [ODR_SIT].[COD_ORDER_SIT] = [ODR].[COD_ORDER_SIT]
LEFT JOIN [PRODUCTS] AS [P]
	ON [P].[COD_PRODUCT] = [ODR_ITEM].[COD_PRODUCT]
JOIN [USERS] AS [U]
	ON [U].[COD_USER] = [ODR].[COD_USER]
LEFT JOIN [TRANSACTION] AS [T] WITH (NOLOCK)
	ON [T].[COD_TRAN] = [ODR].[COD_TRAN]
JOIN [COMMERCIAL_ESTABLISHMENT] AS [CE]
	ON [CE].[COD_EC] = [ODR].[COD_EC]
JOIN [AFFILIATOR] AS [AFF]
	ON [AFF].[COD_AFFILIATOR] = [CE].[COD_AFFILIATOR]
LEFT JOIN [ECOMMERCE_THEMES_IMG] AS [ETI]
	ON [ETI].[COD_AFFILIATOR] = [AFF].[COD_AFFILIATOR]
		AND [ETI].[ACTIVE] = 1
		AND [ETI].[COD_WL_CONT_TYPE] = 8
		AND [ETI].[COD_MODEL] = [P].[COD_MODEL]
LEFT JOIN [CELL_OPERATOR] AS [CELL]
	ON [CELL].[COD_OPER] = [ODR_ITEM].[COD_OPERATOR]
WHERE [ODR].[CODE] = @ORDER;
END;

GO
IF OBJECT_ID('SP_LS_DATA_ORDER') IS NOT NULL DROP PROCEDURE SP_LS_DATA_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_LS_DATA_ORDER]     /*********************************************************************************************************************  ----------------------------------------------------------------------------------------                       Procedure Name: [[SP_LS_DATA_ORDER]]                       Project.......: TKPP                       ------------------------------------------------------------------------------------------                       Author                          VERSION        Date                            Description                              ------------------------------------------------------------------------------------------                       Lucas Aguiar     V1    2020-01-31       Creation                             ------------------------------------------------------------------------------------------    *********************************************************************************************************************/     (   @EC  VARCHAR(255),   @AFF VARCHAR(255))  AS  BEGIN
SELECT
	[ODR].[CODE] AS [ORDER_NUMBER]
   ,[U].[IDENTIFICATION] AS [NAME]
   ,[ODR].[AMOUNT] AS [TOTAL]
   ,[T].[CODE] AS [NSU]
   ,[ODR_SIT].[CODE]
   ,[P].[COD_PRODUCT]
   ,[P].[PRODUCT_NAME]
   ,[ODR_ITEM].[PRICE]
   ,[ODR_ITEM].[QUANTITY]
   ,[ETI].[PATH_CONTENT]
   ,[CELL].[NAME] AS [OPERATOR]
   ,[ODR].[COMMENT]
FROM [ORDER] AS [ODR]
LEFT JOIN [ORDER_ITEM] AS [ODR_ITEM]
	ON [ODR_ITEM].[COD_ODR] = [ODR].[COD_ODR]
JOIN [ORDER_SITUATION] AS [ODR_SIT]
	ON [ODR_SIT].[COD_ORDER_SIT] = [ODR].[COD_ORDER_SIT]
LEFT JOIN [PRODUCTS] AS [P]
	ON [P].[COD_PRODUCT] = [ODR_ITEM].[COD_PRODUCT]
JOIN [USERS] AS [U]
	ON [U].[COD_USER] = [ODR].[COD_USER]
LEFT JOIN [TRANSACTION] AS [T] WITH (NOLOCK)
	ON [T].[COD_TRAN] = [ODR].[COD_TRAN]
JOIN [COMMERCIAL_ESTABLISHMENT] AS [CE]
	ON [CE].[COD_EC] = [ODR].[COD_EC]
JOIN [AFFILIATOR] AS [AFF]
	ON [AFF].[COD_AFFILIATOR] = [CE].[COD_AFFILIATOR]
LEFT JOIN [ECOMMERCE_THEMES_IMG] AS [ETI]
	ON [ETI].[COD_AFFILIATOR] = [AFF].[COD_AFFILIATOR]
		AND [ETI].[ACTIVE] = 1
		AND [ETI].[COD_WL_CONT_TYPE] = 8
		AND [ETI].[COD_MODEL] = [P].[COD_MODEL]
LEFT JOIN [CELL_OPERATOR] AS [CELL]
	ON [CELL].[COD_OPER] = [ODR_ITEM].[COD_OPERATOR]
WHERE [CE].[CPF_CNPJ] = @EC
AND [AFF].[CPF_CNPJ] = @AFF
AND [ODR].[CODE] IS NOT NULL
ORDER BY ODR.CREATED_AT DESC;
END;
GO
GO
IF OBJECT_ID('SP_LS_ORDERS_DISPATCHED') IS NOT NULL DROP PROCEDURE SP_LS_ORDERS_DISPATCHED;
GO

CREATE PROCEDURE [DBO].[SP_LS_ORDERS_DISPATCHED]              /*----------------------------------------------------------------------------------------                                   Procedure Name: [SP_LS_ORDERS_DISPATCHED]                                   Project.......: TKPP                                   ------------------------------------------------------------------------------------------                                   Author                          VERSION        Date                            Description                                          ------------------------------------------------------------------------------------------                                   Caike Uchôa                       V1         2020-02-13                         Creation                                     ------------------------------------------------------------------------------------------*/                   AS            BEGIN
SELECT
	PICKING_ORDER AS ORDER_NUMBER
   ,[ORDER].CODE
   ,[ORDER].COD_ORDER_SIT AS COD_ORDER_SIT
   ,[ORDER].COD_EC
   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH AS COD_DEPTO
   ,[ORDER].COD_USER
   ,USERS.COD_COMP
   ,PRODUCTS.COD_MODEL
   ,PRODUCTS.COD_PRODUCT
   ,[ORDER_ITEM].COD_OPERATOR AS COD_OPER
   ,COUNT(ORDER_ITEM.COD_ODR_ITEM) AS QTD_ITEMS
   ,PRODUCTS.SKU
   ,SEGMENTS_GROUP.[GROUP]
   ,[ORDER].COD_ODR
FROM [ORDER]
INNER JOIN ORDER_SITUATION
	ON ORDER_SITUATION.COD_ORDER_SIT = [ORDER].COD_ORDER_SIT
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_EC = [ORDER].COD_EC
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
INNER JOIN USERS
	ON USERS.COD_USER = [ORDER].COD_USER
INNER JOIN ORDER_ITEM
	ON ORDER_ITEM.COD_ODR = [ORDER].COD_ODR
INNER JOIN PRODUCTS
	ON PRODUCTS.COD_PRODUCT = ORDER_ITEM.COD_PRODUCT
LEFT JOIN ORDER_EQUIPMENT
	ON ORDER_EQUIPMENT.COD_ODR_ITEM = ORDER_ITEM.COD_ODR_ITEM
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = [ORDER].COD_EC
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
INNER JOIN SEGMENTS_GROUP
	ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
LEFT JOIN ACQUIRER
	ON ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP
WHERE [ORDER_SITUATION].COD_ORDER_SIT IN (9, 10)
AND [ORDER].COD_SITUATION = 1
AND ORDER_EQUIPMENT.COD_ODR_ITEM IS NULL
GROUP BY [ORDER].PICKING_ORDER
		,[ORDER].CODE
		,[ORDER].COD_ORDER_SIT
		,[ORDER].COD_EC
		,[DEPARTMENTS_BRANCH].COD_DEPTO_BRANCH
		,[ORDER].COD_USER
		,[USERS].COD_COMP
		,[PRODUCTS].COD_MODEL
		,PRODUCTS.COD_PRODUCT
		,[ORDER_ITEM].COD_OPERATOR
		,PRODUCTS.SKU
		,SEGMENTS_GROUP.[GROUP]
		,[ORDER].COD_ODR
END

GO
GO
IF OBJECT_ID('SP_LS_PENDING_ORDER') IS NOT NULL DROP PROCEDURE SP_LS_PENDING_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_LS_PENDING_ORDER]                            
                
/*****************************************************************************************************************************  
----------------------------------------------------------------------------------------                           
    Procedure Name: [SP_LS_PENDING_ORDER]                           
    Project.......: TKPP                           
    ------------------------------------------------------------------------------------------                           
    Author                          VERSION        Date                            Description                                  
    ------------------------------------------------------------------------------------------                           
    Lucas Aguiar     V1    2020-02-03       Creation                                 
    ------------------------------------------------------------------------------------------            
*****************************************************************************************************************************/            
                           
AS  
BEGIN


SELECT
	[CE].[name] AS [EC_NAME]
   ,[CE].[EMAIL]
   ,[CE].[CPF_CNPJ]
   ,[SEX_TYPE].[CODE] AS [SEX]
   ,[TE].[CODE] AS [TYPE_EC]
   ,[CE].[MUNICIPAL_REGISTRATION]
   ,[CE].[STATE_REGISTRATION]
   ,[CONTACT_BRANCH].[DDI]
   ,[CONTACT_BRANCH].[DDD]
   ,[CONTACT_BRANCH].[number]
   ,[ODR].[CODE] AS [ORDER_NUMBER]
   ,[ODR].[CREATED_AT] AS [ORDER_DATE]
   ,[ODR_ADD].[CEP]
   ,[ODR_ADD].[COMPLEMENT]
   ,[ODR_ADD].[ADDRESS]
   ,[ODR_ADD].[number] AS [ADDR_NUMBER]
   ,[NEIGHBORHOOD].[name] AS [NEIGHBORHOOD]
   ,STATE.[UF] AS [UF]
   ,[CITY].[name] AS [CITY]
   ,[COUNTRY].[INITIALS]
   ,[ORDER_ITEM].[PRICE]
   ,[ORDER_ITEM].[QUANTITY]
   ,[PRODUCTS].[SKU]
   ,[CELL_OPERATOR].[CODE] AS [OPERATOR]
   ,SUBSTRING([COMPANY].[name], 0, 6) AS [COMPANY]
   ,[TRANSACTION].[PLOTS] AS [PLOTS]
   ,IIF([EQUIPMENT_MODEL].[COD_MODEL_GROUP] = 1, 1, 0) AS [HAS_CHIP]
   ,[TRANSACTION].[BRAND]
   ,[TRANSIRE_PRODUCT].[AMOUNT] AS [TRANSIRE_AMOUNT]
   ,[TRANSACTION].[CODE] AS [NSU]
FROM [COMMERCIAL_ESTABLISHMENT] AS [CE]
JOIN [TYPE_ESTAB] AS [TE]
	ON [TE].[COD_TYPE_ESTAB] = [CE].[COD_TYPE_ESTAB]
JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_EC] = [CE].[COD_EC]
		AND [BRANCH_EC].[ACTIVE] = 1
JOIN [CONTACT_BRANCH]
	ON [CONTACT_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [CONTACT_BRANCH].[ACTIVE] = 1
		AND [CONTACT_BRANCH].[COD_CONT] = (SELECT TOP 1
				[COD_CONT]
			FROM [CONTACT_BRANCH]
			WHERE [CONTACT_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
			AND [CONTACT_BRANCH].[ACTIVE] = 1
			ORDER BY 1 DESC)
JOIN [ORDER] AS [ODR]
	ON [ODR].[COD_EC] = [CE].[COD_EC]
		AND [ODR].[COD_ORDER_SIT] = 2
		AND [ODR].[COD_TRAN] IS NOT NULL
JOIN [ORDER_ADDRESS] AS [ODR_ADD]
	ON [ODR_ADD].[COD_ODR] = [ODR].[COD_ODR]
		AND [ODR_ADD].[ACTIVE] = 1
JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ODR_ADD].[COD_NEIGH]
JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
JOIN STATE
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
JOIN [ORDER_ITEM]
	ON [ORDER_ITEM].[COD_ODR] = [ODR].[COD_ODR]
JOIN [PRODUCTS]
	ON [PRODUCTS].[COD_PRODUCT] = [ORDER_ITEM].[COD_PRODUCT]
JOIN [CELL_OPERATOR]
	ON [CELL_OPERATOR].[COD_OPER] = [ORDER_ITEM].[COD_OPERATOR]
JOIN [SEX_TYPE]
	ON [SEX_TYPE].[COD_SEX] = [CE].[COD_SEX]
JOIN [COMPANY]
	ON [COMPANY].[COD_COMP] = [CE].[COD_COMP]
JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].[COD_TRAN] = [ODR].[COD_TRAN]
JOIN [EQUIPMENT_MODEL]
	ON [EQUIPMENT_MODEL].[COD_MODEL] = [PRODUCTS].[COD_MODEL]
JOIN [TRANSIRE_PRODUCT]
	ON [TRANSIRE_PRODUCT].[COD_TRANSIRE_PRD] = [ORDER_ITEM].[COD_TRANSIRE_PRD]
		AND [TRANSIRE_PRODUCT].[ACTIVE] = 1
GROUP BY [CE].[name]
		,[CE].[EMAIL]
		,[CE].[CPF_CNPJ]
		,[SEX_TYPE].[CODE]
		,[TE].[CODE]
		,[CE].[MUNICIPAL_REGISTRATION]
		,[CE].[STATE_REGISTRATION]
		,[CONTACT_BRANCH].[DDI]
		,[CONTACT_BRANCH].[DDD]
		,[CONTACT_BRANCH].[number]
		,[ODR].[CODE]
		,[ODR].[CREATED_AT]
		,[ODR_ADD].[CEP]
		,[ODR_ADD].[COMPLEMENT]
		,[ODR_ADD].[ADDRESS]
		,[ODR_ADD].[number]
		,[NEIGHBORHOOD].[name]
		,STATE.[UF]
		,[CITY].[name]
		,[COUNTRY].[INITIALS]
		,[ORDER_ITEM].[PRICE]
		,[ORDER_ITEM].[QUANTITY]
		,[PRODUCTS].[SKU]
		,[CELL_OPERATOR].[CODE]
		,[COMPANY].[name]
		,[TRANSACTION].[PLOTS]
		,IIF([EQUIPMENT_MODEL].[COD_MODEL_GROUP] = 1, 1, 0)
		,[TRANSACTION].[BRAND]
		,[TRANSIRE_PRODUCT].[AMOUNT]
		,[TRANSACTION].[CODE]
ORDER BY [ODR].[CREATED_AT] ASC;


END;

GO
IF OBJECT_ID('SP_LS_PRODUCTS') IS NOT NULL DROP PROCEDURE SP_LS_PRODUCTS;
GO
CREATE PROCEDURE SP_LS_PRODUCTS    AS   
BEGIN
SELECT
	COD_PRODUCT
   ,CREATED_AT
   ,PRODUCT_NAME
   ,NICKNAME
   ,DESCRIPTION
   ,SKU
   ,PRICE
   ,ACTIVE
   ,ALTER_DATE
FROM PRODUCTS
WHERE ACTIVE = 1
END;

GO
IF OBJECT_ID('SP_LS_PRODUCTS_SALES') IS NOT NULL DROP PROCEDURE SP_LS_PRODUCTS_SALES;
GO
CREATE PROCEDURE [dbo].[SP_LS_PRODUCTS_SALES]      
/*----------------------------------------------------------------------------------------      
Procedure Name: SP_LS_PRODUCTS_SALES      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Fernando Henrique Francesco O.  V1     27/08/2018             CREATION      
------------------------------------------------------------------------------------------*/      
(      
    @COD_COMPANY INT      
   ,@COD_AFFILIATOR INT      
)      
AS      
      
    DECLARE @QUERY NVARCHAR(MAX);
       
      
BEGIN

SET @QUERY =
'SELECT [PRODUCTS_COMPANY].COD_COMP       
     ,[PRODUCTS_AFFILIATOR].COD_AFFILIATOR       
     ,[PRODUCTS].COD_PR AS COD_PRODUCT      
     ,[EQUIPMENT_MODEL].COD_MODEL      
     ,[PRODUCTS].NAME       
     ,[PRODUCTS].SHORT_DESCRIPTION      
     ,[PRODUCTS].DESCRIPTION       
     ,[PRODUCTS].SKU      
     ,ISNULL([PRODUCTS_AFFILIATOR].PRICE,0) AS PRICE     
     ,ISNULL([PRODUCTS_AFFILIATOR].DISCOUNT,0) AS DISCOUNT      
     ,ISNULL([PRODUCTS_AFFILIATOR].DISCOUNT_PERCENT,0)  AS DISCOUNT_PERCENT     
     ,[PRODUCTS].DEFAULT_IMAGEM      
     ,[PRODUCTS].ACTIVE       
    FROM [PRODUCTS]      
    INNER JOIN [PRODUCTS_AFFILIATOR] ON [PRODUCTS].COD_PR = [PRODUCTS_AFFILIATOR].COD_PR_COMPANY      
    INNER JOIN [PRODUCTS_COMPANY] ON [PRODUCTS].COD_PR = [PRODUCTS_COMPANY].COD_PR     
    INNER JOIN [EQUIPMENT_MODEL] ON [PRODUCTS].COD_MODEL = [EQUIPMENT_MODEL].COD_MODEL       
    WHERE [PRODUCTS].ACTIVE = 1      
    AND [PRODUCTS_AFFILIATOR].ACTIVE = 1      
          AND [PRODUCTS_COMPANY].COD_COMP = ' + CAST(@COD_COMPANY AS VARCHAR)
      
      
    IF @COD_AFFILIATOR IS NOT NULL
SET @QUERY = @QUERY + ' AND [PRODUCTS_AFFILIATOR].COD_AFFILIATOR = ' + CAST(@COD_AFFILIATOR AS VARCHAR)

SET @QUERY = @QUERY + ' order by [PRODUCTS].DEFAULT_IMAGEM  desc'
EXEC sp_executesql @QUERY
				  ,N'        
     @COD_COMPANY INT,        
     @COD_AFFILIATOR INT        
     '
				  ,@COD_COMPANY = @COD_COMPANY
				  ,@COD_AFFILIATOR = @COD_AFFILIATOR

END;

GO
IF OBJECT_ID('SP_REG_ECOMMERCE_PRODUCT') IS NOT NULL DROP PROCEDURE SP_REG_ECOMMERCE_PRODUCT;
GO
CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_PRODUCT]         /*----------------------------------------------------------------------------------------      Procedure Name: [SP_REG_ECOMMERCE_ABOUT]      Project.......: TKPP      ------------------------------------------------------------------------------------------      Author              VERSION        Date      Description      ------------------------------------------------------------------------------------------      Lucas Aguiar  v1      2019-11-07    Procedure para o registro o contúdp da tela "about" do Ecommerce    ------------------------------------------------------------------------------------------*/        (     @THEMES_IMG [TP_THEMES_IMG] READONLY,     @PRODUCTS [WL_PRODUCTS] READONLY    )    AS    BEGIN
UPDATE ECOMMERCE_THEMES_IMG
SET ACTIVE = 0
   ,MODIFY_DATE = current_timestamp
   ,COD_USER_ALT = THEMES_IMG.COD_USER
FROM ECOMMERCE_THEMES_IMG
JOIN @THEMES_IMG THEMES_IMG
	ON THEMES_IMG.COD_AFF = ECOMMERCE_THEMES_IMG.COD_AFFILIATOR
	AND ECOMMERCE_THEMES_IMG.ACTIVE = 1
WHERE ECOMMERCE_THEMES_IMG.COD_WL_CONT_TYPE = THEMES_IMG.COD_WL_CONT_TYPE
AND ((THEMES_IMG.COD_MODEL IS NOT NULL
AND ECOMMERCE_THEMES_IMG.COD_MODEL = THEMES_IMG.COD_MODEL)
OR (THEMES_IMG.COD_MODEL IS NULL
AND ECOMMERCE_THEMES_IMG.COD_MODEL IS NULL));
INSERT INTO ECOMMERCE_THEMES_IMG (COD_USER_CAD, COD_AFFILIATOR, COD_WL_CONT_TYPE, PATH_CONTENT, COD_MODEL)
	SELECT
		THEMES_IMG.COD_USER
	   ,THEMES_IMG.COD_AFF
	   ,THEMES_IMG.COD_WL_CONT_TYPE
	   ,THEMES_IMG.PATH_CONTENT
	   ,THEMES_IMG.COD_MODEL
	FROM @THEMES_IMG THEMES_IMG;
UPDATE PRODUCTS
SET ACTIVE = 0
   ,COD_USER_ALTER = PROD.COD_USER
   ,ALTER_DATE = current_timestamp
FROM PRODUCTS
JOIN @PRODUCTS PROD
	ON PROD.COD_AFF = PRODUCTS.COD_AFFILIATOR
WHERE PRODUCTS.ACTIVE = 1
INSERT INTO PRODUCTS (COD_AFFILIATOR, COD_MODEL, COD_USER, CREATED_AT, PRODUCT_NAME, SKU, PRICE)
	SELECT
		PROD.COD_AFF
	   ,PROD.COD_MODEL
	   ,PROD.COD_USER
	   ,current_timestamp
	   ,PROD.PRODUCT_NAME
	   ,PROD.SKU
	   ,PROD.PRICE
	FROM @PRODUCTS PROD
END;

GO
GO
IF OBJECT_ID('SP_REG_EQUIP_ASS_PICKING') IS NOT NULL DROP PROCEDURE SP_REG_EQUIP_ASS_PICKING;
GO
CREATE PROCEDURE SP_REG_EQUIP_ASS_PICKING  
(  
 @TP_REG_EQUIP_PICKING TP_REG_EQUIP_PICKING READONLY  
 )   
 AS  
 BEGIN
  
 DECLARE @COD_AC INT;
  
DECLARE @THROW_MESSAGE VARCHAR(255);
  
DECLARE @QTY_EQUIPS INT = ( SELECT
		COUNT(*)
	FROM @TP_REG_EQUIP_PICKING);

IF @QTY_EQUIPS = 0
THROW 70001, 'SERIAL LIST EMPTY', 1


SELECT
	*
FROM EQUIPMENT
WHERE SERIAL IN (SELECT
		SERIAL
	FROM @TP_REG_EQUIP_PICKING)

IF @@rowcount > 0
THROW 70002, 'SERIAL ALREADY REGISTERED', 1;

INSERT INTO EQUIPMENT (CREATED_AT,
SERIAL,
COD_MODEL,
COD_COMP,
ACTIVE,
CHIP,
PUK,
COD_OPER,
TID)
	SELECT
		current_timestamp
	   ,SERIAL
	   ,CODMODEL
	   ,COMPANY
	   ,1
	   ,CHIP
	   ,PUK
	   ,OPERATOR
	   ,NEXT VALUE FOR SEQ_TID
	FROM @TP_REG_EQUIP_PICKING TP

IF @@rowcount <> @QTY_EQUIPS
THROW 70003, 'FAILED TO INSERT EQUIPMENTS', 1;


SELECT
	EQUIPMENT.COD_EQUIP
   ,EQUIPMENT.SERIAL
   ,MODEL_GROUP.CODE
   ,TP.COD_COMP
   ,TP.COD_DEPTO
   ,TP.COD_USER INTO #TBL_EQUIPMENTS_TO_INSERT_TID
FROM EQUIPMENT
INNER JOIN EQUIPMENT_MODEL
	ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL
INNER JOIN MODEL_GROUP
	ON MODEL_GROUP.COD_MODEL_GROUP = EQUIPMENT_MODEL.COD_MODEL_GROUP
INNER JOIN @TP_REG_EQUIP_PICKING TP
	ON TP.SERIAL = EQUIPMENT.SERIAL


DECLARE @SERIAIS_TO_RECEIVE_TID AS CURSOR;
DECLARE @COD_EQUIP INT;
DECLARE @SERIAL VARCHAR(100);
DECLARE @CODE VARCHAR(100);
DECLARE @COD_COMP INT;
DECLARE @COD_DEPTO INT;
DECLARE @COD_USER INT;

DECLARE @COD_DATA_EQUIP INT;
DECLARE @TID VARCHAR(255);

SET @SERIAIS_TO_RECEIVE_TID = CURSOR FOR SELECT
	COD_EQUIP
   ,SERIAL
   ,CODE
   ,COD_COMP
   ,COD_DEPTO
   ,COD_USER
FROM #TBL_EQUIPMENTS_TO_INSERT_TID
WHERE CODE = 'GPRS'

SELECT
	COUNT(*)
FROM DATA_TID_AVAILABLE_EC

OPEN @SERIAIS_TO_RECEIVE_TID

FETCH NEXT FROM @SERIAIS_TO_RECEIVE_TID INTO
@COD_EQUIP
, @SERIAL
, @CODE
, @COD_COMP
, @COD_DEPTO
, @COD_USER;

WHILE @@fetch_status = 0
BEGIN

SELECT TOP 1
	@COD_AC =
	(CASE
		WHEN TYPE_ESTAB.CODE = 'PF' THEN 10
		ELSE ACQUIRER.COD_AC
	END)
FROM @TP_REG_EQUIP_PICKING TP
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = TP.COD_DEPTO
JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
JOIN SEGMENTS_GROUP
	ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
JOIN ACQUIRER
	ON ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP
INNER JOIN TYPE_ESTAB
	ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB

SELECT
	@COD_DATA_EQUIP = COD_DATA_EQUIP
   ,@TID = TID
FROM DATA_TID_AVAILABLE_EC
WHERE COD_AC = @COD_AC
AND TYPE_KEY_AC = 'PRESENCIAL'
AND AVAILABLE = 1
AND ACTIVE = 1

IF @TID IS NULL
THROW 70004, 'TID NOT AVAILABLE', 1;

INSERT INTO DATA_EQUIPMENT_AC ([CREATED_AT]
, [COD_EQUIP]
, [COD_COMP]
, [COD_AC]
, [name]
, [CODE]
, [ACTIVE])
	VALUES (current_timestamp, @COD_EQUIP, @COD_COMP, @COD_AC, 'TID', @TID, 1);

IF @@rowcount < 1
BEGIN
SET @THROW_MESSAGE = 'FAILED TO INSERT THE TID TO EQUIPMENT ' + @SERIAL;
  
 THROW 70005, @THROW_MESSAGE, 1;
  
END
UPDATE DATA_TID_AVAILABLE_EC
SET AVAILABLE = 0
   ,ACTIVE = 0
WHERE COD_DATA_EQUIP = @COD_DATA_EQUIP;

IF @@rowcount < 1
BEGIN
SET @THROW_MESSAGE = 'FAILED DISABLE THE TID TO EQUIPMENT ' + @SERIAL;
  
 THROW 70006, @THROW_MESSAGE, 1;
  
END

INSERT INTO ROUTE_ACQUIRER (COD_USER, COD_EQUIP, ACTIVE, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
	SELECT
		TP.COD_USER
	   ,TID.COD_EQUIP
	   ,1
	   ,CONF_TYPE
	   ,COD_BRAND
	   ,COD_AC
	   ,COD_SOURCE_TRAN
	FROM ROUTE_ACQUIRER_DEFAULT
	INNER JOIN #TBL_EQUIPMENTS_TO_INSERT_TID TID
		ON TID.CODE = 'GPRS'
			AND TID.COD_EQUIP = @COD_EQUIP
	INNER JOIN @TP_REG_EQUIP_PICKING TP
		ON TP.SERIAL = TID.SERIAL
	WHERE COD_AC = @COD_AC

IF @@rowcount < 1
BEGIN
SET @THROW_MESSAGE = 'FAILED TO INSERT THE ROUTE TO EQUIPMENT ' + @SERIAL;
  
 THROW 70004, @THROW_MESSAGE , 1;
  
END

INSERT INTO ORDER_EQUIPMENT (CREATED_AT, ORDER_NUMBER, SERIAL, COD_EQUIP, COD_ODR_ITEM, COD_ORDER_SIT)
	SELECT DISTINCT
		current_timestamp
	   ,TP.ORDER_NUMBER
	   ,TP.SERIAL
	   ,EQUIPMENT.COD_EQUIP
	   ,ORDER_ITEM.COD_ODR_ITEM
	   ,[ORDER].COD_ORDER_SIT
	FROM @TP_REG_EQUIP_PICKING TP
	INNER JOIN [ORDER]
		ON [ORDER].COD_ODR = TP.ORDER_CODE
	INNER JOIN ORDER_ITEM
		ON [ORDER].COD_ODR = ORDER_ITEM.COD_ODR
	INNER JOIN PRODUCTS
		ON PRODUCTS.COD_PRODUCT = ORDER_ITEM.COD_PRODUCT
			AND SKU = PARTNUMBER
	INNER JOIN EQUIPMENT
		ON EQUIPMENT.SERIAL = TP.SERIAL
	WHERE TP.SERIAL = @SERIAL


IF @@rowcount < 1
BEGIN
SET @THROW_MESSAGE = 'DEMONHO ' + @SERIAL;
  
 THROW 70004, @THROW_MESSAGE , 1;
  
END
  
  
FETCH NEXT FROM @SERIAIS_TO_RECEIVE_TID INTO  
@COD_EQUIP  
, @SERIAL  
, @CODE  
, @COD_COMP  
, @COD_DEPTO  
, @COD_USER;
  
  
END;

INSERT INTO ASS_DEPTO_EQUIP (COD_EQUIP, COD_DEPTO_BRANCH, ACTIVE, COD_USER)
	SELECT
		EQUIPMENT.COD_EQUIP
	   ,TP.COD_DEPTO
	   ,1
	   ,TP.COD_USER
	FROM @TP_REG_EQUIP_PICKING TP
	INNER JOIN EQUIPMENT
		ON EQUIPMENT.SERIAL = TP.SERIAL
END

GO
IF OBJECT_ID('SP_REG_PRODUCTS') IS NOT NULL DROP PROCEDURE SP_REG_PRODUCTS;
GO
CREATE PROCEDURE [dbo].[SP_REG_PRODUCTS]                /*----------------------------------------------------------------------------------------                Procedure Name: [SP_REG_PRODUCTS]                Project.......: TKPP                ------------------------------------------------------------------------------------------                Author                            VERSION        Date                          Description                ------------------------------------------------------------------------------------------                Fernando Henrique Francesco de O V1     28/08/2018              CREATION                Elir Ribeiro     v2     21/09/2019              Changed            ------------------------------------------------------------------------------------------*/                 (                     @COD_MODEL INT                    ,@NAME VARCHAR(200)                 ,@SHORT_DESCRIPTION  VARCHAR(100)                    ,@DESCRIPTION VARCHAR(200)                 ,@SKU VARCHAR(255) = NULL                 ,@DEFAULT_IMAGEM VARCHAR(255)                 ,@PRICE_DEFAULT decimal(22,6) NULL                    ,@COD_USER INT,           @COD_AFF VARCHAR(100),           @PRICE_FINAL decimal(22,6)                )                AS                  DECLARE @COUNT INT;
              DECLARE @IDPRODUCTS INT;
                              BEGIN
SET @COUNT = 0;
SELECT
	@COUNT = COUNT(*)
FROM PRODUCTS
WHERE PRODUCTS.PRODUCT_NAME = @NAME;
IF @SKU = NULL
SET @SKU = CAST(NEWID() AS VARCHAR);
IF @COUNT > 0
THROW 70005, 'PRODUCTS ALREADY REGISTERED', 1;
BEGIN
INSERT INTO [DBO].[PRODUCTS] ([COD_MODEL], [name], [SHORT_DESCRIPTION], [DESCRIPTION], [SKU], [DEFAULT_IMAGEM], [PRICE_DEFAULT], [ACTIVE], [COD_USER_CREAT], [MODIFY_DATE], [COD_USER_MODIFY])
	VALUES (@COD_MODEL, @NAME, @SHORT_DESCRIPTION, @DESCRIPTION, @SKU, @DEFAULT_IMAGEM, @PRICE_DEFAULT, 1, @COD_USER, GETDATE(), @COD_USER)
END
IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER [PRODUCTS] ', 1;
SELECT
	@@identity AS COD_PR
SELECT
	@IDPRODUCTS = @@identity
EXEC SP_REG_PRODUCTS_COMPANY 8
							,@IDPRODUCTS
							,@COD_USER
END;

GO
IF OBJECT_ID('SP_UP_PRODUCTS') IS NOT NULL DROP PROCEDURE SP_UP_PRODUCTS;
GO
CREATE PROCEDURE [dbo].[SP_UP_PRODUCTS]                    /*----------------------------------------------------------------------------------------                    Procedure Name: SP_UP_PRODUCTS                    Project.......: TKPP                    ------------------------------------------------------------------------------------------                    Author                          VERSION             Date                       Description                    ------------------------------------------------------------------------------------------                    Fernando Henrique F. de O     V1     19/09/2018             Creation                    Elir Ribeiro  v2               26/09/2018     Changed                     Elir Ribeiro v3             27/09/2018     Changed                Elir Ribeiro v4             16/10/2018     changed    ------------------------------------------------------------------------------------------*/                    (                    @COD_PR int                    ,@PRICE_DEFAULT decimal(22,6),              @SHORT_DESCRIPTION VARCHAR(100),              @DESCRIPTION VARCHAR(100),              @DEFAULT_IMAGEM VARCHAR(100),                    @COD_USER_MODIFY int,        @NAME VARCHAR(100),      @COD_AFF VARCHAR(100),            @PRICE_FINAL decimal(22,6)                                            )                    AS                    BEGIN
                    DECLARE @IMGFINAL VARCHAR(100)
      IF @DEFAULT_IMAGEM = '' SELECT
	@IMGFINAL = DEFAULT_IMAGEM
FROM [PRODUCTS]
WHERE COD_PR = @COD_PR
ELSE
SET @IMGFINAL = @DEFAULT_IMAGEM
UPDATE [DBO].[PRODUCTS]
SET [PRICE_DEFAULT] = @PRICE_DEFAULT
   ,[MODIFY_DATE] = GETDATE()
   ,[COD_USER_MODIFY] = @COD_USER_MODIFY
   ,[SHORT_DESCRIPTION] = @SHORT_DESCRIPTION
   ,[DESCRIPTION] = @DESCRIPTION
   ,[name] = @NAME
   ,[DEFAULT_IMAGEM] = @IMGFINAL
WHERE COD_PR = @COD_PR
IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PRODUCTS]', 1
END;

GO
IF OBJECT_ID('SP_UP_ORDER_LOT') IS NOT NULL DROP PROCEDURE SP_UP_ORDER_LOT;
GO
CREATE PROCEDURE [DBO].[SP_UP_ORDER_LOT]                                              /*********************************************************************************************************************            ----------------------------------------------------------------------------------------                                 Procedure Name: [SP_UP_BANK_DETAILS_EC]                                 Project.......: TKPP                                 ------------------------------------------------------------------------------------------                                 Author                          VERSION        Date                            Description                                        ------------------------------------------------------------------------------------------                                 Lucas Aguiar     V1   2020-02-04       Creation                                       ------------------------------------------------------------------------------------------            *********************************************************************************************************************/                                         (             @CODE_ORDER [CODE_TYPE] READONLY,              @COMMENT    VARCHAR(500) = NULL,              @ORDER_SIT  VARCHAR(255))            AS            BEGIN
                                                      DECLARE                @COD_SITUATION INT;
SELECT
	@COD_SITUATION = [ORDER_SITUATION].[COD_ORDER_SIT]
FROM [ORDER_SITUATION]
WHERE [name] = @ORDER_SIT;
IF (@ORDER_SIT = 'PREPARING')
BEGIN
UPDATE [ODR]
SET [ODR].[COD_ORDER_SIT] = @COD_SITUATION
   ,PICKING_ORDER = (SELECT
			SUBSTRING([COMPANY].[name], 0, 6)
		FROM COMPANY)
	+ '_' + CONVERT(VARCHAR(150), [ODR].CODE)
FROM [TRANSACTION]
JOIN [ORDER] [ODR]
	ON [ODR].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
	AND [ODR].[COD_ORDER_SIT] = 2
JOIN @CODE_ORDER [TP]
	ON [TP].[CODE] = [ODR].[CODE]
WHERE [TRANSACTION].[COD_SITUATION] = 3;
UPDATE [RESUME_TRACKING]
SET [PREPARING] = 1
   ,[DATE_PREPARING] = current_timestamp
FROM [RESUME_TRACKING]
JOIN [ORDER] [ODR]
	ON [ODR].[COD_ODR] = [RESUME_TRACKING].[COD_ODR]
JOIN @CODE_ORDER [TP]
	ON [TP].[CODE] = [ODR].[CODE];
END;
INSERT INTO [TRACKING_ORDER] ([COD_ODR], [CREATED_AT], [COD_ORDER_SIT], [SITUATION_ORDER], [COD_USER], [USERS], [COMMENT], [MODIFY_DATE], [COD_TRAN], [NSU], [BRAND], [PLOTS], [COD_SITUATION])
	SELECT
		[ORDER].[COD_ODR]
	   ,current_timestamp
	   ,[ORDER].[COD_ORDER_SIT]
	   ,[ORDER_SITUATION].[CODE]
	   ,[ORDER].[COD_USER]
	   ,[USERS].[COD_ACCESS]
	   ,@COMMENT
	   ,NULL
	   ,[ORDER].[COD_TRAN]
	   ,[REPORT_TRANSACTIONS].[TRANSACTION_CODE]
	   ,[REPORT_TRANSACTIONS].[BRAND]
	   ,[REPORT_TRANSACTIONS].[PLOTS]
	   ,[ORDER].[COD_SITUATION]
	FROM [ORDER]
	JOIN @CODE_ORDER AS [TP]
		ON [TP].[CODE] = [ORDER].[CODE]
	JOIN [ORDER_SITUATION]
		ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
	LEFT JOIN [USERS]
		ON [USERS].[COD_USER] = [ORDER].[COD_USER]
	LEFT JOIN [REPORT_TRANSACTIONS]
		ON [REPORT_TRANSACTIONS].[COD_TRAN] = [ORDER].[COD_TRAN];
END;    --SELECT  -- *  --FROM [ORDER]  --ORDER BY 1 DESC    --UPDATE [ORDER] SET PICKING_ORDER = 'CELER_20223' WHERE PICKING_ORDER = 'Celer20223'    SELECT   *  FROM [ORDER]  INNER JOIN WEBHOOK_PICKING   ON WEBHOOK_PICKING.ORDER_NUMEBER = [ORDER].PICKING_ORDER  WHERE [ORDER].PICKING_ORDER = 'CELER_20223'  ORDER BY 1 DESC
GO
IF OBJECT_ID('SP_UP_TRACKING_ORDER') IS NOT NULL DROP PROCEDURE SP_UP_TRACKING_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_UP_TRACKING_ORDER](  
 @COD_ODR INT)  
AS  
BEGIN

INSERT INTO [TRACKING_ORDER] ([COD_ODR],
[CREATED_AT],
[COD_ORDER_SIT],
[SITUATION_ORDER],
[COD_USER],
[USERS],
[COMMENT],
[MODIFY_DATE],
[COD_TRAN],
[NSU],
[BRAND],
[PLOTS],
[COD_SITUATION])
	SELECT
		@COD_ODR
	   ,current_timestamp
	   ,[ORDER].[COD_ORDER_SIT]
	   ,[ORDER_SITUATION].[CODE]
	   ,[ORDER].[COD_USER]
	   ,[USERS].[COD_ACCESS]
	   ,''
	   ,NULL
	   ,[ORDER].[COD_TRAN]
	   ,[REPORT_TRANSACTIONS].[TRANSACTION_CODE]
	   ,[REPORT_TRANSACTIONS].[BRAND]
	   ,[REPORT_TRANSACTIONS].[PLOTS]
	   ,[ORDER].[COD_SITUATION]
	FROM [ORDER]
	INNER JOIN [ORDER_SITUATION]
		ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
	LEFT JOIN [USERS] --SÓ TERÁ ALTERAÇÃO DE USUÁRIO QUANDO EXISTIR INTERFERÊNCIA EXTERNA NO PEDIDO      
		ON [USERS].[COD_USER] = [ORDER].[COD_USER]
	LEFT JOIN [REPORT_TRANSACTIONS] --SÓ TERÁ TRANSAÇÃO AO CONFIRMAR O PAGAMENTO      
		ON [REPORT_TRANSACTIONS].[COD_TRAN] = [ORDER].[COD_TRAN]
	WHERE [ORDER].[COD_ODR] = @COD_ODR;

IF ((SELECT
			COUNT(*)
		FROM [RESUME_TRACKING]
		WHERE [COD_ODR] = @COD_ODR)
	= 0)
BEGIN
INSERT INTO [RESUME_TRACKING] ([COD_ODR],
[DATE_PAYMENT_PENDING],
[PAYMENT_PENDING])
	VALUES (@COD_ODR, current_timestamp, 1);
END;
ELSE
EXEC [SP_UP_RESUME_TRACKING] @COD_ODR;
END;

GO

GO
IF OBJECT_ID('SP_UP_RESUME_TRACKING') IS NOT NULL DROP PROCEDURE SP_UP_RESUME_TRACKING;
GO
CREATE PROCEDURE SP_UP_RESUME_TRACKING     (     @COD_ODR INT    )    AS    BEGIN
      DECLARE @QUERY NVARCHAR(MAX);
SELECT
	@QUERY = 'UPDATE RESUME_TRACKING SET ' + name + ' = 1, DATE_' + name + ' = CURRENT_TIMESTAMP WHERE COD_ODR = @COD_ODR'
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.RESUME_TRACKING')
AND name LIKE (SELECT
		REPLACE([ORDER_SITUATION].name, ' ', '_')
	FROM ORDER_SITUATION
	INNER JOIN [ORDER]
		ON [ORDER].COD_ORDER_SIT = ORDER_SITUATION.COD_ORDER_SIT
		AND [ORDER].COD_ODR = @COD_ODR)
EXEC sp_executesql @QUERY
				  ,N'    @COD_ODR INT'
				  ,@COD_ODR = @COD_ODR
END;

GO

ALTER PROCEDURE [dbo].[SP_REG_PROV_PASS_USER]      
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_REG_PROV_PASS_USER]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author VERSION Date Description      
------------------------------------------------------------------------------------------      
Kennedy Alef V1 27/07/2018 Creation      
------------------------------------------------------------------------------------------*/      
(      
@CODACESS VARCHAR(100),      
@ACCESS_KEY VARCHAR(200),      
@VALUE VARCHAR(200),      
@REQUIRED INT,      
@COD_AFFILIATOR INT = NULL,    
@EMPTY_RETURN INT = NULL    
)      
AS      
DECLARE @LOGIN VARCHAR(250);
    
      
DECLARE @NAME VARCHAR(250);
    
      
DECLARE @EMAIL VARCHAR(250) = NULL;
    
      
DECLARE @PASSPROV VARCHAR(100) = NULL;
    
      
DECLARE @CODUSER INT = NULL;
    
      
DECLARE @SUBDOMAIN VARCHAR(100);
    
      
DECLARE @COD_AFF_FIND INT = NULL;
    
      
BEGIN
    
      
IF @COD_AFFILIATOR IS NULL
SET @COD_AFFILIATOR = 0;
SELECT
	@PASSPROV = PROVISORY_PASS_USER.value
   ,@EMAIL = EMAIL
   ,@NAME = IDENTIFICATION
   ,@LOGIN = USERS.COD_ACCESS
   ,@SUBDOMAIN = AFFILIATOR.SUBDOMAIN
FROM PROVISORY_PASS_USER
INNER JOIN USERS
	ON USERS.COD_USER = PROVISORY_PASS_USER.COD_USER
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = USERS.COD_COMP
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
WHERE COD_ACCESS = @CODACESS
AND COMPANY.ACCESS_KEY = @ACCESS_KEY
AND PROVISORY_PASS_USER.ACTIVE = 1
AND DATEDIFF(DAY, PROVISORY_PASS_USER.CREATED_AT, GETDATE()) < 1
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)
OR USERS.CPF_CNPJ = @CODACESS
AND COMPANY.ACCESS_KEY = @ACCESS_KEY
AND PROVISORY_PASS_USER.ACTIVE = 1
AND DATEDIFF(DAY, PROVISORY_PASS_USER.CREATED_AT, GETDATE()) < 1
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)
OR USERS.EMAIL = @CODACESS
AND COMPANY.ACCESS_KEY = @ACCESS_KEY
AND PROVISORY_PASS_USER.ACTIVE = 1
AND DATEDIFF(DAY, PROVISORY_PASS_USER.CREATED_AT, GETDATE()) < 1
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)
IF @PASSPROV IS NOT NULL
BEGIN
SELECT
	@PASSPROV AS PASS
   ,@EMAIL AS EMAIL
   ,@NAME AS NAME
   ,@LOGIN AS LOGIN
END;
ELSE
BEGIN
SELECT
	@COD_AFF_FIND = COD_AFFILIATOR
FROM USERS
WHERE COD_ACCESS = @CODACESS;
IF @COD_AFF_FIND IS NOT NULL
SET @COD_AFFILIATOR = @COD_AFF_FIND
SELECT
	@CODUSER = USERS.COD_USER
   ,@EMAIL = EMAIL
   ,@NAME = IDENTIFICATION
   ,@LOGIN = USERS.COD_ACCESS
   ,@SUBDOMAIN = AFFILIATOR.SUBDOMAIN
FROM USERS
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = USERS.COD_COMP
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
WHERE COD_ACCESS = @CODACESS
AND COMPANY.ACCESS_KEY = @ACCESS_KEY
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)
OR USERS.CPF_CNPJ = @CODACESS
AND COMPANY.ACCESS_KEY = @ACCESS_KEY
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)
OR USERS.EMAIL = @CODACESS
AND COMPANY.ACCESS_KEY = @ACCESS_KEY
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)
IF @EMAIL IS NULL
	OR @CODUSER IS NULL
THROW 61006, 'USER NOT FOUND', 1;
UPDATE USERS
SET LOGGED = 0
   ,LOCKED_UP = NULL
WHERE COD_USER = @CODUSER
INSERT INTO PROVISORY_PASS_USER (value, COD_USER)
	VALUES (@VALUE, @CODUSER)
IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER PROVISORY_PASS_USER', 1
IF (@REQUIRED = 1)
BEGIN
EXEC [SP_REG_HISTORY_PASS] @COD_USER = @CODUSER
						  ,@PASS = NULL
END

IF (@EMPTY_RETURN IS NOT NULL)
BEGIN
SELECT
	ISNULL(@PASSPROV, @VALUE) AS PASS
   ,@EMAIL AS EMAIL
   ,@NAME AS NAME
   ,@LOGIN AS LOGIN
   ,@CODUSER AS INSIDE_CODE
   ,@SUBDOMAIN AS SUBDOMAIN
END
END;
END;

GO

CREATE PROCEDURE [DBO].[SP_USER_CLAIMS]    
  
/************************************************************************************************  
---------------------------------------------------------------------------------------------    
    Project.......: TKPP    
-----------------------------------------------------------------------------------------------    
    Author                        VERSION         Date                        Description    
-----------------------------------------------------------------------------------------------    
    Luiz Aquino      V1   2020-01-13      Created    
************************************************************************************************/  
    
(  
 @ACESSKEY       VARCHAR(300),   
 @USER           VARCHAR(100) = NULL,   
 @COD_AFFILIATOR INT          = NULL,   
 @COD_USER       INT          = NULL)  
AS  
BEGIN
SELECT
	[USERS].[COD_ACCESS] AS [USERNAME]
   ,[USERS].[COD_USER]
   ,[USERS].[IDENTIFICATION]
   ,[PASS_HISTORY].[PASS]
   ,[USERS].[CPF_CNPJ] AS [CPF_CNPJ_USER]
   ,[USERS].[EMAIL]
   ,[COMPANY].[COD_COMP] AS [COD_COMP]
   ,[AFFILIATOR].[COD_AFFILIATOR] AS [INSIDECODE_AFL]
   ,[PROFILE_ACCESS].[CODE] AS [COD_PROFILE]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,[MODULES].[CODE] AS [MODULE]
   ,[MODULES].[COD_MODULE] AS [COD_MODULE]
   ,@COD_AFFILIATOR AS [PAR_AFFILIATOR]
   ,CASE [COMMERCIAL_ESTABLISHMENT].[SEC_FACTOR_AUTH_ACTIVE]
		WHEN 1 THEN [AUTHENTICATION_FACTOR].[NAME]
		WHEN 0 THEN NULL
		ELSE [AUTHENTICATION_FACTOR].[NAME]
	END AS [AUTHENTICATION_FACTOR]
   ,CASE
		WHEN [FIRST_LOGIN_DATE] IS NULL THEN 1
		ELSE 0
	END AS [FIRST_ACCESS]
   ,[AUTHENTICATION_FACTOR].[COD_FACT]
   ,(-1 * (DATEDIFF(DAY, ((DATEADD(DAY, 30, GETDATE()) + GETDATE()) - GETDATE()), [PASS_HISTORY].[CREATED_AT]))) AS [DAYSTO_EXPIRE]
   ,[THEMES].[COD_THEMES] AS 'ThemeCode'
   ,[THEMES].[CREATED_AT] AS 'CreatedDate'
   ,[THEMES].[LOGO_AFFILIATE] AS 'PathLogo'
   ,[THEMES].[LOGO_HEADER_AFFILIATE] AS 'PathLogoHeader'
   ,[THEMES].[COD_AFFILIATOR] AS 'AffiliatorCode'
   ,[THEMES].[MODIFY_DATE] AS 'ModifyDate'
   ,[THEMES].[COLOR_HEADER] AS 'ColorHeader'
   ,[THEMES].[Active] AS 'Active'
   ,[AFFILIATOR].[SubDomain] AS 'SubDomain'
   ,[AFFILIATOR].[Guid] AS 'Guid'
   ,[THEMES].[BACKGROUND_IMAGE] AS 'BackgroundImage'
   ,[THEMES].[SECONDARY_COLOR] AS 'SecondaryColor'
   ,[POS_AVAILABLE].[AVAILABLE] AS 'AvailablePOS'
   ,[COMMERCIAL_ESTABLISHMENT].[DEFAULT_EC] AS 'DefaultEc'
   ,[SALES_REPRESENTATIVE].[COD_SALES_REP]
   ,IIF([COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = 8, 1, 0) AS [PENDING_DOCUMENTATION]
   ,[USERS].[Active] AS [USER_ACTIVE]
   ,[COMMERCIAL_ESTABLISHMENT].CPF_CNPJ AS EC_IDENTIFICATION
FROM [USERS]
INNER JOIN [COMPANY]
	ON [COMPANY].[COD_COMP] = [USERS].[COD_COMP]
		AND [COMPANY].[ACCESS_KEY] = @ACESSKEY
INNER JOIN [PROFILE_ACCESS]
	ON [PROFILE_ACCESS].[COD_PROFILE] = [USERS].[COD_PROFILE]
LEFT JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [USERS].[COD_EC]
LEFT JOIN [AFFILIATOR]
	ON [AFFILIATOR].[COD_AFFILIATOR] = [USERS].[COD_AFFILIATOR]
INNER JOIN [PASS_HISTORY]
	ON [PASS_HISTORY].[COD_USER] = [USERS].[COD_USER]
		AND [PASS_HISTORY].[ACTUAL] = 1
INNER JOIN [MODULES]
	ON [MODULES].[COD_MODULE] = [USERS].[COD_MODULE]
LEFT JOIN [ASS_FACTOR_AUTH_COMPANY]
	ON [ASS_FACTOR_AUTH_COMPANY].[COD_COMP] = [COMPANY].[COD_COMP]
LEFT JOIN [AUTHENTICATION_FACTOR]
	ON [AUTHENTICATION_FACTOR].[COD_FACT] = [ASS_FACTOR_AUTH_COMPANY].[COD_FACT]
LEFT JOIN [THEMES]
	ON [THEMES].[COD_AFFILIATOR] = [AFFILIATOR].[COD_AFFILIATOR]
		AND ([THEMES].[Active] = 1
			OR [THEMES].[Active] IS NULL)
LEFT JOIN [POS_AVAILABLE]
	ON [POS_AVAILABLE].[COD_AFFILIATOR] = [AFFILIATOR].[COD_AFFILIATOR]
LEFT JOIN [SALES_REPRESENTATIVE]
	ON [SALES_REPRESENTATIVE].[COD_USER] = [USERS].[COD_USER]
WHERE [COD_ACCESS] = @USER
OR [USERS].[EMAIL] = @USER
OR [USERS].[COD_USER] = @COD_USER;
END;

GO

alter PROCEDURE [dbo].[SP_LS_AFFILIATOR_COMP]                    
/*----------------------------------------------------------------------------------------                    
Procedure Name: SP_LS_AFFILIATOR_COMP                    
Project.......: TKPP                    
------------------------------------------------------------------------------------------                    
Author                          VERSION       Date              Description                    
------------------------------------------------------------------------------------------                    
Gian Luca Dalle Cort              V1        01/08/2018            CREATION             
Luiz Aquino                       V2        01/10/2018            UPDATE            
Luiz Aquino                       v3        18/12/2018            ADD SPOT_TAX            
Lucas Aguiar                      v4        01/07/2019            Rotina de bloqueio bancario     
Caike Uchôa                       v5        26/02/2020            add OperationAff  
------------------------------------------------------------------------------------------*/                    
(                    
  @ACCESS_KEY VARCHAR(300),            
  @Name VARCHAR(100) = NULL,            
  @Active INT = 1,            
  @CodAff INT = NULL,            
  @WAS_BLOCKED_FINANCE INT = NULL            
            
)                    
AS              
                  
 DECLARE @QUERY_ NVARCHAR(MAX);
    
          
            
 DECLARE @COD_BLOCK_SITUATION INT;
    
          
 DECLARE @BUSCA VARCHAR(255);
    
          
                  
            
BEGIN

SET @BUSCA = '%' + @Name + '%'

SELECT
	@COD_BLOCK_SITUATION = COD_SITUATION
FROM SITUATION
WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';

SET @QUERY_ = '            
            
  SELECT                     
  AFFILIATOR.COD_AFFILIATOR,                    
  AFFILIATOR.CREATED_AT,                    
  AFFILIATOR.ACTIVE,                    
  AFFILIATOR.NAME AS NAME,                    
  AFFILIATOR.CODE,                    
  AFFILIATOR.CPF_CNPJ AS CPF_CNPJ,                    
  AFFILIATOR.COD_USER_CAD,            
  u.IDENTIFICATION AFF_USER,            
  AFFILIATOR.ACCESS_KEY_AFL,                    
  AFFILIATOR.SECRET_KEY_AFL,                    
  AFFILIATOR.CLIENT_ID_AFL,                    
  AFFILIATOR.FIREBASE_NAME,                    
  AFFILIATOR.MODIFY_DATE,                    
  AFFILIATOR.COD_USER_ALT,                    
  AFFILIATOR.GUID AS GUID,                    
  COMPANY.COD_COMP,                    
  COMPANY.NAME AS COMPANY_NAME,                    
  COMPANY.CODE AS COMPANY_CODE,                     
  COMPANY.CPF_CNPJ AS CNPJ_COMPANY,                    
  AFFILIATOR.SUBDOMAIN SUB_DOMAIN,                  
  THEMES.LOGO_AFFILIATE,                  
  THEMES.LOGO_HEADER_AFFILIATE,                  
  THEMES.COLOR_HEADER,            
  THEMES.BACKGROUND_IMAGE,            
  THEMES.SECONDARY_COLOR,            
  AFFILIATOR.SPOT_TAX,            
  CASE            
   WHEN AFFILIATOR.COD_SITUATION = @COD_BLOCK_SITUATION THEN 1            
   ELSE 0             
  END [FINANCE_BLOCK],            
  AFFILIATOR.NOTE_FINANCE_SCHEDULE  ,          
  TRADUCTION_SITUATION.SITUATION_TR,    
  AFFILIATOR.PLATFORM_NAME PlatformName,                  
  AFFILIATOR.PROPOSED_NUMBER  ProposedNumber,    
  AFFILIATOR.STATE_REGISTRATION  StateRegistration,    
  AFFILIATOR.MUNICIPAL_REGISTRATION  MunicipalRegistration,    
  AFFILIATOR.COMPANY_NAME  CompanyTraddingName,  
  AFFILIATOR.OPERATION_AFF  
 FROM AFFILIATOR                     
  INNER JOIN COMPANY ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP                    
  LEFT JOIN THEMES ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR AND THEMES.ACTIVE = 1            
  LEFT JOIN USERS u ON u.COD_USER = AFFILIATOR.COD_USER_CAD            
  LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = AFFILIATOR.COD_SITUATION              
 WHERE COMPANY.ACCESS_KEY = @ACCESS_KEY AND AFFILIATOR.ACTIVE = @Active '
    
          
              
             
             
 IF @Name IS NOT NULL
SET @QUERY_ = @QUERY_ + 'AND AFFILIATOR.NAME LIKE @BUSCA ';

IF (@CodAff IS NOT NULL)
SET @QUERY_ = @QUERY_ + 'AND AFFILIATOR.COD_AFFILIATOR = @CodAff ';

IF @WAS_BLOCKED_FINANCE = 1
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_SITUATION = @COD_BLOCK_SITUATION ';
ELSE
IF @WAS_BLOCKED_FINANCE = 0
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_SITUATION <> @COD_BLOCK_SITUATION';


EXEC sp_executesql @QUERY_
				  ,N'              
  @ACCESS_KEY VARCHAR(300),            
  @Name VARCHAR(100) ,            
  @Active INT,            
  @CodAff INT,            
  @COD_BLOCK_SITUATION INT,          
  @BUSCA VARCHAR(255)          
  '
				  ,@ACCESS_KEY = @ACCESS_KEY
				  ,@Name = @Name
				  ,@Active = @Active
				  ,@CodAff = @CodAff
				  ,@COD_BLOCK_SITUATION = @COD_BLOCK_SITUATION
				  ,@BUSCA = @BUSCA



END;
GO

IF OBJECT_ID('VW_COMPANY_EC_BR_DEP_EQUIP') IS NOT NULL
DROP VIEW VW_COMPANY_EC_BR_DEP_EQUIP
GO
CREATE VIEW [dbo].[VW_COMPANY_EC_BR_DEP_EQUIP]        
AS
SELECT
	VW_COMPANY_EC_BR_DEP.MCC
   ,VW_COMPANY_EC_BR_DEP.COMPANY
   ,VW_COMPANY_EC_BR_DEP.COD_COMP
   ,VW_COMPANY_EC_BR_DEP.FIREBASE_NAME
   ,VW_COMPANY_EC_BR_DEP.EC AS TRADING_NAME_BR
   ,VW_COMPANY_EC_BR_DEP.COD_EC
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC
   ,VW_COMPANY_EC_BR_DEP.SITUATION_EC
   ,VW_COMPANY_EC_BR_DEP.BRANCH_NAME
   ,VW_COMPANY_EC_BR_DEP.TRADING_NAME_BR AS EC
   ,VW_COMPANY_EC_BR_DEP.COD_BRANCH
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_BR
   ,VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
   ,VW_COMPANY_EC_BR_DEP.DEPARTMENT
   ,VW_COMPANY_EC_BR_DEP.SEGMENTS
   ,VW_COMPANY_EC_BR_DEP.MERCHANT_CODE
   ,ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
   ,EQUIPMENT.COD_EQUIP
   ,EQUIPMENT.SERIAL
   ,EQUIPMENT.TID
   ,CELL_OPERATOR.NAME AS OPERATOR
   ,EQUIPMENT.PUK
   ,EQUIPMENT.CHIP
   ,EQUIPMENT.ACTIVE
   ,DATA_EQUIPMENT_AC.CODE
FROM VW_COMPANY_EC_BR_DEP
INNER JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
INNER JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
LEFT JOIN CELL_OPERATOR
	ON CELL_OPERATOR.COD_OPER = EQUIPMENT.COD_OPER
LEFT JOIN DATA_EQUIPMENT_AC
	ON ASS_DEPTO_EQUIP.COD_EQUIP = DATA_EQUIPMENT_AC.COD_EQUIP
WHERE ASS_DEPTO_EQUIP.ACTIVE = 1
AND EQUIPMENT.ACTIVE = 1

GO

IF NOT EXISTS (SELECT
		*
	FROM sys.columns
	WHERE object_id = OBJECT_ID('COMMERCIAL_ESTABLISHMENT')
	AND name = 'CIELO_CODE')
BEGIN
ALTER TABLE COMMERCIAL_ESTABLISHMENT ADD CIELO_CODE VARCHAR(255);
END

IF NOT EXISTS (SELECT
		*
	FROM sys.columns
	WHERE object_id = OBJECT_ID('COMMERCIAL_ESTABLISHMENT')
	AND name = 'PIX_KEY')
BEGIN
ALTER TABLE COMMERCIAL_ESTABLISHMENT ADD PIX_KEY VARCHAR(255);
END
GO
IF NOT EXISTS (SELECT
		*
	FROM sys.columns
	WHERE object_id = OBJECT_ID('COMMERCIAL_ESTABLISHMENT')
	AND name = 'PIX_TCU')
BEGIN
ALTER TABLE COMMERCIAL_ESTABLISHMENT ADD PIX_TCU INT;
END
GO
IF NOT EXISTS (SELECT
		COD_AC
	FROM ACQUIRER
	WHERE CODE = 'PIX')
BEGIN
INSERT INTO ACQUIRER (CODE, NAME, COD_USER, ALIAS, SUBTITLE, ACTIVE, [GROUP], LOGICAL_NUMBER, COD_SEG_GROUP, ONLINE, ACQ_DOCUMENT)
	VALUES ('PIX', 'PIX', NULL, 'PIX', 'PIX', 1, 'PIX', 0, NULL, NULL, '26994558000123')
END
GO

DECLARE @COD_TTYPE INT, @COD_AC INT, @COD_COMP INT = 8,  @COD_BRAND INT, @SOURCE_TRAN  INT

SELECT
	@COD_TTYPE = COD_TTYPE
   ,@COD_BRAND = COD_BRAND
FROM BRAND
SELECT
	@COD_AC = COD_AC
FROM ACQUIRER
WHERE NAME = 'PIX'
SELECT
	@SOURCE_TRAN = COD_SOURCE_TRAN
FROM SOURCE_TRANSACTION
WHERE CODE = 'PRESENCIAL'

IF NOT EXISTS (SELECT
		COD_ASS_TR_COMP
	FROM ASS_TR_TYPE_COMP
	WHERE COD_AC = @COD_AC
	AND COD_BRAND = @COD_BRAND)
BEGIN
INSERT INTO ASS_TR_TYPE_COMP (COD_USER, COD_TTYPE, COD_AC, COD_COMP, MODIFY_DATE, CODE, TAX_VALUE, PLOT_INI, PLOT_END, INTERVAL, COD_BRAND, COD_SOURCE_TRAN)
	VALUES (NULL, @COD_TTYPE, @COD_AC, @COD_COMP, NULL, '01', 0, 1, 1, 1, @COD_BRAND, @SOURCE_TRAN)
END

IF NOT EXISTS (SELECT
		COD_PR_ACQ
	FROM PRODUCTS_ACQUIRER
	WHERE COD_AC = @COD_AC
	AND COD_BRAND = @COD_BRAND)
BEGIN
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (@COD_TTYPE, @COD_AC, 'À vista', '01', @COD_BRAND, 1, 0, @SOURCE_TRAN, 0)
END
GO

IF NOT EXISTS (SELECT
		*
	FROM sys.columns
	WHERE object_id = OBJECT_ID('TRANSACTION_SERVICES')
	AND name = 'SERVICE_TAX')
BEGIN
ALTER TABLE TRANSACTION_SERVICES
ADD SERVICE_TAX DECIMAL(22, 6) NULL
END
GO
IF NOT EXISTS (SELECT
		*
	FROM sys.columns
	WHERE object_id = OBJECT_ID('TRANSACTION_SERVICES')
	AND name = 'TAX_TYPE')
BEGIN
ALTER TABLE TRANSACTION_SERVICES
ADD TAX_TYPE VARCHAR(16) NULL
END
GO
IF NOT EXISTS (SELECT
		*
	FROM sys.columns
	WHERE object_id = OBJECT_ID('TRANSACTION_SERVICES')
	AND name = 'SERVICE_TAX_AFF')
BEGIN
ALTER TABLE TRANSACTION_SERVICES
ADD SERVICE_TAX_AFF DECIMAL(22, 6) NULL
END
GO

IF OBJECT_ID('SP_VALIDATE_PIX_TRANSACTION') IS NOT NULL
DROP PROCEDURE SP_VALIDATE_PIX_TRANSACTION
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_PIX_TRANSACTION]
/*----------------------------------------------------------------------------------------      
  Author        VERSION     Date      Description      
------------------------------------------------------------------------------------------      
  Luiz Aquino   V1        2020-10-14  Created   
------------------------------------------------------------------------------------------*/
(
    @TERMINALID INT,
    @AMOUNT DECIMAL(22, 6),
    @PAN VARCHAR(100),/*-- ENVIAR ENDTOENDID --*/
    @TRCODE VARCHAR(200),
    @TERMINALDATE DATETIME,
    @HOLDER_NAME VARCHAR(100) = NULL,
    @HOLDER_DOC VARCHAR(100) = NULL
) AS
BEGIN
    
    DECLARE @CODTX INT;
    DECLARE @CODPLAN INT;
    DECLARE @INTERVAL INT;
    DECLARE @TERMINALACTIVE INT;
    DECLARE @CODEC INT;
    DECLARE @CODASS INT;
    DECLARE @COD_ASS_TR_COMP INT;
    DECLARE @COMPANY INT;
    DECLARE @BRANCH INT = 0;
    DECLARE @TYPETRAN INT;
    DECLARE @ACTIVE_EC INT;
    DECLARE @COD_COMP INT;
    DECLARE @LIMIT DECIMAL(22, 6);
    DECLARE @COD_AFFILIATOR INT;
    DECLARE @PLAN_AFF INT;
    DECLARE @CODTR_RETURN INT;
    DECLARE @EC_TRANS INT;
    DECLARE @GEN_TITLES INT;
    DECLARE @COD_RISK_SITUATION INT;
    DECLARE @COD_BRAND INT;
    DECLARE @COD_TTYPE INT;
    DECLARE @QTY_PLOTS INT = 1;
    DECLARE @BRAND VARCHAR(65)
    DECLARE @TYPE VARCHAR(100)
    DECLARE @COD_AC INT;
    DECLARE @CODPROD_ACQ INT;

SELECT
	@COD_BRAND = COD_BRAND
   ,@COD_TTYPE = B.COD_TTYPE
   ,@BRAND = B.NAME
   ,@TYPE = TT.NAME
FROM BRAND B (NOLOCK)
JOIN TRANSACTION_TYPE(NOLOCK) TT
	ON B.COD_TTYPE = TT.COD_TTYPE
WHERE B.NAME = 'PIX'

SELECT
	@COD_AC = COD_AC
FROM ACQUIRER
WHERE CODE = 'PIX'

SELECT TOP 1
	@CODTX = [ATD].[COD_ASS_TX_DEP]
   ,@CODPLAN = [ATD].[COD_ASS_TX_DEP]
   ,@INTERVAL = [ATD].[INTERVAL]
   ,@TERMINALACTIVE = [E].[ACTIVE]
   ,@CODEC = [CE].[COD_EC]
   ,@CODASS = [ADE].[COD_ASS_DEPTO_TERMINAL]
   ,@COMPANY = [CE].[COD_COMP]
   ,@TYPETRAN = [ATD].[COD_TTYPE]
   ,@ACTIVE_EC = [CE].[ACTIVE]
   ,@BRANCH = [BE].[COD_BRANCH]
   ,@COD_COMP = [CE].[COD_COMP]
   ,@LIMIT = [CE].[TRANSACTION_LIMIT]
   ,@COD_AFFILIATOR = [CE].[COD_AFFILIATOR]
   ,@GEN_TITLES = [B].[GEN_TITLES]
   ,@COD_RISK_SITUATION = CE.COD_RISK_SITUATION
FROM [ASS_DEPTO_EQUIP] ADE
LEFT JOIN [EQUIPMENT](NOLOCK) E
	ON [E].[COD_EQUIP] = [ADE].[COD_EQUIP]
LEFT JOIN [DEPARTMENTS_BRANCH](NOLOCK) DB
	ON [DB].[COD_DEPTO_BRANCH] = [ADE].[COD_DEPTO_BRANCH]
LEFT JOIN [BRANCH_EC](NOLOCK) BE
	ON [BE].[COD_BRANCH] = [DB].[COD_BRANCH]
LEFT JOIN [COMMERCIAL_ESTABLISHMENT](NOLOCK) CE
	ON [CE].[COD_EC] = [BE].[COD_EC]
LEFT JOIN [ASS_TAX_DEPART](NOLOCK) ATD
	ON [ATD].[ACTIVE] = 1
		AND [ATD].[COD_DEPTO_BRANCH] = [DB].[COD_DEPTO_BRANCH]
		AND [ATD].[COD_SOURCE_TRAN] = 2
		AND [ATD].[QTY_INI_PLOTS] <= @QTY_PLOTS
		AND [ATD].[QTY_FINAL_PLOTS] >= @QTY_PLOTS
		AND [ATD].COD_TTYPE = @COD_TTYPE
		AND [ATD].COD_BRAND = @COD_BRAND
		AND ([ATD].COD_MODEL IS NULL
			OR [ATD].COD_MODEL = [E].COD_MODEL)
LEFT JOIN [BRAND](NOLOCK) B
	ON [B].[COD_BRAND] = [ATD].[COD_BRAND]
		AND [B].[COD_TTYPE] = [ATD].[COD_TTYPE]
		AND B.COD_BRAND = @COD_BRAND
WHERE [ADE].[COD_EQUIP] = @TERMINALID
AND [ADE].[ACTIVE] = 1;

SELECT
	@TYPETRAN
   ,@COMPANY
   ,@QTY_PLOTS
   ,@BRAND;

SET @EC_TRANS = @CODEC
    
    DECLARE @ERROR_MSG VARCHAR(100) = null, @ERROR_CODE VARCHAR(16)
    
    IF @ERROR_MSG IS NULL AND @AMOUNT > @LIMIT BEGIN
SET @ERROR_MSG = '402 - Transaction limit value exceeded"d';
SET @ERROR_CODE = '402';
    END

    IF @ERROR_MSG IS NULL AND @CODTX IS NULL BEGIN
SET @ERROR_MSG = '404 - PLAN/TAX NOT FOUND';
SET @ERROR_CODE = '404';
    END

    IF @ERROR_MSG IS NULL AND @COD_AFFILIATOR IS NOT NULL BEGIN
SELECT TOP 1
	@PLAN_AFF = [COD_PLAN_TAX_AFF]
FROM [PLAN_TAX_AFFILIATOR](NOLOCK) PTA
WHERE [PTA].[ACTIVE] = 1
AND [PTA].[COD_AFFILIATOR] = @COD_AFFILIATOR
AND PTA.COD_SOURCE_TRAN = 2
AND [COD_TTYPE] = @TYPETRAN
AND COD_BRAND = @COD_BRAND
AND @QTY_PLOTS BETWEEN [QTY_INI_PLOTS] AND [QTY_FINAL_PLOTS];

IF @PLAN_AFF IS NULL
BEGIN
SET @ERROR_MSG = '404 - PLAN/TAX NOT FOUND TO AFFILIATOR';
SET @ERROR_CODE = '404';
        END
    END

    IF @ERROR_MSG IS NULL AND @TERMINALACTIVE = 0 BEGIN
SET @ERROR_MSG = '003 - Blocked terminal';
SET @ERROR_CODE = '003';
    END
    
    IF @ERROR_MSG IS NULL AND @COD_RISK_SITUATION <> 2 BEGIN
SET @ERROR_MSG = '009 - Blocked commercial establishment';
SET @ERROR_CODE = '009';
    END

SELECT
	@COD_ASS_TR_COMP = COD_ASS_TR_COMP
   ,@CODPROD_ACQ = PA.COD_PR_ACQ
FROM ASS_TR_TYPE_COMP ATTC
LEFT JOIN PRODUCTS_ACQUIRER PA
	ON PA.COD_AC = ATTC.COD_AC
		AND PA.COD_BRAND = ATTC.COD_BRAND
		AND PA.COD_TTYPE = ATTC.COD_TTYPE
WHERE ATTC.COD_AC = @COD_AC
AND ATTC.COD_TTYPE = @COD_TTYPE
AND ATTC.COD_BRAND = @COD_BRAND
AND @QTY_PLOTS BETWEEN ATTC.PLOT_INI AND ATTC.PLOT_END
AND ATTC.COD_SOURCE_TRAN = 2

IF @ERROR_MSG IS NULL
	AND @COD_ASS_TR_COMP = 0
BEGIN
SET @ERROR_MSG = '004 - Acquirer key not found for terminal';
SET @ERROR_CODE = '004';
    END
        
    IF @ERROR_MSG IS NOT NULL BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = @COD_ASS_TR_COMP
								,@CODETR = @TRCODE
								,@COMMENT = @ERROR_MSG
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC;
THROW 60002, @ERROR_CODE, 1;
END

EXEC [SP_VAL_LIMIT_EC] @CODEC
					  ,@AMOUNT
					  ,@PAN = @PAN
					  ,@BRAND = @BRAND
					  ,@CODASS_DEPTO_TERMINAL = @CODASS
					  ,@COD_TTYPE = @TYPETRAN
					  ,@PLOTS = @QTY_PLOTS
					  ,@CODTAX_ASS = @CODTX
					  ,@CODETR = @TRCODE
					  ,@TYPE = @TYPE
					  ,@TERMINALDATE = @TERMINALDATE
					  ,@COD_COMP = @COD_COMP
					  ,@COD_AFFILIATOR = @COD_AFFILIATOR
					  ,@EC_TRANS = @EC_TRANS
					  ,@HOLDER_NAME = @HOLDER_NAME
					  ,@HOLDER_DOC = @HOLDER_DOC
					  ,@SOURCE_TRAN = 2;

IF @ERROR_MSG IS NULL
BEGIN
EXECUTE [SP_REG_TRANSACTION] @AMOUNT
							,@PAN
							,@BRAND
							,@CODASS_DEPTO_TERMINAL = @CODASS
							,@COD_TTYPE = @TYPETRAN
							,@PLOTS = @QTY_PLOTS
							,@CODTAX_ASS = @CODTX
							,@CODAC = @COD_ASS_TR_COMP
							,@CODETR = @TRCODE
							,@TERMINALDATE = @TERMINALDATE
							,@COD_ASS_TR_ACQ = @COD_ASS_TR_COMP
							,@CODPROD_ACQ = @CODPROD_ACQ
							,@TYPE = @TYPE
							,@COD_COMP = @COD_COMP
							,@COD_AFFILIATOR = @COD_AFFILIATOR
							,@SOURCE_TRAN = 2
							,@CODE_SPLIT = NULL
							,@EC_TRANS = @EC_TRANS
							,@RET_CODTRAN = @CODTR_RETURN OUTPUT
							,@HOLDER_NAME = @HOLDER_NAME
							,@HOLDER_DOC = @HOLDER_DOC

DECLARE @COD_PIX_SERVICE INT
	   ,@TAX_PIX DECIMAL(22, 6)
	   ,@TAX_PIX_AFF DECIMAL(22, 6)
	   ,@TAX_TYPE VARCHAR(16);

SELECT TOP 1
	@COD_PIX_SERVICE = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE NAME = 'PIX'

SELECT
	@TAX_PIX = CAST(JSON_VALUE(CONFIG_JSON, '$.PixTax') AS DECIMAL(4, 2))
   ,@TAX_TYPE = CAST(JSON_VALUE(CONFIG_JSON, '$.PixChargeOption') AS VARCHAR(16))
FROM SERVICES_AVAILABLE
WHERE ACTIVE = 1
AND COD_ITEM_SERVICE = @COD_PIX_SERVICE
AND COD_EC = @CODEC

SELECT
	@TAX_PIX_AFF = CAST(JSON_VALUE(CONFIG_JSON, '$.PixTax') AS DECIMAL(4, 2))
FROM SERVICES_AVAILABLE
WHERE ACTIVE = 1
AND COD_ITEM_SERVICE = @COD_PIX_SERVICE
AND COD_AFFILIATOR = @COD_AFFILIATOR
AND COD_EC IS NULL;


INSERT INTO TRANSACTION_SERVICES (COD_ITEM_SERVICE, COD_TRAN, MODIFY_DATE, COD_EC, SERVICE_TAX, TAX_TYPE, SERVICE_TAX_AFF)
	VALUES (@COD_PIX_SERVICE, @CODTR_RETURN, GETDATE(), @CODEC, @TAX_PIX, @TAX_TYPE, @TAX_PIX_AFF)

SELECT
	@COD_ASS_TR_COMP AS [ACQUIRER]
   ,@TRCODE AS [TRAN_CODE]
   ,@CODTR_RETURN AS [COD_TRAN];
END
END
GO

IF OBJECT_ID('SP_PIX_TAX_INFO') IS NOT NULL
DROP PROCEDURE SP_PIX_TAX_INFO
GO
CREATE PROCEDURE [dbo].[SP_PIX_TAX_INFO]
/*----------------------------------------------------------------------------------------      
  Author        VERSION     Date      Description      
------------------------------------------------------------------------------------------      
  Luiz Aquino   V1        2020-10-16  Created   
------------------------------------------------------------------------------------------*/
(
    @TERMINALID INT/*-- ALTERAR PARA TERMINALID--*/    
) AS BEGIN
 
    DECLARE @COD_EC INT, 
        @COD_AFF INT, 
        @TAX_PIX DECIMAL(22, 6), 
        @TAX_PIX_AFF DECIMAL(22, 6), 
        @TAX_TYPE VARCHAR(16),
        @COD_PIX_SERVICE INT;

SELECT TOP 1
	@COD_PIX_SERVICE = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE NAME = 'PIX'

SELECT
	@COD_AFF = COD_AFFILIATOR
   ,@COD_EC = COD_EC
FROM VW_COMPANY_EC_AFF_BR_DEP_EQUIP
WHERE COD_EQUIP = @TERMINALID;

SELECT
	@TAX_PIX = CAST(JSON_VALUE(CONFIG_JSON, '$.PixTax') AS DECIMAL(4, 2))
   ,@TAX_TYPE = CAST(JSON_VALUE(CONFIG_JSON, '$.PixChargeOption') AS VARCHAR(16))
FROM SERVICES_AVAILABLE
WHERE ACTIVE = 1
AND (COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFF)
AND COD_ITEM_SERVICE = @COD_PIX_SERVICE
AND COD_EC = @COD_EC;

SELECT
	@TAX_PIX_AFF = CAST(JSON_VALUE(CONFIG_JSON, '$.PixTax') AS DECIMAL(4, 2))
FROM SERVICES_AVAILABLE
WHERE ACTIVE = 1
AND COD_AFFILIATOR = @COD_AFF
AND COD_ITEM_SERVICE = @COD_PIX_SERVICE
AND COD_EC IS NULL;

SELECT
	@TAX_PIX [EC_PIX_TAX]
   ,@TAX_PIX_AFF [AFF_PIX_TAX]
   ,@TAX_TYPE [TAX_TYPE]
END
GO


IF OBJECT_ID('VW_REPORT_TRANSACTIONS_EXP') IS NOT NULL
DROP VIEW VW_REPORT_TRANSACTIONS_EXP
GO
CREATE VIEW [dbo].[VW_REPORT_TRANSACTIONS_EXP]
AS
/*----------------------------------------------------------------------------------------                                          
    Project.......: TKPP                                          
------------------------------------------------------------------------------------------                                          
    Author                     VERSION        Date                Description                                          
-------------------------------------------------------------------------------------                                          
    Marcus Gall                V1       28/11/2019             Add Model_POS, Segment, Location EC                                
    Caike Uchoa                v2       10/01/2020             add CNAE                      
    Kennedy Alef               v3       08/04/2020             add link de pagamento                
    Caike Uchoa                v4       30/04/2020             insert ec prod                
    Caike Uchoa                v5       17/08/2020             Add SALES_TYPE     
    Luiz Aquino                v6       01/07/2020             Add PlanDZero    
    Caike Uchoa                v7       31/08/2020             Add cod_ec_prod    
    Kennedy Alef               v8       02/09/2020             Add change calculations         
    Caike Uchoa                v9       28/09/2020             Add branch business  
    Caike Uchoa                v10      29/09/2020             remove NET_VALUE  
    Luiz Aquino                V11      2020-10-16             ET-1119 PIX
------------------------------------------------------------------------------------------*/
WITH CTE
AS
(SELECT TOP (1000)
		[TRANSACTION].[COD_TRAN]
	   ,[TRANSACTION].[CODE] AS [TRANSACTION_CODE]
	   ,[TRANSACTION].[AMOUNT] AS [AMOUNT]
	   ,[TRANSACTION].[PLOTS] AS [PLOTS]
	   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].[CREATED_AT]) AS DATETIME) AS [TRANSACTION_DATE]
	   ,[TRANSACTION_TYPE].[CODE] AS [TRANSACTION_TYPE]
	   ,[COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ]
	   ,[COMMERCIAL_ESTABLISHMENT].[NAME]
	   ,[EQUIPMENT].[SERIAL] AS [SERIAL_EQUIP]
	   ,[EQUIPMENT].[TID] AS [TID]
	   ,[TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION]
	   ,[TRANSACTION].[Brand]
	   ,[TRANSACTION].[PAN]
	   ,[TRANSACTION_DATA_EXT].[NAME] AS [TRAN_DATA_EXT]
	   ,[TRANSACTION_DATA_EXT].[VALUE] AS [TRAN_DATA_EXT_VALUE]
	   ,(SELECT
				[TDE].[VALUE]
			FROM [TRANSACTION_DATA_EXT] TDE WITH (NOLOCK)
			WHERE [TDE].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
			AND [TDE].[NAME] = 'AUTHCODE')
		AS [AUTH_CODE]
	   ,[ACQUIRER].[COD_AC]
	   ,[ACQUIRER].[NAME] AS [NAME_ACQUIRER]
	   ,[TRANSACTION].[COMMENT] AS [COMMENT]
	   ,[ASS_TAX_DEPART].[PARCENTAGE] AS [TAX]
	   ,COALESCE([ASS_TAX_DEPART].[ANTICIPATION_PERCENTAGE], 0) AS [ANTICIPATION]
	   ,[AFFILIATOR].[COD_AFFILIATOR]
	   ,[AFFILIATOR].[NAME] AS [NAME_AFFILIATOR]
		--------------******------------                                              
	   ,[TRANSACTION].[COD_TTYPE]
	   ,[COMPANY].[COD_COMP]
	   ,[BRANCH_EC].[COD_EC]
	   ,[BRANCH_EC].[COD_BRANCH]
	   ,[STATE].[NAME] AS [STATE_NAME]
	   ,[CITY].[NAME] AS [CITY_NAME]
	   ,[SITUATION].[COD_SITUATION]
	   ,[DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH]
	   ,COALESCE([POSWEB_DATA_TRANSACTION].[AMOUNT], 0) AS [GROSS_VALUE_AGENCY]
	   ,COALESCE([dbo].[FNC_ANT_VALUE_LIQ_TRAN]([POSWEB_DATA_TRANSACTION].[AMOUNT],
		[POSWEB_DATA_TRANSACTION].[MDR],
		[POSWEB_DATA_TRANSACTION].[PLOTS],
		[POSWEB_DATA_TRANSACTION].[ANTICIPATION]) -
		[POSWEB_DATA_TRANSACTION].[TARIFF], 0) AS [NET_VALUE_AGENCY]
	   ,[SOURCE_TRANSACTION].[DESCRIPTION] AS [TYPE_TRAN]
	   ,[TRANSACTION].[COD_SOURCE_TRAN]
	   ,COALESCE([TRANSACTION].[POSWEB], 0) AS [POSWEB]
	   ,[SEGMENTS].[NAME] AS [SEGMENTS_NAME]
	   ,[TRANSACTION].[CREATED_AT]
	   ,[REPORT_TRANSACTIONS_EXP].[COD_TRAN] AS [REP_COD_TRAN]
	   ,[EC_TRAN].[COD_EC] AS [COD_EC_TRANS]
	   ,[EC_TRAN].[NAME] AS [TRANS_EC_NAME]
	   ,[EC_TRAN].[CPF_CNPJ] AS [TRANS_EC_CPF_CNPJ]
	   ,IIF((SELECT
				COUNT(*)
			FROM [TRANSACTION_SERVICES] TS (NOLOCK)
			WHERE [TS].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
			AND [TS].[COD_ITEM_SERVICE] = 4)
		> 0, 1, 0) AS [SPLIT]
	   ,[USERS].[IDENTIFICATION] AS [SALES_REP]
	   ,[USERS].[COD_USER] AS [COD_USER_REP]
	   ,COALESCE([TRANSACTION].[CREDITOR_DOCUMENT], 'NOT CREDITOR_DOCUMENT') AS [CREDITOR_DOCUMENT]
	   ,[SALES_REPRESENTATIVE].[COD_SALES_REP]
	   ,[EQUIPMENT_MODEL].[CODIGO] AS [MODEL_POS]
	   ,[TRANSACTION].[CARD_HOLDER_NAME] AS [CARD_NAME]
	   ,[SEGMENTS].[CNAE]
	   ,[TRANSACTION].[COD_USER]
	   ,[USER_TRAN].[IDENTIFICATION] AS [NAME_USER]
	   ,IIF((SELECT
				COUNT(*)
			FROM [TRANSACTION_SERVICES] TS (NOLOCK)
			WHERE [TS].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
			AND [TS].[COD_ITEM_SERVICE] = 10)
		> 0, 1, 0) AS [LINK_PAYMENT]
	   ,[TRANSACTION].[CUSTOMER_EMAIL]
	   ,[TRANSACTION].[CUSTOMER_IDENTIFICATION]
	   ,IIF((SELECT
				COUNT(*)
			FROM [TRANSACTION_SERVICES]
			WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
			AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
		> 0, [TRANSACTION].[TRACKING_TRANSACTION], NULL) AS [PAYMENT_LINK_TRACKING]
	   ,[TRAN_PROD].[NAME] AS [NAME_PRODUCT_EC]
	   ,[EC_PROD].[NAME] AS [EC_PRODUCT]
	   ,[EC_PROD].CPF_CNPJ AS [EC_PRODUCT_CPF_CNPJ]
	   ,[PROD_ACQ].[NAME] AS [SALES_TYPE]
	   ,(SELECT
				TS.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES TS WITH (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE isa
				ON TS.COD_ITEM_SERVICE = isa.COD_ITEM_SERVICE
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN
			AND isa.NAME = 'PlanDZero')
		AS PLAN_DZEROEC
	   ,(SELECT
				TS.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES TS WITH (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE isa
				ON TS.COD_ITEM_SERVICE = isa.COD_ITEM_SERVICE
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN
			AND isa.NAME = 'PlanDZero')
		AS PLAN_DZEROAFF
	   ,[EC_PROD].COD_EC AS [COD_EC_PROD]
	   ,BRANCH_BUSINESS.[NAME] AS [BRANCH_BUSINESS_EC]
	   ,(SELECT TOP 1
				SERVICE_TAX
			FROM TRANSACTION_SERVICES TS (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE I
				ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
				AND I.NAME = 'PIX'
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		AS [PIX_TAX_EC]
	   ,(SELECT TOP 1
				SERVICE_TAX_AFF
			FROM TRANSACTION_SERVICES TS (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE I
				ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
				AND I.NAME = 'PIX'
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		AS [PIX_TAX_AFF]
	   ,(SELECT TOP 1
				TAX_TYPE
			FROM TRANSACTION_SERVICES TS (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE I
				ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
				AND I.NAME = 'PIX'
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		AS [PIX_TAX_TYPE]
	FROM [TRANSACTION] WITH (NOLOCK)
	LEFT JOIN [dbo].[PROCESS_BG_STATUS]
		ON ([PROCESS_BG_STATUS].[CODE] = [TRANSACTION].[COD_TRAN])
	LEFT JOIN [ASS_DEPTO_EQUIP]
		ON [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL] = [TRANSACTION].[COD_ASS_DEPTO_TERMINAL]
	LEFT JOIN [EQUIPMENT]
		ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
	LEFT JOIN [DEPARTMENTS_BRANCH]
		ON [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] = [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH]
	LEFT JOIN [DEPARTMENTS]
		ON [DEPARTMENTS].[COD_DEPARTS] = [DEPARTMENTS_BRANCH].[COD_DEPARTS]
	LEFT JOIN [BRANCH_EC]
		ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
	LEFT JOIN [ADDRESS_BRANCH]
		ON [ADDRESS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
	LEFT JOIN [NEIGHBORHOOD]
		ON [NEIGHBORHOOD].[COD_NEIGH] = [ADDRESS_BRANCH].[COD_NEIGH]
	LEFT JOIN [ASS_TAX_DEPART]
		ON [ASS_TAX_DEPART].[COD_ASS_TX_DEP] = [TRANSACTION].[COD_ASS_TX_DEP]
	LEFT JOIN [PLAN]
		ON [PLAN].[COD_PLAN] = [ASS_TAX_DEPART].[COD_PLAN]
	LEFT JOIN [CITY]
		ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
	LEFT JOIN [STATE]
		ON [STATE].[COD_STATE] = [CITY].[COD_STATE]
	LEFT JOIN [COMMERCIAL_ESTABLISHMENT]
		ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [BRANCH_EC].[COD_EC]
	LEFT JOIN [COMPANY]
		ON [COMPANY].[COD_COMP] = [COMMERCIAL_ESTABLISHMENT].[COD_COMP]
	LEFT JOIN [TRANSACTION_TYPE]
		ON [TRANSACTION_TYPE].[COD_TTYPE] = [TRANSACTION].[COD_TTYPE]
	LEFT JOIN [SITUATION]
		ON [SITUATION].[COD_SITUATION] = [TRANSACTION].[COD_SITUATION]
	LEFT JOIN [TRADUCTION_SITUATION]
		ON [TRADUCTION_SITUATION].[COD_SITUATION] = [SITUATION].[COD_SITUATION]
	LEFT JOIN [SEGMENTS]
		ON [SEGMENTS].[COD_SEG] = [COMMERCIAL_ESTABLISHMENT].[COD_SEG]
	LEFT JOIN [dbo].[REPORT_TRANSACTIONS_EXP]
		ON ([REPORT_TRANSACTIONS_EXP].[COD_TRAN] = [TRANSACTION].[COD_TRAN])
	LEFT JOIN [TRANSACTION_DATA_EXT] WITH (NOLOCK)
		ON [TRANSACTION_DATA_EXT].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
	LEFT JOIN [AFFILIATOR]
		ON [AFFILIATOR].[COD_AFFILIATOR] = [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR]
	LEFT JOIN [POSWEB_DATA_TRANSACTION]
		ON [POSWEB_DATA_TRANSACTION].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
	LEFT JOIN [dbo].[SOURCE_TRANSACTION] WITH (NOLOCK)
		ON ([SOURCE_TRANSACTION].[COD_SOURCE_TRAN] = [TRANSACTION].[COD_SOURCE_TRAN])
	LEFT JOIN [COMMERCIAL_ESTABLISHMENT] AS [EC_TRAN] WITH (NOLOCK)
		ON [EC_TRAN].[COD_EC] = [TRANSACTION].[COD_EC]
	LEFT JOIN [SALES_REPRESENTATIVE]
		ON [SALES_REPRESENTATIVE].[COD_SALES_REP] = [COMMERCIAL_ESTABLISHMENT].[COD_SALES_REP]
	LEFT JOIN [USERS]
		ON [USERS].[COD_USER] = [SALES_REPRESENTATIVE].[COD_USER]
	LEFT JOIN [USERS] AS [USER_TRAN]
		ON [USER_TRAN].[COD_USER] = [TRANSACTION].[COD_USER]
	LEFT JOIN [ASS_TR_TYPE_COMP]
		ON [ASS_TR_TYPE_COMP].[COD_ASS_TR_COMP] = [TRANSACTION].[COD_ASS_TR_COMP]
	LEFT JOIN [ACQUIRER]
		ON [ACQUIRER].[COD_AC] = [ASS_TR_TYPE_COMP].[COD_AC]
	LEFT JOIN [EQUIPMENT_MODEL] WITH (NOLOCK)
		ON [EQUIPMENT_MODEL].[COD_MODEL] = [EQUIPMENT].[COD_MODEL]
	LEFT JOIN TRANSACTION_PRODUCTS AS [TRAN_PROD] WITH (NOLOCK)
		ON [TRAN_PROD].COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
	LEFT JOIN COMMERCIAL_ESTABLISHMENT AS [EC_PROD] WITH (NOLOCK)
		ON [EC_PROD].COD_EC = [TRAN_PROD].COD_EC
	LEFT JOIN PRODUCTS_ACQUIRER AS [PROD_ACQ] WITH (NOLOCK)
		ON [PROD_ACQ].COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ
	LEFT JOIN BRANCH_BUSINESS
		ON BRANCH_BUSINESS.COD_BRANCH_BUSINESS = COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS
	WHERE [ADDRESS_BRANCH].[ACTIVE] = 1
	AND [PROCESS_BG_STATUS].[STATUS_PROCESSED] = 0
	AND [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 1
	AND COALESCE([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION].[CREATED_AT])

SELECT
	CTE.COD_TRAN
   ,CTE.TRANSACTION_CODE
   ,CTE.Amount
   ,CTE.PLOTS
   ,CTE.TRANSACTION_DATE
   ,CTE.TRANSACTION_TYPE
   ,CTE.CPF_CNPJ
   ,CTE.[NAME]
   ,CTE.SERIAL_EQUIP
   ,CTE.TID
   ,CTE.SITUATION
   ,CTE.Brand
   ,CTE.PAN
   ,CTE.TRAN_DATA_EXT
   ,CTE.TRAN_DATA_EXT_VALUE
   ,CTE.AUTH_CODE
   ,CTE.COD_AC
   ,CTE.NAME_ACQUIRER
   ,CTE.COMMENT
   ,CTE.TAX
   ,CTE.ANTICIPATION
   ,CTE.COD_AFFILIATOR
   ,CTE.NAME_AFFILIATOR
   ,CTE.COD_TTYPE
   ,CTE.COD_COMP
   ,CTE.COD_EC
   ,CTE.COD_BRANCH
   ,CTE.STATE_NAME
   ,CTE.CITY_NAME
   ,CTE.COD_SITUATION
   ,CTE.COD_DEPTO_BRANCH
   ,CTE.GROSS_VALUE_AGENCY
   ,CTE.NET_VALUE_AGENCY
   ,CTE.TYPE_TRAN
   ,CTE.COD_SOURCE_TRAN
   ,CTE.POSWEB
   ,CTE.SEGMENTS_NAME
   ,CTE.CREATED_AT
   ,CTE.REP_COD_TRAN
   ,CTE.COD_EC_TRANS
   ,CTE.TRANS_EC_NAME
   ,CTE.TRANS_EC_CPF_CNPJ
   ,CTE.SPLIT
   ,CTE.SALES_REP
   ,CTE.COD_USER_REP
   ,CTE.CREDITOR_DOCUMENT
   ,CTE.COD_SALES_REP
   ,CTE.MODEL_POS
   ,CTE.CARD_NAME
   ,CTE.CNAE
   ,CTE.COD_USER
   ,CTE.NAME_USER
   ,CTE.LINK_PAYMENT
   ,CTE.CUSTOMER_EMAIL
   ,CTE.CUSTOMER_IDENTIFICATION
   ,CTE.PAYMENT_LINK_TRACKING
   ,CTE.NAME_PRODUCT_EC
   ,CTE.EC_PRODUCT
   ,CTE.EC_PRODUCT_CPF_CNPJ
   ,CTE.SALES_TYPE
   ,CTE.PLAN_DZEROEC
   ,CTE.PLAN_DZEROAFF
   ,CTE.COD_EC_PROD
   ,CTE.BRANCH_BUSINESS_EC
   ,CTE.PIX_TAX_EC
   ,CTE.PIX_TAX_AFF
   ,CTE.PIX_TAX_TYPE

FROM CTE
GO

IF OBJECT_ID('SP_CONTACT_DATA_EQUIP') IS NOT NULL
DROP PROCEDURE SP_CONTACT_DATA_EQUIP
GO
CREATE PROCEDURE [dbo].[SP_CONTACT_DATA_EQUIP]    
/*----------------------------------------------------------------------------------------                      
Procedure Name: [SP_CONTACT_DATA_EQUIP]                      
Project.......: TKPP                      
------------------------------------------------------------------------------------------                      
Author                          VERSION         Date                            Description                      
------------------------------------------------------------------------------------------                      
Kennedy Alef                      V1         27/07/2018                           Creation                      
Fernando Henrique F. O            V2         03/04/2019                           Change                        
Lucas Aguiar                      v3         22-04-2019                   Descer se é split ou não                      
Caike Uchôa                       v4         15/01/2020                     descer MMC padrão para PF              
Caike Uchoa                       v5         22/09/2020                    Add formatacao de strings            
------------------------------------------------------------------------------------------*/ (    
@TERMINALID INT,     
@COD_EC INT = NULL)    
AS    
BEGIN
SELECT TOP 1
	VW_COMPANY_EC_BR_DEP_EQUIP.CPF_CNPJ_BR
   ,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF
   ,[dbo].[FNC_REMOV_CARAC_ESP](
	VW_COMPANY_EC_BR_DEP_EQUIP.TRADING_NAME_BR) AS TRADING_NAME_BR
   ,[dbo].[FNC_REMOV_CARAC_ESP](VW_COMPANY_EC_BR_DEP_EQUIP.BRANCH_NAME) AS BRANCH_NAME
   ,CASE
		WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'
		ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC
	END AS MCC
   ,COMMERCIAL_ESTABLISHMENT.CODE AS MERCHANT_CODE
   ,LEFT([dbo].[FNC_REMOV_CARAC_ESP](ADDRESS_BRANCH.[ADDRESS]), 20) AS [ADDRESS]
   ,[dbo].[FNC_REMOV_LETRAS]([dbo].FNC_REMOV_CARAC_ESP(ADDRESS_BRANCH.[NUMBER])) AS [NUMBER]
   ,ADDRESS_BRANCH.CEP
   ,ISNULL([dbo].[FNC_REMOV_CARAC_ESP](ADDRESS_BRANCH.COMPLEMENT), 0) AS COMPLEMENT
   ,[dbo].[FNC_REMOV_CARAC_ESP](NEIGHBORHOOD.NAME) AS NEIGHBORDHOOD
   ,[dbo].[FNC_REMOV_CARAC_ESP](CITY.[NAME]) AS CITY
   ,[dbo].[FNC_REMOV_CARAC_ESP]([STATE].UF) AS [STATE]
   ,COUNTRY.INITIALS
   ,[dbo].[FNC_REMOV_LETRAS]([dbo].FNC_REMOV_CARAC_ESP(CONTACT_BRANCH.DDI)) AS DDI
   ,[dbo].[FNC_REMOV_LETRAS]([dbo].FNC_REMOV_CARAC_ESP(CONTACT_BRANCH.DDD)) AS DDD
   ,[dbo].[FNC_REMOV_LETRAS]([dbo].[FNC_REMOV_CARAC_ESP](CONTACT_BRANCH.[NUMBER])) AS TEL_NUMBER
   ,TYPE_CONTACT.NAME AS TYPE_CONTACT
   ,EQUIPMENT.COD_EQUIP
   ,VW_COMPANY_EC_BR_DEP_EQUIP.MERCHANT_CODE
   ,COMMERCIAL_ESTABLISHMENT.CIELO_CODE
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE COD_ITEM_SERVICE = 4
				AND ACTIVE = 1
				AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
				AND COD_EC IS NULL
				AND COD_OPT_SERV = 4)
			> 0 THEN 1
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE COD_ITEM_SERVICE = 4
				AND ACTIVE = 1
				AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
				AND COD_EC IS NULL
				AND COD_OPT_SERV = 2)
			> 0 THEN 0
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE COD_ITEM_SERVICE = 4
				AND ACTIVE = 1
				AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
				AND COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC)
			> 0 THEN 1
		ELSE 0
	END AS [SPLIT]
   ,(
	CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE COD_ITEM_SERVICE = 13
				AND ACTIVE = 1
				AND COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
				AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR)
			> 0 THEN 1
		ELSE 0
	END
	) AS MANY_MERCHANTS
   ,EC_PARAM.CPF_CNPJ AS CNPJ_PARAM
   ,IIF(LEN(EC_PARAM.CPF_CNPJ) = 11, 'CPF',
	IIF(EC_PARAM.CPF_CNPJ IS NOT NULL, 'CNPJ', NULL)) AS TYPE_DOC_PARAM
	--,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF      
   ,[dbo].[FNC_REMOV_CARAC_ESP](EC_PARAM.NAME) AS TRADING_NAME_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP](EC_PARAM.TRADING_NAME) AS BRANCH_NAME_PARAM
	--  ,CASE      
	-- WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'      
	-- ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC      
	--END AS MCC_PARAM      
   ,EC_PARAM.CODE AS MERCHANT_CODE_PARAM
   ,LEFT([dbo].[FNC_REMOV_CARAC_ESP](ADD_EC_PARAM.[ADDRESS]), 20) AS [ADDRESS_PARAM]
   ,[dbo].[FNC_REMOV_LETRAS](
	[dbo].FNC_REMOV_CARAC_ESP(ADD_EC_PARAM.[NUMBER])) AS [NUMBER_PARAM]
   ,ADD_EC_PARAM.CEP AS CEP_PARAM
   ,ISNULL([dbo].[FNC_REMOV_CARAC_ESP](ADD_EC_PARAM.COMPLEMENT), 0) AS COMPLEMENT_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP](ENIGH_EC_PARAM.NAME) AS NEIGHBORDHOOD_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP](CITY_EC_PARAM.[NAME]) AS CITY_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP]([STATE_EC_PARAM].UF) AS [STATE_PARAM]
   ,COUNTRY_EC_PARAM.INITIALS AS INITIALS_PARAM
   ,COMMERCIAL_ESTABLISHMENT.PIX_KEY
   ,ISNULL(COMMERCIAL_ESTABLISHMENT.PIX_TCU, 0) AS PIX_TCU
   ,(SELECT
			ACCOUNT
		FROM BANK_DETAILS_EC AS BK_DET
		JOIN BANKS
			ON BK_DET.COD_BANK = BANKS.COD_BANK
			AND BK_DET.COD_BANK = 324
		WHERE BK_DET.ACTIVE = 1
		AND BK_DET.COD_BRANCH = VW_COMPANY_EC_BR_DEP_EQUIP.COD_BRANCH)
	AS ACCOUNT_CELER
   ,(SELECT
			COUNT(*)
		FROM SERVICES_AVAILABLE
		WHERE COD_ITEM_SERVICE = 19
		AND ACTIVE = 1
		AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
		AND COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC)
	AS PIX
FROM VW_COMPANY_EC_BR_DEP_EQUIP
JOIN ADDRESS_BRANCH
	ON ADDRESS_BRANCH.COD_BRANCH = VW_COMPANY_EC_BR_DEP_EQUIP.COD_BRANCH
JOIN NEIGHBORHOOD
	ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
JOIN CITY
	ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
JOIN STATE
	ON STATE.COD_STATE = CITY.COD_STATE
JOIN COUNTRY
	ON COUNTRY.COD_COUNTRY = STATE.COD_COUNTRY
JOIN CONTACT_BRANCH
	ON CONTACT_BRANCH.COD_BRANCH = VW_COMPANY_EC_BR_DEP_EQUIP.COD_BRANCH
JOIN TYPE_CONTACT
	ON TYPE_CONTACT.COD_TP_CONT = CONTACT_BRANCH.COD_TP_CONT
JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP_EQUIP.COD_DEPTO_BR
JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
INNER JOIN TYPE_ESTAB
	ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB
LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PARAM
	ON EC_PARAM.COD_EC = ISNULL(@COD_EC, 0)
		AND EC_PARAM.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
LEFT JOIN BRANCH_EC BRANCH_PARAM
	ON EC_PARAM.COD_EC = BRANCH_PARAM.COD_EC
LEFT JOIN ADDRESS_BRANCH ADD_EC_PARAM
	ON ADD_EC_PARAM.COD_BRANCH = BRANCH_PARAM.COD_BRANCH
		AND ADD_EC_PARAM.ACTIVE = 1
LEFT JOIN NEIGHBORHOOD ENIGH_EC_PARAM
	ON ENIGH_EC_PARAM.COD_NEIGH = ADD_EC_PARAM.COD_NEIGH
LEFT JOIN CITY CITY_EC_PARAM
	ON CITY_EC_PARAM.COD_CITY = ENIGH_EC_PARAM.COD_CITY
LEFT JOIN STATE STATE_EC_PARAM
	ON STATE_EC_PARAM.COD_STATE = CITY_EC_PARAM.COD_STATE
LEFT JOIN COUNTRY COUNTRY_EC_PARAM
	ON COUNTRY_EC_PARAM.COD_COUNTRY = STATE_EC_PARAM.COD_COUNTRY
WHERE EQUIPMENT.COD_EQUIP = @TERMINALID
AND ASS_DEPTO_EQUIP.ACTIVE = 1
ORDER BY ADDRESS_BRANCH.COD_ADDRESS DESC

END

GO

IF OBJECT_ID('SP_UPDATE_PIX_ACCEPTED') IS NOT NULL
DROP PROCEDURE SP_UPDATE_PIX_ACCEPTED
GO
CREATE PROCEDURE SP_UPDATE_PIX_ACCEPTED 
(
	@TERMINALID INT,
	@PIX_KEY VARCHAR(255) = NULL,
	@PIX_TCU INT
)
AS
BEGIN

UPDATE COMMERCIAL_ESTABLISHMENT
SET PIX_TCU = @PIX_TCU
   ,PIX_KEY = ISNULL(@PIX_KEY, PIX_KEY)
FROM COMMERCIAL_ESTABLISHMENT
JOIN VW_COMPANY_EC_AFF_BR_DEP_EQUIP
	ON VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
WHERE COD_EQUIP = @TERMINALID

END;

GO
IF OBJECT_ID('SP_FD_PIX_TRAN_INFO') IS NOT NULL
DROP PROCEDURE SP_FD_PIX_TRAN_INFO
GO
CREATE PROCEDURE SP_FD_PIX_TRAN_INFO  
(  
 @NSU VARCHAR(255)  
)  
AS  
BEGIN
SELECT
	[TRANSACTION].AMOUNT AS TRANSACTION_AMOUNT
   ,(CASE
		WHEN TAX_TYPE = '%' THEN ([TRANSACTION].AMOUNT * (100 - SERVICE_TAX) / 100)
		ELSE ([TRANSACTION].AMOUNT - ISNULL(SERVICE_TAX, 20))
	END) AS LIQUID_AMOUNT
   ,(CASE
		WHEN TAX_TYPE = '%' THEN (150 * SERVICE_TAX / 100)
		ELSE ([TRANSACTION].AMOUNT - SERVICE_TAX)
	END) AS LIQUID_TAX
   ,SERVICE_TAX AS PIX_TAX
   ,TRANSACTION_SERVICES.TAX_TYPE AS TYPE_PIX
   ,TRADUCTION_SITUATION.SITUATION_TR
FROM [TRANSACTION] WITH (NOLOCK)
JOIN TRANSACTION_SERVICES WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
JOIN SITUATION
	ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
LEFT JOIN TRADUCTION_SITUATION
	ON TRADUCTION_SITUATION.COD_SITUATION = SITUATION.COD_SITUATION
WHERE [TRANSACTION].CODE = @NSU
AND TRANSACTION_SERVICES.COD_ITEM_SERVICE = 19
END
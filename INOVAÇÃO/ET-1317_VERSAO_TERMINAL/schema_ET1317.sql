IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'QTY_BUSINESS_DAY'
	AND object_id = OBJECT_ID(N'REPORT_CONSOLIDATED_TRANS_SUB'))
BEGIN
ALTER TABLE REPORT_CONSOLIDATED_TRANS_SUB
ADD QTY_BUSINESS_DAY INT
END


GO


IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'SITUATION_TRAN'
	AND object_id = OBJECT_ID(N'REPORT_CONSOLIDATED_TRANS_SUB'))
BEGIN
ALTER TABLE REPORT_CONSOLIDATED_TRANS_SUB
ADD SITUATION_TRAN VARCHAR(100)
END

GO

IF NOT EXISTS (SELECT
		*
	FROM sys.columns c
	WHERE c.object_id = OBJECT_ID('TRANSACTION')
	AND name = 'TERMINAL_VERSION')
BEGIN
ALTER TABLE [TRANSACTION]
ADD TERMINAL_VERSION VARCHAR(200);
END

GO

IF NOT EXISTS (SELECT
		*
	FROM sys.columns c
	WHERE c.object_id = OBJECT_ID('REPORT_TRANSACTIONS')
	AND name = 'TERMINAL_VERSION')
BEGIN
ALTER TABLE REPORT_TRANSACTIONS
ADD TERMINAL_VERSION VARCHAR(200);
END

GO

IF NOT EXISTS (SELECT
		*
	FROM sys.columns c
	WHERE c.object_id = OBJECT_ID('REPORT_TRANSACTIONS_EXP')
	AND name = 'TERMINAL_VERSION')
BEGIN
ALTER TABLE REPORT_TRANSACTIONS_EXP
ADD TERMINAL_VERSION VARCHAR(200);
END

GO

IF NOT EXISTS (SELECT
		*
	FROM sys.columns c
	WHERE c.object_id = OBJECT_ID('REPORT_CONSOLIDATED_TRANS_SUB')
	AND name = 'TERMINAL_VERSION')
BEGIN
ALTER TABLE REPORT_CONSOLIDATED_TRANS_SUB
ADD TERMINAL_VERSION VARCHAR(200);
END

GO

IF OBJECT_ID('SP_VALIDATE_TRANSACTION') IS NOT NULL DROP PROCEDURE SP_VALIDATE_TRANSACTION
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION]      
      
/***********************************************************************************************************************************************************************            
------------------------------------------------------------------------------------------------------------------------------------------------                                  
Procedure Name: [SP_VALIDATE_TRANSACTION]                                  
Project.......: TKPP                                  
--------------------------------------------------------------------------------------------------------------------------------------------------                                  
Author                          VERSION        Date                            Description                                  
------------------------         --------------------------------------------------------------------------------------------------------------------------                                  
Kennedy Alef                      V1         27/07/2018                          Creation                                  
Gian Luca Dalle Cort              V1         14/08/2018                          Changed                  
Lucas Aguiar                      v3         17-04-2019           Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções                    
Lucas Aguiar                      v4         23-04-2019                    Parametro opc cod ec              
Kennedy Alef                      v5         12-11-2019           Card holder name, doc holder, logical number                  
Caike Uchoa                       V6         26-10-2020                        ADD COD_MODEL    
Caike Uchoa                       V7         03/11/2020                        ADD COD_TTYPE    
Caike Uchoa               v8         16-11-2020           Permitir tranções com limite excedido   
--------------------------------------------------------------------------------------------------------------------------------------------------            
***********************************************************************************************************************************************************************/ (@TERMINALID INT,      
@TYPETRANSACTION VARCHAR(100),      
@AMOUNT DECIMAL(22, 6),      
@QTY_PLOTS INT,      
@PAN VARCHAR(100),      
@BRAND VARCHAR(200),      
@TRCODE VARCHAR(200),      
@TERMINALDATE DATETIME,      
@CODPROD_ACQ INT,      
@TYPE VARCHAR(100),      
@COD_BRANCH INT,      
@CODE_SPLIT INT = NULL,      
@COD_EC INT = NULL,      
@HOLDER_NAME VARCHAR(100) = NULL,      
@HOLDER_DOC VARCHAR(100) = NULL,      
@LOGICAL_NUMBER VARCHAR(100) = NULL,      
@COD_TRAN_PROD INT = NULL,      
@COD_EC_PRD INT = NULL,
@TERMINAL_VERSION VARCHAR(200) = NULL)      
AS      
BEGIN
    
      
      
      
      
 DECLARE @CODTX INT;
    
      
      
      
      
 DECLARE @CODPLAN INT;
    
      
      
      
      
 DECLARE @INTERVAL INT;
    
      
      
      
      
 DECLARE @TERMINALACTIVE INT;
    
      
      
      
      
 DECLARE @CODEC INT;
    
      
      
      
      
 DECLARE @CODASS INT;
    
      
      
      
      
 DECLARE @CODAC INT;
    
      
      
      
      
 DECLARE @COMPANY INT;
    
      
      
      
      
 DECLARE @BRANCH INT = 0;
    
      
      
      
      
 DECLARE @TYPETRAN INT;
    
      
      
      
      
 DECLARE @ACTIVE_EC INT;
    
      
      
      
      
 DECLARE @CONT INT;
    
      
      
      
      
 DECLARE @COD_COMP INT;
    
      
      
      
      
 DECLARE @LIMIT DECIMAL(22, 6);
    
      
      
      
      
 DECLARE @COD_AFFILIATOR INT;
    
      
      
      
      
 DECLARE @PLAN_AFF INT;
    
      
      
      
      
 DECLARE @CODTR_RETURN INT;
    
      
      
      
      
 DECLARE @EC_TRANS INT;
    
      
      
      
      
 DECLARE @GEN_TITLES INT;
    
      
      
      
      
 DECLARE @COD_ERROR INT;
    
      
      
      
 DECLARE @ERROR_DESCRIPTION VARCHAR(100)
    
      
      
 DECLARE @COD_RISK_SITUATION INT;
    
     
     
 DECLARE @COD_MODEL INT;
    
      
      
 BEGIN

SELECT TOP 1
	@CODTX = [ASS_TAX_DEPART].[COD_ASS_TX_DEP]
   ,@CODPLAN = [ASS_TAX_DEPART].[COD_ASS_TX_DEP]
   ,@INTERVAL = [ASS_TAX_DEPART].[INTERVAL]
   ,@TERMINALACTIVE = [EQUIPMENT].[ACTIVE]
   ,@CODEC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,@CODASS = [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL]
   ,@COMPANY = [COMPANY].[COD_COMP]
   ,@TYPETRAN = [TRANSACTION_TYPE].[COD_TTYPE]
   ,@ACTIVE_EC = [COMMERCIAL_ESTABLISHMENT].[ACTIVE]
   ,@BRANCH = [BRANCH_EC].[COD_BRANCH]
   ,@COD_COMP = [COMPANY].[COD_COMP]
   ,@LIMIT = [COMMERCIAL_ESTABLISHMENT].[TRANSACTION_LIMIT]
   ,@COD_AFFILIATOR = [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR]
   ,@GEN_TITLES = [BRAND].[GEN_TITLES]
   ,@COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
   ,@COD_MODEL = [EQUIPMENT_MODEL].COD_MODEL
FROM [ASS_DEPTO_EQUIP]
LEFT JOIN [EQUIPMENT]
	ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
LEFT JOIN [EQUIPMENT_MODEL]
	ON [EQUIPMENT_MODEL].[COD_MODEL] = [EQUIPMENT].[COD_MODEL]
LEFT JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] = [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH]
LEFT JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
LEFT JOIN [DEPARTMENTS]
	ON [DEPARTMENTS].[COD_DEPARTS] = [DEPARTMENTS_BRANCH].[COD_DEPARTS]
LEFT JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [BRANCH_EC].[COD_EC]
LEFT JOIN [COMPANY]
	ON [COMPANY].[COD_COMP] = [COMMERCIAL_ESTABLISHMENT].[COD_COMP]
LEFT JOIN [ASS_TAX_DEPART]
	ON [ASS_TAX_DEPART].[COD_DEPTO_BRANCH] = [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH]
LEFT JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].[COD_TTYPE] = [ASS_TAX_DEPART].[COD_TTYPE]
LEFT JOIN [BRAND]
	ON [BRAND].[COD_BRAND] = [ASS_TAX_DEPART].[COD_BRAND]
		AND [BRAND].[COD_TTYPE] = [TRANSACTION_TYPE].[COD_TTYPE]
WHERE [ASS_TAX_DEPART].[ACTIVE] = 1
AND [ASS_DEPTO_EQUIP].[ACTIVE] = 1
AND [ASS_TAX_DEPART].[COD_SOURCE_TRAN] = 2
AND [EQUIPMENT].[COD_EQUIP] = @TERMINALID
AND LOWER([TRANSACTION_TYPE].[NAME]) = @TYPETRANSACTION
AND [ASS_TAX_DEPART].[QTY_INI_PLOTS] <=
@QTY_PLOTS
AND [ASS_TAX_DEPART].[QTY_FINAL_PLOTS] >= @QTY_PLOTS
AND ([BRAND].[NAME] = @BRAND
OR [BRAND].[COD_BRAND] IS NULL)
AND ([ASS_TAX_DEPART].COD_MODEL = [EQUIPMENT_MODEL].COD_MODEL
OR [ASS_TAX_DEPART].COD_MODEL IS NULL);


IF (@COD_EC IS NOT NULL)
SET @EC_TRANS = @COD_EC;
ELSE
SET @EC_TRANS = @CODEC;


--IF @AMOUNT > @LIMIT    
--BEGIN    
--EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT    
--        ,@PAN = @PAN    
--        ,@BRAND = @BRAND    
--        ,@CODASS_DEPTO_TERMINAL = @CODASS    
--        ,@COD_TTYPE = @TYPETRAN    
--        ,@PLOTS = @QTY_PLOTS    
--        ,@CODTAX_ASS = @CODTX    
--        ,@CODAC = NULL    
--        ,@CODETR = @TRCODE    
--        ,@COMMENT = '402 - Transaction limit value exceeded"d'    
--        ,@TERMINALDATE = @TERMINALDATE    
--        ,@TYPE = @TYPE    
--        ,@COD_COMP = @COD_COMP    
--        ,@COD_AFFILIATOR = @COD_AFFILIATOR    
--        ,@SOURCE_TRAN = 2    
--        ,@CODE_SPLIT = @CODE_SPLIT    
--        ,@COD_EC = @EC_TRANS    
--        ,@HOLDER_NAME = @HOLDER_NAME    
--        ,@HOLDER_DOC = @HOLDER_DOC    
--        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;    
--THROW 60002, '402', 1;    

--END;    

IF @CODTX IS NULL

/*******************************************            
 PROCEDURE DE REGISTRO DE TRANSAÇÕES NEGADAS            
*******************************************/

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = '404 - PLAN/TAX NOT FOUND'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, '404', 1;
END;

IF @COD_AFFILIATOR IS NOT NULL
BEGIN

SELECT TOP 1
	@PLAN_AFF = [COD_PLAN_TAX_AFF]
FROM [PLAN_TAX_AFFILIATOR]
INNER JOIN [AFFILIATOR]
	ON [AFFILIATOR].[COD_AFFILIATOR] = [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR]
WHERE [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR] = @COD_AFFILIATOR
AND @QTY_PLOTS BETWEEN [QTY_INI_PLOTS] AND [QTY_FINAL_PLOTS]
AND [COD_TTYPE] = @TYPETRAN
AND [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1;

IF @PLAN_AFF IS NULL
BEGIN

EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = '404 - PLAN/TAX NOT FOUND TO AFFILIATOR'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, '404', 1;

END;

END;


IF @TERMINALACTIVE = 0

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = '003 - Blocked terminal'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, '003', 1;

END;

IF @COD_RISK_SITUATION <> 2

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = '009 - Blocked commercial establishment'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, '009', 1;

END;

--EXEC [SP_VAL_LIMIT_EC] @CODEC    
--       ,@AMOUNT    
--       ,@PAN = @PAN    
--       ,@BRAND = @BRAND    
--       ,@CODASS_DEPTO_TERMINAL = @CODASS    
--       ,@COD_TTYPE = @TYPETRAN    
--       ,@PLOTS = @QTY_PLOTS    
--       ,@CODTAX_ASS = @CODTX    
--       ,@CODETR = @TRCODE    
--       ,@TYPE = @TYPE    
--       ,@TERMINALDATE = @TERMINALDATE    
--       ,@COD_COMP = @COD_COMP    
--       ,@COD_AFFILIATOR = @COD_AFFILIATOR    
--       ,@CODE_SPLIT = @CODE_SPLIT    
--       ,@EC_TRANS = @EC_TRANS    
--       ,@HOLDER_NAME = @HOLDER_NAME    
--       ,@HOLDER_DOC = @HOLDER_DOC    
--       ,@LOGICAL_NUMBER = @LOGICAL_NUMBER    
--       ,@SOURCE_TRAN = 2;    



EXEC @CODAC = [SP_DEFINE_ACQ] @TR_TYPE = @TYPETRAN
							 ,@COMPANY = @COMPANY
							 ,@QTY_PLOTS = @QTY_PLOTS
							 ,@BRAND = @BRAND
							 ,@COD_PR = @CODPROD_ACQ;

IF @CODAC = 0

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = '004 - Acquirer key not found for terminal  '
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, '004', 1;

END;

IF @GEN_TITLES = 0
	AND @CODE_SPLIT IS NOT NULL
BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = '012 - PRIVATE LABELS ESTABLISHMENTS CAN NOT HAVE SPLIT'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, '012', 1;
END;

--IF @COD_RISK_SITUATION <> 2      
--BEGIN      
-- EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT      
--         ,@PAN = @PAN      
--         ,@BRAND = @BRAND      
--         ,@CODASS_DEPTO_TERMINAL = @CODASS      
--         ,@COD_TTYPE = @TYPETRAN      
--         ,@PLOTS = @QTY_PLOTS      
--         ,@CODTAX_ASS = @CODTX      
--         ,@CODAC = NULL      
--         ,@CODETR = @TRCODE      
--         ,@COMMENT = '020 - PENDING RISK RELEASE ESTABLISHMENT'      
--         ,@TERMINALDATE = @TERMINALDATE      
--         ,@TYPE = @TYPE      
--         ,@COD_COMP = @COD_COMP      
--         ,@COD_AFFILIATOR = @COD_AFFILIATOR      
--         ,@SOURCE_TRAN = 2      
--         ,@CODE_SPLIT = @CODE_SPLIT      
--         ,@COD_EC = @EC_TRANS      
--         ,@HOLDER_NAME = @HOLDER_NAME      
--         ,@HOLDER_DOC = @HOLDER_DOC      
--         ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;      
-- THROW 60002, '020', 1;      

--END      


IF @COD_TRAN_PROD IS NOT NULL
BEGIN

EXEC [SP_VAL_SPLIT_MULT_EC] @COD_TRAN_PROD = @COD_TRAN_PROD
						   ,@COD_EC = @EC_TRANS
						   ,@QTY_PLOTS = @QTY_PLOTS
						   ,@BRAND = @BRAND
						   ,@COD_ERROR = @COD_ERROR OUTPUT
						   ,@ERROR_DESCRIPTION = @ERROR_DESCRIPTION OUTPUT
						   ,@COD_MODEL = @COD_MODEL
						   ,@COD_TTYPE = @TYPETRAN;

IF @COD_ERROR IS NOT NULL
BEGIN

EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS
								,@COD_TTYPE = @TYPETRAN
								,@PLOTS = @QTY_PLOTS
								,@CODTAX_ASS = @CODTX
								,@CODAC = NULL
								,@CODETR = @TRCODE
								,@COMMENT = @ERROR_DESCRIPTION
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@TERMINAL_VERSION = @TERMINAL_VERSION;
THROW 60002, @COD_ERROR, 1;


END;


END;



EXECUTE [SP_REG_TRANSACTION] @AMOUNT
							,@PAN
							,@BRAND
							,@CODASS_DEPTO_TERMINAL = @CODASS
							,@COD_TTYPE = @TYPETRAN
							,@PLOTS = @QTY_PLOTS
							,@CODTAX_ASS = @CODTX
							,@CODAC = @CODAC
							,@CODETR = @TRCODE
							,@TERMINALDATE = @TERMINALDATE
							,@COD_ASS_TR_ACQ = @CODAC
							,@CODPROD_ACQ = @CODPROD_ACQ
							,@TYPE = @TYPE
							,@COD_COMP = @COD_COMP
							,@COD_AFFILIATOR = @COD_AFFILIATOR
							,@SOURCE_TRAN = 2
							,@CODE_SPLIT = @CODE_SPLIT
							,@EC_TRANS = @EC_TRANS
							,@RET_CODTRAN = @CODTR_RETURN OUTPUT
							,@HOLDER_NAME = @HOLDER_NAME
							,@HOLDER_DOC = @HOLDER_DOC
							,@LOGICAL_NUMBER = @LOGICAL_NUMBER
							,@COD_PRD = @COD_TRAN_PROD
							,@COD_EC_PRD = @COD_EC_PRD
							,@TERMINAL_VERSION = @TERMINAL_VERSION;

SELECT
	@CODAC AS [ACQUIRER]
   ,@TRCODE AS [TRAN_CODE]
   ,@CODTR_RETURN AS [COD_TRAN];


END;
END;

GO
  
 
IF OBJECT_ID('[SP_REG_TRANSACTION]') IS NOT NULL DROP PROCEDURE [SP_REG_TRANSACTION]
GO
CREATE PROCEDURE [dbo].[SP_REG_TRANSACTION]                                        
/*--------------------------------------------------------------------------------------------------------------------                                        
Procedure Name: [SP_VALIDATE_TRANSACTION]                                        
Project.......: TKPP                                        
----------------------------------------------------------------------------------------------------------------------                                        
Author                          VERSION        Date                            Description                                        
----------------------------------------------------------------------------------------------------------------------                                        
Kennedy Alef     V1    27/07/2018    Creation                                        
Gian Luca Dalle Cort   V1    14/08/2018    Changed                         
Lucas Aguiar     v3    2019-04-17    ADD PARÂMETRO DO CODE_SPLIT E SUA INSERÇÃO                      
Lucas Aguiar     v4    23-04-2019    Parametro opc cod ec                               
----------------------------------------------------------------------------------------------------------------------*/                                        
(                                        
  @AMOUNT                DECIMAL(22,6),                                        
  @PAN                   VARCHAR(200),                                        
  @BRAND                 VARCHAR(200),                                        
  @CODASS_DEPTO_TERMINAL INT,                                        
  @COD_TTYPE             INT,                                        
  @PLOTS                 INT,                                        
  @CODTAX_ASS            INT,                        
  @CODAC                 INT,                                        
  @CODETR                VARCHAR(200),                                        
  @TERMINALDATE          DATETIME,                                        
  @COD_ASS_TR_ACQ        INT,                                        
  @CODPROD_ACQ           INT,                                        
  @TYPE                  VARCHAR(100),                                        
  @COD_COMP     INT,                                        
  @COD_AFFILIATOR   INT = NULL  ,                                      
  @POSWEB INT = NULL ,                                    
  @COD_EC INT = NULL ,                                    
  @COD_DESCRIPTION INT = NULL,                                    
  @DESCRIPTION VARCHAR(MAX) = NULL ,                                    
  @VALUE DECIMAL(22,6) = NULL ,                                    
  @TRACKING_DESCRIPTION VARCHAR(400) = NULL,                                  
  @COD_EQUIP INT = NULL ,                              
  @MDR DECIMAL(22,6)= NULL ,                              
  @ANTICIP DECIMAL(22,6)= NULL ,                          
  @TARIFF DECIMAL(22,6)= NULL,                    
  @SOURCE_TRAN INT = NULL,                  
  @CODE_SPLIT INT  = NULL,                  
  @EC_TRANS INT = NULL,                  
  @RET_CODTRAN INT  = NULL     OUTPUT,                
  @CREDITOR_DOC VARCHAR(100) = NULL,        
  @HOLDER_NAME VARCHAR(100)  = NULL,        
  @HOLDER_DOC VARCHAR(100)  = NULL,          
  @LOGICAL_NUMBER VARCHAR(100)  = NULL ,      
  @CUSTOMER_EMAIL VARCHAR(100) = NULL,      
  @LINK_MODE INT = NULL,      
  @CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL,    
  @COD_PRD INT = NULL,    
  @COD_EC_PRD INT = NULL,
  @BILLCODE VARCHAR(64) = NULL,
  @BILLEXPIREDATE DATETIME = NULL,
  @TERMINAL_VERSION VARCHAR(200) = NULL
)                                        
                                        
                              
AS                             
DECLARE @COD_TRAN INT = 0;
    
      
              
                  
BEGIN


INSERT INTO [TRANSACTION] (CODE,
AMOUNT,
PAN,
BRAND,
COD_ASS_DEPTO_TERMINAL,
COD_TTYPE,
PLOTS,
COD_ASS_TX_DEP,
COD_SITUATION,
EQUIPMENT_DATE,
COD_ASS_TR_COMP,
COD_PR_ACQ,
[type],
[COD_COMP],
COD_AFFILIATOR,
POSWEB,
COD_SOURCE_TRAN,
COD_EC,
CREDITOR_DOCUMENT,
[DESCRIPTION], TRACKING_TRANSACTION,
BRAZILIAN_DATE,
CARD_HOLDER_NAME,
CARD_HOLDER_DOC,
LOGICAL_NUMBER_ACQ,
CUSTOMER_EMAIL,
CUSTOMER_IDENTIFICATION,
COD_TRAN_PROD,
COD_EC_PR
, [BILLCODE]
, [BILL_EXPIRE_DATE]
, TERMINAL_VERSION)
	VALUES (@CODETR, @AMOUNT, @PAN, @BRAND, @CODASS_DEPTO_TERMINAL, @COD_TTYPE, @PLOTS, @CODTAX_ASS, 5, @TERMINALDATE, @COD_ASS_TR_ACQ, @CODPROD_ACQ, @TYPE, @COD_COMP, @COD_AFFILIATOR, @POSWEB, @SOURCE_TRAN, @EC_TRANS, @CREDITOR_DOC, @DESCRIPTION, @TRACKING_DESCRIPTION, dbo.FN_FUS_UTF(GETDATE()), @HOLDER_NAME, @HOLDER_DOC, @LOGICAL_NUMBER, @CUSTOMER_EMAIL, @CUSTOMER_IDENTIFICATION, @COD_PRD, @COD_EC_PRD, @BILLCODE, @BILLEXPIREDATE, @TERMINAL_VERSION);



IF @@rowcount < 1
THROW 60001, '002', 1;

SET @COD_TRAN = SCOPE_IDENTITY();
SET @RET_CODTRAN = @COD_TRAN;
    
      
        
          
                           
                                            
                
IF ISNULL(@CODE_SPLIT, 0) = 1                
BEGIN
INSERT INTO TRANSACTION_SERVICES (COD_ITEM_SERVICE, COD_TRAN)
	SELECT
		4
	   ,@COD_TRAN

IF @@rowcount < 1
THROW 60001, 'COULD NOT REGISTER TRANSACTION_SERVICES', 1;
END;

IF ISNULL(@LINK_MODE, 0) = 1
BEGIN
INSERT INTO TRANSACTION_SERVICES (COD_ITEM_SERVICE, COD_TRAN)
	SELECT
		10
	   ,@COD_TRAN

IF @@rowcount < 1
THROW 60001, 'COULD NOT REGISTER TRANSACTION_SERVICES', 1;
END;

--@LINK_MODE      

INSERT INTO PROCESS_BG_STATUS (CODE, COD_TYPE_PROCESS_BG, COD_SOURCE_PROCESS)
	SELECT
		@COD_TRAN
	   ,1
	   ,COD_SOURCE_PROCESS
	FROM SOURCE_PROCESS


END

GO

IF OBJECT_ID('SP_REG_TRANSACTION_DENIED') IS NOT NULL DROP PROCEDURE SP_REG_TRANSACTION_DENIED
GO
            
CREATE PROCEDURE [dbo].[SP_REG_TRANSACTION_DENIED]                    
/*----------------------------------------------------------------------------------------------------------------------                    
Procedure Name: [SP_VALIDATE_TRANSACTION]                    
Project.......: TKPP                    
------------------------------------------------------------------------------------------------------------------------                    
Author                          VERSION        Date                            Description                    
------------------------------------------------------------------------------------------------------------------------                    
Kennedy Alef     V1      27/07/2018        Creation                    
Gian Luca Dalle Cort   V1      14/08/2018        Changed                    
Lucas Aguiar       v3      2019-04-17        Registrar em tabela de associação               
Lucas Aguiar     v4      23-04-2019        Parametro opc cod ec                    
------------------------------------------------------------------------------------------------------------------------*/                    
(                    
 @AMOUNT DECIMAL(22,6),                    
 @PAN VARCHAR(200),                    
 @BRAND VARCHAR(200),                    
 @CODASS_DEPTO_TERMINAL INT,                    
 @COD_TTYPE INT,                    
 @PLOTS INT,                    
 @CODTAX_ASS INT,                    
 @CODAC INT,                    
 @CODETR VARCHAR(200),                    
 @COMMENT VARCHAR(200),                    
 @TERMINALDATE DATETIME,                    
 @TYPE VARCHAR(100),                    
 @COD_COMP INT,                    
 @COD_AFFILIATOR INT = NULL  ,                  
 @POSWEB INT = NULL ,                
 @SOURCE_TRAN INT = NULL,              
 @CODE_SPLIT INT = NULL,              
 @COD_EC INT = NULL,            
 @CREDITOR_DOC VARCHAR(100) = NULL,        
 @HOLDER_NAME VARCHAR(100)  = NULL,        
 @HOLDER_DOC VARCHAR(100)  = NULL,         
 @LOGICAL_NUMBER VARCHAR(100)  = NULL ,      
 @CUSTOMER_EMAIL VARCHAR(100) = NULL,      
 @LINK_MODE INT = NULL,      
 @CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL,    
 @COD_PRD INT = NULL,    
 @COD_EC_PRD INT = NULL, 
 @BILLCODE VARCHAR(64) = NULL,
 @BILLEXPIREDATE DATETIME = NULL,
 @TERMINAL_VERSION VARCHAR(200) = NULL
 )                    
                
 AS                    
                     
DECLARE @COD_TRAN INT = 0;
    
      
        
          
            
              
                  
BEGIN

INSERT INTO [TRANSACTION] (CODE,
AMOUNT,
PAN,
BRAND,
COD_ASS_DEPTO_TERMINAL,
COD_TTYPE,
PLOTS,
COD_ASS_TX_DEP,
COD_SITUATION,
COD_ASS_TR_COMP,
COMMENT,
EQUIPMENT_DATE,
[type],
COD_COMP,
COD_AFFILIATOR,
POSWEB,
COD_SOURCE_TRAN,
COD_EC,
CREDITOR_DOCUMENT,
BRAZILIAN_DATE,
CARD_HOLDER_NAME,
CARD_HOLDER_DOC,
LOGICAL_NUMBER_ACQ,
CUSTOMER_EMAIL,
CUSTOMER_IDENTIFICATION,
COD_TRAN_PROD,
COD_EC_PR
, [BILLCODE]
, [BILL_EXPIRE_DATE]
, TERMINAL_VERSION)
	VALUES (@CODETR, @AMOUNT, @PAN, @BRAND, @CODASS_DEPTO_TERMINAL, @COD_TTYPE, @PLOTS, @CODTAX_ASS, 9, @CODAC, @COMMENT, @TERMINALDATE, @TYPE, @COD_COMP, @COD_AFFILIATOR, @POSWEB, @SOURCE_TRAN, @COD_EC, @CREDITOR_DOC, dbo.FN_FUS_UTF(GETDATE()), @HOLDER_NAME, @HOLDER_DOC, @LOGICAL_NUMBER, @CUSTOMER_EMAIL, @CUSTOMER_IDENTIFICATION, @COD_PRD, @COD_EC_PRD, @BILLCODE, @BILLEXPIREDATE, @TERMINAL_VERSION);


IF @@rowcount < 1
THROW 60001, '002', 1;

SET @COD_TRAN = SCOPE_IDENTITY();
    
      
        
          
            
      
IF @CODE_SPLIT IS NOT NULL              
BEGIN
INSERT INTO TRANSACTION_SERVICES (COD_ITEM_SERVICE, COD_TRAN)
	SELECT
		4
	   ,@COD_TRAN

IF @@rowcount < 1
THROW 60001, 'COULD NOT REGISTER TRANSACTION_SERVICES', 1;
END;

IF ISNULL(@LINK_MODE, 0) = 1
BEGIN
INSERT INTO TRANSACTION_SERVICES (COD_ITEM_SERVICE, COD_TRAN)
	SELECT
		10
	   ,@COD_TRAN

IF @@rowcount < 1
THROW 60001, 'COULD NOT REGISTER TRANSACTION_SERVICES', 1;
END;



INSERT INTO PROCESS_BG_STATUS (CODE, COD_TYPE_PROCESS_BG, COD_SOURCE_PROCESS)
	SELECT
		@COD_TRAN
	   ,1
	   ,COD_SOURCE_PROCESS
	FROM SOURCE_PROCESS
END;

GO
IF OBJECT_ID('[SP_VALIDATE_PIX_TRANSACTION]') IS NOT NULL DROP PROCEDURE [SP_VALIDATE_PIX_TRANSACTION]
GO
        
CREATE PROCEDURE [dbo].[SP_VALIDATE_PIX_TRANSACTION]    
/*----------------------------------------------------------------------------------------          
  Author        VERSION     Date      Description          
------------------------------------------------------------------------------------------          
  Luiz Aquino   V1        2020-10-14   Created       
------------------------------------------------------------------------------------------*/    
(    
    @TERMINALID INT,    
    @AMOUNT DECIMAL(22, 6),    
    @PAN VARCHAR(100),/*-- ENVIAR ENDTOENDID --*/    
    @TRCODE VARCHAR(200),    
    @TERMINALDATE DATETIME,    
    @HOLDER_NAME VARCHAR(100) = NULL,    
    @HOLDER_DOC VARCHAR(100) = NULL,
	@TERMINAL_VERSION VARCHAR(200) = NULL
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
  
    
    
    IF @ERROR_MSG IS NULL AND @AMOUNT > @LIMIT    
        BEGIN
SET @ERROR_MSG = '402 - Transaction limit value exceeded"d';
SET @ERROR_CODE = '402';
  
    
        END
  
    
    
    IF @ERROR_MSG IS NULL AND @CODTX IS NULL    
        BEGIN
SET @ERROR_MSG = '404 - PLAN/TAX NOT FOUND';
SET @ERROR_CODE = '404';
  
    
        END
  
    
    
    IF @ERROR_MSG IS NULL AND @COD_AFFILIATOR IS NOT NULL    
        BEGIN
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
  
    
    
    IF @ERROR_MSG IS NULL AND @TERMINALACTIVE = 0    
        BEGIN
SET @ERROR_MSG = '003 - Blocked terminal';
SET @ERROR_CODE = '003';
  
    
        END
  
    
    
    IF @ERROR_MSG IS NULL AND @COD_RISK_SITUATION <> 2    
        BEGIN
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
  
    
    
    IF @ERROR_MSG IS NOT NULL    
        BEGIN
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
								,@HOLDER_DOC = @HOLDER_DOC
								,@TERMINAL_VERSION = @TERMINAL_VERSION;

THROW 60002, @ERROR_CODE, 1;
END

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
							,@TERMINAL_VERSION = @TERMINAL_VERSION;

DECLARE @COD_PIX_SERVICE INT
	   ,@TAX_PIX DECIMAL(22, 6)
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


INSERT INTO TRANSACTION_SERVICES (COD_ITEM_SERVICE, COD_TRAN, MODIFY_DATE, COD_EC, SERVICE_TAX, TAX_TYPE)
	VALUES (@COD_PIX_SERVICE, @CODTR_RETURN, GETDATE(), @CODEC, @TAX_PIX, @TAX_TYPE)

SELECT
	@COD_ASS_TR_COMP AS [ACQUIRER]
   ,@TRCODE AS [TRAN_CODE]
   ,@CODTR_RETURN AS [COD_TRAN];
END
END

GO

IF OBJECT_ID('VW_REPORT_FULL_CASH_FLOW') IS NOT NULL
DROP VIEW VW_REPORT_FULL_CASH_FLOW
GO
CREATE VIEW [dbo].[VW_REPORT_FULL_CASH_FLOW]          
    /*----------------------------------------------------------------------------------------                                                                
    View Name: [VW_REPORT_FULL_CASH_FLOW]                                                                
    Project.......: TKPP                                                                
    ----------------------------------------------------------------------------------------                                                                
    Author                          VERSION        Date                        Description                                                                
    ---------------------------------------------------------------------------------------                                                                 
    Caike Uch?a                       V1         30/03/2020            mdr afiliador-pela parcela                                                 
    Caike Uch?a                       V2         30/04/2020               add colunas produto ec                                          
    Caike Uch?a                       V3         03/08/2020                   add QTY_DAYS_ANTECIP                                        
    Caike Uch?a                       V4         20/08/2020                Corre??o val liquid afiliador                   
    Luiz Aquino                       v5         01/09/2020                    Plan DZero                
    Caike Uchoa                       v6         01/09/2020                   Add cod_ec_prod                
    Caike Uchoa                       V7         04/09/2020               Add correção qtd_days quando spot                
    Caike Uchoa                       v8         10/11/2020                Add Program Manager          
 Caike uchoa                       v9         22/01/2021       add correção mdr_afiliador E antecip_aff val planoDzero  
 Caike Uchoa                       v10        08/02/2021                    add QTY_BUSINESS_DAY  
 Caike Uchoa                       v10        08/02/2021                    add SITUATION_TRAN  
    ---------------------------------------------------------------------------------------*/          
AS
WITH CTE
AS
(SELECT --TOP(1000)                                                                             
		TRANSACTION_TITLES.TAX_INITIAL
	   ,TRANSACTION_TITLES.ANTICIP_PERCENT AS ANTECIP_EC
	   ,COALESCE(AFFILIATOR.[NAME], 'CELER') AS AFFILIATOR
	   ,[TRANSACTION_TYPE].CODE AS TRAN_TYPE
	   ,TRANSACTION_TITLES.PLOT
	   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].CREATED_AT) AS DATETIME) AS TRANSACTION_DATE
	   ,COMMERCIAL_ESTABLISHMENT.[NAME] AS MERSHANT
	   ,[TRANSACTION_TITLES].ACQ_TAX
	   ,[TRANSACTION_TITLES].PREVISION_PAY_DATE
	   ,[TRANSACTION_TITLES].PREVISION_RECEIVE_DATE
	   ,[TRANSACTION_TITLES].AMOUNT
	   ,[TRANSACTION].AMOUNT AS TRANSACTION_AMOUNT
	   ,[TRANSACTION].CODE AS NSU
	   ,[TRANSACTION].BRAND AS BRAND
	   ,ACQUIRER.[NAME] AS ACQUIRER
	   ,(IIF(TRANSACTION_TITLES.PLOT = 1, TRANSACTION_TITLES.RATE, 0)) AS RATE
	   ,dbo.FNC_CALC_LIQUID(TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.ACQ_TAX) AS LIQUID_SUB
	   ,COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, 0) AS ANTECIP_AFF
	   ,COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], 0) AS MDR_AFF
	   ,IIF((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		> 0, dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.ANTICIP_PERCENT, (SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, [TRANSACTION].COD_TTYPE), dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT,
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP)))) AS EC
	   ,0 AS '0'
	   ,(IIF((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		> 0, dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED
		(TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.ANTICIP_PERCENT, (SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, [TRANSACTION].COD_TTYPE), (dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		(
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT,
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(
		DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP))
		) -
		(IIF(TRANSACTION_TITLES.PLOT = 1, TRANSACTION_TITLES.RATE, 0))))) AS EC_TARIFF
	   ,[TRANSACTION].PLOTS AS TOTAL_PLOTS
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT),
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP))) AS AFF_DISCOUNT
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT,
		TRANSACTION_TITLES.ANTICIP_PERCENT)
		, (IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP)
		)) AS AFF_DISCOUNT_TARIFF
	   ,(
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		(
		TRANSACTION_TITLES.AMOUNT,
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL) +
		(IIF([TRANSACTION].COD_TTYPE = 2, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0)),
		TRANSACTION_TITLES.PLOT,
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT +
		(IIF([TRANSACTION].COD_TTYPE = 1, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0)),
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP))
		)
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL +
		(IIF([TRANSACTION].COD_TTYPE = 2, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0)),
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT +
		(IIF([TRANSACTION].COD_TTYPE = 1, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0)),
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP)))
		) AS AFF
	   ,((
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		((TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], TRANSACTION_TITLES.TAX_INITIAL)
		+
		(IIF([TRANSACTION].COD_TTYPE = 2, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0))
		,
		TRANSACTION_TITLES.PLOT,
		COALESCE(
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT)
		+
		(IIF([TRANSACTION].COD_TTYPE = 1, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0))
		,
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP)
		))
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		TRANSACTION_TITLES.TAX_INITIAL
		+
		(IIF([TRANSACTION].COD_TTYPE = 2, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0))
		,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT
		+
		(IIF([TRANSACTION].COD_TTYPE = 1, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
		, 0), 0))
		,
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP)))
		)
		+ (IIF(TRANSACTION_TITLES.PLOT = 1, TRANSACTION_TITLES.RATE, 0))
		-
		(IIF(TRANSACTION_TITLES.PLOT = 1, ISNULL([TRANSACTION_TITLES_COST].RATE_PLAN, 0), 0))
		)
		AS AFF_TARIFF
	   ,[TRANSACTION].COD_ASS_TR_COMP
	   ,TRANSACTION_TITLES.COD_TITLE
	   ,CE_DESTINY.COD_EC
	   ,COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	   ,BRANCH_EC.COD_BRANCH
	   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
	   ,[TRANSACTION].PAN
	   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS 'CPF_CNPJ_ORIGINATOR'
	   ,CE_DESTINY.[NAME] AS 'EC_NAME_DESTINY'
	   ,CE_DESTINY.CPF_CNPJ AS 'CPF_CNPJ_DESTINY'
	   ,AFFILIATOR.CPF_CNPJ AS 'CPF_AFF'
	   ,(SELECT
				EQUIPMENT.SERIAL
			FROM ASS_DEPTO_EQUIP
			INNER JOIN EQUIPMENT
				ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
			WHERE ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL)
		AS SERIAL
	   ,[TRANSACTION_DATA_EXT].[VALUE] AS 'EXTERNAL_NSU'
	   ,[TRANSACTION].CODE
	   ,[TRANSACTION].COD_TRAN
	   ,[COMPANY].COD_COMP
	   ,[REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN AS REP_COD_TRAN
	   ,[TRANSACTION].COD_SITUATION
	   ,dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES.TAX_INITIAL +
		(IIF([TRANSACTION].COD_TTYPE = 2,
		ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
		, 0), 0))
		,
		[TRANSACTION_TITLES].AMOUNT) AS LIQUID_MDR_EC
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES.ANTICIP_PERCENT +
		(IIF([TRANSACTION].COD_TTYPE = 1, ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
		, 0), 0)), 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT, [TRANSACTION_TITLES].TAX_INITIAL),
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP))
		) AS ANTECIP_DISCOUNT_EC
	   ,IIF([TRANSACTION].PLOTS = 1, dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE] +
		IIF([TRANSACTION].COD_TTYPE = 1 AND (SELECT
				COUNT(*)
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
		> 0,
		TRANSACTION_TITLES_COST.TAX_PLANDZERO,
		0), TRANSACTION_TITLES.AMOUNT),
		dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE], TRANSACTION_TITLES.AMOUNT)) AS LIQUID_MDR_AFF

	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES_COST.ANTICIP_PERCENT, 0) +
		IIF([TRANSACTION].COD_TTYPE = 1 AND (SELECT
				COUNT(*)
			FROM TRANSACTION_SERVICES
			INNER JOIN ITEMS_SERVICES_AVAILABLE
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =
				ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
			WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
			AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
		> 0, TRANSACTION_TITLES_COST.TAX_PLANDZERO, 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT,
		[TRANSACTION_TITLES_COST].[PERCENTAGE]),
		(IIF(TRANSACTION_TITLES.IS_SPOT = 1, DATEDIFF(DAY,
		TRANSACTION_TITLES.PREVISION_PAY_DATE,
		TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP))
		) AS ANTECIP_DISCOUNT_AFF
	   ,IIF((SELECT
				COUNT(*)
			FROM TRANSACTION_SERVICES WITH (NOLOCK)
			WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
			AND TRANSACTION_SERVICES.COD_ITEM_SERVICE IN (4, 19))
		> 0, 1,
		0) AS SPLIT
	   ,EC_TRAN.COD_EC AS COD_EC_TRANS
	   ,EC_TRAN.NAME AS TRANS_EC_NAME
	   ,EC_TRAN.CPF_CNPJ AS TRANS_EC_CPF_CNPJ
	   ,[TRANSACTION_TITLES].[IS_ASSIGN] ASSIGNED
	   ,[ASSIGN_FILE_TITLE].RETAINED_AMOUNT
	   ,[ASSIGN_FILE_TITLE].[ORIGINAL_DATE]
	   ,CAST([TRANSACTION_TITLES].CREATED_AT AS DATE) TRAN_TITTLE_DATE
	   ,CAST([TRANSACTION_TITLES].CREATED_AT AS TIME) TRAN_TITTLE_TIME
	   ,(SELECT TOP 1
				[NAME]
			FROM ACQUIRER(NOLOCK)
			JOIN ASSIGN_FILE_ACQUIRE(NOLOCK) fType
				ON fType.COD_AC = ACQUIRER.COD_AC
				AND fType.COD_ASSIGN_FILE_MODEL = assignModel.COD_ASSIGN_FILE_MODEL)
		[ASSIGNEE]
	   ,(SELECT
				TRANSACTION_DATA_EXT.[VALUE]
			FROM TRANSACTION_DATA_EXT WITH (NOLOCK)
			WHERE TRANSACTION_DATA_EXT.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_DATA_EXT.[NAME] = 'AUTHCODE')
		AS [AUTH_CODE]
	   ,[TRANSACTION].CREDITOR_DOCUMENT
	   ,(SELECT
				TRANSACTION_DATA_EXT.[VALUE]
			FROM TRANSACTION_DATA_EXT WITH (NOLOCK)
			WHERE TRANSACTION_DATA_EXT.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_DATA_EXT.[NAME] = 'COUNT')
		AS ORDER_CODE
	   ,TRANSACTION_TITLES.COD_SITUATION [COD_SITUATION_TITLE]
	   ,[EQUIPMENT_MODEL].CODIGO AS MODEL_POS
	   ,[SEGMENTS].[NAME] AS SEGMENT_EC
	   ,[State].UF AS STATE_EC
	   ,[CITY].[NAME] AS CITY_EC
	   ,[NEIGHBORHOOD].[NAME] AS NEIGHBORHOOD_EC
	   ,[ADDRESS_BRANCH].COD_ADDRESS
	   ,SOURCE_TRANSACTION.DESCRIPTION AS TYPE_TRAN
	   ,EC_PROD.[NAME] AS [EC_PROD]
	   ,EC_PROD.CPF_CNPJ AS [EC_PROD_CPF_CNPJ]
	   ,TRAN_PROD.[NAME] AS [NAME_PROD]
	   ,SPLIT_PROD.[PERCENTAGE] AS [PERCENT_PARTICIP_SPLIT]
	   ,[TRANSACTION_TITLES_COST].RATE_PLAN
	   ,IIF(TRANSACTION_TITLES.IS_SPOT = 1,
		DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE),
		TRANSACTION_TITLES.QTY_DAYS_ANTECIP) AS QTY_DAYS_ANTECIP
	   ,IIF([TRANSACTION_TITLES].TAX_PLANDZERO IS NULL, 0, 1) AS IS_PLANDZERO
	   ,COALESCE([TRANSACTION_TITLES].TAX_PLANDZERO, 0) TAX_PLANDZERO
	   ,ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES WITH (NOLOCK)
			INNER JOIN ITEMS_SERVICES_AVAILABLE isa
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = isa.COD_ITEM_SERVICE
			WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION].COD_EC
			AND isa.NAME = 'PlanDZero')
		, 0)
		AS TAX_PLANDZEROAFF
	   ,USER_REPRESENTANTE.IDENTIFICATION AS SALES_REPRESENTANTE
	   ,USER_REPRESENTANTE.CPF_CNPJ AS CPF_CNPJ_REPRESENTANTE
	   ,USER_REPRESENTANTE.EMAIL AS EMAIL_REPRESENTANTE
	   ,EC_PROD.COD_EC AS [COD_EC_PROD]
	   ,IIF((SELECT
				COUNT(*)
			FROM TRANSACTION_SERVICES WITH (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE ISA
				ON ISA.COD_ITEM_SERVICE = TRANSACTION_SERVICES.COD_ITEM_SERVICE
			WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
			AND ISA.NAME = 'RECURRING')
		> 0, 1,
		0) AS IS_RECURRING
	   ,AFFILIATOR.PROGRAM_MANAGER
	   ,ASSIGN_D.NEW_PREVISION ASSIGN_PREVISION
	   ,ASSIGN_D.NEW_ANTICIPATION ASSIGN_ANTICIPATION
	   ,ASSIGN_D.ASSIGNMENT_RATE ASSIGN_RATE
	   ,ASSIGN_D.NET_VALUE ASSIGN_NET_VALUE
	   ,[TRANSACTION].TERMINAL_VERSION
	   ,TRANSACTION_TITLES.QTY_BUSINESS_DAY
	   ,CASE
			WHEN [TRANSACTION].COD_SITUATION = 3 THEN 'CONFIRMADA'
			WHEN [TRANSACTION].COD_SITUATION = 14 THEN 'BLOQUEADA'
		END AS SITUATION_TRAN
	FROM [TRANSACTION_TITLES]
	WITH (NOLOCK)
	INNER JOIN [TRANSACTION]
	WITH (NOLOCK)
		ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
	LEFT JOIN [TRANSACTION_TITLES_COST]
	WITH (NOLOCK)
		ON [TRANSACTION_TITLES].COD_TITLE = TRANSACTION_TITLES_COST.COD_TITLE
	INNER JOIN [TRANSACTION_TYPE]
	WITH (NOLOCK)
		ON TRANSACTION_TYPE.COD_TTYPE = [TRANSACTION].COD_TTYPE
	LEFT JOIN AFFILIATOR
	WITH (NOLOCK)
		ON AFFILIATOR.COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR
	INNER JOIN ASS_DEPTO_EQUIP
	WITH (NOLOCK)
		ON ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
	INNER JOIN DEPARTMENTS_BRANCH
	WITH (NOLOCK)
		ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
	INNER JOIN DEPARTMENTS
	WITH (NOLOCK)
		ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
	INNER JOIN BRANCH_EC
	WITH (NOLOCK)
		ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
	INNER JOIN COMMERCIAL_ESTABLISHMENT
	WITH (NOLOCK)
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
	INNER JOIN COMMERCIAL_ESTABLISHMENT CE_DESTINY
	WITH (NOLOCK)
		ON CE_DESTINY.COD_EC = TRANSACTION_TITLES.COD_EC
	INNER JOIN PRODUCTS_ACQUIRER
	WITH (NOLOCK)
		ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ
	INNER JOIN ACQUIRER
	WITH (NOLOCK)
		ON ACQUIRER.COD_AC = PRODUCTS_ACQUIRER.COD_AC
	LEFT JOIN [TRANSACTION_DATA_EXT]
	WITH (NOLOCK)
		ON [TRANSACTION_DATA_EXT].COD_TRAN = [TRANSACTION].COD_TRAN
	INNER JOIN [dbo].[PROCESS_BG_STATUS]
	WITH (NOLOCK)
		ON ([PROCESS_BG_STATUS].CODE = [TRANSACTION].COD_TRAN)
	LEFT JOIN COMPANY
	WITH (NOLOCK)
		ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
	LEFT JOIN [dbo].[REPORT_CONSOLIDATED_TRANS_SUB]
	WITH (NOLOCK)
		ON ([REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN = [TRANSACTION].COD_TRAN)
	LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_TRAN
	WITH (NOLOCK)
		ON EC_TRAN.COD_EC = [TRANSACTION].COD_EC
	LEFT JOIN [ASSIGN_FILE_TITLE](NOLOCK)
		ON [ASSIGN_FILE_TITLE].COD_TITLE = [TRANSACTION_TITLES].COD_TITLE
		AND [ASSIGN_FILE_TITLE].ACTIVE = 1
	LEFT JOIN ASSIGN_FILE(NOLOCK)
		ON ASSIGN_FILE.COD_ASSIGN_FILE = [ASSIGN_FILE_TITLE].COD_ASSIGN_FILE
	LEFT JOIN ASSIGN_DATA(NOLOCK) ASSIGN_D
		ON ASSIGN_D.COD_TITLE = TRANSACTION_TITLES.COD_TITLE
		AND ASSIGN_D.ACTIVE = 1
	LEFT JOIN ASSIGN_FILE(NOLOCK) ASSIGN_F
		ON ASSIGN_FILE.COD_ASSIGN_FILE = ASSIGN_D.COD_ASSIGN_FILE
	LEFT JOIN ASSIGN_FILE_MODEL assignModel (NOLOCK)
		ON assignModel.COD_ASSIGN_FILE_MODEL = ASSIGN_F.COD_ASSIGN_FILE_MODEL
	INNER JOIN [EQUIPMENT]
	WITH (NOLOCK)
		ON [EQUIPMENT].COD_EQUIP = [ASS_DEPTO_EQUIP].COD_EQUIP
	INNER JOIN [EQUIPMENT_MODEL]
	WITH (NOLOCK)
		ON [EQUIPMENT_MODEL].COD_MODEL = [EQUIPMENT].COD_MODEL
	INNER JOIN [SEGMENTS]
	WITH (NOLOCK)
		ON [SEGMENTS].COD_SEG = [COMMERCIAL_ESTABLISHMENT].COD_SEG
	INNER JOIN [ADDRESS_BRANCH]
	WITH (NOLOCK)
		ON [ADDRESS_BRANCH].COD_BRANCH = [BRANCH_EC].COD_BRANCH
		AND [ADDRESS_BRANCH].ACTIVE = 1
	INNER JOIN [NEIGHBORHOOD]
	WITH (NOLOCK)
		ON [NEIGHBORHOOD].COD_NEIGH = [ADDRESS_BRANCH].COD_NEIGH
	INNER JOIN [CITY]
	WITH (NOLOCK)
		ON [CITY].COD_CITY = [NEIGHBORHOOD].COD_CITY
	INNER JOIN [State]
	WITH (NOLOCK)
		ON [State].COD_STATE = [CITY].COD_STATE
	INNER JOIN SOURCE_TRANSACTION
	WITH (NOLOCK)
		ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN
	LEFT JOIN TRANSACTION_PRODUCTS AS [TRAN_PROD]
	WITH (NOLOCK)
		ON [TRAN_PROD].COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
		AND [TRAN_PROD].ACTIVE = 1
	LEFT JOIN SPLIT_PRODUCTS SPLIT_PROD
	WITH (NOLOCK)
		ON SPLIT_PROD.COD_SPLIT_PROD = TRANSACTION_TITLES.COD_SPLIT_PROD
	LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PROD
	WITH (NOLOCK)
		ON EC_PROD.COD_EC = [TRAN_PROD].COD_EC
	LEFT JOIN SALES_REPRESENTATIVE
		ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
	LEFT JOIN USERS USER_REPRESENTANTE
		ON USER_REPRESENTANTE.COD_USER = SALES_REPRESENTATIVE.COD_USER
	JOIN SITUATION
	WITH (NOLOCK)
		ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
	WHERE [TRANSACTION].COD_SITUATION IN (3, 14)
	AND [TRANSACTION_TITLES].COD_SITUATION != 26
	AND COALESCE([TRANSACTION_DATA_EXT].[NAME]
	, '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
	AND PROCESS_BG_STATUS.STATUS_PROCESSED = 0
	AND PROCESS_BG_STATUS.COD_SOURCE_PROCESS = 3
	AND DATEADD(MINUTE
	, -5
	, GETDATE())
	> [TRANSACTION].CREATED_AT
	AND DATEADD(MINUTE
	, -5
	, GETDATE())
	> [TRANSACTION_TITLES].CREATED_AT
	AND DATEPART(YEAR, [TRANSACTION].CREATED_AT) = DATEPART(YEAR, GETDATE())
	AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN IS NULL)
SELECT
	AFFILIATOR
   ,MERSHANT
   ,SERIAL
   ,CAST(TRANSACTION_DATE AS DATE) AS TRANSACTION_DATE
   ,CAST(TRANSACTION_DATE AS TIME) AS TRANSACTION_TIME
   ,NSU
   ,EXTERNAL_NSU
   ,TRAN_TYPE
   ,TRANSACTION_AMOUNT
   ,TOTAL_PLOTS AS QUOTA_TOTAL
   ,AMOUNT AS 'QUOTA_AMOUNT'
   ,PLOT AS QUOTA
   ,ACQUIRER
   ,ACQ_TAX AS 'MDR_ACQ'
   ,BRAND
   ,CTE.TAX_INITIAL AS 'MDR_EC'
   ,ANTECIP_EC AS 'ANTICIP_EC'
   ,MDR_AFF AS 'MDR_AFF'
   ,ANTECIP_AFF AS 'ANTICIP_AFF'
   ,LIQUID_SUB AS 'TO_RECEIVE_ACQ'
   ,CAST(PREVISION_RECEIVE_DATE AS DATE) AS 'PREDICTION_RECEIVE_DATE'
   ,(LIQUID_SUB - AFF_DISCOUNT) AS 'NET_WITHOUT_FEE_SUB'
   ,RATE_PLAN AS 'FEE_AFFILIATOR'
   ,(LIQUID_SUB - AFF_DISCOUNT_TARIFF) AS 'NET_SUB'
   ,AFF AS 'NET_WITHOUT_FEE_AFF'
   ,AFF_TARIFF AS 'NET_AFF'
   ,EC AS 'MERCHANT_WITHOUT_FEE'
   ,CTE.RATE AS 'FEE_MERCHANT'
   ,EC_TARIFF AS 'MERCHANT_NET'
   ,CAST(PREVISION_PAY_DATE AS DATE) AS 'PREDICTION_PAY_DATE'
   ,IIF(TRAN_TYPE = 'CREDITO' AND
	(CAST(PREVISION_RECEIVE_DATE AS DATE) != CAST(PREVISION_PAY_DATE AS DATE)), 1, 0) AS ANTECIPATED
   ,COD_EC
   ,CTE.COD_AFFILIATOR
   ,COD_BRANCH
   ,CTE.COD_DEPTO_BRANCH
   ,PAN
   ,CPF_CNPJ_ORIGINATOR
   ,EC_NAME_DESTINY
   ,CPF_CNPJ_DESTINY
   ,CPF_AFF
   ,CTE.CODE
   ,CTE.COD_TRAN
   ,CTE.COD_COMP
   ,CTE.REP_COD_TRAN
   ,CTE.COD_SITUATION
   ,CTE.LIQUID_MDR_EC
   ,CTE.ANTECIP_DISCOUNT_EC
   ,CTE.LIQUID_MDR_AFF
   ,CTE.ANTECIP_DISCOUNT_AFF
   ,CTE.SPLIT
   ,CTE.COD_EC_TRANS
   ,CTE.TRANS_EC_NAME
   ,CTE.TRANS_EC_CPF_CNPJ
   ,CTE.[ASSIGNED]
   ,CTE.RETAINED_AMOUNT
   ,CTE.[ORIGINAL_DATE]
   ,CTE.[ASSIGNEE]
   ,CTE.TRAN_TITTLE_DATE
   ,CTE.TRAN_TITTLE_TIME
   ,CTE.AUTH_CODE
   ,CTE.CREDITOR_DOCUMENT
   ,CTE.ORDER_CODE
   ,CTE.COD_TITLE
   ,CTE.[COD_SITUATION_TITLE]
   ,CTE.MODEL_POS
   ,CTE.SEGMENT_EC
   ,CTE.STATE_EC
   ,CTE.CITY_EC
   ,CTE.NEIGHBORHOOD_EC
   ,CTE.COD_ADDRESS
   ,CTE.TYPE_TRAN
   ,CTE.NAME_PROD
   ,CTE.EC_PROD
   ,CTE.EC_PROD_CPF_CNPJ
   ,CTE.PERCENT_PARTICIP_SPLIT
   ,CTE.QTY_DAYS_ANTECIP
   ,CTE.IS_PLANDZERO
   ,CTE.TAX_PLANDZERO
   ,CTE.EC_TARIFF
   ,CTE.AFF_TARIFF
   ,AFF
   ,CTE.TAX_PLANDZEROAFF
   ,CTE.SALES_REPRESENTANTE
   ,CTE.CPF_CNPJ_REPRESENTANTE
   ,CTE.EMAIL_REPRESENTANTE
   ,CTE.COD_EC_PROD
   ,CTE.IS_RECURRING
   ,CTE.PROGRAM_MANAGER
   ,CTE.ASSIGN_PREVISION
   ,CTE.ASSIGN_ANTICIPATION
   ,CTE.ASSIGN_RATE
   ,CTE.ASSIGN_NET_VALUE
   ,CTE.QTY_BUSINESS_DAY
   ,CTE.SITUATION_TRAN
   ,CTE.TERMINAL_VERSION
FROM CTE

GO



IF OBJECT_ID('VW_REPORT_FULL_CASH_FLOW_UP') IS NOT NULL
DROP VIEW [VW_REPORT_FULL_CASH_FLOW_UP];

GO
 
CREATE VIEW [dbo].[VW_REPORT_FULL_CASH_FLOW_UP]     
  /*----------------------------------------------------------------------------------------                                                              
  View Name: [VW_REPORT_FULL_CASH_FLOW_UP]                                                              
  Project.......: TKPP                                                              
  ----------------------------------------------------------------------------------------                                                              
  Author                          VERSION        Date                        Description                                                              
  ---------------------------------------------------------------------------------------                                                               
  Caike Uchoa                       V2        08/02/2021                    add SITUATION_TRAN
  ---------------------------------------------------------------------------------------*/        
AS
WITH CTE
AS
(SELECT --TOP(1000)                                 
		TRANSACTION_TITLES.TAX_INITIAL
	   ,TRANSACTION_TITLES.ANTICIP_PERCENT AS ANTECIP_EC
	   ,COALESCE(AFFILIATOR.[NAME], 'CELER') AS AFFILIATOR
	   ,[TRANSACTION_TYPE].CODE AS TRAN_TYPE
	   ,TRANSACTION_TITLES.PLOT
	   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].CREATED_AT) AS DATETIME) AS TRANSACTION_DATE
	   ,COMMERCIAL_ESTABLISHMENT.[NAME] AS MERSHANT
	   ,[TRANSACTION_TITLES].ACQ_TAX
	   ,[TRANSACTION_TITLES].PREVISION_PAY_DATE
	   ,[TRANSACTION_TITLES].PREVISION_RECEIVE_DATE
	   ,[TRANSACTION_TITLES].AMOUNT
	   ,[TRANSACTION].AMOUNT AS TRANSACTION_AMOUNT
	   ,[TRANSACTION].CODE AS NSU
	   ,[TRANSACTION].BRAND AS BRAND
	   ,ACQUIRER.[NAME] AS ACQUIRER
	   ,(CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END) AS RATE
	   ,dbo.FNC_CALC_LIQUID(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.ACQ_TAX) AS LIQUID_SUB
	   ,COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, 0) AS ANTECIP_AFF
	   ,COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], 0) AS MDR_AFF
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)) AS EC
	   ,0 AS '0'
	   ,(dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.TAX_INITIAL, TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.ANTICIP_PERCENT, (CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		) - (CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END)) AS EC_TARIFF
	   ,[TRANSACTION].PLOTS AS TOTAL_PLOTS
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)) AS AFF_DISCOUNT
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT,
		TRANSACTION_TITLES.ANTICIP_PERCENT)
		, (CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END
		)) AS AFF_DISCOUNT_TARIFF
	   ,(
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		(
		TRANSACTION_TITLES.AMOUNT,
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		)
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.ANTICIP_PERCENT,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END))
		) AS AFF
	   ,((
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		((TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END
		))
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		TRANSACTION_TITLES.TAX_INITIAL,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END))
		)
		+ (CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END)
		) AS AFF_TARIFF
	   ,[TRANSACTION].COD_ASS_TR_COMP
	   ,TRANSACTION_TITLES.COD_TITLE
	   ,CE_DESTINY.COD_EC
	   ,COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	   ,BRANCH_EC.COD_BRANCH
	   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
	   ,[TRANSACTION].PAN
	   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS 'CPF_CNPJ_ORIGINATOR'
	   ,CE_DESTINY.[NAME] AS 'EC_NAME_DESTINY'
	   ,CE_DESTINY.CPF_CNPJ AS 'CPF_CNPJ_DESTINY'
	   ,AFFILIATOR.CPF_CNPJ AS 'CPF_AFF'
	   ,(SELECT
				EQUIPMENT.SERIAL
			FROM ASS_DEPTO_EQUIP
			INNER JOIN EQUIPMENT
				ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
			WHERE ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL)
		AS SERIAL
	   ,[TRANSACTION_DATA_EXT].[VALUE] AS 'EXTERNAL_NSU'
	   ,[TRANSACTION].CODE
	   ,[TRANSACTION].COD_TRAN
	   ,[COMPANY].COD_COMP
	   ,[REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN AS REP_COD_TRAN
	   ,[TRANSACTION].COD_SITUATION
	   ,dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES.TAX_INITIAL, [TRANSACTION_TITLES].AMOUNT) AS LIQUID_MDR_EC
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES.ANTICIP_PERCENT, 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT, [TRANSACTION_TITLES].TAX_INITIAL),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		) AS ANTECIP_DISCOUNT_EC
	   ,dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE], [TRANSACTION].AMOUNT) AS LIQUID_MDR_AFF
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES_COST.ANTICIP_PERCENT, 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT,
		[TRANSACTION_TITLES_COST].[PERCENTAGE]),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		) AS ANTECIP_DISCOUNT_AFF
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM TRANSACTION_SERVICES WITH (NOLOCK)
					WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
					AND TRANSACTION_SERVICES.COD_ITEM_SERVICE = 4)
				> 0 THEN 1
			ELSE 0
		END AS SPLIT
	   ,EC_TRAN.COD_EC AS COD_EC_TRANS
	   ,EC_TRAN.NAME AS TRANS_EC_NAME
	   ,EC_TRAN.CPF_CNPJ AS TRANS_EC_CPF_CNPJ
	   ,[TRANSACTION_TITLES].[ASSIGNED]
	   ,[ASSIGN_FILE_TITLE].RETAINED_AMOUNT
	   ,[ASSIGN_FILE_TITLE].[ORIGINAL_DATE]
	   ,CAST([TRANSACTION_TITLES].CREATED_AT AS DATE) TRAN_TITTLE_DATE
	   ,CAST([TRANSACTION_TITLES].CREATED_AT AS TIME) TRAN_TITTLE_TIME
	   ,(SELECT TOP 1
				[NAME]
			FROM ACQUIRER(NOLOCK)
			JOIN ASSIGN_FILE_ACQUIRE(NOLOCK) fType
				ON fType.COD_AC = ACQUIRER.COD_AC
				AND fType.COD_ASSIGN_FILE_MODEL = assignModel.COD_ASSIGN_FILE_MODEL)
		[ASSIGNEE]
	   ,(SELECT
				TRANSACTION_DATA_EXT.[VALUE]
			FROM TRANSACTION_DATA_EXT WITH (NOLOCK)
			WHERE TRANSACTION_DATA_EXT.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_DATA_EXT.[NAME] = 'AUTHCODE')
		AS [AUTH_CODE]
	   ,[TRANSACTION].CREDITOR_DOCUMENT
	   ,(SELECT
				TRANSACTION_DATA_EXT.[VALUE]
			FROM TRANSACTION_DATA_EXT WITH (NOLOCK)
			WHERE TRANSACTION_DATA_EXT.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_DATA_EXT.[NAME] = 'COUNT')
		AS ORDER_CODE
	   ,TRANSACTION_TITLES.COD_SITUATION [COD_SITUATION_TITLE]
	   ,[EQUIPMENT_MODEL].CODIGO AS MODEL_POS
	   ,[SEGMENTS].[NAME] AS SEGMENT_EC
	   ,[STATE].UF AS STATE_EC
	   ,[CITY].[NAME] AS CITY_EC
	   ,[NEIGHBORHOOD].[NAME] AS NEIGHBORHOOD_EC
	   ,[ADDRESS_BRANCH].COD_ADDRESS
	   ,SOURCE_TRANSACTION.DESCRIPTION AS TYPE_TRAN
	   ,CASE
			WHEN [TRANSACTION].COD_SITUATION = 3 THEN 'CONFIRMADA'
			WHEN [TRANSACTION].COD_SITUATION = 14 THEN 'BLOQUEADA'
		END AS SITUATION_TRAN
	FROM [TRANSACTION_TITLES] WITH (NOLOCK)
	INNER JOIN [TRANSACTION] WITH (NOLOCK)
		ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
	LEFT JOIN [TRANSACTION_TITLES_COST] WITH (NOLOCK)
		ON [TRANSACTION_TITLES].COD_TITLE = TRANSACTION_TITLES_COST.COD_TITLE
	INNER JOIN [TRANSACTION_TYPE] WITH (NOLOCK)
		ON TRANSACTION_TYPE.COD_TTYPE = [TRANSACTION].COD_TTYPE
	LEFT JOIN AFFILIATOR WITH (NOLOCK)
		ON AFFILIATOR.COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR
	INNER JOIN ASS_DEPTO_EQUIP WITH (NOLOCK)
		ON ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
	INNER JOIN DEPARTMENTS_BRANCH WITH (NOLOCK)
		ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
	INNER JOIN DEPARTMENTS WITH (NOLOCK)
		ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
	INNER JOIN BRANCH_EC WITH (NOLOCK)
		ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
	INNER JOIN COMMERCIAL_ESTABLISHMENT WITH (NOLOCK)
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
	INNER JOIN COMMERCIAL_ESTABLISHMENT CE_DESTINY WITH (NOLOCK)
		ON CE_DESTINY.COD_EC = TRANSACTION_TITLES.COD_EC
	INNER JOIN PRODUCTS_ACQUIRER WITH (NOLOCK)
		ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ
	INNER JOIN ACQUIRER WITH (NOLOCK)
		ON ACQUIRER.COD_AC = PRODUCTS_ACQUIRER.COD_AC
	LEFT JOIN [TRANSACTION_DATA_EXT] WITH (NOLOCK)
		ON [TRANSACTION_DATA_EXT].COD_TRAN = [TRANSACTION].COD_TRAN
	INNER JOIN [dbo].[PROCESS_BG_STATUS] WITH (NOLOCK)
		ON ([PROCESS_BG_STATUS].CODE = [TRANSACTION].COD_TRAN)
	LEFT JOIN COMPANY WITH (NOLOCK)
		ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
	INNER JOIN [dbo].[REPORT_CONSOLIDATED_TRANS_SUB] WITH (NOLOCK)
		ON ([REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN = [TRANSACTION].COD_TRAN)
	LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_TRAN WITH (NOLOCK)
		ON EC_TRAN.COD_EC = [TRANSACTION].COD_EC
	LEFT JOIN [ASSIGN_FILE_TITLE](NOLOCK)
		ON [ASSIGN_FILE_TITLE].COD_TITLE = [TRANSACTION_TITLES].COD_TITLE
		AND [ASSIGN_FILE_TITLE].ACTIVE = 1
	LEFT JOIN ASSIGN_FILE(NOLOCK)
		ON ASSIGN_FILE.COD_ASSIGN_FILE = [ASSIGN_FILE_TITLE].COD_ASSIGN_FILE
	LEFT JOIN ASSIGN_FILE_MODEL assignModel (NOLOCK)
		ON assignModel.COD_ASSIGN_FILE_MODEL = ASSIGN_FILE.COD_ASSIGN_FILE_MODEL
	INNER JOIN [EQUIPMENT] WITH (NOLOCK)
		ON [EQUIPMENT].COD_EQUIP = [ASS_DEPTO_EQUIP].COD_EQUIP
	INNER JOIN [EQUIPMENT_MODEL] WITH (NOLOCK)
		ON [EQUIPMENT_MODEL].COD_MODEL = [EQUIPMENT].COD_MODEL
	INNER JOIN [SEGMENTS] WITH (NOLOCK)
		ON [SEGMENTS].COD_SEG = [COMMERCIAL_ESTABLISHMENT].COD_SEG
	INNER JOIN [ADDRESS_BRANCH] WITH (NOLOCK)
		ON [ADDRESS_BRANCH].COD_BRANCH = [BRANCH_EC].COD_BRANCH
		AND [ADDRESS_BRANCH].ACTIVE = 1
	INNER JOIN [NEIGHBORHOOD] WITH (NOLOCK)
		ON [NEIGHBORHOOD].COD_NEIGH = [ADDRESS_BRANCH].COD_NEIGH
	INNER JOIN [CITY] WITH (NOLOCK)
		ON [CITY].COD_CITY = [NEIGHBORHOOD].COD_CITY
	INNER JOIN [STATE] WITH (NOLOCK)
		ON [STATE].COD_STATE = [CITY].COD_STATE
	INNER JOIN SOURCE_TRANSACTION WITH (NOLOCK)
		ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN
	WHERE [TRANSACTION].COD_SITUATION IN (6, 10, 14)
	AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION <> [TRANSACTION].COD_SITUATION
	AND [TRANSACTION_TITLES].COD_SITUATION != 26
	AND COALESCE([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
	AND PROCESS_BG_STATUS.STATUS_PROCESSED = 0
	AND PROCESS_BG_STATUS.COD_SOURCE_PROCESS = 3
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION].CREATED_AT
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION_TITLES].CREATED_AT
--AND DATEPART(YEAR,[TRANSACTION].CREATED_AT) = DATEPART(YEAR,GETDATE())  
)
SELECT
	AFFILIATOR
   ,MERSHANT
   ,SERIAL
   ,CAST(TRANSACTION_DATE AS DATE) AS TRANSACTION_DATE
   ,CAST(TRANSACTION_DATE AS TIME) AS TRANSACTION_TIME
   ,NSU
   ,EXTERNAL_NSU
   ,TRAN_TYPE
   ,TRANSACTION_AMOUNT
   ,TOTAL_PLOTS AS QUOTA_TOTAL
   ,AMOUNT AS 'QUOTA_AMOUNT'
   ,PLOT AS QUOTA
   ,ACQUIRER
   ,ACQ_TAX AS 'MDR_ACQ'
   ,BRAND
   ,CTE.TAX_INITIAL AS 'MDR_EC'
   ,ANTECIP_EC AS 'ANTICIP_EC'
   ,MDR_AFF AS 'MDR_AFF'
   ,ANTECIP_AFF AS 'ANTICIP_AFF'
   ,LIQUID_SUB AS 'TO_RECEIVE_ACQ'
   ,CAST(PREVISION_RECEIVE_DATE AS DATE) AS 'PREDICTION_RECEIVE_DATE'
   ,(LIQUID_SUB - AFF_DISCOUNT) AS 'NET_WITHOUT_FEE_SUB'
   ,'0' AS 'FEE_AFFILIATOR'
   ,(LIQUID_SUB - AFF_DISCOUNT_TARIFF) AS 'NET_SUB'
   ,AFF AS 'NET_WITHOUT_FEE_AFF'
   ,AFF_TARIFF AS 'NET_AFF'
   ,EC AS 'MERCHANT_WITHOUT_FEE'
   ,CTE.RATE AS 'FEE_MERCHANT'
   ,EC_TARIFF AS 'MERCHANT_NET'
   ,CAST(PREVISION_PAY_DATE AS DATE) AS 'PREDICTION_PAY_DATE'
   ,CASE
		WHEN TRAN_TYPE = 'CREDITO' AND
			(CAST(PREVISION_RECEIVE_DATE AS DATE) != CAST(PREVISION_PAY_DATE AS DATE)) THEN 1
		ELSE 0
	END AS ANTECIPATED
   ,COD_EC
   ,CTE.COD_AFFILIATOR
   ,COD_BRANCH
   ,CTE.COD_DEPTO_BRANCH
   ,PAN
   ,CPF_CNPJ_ORIGINATOR
   ,EC_NAME_DESTINY
   ,CPF_CNPJ_DESTINY
   ,CPF_AFF
   ,CTE.CODE
   ,CTE.COD_TRAN
   ,CTE.COD_COMP
   ,CTE.REP_COD_TRAN
   ,CTE.COD_SITUATION
   ,CTE.LIQUID_MDR_EC
   ,CTE.ANTECIP_DISCOUNT_EC
   ,CTE.LIQUID_MDR_AFF
   ,CTE.ANTECIP_DISCOUNT_AFF
   ,CTE.SPLIT
   ,CTE.COD_EC_TRANS
   ,CTE.TRANS_EC_NAME
   ,CTE.TRANS_EC_CPF_CNPJ
   ,CTE.[ASSIGNED]
   ,CTE.RETAINED_AMOUNT
   ,CTE.[ORIGINAL_DATE]
   ,CTE.[ASSIGNEE]
   ,CTE.TRAN_TITTLE_DATE
   ,CTE.TRAN_TITTLE_TIME
   ,CTE.AUTH_CODE
   ,CTE.CREDITOR_DOCUMENT
   ,CTE.ORDER_CODE
   ,CTE.COD_TITLE
   ,CTE.[COD_SITUATION_TITLE]
   ,CTE.MODEL_POS
   ,CTE.SEGMENT_EC
   ,CTE.STATE_EC
   ,CTE.CITY_EC
   ,CTE.NEIGHBORHOOD_EC
   ,CTE.COD_ADDRESS
   ,CTE.TYPE_TRAN
   ,CTE.SITUATION_TRAN
FROM CTE


GO
 

IF OBJECT_ID('SP_REG_REPORT_CONSOLIDATED_TRANS_SUB') IS NOT NULL
DROP PROCEDURE SP_REG_REPORT_CONSOLIDATED_TRANS_SUB
GO
CREATE PROCEDURE [dbo].[SP_REG_REPORT_CONSOLIDATED_TRANS_SUB]    
    WITH RECOMPILE    
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author                          VERSION           Date             Description    
------------------------------------------------------------------------------------------    
    Fernando Henrique F. de O       V1              28/12/2018      Creation    
    Fernando Henrique F. de O       V2              07/02/2019      Changed    
    Luiz Aquino                     V3              22/02/2019      Remove Incomplete Installments    
    Lucas Aguiar                    V4              22-04-2019      add originador e destino    
    Caike Ucha                      V5              16/08/2019      add columns AUTH_CODE e CREDITOR_DOCUMENT    
    Caike Ucha                      V6              11/09/2019      add column ORDER_CODE    
    Marcus Gall                     V7              27/11/2019      Add Model_POS, Segment, Location_EC    
    Ana Paula Liick                 V8              31/01/2020      Add Origem_Trans    
    Caike Ucha                      V9              30/04/2020      add produto ec    
    Caike Uchoa                     V10             03/08/2020      add QTY_DAYS_ANTECIP    
    Caike Uchoa                     V11             06/08/2020      Add AMOUNT_NEW    
    Caike Uchoa                     V12             27/08/2020      add representante    
    Luiz Aquino                     V13             02/07/2020      PlanDZero (ET-895)    
    Caike Uchoa                     v14             01/09/2020      Add cod_ec_prod    
    Caike Uchoa                     v15             10/11/2020      Add Program Manager    
   Caike Uchoa                     v16             08/02/2021      add QTY_BUSINESS_DAY  
 Caike Uchoa                     v10             08/02/2021      add SITUATION_TRAN  
------------------------------------------------------------------------------------------*/    
AS    
DECLARE @COUNT INT = 0;
    
    
BEGIN

---------------------------------------------    
--------------RECORDS INSERT-----------------    
---------------------------------------------    
SELECT
	--TOP (1000)    
	[VW_REPORT_FULL_CASH_FLOW].COD_TRAN
   ,[VW_REPORT_FULL_CASH_FLOW].AFFILIATOR
   ,[VW_REPORT_FULL_CASH_FLOW].MERSHANT
   ,[VW_REPORT_FULL_CASH_FLOW].TRANSACTION_DATE
   ,[VW_REPORT_FULL_CASH_FLOW].TRANSACTION_TIME
   ,[VW_REPORT_FULL_CASH_FLOW].NSU
   ,[VW_REPORT_FULL_CASH_FLOW].QUOTA_TOTAL
   ,[VW_REPORT_FULL_CASH_FLOW].TRAN_TYPE
   ,[VW_REPORT_FULL_CASH_FLOW].QUOTA
   ,[VW_REPORT_FULL_CASH_FLOW].QUOTA_AMOUNT AMOUNT
   ,[VW_REPORT_FULL_CASH_FLOW].TRANSACTION_AMOUNT
   ,[VW_REPORT_FULL_CASH_FLOW].ACQUIRER
   ,[VW_REPORT_FULL_CASH_FLOW].MDR_ACQ
   ,[VW_REPORT_FULL_CASH_FLOW].BRAND
   ,[VW_REPORT_FULL_CASH_FLOW].MDR_EC
   ,[VW_REPORT_FULL_CASH_FLOW].ANTICIP_EC
   ,[VW_REPORT_FULL_CASH_FLOW].ANTICIP_AFF
   ,[VW_REPORT_FULL_CASH_FLOW].MDR_AFF
   ,[VW_REPORT_FULL_CASH_FLOW].NET_SUB AS NET_SUB_RATE
   ,[VW_REPORT_FULL_CASH_FLOW].ANTECIPATED
   ,[VW_REPORT_FULL_CASH_FLOW].PREDICTION_PAY_DATE
   ,[VW_REPORT_FULL_CASH_FLOW].TO_RECEIVE_ACQ
   ,[VW_REPORT_FULL_CASH_FLOW].NET_AFF
	--,COALESCE([VW_REPORT_FULL_CASH_FLOW].RATE_CURRENT_EC, 0) AS RATE_EC    
   ,[VW_REPORT_FULL_CASH_FLOW].NET_WITHOUT_FEE_AFF AS NET_WITHOUT_FEE_AFF_RATE
   ,[VW_REPORT_FULL_CASH_FLOW].NET_SUB AS NET_SUB_ACQ
   ,[VW_REPORT_FULL_CASH_FLOW].PREDICTION_RECEIVE_DATE
   ,[VW_REPORT_FULL_CASH_FLOW].FEE_MERCHANT AS RATE
   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].ANTECIP_DISCOUNT_AFF, 0) AS ANTECIP_DISCOUNT_AFF
   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].ANTECIP_DISCOUNT_EC, 0) AS ANTECIP_DISCOUNT_EC
	--,COALESCE([VW_REPORT_FULL_CASH_FLOW].MDR_CURRENT_ACQ, 0) AS MDR_CURRENT_ACQ    
   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].LIQUID_MDR_AFF, 0) AS LIQUID_MDR_AFF
	--,COALESCE([VW_REPORT_FULL_CASH_FLOW].RATE_CURRENT_AFF, 0) AS RATE_CURRENT_AFF    
	--,COALESCE([VW_REPORT_FULL_CASH_FLOW].RATE_CURRENT_EC, 0) AS RATE_CURRENT_EC    
   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].LIQUID_MDR_EC, 0) AS LIQUID_MDR_EC
   ,[VW_REPORT_FULL_CASH_FLOW].MERCHANT_WITHOUT_FEE
   ,[VW_REPORT_FULL_CASH_FLOW].FEE_AFFILIATOR
   ,[VW_REPORT_FULL_CASH_FLOW].NET_SUB
   ,[VW_REPORT_FULL_CASH_FLOW].NET_WITHOUT_FEE_SUB
   ,[VW_REPORT_FULL_CASH_FLOW].NET_WITHOUT_FEE_AFF
   ,[VW_REPORT_FULL_CASH_FLOW].MERCHANT_NET
   ,[VW_REPORT_FULL_CASH_FLOW].CPF_CNPJ_ORIGINATOR AS 'CPF_EC'
   ,[VW_REPORT_FULL_CASH_FLOW].EC_NAME_DESTINY AS 'ECNAME_DESTINY'
   ,[VW_REPORT_FULL_CASH_FLOW].CPF_CNPJ_DESTINY AS 'DESTINY'
   ,[VW_REPORT_FULL_CASH_FLOW].CPF_AFF AS CPF_AFF
   ,[VW_REPORT_FULL_CASH_FLOW].SERIAL
   ,[VW_REPORT_FULL_CASH_FLOW].EXTERNAL_NSU
   ,[VW_REPORT_FULL_CASH_FLOW].PAN
   ,[VW_REPORT_FULL_CASH_FLOW].CODE
   ,[VW_REPORT_FULL_CASH_FLOW].COD_COMP
   ,[VW_REPORT_FULL_CASH_FLOW].COD_EC
   ,[VW_REPORT_FULL_CASH_FLOW].COD_BRANCH
   ,[VW_REPORT_FULL_CASH_FLOW].COD_DEPTO_BRANCH
   ,[VW_REPORT_FULL_CASH_FLOW].COD_AFFILIATOR
   ,[VW_REPORT_FULL_CASH_FLOW].SPLIT
   ,[VW_REPORT_FULL_CASH_FLOW].COD_EC_TRANS
   ,[VW_REPORT_FULL_CASH_FLOW].TRANS_EC_NAME
   ,[VW_REPORT_FULL_CASH_FLOW].TRANS_EC_CPF_CNPJ
   ,[VW_REPORT_FULL_CASH_FLOW].COD_SITUATION
   ,[VW_REPORT_FULL_CASH_FLOW].[ASSIGNED]
   ,[VW_REPORT_FULL_CASH_FLOW].[RETAINED_AMOUNT]
   ,[VW_REPORT_FULL_CASH_FLOW].[ORIGINAL_DATE]
   ,[VW_REPORT_FULL_CASH_FLOW].[ASSIGNEE]
   ,[VW_REPORT_FULL_CASH_FLOW].TRAN_TITTLE_TIME
   ,[VW_REPORT_FULL_CASH_FLOW].TRAN_TITTLE_DATE
   ,[VW_REPORT_FULL_CASH_FLOW].AUTH_CODE
   ,[VW_REPORT_FULL_CASH_FLOW].CREDITOR_DOCUMENT
   ,[VW_REPORT_FULL_CASH_FLOW].ORDER_CODE
   ,[VW_REPORT_FULL_CASH_FLOW].COD_TITLE
   ,[VW_REPORT_FULL_CASH_FLOW].COD_SITUATION_TITLE
   ,[VW_REPORT_FULL_CASH_FLOW].MODEL_POS
   ,[VW_REPORT_FULL_CASH_FLOW].SEGMENT_EC
   ,[VW_REPORT_FULL_CASH_FLOW].STATE_EC
   ,[VW_REPORT_FULL_CASH_FLOW].CITY_EC
   ,[VW_REPORT_FULL_CASH_FLOW].NEIGHBORHOOD_EC
   ,[VW_REPORT_FULL_CASH_FLOW].COD_ADDRESS
   ,[VW_REPORT_FULL_CASH_FLOW].TYPE_TRAN
   ,[VW_REPORT_FULL_CASH_FLOW].NAME_PROD
   ,[VW_REPORT_FULL_CASH_FLOW].EC_PROD
   ,[VW_REPORT_FULL_CASH_FLOW].EC_PROD_CPF_CNPJ
   ,[VW_REPORT_FULL_CASH_FLOW].PERCENT_PARTICIP_SPLIT
   ,[VW_REPORT_FULL_CASH_FLOW].IS_PLANDZERO
   ,[VW_REPORT_FULL_CASH_FLOW].TAX_PLANDZERO
   ,[VW_REPORT_FULL_CASH_FLOW].TAX_PLANDZEROAFF
   ,dbo.VW_REPORT_FULL_CASH_FLOW.QTY_DAYS_ANTECIP
   ,[VW_REPORT_FULL_CASH_FLOW].SALES_REPRESENTANTE
   ,[VW_REPORT_FULL_CASH_FLOW].CPF_CNPJ_REPRESENTANTE
   ,[VW_REPORT_FULL_CASH_FLOW].EMAIL_REPRESENTANTE
   ,[VW_REPORT_FULL_CASH_FLOW].COD_EC_PROD
   ,[VW_REPORT_FULL_CASH_FLOW].IS_RECURRING
   ,[VW_REPORT_FULL_CASH_FLOW].PROGRAM_MANAGER
   ,[VW_REPORT_FULL_CASH_FLOW].ASSIGN_PREVISION
   ,[VW_REPORT_FULL_CASH_FLOW].ASSIGN_ANTICIPATION
   ,[VW_REPORT_FULL_CASH_FLOW].ASSIGN_RATE
   ,[VW_REPORT_FULL_CASH_FLOW].ASSIGN_NET_VALUE
   ,[VW_REPORT_FULL_CASH_FLOW].SITUATION_TRAN
   ,VW_REPORT_FULL_CASH_FLOW.TERMINAL_VERSION
   ,[VW_REPORT_FULL_CASH_FLOW].QTY_BUSINESS_DAY INTO #TB_REPORT_FULL_CASH_FLOW_INSERT
FROM [dbo].[VW_REPORT_FULL_CASH_FLOW]
ORDER BY COD_TRAN, QUOTA
OFFSET 0 ROWS FETCH FIRST 500 ROWS ONLY;

WITH TRANINFO
AS
(SELECT
		COUNT(COD_TRAN) AVAILABLE_INSTALLMENTS
	   ,COD_TRAN
	   ,QUOTA_TOTAL
	FROM #TB_REPORT_FULL_CASH_FLOW_INSERT installments
	GROUP BY COD_TRAN
			,QUOTA_TOTAL)
DELETE INSTALLMENT
	FROM #TB_REPORT_FULL_CASH_FLOW_INSERT INSTALLMENT
	JOIN TRANINFO
		ON TRANINFO.COD_TRAN = INSTALLMENT.COD_TRAN
WHERE TRANINFO.QUOTA_TOTAL > TRANINFO.AVAILABLE_INSTALLMENTS

SELECT
	@COUNT = COUNT(*)
FROM #TB_REPORT_FULL_CASH_FLOW_INSERT;

IF @COUNT > 0
BEGIN
INSERT INTO [dbo].[REPORT_CONSOLIDATED_TRANS_SUB] ([COD_TRAN],
[AFFILIATOR],
[COMMERCIALESTABLISHMENT],
[TRANSACTION_DATE],
[TRANSACTION_TIME],
[NSU],
[QUOTA_TOTAL],
[TRANSACTION_TYPE],
[PLOT],
[AMOUNT],
[TRANSACTION_AMOUNT],
[ACQUIRER],
[MDR_ACQUIRER],
[BRAND],
[MDR_EC],
[ANTECIP_PERCENT],
[ANTECIP_AFFILIATOR],
[MDR_AFFILIATOR],
[LIQUID_VALUE_SUB],
[ANTECIPATED],
[PREVISION_PAY_DATE],
[TO_RECEIVE_ACQ],
[LIQUID_VALUE_AFFILIATOR],
[LIQUID_AFF_RATE],
[LIQUID_SUB_RATE],
[PREVISION_RECEIVE_DATE],
[RATE],
[ANTECIP_CURRENT_AFF],
[ANTECIP_CURRENT_EC],
[MDR_CURRENT_AFF],
[MDR_CURRENT_EC],
[LIQUID_VALUE_EC],
[FEE_AFFILIATOR],
[NET_SUB_AQUIRER],
[NET_WITHOUT_FEE_SUB],
[NET_WITHOUT_FEE_AFF], [MERCHANT_NET],
[CPF_EC],
[DESTINY],
[CPF_AFF],
[SERIAL],
[EXTERNALNSU],
[PAN],
[CODE],
[COD_COMP],
[COD_EC],
[COD_BRANCH],
[COD_DEPTO_BRANCH],
[COD_AFFILIATOR],
[COD_SITUATION],
[SPLIT],
[COD_EC_TRANS],
[TRANS_EC_NAME],
[TRANS_EC_CPF_CNPJ]
, [ASSIGNED]
, [RETAINED_AMOUNT]
, [ORIGINAL_DATE]
, [ASSIGNEE]
, [MODIFY_DATE]
, EC_NAME_DESTINY
, TRANSACTION_TITTLE_DATE
, TRANSACTION_TITTLE_TIME
, AUTH_CODE
, CREDITOR_DOCUMENT
, ORDER_CODE
, COD_TITLE
, COD_SITUATION_TITLE
, MODEL_POS
, SEGMENT_EC
, STATE_EC
, CITY_EC
, NEIGHBORHOOD_EC
, COD_ADDRESS
, TYPE_TRAN
, NAME_PROD
, EC_PROD
, EC_PROD_CPF_CNPJ
, PERCENT_PARTICIP_SPLIT
, IS_PLANDZERO
, TAX_PLANDZERO
, QTY_DAYS_ANTECIP
, TAX_PLANDZERO_AFF
, SALES_REPRESENTANTE
, CPF_CNPJ_REPRESENTANTE
, EMAIL_REPRESENTANTE
, COD_EC_PROD
, IS_RECURRING
, PROGRAM_MANAGER
, ASSIGN_PREVISION
, ASSIGN_ANTICIPATION
, ASSIGN_RATE
, ASSIGN_NET_VALUE
, QTY_BUSINESS_DAY
, SITUATION_TRAN
, TERMINAL_VERSION)
	(SELECT
		TEMP.[COD_TRAN]
	   ,TEMP.[AFFILIATOR]
	   ,TEMP.[MERSHANT]
	   ,TEMP.[TRANSACTION_DATE]
	   ,TEMP.[TRANSACTION_TIME]
	   ,TEMP.[NSU]
	   ,TEMP.[QUOTA_TOTAL]
	   ,TEMP.[TRAN_TYPE]
	   ,TEMP.[QUOTA]
	   ,TEMP.[AMOUNT]
	   ,TEMP.[TRANSACTION_AMOUNT]
	   ,TEMP.[ACQUIRER]
	   ,TEMP.[MDR_ACQ]
	   ,TEMP.[BRAND]
	   ,TEMP.[MDR_EC]
	   ,TEMP.[ANTICIP_EC]
	   ,TEMP.[ANTICIP_AFF]
	   ,TEMP.[MDR_AFF]
	   ,TEMP.[NET_SUB_RATE]
	   ,TEMP.[ANTECIPATED]
	   ,TEMP.[PREDICTION_PAY_DATE]
	   ,TEMP.[TO_RECEIVE_ACQ]
	   ,TEMP.[NET_AFF]
	   ,TEMP.[NET_WITHOUT_FEE_AFF_RATE]
	   ,TEMP.[NET_SUB_ACQ]
	   ,TEMP.[PREDICTION_RECEIVE_DATE]
	   ,TEMP.[RATE]
	   ,TEMP.[ANTECIP_DISCOUNT_AFF]
	   ,TEMP.[ANTECIP_DISCOUNT_EC]
	   ,TEMP.[LIQUID_MDR_AFF]
	   ,TEMP.[LIQUID_MDR_EC]
	   ,TEMP.[MERCHANT_WITHOUT_FEE]
	   ,TEMP.[FEE_AFFILIATOR]
	   ,TEMP.[NET_SUB]
	   ,TEMP.[NET_WITHOUT_FEE_SUB]
	   ,TEMP.[NET_WITHOUT_FEE_AFF]
	   ,TEMP.[MERCHANT_NET]
	   ,TEMP.[CPF_AFF]
	   ,TEMP.[DESTINY]
	   ,TEMP.[CPF_EC]
	   ,TEMP.[SERIAL]
	   ,TEMP.[EXTERNAL_NSU]
	   ,TEMP.[PAN]
	   ,TEMP.[CODE]
	   ,TEMP.[COD_COMP]
	   ,TEMP.[COD_EC]
	   ,TEMP.[COD_BRANCH]
	   ,TEMP.[COD_DEPTO_BRANCH]
	   ,TEMP.[COD_AFFILIATOR]
	   ,TEMP.[COD_SITUATION]
	   ,TEMP.[SPLIT]
	   ,TEMP.[COD_EC_TRANS]
	   ,TEMP.[TRANS_EC_NAME]
	   ,TEMP.[TRANS_EC_CPF_CNPJ]
	   ,TEMP.[ASSIGNED]
	   ,TEMP.[RETAINED_AMOUNT]
	   ,TEMP.[ORIGINAL_DATE]
	   ,TEMP.[ASSIGNEE]
	   ,GETDATE()
	   ,TEMP.ECNAME_DESTINY
	   ,TRAN_TITTLE_DATE
	   ,TRAN_TITTLE_TIME
	   ,TEMP.AUTH_CODE
	   ,TEMP.CREDITOR_DOCUMENT
	   ,TEMP.ORDER_CODE
	   ,TEMP.COD_TITLE
	   ,TEMP.COD_SITUATION_TITLE
	   ,TEMP.MODEL_POS
	   ,TEMP.SEGMENT_EC
	   ,TEMP.STATE_EC
	   ,TEMP.CITY_EC
	   ,TEMP.NEIGHBORHOOD_EC
	   ,TEMP.COD_ADDRESS
	   ,TEMP.TYPE_TRAN
	   ,TEMP.NAME_PROD
	   ,TEMP.EC_PROD
	   ,TEMP.EC_PROD_CPF_CNPJ
	   ,TEMP.PERCENT_PARTICIP_SPLIT
	   ,TEMP.IS_PLANDZERO
	   ,TEMP.TAX_PLANDZERO
	   ,TEMP.QTY_DAYS_ANTECIP
	   ,TEMP.TAX_PLANDZEROAFF
	   ,TEMP.SALES_REPRESENTANTE
	   ,TEMP.CPF_CNPJ_REPRESENTANTE
	   ,TEMP.EMAIL_REPRESENTANTE
	   ,TEMP.COD_EC_PROD
	   ,TEMP.IS_RECURRING
	   ,TEMP.PROGRAM_MANAGER
	   ,TEMP.ASSIGN_PREVISION
	   ,TEMP.ASSIGN_ANTICIPATION
	   ,TEMP.ASSIGN_RATE
	   ,TEMP.ASSIGN_NET_VALUE
	   ,TEMP.QTY_BUSINESS_DAY
	   ,TEMP.SITUATION_TRAN
	   ,TEMP.TERMINAL_VERSION
	FROM #TB_REPORT_FULL_CASH_FLOW_INSERT TEMP
	)

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER [REPORT_CONSOLIDATED_TRANS_SUB] ', 1;

UPDATE [PROCESS_BG_STATUS]
SET STATUS_PROCESSED = 1
   ,MODIFY_DATE = GETDATE()
FROM [PROCESS_BG_STATUS]
INNER JOIN #TB_REPORT_FULL_CASH_FLOW_INSERT
	ON (PROCESS_BG_STATUS.CODE = #TB_REPORT_FULL_CASH_FLOW_INSERT.COD_TRAN)
WHERE [PROCESS_BG_STATUS].COD_SOURCE_PROCESS = 3;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](INSERT)', 1;
END;

---------------------------------------------    
--------------RECORDS UPDATE-----------------    
---------------------------------------------    
SELECT
	[VW_REPORT_FULL_CASH_FLOW_UP].COD_TRAN
   ,[VW_REPORT_FULL_CASH_FLOW_UP].COD_SITUATION
   ,[VW_REPORT_FULL_CASH_FLOW_UP].TRANSACTION_AMOUNT
   ,[VW_REPORT_FULL_CASH_FLOW_UP].SITUATION_TRAN INTO #TB_REPORT_FULL_CASH_FLOW_UPDATE
FROM [dbo].[VW_REPORT_FULL_CASH_FLOW_UP]


SELECT
	@COUNT = COUNT(*)
FROM #TB_REPORT_FULL_CASH_FLOW_UPDATE;

IF @COUNT > 0
BEGIN
UPDATE [REPORT_CONSOLIDATED_TRANS_SUB]
SET [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = #TB_REPORT_FULL_CASH_FLOW_UPDATE.COD_SITUATION
   ,[REPORT_CONSOLIDATED_TRANS_SUB].MODIFY_DATE = GETDATE()
   ,[REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_AMOUNT = #TB_REPORT_FULL_CASH_FLOW_UPDATE.TRANSACTION_AMOUNT
   ,[REPORT_CONSOLIDATED_TRANS_SUB].SITUATION_TRAN = #TB_REPORT_FULL_CASH_FLOW_UPDATE.SITUATION_TRAN
FROM [REPORT_CONSOLIDATED_TRANS_SUB]
INNER JOIN #TB_REPORT_FULL_CASH_FLOW_UPDATE
	ON ([REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN =
	#TB_REPORT_FULL_CASH_FLOW_UPDATE.COD_TRAN);

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [REPORT_CONSOLIDATED_TRANS_SUB]', 1;

UPDATE [PROCESS_BG_STATUS]
SET STATUS_PROCESSED = 1
   ,MODIFY_DATE = GETDATE()
FROM [PROCESS_BG_STATUS]
INNER JOIN #TB_REPORT_FULL_CASH_FLOW_UPDATE
	ON (PROCESS_BG_STATUS.CODE = #TB_REPORT_FULL_CASH_FLOW_UPDATE.COD_TRAN)
WHERE [PROCESS_BG_STATUS].COD_SOURCE_PROCESS = 3;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](UPDATE)', 1;
END;
END;

GO

IF OBJECT_ID('VW_REPORT_TRANSACTIONS_EXP') IS NOT NULL DROP VIEW VW_REPORT_TRANSACTIONS_EXP
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
		[POSWEB_DATA_TRANSACTION].[TARIFF],
		0) AS [NET_VALUE_AGENCY]
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
			AND [TS].[COD_ITEM_SERVICE] IN (4, 19))
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
		> 0, [TRANSACTION].[TRACKING_TRANSACTION],
		NULL) AS [PAYMENT_LINK_TRACKING]
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
	   ,[TRANSACTION].LOGICAL_NUMBER_ACQ AS LOGICAL_NUMBER_ACQ
	   ,DATA_TID_AVAILABLE_EC.COD_AC AS COD_ACQ_SEGMENT
	   ,(SELECT TOP 1
				SERVICE_TAX
			FROM TRANSACTION_SERVICES TS (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE I
				ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
				AND I.NAME = 'PIX'
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		AS [PIX_TAX_EC]
	   ,(SELECT TOP 1
				TAX_TYPE
			FROM TRANSACTION_SERVICES TS (NOLOCK)
			JOIN ITEMS_SERVICES_AVAILABLE I
				ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
				AND I.NAME = 'PIX'
			WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		AS [PIX_TAX_TYPE]
	   ,[TRANSACTION].TERMINAL_VERSION
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
	LEFT JOIN DATA_TID_AVAILABLE_EC
		ON DATA_TID_AVAILABLE_EC.TID = [TRANSACTION].LOGICAL_NUMBER_ACQ
		AND DATA_TID_AVAILABLE_EC.ACTIVE = 1
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
   ,CTE.LOGICAL_NUMBER_ACQ
   ,CTE.COD_ACQ_SEGMENT
   ,CTE.PIX_TAX_EC
   ,CTE.PIX_TAX_TYPE
   ,CTE.TERMINAL_VERSION
FROM CTE

GO

IF OBJECT_ID('SP_REG_REPORT_TRANSACTIONS_EXP') IS NOT NULL
DROP PROCEDURE SP_REG_REPORT_TRANSACTIONS_EXP
GO
CREATE PROCEDURE [dbo].[SP_REG_REPORT_TRANSACTIONS_EXP]  
  
/*****************************************************************************************************************  
----------------------------------------------------------------------------------------  
 Procedure Name: [SP_REG_REPORT_TRANSACTIONS_EXP]  
 Project.......: TKPP  
 ------------------------------------------------------------------------------------------  
 Author                          VERSION        Date                            Description  
 ------------------------------------------------------------------------------------------  
 Fernando Henrique F.             V1       13/12/2018                          Creation  
 Lucas Aguiar                     V2       23-04-2019                      ROTINA DE SPLIT  
 Caike Uch?a                      V3       15/08/2019                       inserting coluns  
 Marcus Gall                      V4       28/11/2019              Add Model_POS, Segment, Location EC  
 Caike Uch?a                      V5       20/01/2020                            ADD CNAE  
 Kennedy Alef                     v6       08/04/2020                      add link de pagamento  
 Caike Uch?a                      v7       30/04/2020                        insert ec prod  
 Caike Uch?a                      V8       06/08/2020                    Add [AMOUNT] to reprocess  
 Caike Uch?a                      V9       17/08/2020                        Add SALES_TYPE  
 Luiz Aquino                      v10      01/07/2020                         add PlanDzero  
 Caike Uchoa                      V11      31/08/2020                        Add Cod_ec_prod  
 Caike Uchoa                      v12      28/09/2020                        Add branch business  
 Caike Uchoa                      v10      29/09/2020                        Add NET_VALUE  
 ------------------------------------------------------------------------------------------  
*****************************************************************************************************************/  
  
AS  
BEGIN
  
  
    DECLARE @COUNT INT = 0;
  
  
  
    BEGIN

---------------------------------------------  
--------------RECORDS INSERT-----------------  
---------------------------------------------  
SELECT
	[VW_REPORT_TRANSACTIONS_EXP].[COD_TRAN]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANSACTION_CODE]
   ,[VW_REPORT_TRANSACTIONS_EXP].[Amount]
   ,[VW_REPORT_TRANSACTIONS_EXP].[PLOTS]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANSACTION_DATE]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANSACTION_TYPE]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CPF_CNPJ]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SERIAL_EQUIP]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TID]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SITUATION]
   ,[VW_REPORT_TRANSACTIONS_EXP].[Brand]
   ,[VW_REPORT_TRANSACTIONS_EXP].[PAN]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRAN_DATA_EXT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRAN_DATA_EXT_VALUE]
   ,[VW_REPORT_TRANSACTIONS_EXP].[AUTH_CODE]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_AC]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_ACQUIRER]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COMMENT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TAX]
   ,[VW_REPORT_TRANSACTIONS_EXP].[ANTICIPATION]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_AFFILIATOR]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_AFFILIATOR]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_COMP]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_EC]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_BRANCH]
   ,[VW_REPORT_TRANSACTIONS_EXP].[STATE_NAME]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CITY_NAME]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SITUATION]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_DEPTO_BRANCH]
   ,[VW_REPORT_TRANSACTIONS_EXP].[GROSS_VALUE_AGENCY]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NET_VALUE_AGENCY]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TYPE_TRAN]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SOURCE_TRAN]
   ,[VW_REPORT_TRANSACTIONS_EXP].[POSWEB]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SEGMENTS_NAME]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_EC_TRANS]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANS_EC_NAME]
   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANS_EC_CPF_CNPJ]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SPLIT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CREATED_AT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SALES_REP]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_USER_REP]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CREDITOR_DOCUMENT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SALES_REP]
   ,[VW_REPORT_TRANSACTIONS_EXP].[MODEL_POS]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CARD_NAME]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CNAE]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_USER]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_USER]
   ,[VW_REPORT_TRANSACTIONS_EXP].[LINK_PAYMENT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CUSTOMER_EMAIL]
   ,[VW_REPORT_TRANSACTIONS_EXP].[CUSTOMER_IDENTIFICATION]
   ,[VW_REPORT_TRANSACTIONS_EXP].[PAYMENT_LINK_TRACKING]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_PRODUCT_EC]
   ,[VW_REPORT_TRANSACTIONS_EXP].[EC_PRODUCT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[EC_PRODUCT_CPF_CNPJ]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SALES_TYPE]
   ,[VW_REPORT_TRANSACTIONS_EXP].PLAN_DZEROEC
   ,[VW_REPORT_TRANSACTIONS_EXP].PLAN_DZEROAFF
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_EC_PROD]
   ,[VW_REPORT_TRANSACTIONS_EXP].[BRANCH_BUSINESS_EC]
   ,CAST(0 AS DECIMAL(22, 6)) AS NET_VALUE
   ,[VW_REPORT_TRANSACTIONS_EXP].[LOGICAL_NUMBER_ACQ]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_ACQ_SEGMENT]
   ,[VW_REPORT_TRANSACTIONS_EXP].PIX_TAX_EC
   ,[VW_REPORT_TRANSACTIONS_EXP].PIX_TAX_TYPE
   ,VW_REPORT_TRANSACTIONS_EXP.TERMINAL_VERSION INTO #TB_REPORT_TRANSACTIONS_EXP_INSERT
FROM [dbo].[VW_REPORT_TRANSACTIONS_EXP]
WHERE [VW_REPORT_TRANSACTIONS_EXP].[REP_COD_TRAN] IS NULL;


SELECT
	TRANSACTION_TITLES.COD_EC
   ,[TRANSACTION].COD_TRAN
   ,TRANSACTION_SERVICES.TAX_PLANDZERO_EC INTO #TEMP_DZERO
FROM TRANSACTION_SERVICES
INNER JOIN ITEMS_SERVICES_AVAILABLE
	ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
JOIN #TB_REPORT_TRANSACTIONS_EXP_INSERT
	ON #TB_REPORT_TRANSACTIONS_EXP_INSERT.COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
JOIN TRANSACTION_TITLES WITH (NOLOCK)
	ON TRANSACTION_TITLES.COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
		AND TRANSACTION_TITLES.COD_EC = TRANSACTION_SERVICES.COD_EC
JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
GROUP BY TRANSACTION_TITLES.COD_EC
		,[TRANSACTION].COD_TRAN
		,TRANSACTION_SERVICES.TAX_PLANDZERO_EC


SELECT
	[TRANSACTION].COD_TRAN
   ,CASE
		WHEN (
			#TEMP_DZERO.TAX_PLANDZERO_EC
			)
			> 0 THEN SUM(
			dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.Amount, TRANSACTION_TITLES.PLOT,
			TRANSACTION_TITLES.TAX_INITIAL,
			TRANSACTION_TITLES.ANTICIP_PERCENT,
			(
			#TEMP_DZERO.TAX_PLANDZERO_EC
			)
			, [TRANSACTION].COD_TTYPE))
		ELSE CASE
				WHEN [TRANSACTION_TITLES].COD_TRAN IS NOT NULL THEN SUM(dbo.[FNC_ANT_VALUE_LIQ_DAYS](
					TRANSACTION_TITLES.Amount,
					TRANSACTION_TITLES.TAX_INITIAL,
					TRANSACTION_TITLES.PLOT,
					TRANSACTION_TITLES.ANTICIP_PERCENT,
					(CASE
						WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY,
							TRANSACTION_TITLES.PREVISION_PAY_DATE,
							TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
						ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
					END)))
				ELSE 0
			END
	END AS NET_VALUE INTO #TEMP_NET
FROM [TRANSACTION] WITH (NOLOCK)
LEFT JOIN [TRANSACTION_TITLES] WITH (NOLOCK)
	ON [TRANSACTION_TITLES].COD_TRAN = [TRANSACTION].COD_TRAN
LEFT JOIN #TEMP_DZERO
	ON #TEMP_DZERO.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
		AND #TEMP_DZERO.COD_EC = TRANSACTION_TITLES.COD_EC

WHERE [TRANSACTION].COD_TRAN IN (SELECT
		COD_TRAN
	FROM #TB_REPORT_TRANSACTIONS_EXP_INSERT)
GROUP BY TRANSACTION_TITLES.COD_TRAN
		,[TRANSACTION].COD_TRAN
		,#TEMP_DZERO.TAX_PLANDZERO_EC


UPDATE #TB_REPORT_TRANSACTIONS_EXP_INSERT
SET NET_VALUE = (SELECT
		NET_VALUE
	FROM #TEMP_NET
	WHERE COD_TRAN = #TB_REPORT_TRANSACTIONS_EXP_INSERT.COD_TRAN)
FROM #TB_REPORT_TRANSACTIONS_EXP_INSERT


SELECT
	@COUNT = COUNT(*)
FROM [#TB_REPORT_TRANSACTIONS_EXP_INSERT];

IF @COUNT > 0
BEGIN
INSERT INTO [dbo].[REPORT_TRANSACTIONS_EXP] ([COD_TRAN],
[TRANSACTION_CODE],
[Amount],
[PLOTS],
[TRANSACTION_DATE],
[TRANSACTION_TYPE],
[CPF_CNPJ],
[NAME],
[SERIAL_EQUIP],
[TID],
[SITUATION],
[Brand],
[PAN],
[TRAN_DATA_EXT],
[TRAN_DATA_EXT_VALUE],
[AUTH_CODE],
[COD_AC],
[NAME_ACQUIRER],
[COMMENT],
[TAX],
[ANTICIPATION],
[COD_AFFILIATOR],
[NAME_AFFILIATOR],
[NET_VALUE],
[COD_COMP],
[COD_EC],
[COD_BRANCH],
[STATE_NAME],
[CITY_NAME],
[COD_SITUATION],
[COD_DEPTO_BRANCH],
[GROSS_VALUE_AGENCY],
[NET_VALUE_AGENCY],
[TYPE_TRAN],
[COD_SOURCE_TRAN],
[POSWEB],
[SEGMENTS_NAME],
[CREATED_TRANSACTION_DATE],
[COD_EC_TRANS],
[TRANS_EC_NAME],
[TRANS_EC_CPF_CNPJ],
[SPLIT],
[SALES_REP],
[COD_USER_REP],
[MODIFY_DATE],
[CREDITOR_DOCUMENT],
[COD_SALES_REP],
[MODEL_POS],
[CARD_NAME],
[CNAE],
[COD_USER],
[NAME_USER],
[LINK_PAYMENT_SERVICE],
[CUSTOMER_EMAIL],
[CUSTOMER_IDENTIFICATION],
[PAYMENT_LINK_TRACKING],
[NAME_PRODUCT_EC],
[EC_PRODUCT],
[EC_PRODUCT_CPF_CNPJ],
[SALES_TYPE],
DZERO_EC_TAX,
DZERO_AFF_TAX,
[COD_EC_PROD],
[BRANCH_BUSINESS],
LOGICAL_NUMBER_ACQ,
COD_ACQ_SEGMENT,
PIX_TAX_EC,
PIX_TAX_TYPE,
TERMINAL_VERSION)
	(SELECT
		[TEMP].[COD_TRAN]
	   ,[TEMP].[TRANSACTION_CODE]
	   ,[TEMP].[Amount]
	   ,[TEMP].[PLOTS]
	   ,[TEMP].[TRANSACTION_DATE]
	   ,[TEMP].[TRANSACTION_TYPE]
	   ,[TEMP].[CPF_CNPJ]
	   ,[TEMP].[NAME]
	   ,[TEMP].[SERIAL_EQUIP]
	   ,[TEMP].[TID]
	   ,[TEMP].[SITUATION]
	   ,[TEMP].[Brand]
	   ,[TEMP].[PAN]
	   ,[TEMP].[TRAN_DATA_EXT]
	   ,[TEMP].[TRAN_DATA_EXT_VALUE]
	   ,[TEMP].[AUTH_CODE]
	   ,[TEMP].[COD_AC]
	   ,[TEMP].[NAME_ACQUIRER]
	   ,[TEMP].[COMMENT]
	   ,[TEMP].[TAX]
	   ,[TEMP].[ANTICIPATION]
	   ,[TEMP].[COD_AFFILIATOR]
	   ,[TEMP].[NAME_AFFILIATOR]
	   ,[TEMP].[NET_VALUE]
	   ,[TEMP].[COD_COMP]
	   ,[TEMP].[COD_EC]
	   ,[TEMP].[COD_BRANCH]
	   ,[TEMP].[STATE_NAME]
	   ,[TEMP].[CITY_NAME]
	   ,[TEMP].[COD_SITUATION]
	   ,[TEMP].[COD_DEPTO_BRANCH]
	   ,[TEMP].[GROSS_VALUE_AGENCY]
	   ,[TEMP].[NET_VALUE_AGENCY]
	   ,[TEMP].[TYPE_TRAN]
	   ,[TEMP].[COD_SOURCE_TRAN]
	   ,[TEMP].[POSWEB]
	   ,[TEMP].[SEGMENTS_NAME]
	   ,[TEMP].[CREATED_AT]
	   ,[TEMP].[COD_EC_TRANS]
	   ,[TEMP].[TRANS_EC_NAME]
	   ,[TEMP].[TRANS_EC_CPF_CNPJ]
	   ,[TEMP].[SPLIT]
	   ,[SALES_REP]
	   ,[COD_USER_REP]
	   ,GETDATE()
	   ,[CREDITOR_DOCUMENT]
	   ,[COD_SALES_REP]
	   ,[TEMP].[MODEL_POS]
	   ,[CARD_NAME]
	   ,[CNAE]
	   ,[COD_USER]
	   ,[NAME_USER]
	   ,[LINK_PAYMENT]
	   ,[CUSTOMER_EMAIL]
	   ,[CUSTOMER_IDENTIFICATION]
	   ,[TEMP].[PAYMENT_LINK_TRACKING]
	   ,[TEMP].[NAME_PRODUCT_EC]
	   ,[TEMP].[EC_PRODUCT]
	   ,[TEMP].[EC_PRODUCT_CPF_CNPJ]
	   ,[TEMP].[SALES_TYPE]
	   ,[TEMP].PLAN_DZEROEC
	   ,[TEMP].PLAN_DZEROAFF
	   ,[TEMP].[COD_EC_PROD]
	   ,[TEMP].[BRANCH_BUSINESS_EC]
	   ,TEMP.LOGICAL_NUMBER_ACQ
	   ,TEMP.COD_ACQ_SEGMENT
	   ,[TEMP].PIX_TAX_EC
	   ,[TEMP].PIX_TAX_TYPE
	   ,TEMP.TERMINAL_VERSION
	FROM [#TB_REPORT_TRANSACTIONS_EXP_INSERT] AS [TEMP]);

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER [REPORT_TRANSACTIONS_EXP] ', 1;

UPDATE [PROCESS_BG_STATUS]
SET [STATUS_PROCESSED] = 1
   ,[MODIFY_DATE] = GETDATE()
FROM [PROCESS_BG_STATUS]
INNER JOIN [#TB_REPORT_TRANSACTIONS_EXP_INSERT]
	ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_EXP_INSERT].[COD_TRAN])
WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 1;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](INSERT)', 1;
END;


---------------------------------------------  
--------------RECORDS UPDATE-----------------  
---------------------------------------------  
SELECT
	[VW_REPORT_TRANSACTIONS_EXP].[COD_TRAN]
   ,[VW_REPORT_TRANSACTIONS_EXP].[SITUATION]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COMMENT]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SITUATION]
   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_USER]
   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_USER]
   ,[VW_REPORT_TRANSACTIONS_EXP].[Amount]
   ,CAST(0 AS DECIMAL(22, 6)) AS [NET_VALUE] INTO [#TB_REPORT_TRANSACTIONS_EXP_UPDATE]
FROM [dbo].[VW_REPORT_TRANSACTIONS_EXP]
WHERE [VW_REPORT_TRANSACTIONS_EXP].[REP_COD_TRAN] IS NOT NULL;


SELECT
	TRANSACTION_TITLES.COD_EC
   ,[TRANSACTION].COD_TRAN
   ,TRANSACTION_SERVICES.TAX_PLANDZERO_EC INTO #TEMP_DZERO_2
FROM TRANSACTION_SERVICES
INNER JOIN ITEMS_SERVICES_AVAILABLE
	ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
JOIN #TB_REPORT_TRANSACTIONS_EXP_INSERT
	ON #TB_REPORT_TRANSACTIONS_EXP_INSERT.COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
JOIN TRANSACTION_TITLES WITH (NOLOCK)
	ON TRANSACTION_TITLES.COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
		AND TRANSACTION_TITLES.COD_EC = TRANSACTION_SERVICES.COD_EC
JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
GROUP BY TRANSACTION_TITLES.COD_EC
		,[TRANSACTION].COD_TRAN
		,TRANSACTION_SERVICES.TAX_PLANDZERO_EC


SELECT
	[TRANSACTION].COD_TRAN
   ,CASE
		WHEN (
			#TEMP_DZERO_2.TAX_PLANDZERO_EC
			)
			> 0 THEN SUM(
			dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.Amount, TRANSACTION_TITLES.PLOT,
			TRANSACTION_TITLES.TAX_INITIAL,
			TRANSACTION_TITLES.ANTICIP_PERCENT, (
			#TEMP_DZERO_2.TAX_PLANDZERO_EC
			)
			, [TRANSACTION].COD_TTYPE))
		ELSE CASE
				WHEN [TRANSACTION_TITLES].COD_TRAN IS NOT NULL THEN SUM(dbo.[FNC_ANT_VALUE_LIQ_DAYS](
					TRANSACTION_TITLES.Amount,
					TRANSACTION_TITLES.TAX_INITIAL,
					TRANSACTION_TITLES.PLOT,
					TRANSACTION_TITLES.ANTICIP_PERCENT,
					(CASE
						WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY,
							TRANSACTION_TITLES.PREVISION_PAY_DATE,
							TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
						ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
					END)))
				ELSE 0
			END
	END AS NET_VALUE INTO #TEMP_NET_2
FROM [TRANSACTION] WITH (NOLOCK)
LEFT JOIN [TRANSACTION_TITLES] WITH (NOLOCK)
	ON [TRANSACTION_TITLES].COD_TRAN = [TRANSACTION].COD_TRAN
LEFT JOIN #TEMP_DZERO_2
	ON #TEMP_DZERO_2.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
		AND #TEMP_DZERO_2.COD_EC = TRANSACTION_TITLES.COD_EC
WHERE [TRANSACTION].COD_TRAN IN (SELECT
		COD_TRAN
	FROM #TB_REPORT_TRANSACTIONS_EXP_UPDATE)
GROUP BY TRANSACTION_TITLES.COD_TRAN
		,[TRANSACTION].COD_TRAN
		,#TEMP_DZERO_2.TAX_PLANDZERO_EC


UPDATE #TB_REPORT_TRANSACTIONS_EXP_UPDATE
SET NET_VALUE = (SELECT
		NET_VALUE
	FROM #TEMP_NET_2
	WHERE COD_TRAN = #TB_REPORT_TRANSACTIONS_EXP_UPDATE.COD_TRAN)
FROM #TB_REPORT_TRANSACTIONS_EXP_UPDATE


SELECT
	@COUNT = COUNT(*)
FROM [#TB_REPORT_TRANSACTIONS_EXP_UPDATE];

IF @COUNT > 0
BEGIN
UPDATE [REPORT_TRANSACTIONS_EXP]
SET [REPORT_TRANSACTIONS_EXP].[SITUATION] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[SITUATION]
   ,[REPORT_TRANSACTIONS_EXP].[COD_SITUATION] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_SITUATION]
   ,[REPORT_TRANSACTIONS_EXP].[COMMENT] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COMMENT]
   ,[REPORT_TRANSACTIONS_EXP].[MODIFY_DATE] = GETDATE()
   ,[REPORT_TRANSACTIONS_EXP].[COD_USER] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_USER]
   ,[REPORT_TRANSACTIONS_EXP].[NAME_USER] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[NAME_USER]
   ,[REPORT_TRANSACTIONS_EXP].[Amount] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[Amount]
   ,[REPORT_TRANSACTIONS_EXP].NET_VALUE = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[NET_VALUE]
FROM [REPORT_TRANSACTIONS_EXP]
INNER JOIN [#TB_REPORT_TRANSACTIONS_EXP_UPDATE]
	ON ([REPORT_TRANSACTIONS_EXP].[COD_TRAN] =
	[#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_TRAN]);

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [REPORT_TRANSACTIONS_EX]', 1;

UPDATE [PROCESS_BG_STATUS]
SET [STATUS_PROCESSED] = 1
   ,[MODIFY_DATE] = GETDATE()
FROM [PROCESS_BG_STATUS]
INNER JOIN [#TB_REPORT_TRANSACTIONS_EXP_UPDATE]
	ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_TRAN])
WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 1;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](UPDATE)', 1;
END;
END;
END;

GO

IF OBJECT_ID('VW_REPORT_TRANSACTIONS_PRCS') IS NOT NULL DROP VIEW VW_REPORT_TRANSACTIONS_PRCS
GO
CREATE VIEW [dbo].[VW_REPORT_TRANSACTIONS_PRCS]  
/***********************************************************************************************************************************************            
----------------------------------------------------------------------------------------                                                                  
Procedure Name: [VW_REPORT_TRANSACTIONS_PRCS]                                                                  
Project.......: TKPP                                                                  
------------------------------------------------------------------------------------------                                                                  
Author                          VERSION        Date                            Description                                                                  
------------------------------------------------------------------------------------------                                                                  
Caike Uchôa                       v4         31-08-2020                        Add EC_PROD,CPF/CNPJ...       
------------------------------------------------------------------------------------------            
***********************************************************************************************************************************************/  
AS
SELECT TOP (1000)
	[TRANSACTION].[COD_TRAN]
   ,[TRANSACTION].[CODE] AS [TRANSACTION_CODE]
   ,[TRANSACTION].[AMOUNT] AS [AMOUNT]
   ,[TRANSACTION].[PLOTS] AS [PLOTS]
   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].[CREATED_AT]) AS DATETIME) AS [TRANSACTION_DATE]
   ,[TRANSACTION_TYPE].[CODE] AS [TRANSACTION_TYPE]
   ,[TRANSACTION_TYPE].[COD_TTYPE] AS [TYPE_TRAN]
   ,[COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ]
   ,[COMMERCIAL_ESTABLISHMENT].[NAME]
   ,[EQUIPMENT].[Serial] AS [SERIAL_EQUIP]
   ,[EQUIPMENT].[TID] AS [TID]
   ,[TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION]
   ,[TRADUCTION_SITUATION].[COD_SITUATION]
   ,[TRANSACTION].[BRAND]
   ,[TRANSACTION_DATA_EXT].[value] AS [NSU_EXT]
   ,[TRANSACTION].[PAN]
   ,[AFFILIATOR].[COD_AFFILIATOR]
   ,[AFFILIATOR].[NAME] AS [NAME_AFFILIATOR]
   ,[POSWEB_DATA_TRANSACTION].[TRACKING_TRANSACTION]
   ,[POSWEB_DATA_TRANSACTION].[DESCRIPTION] AS [DESCRIPTION]
   ,[REPORT_TRANSACTIONS].[COD_TRAN] AS [REP_COD_TRAN]
   ,[TRANSACTION].[COD_SOURCE_TRAN]
   ,[TRANSACTION].[CREATED_AT]
   ,[REPORT_TRANSACTIONS].[MODIFY_DATE]
   ,[COMPANY].[COD_COMP]
   ,[PRODUCTS_ACQUIRER].[COD_AC]
   ,[BRANCH_EC].[COD_EC]
   ,[TRANSACTION].[POSWEB]
   ,[BRANCH_EC].[COD_BRANCH]
   ,[EC_TRAN].[COD_EC] AS [COD_EC_TRANS]
   ,[EC_TRAN].[NAME] AS [TRANS_EC_NAME]
   ,[EC_TRAN].[CPF_CNPJ] AS [TRANS_EC_CPF_CNPJ]
   ,[SR].[COD_SALES_REP]
   ,[U].[IDENTIFICATION] AS [SALES_REP_NAME]
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM [TRANSACTION_SERVICES]
				WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
				AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
			> 0 THEN 1
		ELSE 0
	END AS [LINK_PAYMENT_SERVICE]
   ,[TRANSACTION].[CUSTOMER_EMAIL]
   ,[TRANSACTION].[CUSTOMER_IDENTIFICATION]
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM [TRANSACTION_SERVICES]
				WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
				AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
			> 0 THEN [TRANSACTION].[TRACKING_TRANSACTION]
		ELSE NULL
	END AS [PAYMENT_LINK_TRACKING]
   ,TRAN_PROD.[NAME] AS [NAME_PROD]
   ,EC_PROD.[NAME] AS EC_PRODUTO
   ,EC_PROD.CPF_CNPJ AS [EC_PROD_CPF_CNPJ]
   ,EC_PROD.COD_EC AS COD_EC_PROD
   ,[TRANSACTION].TERMINAL_VERSION
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [dbo].[PROCESS_BG_STATUS]
	ON ([PROCESS_BG_STATUS].[CODE] = [TRANSACTION].[COD_TRAN])
INNER JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL] = [TRANSACTION].[COD_ASS_DEPTO_TERMINAL]
INNER JOIN [EQUIPMENT]
	ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
INNER JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] = [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH]
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
INNER JOIN [ASS_TAX_DEPART]
	ON [ASS_TAX_DEPART].[COD_ASS_TX_DEP] = [TRANSACTION].[COD_ASS_TX_DEP]
INNER JOIN [PLAN]
	ON [PLAN].[COD_PLAN] = [ASS_TAX_DEPART].[COD_PLAN]
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [BRANCH_EC].[COD_EC]
INNER JOIN [COMPANY]
	ON [COMPANY].[COD_COMP] = [COMMERCIAL_ESTABLISHMENT].[COD_COMP]
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].[COD_TTYPE] = [TRANSACTION].[COD_TTYPE]
INNER JOIN [SITUATION]
	ON [SITUATION].[COD_SITUATION] = [TRANSACTION].[COD_SITUATION]
INNER JOIN [TRADUCTION_SITUATION]
	ON [TRADUCTION_SITUATION].[COD_SITUATION] = [SITUATION].[COD_SITUATION]
LEFT JOIN [dbo].[REPORT_TRANSACTIONS]
	ON ([REPORT_TRANSACTIONS].[COD_TRAN] = [TRANSACTION].[COD_TRAN])
LEFT JOIN [TRANSACTION_DATA_EXT]
	ON [TRANSACTION_DATA_EXT].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
LEFT JOIN [AFFILIATOR]
	ON [AFFILIATOR].[COD_AFFILIATOR] = [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR]
LEFT JOIN [POSWEB_DATA_TRANSACTION]
	ON [POSWEB_DATA_TRANSACTION].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
LEFT JOIN [PRODUCTS_ACQUIRER]
	ON [PRODUCTS_ACQUIRER].[COD_PR_ACQ] = [TRANSACTION].[COD_PR_ACQ]
LEFT JOIN [COMMERCIAL_ESTABLISHMENT] AS [EC_TRAN] WITH (NOLOCK)
	ON [EC_TRAN].[COD_EC] = [TRANSACTION].[COD_EC]
LEFT JOIN [SALES_REPRESENTATIVE] AS [SR]
	ON [EC_TRAN].[COD_SALES_REP] = [SR].[COD_SALES_REP]
LEFT JOIN [USERS] AS [U]
	ON [SR].[COD_USER] = [U].[COD_USER]
LEFT JOIN TRANSACTION_PRODUCTS AS TRAN_PROD
	ON TRAN_PROD.COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PROD
	ON EC_PROD.COD_EC = TRAN_PROD.COD_EC
WHERE [PROCESS_BG_STATUS].[STATUS_PROCESSED] = 0
AND [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 4
AND ISNULL([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
AND DATEADD(MINUTE, -2, GETDATE()) > [TRANSACTION].[CREATED_AT];

GO
IF OBJECT_ID('SP_REG_REPORT_TRANSACTIONS_PRCS') IS NOT NULL DROP PROCEDURE SP_REG_REPORT_TRANSACTIONS_PRCS;
GO
CREATE PROCEDURE [dbo].[SP_REG_REPORT_TRANSACTIONS_PRCS]  
  
/*****************************************************************************************************************      
----------------------------------------------------------------------------------------                              
Procedure Name: [SP_REG_REPORT_TRANSACTIONS_PRCS]                              
Project.......: TKPP                              
------------------------------------------------------------------------------------------                              
Author                          VERSION        Date                            Description                              
------------------------------------------------------------------------------------------                              
LUCAS AGUIAR                      V1        16/01/2019                          Creation                      
LUCAS AGUIAR                      V2        23-04-2019                         ROTINA SPLIT         
Caike Uchôa                       V3        12-08-2020                         ADD AMOUNT_NEW    
Caike Uchôa                       V4        31-08-2020                         Add EC_PROD, CPF_CNPJ...    
------------------------------------------------------------------------------------------      
*****************************************************************************************************************/  
  
AS  
BEGIN
  
 DECLARE @COUNT INT = 0;
  
  
  
  
  
 BEGIN

---------------------------------------------                            
--------------RECORDS INSERT-----------------                            
---------------------------------------------                           

SELECT
	[VW_REPORT_TRANSACTIONS_PRCS].[COD_TRAN]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_AC]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_COMP]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SOURCE_TRAN]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[POSWEB]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANSACTION_CODE]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[AMOUNT]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[PLOTS]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANSACTION_DATE]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANSACTION_TYPE]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TYPE_TRAN]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[CPF_CNPJ]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[NAME]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_EC]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[SERIAL_EQUIP]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TID]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[SITUATION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SITUATION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[BRAND]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[NSU_EXT]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[PAN]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_AFFILIATOR]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[NAME_AFFILIATOR]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRACKING_TRANSACTION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[DESCRIPTION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_EC_TRANS]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANS_EC_NAME]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANS_EC_CPF_CNPJ]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SALES_REP]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[CREATED_AT]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[SALES_REP_NAME]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[LINK_PAYMENT_SERVICE]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[CUSTOMER_EMAIL]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[CUSTOMER_IDENTIFICATION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[PAYMENT_LINK_TRACKING]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[NAME_PROD]
   ,[VW_REPORT_TRANSACTIONS_PRCS].EC_PRODUTO
   ,[VW_REPORT_TRANSACTIONS_PRCS].[EC_PROD_CPF_CNPJ]
   ,[VW_REPORT_TRANSACTIONS_PRCS].COD_EC_PROD
   ,[VW_REPORT_TRANSACTIONS_PRCS].TERMINAL_VERSION INTO [#TB_REPORT_TRANSACTIONS_PRCS_INSERT]
FROM [dbo].[VW_REPORT_TRANSACTIONS_PRCS]
WHERE [VW_REPORT_TRANSACTIONS_PRCS].[REP_COD_TRAN] IS NULL;

SELECT
	@COUNT = COUNT(*)
FROM [#TB_REPORT_TRANSACTIONS_PRCS_INSERT];

IF @COUNT > 0
BEGIN
INSERT INTO [dbo].[REPORT_TRANSACTIONS] ([COD_TRAN],
[COD_AC],
[COD_COMP],
[COD_SOURCE_TRAN],
[POSWEB],
[TRANSACTION_CODE],
[TYPE_TRAN],
[AMOUNT],
[PLOTS],
[TRANSACTION_DATE],
[TRANSACTION_TYPE],
[CPF_CNPJ],
[NAME],
[COD_EC],
[SERIAL_EQUIP],
[TID],
[SITUATION],
[COD_SITUATION],
[BRAND],
[NSU_EXT],
[PAN],
[COD_AFFILIATOR],
[NAME_AFFILIATOR],
[TRACKING_TRANSACTION],
[DESCRIPTION],
[COD_EC_TRANS],
[TRANS_EC_NAME],
[TRANS_EC_CPF_CNPJ],
[CREATED_AT],
[MODIFY_DATE],
[COD_SALE_REP],
[SALES_REPRESENTATIVE],
[LINK_PAYMENT_SERVICE],
[CUSTOMER_EMAIL], [CUSTOMER_IDENTIFICATION],
[PAYMENT_LINK_TRACKING],
[NAME_PROD],
[EC_PROD],
[EC_PROD_CPF_CNPJ],
[COD_EC_PROD],
TERMINAL_VERSION)
	SELECT
		[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_TRAN]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_AC]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_COMP]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_SOURCE_TRAN]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[POSWEB]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANSACTION_CODE]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TYPE_TRAN]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[AMOUNT]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[PLOTS]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANSACTION_DATE]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANSACTION_TYPE]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CPF_CNPJ]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NAME]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_EC]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[SERIAL_EQUIP]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TID]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[SITUATION]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_SITUATION]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[BRAND]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NSU_EXT]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[PAN]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_AFFILIATOR]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NAME_AFFILIATOR]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRACKING_TRANSACTION]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[DESCRIPTION]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_EC_TRANS]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANS_EC_NAME]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANS_EC_CPF_CNPJ]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CREATED_AT]
	   ,GETDATE()
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_SALES_REP]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[SALES_REP_NAME]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[LINK_PAYMENT_SERVICE]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CUSTOMER_EMAIL]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CUSTOMER_IDENTIFICATION]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[PAYMENT_LINK_TRACKING]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NAME_PROD]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[EC_PRODUTO]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[EC_PROD_CPF_CNPJ]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_EC_PROD]
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].TERMINAL_VERSION
	FROM [#TB_REPORT_TRANSACTIONS_PRCS_INSERT];

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER [REPORT_TRANSACTIONS_EXP] ', 1;

UPDATE [PROCESS_BG_STATUS]
SET [STATUS_PROCESSED] = 1
   ,[MODIFY_DATE] = GETDATE()
FROM [PROCESS_BG_STATUS]
INNER JOIN [#TB_REPORT_TRANSACTIONS_PRCS_INSERT]
	ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_TRAN])
WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 4;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](INSERT)', 1;
END;


---------------------------------------------                            
--------------RECORDS UPDATE-----------------                            
---------------------------------------------                              
SELECT
	[VW_REPORT_TRANSACTIONS_PRCS].[COD_TRAN]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SITUATION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[SITUATION]
   ,[VW_REPORT_TRANSACTIONS_PRCS].[AMOUNT] INTO [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
FROM [dbo].[VW_REPORT_TRANSACTIONS_PRCS]
WHERE [VW_REPORT_TRANSACTIONS_PRCS].[REP_COD_TRAN] IS NOT NULL;

SELECT
	@COUNT = COUNT(*)
FROM [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE];

IF @COUNT > 0
BEGIN
UPDATE [REPORT_TRANSACTIONS]
SET [REPORT_TRANSACTIONS].[SITUATION] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[SITUATION]
   ,[REPORT_TRANSACTIONS].[COD_SITUATION] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[COD_SITUATION]
   ,[REPORT_TRANSACTIONS].[MODIFY_DATE] = GETDATE()
   ,[REPORT_TRANSACTIONS].AMOUNT = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[AMOUNT]
FROM [REPORT_TRANSACTIONS]
INNER JOIN [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
	ON ([REPORT_TRANSACTIONS].[COD_TRAN] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[COD_TRAN]);

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [REPORT_TRANSACTIONS_EX]', 1;

UPDATE [PROCESS_BG_STATUS]
SET [STATUS_PROCESSED] = 1
   ,[MODIFY_DATE] = GETDATE()
FROM [PROCESS_BG_STATUS]
INNER JOIN [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
	ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[COD_TRAN])
WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 4;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](UPDATE)', 1;
END;


END;
END;

GO

IF OBJECT_ID('SP_REPORT_TRANSACTIONS_PAGE') IS NOT NULL DROP PROCEDURE SP_REPORT_TRANSACTIONS_PAGE
GO

CREATE PROCEDURE [dbo].[SP_REPORT_TRANSACTIONS_PAGE]    
/***********************************************************************************************************************************************        
----------------------------------------------------------------------------------------                                                              
Procedure Name: [SP_REPORT_TRANSACTIONS_PAGE]                                                              
Project.......: TKPP                                                              
------------------------------------------------------------------------------------------                                                              
Author                          VERSION        Date                            Description                                                              
------------------------------------------------------------------------------------------                                                              
Fernando                           V1        24/01/2019                          Creation                                                              
Lucas Aguiar                       v2        26-04-2019                      Add split service                         
Elir Ribeiro                       v2        24-06-2019                 
Caike Uchôa                        v4        31-08-2020      Add EC_PROD e Arrumar porquisse Total_tran e qtd_tran    
Elir Ribeiro                       v5        24-08-2020    alter lenght terminal to 100   
------------------------------------------------------------------------------------------        
***********************************************************************************************************************************************/ (@CODCOMP VARCHAR(10),    
@INITIAL_DATE DATETIME,    
@FINAL_DATE DATETIME,    
@EC VARCHAR(10),    
@BRANCH VARCHAR(10) = NULL,    
@DEPART VARCHAR(10) = NULL,    
@TERMINAL VARCHAR(100),    
@STATE VARCHAR(100) = NULL,    
@CITY VARCHAR(100) = NULL,    
@TYPE_TRAN INT,    
@SITUATION VARCHAR(10),    
@NSU VARCHAR(100) = NULL,    
@NSU_EXT VARCHAR(100) = NULL,    
@BRAND VARCHAR(50) = NULL,    
@PAN VARCHAR(50) = NULL,    
@CODAFF INT = NULL,    
@TRACKING_TRANSACTION VARCHAR(100) = NULL,    
@DESCRIPTION VARCHAR(100) = NULL,    
@SPOT_ELEGIBLE INT = NULL,    
@COD_ACQ VARCHAR(10) = NULL,    
@SOURCE_TRAN INT = NULL,    
@POSWEB INT = 0,    
@INITIAL_VALUE DECIMAL(22, 6) = NULL,    
@FINAL_VALUE DECIMAL(22, 6) = NULL,    
@QTD_BY_PAGE INT,    
@NEXT_PAGE INT,    
@SPLIT INT = NULL,    
@COD_SALES_REP INT = NULL,    
@COD_EC_PROD INT = NULL,    
@TOTAL_REGS INT OUTPUT,    
@TOTAL_AMOUNT DECIMAL(22, 6) OUTPUT,
@TERMINAL_VERSION VARCHAR(200) = NULL
)
AS
    
BEGIN
    
    
 DECLARE @QUERY_BASIS_PARAMETERS NVARCHAR(MAX) = '';
    
 DECLARE @QUERY_BASIS_SELECT NVARCHAR(MAX) = '';
    
 DECLARE @QUERY_BASIS_COUNT NVARCHAR(MAX) = '';
    
    
 DECLARE @TIME_FINAL_DATE TIME;
    
 DECLARE @CNT INT;
    
 DECLARE @TAMOUNT DECIMAL(22, 6);
--DECLARE @PARAMS nvarchar(max);                

SET NOCOUNT ON;
SET ARITHABORT ON;
    
    
 BEGIN

SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');

--SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                        
--SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                 )                          

SET @FINAL_DATE = DATEADD([MILLISECOND], 999, @FINAL_DATE);
    
    
    
  IF (@TIME_FINAL_DATE = '00:00:00')
SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'));


SET @QUERY_BASIS_SELECT = '                                                        
   SELECT                                                           
    [REPORT_TRANSACTIONS].TRANSACTION_CODE AS TRANSACTION_CODE,                                       
    [REPORT_TRANSACTIONS].AMOUNT,           
    [REPORT_TRANSACTIONS].PLOTS,                                                          
    [REPORT_TRANSACTIONS].TRANSACTION_DATE AS TRANSACTION_DATE,                                                          
    [REPORT_TRANSACTIONS].TRANSACTION_TYPE,                                                          
    [REPORT_TRANSACTIONS].CPF_CNPJ,                                              
    [REPORT_TRANSACTIONS].NAME,                                                          
    [REPORT_TRANSACTIONS].SERIAL_EQUIP,                                                          
    [REPORT_TRANSACTIONS].TID,                                                          
    [REPORT_TRANSACTIONS].SITUATION,                                                          
    [REPORT_TRANSACTIONS].BRAND,                                        
    [REPORT_TRANSACTIONS].NSU_EXT,                                                      
    [REPORT_TRANSACTIONS].PAN,                                                
    [REPORT_TRANSACTIONS].COD_AFFILIATOR,                                    
    [REPORT_TRANSACTIONS].NAME_AFFILIATOR AS NAME_AFFILIATOR ,                                                   
    [REPORT_TRANSACTIONS].TRACKING_TRANSACTION AS COD_RAST,                                            
    [REPORT_TRANSACTIONS].DESCRIPTION AS DESCRIPTION,        
    REPORT_TRANSACTIONS.LINK_PAYMENT_SERVICE,        
    REPORT_TRANSACTIONS.CUSTOMER_EMAIL,        
    REPORT_TRANSACTIONS.CUSTOMER_IDENTIFICATION,        
    REPORT_TRANSACTIONS.PAYMENT_LINK_TRACKING,    
 REPORT_TRANSACTIONS.NAME_PROD,    
 REPORT_TRANSACTIONS.EC_PROD,    
 REPORT_TRANSACTIONS.EC_PROD_CPF_CNPJ,
 REPORT_TRANSACTIONS.TERMINAL_VERSION
   FROM [REPORT_TRANSACTIONS]                  
   LEFT JOIN TRANSACTION_SERVICES ON TRANSACTION_SERVICES.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN      
          AND [TRANSACTION_SERVICES].COD_ITEM_SERVICE = 4      
   WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                        
      --AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)          
   ';


SET @QUERY_BASIS_COUNT = '                                                        
   SELECT     
   @CNT=COUNT(COD_REPORT_TRANS),    
   @TAMOUNT = SUM([REPORT_TRANSACTIONS].AMOUNT)    
   FROM [REPORT_TRANSACTIONS]                     
   LEFT JOIN TRANSACTION_SERVICES ON TRANSACTION_SERVICES.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN      
    AND [TRANSACTION_SERVICES].COD_ITEM_SERVICE = 4      
        
   WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                                                           
      --AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)          
   ';


SET @QUERY_BASIS_PARAMETERS = '';
    
    
  IF (@INITIAL_DATE IS NOT NULL    
   AND @FINAL_DATE IS NOT NULL)
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, 'AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)');

IF @EC IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_EC = @EC ');

IF @BRANCH IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '  AND [REPORT_TRANSACTIONS].COD_BRANCH =  @BRANCH ');

IF @DEPART IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_DEPTO_BRANCH =  @DEPART ');

IF LEN(@TERMINAL) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '  AND [REPORT_TRANSACTIONS].SERIAL_EQUIP = @TERMINAL');

IF LEN(@STATE) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '  AND [REPORT_TRANSACTIONS].STATE_NAME = @STATE ');

IF LEN(@CITY) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].CITY_NAME = @CITY ');

IF @TYPE_TRAN IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND EXISTS( SELECT CODE FROM TRANSACTION_TYPE tt WHERE tt.COD_TTYPE = @TYPE_TRAN AND [REPORT_TRANSACTIONS].TRANSACTION_TYPE = tt.CODE ) ');

IF @SITUATION IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_SITUATION = @SITUATION ');

IF LEN(@BRAND) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].BRAND = @BRAND ');

IF LEN(@NSU) > 0

SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].TRANSACTION_CODE = @NSU ');

IF LEN(@NSU_EXT) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].NSU_EXT = @NSU_EXT ');

IF @PAN IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].PAN = @PAN ');

IF (@CODAFF IS NOT NULL)
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_AFFILIATOR = @CodAff ');

IF LEN(@TRACKING_TRANSACTION) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].TRACKING_TRANSACTION  = @TRACKING_TRANSACTION ');

IF LEN(@DESCRIPTION) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND  [REPORT_TRANSACTIONS].DESCRIPTION  LIKE  %@DESCRIPTION%');

IF @SPOT_ELEGIBLE = 1
BEGIN
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND  [REPORT_TRANSACTIONS].PLOTS > 1         
    AND EXISTS(SELECT title.COD_TRAN FROM TRANSACTION_TITLES title JOIN [TRANSACTION] title_tran ON title_tran.COD_TRAN = title.COD_TRAN WHERE [REPORT_TRANSACTIONS].COD_TRAN = title_tran.COD_TRA         
    AND title.PREVISION_PAY_DATE > @FINAL_DATE and title.cod_situation = 4 and isnull(title.ANTICIP_PERCENT,0) <= 0  ) ');
    
  END;

IF @COD_ACQ IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_AC = @COD_ACQ');

IF @SOURCE_TRAN IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_SOURCE_TRAN = @SOURCE_TRAN');

IF @POSWEB = 1
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].POSWEB = @POSWEB');

IF (@INITIAL_VALUE > 0)
	AND (@FINAL_VALUE >= @INITIAL_VALUE)
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].AMOUNT BETWEEN @INITIAL_VALUE AND @FINAL_VALUE');

IF @SPLIT = 1
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, 'AND TRANSACTION_SERVICES.COD_ITEM_SERVICE = 4');

IF @COD_SALES_REP IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_SALE_REP = @COD_SALES_REP ');

IF @COD_EC_PROD IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_EC_PROD = @COD_EC_PROD ');
IF @TERMINAL_VERSION IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].TERMINAL_VERSION = @TERMINAL_VERSION ');


SET @QUERY_BASIS_COUNT = CONCAT(@QUERY_BASIS_COUNT, @QUERY_BASIS_PARAMETERS);



EXEC [sp_executesql] @QUERY_BASIS_COUNT
					,N'                                                                  
   @CODCOMP VARCHAR(10),                                            
   @INITIAL_DATE DATETIME,                                                                  
   @FINAL_DATE DATETIME,                                           
   @EC int,                                                                  
   @BRANCH int,                                                                  
   @DEPART int,                                                                   
   @TERMINAL varchar(100),                                                                  
   @STATE varchar(25),                                                                  
   @CITY varchar(40),                               
   @TYPE_TRAN int,                                                                  
   @SITUATION int,                                                         
   @NSU varchar(100),                                                                  
   @NSU_EXT varchar(100),                                                                  
   @BRAND varchar(50) ,                                                                
   @PAN VARCHAR(50),           
   @CodAff INT,                                            
   @TRACKING_TRANSACTION  VARCHAR(100),                                                    
   @DESCRIPTION  VARCHAR(100),                                        
   @COD_ACQ  VARCHAR(10),                                        
   @SOURCE_TRAN VARCHAR(12),                                        
   @POSWEB int,                                          
   @INITIAL_VALUE DECIMAL(22,6),                                            
   @FINAL_VALUE DECIMAL(22,6),                
   @CNT INT OUTPUT,        
   @TAMOUNT DECIMAL(22,6) OUTPUT,     
   @COD_SALES_REP INT,     
   @COD_EC_PROD INT,
   @TERMINAL_VERSION VARCHAR(200)
   '
					,@CODCOMP = @CODCOMP
					,@INITIAL_DATE = @INITIAL_DATE
					,@FINAL_DATE = @FINAL_DATE
					,@EC = @EC
					,@BRANCH = @BRANCH
					,@DEPART = @DEPART
					,@TERMINAL = @TERMINAL
					,@STATE = @STATE
					,@CITY = @CITY
					,@TYPE_TRAN = @TYPE_TRAN
					,@SITUATION = @SITUATION
					,@NSU = @NSU
					,@NSU_EXT = @NSU_EXT
					,@BRAND = @BRAND
					,@PAN = @PAN
					,@CODAFF = @CODAFF
					,@TRACKING_TRANSACTION = @TRACKING_TRANSACTION
					,@DESCRIPTION = @DESCRIPTION
					,@COD_ACQ = @COD_ACQ
					,@SOURCE_TRAN = @SOURCE_TRAN
					,@POSWEB = @POSWEB
					,@INITIAL_VALUE = @INITIAL_VALUE
					,@FINAL_VALUE = @FINAL_VALUE
					,@CNT = @CNT OUTPUT
					,@TAMOUNT = @TAMOUNT OUTPUT
					,@COD_SALES_REP = @COD_SALES_REP
					,@COD_EC_PROD = @COD_EC_PROD
					,@TERMINAL_VERSION = @TERMINAL_VERSION;


SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' ORDER BY [REPORT_TRANSACTIONS].TRANSACTION_DATE DESC ');
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' OFFSET (@NEXT_PAGE - 1) * @QTD_BY_PAGE ROWS');
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' FETCH NEXT @QTD_BY_PAGE ROWS ONLY');

SET @TOTAL_AMOUNT = @TAMOUNT;
SET @TOTAL_REGS = @CNT;
SET @QUERY_BASIS_SELECT = CONCAT(@QUERY_BASIS_SELECT, @QUERY_BASIS_PARAMETERS);


EXEC [sp_executesql] @QUERY_BASIS_SELECT
					,N'                                                                  
   @CODCOMP VARCHAR(10),                                    
   @INITIAL_DATE DATETIME,                                                                  
   @FINAL_DATE DATETIME,                                           
   @EC int,                                                                  
   @BRANCH int,                                                                  
   @DEPART int,                                                                   
   @TERMINAL varchar(100),                                                                  
   @STATE varchar(25),                                                                  
   @CITY varchar(40),                                                               
   @TYPE_TRAN int,                                                                  
   @SITUATION int,                                                         
   @NSU varchar(100),                                                                  
   @NSU_EXT varchar(100),                                                                  
   @BRAND varchar(50) ,                                                                
   @PAN VARCHAR(50),                                                          
   @CodAff INT,                                            
   @TRACKING_TRANSACTION  VARCHAR(100),                                                    
   @DESCRIPTION  VARCHAR(100),                                        
   @COD_ACQ  VARCHAR(10),                                        
   @SOURCE_TRAN VARCHAR(12),                                        
   @POSWEB int,                                          
   @INITIAL_VALUE DECIMAL(22,6),                                                                  
   @FINAL_VALUE DECIMAL(22,6),                
   @QTD_BY_PAGE INT,                 
   @NEXT_PAGE INT,              
   @COD_SALES_REP INT,    
   @COD_EC_PROD INT,
   @TERMINAL_VERSION VARCHAR(200)
   '
					,@CODCOMP = @CODCOMP
					,@INITIAL_DATE = @INITIAL_DATE
					,@FINAL_DATE = @FINAL_DATE
					,@EC = @EC
					,@BRANCH = @BRANCH
					,@DEPART = @DEPART
					,@TERMINAL = @TERMINAL
					,@STATE = @STATE
					,@CITY = @CITY
					,@TYPE_TRAN = @TYPE_TRAN
					,@SITUATION = @SITUATION
					,@NSU = @NSU
					,@NSU_EXT = @NSU_EXT
					,@BRAND = @BRAND
					,@PAN = @PAN
					,@CODAFF = @CODAFF
					,@TRACKING_TRANSACTION = @TRACKING_TRANSACTION
					,@DESCRIPTION = @DESCRIPTION
					,@COD_ACQ = @COD_ACQ
					,@SOURCE_TRAN = @SOURCE_TRAN
					,@POSWEB = @POSWEB
					,@INITIAL_VALUE = @INITIAL_VALUE
					,@FINAL_VALUE = @FINAL_VALUE
					,@QTD_BY_PAGE = @QTD_BY_PAGE
					,@NEXT_PAGE = @NEXT_PAGE
					,@COD_SALES_REP = @COD_SALES_REP
					,@COD_EC_PROD = @COD_EC_PROD
					,@TERMINAL_VERSION = @TERMINAL_VERSION;

END;
END;

GO
------ multilinguagem
IF OBJECT_ID('SP_REPORT_TRANSACTIONS_EXP') IS NOT NULL
DROP PROCEDURE [SP_REPORT_TRANSACTIONS_EXP]
GO
CREATE PROCEDURE [dbo].[SP_REPORT_TRANSACTIONS_EXP]  
/***************************************************************************************  
----------------------------------------------------------------------------------------  
Procedure Name: [SP_REPORT_TRANSACTIONS_EXP]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author               VERSION         Date                     Description  
------------------------------------------------------------------------------------------  
Fernando Henrique F.   V1         13/12/2018               Creation  
Kennedy Alef           V2         16/01/2018               Modify  
Lucas Aguiar           V2         23/04/2019               ROTINA DE SPLIT  
Caike Uch?a            V3         15/08/2019               inserting coluns  
Marcus Gall            V4         28/11/2019               Add Model_POS, Segment, Location EC  
Caike Uch?a            V5         20/01/2020               ADD CNAE  
Kennedy Alef           v3         08/04/2020               add link de pagamento  
Caike Uch?a            v4         30/04/2020               insert ec prod  
Caike Uch?a            v5         17/08/2020               Add SALES_TYPE  
Luiz Aquino            v6         01/07/2020                 add PlanDzero  
Caike Uchoa            v7         31/08/2020               Add cod_ec_prod  
 Caike Uchoa           v12        28/09/2020               Add branch business  
Elir Ribeiro           v13        24/11/2020              terminal length to 100  
---------------------------------------------           ---------------------------------------------  
********************************************************************************************/ (@CODCOMP VARCHAR(10),  
                                                                                               @INITIAL_DATE DATETIME,  
                                                                                               @FINAL_DATE DATETIME,  
                                                                                               @EC VARCHAR(10),  
                                                                                               @BRANCH VARCHAR(10),  
                                                                                               @DEPART VARCHAR(10),  
                                                                                               @TERMINAL VARCHAR(100),  
                                                                                               @STATE VARCHAR(100),  
                                                                                               @CITY VARCHAR(100),  
                                                                                               @TYPE_TRAN VARCHAR(10),  
                                                                                               @SITUATION VARCHAR(10),  
                                                                                               @NSU VARCHAR(100) = NULL,  
                                                                                               @NSU_EXT VARCHAR(100) = NULL,  
                                                                                               @BRAND VARCHAR(50) = NULL,  
                                                                                               @PAN VARCHAR(50) = NULL,  
                                                                                               @COD_AFFILIATOR INT = NULL,  
                                                                                               @TRACKING_TRANSACTION VARCHAR(100) = NULL,  
                                                                                               @DESCRIPTION VARCHAR(100) = NULL,  
                                                                                               @SPOT_ELEGIBLE INT = 0,  
                                                           @COD_ACQ INT = NULL,  
                                                                                               @SOURCE_TRAN INT = NULL,  
                                                                                               @POSWEB INT = 0,  
                                                                                               @SPLIT INT = NULL,  
                                                                                               @INITIAL_VALUE DECIMAL(22, 6) = NULL,  
                                                                                               @FINAL_VALUE DECIMAL(22, 6) = NULL,  
                                                                                               @COD_SALES_REP INT = NULL,  
                                                                                               @COD_EC_PROD INT = NULL,
@TERMINAL_VERSION VARCHAR(200) = NULL)  
AS  
BEGIN
  
    DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';
  
    DECLARE @TIME_FINAL_DATE TIME;
SET NOCOUNT ON;
SET ARITHABORT ON;
  
    BEGIN
SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');
--SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));  
--SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0)); )  
SET @FINAL_DATE = DATEADD([MILLISECOND], 999, @FINAL_DATE);
  
        IF (@TIME_FINAL_DATE = '00:00:00')
SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'));
SET @QUERY_BASIS = '  
   SELECT [REPORT_TRANSACTIONS_EXP].TRANSACTION_CODE  
      ,[REPORT_TRANSACTIONS_EXP].AMOUNT  
      ,[REPORT_TRANSACTIONS_EXP].PLOTS  
      ,[REPORT_TRANSACTIONS_EXP].TRANSACTION_DATE  
      ,[REPORT_TRANSACTIONS_EXP].TRANSACTION_TYPE  
      ,[REPORT_TRANSACTIONS_EXP].CPF_CNPJ  
      ,[REPORT_TRANSACTIONS_EXP].NAME  
      ,[REPORT_TRANSACTIONS_EXP].SERIAL_EQUIP  
      ,[REPORT_TRANSACTIONS_EXP].TID  
      ,[REPORT_TRANSACTIONS_EXP].SITUATION  
      ,[REPORT_TRANSACTIONS_EXP].BRAND  
      ,[REPORT_TRANSACTIONS_EXP].PAN  
      ,COALESCE([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT_VALUE, '''') AS TRAN_DATA_EXT_VALUE  
      ,COALESCE([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT, '''') AS TRAN_DATA_EXT  
   ,(  
      SELECT TRANSACTION_DATA_EXT.[VALUE] FROM TRANSACTION_DATA_EXT  
   WHERE TRANSACTION_DATA_EXT.[NAME]= ''AUTHCODE'' AND TRANSACTION_DATA_EXT.COD_TRAN = REPORT_TRANSACTIONS_EXP.COD_TRAN  
   ) AS [AUTH_CODE]  
   ,[REPORT_TRANSACTIONS_EXP].COD_AC  
   ,[REPORT_TRANSACTIONS_EXP].NAME_ACQUIRER  
   ,[REPORT_TRANSACTIONS_EXP].COMMENT  
   ,[REPORT_TRANSACTIONS_EXP].TAX  
   ,[REPORT_TRANSACTIONS_EXP].ANTICIPATION  
   ,[REPORT_TRANSACTIONS_EXP].COD_AFFILIATOR  
   ,[REPORT_TRANSACTIONS_EXP].NAME_AFFILIATOR  
   ,[REPORT_TRANSACTIONS_EXP].NET_VALUE  
   ,[REPORT_TRANSACTIONS_EXP].GROSS_VALUE_AGENCY  
   ,[REPORT_TRANSACTIONS_EXP].NET_VALUE_AGENCY  
   ,[REPORT_TRANSACTIONS_EXP].TYPE_TRAN  
   ,[REPORT_TRANSACTIONS_EXP].POSWEB  
   ,[REPORT_TRANSACTIONS_EXP].CITY_NAME  
   ,[REPORT_TRANSACTIONS_EXP].STATE_NAME  
   ,[REPORT_TRANSACTIONS_EXP].SEGMENTS_NAME  
   ,[REPORT_TRANSACTIONS_EXP].COD_EC_TRANS  
   ,[REPORT_TRANSACTIONS_EXP].TRANS_EC_NAME  
   ,[REPORT_TRANSACTIONS_EXP].TRANS_EC_CPF_CNPJ  
   ,[REPORT_TRANSACTIONS_EXP].SPLIT  
   ,[REPORT_TRANSACTIONS_EXP].[SALES_REP]  
   ,[REPORT_TRANSACTIONS_EXP].CREDITOR_DOCUMENT  
   ,REPORT_TRANSACTIONS_EXP.COD_SALES_REP  
   ,[REPORT_TRANSACTIONS_EXP].MODEL_POS  
   ,[REPORT_TRANSACTIONS_EXP].CARD_NAME  
   ,[REPORT_TRANSACTIONS_EXP].CNAE  
   ,[REPORT_TRANSACTIONS_EXP].LINK_PAYMENT_SERVICE  
   ,[REPORT_TRANSACTIONS_EXP].CUSTOMER_EMAIL  
   ,[REPORT_TRANSACTIONS_EXP].CUSTOMER_IDENTIFICATION  
   ,[REPORT_TRANSACTIONS_EXP].PAYMENT_LINK_TRACKING  
   ,[REPORT_TRANSACTIONS_EXP].[NAME_PRODUCT_EC]  
   ,[REPORT_TRANSACTIONS_EXP].[EC_PRODUCT]  
   ,[REPORT_TRANSACTIONS_EXP].[EC_PRODUCT_CPF_CNPJ]  
   ,[REPORT_TRANSACTIONS_EXP].[SALES_TYPE]  
   ,ISNULL([REPORT_TRANSACTIONS_EXP].DZERO_EC_TAX, 0) AS DZERO_EC_TAX  
   ,ISNULL([REPORT_TRANSACTIONS_EXP].DZERO_AFF_TAX, 0)       AS DZERO_AFF_TAX  
   ,[REPORT_TRANSACTIONS_EXP].[COD_EC_PROD]  
   ,[REPORT_TRANSACTIONS_EXP].[BRANCH_BUSINESS]  
   ,ISNULL([REPORT_TRANSACTIONS_EXP].PIX_TAX_EC, 0) AS PIX_TAX_EC  
   ,ISNULL([REPORT_TRANSACTIONS_EXP].PIX_TAX_TYPE, '''') AS PIX_TAX_TYPE
   ,REPORT_TRANSACTIONS_EXP.TERMINAL_VERSION
   FROM [dbo].[REPORT_TRANSACTIONS_EXP]  
   WHERE [REPORT_TRANSACTIONS_EXP].COD_COMP = @CODCOMP  
    ';
  
        IF @INITIAL_DATE IS NOT NULL  
            AND @FINAL_DATE IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
' AND CAST([REPORT_TRANSACTIONS_EXP].TRANSACTION_DATE AS DATETIME) BETWEEN CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)');
IF @EC IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_EC = @EC ');
IF @BRANCH IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND[REPORT_TRANSACTIONS_EXP].COD_BRANCH = @BRANCH ');
IF @DEPART IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_DEPTO_BRANCH = @DEPART ');
IF LEN(@TERMINAL) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].SERIAL_EQUIP = @TERMINAL');
IF LEN(@STATE) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].STATE_NAME = @STATE ');
IF LEN(@CITY) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].CITY_NAME = @CITY ');
IF LEN(@TYPE_TRAN) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
' AND EXISTS( SELECT tt.CODE FROM TRANSACTION_TYPE tt WHERE tt.COD_TTYPE = @TYPE_TRAN AND [REPORT_TRANSACTIONS_EXP].TRANSACTION_TYPE = tt.CODE )');
IF LEN(@SITUATION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
' AND EXISTS( SELECT tt.SITUATION_TR FROM [TRADUCTION_SITUATION] tt WHERE tt.COD_SITUATION = @SITUATION AND [REPORT_TRANSACTIONS_EXP].SITUATION = tt.SITUATION_TR )');
IF LEN(@BRAND) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].BRAND = @BRAND ');
IF LEN(@PAN) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].PAN = @PAN ');
IF LEN(@NSU) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRANSACTION_CODE = @NSU ');
IF LEN(@NSU_EXT) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT_VALUE = @NSU_EXT ');
--ELSE  
-- SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,' AND ([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''RCPTTXID'' OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT IS NULL  
-- OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''AUTO'' OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''NSU'' ) ');  
IF @COD_AFFILIATOR IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_AFFILIATOR = @COD_AFFILIATOR ');
IF LEN(@TRACKING_TRANSACTION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
' AND [REPORT_TRANSACTIONS_EXP].TRACKING_TRANSACTION = @TRACKING_TRANSACTION ');
IF LEN(@DESCRIPTION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].DESCRIPTION LIKE %@DESCRIPTION%');
IF @SPOT_ELEGIBLE = 1
BEGIN
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].PLOTS > 1 AND (SELECT COUNT(*) FROM TRANSACTION_TITLES title JOIN [TRANSACTION] title_tran ON title_tran.COD_TRAN = title.COD_TRAN WHERE [VW_REPORT_TRANSACTIONS].TRANSACTION_CODE  
  
  
  
  
  
  
  
        = title_tran.CODE AND title.PREVISION_PAY_DATE > @FINAL_DATE ) > 0 AND TRANSACTION_TITLES.COD_SITUATION = 4 ');
  
            END;
IF @COD_ACQ IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_AC = @COD_ACQ');
IF @SOURCE_TRAN IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_SOURCE_TRAN = @SOURCE_TRAN');
IF @POSWEB = 1
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].POSWEB = @POSWEB');
IF (@INITIAL_VALUE > 0)
	AND (@FINAL_VALUE >= @INITIAL_VALUE)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
' AND [REPORT_TRANSACTIONS_EXP].AMOUNT BETWEEN @INITIAL_VALUE AND @FINAL_VALUE');
IF (@SPLIT = 1)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND [REPORT_TRANSACTIONS_EXP].SPLIT = 1');
IF @COD_SALES_REP IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_SALES_REP = @COD_SALES_REP');

IF @COD_EC_PROD IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_EC_PROD = @COD_EC_PROD');

IF @TERMINAL_VERSION IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TERMINAL_VERSION = @TERMINAL_VERSION ');

SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY [REPORT_TRANSACTIONS_EXP].CREATED_AT DESC');
--SELECT @QUERY_BASIS  
EXEC [sp_executesql] @QUERY_BASIS
					,N'  
   @CODCOMP VARCHAR(10),  
   @INITIAL_DATE DATETIME,  
   @FINAL_DATE DATETIME,  
   @EC int,  
   @BRANCH int,  
   @DEPART int,  
   @TERMINAL varchar(100),  
   @STATE varchar(25),  
   @CITY varchar(40),  
   @TYPE_TRAN VARCHAR(10),  
   @SITUATION VARCHAR(10),  
   @NSU varchar(100),  
   @NSU_EXT varchar(100),  
   @BRAND varchar(50),  
   @COD_AFFILIATOR INT,  
   @PAN VARCHAR(50),  
   @SOURCE_TRAN INT,  
   @POSWEB INT,  
   @INITIAL_VALUE DECIMAL(22,6),  
   @FINAL_VALUE DECIMAL(22,6),  
   @COD_SALES_REP INT,  
   @COD_ACQ INT,  
   @COD_EC_PROD INT,
   @TERMINAL_VERSION VARCHAR(200)
   '
					,@CODCOMP = @CODCOMP
					,@INITIAL_DATE = @INITIAL_DATE
					,@FINAL_DATE = @FINAL_DATE
					,@EC = @EC
					,@BRANCH = @BRANCH
					,@DEPART = @DEPART
					,@TERMINAL = @TERMINAL
					,@STATE = @STATE
					,@CITY = @CITY
					,@TYPE_TRAN = @TYPE_TRAN
					,@SITUATION = @SITUATION
					,@NSU = @NSU
					,@NSU_EXT = @NSU_EXT
					,@BRAND = @BRAND
					,@PAN = @PAN
					,@COD_AFFILIATOR = @COD_AFFILIATOR
					,@SOURCE_TRAN = @SOURCE_TRAN
					,@POSWEB = @POSWEB
					,@INITIAL_VALUE = @INITIAL_VALUE
					,@FINAL_VALUE = @FINAL_VALUE
					,@COD_SALES_REP = @COD_SALES_REP
					,@COD_ACQ = @COD_ACQ
					,@COD_EC_PROD = @COD_EC_PROD
					,@TERMINAL_VERSION = @TERMINAL_VERSION;
END;
END;
GO

IF OBJECT_ID('SP_REPORT_CONSOLIDATED_TRANSACTION_SUB') IS NOT NULL DROP PROCEDURE SP_REPORT_CONSOLIDATED_TRANSACTION_SUB
GO
CREATE PROCEDURE [dbo].[SP_REPORT_CONSOLIDATED_TRANSACTION_SUB]    
    
/**************************************************************************************************************                      
    Project.......: TKPP                                          
 ------------------------------------------------------------------------------------------                                          
     Author                      VERSION        Date                            Description                                          
 ------------------------------------------------------------------------------------------                                          
    Fernando Henrique F. de O       V1         28/12/2018                          Creation                                        
    Fernando Henrique F. de O       V2         07/02/2019                          Changed                                            
    Elir Ribeiro                    V3         29/07/2019                          Changed date                                  
    Caike Ucha Almeida              V4         16/08/2019                        Inserting columns                                 
    Caike Ucha Almeida              V5         11/09/2019                        Inserting column                                
    Marcus Gall                     V6         27/11/2019               Add Model_POS, Segment, Location_EC                        
    Ana Paula Liick                 V8         31/01/2020                       Add Origem_Trans                        
    Caike Ucha                      V9         30/04/2020                       add produto ec                    
    Luiz Aquino                     V10        02/07/2020                   PlanoDZero (ET-895)           
    Caike Uch�a                     V11        03/08/2020                       add QTY_DAYS_ANTECIP            
    Caike Uch�a                     V12        07/08/2020                       ISNULL na RATE_PLAN          
    Caike Uchoa                     v13        01/09/2020                       Add cod_ec_prod        
    Caike Uchoa                     v14        10/11/2020                  Add Program Manager      
    Caike Uchoa                     v15        08/02/2021                    add QTY_BUSINESS_DAY  
 Caike Uchoa                     v10        08/02/2021                   add SITUATION_TRAN  
**************************************************************************************************************/   
(@CODCOMP VARCHAR(10),    
 @INITIAL_DATE DATETIME,    
 @FINAL_DATE DATETIME,    
 @EC VARCHAR(10),    
 @BRANCH VARCHAR(10),    
 @DEPART VARCHAR(10),    
 @TERMINAL VARCHAR(100),    
 @STATE VARCHAR(100),    
 @CITY VARCHAR(100),    
 @TYPE_TRAN VARCHAR(10),    
 @SITUATION VARCHAR(10),    
 @NSU VARCHAR(100) = NULL,    
 @NSU_EXT VARCHAR(100) = NULL,    
 @BRAND VARCHAR(50) = NULL,    
 @PAN VARCHAR(50) = NULL,    
 @CODAFF INT = NULL,    
 @SPLIT INT = NULL,    
 @CODACQUIRER INT = NULL,    
 @ISPlanDZero INT = NULL,    
 @COD_EC_PROD INT = NULL,
 @TERMINAL_VERSION VARCHAR(200) = NULL)    
AS    
BEGIN
    
    
    
    DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';
    
    
    
    DECLARE @AWAITINGSPLIT INT = NULL;
SET NOCOUNT ON;
SET ARITHABORT ON;

SELECT TOP 1
	@AWAITINGSPLIT = [COD_SITUATION]
FROM [SITUATION]
WHERE [NAME] = 'WAITING FOR SPLIT OF FINANCE SCHEDULE';

SET @QUERY_BASIS = 'SELECT                                              
        [REPORT_CONSOLIDATED_TRANS_SUB].AFFILIATOR AS AFFILIATOR,                             
        [REPORT_CONSOLIDATED_TRANS_SUB].COMMERCIALESTABLISHMENT AS MERCHANT,                                                  
        [REPORT_CONSOLIDATED_TRANS_SUB].SERIAL  AS SERIAL,                                            
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE  AS TRANSACTION_DATE,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TIME  AS TRANSACTION_TIME,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].NSU  AS NSU ,                          
        [REPORT_CONSOLIDATED_TRANS_SUB].EXTERNALNSU  AS EXTERNAL_NSU,                                            
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TYPE  AS TRAN_TYPE,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_AMOUNT  AS TRANSACTION_AMOUNT,                                              
        [REPORT_CONSOLIDATED_TRANS_SUB].QUOTA_TOTAL  AS QUOTA_TOTAL,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].AMOUNT  AS  AMOUNT,                 
        [REPORT_CONSOLIDATED_TRANS_SUB].PLOT  AS QUOTA,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].ACQUIRER  AS ACQUIRER,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_ACQUIRER  AS MDR_ACQ,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].BRAND  AS BRAND,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_EC  AS MDR_EC,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_PERCENT  AS ANTICIP_EC,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_AFFILIATOR  AS MDR_AFF,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_AFFILIATOR  AS ANTICIP_AFF,                          
        [REPORT_CONSOLIDATED_TRANS_SUB].TO_RECEIVE_ACQ  AS TO_RECEIVE_ACQ,                                    
        [REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_RECEIVE_DATE  AS PREDICTION_RECEIVE_DATE,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].NET_WITHOUT_FEE_SUB  AS NET_WITHOUT_FEE_SUB,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].FEE_AFFILIATOR  AS FEE_AFFILIATOR,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].NET_SUB_AQUIRER  AS NET_SUB,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].NET_WITHOUT_FEE_AFF  AS NET_WITHOUT_FEE_AFF,                                            
        [REPORT_CONSOLIDATED_TRANS_SUB].LIQUID_VALUE_AFFILIATOR  AS NET_AFF,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].LIQUID_VALUE_EC  AS MERCHANT_WITHOUT_FEE,                          
        [REPORT_CONSOLIDATED_TRANS_SUB].MERCHANT_NET  AS MERCHANT_NET,                     
        IIF([REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE] is not null, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE] ,[REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE )  AS PREDICTION_PAY_DATE,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIPATED  AS ANTECIPATED,                                        
        [REPORT_CONSOLIDATED_TRANS_SUB].RATE,                                        
        --[REPORT_CONSOLIDATED_TRANS_SUB].MDR_CURRENT_ACQ  AS MDR_CURRENT_ACQ,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_CURRENT_EC  AS MDR_CURRENT_EC,                          
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_CURRENT_EC  AS ANTICIP_CURRENT_EC,                                                
        --[REPORT_CONSOLIDATED_TRANS_SUB].RATE_CURRENT_EC  AS RATE_CURRENT_EC,                                              
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_CURRENT_AFF  AS MDR_CURRENT_AFF,                                                
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_CURRENT_AFF  AS ANTICIP_CURRENT_AFF,                                           
        --[REPORT_CONSOLIDATED_TRANS_SUB].RATE_CURRENT_AFF  AS RATE_CURRENT_AFF,                          
        [REPORT_CONSOLIDATED_TRANS_SUB].CPF_EC  AS CPF_AFF,                                      
        [REPORT_CONSOLIDATED_TRANS_SUB].DESTINY  AS DESTINY,                           
        [REPORT_CONSOLIDATED_TRANS_SUB].COD_AFFILIATOR  AS COD_AFFILIATOR,                                                
        [REPORT_CONSOLIDATED_TRANS_SUB].COD_BRANCH  AS COD_BRANCH,                                                
        [REPORT_CONSOLIDATED_TRANS_SUB].COD_DEPTO_BRANCH  AS COD_DEPTO_BRANCH,                               
        [REPORT_CONSOLIDATED_TRANS_SUB].PAN  AS PAN,                                            
        [REPORT_CONSOLIDATED_TRANS_SUB].CPF_AFF AS ORIGINATOR,                                        
        [REPORT_CONSOLIDATED_TRANS_SUB].CODE  AS CODE,                                           
        [REPORT_CONSOLIDATED_TRANS_SUB].SPLIT,                                      
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANS_EC_NAME,                                      
  [REPORT_CONSOLIDATED_TRANS_SUB].TRANS_EC_CPF_CNPJ                                      
        ,[REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED]                                      
        ,[REPORT_CONSOLIDATED_TRANS_SUB].[RETAINED_AMOUNT]                                         
        --, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE]                          
        ,IIF( [REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED] = 1, [REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE] ) [ORIGINAL_DATE]                      
        ,[REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNEE]                                      
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_NAME_DESTINY                                    
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TITTLE_DATE                                    
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TITTLE_TIME                                 
        ,[REPORT_CONSOLIDATED_TRANS_SUB].AUTH_CODE                                
        ,[REPORT_CONSOLIDATED_TRANS_SUB].CREDITOR_DOCUMENT                                
       ,[REPORT_CONSOLIDATED_TRANS_SUB].ORDER_CODE                              
        ,CASE WHEN [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION_TITLE = @AwaitingSplit THEN 1 ELSE 0 END [AWAITINGSPLIT]                          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].MODEL_POS                          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].SEGMENT_EC                          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].STATE_EC                          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].CITY_EC                          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].NEIGHBORHOOD_EC                          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].COD_ADDRESS                        
,[REPORT_CONSOLIDATED_TRANS_SUB].COD_ADDRESS                        
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TYPE_TRAN                        
        ,[REPORT_CONSOLIDATED_TRANS_SUB].NAME_PROD                    
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_PROD                    
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_PROD_CPF_CNPJ                    
        ,ISNULL([REPORT_CONSOLIDATED_TRANS_SUB].PERCENT_PARTICIP_SPLIT,0) PERCENT_PARTICIP_SPLIT                   
        ,[REPORT_CONSOLIDATED_TRANS_SUB].IS_PLANDZERO                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TAX_PLANDZERO                    
  ,IIF([REPORT_CONSOLIDATED_TRANS_SUB].[TRANSACTION_TYPE] = ''CREDITO'', [REPORT_CONSOLIDATED_TRANS_SUB].QTY_DAYS_ANTECIP , 0)  QTY_DAYS_ANTECIP                
  ,isnull([REPORT_CONSOLIDATED_TRANS_SUB].TAX_PLANDZERO_AFF, 0) TAX_PLANDZERO_AFF                
  ,[REPORT_CONSOLIDATED_TRANS_SUB].SALES_REPRESENTANTE              
  ,[REPORT_CONSOLIDATED_TRANS_SUB].CPF_CNPJ_REPRESENTANTE              
  ,[REPORT_CONSOLIDATED_TRANS_SUB].EMAIL_REPRESENTANTE        
  ,[REPORT_CONSOLIDATED_TRANS_SUB].IS_RECURRING           
  ,[REPORT_CONSOLIDATED_TRANS_SUB].PROGRAM_MANAGER    
  ,[REPORT_CONSOLIDATED_TRANS_SUB].ASSIGN_PREVISION    
  ,[REPORT_CONSOLIDATED_TRANS_SUB].ASSIGN_ANTICIPATION    
  ,[REPORT_CONSOLIDATED_TRANS_SUB].ASSIGN_RATE    
  ,[REPORT_CONSOLIDATED_TRANS_SUB].ASSIGN_NET_VALUE    
  ,[REPORT_CONSOLIDATED_TRANS_SUB].QTY_BUSINESS_DAY  
  ,[REPORT_CONSOLIDATED_TRANS_SUB].SITUATION_TRAN  
  ,REPORT_CONSOLIDATED_TRANS_SUB.TERMINAL_VERSION
  ,[REPORT_CONSOLIDATED_TRANS_SUB].QTY_BUSINESS_DAY
  ,[REPORT_CONSOLIDATED_TRANS_SUB].SITUATION_TRAN
  FROM [REPORT_CONSOLIDATED_TRANS_SUB]                                                 
   WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_COMP = @CODCOMP                          
   AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION IN (3,14)                                          
';
    
    
    
    IF @INITIAL_DATE IS NOT NULL    
        AND @FINAL_DATE IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
' AND [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE BETWEEN @INITIAL_DATE AND @FINAL_DATE  ');

IF @EC IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COD_EC = @EC ');
IF @BRANCH IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND COD_BRANCH =  @BRANCH ');
IF @DEPART IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COD_DEPTO_BRANCH =  @DEPART ');
IF (@CODAFF IS NOT NULL)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COD_AFFILIATOR = @CodAff ');
IF LEN(@BRAND) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND BRAND = @BRAND ');
IF LEN(@NSU) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND CODE = @NSU ');
IF @PAN IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND PAN = @PAN ');
IF (@SPLIT = 1)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND SPLIT = 1');

IF (@ISPlanDZero = 1)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND IS_PLANDZERO = 1');

IF @COD_EC_PROD IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_EC_PROD = @COD_EC_PROD');

IF @CODACQUIRER IS NOT NULL
SET @QUERY_BASIS =
CONCAT(@QUERY_BASIS, ' AND ACQUIRER = (SELECT [NAME] FROM ACQUIRER WHERE COD_AC = @CODACQUIRER ) ');
IF @TERMINAL_VERSION IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_CONSOLIDATED_TRANS_SUB].TERMINAL_VERSION = @TERMINAL_VERSION ');

EXEC [sp_executesql] @QUERY_BASIS
					,N'                                         
           @CODCOMP VARCHAR(10),                                 
           @INITIAL_DATE DATE,                                 
           @FINAL_DATE DATE,                                
           @EC int,                                 
           @BRANCH int,                                 
           @DEPART int,                               
           @TERMINAL varchar(100),                                 
           @STATE varchar(25),                                 
           @CITY varchar(40),                                 
           @TYPE_TRAN int,                                 
           @SITUATION int,                                 
           @NSU varchar(100),                     
           @NSU_EXT varchar(100),                                              
		   @BRAND varchar(50) ,                               
           @PAN VARCHAR(50),                                 
           @CodAff INT,     
           @CODACQUIRER INT,                          
           @AwaitingSplit INT = NULL,        
		   @COD_EC_PROD INT,       
		   @TERMINAL_VERSION VARCHAR(200)
           '
					,@CODCOMP = @CODCOMP
					,@INITIAL_DATE = @INITIAL_DATE
					,@FINAL_DATE = @FINAL_DATE
					,@EC = @EC
					,@BRANCH = @BRANCH
					,@DEPART = @DEPART
					,@TERMINAL = @TERMINAL
					,@STATE = @STATE
					,@CITY = @CITY
					,@TYPE_TRAN = @TYPE_TRAN
					,@SITUATION = @SITUATION
					,@NSU = @NSU
					,@NSU_EXT = @NSU_EXT
					,@BRAND = @BRAND
					,@PAN = @PAN
					,@CODAFF = @CODAFF
					,@CODACQUIRER = @CODACQUIRER
					,@AWAITINGSPLIT = @AWAITINGSPLIT
					,@COD_EC_PROD = @COD_EC_PROD
					,@TERMINAL_VERSION = @TERMINAL_VERSION;

END;

--ST-1668

GO

IF OBJECT_ID('SP_DATA_TRANSACTION') IS NOT NULL
DROP PROCEDURE SP_DATA_TRANSACTION
GO
CREATE PROCEDURE [DBO].[SP_DATA_TRANSACTION]                  
  
   
  
/*********************************************************************************************************  
----------------------------------------------------------------------------------------                  
Procedure Name: [SP_DATA_TRANSACTION]                  
Project.......: TKPP                  
------------------------------------------------------------------------------------------                  
Author                          VERSION        Date                            Description                  
------------------------------------------------------------------------------------------                  
Kennedy Alef     V1    27/07/2018      Creation                  
Lucas Aguiar  v2    21/11/2018      Changed                
Amós Corcino dos Santos   V3    17/01/2019      Change              
------------------------------------------------------------------------------------------  
*********************************************************************************************************/  
                         
(  
    @TRANSACTIONCODE VARCHAR(300))  
AS  
BEGIN
SELECT
	[TRANSACTION].[BRAND]
   ,[TRANSACTION].[AMOUNT]
   ,CAST([dbo].[FN_FUS_UTF](ISNULL([TRANSACTION].[CREATED_AT], [TRANSACTION].[CREATED_AT])) AS DATETIME) AS [TRANSACTION_DATE]
   ,
	--CAST(((ISNULL([TRANSACTION].MODIFY_DATE, [TRANSACTION].CREATED_AT)  at time zone 'West Bank Standard Time') AT TIME ZONE 'UTC') AS DATETIME)  AS TRANSACTION_DATE,                   
	[TRANSACTION].[CODE] AS [TRANSACTION_CODE]
   ,[SITUATION_TR] AS [SITUATION]
   ,[TRANSACTION_TYPE].[CODE] AS [TRAN_TYPE]
   ,[ACQUIRER].[CODE] AS [ACQ_CODE]
   ,[ACQUIRER].[NAME] AS [ACQ_NAME]
   ,[TRANSACTION].[CREATED_AT]
   ,[EQUIPMENT].[SERIAL]
   ,[TRANSACTION].[PAN]
   ,[TRANSACTION].[COMMENT] AS [COMMENT]
   ,[TRANSACTION].[TRACKING_TRANSACTION] AS [COD_RAST]
   ,[TRANSACTION].[DESCRIPTION]
   ,[TRANSACTION].[POSWEB]
   ,[TRANSACTION].[TYPE] AS [TXT_TRAN_TYPE]
   ,[TRANSACTION].[PLOTS]
   ,[TRANSACTION].[CARD_HOLDER_NAME]
   ,[TRANSACTION].[CARD_HOLDER_DOC]
   ,[TRANSACTION].[LOGICAL_NUMBER_ACQ]
   ,(CASE
		WHEN (SELECT
					COUNT(*)
				FROM [TRANSACTION_SERVICES]
				WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
				AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
			> 0 THEN 1
		ELSE 0
	END) AS [LINK_MODE]
   ,[TRANSACTION].TERMINAL_VERSION
   ,REPORT_TRANSACTIONS_EXP.TRAN_DATA_EXT_VALUE AS EXTERNALNSU
FROM [EQUIPMENT]
LEFT JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].[COD_EQUIP] = [EQUIPMENT].[COD_EQUIP]
LEFT JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].[COD_ASS_DEPTO_TERMINAL] = [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL]
LEFT JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].[COD_TTYPE] = [TRANSACTION].[COD_TTYPE]
LEFT JOIN [PRODUCTS_ACQUIRER]
	ON [PRODUCTS_ACQUIRER].[COD_PR_ACQ] = [TRANSACTION].[COD_PR_ACQ]
LEFT JOIN [ACQUIRER]
	ON [ACQUIRER].[COD_AC] = [PRODUCTS_ACQUIRER].[COD_AC]
LEFT JOIN [CURRENCY]
	ON [TRANSACTION].[COD_CURRRENCY] = [CURRENCY].[COD_CURRRENCY]
LEFT JOIN [SITUATION]
	ON [SITUATION].[COD_SITUATION] = [TRANSACTION].[COD_SITUATION]
LEFT JOIN [TRADUCTION_SITUATION]
	ON [TRADUCTION_SITUATION].[COD_SITUATION] = [SITUATION].[COD_SITUATION]
LEFT JOIN [POSWEB_DATA_TRANSACTION]
	ON [POSWEB_DATA_TRANSACTION].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
LEFT JOIN REPORT_TRANSACTIONS_EXP
	ON [TRANSACTION].COD_TRAN = REPORT_TRANSACTIONS_EXP.COD_TRAN
WHERE [TRANSACTION].[CODE] = @TRANSACTIONCODE;
END;
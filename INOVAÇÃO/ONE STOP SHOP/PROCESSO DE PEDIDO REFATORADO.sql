ALTER PROCEDURE SP_FD_ORDERS_TO_CONTINUE
(	
	@TP_ORDER_ITEM TP_ORDER_ITEM READONLY,
	@AMOUNT DECIMAL(22,8),
	@CPF_CNPJ VARCHAR(200),
	@COD_AFFILIATOR INT
)
AS
BEGIN

SELECT
	[ORDER].COD_ODR
FROM [ORDER]
INNER JOIN ORDER_ITEM
	ON [ORDER].COD_ODR = ORDER_ITEM.COD_ODR
INNER JOIN @TP_ORDER_ITEM TP_ORDER_ITEM
	ON TP_ORDER_ITEM.COD_PR_AFF = ORDER_ITEM.COD_PRODUCT
		AND TP_ORDER_ITEM.QUANTITY = ORDER_ITEM.QUANTITY
		AND TP_ORDER_ITEM.PRICE = ORDER_ITEM.PRICE
		AND TP_ORDER_ITEM.CELL_OPERATOR = ORDER_ITEM.COD_OPERATOR
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = [ORDER].COD_EC
INNER JOIN ORDER_SITUATION
	ON ORDER_SITUATION.COD_ORDER_SIT = [ORDER].COD_ORDER_SIT
WHERE COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = @CPF_CNPJ
AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFFILIATOR
AND [ORDER].AMOUNT = @AMOUNT
AND ORDER_SITUATION.CODE = 'PAGAMENTO PENDENTE'
END;

GO

ALTER PROCEDURE [DBO].[SP_REG_COMMERCIAL_ORDER]                                                      
              
/***********************************************************************************************************************************************          
----------------------------------------------------------------------------------------                                                     
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                                                     
    Project.......: TKPP                                                     
    ------------------------------------------------------------------------------------------                                                     
    Author                          VERSION        Date                            Description                                                            
    ------------------------------------------------------------------------------------------                                                     
    Lucas Aguiar     V1      2019-10-28         Creation                                                           
    ------------------------------------------------------------------------------------------          
***********************************************************************************************************************************************/          
                                                     
(                                                 
 -- informations about commercial establishments                                         
 @ACCESS_KEY          VARCHAR(300),           
 @AFFILIATOR          VARCHAR(20),           
 @COD_COMP            INT,           
 @COD_BRANCH_BUSINESS INT,           
 @COD_SEGMENT         INT,           
 @NAME                VARCHAR(255),           
 @TRADING_NAME        VARCHAR(255),           
 @BIRTHDATE           DATETIME,           
 @COD_SEX             INT,           
 @RG                  VARCHAR(100)       = NULL,           
 @CPF_CNPJ            VARCHAR(14),           
 @COD_TYPE_EC         INT,           
 @STATE_REG           VARCHAR(100)       = NULL,           
 @MUN_REG             VARCHAR(100)       = NULL,           
 @EC_EMAIL            VARCHAR(200),                                                
 -- plan of commercial establishment                                    
 @COD_PLAN            INT,                                                                
 --address of commmercial establishment                                    
 @ADDRESS             VARCHAR(300),           
 @NUMBER              VARCHAR(100),           
 @COMPLEMENT          VARCHAR(200)       = NULL,           
 @REFPOINT            VARCHAR(100)       = NULL,           
 @CEP                 VARCHAR(12),           
 @COD_NEIGH           INT,                                          
 --partners of ec                                                   
 @TP_PARTNERS         [TP_PARTNERS] READONLY,                                              
 --bank data about ec                                           
 @BANKCODE            VARCHAR(10),           
 @COD_OPER_BANK       INT                = NULL,           
 @DIGIT_AGENCY        VARCHAR(100)       = NULL,           
 @AGENCY              VARCHAR(100),           
 @DIGIT_ACCOUNT       VARCHAR(100),           
 @ACCOUNT             VARCHAR(100),           
 @ACCOUNT_TYPE        INT,                                                    
                                    
 --first user of ec                                                   
 @USERNAME            VARCHAR(255),           
 @EMAIL               VARCHAR(255),           
 @TEMP_PASS           VARCHAR(200),                                                    
                                    
 --contacts of ec                                                   
 @TP_CONTACT          [TP_CONTACT_LIST] READONLY,                                                    
           
 --sales order address                                             
 --@ADDRESS_ORDER       VARCHAR(300),       
 --@NUMBER_ORDER        VARCHAR(100),           
 --@COMPLEMENT_ORDER    VARCHAR(200)       = NULL,           
 --@REFPOINT_ORDER    VARCHAR(100)       = NULL,           
 --@CEP_ORDER           VARCHAR(12),           
 --@COD_NEIGH_ORDER     INT,                             
                                                 
 --value of sales order                                    
 --@AMOUNT              DECIMAL(22, 6),           
 --@CODE                VARCHAR(128)       = NULL,                                                    
 ---- items of order                     
 --@TP_ORDER_ITEM       [TP_ORDER_ITEM] READONLY,           
 @TP_DOCUMENT         [TP_DOCUMENT_LIST] READONLY,           
 @TP_MEET_COSTUMER    [TP_MEET_COSTUMER] READONLY)          
AS          
BEGIN
  
    
      
        
          
          
    DECLARE           
   @DOCUMENT_TYPE VARCHAR(20);
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @COD_SALES_REP INT = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @SEQ INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @TRANSACTION_LIMIT DECIMAL(22, 8)  = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @TRANSACTION_DAILY DECIMAL(22, 8)  = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @TRANSACTION_MOUNTH DECIMAL(22, 8)  = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @COD_RISK_SIT INT = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @COD_USER INT = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_EC INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_BR INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_DEPART INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_USER INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_ORDER_ADDR INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_TRAN INT = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @TP_PLAN INT = NULL;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @ID_ORDER INT;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @COUNT_USER INT = 0;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @CONT INT = 0;
  
    
      
        
          
          
          
          
          
          
    DECLARE           
   @COD_AFFILIATOR INT;
  
	DECLARE @HAVE_USER INT;
BEGIN

IF ( SELECT
		COUNT(*)
	FROM COMMERCIAL_ESTABLISHMENT
	WHERE CPF_CNPJ = @CPF_CNPJ
	AND COD_AFFILIATOR = @COD_AFFILIATOR)
> 0
BEGIN

IF (SELECT
			COUNT(*)
		FROM USERS
		WHERE COD_ACCESS = @USERNAME)
	> 0
BEGIN

SELECT
	COMMERCIAL_ESTABLISHMENT.COD_EC
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,AFFILIATOR.COD_AFFILIATOR
   ,AFFILIATOR.CPF_CNPJ AS CNPJ_AFF
   ,EC_TRANSIRE.USER_ONLINE
   ,EC_TRANSIRE.PWD_ONLINE
   ,EC_TRANSIRE.COD_EC
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL AS 'SITE'
   ,@USERNAME AS 'USERNAME'
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_ASS_DEPTO_TERMINAL
FROM COMMERCIAL_ESTABLISHMENT
INNER JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
INNER JOIN COMMERCIAL_ESTABLISHMENT EC_TRANSIRE
	ON EC_TRANSIRE.GENERIC_EC = 1
		AND EC_TRANSIRE.COD_AFFILIATOR = @COD_AFFILIATOR
INNER JOIN VW_COMPANY_EC_AFF_BR_DEP_EQUIP
	ON VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EC = EC_TRANSIRE.COD_EC
WHERE COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = @CPF_CNPJ
AND AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATOR

END
ELSE
BEGIN

INSERT INTO [USERS] ([COD_ACCESS],
[CPF_CNPJ],
[IDENTIFICATION],
[EMAIL],
[FIRST_LOGIN],
[COD_COMP],
[COD_MODULE],
[COD_EC],
[ALTERNATIVE_EMAIL],
[COD_PROFILE],
[COD_SEX],
[COD_AFFILIATOR],
[ACCEPT])
	VALUES (@USERNAME, @CPF_CNPJ, @USERNAME, @EMAIL, 1, @COD_COMP, 2, @ID_EC, @EMAIL, 11, @COD_SEX, @COD_AFFILIATOR, 1);

IF @@rowcount < 1
THROW 70016, 'COULD NOT REGISTER USERS. Parameter name: 70016', 1;

SET @ID_USER = SCOPE_IDENTITY();

INSERT INTO CONTACT_USERS (CREATED_AT,
NUMBER,
COD_TP_CONT,
COD_USER,
COD_OPER,
DDI,
DDD,
ACTIVE)
	SELECT
		current_timestamp
	   ,TP.NUMBER
	   ,TP.CONTACT_TYPE
	   ,@ID_USER
	   ,TP.COD_OPER
	   ,TP.DDI
	   ,TP.DDD
	   ,1
	FROM @TP_CONTACT AS TP

EXEC [SP_REG_PROV_PASS_USER] @USERNAME
							,@ACCESS_KEY
							,@TEMP_PASS
							,1
							,@COD_AFFILIATOR;

END
END
ELSE
BEGIN
SELECT TOP 1
	@COD_SALES_REP = [COD_SALES_REP]
FROM [SALES_REPRESENTATIVE]
WHERE [DEFAULT_SR] = 1
AND [ACTIVE] = 1;

IF @COD_SALES_REP IS NULL
THROW 70004, 'INVALID SALES REPRESENTATIVE. Parameter name: 70004', 1;


IF @COD_TYPE_EC = 3
SET @COD_SEGMENT = 507; -- SEGUIMENTO PADRÃO PARA PESSOA FÍSICA                                                    

IF (SELECT
			COUNT(*)
		FROM @TP_DOCUMENT)
	> 0
SET @COD_RISK_SIT = 1; -- Pending risk Analysis                                                    
ELSE
SET @COD_RISK_SIT = 8; -- Documentation Pending                                                    


SELECT
	@TRANSACTION_LIMIT = [TRANSACTION_LIMIT]
   ,@TRANSACTION_DAILY = [LIMIT_TRANSACTION_DIALY]
   ,@TRANSACTION_MOUNTH = (SELECT
			[LIMIT_TRANSACTION_MONTHLY]
		FROM [SEGMENTS]
		WHERE [COD_SEG] = @COD_SEGMENT)
FROM [TRANSACTION_LIMIT]
JOIN [COMPANY]
	ON [COMPANY].[COD_COMP] = [TRANSACTION_LIMIT].[COD_COMP]
WHERE [ACTIVE] = 1
AND [COD_TYPE_ESTAB] = @COD_TYPE_EC
AND [COMPANY].[COD_COMP] = @COD_COMP;


SELECT
	@COD_USER = [COD_USER]
FROM [USERS]
WHERE [COD_ACCESS] = 'ECOMMERCE_USER';

IF @COD_USER IS NULL
THROW 70006, 'INVALID ECOMMERCE USER. Parameter name: 70006', 1;


SELECT
	@SEQ = NEXT VALUE FOR [SEQ_ECCODE];


INSERT INTO [COMMERCIAL_ESTABLISHMENT] ([CODE],
[NAME],
[TRADING_NAME],
[CPF_CNPJ],
[DOCUMENT],
[DOCUMENT_TYPE],
[EMAIL],
[STATE_REGISTRATION],
[MUNICIPAL_REGISTRATION],
[COD_SEG],
[TRANSACTION_LIMIT],
[LIMIT_TRANSACTION_DIALY],
[LIMIT_TRANSACTION_MONTHLY],
[BIRTHDATE],
[COD_COMP],
[COD_TYPE_ESTAB],
[SEC_FACTOR_AUTH_ACTIVE],
[COD_SEX],
[COD_AFFILIATOR],
[COD_RISK_SITUATION],
[COD_SALES_REP],
[COD_SIT_REQ],
[COD_SITUATION],
[COD_USER],
[TRANSACTION_ONLINE],
[COD_BRANCH_BUSINESS])
	SELECT
		@SEQ
	   ,@NAME
	   ,@TRADING_NAME
	   ,@CPF_CNPJ
	   ,@RG
	   ,@DOCUMENT_TYPE
	   ,@EC_EMAIL
	   ,@STATE_REG
	   ,@MUN_REG
	   ,@COD_SEGMENT
	   ,@TRANSACTION_LIMIT
	   ,@TRANSACTION_DAILY
	   ,@TRANSACTION_MOUNTH
	   ,@BIRTHDATE
	   ,[COD_COMP]
	   ,@COD_TYPE_EC
	   ,0
	   ,@COD_SEX
	   ,@COD_AFFILIATOR
	   ,@COD_RISK_SIT
	   ,@COD_SALES_REP
	   ,11
	   ,25
	   ,@COD_USER
	   ,0
	   ,@COD_BRANCH_BUSINESS
	FROM [COMPANY]
	WHERE [COMPANY].[COD_COMP] = @COD_COMP;
IF @@rowcount < 1
THROW 70007, 'COULD NOT REGISTER COMMERCIAL_ESTABLISHMENT. Parameter name: 70007', 1;

SET @ID_EC = SCOPE_IDENTITY();

INSERT INTO [BRANCH_EC] ([CODE],
[NAME],
[TRADING_NAME],
[CPF_CNPJ],
[DOCUMENT],
[DOCUMENT_TYPE],
[EMAIL],
[STATE_REGISTRATION],
[MUNICIPAL_REGISTRATION],
[TRANSACTION_LIMIT],
[LIMIT_TRANSACTION_DIALY],
[BIRTHDATE],
[COD_EC],
[TYPE_BRANCH],
[COD_SEX],
[COD_TYPE_ESTAB],
[COD_TYPE_REC],
[COD_USER])
	VALUES (@SEQ, @NAME, @TRADING_NAME, @CPF_CNPJ, @CPF_CNPJ, @DOCUMENT_TYPE, @EC_EMAIL, @STATE_REG, @MUN_REG, @TRANSACTION_LIMIT, @TRANSACTION_DAILY, @BIRTHDATE, @ID_EC, 'PRINCIPAL', @COD_SEX, @COD_TYPE_EC, 1, @COD_USER);

IF @@rowcount < 1
THROW 70008, 'COULD NOT REGISTER BRANCH_EC. Parameter name: 70008', 1;


SELECT
	@ID_BR = SCOPE_IDENTITY();


INSERT INTO [BANK_DETAILS_EC] ([AGENCY],
[DIGIT_AGENCY],
[COD_TYPE_ACCOUNT],
[COD_EC],
[COD_BANK],
[ACCOUNT],
[DIGIT_ACCOUNT],
[COD_USER],
[COD_BRANCH],
[COD_OPER_BANK])
	SELECT
		@AGENCY
	   ,@DIGIT_AGENCY
	   ,@ACCOUNT_TYPE
	   ,@ID_EC
	   ,[COD_BANK]
	   ,@ACCOUNT
	   ,@DIGIT_ACCOUNT
	   ,@COD_USER
	   ,@ID_BR
	   ,@COD_OPER_BANK
	FROM [BANKS]
	WHERE [BANKS].[CODE] = @BANKCODE;

IF @@rowcount < 1
THROW 70009, 'COULD NOT REGISTER BANK_DETAILS_EC. Parameter name: 70009', 1;


UPDATE [ADDRESS_BRANCH]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = GETDATE()
WHERE [ACTIVE] = 1
AND [COD_BRANCH] = @ID_BR;


INSERT INTO [ADDRESS_BRANCH] ([ADDRESS],
[NUMBER],
[COMPLEMENT],
[CEP],
[COD_NEIGH],
[REFERENCE_POINT],
[COD_BRANCH])
	VALUES (@ADDRESS, @NUMBER, @COMPLEMENT, @CEP, @COD_NEIGH, @REFPOINT, @ID_BR);

IF @@rowcount < 1
THROW 70010, 'COULD NOT REGISTER ADDRESS_BRANCH. Parameter name: 70010', 1;

INSERT INTO [DEPARTMENTS_BRANCH] ([COD_BRANCH],
[COD_DEPARTS])
	VALUES (@ID_BR, 1);


IF @@rowcount < 1
THROW 70011, 'COULD NOT REGISTER DEPARTMENTS_BRANCH. Parameter name: 70011', 1;

SET @ID_DEPART = SCOPE_IDENTITY();

INSERT INTO [CONTACT_BRANCH] ([NUMBER],
[COD_TP_CONT],
[COD_BRANCH],
[COD_OPER],
[DDD],
[DDI])
	SELECT
		[NUMBER]
	   ,[CONTACT_TYPE]
	   ,@ID_BR
	   ,[COD_OPER]
	   ,[DDD]
	   ,[DDI]
	FROM @TP_CONTACT;

IF @@rowcount < 1
THROW 70012, 'COULD NOT REGISTER CONTACT_BRANCH. Parameter name: 70012', 1;


SELECT
	@TP_PLAN = [COD_T_PLAN]
FROM [PLAN]
WHERE [COD_PLAN] = @COD_PLAN
AND [ACTIVE] = 1;


IF @TP_PLAN IS NULL
THROW 70013, 'INVALID PLAN. Parameter name: 70013', 1;


UPDATE [ASS_TAX_DEPART]
SET [ACTIVE] = 0
WHERE [COD_DEPTO_BRANCH] = @ID_DEPART;

UPDATE [DEPARTMENTS_BRANCH]
SET [COD_PLAN] = @COD_PLAN
   ,[COD_T_PLAN] = @TP_PLAN
WHERE [COD_DEPTO_BRANCH] = @ID_DEPART;

INSERT INTO [ASS_TAX_DEPART] ([COD_TTYPE],
[QTY_INI_PLOTS],
[QTY_FINAL_PLOTS],
[PARCENTAGE],
[RATE],
[INTERVAL],
[COD_DEPTO_BRANCH],
[COD_USER],
[COD_PLAN],
[EFFECTIVE_PERCENTAGE],
[ANTICIPATION_PERCENTAGE],
[COD_BRAND],
[COD_SOURCE_TRAN])
	SELECT
		[COD_TTYPE]
	   ,[QTY_INI_PLOTS]
	   ,[QTY_FINAL_PLOTS]
	   ,[PARCENTAGE]
	   ,[RATE]
	   ,[INTERVAL]
	   ,@ID_DEPART
	   ,@COD_USER
	   ,@COD_PLAN
	   ,[EFFECTIVE_PERCENTAGE]
	   ,[ANTICIPATION_PERCENTAGE]
	   ,[COD_BRAND]
	   ,[COD_SOURCE_TRAN]
	FROM [TAX_PLAN]
	WHERE [COD_PLAN] = @COD_PLAN
	AND [TAX_PLAN].[ACTIVE] = 1;

IF @@rowcount < 1
THROW 70014, 'COULD NOT REGISTER ASS_TAX_DEPART. Parameter name: 70014', 1;


UPDATE [DOCS_BRANCH]
SET [ACTIVE] = 0
FROM [DOCS_BRANCH]
JOIN @TP_DOCUMENT [TP_DOC]
	ON [TP_DOC].[COD_DOC_TYPE] = [DOCS_BRANCH].[COD_DOC_TYPE]
WHERE [DOCS_BRANCH].[COD_BRANCH] = @ID_BR
AND [DOCS_BRANCH].[ACTIVE] = 1;


INSERT INTO [DOCS_BRANCH] ([COD_USER],
[COD_BRANCH],
[COD_SIT_REQ],
[COD_DOC_TYPE],
[PATH_DOC])
	SELECT
		@COD_USER
	   ,@ID_BR
	   ,16
	   ,[TP_DOCS].[COD_DOC_TYPE]
	   ,[TP_DOCS].[PATH_DOC]
	FROM @TP_DOCUMENT AS [TP_DOCS];

INSERT INTO [ADITIONAL_DATA_TYPE_EC] ([CREATED_AT],
[NAME],
[CPF],
[DOCUMENT],
[BIRTH_DATA],
[COD_EC],
[COD_TYPE_PARTNER],
[PERCENTEGE_QUOTAS],
[ACTIVE])
	SELECT
		current_timestamp
	   ,[NAME]
	   ,[CPF]
	   ,[DOCUMENT]
	   ,[BIRTHDAY]
	   ,@ID_EC
	   ,[COD_TYPE_PARTNER]
	   ,[PERCENTAGE_QUOTAS]
	   ,[ACTIVE]
	FROM @TP_PARTNERS;

SELECT
	@COUNT_USER = COUNT(*)
FROM [USERS]
WHERE [COD_ACCESS] = @USERNAME;

IF @COUNT_USER > 0
THROW 70015, 'USER ALREADY REGISTERED. Parameter name: 70015', 1;

INSERT INTO [USERS] ([COD_ACCESS],
[CPF_CNPJ],
[IDENTIFICATION],
[EMAIL],
[FIRST_LOGIN],
[COD_COMP],
[COD_MODULE],
[COD_EC],
[ALTERNATIVE_EMAIL],
[COD_PROFILE],
[COD_SEX],
[COD_AFFILIATOR],
[ACCEPT])
	VALUES (@USERNAME, @CPF_CNPJ, @USERNAME, @EMAIL, 1, @COD_COMP, 2, @ID_EC, @EMAIL, 11, @COD_SEX, @COD_AFFILIATOR, 1);

IF @@rowcount < 1
THROW 70016, 'COULD NOT REGISTER USERS. Parameter name: 70016', 1;

SET @ID_USER = SCOPE_IDENTITY();

INSERT INTO CONTACT_USERS (CREATED_AT,
NUMBER,
COD_TP_CONT,
COD_USER,
COD_OPER,
DDI,
DDD,
ACTIVE)
	SELECT
		current_timestamp
	   ,TP.NUMBER
	   ,TP.CONTACT_TYPE
	   ,@ID_USER
	   ,TP.COD_OPER
	   ,TP.DDI
	   ,TP.DDD
	   ,1
	FROM @TP_CONTACT AS TP

EXEC [SP_REG_PROV_PASS_USER] @USERNAME
							,@ACCESS_KEY
							,@TEMP_PASS
							,1
							,@COD_AFFILIATOR;

END;

SELECT
	COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,AFFILIATOR.CPF_CNPJ
   ,EC_TRANSIRE.USER_ONLINE
   ,EC_TRANSIRE.PWD_ONLINE
   ,EC_TRANSIRE.COD_EC
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL
   ,@USERNAME
FROM COMMERCIAL_ESTABLISHMENT
INNER JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
INNER JOIN COMMERCIAL_ESTABLISHMENT EC_TRANSIRE
	ON EC_TRANSIRE.GENERIC_EC = 1
		AND EC_TRANSIRE.COD_AFFILIATOR = @COD_AFFILIATOR
INNER JOIN VW_COMPANY_EC_AFF_BR_DEP_EQUIP
	ON VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EC = EC_TRANSIRE.COD_EC
WHERE COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = @CPF_CNPJ
AND AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATOR

END;
END;

GO

ALTER VIEW [dbo].[VW_COMPANY_EC_AFF_BR_DEP_EQUIP]      
AS
SELECT
	ISNULL(AFFILIATOR.[NAME], COMPANY.NAME) AS COMPANY
   ,COMPANY.COD_COMP AS COD_COMP
   ,COMPANY.FIREBASE_NAME AS FIREBASE_NAME
   ,COMMERCIAL_ESTABLISHMENT.NAME AS EC
   ,COMMERCIAL_ESTABLISHMENT.COD_EC
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS CPF_CNPJ_EC
   ,COMMERCIAL_ESTABLISHMENT.ACTIVE AS SITUATION_EC
   ,AFFILIATOR.COD_AFFILIATOR
   ,AFFILIATOR.NAME AS AFFILIATOR
   ,BRANCH_EC.NAME AS BRANCH_NAME
   ,BRANCH_EC.TRADING_NAME AS TRADING_NAME_BR
   ,BRANCH_EC.COD_BRANCH
   ,BRANCH_EC.CPF_CNPJ AS CPF_CNPJ_BR
   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH AS COD_DEPTO_BR
   ,DEPARTMENTS.NAME AS DEPARTMENT
   ,SEGMENTS.NAME AS SEGMENTS
   ,EQUIPMENT.COD_EQUIP AS COD_EQUIP
   ,EQUIPMENT.SERIAL AS SERIAL
   ,ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
FROM BRANCH_EC
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
INNER JOIN DEPARTMENTS
	ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
INNER JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
INNER JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
LEFT JOIN CELL_OPERATOR
	ON CELL_OPERATOR.COD_OPER = EQUIPMENT.COD_OPER
WHERE ASS_DEPTO_EQUIP.ACTIVE = 1  
﻿ALTER TABLE AFFILIATOR ADD OPERATION_AFF INT;
GO
UPDATE AFFILIATOR
SET OPERATION_AFF = 0
WHERE OPERATION_AFF IS NULL
GO
ALTER TABLE COMMERCIAL_ESTABLISHMENT ADD GENERIC_EC INT;
GO
ALTER PROCEDURE [dbo].[SP_LOGIN_USER]                  
/*----------------------------------------------------------------------------------------                  
    Procedure Name: SP_LOGIN_USER                  
    Project.......: TKPP                  
    ------------------------------------------------------------------------------------------                  
    Author                          VERSION        Date                            Description                  
    ------------------------------------------------------------------------------------------                  
    Kennedy Alef     V1      31/07/2018        Creation                  
    Gian Luca Dalle Cort   V2      31/07/2018        Changed                  
    Lucas Aguiar   v3  26/11/2018  changed          
       
*/
          
(                 
@ACESSKEY VARCHAR(300),                  
@USER VARCHAR(100) ,                 
@COD_AFFILIATOR INT                   
)                  
AS                  
DECLARE @LOCK DATETIME;
                  
DECLARE @ACTIVE_USER INT;
                  
DECLARE @CODUSER INT;
                  
DECLARE @ACTIVE_EC INT;
                  
DECLARE @DATEPASS DATETIME
                  
DECLARE @LOGGED INT;
                  
DECLARE @PASS_TMP VARCHAR(MAX);
                  
DECLARE @RETURN VARCHAR(200);
                  
DECLARE @ACTIVE_AFL INT;
                  
DECLARE @COD_AFF INT;
                   
DECLARE @COD_MODULE_ INT;
               
DECLARE @COD_SALES_REP INT;
          
BEGIN

SELECT
	@LOCK = LOCKED_UP
   ,@ACTIVE_USER = USERS.ACTIVE
   ,@CODUSER = USERS.COD_USER
   ,@ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE
   ,@DATEPASS = PASS_HISTORY.CREATED_AT
   ,@LOGGED = USERS.LOGGED
   ,@PASS_TMP = PASS_HISTORY.PASS
   ,@ACTIVE_AFL = AFFILIATOR.ACTIVE
   ,@COD_AFF = AFFILIATOR.COD_AFFILIATOR
   ,@COD_SALES_REP = SALES_REPRESENTATIVE.COD_SALES_REP
FROM USERS
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = USERS.COD_COMP
INNER JOIN PROFILE_ACCESS
	ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE
INNER JOIN PASS_HISTORY
	ON PASS_HISTORY.COD_USER = USERS.COD_USER
LEFT JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = USERS.COD_EC
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR --BUSCA SE USU�RIO POSSUI C�DIGO DE AFILIADOR                  
LEFT JOIN SALES_REPRESENTATIVE
	ON SALES_REPRESENTATIVE.COD_USER = USERS.COD_USER
WHERE COD_ACCESS = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1
OR USERS.EMAIL = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1

IF @CODUSER IS NULL
	OR @CODUSER = 0
BEGIN

SET @RETURN = CONCAT('USER NOT FOUND', ';') + ISNULL(@PASS_TMP, 0);
                  
THROW 61006,@RETURN,1;
                  
END
                  
                
IF ISNULL(@COD_AFF,0) <> ISNULL(@COD_AFFILIATOR,0)              
BEGIN

SET @RETURN = CONCAT('USER NOT FOUND r', ';') + ISNULL(@PASS_TMP, 0);
                  
THROW 61006,@RETURN,1;
                  
END
                 
                
                  
IF DATEDIFF(MINUTE,@LOCK,GETDATE()) < 30                  
BEGIN

SET @RETURN = CONCAT(CONCAT('USER BLOCKED', ';'), @PASS_TMP);
                  
THROW 61008,@RETURN,1;
                  
END
                  
                  
IF @ACTIVE_USER = 0                  
BEGIN
SET @RETURN = CONCAT(CONCAT('USER INACTIVE', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('USER INACTIVE',CONCAT('-',@PASS_TMP))                  
THROW 61007,@RETURN,1;
                  
END
                  
                  
IF @ACTIVE_EC = 0                  
BEGIN
SET @RETURN = CONCAT(CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE',CONCAT('-',@PASS_TMP))                  
THROW 61009,@RETURN,1;
                  
END
                  
                  
IF @ACTIVE_AFL = 0                  
BEGIN
SET @RETURN = CONCAT(CONCAT('AFFILIATOR INACTIVE', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE',CONCAT('-',@PASS_TMP))                  
THROW 61009,@RETURN,1;
                  
END
                  
                  
IF DATEDIFF(DAY,@DATEPASS,GETDATE()) >= 30                  
BEGIN
SET @RETURN = CONCAT(CONCAT('PASSWORD EXPIRED', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('PASSWORD EXPIRED',CONCAT('-',@PASS_TMP))                  
THROW 61010,@RETURN,1;
                  
END
                  
IF @LOGGED = 1                  
BEGIN
UPDATE USERS
SET LOGGED = 0
WHERE USERS.COD_USER = @CODUSER;
DELETE FROM TEMP_TOKEN
WHERE TEMP_TOKEN.COD_USER = @CODUSER;
SET @RETURN = CONCAT(CONCAT('USER ALREADY LOGGED', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('USER ALREADY LOGGED',CONCAT('-',@PASS_TMP))                  
THROW 61011,@RETURN,1;
                  
END
                  
IF @PASS_TMP IS NULL                 
THROW 61029,'TEMPORARY ACCESS',1;



SELECT
	USERS.COD_ACCESS AS USERNAME
   ,USERS.COD_USER
   ,USERS.IDENTIFICATION
   ,PASS_HISTORY.PASS
   ,USERS.CPF_CNPJ AS CPF_CNPJ_USER
   ,USERS.EMAIL
   ,COMPANY.COD_COMP AS COD_COMP
   ,AFFILIATOR.COD_AFFILIATOR AS INSIDECODE_AFL
   ,PROFILE_ACCESS.CODE AS COD_PROFILE
   ,COMMERCIAL_ESTABLISHMENT.COD_EC
   ,MODULES.CODE AS MODULE
   ,MODULES.COD_MODULE AS COD_MODULE
   ,@COD_AFFILIATOR AS PAR_AFFILIATOR
   ,@COD_AFF AS AFF_RET
   ,CASE COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE
		WHEN 1 THEN AUTHENTICATION_FACTOR.NAME
		WHEN 0 THEN NULL
		ELSE AUTHENTICATION_FACTOR.NAME
	END
	AS AUTHENTICATION_FACTOR
   ,CASE
		WHEN FIRST_LOGIN_DATE IS NULL THEN 1
		ELSE 0
	END
	AS FIRST_ACCESS
   ,AUTHENTICATION_FACTOR.COD_FACT
   ,(-1 * (DATEDIFF(DAY, ((DATEADD(DAY, 30, GETDATE()) + GETDATE()) - GETDATE()), @DATEPASS))) AS DAYSTO_EXPIRE
   ,THEMES.COD_THEMES AS 'ThemeCode'
   ,THEMES.CREATED_AT AS 'CreatedDate'
   ,THEMES.LOGO_AFFILIATE AS 'PathLogo'
   ,THEMES.LOGO_HEADER_AFFILIATE AS 'PathLogoHeader'
   ,THEMES.COD_AFFILIATOR AS 'AffiliatorCode'
   ,THEMES.MODIFY_DATE AS 'ModifyDate'
   ,THEMES.COLOR_HEADER AS 'ColorHeader'
   ,THEMES.Active AS 'Active'
   ,AFFILIATOR.SubDomain AS 'SubDomain'
   ,AFFILIATOR.Guid AS 'Guid'
   ,THEMES.BACKGROUND_IMAGE AS 'BackgroundImage'
   ,THEMES.SECONDARY_COLOR AS 'SecondaryColor'
   ,[POS_AVAILABLE].[AVAILABLE] AS 'AvailablePOS'
   ,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC AS 'DefaultEc'
   ,SALES_REPRESENTATIVE.COD_SALES_REP
FROM USERS
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = USERS.COD_COMP
INNER JOIN PROFILE_ACCESS
	ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE
LEFT JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = USERS.COD_EC
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
INNER JOIN PASS_HISTORY
	ON PASS_HISTORY.COD_USER = USERS.COD_USER
INNER JOIN MODULES
	ON MODULES.COD_MODULE = USERS.COD_MODULE
LEFT JOIN ASS_FACTOR_AUTH_COMPANY
	ON ASS_FACTOR_AUTH_COMPANY.COD_COMP = COMPANY.COD_COMP
LEFT JOIN AUTHENTICATION_FACTOR
	ON AUTHENTICATION_FACTOR.COD_FACT = ASS_FACTOR_AUTH_COMPANY.COD_FACT
LEFT JOIN THEMES
	ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
LEFT JOIN POS_AVAILABLE
	ON POS_AVAILABLE.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
LEFT JOIN SALES_REPRESENTATIVE
	ON SALES_REPRESENTATIVE.COD_USER = USERS.COD_USER
WHERE COD_ACCESS = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1
AND (THEMES.Active = 1
OR THEMES.Active IS NULL)
OR USERS.EMAIL = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1
AND (THEMES.Active = 1
OR THEMES.Active IS NULL)
END;
GO
PRINT N'Altering [dbo].[SP_LS_AFFILIATOR_INFO]...';


GO

ALTER PROCEDURE [dbo].[SP_LS_AFFILIATOR_INFO]
/*----------------------------------------------------------------------------------------        
Procedure Name: SP_LS_AFFILIATOR_COMP        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Luiz Aquino                     V1            20/09/2018                           CREATION     
Luiz Aquino                     v2            04/07/2019                bank is_cerc
------------------------------------------------------------------------------------------*/ 
(
	@CodAff INT
)
AS
BEGIN

SET NOCOUNT ON

SELECT
	af.COD_ADR_AFL [AddrCod]
   ,af.COD_AFFILIATOR [AddrCodAff]
   ,af.CREATED_AT [AddrCreated]
   ,af.COD_USER_CAD [AddrUserCad]
   ,af.[ADDRESS] [AddrStreet]
   ,af.NUMBER [AddrNumber]
   ,af.COMPLEMENT [AddrComp]
   ,af.CEP [AddrCep]
   ,af.COD_NEIGH [AddrNeighCod]
   ,c.COD_CITY [AddrCityCod]
   ,s.COD_STATE [AddrStateCod]
   ,s.COD_COUNTRY [AddrCountryCod]
   ,af.ACTIVE [AddrActive]
   ,af.MODIFY_DATE [AddrModified]
   ,af.COD_USER_ALT [AddUserAltCod]
   ,af.REFERENCE_POINT [AddrReference]
   ,ac.COD_CONTACT_AFL [ContactCod]
   ,ac.COD_AFFILIATOR [ContactCodAff]
   ,ac.CREATED_AT [ContactCreated]
   ,ac.COD_USER_CAD [ContactUserCad]
   ,ac.NUMBER [ContactNumber]
   ,ac.COD_TP_CONT [ContactType]
   ,ac.COD_OPER [ContactOper]
   ,ac.MODIFY_DATE [ContactModified]
   ,ac.COD_USER_ALT [ContactUserAlt]
   ,ac.DDI [ContactDdi]
   ,ac.DDD [ContactDdd]
   ,ac.ACTIVE [ContactActive]
   ,bd.COD_BK_EC [BankCod]
   ,c.[NAME] [BankName]
   ,bd.CREATED_AT [BankCreated]
   ,bd.AGENCY [BankAgency]
   ,bd.DIGIT_AGENCY [BankAgencyDigit]
   ,bd.ACCOUNT [BankAccount]
   ,ISNULL(bd.DIGIT_ACCOUNT, '') [BankAccountDigit]
   ,bd.COD_BANK [BankCodBank]
   ,bd.COD_USER [BankCodUser]
   ,bd.ACTIVE [BankActive]
   ,bd.MODIFY_DATE [BankModified]
   ,bd.COD_TYPE_ACCOUNT [BankAccountTypeCod]
   ,act.[NAME] [BankAccountType]
   ,bd.COD_OPER_BANK [BankAccountOp]
   ,bd.COD_BRANCH [BankBranchCod]
   ,bd.COD_AFFILIATOR [BankAffiliatorCod]
   ,pca.COD_TYPE_PROG [AffProgressiveCod]
FROM AFFILIATOR a
JOIN ADDRESS_AFFILIATOR af
	ON af.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND af.ACTIVE = 1
JOIN NEIGHBORHOOD n
	ON n.COD_NEIGH = af.COD_NEIGH
JOIN CITY c
	ON c.COD_CITY = n.COD_CITY
JOIN [STATE] s
	ON s.COD_STATE = c.COD_STATE
JOIN AFFILIATOR_CONTACT ac
	ON ac.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND ac.ACTIVE = 1
JOIN BANK_DETAILS_EC bd
	ON bd.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND bd.COD_EC IS NULL
		AND bd.ACTIVE = 1
		AND bd.IS_CERC = 0
JOIN BANKS b
	ON b.COD_BANK = bd.COD_BANK
JOIN ACCOUNT_TYPE act
	ON act.COD_TYPE_ACCOUNT = bd.COD_TYPE_ACCOUNT
JOIN PROGRESSIVE_COST_AFFILIATOR pca
	ON pca.COD_AFFILIATOR = a.COD_AFFILIATOR
WHERE a.COD_AFFILIATOR = @CodAff
END;
GO
PRINT N'Altering [dbo].[SP_UPDATE_AFFILIATED]...';


GO
ALTER  PROCEDURE [DBO].[SP_UPDATE_AFFILIATED]                       
  
/***************************************************************************************************  
----------------------------------------------------------------------------------------            
Procedure Name: [SP_UPDATE_AFFILIATOR]            
Project.......: TKPP            
------------------------------------------------------------------------------------------            
Author          VERSION   Date              Description            
------------------------------------------------------------------------------------------            
Luiz Aquino  V1       01/10/2018   Creation            
Luiz Aquino  V2       18/12/2018   Add SPOT_TAX            
Lucas Aguiar v3   2019-04-19   add rotina de split            
Lucas Aguiar v4   2019-07-19   Rotina de agenda bloqueada                
Lucas Aguiar v5   2019-08-23   Add serviço de notificações          
Luiz Aquino  V6   2019-10-24   Add Serviço de retenção de agenda          
------------------------------------------------------------------------------------------  
***************************************************************************************************/  
            
(  
 @CODAFFILIATED          INT,            
 -- INFO BASE              
 @COD_COMP               INT,   
 @NAME                   VARCHAR(100),   
 @CPF_CNPJ               VARCHAR(14),   
 @COD_USER_CAD           INT,   
 @FIREBASE_NAME          VARCHAR(100)  = NULL,   
 @COD_USER_ALT           INT,   
 @PROGRESSIVE_COST       INT,             
 -- ADDRESS                
 @ADDRESS                VARCHAR(250),   
 @NUMBER                 VARCHAR(50),   
 @COMPLEMENT             VARCHAR(400)  = NULL,   
 @CEP                    VARCHAR(80),   
 @COD_NEIGH              INT,   
 @REFERENCE_POINT        VARCHAR(200)  = NULL,            
 -- CONTACT             
 @CELL_NUMBER            VARCHAR(30),   
 @COD_TP_CONT            INT,   
 @COD_OPER               INT,   
 @DDI                    VARCHAR(20),   
 @DDD                    VARCHAR(20),   
 @PHONE_NUMBER           VARCHAR(30)   = NULL,   
 @PHONE_COD_TP_CONT      INT           = NULL,   
 @PHONE_COD_OPER         INT           = NULL,   
 @PHONE_DDI              VARCHAR(20)   = NULL,   
 @PHONE_DDD              VARCHAR(20)   = NULL,             
 -- SUBDOMAIN              
 @SUBDOMAIN              VARCHAR(100),            
 -- BANK DETAILS              
 @AGENCY                 VARCHAR(100)  = NULL,   
 @DIGIT                  VARCHAR(100)  = NULL,   
 @ACCOUNT                VARCHAR(100)  = NULL,   
 @DIGIT_ACCOUNT          VARCHAR(100)  = NULL,   
 @BANK                   INT           = NULL,   
 @ACCOUNT_TYPE           INT           = NULL,   
 @SPOT_TAX               DECIMAL(6, 2)  = 0,   
 @HAS_SPOT               INT           = 0,   
 @SPLIT_OPT              INT           = 0,   
 @HAS_SPLIT              INT           = 0,   
 @WAS_BLOCKED            INT           = NULL,   
 @NOTE_FINANCE           VARCHAR(MAX)  = NULL,   
 @HAS_NOTIFICATION       INT           = 0,   
 @PASSWORD_NOTIFICATION  VARCHAR(255)  = NULL,   
 @CLIENTID_NOTIFICATION  VARCHAR(255)  = NULL,   
 @LEDGERRETENTION        INT           = 0,   
 @LEDGERRETENTIONCONFIG  VARCHAR(512)  = NULL,   
 @ACTIVE                 INT           = NULL,   
 @PLATFORMNAME           VARCHAR(100)  = NULL,   
 @COMPANY_NAME           VARCHAR(100)  = NULL,   
 @STATE_REGISTRATION     VARCHAR(100)  = NULL,   
 @MUNICIPAL_REGISTRATION VARCHAR(100)  = NULL,   
 @PROPOSED_NUMBER        VARCHAR(100)  = NULL,   
 @HAS_TRANSLATION        INT           = 0)  
AS  
BEGIN
  
  
  
  
    DECLARE   
   @CODSPOTSERVICE INT;
  
  
  
    DECLARE   
   @COD_SPLIT_SERVICE INT;
  
  
  
    DECLARE   
   @COD_SITUATION INT;
  
  
  
    DECLARE   
   @COD_GWNOTIFICATION INT;
  
  
    DECLARE   
   @HAS_CREDENTIAL INT = 0;
  
  
    DECLARE   
   @COD_AWAITSPLIT INT = 0;
  
  
    DECLARE   
   @COD_TRANSLATE INT;

SELECT
	@CODSPOTSERVICE = [COD_ITEM_SERVICE]
FROM [ITEMS_SERVICES_AVAILABLE]
WHERE [CODE] = '1';

SELECT
	@COD_SPLIT_SERVICE = [COD_ITEM_SERVICE]
FROM [ITEMS_SERVICES_AVAILABLE]
WHERE [NAME] = 'SPLIT';

SELECT
	@COD_GWNOTIFICATION = [COD_ITEM_SERVICE]
FROM [ITEMS_SERVICES_AVAILABLE]
WHERE [NAME] = 'GWNOTIFICATIONAFFILIATOR';

SELECT
	@COD_AWAITSPLIT = [COD_ITEM_SERVICE]
FROM [ITEMS_SERVICES_AVAILABLE]
WHERE [CODE] = '8';

SELECT
	@HAS_CREDENTIAL = COUNT(*)
FROM [ACCESS_APPAPI]
WHERE [COD_AFFILIATOR] = @CODAFFILIATED
AND [ACTIVE] = 1;

SELECT
	@COD_TRANSLATE = [COD_ITEM_SERVICE]
FROM [ITEMS_SERVICES_AVAILABLE]
WHERE [NAME] = 'TRANSLATE';

IF (@HAS_SPOT = 0
	AND (SELECT
			COUNT(*)
		FROM [SERVICES_AVAILABLE]
		WHERE [COD_ITEM_SERVICE] = @CODSPOTSERVICE
		AND [COD_AFFILIATOR] = @CODAFFILIATED
		AND [COD_EC] IS NOT NULL
		AND [ACTIVE] = 1)
	> 0)
THROW 61046, 'Conflict Affiliated has establishments with Spot Active', 1;

IF (@HAS_SPLIT = 0
	AND (SELECT
			COUNT(*)
		FROM [SERVICES_AVAILABLE]
		WHERE [COD_ITEM_SERVICE] = @COD_SPLIT_SERVICE
		AND [COD_AFFILIATOR] = @CODAFFILIATED
		AND [COD_EC] IS NOT NULL
		AND [ACTIVE] = 1)
	> 0)
THROW 61049, 'AFFILIATE CONFLICT HAS ALREADY ESTABLISHMENTS WITH SPLIT ENABLE', 1;

IF (@HAS_SPLIT = 1
	AND @SPLIT_OPT = 1
	AND (SELECT
			COUNT(*)
		FROM [SERVICES_AVAILABLE]
		WHERE [COD_ITEM_SERVICE] = @COD_SPLIT_SERVICE
		AND [COD_AFFILIATOR] = @CODAFFILIATED
		AND [COD_EC] IS NOT NULL
		AND [ACTIVE] = 1)
	> 0)
THROW 61049, 'AFFILIATE CONFLICT HAS ALREADY ESTABLISHMENTS WITH SPLIT ENABLE', 1;

/*******************************************  
*********** UPDATE SPOT AFFILIATED *********  
*******************************************/

IF (SELECT
			COUNT(*)
		FROM [SERVICES_AVAILABLE]
		WHERE [COD_ITEM_SERVICE] = 1
		AND [COD_AFFILIATOR] = @CODAFFILIATED
		AND [COD_EC] IS NULL
		AND [ACTIVE] = 1)
	> 0
BEGIN
IF @HAS_SPOT = 0
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @CODSPOTSERVICE
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;
END;
ELSE
BEGIN
IF @SPOT_TAX > (SELECT
			MIN([SPOT_TAX])
		FROM [COMMERCIAL_ESTABLISHMENT]
		WHERE [COD_AFFILIATOR] = @CODAFFILIATED
		AND [SPOT_TAX] <> 0
		AND [ACTIVE] = 1)
THROW 61047, 'AFFILIATED NEW SPOT TAX IS HIGHER THAN ONE OF ITS ESTABLISHMENTS', 1;
END;
END;
ELSE
IF @HAS_SPOT = 1
BEGIN
INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[MODIFY_DATE])
	VALUES (current_timestamp, @COD_USER_ALT, @CODSPOTSERVICE, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp);
END;

/********************************************  
*********** UPDATE SPLIT AFFILIATED *********  
********************************************/

IF (@HAS_SPLIT = 0)
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_SPLIT_SERVICE
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;
END;
ELSE
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_SPLIT_SERVICE
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;

INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[MODIFY_DATE],
[COD_OPT_SERV])
	VALUES (current_timestamp, @COD_USER_ALT, @COD_SPLIT_SERVICE, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, (SELECT [COD_OPT_SERV] FROM [OPTIONS_SERVICES] WHERE [CODE] = @SPLIT_OPT));
END;

/**********************************************  
*********** UPDATE LEDGER RETENTION ***********  
**********************************************/

IF (@LEDGERRETENTION = 0)
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_AWAITSPLIT
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED;
END;
ELSE
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_AWAITSPLIT
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;

INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[MODIFY_DATE],
[CONFIG_JSON])
	VALUES (current_timestamp, @COD_USER_ALT, @COD_AWAITSPLIT, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, @LEDGERRETENTIONCONFIG);

DECLARE @DT_FROM DATE;
DECLARE @DT_UNTIL DATE;

SELECT
	@DT_FROM = CONVERT(DATE, JSON_VALUE(@LEDGERRETENTIONCONFIG, '$.from'), 103);
SELECT
	@DT_UNTIL = CONVERT(DATE, JSON_VALUE(@LEDGERRETENTIONCONFIG, '$.until'), 103);

UPDATE [LEDGER_RETENTION_CONTROL]
SET [ACTIVE] = 0
FROM [LEDGER_RETENTION_CONTROL]
JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [LEDGER_RETENTION_CONTROL].[COD_EC]
WHERE [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR] = 1
AND [LEDGER_RETENTION_CONTROL].[ACTIVE] = 1
AND ([LEDGER_RETENTION_CONTROL].[FROM_DATE] < @DT_FROM
OR [LEDGER_RETENTION_CONTROL].[FROM_DATE] > @DT_UNTIL
OR [LEDGER_RETENTION_CONTROL].[UNTIL_DATE] > @DT_UNTIL);

END;


/************************************************  
*********** UPDATE TRANSLATE AFFILIATED *********  
************************************************/

IF @HAS_TRANSLATION = 0
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_TRANSLATE
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;
END;
ELSE
BEGIN
IF (SELECT
			COUNT(*)
		FROM [SERVICES_AVAILABLE]
		WHERE [COD_ITEM_SERVICE] = @COD_TRANSLATE
		AND [COD_COMP] = @COD_COMP
		AND [COD_AFFILIATOR] = @CODAFFILIATED
		AND [COD_EC] IS NULL
		AND [ACTIVE] = 1)
	= 0
BEGIN
INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[MODIFY_DATE])
	VALUES (current_timestamp, @COD_USER_ALT, @COD_TRANSLATE, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp);
END;

END;


/***************************************************  
*********** UPDATE NOTIFICATION AFFILIATED *********  
***************************************************/

IF @HAS_NOTIFICATION = 0
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_GWNOTIFICATION
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;

UPDATE [ACCESS_APPAPI]
SET [ACTIVE] = 0
WHERE [COD_AFFILIATOR] = @CODAFFILIATED
AND [ACTIVE] = 1;
END;
ELSE
IF @HAS_CREDENTIAL = 0
	AND @HAS_NOTIFICATION = 1
BEGIN
UPDATE [SERVICES_AVAILABLE]
SET [ACTIVE] = 0
   ,[COD_USER] = @COD_USER_ALT
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_ITEM_SERVICE] = @COD_GWNOTIFICATION
AND [COD_COMP] = @COD_COMP
AND [COD_AFFILIATOR] = @CODAFFILIATED
AND [COD_EC] IS NULL;

INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[MODIFY_DATE])
	VALUES (current_timestamp, @COD_USER_ALT, @COD_GWNOTIFICATION, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp);

EXEC [SP_REG_ACCESS_NOTIFICATION_AFF] @CODAFFILIATED
									 ,@PASSWORD_NOTIFICATION
									 ,@CLIENTID_NOTIFICATION;
END;

/********************************************************  
*********** UPDATE PROGRESSIVEE COST AFFILIATOR *********  
********************************************************/

/***********************  
BLOCKED FINANCE SCHEDULE  
***********************/

IF @WAS_BLOCKED = 1
SELECT
	@COD_SITUATION = [COD_SITUATION]
FROM [SITUATION]
WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';
ELSE
IF @WAS_BLOCKED = 0
SELECT
	@COD_SITUATION = [COD_SITUATION]
FROM [SITUATION]
WHERE [NAME] = 'RELEASED';
ELSE
SELECT
	@COD_SITUATION = [COD_SITUATION]
FROM [AFFILIATOR]
WHERE [COD_AFFILIATOR] = @CODAFFILIATED;

/**************  
LOGS AFFILIATOR  
**************/

EXEC [SP_LOG_AFF_REG] @COD_USER = @COD_USER_ALT
					 ,@COD_AFF = @CODAFFILIATED;

/*********  
AFFILIATOR  
*********/

UPDATE [AFFILIATOR]
SET [NAME] = @NAME
   ,[MODIFY_DATE] = current_timestamp
   ,[CPF_CNPJ] = @CPF_CNPJ
   ,[COD_USER_ALT] = @COD_USER_CAD
   ,[FIREBASE_NAME] = @FIREBASE_NAME
   ,[SUBDOMAIN] = @SUBDOMAIN
   ,[SPOT_TAX] = @SPOT_TAX
   ,[COD_SITUATION] = @COD_SITUATION
   ,[NOTE_FINANCE_SCHEDULE] = @NOTE_FINANCE
   ,[ACTIVE] = @ACTIVE
   ,[PLATFORM_NAME] = @PLATFORMNAME
   ,[COMPANY_NAME] = @COMPANY_NAME
   ,[STATE_REGISTRATION] = @STATE_REGISTRATION
   ,[MUNICIPAL_REGISTRATION] = @MUNICIPAL_REGISTRATION
   ,[PROPOSED_NUMBER] = @PROPOSED_NUMBER
WHERE [COD_AFFILIATOR] = @CODAFFILIATED;


/*******************************************************************  
 ******************* ADDRESS AFFILIATOR ****************************  
*******************************************************************/

UPDATE [ADDRESS_AFFILIATOR]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = GETDATE()
WHERE [ACTIVE] = 1
AND [COD_AFFILIATOR] = @CODAFFILIATED;

INSERT INTO [ADDRESS_AFFILIATOR] ([COD_AFFILIATOR],
[CREATED_AT],
[COD_USER_CAD],
[ADDRESS],
[NUMBER],
[COMPLEMENT],
[CEP],
[COD_NEIGH],
[ACTIVE],
[MODIFY_DATE],
[COD_USER_ALT],
[REFERENCE_POINT])
	VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @ADDRESS, @NUMBER, @COMPLEMENT, @CEP, @COD_NEIGH, 1, current_timestamp, @COD_USER_ALT, @REFERENCE_POINT);

/*********************************************************************  
************************ AFFILIATOR CONTACT **************************  
*********************************************************************/

UPDATE [AFFILIATOR_CONTACT]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_AFFILIATOR] = @CODAFFILIATED
AND [ACTIVE] = 1;

INSERT INTO [AFFILIATOR_CONTACT] ([COD_AFFILIATOR],
[CREATED_AT],
[COD_USER_CAD],
[NUMBER],
[COD_TP_CONT],
[COD_OPER],
[MODIFY_DATE],
[COD_USER_ALT],
[DDI],
[DDD],
[ACTIVE])
	VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @CELL_NUMBER, @COD_TP_CONT, @COD_OPER, current_timestamp, @COD_USER_ALT, @DDI, @DDD, 1);

IF (@PHONE_NUMBER IS NOT NULL)
BEGIN
INSERT INTO [AFFILIATOR_CONTACT] ([COD_AFFILIATOR],
[CREATED_AT],
[COD_USER_CAD],
[NUMBER],
[COD_TP_CONT],
[COD_OPER],
[MODIFY_DATE],
[COD_USER_ALT],
[DDI],
[DDD],
[ACTIVE])
	VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @PHONE_NUMBER, @PHONE_COD_TP_CONT, @PHONE_COD_OPER, current_timestamp, @COD_USER_ALT, @PHONE_DDI, @PHONE_DDD, 1);
END;

/*******************************************************  
********************* BANK DETAILS *********************  
*******************************************************/

UPDATE [BANK_DETAILS_EC]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = current_timestamp
WHERE [COD_AFFILIATOR] = @CODAFFILIATED;

INSERT INTO [BANK_DETAILS_EC] ([AGENCY],
[DIGIT_AGENCY],
[COD_TYPE_ACCOUNT],
[COD_BANK],
[ACCOUNT],
[DIGIT_ACCOUNT],
[COD_USER],
[COD_OPER_BANK],
[COD_AFFILIATOR])
	VALUES (@AGENCY, @DIGIT, @ACCOUNT_TYPE, @BANK, @ACCOUNT, @DIGIT_ACCOUNT, @COD_USER_CAD, @COD_OPER, @CODAFFILIATED);

SELECT
	@CODAFFILIATED AS 'COD_AFFILIATOR';
END;
GO
PRINT N'Altering [dbo].[SP_FINANCE_SCHEDULE_GENERATE_ALL_AWAITING_PAYMENTS]...';


GO


ALTER PROCEDURE [DBO].[SP_FINANCE_SCHEDULE_GENERATE_ALL_AWAITING_PAYMENTS]            
  
/*****************************************************************************************************
----------------------------------------------------------------------------------------            
Procedure Name: [SP_FINANCE_SCHEDULE_GENERATE_ALL_AWAITING_PAYMENTS]            
Project.......: TKPP            
------------------------------------------------------------------------------------------            
Author           VERSION        Date        Description            
------------------------------------------------------------------------------------------            
Luiz Aquino         V1      26/03/2019      Creation            
Elir Ribeiro  v2      25/06/2019      Changed          
Luiz Aquino   v3  16/07/2019  Add lock schedule insert        
Luiz Aquino   v4  2019-11-19  Add Trace Info to the file (Celer Digital)    
------------------------------------------------------------------------------------------  
*****************************************************************************************************/  
    
(
	@FCODE     [TP_CNAB_PAYMNT] READONLY, 
	@TYPE_BANK INT)
AS
BEGIN
    
     
    --==================================================================    
    --===    REGISTRANDO ARQUIVOS ===    
    --==================================================================    

    DECLARE @CONT INT;

SELECT
	@CONT = COUNT(*)
FROM [FINANCE_SCHEDULE_FILE]
INNER JOIN @FCODE AS [FINFO]
	ON [FINANCE_SCHEDULE_FILE].[FILE_NAME] = [FINFO].[FILE_NAME]
		AND [FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE] = [FINFO].[SEQ_FILE]
		AND [FINANCE_SCHEDULE_FILE].[TYPE_BANK] = @TYPE_BANK
		AND [FINANCE_SCHEDULE_FILE].[ACTIVE] = 1;

DECLARE @COD_BK_CELER INT;
DECLARE @CODE_BK_CELER VARCHAR(100);

SELECT
	@COD_BK_CELER = [COD_BANK]
FROM [BANKS]
WHERE [NAME] = 'Celer Digital';
SELECT
	@CODE_BK_CELER = [CODE]
FROM [BANKS]
WHERE [NAME] = 'Celer Digital';

IF @CONT > 0
THROW 61005, 'FINANCE_SCHEDULE_FILE ALREADY REGISTERED', 1;

SELECT
	[F].[COD_EC]
   ,[BK_EC].[COD_BANK]
   ,[F].[COD_BK_EC] INTO [#ECSTOIGNORE]
FROM @FCODE AS [F]
JOIN [BANK_DETAILS_EC] AS [BK_EC]
	ON [BK_EC].[COD_BK_EC] = [F].[COD_BK_EC]
WHERE [BK_EC].[IS_CERC] = 0;

SELECT
	[F].[COD_EC]
   ,[BK_EC].[COD_BANK]
   ,[F].[COD_BK_EC] INTO [#ECCERCTOIGNORE]
FROM @FCODE AS [F]
JOIN [BANK_DETAILS_EC] AS [BK_EC]
	ON [BK_EC].[COD_BK_EC] = [F].[COD_BK_EC]
WHERE [BK_EC].[IS_CERC] = 1;

IF @COD_BK_CELER = @TYPE_BANK
BEGIN
DELETE FROM [#ECSTOIGNORE]
WHERE [COD_BANK] = @COD_BK_CELER;
DELETE FROM [#ECCERCTOIGNORE]
WHERE [COD_BANK] = @COD_BK_CELER;
END;
ELSE
BEGIN
DELETE FROM [#ECSTOIGNORE]
WHERE [COD_BANK] != @COD_BK_CELER;
DELETE FROM [#ECCERCTOIGNORE]
WHERE [COD_BANK] != @COD_BK_CELER;
END;

INSERT INTO [dbo].[FINANCE_SCHEDULE_FILE] ([CREATED_AT],
[STATUS],
[FILE_NAME],
[FILE_SEQUENCE],
[RETURN_FILE_NAME],
[ACTIVE],
[COD_USER_CREAT],
[MODIFY_DATE],
[COD_USER_MODIFY],
[SEARCH_DATE],
[COD_BK_EC],
[TYPE_BANK],
[TRACEID],
[TRANSACTION_ID],
[AMOUNT])
	SELECT
		GETDATE()
	   ,NULL
	   ,[FILE_NAME]
	   ,[SEQ_FILE]
	   ,NULL
	   ,1
	   ,[COD_USER]
	   ,GETDATE()
	   ,[COD_USER]
	   ,[DATE]
	   ,[COD_BK_EC]
	   ,@TYPE_BANK
	   ,[TRACE_ID]
	   ,[TRANSACTION_ID]
	   ,[AMOUNT]
	FROM @FCODE AS [F]
	WHERE [F].[COD_BK_EC] NOT IN (SELECT
			[COD_BK_EC]
		FROM [#ECSTOIGNORE])
	AND [F].[COD_BK_EC] NOT IN (SELECT
			[COD_BK_EC]
		FROM [#ECCERCTOIGNORE]);

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER [FINANCE_SCHEDULE_FILE] ', 1;

--==================================================================    
-- ==       ATUALIZAR TITULOS    ===    
--==================================================================    

SELECT
	[F].[COD_EC]
   ,[F].[COD_AFF]
   ,DATEADD([SECOND], -1, DATEADD(DAY, 1, CAST([F].[DATE] AS DATETIME))) AS [DATE]
   ,[F].[COD_USER]
   ,[FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE] AS [COD_FILE]
   ,[F].[COD_BK_EC]
   ,[BANK_DETAILS_EC].[IS_CERC] INTO [#ECCODES]
FROM @FCODE AS [F]
LEFT JOIN [dbo].[FINANCE_SCHEDULE_FILE]
	ON [FINANCE_SCHEDULE_FILE].[FILE_NAME] = [F].[FILE_NAME]
		AND [FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE] = [F].[SEQ_FILE]
		AND [FINANCE_SCHEDULE_FILE].[ACTIVE] = 1
JOIN [BANK_DETAILS_EC](NOLOCK)
	ON [BANK_DETAILS_EC].[COD_BK_EC] = [F].[COD_BK_EC]
WHERE [F].[COD_EC] IS NOT NULL;

SELECT
	[F].[COD_EC]
   ,[F].[COD_AFF]
   ,DATEADD([SECOND], -1, DATEADD(DAY, 1, CAST([F].[DATE] AS DATETIME))) AS [DATE]
   ,[F].[COD_USER]
   ,[FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE] AS [COD_FILE]
   ,[F].[COD_BK_EC] INTO [#AFCODES]
FROM @FCODE AS [F]
INNER JOIN [dbo].[FINANCE_SCHEDULE_FILE]
	ON [FINANCE_SCHEDULE_FILE].[FILE_NAME] = [F].[FILE_NAME]
		AND [FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE] = [F].[SEQ_FILE]
		AND [FINANCE_SCHEDULE_FILE].[ACTIVE] = 1
WHERE [F].[COD_AFF] IS NOT NULL;

DECLARE @TOTAL_EC DECIMAL(15, 2) = 0;
DECLARE @TOTAL_CERC DECIMAL(15, 2) = 0;
DECLARE @QTY_CERC INT = 0;

SELECT
	@TOTAL_EC = CAST(SUM([VW_FINANCE_SCHEDULE].[PLOT_VALUE_PAYMENT]) AS DECIMAL(15, 2))
FROM [#ECCODES] AS [FCODE]
INNER JOIN [dbo].[VW_FINANCE_SCHEDULE]
	ON [VW_FINANCE_SCHEDULE].[COD_EC] NOT IN (SELECT
				[COD_EC]
			FROM [#ECSTOIGNORE])
		AND [VW_FINANCE_SCHEDULE].[COD_EC] = [FCODE].[COD_EC]
		AND [VW_FINANCE_SCHEDULE].[PREVISION_PAY_DATE] <= [FCODE].[DATE];

SELECT
	[FCODE].[COD_USER]
   ,[CERC].[COD_TITLE]
   ,[CERC].[CERC_VALUE]
   ,[CERC].[COD_BK_EC]
   ,NULL AS [COD_PAY_PROT]
   ,[FCODE].[COD_FILE]
   ,4 AS [COD_SITUATION]
   ,[FCODE].[COD_EC]
   ,[lock_situation]
   ,[CERC_ONLY_PAYMENT] INTO [#CERC_VL]
FROM [#ECCODES] AS [FCODE]
JOIN [VW_PAYMENT_DIARY_CERC] AS [CERC]
	ON [CERC].[PREVISION_PAY_DATE] < [FCODE].[DATE]
		AND [CERC].[COD_EC] = [FCODE].[COD_EC]
		AND [CERC].[COD_BK_EC] = [FCODE].[COD_BK_EC];

SELECT
	@TOTAL_CERC = SUM([CERC_VALUE])
FROM [#CERC_VL]
WHERE [COD_EC] NOT IN (SELECT
		[COD_EC]
	FROM [#ECCERCTOIGNORE]);

SELECT
	@QTY_CERC = COUNT(*)
FROM [#CERC_VL]
WHERE [COD_EC] NOT IN (SELECT
		[COD_EC]
	FROM [#ECCERCTOIGNORE])
GROUP BY [COD_BK_EC];

SET @TOTAL_EC = @TOTAL_EC - @TOTAL_CERC;

    IF @TOTAL_EC < 0
    BEGIN
	   DECLARE @DEDUCT DECIMAL(15, 2)= @TOTAL_EC / @QTY_CERC;
UPDATE [#CERC_VL]
SET [CERC_VALUE] = [CERC_VALUE] + (([CERC_VALUE] / (SELECT
		SUM([VL2].[CERC_VALUE])
	FROM [#CERC_VL] AS [VL2]
	WHERE [VL2].[COD_BK_EC] = [COD_BK_EC])
) * @DEDUCT);
END;

INSERT INTO [TITLE_LOCK_PAYMENT_DETAILS] ([COD_USER],
[COD_TITLE],
[AMOUNT],
[COD_BK_EC],
[COD_PAY_PROT],
[COD_FIN_SCH_FILE],
[COD_SITUATION],
[COD_EC])
	SELECT
		[COD_USER]
	   ,[COD_TITLE]
	   ,[CERC_VALUE]
	   ,[COD_BK_EC]
	   ,[COD_PAY_PROT]
	   ,[COD_FILE]
	   ,[COD_SITUATION]
	   ,[COD_EC]
	FROM [#CERC_VL]
	WHERE [lock_situation] IS NULL
	AND [CERC_ONLY_PAYMENT] = 0;

IF (SELECT
			COUNT(*)
		FROM [#ECCODES])
	> 0
BEGIN
UPDATE [TRANSACTION_TITLES]
SET [COD_SITUATION] = 17
   ,[COD_FIN_SCH_FILE] = [FCODE].[COD_FILE]
   ,[MODIFY_DATE] = GETDATE()
FROM [TRANSACTION_TITLES]
INNER JOIN [#ECCODES] [FCODE] (NOLOCK)
	ON [FCODE].[COD_EC] NOT IN (SELECT
			[COD_EC]
		FROM [#ECSTOIGNORE])
	AND [FCODE].[COD_EC] = [TRANSACTION_TITLES].[COD_EC]
	AND [IS_CERC] = 0
	AND [TRANSACTION_TITLES].[PREVISION_PAY_DATE] < [FCODE].[DATE]
WHERE [TRANSACTION_TITLES].[COD_SITUATION] = 4;

UPDATE [RELEASE_ADJUSTMENTS]
SET [COD_SITUATION] = 17
   ,[COD_FIN_SCH_FILE] = [FCODE].[COD_FILE]
FROM [RELEASE_ADJUSTMENTS]
INNER JOIN [#ECCODES] [FCODE]
	ON [FCODE].[COD_EC] NOT IN (SELECT
			[COD_EC]
		FROM [#ECSTOIGNORE])
	AND [FCODE].[COD_EC] = [RELEASE_ADJUSTMENTS].[COD_EC]
	--AND [IS_CERC] = 0  
	AND [PREVISION_PAY_DATE] < [FCODE].[DATE]
WHERE [RELEASE_ADJUSTMENTS].[COD_SITUATION] = 4;

UPDATE [TARIFF_EC]
SET [COD_SITUATION] = 17
   ,[COD_FIN_SCH_FILE] = [FCODE].[COD_FILE]
   ,[MODIFY_DATE] = GETDATE()
FROM [TARIFF_EC]
INNER JOIN [#ECCODES] [FCODE]
	ON [FCODE].[COD_EC] NOT IN (SELECT
			[COD_EC]
		FROM [#ECSTOIGNORE])
	AND [FCODE].[COD_EC] = [TARIFF_EC].[COD_EC]
	--AND [IS_CERC] = 0  
	AND [PAYMENT_DAY] < [FCODE].[DATE]
WHERE [TARIFF_EC].[COD_SITUATION] = 4;

UPDATE [TITLE_LOCK_PAYMENT_DETAILS]
SET [COD_SITUATION] = 17
   ,[COD_FIN_SCH_FILE] = [ECVL].[COD_FILE]
   ,[AMOUNT] = [ECVL].[CERC_VALUE]
FROM [TITLE_LOCK_PAYMENT_DETAILS]
INNER JOIN [#CERC_VL] [ECVL]
	ON [ECVL].[COD_EC] NOT IN (SELECT
			[COD_EC]
		FROM [#ECCERCTOIGNORE])
	AND [ECVL].[COD_EC] = [TITLE_LOCK_PAYMENT_DETAILS].[COD_EC]
	AND [ECVL].[COD_TITLE] = [TITLE_LOCK_PAYMENT_DETAILS].[COD_TITLE]
WHERE [TITLE_LOCK_PAYMENT_DETAILS].[COD_SITUATION] = 4;

END;

IF (SELECT
			COUNT(*)
		FROM [#AFCODES])
	> 0
BEGIN
UPDATE [TRANSACTION_TITLES_COST]
SET [COD_SITUATION] = 17
   ,[COD_FIN_SCH_FILE] = [FCODE].[COD_FILE]
   ,[MODIFY_DATE] = GETDATE()
FROM [TRANSACTION_TITLES_COST]
INNER JOIN [#AFCODES] [FCODE]
	ON [FCODE].[COD_AFF] = [TRANSACTION_TITLES_COST].[COD_AFFILIATOR]
	AND [TRANSACTION_TITLES_COST].[PREVISION_PAY_DATE] < [FCODE].[DATE]
INNER JOIN [BANK_DETAILS_EC](NOLOCK)
	ON [BANK_DETAILS_EC].[COD_BK_EC] = [FCODE].[COD_BK_EC]
	AND [BANK_DETAILS_EC].[IS_CERC] = 0
	AND (@TYPE_BANK != @COD_BK_CELER
	OR [BANK_DETAILS_EC].[COD_BANK] = @COD_BK_CELER)
WHERE [COD_SITUATION] = 4;
END;
END;
GO
PRINT N'Altering [dbo].[SP_EXP_FINANCE_CALENDAR]...';


GO

ALTER PROCEDURE [DBO].[SP_EXP_FINANCE_CALENDAR]                
  
/*******************************************************************************************************  
----------------------------------------------------------------------------------------                
Procedure Name: [SP_LS_TYPE_ACCOUNT]                
Project.......: TKPP                
------------------------------------------------------------------------------------------                
Author                          VERSION        Date                            Description                
------------------------------------------------------------------------------------------                
Lucas Aguiar     v1      2019-10-03      CRIA��O              
------------------------------------------------------------------------------------------  
*******************************************************************************************************/  
                
(  
 @REF_DATE        DATETIME,   
 @EC              [CODE_TYPE] READONLY,   
 @BANK            [CODE_TYPE] READONLY,   
 @CODAFF          [CODE_TYPE] READONLY,   
 @ACCOUNT         [CODE_TYPE] READONLY,   
 @CODSITUATION    INT         = NULL,   
 @MINVALUE        DECIMAL     = NULL,   
 @CHECK_CONFIRM   INT         = 1,   
 @CHECK_PAYMENT   INT         = 1,   
 @CHECK_BLOCK     INT         = 1,   
 @CHECK_SPLIT     INT         = 1,   
 @ONLY_ASSIGNMENT INT         = 0)  
AS  
BEGIN
  
  
    DECLARE   
   @QUERY NVARCHAR(MAX);



SELECT
	@REF_DATE AS [DATE]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[IDENTIFIER]
   ,CAST(SUM(CASE
		WHEN [VW_PAYMENT_DIARY_CERC_EXP].[PENDING_PAYMENT] = 1 THEN [VW_PAYMENT_DIARY_CERC_EXP].[CERC_VALUE]
		ELSE 0
	END) AS DECIMAL(15, 2)) AS [PLOT_VALUE_PAYMENT]
   ,CAST(SUM([VW_PAYMENT_DIARY_CERC_EXP].[CERC_VALUE]) AS DECIMAL(15, 2)) AS [GROSS_TOTAL_VALUE]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[CODE_BANK]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[AGENCY]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[ACCOUNT]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[CPF_CNPJ]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[NAME]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[ACCOUNT_EC]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[COD_AFFILIATOR]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[COD_EC]
   ,[DIGIT_ACCOUNT]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[AGENCY_EC]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[COD_BK_EC]
   ,(CASE
		WHEN [VW_PAYMENT_DIARY_CERC_EXP].[lock_situation] = 27 AND
			[BLOCKED_FINANCE] <> 1 THEN 'AGUARDANDO SPLIT'
		WHEN [VW_PAYMENT_DIARY_CERC_EXP].[lock_situation] = 17 AND
			[BLOCKED_FINANCE] <> 1 THEN 'CONFIRMACAO'
		WHEN [VW_PAYMENT_DIARY_CERC_EXP].[lock_situation] = 4 AND
			[BLOCKED_FINANCE] <> 1 THEN 'PAGAMENTO'
		WHEN [BLOCKED_FINANCE] = 1 THEN 'AGENDA SUSPENSA'
	END) AS [PAYMENT_SITUATION]
   ,0 AS [WAS_PRORATED]
   ,0 AS [FILE_CODE]
   ,1 AS IsLocked
   ,[VW_PAYMENT_DIARY_CERC_EXP].[TYPE_ESTAB]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[BANK_NAME]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[ACCOUNT_TYPE]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[AFF_NAME]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[OPERATION]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[CREATED_AT]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[IS_ASSIGNMENT]
   ,[VW_PAYMENT_DIARY_CERC_EXP].[ASSIGNMENT_IDENTIFICATION] INTO [#TEMP_CERC]
FROM [VW_PAYMENT_DIARY_CERC_EXP]
WHERE [PREVISION_PAY_DATE] <= @REF_DATE
AND [lock_situation] <> 8
AND (([VW_PAYMENT_DIARY_CERC_EXP].[COD_EC] IN (SELECT
		*
	FROM @EC)
AND (SELECT
		COUNT(*)
	FROM @EC)
> 0)
OR (SELECT
		COUNT(*)
	FROM @EC)
= 0)
AND (([VW_PAYMENT_DIARY_CERC_EXP].[COD_BANK] IN (SELECT
		*
	FROM @BANK)
AND (SELECT
		COUNT(*)
	FROM @BANK)
> 0)
OR (SELECT
		COUNT(*)
	FROM @BANK)
= 0)
AND (([VW_PAYMENT_DIARY_CERC_EXP].[COD_AFFILIATOR] IN (SELECT
		*
	FROM @CODAFF)
AND (SELECT
		COUNT(*)
	FROM @CODAFF)
> 0)
OR (SELECT
		COUNT(*)
	FROM @CODAFF)
= 0)
AND (([VW_PAYMENT_DIARY_CERC_EXP].[COD_SITUATION] = @CODSITUATION)
OR (@CODSITUATION IS NULL)
AND (([VW_PAYMENT_DIARY_CERC_EXP].[COD_TYPE_ACCOUNT] IN (SELECT
		[CODE]
	FROM @ACCOUNT)
AND (SELECT
		COUNT(*)
	FROM @ACCOUNT)
> 0))
OR (SELECT
		COUNT(*)
	FROM @ACCOUNT)
= 0)
GROUP BY [IDENTIFIER]
		,[CODE_BANK]
		,[AGENCY]
		,[ACCOUNT]
		,[ACCOUNT_EC]
		,[CPF_CNPJ]
		,[NAME]
		,[AGENCY_EC]
		,[ACCOUNT_EC]
		,[COD_AFFILIATOR]
		,[COD_EC]
		,[DIGIT_ACCOUNT]
		,[VW_PAYMENT_DIARY_CERC_EXP].[COD_BK_EC]
		,CASE
			 WHEN [VW_PAYMENT_DIARY_CERC_EXP].[lock_situation] = 27 AND
				 [BLOCKED_FINANCE] <> 1 THEN 'AGUARDANDO SPLIT'
			 WHEN [VW_PAYMENT_DIARY_CERC_EXP].[lock_situation] = 17 AND
				 [BLOCKED_FINANCE] <> 1 THEN 'CONFIRMACAO'
			 WHEN [VW_PAYMENT_DIARY_CERC_EXP].[lock_situation] = 4 AND
				 [BLOCKED_FINANCE] <> 1 THEN 'PAGAMENTO'
			 WHEN [BLOCKED_FINANCE] = 1 THEN 'AGENDA SUSPENSA'
		 END
		,[VW_PAYMENT_DIARY_CERC_EXP].[TYPE_ESTAB]
		,[VW_PAYMENT_DIARY_CERC_EXP].[BANK_NAME]
		,[VW_PAYMENT_DIARY_CERC_EXP].[ACCOUNT_TYPE]
		,[VW_PAYMENT_DIARY_CERC_EXP].[AFF_NAME]
		,[VW_PAYMENT_DIARY_CERC_EXP].[OPERATION]
		,[VW_PAYMENT_DIARY_CERC_EXP].[CREATED_AT]
		,[VW_PAYMENT_DIARY_CERC_EXP].[IS_ASSIGNMENT]
		,[VW_PAYMENT_DIARY_CERC_EXP].[ASSIGNMENT_IDENTIFICATION];



SELECT
	@REF_DATE AS [DATE]
   ,[VWREPEC].[CODE] AS [IDENTIFIER]
   ,SUM([VWREPEC].[PLOT_VALUE_PAYMENT]) AS [PLOT_VALUE_PAYMENT]
   ,[VWREPEC].[CODE_BANK]
   ,[VWREPEC].[AGENCY]
   ,[VWREPEC].[ACCOUNT]
   ,[VWREPEC].[CPF_CNPJ_EC] AS [CPF_CNPJ]
   ,[VWREPEC].[EC] AS [NAME]
   ,[BANK_DETAILS_EC].[AGENCY] AS [AGENCY_EC]
   ,[BANK_DETAILS_EC].[ACCOUNT] AS [ACCOUNT_EC]
   ,[VWREPEC].[COD_AFFILIATOR]
   ,[VWREPEC].[COD_EC]
   ,[VWREPEC].[DIGIT_ACCOUNT]
   ,[BANK_DETAILS_EC].[COD_BK_EC]
   ,[VWREPEC].[BANK]
   ,[VWREPEC].[ACCOUNT_TYPE]
   ,[VWREPEC].[COD_TYPE_ACCOUNT]
   ,(CASE
		WHEN [VWREPEC].[COD_SITUATION] = 27 AND
			[BLOCKED_FINANCE] <> 1 THEN 'AGUARDANDO SPLIT'
		WHEN [VWREPEC].[COD_SITUATION] = 17 AND
			[BLOCKED_FINANCE] <> 1 THEN 'CONFIRMACAO'
		WHEN [VWREPEC].[COD_SITUATION] = 4 AND
			[BLOCKED_FINANCE] <> 1 THEN 'PAGAMENTO'
		WHEN [BLOCKED_FINANCE] = 1 THEN 'AGENDA SUSPENSA'
	END) AS [PAYMENT_SITUATION]
   ,0 AS [WAS_PRORATED]
   ,0 AS [FILE_CODE]
   ,0 AS IsLocked
   ,[VWREPEC].[COD_SITUATION]
   ,[VWREPEC].[TYPE_ESTAB]
   ,[VWREPEC].[BANK] AS [BANK_NAME]
   ,[VWREPEC].[NAME_AFFILIATOR] AS [AFF_NAME]
   ,[VWREPEC].[OPERATION_CODE] AS [OPERATION]
   ,[VWREPEC].[CREATED_AT]
   ,[VWREPEC].[IS_ASSIGNMENT]
   ,[VWREPEC].[ASSIGNMENT_IDENTIFICATION] INTO [#TEMP_FIN]
FROM [dbo].[VW_REP_RELEASES_EC] AS [VWREPEC]
JOIN [BANKS]
	ON [BANKS].[COD_BANK] = [VWREPEC].[COD_BANK]
JOIN [BANK_DETAILS_EC]
	ON [BANK_DETAILS_EC].[COD_BRANCH] = [VWREPEC].[COD_EC]
		AND [BANK_DETAILS_EC].[ACTIVE] = 1
		AND [BANK_DETAILS_EC].[IS_CERC] = 0
WHERE [PREVISION_PAY_DATE] <= @REF_DATE
--AND (VWREPEC.COD_FIN_SCH_FILE IS NULL AND  VWREPEC.COD_SITUATION <> 17) OR (VWREPEC.COD_FIN_SCH_FILE IS NOT NULL AND VWREPEC.COD_SITUATION = 17)
AND (([VWREPEC].[COD_EC] IN (SELECT
		*
	FROM @EC)
AND (SELECT
		COUNT(*)
	FROM @EC)
> 0)
OR (SELECT
		COUNT(*)
	FROM @EC)
= 0)
AND (([VWREPEC].[COD_BANK] IN (SELECT
		*
	FROM @BANK)
AND (SELECT
		COUNT(*)
	FROM @BANK)
> 0)
OR (SELECT
		COUNT(*)
	FROM @BANK)
= 0)
AND (([VWREPEC].[COD_AFFILIATOR] IN (SELECT
		*
	FROM @CODAFF)
AND (SELECT
		COUNT(*)
	FROM @CODAFF)
> 0)
OR (SELECT
		COUNT(*)
	FROM @CODAFF)
= 0)
AND (([VWREPEC].[COD_SITUATION] = @CODSITUATION)
OR (@CODSITUATION IS NULL)
AND (([VWREPEC].[COD_TYPE_ACCOUNT] IN (SELECT
		[CODE]
	FROM @ACCOUNT)
AND (SELECT
		COUNT(*)
	FROM @ACCOUNT)
> 0))
OR (SELECT
		COUNT(*)
	FROM @ACCOUNT)
= 0)
GROUP BY [VWREPEC].[CODE]
		,[VWREPEC].[COD_EC]
		,[VWREPEC].[EC]
		,[VWREPEC].[CPF_CNPJ_EC]
		,[VWREPEC].[CODE_BANK]
		,[BANK_DETAILS_EC].[AGENCY]
		,[BANK_DETAILS_EC].[ACCOUNT]
		,[VWREPEC].[BANK]
		,[VWREPEC].[ACCOUNT]
		,[VWREPEC].[AGENCY]
		,[VWREPEC].[DIGIT_ACCOUNT]
		,[VWREPEC].[ACCOUNT_TYPE]
		,[VWREPEC].[COD_TYPE_ACCOUNT]
		,[BANK_DETAILS_EC].[COD_BK_EC]
		,(CASE
			 WHEN [VWREPEC].[COD_SITUATION] = 27 AND
				 [BLOCKED_FINANCE] <> 1 THEN 'AGUARDANDO SPLIT'
			 WHEN [VWREPEC].[COD_SITUATION] = 17 AND
				 [BLOCKED_FINANCE] <> 1 THEN 'CONFIRMACAO'
			 WHEN [VWREPEC].[COD_SITUATION] = 4 AND
				 [BLOCKED_FINANCE] <> 1 THEN 'PAGAMENTO'
			 WHEN [BLOCKED_FINANCE] = 1 THEN 'AGENDA SUSPENSA'
		 END)
		,[VWREPEC].[COD_AFFILIATOR]
		,[VWREPEC].[COD_SITUATION]
		,[VWREPEC].[TYPE_ESTAB]
		,[VWREPEC].[BANK]
		,[VWREPEC].[NAME_AFFILIATOR]
		,[VWREPEC].[OPERATION_CODE]
		,[VWREPEC].[CREATED_AT]
		,[VWREPEC].[IS_ASSIGNMENT]
		,[VWREPEC].[ASSIGNMENT_IDENTIFICATION];


-- SELECT * FROM #TEMP_CERC;  
-- SELECT * FROM #TEMP_FIN;  

UPDATE [#TEMP_FIN]
SET [PLOT_VALUE_PAYMENT] = ([TMP_FIN].[PLOT_VALUE_PAYMENT] - COALESCE((SELECT
		SUM([TMP].[GROSS_TOTAL_VALUE])
	FROM [#TEMP_CERC] AS [TMP]
	WHERE [TMP].[COD_EC] = [TMP_FIN].[COD_EC]
	AND [TMP].[PAYMENT_SITUATION] = [TMP_FIN].[PAYMENT_SITUATION])
, 0))
FROM [#TEMP_FIN] [TMP_FIN];

UPDATE [CERC_FIN]
SET [PLOT_VALUE_PAYMENT] = [CERC_FIN].[PLOT_VALUE_PAYMENT] + ([EC_FIN].[PLOT_VALUE_PAYMENT] / (SELECT
			COUNT(*)
		FROM [#TEMP_CERC] AS [TMP_CERC]
		WHERE [TMP_CERC].[COD_EC] = [CERC_FIN].[COD_EC])
	)
   ,[WAS_PRORATED] = 1
FROM [#TEMP_CERC] [CERC_FIN]
JOIN [#TEMP_FIN] [EC_FIN]
	ON [EC_FIN].[COD_EC] = [CERC_FIN].[COD_EC]
WHERE [EC_FIN].[PLOT_VALUE_PAYMENT] < 0;


WITH CTE
AS
(SELECT
		[DATE]
	   ,[IDENTIFIER]
	   ,[PLOT_VALUE_PAYMENT]
	   ,[CODE_BANK]
	   ,[AGENCY]
	   ,CONCAT([ACCOUNT], '-', [DIGIT_ACCOUNT]) AS [ACCOUNT]
	   ,[CPF_CNPJ]
	   ,[NAME]
	   ,[ACCOUNT_EC]
	   ,[COD_AFFILIATOR]
	   ,[COD_EC]
	   ,[DIGIT_ACCOUNT]
	   ,[COD_BK_EC]
	   ,[FILE_CODE]
	   ,[WAS_PRORATED]
	   ,[PAYMENT_SITUATION]
	   ,[TYPE_ESTAB]
	   ,[BANK_NAME]
	   ,[ACCOUNT_TYPE]
	   ,[AFF_NAME]
	   ,[OPERATION]
	   ,[CREATED_AT]
	   ,IsLocked
	   ,[IS_ASSIGNMENT]
	   ,[ASSIGNMENT_IDENTIFICATION]
	FROM [#TEMP_CERC]
	UNION ALL
	SELECT
		[DATE]
	   ,[IDENTIFIER]
	   ,[PLOT_VALUE_PAYMENT]
	   ,[CODE_BANK]
	   ,[AGENCY]
	   ,[ACCOUNT]
	   ,[CPF_CNPJ]
	   ,[NAME]
	   ,[ACCOUNT_EC]
	   ,[COD_AFFILIATOR]
	   ,[COD_EC]
	   ,[DIGIT_ACCOUNT]
	   ,[COD_BK_EC]
	   ,[FILE_CODE]
	   ,[WAS_PRORATED]
	   ,[PAYMENT_SITUATION]
	   ,[TYPE_ESTAB]
	   ,[BANK_NAME]
	   ,[ACCOUNT_TYPE]
	   ,[AFF_NAME]
	   ,[OPERATION]
	   ,[CREATED_AT]
	   ,IsLocked
	   ,[IS_ASSIGNMENT]
	   ,[ASSIGNMENT_IDENTIFICATION]
	FROM [#TEMP_FIN])
SELECT
	[DATE]
   ,[NAME]
   ,[COD_EC]
   ,[CPF_CNPJ]
   ,[TYPE_ESTAB]
   ,[CODE_BANK]
   ,[BANK_NAME]
   ,[AGENCY]
   ,[ACCOUNT]
   ,[ACCOUNT_TYPE]
   ,[PLOT_VALUE_PAYMENT]
   ,[PAYMENT_SITUATION]
   ,[OPERATION]
   ,[AFF_NAME]
   ,[CREATED_AT]
   ,IsLocked
   ,[IS_ASSIGNMENT]
   ,[ASSIGNMENT_IDENTIFICATION]
FROM [CTE]
WHERE (([PLOT_VALUE_PAYMENT] > @MINVALUE)
OR (@MINVALUE IS NULL))
AND ((@CHECK_BLOCK = 1
AND [PAYMENT_SITUATION] = 'AGENDA SUSPENSA')
OR (@CHECK_CONFIRM = 1
AND [PAYMENT_SITUATION] = 'CONFIRMACAO')
OR (@CHECK_PAYMENT = 1
AND [PAYMENT_SITUATION] = 'PAGAMENTO')
OR (@CHECK_SPLIT = 1
AND [PAYMENT_SITUATION] = 'AGUARDANDO SPLIT'))
AND ((@ONLY_ASSIGNMENT = 1
AND [IS_ASSIGNMENT] = 1)
OR (@ONLY_ASSIGNMENT = 0));

END;
GO
PRINT N'Altering [dbo].[SP_FINANCE_CERC]...';


GO

     
ALTER PROCEDURE [dbo].[SP_FINANCE_CERC]  
    /*----------------------------------------------------------------------------------------  
    Procedure Name: [[SP_FINANCE_CERC]]  
    Project.......: TKPP  
    ------------------------------------------------------------------------------------------  
    Author                  VERSION   Date                        Description  
    ------------------------------------------------------------------------------------------  
 Lucas Aguiar   v1    2019-07-22     creation  
    ------------------------------------------------------------------------------------------*/  
  
AS  
  
BEGIN
SELECT
	[VW_REP_RELEASES_CERC].COMP_NAME
   ,[VW_REP_RELEASES_CERC].COMP_CPF_CNPJ
   ,[VW_REP_RELEASES_CERC].COD_EC
   ,[VW_REP_RELEASES_CERC].CODE
   ,[VW_REP_RELEASES_CERC].EC_NAME
   ,[VW_REP_RELEASES_CERC].EC
   ,[VW_REP_RELEASES_CERC].CPF_CNPJ_EC
   ,[VW_REP_RELEASES_CERC].COD_COMP
   ,[VW_REP_RELEASES_CERC].TYPE_ESTAB
   ,[VW_REP_RELEASES_CERC].ACCOUNT_TYPE
   ,[VW_REP_RELEASES_CERC].COD_TYPE_ACCOUNT
   ,SUM(PLOT_VALUE_PAYMENT) AS PLOT_VALUE_PAYMENT
   ,[VW_REP_RELEASES_CERC].COD_BANK
   ,[VW_REP_RELEASES_CERC].CODE_BANK
   ,[VW_REP_RELEASES_CERC].ISPB
   ,[VW_REP_RELEASES_CERC].BANK
   ,[VW_REP_RELEASES_CERC].AGENCY
   ,[VW_REP_RELEASES_CERC].DIGIT_AGENCY
   ,[VW_REP_RELEASES_CERC].ACCOUNT
   ,[VW_REP_RELEASES_CERC].DIGIT_ACCOUNT
   ,[VW_REP_RELEASES_CERC].[START_DATE]
   ,[VW_REP_RELEASES_CERC].END_DATE
   ,[VW_REP_RELEASES_CERC].[PERCENTAGE]
   ,[VW_REP_RELEASES_CERC].BRAND
   ,[VW_REP_RELEASES_CERC].COD_BRAND
   ,[VW_REP_RELEASES_CERC].[GROUP]
   ,[VW_REP_RELEASES_CERC].[ADDRESS]
   ,[VW_REP_RELEASES_CERC].NUMBER
   ,[VW_REP_RELEASES_CERC].COMPLEMENT
   ,[VW_REP_RELEASES_CERC].COD_ADDRESS
   ,[VW_REP_RELEASES_CERC].NEIGHBORHOOD
   ,[VW_REP_RELEASES_CERC].CITY
   ,[VW_REP_RELEASES_CERC].[STATE]
   ,[VW_REP_RELEASES_CERC].IS_SPOT
   ,[VW_REP_RELEASES_CERC].IS_SPOT
   ,[VW_REP_RELEASES_CERC].PREVISION_PAY_DATE
   ,[VW_REP_RELEASES_CERC].[TYPE_TRANSACTION]
   ,[VW_REP_RELEASES_CERC].COD_TTYPE
   ,[VW_REP_RELEASES_CERC].CEP
   ,[VW_REP_RELEASES_CERC].REG_IDENTIFIER

FROM [VW_REP_RELEASES_CERC]
WHERE PLOT_VALUE_PAYMENT > 0
GROUP BY [VW_REP_RELEASES_CERC].COMP_NAME
		,[VW_REP_RELEASES_CERC].COMP_CPF_CNPJ
		,[VW_REP_RELEASES_CERC].COD_EC
		,[VW_REP_RELEASES_CERC].CODE
		,[VW_REP_RELEASES_CERC].EC_NAME
		,[VW_REP_RELEASES_CERC].EC
		,[VW_REP_RELEASES_CERC].CPF_CNPJ_EC
		,[VW_REP_RELEASES_CERC].COD_COMP
		,[VW_REP_RELEASES_CERC].TYPE_ESTAB
		,[VW_REP_RELEASES_CERC].ACCOUNT_TYPE
		,[VW_REP_RELEASES_CERC].COD_TYPE_ACCOUNT
		,[VW_REP_RELEASES_CERC].COD_BANK
		,[VW_REP_RELEASES_CERC].CODE_BANK
		,[VW_REP_RELEASES_CERC].ISPB
		,[VW_REP_RELEASES_CERC].BANK
		,[VW_REP_RELEASES_CERC].AGENCY
		,[VW_REP_RELEASES_CERC].DIGIT_AGENCY
		,[VW_REP_RELEASES_CERC].ACCOUNT
		,[VW_REP_RELEASES_CERC].DIGIT_ACCOUNT
		,[VW_REP_RELEASES_CERC].[START_DATE]
		,[VW_REP_RELEASES_CERC].END_DATE
		,[VW_REP_RELEASES_CERC].[PERCENTAGE]
		,[VW_REP_RELEASES_CERC].BRAND
		,[VW_REP_RELEASES_CERC].COD_BRAND
		,[VW_REP_RELEASES_CERC].[GROUP]
		,[VW_REP_RELEASES_CERC].[ADDRESS]
		,[VW_REP_RELEASES_CERC].NUMBER
		,[VW_REP_RELEASES_CERC].COMPLEMENT
		,[VW_REP_RELEASES_CERC].COD_ADDRESS
		,[VW_REP_RELEASES_CERC].NEIGHBORHOOD
		,[VW_REP_RELEASES_CERC].CITY
		,[VW_REP_RELEASES_CERC].[STATE]
		,[VW_REP_RELEASES_CERC].IS_SPOT
		,[VW_REP_RELEASES_CERC].PREVISION_PAY_DATE
		,[VW_REP_RELEASES_CERC].[TYPE_TRANSACTION]
		,[VW_REP_RELEASES_CERC].COD_TTYPE
		,[VW_REP_RELEASES_CERC].CEP
		,[VW_REP_RELEASES_CERC].REG_IDENTIFIER
END
GO
PRINT N'Altering [dbo].[SP_FINANCE_SCHEDULE_GENERATE_PAYMENT]...';


GO

  
ALTER PROCEDURE [DBO].[SP_FINANCE_SCHEDULE_GENERATE_PAYMENT]      
     
/*************************************************************************************************************
----------------------------------------------------------------------------------------                   
PROCEDURE NAME: [SP_FINANCE_SCHEDULE_GENERATE_AWAITING_PAYMENT]                   
PROJECT.......: TKPP                   
------------------------------------------------------------------------------------------                   
AUTHOR                          VERSION   DATE                         DESCRIPTION                   
------------------------------------------------------------------------------------------                   
LUIZ AQUINO                        V1              05/11/2018           CREATION               
LUCAS AGUIAR                       V2              28/02/2019           CHANGE      ADD PAYMENT DATE          
Luiz Aquino                        v3              04/04/2019           Search title by cod file        
Elir Ribeiro                       v4              26/06/2019         add parametros             
Luiz Aquino                        v5              08/07/2019          bank is_cerc          
Caike Uch?a Almeida                v6              12/12/2019        add COD_ASS_CNAB na protocols      
Lucas Aguiar           Alteração na divisão de valores    
------------------------------------------------------------------------------------------    
*************************************************************************************************************/    
      
(
	@LINES_FILE [FIN_SCH_GEN_PAY_FILE_TP] READONLY, 
	@CODUSER    INT, 
	@PAYDATE    DATETIME, 
	@TYPEBANK   INT)
AS
BEGIN
    DECLARE @PROTID INT;
    DECLARE @QTDTITLES INT;
    DECLARE @CODFILE INT;
    DECLARE @SEARCH_DATE DATETIME;

    BEGIN
SELECT
	SUM([VW_REP_RELEASES_EC].[PLOT_VALUE_PAYMENT]) AS [AMOUNT]
   ,[VW_REP_RELEASES_EC].[COD_EC]
   ,[LINES_FILE].[CODE_FILE]
   ,[LINES_FILE].[DATE]
   ,[FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE]
   ,[FINANCE_SCHEDULE_FILE].[COD_BK_EC]
   ,0 AS [IS_CERC] INTO [#AVAILABLE_ECS]
FROM @LINES_FILE AS [LINES_FILE]
JOIN [FINANCE_SCHEDULE_FILE](NOLOCK)
	ON [FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE] = [LINES_FILE].[CODE_FILE]
JOIN [VW_REP_RELEASES_EC]
	ON [VW_REP_RELEASES_EC].[COD_FIN_SCH_FILE] = [FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE]
WHERE [VW_REP_RELEASES_EC].[COD_SITUATION] = 17
AND [FINANCE_SCHEDULE_FILE].[TYPE_BANK] = @TYPEBANK
GROUP BY [VW_REP_RELEASES_EC].[COD_EC]
		,[LINES_FILE].[CODE_FILE]
		,[LINES_FILE].[DATE]
		,[FINANCE_SCHEDULE_FILE].[COD_BK_EC]
		,[FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE]
HAVING SUM([VW_REP_RELEASES_EC].[PLOT_VALUE_PAYMENT]) > 0;

INSERT INTO [#AVAILABLE_ECS] ([AMOUNT],
[COD_EC],
[CODE_FILE],
[DATE],
[COD_FIN_SCH_FILE],
[COD_BK_EC],
[IS_CERC])
	SELECT
		SUM([VW_PAYMENT_DIARY_CERC_PENDING].[CERC_VALUE]) AS [AMOUNT]
	   ,[VW_PAYMENT_DIARY_CERC_PENDING].[COD_EC]
	   ,[LINES_FILE].[CODE_FILE]
	   ,[LINES_FILE].[DATE]
	   ,[FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE]
	   ,[FINANCE_SCHEDULE_FILE].[COD_BK_EC]
	   ,1 AS [IS_CERC]
	FROM @LINES_FILE AS [LINES_FILE]
	JOIN [FINANCE_SCHEDULE_FILE](NOLOCK)
		ON [FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE] = [LINES_FILE].[CODE_FILE]
	JOIN [VW_PAYMENT_DIARY_CERC_PENDING]
		ON [VW_PAYMENT_DIARY_CERC_PENDING].[COD_FIN_SCH_FILE] = [FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE]
	WHERE [FINANCE_SCHEDULE_FILE].[TYPE_BANK] = @TYPEBANK
	GROUP BY [VW_PAYMENT_DIARY_CERC_PENDING].[COD_EC]
			,[LINES_FILE].[CODE_FILE]
			,[LINES_FILE].[DATE]
			,[FINANCE_SCHEDULE_FILE].[COD_BK_EC]
			,[FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE]
	HAVING SUM([VW_PAYMENT_DIARY_CERC_PENDING].[CERC_VALUE]) > 0;

UPDATE [ECS]
SET [ECS].[AMOUNT] = [ECS].[AMOUNT] - ISNULL((SELECT
		SUM([A].[AMOUNT])
	FROM [#AVAILABLE_ECS] AS [A]
	WHERE [A].[IS_CERC] = 1
	AND [A].[COD_EC] = [ECS].[COD_EC])
, 0)
FROM [#AVAILABLE_ECS] [ECS]
WHERE [ECS].[IS_CERC] = 0;

DECLARE @QTY_CERC INT = 0;

SELECT
	@QTY_CERC = COUNT(*)
FROM [#AVAILABLE_ECS] AS [ECS]
WHERE [ECS].[IS_CERC] = 1
GROUP BY [ECS].[COD_BK_EC];

UPDATE [ECS]
SET [ECS].[AMOUNT] = IIF(([ECS].[AMOUNT] + (ISNULL((SELECT
		SUM([A].[AMOUNT])
	FROM [#AVAILABLE_ECS] AS [A]
	WHERE [A].[IS_CERC] = 0
	AND [A].[COD_EC] = [ECS].[COD_EC])
, 0) / @QTY_CERC)) > 0, ([ECS].[AMOUNT] + (ISNULL((SELECT
		SUM([A].[AMOUNT])
	FROM [#AVAILABLE_ECS] AS [A]
	WHERE [A].[IS_CERC] = 0
	AND [A].[COD_EC] = [ECS].[COD_EC])
, 0) / @QTY_CERC)), ([ECS].[AMOUNT]))
FROM [#AVAILABLE_ECS] [ECS]
WHERE [ECS].[IS_CERC] = 1
AND ISNULL((SELECT
		SUM([A].[AMOUNT])
	FROM [#AVAILABLE_ECS] AS [A]
	WHERE [A].[IS_CERC] = 0
	AND [A].[COD_EC] = [ECS].[COD_EC])
, 0) < 0;


IF (SELECT
			COUNT(*)
		FROM [#AVAILABLE_ECS])
	= 0
THROW 61033, 'NONE OF THE PROVIDED ECS ARE PENDING PAYMENTS', 1;
SELECT
	[AECS].[COD_EC] AS [CODEC]
   ,[LINES_FILE].[DATE]
   ,[LINES_FILE].[VALUE]
   ,(NEXT VALUE FOR [SEQ_PROT_PAY]) AS [CODSEQ]
   ,[AECS].[COD_FIN_SCH_FILE]
   ,[AECS].[COD_BK_EC]
   ,[ASSOCIATE_GENERATE_CNAB].[COD_ASS_CNAB] INTO [#LINESFILE]
FROM @LINES_FILE AS [LINES_FILE]
JOIN [#AVAILABLE_ECS] AS [AECS]
	ON [AECS].[CODE_FILE] = [LINES_FILE].[CODE_FILE]
		AND [AECS].[DATE] = [LINES_FILE].[DATE]
		AND [AECS].[AMOUNT] > 0
JOIN [ASSOCIATE_GENERATE_CNAB]
	ON [ASSOCIATE_GENERATE_CNAB].[COD_BANK] = @TYPEBANK
		AND [ASSOCIATE_GENERATE_CNAB].[STANDARD_BANK] = 1
		AND [COD_TYPE_ACCOUNT] = 2
		AND [ASSOCIATE_GENERATE_CNAB].[ACTIVE] = 1;

INSERT INTO [PROTOCOLS] ([PROTOCOL],
[CREATED_AT],
VALUE,
[COD_EC],
[COD_BK_EC],
[COD_USER],
[COD_TYPE_PROT],
[COD_ASS_CNAB])
	SELECT
		[CODSEQ]
	   ,[DATE]
	   ,[VALUE]
	   ,[CODEC]
	   ,[COD_BK_EC]
	   ,@CODUSER
	   ,1
	   ,[COD_ASS_CNAB]
	FROM [#LINESFILE];

SET @PROTID = @@identity;

UPDATE [TRANSACTION_TITLES]
SET [COD_PAY_PROT] = [PROTOCOLS].[COD_PAY_PROT]
   ,[COD_SITUATION] = 8
   ,[PAYMENT_DATE] = [LINES_FILE].[DATE]
   ,[MODIFY_DATE] = GETDATE()
FROM [TRANSACTION_TITLES]
INNER JOIN [#LINESFILE] [LINES_FILE]
	ON [LINES_FILE].[CODEC] IS NOT NULL
	AND [LINES_FILE].[CODEC] = [TRANSACTION_TITLES].[COD_EC]
	AND [TRANSACTION_TITLES].[COD_FIN_SCH_FILE] = [LINES_FILE].[COD_FIN_SCH_FILE]
INNER JOIN [PROTOCOLS](NOLOCK)
	ON [PROTOCOLS].[PROTOCOL] = [LINES_FILE].[CODSEQ]
WHERE [TRANSACTION_TITLES].[COD_SITUATION] = 17;

UPDATE [RELEASE_ADJUSTMENTS]
SET [COD_PAY_PROT] = [PROTOCOLS].[COD_PAY_PROT]
   ,[COD_SITUATION] = 8
FROM [RELEASE_ADJUSTMENTS]
INNER JOIN [#LINESFILE] [LINES_FILE]
	ON [LINES_FILE].[CODEC] IS NOT NULL
	AND [LINES_FILE].[CODEC] = [RELEASE_ADJUSTMENTS].[COD_EC]
	AND [RELEASE_ADJUSTMENTS].[COD_FIN_SCH_FILE] = [LINES_FILE].[COD_FIN_SCH_FILE]
INNER JOIN [PROTOCOLS](NOLOCK)
	ON [PROTOCOLS].[PROTOCOL] = [LINES_FILE].[CODSEQ]
WHERE [RELEASE_ADJUSTMENTS].[COD_SITUATION] = 17;

UPDATE [TARIFF_EC]
SET [COD_PAY_PROT] = [PROTOCOLS].[COD_PAY_PROT]
   ,[COD_SITUATION] = 8
   ,[MODIFY_DATE] = GETDATE()
FROM [TARIFF_EC]
INNER JOIN [#LINESFILE] [LINES_FILE]
	ON [LINES_FILE].[CODEC] IS NOT NULL
	AND [LINES_FILE].[CODEC] = [TARIFF_EC].[COD_EC]
	AND [TARIFF_EC].[COD_FIN_SCH_FILE] = [LINES_FILE].[COD_FIN_SCH_FILE]
INNER JOIN [PROTOCOLS](NOLOCK)
	ON [PROTOCOLS].[PROTOCOL] = [LINES_FILE].[CODSEQ]
WHERE [TARIFF_EC].[COD_SITUATION] = 17;

UPDATE [TITLE_LOCK_PAYMENT_DETAILS]
SET [COD_SITUATION] = 8
   ,[COD_PAY_PROT] = [PROTOCOLS].[COD_PAY_PROT]
FROM [TITLE_LOCK_PAYMENT_DETAILS]
INNER JOIN [#LINESFILE] [LINES_FILE]
	ON [TITLE_LOCK_PAYMENT_DETAILS].[COD_FIN_SCH_FILE] = [LINES_FILE].[COD_FIN_SCH_FILE]
INNER JOIN [PROTOCOLS](NOLOCK)
	ON [PROTOCOLS].[PROTOCOL] = [LINES_FILE].[CODSEQ]
WHERE [LINES_FILE].[CODEC] IS NOT NULL;


UPDATE [TRANSACTION_TITLES]
SET [TRANSACTION_TITLES].[COD_SITUATION] = 8
FROM [TITLE_LOCK_PAYMENT_DETAILS]
JOIN [TRANSACTION_TITLES]
	ON [TRANSACTION_TITLES].[COD_TITLE] = [TITLE_LOCK_PAYMENT_DETAILS].[COD_TITLE]
INNER JOIN [#LINESFILE] [LINES_FILE]
	ON [TITLE_LOCK_PAYMENT_DETAILS].[COD_FIN_SCH_FILE] = [LINES_FILE].[COD_FIN_SCH_FILE]
INNER JOIN [PROTOCOLS](NOLOCK)
	ON [PROTOCOLS].[PROTOCOL] = [LINES_FILE].[CODSEQ]
WHERE [LINES_FILE].[CODEC] IS NOT NULL;

UPDATE [FINANCE_SCHEDULE_FILE]
SET [COD_SITUATION] = 8
FROM [FINANCE_SCHEDULE_FILE]
JOIN [#AVAILABLE_ECS]
	ON [#AVAILABLE_ECS].[COD_FIN_SCH_FILE] = [FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE];
END;
END;
GO
PRINT N'Altering [dbo].[SP_REG_REPORT_TRANSACTIONS_PRCS]...';


GO

ALTER PROCEDURE [DBO].[SP_REG_REPORT_TRANSACTIONS_PRCS]                        

/*****************************************************************************************************************
----------------------------------------------------------------------------------------                        
Procedure Name: [SP_REG_REPORT_TRANSACTIONS_EXP]                        
Project.......: TKPP                        
------------------------------------------------------------------------------------------                        
Author                          VERSION        Date                            Description                        
------------------------------------------------------------------------------------------                        
LUCAS AGUIAR     V1    16/01/2019        Creation                
LUCAS AGUIAR  V2    23-04-2019  ROTINA SPLIT                     
------------------------------------------------------------------------------------------
*****************************************************************************************************************/                       
                       
AS
BEGIN
    DECLARE @COUNT INT= 0;




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
   ,[VW_REPORT_TRANSACTIONS_PRCS].[PAYMENT_LINK_TRACKING] INTO [#TB_REPORT_TRANSACTIONS_PRCS_INSERT]
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
[CUSTOMER_EMAIL],
[CUSTOMER_IDENTIFICATION],
[PAYMENT_LINK_TRACKING])
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
   ,[VW_REPORT_TRANSACTIONS_PRCS].[SITUATION] INTO [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
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
PRINT N'Altering [dbo].[SP_FD_DATA_EC]...';


GO

ALTER PROCEDURE SP_FD_DATA_EC        
/*----------------------------------------------------------------------------------------                  
Project.......: TKPP                  
Procedure Name: [SP_FD_DATA_EC]        
------------------------------------------------------------------------------------------                  
Author              VERSION        Date   Description                  
------------------------------------------------------------------------------------------                  
Kennedy Alef  V1   2018-07-27  Creation                  
Elir Ribeiro  V2   2018-11-07  Changed                      
Lucas Aguiar  V3   2019-04-22  Add split                  
Lucas Aguiar  V4   2019-07-01  rotina de travar agenda do ec                  
Luiz Aquino   V5   2019-07-03  Is_Cerc                  
Elir Ribeiro  V6   2019-10-01  changed Limit transaction monthy                    
Caike Uchoa   V7   2019-10-03  add case split pelo afiliador                  
Luiz Aquino   V8   2019-10-16  Add reten��o de agenda                  
Lucas Aguiar  V9   2019-10-28  Conta Cess�o                  
Marcus Gall   V10   2019-11-11  Add FK with BRANCH BUSINESS                  
Marcus Gall   V11   2019-12-06  Add field HAS_CREDENTIALS                  
Elir Ribeiro  V12   2020-01-08  trazendo dados meet consumer                  
Elir Ribeiro  V13   2020-01-15  ajustando procedure         
Marcus Gall   V14   2020-01-22  Add Translate service        
------------------------------------------------------------------------------------------*/                  
(                  
    @COD_EC INT                  
)                  
AS BEGIN
  
      
        
 DECLARE @CodSpotService INT
  
      
        
 DECLARE @COD_SPLIT_SERVICE INT;
  
      
        
 DECLARE @COD_BLOCK_SITUATION INT;
  
      
        
 DECLARE @COD_CUSTOMERINSTALLMENT INT;
  
      
        
 DECLARE @CodSchRetention INT;
  
      
        
 DECLARE @COD_TRANSLATE_SERVICE INT;

SELECT
	@CodSpotService = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE CODE = '1';

SELECT
	@COD_SPLIT_SERVICE = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE [NAME] = 'SPLIT';

SELECT
	@COD_BLOCK_SITUATION = COD_SITUATION
FROM SITUATION
WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';

SELECT
	@COD_CUSTOMERINSTALLMENT = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE NAME = 'PARCELADOCLIENTE';

SELECT
	@CodSchRetention = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE [NAME] = 'SCHEDULEDRETENTION';

SELECT
	@COD_TRANSLATE_SERVICE = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE [NAME] = 'TRANSLATE';

SELECT
	BRANCH_EC.[NAME]
   ,BRANCH_EC.TRADING_NAME
   ,COMMERCIAL_ESTABLISHMENT.CODE AS CODE_EC
   ,BRANCH_EC.CPF_CNPJ
   ,BRANCH_EC.DOCUMENT
   ,BRANCH_EC.BIRTHDATE
   ,COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT
   ,COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY
   ,COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY
   ,BRANCH_EC.EMAIL
   ,BRANCH_EC.STATE_REGISTRATION
   ,BRANCH_EC.MUNICIPAL_REGISTRATION
   ,BRANCH_EC.NOTE AS NOTE
   ,TYPE_ESTAB.CODE AS TYPE_ESTAB_CODE
   ,SEGMENTS.COD_SEG AS SEGMENT
   ,BRANCH_EC.ACTIVE
   ,ADDRESS_BRANCH.[ADDRESS]
   ,ADDRESS_BRANCH.NUMBER AS NUMBER_ADDRESS
   ,ADDRESS_BRANCH.COMPLEMENT
   ,ADDRESS_BRANCH.CEP
   ,ADDRESS_BRANCH.REFERENCE_POINT
   ,NEIGHBORHOOD.COD_NEIGH
   ,NEIGHBORHOOD.[NAME] AS NEIGHBORHOOD
   ,CITY.COD_CITY
   ,CITY.[NAME] AS CITY
   ,[STATE].COD_STATE
   ,[STATE].[NAME] AS [STATE]
   ,COUNTRY.COD_COUNTRY
   ,COUNTRY.[NAME] AS COUNTRY
   ,BANKS.COD_BANK AS BANK_INSIDECODE
   ,BANKS.[NAME] AS BANK
   ,BANK_DETAILS_EC.DIGIT_AGENCY
   ,BANK_DETAILS_EC.AGENCY
   ,BANK_DETAILS_EC.DIGIT_ACCOUNT
   ,BANK_DETAILS_EC.ACCOUNT
   ,ACCOUNT_TYPE.COD_TYPE_ACCOUNT AS ACCOUNT_TYPE_INSIDECODE
   ,ACCOUNT_TYPE.[NAME] AS ACCOUNT_TYPE
   ,SALES_REPRESENTATIVE.COD_SALES_REP
   ,COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE
   ,BRANCH_EC.COD_SEX
   ,BRANCH_EC.COD_BRANCH AS COD_BRANCH
   ,BANK_DETAILS_EC.AGENCY AS AGENCY
   ,BANK_DETAILS_EC.DIGIT_AGENCY AS AGENCY_DIGIT
   ,BANK_DETAILS_EC.ACCOUNT AS ACCOUNT
   ,BANK_DETAILS_EC.DIGIT_ACCOUNT AS DIGIT_ACCOUNT
   ,BANK_DETAILS_EC.COD_OPER_BANK
   ,TYPE_RECEIPT.COD_TYPE_REC
   ,TYPE_RECEIPT.CODE AS TYPE_RECEIPT
   ,CARDS_TOBRANCH.CARDNUMBER
   ,CARDS_TOBRANCH.ACCOUNTID AS 'ACCOUNTID'
   ,CARDS_TOBRANCH.COD_CARD_BRANCH AS 'COD_CARD_BRANCH'
   ,COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE AS 'TRANSACTION_ONLINE'
   ,COMMERCIAL_ESTABLISHMENT.SPOT_TAX
   ,CASE
		WHEN COMMERCIAL_ESTABLISHMENT.COD_SITUATION = @COD_BLOCK_SITUATION THEN 1
		ELSE 0
	END [FINANCE_BLOCK]
   ,COMMERCIAL_ESTABLISHMENT.NOTE_FINANCE_SCHEDULE
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodSpotService
				AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
				AND SERVICES_AVAILABLE.ACTIVE = 1)
			> 0 THEN 1
		ELSE 0
	END [HAS_SPOT]
   ,COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_SPLIT_SERVICE
				AND SERVICES_AVAILABLE.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
				AND SERVICES_AVAILABLE.ACTIVE = 1
				AND SERVICES_AVAILABLE.COD_OPT_SERV = 4
				AND SERVICES_AVAILABLE.COD_EC IS NULL)
			> 0 THEN 1
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_SPLIT_SERVICE
				AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
				AND SERVICES_AVAILABLE.ACTIVE = 1)
			> 0 THEN 1
		ELSE 0
	END [HAS_SPLIT]
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_CUSTOMERINSTALLMENT
				AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
				AND SERVICES_AVAILABLE.ACTIVE = 1)
			> 0 THEN 1
		ELSE 0
	END [HAS_CUSTOMERINSTALLMENT]
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodSchRetention
				AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
				AND SERVICES_AVAILABLE.ACTIVE = 1)
			> 0 THEN 1
		ELSE 0
	END [HAS_SCHRETENTION]
   ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
   ,COMMERCIAL_ESTABLISHMENT.RISK_REASON
   ,COMMERCIAL_ESTABLISHMENT.IS_PROVIDER
   ,BANK_DETAILS_EC.IS_ASSIGNMENT
   ,BANK_DETAILS_EC.ASSIGNMENT_NAME
   ,BANK_DETAILS_EC.ASSIGNMENT_IDENTIFICATION
   ,BRANCH_BUSINESS.COD_BRANCH_BUSINESS AS BRANCH_BUSINESS
   ,COMMERCIAL_ESTABLISHMENT.HAS_CREDENTIALS
   ,MEET_COSTUMER.CNPJ [ACCEPTANCE]
   ,ISNULL(MEET_COSTUMER.QTY_EMPLOYEES, 0) QTY_EMPLOYEES
   ,ISNULL(MEET_COSTUMER.AVERAGE_BILLING, 0) AVERAGE_BILLING
   ,MEET_COSTUMER.URL_SITE
   ,MEET_COSTUMER.FACEBOOK
   ,MEET_COSTUMER.INSTAGRAM
   ,MEET_COSTUMER.STREET
   ,MEET_COSTUMER.COMPLEMENT [COMPLEMENTO]
   ,MEET_COSTUMER.ANOTHER_INFO
   ,MEET_COSTUMER.NUMBER
   ,MEET_COSTUMER.NEIGHBORHOOD AS MEET_NEIGH
   ,MEET_COSTUMER.CITY AS MEET_CITY
   ,MEET_COSTUMER.STATES
   ,MEET_COSTUMER.REFERENCEPOINT
   ,MEET_COSTUMER.ZIPCODE
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_TRANSLATE_SERVICE
				AND SERVICES_AVAILABLE.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
				AND SERVICES_AVAILABLE.ACTIVE = 1)
			> 0 THEN 1
		ELSE 0
	END [HAS_TRANSLATE]
FROM COMMERCIAL_ESTABLISHMENT
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
INNER JOIN TYPE_ESTAB
	ON TYPE_ESTAB.COD_TYPE_ESTAB = BRANCH_EC.COD_TYPE_ESTAB
INNER JOIN ADDRESS_BRANCH
	ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
		AND ADDRESS_BRANCH.ACTIVE = 1
INNER JOIN NEIGHBORHOOD
	ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
INNER JOIN CITY
	ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
INNER JOIN [STATE]
	ON [STATE].COD_STATE = CITY.COD_STATE
INNER JOIN COUNTRY
	ON [STATE].COD_COUNTRY = COUNTRY.COD_COUNTRY
INNER JOIN TYPE_RECEIPT
	ON TYPE_RECEIPT.COD_TYPE_REC = BRANCH_EC.COD_TYPE_REC
LEFT JOIN BANK_DETAILS_EC
	ON BANK_DETAILS_EC.COD_BRANCH = BRANCH_EC.COD_BRANCH
		AND BANK_DETAILS_EC.ACTIVE = 1
		AND BANK_DETAILS_EC.IS_CERC = 0
LEFT JOIN BANKS
	ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK
LEFT JOIN ACCOUNT_TYPE
	ON ACCOUNT_TYPE.COD_TYPE_ACCOUNT = BANK_DETAILS_EC.COD_TYPE_ACCOUNT
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
INNER JOIN SALES_REPRESENTATIVE
	ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
LEFT JOIN CARDS_TOBRANCH
	ON CARDS_TOBRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
INNER JOIN BRANCH_BUSINESS
	ON BRANCH_BUSINESS.COD_BRANCH_BUSINESS = COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS
LEFT JOIN MEET_COSTUMER
	ON MEET_COSTUMER.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC
AND (CARDS_TOBRANCH.COD_SITUATION = 15
OR CARDS_TOBRANCH.COD_SITUATION IS NULL)

END;
GO
PRINT N'Altering [dbo].[SP_UP_TRANSACTION]...';


GO
ALTER PROCEDURE [dbo].[SP_UP_TRANSACTION]                               
/*----------------------------------------------------------------------------------------                               
Procedure Name: [SP_UP_TRANSACTION]                               
Project.......: TKPP                               
------------------------------------------------------------------------------------------                               
Author   Version  Date   Description                               
------------------------------------------------------------------------------------------                               
Kennedy Alef V1   27/07/2018  Creation                      
Lucas Aguiar V2   17-04-2019  rotina de aw. titles e cancelamento                       
Elir Ribeiro V3   12-08-2019  Changed situation Blocked                
Elir Ribeiro V4   20-08-2019  Changed situation AWAITING PAYMENT         
Marcus Gall  V5   01-02-2020  Changes CONFIRMED, New CANCELED after RELEASED        
Elir Ribeiro v6   27-02-2020  Changes Cod_user    
------------------------------------------------------------------------------------------*/                               
(                               
@CODE_TRAN VARCHAR(200),                               
@SITUATION VARCHAR(100),                               
@DESCRIPTION VARCHAR(200) = NULL,                               
@CURRENCY VARCHAR(100),                               
@CODE_ERROR VARCHAR(100) = NULL,                            
@TRAN_ID INT   = NULL,          
@LOGICAL_NUMBER_ACQ VARCHAR(100) = NULL ,          
@CARD_HOLDER_NAME VARCHAR(100) = NULL,       
@COD_USER INT = NULL                      
)                               
AS                               
DECLARE @QTY INT=0;
        
                              
DECLARE @CONT INT;
        
                               
DECLARE @SIT VARCHAR(100);
        
                               
DECLARE @BRANCH INT;
        
                               
                              
IF @TRAN_ID IS NULL        
 BEGIN
SELECT
	@CONT = COD_TRAN
   ,@SIT = SITUATION.NAME
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN SITUATION
	ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
WHERE CODE = @CODE_TRAN;
END;
ELSE
BEGIN
SELECT
	@CONT = COD_TRAN
   ,@SIT = SITUATION.NAME
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN SITUATION
	ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
WHERE COD_TRAN = @TRAN_ID;
END;

IF @CONT < 1
	OR @CONT IS NULL
THROW 60002, '601', 1;
UPDATE PROCESS_BG_STATUS
SET STATUS_PROCESSED = 0
   ,MODIFY_DATE = GETDATE()
FROM PROCESS_BG_STATUS WITH (NOLOCK)
WHERE CODE = @CONT
AND COD_TYPE_PROCESS_BG = 1;

-- @SITUATION CONDITIONALS        
IF @SITUATION = 'APPROVED'
BEGIN
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,1
	   ,'100 - APROVADA';

UPDATE [TRANSACTION]
SET COD_SITUATION = 1
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = ISNULL(dbo.[ISNULLOREMPTY](@DESCRIPTION), '100 - APROVADA')
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 100)
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
   ,LOGICAL_NUMBER_ACQ = @LOGICAL_NUMBER_ACQ
   ,CARD_HOLDER_NAME = @CARD_HOLDER_NAME
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;
END;
ELSE
IF @SITUATION = 'CONFIRMED'
BEGIN
IF @SIT = @SITUATION
THROW 60002, '603', 1;
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,3
	   ,@DESCRIPTION;

--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
UPDATE [TRANSACTION]
SET COD_SITUATION = 3
   ,MODIFY_DATE = GETDATE()
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 200)
   ,COMMENT = ISNULL(dbo.[ISNULLOREMPTY](@DESCRIPTION), '200 - CONFIRMADA')
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;
--EXECUTE [SP_GEN_TITLES_TRANS] @COD_TRAN = @CODE_TRAN, @TRAN_ID= @TRAN_ID;        
END;
ELSE
IF @SITUATION = 'AWAITING TITLES'
BEGIN
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,22
	   ,'206 - AGUARDANDO TITULOS';

--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
UPDATE [TRANSACTION]
SET COD_SITUATION = 22
   ,MODIFY_DATE = GETDATE()
   ,CODE_ERROR = 206
   ,COMMENT = '206 - AGUARDANDO TITULOS'
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;
END;
ELSE
IF @SITUATION = 'PROCESSING UNDONE'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,21
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 21
   ,MODIFY_DATE = GETDATE()
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;
END;
ELSE
IF @SITUATION = 'UNDONE FAIL'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,23
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 23
   ,MODIFY_DATE = GETDATE()
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;
END;
ELSE
IF @SITUATION = 'DENIED ACQUIRER'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                          
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,2
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 2
   ,MODIFY_DATE = GETDATE()
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = @CODE_ERROR
   ,CARD_HOLDER_NAME = @CARD_HOLDER_NAME
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;
END;
ELSE
IF @SITUATION = 'BLOCKED'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,14
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 14
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = @CODE_ERROR
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;
IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 14
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES WITH (NOLOCK)
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;

UPDATE [TRANSACTION_TITLES_COST]
SET COD_SITUATION = 14
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)
INNER JOIN [TRANSACTION_TITLES]
	ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;
END;
ELSE
IF @SITUATION = 'AWAITING PAYMENT'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,4
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 3
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = @CODE_ERROR
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 4
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES WITH (NOLOCK)
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;

UPDATE [TRANSACTION_TITLES_COST]
SET COD_SITUATION = 4
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)
INNER JOIN [TRANSACTION_TITLES]
	ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;
END;
ELSE
IF @SITUATION = 'UNDONE'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,10
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 10
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = @CODE_ERROR
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES WITH (NOLOCK)
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;

UPDATE [TRANSACTION_TITLES_COST]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)
INNER JOIN [TRANSACTION_TITLES]
	ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;
END;
ELSE
IF @SITUATION = 'FAILED'
BEGIN
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                               
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,7
	   ,'';

UPDATE [TRANSACTION]
SET COD_SITUATION = 7
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 700)
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT

IF @@rowcount < 1
THROW 60002, '002', 1;
END;
ELSE
IF @SITUATION = 'CANCELED'
BEGIN
IF @SIT = @SITUATION
THROW 60002, '703', 1;
IF @SIT = 'AWAITING TITLES'
BEGIN
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,6
	   ,@DESCRIPTION;

UPDATE [TRANSACTION]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 300)
   ,COD_USER = @COD_USER
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES WITH (NOLOCK)
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;

UPDATE [TRANSACTION_TITLES_COST]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)
INNER JOIN [TRANSACTION_TITLES] WITH (NOLOCK)
	ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;
END;
ELSE
BEGIN
SELECT
	@QTY = COUNT(*)
FROM TRANSACTION_TITLES WITH (NOLOCK)
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT
AND TRANSACTION_TITLES.COD_SITUATION NOT IN (4, 20);

IF @QTY > 0
THROW 60002, '704', 1;
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)
	SELECT
		@CONT
	   ,@CODE_TRAN
	   ,6
	   ,@DESCRIPTION;

UPDATE [TRANSACTION]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 300)
   ,COD_USER = @COD_USER
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES WITH (NOLOCK)
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;

UPDATE [TRANSACTION_TITLES_COST]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)
INNER JOIN [TRANSACTION_TITLES] WITH (NOLOCK)
	ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT;
END;
END;
ELSE
IF @SITUATION = 'CANCELED PARTIAL'
BEGIN
IF @SIT = 'CANCELED'
THROW 60002, '703', 1;

INSERT INTO RELEASE_ADJUSTMENTS (COD_EC, VALUE, PREVISION_PAY_DATE, COD_TYPEJUST, COMMENT, COD_SITUATION, COD_USER, COD_REQ, COD_BRANCH, COD_TRAN, COD_TITLE_REF)
	SELECT
		CAST([TRANSACTION].COD_EC AS INT) AS COD_EC
	   ,(CAST(
		(
		(
		(TRANSACTION_TITLES.AMOUNT * (1 - (TRANSACTION_TITLES.TAX_INITIAL / 100))) *
		CASE
			WHEN TRANSACTION_TITLES.ANTICIP_PERCENT IS NULL THEN 1
			ELSE 1 - (((TRANSACTION_TITLES.ANTICIP_PERCENT / 30) *
				COALESCE(CASE
					WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
					ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
				END, (TRANSACTION_TITLES.PLOT * 30) - 1)
				) / 100)
		END
		)
		- (CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END)
		) AS DECIMAL(22, 6)) * -1) AS value
	   ,[TRANSACTION_TITLES].PREVISION_PAY_DATE AS PREVISION_PAY_DATE
	   ,CAST(2 AS INT) AS COD_TYPEJUST
	   ,CAST('CANCELAMENTO PARCIAL, NSU: ' + [TRANSACTION].CODE AS VARCHAR(200)) AS COMMENT
	   ,CAST(4 AS INT) AS COD_SITUATION
	   ,NULL AS CODUSER
	   ,NULL AS COD_REQ
	   ,CAST([COMMERCIAL_ESTABLISHMENT].COD_EC AS INT) AS COD_BRANCH
	   ,CAST([TRANSACTION].COD_TRAN AS INT) AS COD_TRAN
	   ,CAST([TRANSACTION_TITLES].COD_TITLE AS INT) AS COD_TITLE_REF
	FROM [TRANSACTION_TITLES] AS [TRANSACTION_TITLES]
	INNER JOIN [TRANSACTION]
		ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
	INNER JOIN [COMMERCIAL_ESTABLISHMENT]
		ON [COMMERCIAL_ESTABLISHMENT].COD_EC = [TRANSACTION].COD_EC
	WHERE [TRANSACTION].COD_TRAN = @CONT
	AND [TRANSACTION_TITLES].COD_SITUATION = 8;

IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE [TRANSACTION]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 300)
   ,COD_USER = @COD_USER
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [TRANSACTION].COD_TRAN = @CONT;

IF @@rowcount < 1
THROW 60002, '002', 1;

UPDATE [TRANSACTION_TITLES]
SET TRANSACTION_TITLES.COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES] WITH (NOLOCK)
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT
AND [TRANSACTION_TITLES].COD_SITUATION = 4;

UPDATE [TRANSACTION_TITLES_COST]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)
INNER JOIN [TRANSACTION_TITLES] WITH (NOLOCK)
	ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
WHERE [TRANSACTION].COD_TRAN = @CONT
AND [TRANSACTION_TITLES_COST].COD_SITUATION = 4;
END;
GO
PRINT N'Altering [dbo].[SP_UP_EC_PWDONLINE]...';


GO
ALTER PROCEDURE [dbo].[SP_UP_EC_PWDONLINE]
/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_UP_EC_PWDONLINE]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Elir Ribeiro      V1		29/10/2018        Creation         
------------------------------------------------------------------------------------------*/       
@COD_EC INT,
@PWD_ONLINE VARCHAR(200) 
AS
UPDATE COMMERCIAL_ESTABLISHMENT
SET PWD_ONLINE = @PWD_ONLINE
WHERE COD_EC = @COD_EC
GO
PRINT N'Altering [dbo].[SP_DETAILS_FINANCE_CALENDAR_TITLES]...';


GO

ALTER PROCEDURE [dbo].[SP_DETAILS_FINANCE_CALENDAR_TITLES]      
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_DETAILS_FINANCE_CALENDAR_TITLES]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Kennedy Alef     V1    27/07/2018      Creation      
------------------------------------------------------------------------------------------*/      
(      
    @PAYMENT_DATA DATETIME,      
    @EC INT,  
    @COD_SITUATION INT = NULL    
)      
AS      
BEGIN

SELECT
	*
FROM VW_DETAILS_PAYMENT_TRAN_TITLES
WHERE PREVISION_PAY_DATE <= @PAYMENT_DATA
AND COD_EC = @EC
AND COD_SITUATION = ISNULL(@COD_SITUATION, 4)
AND PLOT_VALUE_PAYMENT > 0;

END;
GO
PRINT N'Altering [dbo].[SP_EQUIPMENT_INITIALIZATION]...';


GO
ALTER PROCEDURE [dbo].[SP_EQUIPMENT_INITIALIZATION]
/*----------------------------------------------------------------------------------------
Procedure Name: [SP_EQUIPMENT_INITIALIZATION]
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date                            Description
------------------------------------------------------------------------------------------
Kennedy Alef					V1				27/07/2018						Creation
------------------------------------------------------------------------------------------*/
(
  @SERIAL   VARCHAR(200),
  @CPF_CNPJ VARCHAR(100)
)
AS
DECLARE @ACTIVE INT;
DECLARE @TERMINALID INT;
DECLARE @SELECTED_DOCUMENT VARCHAR(100)
DECLARE @COD_BRANCH INT
DECLARE @FIREBASE_NAME VARCHAR(100)
BEGIN

SELECT
	@ACTIVE = ACTIVE
   ,@TERMINALID = COD_EQUIP
   ,@SELECTED_DOCUMENT = CPF_CNPJ
   ,@COD_BRANCH = COD_BRANCH
   ,@FIREBASE_NAME = FIREBASE_NAME
FROM VW_EQUIPMENT_EC
WHERE SERIAL = @SERIAL

IF @ACTIVE IS NULL
THROW 60002, '006', 1;

IF @ACTIVE = 0
THROW 60002, '003', 1;

IF @CPF_CNPJ <> @SELECTED_DOCUMENT
THROW 60002, '102', 1;

UPDATE EQUIPMENT
SET INITIALIZATION_DATE = GETDATE()
WHERE COD_EQUIP = @TERMINALID
IF @@rowcount < 1
THROW 60002, '002', 1;

SELECT
	@TERMINALID AS TERMINAL_ID
   ,@COD_BRANCH AS COD_BRANCH
   ,@FIREBASE_NAME AS FIREBASE_NAME
END
GO
PRINT N'Altering [dbo].[SP_FIND_CELER_PAY_PENDING]...';


GO
ALTER PROCEDURE SP_FIND_CELER_PAY_PENDING
    /*----------------------------------------------------------------------------------------     
    Procedure Name: [[SP_LS_FINANCE_SCHEDULE]]     
    Project.......: TKPP     
    ------------------------------------------------------------------------------------------     
    Author           VERSION        Date         Description     
    ------------------------------------------------------------------------------------------     
    Luiz Aquino        V1       2019-11-19        Creation  
    ------------------------------------------------------------------------------------------*/    
AS
BEGIN
SELECT
	FINANCE_SCHEDULE_FILE.[FILE_NAME]
   ,FINANCE_SCHEDULE_FILE.TRACEID
FROM CELER_PAY_REQUEST_HISTORY
JOIN FINANCE_SCHEDULE_FILE
	ON FINANCE_SCHEDULE_FILE.COD_FIN_SCH_FILE = CELER_PAY_REQUEST_HISTORY.COD_FIN_SCH_FILE
JOIN BANKS
	ON BANKS.COD_BANK = FINANCE_SCHEDULE_FILE.TYPE_BANK
		AND BANKS.[NAME] = 'CELER DIGITAL'
WHERE CELER_PAY_REQUEST_HISTORY.PROCESSED = 0
AND ((SELECT
		COUNT(*) [Awaiting]
	FROM TRANSACTION_TITLES
	WHERE COD_FIN_SCH_FILE = FINANCE_SCHEDULE_FILE.COD_FIN_SCH_FILE
	AND COD_SITUATION = 17)
> 0
OR (SELECT
		COUNT(*) [Awaiting]
	FROM RELEASE_ADJUSTMENTS
	WHERE COD_FIN_SCH_FILE = FINANCE_SCHEDULE_FILE.COD_FIN_SCH_FILE
	AND [VALUE] > 0
	AND COD_SITUATION = 17)
> 0)
GROUP BY FINANCE_SCHEDULE_FILE.[FILE_NAME]
		,FINANCE_SCHEDULE_FILE.TRACEID
END
GO
PRINT N'Altering [dbo].[SP_GENERATE_LOW_TITLES_PAYMENT_EC]...';


GO

ALTER PROCEDURE [dbo].[SP_GENERATE_LOW_TITLES_PAYMENT_EC]   
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_GENERATE_LOW_TITLES_PAYMENT_EC]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date                         Description  
------------------------------------------------------------------------------------------  
Kennedy Alef         V1          27/07/2018         Creation  
Luiz Aquino          v2          03/07/2019         Check bank is_cerc
------------------------------------------------------------------------------------------*/   
(    
    @TYPE INT,    
    @TITLES NVARCHAR(4000),    
    @COD_EC INT,     
    @COD_USER INT    
)    
AS     
BEGIN
     
    DECLARE @VALUE DECIMAL(22,6)
      
    DECLARE @PROTID INT
     
    DECLARE @FK_KEY INT
    
    
    --CURSOR TITLES     
    DECLARE DBCURSOR_TITLES CURSOR FOR
SELECT
	[TRANSACTION_TITLES].COD_TITLE
FROM [TRANSACTION]
INNER JOIN [TRANSACTION_TITLES]
	ON TRANSACTION_TITLES.COD_TRAN = [TRANSACTION].COD_TRAN
WHERE [TRANSACTION].CODE + CAST([TRANSACTION_TITLES].PLOT AS VARCHAR(10)) IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))

--CURSOR RELEASE     
DECLARE DBCURSOR_RELEASE CURSOR FOR SELECT
	RELEASE_ADJUSTMENTS.COD_REL_ADJ
FROM RELEASE_ADJUSTMENTS
WHERE RELEASE_ADJUSTMENTS.COD_REL_ADJ IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))

--CURSOR TARIFF     
DECLARE DBCURSOR_TARIFF CURSOR FOR SELECT
	TARIFF_EC.COD_TARIFF_EC
FROM TARIFF_EC
WHERE TARIFF_EC.COD_TTARIFF IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))

SELECT
	@VALUE = SUM(CAST(((TRANSACTION_TITLES.AMOUNT - ((TRANSACTION_TITLES.ACQ_TAX * TRANSACTION_TITLES.AMOUNT) / 100))) AS DECIMAL(22, 2)))
FROM [TRANSACTION]
INNER JOIN [TRANSACTION_TITLES]
	ON TRANSACTION_TITLES.COD_TRAN = [TRANSACTION].COD_TRAN
WHERE [TRANSACTION].CODE + CAST([TRANSACTION_TITLES].PLOT AS VARCHAR(10)) IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))

IF @VALUE IS NULL
	OR @VALUE <= 0
THROW 61033, 'INVALID PAYMENT TO THIS COMMERCIAL ESTABLISHMENT', 1

INSERT INTO PROTOCOLS (PROTOCOL, VALUE, COD_EC, COD_BK_EC, COD_USER, COD_TYPE_PROT)
	VALUES ((NEXT VALUE FOR [SEQ_PROT_PAY]), @VALUE, @COD_EC, (SELECT COD_BK_EC FROM BANK_DETAILS_EC WHERE COD_EC = @COD_EC AND ACTIVE = 1 AND IS_CERC = 0), @COD_USER, 1)

SET @PROTID = @@identity;
 

    IF(@TYPE = 1)    
    BEGIN
UPDATE [TRANSACTION_TITLES]
SET [TRANSACTION_TITLES].COD_SITUATION = 8
   ,COD_PAY_PROT = @PROTID
FROM [TRANSACTION_TITLES]
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
WHERE [TRANSACTION].CODE + CAST([TRANSACTION_TITLES].PLOT AS VARCHAR(10)) IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))
OPEN DBCURSOR_TITLES
FETCH NEXT FROM DBCURSOR_TITLES INTO @FK_KEY

WHILE @@fetch_status = 0
BEGIN
INSERT INTO LOW_TITLES_PAYMENT_LOG (CREATED_AT, COD_SITUATION, COD_PAY_PROT, COD_USER, COD_TITLE)
	VALUES (GETDATE(), 8, @PROTID, @COD_USER, @FK_KEY)
FETCH NEXT FROM DBCURSOR_TITLES INTO @FK_KEY
END
CLOSE DBCURSOR_TITLES
DEALLOCATE DBCURSOR_TITLES
END
ELSE
IF (@TYPE = 2)
BEGIN
UPDATE RELEASE_ADJUSTMENTS
SET COD_SITUATION = 8
   ,COD_PAY_PROT = @PROTID
WHERE COD_REL_ADJ IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))

OPEN DBCURSOR_RELEASE
FETCH NEXT FROM DBCURSOR_RELEASE INTO @FK_KEY

WHILE @@fetch_status = 0
BEGIN
INSERT INTO LOW_TITLES_PAYMENT_LOG (CREATED_AT, COD_SITUATION, COD_PAY_PROT, COD_USER, COD_REL_ADJ)
	VALUES (GETDATE(), 8, @PROTID, @COD_USER, @FK_KEY)
FETCH NEXT FROM DBCURSOR_RELEASE INTO @FK_KEY
END

CLOSE DBCURSOR_RELEASE
DEALLOCATE DBCURSOR_RELEASE
END
ELSE
IF (@TYPE = 3)
BEGIN

UPDATE TARIFF_EC
SET COD_SITUATION = 8
   ,COD_PAY_PROT = @PROTID
WHERE COD_TTARIFF IN (SELECT
		*
	FROM dbo.splitstring(@TITLES))

OPEN DBCURSOR_TARIFF
FETCH NEXT FROM DBCURSOR_TARIFF INTO @FK_KEY

WHILE @@fetch_status = 0
BEGIN
INSERT INTO LOW_TITLES_PAYMENT_LOG (CREATED_AT, COD_SITUATION, COD_PAY_PROT, COD_USER, COD_TARIFF_EC)
	VALUES (GETDATE(), 8, @PROTID, @COD_USER, @FK_KEY)
FETCH NEXT FROM DBCURSOR_TARIFF INTO @FK_KEY
END

CLOSE DBCURSOR_TARIFF
DEALLOCATE DBCURSOR_TARIFF
END
END;
GO
PRINT N'Altering [dbo].[SP_REG_TRANSACTION]...';


GO

ALTER PROCEDURE [dbo].[SP_REG_TRANSACTION]                                  
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
  @CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL
)                                  
                                  
                        
AS                       
DECLARE @COD_TRAN INT = 0;
  
    
      
          
            
            
BEGIN

--SELECT @CODETR = CAST(NEXT VALUE FOR [SEQ_TRANCODE] AS varchar) +                                   
--     CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112)+                                  
--     REPLACE(CONVERT(CHAR(8), CURRENT_TIMESTAMP, 108), ':', '')           



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
[TYPE],
[COD_COMP],
COD_AFFILIATOR,
POSWEB,
COD_SOURCE_TRAN,
COD_EC,
CREDITOR_DOCUMENT,
[DESCRIPTION],
TRACKING_TRANSACTION,
BRAZILIAN_DATE,
CARD_HOLDER_NAME,
CARD_HOLDER_DOC,
LOGICAL_NUMBER_ACQ,
CUSTOMER_EMAIL,
CUSTOMER_IDENTIFICATION)
	VALUES (@CODETR, @AMOUNT, @PAN, @BRAND, @CODASS_DEPTO_TERMINAL, @COD_TTYPE, @PLOTS, @CODTAX_ASS, 5, @TERMINALDATE, @COD_ASS_TR_ACQ, @CODPROD_ACQ, @TYPE, @COD_COMP, @COD_AFFILIATOR, @POSWEB, @SOURCE_TRAN, @EC_TRANS, @CREDITOR_DOC, @DESCRIPTION, @TRACKING_DESCRIPTION, dbo.FN_FUS_UTF(GETDATE()), @HOLDER_NAME, @HOLDER_DOC, @LOGICAL_NUMBER, @CUSTOMER_EMAIL, @CUSTOMER_IDENTIFICATION);



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
PRINT N'Altering [dbo].[SP_REG_TRANSACTION_DENIED]...';


GO
      
          
ALTER PROCEDURE [dbo].[SP_REG_TRANSACTION_DENIED]              
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
 @CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL        
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
[TYPE],
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
CUSTOMER_IDENTIFICATION)
	VALUES (@CODETR, @AMOUNT, @PAN, @BRAND, @CODASS_DEPTO_TERMINAL, @COD_TTYPE, @PLOTS, @CODTAX_ASS, 9, @CODAC, @COMMENT, @TERMINALDATE, @TYPE, @COD_COMP, @COD_AFFILIATOR, @POSWEB, @SOURCE_TRAN, @COD_EC, @CREDITOR_DOC, dbo.FN_FUS_UTF(GETDATE()), @HOLDER_NAME, @HOLDER_DOC, @LOGICAL_NUMBER, @CUSTOMER_EMAIL, @CUSTOMER_IDENTIFICATION);


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
PRINT N'Altering [dbo].[SP_DATA_TRAN_TITLE]...';


GO
ALTER PROCEDURE [DBO].[SP_DATA_TRAN_TITLE]   

/********************************************************************************************
----------------------------------------------------------------------------------------   
    Procedure Name: [SP_DATA_TRAN_TITLE]  Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author              VERSION        Date         Description   
------------------------------------------------------------------------------------------   
    Kennedy Alef        V1          27/07/2018      Creation   
    Luiz Aquino         V2          08/07/2019      bank is_cerc  
 Marcus Gall   V3   03/01/2020  Add AmountNoRate and RatePlot  
 Marcus Gall   V4   07/02/2020  Alter UNION RELEASE_ADJUSTMENTS   
    Lucas Aguiar	    v5		25/03/2020	  add cod ec
------------------------------------------------------------------------------------------
********************************************************************************************/
   
(
	@CODE_TRAN        VARCHAR(100), 
	@SHOW_ADJUSTMENTS INT          = 0, 
	@COD_EC           INT          = NULL)
AS
BEGIN
    DECLARE @QUERY_ NVARCHAR(MAX)= '';
    BEGIN
SET @QUERY_ = CONCAT(@QUERY_, '   
		  SELECT * FROM (  
		  SELECT  
		   TRANSACTION_TITLES.COD_TITLE AS CODE  
		   ,CAST(TRANSACTION_TITLES.AMOUNT AS DECIMAL(22, 6)) AS AMOUNT  
		   ,TRANSACTION_TITLES.PLOT  
		   ,CAST((  
		    dbo.[FNC_ANT_VALUE_LIQ_DAYS]  
		    (  
		    TRANSACTION_TITLES.AMOUNT,  
		    TRANSACTION_TITLES.TAX_INITIAL,  
		    TRANSACTION_TITLES.PLOT,  
		    TRANSACTION_TITLES.ANTICIP_PERCENT,  
		    (  
		    CASE  
		     WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)  
		     ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP  
		    END  
		    )  
		    )  
		    ) - (CASE  
		     WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE  
		     ELSE 0  
		    END) AS DECIMAL(22, 6))  
		   AS [PLOT_VALUE_PAYMENT]  
		   ,CAST(TRANSACTION_TITLES.PREVISION_PAY_DATE AS DATE) AS [PREVISION_PAY_DATE]  
		   ,TRADUCTION_SITUATION.SITUATION_TR AS SITUATION  
		   ,TRANSACTION_TITLES.ANTICIPATED  
		   ,TYPE_TRANSACTION_TITTLE.CODE AS TITTLE_TYPE  
		   ,COMMERCIAL_ESTABLISHMENT.NAME AS MERCHANT  
		   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS DOC_MERCHANT  
		   ,TR_TITTLE.SITUATION_TR AS SITUATION_TITTLE  
		   ,ISNULL(PROTOCOLS.PROTOCOL, '''') AS PROTOCOL  
		   , dbo.[FNC_ANT_VALUE_LIQ_DAYS](  
		    TRANSACTION_TITLES.AMOUNT,  
		    TRANSACTION_TITLES.TAX_INITIAL,  
		    TRANSACTION_TITLES.PLOT,  
		    TRANSACTION_TITLES.ANTICIP_PERCENT,  
		    (  
		    CASE  
		     WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)  
		     ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP  
		    END  
		    )  
		   ) AS [PLOT_VALUE_NO_RATE]  
		   , (  
		    CASE  
		     WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE  
		     ELSE 0  
		    END  
		   ) AS [PLOT_RATE]  
		  FROM TRANSACTION_TITLES  
		  INNER JOIN [TRANSACTION] WITH (NOLOCK)  
		   ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN  
		  INNER JOIN COMMERCIAL_ESTABLISHMENT  
		   ON COMMERCIAL_ESTABLISHMENT.COD_EC = TRANSACTION_TITLES.COD_EC  
		  INNER JOIN BRANCH_EC  
		   ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
		  INNER JOIN COMPANY  
		   ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP  
		  INNER JOIN SITUATION  
		   ON SITUATION.COD_SITUATION = TRANSACTION_TITLES.COD_SITUATION  
		  INNER JOIN BANK_DETAILS_EC  
		   ON BANK_DETAILS_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
		    AND BANK_DETAILS_EC.ACTIVE = 1  
		    AND BANK_DETAILS_EC.IS_CERC = 0  
		  LEFT JOIN BANKS  
		   ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK  
		  LEFT JOIN TYPE_TRANSACTION_TITTLE  
		   ON TYPE_TRANSACTION_TITTLE.COD_TYPE_TRAN_TITLE = TRANSACTION_TITLES.COD_TYPE_TRAN_TITLE  
		  INNER JOIN TRADUCTION_SITUATION  
		   ON TRADUCTION_SITUATION.COD_SITUATION = SITUATION.COD_SITUATION  
		  LEFT JOIN SITUATION ST_TITTLE  
		   ON ST_TITTLE.COD_SITUATION = TRANSACTION_TITLES.COD_SITUATION  
		  LEFT JOIN TRADUCTION_SITUATION TR_TITTLE  
		   ON TR_TITTLE.COD_SITUATION = ST_TITTLE.COD_SITUATION  
		  LEFT JOIN PROTOCOLS  
		   ON PROTOCOLS.COD_PAY_PROT = TRANSACTION_TITLES.COD_PAY_PROT  
		  WHERE [TRANSACTION].CODE=''' + @CODE_TRAN + '''');

	   IF @COD_EC IS NOT NULL
SET @QUERY_ = CONCAT(@QUERY_, '  and TRANSACTION_TITLES.COD_EC = @COD_EC');

IF @SHOW_ADJUSTMENTS = 1
BEGIN
SET @QUERY_ = CONCAT(@QUERY_, '  
								    UNION  
								    
								    SELECT  
								     RELEASE_ADJUSTMENTS.COD_REL_ADJ AS CODE  
								       , CAST(TRANSACTION_TITLES.AMOUNT AS DECIMAL(22, 6)) AS AMOUNT  
								       , ROW_NUMBER() OVER (ORDER BY RELEASE_ADJUSTMENTS.COD_REL_ADJ ASC) AS PLOT  
								       , RELEASE_ADJUSTMENTS.[VALUE] AS [PLOT_VALUE_PAYMENT]  
								       , RELEASE_ADJUSTMENTS.PREVISION_PAY_DATE  
								       , TRADUCTION_SITUATION.SITUATION_TR AS SITUATION  
								       , TRANSACTION_TITLES.ANTICIPATED  
								       , ''TRANSACTION'' AS TITTLE_TYPE  
								       , COMMERCIAL_ESTABLISHMENT.[NAME] AS EC  
								       , COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS DOC_MERCHANT  
								       , TR_TITTLE.SITUATION_TR AS SITUATION_TITTLE  
								       , ISNULL(PROTOCOLS.PROTOCOL, '''') AS PROTOCOL  
								       , 0    
								       , 0   
								    FROM [TRANSACTION] WITH (NOLOCK)  
								    INNER JOIN RELEASE_ADJUSTMENTS ON RELEASE_ADJUSTMENTS.COD_TRAN = [TRANSACTION].COD_TRAN  
								    INNER JOIN [TRANSACTION_TITLES] ON [TRANSACTION_TITLES].COD_TITLE = RELEASE_ADJUSTMENTS.COD_TITLE_REF  
								    INNER JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = RELEASE_ADJUSTMENTS.COD_EC  
								    LEFT JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = RELEASE_ADJUSTMENTS.COD_PAY_PROT  
								    INNER JOIN SITUATION ON SITUATION.COD_SITUATION = RELEASE_ADJUSTMENTS.COD_SITUATION  
								    INNER JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = SITUATION.COD_SITUATION  
								    INNER JOIN SITUATION ST_TITTLE ON ST_TITTLE.COD_SITUATION = RELEASE_ADJUSTMENTS.COD_SITUATION  
								    INNER JOIN TRADUCTION_SITUATION TR_TITTLE ON TR_TITTLE.COD_SITUATION = ST_TITTLE.COD_SITUATION  
								    WHERE [TRANSACTION].CODE =''' + @CODE_TRAN + '''');

		  IF @COD_EC IS NOT NULL
SET @QUERY_ = CONCAT(@QUERY_, '  and TRANSACTION_TITLES.COD_EC = @COD_EC');

END;

SET @QUERY_ = CONCAT(@QUERY_, ' ) AS RESULTADO ORDER BY RESULTADO.PLOT, RESULTADO.[PLOT_VALUE_PAYMENT] DESC');
--SELECT @QUERY_;  

EXEC [sp_executesql] @QUERY_
					,N'   
			 @CODE_TRAN VARCHAR(100),
			 @SHOW_ADJUSTMENTS INT,
			 @COD_EC INT = NULL'
					,@CODE_TRAN = @CODE_TRAN
					,@SHOW_ADJUSTMENTS = @SHOW_ADJUSTMENTS
					,@COD_EC = @COD_EC;

END;
END;
GO
PRINT N'Altering [dbo].[SP_REG_CONTACT_AFL]...';


GO

ALTER PROCEDURE [dbo].[SP_REG_CONTACT_AFL]
/*----------------------------------------------------------------------------------------
Procedure Name: SP_REG_CONTACT_AFL
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date                            Description
------------------------------------------------------------------------------------------
Gian Luca Dalle Cort			V1			   31/07/2018					   CREATION
------------------------------------------------------------------------------------------*/
(
	@COD_AFFILIATOR INT,
	@COD_USER_CAD INT,
	@NUMBER VARCHAR(30), 
	@COD_TP_CONT INT,
	@COD_OPER INT,
	@COD_USER_ALT INT,
	@DDI VARCHAR(20),
	@DDD VARCHAR(20)
)
AS
BEGIN

INSERT INTO AFFILIATOR_CONTACT (COD_AFFILIATOR,
CREATED_AT,
COD_USER_CAD,
NUMBER,
COD_TP_CONT,
COD_OPER,
MODIFY_DATE,
COD_USER_ALT,
DDI,
DDD,
ACTIVE)
	VALUES (@COD_AFFILIATOR, current_timestamp, @COD_USER_CAD, @NUMBER, @COD_TP_CONT, @COD_OPER, current_timestamp, @COD_USER_ALT, @DDI, @DDD, 1);

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER AFFILIATOR_CONTACT ', 1;

END;
GO
PRINT N'Altering [dbo].[SP_REPORT_ACQUIRER]...';


GO
ALTER PROCEDURE [dbo].[SP_REPORT_ACQUIRER]                                                                             
/*----------------------------------------------------------------------------------------                                                                          
Procedure Name: [SP_REPORT_ACQUIRER]                    pu                                                      
Project.......: TKPP                                                                          
------------------------------------------------------------------------------------------                                                                          
Author                          VERSION        Date                            Description                                                                          
------------------------------------------------------------------------------------------                                                                          
Elir Ribeiro                     v1           2019-08-30                     procedure to list acquirer                       
Elir Ribeiro                     v2           2019-09-03                     Changed procedure                    
Elir Ribeiro                     v3           2019-0--04                     Changed                 
------------------------------------------------------------------------------------------*/                                                                          
(                                                                              
    @CODCOMP VARCHAR(10),                                                                              
    @INITIAL_DATE DATETIME,                                                                              
    @FINAL_DATE DATETIME,                                                                              
    @BRAND VARCHAR(100) = NULL,                                                                            
    @NAMEACQ  VARCHAR(100) = NULL,                      
    @TRANSACTION_TYPE  VARCHAR(100) = NULL,            
 @QTY INT   = NULL,        
 @QTY_TOTAL INT OUTPUT                  
  )                                                                              
AS                                                        
                                                                              
DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';
    
      
        
             
DECLARE @QUERY_BASIS_COUNT NVARCHAR(MAX) = '';
    
      
        
            
 DECLARE @QUERY_BASIS_PARAMETERS NVARCHAR(MAX) = '';
    
      
        
               
DECLARE @TOTAL_ACQ INT
SET NOCOUNT ON
SET ARITHABORT ON
    
      
        
                        
                            
                                                                                                    
BEGIN

SET @QUERY_BASIS =
'                                                                    
       SELECT                                     
     REPORT_CONSOLIDATED_TRANS_SUB.ACQUIRER ADQUIRENTE,                      
  [REPORT_CONSOLIDATED_TRANS_SUB].NSU AS [NSU INTERNO],                      
  [REPORT_CONSOLIDATED_TRANS_SUB].EXTERNALNSU [NSU EXTERNO],                      
  [REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_RECEIVE_DATE [DATA DE PREVISÃO RECEBIMENTO],                                     
     CAST([dbo].[FN_FUS_UTF]([REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE)AS DATETIME) AS [DATA DA TRANSAÇÃO],                                                                      
     [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TYPE [TIPO TRANSAÇÃO],                        
  [REPORT_CONSOLIDATED_TRANS_SUB].MDR_ACQUIRER [MDR ADQ],                      
  [REPORT_CONSOLIDATED_TRANS_SUB].QUOTA_TOTAL  AS [TOTAL PARCELA],                                    
  [REPORT_CONSOLIDATED_TRANS_SUB].BRAND [BANDEIRA],                      
  [REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED] AS CESSÃO,                   
  CAST([dbo].[FN_FUS_UTF]([REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE)AS DATETIME)  AS [PREVISÃO DE PAGAMENTO EC],                       
  [REPORT_CONSOLIDATED_TRANS_SUB].TO_RECEIVE_ACQ [LIQUIDO EC],                
  [REPORT_CONSOLIDATED_TRANS_SUB].AMOUNT [VALOR BRUTO],                
  [REPORT_CONSOLIDATED_TRANS_SUB].PLOT [PARCELA]                
    FROM [REPORT_CONSOLIDATED_TRANS_SUB] WITH (NOLOCK)                        
   WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_COMP = @CODCOMP                                                                       
   AND CAST([REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_RECEIVE_DATE AS DATETIME) BETWEEN  @INITIAL_DATE  AND @FINAL_DATE                
     AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = 3            
            
   ';

SET @QUERY_BASIS_COUNT =
'                                                            
   SELECT cOUNT(COD_REP_CONSO_TRANS_SUB)                                                             
   FROM [REPORT_CONSOLIDATED_TRANS_SUB]               
   WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_COMP = @CODCOMP                                                                       
   AND CAST([REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_RECEIVE_DATE AS DATETIME) BETWEEN  @INITIAL_DATE  AND @FINAL_DATE                
     AND  [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = 3                      
   '
    
      
        
 ;

SET @QUERY_BASIS_PARAMETERS = ''
    
      
        
                       
IF LEN(@BRAND) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_CONSOLIDATED_TRANS_SUB].[BRAND] = @BRAND ');

IF LEN(@NAMEACQ) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_CONSOLIDATED_TRANS_SUB].[ACQUIRER] = @NAMEACQ ');

IF LEN(@TRANSACTION_TYPE) > 0
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_CONSOLIDATED_TRANS_SUB].[TRANSACTION_TYPE]= @TRANSACTION_TYPE ');


SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '             
GROUP BY REPORT_CONSOLIDATED_TRANS_SUB.ACQUIRER,[REPORT_CONSOLIDATED_TRANS_SUB].NSU,            
  [REPORT_CONSOLIDATED_TRANS_SUB].EXTERNALNSU,[REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_RECEIVE_DATE,             
  [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE,   
  [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TYPE,            
  [REPORT_CONSOLIDATED_TRANS_SUB].MDR_ACQUIRER,  
  [REPORT_CONSOLIDATED_TRANS_SUB].QUOTA_TOTAL,            
  [REPORT_CONSOLIDATED_TRANS_SUB].BRAND,  
  [REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED],   
  [REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE,            
  [REPORT_CONSOLIDATED_TRANS_SUB].TO_RECEIVE_ACQ,   
  [REPORT_CONSOLIDATED_TRANS_SUB].AMOUNT, [REPORT_CONSOLIDATED_TRANS_SUB].PLOT            
  ORDER BY PREVISION_RECEIVE_DATE DESC             
   ');
    
      
        
                      
            
IF @QTY IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, 'OFFSET @QTY ROWS FETCH NEXT @QTY ROWS ONLY;');


--SELECT @QUERY_BASIS            
SET @QTY_TOTAL = @TOTAL_ACQ

SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, @QUERY_BASIS_PARAMETERS);
--SET @QUERY_BASIS_COUNT = CONCAT(@QUERY_BASIS_COUNT, @QUERY_BASIS_PARAMETERS);        

--EXEC sp_executesql @QUERY_BASIS_COUNT      
--      ,N'                                
--    @CODCOMP VARCHAR(10),                                                                              
--    @INITIAL_DATE DATETIME,                                                                              
--    @FINAL_DATE DATETIME,                                                                              
--    @BRAND VARCHAR(50),                                                                            
--    @NAMEACQ  VARCHAR(100),                      
--    @TRANSACTION_TYPE  VARCHAR(10),            
--    @QTY INT,        
-- @QTY_TOTAL int output                              
--       '      
--      ,@CODCOMP = @CODCOMP      
--      ,@INITIAL_DATE = @INITIAL_DATE      
--      ,@FINAL_DATE = @FINAL_DATE      
--      ,@BRAND = @BRAND      
--      ,@NAMEACQ = @NAMEACQ      
--      ,@TRANSACTION_TYPE = @TRANSACTION_TYPE      
--      ,@QTY = @QTY      
--      ,@QTY_TOTAL = @QTY_TOTAL OUTPUT;      



EXEC sp_executesql @QUERY_BASIS
				  ,N'                                
    @CODCOMP VARCHAR(10),                                                                              
    @INITIAL_DATE DATETIME,                                                 
    @FINAL_DATE DATETIME,                                                                              
    @BRAND VARCHAR(50),             
    @NAMEACQ  VARCHAR(100),                      
    @TRANSACTION_TYPE  VARCHAR(10),            
    @QTY INT,        
 @QTY_TOTAL int output                              
       '
				  ,@CODCOMP = @CODCOMP
				  ,@INITIAL_DATE = @INITIAL_DATE
				  ,@FINAL_DATE = @FINAL_DATE
				  ,@BRAND = @BRAND
				  ,@NAMEACQ = @NAMEACQ
				  ,@TRANSACTION_TYPE = @TRANSACTION_TYPE
				  ,@QTY = @QTY
				  ,@QTY_TOTAL = @TOTAL_ACQ OUTPUT





END;
GO
PRINT N'Altering [dbo].[SP_REPORT_CANCELATED]...';


GO
ALTER PROCEDURE [dbo].[SP_REPORT_CANCELATED]                   
/*----------------------------------------------------------------------------------------                   
Procedure Name: [SP_REPORT_CANCELATED]                   
Project.......: TKPP                   
------------------------------------------------------------------------------------------                   
Author                          VERSION        Date                            Description                   
------------------------------------------------------------------------------------------                   
Elir Ribeiro      V1      18/02/2020        Creation                   
------------------------------------------------------------------------------------------*/                   
(                   
 @INITIAL_DATE datetime,                 
 @FINAL_DATE datetime,                 
 @ACQUIRER VARCHAR(100) ,                 
 @BRAND VARCHAR(200) ,                 
  @TRANSACTION_TYPE VARCHAR(100) ,               
 @VALUEINITIAL DECIMAL(22,6) = NULL,                 
 @VALUEFINAL DECIMAL(22,6) =  NULL                 
                 
                 
)                   
AS                   
DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';
                   
BEGIN
SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'))

SET @QUERY_BASIS = '                   
SELECT REPORTS.TRANSACTION_DATE,REPORTS.TRANSACTION_TYPE,AC.NAME,REPORTS.MODIFY_DATE,REPORTS.TRANSACTION_CODE,REPORTS.TRAN_DATA_EXT_VALUE,REPORTS.AMOUNT,REPORTS.TAX,REPORTS.COMMENT,REPORTS.NAME_USER            
FROM REPORT_TRANSACTIONS_EXP REPORTS INNER JOIN ACQUIRER AC                 
ON REPORTS.COD_AC  = AC.COD_AC                 
INNER JOIN [TRANSACTION] TRANS ON TRANS.COD_TRAN = REPORTS.COD_TRAN             
WHERE                 
 REPORTS.SITUATION = ''CANCELADA'' and                  
 CAST([dbo].[FN_FUS_UTF]([REPORTS].MODIFY_DATE) AS DATETIME)                                   
 BETWEEN  ''' + CAST(@INITIAL_DATE AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE AS VARCHAR) + ''' '
               
                   
IF @ACQUIRER IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND AC.NAME = @ACQUIRER ');

IF @BRAND IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND REPORTS.BRAND = @BRAND ');

IF @TRANSACTION_TYPE IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND REPORTS.TRANSACTION_TYPE = @TRANSACTION_TYPE ');

IF @VALUEINITIAL > 0
	AND (@VALUEFINAL >= @VALUEINITIAL)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND REPORTS.AMOUNT BETWEEN @VALUEINITIAL AND @VALUEFINAL ');

SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'ORDER BY [REPORTS].TRANSACTION_DATE DESC ')
EXEC sp_executesql @QUERY_BASIS
				  ,N'                   
@INITIAL_DATE VARCHAR(100),                 
 @FINAL_DATE VARCHAR(100),               
@ACQUIRER VARCHAR(100),                 
 @BRAND VARCHAR(200),                 
 @VALUEINITIAL DECIMAL(22,6),                 
 @VALUEFINAL DECIMAL(22,6),                 
 @TRANSACTION_TYPE VARCHAR(100)                 
                  
 '
				  ,@INITIAL_DATE = @INITIAL_DATE
				  ,@FINAL_DATE = @FINAL_DATE
				  ,@ACQUIRER = @ACQUIRER
				  ,@BRAND = @BRAND
				  ,@VALUEINITIAL = @VALUEINITIAL
				  ,@VALUEFINAL = @VALUEFINAL
				  ,@TRANSACTION_TYPE = @TRANSACTION_TYPE

END;
GO
PRINT N'Altering [dbo].[SP_REPORT_CONSOLIDATED_TRANSACTION_SUB]...';


GO
ALTER PROCEDURE [DBO].[SP_REPORT_CONSOLIDATED_TRANSACTION_SUB]                   
 
/**************************************************************************************************************
----------------------------------------------------------------------------------------                    
 Procedure Name: [SP_REPORT_CONSOLIDATED_TRANSACTION_SUB]                    
 Project.......: TKPP                    
 ------------------------------------------------------------------------------------------                    
 Author                          VERSION        Date                            Description                    
 ------------------------------------------------------------------------------------------                    
 Fernando Henrique F. de O       V1         28/12/2018                          Creation                  
 Fernando Henrique F. de O       V2         07/02/2019                          Changed                      
 Elir Ribeiro                    V3         29/07/2019                          Changed date            
 Caike Uchôa Almeida             V4         16/08/2019                        Inserting columns           
 Caike Uchôa Almeida             V5         11/09/2019                        Inserting column          
 Marcus Gall      V6     27/11/2019  Add Model_POS, Segment, Location_EC  
 Ana Paula Liick    V8   31/01/2020       Add Origem_Trans  
 ------------------------------------------------------------------------------------------
**************************************************************************************************************/
                            
(
	@CODCOMP      VARCHAR(10), 
	@INITIAL_DATE DATETIME, 
	@FINAL_DATE   DATETIME, 
	@EC           VARCHAR(10), 
	@BRANCH       VARCHAR(10), 
	@DEPART       VARCHAR(10), 
	@TERMINAL     VARCHAR(100), 
	@STATE        VARCHAR(100), 
	@CITY         VARCHAR(100), 
	@TYPE_TRAN    VARCHAR(10), 
	@SITUATION    VARCHAR(10), 
	@NSU          VARCHAR(100) = NULL, 
	@NSU_EXT      VARCHAR(100) = NULL, 
	@BRAND        VARCHAR(50)  = NULL, 
	@PAN          VARCHAR(50)  = NULL, 
	@CODAFF       INT          = NULL, 
	@SPLIT        INT          = NULL, 
	@CODACQUIRER  INT          = NULL)
AS
BEGIN
    DECLARE @QUERY_BASIS NVARCHAR(MAX)= '';


    DECLARE @AWAITINGSPLIT INT= NULL;
SET NOCOUNT ON;
SET ARITHABORT ON;


    BEGIN

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
	IIF([REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED] = 1, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE] ,[REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE )  AS PREDICTION_PAY_DATE,     
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
  FROM [REPORT_CONSOLIDATED_TRANS_SUB]                           
  WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_COMP = @CODCOMP                         
                     
    AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = 3                    
                      
    ';

     


	   IF @INITIAL_DATE IS NOT NULL AND @FINAL_DATE IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE BETWEEN @INITIAL_DATE AND @FINAL_DATE  ');

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



IF @CODACQUIRER IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND ACQUIRER = (SELECT [NAME] FROM ACQUIRER WHERE COD_AC = @CODACQUIRER ) ');

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
   @AwaitingSplit INT = NULL    
       
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
					,@AWAITINGSPLIT = @AWAITINGSPLIT;

END;
END;
GO
PRINT N'Altering [dbo].[SP_REPORT_TRANSACTIONS_EXP]...';


GO

ALTER PROCEDURE [DBO].[SP_REPORT_TRANSACTIONS_EXP]                                                    
                                        
 /**********************************************************************************************************************************************
----------------------------------------------------------------------------------------                                                    
 Procedure Name: [SP_REPORT_TRANSACTIONS_EXP]                                                    
 Project.......: TKPP                                                    
 ------------------------------------------------------------------------------------------                                                    
 Author                       VERSION            Date             Description                                                    
 ------------------------------------------------------------------------------------------                                                    
 Fernando Henrique F.          V1            13/12/2018             Creation                                                    
 Kennedy Alef                  V2            16/01/2018             Modify                  
 Lucas Aguiar                  V2            23/04/2019       ROTINA DE SPLIT                 
 Caike Uchôa                   V3            15/08/2019         inserting coluns           
 Marcus Gall                   V4            28/11/2019   Add Model_POS, Segment, Location EC    
 Caike Uchôa                   V5            20/01/2020             ADD CNAE  
  
 ------------------------------------------------------------------------------------------
**********************************************************************************************************************************************/                                                    
                                      
(
	@CODCOMP              VARCHAR(10), 
	@INITIAL_DATE         DATETIME, 
	@FINAL_DATE           DATETIME, 
	@EC                   VARCHAR(10), 
	@BRANCH               VARCHAR(10), 
	@DEPART               VARCHAR(10), 
	@TERMINAL             VARCHAR(100), 
	@STATE                VARCHAR(100), 
	@CITY                 VARCHAR(100), 
	@TYPE_TRAN            VARCHAR(10), 
	@SITUATION            VARCHAR(10), 
	@NSU                  VARCHAR(100)   = NULL, 
	@NSU_EXT              VARCHAR(100)   = NULL, 
	@BRAND                VARCHAR(50)    = NULL, 
	@PAN                  VARCHAR(50)    = NULL, 
	@COD_AFFILIATOR       INT            = NULL, 
	@TRACKING_TRANSACTION VARCHAR(100)   = NULL, 
	@DESCRIPTION          VARCHAR(100)   = NULL, 
	@SPOT_ELEGIBLE        INT            = 0, 
	@COD_ACQ              INT            = NULL, 
	@SOURCE_TRAN          INT            = NULL, 
	@POSWEB               INT            = 0, 
	@SPLIT                INT            = NULL, 
	@INITIAL_VALUE        DECIMAL(22, 6)  = NULL, 
	@FINAL_VALUE          DECIMAL(22, 6)  = NULL, 
	@COD_SALES_REP        INT            = NULL)
AS
BEGIN
    DECLARE @QUERY_BASIS NVARCHAR(MAX)= '';

    DECLARE @TIME_FINAL_DATE TIME;

SET NOCOUNT ON;
SET ARITHABORT ON;


    BEGIN


SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');

--SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                        
--SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                 )                          

SET @FINAL_DATE = DATEADD([MILLISECOND], 999, @FINAL_DATE);



	   IF(@TIME_FINAL_DATE = '00:00:00')
SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'));

SET @QUERY_BASIS = '                    
   SELECT                                        
       [REPORT_TRANSACTIONS_EXP].TRANSACTION_CODE                                        
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
      ,COALESCE([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT_VALUE, '''')   AS TRAN_DATA_EXT_VALUE                          
      ,COALESCE([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT, '''')   AS TRAN_DATA_EXT          
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
   FROM [dbo].[REPORT_TRANSACTIONS_EXP]                                            
   WHERE [REPORT_TRANSACTIONS_EXP].COD_COMP = @CODCOMP                                                                               
    ';


	   IF @INITIAL_DATE IS NOT NULL AND @FINAL_DATE IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND CAST([REPORT_TRANSACTIONS_EXP].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)');

IF @EC IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_EC = @EC ');

IF @BRANCH IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND[REPORT_TRANSACTIONS_EXP].COD_BRANCH =  @BRANCH ');

IF @DEPART IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_DEPTO_BRANCH =  @DEPART ');

IF LEN(@TERMINAL) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND [REPORT_TRANSACTIONS_EXP].SERIAL_EQUIP = @TERMINAL');

IF LEN(@STATE) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND [REPORT_TRANSACTIONS_EXP].STATE_NAME = @STATE ');

IF LEN(@CITY) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].CITY_NAME = @CITY ');

IF LEN(@TYPE_TRAN) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND EXISTS( SELECT tt.CODE FROM TRANSACTION_TYPE tt WHERE tt.COD_TTYPE = @TYPE_TRAN AND [REPORT_TRANSACTIONS_EXP].TRANSACTION_TYPE = tt.CODE )');

IF LEN(@SITUATION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND  EXISTS( SELECT tt.SITUATION_TR FROM [TRADUCTION_SITUATION] tt WHERE tt.COD_SITUATION = @SITUATION AND [REPORT_TRANSACTIONS_EXP].SITUATION = tt.SITUATION_TR )');



IF LEN(@BRAND) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].BRAND = @BRAND ');

IF LEN(@PAN) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].PAN = @PAN ');

IF LEN(@NSU) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRANSACTION_CODE = @NSU ');

IF LEN(@NSU_EXT) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT_VALUE = @NSU_EXT ');
--ELSE                                                    
-- SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,' AND ([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''RCPTTXID'' OR  [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT IS NULL                                   
--                                          OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''AUTO'' OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''NSU'' ) ');                                                   

IF @COD_AFFILIATOR IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_AFFILIATOR =  @COD_AFFILIATOR ');

IF LEN(@TRACKING_TRANSACTION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRACKING_TRANSACTION  = @TRACKING_TRANSACTION ');

IF LEN(@DESCRIPTION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND  [REPORT_TRANSACTIONS_EXP].DESCRIPTION  LIKE  %@DESCRIPTION%');

IF @SPOT_ELEGIBLE = 1
BEGIN
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND  [REPORT_TRANSACTIONS_EXP].PLOTS > 1 AND (SELECT COUNT(*) FROM TRANSACTION_TITLES title JOIN [TRANSACTION] title_tran ON title_tran.COD_TRAN = title.COD_TRAN WHERE [VW_REPORT_TRANSACTIONS].TRANSACTION_CODE    
      
                    
        = title_tran.CODE AND title.PREVISION_PAY_DATE > @FINAL_DATE  ) > 0 AND TRANSACTION_TITLES.COD_SITUATION = 4 ');

	   END;


IF @COD_ACQ IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_AC = @COD_ACQ');

IF @SOURCE_TRAN IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_SOURCE_TRAN = @SOURCE_TRAN');

IF @POSWEB = 1
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].POSWEB = @POSWEB');

IF (@INITIAL_VALUE > 0)
	AND (@FINAL_VALUE >= @INITIAL_VALUE)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].AMOUNT BETWEEN @INITIAL_VALUE AND @FINAL_VALUE');

IF (@SPLIT = 1)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND [REPORT_TRANSACTIONS_EXP].SPLIT = 1');

IF @COD_SALES_REP IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_SALES_REP = @COD_SALES_REP');


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
   @TERMINAL varchar(14),                                                  
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
   @COD_ACQ INT                                       
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
					,@COD_ACQ = @COD_ACQ;

END;
END;
GO
PRINT N'Altering [dbo].[SP_REPORT_TRANSACTIONS_PAGE]...';


GO

ALTER PROCEDURE [DBO].[SP_REPORT_TRANSACTIONS_PAGE]      

/***********************************************************************************************************************************************
----------------------------------------------------------------------------------------                                                      
Procedure Name: [SP_REPORT_TRANSACTIONS_PAGE]                                                      
Project.......: TKPP                                                      
------------------------------------------------------------------------------------------                                                      
Author                          VERSION        Date                            Description                                                      
------------------------------------------------------------------------------------------                                                      
Fernando                               V1    24/01/2019                           Creation                                                      
Lucas Aguiar         v2  26-04-2019     Add split service                 
Elir Ribeiro         v2   24-06-2019         
------------------------------------------------------------------------------------------
***********************************************************************************************************************************************/

(
	@CODCOMP              VARCHAR(10), 
	@INITIAL_DATE         DATETIME, 
	@FINAL_DATE           DATETIME, 
	@EC                   VARCHAR(10), 
	@BRANCH               VARCHAR(10)    = NULL, 
	@DEPART               VARCHAR(10)    = NULL, 
	@TERMINAL             VARCHAR(100), 
	@STATE                VARCHAR(100)   = NULL, 
	@CITY                 VARCHAR(100)   = NULL, 
	@TYPE_TRAN            INT, 
	@SITUATION            VARCHAR(10), 
	@NSU                  VARCHAR(100)   = NULL, 
	@NSU_EXT              VARCHAR(100)   = NULL, 
	@BRAND                VARCHAR(50)    = NULL, 
	@PAN                  VARCHAR(50)    = NULL, 
	@CODAFF               INT            = NULL, 
	@TRACKING_TRANSACTION VARCHAR(100)   = NULL, 
	@DESCRIPTION          VARCHAR(100)   = NULL, 
	@SPOT_ELEGIBLE        INT            = NULL, 
	@COD_ACQ              VARCHAR(10)    = NULL, 
	@SOURCE_TRAN          INT            = NULL, 
	@POSWEB               INT            = 0, 
	@INITIAL_VALUE        DECIMAL(22, 6)  = NULL, 
	@FINAL_VALUE          DECIMAL(22, 6)  = NULL, 
	@QTD_BY_PAGE          INT, 
	@NEXT_PAGE            INT, 
	@SPLIT                INT            = NULL, 
	@COD_SALES_REP        INT            = NULL, 
	@TOTAL_REGS           INT OUTPUT)
AS
BEGIN

    DECLARE @QUERY_BASIS_PARAMETERS NVARCHAR(MAX)= '';
    DECLARE @QUERY_BASIS_SELECT NVARCHAR(MAX)= '';
    DECLARE @QUERY_BASIS_COUNT NVARCHAR(MAX)= '';

    DECLARE @TIME_FINAL_DATE TIME;
    DECLARE @CNT INT;
--DECLARE @PARAMS nvarchar(max);        

SET NOCOUNT ON;
SET ARITHABORT ON;

    BEGIN

SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');

--SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                
--SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                 )                  

SET @FINAL_DATE = DATEADD([MILLISECOND], 999, @FINAL_DATE);


	   IF(@TIME_FINAL_DATE = '00:00:00')
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
    REPORT_TRANSACTIONS.PAYMENT_LINK_TRACKING
   FROM [REPORT_TRANSACTIONS]          
   LEFT JOIN TRANSACTION_SERVICES ON TRANSACTION_SERVICES.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN                                           
   WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                
      --AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)  
   ';


SET @QUERY_BASIS_COUNT = '                                                
   SELECT @CNT=COUNT(COD_REPORT_TRANS)                                                  
   FROM [REPORT_TRANSACTIONS]             
   LEFT JOIN TRANSACTION_SERVICES ON TRANSACTION_SERVICES.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN        
   WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                                                   
      --AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)  
   ';


SET @QUERY_BASIS_PARAMETERS = '';

	   IF(@INITIAL_DATE IS NOT NULL AND @FINAL_DATE IS NOT NULL)
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

SET @QUERY_BASIS_COUNT = CONCAT(@QUERY_BASIS_COUNT, @QUERY_BASIS_PARAMETERS);



EXEC [sp_executesql] @QUERY_BASIS_COUNT
					,N'                                                          
   @CODCOMP VARCHAR(10),                                    
   @INITIAL_DATE DATETIME,                                                          
   @FINAL_DATE DATETIME,                                   
   @EC int,                                                          
   @BRANCH int,                                                          
   @DEPART int,                                                           
   @TERMINAL varchar(14),                                                          
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
   @COD_SALES_REP INT         
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
					,@COD_SALES_REP = @COD_SALES_REP;
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' ORDER BY [REPORT_TRANSACTIONS].TRANSACTION_DATE DESC ');
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' OFFSET (@NEXT_PAGE - 1) * @QTD_BY_PAGE ROWS');
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' FETCH NEXT @QTD_BY_PAGE ROWS ONLY');

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
   @TERMINAL varchar(14),                                                          
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
   @COD_SALES_REP INT                
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
					,@COD_SALES_REP = @COD_SALES_REP;

END;
END;
GO
PRINT N'Altering [dbo].[SP_REPORT_TRANSACTIONS_SPOT]...';


GO


ALTER PROCEDURE [dbo].[SP_REPORT_TRANSACTIONS_SPOT]                                                             
/*----------------------------------------------------------------------------------------                                                          
Procedure Name: [SP_REPORT_TRANSACTIONS]                                                          
Project.......: TKPP                                                          
------------------------------------------------------------------------------------------                                                          
Author                          VERSION        Date                            Description                                                          
------------------------------------------------------------------------------------------                                                          
Kennedy Alef     V1    27/07/2018      Creation                                                          
Gian Luca Dalle Cort   V1    04/10/2018      Changed                                                       
Lucas Aguiar           v2    26/11/2018    Changed                                   
Luiz Aquino    v3  15/01/2019     Change spot filter and transaction type from varchar to int                                  
Lucas Aguiar   v4   16/01/2019  changed                    
LUCAS AGUIAR V5 15-04-2019 PERMITIR ANTECIPAR CREDITO A VISTA            
LUCAS AGUIAR V6 15-04-2019 ROTINA DE SPLIT            
ANA PAULA LIICK V7 17-12-2019 ROTINA DE SPOT      
------------------------------------------------------------------------------------------*/                                                          
                                              
                                                    
(                                                              
    @CODCOMP VARCHAR(10),                                                              
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
    @NSU VARCHAR(100) = null,                                                              
    @NSU_EXT VARCHAR(100) = null,                                                              
    @BRAND VARCHAR(50) = NULL,                                                            
    @PAN VARCHAR(50) = NULL,                                                      
    @CodAff INT = NULL,                                        
    @TRACKING_TRANSACTION  VARCHAR(100) = null,                                                
    @DESCRIPTION  VARCHAR(100) = null,                                    
    @SPOT_ELEGIBLE INT = null,                                    
    @COD_ACQ  VARCHAR(10) = NULL,                                    
    @SOURCE_TRAN INT  = NULL,                                    
    @POSWEB INT = 0,                                    
    @INITIAL_VALUE DECIMAL(22,6) = NULL,                                                              
    @FINAL_VALUE DECIMAL(22,6) = NULL                                                                
 )                        
AS                                        
                                         
DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';
    
        
                 
                                                                  
DECLARE @TIME_FINAL_DATE TIME;

SET NOCOUNT ON
SET ARITHABORT ON
    
        
            
                                                                                    
BEGIN

SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');

--SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                    
--SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                 )                      

SET @FINAL_DATE = DATEADD(MILLISECOND, 999, @FINAL_DATE);
    
        
                       
            
                                    
    IF (@TIME_FINAL_DATE = '00:00:00')
SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'))


SET @QUERY_BASIS =
'                                                    
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
        [REPORT_TRANSACTIONS].DESCRIPTION AS DESCRIPTION              
  ,[REPORT_TRANSACTIONS].COD_EC_TRANS                   
   ,[REPORT_TRANSACTIONS].TRANS_EC_NAME              
   ,[REPORT_TRANSACTIONS].TRANS_EC_CPF_CNPJ        
   ,REPORT_TRANSACTIONS.COD_EC      
   ,(SELECT COUNT(*) FROM TRANSACTION_TITLES WHERE [REPORT_TRANSACTIONS].COD_TRAN = TRANSACTION_TITLES.COD_TRAN AND TRANSACTION_TITLES.PREVISION_PAY_DATE > @FINAL_DATE and TRANSACTION_TITLES.COD_EC = REPORT_TRANSACTIONS.COD_EC) AS PLOTS_AVAILABLE      
      FROM [REPORT_TRANSACTIONS] WITH (NOLOCK)                                                     
       WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                                                       
          AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)';
    
        
                    
                                    
                                                                
--       IF @EC IS NOT NULL    
--SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].COD_EC = @EC ');    
    
IF @BRANCH IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND [REPORT_TRANSACTIONS].COD_BRANCH =  @BRANCH ');

IF @DEPART IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].COD_DEPTO_BRANCH =  @DEPART ');

IF LEN(@TERMINAL) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND [REPORT_TRANSACTIONS].SERIAL_EQUIP = @TERMINAL');

IF LEN(@STATE) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND [REPORT_TRANSACTIONS].STATE_NAME = @STATE ');

IF LEN(@CITY) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].CITY_NAME = @CITY ');

IF @TYPE_TRAN IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND EXISTS( SELECT CODE FROM TRANSACTION_TYPE tt WHERE tt.COD_TTYPE = @TYPE_TRAN AND [REPORT_TRANSACTIONS].TRANSACTION_TYPE = tt.CODE ) ');

IF @SITUATION IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].COD_SITUATION = @SITUATION ');

IF LEN(@BRAND) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].BRAND = @BRAND ');

IF LEN(@NSU) > 0

SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].TRANSACTION_CODE = @NSU ');

IF LEN(@NSU_EXT) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].NSU_EXT = @NSU_EXT ');
--ELSE                                        
--SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND ([VW_REPORT_TRANSACTIONS].TRAN_DATA_EXT = ''RCPTTXID'' OR  [VW_REPORT_TRANSACTIONS].TRAN_DATA_EXT IS NULL                                       
--                                          OR [VW_REPORT_TRANSACTIONS].TRAN_DATA_EXT = ''AUTO'' OR [VW_REPORT_TRANSACTIONS].TRAN_DATA_EXT = ''NSU'' ) ');                                        

IF @PAN IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].PAN = @PAN ');

IF (@CodAff IS NOT NULL)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].COD_AFFILIATOR = @CodAff ');

IF LEN(@TRACKING_TRANSACTION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].TRACKING_TRANSACTION  = @TRACKING_TRANSACTION ');

IF LEN(@DESCRIPTION) > 0
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND  [REPORT_TRANSACTIONS].DESCRIPTION  LIKE  %@DESCRIPTION%');

IF @SPOT_ELEGIBLE = 1
BEGIN
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND EXISTS(SELECT title.COD_TRAN FROM TRANSACTION_TITLES title JOIN [TRANSACTION] title_tran WITH(NOLOCK) ON title_tran.COD_TRAN = title.COD_TRAN WHERE [REPORT_TRANSACTIONS].COD_TRAN = title_tran.COD_TRAN AND title.PREVISION_PAY_DATE > @FINAL_DATE and title.cod_situation = 4 and isnull(title.ANTICIP_PERCENT,0) <= 0 AND TITLE.COD_EC = @EC) ');
    
        
                    
    END
    
        
                    
                                         
       IF @COD_ACQ IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].COD_AC = @COD_ACQ');

IF @SOURCE_TRAN IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].COD_SOURCE_TRAN = @SOURCE_TRAN');

IF @POSWEB = 1
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].POSWEB = @POSWEB');

IF (@INITIAL_VALUE > 0)
	AND (@FINAL_VALUE >= @INITIAL_VALUE)
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS].AMOUNT BETWEEN @INITIAL_VALUE AND @FINAL_VALUE');

--SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY [VW_REPORT_TRANSACTIONS].TRANSACTION_DATE DESC ');                                        

--SELECT @QUERY_BASIS;                    

EXEC sp_executesql @QUERY_BASIS
				  ,N'                                                              
       @CODCOMP VARCHAR(10),                                        
       @INITIAL_DATE DATETIME,                                                              
       @FINAL_DATE DATETIME,                                       
       @EC int,                                           
       @BRANCH int,                                                              
       @DEPART int,                                                               
       @TERMINAL varchar(14),                                                              
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
       @FINAL_VALUE DECIMAL(22,6)                             
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
				  ,@CodAff = @CodAff
				  ,@TRACKING_TRANSACTION = @TRACKING_TRANSACTION
				  ,@DESCRIPTION = @DESCRIPTION
				  ,@COD_ACQ = @COD_ACQ
				  ,@SOURCE_TRAN = @SOURCE_TRAN
				  ,@POSWEB = @POSWEB
				  ,@INITIAL_VALUE = @INITIAL_VALUE
				  ,@FINAL_VALUE = @FINAL_VALUE

END;
GO
PRINT N'Altering [dbo].[SP_UP_BANK_CERC_EC_SITUATION]...';


GO


ALTER PROCEDURE [DBO].[SP_UP_BANK_CERC_EC_SITUATION]            
        
/**********************************************************************************************************
----------------------------------------------------------------------------------------            
    Procedure Name: [SP_UP_BANK_CERC_EC]            
    Project.......: TKPP            
    ------------------------------------------------------------------------------------------            
    Author                  VERSION  Date                        Description            
    -------------------------------------------------------------------------------------------            
 Lucas Aguiar   v1   2019-07-16     CREATE           
    ------------------------------------------------------------------------------------------    
**********************************************************************************************************/    
            
(
	@BANK_TYPE [BANK_CERC] READONLY)
AS
BEGIN


UPDATE [BANK_DETAILS_EC]
SET [ACTIVE] = 0
FROM [BANK_DETAILS_EC]
JOIN [BANK_DETAILS_CERC_INFO]
	ON [BANK_DETAILS_CERC_INFO].[COD_BK_EC] = [BANK_DETAILS_EC].[COD_BK_EC]
JOIN @BANK_TYPE [BANK_TYPE]
	ON [BANK_TYPE].[REG_IDENTIFIER] = [BANK_DETAILS_CERC_INFO].[REG_IDENTIFIER]
	AND [BANK_DETAILS_CERC_INFO].[COD_SITUATION] = 3
WHERE [ACTIVE] = 1;


UPDATE [BANK_DETAILS_CERC_INFO]
SET [BANK_DETAILS_CERC_INFO].[COD_SITUATION] = 16
FROM [BANK_DETAILS_CERC_INFO]
JOIN @BANK_TYPE [BANK_TYPE]
	ON [BANK_TYPE].[REG_IDENTIFIER] = [BANK_DETAILS_CERC_INFO].[REG_IDENTIFIER]
	AND [BANK_DETAILS_CERC_INFO].[COD_SITUATION] = 3;




END;
GO
PRINT N'Creating [dbo].[SP_DEFINE_PRD_PAYMENT_LINK]...';


--GO
--CREATE PROCEDURE SP_DEFINE_PRD_PAYMENT_LINK          
--(       
-- @BRAND VARCHAR(20),           
-- @PLOT INT,
-- @COD_AC INT
--)        
--AS      
--DECLARE @PLOT_PR INT = 0;
--BEGIN
  

--IF @PLOT > 1
--SET @PLOT_PR = 2
--ELSE
--SET @PLOT_PR = 1

--SELECT
--TOP 1
--	PRODUCTS_ACQUIRER.COD_AC
--   ,PRODUCTS_ACQUIRER.COD_PR_ACQ
--FROM PRODUCTS_ACQUIRER
--JOIN [BRAND]
--	ON [BRAND].COD_BRAND = PRODUCTS_ACQUIRER.COD_BRAND
--		AND [BRAND].[NAME] = @BRAND
--WHERE PRODUCTS_ACQUIRER.COD_AC = @COD_AC
--AND PRODUCTS_ACQUIRER.COD_SOURCE_TRAN = 1
--AND PRODUCTS_ACQUIRER.PLOT_VALUE = @PLOT_PR


--END;
--GO
--PRINT N'Creating [dbo].[SP_FD_ONLINEPOS_EC]...';


--GO

--CREATE PROCEDURE SP_FD_ONLINEPOS_EC
--(
--@COD_EC INT 
--)
--AS
--BEGIN


--WITH cte
--AS
--(SELECT
--		(SELECT
--			TOP 1
--				EQUIPMENT.SERIAL
--			FROM ASS_DEPTO_EQUIP
--			JOIN EQUIPMENT
--				ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
--				AND EQUIPMENT.COD_MODEL = 6
--			WHERE ASS_DEPTO_EQUIP.ACTIVE = 1
--			AND ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH)
--		AS ONLINEPOS
--	   ,COMMERCIAL_ESTABLISHMENT.[NAME]

--	FROM COMMERCIAL_ESTABLISHMENT
--	JOIN BRANCH_EC
--		ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
--	JOIN DEPARTMENTS_BRANCH
--		ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH

--	WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC)
--SELECT
--	*
--FROM cte
--WHERE ONLINEPOS IS NOT NULL


--END
--GO
--PRINT N'Creating [dbo].[SP_FD_TRANSACTION_TO_APPROVE]...';


--GO
--CREATE PROCEDURE SP_FD_TRANSACTION_TO_APPROVE
--(
--	@CODE_TRAN VARCHAR(255)
--)
--AS
--BEGIN
--SELECT
--	ACQUIRER_KEYS_CREDENTIALS.[NAME]
--   ,ACQUIRER_KEYS_CREDENTIALS.[VALUE]
--FROM [TRANSACTION] WITH (NOLOCK)
--INNER JOIN PRODUCTS_ACQUIRER
--	ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ
--INNER JOIN ACQUIRER
--	ON ACQUIRER.COD_AC = PRODUCTS_ACQUIRER.COD_AC
--INNER JOIN ACQUIRER_KEYS_CREDENTIALS
--	ON ACQUIRER.COD_AC = ACQUIRER_KEYS_CREDENTIALS.COD_AC
--INNER JOIN SITUATION
--	ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
--WHERE [TRANSACTION].CODE = @CODE_TRAN
--AND SITUATION.NAME = 'PRE-APPROVED'

--IF @@rowcount < 1 
--	THROW 60002, '010', 1;
--END;
--GO
--PRINT N'Creating [dbo].[SP_LS_ACQUIRER_BY_SEGMENT]...';


--GO

--CREATE PROCEDURE [SP_LS_ACQUIRER_BY_SEGMENT](
--	@COD_SEG INT)
--AS
--BEGIN
--    SELECT [ACQUIRER].[COD_AC], 
--		 [ACQUIRER].[NAME] AS [ACQUIRER_NAME], 
--		 [ACQUIRER].[CODE] AS [ACQUIRER_CODE], 
--		 [ACQUIRER].[GROUP] AS [ACQ_GROUP], 
--		 [SEGMENTS].[NAME], 
--		 [SEGMENTS].[DESCRIPTION], 
--		 [SEGMENTS_GROUP].[GROUP], 
--		 [SEGMENTS].[COD_SEG], 
--		 [SEGMENTS_GROUP].[COD_SEG_GROUP]
--    FROM [SEGMENTS]
--	    INNER JOIN [SEGMENTS_GROUP] ON [SEGMENTS].[COD_SEG_GROUP] = [SEGMENTS_GROUP].[COD_SEG_GROUP]
--	    INNER JOIN [ACQUIRER] ON [ACQUIRER].[COD_SEG_GROUP] = [SEGMENTS_GROUP].[COD_SEG_GROUP]
--    WHERE [COD_SEG] = @COD_SEG and ONLINE = 1
--END;
--GO
--PRINT N'Creating [dbo].[SP_LS_ACQUIRER_LINK_PAYMENTS]...';


--GO
--CREATE PROCEDURE SP_LS_ACQUIRER_LINK_PAYMENTS
--AS
--BEGIN

--SELECT
--	ACQUIRER.[GROUP] AS ACQUIRER
--   ,ACQUIRER.COD_AC
--FROM ACQUIRER
--JOIN LINK_PAYMENTS_ACTIVE
--	ON LINK_PAYMENTS_ACTIVE.COD_AC = ACQUIRER.COD_AC


--END
--GO
--PRINT N'Creating [dbo].[SP_LS_EMAIL_PENDING_TOSEND_TRAN]...';


--GO
 


--CREATE PROCEDURE SP_LS_EMAIL_PENDING_TOSEND_TRAN
--AS
--BEGIN

--SELECT
--	REPORT_TRANSACTIONS_EXP.TRANSACTION_CODE
--   ,REPORT_TRANSACTIONS_EXP.COD_TRAN
--   ,ISNULL(REPORT_TRANSACTIONS_EXP.TRAN_DATA_EXT_VALUE, '') AS ORDER_NUM
--   ,REPORT_TRANSACTIONS_EXP.COD_EC
--   ,REPORT_TRANSACTIONS_EXP.[NAME] AS TRANS_EC_NAME
--   ,REPORT_TRANSACTIONS_EXP.BRAND
--   ,REPORT_TRANSACTIONS_EXP.AMOUNT
--   ,REPORT_TRANSACTIONS_EXP.PLOTS
--   ,REPORT_TRANSACTIONS_EXP.CUSTOMER_EMAIL
--   ,REPORT_TRANSACTIONS_EXP.CUSTOMER_IDENTIFICATION
--   ,CASE
--		WHEN
--			REPORT_TRANSACTIONS_EXP.SITUATION = 'CONFIRMADA' THEN REPORT_TRANSACTIONS_EXP.SITUATION
--		ELSE 'NAO AUTORIZADA'
--	END AS SITUATION
--   ,REPORT_TRANSACTIONS_EXP.TRANSACTION_DATE
--   ,REPORT_TRANSACTIONS_EXP.NAME_AFFILIATOR
--   ,THEMES.LOGO_AFFILIATE
--   ,THEMES.LOGO_HEADER_AFFILIATE
--   ,THEMES.COLOR_HEADER
--   ,THEMES.SECONDARY_COLOR
--FROM REPORT_TRANSACTIONS_EXP
--JOIN THEMES
--	ON THEMES.COD_AFFILIATOR = REPORT_TRANSACTIONS_EXP.COD_AFFILIATOR
--		AND THEMES.ACTIVE = 1
--WHERE EMAIL_CONFIRM_SENDED IS NULL
--AND CUSTOMER_EMAIL IS NOT NULL
--AND LINK_PAYMENT_SERVICE = 1
--AND REPORT_TRANSACTIONS_EXP.COD_TRAN > 3089395





--END
--GO
--PRINT N'Creating [dbo].[SP_LS_KEY_ACQ]...';


--GO
--CREATE PROCEDURE [SP_LS_KEY_ACQ](
--	@COD_AC INT)
--AS
--BEGIN
--    SELECT 
--    COD_KEY_ACQ,
--    [CODE]
--    FROM [KEYS_ACQUIRER]
--    WHERE [COD_AC] = @COD_AC;
--END;
--GO
--PRINT N'Creating [dbo].[SP_LS_MERCHANT_TOSEND]...';


--GO



--create PROCEDURE SP_LS_MERCHANT_TOSEND
--AS
--BEGIN
--SELECT 
--COMMERCIAL_ESTABLISHMENT.COD_EC,
--COMMERCIAL_ESTABLISHMENT.[NAME],
--COMMERCIAL_ESTABLISHMENT.TRADING_NAME,
--COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,
--COMMERCIAL_ESTABLISHMENT.EMAIL,
--COMMERCIAL_ESTABLISHMENT.MUNICIPAL_REGISTRATION,
--COMMERCIAL_ESTABLISHMENT.STATE_REGISTRATION,
--COMMERCIAL_ESTABLISHMENT.BIRTHDATE,
--COMMERCIAL_ESTABLISHMENT.USER_ONLINE,
--COMMERCIAL_ESTABLISHMENT.PWD_ONLINE,
--(
--SELECT 
--TOP 1
--EQUIPMENT.SERIAL
--FROM
--ASS_DEPTO_EQUIP 
--JOIN EQUIPMENT ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
--		AND EQUIPMENT.COD_MODEL=6
--WHERE  ASS_DEPTO_EQUIP.ACTIVE=1 AND ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
--) AS SERIAL_EQUIP,
--dbo.FN_FUS_UTF(COMMERCIAL_ESTABLISHMENT.CREATED_AT) AS REG_DATE,
--dbo.FN_FUS_UTF(COMMERCIAL_ESTABLISHMENT.MODIFY_DATE) AS MOD_DATE,
--SEGMENTS.CNAE, 
--SEGMENTS.[NAME] AS SEGMENT, 
--TYPE_ESTAB.CODE AS TYPE_ESTAB,
--(
--SELECT 
--CONCAT(DDD, NUMBER) 
--from CONTACT_BRANCH
--WHERE ACTIVE=1
--AND CONTACT_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
--AND COD_TP_CONT=1
--) AS CELL,
--(
--SELECT 
--CONCAT(DDD, NUMBER)
--from CONTACT_BRANCH
--WHERE ACTIVE=1
--AND CONTACT_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
--AND COD_TP_CONT=2
--) AS TEL,
--(
--SELECT 
--CONCAT(DDD, NUMBER)
--from CONTACT_BRANCH
--WHERE ACTIVE=1
--AND CONTACT_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
--AND COD_TP_CONT=1
--) AS COMM_TEL,
--(
--SELECT 
--TOP 1
--ADITIONAL_DATA_TYPE_EC.[NAME] 
--FROM ADITIONAL_DATA_TYPE_EC
--WHERE ADITIONAL_DATA_TYPE_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
--AND ADITIONAL_DATA_TYPE_EC.ACTIVE=1

--) AS [PARTNER],
--ADDRESS_BRANCH.[ADDRESS],
--ADDRESS_BRANCH.CEP,
--ADDRESS_BRANCH.NUMBER as ADD_NUMBER,
--ADDRESS_BRANCH.COMPLEMENT,
--ADDRESS_BRANCH.REFERENCE_POINT,
--CITY.[NAME] AS CITY,
--[STATE].UF,
--COUNTRY.[NAME] AS COUNTRY,
--BANK_DETAILS_EC.AGENCY,
--BANK_DETAILS_EC.DIGIT_AGENCY,
--BANK_DETAILS_EC.ACCOUNT,
--BANK_DETAILS_EC.DIGIT_ACCOUNT,
--BANKS.CODE AS BANK_CODE,
--BANKS.[NAME] AS BANK
--FROM COMMERCIAL_ESTABLISHMENT
--JOIN TYPE_ESTAB ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB
--JOIN SEGMENTS ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
--JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
--JOIN DEPARTMENTS_BRANCH ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
--JOIN ADDRESS_BRANCH ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
--				AND ADDRESS_BRANCH.ACTIVE=1
--JOIN NEIGHBORHOOD ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
--JOIN CITY ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
--JOIN [STATE] ON [STATE].COD_STATE = CITY.COD_STATE
--JOIN COUNTRY ON COUNTRY.COD_COUNTRY = [STATE].COD_COUNTRY
--JOIN BANK_DETAILS_EC ON BANK_DETAILS_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
--		AND BANK_DETAILS_EC.ACTIVE=1
--		AND BANK_DETAILS_EC.IS_CERC = 0
--JOIN BANKS ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK
--WHERE COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR in (35,129)
--AND EMAIL_SENDED IS NULL
--AND COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION=2


--END;
--GO
--PRINT N'Creating [dbo].[SP_LS_PRODUCTS_TYPE]...';


--GO

--CREATE PROCEDURE SP_LS_PRODUCTS_TYPE
--AS
--BEGIN

--SELECT
--	[NAME] AS PRODUCT_TYPE
--   ,[CODE] AS PRODUCT_TYPE_CODE
--FROM PRODUCT_TYPE_LINK
--WHERE ACTIVE = 1


--END
--GO
--PRINT N'Creating [dbo].[SP_LS_SHIPPING_TYPE]...';


--GO

 

--CREATE PROCEDURE [SP_LS_SHIPPING_TYPE]
--AS
--BEGIN



--SELECT
--	[NAME]
--   ,[CODE]
--FROM [SHIPPING_TYPE]
--WHERE [ACTIVE] = 1;




--END;
--GO
--PRINT N'Creating [dbo].[SP_LS_USERS_TO_SEND]...';


--GO
--CREATE PROCEDURE SP_LS_USERS_TO_SEND
--AS
--BEGIN

--SELECT
--	USERS.COD_USER
--   ,IDENTIFICATION
--   ,EMAIL
--   ,COD_ACCESS
--   ,AFFILIATOR.SUBDOMAIN
--FROM USERS
--INNER JOIN PROVISORY_PASS_USER
--	ON PROVISORY_PASS_USER.COD_USER = USERS.COD_USER
--		AND PROVISORY_PASS_USER.ACTIVE = 1
--LEFT JOIN AFFILIATOR
--	ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
--WHERE ISNULL(SENT, 0) = 0

--END
--GO
--PRINT N'Creating [dbo].[SP_REG_EMAIL_SEND_EC]...';


--GO

 

--CREATE PROCEDURE [SP_REG_EMAIL_SEND_EC](
--    @COD_EC [CODE_TYPE] READONLY)
--AS
--BEGIN

 

--    UPDATE [COMMERCIAL_ESTABLISHMENT]
--     SET 
--        [EMAIL_SENDED] = 1
--    FROM [COMMERCIAL_ESTABLISHMENT]
--        JOIN @COD_EC [TP] ON [TP].[CODE] = [COMMERCIAL_ESTABLISHMENT].[COD_EC];

 

--END;
--GO
--PRINT N'Creating [dbo].[SP_REG_EMAIL_TRAN_LINK]...';


--GO
-- CREATE PROCEDURE [SP_REG_EMAIL_TRAN_LINK](
--    @COD_EC [CODE_TYPE] READONLY)
--AS
--BEGIN



--UPDATE REPORT_TRANSACTIONS_EXP
--SET EMAIL_CONFIRM_SENDED = 1
--FROM REPORT_TRANSACTIONS_EXP
--JOIN @COD_EC [TP]
--	ON [TP].[CODE] = REPORT_TRANSACTIONS_EXP.COD_TRAN;



--END;
--GO
--PRINT N'Creating [dbo].[SP_REG_LOGNUMBER_ACQ_MERCHANT]...';


--GO

--CREATE PROCEDURE SP_REG_LOGNUMBER_ACQ_MERCHANT
--(
--@COD_EC INT,
--@COD_USER INT
--)
--AS
--DECLARE @COD_AC INT ;
--DECLARE @LOGICAL_NUMBER VARCHAR(100);
--DECLARE @NAME VARCHAR(100);


--BEGIN

---- PROCEDURE WORK JUST TO PRESENTIAL PAGSEGURO

--IF (SELECT COUNT(*) FROM MERCHANT_LOGICALNUMBERS_ACQ WHERE COD_EC = @COD_EC) =0
--BEGIN

--SELECT 
--@COD_AC=COD_AC
--FROM COMMERCIAL_ESTABLISHMENT
--JOIN SEGMENTS ON SEGMENTS.COD_SEG =COMMERCIAL_ESTABLISHMENT.COD_SEG
--JOIN ACQUIRER ON ACQUIRER.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
--			AND ACQUIRER.[GROUP] = 'PAGSEGURO'
--WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC


--SELECT 
--TOP 1
--@NAME = DATA_TID_AVAILABLE_EC.[NAME],
--@LOGICAL_NUMBER=DATA_TID_AVAILABLE_EC.TID 
--FROM DATA_TID_AVAILABLE_EC 
--WHERE COD_AC = @COD_AC 
--	 AND ACTIVE=1 
--	 AND AVAILABLE=1

--IF @LOGICAL_NUMBER IS NULL
--THROW 60000, 'TID UNAVAILABLE',1;
--ELSE
--BEGIN

--INSERT INTO MERCHANT_LOGICALNUMBERS_ACQ 
--(
--COD_EC,
--[NAME],
--LOGICAL_NUMBER_ACQ,
--COD_AC,
--COD_USER
--)
--VALUES
--(
--@COD_EC,
--@NAME,
--@LOGICAL_NUMBER,
--@COD_AC,
--@COD_USER
--)

--IF @@ROWCOUNT < 1
--THROW 60000, 'COULD NOT REGISTER LOGICAL NUMBER',1;

--END;


--END;





--END;
--GO
--PRINT N'Creating [dbo].[SP_REG_ONLINE_CREDENTIALS]...';


--GO


--CREATE PROCEDURE [SP_REG_ONLINE_CREDENTIALS](  
-- @TP_ONLINE_CREDENTIALS [TP_ONLINE_CREDENTIALS] READONLY,   
-- @CODE_EC               INT)  
--AS  
--BEGIN  


--SELECT @CODE_EC = CODE FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @CODE_EC


  
--    IF  
--    (SELECT COUNT(*)  
-- FROM [ACQUIRER_KEYS_CREDENTIALS]
-- WHERE [CODE_EC] = @CODE_EC
-- AND [NAME] IN 
-- (
-- SELECT [NAME] FROM @TP_ONLINE_CREDENTIALS
-- )
-- ) > 0  
--    DELETE [ACQUIRER_KEYS_CREDENTIALS] FROM [ACQUIRER_KEYS_CREDENTIALS]  
--	JOIN @TP_ONLINE_CREDENTIALS TP ON TP.COD_AC = [ACQUIRER_KEYS_CREDENTIALS].COD_AC
--				AND TP.[NAME] = [ACQUIRER_KEYS_CREDENTIALS].[NAME]
--    WHERE [ACQUIRER_KEYS_CREDENTIALS].[CODE_EC] = @CODE_EC ;  
  
  
--    INSERT INTO [ACQUIRER_KEYS_CREDENTIALS]  
--    ([NAME],   
-- VALUE,   
-- [COD_AC],   
-- [CODE_EC]  
--    )  
--    SELECT [NAME],   
--   [VALUE],   
--   [COD_AC],   
--   @CODE_EC
--    FROM @TP_ONLINE_CREDENTIALS;  
  
  
--END;
--GO
--PRINT N'Creating [dbo].[SP_UP_SENT_USER]...';


--GO

--CREATE PROCEDURE SP_UP_SENT_USER
--(
--	@COD_USER INT
--)
--AS
--BEGIN

--UPDATE USERS
--SET SENT = 1
--WHERE COD_USER = @COD_USER

--END
--GO
PRINT N'Altering [dbo].[SP_UP_TRANSACTION_ON]...';


GO
ALTER PROCEDURE [dbo].[SP_UP_TRANSACTION_ON]              
/*----------------------------------------------------------------------------------------              
Procedure Name: [SP_UP_TRANSACTION]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author VERSION Date Description              
------------------------------------------------------------------------------------------              
Kennedy Alef V1 27/07/2018 Creation              
Rodrigo Carvalho V2 12/12/2018 Creation              
Lucas Aguiar v3 2019-04-17 Add parâmetro e rotina de aw. titles              
------------------------------------------------------------------------------------------*/              
(              
@CODE_TRAN VARCHAR(200),              
@SITUATION VARCHAR(100),              
@DESCRIPTION VARCHAR(200),              
@CURRENCY VARCHAR(100),          
@COD_PROD_ACQ INT = NULL,        
@COD_AC INT = NULL      
)              
AS              
DECLARE @CONT INT;
    
        
          
              
DECLARE @SIT VARCHAR(100);
    
        
          
              
DECLARE @BRANCH INT
    
        
          
DECLARE @COD_ASS_TR_COMP INT;
    
        
BEGIN

SELECT
	@COD_ASS_TR_COMP = ASS_TR_TYPE_COMP.COD_ASS_TR_COMP
FROM ASS_TR_TYPE_COMP
INNER JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].CODE = @CODE_TRAN
		AND [TRANSACTION].PLOTS BETWEEN PLOT_INI AND PLOT_END
INNER JOIN BRAND
	ON BRAND.NAME = [TRANSACTION].BRAND
		AND BRAND.COD_TTYPE = [TRANSACTION].COD_TTYPE
		AND ASS_TR_TYPE_COMP.COD_BRAND = BRAND.COD_BRAND
WHERE ASS_TR_TYPE_COMP.COD_SOURCE_TRAN = 1
AND ACTIVE = 1
AND ASS_TR_TYPE_COMP.COD_AC = @COD_AC

SET @CONT = 1;
SELECT
	@CONT = COD_TRAN
   ,@SIT = SITUATION.NAME
FROM [TRANSACTION]
INNER JOIN SITUATION
	ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
WHERE CODE = @CODE_TRAN
IF @CONT < 1
	OR @CONT IS NULL
THROW 60002, '601', 1;
UPDATE PROCESS_BG_STATUS
SET STATUS_PROCESSED = 0
   ,MODIFY_DATE = GETDATE()
WHERE CODE = @CONT
AND COD_TYPE_PROCESS_BG = 1
IF @SITUATION = 'APPROVED'
BEGIN
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 1
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
END
ELSE
IF @SITUATION = 'PENDENT'
BEGIN
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 19
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
END
ELSE
IF @SITUATION = 'CONFIRMED'
BEGIN
IF @SIT = @SITUATION
THROW 60002, '603', 1
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 3
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
DELETE FROM TRANSACTION_PENDENT_TREATMENT
WHERE TID = @CODE_TRAN
EXECUTE [SP_GEN_TITLES_TRANS] @COD_TRAN = @CODE_TRAN
END
ELSE
IF @SITUATION = 'AWAITING TITLES'
BEGIN
IF @SIT = @SITUATION
THROW 60002, '603', 1
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 22
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = '206 - AGUARDANDO TITULOS'
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
DELETE FROM TRANSACTION_PENDENT_TREATMENT
WHERE TID = @CODE_TRAN;
END
ELSE
IF @SITUATION = 'DENIED ACQUIRER'
BEGIN
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 2
   ,MODIFY_DATE = GETDATE()
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
END;
IF @SITUATION = 'UNDONE'
BEGIN
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 10
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
END;
--OR @SITUATION = ''              
ELSE
IF @SITUATION = 'PRE-APPROVED'
BEGIN
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 31
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,COD_CURRRENCY = (SELECT
			COD_CURRRENCY
		FROM CURRENCY
		WHERE NUM = @CURRENCY)
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
   ,[TRANSACTION].PRE_APPROVED = 1
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
END
IF @SITUATION = 'FAILED'
BEGIN
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 7
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
END;
ELSE
IF @SITUATION = 'CANCELED'
BEGIN
IF (@SIT = 'AWAITING TITLES')
BEGIN
IF @SIT = @SITUATION
THROW 60002, '703', 1
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].CODE = @CODE_TRAN
UPDATE RELEASE_ADJUSTMENTS
SET RELEASE_ADJUSTMENTS.COD_SITUATION = 6
FROM RELEASE_ADJUSTMENTS
INNER JOIN POSWEB_DATA_TRANSACTION
	ON RELEASE_ADJUSTMENTS.COD_POS_DATA = POSWEB_DATA_TRANSACTION.COD_POS_DATA
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = POSWEB_DATA_TRANSACTION.COD_TRAN
WHERE [TRANSACTION].CODE = @CODE_TRAN
END;
ELSE
BEGIN
IF @SIT = @SITUATION
THROW 60002, '703', 1
SELECT
	@CONT = COUNT(*)
FROM TRANSACTION_TITLES
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].CODE = @CODE_TRAN
AND TRANSACTION_TITLES.COD_SITUATION != 4
IF @CONT > 0
THROW 60002, '704', 1
EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;
UPDATE [TRANSACTION]
SET COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
   ,[TRANSACTION].COD_PR_ACQ = ISNULL(@COD_PROD_ACQ, [TRANSACTION].COD_PR_ACQ)
   ,[TRANSACTION].COD_ASS_TR_COMP = ISNULL(@COD_ASS_TR_COMP, [TRANSACTION].COD_ASS_TR_COMP)
WHERE [TRANSACTION].CODE = @CODE_TRAN;
IF @@rowcount < 1
THROW 60002, '002', 1
UPDATE TRANSACTION_TITLES
SET TRANSACTION_TITLES.COD_SITUATION = 6
   ,MODIFY_DATE = GETDATE()
   ,COMMENT = @DESCRIPTION
FROM TRANSACTION_TITLES
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
WHERE [TRANSACTION].CODE = @CODE_TRAN
UPDATE RELEASE_ADJUSTMENTS
SET RELEASE_ADJUSTMENTS.COD_SITUATION = 6
FROM RELEASE_ADJUSTMENTS
INNER JOIN POSWEB_DATA_TRANSACTION
	ON RELEASE_ADJUSTMENTS.COD_POS_DATA = POSWEB_DATA_TRANSACTION.COD_POS_DATA
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = POSWEB_DATA_TRANSACTION.COD_TRAN
WHERE [TRANSACTION].CODE = @CODE_TRAN
END;
END
END
GO
PRINT N'Altering [dbo].[SP_VAL_LIMIT_EC]...';


GO

  
ALTER PROCEDURE [dbo].[SP_VAL_LIMIT_EC]       
/*----------------------------------------------------------------------------------------------------------------------       
Procedure Name: [SP_VAL_LIMIT_EC]       
Project.......: TKPP       
------------------------------------------------------------------------------------------------------------------------       
Author VERSION Date Description       
------------------------------------------------------------------------------------------------------------------------       
Kennedy Alef V1 27/07/2018 Creation      
Lucas Aguair V2 17-04-2019 ADD PARÂMETRO OPCIONAL DO SPLIT E SUA INSERÇÃO       
Lucas Aguiar v4 23-04-2019 Parametro opc cod ec       
------------------------------------------------------------------------------------------------------------------------*/       
(       
@CODEC INT,       
@AMOUNT DECIMAL(22,6),       
@PAN VARCHAR(200),       
@BRAND VARCHAR(200),       
@CODASS_DEPTO_TERMINAL int ,       
@COD_TTYPE int,       
@PLOTS int,       
@CODTAX_ASS INT,       
@CODETR VARCHAR(200),       
@TYPE VARCHAR(100),       
@TERMINALDATE DATETIME,       
@COD_COMP INT,       
@COD_AFFILIATOR INT = NULL,       
@CODE_SPLIT INT = NULL,      
@EC_TRANS INT = NULL,  
@HOLDER_NAME VARCHAR(100)  = NULL,  
@HOLDER_DOC VARCHAR(100)  = NULL,   
@LOGICAL_NUMBER VARCHAR(100)  = NULL,  
@SOURCE_TRAN INT = NULL,
@CUSTOMER_EMAIL VARCHAR(100) = NULL,
@LINK_MODE INT = NULL,
@CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL
           
      
)       
AS       
DECLARE @VALUE DECIMAL(22,6);
  
    
       
DECLARE @LIMIT_DAILY DECIMAL(22,6);
  
    
       
DECLARE @LIMIT DECIMAL(22,6);
  
    
       
DECLARE @MONTLY DECIMAL(22,6);
  
    
       
BEGIN
SET @LIMIT_DAILY = 0;
SET @VALUE = 0;

SELECT
	@LIMIT_DAILY = EC.LIMIT_TRANSACTION_DIALY
   ,@LIMIT = EC.TRANSACTION_LIMIT
   ,@MONTLY = EC.LIMIT_TRANSACTION_MONTHLY
FROM COMMERCIAL_ESTABLISHMENT EC
WHERE EC.COD_EC = @CODEC;

IF @AMOUNT > @LIMIT

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS_DEPTO_TERMINAL
								,@COD_TTYPE = @COD_TTYPE
								,@PLOTS = @PLOTS
								,@CODTAX_ASS = @CODTAX_ASS
								,@CODAC = NULL
								,@CODETR = @CODETR
								,@COMMENT = '402 - Transaction limit value exceeded'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@SOURCE_TRAN = @SOURCE_TRAN
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

--select @VALUE as value, @AMOUNT as amout, @LIMIT_DAILY as limit       
THROW 60002, '402', 1;

END;


--  DIALY    

SELECT
	@VALUE = SUM(ISNULL([TRANSACTION].AMOUNT, 0))
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
INNER JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].COD_BRANCH = [DEPARTMENTS_BRANCH].COD_BRANCH
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = [BRANCH_EC].COD_EC
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @CODEC
AND CAST([TRANSACTION].BRAZILIAN_DATE AS DATE) = CAST(dbo.FN_FUS_UTF(GETDATE()) AS DATE)
AND [TRANSACTION].COD_SITUATION = 3
GROUP BY COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY

IF ((ISNULL(@VALUE, 0) + @AMOUNT) > @LIMIT_DAILY)

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS_DEPTO_TERMINAL
								,@COD_TTYPE = @COD_TTYPE
								,@PLOTS = @PLOTS
								,@CODTAX_ASS = @CODTAX_ASS
								,@CODAC = NULL
								,@CODETR = @CODETR
								,@COMMENT = '403 - Daily limit value exceeded'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@SOURCE_TRAN = @SOURCE_TRAN
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;



--select @VALUE as value, @AMOUNT as amout, @LIMIT_DAILY as limit       
THROW 60002, '403', 1;

END;

-- MONTH    

SELECT
	@VALUE = SUM(ISNULL([TRANSACTION].AMOUNT, 0))
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
INNER JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].COD_BRANCH = [DEPARTMENTS_BRANCH].COD_BRANCH
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = [BRANCH_EC].COD_EC
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @CODEC
AND CAST([TRANSACTION].BRAZILIAN_DATE AS DATE)
BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AND
DATEADD(SECOND, 86399, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 30))
AND [TRANSACTION].COD_SITUATION = 3
GROUP BY COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY

IF ((ISNULL(@VALUE, 0) + @AMOUNT) > @MONTLY)

BEGIN
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
								,@PAN = @PAN
								,@BRAND = @BRAND
								,@CODASS_DEPTO_TERMINAL = @CODASS_DEPTO_TERMINAL
								,@COD_TTYPE = @COD_TTYPE
								,@PLOTS = @PLOTS
								,@CODTAX_ASS = @CODTAX_ASS
								,@CODAC = NULL
								,@CODETR = @CODETR
								,@COMMENT = '407 - Monthly limit value exceeded'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@SOURCE_TRAN = @SOURCE_TRAN
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;


--select @VALUE as value, @AMOUNT as amout, @LIMIT_DAILY as limit       
THROW 60002, '407', 1;

END;



END;
GO
PRINT N'Altering [dbo].[SP_VALIDATE_TRANSACTION_ON]...';


GO
    
ALTER PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION_ON]                            
 /*------------------------------------------------------------------------------------------------------------------------------------------                                          
Procedure Name: [SP_VALIDATE_TRANSACTION]                                          
Project.......: TKPP                                          
------------------------------------------------------------------------------------------------------------------------------------------------                                          
Author                          VERSION        Date                            Description                                          
-------------------------------------------------------------------------------------------------------------------------------------------------                                          
Kennedy Alef     V1   20/08/2018    Creation                                          
Lucas Aguiar     v2   17-04-2019    Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções                              
Lucas Aguiar     v4   23-04-2019    Parametro opc cod ec                             
------------------------------------------------------------------------------------------------------------------------------------------------*/                            
 (                            
@TERMINALID VARCHAR(100)                            
,@TYPETRANSACTION VARCHAR(100)                            
,@AMOUNT DECIMAL(22, 6)                            
,@QTY_PLOTS INT                            
,@PAN VARCHAR(100)                            
,@BRAND VARCHAR(200)                            
,@TRCODE VARCHAR(200)                            
,@TERMINALDATE DATETIME = NULL                            
,@CODPROD_ACQ INT                         
,@TYPE VARCHAR(100)                            
,@COD_BRANCH INT = NULL                            
,@MID VARCHAR(100)                            
,@DESCRIPTION VARCHAR(300) = NULL                            
,@CODE_SPLIT INT = NULL                            
,@COD_EC INT = NULL                         
,@CREDITOR_DOC VARCHAR(100) = NULL                 
,@DESCRIPTION_TRAN VARCHAR(100) = NULL                
,@TRACKING VARCHAR(100) = NULL  
,@HOLDER_NAME     VARCHAR(100) = NULL  
,@HOLDER_DOC   VARCHAR(100) = NULL  
,@LOGICAL_NUMBER  VARCHAR(100) = NULL
,@CUSTOMER_EMAIL VARCHAR(100) = NULL
,@LINK_MODE INT = NULL
,@CUSTOMER_IDENTIFICATION VARCHAR(100) =NULL
 )                            
AS                            
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
      
        
          
                        
       
DECLARE @ONLINE INT = NULL;
      
        
          
                        
                            
DECLARE @TYPE_CREDIT INT;
      
        
          
                        
                            
DECLARE @EC_TRANS INT;
      
        
          
                        
                            
DECLARE @GEN_TITLES INT;
      
        
          
              
                            
--DECLARE @PRODUCT_ACQ INT;                                  
BEGIN
SELECT
	@CODTX = ASS_TAX_DEPART.COD_ASS_TX_DEP
   ,@CODPLAN = ASS_TAX_DEPART.COD_ASS_TX_DEP
   ,@INTERVAL = ASS_TAX_DEPART.INTERVAL
   ,@TERMINALACTIVE = EQUIPMENT.ACTIVE
   ,@CODEC = COMMERCIAL_ESTABLISHMENT.COD_EC
   ,@CODASS = [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL
   ,@COMPANY = COMPANY.COD_COMP
   ,@TYPETRAN = TRANSACTION_TYPE.COD_TTYPE
   ,@ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE
   ,@BRANCH = BRANCH_EC.COD_BRANCH
   ,@COD_COMP = COMPANY.COD_COMP
   ,@LIMIT = COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT
   ,@COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
   ,@ONLINE = COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE
   ,@GEN_TITLES = BRAND.GEN_TITLES
FROM [ASS_DEPTO_EQUIP]
LEFT JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = [ASS_DEPTO_EQUIP].COD_EQUIP
LEFT JOIN EQUIPMENT_MODEL
	ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL
LEFT JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH
LEFT JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
LEFT JOIN DEPARTMENTS
	ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
LEFT JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
LEFT JOIN COMPANY
	ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
LEFT JOIN ASS_TAX_DEPART
	ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
LEFT JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE
LEFT JOIN BRAND
	ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
		AND BRAND.COD_TTYPE = TRANSACTION_TYPE.COD_TTYPE
--LEFT JOIN EXTERNAL_DATA_EC_ACQ ON EXTERNAL_DATA_EC_ACQ.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC                                          
WHERE ASS_TAX_DEPART.ACTIVE = 1
AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 1
AND [ASS_DEPTO_EQUIP].ACTIVE = 1
AND EQUIPMENT.SERIAL = @TERMINALID
AND LOWER(TRANSACTION_TYPE.NAME) = @TYPETRANSACTION
AND ASS_TAX_DEPART.QTY_INI_PLOTS <= @QTY_PLOTS
AND ASS_TAX_DEPART.QTY_FINAL_PLOTS >= @QTY_PLOTS
AND (BRAND.[NAME] = @BRAND
OR BRAND.COD_BRAND IS NULL)


IF (@CODE_SPLIT = 0
	OR @CODE_SPLIT IS NULL)
SET @EC_TRANS = 3;
ELSE
SET @EC_TRANS = @CODEC;

--AND (EXTERNAL_DATA_EC_ACQ.[NAME] = 'MID' OR EXTERNAL_DATA_EC_ACQ.[NAME] IS NULL)                                       
IF @ONLINE = NULL
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
								,@COMMENT = '402 - TRANSACTION ONLINE NOT ENABLE'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 1
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

THROW 60002
, '402'
, 1;
END;

IF @AMOUNT > @LIMIT
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
								,@COMMENT = '402 - Transaction limit value exceeded'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 1
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

THROW 60002
, '402'
, 1;
END;

IF @CODTX IS NULL
/* PROCEDURE DE REGISTRO DE TRANSAÇÕES NEGADAS*/
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
								,@SOURCE_TRAN = 1
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

THROW 60002
, '404'
, 1;
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
								,@COMMENT = '003 - Blocked terminal  '
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 1
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

THROW 60002
, '003'
, 1;
END

IF @ACTIVE_EC = 0
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
								,@SOURCE_TRAN = 1
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

THROW 60002
, '009'
, 1;
END

EXEC SP_VAL_LIMIT_EC @CODEC
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
					,@CODE_SPLIT = @CODE_SPLIT
					,@EC_TRANS = @EC_TRANS
					,@HOLDER_NAME = @HOLDER_NAME
					,@HOLDER_DOC = @HOLDER_DOC
					,@LOGICAL_NUMBER = @LOGICAL_NUMBER
					,@SOURCE_TRAN = 1
					,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
					,@LINK_MODE = @LINK_MODE
					,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;


EXEC @CODAC = SP_DEFINE_ACQ @TR_TYPE = @TYPETRAN
						   ,@COMPANY = @COMPANY
						   ,@QTY_PLOTS = @QTY_PLOTS
						   ,@BRAND = @BRAND
						   ,@DOC_CREDITOR = @CREDITOR_DOC

-- DEFINIR SE PARCELA > 1 ENTAO , CREDITO PARCELADO                                
IF @QTY_PLOTS > 1
SET @TYPE_CREDIT = 2;
ELSE
SET @TYPE_CREDIT = 1;

IF (@CREDITOR_DOC IS NOT NULL)
BEGIN
SELECT
	@CODPROD_ACQ = [PRODUCTS_ACQUIRER].COD_PR_ACQ
FROM [PRODUCTS_ACQUIRER]
INNER JOIN BRAND
	ON BRAND.COD_BRAND = PRODUCTS_ACQUIRER.COD_BRAND
INNER JOIN ASS_TR_TYPE_COMP
	ON ASS_TR_TYPE_COMP.COD_AC = PRODUCTS_ACQUIRER.COD_AC
		AND ASS_TR_TYPE_COMP.COD_BRAND = ASS_TR_TYPE_COMP.COD_BRAND
WHERE ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = @CODAC
AND [PRODUCTS_ACQUIRER].PLOT_VALUE = @TYPE_CREDIT
AND BRAND.NAME = @BRAND
END


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
								,@COMMENT = '004 - Acquirer key not found for terminal '
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 1
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;


THROW 60002
, '004'
, 1;
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
								,@CREDITOR_DOC = @CREDITOR_DOC
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER
								,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
								,@LINK_MODE = @LINK_MODE
								,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;

THROW 60002, '012', 1;
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
							,@SOURCE_TRAN = 1
							,@POSWEB = 0
							,@CODE_SPLIT = @CODE_SPLIT
							,@EC_TRANS = @EC_TRANS
							,@CREDITOR_DOC = @CREDITOR_DOC
							,@TRACKING_DESCRIPTION = @TRACKING
							,@DESCRIPTION = @DESCRIPTION_TRAN
							,@HOLDER_NAME = @HOLDER_NAME
							,@HOLDER_DOC = @HOLDER_DOC
							,@LOGICAL_NUMBER = @LOGICAL_NUMBER
							,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
							,@LINK_MODE = @LINK_MODE
							,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;
--SELECT                                          
--  'ADQ'  AS ACQUIRER,                         
--  '1234567489' AS TRAN_CODE,                                        
--  'ESTABLISHMENT COMMERCIAL TEST' AS EC                                      
SELECT
	EXTERNAL_DATA_EC_ACQ.[VALUE] AS EC
   ,@TRCODE AS TRAN_CODE
   ,ACQUIRER.NAME AS ACQUIRER
--,@CODPROD_ACQ AS PRODUCT      
FROM ASS_TR_TYPE_COMP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
LEFT JOIN EXTERNAL_DATA_EC_ACQ
	ON EXTERNAL_DATA_EC_ACQ.COD_AC = ASS_TR_TYPE_COMP.COD_AC
WHERE
--ISNULL(EXTERNAL_DATA_EC_ACQ.[NAME],'MID') = 'MID' AND                                   
ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = @CODAC
END;
GO
PRINT N'Refreshing [dbo].[SP_FD_CREDENTIALS_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_CREDENTIALS_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_FD_AFF_EXT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_FD_AFF_EXT]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_REG_ACCESS_APPAPI]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_REG_ACCESS_APPAPI]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_REG_EXT_ACCESS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_REG_EXT_ACCESS]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_REG_TOKEN_EXT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_REG_TOKEN_EXT]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_VAL_GEN_TOKEN_EXT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_VAL_GEN_TOKEN_EXT]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_DATA_COMP_ACCESS_KEYS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_DATA_COMP_ACCESS_KEYS]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_DATA_COMP_ACCESS_KEYS_EXTERNAL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_DATA_COMP_ACCESS_KEYS_EXTERNAL]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ACCESS_APPAPI]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ACCESS_APPAPI]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ACCESS_NOTIFICATION_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ACCESS_NOTIFICATION_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_CREDENTIAL_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_CREDENTIAL_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_ACCESS_APPAPI]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_ACCESS_APPAPI]';


--GO
--PRINT N'Refreshing [DBO].[SP_LOAD_TABLES_EQUIP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[DBO].[SP_LOAD_TABLES_EQUIP]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_CARD_RULES_PROD]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_CARD_RULES_PROD]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_COMP_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_COMP_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_COMP_ACQ_1]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_COMP_ACQ_1]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_COMP_ACQ_NEW]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_COMP_ACQ_NEW]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_EQUIP_AC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_EQUIP_AC]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_TRAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_TRAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_DEFINE_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DEFINE_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_DISABLE_ASS_EQUIP_DEPTO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DISABLE_ASS_EQUIP_DEPTO]';


--GO
--PRINT N'Refreshing [dbo].[SP_DSB_REP_SIT_TRAN_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DSB_REP_SIT_TRAN_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_DATA_TRAN_OPER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_DATA_TRAN_OPER]';


--GO
--PRINT N'Refreshing [dbo].[SP_GET_DATA_EC_AC_OLN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GET_DATA_EC_AC_OLN]';


--GO
--PRINT N'Refreshing [dbo].[SP_GET_DATA_EC_AC_OLN_2]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GET_DATA_EC_AC_OLN_2]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOAD_TABLES_CONFIG]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOAD_TABLES_CONFIG]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_ACQUIRER_BY_GROUP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_ACQUIRER_BY_GROUP]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_DATA_EC_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_DATA_EC_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_DATA_EC_ACQ_CODE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_DATA_EC_ACQ_CODE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SERIAL_DATA_AC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SERIAL_DATA_AC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TRAN_TOUNDONE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TRAN_TOUNDONE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TRANSACTION_SETT_BY_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TRANSACTION_SETT_BY_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TRANSACTION_SETT_BY_BRAND]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TRANSACTION_SETT_BY_BRAND]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ASS_TID_EQUIP_EC_COUNT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ASS_TID_EQUIP_EC_COUNT]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_CONC_DATA]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_CONC_DATA]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ROUTE_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ROUTE_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_ASSOCIATE_TIDS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_ASSOCIATE_TIDS]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_REG_ROUTE_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_REG_ROUTE_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_DETAILS_VALUETORECEIVE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_VALUETORECEIVE]';


--GO
--PRINT N'Refreshing [dbo].[SP_DETAILS_VALUETORECEIVE_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_VALUETORECEIVE_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EQUIPMENT_EXP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EQUIPMENT_EXP]';


--GO
--PRINT N'Refreshing [dbo].[SP_RECEIPT_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_RECEIPT_TRANSACTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_REPORT_CONSOLIDATED_TRANS_SUB_RECOVERY]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_REPORT_CONSOLIDATED_TRANS_SUB_RECOVERY]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TRAN_TO_CANCEL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TRAN_TO_CANCEL]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_RECEIVE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_RECEIVE]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_TORECEIVE_ACQ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_TORECEIVE_ACQ]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_CANC_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_CANC_TRANSACTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_ROUTE_TID]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ROUTE_TID]';


--GO
--PRINT N'Refreshing [dbo].[SP_CONTACT_DATA_EQUIP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_CONTACT_DATA_EQUIP]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_SPLIT_PENDING]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_SPLIT_PENDING]';


--GO
--PRINT N'Refreshing [dbo].[SP_ADVANCE_REPORT_SPOT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ADVANCE_REPORT_SPOT]';


--GO
--PRINT N'Refreshing [dbo].[SP_REP_PAYMENTS_AFFILIATOR_DETAILS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REP_PAYMENTS_AFFILIATOR_DETAILS]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SPOT_ELEGIBLE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SPOT_ELEGIBLE]';


----GO
------PRINT N'Refreshing [dbo].[SP_ASS_AFF_PLAN]...';


----GO
----EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ASS_AFF_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_NOTIFY_PAYMENTS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_NOTIFY_PAYMENTS]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_NOTIFY_PAYMENTS_UNITY]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_NOTIFY_PAYMENTS_UNITY]';

GO

/****** Object:  Table [dbo].[WL_CONTENT_TYPE]    Script Date: 27/04/2020 15:21:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WL_CONTENT_TYPE](
	[COD_WL_CONT_TYPE] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](255) NOT NULL,
	[DESCRIPTION] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_WL_CONT_TYPE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET IDENTITY_INSERT [dbo].[WL_CONTENT_TYPE] ON

INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (1, N'IMG_LOGO', N'IMAGEM DO LOGO')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (2, N'IMG_LATERAL', N'IMAGEM LATERAL')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (3, N'IMG_CAROUSEL01', N'IMAGEM 01 DO CARROSSEL')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (4, N'IMG_CAROUSEL02', N'IMAGEM 02 DO CARROSSEL')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (5, N'IMG_CAROUSEL03', N'IMAGEM 03 DO CARROSSEL')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (6, N'IMG_ABOUT01', N'IMAGEM 01 DO SOBRE NÓS')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (7, N'IMG_ABOUT02', N'IMAGEM 02 DO SOBRE NÓS')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (8, N'IMG_PRODUCT', N'IMAGENS DOS PRODUTOS')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (9, N'IMG_BENEFITS01', N'IMAGEM 01 DO BENEFÍCIO')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (10, N'IMG_BENEFITS02', N'IMAGEM 02 DO BENEFÍCIO')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (11, N'IMG_BENEFITS03', N'IMAGEM 03 DO BENEFÍCIO')
INSERT [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE], [CODE], [DESCRIPTION])
	VALUES (12, N'IMG_BENEFITS04', N'IMAGEM 04 DO BENEFÍCIO')
SET IDENTITY_INSERT [dbo].[WL_CONTENT_TYPE] OFF

--GO
--PRINT N'Refreshing [dbo].[SP_EXP_TITLE_LOCK_PAYMENT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXP_TITLE_LOCK_PAYMENT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_BRAND_BY_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_BRAND_BY_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_CREDENTIALS_MERCHANT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_CREDENTIALS_MERCHANT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_EC_PWDONLINE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_EC_PWDONLINE]';


--GO
--PRINT N'Refreshing [dbo].[SP_GEN_SEQ_FILE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GEN_SEQ_FILE]';


--GO
--PRINT N'Refreshing [dbo].[SP_GEN_SEQ_FILE_SAFRA]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GEN_SEQ_FILE_SAFRA]';


--GO
--PRINT N'Refreshing [dbo].[SP_GEN_TITLES_TRANS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GEN_TITLES_TRANS]';


--GO
--PRINT N'Refreshing [dbo].[SP_GEN_TITLES_TRANS_POSWEB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GEN_TITLES_TRANS_POSWEB]';


--GO
--PRINT N'Refreshing [dbo].[SP_GEN_TITLES_TRANS_WITH_DATE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GEN_TITLES_TRANS_WITH_DATE]';


--GO
--PRINT N'Refreshing [dbo].[SP_GEN_TITLES_TRANS_WITH_DATE_NEW]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GEN_TITLES_TRANS_WITH_DATE_NEW]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_FD_DATA_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_FD_DATA_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOG_AFF_REG]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOG_AFF_REG]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOGIN_USER_DEV]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOGIN_USER_DEV]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_BRANCH_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_BRANCH_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_BRANCH_COMP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_BRANCH_COMP]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_COMPANY]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_COMPANY]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_OFAC_DATA]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_OFAC_DATA]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_OPERATION_COSTS_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_OPERATION_COSTS_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_PLAN_TAX_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_PLAN_TAX_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_PRODUCTS_COMPANY_EDIT_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_PRODUCTS_COMPANY_EDIT_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SPLIT_PENDING_RETENTATIVE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SPLIT_PENDING_RETENTATIVE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SUBDOMAIN_AFL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SUBDOMAIN_AFL]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TX_PLAN_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TX_PLAN_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TYPE_CONTRACTS_AFFILIADOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TYPE_CONTRACTS_AFFILIADOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TYPE_DOC_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TYPE_DOC_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_SALES_REP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_SALES_REP]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_TRANSACTION_COSTS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_TRANSACTION_COSTS]';


--GO
--PRINT N'Refreshing [dbo].[SP_REGISTER_ADVANCE_SPOT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REGISTER_ADVANCE_SPOT]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_SERVICES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_SERVICES]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_POSWEB_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_POSWEB_TRANSACTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_TAX_ASS_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_TAX_ASS_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_TAX_EC_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_TAX_EC_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_DEPTO_BRANCH]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_DEPTO_BRANCH]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDATE_TERMINAL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDATE_TERMINAL]';


--GO
--PRINT N'Refreshing [dbo].[SP_EXTRACT_CONS_SUB_CLI_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXTRACT_CONS_SUB_CLI_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_REPORT_DETAILS_PAID_EXP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_REPORT_DETAILS_PAID_EXP]';


--GO
--PRINT N'Refreshing [dbo].[SP_ALLOT_REJOIN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ALLOT_REJOIN]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_SCHEDULE_RETENTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_SCHEDULE_RETENTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_RELEASE_TITLES_FROM_RULE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_RELEASE_TITLES_FROM_RULE]';


--GO
--PRINT N'Refreshing [dbo].[SP_RETAIN_TITLES_FROM_DATE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_RETAIN_TITLES_FROM_DATE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LIST_EC_OPEN_LEDGER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LIST_EC_OPEN_LEDGER]';


--GO
--PRINT N'Refreshing [dbo].[SP_FINANCE_CALENDAR_AFFILIATOR_DETAILS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FINANCE_CALENDAR_AFFILIATOR_DETAILS]';


--GO
--PRINT N'Refreshing [dbo].[SP_EXTRACT_CONS_SUB_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXTRACT_CONS_SUB_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_EXTRACT_CONS_TRAN_SUB_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXTRACT_CONS_TRAN_SUB_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_PAYMENT_DIARY_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_PAYMENT_DIARY_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_PAYMENT_DIARY_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_PAYMENT_DIARY_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_FINANCE_SCHEDULE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_FINANCE_SCHEDULE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_FINANCE_SCHEDULE_EC_CERC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_FINANCE_SCHEDULE_EC_CERC]';


--GO
--PRINT N'Refreshing [dbo].[SP_FINANCE_CALENDAR_EC_EXTRACT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FINANCE_CALENDAR_EC_EXTRACT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FINANCE_CALENDAR_EC_EXTRACT_ACC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FINANCE_CALENDAR_EC_EXTRACT_ACC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REP_ACC_DIARY_PAYMENT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REP_ACC_DIARY_PAYMENT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_PENDING_TITLES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_PENDING_TITLES]';


--GO
--PRINT N'Refreshing [dbo].[SP_EXTRACT_QTY_EQUIP_ASS_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXTRACT_QTY_EQUIP_ASS_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_DATA_EQUIP_AC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_DATA_EQUIP_AC]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_DATA_TID_AVAILABLE_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_DATA_TID_AVAILABLE_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REGISTER_ALLOTMENTS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REGISTER_ALLOTMENTS]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_RETENTION_RULES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_RETENTION_RULES]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_VALUE_PAYMENT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_VALUE_PAYMENT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_DATA_BR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_DATA_BR]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_EC_BY_RISK_PERSON]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_EC_BY_RISK_PERSON]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_VERIFY_NEIGH]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_VERIFY_NEIGH]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_CERC_DATA_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_CERC_DATA_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_CITIES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_CITIES]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_NEIGHBORDHOOD]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_NEIGHBORDHOOD]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_NEIGHBORDHOODBYNAME]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_NEIGHBORDHOODBYNAME]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_REQUESTS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_REQUESTS]';


--GO
--PRINT N'Refreshing [dbo].[SP_VERIFY_NEIGH]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VERIFY_NEIGH]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_ADT_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_ADT_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDATE_TRAN_POSWEB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDATE_TRAN_POSWEB]';


--GO
--PRINT N'Refreshing [dbo].[SP_SIMULATE_ANTECIP_SPOT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_SIMULATE_ANTECIP_SPOT]';


--GO
--PRINT N'Refreshing [dbo].[SP_REPORT_CELER_PAY_DETAIL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REPORT_CELER_PAY_DETAIL]';


--GO
--PRINT N'Refreshing [dbo].[SP_DETAILS_PAYMENT_PROTOCOL_GENNERATE_PDF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_PAYMENT_PROTOCOL_GENNERATE_PDF]';


--GO
--PRINT N'Refreshing [dbo].[SP_ADD_TAX_DEPTO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ADD_TAX_DEPTO]';


--GO
--PRINT N'Refreshing [dbo].[SP_ANTICIPATION_BX]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ANTICIPATION_BX]';


--GO
--PRINT N'Refreshing [dbo].[SP_DASH_LEDGER_INFO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DASH_LEDGER_INFO]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_ALL_TITLE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_ALL_TITLE]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_SIMULATED_PARAMS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_SIMULATED_PARAMS]';


--GO
--PRINT N'Refreshing [dbo].[SP_DETAILS_USERS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_USERS]';


--GO
--PRINT N'Refreshing [dbo].[SP_DISABLE_COMMERCIAL_ESTAB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DISABLE_COMMERCIAL_ESTAB]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_APPLIED_TAX_TRAN_DETAILS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_APPLIED_TAX_TRAN_DETAILS]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_DATA_CONTACT_BR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_DATA_CONTACT_BR]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_DEFAULT_EC_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_DEFAULT_EC_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_PROVIDER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_PROVIDER]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_PROVIDER_SPLIT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_PROVIDER_SPLIT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_TX_PLAN_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_TX_PLAN_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_FINANCE_SCHEDULE_GENERATE_ALL_AWAITING_PAYMENT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FINANCE_SCHEDULE_GENERATE_ALL_AWAITING_PAYMENT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FINANCE_SCHEDULE_GENERATE_AWAITING_PAYMENT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FINANCE_SCHEDULE_GENERATE_AWAITING_PAYMENT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FIND_AFF_LOWEST_SPOT_TAX]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FIND_AFF_LOWEST_SPOT_TAX]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_CANCEL_DIARY_EC_PREIPCARD]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_CANCEL_DIARY_EC_PREIPCARD]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_PAYMENT_DIARY_EC_PREIPCARD]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_PAYMENT_DIARY_EC_PREIPCARD]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_PAYMENT_DIARY_EC_REC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_PAYMENT_DIARY_EC_REC]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_REVERSAL_CARDSTOBRANCH_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_REVERSAL_CARDSTOBRANCH_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_GETKEYBYMERSHANT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GETKEYBYMERSHANT]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_ASS_EQUIP_DEPTO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_ASS_EQUIP_DEPTO]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_DISABLE_ASS_EQUIP_DEPTO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_DISABLE_ASS_EQUIP_DEPTO]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_FD_EQUIP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_FD_EQUIP]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_LS_DATA_COMPANY_ECS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_LS_DATA_COMPANY_ECS]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_REG_COMMERCIAL_ESTAB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_REG_COMMERCIAL_ESTAB]';


--GO
--PRINT N'Refreshing [dbo].[SP_GW_REG_PROVIDER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GW_REG_PROVIDER]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOG_MERC_REG]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOG_MERC_REG]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOGIN_USER_MOBILE_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOGIN_USER_MOBILE_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_ANTICIPATION_REQUESTS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_ANTICIPATION_REQUESTS]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_CONTACTS_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_CONTACTS_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_PWDONLINE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_PWDONLINE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_REP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_REP]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_SALES_REP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_SALES_REP]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_USER_ONLINE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_USER_ONLINE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_FINANCIAL_COMPENSATION_PREIPCARD]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_FINANCIAL_COMPENSATION_PREIPCARD]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_PENDING_RISK]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_PENDING_RISK]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SERVICES_AVAILABLE_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SERVICES_AVAILABLE_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TARIFF_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TARIFF_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TRANSACTIONS_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TRANSACTIONS_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_USERS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_USERS]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_BANK_CERC_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_BANK_CERC_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_BANK_CERC_EC_tmp]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_BANK_CERC_EC_tmp]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_COMMERCIAL_ESTAB_SALES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_COMMERCIAL_ESTAB_SALES]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_DOC_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_DOC_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_OFAC_DATA_ANALYSE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_OFAC_DATA_ANALYSE]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_PROVIDER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_PROVIDER]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_REQ_PAY_CARD_BRANCH]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_REQ_PAY_CARD_BRANCH]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_USER_DEVELOPER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_USER_DEVELOPER]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_USER_NEW]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_USER_NEW]';


--GO
--PRINT N'Refreshing [dbo].[SP_REP_VALUE_ANTICIPATE_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REP_VALUE_ANTICIPATE_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_SET_USER_ACCESS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_SET_USER_ACCESS]';


--GO
--PRINT N'Refreshing [dbo].[SP_SHUFFLE_SENS_DATA]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_SHUFFLE_SENS_DATA]';


--GO
----PRINT N'Refreshing [dbo].[SP_UP_DATA_BR]...';


----GO
----EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_DATA_BR]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_PROFILE_ACCESS_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_PROFILE_ACCESS_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_SET_DEFAULT_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_SET_DEFAULT_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_SIT_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_SIT_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_DOCS_BRANCH_TICKET]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_DOCS_BRANCH_TICKET]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_DOCS_BRANCH_TICKET_DEV]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_DOCS_BRANCH_TICKET_DEV]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_STATUS_DOCS_TICKET]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_STATUS_DOCS_TICKET]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_TAX_AFF]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_TAX_AFF]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_TAX_AFF_EXP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_TAX_AFF_EXP]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_TAX_AFFILIATOR_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_TAX_AFFILIATOR_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDADE_LOGIN_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDADE_LOGIN_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_ECS_ELO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_ECS_ELO]';


--GO
--PRINT N'Refreshing [dbo].[SP_DETAILS_PAYMENT_PROTOCOL_TITLES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_PAYMENT_PROTOCOL_TITLES]';


--GO
--PRINT N'Refreshing [dbo].[SP_EXTRACT_AMOUNT_TTYPE_TRANNSATION_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXTRACT_AMOUNT_TTYPE_TRANNSATION_EC]';


--GO
----PRINT N'Refreshing [dbo].[SP_EXTRACT_CONS_SUB]...';


----GO
----EXECUTE sp_refreshsqlmodule N'[dbo].[SP_EXTRACT_CONS_SUB]';


--GO
----PRINT N'Refreshing [dbo].[SP_REP_EXTRACT_CALENDAR_DETAILS]...';


----GO
----EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REP_EXTRACT_CALENDAR_DETAILS]';


--GO
----PRINT N'Refreshing [dbo].[SP_DETAILS_PAYMENT_PROTOCOL_TARIFF_ADJ]...';


----GO
----EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_PAYMENT_PROTOCOL_TARIFF_ADJ]';


--GO
--PRINT N'Refreshing [dbo].[SP_DETAILS_FINANCE_CALENDAR_TAFIFF_ADJ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DETAILS_FINANCE_CALENDAR_TAFIFF_ADJ]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_COST_FILE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_COST_FILE]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_TX_DEP_BR_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_TX_DEP_BR_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_TRAN_ELO]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_TRAN_ELO]';


--GO
--PRINT N'Refreshing [dbo].[SP_GENERATE_PAYMENT_COMPEN_CARD_BR_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_GENERATE_PAYMENT_COMPEN_CARD_BR_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_ASS_DEPTO_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_ASS_DEPTO_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_DATA_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_DATA_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_PLANS_SALES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_PLANS_SALES]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_PLAN_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_PLAN_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_PLAN_DEPARTS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_PLAN_DEPARTS]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TX_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TX_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_DATA_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_DATA_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDATE_AFFILIATED_EC_PLAN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDATE_AFFILIATED_EC_PLAN]';


--GO
--PRINT N'Refreshing [dbo].[SP_MARK_TITLES_AS_AVAILABLE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_MARK_TITLES_AS_AVAILABLE]';


--GO
--PRINT N'Refreshing [dbo].[SP_MARK_TITLES_AS_RETAINED]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_MARK_TITLES_AS_RETAINED]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_FINANCIAL_FILE_SEQ_DISSOCIATION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_FINANCIAL_FILE_SEQ_DISSOCIATION]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_RELEASE_ADJ]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_RELEASE_ADJ]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_RELEASE_ADJ_AFFL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_RELEASE_ADJ_AFFL]';


--GO
--PRINT N'Refreshing [dbo].[SP_RETAIN_POSITIVE_RELEASE_PARTIAL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_RETAIN_POSITIVE_RELEASE_PARTIAL]';


--GO
--PRINT N'Refreshing [dbo].[SP_UNLINK_FINANCE_SCHEDULE_FILE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UNLINK_FINANCE_SCHEDULE_FILE]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_GENERATE_PAYMENT_DIARY_EC_LOW_PAYMENT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_GENERATE_PAYMENT_DIARY_EC_LOW_PAYMENT]';


--GO
--PRINT N'Refreshing [dbo].[SP_CONC_REPROCESS_SIT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_CONC_REPROCESS_SIT]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_CASH_FLOW_TERMINAL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_CASH_FLOW_TERMINAL]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_EC_TRANSACTION_POS_WEB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_EC_TRANSACTION_POS_WEB]';


--GO
--PRINT N'Refreshing [dbo].[SP_CANCEL_TARIFF_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_CANCEL_TARIFF_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_TARIFF_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_TARIFF_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_TARIFF_EC_DEV]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_TARIFF_EC_DEV]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_REPORT_STATUS_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_REPORT_STATUS_TRANSACTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_DASH_TRAN_BY_BRAND]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DASH_TRAN_BY_BRAND]';


--GO
--PRINT N'Refreshing [dbo].[SP_DATA_TRANSAC_ONL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DATA_TRANSAC_ONL]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_LOW_CONSULTING_TITLES]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_LOW_CONSULTING_TITLES]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_DATA_EXT_TR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_DATA_EXT_TR]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_DATA_EXT_TR_ON]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_DATA_EXT_TR_ON]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_HIST_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_HIST_TRANSACTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ITEM_TITTLE_CONC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ITEM_TITTLE_CONC]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ITEMS_CONC_CANCELED]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ITEMS_CONC_CANCELED]';


--GO
--PRINT N'Refreshing [dbo].[SP_REPORT_TOTALSPOT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REPORT_TOTALSPOT]';


--GO
--PRINT N'Refreshing [dbo].[SP_RETURN_STATUS_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_RETURN_STATUS_TRANSACTION]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_SPLIT_PENDING]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_SPLIT_PENDING]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_Adjustment_Credit_Debit]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_Adjustment_Credit_Debit]';


--GO
--PRINT N'Refreshing [dbo].[SP_REM_ASSIGN_FILE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REM_ASSIGN_FILE]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_ASSIGN_FILE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_ASSIGN_FILE]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_HIST_TRAN_TITLE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_HIST_TRAN_TITLE]';


--GO
--PRINT N'Refreshing [dbo].[SP_RETAIN_TITLE_PARTIAL]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_RETAIN_TITLE_PARTIAL]';


--GO
--PRINT N'Refreshing [dbo].[SP_CLEAR_REG_ACCESS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_CLEAR_REG_ACCESS]';


--GO
--PRINT N'Refreshing [dbo].[SP_DISCONNECT_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DISCONNECT_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_DISCONNECT_USER_TK_EXP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_DISCONNECT_USER_TK_EXP]';


--GO
--PRINT N'Refreshing [dbo].[SP_FD_DATA_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_FD_DATA_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_INITIAL_ACCESS_SECOND_FACTOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_INITIAL_ACCESS_SECOND_FACTOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOG_USER_REG]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOG_USER_REG]';


--GO
--PRINT N'Refreshing [dbo].[SP_LOGIN_BCK_HDN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LOGIN_BCK_HDN]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_ALL_USERS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_ALL_USERS]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_FUNCTIONALITIES_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_FUNCTIONALITIES_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_REP]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_REP]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_REQUESTS_SIT]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_REQUESTS_SIT]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SUP_TIC_USER_QUEUE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SUP_TIC_USER_QUEUE]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SUPPORT_TICKET_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SUPPORT_TICKET_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_SUPPORT_TICKET_HISTORY]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_SUPPORT_TICKET_HISTORY]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_TOKEN_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_TOKEN_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_DENIED_ACCESS_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_DENIED_ACCESS_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_MESSAGING]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_MESSAGING]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_SEC_FACTOR_PASS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_SEC_FACTOR_PASS]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_TOKEN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_TOKEN]';


--GO
--PRINT N'Refreshing [dbo].[SP_REG_USER_DEV]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_REG_USER_DEV]';


--GO
--PRINT N'Refreshing [dbo].[SP_UNLOCK_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UNLOCK_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_ACTIVE_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_ACTIVE_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_DATA_SALES_REPRESENTATIVE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_DATA_SALES_REPRESENTATIVE]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_DATA_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_DATA_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_VAL_CPF_USER_AVAILABLE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VAL_CPF_USER_AVAILABLE]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDADE_EMAIL_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDADE_EMAIL_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDADE_PASS_PROV]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDADE_PASS_PROV]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDADE_PASS_PROV_LOGIN]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDADE_PASS_PROV_LOGIN]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDATE_USERNAME]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDATE_USERNAME]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_HISTORY_EC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_HISTORY_EC]';


--GO
--PRINT N'Refreshing [dbo].[SP_LS_REQ_USER]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_LS_REQ_USER]';


--GO
--PRINT N'Refreshing [dbo].[SP_UPDATE_AFFILIATOR]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UPDATE_AFFILIATOR]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDATE_TRANSACTION_POSWEB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDATE_TRANSACTION_POSWEB]';


--GO
--PRINT N'Refreshing [dbo].[SP_UPDATE_SERIAL_DATA_AC]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UPDATE_SERIAL_DATA_AC]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_TRANSACTION_POSWEB]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_TRANSACTION_POSWEB]';


--GO
--PRINT N'Refreshing [dbo].[SP_UP_TRANSACTION_WITH_DATE]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UP_TRANSACTION_WITH_DATE]';


--GO
--PRINT N'Refreshing [dbo].[SP_UPDATE_CELER_PAY_STATUS]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_UPDATE_CELER_PAY_STATUS]';


--GO
--PRINT N'Refreshing [dbo].[SP_VALIDATE_TRANSACTION]...';


--GO
--EXECUTE sp_refreshsqlmodule N'[dbo].[SP_VALIDATE_TRANSACTION]';


GO

GO
IF OBJECT_ID('ORDER_STEPS') IS NOT NULL DROP TABLE ORDER_STEPS
GO
IF OBJECT_ID('DELIVERY_ADDRESS') IS NOT NULL DROP TABLE DELIVERY_ADDRESS;
GO
IF OBJECT_ID('SELL_ORDER') IS NOT NULL DROP TABLE SELL_ORDER;
GO
IF OBJECT_ID('TRANSIRE_PRODUCT') IS NOT NULL DROP TABLE TRANSIRE_PRODUCT;
GO
IF OBJECT_ID('ORDER_ITEM') IS NOT NULL DROP TABLE ORDER_ITEM;
GO
IF OBJECT_ID('[PRODUCTS_AFFILIATOR]') IS NOT NULL DROP TABLE [PRODUCTS_AFFILIATOR];
GO
IF OBJECT_ID('PRODUCTS_COMPANY') IS NOT NULL DROP TABLE PRODUCTS_COMPANY;
GO
IF OBJECT_ID('[PRODUCTS]') IS NOT NULL DROP TABLE [PRODUCTS];
GO
IF OBJECT_ID('PRODUCTS') IS NULL
CREATE TABLE [dbo].[PRODUCTS](
	[COD_PRODUCT] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NULL,
	[PRODUCT_NAME] [varchar](200) NULL,
	[NICKNAME] [varchar](200) NULL,
	[DESCRIPTION] [nvarchar](max) NULL,
	[SKU] [varchar](255) NULL,
	[PRICE] [decimal](22, 8) NULL,
	[ACTIVE] [int] NULL,
	[COD_AFFILIATOR] [int] NULL,
	[COD_MODEL] [int] NULL,
	[COD_USER] [int] NULL,
	[ALTER_DATE] [datetime] NULL,
	[COD_USER_ALTER] [int] NULL,
	[COD_SITUATION] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_PRODUCT] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

--ALTER TABLE [dbo].[PRODUCTS] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
--GO

ALTER TABLE [dbo].[PRODUCTS] ADD  CONSTRAINT [DF_CONSTRAINT_PROD_ACTIVE]  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_AFFILIATOR])
REFERENCES [dbo].[AFFILIATOR] ([COD_AFFILIATOR])
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_MODEL])
REFERENCES [dbo].[EQUIPMENT_MODEL] ([COD_MODEL])
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD  CONSTRAINT [FK__PRODUCTS__COD_SI__08D61451] FOREIGN KEY([COD_SITUATION])
REFERENCES [dbo].[SITUATION] ([COD_SITUATION])
GO

ALTER TABLE [dbo].[PRODUCTS] CHECK CONSTRAINT [FK__PRODUCTS__COD_SI__08D61451]
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_USER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_USER_ALTER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

GO

/****** Object:  Table [dbo].[ORDER_ITEM]    Script Date: 27/04/2020 09:30:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TRANSIRE_PRODUCT](
	[COD_TRANSIRE_PRD] [int] IDENTITY(1,1) NOT NULL,
	[SKU] [varchar](255) NULL,
	[AMOUNT] [decimal](22, 6) NULL,
	[ACTIVE] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_TRANSIRE_PRD] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TRANSIRE_PRODUCT] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('238472398', 900.000000, 1);
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('23423423', 900.000000, 1);
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('6077324STELO', 900.000000, 1);
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('6068334STELO', 900.000000, 1);

IF OBJECT_ID('ORDER_ITEM') IS NULL
CREATE TABLE [dbo].[ORDER_ITEM](
	[COD_ODR_ITEM] [int] IDENTITY(1,1) NOT NULL,
	[PRICE] [decimal](22, 6) NOT NULL,
	[QUANTITY] [int] NOT NULL,
	[COD_ODR] [int] NOT NULL,
	[CHIP] [varchar](256) NOT NULL,
	[COD_PRODUCT] [int] NULL,
	[COD_OPERATOR] [int] NULL,
	[COD_TRANSIRE_PRD] [int] NULL,
 CONSTRAINT [PK_ORDER_ITEM] PRIMARY KEY NONCLUSTERED 
(
	[COD_ODR_ITEM] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ORDER_ITEM]  WITH CHECK ADD FOREIGN KEY([COD_OPERATOR])
REFERENCES [dbo].[CELL_OPERATOR] ([COD_OPER])
GO

ALTER TABLE [dbo].[ORDER_ITEM]  WITH CHECK ADD FOREIGN KEY([COD_PRODUCT])
REFERENCES [dbo].[PRODUCTS] ([COD_PRODUCT])
GO

ALTER TABLE [dbo].[ORDER_ITEM]  WITH CHECK ADD FOREIGN KEY([COD_TRANSIRE_PRD])
REFERENCES [dbo].[TRANSIRE_PRODUCT] ([COD_TRANSIRE_PRD])
GO
/****** Object:  Table [dbo].[TRANSIRE_PRODUCT]    Script Date: 27/04/2020 09:39:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

GO


IF OBJECT_ID('[SP_VERIFY_SKU]') IS NOT NULL
DROP PROCEDURE [SP_VERIFY_SKU];
GO
/****** Object:  UserDefinedTableType [dbo].[TP_SKU]    Script Date: 03/05/2020 17:12:56 ******/
CREATE TYPE [dbo].[TP_SKU] AS TABLE(
	[SKU] [varchar](255) NULL
)
GO



GO

CREATE PROCEDURE [SP_VERIFY_SKU](
	@CODE [TP_SKU] READONLY)
AS
BEGIN

SELECT
	[CODE].[SKU]
FROM @CODE AS [CODE]
LEFT JOIN [TRANSIRE_PRODUCT]
	ON [CODE].[SKU] = [TRANSIRE_PRODUCT].[SKU]
		AND [TRANSIRE_PRODUCT].ACTIVE = 1
WHERE [TRANSIRE_PRODUCT].[COD_TRANSIRE_PRD] IS NULL;

END;

GO


IF OBJECT_ID('[SP_FD_INFO_TO_REVERSE_LOGISTIC]') IS NOT NULL
DROP PROCEDURE [SP_FD_INFO_TO_REVERSE_LOGISTIC];
GO

CREATE PROCEDURE [SP_FD_INFO_TO_REVERSE_LOGISTIC]  
--'celer_20232'  
(
	@ORDER_NUMBER VARCHAR(255))
AS
BEGIN
SELECT
	'(' + [CONTACT_BRANCH].[DDI] + ') ' + [CONTACT_BRANCH].[DDD] + ' ' + [CONTACT_BRANCH].[NUMBER] AS 'PHONE_NUMBER'
   ,[COMMERCIAL_ESTABLISHMENT].[STATE_REGISTRATION]
   ,[COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ]
   ,[COMMERCIAL_ESTABLISHMENT].[EMAIL]
   ,[COMMERCIAL_ESTABLISHMENT].[TRADING_NAME]
   ,[COMMERCIAL_ESTABLISHMENT].[NAME] AS 'EC_NAME'
   ,[TYPE_ESTAB].[CODE] AS 'TYPE_EC'
   ,[SEX_TYPE].[CODE] AS 'SEX_EC'
   ,[ADDRESS_BRANCH].[ADDRESS]
   ,[NEIGHBORHOOD].[NAME]
   ,[ADDRESS_BRANCH].[CEP]
   ,[COMPLEMENT]
   ,STATE.[UF]
   ,[ADDRESS_BRANCH].[ADDRESS]
   ,[CITY].[NAME] AS [CITY]
   ,[ADDRESS_BRANCH].[NUMBER]
   ,[COUNTRY].[INITIALS]
   ,[ORDER].[AMOUNT]
   ,[TRANSACTION].[CODE] AS [NSU]
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [ORDER]
	ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [CONTACT_BRANCH]
	ON [CONTACT_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [CONTACT_BRANCH].[ACTIVE] = 1
INNER JOIN [TYPE_CONTACT]
	ON [TYPE_CONTACT].[COD_TP_CONT] = [CONTACT_BRANCH].[COD_TP_CONT]
INNER JOIN [ADDRESS_BRANCH]
	ON [ADDRESS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [ADDRESS_BRANCH].[ACTIVE] = 1
INNER JOIN [SEX_TYPE]
	ON [SEX_TYPE].[COD_SEX] = [COMMERCIAL_ESTABLISHMENT].[COD_SEX]
INNER JOIN [TYPE_ESTAB]
	ON [TYPE_ESTAB].[COD_TYPE_ESTAB] = [COMMERCIAL_ESTABLISHMENT].[COD_TYPE_ESTAB]
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ADDRESS_BRANCH].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN [STATE]
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].[COD_TRAN] = [ORDER].[COD_TRAN]
WHERE [ORDER].[PICKING_ORDER] = @ORDER_NUMBER
AND [TYPE_CONTACT].[NAME] = 'CELULAR';
--SELECT * FROM TYPE_CONTACT
END;

GO

CREATE TABLE [dbo].[WL_COLORS](
	[COD_WL_COLORS] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_WL_COLORS] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

--/****** Object:  Table [dbo].[WL_CONTENT_TYPE]    Script Date: 27/04/2020 15:21:06 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--CREATE TABLE [dbo].[WL_CONTENT_TYPE](
--	[COD_WL_CONT_TYPE] [int] IDENTITY(1,1) NOT NULL,
--	[CODE] [varchar](255) NOT NULL,
--	[DESCRIPTION] [varchar](255) NOT NULL,
--PRIMARY KEY CLUSTERED 
--(
--	[COD_WL_CONT_TYPE] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY]
--GO
/****** Object:  Table [dbo].[WL_CUSTOM_TEXT]    Script Date: 27/04/2020 15:21:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WL_CUSTOM_TEXT](
	[COD_WL_CUSTOM_TEXT] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](255) NOT NULL,
	[DESCRIPTION] [varchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_WL_CUSTOM_TEXT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[WL_COLORS] ON

INSERT [dbo].[WL_COLORS] ([COD_WL_COLORS], [CODE])
	VALUES (1, N'PRIMARY')
INSERT [dbo].[WL_COLORS] ([COD_WL_COLORS], [CODE])
	VALUES (2, N'AUXILIARY')
INSERT [dbo].[WL_COLORS] ([COD_WL_COLORS], [CODE])
	VALUES (3, N'HIGHLIGHT')
INSERT [dbo].[WL_COLORS] ([COD_WL_COLORS], [CODE])
	VALUES (4, N'HIGHLIGHT TEXT')
SET IDENTITY_INSERT [dbo].[WL_COLORS] OFF
SET IDENTITY_INSERT [dbo].[WL_CUSTOM_TEXT] ON

INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (1, N'TXT_ABOUT01', N'1º TÍTULO DO SOBRE NÓS')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (2, N'TXT_ABOUT02', N'1º CONTEÚDO DO SOBRE NÓS')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (3, N'TXT_ABOUT03', N'2º TÍTULO DO SOBRE NÓS')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (4, N'TXT_ABOUT04', N'2º CONTEÚDO DO SOBRE NÓS')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (5, N'TXT_ABOUT05', N'3º CONTEÚDO DO SOBRE NÓS')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (18, N'TXT_BENEFITS01', N'1º TÍTULO DO BENEFÍCIO')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (19, N'TXT_BENEFITS02', N'1º CONTEÚDO DO BENEFÍCIO')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (20, N'TXT_BENEFITS03', N'2º TÍTULO DO BENEFÍCIO')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (21, N'TXT_BENEFITS04', N'2º CONTEÚDO DO BENEFÍCIO')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (22, N'TXT_BENEFITS05', N'3º TÍTULO DO BENEFÍCIO')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (23, N'TXT_BENEFITS06', N'3º CONTEÚDO DO BENEFÍCIO')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (24, N'TXT_CONTACT_EMAIL', N'EMAIL DE CONTATO PARA SUPORTE')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (25, N'TXT_CONTACT_PHONE', N'TELEFONE DE CONTATO PARA SUPORTE')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (26, N'TXT_CONTACT_EMAIL_AVAILABILITY', N'DISPONIBILIDADE DE CONTATO PARA SUPORTE VIA EMAIL')
INSERT [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT], [CODE], [DESCRIPTION])
	VALUES (27, N'TXT_CONTACT_PHONE_AVAILABILITY', N'DISPONIBILIDADE DE CONTATO PARA SUPORTE VIA TELEFONE')
SET IDENTITY_INSERT [dbo].[WL_CUSTOM_TEXT] OFF

GO

ALTER TABLE [PLAN] ADD AVAILABLE_SALE INT;
GO
CREATE PROCEDURE [dbo].[SP_FD_ECOMMERCE_COLORS]

	/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_FD_ECOMMERCE_COLORS]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para buscar imagens do Ecommerce
------------------------------------------------------------------------------------------*/

	(
	@COD_AFFILIATOR INT
)
AS
BEGIN

SELECT
	COLORS.COD_WL_COLORS
   ,COLORS.COLOR
   ,WL_COLORS.CODE
FROM ECOMMERCE_THEMES_COLORS COLORS
JOIN WL_COLORS
	ON WL_COLORS.COD_WL_COLORS = COLORS.COD_WL_COLORS
WHERE ACTIVE = 1
AND COD_AFFILIATOR = @COD_AFFILIATOR;

END;
GO
/****** Object:  StoredProcedure [dbo].[SP_FD_ECOMMERCE_IMG]    Script Date: 27/04/2020 15:27:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[SP_FD_ECOMMERCE_IMG]

	/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_FD_ECOMMERCE_IMG]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para buscar imagens do Ecommerce
------------------------------------------------------------------------------------------*/

	(
	@COD_AFFILIATOR INT
)
AS
BEGIN

SELECT
	IMG.COD_WL_CONT_TYPE
   ,IMG.PATH_CONTENT
   ,WL_CONTENT_TYPE.CODE
FROM ECOMMERCE_THEMES_IMG IMG
JOIN WL_CONTENT_TYPE
	ON WL_CONTENT_TYPE.COD_WL_CONT_TYPE = IMG.COD_WL_CONT_TYPE
WHERE ACTIVE = 1
AND COD_AFFILIATOR = @COD_AFFILIATOR;

END;
GO
/****** Object:  StoredProcedure [dbo].[SP_FD_ECOMMERCE_PLAN]    Script Date: 27/04/2020 15:27:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[SP_FD_ECOMMERCE_PLAN]  
  
/*******************************************************************************************  
----------------------------------------------------------------------------------------    
Procedure Name: [SP_FD_ECOMMERCE_PLAN]    

go


Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author              VERSION        Date      Description    
------------------------------------------------------------------------------------------    
Lucas Aguiar  v1      2019-11-22    Procedure para a busca do plano - ecommerce  
------------------------------------------------------------------------------------------  
*******************************************************************************************/  
  
(  
 @COD_AFFILIATOR INT)  
AS  
    BEGIN
WITH CTE
AS
(SELECT
		[PLAN].COD_PLAN
	   ,[CODE]
	   ,[DESCRIPTION]
	   ,[COD_T_PLAN]
	   ,[ANTICIPATION_PERCENTAGE]
	   ,[PARCENTAGE]
	   ,[INTERVAL]
	   ,'D' AS [type]
	FROM [TAX_PLAN]
	JOIN [PLAN]
		ON [PLAN].[COD_PLAN] = [TAX_PLAN].[COD_PLAN]
	WHERE [COD_TTYPE] = 2
	AND [QTY_INI_PLOTS] = 1
	AND [QTY_FINAL_PLOTS] = 1
	AND [COD_AFFILIATOR] = @COD_AFFILIATOR
	AND [AVAILABLE_SALE] = 1
	AND [PLAN].[ACTIVE] = 1
	GROUP BY [PLAN].COD_PLAN
			,[CODE]
			,[DESCRIPTION]
			,[COD_T_PLAN]
			,[ANTICIPATION_PERCENTAGE]
			,[PARCENTAGE]
			,[INTERVAL]
	UNION
	SELECT
		[PLAN].COD_PLAN
	   ,[CODE]
	   ,[DESCRIPTION]
	   ,[COD_T_PLAN]
	   ,[ANTICIPATION_PERCENTAGE]
	   ,[PARCENTAGE]
	   ,[INTERVAL]
	   ,'C' AS [type]
	FROM [TAX_PLAN]
	JOIN [PLAN]
		ON [PLAN].[COD_PLAN] = [TAX_PLAN].[COD_PLAN]
	WHERE [COD_TTYPE] = 1
	AND [QTY_INI_PLOTS] = 1
	AND [QTY_FINAL_PLOTS] = 1
	AND [COD_AFFILIATOR] = @COD_AFFILIATOR
	AND [AVAILABLE_SALE] = 1
	AND [PLAN].[ACTIVE] = 1
	GROUP BY [PLAN].COD_PLAN
			,[CODE]
			,[DESCRIPTION]
			,[COD_T_PLAN]
			,[ANTICIPATION_PERCENTAGE]
			,[PARCENTAGE]
			,[INTERVAL]
	UNION
	SELECT
		[PLAN].COD_PLAN
	   ,[CODE]
	   ,[DESCRIPTION]
	   ,[COD_T_PLAN]
	   ,[ANTICIPATION_PERCENTAGE]
	   ,[PARCENTAGE]
	   ,[INTERVAL]
	   ,'P' AS [type]
	FROM [TAX_PLAN]
	JOIN [PLAN]
		ON [PLAN].[COD_PLAN] = [TAX_PLAN].[COD_PLAN]
	WHERE [COD_TTYPE] = 1
	AND [QTY_INI_PLOTS] = 2
	AND [QTY_FINAL_PLOTS] = 12
	AND [COD_AFFILIATOR] = @COD_AFFILIATOR
	AND [AVAILABLE_SALE] = 1
	AND [PLAN].[ACTIVE] = 1
	GROUP BY [PLAN].COD_PLAN
			,[CODE]
			,[DESCRIPTION]
			,[COD_T_PLAN]
			,[ANTICIPATION_PERCENTAGE]
			,[PARCENTAGE]
			,[INTERVAL])
SELECT
	*
FROM [CTE]
ORDER BY [CTE].[COD_T_PLAN];


END;
GO
/****** Object:  StoredProcedure [dbo].[SP_FD_ECOMMERCE_PRODUCT]    Script Date: 27/04/2020 15:27:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[SP_FD_ECOMMERCE_PRODUCT]    
    
/*********************************************************************************************  
----------------------------------------------------------------------------------------      
Procedure Name: [SP_FD_ECOMMERCE_PRODUCT]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author              VERSION        Date      Description      
------------------------------------------------------------------------------------------      
Lucas Aguiar  v1      2019-11-19    Procedure para busca de produtos    
------------------------------------------------------------------------------------------  
*********************************************************************************************/    
    
(  
 @COD_AFFILIATOR INT)  
AS  
BEGIN
SELECT
	[P].COD_MODEL
   ,[P].[COD_PRODUCT]
   ,[P].[PRODUCT_NAME]
   ,[P].[PRICE]
   ,[P].[SKU]
   ,[ETI].[PATH_CONTENT]
   ,[ETI].[COD_WL_CONT_TYPE]
   ,[EQUIPMENT_MODEL].[CODIGO]
FROM [PRODUCTS] AS [P]
JOIN [ECOMMERCE_THEMES_IMG] AS [ETI]
	ON [ETI].[COD_AFFILIATOR] = [P].[COD_AFFILIATOR]
		AND [ETI].[COD_MODEL] = [P].[COD_MODEL]
		AND [ETI].[ACTIVE] = 1
JOIN [EQUIPMENT_MODEL]
	ON [EQUIPMENT_MODEL].[COD_MODEL] = [ETI].[COD_MODEL]
WHERE [P].[COD_AFFILIATOR] = @COD_AFFILIATOR
AND [P].[ACTIVE] = 1;
END;



GO
/****** Object:  StoredProcedure [dbo].[SP_FD_ECOMMERCE_TEXTS]    Script Date: 27/04/2020 15:27:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[SP_FD_ECOMMERCE_TEXTS]

	/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_FD_ECOMMERCE_COLORS]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para buscar os textos do Ecommerce
------------------------------------------------------------------------------------------*/

(
	@COD_AFFILIATOR INT
)
AS
BEGIN

SELECT
	[CONTENT].COD_WL_CUSTOM_TEXT
   ,[CONTENT].[TEXT]
   ,WL_CUSTOM_TEXT.CODE
FROM ECOMMERCE_THEMES_TEXT [CONTENT]
JOIN WL_CUSTOM_TEXT
	ON WL_CUSTOM_TEXT.COD_WL_CUSTOM_TEXT = [CONTENT].COD_WL_CUSTOM_TEXT
WHERE ACTIVE = 1
AND COD_AFFILIATOR = @COD_AFFILIATOR;

END;
GO
ALTER TABLE AFFILIATOR ADD WHITELABEL_URL VARCHAR(200)

GO

alter PROCEDURE [dbo].[SP_LS_AFFILIATOR_INFO]  
/*----------------------------------------------------------------------------------------  
Procedure Name: SP_LS_AFFILIATOR_COMP  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Luiz Aquino                     V1            20/09/2018                           CREATION  
Luiz Aquino                     v2            04/07/2019                bank is_cerc  
------------------------------------------------------------------------------------------*/  
(  
    @CodAff INT  
)  
AS  
BEGIN

SET NOCOUNT ON

SELECT
	af.COD_ADR_AFL [AddrCod]
   ,af.COD_AFFILIATOR [AddrCodAff]
   ,af.CREATED_AT [AddrCreated]
   ,af.COD_USER_CAD [AddrUserCad]
   ,af.[ADDRESS] [AddrStreet]
   ,af.NUMBER [AddrNumber]
   ,af.COMPLEMENT [AddrComp]
   ,af.CEP [AddrCep]
   ,af.COD_NEIGH [AddrNeighCod]
   ,c.COD_CITY [AddrCityCod]
   ,s.COD_STATE [AddrStateCod]
   ,s.COD_COUNTRY [AddrCountryCod]
   ,af.ACTIVE [AddrActive]
   ,af.MODIFY_DATE [AddrModified]
   ,af.COD_USER_ALT [AddUserAltCod]
   ,af.REFERENCE_POINT [AddrReference]
   ,ac.COD_CONTACT_AFL [ContactCod]
   ,ac.COD_AFFILIATOR [ContactCodAff]
   ,ac.CREATED_AT [ContactCreated]
   ,ac.COD_USER_CAD [ContactUserCad]
   ,ac.NUMBER [ContactNumber]
   ,ac.COD_TP_CONT [ContactType]
   ,ac.COD_OPER [ContactOper]
   ,ac.MODIFY_DATE [ContactModified]
   ,ac.COD_USER_ALT [ContactUserAlt]
   ,ac.DDI [ContactDdi]
   ,ac.DDD [ContactDdd]
   ,ac.ACTIVE [ContactActive]
   ,bd.COD_BK_EC [BankCod]
   ,c.[NAME] [BankName]
   ,bd.CREATED_AT [BankCreated]
   ,bd.AGENCY [BankAgency]
   ,bd.DIGIT_AGENCY [BankAgencyDigit]
   ,bd.ACCOUNT [BankAccount]
   ,ISNULL(bd.DIGIT_ACCOUNT, '') [BankAccountDigit]
   ,bd.COD_BANK [BankCodBank]
   ,bd.COD_USER [BankCodUser]
   ,bd.ACTIVE [BankActive]
   ,bd.MODIFY_DATE [BankModified]
   ,bd.COD_TYPE_ACCOUNT [BankAccountTypeCod]
   ,act.[NAME] [BankAccountType]
   ,bd.COD_OPER_BANK [BankAccountOp]
   ,bd.COD_BRANCH [BankBranchCod]
   ,bd.COD_AFFILIATOR [BankAffiliatorCod]
   ,pca.COD_TYPE_PROG [AffProgressiveCod]
   ,a.WHITELABEL_URL [WhiteLabelUrl]
FROM AFFILIATOR a
JOIN ADDRESS_AFFILIATOR af
	ON af.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND af.ACTIVE = 1
JOIN NEIGHBORHOOD n
	ON n.COD_NEIGH = af.COD_NEIGH
JOIN CITY c
	ON c.COD_CITY = n.COD_CITY
JOIN [STATE] s
	ON s.COD_STATE = c.COD_STATE
JOIN AFFILIATOR_CONTACT ac
	ON ac.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND ac.ACTIVE = 1
JOIN BANK_DETAILS_EC bd
	ON bd.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND bd.COD_EC IS NULL
		AND bd.ACTIVE = 1
		AND bd.IS_CERC = 0
JOIN BANKS b
	ON b.COD_BANK = bd.COD_BANK
JOIN ACCOUNT_TYPE act
	ON act.COD_TYPE_ACCOUNT = bd.COD_TYPE_ACCOUNT
JOIN PROGRESSIVE_COST_AFFILIATOR pca
	ON pca.COD_AFFILIATOR = a.COD_AFFILIATOR
WHERE a.COD_AFFILIATOR = @CodAff
END;

GO

/****** Object:  Table [dbo].[ECOMMERCE_THEMES_COLORS]    Script Date: 03/05/2020 16:17:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ECOMMERCE_THEMES_COLORS](
	[COD_ECOMMERCE_COLORS] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NOT NULL,
	[MODIFY_DATE] [datetime] NULL,
	[COD_USER_CAD] [int] NOT NULL,
	[COD_USER_ALT] [int] NULL,
	[ACTIVE] [int] NOT NULL,
	[COD_AFFILIATOR] [int] NOT NULL,
	[COD_WL_COLORS] [int] NOT NULL,
	[COLOR] [varchar](400) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_ECOMMERCE_COLORS] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_COLORS] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_COLORS] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_COLORS]  WITH CHECK ADD FOREIGN KEY([COD_AFFILIATOR])
REFERENCES [dbo].[AFFILIATOR] ([COD_AFFILIATOR])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_COLORS]  WITH CHECK ADD FOREIGN KEY([COD_USER_CAD])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_COLORS]  WITH CHECK ADD FOREIGN KEY([COD_USER_ALT])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_COLORS]  WITH CHECK ADD FOREIGN KEY([COD_WL_COLORS])
REFERENCES [dbo].[WL_COLORS] ([COD_WL_COLORS])
GO



SET IDENTITY_INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ON

INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (1, CAST(N'2020-01-24T17:47:49.527' AS DATETIME), NULL, 173, NULL, 1, 128, 1, N'#04B7FB')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (2, CAST(N'2020-01-24T17:47:49.527' AS DATETIME), NULL, 173, NULL, 1, 128, 3, N'#7ADAFF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (3, CAST(N'2020-01-24T17:47:49.527' AS DATETIME), NULL, 173, NULL, 1, 128, 2, N'#04B7FB')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (4, CAST(N'2020-01-28T17:08:08.043' AS DATETIME), CAST(N'2020-01-28T17:12:05.710' AS DATETIME), 287, 287, 0, 171, 1, N'#1F2A69CC')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (5, CAST(N'2020-01-28T17:08:08.043' AS DATETIME), CAST(N'2020-01-28T17:12:05.710' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (6, CAST(N'2020-01-28T17:08:08.043' AS DATETIME), CAST(N'2020-01-28T17:12:05.710' AS DATETIME), 287, 287, 0, 171, 2, N'#EF281A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (7, CAST(N'2020-01-28T17:12:05.717' AS DATETIME), CAST(N'2020-01-28T17:59:33.940' AS DATETIME), 287, 287, 0, 171, 1, N'#13457B')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (8, CAST(N'2020-01-28T17:12:05.717' AS DATETIME), CAST(N'2020-01-28T17:59:33.940' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (9, CAST(N'2020-01-28T17:12:05.717' AS DATETIME), CAST(N'2020-01-28T17:59:33.940' AS DATETIME), 287, 287, 0, 171, 2, N'#EF281A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (10, CAST(N'2020-01-28T17:59:33.943' AS DATETIME), CAST(N'2020-01-28T18:06:07.077' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (11, CAST(N'2020-01-28T17:59:33.943' AS DATETIME), CAST(N'2020-01-28T18:06:07.077' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (12, CAST(N'2020-01-28T17:59:33.943' AS DATETIME), CAST(N'2020-01-28T18:06:07.077' AS DATETIME), 287, 287, 0, 171, 4, N'#000000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (13, CAST(N'2020-01-28T17:59:33.943' AS DATETIME), CAST(N'2020-01-28T18:06:07.077' AS DATETIME), 287, 287, 0, 171, 2, N'#EF281A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (14, CAST(N'2020-01-28T18:06:07.080' AS DATETIME), CAST(N'2020-01-28T18:06:26.640' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (15, CAST(N'2020-01-28T18:06:07.080' AS DATETIME), CAST(N'2020-01-28T18:06:26.640' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (16, CAST(N'2020-01-28T18:06:07.080' AS DATETIME), CAST(N'2020-01-28T18:06:26.640' AS DATETIME), 287, 287, 0, 171, 4, N'#0A0356')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (17, CAST(N'2020-01-28T18:06:07.080' AS DATETIME), CAST(N'2020-01-28T18:06:26.640' AS DATETIME), 287, 287, 0, 171, 2, N'#EF281A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (18, CAST(N'2020-01-28T18:06:26.647' AS DATETIME), CAST(N'2020-01-28T18:06:49.367' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (19, CAST(N'2020-01-28T18:06:26.647' AS DATETIME), CAST(N'2020-01-28T18:06:49.367' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (20, CAST(N'2020-01-28T18:06:26.647' AS DATETIME), CAST(N'2020-01-28T18:06:49.367' AS DATETIME), 287, 287, 0, 171, 4, N'#FFFFFF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (21, CAST(N'2020-01-28T18:06:26.647' AS DATETIME), CAST(N'2020-01-28T18:06:49.367' AS DATETIME), 287, 287, 0, 171, 2, N'#EF281A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (22, CAST(N'2020-01-28T18:06:49.373' AS DATETIME), CAST(N'2020-01-28T18:07:30.397' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (23, CAST(N'2020-01-28T18:06:49.373' AS DATETIME), CAST(N'2020-01-28T18:07:30.397' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (24, CAST(N'2020-01-28T18:06:49.373' AS DATETIME), CAST(N'2020-01-28T18:07:30.397' AS DATETIME), 287, 287, 0, 171, 4, N'#FF0000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (25, CAST(N'2020-01-28T18:06:49.373' AS DATETIME), CAST(N'2020-01-28T18:07:30.397' AS DATETIME), 287, 287, 0, 171, 2, N'#EF281A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (26, CAST(N'2020-01-28T18:07:30.403' AS DATETIME), CAST(N'2020-01-28T18:08:02.743' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (27, CAST(N'2020-01-28T18:07:30.403' AS DATETIME), CAST(N'2020-01-28T18:08:02.743' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (28, CAST(N'2020-01-28T18:07:30.403' AS DATETIME), CAST(N'2020-01-28T18:08:02.743' AS DATETIME), 287, 287, 0, 171, 4, N'#262525')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (29, CAST(N'2020-01-28T18:07:30.403' AS DATETIME), CAST(N'2020-01-28T18:08:02.743' AS DATETIME), 287, 287, 0, 171, 2, N'#737373')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (30, CAST(N'2020-01-28T18:08:02.747' AS DATETIME), CAST(N'2020-01-28T18:09:35.853' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (31, CAST(N'2020-01-28T18:08:02.747' AS DATETIME), CAST(N'2020-01-28T18:09:35.853' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (32, CAST(N'2020-01-28T18:08:02.747' AS DATETIME), CAST(N'2020-01-28T18:09:35.853' AS DATETIME), 287, 287, 0, 171, 4, N'#262525')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (33, CAST(N'2020-01-28T18:08:02.747' AS DATETIME), CAST(N'2020-01-28T18:09:35.853' AS DATETIME), 287, 287, 0, 171, 2, N'#BA150A')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (34, CAST(N'2020-01-28T18:09:35.860' AS DATETIME), CAST(N'2020-01-29T10:25:37.047' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (35, CAST(N'2020-01-28T18:09:35.860' AS DATETIME), CAST(N'2020-01-29T10:25:37.047' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (36, CAST(N'2020-01-28T18:09:35.860' AS DATETIME), CAST(N'2020-01-29T10:25:37.047' AS DATETIME), 287, 287, 0, 171, 4, N'#161616')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (37, CAST(N'2020-01-28T18:09:35.860' AS DATETIME), CAST(N'2020-01-29T10:25:37.047' AS DATETIME), 287, 287, 0, 171, 2, N'#EE1C23')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (38, CAST(N'2020-01-29T10:25:37.050' AS DATETIME), CAST(N'2020-02-05T18:01:36.750' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (39, CAST(N'2020-01-29T10:25:37.050' AS DATETIME), CAST(N'2020-02-05T18:01:36.750' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (40, CAST(N'2020-01-29T10:25:37.050' AS DATETIME), CAST(N'2020-02-05T18:01:36.750' AS DATETIME), 287, 287, 0, 171, 4, N'#343333')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (41, CAST(N'2020-01-29T10:25:37.050' AS DATETIME), CAST(N'2020-02-05T18:01:36.750' AS DATETIME), 287, 287, 0, 171, 2, N'#EE1C23')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (42, CAST(N'2020-02-05T18:01:36.773' AS DATETIME), CAST(N'2020-02-05T18:04:17.250' AS DATETIME), 287, 287, 0, 171, 1, N'#295380')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (43, CAST(N'2020-02-05T18:01:36.773' AS DATETIME), CAST(N'2020-02-05T18:04:17.250' AS DATETIME), 287, 287, 0, 171, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (44, CAST(N'2020-02-05T18:01:36.773' AS DATETIME), CAST(N'2020-02-05T18:04:17.250' AS DATETIME), 287, 287, 0, 171, 4, N'#343232')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (45, CAST(N'2020-02-05T18:01:36.773' AS DATETIME), CAST(N'2020-02-05T18:04:17.250' AS DATETIME), 287, 287, 0, 171, 2, N'#EE1C23')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (46, CAST(N'2020-02-05T18:04:17.253' AS DATETIME), CAST(N'2020-02-05T18:04:58.397' AS DATETIME), 287, 287, 0, 171, 1, N'#84344FF2')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (47, CAST(N'2020-02-05T18:04:17.253' AS DATETIME), CAST(N'2020-02-05T18:04:58.397' AS DATETIME), 287, 287, 0, 171, 3, N'#704CB2D9')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (48, CAST(N'2020-02-05T18:04:17.253' AS DATETIME), CAST(N'2020-02-05T18:04:58.397' AS DATETIME), 287, 287, 0, 171, 4, N'#E68B8B')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (49, CAST(N'2020-02-05T18:04:17.253' AS DATETIME), CAST(N'2020-02-05T18:04:58.397' AS DATETIME), 287, 287, 0, 171, 2, N'#D76367')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (50, CAST(N'2020-02-05T18:04:58.403' AS DATETIME), CAST(N'2020-02-06T21:40:02.593' AS DATETIME), 287, 287, 0, 171, 1, N'#274F79')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (51, CAST(N'2020-02-05T18:04:58.403' AS DATETIME), CAST(N'2020-02-06T21:40:02.593' AS DATETIME), 287, 287, 0, 171, 3, N'#FFD200')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (52, CAST(N'2020-02-05T18:04:58.403' AS DATETIME), CAST(N'2020-02-06T21:40:02.593' AS DATETIME), 287, 287, 0, 171, 4, N'#2B2929')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (53, CAST(N'2020-02-05T18:04:58.403' AS DATETIME), CAST(N'2020-02-06T21:40:02.593' AS DATETIME), 287, 287, 0, 171, 2, N'#E31D23')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (54, CAST(N'2020-02-06T21:40:02.597' AS DATETIME), NULL, 287, NULL, 1, 171, 1, N'#274F79')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (55, CAST(N'2020-02-06T21:40:02.597' AS DATETIME), NULL, 287, NULL, 1, 171, 3, N'#FFD200')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (56, CAST(N'2020-02-06T21:40:02.597' AS DATETIME), NULL, 287, NULL, 1, 171, 4, N'#422222')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (57, CAST(N'2020-02-06T21:40:02.597' AS DATETIME), NULL, 287, NULL, 1, 171, 2, N'#E31D23')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (58, CAST(N'2020-02-13T12:39:23.267' AS DATETIME), NULL, 474, NULL, 1, 172, 1, N'#012D52')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (59, CAST(N'2020-02-13T12:39:23.267' AS DATETIME), NULL, 474, NULL, 1, 172, 3, N'#FFFFFF70')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (60, CAST(N'2020-02-13T12:39:23.267' AS DATETIME), NULL, 474, NULL, 1, 172, 4, N'#020000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (61, CAST(N'2020-02-13T12:39:23.267' AS DATETIME), NULL, 474, NULL, 1, 172, 2, N'#012D52')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (62, CAST(N'2020-03-03T15:23:47.800' AS DATETIME), CAST(N'2020-03-03T18:18:18.600' AS DATETIME), 173, 173, 0, 174, 1, N'#CF1043')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (63, CAST(N'2020-03-03T15:23:47.800' AS DATETIME), CAST(N'2020-03-03T18:18:18.600' AS DATETIME), 173, 173, 0, 174, 3, N'#59AC40')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (64, CAST(N'2020-03-03T15:23:47.800' AS DATETIME), CAST(N'2020-03-03T18:18:18.600' AS DATETIME), 173, 173, 0, 174, 4, N'#FFFFFF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (65, CAST(N'2020-03-03T15:23:47.800' AS DATETIME), CAST(N'2020-03-03T18:18:18.600' AS DATETIME), 173, 173, 0, 174, 2, N'#CF1043')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (66, CAST(N'2020-03-03T18:18:18.603' AS DATETIME), NULL, 173, NULL, 1, 174, 1, N'#CD1041')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (67, CAST(N'2020-03-03T18:18:18.603' AS DATETIME), NULL, 173, NULL, 1, 174, 3, N'#59AC40')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (68, CAST(N'2020-03-03T18:18:18.603' AS DATETIME), NULL, 173, NULL, 1, 174, 4, N'#FFFFFF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (69, CAST(N'2020-03-03T18:18:18.603' AS DATETIME), NULL, 173, NULL, 1, 174, 2, N'#CD1041')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (70, CAST(N'2020-03-09T14:18:56.577' AS DATETIME), NULL, 173, NULL, 1, 175, 1, N'#040586')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (71, CAST(N'2020-03-09T14:18:56.577' AS DATETIME), NULL, 173, NULL, 1, 175, 3, N'#FB0045')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (72, CAST(N'2020-03-09T14:18:56.577' AS DATETIME), NULL, 173, NULL, 1, 175, 4, N'#FFFFFF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (73, CAST(N'2020-03-09T14:18:56.577' AS DATETIME), NULL, 173, NULL, 1, 175, 2, N'#FFC500')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (74, CAST(N'2020-03-16T14:35:13.483' AS DATETIME), NULL, 173, NULL, 1, 7, 1, N'#64ba00')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (75, CAST(N'2020-03-16T14:35:13.483' AS DATETIME), NULL, 173, NULL, 1, 7, 3, N'#fdd000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (76, CAST(N'2020-03-16T14:35:13.483' AS DATETIME), NULL, 173, NULL, 1, 7, 4, N'#474747')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (77, CAST(N'2020-03-16T14:35:13.483' AS DATETIME), NULL, 173, NULL, 1, 7, 2, N'#B5D9A6')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (78, CAST(N'2020-03-20T15:34:38.403' AS DATETIME), NULL, 173, NULL, 1, 176, 1, N'#910811')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (79, CAST(N'2020-03-20T15:34:38.403' AS DATETIME), NULL, 173, NULL, 1, 176, 3, N'#FFFFFF00')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (80, CAST(N'2020-03-20T15:34:38.403' AS DATETIME), NULL, 173, NULL, 1, 176, 4, N'#000000')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (81, CAST(N'2020-03-20T15:34:38.403' AS DATETIME), NULL, 173, NULL, 1, 176, 2, N'#910811')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (82, CAST(N'2020-03-21T19:56:31.783' AS DATETIME), NULL, 287, NULL, 1, 177, 1, N'#DB6C6CBF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (83, CAST(N'2020-03-21T19:56:31.783' AS DATETIME), NULL, 287, NULL, 1, 177, 3, N'#922349F2')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (84, CAST(N'2020-03-21T19:56:31.783' AS DATETIME), NULL, 287, NULL, 1, 177, 4, N'#FFFFFF')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (85, CAST(N'2020-03-21T19:56:31.783' AS DATETIME), NULL, 287, NULL, 1, 177, 2, N'#F44336')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (86, CAST(N'2020-04-13T15:26:19.807' AS DATETIME), NULL, 173, NULL, 1, 86, 1, N'#232323')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (87, CAST(N'2020-04-13T15:26:19.807' AS DATETIME), NULL, 173, NULL, 1, 86, 3, N'#CCB768')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (88, CAST(N'2020-04-13T15:26:19.807' AS DATETIME), NULL, 173, NULL, 1, 86, 4, N'#232323')
INSERT [dbo].[ECOMMERCE_THEMES_COLORS] ([COD_ECOMMERCE_COLORS], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_COLORS], [COLOR])
	VALUES (89, CAST(N'2020-04-13T15:26:19.807' AS DATETIME), NULL, 173, NULL, 1, 86, 2, N'#CCB768')
SET IDENTITY_INSERT [dbo].[ECOMMERCE_THEMES_COLORS] OFF

/****** Object:  Table [dbo].[ECOMMERCE_THEMES_IMG]    Script Date: 03/05/2020 16:18:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ECOMMERCE_THEMES_IMG](
	[COD_ECOMMERCE_IMG] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NOT NULL,
	[MODIFY_DATE] [datetime] NULL,
	[COD_USER_CAD] [int] NOT NULL,
	[COD_USER_ALT] [int] NULL,
	[ACTIVE] [int] NOT NULL,
	[COD_AFFILIATOR] [int] NOT NULL,
	[COD_WL_CONT_TYPE] [int] NOT NULL,
	[PATH_CONTENT] [varchar](400) NOT NULL,
	[COD_MODEL] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_ECOMMERCE_IMG] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG]  WITH CHECK ADD FOREIGN KEY([COD_AFFILIATOR])
REFERENCES [dbo].[AFFILIATOR] ([COD_AFFILIATOR])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG]  WITH CHECK ADD FOREIGN KEY([COD_MODEL])
REFERENCES [dbo].[EQUIPMENT_MODEL] ([COD_MODEL])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG]  WITH CHECK ADD FOREIGN KEY([COD_MODEL])
REFERENCES [dbo].[EQUIPMENT_MODEL] ([COD_MODEL])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG]  WITH CHECK ADD FOREIGN KEY([COD_USER_CAD])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG]  WITH CHECK ADD FOREIGN KEY([COD_USER_ALT])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_IMG]  WITH CHECK ADD FOREIGN KEY([COD_WL_CONT_TYPE])
REFERENCES [dbo].[WL_CONTENT_TYPE] ([COD_WL_CONT_TYPE])
GO


SET IDENTITY_INSERT [dbo].[ECOMMERCE_THEMES_IMG] ON

INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (1, CAST(N'2020-01-24T17:44:48.287' AS DATETIME), CAST(N'2020-01-24T17:48:14.117' AS DATETIME), 173, 173, 0, 128, 1, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (2, CAST(N'2020-01-24T17:44:48.287' AS DATETIME), CAST(N'2020-01-24T17:48:14.117' AS DATETIME), 173, 173, 0, 128, 2, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (3, CAST(N'2020-01-24T17:48:14.140' AS DATETIME), CAST(N'2020-01-24T17:49:25.297' AS DATETIME), 173, 173, 0, 128, 1, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (4, CAST(N'2020-01-24T17:48:14.140' AS DATETIME), CAST(N'2020-01-24T17:49:25.297' AS DATETIME), 173, 173, 0, 128, 2, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (5, CAST(N'2020-01-24T17:48:14.140' AS DATETIME), CAST(N'2020-01-24T17:49:25.297' AS DATETIME), 173, 173, 0, 128, 3, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (6, CAST(N'2020-01-24T17:48:14.140' AS DATETIME), CAST(N'2020-01-24T17:49:25.297' AS DATETIME), 173, 173, 0, 128, 4, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (7, CAST(N'2020-01-24T17:48:14.140' AS DATETIME), CAST(N'2020-01-24T17:49:25.297' AS DATETIME), 173, 173, 0, 128, 5, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (8, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 1, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (9, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 2, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (10, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 3, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (11, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 4, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (12, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 5, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (13, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 6, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_ABOUT01\IMG_ABOUT01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (14, CAST(N'2020-01-24T17:49:25.303' AS DATETIME), NULL, 173, NULL, 1, 128, 7, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (15, CAST(N'2020-01-24T17:53:46.140' AS DATETIME), CAST(N'2020-01-24T17:54:15.690' AS DATETIME), 173, 173, 0, 128, 8, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_PRODUCT\D150.png', 4)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (16, CAST(N'2020-01-24T17:53:46.140' AS DATETIME), CAST(N'2020-01-24T17:54:15.690' AS DATETIME), 173, 173, 0, 128, 8, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (17, CAST(N'2020-01-24T17:54:15.697' AS DATETIME), NULL, 173, NULL, 1, 128, 8, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_PRODUCT\D150.png', 4)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (18, CAST(N'2020-01-24T17:54:15.697' AS DATETIME), NULL, 173, NULL, 1, 128, 8, N'C:\ECOMMERCE_STYLE\\46100036434447\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (19, CAST(N'2020-01-28T17:07:40.503' AS DATETIME), CAST(N'2020-01-28T17:08:28.297' AS DATETIME), 287, 287, 0, 171, 1, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (20, CAST(N'2020-01-28T17:07:40.503' AS DATETIME), CAST(N'2020-01-28T17:08:28.297' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (21, CAST(N'2020-01-28T17:08:28.310' AS DATETIME), CAST(N'2020-01-28T17:09:33.490' AS DATETIME), 287, 287, 0, 171, 1, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (22, CAST(N'2020-01-28T17:08:28.310' AS DATETIME), CAST(N'2020-01-28T17:09:33.490' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (23, CAST(N'2020-01-28T17:08:28.310' AS DATETIME), CAST(N'2020-01-28T17:09:33.490' AS DATETIME), 287, 287, 0, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (24, CAST(N'2020-01-28T17:08:28.310' AS DATETIME), CAST(N'2020-01-28T17:09:33.490' AS DATETIME), 287, 287, 0, 171, 4, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (25, CAST(N'2020-01-28T17:08:28.310' AS DATETIME), CAST(N'2020-01-28T17:09:33.490' AS DATETIME), 287, 287, 0, 171, 5, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (26, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 1, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (27, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (28, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (29, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 4, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (30, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 5, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (31, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 6, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_ABOUT01\IMG_ABOUT01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (32, CAST(N'2020-01-28T17:09:33.507' AS DATETIME), CAST(N'2020-01-28T17:16:43.710' AS DATETIME), 287, 287, 0, 171, 7, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (33, CAST(N'2020-01-28T17:10:38.487' AS DATETIME), NULL, 287, NULL, 1, 171, 8, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_PRODUCT\D200.png', 1)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (34, CAST(N'2020-01-28T17:10:38.487' AS DATETIME), NULL, 287, NULL, 1, 171, 8, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (35, CAST(N'2020-01-28T17:10:38.487' AS DATETIME), NULL, 287, NULL, 1, 171, 8, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_PRODUCT\A920.png', 5)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (36, CAST(N'2020-01-28T17:10:38.487' AS DATETIME), NULL, 287, NULL, 1, 171, 8, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_PRODUCT\D150.png', 4)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (37, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 1, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (38, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (39, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 4, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (40, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 5, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (41, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 6, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_ABOUT01\IMG_ABOUT01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (42, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 7, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (43, CAST(N'2020-01-28T17:16:43.717' AS DATETIME), CAST(N'2020-01-28T17:18:53.290' AS DATETIME), 287, 287, 0, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (44, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), NULL, 287, NULL, 1, 171, 1, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (45, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), CAST(N'2020-02-05T18:01:13.167' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (46, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), NULL, 287, NULL, 1, 171, 5, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (47, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), NULL, 287, NULL, 1, 171, 6, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_ABOUT01\IMG_ABOUT01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (48, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), NULL, 287, NULL, 1, 171, 7, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (49, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), CAST(N'2020-02-06T21:40:25.907' AS DATETIME), 287, 287, 0, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (50, CAST(N'2020-01-28T17:18:53.300' AS DATETIME), NULL, 287, NULL, 1, 171, 4, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (51, CAST(N'2020-01-29T11:17:10.977' AS DATETIME), NULL, 287, NULL, 1, 171, 9, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (52, CAST(N'2020-01-29T11:17:10.977' AS DATETIME), CAST(N'2020-01-29T11:28:06.707' AS DATETIME), 287, 287, 0, 171, 10, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (53, CAST(N'2020-01-29T11:17:10.977' AS DATETIME), CAST(N'2020-01-29T11:28:06.707' AS DATETIME), 287, 287, 0, 171, 11, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (54, CAST(N'2020-01-29T11:17:10.977' AS DATETIME), CAST(N'2020-01-29T11:28:06.707' AS DATETIME), 287, 287, 0, 171, 12, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (55, CAST(N'2020-01-29T11:28:06.713' AS DATETIME), CAST(N'2020-01-29T11:28:39.837' AS DATETIME), 287, 287, 0, 171, 10, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS02\IMG_BENEFITS02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (56, CAST(N'2020-01-29T11:28:06.713' AS DATETIME), CAST(N'2020-01-29T11:28:39.837' AS DATETIME), 287, 287, 0, 171, 11, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS03\IMG_BENEFITS03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (57, CAST(N'2020-01-29T11:28:06.713' AS DATETIME), CAST(N'2020-01-29T11:28:39.837' AS DATETIME), 287, 287, 0, 171, 12, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (58, CAST(N'2020-01-29T11:28:39.840' AS DATETIME), NULL, 287, NULL, 1, 171, 10, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (59, CAST(N'2020-01-29T11:28:39.840' AS DATETIME), NULL, 287, NULL, 1, 171, 11, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (60, CAST(N'2020-01-29T11:28:39.840' AS DATETIME), NULL, 287, NULL, 1, 171, 12, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (61, CAST(N'2020-02-05T18:01:13.173' AS DATETIME), CAST(N'2020-02-05T18:02:16.690' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (62, CAST(N'2020-02-05T18:02:16.697' AS DATETIME), CAST(N'2020-02-05T18:02:44.780' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (63, CAST(N'2020-02-05T18:02:44.787' AS DATETIME), CAST(N'2020-02-06T21:37:23.680' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (64, CAST(N'2020-02-06T21:37:23.690' AS DATETIME), CAST(N'2020-02-06T21:40:25.907' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (65, CAST(N'2020-02-06T21:40:25.913' AS DATETIME), CAST(N'2020-02-06T21:41:19.387' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (66, CAST(N'2020-02-06T21:40:25.913' AS DATETIME), CAST(N'2020-02-06T21:41:19.387' AS DATETIME), 287, 287, 0, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (67, CAST(N'2020-02-06T21:41:19.393' AS DATETIME), CAST(N'2020-02-06T21:41:34.387' AS DATETIME), 287, 287, 0, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (68, CAST(N'2020-02-06T21:41:19.393' AS DATETIME), CAST(N'2020-02-06T21:41:34.387' AS DATETIME), 287, 287, 0, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (69, CAST(N'2020-02-06T21:41:34.393' AS DATETIME), NULL, 287, NULL, 1, 171, 2, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (70, CAST(N'2020-02-06T21:41:34.393' AS DATETIME), NULL, 287, NULL, 1, 171, 3, N'C:\ECOMMERCE_STYLE\\27928698000166\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (71, CAST(N'2020-02-13T12:35:56.163' AS DATETIME), CAST(N'2020-02-13T12:36:51.447' AS DATETIME), 474, 474, 0, 172, 2, N'C:\ECOMMERCE_STYLE\\72258453000123\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (72, CAST(N'2020-02-13T12:35:56.163' AS DATETIME), CAST(N'2020-02-13T12:36:51.447' AS DATETIME), 474, 474, 0, 172, 1, N'C:\ECOMMERCE_STYLE\\72258453000123\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (73, CAST(N'2020-02-13T12:36:51.450' AS DATETIME), CAST(N'2020-02-13T12:37:26.753' AS DATETIME), 474, 474, 0, 172, 2, N'C:\ECOMMERCE_STYLE\\72258453000123\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (74, CAST(N'2020-02-13T12:36:51.450' AS DATETIME), CAST(N'2020-02-13T12:37:26.753' AS DATETIME), 474, 474, 0, 172, 1, N'C:\ECOMMERCE_STYLE\\72258453000123\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (75, CAST(N'2020-02-13T12:37:26.760' AS DATETIME), NULL, 474, NULL, 1, 172, 2, N'C:\ECOMMERCE_STYLE\\72258453000123\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (76, CAST(N'2020-02-13T12:37:26.760' AS DATETIME), NULL, 474, NULL, 1, 172, 1, N'C:\ECOMMERCE_STYLE\\72258453000123\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (77, CAST(N'2020-02-27T16:49:10.087' AS DATETIME), NULL, 4852, NULL, 1, 6, 1, N'C:\ECOMMERCE_STYLE\\21100079544352\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (78, CAST(N'2020-02-27T16:49:10.087' AS DATETIME), NULL, 4852, NULL, 1, 6, 2, N'C:\ECOMMERCE_STYLE\\21100079544352\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (79, CAST(N'2020-03-03T15:22:39.620' AS DATETIME), CAST(N'2020-03-03T15:27:28.500' AS DATETIME), 173, 173, 0, 174, 2, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (80, CAST(N'2020-03-03T15:22:39.620' AS DATETIME), CAST(N'2020-03-03T15:27:28.500' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (81, CAST(N'2020-03-03T15:27:28.507' AS DATETIME), CAST(N'2020-03-03T15:28:57.020' AS DATETIME), 173, 173, 0, 174, 2, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (82, CAST(N'2020-03-03T15:27:28.507' AS DATETIME), CAST(N'2020-03-03T15:28:57.020' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (83, CAST(N'2020-03-03T15:28:57.027' AS DATETIME), CAST(N'2020-03-03T19:02:56.737' AS DATETIME), 173, 173, 0, 174, 2, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (84, CAST(N'2020-03-03T15:28:57.027' AS DATETIME), CAST(N'2020-03-03T16:29:43.090' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (85, CAST(N'2020-03-03T15:28:57.027' AS DATETIME), NULL, 173, NULL, 1, 174, 3, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (86, CAST(N'2020-03-03T15:28:57.027' AS DATETIME), NULL, 173, NULL, 1, 174, 4, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (87, CAST(N'2020-03-03T15:28:57.027' AS DATETIME), NULL, 173, NULL, 1, 174, 5, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_CAROUSEL03\IMG_CAROUSEL03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (88, CAST(N'2020-03-03T16:29:43.097' AS DATETIME), CAST(N'2020-03-03T16:29:58.490' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (89, CAST(N'2020-03-03T16:29:43.097' AS DATETIME), CAST(N'2020-03-03T16:29:58.490' AS DATETIME), 173, 173, 0, 174, 6, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_ABOUT01\IMG_ABOUT01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (90, CAST(N'2020-03-03T16:29:43.097' AS DATETIME), CAST(N'2020-03-03T16:29:58.490' AS DATETIME), 173, 173, 0, 174, 7, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (91, CAST(N'2020-03-03T16:29:58.493' AS DATETIME), NULL, 173, NULL, 1, 174, 6, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_ABOUT01\IMG_ABOUT01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (92, CAST(N'2020-03-03T16:29:58.493' AS DATETIME), NULL, 173, NULL, 1, 174, 7, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (93, CAST(N'2020-03-03T16:29:58.493' AS DATETIME), CAST(N'2020-03-03T16:56:02.353' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (94, CAST(N'2020-03-03T16:39:29.783' AS DATETIME), CAST(N'2020-03-03T16:42:28.263' AS DATETIME), 173, 173, 0, 174, 8, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (95, CAST(N'2020-03-03T16:42:28.267' AS DATETIME), NULL, 173, NULL, 1, 174, 8, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (96, CAST(N'2020-03-03T16:42:28.267' AS DATETIME), NULL, 173, NULL, 1, 174, 8, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_PRODUCT\D150.jpg', 4)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (97, CAST(N'2020-03-03T16:51:48.680' AS DATETIME), CAST(N'2020-03-03T17:13:57.120' AS DATETIME), 173, 173, 0, 174, 9, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_BENEFITS01\IMG_BENEFITS01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (98, CAST(N'2020-03-03T16:51:48.680' AS DATETIME), NULL, 173, NULL, 1, 174, 10, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_BENEFITS02\IMG_BENEFITS02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (99, CAST(N'2020-03-03T16:51:48.680' AS DATETIME), NULL, 173, NULL, 1, 174, 11, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_BENEFITS03\IMG_BENEFITS03.jpg', NULL)
GO
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (100, CAST(N'2020-03-03T16:51:48.680' AS DATETIME), NULL, 173, NULL, 1, 174, 12, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_BENEFITS04\IMG_BENEFITS04.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (101, CAST(N'2020-03-03T16:56:02.360' AS DATETIME), CAST(N'2020-03-03T18:10:25.390' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (102, CAST(N'2020-03-03T17:13:57.127' AS DATETIME), NULL, 173, NULL, 1, 174, 9, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (103, CAST(N'2020-03-03T18:10:25.397' AS DATETIME), CAST(N'2020-03-04T14:20:39.340' AS DATETIME), 173, 173, 0, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (104, CAST(N'2020-03-03T18:13:47.087' AS DATETIME), NULL, 173, NULL, 1, 174, 8, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_PRODUCT\D180.jpg', 3)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (105, CAST(N'2020-03-03T19:02:56.743' AS DATETIME), NULL, 173, NULL, 1, 174, 2, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LATERAL\IMG_LATERAL.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (106, CAST(N'2020-03-04T14:20:39.357' AS DATETIME), NULL, 173, NULL, 1, 174, 1, N'C:\ECOMMERCE_STYLE\\41202821000198\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (107, CAST(N'2020-03-09T14:02:27.430' AS DATETIME), CAST(N'2020-03-09T14:14:56.380' AS DATETIME), 173, 173, 0, 175, 1, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (108, CAST(N'2020-03-09T14:02:27.430' AS DATETIME), CAST(N'2020-03-09T14:10:16.303' AS DATETIME), 173, 173, 0, 175, 2, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (109, CAST(N'2020-03-09T14:10:16.307' AS DATETIME), CAST(N'2020-03-09T14:14:56.380' AS DATETIME), 173, 173, 0, 175, 2, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (110, CAST(N'2020-03-09T14:14:56.387' AS DATETIME), CAST(N'2020-03-09T14:23:03.653' AS DATETIME), 173, 173, 0, 175, 1, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (111, CAST(N'2020-03-09T14:14:56.387' AS DATETIME), NULL, 173, NULL, 1, 175, 2, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (112, CAST(N'2020-03-09T14:23:03.657' AS DATETIME), NULL, 173, NULL, 1, 175, 1, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (113, CAST(N'2020-03-09T14:38:50.330' AS DATETIME), CAST(N'2020-03-09T14:44:20.843' AS DATETIME), 173, 173, 0, 175, 3, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (114, CAST(N'2020-03-09T14:38:50.330' AS DATETIME), CAST(N'2020-03-09T14:44:20.843' AS DATETIME), 173, 173, 0, 175, 4, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (115, CAST(N'2020-03-09T14:38:50.330' AS DATETIME), CAST(N'2020-03-09T14:44:20.843' AS DATETIME), 173, 173, 0, 175, 5, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL03\IMG_CAROUSEL03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (116, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 3, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (117, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 4, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (118, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 5, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL03\IMG_CAROUSEL03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (119, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 9, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS01\IMG_BENEFITS01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (120, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 10, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (121, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 11, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (122, CAST(N'2020-03-09T14:44:20.850' AS DATETIME), CAST(N'2020-03-09T14:46:11.530' AS DATETIME), 173, 173, 0, 175, 12, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (123, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 3, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (124, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 4, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (125, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 5, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_CAROUSEL03\IMG_CAROUSEL03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (126, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 9, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS01\IMG_BENEFITS01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (127, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 10, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (128, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 11, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (129, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 12, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (130, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 6, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_ABOUT01\IMG_ABOUT01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (131, CAST(N'2020-03-09T14:46:11.537' AS DATETIME), NULL, 173, NULL, 1, 175, 7, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_ABOUT02\IMG_ABOUT02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (132, CAST(N'2020-03-09T14:47:26.660' AS DATETIME), NULL, 173, NULL, 1, 175, 8, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_PRODUCT\D150.jpg', 4)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (133, CAST(N'2020-03-09T14:47:26.660' AS DATETIME), NULL, 173, NULL, 1, 175, 8, N'C:\ECOMMERCE_STYLE\\31198332000156\IMG_PRODUCT\S920.jpg', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (134, CAST(N'2020-03-16T12:08:54.957' AS DATETIME), NULL, 173, NULL, 1, 136, 1, N'C:\ECOMMERCE_STYLE\\42700044469892\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (135, CAST(N'2020-03-16T12:08:54.957' AS DATETIME), NULL, 173, NULL, 1, 136, 2, N'C:\ECOMMERCE_STYLE\\42700044469892\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (136, CAST(N'2020-03-16T14:33:00.863' AS DATETIME), CAST(N'2020-03-16T14:34:42.330' AS DATETIME), 173, 173, 0, 7, 1, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (137, CAST(N'2020-03-16T14:33:00.863' AS DATETIME), CAST(N'2020-03-16T14:34:42.330' AS DATETIME), 173, 173, 0, 7, 2, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (138, CAST(N'2020-03-16T14:34:42.350' AS DATETIME), CAST(N'2020-03-16T14:35:26.350' AS DATETIME), 173, 173, 0, 7, 1, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (139, CAST(N'2020-03-16T14:34:42.350' AS DATETIME), CAST(N'2020-03-16T14:35:26.350' AS DATETIME), 173, 173, 0, 7, 2, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (140, CAST(N'2020-03-16T14:35:26.353' AS DATETIME), CAST(N'2020-03-16T14:35:33.083' AS DATETIME), 173, 173, 0, 7, 1, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (141, CAST(N'2020-03-16T14:35:26.353' AS DATETIME), CAST(N'2020-03-16T14:35:33.083' AS DATETIME), 173, 173, 0, 7, 2, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (142, CAST(N'2020-03-16T14:35:33.097' AS DATETIME), CAST(N'2020-03-16T14:35:48.607' AS DATETIME), 173, 173, 0, 7, 1, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (143, CAST(N'2020-03-16T14:35:33.097' AS DATETIME), CAST(N'2020-03-16T14:35:48.607' AS DATETIME), 173, 173, 0, 7, 2, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (144, CAST(N'2020-03-16T14:35:48.630' AS DATETIME), NULL, 173, NULL, 1, 7, 1, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (145, CAST(N'2020-03-16T14:35:48.630' AS DATETIME), NULL, 173, NULL, 1, 7, 2, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (146, CAST(N'2020-03-16T14:36:11.877' AS DATETIME), NULL, 173, NULL, 1, 7, 8, N'C:\ECOMMERCE_STYLE\\90100039853931\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (147, CAST(N'2020-03-20T15:31:55.917' AS DATETIME), CAST(N'2020-03-20T15:41:21.123' AS DATETIME), 173, 173, 0, 176, 2, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (148, CAST(N'2020-03-20T15:31:55.917' AS DATETIME), CAST(N'2020-03-20T15:41:21.123' AS DATETIME), 173, 173, 0, 176, 1, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (149, CAST(N'2020-03-20T15:41:21.130' AS DATETIME), CAST(N'2020-03-20T15:50:41.637' AS DATETIME), 173, 173, 0, 176, 2, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (150, CAST(N'2020-03-20T15:41:21.130' AS DATETIME), CAST(N'2020-03-20T15:50:41.637' AS DATETIME), 173, 173, 0, 176, 1, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (151, CAST(N'2020-03-20T15:41:21.130' AS DATETIME), CAST(N'2020-03-20T15:50:41.637' AS DATETIME), 173, 173, 0, 176, 3, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (152, CAST(N'2020-03-20T15:41:21.130' AS DATETIME), CAST(N'2020-03-20T15:50:41.637' AS DATETIME), 173, 173, 0, 176, 5, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (153, CAST(N'2020-03-20T15:41:21.130' AS DATETIME), CAST(N'2020-03-20T15:50:41.637' AS DATETIME), 173, 173, 0, 176, 4, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (154, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 2, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (155, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 1, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (156, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 3, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (157, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 5, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (158, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 4, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (159, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 9, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (160, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 10, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (161, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 11, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS03\IMG_BENEFITS03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (162, CAST(N'2020-03-20T15:50:41.640' AS DATETIME), CAST(N'2020-03-20T15:58:27.530' AS DATETIME), 173, 173, 0, 176, 12, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS04\IMG_BENEFITS04.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (163, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 2, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (164, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 1, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (165, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 3, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (166, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 5, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (167, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 4, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (168, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 9, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (169, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 10, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (170, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 11, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS03\IMG_BENEFITS03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (171, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 12, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_BENEFITS04\IMG_BENEFITS04.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (172, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 6, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_ABOUT01\IMG_ABOUT01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (173, CAST(N'2020-03-20T15:58:27.533' AS DATETIME), NULL, 173, NULL, 1, 176, 7, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (174, CAST(N'2020-03-20T16:10:30.000' AS DATETIME), NULL, 173, NULL, 1, 176, 8, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (175, CAST(N'2020-03-20T16:10:30.000' AS DATETIME), NULL, 173, NULL, 1, 176, 8, N'C:\ECOMMERCE_STYLE\\60716731000160\IMG_PRODUCT\D200.png', 1)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (176, CAST(N'2020-03-21T19:54:55.810' AS DATETIME), CAST(N'2020-03-21T19:57:53.217' AS DATETIME), 287, 287, 0, 177, 2, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LATERAL\IMG_LATERAL.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (177, CAST(N'2020-03-21T19:54:55.810' AS DATETIME), CAST(N'2020-03-21T19:57:53.217' AS DATETIME), 287, 287, 0, 177, 1, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (178, CAST(N'2020-03-21T19:57:53.223' AS DATETIME), CAST(N'2020-03-21T20:00:10.650' AS DATETIME), 287, 287, 0, 177, 2, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LATERAL\IMG_LATERAL.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (179, CAST(N'2020-03-21T19:57:53.223' AS DATETIME), CAST(N'2020-03-21T20:00:10.650' AS DATETIME), 287, 287, 0, 177, 1, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (180, CAST(N'2020-03-21T19:57:53.223' AS DATETIME), CAST(N'2020-03-21T20:00:10.650' AS DATETIME), 287, 287, 0, 177, 3, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (181, CAST(N'2020-03-21T19:57:53.223' AS DATETIME), CAST(N'2020-03-21T20:00:10.650' AS DATETIME), 287, 287, 0, 177, 4, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (182, CAST(N'2020-03-21T19:57:53.223' AS DATETIME), CAST(N'2020-03-21T20:00:10.650' AS DATETIME), 287, 287, 0, 177, 5, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (183, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 2, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LATERAL\IMG_LATERAL.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (184, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 1, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (185, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 3, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (186, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 4, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (187, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 5, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (188, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 9, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (189, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 10, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (190, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 11, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (191, CAST(N'2020-03-21T20:00:10.657' AS DATETIME), CAST(N'2020-03-21T20:01:07.790' AS DATETIME), 287, 287, 0, 177, 12, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (192, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 2, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LATERAL\IMG_LATERAL.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (193, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 1, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (194, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), CAST(N'2020-03-21T20:47:43.167' AS DATETIME), 287, 287, 0, 177, 3, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (195, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), CAST(N'2020-03-21T20:47:43.167' AS DATETIME), 287, 287, 0, 177, 4, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (196, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), CAST(N'2020-03-21T20:47:43.167' AS DATETIME), 287, 287, 0, 177, 5, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (197, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 9, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (198, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 10, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (199, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 11, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
GO
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (200, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 12, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (201, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 7, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_ABOUT02\IMG_ABOUT02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (202, CAST(N'2020-03-21T20:01:07.803' AS DATETIME), NULL, 287, NULL, 1, 177, 6, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_ABOUT01\IMG_ABOUT01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (203, CAST(N'2020-03-21T20:01:51.557' AS DATETIME), NULL, 287, NULL, 1, 177, 8, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (204, CAST(N'2020-03-21T20:47:43.177' AS DATETIME), NULL, 287, NULL, 1, 177, 3, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL01\IMG_CAROUSEL01.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (205, CAST(N'2020-03-21T20:47:43.177' AS DATETIME), NULL, 287, NULL, 1, 177, 4, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL02\IMG_CAROUSEL02.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (206, CAST(N'2020-03-21T20:47:43.177' AS DATETIME), NULL, 287, NULL, 1, 177, 5, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_CAROUSEL03\IMG_CAROUSEL03.jpg', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (207, CAST(N'2020-04-02T14:14:40.440' AS DATETIME), NULL, 287, NULL, 1, 177, 8, N'C:\ECOMMERCE_STYLE\\38167331000193\IMG_PRODUCT\A920.png', 5)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (208, CAST(N'2020-04-13T15:25:10.807' AS DATETIME), CAST(N'2020-04-13T15:28:07.747' AS DATETIME), 173, 173, 0, 86, 1, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (209, CAST(N'2020-04-13T15:25:10.807' AS DATETIME), CAST(N'2020-04-13T15:28:07.747' AS DATETIME), 173, 173, 0, 86, 2, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (210, CAST(N'2020-04-13T15:28:07.753' AS DATETIME), CAST(N'2020-04-13T15:45:26.823' AS DATETIME), 173, 173, 0, 86, 1, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (211, CAST(N'2020-04-13T15:28:07.753' AS DATETIME), CAST(N'2020-04-13T15:45:26.823' AS DATETIME), 173, 173, 0, 86, 2, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (212, CAST(N'2020-04-13T15:28:07.753' AS DATETIME), CAST(N'2020-04-13T15:45:26.823' AS DATETIME), 173, 173, 0, 86, 3, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (213, CAST(N'2020-04-13T15:28:07.753' AS DATETIME), CAST(N'2020-04-13T15:45:26.823' AS DATETIME), 173, 173, 0, 86, 4, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (214, CAST(N'2020-04-13T15:28:07.753' AS DATETIME), CAST(N'2020-04-13T15:45:26.823' AS DATETIME), 173, 173, 0, 86, 5, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (215, CAST(N'2020-04-13T15:45:26.830' AS DATETIME), NULL, 173, NULL, 1, 86, 1, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_LOGO\IMG_LOGO.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (216, CAST(N'2020-04-13T15:45:26.830' AS DATETIME), NULL, 173, NULL, 1, 86, 2, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_LATERAL\IMG_LATERAL.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (217, CAST(N'2020-04-13T15:45:26.830' AS DATETIME), NULL, 173, NULL, 1, 86, 4, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_CAROUSEL02\IMG_CAROUSEL02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (218, CAST(N'2020-04-13T15:45:26.830' AS DATETIME), NULL, 173, NULL, 1, 86, 3, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_CAROUSEL01\IMG_CAROUSEL01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (219, CAST(N'2020-04-13T15:45:26.830' AS DATETIME), NULL, 173, NULL, 1, 86, 5, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_CAROUSEL03\IMG_CAROUSEL03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (220, CAST(N'2020-04-13T16:03:53.633' AS DATETIME), NULL, 173, NULL, 1, 86, 9, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_BENEFITS01\IMG_BENEFITS01.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (221, CAST(N'2020-04-13T16:03:53.633' AS DATETIME), NULL, 173, NULL, 1, 86, 10, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_BENEFITS02\IMG_BENEFITS02.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (222, CAST(N'2020-04-13T16:03:53.633' AS DATETIME), NULL, 173, NULL, 1, 86, 11, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_BENEFITS03\IMG_BENEFITS03.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (223, CAST(N'2020-04-13T16:03:53.633' AS DATETIME), NULL, 173, NULL, 1, 86, 12, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_BENEFITS04\IMG_BENEFITS04.png', NULL)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (224, CAST(N'2020-04-13T17:15:14.073' AS DATETIME), NULL, 173, NULL, 1, 86, 8, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_PRODUCT\D150.png', 4)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (225, CAST(N'2020-04-13T17:15:14.073' AS DATETIME), CAST(N'2020-04-16T17:28:31.287' AS DATETIME), 173, 173, 0, 86, 8, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_PRODUCT\S920.png', 2)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (226, CAST(N'2020-04-16T17:28:31.290' AS DATETIME), NULL, 173, NULL, 1, 86, 8, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_PRODUCT\D200.png', 1)
INSERT [dbo].[ECOMMERCE_THEMES_IMG] ([COD_ECOMMERCE_IMG], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CONT_TYPE], [PATH_CONTENT], [COD_MODEL])
	VALUES (227, CAST(N'2020-04-16T17:28:31.290' AS DATETIME), NULL, 173, NULL, 1, 86, 8, N'C:\ECOMMERCE_STYLE\\27100068184484\IMG_PRODUCT\S920.png', 2)
SET IDENTITY_INSERT [dbo].[ECOMMERCE_THEMES_IMG] OFF

/****** Object:  Table [dbo].[ECOMMERCE_THEMES_TEXT]    Script Date: 03/05/2020 16:48:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ECOMMERCE_THEMES_TEXT](
	[COD_ECOMMERCE_TEXT] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NOT NULL,
	[MODIFY_DATE] [datetime] NULL,
	[COD_USER_CAD] [int] NOT NULL,
	[COD_USER_ALT] [int] NULL,
	[ACTIVE] [int] NOT NULL,
	[COD_AFFILIATOR] [int] NOT NULL,
	[COD_WL_CUSTOM_TEXT] [int] NOT NULL,
	[TEXT] [varchar](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_ECOMMERCE_TEXT] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_TEXT] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_TEXT] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_TEXT]  WITH CHECK ADD FOREIGN KEY([COD_AFFILIATOR])
REFERENCES [dbo].[AFFILIATOR] ([COD_AFFILIATOR])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_TEXT]  WITH CHECK ADD FOREIGN KEY([COD_USER_CAD])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_TEXT]  WITH CHECK ADD FOREIGN KEY([COD_USER_ALT])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ECOMMERCE_THEMES_TEXT]  WITH CHECK ADD FOREIGN KEY([COD_WL_CUSTOM_TEXT])
REFERENCES [dbo].[WL_CUSTOM_TEXT] ([COD_WL_CUSTOM_TEXT])
GO




SET IDENTITY_INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ON

INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (1, CAST(N'2020-01-24T17:49:25.307' AS DATETIME), NULL, 173, NULL, 1, 128, 1, N'CELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (2, CAST(N'2020-01-24T17:49:25.307' AS DATETIME), NULL, 173, NULL, 1, 128, 2, N'CELERCELERCELERCELERCELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (3, CAST(N'2020-01-24T17:49:25.307' AS DATETIME), NULL, 173, NULL, 1, 128, 3, N'CELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (4, CAST(N'2020-01-24T17:49:25.307' AS DATETIME), NULL, 173, NULL, 1, 128, 4, N'CELERCELERCELERCELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (5, CAST(N'2020-01-24T17:49:25.307' AS DATETIME), NULL, 173, NULL, 1, 128, 5, N'CELERCELERCELERCELERCELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (6, CAST(N'2020-01-28T17:09:33.520' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 1, N'Dictum leo tristique sociosqu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (7, CAST(N'2020-01-28T17:09:33.520' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 2, N'as diam viverra interdum etiam leo purus fringilla sapien, orci dolor arcu elit non conubia dolor elit fermentum nam laoreet, ultrices auctor class maecenas sollicitudin est erat pellentesque mattis')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (8, CAST(N'2020-01-28T17:09:33.520' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 3, N'Dictum leo tristique sociosqu accumsan elit ac por')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (9, CAST(N'2020-01-28T17:09:33.520' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 4, N'molestie platea sem convallis inceptos. egestas nostra torquent per potenti metus at curabitur, habitant diam pretium enim congue inceptos litora fermentum, ornare eget pretium elit nisi ullamcorper. ligula suspendisse pretium phasellus elit molestie eleifend donec, ullamcorper odio donec quis ipsum felis amet sagittis, turpis hendrerit massa amet nibh volutpat.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (10, CAST(N'2020-01-28T17:09:33.520' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 5, N'et tincidunt a sollicitudin elementum nulla mauris facilisis tincidunt, sollicitudin tellus sit nulla habitant pellent')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (11, CAST(N'2020-01-29T10:45:54.890' AS DATETIME), CAST(N'2020-01-29T10:55:09.740' AS DATETIME), 287, 287, 0, 171, 18, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (12, CAST(N'2020-01-29T10:45:54.890' AS DATETIME), CAST(N'2020-01-29T10:55:09.740' AS DATETIME), 287, 287, 0, 171, 19, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (13, CAST(N'2020-01-29T10:45:54.890' AS DATETIME), CAST(N'2020-01-29T10:55:09.740' AS DATETIME), 287, 287, 0, 171, 20, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (14, CAST(N'2020-01-29T10:45:54.890' AS DATETIME), CAST(N'2020-01-29T10:55:09.740' AS DATETIME), 287, 287, 0, 171, 21, N' Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (15, CAST(N'2020-01-29T10:45:54.890' AS DATETIME), CAST(N'2020-01-29T10:55:09.740' AS DATETIME), 287, 287, 0, 171, 22, N'Digite aqui o título 03')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (16, CAST(N'2020-01-29T10:45:54.890' AS DATETIME), CAST(N'2020-01-29T10:55:09.740' AS DATETIME), 287, 287, 0, 171, 23, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (17, CAST(N'2020-01-29T10:55:09.743' AS DATETIME), CAST(N'2020-01-29T11:17:10.980' AS DATETIME), 287, 287, 0, 171, 18, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (18, CAST(N'2020-01-29T10:55:09.743' AS DATETIME), CAST(N'2020-01-29T11:17:10.980' AS DATETIME), 287, 287, 0, 171, 19, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (19, CAST(N'2020-01-29T10:55:09.743' AS DATETIME), CAST(N'2020-01-29T11:17:10.980' AS DATETIME), 287, 287, 0, 171, 20, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (20, CAST(N'2020-01-29T10:55:09.743' AS DATETIME), CAST(N'2020-01-29T11:17:10.980' AS DATETIME), 287, 287, 0, 171, 21, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (21, CAST(N'2020-01-29T10:55:09.743' AS DATETIME), CAST(N'2020-01-29T11:17:10.980' AS DATETIME), 287, 287, 0, 171, 22, N'Digite aqui o título 03')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (22, CAST(N'2020-01-29T10:55:09.743' AS DATETIME), CAST(N'2020-01-29T11:17:10.980' AS DATETIME), 287, 287, 0, 171, 23, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (23, CAST(N'2020-01-29T11:17:10.997' AS DATETIME), CAST(N'2020-01-29T11:28:06.717' AS DATETIME), 287, 287, 0, 171, 18, N'st condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (24, CAST(N'2020-01-29T11:17:10.997' AS DATETIME), CAST(N'2020-01-29T11:28:06.717' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (25, CAST(N'2020-01-29T11:17:10.997' AS DATETIME), CAST(N'2020-01-29T11:28:06.717' AS DATETIME), 287, 287, 0, 171, 20, N'rmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (26, CAST(N'2020-01-29T11:17:10.997' AS DATETIME), CAST(N'2020-01-29T11:28:06.717' AS DATETIME), 287, 287, 0, 171, 21, N'in aenean sit fusce vitae, massa egestas vel sodales rutrum ante risus, aenean felis fames lectus tempus orci. justo ornare felis tempus nisl quis phasellus rutrum auctor leo, felis elit primis praesent aliquet lobortis mollis lectus, volutpat sapien consectetur ultrices habitasse egestas pulvinar primis. mauris etiam metus potenti quisque pellentesque non ante lo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (27, CAST(N'2020-01-29T11:17:10.997' AS DATETIME), CAST(N'2020-01-29T11:28:06.717' AS DATETIME), 287, 287, 0, 171, 22, N'rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (28, CAST(N'2020-01-29T11:17:10.997' AS DATETIME), CAST(N'2020-01-29T11:28:06.717' AS DATETIME), 287, 287, 0, 171, 23, N'tincidunt, aenean vehicula varius sodales ultrices est neque fusce non accumsan convallis, dui a integer pellentesque tempor lectus fames convallis suspendisse morbi. ante donec convallis faucibus senectus fringilla inceptos id lorem accumsan vestibulum ullamcorper nec libero, lacinia ligula et sociosqu sapien vivamus orci scelerisque est semper senectus. tempor sociosqu ligula mattis potenti donec rhoncus dolor nostra quisque donec eget class, platea lorem lig')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (29, CAST(N'2020-01-29T11:28:06.720' AS DATETIME), CAST(N'2020-01-29T11:28:39.847' AS DATETIME), 287, 287, 0, 171, 18, N'st condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (30, CAST(N'2020-01-29T11:28:06.720' AS DATETIME), CAST(N'2020-01-29T11:28:39.847' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (31, CAST(N'2020-01-29T11:28:06.720' AS DATETIME), CAST(N'2020-01-29T11:28:39.847' AS DATETIME), 287, 287, 0, 171, 20, N'rmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (32, CAST(N'2020-01-29T11:28:06.720' AS DATETIME), CAST(N'2020-01-29T11:28:39.847' AS DATETIME), 287, 287, 0, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (33, CAST(N'2020-01-29T11:28:06.720' AS DATETIME), CAST(N'2020-01-29T11:28:39.847' AS DATETIME), 287, 287, 0, 171, 22, N'rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (34, CAST(N'2020-01-29T11:28:06.720' AS DATETIME), CAST(N'2020-01-29T11:28:39.847' AS DATETIME), 287, 287, 0, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (35, CAST(N'2020-01-29T11:28:39.850' AS DATETIME), CAST(N'2020-02-05T18:02:16.703' AS DATETIME), 287, 287, 0, 171, 18, N'st condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (36, CAST(N'2020-01-29T11:28:39.850' AS DATETIME), CAST(N'2020-02-05T18:02:16.703' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (37, CAST(N'2020-01-29T11:28:39.850' AS DATETIME), CAST(N'2020-02-05T18:02:16.703' AS DATETIME), 287, 287, 0, 171, 20, N'rmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (38, CAST(N'2020-01-29T11:28:39.850' AS DATETIME), CAST(N'2020-02-05T18:02:16.703' AS DATETIME), 287, 287, 0, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (39, CAST(N'2020-01-29T11:28:39.850' AS DATETIME), CAST(N'2020-02-05T18:02:16.703' AS DATETIME), 287, 287, 0, 171, 22, N'rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (40, CAST(N'2020-01-29T11:28:39.850' AS DATETIME), CAST(N'2020-02-05T18:02:16.703' AS DATETIME), 287, 287, 0, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (41, CAST(N'2020-02-05T18:02:16.707' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 18, N'St condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (42, CAST(N'2020-02-05T18:02:16.707' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (43, CAST(N'2020-02-05T18:02:16.707' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 20, N'rmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (44, CAST(N'2020-02-05T18:02:16.707' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (45, CAST(N'2020-02-05T18:02:16.707' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 22, N'rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (46, CAST(N'2020-02-05T18:02:16.707' AS DATETIME), CAST(N'2020-02-05T18:02:44.790' AS DATETIME), 287, 287, 0, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (47, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:19.397' AS DATETIME), 287, 287, 0, 171, 18, N'St condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (48, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:19.397' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (49, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:19.397' AS DATETIME), 287, 287, 0, 171, 20, N'rmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (50, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:19.397' AS DATETIME), 287, 287, 0, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (51, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:19.397' AS DATETIME), 287, 287, 0, 171, 22, N'rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (52, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:19.397' AS DATETIME), 287, 287, 0, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (53, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 1, N'Dictum leo tristique sociosqu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (54, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 2, N'as diam viverra interdum etiam leo purus fringilla sapien, orci dolor arcu elit non conubia dolor elit fermentum nam laoreet, ultrices auctor class maecenas sollicitudin est erat pellentesque mattis')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (55, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 3, N'Dictum leo tristique sociosqu accumsan elit ac por')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (56, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 4, N'molestie platea sem convallis inceptos. egestas nostra torquent per potenti metus at curabitur, habitant diam pretium enim congue inceptos litora fermentum, ornare eget pretium elit nisi ullamcorper. ligula suspendisse pretium phasellus elit molestie eleifend donec, ullamcorper odio donec quis ipsum felis amet sagittis, turpis hendrerit massa amet nibh volutpat.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (57, CAST(N'2020-02-05T18:02:44.797' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 5, N'Et tincidunt a sollicitudin elementum nulla mauris facilisis tincidunt, sollicitudin tellus sit nulla habitant pellent')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (58, CAST(N'2020-02-06T21:41:19.400' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 18, N'St condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (59, CAST(N'2020-02-06T21:41:19.400' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (60, CAST(N'2020-02-06T21:41:19.400' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 20, N'Mmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (61, CAST(N'2020-02-06T21:41:19.400' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (62, CAST(N'2020-02-06T21:41:19.400' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 22, N'Rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (63, CAST(N'2020-02-06T21:41:19.400' AS DATETIME), CAST(N'2020-02-06T21:41:34.397' AS DATETIME), 287, 287, 0, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (64, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 18, N'St condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (65, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (66, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 20, N'Mmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (67, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (68, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 22, N'Rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (69, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (70, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 1, N'Dictum leo tristique sociosqu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (71, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 2, N'as diam viverra interdum etiam leo purus fringilla sapien, orci dolor arcu elit non conubia dolor elit fermentum nam laoreet, ultrices auctor class maecenas sollicitudin est erat pellentesque mattis')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (72, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 3, N'Dictum leo tristique sociosqu accumsan elit ac por')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (73, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 4, N'molestie platea sem convallis inceptos. egestas nostra torquent per potenti metus at curabitur, habitant diam pretium enim congue inceptos litora fermentum, ornare eget pretium elit nisi ullamcorper. ligula suspendisse pretium phasellus elit molestie eleifend donec, ullamcorper odio donec quis ipsum felis amet sagittis, turpis hendrerit massa amet nibh volutpat.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (74, CAST(N'2020-02-06T21:41:34.400' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 287, 287, 0, 171, 5, N'Et tincidunt a sollicitudin elementum nulla mauris facilisis tincidunt, sollicitudin tellus sit nulla habitant pellent')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (75, CAST(N'2020-02-18T20:30:42.780' AS DATETIME), CAST(N'2020-03-02T13:16:42.703' AS DATETIME), 4683, 4683, 0, 1, 24, N'marcus@google.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (76, CAST(N'2020-02-18T20:30:42.780' AS DATETIME), CAST(N'2020-03-02T13:16:42.703' AS DATETIME), 4683, 4683, 0, 1, 25, N'Seu telefone de atendimento')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (77, CAST(N'2020-02-18T21:03:53.520' AS DATETIME), CAST(N'2020-02-19T14:24:18.020' AS DATETIME), 4683, 4683, 0, 2, 24, N'Seu email de atendimento')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (78, CAST(N'2020-02-18T21:03:53.520' AS DATETIME), CAST(N'2020-02-19T14:24:18.020' AS DATETIME), 4683, 4683, 0, 2, 25, N'Seu telefone de atendimento')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (79, CAST(N'2020-02-19T14:24:18.023' AS DATETIME), CAST(N'2020-02-19T14:28:32.880' AS DATETIME), 4683, 4683, 0, 2, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (80, CAST(N'2020-02-19T14:24:18.023' AS DATETIME), CAST(N'2020-02-19T14:28:32.880' AS DATETIME), 4683, 4683, 0, 2, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (81, CAST(N'2020-02-19T14:24:18.023' AS DATETIME), CAST(N'2020-02-19T14:28:32.880' AS DATETIME), 4683, 4683, 0, 2, 24, N'talaricofontes@gmail.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (82, CAST(N'2020-02-19T14:24:18.023' AS DATETIME), CAST(N'2020-02-19T14:28:32.880' AS DATETIME), 4683, 4683, 0, 2, 25, N'+55-00-3244-6700')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (83, CAST(N'2020-02-19T14:28:32.883' AS DATETIME), NULL, 4683, NULL, 1, 2, 26, N'Disponível de segunda a sexta-feira, das 9h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (84, CAST(N'2020-02-19T14:28:32.883' AS DATETIME), NULL, 4683, NULL, 1, 2, 27, N'Disponível de segunda a sexta-feira, das 8h às 17h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (85, CAST(N'2020-02-19T14:28:32.883' AS DATETIME), NULL, 4683, NULL, 1, 2, 24, N'atendimento@celer.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (86, CAST(N'2020-02-19T14:28:32.883' AS DATETIME), NULL, 4683, NULL, 1, 2, 25, N'+55-00-3244-6799')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (87, CAST(N'2020-02-26T17:33:30.520' AS DATETIME), CAST(N'2020-02-26T17:33:58.227' AS DATETIME), 4852, 4852, 0, 171, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (88, CAST(N'2020-02-26T17:33:30.520' AS DATETIME), CAST(N'2020-02-26T17:33:58.227' AS DATETIME), 4852, 4852, 0, 171, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (89, CAST(N'2020-02-26T17:33:30.520' AS DATETIME), CAST(N'2020-02-26T17:33:58.227' AS DATETIME), 4852, 4852, 0, 171, 24, N'ana.liick@c.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (90, CAST(N'2020-02-26T17:33:30.520' AS DATETIME), CAST(N'2020-02-26T17:33:58.227' AS DATETIME), 4852, 4852, 0, 171, 25, N'+55-11-9456-4478')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (91, CAST(N'2020-02-26T17:33:58.237' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 4852, 287, 0, 171, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (92, CAST(N'2020-02-26T17:33:58.237' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 4852, 287, 0, 171, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (93, CAST(N'2020-02-26T17:33:58.237' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 4852, 287, 0, 171, 24, N'teste.c@c.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (94, CAST(N'2020-02-26T17:33:58.237' AS DATETIME), CAST(N'2020-03-21T19:20:00.683' AS DATETIME), 4852, 287, 0, 171, 25, N'+55-11-9456-4478')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (95, CAST(N'2020-02-27T16:47:32.770' AS DATETIME), CAST(N'2020-02-28T11:40:59.030' AS DATETIME), 4852, 4852, 0, 6, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (96, CAST(N'2020-02-27T16:47:32.770' AS DATETIME), CAST(N'2020-02-28T11:40:59.030' AS DATETIME), 4852, 4852, 0, 6, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (97, CAST(N'2020-02-27T16:47:32.770' AS DATETIME), CAST(N'2020-02-28T11:40:59.030' AS DATETIME), 4852, 4852, 0, 6, 24, N'ana.liick@c.b')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (98, CAST(N'2020-02-27T16:47:32.770' AS DATETIME), CAST(N'2020-02-28T11:40:59.030' AS DATETIME), 4852, 4852, 0, 6, 25, N'+55-11-94564-1512')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (99, CAST(N'2020-02-27T18:12:51.593' AS DATETIME), CAST(N'2020-02-27T18:36:58.950' AS DATETIME), 4852, 4852, 0, 16, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
GO
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (100, CAST(N'2020-02-27T18:12:51.593' AS DATETIME), CAST(N'2020-02-27T18:36:58.950' AS DATETIME), 4852, 4852, 0, 16, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (101, CAST(N'2020-02-27T18:12:51.593' AS DATETIME), CAST(N'2020-02-27T18:36:58.950' AS DATETIME), 4852, 4852, 0, 16, 24, N'teste.outrosCanais@h.c')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (102, CAST(N'2020-02-27T18:12:51.593' AS DATETIME), CAST(N'2020-02-27T18:36:58.950' AS DATETIME), 4852, 4852, 0, 16, 25, N'+55-11-94546-5623')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (103, CAST(N'2020-02-27T18:36:59.990' AS DATETIME), NULL, 4852, NULL, 1, 16, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (104, CAST(N'2020-02-27T18:36:59.990' AS DATETIME), NULL, 4852, NULL, 1, 16, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (105, CAST(N'2020-02-27T18:36:59.990' AS DATETIME), NULL, 4852, NULL, 1, 16, 24, N'testtehsbv@bghgdvf.casffd')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (106, CAST(N'2020-02-27T18:36:59.990' AS DATETIME), NULL, 4852, NULL, 1, 16, 25, N'+55-2456-9564')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (107, CAST(N'2020-02-28T11:40:59.060' AS DATETIME), NULL, 4852, NULL, 1, 6, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (108, CAST(N'2020-02-28T11:40:59.060' AS DATETIME), NULL, 4852, NULL, 1, 6, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (109, CAST(N'2020-02-28T11:40:59.060' AS DATETIME), NULL, 4852, NULL, 1, 6, 24, N'teste_Desndmds@c.b')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (110, CAST(N'2020-02-28T11:40:59.060' AS DATETIME), NULL, 4852, NULL, 1, 6, 25, N'+55-11-94564-1512')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (111, CAST(N'2020-03-02T13:16:42.710' AS DATETIME), CAST(N'2020-03-02T13:17:12.637' AS DATETIME), 4683, 4683, 0, 1, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (112, CAST(N'2020-03-02T13:16:42.710' AS DATETIME), CAST(N'2020-03-02T13:17:12.637' AS DATETIME), 4683, 4683, 0, 1, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (113, CAST(N'2020-03-02T13:16:42.710' AS DATETIME), CAST(N'2020-03-02T13:17:12.637' AS DATETIME), 4683, 4683, 0, 1, 24, N'marcus@google.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (114, CAST(N'2020-03-02T13:16:42.710' AS DATETIME), CAST(N'2020-03-02T13:17:12.637' AS DATETIME), 4683, 4683, 0, 1, 25, N'+55-0800-123-5600')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (115, CAST(N'2020-03-02T13:17:12.643' AS DATETIME), NULL, 4683, NULL, 1, 1, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (116, CAST(N'2020-03-02T13:17:12.643' AS DATETIME), NULL, 4683, NULL, 1, 1, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (117, CAST(N'2020-03-02T13:17:12.643' AS DATETIME), NULL, 4683, NULL, 1, 1, 24, N'atendimento@boxinternet.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (118, CAST(N'2020-03-02T13:17:12.643' AS DATETIME), NULL, 4683, NULL, 1, 1, 25, N'+55-0800-123-5600')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (119, CAST(N'2020-03-02T14:06:20.720' AS DATETIME), CAST(N'2020-03-02T14:06:20.720' AS DATETIME), 173, NULL, 1, 172, 1, N'CELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (120, CAST(N'2020-03-02T14:06:20.720' AS DATETIME), CAST(N'2020-03-02T14:06:20.720' AS DATETIME), 173, NULL, 1, 172, 2, N'CELERCELERCELERCELERCELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (121, CAST(N'2020-03-02T14:06:20.720' AS DATETIME), CAST(N'2020-03-02T14:06:20.720' AS DATETIME), 173, NULL, 1, 172, 3, N'CELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (122, CAST(N'2020-03-02T14:06:20.720' AS DATETIME), CAST(N'2020-03-02T14:06:20.720' AS DATETIME), 173, NULL, 1, 172, 4, N'CELERCELERCELERCELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (123, CAST(N'2020-03-02T14:06:20.720' AS DATETIME), CAST(N'2020-03-02T14:06:20.720' AS DATETIME), 173, NULL, 1, 172, 5, N'CELERCELERCELERCELERCELER')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (124, CAST(N'2020-03-03T16:29:43.100' AS DATETIME), CAST(N'2020-03-03T16:51:48.687' AS DATETIME), 173, 173, 0, 174, 1, N'PORTAL DO CLIENTE')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (125, CAST(N'2020-03-03T16:29:43.100' AS DATETIME), CAST(N'2020-03-03T16:51:48.687' AS DATETIME), 173, 173, 0, 174, 2, N'como podemos
te ajudar?')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (126, CAST(N'2020-03-03T16:29:43.100' AS DATETIME), CAST(N'2020-03-03T16:51:48.687' AS DATETIME), 173, 173, 0, 174, 3, N'Dúvidas?')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (127, CAST(N'2020-03-03T16:29:43.100' AS DATETIME), CAST(N'2020-03-03T16:51:48.687' AS DATETIME), 173, 173, 0, 174, 4, N'Ligue para a nossa central')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (128, CAST(N'2020-03-03T16:29:43.100' AS DATETIME), CAST(N'2020-03-03T16:51:48.687' AS DATETIME), 173, 173, 0, 174, 5, N'(11) 4002-8922')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (129, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T17:13:57.130' AS DATETIME), 173, 173, 0, 174, 18, N'Promoção de bicicletas')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (130, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T17:13:57.130' AS DATETIME), 173, 173, 0, 174, 19, N'Montagem de todos os opcionais na retirada')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (131, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T17:13:57.130' AS DATETIME), 173, 173, 0, 174, 20, N'Roupas Esportivas')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (132, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T17:13:57.130' AS DATETIME), 173, 173, 0, 174, 21, N'Produtos com até 60% de desconto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (133, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T17:13:57.130' AS DATETIME), 173, 173, 0, 174, 22, N'Chinelos Slide')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (134, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T17:13:57.130' AS DATETIME), 173, 173, 0, 174, 23, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (135, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 1, N'PORTAL DO CLIENTE')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (136, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 2, N'como podemos
te ajudar?')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (137, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 3, N'Dúvidas?')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (138, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 4, N'Ligue para a nossa central')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (139, CAST(N'2020-03-03T16:51:48.690' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 5, N'(11) 4002-8922')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (140, CAST(N'2020-03-03T16:53:54.647' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (141, CAST(N'2020-03-03T16:53:54.647' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (142, CAST(N'2020-03-03T16:53:54.647' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 24, N'atendimento@centauro.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (143, CAST(N'2020-03-03T16:53:54.647' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 25, N'+55-11-4002-8922')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (144, CAST(N'2020-03-03T17:13:57.133' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 18, N'Promoção de bicicletas')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (145, CAST(N'2020-03-03T17:13:57.133' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 19, N'Montagem de todos os opcionais na retirada')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (146, CAST(N'2020-03-03T17:13:57.133' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 20, N'Roupas Esportivas')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (147, CAST(N'2020-03-03T17:13:57.133' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 21, N'Montagem de todos os opcionais na retirada')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (148, CAST(N'2020-03-03T17:13:57.133' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 22, N'Chinelos Slide')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (149, CAST(N'2020-03-03T17:13:57.133' AS DATETIME), CAST(N'2020-03-03T18:15:50.793' AS DATETIME), 173, 173, 0, 174, 23, N'Montagem de todos os opcionais na retirada')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (150, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 18, N'Promoção de bicicletas')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (151, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 19, N'Montagem de todos os opcionais na retirada')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (152, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 20, N'Roupas Esportivas')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (153, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 21, N'Montagem da mamae')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (154, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 22, N'Chinelos Slide')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (155, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 23, N'montagem do papai')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (156, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 1, N'PORTAL DO CLIENTE')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (157, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 2, N'como podemos
te ajudar?')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (158, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 3, N'Dúvidas?')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (159, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 4, N'Ligue para a nossa central')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (160, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 5, N'(11) 4002-8922')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (161, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (162, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (163, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 24, N'atendimento@centauro.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (164, CAST(N'2020-03-03T18:15:50.797' AS DATETIME), NULL, 173, NULL, 1, 174, 25, N'+55-11-4002-8922')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (165, CAST(N'2020-03-09T14:44:20.853' AS DATETIME), CAST(N'2020-03-09T14:46:11.540' AS DATETIME), 173, 173, 0, 175, 18, N'Teste de texto 1')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (166, CAST(N'2020-03-09T14:44:20.853' AS DATETIME), CAST(N'2020-03-09T14:46:11.540' AS DATETIME), 173, 173, 0, 175, 19, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (167, CAST(N'2020-03-09T14:44:20.853' AS DATETIME), CAST(N'2020-03-09T14:46:11.540' AS DATETIME), 173, 173, 0, 175, 20, N'Teste de texto 2')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (168, CAST(N'2020-03-09T14:44:20.853' AS DATETIME), CAST(N'2020-03-09T14:46:11.540' AS DATETIME), 173, 173, 0, 175, 21, N'Descrição do segundo texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (169, CAST(N'2020-03-09T14:44:20.853' AS DATETIME), CAST(N'2020-03-09T14:46:11.540' AS DATETIME), 173, 173, 0, 175, 22, N'Descrição do terceiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (170, CAST(N'2020-03-09T14:44:20.853' AS DATETIME), CAST(N'2020-03-09T14:46:11.540' AS DATETIME), 173, 173, 0, 175, 23, N'Aoba basdhbjhasd')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (171, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 18, N'Teste de texto 1')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (172, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 19, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (173, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 20, N'Teste de texto 2')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (174, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 21, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (175, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 22, N'Descrição do terceiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (176, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 23, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (177, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 1, N'Digitei aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (178, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 2, N'Digitei aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (179, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 3, N'Digiteiaqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (180, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 4, N'Digitei aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (181, CAST(N'2020-03-09T14:46:11.543' AS DATETIME), CAST(N'2020-03-09T14:50:03.003' AS DATETIME), 173, 173, 0, 175, 5, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (182, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 18, N'Teste de texto 1')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (183, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 19, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (184, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 20, N'Teste de texto 2')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (185, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 21, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (186, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 22, N'Descrição do terceiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (187, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 23, N'Descrição do primeiro texto')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (188, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 1, N'Digitei aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (189, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 2, N'Digitei aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (190, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 3, N'Digiteiaqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (191, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 4, N'Digitei aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (192, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 5, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (193, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (194, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (195, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 24, N'atendimento@redbull.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (196, CAST(N'2020-03-09T14:50:03.010' AS DATETIME), NULL, 173, NULL, 1, 175, 25, N'+55-11-54994-5894')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (197, CAST(N'2020-03-16T14:35:33.110' AS DATETIME), CAST(N'2020-03-16T14:35:48.633' AS DATETIME), 173, 173, 0, 7, 18, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (198, CAST(N'2020-03-16T14:35:33.110' AS DATETIME), CAST(N'2020-03-16T14:35:48.633' AS DATETIME), 173, 173, 0, 7, 19, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (199, CAST(N'2020-03-16T14:35:33.110' AS DATETIME), CAST(N'2020-03-16T14:35:48.633' AS DATETIME), 173, 173, 0, 7, 20, N'Digite aqui o título 02')
GO
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (200, CAST(N'2020-03-16T14:35:33.110' AS DATETIME), CAST(N'2020-03-16T14:35:48.633' AS DATETIME), 173, 173, 0, 7, 21, N' Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (201, CAST(N'2020-03-16T14:35:33.110' AS DATETIME), CAST(N'2020-03-16T14:35:48.633' AS DATETIME), 173, 173, 0, 7, 22, N'Digite aqui o título 03')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (202, CAST(N'2020-03-16T14:35:33.110' AS DATETIME), CAST(N'2020-03-16T14:35:48.633' AS DATETIME), 173, 173, 0, 7, 23, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (203, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 18, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (204, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 19, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (205, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 20, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (206, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 21, N' Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (207, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 22, N'Digite aqui o título 03')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (208, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 23, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (209, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 1, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (210, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 2, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (211, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 3, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (212, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 4, N'Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (213, CAST(N'2020-03-16T14:35:48.637' AS DATETIME), CAST(N'2020-03-16T14:37:19.833' AS DATETIME), 173, 173, 0, 7, 5, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (214, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 18, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (215, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 19, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (216, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 20, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (217, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 21, N' Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (218, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 22, N'Digite aqui o título 03')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (219, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 23, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (220, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 1, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (221, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 2, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (222, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 3, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (223, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 4, N'Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (224, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 5, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (225, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (226, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (227, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 24, N'bla@gmail.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (228, CAST(N'2020-03-16T14:37:19.840' AS DATETIME), NULL, 173, NULL, 1, 7, 25, N'+55-11-11111-1111')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (229, CAST(N'2020-03-20T15:50:41.647' AS DATETIME), CAST(N'2020-03-20T15:58:27.540' AS DATETIME), 173, 173, 0, 176, 18, N'Mais emoção, mais que 3D: REAL')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (230, CAST(N'2020-03-20T15:50:41.647' AS DATETIME), CAST(N'2020-03-20T15:58:27.540' AS DATETIME), 173, 173, 0, 176, 19, N'Nas salas 3D da rede Cinemark você vive a experiência tridimensional REAL D 3D com muito mais emoção. Com a tecnologia REAL D 3D a fusão das imagens preserva a noção de profundidade e torna a sensação de mergulhar no universo do filme ainda mais intensa e verdadeira. Esse é o sistema de projeção líder mundial no segmento, e oferece uma experiência única, idêntica ao que nossos olhos veem naturalmente.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (231, CAST(N'2020-03-20T15:50:41.647' AS DATETIME), CAST(N'2020-03-20T15:58:27.540' AS DATETIME), 173, 173, 0, 176, 20, N'Cinemark Movie Bistrô')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (232, CAST(N'2020-03-20T15:50:41.647' AS DATETIME), CAST(N'2020-03-20T15:58:27.540' AS DATETIME), 173, 173, 0, 176, 21, N'Nas salas Movie Bistrô, sua ida ao cinema se torna uma nova experiência. Você pode se acomodar nas poltronas em couro ecológico acompanhadas de mesinhas individuais e que podem ser transformadas em cadeiras namoradeiras, as “Love Seats”. Aproveite também uma carta especial de bebidas, comidinhas e pipocas gourmet.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (233, CAST(N'2020-03-20T15:50:41.647' AS DATETIME), CAST(N'2020-03-20T15:58:27.540' AS DATETIME), 173, 173, 0, 176, 22, N'Salas Bradesco Prime')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (234, CAST(N'2020-03-20T15:50:41.647' AS DATETIME), CAST(N'2020-03-20T15:58:27.540' AS DATETIME), 173, 173, 0, 176, 23, N'Sua diversão ganha um toque de sofisticação e exclusividade do início ao fim. O lounge com arquitetura exclusiva, o Snack Bar com carta de vinhos, comidinhas e pipocas gourmet, as poltronas de couro totalmente reclináveis: tudo foi preparado para oferecer um momento realmente especial para você. Encontre uma sala Bradesco Prime e descubra como a experiência de cinema pode ser ainda mais incrível.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (235, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 18, N'Mais emoção, mais que 3D: REAL')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (236, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 19, N'Nas salas 3D da rede Cinemark você vive a experiência tridimensional REAL D 3D com muito mais emoção. Com a tecnologia REAL D 3D a fusão das imagens preserva a noção de profundidade e torna a sensação de mergulhar no universo do filme ainda mais intensa e verdadeira. Esse é o sistema de projeção líder mundial no segmento, e oferece uma experiência única, idêntica ao que nossos olhos veem naturalmente.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (237, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 20, N'Cinemark Movie Bistrô')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (238, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 21, N'Nas salas 3D da rede Cinemark você vive a experiência tridimensional REAL D 3D com muito mais emoção. Com a tecnologia REAL D 3D a fusão das imagens preserva a noção de profundidade e torna a sensação de mergulhar no universo do filme ainda mais intensa e verdadeira. Esse é o sistema de projeção líder mundial no segmento, e oferece uma experiência única, idêntica ao que nossos olhos veem naturalmente.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (239, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 22, N'Salas Bradesco Prime')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (240, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 23, N'Nas salas 3D da rede Cinemark você vive a experiência tridimensional REAL D 3D com muito mais emoção. Com a tecnologia REAL D 3D a fusão das imagens preserva a noção de profundidade e torna a sensação de mergulhar no universo do filme ainda mais intensa e verdadeira. Esse é o sistema de projeção líder mundial no segmento, e oferece uma experiência única, idêntica ao que nossos olhos veem naturalmente.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (241, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 1, N'É MAIS QUE CINEMA. É CINEMARK.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (242, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 2, N'Nós nos dedicamos a proporcionar uma experiência cinematográfica inesquecível para cada um de nosso Clientes.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (243, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 3, N'NOSSA VISÃO')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (244, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 4, N'Moldar o futuro da indústria ao sermos reconhecidos como a rede de entretenimento fora de casa mais influente do mundo.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (245, CAST(N'2020-03-20T15:58:27.550' AS DATETIME), NULL, 173, NULL, 1, 176, 5, N'Respeitamos e cuidamos de cada um dos nossos Clientes, dos nossos Parceiros e da Comunidade.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (246, CAST(N'2020-03-20T16:15:48.353' AS DATETIME), NULL, 173, NULL, 1, 176, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (247, CAST(N'2020-03-20T16:15:48.353' AS DATETIME), NULL, 173, NULL, 1, 176, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (248, CAST(N'2020-03-20T16:15:48.353' AS DATETIME), NULL, 173, NULL, 1, 176, 24, N'cinemark@atendimento.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (249, CAST(N'2020-03-20T16:15:48.353' AS DATETIME), NULL, 173, NULL, 1, 176, 25, N'+55-11-4002-8922')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (250, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 18, N'St condimentum curae amet')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (251, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 19, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (252, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 20, N'Mmentum inceptos feugiat')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (253, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 21, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (254, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 22, N'Rmentum inceptos feugiat qu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (255, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 23, N'lutpat vehicula, velit taciti himenaeos lectus ultrices volutpat nunc. sit primis pretium id metus ullamcorper velit interdum egestas ac dapibus, senectus sit euismod morbi dapibus et lobortis proin lobortis quam, adipiscing diam bibendum accumsan sagittis metus ipsum lacus feugiat. aliquam fusce et sollicitudin blandit vel luctus neque sollicitudin, vehicula commodo fermentum scelerisque nec vehicula imperdiet dui, sagittis porta urna commodo suscipit maecenas nec.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (256, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 1, N'Dictum leo tristique sociosqu')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (257, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 2, N'as diam viverra interdum etiam leo purus fringilla sapien, orci dolor arcu elit non conubia dolor elit fermentum nam laoreet, ultrices auctor class maecenas sollicitudin est erat pellentesque mattis')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (258, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 3, N'Dictum leo tristique sociosqu accumsan elit ac por')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (259, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 4, N'molestie platea sem convallis inceptos. egestas nostra torquent per potenti metus at curabitur, habitant diam pretium enim congue inceptos litora fermentum, ornare eget pretium elit nisi ullamcorper. ligula suspendisse pretium phasellus elit molestie eleifend donec, ullamcorper odio donec quis ipsum felis amet sagittis, turpis hendrerit massa amet nibh volutpat.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (260, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 5, N'Et tincidunt a sollicitudin elementum nulla mauris facilisis tincidunt, sollicitudin tellus sit nulla habitant pellent')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (261, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (262, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (263, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 24, N'teste.c@c.com.br')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (264, CAST(N'2020-03-21T19:20:00.690' AS DATETIME), NULL, 287, NULL, 1, 171, 25, N'+55-11-9456-4478')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (265, CAST(N'2020-03-21T20:00:10.660' AS DATETIME), CAST(N'2020-03-21T20:01:07.807' AS DATETIME), 287, 287, 0, 177, 18, N'Lacinia dictum urna dictum cub')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (266, CAST(N'2020-03-21T20:00:10.660' AS DATETIME), CAST(N'2020-03-21T20:01:07.807' AS DATETIME), 287, 287, 0, 177, 19, N'felis. rhoncus porttitor volutpat lorem viverra elementum quis adipiscing nibh a duis, leo aenean eget varius class eu ullamcorper felis venenatis egestas, amet maecenas magna scelerisque libero mollis placerat porta platea. adipiscing fermentum nunc ipsum proin facilisis vitae proin lacus egestas posuere blandit congue, dolor cras libero sit netus vulputate nec class erat nibh molestie, aliquam nullam condimentum netus euismod massa taciti velit cursus quis aptent. luctus maecenas aliquam risus odio etiam quam mollis, iaculis turpis sit fusce magna leo venenatis aliquet, a non feugiat vulputate sapien ut.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (267, CAST(N'2020-03-21T20:00:10.660' AS DATETIME), CAST(N'2020-03-21T20:01:07.807' AS DATETIME), 287, 287, 0, 177, 20, N'Lacinia dictum urna dictum cub')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (268, CAST(N'2020-03-21T20:00:10.660' AS DATETIME), CAST(N'2020-03-21T20:01:07.807' AS DATETIME), 287, 287, 0, 177, 21, N'Digite aqui 2º conteúdo felis. rhoncus porttitor volutpat lorem viverra elementum quis adipiscing nibh a duis, leo aenean eget varius class eu ullamcorper felis venenatis egestas, amet maecenas magna scelerisque libero mollis placerat porta platea. adipiscing fermentum nunc ipsum proin facilisis vitae proin lacus egestas posuere blandit congue, dolor cras libero sit netus vulputate nec class erat nibh molestie, aliquam nullam condimentum netus euismod massa taciti velit cursus quis aptent. luctus maecenas aliquam risus odio etiam quam mollis, iaculis turpis sit fusce magna leo venenatis aliquet, a non feugiat vulputate sapien ut.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (269, CAST(N'2020-03-21T20:00:10.660' AS DATETIME), CAST(N'2020-03-21T20:01:07.807' AS DATETIME), 287, 287, 0, 177, 22, N'ntesque tempor. taciti fringil')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (270, CAST(N'2020-03-21T20:00:10.660' AS DATETIME), CAST(N'2020-03-21T20:01:07.807' AS DATETIME), 287, 287, 0, 177, 23, N'felis. rhoncus porttitor volutpat lorem viverra elementum quis adipiscing nibh a duis, leo aenean eget varius class eu ullamcorper felis venenatis egestas, amet maecenas magna scelerisque libero mollis placerat porta platea. adipiscing fermentum nunc ipsum proin facilisis vitae proin lacus egestas posuere blandit congue, dolor cras libero sit netus vulputate nec class erat nibh molestie, aliquam nullam condimentum netus euismod massa taciti velit cursus quis aptent. luctus maecenas aliquam risus odio etiam quam mollis, iaculis turpis sit fusce magna leo venenatis aliquet, a non feugiat vulputate sapien ut.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (271, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 18, N'Lacinia dictum urna dictum cub')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (272, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 19, N'felis. rhoncus porttitor volutpat lorem viverra elementum quis adipiscing nibh a duis, leo aenean eget varius class eu ullamcorper felis venenatis egestas, amet maecenas magna scelerisque libero mollis placerat porta platea. adipiscing fermentum nunc ipsum proin facilisis vitae proin lacus egestas posuere blandit congue, dolor cras libero sit netus vulputate nec class erat nibh molestie, aliquam nullam condimentum netus euismod massa taciti velit cursus quis aptent. luctus maecenas aliquam risus odio etiam quam mollis, iaculis turpis sit fusce magna leo venenatis aliquet, a non feugiat vulputate sapien ut.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (273, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 20, N'Lacinia dictum urna dictum cub')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (274, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 21, N'Digite aqui 2º conteúdo felis. rhoncus porttitor volutpat lorem viverra elementum quis adipiscing nibh a duis, leo aenean eget varius class eu ullamcorper felis venenatis egestas, amet maecenas magna scelerisque libero mollis placerat porta platea. adipiscing fermentum nunc ipsum proin facilisis vitae proin lacus egestas posuere blandit congue, dolor cras libero sit netus vulputate nec class erat nibh molestie, aliquam nullam condimentum netus euismod massa taciti velit cursus quis aptent. luctus maecenas aliquam risus odio etiam quam mollis, iaculis turpis sit fusce magna leo venenatis aliquet, a non feugiat vulputate sapien ut.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (275, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 22, N'ntesque tempor. taciti fringil')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (276, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 23, N'felis. rhoncus porttitor volutpat lorem viverra elementum quis adipiscing nibh a duis, leo aenean eget varius class eu ullamcorper felis venenatis egestas, amet maecenas magna scelerisque libero mollis placerat porta platea. adipiscing fermentum nunc ipsum proin facilisis vitae proin lacus egestas posuere blandit congue, dolor cras libero sit netus vulputate nec class erat nibh molestie, aliquam nullam condimentum netus euismod massa taciti velit cursus quis aptent. luctus maecenas aliquam risus odio etiam quam mollis, iaculis turpis sit fusce magna leo venenatis aliquet, a non feugiat vulputate sapien ut.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (277, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 1, N'ntesque tempor. taciti fringig')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (278, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 2, N'ntesque tempor. taciti fringilla ulla')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (279, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 3, N'ntesque tempor. taciti fringilla ulla')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (280, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 4, N'Felis tempus hac semper morbi sollicitudin tincidunt primis senectus tellus dictum, porttitor aenean rutrum magna gravida eleifend lobortis praesent turpis arcu velit, inceptos tempus ornare amet curae ullamcorper interdum pellentesque tempor. taciti fringilla ullamcorper diam vitae varius consequat semper nam rhoncus suspendisse tortor porta, interdum blandit eros dictumst massa ac ornare felis euismod nisl bibendum velit phasellus, condimentum etiam praesent duis per leo tincidunt fringilla semper quam magna. purus volutpat amet vestibulum potenti posuere hac, consectetur scelerisque gravida cursus phasellus duis maecenas, inceptos per nisl pulvinar arcu. scelerisque per cubilia id diam per interdum sit consectetur risus venenatis nunc morbi hendrerit risus platea, risus eros lobortis in')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (281, CAST(N'2020-03-21T20:01:07.810' AS DATETIME), NULL, 287, NULL, 1, 177, 5, N'Felis tempus hac semper morbi sollicitudin tincidunt primis senectus tellus dictum, porttitor aenean rutrum magna gravida eleifend lobortis praesent turpis arcu velit, inceptos tempus ornare amet curae ullamcorper interdum pellentesque')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (282, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 18, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (283, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 19, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (284, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 20, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (285, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 21, N' Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (286, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 22, N'Digite aqui o título 03')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (287, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 23, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (288, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 1, N'Digite aqui o título 01')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (289, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 2, N'Digite aqui 1º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (290, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 3, N'Digite aqui o título 02')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (291, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 4, N'Digite aqui 2º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (292, CAST(N'2020-04-13T16:03:53.637' AS DATETIME), NULL, 173, NULL, 1, 86, 5, N'Digite aqui 3º conteúdo')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (293, CAST(N'2020-04-13T18:01:36.050' AS DATETIME), NULL, 173, NULL, 1, 86, 26, N'Disponível de segunda a sexta-feira, das 8h às 21h.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (294, CAST(N'2020-04-13T18:01:36.050' AS DATETIME), NULL, 173, NULL, 1, 86, 27, N'Disponível de segunda a sexta-feira, das 8h às 21h. Ligação gratuita.')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (295, CAST(N'2020-04-13T18:01:36.050' AS DATETIME), NULL, 173, NULL, 1, 86, 24, N'teste@gmail.com')
INSERT [dbo].[ECOMMERCE_THEMES_TEXT] ([COD_ECOMMERCE_TEXT], [CREATED_AT], [MODIFY_DATE], [COD_USER_CAD], [COD_USER_ALT], [ACTIVE], [COD_AFFILIATOR], [COD_WL_CUSTOM_TEXT], [TEXT])
	VALUES (296, CAST(N'2020-04-13T18:01:36.050' AS DATETIME), NULL, 173, NULL, 1, 86, 25, N'+55-11-11111-1111')
SET IDENTITY_INSERT [dbo].[ECOMMERCE_THEMES_TEXT] OFF


GO
   
  
CREATE PROCEDURE [dbo].[SP_WL_CONTENT_TYPE]  
AS  
  
BEGIN

SELECT
	COD_WL_CONT_TYPE
   ,CODE
   ,DESCRIPTION
FROM WL_CONTENT_TYPE


END;


GO

  /****** Object:  UserDefinedTableType [dbo].[TP_ECOMMERCE_PLAN]    Script Date: 27/04/2020 16:23:11 ******/
CREATE TYPE [dbo].[TP_ECOMMERCE_PLAN] AS TABLE(
	[PLAN_NAME] [varchar](255) NULL,
	[COD_PLAN_TYPE] [int] NULL,
	[COD_USER] [int] NULL,
	[COD_AFFILIATOR] [int] NULL,
	[COD_COMP] [int] NULL,
	[COD_TRAN_TYPE] [int] NULL,
	[MDR_DEBIT] [decimal](22, 8) NULL,
	[MDR_CREDIT] [decimal](22, 8) NULL,
	[MDR_CREDIT_INSTALLMENT] [decimal](22, 8) NULL,
	[INTERVAL_DEBIT] [int] NULL,
	[INTERVAL_CREDIT] [int] NULL,
	[ANTECIPATION] [decimal](22, 8) NULL
)
GO
/****** Object:  UserDefinedTableType [dbo].[TP_THEMES_COLORS]    Script Date: 27/04/2020 16:23:11 ******/
CREATE TYPE [dbo].[TP_THEMES_COLORS] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[COD_WL_COLORS] [int] NULL,
	[COLOR] [varchar](400) NULL
)
GO
/****** Object:  UserDefinedTableType [dbo].[TP_THEMES_IMG]    Script Date: 27/04/2020 16:23:12 ******/

/****** Object:  UserDefinedTableType [dbo].[TP_THEMES_TEXT]    Script Date: 27/04/2020 16:23:12 ******/
CREATE TYPE [dbo].[TP_THEMES_TEXT] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[COD_WL_CUSTOM_TEXT] [int] NULL,
	[TEXT] [varchar](max) NULL
)
GO











--CREATE PROCEDURE [dbo].[SP_REG_DOCUMENTS_AFFILIATOR]  
-- /*----------------------------------------------------------------------------------------                                
-- Procedure Name: SP_REG_DOCUMENTS_AFFILIATOR                                
-- Project.......: TKPP                                
-- ------------------------------------------------------------------------------------------                                
-- Author                          VERSION        Date             Description                                
-- ------------------------------------------------------------------------------------------                                
-- Elir Ribeiro      v1   2020-01-23       crindo procedure para registrar na base de dados       
-- ------------------------------------------------------------------------------------------*/   
--@DOCUMENTS VARCHAR(100),  
--@COD_USER INT,  
--@COD_AFFILIATOR INT,  
--@COD_DOC_TYPE INT  
--AS
--INSERT INTO DOCS_AFFILIATOR (DOCUMENTS, COD_USER_CREATE, CREATED_AT, ACTIVE, COD_AFFILIATOR, COD_TYPE_CONTRACTS)
--	VALUES (@DOCUMENTS, @COD_USER, current_timestamp, 1, @COD_AFFILIATOR, @COD_DOC_TYPE)
--GO
--/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_ABOUT]    Script Date: 27/04/2020 16:01:15 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
GO

/****** Object:  UserDefinedTableType [dbo].[TP_THEMES_IMG]    Script Date: 03/05/2020 16:21:23 ******/
CREATE TYPE [dbo].[TP_THEMES_IMG] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[COD_WL_CONT_TYPE] [int] NULL,
	[PATH_CONTENT] [varchar](400) NULL,
	[COD_MODEL] [int] NULL
)
GO



CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_ABOUT]

	/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_REG_ECOMMERCE_ABOUT]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para o registro o contúdp da tela "about" do Ecommerce
------------------------------------------------------------------------------------------*/

(
	@THEMES_IMG [TP_THEMES_IMG] READONLY,
	@THEMES_TEXT [TP_THEMES_TEXT] READONLY
)
AS
BEGIN

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

INSERT INTO ECOMMERCE_THEMES_IMG (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_CONT_TYPE,
PATH_CONTENT,
COD_MODEL)
	SELECT
		THEMES_IMG.COD_USER
	   ,THEMES_IMG.COD_AFF
	   ,THEMES_IMG.COD_WL_CONT_TYPE
	   ,THEMES_IMG.PATH_CONTENT
	   ,THEMES_IMG.COD_MODEL
	FROM @THEMES_IMG THEMES_IMG;


UPDATE ECOMMERCE_THEMES_TEXT
SET ACTIVE = 0
   ,MODIFY_DATE = current_timestamp
   ,COD_USER_ALT = THEMES_TEXT.COD_USER
FROM ECOMMERCE_THEMES_TEXT
JOIN @THEMES_TEXT THEMES_TEXT
	ON THEMES_TEXT.COD_AFF = ECOMMERCE_THEMES_TEXT.COD_AFFILIATOR
	AND ECOMMERCE_THEMES_TEXT.ACTIVE = 1
WHERE ECOMMERCE_THEMES_TEXT.COD_WL_CUSTOM_TEXT = THEMES_TEXT.COD_WL_CUSTOM_TEXT;

INSERT INTO ECOMMERCE_THEMES_TEXT (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_CUSTOM_TEXT,
[TEXT])
	SELECT
		THEMES_TEXT.COD_USER
	   ,THEMES_TEXT.COD_AFF
	   ,THEMES_TEXT.COD_WL_CUSTOM_TEXT
	   ,THEMES_TEXT.[TEXT]
	FROM @THEMES_TEXT THEMES_TEXT;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_BENEFITS]    Script Date: 27/04/2020 16:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_BENEFITS]

/***************************************************************************************************
----------------------------------------------------------------------------------------  
Procedure Name: [[SP_REG_ECOMMERCE_BENEFITS]]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para o registro o contúdp da tela "Benefits" do Ecommerce
------------------------------------------------------------------------------------------
***************************************************************************************************/

(
	@THEMES_IMG  [TP_THEMES_IMG] READONLY, 
	@THEMES_TEXT [TP_THEMES_TEXT] READONLY)
AS
BEGIN

UPDATE [ECOMMERCE_THEMES_IMG]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = current_timestamp
   ,[COD_USER_ALT] = [THEMES_IMG].[COD_USER]
FROM [ECOMMERCE_THEMES_IMG]
JOIN @THEMES_IMG [THEMES_IMG]
	ON [THEMES_IMG].[COD_AFF] = [ECOMMERCE_THEMES_IMG].[COD_AFFILIATOR]
	AND [ECOMMERCE_THEMES_IMG].[ACTIVE] = 1
WHERE [ECOMMERCE_THEMES_IMG].[COD_WL_CONT_TYPE] = [THEMES_IMG].[COD_WL_CONT_TYPE]
AND (([THEMES_IMG].[COD_MODEL] IS NOT NULL
AND [ECOMMERCE_THEMES_IMG].[COD_MODEL] = [THEMES_IMG].[COD_MODEL])
OR ([THEMES_IMG].[COD_MODEL] IS NULL
AND [ECOMMERCE_THEMES_IMG].[COD_MODEL] IS NULL));

INSERT INTO [ECOMMERCE_THEMES_IMG] ([COD_USER_CAD],
[COD_AFFILIATOR],
[COD_WL_CONT_TYPE],
[PATH_CONTENT],
[COD_MODEL])
	SELECT
		[THEMES_IMG].[COD_USER]
	   ,[THEMES_IMG].[COD_AFF]
	   ,[THEMES_IMG].[COD_WL_CONT_TYPE]
	   ,[THEMES_IMG].[PATH_CONTENT]
	   ,[THEMES_IMG].[COD_MODEL]
	FROM @THEMES_IMG AS [THEMES_IMG];


UPDATE [ECOMMERCE_THEMES_TEXT]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = current_timestamp
   ,[COD_USER_ALT] = [THEMES_TEXT].[COD_USER]
FROM [ECOMMERCE_THEMES_TEXT]
JOIN @THEMES_TEXT [THEMES_TEXT]
	ON [THEMES_TEXT].[COD_AFF] = [ECOMMERCE_THEMES_TEXT].[COD_AFFILIATOR]
	AND [ECOMMERCE_THEMES_TEXT].[ACTIVE] = 1
WHERE [ECOMMERCE_THEMES_TEXT].[COD_WL_CUSTOM_TEXT] = [THEMES_TEXT].[COD_WL_CUSTOM_TEXT];

INSERT INTO [ECOMMERCE_THEMES_TEXT] ([COD_USER_CAD],
[COD_AFFILIATOR],
[COD_WL_CUSTOM_TEXT],
[TEXT])
	SELECT
		[THEMES_TEXT].[COD_USER]
	   ,[THEMES_TEXT].[COD_AFF]
	   ,[THEMES_TEXT].[COD_WL_CUSTOM_TEXT]
	   ,[THEMES_TEXT].[TEXT]
	FROM @THEMES_TEXT AS [THEMES_TEXT];
END;

GO
/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_COLORS]    Script Date: 27/04/2020 16:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_COLORS]

	/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_REG_ECOMMERCE_COLORS]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para o registro das imagens do Ecommerce
------------------------------------------------------------------------------------------*/

	(@THEMES_COLORS [TP_THEMES_COLORS] READONLY
)
AS
BEGIN
UPDATE ECOMMERCE_THEMES_COLORS
SET ACTIVE = 0
   ,MODIFY_DATE = current_timestamp
   ,COD_USER_ALT = THEMES_COLORS.COD_USER
FROM ECOMMERCE_THEMES_COLORS
JOIN @THEMES_COLORS THEMES_COLORS
	ON THEMES_COLORS.COD_AFF = ECOMMERCE_THEMES_COLORS.COD_AFFILIATOR
	AND ECOMMERCE_THEMES_COLORS.ACTIVE = 1
WHERE ECOMMERCE_THEMES_COLORS.COD_WL_COLORS = THEMES_COLORS.COD_WL_COLORS;

INSERT INTO ECOMMERCE_THEMES_COLORS (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_COLORS,
COLOR)
	SELECT
		THEMES_COLOR.COD_USER
	   ,THEMES_COLOR.COD_AFF
	   ,THEMES_COLOR.COD_WL_COLORS
	   ,THEMES_COLOR.COLOR
	FROM @THEMES_COLORS THEMES_COLOR;

IF @@rowcount <= 0
THROW 60000, 'COULD NOT REGISTER ECOMMERCE_THEMES_COLORS', 1;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_IMG]    Script Date: 27/04/2020 16:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_IMG]

	/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_REG_ECOMMERCE_IMG]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-07				Procedure para o registro das imagens do Ecommerce
------------------------------------------------------------------------------------------*/

	(@THEMES_IMG [TP_THEMES_IMG] READONLY
)
AS
BEGIN
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

INSERT INTO ECOMMERCE_THEMES_IMG (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_CONT_TYPE,
PATH_CONTENT,
COD_MODEL)
	SELECT
		THEMES_IMG.COD_USER
	   ,THEMES_IMG.COD_AFF
	   ,THEMES_IMG.COD_WL_CONT_TYPE
	   ,THEMES_IMG.PATH_CONTENT
	   ,THEMES_IMG.COD_MODEL
	FROM @THEMES_IMG THEMES_IMG;

IF @@rowcount <= 0
THROW 60000, 'COULD NOT REGISTER ECOMMERCE_THEMES_IMG', 1;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_INFO]    Script Date: 27/04/2020 16:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_INFO]
/*----------------------------------------------------------------------------------------
   Project.......: TKPP
------------------------------------------------------------------------------------------
   Author              VERSION        Date      Description
------------------------------------------------------------------------------------------
   Luiz Aquino          v1          2020-02-27  Add url WhiteLabel
------------------------------------------------------------------------------------------*/

( @COD_AFFILIATOR INT, @urlWhiteLabel VARCHAR(128) = null)
AS
BEGIN

    IF @urlWhiteLabel IS NOT NULL
    BEGIN
UPDATE AFFILIATOR
SET WHITELABEL_URL = @urlWhiteLabel
WHERE COD_AFFILIATOR = @COD_AFFILIATOR
END

END;
GO
/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_PLAN]    Script Date: 27/04/2020 16:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_PLAN]

/*******************************************************************************************
----------------------------------------------------------------------------------------  
Procedure Name: [SP_REG_ECOMMERCE_PLAN]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author              VERSION        Date						Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar		v1			   2019-11-21				Procedure para o cadastro do plano - ecommerce
------------------------------------------------------------------------------------------
*******************************************************************************************/

(
	@TP_PLAN [TP_ECOMMERCE_PLAN] READONLY)
AS
    BEGIN
	   DECLARE 
			@COD_PLAN INT;
UPDATE [TAX_PLAN]
SET [ACTIVE] = 0
FROM [TAX_PLAN]
JOIN [PLAN]
	ON [PLAN].[COD_PLAN] = [TAX_PLAN].[COD_PLAN]
JOIN @TP_PLAN [TP]
	ON [TP].[COD_AFFILIATOR] = [PLAN].[COD_AFFILIATOR]
	AND [AVAILABLE_SALE] = 1
	AND [PLAN].[ACTIVE] = 1
	AND [PLAN].[COD_T_PLAN] = [TP].[COD_PLAN_TYPE];
UPDATE [PLAN]
SET [PLAN].[ACTIVE] = 0
   ,[PLAN].[MODIFY_DATE] = current_timestamp
   ,[PLAN].[COD_USER_MODIFY] = [TP].[COD_USER]
FROM [PLAN]
JOIN @TP_PLAN [TP]
	ON [TP].[COD_AFFILIATOR] = [PLAN].[COD_AFFILIATOR]
	AND [AVAILABLE_SALE] = 1
	AND [PLAN].[ACTIVE] = 1
	AND [PLAN].[COD_T_PLAN] = [TP].[COD_PLAN_TYPE];
DECLARE @PLAN_NAME VARCHAR(255)
	   ,@COD_PLAN_TYPE INT
	   ,@COD_USER INT
	   ,@COD_AFFILIATOR INT
	   ,@COD_COMP INT
	   ,@MDR_DEBIT DECIMAL(22, 8)
	   ,@MDR_CREDIT DECIMAL(22, 8)
	   ,@MDR_CREDIT_INSTALLMENT DECIMAL(22, 8)
	   ,@INTERVAL_DEBIT INT
	   ,@INTERVAL_CREDIT INT
	   ,@ANTECIPATION DECIMAL(22, 8);
DECLARE CURSOR_PLAN CURSOR FOR SELECT
	[PLAN_NAME]
   ,[COD_PLAN_TYPE]
   ,[COD_USER]
   ,[COD_AFFILIATOR]
   ,[COD_COMP]
   ,[MDR_DEBIT]
   ,[MDR_CREDIT]
   ,[MDR_CREDIT_INSTALLMENT]
   ,[INTERVAL_DEBIT]
   ,[INTERVAL_CREDIT]
   ,[ANTECIPATION]
FROM @TP_PLAN AS [TP];
OPEN CURSOR_PLAN;
FETCH NEXT FROM CURSOR_PLAN INTO
@PLAN_NAME,
@COD_PLAN_TYPE,
@COD_USER,
@COD_AFFILIATOR,
@COD_COMP,
@MDR_DEBIT,
@MDR_CREDIT,
@MDR_CREDIT_INSTALLMENT,
@INTERVAL_DEBIT,
@INTERVAL_CREDIT,
@ANTECIPATION;
WHILE @@fetch_status = 0
BEGIN
INSERT INTO [PLAN] ([CODE],
[COD_T_PLAN],
[DESCRIPTION],
[COD_USER],
[COD_COMP],
[COD_SEG],
[COD_AFFILIATOR],
[COD_PLAN_CATEGORY],
[AVAILABLE_SALE])
	VALUES (@PLAN_NAME, @COD_PLAN_TYPE, @PLAN_NAME, @COD_USER, @COD_COMP, 354, @COD_AFFILIATOR, 1, 1);

SET @COD_PLAN = @@identity;

INSERT INTO [TAX_PLAN] ([COD_TTYPE],
[QTY_INI_PLOTS],
[QTY_FINAL_PLOTS],
[PARCENTAGE],
[RATE],
[INTERVAL],
[COD_PLAN],
[ANTICIPATION_PERCENTAGE],
[COD_BRAND],
[COD_SOURCE_TRAN],
[EFFECTIVE_PERCENTAGE])
	SELECT
		[B].[COD_TTYPE]
	   ,1
	   ,1
	   ,IIF([B].[COD_TTYPE] = 1, @MDR_CREDIT, @MDR_DEBIT)
	   ,0
	   ,IIF([B].[COD_TTYPE] = 1, @INTERVAL_CREDIT, @INTERVAL_DEBIT)
	   ,@COD_PLAN
	   ,@ANTECIPATION
	   ,[B].[COD_BRAND]
	   ,2
	   ,0
	FROM [BRAND] AS [B]
	WHERE [B].[GEN_TITLES] = 1;

INSERT INTO [TAX_PLAN] ([COD_TTYPE],
[QTY_INI_PLOTS],
[QTY_FINAL_PLOTS],
[PARCENTAGE],
[RATE],
[INTERVAL],
[COD_PLAN],
[ANTICIPATION_PERCENTAGE],
[COD_BRAND],
[COD_SOURCE_TRAN],
[EFFECTIVE_PERCENTAGE])
	SELECT
		[B].[COD_TTYPE]
	   ,2
	   ,12
	   ,@MDR_CREDIT_INSTALLMENT
	   ,0
	   ,@INTERVAL_CREDIT
	   ,@COD_PLAN
	   ,@ANTECIPATION
	   ,[B].[COD_BRAND]
	   ,2
	   ,0
	FROM [BRAND] AS [B]
	WHERE [B].[GEN_TITLES] = 1
	AND [COD_TTYPE] = 1;

FETCH NEXT FROM CURSOR_PLAN INTO
@PLAN_NAME,
@COD_PLAN_TYPE,
@COD_USER,
@COD_AFFILIATOR,
@COD_COMP,
@MDR_DEBIT,
@MDR_CREDIT,
@MDR_CREDIT_INSTALLMENT,
@INTERVAL_DEBIT,
@INTERVAL_CREDIT,
@ANTECIPATION;
END;
CLOSE CURSOR_PLAN;
DEALLOCATE CURSOR_PLAN;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_REG_ECOMMERCE_PRODUCT]    Script Date: 27/04/2020 16:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Table [dbo].[WL_COLORS]    Script Date: 03/05/2020 16:22:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



GO

/****** Object:  UserDefinedTableType [dbo].[WL_PRODUCTS]    Script Date: 03/05/2020 17:25:11 ******/
CREATE TYPE [dbo].[WL_PRODUCTS] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[PRODUCT_NAME] [varchar](255) NULL,
	[SKU] [varchar](255) NULL,
	[PRICE] [decimal](22, 8) NULL,
	[COD_MODEL] [int] NULL
)
GO


 
CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_PRODUCT]  
  
 /*----------------------------------------------------------------------------------------    
Procedure Name: [SP_REG_ECOMMERCE_ABOUT]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author              VERSION        Date      Description    
------------------------------------------------------------------------------------------    
Lucas Aguiar  v1      2019-11-07    Procedure para o registro o contúdp da tela "about" do Ecommerce  
------------------------------------------------------------------------------------------*/  
  
(  
 @THEMES_IMG [TP_THEMES_IMG] READONLY,  
 @PRODUCTS [WL_PRODUCTS] READONLY  
)  
AS  
BEGIN

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

INSERT INTO ECOMMERCE_THEMES_IMG (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_CONT_TYPE,
PATH_CONTENT,
COD_MODEL)
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


INSERT INTO PRODUCTS (COD_AFFILIATOR,
COD_MODEL,
COD_USER,
CREATED_AT,
PRODUCT_NAME,
SKU,
PRICE)
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

CREATE PROCEDURE [dbo].[SP_CHECK_WHITELABEL_URL]  
/*----------------------------------------------------------------------------------------  
   Project.......: TKPP  
------------------------------------------------------------------------------------------  
   Author              VERSION        Date      Description  
------------------------------------------------------------------------------------------  
   Luiz Aquino          v1          2020-02-27  Add url WhiteLabel  
------------------------------------------------------------------------------------------*/  
  
( @WHITELABEL_URL VARCHAR(128), @COD_AFF_IGNORE INT = NULL  )  
AS  
BEGIN
SELECT
	COUNT(*) CONFLICTING
FROM AFFILIATOR
WHERE WHITELABEL_URL LIKE ('%' + @WHITELABEL_URL + '%')
AND COD_AFFILIATOR != @COD_AFF_IGNORE
END;

GO

   
  
CREATE PROCEDURE [dbo].[SP_WL_COLORS]  
AS  
  
BEGIN

SELECT
	COD_WL_COLORS
   ,CODE
FROM WL_COLORS


END;

GO

   
--CREATE PROCEDURE [dbo].[SP_FD_ECOMMERCE_IMG]  
  
-- /*----------------------------------------------------------------------------------------    
--Procedure Name: [SP_FD_ECOMMERCE_IMG]    
--Project.......: TKPP    
--------------------------------------------------------------------------------------------    
--Author              VERSION        Date      Description    
--------------------------------------------------------------------------------------------    
--Lucas Aguiar  v1      2019-11-07    Procedure para buscar imagens do Ecommerce  
--------------------------------------------------------------------------------------------*/  
  
-- (  
-- @COD_AFFILIATOR INT  
--)  
--AS  
--BEGIN

--SELECT
--	IMG.COD_WL_CONT_TYPE
--   ,IMG.PATH_CONTENT
--   ,WL_CONTENT_TYPE.CODE
--FROM ECOMMERCE_THEMES_IMG IMG
--JOIN WL_CONTENT_TYPE
--	ON WL_CONTENT_TYPE.COD_WL_CONT_TYPE = IMG.COD_WL_CONT_TYPE
--WHERE ACTIVE = 1
--AND COD_AFFILIATOR = @COD_AFFILIATOR;

--END;

GO

   
  
    
CREATE PROCEDURE [dbo].[SP_WL_CUSTOM_TEXT]                     
AS                      
                      
BEGIN

SELECT
	COD_WL_CUSTOM_TEXT
   ,CODE
   ,DESCRIPTION
FROM WL_CUSTOM_TEXT


END;

GO

  
ALTER PROCEDURE [DBO].[SP_REG_ECOMMERCE_BENEFITS]  
  
/***************************************************************************************************  
----------------------------------------------------------------------------------------    
Procedure Name: [[SP_REG_ECOMMERCE_BENEFITS]]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author              VERSION        Date      Description    
------------------------------------------------------------------------------------------    
Lucas Aguiar  v1      2019-11-07    Procedure para o registro o contúdp da tela "Benefits" do Ecommerce  
------------------------------------------------------------------------------------------  
***************************************************************************************************/  
  
(  
 @THEMES_IMG  [TP_THEMES_IMG] READONLY,   
 @THEMES_TEXT [TP_THEMES_TEXT] READONLY)  
AS  
BEGIN

UPDATE [ECOMMERCE_THEMES_IMG]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = current_timestamp
   ,[COD_USER_ALT] = [THEMES_IMG].[COD_USER]
FROM [ECOMMERCE_THEMES_IMG]
JOIN @THEMES_IMG [THEMES_IMG]
	ON [THEMES_IMG].[COD_AFF] = [ECOMMERCE_THEMES_IMG].[COD_AFFILIATOR]
	AND [ECOMMERCE_THEMES_IMG].[ACTIVE] = 1
WHERE [ECOMMERCE_THEMES_IMG].[COD_WL_CONT_TYPE] = [THEMES_IMG].[COD_WL_CONT_TYPE]
AND (([THEMES_IMG].[COD_MODEL] IS NOT NULL
AND [ECOMMERCE_THEMES_IMG].[COD_MODEL] = [THEMES_IMG].[COD_MODEL])
OR ([THEMES_IMG].[COD_MODEL] IS NULL
AND [ECOMMERCE_THEMES_IMG].[COD_MODEL] IS NULL));

INSERT INTO [ECOMMERCE_THEMES_IMG] ([COD_USER_CAD],
[COD_AFFILIATOR],
[COD_WL_CONT_TYPE],
[PATH_CONTENT],
[COD_MODEL])
	SELECT
		[THEMES_IMG].[COD_USER]
	   ,[THEMES_IMG].[COD_AFF]
	   ,[THEMES_IMG].[COD_WL_CONT_TYPE]
	   ,[THEMES_IMG].[PATH_CONTENT]
	   ,[THEMES_IMG].[COD_MODEL]
	FROM @THEMES_IMG AS [THEMES_IMG];


UPDATE [ECOMMERCE_THEMES_TEXT]
SET [ACTIVE] = 0
   ,[MODIFY_DATE] = current_timestamp
   ,[COD_USER_ALT] = [THEMES_TEXT].[COD_USER]
FROM [ECOMMERCE_THEMES_TEXT]
JOIN @THEMES_TEXT [THEMES_TEXT]
	ON [THEMES_TEXT].[COD_AFF] = [ECOMMERCE_THEMES_TEXT].[COD_AFFILIATOR]
	AND [ECOMMERCE_THEMES_TEXT].[ACTIVE] = 1
WHERE [ECOMMERCE_THEMES_TEXT].[COD_WL_CUSTOM_TEXT] = [THEMES_TEXT].[COD_WL_CUSTOM_TEXT];

INSERT INTO [ECOMMERCE_THEMES_TEXT] ([COD_USER_CAD],
[COD_AFFILIATOR],
[COD_WL_CUSTOM_TEXT],
[TEXT])
	SELECT
		[THEMES_TEXT].[COD_USER]
	   ,[THEMES_TEXT].[COD_AFF]
	   ,[THEMES_TEXT].[COD_WL_CUSTOM_TEXT]
	   ,[THEMES_TEXT].[TEXT]
	FROM @THEMES_TEXT AS [THEMES_TEXT];
END;

GO

   
ALTER PROCEDURE [dbo].[SP_REG_ECOMMERCE_ABOUT]  
  
 /*----------------------------------------------------------------------------------------    
Procedure Name: [SP_REG_ECOMMERCE_ABOUT]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author              VERSION        Date      Description    
------------------------------------------------------------------------------------------    
Lucas Aguiar  v1      2019-11-07    Procedure para o registro o contúdp da tela "about" do Ecommerce  
------------------------------------------------------------------------------------------*/  
  
(  
 @THEMES_IMG [TP_THEMES_IMG] READONLY,  
 @THEMES_TEXT [TP_THEMES_TEXT] READONLY  
)  
AS  
BEGIN

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

INSERT INTO ECOMMERCE_THEMES_IMG (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_CONT_TYPE,
PATH_CONTENT,
COD_MODEL)
	SELECT
		THEMES_IMG.COD_USER
	   ,THEMES_IMG.COD_AFF
	   ,THEMES_IMG.COD_WL_CONT_TYPE
	   ,THEMES_IMG.PATH_CONTENT
	   ,THEMES_IMG.COD_MODEL
	FROM @THEMES_IMG THEMES_IMG;


UPDATE ECOMMERCE_THEMES_TEXT
SET ACTIVE = 0
   ,MODIFY_DATE = current_timestamp
   ,COD_USER_ALT = THEMES_TEXT.COD_USER
FROM ECOMMERCE_THEMES_TEXT
JOIN @THEMES_TEXT THEMES_TEXT
	ON THEMES_TEXT.COD_AFF = ECOMMERCE_THEMES_TEXT.COD_AFFILIATOR
	AND ECOMMERCE_THEMES_TEXT.ACTIVE = 1
WHERE ECOMMERCE_THEMES_TEXT.COD_WL_CUSTOM_TEXT = THEMES_TEXT.COD_WL_CUSTOM_TEXT;

INSERT INTO ECOMMERCE_THEMES_TEXT (COD_USER_CAD,
COD_AFFILIATOR,
COD_WL_CUSTOM_TEXT,
[TEXT])
	SELECT
		THEMES_TEXT.COD_USER
	   ,THEMES_TEXT.COD_AFF
	   ,THEMES_TEXT.COD_WL_CUSTOM_TEXT
	   ,THEMES_TEXT.[TEXT]
	FROM @THEMES_TEXT THEMES_TEXT;
END;

GO

   
--CREATE PROCEDURE [dbo].[SP_REG_ECOMMERCE_PLAN]  
  
--/*******************************************************************************************  
------------------------------------------------------------------------------------------    
--Procedure Name: [SP_REG_ECOMMERCE_PLAN]    
--Project.......: TKPP    
--------------------------------------------------------------------------------------------    
--Author              VERSION        Date      Description    
--------------------------------------------------------------------------------------------    
--Lucas Aguiar  v1      2019-11-21    Procedure para o cadastro do plano - ecommerce  
--------------------------------------------------------------------------------------------  
--*******************************************************************************************/  
  
--(  
-- @TP_PLAN [TP_ECOMMERCE_PLAN] READONLY)  
--AS  
--    BEGIN
  
--    DECLARE   
--   @COD_PLAN INT;
--UPDATE [TAX_PLAN]
--SET [ACTIVE] = 0
--FROM [TAX_PLAN]
--JOIN [PLAN]
--	ON [PLAN].[COD_PLAN] = [TAX_PLAN].[COD_PLAN]
--JOIN @TP_PLAN [TP]
--	ON [TP].[COD_AFFILIATOR] = [PLAN].[COD_AFFILIATOR]
--	AND [AVAILABLE_SALE] = 1
--	AND [PLAN].[ACTIVE] = 1
--	AND [PLAN].[COD_T_PLAN] = [TP].[COD_PLAN_TYPE];
--UPDATE [PLAN]
--SET [PLAN].[ACTIVE] = 0
--   ,[PLAN].[MODIFY_DATE] = current_timestamp
--   ,[PLAN].[COD_USER_MODIFY] = [TP].[COD_USER]
--FROM [PLAN]
--JOIN @TP_PLAN [TP]
--	ON [TP].[COD_AFFILIATOR] = [PLAN].[COD_AFFILIATOR]
--	AND [AVAILABLE_SALE] = 1
--	AND [PLAN].[ACTIVE] = 1
--	AND [PLAN].[COD_T_PLAN] = [TP].[COD_PLAN_TYPE];
--DECLARE @PLAN_NAME VARCHAR(255)
--	   ,@COD_PLAN_TYPE INT
--	   ,@COD_USER INT
--	   ,@COD_AFFILIATOR INT
--	   ,@COD_COMP INT
--	   ,@MDR_DEBIT DECIMAL(22, 8)
--	   ,@MDR_CREDIT DECIMAL(22, 8)
--	   ,@MDR_CREDIT_INSTALLMENT DECIMAL(22, 8)
--	   ,@INTERVAL_DEBIT INT
--	   ,@INTERVAL_CREDIT INT
--	   ,@ANTECIPATION DECIMAL(22, 8);
--DECLARE CURSOR_PLAN CURSOR FOR SELECT
--	[PLAN_NAME]
--   ,[COD_PLAN_TYPE]
--   ,[COD_USER]
--   ,[COD_AFFILIATOR]
--   ,[COD_COMP]
--   ,[MDR_DEBIT]
--   ,[MDR_CREDIT]
--   ,[MDR_CREDIT_INSTALLMENT]
--   ,[INTERVAL_DEBIT]
--   ,[INTERVAL_CREDIT]
--   ,[ANTECIPATION]
--FROM @TP_PLAN AS [TP];
--OPEN CURSOR_PLAN;
--FETCH NEXT FROM CURSOR_PLAN INTO
--@PLAN_NAME,
--@COD_PLAN_TYPE,
--@COD_USER,
--@COD_AFFILIATOR,
--@COD_COMP,
--@MDR_DEBIT,
--@MDR_CREDIT,
--@MDR_CREDIT_INSTALLMENT,
--@INTERVAL_DEBIT,
--@INTERVAL_CREDIT,
--@ANTECIPATION;
--WHILE @@fetch_status = 0
--BEGIN
--INSERT INTO [PLAN] ([CODE],
--[COD_T_PLAN],
--[DESCRIPTION],
--[COD_USER],
--[COD_COMP],
--[COD_SEG],
--[COD_AFFILIATOR],
--[COD_PLAN_CATEGORY],
--[AVAILABLE_SALE])
--	VALUES (@PLAN_NAME, @COD_PLAN_TYPE, @PLAN_NAME, @COD_USER, @COD_COMP, 354, @COD_AFFILIATOR, 1, 1);

--SET @COD_PLAN = @@identity;

--INSERT INTO [TAX_PLAN] ([COD_TTYPE],
--[QTY_INI_PLOTS],
--[QTY_FINAL_PLOTS],
--[PARCENTAGE],
--[RATE],
--[INTERVAL],
--[COD_PLAN],
--[ANTICIPATION_PERCENTAGE],
--[COD_BRAND],
--[COD_SOURCE_TRAN],
--[EFFECTIVE_PERCENTAGE])
--	SELECT
--		[B].[COD_TTYPE]
--	   ,1
--	   ,1
--	   ,IIF([B].[COD_TTYPE] = 1, @MDR_CREDIT, @MDR_DEBIT)
--	   ,0
--	   ,IIF([B].[COD_TTYPE] = 1, @INTERVAL_CREDIT, @INTERVAL_DEBIT)
--	   ,@COD_PLAN
--	   ,@ANTECIPATION
--	   ,[B].[COD_BRAND]
--	   ,2
--	   ,0
--	FROM [BRAND] AS [B]
--	WHERE [B].[GEN_TITLES] = 1;

--INSERT INTO [TAX_PLAN] ([COD_TTYPE],
--[QTY_INI_PLOTS],
--[QTY_FINAL_PLOTS],
--[PARCENTAGE],
--[RATE],
--[INTERVAL],
--[COD_PLAN],
--[ANTICIPATION_PERCENTAGE],
--[COD_BRAND],
--[COD_SOURCE_TRAN],
--[EFFECTIVE_PERCENTAGE])
--	SELECT
--		[B].[COD_TTYPE]
--	   ,2
--	   ,12
--	   ,@MDR_CREDIT_INSTALLMENT
--	   ,0
--	   ,@INTERVAL_CREDIT
--	   ,@COD_PLAN
--	   ,@ANTECIPATION
--	   ,[B].[COD_BRAND]
--	   ,2
--	   ,0
--	FROM [BRAND] AS [B]
--	WHERE [B].[GEN_TITLES] = 1
--	AND [COD_TTYPE] = 1;

--FETCH NEXT FROM CURSOR_PLAN INTO
--@PLAN_NAME,
--@COD_PLAN_TYPE,
--@COD_USER,
--@COD_AFFILIATOR,
--@COD_COMP,
--@MDR_DEBIT,
--@MDR_CREDIT,
--@MDR_CREDIT_INSTALLMENT,
--@INTERVAL_DEBIT,
--@INTERVAL_CREDIT,
--@ANTECIPATION;
--END;
--CLOSE CURSOR_PLAN;
--DEALLOCATE CURSOR_PLAN;
--END;

--GO

  
  
CREATE PROCEDURE [DBO].[SP_DEF_EC_TRANSIRE]                                
              
/*******************************************************************************************************  
----------------------------------------------------------------------------------------                
Procedure Name: [SP_DEF_EC_TRANSIRE]                
Project.......: TKPP                
------------------------------------------------------------------------------------------                
Author              VERSION        Date      Description                
------------------------------------------------------------------------------------------                
Lucas Aguiar  v1   2019-11-25   Procedure para associar o plano ao ec transire              
------------------------------------------------------------------------------------------              
*******************************************************************************************************/              
              
(  
 @COD_AFFILIATOR INT,   
 @CLIENT_ID      VARCHAR(255) = null,   
 @SECRET_KEY     VARCHAR(255) = null)  
AS  
BEGIN
  
  
  
  
    DECLARE @COD_EC INT= NULL;
  
  
  
    DECLARE @SEQ INT;
  
  
  
    DECLARE @GENERIC_EC INT;
  
  
  
    DECLARE @AFF_NAME VARCHAR(255);
  
  
  
    DECLARE @COD_BRANCH INT;
  
  
  
    DECLARE @COD_DEPART INT;
  
  
  
    DECLARE @COD_USER INT;
  
  
  
    DECLARE @COD_ADT INT;

SELECT
	@COD_EC = [ASS_AFF_TRANSIRE].[COD_EC]
FROM [ASS_AFF_TRANSIRE]
WHERE [COD_AFF] = @COD_AFFILIATOR
AND [ACTIVE] = 1;

IF @COD_EC IS NOT NULL
BEGIN

SELECT
	[COD_DEPTO_BRANCH] AS [COD_DEPART]
   ,[BRANCH_EC].[COD_BRANCH] AS [COD_BRANCH]
FROM [DEPARTMENTS_BRANCH]
JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
		AND [COD_EC] = @COD_EC;
END;
ELSE
BEGIN

SELECT
	@AFF_NAME = [AFFILIATOR].[NAME]
FROM [AFFILIATOR]
WHERE [COD_AFFILIATOR] = @COD_AFFILIATOR;

SELECT
	@GENERIC_EC = [COD_EC]
   ,@SEQ = (NEXT VALUE FOR [SEQ_ECCODE])
   ,@COD_USER = [COD_USER]
FROM [COMMERCIAL_ESTABLISHMENT]
WHERE [GENERIC_EC] = 1
AND [COD_AFFILIATOR] IS NULL
AND [ACTIVE] = 1;


INSERT INTO [COMMERCIAL_ESTABLISHMENT] ([CODE],
[NAME],
[TRADING_NAME],
[CPF_CNPJ],
[DOCUMENT_TYPE],
[EMAIL],
[STATE_REGISTRATION],
[MUNICIPAL_REGISTRATION],
[COD_SEG],
[TRANSACTION_LIMIT],
[LIMIT_TRANSACTION_DIALY],
[BIRTHDATE],
[COD_USER],
[COD_COMP],
[SEC_FACTOR_AUTH_ACTIVE],
[COD_TYPE_ESTAB],
[COD_SEX],
[DOCUMENT],
[COD_SALES_REP],
[COD_SITUATION],
[COD_REQ],
[NOTE],
[COD_AFFILIATOR],
[TRANSACTION_ONLINE],
[USER_ONLINE],
[PWD_ONLINE],
[COD_SIT_REQ],
[DEFAULT_EC],
[SPOT_TAX],
[NOTE_FINANCE_SCHEDULE],
[DATE_OFAC],
[RISK_REASON],
[COD_RISK_SITUATION],
[IS_PROVIDER],
[LIMIT_TRANSACTION_MONTHLY],
[COD_BRANCH_BUSINESS],
[GENERIC_EC])
	SELECT
		@SEQ
	   ,CONCAT([NAME], '_', @AFF_NAME)
	   ,CONCAT([TRADING_NAME], '_', @AFF_NAME)
	   ,[CPF_CNPJ]
	   ,[DOCUMENT_TYPE]
	   ,[EMAIL]
	   ,[STATE_REGISTRATION]
	   ,[MUNICIPAL_REGISTRATION]
	   ,[COD_SEG]
	   ,[TRANSACTION_LIMIT]
	   ,[LIMIT_TRANSACTION_DIALY]
	   ,[BIRTHDATE]
	   ,[COD_USER]
	   ,[COD_COMP]
	   ,[SEC_FACTOR_AUTH_ACTIVE]
	   ,[COD_TYPE_ESTAB]
	   ,[COD_SEX]
	   ,[DOCUMENT]
	   ,[COD_SALES_REP]
	   ,[COD_SITUATION]
	   ,[COD_REQ]
	   ,[NOTE]
	   ,@COD_AFFILIATOR
	   ,[TRANSACTION_ONLINE]
	   ,[USER_ONLINE]
	   ,[PWD_ONLINE]
	   ,[COD_SIT_REQ]
	   ,[DEFAULT_EC]
	   ,[SPOT_TAX]
	   ,[NOTE_FINANCE_SCHEDULE]
	   ,[DATE_OFAC]
	   ,[RISK_REASON]
	   ,[COD_RISK_SITUATION]
	   ,[IS_PROVIDER]
	   ,[LIMIT_TRANSACTION_MONTHLY]
	   ,[COD_BRANCH_BUSINESS]
	   ,1
	FROM [COMMERCIAL_ESTABLISHMENT]
	WHERE [COD_EC] = @GENERIC_EC;

SET @COD_EC = @@identity;

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
[COD_USER],
[COD_SEX],
[COD_SALES_REP],
[COD_TYPE_ESTAB],
[COD_REQ],
[COD_SITUATION],
[COD_TYPE_REC])
	SELECT
		@SEQ
	   ,CONCAT([NAME], '_', @AFF_NAME)
	   ,CONCAT([TRADING_NAME], '_', @AFF_NAME)
	   ,[CPF_CNPJ]
	   ,[DOCUMENT]
	   ,[DOCUMENT_TYPE]
	   ,[EMAIL]
	   ,[STATE_REGISTRATION]
	   ,[MUNICIPAL_REGISTRATION]
	   ,[TRANSACTION_LIMIT]
	   ,[LIMIT_TRANSACTION_DIALY]
	   ,[BIRTHDATE]
	   ,@COD_EC
	   ,[TYPE_BRANCH]
	   ,[COD_USER]
	   ,[COD_SEX]
	   ,[COD_SALES_REP]
	   ,[COD_TYPE_ESTAB]
	   ,[COD_REQ]
	   ,[COD_SITUATION]
	   ,[COD_TYPE_REC]
	FROM [BRANCH_EC]
	WHERE [COD_EC] = @GENERIC_EC
	AND [ACTIVE] = 1;

SET @COD_BRANCH = @@identity;

INSERT INTO [BANK_DETAILS_EC] ([AGENCY],
[DIGIT_AGENCY],
[COD_TYPE_ACCOUNT],
[COD_EC],
[COD_BANK],
[ACCOUNT],
[DIGIT_ACCOUNT],
[COD_USER],
[COD_OPER_BANK],
[COD_BRANCH],
[IS_ASSIGNMENT],
[ASSIGNMENT_NAME],
[ASSIGNMENT_IDENTIFICATION])
	SELECT
		[AGENCY]
	   ,[DIGIT_AGENCY]
	   ,[COD_TYPE_ACCOUNT]
	   ,@COD_EC
	   ,[COD_BANK]
	   ,[ACCOUNT]
	   ,[DIGIT_ACCOUNT]
	   ,[COD_USER]
	   ,[COD_OPER_BANK]
	   ,@COD_BRANCH
	   ,[IS_ASSIGNMENT]
	   ,[ASSIGNMENT_NAME]
	   ,[ASSIGNMENT_IDENTIFICATION]
	FROM [BANK_DETAILS_EC]
	WHERE [COD_EC] = @GENERIC_EC
	AND [ACTIVE] = 1;

INSERT INTO [ADDRESS_BRANCH] ([ADDRESS],
[NUMBER],
[COMPLEMENT],
[CEP],
[COD_NEIGH],
[REFERENCE_POINT],
[COD_BRANCH])
	SELECT
		[ADDRESS]
	   ,[NUMBER]
	   ,[COMPLEMENT]
	   ,[CEP]
	   ,[COD_NEIGH]
	   ,[REFERENCE_POINT]
	   ,@COD_BRANCH
	FROM [ADDRESS_BRANCH]
	JOIN [BRANCH_EC]
		ON [BRANCH_EC].[COD_BRANCH] = [ADDRESS_BRANCH].[COD_BRANCH]
	WHERE [COD_EC] = @GENERIC_EC
	AND [BRANCH_EC].[ACTIVE] = 1
	AND [ADDRESS_BRANCH].[ACTIVE] = 1;


INSERT INTO [DEPARTMENTS_BRANCH] ([COD_BRANCH],
[COD_DEPARTS],
[COD_USER],
[COD_T_PLAN])
	SELECT
		@COD_BRANCH
	   ,[COD_DEPARTS]
	   ,[DEPARTMENTS_BRANCH].[COD_USER]
	   ,[COD_T_PLAN]
	FROM [DEPARTMENTS_BRANCH]
	JOIN [BRANCH_EC]
		ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
	WHERE [COD_EC] = @GENERIC_EC
	AND [ACTIVE] = 1;


SET @COD_DEPART = @@identity;

INSERT INTO [ASS_AFF_TRANSIRE] ([COD_EC],
[COD_AFF])
	VALUES (@COD_EC, @COD_AFFILIATOR);

EXEC [SP_REG_EXTERNAL_DATA_EC_ACQ] @COD_EC
								  ,@COD_USER;

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
		[PLAN_TAX_AFFILIATOR].[COD_TTYPE]
	   ,[PLAN_TAX_AFFILIATOR].[QTY_INI_PLOTS]
	   ,[PLAN_TAX_AFFILIATOR].[QTY_FINAL_PLOTS]
	   ,[PLAN_TAX_AFFILIATOR].[PERCENTAGE]
	   ,[PLAN_TAX_AFFILIATOR].[RATE]
	   ,[PLAN_TAX_AFFILIATOR].[INTERVAL]
	   ,@COD_DEPART
	   ,[PLAN_TAX_AFFILIATOR].[COD_USER]
	   ,[PLAN_TAX_AFFILIATOR].[COD_PLAN]
	   ,[PLAN_TAX_AFFILIATOR].[EFFECTIVE_PERCENTAGE]
	   ,[PLAN_TAX_AFFILIATOR].[ANTICIPATION_PERCENTAGE]
	   ,[PLAN_TAX_AFFILIATOR].[COD_BRAND]
	   ,[PLAN_TAX_AFFILIATOR].[COD_SOURCE_TRAN]
	FROM [PLAN_TAX_AFFILIATOR]
	WHERE [COD_AFFILIATOR] = @COD_AFFILIATOR
	AND [ACTIVE] = 1;


INSERT INTO [TARIFF_EC] ([COD_TTARIFF],
[COD_EC],
[VALUE],
[PAYMENT_DAY],
[PLOT],
[COD_SITUATION],
[COD_USER],
[COMMENT],
[COD_REQ],
[COD_BRANCH])
	SELECT
		[COD_TTARIFF]
	   ,@COD_EC
	   ,[VALUE]
	   ,[PAYMENT_DAY]
	   ,[PLOT]
	   ,[COD_SITUATION]
	   ,[COD_USER]
	   ,[COMMENT]
	   ,[COD_REQ]
	   ,@COD_BRANCH
	FROM [TARIFF_EC]
	WHERE [COD_EC] = @GENERIC_EC
	AND [ACTIVE] = 1;


INSERT INTO [CONTACT_BRANCH] ([NUMBER],
[COD_TP_CONT],
[COD_BRANCH],
[COD_USER],
[COD_OPER],
[DDD],
[DDI])
	SELECT
		[NUMBER]
	   ,[COD_TP_CONT]
	   ,@COD_BRANCH
	   ,[CONTACT_BRANCH].[COD_USER]
	   ,[COD_OPER]
	   ,[DDD]
	   ,[DDI]
	FROM [CONTACT_BRANCH]
	JOIN [BRANCH_EC]
		ON [BRANCH_EC].[COD_BRANCH] = [CONTACT_BRANCH].[COD_BRANCH]
			AND [BRANCH_EC].[COD_EC] = @GENERIC_EC
	WHERE [CONTACT_BRANCH].[ACTIVE] = 1;



INSERT INTO [ADITIONAL_DATA_TYPE_EC] ([NAME],
[CPF],
[DOCUMENT],
[BIRTH_DATA],
[COD_EC],
[COD_TYPE_PARTNER],
[PERCENTEGE_QUOTAS])
	SELECT
		[NAME]
	   ,[CPF]
	   ,[DOCUMENT]
	   ,[BIRTH_DATA]
	   ,@COD_EC
	   ,[COD_TYPE_PARTNER]
	   ,[PERCENTEGE_QUOTAS]
	FROM [ADITIONAL_DATA_TYPE_EC]
	WHERE [COD_EC] = @GENERIC_EC
	AND [ACTIVE] = 1;


SET @COD_ADT = @@identity;

INSERT INTO [ADDRESS_ADT_EC] ([ADDRESS],
[NUMBER],
[COMPLEMENT],
[CEP],
[COD_NEIGH],
[COD_ADT_DATA],
[REFERENCE_POINT])
	SELECT
		[ADDRESS]
	   ,[NUMBER]
	   ,[COMPLEMENT]
	   ,[CEP]
	   ,[COD_NEIGH]
	   ,@COD_ADT
	   ,[REFERENCE_POINT]
	FROM [ADDRESS_ADT_EC]
	WHERE @COD_EC = @GENERIC_EC
	AND [ACTIVE] = 1;

INSERT INTO [DOCS_BRANCH] ([COD_USER],
[COD_BRANCH],
[COD_SIT_REQ],
[COD_DOC_TYPE],
[PATH_DOC],
[COD_SUP_TIC])
	SELECT
		[DOCS_BRANCH].[COD_USER]
	   ,@COD_BRANCH
	   ,[COD_SIT_REQ]
	   ,[COD_DOC_TYPE]
	   ,[PATH_DOC]
	   ,[COD_SUP_TIC]
	FROM [DOCS_BRANCH]
	JOIN [BRANCH_EC]
		ON [BRANCH_EC].[COD_BRANCH] = [DOCS_BRANCH].[COD_BRANCH]
			AND [BRANCH_EC].[COD_EC] = @GENERIC_EC
	WHERE [DOCS_BRANCH].[ACTIVE] = 1;

DECLARE @SUBDOMAIN VARCHAR(100);

SELECT
	@SUBDOMAIN = [SUBDOMAIN]
FROM [AFFILIATOR]
WHERE [COD_AFFILIATOR] = @COD_AFFILIATOR;

INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[MODIFY_DATE])
	--VALUES (current_timestamp, 63, 1, NULL, 174, 8631, 0, NULL)        
	SELECT
		current_timestamp
	   ,@COD_USER
	   ,[COD_ITEM_SERVICE]
	   ,NULL
	   ,@COD_AFFILIATOR
	   ,@COD_EC
	   ,0
	   ,NULL
	FROM [ITEMS_SERVICES_AVAILABLE];

IF ((SELECT
			COUNT(*)
		FROM [EQUIPMENT]
		WHERE [SERIAL] = 'www.' + @SUBDOMAIN + '.com.br')
	= 0)
BEGIN
INSERT INTO [EQUIPMENT] ([CREATED_AT],
[SERIAL],
[COD_MODEL],
[COD_COMP],
[ACTIVE],
[CHIP],
[COD_USER],
[PUK],
[COD_OPER],
[TID])
	VALUES (current_timestamp, 'www.' + @SUBDOMAIN + '.com.br', 6, 8, 1, '00000000', @COD_USER, '000000000', 1, NEXT VALUE FOR [SEQ_TID]);

INSERT INTO [ASS_DEPTO_EQUIP] ([DATA_REGISTRO],
[COD_EQUIP],
[COD_DEPTO_BRANCH],
[ACTIVE],
[COD_USER],
[DEFAULT_EQUIP])
	VALUES (current_timestamp, @@identity, @COD_DEPART, 1, @COD_USER, 1);
END;

INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT],
[COD_USER],
[COD_ITEM_SERVICE],
[COD_COMP],
[COD_AFFILIATOR],
[COD_EC],
[ACTIVE],
[COD_OPT_SERV],
[CONFIG_JSON])
	SELECT
		[CREATED_AT]
	   ,[COD_USER]
	   ,[COD_ITEM_SERVICE]
	   ,[COD_COMP]
	   ,[COD_AFFILIATOR]
	   ,@COD_EC
	   ,[ACTIVE]
	   ,[COD_OPT_SERV]
	   ,[CONFIG_JSON]
	FROM [SERVICES_AVAILABLE]
	WHERE [COD_EC] = @COD_EC;


SELECT
	@COD_DEPART AS [COD_DEPART]
   ,@COD_BRANCH AS [COD_BRANCH];
END;

EXEC [SP_CREATE_PERMISSION_ORDER] @COD_AFFILIATOR = @COD_AFFILIATOR
								 ,@CLIENT_ID = @CLIENT_ID
								 ,@SECRET_KEY = @SECRET_KEY;

END;

GO

ALTER TABLE ACCESS_APPAPI ADD CLAIMS VARCHAR(150)

GO

  
CREATE PROCEDURE SP_CREATE_PERMISSION_ORDER  
(  
 @COD_AFFILIATOR INT,  
 @CLIENT_ID VARCHAR(255),  
 @SECRET_KEY VARCHAR(255)  
)  
AS  
DECLARE @COD_AFF INT;
  
DECLARE @SERVICETYPE INT;
  
DECLARE @CLAIMS INT;
  
DECLARE @CONF_CLAIMS VARCHAR(150);
  
BEGIN


SELECT
	@COD_AFF = COD_AFFILIATOR
   ,@SERVICETYPE =
	CASE
		WHEN SUBSTRING(CLAIMS, 0, CHARINDEX('.', CLAIMS, 0)) LIKE '%2%' THEN 1
		ELSE 0
	END
   ,@CLAIMS =
	CASE
		WHEN SUBSTRING(CLAIMS, CHARINDEX('.', CLAIMS, 0), LEN(CLAIMS)) LIKE '%1%' THEN 1
		ELSE 0
	END
   ,@CONF_CLAIMS = ACCESS_APPAPI.CLAIMS
FROM ACCESS_APPAPI
WHERE ((CLAIMS LIKE '%.%'
OR SUBSTRING(CLAIMS, 0, CHARINDEX('.', CLAIMS, 0)) LIKE '%2%'
OR SUBSTRING(CLAIMS, CHARINDEX('.', CLAIMS, 0), LEN(CLAIMS)) LIKE '%9%')
OR (CLAIMS IS NULL))
AND COD_AFFILIATOR = @COD_AFFILIATOR;

IF @COD_AFF IS NULL
BEGIN
INSERT INTO ACCESS_APPAPI (APPNAME, CLIENT_ID, NAME, COD_COMP, SECRETKEY, COD_AFFILIATOR, ACTIVE, CLAIMS)
	VALUES ((SELECT [NAME] FROM AFFILIATOR WHERE COD_AFFILIATOR = @COD_AFFILIATOR), NEWID(), (SELECT [NAME] FROM AFFILIATOR WHERE COD_AFFILIATOR = @COD_AFFILIATOR), 8, @SECRET_KEY, @COD_AFFILIATOR, 1, '2.12345')
END
ELSE
IF (@SERVICETYPE = 0
	AND @CLAIMS = 1)
BEGIN
SET @CONF_CLAIMS = '2' + @CLAIMS;
UPDATE ACCESS_APPAPI
SET CLAIMS = @CONF_CLAIMS
WHERE COD_AFFILIATOR = @COD_AFFILIATOR
END
ELSE
IF (@SERVICETYPE = 1
	AND @CLAIMS = 0)
BEGIN
SET @CONF_CLAIMS = @CLAIMS + '1';
UPDATE ACCESS_APPAPI
SET CLAIMS = @CONF_CLAIMS
WHERE COD_AFFILIATOR = @COD_AFFILIATOR
END
IF (@SERVICETYPE = 0
	AND @CLAIMS = 0)
BEGIN
SET @CONF_CLAIMS = '2.12345';
UPDATE ACCESS_APPAPI
SET CLAIMS = @CONF_CLAIMS
WHERE COD_AFFILIATOR = @COD_AFFILIATOR
END


END

GO

/****** Object:  Table [dbo].[ASS_AFF_TRANSIRE]    Script Date: 28/04/2020 09:48:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ASS_AFF_TRANSIRE](
	[COD_ASS_AFF_TRAN] [int] IDENTITY(1,1) NOT NULL,
	[COD_EC] [int] NULL,
	[COD_AFF] [int] NULL,
	[ACTIVE] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_ASS_AFF_TRAN] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ASS_AFF_TRANSIRE] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[ASS_AFF_TRANSIRE]  WITH CHECK ADD FOREIGN KEY([COD_AFF])
REFERENCES [dbo].[AFFILIATOR] ([COD_AFFILIATOR])
GO

ALTER TABLE [dbo].[ASS_AFF_TRANSIRE]  WITH CHECK ADD FOREIGN KEY([COD_EC])
REFERENCES [dbo].[COMMERCIAL_ESTABLISHMENT] ([COD_EC])
GO

CREATE PROCEDURE [DBO].[SP_FD_AFFILIATOR_DATA]  
    /*----------------------------------------------------------------------------------------  
   Project.......: TKPP  
------------------------------------------------------------------------------------------  
   Author              VERSION        Date      Description  
------------------------------------------------------------------------------------------  
   Luiz Aquino          v2          2020-02-27   ET-633 Add url WhiteLabel  
------------------------------------------------------------------------------------------*/  
    (@DOMAIN VARCHAR(255), @WHITE_URL VARCHAR(128) = null)  
AS  
BEGIN
SELECT
	[AFF].[COD_AFFILIATOR] AS [COD_AFFILIATOR]
   ,[AFF].[CPF_CNPJ]
   ,[AFF].[CODE] AS [CODE]
   ,[AFF].[NAME] AS [NAME_AFF]
   ,[ADDR_AFF].[ADDRESS] AS [ADDRESS]
   ,[ADDR_AFF].[NUMBER] AS [ADDRESS_NUMBER]
   ,[ADDR_AFF].[COMPLEMENT] AS [COMPLEMENT]
   ,[ADDR_AFF].[CEP] AS [CEP]
   ,[NEIGH].[NAME] AS [NEIGHBORHOOD]
   ,[CITY].[NAME] AS [CITY]
   ,STATE.[NAME] AS [STATE]
   ,STATE.[UF] AS [UF]
   ,[AFF_CONT].[DDI]
   ,[AFF_CONT].[DDD]
   ,[AFF_CONT].[NUMBER]
   ,(SELECT
			MIN([PARCENTAGE])
		FROM [TAX_PLAN]
		WHERE [COD_PLAN] = [AFF].[COD_PLAN]
		AND [ACTIVE] = 1
		AND [PARCENTAGE] <> 0)
	AS [MIN_PERCENTAGE]
   ,(SELECT
			ISNULL(MIN([ANTICIPATION_PERCENTAGE]), 0)
		FROM [TAX_PLAN]
		WHERE [COD_PLAN] = [AFF].[COD_PLAN]
		AND [ACTIVE] = 1
		AND [ANTICIPATION_PERCENTAGE] <> 0)
	AS [ANTICIPATION]
   ,[COMP].[ACCESS_KEY]
   ,[COMP].[COD_COMP]
   ,[ACCESS_APPAPI].[APPNAME] AS [USER_TOKEN]
   ,[ACCESS_APPAPI].[SECRETKEY] AS [PASS_TOKEN]
   ,[AFF].[SUBDOMAIN]
   ,[EC].[CPF_CNPJ] AS [EC_IDENTIFICATION]
   ,[EC].[NAME] AS [EC_NAME]
FROM [AFFILIATOR] AS [AFF]
JOIN [ADDRESS_AFFILIATOR] AS [ADDR_AFF]
	ON [ADDR_AFF].[COD_AFFILIATOR] = [AFF].[COD_AFFILIATOR]
		AND [ADDR_AFF].[ACTIVE] = 1
JOIN [NEIGHBORHOOD] AS [NEIGH]
	ON [NEIGH].[COD_NEIGH] = [ADDR_AFF].[COD_NEIGH]
JOIN [CITY] AS [CITY]
	ON [CITY].[COD_CITY] = [NEIGH].[COD_CITY]
JOIN STATE AS STATE
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
JOIN [AFFILIATOR_CONTACT] AS [AFF_CONT]
	ON [AFF_CONT].[COD_AFFILIATOR] = [AFF].[COD_AFFILIATOR]
		AND [AFF_CONT].[ACTIVE] = 1
JOIN [COMPANY] AS [COMP]
	ON [COMP].[COD_COMP] = [AFF].[COD_COMP]
LEFT JOIN [ACCESS_APPAPI]
	ON [ACCESS_APPAPI].[COD_COMP] = [COMP].[COD_COMP]
		AND [ACCESS_APPAPI].[COD_AFFILIATOR] = [AFF].[COD_AFFILIATOR]
JOIN [COMMERCIAL_ESTABLISHMENT] AS [EC]
	ON [EC].[COD_AFFILIATOR] = [AFF].[COD_AFFILIATOR]
		AND [EC].[ACTIVE] = 1
		AND [EC].[GENERIC_EC] = 1
WHERE ([AFF].[SUBDOMAIN] = @DOMAIN
OR AFF.WHITELABEL_URL = @WHITE_URL);

END;

GO
CREATE PROCEDURE SP_LS_CONST_COMPANY    
AS    
BEGIN
SELECT
	COD_COMP
   ,NAME
   ,CODE
   ,CPF_CNPJ
   ,COD_USER
   ,ACCESS_KEY
   ,SECRET_KEY
   ,CLIENT_ID
   ,FIREBASE_NAME
   ,OFAC_EMAIL
FROM COMPANY
END;

GO

        
        
CREATE PROCEDURE SP_LS_CONST_NEIGHBORHOOD        
AS        
BEGIN
SELECT
	NEIGHBORHOOD.COD_NEIGH
   ,NEIGHBORHOOD.NAME
   ,NEIGHBORHOOD.COD_CITY
   ,STATE.UF
   ,COUNTRY.INITIALS
   ,CITY.NAME AS 'CITY'
FROM NEIGHBORHOOD
INNER JOIN CITY
	ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
INNER JOIN STATE
	ON STATE.COD_STATE = CITY.COD_STATE
INNER JOIN COUNTRY
	ON COUNTRY.COD_COUNTRY = STATE.COD_COUNTRY

END

GO

CREATE PROCEDURE SP_LS_CONST_TYPE_EC    
AS    
BEGIN

SELECT
	COD_TYPE_ESTAB
   ,CODE
FROM TYPE_ESTAB

END

GO

CREATE PROCEDURE SP_LS_TRANSACTION_RETURN_CODE  
AS  
BEGIN
SELECT
	CODE_GW
   ,TITLE
   ,ERROR_DETAIL
   ,COD_AC
   ,ACTIVE
FROM TRANSACTION_RETURN_CODE
END

GO
/****** Object:  Table [dbo].[TRANSACTION_RETURN_CODE]    Script Date: 28/04/2020 10:30:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TRANSACTION_RETURN_CODE](
	[COD_TR_CODE] [int] NULL,
	[CODE_GW] [varchar](50) NULL,
	[TITLE] [varchar](150) NULL,
	[ERROR_DETAIL] [nvarchar](max) NULL,
	[COD_AC] [int] NULL,
	[ACTIVE] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

  
    
CREATE PROCEDURE [dbo].[SP_LS_SALES_PLAN]    
(    
 @CNPJ_AFF VARCHAR(14) = NULL,    
 @ACCESS_KEY VARCHAR(50) = NULL    
)    
AS    
BEGIN
SELECT DISTINCT
	[PLAN].COD_PLAN AS INSIDECODE
   ,[PLAN].CREATED_AT
   ,[PLAN].CODE AS 'PLAN_CODE'
   ,[PLAN].DESCRIPTION AS 'PLAN_DESC'
   ,[TYPE_PLAN].CODE AS 'TYPE_PLAN'
   ,AFFILIATOR.NAME AS 'NAME_AFF'
   ,AFFILIATOR.CPF_CNPJ
   ,TRANSACTION_TYPE.CODE AS 'TYPE_TRAN'
   ,BRAND.[GROUP] AS 'BRAND'
   ,TAX_PLAN.QTY_INI_PLOTS
   ,TAX_PLAN.QTY_FINAL_PLOTS
   ,TAX_PLAN.PARCENTAGE
   ,RATE
   ,INTERVAL
   ,ANTICIPATION_PERCENTAGE
   ,SOURCE_TRANSACTION.DESCRIPTION AS 'SOURCE_TRAN'
FROM [PLAN]
INNER JOIN TYPE_PLAN
	ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN
INNER JOIN TAX_PLAN
	ON [PLAN].COD_PLAN = TAX_PLAN.COD_PLAN
		AND [PLAN].ACTIVE = 1
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = [PLAN].COD_AFFILIATOR
INNER JOIN BRAND
	ON BRAND.COD_BRAND = TAX_PLAN.COD_BRAND
		AND BRAND.GEN_TITLES = 1
INNER JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = TAX_PLAN.COD_TTYPE
INNER JOIN SOURCE_TRANSACTION
	ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = TAX_PLAN.COD_SOURCE_TRAN
LEFT JOIN COMPANY
	ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP
WHERE [PLAN].AVAILABLE_SALE = 1
AND ((AFFILIATOR.CPF_CNPJ = @CNPJ_AFF)
OR (@CNPJ_AFF IS NULL))
AND ((COMPANY.ACCESS_KEY = @ACCESS_KEY)
OR (@ACCESS_KEY IS NULL))
END

GO

CREATE PROCEDURE [dbo].[SP_LS_AFF_DOMAIN_INFO]  
/*----------------------------------------------------------------------------------------  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author           VERSION   Date       Description  
------------------------------------------------------------------------------------------  
Luiz Aquino      V1    23/01/2020      CREATED  
------------------------------------------------------------------------------------------*/  
(  
  @ACCESS_KEY VARCHAR(300),  
  @Active INT = 1  
)  
AS  
  
BEGIN


SELECT
	AFFILIATOR.COD_AFFILIATOR
   ,AFFILIATOR.NAME
   ,AFFILIATOR.CPF_CNPJ
   ,AFFILIATOR.ACCESS_KEY_AFL
   ,AFFILIATOR.SECRET_KEY_AFL
   ,AFFILIATOR.CLIENT_ID_AFL
   ,AFFILIATOR.FIREBASE_NAME
   ,AFFILIATOR.COD_COMP
   ,AFFILIATOR.SUBDOMAIN SUB_DOMAIN
   ,THEMES.LOGO_AFFILIATE
   ,THEMES.LOGO_HEADER_AFFILIATE
   ,THEMES.COLOR_HEADER
   ,THEMES.BACKGROUND_IMAGE
   ,THEMES.SECONDARY_COLOR
FROM AFFILIATOR
INNER JOIN COMPANY
	ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP
LEFT JOIN THEMES
	ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
		AND THEMES.ACTIVE = 1
WHERE COMPANY.ACCESS_KEY = @ACCESS_KEY
AND AFFILIATOR.ACTIVE = @Active

END;

GO

  
CREATE PROCEDURE SP_LS_REGISTERED_ECS    
AS    
BEGIN

SELECT
	COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS EC
   ,AFFILIATOR.CPF_CNPJ AS AFF
FROM COMMERCIAL_ESTABLISHMENT
INNER JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR

END;

GO

alter PROCEDURE [dbo].[SP_LS_COUNTRY]      
(    
 @CODE_COUNTRY VARCHAR(100) = NULL     
)    
AS      
BEGIN
SELECT
	COD_COUNTRY
   ,NAME
   ,INITIALS
FROM COUNTRY
WHERE INITIALS LIKE '%' + @CODE_COUNTRY + '%'
OR @CODE_COUNTRY IS NULL

END

GO

ALTER PROCEDURE [dbo].[SP_LS_CELL_OPERATOR]    
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_LS_CELL_OPERATOR]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author                          VERSION        Date                            Description    
------------------------------------------------------------------------------------------    
Kennedy Alef     V1    27/07/2018      Creation    
------------------------------------------------------------------------------------------*/    
AS    
BEGIN
SELECT
	COD_OPER AS INSIDE_CODE
   ,NAME
   ,CODE
FROM CELL_OPERATOR

END;

GO

CREATE PROCEDURE [dbo].[SP_FD_BRANCH_BUSINESS]      
/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_LS_BRANCH_BUSINESS]      
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Lucas Aguiar          V1     05/12/2019     Creation        
------------------------------------------------------------------------------------------*/        
(  
    @param varchar(255) = null  
)  
AS          
BEGIN
SELECT
	COD_BRANCH_BUSINESS
   ,[NAME]
FROM BRANCH_BUSINESS
WHERE (NAME LIKE '%' + @param + '%'
AND @param IS NOT NULL)
OR (@param IS NULL)
ORDER BY [NAME]
END

GO

/****** Object:  UserDefinedTableType [dbo].[TP_ORDER_ITEM]    Script Date: 03/05/2020 16:27:04 ******/
CREATE TYPE [dbo].[TP_ORDER_ITEM] AS TABLE(
	[COD_PR_AFF] [int] NOT NULL,
	[PRICE] [decimal](22, 6) NOT NULL,
	[QUANTITY] [int] NOT NULL,
	[CHIP] [varchar](256) NOT NULL,
	[CELL_OPERATOR] [varchar](40) NULL
)
GO



GO
CREATE PROCEDURE SP_FD_ORDERS_TO_CONTINUE  
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

/****** Object:  Table [dbo].[ORDER_SITUATION]    Script Date: 28/04/2020 11:21:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ORDER_SITUATION](
	[COD_ORDER_SIT] [int] IDENTITY(1,1) NOT NULL,
	[NAME] [varchar](300) NULL,
	[CODE] [varchar](300) NULL,
	[DESCRIPTION] [nvarchar](max) NULL,
	[VISIBLE] [int] NULL,
	[ORDER_SIT_RESUME] [varchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_ORDER_SIT] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO



CREATE TABLE [dbo].[ORDER](
	[COD_ODR] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NULL,
	[AMOUNT] [decimal](22, 8) NULL,
	[CODE] [int] NULL,
	[COD_EC] [int] NULL,
	[COD_USER] [int] NULL,
	[COD_SITUATION] [int] NULL,
	[COD_TRAN] [int] NULL,
	[COD_ORDER_SIT] [int] NULL,
	[COMMENT] [varchar](500) NULL,
	[PICKING_ORDER] [varchar](200) NULL,
 CONSTRAINT [PK_ORDER] PRIMARY KEY CLUSTERED 
(
	[COD_ODR] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ORDER] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

ALTER TABLE [dbo].[ORDER]  WITH CHECK ADD FOREIGN KEY([COD_ORDER_SIT])
REFERENCES [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT])
GO

ALTER TABLE [dbo].[ORDER]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_EC] FOREIGN KEY([COD_EC])
REFERENCES [dbo].[COMMERCIAL_ESTABLISHMENT] ([COD_EC])
GO

ALTER TABLE [dbo].[ORDER] CHECK CONSTRAINT [FK_ORDER_EC]
GO

ALTER TABLE [dbo].[ORDER]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_SITUATION] FOREIGN KEY([COD_SITUATION])
REFERENCES [dbo].[SITUATION] ([COD_SITUATION])
GO

ALTER TABLE [dbo].[ORDER] CHECK CONSTRAINT [FK_ORDER_SITUATION]
GO

ALTER TABLE [dbo].[ORDER]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_TRANSACTION] FOREIGN KEY([COD_TRAN])
REFERENCES [dbo].[TRANSACTION] ([COD_TRAN])
GO

ALTER TABLE [dbo].[ORDER] CHECK CONSTRAINT [FK_ORDER_TRANSACTION]
GO

ALTER TABLE [dbo].[ORDER]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_USER] FOREIGN KEY([COD_USER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[ORDER] CHECK CONSTRAINT [FK_ORDER_USER]
GO

  
CREATE PROCEDURE SP_VAL_USER_APP_ACESS_CLAIM      
(      
 @Username VARCHAR(200),      
 @Password VARCHAR(500)      
) AS BEGIN

SELECT
	COD_COMP
   ,COD_AFFILIATOR
   ,CLAIMS
   ,COD_ACCESS_APP
FROM ACCESS_APPAPI
WHERE [NAME] = @Username
AND SECRETKEY = @Password
AND CLAIMS IS NOT NULL

END

GO

/****** Object:  UserDefinedTableType [dbo].[TP_PARTNERS]    Script Date: 28/04/2020 12:11:48 ******/
CREATE TYPE [dbo].[TP_PARTNERS] AS TABLE(
	[NAME] [varchar](300) NULL,
	[CPF] [varchar](20) NULL,
	[DOCUMENT] [varchar](100) NULL,
	[BIRTHDAY] [datetime] NULL,
	[COD_EC] [int] NULL,
	[COD_TYPE_PARTNER] [int] NULL,
	[PERCENTAGE_QUOTAS] [int] NULL,
	[ACTIVE] [int] NULL
)
GO

/****** Object:  UserDefinedTableType [dbo].[TP_DOCUMENT_LIST]    Script Date: 28/04/2020 12:12:14 ******/
CREATE TYPE [dbo].[TP_DOCUMENT_LIST] AS TABLE(
	[COD_DOC_TYPE] [int] NOT NULL,
	[PATH_DOC] [varchar](300) NOT NULL
)
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

GO

CREATE PROCEDURE [DBO].[SP_REG_COMMERCIAL_ORDER]                                                          
                  
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
   @COD_AFFILIATOR INT = ( SELECT
		COD_AFFILIATOR
	FROM AFFILIATOR
	WHERE CPF_CNPJ = @AFFILIATOR);


DECLARE @HAVE_USER INT;

BEGIN


IF (SELECT
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
   ,AFFILIATOR.COD_AFFILIATOR AS COD_AFF
   ,AFFILIATOR.CPF_CNPJ AS CNPJ_AFF
   ,EC_TRANSIRE.USER_ONLINE
   ,EC_TRANSIRE.PWD_ONLINE
   ,EC_TRANSIRE.COD_EC AS EC_TRANSIRE
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL AS 'SITE'
   ,11 AS 'USERNAME'
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

SET @DOCUMENT_TYPE =
CASE
	WHEN LEN(@CPF_CNPJ) = 11 THEN 'CPF'
	ELSE 'CNPJ'
END

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
	COMMERCIAL_ESTABLISHMENT.COD_EC
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,AFFILIATOR.COD_AFFILIATOR AS COD_AFF
   ,AFFILIATOR.CPF_CNPJ AS CNPJ_AFF
   ,EC_TRANSIRE.USER_ONLINE
   ,EC_TRANSIRE.PWD_ONLINE
   ,EC_TRANSIRE.COD_EC AS EC_TRANSIRE
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL AS 'SITE'
   ,11 AS 'USERNAME'
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
END;
END;

GO

    
CREATE PROCEDURE [SP_FD_DATA_CUSTOMER_EC]    
 @COD_EC INT    
AS    
BEGIN
SELECT
	[EC].[NAME] AS [NAME]
   ,[SEX_TYPE].[CODE] AS [GENDER]
   ,[CB].[DDD]
   ,[CB].[NUMBER] AS [PHONE]
   ,[EC].[EMAIL]
   ,[EC].[DOCUMENT_TYPE]
   ,[EC].[CPF_CNPJ] AS [DOCUMENT]
   ,[EC].[BIRTHDATE]
   ,AB.ADDRESS AS STREET_EC
   ,AB.NUMBER NUMBER_EC
   ,AB_NEIGH.NAME AS NEIGHBORHOOD_EC
   ,AB_CITY.NAME AS CITY_EC
   ,AB_STATE.UF AS UF_EC
   ,AB_COUNTRY.NAME AS COUNTRY_EC
   ,AB.CEP AS CEP_EC
--,ADD_ORDER.ADDRESS AS STREET_ORDER  
--,ADD_ORDER.NUMBER AS NUMBER_ORDER  
--,ADD_ORDER_NEIGH.NAME AS NEIGHBORHOOD_ORDER  
--,ADD_ORDER_CITY.NAME AS CITY_ORDER  
--,ADD_ORDER_STATE.UF AS UF_ORDER  
--,ADD_ORDER_COUNTRY.NAME AS COUNTRY_ORDER  
--,ADD_ORDER.CEP AS CEP_ORDER  

FROM [COMMERCIAL_ESTABLISHMENT] AS [EC]
JOIN [SEX_TYPE]
	ON [SEX_TYPE].[COD_SEX] = [EC].[COD_SEX]
JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_EC] = [EC].[COD_EC]
JOIN [CONTACT_BRANCH] AS [CB]
	ON [CB].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [CB].[ACTIVE] = 1
JOIN [ADDRESS_BRANCH] AS [AB]
	ON [AB].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [AB].[ACTIVE] = 1
JOIN NEIGHBORHOOD AB_NEIGH
	ON AB_NEIGH.COD_NEIGH = AB.COD_NEIGH
JOIN CITY AB_CITY
	ON AB_CITY.COD_CITY = AB_NEIGH.COD_CITY
JOIN STATE AB_STATE
	ON AB_STATE.COD_STATE = AB_CITY.COD_STATE
JOIN COUNTRY AB_COUNTRY
	ON AB_COUNTRY.COD_COUNTRY = AB_STATE.COD_COUNTRY
--JOIN NEIGHBORHOOD ADD_ORDER_NEIGH  
-- ON ADD_ORDER_NEIGH.COD_NEIGH = ADD_ORDER.COD_NEIGH  
--JOIN CITY ADD_ORDER_CITY  
-- ON ADD_ORDER_CITY.COD_CITY = ADD_ORDER_NEIGH.COD_CITY  
--JOIN STATE ADD_ORDER_STATE  
-- ON ADD_ORDER_STATE.COD_STATE = ADD_ORDER_CITY.COD_STATE  
--JOIN COUNTRY ADD_ORDER_COUNTRY  
-- ON ADD_ORDER_COUNTRY.COD_COUNTRY = ADD_ORDER_STATE.COD_COUNTRY  
WHERE [EC].[ACTIVE] = 1
AND [EC].[COD_EC] = @COD_EC;
END;

GO

INSERT INTO USERS (CREATED_AT
, COD_ACCESS
, CPF_CNPJ
, IDENTIFICATION
, EMAIL
, FIRST_LOGIN
, LOGGED
, ACTIVE
, COD_COMP
, COD_MODULE
, ALTERNATIVE_EMAIL
, COD_PROFILE
, COD_SEX
, ACCEPT)
	VALUES (current_timestamp, 'ECOMMERCE_USER', '03125330041', 'ECOMMERCE_USER', 'ecommerce@ecommerce.com.br', 1, 0, 1, 8, 1, 'ecommerce@ecommerce.com.br', 4, 1, 1)

GO

INSERT INTO RISK_SITUATION (NAME, VIEWER, TRANSACTION_VIEWER, SITUATION_EC)
	VALUES ('Pending Docs', 1, 1, 0);

GO

/****** Object:  Table [dbo].[ORDER_ADDRESS]    Script Date: 28/04/2020 12:36:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ORDER_ADDRESS](
	[COD_ODR_ADDR] [int] IDENTITY(1,1) NOT NULL,
	[ADDRESS] [varchar](448) NOT NULL,
	[NUMBER] [varchar](12) NOT NULL,
	[COMPLEMENT] [varchar](300) NULL,
	[CEP] [varchar](12) NOT NULL,
	[COD_NEIGH] [int] NOT NULL,
	[COD_EC] [int] NOT NULL,
	[ACTIVE] [int] NOT NULL,
	[COD_ODR] [int] NULL,
 CONSTRAINT [PK_ORDER_ADDRESS] PRIMARY KEY CLUSTERED 
(
	[COD_ODR_ADDR] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ORDER_ADDRESS] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[ORDER_ADDRESS]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_ADDRESS_EC] FOREIGN KEY([COD_EC])
REFERENCES [dbo].[COMMERCIAL_ESTABLISHMENT] ([COD_EC])
GO

ALTER TABLE [dbo].[ORDER_ADDRESS] CHECK CONSTRAINT [FK_ORDER_ADDRESS_EC]
GO

ALTER TABLE [dbo].[ORDER_ADDRESS]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_ADDRESS_NEIGH] FOREIGN KEY([COD_NEIGH])
REFERENCES [dbo].[NEIGHBORHOOD] ([COD_NEIGH])
GO

ALTER TABLE [dbo].[ORDER_ADDRESS] CHECK CONSTRAINT [FK_ORDER_ADDRESS_NEIGH]
GO

ALTER TABLE [dbo].[ORDER_ADDRESS]  WITH CHECK ADD  CONSTRAINT [FK_ORDER_ORDER_ADDRESS] FOREIGN KEY([COD_ODR])
REFERENCES [dbo].[ORDER] ([COD_ODR])
GO

ALTER TABLE [dbo].[ORDER_ADDRESS] CHECK CONSTRAINT [FK_ORDER_ORDER_ADDRESS]
GO

/****** Object:  Sequence [dbo].[SEQ_ORDERCODE]    Script Date: 28/04/2020 12:38:33 ******/
CREATE SEQUENCE [dbo].[SEQ_ORDERCODE] 
 AS [bigint]
 START WITH 20000
 INCREMENT BY 1
 MINVALUE -9223372036854775808
 MAXVALUE 9223372036854775807
 CACHE
GO

SET IDENTITY_INSERT [dbo].[ORDER_SITUATION] ON

INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (1, N'PAYMENT PENDING', N'PAGAMENTO PENDENTE', N'Pedido inserido na base de dados, aguardando a transação de pagamento ser realizada para seguir o processo de faturamento.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (2, N'PAYMENT MADE', N'PAGAMENTO EFETUADO', N'Transação de pagamento dos produtos realizada e confirmada. ', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (3, N'PAYMENT DENIED', N'PAGAMENTO NEGADO', N'Forma de pagamento utilizada não aprovada pela adquirente. Necessário refazer o pedido.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (4, N'PENDING ANALYSIS RISK', N'EM ANÁLISE DE RISCO', N'Etapa em que o estabelecimento comercial passa por um processo de prevenção a fraude e golpes.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (5, N'APPROVED AFTER RISK ANALYSIS', N'APROVADO PELA ÁREA DE RISCO', N'Não foram encontrados riscos de fraude por parte do estabelecimento comercial.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (6, N'FAILED AFTER RISK ANALYSIS', N'NEGADO PELA ÁREA DE RISCO', N'Foram encontrados riscos de fraude por parte do estabelecimento comercial. Por isso, a compra foi reprovada.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (7, N'PREPARING', N'EM PREPARAÇÃO', N'Após a liberação da área de risco, os produtos foram enviados para preparação de envio.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (8, N'LOGISTICS UNDER ANALYSIS', N'LOGÍSTICA EM ANÁLISE', NULL, 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (9, N'DISPATCHED', N'DESPACHADO', N'Produto(s) enviado(s) ao endereço de entrega.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (10, N'DELIVERED', N'ENTREGUE', N'Produto(s) recebido(s) no endereço de entrega.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME])
	VALUES (11, N'UNDELIVERABLE', N'NÃO ENTREGUE', N'Produto(s) não recebido(s) no endereço de entrega.', 1, NULL)
SET IDENTITY_INSERT [dbo].[ORDER_SITUATION] OFF

INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('7070790CELER', 990.00, 1)

GO

  
CREATE PROCEDURE [DBO].[SP_UP_ORDER]                        
          
/*************************************************************************************************************************  
----------------------------------------------------------------------------------------                       
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                       
    Project.......: TKPP                       
    ------------------------------------------------------------------------------------------                       
    Author                          VERSION        Date                            Description                              
    ------------------------------------------------------------------------------------------                       
    Lucas Aguiar     V1      2019-10-28         Creation                             
    ------------------------------------------------------------------------------------------      
*************************************************************************************************************************/      
                       
(  
 @CODE_ORDER  INT,   
 @ORDER_SIT   VARCHAR(150),   
 @CODE_TRAN   VARCHAR(255)   = NULL,   
 @AMOUNT      DECIMAL(22, 6)  = NULL,   
 @CODE        VARCHAR(128)   = NULL,   
 @COMMENT     VARCHAR(500)   = NULL,   
 @ACCESS_USER VARCHAR(200)   = NULL)  
AS  
BEGIN
  
    DECLARE   
   @COD_ODR INT;
  
    DECLARE   
   @COD_TRAN INT;
  
    DECLARE   
   @COD_SITUATION INT;
  
    DECLARE   
   @SIT_ORDER VARCHAR(400);
  
    DECLARE   
   @DOCUMENT_TYPE VARCHAR(150);
  
    DECLARE   
   @COD_EC INT;
  
    DECLARE   
   @EMAIL VARCHAR(255);

SELECT
	@COD_ODR = [COD_ODR]
   ,@SIT_ORDER = [ORDER_SITUATION].[NAME]
   ,@DOCUMENT_TYPE = [COMMERCIAL_ESTABLISHMENT].[DOCUMENT_TYPE]
   ,@COD_EC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,@EMAIL = [COMMERCIAL_ESTABLISHMENT].[EMAIL]
FROM [ORDER_SITUATION]
INNER JOIN [ORDER]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
		AND [ORDER].[CODE] = @CODE_ORDER
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC];

DECLARE @SIT_TRAN INT;
DECLARE @SIT_TRAN_DESC INT;

SELECT
	@COD_SITUATION = [COD_ORDER_SIT]
FROM [ORDER_SITUATION]
WHERE [NAME] = @ORDER_SIT;

IF (@ORDER_SIT = 'PAYMENT MADE')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;
IF (@ORDER_SIT = 'PAYMENT DENIED')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN = 3
THROW 60000, '[TRANSACTION] CAN''T''BE CONFIRM', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PENDING ANALYSIS RISK')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PAYMENT MADE')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'APPROVED AFTER RISK ANALYSIS')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PENDING ANALYSIS RISK')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 2
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'FAILED AFTER RISK ANALYSIS')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PENDING ANALYSIS RISK')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 3
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PREPARING')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PAYMENT MADE')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DELIVERED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'UNDELIVERABLE')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DISPATCHED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;


IF (@ORDER_SIT = 'LOGISTICS UNDER ANALYSIS')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

EXEC [SP_UP_TRACKING_ORDER] @COD_ODR;

SELECT
	[ORDER_SITUATION].[ORDER_SIT_RESUME]
   ,[COMMERCIAL_ESTABLISHMENT].[EMAIL]
   ,[USERS].[IDENTIFICATION]
   ,[ORDER].[CODE]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ORDER_ADDRESS].[CEP]
   ,[CITY].[NAME]
   ,STATE.[UF]
   ,[COUNTRY].[INITIALS]
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [ORDER]
	ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
INNER JOIN [USERS]
	ON [USERS].[COD_USER] = [ORDER].[COD_USER]
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN STATE
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
WHERE [ORDER].[CODE] = @CODE_ORDER;


END;

GO

/****** Object:  Table [dbo].[TRACKING_ORDER]    Script Date: 28/04/2020 16:46:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TRACKING_ORDER](
	[COD_TR_ORDER] [int] IDENTITY(1,1) NOT NULL,
	[COD_ODR] [int] NULL,
	[CREATED_AT] [datetime] NULL,
	[COD_ORDER_SIT] [int] NULL,
	[SITUATION_ORDER] [varchar](250) NULL,
	[COD_USER] [int] NULL,
	[USERS] [varchar](200) NULL,
	[COMMENT] [nvarchar](max) NULL,
	[MODIFY_DATE] [datetime] NULL,
	[COD_TRAN] [int] NULL,
	[NSU] [varchar](255) NULL,
	[BRAND] [varchar](100) NULL,
	[PLOTS] [int] NULL,
	[COD_SITUATION] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_TR_ORDER] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_ODR])
REFERENCES [dbo].[ORDER] ([COD_ODR])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_ORDER_SIT])
REFERENCES [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_ODR])
REFERENCES [dbo].[ORDER] ([COD_ODR])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_ORDER_SIT])
REFERENCES [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_SITUATION])
REFERENCES [dbo].[SITUATION] ([COD_SITUATION])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_SITUATION])
REFERENCES [dbo].[SITUATION] ([COD_SITUATION])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_TRAN])
REFERENCES [dbo].[TRANSACTION] ([COD_TRAN])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_TRAN])
REFERENCES [dbo].[TRANSACTION] ([COD_TRAN])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_USER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[TRACKING_ORDER]  WITH CHECK ADD FOREIGN KEY([COD_USER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

/****** Object:  Table [dbo].[WEBHOOK_PICKING]    Script Date: 29/04/2020 11:04:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WEBHOOK_PICKING](
	[COD_WEBHOOK_PICK] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NULL,
	[MODIFY_DATE] [datetime] NULL,
	[CODE] [int] NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[ORDER_NUMEBER] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_WEBHOOK_PICK] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[WEBHOOK_PICKING] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

/****** Object:  Table [dbo].[WEBHOOKS]    Script Date: 29/04/2020 11:05:03 ******/
SET ANSI_NULLS ON
GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE TABLE [dbo].[WEBHOOKS](
--	[APPNAME] [varchar](64) NOT NULL,
--	[USERNAME] [varchar](128) NOT NULL,
--	[ID] [varchar](128) NOT NULL,
--	[DATA] [varchar](max) NOT NULL
--) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
--GO

  
CREATE PROCEDURE [SP_GET_SITUATION_BY_PICKING]   
 @SITUATION VARCHAR(255)  
AS  
BEGIN

SELECT
	[ORDER_SITUATION].[COD_ORDER_SIT]
   ,[ORDER_SITUATION].[NAME]
FROM [BASIS_SITUATION]
JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [BASIS_SITUATION].[COD_ORDER_SIT]
WHERE [BASIS_SITUATION].[CODE] = @SITUATION;

END;

GO

/****** Object:  Table [dbo].[BASIS_SITUATION]    Script Date: 29/04/2020 11:07:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BASIS_SITUATION](
	[COD_BASIS_SIT] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](255) NOT NULL,
	[COD_ORDER_SIT] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_BASIS_SIT] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[BASIS_SITUATION]  WITH CHECK ADD FOREIGN KEY([COD_ORDER_SIT])
REFERENCES [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT])
GO

GO
SET IDENTITY_INSERT [dbo].[BASIS_SITUATION] ON
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (1, N'PROBLEMA ENTREGA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (2, N'A ENTREGA NAO PODE SER EFETUADA - CLIENTE RECUSOU-SE A RECEBER', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (3, N'A ENTREGA NAO PODE SER EFETUADA - CLIENTE DESCONHECIDO NO LOCAL', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (4, N'A ENTREGA NAO PODE SER EFETUADA - CLIENTE MUDOU-SE', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (5, N'A ENTREGA NAO PODE SER EFETUADA - EMPRESA SEM EXPEDIENTE', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (6, N'A ENTREGA NAO PODE SER EFETUADA - DIRECIONAMENTO ERRADO DOS CORREIOS', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (7, N'DEVOLVIDO', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (8, N'CLIENTE AUSENTE', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (9, N'ENDEREÇO INCOMPLETO', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (10, N'ENDEREÇO INCORRETO', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (11, N'ESTABELECIMENTO FECHADO', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (12, N'COLETADO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (13, N'RECUSA POR PEDIDO DE COMPRA CANCELADO', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (14, N'ENDEREÇO DO CLIENTE DESTINO NÃO LOCALIZADO', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (15, N'A ENTREGA NAO PODE SER EFETUADA - CLIENTE RECUSOU A RECEBER', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (16, N'RECUSA POR FALTA DE AGENDAMENTO', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (17, N'EXCEDEU A QUANTIDADE DE VISITAS', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (18, N'ROTA INCORRETA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (19, N'EM PROCESSO DE DEVOLUCAO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (20, N'ENTREGA REALIZADA - 1 TENTATIVA', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (21, N'ENTREGA REALIZADA - 2 TENTATIVA', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (22, N'ENTREGA REALIZADA - 3 TENTATIVA', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (23, N'ENTREGA REALIZADA NORMALMENTE', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (24, N'ENTREGUE', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (25, N'PRE-BAIXA (ENTREGUE)', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (26, N'PRE-BAIXA (CUSTODIA)', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (27, N'NOTA FISCAL DENEGADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (28, N'ENVIADO CORREIOS', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (29, N'ENVIADO FILIAL PA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (30, N'ENVIADO PA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (31, N'POSTADO - CORREIOS', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (32, N'POSTADO - TRANSPORTADORA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (33, N'AWB EMITIDA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (34, N'MERCADORIA AVARIADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (35, N'MERCADORIA RECUSADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (36, N'MERCADORIA ROUBADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (37, N'MERCADORIA EXTRAVIADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (38, N'MERCADORIA APREENDIDA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (39, N'REENVIO AUTORIZADO PELO CLIENTE', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (40, N'REENVIO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (41, N'EM TRANSITO', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (42, N'MERCADORIA EM ROTA DE ENTREGA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (43, N'AGUARDANDO RETIRADA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (44, N'MERCADORIA EM ROTEIRIZAÇÃO NO DEPÓSITO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (45, N'RECEBIDO CD', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (46, N'MERCADORIA RECEBIDA NA BASE', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (47, N'EM TRANSITO PARA DESPACHO', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (48, N'EM TRANSITO PARA RETIRADA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (49, N'EM TRANSITO PARA ENTREGA', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (50, N'MERCADORIA DESPACHADA ( ENTREGUE AO PARCEIRO )', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (51, N'RECEBIDO CD / AGUARDANDO ROTEIRIZAÇÃO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (52, N'MERCADORIA DESPACHADA ( ENTREGUE AO CORREIO )', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (53, N'DISPONIVEL PARA RETIRADA', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (54, N'AGUARDANDO AGENDAMENTO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (55, N'ENVIO LIBERADO PAX', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (56, N'SAIDA DO VOO', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (57, N'CHEGADA DO VOO', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (58, N'ENTREGUE NA PA', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (59, N'AGUARDANDO ESTOQUE', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (60, N'PRONTO PARA FATURAR', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (61, N'FATURADO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (62, N'DESPACHADO', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (63, N'AGUARDANDO LIBERAÇÃO DE GNRE', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (64, N'AGUARDANDO DADOS PARA DESPACHO', 9)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (65, N'AGUARDANDO EXPEDICAO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (66, N'GERADO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (67, N'RECEBIDO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (68, N'PRE-ANALISE ', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (69, N'PRE-ANALISE NEGADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (70, N'CADASTRADO', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (71, N'RECEITA DEVOLVIDA', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (72, N'DISPONIVEL', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (73, N'FINALIZADO', 10)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (74, N'CANCELADO', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (75, N'NOTA FISCAL INUTILIZADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (76, N'NOTA FISCAL CANCELADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (77, N'NOTA FISCAL REJEITADA', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (78, N'ERRO DADOS CADASTRAIS', 8)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (79, N'ERRO PEDIDO', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (80, N'MERCADORIA AGUARDANDO ANALISE PAX', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (81, N'PRE-ANALISE NEGADA - CPF OU CNPJ INVÁLIDO', 11)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (82, N'AGUARDANDO REPROCESSAMENTO SINERGI', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (83, N'AGUARDANDO SERIAL', 7)
GO
INSERT [dbo].[BASIS_SITUATION] ([COD_BASIS_SIT], [CODE], [COD_ORDER_SIT])
	VALUES (84, N'NAO CREDENCIADO NA ADQUIRENTE', 8)
GO
SET IDENTITY_INSERT [dbo].[BASIS_SITUATION] OFF
GO


  
ALTER PROCEDURE [DBO].[SP_UP_ORDER]                        
          
/*************************************************************************************************************************  
----------------------------------------------------------------------------------------                       
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                       
    Project.......: TKPP                       
    ------------------------------------------------------------------------------------------                       
    Author                          VERSION        Date                            Description                              
    ------------------------------------------------------------------------------------------                       
    Lucas Aguiar     V1      2019-10-28         Creation                             
    ------------------------------------------------------------------------------------------      
*************************************************************************************************************************/      
                       
(  
 @CODE_ORDER  INT,   
 @ORDER_SIT   VARCHAR(150),   
 @CODE_TRAN   VARCHAR(255)   = NULL,   
 @AMOUNT      DECIMAL(22, 6)  = NULL,   
 @CODE        VARCHAR(128)   = NULL,   
 @COMMENT     VARCHAR(500)   = NULL,   
 @ACCESS_USER VARCHAR(200)   = NULL)  
AS  
BEGIN
  
    DECLARE   
   @COD_ODR INT;
  
    DECLARE   
   @COD_TRAN INT;
  
    DECLARE   
   @COD_SITUATION INT;
  
    DECLARE   
   @SIT_ORDER VARCHAR(400);
  
    DECLARE   
   @DOCUMENT_TYPE VARCHAR(150);
  
    DECLARE   
   @COD_EC INT;
  
    DECLARE   
   @EMAIL VARCHAR(255);

SELECT
	@COD_ODR = [COD_ODR]
   ,@SIT_ORDER = [ORDER_SITUATION].[NAME]
   ,@DOCUMENT_TYPE = [COMMERCIAL_ESTABLISHMENT].[DOCUMENT_TYPE]
   ,@COD_EC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,@EMAIL = [COMMERCIAL_ESTABLISHMENT].[EMAIL]
FROM [ORDER_SITUATION]
INNER JOIN [ORDER]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
		AND [ORDER].[CODE] = @CODE_ORDER
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC];

DECLARE @SIT_TRAN INT;
DECLARE @SIT_TRAN_DESC INT;

SELECT
	@COD_SITUATION = [COD_ORDER_SIT]
FROM [ORDER_SITUATION]
WHERE [NAME] = @ORDER_SIT;

IF (@CODE_TRAN IS NULL)
BEGIN
SELECT
	@COD_TRAN = [TRANSACTION].[COD_TRAN]
   ,@SIT_TRAN = [TRANSACTION].[COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [ORDER]
	ON [ORDER].COD_TRAN = [TRANSACTION].COD_TRAN
WHERE [ORDER].[CODE] = @CODE_ORDER
END
IF (@ORDER_SIT = 'PAYMENT MADE')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;
IF (@ORDER_SIT = 'PAYMENT DENIED')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN = 3
THROW 60000, '[TRANSACTION] CAN''T''BE CONFIRM', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PENDING ANALYSIS RISK')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PAYMENT MADE')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'APPROVED AFTER RISK ANALYSIS')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PENDING ANALYSIS RISK')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 2
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'FAILED AFTER RISK ANALYSIS')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PENDING ANALYSIS RISK')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 3
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PREPARING')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

IF (@SIT_ORDER <> 'PAYMENT MADE')
THROW 60000, 'INVALID [ORDER SITUATION]', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DELIVERED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'UNDELIVERABLE')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DISPATCHED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;


IF (@ORDER_SIT = 'LOGISTICS UNDER ANALYSIS')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].COMMENT = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

EXEC [SP_UP_TRACKING_ORDER] @COD_ODR;

SELECT
	[ORDER_SITUATION].[ORDER_SIT_RESUME]
   ,[COMMERCIAL_ESTABLISHMENT].[EMAIL]
   ,[USERS].[IDENTIFICATION]
   ,[ORDER].[CODE]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ORDER_ADDRESS].[CEP]
   ,[CITY].[NAME]
   ,STATE.[UF]
   ,[COUNTRY].[INITIALS]
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [ORDER]
	ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
INNER JOIN [USERS]
	ON [USERS].[COD_USER] = [ORDER].[COD_USER]
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN STATE
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
WHERE [ORDER].[CODE] = @CODE_ORDER;


END;

GO

alter PROCEDURE [DBO].[SP_REG_COMMERCIAL_ORDER]                                                            
                    
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
   @COD_AFFILIATOR INT = ( SELECT
		COD_AFFILIATOR
	FROM AFFILIATOR
	WHERE CPF_CNPJ = @AFFILIATOR);


DECLARE @HAVE_USER INT;

BEGIN


IF (SELECT
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
   ,AFFILIATOR.COD_AFFILIATOR AS COD_AFF
   ,AFFILIATOR.CPF_CNPJ AS CNPJ_AFF
   ,EC_TRANSIRE.USER_ONLINE
   ,EC_TRANSIRE.PWD_ONLINE
   ,EC_TRANSIRE.COD_EC AS EC_TRANSIRE
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL AS 'SITE'
   ,11 AS 'USERNAME'
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

SET @DOCUMENT_TYPE =
CASE
	WHEN LEN(@CPF_CNPJ) = 11 THEN 'CPF'
	ELSE 'CNPJ'
END

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
	   ,1
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
	COMMERCIAL_ESTABLISHMENT.COD_EC
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,AFFILIATOR.COD_AFFILIATOR AS COD_AFF
   ,AFFILIATOR.CPF_CNPJ AS CNPJ_AFF
   ,EC_TRANSIRE.USER_ONLINE
   ,EC_TRANSIRE.PWD_ONLINE
   ,EC_TRANSIRE.COD_EC AS EC_TRANSIRE
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL AS 'SITE'
   ,11 AS 'USERNAME'
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
END;
END;

GO

  
CREATE PROCEDURE [DBO].[SP_VAL_OPERATION_AFF]  
/*----------------------------------------------------------------------------------------              
Procedure Name: [SP_VAL_OPERATION_AFF]             
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION       Date                            Description              
------------------------------------------------------------------------------------------      
Caike Uchôa                       v4         01/10/2019                        creation    
  
------------------------------------------------------------------------------------------*/        
(  
@COD_AFILIATOR INT   
)  
AS  
BEGIN

SELECT
	COD_AFFILIATOR
   ,[NAME]
   ,OPERATION_AFF
FROM AFFILIATOR
WHERE COD_AFFILIATOR = @COD_AFILIATOR

END

GO

CREATE PROCEDURE [dbo].SP_FD_STATUS_EC  
    /*---------------------------------------------------------------------------------------- 
    Procedure Name: [SP_FD_STATUS_EC] 
    Project.......: TKPP 
    ------------------------------------------------------------------------------------------ 
    Author                          VERSION        Date                            Description        
    ------------------------------------------------------------------------------------------ 
    Lucas Aguiar                    V1               2019-10-31                        Creation       
    ------------------------------------------------------------------------------------------*/ 
(  
    @COD_EC int
) 
AS  



BEGIN


SELECT
	IIF(COD_RISK_SITUATION = 8, 1, 0) [PENDING_DOC]
FROM COMMERCIAL_ESTABLISHMENT
WHERE COD_EC = @COD_EC
AND ACTIVE = 1;
END



GO
 

CREATE PROCEDURE [dbo].[SP_REG_DOC_BY_GROUB]                  
(                  
	@COD_BRANCH INT,                  
	@COD_USER INT,          
	@DOCS [TP_DOCUMENT_LIST] READONLY
)                  
AS                  
                  
BEGIN                  
                  
 UPDATE DOCS_BRANCH SET ACTIVE = 0, MODIFY_DATE = CURRENT_TIMESTAMP                  
 FROM DOCS_BRANCH 
	JOIN @DOCS DOCS ON DOCS.COD_DOC_TYPE = DOCS_BRANCH.COD_DOC_TYPE
 WHERE COD_BRANCH = @COD_BRANCH AND ACTIVE = 1;           

 INSERT INTO DOCS_BRANCH                  
 (                  
  COD_USER,                  
  COD_BRANCH,                  
  COD_SIT_REQ,                  
  COD_DOC_TYPE,                  
  PATH_DOC                
 )      
 SELECT 
	@COD_USER,
	@COD_BRANCH,
	16,
	DOCS.COD_DOC_TYPE,
	DOCS.PATH_DOC
 FROM @DOCS DOCS
  
 IF @@rowcount < 1                  
  THROW 60000, 'COULD NOT REGISTER DOCS_BRANCH' , 1;              
          
	  
END;  

go

IF OBJECT_ID('SP_REG_PROV_PASS_USER') IS NOT NULL DROP PROCEDURE SP_REG_PROV_PASS_USER;
GO
CREATE PROCEDURE [dbo].[SP_REG_PROV_PASS_USER]        
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
INSERT INTO PROVISORY_PASS_USER (VALUE, COD_USER)
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

IF OBJECT_ID('SP_USER_CLAIMS') IS NOT NULL
DROP PROCEDURE SP_USER_CLAIMS
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

go

IF OBJECT_ID('SP_LS_AFFILIATOR_COMP') IS NOT NULL
DROP PROCEDURE SP_LS_AFFILIATOR_COMP
GO
CREATE PROCEDURE [dbo].[SP_LS_AFFILIATOR_COMP]                      
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

GO

IF OBJECT_ID('SP_LS_PRODUCTS') IS NOT NULL DROP PROCEDURE SP_LS_PRODUCTS
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

 IF OBJECT_ID('SP_REG_ORDER') IS NOT NULL DROP PROCEDURE SP_REG_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_REG_ORDER]                          
              
/***************************************************************************************************************************  
----------------------------------------------------------------------------------------                         
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                         
    Project.......: TKPP                         
    ------------------------------------------------------------------------------------------                         
    Author                          VERSION        Date                            Description                                
    ------------------------------------------------------------------------------------------                         
    Lucas Aguiar     V1      2019-10-28         Creation                               
    ------------------------------------------------------------------------------------------          
***************************************************************************************************************************/          
                         
(  
 @CPF_EC           VARCHAR(50),   
 @CPF_AFF          VARCHAR(50),   
 @ACCESS_USER      VARCHAR(50),   
 @ADDRESS_ORDER    VARCHAR(300),   
 @NUMBER_ORDER     VARCHAR(100),   
 @COMPLEMENT_ORDER VARCHAR(200)    = NULL,   
 @REFPOINT_ORDER   VARCHAR(100)    = NULL,   
 @CEP_ORDER        VARCHAR(12),   
 @COD_NEIGH_ORDER  INT,   
 @AMOUNT           DECIMAL(22, 6),   
 @CODE             VARCHAR(128)    = NULL,   
 @TP_ORDER_ITEM    [TP_ORDER_ITEM] READONLY)  
AS  
BEGIN
  
  
    DECLARE @COD_EC INT;
  
  
    DECLARE @COD_AFF INT;
  
  
    DECLARE @COD_USER INT;
  
  
    DECLARE @COD_ORDER INT;



SELECT
	@COD_AFF = [COD_AFFILIATOR]
FROM [AFFILIATOR]
WHERE [CPF_CNPJ] = @CPF_AFF
AND [ACTIVE] = 1;

IF @COD_AFF IS NULL
THROW 66600, 'AFFILIATOR NOT FOUND', 0;

SELECT
	@COD_EC = [COD_EC]
FROM [COMMERCIAL_ESTABLISHMENT]
WHERE [CPF_CNPJ] = @CPF_EC
AND [COD_AFFILIATOR] = @COD_AFF
AND [ACTIVE] = 1;

IF @COD_EC IS NULL
THROW 66601, 'EC NOT FOUND', 0;

SELECT
	[ORDER].[COD_ODR]
   ,[ORDER].[CREATED_AT]
   ,[ORDER].[AMOUNT]
   ,[ORDER].[CODE]
   ,[ORDER].[COD_EC] AS [EC]
   ,[ORDER].[COD_USER]
   ,[ORDER].[COD_SITUATION]
   ,[ORDER].[COD_TRAN]
   ,[ORDER_ADDRESS].[COD_ODR_ADDR]
   ,[ORDER].[COD_ORDER_SIT]
   ,[ORDER_SITUATION].[CODE] AS [ORDER_SIT]
   ,[ORDER_ADDRESS].[CEP]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[NEIGHBORHOOD].[NAME] AS [NEIGH]
   ,[CITY].[NAME] AS [CITY]
   ,State.[UF]
   ,[COUNTRY].[INITIALS]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL]
   ,[EQUIPMENT].[SERIAL] AS 'SITE'
   ,
	--,[ORDER].[AMOUNT]     
	[GENERIC_EC].[COD_EC]
   ,[GENERIC_EC].[USER_ONLINE] AS [USER_ONLINE]
   ,[GENERIC_EC].[PWD_ONLINE] INTO [#PENDENT_ORDER]
FROM [ORDER]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
		AND [ORDER_ADDRESS].[ACTIVE] = 1
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN State
	ON State.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = State.[COD_COUNTRY]
INNER JOIN [COMMERCIAL_ESTABLISHMENT] AS [GENERIC_EC]
	ON [GENERIC_EC].[COD_AFFILIATOR] = @COD_AFF
		AND [GENERIC_EC].[GENERIC_EC] = 1
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
INNER JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH] = [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH]
		AND [ASS_DEPTO_EQUIP].[ACTIVE] = 1
INNER JOIN [EQUIPMENT]
	ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
		AND [EQUIPMENT].[ACTIVE] = 1
WHERE [AMOUNT] = 250
AND [ORDER_SITUATION].[CODE] = 'PAGAMENTO PENDENTE'
AND [COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ] = @CPF_EC
AND [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR] = @COD_AFF
AND DATEDIFF(HOUR, [ORDER].[CREATED_AT], current_timestamp) < 24;

IF (@@rowcount > 0)
BEGIN

SELECT
	*
FROM [#PENDENT_ORDER];

END;
ELSE
BEGIN

SELECT
	@COD_NEIGH_ORDER = [COD_NEIGH]
FROM [NEIGHBORHOOD]
WHERE [COD_NEIGH] = @COD_NEIGH_ORDER;

IF @COD_NEIGH_ORDER IS NULL
THROW 66602, 'NEIGHBORHOOD NOT FOUND', 0;

SELECT
	@COD_USER = [COD_USER]
FROM [USERS]
WHERE [COD_ACCESS] = @ACCESS_USER
AND [ACTIVE] = 1
AND [COD_EC] = @COD_EC;

IF @COD_USER IS NULL
THROW 66603, 'USER NOT FOUND', 0;

INSERT INTO [ORDER] ([CREATED_AT],
[AMOUNT],
[COD_EC],
[COD_USER],
[COD_SITUATION],
[COD_ORDER_SIT],
[COMMENT],
[CODE])
	VALUES (current_timestamp, @AMOUNT, @COD_EC, @COD_USER, 1, 1, NULL, NEXT VALUE FOR [SEQ_ORDERCODE]);

IF @@rowcount < 1
THROW 66604, 'INSERT ORDER ERROR', 0;

SET @COD_ORDER = SCOPE_IDENTITY();

INSERT INTO [ORDER_ADDRESS] ([ADDRESS],
[NUMBER],
[COMPLEMENT],
[CEP],
[COD_NEIGH],
[COD_EC],
[ACTIVE],
[COD_ODR])
	VALUES (@ADDRESS_ORDER, @NUMBER_ORDER, @COMPLEMENT_ORDER, @CEP_ORDER, @COD_NEIGH_ORDER, @COD_EC, 1, @COD_ORDER);

IF @@rowcount < 1
THROW 66605, 'INSERT ORDER ADDRESS ERROR', 0;

INSERT INTO [ORDER_ITEM] ([PRICE],
[QUANTITY],
[COD_ODR],
[CHIP],
[COD_PRODUCT],
[COD_OPERATOR],
[COD_TRANSIRE_PRD])
	SELECT
		[TP].[PRICE]
	   ,[TP].[QUANTITY]
	   ,@COD_ORDER
	   ,[TP].[CHIP]
	   ,[TP].[COD_PR_AFF]
	   ,[CELL_OPERATOR].[COD_OPER]
	   ,[TRANSIRE_PRODUCT].[COD_TRANSIRE_PRD]
	FROM @TP_ORDER_ITEM AS [TP]
	JOIN [CELL_OPERATOR]
		ON [CELL_OPERATOR].[CODE] = [TP].[CELL_OPERATOR]
	JOIN [PRODUCTS]
		ON [PRODUCTS].[COD_PRODUCT] = [TP].[COD_PR_AFF]
	JOIN [TRANSIRE_PRODUCT]
		ON [TRANSIRE_PRODUCT].[SKU] = [PRODUCTS].[SKU]
			AND [TRANSIRE_PRODUCT].[ACTIVE] = 1;


IF @@rowcount < (SELECT
			COUNT(*)
		FROM @TP_ORDER_ITEM)
THROW 66606, 'INSERT ORDER ITEMS ERROR', 0;



SELECT
	[ORDER].[COD_ODR]
   ,[ORDER].[CREATED_AT]
   ,[ORDER].[AMOUNT]
   ,[ORDER].[CODE]
   ,[ORDER].[COD_EC] AS [EC]
   ,[ORDER].[COD_USER]
   ,[ORDER].[COD_SITUATION]
   ,[ORDER].[COD_TRAN]
   ,[ORDER_ADDRESS].[COD_ODR_ADDR]
   ,[ORDER].[COD_ORDER_SIT]
   ,[ORDER_SITUATION].[CODE] AS [ORDER_SIT]
   ,[ORDER_ADDRESS].[CEP]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[NEIGHBORHOOD].[NAME] AS [NEIGH]
   ,[CITY].[NAME] AS [CITY]
   ,State.[UF]
   ,[COUNTRY].[INITIALS]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL]
   ,[EQUIPMENT].[SERIAL] AS 'SITE'
   ,[GENERIC_EC].[COD_EC]
   ,[GENERIC_EC].[USER_ONLINE] AS [USER_ONLINE]
   ,[GENERIC_EC].[PWD_ONLINE]
FROM [ORDER]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
		AND [ORDER_ADDRESS].[ACTIVE] = 1
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN State
	ON State.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = State.[COD_COUNTRY]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
INNER JOIN [COMMERCIAL_ESTABLISHMENT] AS [GENERIC_EC]
	ON [GENERIC_EC].[COD_AFFILIATOR] = @COD_AFF
		AND [GENERIC_EC].[GENERIC_EC] = 1
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_EC] = [GENERIC_EC].[COD_EC]
INNER JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
INNER JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH] = [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH]
		AND [ASS_DEPTO_EQUIP].[ACTIVE] = 1
INNER JOIN [EQUIPMENT]
	ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
		AND [EQUIPMENT].[ACTIVE] = 1
WHERE [ORDER].[COD_ODR] = @COD_ORDER;
END;
END;

GO

 IF OBJECT_ID('SP_UP_ORDER') IS NOT NULL DROP PROCEDURE SP_UP_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_UP_ORDER]                            
              
/*****************************************************************************************************************************  
----------------------------------------------------------------------------------------                           
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                           
    Project.......: TKPP                           
    ------------------------------------------------------------------------------------------                           
    Author                          VERSION        Date                            Description                                  
    ------------------------------------------------------------------------------------------                           
    Lucas Aguiar     V1      2019-10-28         Creation                                 
    ------------------------------------------------------------------------------------------          
*****************************************************************************************************************************/          
                           
(  
 @CODE_ORDER  INT,   
 @ORDER_SIT   VARCHAR(150),   
 @CODE_TRAN   VARCHAR(255)   = NULL,   
 @AMOUNT      DECIMAL(22, 6)  = NULL,   
 @CODE        VARCHAR(128)   = NULL,   
 @COMMENT     VARCHAR(500)   = NULL,   
 @ACCESS_USER VARCHAR(200)   = NULL)  
AS  
BEGIN
  
  
    DECLARE @COD_ODR INT;
  
  
    DECLARE @COD_TRAN INT;
  
  
    DECLARE @COD_SITUATION INT;
  
  
    DECLARE @SIT_ORDER VARCHAR(400);
  
  
    DECLARE @DOCUMENT_TYPE VARCHAR(150);
  
  
    DECLARE @COD_EC INT;
  
  
    DECLARE @EMAIL VARCHAR(255);

SELECT
	@COD_ODR = [COD_ODR]
   ,@SIT_ORDER = [ORDER_SITUATION].[NAME]
   ,@DOCUMENT_TYPE = [COMMERCIAL_ESTABLISHMENT].[DOCUMENT_TYPE]
   ,@COD_EC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,@EMAIL = [COMMERCIAL_ESTABLISHMENT].[EMAIL]
FROM [ORDER_SITUATION]
INNER JOIN [ORDER]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
		AND [ORDER].[CODE] = @CODE_ORDER
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC];

DECLARE @SIT_TRAN INT;
DECLARE @SIT_TRAN_DESC INT;

SELECT
	@COD_SITUATION = [COD_ORDER_SIT]
FROM [ORDER_SITUATION]
WHERE [NAME] = @ORDER_SIT;

IF (@CODE_TRAN IS NULL)
BEGIN
SELECT
	@COD_TRAN = [TRANSACTION].[COD_TRAN]
   ,@SIT_TRAN = [TRANSACTION].[COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [ORDER]
	ON [ORDER].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
WHERE [ORDER].[CODE] = @CODE_ORDER;
END;
IF (@ORDER_SIT = 'PAYMENT MADE')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;
IF (@ORDER_SIT = 'PAYMENT DENIED')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN = 3
THROW 60000, '[TRANSACTION] CAN''T''BE CONFIRM', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PENDING ANALYSIS RISK')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PAYMENT MADE')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'APPROVED AFTER RISK ANALYSIS')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PENDING ANALYSIS RISK')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 2
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'FAILED AFTER RISK ANALYSIS')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PENDING ANALYSIS RISK')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 3
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PREPARING')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PAYMENT MADE')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DELIVERED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'UNDELIVERABLE')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DISPATCHED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;


IF (@ORDER_SIT = 'LOGISTICS UNDER ANALYSIS')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

EXEC [SP_UP_TRACKING_ORDER] @COD_ODR;

SELECT
	[ORDER_SITUATION].[ORDER_SIT_RESUME]
   ,[COMMERCIAL_ESTABLISHMENT].[EMAIL]
   ,[USERS].[IDENTIFICATION]
   ,[ORDER].[CODE]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ORDER_ADDRESS].[CEP]
   ,[CITY].[NAME]
   ,State.[UF]
   ,[COUNTRY].[INITIALS]
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [ORDER]
	ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
INNER JOIN [USERS]
	ON [USERS].[COD_USER] = [ORDER].[COD_USER]
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN State
	ON State.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = State.[COD_COUNTRY]
WHERE [ORDER].[CODE] = @CODE_ORDER;


END;

GO

 IF OBJECT_ID('SP_UP_ORDER') IS NOT NULL DROP PROCEDURE SP_UP_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_UP_ORDER]                            
              
/*****************************************************************************************************************************  
----------------------------------------------------------------------------------------                           
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                           
    Project.......: TKPP                           
    ------------------------------------------------------------------------------------------                           
    Author                          VERSION        Date                            Description                                  
    ------------------------------------------------------------------------------------------                           
    Lucas Aguiar     V1      2019-10-28         Creation                                 
    ------------------------------------------------------------------------------------------          
*****************************************************************************************************************************/          
                           
(  
 @CODE_ORDER  INT,   
 @ORDER_SIT   VARCHAR(150),   
 @CODE_TRAN   VARCHAR(255)   = NULL,   
 @AMOUNT      DECIMAL(22, 6)  = NULL,   
 @CODE        VARCHAR(128)   = NULL,   
 @COMMENT     VARCHAR(500)   = NULL,   
 @ACCESS_USER VARCHAR(200)   = NULL)  
AS  
BEGIN
  
  
    DECLARE @COD_ODR INT;
  
  
    DECLARE @COD_TRAN INT;
  
  
    DECLARE @COD_SITUATION INT;
  
  
    DECLARE @SIT_ORDER VARCHAR(400);
  
  
    DECLARE @DOCUMENT_TYPE VARCHAR(150);
  
  
    DECLARE @COD_EC INT;
  
  
    DECLARE @EMAIL VARCHAR(255);

SELECT
	@COD_ODR = [COD_ODR]
   ,@SIT_ORDER = [ORDER_SITUATION].[NAME]
   ,@DOCUMENT_TYPE = [COMMERCIAL_ESTABLISHMENT].[DOCUMENT_TYPE]
   ,@COD_EC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,@EMAIL = [COMMERCIAL_ESTABLISHMENT].[EMAIL]
FROM [ORDER_SITUATION]
INNER JOIN [ORDER]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
		AND [ORDER].[CODE] = @CODE_ORDER
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC];

DECLARE @SIT_TRAN INT;
DECLARE @SIT_TRAN_DESC INT;

SELECT
	@COD_SITUATION = [COD_ORDER_SIT]
FROM [ORDER_SITUATION]
WHERE [NAME] = @ORDER_SIT;

IF (@CODE_TRAN IS NULL)
BEGIN
SELECT
	@COD_TRAN = [TRANSACTION].[COD_TRAN]
   ,@SIT_TRAN = [TRANSACTION].[COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [ORDER]
	ON [ORDER].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
WHERE [ORDER].[CODE] = @CODE_ORDER;
END;
IF (@ORDER_SIT = 'PAYMENT MADE')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;
IF (@ORDER_SIT = 'PAYMENT DENIED')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN = 3
THROW 60000, '[TRANSACTION] CAN''T''BE CONFIRM', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PENDING ANALYSIS RISK')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PAYMENT MADE')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'APPROVED AFTER RISK ANALYSIS')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PENDING ANALYSIS RISK')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 2
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'FAILED AFTER RISK ANALYSIS')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PENDING ANALYSIS RISK')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 3
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PREPARING')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PAYMENT MADE')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DELIVERED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'UNDELIVERABLE')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DISPATCHED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;


IF (@ORDER_SIT = 'LOGISTICS UNDER ANALYSIS')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

EXEC [SP_UP_TRACKING_ORDER] @COD_ODR;

SELECT
	[ORDER_SITUATION].[ORDER_SIT_RESUME]
   ,[COMMERCIAL_ESTABLISHMENT].[EMAIL]
   ,[USERS].[IDENTIFICATION]
   ,[ORDER].[CODE]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ORDER_ADDRESS].[CEP]
   ,[CITY].[NAME]
   ,STATE.[UF]
   ,[COUNTRY].[INITIALS]
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [ORDER]
	ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
INNER JOIN [USERS]
	ON [USERS].[COD_USER] = [ORDER].[COD_USER]
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN STATE
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
WHERE [ORDER].[CODE] = @CODE_ORDER;


END;

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

 IF OBJECT_ID('SP_UP_RESUME_TRACKING') IS NOT NULL DROP PROCEDURE SP_UP_RESUME_TRACKING;
GO
CREATE PROCEDURE SP_UP_RESUME_TRACKING     (     @COD_ODR INT    )    AS    BEGIN
  
      DECLARE @QUERY NVARCHAR(MAX);
SELECT
	@QUERY = 'UPDATE RESUME_TRACKING SET ' + NAME + ' = 1, DATE_' + NAME + ' = CURRENT_TIMESTAMP WHERE COD_ODR = @COD_ODR'
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.RESUME_TRACKING')
AND NAME LIKE (SELECT
		REPLACE([ORDER_SITUATION].NAME, ' ', '_')
	FROM ORDER_SITUATION
	INNER JOIN [ORDER]
		ON [ORDER].COD_ORDER_SIT = ORDER_SITUATION.COD_ORDER_SIT
		AND [ORDER].COD_ODR = @COD_ODR)
EXEC sp_executesql @QUERY
				  ,N'    @COD_ODR INT'
				  ,@COD_ODR = @COD_ODR
END;

go

 IF OBJECT_ID('SP_UP_ORDER') IS NOT NULL DROP PROCEDURE SP_UP_ORDER;
GO
CREATE PROCEDURE [DBO].[SP_UP_ORDER]                            
              
/*****************************************************************************************************************************  
----------------------------------------------------------------------------------------                           
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                           
    Project.......: TKPP                           
    ------------------------------------------------------------------------------------------                           
    Author                          VERSION        Date                            Description                                  
    ------------------------------------------------------------------------------------------                           
    Lucas Aguiar     V1      2019-10-28         Creation                                 
    ------------------------------------------------------------------------------------------          
*****************************************************************************************************************************/          
                           
(  
 @CODE_ORDER  INT,   
 @ORDER_SIT   VARCHAR(150),   
 @CODE_TRAN   VARCHAR(255)   = NULL,   
 @AMOUNT      DECIMAL(22, 6)  = NULL,   
 @CODE        VARCHAR(128)   = NULL,   
 @COMMENT     VARCHAR(500)   = NULL,   
 @ACCESS_USER VARCHAR(200)   = NULL)  
AS  
BEGIN
  
  
    DECLARE @COD_ODR INT;
  
  
    DECLARE @COD_TRAN INT;
  
  
    DECLARE @COD_SITUATION INT;
  
  
    DECLARE @SIT_ORDER VARCHAR(400);
  
  
    DECLARE @DOCUMENT_TYPE VARCHAR(150);
  
  
    DECLARE @COD_EC INT;
  
  
    DECLARE @EMAIL VARCHAR(255);

SELECT
	@COD_ODR = [COD_ODR]
   ,@SIT_ORDER = [ORDER_SITUATION].[NAME]
   ,@DOCUMENT_TYPE = [COMMERCIAL_ESTABLISHMENT].[DOCUMENT_TYPE]
   ,@COD_EC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
   ,@EMAIL = [COMMERCIAL_ESTABLISHMENT].[EMAIL]
FROM [ORDER_SITUATION]
INNER JOIN [ORDER]
	ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
		AND [ORDER].[CODE] = @CODE_ORDER
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC];

DECLARE @SIT_TRAN INT;
DECLARE @SIT_TRAN_DESC INT;

SELECT
	@COD_SITUATION = [COD_ORDER_SIT]
FROM [ORDER_SITUATION]
WHERE [NAME] = @ORDER_SIT;

IF (@CODE_TRAN IS NULL)
BEGIN
SELECT
	@COD_TRAN = [TRANSACTION].[COD_TRAN]
   ,@SIT_TRAN = [TRANSACTION].[COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [ORDER]
	ON [ORDER].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
WHERE [ORDER].[CODE] = @CODE_ORDER;
END;
IF (@ORDER_SIT = 'PAYMENT MADE')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;
IF (@ORDER_SIT = 'PAYMENT DENIED')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN = 3
THROW 60000, '[TRANSACTION] CAN''T''BE CONFIRM', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PENDING ANALYSIS RISK')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PAYMENT MADE')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'APPROVED AFTER RISK ANALYSIS')
BEGIN

SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PENDING ANALYSIS RISK')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 2
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'FAILED AFTER RISK ANALYSIS')
BEGIN
SELECT
	@COD_TRAN = [COD_TRAN]
   ,@SIT_TRAN = [COD_SITUATION]
FROM [TRANSACTION] WITH (NOLOCK)
WHERE [CODE] = @CODE_TRAN;

IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PENDING ANALYSIS RISK')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [COMMERCIAL_ESTABLISHMENT]
SET [COMMERCIAL_ESTABLISHMENT].[COD_RISK_SITUATION] = [RISK_SITUATION].[COD_RISK_SITUATION]
   ,[ACTIVE] = [RISK_SITUATION].[SITUATION_EC]
   ,[COMMERCIAL_ESTABLISHMENT].[COD_USER_MODIFY] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
   ,[COMMERCIAL_ESTABLISHMENT].[MODIFY_DATE] = current_timestamp
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [RISK_SITUATION]
	ON [RISK_SITUATION].[COD_RISK_SITUATION] = 3
WHERE [COD_EC] = @COD_EC;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
   ,[ORDER].[COD_USER] = (SELECT
			[COD_USER]
		FROM [USERS]
		WHERE [COD_ACCESS] = @ACCESS_USER)
WHERE [ORDER].[COD_ODR] = @COD_ODR;

END;

IF (@ORDER_SIT = 'PREPARING')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

--IF(@SIT_ORDER <> 'PAYMENT MADE')  
--THROW 60000, 'INVALID [ORDER SITUATION]', 1;  

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DELIVERED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'UNDELIVERABLE')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

IF (@ORDER_SIT = 'DISPATCHED')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;


IF (@ORDER_SIT = 'LOGISTICS UNDER ANALYSIS')
BEGIN
IF @SIT_TRAN <> 3
THROW 60000, '[TRANSACTION] NOT CONFIRMED', 1;

UPDATE [ORDER]
SET [ORDER].[COD_ORDER_SIT] = @COD_SITUATION
   ,[ORDER].[COD_TRAN] = ISNULL(@COD_TRAN, [ORDER].[COD_TRAN])
   ,[ORDER].[COMMENT] = @COMMENT
WHERE [ORDER].[COD_ODR] = @COD_ODR;
END;

EXEC [SP_UP_TRACKING_ORDER] @COD_ODR;

SELECT
	[ORDER_SITUATION].[ORDER_SIT_RESUME]
   ,[COMMERCIAL_ESTABLISHMENT].[EMAIL]
   ,[USERS].[IDENTIFICATION]
   ,[ORDER].[CODE]
   ,[ORDER_ADDRESS].[ADDRESS]
   ,[ORDER_ADDRESS].[NUMBER]
   ,[ORDER_ADDRESS].[COMPLEMENT]
   ,[ORDER_ADDRESS].[CEP]
   ,[CITY].[NAME]
   ,STATE.[UF]
   ,[COUNTRY].[INITIALS]
FROM [COMMERCIAL_ESTABLISHMENT]
INNER JOIN [ORDER]
	ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
INNER JOIN [ORDER_SITUATION]
	ON [ORDER_SITUATION].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
INNER JOIN [ORDER_ADDRESS]
	ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR]
INNER JOIN [USERS]
	ON [USERS].[COD_USER] = [ORDER].[COD_USER]
INNER JOIN [NEIGHBORHOOD]
	ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
INNER JOIN [CITY]
	ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
INNER JOIN STATE
	ON STATE.[COD_STATE] = [CITY].[COD_STATE]
INNER JOIN [COUNTRY]
	ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
WHERE [ORDER].[CODE] = @CODE_ORDER;


END;

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

 IF OBJECT_ID('SP_UP_RESUME_TRACKING') IS NOT NULL DROP PROCEDURE SP_UP_RESUME_TRACKING;
GO
CREATE PROCEDURE SP_UP_RESUME_TRACKING     (     @COD_ODR INT    )    AS    BEGIN
  
      DECLARE @QUERY NVARCHAR(MAX);
SELECT
	@QUERY = 'UPDATE RESUME_TRACKING SET ' + NAME + ' = 1, DATE_' + NAME + ' = CURRENT_TIMESTAMP WHERE COD_ODR = @COD_ODR'
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.RESUME_TRACKING')
AND NAME LIKE (SELECT
		REPLACE([ORDER_SITUATION].NAME, ' ', '_')
	FROM ORDER_SITUATION
	INNER JOIN [ORDER]
		ON [ORDER].COD_ORDER_SIT = ORDER_SITUATION.COD_ORDER_SIT
		AND [ORDER].COD_ODR = @COD_ODR)
EXEC sp_executesql @QUERY
				  ,N'    @COD_ODR INT'
				  ,@COD_ODR = @COD_ODR
END;

GO

IF OBJECT_ID('RESUME_TRACKING') IS NOT NULL DROP PROCEDURE RESUME_TRACKING
GO
CREATE TABLE [dbo].[RESUME_TRACKING](
	[COD_RESUME] [int] IDENTITY(1,1) NOT NULL,
	[COD_ODR] [int] NULL,
	[PAYMENT_PENDING] [int] NULL,
	[DATE_PAYMENT_PENDING] [datetime] NULL,
	[PAYMENT_MADE] [int] NULL,
	[DATE_PAYMENT_MADE] [datetime] NULL,
	[PAYMENT_DENIED] [int] NULL,
	[DATE_PAYMENT_DENIED] [datetime] NULL,
	[PENDING_ANALYSIS_RISK] [int] NULL,
	[DATE_PENDING_ANALYSIS_RISK] [datetime] NULL,
	[APPROVED_AFTER_RISK_ANALYSIS] [int] NULL,
	[DATE_APPROVED_AFTER_RISK_ANALYSIS] [datetime] NULL,
	[FAILED_AFTER_RISK_ANALYSIS] [int] NULL,
	[DATE_FAILED_AFTER_RISK_ANALYSIS] [datetime] NULL,
	[PREPARING] [int] NULL,
	[DATE_PREPARING] [datetime] NULL,
	[LOGISTICS_UNDER_ANALYSIS] [int] NULL,
	[DATE_LOGISTICS_UNDER_ANALYSIS] [datetime] NULL,
	[DISPATCHED] [int] NULL,
	[DATE_DISPATCHED] [datetime] NULL,
	[DELIVERED] [int] NULL,
	[DATE_DELIVERED] [datetime] NULL,
	[UNDELIVERABLE] [int] NULL,
	[DATE_UNDELIVERABLE] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_RESUME] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RESUME_TRACKING]  WITH CHECK ADD FOREIGN KEY([COD_ODR])
REFERENCES [dbo].[ORDER] ([COD_ODR])
GO

ALTER TABLE [dbo].[RESUME_TRACKING]  WITH CHECK ADD FOREIGN KEY([COD_ODR])
REFERENCES [dbo].[ORDER] ([COD_ODR])
GO

GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'701', N'Transação Negada', N'Por algum motivo, a transação não foi aprovada. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente utilizar um cartão de crédito diferente', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'001', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'002', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'003', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'004', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'005', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'006', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'007', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'999', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'200', N'Transação Confirmada', N'Pagamento realizado. Agora que seu pedido foi finalizado, você será redirecionado paara a tela de acompanhamento de pedido, onde terá mais detalhes dos processos que serão realizados.', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'201', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'202', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'203', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'204', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'801', N'Condições de pagamento inválidas', N'As condições de pagamento escolhidas são inválidas. Por favor, selecione outra formae tente novamente.', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'802', N'Quantidade de parcelas inválida', N'O valor mínimo por parcela foi excedido. Por favor, selecione um número inferior de parcelas e tente novamente.', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'902', N'Transação Negada', N'Por algum motivo, a transação foi negada. Por favor, tente utilizar um cartão de crédito diferente para finalizar a compra.', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'301', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'302', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'303', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'304', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'305', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'901', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'950', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO
INSERT [dbo].[TRANSACTION_RETURN_CODE] ([COD_TR_CODE], [CODE_GW], [TITLE], [ERROR_DETAIL], [COD_AC], [ACTIVE]) VALUES (NULL, N'951', N'Erro ao realizar transação', N'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema através dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1)
GO

IF OBJECT_ID('SP_GET_DATA_ORDER') IS NOT NULL DROP PROCEDURE SP_GET_DATA_ORDER
GO

CREATE PROCEDURE [DBO].[SP_GET_DATA_ORDER]     /*********************************************************************************************************************  ----------------------------------------------------------------------------------------
                       Procedure Name: [SP_GET_DATA_ORDER]                       Project.......: TKPP                       ------------------------------------------------------------------------------------------                       Author            
              VERSION        Date                            Description                              ------------------------------------------------------------------------------------------                       Lucas Aguiar     V1    2020-01-31       
Creation                             ------------------------------------------------------------------------------------------    *********************************************************************************************************************/    ( 
  @ORDER VARCHAR(255))  AS  BEGIN  
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
 go
 
 
IF OBJECT_ID('SP_FD_ORDERS') IS NOT NULL DROP PROCEDURE SP_FD_ORDERS
GO
CREATE PROCEDURE [DBO].[SP_FD_ORDERS]             /*************************************************************************************************************************  ---------------------------------------------------------------------------------
-------                           Procedure Name: [[SP_LS_DATA_ORDER]]                           Project.......: TKPP                           ------------------------------------------------------------------------------------------                     
      Author                          VERSION        Date                            Description                                  ------------------------------------------------------------------------------------------                           Lucas Ag
uiar     V1    2020-01-31       Creation                                 ------------------------------------------------------------------------------------------        ************************************************************************************
*************************************/            (   @COD_EC       INT,    @ORDER_NUMBER INT = NULL)  AS  BEGIN  
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
 
 IF OBJECT_ID('SP_LS_DELIVERY_ADDRESS') IS NOT NULL DROP PROCEDURE SP_LS_DELIVERY_ADDRESS
GO
CREATE PROCEDURE [SP_LS_DELIVERY_ADDRESS]    
 @COD_EC INT    
AS    
BEGIN  
SELECT TOP 3  
 [ADDITIONAL_ORDER_INFO].[COD_ADD_ORDER]  
   ,[ADDITIONAL_ORDER_INFO].[ADDRESS]  
   ,[ADDITIONAL_ORDER_INFO].[NUMBER]  
   ,[ADDITIONAL_ORDER_INFO].[COMPLEMENT]  
   ,[ADDITIONAL_ORDER_INFO].[REFERENCE]  
   ,[ADDITIONAL_ORDER_INFO].[CEP]  
   ,[ADDITIONAL_ORDER_INFO].[COD_NEIGH]  
   ,[NEIGHBORHOOD].[NAME] AS [NEIGHBORHOOD]  
   ,[CITY].[NAME] AS [CITY]  
   ,STATE.[UF] AS STATE  
   ,[COUNTRY].[NAME] AS [COUNTRY]  
   ,[ADDITIONAL_ORDER_INFO].[ACTUAL]  
FROM [ADDITIONAL_ORDER_INFO]  
JOIN [COMMERCIAL_ESTABLISHMENT]  
 ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ADDITIONAL_ORDER_INFO].[COD_EC]  
  AND [COMMERCIAL_ESTABLISHMENT].[ACTIVE] = 1  
  AND [COMMERCIAL_ESTABLISHMENT].[COD_EC] = @COD_EC  
JOIN [NEIGHBORHOOD]  
 ON [NEIGHBORHOOD].[COD_NEIGH] = [ADDITIONAL_ORDER_INFO].[COD_NEIGH]  
JOIN [CITY]  
 ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]  
JOIN STATE  
 ON STATE.[COD_STATE] = [CITY].[COD_STATE]  
JOIN [COUNTRY]  
 ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]  
WHERE [ADDITIONAL_ORDER_INFO].[ACTIVE] = 1  
UNION  
SELECT  
 ADDRESS_BRANCH.COD_ADDRESS  
   ,ADDRESS_BRANCH.[ADDRESS]  
   ,ADDRESS_BRANCH.[NUMBER]  
   ,ADDRESS_BRANCH.[COMPLEMENT]  
   ,ADDRESS_BRANCH.REFERENCE_POINT  
   ,ADDRESS_BRANCH.[CEP]  
   ,ADDRESS_BRANCH.[COD_NEIGH]  
   ,[NEIGHBORHOOD].[NAME] AS [NEIGHBORHOOD]  
   ,[CITY].[NAME] AS [CITY]  
   ,STATE.[UF] AS STATE  
   ,[COUNTRY].[NAME] AS [COUNTRY]  
   ,ADDRESS_BRANCH.ACTIVE  
FROM ADDRESS_BRANCH  
JOIN BRANCH_EC  
 ON BRANCH_EC.COD_BRANCH = ADDRESS_BRANCH.COD_BRANCH  
JOIN [COMMERCIAL_ESTABLISHMENT]  
 ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = BRANCH_EC.[COD_EC]  
  AND [COMMERCIAL_ESTABLISHMENT].[ACTIVE] = 1  
  AND [COMMERCIAL_ESTABLISHMENT].[COD_EC] = @COD_EC  
JOIN [NEIGHBORHOOD]  
 ON [NEIGHBORHOOD].[COD_NEIGH] = ADDRESS_BRANCH.[COD_NEIGH]  
JOIN [CITY]  
 ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]  
JOIN STATE  
 ON STATE.[COD_STATE] = [CITY].[COD_STATE]  
JOIN [COUNTRY]  
 ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]  
WHERE ADDRESS_BRANCH.[ACTIVE] = 1  
END;

GO

IF OBJECT_ID('ADDITIONAL_ORDER_INFO') IS NOT NULL DROP TABLE ADDITIONAL_ORDER_INFO
GO
CREATE TABLE [dbo].[ADDITIONAL_ORDER_INFO](
	[COD_ADD_ORDER] [int] IDENTITY(1,1) NOT NULL,
	[ADDRESS] [varchar](255) NOT NULL,
	[NUMBER] [varchar](100) NOT NULL,
	[COMPLEMENT] [varchar](255) NULL,
	[REFERENCE] [varchar](255) NULL,
	[CEP] [varchar](10) NOT NULL,
	[COD_NEIGH] [int] NOT NULL,
	[ACTUAL] [int] NULL,
	[ACTIVE] [int] NULL,
	[COD_EC] [int] NOT NULL,
	[CREATED_AT] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_ADD_ORDER] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ADDITIONAL_ORDER_INFO] ADD  DEFAULT ((1)) FOR [ACTUAL]
GO

ALTER TABLE [dbo].[ADDITIONAL_ORDER_INFO] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[ADDITIONAL_ORDER_INFO] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

ALTER TABLE [dbo].[ADDITIONAL_ORDER_INFO]  WITH CHECK ADD FOREIGN KEY([COD_EC])
REFERENCES [dbo].[COMMERCIAL_ESTABLISHMENT] ([COD_EC])
GO

ALTER TABLE [dbo].[ADDITIONAL_ORDER_INFO]  WITH CHECK ADD FOREIGN KEY([COD_NEIGH])
REFERENCES [dbo].[NEIGHBORHOOD] ([COD_NEIGH])
GO


 IF OBJECT_ID('SP_SET_DELIVERY_ADDRESS') IS NOT NULL DROP PROCEDURE SP_SET_DELIVERY_ADDRESS;
GO
CREATE PROCEDURE [SP_SET_DELIVERY_ADDRESS]  
 @COD_EC   INT,  
 @COD_ADDR INT  
AS  
BEGIN

UPDATE [ADDITIONAL_ORDER_INFO]
SET [ACTUAL] = 0
WHERE [COD_EC] = @COD_EC;

UPDATE [ADDITIONAL_ORDER_INFO]
SET [ACTUAL] = 1
WHERE [COD_EC] = @COD_EC
AND [COD_ADD_ORDER] = @COD_ADDR;

END;

GO

IF OBJECT_ID('SP_REG_DELIVERY_ADDRESS') IS NOT NULL DROP PROCEDURE SP_REG_DELIVERY_ADDRESS;
GO
  
CREATE PROCEDURE [SP_REG_DELIVERY_ADDRESS]  
 @COD_EC     INT,  
 @COD_NEIGH  INT,  
 @CEP        VARCHAR(255),  
 @NUMBER     VARCHAR(255),  
 @COMPLEMENT VARCHAR(255) = null,  
 @REFERENCE  VARCHAR(255) = null,  
 @ADDRESS    VARCHAR(255)  
AS  
BEGIN


UPDATE [ADDITIONAL_ORDER_INFO]
SET [ACTUAL] = 0
WHERE [COD_EC] = @COD_EC
AND [ACTIVE] = 1;

IF (SELECT
			COUNT(*)
		FROM [ADDITIONAL_ORDER_INFO]
		WHERE [COD_EC] = @COD_EC
		AND [ACTIVE] = 1)
	>= 3
BEGIN
UPDATE [ADDITIONAL_ORDER_INFO]
SET [ACTIVE] = 0
FROM [ADDITIONAL_ORDER_INFO]
WHERE [ADDITIONAL_ORDER_INFO].[COD_ADD_ORDER] = (SELECT TOP 1
		[ADD_ORDER].[COD_ADD_ORDER]
	FROM [ADDITIONAL_ORDER_INFO] AS [ADD_ORDER]
	WHERE [ACTIVE] = 1
	ORDER BY [ADD_ORDER].[CREATED_AT] DESC);

INSERT INTO [ADDITIONAL_ORDER_INFO] ([ADDRESS],
[NUMBER],
[COMPLEMENT],
[REFERENCE],
[CEP],
[COD_NEIGH],
[ACTUAL],
[ACTIVE],
[COD_EC])
	VALUES (@ADDRESS, @NUMBER, @COMPLEMENT, @REFERENCE, @CEP, @COD_NEIGH, 1, 1, @COD_EC);
END;
ELSE
INSERT INTO [ADDITIONAL_ORDER_INFO] ([ADDRESS],
[NUMBER],
[COMPLEMENT],
[REFERENCE],
[CEP],
[COD_NEIGH],
[ACTUAL],
[ACTIVE],
[COD_EC])
	VALUES (@ADDRESS, @NUMBER, @COMPLEMENT, @REFERENCE, @CEP, @COD_NEIGH, 1, 1, @COD_EC);

END;

GO

IF OBJECT_ID('SP_FD_DATA_NEW_ORDER') IS NOT NULL DROP PROCEDURE SP_FD_DATA_NEW_ORDER 
GO
CREATE PROCEDURE SP_FD_DATA_NEW_ORDER    
(    
 @COD_ACCESS VARCHAR(250)    
)    
AS    
BEGIN  
  
SELECT  
 COMPANY.ACCESS_KEY  
   ,AFFILIATOR.CPF_CNPJ AS AFFILIATOR  
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS COMMERCIAL_ESTABLISHMENT  
   ,USERS.COD_ACCESS AS ACCESSUSER  
   ,NEIGHBORHOOD.NAME AS NEIGH  
   ,CITY.NAME AS CITY  
   ,ADDRESS_BRANCH.ADDRESS AS STREET  
   ,ADDRESS_BRANCH.CEP AS CEP  
   ,ADDRESS_BRANCH.REFERENCE_POINT  
   ,number AS NUMBER_DELIVERY  
   ,STATE.UF AS STATE  
   ,COMPLEMENT  
   ,COUNTRY.NAME AS COUNTRY  
   ,ACCESS_APPAPI.NAME AS ACCESS_APPAPI  
   ,ACCESS_APPAPI.SECRETKEY AS SECRET_KEY  
   ,ACCESS_APPAPI.CLIENT_ID AS CLIENTID  
   ,VW_COMPANY_EC_AFF_BR_DEP_EQUIP.SERIAL  
FROM COMMERCIAL_ESTABLISHMENT  
INNER JOIN AFFILIATOR  
 ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR  
INNER JOIN BRANCH_EC  
 ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
INNER JOIN ADDRESS_BRANCH  
 ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH  
  AND ADDRESS_BRANCH.ACTIVE = 1  
INNER JOIN NEIGHBORHOOD  
 ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH  
INNER JOIN CITY  
 ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY  
INNER JOIN STATE  
 ON STATE.COD_STATE = CITY.COD_STATE  
INNER JOIN COUNTRY  
 ON COUNTRY.COD_COUNTRY = STATE.COD_COUNTRY  
INNER JOIN COMPANY  
 ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP  
INNER JOIN USERS  
 ON USERS.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
INNER JOIN COMMERCIAL_ESTABLISHMENT GENERIC_EC  
 ON GENERIC_EC.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR  
  AND GENERIC_EC.GENERIC_EC = 1  
INNER JOIN VW_COMPANY_EC_AFF_BR_DEP_EQUIP  
 ON VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EC = GENERIC_EC.COD_EC  
INNER JOIN ACCESS_APPAPI  
 ON ACCESS_APPAPI.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR  
  AND ACCESS_APPAPI.COD_COMP = AFFILIATOR.COD_COMP  
WHERE USERS.COD_ACCESS = @COD_ACCESS  
  
END

GO

IF OBJECT_ID('SP_FD_DATA_CUSTOMER') IS NOT NULL DROP PROCEDURE SP_FD_DATA_CUSTOMER
GO
CREATE PROCEDURE [SP_FD_DATA_CUSTOMER] @COD_EC INT  
AS  
BEGIN
SELECT
	[EC].[NAME] AS [NAME]
   ,[SEX_TYPE].[CODE] AS [GENDER]
   ,[CB].[DDD]
   ,[CB].[NUMBER] AS [PHONE]
   ,[EC].[EMAIL]
   ,[EC].[DOCUMENT_TYPE]
   ,[EC].[CPF_CNPJ] AS [DOCUMENT]
   ,[EC].[BIRTHDATE]
   ,AB.ADDRESS AS STREET_EC
   ,AB.NUMBER NUMBER_EC
   ,AB_NEIGH.NAME AS NEIGHBORHOOD_EC
   ,AB_CITY.NAME AS CITY_EC
   ,AB_STATE.UF AS UF_EC
   ,AB_COUNTRY.NAME AS COUNTRY_EC
   ,AB.CEP AS CEP_EC
   ,ADD_ORDER.ADDRESS AS STREET_ORDER
   ,ADD_ORDER.NUMBER AS NUMBER_ORDER
   ,ADD_ORDER_NEIGH.NAME AS NEIGHBORHOOD_ORDER
   ,ADD_ORDER_CITY.NAME AS CITY_ORDER
   ,ADD_ORDER_STATE.UF AS UF_ORDER
   ,ADD_ORDER_COUNTRY.NAME AS COUNTRY_ORDER
   ,ADD_ORDER.CEP AS CEP_ORDER

FROM [COMMERCIAL_ESTABLISHMENT] AS [EC]
JOIN [SEX_TYPE]
	ON [SEX_TYPE].[COD_SEX] = [EC].[COD_SEX]
JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_EC] = [EC].[COD_EC]
JOIN [CONTACT_BRANCH] AS [CB]
	ON [CB].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [CB].[ACTIVE] = 1
JOIN [ADDRESS_BRANCH] AS [AB]
	ON [AB].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		AND [AB].[ACTIVE] = 1
JOIN NEIGHBORHOOD AB_NEIGH
	ON AB_NEIGH.COD_NEIGH = AB.COD_NEIGH
JOIN CITY AB_CITY
	ON AB_CITY.COD_CITY = AB_NEIGH.COD_CITY
JOIN STATE AB_STATE
	ON AB_STATE.COD_STATE = AB_CITY.COD_STATE
JOIN COUNTRY AB_COUNTRY
	ON AB_COUNTRY.COD_COUNTRY = AB_STATE.COD_COUNTRY

JOIN ADDITIONAL_ORDER_INFO ADD_ORDER
	ON ADD_ORDER.COD_EC = EC.COD_EC
		AND ADD_ORDER.ACTIVE = 1
		AND ADD_ORDER.ACTUAL = 1
JOIN NEIGHBORHOOD ADD_ORDER_NEIGH
	ON ADD_ORDER_NEIGH.COD_NEIGH = ADD_ORDER.COD_NEIGH
JOIN CITY ADD_ORDER_CITY
	ON ADD_ORDER_CITY.COD_CITY = ADD_ORDER_NEIGH.COD_CITY
JOIN STATE ADD_ORDER_STATE
	ON ADD_ORDER_STATE.COD_STATE = ADD_ORDER_CITY.COD_STATE
JOIN COUNTRY ADD_ORDER_COUNTRY
	ON ADD_ORDER_COUNTRY.COD_COUNTRY = ADD_ORDER_STATE.COD_COUNTRY
WHERE [EC].[ACTIVE] = 1
AND [EC].[COD_EC] = @COD_EC;
END;

go

IF OBJECT_ID('SP_VERIFY_USER_EMAIL') IS NOT NULL DROP PROCEDURE SP_VERIFY_USER_EMAIL;
GO
CREATE PROCEDURE [DBO].[SP_VERIFY_USER_EMAIL]  
  
    /***********************************************************************************************    
----------------------------------------------------------------------------------------          
Procedure Name: [SP_VERIFY_USER]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author              VERSION        Date      Description          
------------------------------------------------------------------------------------------          
Lucas Aguiar  v1      2019-12-17    validação de usuário       
------------------------------------------------------------------------------------------      
***********************************************************************************************/  
  
    (  
    @EMAIL          VARCHAR(255),  
    @COD_AFFILIATOR INT)  
AS  
BEGIN

SELECT
	COUNT(*) AS [EXIST]
FROM [USERS]
WHERE [EMAIL] = @EMAIL
AND [ACTIVE] = 1
AND [COD_AFFILIATOR] = @COD_AFFILIATOR;
END;

GO

IF OBJECT_ID('SP_VERIFY_USER_ACCESS') IS NOT NULL DROP PROCEDURE SP_VERIFY_USER_ACCESS;
GO
CREATE PROCEDURE [dbo].[SP_VERIFY_USER_ACCESS]  
  
    /*********************************************************************************************      
----------------------------------------------------------------------------------------          
Procedure Name: [SP_VERIFY_USER_ACCESS]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author              VERSION        Date      Description          
------------------------------------------------------------------------------------------          
Lucas Aguiar  v1      2019-12-17    validação de usuário       
------------------------------------------------------------------------------------------      
*********************************************************************************************/  
  
    (  
    @USERNAME VARCHAR(255),  
    @COD_AFFILIATOR VARCHAR(300) = NULL  
)  
AS  
BEGIN

SELECT
	COUNT(*) AS exist
FROM [USERS]
WHERE [COD_ACCESS] = @USERNAME
AND COD_AFFILIATOR = @COD_AFFILIATOR;
END;

GO

CREATE PROCEDURE [dbo].[SP_LS_AFFILIATOR_COMP]                        
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
  AFFILIATOR.OPERATION_AFF,
  ACCESS_APPAPI.NAME AS USER_TOKEN,
  ACCESS_APPAPI.SECRETKEY AS PASS_TOKEN
 FROM AFFILIATOR                         
  INNER JOIN COMPANY ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP                        
  LEFT JOIN THEMES ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR AND THEMES.ACTIVE = 1                
  LEFT JOIN USERS u ON u.COD_USER = AFFILIATOR.COD_USER_CAD                
  LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = AFFILIATOR.COD_SITUATION  
  LEFT JOIN ACCESS_APPAPI ON ACCESS_APPAPI.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR                
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
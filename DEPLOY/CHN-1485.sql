--ET-1341

IF NOT EXISTS (SELECT
		1
	FROM [ITEMS_SERVICES_AVAILABLE_GW]
	WHERE [NAME] = 'BOLETO')
BEGIN
INSERT INTO [ITEMS_SERVICES_AVAILABLE_GW] ([NAME], [DESCRIPTION], COD_ITEM_SERVICE)
	VALUES ('BOLETO', 'Boleto', (SELECT COD_ITEM_SERVICE FROM ITEMS_SERVICES_AVAILABLE WHERE [NAME] = 'BOLETO'));
END
GO

IF OBJECT_ID('SP_GW_UP_SERVICES') IS NOT NULL
DROP PROCEDURE SP_GW_UP_SERVICES;
GO
CREATE PROCEDURE [dbo].[SP_GW_UP_SERVICES]   
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_GW_UP_SERVICES]   
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author    VERSION   Date   Description   
------------------------------------------------------------------------------------------   
Marcus Gall   v1    2020-06-04  Created  
Marcus Gall   v2    2021-02-17  Add PROMOCODE and BOLETO Services
------------------------------------------------------------------------------------------*/   
(  
 @COD_EC INT,   
 @COD_AFFILIATOR INT,  
 @SERVICE_NAME VARCHAR(100),  
 @TAX DECIMAL(22, 6),  
 @ACTIVE INT  
)  
AS   
 DECLARE @COD_ITEM_SERVICE INT;
  
 DECLARE @ONLINE_ACTIVE INT;
  
 DECLARE @HAS_CREDENTIALS INT;
  
 DECLARE @HAS_TRANSACTION_ONLINE INT;
  
 DECLARE @COD_USER INT = NULL;
  
  
BEGIN

-- Busca o id de usuario para fins de resgistros da altera��o        
SELECT
	@COD_USER = COD_USER_INT
FROM ACCESS_APPAPI
WHERE COD_USER_INT IS NOT NULL
AND COD_AFFILIATOR = @COD_AFFILIATOR;

SELECT
	@COD_ITEM_SERVICE = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE [NAME] = @SERVICE_NAME;

/******************************************                    
*************** CREDENTIALS ***************                    
******************************************/
IF @SERVICE_NAME = 'CREDENTIALS'
BEGIN
IF (@ACTIVE = 1)
BEGIN
IF ((SELECT
			COUNT(*)
		FROM COMMERCIAL_ESTABLISHMENT
		WHERE USER_ONLINE IS NULL
		AND COD_EC = @COD_EC)
	> 0)
UPDATE COMMERCIAL_ESTABLISHMENT
SET USER_ONLINE = NEXT VALUE FOR [SEQ_TR_ON_EC]
   ,PWD_ONLINE = CONVERT(VARCHAR(255), NEWID())
   ,HAS_CREDENTIALS = 1
WHERE COD_EC = @COD_EC;
ELSE
UPDATE COMMERCIAL_ESTABLISHMENT
SET HAS_CREDENTIALS = 1
WHERE COD_EC = @COD_EC;
END
ELSE
UPDATE COMMERCIAL_ESTABLISHMENT
SET HAS_CREDENTIALS = 0
WHERE COD_EC = @COD_EC;
END

/******************************************                    
******************* SPOT ******************                    
******************************************/
IF (@SERVICE_NAME = 'SPOT')
BEGIN
IF (@ACTIVE = 1
	AND @COD_AFFILIATOR IS NOT NULL
	AND (SELECT
			COUNT(*)
		FROM SERVICES_AVAILABLE
		WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
		AND COD_AFFILIATOR = @COD_AFFILIATOR
		AND COD_EC IS NULL
		AND ACTIVE = 1)
	<= 0)
THROW 61044, 'Affiliated is not allowed to give advance (SPOT)', 1;

IF (@ACTIVE = 0)
BEGIN
UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = current_timestamp
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (@COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1;

UPDATE COMMERCIAL_ESTABLISHMENT
SET SPOT_TAX = 0
WHERE COD_EC = @COD_EC;
END
ELSE
BEGIN
IF (@COD_AFFILIATOR IS NULL
	AND @TAX <= 0)
THROW 61054, 'A taxa Spot n�o pode ser menor ou igual a Zero ', 1;

UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = current_timestamp
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (@COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1;

INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)
	VALUES (current_timestamp, @COD_USER, @COD_ITEM_SERVICE, NULL, @COD_AFFILIATOR, @COD_EC, 1, NULL);

UPDATE COMMERCIAL_ESTABLISHMENT
SET SPOT_TAX = @TAX
WHERE COD_EC = @COD_EC;
END
END

/******************************************                    
****************** SPLIT ******************                    
******************************************/
IF (@SERVICE_NAME = 'SPLIT')
BEGIN
IF (@ACTIVE = 1)
BEGIN
UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = current_timestamp
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (@COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1;

INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE, COD_OPT_SERV)
	VALUES (current_timestamp, @COD_USER, @COD_ITEM_SERVICE, NULL, @COD_AFFILIATOR, @COD_EC, 1, NULL, (SELECT COD_OPT_SERV FROM OPTIONS_SERVICES WHERE [DESCRIPTION] = 'ALGUNS'));
END
ELSE
BEGIN
UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = current_timestamp
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (@COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1;
END
END

/******************************************                    
************ TRANSACTIONONLINE ************                    
******************************************/
IF @SERVICE_NAME = 'TRANSACTIONONLINE'
BEGIN

SELECT
	@HAS_TRANSACTION_ONLINE = TRANSACTION_ONLINE
   ,@HAS_CREDENTIALS = HAS_CREDENTIALS
FROM COMMERCIAL_ESTABLISHMENT
WHERE COD_EC = @COD_EC;

IF (@HAS_CREDENTIALS = 0)
THROW 61062, 'ENABLING ONLINE TRANSACTION WITHOUT CREDENTIAL SERVICE IS NOT ALLOWED', 1;

IF (@HAS_TRANSACTION_ONLINE = 0
	AND @ACTIVE = 1)
BEGIN
IF ((SELECT
			COUNT(COD_SOURCE_TRAN)
		FROM ASS_TAX_DEPART
		INNER JOIN DEPARTMENTS_BRANCH
			ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH
		INNER JOIN BRANCH_EC
			ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
		INNER JOIN COMMERCIAL_ESTABLISHMENT
			ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
		WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC
		AND ASS_TAX_DEPART.ACTIVE = 1
		AND COD_SOURCE_TRAN = 1)
	= 0)
THROW 61055, 'Para habilitar o servi�o de transa��es online, o EC precisa de um plano compat�vel com o tipo de transa��o.', 1;

IF ((SELECT
			COUNT(*)
		FROM COMMERCIAL_ESTABLISHMENT
		LEFT JOIN AFFILIATOR
			ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
		LEFT JOIN PLAN_TAX_AFFILIATOR
			ON PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
		WHERE COD_EC = @COD_EC
		AND (PLAN_TAX_AFFILIATOR.COD_SOURCE_TRAN = 1
		OR COD_SOURCE_TRAN IS NULL))
	= 0)
THROW 61056, 'Para habilitar o servi�o de transa��es online, o Afiliador precisa de um plano compat�vel com o tipo de transa��o.', 1;

UPDATE COMMERCIAL_ESTABLISHMENT
SET TRANSACTION_ONLINE = 1
WHERE COD_EC = @COD_EC;
END
ELSE
BEGIN
IF (@HAS_TRANSACTION_ONLINE = 1
	AND @ACTIVE = 0)
BEGIN
UPDATE COMMERCIAL_ESTABLISHMENT
SET TRANSACTION_ONLINE = 0
WHERE COD_EC = @COD_EC;
END
END
END

/******************************************                    
**************** TRANSLATE ****************                    
******************************************/
IF @SERVICE_NAME = 'TRANSLATE'
BEGIN
IF (@ACTIVE = 1)
BEGIN
UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = current_timestamp
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (@COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1;

INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)
	VALUES (current_timestamp, @COD_USER, @COD_ITEM_SERVICE, NULL, @COD_AFFILIATOR, @COD_EC, 1, NULL);
END
ELSE
BEGIN
UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = current_timestamp
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (@COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1;
END
END

/******************************************                    
****************** BOLETO *****************                    
******************************************/
IF @SERVICE_NAME = 'BOLETO'
BEGIN
IF (@ACTIVE = 1
	AND @COD_AFFILIATOR IS NOT NULL
	AND (SELECT
			COUNT(*)
		FROM SERVICES_AVAILABLE
		WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
		AND COD_AFFILIATOR = @COD_AFFILIATOR
		AND COD_EC IS NULL
		AND ACTIVE = 1)
	<= 0)
THROW 61044, 'Affiliated is not allowed to give advance (BILLET)', 1;

IF (@ACTIVE = 0)
BEGIN
UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = GETDATE()
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1
UPDATE COMMERCIAL_ESTABLISHMENT
SET BILLET_TAX = 0
WHERE COD_EC = @COD_EC
END
ELSE
BEGIN
IF (@COD_AFFILIATOR IS NULL
	AND @TAX <= 0)
THROW 61054, 'A taxa boleto n�o pode ser menor ou igual a Zero ', 1;

DECLARE @BILLET_TAX_AFF DECIMAL(22, 6);
SELECT TOP 1
	@BILLET_TAX_AFF = ISNULL(BILLET_TAX, 0.0)
FROM AFFILIATOR
WHERE COD_AFFILIATOR = @COD_AFFILIATOR

IF ((SELECT TOP 1
			ISNULL(BILLET_TAX, 0.0)
		FROM AFFILIATOR
		WHERE COD_AFFILIATOR = @COD_AFFILIATOR)
	> @TAX)
THROW 61054, 'A taxa boleto n�o pode ser menor que a do afiliador', 1;

UPDATE SERVICES_AVAILABLE
SET ACTIVE = 0
   ,COD_USER = @COD_USER
   ,MODIFY_DATE = GETDATE()
WHERE COD_ITEM_SERVICE = @COD_ITEM_SERVICE
AND (COD_AFFILIATOR IS NULL
OR COD_AFFILIATOR = @COD_AFFILIATOR)
AND COD_EC = @COD_EC
AND ACTIVE = 1

INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE, SERVICE_AMOUNT)
	VALUES (GETDATE(), @COD_USER, @COD_ITEM_SERVICE, NULL, @COD_AFFILIATOR, @COD_EC, 1, NULL, @TAX)

UPDATE COMMERCIAL_ESTABLISHMENT
SET BILLET_TAX = @TAX
WHERE COD_EC = @COD_EC;
END
END

END
GO

IF OBJECT_ID('SP_GW_LS_SERVICES_AVAILABLE_AFF') IS NOT NULL
DROP PROCEDURE SP_GW_LS_SERVICES_AVAILABLE_AFF;
GO
CREATE PROCEDURE [dbo].[SP_GW_LS_SERVICES_AVAILABLE_AFF]  
/*----------------------------------------------------------------------------------------            
Project.......: TKPP            
Procedure Name: [SP_GW_LS_SERVICES_AVAILABLE_AFF]  
------------------------------------------------------------------------------------------            
Author     VERSION  Date   Description            
------------------------------------------------------------------------------------------            
Marcus Gall    V1   2020-06-03  Creation  
Marcus Gall    V2   2021-02-18  Show Billet Transaction tax
------------------------------------------------------------------------------------------*/  
(        
    @COD_AFF INT        
)        
AS        
BEGIN
     
       
    DECLARE @_SERVICES TABLE (ACTIVE INT, COD_ITEM_SERVICE INT, COD_AFF INT, [NAME] VARCHAR(250), [DESCRIPTION] VARCHAR(250), [TAX] DECIMAL(22, 6));

INSERT INTO @_SERVICES
	SELECT
		SERVICES_AVAILABLE.ACTIVE
	   ,SERVICES_AVAILABLE.COD_ITEM_SERVICE
	   ,SERVICES_AVAILABLE.COD_AFFILIATOR
	   ,ITEMS_SERVICES_AVAILABLE.[NAME]
	   ,ITEMS_SERVICES_AVAILABLE.[DESCRIPTION]
	   ,CASE
			WHEN ITEMS_SERVICES_AVAILABLE.[NAME] = 'SPOT' THEN AFFILIATOR.SPOT_TAX
			WHEN ITEMS_SERVICES_AVAILABLE.[NAME] = 'BOLETO' THEN AFFILIATOR.BILLET_TAX
			ELSE 0
		END AS TAX
	FROM SERVICES_AVAILABLE
	INNER JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = SERVICES_AVAILABLE.COD_AFFILIATOR
	INNER JOIN ITEMS_SERVICES_AVAILABLE
		ON ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE = SERVICES_AVAILABLE.COD_ITEM_SERVICE
	INNER JOIN ITEMS_SERVICES_AVAILABLE_GW
		ON ITEMS_SERVICES_AVAILABLE_GW.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
	WHERE SERVICES_AVAILABLE.COD_AFFILIATOR = @COD_AFF
	AND SERVICES_AVAILABLE.ACTIVE = 1
	AND ITEMS_SERVICES_AVAILABLE.ACTIVE = 1;

IF ((SELECT
			COUNT(*)
		FROM PLAN_TAX_AFFILIATOR
		WHERE ACTIVE = 1
		AND COD_AFFILIATOR = @COD_AFF
		AND COD_SOURCE_TRAN = 1)
	> 0)
BEGIN
INSERT INTO @_SERVICES
	SELECT
		ACTIVE
	   ,COD_ITEM_SERVICE
	   ,@COD_AFF
	   ,[NAME]
	   ,[DESCRIPTION]
	   ,0
	FROM ITEMS_SERVICES_AVAILABLE_GW
	WHERE [NAME] IN ('CREDENTIALS', 'TRANSACTIONONLINE');
END
ELSE
BEGIN
DELETE @_SERVICES
WHERE [NAME] IN ('CREDENTIALS', 'TRANSACTIONONLINE');
END

SELECT DISTINCT
	ACTIVE
   ,COD_ITEM_SERVICE
   ,COD_AFF
   ,[NAME]
   ,[DESCRIPTION]
   ,TAX
FROM @_SERVICES;
END;
GO

IF OBJECT_ID('SP_GW_LS_SERVICES_EC') IS NOT NULL
DROP PROCEDURE SP_GW_LS_SERVICES_EC;
GO
  
CREATE PROCEDURE [dbo].[SP_GW_LS_SERVICES_EC]  
/*----------------------------------------------------------------------------------------            
Project.......: TKPP            
Procedure Name: [SP_GW_LS_SERVICES_EC]  
------------------------------------------------------------------------------------------            
Author			VERSION	Date		Description            
------------------------------------------------------------------------------------------            
Marcus Gall		V1		2020-06-03	Creation  
Marcus Gall		V2		2021-02-18	Handle Promocode service
------------------------------------------------------------------------------------------*/  
(        
    @COD_EC INT        
)        
AS   
 DECLARE @COD_AFFILIATOR INT;
  
 DECLARE @HAS_CREDENTIALS INT;
  
 DECLARE @TRANSACTION_ONLINE INT;
  
   
BEGIN

SELECT
	@COD_AFFILIATOR = COD_AFFILIATOR
   ,@HAS_CREDENTIALS = HAS_CREDENTIALS
   ,@TRANSACTION_ONLINE = TRANSACTION_ONLINE
FROM COMMERCIAL_ESTABLISHMENT
WHERE COD_EC = @COD_EC;

DECLARE @_SERVICES TABLE (
	ACTIVE INT
   ,COD_ITEM_SERVICE INT
   ,COD_AFFILIATOR INT
   ,COD_EC INT
   ,[NAME] VARCHAR(250)
   ,[DESCRIPTION] VARCHAR(250)
   ,[SPOT_TAX] DECIMAL(22, 6)
);

INSERT INTO @_SERVICES
	SELECT
		SERVICES_AVAILABLE.ACTIVE
	   ,SERVICES_AVAILABLE.COD_ITEM_SERVICE
	   ,SERVICES_AVAILABLE.COD_AFFILIATOR
	   ,SERVICES_AVAILABLE.COD_EC
	   ,ITEMS_SERVICES_AVAILABLE.[NAME]
	   ,ITEMS_SERVICES_AVAILABLE.[DESCRIPTION]
	   ,CASE
			WHEN ITEMS_SERVICES_AVAILABLE.[NAME] = 'SPOT' THEN COMMERCIAL_ESTABLISHMENT.SPOT_TAX
			WHEN ITEMS_SERVICES_AVAILABLE.[NAME] = 'BOLETO' THEN COMMERCIAL_ESTABLISHMENT.BILLET_TAX
			ELSE 0
		END AS SPOT_TAX
	FROM SERVICES_AVAILABLE
	INNER JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = SERVICES_AVAILABLE.COD_EC
	INNER JOIN ITEMS_SERVICES_AVAILABLE
		ON ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE = SERVICES_AVAILABLE.COD_ITEM_SERVICE
	INNER JOIN ITEMS_SERVICES_AVAILABLE_GW
		ON ITEMS_SERVICES_AVAILABLE_GW.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
	WHERE SERVICES_AVAILABLE.COD_EC = @COD_EC
	AND ITEMS_SERVICES_AVAILABLE.ACTIVE = 1
	AND SERVICES_AVAILABLE.ACTIVE = 1;

INSERT INTO @_SERVICES
	SELECT
		0
	   ,SERVICES_AVAILABLE.COD_ITEM_SERVICE
	   ,SERVICES_AVAILABLE.COD_AFFILIATOR
	   ,SERVICES_AVAILABLE.COD_EC
	   ,ITEMS_SERVICES_AVAILABLE.[NAME]
	   ,ITEMS_SERVICES_AVAILABLE.[DESCRIPTION]
	   ,CASE
			WHEN ITEMS_SERVICES_AVAILABLE.[NAME] = 'SPOT' THEN AFFILIATOR.SPOT_TAX
			WHEN ITEMS_SERVICES_AVAILABLE.[NAME] = 'BOLETO' THEN AFFILIATOR.BILLET_TAX
			ELSE 0
		END AS TAX
	FROM SERVICES_AVAILABLE
	INNER JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = SERVICES_AVAILABLE.COD_AFFILIATOR
	INNER JOIN ITEMS_SERVICES_AVAILABLE
		ON ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE = SERVICES_AVAILABLE.COD_ITEM_SERVICE
	INNER JOIN ITEMS_SERVICES_AVAILABLE_GW
		ON ITEMS_SERVICES_AVAILABLE_GW.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
	WHERE SERVICES_AVAILABLE.COD_AFFILIATOR = @COD_AFFILIATOR
	AND SERVICES_AVAILABLE.ACTIVE = 1
	AND ITEMS_SERVICES_AVAILABLE.ACTIVE = 1
	AND SERVICES_AVAILABLE.COD_EC IS NULL
	AND SERVICES_AVAILABLE.COD_ITEM_SERVICE NOT IN (SELECT
			COD_ITEM_SERVICE
		FROM @_SERVICES);

IF ((SELECT
			COUNT(*)
		FROM PLAN_TAX_AFFILIATOR
		WHERE ACTIVE = 1
		AND COD_AFFILIATOR = @COD_AFFILIATOR
		AND COD_SOURCE_TRAN = 1)
	> 0)
INSERT INTO @_SERVICES
	SELECT
		ACTIVE
	   ,COD_ITEM_SERVICE
	   ,@COD_AFFILIATOR
	   ,@COD_EC
	   ,[NAME]
	   ,[DESCRIPTION]
	   ,0
	FROM ITEMS_SERVICES_AVAILABLE_GW
	WHERE [NAME] IN ('CREDENTIALS', 'TRANSACTIONONLINE');
ELSE
DELETE @_SERVICES
WHERE [NAME] IN ('CREDENTIALS', 'TRANSACTIONONLINE');

UPDATE @_SERVICES
SET ACTIVE = @HAS_CREDENTIALS
WHERE NAME = 'CREDENTIALS';
UPDATE @_SERVICES
SET ACTIVE = @TRANSACTION_ONLINE
WHERE NAME = 'TRANSACTIONONLINE';
UPDATE @_SERVICES
SET ACTIVE = 1
WHERE NAME = 'PROMOCODE';

SELECT DISTINCT
	ACTIVE
   ,COD_ITEM_SERVICE
   ,COD_AFFILIATOR
   ,COD_EC
   ,[NAME]
   ,[DESCRIPTION]
   ,SPOT_TAX
FROM @_SERVICES;
END
GO

--ET-1341

GO

--ST-1877

GO
 

IF OBJECT_ID('SP_LS_AFFILIATOR_COMP') IS NOT NULL
DROP PROCEDURE [SP_LS_AFFILIATOR_COMP]

GO
  
CREATE PROCEDURE [DBO].[SP_LS_AFFILIATOR_COMP]                                    
            
/*****************************************************************************************************************            
----------------------------------------------------------------------------------------                                    
Procedure Name: SP_LS_AFFILIATOR_COMP                                    
Project.......: TKPP                                    
------------------------------------------------------------------------------------------                                    
Author                          VERSION       Date              Description                                    
------------------------------------------------------------------------------------------                                    
Gian Luca Dalle Cort              V1        01/08/2018            CREATION                             
Luiz Aquino                       V2        01/10/2018            UPDATE                            
Luiz Aquino                       v3        18/12/2018            ADD SPOT_TAX                            
Lucas Aguiar                      v4        01/07/2019            Rotina de bloqueio bancario                     
Caike Uch�a                       v5        26/02/2020            add OperationAff                  
Elir Ribeiro                      v6        16/04/2020           add tax and deadline billet                
Caike Uch�a                       v7        17/04/2020           add busca por cnpj            
Caike Uchoa                       v8        16/09/2020           add correcao billetTax        
Caike uchoa                       v9        21/10/2020           add email      
Caike Uchoa                       v10       10/11/2020           Add Program Manager    
Caio Vitalino                     v11       08/12/2020           Remove the filter active   
Caike Uchoa                       v12       25/02/2021           correcao filtro active
------------------------------------------------------------------------------------------            
*****************************************************************************************************************/            
                                    
(            
 @ACCESS_KEY          VARCHAR(300),             
 @NAME                VARCHAR(100) = NULL,             
 @ACTIVE              INT          = NULL,             
 @CODAFF              INT          = NULL,             
 @WAS_BLOCKED_FINANCE INT          = NULL)            
AS            
BEGIN
    
          
            
            
    DECLARE @QUERY_ NVARCHAR(MAX);
    
          
            
            
    DECLARE @COD_BLOCK_SITUATION INT;
    
          
            
            
    DECLARE @BUSCA VARCHAR(255);




SET @BUSCA = '%' + @NAME + '%';

SELECT
	@COD_BLOCK_SITUATION = [COD_SITUATION]
FROM [SITUATION]
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
  THEMES.SELF_REG_IMG_INITIAL,                            
  THEMES.SELF_REG_IMG_FINAL,                            
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
  COMPANY_DOMAIN.DOMAIN,          
  (        
  SELECT TOP 1 SERVICE_AMOUNT FROM SERVICES_AVAILABLE        
  WHERE COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR        
  AND ACTIVE = 1        
  AND COD_EC IS NULL         
  AND COD_ITEM_SERVICE = 11        
  ) AS [billet_tax],      
 AFFILIATOR_CONTACT.MAIL AS EMAIL,    
 AFFILIATOR.PROGRAM_MANAGER     
 FROM AFFILIATOR                                     
  INNER JOIN COMPANY ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP           
  JOIN COMPANY_DOMAIN ON COMPANY_DOMAIN.COD_COMP = COMPANY.COD_COMP AND COMPANY_DOMAIN.ACTIVE = 1          
  LEFT JOIN THEMES ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR AND THEMES.ACTIVE = 1                            
  LEFT JOIN USERS u ON u.COD_USER = AFFILIATOR.COD_USER_CAD                            
  LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = AFFILIATOR.COD_SITUATION             
  LEFT JOIN AFFILIATOR_CONTACT ON AFFILIATOR_CONTACT.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
  AND AFFILIATOR_CONTACT.ACTIVE =1      
 WHERE COMPANY.ACCESS_KEY = @ACCESS_KEY';
    


  IF @ACTIVE IS NOT NULL
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.ACTIVE = @ACTIVE';

IF @NAME IS NOT NULL
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.NAME LIKE @BUSCA OR AFFILIATOR.CPF_CNPJ LIKE @BUSCA';

IF (@CODAFF IS NOT NULL)
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_AFFILIATOR = @CodAff ';

IF @WAS_BLOCKED_FINANCE = 1
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_SITUATION = @COD_BLOCK_SITUATION ';
ELSE
IF @WAS_BLOCKED_FINANCE = 0
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_SITUATION <> @COD_BLOCK_SITUATION';


EXEC [sp_executesql] @QUERY_
					,N'                              
  @ACCESS_KEY VARCHAR(300),                            
  @Name VARCHAR(100) ,                            
  @ACTIVE INT,                            
  @CodAff INT,                            
  @COD_BLOCK_SITUATION INT,                          
  @BUSCA VARCHAR(255)                          
  '
					,@ACCESS_KEY = @ACCESS_KEY
					,@NAME = @NAME
					,@ACTIVE = @ACTIVE
					,@CODAFF = @CODAFF
					,@COD_BLOCK_SITUATION = @COD_BLOCK_SITUATION
					,@BUSCA = @BUSCA;



END;

--ST-1877

GO

--ST-1863

GO

IF OBJECT_ID('SP_ALLOCATE_IN_LOT_TARIFF') IS NOT NULL
DROP PROCEDURE [SP_ALLOCATE_IN_LOT_TARIFF]

GO

IF TYPE_ID('TARIFF_EC_IN_LOT') IS NOT NULL
DROP TYPE TARIFF_EC_IN_LOT;

GO
CREATE TYPE TARIFF_EC_IN_LOT AS TABLE(
COD_TTARIFF INT NOT NULL,
COD_EC INT NOT NULL,
[VALUE] DECIMAL(22,6) NOT NULL,
PAYMENT_DAY DATETIME NOT NULL,
PLOTS INT NOT NULL,
[TYPE] VARCHAR(100) NOT NULL,
[COMMENT] VARCHAR(300) NULL
)

GO

CREATE PROCEDURE [SP_ALLOCATE_IN_LOT_TARIFF]            
/*----------------------------------------------------------------------------------------                    
Procedure Name: SP_ALLOCATE_IN_LOT_TARIFF                    
Project.......: TKPP                    
------------------------------------------------------------------------------------------                    
Author          VERSION        Date                            Description                    
------------------------------------------------------------------------------------------                    
Elir Ribeiro      V1        18/01/2021             Creation        ADD IN LOT TARIFF BY EC            
Elir Ribeiro      v2        22-01-2021                    add rule payment day    
Caike Uchoa       v3        09-02-2021                    alter lan�amento de tarifa anual 
Caike Uch�a       v4        19-02-2021                        change all procedure logic
------------------------------------------------------------------------------------------*/       
(
@TARIFF_EC_IN_LOT dbo.[TARIFF_EC_IN_LOT] READONLY,
@COD_USER INT
)
AS
BEGIN

DECLARE @COD_TTARIFF INT;
DECLARE @COD_EC INT;
DECLARE @VALUE DECIMAL(22,6);
DECLARE @PAYMENT_DAY DATETIME;
DECLARE @PLOTS INT;
DECLARE @TYPE VARCHAR(100);
DECLARE @CONT INT;
DECLARE @PAYDAY DATETIME;
    
DECLARE @INTERVAL INT;
    
DECLARE @COMMENT VARCHAR(300);
DECLARE @PERIOD_VALUE DECIMAL(22,6);


DECLARE INSERT_TARIFF CURSOR
FOR SELECT
	COD_TTARIFF
   ,COD_EC
   ,[VALUE]
   ,PAYMENT_DAY
   ,PLOTS
   ,[TYPE]
   ,COMMENT
FROM @TARIFF_EC_IN_LOT


OPEN INSERT_TARIFF

FETCH NEXT FROM INSERT_TARIFF
INTO @COD_TTARIFF,
@COD_EC,
@VALUE,
@PAYMENT_DAY,
@PLOTS,
@TYPE,
@COMMENT;

WHILE @@FETCH_STATUS = 0
BEGIN

IF (UPPER(@TYPE) = 'MENSAL')
SET @INTERVAL = 30;
ELSE
IF (UPPER(@TYPE) = 'ANUAL')
SET @INTERVAL = 365;


SET @PERIOD_VALUE = (@VALUE / @PLOTS)
SET @PAYDAY = dbo.FN_FUS_UTF(@PAYMENT_DAY);
SET @CONT = 0

WHILE @CONT < @PLOTS
BEGIN

INSERT INTO TARIFF_EC (COD_USER, [VALUE], ACTIVE, COD_TTARIFF, COD_EC, PLOT, COD_SITUATION, PAYMENT_DAY, COMMENT)
	VALUES (@COD_USER, (-@PERIOD_VALUE), 1, @COD_TTARIFF, @COD_EC, (@CONT + 1), 4, @PAYDAY, @COMMENT)


SET @PAYDAY = DATEADD(DAY, @INTERVAL, @PAYDAY);

SET @CONT = @CONT + 1;

END


INSERT INTO PROCESSING_QUEUE (COD_EC)
	VALUES (@COD_EC)


FETCH NEXT FROM INSERT_TARIFF
INTO @COD_TTARIFF,
@COD_EC,
@VALUE,
@PAYMENT_DAY,
@PLOTS,
@TYPE,
@COMMENT;
END

CLOSE INSERT_TARIFF
DEALLOCATE INSERT_TARIFF



END


GO

IF OBJECT_ID('SP_TARIFF_IN_LOT_VALIDATE') IS NOT NULL
DROP PROCEDURE [SP_TARIFF_IN_LOT_VALIDATE]

GO

IF TYPE_ID('TARIFF_EC_IN_LOT_VALIDATE') IS NOT NULL
DROP TYPE TARIFF_EC_IN_LOT_VALIDATE;

GO
CREATE TYPE TARIFF_EC_IN_LOT_VALIDATE AS TABLE(
NAME_TARIFF VARCHAR(100) NOT NULL,
CPF_CNPJ_EC VARCHAR(100) NOT NULL,
[VALUE] DECIMAL(22,2) NOT NULL,
PAYMENT_DAY DATETIME NOT NULL,
PLOTS INT NOT NULL,
[TYPE] VARCHAR(100) NOT NULL,
[COMMENT] VARCHAR(300) NULL
)

GO

CREATE PROCEDURE [SP_TARIFF_IN_LOT_VALIDATE]
/*----------------------------------------------------------------------------------------                    
Procedure Name: [SP_TARIFF_IN_LOT_VALIDATE]                    
Project.......: TKPP                    
------------------------------------------------------------------------------------------                    
Author          VERSION        Date                            Description                    
------------------------------------------------------------------------------------------                    
Caike Uch�a       v4        19-02-2021                             CREATE
------------------------------------------------------------------------------------------*/       
(
@TARIFF_EC_IN_LOT_VALIDATE dbo.[TARIFF_EC_IN_LOT_VALIDATE] READONLY,
@COD_AFFILIATOR INT
)
AS
BEGIN
 



CREATE TABLE #ERRORS (  
    TARIFF_NAME VARCHAR(100),
    CPF_CNPJ_EC VARCHAR(100),
    [VALUE] DECIMAL(22,2),
    PAYMENT_DAY DATETIME,
    PLOTS INT,
    [TYPE] VARCHAR(100),
	COMMENT VARCHAR(300),
    [REASON] VARCHAR(100),
	QTD_DUPLICATED INT
 )

INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'CPF/CNPJ Inv�lido'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	LEFT JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = ITEM.CPF_CNPJ_EC
	WHERE COMMERCIAL_ESTABLISHMENT.CPF_CNPJ IS NULL



INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Estabelecimento Inativo'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = ITEM.CPF_CNPJ_EC
	WHERE COMMERCIAL_ESTABLISHMENT.ACTIVE = 0

INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Afiliador Inativo'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = ITEM.CPF_CNPJ_EC
	JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	WHERE AFFILIATOR.ACTIVE = 0


INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Estabelecimento invalido para o afiliador'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = ITEM.CPF_CNPJ_EC
	WHERE COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR <> @COD_AFFILIATOR


INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Nome da Tarifa Inv�lido'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	LEFT JOIN TYPE_TARIFF
		ON UPPER(TYPE_TARIFF.[NAME]) = UPPER(ITEM.NAME_TARIFF)
	WHERE TYPE_TARIFF.[NAME] IS NULL



INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Tarifa inativa ou inv�lida para o afiliador'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	LEFT JOIN TYPE_TARIFF
		ON UPPER(TYPE_TARIFF.[NAME]) = UPPER(ITEM.NAME_TARIFF)
			AND TYPE_TARIFF.ACTIVE = 1
			AND TYPE_TARIFF.COD_AFFILIATOR = @COD_AFFILIATOR
	WHERE TYPE_TARIFF.[NAME] IS NULL


INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Valor da Tarifa inv�lido'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN TYPE_TARIFF
		ON TYPE_TARIFF.[NAME] = ITEM.NAME_TARIFF
			AND TYPE_TARIFF.COD_AFFILIATOR = @COD_AFFILIATOR
			AND TYPE_TARIFF.ACTIVE = 1
	WHERE ITEM.[VALUE] <> TYPE_TARIFF.AMOUNT


INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Tipo de Tarifa inv�lido'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN TYPE_TARIFF
		ON TYPE_TARIFF.[NAME] = ITEM.NAME_TARIFF
			AND TYPE_TARIFF.COD_AFFILIATOR = @COD_AFFILIATOR
			AND TYPE_TARIFF.ACTIVE = 1
	WHERE UPPER(ITEM.[TYPE]) <> UPPER(TYPE_TARIFF.[TYPE])


INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Parcela da Tarifa inv�lida'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN TYPE_TARIFF
		ON TYPE_TARIFF.[NAME] = ITEM.NAME_TARIFF
			AND TYPE_TARIFF.COD_AFFILIATOR = @COD_AFFILIATOR
			AND TYPE_TARIFF.ACTIVE = 1
	WHERE ITEM.PLOTS <> TYPE_TARIFF.QTY_PLOTS

INSERT INTO #ERRORS
	SELECT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'O coment�rio n�o pode ultrapassar 300 caracteres'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	WHERE LEN(ITEM.COMMENT) > 300

INSERT INTO #ERRORS
	SELECT
		TYPE_TARIFF.[NAME]
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'A Data de Lan�amento deve ser maior ou igual a ' + CONVERT(VARCHAR(10), dbo.FN_FUS_UTF(GETDATE()), 103)
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN TYPE_TARIFF
		ON TYPE_TARIFF.[NAME] = ITEM.NAME_TARIFF
			AND TYPE_TARIFF.ACTIVE = 1
			AND TYPE_TARIFF.COD_AFFILIATOR = @COD_AFFILIATOR
	WHERE CAST(ITEM.PAYMENT_DAY AS DATE) < CAST(dbo.FN_FUS_UTF(GETDATE()) AS DATE)


INSERT INTO #ERRORS
	SELECT DISTINCT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'Tarifa duplicada: ' + CAST(COUNT(ITEM.NAME_TARIFF) AS VARCHAR(100)) + ' vez(es)'
	   ,COUNT(*)
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	GROUP BY ITEM.NAME_TARIFF
			,ITEM.CPF_CNPJ_EC
			,ITEM.[VALUE]
			,ITEM.PAYMENT_DAY
			,ITEM.PLOTS
			,ITEM.[TYPE]
			,ITEM.COMMENT
	HAVING COUNT(*) > 1



INSERT INTO #ERRORS
	SELECT DISTINCT
		ITEM.NAME_TARIFF
	   ,ITEM.CPF_CNPJ_EC
	   ,ITEM.[VALUE]
	   ,ITEM.PAYMENT_DAY
	   ,ITEM.PLOTS
	   ,ITEM.[TYPE]
	   ,ITEM.COMMENT
	   ,'J� existe uma tarifa lan�ada para este Estabelecimento, data, parcela, tipo e valor'
	   ,0
	FROM @TARIFF_EC_IN_LOT_VALIDATE ITEM
	JOIN TYPE_TARIFF
		ON TYPE_TARIFF.[NAME] = ITEM.NAME_TARIFF
			AND TYPE_TARIFF.ACTIVE = 1
			AND TYPE_TARIFF.COD_AFFILIATOR = @COD_AFFILIATOR
	JOIN TARIFF_EC
		ON TARIFF_EC.COD_TTARIFF = TYPE_TARIFF.COD_TTARIFF
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = ITEM.CPF_CNPJ_EC
			AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFFILIATOR
	WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = TARIFF_EC.COD_EC
	AND (-ITEM.[VALUE]) = CAST(TARIFF_EC.[VALUE] AS DECIMAL(22, 2))
	AND ITEM.[TYPE] = TYPE_TARIFF.[TYPE]
	AND CAST(ITEM.PAYMENT_DAY AS DATE) = CAST(TARIFF_EC.PAYMENT_DAY AS DATE)
	AND ITEM.PLOTS = TYPE_TARIFF.QTY_PLOTS



SELECT
	TARIFF_NAME
   ,CPF_CNPJ_EC
   ,[VALUE]
   ,PAYMENT_DAY
   ,PLOTS
   ,[TYPE]
   ,COMMENT
   ,REASON
FROM #ERRORS


END


GO

IF OBJECT_ID('SP_REG_TYPE_TARIFF') IS NOT NULL
DROP PROCEDURE [SP_REG_TYPE_TARIFF]

GO
  
create PROCEDURE [dbo].[SP_REG_TYPE_TARIFF]  
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_REG_TYPE_TARIFF]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author                          VERSION        Date                            Description    
------------------------------------------------------------------------------------------    
Kennedy Alef                       V1       27/07/2018                        Creation    
Elir Ribeiro                       v2       04/08/2020                    add cod_affiliator    
Caike Uchoa                        v3       19/02/2021                       alter cod_aff
------------------------------------------------------------------------------------------*/  
(  
    @NAME VARCHAR(100),  
    @TYPE VARCHAR(20),  
    @PLOT INT,  
    @CODUSER INT,  
    @CODCOMP INT,  
    @AMOUNT DECIMAL(14,2),  
    @COD_REQ INT = NULL,  
    @COD_SIT INT = NULL,  
    @COD_AFF INT = NULL  
)  
AS  
DECLARE @CONT INT=0;
  
BEGIN

SELECT
	@CONT = COUNT(*)
FROM TYPE_TARIFF
WHERE NAME = @NAME
AND QTY_PLOTS = @PLOT
AND COD_AFFILIATOR = @COD_AFF

IF @CONT > 0
THROW 61032, 'TYPE_TARIFF ALREADY ', 1;

INSERT INTO TYPE_TARIFF (NAME, TYPE, QTY_PLOTS, COD_USER, COD_COMP, AMOUNT, COD_REQ, COD_SITUATION, COD_AFFILIATOR)
	VALUES (@NAME, @TYPE, @PLOT, @CODUSER, @CODCOMP, @AMOUNT, @COD_REQ, @COD_SIT, @COD_AFF)

IF @@ROWCOUNT < 1

THROW 60000, 'COULD NOT REGISTER TYPE_TARIFF ', 1

END;


GO


IF( SELECT
		COUNT(*)
	FROM sys.objects
	WHERE type = 'UQ'
	AND OBJECT_NAME(parent_object_id) = N'TYPE_TARIFF')
> 0
-- Delete the unique constraint.  
BEGIN

ALTER TABLE TYPE_TARIFF
DROP CONSTRAINT UQ_NAME_TYPE_TARIFF;

END

GO

IF OBJECT_ID('SP_LS_TYPE_TARIFF') IS NOT NULL
DROP PROCEDURE [SP_LS_TYPE_TARIFF]

GO
CREATE PROCEDURE [dbo].[SP_LS_TYPE_TARIFF]      
/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_LS_TYPE_TARIFF]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Kennedy Alef                      V1         27/07/2018                         Creation        
Elir Ribeiro                      v2         04/08/2020                    add name is tariff      
Caike Uchoa                       v3         25/02/2021                  add company an affiliator
------------------------------------------------------------------------------------------*/      
( @COD_COMP INT,      
  @COD_AFF INT = NULL  
  ,@NAME VARCHAR(200) = NULL,  
  @TYPE_TARIFF VARCHAR(100) = NULL,
  @COD_TTARIFF INT = NULL
 )      
AS      
      
BEGIN
      
    DECLARE @QUERY  NVARCHAR(MAX)
SET @QUERY = '      
SELECT         
COD_TTARIFF,        
TYPE_TARIFF.NAME,        
TYPE,        
QTY_PLOTS,        
AMOUNT,
ISNULL(AFFILIATOR.[NAME],COMPANY.[NAME]) AS AFFILIATOR,
CASE 
WHEN AFFILIATOR.COD_AFFILIATOR IS NOT NULL THEN TYPE_TARIFF.[NAME] + '' - '' + AFFILIATOR.[NAME]
ELSE TYPE_TARIFF.[NAME] + '' - '' +COMPANY.[NAME]
END AS NAME_TARRIFF_AFF
 FROM TYPE_TARIFF  
 LEFT JOIN AFFILIATOR
  ON AFFILIATOR.COD_AFFILIATOR = TYPE_TARIFF.COD_AFFILIATOR
 JOIN COMPANY 
  ON COMPANY.COD_COMP =TYPE_TARIFF.COD_COMP
WHERE TYPE_TARIFF.ACTIVE = 1        
AND TYPE_TARIFF.COD_COMP = @COD_COMP'
      
    IF @COD_AFF IS NOT NULL
SET @QUERY = @QUERY + ' AND AFFILIATOR.COD_AFFILIATOR = @COD_AFF'
      
      
 IF @NAME IS NOT NULL
SET @QUERY = @QUERY + ' AND TYPE_TARIFF.NAME = @NAME'
     
  
  IF @TYPE_TARIFF IS NOT NULL
SET @QUERY = @QUERY + ' AND TYPE_TARIFF.TYPE = @TYPE_TARIFF'
     

  IF @COD_TTARIFF IS NOT NULL
SET @QUERY = @QUERY + ' AND TYPE_TARIFF.COD_TTARIFF = @COD_TTARIFF'


EXEC sp_executesql @QUERY
				  ,N'         
         @COD_AFF INT,         
         @COD_COMP INT  
   ,@NAME VARCHAR(200)  
   ,@TYPE_TARIFF VARCHAR(100) 
   ,@COD_TTARIFF INT
         '
				  ,@COD_AFF = @COD_AFF
				  ,@COD_COMP = @COD_COMP
				  ,@NAME = @NAME
				  ,@TYPE_TARIFF = @TYPE_TARIFF
				  ,@COD_TTARIFF = @COD_TTARIFF
END




GO

IF OBJECT_ID('SP_UP_TYPE_TARIFF') IS NOT NULL
DROP PROCEDURE [SP_UP_TYPE_TARIFF]

GO
CREATE PROCEDURE SP_UP_TYPE_TARIFF
/*----------------------------------------------------------------------------------------  
    Procedure Name: [SP_UP_TYPE_TARIFF]            
    Project.......: TKPP      
------------------------------------------------------------------------------------------  
    Author          VERSION            Date               Description  
------------------------------------------------------------------------------------------  
   Caike Uchoa          v1           2021-03-01            CREATED  
***************************************************************************************************/  
(
@COD_TARIFF INT,
@COD_USER INT,
@PLOTS INT,
@TYPE VARCHAR(100),
@AMOUNT DECIMAL(14,2),
@NAME VARCHAR(100)
)
AS 
BEGIN


UPDATE TYPE_TARIFF
SET [NAME] = @NAME
   ,QTY_PLOTS = @PLOTS
   ,[TYPE] = @TYPE
   ,AMOUNT = @AMOUNT
   ,COD_USER_ALT = @COD_USER
   ,MODIFY_DATE = GETDATE()
WHERE COD_TTARIFF = @COD_TARIFF

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE TYPE_TARIFF', 1



END

GO

--ST-1863

GO

--ST-1891

IF OBJECT_ID('SP_LOAD_TABLES_EQUIP') IS NOT NULL
DROP PROCEDURE SP_LOAD_TABLES_EQUIP;
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

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE
, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
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

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE
, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
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

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE
, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
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

INSERT INTO #ROUTES_TERMINAL (ACQUIRER_NAME, PRODUCT_ID, PRODUCT_NAME, PRODUCT_EXT_CODE, TRAN_TYPE, TRAN_TYPE_NAME, CODE_EC_ACQ, BRAND, CONF_TYPE
, IS_SIMULATED, DATE_PLAN, COD_AC, COD_BRAND, DEBIT, CREDIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_DEBIT, CLIENT_CREDIT, ONLINE, PRESENTIAL, RATE_FREE)
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

-- BLOQUEAR TAXAS AO CLIENTE PARA O MODELO S500
IF EXISTS (SELECT
			COD_MODEL
		FROM EQUIPMENT_MODEL
		WHERE COD_MODEL = @EQUIP_MODEL
		AND CODIGO = 'S500')
INSERT INTO #TERMINAL_FILTER (COD_AC, COD_MODEL, COD_BRAND, ONLINE, PRESENTIAL, CREDIT, DEBIT, CREDIT_INSTALLMENTS, CLIENT_INSTALLMENT, CLIENT_CREDIT, CLIENT_DEBIT, RATE_FREE)
	VALUES (NULL, @EQUIP_MODEL, NULL, 0, 0, NULL, NULL, NULL, 1, 1, 1, NULL)

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

--ST-1891

GO

--ST-1899

IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'CARD_HOLDER_DOC'
	AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS'))
BEGIN
ALTER TABLE REPORT_TRANSACTIONS
ADD CARD_HOLDER_DOC VARCHAR(100)
END

GO

IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'CARD_HOLDER_DOC'
	AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS_EXP'))
BEGIN
ALTER TABLE REPORT_TRANSACTIONS_EXP
ADD CARD_HOLDER_DOC VARCHAR(100)
END


GO

IF OBJECT_ID('VW_REPORT_TRANSACTIONS_PRCS') IS NOT NULL
DROP VIEW [VW_REPORT_TRANSACTIONS_PRCS]

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
Caike Uchôa                       v5         17-02-2021                        Add e-mail
Caike Uchoa                       v6         02-03-2021                        add card_holder_doc and alter email
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
   ,ISNULL([TRANSACTION].[CUSTOMER_EMAIL], (SELECT
			[VALUE]
		FROM TRANSACTION_DATA_EXT
		WHERE COD_TRAN = [TRANSACTION].COD_TRAN
		AND [NAME] = 'EMAIL')
	) AS CUSTOMER_EMAIL
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
   ,[TRANSACTION].CARD_HOLDER_DOC
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

IF OBJECT_ID('SP_REG_REPORT_TRANSACTIONS_PRCS') IS NOT NULL
DROP PROCEDURE [SP_REG_REPORT_TRANSACTIONS_PRCS]

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
   ,[VW_REPORT_TRANSACTIONS_PRCS].TERMINAL_VERSION
   ,[VW_REPORT_TRANSACTIONS_PRCS].CARD_HOLDER_DOC INTO [#TB_REPORT_TRANSACTIONS_PRCS_INSERT]
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
TERMINAL_VERSION,
CARD_HOLDER_DOC)
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
	   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].CARD_HOLDER_DOC
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
IF OBJECT_ID('SP_REPORT_TRANSACTIONS_PAGE') IS NOT NULL
DROP PROCEDURE [SP_REPORT_TRANSACTIONS_PAGE]

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
Caike Uchôa                        v6        17-02-2021                         Add e-mail
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
@TERMINAL_VERSION VARCHAR(200) = NULL,    
@EMAIL VARCHAR(100) = NULL    
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
 REPORT_TRANSACTIONS.TERMINAL_VERSION,    
 [REPORT_TRANSACTIONS].EMAIL    
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

IF @EMAIL IS NOT NULL
SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].CUSTOMER_EMAIL = @EMAIL ');


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
   @TERMINAL_VERSION VARCHAR(200),    
   @EMAIL VARCHAR(100)      
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
					,@TERMINAL_VERSION = @TERMINAL_VERSION
					,@EMAIL = @EMAIL;


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
   @TERMINAL_VERSION VARCHAR(200),    
   @EMAIL VARCHAR(100)    
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
					,@TERMINAL_VERSION = @TERMINAL_VERSION
					,@EMAIL = @EMAIL;

END;
END;


GO

IF OBJECT_ID('VW_REPORT_TRANSACTIONS_EXP') IS NOT NULL
DROP VIEW [VW_REPORT_TRANSACTIONS_EXP]

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
Caike Uchôa                v12      17-02-2021             Add e-mail
Caike Uchoa                v13      02-03-2021             add card_holder_doc and alter email
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
	   ,ISNULL([TRANSACTION].[CUSTOMER_EMAIL], (SELECT
				[VALUE]
			FROM TRANSACTION_DATA_EXT
			WHERE COD_TRAN = [TRANSACTION].COD_TRAN
			AND [NAME] = 'EMAIL')
		) AS CUSTOMER_EMAIL
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
		--  ,(SELECT TOP 1
		--		SERVICE_TAX_AFF
		--	FROM TRANSACTION_SERVICES TS (NOLOCK)
		--	JOIN ITEMS_SERVICES_AVAILABLE I
		--		ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
		--		AND I.NAME = 'PIX'
		--	WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		--AS [PIX_TAX_AFF]
		--  ,(SELECT TOP 1
		--		TAX_TYPE_AFF
		--	FROM TRANSACTION_SERVICES TS (NOLOCK)
		--	JOIN ITEMS_SERVICES_AVAILABLE I
		--		ON TS.COD_ITEM_SERVICE = I.COD_ITEM_SERVICE
		--		AND I.NAME = 'PIX'
		--	WHERE TS.COD_TRAN = [TRANSACTION].COD_TRAN)
		--AS [PIX_TAX_TYPE_AFF]
	   ,[TRANSACTION].TERMINAL_VERSION
	   ,[TRANSACTION].CARD_HOLDER_DOC
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
	--,CTE.PIX_TAX_AFF
	--,CTE.PIX_TAX_TYPE_AFF
   ,CTE.CARD_HOLDER_DOC
FROM CTE



GO

IF OBJECT_ID('SP_REG_REPORT_TRANSACTIONS_EXP') IS NOT NULL
DROP PROCEDURE [SP_REG_REPORT_TRANSACTIONS_EXP]

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
 Caike uchoa                      v11      02/03/2021                        add card_holder_doc and alter email
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
   ,VW_REPORT_TRANSACTIONS_EXP.TERMINAL_VERSION
	--,[VW_REPORT_TRANSACTIONS_EXP].PIX_TAX_AFF
	--,[VW_REPORT_TRANSACTIONS_EXP].PIX_TAX_TYPE_AFF
   ,[VW_REPORT_TRANSACTIONS_EXP].CARD_HOLDER_DOC INTO #TB_REPORT_TRANSACTIONS_EXP_INSERT
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
TERMINAL_VERSION,
--PIX_TAX_TYPE_AFF,
--PIX_TAX_AFF,
CARD_HOLDER_DOC)
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
		--,[TEMP].PIX_TAX_TYPE_AFF
		--,[TEMP].PIX_TAX_AFF
	   ,[TEMP].CARD_HOLDER_DOC
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
Lucas Aguiar           V3         23/04/2019               ROTINA DE SPLIT            
Caike Uch?a            V4         15/08/2019               inserting coluns            
Marcus Gall            V5         28/11/2019               Add Model_POS, Segment, Location EC            
Caike Uch?a            V6         20/01/2020               ADD CNAE            
Kennedy Alef           v7         08/04/2020               add link de pagamento            
Caike Uch?a            v8         30/04/2020               insert ec prod            
Caike Uch?a            v9         17/08/2020               Add SALES_TYPE            
Luiz Aquino            v10         01/07/2020                 add PlanDzero            
Caike Uchoa            v11         31/08/2020               Add cod_ec_prod            
 Caike Uchoa           v12        28/09/2020               Add branch business            
Elir Ribeiro           v13        24/11/2020              terminal length to 100        
Caike Uchôa            v14        17-02-2021              Add e-mail
Caike Uchoa            v15        02-03-2021              add card_holder_doc and alter email
---------------------------------------------           ---------------------------------------------            
********************************************************************************************/ 
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
@TERMINAL_VERSION VARCHAR(200) = NULL,        
@EMAIL VARCHAR(200) = null)              
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
   ,REPORT_TRANSACTIONS_EXP.EMAIL    
   ,ISNULL([REPORT_TRANSACTIONS_EXP].PIX_TAX_AFF, 0) AS PIX_TAX_AFF  
   ,ISNULL([REPORT_TRANSACTIONS_EXP].PIX_TAX_TYPE_AFF, '''') AS PIX_TAX_TYPE_AFF
   ,[REPORT_TRANSACTIONS_EXP].CARD_HOLDER_DOC
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

IF @EMAIL IS NOT NULL
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].CUSTOMER_EMAIL = @EMAIL ');

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
   @TERMINAL_VERSION VARCHAR(200),        
   @EMAIL VARCHAR(200)        
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
					,@TERMINAL_VERSION = @TERMINAL_VERSION
					,@EMAIL = @EMAIL;
END;
END;

--ST-1899

GO

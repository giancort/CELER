--ST-1441

UPDATE COMMERCIAL_ESTABLISHMENT SET 
SHORT_URL_TCU =('https://' + SHORT_URL_TCU) FROM COMMERCIAL_ESTABLISHMENT WHERE SHORT_URL_TCU IS NOT NULL

--ST-1441

GO

--ST-1488

GO 

IF OBJECT_ID('SP_LS_AFFILIATOR_COMP') IS NOT NULL
DROP PROCEDURE [SP_LS_AFFILIATOR_COMP];

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
------------------------------------------------------------------------------------------      
*****************************************************************************************************************/      
                              
(      
 @ACCESS_KEY          VARCHAR(300),       
 @NAME                VARCHAR(100) = NULL,       
 @ACTIVE              INT          = 1,       
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
 AFFILIATOR_CONTACT.MAIL AS EMAIL
 FROM AFFILIATOR                               
  INNER JOIN COMPANY ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP     
  JOIN COMPANY_DOMAIN ON COMPANY_DOMAIN.COD_COMP = COMPANY.COD_COMP AND COMPANY_DOMAIN.ACTIVE = 1    
  LEFT JOIN THEMES ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR AND THEMES.ACTIVE = 1                      
  LEFT JOIN USERS u ON u.COD_USER = AFFILIATOR.COD_USER_CAD                      
  LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = AFFILIATOR.COD_SITUATION       
  LEFT JOIN AFFILIATOR_CONTACT ON AFFILIATOR_CONTACT.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
  AND AFFILIATOR_CONTACT.ACTIVE =1
 WHERE COMPANY.ACCESS_KEY = @ACCESS_KEY AND AFFILIATOR.ACTIVE = @Active';    
      
      
      
      
      
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
  @Active INT,                      
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
  

  GO 

IF OBJECT_ID('SP_UPDATE_AFFILIATED') IS NOT NULL
DROP PROCEDURE [SP_UPDATE_AFFILIATED];

GO    
CREATE PROCEDURE [DBO].[SP_UPDATE_AFFILIATED]                               
/*----------------------------------------------------------------------------------------                    
Procedure Name: [SP_UPDATE_AFFILIATOR]                    
Project.......: TKPP                    
------------------------------------------------------------------------------------------                    
Author                       VERSION           Date              Description                    
------------------------------------------------------------------------------------------                    
Luiz Aquino                    V1           01/10/2018             Creation                    
Luiz Aquino                    V2           18/12/2018            Add SPOT_TAX                    
Lucas Aguiar                   v3           2019-04-19        add rotina de split                    
Lucas Aguiar                   v4           2019-07-19        Rotina de agenda bloqueada                        
Lucas Aguiar                   v5           2019-08-23        Add servi�o de notifica��es                  
Luiz Aquino                    V6           2019-10-24        Add Servi�o de reten��o de agenda         
Caike Uch�a                    v7           2020-02-26           drop services   
Caike uchoa                    v9           21/10/2020           add email 
------------------------------------------------------------------------------------------          
*************************************************************************************************/          
                    
(          
 @CODAFFILIATED          INT,                    
 -- INFO BASE                      
 @COD_COMP               INT,           
 @NAME                   VARCHAR(100),        
 @ACTIVE                 INT = NULL,      
 @CPF_CNPJ               VARCHAR(14),           
 @COD_USER_CAD           INT,           
 @FIREBASE_NAME          VARCHAR(100)  = NULL,           
 @COD_USER_ALT           INT,                    
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
 @PLATFORMNAME           VARCHAR(100)  = NULL,           
 @COMPANY_NAME           VARCHAR(100)  = NULL,           
 @STATE_REGISTRATION     VARCHAR(100)  = NULL,           
 @MUNICIPAL_REGISTRATION VARCHAR(100)  = NULL,           
 @PROPOSED_NUMBER        VARCHAR(100)  = NULL,        
 --      
 @PROGRESSIVE_COST       INT,         
 @NOTE_FINANCE           VARCHAR(MAX)  = NULL,       
 @WAS_BLOCKED            INT           = NULL,
 @EMAIL                  VARCHAR(100)
)          
AS          
BEGIN    
        
           
   DECLARE           
   @COD_SITUATION INT;    
       
         
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
   ,[COD_SITUATION] = @COD_SITUATION    
   ,[NOTE_FINANCE_SCHEDULE] = @NOTE_FINANCE    
   ,[ACTIVE] = ISNULL(@ACTIVE ,[ACTIVE])   
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
[ACTIVE],
MAIL)    
 VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @CELL_NUMBER, @COD_TP_CONT, @COD_OPER, current_timestamp, @COD_USER_ALT, @DDI, @DDD, 1,@EMAIL);    
    
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
[ACTIVE],
MAIL)    
 VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @PHONE_NUMBER, @PHONE_COD_TP_CONT, @PHONE_COD_OPER, current_timestamp, @COD_USER_ALT, @PHONE_DDI, @PHONE_DDD, 1,@EMAIL);    
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

--ST-1488
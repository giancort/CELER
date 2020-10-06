GO
GO

IF OBJECT_ID ('SP_LS_AFFILIATOR_COMP') IS NOT NULL
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
Caike Uchôa                       v5        26/02/2020            add OperationAff          
Elir Ribeiro                      v6        16/04/2020           add tax and deadline billet        
Caike Uchôa                       v7        17/04/2020           add busca por cnpj    
Caike Uchoa                       v8        16/09/2020           add correcao billetTax
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
  ) AS [billet_tax]
 FROM AFFILIATOR                             
  INNER JOIN COMPANY ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP   
  JOIN COMPANY_DOMAIN ON COMPANY_DOMAIN.COD_COMP = COMPANY.COD_COMP AND COMPANY_DOMAIN.ACTIVE = 1  
  LEFT JOIN THEMES ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR AND THEMES.ACTIVE = 1                    
  LEFT JOIN USERS u ON u.COD_USER = AFFILIATOR.COD_USER_CAD                    
  LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = AFFILIATOR.COD_SITUATION                      
 WHERE COMPANY.ACCESS_KEY = @ACCESS_KEY AND AFFILIATOR.ACTIVE = @Active ';  
    
    
    
    
    
    IF @NAME IS NOT NULL  
SET @QUERY_ = @QUERY_ + 'AND AFFILIATOR.NAME LIKE @BUSCA OR AFFILIATOR.CPF_CNPJ LIKE @BUSCA';  
  
IF (@CODAFF IS NOT NULL)  
SET @QUERY_ = @QUERY_ + 'AND AFFILIATOR.COD_AFFILIATOR = @CodAff ';  
  
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

IF OBJECT_ID('SP_UPDATE_SERVICES_AFFILIATOR') IS NOT NULL
DROP PROCEDURE [SP_UPDATE_SERVICES_AFFILIATOR];

GO

CREATE PROCEDURE [dbo].[SP_UPDATE_SERVICES_AFFILIATOR]  
/*----------------------------------------------------------------------------------------  
    Project.......: TKPP  
------------------------------------------------------------------------------------------  
    Author          VERSION      Date              Description  
------------------------------------------------------------------------------------------  
    Caike Ucha     v1           2020-02-26        Creation  
    Elir Ribeiro    v2           2020-04-20         add service billet  
    Caike Ucha     v3           2020-04-20        add service MultiEC  
    Elir Ribeiro    v4           2020-04-22        alter proc  
    Luiz Aquino     v5           2020-05-18        et 859 tcu estabelecimento  
    Luiz Aquino     V6           2020-06-23        ET-895 PlanDZero  
	Caike Uchoa     v7           2020-09-16        add correcao billetTax na services
------------------------------------------------------------------------------------------  
***************************************************************************************************/ (@CODAFFILIATED INT,  
@COD_COMP INT,  
@COD_USER_ALT INT,  
@SPOT_TAX DECIMAL(6, 2) = 0,  
@HAS_SPOT INT = 0,  
@SPLIT_OPT INT = 0,  
@HAS_SPLIT INT = 0,  
@HAS_NOTIFICATION INT = 0,  
@PASSWORD_NOTIFICATION VARCHAR(255) = NULL,  
@CLIENTID_NOTIFICATION VARCHAR(255) = NULL,  
@LEDGERRETENTION INT = 0,  
@LEDGERRETENTIONCONFIG VARCHAR(512) = NULL,  
@HAS_TRANSLATION INT = 0,  
@OPERATION_AFF INT = 0,  
@HAS_BILLET INT = 0,  
@BILLET_TAX DECIMAL(6, 2) = 0,  
@HAS_SPLIT_BILLET INT = 0,  
@MULTIEC_ACTIVE INT = 0,  
@TCU_DETAILED INT = 0,  
@PLANDZERO INT = 0,  
@PlanDZeroJson VARCHAR(256) = NULL)  
AS  
BEGIN  
 DECLARE @CODSPOTSERVICE INT;  
 DECLARE @COD_SPLIT_SERVICE INT;  
 DECLARE @COD_GWNOTIFICATION INT;  
 DECLARE @HAS_CREDENTIAL INT = 0;  
 DECLARE @COD_AWAITSPLIT INT = 0;  
 DECLARE @COD_TRANSLATE INT;  
 DECLARE @CODBILLETSERVICE INT;  
 DECLARE @CODSPLITBILLET INT;  
 DECLARE @COD_MULTIEC_AFFILIATOR INT;  
 DECLARE @COD_TCU_DETAILED INT;  
 DECLARE @COD_PLANDZERO INT;  
  
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
 SELECT  
  @CODBILLETSERVICE = [COD_ITEM_SERVICE]  
 FROM [ITEMS_SERVICES_AVAILABLE]  
 WHERE [CODE] = '12';  
 SELECT  
  @CODSPLITBILLET = [COD_ITEM_SERVICE]  
 FROM [ITEMS_SERVICES_AVAILABLE]  
 WHERE [CODE] = '13';  
 SELECT  
  @COD_MULTIEC_AFFILIATOR = [COD_ITEM_SERVICE]  
 FROM [ITEMS_SERVICES_AVAILABLE]  
 WHERE [CODE] = '14';  
 SELECT  
  @COD_TCU_DETAILED = [COD_ITEM_SERVICE]  
 FROM [ITEMS_SERVICES_AVAILABLE]  
 WHERE [CODE] = '16';  
 SELECT  
  @COD_PLANDZERO = [COD_ITEM_SERVICE]  
 FROM [ITEMS_SERVICES_AVAILABLE]  
 WHERE [NAME] = 'PlanDZero';  
  
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
  
 IF (@MULTIEC_ACTIVE = 0  
  AND (SELECT  
    COUNT(*)  
   FROM [SERVICES_AVAILABLE]  
   WHERE [COD_ITEM_SERVICE] = @COD_MULTIEC_AFFILIATOR  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NOT NULL  
   AND [ACTIVE] = 1)  
  > 0)  
  THROW 61059, 'AFFILIATE CONFLICT HAS ESTABLISHMENTS WITH MULTIEC ACTIVE', 1;  
  
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
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE])  
   VALUES (current_timestamp, @COD_USER_ALT, @CODSPOTSERVICE, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp);  
 END;  
  
 UPDATE AFFILIATOR  
 SET SPOT_TAX = @SPOT_TAX  
    ,OPERATION_AFF = @OPERATION_AFF  
 WHERE COD_AFFILIATOR = @CODAFFILIATED;  
  
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
  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], [COD_OPT_SERV])  
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
  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], [CONFIG_JSON])  
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
   INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE])  
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
  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE])  
   VALUES (current_timestamp, @COD_USER_ALT, @COD_GWNOTIFICATION, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp);  
  
  EXEC [SP_REG_ACCESS_NOTIFICATION_AFF] @CODAFFILIATED  
            ,@PASSWORD_NOTIFICATION  
            ,@CLIENTID_NOTIFICATION;  
 END  
  
 /*******************************************  
 *********** UPDATE BILLET AFFILIATED *******  
 *******************************************/  
  
 IF (SELECT  
    COUNT(*)  
   FROM [SERVICES_AVAILABLE]  
   WHERE [COD_ITEM_SERVICE] = @CODBILLETSERVICE  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NULL  
   AND [ACTIVE] = 1)  
  > 0  
 BEGIN  
  IF @HAS_BILLET = 0  
  BEGIN  
   UPDATE [SERVICES_AVAILABLE]  
   SET [ACTIVE] = 0  
      ,[COD_USER] = @COD_USER_ALT  
      ,[MODIFY_DATE] = current_timestamp  
   WHERE [COD_ITEM_SERVICE] = @CODBILLETSERVICE  
   AND [COD_COMP] = @COD_COMP  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NULL;  
  END;  
  IF @HAS_SPLIT_BILLET = 0  
  BEGIN  
   UPDATE [SERVICES_AVAILABLE]  
   SET [ACTIVE] = 0  
      ,[COD_USER] = @COD_USER_ALT  
      ,[MODIFY_DATE] = current_timestamp  
   WHERE [COD_ITEM_SERVICE] = @CODSPLITBILLET  
   AND [COD_COMP] = @COD_COMP  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NULL;  
  END;  
  ELSE  
  BEGIN  
   IF @BILLET_TAX > (SELECT  
      MIN([BILLET_TAX])  
     FROM [COMMERCIAL_ESTABLISHMENT]  
     WHERE [COD_AFFILIATOR] = @CODAFFILIATED  
     AND [BILLET_TAX] <> 0  
     AND [ACTIVE] = 1)  
    THROW 61047, 'AFFILIATED NEW BILLET VALUE IS HIGHER THAN ONE OF ITS ESTABLISHMENTS', 1;  
  END;  
 END;  
 ELSE  
 IF @HAS_BILLET = 1  
 BEGIN  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], SERVICE_AMOUNT)  
   VALUES (current_timestamp, @COD_USER_ALT, @CODBILLETSERVICE, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, @BILLET_TAX);  
 END;  
  
 IF @HAS_SPLIT_BILLET = 1  
 BEGIN  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], SERVICE_AMOUNT)  
   VALUES (current_timestamp, @COD_USER_ALT, @CODSPLITBILLET, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, @BILLET_TAX);  
 END;  
  
 UPDATE [SERVICES_AVAILABLE]  
 SET SERVICE_AMOUNT = @BILLET_TAX  
 WHERE [COD_ITEM_SERVICE] = @CODBILLETSERVICE  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NULL  
   AND [ACTIVE] = 1;  
  
 /*******************************************  
 *********** UPDATE MULTIEC AFFILIATED *******  
 *******************************************/  
  
 IF (@MULTIEC_ACTIVE = 0)  
 BEGIN  
  UPDATE [SERVICES_AVAILABLE]  
  SET [ACTIVE] = 0  
     ,[COD_USER] = @COD_USER_ALT  
     ,[MODIFY_DATE] = current_timestamp  
  WHERE [COD_ITEM_SERVICE] = @COD_MULTIEC_AFFILIATOR  
  AND [COD_COMP] = @COD_COMP  
  AND [COD_AFFILIATOR] = @CODAFFILIATED  
  AND [COD_EC] IS NULL;  
 END  
 ELSE  
 BEGIN  
  UPDATE [SERVICES_AVAILABLE]  
  SET [ACTIVE] = 0  
     ,[COD_USER] = @COD_USER_ALT  
     ,[MODIFY_DATE] = current_timestamp  
  WHERE [COD_ITEM_SERVICE] = @COD_MULTIEC_AFFILIATOR  
  AND [COD_COMP] = @COD_COMP  
  AND [COD_AFFILIATOR] = @CODAFFILIATED  
  AND [COD_EC] IS NULL;  
  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], [COD_OPT_SERV])  
   VALUES (current_timestamp, @COD_USER_ALT, @COD_MULTIEC_AFFILIATOR, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, 1);  
 END  
  
 /*******************************************  
     *********** TCU DETAILED *******  
 *******************************************/  
  
 IF (@TCU_DETAILED = 0)  
 BEGIN  
  UPDATE [SERVICES_AVAILABLE]  
  SET [ACTIVE] = 0  
     ,[COD_USER] = @COD_USER_ALT  
     ,[MODIFY_DATE] = current_timestamp  
  WHERE [COD_ITEM_SERVICE] = @COD_TCU_DETAILED  
  AND [COD_COMP] = @COD_COMP  
  AND [COD_AFFILIATOR] = @CODAFFILIATED  
  AND [COD_EC] IS NULL;  
 END  
 ELSE  
 IF NOT EXISTS (SELECT  
    COD_ITEM_SERVICE  
   FROM [SERVICES_AVAILABLE]  
   WHERE [COD_ITEM_SERVICE] = @COD_TCU_DETAILED  
   AND [COD_COMP] = @COD_COMP  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NULL  
   AND [ACTIVE] = 1)  
 BEGIN  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], [COD_OPT_SERV])  
   VALUES (current_timestamp, @COD_USER_ALT, @COD_TCU_DETAILED, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, 1);  
 END  
  
 /*******************************************  
     *********** Plano DZero *******  
 *******************************************/  
  
 IF @PLANDZERO = 0  
 BEGIN  
  UPDATE [SERVICES_AVAILABLE]  
  SET [ACTIVE] = 0  
     ,[COD_USER] = @COD_USER_ALT  
     ,[MODIFY_DATE] = current_timestamp  
  WHERE [COD_ITEM_SERVICE] = @COD_PLANDZERO  
  AND [COD_AFFILIATOR] = @CODAFFILIATED;  
 END  
 ELSE  
 IF NOT EXISTS (SELECT  
    COD_ITEM_SERVICE  
   FROM [SERVICES_AVAILABLE]  
   WHERE [COD_ITEM_SERVICE] = @COD_PLANDZERO  
   AND [COD_COMP] = @COD_COMP  
   AND [COD_AFFILIATOR] = @CODAFFILIATED  
   AND [COD_EC] IS NULL  
   AND [ACTIVE] = 1)  
 BEGIN  
  INSERT INTO [SERVICES_AVAILABLE] ([CREATED_AT], [COD_USER], [COD_ITEM_SERVICE], [COD_COMP], [COD_AFFILIATOR], [COD_EC], [ACTIVE], [MODIFY_DATE], [COD_OPT_SERV], CONFIG_JSON)  
   VALUES (current_timestamp, @COD_USER_ALT, @COD_PLANDZERO, @COD_COMP, @CODAFFILIATED, NULL, 1, current_timestamp, 1, @PlanDZeroJson);  
 END  
 ELSE  
 BEGIN  
  
  UPDATE [SERVICES_AVAILABLE]  
  SET CONFIG_JSON = @PlanDZeroJson  
     ,COD_USER = @COD_USER_ALT  
     ,MODIFY_DATE = GETDATE()  
  WHERE [COD_ITEM_SERVICE] = @COD_PLANDZERO  
  AND [COD_COMP] = @COD_COMP  
  AND [COD_AFFILIATOR] = @CODAFFILIATED  
  AND [COD_EC] IS NULL  
  AND [ACTIVE] = 1  
  
  DECLARE @CREDIT DECIMAL(4, 2) = CAST(JSON_VALUE(@PlanDZeroJson, '$.credit') AS DECIMAL(4, 2))  
  DECLARE @DEBIT DECIMAL(4, 2) = CAST(JSON_VALUE(@PlanDZeroJson, '$.debit') AS DECIMAL(4, 2))  
  DECLARE @CELERONLY VARCHAR(16) = JSON_VALUE(@PlanDZeroJson, '$.celerOnly')  
  
  UPDATE [SERVICES_AVAILABLE]  
  SET CONFIG_JSON = JSON_MODIFY(CONFIG_JSON, '$.debit', @DEBIT)  
     ,MODIFY_DATE = GETDATE()  
  WHERE [COD_ITEM_SERVICE] = @COD_PLANDZERO  
  AND [COD_AFFILIATOR] = @CODAFFILIATED  
  AND [COD_EC] IS NOT NULL  
  AND [ACTIVE] = 1  
  AND CAST(JSON_VALUE(CONFIG_JSON, '$.debit') AS DECIMAL(4, 2)) < @DEBIT  
  
  UPDATE [SERVICES_AVAILABLE]  
  SET CONFIG_JSON = JSON_MODIFY(CONFIG_JSON, '$.credit', @CREDIT)  
     ,MODIFY_DATE = GETDATE()  
  WHERE [COD_ITEM_SERVICE] = @COD_PLANDZERO  
  AND [COD_AFFILIATOR] = @CODAFFILIATED  
  AND [COD_EC] IS NOT NULL  
  AND [ACTIVE] = 1  
  AND CAST(JSON_VALUE(CONFIG_JSON, '$.credit') AS DECIMAL(4, 2)) < @CREDIT  
  
  IF @CELERONLY = 'true'  
  BEGIN  
   DECLARE @CODBKCELER INT  
   SELECT  
    @CODBKCELER = COD_BANK  
   FROM BANKS  
   WHERE NAME = 'CELER DIGITAL'  
  
   UPDATE SA  
   SET ACTIVE = 0  
      ,MODIFY_DATE = GETDATE()  
   FROM [SERVICES_AVAILABLE] SA  
   JOIN BANK_DETAILS_EC BDE  
    ON SA.COD_EC = BDE.COD_EC  
    AND BDE.ACTIVE = 1  
    AND IS_CERC = 0  
    AND COD_BANK != @CODBKCELER  
   WHERE [COD_ITEM_SERVICE] = @COD_PLANDZERO  
   AND SA.[COD_AFFILIATOR] = @CODAFFILIATED  
   AND SA.[COD_EC] IS NOT NULL  
   AND SA.[ACTIVE] = 1  
  END  
 END  
END;  


GO

IF OBJECT_ID ('SP_REPORT_TRANSACTION_BILLET') IS NOT NULL
DROP PROCEDURE [SP_REPORT_TRANSACTION_BILLET];

GO
CREATE PROCEDURE [dbo].[SP_REPORT_TRANSACTION_BILLET]  
/*----------------------------------------------------------------------------------------      
    Procedure Name: [SP_REPORT_TRANSACTION_BILLET]  Project.......: TKPP      
------------------------------------------------------------------------------------------      
    Author              VERSION        Date         Description      
------------------------------------------------------------------------------------------      
    Marcus Gall        V1          22/04/2020      Creation      
	Caike Uchoa        V2          21/09/2020      add DESCRIPTION_TRAN_BILLET boleto
------------------------------------------------------------------------------------------*/  
(@INITIAL_DATE DATETIME,  
 @FINAL_DATE DATETIME,  
 @AFF [CODE_TYPE] READONLY,  
 @EC [CODE_TYPE] READONLY,  
 @STATUS [CODE_TYPE] READONLY,  
 @NSU VARCHAR(255) = NULL)  
AS  
  
DECLARE @QUERY_ NVARCHAR(MAX) = '';  
  
BEGIN  
    SET @INITIAL_DATE = CONCAT(CAST(@INITIAL_DATE AS DATE), ' ', FORMAT(CAST('00:00:00' AS TIME), N'hh\:mm\:ss'))  
    SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'))  
  
    SET @QUERY_ = CONCAT(@QUERY_, '      
SELECT BILLET_TRANSACTION.TRANSACTION_CODE    
     , BILLET_TRANSACTION.COD_BILLET    
     , BILLET_TRANSACTION.CREATED_AT    
     , BILLET_TRANSACTION.BILLET_AMOUNT    
     , BILLET_TRANSACTION.RATE    
     , BILLET_TRANSACTION.NET_AMOUNT    
     , BILLET_TRANSACTION.DUE_DATE    
     , AFFILIATOR.NAME                AS AFFILIATOR_NAME    
     , COMMERCIAL_ESTABLISHMENT.NAME  AS EC_NAME    
     , IIF(FINANCE_CALENDAR.COD_FIN_CALENDAR IS NOT NULL, CALENDAR_SIT.SITUATION_TR,    
           TRADUCTION_SITUATION.SITUATION_TR) AS SITUATION_NAME    
     , BILLET_TRANSACTION.BILLET_URL    
     , BILLET_TRANSACTION.DIGITABLE_LINE    
     , BILLET_TRANSACTION.SPLIT_MODE    
     , BILLET_TRANSACTION.BARCODE  
     ,  COMMERCIAL_ESTABLISHMENT.CALLBACK_BILLET      
	 ,BILLET_TRANSACTION.DESCRIPTION_TRAN_BILLET
FROM BILLET_TRANSACTION    
         INNER JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = BILLET_TRANSACTION.COD_EC    
         INNER JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR    
         LEFT JOIN SITUATION ON SITUATION.COD_SITUATION = BILLET_TRANSACTION.COD_SITUATION    
         LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = SITUATION.COD_SITUATION    
         LEFT JOIN FINANCIAL_BILLET ON BILLET_TRANSACTION.COD_BILLET = FINANCIAL_BILLET.COD_BILLET    
         LEFT JOIN FINANCE_CALENDAR ON FINANCIAL_BILLET.COD_FIN_CALENDAR = FINANCE_CALENDAR.COD_FIN_CALENDAR    
         LEFT JOIN TRADUCTION_SITUATION CALENDAR_SIT ON CALENDAR_SIT.COD_SITUATION = FINANCE_CALENDAR.COD_SITUATION       
 WHERE CAST(BILLET_TRANSACTION.CREATED_AT AS DATETIME) BETWEEN ''' + CAST(@INITIAL_DATE AS VARCHAR) + ''' AND ''' +  
                                  CAST(@FINAL_DATE AS VARCHAR) + ''' ');  
  
    IF (SELECT COUNT(*)  
        FROM @EC)  
        > 0  
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_EC IN (SELECT [CODE] FROM @EC) ';  
  
    IF (SELECT COUNT(*)  
        FROM @AFF)  
        > 0  
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR IN (SELECT [CODE] FROM @AFF) ';  
  
    IF (SELECT COUNT(*)  
        FROM @STATUS)  
        > 0  
        SET @QUERY_ = @QUERY_ + ' AND SITUATION.COD_SITUATION IN (SELECT [CODE] FROM @STATUS) ';  
  
    IF ( @NSU IS NOT NULL)  
        SET @QUERY_ = @QUERY_ + ' AND BILLET_TRANSACTION.TRANSACTION_CODE = @NSU';  
  
    SET @QUERY_ = CONCAT(@QUERY_, ' ORDER BY BILLET_TRANSACTION.CREATED_AT');  
  
    EXEC sp_executesql @QUERY_  
        ,  
         N' @INITIAL_DATE DATETIME, @FINAL_DATE DATETIME, @AFF [CODE_TYPE] READONLY, @EC [CODE_TYPE] READONLY, @STATUS [CODE_TYPE] READONLY, @NSU VARCHAR(255)'  
        , @INITIAL_DATE = @INITIAL_DATE  
        , @FINAL_DATE = @FINAL_DATE  
        , @AFF = @AFF  
        , @EC = @EC  
        , @STATUS = @STATUS  
        , @NSU = @NSU;  
END    





GO


GO

IF OBJECT_ID('FNC_REMOV_CARAC_ESP') IS NOT NULL
DROP FUNCTION [FNC_REMOV_CARAC_ESP];

GO

CREATE FUNCTION [dbo].[FNC_REMOV_CARAC_ESP]
(
    @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
 
    
    DECLARE 
        @Result VARCHAR(MAX), 
        @StartingIndex INT = 0
    
    
    WHILE (1 = 1)
    BEGIN 
        
        SET @StartingIndex = PATINDEX('%[^a-Z|0-9|^ ]%',@String) 
        
        IF (@StartingIndex <> 0)
            SET @String = REPLACE(@String,SUBSTRING(@String, @StartingIndex,1),'') 
        ELSE 
            BREAK
 
    END   
	
	SET @String = LOWER(@String)
	/****************************************************************************************************************/
    /** RETIRA ACENTUAÇÃO DAS VOGAIS **/
    /****************************************************************************************************************/
	SET @String = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@String,'á','a'),'à','a'),'â','a'),'ã','a'),'ä','a')
    SET @String = REPLACE(REPLACE(REPLACE(REPLACE(@String,'é','e'),'è','e'),'ê','e'),'ë','e')
    SET @String = REPLACE(REPLACE(REPLACE(REPLACE(@String,'í','i'),'ì','i'),'î','i'),'ï','i')
    SET @String = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@String,'ó','o'),'ò','o'),'ô','o'),'õ','o'),'ö','o')
    SET @String = REPLACE(REPLACE(REPLACE(REPLACE(@String,'ú','u'),'ù','u'),'û','u'),'ü','u')
    SET @String = REPLACE(@String,'^','')

    
    /****************************************************************************************************************/
    /** RETIRA ACENTUAÇÃO DAS CONSOANTES **/
    /****************************************************************************************************************/
    SET @String = REPLACE(@String,'ý','y')
    SET @String = REPLACE(@String,'ñ','n')
    SET @String = REPLACE(@String,'ç','c')  
    
    SET @Result = UPPER(REPLACE(@String,'|',''))
    
	IF (@Result = '')
	SET @Result = '0';

    RETURN @Result
 
END
 

 GO

IF OBJECT_ID('FNC_REMOV_LETRAS') IS NOT NULL
DROP FUNCTION [FNC_REMOV_LETRAS];

GO

CREATE FUNCTION [dbo].[FNC_REMOV_LETRAS]
(
    @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
 
    
    DECLARE 
        @Result VARCHAR(MAX), 
        @StartingIndex INT = 0
    
    
    WHILE (1 = 1)
    BEGIN 
        
        SET @StartingIndex = PATINDEX('%[^0-9]%',@String) 
        
        IF (@StartingIndex <> 0)
            SET @String = REPLACE(@String,SUBSTRING(@String, @StartingIndex,1),'') 
        ELSE 
            BREAK
 
    END    
    
    SET @Result = REPLACE(@String,'|','')
    
    IF (@Result = '')
	SET @Result = '0';

    RETURN @Result
 
END


GO 

IF OBJECT_ID('SP_CONTACT_DATA_EQUIP') IS NOT NULL 
DROP PROCEDURE [SP_CONTACT_DATA_EQUIP];

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
------------------------------------------------------------------------------------------*/          
(          
  @TERMINALID INT)          
AS          
BEGIN    
SELECT    
TOP 1    
 VW_COMPANY_EC_BR_DEP_EQUIP.CPF_CNPJ_BR    
   ,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF    
   ,[dbo].[FNC_REMOV_CARAC_ESP](VW_COMPANY_EC_BR_DEP_EQUIP.TRADING_NAME_BR) AS TRADING_NAME_BR 
   ,[dbo].[FNC_REMOV_CARAC_ESP](VW_COMPANY_EC_BR_DEP_EQUIP.BRANCH_NAME) AS BRANCH_NAME
   ,CASE    
  WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'    
  ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC    
 END AS MCC    
   ,COMMERCIAL_ESTABLISHMENT.CODE AS MERCHANT_CODE    
   ,[dbo].[FNC_REMOV_CARAC_ESP](ADDRESS_BRANCH.[ADDRESS]) AS [ADDRESS]  
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
 END AS [SPLIT] ,  
 (  
CASE   
WHEN   
  (SELECT   
 COUNT(*) FROM SERVICES_AVAILABLE  
 WHERE COD_ITEM_SERVICE=13  
 AND ACTIVE=1  
 AND COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC  
 AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR ) > 0 THEN 1  
 ELSE 0  
END   
 ) AS MANY_MERCHANTS  
  
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
--LEFT JOIN SERVICES_AVAILABLE          
-- ON SERVICES_AVAILABLE.COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC          
WHERE EQUIPMENT.COD_EQUIP = @TERMINALID    
AND ASS_DEPTO_EQUIP.ACTIVE = 1    
ORDER BY ADDRESS_BRANCH.COD_ADDRESS DESC    
    
END    
  

GO

GO

IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '006')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('006', 'TERMINAL NAO CADASTRADO', 'TERMINAL NAO CADASTRADO', 'VALIDATE_TERMINAL', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '003')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('003', 'TERMINAL INATIVO', 'TERMINAL INATIVO', 'VALIDATE_TERMINAL', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '008')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('008', 'NAO ASSOCIADO', 'NAO ASSOCIADO', 'VALIDATE_TERMINAL', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '009')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('009', 'EC PENDENTE DE APROVACAO', 'EC PENDENTE DE APROVACAO', 'VALIDATE_TERMINAL', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '010')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('010', 'EC INVALIDO . RESETE O TERMINAL', 'EC INVALIDO . RESETE O TERMINAL', 'VALIDATE_TERMINAL', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '302')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('302', 'TID / LOGICAL NUMBER NOT FOUND', 'TID / LOGICAL NUMBER NOT FOUND', 'DATA_EQUIP_AC / DATA_COMP_ACQ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '402')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('402', 'LIMITE DE TRANSACOES EXCEDIDO', 'LIMITE DE TRANSACOES EXCEDIDO', '   VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '404')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('404', 'PLANO / TAXA / TERMINAL NAO ENCONTRADO', 'PLANO / TAXA / TERMINAL NAO ENCONTRADO', '   VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '403')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('403', 'LIMITE DIARIO EXCEDIDO', 'LIMITE DIARIO EXCEDIDO', '   VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '407')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('407', 'LIMITE MENSAL EXCEDIDO', 'LIMITE MENSAL EXCEDIDO', '   VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '004')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('004', 'CHAVE DE CONEXAO COM ADQUIRENTE NAO ENCONTRADAS', 'CHAVE DE CONEXAO COM ADQUIRENTE NAO ENCONTRADAS', '   VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '012')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('012', 'PRIVATE LABEL NAO PODE REALIZAR SPLIT', 'PRIVATE LABEL NAO PODE REALIZAR SPLIT', '   VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '030')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('030', 'ESTABELECIMENTO COMERCIAL DA TRANSACAO (PRODUTO) NAO ENCONTRADO', 'ESTABELECIMENTO COMERCIAL DA TRANSACAO (PRODUTO) NAO ENCONTRADO', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '031')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('031', 'ESTABELECIMENTO COMERCIAL DA TRANSACAO (PRODUTO) INATIVO', 'ESTABELECIMENTO COMERCIAL DA TRANSACAO (PRODUTO) INATIVO', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '032')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('032', 'ESTABELECIMENTO DO POS NAO ASSOCIADO AO PRODUTO', 'ESTABELECIMENTO DO POS NAO ASSOCIADO AO PRODUTO', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '033')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('033', 'PRODUTO SEM ECS PARA SPLIT ASSOCIADOS', 'PRODUTO SEM ECS PARA SPLIT ASSOCIADOS', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '034')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('034', 'UM OU MAIS ECS DO SPLIT ESTAO INATIVOS', 'UM OU MAIS ECS DO SPLIT ESTAO INATIVOS', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '035')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('035', 'PERCENTUAL DO SPLIT INVALIDO PARA O PRODUTO ', 'PERCENTUAL DO SPLIT INVALIDO PARA O PRODUTO ', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '036')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('036', 'UM OU MAIS ECS NAO POSSUEM PLANO PARA REALIZAR O SPLIT DA TRANSACAO', 'UM OU MAIS ECS NAO POSSUEM PLANO PARA REALIZAR O SPLIT DA TRANSACAO', 'MULTI EC ON VALIDATE_TRANSACTION ', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '007')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('007', 'CREDENCIAIS INVALIDAS', 'CREDENCIAIS INVALIDAS', 'GET_ONLINE_CREDENCIALS', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '409')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('409', 'TRANSACAO ONLINE DESABILITADA', 'TRANSACAO ONLINE DESABILITADA', 'VALIDATE_TRANSACTION', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '300')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('300', 'SITUACAO DA TRANSACAO INVALIDA (Transacao precisa estar como aguardando t�tulos)', 'SITUACAO DA TRANSACAO INVALIDA (Transacao precisa estar como aguardando t�tulos)', 'SPLIT', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '301')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('301', 'EC DE ORIGEM INVALIDO (EC que esta tentando fazer o split � diferente do ec da transacao)', 'EC DE ORIGEM INVALIDO (EC que esta tentando fazer o split � diferente do ec da transacao)', 'SPLIT', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '303')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('303', 'VALOR DE SPLIT INVALIDO (Comparativo entre transacao e valor enviado para split)', 'VALOR DE SPLIT INVALIDO (Comparativo entre transacao e valor enviado para split)', 'SPLIT', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '304')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('304', 'AFILIADOR INVALIDO (Documento do afiliador � diferente dos ecs que receberao split)', 'AFILIADOR INVALIDO (Documento do afiliador � diferente dos ecs que receberao split)', 'SPLIT', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '305')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('305', 'UM OU MAIS ECS ESTAO INATIVOS (Ecs do split)', 'UM OU MAIS ECS ESTAO INATIVOS (Ecs do split)', 'SPLIT', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '306')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('306', 'UM OU MAIS ECS NAO POSSUEM PLANO PARA REALIZAR O SPLIT DA TRANSACAO', 'UM OU MAIS ECS NAO POSSUEM PLANO PARA REALIZAR O SPLIT DA TRANSACAO ', 'SPLIT', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '002')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('002', 'ERRO GEN�RICO DE BASE (POSS�VEL PROBLEMA GRAVE)', 'ERRO GEN�RICO DE BASE (POSS�VEL PROBLEMA GRAVE)', 'BANCO DE DADOS', 'BACKOFFICE')
IF (SELECT
			COUNT(*)
		FROM CONTROL_ERRORS
		WHERE CODE = '001')
	= 0
	INSERT INTO CONTROL_ERRORS (CODE, [DESCRIPTION], DESCRIPTION_SOURCE, TYPE_ERROR, MODULE_ERROR)
		VALUES ('001', 'FALHA DE CONEXAO COM A BASE (F)', 'FALHA DE CONEXAO COM A BASE (F)', 'BANCO DE DADOS', 'BACKOFFICE')


GO


IF OBJECT_ID('SP_VALIDATE_TRANSACTION_ON') IS NOT NULL
	DROP PROCEDURE [SP_VALIDATE_TRANSACTION_ON];

GO

CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION_ON]
/*------------------------------------------------------------------------------------------------------------------------------------------                                                
Procedure Name: [SP_VALIDATE_TRANSACTION]                                                
Project.......: TKPP                                                
------------------------------------------------------------------------------------------------------------------------------------------------                                                
Author                          VERSION        Date                            Description                                                
-------------------------------------------------------------------------------------------------------------------------------------------------                                                
Kennedy Alef     V1   20/08/2018    Creation                                                
Lucas Aguiar     v2   17-04-2019    Passar par�metro opcional (CODE_SPLIT) e fazer suas respectivas inser��es                                    
Lucas Aguiar     v4   23-04-2019    Parametro opc cod ec         
Caike Uch�a      v5   21-09-2020    correcao error 409
------------------------------------------------------------------------------------------------------------------------------------------------*/ (@TERMINALID VARCHAR(100)
, @TYPETRANSACTION VARCHAR(100)
, @AMOUNT DECIMAL(22, 6)
, @QTY_PLOTS INT
, @PAN VARCHAR(100)
, @BRAND VARCHAR(200)
, @TRCODE VARCHAR(200)
, @TERMINALDATE DATETIME = NULL
, @CODPROD_ACQ INT
, @TYPE VARCHAR(100)
, @COD_BRANCH INT = NULL
, @MID VARCHAR(100)
, @DESCRIPTION VARCHAR(300) = NULL
, @CODE_SPLIT INT = NULL
, @COD_EC INT = NULL
, @CREDITOR_DOC VARCHAR(100) = NULL
, @DESCRIPTION_TRAN VARCHAR(100) = NULL
, @TRACKING VARCHAR(100) = NULL
, @HOLDER_NAME VARCHAR(100) = NULL
, @HOLDER_DOC VARCHAR(100) = NULL
, @LOGICAL_NUMBER VARCHAR(100) = NULL
, @CUSTOMER_EMAIL VARCHAR(100) = NULL
, @LINK_MODE INT = NULL
, @CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL
, @BILLCODE VARCHAR(64) = NULL
, @BILLEXPIREDATE DATETIME = NULL)
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
											,@COMMENT = '409 - TRANSACTION ONLINE NOT ENABLE'
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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;

			THROW 60002
			, '409'
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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;

			THROW 60002
			, '402'
			, 1;
		END;

		IF @CODTX IS NULL
		/* PROCEDURE DE REGISTRO DE TRANSA��ES NEGADAS*/
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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;

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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;

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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;

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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;


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
											,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
											,@BILLCODE = @BILLCODE
											,@BILLEXPIREDATE = @BILLEXPIREDATE;

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
									,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION
									,@BILLCODE = @BILLCODE
									,@BILLEXPIREDATE = @BILLEXPIREDATE;
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

IF (SELECT
			COUNT(*)
		FROM ITEMS_SERVICES_AVAILABLE
		WHERE NAME = 'RECURRING')
	= 0
	INSERT INTO ITEMS_SERVICES_AVAILABLE (NAME, DESCRIPTION, CODE, ACTIVE, MIN_VALUE, TERM_PAYMENT, TERM_EXP)
		VALUES ('RECURRING', 'Pagamento recorrente', 19, 1, NULL, NULL, NULL);
GO

IF NOT EXISTS (SELECT
			*
		FROM sys.schemas
		WHERE NAME = 'Recurring')
BEGIN
	EXEC ('CREATE SCHEMA Recurring;');
END;
GO


IF OBJECT_ID('Recurring.RECURRING_PAYMENT') IS NOT NULL
	DROP TABLE Recurring.RECURRING_PAYMENT;
GO
CREATE TABLE Recurring.RECURRING_PAYMENT (
	COD_REC_PAYMENT INT IDENTITY
	PRIMARY KEY
   ,CREATED_AT DATETIME DEFAULT [dbo].[FN_FUS_UTF](GETDATE())
   ,ACTIVE INT DEFAULT 1
   ,NAME VARCHAR(255) NOT NULL
   ,DESCRIPTION VARCHAR(255) NOT NULL
   ,COD_EC INT NOT NULL
	REFERENCES COMMERCIAL_ESTABLISHMENT
   ,COD_SITUATION INT NOT NULL
	REFERENCES SITUATION
   ,AMOUNT DECIMAL(22, 6) NOT NULL
   ,PERIOD_TYPE VARCHAR(100) NOT NULL
   ,INITIAL_DATE DATETIME
   ,FINAL_DATE DATETIME
   ,URL_CALLBACK VARCHAR(255)
   ,HAS_EMAIL INT DEFAULT 0
   ,COD_CUSTOMER_REC INT
   ,EMAIL VARCHAR(255)
   ,COD_AFFILIATOR INT
   ,FOREIGN KEY (COD_AFFILIATOR) REFERENCES AFFILIATOR (COD_AFFILIATOR)
)

GO

IF OBJECT_ID('Recurring.CARD_TOKEN') IS NOT NULL
	DROP TABLE Recurring.CARD_TOKEN;
GO
CREATE TABLE Recurring.CARD_TOKEN (
	COD_CARD_TOKEN INT IDENTITY PRIMARY KEY
   ,CREATED_AT DATETIME DEFAULT dbo.FN_FUS_UTF(GETDATE())
   ,TOKEN VARCHAR(255) NOT NULL
   ,BRAND VARCHAR(255) NOT NULL
   ,COD_SITUATION INT
   ,PAN VARCHAR(255)
	FOREIGN KEY (COD_SITUATION) REFERENCES SITUATION (COD_SITUATION)
);

GO

IF OBJECT_ID('Recurring.ASS_RECURRING_TOKEN') IS NOT NULL
	DROP TABLE Recurring.ASS_RECURRING_TOKEN;
GO
CREATE TABLE Recurring.ASS_RECURRING_TOKEN (
	COD_ASS_REC_TOKEN INT IDENTITY PRIMARY KEY
   ,COD_CARD_TOKEN INT NOT NULL
   ,COD_REC_PAYMENT INT NOT NULL
   ,ACTIVE INT DEFAULT 1
   ,FOREIGN KEY (COD_CARD_TOKEN) REFERENCES Recurring.CARD_TOKEN (COD_CARD_TOKEN)
   ,FOREIGN KEY (COD_REC_PAYMENT) REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
);

GO

IF OBJECT_ID('Recurring.DATE_RECURRING_PAYMENT') IS NOT NULL
	DROP TABLE Recurring.DATE_RECURRING_PAYMENT;
GO
CREATE TABLE Recurring.DATE_RECURRING_PAYMENT (
	COD_DATE_REC_PAYMENT INT IDENTITY
	PRIMARY KEY
   ,COD_REC_PAYMENT INT NOT NULL
	REFERENCES Recurring.RECURRING_PAYMENT
   ,RECURRING_DATE DATETIME NOT NULL
   ,ENQUEUED INT DEFAULT 0 NOT NULL
   ,SEQUENCE INT DEFAULT 1 NOT NULL
)
GO

CREATE INDEX IX_Recurring_DATES_TO_ENQUEUE
ON Recurring.DATE_RECURRING_PAYMENT (ENQUEUED)
GO



GO

IF OBJECT_ID('Recurring.SCHEDULE_DATA_RECURRING') IS NOT NULL
	DROP TABLE Recurring.SCHEDULE_DATA_RECURRING;
GO
CREATE TABLE Recurring.SCHEDULE_DATA_RECURRING (
	COD_SCHED_DATA_REC INT IDENTITY
	PRIMARY KEY
   ,COD_DATE_REC_PAYMENT INT NOT NULL
	REFERENCES Recurring.DATE_RECURRING_PAYMENT
   ,COD_REC_PAYMENT INT NOT NULL
	REFERENCES Recurring.RECURRING_PAYMENT
   ,COD_SITUATION INT NOT NULL
	REFERENCES SITUATION
   ,RETRY_COUNT INT DEFAULT 1 NOT NULL
   ,RAN_AT DATETIME NOT NULL
   ,MESSAGE VARCHAR(255)
)
GO

IF OBJECT_ID('Recurring.TRANSACTION_RECURRING') IS NOT NULL
	DROP TABLE Recurring.TRANSACTION_RECURRING;
GO
CREATE TABLE Recurring.TRANSACTION_RECURRING (
	COD_TRAN_REC INT IDENTITY PRIMARY KEY
   ,COD_TRAN INT NOT NULL
   ,COD_REC_PAYMENT INT NOT NULL
   ,INSTALLMENT INT NOT NULL
   ,FOREIGN KEY (COD_REC_PAYMENT) REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
   ,FOREIGN KEY (COD_TRAN) REFERENCES [TRANSACTION] (COD_TRAN)
)
GO

IF OBJECT_ID('Recurring.CUSTOMER_RECURRING') IS NOT NULL
	DROP TABLE Recurring.CUSTOMER_RECURRING;
GO
CREATE TABLE Recurring.CUSTOMER_RECURRING (
	COD_CUSTOMER_REC INT IDENTITY PRIMARY KEY
   ,NAME VARCHAR(255)
   ,CPF_CNPJ VARCHAR(14)
   ,BIRTHDATE DATETIME
   ,EMAIL VARCHAR(255)
   ,PHONE VARCHAR(100)
   ,ZIPCODE VARCHAR(10)
   ,STREET VARCHAR(255)
   ,NUMBER VARCHAR(100)
   ,COMPLEMENT VARCHAR(100)
   ,NEIGHBORHOOD VARCHAR(100)
   ,CITY VARCHAR(100)
   ,UF VARCHAR(100)
   ,
);

GO

IF OBJECT_ID('Recurring.LINK_RECURRING') IS NOT NULL
	DROP TABLE Recurring.LINK_RECURRING;
GO
CREATE TABLE Recurring.LINK_RECURRING (
	COD_LINK_RECURRING INT IDENTITY PRIMARY KEY
   ,NAME VARCHAR(255) NOT NULL
   ,DESCRIPTION VARCHAR(255) NOT NULL
   ,DOCUMENT VARCHAR(255) NOT NULL
   ,COD_AFFILIATOR INT
   ,PERIOD_TYPE VARCHAR(100) NOT NULL
   ,INITIAL_DATE DATETIME
   ,FINAL_DATE DATETIME
   ,URL_CALLBACK VARCHAR(255)
   ,HAS_EMAIL INT DEFAULT 0
   ,COD_PAY_LINK INT
   ,FOREIGN KEY (COD_AFFILIATOR) REFERENCES AFFILIATOR (COD_AFFILIATOR)
   ,FOREIGN KEY (COD_PAY_LINK) REFERENCES PAYMENT_LINK (COD_PAY_LINK)
   ,
);

GO

IF OBJECT_ID('Recurring.DATE_RECURRING_LINK') IS NOT NULL
	DROP TABLE Recurring.DATE_RECURRING_LINK;
GO
CREATE TABLE Recurring.DATE_RECURRING_LINK (
	COD_DATE_RECURRING_LINK INT IDENTITY PRIMARY KEY
   ,COD_PAY_LINK INT NOT NULL
   ,RECURRING_DATE DATETIME NOT NULL
   ,FOREIGN KEY (COD_PAY_LINK) REFERENCES PAYMENT_LINK (COD_PAY_LINK)
   ,
);

GO


IF OBJECT_ID('Recurring.RECURRING_SPLIT') IS NOT NULL
	DROP TABLE Recurring.RECURRING_SPLIT;
GO
CREATE TABLE Recurring.RECURRING_SPLIT (
	COD_REC_SPLIT INT PRIMARY KEY IDENTITY
   ,COD_EC INT NOT NULL
   ,COD_AFFILIATOR INT
   ,AMOUNT DECIMAL(22, 6)
   ,COD_REC_PAYMENT INT NOT NULL
   ,FOREIGN KEY (COD_EC) REFERENCES COMMERCIAL_ESTABLISHMENT (COD_EC)
   ,FOREIGN KEY (COD_AFFILIATOR) REFERENCES AFFILIATOR (COD_AFFILIATOR)
   ,FOREIGN KEY (COD_REC_PAYMENT) REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
)

GO

IF TYPE_ID('Recurring.TP_RECURRING_DATE') IS NOT NULL
	DROP TYPE Recurring.TP_RECURRING_DATE
GO
CREATE TYPE Recurring.TP_RECURRING_DATE AS TABLE
(
INTERVAL DATETIME
)

GO
IF OBJECT_ID('Recurring.SP_REG_RECURRING') IS NOT NULL
	DROP PROCEDURE Recurring.SP_REG_RECURRING;
GO
CREATE PROCEDURE Recurring.SP_REG_RECURRING (@NAME VARCHAR(255),
@DESCRIPTION VARCHAR(255),
@COD_AFF INT,
@DOCUMENT VARCHAR(255) = NULL,
@AMOUNT DECIMAL(22, 6),
@LINK_CODE VARCHAR(255) = NULL,
@PERIOD_TYPE VARCHAR(255) = NULL,
@INITIAL_DATA DATE = NULL,
@FINAL_DATA DATE = NULL,
@URL_CALLBACK VARCHAR(255) = NULL,
@HAS_EMAIL INT = NULL,
@BRAND VARCHAR(255),
@CARD_TOKEN VARCHAR(255),
@TP_DATE Recurring.TP_RECURRING_DATE READONLY,
@CUSTOMER_NAME VARCHAR(255),
@CUSTOMER_CPF_CNPJ VARCHAR(14),
@CUSTOMER_BIRTHDATE DATETIME,
@CUSTOMER_EMAIL VARCHAR(255),
@CUSTOMER_PHONE VARCHAR(255),
@CUSTOMER_ZIPCODE VARCHAR(255),
@CUSTOMER_STREET VARCHAR(255),
@CUSTOMER_NUMBER VARCHAR(255),
@CUSTOMER_COMPLEMENT VARCHAR(255) = NULL,
@CUSTOMER_NEIGH VARCHAR(255),
@CUSTOMER_CITY VARCHAR(255),
@CUSTOMER_UF VARCHAR(255),
@PAN VARCHAR(255),
@IS_SPLIT INT = 0,
@PROVIDERS ITEM_SPLIT READONLY)
AS
BEGIN
	DECLARE @COD_REC_PAYMENT INT = NULL;
	DECLARE @COD_CARD_TOKEN INT = NULL;
	DECLARE @COD_CUSTOMER_REC INT = NULL;

	SELECT
		@COD_CUSTOMER_REC = COD_CUSTOMER_REC
	FROM Recurring.CUSTOMER_RECURRING
	WHERE CPF_CNPJ = @CUSTOMER_CPF_CNPJ;
	IF @COD_CUSTOMER_REC IS NULL
	BEGIN
		INSERT INTO Recurring.CUSTOMER_RECURRING (NAME, CPF_CNPJ, BIRTHDATE, EMAIL, PHONE, ZIPCODE, STREET, NUMBER,
		COMPLEMENT, NEIGHBORHOOD, CITY, UF)
			VALUES (@CUSTOMER_NAME, @CUSTOMER_CPF_CNPJ, @CUSTOMER_BIRTHDATE, @CUSTOMER_EMAIL, @CUSTOMER_PHONE, @CUSTOMER_ZIPCODE, @CUSTOMER_STREET, @CUSTOMER_NUMBER, @CUSTOMER_COMPLEMENT, @CUSTOMER_NEIGH, @CUSTOMER_CITY, @CUSTOMER_UF);
		SET @COD_CUSTOMER_REC = @@identity;
	END
	ELSE
	BEGIN
		UPDATE Recurring.CUSTOMER_RECURRING
		SET NAME = @CUSTOMER_NAME
		   ,CPF_CNPJ = @CUSTOMER_CPF_CNPJ
		   ,BIRTHDATE = @CUSTOMER_BIRTHDATE
		   ,EMAIL = @CUSTOMER_EMAIL
		   ,PHONE = @CUSTOMER_PHONE
		   ,ZIPCODE = @CUSTOMER_ZIPCODE
		   ,STREET = @CUSTOMER_STREET
		   ,NUMBER = @CUSTOMER_NUMBER
		   ,COMPLEMENT = @CUSTOMER_COMPLEMENT
		   ,CITY = @CUSTOMER_CITY
		   ,UF = @CUSTOMER_UF
		WHERE Recurring.CUSTOMER_RECURRING.COD_CUSTOMER_REC = @COD_CUSTOMER_REC;
	END

	IF @LINK_CODE IS NOT NULL
	BEGIN
		SELECT
			NAME
		   ,LINK_RECURRING.DESCRIPTION
		   ,DOCUMENT
		   ,PL.COD_AFFILIATOR
		   ,PERIOD_TYPE
		   ,INITIAL_DATE
		   ,FINAL_DATE
		   ,LINK_RECURRING.URL_CALLBACK
		   ,HAS_EMAIL INTO #tmpLinkRecurring
		FROM Recurring.LINK_RECURRING
		JOIN PAYMENT_LINK PL
			ON LINK_RECURRING.COD_PAY_LINK = PL.COD_PAY_LINK
				AND PL.ACTIVE = 1
				AND EXPIRATION_DATE >= dbo.FN_FUS_UTF(GETDATE())
		WHERE PL.CODE = @LINK_CODE
		IF (SELECT
					COUNT(*)
				FROM #tmpLinkRecurring)
			<= 0
			THROW 60000, 'LINK_RECURRING NOT FOUND', 1;

		INSERT INTO Recurring.RECURRING_PAYMENT (NAME, DESCRIPTION, COD_EC, COD_SITUATION, AMOUNT, PERIOD_TYPE,
		INITIAL_DATE,
		FINAL_DATE, URL_CALLBACK, HAS_EMAIL, EMAIL, COD_CUSTOMER_REC,
		COD_AFFILIATOR)
			SELECT
				tmp.NAME
			   ,tmp.DESCRIPTION
			   ,CE.COD_EC
			   ,32
			   , -- GENERATED
				@AMOUNT
			   ,tmp.PERIOD_TYPE
			   ,tmp.INITIAL_DATE
			   ,tmp.FINAL_DATE
			   ,tmp.URL_CALLBACK
			   ,tmp.HAS_EMAIL
			   ,@CUSTOMER_EMAIL
			   ,@COD_CUSTOMER_REC
			   ,@COD_AFF
			FROM #tmpLinkRecurring tmp
			JOIN COMMERCIAL_ESTABLISHMENT CE
				ON tmp.COD_AFFILIATOR = CE.COD_AFFILIATOR
					AND CE.CPF_CNPJ = tmp.DOCUMENT
					AND CE.ACTIVE = 1
		SET @COD_REC_PAYMENT = @@identity;
		INSERT INTO Recurring.DATE_RECURRING_PAYMENT (COD_REC_PAYMENT, RECURRING_DATE)
			SELECT
				@COD_REC_PAYMENT
			   ,INITIAL_DATE
			FROM #tmpLinkRecurring
	END
	ELSE
	BEGIN
		DECLARE @COD_EC INT = NULL;
		SELECT
			@COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
		FROM COMMERCIAL_ESTABLISHMENT
		WHERE CPF_CNPJ = @DOCUMENT
		AND COD_AFFILIATOR = @COD_AFF
		AND ACTIVE = 1;
		INSERT INTO Recurring.RECURRING_PAYMENT (NAME, DESCRIPTION, COD_EC, COD_SITUATION, AMOUNT, PERIOD_TYPE,
		INITIAL_DATE,
		FINAL_DATE, URL_CALLBACK, HAS_EMAIL, EMAIL, COD_CUSTOMER_REC,
		COD_AFFILIATOR)
			VALUES (@NAME, @DESCRIPTION, @COD_EC, 32, @AMOUNT, @PERIOD_TYPE, @INITIAL_DATA, @FINAL_DATA, @URL_CALLBACK, @HAS_EMAIL, @CUSTOMER_EMAIL, @COD_CUSTOMER_REC, @COD_AFF);
		SET @COD_REC_PAYMENT = @@identity;
		INSERT INTO Recurring.DATE_RECURRING_PAYMENT (COD_REC_PAYMENT, RECURRING_DATE)
			SELECT
				@COD_REC_PAYMENT
			   ,TP.INTERVAL
			FROM @TP_DATE TP
	END
	IF @COD_REC_PAYMENT IS NULL
		THROW 60000, 'COULD NOT REGISTER [RECURRING_PAYMENT] ', 1;
	IF @IS_SPLIT = 1
	BEGIN
		INSERT INTO Recurring.RECURRING_SPLIT (COD_EC,
		COD_AFFILIATOR,
		AMOUNT,
		COD_REC_PAYMENT)
			SELECT
				COMMERCIAL_ESTABLISHMENT.COD_EC
			   ,@COD_AFF
			   ,TP.AMOUNT
			   ,@COD_REC_PAYMENT
			FROM COMMERCIAL_ESTABLISHMENT
			JOIN @PROVIDERS TP
				ON TP.DOC_MERCHANT = COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
					AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFF
					AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1;
		IF @@rowcount < 1
			THROW 70016, 'COULD NOT REGISTER [RECURRING_SPLIT]', 1;
	END;

	INSERT INTO Recurring.CARD_TOKEN (TOKEN, BRAND, COD_SITUATION, PAN)
		VALUES (@CARD_TOKEN, @BRAND, 32, @PAN);
	SET @COD_CARD_TOKEN = @@identity;
	IF @@rowcount < 1
		THROW 60000, 'COULD NOT REGISTER [CARD_TOKEN] ', 1;
	INSERT INTO ASS_RECURRING_TOKEN (COD_CARD_TOKEN, COD_REC_PAYMENT)
		VALUES (@COD_CARD_TOKEN, @COD_REC_PAYMENT);
	IF @@rowcount < 1
		THROW 60000, 'COULD NOT REGISTER [ASS_RECURRING_TOKEN] ', 1;
	SELECT
		@COD_REC_PAYMENT;
END
GO
GO


IF OBJECT_ID('Recurring.SP_UP_RECURRING') IS NOT NULL
	DROP PROCEDURE Recurring.SP_UP_RECURRING;
GO
CREATE PROCEDURE Recurring.SP_UP_RECURRING (@COD_REC_PAYMENT INT, @SITUATION VARCHAR(255))
AS
BEGIN

	DECLARE @CARD_TOKEN INT = NULL;
	DECLARE @CARD_SITUATION INT = NULL;
	DECLARE @RECURRING_SITUATION INT = NULL;

	SELECT
		@CARD_TOKEN = CT.COD_CARD_TOKEN
	FROM Recurring.ASS_RECURRING_TOKEN ART
	JOIN Recurring.CARD_TOKEN CT
		ON CT.COD_CARD_TOKEN = ART.COD_CARD_TOKEN
	WHERE ART.COD_REC_PAYMENT = @COD_REC_PAYMENT
	AND ART.ACTIVE = 1

	IF @CARD_TOKEN IS NULL
		THROW 60000, 'CARD TOKEN NOT FOUND', 1;

	SELECT
		@CARD_SITUATION = COD_SITUATION
	FROM CARD_TOKEN
	WHERE COD_CARD_TOKEN = @CARD_TOKEN;

	SELECT
		@RECURRING_SITUATION = COD_SITUATION
	FROM Recurring.RECURRING_PAYMENT
	WHERE COD_REC_PAYMENT = @RECURRING_SITUATION;

	IF @SITUATION = 'APPROVED'
	BEGIN

		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 3
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT;

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 3
		WHERE COD_CARD_TOKEN = @CARD_TOKEN;

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;
	END

	IF @SITUATION = 'FAILED'
	BEGIN
		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 7
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 7
		WHERE COD_CARD_TOKEN = @CARD_TOKEN

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;
	END

	IF @SITUATION = 'CANCELED'
	BEGIN
		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 6
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 6
		WHERE COD_CARD_TOKEN = @CARD_TOKEN
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;
	END

	IF @SITUATION = 'COMPENSATED'
	BEGIN
		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 34
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 34
		WHERE COD_CARD_TOKEN = @CARD_TOKEN
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;
	END
END
GO



IF OBJECT_ID('Recurring.SP_REG_ASS_TRAN_RECURRING') IS NOT NULL
	DROP PROCEDURE Recurring.SP_REG_ASS_TRAN_RECURRING;
GO
CREATE PROCEDURE Recurring.SP_REG_ASS_TRAN_RECURRING (@NSU VARCHAR(255),
@COD_REC_PAYMENT INT,
@CODE_REC VARCHAR(255),
@TRANDESCRIPTION VARCHAR(255))
AS
BEGIN

	DECLARE @service INT;

	DECLARE @NAME VARCHAR(255) = NULL;
	DECLARE @EMAIL VARCHAR(255) = NULL;
	DECLARE @COD_TRAN INT = NULL

	SELECT
		@service = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE NAME = 'RECURRING';

	SELECT
		@EMAIL = Recurring.RECURRING_PAYMENT.EMAIL
	   ,@NAME = Recurring.CUSTOMER_RECURRING.NAME
	FROM Recurring.RECURRING_PAYMENT
	JOIN Recurring.CUSTOMER_RECURRING
		ON RECURRING_PAYMENT.COD_CUSTOMER_REC = CUSTOMER_RECURRING.COD_CUSTOMER_REC
	WHERE Recurring.RECURRING_PAYMENT.COD_REC_PAYMENT = @COD_REC_PAYMENT

	IF @EMAIL IS NULL
		OR @NAME IS NULL
		THROW 70012, 'INVALID RECURRING PAYMENT CODE', 1;

	SELECT
		@COD_TRAN = [TRANSACTION].[COD_TRAN]
	FROM [TRANSACTION] WITH (NOLOCK)
	WHERE [CODE] = @NSU;

	IF @COD_TRAN IS NULL
		THROW 70012, 'INVALID CODE TRAN', 1;

	INSERT INTO [Recurring].TRANSACTION_RECURRING (COD_TRAN, COD_REC_PAYMENT, INSTALLMENT)
		VALUES (@COD_TRAN, @COD_REC_PAYMENT, 1);

	IF @@rowcount < 1
		THROW 70016, 'COULD NOT REGISTER [TRANSACTION_RECURRING]', 1;

	INSERT INTO [TRANSACTION_SERVICES] ([COD_ITEM_SERVICE],
	[COD_TRAN])
		VALUES (@service, @COD_TRAN);

	IF @@rowcount < 1
		THROW 70016, 'COULD NOT REGISTER [TRANSACTION_SERVICES]', 1;

	UPDATE [TRANSACTION]
	SET [CUSTOMER_EMAIL] = @EMAIL
	   ,[CUSTOMER_IDENTIFICATION] = @NAME
	   ,[DESCRIPTION] = @TRANDESCRIPTION
	   ,[TRACKING_TRANSACTION] = @COD_REC_PAYMENT
	WHERE [COD_TRAN] = @COD_TRAN;

END
GO


IF OBJECT_ID('SP_FD_EC_BY_DOC') IS NOT NULL
	DROP PROCEDURE SP_FD_EC_BY_DOC;
GO
CREATE PROCEDURE SP_FD_EC_BY_DOC (@DOCUMENT VARCHAR(255),
@COD_AFF INT,
@SERIAL VARCHAR(255))
AS
BEGIN
	SELECT
		CE.NAME
	   ,SERIAL
	FROM COMMERCIAL_ESTABLISHMENT CE
	JOIN BRANCH_EC B
		ON B.COD_EC = CE.COD_EC
	JOIN DEPARTMENTS_BRANCH DB
		ON B.COD_BRANCH = DB.COD_BRANCH
	LEFT JOIN ASS_DEPTO_EQUIP ADE
		ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
			AND ADE.ACTIVE = 1
	LEFT JOIN EQUIPMENT E
		ON ADE.COD_EQUIP = E.COD_EQUIP
			AND E.ACTIVE = 1
			AND E.SERIAL = @SERIAL
	WHERE CE.COD_AFFILIATOR = @COD_AFF
	AND CE.CPF_CNPJ = @DOCUMENT
	AND CE.ACTIVE = 1
END

GO


IF OBJECT_ID('Recurring.SP_FD_DATA_RECURRING') IS NOT NULL
	DROP PROCEDURE Recurring.SP_FD_DATA_RECURRING;
GO
CREATE PROCEDURE Recurring.SP_FD_DATA_RECURRING (@COD_REC_PAYMENT INT, @COD_AFFILIATOR INT)
AS
BEGIN
	SELECT
		RP.NAME
	   ,RP.DESCRIPTION
	   ,CE.NAME AS EC_NAME
	   ,CE.CPF_CNPJ
	   ,TRADUCTION_SITUATION.SITUATION_TR AS SITUATION
	   ,RP.AMOUNT
	   ,RP.PERIOD_TYPE
	   ,RP.INITIAL_DATE
	   ,RP.FINAL_DATE
	   ,RP.HAS_EMAIL
	   ,RP.EMAIL
	   ,RP.URL_CALLBACK
	FROM Recurring.RECURRING_PAYMENT RP
	JOIN COMMERCIAL_ESTABLISHMENT CE
		ON RP.COD_EC = CE.COD_EC
	JOIN TRADUCTION_SITUATION
		ON RP.COD_SITUATION = TRADUCTION_SITUATION.COD_SITUATION
	WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
	AND RP.COD_AFFILIATOR = @COD_AFFILIATOR
END
GO


IF OBJECT_ID('Recurring.SP_FD_TRANSACTION_RECURRING ') IS NOT NULL
	DROP PROCEDURE Recurring.SP_FD_TRANSACTION_RECURRING;
GO
CREATE PROCEDURE Recurring.SP_FD_TRANSACTION_RECURRING (@COD_REC_PAYMENT INT, @COD_AFFILIATOR INT)
AS
BEGIN
	SELECT
		[TRANSACTION].CODE AS NSU
	   ,[TRANSACTION].BRAND
	   ,[TRANSACTION].BRAZILIAN_DATE AS TRANSACTION_DATE
	   ,TS.SITUATION_TR AS SITUATION
	   ,TRANSACTION_RECURRING.INSTALLMENT
	FROM Recurring.RECURRING_PAYMENT RP
	JOIN Recurring.TRANSACTION_RECURRING
		ON TRANSACTION_RECURRING.COD_REC_PAYMENT = RP.COD_REC_PAYMENT
	JOIN [TRANSACTION] WITH (NOLOCK)
		ON TRANSACTION_RECURRING.COD_TRAN = [TRANSACTION].COD_TRAN
	JOIN TRADUCTION_SITUATION TS
		ON [TRANSACTION].COD_SITUATION = TS.COD_SITUATION
	WHERE RP.COD_REC_PAYMENT = @COD_REC_PAYMENT
	AND RP.COD_AFFILIATOR = @COD_AFFILIATOR

END
GO


IF OBJECT_ID('Recurring.SCHEDULE_DATA_RECURRING') IS NULL
BEGIN
	CREATE TABLE Recurring.SCHEDULE_DATA_RECURRING (
		COD_SCHED_DATA_REC INT IDENTITY PRIMARY KEY
	   ,COD_DATE_REC_PAYMENT INT NOT NULL
	   ,COD_REC_PAYMENT INT NOT NULL
	   ,COD_SITUATION INT NOT NULL
	   ,RETRY_COUNT INT NOT NULL DEFAULT (1)
	   ,RAN_AT DATETIME NOT NULL
	   ,[MESSAGE] VARCHAR(255) NULL
	   ,FOREIGN KEY (COD_REC_PAYMENT) REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
	   ,FOREIGN KEY (COD_DATE_REC_PAYMENT) REFERENCES Recurring.DATE_RECURRING_PAYMENT (COD_DATE_REC_PAYMENT)
	   ,FOREIGN KEY (COD_SITUATION) REFERENCES SITUATION (COD_SITUATION)
	);
END
GO

IF OBJECT_ID('Recurring.DATE_RECURRING_PAYMENT') IS NULL
BEGIN
	CREATE TABLE Recurring.DATE_RECURRING_PAYMENT (
		COD_DATE_REC_PAYMENT INT IDENTITY PRIMARY KEY
	   ,COD_REC_PAYMENT INT NOT NULL
	   ,RECURRING_DATE DATETIME NOT NULL
	   ,ENQUEUED INT NOT NULL DEFAULT (0)
	   ,[SEQUENCE] INT NOT NULL DEFAULT (1)
	   ,FOREIGN KEY (COD_REC_PAYMENT) REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
	);
END

IF OBJECT_ID('Recurring.QUEUE') IS NULL
BEGIN
	CREATE TABLE Recurring.QUEUE (
		COD_QUEUE INT PRIMARY KEY IDENTITY NOT NULL
	   ,CREATE_AT DATETIME NOT NULL DEFAULT (GETDATE())
	   ,RETRY_COUNT INT NOT NULL DEFAULT 0
	   ,COD_REC_PAYMENT INT NOT NULL REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
	   ,COD_DATE_REC_PAYMENT INT NOT NULL REFERENCES Recurring.DATE_RECURRING_PAYMENT (COD_DATE_REC_PAYMENT)
	   ,RUN_AT DATETIME NOT NULL
	   ,STARTED_PROCESSING DATETIME NULL
	   ,ENDED_PROCESSING DATETIME NULL
	   ,TO_DELETE INT NOT NULL DEFAULT (0)
	);
END
GO

GO
IF NOT EXISTS (SELECT
			object_id
		FROM sys.indexes
		WHERE NAME = 'IX_Recurring_DATES_TO_ENQUEUE')
	CREATE NONCLUSTERED INDEX IX_Recurring_DATES_TO_ENQUEUE ON Recurring.DATE_RECURRING_PAYMENT (ENQUEUED)

IF OBJECT_ID('Recurring.SP_LIST_RECURRING_PAYMENTS') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_LIST_RECURRING_PAYMENTS
END
GO
CREATE PROCEDURE Recurring.SP_LIST_RECURRING_PAYMENTS
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-28       Creation    
------------------------------------------------------------------------------------------*/
AS
BEGIN

	DECLARE @CURRENT_DATE DATETIME = GETDATE()

	SELECT
		Q.RETRY_COUNT
	   ,Q.COD_DATE_REC_PAYMENT
	   ,Q.COD_QUEUE
	   ,Q.RUN_AT
	   ,Q.STARTED_PROCESSING
	   ,Q.ENDED_PROCESSING
	   ,DRP.RECURRING_DATE
	   ,DRP.SEQUENCE
	   ,RP.COD_REC_PAYMENT
	   ,RP.DESCRIPTION
	   ,RP.AMOUNT
	   ,RP.NAME [RecurrencyName]
	   ,RP.INITIAL_DATE
	   ,RP.FINAL_DATE
	   ,RP.PERIOD_TYPE
	   ,RP.URL_CALLBACK
	   ,RP.HAS_EMAIL
	   ,CR.NAME
	   ,RP.EMAIL
	   ,CR.CPF_CNPJ
	   ,CR.BIRTHDATE
	   ,CR.PHONE
	   ,CR.ZIPCODE
	   ,CR.STREET
	   ,CR.NUMBER
	   ,CR.COMPLEMENT
	   ,CR.NEIGHBORHOOD
	   ,CR.CITY
	   ,CR.UF
	   ,'Brasil' [Country]
	   ,CT.TOKEN
	   ,CT.BRAND
	   ,RP.COD_EC
	   ,IIF(EXISTS (SELECT
				COD_REC_PAYMENT
			FROM Recurring.RECURRING_SPLIT rs
			WHERE rs.COD_REC_PAYMENT = Q.COD_REC_PAYMENT)
		, 1, 0) [HasSplit] INTO #toRun
	FROM Recurring.QUEUE Q
	JOIN Recurring.DATE_RECURRING_PAYMENT DRP
		ON Q.COD_DATE_REC_PAYMENT = DRP.COD_DATE_REC_PAYMENT
	JOIN Recurring.RECURRING_PAYMENT RP
		ON DRP.COD_REC_PAYMENT = RP.COD_REC_PAYMENT
			AND RP.ACTIVE = 1
	JOIN Recurring.CUSTOMER_RECURRING CR
		ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
	JOIN Recurring.ASS_RECURRING_TOKEN ART
		ON ART.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
	JOIN Recurring.CARD_TOKEN CT
		ON ART.COD_CARD_TOKEN = CT.COD_CARD_TOKEN
	WHERE Q.RUN_AT <= @CURRENT_DATE

	SELECT DISTINCT
		COD_EC INTO #Ecs
	FROM #toRun

	SELECT
		CE.COD_EC [Ec_Id]
	   ,CE.COD_AFFILIATOR
	   ,CE.TRADING_NAME [EC_NAME]
	   ,CE.CPF_CNPJ [EC_DOC]
	   ,CE.USER_ONLINE [EC_USER_ONLINE]
	   ,CE.PWD_ONLINE [EC_PWD_ONLINE]
	   ,E.SERIAL [EQP_SERIAL]
	   ,E.COD_EQUIP
	   ,ROW_NUMBER() OVER (PARTITION BY CE.COD_EC ORDER BY E.COD_EQUIP) Seq_Number INTO #Eqps
	FROM COMMERCIAL_ESTABLISHMENT CE
	JOIN BRANCH_EC BE
		ON CE.COD_EC = BE.COD_EC
	JOIN DEPARTMENTS_BRANCH DB
		ON DB.COD_BRANCH = BE.COD_BRANCH
	JOIN ASS_DEPTO_EQUIP ADE
		ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
			AND BE.ACTIVE = 1
	JOIN EQUIPMENT E
		ON ADE.COD_EQUIP = E.COD_EQUIP
			AND E.COD_MODEL = 6
			AND E.ACTIVE = 1
	WHERE CE.COD_EC IN (SELECT
			COD_EC
		FROM #Ecs)
	AND CE.ACTIVE = 1

	DELETE FROM #Eqps
	WHERE Seq_Number > 1

	SELECT
		tR.*
	   ,E2.*
	FROM #toRun tR
	JOIN #Eqps E2
		ON tR.COD_EC = E2.Ec_Id

END
GO

IF OBJECT_ID('Recurring.SP_START_PAYMENT_PROCESSING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_START_PAYMENT_PROCESSING
END
GO
CREATE PROCEDURE [Recurring].[SP_START_PAYMENT_PROCESSING]
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-29       Created   
------------------------------------------------------------------------------------------*/ (@COD_QUEUE INT)
AS
BEGIN
	DECLARE @STARTED_PROCESSING DATETIME;

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

		BEGIN TRANSACTION;

		SELECT
			@STARTED_PROCESSING = STARTED_PROCESSING
		FROM Recurring.QUEUE
		WHERE COD_QUEUE = @COD_QUEUE;

		IF @STARTED_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @STARTED_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE
			SET STARTED_PROCESSING = GETDATE()
			WHERE COD_QUEUE = @COD_QUEUE;

			SET @STARTED_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	DECLARE @Recurring_Active INT

	SET @Recurring_Active = IIF(
	EXISTS (SELECT
			Q.COD_QUEUE
		FROM RECURRING_PAYMENT RP
		JOIN QUEUE Q
			ON RP.COD_REC_PAYMENT = Q.COD_REC_PAYMENT
		WHERE Q.COD_QUEUE = @COD_QUEUE
		AND COD_SITUATION = 3)
	, 1, 0)

	IF @Recurring_Active = 0
	BEGIN
		SELECT
			'DELETED' [MESSAGE]
	END
	ELSE
	IF @STARTED_PROCESSING IS NULL
	BEGIN
		SELECT
			'SUCCESS' [MESSAGE];
	END
	ELSE
	BEGIN
		DECLARE @ENDED_PROCESSING DATETIME

		SELECT
			@ENDED_PROCESSING = ENDED_PROCESSING
		FROM Recurring.QUEUE
		WHERE COD_QUEUE = @COD_QUEUE

		IF @ENDED_PROCESSING IS NULL
			SELECT
				'STARTED' [MESSAGE];
		ELSE
			SELECT
				'ENDED' [MESSAGE];

	END
END
GO
GO
IF OBJECT_ID('Recurring.SP_END_PAYMENT_PROCESSING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_END_PAYMENT_PROCESSING
END
GO
CREATE PROCEDURE Recurring.SP_END_PAYMENT_PROCESSING
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-29       Created   
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT,
@COD_REC_PAYMENT INT,
@CurrentExecutionDate DATETIME,
@Sequence INT,
@PeriodType VARCHAR(64),
@FinalDate DATETIME,
@NSU VARCHAR(256),
@TranDescription VARCHAR(128),
@Email VARCHAR(256),
@Name VARCHAR(256),
@MailJsonData VARCHAR(MAX) = NULL,
@NotifyJsonData VARCHAR(MAX) = NULL)
AS
BEGIN
	DECLARE @ENDED_PROCESSING DATETIME = NULL;
	DECLARE @recurring INT;

	SELECT
		@recurring = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE NAME = 'RECURRING';

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

		BEGIN TRANSACTION;

		SELECT
			@ENDED_PROCESSING = ENDED_PROCESSING
		FROM Recurring.QUEUE
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		IF @ENDED_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @ENDED_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE
			SET ENDED_PROCESSING = GETDATE()
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

			SET @ENDED_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	IF NOT EXISTS (SELECT
				COD_REC_PAYMENT
			FROM Recurring.DATE_RECURRING_PAYMENT
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT
			AND COD_REC_PAYMENT = @COD_REC_PAYMENT)
		THROW 70012, 'INVALID RECURRING PAYMENT CODE', 1;

	DECLARE @Recurring_Active INT

	SET @Recurring_Active = IIF(
	EXISTS (SELECT
			Q.COD_QUEUE
		FROM RECURRING_PAYMENT RP
		JOIN QUEUE Q
			ON RP.COD_REC_PAYMENT = Q.COD_REC_PAYMENT
		WHERE Q.COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND COD_SITUATION = 3)
	, 1, 0)

	IF @Recurring_Active = 1
		AND @NSU IS NOT NULL
	BEGIN
		DECLARE @COD_TRAN INT = NULL

		SELECT
			@COD_TRAN = COD_TRAN
		FROM [TRANSACTION] WITH (NOLOCK)
		WHERE CODE = @NSU

		IF @COD_TRAN IS NULL
			THROW 70012, 'INVALID CODE TRAN', 1;

		DECLARE @COD_TRAN_DPL INT = NULL

		SELECT
			@COD_TRAN_DPL = @COD_TRAN
		FROM Recurring.TRANSACTION_RECURRING WITH (NOLOCK)
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND [INSTALLMENT] = @Sequence

		IF @COD_TRAN_DPL IS NOT NULL
			AND @COD_TRAN_DPL != @COD_TRAN
			THROW 70012, 'POSSIBLE DOUBLE CHARGE', 1

		IF @COD_TRAN_DPL IS NULL
		BEGIN
			INSERT INTO Recurring.TRANSACTION_RECURRING (COD_TRAN, COD_REC_PAYMENT, INSTALLMENT)
				VALUES (@COD_TRAN, @COD_REC_PAYMENT, @Sequence);

			INSERT INTO [TRANSACTION_SERVICES] (COD_ITEM_SERVICE, COD_TRAN)
				VALUES (@recurring, @COD_TRAN)

			UPDATE [TRANSACTION]
			SET [CUSTOMER_EMAIL] = @Email
			   ,[CUSTOMER_IDENTIFICATION] = @Name
			   ,[DESCRIPTION] = @TranDescription
			   ,[TRACKING_TRANSACTION] = @COD_REC_PAYMENT
			WHERE COD_TRAN = @COD_TRAN
		END
	END

	IF @Recurring_Active = 1
		AND @ENDED_PROCESSING IS NULL
	BEGIN

		IF @MailJsonData IS NOT NULL
		BEGIN
			INSERT INTO Recurring.QUEUE_MAIL (RETRY_COUNT, COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT, JSON_DATA)
				SELECT
					0
				   ,COD_REC_PAYMENT
				   ,COD_DATE_REC_PAYMENT
				   ,GETDATE()
				   ,@MailJsonData
				FROM Recurring.QUEUE
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;
		END

		IF @NotifyJsonData IS NOT NULL
		BEGIN
			INSERT INTO Recurring.QUEUE_NOTIFICATION (RETRY_COUNT, COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT, JSON_DATA)
				SELECT
					0
				   ,COD_REC_PAYMENT
				   ,COD_DATE_REC_PAYMENT
				   ,GETDATE()
				   ,@NotifyJsonData
				FROM Recurring.QUEUE
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;
		END

		INSERT INTO Recurring.SCHEDULE_DATA_RECURRING (COD_DATE_REC_PAYMENT, COD_REC_PAYMENT, COD_SITUATION, RETRY_COUNT, RAN_AT, MESSAGE)
			SELECT
				COD_DATE_REC_PAYMENT
			   ,COD_REC_PAYMENT
			   ,3
			   ,RETRY_COUNT
			   ,RUN_AT
			   ,'SUCCESS'
			FROM Recurring.QUEUE
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		DECLARE @NextExecutionDate DATETIME = NULL;

		SET @NextExecutionDate = Recurring.FN_NEXT_RECURRING_DATE(@CurrentExecutionDate, @PeriodType)

		IF @FinalDate IS NULL
			OR (@NextExecutionDate <= @FinalDate
			AND @FinalDate IS NOT NULL)
		BEGIN
			INSERT INTO Recurring.DATE_RECURRING_PAYMENT (COD_REC_PAYMENT, RECURRING_DATE, ENQUEUED, SEQUENCE)
				SELECT
					COD_REC_PAYMENT
				   ,@NextExecutionDate
				   ,0
				   ,(@Sequence + 1)
				FROM Recurring.DATE_RECURRING_PAYMENT
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT
		END

		EXEC Recurring.SP_ADD_NEW_PAYMENT @COD_REC_PAYMENT

		DELETE FROM Recurring.QUEUE
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		SELECT
			'SUCCESS' [MESSAGE];
	END
	ELSE
	IF @Recurring_Active = 0
	BEGIN
		SELECT
			'DELETED' [MESSAGE]
	END
	ELSE
	BEGIN
		SELECT
			'LOCKED' [MESSAGE];
	END
END
GO
GO

IF OBJECT_ID('Recurring.QUEUE_MAIL') IS NULL
BEGIN
	CREATE TABLE Recurring.QUEUE_MAIL (
		COD_QUEUE_MAIL INT PRIMARY KEY IDENTITY NOT NULL
	   ,CREATE_AT DATETIME NOT NULL DEFAULT (GETDATE())
	   ,RETRY_COUNT INT NOT NULL DEFAULT 0
	   ,COD_REC_PAYMENT INT NOT NULL REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
	   ,COD_DATE_REC_PAYMENT INT NOT NULL REFERENCES Recurring.DATE_RECURRING_PAYMENT (COD_DATE_REC_PAYMENT)
	   ,RUN_AT DATETIME NOT NULL
	   ,STARTED_PROCESSING DATETIME NULL
	   ,[JSON_DATA] VARCHAR(MAX) NULL
	);
END
GO

IF OBJECT_ID('Recurring.QUEUE_NOTIFICATION') IS NULL
BEGIN
	CREATE TABLE Recurring.QUEUE_NOTIFICATION (
		COD_QUEUE_NOTIFICATION INT PRIMARY KEY IDENTITY NOT NULL
	   ,CREATE_AT DATETIME NOT NULL DEFAULT (GETDATE())
	   ,RETRY_COUNT INT NOT NULL DEFAULT 0
	   ,COD_REC_PAYMENT INT NOT NULL REFERENCES Recurring.RECURRING_PAYMENT (COD_REC_PAYMENT)
	   ,COD_DATE_REC_PAYMENT INT NOT NULL REFERENCES Recurring.DATE_RECURRING_PAYMENT (COD_DATE_REC_PAYMENT)
	   ,RUN_AT DATETIME NOT NULL
	   ,STARTED_PROCESSING DATETIME NULL
	   ,[JSON_DATA] VARCHAR(MAX) NULL
	);
END
GO
IF OBJECT_ID('Recurring.SP_END_PAYMENT_PROCESSING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_END_PAYMENT_PROCESSING
END
GO
CREATE PROCEDURE Recurring.SP_END_PAYMENT_PROCESSING
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-29       Created   
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT,
@COD_REC_PAYMENT INT,
@CurrentExecutionDate DATETIME,
@Sequence INT,
@PeriodType VARCHAR(64),
@FinalDate DATETIME,
@NSU VARCHAR(256),
@TranDescription VARCHAR(128),
@Email VARCHAR(256),
@Name VARCHAR(256),
@MailJsonData VARCHAR(MAX) = NULL,
@NotifyJsonData VARCHAR(MAX) = NULL)
AS
BEGIN
	DECLARE @ENDED_PROCESSING DATETIME = NULL;

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

		BEGIN TRANSACTION;

		SELECT
			@ENDED_PROCESSING = ENDED_PROCESSING
		FROM Recurring.QUEUE
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		IF @ENDED_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @ENDED_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE
			SET ENDED_PROCESSING = GETDATE()
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

			SET @ENDED_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	IF NOT EXISTS (SELECT
				COD_REC_PAYMENT
			FROM Recurring.DATE_RECURRING_PAYMENT
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT
			AND COD_REC_PAYMENT = @COD_REC_PAYMENT)
		THROW 70012, 'INVALID RECURRING PAYMENT CODE', 1;

	IF @NSU IS NOT NULL
	BEGIN
		DECLARE @COD_TRAN INT = NULL

		SELECT
			@COD_TRAN = COD_TRAN
		FROM [TRANSACTION] WITH (NOLOCK)
		WHERE CODE = @NSU

		IF @COD_TRAN IS NULL
			THROW 70012, 'INVALID CODE TRAN', 1;

		DECLARE @COD_TRAN_DPL INT = NULL

		SELECT
			@COD_TRAN_DPL = @COD_TRAN
		FROM Recurring.TRANSACTION_RECURRING WITH (NOLOCK)
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND [INSTALLMENT] = @Sequence

		IF @COD_TRAN_DPL IS NOT NULL
			AND @COD_TRAN_DPL != @COD_TRAN
			THROW 70012, 'POSSIBLE DOUBLE CHARGE', 1

		IF @COD_TRAN_DPL IS NULL
		BEGIN
			INSERT INTO Recurring.TRANSACTION_RECURRING (COD_TRAN, COD_REC_PAYMENT, INSTALLMENT)
				VALUES (@COD_TRAN, @COD_REC_PAYMENT, @Sequence);

			INSERT INTO [TRANSACTION_SERVICES] (COD_ITEM_SERVICE, COD_TRAN)
				VALUES (17, @COD_TRAN)

			UPDATE [TRANSACTION]
			SET [CUSTOMER_EMAIL] = @Email
			   ,[CUSTOMER_IDENTIFICATION] = @Name
			   ,[DESCRIPTION] = @TranDescription
			   ,[TRACKING_TRANSACTION] = @COD_REC_PAYMENT
			WHERE COD_TRAN = @COD_TRAN
		END
	END

	IF @ENDED_PROCESSING IS NULL
	BEGIN

		IF @MailJsonData IS NOT NULL
		BEGIN
			INSERT INTO Recurring.QUEUE_MAIL (RETRY_COUNT, COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT, JSON_DATA)
				SELECT
					0
				   ,COD_REC_PAYMENT
				   ,COD_DATE_REC_PAYMENT
				   ,GETDATE()
				   ,@MailJsonData
				FROM Recurring.QUEUE
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;
		END

		IF @NotifyJsonData IS NOT NULL
		BEGIN
			INSERT INTO Recurring.QUEUE_NOTIFICATION (RETRY_COUNT, COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT, JSON_DATA)
				SELECT
					0
				   ,COD_REC_PAYMENT
				   ,COD_DATE_REC_PAYMENT
				   ,GETDATE()
				   ,@NotifyJsonData
				FROM Recurring.QUEUE
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;
		END

		INSERT INTO Recurring.SCHEDULE_DATA_RECURRING (COD_DATE_REC_PAYMENT, COD_REC_PAYMENT, COD_SITUATION, RETRY_COUNT, RAN_AT, MESSAGE)
			SELECT
				COD_DATE_REC_PAYMENT
			   ,COD_REC_PAYMENT
			   ,3
			   ,RETRY_COUNT
			   ,RUN_AT
			   ,'SUCCESS'
			FROM Recurring.QUEUE
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		DECLARE @NextExecutionDate DATETIME = NULL;

		SET @NextExecutionDate = Recurring.FN_NEXT_RECURRING_DATE(@CurrentExecutionDate, @PeriodType)

		IF @FinalDate IS NOT NULL
			AND @NextExecutionDate < @FinalDate
		BEGIN
			INSERT INTO Recurring.DATE_RECURRING_PAYMENT (COD_REC_PAYMENT, RECURRING_DATE, ENQUEUED, SEQUENCE)
				SELECT
					COD_REC_PAYMENT
				   ,@NextExecutionDate
				   ,0
				   ,(@Sequence + 1)
				FROM Recurring.DATE_RECURRING_PAYMENT
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT
		END

		DELETE FROM Recurring.QUEUE
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		SELECT
			'SUCCESS' [MESSAGE];
	END
	ELSE
	BEGIN
		SELECT
			'LOCKED' [MESSAGE];
	END
END
GO

IF OBJECT_ID('Recurring.SP_RETRY_PAYMENT_PROCESSING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_RETRY_PAYMENT_PROCESSING
END
GO
CREATE PROCEDURE Recurring.SP_RETRY_PAYMENT_PROCESSING
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-30       Created   
------------------------------------------------------------------------------------------*/ (@COD_QUEUE INT,
@REASON VARCHAR(255),
@RAN_AT DATETIME)
AS
BEGIN

	IF EXISTS (SELECT
				COD_QUEUE
			FROM Recurring.QUEUE
			WHERE COD_QUEUE = @COD_QUEUE
			AND RUN_AT > @RAN_AT)
	BEGIN
		RETURN;
	END

	INSERT INTO Recurring.SCHEDULE_DATA_RECURRING (COD_DATE_REC_PAYMENT, COD_REC_PAYMENT, COD_SITUATION, RETRY_COUNT, RAN_AT, MESSAGE)
		SELECT
			COD_DATE_REC_PAYMENT
		   ,COD_REC_PAYMENT
		   ,7
		   ,RETRY_COUNT
		   ,RUN_AT
		   ,@REASON
		FROM Recurring.QUEUE
		WHERE COD_QUEUE = @COD_QUEUE

	DECLARE @DATE_TO_RUN DATETIME = DATEADD(DAY, 1, CAST(GETDATE() AS DATE))

	UPDATE Recurring.QUEUE
	SET [RUN_AT] = @DATE_TO_RUN
	   ,[RETRY_COUNT] = (RETRY_COUNT + 1)
	   ,[STARTED_PROCESSING] = NULL
	WHERE COD_QUEUE = @COD_QUEUE

END
GO

IF OBJECT_ID('Recurring.SP_START_MAIL_SENDING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_START_MAIL_SENDING
END
GO
CREATE PROCEDURE Recurring.SP_START_MAIL_SENDING
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-30       Created
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT)
AS
BEGIN
	DECLARE @START_PROCESSING DATETIME = NULL

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

		BEGIN TRANSACTION;

		SELECT
			@START_PROCESSING = STARTED_PROCESSING
		FROM Recurring.QUEUE_MAIL
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT

		IF @START_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @START_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE_MAIL
			SET STARTED_PROCESSING = GETDATE()
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

			SET @START_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	IF @START_PROCESSING IS NULL
		SELECT
			'SUCCESS' [MESSAGE]
	ELSE
		SELECT
			'LOCKED' [MESSAGE]

END
GO

IF OBJECT_ID('Recurring.SP_END_MAIL_SENDING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_END_MAIL_SENDING
END
GO
CREATE PROCEDURE Recurring.SP_END_MAIL_SENDING
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-30       Created   
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT)
AS
BEGIN

	INSERT INTO Recurring.SCHEDULE_DATA_RECURRING (COD_DATE_REC_PAYMENT, COD_REC_PAYMENT, COD_SITUATION, RETRY_COUNT, RAN_AT, MESSAGE)
		SELECT
			COD_DATE_REC_PAYMENT
		   ,COD_REC_PAYMENT
		   ,3
		   ,RETRY_COUNT
		   ,dbo.FN_FUS_UTF(GETDATE())
		   ,'EMAIL ENVIADO'
		FROM Recurring.QUEUE_MAIL
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT

	DELETE FROM Recurring.QUEUE_MAIL
	WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT

END
GO


IF OBJECT_ID('Recurring.SP_START_PAYMENT_NOTIFICATION') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_START_PAYMENT_NOTIFICATION
END
GO
CREATE PROCEDURE Recurring.SP_START_PAYMENT_NOTIFICATION
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-30       Created   
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT)
AS
BEGIN
	DECLARE @START_PROCESSING DATETIME = NULL

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION;

		SELECT
			@START_PROCESSING = STARTED_PROCESSING
		FROM Recurring.QUEUE_NOTIFICATION
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT

		IF @START_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @START_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE_NOTIFICATION
			SET STARTED_PROCESSING = GETDATE()
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

			SET @START_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	IF @START_PROCESSING IS NULL
		SELECT
			'SUCCESS' [MESSAGE]
	ELSE
		SELECT
			'LOCKED' [MESSAGE]

END
GO

IF OBJECT_ID('Recurring.SP_END_PAYMENT_NOTIFICATION') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_END_PAYMENT_NOTIFICATION
END
GO
CREATE PROCEDURE Recurring.SP_END_PAYMENT_NOTIFICATION
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-30       Created   
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT)
AS
BEGIN

	INSERT INTO Recurring.SCHEDULE_DATA_RECURRING (COD_DATE_REC_PAYMENT, COD_REC_PAYMENT, COD_SITUATION, RETRY_COUNT, RAN_AT, MESSAGE)
		SELECT
			COD_DATE_REC_PAYMENT
		   ,COD_REC_PAYMENT
		   ,3
		   ,RETRY_COUNT
		   ,dbo.FN_FUS_UTF(GETDATE())
		   ,'NOTIFICACAO ENVIADA'
		FROM Recurring.QUEUE_NOTIFICATION
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT

	DELETE FROM Recurring.QUEUE_NOTIFICATION
	WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT

END
GO

IF OBJECT_ID('Recurring.SP_RETRY_MAIL') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_RETRY_MAIL
END
GO
CREATE PROCEDURE Recurring.SP_RETRY_MAIL
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-31       Created   
------------------------------------------------------------------------------------------*/
AS
BEGIN
	DECLARE @CURRENT_DATE DATETIME = GETDATE()

	SELECT
		Q.RETRY_COUNT
	   ,Q.COD_DATE_REC_PAYMENT
	   ,Q.COD_QUEUE_MAIL [COD_QUEUE]
	   ,Q.RUN_AT
	   ,Q.STARTED_PROCESSING
	   ,Q.JSON_DATA
	   ,DRP.RECURRING_DATE
	   ,RP.COD_REC_PAYMENT
	   ,RP.DESCRIPTION
	   ,RP.AMOUNT
	   ,RP.NAME [RecurrencyName]
	   ,RP.INITIAL_DATE
	   ,RP.FINAL_DATE
	   ,RP.PERIOD_TYPE
	   ,RP.URL_CALLBACK
	   ,RP.HAS_EMAIL
	   ,CR.EMAIL
	   ,CR.NAME
	   ,CR.CPF_CNPJ
	   ,CR.BIRTHDATE
	   ,CR.PHONE
	   ,CR.ZIPCODE
	   ,CR.STREET
	   ,CR.NUMBER
	   ,CR.COMPLEMENT
	   ,CR.NEIGHBORHOOD
	   ,CR.CITY
	   ,CR.UF
	   ,RP.COD_EC
	   ,CE.TRADING_NAME [EC_NAME]
	   ,CE.CPF_CNPJ [EC_DOC]
	FROM Recurring.QUEUE_MAIL Q
	JOIN Recurring.DATE_RECURRING_PAYMENT DRP
		ON Q.COD_DATE_REC_PAYMENT = DRP.COD_DATE_REC_PAYMENT
	JOIN Recurring.RECURRING_PAYMENT RP
		ON DRP.COD_REC_PAYMENT = RP.COD_REC_PAYMENT
			AND RP.ACTIVE = 1
	JOIN Recurring.CUSTOMER_RECURRING CR
		ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
	JOIN COMMERCIAL_ESTABLISHMENT CE
		ON RP.COD_EC = CE.COD_EC
	WHERE Q.RUN_AT <= @CURRENT_DATE
	AND DATEDIFF(MINUTE, Q.CREATE_AT, @CURRENT_DATE) > 5

END
GO

IF OBJECT_ID('Recurring.SP_RETRY_NOTIFY') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_RETRY_NOTIFY
END
GO
CREATE PROCEDURE Recurring.SP_RETRY_NOTIFY
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-07-31       Created   
------------------------------------------------------------------------------------------*/
AS
BEGIN
	DECLARE @CURRENT_DATE DATETIME = GETDATE()

	SELECT
		Q.RETRY_COUNT
	   ,Q.COD_DATE_REC_PAYMENT
	   ,Q.COD_QUEUE_NOTIFICATION [COD_QUEUE]
	   ,Q.RUN_AT
	   ,Q.STARTED_PROCESSING
	   ,Q.JSON_DATA
	   ,DRP.RECURRING_DATE
	   ,RP.COD_REC_PAYMENT
	   ,RP.DESCRIPTION
	   ,RP.AMOUNT
	   ,RP.NAME [RecurrencyName]
	   ,RP.INITIAL_DATE
	   ,RP.FINAL_DATE
	   ,RP.PERIOD_TYPE
	   ,RP.URL_CALLBACK
	   ,RP.HAS_EMAIL
	   ,CR.EMAIL
	   ,CR.NAME
	   ,CR.CPF_CNPJ
	   ,CR.BIRTHDATE
	   ,CR.PHONE
	   ,CR.ZIPCODE
	   ,CR.STREET
	   ,CR.NUMBER
	   ,CR.COMPLEMENT
	   ,CR.NEIGHBORHOOD
	   ,CR.CITY
	   ,CR.UF
	   ,RP.COD_EC
	   ,CE.TRADING_NAME [EC_NAME]
	   ,CE.CPF_CNPJ [EC_DOC]
	FROM Recurring.QUEUE_NOTIFICATION Q
	JOIN Recurring.DATE_RECURRING_PAYMENT DRP
		ON Q.COD_DATE_REC_PAYMENT = DRP.COD_DATE_REC_PAYMENT
	JOIN Recurring.RECURRING_PAYMENT RP
		ON DRP.COD_REC_PAYMENT = RP.COD_REC_PAYMENT
			AND RP.ACTIVE = 1
	JOIN Recurring.CUSTOMER_RECURRING CR
		ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
	JOIN COMMERCIAL_ESTABLISHMENT CE
		ON RP.COD_EC = CE.COD_EC
	WHERE Q.RUN_AT <= @CURRENT_DATE
	AND DATEDIFF(MINUTE, Q.CREATE_AT, @CURRENT_DATE) > 5

END
GO

IF OBJECT_ID('Recurring.FN_NEXT_RECURRING_DATE') IS NOT NULL
BEGIN
	DROP FUNCTION Recurring.FN_NEXT_RECURRING_DATE
END
GO
CREATE FUNCTION Recurring.FN_NEXT_RECURRING_DATE
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-03       Created    
------------------------------------------------------------------------------------------*/ (@Previous_Date DATETIME,
@Type VARCHAR(64))
RETURNS DATETIME
AS
BEGIN

	DECLARE @NEXT_DATE DATETIME = NULL

	SET @NEXT_DATE =
	CASE
		WHEN @Type = 'Weekly' THEN DATEADD(DAY, 7, @Previous_Date)
		WHEN @Type = 'Monthly' THEN DATEADD(MONTH, 1, @Previous_Date)
		WHEN @Type = 'Quarterly' THEN DATEADD(MONTH, 3, @Previous_Date)
		WHEN @Type = 'BiAnnual' THEN DATEADD(MONTH, 6, @Previous_Date)
		WHEN @Type = 'Yearly' THEN DATEADD(YEAR, 1, @Previous_Date)
	END;

	RETURN @NEXT_DATE;
END
GO

IF OBJECT_ID('Recurring.SP_ADD_NEW_PAYMENT') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_ADD_NEW_PAYMENT
END
GO
CREATE PROCEDURE Recurring.SP_ADD_NEW_PAYMENT
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-03       Created    
------------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN

	SELECT
		DRP.COD_REC_PAYMENT
	   ,DRP.COD_DATE_REC_PAYMENT
	   ,DRP.RECURRING_DATE
	   ,RP.PERIOD_TYPE
	   ,RP.FINAL_DATE
	   ,DRP.SEQUENCE
	   ,Recurring.FN_NEXT_RECURRING_DATE(DRP.RECURRING_DATE, RP.PERIOD_TYPE) NEXT_DATE INTO #toProcess
	FROM Recurring.DATE_RECURRING_PAYMENT DRP
	JOIN Recurring.RECURRING_PAYMENT RP
		ON RP.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
			AND RP.ACTIVE = 1
			AND RP.COD_SITUATION != 7
	JOIN Recurring.CUSTOMER_RECURRING CR
		ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
	JOIN Recurring.ASS_RECURRING_TOKEN ART
		ON ART.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
	JOIN Recurring.CARD_TOKEN CT
		ON ART.COD_CARD_TOKEN = CT.COD_CARD_TOKEN
	WHERE DRP.ENQUEUED = 0
	AND RP.COD_REC_PAYMENT = @COD_REC_PAYMENT

	INSERT INTO Recurring.DATE_RECURRING_PAYMENT (COD_REC_PAYMENT, RECURRING_DATE, SEQUENCE)
		SELECT
			tp.COD_REC_PAYMENT
		   ,tp.NEXT_DATE
		   ,(tp.SEQUENCE + 1)
		FROM #toProcess tp
		WHERE tp.SEQUENCE = 1
		AND (tp.FINAL_DATE IS NULL
		OR tp.[FINAL_DATE] >= tp.NEXT_DATE)

	UPDATE DRP
	SET ENQUEUED = 1
	FROM Recurring.DATE_RECURRING_PAYMENT DRP
	JOIN #toProcess t
		ON DRP.COD_DATE_REC_PAYMENT = t.COD_DATE_REC_PAYMENT
		AND t.SEQUENCE = 1

	SELECT DISTINCT
		DRP.COD_REC_PAYMENT
	   ,DRP.COD_DATE_REC_PAYMENT
	   ,DRP.RECURRING_DATE INTO #toInsert
	FROM Recurring.DATE_RECURRING_PAYMENT DRP
	JOIN #toProcess tP
		ON DRP.COD_REC_PAYMENT = tP.COD_REC_PAYMENT
	WHERE DRP.ENQUEUED = 0

	INSERT INTO Recurring.QUEUE (COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT)
		SELECT
			p.COD_REC_PAYMENT
		   ,p.COD_DATE_REC_PAYMENT
		   ,p.RECURRING_DATE
		FROM #toInsert p
		LEFT JOIN Recurring.QUEUE Q
			ON p.COD_DATE_REC_PAYMENT = Q.COD_DATE_REC_PAYMENT
		WHERE Q.COD_QUEUE IS NULL

	UPDATE DRP
	SET ENQUEUED = 1
	FROM Recurring.DATE_RECURRING_PAYMENT DRP
	JOIN #toInsert p
		ON p.COD_DATE_REC_PAYMENT = DRP.COD_DATE_REC_PAYMENT
END
GO
IF OBJECT_ID('Recurring.SP_RM_PAYMENT') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_RM_PAYMENT
END
GO
CREATE PROCEDURE Recurring.SP_RM_PAYMENT
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-03       Created    
-----------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN
	DECLARE @TODAY DATETIME = GETDATE()

	DELETE FROM Recurring.QUEUE
	WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND STARTED_PROCESSING IS NULL
		OR (ENDED_PROCESSING IS NULL
		AND DATEDIFF(MINUTE, STARTED_PROCESSING, @TODAY) > 5)

	UPDATE Recurring.QUEUE
	SET QUEUE.TO_DELETE = 1
	WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

END
GO
IF OBJECT_ID('Recurring.SP_LIST_SPLIT_INFO') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_LIST_SPLIT_INFO
END
GO
CREATE PROCEDURE Recurring.SP_LIST_SPLIT_INFO
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-05       Created   
------------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN

	SELECT
		COD_REC_SPLIT
	   ,RS.COD_EC
	   ,CE.CPF_CNPJ [EC_DOC]
	   ,RS.COD_AFFILIATOR
	   ,A.CPF_CNPJ [AFF_DOC]
	   ,AMOUNT
	FROM Recurring.RECURRING_SPLIT RS WITH (NOLOCK)
	JOIN AFFILIATOR A WITH (NOLOCK)
		ON RS.COD_AFFILIATOR = A.COD_AFFILIATOR
	JOIN COMMERCIAL_ESTABLISHMENT CE WITH (NOLOCK)
		ON RS.COD_EC = CE.COD_EC
	WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

END
GO

IF OBJECT_ID('Recurring.SP_GIVE_UP_PAYMENT') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_GIVE_UP_PAYMENT
END
GO
CREATE PROCEDURE Recurring.SP_GIVE_UP_PAYMENT
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-07       Created   
------------------------------------------------------------------------------------------*/ (@COD_DATE_REC_PAYMENT INT,
@COD_REC_PAYMENT INT,
@Reason VARCHAR(256),
@MailJsonData VARCHAR(MAX) = NULL,
@NotifyJsonData VARCHAR(MAX) = NULL)
AS
BEGIN
	DECLARE @ENDED_PROCESSING DATETIME = NULL;

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION;

		SELECT
			@ENDED_PROCESSING = ENDED_PROCESSING
		FROM Recurring.QUEUE
		WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		IF @ENDED_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @ENDED_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE
			SET ENDED_PROCESSING = GETDATE()
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

			SET @ENDED_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	IF @ENDED_PROCESSING IS NULL
	BEGIN

		IF @MailJsonData IS NOT NULL
		BEGIN
			INSERT INTO Recurring.QUEUE_MAIL (RETRY_COUNT, COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT, JSON_DATA)
				SELECT
					0
				   ,COD_REC_PAYMENT
				   ,COD_DATE_REC_PAYMENT
				   ,GETDATE()
				   ,@MailJsonData
				FROM Recurring.QUEUE
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;
		END

		IF @NotifyJsonData IS NOT NULL
		BEGIN
			INSERT INTO Recurring.QUEUE_NOTIFICATION (RETRY_COUNT, COD_REC_PAYMENT, COD_DATE_REC_PAYMENT, RUN_AT, JSON_DATA)
				SELECT
					0
				   ,COD_REC_PAYMENT
				   ,COD_DATE_REC_PAYMENT
				   ,GETDATE()
				   ,@NotifyJsonData
				FROM Recurring.QUEUE
				WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;
		END

		INSERT INTO Recurring.SCHEDULE_DATA_RECURRING (COD_DATE_REC_PAYMENT, COD_REC_PAYMENT, COD_SITUATION, RETRY_COUNT, RAN_AT, MESSAGE)
			SELECT
				COD_DATE_REC_PAYMENT
			   ,COD_REC_PAYMENT
			   ,7
			   ,RETRY_COUNT
			   ,RUN_AT
			   ,@Reason
			FROM Recurring.QUEUE
			WHERE COD_DATE_REC_PAYMENT = @COD_DATE_REC_PAYMENT;

		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 7
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 7
		FROM Recurring.ASS_RECURRING_TOKEN ACT
		JOIN Recurring.CARD_TOKEN C
			ON C.COD_CARD_TOKEN = ACT.COD_CARD_TOKEN
		WHERE ACT.COD_REC_PAYMENT = @COD_REC_PAYMENT

		DELETE FROM Recurring.QUEUE
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT;

		SELECT
			'SUCCESS' [MESSAGE];
	END
	ELSE
	BEGIN
		SELECT
			'LOCKED' [MESSAGE];
	END
END
GO

IF OBJECT_ID('Recurring.SP_REMOVE_QUEUE_ITEM') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_REMOVE_QUEUE_ITEM
END
GO
CREATE PROCEDURE Recurring.SP_REMOVE_QUEUE_ITEM
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-07       Created   
------------------------------------------------------------------------------------------*/ (@COD_QUEUE INT)
AS
BEGIN
	DECLARE @ENDED_PROCESSING DATETIME = NULL;

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION;

		SELECT
			@ENDED_PROCESSING = ENDED_PROCESSING
		FROM Recurring.QUEUE
		WHERE COD_QUEUE = @COD_QUEUE;

		IF @ENDED_PROCESSING IS NULL
			OR DATEDIFF(MINUTE, @ENDED_PROCESSING, GETDATE()) > 5
		BEGIN
			UPDATE Recurring.QUEUE
			SET ENDED_PROCESSING = GETDATE()
			WHERE COD_QUEUE = @COD_QUEUE;

			SET @ENDED_PROCESSING = NULL;

			COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
		END

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT
			'FAILED TO LOCK QUEUE ITEM' [MESSAGE]
		   ,ERROR_MESSAGE() [ErrorMessage]
		   ,ERROR_NUMBER() AS ErrorNumber;
		RETURN;
	END CATCH

	DELETE FROM Recurring.QUEUE
	WHERE COD_QUEUE = @COD_QUEUE

END
GO
IF OBJECT_ID('Recurring.SP_UP_RECURRING') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_UP_RECURRING
END
GO
CREATE PROCEDURE Recurring.SP_UP_RECURRING (@COD_REC_PAYMENT INT, @SITUATION VARCHAR(255))
AS
BEGIN

	DECLARE @CARD_TOKEN INT = NULL;
	DECLARE @CARD_SITUATION INT = NULL;
	DECLARE @RECURRING_SITUATION INT = NULL;

	SELECT
		@CARD_TOKEN = CT.COD_CARD_TOKEN
	FROM Recurring.ASS_RECURRING_TOKEN ART
	JOIN Recurring.CARD_TOKEN CT
		ON CT.COD_CARD_TOKEN = ART.COD_CARD_TOKEN
	WHERE ART.COD_REC_PAYMENT = @COD_REC_PAYMENT
	AND ART.ACTIVE = 1

	IF @CARD_TOKEN IS NULL
		THROW 60000, 'CARD TOKEN NOT FOUND', 1;

	SELECT
		@CARD_SITUATION = COD_SITUATION
	FROM CARD_TOKEN
	WHERE COD_CARD_TOKEN = @CARD_TOKEN;

	SELECT
		@RECURRING_SITUATION = COD_SITUATION
	FROM Recurring.RECURRING_PAYMENT
	WHERE COD_REC_PAYMENT = @RECURRING_SITUATION;

	IF @SITUATION = 'APPROVED'
	BEGIN

		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 3
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT;

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 3
		WHERE COD_CARD_TOKEN = @CARD_TOKEN;

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;

		EXEC Recurring.SP_ADD_NEW_PAYMENT @COD_REC_PAYMENT
	END

	IF @SITUATION = 'FAILED'
	BEGIN
		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 7
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 7
		WHERE COD_CARD_TOKEN = @CARD_TOKEN

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;
	END

	IF @SITUATION = 'CANCELED'
	BEGIN
		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 6
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 6
		WHERE COD_CARD_TOKEN = @CARD_TOKEN
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;

		EXEC Recurring.SP_RM_PAYMENT @COD_REC_PAYMENT
	END

	IF @SITUATION = 'COMPENSATED'
	BEGIN
		UPDATE Recurring.RECURRING_PAYMENT
		SET COD_SITUATION = 34
		WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [RECURRING_PAYMENT] ', 1;

		UPDATE Recurring.CARD_TOKEN
		SET COD_SITUATION = 34
		WHERE COD_CARD_TOKEN = @CARD_TOKEN
		AND COD_SITUATION = 3

		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE [CARD_TOKEN] ', 1;
	END
END
GO

-- report

IF OBJECT_ID('Recurring.SP_REPORT_PLANS') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_REPORT_PLANS
END
GO
CREATE PROCEDURE Recurring.SP_REPORT_PLANS
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-27       Created   
------------------------------------------------------------------------------------------*/ (@DATE_FROM DATETIME,
@DATE_UNTIL DATETIME,
@PLAN_NAME VARCHAR(128) = NULL,
@COD_EC TP_STRING_CODE READONLY,
@COD_AF TP_STRING_CODE READONLY,
@BILLING_TYPE TP_STRING_CODE READONLY,
@COD_SITUATION TP_STRING_CODE READONLY,
@PAGE_SIZE INT = 15,
@PAGE INT = 1,
@TOTAL INT OUTPUT)
AS
BEGIN
	SET @PLAN_NAME = '%' + @PLAN_NAME + '%';
	DECLARE @SQL NVARCHAR(MAX)
		   ,@OFFSET INT = ((@PAGE - 1) * @PAGE_SIZE)
	DECLARE @IdsSituation CODE_TYPE
	DECLARE @TODAY DATE = CAST(GETDATE() AS DATE)

	SET @SQL = 'FROM Recurring.DATE_RECURRING_PAYMENT DRP
    JOIN Recurring.RECURRING_PAYMENT (NOLOCK) RP ON RP.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
    JOIN TRADUCTION_SITUATION TS on RP.COD_SITUATION = TS.COD_SITUATION 
    JOIN Recurring.CUSTOMER_RECURRING CR ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
    JOIN COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC
    LEFT JOIN AFFILIATOR A ON RP.COD_AFFILIATOR = A.COD_AFFILIATOR
    WHERE DRP.RECURRING_DATE BETWEEN @DATE_FROM AND @DATE_UNTIL '

	IF EXISTS (SELECT
				CODE
			FROM @COD_EC)
		SET @SQL += ' AND CE.CPF_CNPJ IN (SELECT CODE FROM @COD_EC) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_AF)
		SET @SQL += ' AND A.CPF_CNPJ IN (SELECT CODE FROM @COD_AF) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_SITUATION)
	BEGIN
		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'active')
			INSERT INTO @IdsSituation
				VALUES (3)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'canceled')
			INSERT INTO @IdsSituation
				VALUES (6)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'expired')
		BEGIN
			SET @SQL += ' AND (RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) OR (RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY ) )'
		END
		ELSE
		BEGIN
			SET @SQL += ' AND RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) '
		END
	END

	IF @PLAN_NAME IS NOT NULL
		SET @SQL += ' AND (RP.NAME LIKE @PLAN_NAME OR RP.DESCRIPTION LIKE @PLAN_NAME) '

	SET @SQL = 'SELECT @TOTAL = COUNT(*) FROM (SELECT DISTINCT RP.COD_REC_PAYMENT ' + @SQL + ') tmp; ' + '
        SELECT DISTINCT
            RP.COD_REC_PAYMENT,
            RP.NAME [PLAN_NAME], 
            CR.CPF_CNPJ,
            ''CREDIT'' [BILLING_TYPE],
            PERIOD_TYPE,
            AMOUNT,
            FINAL_DATE,
            (CASE WHEN RP.COD_SITUATION = 6 THEN ''canceled'' WHEN RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY THEN ''expired'' WHEN RP.COD_SITUATION = 3 THEN ''active'' WHEN RP.COD_SITUATION = 7 THEN ''failed'' ELSE TS.SITUATION_TR END )  [STATUS]
    ' + @SQL + ' ORDER BY RP.COD_REC_PAYMENT OFFSET @OFFSET ROWS FETCH NEXT @PAGE_SIZE ROWS ONLY '

	EXEC sp_executesql @SQL
					  ,N'
        @DATE_FROM DATETIME,
        @DATE_UNTIL DATETIME,
        @PLAN_NAME VARCHAR(128),
        @COD_EC TP_STRING_CODE READONLY,
        @COD_AF TP_STRING_CODE READONLY,
        @BILLING_TYPE TP_STRING_CODE READONLY,
        @COD_SITUATION CODE_TYPE READONLY,
        @PAGE_SIZE INT,
        @PAGE INT,
        @OFFSET INT,
        @TODAY DATE,
        @TOTAL INT OUTPUT
    '
					  ,@DATE_FROM = @DATE_FROM
					  ,@DATE_UNTIL = @DATE_UNTIL
					  ,@PLAN_NAME = @PLAN_NAME
					  ,@COD_EC = @COD_EC
					  ,@COD_AF = @COD_AF
					  ,@BILLING_TYPE = @BILLING_TYPE
					  ,@COD_SITUATION = @IdsSituation
					  ,@PAGE_SIZE = @PAGE_SIZE
					  ,@PAGE = @PAGE
					  ,@OFFSET = @OFFSET
					  ,@TODAY = @TODAY
					  ,@TOTAL = @TOTAL OUTPUT;
END
GO



IF OBJECT_ID('Recurring.SP_REPORT_STAT_PLANS') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_REPORT_STAT_PLANS
END
GO
CREATE PROCEDURE Recurring.SP_REPORT_STAT_PLANS
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-27       Created   
------------------------------------------------------------------------------------------*/ (@DATE_FROM DATETIME,
@DATE_UNTIL DATETIME,
@PLAN_NAME VARCHAR(128) = NULL,
@COD_EC TP_STRING_CODE READONLY,
@COD_AF TP_STRING_CODE READONLY,
@BILLING_TYPE TP_STRING_CODE READONLY,
@COD_SITUATION TP_STRING_CODE READONLY)
AS
BEGIN

	SET @PLAN_NAME = '%' + @PLAN_NAME + '%';

	DECLARE @QUERY NVARCHAR(MAX)
	DECLARE @IdsSituation CODE_TYPE
	DECLARE @TODAY DATE = CAST(GETDATE() AS DATE)

	SET @QUERY = '
    SELECT DISTINCT COD_REC_PAYMENT
    INTO #PlansInRange
    FROM Recurring.DATE_RECURRING_PAYMENT
    WHERE RECURRING_DATE BETWEEN @DATE_FROM AND @DATE_UNTIL;
    
    SELECT 
           count(*) [Total], 
           COALESCE(SUM(AMOUNT), 0) [TPV], 
           COALESCE((SUM(AMOUNT) / COUNT(*)), 0) [Average_Amount], 
           COALESCE(SUM(AMOUNT), 0) [CREDIT], 
           CAST( 0 AS DECIMAL(22,6)) [BILLET]  
    FROM Recurring.RECURRING_PAYMENT RP
    JOIN COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC
    LEFT JOIN AFFILIATOR A ON RP.COD_AFFILIATOR = A.COD_AFFILIATOR
    WHERE RP.COD_REC_PAYMENT IN (SELECT COD_REC_PAYMENT FROM #PlansInRange)
    '
	IF EXISTS (SELECT
				CODE
			FROM @COD_EC)
		SET @QUERY += ' AND CE.CPF_CNPJ IN (SELECT CODE FROM @COD_EC) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_AF)
		SET @QUERY += ' AND A.CPF_CNPJ IN (SELECT CODE FROM @COD_AF) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_SITUATION)
	BEGIN
		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'active')
			INSERT INTO @IdsSituation
				VALUES (3)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'canceled')
			INSERT INTO @IdsSituation
				VALUES (6)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'expired')
		BEGIN
			SET @QUERY += ' AND (RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) OR (RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY ) )'
		END
		ELSE
		BEGIN
			SET @QUERY += ' AND RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) '
		END
	END

	IF @PLAN_NAME IS NOT NULL
		SET @QUERY += ' AND (RP.NAME LIKE @PLAN_NAME OR RP.DESCRIPTION LIKE @PLAN_NAME) '

	EXEC sp_executesql @QUERY
					  ,N'
        @DATE_FROM DATETIME,
        @DATE_UNTIL DATETIME,
        @PLAN_NAME VARCHAR(128),
        @COD_EC TP_STRING_CODE READONLY,
        @COD_AF TP_STRING_CODE READONLY,
        @BILLING_TYPE TP_STRING_CODE READONLY,
        @COD_SITUATION CODE_TYPE READONLY,
        @TODAY DATE
    '
					  ,@DATE_FROM = @DATE_FROM
					  ,@DATE_UNTIL = @DATE_UNTIL
					  ,@PLAN_NAME = @PLAN_NAME
					  ,@COD_EC = @COD_EC
					  ,@COD_AF = @COD_AF
					  ,@BILLING_TYPE = @BILLING_TYPE
					  ,@COD_SITUATION = @IdsSituation
					  ,@TODAY = @TODAY
END
GO


IF OBJECT_ID('Recurring.SP_DETAIL_PLAN') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_DETAIL_PLAN
END
GO
CREATE PROCEDURE Recurring.SP_DETAIL_PLAN
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-28       Created   
------------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN

	SELECT
		RP.COD_REC_PAYMENT
	   ,RP.COD_CUSTOMER_REC
	   ,RP.COD_EC
	   ,RP.NAME
	   ,RP.DESCRIPTION
	   ,RP.AMOUNT
	   ,RP.FINAL_DATE
	   ,RP.PERIOD_TYPE
	   ,RP.EMAIL
	   ,CR.NAME [Client]
	   ,CR.CPF_CNPJ [DOC_CLIENT]
	   ,IIF(EXISTS (SELECT
				COD_REC_SPLIT
			FROM Recurring.RECURRING_SPLIT RS
			WHERE RS.COD_REC_PAYMENT = RP.COD_REC_PAYMENT)
		, 1, 0) [Has_Split]
	   ,CR.CITY
	   ,CR.COMPLEMENT
	   ,CR.NEIGHBORHOOD
	   ,CR.NUMBER [STREET_NUMBER]
	   ,CR.STREET
	   ,CR.UF
	   ,CR.ZIPCODE
	   ,CR.PHONE
	   ,CE.TRADING_NAME [EC_NAME]
	   ,CE.CPF_CNPJ [EC_DOC]
	FROM Recurring.RECURRING_PAYMENT(NOLOCK) RP
	JOIN Recurring.CUSTOMER_RECURRING(NOLOCK) CR
		ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
	JOIN COMMERCIAL_ESTABLISHMENT(NOLOCK) CE
		ON RP.COD_EC = CE.COD_EC
	WHERE RP.COD_REC_PAYMENT = @COD_REC_PAYMENT

END
GO


IF OBJECT_ID('Recurring.SP_LIST_SPLIT_INFO') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_LIST_SPLIT_INFO
END
GO
CREATE PROCEDURE Recurring.SP_LIST_SPLIT_INFO
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-05       Created   
------------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN

	SELECT
		COD_REC_SPLIT
	   ,RS.COD_EC
	   ,CE.CPF_CNPJ [EC_DOC]
	   ,RS.COD_AFFILIATOR
	   ,A.CPF_CNPJ [AFF_DOC]
	   ,AMOUNT
	   ,CE.TRADING_NAME [EC_NAME]
	   ,A.NAME [AFF_NAME]
	   ,CE.TRADING_NAME [NAME_EC]
	FROM Recurring.RECURRING_SPLIT RS WITH (NOLOCK)
	JOIN AFFILIATOR A WITH (NOLOCK)
		ON RS.COD_AFFILIATOR = A.COD_AFFILIATOR
	JOIN COMMERCIAL_ESTABLISHMENT CE WITH (NOLOCK)
		ON RS.COD_EC = CE.COD_EC
	WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

END
GO

IF OBJECT_ID('Recurring.SP_PAYMENT_HISTORY') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_PAYMENT_HISTORY
END
GO
CREATE PROCEDURE Recurring.SP_PAYMENT_HISTORY
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-28       Created   
------------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN

	SELECT
		DRP.COD_REC_PAYMENT
	   ,DRP.COD_DATE_REC_PAYMENT
	   ,DRP.RECURRING_DATE
	   ,DRP.ENQUEUED
	   ,DRP.SEQUENCE
	   ,NULL COD_SITUATION
	   ,(CASE
			WHEN TR.COD_TRAN_REC IS NOT NULL THEN 'success'
			WHEN NOT EXISTS (SELECT TOP 1
						COD_SCHED_DATA_REC
					FROM Recurring.SCHEDULE_DATA_RECURRING(NOLOCK) SDR
					WHERE DRP.COD_DATE_REC_PAYMENT = SDR.COD_DATE_REC_PAYMENT) THEN 'ready'
			ELSE 'failed'
		END) [LAST_SITUATION]
	   ,(SELECT TOP 1
				RAN_AT
			FROM Recurring.SCHEDULE_DATA_RECURRING(NOLOCK) SDR
			WHERE DRP.COD_DATE_REC_PAYMENT = SDR.COD_DATE_REC_PAYMENT
			AND MESSAGE LIKE 'SUCCESS')
	   ,Q.RETRY_COUNT
	   ,IIF(T.Amount IS NULL, RP.Amount, T.Amount) [Amount]
	   ,T.CODE [Nsu]
	FROM Recurring.DATE_RECURRING_PAYMENT(NOLOCK) DRP
	JOIN Recurring.RECURRING_PAYMENT RP
		ON RP.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
	LEFT JOIN Recurring.QUEUE(NOLOCK) Q
		ON DRP.COD_DATE_REC_PAYMENT = Q.COD_DATE_REC_PAYMENT
	LEFT JOIN Recurring.TRANSACTION_RECURRING(NOLOCK) TR
		ON TR.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
			AND TR.INSTALLMENT = DRP.SEQUENCE
	LEFT JOIN [TRANSACTION](NOLOCK) T
		ON T.COD_TRAN = TR.COD_TRAN
	WHERE DRP.COD_REC_PAYMENT = @COD_REC_PAYMENT

END
GO

IF OBJECT_ID('Recurring.SP_EXPORT_PLANS') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_EXPORT_PLANS
END
GO
CREATE PROCEDURE Recurring.SP_EXPORT_PLANS
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-09-09       Created   
------------------------------------------------------------------------------------------*/ (@DATE_FROM DATETIME,
@DATE_UNTIL DATETIME,
@PLAN_NAME VARCHAR(128) = NULL,
@COD_EC TP_STRING_CODE READONLY,
@COD_AF TP_STRING_CODE READONLY,
@BILLING_TYPE TP_STRING_CODE READONLY,
@COD_SITUATION TP_STRING_CODE READONLY)
AS
BEGIN
	SET @PLAN_NAME = '%' + @PLAN_NAME + '%';
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @IdsSituation CODE_TYPE;
	DECLARE @TODAY DATE = CAST(GETDATE() AS DATE);

	SET @SQL = '
        SELECT DISTINCT
            RP.COD_REC_PAYMENT,
            RP.COD_CUSTOMER_REC,
            RP.COD_EC,
            RP.NAME,
            RP.DESCRIPTION,
            RP.AMOUNT,
            RP.FINAL_DATE,
            RP.PERIOD_TYPE,
            RP.EMAIL,
            CR.NAME [Client],
            CR.CPF_CNPJ [DOC_CLIENT],
            IIF(EXISTS(SELECT COD_REC_SPLIT FROM Recurring.RECURRING_SPLIT RS WHERE RS.COD_REC_PAYMENT = RP.COD_REC_PAYMENT), 1, 0) [Has_Split],
            CR.CITY,
            CR.COMPLEMENT,
            CR.NEIGHBORHOOD,
            CR.NUMBER [STREET_NUMBER],
            CR.STREET,
            CR.UF,
            CR.ZIPCODE,
            CR.PHONE,
            CE.TRADING_NAME [EC_NAME],
            CE.CPF_CNPJ [EC_DOC],
            A.NAME [AFF_NAME],
            A.CPF_CNPJ [AFF_DOC],
            ''CREDIT'' [BILLING_TYPE],
            (CASE WHEN RP.COD_SITUATION = 6 THEN ''canceled''
                  WHEN RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY THEN ''expired''
                  WHEN RP.COD_SITUATION = 3 THEN ''active''
                  WHEN RP.COD_SITUATION = 7 THEN ''failed''
                  ELSE TS.SITUATION_TR
                END )  [STATUS]
        FROM Recurring.DATE_RECURRING_PAYMENT DRP
                 JOIN Recurring.RECURRING_PAYMENT (NOLOCK) RP ON RP.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
                 JOIN TRADUCTION_SITUATION TS on RP.COD_SITUATION = TS.COD_SITUATION
                 JOIN Recurring.CUSTOMER_RECURRING CR ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
                 JOIN COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC
                 LEFT JOIN AFFILIATOR A ON RP.COD_AFFILIATOR = A.COD_AFFILIATOR
            WHERE DRP.RECURRING_DATE BETWEEN @DATE_FROM AND @DATE_UNTIL '

	IF EXISTS (SELECT
				CODE
			FROM @COD_EC)
		SET @SQL += ' AND CE.CPF_CNPJ IN (SELECT CODE FROM @COD_EC) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_AF)
		SET @SQL += ' AND A.CPF_CNPJ IN (SELECT CODE FROM @COD_AF) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_SITUATION)
	BEGIN
		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'active')
			INSERT INTO @IdsSituation
				VALUES (3)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'canceled')
			INSERT INTO @IdsSituation
				VALUES (6)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'expired')
		BEGIN
			SET @SQL += ' AND (RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) OR (RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY ) )'
		END
		ELSE
		BEGIN
			SET @SQL += ' AND RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) '
		END
	END

	IF @PLAN_NAME IS NOT NULL
		SET @SQL += ' AND (RP.NAME LIKE @PLAN_NAME OR RP.DESCRIPTION LIKE @PLAN_NAME) '

	EXEC sp_executesql @SQL
					  ,N'
        @DATE_FROM DATETIME,
        @DATE_UNTIL DATETIME,
        @PLAN_NAME VARCHAR(128),
        @COD_EC TP_STRING_CODE READONLY,
        @COD_AF TP_STRING_CODE READONLY,
        @BILLING_TYPE TP_STRING_CODE READONLY,
        @COD_SITUATION CODE_TYPE READONLY,
        @TODAY DATE
    '
					  ,@DATE_FROM = @DATE_FROM
					  ,@DATE_UNTIL = @DATE_UNTIL
					  ,@PLAN_NAME = @PLAN_NAME
					  ,@COD_EC = @COD_EC
					  ,@COD_AF = @COD_AF
					  ,@BILLING_TYPE = @BILLING_TYPE
					  ,@COD_SITUATION = @IdsSituation
					  ,@TODAY = @TODAY;
END
GO



-- novo

IF NOT EXISTS (SELECT
			1
		FROM [sys].[COLUMNS]
		WHERE NAME = N'AMOUNT'
		AND object_id = OBJECT_ID(N'Recurring.LINK_RECURRING'))
BEGIN

	ALTER TABLE Recurring.LINK_RECURRING
	ADD AMOUNT DECIMAL(22, 6)

END;

GO

IF TYPE_ID('Recurring.TP_RECURRING_LINK') IS NOT NULL
	DROP TYPE Recurring.TP_RECURRING_LINK
GO
CREATE TYPE Recurring.TP_RECURRING_LINK AS TABLE
(
NAME VARCHAR(255),
DESCRIPTION VARCHAR(255),
PERIOD_TYPE VARCHAR(255),
INITIAL_DATE DATETIME,
FINAL_DATE DATETIME,
URL_CALLBACK VARCHAR(255),
HAS_EMAIL INT,
AMOUNT DECIMAL(22, 6)
)
GO

IF NOT EXISTS (SELECT
			1
		FROM [sys].[COLUMNS]
		WHERE NAME = N'IS_RECURRING'
		AND object_id = OBJECT_ID(N'PAYMENT_LINK'))
BEGIN
	ALTER TABLE PAYMENT_LINK
	ADD IS_RECURRING INT DEFAULT 0;

END

GO


UPDATE PAYMENT_LINK
SET IS_RECURRING = 0
WHERE IS_RECURRING IS NULL

GO

IF OBJECT_ID('SP_REG_PAYMENT_LINK') IS NOT NULL
	DROP PROCEDURE SP_REG_PAYMENT_LINK;
GO

CREATE PROCEDURE SP_REG_PAYMENT_LINK (@CODE VARCHAR(255),
@COD_AFFILIATOR INT,
@CPF_CNPJ VARCHAR(255),
@EXP_DATE DATETIME,
@ORDER_IDENT VARCHAR(255),
@DESCRIPTION VARCHAR(255),
@COD_TYPE_PR INT,
@COD_SHIPP_TYPE INT,
@SHIPP_NAME VARCHAR(255) = NULL,
@PRICE DECIMAL(22, 6) = NULL,
@ZIPCODE VARCHAR(100) = NULL,
@MAX_INSTALLMENT INT,
@IS_VARIABLE INT,
@IS_CUSTOMER_INTEREST INT,
@IS_SPLIT INT,
@URL_CALLBACK VARCHAR(255) = NULL,
@HAS_CUSTOMER INT = 0,
@IS_RECURRING INT = 0,
@CUSTOMER_EMAIL VARCHAR(100) = NULL,
@CUSTOMER_NAME VARCHAR(100) = NULL,
@CUSTOMER_PHONE VARCHAR(100) = NULL,
@CUSTOMER_ZIPCODE VARCHAR(100) = NULL,
@CUSTOMER_STREET VARCHAR(100) = NULL,
@CUSTOMER_NUMBER VARCHAR(100) = NULL,
@CUSTOMER_NEIGHBORHOOD VARCHAR(100) = NULL,
@CUSTOMER_CITY VARCHAR(100) = NULL,
@CUSTOMER_UF VARCHAR(100) = NULL,
@PRODUCTS TP_LINK_PROD READONLY,
@PROVIDERS ITEM_SPLIT READONLY,
@DATA_RECURRING Recurring.TP_RECURRING_LINK READONLY)
AS
BEGIN

	DECLARE @COD_PAY_LINK INT;
	DECLARE @COD_EC INT;

	SELECT
		@COD_EC = COD_EC
	FROM COMMERCIAL_ESTABLISHMENT
	WHERE COD_AFFILIATOR = @COD_AFFILIATOR
	AND CPF_CNPJ = @CPF_CNPJ;

	INSERT INTO PAYMENT_LINK (CODE,
	EXPIRATION_DATE,
	COD_AFFILIATOR,
	COD_EC,
	ORDER_IDENT,
	COD_TYPE_PR,
	MAX_INSTALLMENT,
	DESCRIPTION,
	IS_VARIABLE,
	IS_CUSTOMER_INTEREST,
	IS_SPLIT,
	URL_CALLBACK,
	IS_RECURRING)
		VALUES (@CODE, @EXP_DATE, @COD_AFFILIATOR, @COD_EC, @ORDER_IDENT, @COD_TYPE_PR, @MAX_INSTALLMENT, @DESCRIPTION, @IS_VARIABLE, @IS_CUSTOMER_INTEREST, @IS_SPLIT, @URL_CALLBACK, @IS_RECURRING);

	IF @@rowcount < 1
		THROW 70016, 'COULD NOT REGISTER [PAYMENT_LINK]', 1;

	SET @COD_PAY_LINK = @@identity;

	INSERT INTO PRODUCTS_LINK (NAME,
	QTY,
	AMOUNT,
	COD_PAY_LINK)
		SELECT
			NAME
		   ,QTY
		   ,AMOUNT
		   ,@COD_PAY_LINK
		FROM @PRODUCTS AS PRODS;

	INSERT INTO SHIPPING_LINK (NAME,
	COD_SHIPP_TYPE,
	PRICE,
	ZIPCODE,
	COD_PAY_LINK)
		VALUES (@SHIPP_NAME, @COD_SHIPP_TYPE, @PRICE, @ZIPCODE, @COD_PAY_LINK);

	IF @IS_SPLIT = 1
	BEGIN

		INSERT INTO SPLIT_LINK (COD_EC,
		COD_AFFILIATOR,
		AMOUNT,
		COD_PAY_LINK)
			SELECT
				COMMERCIAL_ESTABLISHMENT.COD_EC
			   ,@COD_AFFILIATOR
			   ,TP.AMOUNT
			   ,@COD_PAY_LINK
			FROM COMMERCIAL_ESTABLISHMENT
			JOIN @PROVIDERS TP
				ON TP.DOC_MERCHANT = COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
					AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFFILIATOR
					AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1;

		IF @@rowcount < 1
			THROW 70016, 'COULD NOT REGISTER [SPLIT_LINK]', 1;
	END;

	IF @HAS_CUSTOMER = 1
	BEGIN

		INSERT INTO CUSTOMER_LINK (NAME,
		EMAIL_ADDRESS,
		PHONE_NUMBER,
		ZIPCODE,
		STREET,
		NUMBER,
		NEIGHBORHOOD,
		CITY,
		UF,
		COD_PAY_LINK)
			VALUES (@CUSTOMER_NAME, @CUSTOMER_EMAIL, @CUSTOMER_PHONE, @CUSTOMER_ZIPCODE, @CUSTOMER_STREET, @CUSTOMER_NUMBER, @CUSTOMER_NEIGHBORHOOD, @CUSTOMER_CITY, @CUSTOMER_UF, @COD_PAY_LINK);

		IF @@rowcount < 1
			THROW 70016, 'COULD NOT REGISTER [CUSTOMER_LINK]', 1;
	END;

	IF @IS_RECURRING = 1
	BEGIN

		INSERT INTO Recurring.LINK_RECURRING (NAME, DESCRIPTION, DOCUMENT, COD_AFFILIATOR, PERIOD_TYPE, INITIAL_DATE,
		FINAL_DATE, URL_CALLBACK, AMOUNT, COD_PAY_LINK, HAS_EMAIL)
			SELECT
				data_req.NAME
			   ,data_req.DESCRIPTION
			   ,@CPF_CNPJ
			   ,@COD_AFFILIATOR
			   ,data_req.PERIOD_TYPE
			   ,data_req.INITIAL_DATE
			   ,data_req.FINAL_DATE
			   ,data_req.URL_CALLBACK
			   ,data_req.AMOUNT
			   ,@COD_PAY_LINK
			   ,data_req.HAS_EMAIL
			FROM @DATA_RECURRING data_req

	END
END;

GO


IF OBJECT_ID('SP_FD_DATA_LINK') IS NOT NULL
	DROP PROCEDURE SP_FD_DATA_LINK;
GO
CREATE PROCEDURE SP_FD_DATA_LINK (@CODE VARCHAR(255))
AS
BEGIN
	SELECT
		PAYMENT_LINK.CODE
	   ,PAYMENT_LINK.COD_EC
	   ,PAYMENT_LINK.COD_AFFILIATOR
	   ,PAYMENT_LINK.ORDER_IDENT
	   ,COMMERCIAL_ESTABLISHMENT.NAME AS EC_NAME
	   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS EC_CPF_CNPJ
	   ,AFFILIATOR.NAME AS AFF_NAME
	   ,AFFILIATOR.CPF_CNPJ AS AFF_CPF_CNPJ
	   ,THEMES.LOGO_AFFILIATE
	   ,THEMES.LOGO_HEADER_AFFILIATE
	   ,THEMES.COLOR_HEADER
	   ,PAYMENT_LINK.EXPIRATION_DATE
	   ,PAYMENT_LINK.MAX_INSTALLMENT
	   ,PAYMENT_LINK.IS_VARIABLE
	   ,PAYMENT_LINK.IS_CUSTOMER_INTEREST
	   ,PAYMENT_LINK.IS_SPLIT
	   ,PAYMENT_LINK.URL_CALLBACK
	   ,PAYMENT_LINK.DESCRIPTION
	   ,PAYMENT_LINK.IS_RECURRING
	FROM PAYMENT_LINK
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = PAYMENT_LINK.COD_EC
	JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = PAYMENT_LINK.COD_AFFILIATOR
	JOIN THEMES
		ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
			AND THEMES.ACTIVE = 1
	WHERE PAYMENT_LINK.CODE = @CODE
	AND PAYMENT_LINK.ACTIVE = 1
	AND PAYMENT_LINK.EXPIRATION_DATE >= dbo.FN_FUS_UTF(GETDATE());
END;
GO

IF OBJECT_ID('Recurring.SP_FD_DATA_RECURRING_LINK') IS NOT NULL
	DROP PROCEDURE Recurring.SP_FD_DATA_RECURRING_LINK;
GO
CREATE PROCEDURE Recurring.SP_FD_DATA_RECURRING_LINK (@CODE VARCHAR(255))
AS
BEGIN

	SELECT
		lr.NAME
	   ,lr.DESCRIPTION
	   ,lr.PERIOD_TYPE
	   ,lr.INITIAL_DATE
	   ,lr.FINAL_DATE
	   ,lr.HAS_EMAIL
	   ,lr.AMOUNT
	FROM PAYMENT_LINK
	JOIN Recurring.LINK_RECURRING lr
		ON lr.COD_PAY_LINK = PAYMENT_LINK.COD_PAY_LINK
	WHERE CODE = @CODE
	AND ACTIVE = 1

END

GO

IF OBJECT_ID('SP_FD_EC_BY_DOC') IS NOT NULL
	DROP PROCEDURE SP_FD_EC_BY_DOC;
GO
CREATE PROCEDURE SP_FD_EC_BY_DOC (@DOCUMENT VARCHAR(255),
@COD_AFF INT)
AS
BEGIN
	SELECT
		CE.NAME
	   ,(SELECT TOP 1
				SERIAL
			FROM DEPARTMENTS_BRANCH DB
			JOIN ASS_DEPTO_EQUIP ADE
				ON ADE.COD_DEPTO_BRANCH = DB.COD_DEPTO_BRANCH
				AND ADE.ACTIVE = 1
			JOIN EQUIPMENT E
				ON E.COD_EQUIP = ADE.COD_EQUIP
				AND E.ACTIVE = 1
				AND COD_MODEL = 6
			WHERE DB.COD_BRANCH = B.COD_BRANCH)
		AS SERIAL

	FROM COMMERCIAL_ESTABLISHMENT CE
	JOIN BRANCH_EC B
		ON B.COD_EC = CE.COD_EC
	WHERE CE.COD_AFFILIATOR = @COD_AFF
	AND CE.CPF_CNPJ = @DOCUMENT
	AND CE.ACTIVE = 1

END
GO


IF OBJECT_ID('Recurring.SP_FD_DATA_EMAIL_RECURRING') IS NOT NULL
	DROP PROCEDURE Recurring.SP_FD_DATA_EMAIL_RECURRING;
GO
CREATE PROCEDURE Recurring.SP_FD_DATA_EMAIL_RECURRING (@COD_REC_PAYMENT INT)
AS
BEGIN
	SELECT
		COMMERCIAL_ESTABLISHMENT.NAME AS EC_NAME
	   ,rp.NAME AS REC_NAME
	   ,rp.DESCRIPTION
	   ,rp.AMOUNT
	   ,rp.PERIOD_TYPE
	   ,rp.FINAL_DATE
	   ,rp.INITIAL_DATE
	   ,AFFILIATOR.NAME AS AffName
	   ,THEMES.COLOR_HEADER
	   ,THEMES.LOGO_HEADER_AFFILIATE
	FROM Recurring.RECURRING_PAYMENT rp
	LEFT JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = rp.COD_AFFILIATOR
	LEFT JOIN THEMES
		ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
			AND THEMES.ACTIVE = 1
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = rp.COD_EC
	WHERE rp.COD_REC_PAYMENT = @COD_REC_PAYMENT

END

GO

IF OBJECT_ID('Recurring.SP_FD_RECURRING_CUSTOMER') IS NOT NULL
	DROP PROCEDURE Recurring.SP_FD_RECURRING_CUSTOMER;
GO
CREATE PROCEDURE Recurring.SP_FD_RECURRING_CUSTOMER (@COD_REC INT)
AS
BEGIN
	SELECT
		rp.NAME AS REC_NAME
	   ,rp.DESCRIPTION
	   ,rp.AMOUNT
	   ,rp.PERIOD_TYPE
	   ,rp.INITIAL_DATE
	   ,rp.FINAL_DATE
	   ,rp.HAS_EMAIL
	   ,cr.NAME
	   ,cr.EMAIL
	   ,cr.CPF_CNPJ
	   ,cr.PHONE
	   ,cr.ZIPCODE
	   ,cr.STREET
	   ,cr.NUMBER
	   ,cr.NEIGHBORHOOD
	   ,cr.CITY
	   ,cr.UF
	   ,rp.COD_EC
	   ,rp.COD_AFFILIATOR
	FROM Recurring.RECURRING_PAYMENT rp
	JOIN Recurring.CUSTOMER_RECURRING cr
		ON cr.COD_CUSTOMER_REC = rp.COD_CUSTOMER_REC
	WHERE rp.COD_REC_PAYMENT = @COD_REC
	AND rp.COD_SITUATION = 3
END
GO

IF OBJECT_ID('Recurring.SP_LIST_SPLIT_INFO') IS NOT NULL
	DROP PROCEDURE Recurring.SP_LIST_SPLIT_INFO;
GO
CREATE PROCEDURE Recurring.SP_LIST_SPLIT_INFO
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-05       Created   
------------------------------------------------------------------------------------------*/ (@COD_REC_PAYMENT INT)
AS
BEGIN

	SELECT
		COD_REC_SPLIT
	   ,RS.COD_EC
	   ,CE.CPF_CNPJ [EC_DOC]
	   ,RS.COD_AFFILIATOR
	   ,A.CPF_CNPJ [AFF_DOC]
	   ,AMOUNT
	   ,CE.NAME [NAME_EC]
	FROM Recurring.RECURRING_SPLIT RS WITH (NOLOCK)
	JOIN AFFILIATOR A WITH (NOLOCK)
		ON RS.COD_AFFILIATOR = A.COD_AFFILIATOR
	JOIN COMMERCIAL_ESTABLISHMENT CE WITH (NOLOCK)
		ON RS.COD_EC = CE.COD_EC
	WHERE COD_REC_PAYMENT = @COD_REC_PAYMENT

END
GO

IF OBJECT_ID('Recurring.SP_FD_DATA_EMAIL_BY_LINK') IS NOT NULL
	DROP PROCEDURE Recurring.SP_FD_DATA_EMAIL_BY_LINK;
GO
CREATE PROCEDURE Recurring.SP_FD_DATA_EMAIL_BY_LINK (@CODE VARCHAR(255))
AS
BEGIN


	SELECT
		COMMERCIAL_ESTABLISHMENT.NAME AS EC_NAME
	   ,lr.NAME AS REC_NAME
	   ,lr.DESCRIPTION
	   ,lr.AMOUNT
	   ,lr.PERIOD_TYPE
	   ,lr.FINAL_DATE
	   ,lr.INITIAL_DATE
	   ,AFFILIATOR.NAME AS AffName
	   ,THEMES.COLOR_HEADER
	   ,THEMES.LOGO_HEADER_AFFILIATE
	FROM PAYMENT_LINK PL
	JOIN Recurring.LINK_RECURRING lr
		ON lr.COD_PAY_LINK = PL.COD_PAY_LINK
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = PL.COD_EC
	JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = PL.COD_AFFILIATOR
	LEFT JOIN THEMES
		ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
			AND THEMES.ACTIVE = 1
	WHERE PL.CODE = @CODE

END

GO


IF OBJECT_ID('Recurring.SP_REPORT_PLANS') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_REPORT_PLANS
END
GO
CREATE PROCEDURE Recurring.SP_REPORT_PLANS
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-27       Created   
    Lucas Aguiar     V2         2020-09-19       altera��es hmg   
------------------------------------------------------------------------------------------*/ (@DATE_FROM DATETIME,
@DATE_UNTIL DATETIME,
@PLAN_NAME VARCHAR(128) = NULL,
@COD_EC TP_STRING_CODE READONLY,
@COD_AF TP_STRING_CODE READONLY,
@BILLING_TYPE TP_STRING_CODE READONLY,
@COD_SITUATION TP_STRING_CODE READONLY,
@PAGE_SIZE INT = 15,
@PAGE INT = 1,
@TOTAL INT OUTPUT)
AS
BEGIN
	SET @PLAN_NAME = '%' + @PLAN_NAME + '%';
	DECLARE @SQL NVARCHAR(MAX)
		   ,@OFFSET INT = ((@PAGE - 1) * @PAGE_SIZE)
	DECLARE @IdsSituation CODE_TYPE
	DECLARE @TODAY DATE = CAST(GETDATE() AS DATE)

	SET @SQL = 'FROM Recurring.DATE_RECURRING_PAYMENT DRP
    JOIN Recurring.RECURRING_PAYMENT (NOLOCK) RP ON RP.COD_REC_PAYMENT = DRP.COD_REC_PAYMENT
    JOIN TRADUCTION_SITUATION TS on RP.COD_SITUATION = TS.COD_SITUATION 
    JOIN Recurring.CUSTOMER_RECURRING CR ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
    JOIN COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC
    LEFT JOIN AFFILIATOR A ON RP.COD_AFFILIATOR = A.COD_AFFILIATOR
    WHERE DRP.RECURRING_DATE BETWEEN @DATE_FROM AND @DATE_UNTIL '

	IF EXISTS (SELECT
				CODE
			FROM @COD_EC)
		SET @SQL += ' AND CE.CPF_CNPJ IN (SELECT CODE FROM @COD_EC) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_AF)
		SET @SQL += ' AND A.CPF_CNPJ IN (SELECT CODE FROM @COD_AF) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_SITUATION)
	BEGIN
		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'active')
			INSERT INTO @IdsSituation
				VALUES (3)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'canceled')
			INSERT INTO @IdsSituation
				VALUES (6)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'expired')
		BEGIN
			SET @SQL += ' AND (RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) OR (RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY ) )'
		END
		ELSE
		BEGIN
			SET @SQL += ' AND RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) '
		END
	END

	IF @PLAN_NAME IS NOT NULL
		SET @SQL += ' AND (RP.NAME LIKE @PLAN_NAME OR RP.DESCRIPTION LIKE @PLAN_NAME OR CR.CPF_CNPJ LIKE @PLAN_NAME) '

	SET @SQL = 'SELECT @TOTAL = COUNT(*) FROM (SELECT DISTINCT RP.COD_REC_PAYMENT ' + @SQL + ') tmp; ' + '
        SELECT DISTINCT
            RP.COD_REC_PAYMENT,
            RP.NAME [PLAN_NAME], 
            CR.CPF_CNPJ,
            ''CREDIT'' [BILLING_TYPE],
            PERIOD_TYPE,
            AMOUNT,
            FINAL_DATE,
            (CASE WHEN RP.COD_SITUATION = 6 THEN ''canceled'' WHEN RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY THEN ''expired'' WHEN RP.COD_SITUATION = 3 THEN ''active'' WHEN RP.COD_SITUATION = 7 THEN ''failed'' ELSE TS.SITUATION_TR END )  [STATUS]
    ' + @SQL + ' ORDER BY RP.COD_REC_PAYMENT DESC OFFSET @OFFSET ROWS FETCH NEXT @PAGE_SIZE ROWS ONLY '

	EXEC sp_executesql @SQL
					  ,N'
        @DATE_FROM DATETIME,
        @DATE_UNTIL DATETIME,
        @PLAN_NAME VARCHAR(128),
        @COD_EC TP_STRING_CODE READONLY,
        @COD_AF TP_STRING_CODE READONLY,
        @BILLING_TYPE TP_STRING_CODE READONLY,
        @COD_SITUATION CODE_TYPE READONLY,
        @PAGE_SIZE INT,
        @PAGE INT,
        @OFFSET INT,
        @TODAY DATE,
        @TOTAL INT OUTPUT
    '
					  ,@DATE_FROM = @DATE_FROM
					  ,@DATE_UNTIL = @DATE_UNTIL
					  ,@PLAN_NAME = @PLAN_NAME
					  ,@COD_EC = @COD_EC
					  ,@COD_AF = @COD_AF
					  ,@BILLING_TYPE = @BILLING_TYPE
					  ,@COD_SITUATION = @IdsSituation
					  ,@PAGE_SIZE = @PAGE_SIZE
					  ,@PAGE = @PAGE
					  ,@OFFSET = @OFFSET
					  ,@TODAY = @TODAY
					  ,@TOTAL = @TOTAL OUTPUT;
END
GO
IF OBJECT_ID('Recurring.SP_REPORT_STAT_PLANS') IS NOT NULL
BEGIN
	DROP PROCEDURE Recurring.SP_REPORT_STAT_PLANS
END
GO
CREATE PROCEDURE Recurring.SP_REPORT_STAT_PLANS
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author           VERSION    Date             Description    
------------------------------------------------------------------------------------------    
    Luiz Aquino      V1         2020-08-27       Created   
------------------------------------------------------------------------------------------*/ (@DATE_FROM DATETIME,
@DATE_UNTIL DATETIME,
@PLAN_NAME VARCHAR(128) = NULL,
@COD_EC TP_STRING_CODE READONLY,
@COD_AF TP_STRING_CODE READONLY,
@BILLING_TYPE TP_STRING_CODE READONLY,
@COD_SITUATION TP_STRING_CODE READONLY)
AS
BEGIN

	SET @PLAN_NAME = '%' + @PLAN_NAME + '%';

	DECLARE @QUERY NVARCHAR(MAX)
	DECLARE @IdsSituation CODE_TYPE
	DECLARE @TODAY DATE = CAST(GETDATE() AS DATE)

	SET @QUERY = '
    SELECT DISTINCT COD_REC_PAYMENT
    INTO #PlansInRange
    FROM Recurring.DATE_RECURRING_PAYMENT
    WHERE RECURRING_DATE BETWEEN @DATE_FROM AND @DATE_UNTIL;
    
    SELECT 
           count(*) [Total], 
           COALESCE(SUM(AMOUNT), 0) [TPV], 
           COALESCE((SUM(AMOUNT) / COUNT(*)), 0) [Average_Amount], 
           COALESCE(SUM(AMOUNT), 0) [CREDIT], 
           CAST( 0 AS DECIMAL(22,6)) [BILLET]  
    FROM Recurring.RECURRING_PAYMENT RP
    JOIN Recurring.CUSTOMER_RECURRING CR ON CR.COD_CUSTOMER_REC = RP.COD_CUSTOMER_REC
    JOIN COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC
    LEFT JOIN AFFILIATOR A ON RP.COD_AFFILIATOR = A.COD_AFFILIATOR
    WHERE RP.COD_REC_PAYMENT IN (SELECT COD_REC_PAYMENT FROM #PlansInRange)
    '
	IF EXISTS (SELECT
				CODE
			FROM @COD_EC)
		SET @QUERY += ' AND CE.CPF_CNPJ IN (SELECT CODE FROM @COD_EC) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_AF)
		SET @QUERY += ' AND A.CPF_CNPJ IN (SELECT CODE FROM @COD_AF) '

	IF EXISTS (SELECT
				CODE
			FROM @COD_SITUATION)
	BEGIN
		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'active')
			INSERT INTO @IdsSituation
				VALUES (3)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'canceled')
			INSERT INTO @IdsSituation
				VALUES (6)

		IF EXISTS (SELECT
					CODE
				FROM @COD_SITUATION
				WHERE CODE = 'expired')
		BEGIN
			SET @QUERY += ' AND (RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) OR (RP.COD_SITUATION = 3 AND RP.FINAL_DATE < @TODAY ) )'
		END
		ELSE
		BEGIN
			SET @QUERY += ' AND RP.COD_SITUATION IN (SELECT CODE FROM @COD_SITUATION) '
		END
	END

	IF @PLAN_NAME IS NOT NULL
		SET @QUERY += ' AND (RP.NAME LIKE @PLAN_NAME OR RP.DESCRIPTION LIKE @PLAN_NAME OR CR.CPF_CNPJ LIKE @PLAN_NAME) '

	EXEC sp_executesql @QUERY
					  ,N'
        @DATE_FROM DATETIME,
        @DATE_UNTIL DATETIME,
        @PLAN_NAME VARCHAR(128),
        @COD_EC TP_STRING_CODE READONLY,
        @COD_AF TP_STRING_CODE READONLY,
        @BILLING_TYPE TP_STRING_CODE READONLY,
        @COD_SITUATION CODE_TYPE READONLY,
        @TODAY DATE
    '
					  ,@DATE_FROM = @DATE_FROM
					  ,@DATE_UNTIL = @DATE_UNTIL
					  ,@PLAN_NAME = @PLAN_NAME
					  ,@COD_EC = @COD_EC
					  ,@COD_AF = @COD_AF
					  ,@BILLING_TYPE = @BILLING_TYPE
					  ,@COD_SITUATION = @IdsSituation
					  ,@TODAY = @TODAY
END

GO


IF OBJECT_ID('SP_FIN_CALENDAR_TITLES_PRC') IS NOT NULL
DROP PROCEDURE SP_FIN_CALENDAR_TITLES_PRC
GO
CREATE PROCEDURE [dbo].[SP_FIN_CALENDAR_TITLES_PRC] (@COD_BK_EC INT,
@DATE DATE,
@COD_SITUATION INT = NULL)
AS
	DECLARE @COD_EC INT;
	DECLARE @recurring INT;

	BEGIN


		SELECT
			@COD_EC = COD_EC
		FROM BANK_DETAILS_EC
		WHERE COD_BK_EC = @COD_BK_EC;

		SELECT
			@recurring = COD_ITEM_SERVICE
		FROM ITEMS_SERVICES_AVAILABLE
		WHERE NAME = 'RECURRING';

		SELECT
			[T].[CODE]
		   ,CONCAT(CONCAT([TT].[PLOT], '/'), [T].[PLOTS]) AS [PLOT]
		   ,[dbo].[FN_FUS_UTF]([T].[CREATED_AT]) AS [TRANSACTION_DATE]
		   ,[T].[AMOUNT] AS [TRANSACTION_AMOUNT]
		   ,[F].[COD_EC]
		   ,[F].[EC_NAME] AS [EC]
		   ,[F].[EC_CPF_CNPJ] AS [CPF_CNPJ_EC]
		   ,CAST((([TT].[AMOUNT] * (1 - ([TT].[TAX_INITIAL] / 100)) *
			CASE
				WHEN [TT].[ANTICIP_PERCENT] IS NULL THEN 1
				ELSE 1 - ((([TT].[ANTICIP_PERCENT] / 30) *
					COALESCE(CASE
						WHEN [TT].[IS_SPOT] = 1 THEN DATEDIFF(DAY,
							[TT].[PREVISION_PAY_DATE],
							[TT].[ORIGINAL_RECEIVE_DATE])
						ELSE [TT].[QTY_DAYS_ANTECIP]
					END,
					([TT].[PLOT] * 30) - 1)) /
					100)
			END) - (CASE
				WHEN [TT].[PLOT] = 1 THEN [TT].[RATE]
				ELSE 0
			END)) AS DECIMAL(22, 6)) AS [PLOT_VALUE_PAYMENT]
		   ,[F].[PREVISION_PAY_DATE]
		   ,[F].[COD_BANK]
		   ,ISNULL([F].[CODE_BANK], 'N�O CADASTRADO') AS [CODE_BANK]
		   ,ISNULL([F].[BANK], 'N�O CADASTRADO') AS [BANK]
		   ,[F].[AGENCY]
		   ,CONCAT([F].[ACCOUNT], [F].[DIGIT_ACCOUNT]) AS [ACCOUNT]
		   ,[S].[NAME] AS [SITUATION]
		   ,[F].[COD_SITUATION]
		   ,'TITLE' AS [TYPE_RELEASE]
		   ,[F].[COD_FIN_SCH_FILE]
		   ,[FINANCE_SCHEDULE_FILE].[CREATED_AT] AS [FILE_DATE]
		   ,[FINANCE_SCHEDULE_FILE].file_name
		   ,[FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE]
		   ,[F].[IS_LOCK]
		   ,[TT].[IS_SPOT]
		   ,IIF(TS.COD_ITEM_SERVICE IS NOT NULL, 1, 0) AS WAS_RECURRING
		FROM [FINANCE_CALENDAR] AS [F]
		JOIN [TRANSACTION_TITLES] AS [TT] WITH (NOLOCK)
			ON [TT].[COD_FIN_CALENDAR] = [F].[COD_FIN_CALENDAR]
		JOIN [TRANSACTION] AS [T] WITH (NOLOCK)
			ON [T].[COD_TRAN] = [TT].[COD_TRAN]
		JOIN [SITUATION] AS [S]
			ON [S].[COD_SITUATION] = [F].[COD_SITUATION]
		LEFT JOIN [FINANCE_SCHEDULE_FILE]
			ON [FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE] = [F].[COD_FIN_SCH_FILE]
		LEFT JOIN TRANSACTION_SERVICES TS WITH (NOLOCK)
			ON TS.COD_TRAN = T.COD_TRAN
				AND TS.COD_ITEM_SERVICE = @recurring
		WHERE [F].[ACTIVE] = 1
		AND [F].COD_EC = @COD_EC
		AND [F].[COD_BK_EC] = @COD_BK_EC
		AND [F].[COD_SITUATION] = ISNULL(@COD_SITUATION, 4)
		AND CAST([F].[PREVISION_PAY_DATE] AS DATE) <= @DATE;
	END;

GO

IF OBJECT_ID('SP_FINANCE_CALENDAR_PRC') IS NOT NULL
DROP PROCEDURE SP_FINANCE_CALENDAR_PRC
GO
CREATE PROCEDURE [SP_FINANCE_CALENDAR_PRC] (@INITIAL_DATE DATETIME,
@FINAL_DATE DATETIME,
@EC [CODE_TYPE] READONLY,
@BANK [CODE_TYPE] READONLY,
@CODAFF [CODE_TYPE] READONLY,
@ACCOUNT [CODE_TYPE] READONLY,
@CODSITUATION INT = NULL,
@ONLY_ASSIGNMENT INT = 0,
@ONLY_LOCKED INT = 0)
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	DECLARE @QUERY NVARCHAR(MAX);

	SET @QUERY = '
    SELECT
        [FINANCE_CALENDAR].[COD_EC] as BusinessEstablishmentInsideCode,
        [FINANCE_CALENDAR].[TRADING_NAME] AS BusinessEstablishment,
        [FINANCE_CALENDAR].[EC_CPF_CNPJ] AS Identification,
        sum([FINANCE_CALENDAR].[PLOT_VALUE_PAYMENT]) as Amount,
        @INITIAL_DATE as DatePrevisionPayment,
        [FINANCE_CALENDAR].[COD_BANK],
        [FINANCE_CALENDAR].[PRIORITY],
        [FINANCE_CALENDAR].[CODE_BANK] as BankCode,
        [FINANCE_CALENDAR].[BANK] as BankName,
        [FINANCE_CALENDAR].[ACCOUNT] BankAccount,
        [FINANCE_CALENDAR].[DIGIT_ACCOUNT] as DigitAccount,
        [FINANCE_CALENDAR].[AGENCY] as BankAgency,
        [FINANCE_CALENDAR].[DIGIT_AGENCY] as DigitAgency,
        [FINANCE_CALENDAR].[ACCOUNT_TYPE] as BankTypeAccount,
        [FINANCE_CALENDAR].[OPERATION_CODE] as OperationCode,
        [FINANCE_CALENDAR].[COD_TYPE_ACCOUNT],
        (CASE
            WHEN EC.TCU_ACCEPTED = 0
                THEN ''AGENDA SUSPENSA - Aguardando Optin TCU''
            WHEN ([EC].[COD_SITUATION] = 24  OR [AFF].[COD_SITUATION] = 24)
                THEN ''AGENDA SUSPENSA''
            WHEN [FINANCE_CALENDAR].[COD_SITUATION] = 30
                THEN ''AGUARDANDO SPLIT''
            WHEN [FINANCE_CALENDAR].[COD_SITUATION] = 17
                THEN ''CONFIRMACAO''
            WHEN [FINANCE_CALENDAR].[COD_SITUATION] = 4
                THEN ''PAGAMENTO''
            ELSE SITUATION.NAME
        END) AS Situation,
        [FINANCE_CALENDAR].[COD_AFFILIATOR] as AffiliatorInsideCode,
        [FINANCE_CALENDAR].[AFFILIATOR_NAME] AS Affiliator,
        [FINANCE_CALENDAR].[COD_SITUATION] as SituationInsideCode,
        [SITUATION].[NAME] AS [SITUATION_NAME],
        [FINANCE_CALENDAR].[IS_ASSIGNMENT] as Assignment,
        [FINANCE_CALENDAR].[ASSIGNMENT_IDENTIFICATION] as IdentificationAssignment,
        [FINANCE_CALENDAR].[IS_LOCK] AS HasLock,
        IIF([COD_TYPE_ACCOUNT] = 3, 1, 0) AS IsPaymentAccount,
        [FINANCE_CALENDAR].[COD_COMP],
        [FINANCE_CALENDAR].[TYPE_ESTAB] as TypeEstab,
        [FINANCE_CALENDAR].[COD_BK_EC] as BankEcInsideCode
    FROM [FINANCE_CALENDAR]
         JOIN [COMMERCIAL_ESTABLISHMENT] AS [EC] ON [EC].[COD_EC] = [FINANCE_CALENDAR].[COD_EC]
         JOIN [SITUATION] ON [SITUATION].[COD_SITUATION] = [FINANCE_CALENDAR].[COD_SITUATION]
         LEFT JOIN [AFFILIATOR] AS [AFF] ON [AFF].[COD_AFFILIATOR] = [FINANCE_CALENDAR].[COD_AFFILIATOR]
    WHERE [FINANCE_CALENDAR].[COD_SITUATION] IN(4, 17, 30) AND [FINANCE_CALENDAR].[ACTIVE] = 1  AND cast([PREVISION_PAY_DATE] as date) <= cast(@INITIAL_DATE as date)';


	IF @ONLY_ASSIGNMENT = 1
		SET @QUERY = @QUERY + ' AND [IS_ASSIGNMENT] = 1';

	IF @ONLY_LOCKED = 1
		SET @QUERY = @QUERY + ' AND [IS_LOCK] = 1';

	IF @CODSITUATION IS NOT NULL
		SET @QUERY = @QUERY + ' AND [FINANCE_CALENDAR].[COD_SITUATION] = @CODSITUATION';

	IF (SELECT
				COUNT(*)
			FROM @EC)
		> 0
		SET @QUERY = @QUERY + ' AND [FINANCE_CALENDAR].[COD_EC] IN (SELECT [CODE] FROM @EC)';

	IF (SELECT
				COUNT(*)
			FROM @BANK)
		> 0
		SET @QUERY = @QUERY + ' AND [FINANCE_CALENDAR].[COD_BANK] IN (SELECT [CODE] FROM @BANK)';

	IF (SELECT
				COUNT(*)
			FROM @CODAFF)
		> 0
		SET @QUERY = @QUERY + ' AND [FINANCE_CALENDAR].[COD_AFFILIATOR] IN (SELECT [CODE] FROM @CODAFF)';

	IF (SELECT
				COUNT(*)
			FROM @ACCOUNT)
		> 0
		SET @QUERY = @QUERY + ' AND [FINANCE_CALENDAR].[COD_TYPE_ACCOUNT] IN (SELECT [CODE] FROM @ACCOUNT)';


	SET @QUERY = @QUERY + '

    GROUP BY [FINANCE_CALENDAR].[COD_EC],
        [FINANCE_CALENDAR].[TRADING_NAME],
        [FINANCE_CALENDAR].[EC_CPF_CNPJ],
        [FINANCE_CALENDAR].[COD_BANK],
        [FINANCE_CALENDAR].[PRIORITY],
        [FINANCE_CALENDAR].[CODE_BANK],
        [FINANCE_CALENDAR].[BANK],
        [FINANCE_CALENDAR].[ACCOUNT],
        [FINANCE_CALENDAR].[DIGIT_ACCOUNT],
        [FINANCE_CALENDAR].[AGENCY],
        [FINANCE_CALENDAR].[DIGIT_AGENCY],
        [FINANCE_CALENDAR].[ACCOUNT_TYPE],
        [FINANCE_CALENDAR].[OPERATION_CODE],
        [FINANCE_CALENDAR].[COD_TYPE_ACCOUNT],
        (CASE
            WHEN EC.TCU_ACCEPTED = 0 THEN ''AGENDA SUSPENSA - Aguardando Optin TCU''
            WHEN ([EC].[COD_SITUATION] = 24  OR [AFF].[COD_SITUATION] = 24) THEN ''AGENDA SUSPENSA''
            WHEN [FINANCE_CALENDAR].[COD_SITUATION] = 30 THEN ''AGUARDANDO SPLIT''
            WHEN [FINANCE_CALENDAR].[COD_SITUATION] = 17 THEN ''CONFIRMACAO''
            WHEN [FINANCE_CALENDAR].[COD_SITUATION] = 4  THEN ''PAGAMENTO''
            ELSE SITUATION.NAME
        END),
        [FINANCE_CALENDAR].[COD_AFFILIATOR],
        [FINANCE_CALENDAR].[AFFILIATOR_NAME],
        [FINANCE_CALENDAR].[COD_SITUATION],
        [SITUATION].[NAME],
        [FINANCE_CALENDAR].[IS_ASSIGNMENT],
        [FINANCE_CALENDAR].[ASSIGNMENT_IDENTIFICATION],
        [FINANCE_CALENDAR].[IS_LOCK],
        IIF([COD_TYPE_ACCOUNT] = 3, 1, 0),
        [FINANCE_CALENDAR].[COD_COMP],
        [FINANCE_CALENDAR].[TYPE_ESTAB],
        [FINANCE_CALENDAR].[COD_BK_EC]
    ORDER BY [PRIORITY] DESC,FINANCE_CALENDAR.[COD_EC]';

	--SELECT @QUERY;

	EXEC [sp_executesql] @QUERY
						,N'
  @INITIAL_DATE DATETIME,
  @FINAL_DATE DATETIME,
  @EC [CODE_TYPE] READONLY,
  @BANK [CODE_TYPE] READONLY,
  @CodAff [CODE_TYPE] READONLY,
  @ACCOUNT [CODE_TYPE] READONLY,
  @CodSituation INT = NULL,
  @ONLY_ASSIGNMENT INT = 0,
  @ONLY_LOCKED INT = 0
 '
						,@INITIAL_DATE = @INITIAL_DATE
						,@FINAL_DATE = @FINAL_DATE
						,@EC = @EC
						,@BANK = @BANK
						,@CODAFF = @CODAFF
						,@ACCOUNT = @ACCOUNT
						,@CODSITUATION = @CODSITUATION
						,@ONLY_ASSIGNMENT = @ONLY_ASSIGNMENT
						,@ONLY_LOCKED = @ONLY_LOCKED;

END;
GO

IF NOT EXISTS (SELECT
			1
		FROM [sys].[COLUMNS]
		WHERE NAME = N'IS_RECURRING'
		AND object_id = OBJECT_ID(N'REPORT_CONSOLIDATED_TRANS_SUB'))
BEGIN

	ALTER TABLE REPORT_CONSOLIDATED_TRANS_SUB
	ADD IS_RECURRING INT DEFAULT 0;
END;

GO


IF OBJECT_ID('VW_REPORT_FULL_CASH_FLOW') IS NOT NULL
	DROP VIEW VW_REPORT_FULL_CASH_FLOW;
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
	   ,(CASE
			WHEN (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				> 0 THEN dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.TAX_INITIAL, TRANSACTION_TITLES.ANTICIP_PERCENT, (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, [TRANSACTION].COD_TTYPE)
			ELSE dbo.[FNC_ANT_VALUE_LIQ_DAYS](
				TRANSACTION_TITLES.AMOUNT,
				TRANSACTION_TITLES.TAX_INITIAL,
				TRANSACTION_TITLES.PLOT,
				TRANSACTION_TITLES.ANTICIP_PERCENT,
				(CASE
					WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

					ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
				END))
		END) AS EC
	   ,0 AS '0'
	   ,(CASE
			WHEN (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				> 0 THEN dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.TAX_INITIAL, TRANSACTION_TITLES.ANTICIP_PERCENT, (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, [TRANSACTION].COD_TTYPE)
			ELSE (dbo.[FNC_ANT_VALUE_LIQ_DAYS](
				TRANSACTION_TITLES.AMOUNT,
				TRANSACTION_TITLES.TAX_INITIAL,
				TRANSACTION_TITLES.PLOT,
				TRANSACTION_TITLES.ANTICIP_PERCENT,
				(CASE
					WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
					ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
				END)
				) - (CASE
					WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
					ELSE 0
				END))
		END) AS EC_TARIFF
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
		TRANSACTION_TITLES.TAX_INITIAL) +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		TRANSACTION_TITLES.PLOT,
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		)
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL + (CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT + (CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END))
		) AS AFF
	   ,((
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		((TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], TRANSACTION_TITLES.TAX_INITIAL)
		+
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		TRANSACTION_TITLES.PLOT,
		COALESCE(
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT)
		+
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END
		))
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		TRANSACTION_TITLES.TAX_INITIAL
		+ (CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT
		+ (CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END))
		)
		+ (CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END)
		-
		(CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN ISNULL([TRANSACTION_TITLES_COST].RATE_PLAN, 0)
			ELSE 0
		END)
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
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
				, 0)
			ELSE 0
		END)

		, [TRANSACTION_TITLES].AMOUNT) AS LIQUID_MDR_EC
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES.ANTICIP_PERCENT +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
				, 0)
			ELSE 0
		END), 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT, [TRANSACTION_TITLES].TAX_INITIAL),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		) AS ANTECIP_DISCOUNT_EC
	   ,CASE
			WHEN [TRANSACTION].PLOTS = 1 THEN dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE] + IIF([TRANSACTION].COD_TTYPE = 2, TRANSACTION_TITLES_COST.TAX_PLANDZERO, 0), TRANSACTION_TITLES.AMOUNT)
			ELSE dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE], TRANSACTION_TITLES.AMOUNT)
		END AS LIQUID_MDR_AFF
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES_COST.ANTICIP_PERCENT, 0) + IIF([TRANSACTION].COD_TTYPE = 1, TRANSACTION_TITLES_COST.TAX_PLANDZERO, 0),
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
	   ,EC_PROD.[NAME] AS [EC_PROD]
	   ,EC_PROD.CPF_CNPJ AS [EC_PROD_CPF_CNPJ]
	   ,TRAN_PROD.[NAME] AS [NAME_PROD]
	   ,SPLIT_PROD.[PERCENTAGE] AS [PERCENT_PARTICIP_SPLIT]
	   ,[TRANSACTION_TITLES_COST].RATE_PLAN
	   ,CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END AS QTY_DAYS_ANTECIP
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
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM TRANSACTION_SERVICES WITH (NOLOCK)
					JOIN ITEMS_SERVICES_AVAILABLE ISA
						ON ISA.COD_ITEM_SERVICE = TRANSACTION_SERVICES.COD_ITEM_SERVICE
					WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
					AND ISA.NAME = 'RECURRING')
				> 0 THEN 1
			ELSE 0
		END AS IS_RECURRING
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
	LEFT JOIN [dbo].[REPORT_CONSOLIDATED_TRANS_SUB] WITH (NOLOCK)
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
	LEFT JOIN TRANSACTION_PRODUCTS AS [TRAN_PROD] WITH (NOLOCK)
		ON [TRAN_PROD].COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
		AND [TRAN_PROD].ACTIVE = 1
	LEFT JOIN SPLIT_PRODUCTS SPLIT_PROD WITH (NOLOCK)
		ON SPLIT_PROD.COD_SPLIT_PROD = TRANSACTION_TITLES.COD_SPLIT_PROD
	LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PROD WITH (NOLOCK)
		ON EC_PROD.COD_EC = [TRAN_PROD].COD_EC
	LEFT JOIN SALES_REPRESENTATIVE
		ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
	LEFT JOIN USERS USER_REPRESENTANTE
		ON USER_REPRESENTANTE.COD_USER = SALES_REPRESENTATIVE.COD_USER
	WHERE
	--[TRANSACTION].COD_SITUATION IN (3, 6, 10)                                    
	[TRANSACTION].COD_SITUATION = 3
	AND [TRANSACTION_TITLES].COD_SITUATION != 26
	AND COALESCE([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
	AND PROCESS_BG_STATUS.STATUS_PROCESSED = 0
	AND PROCESS_BG_STATUS.COD_SOURCE_PROCESS = 3
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION].CREATED_AT
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION_TITLES].CREATED_AT
	AND DATEPART(YEAR, [TRANSACTION].CREATED_AT) = DATEPART(YEAR, GETDATE())
	AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN IS NULL)
SELECT
	AFFILIATOR
   ,MERSHANT
   ,Serial
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
FROM CTE  
  
GO



IF OBJECT_ID('SP_REG_REPORT_CONSOLIDATED_TRANS_SUB') IS NOT NULL
DROP PROCEDURE SP_REG_REPORT_CONSOLIDATED_TRANS_SUB
GO
CREATE PROCEDURE [dbo].[SP_REG_REPORT_CONSOLIDATED_TRANS_SUB] WITH RECOMPILE
/*----------------------------------------------------------------------------------------                                
    Project.......: TKPP                                
------------------------------------------------------------------------------------------                                
    Author                          VERSION        Date             Description                                
------------------------------------------------------------------------------------------                                
    Fernando Henrique F. de O       V1              28/12/2018      Creation                              
    Fernando Henrique F. de O       V2              07/02/2019      Changed                          
    Luiz Aquino                     V3              22/02/2019      Remove Incomplete Installments                             
    Lucas Aguiar                    V4              22-04-2019      add originador e destino                         
    Caike Ucha                     V5              16/08/2019      add columns AUTH_CODE e CREDITOR_DOCUMENT                     
    Caike Ucha                     V6              11/09/2019      add column ORDER_CODE                      
    Marcus Gall                     V7              27/11/2019      Add Model_POS, Segment, Location_EC              
    Ana Paula Liick                 V8              31/01/2020      Add Origem_Trans            
    Caike Ucha                      V9              30/04/2020      add produto ec    
	Caike Uchoa                     V10             03/08/2020      add QTY_DAYS_ANTECIP    
    Caike Uchoa                     V11             06/08/2020      Add AMOUNT_NEW  
    Caike Uchoa                     V12             27/08/2020      add representante 
    Luiz Aquino                    V10            02/07/2020      PlanDZero (ET-895)      
	Caike Uchoa                     v12             01/09/2020      Add cod_ec_prod
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
		   ,[VW_REPORT_FULL_CASH_FLOW].IS_RECURRING INTO #TB_REPORT_FULL_CASH_FLOW_INSERT
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
			, IS_RECURRING)
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
		   ,[VW_REPORT_FULL_CASH_FLOW_UP].TRANSACTION_AMOUNT INTO #TB_REPORT_FULL_CASH_FLOW_UPDATE
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


IF OBJECT_ID('SP_REPORT_CONSOLIDATED_TRANSACTION_SUB') IS NOT NULL
DROP PROCEDURE SP_REPORT_CONSOLIDATED_TRANSACTION_SUB
GO
CREATE PROCEDURE [dbo].[SP_REPORT_CONSOLIDATED_TRANSACTION_SUB]

/**************************************************************************************************************              
    Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
     Author                          VERSION        Date                            Description                                  
 ------------------------------------------------------------------------------------------                                  
    Fernando Henrique F. de O       V1         28/12/2018                          Creation                                
    Fernando Henrique F. de O       V2         07/02/2019                          Changed                                    
    Elir Ribeiro                    V3         29/07/2019                          Changed date                          
    Caike Ucha Almeida             V4         16/08/2019                        Inserting columns                         
    Caike Ucha Almeida             V5         11/09/2019                        Inserting column                        
    Marcus Gall                     V6         27/11/2019               Add Model_POS, Segment, Location_EC                
    Ana Paula Liick                 V8         31/01/2020                       Add Origem_Trans                
    Caike Ucha                     V9         30/04/2020                       add produto ec            
    Luiz Aquino                     V10        02/07/2020                   PlanoDZero (ET-895)   
	 Caike Uch�a                     V10        03/08/2020                       add QTY_DAYS_ANTECIP    
     Caike Uch�a                     V11        07/08/2020                       ISNULL na RATE_PLAN  
     Caike Uchoa                     v12        01/09/2020                       Add cod_ec_prod
**************************************************************************************************************/ (@CODCOMP VARCHAR(10),
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
@COD_EC_PROD INT = NULL)
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
        ,[REPORT_CONSOLIDATED_TRANS_SUB].NAME_PROD            
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_PROD            
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_PROD_CPF_CNPJ            
        ,ISNULL([REPORT_CONSOLIDATED_TRANS_SUB].PERCENT_PARTICIP_SPLIT,0) PERCENT_PARTICIP_SPLIT           
        ,[REPORT_CONSOLIDATED_TRANS_SUB].IS_PLANDZERO          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TAX_PLANDZERO            
  ,[REPORT_CONSOLIDATED_TRANS_SUB].QTY_DAYS_ANTECIP          
  ,isnull([REPORT_CONSOLIDATED_TRANS_SUB].TAX_PLANDZERO_AFF, 0) TAX_PLANDZERO_AFF        
  ,[REPORT_CONSOLIDATED_TRANS_SUB].SALES_REPRESENTANTE      
  ,[REPORT_CONSOLIDATED_TRANS_SUB].CPF_CNPJ_REPRESENTANTE      
  ,[REPORT_CONSOLIDATED_TRANS_SUB].EMAIL_REPRESENTANTE
  ,[REPORT_CONSOLIDATED_TRANS_SUB].IS_RECURRING   
  FROM [REPORT_CONSOLIDATED_TRANS_SUB]                                         
   WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_COMP = @CODCOMP                                                              
   AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = 3                                  
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
		   @COD_EC_PROD INT
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
						,@COD_EC_PROD = @COD_EC_PROD;

END;


GO


INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600806156547,'22/9/2020','22/9/2020','Café do Jeú','35464758000165','16008115964473696','TERCA10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600806044999,'22/9/2020','22/9/2020','Brigaduda','03770828216','16008100822276388','TERCA10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600797832062,'22/9/2020','22/9/2020','Brigaduda','03770828216','16008053088199386','TERCA10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600796537643,'22/9/2020','22/9/2020','Jiovanna Brownies','28997381000144','16008000138511670','TERCA10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600796091836,'22/9/2020','22/9/2020','Almoço Do Goiano','41756630291','16007981147643064','TERCA10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600792947225,'22/9/2020','22/9/2020','Jiovanna Brownies','28997381000144','16007966622239992','TERCA10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600793167089,'22/9/2020','22/9/2020','Jiovanna Brownies','28997381000144','16007954149515916','TERCA10','10,00','Cash','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600735004490,'22/9/2020','22/9/2020','Açaí Do Tio Julio','19263090220','16007411672103476','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600739180708,'22/9/2020','22/9/2020','Jiovanna Brownies','28997381000144','16007408522430064','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600737144345,'22/9/2020','22/9/2020','Bobs Torquato','10676472001780','16007371460952476','Cupom de R$10','10,00','Card','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600732966610,'22/9/2020','22/9/2020','Explosão do Sabor','04503980211','16007389438856410','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600735355609,'22/9/2020','22/9/2020','Manaus Lanches','98071661287','16007386907407670','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600734555973,'22/9/2020','22/9/2020','Lasanha House','71027629253','16007345576499330','Cupom de R$10','10,00','Card','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600733762463,'22/9/2020','22/9/2020','Esquina Do Pastel','32120141215','16007379606515400','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600733921484,'22/9/2020','22/9/2020','Lanchonete e Pizzaria do Arilson','34715380200','16007339232143740','Cupom de R$10','10,00','Card','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600731943050,'21/9/2020','22/9/2020','Bobs Sumaúma','10676472002085','16007363845290272','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600731657270,'21/9/2020','22/9/2020','Hot Dog Brasil','01308380208','undefined','Cupom de R$10','10,00','Desconto em Folha','OK','NOK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600731743944,'21/9/2020','22/9/2020','Bobs Sumaúma','10676472002085','16007351249506012','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600731774315,'21/9/2020','22/9/2020','Speto da Hora - Espeto','35847838000108','16007347770478980','Cupom de R$10','10,00','POS','OK','OK','OK','OK');
INSERT INTO TMP_PROMOCODE(Num_Pedido,Data_Pedido,Data_Transacao,Nome_EC,CNPJ_CPF,NSU,Cupom,Valor,Forma_Pagamento,Status_Cupom,Status_Split,Status_MDR,Status_Desconto) VALUES (1600731734227,'21/9/2020','22/9/2020','Bobs Sumaúma','10676472002085','16007343077392560','Cupom de R$10','10,00','POS','OK','OK','OK','OK');


GO

SELECT BRAND.COD_BRAND,
       PLOTS,
       REPORT_TRANSACTIONS_EXP.COD_SOURCE_TRAN,
       BRAND.COD_TTYPE,
       REPORT_TRANSACTIONS_EXP.COD_TRAN,
       REPORT_TRANSACTIONS_EXP.TRANSACTION_CODE AS NSU,
       TMP_PROMOCODE.CNPJ_CPF,
       REPLACE(Valor, ',', '.')                 AS AMOUNT,
       TMP_PROMOCODE.Cupom
INTO #TMP
FROM REPORT_TRANSACTIONS_EXP
         JOIN BRAND ON BRAND.[NAME] = REPORT_TRANSACTIONS_EXP.BRAND
         JOIN TMP_PROMOCODE ON TMP_PROMOCODE.NSU = TRANSACTION_CODE
go



go
SELECT VW_COMPANY_EC_BR_DEP.COD_EC,
       REPLACE(TMP_PROMOCODE.Valor, ',', '.') AS AMOUNT,
       VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC,
       ASS_TAX_DEPART.COD_ASS_TX_DEP,
       ASS_TAX_DEPART.[PARCENTAGE]             AS MDR,
       ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE  AS ANTICIP,
       ASS_TAX_DEPART.INTERVAL
INTO #TMP_TAX
FROM VW_COMPANY_EC_BR_DEP
         JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
         join TMP_PROMOCODE on TMP_PROMOCODE.CNPJ_CPF = VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC
WHERE ASS_TAX_DEPART.ACTIVE = 1
GROUP BY VW_COMPANY_EC_BR_DEP.COD_EC,
         VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC,
         ASS_TAX_DEPART.COD_ASS_TX_DEP,
         ASS_TAX_DEPART.[PARCENTAGE],
         ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE,
         ASS_TAX_DEPART.INTERVAL,
         TMP_PROMOCODE.Valor
go



WITH CTE
         AS
         (
             SELECT #TMP.*,
                    (
                        SELECT ASS_TAX_DEPART.COD_ASS_TX_DEP
                        FROM VW_COMPANY_EC_BR_DEP
                                 JOIN COMMERCIAL_ESTABLISHMENT MERCHANT ON MERCHANT.COD_EC = VW_COMPANY_EC_BR_DEP.COD_EC
                            AND MERCHANT.COD_AFFILIATOR = 35
                                 JOIN ASS_TAX_DEPART
                                      ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
                        WHERE ASS_TAX_DEPART.ACTIVE = 1
                          AND CPF_CNPJ_EC = #TMP.CNPJ_CPF
                          AND ASS_TAX_DEPART.COD_BRAND = #TMP.COD_BRAND
                          AND ASS_TAX_DEPART.COD_SOURCE_TRAN = #TMP.COD_SOURCE_TRAN
                          AND #TMP.PLOTS BETWEEN ASS_TAX_DEPART.QTY_INI_PLOTS AND ASS_TAX_DEPART.QTY_FINAL_PLOTS
                    ) AS COD_ASS_TAX
             FROM #TMP
         )
SELECT VW_COMPANY_EC_BR_DEP.COD_EC,
       VW_COMPANY_EC_BR_DEP.COD_BRANCH,
       VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC,
       ASS_TAX_DEPART.PARCENTAGE AS MDR,
       ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE,
       ASS_TAX_DEPART.INTERVAL,
       CTE.NSU,
       CTE.AMOUNT,
       CTE.Cupom,
       (
           dbo.FNC_ANT_VALUE_LIQ_DAYS
               (
                   CTE.AMOUNT,
                   ASS_TAX_DEPART.PARCENTAGE,
                   1,
                   ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE,
                   0
               )
           )                     AS NET_AMOUNT
INTO #TMP_TOREGISTER
FROM CTE
         JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_ASS_TX_DEP = CTE.COD_ASS_TAX
         JOIN VW_COMPANY_EC_BR_DEP ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR

WHERE ASS_TAX_DEPART.ACTIVE = 1

GO



DECLARE @COD_EC INT;
DECLARE @AMOUNT DECIMAL(22, 6);
DECLARE @DATE DATETIME;
DECLARE @COMMENT VARCHAR(100);
DECLARE @COD_BRANCH INT;

DECLARE _CURSOR_INSERT CURSOR FOR
    SELECT COD_EC,
           NET_AMOUNT,
           DATEADD(DAY, INTERVAL, GETDATE())                                 PREV_DATE,
           ('CREDITO REFERENTE A TRANSACAO ' + NSU + ' E CUPOM ' + Cupom) AS COMMENT
    FROM #TMP_TOREGISTER

OPEN _CURSOR_INSERT

FETCH NEXT FROM _CURSOR_INSERT INTO @COD_EC, @AMOUNT , @DATE, @COMMENT


WHILE @@FETCH_STATUS = 0
    BEGIN


        SELECT @COD_BRANCH = COD_BRANCH FROM BRANCH_EC WHERE COD_EC = @COD_EC

        INSERT INTO [RELEASE_ADJUSTMENTS] ([COD_EC],
                                           [VALUE],
                                           [PREVISION_PAY_DATE],
                                           [COD_TYPEJUST],
                                           [COMMENT],
                                           [COD_SITUATION],
                                           [COD_USER],
                                           [COD_REQ],
                                           [COD_BRANCH],
                                           [COD_TRAN])
        select @COD_EC,
               @AMOUNT,
               @DATE,
               1,
               @COMMENT,
               4,
               474,
               null,
               @COD_BRANCH,
               null

        FETCH NEXT FROM _CURSOR_INSERT INTO @COD_EC, @AMOUNT , @DATE, @COMMENT


    END;


CLOSE _CURSOR_INSERT
DEALLOCATE _CURSOR_INSERT

GO
declare @tp CODE_TYPE;

insert into @tp (CODE)
select distinct COD_EC
from #TMP_TOREGISTER

exec SP_GEN_ALL_CALENDAR_BY_EC @tp;


select * from #TMP_TOREGISTER

GO


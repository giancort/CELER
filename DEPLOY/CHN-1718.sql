--ST-2073

IF(SELECT COUNT(*) FROM SOURCE_PROCESS WHERE CODE='CLIQUE PARA REDEFINIR SUA SENHA') = 0
INSERT INTO SOURCE_PROCESS ([DESCRIPTION], COD_USER_CREAT, CODE) VALUES ('PROCESS_EXPIRED_PASSWORD',474,'CLIQUE PARA REDEFINIR SUA SENHA')

IF(SELECT COUNT(*) FROM MESSAGING_CATEGORY WHERE [DESCRIPTION]= 'EXPIRING PASSWORD') = 0
INSERT INTO MESSAGING_CATEGORY ([DESCRIPTION],SECONS_ON_SCREEN,TRANSLATE_DESCRIPTION,CLASS_STYLE) 
VALUES ('EXPIRING PASSWORD',6,'SENHA EXPIRANDO','info')

GO

IF OBJECT_ID('SP_LOGIN_USER') IS NOT NULL
DROP PROCEDURE [SP_LOGIN_USER]

GO
CREATE PROCEDURE [dbo].[SP_LOGIN_USER]    
/*----------------------------------------------------------------------------------------    
 Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author                  VERSION        Date         Description    
------------------------------------------------------------------------------------------    
    Kennedy Alef            V1          31/07/2018      Creation    
    Gian Luca Dalle Cort    V2          31/07/2018      Changed    
    Lucas Aguiar            v3          26/11/2018      changed    
    Luiz Aquino             V4          15/05/2020      ET-859 TCU EC    
    Caike Uchoa             v5          29/04/2021      alter expiração de senha
	Caike Uchoa             v6          10/05/2021      add reset_logged
------------------------------------------------------------------------------------------  */    
(   @ACESSKEY VARCHAR(300),    
    @USER VARCHAR(100),    
    @COD_AFFILIATOR INT,
	@RESET_LOGGED INT = 0
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
 ON AFFILIATOR.COD_AFFILIATOR =    
  USERS.COD_AFFILIATOR --BUSCA SE USU�RIO POSSUI C�DIGO DE AFILIADOR    
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
    
    IF ISNULL(@COD_AFF, 0) <> ISNULL(@COD_AFFILIATOR, 0)    
        BEGIN    
SET @RETURN = CONCAT('USER NOT FOUND r', ';') + ISNULL(@PASS_TMP, 0);    
            THROW 61006,@RETURN,1;    
        END    
    
    IF DATEDIFF(MINUTE, @LOCK, GETDATE()) < 30    
        BEGIN    
SET @RETURN = CONCAT(CONCAT('USER BLOCKED', ';'), @PASS_TMP);    
    
            THROW 61008,@RETURN,1;    
        END    
    
    IF @ACTIVE_USER = 0    
        BEGIN    
SET @RETURN = CONCAT(CONCAT('USER INACTIVE', ';'), @PASS_TMP);    
            THROW 61007,@RETURN,1;    
        END    
    
    IF @ACTIVE_EC = 0    
        BEGIN    
SET @RETURN = CONCAT(CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE', ';'), @PASS_TMP);    
            THROW 61009,@RETURN,1;    
        END    
    
    IF @ACTIVE_AFL = 0    
        BEGIN    
SET @RETURN = CONCAT(CONCAT('AFFILIATOR INACTIVE', ';'), @PASS_TMP);    
            THROW 61009,@RETURN,1;    
        END    
    
    IF DATEDIFF(DAY, @DATEPASS, GETDATE()) >= 90    
        BEGIN    
SET @RETURN = CONCAT(CONCAT('PASSWORD EXPIRED', ';'), @PASS_TMP);    
            THROW 61010,@RETURN,1;    
        END    
    
    IF @LOGGED = 1 AND @RESET_LOGGED = 0   
        BEGIN    
UPDATE USERS    
SET LOGGED = 0    
WHERE USERS.COD_USER = @CODUSER;    
DELETE FROM TEMP_TOKEN    
WHERE TEMP_TOKEN.COD_USER = @CODUSER;    
SET @RETURN = CONCAT(CONCAT('USER ALREADY LOGGED', ';'), @PASS_TMP);    
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
 END AS AUTHENTICATION_FACTOR    
   ,CASE    
  WHEN FIRST_LOGIN_DATE IS NULL OR    
   COMMERCIAL_ESTABLISHMENT.TCU_ACCEPTED = 0 THEN 1    
  ELSE 0    
 END AS FIRST_ACCESS    
   ,AUTHENTICATION_FACTOR.COD_FACT    
   ,(-1 * (DATEDIFF(DAY, ((DATEADD(DAY, 90, GETDATE()) + GETDATE()) - GETDATE()), @DATEPASS))) AS DAYSTO_EXPIRE    
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
   ,ISNULL(USERS.LAST_LOGIN, current_timestamp) AS LAST_LOGIN    
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

IF OBJECT_ID('SP_LOGIN_USER_MOBILE_EC') IS NOT NULL
DROP PROCEDURE [SP_LOGIN_USER_MOBILE_EC];

GO
CREATE PROCEDURE [dbo].[SP_LOGIN_USER_MOBILE_EC]    
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_LOGIN_USER_MOBILE_EC]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author                          VERSION        Date                            Description    
------------------------------------------------------------------------------------------    
Kennedy Alef                       V1      27/07/2018                           Creation    
Caike Uchoa                        v2      10/05/2021                     alter expire pass
------------------------------------------------------------------------------------------*/    
(    
@ACESSKEY VARCHAR(300),    
@USER VARCHAR(100)    
)    
AS    
DECLARE @LOCK DATETIME;    
DECLARE @ACTIVE_USER INT;    
DECLARE @CODUSER INT;    
DECLARE @ACTIVE_EC INT;    
DECLARE @DATEPASS DATETIME    
DECLARE @LOGGED INT;    
DECLARE @PASS_TMP VARCHAR(MAX)    
DECLARE @RETURN VARCHAR(200)    
    
BEGIN    
    
SELECT @LOCK = LOCKED_UP ,     
    @ACTIVE_USER = USERS.ACTIVE,    
    @CODUSER = USERS.COD_USER ,     
    @ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE ,    
    @DATEPASS = PASS_HISTORY.CREATED_AT,    
    @LOGGED = USERS.LOGGED,    
    @PASS_TMP= PASS_HISTORY.PASS    
  FROM     
USERS     
INNER JOIN COMPANY ON COMPANY.COD_COMP = USERS.COD_COMP     
INNER JOIN PROFILE_ACCESS ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE    
INNER JOIN PASS_HISTORY on PASS_HISTORY.COD_USER = USERS.COD_USER    
LEFT JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC  = USERS.COD_EC    
WHERE COD_ACCESS =  @USER    
   AND COMPANY.ACCESS_KEY = @ACESSKEY    
   AND PASS_HISTORY.ACTUAL = 1 OR     
   USERS.EMAIL =  @USER    
   AND COMPANY.ACCESS_KEY = @ACESSKEY    
   AND PASS_HISTORY.ACTUAL = 1    
    
IF @CODUSER IS NULL OR @CODUSER = 0    
BEGIN    
    
SET @RETURN = CONCAT('USER NOT FOUND',';')+@PASS_TMP;    
THROW 61006,@RETURN,1;    
END    
    
IF DATEDIFF(MINUTE,@LOCK,GETDATE()) < 30    
BEGIN    
    
SET @RETURN = CONCAT(CONCAT('USER BLOCKED',';'),@PASS_TMP);    
THROW 61008,@RETURN,1;    
END    
    
IF @ACTIVE_USER = 0    
BEGIN    
SET @RETURN = CONCAT(CONCAT('USER INACTIVE',';'),@PASS_TMP);    
--SET @RETURN = CONCAT('USER INACTIVE',CONCAT('-',@PASS_TMP))    
THROW 61007,@RETURN,1;    
END    
    
IF @ACTIVE_EC = 0    
BEGIN    
SET @RETURN = CONCAT(CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE',';'),@PASS_TMP);    
--SET @RETURN = CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE',CONCAT('-',@PASS_TMP))    
THROW 61009,@RETURN,1;    
END    
    
IF DATEDIFF(DAY,@DATEPASS,GETDATE()) >= 90    
BEGIN    
SET @RETURN = CONCAT(CONCAT('PASSWORD EXPIRED',';'),@PASS_TMP);    
--SET @RETURN = CONCAT('PASSWORD EXPIRED',CONCAT('-',@PASS_TMP))    
THROW 61010,@RETURN,1;    
END    
IF @LOGGED = 1    
BEGIN    
UPDATE USERS SET LOGGED = 0 WHERE USERS.COD_USER = @CODUSER;    
DELETE FROM TEMP_TOKEN WHERE TEMP_TOKEN.COD_USER  = @CODUSER;    
SET @RETURN = CONCAT(CONCAT('USER ALREADY LOGGED',';'),@PASS_TMP);    
--SET @RETURN = CONCAT('USER ALREADY LOGGED',CONCAT('-',@PASS_TMP))    
THROW 61011,@RETURN,1;    
END    
IF @PASS_TMP IS NULL    
BEGIN    
THROW 61029,'TEMPORARY ACCESS',1;    
END    
    
    
    
SELECT USERS.COD_ACCESS AS [Name],    
    USERS.COD_USER  as [UserInsideCode],    
    USERS.IDENTIFICATION as [Identification],      
    PASS_HISTORY.PASS as [InsidePassword],    
    USERS.EMAIL as [Email],    
    COMPANY.COD_COMP AS [CompanyInsideCode] ,    
    COMPANY.NAME AS [Company],    
    PROFILE_ACCESS.COD_PROFILE AS [PerfilInsidecode],    
    PROFILE_ACCESS.CODE AS [Perfil],    
    MODULES.CODE AS [Module],    
    MODULES.COD_MODULE AS [ModuleInsideCode],    
    COMMERCIAL_ESTABLISHMENT.COD_EC  AS [BusinessEstablishmentInsideCode],    
    COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS [Identification],    
    COMMERCIAL_ESTABLISHMENT.NAME AS [BusinessEstablishment],    
    BRANCH_EC.COD_BRANCH AS [BranchInsideCode],    
    BRANCH_EC.NAME AS [Branch],    
    DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH AS [DepartmentInsideCode],    
    DEPARTMENTS.NAME as [Department],    
    COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE AS [ActiveAuthenticationFactor],    
    CASE COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE    
    WHEN 1 THEN AUTHENTICATION_FACTOR.NAME    
    WHEN 0 THEN NULL    
   ELSE AUTHENTICATION_FACTOR.NAME    
    END    
    AS  [AuthenticationFactor],    
    AUTHENTICATION_FACTOR.COD_FACT  AS [AuthenticationFactorInsideCode]    
  FROM     
USERS     
INNER JOIN COMPANY ON COMPANY.COD_COMP = USERS.COD_COMP     
INNER JOIN PROFILE_ACCESS ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE    
LEFT JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC  = USERS.COD_EC    
LEFT JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC    
LEFT JOIN DEPARTMENTS_BRANCH ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH    
LEFT JOIN DEPARTMENTS ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS    
INNER JOIN PASS_HISTORY on PASS_HISTORY.COD_USER = USERS.COD_USER    
INNER JOIN MODULES ON MODULES.COD_MODULE = USERS.COD_MODULE    
LEFT JOIN ASS_FACTOR_AUTH_COMPANY ON ASS_FACTOR_AUTH_COMPANY.COD_COMP = COMPANY.COD_COMP    
LEFT JOIN AUTHENTICATION_FACTOR ON AUTHENTICATION_FACTOR.COD_FACT = ASS_FACTOR_AUTH_COMPANY.COD_FACT    
    
WHERE  COD_ACCESS =  @USER    
   AND COMPANY.ACCESS_KEY = @ACESSKEY    
   AND PASS_HISTORY.ACTUAL = 1    
   OR     
   USERS.EMAIL =  @USER    
   AND COMPANY.ACCESS_KEY = @ACESSKEY    
   AND PASS_HISTORY.ACTUAL = 1    
    
END;

GO

IF OBJECT_ID('SP_LS_USERS_NOTIFY_RESET_PASS') IS NOT NULL
DROP PROCEDURE [SP_LS_USERS_NOTIFY_RESET_PASS];

GO
CREATE PROCEDURE [dbo].[SP_LS_USERS_NOTIFY_RESET_PASS]  
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_LS_USERS_NOTIFY_RESET_PASS]
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Caike Uchoa                        V1        07/05/2021                          CREATION
------------------------------------------------------------------------------------------*/  
AS
BEGIN


DELETE FROM NOTIFICATION_MESSAGES WHERE GENERATE_STATUS = 'Senha Expirando'
DELETE FROM MESSAGING WHERE COD_MES_CAT = (SELECT TOP 1 COD_MES_CAT FROM MESSAGING_CATEGORY WHERE TRANSLATE_DESCRIPTION = 'SENHA EXPIRANDO') 


SELECT   
    USERS.COD_USER      
   ,(-1 * (DATEDIFF(DAY,DATEADD(DAY, 90,PASS_HISTORY.CREATED_AT),GETDATE()))) AS DAYSTO_EXPIRE
   ,USERS.COD_AFFILIATOR
   ,USERS.COD_MODULE
   ,USERS.COD_EC
INTO #TEMP_RESET
FROM USERS  
INNER JOIN PASS_HISTORY  
 ON PASS_HISTORY.COD_USER = USERS.COD_USER   
AND PASS_HISTORY.ACTUAL = 1  
AND ACTIVE = 1


IF(SELECT COUNT(*) 
FROM #TEMP_RESET
WHERE COD_MODULE IN (2,5)
AND DAYSTO_EXPIRE > 0 
AND DAYSTO_EXPIRE <= 5) > 0
BEGIN

INSERT INTO MESSAGING (TITLE, CREATED_AT, EXPIRATION_DATE, COD_USER_ORIGIN, COD_USER, COD_EC, COD_AFFILIATOR,  
COD_MES_CAT, CONTENT_MESSAGE, COD_SHIPPING_OPT,REDIRECT_URL)  
 SELECT  
    'Clique para resetar a senha'  
    ,current_timestamp  
    ,DATEADD(DAY, 1, current_timestamp)  
    ,(SELECT TOP 1 COD_USER FROM USERS WHERE [COD_ACCESS] ='auth.user') 
    ,COD_USER  
    ,COD_EC  
    ,COD_AFFILIATOR  
    ,(SELECT TOP 1 COD_MES_CAT FROM MESSAGING_CATEGORY WHERE TRANSLATE_DESCRIPTION = 'SENHA EXPIRANDO')  
    ,'Sua senha expira em ' + CAST(DAYSTO_EXPIRE AS VARCHAR(100)) + ' dias'        
    ,4 
	,'/Account/ResetPasswordLogged/'
 FROM #TEMP_RESET U  
 WHERE COD_MODULE IN (2,5)
AND DAYSTO_EXPIRE > 0 
AND DAYSTO_EXPIRE <= 5


END 


SELECT COD_USER,DAYSTO_EXPIRE FROM #TEMP_RESET WHERE COD_MODULE = 1


  END

    GO
IF OBJECT_ID('SP_UPDATE_PASS_RED_USER') IS NOT NULL
DROP PROCEDURE [SP_UPDATE_PASS_RED_USER];

GO
  
CREATE PROCEDURE [dbo].[SP_UPDATE_PASS_RED_USER]  
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_UPDATE_PASS_RED_USER]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Kennedy Alef                      V1        27/07/2018                       Creation  
Caike Uchoa                       v2        30/04/2021                 alter pass e add reset logged 
------------------------------------------------------------------------------------------*/  
(  
@CODUSER INT,  
@PASS VARCHAR(200),
@RESET_LOGGED INT = 0
)  
AS  
DECLARE @USED INT = 0;  
BEGIN  

IF @RESET_LOGGED = 0
  BEGIN
--SELECT @USED=COUNT(*) FROM PASS_HISTORY WHERE PASS = @PASS AND COD_USER = @CODUSER;  
  
--IF @USED > 0  
--THROW 61001, 'PASSWORD ALREADY USED IN THE LAST 12 MONTHS',1  
  
UPDATE PASS_HISTORY SET PASS = @PASS, CREATED_AT= dbo.FN_FUS_UTF(GETDATE()) WHERE COD_USER = @CODUSER AND ACTUAL = 1 AND PASS IS NULL
  
 IF @@ROWCOUNT < 1  
 THROW 60000,'COULD NOT REGISTER PROVISORY_PASS_USER',1  
  
 UPDATE PROVISORY_PASS_USER SET ACTIVE = 0,MODIFY_DATE = GETDATE() WHERE COD_USER =  @CODUSER AND ACTIVE = 1  
 UPDATE DENIED_ACCESS_USER SET ACTIVE = 0 WHERE COD_USER = @CODUSER  
 DELETE FROM TEMP_TOKEN WHERE COD_USER = @CODUSER  


 END 
 ELSE 
 BEGIN 

 UPDATE PASS_HISTORY SET PASS = @PASS, CREATED_AT= dbo.FN_FUS_UTF(GETDATE()) WHERE COD_USER = @CODUSER AND ACTUAL = 1 AND (PASS IS NULL OR PASS IS NOT NULL)

 END 

  
END;

GO 
IF OBJECT_ID('SP_VALIDADE_LOGIN_USER') IS NOT NULL 
DROP PROCEDURE [SP_VALIDADE_LOGIN_USER]

GO
CREATE PROCEDURE [dbo].[SP_VALIDADE_LOGIN_USER]  
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_VALIDADE_LOGIN_USER]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Kennedy Alef                         V1      27/07/2018                        Creation  
Caike Uchoa                          v2      30/04/2021                      alter tempo de expiracao 
------------------------------------------------------------------------------------------*/  
(  
@ACESSKEY VARCHAR(300),  
@USER VARCHAR(100)  
)  
AS  
DECLARE @LOCK DATETIME;  
DECLARE @ACTIVE_USER INT;  
DECLARE @CODUSER INT;  
DECLARE @ACTIVE_EC INT;  
DECLARE @DATEPASS DATETIME  
DECLARE @LOGGED INT;  
  
BEGIN  
  
SELECT @LOCK = LOCKED_UP ,   
    @ACTIVE_USER = USERS.ACTIVE,  
    @CODUSER = USERS.COD_USER ,   
    @ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE ,  
    @DATEPASS = PASS_HISTORY.CREATED_AT,  
    @LOGGED = USERS.LOGGED  
  FROM   
USERS   
INNER JOIN COMPANY ON COMPANY.COD_COMP = USERS.COD_COMP   
INNER JOIN PROFILE_ACCESS ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE  
INNER JOIN PASS_HISTORY on PASS_HISTORY.COD_USER = USERS.COD_USER  
LEFT JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC  = USERS.COD_EC  
WHERE (COD_ACCESS =  @USER OR USERS.EMAIL = @USER)  
   AND COMPANY.ACCESS_KEY = @ACESSKEY  
   AND PASS_HISTORY.ACTUAL = 1  
  
  
IF @CODUSER IS NULL OR @CODUSER = 0  
THROW 61006,'USER NOT FOUND',1;  
  
  
IF DATEDIFF(MINUTE,@LOCK,GETDATE()) < 30  
THROW 61008,'USER BLOCKED',1;  
  
  
IF @ACTIVE_USER = 0  
THROW 61007,'USER INACTIVE',1;  
  
IF @ACTIVE_EC = 0  
THROW 61009,'COMMERCIAL ESTABLISHMENT INACTIVE',1;  
  
IF DATEDIFF(DAY,@DATEPASS,GETDATE()) >= 90  
THROW 61010,'PASSWORD EXPIRED',1;  
  
IF @LOGGED = 0  
THROW 61035,'NOT AUTHENTICATED',1;  
  
END;

GO

IF OBJECT_ID('SP_VALIDADE_PASS_PROV') IS NOT NULL
DROP PROCEDURE [SP_VALIDADE_PASS_PROV];

GO
CREATE PROCEDURE [dbo].[SP_VALIDADE_PASS_PROV]  
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_VALIDADE_PASS_PROV]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Kennedy Alef                       V1        27/07/2018                          Creation  
Caike Uchoa                        V2        07/05/2021                     add validate reset logado
------------------------------------------------------------------------------------------*/  
(  
@CODACESS VARCHAR(100),  
@ACCESSKEY VARCHAR(100),  
@PASS VARCHAR(100) = NULL,
@PASS_ACTUAL_INF VARCHAR(100) = NULL,
@RESET_LOGGED INT = 0
)  
AS  
DECLARE @PASSPROV VARCHAR(200) = NULL;  
DECLARE @CODEUSER INT = NULL;  
DECLARE @PASS_ACTUAL VARCHAR(200);
BEGIN  
  
IF @RESET_LOGGED = 0 
  BEGIN
SELECT @PASSPROV=PROVISORY_PASS_USER.VALUE, @CODEUSER = USERS.COD_USER FROM PROVISORY_PASS_USER  
  INNER JOIN USERS ON USERS.COD_USER = PROVISORY_PASS_USER.COD_USER  
  INNER JOIN COMPANY ON COMPANY.COD_COMP = USERS.COD_COMP    
  WHERE  COD_ACCESS = @CODACESS  
     AND  COMPANY.ACCESS_KEY = @ACCESSKEY  
     AND PROVISORY_PASS_USER.ACTIVE = 1   
     AND DATEDIFF(DAY,PROVISORY_PASS_USER.CREATED_AT,GETDATE()) <= 1 OR  
     USERS.EMAIL = @CODACESS  
     AND  COMPANY.ACCESS_KEY = @ACCESSKEY  
     AND PROVISORY_PASS_USER.ACTIVE = 1   
     AND DATEDIFF(DAY,PROVISORY_PASS_USER.CREATED_AT,GETDATE()) <= 1  
  
IF @PASSPROV IS NULL  
THROW 61012,'TEMPORARY PASSWORD NOT FOUND',1;  
  
SELECT @CODEUSER AS COD_USER,@PASS AS PASS,@PASSPROV AS PROV  

END
ELSE 
BEGIN 

SELECT 
@CODEUSER = USERS.COD_USER,
@PASS_ACTUAL = PASS_HISTORY.PASS
FROM PASS_HISTORY 
  INNER JOIN USERS ON USERS.COD_USER = PASS_HISTORY.COD_USER  
  INNER JOIN COMPANY ON COMPANY.COD_COMP = USERS.COD_COMP    
  WHERE  COD_ACCESS = @CODACESS  
     AND  COMPANY.ACCESS_KEY = @ACCESSKEY  
     AND PASS_HISTORY.ACTUAL = 1   OR  
     USERS.EMAIL = @CODACESS  
     AND  COMPANY.ACCESS_KEY = @ACCESSKEY  
	 AND PASS_HISTORY.ACTUAL = 1 


 IF @PASS_ACTUAL_INF <> @PASS_ACTUAL OR  @PASS_ACTUAL_INF IS NULL 
THROW 61081,'Invalid password',1;  

  
SELECT @CODEUSER AS COD_USER


END


END


GO

IF OBJECT_ID('SP_LS_NOTIFY_MESSAGES') IS NOT NULL
DROP PROCEDURE [SP_LS_NOTIFY_MESSAGES]

GO

CREATE PROCEDURE SP_LS_NOTIFY_MESSAGES
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_LS_NOTIFY_MESSAGES]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Caike Uchoa                        V2        14/05/2021                 add status Senha Expirando
------------------------------------------------------------------------------------------*/  
(@COD_USER INT)  
AS  
BEGIN  
  
SELECT  
 COD_NOTIFY_MESSAGE  
   ,COD_USER  
   ,CREATED_AT  
   ,EXPIRED  
   ,CONTENT_MESSAGE  
   ,LINK_REPORT  
   ,COD_SOURCE_PROCESS  
   ,NOTIFY_READ  
   ,CODE  
   ,GENERATE_STATUS  
FROM NOTIFICATION_MESSAGES  
WHERE COD_USER = @COD_USER  
AND NOTIFY_READ = 0  
AND GENERATE_STATUS IN ('Concluído','Senha Expirando') 
  
END;


  GO

IF OBJECT_ID('SP_READ_NOTIFICATION_MESSAGE') IS NOT NULL
DROP PROCEDURE [SP_READ_NOTIFICATION_MESSAGE]

GO
CREATE PROCEDURE SP_READ_NOTIFICATION_MESSAGE 
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_READ_NOTIFICATION_MESSAGE]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Caike Uchoa                        V2        14/05/2021                   add @DELETE_NOTIFY
------------------------------------------------------------------------------------------*/  
(
@COD_NOTIFY_MESSAGE INT,  
@NOTIFY_READ INT = NULL,
@DELETE_NOTIFY INT = 0
)  
AS  
BEGIN  
  
IF @DELETE_NOTIFY = 0
BEGIN

UPDATE NOTIFICATION_MESSAGES  
SET NOTIFY_SENT = 1  
   ,NOTIFY_READ = ISNULL(@NOTIFY_READ, 0)  
WHERE COD_NOTIFY_MESSAGE = @COD_NOTIFY_MESSAGE;  

END
ELSE 
BEGIN 

UPDATE NOTIFICATION_MESSAGES  
SET NOTIFY_SENT = 1  
   ,NOTIFY_READ = ISNULL(@NOTIFY_READ, 0)  
   ,CREATED_AT = DATEADD(DAY,-3,dbo.FN_FUS_UTF(GETDATE()))
WHERE COD_NOTIFY_MESSAGE = @COD_NOTIFY_MESSAGE;  

END 


END;


GO

IF OBJECT_ID('SP_CLEAR_MESSAGES') IS NOT NULL
DROP PROCEDURE SP_CLEAR_MESSAGES

GO
CREATE PROCEDURE SP_CLEAR_MESSAGES    
/*----------------------------------------------------------------------------------------          
Procedure Name: [SP_MESSAGES_USER]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author                          VERSION        Date                            Description          
------------------------------------------------------------------------------------------          
Lucas Aguiar                       V1        2019-10-22                          Creation    
Caike Uchôa                        V2        2021-05-18                           alter
------------------------------------------------------------------------------------------*/              
(
@COD_USER INT = NULL
)  
AS
BEGIN  
  
IF (@COD_USER IS NULL)
BEGIN

DELETE FROM MESSAGING  
WHERE current_timestamp > EXPIRATION_DATE;  

END 
ELSE 
BEGIN

DELETE FROM MESSAGING  
WHERE COD_MES_CAT = (SELECT TOP 1 COD_MES_CAT FROM MESSAGING_CATEGORY WHERE TRANSLATE_DESCRIPTION = 'SENHA EXPIRANDO')
AND COD_USER = @COD_USER 

END



END;

GO

--ST-2073

GO

--
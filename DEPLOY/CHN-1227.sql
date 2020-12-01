--ST-1528

GO 

IF OBJECT_ID('SP_LS_REP') IS NOT NULL
DROP PROCEDURE [SP_LS_REP];

GO
CREATE PROCEDURE [dbo].[SP_LS_REP]  
/*----------------------------------------------------------------------------------------          
Procedure Name: [SP_LS_EC_COMPANY]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author                          VERSION        Date                            Description          
------------------------------------------------------------------------------------------          
LUCAS AGUIAR                       V1       21/01/2019                         Creation          
Caike Uchoa                        V2       30/10/2020                      add affiliator
Caike Uchoa                        v3       12/11/2020                     Add filtro por cnpj
Caike Uchoa                        v4       13/11/2020                Trazer representante padrão
------------------------------------------------------------------------------------------*/ 
(
@COD_COMP INT,  
@Search VARCHAR(100) = NULL,  
@cod_affiliator INT = NULL)  
AS  
BEGIN  

SELECT  
 SR.COD_SALES_REP  
   ,USERS.IDENTIFICATION  
   ,USERS.EMAIL
   ,ISNULL(AFFILIATOR.[NAME],'CELER') AS AFFILIATOR
INTO #TEMP_REPRESENTANTE
FROM SALES_REPRESENTATIVE SR  
INNER JOIN USERS  
 ON USERS.COD_USER = SR.COD_USER  
INNER JOIN ADDRESS_SALES_REP  
 ON ADDRESS_SALES_REP.COD_SALES_REP = SR.COD_SALES_REP  
LEFT JOIN AFFILIATOR 
 ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
WHERE SR.COD_COMP = @COD_COMP  
AND SR.ACTIVE = 1  
AND ADDRESS_SALES_REP.ACTIVE = 1  
AND (USERS.COD_AFFILIATOR = @cod_affiliator  
OR @cod_affiliator IS NULL)  
AND (@Search IS NULL  
OR (USERS.IDENTIFICATION LIKE ('%' + @Search COLLATE SQL_Latin1_General_CP1251_CI_AS + '%'))
or USERS.CPF_CNPJ LIKE ('%' + @Search + '%'))  

  
IF @cod_affiliator IS NOT NULL
BEGIN

INSERT INTO #TEMP_REPRESENTANTE (COD_SALES_REP,IDENTIFICATION,EMAIL,AFFILIATOR)
SELECT 
COD_SALES_REP,
IDENTIFICATION,
EMAIL,
ISNULL(AFFILIATOR.[NAME],'') AS AFFILIATOR
FROM SALES_REPRESENTATIVE
JOIN USERS ON USERS.COD_USER = SALES_REPRESENTATIVE.COD_USER
LEFT JOIN AFFILIATOR 
 ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
WHERE DEFAULT_SR = 1

SELECT * FROM #TEMP_REPRESENTANTE
ORDER BY IDENTIFICATION ASC

DROP TABLE #TEMP_REPRESENTANTE


END 
ELSE 
BEGIN 

SELECT * FROM #TEMP_REPRESENTANTE
ORDER BY IDENTIFICATION ASC

DROP TABLE #TEMP_REPRESENTANTE

END


END;


GO 

IF OBJECT_ID('SP_LS_REP_SALES_COMP') IS NOT NULL
DROP PROCEDURE [SP_LS_REP_SALES_COMP];

GO
CREATE PROCEDURE [dbo].[SP_LS_REP_SALES_COMP]                              
/*----------------------------------------------------------------------------------------                              
Procedure Name: [SP_LS_REP_SALES_COMP]                              
Project.......: TKPP                              
------------------------------------------------------------------------------------------                              
Author                          VERSION        Date                            Description                              
------------------------------------------------------------------------------------------                              
Kennedy Alef     V1    27/07/2018      Creation                              
Elir Ribeiro    v2     13/09/2018      Change                            
LUCAS AGUIAR    V3     21/01/2019      CHANGE               
Caike Uchôa     V4     23/01/2019      Change                         
Elir Ribeiro    v5     25/01/2019      Change        
Caike Uchoa     v6     07/02/2019      Change        
Caike Uchoa     v7     06-11-2020      Add afiliator
------------------------------------------------------------------------------------------*/                              
(                              
@CODCOMP INT,                          
@CODREP INT = NULL,                      
@CODAFL INT = NULL                    
)                              
AS                              
DECLARE @QUERY NVARCHAR(MAX);  
                        
                          
                               
BEGIN  
  
SET @QUERY = '                             
                      
SELECT                                
SR.COD_SALES_REP AS INSIDE_CODE,                              
USERS.IDENTIFICATION AS NAME ,                              
USERS.EMAIL AS EMAIL,                          
USERS.CPF_CNPJ,                          
SR.COD_SEX,                    
SR.ACTIVE,                                
ASR.ADDRESS,                          
ASR.NUMBER as NUMBER_ADD,                          
ASR.COMPLEMENT,                          
ASR.CEP,                          
ASR.REFERENCE_POINT,                          
ASR.COD_NEIGH,                          
NEIGHBORHOOD.NAME as NAME_NEIGHBORHOOD,                      
CITY.COD_CITY,                    
CITY.NAME AS NAME_CITY,                    
STATE.COD_STATE,                    
STATE.UF,                    
COUNTRY.COD_COUNTRY,                    
COUNTRY.NAME AS NAME_COUNTRY,                    
CSR.NUMBER,                          
CSR.COD_TP_CONT,                          
CSR.COD_OPER,                             
CSR.DDD,                      
TE.CODE,
AFFILIATOR.[NAME] AS AFFILIATOR,
SR.DEFAULT_SR
 FROM SALES_REPRESENTATIVE SR                              
INNER JOIN USERS ON USERS.COD_USER = SR.COD_USER                  
INNER JOIN ADDRESS_SALES_REP ASR ON ASR.COD_SALES_REP = SR.COD_SALES_REP AND ASR.ACTIVE = 1                         
INNER JOIN CONTACT_SALES_REP CSR ON CSR.COD_SALES_REP = SR.COD_SALES_REP AND CSR.ACTIVE = 1                    
INNER JOIN TYPE_ESTAB TE ON TE.COD_TYPE_ESTAB = SR.COD_TYPE_ESTAB                      
INNER JOIN NEIGHBORHOOD ON NEIGHBORHOOD.COD_NEIGH = ASR.COD_NEIGH                    
INNER JOIN CITY ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY                    
INNER JOIN STATE ON STATE.COD_STATE = CITY.COD_STATE                    
INNER JOIN COUNTRY ON COUNTRY.COD_COUNTRY = STATE.COD_COUNTRY       
LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR= USERS.COD_AFFILIATOR
WHERE SR.COD_COMP = @CODCOMP                                  
                  
'  
                        
                          
IF @CODREP IS NOT NULL  
SET @QUERY = @QUERY + ' AND SR.COD_SALES_REP = @CODREP '  
                        
                        
IF @CODAFL IS NOT NULL  
SET @QUERY = @QUERY + ' AND USERS.COD_AFFILIATOR = @CODAFL OR SR.DEFAULT_SR = 1'  
  
--SELECT                        
-- @QUERY;                        
EXEC sp_executesql @QUERY  
      ,N'                                              
   @CODCOMP INT,                          
   @CODREP INT,              
   @CODAFL INT     
                                   
  '  
      ,@CODCOMP = @CODCOMP  
      ,@CODREP = @CODREP  
      ,@CODAFL = @CODAFL  
END;  
  
--ST-1528

GO

--ET-1560 (ET-489)

IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'ACTIVE'
	AND object_id = OBJECT_ID(N'ACQUIRER_KEYS_CREDENTIALS'))
BEGIN
ALTER TABLE ACQUIRER_KEYS_CREDENTIALS ADD ACTIVE INT
END
GO

IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'COD_USER'
	AND object_id = OBJECT_ID(N'ACQUIRER_KEYS_CREDENTIALS'))
BEGIN
ALTER TABLE ACQUIRER_KEYS_CREDENTIALS ADD COD_USER INT FOREIGN KEY (COD_USER) REFERENCES USERS (COD_USER)
END
GO
IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'COD_USER_ALT'
	AND object_id = OBJECT_ID(N'ACQUIRER_KEYS_CREDENTIALS'))
BEGIN
ALTER TABLE ACQUIRER_KEYS_CREDENTIALS ADD COD_USER_ALT INT FOREIGN KEY (COD_USER) REFERENCES USERS (COD_USER)
END
GO
IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'COD_USER_ALT'
	AND object_id = OBJECT_ID(N'ACQUIRER_KEYS_CREDENTIALS'))
BEGIN
ALTER TABLE ACQUIRER_KEYS_CREDENTIALS ADD COD_USER_ALT INT FOREIGN KEY (COD_USER) REFERENCES USERS (COD_USER)
END
GO

IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'MODIFY_DATE'
	AND object_id = OBJECT_ID(N'ACQUIRER_KEYS_CREDENTIALS'))
BEGIN
ALTER TABLE ACQUIRER_KEYS_CREDENTIALS ADD MODIFY_DATE DATETIME
END
GO
IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'CREATE_AT'
	AND object_id = OBJECT_ID(N'ACQUIRER_KEYS_CREDENTIALS'))
BEGIN
ALTER TABLE ACQUIRER_KEYS_CREDENTIALS ADD CREATE_AT DATETIME
END
GO


IF OBJECT_ID('SP_REG_CREDENTIALS_DATA_EC_ACQ_REGISTER') IS NOT NULL DROP PROCEDURE SP_REG_CREDENTIALS_DATA_EC_ACQ_REGISTER;
GO
CREATE PROCEDURE [dbo].[SP_REG_CREDENTIALS_DATA_EC_ACQ_REGISTER]                          
/*----------------------------------------------------------------------------------------                          
Procedure Name: [SP_REG_CREDENTIALS_DATA_EC_ACQ_REGISTER]                          
Project.......: TKPP                          
------------------------------------------------------------------------------------------                          
Author                          VERSION        Date                            Description                          
------------------------------------------------------------------------------------------                          
Elir Ribeiro           v1     05/11/2020              Created                        
------------------------------------------------------------------------------------------*/                          
                        
(                          
 @COD_EC INT,                
  @NAME VARCHAR(100) ,        
  @VALUE VARCHAR(200) ,        
  @COD_AC INT,
  @COD_USER INT
                   
)                          
AS              
BEGIN
INSERT INTO ACQUIRER_KEYS_CREDENTIALS (CODE_EC, NAME, VALUE, COD_AC, ACTIVE, COD_USER, CREATE_AT)
	VALUES (@COD_EC, @NAME, @VALUE, @COD_AC, 1, @COD_USER, GETDATE())
IF @@rowcount < 1
THROW 600001, 'COULD NOT REGISTER SP_REG_CREDENTIALS_DATA_EC_ACQ_REGISTER', 1;

END

GO

IF OBJECT_ID('SP_LS_ACK_CREDENTIALS') IS NOT NULL DROP PROCEDURE SP_LS_ACK_CREDENTIALS;
GO
CREATE PROCEDURE SP_LS_ACK_CREDENTIALS  
  (@COD_EC INT)  
  AS
SELECT
	ACQUIRER_KEYS_CREDENTIALS.[NAME]
   ,ACQUIRER_KEYS_CREDENTIALS.VALUE [NUMERO LÓGICO]
   ,ACQUIRER.[NAME] ACQUIRER_NAME
   ,ACQUIRER_KEYS_CREDENTIALS.CODE_EC
   ,ACQUIRER_KEYS_CREDENTIALS.COD_KEY_AC ID
FROM ACQUIRER_KEYS_CREDENTIALS
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ACQUIRER_KEYS_CREDENTIALS.COD_AC
WHERE CODE_EC = @COD_EC
AND ACQUIRER_KEYS_CREDENTIALS.ACTIVE = 1

GO





IF OBJECT_ID('SP_DISABLE_CREDENTIALS_EC_ACQ') IS NOT NULL DROP PROCEDURE SP_DISABLE_CREDENTIALS_EC_ACQ;
GO
CREATE PROCEDURE [dbo].[SP_DISABLE_CREDENTIALS_EC_ACQ]  
/*----------------------------------------------------------------------------------------                        
Procedure Name: [SP_DISABLE_CREDENTIALS_EC_ACQ]                        
Project.......: TKPP                        
------------------------------------------------------------------------------------------                        
Author                          VERSION        Date                            Description                        
------------------------------------------------------------------------------------------                        
Elir Ribeiro  v1     09/11/2020       Created                      
------------------------------------------------------------------------------------------*/                        
        
@CODEC INT,
@ID INT,
@CODUSER INT      
AS
UPDATE ACQUIRER_KEYS_CREDENTIALS
SET ACTIVE = 0
   ,COD_USER_ALT = @CODUSER
   ,MODIFY_DATE = GETDATE()
WHERE CODE_EC = @CODEC
AND COD_KEY_AC = @ID

GO

IF OBJECT_ID('SP_LS_ACK_EDIT_CREDENTIAILS') IS NOT NULL DROP PROCEDURE SP_LS_ACK_EDIT_CREDENTIAILS;
GO
CREATE PROCEDURE SP_LS_ACK_EDIT_CREDENTIAILS 
@COD_ACK INT
AS
SELECT
	ACQUIRER_KEYS_CREDENTIALS.NAME
   ,ACQUIRER_KEYS_CREDENTIALS.VALUE
   ,ACQUIRER.COD_AC [ACQUIRER]
FROM ACQUIRER_KEYS_CREDENTIALS
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ACQUIRER_KEYS_CREDENTIALS.COD_AC
WHERE ACQUIRER_KEYS_CREDENTIALS.COD_KEY_AC = @COD_ACK

GO

IF OBJECT_ID('SP_UP_ACK_CREDENTIALS') IS NOT NULL DROP PROCEDURE SP_UP_ACK_CREDENTIALS;
GO
CREATE PROCEDURE [dbo].[SP_UP_ACK_CREDENTIALS]                        
/*----------------------------------------------------------------------------------------                        
Procedure Name: [SP_UP_ACK_CREDENTIALS]                        
Project.......: TKPP                        
------------------------------------------------------------------------------------------                        
Author                          VERSION        Date                            Description                        
------------------------------------------------------------------------------------------                        
Elir Ribeiro  v1     09/11/2020       Created                      
------------------------------------------------------------------------------------------*/                        
                      
(                        
 @COD_ACK INT,
 @COD_AC INT,
 @NAME VARCHAR(200),
 @VALUE VARCHAR(200),
 @COD_USER INT

                 
)                        
AS            
BEGIN
UPDATE ACQUIRER_KEYS_CREDENTIALS
SET NAME = @NAME
   ,VALUE = @VALUE
   ,COD_AC = @COD_AC
   ,COD_USER_ALT = @COD_USER
   ,MODIFY_DATE = GETDATE()
WHERE COD_KEY_AC = @COD_ACK
END

--ST-1560 (ET-489)

GO

--ST-1590

IF OBJECT_ID('SP_FD_EC') IS NOT NULL DROP PROCEDURE SP_FD_EC;
GO
CREATE PROCEDURE [dbo].[SP_FD_EC]    
    
/*----------------------------------------------------------------------------------------            
Project.......: TKPP            
------------------------------------------------------------------------------------------            
Author                          VERSION        Date                            Description            
------------------------------------------------------------------------------------------            
Kennedy Alef                V1   27/07/2018   Creation            
Gian Luca Dalle Cort        V2   04/10/2018   Changed            
Lucas Aguiar                V3   15/10/2018   Changed            
Elir Ribeiro                V4   14/11/2018   Changed            
Luiz Aquino                 V5   26/12/2018   Add Column Spot_tax            
Lucas Aguiar                V6   01/07/2019   Add Rotina de travar agenda            
Elir Ribeiro                V7   02/08/2019   Add Situa??o Risco            
Lucas Aguiar                V8   04-09-2019   IS_PROVIDER            
Marcus Gall Barreira        V9   11-11-2019   Add parameter Branch Business            
Marcus Gall Barreira        V10  19-11-2019   Add informações de endereço do EC            
Marcus Gall                 v11  06-05-2020   Add ModifyDate            
Kennedy Alef                v12  05/08/2020   otimização da consulta        
Elir Ribeiro                v13  23/09/2020   add address to affiliator       
Elir Ribeiro                v14  10/11/2020    add comment risk   
------------------------------------------------------------------------------------------*/ (@CPF_CNPJ VARCHAR(14),    
@COD_REP INT,    
@ID_EC INT,    
@SEGMENT INT,    
@COMP INT,    
@TYPE VARCHAR(100),    
@COD_PLAN INT = NULL,    
@COD_AFF INT = NULL,    
@Active BIT = NULL,    
@PersonType VARCHAR(100) = NULL,    
@CODSIT INT = NULL,    
@WAS_BLOCKED_FINANCE INT = NULL,    
@COD_SITUATION_RISK INT = NULL,    
@IS_PROVIDER INT = NULL,    
@BRANCH_BUSINESS INT = NULL,    
@RISK_SITUATION_LIST [CODE_TYPE] READONLY,    
@CREATED_FROM DATETIME = NULL,    
@CREATED_UNTIL DATETIME = NULL)    
AS    
 DECLARE @QUERY_ NVARCHAR(MAX);    
 DECLARE @COD_BLOCKED_FINANCE INT;    
 BEGIN    
  SET @QUERY_ = N'            
        SELECT       
        
    BRANCH_EC.COD_EC,            
    BRANCH_EC.CODE,            
    dbo.FN_FUS_UTF(BRANCH_EC.CREATED_AT) AS CREATED_AT,            
    BRANCH_EC.NAME,            
    COMMERCIAL_ESTABLISHMENT.TRADING_NAME,            
    BRANCH_EC.COD_BRANCH,            
    BRANCH_EC.CPF_CNPJ,            
    BRANCH_EC.DOCUMENT_TYPE,            
    BRANCH_EC.EMAIL,            
    BRANCH_EC.STATE_REGISTRATION,            
    BRANCH_EC.MUNICIPAL_REGISTRATION,            
    BRANCH_EC.TRANSACTION_LIMIT,            
    BRANCH_EC.LIMIT_TRANSACTION_DIALY,            
    BRANCH_EC.BIRTHDATE,            
    TYPE_ESTAB.CODE AS TYPE_EC,            
    BRANCH_EC.TYPE_BRANCH AS TYPE_BR,            
    SEGMENTS.NAME AS SEGMENTS,            
    BRANCH_EC.ACTIVE,            
    USERS.IDENTIFICATION AS SALES_REP,            
    DEPARTMENTS_BRANCH.COD_PLAN,            
    TYPE_RECEIPT.[CODE] AS ACCOUNT_TYPE,            
    COUNT(*) AS QTY,            
    AFFILIATOR.COD_AFFILIATOR,            
    ISNULL(AFFILIATOR.NAME, ''CELER'')  AS NAME_AFFILIATOR,            
    SITUATION_REQUESTS.NAME AS SIT_REQUEST,            
    ISNULL(COMMERCIAL_ESTABLISHMENT.DEFAULT_EC, 0) AS DEFAULT_EC,            
    COMMERCIAL_ESTABLISHMENT.SPOT_TAX,            
    TRADUCTION_SITUATION.SITUATION_TR,            
    TRADUCTION_RISK_SITUATION.RISK_SITUATION_TR            
    , COMMERCIAL_ESTABLISHMENT.IS_PROVIDER            
    , BRANCH_BUSINESS.NAME AS BRANCH_BUSINESS            
    , NEIGHBORHOOD.[NAME] AS NEIGHBORHOOD            
    , CITY.[NAME] AS CITY            
    , STATE.[NAME] AS STATE            
    , dbo.FN_FUS_UTF(COMMERCIAL_ESTABLISHMENT.MODIFY_DATE) AS MODIFY_DATE          
 , COMMERCIAL_ESTABLISHMENT.TCU_ACCEPTED      
 ,ADDRESS_BRANCH.ADDRESS AS [ADDRESS_AFFILIATOR]      
 ,ADDRESS_BRANCH.NUMBER AS [NUMBER_AFFILIATOR]      
 ,ADDRESS_BRANCH.COMPLEMENT AS [COMPLEMENT_AFFILIATOR]      
 ,ADDRESS_BRANCH.CEP AS [ZIPCODE_AFFILIATOR],  
 COMMERCIAL_ESTABLISHMENT.RISK_REASON  
 ,(SELECT top 1 CONCAT(C.DDD,C.NUMBER) FROM CONTACT_BRANCH C WHERE C.ACTIVE = 1 AND BRANCH_EC.COD_BRANCH = C.COD_BRANCH) AS [PHONE_AFFILIATOR]      
       FROM COMMERCIAL_ESTABLISHMENT            
   INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC AND BRANCH_EC.CPF_CNPJ = COMMERCIAL_ESTABLISHMENT.CPF_CNPJ             
   INNER JOIN SEGMENTS ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG            
   INNER JOIN TYPE_ESTAB ON COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB = TYPE_ESTAB.COD_TYPE_ESTAB            
   INNER JOIN SALES_REPRESENTATIVE ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP            
   INNER JOIN USERS ON USERS.COD_USER = SALES_REPRESENTATIVE.COD_USER            
   INNER JOIN DEPARTMENTS_BRANCH ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH              
   INNER JOIN TYPE_RECEIPT ON TYPE_RECEIPT.COD_TYPE_REC = BRANCH_EC.COD_TYPE_REC            
   INNER JOIN SITUATION_REQUESTS ON SITUATION_REQUESTS.COD_SIT_REQ = COMMERCIAL_ESTABLISHMENT.COD_SIT_REQ            
   LEFT JOIN BRANCH_BUSINESS ON BRANCH_BUSINESS.COD_BRANCH_BUSINESS = COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS            
   LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR            
   LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_SITUATION            
   LEFT JOIN TRADUCTION_RISK_SITUATION ON TRADUCTION_RISK_SITUATION.COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION            
   INNER JOIN ADDRESS_BRANCH  ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH AND ADDRESS_BRANCH.ACTIVE = 1 AND  COMMERCIAL_ESTABLISHMENT.COD_EC =  BRANCH_EC.COD_EC          
   INNER JOIN NEIGHBORHOOD  ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH            
   INNER JOIN CITY    ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY            
   INNER JOIN STATE   ON STATE.COD_STATE = CITY.COD_STATE       
      
         
        
  WHERE            
   COMMERCIAL_ESTABLISHMENT.COD_COMP = @COMP ';    
  SELECT    
   @COD_BLOCKED_FINANCE = COD_SITUATION    
  FROM SITUATION    
  WHERE NAME = 'LOCKED FINANCIAL SCHEDULE';    
  IF @ID_EC IS NOT NULL    
  BEGIN    
   IF @TYPE = 'BRANCH'    
    SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.COD_BRANCH = @ID_EC ';    
   ELSE    
    SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_EC = @ID_EC ';    
  END;    
  IF @SEGMENT IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SEG = @SEGMENT ';    
  IF @COD_REP IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SALES_REP = @COD_REP ';    
  IF @TYPE IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.TYPE_BRANCH = @TYPE ';    
  IF @CPF_CNPJ IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.CPF_CNPJ = @CPF_CNPJ ';    
  IF @COD_PLAN IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND  DEPARTMENTS_BRANCH.COD_PLAN = @COD_PLAN ';    
  IF @COD_AFF IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFF';    
  IF @Active IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.ACTIVE = @Active';    
  IF @IS_PROVIDER IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.IS_PROVIDER = @IS_PROVIDER';    
  IF @PersonType IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND TYPE_ESTAB.CODE = @PersonType';    
  IF @CODSIT IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SIT_REQ = @CODSIT';    
  IF @WAS_BLOCKED_FINANCE = 1    
  BEGIN    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SITUATION = @COD_BLOCKED_FINANCE';    
  END;    
  ELSE    
  IF @WAS_BLOCKED_FINANCE = 0    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SITUATION <> @COD_BLOCKED_FINANCE';   
  IF @COD_SITUATION_RISK IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION = @COD_SITUATION_RISK';    
  IF @BRANCH_BUSINESS IS NOT NULL    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS = @BRANCH_BUSINESS';    
  IF EXISTS (SELECT TOP 1    
     CODE    
    FROM @RISK_SITUATION_LIST)    
   SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION IN (SELECT CODE FROM @RISK_SITUATION_LIST)';    
  SET @QUERY_ = CONCAT(@QUERY_, ' GROUP BY      
      BRANCH_EC.CREATED_AT,            
         BRANCH_EC.COD_EC,            
    COMMERCIAL_ESTABLISHMENT.TRADING_NAME,      
                                
                              BRANCH_EC.CODE,            
                              BRANCH_EC.NAME,            
                              BRANCH_EC.TRADING_NAME,            
                              BRANCH_EC.COD_BRANCH,            
                              BRANCH_EC.CPF_CNPJ,            
                              BRANCH_EC.DOCUMENT_TYPE,            
                              BRANCH_EC.EMAIL,            
                              BRANCH_EC.STATE_REGISTRATION,            
                              BRANCH_EC.MUNICIPAL_REGISTRATION,            
                              BRANCH_EC.TRANSACTION_LIMIT,            
                              BRANCH_EC.LIMIT_TRANSACTION_DIALY,            
                              BRANCH_EC.BIRTHDATE,            
                              TYPE_ESTAB.CODE,            
                              BRANCH_EC.TYPE_BRANCH,            
                              SEGMENTS.NAME,            
                              BRANCH_BUSINESS.NAME,            
                              BRANCH_EC.ACTIVE,            
                              USERS.IDENTIFICATION,            
                              DEPARTMENTS_BRANCH.COD_PLAN,            
                              TYPE_RECEIPT.[CODE],            
                              AFFILIATOR.COD_AFFILIATOR,            
                              AFFILIATOR.NAME,            
                              SITUATION_REQUESTS.NAME,            
                              COMMERCIAL_ESTABLISHMENT.DEFAULT_EC,            
                              COMMERCIAL_ESTABLISHMENT.SPOT_TAX ,            
                              TRADUCTION_SITUATION.SITUATION_TR,            
                              TRADUCTION_RISK_SITUATION.RISK_SITUATION_TR,            
                              COMMERCIAL_ESTABLISHMENT.IS_PROVIDER            
                              , NEIGHBORHOOD.[NAME]            
                              , CITY.[NAME]            
                              , STATE.[NAME]            
         , COMMERCIAL_ESTABLISHMENT.MODIFY_DATE          
   , COMMERCIAL_ESTABLISHMENT.TCU_ACCEPTED       
   ,ADDRESS_BRANCH.ADDRESS      
   ,ADDRESS_BRANCH.CEP      
   ,ADDRESS_BRANCH.COMPLEMENT      
   ,ADDRESS_BRANCH.NUMBER  
   ,COMMERCIAL_ESTABLISHMENT.RISK_REASON  
   ORDER BY COMMERCIAL_ESTABLISHMENT.TRADING_NAME      
         
                              ');    
  EXEC sp_executesql @QUERY_    
        ,N'            
  @CPF_CNPJ VARCHAR(14),            
  @COD_REP INT,            
  @ID_EC INT,            
  @SEGMENT INT,            
  @COMP INT,            
  @TYPE VARCHAR(100),            
  @COD_PLAN INT,            
  @COD_AFF INT,            
  @Active BIT,            
  @PersonType VARCHAR(100),            
  @CODSIT INT,            
  @WAS_BLOCKED_FINANCE INT,            
  @COD_SITUATION_RISK INT,            
  @IS_PROVIDER INT,            
  @BRANCH_BUSINESS INT,            
  @RISK_SITUATION_LIST [CODE_TYPE] READONLY            
 '    
        ,@CPF_CNPJ = @CPF_CNPJ    
        ,@COD_REP = @COD_REP    
        ,@ID_EC = @ID_EC    
        ,@SEGMENT = @SEGMENT    
        ,@COMP = @COMP    
        ,@TYPE = @TYPE    
        ,@COD_PLAN = @COD_PLAN    
        ,@COD_AFF = @COD_AFF    
        ,@Active = @Active    
        ,@PersonType = @PersonType    
        ,@CODSIT = @CODSIT    
        ,@WAS_BLOCKED_FINANCE = @WAS_BLOCKED_FINANCE    
        ,@COD_SITUATION_RISK = @COD_SITUATION_RISK    
        ,@IS_PROVIDER = @IS_PROVIDER    
        ,@BRANCH_BUSINESS = @BRANCH_BUSINESS    
        ,@RISK_SITUATION_LIST = @RISK_SITUATION_LIST;    
 END;    

 --ST-1590

 GO

 --ST-1607

 IF OBJECT_ID('SP_PAYMENT_PROTOCOL_TITLES_ARRANGE') IS NOT NULL
    DROP PROCEDURE [SP_PAYMENT_PROTOCOL_TITLES_ARRANGE];
GO  
CREATE PROCEDURE [DBO].[SP_PAYMENT_PROTOCOL_TITLES_ARRANGE](    
 @COD_PAY_PROT INT)
 /*******************************************************************************************  
----------------------------------------------------------------------------------------    
Procedure Name: [SP_PAYMENT_PROTOCOL_TITLES_ARRANGE]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author VERSION Date Description    
------------------------------------------------------------------------------------------    
Elir Ribeiro  v? 16-11-2020 add groos amount 
------------------------------------------------------------------------------------------  
*******************************************************************************************/  

AS    
BEGIN    
    
 -- CONDITIONAL FOR LEGACY  
  
IF (SELECT COUNT(*) FROM PROTOCOLS WHERE COD_PAY_PROT=@COD_PAY_PROT AND ISNULL(LEGACY,1) = 0) >0  
BEGIN  
  
SELECT    
 [T].[CODE] AS [TRANSACTION_CODE]    
   ,[T].[AMOUNT] AS [TRANSACTION_AMOUNT]    
   ,CONCAT(CONCAT([TRANSACTION_TITLES].[PLOT], '/'), [T].[PLOTS]) AS [PLOT]    
   ,[dbo].[FN_FUS_UTF]([T].[CREATED_AT]) AS [TRANSACTION_DATE]    
   ,[ARRANG_TO_PAY].[COD_EC]    
   ,CAST(((([TRANSACTION_TITLES].[AMOUNT] * (1 - ([TRANSACTION_TITLES].[TAX_INITIAL] / 100))) *    
  IIF([TRANSACTION_TITLES].[ANTICIP_PERCENT] IS NULL, 1,    
  1 - ((([TRANSACTION_TITLES].[ANTICIP_PERCENT] / 30) * COALESCE(IIF([TRANSACTION_TITLES].[IS_SPOT] = 1,    
  DATEDIFF(DAY, [TRANSACTION_TITLES].[PREVISION_PAY_DATE], [TRANSACTION_TITLES].[ORIGINAL_RECEIVE_DATE]), [TRANSACTION_TITLES].[QTY_DAYS_ANTECIP]),    
  ([TRANSACTION_TITLES].[PLOT] * 30) - 1)) /    
  100))) - (IIF([TRANSACTION_TITLES].[PLOT] = 1, [TRANSACTION_TITLES].[RATE], 0))) AS DECIMAL(22, 6)) AS [PLOT_AMOUNT_NET]  
 ,DETAILS_ARRANG_TO_PAY.AMOUNT AS NET_TO_PAY   
   ,[TRANSACTION_TITLES].[PREVISION_PAY_DATE]    
   ,'TITLE' AS [TYPE_RELEASE]    
   ,ARRANG_TO_PAY.[COD_FIN_SCH_FILE]    
   ,[FINANCE_SCHEDULE_FILE].[CREATED_AT] AS [FILE_DATE]    
   ,[FINANCE_SCHEDULE_FILE].file_name    
   ,[FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE]    
   ,ARRANG_TO_PAY.[IS_LOCK]    
   ,[TRANSACTION_TITLES].[IS_SPOT]    
   ,[P].[PROTOCOL]
   , CAST([T].[AMOUNT] / [T].[PLOTS] AS DECIMAL (22,6)) AS [GROSS_AMOUNT]  
FROM [ARRANG_TO_PAY]  
JOIN DETAILS_ARRANG_TO_PAY   
ON DETAILS_ARRANG_TO_PAY.COD_ARR_PAY = [ARRANG_TO_PAY].COD_ARR_PAY  
JOIN FINANCE_CALENDAR   
 ON FINANCE_CALENDAR.COD_FIN_CALENDAR = ARRANG_TO_PAY.COD_FIN_CALENDAR  
JOIN [TRANSACTION_TITLES]  WITH (NOLOCK)    
 ON [TRANSACTION_TITLES].COD_TITLE = DETAILS_ARRANG_TO_PAY.COD_TITTLE    
JOIN [TRANSACTION] AS [T] WITH (NOLOCK)    
 ON [T].[COD_TRAN] = [TRANSACTION_TITLES].[COD_TRAN]    
JOIN [PROTOCOLS] AS [P]    
 ON [P].[COD_PAY_PROT] = [ARRANG_TO_PAY].[COD_PAY_PROT]    
LEFT JOIN [FINANCE_SCHEDULE_FILE]    
 ON [FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE] = ARRANG_TO_PAY.[COD_FIN_SCH_FILE]    
WHERE  
--FINANCE_CALENDAR.[ACTIVE]  <> 99    
--AND FINANCE_CALENDAR.[COD_SITUATION] = 8    
--AND  
[P].COD_PAY_PROT = @COD_PAY_PROT;    
  
END;  
ELSE  
BEGIN  
  
SELECT    
 [T].[CODE] AS [TRANSACTION_CODE]    
   ,[T].[AMOUNT] AS [TRANSACTION_AMOUNT]    
   ,CONCAT(CONCAT([TRANSACTION_TITLES].[PLOT], '/'), [T].[PLOTS]) AS [PLOT]    
   ,[dbo].[FN_FUS_UTF]([T].[CREATED_AT]) AS [TRANSACTION_DATE]    
   ,FINANCE_CALENDAR.[COD_EC]    
   ,CAST(((([TRANSACTION_TITLES].[AMOUNT] * (1 - ([TRANSACTION_TITLES].[TAX_INITIAL] / 100))) *    
  IIF([TRANSACTION_TITLES].[ANTICIP_PERCENT] IS NULL, 1,    
  1 - ((([TRANSACTION_TITLES].[ANTICIP_PERCENT] / 30) * COALESCE(IIF([TRANSACTION_TITLES].[IS_SPOT] = 1,    
  DATEDIFF(DAY, [TRANSACTION_TITLES].[PREVISION_PAY_DATE], [TRANSACTION_TITLES].[ORIGINAL_RECEIVE_DATE]), [TRANSACTION_TITLES].[QTY_DAYS_ANTECIP]),    
  ([TRANSACTION_TITLES].[PLOT] * 30) - 1)) /    
  100))) - (IIF([TRANSACTION_TITLES].[PLOT] = 1, [TRANSACTION_TITLES].[RATE], 0))) AS DECIMAL(22, 6)) AS [PLOT_AMOUNT_NET]  
 ,CAST(((([TRANSACTION_TITLES].[AMOUNT] * (1 - ([TRANSACTION_TITLES].[TAX_INITIAL] / 100))) *    
  IIF([TRANSACTION_TITLES].[ANTICIP_PERCENT] IS NULL, 1,    
  1 - ((([TRANSACTION_TITLES].[ANTICIP_PERCENT] / 30) * COALESCE(IIF([TRANSACTION_TITLES].[IS_SPOT] = 1,    
  DATEDIFF(DAY, [TRANSACTION_TITLES].[PREVISION_PAY_DATE], [TRANSACTION_TITLES].[ORIGINAL_RECEIVE_DATE]), [TRANSACTION_TITLES].[QTY_DAYS_ANTECIP]),    
  ([TRANSACTION_TITLES].[PLOT] * 30) - 1)) /    
  100))) - (IIF([TRANSACTION_TITLES].[PLOT] = 1, [TRANSACTION_TITLES].[RATE], 0))) AS DECIMAL(22, 6)) AS NET_TO_PAY   
   ,[TRANSACTION_TITLES].[PREVISION_PAY_DATE]    
   ,'TITLE' AS [TYPE_RELEASE]    
   ,FINANCE_CALENDAR.[COD_FIN_SCH_FILE]    
   ,[FINANCE_SCHEDULE_FILE].[CREATED_AT] AS [FILE_DATE]    
   ,[FINANCE_SCHEDULE_FILE].file_name    
   ,[FINANCE_SCHEDULE_FILE].[FILE_SEQUENCE]    
   ,FINANCE_CALENDAR.[IS_LOCK]    
   ,[TRANSACTION_TITLES].[IS_SPOT]    
   ,[P].[PROTOCOL]
   ,CAST([T].[AMOUNT] / [T].[PLOTS] AS DECIMAL (22,6)) AS [GROSS_AMOUNT]  
FROM  FINANCE_CALENDAR   
JOIN [TRANSACTION_TITLES]  WITH (NOLOCK)    
 ON [TRANSACTION_TITLES].COD_FIN_CALENDAR = FINANCE_CALENDAR.COD_FIN_CALENDAR    
JOIN [TRANSACTION] AS [T] WITH (NOLOCK)    
 ON [T].[COD_TRAN] = [TRANSACTION_TITLES].[COD_TRAN]    
JOIN [PROTOCOLS] AS [P]    
 ON [P].[COD_PAY_PROT] = FINANCE_CALENDAR.[COD_PAY_PROT]    
LEFT JOIN [FINANCE_SCHEDULE_FILE]    
 ON [FINANCE_SCHEDULE_FILE].[COD_FIN_SCH_FILE] = FINANCE_CALENDAR.[COD_FIN_SCH_FILE]    
WHERE  
--FINANCE_CALENDAR.[ACTIVE]  <> 99    
--AND FINANCE_CALENDAR.[COD_SITUATION] = 8    
--AND  
[P].COD_PAY_PROT = @COD_PAY_PROT;    
  
  
  
END;  
  
  
END;    
    
--ST-1607

GO

--ST-1609

GO 

IF OBJECT_ID('SP_REPORT_RELEASE_ADJUSTMENTS') IS NOT NULL
DROP PROCEDURE [SP_REPORT_RELEASE_ADJUSTMENTS];

GO

CREATE PROCEDURE [DBO].[SP_REPORT_RELEASE_ADJUSTMENTS]                    
      
/***********************************************************************************************************  
----------------------------------------------------------------------------------------                    
Procedure Name: [SP_REPORT_RELEASE_ADJUSTMENTS]                    
Project.......: TKPP                    
------------------------------------------------------------------------------------------                    
Author                          VERSION         Date            Description                    
------------------------------------------------------------------------------------------                    
Kennedy Alef                    V1              27/07/2018      Creation                    
Gian Luca Dalle Cort            V2              04/10/2018      Changed                  
Lucas Aguiar              v3              26/11/2018      Changed                
Luiz Aquino                     v4              06/05/2019      Adicionar NSU                
Elir Ribeiro                   v5             23/08/2019       add motivo,justificativa      
Caike Uchoa                    v6            13/11/2020       add join arrang_to_pay com a protocols
------------------------------------------------------------------------------------------      
***********************************************************************************************************/                    
                 
(  
 @INITIAL_DATE         DATETIME,   
 @FINAL_DATE           DATETIME,   
 @CODCOMP              INT,   
 @CPFEC                VARCHAR(100),   
 @CODAFF               INT          = NULL,   
 @COD_EC               INT          = NULL,   
 @TRACKING_TRANSACTION VARCHAR(100) = NULL,   
 @DESCRIPTION          VARCHAR(100) = NULL,   
 @NSU                  VARCHAR(255) = NULL,   
 @NSUEXT               VARCHAR(255) = NULL)  
AS  
BEGIN  
    DECLARE @QUERY_BASIS NVARCHAR(MAX);  
  
  
SET @QUERY_BASIS = '                    
    SELECT [RELEASE_ADJUSTMENTS].[COD_REL_ADJ],       
   CAST([DBO].[FN_FUS_UTF] ( [RELEASE_ADJUSTMENTS].[PREVISION_PAY_DATE] ) AS DATETIME) AS [PREVISION_PAY_DATE],       
   [RELEASE_ADJUSTMENTS].VALUE,       
   [FINANCE_CALENDAR].[EC_NAME] AS [NAME],       
   [FINANCE_CALENDAR].[EC_CPF_CNPJ] as [CPF_CNPJ],       
   ISNULL([PROTOCOLS].[PROTOCOL], ''-'') AS [PROTOCOL],       
   [TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION],       
   [FINANCE_CALENDAR].[AFFILIATOR_NAME] as [NAME_AFFILIATOR],       
   [POSWEB_DATA_TRANSACTION].[TRACKING_TRANSACTION] AS [COD_RAST],       
   [POSWEB_DATA_TRANSACTION].[DESCRIPTION] AS [DESCRIPTION],       
   [REPORT_TRANSACTIONS].[TRANSACTION_CODE] AS [NSU],       
   [REPORT_TRANSACTIONS].[NSU_EXT] AS [EXTERNALNSU],      
   [TYPE_JUSTIFICATION].[DESCRIPTION] AS [DESCRIPTION_JUSTIFY],       
   [RELEASE_ADJUSTMENTS].[COMMENT],      
   CAST([DBO].[FN_FUS_UTF] ( [PROTOCOLS].[CREATED_AT] ) AS DATETIME) AS [TRANSACTION_DATE],       
   ISNULL([USERS].[COD_ACCESS], '' '') AS [USUARIO],       
   [RELEASE_ADJUSTMENTS].[IS_PARTIAL],       
   [ADJ_PARTIAL].VALUE AS [ORIGINAL_VALUE],  
   ADJ_PARTIAL.COD_REL_ADJ as COD_REL_ADJ_PARTIAL  
FROM [FINANCE_CALENDAR]      
 JOIN [RELEASE_ADJUSTMENTS] ON [RELEASE_ADJUSTMENTS].[COD_FIN_CALENDAR] = [FINANCE_CALENDAR].[COD_FIN_CALENDAR]      
 JOIN [TRADUCTION_SITUATION](NOLOCK) ON [TRADUCTION_SITUATION].[COD_SITUATION] = [FINANCE_CALENDAR].[COD_SITUATION]      
 LEFT JOIN [RELEASE_ADJUSTMENTS] AS [ADJ_PARTIAL] ON [ADJ_PARTIAL].[COD_REL_ADJ] = [RELEASE_ADJUSTMENTS].[COD_ORIGIN]
 JOIN DETAILS_ARRANG_TO_PAY ON DETAILS_ARRANG_TO_PAY.COD_REL_ADJ = RELEASE_ADJUSTMENTS.COD_REL_ADJ
 JOIN ARRANG_TO_PAY ON ARRANG_TO_PAY.COD_ARR_PAY = DETAILS_ARRANG_TO_PAY.COD_ARR_PAY
  AND ARRANG_TO_PAY.COD_FIN_CALENDAR = RELEASE_ADJUSTMENTS.COD_FIN_CALENDAR
  LEFT JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = ARRANG_TO_PAY.COD_PAY_PROT
 LEFT JOIN [POSWEB_DATA_TRANSACTION](NOLOCK) ON [POSWEB_DATA_TRANSACTION].[COD_POS_DATA] = [RELEASE_ADJUSTMENTS].[COD_POS_DATA]      
 LEFT JOIN [REPORT_TRANSACTIONS](NOLOCK) ON [REPORT_TRANSACTIONS].[COD_TRAN] = [POSWEB_DATA_TRANSACTION].[COD_TRAN] OR [REPORT_TRANSACTIONS].[COD_TRAN] = [RELEASE_ADJUSTMENTS].[COD_TRAN]      
 LEFT JOIN [TYPE_JUSTIFICATION] ON [TYPE_JUSTIFICATION].[COD_TYPEJUST] = [RELEASE_ADJUSTMENTS].[COD_TYPEJUST]      
 LEFT JOIN [USERS] ON [USERS].[COD_USER] = [RELEASE_ADJUSTMENTS].[COD_USER]      
WHERE [FINANCE_CALENDAR].[ACTIVE] = 1 and      
 CAST([dbo].[FN_FUS_UTF](RELEASE_ADJUSTMENTS.PREVISION_PAY_DATE) as DATETIME) BETWEEN  ''' + CAST(@INITIAL_DATE AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE AS VARCHAR) + '''                 
     AND FINANCE_CALENDAR.COD_COMP = ' + CAST(@CODCOMP AS VARCHAR);  
  
    IF @CPFEC IS NOT NULL  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.EC_CPF_CNPJ  = @CPFEC ');  
  
IF @CODAFF IS NOT NULL  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.COD_AFFILIATOR = @CodAff ');  
  
IF @COD_EC IS NOT NULL  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.COD_EC  = @COD_EC ');  
  
IF LEN(@TRACKING_TRANSACTION) > 0  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND POSWEB_DATA_TRANSACTION.TRACKING_TRANSACTION  = @TRACKING_TRANSACTION ');  
  
IF LEN(@DESCRIPTION) > 0  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND POSWEB_DATA_TRANSACTION.DESCRIPTION  LIKE  ''%' + @DESCRIPTION + '%''');  
  
IF LEN(@NSU) > 0  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND  REPORT_TRANSACTIONS.TRANSACTION_CODE = @NSU ');  
  
IF LEN(@NSUEXT) > 0  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND  REPORT_TRANSACTIONS.NSU_EXT = @NSUEXT ');  
  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '   ORDER BY CAST([dbo].[FN_FUS_UTF](RELEASE_ADJUSTMENTS.PREVISION_PAY_DATE) as DATETIME) DESC,  FINANCE_CALENDAR.COD_EC');  
  
EXEC [sp_executesql] @QUERY_BASIS  
     ,N' @CPFEC VARCHAR(14),                    
    @CodAff INT,                
    @COD_EC INT,                
    @TRACKING_TRANSACTION  VARCHAR(100),                
    @DESCRIPTION  VARCHAR(100),                
    @NSU VARCHAR(255),                
    @NSUEXT VARCHAR(255)                
    '  
     ,@CPFEC = @CPFEC  
     ,@CODAFF = @CODAFF  
     ,@COD_EC = @COD_EC  
     ,@TRACKING_TRANSACTION = @TRACKING_TRANSACTION  
     ,@DESCRIPTION = @DESCRIPTION  
     ,@NSU = @NSU  
     ,@NSUEXT = @NSUEXT;  
  
--SELECT @QUERY_BASIS              
END;  
  


  GO 

IF OBJECT_ID('SP_REPORT_TARIFF') IS NOT NULL
DROP PROCEDURE [SP_REPORT_TARIFF];

GO

CREATE PROCEDURE [dbo].[SP_REPORT_TARIFF]  
  
/***********************************************************************************************    
----------------------------------------------------------------------------------------          
Procedure Name: [SP_REPORT_TARIFF]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author                          VERSION        Date                            Description          
------------------------------------------------------------------------------------------          
Kennedy Alef                       V1        27/07/2018                       Creation          
Caike Uchôa                        V2        14/09/2020                    Add Representante  
Caike Uchoa                        v6        13/11/2020         add join arrang_to_pay com a protocols
------------------------------------------------------------------------------------------    
***********************************************************************************************/ (@INITIAL_DATE DATETIME,  
@FINAL_DATE DATETIME,  
@CODCOMP INT,  
@CPFEC VARCHAR(100),  
@CODAFF INT = NULL)  
AS  
BEGIN  
 DECLARE @QUERY_BASIS NVARCHAR(MAX);  
  
 BEGIN  
  
  SET @QUERY_BASIS = '          
SELECT [TARIFF_EC].[PLOT],     
   [TARIFF_EC].[CREATED_AT],     
   [TARIFF_EC].[PAYMENT_DAY] AS [PREVISION_PAY_DAY],     
   [TARIFF_EC].VALUE,     
   [TFF_PARTIAL].VALUE AS [ORIGINAL_VALUE],     
   [FINANCE_CALENDAR].[EC_NAME] AS [NAME],     
   [FINANCE_CALENDAR].[EC_CPF_CNPJ] AS [CPF_CNPJ],     
   ISNULL([PROTOCOLS].[PROTOCOL], ''-'') AS [PROTOCOL],     
   [TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION],     
   [PROTOCOLS].[CREATED_AT] AS [PAYMENT_DAY],     
   [FINANCE_CALENDAR].[COD_AFFILIATOR],     
   [FINANCE_CALENDAR].[AFFILIATOR_NAME] AS [NAME_AFFILIATOR],    
   [TARIFF_EC].[IS_PARTIAL],    
   TFF_PARTIAL.COD_TARIFF_EC as COD_TARIFF_EC_PARTIAL,    
   TARIFF_EC.COD_TARIFF_EC,    
   TARIFF_EC.COMMENT,    
   USER_SALES.IDENTIFICATION AS SALES_REPRESENTATIVE,  
   USER_SALES.CPF_CNPJ AS CPF_CNPJ_REPRESENTATIVE,  
   USER_SALES.EMAIL AS EMAIL_REPRESENTATIVE  
FROM [FINANCE_CALENDAR]    
 JOIN [TARIFF_EC] ON [TARIFF_EC].[COD_FIN_CALENDAR] = [FINANCE_CALENDAR].[COD_FIN_CALENDAR]      
 LEFT JOIN [TARIFF_EC] AS [TFF_PARTIAL] ON [TFF_PARTIAL].[COD_TARIFF_EC] = [TARIFF_EC].[COD_ORIGIN]   
 JOIN DETAILS_ARRANG_TO_PAY ON DETAILS_ARRANG_TO_PAY.COD_TARIFF_EC = TARIFF_EC.COD_TARIFF_EC
 JOIN ARRANG_TO_PAY ON ARRANG_TO_PAY.COD_ARR_PAY = DETAILS_ARRANG_TO_PAY.COD_ARR_PAY
  AND ARRANG_TO_PAY.COD_FIN_CALENDAR = TARIFF_EC.COD_FIN_CALENDAR
  LEFT JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = ARRANG_TO_PAY.COD_PAY_PROT
 JOIN [TRADUCTION_SITUATION] ON [TRADUCTION_SITUATION].[COD_SITUATION] = [FINANCE_CALENDAR].[COD_SITUATION]    
 LEFT JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = TARIFF_EC.COD_EC  
 LEFT JOIN SALES_REPRESENTATIVE SP ON SP.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP  
 LEFT JOIN USERS USER_SALES ON USER_SALES.COD_USER = SP.COD_USER  
WHERE [FINANCE_CALENDAR].[ACTIVE] = 1       
AND TARIFF_EC.PAYMENT_DAY BETWEEN  ''' + CAST(@INITIAL_DATE AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE AS VARCHAR) + '''          
 AND FINANCE_CALENDAR.COD_COMP = ''' + CAST(@CODCOMP AS VARCHAR) + ''' ';  
  
  
  IF @CPFEC IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.EC_CPF_CNPJ  = @CPFEC ');  
  
  IF @CODAFF IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.COD_AFFILIATOR  = @CodAff ');  
  
  SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY TARIFF_EC.PAYMENT_DAY DESC, FINANCE_CALENDAR.cod_ec');  
  
  
  --EXECUTE (@QUERY_BASIS);          
  EXEC [sp_executesql] @QUERY_BASIS  
       ,N'          
@CPFEC varchar(14),          
@CodAff INT          
'  
       ,@CPFEC = @CPFEC  
       ,@CODAFF = @CODAFF;  
  
 END;  
END;  

GO

--ST-1609

GO

--ST-1546

IF OBJECT_ID('SP_UPDATE_AFFILIATED') IS NOT NULL DROP PROCEDURE SP_UPDATE_AFFILIATED;
GO
create PROCEDURE [DBO].[SP_UPDATE_AFFILIATED]                                   
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
Lucas Aguiar                   v5           2019-08-23        Add serviço de notificações                      
Luiz Aquino                    V6           2019-10-24        Add Serviço de retenção de agenda             
Caike Uchôa                    v7           2020-02-26           drop services       
Caike uchoa                    v9           21/10/2020           add email     
Caike Uchoa                    v10          10/11/2020           Add Program Manager  
Elir Ribeiro                   v11          13/11/2020           add null in @PROGRAM_MANAGER
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
 @EMAIL                  VARCHAR(100),  
 @PROGRAM_MANAGER VARCHAR(100)   = NULL
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
   ,[ACTIVE] = ISNULL(@ACTIVE, [ACTIVE])  
   ,[PLATFORM_NAME] = @PLATFORMNAME  
   ,[COMPANY_NAME] = @COMPANY_NAME  
   ,[STATE_REGISTRATION] = @STATE_REGISTRATION  
   ,[MUNICIPAL_REGISTRATION] = @MUNICIPAL_REGISTRATION  
   ,[PROPOSED_NUMBER] = @PROPOSED_NUMBER  
   ,[PROGRAM_MANAGER] = @PROGRAM_MANAGER  
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
 VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @CELL_NUMBER, @COD_TP_CONT, @COD_OPER, current_timestamp, @COD_USER_ALT, @DDI, @DDD, 1, @EMAIL);  
  
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
 VALUES (@CODAFFILIATED, current_timestamp, @COD_USER_CAD, @PHONE_NUMBER, @PHONE_COD_TP_CONT, @PHONE_COD_OPER, current_timestamp, @COD_USER_ALT, @PHONE_DDI, @PHONE_DDD, 1, @EMAIL);  
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
  
go

IF OBJECT_ID('SP_REG_AFFILIATOR') IS NOT NULL DROP PROCEDURE SP_REG_AFFILIATOR;
GO
create PROCEDURE [dbo].[SP_REG_AFFILIATOR]                                                                                                  
 /*----------------------------------------------------------------------------------------                                                          
 Procedure Name: SP_REG_AFFILIATOR                                                          
 Project.......: TKPP                                                          
 ------------------------------------------------------------------------------------------                                                          
 Author                          VERSION        Date              Description                                                          
 ------------------------------------------------------------------------------------------                                                          
 Gian Luca Dalle Cort              V1          31/07/2018          CREATION                                                          
 Gian Luca Dalle Cort              V2          31/07/2018          CHANGE                                                          
 Kennedy Alef de Oliveira          V3          25/08/2018          CHANGE                                                     
 Elir  Ribeiro                     V4          31/08/2018          CHANGE                                      
 Luiz Aquino                       v5          13/12/2018     INCLUDE HAS_SPOT AND SPOT_TAX                                      
 Lucas Aguiar                      v6          14/12/2018     Add  TRANSACTION_DIGITED                                      
 Elir Ribeiro                      v7          21/03/2019     changed COD_COMP,CODUSER                                  
 Lucas Aguiar                      v8          2019-04-17     Add Split service                                   
 Lucas Aguiar                      v9          2019-08-28     Add serviço do notification                                  
 Elir Ribeiro                      v10         20200-01-21    add contracts affiliator                                 
 Elir Ribeiro                      v11         2020-01-22     add propposed number                             
 Elir Ribeiro                      v12         2020-01-23     add documents                      
 Elir Ribeiro                      v13         2020-01-29     add description in documents                    
 Caike Uchôa                       v14         20/02/2019     Add service Afiliator operation         
 Caike Uchoa                       V15         21/10/2020     Add cod_user_modify, created_at e modify_date  
 Caike Uchoa                       v17         10/11/2020     Add Program Manager  
 Elir Ribeiro                      v18         13/11/2020     add null in @PROGRAM_MANAGER
 ------------------------------------------------------------------------------------------*/                                      
(                                                      
-- INFO BASE                                                    
  @COD_COMP INT,                                                          
  @NAME VARCHAR(100),                                                                  
  @CPF_CNPJ VARCHAR(14),                                                           
  @COD_USER_CAD INT,                                                          
  @FIREBASE_NAME VARCHAR(100) = NULL,                                                          
  @COD_USER_ALT INT,                                                 
 -- ADDRESS                                                
  @ADDRESS VARCHAR(250),                                                          
  @NUMBER VARCHAR(50),                                                          
  @COMPLEMENT VARCHAR(400) = NULL,                                                          
  @CEP VARCHAR(80),                                                          
  @COD_NEIGH INT,                                                          
  @REFERENCE_POINT VARCHAR(200) = NULL,                           
 ----- CONTACT                          
 @CELL_NUMBER VARCHAR(30),                                                           
 @COD_TP_CONT INT,                     
 @COD_OPER INT,                                                          
 @DDI VARCHAR(20),                                                          
 @DDD VARCHAR(20),                                          
 -- SUBDOMAIN            
 @SUBDOMAIN varchar(100),                                                      
 -- PLAN                                          
 @COD_PLAN [CODE_TYPE] READONLY,                                                  
 -- THEME                                                
  @LOGO_AFFILIATE VARCHAR(400),                                                    
  @LOGO_HEADER_AFFILIATE VARCHAR(400),                                                      
  @COLOR_HEADER VARCHAR(400) = NULL,                                                    
  @BACKGROUND_IMAGE VARCHAR(400) = NULL,                                                    
  @SECONDARY_COLOR VARCHAR(400) = NULL ,                                                
  @CSS_FILE VARCHAR(100) = NULL,                 
  @PROGRESSIVE_COST INT,                                                
 -- BANK DETAILS                                                    
 @AGENCY VARCHAR(100) = NULL,                                                  
 @DIGIT VARCHAR(100) = NULL,                               
 @ACCOUNT VARCHAR(100)= NULL,                                                 
 @DIGIT_ACCOUNT VARCHAR(100)= NULL,                                                 
 @BANK INT = NULL,                        
 @ACCOUNT_TYPE INT = NULL,                                      
--SPOT                                      
 @HAS_SPOT INT = 0,                                      
 @SPOT_TAX DECIMAL(6,2)= 0,                                  
--SPLIT                                  
 @HAS_SPLIT INT = 0,                                    
 @SPLIT INT = 0,                                  
 --Notification Afiliador                                  
 @HAS_NOTIFICATION INT = 0,                                  
 @PASSWORD_NOTIFICATION VARCHAR(255) = NULL,                                  
 @CLIENTID_NOTIFICATION VARCHAR(255) = NULL,                                
 @PLATFORM_NAME VARCHAR(100) = NULL,                                
 @COMPANY_NAME VARCHAR(100) = NULL,                                
 @STATE_REGISTRATION VARCHAR(100) = NULL,                                
 @MUNICIPAL_REGISTRATION VARCHAR(100) = NULL ,                                
 @TYPECONTRACTS INT = NULL,                                
 @CONTROLNUMBER VARCHAR (100) = NULL,                                
 @DESCRIPTION VARCHAR(100) = NULL ,                            
 @PROPOSED_NUMBER varchar(100) = NULL,                                
 @NAME_CONTACT VARCHAR(100) = NULL,                          
 @MAIL_CONTACT VARCHAR(100) = NULL,                        
 @DOCUMENTS VARCHAR(100) = NULL,                     
 @DESCRIPTION_DOCUMENT VARCHAR(200) = NULL,                       
 @CONTRACTS VARCHAR(100) = NULL,                      
 @TYPEDOCS int = NULL,            
 @OPERATION_AFF INT,            
 -- Translate Service                
 @HAS_TRANSLATION INT = 0,  
 @PROGRAM_MANAGER VARCHAR(100)   = null
)                                                          
AS                                      
                                                          
DECLARE @SEQ INT;  
      
        
              
                
                                   
DECLARE @IDAFL INT;  
      
        
              
                
                                  
DECLARE @CONT INT;  
      
        
              
                
                                   
DECLARE @PROG INT;  
      
        
              
                
                                   
DECLARE @COD_SPLIT INT;  
      
        
              
                
                                  
DECLARE @cod_plan_int int;  
     
        
              
                
                                  
DECLARE @COD_GWNOTIFICATION INT;  
      
        
              
               
                  
DECLARE @COD_TRANSLATE INT;  
      
        
              
                             
                                    
                                  
BEGIN  
  
  
(SELECT  
 @cod_plan_int = CODE  
FROM @COD_PLAN);  
SELECT  
 @CONT = COUNT(*)  
FROM AFFILIATOR  
WHERE CPF_CNPJ = @CPF_CNPJ  
  
IF @CONT > 0  
THROW 61002, 'AFILIADOR Já CADASTRADO', 1;  
  
SET @SEQ = NEXT VALUE FOR [SEQ_AFLCODE];  
  
SELECT  
 @COD_GWNOTIFICATION = COD_ITEM_SERVICE  
FROM ITEMS_SERVICES_AVAILABLE  
WHERE [NAME] = 'GWNOTIFICATIONAFFILIATOR';  
  
SELECT  
 @COD_TRANSLATE = COD_ITEM_SERVICE  
FROM ITEMS_SERVICES_AVAILABLE  
WHERE [NAME] = 'TRANSLATE';  
/********************** REGISTER AFFILIATOR ****************/  
  
INSERT INTO AFFILIATOR (COD_COMP,  
NAME,  
CREATED_AT,  
ACTIVE,  
CODE,  
CPF_CNPJ,  
COD_USER_CAD,  
FIREBASE_NAME,  
MODIFY_DATE,  
COD_USER_ALT,  
SUBDOMAIN,  
COD_OPER_COST,  
--HAS_SPOT,                                      
SPOT_TAX,  
COD_SITUATION,  
PLATFORM_NAME,  
COMPANY_NAME,  
STATE_REGISTRATION,  
MUNICIPAL_REGISTRATION,  
PROPOSED_NUMBER,  
OPERATION_AFF,  
PROGRAM_MANAGER)  
 VALUES (@COD_COMP, @NAME, current_timestamp, 1, @SEQ, @CPF_CNPJ, @COD_USER_CAD, @FIREBASE_NAME, current_timestamp, @COD_USER_ALT, @SUBDOMAIN, (SELECT TOP 1 COD_OPER_COST FROM OPERATION_COST WHERE COD_COMP = @COD_COMP AND ACTIVE = 1), @SPOT_TAX, (SELECT 
COD_SITUATION FROM SITUATION WHERE [NAME] = 'RELEASED'), @PLATFORM_NAME, @COMPANY_NAME, @STATE_REGISTRATION, @MUNICIPAL_REGISTRATION, @PROPOSED_NUMBER, @OPERATION_AFF, @PROGRAM_MANAGER);  
  
IF @@rowcount < 1  
THROW 60000, 'COULD NOT REGISTER AFFILIATOR', 1;  
  
SET @IDAFL = @@identity;  
      
        
              
                
                                  
                                      
                                      
 IF @HAS_SPOT = 1                                      
 BEGIN  
      
        
              
                
                                  
                       
                                      
 DECLARE @CodSpotService INT  
SELECT  
 @CodSpotService = COD_ITEM_SERVICE  
FROM ITEMS_SERVICES_AVAILABLE  
WHERE CODE = '1'  
  
INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)  
 VALUES (current_timestamp, @COD_USER_CAD, @CodSpotService, @COD_COMP, @IDAFL, NULL, 1, current_timestamp)  
  
END  
  
IF @HAS_SPLIT = 1  
BEGIN  
SELECT  
 @COD_SPLIT = COD_ITEM_SERVICE  
FROM ITEMS_SERVICES_AVAILABLE  
WHERE [NAME] = 'SPLIT';  
  
INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE, COD_OPT_SERV)  
 VALUES (current_timestamp, @COD_USER_CAD, @COD_SPLIT, @COD_COMP, @IDAFL, NULL, 1, current_timestamp, (SELECT COD_OPT_SERV FROM OPTIONS_SERVICES WHERE CODE = @SPLIT))  
END;  
  
/************ UPDATE TRANSLATE SERVICE **********/  
IF @HAS_TRANSLATION = 1  
BEGIN  
INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)  
 VALUES (current_timestamp, @COD_USER_ALT, @COD_TRANSLATE, @COD_COMP, @IDAFL, NULL, 1, current_timestamp)  
END;  
/************ UPDATE NOTIFICATION AFFILIATED **********/  
  
IF @HAS_NOTIFICATION = 0  
BEGIN  
  
UPDATE SERVICES_AVAILABLE  
SET ACTIVE = 0  
   ,COD_USER = @COD_USER_ALT  
   ,MODIFY_DATE = current_timestamp  
WHERE COD_ITEM_SERVICE = @COD_GWNOTIFICATION  
AND COD_COMP = @COD_COMP  
AND COD_AFFILIATOR = @IDAFL  
AND COD_EC IS NULL;  
  
UPDATE ACCESS_APPAPI  
SET ACTIVE = 0  
   ,COD_USER_MODIFY = @COD_USER_ALT  
   ,MODIFY_DATE = CURRENT_TIMESTAMP  
WHERE COD_AFFILIATOR = @IDAFL  
AND ACTIVE = 1  
END  
ELSE  
IF @HAS_NOTIFICATION = 1  
BEGIN  
  
UPDATE SERVICES_AVAILABLE  
SET ACTIVE = 0  
   ,COD_USER = @COD_USER_ALT  
   ,MODIFY_DATE = current_timestamp  
WHERE COD_ITEM_SERVICE = @COD_GWNOTIFICATION  
AND COD_COMP = @COD_COMP  
AND COD_AFFILIATOR = @IDAFL  
AND COD_EC IS NULL;  
  
INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)  
 VALUES (current_timestamp, @COD_USER_ALT, @COD_GWNOTIFICATION, @COD_COMP, @IDAFL, NULL, 1, current_timestamp)  
  
EXEC [SP_REG_ACCESS_NOTIFICATION_AFF] @IDAFL  
          ,@PASSWORD_NOTIFICATION  
          ,@CLIENTID_NOTIFICATION  
          ,@COD_USER_ALT;  
  
END  
  
  
  
/************ REGISTER PROGRESSIVEE COST AFFILIATOR **********/  
  
INSERT INTO PROGRESSIVE_COST_AFFILIATOR (COD_AFFILIATOR,  
COD_PROG_COST,  
COD_TYPE_PROG,  
COD_USER)  
 SELECT  
  @IDAFL  
    ,COD_PROG_COST  
    ,COD_TYPE_PROG  
    ,@COD_USER_CAD  
 FROM PROGRESSIVE_COST  
 WHERE COD_COMP = @COD_COMP  
 AND ACTIVE = 1  
 AND COD_TYPE_PROG = @PROGRESSIVE_COST  
  
SET @PROG = @@identity;  
  
INSERT INTO ITENS_PROG_COST_AFF (COD_PROG_COST_AF,  
QTY_INITIAL,  
QTY_FINAL,  
FIX_COST,  
ADITIONAL_COST)  
 SELECT  
  @PROG  
    ,ITENS_PROG_COST.QTY_INITIAL  
    ,ITENS_PROG_COST.QTY_FINAL  
    ,ITENS_PROG_COST.FIX_COST  
    ,ITENS_PROG_COST.ADITIONAL_COST  
 FROM ITENS_PROG_COST  
 INNER JOIN PROGRESSIVE_COST  
  ON PROGRESSIVE_COST.COD_PROG_COST = ITENS_PROG_COST.COD_PROG_COST  
 WHERE COD_COMP = @COD_COMP  
 AND PROGRESSIVE_COST.ACTIVE = 1  
 AND ITENS_PROG_COST.ACTIVE = 1  
 AND COD_TYPE_PROG = @PROGRESSIVE_COST  
  
  
/* ******************* ADDRESS AFFILIATOR *****************************/  
  
  
UPDATE ADDRESS_AFFILIATOR  
SET ACTIVE = 0  
   ,MODIFY_DATE = GETDATE()  
WHERE ACTIVE = 1  
AND COD_AFFILIATOR = @IDAFL;  
  
INSERT INTO ADDRESS_AFFILIATOR (COD_AFFILIATOR,  
CREATED_AT,  
COD_USER_CAD,  
ADDRESS,  
number,  
COMPLEMENT,  
CEP,  
COD_NEIGH,  
ACTIVE,  
MODIFY_DATE,  
COD_USER_ALT,  
REFERENCE_POINT)  
 VALUES (@IDAFL, current_timestamp, @COD_USER_CAD, @ADDRESS, @NUMBER, @COMPLEMENT, @CEP, @COD_NEIGH, 1, current_timestamp, @COD_USER_ALT, @REFERENCE_POINT);  
  
IF @@rowcount < 1  
THROW 60000, 'COULD NOT REGISTER ADDRESS_AFFILIATOR ', 1;  
  
/************************* AFFILIATOR CONTACT ***************************/  
  
INSERT INTO AFFILIATOR_CONTACT (COD_AFFILIATOR,  
CREATED_AT,  
COD_USER_CAD,  
number,  
COD_TP_CONT,  
COD_OPER,  
MODIFY_DATE,  
COD_USER_ALT,  
DDI,  
DDD,  
ACTIVE,  
NAME,  
MAIL)  
 VALUES (@IDAFL, current_timestamp, @COD_USER_CAD, @CELL_NUMBER, @COD_TP_CONT, @COD_OPER, current_timestamp, @COD_USER_ALT, @DDI, @DDD, 1, @NAME_CONTACT, @MAIL_CONTACT);  
  
IF @@rowcount < 1  
THROW 60000, 'COULD NOT REGISTER AFFILIATOR_CONTACT ', 1;  
  
/**********  UPDATE AND REGISTER THEMES ****************/  
  
UPDATE THEMES  
SET ACTIVE = 0  
   ,MODIFY_DATE = current_timestamp  
   ,COD_USER_ALT = @COD_USER_CAD  
WHERE COD_AFFILIATOR = @IDAFL  
AND ACTIVE = 1;  
  
  
INSERT INTO THEMES (CREATED_AT,  
LOGO_AFFILIATE,  
LOGO_HEADER_AFFILIATE,  
COD_AFFILIATOR,  
COLOR_HEADER,  
ACTIVE,  
COD_USER_CAD,  
BACKGROUND_IMAGE,  
SECONDARY_COLOR)  
 VALUES (current_timestamp, @LOGO_AFFILIATE, @LOGO_HEADER_AFFILIATE, @IDAFL, @COLOR_HEADER, 1, @COD_USER_CAD, @BACKGROUND_IMAGE, @SECONDARY_COLOR);  
  
IF @@rowcount < 1  
THROW 60000, 'COULD NOT REGISTER THEMES ', 1;  
  
  
/********************** BANK DETAILS **********************/  
  
INSERT INTO BANK_DETAILS_EC (AGENCY,  
DIGIT_AGENCY,  
COD_TYPE_ACCOUNT,  
COD_BANK,  
ACCOUNT,  
DIGIT_ACCOUNT,  
COD_USER,  
COD_OPER_BANK,  
COD_AFFILIATOR)  
 VALUES (@AGENCY, @DIGIT, @ACCOUNT_TYPE, @BANK, @ACCOUNT, @DIGIT_ACCOUNT, @COD_USER_CAD, @COD_OPER, @IDAFL)  
  
INSERT INTO CONTRACTS_AFFILIATOR (TYPECONTRACTS, CONTROLNUMBER, DESCRIPTION, COD_USER_CREATE, CREATED_AT, ACTIVE, CONTRACTS, COD_AFFILIATOR)  
 VALUES (@TYPECONTRACTS, @CONTROLNUMBER, @DESCRIPTION, @COD_USER_CAD, current_timestamp, 1, @CONTRACTS, @IDAFL)  
  
INSERT INTO DOCS_AFFILIATOR (DOCUMENTS, COD_USER_CREATE, CREATED_AT, ACTIVE, COD_AFFILIATOR, COD_TYPE_CONTRACTS, DESCRIPTION)  
 VALUES (@DOCUMENTS, @COD_USER_CAD, current_timestamp, 1, @IDAFL, @TYPEDOCS, @DESCRIPTION_DOCUMENT)  
  
  
/******** REGISTER TAX PLAN OF AFFILIATOR **********/  
  
EXEC SP_ASS_AFF_PLAN @CODPLAN = @COD_PLAN  
     ,@COD_AFF = @IDAFL  
     ,@CODUSER = @COD_USER_CAD;  
  
  
/******** REGISTER TAX PLAN OF AFFILIATOR **********/  
  
EXEC SP_REG_OPER_COST_AFF @COD_AFFILIATOR = @IDAFL  
       ,@COD_COMP = @COD_COMP;  
  
/****** REGISTER PRODUCTS UNAVAILABLE TO MODELS *****/  
  
EXEC SP_REG_UNAVAILABLE_PRODUCT @COD_AFF = @IDAFL  
  
  
SELECT  
 @IDAFL AS 'COD_AFFILIATOR'  
   ,@COD_COMP AS 'COD_COMP'  
   ,@COD_USER_CAD AS 'CODUSER';  
  
  
END;  
  

--ST-1546

GO

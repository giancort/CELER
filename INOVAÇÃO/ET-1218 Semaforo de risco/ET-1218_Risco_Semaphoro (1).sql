IF ( SELECT
		COUNT(*)
	FROM RISK_SITUATION
	WHERE NAME = 'automatically approved')
= 0
BEGIN
INSERT INTO RISK_SITUATION (NAME, VIEWER, TRANSACTION_VIEWER, SITUATION_EC)
	VALUES ('automatically approved', 1, 1, 1)
END
GO
IF ( SELECT
		COUNT(*)
	FROM RISK_SITUATION
	WHERE NAME = 'automatically denied')
= 0
BEGIN
INSERT INTO RISK_SITUATION (NAME, VIEWER, TRANSACTION_VIEWER, SITUATION_EC)
	VALUES ('automatically denied', 1, 1, 1)
END
GO

IF ( SELECT
		COUNT(*)
	FROM TRADUCTION_RISK_SITUATION
	WHERE RISK_SITUATION_TR = 'Aprovado Automaticamente')
= 0
BEGIN
INSERT INTO TRADUCTION_RISK_SITUATION (COD_RISK_SITUATION, LANGUAGE, RISK_SITUATION_TR)
	VALUES ((SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE NAME = 'automatically approved'), 'PORTUGUES', 'Aprovado Automaticamente')
END
GO

IF ( SELECT
		COUNT(*)
	FROM TRADUCTION_RISK_SITUATION
	WHERE RISK_SITUATION_TR = 'Negado Automaticamente')
= 0
BEGIN
INSERT INTO TRADUCTION_RISK_SITUATION (COD_RISK_SITUATION, LANGUAGE, RISK_SITUATION_TR)
	VALUES ((SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE NAME = 'automatically denied'), 'PORTUGUES', 'Negado Automaticamente')
END
GO


IF OBJECT_ID('RISK_MCC_SEMAPHORE') IS NULL BEGIN
    CREATE TABLE RISK_MCC_SEMAPHORE
    (
        COD_MCC_RISK INT NOT NULL IDENTITY PRIMARY KEY,
        COD_SEG INT REFERENCES SEGMENTS (COD_SEG),
        COD_TYPE_EC INT NOT NULL REFERENCES TYPE_ESTAB(COD_TYPE_ESTAB),
        RISK VARCHAR(8) NOT NULL DEFAULT('B'),
        LIMIT DECIMAL(22, 6) NOT NULL,
        LIMIT_DAY DECIMAL(22, 6) NOT NULL,
        CREATED_AT DATETIME NOT NULL DEFAULT(GETDATE()),
        COD_USER INT REFERENCES USERS (COD_USER)
    )
END

GO
IF OBJECT_ID('SP_CHECK_RISK_SEMAPHORE') IS NOT NULL
DROP PROCEDURE SP_CHECK_RISK_SEMAPHORE
GO
CREATE PROCEDURE SP_CHECK_RISK_SEMAPHORE      
/*----------------------------------------------------------------------------------------             
  Project.......: TKPP             
------------------------------------------------------------------------------------------             
  Author              VERSION        Date         Description             
------------------------------------------------------------------------------------------             
  Luiz Aquino          1            2021-02-19      Created      
------------------------------------------------------------------------------------------*/      
(      
    @SITUATION_RISK VARCHAR(128),      
    @COD_RESEARCH_RISK INT      
) AS BEGIN
  
    
      
          
    DECLARE @COD_EC INT,       
        @COD_SEG INT,       
        @LIMIT DECIMAL(22, 6),       
        @LIMIT_DAY DECIMAL(22, 6),       
        @FOUND BIT = 0,       
        @CODE_BANK VARCHAR(32),      
        @SOURCE_NAME VARCHAR(12),      
        @CODE VARCHAR(12),    
  @COD_TYPE_ESTAB INT,  
  @CPF_EC varchar(200),  
  @CPF_ASSIGN VARCHAR(200) = NULL;

SELECT
	@COD_EC = COD_EC
   ,@SOURCE_NAME = SOURCE_NAME
   ,@CODE = RRT.CODE
FROM RESEARCH_RISK(NOLOCK) RR
JOIN RESEARCH_RISK_TYPE(NOLOCK) RRT
	ON RRT.COD_RESEARCH_RISK_TYPE = RR.COD_RESEARCH_RISK_TYPE
WHERE RR.COD_EC = @COD_RESEARCH_RISK;

IF @SOURCE_NAME = 'B2e'
	AND @CODE = 'INITIAL'
BEGIN

SELECT
	@COD_SEG = CE.COD_SEG
   ,@COD_TYPE_ESTAB = CE.COD_TYPE_ESTAB
   ,@CPF_EC = CE.CPF_CNPJ
FROM COMMERCIAL_ESTABLISHMENT CE
WHERE CE.COD_EC = @COD_EC

SET @CPF_EC = (SELECT TOP 1
		RESEARCH_RISK_RESPONSE_DETAILS.CPF_PARTNER_EC
	FROM RESEARCH_RISK
	JOIN RESEARCH_RISK_RESPONSE
		ON RESEARCH_RISK.COD_RESEARCH_RISK = RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK
	JOIN RESEARCH_RISK_RESPONSE_DETAILS
		ON RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE =
		RESEARCH_RISK_RESPONSE_DETAILS.COD_RESEARCH_RISK_RESPONSE
	WHERE COD_RESEARCH_RISK_TYPE = 4
	AND CPF_PARTNER_EC IS NOT NULL
	AND COD_EC = 28039
	ORDER BY RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE DESC)

SELECT TOP 1
	@LIMIT = LIMIT
   ,@LIMIT_DAY = LIMIT_DAY
   ,@FOUND = 1
FROM RISK_MCC_SEMAPHORE RMS
WHERE RMS.COD_SEG = @COD_SEG
AND RMS.COD_TYPE_EC = @COD_TYPE_ESTAB
ORDER BY RISK

DECLARE @NEW_RISK_SIT INT
	   ,@NEW_EC_SITUATION INT
	   ,@RISK_REASON VARCHAR(64) = NULL;

IF CHARINDEX('APROVADO', @SITUATION_RISK) > 0
BEGIN

SELECT TOP 1
	@CODE_BANK = B.CODE
   ,@CPF_ASSIGN = BDE.ASSIGNMENT_IDENTIFICATION
FROM BANK_DETAILS_EC BDE
JOIN BANKS B
	ON B.COD_BANK = BDE.COD_BANK
WHERE BDE.COD_EC = 28039
AND BDE.ACTIVE = 1
AND BDE.IS_CERC = 0
ORDER BY BDE.COD_BK_EC DESC

IF @CODE_BANK != '341'
BEGIN

IF ((@COD_TYPE_ESTAB = 1)
	AND (@CPF_EC <> @CPF_ASSIGN)
	AND (@CPF_ASSIGN IS NOT NULL)) --MEI   
BEGIN

SELECT
	@NEW_RISK_SIT = COD_RISK_SITUATION
FROM RISK_SITUATION
WHERE NAME = 'Pending risk Analysis';

SELECT
	@NEW_EC_SITUATION = COD_SITUATION
FROM SITUATION
WHERE NAME = 'LOCKED FINANCIAL SCHEDULE'

END
ELSE
BEGIN
SELECT
	@NEW_RISK_SIT = COD_RISK_SITUATION
FROM RISK_SITUATION
WHERE NAME = 'automatically approved';

SELECT
	@NEW_EC_SITUATION = COD_SITUATION
FROM SITUATION
WHERE NAME = 'RELEASED'
END
END
ELSE
BEGIN
SELECT
	@NEW_RISK_SIT = COD_RISK_SITUATION
FROM RISK_SITUATION
WHERE NAME = 'Pending risk Analysis';

SELECT
	@NEW_EC_SITUATION = COD_SITUATION
FROM SITUATION
WHERE NAME = 'LOCKED FINANCIAL SCHEDULE'
END

END
ELSE
IF CHARINDEX('AGUARDANDO', @SITUATION_RISK) > 0
BEGIN
SELECT
	@NEW_RISK_SIT = COD_RISK_SITUATION
FROM RISK_SITUATION
WHERE NAME = 'Pending risk Analysis';

SELECT
	@NEW_EC_SITUATION = COD_SITUATION
FROM SITUATION
WHERE NAME = 'LOCKED FINANCIAL SCHEDULE'
END
ELSE --CANCELADO OU REPROVADO       
BEGIN
SELECT
	@NEW_RISK_SIT = COD_RISK_SITUATION
FROM RISK_SITUATION
WHERE NAME = 'automatically denied';

SELECT
	@NEW_EC_SITUATION = COD_SITUATION
FROM SITUATION
WHERE NAME = 'LOCKED FINANCIAL SCHEDULE'

SET @RISK_REASON = 'CANCELADO AUTOMATICAMENTE B2e'
  
    
      
        END

UPDATE COMMERCIAL_ESTABLISHMENT
SET LIMIT_TRANSACTION_DIALY = @LIMIT_DAY
   ,TRANSACTION_LIMIT = @LIMIT
   ,COD_RISK_SITUATION = @NEW_RISK_SIT
   ,COD_SITUATION = @NEW_EC_SITUATION
   ,RISK_REASON = @COD_RESEARCH_RISK
WHERE COD_EC = @COD_EC

END

END
GO

IF OBJECT_ID('SP_REG_RESEARCH_RISK_RESPONSE_B2E') IS NOT NULL
DROP PROCEDURE SP_REG_RESEARCH_RISK_RESPONSE_B2E
GO
CREATE PROCEDURE [dbo].[SP_REG_RESEARCH_RISK_RESPONSE_B2E]    
/*----------------------------------------------------------------------------------------            
 Procedure Name: [SP_REG_RESEARCH_RISK_RESPONSE]     Project.......: TKPP            
------------------------------------------------------------------------------------------            
 Author              Version            Date         Description            
------------------------------------------------------------------------------------------            
 Marcus Gall            V1           05/03/2020        Creation            
 Caike Uchôa            V2           27/05/2020   Add validate by cod_status           
 Caike Uchôa            V3           16/06/2020      ajuste Insert Details        
 Caike Uchôa            V4           30/06/2020          add status 2,3      
 Marcus Gall   V5    10/12/2020  Monthly Service change OFAC api    
 Luiz Aquino            V6           22/02/2021     ET-1218 Aprovacao atutomatica risco    
------------------------------------------------------------------------------------------*/    
(@COD_RESEARCH_RISK INT    
, @BID_ID VARCHAR(100) = NULL    
, @SITUATION_RISK VARCHAR(50) = NULL    
, @MESSAGE VARCHAR(500) = NULL    
, @CODE_POLICY VARCHAR(100) = NULL    
, @CNAE VARCHAR(10) = NULL    
, @STATE_REGISTRATION VARCHAR(20) = NULL    
, @CPF_CNPJ VARCHAR(20) = NULL    
, @NAME VARCHAR(200) = NULL    
, @TEST_LINES INT = 0    
, @PATH_FILE_RESPONSE VARCHAR(500) = NULL    
, @PATH_FILE_RESPONSE_CONSOLIDATED VARCHAR(500) = NULL    
, @LINES_RESEARCH_RISK_DETAILS TP_RESEARCH_RISK_RESPONSE_DETAILS READONLY)    
AS    
DECLARE @COD_RESEARCH_RISK_RESPONSE INT;
  
DECLARE @COD_RESEARCH_RISK_PK INT;
    
DECLARE @COD_EC INT;
  
    
DECLARE @DOCUMENT_TYPE VARCHAR(5);
  
    
DECLARE @COD_RESEARCH_RISK_TYPE INT;
  
    
DECLARE @COD_STATUS INT;
  
    
    
BEGIN
  
    
    
    -- BEGIN > REGISTRANDO O RESULTADO DA PESQUISA RECEBIDA            
    IF ( SELECT
		COUNT(RESEARCH_RISK.COD_RESEARCH_RISK)
	FROM RESEARCH_RISK
	WHERE RESEARCH_RISK.COD_EC = @COD_RESEARCH_RISK)
= 0
THROW 60001, 'BAD REQUEST, NOT FOUND RESEARCH_RISK REGISTER WITH PARAMETER >> @COD_RESEARCH_RISK', 1;

SELECT
	@COD_RESEARCH_RISK_PK = COD_RESEARCH_RISK
FROM RESEARCH_RISK
WHERE RESEARCH_RISK.COD_EC = @COD_RESEARCH_RISK

SELECT
	@COD_STATUS = COD_STATUS
FROM RESEARCH_RISK
WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK
-- COD_STATUS = 0 (EC NÃO ENVIADO PARA A B2e - NÃO ENVIADO)      
-- COD_STATUS = 1 (EC ENVIADO PARA A B2e - ENVIADO)      
-- COD_STATUS = 3 ( FALHA AO ENVIAR)      

-- VERIFICANDO SE O RETORNO É DO SERVICO DA OFAC (ENVIADO e RECEBIDO PELA OFAC SINCRONO)    
IF EXISTS (SELECT
			1
		FROM RESEARCH_RISK
		INNER JOIN RESEARCH_RISK_TYPE
			ON RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE = RESEARCH_RISK.COD_RESEARCH_RISK_TYPE
		WHERE RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK
		AND RESEARCH_RISK.COD_STATUS IN (0, 1)
		AND RESEARCH_RISK_TYPE.SOURCE_NAME = 'OFAC')
BEGIN
UPDATE RESEARCH_RISK
SET MODIFY_AT = current_timestamp
   ,SEND_AT = current_timestamp
   ,COD_STATUS = 2
WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;
SET @COD_STATUS = 1;
  
    
   END
  
    
    
  IF (@TEST_LINES = 1)    
   BEGIN
SELECT
	NULL
   ,LINES.[CODE]
   ,LINES.[COD_SITUATION]
   ,LINES.[SITUATION_DESCRIPTION]
   ,EC_PARTNERS.COD_ADT_DATA
   ,LINES.[CPF_PARTNER_EC]
FROM @LINES_RESEARCH_RISK_DETAILS AS LINES
INNER JOIN RESEARCH_RISK
	ON RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK
LEFT JOIN ADITIONAL_DATA_TYPE_EC AS EC_PARTNERS
	ON EC_PARTNERS.COD_EC = RESEARCH_RISK.COD_EC
		AND LINES.[CPF_PARTNER_EC] = EC_PARTNERS.CPF;

SELECT
	LINES.*
FROM @LINES_RESEARCH_RISK_DETAILS AS LINES;
END

ELSE
IF (@COD_STATUS = 1)
BEGIN
UPDATE RESEARCH_RISK
SET MODIFY_AT = current_timestamp
   ,COD_STATUS = 2
WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;
IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK', 1;

UPDATE RESEARCH_RISK_RESPONSE
SET ACTIVE = 0
WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;

INSERT INTO RESEARCH_RISK_RESPONSE (COD_RESEARCH_RISK, BID_ID, SITUATION_RISK, MESSAGE_SITUATION,
CODE_POLICY, CNAE, STATE_REGISTRATION, CPF_CNPJ, NAME_EC,
PATH_FILE_RESPONSE)
	VALUES (@COD_RESEARCH_RISK_PK, @BID_ID, @SITUATION_RISK, @MESSAGE, @CODE_POLICY, @CNAE, @STATE_REGISTRATION, @CPF_CNPJ, @NAME, @PATH_FILE_RESPONSE);

SET @COD_RESEARCH_RISK_RESPONSE = @@identity;
  
    
     IF @@rowcount < 1    
      THROW 60001, 'COULD NOT INSERT RESEARCH_RISK_RESPONSE', 1;

INSERT INTO RESEARCH_RISK_RESPONSE_DETAILS (COD_RESEARCH_RISK_RESPONSE, CODE, COD_SITUATION,
SITUATION_DESCRIPTION, COD_PARTNER_EC, CPF_PARTNER_EC)
	SELECT
		@COD_RESEARCH_RISK_RESPONSE
	   ,LINES.[CODE]
	   ,LINES.[COD_SITUATION]
	   ,LINES.[SITUATION_DESCRIPTION]
	   ,EC_PARTNERS.COD_ADT_DATA
	   ,LINES.[CPF_PARTNER_EC]
	FROM @LINES_RESEARCH_RISK_DETAILS AS LINES
	INNER JOIN RESEARCH_RISK
		ON RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK
	LEFT JOIN ADITIONAL_DATA_TYPE_EC AS EC_PARTNERS
		ON EC_PARTNERS.COD_EC = RESEARCH_RISK.COD_EC
			AND LINES.[CPF_PARTNER_EC] = EC_PARTNERS.CPF;
IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK_RESPONSE_DETAILS', 1;

-- BEGIN > AGENDAMENTO DE NOVAS PESQUISAS PROGRAMADAS (MONTHLY, YEARLY)            
SELECT TOP 1
	@COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
   ,@DOCUMENT_TYPE = COMMERCIAL_ESTABLISHMENT.DOCUMENT_TYPE
FROM COMMERCIAL_ESTABLISHMENT
INNER JOIN RESEARCH_RISK
	ON RESEARCH_RISK.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
WHERE RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK;

EXEC SP_CHECK_RISK_SEMAPHORE @SITUATION_RISK
							,@COD_RESEARCH_RISK

SET @COD_RESEARCH_RISK_TYPE = 0;
  
    
    
                -- > MONTHLY            
 IF ( SELECT
		COUNT(RESEARCH_RISK.COD_RESEARCH_RISK)
	FROM RESEARCH_RISK
	INNER JOIN RESEARCH_RISK_TYPE
		ON RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE =
		RESEARCH_RISK.COD_RESEARCH_RISK_TYPE
	WHERE RESEARCH_RISK.COD_EC = @COD_EC
	AND ((RESEARCH_RISK_TYPE.CODE = 'MONTHLY'
	AND RESEARCH_RISK.COD_STATUS IN (0, 1))
	OR (RESEARCH_RISK_TYPE.CODE = 'YEARLY'
	AND RESEARCH_RISK.COD_STATUS IN (0, 1)
	AND DATEADD(YEAR, 1, RESEARCH_RISK.CREATED_AT) < GETDATE())))
= 0
BEGIN

SET @COD_RESEARCH_RISK_TYPE = (SELECT TOP 1
		RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE
	FROM RESEARCH_RISK_TYPE
	WHERE RESEARCH_RISK_TYPE.CODE = 'MONTHLY'
	AND RESEARCH_RISK_TYPE.DOCUMENT_TYPE = @DOCUMENT_TYPE
	AND RESEARCH_RISK_TYPE.ACTIVE = 1
	AND RESEARCH_RISK_TYPE.SOURCE_NAME = 'OFAC');

INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS)
	VALUES (@COD_EC, NULL, @COD_RESEARCH_RISK_TYPE, 0);

SET @COD_RESEARCH_RISK_PK = @@identity;
END
END
-- COD_STATUS = 2 ( CALLBACK RECEBIDO - RETORNO RECEBIDO)      
-- COD_STATUS = 4 ( CALLBACK RECEBIDO COM RESALVAS - RECUSADO AUTOMATICAMENTE)       
ELSE
IF (@COD_STATUS IN (2, 4))
BEGIN
UPDATE RESEARCH_RISK
SET MODIFY_AT = current_timestamp
   ,COD_STATUS = 2
WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;
IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK', 1;

UPDATE RESEARCH_RISK_RESPONSE
SET ACTIVE = 0
WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;

INSERT INTO RESEARCH_RISK_RESPONSE (COD_RESEARCH_RISK, BID_ID, SITUATION_RISK, MESSAGE_SITUATION,
CODE_POLICY, CNAE, STATE_REGISTRATION, CPF_CNPJ, NAME_EC,
PATH_FILE_RESPONSE)
	VALUES (@COD_RESEARCH_RISK_PK, @BID_ID, @SITUATION_RISK, @MESSAGE, @CODE_POLICY, @CNAE, @STATE_REGISTRATION, @CPF_CNPJ, @NAME, @PATH_FILE_RESPONSE);

SET @COD_RESEARCH_RISK_RESPONSE = @@identity;
  
    
    
                    IF @@rowcount < 1    
                        THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK_RESPONSE', 1;

INSERT INTO RESEARCH_RISK_RESPONSE_DETAILS (COD_RESEARCH_RISK_RESPONSE, CODE, COD_SITUATION,
SITUATION_DESCRIPTION, COD_PARTNER_EC, CPF_PARTNER_EC)
	SELECT
		@COD_RESEARCH_RISK_RESPONSE
	   ,LINES.[CODE]
	   ,LINES.[COD_SITUATION]
	   ,LINES.[SITUATION_DESCRIPTION]
	   ,EC_PARTNERS.COD_ADT_DATA
	   ,LINES.[CPF_PARTNER_EC]
	FROM @LINES_RESEARCH_RISK_DETAILS AS LINES
	INNER JOIN RESEARCH_RISK
		ON RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK
	LEFT JOIN ADITIONAL_DATA_TYPE_EC AS EC_PARTNERS
		ON EC_PARTNERS.COD_EC = RESEARCH_RISK.COD_EC
			AND LINES.[CPF_PARTNER_EC] = EC_PARTNERS.CPF;
IF @@rowcount < 1
THROW 60001, 'COULD NOT INSERT RESEARCH_RISK_RESPONSE_DETAILS', 1;

EXEC SP_CHECK_RISK_SEMAPHORE @SITUATION_RISK
							,@COD_RESEARCH_RISK

END

IF @PATH_FILE_RESPONSE_CONSOLIDATED IS NOT NULL
BEGIN
UPDATE RESEARCH_RISK_DETACHED
SET PATH_FILE_RESPONSE = @PATH_FILE_RESPONSE_CONSOLIDATED
   ,MODIFY_AT = dbo.FN_FUS_UTF(current_timestamp)
WHERE COD_RESEARCH_RISK_DETACHED = (SELECT TOP 1
		RESEARCH_RISK_DETACHED_LINES.COD_RESEARCH_RISK_DETACHED
	FROM RESEARCH_RISK_DETACHED
	INNER JOIN RESEARCH_RISK_DETACHED_LINES
		ON RESEARCH_RISK_DETACHED_LINES.COD_RESEARCH_RISK_DETACHED =
		RESEARCH_RISK_DETACHED.COD_RESEARCH_RISK_DETACHED
	INNER JOIN RESEARCH_RISK
		ON RESEARCH_RISK.COD_RISK_DETACHED_LINES =
		RESEARCH_RISK_DETACHED_LINES.COD_RISK_DETACHED_LINES
	WHERE RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK)


END

END

GO

IF OBJECT_ID('SP_LS_RISK_SEMAPHORE') IS NOT NULL
DROP PROCEDURE SP_LS_RISK_SEMAPHORE
GO
CREATE PROCEDURE [dbo].[SP_LS_RISK_SEMAPHORE]
/*----------------------------------------------------------------------------------------       
  Project.......: TKPP       
------------------------------------------------------------------------------------------       
  Author              VERSION        Date         Description       
------------------------------------------------------------------------------------------       
  Luiz Aquino          1            2021-02-22      Created
------------------------------------------------------------------------------------------*/
(
    @MCC VARCHAR(16) = NULL,
    @COD_SEG INT = NULL,
    @PAGE INT = 1,
    @PAGESIZE INT = 10,
    @TOTAL INT OUTPUT
) AS BEGIN

    DECLARE @QUERY NVARCHAR(MAX), @COUNT NVARCHAR(MAX), @SKIP INT = @PAGESIZE * (@PAGE - 1);

SET @QUERY = '
    FROM RISK_MCC_SEMAPHORE RMS
    JOIN SEGMENTS S on RMS.COD_SEG = S.COD_SEG
    JOIN TYPE_ESTAB TE on RMS.COD_TYPE_EC = TE.COD_TYPE_ESTAB  
    WHERE S.ACTIVE = 1 AND S.VISIBLE = 1 ';

    IF @MCC IS NOT NULL
SET @QUERY += ' AND S.CODE = @MCC  ';

IF @COD_SEG IS NOT NULL
SET @QUERY += ' AND RMS.COD_SEG = @COD_SEG ';

SET @COUNT = 'SELECT @TOTAL = COUNT(*) ' + @QUERY;

EXEC sp_executesql @COUNT
				  ,N' @MCC VARCHAR(16),
            @COD_SEG INT,
            @TOTAL INT OUTPUT 
         '
				  ,@MCC = @MCC
				  ,@COD_SEG = @COD_SEG
				  ,@TOTAL = @TOTAL OUTPUT;

SET @QUERY = '
    SELECT RMS.COD_MCC_RISK,
           S.CODE MCC,
           S.NAME SEGMENT,
           RMS.LIMIT,
           RMS.LIMIT_DAY,
           RMS.RISK,
           TE.CODE TYPE_ESTAB,
           RMS.COD_SEG,
           RMS.COD_TYPE_EC' + @QUERY + ' ORDER BY S.CODE OFFSET @SKIP ROW FETCH NEXT @PAGESIZE ROWS ONLY ';

EXEC sp_executesql @QUERY
				  ,N' @MCC VARCHAR(16),
            @COD_SEG INT,
            @PAGE INT,
            @PAGESIZE INT,
            @SKIP INT
         '
				  ,@MCC = @MCC
				  ,@COD_SEG = @COD_SEG
				  ,@PAGE = @PAGE
				  ,@PAGESIZE = @PAGESIZE
				  ,@SKIP = @SKIP;

END
GO

IF OBJECT_ID('SP_LS_SEGMMENTS_PREFIXO') IS NOT NULL
DROP PROCEDURE SP_LS_SEGMMENTS_PREFIXO
GO
CREATE PROCEDURE [dbo].[SP_LS_SEGMMENTS_PREFIXO]
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_LS_SEGMMENTS_PREFIXO]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                VERSION        Date                      Description      
------------------------------------------------------------------------------------------      
Kennedy Alef          V1            27/07/2018                  Creation      
Elir Ribeiro          V2            18/10                       add active    
Marcus Gall           V3            14/11/2019         Add Branch Business Parameter  
Caike Uchôa           V4            10/01/2020                 ADD VISIBLE
Luiz Aquino           V1            23/02/2021              Add mcc
------------------------------------------------------------------------------------------*/
(@NAME VARCHAR(200),
 @COD_BRANCH_BUSINESS INT = NULL)
AS
DECLARE @QUERY NVARCHAR(MAX)


BEGIN


    IF (@COD_BRANCH_BUSINESS <> '')
SELECT
	[NAME]
   ,[COD_SEG]
   ,[ACTIVE]
   ,CODE MCC
FROM [dbo].[SEGMENTS]
WHERE [ACTIVE] = 1
AND [COD_BRANCH_BUSINESS] = @COD_BRANCH_BUSINESS
AND ([NAME] LIKE +'%' + @NAME + '%'
OR [CNAE] LIKE +'%' + @NAME + '%'
OR [CODE] LIKE +'%' + @NAME + '%')
AND VISIBLE = 1
ORDER BY [NAME]
ELSE
SELECT
	[NAME]
   ,[COD_SEG]
   ,[ACTIVE]
   ,CODE MCC
FROM [dbo].[SEGMENTS]
WHERE [ACTIVE] = 1
AND ([NAME] LIKE +'%' + @NAME + '%'
OR [CNAE] LIKE +'%' + @NAME + '%'
OR [CODE] LIKE +'%' + @NAME + '%')
AND VISIBLE = 1
ORDER BY [NAME]
END
GO


IF OBJECT_ID('SP_CREATE_RISK_TABLE') IS NOT NULL
DROP PROCEDURE SP_CREATE_RISK_TABLE
GO
CREATE PROCEDURE SP_CREATE_RISK_TABLE
/*----------------------------------------------------------------------------------------       
  Project.......: TKPP       
------------------------------------------------------------------------------------------       
  Author              VERSION        Date         Description       
------------------------------------------------------------------------------------------       
  Luiz Aquino          1            2021-02-24      Created
------------------------------------------------------------------------------------------*/
(
    @COD_SEG INT,
    @COD_TYPE_EC INT,
    @LIMIT DECIMAL(22, 6),
    @LIMIT_DAY DECIMAL(22, 6),
    @COD_USER INT
) AS BEGIN

DELETE FROM RISK_MCC_SEMAPHORE
WHERE COD_SEG = @COD_SEG
	AND @COD_TYPE_EC = COD_TYPE_EC

INSERT INTO RISK_MCC_SEMAPHORE (COD_SEG, COD_TYPE_EC, LIMIT, LIMIT_DAY, COD_USER)
	VALUES (@COD_SEG, @COD_TYPE_EC, @LIMIT, @LIMIT_DAY, @COD_USER)

END
GO

IF OBJECT_ID('SP_RISK_TABLE_MISSING') IS NOT NULL
DROP PROCEDURE SP_RISK_TABLE_MISSING
GO
CREATE PROCEDURE SP_RISK_TABLE_MISSING
/*----------------------------------------------------------------------------------------       
  Project.......: TKPP       
------------------------------------------------------------------------------------------       
  Author              VERSION        Date         Description       
------------------------------------------------------------------------------------------       
  Luiz Aquino          1            2021-02-24      Created
------------------------------------------------------------------------------------------*/
AS BEGIN

SELECT
	S.CODE [MCC]
   ,S.COD_SEG
   ,TE.COD_TYPE_ESTAB
   ,S.NAME
   ,TE.CODE
FROM SEGMENTS S
JOIN TYPE_ESTAB TE
	ON 1 = 1
LEFT JOIN RISK_MCC_SEMAPHORE RMS
	ON TE.COD_TYPE_ESTAB = RMS.COD_TYPE_EC
		AND S.COD_SEG = RMS.COD_SEG
WHERE RMS.COD_MCC_RISK IS NULL
AND S.VISIBLE = 1
ORDER BY S.CODE

END
GO

IF OBJECT_ID('SP_ALL_RISK_TABLE') IS NOT NULL
DROP PROCEDURE SP_ALL_RISK_TABLE
GO
CREATE PROCEDURE SP_ALL_RISK_TABLE
/*----------------------------------------------------------------------------------------       
  Project.......: TKPP       
------------------------------------------------------------------------------------------       
  Author              VERSION        Date         Description       
------------------------------------------------------------------------------------------       
  Luiz Aquino          1            2021-02-24      Created
------------------------------------------------------------------------------------------*/
AS BEGIN

SELECT
	RMS.COD_MCC_RISK
   ,S.CODE MCC
   ,S.NAME SEGMENT
   ,RMS.LIMIT
   ,RMS.LIMIT_DAY
   ,RMS.RISK
   ,TE.CODE TYPE_ESTAB
   ,RMS.COD_SEG
   ,RMS.COD_TYPE_EC
FROM RISK_MCC_SEMAPHORE RMS
JOIN SEGMENTS S
	ON RMS.COD_SEG = S.COD_SEG
		AND S.ACTIVE = 1
		AND S.VISIBLE = 1
JOIN TYPE_ESTAB TE
	ON RMS.COD_TYPE_EC = TE.COD_TYPE_ESTAB
ORDER BY S.CODE
END
GO

IF OBJECT_ID('SP_CREATE_ALL_RISK_TABLE') IS NOT NULL
DROP PROCEDURE SP_CREATE_ALL_RISK_TABLE
GO
IF TYPE_ID('TP_RISK_TB') IS NOT NULL
DROP TYPE TP_RISK_TB
GO
CREATE TYPE TP_RISK_TB AS TABLE
(
    COD_SEG INT NOT NULL,
    COD_TYPE_EC INT NOT NULL,
    LIMIT DECIMAL(22, 6) NOT NULL,
    LIMIT_DAY DECIMAL(22, 6) NOT NULL
)
GO
CREATE PROCEDURE SP_CREATE_ALL_RISK_TABLE
/*----------------------------------------------------------------------------------------       
  Project.......: TKPP       
------------------------------------------------------------------------------------------       
  Author              VERSION        Date         Description       
------------------------------------------------------------------------------------------       
  Luiz Aquino          1            2021-02-25      Created
------------------------------------------------------------------------------------------*/
(
    @ITEMS TP_RISK_TB READONLY ,
    @COD_USER INT NULL
) AS BEGIN

DELETE RMS
	FROM RISK_MCC_SEMAPHORE RMS
	JOIN @ITEMS I
		ON I.COD_SEG = RMS.COD_SEG
		AND I.COD_TYPE_EC = RMS.COD_TYPE_EC

INSERT INTO RISK_MCC_SEMAPHORE (COD_SEG, COD_TYPE_EC, LIMIT, LIMIT_DAY, COD_USER)
	SELECT
		I.COD_SEG
	   ,I.COD_TYPE_EC
	   ,I.LIMIT
	   ,I.LIMIT_DAY
	   ,@COD_USER
	FROM @ITEMS I

END
GO

IF OBJECT_ID('SP_VALIDATE_TRANSACTION') IS NOT NULL
DROP PROCEDURE SP_VALIDATE_TRANSACTION
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

IF @COD_RISK_SITUATION NOT IN (2, 9)

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
IF OBJECT_ID('SP_VALIDATE_TRANSACTION_ON') IS NOT NULL
DROP PROCEDURE SP_VALIDATE_TRANSACTION_ON
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
Caike Uchoa      v6   17-11-2020    Permitir tranções com limite excedido   
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

--IF @AMOUNT > @LIMIT    
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
--         ,@COMMENT = '402 - Transaction limit value exceeded'    
--         ,@TERMINALDATE = @TERMINALDATE    
--         ,@TYPE = @TYPE    
--         ,@COD_COMP = @COD_COMP    
--         ,@COD_AFFILIATOR = @COD_AFFILIATOR    
--         ,@SOURCE_TRAN = 1    
--         ,@CODE_SPLIT = @CODE_SPLIT    
--         ,@COD_EC = @EC_TRANS    
--         ,@CREDITOR_DOC = @CREDITOR_DOC    
--         ,@HOLDER_NAME = @HOLDER_NAME    
--         ,@HOLDER_DOC = @HOLDER_DOC    
--         ,@LOGICAL_NUMBER = @LOGICAL_NUMBER    
--         ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL    
--         ,@LINK_MODE = @LINK_MODE    
--         ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION    
--         ,@BILLCODE = @BILLCODE    
--         ,@BILLEXPIREDATE = @BILLEXPIREDATE;    

-- THROW 60002    
-- , '402'    
-- , 1;    
--END;    

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

--EXEC SP_VAL_LIMIT_EC @CODEC    
--     ,@AMOUNT    
--     ,@PAN = @PAN    
--     ,@BRAND = @BRAND    
--     ,@CODASS_DEPTO_TERMINAL = @CODASS    
--     ,@COD_TTYPE = @TYPETRAN    
--     ,@PLOTS = @QTY_PLOTS    
--     ,@CODTAX_ASS = @CODTX    
--     ,@CODETR = @TRCODE    
--     ,@TYPE = @TYPE    
--     ,@TERMINALDATE = @TERMINALDATE    
--     ,@COD_COMP = @COD_COMP    
--     ,@COD_AFFILIATOR = @COD_AFFILIATOR    
--     ,@CODE_SPLIT = @CODE_SPLIT    
--     ,@EC_TRANS = @EC_TRANS    
--     ,@HOLDER_NAME = @HOLDER_NAME    
--     ,@HOLDER_DOC = @HOLDER_DOC    
--     ,@LOGICAL_NUMBER = @LOGICAL_NUMBER    
--     ,@SOURCE_TRAN = 1    
--     ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL    
--     ,@LINK_MODE = @LINK_MODE    
--     ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;    


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
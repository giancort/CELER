-- ET-920


IF ( SELECT
		COUNT(*)
	FROM PLAN_OPTION
	WHERE CODE = 'TERMINAL_PLAN')
= 0
INSERT INTO PLAN_OPTION (CODE)
	VALUES ('TERMINAL_PLAN');

GO

IF NOT EXISTS (SELECT
		1
	FROM [sys].[columns]
	WHERE NAME = N'COD_MODEL'
	AND object_id = OBJECT_ID(N'TAX_PLAN'))
BEGIN

ALTER TABLE TAX_PLAN ADD COD_MODEL INT;

ALTER TABLE TAX_PLAN ADD FOREIGN KEY (COD_MODEL) REFERENCES EQUIPMENT_MODEL (COD_MODEL)
END;

GO

--TEST
 
IF NOT EXISTS (SELECT
		1
	FROM [sys].[columns]
	WHERE NAME = N'COD_MODEL'
	AND object_id = OBJECT_ID(N'PLAN_TAX_AFFILIATOR'))
BEGIN

ALTER TABLE PLAN_TAX_AFFILIATOR ADD COD_MODEL INT;

ALTER TABLE PLAN_TAX_AFFILIATOR ADD FOREIGN KEY (COD_MODEL) REFERENCES EQUIPMENT_MODEL (COD_MODEL)
END;

GO

IF NOT EXISTS (SELECT
		1
	FROM [sys].[columns]
	WHERE NAME = N'COD_MODEL'
	AND object_id = OBJECT_ID(N'ASS_TAX_DEPART'))
BEGIN

ALTER TABLE ASS_TAX_DEPART ADD COD_MODEL INT;

ALTER TABLE ASS_TAX_DEPART ADD FOREIGN KEY (COD_MODEL) REFERENCES EQUIPMENT_MODEL (COD_MODEL)
END;

GO



IF OBJECT_ID('SP_REG_PLAN') IS NOT NULL DROP PROCEDURE SP_REG_PLAN;
GO
CREATE PROCEDURE [DBO].[SP_REG_PLAN]      
  
/*********************************************************************************************  
----------------------------------------------------------------------------------------      
Procedure Name: SP_REG_PLAN      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Kennedy Alef      V1     27/07/2018        Creation      
Gian Luca Dalle Cort    V1     01/08/2018        CHANGED      
Lucas Aguiar      V2     18/06/2020    ET-920 Plano por modelo  
------------------------------------------------------------------------------------------  
*********************************************************************************************/  
      
(  
 @CODE              VARCHAR(100),   
 @TYPEPLAN          INT,   
 @DESCRIPTION       VARCHAR(100),   
 @CODUSER           INT,   
 @COMPANY           INT,   
 @CODSEG            INT,   
 @COD_REQ           INT          = NULL,   
 @COD_SIT           INT          = NULL,   
 @COD_AFFILIATOR    INT          = NULL,   
 @COD_PLAN_CATEGORY INT          = NULL,   
 @COD_BILLING       INT          = NULL,   
 @COD_OPT_PLAN      INT          = NULL)  
AS  
BEGIN
  
    DECLARE @CONT INT;
  
    BEGIN

SELECT
	@CONT = COUNT(*)
FROM [PLAN]
WHERE [CODE] = @CODE
AND [COD_COMP] = @COMPANY;

IF @CONT > 0
THROW 61005, 'PLAN ALREADY REGISTERED', 1;

INSERT INTO [PLAN] ([CODE],
[COD_T_PLAN],
[DESCRIPTION],
[COD_COMP],
[COD_SEG],
[COD_USER],
[COD_SITUATION],
[COD_REQ],
[COD_AFFILIATOR],
[COD_PLAN_CATEGORY],
[COD_BILLING],
[COD_PLAN_OPT])
	VALUES (@CODE, @TYPEPLAN, @DESCRIPTION, @COMPANY, @CODSEG, @CODUSER, @COD_SIT, @COD_REQ, @COD_AFFILIATOR, @COD_PLAN_CATEGORY, @COD_BILLING, @COD_OPT_PLAN);

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER [PLAN] ', 1;

SELECT
	@@identity AS [COD_PLAN];
END;
END;

GO

  
IF OBJECT_ID('SP_REG_TAX_PLAN') IS NOT NULL DROP PROCEDURE SP_REG_TAX_PLAN;
GO
CREATE PROCEDURE [DBO].[SP_REG_TAX_PLAN]              
  
/*****************************************************************************************************  
----------------------------------------------------------------------------------------              
Procedure Name: [SP_REG_TAX_PLAN]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION     Date                            Description              
------------------------------------------------------------------------------------------              
Kennedy Alef      V1      27/07/2018     Creation  
Lucas Aguiar      V2      18/06/2020    ET-920 Plano por modelo  
------------------------------------------------------------------------------------------  
*****************************************************************************************************/  
           
(  
 @COD_TRAN_TYPE        INT,   
 @QTY_INI_PL           INT,   
 @QTY_FINAL_FL         INT,   
 @PERCENT              DECIMAL(22, 6),   
 @RATE                 DECIMAL(22, 6),   
 @INTERVAL             INT,   
 @CODPLAN              INT,   
 @ANTICIPATION         DECIMAL(22, 6),   
 @PERCENTAGE_EFFECTIVE DECIMAL(22, 6),   
 @COD_BRAND            VARCHAR(100)   = NULL,   
 @COD_TAX_TYPE         INT            = NULL,   
 @COD_MODEL            INT            = NULL)  
AS  
BEGIN
  
    DECLARE @CONT INT= 0;
  
    DECLARE @INSIDECODE_BRANCH INT;
  
    BEGIN

SET @INSIDECODE_BRANCH = (SELECT
		[COD_BRAND]
	FROM [BRAND]
	WHERE [GROUP] = @COD_BRAND
	AND [COD_TTYPE] = @COD_TRAN_TYPE);


SELECT
	@CONT = COUNT(*)
FROM [TAX_PLAN]
WHERE [COD_TTYPE] = @COD_TRAN_TYPE
AND [QTY_INI_PLOTS] = @QTY_INI_PL
AND [QTY_FINAL_PLOTS] = @QTY_FINAL_FL
AND [PARCENTAGE] = @PERCENT
AND [RATE] = @RATE
AND [COD_PLAN] = @CODPLAN
AND [ACTIVE] = 1
AND [COD_BRAND] = @INSIDECODE_BRANCH
AND [COD_SOURCE_TRAN] = @COD_TAX_TYPE;

IF @CONT > 0
THROW 61001, 'TAX ALREADY REGISTERED TO THIS PLAN', 1;

INSERT INTO [TAX_PLAN] ([COD_TTYPE],
[QTY_INI_PLOTS],
[QTY_FINAL_PLOTS],
[PARCENTAGE],
[RATE],
[INTERVAL],
[COD_PLAN],
[ANTICIPATION_PERCENTAGE],
[EFFECTIVE_PERCENTAGE],
[COD_BRAND],
[COD_SOURCE_TRAN],
[COD_MODEL])
	VALUES (@COD_TRAN_TYPE, @QTY_INI_PL, @QTY_FINAL_FL, @PERCENT, @RATE, @INTERVAL, @CODPLAN, @ANTICIPATION, @PERCENTAGE_EFFECTIVE, @COD_BRAND, @COD_TAX_TYPE, @COD_MODEL);

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER TAX_PLAN', 1;
END;
END;
GO


IF OBJECT_ID('SP_ADD_TAX_DEPTO') IS NOT NULL DROP PROCEDURE SP_ADD_TAX_DEPTO;
GO
CREATE PROCEDURE [dbo].[SP_ADD_TAX_DEPTO]
/*----------------------------------------------------------------------------------------        
 Procedure Name: [SP_DISABLE_TX_DEPTO_PLAN]        
 Project.......: TKPP        
 ------------------------------------------------------------------------------------------        
 Author                          VERSION         Date                            Description        
 ------------------------------------------------------------------------------------------        
 Luiz Aquino                     V1              05/02/2019                      Add Cod Plan Affiliated        
 ------------------------------------------------------------------------------------------*/
(
    @COD_TTYPE INT,
    @QTY_INI_PLOTS INT,
    @QTY_FINAL_PLOTS INT,
    @PARCENTAGE DECIMAL(22, 6),
    @RATE DECIMAL(22, 6),
    @INTERVAL INT,
    @COD_DEPTO_BRANCH INT,
    @CODUSER INT,
    @ANTICIPATION DECIMAL(22, 6),
    @PERCENTAGE_EFFECTIVE DECIMAL(22, 6),
    @COD_PLAN INT,
    @COD_BRAND INT = NULL,
    @COD_TAX_TYPE INT = 2,
    @COD_PLAN_AFFILIATED INT = NULL,
	@COD_MODEL int = null 
) AS DECLARE @QTD INT;

DECLARE @COD_AFFILIATED INT;

DECLARE @PERCENTAGE_VALID DECIMAL(22, 6);

DECLARE @RATE_VALID DECIMAL(22, 6);

DECLARE @ANTECIP_VALID DECIMAL(22, 6);

BEGIN
SELECT
TOP 1
	@COD_AFFILIATED = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
FROM DEPARTMENTS_BRANCH
JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
WHERE DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH
IF @COD_PLAN_AFFILIATED IS NULL
	AND @COD_AFFILIATED IS NOT NULL
SELECT
TOP 1
	@COD_PLAN_AFFILIATED = PLAN_TAX_AFFILIATOR.COD_PLAN
FROM PLAN_TAX_AFFILIATOR
WHERE PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATED
AND ACTIVE = 1
IF @COD_AFFILIATED IS NOT NULL
BEGIN
SELECT
	@PERCENTAGE_VALID = (@PARCENTAGE - PLAN_TAX_AFFILIATOR.[PERCENTAGE])
   ,@RATE_VALID = (@RATE - PLAN_TAX_AFFILIATOR.RATE)
   ,@ANTECIP_VALID = (
	@ANTICIPATION - PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE
	)
FROM PLAN_TAX_AFFILIATOR
WHERE PLAN_TAX_AFFILIATOR.COD_TTYPE = @COD_TTYPE
AND (
PLAN_TAX_AFFILIATOR.COD_BRAND = @COD_BRAND
OR PLAN_TAX_AFFILIATOR.COD_BRAND IS NULL
)
AND PLAN_TAX_AFFILIATOR.COD_SOURCE_TRAN = @COD_TAX_TYPE
AND @QTY_INI_PLOTS BETWEEN PLAN_TAX_AFFILIATOR.QTY_INI_PLOTS
AND PLAN_TAX_AFFILIATOR.QTY_FINAL_PLOTS
AND PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATED
AND ACTIVE = 1;


SELECT
	@PERCENTAGE_VALID = (@PARCENTAGE - PLAN_TAX_AFFILIATOR.[PERCENTAGE])
   ,@RATE_VALID = (@RATE - PLAN_TAX_AFFILIATOR.RATE)
   ,@ANTECIP_VALID = (
	@ANTICIPATION - PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE
	)
FROM PLAN_TAX_AFFILIATOR
WHERE PLAN_TAX_AFFILIATOR.COD_TTYPE = @COD_TTYPE
AND (
PLAN_TAX_AFFILIATOR.COD_BRAND = @COD_BRAND
OR PLAN_TAX_AFFILIATOR.COD_BRAND IS NULL
)
AND PLAN_TAX_AFFILIATOR.COD_SOURCE_TRAN = @COD_TAX_TYPE
AND @QTY_FINAL_PLOTS BETWEEN PLAN_TAX_AFFILIATOR.QTY_INI_PLOTS
AND PLAN_TAX_AFFILIATOR.QTY_FINAL_PLOTS
AND PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATED
AND ACTIVE = 1;

END;

INSERT INTO ASS_TAX_DEPART (COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
PARCENTAGE,
RATE,
INTERVAL,
COD_DEPTO_BRANCH,
COD_USER,
COD_PLAN,
EFFECTIVE_PERCENTAGE,
ANTICIPATION_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	VALUES (@COD_TTYPE, @QTY_INI_PLOTS, @QTY_FINAL_PLOTS, @PARCENTAGE, @RATE, @INTERVAL, @COD_DEPTO_BRANCH, @CODUSER, @COD_PLAN, @PERCENTAGE_EFFECTIVE, @ANTICIPATION, @COD_BRAND, @COD_TAX_TYPE, @COD_MODEL);

UPDATE DEPARTMENTS_BRANCH
SET COD_PLAN = @COD_PLAN
   ,COD_T_PLAN = (SELECT
			COD_T_PLAN
		FROM [PLAN]
		WHERE COD_PLAN = @COD_PLAN)
WHERE DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH;

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER ASS_TAX_DEPART ', 1;

END;

GO

IF OBJECT_ID('SP_ADD_TAX_PLAN_AFFILIATOR') IS NOT NULL DROP PROCEDURE SP_ADD_TAX_PLAN_AFFILIATOR;
GO
CREATE PROCEDURE [dbo].[SP_ADD_TAX_PLAN_AFFILIATOR]  
      
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_DISABLE_TX_DEPTO_PLAN]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Gian Luca Dalle Cort   V1      01/10/2018      Creation      
------------------------------------------------------------------------------------------*/      
      
(        
@COD_TTYPE INT,        
@QTY_INI_PLOTS INT ,        
@QTY_FINAL_PLOTS INT,        
@PARCENTAGE DECIMAL(22,6),        
@RATE DECIMAL(22,6),        
@INTERVAL INT,        
@COD_AFFILIATOR INT,        
@CODUSER INT,        
@ANTICIPATION DECIMAL(22,6),        
@PERCENTAGE_EFFECTIVE DECIMAL(22,6),        
@COD_PLAN INT,        
@COD_BRAND INT = NULL,      
@COD_SOURCE_TRAN INT = 2,
@COD_MODEL int = null
)        
AS        
DECLARE @QTD INT;
  
        
BEGIN


INSERT INTO PLAN_TAX_AFFILIATOR (COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
[PERCENTAGE],
RATE,
INTERVAL,
COD_AFFILIATOR,
COD_USER,
COD_PLAN,
EFFECTIVE_PERCENTAGE,
ANTICIPATION_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	VALUES (@COD_TTYPE, @QTY_INI_PLOTS, @QTY_FINAL_PLOTS, @PARCENTAGE, @RATE, @INTERVAL, @COD_AFFILIATOR, @CODUSER, @COD_PLAN, @PERCENTAGE_EFFECTIVE, @ANTICIPATION, @COD_BRAND, @COD_SOURCE_TRAN, @COD_MODEL);


IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER PLAN_TAX_AFFILIATOR ', 1;

END;

GO

IF OBJECT_ID('SP_UP_DATA_PLAN') IS NOT NULL DROP PROCEDURE SP_UP_DATA_PLAN;
GO
CREATE PROCEDURE [DBO].[SP_UP_DATA_PLAN]      
  
/*********************************************************************************************  
----------------------------------------------------------------------------------------      
Procedure Name: [SP_UP_DATA_PLAN]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Kennedy Alef     V1      27/07/2018        Creation      
------------------------------------------------------------------------------------------  
*********************************************************************************************/  
      
(  
 @NAME         VARCHAR(100),   
 @DESCRIPTION  VARCHAR(100),   
 @ACTIVE       INT,   
 @COD_SEG      INT,   
 @COD_PLAN     INT,   
 @COD_TYPEPLAN INT,   
 @CODUSER      INT,   
 @COD_BILLING  INT          = NULL,   
 @COD_OPT_PLAN INT          = NULL)  
AS  
BEGIN

UPDATE [PLAN]
SET [CODE] = @NAME
   ,[COD_T_PLAN] = @COD_TYPEPLAN
   ,[DESCRIPTION] = @DESCRIPTION
   ,[ACTIVE] = @ACTIVE
   ,[COD_USER_MODIFY] = @CODUSER
   ,[COD_SEG] = @COD_SEG
   ,[MODIFY_DATE] = GETDATE()
   ,[COD_BILLING] = @COD_BILLING
   ,[COD_PLAN_OPT] = @COD_OPT_PLAN
WHERE [COD_PLAN] = @COD_PLAN;

IF @@rowcount < 1
THROW 60001, 'COULD NOT UPDATE [PLAN] ', 1;

END;

GO


IF OBJECT_ID('SP_FD_DATA_PLAN') IS NOT NULL
DROP PROCEDURE SP_FD_DATA_PLAN;
GO
CREATE PROCEDURE [dbo].[SP_FD_DATA_PLAN]

/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_FD_DATA_PLAN]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Kennedy Alef     V1    27/07/2018      Creation        
Lucas Aguiar     V2    23/10/2018      Change        
------------------------------------------------------------------------------------------*/

(@COD_PLAN INT
)
AS
    BEGIN
SELECT
	TYPE_PLAN.CODE AS TYPE_PLAN
   ,[PLAN].COD_PLAN AS PLAN_INSIDECODE
   ,[PLAN].CODE AS NAME_PLAN
   ,[PLAN].DESCRIPTION AS [DESCRIPTION]
   ,[PLAN].COD_PLAN_OPT
   ,SEGMENTS.COD_SEG AS SEG_INSIDECODE
   ,SEGMENTS.NAME AS SEGMENT
   ,TRANSACTION_TYPE.COD_TTYPE AS TP_RATE_INSIDECODE
   ,TRANSACTION_TYPE.CODE AS TYPE_RATE
   ,TAX_PLAN.QTY_INI_PLOTS
   ,TAX_PLAN.QTY_FINAL_PLOTS
   ,TAX_PLAN.PARCENTAGE
   ,TAX_PLAN.RATE
   ,TAX_PLAN.INTERVAL
   ,TAX_PLAN.EFFECTIVE_PERCENTAGE AS PERCENTAGE_EFFECTIVE
   ,TAX_PLAN.ANTICIPATION_PERCENTAGE AS ANTICIPATION
   ,TAX_PLAN.COD_MODEL
   ,BRAND.COD_BRAND
   ,TAX_PLAN.COD_SOURCE_TRAN AS COD_TAX_TYPE
   ,SOURCE_TRANSACTION.DESCRIPTION AS 'TAX_TYPE'
   ,BRAND.[GROUP] AS 'NAME'
FROM TAX_PLAN
INNER JOIN [PLAN]
	ON [PLAN].COD_PLAN = TAX_PLAN.COD_PLAN
INNER JOIN TYPE_PLAN
	ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN
INNER JOIN TRANSACTION_TYPE
	ON TAX_PLAN.COD_TTYPE = TRANSACTION_TYPE.COD_TTYPE
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = [PLAN].COD_SEG
LEFT JOIN BRAND
	ON BRAND.COD_BRAND = TAX_PLAN.COD_BRAND
INNER JOIN SOURCE_TRANSACTION
	ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = TAX_PLAN.COD_SOURCE_TRAN
WHERE TAX_PLAN.ACTIVE = 1
AND [PLAN].COD_PLAN = @COD_PLAN;
END;
GO

IF OBJECT_ID('SP_LS_PLAN_SEGMENTS') IS NOT NULL
DROP PROCEDURE SP_LS_PLAN_SEGMENTS;
GO
CREATE PROCEDURE [dbo].[SP_LS_PLAN_SEGMENTS]

/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_LS_PLAN_SEGMENTS]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Kennedy Alef     V1    27/07/2018      Creation        
------------------------------------------------------------------------------------------*/

(@CODCOMP        INT, 
 @COD_SEG        INT, 
 @TYPE_PLAN      INT, 
 @COD_AFFILIATOR INT          = NULL, 
 @COD_TYPE_PLAN  INT          = NULL, 
 @PREFIX         VARCHAR(255) = NULL
)
AS
    BEGIN
        DECLARE @QUERY NVARCHAR(MAX);
SET @QUERY = N'SELECT          
							COD_PLAN,        
							[PLAN].CODE AS NAME,        
							ACTIVE ,        
							TYPE_PLAN.CODE AS TYPE_PLAN        
						FROM [PLAN]         
						INNER JOIN TYPE_PLAN ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN        
							WHERE [PLAN].ACTIVE = 1 AND  [PLAN].COD_COMP = @CODCOMP';
        IF @TYPE_PLAN IS NOT NULL
SET @QUERY = @QUERY + ' AND TYPE_PLAN.COD_T_PLAN = @TYPE_PLAN';
IF @COD_SEG IS NOT NULL
SET @QUERY = @QUERY + ' AND [PLAN].COD_SEG = @COD_SEG';
IF @COD_AFFILIATOR IS NOT NULL
SET @QUERY = @QUERY + ' AND [PLAN].COD_AFFILIATOR = @COD_AFFILIATOR';
IF @PREFIX IS NOT NULL
SET @QUERY = @QUERY + ' AND [PLAN].CODE LIKE ''%'' + @PREFIX  + ''%'' ';
SET @COD_TYPE_PLAN = ISNULL(@COD_TYPE_PLAN, 1);
SET @QUERY = @QUERY + ' AND [PLAN].COD_PLAN_CATEGORY = @COD_TYPE_PLAN ORDER BY [PLAN].CODE ';
EXEC sp_executesql @QUERY
				  ,N'  
        	@CODCOMP INT,  
        	@COD_SEG INT,  
			@TYPE_PLAN INT,
        	@COD_AFFILIATOR INT,  
        	@COD_TYPE_PLAN INT, 
        	@PREFIX VARCHAR(255)
        '
				  ,@CODCOMP = @CODCOMP
				  ,@COD_SEG = @COD_SEG
				  ,@TYPE_PLAN = @TYPE_PLAN
				  ,@COD_AFFILIATOR = @COD_AFFILIATOR
				  ,@COD_TYPE_PLAN = @COD_TYPE_PLAN
				  ,@PREFIX = @PREFIX;
END;
GO


IF OBJECT_ID('SP_LS_TX_PLAN') IS NOT NULL
DROP PROCEDURE [SP_LS_TX_PLAN];
GO
CREATE PROCEDURE [dbo].[SP_LS_TX_PLAN]

/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_LS_TX_PLAN]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Kennedy Alef     V1    27/07/2018      Creation      
Gian Luca Dalle Cort   V1    13/09/2018      Changed      
------------------------------------------------------------------------------------------*/

(@CODPLAN INT
)
AS
    BEGIN
SELECT
	[PLAN].CODE AS PLANCODE
   ,TRANSACTION_TYPE.CODE AS TYPE
   ,TRANSACTION_TYPE.COD_TTYPE AS TYPETR_INSIDECODE
   ,[TAX_PLAN].QTY_INI_PLOTS
   ,[TAX_PLAN].QTY_FINAL_PLOTS
   ,[TAX_PLAN].PARCENTAGE
   ,[TAX_PLAN].RATE
   ,[TAX_PLAN].INTERVAL
   ,[TAX_PLAN].EFFECTIVE_PERCENTAGE AS PERCENTAGE_EFFECTIVE
   ,[TAX_PLAN].ANTICIPATION_PERCENTAGE AS ANTICIPATION
   ,[TAX_PLAN].COD_MODEL
   ,BRAND.[GROUP] AS 'BRAND'
   ,BRAND.COD_BRAND
   ,SOURCE_TRANSACTION.COD_SOURCE_TRAN AS COD_TAX_TYPE
   ,SOURCE_TRANSACTION.DESCRIPTION AS 'TAX_TYPE'
FROM [TAX_PLAN]
INNER JOIN [PLAN]
	ON [PLAN].COD_PLAN = [TAX_PLAN].COD_PLAN
INNER JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = [TAX_PLAN].COD_TTYPE
INNER JOIN SOURCE_TRANSACTION
	ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = TAX_PLAN.COD_SOURCE_TRAN
LEFT JOIN BRAND
	ON BRAND.COD_BRAND = TAX_PLAN.COD_BRAND
WHERE [PLAN].COD_PLAN = @CODPLAN
AND [TAX_PLAN].ACTIVE = 1;
END;

GO

IF OBJECT_ID('SP_LS_PLAN_TAX_AFFILIATOR') IS NOT NULL
DROP PROCEDURE [SP_LS_PLAN_TAX_AFFILIATOR];
GO
CREATE PROCEDURE [DBO].[SP_LS_PLAN_TAX_AFFILIATOR](@COD_AFFILIATOR INT)
AS
    BEGIN
        DECLARE @CATEGORY INT;
SELECT
	@CATEGORY = [COD_PLAN_CATEGORY]
FROM [PLAN_CATEGORY]
WHERE [CATEGORY] = 'AUTO CADASTRO';
SELECT
	[TYPE_PLAN].[CODE] AS [TYPE_PLAN]
   ,[PLAN].[COD_PLAN] AS [PLAN_INSIDECODE]
   ,[PLAN].[CODE] AS [NAME_PLAN]
   ,[TRANSACTION_TYPE].[COD_TTYPE] AS [TP_RATE_INSIDECODE]
   ,[TRANSACTION_TYPE].[CODE] AS [TYPE_RATE]
   ,[PLAN_TAX_AFFILIATOR].[QTY_INI_PLOTS]
   ,[PLAN_TAX_AFFILIATOR].[QTY_FINAL_PLOTS]
   ,[PLAN_TAX_AFFILIATOR].[PERCENTAGE]
   ,[PLAN_TAX_AFFILIATOR].[RATE]
   ,[PLAN_TAX_AFFILIATOR].[INTERVAL]
   ,[PLAN_TAX_AFFILIATOR].[EFFECTIVE_PERCENTAGE] AS [PERCENTAGE_EFFECTIVE]
   ,[PLAN_TAX_AFFILIATOR].[ANTICIPATION_PERCENTAGE] AS [ANTICIPATION]
   ,[PLAN_TAX_AFFILIATOR].COD_MODEL
   ,[BRAND].[COD_BRAND]
   ,[BRAND].[NAME] AS 'BRAND'
   ,[BRAND].[GROUP] AS 'GROUP_BRAND'
   ,[PLAN].[COD_BILLING]
   ,[PLAN].[DESCRIPTION] AS [PLAN_DESCRIPTION]
   ,[BILLING_TYPE].[DESCRIPTION] AS 'BILLING_TYPE'
   ,[SOURCE_TRANSACTION].[COD_SOURCE_TRAN]
   ,[SOURCE_TRANSACTION].[DESCRIPTION] AS 'TYPE_TAX'
FROM [PLAN_TAX_AFFILIATOR]
INNER JOIN [PLAN]
	ON [PLAN].[COD_PLAN] = [PLAN_TAX_AFFILIATOR].[COD_PLAN]
		AND [PLAN].[COD_PLAN_CATEGORY] <> @CATEGORY
INNER JOIN [TYPE_PLAN]
	ON [TYPE_PLAN].[COD_T_PLAN] = [PLAN].[COD_T_PLAN]
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].[COD_TTYPE] = [PLAN_TAX_AFFILIATOR].[COD_TTYPE]
INNER JOIN [AFFILIATOR]
	ON [AFFILIATOR].[COD_AFFILIATOR] = [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR]
LEFT JOIN [BRAND]
	ON [BRAND].[COD_BRAND] = [PLAN_TAX_AFFILIATOR].[COD_BRAND]
LEFT JOIN [BILLING_TYPE]
	ON [BILLING_TYPE].[COD_BILLING] = [PLAN].[COD_BILLING]
INNER JOIN [SOURCE_TRANSACTION]
	ON [SOURCE_TRANSACTION].[COD_SOURCE_TRAN] = [PLAN_TAX_AFFILIATOR].[COD_SOURCE_TRAN]
WHERE [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1
AND [AFFILIATOR].[COD_AFFILIATOR] = @COD_AFFILIATOR;
END;
GO

IF OBJECT_ID('SP_LS_PLAN_DEPARTS') IS NOT NULL
DROP PROCEDURE [SP_LS_PLAN_DEPARTS];
GO
CREATE PROCEDURE [dbo].[SP_LS_PLAN_DEPARTS]

/*------------------------------------A----------------------------------------------------              
Procedure Name: [SP_LS_PLAN_DEPARTS]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION        Date                            Description              
------------------------------------------------------------------------------------------              
Kennedy Alef                       V1           27/07/2018                     Creation              
Luiz Aquino                        V1           30/10/2018                     Add Plan description to the result              
------------------------------------------------------------------------------------------*/

(@COD_DEPART_BRANCH INT
)
AS
    BEGIN
SELECT
	TYPE_PLAN.CODE AS TYPE_PLAN
   ,[PLAN].COD_PLAN AS PLAN_INSIDECODE
   ,[PLAN].CODE AS NAME_PLAN
   ,TRANSACTION_TYPE.COD_TTYPE AS TP_RATE_INSIDECODE
   ,TRANSACTION_TYPE.CODE AS TYPE_RATE
   ,ASS_TAX_DEPART.QTY_INI_PLOTS
   ,ASS_TAX_DEPART.QTY_FINAL_PLOTS
   ,ASS_TAX_DEPART.PARCENTAGE
   ,ASS_TAX_DEPART.RATE
   ,ASS_TAX_DEPART.INTERVAL
   ,ASS_TAX_DEPART.EFFECTIVE_PERCENTAGE AS PERCENTAGE_EFFECTIVE
   ,ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE AS ANTICIPATION
   ,ASS_TAX_DEPART.COD_MODEL
   ,BRAND.COD_BRAND
   ,BRAND.[GROUP] AS 'BRAND'
   ,[PLAN].COD_BILLING
   ,BILLING_TYPE.[DESCRIPTION] AS 'BILLING_TYPE'
   ,[PLAN].[DESCRIPTION]
   ,SOURCE_TRANSACTION.COD_SOURCE_TRAN AS COD_TAX_TYPE
   ,SOURCE_TRANSACTION.[DESCRIPTION] AS 'TAX_TYPE'
FROM ASS_TAX_DEPART
INNER JOIN [PLAN]
	ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN
INNER JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH
INNER JOIN TYPE_PLAN
	ON TYPE_PLAN.COD_T_PLAN = DEPARTMENTS_BRANCH.COD_T_PLAN
INNER JOIN DEPARTMENTS
	ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
LEFT JOIN BRAND
	ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
LEFT JOIN BILLING_TYPE
	ON BILLING_TYPE.COD_BILLING = [PLAN].COD_BILLING
INNER JOIN SOURCE_TRANSACTION
	ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = ASS_TAX_DEPART.COD_SOURCE_TRAN
WHERE ASS_TAX_DEPART.ACTIVE = 1
AND DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = @COD_DEPART_BRANCH;
END;
GO


IF OBJECT_ID('SP_LS_PLAN_SEGMENTS_AFF') IS NOT NULL
DROP PROCEDURE SP_LS_PLAN_SEGMENTS_AFF;
GO
CREATE PROCEDURE [dbo].SP_LS_PLAN_SEGMENTS_AFF

/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_LS_PLAN_SEGMENTS]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Kennedy Alef     V1    27/07/2018      Creation        
------------------------------------------------------------------------------------------*/

(@CODCOMP        INT, 
 @COD_SEG        INT, 
 @TYPE_PLAN      INT, 
 @COD_AFFILIATOR INT          = NULL, 
 @COD_TYPE_PLAN  INT          = NULL, 
 @PREFIX         VARCHAR(255) = NULL
)
AS
    BEGIN
        DECLARE @QUERY NVARCHAR(MAX);

SET @QUERY = N'SELECT          
							COD_PLAN,        
							[PLAN].CODE AS NAME,        
							ACTIVE ,        
							TYPE_PLAN.CODE AS TYPE_PLAN        
						FROM [PLAN]         
						INNER JOIN TYPE_PLAN ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN        
							WHERE [PLAN].ACTIVE = 1 AND  [PLAN].COD_COMP = @CODCOMP';
        IF @TYPE_PLAN IS NOT NULL
SET @QUERY = @QUERY + ' AND TYPE_PLAN.COD_T_PLAN = @TYPE_PLAN';
IF @COD_SEG IS NOT NULL
SET @QUERY = @QUERY + ' AND [PLAN].COD_SEG = @COD_SEG';
IF @COD_AFFILIATOR IS NOT NULL
SET @QUERY = @QUERY + ' AND [PLAN].COD_AFFILIATOR = @COD_AFFILIATOR';
IF @PREFIX IS NOT NULL
SET @QUERY = @QUERY + ' AND [PLAN].CODE LIKE ''%'' + @PREFIX  + ''%'' ';

SET @QUERY = @QUERY + ' AND [PLAN].COD_PLAN_CATEGORY = 2 ORDER BY [PLAN].CODE ';
EXEC sp_executesql @QUERY
				  ,N'  
        	@CODCOMP INT,  
        	@COD_SEG INT,  
			@TYPE_PLAN INT,
        	@COD_AFFILIATOR INT,  
        	@COD_TYPE_PLAN INT, 
        	@PREFIX VARCHAR(255)
        '
				  ,@CODCOMP = @CODCOMP
				  ,@COD_SEG = @COD_SEG
				  ,@TYPE_PLAN = @TYPE_PLAN
				  ,@COD_AFFILIATOR = @COD_AFFILIATOR
				  ,@COD_TYPE_PLAN = @COD_TYPE_PLAN
				  ,@PREFIX = @PREFIX;
END;
GO


IF OBJECT_ID('SP_ASS_AFF_PLAN') IS NOT NULL
DROP PROCEDURE SP_ASS_AFF_PLAN;
GO
CREATE PROCEDURE [dbo].[SP_ASS_AFF_PLAN]

/*----------------------------------------------------------------------------------------  
Procedure Name: SP_ASS_DEPTO_PLAN  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                     Description  
------------------------------------------------------------------------------------------  
Kennedy Alef						V1			27/07/2018				Creation  
Luiz Aquino							v2			23/01/2019			Affiliated with multiple plans	
------------------------------------------------------------------------------------------*/

(@CODPLAN [CODE_TYPE] READONLY, 
 @COD_AFF INT, 
 @CODUSER INT
)
AS
     DECLARE @QTD INT;
    BEGIN
UPDATE PLAN_TAX_AFFILIATOR
SET ACTIVE = 0
WHERE COD_AFFILIATOR = @COD_AFF
AND COD_PLAN NOT IN (SELECT
		CODE
	FROM @CODPLAN);
DECLARE @DEFAULTPLAN INT;
SELECT TOP 1
	@DEFAULTPLAN = CODE
FROM @CODPLAN;
UPDATE AFFILIATOR
SET COD_PLAN = @DEFAULTPLAN
WHERE COD_AFFILIATOR = @COD_AFF;
SELECT DISTINCT
	COD_PLAN INTO #CURRENT_PLANS
FROM PLAN_TAX_AFFILIATOR
WHERE COD_AFFILIATOR = @COD_AFF;
SELECT
	CODE INTO #ADDED_PLANS
FROM @CODPLAN
WHERE CODE NOT IN (SELECT
		COD_PLAN
	FROM #CURRENT_PLANS);
INSERT INTO PLAN_TAX_AFFILIATOR (COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
[PERCENTAGE],
RATE,
INTERVAL,
COD_AFFILIATOR,
COD_USER,
COD_PLAN,
EFFECTIVE_PERCENTAGE,
ANTICIPATION_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	SELECT
		COD_TTYPE
	   ,QTY_INI_PLOTS
	   ,QTY_FINAL_PLOTS
	   ,PARCENTAGE
	   ,RATE
	   ,INTERVAL
	   ,@COD_AFF
	   ,@CODUSER
	   ,COD_PLAN
	   ,EFFECTIVE_PERCENTAGE
	   ,ANTICIPATION_PERCENTAGE
	   ,COD_BRAND
	   ,COD_SOURCE_TRAN SP_REG_AFFILIATOR
	   ,COD_MODEL
	FROM TAX_PLAN
	WHERE COD_PLAN IN (SELECT
			CODE
		FROM #ADDED_PLANS)
	AND TAX_PLAN.ACTIVE = 1;
IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER ASS_TAX_DEPART ', 1;
END;
GO

    

IF OBJECT_ID('SP_VALIDATE_AFFILIATED_EC_PLAN') IS NOT NULL
DROP PROCEDURE [SP_VALIDATE_AFFILIATED_EC_PLAN];
GO
CREATE PROCEDURE [DBO].[SP_VALIDATE_AFFILIATED_EC_PLAN]

/*************************************************************************************************************************      
----------------------------------------------------------------------------------------                                      
Procedure Name: [SP_VALIDATE_AFFILIATED_EC_PLAN]                                      
Project.......: TKPP                                      
                        
    Checks establishment Plan (PERCENTAGE, RATE, ANTICIPATION) against its Affiliated Plan                        
                        
------------------------------------------------------------------------------------------                                      
Author                          VERSION        Date                            Description                                      
------------------------------------------------------------------------------------------                                      
Luiz Aquino      V1     07/02/2019      Created                       
Luiz Aquino      V3    08/05/2019      Add Interval column          
------------------------------------------------------------------------------------------      
*************************************************************************************************************************/

(@PLAN_TAXES [PLAN_RATE] READONLY
)
AS
    BEGIN
        DECLARE @CATEGORY INT;
SELECT
	@CATEGORY = [COD_PLAN_CATEGORY]
FROM [PLAN_CATEGORY]
WHERE [CATEGORY] = 'AUTO CADASTRO';
SELECT
	'' AS [BRAND_EC]
   ,[PLAN_TAX_AFFILIATOR].[COD_BRAND]
   ,0 AS [INI_EC]
   ,[PLAN_TAX_AFFILIATOR].[QTY_INI_PLOTS]
   ,0 AS [FIN_EC]
   ,[PLAN_TAX_AFFILIATOR].[QTY_FINAL_PLOTS]
   ,0 AS [EC_ANTICIPATION]
   ,CASE
		WHEN [PLAN].[COD_T_PLAN] = 1 THEN 0
		ELSE [PLAN_TAX_AFFILIATOR].[ANTICIPATION_PERCENTAGE]
	END AS [AFF_ANTICIPATION]
   ,0 AS [EC_PERCENTAGE]
   ,[PLAN_TAX_AFFILIATOR].[PERCENTAGE] AS [AFF_PERCENTEGE]
   ,0 AS [EC_RATE]
   ,[PLAN_TAX_AFFILIATOR].[RATE] AS [AFF_RATE]
   ,'' AS [SOURCE_TYPE]
   ,[PLAN_TAX_AFFILIATOR].[COD_SOURCE_TRAN] AS [AFF_SOURCE_TYPE]
   ,[PLAN_TAX_AFFILIATOR].[INTERVAL] AS [AFF_INTERVAL]
   ,[PLAN_TAX_AFFILIATOR].COD_MODEL AS AFF_MODEL
FROM [PLAN_TAX_AFFILIATOR]
INNER JOIN @PLAN_TAXES AS [TAXES]
	ON [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR] = [TAXES].[COD_AFFILIATOR]
LEFT JOIN [PLAN]
	ON [PLAN].[COD_PLAN] = [TAXES].[COD_PLAN]
		AND [PLAN].[COD_PLAN_CATEGORY] <> @CATEGORY
		AND [PLAN].ACTIVE = 1
JOIN [PLAN] PLAN_AFF
	ON PLAN_AFF.COD_PLAN = [PLAN_TAX_AFFILIATOR].COD_PLAN
		AND PLAN_AFF.COD_PLAN_CATEGORY <> @CATEGORY
		AND [PLAN].ACTIVE = 1
WHERE [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1;
END;

GO

    
IF OBJECT_ID('SP_LS_MULTPLAN_AFFILIATOR') IS NOT NULL
DROP PROCEDURE [SP_LS_MULTPLAN_AFFILIATOR];
GO
CREATE PROCEDURE [dbo].[SP_LS_MULTPLAN_AFFILIATOR]

/*----------------------------------------------------------------------------------------            
Procedure Name: [SP_LS_MULTPLAN_AFFILIATOR]            
Project.......: TKPP            
---------------    
---------------------------------------------------------------------------            
Author                          VERSION        Date                            Description            
Luiz Aquino               V1      04/02/2019        Created            
LUCA    
S AGUIAR              V2      04/02/2019        add tipo de parametro            
LUCAS AGUIAR     V3      05/02/2019  Consultas din�mica - Cod aff          
------------------------------------------------------------------------------------------               
*/

@COD_AFFILIATOR INT, 
@TYPE_PLAN      INT = NULL
AS
     DECLARE @QUERY NVARCHAR(MAX);
    BEGIN
SET @QUERY = '            
SELECT          
 [PLAN].COD_PLAN          
   ,[PLAN].CODE AS NAME          
   ,[PLAN].ACTIVE          
   ,TYPE_PLAN    
.CODE AS TYPE_PLAN          
   ,[PLAN].COD_AFFILIATOR        
FROM [PLAN]          
INNER JOIN TYPE_PLAN          
 ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN          
 where COD_AFFILIATOR = @COD_AFFILIATOR  and COD_PLAN_CATEGORY <> 3  
';
        IF @TYPE_PLAN IS NOT NULL
SET @QUERY = @QUERY + ' and [PLAN].COD_T_PLAN = @TYPE_PLAN';
EXEC sp_executesql @QUERY
				  ,N'                             
   @COD_AFFILIATOR int,                                                                                                            
  @TYPE_PLAN     
int                                        
                         
   '
				  ,@TYPE_PLAN = @TYPE_PLAN
				  ,@COD_AFFILIATOR = @COD_AFFILIATOR;
END;

GO


IF OBJECT_ID('SP_VALIDATE_AFFILIATED_EC_PLAN') IS NOT NULL
DROP PROCEDURE [SP_VALIDATE_AFFILIATED_EC_PLAN];
GO
CREATE PROCEDURE [DBO].[SP_VALIDATE_AFFILIATED_EC_PLAN]

/*************************************************************************************************************************        
----------------------------------------------------------------------------------------                                        
Procedure Name: [SP_VALIDATE_AFFILIATED_EC_PLAN]                                        
Project.......: TKPP                                        
                          
    Checks establishment Plan (PERCENTAGE, RATE, ANTICIPATION) against its Affiliated Plan                          
                          
------------------------------------------------------------------------------------------                                        
Author                          VERSION        Date                            Description                                        
------------------------------------------------------------------------------------------                                        
Luiz Aquino      V1     07/02/2019      Created                         
Luiz Aquino      V3    08/05/2019      Add Interval column            
------------------------------------------------------------------------------------------        
*************************************************************************************************************************/

(@COD_AFF INT
--@PLAN_TAXES [PLAN_RATE] READONLY
)
AS
    BEGIN
        DECLARE @CATEGORY INT;
SELECT
	@CATEGORY = [COD_PLAN_CATEGORY]
FROM [PLAN_CATEGORY]
WHERE [CATEGORY] = 'AUTO CADASTRO';
SELECT
	'' AS [BRAND_EC]
   ,[PLAN_TAX_AFFILIATOR].[COD_BRAND]
   ,0 AS [INI_EC]
   ,[PLAN_TAX_AFFILIATOR].[QTY_INI_PLOTS]
   ,0 AS [FIN_EC]
   ,[PLAN_TAX_AFFILIATOR].[QTY_FINAL_PLOTS]
   ,0 AS [EC_ANTICIPATION]
   ,CASE
		WHEN PLAN_AFF.[COD_T_PLAN] = 1 THEN 0
		ELSE [PLAN_TAX_AFFILIATOR].[ANTICIPATION_PERCENTAGE]
	END AS [AFF_ANTICIPATION]
   ,0 AS [EC_PERCENTAGE]
   ,[PLAN_TAX_AFFILIATOR].[PERCENTAGE] AS [AFF_PERCENTEGE]
   ,0 AS [EC_RATE]
   ,[PLAN_TAX_AFFILIATOR].[RATE] AS [AFF_RATE]
   ,'' AS [SOURCE_TYPE]
   ,[PLAN_TAX_AFFILIATOR].[COD_SOURCE_TRAN] AS [AFF_SOURCE_TYPE]
   ,[PLAN_TAX_AFFILIATOR].[INTERVAL] AS [AFF_INTERVAL]
   ,[PLAN_TAX_AFFILIATOR].COD_MODEL AS AFF_MODEL
FROM [PLAN_TAX_AFFILIATOR]
JOIN [PLAN] PLAN_AFF
	ON PLAN_AFF.COD_PLAN = [PLAN_TAX_AFFILIATOR].COD_PLAN
		AND PLAN_AFF.COD_PLAN_CATEGORY <> @CATEGORY
		AND PLAN_AFF.ACTIVE = 1
WHERE [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1
AND PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = @COD_AFF;
END;
GO


IF OBJECT_ID('SP_VAL_TAX_AFF_EXP') IS NOT NULL
DROP PROCEDURE SP_VAL_TAX_AFF_EXP;
GO
CREATE PROCEDURE [dbo].[SP_VAL_TAX_AFF_EXP]
(@PERCENTAGE      DECIMAL(22, 6), 
 @RATE            DECIMAL(22, 6), 
 @ANTECIP         DECIMAL(22, 6), 
 @COD_BRAND       INT, 
 @COD_TTYPE       INT, 
 @COD_SOURCE_TRAN INT, 
 @COD_AFFILIATOR  INT, 
 @PLOT_INI        INT, 
 @PLOT_FINAL      INT, 
 @INTERVAL        INT, 
 @COD_MODEL       INT            = NULL
)
AS
    BEGIN
SELECT
	ASS_TAX_DEPART.PARCENTAGE
   ,ASS_TAX_DEPART.RATE
   ,ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE
   ,ASS_TAX_DEPART.INTERVAL
   ,COMMERCIAL_ESTABLISHMENT.TRADING_NAME
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,p.COD_T_PLAN
   ,ASS_TAX_DEPART.COD_MODEL INTO #Rates
FROM ASS_TAX_DEPART
INNER JOIN DEPARTMENTS_BRANCH
	ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
		AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1
INNER JOIN [PLAN] p
	ON ASS_TAX_DEPART.COD_PLAN = p.COD_PLAN
WHERE COD_BRAND = @COD_BRAND
AND COD_TTYPE = @COD_TTYPE
AND COD_SOURCE_TRAN = @COD_SOURCE_TRAN
AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFFILIATOR
AND ASS_TAX_DEPART.ACTIVE = 1
AND ((ASS_TAX_DEPART.COD_MODEL = @COD_MODEL
AND @COD_MODEL IS NOT NULL)
OR (ASS_TAX_DEPART.COD_MODEL IS NULL))
AND ((@PLOT_INI BETWEEN QTY_INI_PLOTS AND QTY_FINAL_PLOTS)
OR (@PLOT_FINAL BETWEEN QTY_INI_PLOTS AND QTY_FINAL_PLOTS));
SELECT
	'MDR' [Type]
   ,@PERCENTAGE [Value]
   ,'maior que do EC ' [Reason]
   ,r.PARCENTAGE [EC_VALUE]
   ,@PLOT_INI [RANGE_START]
   ,@PLOT_FINAL [RANGE_END]
   ,r.TRADING_NAME [ECNAME]
   ,r.CPF_CNPJ ECDOC
FROM #Rates r
WHERE r.PARCENTAGE < @PERCENTAGE
UNION
SELECT
	'Taxa' [Type]
   ,@RATE [Value]
   ,'maior que do EC ' [Reason]
   ,r.RATE [EC_VALUE]
   ,@PLOT_INI [RANGE_START]
   ,@PLOT_FINAL [RANGE_END]
   ,r.TRADING_NAME [ECNAME]
   ,r.CPF_CNPJ ECDOC
FROM #Rates r
WHERE r.RATE < @RATE
UNION
SELECT
	'Antecipação' [Type]
   ,@ANTECIP [Value]
   ,'maior que do EC ' [Reason]
   ,r.ANTICIPATION_PERCENTAGE [EC_VALUE]
   ,@PLOT_INI [RANGE_START]
   ,@PLOT_FINAL [RANGE_END]
   ,r.TRADING_NAME [ECNAME]
   ,r.CPF_CNPJ ECDOC
FROM #Rates r
WHERE r.ANTICIPATION_PERCENTAGE < @ANTECIP
AND r.COD_T_PLAN = 2
UNION
SELECT
	'Prazo' [Type]
   ,@INTERVAL [Value]
   ,'maior que do EC ' [Reason]
   ,r.INTERVAL [EC_VALUE]
   ,@PLOT_INI [RANGE_START]
   ,@PLOT_FINAL [RANGE_END]
   ,r.TRADING_NAME [ECNAME]
   ,r.CPF_CNPJ ECDOC
FROM #Rates r
WHERE r.INTERVAL < @INTERVAL
UNION
SELECT
	'Plano por terminal' [Type]
   ,@INTERVAL [Value]
   ,'O Ec possui um plano por terminal' [Reason]
   ,r.INTERVAL [EC_VALUE]
   ,@PLOT_INI [RANGE_START]
   ,@PLOT_FINAL [RANGE_END]
   ,r.TRADING_NAME [ECNAME]
   ,r.CPF_CNPJ ECDOC
FROM #Rates r
WHERE r.COD_MODEL IS NOT NULL
AND @COD_MODEL IS NULL
UNION
SELECT
	'Plano por terminal' [Type]
   ,@INTERVAL [Value]
   ,'O Ec não possui plano por terminal' [Reason]
   ,r.INTERVAL [EC_VALUE]
   ,@PLOT_INI [RANGE_START]
   ,@PLOT_FINAL [RANGE_END]
   ,r.TRADING_NAME [ECNAME]
   ,r.CPF_CNPJ ECDOC
FROM #Rates r
WHERE r.COD_MODEL IS NULL
AND @COD_MODEL IS NOT NULL;
END;
GO
IF OBJECT_ID('SP_LS_TX_PLAN_AFF') IS NOT NULL
DROP PROCEDURE SP_LS_TX_PLAN_AFF;
GO
CREATE PROCEDURE [dbo].[SP_LS_TX_PLAN_AFF]

/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_LS_TX_PLAN_AFF]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION   Date                            Description  
------------------------------------------------------------------------------------------  
Luiz Aquino      V1       26/09/2018      Creation  
Lucas Aguiar     V2    26/10/2018      Changed  
------------------------------------------------------------------------------------------*/

(@CODAFF INT
)
AS
    BEGIN
SELECT
	p.CODE AS PLANCODE
   ,tt.CODE AS [TYPE]
   ,tt.COD_TTYPE AS TYPETR_INSIDECODE
   ,pt.QTY_INI_PLOTS
   ,pt.QTY_FINAL_PLOTS
   ,pt.[PERCENTAGE]
   ,pt.RATE
   ,pt.INTERVAL
   ,pt.EFFECTIVE_PERCENTAGE AS PERCENTAGE_EFFECTIVE
   ,pt.ANTICIPATION_PERCENTAGE AS ANTICIPATION
   ,b.[NAME] AS 'BRAND'
   ,b.[GROUP] AS 'GROUP_BRAND'
   ,b.COD_BRAND
   ,pt.COD_MODEL
FROM AFFILIATOR a
JOIN [PLAN_TAX_AFFILIATOR] pt
	ON pt.COD_AFFILIATOR = a.COD_AFFILIATOR
		AND pt.COD_PLAN = a.COD_PLAN
INNER JOIN [PLAN] p
	ON p.COD_PLAN = pt.COD_PLAN
INNER JOIN TRANSACTION_TYPE tt
	ON tt.COD_TTYPE = pt.COD_TTYPE
LEFT JOIN BRAND b
	ON b.COD_BRAND = pt.COD_BRAND
WHERE a.COD_AFFILIATOR = @CODAFF
AND pt.ACTIVE = 1;
END;

GO


IF OBJECT_ID('SP_LS_TX_PLAN') IS NOT NULL
DROP PROCEDURE SP_LS_TX_PLAN;
GO
CREATE PROCEDURE [dbo].[SP_LS_TX_PLAN]

/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_LS_TX_PLAN]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Kennedy Alef     V1    27/07/2018      Creation        
Gian Luca Dalle Cort   V1    13/09/2018      Changed        
------------------------------------------------------------------------------------------*/

(@CODPLAN INT
)
AS
    BEGIN
SELECT
	[PLAN].CODE AS PLANCODE
   ,TRANSACTION_TYPE.CODE AS TYPE
   ,TRANSACTION_TYPE.COD_TTYPE AS TYPETR_INSIDECODE
   ,[TAX_PLAN].QTY_INI_PLOTS
   ,[TAX_PLAN].QTY_FINAL_PLOTS
   ,[TAX_PLAN].PARCENTAGE
   ,[TAX_PLAN].RATE
   ,[TAX_PLAN].INTERVAL
   ,[TAX_PLAN].EFFECTIVE_PERCENTAGE AS PERCENTAGE_EFFECTIVE
   ,[TAX_PLAN].ANTICIPATION_PERCENTAGE AS ANTICIPATION
   ,[TAX_PLAN].COD_MODEL
   ,BRAND.[GROUP] AS 'BRAND'
   ,BRAND.COD_BRAND
   ,SOURCE_TRANSACTION.COD_SOURCE_TRAN AS COD_TAX_TYPE
   ,SOURCE_TRANSACTION.DESCRIPTION AS 'TAX_TYPE'
   ,[PLAN].COD_T_PLAN
FROM [TAX_PLAN]
INNER JOIN [PLAN]
	ON [PLAN].COD_PLAN = [TAX_PLAN].COD_PLAN
INNER JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = [TAX_PLAN].COD_TTYPE
INNER JOIN SOURCE_TRANSACTION
	ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = TAX_PLAN.COD_SOURCE_TRAN
LEFT JOIN BRAND
	ON BRAND.COD_BRAND = TAX_PLAN.COD_BRAND
WHERE [PLAN].COD_PLAN = @CODPLAN
AND [TAX_PLAN].ACTIVE = 1;
END;

GO

/*

*********************** TESTES **********************

**/

----SELECT * FROM ASS_TAX_DEPART 
----JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN
----WHERE ASS_TAX_DEPART.ACTIVE=1 AND COD_MODEL IS NOT NULL
----GO
--SELECT TAX_PLAN.* FROM TAX_PLAN 
--JOIN [PLAN] ON [PLAN].COD_PLAN = TAX_PLAN.COD_PLAN
--WHERE TAX_PLAN.ACTIVE=1 AND [PLAN].COD_PLAN=5486
----GO
--EXEC SP_ASS_DEPTO_PLAN 5486, 10039,63
--GO
--EXEC SP_ASS_DEPTO_PLAN 5453, 10039,63

----GO
--EXEC SP_LOAD_TABLES_EQUIP 8467
--go
--select * from ASS_TAX_DEPART where active=1 and COD_DEPTO_BRANCH=10039
--go



--select * from VW_COMPANY_EC_BR_DEP_EQUIP_MODEL where COD_DEPTO_BR=10039

--go
--select top 100 * from [PLAN] ORDER BY 1 DESC
--go



--[SP_VALIDATE_TRANSACTION]
--@TERMINALID= 8467
--,@TYPETRANSACTION ='CREDIT'
--,@AMOUNT=200
--,@QTY_PLOTS=1
--,@PAN='64***6565'
--,@BRAND = 'MASTERCARD'
--,@TRCODE = '15911079591022656568'
--,@TERMINALDATE = NULL
--,@CODPROD_ACQ =1
--,@TYPE = 'TRANSACTION'
--,@COD_BRANCH=10045
--,@CODE_SPLIT = NULL
--,@COD_EC =10045
--,@HOLDER_NAME = 'KENNEDY ALEF DE OLIVEIRA'
--,@HOLDER_DOC = NULL
--,@LOGICAL_NUMBER = NULL
--,@COD_TRAN_PROD = NULL
--,@COD_EC_PRD = NULL

--GO

--SP_UP_TRANSACTION 
--@CODE_TRAN = '15911079591022656566'
--,@SITUATION = 'APPROVED'
--,@DESCRIPTION = '100-APROVADA'
--,@CURRENCY = NULL
--,@CODE_ERROR = NULL
--,@TRAN_ID = 4293175
--,@LOGICAL_NUMBER_ACQ = null
--,@CARD_HOLDER_NAME = ''
--,@COD_USER = null
--GO
--SP_UP_TRANSACTION 
--@CODE_TRAN = '15911079591022656566'
--,@SITUATION = 'CONFIRMED'
--,@DESCRIPTION = '200-CONFIRMADA'
--,@CURRENCY = NULL
--,@CODE_ERROR = NULL
--,@TRAN_ID = 4293175
--,@LOGICAL_NUMBER_ACQ = null
--,@CARD_HOLDER_NAME = ''
--,@COD_USER = null
--GO

--EXEC SP_GEN_TITLES_TRANS '15911079591022656566', 4293175
--GO
--SELECT * FROM [TRANSACTION_TITLES] WHERE COD_TRAN=4293175

--GO
--SELECT ASS_TAX_DEPART.* , BRAND.[NAME], EQUIPMENT_MODEL.CODIGO from ASS_TAX_DEPART
--JOIN BRAND ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
--JOIN EQUIPMENT_MODEL ON EQUIPMENT_MODEL.COD_MODEL  = ASS_TAX_DEPART.COD_MODEL
--WHERE COD_ASS_TX_DEP=686991
--GO
--UPDATE ASS_TAX_DEPART SET ACTIVE=1 WHERE COD_ASS_TX_DEP=686991

/*

*********************** FIM TESTES **********************

**/

GO
ALTER PROCEDURE [DBO].[SP_VALIDATE_TRANSACTION]                          
    
/***********************************************************************************************************************************************************************    
------------------------------------------------------------------------------------------------------------------------------------------------                          
Procedure Name: [SP_VALIDATE_TRANSACTION]                          
Project.......: TKPP                          
--------------------------------------------------------------------------------------------------------------------------------------------------                          
Author                          VERSION        Date                            Description                          
--------------------------------------------------------------------------------------------------------------------------------------------------                          
Kennedy Alef     V1   27/07/2018       Creation                          
Gian Luca Dalle Cort   V1   14/08/2018        Changed          
Lucas Aguiar     v3   17-04-2019    Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções            
Lucas Aguiar     v4   23-04-2019    Parametro opc cod ec      
Kennedy Alef  v5   12-11-2019    Card holder name, doc holder, logical number                       
--------------------------------------------------------------------------------------------------------------------------------------------------    
***********************************************************************************************************************************************************************/    
                                   
(    
 @TERMINALID      INT,     
 @TYPETRANSACTION VARCHAR(100),     
 @AMOUNT          DECIMAL(22, 6),     
 @QTY_PLOTS       INT,     
 @PAN             VARCHAR(100),     
 @BRAND           VARCHAR(200),     
 @TRCODE          VARCHAR(200),     
 @TERMINALDATE    DATETIME,     
 @CODPROD_ACQ     INT,     
 @TYPE            VARCHAR(100),     
 @COD_BRANCH      INT,     
 @CODE_SPLIT      INT            = NULL,     
 @COD_EC          INT            = NULL,     
 @HOLDER_NAME     VARCHAR(100)   = NULL,     
 @HOLDER_DOC      VARCHAR(100)   = NULL,     
 @LOGICAL_NUMBER  VARCHAR(100)   = NULL,     
 @COD_TRAN_PROD   INT            = NULL,  
 @COD_EC_PRD   INT    = NULL)    
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
  
    
    
    DECLARE @BRANCH INT= 0;
  
    
    
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
								,@COMMENT = '402 - Transaction limit value exceeded"d'
								,@TERMINALDATE = @TERMINALDATE
								,@TYPE = @TYPE
								,@COD_COMP = @COD_COMP
								,@COD_AFFILIATOR = @COD_AFFILIATOR
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
THROW 60002, '402', 1;

END;

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
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
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
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
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
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
THROW 60002, '003', 1;

END;

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
								,@SOURCE_TRAN = 2
								,@CODE_SPLIT = @CODE_SPLIT
								,@COD_EC = @EC_TRANS
								,@HOLDER_NAME = @HOLDER_NAME
								,@HOLDER_DOC = @HOLDER_DOC
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
THROW 60002, '009', 1;

END;

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
					  ,@CODE_SPLIT = @CODE_SPLIT
					  ,@EC_TRANS = @EC_TRANS
					  ,@HOLDER_NAME = @HOLDER_NAME
					  ,@HOLDER_DOC = @HOLDER_DOC
					  ,@LOGICAL_NUMBER = @LOGICAL_NUMBER
					  ,@SOURCE_TRAN = 2;



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
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
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
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
THROW 60002, '012', 1;
END;


IF @COD_TRAN_PROD IS NOT NULL
BEGIN

EXEC [SP_VAL_SPLIT_MULT_EC] @COD_TRAN_PROD = @COD_TRAN_PROD
						   ,@COD_EC = @EC_TRANS
						   ,@QTY_PLOTS = @QTY_PLOTS
						   ,@BRAND = @BRAND
						   ,@COD_ERROR = @COD_ERROR OUTPUT
						   ,@ERROR_DESCRIPTION = @ERROR_DESCRIPTION OUTPUT;

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
								,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
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

SELECT
	@CODAC AS [ACQUIRER]
   ,@TRCODE AS [TRAN_CODE]
   ,@CODTR_RETURN AS [COD_TRAN];


END;
END;

GO

    
ALTER PROCEDURE [dbo].[SP_ASS_DEPTO_PLAN]      
/*----------------------------------------------------------------------------------------      
Procedure Name: SP_ASS_DEPTO_PLAN      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Kennedy Alef     V1    27/07/2018      Creation      
Gian Luca Dalle Cort   V1    13/09/2018      Changed      
------------------------------------------------------------------------------------------*/      
(      
@CODPLAN INT,      
@COD_DEPTO_BRANCH INT,      
@CODUSER INT)      
AS      
DECLARE @QTD INT;
  
      
DECLARE @TP_PLAN INT;
  
BEGIN

UPDATE ASS_TAX_DEPART
SET ACTIVE = 0
WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH
AND ACTIVE = 1

SELECT
	@TP_PLAN = COD_T_PLAN
FROM [PLAN]
WHERE COD_PLAN = @CODPLAN;

UPDATE DEPARTMENTS_BRANCH
SET COD_PLAN = @CODPLAN
   ,COD_T_PLAN = @TP_PLAN
WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH

INSERT INTO ASS_TAX_DEPART (COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
PARCENTAGE,
RATE,
INTERVAL,
COD_DEPTO_BRANCH,
COD_USER,
COD_PLAN,
EFFECTIVE_PERCENTAGE,
ANTICIPATION_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	SELECT
		COD_TTYPE
	   ,QTY_INI_PLOTS
	   ,QTY_FINAL_PLOTS
	   ,PARCENTAGE
	   ,RATE
	   ,INTERVAL
	   ,@COD_DEPTO_BRANCH
	   ,@CODUSER
	   ,@CODPLAN
	   ,EFFECTIVE_PERCENTAGE
	   ,ANTICIPATION_PERCENTAGE
	   ,COD_BRAND
	   ,COD_SOURCE_TRAN
	   ,COD_MODEL
	FROM TAX_PLAN
	WHERE COD_PLAN = @CODPLAN
	AND TAX_PLAN.ACTIVE = 1


IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER ASS_TAX_DEPART ', 1;

END;

GO

  

IF OBJECT_ID('MIGRATION_PLANS') IS NOT NULL
DROP TABLE MIGRATION_PLANS;
GO

CREATE TABLE MIGRATION_PLANS
(COD_MIGRATION_PLANS INT IDENTITY, 
 ACTIVE              INT NOT NULL, 
 COD_AFFILIATOR      INT NOT NULL, 
 PROCESSED           INT DEFAULT 0 NOT NULL, 
 CREATED_AT          DATETIME DEFAULT DBO.FN_FUS_UTF(GETDATE()) NOT NULL, 
 MODIFY_DATE         DATETIME NULL, 
 COD_USER            INT NOT NULL, 
 COD_MODIFY_USER     INT NULL, 
 FOREIGN KEY(COD_AFFILIATOR) REFERENCES AFFILIATOR(COD_AFFILIATOR), 
 FOREIGN KEY(COD_USER) REFERENCES USERS(COD_USER), 
 FOREIGN KEY(COD_MODIFY_USER) REFERENCES USERS(COD_USER)
);
GO

IF OBJECT_ID('SP_REG_MIGRATION_PLANS') IS NOT NULL
DROP PROCEDURE SP_REG_MIGRATION_PLANS;
GO

CREATE PROCEDURE SP_REG_MIGRATION_PLANS
(@COD_AFF   INT, 
 @COD_USER  INT, 
 @SOLICITED INT
)
AS
    BEGIN
	   DECLARE @ATUAL INT= NULL;

SELECT
	@ATUAL = ACTIVE
FROM MIGRATION_PLANS
WHERE COD_AFFILIATOR = @COD_AFF;

IF @ATUAL IS NOT NULL
	AND @ATUAL <> @SOLICITED
BEGIN

UPDATE MIGRATION_PLANS
SET ACTIVE = @SOLICITED
   ,MODIFY_DATE = DBO.FN_FUS_UTF(GETDATE())
   ,COD_MODIFY_USER = @COD_USER
WHERE COD_AFFILIATOR = @COD_AFF;
END;

IF @ATUAL IS NULL
BEGIN

INSERT INTO MIGRATION_PLANS (COD_AFFILIATOR,
COD_USER,
ACTIVE)
	VALUES (@COD_AFF, @COD_USER, @SOLICITED);
END;
END;

GO



IF OBJECT_ID('SP_LS_PLAN_TAX_AFFILIATOR') IS NOT NULL
DROP PROCEDURE SP_LS_PLAN_TAX_AFFILIATOR;
GO

CREATE PROCEDURE DBO.SP_LS_PLAN_TAX_AFFILIATOR(@COD_AFFILIATOR INT)
AS
    BEGIN
	   DECLARE @CATEGORY INT;

SELECT
	@CATEGORY = COD_PLAN_CATEGORY
FROM PLAN_CATEGORY
WHERE CATEGORY = 'AUTO CADASTRO';

SELECT
	TYPE_PLAN.CODE AS TYPE_PLAN
   ,[PLAN].COD_PLAN AS PLAN_INSIDECODE
   ,[PLAN].CODE AS NAME_PLAN
   ,TRANSACTION_TYPE.COD_TTYPE AS TP_RATE_INSIDECODE
   ,TRANSACTION_TYPE.CODE AS TYPE_RATE
   ,PLAN_TAX_AFFILIATOR.QTY_INI_PLOTS
   ,PLAN_TAX_AFFILIATOR.QTY_FINAL_PLOTS
   ,PLAN_TAX_AFFILIATOR.PERCENTAGE
   ,PLAN_TAX_AFFILIATOR.RATE
   ,PLAN_TAX_AFFILIATOR.INTERVAL
   ,PLAN_TAX_AFFILIATOR.EFFECTIVE_PERCENTAGE AS PERCENTAGE_EFFECTIVE
   ,PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE AS ANTICIPATION
   ,PLAN_TAX_AFFILIATOR.COD_MODEL
   ,BRAND.COD_BRAND
   ,BRAND.NAME AS 'BRAND'
   ,BRAND.[GROUP] AS 'GROUP_BRAND'
   ,[PLAN].COD_BILLING
   ,[PLAN].DESCRIPTION AS PLAN_DESCRIPTION
   ,BILLING_TYPE.DESCRIPTION AS 'BILLING_TYPE'
   ,SOURCE_TRANSACTION.COD_SOURCE_TRAN
   ,SOURCE_TRANSACTION.DESCRIPTION AS 'TYPE_TAX'
   ,ISNULL(MIGRATION_PLANS.ACTIVE, 0) AS SOLICITED_MIGRATION
FROM PLAN_TAX_AFFILIATOR
INNER JOIN [PLAN]
	ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN
		AND [PLAN].COD_PLAN_CATEGORY <> @CATEGORY
INNER JOIN TYPE_PLAN
	ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN
INNER JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = PLAN_TAX_AFFILIATOR.COD_TTYPE
INNER JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = PLAN_TAX_AFFILIATOR.COD_AFFILIATOR
LEFT JOIN BRAND
	ON BRAND.COD_BRAND = PLAN_TAX_AFFILIATOR.COD_BRAND
LEFT JOIN BILLING_TYPE
	ON BILLING_TYPE.COD_BILLING = [PLAN].COD_BILLING
INNER JOIN SOURCE_TRANSACTION
	ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = PLAN_TAX_AFFILIATOR.COD_SOURCE_TRAN
LEFT JOIN MIGRATION_PLANS
	ON MIGRATION_PLANS.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
		AND MIGRATION_PLANS.PROCESSED = 0
WHERE PLAN_TAX_AFFILIATOR.ACTIVE = 1
AND AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATOR;
END;

GO

IF OBJECT_ID('SP_LS_AFF_MIGRATE') IS NOT NULL
DROP PROCEDURE SP_LS_AFF_MIGRATE;
GO
CREATE PROCEDURE SP_LS_AFF_MIGRATE
AS
    BEGIN
SELECT
	COD_AFFILIATOR
FROM MIGRATION_PLANS
WHERE PROCESSED = 0
AND ACTIVE = 1;
END;

GO




IF OBJECT_ID('SP_MIGRATE_PLAN_TERMINAL') IS NOT NULL
DROP PROCEDURE SP_MIGRATE_PLAN_TERMINAL;
GO

CREATE PROCEDURE SP_MIGRATE_PLAN_TERMINAL(@COD_AFF INT)
AS
    BEGIN
	   DECLARE @COD_USER INT= NULL;

SELECT
	@COD_USER = IIF(MIGRATION_PLANS.COD_MODIFY_USER IS NULL, MIGRATION_PLANS.COD_USER, MIGRATION_PLANS.COD_MODIFY_USER)
FROM MIGRATION_PLANS
WHERE COD_AFFILIATOR = @COD_AFF
AND PROCESSED = 0
AND ACTIVE = 1;

DECLARE @COD_MODEL INT;

DECLARE CURSOR_TERMINAL CURSOR FOR SELECT
	COD_MODEL
FROM EQUIPMENT_MODEL
WHERE TIPO = 'MPOS';

OPEN CURSOR_TERMINAL;

FETCH NEXT FROM CURSOR_TERMINAL INTO @COD_MODEL;

WHILE @@fetch_status = 0
BEGIN
-- plano cadastrado
INSERT INTO TAX_PLAN (COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
PARCENTAGE,
RATE,
INTERVAL,
ACTIVE,
COD_PLAN,
ANTICIPATION_PERCENTAGE,
EFFECTIVE_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	SELECT
		TAX_PLAN.COD_TTYPE
	   ,TAX_PLAN.QTY_INI_PLOTS
	   ,TAX_PLAN.QTY_FINAL_PLOTS
	   ,TAX_PLAN.PARCENTAGE
	   ,TAX_PLAN.RATE
	   ,TAX_PLAN.INTERVAL
	   ,TAX_PLAN.ACTIVE
	   ,TAX_PLAN.COD_PLAN
	   ,TAX_PLAN.ANTICIPATION_PERCENTAGE
	   ,TAX_PLAN.EFFECTIVE_PERCENTAGE
	   ,TAX_PLAN.COD_BRAND
	   ,TAX_PLAN.COD_SOURCE_TRAN
	   ,@COD_MODEL
	FROM TAX_PLAN
	JOIN [PLAN] P
		ON P.COD_PLAN = TAX_PLAN.COD_PLAN
			AND (P.COD_PLAN_OPT <> 3
				OR P.COD_PLAN_OPT IS NULL)
			AND P.COD_AFFILIATOR = @COD_AFF
			AND P.ACTIVE = 1
	WHERE TAX_PLAN.ACTIVE = 1
	AND COD_MODEL IS NULL
	AND TAX_PLAN.COD_SOURCE_TRAN = 2;
-- plano ec

INSERT INTO ASS_TAX_DEPART (CREATED_AT,
COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
PARCENTAGE,
RATE,
INTERVAL,
COD_USER,
ACTIVE,
COD_DEPTO_BRANCH,
COD_PLAN,
ANTICIPATION_PERCENTAGE,
EFFECTIVE_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	SELECT
		GETDATE()
	   ,ASS_TAX_DEPART.COD_TTYPE
	   ,ASS_TAX_DEPART.QTY_INI_PLOTS
	   ,ASS_TAX_DEPART.QTY_FINAL_PLOTS
	   ,ASS_TAX_DEPART.PARCENTAGE
	   ,ASS_TAX_DEPART.RATE
	   ,ASS_TAX_DEPART.INTERVAL
	   ,@COD_USER
	   ,ASS_TAX_DEPART.ACTIVE
	   ,ASS_TAX_DEPART.COD_DEPTO_BRANCH
	   ,ASS_TAX_DEPART.COD_PLAN
	   ,ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE
	   ,ASS_TAX_DEPART.EFFECTIVE_PERCENTAGE
	   ,ASS_TAX_DEPART.COD_BRAND
	   ,ASS_TAX_DEPART.COD_SOURCE_TRAN
	   ,@COD_MODEL
	FROM ASS_TAX_DEPART
	JOIN [PLAN]
		ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN
			AND [PLAN].COD_AFFILIATOR = @COD_AFF
			AND ([PLAN].COD_PLAN_OPT <> 3
				OR [PLAN].COD_PLAN_OPT IS NULL)
			AND [PLAN].ACTIVE = 1
	WHERE ASS_TAX_DEPART.ACTIVE = 1
	AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 2
	AND COD_MODEL IS NULL;
-- plano aff

INSERT INTO PLAN_TAX_AFFILIATOR (CREATED_AT,
COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
PERCENTAGE,
RATE,
INTERVAL,
COD_USER,
ACTIVE,
COD_PLAN,
COD_AFFILIATOR,
ANTICIPATION_PERCENTAGE,
EFFECTIVE_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	SELECT
		GETDATE()
	   ,COD_TTYPE
	   ,QTY_INI_PLOTS
	   ,QTY_FINAL_PLOTS
	   ,PERCENTAGE
	   ,RATE
	   ,INTERVAL
	   ,@COD_USER
	   ,ACTIVE
	   ,COD_PLAN
	   ,COD_AFFILIATOR
	   ,ANTICIPATION_PERCENTAGE
	   ,EFFECTIVE_PERCENTAGE
	   ,COD_BRAND
	   ,COD_SOURCE_TRAN
	   ,@COD_MODEL
	FROM PLAN_TAX_AFFILIATOR
	WHERE COD_AFFILIATOR = @COD_AFF
	AND ACTIVE = 1
	AND COD_MODEL IS NULL
	AND COD_SOURCE_TRAN = 2;

FETCH NEXT FROM CURSOR_TERMINAL INTO @COD_MODEL;
END;

CLOSE CURSOR_TERMINAL;

DEALLOCATE CURSOR_TERMINAL;

UPDATE [PLAN]
SET COD_PLAN_OPT = 3
   ,MODIFY_DATE = GETDATE()
   ,COD_USER_MODIFY = @COD_USER
FROM [PLAN]
WHERE COD_PLAN_OPT IS NULL
AND COD_AFFILIATOR = @COD_AFF
AND ACTIVE = 1;

UPDATE TAX_PLAN
SET ACTIVE = 0
FROM TAX_PLAN
JOIN [PLAN]
	ON [PLAN].COD_PLAN = TAX_PLAN.COD_PLAN
WHERE TAX_PLAN.ACTIVE = 1
AND COD_AFFILIATOR = @COD_AFF
AND COD_SOURCE_TRAN = 2
AND COD_MODEL IS NULL;

UPDATE ASS_TAX_DEPART
SET ACTIVE = 0
   ,MODIFY_DATE = GETDATE()
FROM ASS_TAX_DEPART
JOIN [PLAN]
	ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN
WHERE ASS_TAX_DEPART.ACTIVE = 1
AND COD_AFFILIATOR = @COD_AFF
AND COD_SOURCE_TRAN = 2
AND COD_MODEL IS NULL;

UPDATE PLAN_TAX_AFFILIATOR
SET ACTIVE = 0
FROM PLAN_TAX_AFFILIATOR
JOIN [PLAN]
	ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN
WHERE PLAN_TAX_AFFILIATOR.ACTIVE = 1
AND PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = @COD_AFF
AND COD_SOURCE_TRAN = 2
AND COD_MODEL IS NULL;

UPDATE MIGRATION_PLANS
SET PROCESSED = 1
WHERE COD_AFFILIATOR = @COD_AFF
AND PROCESSED = 0;
END;
GO



IF OBJECT_ID('[SP_ADD_TAX_PLAN_AFFILIATOR]') IS NOT NULL
DROP PROCEDURE [SP_ADD_TAX_PLAN_AFFILIATOR];
GO
CREATE PROCEDURE [dbo].[SP_ADD_TAX_PLAN_AFFILIATOR]    
        
/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_DISABLE_TX_DEPTO_PLAN]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Gian Luca Dalle Cort   V1      01/10/2018      Creation        
------------------------------------------------------------------------------------------*/        
        
(          
@COD_TTYPE INT,          
@QTY_INI_PLOTS INT ,          
@QTY_FINAL_PLOTS INT,          
@PARCENTAGE DECIMAL(22,6),          
@RATE DECIMAL(22,6),          
@INTERVAL INT,          
@COD_AFFILIATOR INT,          
@CODUSER INT,          
@ANTICIPATION DECIMAL(22,6),          
@PERCENTAGE_EFFECTIVE DECIMAL(22,6),          
@COD_PLAN INT,          
@COD_BRAND INT = NULL,        
@COD_SOURCE_TRAN INT = 2,  
@COD_MODEL int = null  
)          
AS          
DECLARE @QTD INT;
  
    
          
BEGIN

UPDATE AFFILIATOR
SET COD_PLAN = @COD_PLAN
WHERE COD_AFFILIATOR = @COD_AFFILIATOR

INSERT INTO PLAN_TAX_AFFILIATOR (COD_TTYPE,
QTY_INI_PLOTS,
QTY_FINAL_PLOTS,
[PERCENTAGE],
RATE,
INTERVAL,
COD_AFFILIATOR,
COD_USER,
COD_PLAN,
EFFECTIVE_PERCENTAGE,
ANTICIPATION_PERCENTAGE,
COD_BRAND,
COD_SOURCE_TRAN,
COD_MODEL)
	VALUES (@COD_TTYPE, @QTY_INI_PLOTS, @QTY_FINAL_PLOTS, @PARCENTAGE, @RATE, @INTERVAL, @COD_AFFILIATOR, @CODUSER, @COD_PLAN, @PERCENTAGE_EFFECTIVE, @ANTICIPATION, @COD_BRAND, @COD_SOURCE_TRAN, @COD_MODEL);


IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER PLAN_TAX_AFFILIATOR ', 1;

END;

GO



IF OBJECT_ID('SP_SELF_REG_COMMERCIAL') IS NOT NULL DROP PROCEDURE SP_SELF_REG_COMMERCIAL;
GO
CREATE PROCEDURE [DBO].[SP_SELF_REG_COMMERCIAL]
/***************************************************************************************************************************************************    
----------------------------------------------------------------------------------------                                                   
    Procedure Name: [SP_SELF_REG_COMMERCIAL]                                                  
    Project.......: TKPP                                                   
    ------------------------------------------------------------------------------------------                                                   
    Author                          VERSION        Date                            Description                                                          
    ------------------------------------------------------------------------------------------                                                   
    Lucas Aguiar                       V1        2019-10-28                          Creation           
 Caike Uchôa                        V2        2020-07-10                       add service Risk  
    ------------------------------------------------------------------------------------------        
***************************************************************************************************************************************************/
(        
-- informations about commercial establishments                                       
@ACCESS_KEY          VARCHAR(300), 
@COD_AFFILIATOR      INT, 
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
@DOCUMENT_TYPE       VARCHAR(10),        
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
@NAME_USER           VARCHAR(255), 
@EMAIL               VARCHAR(255), 
@TEMP_PASS           VARCHAR(200), 
@TP_CONTACT          [TP_CONTACT_LIST] READONLY, 
@TP_DOCUMENT         [TP_DOCUMENT_LIST] READONLY, 
@TP_MEET_COSTUMER    [TP_MEET_COSTUMER] READONLY
)
AS
    BEGIN

	   DECLARE @COD_SALES_REP INT= NULL;

	   DECLARE @SEQ INT;

	   DECLARE @TRANSACTION_LIMIT DECIMAL(22, 8)= NULL;

	   DECLARE @TRANSACTION_DAILY DECIMAL(22, 8)= NULL;

	   DECLARE @TRANSACTION_MOUNTH DECIMAL(22, 8)= NULL;

	   DECLARE @COD_RISK_SIT INT= NULL;

	   DECLARE @COD_USER INT= NULL;

	   DECLARE @ID_EC INT;

	   DECLARE @ID_BR INT;

	   DECLARE @ID_DEPART INT;

	   DECLARE @ID_USER INT;

	   DECLARE @ID_ORDER_ADDR INT;

	   DECLARE @ID_TRAN INT= NULL;

	   DECLARE @TP_PLAN INT= NULL;

	   DECLARE @ID_ORDER INT;

	   DECLARE @COUNT_USER INT= 0;

	   DECLARE @CONT INT= 0;

SELECT
	@CONT = COUNT(*)
FROM [COMMERCIAL_ESTABLISHMENT]
WHERE [COD_COMP] = @COD_COMP
AND [CPF_CNPJ] = @CPF_CNPJ
AND ([COD_AFFILIATOR] = @COD_AFFILIATOR
OR @COD_AFFILIATOR IS NULL)
AND [ACTIVE] = 1;

IF ((SELECT
			COUNT(*)
		FROM [USERS]
		WHERE [COD_ACCESS] = @USERNAME
		AND [ACTIVE] = 1)
	> 0)
THROW 70001, 'ACCESS USER ALREADY REGISTERED. Parameter name: 70001', 1;

IF ((SELECT
			COUNT(*)
		FROM [USERS]
		WHERE [EMAIL] = @EMAIL
		AND [COD_AFFILIATOR] = @COD_AFFILIATOR
		AND [ACTIVE] = 1)
	> 0)
THROW 70002, 'EMAIL ALREADY REGISTERED. Parameter name: 70002', 1;

IF (@CONT > 0)
THROW 70003, 'EC ALREADY REGISTERED. Parameter name: 70003', 1;

IF @CONT = 0
BEGIN
SELECT TOP 1
	@COD_SALES_REP = [COD_SALES_REP]
FROM [SALES_REPRESENTATIVE]
WHERE [DEFAULT_SR] = 1
AND [ACTIVE] = 1;

IF @COD_SALES_REP IS NULL
THROW 70004, 'INVALID SALES REPRESENTATIVE. Parameter name: 70004', 1;
-- SEGUIMENTO PADRÃO PARA PESSOA FÍSICA                                                  
IF @COD_TYPE_EC = 3
SET @COD_SEGMENT = 507;

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
WHERE [COD_ACCESS] = 'AUTO_CADASTRO';

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
[COD_BRANCH_BUSINESS],
[IS_SELF_REG],
[TCU_ACCEPTED])
	VALUES (@SEQ, @NAME, @TRADING_NAME, @CPF_CNPJ, @RG, @DOCUMENT_TYPE, @EC_EMAIL, @STATE_REG, @MUN_REG, @COD_SEGMENT, @TRANSACTION_LIMIT, @TRANSACTION_DAILY, @TRANSACTION_MOUNTH, @BIRTHDATE, @COD_COMP, @COD_TYPE_EC, 0, @COD_SEX, @COD_AFFILIATOR, 1, @COD_SALES_REP, 1, (SELECT [COD_SITUATION] FROM [SITUATION] WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE'), @COD_USER, 0, @COD_BRANCH_BUSINESS, 1, 1);

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
	WHERE [BANKS].[COD_BANK] = @BANKCODE;

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
[COD_SOURCE_TRAN],
COD_MODEL)
	SELECT
		[COD_TTYPE]
	   ,[QTY_INI_PLOTS]
	   ,[QTY_FINAL_PLOTS]
	   ,[PERCENTAGE]
	   ,[RATE]
	   ,[INTERVAL]
	   ,@ID_DEPART
	   ,@COD_USER
	   ,@COD_PLAN
	   ,[EFFECTIVE_PERCENTAGE]
	   ,[ANTICIPATION_PERCENTAGE]
	   ,[COD_BRAND]
	   ,[COD_SOURCE_TRAN]
	   ,COD_MODEL
	FROM [PLAN_TAX_AFFILIATOR]
	WHERE [COD_PLAN] = @COD_PLAN
	AND [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1;

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
[ACCEPT],
[FIRST_LOGIN_DATE])
	VALUES (@USERNAME, @CPF_CNPJ, @NAME_USER, @EMAIL, 0, @COD_COMP, 2, @ID_EC, @EMAIL, 11, @COD_SEX, @COD_AFFILIATOR, 1, current_timestamp);

IF @@rowcount < 1
THROW 70016, 'COULD NOT REGISTER USERS. Parameter name: 70016', 1;

SET @ID_USER = SCOPE_IDENTITY();

EXEC [SP_REG_PROV_PASS_USER] @USERNAME
							,@ACCESS_KEY
							,@TEMP_PASS
							,1
							,@COD_AFFILIATOR;

EXEC [SP_REG_ASS_EC_LOCK] @COD_EC = @ID_EC
						 ,@CPF_CNPJ = @CPF_CNPJ;

IF @COD_AFFILIATOR = 35
INSERT INTO [ASS_EC_EXTERNAL_API] ([COD_EC],
[DESCRIPTION])
	VALUES (@ID_EC, 'API PEDIJA');
END;

SELECT
	@ID_USER = [COD_USER]
FROM [USERS]
WHERE [COD_ACCESS] = @USERNAME;

SELECT
	@ID_EC = [COD_EC]
FROM [COMMERCIAL_ESTABLISHMENT]
WHERE [COD_COMP] = @COD_COMP
AND [CPF_CNPJ] = @CPF_CNPJ
AND ([COD_AFFILIATOR] = @COD_AFFILIATOR
OR @COD_AFFILIATOR IS NULL);

IF (SELECT
			COUNT(*)
		FROM @TP_MEET_COSTUMER)
	> 0
BEGIN

INSERT INTO [MEET_COSTUMER] ([COD_EC],
[QTY_EMPLOYEES],
[AVERAGE_BILLING],
[URL_SITE],
[INSTAGRAM],
[FACEBOOK],
[COD_NEIGH],
[STREET],
[NUMBER],
[COMPLEMENT],
[ANOTHER_INFO],
[CNPJ])
	SELECT
		@ID_EC
	   ,[QTY_EMPLOYEES]
	   ,[AVERAGE_BILLING]
	   ,[URL_SITE]
	   ,[INSTAGRAM]
	   ,[FACEBOOK]
	   ,[COD_NEIGH]
	   ,[STREET]
	   ,[NUMBER]
	   ,[COMPLEMENT]
	   ,[ANOTHER_INFO]
	   ,[CNPJ]
	FROM @TP_MEET_COSTUMER;

IF @@rowcount < (SELECT
			COUNT(*)
		FROM @TP_MEET_COSTUMER)
THROW 70020, 'COULD NOT REGISTER [MEET_COSTUMER]. Parameter name: 70020', 1;
END;
-- BEGIN > Scheduling risk research         
DECLARE @COD_RESEARCH_RISK_TYPE INT;
SET @COD_RESEARCH_RISK_TYPE = (SELECT TOP 1
		[RESEARCH_RISK_TYPE].[COD_RESEARCH_RISK_TYPE]
	FROM [RESEARCH_RISK_TYPE]
	WHERE [RESEARCH_RISK_TYPE].[CODE] = 'INITIAL'
	AND [RESEARCH_RISK_TYPE].[DOCUMENT_TYPE] = @DOCUMENT_TYPE
	AND [RESEARCH_RISK_TYPE].[ACTIVE] = 1);
INSERT INTO [RESEARCH_RISK] ([COD_EC],
[COD_USER],
[COD_RESEARCH_RISK_TYPE],
[COD_STATUS])
	VALUES (@ID_EC, @COD_USER, @COD_RESEARCH_RISK_TYPE, 0);
-- BEGIN > Scheduling risk research         
-- FIM --   
END;

GO

DROP PROCEDURE [SP_REG_TAX_PLAN_SELF_REG];

GO

DROP TYPE [TP_PLAN_TAX_SELF_REG];

GO

CREATE TYPE [DBO].[TP_PLAN_TAX_SELF_REG] AS TABLE
([COD_TRAN_TYPE] [INT] NULL, 
 [QTY_INI_PL]    [INT] NULL, 
 [QTY_FINAL_FL]  [INT] NULL, 
 [PERCENT]       [DECIMAL](22, 6) NULL, 
 [RATE]          [DECIMAL](22, 6) NULL, 
 [INTERVAL]      [INT] NULL, 
 [CODPLAN]       [INT] NULL, 
 [ANTICIPATION]  [DECIMAL](22, 6) NULL, 
 [COD_BRAND]     [INT] NULL, 
 [COD_TAX_TYPE]  [INT] NULL, 
 COD_MODEL       [INT] NULL
);
GO

GO

CREATE PROCEDURE [DBO].[SP_REG_TAX_PLAN_SELF_REG]
(@RATES          [TP_PLAN_TAX_SELF_REG] READONLY, 
 @COD_USER       INT, 
 @COD_AFFILIATOR INT, 
 @COD_PLAN_TYPE  INT, 
 @COD_PLAN_OPT   INT
)
AS
    BEGIN
	   DECLARE @COD_PLAN_CATEGORY INT;
SELECT
	@COD_PLAN_CATEGORY = [COD_PLAN_CATEGORY]
FROM [PLAN_CATEGORY]
WHERE [CATEGORY] = 'AUTO CADASTRO';

UPDATE [PLAN_TAX_AFFILIATOR]
SET [ACTIVE] = 0
FROM [PLAN_TAX_AFFILIATOR]
JOIN [PLAN]
	ON [PLAN].[COD_PLAN] = [PLAN_TAX_AFFILIATOR].[COD_PLAN]
WHERE [PLAN].[COD_AFFILIATOR] = @COD_AFFILIATOR
AND [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1
AND COD_PLAN_OPT = @COD_PLAN_OPT
AND [COD_PLAN_CATEGORY] = @COD_PLAN_CATEGORY;

INSERT INTO [PLAN_TAX_AFFILIATOR] ([COD_TTYPE],
[QTY_INI_PLOTS],
[QTY_FINAL_PLOTS],
[PERCENTAGE],
[RATE],
[INTERVAL],
[COD_PLAN],
[ANTICIPATION_PERCENTAGE],
[EFFECTIVE_PERCENTAGE],
[COD_BRAND],
[COD_SOURCE_TRAN],
[COD_AFFILIATOR],
[COD_USER],
COD_MODEL)
	SELECT
		[RATES].[COD_TRAN_TYPE]
	   ,[RATES].[QTY_INI_PL]
	   ,[RATES].[QTY_FINAL_FL]
	   ,[RATES].[PERCENT]
	   ,[RATES].[RATE]
	   ,[RATES].[INTERVAL]
	   ,[RATES].[CODPLAN]
	   ,[RATES].[ANTICIPATION]
	   ,0
	   ,[RATES].[COD_BRAND]
	   ,[RATES].[COD_TAX_TYPE]
	   ,@COD_AFFILIATOR
	   ,@COD_USER
	   ,RATES.COD_MODEL
	FROM @RATES AS [RATES];

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER TAX_PLAN', 1;
END;

GO
-- FINAL ET-920
GO
-- ST-1105

UPDATE ASS_TAX_DEPART
SET ACTIVE = 0
FROM ASS_TAX_DEPART
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
WHERE (COMMERCIAL_ESTABLISHMENT.CPF_CNPJ)
IN
(
'52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '52497895287'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '33502386889'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '01170607209'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '23675741000178'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '00677324294'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '36538132000119'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '40906712807'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00050445294'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '00835948250'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '05437528000146'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '03837447251'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '35993801808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '27812469808'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '68367740220'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '33817090200'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '00185480241'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '38333796850'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '40443701253'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '29290051000187'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '04408929000105'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '18858570200'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '64086275287'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '34672067000194'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '64367657272'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '88680860263'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '70363522212'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '00065142276'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '97529540000107'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '28473302249'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '07147665000171'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '12483107000117'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '33011601000159'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '01208577000156'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '81358199272'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '02204784303'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '28952202000152'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79576206200'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '79741576234'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '20965400000149'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161'
, '18703026000161 '
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '03939851485'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '51876680210'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
, '97685739291'
)
AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = 129
AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 1
AND ASS_TAX_DEPART.ACTIVE = 1
--AND ASS_TAX_DEPART.CREATED_AT BETWEEN '2020-07-16' AND '2020-07-16 09:02:07.433'



GO

INSERT INTO ASS_TAX_DEPART (CREATED_AT
, COD_TTYPE
, QTY_INI_PLOTS
, QTY_FINAL_PLOTS
, PARCENTAGE
, RATE
, INTERVAL
, COD_USER
, ACTIVE
, COD_DEPTO_BRANCH
, COD_PLAN
, ANTICIPATION_PERCENTAGE
, EFFECTIVE_PERCENTAGE
, COD_BRAND
, COD_SOURCE_TRAN)
	SELECT DISTINCT
		current_timestamp
	   ,TAX_PLAN.COD_TTYPE
	   ,TAX_PLAN.QTY_INI_PLOTS
	   ,TAX_PLAN.QTY_FINAL_PLOTS
	   ,TAX_PLAN.PARCENTAGE
	   ,TAX_PLAN.RATE
	   ,TAX_PLAN.INTERVAL
	   ,(SELECT TOP 1
				ASS.COD_USER
			FROM ASS_TAX_DEPART ASS
			WHERE ASS.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
			AND ASS.ACTIVE = 1)
	   ,TAX_PLAN.ACTIVE
	   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
	   ,(SELECT TOP 1
				COD_PLAN
			FROM ASS_TAX_DEPART ASS
			WHERE ASS.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
			AND ASS.ACTIVE = 1)
	   ,TAX_PLAN.ANTICIPATION_PERCENTAGE
	   ,TAX_PLAN.EFFECTIVE_PERCENTAGE
	   ,TAX_PLAN.COD_BRAND
	   ,TAX_PLAN.COD_SOURCE_TRAN
	FROM COMMERCIAL_ESTABLISHMENT
	INNER JOIN [PLAN]
		ON [PLAN].CODE = 'AFL ONLINE'
	INNER JOIN BRANCH_EC
		ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
	INNER JOIN DEPARTMENTS_BRANCH
		ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
	INNER JOIN TAX_PLAN
		ON TAX_PLAN.COD_PLAN = [PLAN].COD_PLAN
	WHERE COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
	IN
	(
	'52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '52497895287'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '33502386889'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '01170607209'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '23675741000178'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '00677324294'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '36538132000119'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '40906712807'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00050445294'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '00835948250'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '05437528000146'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '03837447251'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '35993801808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '27812469808'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '68367740220'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '33817090200'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '00185480241'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '38333796850'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '40443701253'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '29290051000187'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '04408929000105'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '18858570200'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '64086275287'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '34672067000194'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '64367657272'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '88680860263'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '70363522212'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '00065142276'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '97529540000107'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '28473302249'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '07147665000171'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '12483107000117'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '33011601000159'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '01208577000156'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '81358199272'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '02204784303'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '28952202000152'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79576206200'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '79741576234'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '20965400000149'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161'
	, '18703026000161 '
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '03939851485'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '51876680210'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	, '97685739291'
	)
	AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = 129
	ORDER BY COD_DEPTO_BRANCH

-- FIM ST-1105
GO

-- ST-1173
IF OBJECT_ID('SP_GW_DETAILS_DATA_TRANSACTION') IS NOT NULL
    DROP PROCEDURE SP_GW_DETAILS_DATA_TRANSACTION
GO
CREATE PROCEDURE [DBO].[SP_GW_DETAILS_DATA_TRANSACTION]                        
/*********************************************************************************************************        
----------------------------------------------------------------------------------------                        
Procedure Name: [SP_GW_DETAILS_DATA_TRANSACTION]                        
Project.......: TKPP                        
------------------------------------------------------------------------------------------                        
Author						VERSION        Date             Description                        
------------------------------------------------------------------------------------------                        
Kennedy Alef				V1			27/07/2018			Creation                        
Lucas Aguiar				V2			21/11/2018			Changed                      
Amós Corcino dos Santos		V3			17/01/2019			Change                    
Marcus Gall					V4			24/07/2020			Add Plan Name 
------------------------------------------------------------------------------------------        
*********************************************************************************************************/        
(        
	@TRANSACTIONCODE VARCHAR(300) ,       
	@COD_AFF INT 
)        
AS        
BEGIN        
	SELECT [TRANSACTION].[BRAND]        
   , [TRANSACTION].[AMOUNT]        
   , CAST([dbo].[FN_FUS_UTF](ISNULL([TRANSACTION].[CREATED_AT], [TRANSACTION].[CREATED_AT])) AS DATETIME) AS [TRANSACTION_DATE]        
   , [TRANSACTION].[CODE] AS [TRANSACTION_CODE]        
   , [SITUATION_TR] AS [SITUATION]        
   , [TRANSACTION_TYPE].[CODE] AS [TRAN_TYPE]        
   , [ACQUIRER].[CODE] AS [ACQ_CODE]        
   , [ACQUIRER].[NAME] AS [ACQ_NAME]        
   , [TRANSACTION].[CREATED_AT]        
   , [EQUIPMENT].[SERIAL]        
   , [TRANSACTION].[PAN]        
   , [TRANSACTION].[COMMENT] AS [COMMENT]        
   , [TRANSACTION].[TRACKING_TRANSACTION] AS [COD_RAST]        
   , [TRANSACTION].[DESCRIPTION]        
   , [TRANSACTION].[POSWEB]        
   , [TRANSACTION].[TYPE] AS [TXT_TRAN_TYPE]        
   , [TRANSACTION].[PLOTS]        
   , [TRANSACTION].[CARD_HOLDER_NAME]        
   , [TRANSACTION].[CARD_HOLDER_DOC]        
   , [TRANSACTION].[LOGICAL_NUMBER_ACQ]      
   , COMMERCIAL_ESTABLISHMENT.COD_EC      
   , COMMERCIAL_ESTABLISHMENT.[NAME] AS MERCHANT      
   , SOURCE_TRANSACTION.CODE AS SOURCE_TRAN       
   , (CASE WHEN 
		(SELECT COUNT(*) FROM [TRANSACTION_SERVICES] 
		WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]        
		AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10
		) > 0 THEN 1 ELSE 0 END) AS [LINK_MODE]
   , [PLAN].[CODE] AS PLAN_NAME 
	FROM [TRANSACTION] WITH (NOLOCK)       
	LEFT JOIN [ASS_DEPTO_EQUIP] WITH (NOLOCK) ON [TRANSACTION].[COD_ASS_DEPTO_TERMINAL] = [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL]        
	LEFT JOIN [EQUIPMENT] ON [ASS_DEPTO_EQUIP].[COD_EQUIP] = [EQUIPMENT].[COD_EQUIP]        
	LEFT JOIN [TRANSACTION_TYPE] ON [TRANSACTION_TYPE].[COD_TTYPE] = [TRANSACTION].[COD_TTYPE]        
	LEFT JOIN [PRODUCTS_ACQUIRER] ON [PRODUCTS_ACQUIRER].[COD_PR_ACQ] = [TRANSACTION].[COD_PR_ACQ]        
	LEFT JOIN [ACQUIRER] ON [ACQUIRER].[COD_AC] = [PRODUCTS_ACQUIRER].[COD_AC]        
	LEFT JOIN [CURRENCY] ON [TRANSACTION].[COD_CURRRENCY] = [CURRENCY].[COD_CURRRENCY]        
	LEFT JOIN [SITUATION] ON [SITUATION].[COD_SITUATION] = [TRANSACTION].[COD_SITUATION]        
	LEFT JOIN [TRADUCTION_SITUATION] ON [TRADUCTION_SITUATION].[COD_SITUATION] = [SITUATION].[COD_SITUATION]      
	LEFT JOIN [ASS_TAX_DEPART] ON [ASS_TAX_DEPART].[COD_ASS_TX_DEP] = [TRANSACTION].[COD_ASS_TX_DEP]
	LEFT JOIN [PLAN] ON [PLAN].[COD_PLAN] = [ASS_TAX_DEPART].[COD_PLAN]
	JOIN SOURCE_TRANSACTION ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN      
	JOIN DEPARTMENTS_BRANCH ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH      
	JOIN BRANCH_EC on BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH      
	JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC      
	WHERE [TRANSACTION].[CODE] = @TRANSACTIONCODE AND [TRANSACTION].COD_AFFILIATOR=@COD_AFF       
END;        
GO

IF OBJECT_ID('SP_GW_DATA_TRAN_TITLE') IS NOT NULL
    DROP PROCEDURE SP_GW_DATA_TRAN_TITLE
GO      
CREATE PROCEDURE [DBO].[SP_GW_DATA_TRAN_TITLE]           
        
/********************************************************************************************        
----------------------------------------------------------------------------------------           
Procedure Name: [SP_DATA_TRAN_TITLE]  
Project.......: TKPP           
------------------------------------------------------------------------------------------           
Author              VERSION        Date         Description           
------------------------------------------------------------------------------------------           
Kennedy Alef        V1          27/07/2018      Creation           
Luiz Aquino         V2          08/07/2019      bank is_cerc          
Marcus Gall			V3			03/01/2020		Add AmountNoRate and RatePlot          
Marcus Gall			V4			07/02/2020		Alter UNION RELEASE_ADJUSTMENTS           
Lucas Aguiar		V5			25/03/2020		add cod ec        
Marcus Gall			V6			24/07/2020		Add MDR and Antecipation on Titles
------------------------------------------------------------------------------------------        
********************************************************************************************/        
(        
	@CODE_TRAN        VARCHAR(100),         
	@SHOW_ADJUSTMENTS INT          = 0,         
	@COD_EC           INT          = NULL
)        
AS        
    DECLARE @QUERY_ NVARCHAR(MAX)= '';        
BEGIN        
	SET @QUERY_ = CONCAT(@QUERY_, '           
    SELECT * FROM (          
    SELECT TRANSACTION_TITLES.COD_TITLE AS CODE          
    , CAST(TRANSACTION_TITLES.AMOUNT AS DECIMAL(22, 6)) AS AMOUNT          
    ,TRANSACTION_TITLES.PLOT      
	, TRANSACTION_TITLES.COD_EC AS MERCHANTINSIDECODE      
    , CAST((          
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
	 , (
	  CASE 
		WHEN TRANSACTION_TITLES.QTY_DAYS_ANTECIP > 0 AND [TRANSACTION].COD_TTYPE = 1 THEN TRANSACTION_TITLES.ANTICIP_PERCENT
		ELSE 0 
	  END 
	 ) AS ANTICIP_PERCENT
	 , TRANSACTION_TITLES.TAX_INITIAL
    FROM TRANSACTION_TITLES          
    INNER JOIN [TRANSACTION] WITH (NOLOCK) ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
    INNER JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = TRANSACTION_TITLES.COD_EC          
	INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC          
    INNER JOIN COMPANY ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP          
    INNER JOIN SITUATION ON SITUATION.COD_SITUATION = TRANSACTION_TITLES.COD_SITUATION          
    INNER JOIN BANK_DETAILS_EC ON BANK_DETAILS_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
		AND BANK_DETAILS_EC.ACTIVE = 1 AND BANK_DETAILS_EC.IS_CERC = 0          
    LEFT JOIN BANKS ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK          
    LEFT JOIN TYPE_TRANSACTION_TITTLE ON TYPE_TRANSACTION_TITTLE.COD_TYPE_TRAN_TITLE = TRANSACTION_TITLES.COD_TYPE_TRAN_TITLE          
    INNER JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = SITUATION.COD_SITUATION          
    LEFT JOIN SITUATION ST_TITTLE ON ST_TITTLE.COD_SITUATION = TRANSACTION_TITLES.COD_SITUATION          
    LEFT JOIN TRADUCTION_SITUATION TR_TITTLE ON TR_TITTLE.COD_SITUATION = ST_TITTLE.COD_SITUATION          
    LEFT JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = TRANSACTION_TITLES.COD_PAY_PROT      
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
        
	EXEC [sp_executesql] @QUERY_        
     ,N'           
		@CODE_TRAN VARCHAR(100),        
		@SHOW_ADJUSTMENTS INT,        
		@COD_EC INT = NULL'        
		,@CODE_TRAN = @CODE_TRAN        
		,@SHOW_ADJUSTMENTS = @SHOW_ADJUSTMENTS        
		,@COD_EC = @COD_EC;        
        
END; 
GO

-- FIM ST-1173
IF OBJECT_ID('SP_ADD_TAX_DEPTO') IS NOT NULL
    DROP PROCEDURE [SP_ADD_TAX_DEPTO] ;
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

EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH
  
END;

go

IF OBJECT_ID('SP_ASS_DEPTO_PLAN') IS NOT NULL
    DROP PROCEDURE [SP_ASS_DEPTO_PLAN] ;
GO   
      
CREATE PROCEDURE [dbo].[SP_ASS_DEPTO_PLAN]        
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

EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH

  
END;

GO

IF OBJECT_ID('SP_DISABLE_TX_DEPTO_PLAN') IS NOT NULL
    DROP PROCEDURE [SP_DISABLE_TX_DEPTO_PLAN] ;
GO   
      
  
CREATE PROCEDURE [dbo].[SP_DISABLE_TX_DEPTO_PLAN]    
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_DISABLE_TX_DEPTO_PLAN]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author                          VERSION        Date                            Description    
------------------------------------------------------------------------------------------    
Kennedy Alef     V1    27/07/2018      Creation    
------------------------------------------------------------------------------------------*/    
(    
@COD_DEPTO_BRANCH INT)    
AS    
DECLARE @QTD INT;    
BEGIN    
    
UPDATE ASS_TAX_DEPART SET ACTIVE = 0     
FROM ASS_TAX_DEPART     
WHERE   
ACTIVE = 1 AND  
COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH    

EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH

    
END;

GO

IF OBJECT_ID('SP_GW_ASS_PLAN_EC_MODEL_EQUIPMENT') IS NOT NULL
    DROP PROCEDURE [SP_GW_ASS_PLAN_EC_MODEL_EQUIPMENT] ;
GO   
   

CREATE PROCEDURE [dbo].[SP_GW_ASS_PLAN_EC_MODEL_EQUIPMENT]  
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_GW_ASS_PLAN_EC_MODEL_EQUIPMENT]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Marcus Gall      V1   2020-07-13  ET-921: Handle Plan by Equipment  
------------------------------------------------------------------------------------------*/ (@COD_PLAN INT,  
@COD_EC INT,  
@COD_AFFILIATOR INT)  
AS  
BEGIN  
  
 DECLARE @COD_AFF_PLAN INT;  
 DECLARE @TP_RATES_EC_MODEL_EQUIPMENT AS dbo.TP_RATES_EC_MODEL_EQUIPMENT;  
 DECLARE @COD_DEPTO_BRANCH INT;  
 DECLARE @COD_USER INT;  
  
 SELECT  
  @COD_AFF_PLAN = COD_AFFILIATOR  
 FROM [PLAN]  
 WHERE COD_PLAN = @COD_PLAN  
 AND ACTIVE = 1;  
 IF @COD_AFF_PLAN <> @COD_AFFILIATOR  
  THROW 61064, 'INVALID PLAN FOR THIS AFFILIATOR OR PLAN IS INACTIVE', 1;  
  
  
 IF (SELECT  
    COUNT(*)  
   FROM COMMERCIAL_ESTABLISHMENT  
   WHERE COD_EC = @COD_EC  
   AND COD_AFFILIATOR = @COD_AFFILIATOR)  
  = 0  
  THROW 61065, 'INVALID MERCHANT FOR THIS AFFILIATOR', 1;  
  
 INSERT INTO @TP_RATES_EC_MODEL_EQUIPMENT  
  SELECT  
   TAX_PLAN.INTERVAL  
     ,TAX_PLAN.PARCENTAGE  
     ,TAX_PLAN.QTY_INI_PLOTS  
     ,TAX_PLAN.QTY_FINAL_PLOTS  
     ,TAX_PLAN.ANTICIPATION_PERCENTAGE  
     ,TAX_PLAN.COD_TTYPE  
     ,TAX_PLAN.COD_SOURCE_TRAN  
     ,@COD_AFFILIATOR  
     ,TAX_PLAN.COD_BRAND  
     ,[PLAN].COD_T_PLAN  
     ,TAX_PLAN.RATE  
     ,[PLAN].COD_PLAN  
     ,TAX_PLAN.COD_MODEL  
  FROM [PLAN]  
  JOIN TAX_PLAN  
   ON TAX_PLAN.COD_PLAN = [PLAN].COD_PLAN  
  WHERE [PLAN].COD_PLAN = @COD_PLAN  
  AND TAX_PLAN.ACTIVE = 1;  
  
 EXEC SP_GW_VALIDATE_PLAN_EC_AFF_MODEL_EQUIPMENT @TP_RATES_EC_MODEL_EQUIPMENT;  
  
 SELECT  
  @COD_DEPTO_BRANCH = COD_DEPTO_BRANCH  
 FROM COMMERCIAL_ESTABLISHMENT  
 JOIN BRANCH_EC  
  ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
 JOIN DEPARTMENTS_BRANCH  
  ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH  
 WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC;  
  
 SELECT  
  @COD_USER = COD_USER_INT  
 FROM ACCESS_APPAPI  
 WHERE COD_AFFILIATOR = @COD_AFFILIATOR;  
  
 UPDATE ASS_TAX_DEPART  
 SET ACTIVE = 0  
 WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH  
 AND ACTIVE = 1;  
  
 INSERT INTO ASS_TAX_DEPART (INTERVAL,  
 PARCENTAGE,  
 QTY_INI_PLOTS,  
 QTY_FINAL_PLOTS,  
 ANTICIPATION_PERCENTAGE,  
 COD_TTYPE,  
 COD_SOURCE_TRAN,  
 COD_BRAND,  
 RATE,  
 ACTIVE,  
 COD_PLAN,  
 COD_DEPTO_BRANCH,  
 COD_USER,  
 COD_MODEL)  
  SELECT  
   TAX_PLAN.INTERVAL  
     ,TAX_PLAN.PARCENTAGE  
     ,TAX_PLAN.QTY_INI_PLOTS  
     ,TAX_PLAN.QTY_FINAL_PLOTS  
     ,TAX_PLAN.ANTICIPATION_PERCENTAGE  
     ,TAX_PLAN.COD_TTYPE  
     ,TAX_PLAN.COD_SOURCE_TRAN  
     ,TAX_PLAN.COD_BRAND  
     ,TAX_PLAN.RATE  
     ,1  
     ,[PLAN].COD_PLAN  
     ,@COD_DEPTO_BRANCH  
     ,@COD_USER  
     ,TAX_PLAN.COD_MODEL  
  FROM [PLAN]  
  JOIN TAX_PLAN  
   ON TAX_PLAN.COD_PLAN = [PLAN].COD_PLAN  
  WHERE [PLAN].COD_PLAN = @COD_PLAN  
  AND TAX_PLAN.ACTIVE = 1  

  EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH
  
END

go

IF OBJECT_ID('SP_GW_REG_TAX_DEPTO_BR_EC') IS NOT NULL
    DROP PROCEDURE [SP_GW_REG_TAX_DEPTO_BR_EC] ;
GO   
   
CREATE  PROCEDURE [dbo].[SP_GW_REG_TAX_DEPTO_BR_EC]  
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_GW_REG_TAX_DEPTO_BR_EC]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION        Date                            Description  
------------------------------------------------------------------------------------------  
Kennedy Alef     V1    27/07/2018      Creation  
------------------------------------------------------------------------------------------*/  
(  
@COD_TTYPE INT,  
@QTY_INI_PLOTS INT ,  
@QTY_FINAL_PLOTS INT,  
@PARCENTAGE DECIMAL(22,6),  
@RATE DECIMAL(22,6),  
@INTERVAL INT,  
@COD_DEPTO_BRANCH INT,  
@CODUSER INT,  
@ANTICIPATION DECIMAL(22,6),  
@PERCENTAGE_EFFECTIVE DECIMAL(22,6)  
)  
AS  
DECLARE @QTD INT;  
BEGIN  
  
  
INSERT INTO ASS_TAX_DEPART  
(  
COD_TTYPE,  
QTY_INI_PLOTS,  
QTY_FINAL_PLOTS,  
PARCENTAGE,  
RATE,  
INTERVAL,  
COD_DEPTO_BRANCH,  
EFFECTIVE_PERCENTAGE,  
ANTICIPATION_PERCENTAGE  
)  
VALUES  
(  
@COD_TTYPE,  
@QTY_INI_PLOTS,  
@QTY_FINAL_PLOTS,  
@PARCENTAGE,  
@RATE,  
@INTERVAL,  
@COD_DEPTO_BRANCH,  
@PERCENTAGE_EFFECTIVE,  
@ANTICIPATION);  
  
  
IF @@ROWCOUNT < 1  
THROW 60000,'COULD NOT REGISTER ASS_TAX_DEPART ',1;  

EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH

  
END;

go

IF OBJECT_ID('SP_GW_UP_PLAN_ESTABLISHMENT') IS NOT NULL
    DROP PROCEDURE [SP_GW_UP_PLAN_ESTABLISHMENT] ;
GO   
       
      
CREATE PROCEDURE [dbo].[SP_GW_UP_PLAN_ESTABLISHMENT]            
/*----------------------------------------------------------------------------------------              
Procedure Name: [SP_GW_UP_PLAN_ESTABLISHMENT]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION        Date                            Description              
------------------------------------------------------------------------------------------              
Caike Uch�a                       V1          2020-06-09                        Creation            
------------------------------------------------------------------------------------------*/              
(              
 @TP_RATES_EC [TP_RATES_EC] READONLY,        
 @COD_EC INT ,  
 @COD_T_PLAN VARCHAR(100) = NULL  
)        
AS        
BEGIN        
         
DECLARE @COD_DEPTO_BRANCH INT;        
DECLARE @COD_USER INT;        
DECLARE @COD_AFFILIATOR INT;        
DECLARE @QTD_TAX INT;        
DECLARE @COUNT_TAX_EQUALS INT;       
DECLARE @_COD_PLAN INT;    
DECLARE @COD_T_PLAN_INS INT = 0;  
        
      
        
SELECT        
 @COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH        
   ,@QTD_TAX = COUNT(*)      
   ,@_COD_PLAN = ASS_TAX_DEPART.COD_PLAN      
FROM ASS_TAX_DEPART        
JOIN DEPARTMENTS_BRANCH        
 ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH        
JOIN BRANCH_EC        
 ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH        
JOIN COMMERCIAL_ESTABLISHMENT        
 ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC        
JOIN AFFILIATOR        
 ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR        
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC        
AND ASS_TAX_DEPART.ACTIVE = 1        
GROUP BY ASS_TAX_DEPART.COD_DEPTO_BRANCH        
  ,ASS_TAX_DEPART.COD_PLAN      
        
  
SET @COD_T_PLAN_INS=    
(  
SELECT   
CASE   
WHEN @COD_T_PLAN = 'PARCELADO' THEN 1  
WHEN @COD_T_PLAN = 'AGRUPADO' THEN 2  
ELSE NULL  
END  
);  
        
      
UPDATE ASS_TAX_DEPART        
SET ACTIVE = 0        
WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH        
AND ACTIVE = 1        
        
SELECT        
 @COD_USER = COD_USER_INT        
FROM ACCESS_APPAPI        
WHERE COD_AFFILIATOR = @COD_AFFILIATOR        
        
INSERT INTO ASS_TAX_DEPART (COD_TTYPE,        
QTY_INI_PLOTS,        
QTY_FINAL_PLOTS,        
PARCENTAGE,        
RATE,        
INTERVAL,        
ACTIVE,        
COD_PLAN,        
ANTICIPATION_PERCENTAGE,        
COD_BRAND,        
COD_SOURCE_TRAN,        
COD_DEPTO_BRANCH,        
COD_USER,    
EFFECTIVE_PERCENTAGE    
)        
        
 SELECT        
  ITEM.COD_TRAN_TYPE        
    ,ITEM.QTY_INI_PL        
    ,ITEM.QTY_FINAL_FL        
    ,ITEM.[PERCENTAGE]        
    ,ITEM.RATE        
    ,ITEM.INTERVAL        
    ,1        
    ,@_COD_PLAN       
    ,ITEM.ANTICIPATION        
    ,ITEM.COD_BRAND        
    ,ITEM.COD_SOURCE_TRAN        
    ,@COD_DEPTO_BRANCH        
    ,@COD_USER    
 ,0    
 FROM @TP_RATES_EC ITEM        
        
IF @@rowcount < 1        
        
THROW 60000, 'COULD NOT REGISTER [TAX_PLAN] ', 1;     
  
UPDATE DEPARTMENTS_BRANCH SET COD_T_PLAN =  ISNULL(@COD_T_PLAN_INS, COD_T_PLAN)  
WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH  
        

EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH

      
END;
go

IF OBJECT_ID('SP_GW_UP_PLAN_ESTABLISHMENT_MODEL_EQUIPMENT') IS NOT NULL
    DROP PROCEDURE [SP_GW_UP_PLAN_ESTABLISHMENT_MODEL_EQUIPMENT] ;
GO   

CREATE PROCEDURE [dbo].[SP_GW_UP_PLAN_ESTABLISHMENT_MODEL_EQUIPMENT]    
/*----------------------------------------------------------------------------------------          
Procedure Name: [SP_GW_UP_PLAN_ESTABLISHMENT_MODEL_EQUIPMENT]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author                          VERSION        Date                            Description          
------------------------------------------------------------------------------------------          
Marcus Gall                         V1      2020-07-13          ET-921: Handle Plan by Equipment    
Caike Uchoa                         v2      2020-10-16                       return cod_plan  
------------------------------------------------------------------------------------------*/   
(  
@TP_RATES_EC_MODEL_EQUIPMENT [TP_RATES_EC_MODEL_EQUIPMENT] READONLY,    
@COD_EC INT,    
@COD_T_PLAN VARCHAR(100) = NULL)    
AS    
BEGIN  
    
    
 DECLARE @COD_DEPTO_BRANCH INT;  
    
    
 DECLARE @COD_USER INT;  
    
    
 DECLARE @COD_AFFILIATOR INT;  
    
    
 DECLARE @QTD_TAX INT;  
    
    
 DECLARE @COUNT_TAX_EQUALS INT;  
    
    
 DECLARE @_COD_PLAN INT;  
    
    
 DECLARE @COD_T_PLAN_INS INT = 0;  
  
SELECT  
 @COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH  
   ,@QTD_TAX = COUNT(*)  
   ,@_COD_PLAN = ASS_TAX_DEPART.COD_PLAN  
FROM ASS_TAX_DEPART  
JOIN DEPARTMENTS_BRANCH  
 ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH  
JOIN BRANCH_EC  
 ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH  
JOIN COMMERCIAL_ESTABLISHMENT  
 ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC  
JOIN AFFILIATOR  
 ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR  
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC  
AND ASS_TAX_DEPART.ACTIVE = 1  
GROUP BY ASS_TAX_DEPART.COD_DEPTO_BRANCH  
  ,ASS_TAX_DEPART.COD_PLAN  
  
  
SET @COD_T_PLAN_INS = (SELECT  
  CASE  
   WHEN @COD_T_PLAN = 'PARCELADO' THEN 1  
   WHEN @COD_T_PLAN = 'AGRUPADO' THEN 2  
   ELSE NULL  
  END);  
  
UPDATE ASS_TAX_DEPART  
SET ACTIVE = 0  
WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH  
AND ACTIVE = 1;  
  
SELECT  
 @COD_USER = COD_USER_INT  
FROM ACCESS_APPAPI  
WHERE COD_AFFILIATOR = @COD_AFFILIATOR;  
  
INSERT INTO ASS_TAX_DEPART (COD_TTYPE,  
QTY_INI_PLOTS,  
QTY_FINAL_PLOTS,  
PARCENTAGE,  
RATE,  
INTERVAL,  
ACTIVE,  
COD_PLAN,  
ANTICIPATION_PERCENTAGE,  
COD_BRAND,  
COD_SOURCE_TRAN,  
COD_DEPTO_BRANCH,  
COD_USER,  
EFFECTIVE_PERCENTAGE,  
COD_MODEL)  
  
 SELECT  
  ITEM.COD_TRAN_TYPE  
    ,ITEM.QTY_INI_PL  
    ,ITEM.QTY_FINAL_FL  
    ,ITEM.[PERCENTAGE]  
    ,ITEM.RATE  
    ,ITEM.INTERVAL  
    ,1  
    ,@_COD_PLAN  
    ,ITEM.ANTICIPATION  
    ,ITEM.COD_BRAND  
    ,ITEM.COD_SOURCE_TRAN  
    ,@COD_DEPTO_BRANCH  
    ,@COD_USER  
    ,0  
    ,ITEM.COD_MODEL  
 FROM @TP_RATES_EC_MODEL_EQUIPMENT ITEM  
  
IF @@rowcount < 1  
THROW 60000, 'COULD NOT REGISTER [TAX_PLAN] ', 1;  
  
UPDATE DEPARTMENTS_BRANCH  
SET COD_T_PLAN = ISNULL(@COD_T_PLAN_INS, COD_T_PLAN)  
WHERE COD_DEPTO_BRANCH = @COD_DEPTO_BRANCH  

EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH

  
SELECT  
 @_COD_PLAN AS COD_PLAN  
  
END;

GO


IF OBJECT_ID('SP_MIGRATE_PLAN_TERMINAL') IS NOT NULL
    DROP PROCEDURE SP_MIGRATE_PLAN_TERMINAL ;
GO   

  
CREATE PROCEDURE SP_MIGRATE_PLAN_TERMINAL(@COD_AFF INT)  
AS  
    BEGIN  
    DECLARE @COD_USER INT= NULL;  
	DECLARE @TB_DEPTO AS TABLE (COD_DEPTO INT)
  
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
COD_MODEL)  OUTPUT inserted.COD_DEPTO_BRANCH into @TB_DEPTO
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





DECLARE @COD_DEPTO_BRANCH INT;
DECLARE CURSOR_ECS CURSOR FOR SELECT
COD_DEPTO
FROM @TB_DEPTO


OPEN CURSOR_ECS;  
  
FETCH NEXT FROM CURSOR_ECS INTO @COD_DEPTO_BRANCH;  
  
WHILE @@fetch_status = 0  
BEGIN  


EXEC SP_UP_DATA_PLAN_TABLE_LOAD @COD_DEPTO_BRANCH

FETCH NEXT FROM CURSOR_ECS INTO @COD_DEPTO_BRANCH;  

END;
CLOSE CURSOR_ECS;  
  
DEALLOCATE CURSOR_ECS;  



END;

GO
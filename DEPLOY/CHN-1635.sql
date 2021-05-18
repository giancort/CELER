--ST-2007

GO 

IF OBJECT_ID('SP_GW_ASS_EQUIP_TO_MERCHANT')IS NOT NULL
DROP PROCEDURE SP_GW_ASS_EQUIP_TO_MERCHANT;

GO
CREATE PROCEDURE SP_GW_ASS_EQUIP_TO_MERCHANT    
/*----------------------------------------------------------------------------------------                          
Project.......: TKPP                          
------------------------------------------------------------------------------------------                          
Author                  VERSION        Date             Description                          
------------------------------------------------------------------------------------------                                  
Caike Uch�a              V2          2021-04-15       alter number error "equipment not found"  
------------------------------------------------------------------------------------------*/
(    
@COD_EC INT,    
@COD_AFF INT ,    
@SERIAL VARCHAR(100)    
)    
AS    
BEGIN    
    
DECLARE @COD_SITUATION INT;    
    
DECLARE @COD_EQUIP INT;    
    
DECLARE @COD_DEPTO INT;    
    
DECLARE @COD_USER INT;    
    
DECLARE @COD_AC INT;    
    
DECLARE @COD_COMP INT    
    
SELECT     
top 1    
@COD_SITUATION = COD_RISK_SITUATION,    
@COD_DEPTO = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH,    
@COD_USER = USERS.COD_USER,    
@COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP FROM  COMMERCIAL_ESTABLISHMENT     
JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC    
JOIN DEPARTMENTS_BRANCH ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH    
JOIN ACCESS_APPAPI ON ACCESS_APPAPI.COD_AFFILIATOR = @COD_AFF    
  AND ACCESS_APPAPI.ACTIVE=1    
JOIN USERS ON USERS.COD_USER = ACCESS_APPAPI.COD_USER_INT    
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFF     
    
IF @COD_SITUATION IS NULL    
THROW 80700 , 'Merchant not found',1;    
    
IF @COD_SITUATION NOT IN ( 2, 9 )    
THROW 80701 , 'Invalid Risk situation for merchant',1;    
    
SELECT @COD_EQUIP = COD_EQUIP  FROM EQUIPMENT WHERE SERIAL = @SERIAL    
    
IF @COD_EQUIP IS NULL    
THROW 61081 , 'Equipment not found',1;    
    
IF (SELECT COUNT(*) FROM VW_COMPANY_EC_AFF_BR_DEP_EQUIP WHERE COD_EQUIP= @COD_EQUIP) >0     
THROW 80702 , 'Equipment already associated to another merchant',1;    
    
SELECT TOP 1 @COD_AC= COD_AC FROM ACQUIRER WHERE [GROUP] ='Pagseguro'    
    
    
EXEC [SP_REG_ASS_TID_EQUIP_EC_AFF]    
@COD_EQUIP = @COD_EQUIP,    
@COD_USER = @COD_USER,    
@COD_DEPTO = @COD_DEPTO,    
@COD_COMP  = @COD_COMP    
    
    
    
END;

--ST-2007

GO


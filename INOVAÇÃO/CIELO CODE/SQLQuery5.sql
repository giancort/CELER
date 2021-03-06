
INSERT INTO ACQUIRER_KEYS_CREDENTIALS (NAME, VALUE, COD_AC)
	VALUES ('ACQUIRER_CODE', '1095232344', 8)
GO
INSERT INTO ACQUIRER_KEYS_CREDENTIALS (NAME, VALUE, COD_AC)
	VALUES ('ACQUIRER_CODE', '1118144918', 18)

GO

ALTER TABLE COMMERCIAL_ESTABLISHMENT
	ADD CIELO_CODE VARCHAR(100) DEFAULT NULL

GO


IF OBJECT_ID('VW_COMPANY_EC_BR_DEP_EQUIP') IS NOT NULL DROP VIEW VW_COMPANY_EC_BR_DEP_EQUIP;
GO
CREATE VIEW [dbo].[VW_COMPANY_EC_BR_DEP_EQUIP]      
AS
SELECT
	VW_COMPANY_EC_BR_DEP.MCC
   ,VW_COMPANY_EC_BR_DEP.COMPANY
   ,VW_COMPANY_EC_BR_DEP.COD_COMP
   ,VW_COMPANY_EC_BR_DEP.FIREBASE_NAME
   ,VW_COMPANY_EC_BR_DEP.EC AS TRADING_NAME_BR
   ,VW_COMPANY_EC_BR_DEP.COD_EC
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC
   ,VW_COMPANY_EC_BR_DEP.SITUATION_EC
   ,VW_COMPANY_EC_BR_DEP.BRANCH_NAME
   ,VW_COMPANY_EC_BR_DEP.TRADING_NAME_BR AS EC
   ,VW_COMPANY_EC_BR_DEP.COD_BRANCH
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_BR
   ,VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
   ,VW_COMPANY_EC_BR_DEP.DEPARTMENT
   ,VW_COMPANY_EC_BR_DEP.SEGMENTS
   ,VW_COMPANY_EC_BR_DEP.MERCHANT_CODE
   ,ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
   ,EQUIPMENT.COD_EQUIP
   ,EQUIPMENT.SERIAL
   ,EQUIPMENT.TID
   ,CELL_OPERATOR.NAME AS OPERATOR
   ,EQUIPMENT.PUK
   ,EQUIPMENT.CHIP
   ,EQUIPMENT.ACTIVE
   ,DATA_EQUIPMENT_AC.CODE
FROM VW_COMPANY_EC_BR_DEP
INNER JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
INNER JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
LEFT JOIN CELL_OPERATOR
	ON CELL_OPERATOR.COD_OPER = EQUIPMENT.COD_OPER
LEFT JOIN DATA_EQUIPMENT_AC
	ON ASS_DEPTO_EQUIP.COD_EQUIP = DATA_EQUIPMENT_AC.COD_EQUIP
WHERE ASS_DEPTO_EQUIP.ACTIVE = 1
AND EQUIPMENT.ACTIVE = 1

GO

IF OBJECT_ID('SP_CONTACT_DATA_EQUIP') IS NOT NULL DROP PROCEDURE SP_CONTACT_DATA_EQUIP;
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
Lucas Aguiar                      v3         22-04-2019                   Descer se � split ou n�o                    
Caike Uch�a                       v4         15/01/2020                     descer MMC padr�o para PF            
Caike Uchoa                       v5         22/09/2020                    Add formatacao de strings          
------------------------------------------------------------------------------------------*/ (  
@TERMINALID INT,   
@COD_EC INT = NULL)  
AS  
BEGIN
SELECT TOP 1
	VW_COMPANY_EC_BR_DEP_EQUIP.CPF_CNPJ_BR
   ,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF
   ,[dbo].[FNC_REMOV_CARAC_ESP](
	VW_COMPANY_EC_BR_DEP_EQUIP.TRADING_NAME_BR) AS TRADING_NAME_BR
   ,[dbo].[FNC_REMOV_CARAC_ESP](VW_COMPANY_EC_BR_DEP_EQUIP.BRANCH_NAME) AS BRANCH_NAME
   ,CASE
		WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'
		ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC
	END AS MCC
   ,COMMERCIAL_ESTABLISHMENT.CODE AS MERCHANT_CODE
   ,LEFT([dbo].[FNC_REMOV_CARAC_ESP](ADDRESS_BRANCH.[ADDRESS]), 20) AS [ADDRESS]
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
   ,VW_COMPANY_EC_BR_DEP_EQUIP.MERCHANT_CODE
   ,COMMERCIAL_ESTABLISHMENT.CIELO_CODE
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
	END AS [SPLIT]
   ,(
	CASE
		WHEN (SELECT
					COUNT(*)
				FROM SERVICES_AVAILABLE
				WHERE COD_ITEM_SERVICE = 13
				AND ACTIVE = 1
				AND COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
				AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR)
			> 0 THEN 1
		ELSE 0
	END
	) AS MANY_MERCHANTS
   ,EC_PARAM.CPF_CNPJ AS CNPJ_PARAM
   ,IIF(LEN(EC_PARAM.CPF_CNPJ) = 11, 'CPF',
	IIF(EC_PARAM.CPF_CNPJ IS NOT NULL, 'CNPJ', NULL)) AS TYPE_DOC_PARAM
	--,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF    
   ,[dbo].[FNC_REMOV_CARAC_ESP](EC_PARAM.NAME) AS TRADING_NAME_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP](EC_PARAM.TRADING_NAME) AS BRANCH_NAME_PARAM
	--  ,CASE    
	-- WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'    
	-- ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC    
	--END AS MCC_PARAM    
   ,EC_PARAM.CODE AS MERCHANT_CODE_PARAM
   ,LEFT([dbo].[FNC_REMOV_CARAC_ESP](ADD_EC_PARAM.[ADDRESS]), 20) AS [ADDRESS_PARAM]
   ,[dbo].[FNC_REMOV_LETRAS](
	[dbo].FNC_REMOV_CARAC_ESP(ADD_EC_PARAM.[NUMBER])) AS [NUMBER_PARAM]
   ,ADD_EC_PARAM.CEP AS CEP_PARAM
   ,ISNULL([dbo].[FNC_REMOV_CARAC_ESP](ADD_EC_PARAM.COMPLEMENT), 0) AS COMPLEMENT_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP](ENIGH_EC_PARAM.NAME) AS NEIGHBORDHOOD_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP](CITY_EC_PARAM.[NAME]) AS CITY_PARAM
   ,[dbo].[FNC_REMOV_CARAC_ESP]([STATE_EC_PARAM].UF) AS [STATE_PARAM]
   ,COUNTRY_EC_PARAM.INITIALS AS INITIALS_PARAM
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
LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PARAM
	ON EC_PARAM.COD_EC = ISNULL(@COD_EC, 0)
		AND EC_PARAM.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
LEFT JOIN BRANCH_EC BRANCH_PARAM
	ON EC_PARAM.COD_EC = BRANCH_PARAM.COD_EC
LEFT JOIN ADDRESS_BRANCH ADD_EC_PARAM
	ON ADD_EC_PARAM.COD_BRANCH = BRANCH_PARAM.COD_BRANCH
		AND ADD_EC_PARAM.ACTIVE = 1
LEFT JOIN NEIGHBORHOOD ENIGH_EC_PARAM
	ON ENIGH_EC_PARAM.COD_NEIGH = ADD_EC_PARAM.COD_NEIGH
LEFT JOIN CITY CITY_EC_PARAM
	ON CITY_EC_PARAM.COD_CITY = ENIGH_EC_PARAM.COD_CITY
LEFT JOIN STATE STATE_EC_PARAM
	ON STATE_EC_PARAM.COD_STATE = CITY_EC_PARAM.COD_STATE
LEFT JOIN COUNTRY COUNTRY_EC_PARAM
	ON COUNTRY_EC_PARAM.COD_COUNTRY = STATE_EC_PARAM.COD_COUNTRY
WHERE EQUIPMENT.COD_EQUIP = @TERMINALID
AND ASS_DEPTO_EQUIP.ACTIVE = 1
ORDER BY ADDRESS_BRANCH.COD_ADDRESS DESC

END
GO


GO


IF OBJECT_ID('SP_CONTACT_DATA_EQUIP_MID') IS NOT NULL DROP PROCEDURE SP_CONTACT_DATA_EQUIP_MID;
GO
CREATE PROCEDURE [dbo].[SP_CONTACT_DATA_EQUIP_MID]       
/*----------------------------------------------------------------------------------------              
Procedure Name: [SP_CONTACT_DATA_EQUIP]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION         Date                            Description              
------------------------------------------------------------------------------------------              
Kennedy Alef                      V1         27/07/2018                           Creation              
Fernando Henrique F. O            V2         03/04/2019                           Change                
Lucas Aguiar                      v3         22-04-2019                   Descer se � split ou n�o              
Caike Uch�a                       v4         15/01/2020                     descer MMC padr�o para PF        
------------------------------------------------------------------------------------------*/              
(              
  @MID INT)              
AS              
BEGIN  
  
SELECT TOP 1  
 VW_COMPANY_EC_BR_DEP_EQUIP.CPF_CNPJ_BR  
   ,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF  
   ,[dbo].[FNC_REMOV_CARAC_ESP](  
 VW_COMPANY_EC_BR_DEP_EQUIP.TRADING_NAME_BR) AS TRADING_NAME_BR  
   ,[dbo].[FNC_REMOV_CARAC_ESP](VW_COMPANY_EC_BR_DEP_EQUIP.BRANCH_NAME) AS BRANCH_NAME  
   ,CASE  
  WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'  
  ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC  
 END AS MCC  
   ,COMMERCIAL_ESTABLISHMENT.CODE AS MERCHANT_CODE  
   ,LEFT([dbo].[FNC_REMOV_CARAC_ESP](ADDRESS_BRANCH.[ADDRESS]), 20) AS [ADDRESS]  
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
   ,VW_COMPANY_EC_BR_DEP_EQUIP.MERCHANT_CODE  
   ,COMMERCIAL_ESTABLISHMENT.CIELO_CODE  
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
 END AS [SPLIT]  
   ,(  
 CASE  
  WHEN (SELECT  
     COUNT(*)  
    FROM SERVICES_AVAILABLE  
    WHERE COD_ITEM_SERVICE = 13  
    AND ACTIVE = 1  
    AND COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC  
    AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR)  
   > 0 THEN 1  
  ELSE 0  
 END  
 ) AS MANY_MERCHANTS  
   ,EC_PARAM.CPF_CNPJ AS CNPJ_PARAM  
   ,IIF(LEN(EC_PARAM.CPF_CNPJ) = 11, 'CPF',  
 IIF(EC_PARAM.CPF_CNPJ IS NOT NULL, 'CNPJ', NULL)) AS TYPE_DOC_PARAM  
 --,AFFILIATOR.CPF_CNPJ AS CPF_CNPJ_AFF      
   ,[dbo].[FNC_REMOV_CARAC_ESP](EC_PARAM.NAME) AS TRADING_NAME_PARAM  
   ,[dbo].[FNC_REMOV_CARAC_ESP](EC_PARAM.TRADING_NAME) AS BRANCH_NAME_PARAM  
 --  ,CASE      
 -- WHEN TYPE_ESTAB.CODE = 'PF' THEN '8999'      
 -- ELSE VW_COMPANY_EC_BR_DEP_EQUIP.MCC      
 --END AS MCC_PARAM      
   ,EC_PARAM.CODE AS MERCHANT_CODE_PARAM  
   ,LEFT([dbo].[FNC_REMOV_CARAC_ESP](ADD_EC_PARAM.[ADDRESS]), 20) AS [ADDRESS_PARAM]  
   ,[dbo].[FNC_REMOV_LETRAS](  
 [dbo].FNC_REMOV_CARAC_ESP(ADD_EC_PARAM.[NUMBER])) AS [NUMBER_PARAM]  
   ,ADD_EC_PARAM.CEP AS CEP_PARAM  
   ,ISNULL([dbo].[FNC_REMOV_CARAC_ESP](ADD_EC_PARAM.COMPLEMENT), 0) AS COMPLEMENT_PARAM  
   ,[dbo].[FNC_REMOV_CARAC_ESP](ENIGH_EC_PARAM.NAME) AS NEIGHBORDHOOD_PARAM  
   ,[dbo].[FNC_REMOV_CARAC_ESP](CITY_EC_PARAM.[NAME]) AS CITY_PARAM  
   ,[dbo].[FNC_REMOV_CARAC_ESP]([STATE_EC_PARAM].UF) AS [STATE_PARAM]  
   ,COUNTRY_EC_PARAM.INITIALS AS INITIALS_PARAM  
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
LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PARAM  
 ON EC_PARAM.CODE = ISNULL(@MID, 0)  
  AND EC_PARAM.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR  
LEFT JOIN BRANCH_EC BRANCH_PARAM  
 ON EC_PARAM.COD_EC = BRANCH_PARAM.COD_EC  
LEFT JOIN ADDRESS_BRANCH ADD_EC_PARAM  
 ON ADD_EC_PARAM.COD_BRANCH = BRANCH_PARAM.COD_BRANCH  
  AND ADD_EC_PARAM.ACTIVE = 1  
LEFT JOIN NEIGHBORHOOD ENIGH_EC_PARAM  
 ON ENIGH_EC_PARAM.COD_NEIGH = ADD_EC_PARAM.COD_NEIGH  
LEFT JOIN CITY CITY_EC_PARAM  
 ON CITY_EC_PARAM.COD_CITY = ENIGH_EC_PARAM.COD_CITY  
LEFT JOIN STATE STATE_EC_PARAM  
 ON STATE_EC_PARAM.COD_STATE = CITY_EC_PARAM.COD_STATE  
LEFT JOIN COUNTRY COUNTRY_EC_PARAM  
 ON COUNTRY_EC_PARAM.COD_COUNTRY = STATE_EC_PARAM.COD_COUNTRY  
WHERE VW_COMPANY_EC_BR_DEP_EQUIP.MERCHANT_CODE = @MID  
AND ASS_DEPTO_EQUIP.ACTIVE = 1  
ORDER BY ADDRESS_BRANCH.COD_ADDRESS DESC  
  
END  
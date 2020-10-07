IF (SELECT
			COUNT(*)
		FROM ITEMS_SERVICES_AVAILABLE isa
		WHERE isa.NAME = 'PIX')
	= 0
BEGIN
	INSERT INTO ITEMS_SERVICES_AVAILABLE (NAME, DESCRIPTION, CODE, ACTIVE)
		VALUES ('PIX', 'PIX', 20, 1);
END

GO

IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'PIX_ACCEPTED'
		AND object_id = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT'))
BEGIN
	ALTER TABLE COMMERCIAL_ESTABLISHMENT ADD PIX_ACCEPTED INT DEFAULT 0
END

GO

IF OBJECT_ID('SP_CONTACT_DATA_EQUIP') IS NOT NULL
	DROP PROCEDURE SP_CONTACT_DATA_EQUIP
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
------------------------------------------------------------------------------------------*/ (@TERMINALID INT)
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
	   ,(
		CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE COD_ITEM_SERVICE = 19
					AND ACTIVE = 1
					AND COD_EC = VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
					AND COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR)
				> 0 THEN 1
			ELSE 0
		END
		) AS PIX
	   ,ISNULL(COMMERCIAL_ESTABLISHMENT.PIX_ACCEPTED, 0) PIX_ACCEPTED
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

IF COL_LENGTH('BRAND', 'VISIBLE') IS NULL
	ALTER TABLE BRAND ADD VISIBLE INT DEFAULT 1

UPDATE BRAND
SET VISIBLE = 1
WHERE [NAME] <> 'PIX'

IF (SELECT
			COUNT(*)
		FROM BRAND b
		WHERE b.NAME = 'PIX')
	= 0
	INSERT INTO BRAND (NAME, [GROUP], COD_TTYPE, COD_TYPE_BRAND, GEN_TITLES, AVAILABLE_ONLINE, VISIBLE)
		VALUES ('PIX', 'PIX', 2, 2, 0, 0, 0)

GO

IF OBJECT_ID('SP_LS_BRAND') IS NOT NULL
	DROP PROCEDURE SP_LS_BRAND
GO
CREATE PROCEDURE [dbo].[SP_LS_BRAND]
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_LS_BRAND]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author                          VERSION        Date                            Description    
------------------------------------------------------------------------------------------    
Kennedy Alef     V1    27/07/2018      Creation    
------------------------------------------------------------------------------------------*/ (@COD_COMP INT)
AS
BEGIN
	SELECT
		BRAND.[NAME] AS BRAND
	   ,COD_BRAND AS BRANDINSIDECODE
	   ,COD_TTYPE AS TRANSACTIONTYPEINSIDECODE
	   ,[GROUP] AS BRAND_GROUP
	   ,TYPE_BRAND.NAME AS 'TYPE_BRAND'
	   ,AVAILABLE_ONLINE [AvailableOnline]
	FROM BRAND
	INNER JOIN TYPE_BRAND
		ON TYPE_BRAND.COD_TYPE_BRAND = BRAND.COD_TYPE_BRAND
	WHERE BRAND.VISIBLE = 1;
END

GO

SP_HELPTEXT 
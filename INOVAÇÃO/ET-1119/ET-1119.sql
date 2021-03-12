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

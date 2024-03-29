IF ( SELECT
		COUNT(*)
	FROM ASS_TR_TYPE_COMP
	WHERE COD_AC = 4)
= 0
BEGIN

DELETE FROM ASS_TR_TYPE_COMP
WHERE COD_AC = 4
INSERT INTO ASS_TR_TYPE_COMP (CREATED_AT, COD_USER, COD_TTYPE, COD_AC, COD_COMP, ACTIVE, CODE, TAX_VALUE, PLOT_INI, PLOT_END, INTERVAL, COD_BRAND, AVAILABLE, COD_SOURCE_TRAN)
	SELECT
		CURRENT_TIMESTAMP
	   ,63
	   ,2
	   ,4
	   ,8
	   ,1
	   ,01
	   ,1.10
	   ,1
	   ,1
	   ,1
	   ,COD_BRAND
	   ,1
	   ,2
	FROM BRAND
	WHERE COD_TTYPE = 2


INSERT INTO ASS_TR_TYPE_COMP (CREATED_AT, COD_USER, COD_TTYPE, COD_AC, COD_COMP, ACTIVE, CODE, TAX_VALUE, PLOT_INI, PLOT_END, INTERVAL, COD_BRAND, AVAILABLE, COD_SOURCE_TRAN)
	SELECT
		CURRENT_TIMESTAMP
	   ,63
	   ,1
	   ,4
	   ,8
	   ,1
	   ,01
	   ,2.09
	   ,1
	   ,1
	   ,1
	   ,COD_BRAND
	   ,1
	   ,2
	FROM BRAND
	WHERE COD_TTYPE = 1


INSERT INTO ASS_TR_TYPE_COMP (CREATED_AT, COD_USER, COD_TTYPE, COD_AC, COD_COMP, ACTIVE, CODE, TAX_VALUE, PLOT_INI, PLOT_END, INTERVAL, COD_BRAND, AVAILABLE, COD_SOURCE_TRAN)
	SELECT
		CURRENT_TIMESTAMP
	   ,63
	   ,1
	   ,4
	   ,8
	   ,1
	   ,01
	   ,2.34
	   ,2
	   ,6
	   ,1
	   ,COD_BRAND
	   ,1
	   ,2
	FROM BRAND
	WHERE COD_TTYPE = 1

INSERT INTO ASS_TR_TYPE_COMP (CREATED_AT, COD_USER, COD_TTYPE, COD_AC, COD_COMP, ACTIVE, CODE, TAX_VALUE, PLOT_INI, PLOT_END, INTERVAL, COD_BRAND, AVAILABLE, COD_SOURCE_TRAN)
	SELECT
		CURRENT_TIMESTAMP
	   ,63
	   ,1
	   ,4
	   ,8
	   ,1
	   ,01
	   ,2.60
	   ,7
	   ,12
	   ,1
	   ,COD_BRAND
	   ,1
	   ,2
	FROM BRAND
	WHERE COD_TTYPE = 1
END
GO

UPDATE ACQUIRER
SET ACTIVE = 1
WHERE COD_AC = 4
GO
IF OBJECT_ID('SP_DATA_COMP_ACQ') IS NOT NULL DROP PROCEDURE SP_DATA_COMP_ACQ;
GO
CREATE PROCEDURE [dbo].[SP_DATA_COMP_ACQ]  
/*----------------------------------------------------------------------------------------                 
Procedure Name: [SP_DATA_COMP_ACQ]                 
Project.......: TKPP                 
------------------------------------------------------------------------------------------                 
Author           VERSION           Date               Description                 
------------------------------------------------------------------------------------------                 
Kennedy Alef        V1           27/07/2018             Creation                 
Caike Uch�a         V2           15/01/2020         Tirar join segments              
------------------------------------------------------------------------------------------*/ (@TERMINALID INT,  
@ACQUIRER_NAME VARCHAR(100),  
@SERVICE INT = NULL,  
@COD_PRD_TRAN INT = NULL,  
@COD_PRD_ACQ_OLD INT = NULL,  
@NSU VARCHAR(400) = NULL)  
AS  
  
 DECLARE @ACQ INT;
  
 DECLARE @TID_NUMBER VARCHAR(400);
  
 BEGIN
  
  
  
  IF UPPER(@ACQUIRER_NAME) = 'PAGSEGURO'  
  BEGIN
  
  
   IF (@NSU IS NOT NULL)
SELECT
	@TID_NUMBER = t.LOGICAL_NUMBER_ACQ
FROM [TRANSACTION] t WITH (NOLOCK)
WHERE CODE = @NSU

IF @COD_PRD_TRAN IS NOT NULL
BEGIN


WITH CTE
AS
(SELECT
		--MERCHANT_LOGICALNUMBERS_ACQ.[NAME]         
		MERCHANT_LOGICALNUMBERS_ACQ.COD_EC AS [VALUE]
	   ,ISNULL(@TID_NUMBER, MERCHANT_LOGICALNUMBERS_ACQ.LOGICAL_NUMBER_ACQ) TID_VALUE
	   ,'' ALIAS
	   ,'PagSeguro' SUBTITLE
	   ,(SELECT
				(SELECT
						PRD_NEW.COD_PR_ACQ
					FROM PRODUCTS_ACQUIRER PRD_NEW
					WHERE COD_AC = ACQUIRER.COD_AC
					AND PRODUCTS_ACQUIRER.[COD_TTYPE] = PRD_NEW.[COD_TTYPE]
					AND PRODUCTS_ACQUIRER.[NAME] = PRD_NEW.[NAME]
					AND PRODUCTS_ACQUIRER.[EXTERNALCODE] = PRD_NEW.[EXTERNALCODE]
					AND PRODUCTS_ACQUIRER.[COD_BRAND] = PRD_NEW.COD_BRAND
					AND PRODUCTS_ACQUIRER.[PLOT_VALUE] = PRD_NEW.PLOT_VALUE
					AND ISNULL(PRODUCTS_ACQUIRER.[IS_SIMULATED], 0) = ISNULL(PRD_NEW.IS_SIMULATED, 0)
					AND PRODUCTS_ACQUIRER.[COD_SOURCE_TRAN] = PRD_NEW.COD_SOURCE_TRAN
					AND PRODUCTS_ACQUIRER.[VISIBLE] = PRD_NEW.VISIBLE)
			FROM PRODUCTS_ACQUIRER
			WHERE PRODUCTS_ACQUIRER.COD_PR_ACQ = @COD_PRD_ACQ_OLD)
		AS COD_PRD_ACQ
	   ,MERCHANT_LOGICALNUMBERS_ACQ.COD_EC AS MERCHANT
	FROM MERCHANT_LOGICALNUMBERS_ACQ
	JOIN TRANSACTION_PRODUCTS
		ON TRANSACTION_PRODUCTS.COD_EC = MERCHANT_LOGICALNUMBERS_ACQ.COD_EC
	JOIN ACQUIRER
		ON ACQUIRER.COD_AC = MERCHANT_LOGICALNUMBERS_ACQ.COD_AC
	WHERE TRANSACTION_PRODUCTS.COD_TRAN_PROD = @COD_PRD_TRAN)
SELECT
	'PAGSEGUROCODE' AS NAME_DATA
   ,CTE.*
FROM CTE
UNION
SELECT
	'SOFTDESCRIPTOR' AS NAME_DATA
   ,CTE.*
FROM CTE


END
ELSE
BEGIN

SELECT
	DADOS_COMP_ACQ.NAME AS NAME_DATA
   ,CASE
		WHEN @SERVICE IS NULL THEN CONVERT(VARCHAR(100), [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC)
		ELSE 2
	END AS VALUE
   ,ISNULL(@TID_NUMBER, (SELECT TOP 1
			DATA_EQUIPMENT_AC.CODE
		FROM DATA_EQUIPMENT_AC
		JOIN ACQUIRER
			ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
		WHERE DATA_EQUIPMENT_AC.ACTIVE = 1
		AND UPPER(ACQUIRER.[GROUP]) = 'pagseguro'
		AND DATA_EQUIPMENT_AC.COD_EQUIP = [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
	--AND ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP              
	)
	)
	AS TID_VALUE
   ,ACQUIRER.ALIAS
   ,ACQUIRER.SUBTITLE
   ,CASE
		WHEN @SERVICE IS NOT NULL THEN 2
		ELSE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
	END AS MERCHANT
FROM DADOS_COMP_ACQ
INNER JOIN ASS_TR_TYPE_COMP
	ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = DADOS_COMP_ACQ.COD_ASS_TR_COMP
INNER JOIN [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ]
	ON [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_COMP = ASS_TR_TYPE_COMP.COD_COMP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
WHERE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP = @TERMINALID
AND ASS_TR_TYPE_COMP.ACTIVE = 1
AND ACQUIRER.COD_AC = 10
GROUP BY DADOS_COMP_ACQ.NAME
		,DADOS_COMP_ACQ.VALUE
		,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
		,ACQUIRER.ALIAS
		,ACQUIRER.SUBTITLE
		,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
END;
END;

IF UPPER(@ACQUIRER_NAME) = 'ADIQ'
BEGIN

SELECT
	DADOS_COMP_ACQ.NAME AS NAME_DATA
   ,DADOS_COMP_ACQ.VALUE
   ,DATA_EQUIPMENT_AC.CODE AS TID_VALUE
   ,ACQUIRER.ALIAS
   ,ACQUIRER.SUBTITLE
   ,CASE
		WHEN @SERVICE IS NOT NULL THEN 2
		ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
	END AS MERCHANT
FROM DADOS_COMP_ACQ
INNER JOIN ASS_TR_TYPE_COMP
	ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = DADOS_COMP_ACQ.COD_ASS_TR_COMP
INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
	ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_COMP = ASS_TR_TYPE_COMP.COD_COMP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
LEFT JOIN DATA_EQUIPMENT_AC
	ON DATA_EQUIPMENT_AC.COD_AC = ACQUIRER.COD_AC
WHERE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
AND ASS_TR_TYPE_COMP.ACTIVE = 1
AND ACQUIRER.NAME = @ACQUIRER_NAME
GROUP BY DADOS_COMP_ACQ.NAME
		,DADOS_COMP_ACQ.VALUE
		,VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
		,DATA_EQUIPMENT_AC.CODE
		,ACQUIRER.ALIAS
		,ACQUIRER.SUBTITLE
UNION
SELECT
	'BONSUCESSOCODE' AS NAME_DATA
   ,EXTERNAL_DATA_EC_ACQ.[VALUE] AS VALUE
   ,'1' AS TID_VALUE
   ,ACQUIRER.ALIAS
   ,ACQUIRER.SUBTITLE
   ,CASE
		WHEN @SERVICE IS NOT NULL THEN 2
		ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
	END AS MERCHANT
FROM EXTERNAL_DATA_EC_ACQ
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = EXTERNAL_DATA_EC_ACQ.COD_AC
INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
	ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC = EXTERNAL_DATA_EC_ACQ.COD_EC
WHERE EXTERNAL_DATA_EC_ACQ.ACTIVE = 1
AND VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
AND ACQUIRER.NAME = @ACQUIRER_NAME
AND EXTERNAL_DATA_EC_ACQ.[NAME] = 'MID'
--AND EXTERNAL_DATA_EC_ACQ.[NAME]= 'TID';                 


END;

IF UPPER(@ACQUIRER_NAME) = 'STONE'

BEGIN

SELECT
	DADOS_COMP_ACQ.NAME AS NAME_DATA
   ,DADOS_COMP_ACQ.[VALUE] AS VALUE
   ,(SELECT
			DATA_EQUIPMENT_AC.CODE
		FROM DATA_EQUIPMENT_AC
		INNER JOIN ACQUIRER
			ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
		WHERE DATA_EQUIPMENT_AC.COD_EQUIP =
		[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
		AND DATA_EQUIPMENT_AC.ACTIVE = 1
		AND UPPER(ACQUIRER.NAME) = UPPER(@ACQUIRER_NAME))
	AS TID_VALUE
   ,ACQUIRER.ALIAS
   ,ACQUIRER.SUBTITLE
   ,CASE
		WHEN @SERVICE IS NOT NULL THEN 2
		ELSE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
	END AS MERCHANT
FROM DADOS_COMP_ACQ
INNER JOIN ASS_TR_TYPE_COMP
	ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP =
		DADOS_COMP_ACQ.COD_ASS_TR_COMP
INNER JOIN [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ]
	ON [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_COMP =
		ASS_TR_TYPE_COMP.COD_COMP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
WHERE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP = @TERMINALID
AND ASS_TR_TYPE_COMP.ACTIVE = 1
AND ACQUIRER.NAME = @ACQUIRER_NAME
GROUP BY DADOS_COMP_ACQ.NAME
		,DADOS_COMP_ACQ.VALUE
		,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
		,ACQUIRER.ALIAS
		,ACQUIRER.SUBTITLE
		,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP


END;

IF UPPER(@ACQUIRER_NAME) LIKE '%SOFTCRED%'

BEGIN


SELECT
	DADOS_COMP_ACQ.NAME AS NAME_DATA
   ,DADOS_COMP_ACQ.VALUE
   ,DATA_EQUIPMENT_AC.CODE AS TID_VALUE
   ,ACQUIRER.ALIAS
   ,ACQUIRER.SUBTITLE
   ,CASE
		WHEN @SERVICE IS NOT NULL THEN 2
		ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
	END AS MERCHANT
FROM DADOS_COMP_ACQ
INNER JOIN ASS_TR_TYPE_COMP
	ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = DADOS_COMP_ACQ.COD_ASS_TR_COMP
INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
	ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_COMP = ASS_TR_TYPE_COMP.COD_COMP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
LEFT JOIN DATA_EQUIPMENT_AC
	ON DATA_EQUIPMENT_AC.COD_AC = ACQUIRER.COD_AC
WHERE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
AND ASS_TR_TYPE_COMP.ACTIVE = 1
AND ACQUIRER.NAME = @ACQUIRER_NAME
GROUP BY DADOS_COMP_ACQ.NAME
		,DADOS_COMP_ACQ.VALUE
		,VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
		,DATA_EQUIPMENT_AC.CODE
		,ACQUIRER.ALIAS
		,ACQUIRER.SUBTITLE
UNION
SELECT
	EXTERNAL_DATA_EC_ACQ.NAME AS NAME_DATA
   ,EXTERNAL_DATA_EC_ACQ.[VALUE] AS VALUE
   ,'1' AS TID_VALUE
   ,ACQUIRER.ALIAS
   ,ACQUIRER.SUBTITLE
   ,CASE
		WHEN @SERVICE IS NOT NULL THEN 2
		ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
	END AS MERCHANT
FROM EXTERNAL_DATA_EC_ACQ
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_AC = EXTERNAL_DATA_EC_ACQ.COD_AC
INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
	ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC = EXTERNAL_DATA_EC_ACQ.COD_EC
WHERE EXTERNAL_DATA_EC_ACQ.ACTIVE = 1
AND VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
AND ACQUIRER.NAME = @ACQUIRER_NAME;


END;

IF UPPER(@ACQUIRER_NAME) = 'ITSPAY'
BEGIN

SELECT
	'260200000000000' AS LOGICAL_NUMBER
END;

IF @ACQUIRER_NAME = 'Cielo Presencial'
	OR @ACQUIRER_NAME = 'Cielo'

SELECT
	'Cielo' AS ALIAS
   ,'Cielo' AS SUBTITLE
   ,'' AS NAME_DATA
   ,'' AS [VALUE]

IF @ACQUIRER_NAME = 'GLOBAL PAYMENTS'
	OR @ACQUIRER_NAME = 'GLOBALPAYMENTS'
BEGIN

SELECT
	'MID' AS 'NAME'
	--,'012043412506001' AS 'CODE'
   ,(SELECT
			ACQUIRER_KEYS_CREDENTIALS.[VALUE]
		FROM ACQUIRER_KEYS_CREDENTIALS
		JOIN COMMERCIAL_ESTABLISHMENT
			ON COMMERCIAL_ESTABLISHMENT.CODE = ACQUIRER_KEYS_CREDENTIALS.CODE_EC
		WHERE COD_AC = 3
		AND ACQUIRER_KEYS_CREDENTIALS.ACTIVE = 1
		AND ACQUIRER_KEYS_CREDENTIALS.[NAME] = 'MID_PRESENCIAL')
	AS CODE
   ,'GLOBAL PAYMENTS' AS 'ACQ_NAME'
   ,@TERMINALID AS 'COD_EQUIP'

END


END;


GO

UPDATE PRODUCTS_ACQUIRER
SET COD_AC = NULL
   ,VISIBLE = 0
WHERE COD_AC = 4

IF ( SELECT
		COUNT(*)
	FROM PRODUCTS_ACQUIRER
	WHERE COD_AC = 4)
= 0
BEGIN
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� vista', '003/01/A0000000041010', 2, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado', '003/03/A0000000041010', 2, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (2, 4, 'D�bito', '004/50/A0000000043060;A0000000041010D07612;A0000000041010D07613', 1, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� vista', '001/01/A0000000031010', 3, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado', '001/03/A0000000031010', 3, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (2, 4, 'D�bito', '002/50/A0000000032010', 4, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� vista', '007/01/A00000000305076010;A0000004941010', 5, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado', '007/03/A00000000305076010;A0000004941010', 5, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (2, 4, 'D�bito', '008/50/A00000000305076020;A0000004942010', 6, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� vista ', '999/01', 7, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado ', '999/03', 7, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - Cliente', '001/03/A0000000031010', 3, 2, 1, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado sem juros Cliente', '001/03/A0000000031010', 3, 2, 0, 2, 0)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - Cliente', '003/03/A0000000041010', 2, 2, 1, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado sem juros Cliente', '003/03/A0000000041010', 2, 2, 0, 2, 0)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - Cliente', '007/03/A00000000305076010;A0000004941010', 5, 2, 1, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado sem juros Cliente', '007/03/A00000000305076010;A0000004941010', 5, 2, 0, 2, 0)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� vista', '005/01/A0000004421010', 15, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado', '005/03/A0000004421010', 15, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (2, 4, 'D�bito', '006/50/A0000004422010', 16, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - Cliente', '005/03/A0000004421010', 15, 2, 1, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� vista - AMEX', '009/01/A00000002501', 14, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - AMEX', '009/03/A00000002501', 14, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - Cliente', '009/03/A00000002501', 14, 2, 1, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, '� visa - HIPER', '014/01/A0000000041010', 7, 1, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado - HIPER', '014/03/A0000000041010', 7, 2, 0, 2, 1)
INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	VALUES (1, 4, 'Parcelado Cliente - HIPER', '014/03/A0000000041010', 7, 2, 1, 2, 1)
END
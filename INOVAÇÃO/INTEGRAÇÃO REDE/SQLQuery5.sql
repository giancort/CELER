IF OBJECT_ID('SP_FD_DATA_TRAN_OPER') IS NOT NULL DROP PROCEDURE SP_FD_DATA_TRAN_OPER
GO
CREATE PROCEDURE [dbo].[SP_FD_DATA_TRAN_OPER]          
(          
@NSU INT = null,          
@COD_EQUIP INT  ,        
@TRANSACTION_CODE VARCHAR(100) = NULL        
)          
AS          
BEGIN
          
          
IF @NSU IS NOT NULL        
BEGIN

SELECT
	[TRANSACTION].COD_TRAN
   ,[TRANSACTION].COD_TTYPE
   ,SITUATION.NAME AS SITUATION
   ,ASS_DEPTO_EQUIP.COD_EQUIP
   ,ACQUIRER.[GROUP] AS ACQUIRER
   ,EQUIPMENT_DATE
   ,AMOUNT
   ,TRANSACTION_DATA_EXT.NAME
   ,TRANSACTION_DATA_EXT.VALUE
   ,EQUIPMENT.SERIAL
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM TRANSACTION_TITLES
				WHERE TRANSACTION_TITLES.COD_TRAN = [TRANSACTION].COD_TRAN
				AND TRANSACTION_TITLES.COD_SITUATION = 8)
			> 0 THEN 'PAID'
		ELSE ''
	END AS PAID_SITUATION
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN ASS_DEPTO_EQUIP
	ON [TRANSACTION].COD_ASS_DEPTO_TERMINAL = ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
INNER JOIN SITUATION
	ON [TRANSACTION].COD_SITUATION = SITUATION.COD_SITUATION
INNER JOIN PRODUCTS_ACQUIRER
	ON [TRANSACTION].COD_PR_ACQ = PRODUCTS_ACQUIRER.COD_PR_ACQ
INNER JOIN ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_AC = ACQUIRER.COD_AC
LEFT JOIN TRANSACTION_DATA_EXT WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_DATA_EXT.COD_TRAN
INNER JOIN EQUIPMENT
	ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
WHERE EQUIPMENT.COD_EQUIP = @COD_EQUIP
AND [TRANSACTION].COD_TRAN = @TRANSACTION_CODE

END;

ELSE

SELECT
	[TRANSACTION].COD_TRAN
   ,[TRANSACTION].COD_TTYPE
   ,SITUATION.NAME AS SITUATION
   ,ASS_DEPTO_EQUIP.COD_EQUIP
   ,ACQUIRER.[GROUP] AS ACQUIRER
   ,EQUIPMENT_DATE
   ,AMOUNT
   ,TRANSACTION_DATA_EXT.NAME
   ,TRANSACTION_DATA_EXT.VALUE
   ,EQUIPMENT.SERIAL
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM TRANSACTION_TITLES
				WHERE TRANSACTION_TITLES.COD_TRAN = [TRANSACTION].COD_TRAN
				AND TRANSACTION_TITLES.COD_SITUATION = 8)
			> 0 THEN 'PAID'
		ELSE ''
	END AS PAID_SITUATION
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN ASS_DEPTO_EQUIP
	ON [TRANSACTION].COD_ASS_DEPTO_TERMINAL = ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
INNER JOIN SITUATION
	ON [TRANSACTION].COD_SITUATION = SITUATION.COD_SITUATION
INNER JOIN PRODUCTS_ACQUIRER
	ON [TRANSACTION].COD_PR_ACQ = PRODUCTS_ACQUIRER.COD_PR_ACQ
INNER JOIN ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_AC = ACQUIRER.COD_AC
LEFT JOIN TRANSACTION_DATA_EXT WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = TRANSACTION_DATA_EXT.COD_TRAN
INNER JOIN EQUIPMENT
	ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
WHERE EQUIPMENT.COD_EQUIP = @COD_EQUIP
AND [TRANSACTION].CODE = @TRANSACTION_CODE

END;
UPDATE [TRANSACTION]
SET [TRANSACTION].COD_ASS_TR_COMP = (SELECT
			ISNULL(ASS_TR_TYPE_COMP.COD_ASS_TR_COMP, 0)
		FROM ASS_TR_TYPE_COMP
		INNER JOIN TRANSACTION_TYPE
			ON TRANSACTION_TYPE.COD_TTYPE = ASS_TR_TYPE_COMP.COD_TTYPE
		INNER JOIN ACQUIRER
			ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
		INNER JOIN BRAND
			ON BRAND.COD_BRAND = ASS_TR_TYPE_COMP.COD_BRAND
		WHERE TRANSACTION_TYPE.COD_TTYPE = [TRANSACTION].COD_TTYPE
		AND ASS_TR_TYPE_COMP.COD_COMP = 8
		AND ASS_TR_TYPE_COMP.PLOT_INI <= [TRANSACTION].PLOTS
		AND ASS_TR_TYPE_COMP.PLOT_END >= [TRANSACTION].PLOTS
		AND BRAND.[NAME] = [TRANSACTION].BRAND
		AND ASS_TR_TYPE_COMP.ACTIVE = 1
		AND ASS_TR_TYPE_COMP.COD_SOURCE_TRAN = 1
		--AND ASS_TR_TYPE_COMP.TAX_VALUE>0     
		AND ASS_TR_TYPE_COMP.COD_AC = 8)
   ,[TRANSACTION].COD_PR_ACQ = PRODUCTS_ACQUIRER.COD_PR_ACQ
FROM [TRANSACTION]
LEFT JOIN ASS_DEPTO_EQUIP
	ON [TRANSACTION].COD_ASS_DEPTO_TERMINAL = ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
LEFT JOIN EQUIPMENT
	ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
LEFT JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].COD_TTYPE = [TRANSACTION].COD_TTYPE
LEFT JOIN BRAND
	ON BRAND.NAME = [TRANSACTION].BRAND
LEFT JOIN PRODUCTS_ACQUIRER
	ON PRODUCTS_ACQUIRER.COD_AC = 8
	AND PRODUCTS_ACQUIRER.COD_TTYPE = [TRANSACTION].COD_TTYPE
	AND PRODUCTS_ACQUIRER.COD_BRAND = BRAND.COD_BRAND
	AND PRODUCTS_ACQUIRER.NAME LIKE (CASE
		WHEN [TRANSACTION].PLOTS = 1 THEN '%VISTA%'
		ELSE 'Parcelado sem juros%'
	END)
LEFT JOIN ACQUIRER
	ON ACQUIRER.COD_AC = PRODUCTS_ACQUIRER.COD_AC
LEFT JOIN CURRENCY
	ON [TRANSACTION].COD_CURRRENCY = CURRENCY.COD_CURRRENCY
LEFT JOIN SITUATION
	ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION
LEFT JOIN TRADUCTION_SITUATION
	ON TRADUCTION_SITUATION.COD_SITUATION = SITUATION.COD_SITUATION
LEFT JOIN POSWEB_DATA_TRANSACTION
	ON POSWEB_DATA_TRANSACTION.COD_TRAN = [TRANSACTION].COD_TRAN
WHERE [TRANSACTION].COD_PR_ACQ IS NULL
AND [TRANSACTION].COD_SITUATION = 3
AND [TRANSACTION].COD_SOURCE_TRAN = 1
AND CAST([dbo].[FN_FUS_UTF](ISNULL([TRANSACTION].CREATED_AT, [TRANSACTION].CREATED_AT)) AS DATETIME) BETWEEN '2019-08-14 00:00:00' AND '2019-08-15 23:59:59'
AND [TRANSACTION].BRAND <> 'CELER CREDITO';

GO

UPDATE PROCESS_BG_STATUS
SET STATUS_PROCESSED = 0
FROM PROCESS_BG_STATUS
INNER JOIN SOURCE_PROCESS
	ON PROCESS_BG_STATUS.COD_SOURCE_PROCESS = SOURCE_PROCESS.COD_SOURCE_PROCESS
INNER JOIN [TRANSACTION]
	ON [TRANSACTION].COD_TRAN = PROCESS_BG_STATUS.CODE
WHERE [TRANSACTION].CODE
IN
(
'15658167542821107'
, '15658187037626585'
, '15658204764850225'
, '15658208682174765'
, '15658223495719375'
, '15658240805083198'
, '15658257488799358'
, '15658276755395744'
, '15658710513321260'
, '15658722733832374'
, '15658723397532511'
)
AND PROCESS_BG_STATUS.STATUS_PROCESSED = 1
;


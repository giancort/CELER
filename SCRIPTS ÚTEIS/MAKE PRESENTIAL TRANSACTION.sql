DECLARE @COD_EQUIP INT;
DECLARE @COD_EC INT;
DECLARE @COD_PR_ACQ INT;
DECLARE @COD_BRAND INT;
DECLARE @BRAND VARCHAR(100);
DECLARE @COD_BRANCH INT;
DECLARE @TYPE_TRAN VARCHAR(100);

SELECT
	@COD_EQUIP = COD_EQUIP
   ,@COD_EC = COD_EC
   ,@COD_BRANCH = COD_BRANCH
FROM VW_COMPANY_EC_AFF_BR_DEP_EQUIP
WHERE SERIAL = '7C572369'

SELECT
	@COD_PR_ACQ = COD_PR_ACQ
   ,@COD_BRAND = BRAND.COD_BRAND
   ,@BRAND = BRAND.[NAME]
   ,@TYPE_TRAN = TRANSACTION_TYPE.[NAME]
FROM PRODUCTS_ACQUIRER
JOIN BRAND
	ON BRAND.COD_BRAND = PRODUCTS_ACQUIRER.COD_BRAND
JOIN ACQUIRER
	ON ACQUIRER.COD_AC = PRODUCTS_ACQUIRER.COD_AC
JOIN TRANSACTION_TYPE
	ON TRANSACTION_TYPE.COD_TTYPE = PRODUCTS_ACQUIRER.COD_TTYPE
WHERE ACQUIRER.COD_AC = 1
AND TRANSACTION_TYPE.CODE = 'DEBITO'
AND BRAND.[GROUP] = 'MASTER'
AND PLOT_VALUE = 1
AND COD_SOURCE_TRAN = 2
AND IS_SIMULATED = 0

EXEC [SP_VALIDATE_TRANSACTION] @TERMINALID = @COD_EQUIP
							  ,@TYPETRANSACTION = @TYPE_TRAN
							  ,@AMOUNT = 100
							  ,@QTY_PLOTS = 1
							  ,@PAN = '64***6565'
							  ,@BRAND = @BRAND
							  ,@TRCODE = '1593107910104525000003'
							  ,@TERMINALDATE = NULL
							  ,@CODPROD_ACQ = @COD_PR_ACQ
							  ,@TYPE = 'TRANSACTION'
							  ,@COD_BRANCH = @COD_BRANCH
							  ,@CODE_SPLIT = NULL
							  ,@COD_EC = @COD_EC
							  ,@HOLDER_NAME = 'KENNEDY ALEF DE OLIVEIRA'
							  ,@HOLDER_DOC = NULL
							  ,@LOGICAL_NUMBER = NULL
							  ,@COD_TRAN_PROD = NULL
							  ,@COD_EC_PRD = NULL


--GO
DECLARE @COD_TRAN INT;
DECLARE @NSU VARCHAR(255);
SELECT TOP 1
	@NSU = CODE
   ,@COD_TRAN = COD_TRAN
FROM [TRANSACTION]
ORDER BY COD_TRAN DESC

--EXEC [SP_UP_TRANSACTION] @CODE_TRAN = @NSU
--						,@SITUATION = 'APPROVED'
--						,@DESCRIPTION = '100-APROVADA'
--						,@CURRENCY = NULL
--						,@CODE_ERROR = NULL
--						,@TRAN_ID = @COD_TRAN
--						,@LOGICAL_NUMBER_ACQ = NULL
--						,@CARD_HOLDER_NAME = ''
--						,@COD_USER = NULL
----GO
--EXEC SP_UP_TRANSACTION @CODE_TRAN = @NSU
--					  ,@SITUATION = 'CONFIRMED'
--					  ,@DESCRIPTION = '200-CONFIRMADA'
--					  ,@CURRENCY = NULL
--					  ,@CODE_ERROR = NULL
--					  ,@TRAN_ID = @COD_TRAN
--					  ,@LOGICAL_NUMBER_ACQ = NULL
--					  ,@CARD_HOLDER_NAME = ''
--					  ,@COD_USER = NULL
--GO

SELECT
	*
FROM [TRANSACTION_TITLES]
WHERE cod_tran = @cod_tran

EXEC SP_FD_PENDING_TITLES



EXEC SP_GEN_TITLES_TRANS '1593107910104525657299'
						,4377765

SP_HELPTEXT SP_FD_PENDING_TITLES
IF OBJECT_ID('SP_LS_ACQUIRERS_TEF_CONCILIATE') IS NOT NULL
DROP PROCEDURE SP_LS_ACQUIRERS_TEF_CONCILIATE
GO
CREATE PROCEDURE SP_LS_ACQUIRERS_TEF_CONCILIATE
AS
SELECT
	JSON_VALUE(CONFIG_JSON, '$.Acquirer[0].CodAc') AS COD_AC
   ,ACQUIRER.NAME
   ,ACQUIRER.[GROUP]
FROM SERVICES_AVAILABLE
JOIN ITEMS_SERVICES_AVAILABLE
	ON ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE = SERVICES_AVAILABLE.COD_ITEM_SERVICE
JOIN ACQUIRER
	ON ACQUIRER.COD_AC = JSON_VALUE(CONFIG_JSON, '$.Acquirer[0].CodAc')
WHERE ITEMS_SERVICES_AVAILABLE.[NAME] LIKE '%TEF%'
AND SERVICES_AVAILABLE.ACTIVE = 1
AND COD_EC IS NULL

GO
IF OBJECT_ID('SP_LS_AFF_TEF_CONCILIATE') IS NOT NULL
DROP PROCEDURE SP_LS_AFF_TEF_CONCILIATE
GO
CREATE PROCEDURE SP_LS_AFF_TEF_CONCILIATE (@COD_AC INT)
AS
SELECT
	AFFILIATOR.COD_AFFILIATOR
   ,AFFILIATOR.NAME
   ,AFFILIATOR.CPF_CNPJ
FROM SERVICES_AVAILABLE
JOIN ITEMS_SERVICES_AVAILABLE
	ON ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE = SERVICES_AVAILABLE.COD_ITEM_SERVICE
JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = SERVICES_AVAILABLE.COD_AFFILIATOR
WHERE ITEMS_SERVICES_AVAILABLE.[NAME] LIKE '%TEF%'
AND SERVICES_AVAILABLE.ACTIVE = 1
AND COD_EC IS NULL
AND JSON_VALUE(CONFIG_JSON, '$.Acquirer[0].CodAc') = @COD_AC


GO

IF OBJECT_ID('CONCILIATED_TEF_TRANSACTION') IS NOT NULL
DROP TABLE CONCILIATED_TEF_TRANSACTION
GO
CREATE TABLE CONCILIATED_TEF_TRANSACTION
(
	COD_CONC_TR INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	CREATED_AT DATETIME,
	TRANSACTION_DATE DATETIME,
	COD_AC INT FOREIGN KEY REFERENCES ACQUIRER (COD_AC),
	COD_TRAN INT FOREIGN KEY REFERENCES [TRANSACTION] (COD_TRAN),
	COD_USER INT FOREIGN KEY REFERENCES USERS (COD_USER),
	[ACTION] VARCHAR(255)
)


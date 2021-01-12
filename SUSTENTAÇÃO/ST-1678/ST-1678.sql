﻿UPDATE SEGMENTS
SET COD_SEG_GROUP = 5
FROM SEGMENTS
JOIN SEGMENTS_GROUP
	ON SEGMENTS.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP
JOIN ACQUIRER
	ON ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP
WHERE COD_AC = 28
AND SEGMENTS.NAME NOT LIKE '% - PS Transporte Terrestre%'

IF ( SELECT
		COUNT(*)
	FROM SEGMENTS
	WHERE [NAME] LIKE '% - PS Transporte Terrestre%')
= 0
BEGIN
INSERT INTO SEGMENTS (NAME, DESCRIPTION, ACTIVE, COD_COMP, COD_USER, CODE, COD_SEG_GROUP, LIMIT_TRANSACTION_MONTHLY, COD_BRANCH_BUSINESS, CNAE, VISIBLE)
	SELECT
		SEGMENTS.NAME + ' - PS Transporte Terrestre'
	   ,SEGMENTS.DESCRIPTION + ' - PS Transporte Terrestre'
	   ,SEGMENTS.ACTIVE
	   ,SEGMENTS.COD_COMP
	   ,SEGMENTS.COD_USER
	   ,SEGMENTS.CODE
	   ,15
	   ,SEGMENTS.LIMIT_TRANSACTION_MONTHLY
	   ,SEGMENTS.COD_BRANCH_BUSINESS
	   ,SEGMENTS.CNAE
	   ,SEGMENTS.VISIBLE
	FROM SEGMENTS
	WHERE COD_SEG = 1726
END
GO


UPDATE COMMERCIAL_ESTABLISHMENT
SET COD_SEG = (SELECT
		COD_SEG
	FROM SEGMENTS
	WHERE SEGMENTS.NAME LIKE '%- PS Transporte Terrestre%')
WHERE COD_EC = 22217

GO


--DECLARANDO VARIAVEIS
DECLARE @COD_AC2 INT;
 
DECLARE @COD_EQUIP INT;
DECLARE @COD_EC INT;
 
DECLARE @COD_COMP INT;
DECLARE @TID VARCHAR(200);

--CRIANDO UM CURSOR
DECLARE TIDREPROCESS CURSOR
FOR
SELECT
	ASS_DEPTO_EQUIP.COD_EQUIP
   ,COMMERCIAL_ESTABLISHMENT.COD_EC
   ,ACQUIRER.COD_AC
   ,COMMERCIAL_ESTABLISHMENT.COD_COMP
FROM COMMERCIAL_ESTABLISHMENT
JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
JOIN ACQUIRER
	ON ACQUIRER.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
JOIN BRANCH_EC
	ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
WHERE ACQUIRER.[NAME] = 'PagSeguro'
AND ASS_DEPTO_EQUIP.ACTIVE = 1
AND COMMERCIAL_ESTABLISHMENT.COD_SEG IN
(
297
, 1695
, 1726
, 1727
, 1728
, 1729
, 1730
, 1798
, 1799
, 1800
, 1801
, 1802
, 1803
, 1804
, 1805
, 1806
)
-- ABRINDO UM CURSOR

OPEN TIDREPROCESS

--SELECIONAR OS DADOS( busca o pr�ximo dado do cursor)

FETCH NEXT FROM TIDREPROCESS 
INTO @COD_EQUIP,@COD_EC, @COD_AC2,@COD_COMP;

-- itera��o entre os dados retornados pelo Cursor ( Enquanto tiver retornando dados, ele vai inserir as linhas)

WHILE @@FETCH_STATUS = 0
BEGIN

----Pegar os pr�ximos dados
SELECT
	@TID = CODE
FROM DATA_EQUIPMENT_AC
WHERE COD_EQUIP = @COD_EQUIP
AND COD_AC IN (SELECT
		COD_AC
	FROM ACQUIRER
	WHERE [GROUP] = 'PagSeguro')
AND ACTIVE = 1

UPDATE DATA_EQUIPMENT_AC
SET ACTIVE = 0
WHERE COD_EQUIP = @COD_EQUIP
AND ACTIVE = 1
AND CODE = @TID

UPDATE DATA_TID_AVAILABLE_EC
SET AVAILABLE = 1
FROM DATA_EQUIPMENT_AC
INNER JOIN DATA_TID_AVAILABLE_EC
	ON DATA_TID_AVAILABLE_EC.TID = DATA_EQUIPMENT_AC.CODE
WHERE DATA_TID_AVAILABLE_EC.TID = @TID
AND DATA_TID_AVAILABLE_EC.ACTIVE = 1
AND DATA_TID_AVAILABLE_EC.AVAILABLE = 0

--Verifica se o terminal possui rota     
IF (SELECT
			COUNT(*)
		FROM ROUTE_ACQUIRER
		WHERE COD_EQUIP = @COD_EQUIP
		AND ACTIVE = 1)
	> 0
BEGIN

-- Guarda a rota em uma tabela tempor�ria  
SELECT
	COD_USER
   ,COD_EQUIP
   ,CONF_TYPE
   ,COD_BRAND
   ,COD_SOURCE_TRAN INTO #ROUTES
FROM ROUTE_ACQUIRER
WHERE COD_EQUIP = @COD_EQUIP
AND ACTIVE = 1

--Inativa a rota cadastrada para este equipamento    
UPDATE ROUTE_ACQUIRER
SET ACTIVE = 0
   ,COD_USER_MODIFY = 474
   ,MODIFY_DATE = CURRENT_TIMESTAMP
WHERE COD_EQUIP = @COD_EQUIP;

-- Insere uma rota para o Equipamento com o novo Acquirer     
INSERT INTO ROUTE_ACQUIRER (COD_USER, COD_EQUIP, ACTIVE, CONF_TYPE, COD_BRAND, COD_AC, COD_SOURCE_TRAN)
	SELECT
		COD_USER
	   ,COD_EQUIP
	   ,1
	   ,CONF_TYPE
	   ,COD_BRAND
	   ,@COD_AC2
	   ,COD_SOURCE_TRAN
	FROM #ROUTES

DROP TABLE #ROUTES;

END
-- Gera novo TID para o equipamento

-- Chama a procedure para Registrar o TID  

EXEC SP_REG_ASS_TID_EQUIP_EC @COD_EQUIP = @COD_EQUIP
							,@COD_AC = @COD_AC2
							,@COD_EC = @COD_EC
							,@COD_COMP = @COD_COMP



FETCH NEXT FROM TIDREPROCESS
INTO @COD_EQUIP, @COD_EC, @COD_AC2, @COD_COMP;
--SELECT * FROM DATA_EQUIPMENT_AC WHERE CODE= @CODE AND ACTIVE= 1 AND COD_AC = 10

END

-- FECHANDO E DESALOCANDO O CURSOR DA MEM�RIA 

CLOSE TIDREPROCESS
DEALLOCATE TIDREPROCESS



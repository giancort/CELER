--ST-1612 / ST-1614

GO

IF OBJECT_ID('UP_STATUS_AWAITING_PAYMENT') IS NOT NULL
DROP PROCEDURE [UP_STATUS_AWAITING_PAYMENT];

GO
CREATE PROCEDURE [UP_STATUS_AWAITING_PAYMENT]
/*----------------------------------------------------------------------------------------                                                 
Procedure Name: [UP_STATUS_AWAITING_PAYMENT]                                                 
Project.......: TKPP                                                 
------------------------------------------------------------------------------------------                                                 
Author                 Version        Date           Description                                                 
------------------------------------------------------------------------------------------                                                 
Caike uchoa              v1        18/11/2020          CREATE
------------------------------------------------------------------------------------------*/            
(
@COD_TRAN INT,
@DESCRIPTION VARCHAR(200)
)
AS 
BEGIN

DECLARE @LEDGER_RETENTION INT;
DECLARE @GEN_TITLES INT;
DECLARE @CODEC INT;


SELECT 
  @CODEC = COMMERCIAL_ESTABLISHMENT.COD_EC
 ,@GEN_TITLES = BRAND.GEN_TITLES
FROM [TRANSACTION] WITH(NOLOCK)
JOIN [ASS_DEPTO_EQUIP] 
ON [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
JOIN DEPARTMENTS_BRANCH 
ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
JOIN BRANCH_EC 
ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
JOIN COMMERCIAL_ESTABLISHMENT
ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
JOIN BRAND ON BRAND.[NAME] = [TRANSACTION].BRAND
AND BRAND.COD_TTYPE = [TRANSACTION].COD_TTYPE
WHERE [TRANSACTION].COD_TRAN= @COD_TRAN
    

    SELECT @LEDGER_RETENTION = COUNT(*)      
    FROM SERVICES_AVAILABLE s      
             JOIN ITEMS_SERVICES_AVAILABLE item      
                  ON item.COD_ITEM_SERVICE = s.COD_ITEM_SERVICE      
    WHERE s.COD_EC = @CODEC      
      AND item.CODE = '8'      
      AND s.ACTIVE = 1    
	  
	  IF @LEDGER_RETENTION = 0 
	  BEGIN 

	  	UPDATE TRANSACTION_TITLES          
SET TRANSACTION_TITLES.COD_SITUATION = 4          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,COD_FIN_CALENDAR = NULL          
FROM TRANSACTION_TITLES WITH (NOLOCK)          
INNER JOIN [TRANSACTION]          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @COD_TRAN;     

	  END 
	  ELSE
	  BEGIN

	  DECLARE @COD_AWAIT_SPLIT INT;
      DECLARE @COD_AWAIT_PAY INT;
      DECLARE @COD_EXTERNAL_PROCESSING INT;
      DECLARE @TITLE_SIT INT;
      DECLARE @TEMP_TITLE_SIT INT;
      DECLARE @COD_CTRL INT;
      DECLARE @CONT INT;
      DECLARE @COD_TITLE INT;
      DECLARE @PREVISION_PAY_DATE DATETIME;
      DECLARE @COMMENT VARCHAR(200);

	  SELECT @COD_AWAIT_SPLIT = COD_SITUATION      
      FROM SITUATION      
      WHERE [NAME] = 'WAITING FOR SPLIT OF FINANCE SCHEDULE'      
      SELECT @COD_AWAIT_PAY = COD_SITUATION      
      FROM SITUATION      
      WHERE [NAME] = 'AWAITING PAYMENT'      
      SELECT @COD_EXTERNAL_PROCESSING = COD_SITUATION      
      FROM SITUATION      
      WHERE [NAME] = 'LIQUIDACAO PROCESSADORA'    

    IF @GEN_TITLES = 1      
        AND @LEDGER_RETENTION = 0      
        SET @TITLE_SIT = @COD_AWAIT_PAY;      
    ELSE      
        IF @GEN_TITLES <> 1      
            AND @LEDGER_RETENTION = 0      
            SET @TITLE_SIT = @COD_EXTERNAL_PROCESSING;      
        ELSE      
            SET @TITLE_SIT = @COD_AWAIT_SPLIT;      
      
    SET @TEMP_TITLE_SIT = @TITLE_SIT      
      
    CREATE TABLE #retentionRules      
    (      
        COD_RET_CTRL INT      NOT NULL,      
        FROM_DATE    DATETIME NOT NULL,      
        UNTIL_DATE   DATETIME NOT NULL      
    )      
      
    IF @TITLE_SIT = @COD_AWAIT_SPLIT      
        BEGIN      
            INSERT INTO #retentionRules (COD_RET_CTRL, FROM_DATE, UNTIL_DATE)      
            SELECT ctrl.COD_RET_CTRL      
                 , ctrl.FROM_DATE      
                 , ctrl.UNTIL_DATE      
            FROM LEDGER_RETENTION_CONTROL ctrl      
            WHERE ctrl.COD_EC = 20920      
              AND (ctrl.UNTIL_DATE IS NULL      
                OR ctrl.UNTIL_DATE >= CAST(GETDATE() AS DATE))      
        END      
      

   --CRIANDO UM CURSOR
   DECLARE TITLES_TRAN CURSOR
   FOR SELECT 
   COD_TITLE,
   PREVISION_PAY_DATE
   FROM TRANSACTION_TITLES WITH(NOLOCK)
   WHERE COD_TRAN = @COD_TRAN
   
   -- ABRINDO UM CURSOR
   
   OPEN TITLES_TRAN
   
   --SELECIONAR OS DADOS( busca o próximo dado do cursor)
   
   FETCH NEXT FROM TITLES_TRAN 
   INTO @COD_TITLE, @PREVISION_PAY_DATE;
   
   -- iteração entre os dados retornados pelo Cursor ( Enquanto tiver retornando dados, ele vai inserir as linhas)
   
   WHILE @@FETCH_STATUS = 0
   BEGIN 
   
      IF @TITLE_SIT != @TEMP_TITLE_SIT      
        SET @TITLE_SIT = @TEMP_TITLE_SIT;      
   
    SET @COD_CTRL = NULL      
   
    IF @TITLE_SIT = @COD_AWAIT_SPLIT      
        BEGIN      
            SELECT @COD_CTRL = COD_RET_CTRL      
            FROM #retentionRules r      
            WHERE @PREVISION_PAY_DATE BETWEEN r.FROM_DATE AND r.UNTIL_DATE      
   
            IF @COD_CTRL IS NULL      
                SET @TITLE_SIT = @COD_AWAIT_PAY      
        END     
   
   	SELECT @COMMENT = [NAME] 
   	FROM SITUATION 
   	WHERE COD_SITUATION = @TITLE_SIT
   
   UPDATE [TRANSACTION_TITLES]
   SET COD_SITUATION = @TITLE_SIT 
      ,MODIFY_DATE = GETDATE()          
      ,COMMENT = @COMMENT    
      ,COD_FIN_CALENDAR = NULL 
   WHERE COD_TITLE = @COD_TITLE
    
   
   FETCH NEXT FROM TITLES_TRAN 
   INTO @COD_TITLE, @PREVISION_PAY_DATE;
   
   END
   -- FECHANDO E DESALOCANDO O CURSOR DA MEMÓRIA 
   
   CLOSE TITLES_TRAN
   DEALLOCATE TITLES_TRAN
   
   
   END;
   
END;


GO

IF OBJECT_ID('SP_GEN_TITLES_TRANS') IS NOT NULL
DROP PROCEDURE [SP_GEN_TITLES_TRANS];

GO
CREATE PROCEDURE [dbo].[SP_GEN_TITLES_TRANS]      
/*----------------------------------------------------------------------------------------                                
    PROJECT.......: TKPP                                
------------------------------------------------------------------------------------------                                 
    AUTHOR                      VERSION     DATE            DESCRIPTION                                
------------------------------------------------------------------------------------------                                
    KENNEDY ALEF                V1          27/07/2018      CREATION                                
    KENNEDY ALEF                V2          27/08/2018      MODIFY                                
    FERNANDO HENRIQUE OLIVEIRA  V3          06/03/2019      MODIFY                                
    LUCAS AGUIAR                V4          2019-09-11      MODIFY                                
    LUCAS AGUIAR                V5          2019-09-30      WAITINGSPLIT                                
    LUIZ AQUINO                 V6          2019-11-01      Reteno de agenda                                
    Luiz Aquino                 V7          2020-06-26      ADD DZERO TAX (ET-895 PLANDZERO)      
	Caike Uchoa                 v8          2020-11-17      Add valid limit ec
------------------------------------------------------------------------------------------*/      
(@COD_TRAN VARCHAR(200),      
 @TRAN_ID INT = NULL)      
AS      
DECLARE @CONT INT;      
DECLARE @VALUE DECIMAL(22, 6);      
DECLARE @CODE BIGINT;      
DECLARE @PAYDAY DATETIME;      
DECLARE @PREVISION_PAY_DATE DATETIME      
DECLARE @PLOTS INT;      
DECLARE @AMOUNT DECIMAL(22, 6);      
DECLARE @CODASS_EQUIP INT;      
DECLARE @TAXINI DECIMAL(22, 6);      
DECLARE @TAXEFFETIVE DECIMAL(22, 6);      
DECLARE @RATE DECIMAL(22, 6);      
DECLARE @INTERVAL INT;      
DECLARE @TR_ID INT;      
DECLARE @TAX_ACQ DECIMAL(22, 6)      
DECLARE @TYPEPLAN INT      
DECLARE @INTERVALRECEIVE INT;      
DECLARE @RECEIVEDATE DATETIME;      
DECLARE @ANTICIPATION DECIMAL(22, 6);      
DECLARE @COD_AFFILIATOR INT;      
DECLARE @QTY_PLOTS INT;      
DECLARE @ANT_PERCENT DECIMAL(22, 6);      
DECLARE @COD_OPER_COST INT;      
DECLARE @OPER_VALUE DECIMAL(22, 6);      
DECLARE @PLAN INT;      
DECLARE @PERCENT DECIMAL(22, 6);      
DECLARE @COD_TTYPE INT;      
DECLARE @GEN_TITLES INT;      
DECLARE @RATE_PLAN_AFF DECIMAL(22, 6);      
DECLARE @ANTECIP_VALUE_AFF DECIMAL(22, 6);      
DECLARE @TITLE_SIT INT      
DECLARE @TEMP_TITLE_SIT INT      
DECLARE @SOURCE_TRAN INT      
DECLARE @BRAND_TRAN INT;      
DECLARE @COD_EC INT;      
DECLARE @COD_TX_EC INT;      
DECLARE @ANTECIP_PERCENT_EC DECIMAL(22, 6);      
DECLARE @TRANDATE DATETIME;      
DECLARE @LEDGER_RETENTION INT = 0;      
DECLARE @COD_CTRL INT = NULL;      
DECLARE @COD_AWAIT_SPLIT INT = NULL      
DECLARE @COD_AWAIT_PAY INT = NULL      
DECLARE @COD_EXTERNAL_PROCESSING INT = NULL      
DECLARE @HASPLANDZERO BIT = 0;      
DECLARE @PLANDZEROTAX DECIMAL(22, 6) = NULL      
DECLARE @PLANDZEROTAX_AFF DECIMAL(22, 6) = NULL      
DECLARE @PLANDZEROTODAY BIT = 0;      
DECLARE @CURRENTHOUR INT      
DECLARE @PlanDZeroHour INT = 0;      
DECLARE @COD_AC INT;      
DECLARE @COD_BRAND INT;      
DECLARE @TRAN_TYPE INT;      
DECLARE @COD_TITTLE_INSERTED INT;      
DECLARE      
    @OUTPUT_UR AS TABLE      
                  (      
                      COD_ASS    INT,      
                      COD_UR     INT,      
                      PREVISION  DATE,      
                      COD_TITTLE INT,      
                      COD_EC     INT      
                  )      
DECLARE @TP_REPROCESS TP_REPROCESS_BILL_TOPAY ;      
      
BEGIN      
      
    IF @TRAN_ID IS NULL      
        BEGIN      
            SELECT @PLOTS = [TRANSACTION].PLOTS      
                 , @AMOUNT = [TRANSACTION].AMOUNT      
                 , @CODASS_EQUIP = [TRANSACTION].COD_ASS_DEPTO_TERMINAL      
                 , @TAXEFFETIVE = ASS_TAX_DEPART.EFFECTIVE_PERCENTAGE      
                 , @TAXINI = ASS_TAX_DEPART.PARCENTAGE      
                 , @RATE = ASS_TAX_DEPART.RATE      
                 , @INTERVAL = ASS_TAX_DEPART.INTERVAL      
                 , @TR_ID = [TRANSACTION].COD_TRAN      
                 , @TAX_ACQ = ASS_TR_TYPE_COMP.TAX_VALUE      
                 , @TYPEPLAN = DEPARTMENTS_BRANCH.COD_T_PLAN      
                 , @INTERVALRECEIVE = ASS_TR_TYPE_COMP.INTERVAL      
                 , @ANTICIPATION = ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE      
                 , @COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR      
                 , @QTY_PLOTS = [TRANSACTION].PLOTS      
                 , @COD_TTYPE = [TRANSACTION].COD_TTYPE      
                 , @GEN_TITLES = [BRAND].[GEN_TITLES]      
                 , @ANT_PERCENT = ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE      
                 , @SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN      
                 , @BRAND_TRAN = [BRAND].COD_BRAND      
                 , @COD_EC = BRANCH_EC.COD_EC      
                 , @COD_TX_EC = [TRANSACTION].COD_ASS_TX_DEP      
                 , @TRANDATE = [TRANSACTION].BRAZILIAN_DATE      
                 , @COD_AC = PRODUCTS_ACQUIRER.COD_AC      
                 , @COD_BRAND = [BRAND].COD_BRAND      
                 , @TRAN_TYPE = [TRANSACTION].COD_TTYPE      
            FROM [TRANSACTION] WITH (NOLOCK)      
                     JOIN ASS_TAX_DEPART      
                          ON ASS_TAX_DEPART.COD_ASS_TX_DEP = [TRANSACTION].COD_ASS_TX_DEP      
                     JOIN DEPARTMENTS_BRANCH      
                          ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH      
                     JOIN BRANCH_EC      
                          ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH      
                     JOIN ASS_TR_TYPE_COMP      
                          ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = [TRANSACTION].COD_ASS_TR_COMP      
                     JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN      
                     JOIN [BRAND] ON BRAND.[NAME] = [TRANSACTION].BRAND      
                AND [BRAND].COD_TTYPE = [TRANSACTION].COD_TTYPE      
                     JOIN PRODUCTS_ACQUIRER      
                          ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ      
            WHERE [TRANSACTION].CODE = @COD_TRAN;      
        END;      
    ELSE      
        BEGIN      
            SELECT @PLOTS = [TRANSACTION].PLOTS      
                 , @AMOUNT = [TRANSACTION].AMOUNT      
                 , @CODASS_EQUIP = [TRANSACTION].COD_ASS_DEPTO_TERMINAL      
                 , @TAXEFFETIVE = ASS_TAX_DEPART.EFFECTIVE_PERCENTAGE      
                 , @TAXINI = ASS_TAX_DEPART.PARCENTAGE      
                 , @RATE = ASS_TAX_DEPART.RATE      
                 , @INTERVAL = ASS_TAX_DEPART.INTERVAL      
                 , @TR_ID = [TRANSACTION].COD_TRAN      
                 , @TAX_ACQ = ASS_TR_TYPE_COMP.TAX_VALUE      
                 , @TYPEPLAN = [PLAN].COD_T_PLAN      
                 , @INTERVALRECEIVE = ASS_TR_TYPE_COMP.INTERVAL      
                 , @ANTICIPATION = ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE      
                 , @COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR      
                 , @QTY_PLOTS = [TRANSACTION].PLOTS      
                 , @COD_TTYPE = [TRANSACTION].COD_TTYPE      
                 , @GEN_TITLES = [BRAND].[GEN_TITLES]      
                 , @ANT_PERCENT = ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE      
                 , @SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN      
                 , @BRAND_TRAN = [BRAND].COD_BRAND      
                 , @COD_EC = BRANCH_EC.COD_EC      
                 , @COD_TX_EC = [TRANSACTION].COD_ASS_TX_DEP      
                 , @TRANDATE = [TRANSACTION].BRAZILIAN_DATE      
                 , @COD_AC = PRODUCTS_ACQUIRER.COD_AC      
                 , @COD_BRAND = [BRAND].COD_BRAND      
                 , @TRAN_TYPE = [TRANSACTION].COD_TTYPE      
            FROM [TRANSACTION] WITH (NOLOCK)      
            INNER JOIN ASS_TAX_DEPART      
                                ON ASS_TAX_DEPART.COD_ASS_TX_DEP = [TRANSACTION].COD_ASS_TX_DEP      
                     INNER JOIN DEPARTMENTS_BRANCH      
                                ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH      
               INNER JOIN BRANCH_EC      
                                ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH      
                     INNER JOIN ASS_TR_TYPE_COMP      
                                ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = [TRANSACTION].COD_ASS_TR_COMP      
                     INNER JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN      
                     INNER JOIN [BRAND] ON BRAND.[NAME] = [TRANSACTION].BRAND      
                AND [BRAND].COD_TTYPE = [TRANSACTION].COD_TTYPE      
                     JOIN PRODUCTS_ACQUIRER      
                          ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ      
            WHERE [TRANSACTION].COD_TRAN = @TRAN_ID;      
        END;      
      
    SELECT @COD_AWAIT_SPLIT = COD_SITUATION      
    FROM SITUATION      
    WHERE [NAME] = 'WAITING FOR SPLIT OF FINANCE SCHEDULE'      
    SELECT @COD_AWAIT_PAY = COD_SITUATION      
    FROM SITUATION      
    WHERE [NAME] = 'AWAITING PAYMENT'      
    SELECT @COD_EXTERNAL_PROCESSING = COD_SITUATION      
    FROM SITUATION      
    WHERE [NAME] = 'LIQUIDACAO PROCESSADORA'      
      
    SELECT @LEDGER_RETENTION = COUNT(*)      
    FROM SERVICES_AVAILABLE s      
             JOIN ITEMS_SERVICES_AVAILABLE item      
                  ON item.COD_ITEM_SERVICE = s.COD_ITEM_SERVICE      
    WHERE s.COD_EC = @COD_EC      
      AND item.CODE = '8'      
      AND s.ACTIVE = 1      
      
    SELECT @HASPLANDZERO = 1      
         , @PLANDZEROTAX = CAST(JSON_VALUE(CONFIG_JSON, IIF(@COD_TTYPE = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))      
    FROM SERVICES_AVAILABLE SA      
             JOIN ITEMS_SERVICES_AVAILABLE item      
                  ON item.NAME = 'PlanDZero'      
                      AND item.COD_ITEM_SERVICE = SA.COD_ITEM_SERVICE      
    WHERE SA.COD_EC = @COD_EC      
      AND SA.ACTIVE = 1      
      
    IF @HASPLANDZERO = 1      
        AND @COD_AFFILIATOR IS NOT NULL      
        BEGIN      
            SELECT @PLANDZEROTAX_AFF =      
                   CAST(JSON_VALUE(CONFIG_JSON, IIF(@COD_TTYPE = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))      
            FROM SERVICES_AVAILABLE SA      
                     JOIN ITEMS_SERVICES_AVAILABLE item      
                          ON item.NAME = 'PlanDZero'      
                              AND item.COD_ITEM_SERVICE = SA.COD_ITEM_SERVICE      
            WHERE SA.COD_AFFILIATOR = @COD_AFFILIATOR      
              AND SA.COD_EC IS NULL      
              AND SA.ACTIVE = 1      
        END      
      
    SET @CURRENTHOUR = DATEPART(HOUR, @TRANDATE)      
    IF @HASPLANDZERO = 1      
        AND EXISTS(SELECT COD_SCH_PLANDZERO      
                   FROM PlanDZeroSchedule      
                   WHERE WindowMaxHour > @CURRENTHOUR)      
        BEGIN      
            SET @PLANDZEROTODAY = 1;      
            SET @PlanDZeroHour = (SELECT TOP 1 WindowMaxHour      
                                  FROM PlanDZeroSchedule      
                                  WHERE WindowMaxHour > @CURRENTHOUR      
                                  ORDER BY WindowMaxHour);      
        END      
      
    IF (@HASPLANDZERO = 1      
        AND @PLANDZEROTODAY = 0      
        AND @INTERVAL = 1)      
        OR @TYPEPLAN = 1      
        BEGIN      
            SET @HASPLANDZERO = 0;      
            SET @PLANDZEROTAX = NULL;      
            SET @PLANDZEROTAX_AFF = NULL;      
        END      
      
    IF @GEN_TITLES = 1      
        AND @LEDGER_RETENTION = 0      
        SET @TITLE_SIT = @COD_AWAIT_PAY;      
    ELSE      
        IF @GEN_TITLES <> 1      
            AND @LEDGER_RETENTION = 0      
            SET @TITLE_SIT = @COD_EXTERNAL_PROCESSING;      
        ELSE      
            SET @TITLE_SIT = @COD_AWAIT_SPLIT;      
      
    SET @TEMP_TITLE_SIT = @TITLE_SIT      
      
    CREATE TABLE #retentionRules      
    (      
        COD_RET_CTRL INT      NOT NULL,      
        FROM_DATE    DATETIME NOT NULL,      
        UNTIL_DATE   DATETIME NOT NULL      
    )      
      
    IF @TITLE_SIT = @COD_AWAIT_SPLIT      
        BEGIN      
            INSERT INTO #retentionRules (COD_RET_CTRL, FROM_DATE, UNTIL_DATE)      
            SELECT ctrl.COD_RET_CTRL      
                 , ctrl.FROM_DATE      
                 , ctrl.UNTIL_DATE      
            FROM LEDGER_RETENTION_CONTROL ctrl      
            WHERE ctrl.COD_EC = @COD_EC      
              AND (ctrl.UNTIL_DATE IS NULL      
                OR ctrl.UNTIL_DATE >= CAST(GETDATE() AS DATE))      
        END      
      
    SET @ANTECIP_PERCENT_EC = @ANT_PERCENT      
      
    IF @COD_AFFILIATOR IS NOT NULL      
        BEGIN      
            SELECT @COD_OPER_COST = OP_COST.COD_OPER_COST_AFF      
                 , @OPER_VALUE = OP_COST.PERCENTAGE_COST      
                 , @PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN_TAX_AFF      
                 , @PERCENT = PLAN_TAX_AFFILIATOR.[PERCENTAGE]      
                 , @RATE_PLAN_AFF = PLAN_TAX_AFFILIATOR.RATE      
                 , @ANTECIP_VALUE_AFF = PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE      
            FROM AFFILIATOR      
                     INNER JOIN OPERATION_COST_AFFILIATOR OP_COST      
                                ON OP_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
                     INNER JOIN PROGRESSIVE_COST_AFFILIATOR PROG_COST      
                                ON PROG_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
                     INNER JOIN PLAN_TAX_AFFILIATOR      
                                ON PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
                     INNER JOIN [PLAN] ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN      
                AND [PLAN].COD_PLAN_CATEGORY <> 3      
            WHERE [PLAN_TAX_AFFILIATOR].COD_TTYPE = @COD_TTYPE      
              AND [PLAN_TAX_AFFILIATOR].QTY_INI_PLOTS <= @QTY_PLOTS      
              AND [PLAN_TAX_AFFILIATOR].QTY_FINAL_PLOTS >= @QTY_PLOTS      
              AND [PLAN_TAX_AFFILIATOR].ACTIVE = 1      
              AND [OP_COST].ACTIVE = 1      
              AND PROG_COST.ACTIVE = 1      
              AND AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATOR      
              AND AFFILIATOR.ACTIVE = 1      
              AND ([PLAN_TAX_AFFILIATOR].COD_BRAND = @BRAND_TRAN      
                OR PLAN_TAX_AFFILIATOR.COD_BRAND IS NULL)      
              AND [PLAN_TAX_AFFILIATOR].COD_SOURCE_TRAN = @SOURCE_TRAN      
        END;      
      
    IF @TYPEPLAN = 1      
        BEGIN      
            SET @CONT = 0;      
            SET @VALUE = (@AMOUNT / @PLOTS);      
      
            SET @PAYDAY = CAST(@TRANDATE AS DATETIME);      
            SET @RECEIVEDATE = CAST(@TRANDATE AS DATETIME);      
            SET @INTERVAL = IIF(@HASPLANDZERO = 0, @INTERVAL, IIF(@PLANDZEROTODAY = 1, 0, 1))      
      
            IF @HASPLANDZERO = 1      
                SET @PAYDAY = IIF(@PLANDZEROTODAY = 1, @PAYDAY, DATEADD(DAY, 1, @PAYDAY))      
      
            WHILE @CONT < @PLOTS      
                BEGIN      
                    SELECT @CODE = NEXT VALUE FOR SEQ_TRANSACTION_TITLE;      
      
                    SET @PAYDAY = IIF(@HASPLANDZERO = 0, DATEADD(DAY, @INTERVAL, @PAYDAY), @PAYDAY);      
                    SET @PREVISION_PAY_DATE = [dbo].[FN_NEXT_BUSINESS_DAY](@PAYDAY)      
                    SET @RECEIVEDATE = DATEADD(DAY, @INTERVALRECEIVE, @RECEIVEDATE);      
      
                    IF @TITLE_SIT != @TEMP_TITLE_SIT      
                        SET @TITLE_SIT = @TEMP_TITLE_SIT;      
      
                    SET @COD_CTRL = NULL      
      
                    IF @TITLE_SIT = @COD_AWAIT_SPLIT      
                        BEGIN      
                            SELECT @COD_CTRL = COD_RET_CTRL      
                            FROM #retentionRules r      
                            WHERE @PREVISION_PAY_DATE BETWEEN r.FROM_DATE AND r.UNTIL_DATE      
                            IF @COD_CTRL IS NULL      
                                SET @TITLE_SIT = @COD_AWAIT_PAY      
                        END      
      
                    IF @RECEIVEDATE <= @PAYDAY      
                        SET @ANTICIPATION = 0;      
      
                    IF @HASPLANDZERO = 1      
                        AND @COD_TTYPE != 1      
                        SET @ANTICIPATION = 0      
      
                    IF @HASPLANDZERO = 1      
AND @PLANDZEROTODAY = 1      
                        SET @PREVISION_PAY_DATE = DATEADD(HOUR, @PlanDZeroHour, @PREVISION_PAY_DATE)      
      
                    INSERT INTO [TRANSACTION_TITLES] (CODE,      
                                                      COD_TRAN,      
                                                      PLOT,      
                                                      AMOUNT,      
                                                      COD_ASS_DEPTO_TERMINAL,      
                                                      TAX_INITIAL,      
                                                      ANTICIP_PERCENT,      
                                                      RATE,      
                                     PREVISION_PAY_DATE,      
                                                      COD_SITUATION,      
                                                      ACQ_TAX,      
                                                      INTERVAL_INITIAL,      
                                                      PREVISION_RECEIVE_DATE,      
                                                      COD_SITUATION_RECEIVE,      
                                                      COD_TYPE_TRAN_TITLE,      
                                                      COD_EC,      
                                                      COD_ASS_TX_DEP,      
                                                      QTY_DAYS_ANTECIP,      
                                                      QTY_BUSINESS_DAY,      
                                                      COD_RET_CTRL,      
                                                      TAX_PLANDZERO)      
                    VALUES (CONCAT(@CODE, @COD_EC),      
                            @TR_ID,      
                            (@CONT + 1),      
                            @VALUE,      
                            @CODASS_EQUIP,      
                            @TAXINI,      
                            @ANTICIPATION,      
                            @RATE,      
                            @PREVISION_PAY_DATE,      
                            @TITLE_SIT,      
                            @TAX_ACQ,      
                            @INTERVAL,      
                            [dbo].[FN_NEXT_BUSINESS_DAY](@RECEIVEDATE),      
                            @TITLE_SIT,      
                            1,      
                            @COD_EC,      
                            @COD_TX_EC,      
                            (((@CONT + 1) * 30) - DATEDIFF(DAY, (CAST(@TRANDATE AS DATE)), @PAYDAY)),      
                            (((@CONT + 1) * 30) - DATEDIFF(DAY, (CAST(@TRANDATE AS DATE)),      
                                                           [dbo].[FN_NEXT_BUSINESS_DAY](@PAYDAY))),      
                            @COD_CTRL,      
                            @PLANDZEROTAX);      
      
                    IF @@rowcount < 1      
                        THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;      
      
                    SET @COD_TITTLE_INSERTED = SCOPE_IDENTITY();      
      
                    INSERT INTO ASS_UR_TITTLE      
                    (COD_TITLE,      
                     COD_UR,      
                     PREVISION_PAYMENT_DATE,      
                     COD_SOURCE_TRAN,      
                     COD_EC,      
     COD_SITUATION)      
                    OUTPUT inserted.COD_ASS_UR, inserted.COD_UR, inserted.PREVISION_PAYMENT_DATE ,inserted.COD_TITLE, @COD_EC INTO @OUTPUT_UR      
                    SELECT @COD_TITTLE_INSERTED,      
                           RECEIVABLE_UNITS.COD_UR,      
                           @PREVISION_PAY_DATE,      
                           @SOURCE_TRAN,      
                           [TRANSACTION_TITLES].COD_EC,      
                           4      
                    FROM RECEIVABLE_UNITS      
                             JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR      
                             JOIN ACQUIRER ON ACQUIRER.COD_AC = @COD_AC      
                             JOIN ACQUIRER_GROUP ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP      
                             JOIN [TRANSACTION_TITLES] ON [TRANSACTION_TITLES].COD_TITLE = @COD_TITTLE_INSERTED      
                             LEFT JOIN ASS_UR_TITTLE ON ASS_UR_TITTLE.COD_TITLE = @COD_TITTLE_INSERTED      
                    where TYPE_ARR_SLC.COD_TTYPE = @COD_TTYPE      
                      AND TYPE_ARR_SLC.ANTICIP =      
                          (      
                              CASE      
                                  WHEN [TRANSACTION_TITLES].QTY_DAYS_ANTECIP > 0 AND @COD_TTYPE = 1 THEN 1      
                                  ELSE 0      
                                  END      
                              )      
                      AND RECEIVABLE_UNITS.COD_BRAND = @COD_BRAND      
                      AND RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP      
           AND ASS_UR_TITTLE.COD_TITLE IS NULL      
      
      
                    --  AFFILIATOR INSERT COST (RECEIVE)                                
                    IF @COD_AFFILIATOR IS NOT NULL      
                        BEGIN      
                            IF @RECEIVEDATE <= @PAYDAY      
                                SET @ANTECIP_VALUE_AFF = 0;      
      
                            IF @HASPLANDZERO = 1      
                                SET @ANTECIP_VALUE_AFF = 0      
      
                            INSERT INTO TRANSACTION_TITLES_COST (COD_AFFILIATOR,      
                                                                 COD_TITLE,      
                                                                 COD_OPER_COST_AFF,      
                                                                 OPER_VALUE,      
                                                                 COD_PLAN_TAX_AFF,      
                                                                 [PERCENTAGE],      
                                                                 PREVISION_PAY_DATE,      
                                                                 COD_SITUATION,      
                                                                 RATE_PLAN,      
                                                                 ANTICIP_PERCENT,      
                                                                 TAX_PLANDZERO)      
                            VALUES (@COD_AFFILIATOR,      
                                    @COD_TITTLE_INSERTED,      
                                    @COD_OPER_COST,      
                                    @OPER_VALUE,      
                                    @PLAN,      
                                    @PERCENT,      
                                    [dbo].[FN_NEXT_BUSINESS_DAY](@PAYDAY),      
                                    @COD_AWAIT_PAY,      
                                    @RATE_PLAN_AFF,      
                                    @ANTECIP_VALUE_AFF,      
                                    @PLANDZEROTAX_AFF)      
      
                            -- INSERT UR TITTLE          
      
      
                        END;      
      
                    SET @CONT = @CONT + 1;      
                END;      
            IF (@PLANDZEROTAX IS NOT NULL)      
                INSERT INTO TRANSACTION_SERVICES (CREATED_AT, COD_ITEM_SERVICE, COD_TRAN, TAX_PLANDZERO_EC,      
                                                  TAX_PLANDZERO_AFF, COD_EC)      
                VALUES (current_timestamp,      
                        (SELECT isa.COD_ITEM_SERVICE FROM ITEMS_SERVICES_AVAILABLE isa WHERE isa.NAME = 'PlanDZero'),      
                        @TR_ID, @PLANDZEROTAX, @PLANDZEROTAX_AFF, @COD_EC)      
        END;      
    ELSE      
        BEGIN      
            SET @CONT = 0;      
            SET @VALUE = (@AMOUNT / @PLOTS);      
            SET @PAYDAY = CAST(@TRANDATE AS DATETIME);      
            SET @RECEIVEDATE = CAST(@TRANDATE AS DATETIME);      
            SET @PAYDAY = IIF(@HASPLANDZERO = 0, DATEADD(DAY, @INTERVAL, @PAYDAY),      
                              IIF(@PLANDZEROTODAY = 1, @PAYDAY, DATEADD(DAY, 1, @PAYDAY)));      
      
            SET @INTERVAL = IIF(@HASPLANDZERO = 0, @INTERVAL, IIF(@PLANDZEROTODAY = 1, 0, 1))      
      
            IF @HASPLANDZERO = 1      
                AND @COD_TTYPE != 1      
                SET @ANTECIP_PERCENT_EC = 0      
      
            SET @PREVISION_PAY_DATE = [dbo].[FN_NEXT_BUSINESS_DAY](@PAYDAY)      
      
            IF @HASPLANDZERO = 1      
                AND @PLANDZEROTODAY = 1      
                SET @PREVISION_PAY_DATE = DATEADD(HOUR, @PlanDZeroHour, @PREVISION_PAY_DATE)      
      
            IF @TITLE_SIT != @TEMP_TITLE_SIT      
                SET @TITLE_SIT = @TEMP_TITLE_SIT;      
      
            SET @COD_CTRL = NULL      
      
            IF @TITLE_SIT = @COD_AWAIT_SPLIT      
                BEGIN      
                    SELECT @COD_CTRL = COD_RET_CTRL      
                    FROM #retentionRules r      
                    WHERE @PREVISION_PAY_DATE BETWEEN r.FROM_DATE AND r.UNTIL_DATE      
      
                    IF @COD_CTRL IS NULL      
                        SET @TITLE_SIT = @COD_AWAIT_PAY      
                END      
      
            WHILE @CONT < @PLOTS      
      BEGIN      
                    SELECT @CODE = NEXT VALUE FOR SEQ_TRANSACTION_TITLE;      
      
                    SET @RECEIVEDATE = DATEADD(DAY, @INTERVALRECEIVE, @RECEIVEDATE);      
      
                    IF @RECEIVEDATE <= @PAYDAY      
                        SET @ANT_PERCENT = 0;      
                    ELSE      
                        SET @ANT_PERCENT = @ANTECIP_PERCENT_EC;      
      
                    INSERT INTO [TRANSACTION_TITLES] (CODE,      
                                                      COD_TRAN,      
                                                      PLOT,      
                                                      AMOUNT,      
                                                      COD_ASS_DEPTO_TERMINAL,      
                                                      TAX_INITIAL,      
                                                      RATE,      
                                                      PREVISION_PAY_DATE,      
                                                      COD_SITUATION,      
                                                      ACQ_TAX,      
                                                      INTERVAL_INITIAL,      
                                                      PREVISION_RECEIVE_DATE,      
                                                      COD_SITUATION_RECEIVE,      
                                                      COD_TYPE_TRAN_TITLE,      
                                                      ANTICIP_PERCENT,      
                                                      COD_EC,      
                                                      COD_ASS_TX_DEP,      
                                                      QTY_DAYS_ANTECIP,      
                                                      QTY_BUSINESS_DAY,      
                                                      COD_RET_CTRL,      
                                                      TAX_PLANDZERO)      
                    VALUES (CONCAT(@CODE, @COD_EC),      
                            @TR_ID, (@CONT + 1),      
                            @VALUE,      
                            @CODASS_EQUIP,      
                            @TAXINI,      
                            @RATE,      
                            @PREVISION_PAY_DATE,      
                            @TITLE_SIT,      
                            @TAX_ACQ,      
                            @INTERVAL,      
                            [dbo].[FN_NEXT_BUSINESS_DAY](@RECEIVEDATE),      
                            @TITLE_SIT,      
                            1,      
                            @ANT_PERCENT,      
                            @COD_EC,      
                            @COD_TX_EC,      
                            (((@CONT + 1) * 30) - DATEDIFF(DAY, (CAST(@TRANDATE AS DATE)), @PAYDAY)),      
                            (((@CONT + 1) * 30) - DATEDIFF(DAY, (CAST(@TRANDATE AS DATE)),      
                                                           [dbo].[FN_NEXT_BUSINESS_DAY](@PAYDAY))),      
                            @COD_CTRL,      
                            @PLANDZEROTAX);      
      
        IF @@rowcount < 1      
                        THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;      
      
                    SET @COD_TITTLE_INSERTED = SCOPE_IDENTITY();      
      
      
                    IF @COD_AFFILIATOR IS NOT NULL      
                        BEGIN      
                            IF @RECEIVEDATE <= @PAYDAY      
                                SET @ANTECIP_VALUE_AFF = 0;      
      
                            IF @HASPLANDZERO = 1      
                                AND @COD_TTYPE != 1      
                                SET @ANTECIP_VALUE_AFF = 0      
      
                            INSERT INTO TRANSACTION_TITLES_COST (COD_AFFILIATOR,      
                                                                 COD_TITLE,      
                                                                 COD_OPER_COST_AFF,      
                                                                 OPER_VALUE,      
                                                                 COD_PLAN_TAX_AFF,      
                                                                 [PERCENTAGE],      
                      PREVISION_PAY_DATE,      
                                                                 COD_SITUATION,      
                                                                 RATE_PLAN,      
                                                                 ANTICIP_PERCENT,      
                                                                 TAX_PLANDZERO)      
                            VALUES (@COD_AFFILIATOR,      
                                    @COD_TITTLE_INSERTED,      
                                    @COD_OPER_COST,      
                                    @OPER_VALUE,      
                                    @PLAN,      
                                    @PERCENT,      
                                    [dbo].[FN_NEXT_BUSINESS_DAY](@PAYDAY),      
                                    @COD_AWAIT_PAY,      
                                    @RATE_PLAN_AFF,      
                                    @ANTECIP_VALUE_AFF,      
                                    @PLANDZEROTAX_AFF)      
      
                            INSERT INTO ASS_UR_TITTLE      
                            (COD_TITLE,      
                             COD_UR,      
                             PREVISION_PAYMENT_DATE,      
                             COD_SOURCE_TRAN,      
                             COD_EC,      
                             COD_SITUATION)      
                            OUTPUT inserted.COD_ASS_UR, inserted.COD_UR, inserted.PREVISION_PAYMENT_DATE ,inserted.COD_TITLE, @COD_EC INTO @OUTPUT_UR      
                            SELECT @COD_TITTLE_INSERTED,      
                                   RECEIVABLE_UNITS.COD_UR,      
                                   @PREVISION_PAY_DATE,      
                                   @SOURCE_TRAN,      
              [TRANSACTION_TITLES].COD_EC,      
                                   4      
                            FROM RECEIVABLE_UNITS      
                                     JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR      
                                     JOIN ACQUIRER ON ACQUIRER.COD_AC = @COD_AC      
                                     JOIN ACQUIRER_GROUP ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP      
                                     JOIN [TRANSACTION_TITLES] WITH (NOLOCK)      
                                          ON [TRANSACTION_TITLES].COD_TITLE = @COD_TITTLE_INSERTED      
                                     LEFT JOIN ASS_UR_TITTLE ON ASS_UR_TITTLE.COD_TITLE = @COD_TITTLE_INSERTED      
                            WHERE TYPE_ARR_SLC.COD_TTYPE = @COD_TTYPE      
                              AND TYPE_ARR_SLC.ANTICIP =      
                                  (      
                                      CASE      
                                          WHEN [TRANSACTION_TITLES].QTY_DAYS_ANTECIP > 0 AND @COD_TTYPE = 1 THEN 1      
                                          ELSE 0      
                                          END      
                                      )      
                              AND RECEIVABLE_UNITS.COD_BRAND = @COD_BRAND      
                              AND RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP      
                              AND ASS_UR_TITTLE.COD_TITLE IS NULL      
      
      
                        END;      
      
                    SET @CONT = @CONT + 1;      
                END;      
            IF (@PLANDZEROTAX IS NOT NULL)      
                INSERT INTO TRANSACTION_SERVICES (CREATED_AT, COD_ITEM_SERVICE, COD_TRAN, TAX_PLANDZERO_EC,      
                                                  TAX_PLANDZERO_AFF, COD_EC)      
                VALUES (current_timestamp,      
                        (SELECT isa.COD_ITEM_SERVICE FROM ITEMS_SERVICES_AVAILABLE isa WHERE isa.NAME = 'PlanDZero'),      
                        @TR_ID, @PLANDZEROTAX, @PLANDZEROTAX_AFF, @COD_EC)      
        END;      
      

    EXEC [SP_VAL_LIMIT_EC] @CODETR = @COD_TRAN;
      
    UPDATE PROCESS_BG_STATUS      
    SET STATUS_PROCESSED = 0      
    WHERE CODE = @TR_ID      
      
    --EXEC SP_REPROCESS_BILL_TO_PAY_TITTLES @TP_REPROCESS          
      
END;    
  
  

  GO

IF OBJECT_ID('SP_UP_TRANSACTION') IS NOT NULL
DROP PROCEDURE [SP_UP_TRANSACTION];

GO

CREATE PROCEDURE [dbo].[SP_UP_TRANSACTION]                                                 
/*----------------------------------------------------------------------------------------                                                 
Procedure Name: [SP_UP_TRANSACTION]                                                 
Project.......: TKPP                                                 
------------------------------------------------------------------------------------------                                                 
Author   Version  Date   Description                                                 
------------------------------------------------------------------------------------------                                                 
Kennedy Alef V1   27/07/2018  Creation                                        
Lucas Aguiar V2   17-04-2019  rotina de aw. titles e cancelamento                                         
Elir Ribeiro V3   12-08-2019  Changed situation Blocked                                  
Elir Ribeiro V4   20-08-2019  Changed situation AWAITING PAYMENT                           
Marcus Gall  V5   01-02-2020  Changes CONFIRMED, New CANCELED after RELEASED                          
Elir Ribeiro v6   27-02-2020  Changes Cod_user                
Kennedy Alef v7   11-05-2020  Reprocess financial calendar             
Caike Uchôa  v8   13-07-2020  Canceled partial pela Finance calendar          
Caike Uchôa  V9   31-07-2020  Add cod_ec transaction_titles      
Kennedy Alef V10  07-10-2020  add enqueue finance      
Caike uchoa  v11  18/11/2020  alter awaiting payment
------------------------------------------------------------------------------------------*/                                                 
(                                                 
@CODE_TRAN VARCHAR(200),                                                 
@SITUATION VARCHAR(100),                                                 
@DESCRIPTION VARCHAR(200) = NULL,                                                 
@CURRENCY VARCHAR(100),                                                 
@CODE_ERROR VARCHAR(100) = NULL,                                              
@TRAN_ID INT   = NULL,                            
@LOGICAL_NUMBER_ACQ VARCHAR(100) = NULL ,                            
@CARD_HOLDER_NAME VARCHAR(100) = NULL,                         
@COD_USER INT = NULL                                        
)                                                 
AS                                                 
DECLARE @QTY INT=0;          
                
                  
                          
                                                
DECLARE @CONT INT;          
                
                  
                          
                                                 
DECLARE @SIT VARCHAR(100);          
                
                  
                          
                                                 
DECLARE @BRANCH INT;          
                
                  
                
DECLARE @COD_EC_TITTLE INT;          
                
                
DECLARE @DATE_TRAN DATE;          
                
                                            
                                                
IF @TRAN_ID IS NULL                          
 BEGIN          
SELECT          
 @CONT = COD_TRAN          
   ,@SIT = SITUATION.[NAME]          
   ,@DATE_TRAN = [TRANSACTION].BRAZILIAN_DATE          
FROM [TRANSACTION] WITH (NOLOCK)          
INNER JOIN SITUATION          
 ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION          
WHERE CODE = @CODE_TRAN;          
END;          
ELSE          
BEGIN          
SELECT          
 @CONT = COD_TRAN          
   ,@SIT = SITUATION.NAME          
FROM [TRANSACTION] WITH (NOLOCK)          
INNER JOIN SITUATION          
 ON SITUATION.COD_SITUATION = [TRANSACTION].COD_SITUATION          
WHERE COD_TRAN = @TRAN_ID;          
END;          
          
IF @CONT < 1          
 OR @CONT IS NULL          
THROW 60002, '601', 1;          
          
UPDATE PROCESS_BG_STATUS          
SET STATUS_PROCESSED = 0          
   ,MODIFY_DATE = GETDATE()          
FROM PROCESS_BG_STATUS WITH (NOLOCK)          
WHERE CODE = @CONT          
AND COD_TYPE_PROCESS_BG = 1;          
          
-- @SITUATION CONDITIONALS                          
IF @SITUATION = 'APPROVED'          
BEGIN          
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,1          
    ,'100 - APROVADA';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 1          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = ISNULL(dbo.[ISNULLOREMPTY](@DESCRIPTION), '100 - APROVADA')          
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 100)          
   ,COD_CURRRENCY = (SELECT          
   COD_CURRRENCY          
  FROM CURRENCY          
  WHERE NUM = @CURRENCY)          
   ,LOGICAL_NUMBER_ACQ = @LOGICAL_NUMBER_ACQ          
   ,CARD_HOLDER_NAME = @CARD_HOLDER_NAME          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
END;          
ELSE          
IF @SITUATION = 'CONFIRMED'          
BEGIN          
IF @SIT = @SITUATION          
THROW 60002, '603', 1;          
          
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,3          
    ,@DESCRIPTION;          
          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                   
UPDATE [TRANSACTION]          
SET COD_SITUATION = 3          
   ,MODIFY_DATE = GETDATE()          
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 200)          
   ,COMMENT = ISNULL(dbo.[ISNULLOREMPTY](@DESCRIPTION), '200 - CONFIRMADA')          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
--EXECUTE [SP_GEN_TITLES_TRANS] @COD_TRAN = @CODE_TRAN, @TRAN_ID= @TRAN_ID;                          
          
END;          
ELSE          
IF @SITUATION = 'AWAITING TITLES'          
BEGIN          
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,22          
    ,'206 - AGUARDANDO TITULOS';          
          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
UPDATE [TRANSACTION]          
SET COD_SITUATION = 22          
   ,MODIFY_DATE = GETDATE()          
   ,CODE_ERROR = 206          
   ,COMMENT = '206 - AGUARDANDO TITULOS'          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
END;          
ELSE          
IF @SITUATION = 'PROCESSING UNDONE'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,21          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 21          
   ,MODIFY_DATE = GETDATE()          
   ,COD_CURRRENCY = (SELECT          
   COD_CURRRENCY          
  FROM CURRENCY          
  WHERE NUM = @CURRENCY)          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
END;          
ELSE          
IF @SITUATION = 'UNDONE FAIL'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,23          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 23          
   ,MODIFY_DATE = GETDATE()          
,COD_CURRRENCY = (SELECT          
   COD_CURRRENCY          
  FROM CURRENCY          
  WHERE NUM = @CURRENCY)          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
END;          
ELSE          
IF @SITUATION = 'DENIED ACQUIRER'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                             
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,2          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 2          
   ,MODIFY_DATE = GETDATE()          
   ,COD_CURRRENCY = (SELECT          
   COD_CURRRENCY          
  FROM CURRENCY          
  WHERE NUM = @CURRENCY)          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = @CODE_ERROR          
   ,CARD_HOLDER_NAME = @CARD_HOLDER_NAME          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
END;          
ELSE          
IF @SITUATION = 'BLOCKED'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,14          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 14          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = @CODE_ERROR          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
UPDATE TRANSACTION_TITLES          
SET TRANSACTION_TITLES.COD_SITUATION = 14          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,COD_FIN_CALENDAR = NULL          
FROM TRANSACTION_TITLES WITH (NOLOCK)          
INNER JOIN [TRANSACTION]          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
UPDATE [TRANSACTION_TITLES_COST]          
SET COD_SITUATION = 14          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)          
INNER JOIN [TRANSACTION_TITLES]          
 ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE          
INNER JOIN [TRANSACTION]          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
          
--- REPROCESS FINANCIAL CALENDAR                 
          
DECLARE _CURSOR CURSOR FOR SELECT DISTINCT          
 COD_EC          
FROM [TRANSACTION_TITLES] WITH (NOLOCK)          
WHERE COD_TRAN = @CONT          
          
OPEN _CURSOR          
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
WHILE @@fetch_status = 0          
BEGIN          
          
--EXEC SP_PROCESS_FINANCE_RATE @COD_EC_TITTLE        
INSERT INTO PROCESSING_QUEUE (COD_EC) VALUES (@COD_EC_TITTLE)      
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
          
END;          
          
CLOSE _CURSOR          
DEALLOCATE _CURSOR;          
          
END;          
          
          
ELSE          
IF @SITUATION = 'AWAITING PAYMENT'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,4          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 3          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = @CODE_ERROR          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
--UPDATE TRANSACTION_TITLES          
--SET TRANSACTION_TITLES.COD_SITUATION = 4          
--   ,MODIFY_DATE = GETDATE()          
--   ,COMMENT = @DESCRIPTION          
--   ,COD_FIN_CALENDAR = NULL          
--FROM TRANSACTION_TITLES WITH (NOLOCK)          
--INNER JOIN [TRANSACTION]          
-- ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
--WHERE [TRANSACTION].COD_TRAN = @CONT;    

EXEC [UP_STATUS_AWAITING_PAYMENT] @COD_TRAN = @CONT,@DESCRIPTION = @DESCRIPTION;
          
UPDATE [TRANSACTION_TITLES_COST]          
SET COD_SITUATION = 4          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)          
INNER JOIN [TRANSACTION_TITLES]          
 ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE          
INNER JOIN [TRANSACTION]          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
--- REPROCESS FINANCIAL CALENDAR                 
          
DECLARE _CURSOR CURSOR FOR SELECT DISTINCT          
 COD_EC          
FROM [TRANSACTION_TITLES] WITH (NOLOCK)          
WHERE COD_TRAN = @CONT          
          
OPEN _CURSOR          
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
WHILE @@fetch_status = 0          
BEGIN          
          
--EXEC SP_PROCESS_FINANCE_RATE @COD_EC_TITTLE        
INSERT INTO PROCESSING_QUEUE (COD_EC) VALUES (@COD_EC_TITTLE)      
      
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
          
END;          
          
CLOSE _CURSOR          
DEALLOCATE _CURSOR          
          
END;          
ELSE          
IF @SITUATION = 'UNDONE'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,10          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 10          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = @CODE_ERROR          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
UPDATE TRANSACTION_TITLES          
SET TRANSACTION_TITLES.COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM TRANSACTION_TITLES WITH (NOLOCK)          
INNER JOIN [TRANSACTION]          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
UPDATE [TRANSACTION_TITLES_COST]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)          
INNER JOIN [TRANSACTION_TITLES]          
 ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE          
INNER JOIN [TRANSACTION]          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
END;          
ELSE          
IF @SITUATION = 'FAILED'          
BEGIN          
--EXEC SP_REG_HIST_TRANSACTION @CODE_TR = @CODE_TRAN;                                                 
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,7          
    ,'';          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 7          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
  ,CODE_ERROR = ISNULL(@CODE_ERROR, 700)          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
END;          
ELSE          
IF @SITUATION = 'CANCELED'          
BEGIN          
IF @SIT = @SITUATION          
THROW 60002, '703', 1;          
IF @SIT = 'AWAITING TITLES'          
BEGIN          
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,6          
    ,@DESCRIPTION;          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 300)          
   ,COD_USER = @COD_USER          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
UPDATE TRANSACTION_TITLES          
SET TRANSACTION_TITLES.COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,TRANSACTION_TITLES.COD_FIN_CALENDAR = NULL          
FROM TRANSACTION_TITLES WITH (NOLOCK)          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
UPDATE [TRANSACTION_TITLES_COST]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)          
INNER JOIN [TRANSACTION_TITLES] WITH (NOLOCK)          
 ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
END;          
ELSE          
BEGIN          
SELECT          
 @QTY = COUNT(*)          
FROM TRANSACTION_TITLES WITH (NOLOCK)          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
LEFT JOIN FINANCE_CALENDAR          
 ON FINANCE_CALENDAR.COD_FIN_CALENDAR = [TRANSACTION_TITLES].COD_FIN_CALENDAR       
  AND FINANCE_CALENDAR.ACTIVE = 1          
WHERE [TRANSACTION].COD_TRAN = @CONT          
AND ISNULL(FINANCE_CALENDAR.COD_SITUATION, TRANSACTION_TITLES.COD_SITUATION) NOT IN (4, 20);          
          
IF @QTY > 0          
THROW 60002, '704', 1;          
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)          
 SELECT          
  @CONT          
    ,@CODE_TRAN          
    ,6          
    ,@DESCRIPTION;          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 300)          
   ,COD_USER = @COD_USER          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
UPDATE TRANSACTION_TITLES          
SET TRANSACTION_TITLES.COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,TRANSACTION_TITLES.COD_FIN_CALENDAR = NULL          
FROM TRANSACTION_TITLES WITH (NOLOCK)          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
UPDATE [TRANSACTION_TITLES_COST]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)          
INNER JOIN [TRANSACTION_TITLES] WITH (NOLOCK)          
 ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @DATE_TRAN = CAST(dbo.FN_FUS_UTF(GETDATE()) AS DATE)          
BEGIN          
          
          
--- REPROCESS FINANCIAL CALENDAR                 
          
DECLARE _CURSOR CURSOR FOR SELECT DISTINCT          
 COD_EC          
FROM [TRANSACTION_TITLES] WITH (NOLOCK)          
WHERE COD_TRAN = @CONT          
          
OPEN _CURSOR          
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
WHILE @@fetch_status = 0          
BEGIN          
          
--EXEC SP_PROCESS_FINANCE_RATE @COD_EC_TITTLE       
INSERT INTO PROCESSING_QUEUE (COD_EC) VALUES (@COD_EC_TITTLE)      
      
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
          
END;          
          
CLOSE _CURSOR          
DEALLOCATE _CURSOR;          
          
END;          
    
INSERT INTO PROCESSING_QUEUE (COD_EC) VALUES (@COD_EC_TITTLE)      
    
          
          
          
END;          
          
END;          
ELSE          
IF @SITUATION = 'CANCELED PARTIAL'          
BEGIN          
IF @SIT = 'CANCELED'          
THROW 60002, '703', 1;          
          
INSERT INTO RELEASE_ADJUSTMENTS (COD_EC, VALUE, PREVISION_PAY_DATE, COD_TYPEJUST, COMMENT, COD_SITUATION, COD_USER, COD_REQ, COD_BRANCH, COD_TRAN, COD_TITLE_REF)          
 SELECT          
  CAST(TRANSACTION_TITLES.COD_EC AS INT) AS COD_EC          
    ,(CAST(          
  (          
  (          
  (TRANSACTION_TITLES.AMOUNT * (1 - (TRANSACTION_TITLES.TAX_INITIAL / 100))) *          
  CASE          
   WHEN TRANSACTION_TITLES.ANTICIP_PERCENT IS NULL THEN 1          
   ELSE 1 - (((TRANSACTION_TITLES.ANTICIP_PERCENT / 30) *          
    COALESCE(CASE          
     WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)          
     ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP          
    END, (TRANSACTION_TITLES.PLOT * 30) - 1)          
    ) / 100)          
  END          
  )          
  - (CASE          
   WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE          
   ELSE 0          
  END)          
  ) AS DECIMAL(22, 6)) * -1) AS VALUE          
    ,[TRANSACTION_TITLES].PREVISION_PAY_DATE AS PREVISION_PAY_DATE          
    ,CAST(2 AS INT) AS COD_TYPEJUST          
    ,CAST('CANCELAMENTO PARCIAL, NSU: ' + [TRANSACTION].CODE AS VARCHAR(200)) AS COMMENT          
    ,CAST(4 AS INT) AS COD_SITUATION          
    ,NULL AS CODUSER          
    ,NULL AS COD_REQ          
    ,CAST([COMMERCIAL_ESTABLISHMENT].COD_EC AS INT) AS COD_BRANCH          
    ,CAST([TRANSACTION].COD_TRAN AS INT) AS COD_TRAN          
    ,CAST([TRANSACTION_TITLES].COD_TITLE AS INT) AS COD_TITLE_REF          
 FROM [TRANSACTION_TITLES] WITH (NOLOCK)          
 INNER JOIN [TRANSACTION] WITH (NOLOCK)          
  ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN          
 INNER JOIN [COMMERCIAL_ESTABLISHMENT]          
  ON [COMMERCIAL_ESTABLISHMENT].COD_EC = [TRANSACTION_TITLES].COD_EC          
 LEFT JOIN FINANCE_CALENDAR          
  ON FINANCE_CALENDAR.COD_FIN_CALENDAR = [TRANSACTION_TITLES].COD_FIN_CALENDAR          
   AND FINANCE_CALENDAR.ACTIVE = 1          
 WHERE [TRANSACTION].COD_TRAN = @CONT          
 AND ISNULL(FINANCE_CALENDAR.COD_SITUATION, TRANSACTION_TITLES.COD_SITUATION) NOT IN (4, 20);          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
UPDATE [TRANSACTION]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,CODE_ERROR = ISNULL(@CODE_ERROR, 300)          
   ,COD_USER = @COD_USER          
FROM [TRANSACTION] WITH (NOLOCK)          
WHERE [TRANSACTION].COD_TRAN = @CONT;          
          
IF @@rowcount < 1          
THROW 60002, '002', 1;          
          
UPDATE [TRANSACTION_TITLES]          
SET TRANSACTION_TITLES.COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
   ,TRANSACTION_TITLES.COD_FIN_CALENDAR = NULL          
FROM [TRANSACTION_TITLES] WITH (NOLOCK)          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT          
AND [TRANSACTION_TITLES].COD_SITUATION = 4;          
          
UPDATE [TRANSACTION_TITLES_COST]          
SET COD_SITUATION = 6          
   ,MODIFY_DATE = GETDATE()          
   ,COMMENT = @DESCRIPTION          
FROM [TRANSACTION_TITLES_COST] WITH (NOLOCK)          
INNER JOIN [TRANSACTION_TITLES] WITH (NOLOCK)          
 ON [TRANSACTION_TITLES].COD_TITLE = [TRANSACTION_TITLES_COST].COD_TITLE          
INNER JOIN [TRANSACTION] WITH (NOLOCK)          
 ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN          
WHERE [TRANSACTION].COD_TRAN = @CONT          
AND [TRANSACTION_TITLES_COST].COD_SITUATION = 4;          
          
          
DECLARE _CURSOR CURSOR FOR SELECT DISTINCT          
 COD_EC          
FROM [TRANSACTION_TITLES] WITH (NOLOCK)          
WHERE COD_TRAN = @CONT          
          
OPEN _CURSOR          
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
WHILE @@fetch_status = 0          
BEGIN          
          
--EXEC SP_PROCESS_FINANCE_RATE @COD_EC_TITTLE       
INSERT INTO PROCESSING_QUEUE (COD_EC) VALUES (@COD_EC_TITTLE)      
      
          
FETCH NEXT FROM _CURSOR INTO @COD_EC_TITTLE          
          
          
END;          
          
CLOSE _CURSOR          
DEALLOCATE _CURSOR;          
          
          
END;          
          
        
  -- FIM ST-1190        
GO
 

IF OBJECT_ID('SP_VAL_LIMIT_EC') IS NOT NULL
DROP PROCEDURE [SP_VAL_LIMIT_EC];

GO
CREATE PROCEDURE [dbo].[SP_VAL_LIMIT_EC]         
/*----------------------------------------------------------------------------------------------------------------------         
Procedure Name: [SP_VAL_LIMIT_EC]         
Project.......: TKPP         
------------------------------------------------------------------------------------------------------------------------         
Author                 VERSION             Date                              Description         
------------------------------------------------------------------------------------------------------------------------         
Kennedy Alef               V1           27/07/2018                            Creation        
Lucas Aguair               V2           17-04-2019              ADD PARÂMETRO OPCIONAL DO SPLIT E SUA INSERÇÃO         
Lucas Aguiar               v4           23-04-2019                          Parametro opc cod ec        
Caike Uchoa  			   v5           16-11-2020                        Permitir tranções com limite excedido	            
------------------------------------------------------------------------------------------------------------------------*/         
(         
@CODETR VARCHAR(200)
)         
AS         

DECLARE @VALUE DECIMAL(22,6);          
DECLARE @LIMIT_DAILY DECIMAL(22,6);    
DECLARE @LIMIT DECIMAL(22,6);   
DECLARE @MONTLY DECIMAL(22,6);  
DECLARE @DESCRIPTION VARCHAR(200);    
DECLARE @BLOCKED VARCHAR(100);
DECLARE @CODEC INT;       
DECLARE @AMOUNT DECIMAL(22,6);
DECLARE @COD_TRAN INT;
DECLARE @CODE_ERROR VARCHAR(100);
DECLARE @COD_SITUATION INT;

BEGIN  

SET @LIMIT_DAILY = 0;  
SET @VALUE = 0;  

SELECT 
  @CODEC = COMMERCIAL_ESTABLISHMENT.COD_EC
 ,@AMOUNT = [TRANSACTION].AMOUNT
 ,@LIMIT_DAILY = COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY  
 ,@LIMIT = COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT  
 ,@MONTLY = COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY 
 ,@COD_TRAN = [TRANSACTION].COD_TRAN
 ,@COD_SITUATION = [TRANSACTION].COD_SITUATION
FROM [TRANSACTION] WITH(NOLOCK)
JOIN [ASS_DEPTO_EQUIP] 
ON [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
JOIN DEPARTMENTS_BRANCH 
ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
JOIN BRANCH_EC 
ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
JOIN COMMERCIAL_ESTABLISHMENT
ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
WHERE [TRANSACTION].CODE= @CODETR
  
  
IF @AMOUNT > @LIMIT  
  
BEGIN  

SET @CODE_ERROR = '402';
SET @BLOCKED = 'BLOCKED';
SET @DESCRIPTION = 'BLOQUEADA POR LIMITE DE TRANSAÇÃO EXCEDIDO';

END;  
  
  
--  DIALY      
IF @BLOCKED IS NULL  
BEGIN
SELECT  
 @VALUE = SUM(ISNULL([TRANSACTION].AMOUNT, 0))  
FROM [TRANSACTION] WITH (NOLOCK)  
INNER JOIN [ASS_DEPTO_EQUIP]  
 ON [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL  
INNER JOIN [DEPARTMENTS_BRANCH]  
 ON [DEPARTMENTS_BRANCH].COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH  
INNER JOIN [BRANCH_EC]  
 ON [BRANCH_EC].COD_BRANCH = [DEPARTMENTS_BRANCH].COD_BRANCH  
INNER JOIN COMMERCIAL_ESTABLISHMENT  
 ON COMMERCIAL_ESTABLISHMENT.COD_EC = [BRANCH_EC].COD_EC  
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @CODEC  
AND CAST([TRANSACTION].BRAZILIAN_DATE AS DATE) = CAST(dbo.FN_FUS_UTF(GETDATE()) AS DATE)  
AND [TRANSACTION].COD_SITUATION = 3  
GROUP BY COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY  
  

IF @COD_SITUATION = 3
SET @VALUE = ISNULL(@VALUE, 0);
ELSE
SET @VALUE = (ISNULL(@VALUE, 0) + @AMOUNT);


IF(@VALUE > @LIMIT_DAILY)  
BEGIN  

SET @CODE_ERROR = '403';
SET @BLOCKED = 'BLOCKED';
SET @DESCRIPTION = 'BLOQUEADA POR LIMITE DIÁRIO EXCEDIDO';
  
END;  

END;
  
-- MONTH      
 IF @BLOCKED IS NULL  
BEGIN 
SELECT  
 @VALUE = SUM(ISNULL([TRANSACTION].AMOUNT, 0))  
FROM [TRANSACTION] WITH (NOLOCK)  
INNER JOIN [ASS_DEPTO_EQUIP]  
 ON [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL  
INNER JOIN [DEPARTMENTS_BRANCH]  
 ON [DEPARTMENTS_BRANCH].COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH  
INNER JOIN [BRANCH_EC]  
 ON [BRANCH_EC].COD_BRANCH = [DEPARTMENTS_BRANCH].COD_BRANCH  
INNER JOIN COMMERCIAL_ESTABLISHMENT  
 ON COMMERCIAL_ESTABLISHMENT.COD_EC = [BRANCH_EC].COD_EC  
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @CODEC  
AND CAST([TRANSACTION].BRAZILIAN_DATE AS DATE)  
BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AND  
DATEADD(SECOND, 86399, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 30))  
AND [TRANSACTION].COD_SITUATION = 3  
GROUP BY COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY  
  

IF @COD_SITUATION = 3
SET @VALUE = ISNULL(@VALUE, 0);
ELSE
SET @VALUE = (ISNULL(@VALUE, 0) + @AMOUNT);


IF (@VALUE > @MONTLY)  
BEGIN  

SET @CODE_ERROR = '407';
SET @BLOCKED = 'BLOCKED';
SET @DESCRIPTION = 'BLOQUEADA POR LIMITE MENSAL EXCEDIDO';


END;  
END;

IF @BLOCKED IS NOT NULL
BEGIN


        EXEC SP_UP_TRANSACTION 
             @CODE_TRAN = @CODETR
            ,@SITUATION = 'BLOCKED'
            ,@DESCRIPTION = @DESCRIPTION
            ,@CURRENCY = '986'
        	,@CODE_ERROR = @CODE_ERROR
        END
  
   END 

  
     
	 GO 

IF OBJECT_ID ('SP_VALIDATE_TRANSACTION') IS NOT NULL
DROP PROCEDURE [SP_VALIDATE_TRANSACTION];

GO  
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION]    
    
/***********************************************************************************************************************************************************************          
------------------------------------------------------------------------------------------------------------------------------------------------                                
Procedure Name: [SP_VALIDATE_TRANSACTION]                                
Project.......: TKPP                                
--------------------------------------------------------------------------------------------------------------------------------------------------                                
Author                          VERSION        Date                            Description                                
------------------------         --------------------------------------------------------------------------------------------------------------------------                                
Kennedy Alef                      V1         27/07/2018                          Creation                                
Gian Luca Dalle Cort              V1         14/08/2018                          Changed                
Lucas Aguiar                      v3         17-04-2019           Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções                  
Lucas Aguiar                      v4         23-04-2019                    Parametro opc cod ec            
Kennedy Alef                      v5         12-11-2019           Card holder name, doc holder, logical number                
Caike Uchoa                       V6         26-10-2020                        ADD COD_MODEL  
Caike Uchoa                       V7         03/11/2020                        ADD COD_TTYPE  
Caike Uchoa  			          v8         16-11-2020           Permitir tranções com limite excedido	
--------------------------------------------------------------------------------------------------------------------------------------------------          
***********************************************************************************************************************************************************************/ (@TERMINALID INT,    
@TYPETRANSACTION VARCHAR(100),    
@AMOUNT DECIMAL(22, 6),    
@QTY_PLOTS INT,    
@PAN VARCHAR(100),    
@BRAND VARCHAR(200),    
@TRCODE VARCHAR(200),    
@TERMINALDATE DATETIME,    
@CODPROD_ACQ INT,    
@TYPE VARCHAR(100),    
@COD_BRANCH INT,    
@CODE_SPLIT INT = NULL,    
@COD_EC INT = NULL,    
@HOLDER_NAME VARCHAR(100) = NULL,    
@HOLDER_DOC VARCHAR(100) = NULL,    
@LOGICAL_NUMBER VARCHAR(100) = NULL,    
@COD_TRAN_PROD INT = NULL,    
@COD_EC_PRD INT = NULL)    
AS    
BEGIN  
    
    
    
    
 DECLARE @CODTX INT;  
    
    
    
    
 DECLARE @CODPLAN INT;  
    
    
    
    
 DECLARE @INTERVAL INT;  
    
    
    
    
 DECLARE @TERMINALACTIVE INT;  
    
    
    
    
 DECLARE @CODEC INT;  
    
    
    
    
 DECLARE @CODASS INT;  
    
    
    
    
 DECLARE @CODAC INT;  
    
    
    
    
 DECLARE @COMPANY INT;  
    
    
    
    
 DECLARE @BRANCH INT = 0;  
    
    
    
    
 DECLARE @TYPETRAN INT;  
    
    
    
    
 DECLARE @ACTIVE_EC INT;  
    
    
    
    
 DECLARE @CONT INT;  
    
    
    
    
 DECLARE @COD_COMP INT;  
    
    
    
    
 DECLARE @LIMIT DECIMAL(22, 6);  
    
    
    
    
 DECLARE @COD_AFFILIATOR INT;  
    
    
    
    
 DECLARE @PLAN_AFF INT;  
    
    
    
    
 DECLARE @CODTR_RETURN INT;  
    
    
    
    
 DECLARE @EC_TRANS INT;  
    
    
    
    
 DECLARE @GEN_TITLES INT;  
    
    
    
    
 DECLARE @COD_ERROR INT;  
    
    
    
 DECLARE @ERROR_DESCRIPTION VARCHAR(100)  
    
    
 DECLARE @COD_RISK_SITUATION INT;  
   
   
 DECLARE @COD_MODEL INT;  
    
    
 BEGIN  
  
SELECT TOP 1  
 @CODTX = [ASS_TAX_DEPART].[COD_ASS_TX_DEP]  
   ,@CODPLAN = [ASS_TAX_DEPART].[COD_ASS_TX_DEP]  
   ,@INTERVAL = [ASS_TAX_DEPART].[INTERVAL]  
   ,@TERMINALACTIVE = [EQUIPMENT].[ACTIVE]  
   ,@CODEC = [COMMERCIAL_ESTABLISHMENT].[COD_EC]  
   ,@CODASS = [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL]  
   ,@COMPANY = [COMPANY].[COD_COMP]  
   ,@TYPETRAN = [TRANSACTION_TYPE].[COD_TTYPE]  
   ,@ACTIVE_EC = [COMMERCIAL_ESTABLISHMENT].[ACTIVE]  
   ,@BRANCH = [BRANCH_EC].[COD_BRANCH]  
   ,@COD_COMP = [COMPANY].[COD_COMP]  
   ,@LIMIT = [COMMERCIAL_ESTABLISHMENT].[TRANSACTION_LIMIT]  
   ,@COD_AFFILIATOR = [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR]  
   ,@GEN_TITLES = [BRAND].[GEN_TITLES]  
   ,@COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION  
   ,@COD_MODEL = [EQUIPMENT_MODEL].COD_MODEL  
FROM [ASS_DEPTO_EQUIP]  
LEFT JOIN [EQUIPMENT]  
 ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]  
LEFT JOIN [EQUIPMENT_MODEL]  
 ON [EQUIPMENT_MODEL].[COD_MODEL] = [EQUIPMENT].[COD_MODEL]  
LEFT JOIN [DEPARTMENTS_BRANCH]  
 ON [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] = [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH]  
LEFT JOIN [BRANCH_EC]  
 ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]  
LEFT JOIN [DEPARTMENTS]  
 ON [DEPARTMENTS].[COD_DEPARTS] = [DEPARTMENTS_BRANCH].[COD_DEPARTS]  
LEFT JOIN [COMMERCIAL_ESTABLISHMENT]  
 ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [BRANCH_EC].[COD_EC]  
LEFT JOIN [COMPANY]  
 ON [COMPANY].[COD_COMP] = [COMMERCIAL_ESTABLISHMENT].[COD_COMP]  
LEFT JOIN [ASS_TAX_DEPART]  
 ON [ASS_TAX_DEPART].[COD_DEPTO_BRANCH] = [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH]  
LEFT JOIN [TRANSACTION_TYPE]  
 ON [TRANSACTION_TYPE].[COD_TTYPE] = [ASS_TAX_DEPART].[COD_TTYPE]  
LEFT JOIN [BRAND]  
 ON [BRAND].[COD_BRAND] = [ASS_TAX_DEPART].[COD_BRAND]  
  AND [BRAND].[COD_TTYPE] = [TRANSACTION_TYPE].[COD_TTYPE]  
WHERE [ASS_TAX_DEPART].[ACTIVE] = 1  
AND [ASS_DEPTO_EQUIP].[ACTIVE] = 1  
AND [ASS_TAX_DEPART].[COD_SOURCE_TRAN] = 2  
AND [EQUIPMENT].[COD_EQUIP] = @TERMINALID  
AND LOWER([TRANSACTION_TYPE].[NAME]) = @TYPETRANSACTION  
AND [ASS_TAX_DEPART].[QTY_INI_PLOTS] <=  
@QTY_PLOTS  
AND [ASS_TAX_DEPART].[QTY_FINAL_PLOTS] >= @QTY_PLOTS  
AND ([BRAND].[NAME] = @BRAND  
OR [BRAND].[COD_BRAND] IS NULL)  
AND ([ASS_TAX_DEPART].COD_MODEL = [EQUIPMENT_MODEL].COD_MODEL  
OR [ASS_TAX_DEPART].COD_MODEL IS NULL);  
  
  
IF (@COD_EC IS NOT NULL)  
SET @EC_TRANS = @COD_EC;  
ELSE  
SET @EC_TRANS = @CODEC;  
  
  
--IF @AMOUNT > @LIMIT  
--BEGIN  
--EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
--        ,@PAN = @PAN  
--        ,@BRAND = @BRAND  
--        ,@CODASS_DEPTO_TERMINAL = @CODASS  
--        ,@COD_TTYPE = @TYPETRAN  
--        ,@PLOTS = @QTY_PLOTS  
--        ,@CODTAX_ASS = @CODTX  
--        ,@CODAC = NULL  
--        ,@CODETR = @TRCODE  
--        ,@COMMENT = '402 - Transaction limit value exceeded"d'  
--        ,@TERMINALDATE = @TERMINALDATE  
--        ,@TYPE = @TYPE  
--        ,@COD_COMP = @COD_COMP  
--        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
--        ,@SOURCE_TRAN = 2  
--        ,@CODE_SPLIT = @CODE_SPLIT  
--        ,@COD_EC = @EC_TRANS  
--        ,@HOLDER_NAME = @HOLDER_NAME  
--        ,@HOLDER_DOC = @HOLDER_DOC  
--        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
--THROW 60002, '402', 1;  
  
--END;  
  
IF @CODTX IS NULL  
  
/*******************************************          
 PROCEDURE DE REGISTRO DE TRANSAÇÕES NEGADAS          
*******************************************/  
  
BEGIN  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = '404 - PLAN/TAX NOT FOUND'  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, '404', 1;  
END;  
  
IF @COD_AFFILIATOR IS NOT NULL  
BEGIN  
  
SELECT TOP 1  
 @PLAN_AFF = [COD_PLAN_TAX_AFF]  
FROM [PLAN_TAX_AFFILIATOR]  
INNER JOIN [AFFILIATOR]  
 ON [AFFILIATOR].[COD_AFFILIATOR] = [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR]  
WHERE [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR] = @COD_AFFILIATOR  AND @QTY_PLOTS BETWEEN [QTY_INI_PLOTS] AND [QTY_FINAL_PLOTS]  
AND [COD_TTYPE] = @TYPETRAN  
AND [PLAN_TAX_AFFILIATOR].[ACTIVE] = 1;  
  
IF @PLAN_AFF IS NULL  
BEGIN  
  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = '404 - PLAN/TAX NOT FOUND TO AFFILIATOR'  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, '404', 1;  
  
END;  
  
END;  
  
  
IF @TERMINALACTIVE = 0  
  
BEGIN  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = '003 - Blocked terminal'  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, '003', 1;  
  
END;  
  
IF @COD_RISK_SITUATION <> 2  
  
BEGIN  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = '009 - Blocked commercial establishment'  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, '009', 1;  
  
END;  
  
--EXEC [SP_VAL_LIMIT_EC] @CODEC  
--       ,@AMOUNT  
--       ,@PAN = @PAN  
--       ,@BRAND = @BRAND  
--       ,@CODASS_DEPTO_TERMINAL = @CODASS  
--       ,@COD_TTYPE = @TYPETRAN  
--       ,@PLOTS = @QTY_PLOTS  
--       ,@CODTAX_ASS = @CODTX  
--       ,@CODETR = @TRCODE  
--       ,@TYPE = @TYPE  
--       ,@TERMINALDATE = @TERMINALDATE  
--       ,@COD_COMP = @COD_COMP  
--       ,@COD_AFFILIATOR = @COD_AFFILIATOR  
--       ,@CODE_SPLIT = @CODE_SPLIT  
--       ,@EC_TRANS = @EC_TRANS  
--       ,@HOLDER_NAME = @HOLDER_NAME  
--       ,@HOLDER_DOC = @HOLDER_DOC  
--       ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
--       ,@SOURCE_TRAN = 2;  
  
  
  
EXEC @CODAC = [SP_DEFINE_ACQ] @TR_TYPE = @TYPETRAN  
        ,@COMPANY = @COMPANY  
        ,@QTY_PLOTS = @QTY_PLOTS  
        ,@BRAND = @BRAND  
        ,@COD_PR = @CODPROD_ACQ;  
  
IF @CODAC = 0  
  
BEGIN  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = '004 - Acquirer key not found for terminal  '  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, '004', 1;  
  
END;  
  
IF @GEN_TITLES = 0  
 AND @CODE_SPLIT IS NOT NULL  
BEGIN  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = '012 - PRIVATE LABELS ESTABLISHMENTS CAN NOT HAVE SPLIT'  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, '012', 1;  
END;  
  
--IF @COD_RISK_SITUATION <> 2    
--BEGIN    
-- EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT    
--         ,@PAN = @PAN    
--         ,@BRAND = @BRAND    
--         ,@CODASS_DEPTO_TERMINAL = @CODASS    
--         ,@COD_TTYPE = @TYPETRAN    
--         ,@PLOTS = @QTY_PLOTS    
--         ,@CODTAX_ASS = @CODTX    
--         ,@CODAC = NULL    
--         ,@CODETR = @TRCODE    
--         ,@COMMENT = '020 - PENDING RISK RELEASE ESTABLISHMENT'    
--         ,@TERMINALDATE = @TERMINALDATE    
--         ,@TYPE = @TYPE    
--         ,@COD_COMP = @COD_COMP    
--         ,@COD_AFFILIATOR = @COD_AFFILIATOR    
--         ,@SOURCE_TRAN = 2    
--         ,@CODE_SPLIT = @CODE_SPLIT    
--         ,@COD_EC = @EC_TRANS    
--         ,@HOLDER_NAME = @HOLDER_NAME    
--         ,@HOLDER_DOC = @HOLDER_DOC    
--         ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;    
-- THROW 60002, '020', 1;    
  
--END    
  
  
IF @COD_TRAN_PROD IS NOT NULL  
BEGIN  
  
EXEC [SP_VAL_SPLIT_MULT_EC] @COD_TRAN_PROD = @COD_TRAN_PROD  
         ,@COD_EC = @EC_TRANS  
         ,@QTY_PLOTS = @QTY_PLOTS  
         ,@BRAND = @BRAND  
         ,@COD_ERROR = @COD_ERROR OUTPUT  
         ,@ERROR_DESCRIPTION = @ERROR_DESCRIPTION OUTPUT  
         ,@COD_MODEL = @COD_MODEL  
         ,@COD_TTYPE = @TYPETRAN;  
  
IF @COD_ERROR IS NOT NULL  
BEGIN  
  
EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
        ,@PAN = @PAN  
        ,@BRAND = @BRAND  
        ,@CODASS_DEPTO_TERMINAL = @CODASS  
        ,@COD_TTYPE = @TYPETRAN  
        ,@PLOTS = @QTY_PLOTS  
        ,@CODTAX_ASS = @CODTX  
        ,@CODAC = NULL  
        ,@CODETR = @TRCODE  
        ,@COMMENT = @ERROR_DESCRIPTION  
        ,@TERMINALDATE = @TERMINALDATE  
        ,@TYPE = @TYPE  
        ,@COD_COMP = @COD_COMP  
        ,@COD_AFFILIATOR = @COD_AFFILIATOR  
        ,@SOURCE_TRAN = 2  
        ,@CODE_SPLIT = @CODE_SPLIT  
        ,@COD_EC = @EC_TRANS  
        ,@HOLDER_NAME = @HOLDER_NAME  
        ,@HOLDER_DOC = @HOLDER_DOC  
        ,@LOGICAL_NUMBER = @LOGICAL_NUMBER;  
THROW 60002, @COD_ERROR, 1;  
  
  
  
END;  
  
  
END;  
  
  
  
EXECUTE [SP_REG_TRANSACTION] @AMOUNT  
       ,@PAN  
       ,@BRAND  
       ,@CODASS_DEPTO_TERMINAL = @CODASS  
       ,@COD_TTYPE = @TYPETRAN  
       ,@PLOTS = @QTY_PLOTS  
       ,@CODTAX_ASS = @CODTX  
       ,@CODAC = @CODAC  
       ,@CODETR = @TRCODE  
       ,@TERMINALDATE = @TERMINALDATE  
       ,@COD_ASS_TR_ACQ = @CODAC  
       ,@CODPROD_ACQ = @CODPROD_ACQ  
       ,@TYPE = @TYPE  
       ,@COD_COMP = @COD_COMP  
       ,@COD_AFFILIATOR = @COD_AFFILIATOR  
       ,@SOURCE_TRAN = 2  
       ,@CODE_SPLIT = @CODE_SPLIT  
       ,@EC_TRANS = @EC_TRANS  
       ,@RET_CODTRAN = @CODTR_RETURN OUTPUT  
       ,@HOLDER_NAME = @HOLDER_NAME  
       ,@HOLDER_DOC = @HOLDER_DOC  
       ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
       ,@COD_PRD = @COD_TRAN_PROD  
       ,@COD_EC_PRD = @COD_EC_PRD  
  
SELECT  
 @CODAC AS [ACQUIRER]  
   ,@TRCODE AS [TRAN_CODE]  
   ,@CODTR_RETURN AS [COD_TRAN];  
  
  
END;  
END;  
  
--ST-1502    


GO 

IF OBJECT_ID('SP_VALIDATE_TRANSACTION_ON') IS NOT NULL
DROP PROCEDURE [SP_VALIDATE_TRANSACTION_ON];

GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION_ON]  
/*------------------------------------------------------------------------------------------------------------------------------------------                                                  
Procedure Name: [SP_VALIDATE_TRANSACTION]                                                  
Project.......: TKPP                                                  
------------------------------------------------------------------------------------------------------------------------------------------------                                                  
Author                          VERSION        Date                            Description                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------                                                  
Kennedy Alef     V1   20/08/2018    Creation                                                  
Lucas Aguiar     v2   17-04-2019    Passar par�metro opcional (CODE_SPLIT) e fazer suas respectivas inser��es                                      
Lucas Aguiar     v4   23-04-2019    Parametro opc cod ec           
Caike Uch�a      v5   21-09-2020    correcao error 409  
Caike Uchoa      v6   17-11-2020    Permitir tranções com limite excedido	
------------------------------------------------------------------------------------------------------------------------------------------------*/ (@TERMINALID VARCHAR(100)  
, @TYPETRANSACTION VARCHAR(100)  
, @AMOUNT DECIMAL(22, 6)  
, @QTY_PLOTS INT  
, @PAN VARCHAR(100)  
, @BRAND VARCHAR(200)  
, @TRCODE VARCHAR(200)  
, @TERMINALDATE DATETIME = NULL  
, @CODPROD_ACQ INT  
, @TYPE VARCHAR(100)  
, @COD_BRANCH INT = NULL  
, @MID VARCHAR(100)  
, @DESCRIPTION VARCHAR(300) = NULL  
, @CODE_SPLIT INT = NULL  
, @COD_EC INT = NULL  
, @CREDITOR_DOC VARCHAR(100) = NULL  
, @DESCRIPTION_TRAN VARCHAR(100) = NULL  
, @TRACKING VARCHAR(100) = NULL  
, @HOLDER_NAME VARCHAR(100) = NULL  
, @HOLDER_DOC VARCHAR(100) = NULL  
, @LOGICAL_NUMBER VARCHAR(100) = NULL  
, @CUSTOMER_EMAIL VARCHAR(100) = NULL  
, @LINK_MODE INT = NULL  
, @CUSTOMER_IDENTIFICATION VARCHAR(100) = NULL  
, @BILLCODE VARCHAR(64) = NULL  
, @BILLEXPIREDATE DATETIME = NULL)  
AS  
 DECLARE @CODTX INT;  
  
  
  
  
  
 DECLARE @CODPLAN INT;  
  
  
  
  
  
 DECLARE @INTERVAL INT;  
  
  
  
  
  
 DECLARE @TERMINALACTIVE INT;  
  
  
  
  
  
 DECLARE @CODEC INT;  
  
  
  
  
  
 DECLARE @CODASS INT;  
  
  
  
  
  
 DECLARE @CODAC INT;  
  
  
  
  
  
 DECLARE @COMPANY INT;  
  
  
  
  
  
 DECLARE @BRANCH INT = 0;  
  
  
  
  
  
 DECLARE @TYPETRAN INT;  
  
  
  
  
  
 DECLARE @ACTIVE_EC INT;  
  
  
  
  
  
 DECLARE @CONT INT;  
  
  
  
  
  
 DECLARE @COD_COMP INT;  
  
  
  
  
  
 DECLARE @LIMIT DECIMAL(22, 6);  
  
  
  
  
  
 DECLARE @COD_AFFILIATOR INT;  
  
  
  
  
  
 DECLARE @ONLINE INT = NULL;  
  
  
  
  
  
 DECLARE @TYPE_CREDIT INT;  
  
  
  
  
  
 DECLARE @EC_TRANS INT;  
  
  
  
  
  
 DECLARE @GEN_TITLES INT;  
  
  
  
  
  
 --DECLARE @PRODUCT_ACQ INT;                                          
 BEGIN  
  SELECT  
   @CODTX = ASS_TAX_DEPART.COD_ASS_TX_DEP  
     ,@CODPLAN = ASS_TAX_DEPART.COD_ASS_TX_DEP  
     ,@INTERVAL = ASS_TAX_DEPART.INTERVAL  
     ,@TERMINALACTIVE = EQUIPMENT.ACTIVE  
     ,@CODEC = COMMERCIAL_ESTABLISHMENT.COD_EC  
     ,@CODASS = [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL  
     ,@COMPANY = COMPANY.COD_COMP  
     ,@TYPETRAN = TRANSACTION_TYPE.COD_TTYPE  
     ,@ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE  
     ,@BRANCH = BRANCH_EC.COD_BRANCH  
     ,@COD_COMP = COMPANY.COD_COMP  
     ,@LIMIT = COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT  
     ,@COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR  
     ,@ONLINE = COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE  
     ,@GEN_TITLES = BRAND.GEN_TITLES  
  FROM [ASS_DEPTO_EQUIP]  
  LEFT JOIN EQUIPMENT  
   ON EQUIPMENT.COD_EQUIP = [ASS_DEPTO_EQUIP].COD_EQUIP  
  LEFT JOIN EQUIPMENT_MODEL  
   ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL  
  LEFT JOIN DEPARTMENTS_BRANCH  
   ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH  
  LEFT JOIN BRANCH_EC  
   ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH  
  LEFT JOIN DEPARTMENTS  
   ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS  
  LEFT JOIN COMMERCIAL_ESTABLISHMENT  
   ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC  
  LEFT JOIN COMPANY  
   ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP  
  LEFT JOIN ASS_TAX_DEPART  
   ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH  
  LEFT JOIN TRANSACTION_TYPE  
   ON TRANSACTION_TYPE.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE  
  LEFT JOIN BRAND  
   ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND  
    AND BRAND.COD_TTYPE = TRANSACTION_TYPE.COD_TTYPE  
  --LEFT JOIN EXTERNAL_DATA_EC_ACQ ON EXTERNAL_DATA_EC_ACQ.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC                                                  
  WHERE ASS_TAX_DEPART.ACTIVE = 1  
  AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 1  
  AND [ASS_DEPTO_EQUIP].ACTIVE = 1  
  AND EQUIPMENT.SERIAL = @TERMINALID  
  AND LOWER(TRANSACTION_TYPE.NAME) = @TYPETRANSACTION  
  AND ASS_TAX_DEPART.QTY_INI_PLOTS <= @QTY_PLOTS  
  AND ASS_TAX_DEPART.QTY_FINAL_PLOTS >= @QTY_PLOTS  
  AND (BRAND.[NAME] = @BRAND  
  OR BRAND.COD_BRAND IS NULL)  
  
  
  IF (@CODE_SPLIT = 0  
   OR @CODE_SPLIT IS NULL)  
   SET @EC_TRANS = 3;  
  ELSE  
   SET @EC_TRANS = @CODEC;  
  
  --AND (EXTERNAL_DATA_EC_ACQ.[NAME] = 'MID' OR EXTERNAL_DATA_EC_ACQ.[NAME] IS NULL)                                               
  IF @ONLINE = NULL  
  BEGIN  
   EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
           ,@PAN = @PAN  
           ,@BRAND = @BRAND  
           ,@CODASS_DEPTO_TERMINAL = @CODASS  
           ,@COD_TTYPE = @TYPETRAN  
           ,@PLOTS = @QTY_PLOTS  
           ,@CODTAX_ASS = @CODTX  
           ,@CODAC = NULL  
           ,@CODETR = @TRCODE  
           ,@COMMENT = '409 - TRANSACTION ONLINE NOT ENABLE'  
           ,@TERMINALDATE = @TERMINALDATE  
           ,@TYPE = @TYPE  
           ,@COD_COMP = @COD_COMP  
           ,@COD_AFFILIATOR = @COD_AFFILIATOR  
           ,@SOURCE_TRAN = 1  
           ,@CODE_SPLIT = @CODE_SPLIT  
           ,@COD_EC = @EC_TRANS  
           ,@CREDITOR_DOC = @CREDITOR_DOC  
           ,@HOLDER_NAME = @HOLDER_NAME  
           ,@HOLDER_DOC = @HOLDER_DOC  
           ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
           ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
           ,@LINK_MODE = @LINK_MODE  
           ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
           ,@BILLCODE = @BILLCODE  
           ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
   THROW 60002  
   , '409'  
   , 1;  
  END;  
  
  --IF @AMOUNT > @LIMIT  
  --BEGIN  
  -- EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
  --         ,@PAN = @PAN  
  --         ,@BRAND = @BRAND  
  --         ,@CODASS_DEPTO_TERMINAL = @CODASS  
  --         ,@COD_TTYPE = @TYPETRAN  
  --         ,@PLOTS = @QTY_PLOTS  
  --         ,@CODTAX_ASS = @CODTX  
  --         ,@CODAC = NULL  
  --         ,@CODETR = @TRCODE  
  --         ,@COMMENT = '402 - Transaction limit value exceeded'  
  --         ,@TERMINALDATE = @TERMINALDATE  
  --         ,@TYPE = @TYPE  
  --         ,@COD_COMP = @COD_COMP  
  --         ,@COD_AFFILIATOR = @COD_AFFILIATOR  
  --         ,@SOURCE_TRAN = 1  
  --         ,@CODE_SPLIT = @CODE_SPLIT  
  --         ,@COD_EC = @EC_TRANS  
  --         ,@CREDITOR_DOC = @CREDITOR_DOC  
  --         ,@HOLDER_NAME = @HOLDER_NAME  
  --         ,@HOLDER_DOC = @HOLDER_DOC  
  --         ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
  --         ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
  --         ,@LINK_MODE = @LINK_MODE  
  --         ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
  --         ,@BILLCODE = @BILLCODE  
  --         ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
  -- THROW 60002  
  -- , '402'  
  -- , 1;  
  --END;  
  
  IF @CODTX IS NULL  
  /* PROCEDURE DE REGISTRO DE TRANSA��ES NEGADAS*/  
  BEGIN  
   EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
           ,@PAN = @PAN  
           ,@BRAND = @BRAND  
           ,@CODASS_DEPTO_TERMINAL = @CODASS  
           ,@COD_TTYPE = @TYPETRAN  
           ,@PLOTS = @QTY_PLOTS  
           ,@CODTAX_ASS = @CODTX  
           ,@CODAC = NULL  
           ,@CODETR = @TRCODE  
           ,@COMMENT = '404 - PLAN/TAX NOT FOUND'  
           ,@TERMINALDATE = @TERMINALDATE  
           ,@TYPE = @TYPE  
           ,@COD_COMP = @COD_COMP  
           ,@COD_AFFILIATOR = @COD_AFFILIATOR  
           ,@SOURCE_TRAN = 1  
           ,@CODE_SPLIT = @CODE_SPLIT  
           ,@COD_EC = @EC_TRANS  
           ,@CREDITOR_DOC = @CREDITOR_DOC  
           ,@HOLDER_NAME = @HOLDER_NAME  
           ,@HOLDER_DOC = @HOLDER_DOC  
           ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
           ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
           ,@LINK_MODE = @LINK_MODE  
           ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
           ,@BILLCODE = @BILLCODE  
           ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
   THROW 60002  
   , '404'  
   , 1;  
  END;  
  
  IF @TERMINALACTIVE = 0  
  BEGIN  
   EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
           ,@PAN = @PAN  
           ,@BRAND = @BRAND  
           ,@CODASS_DEPTO_TERMINAL = @CODASS  
           ,@COD_TTYPE = @TYPETRAN  
           ,@PLOTS = @QTY_PLOTS  
           ,@CODTAX_ASS = @CODTX  
           ,@CODAC = NULL  
           ,@CODETR = @TRCODE  
           ,@COMMENT = '003 - Blocked terminal  '  
           ,@TERMINALDATE = @TERMINALDATE  
           ,@TYPE = @TYPE  
           ,@COD_COMP = @COD_COMP  
           ,@COD_AFFILIATOR = @COD_AFFILIATOR  
           ,@SOURCE_TRAN = 1  
           ,@CODE_SPLIT = @CODE_SPLIT  
           ,@COD_EC = @EC_TRANS  
           ,@CREDITOR_DOC = @CREDITOR_DOC  
           ,@HOLDER_NAME = @HOLDER_NAME  
           ,@HOLDER_DOC = @HOLDER_DOC  
           ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
           ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
           ,@LINK_MODE = @LINK_MODE  
           ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
           ,@BILLCODE = @BILLCODE  
           ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
   THROW 60002  
   , '003'  
   , 1;  
  END  
  
  IF @ACTIVE_EC = 0  
  BEGIN  
   EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
           ,@PAN = @PAN  
           ,@BRAND = @BRAND  
           ,@CODASS_DEPTO_TERMINAL = @CODASS  
           ,@COD_TTYPE = @TYPETRAN  
           ,@PLOTS = @QTY_PLOTS  
           ,@CODTAX_ASS = @CODTX  
           ,@CODAC = NULL  
           ,@CODETR = @TRCODE  
           ,@COMMENT = '009 - Blocked commercial establishment'  
           ,@TERMINALDATE = @TERMINALDATE  
           ,@TYPE = @TYPE  
           ,@COD_COMP = @COD_COMP  
           ,@COD_AFFILIATOR = @COD_AFFILIATOR  
           ,@SOURCE_TRAN = 1  
           ,@CODE_SPLIT = @CODE_SPLIT  
           ,@COD_EC = @EC_TRANS  
           ,@CREDITOR_DOC = @CREDITOR_DOC  
           ,@HOLDER_NAME = @HOLDER_NAME  
           ,@HOLDER_DOC = @HOLDER_DOC  
           ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
           ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
           ,@LINK_MODE = @LINK_MODE  
           ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
           ,@BILLCODE = @BILLCODE  
           ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
   THROW 60002  
   , '009'  
   , 1;  
  END  
  
  --EXEC SP_VAL_LIMIT_EC @CODEC  
  --     ,@AMOUNT  
  --     ,@PAN = @PAN  
  --     ,@BRAND = @BRAND  
  --     ,@CODASS_DEPTO_TERMINAL = @CODASS  
  --     ,@COD_TTYPE = @TYPETRAN  
  --     ,@PLOTS = @QTY_PLOTS  
  --     ,@CODTAX_ASS = @CODTX  
  --     ,@CODETR = @TRCODE  
  --     ,@TYPE = @TYPE  
  --     ,@TERMINALDATE = @TERMINALDATE  
  --     ,@COD_COMP = @COD_COMP  
  --     ,@COD_AFFILIATOR = @COD_AFFILIATOR  
  --     ,@CODE_SPLIT = @CODE_SPLIT  
  --     ,@EC_TRANS = @EC_TRANS  
  --     ,@HOLDER_NAME = @HOLDER_NAME  
  --     ,@HOLDER_DOC = @HOLDER_DOC  
  --     ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
  --     ,@SOURCE_TRAN = 1  
  --     ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
  --     ,@LINK_MODE = @LINK_MODE  
  --     ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;  
  
  
  EXEC @CODAC = SP_DEFINE_ACQ @TR_TYPE = @TYPETRAN  
           ,@COMPANY = @COMPANY  
           ,@QTY_PLOTS = @QTY_PLOTS  
           ,@BRAND = @BRAND  
           ,@DOC_CREDITOR = @CREDITOR_DOC  
  
  -- DEFINIR SE PARCELA > 1 ENTAO , CREDITO PARCELADO                                        
  IF @QTY_PLOTS > 1  
   SET @TYPE_CREDIT = 2;  
  ELSE  
   SET @TYPE_CREDIT = 1;  
  
  IF (@CREDITOR_DOC IS NOT NULL)  
  BEGIN  
   SELECT  
    @CODPROD_ACQ = [PRODUCTS_ACQUIRER].COD_PR_ACQ  
   FROM [PRODUCTS_ACQUIRER]  
   INNER JOIN BRAND  
    ON BRAND.COD_BRAND = PRODUCTS_ACQUIRER.COD_BRAND  
   INNER JOIN ASS_TR_TYPE_COMP  
    ON ASS_TR_TYPE_COMP.COD_AC = PRODUCTS_ACQUIRER.COD_AC  
     AND ASS_TR_TYPE_COMP.COD_BRAND = ASS_TR_TYPE_COMP.COD_BRAND  
   WHERE ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = @CODAC  
   AND [PRODUCTS_ACQUIRER].PLOT_VALUE = @TYPE_CREDIT  
   AND BRAND.NAME = @BRAND  
  END  
  
  
  IF @CODAC = 0  
  BEGIN  
   EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
           ,@PAN = @PAN  
           ,@BRAND = @BRAND  
           ,@CODASS_DEPTO_TERMINAL = @CODASS  
           ,@COD_TTYPE = @TYPETRAN  
           ,@PLOTS = @QTY_PLOTS  
           ,@CODTAX_ASS = @CODTX  
           ,@CODAC = NULL  
           ,@CODETR = @TRCODE  
           ,@COMMENT = '004 - Acquirer key not found for terminal '  
           ,@TERMINALDATE = @TERMINALDATE  
           ,@TYPE = @TYPE  
           ,@COD_COMP = @COD_COMP  
           ,@COD_AFFILIATOR = @COD_AFFILIATOR  
           ,@SOURCE_TRAN = 1  
           ,@CODE_SPLIT = @CODE_SPLIT  
           ,@COD_EC = @EC_TRANS  
           ,@CREDITOR_DOC = @CREDITOR_DOC  
           ,@HOLDER_NAME = @HOLDER_NAME  
           ,@HOLDER_DOC = @HOLDER_DOC  
           ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
           ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
           ,@LINK_MODE = @LINK_MODE  
           ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
           ,@BILLCODE = @BILLCODE  
           ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
  
   THROW 60002  
   , '004'  
   , 1;  
  END;  
  
  
  
  
  IF @GEN_TITLES = 0  
   AND @CODE_SPLIT IS NOT NULL  
  BEGIN  
   EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT  
           ,@PAN = @PAN  
           ,@BRAND = @BRAND  
           ,@CODASS_DEPTO_TERMINAL = @CODASS  
           ,@COD_TTYPE = @TYPETRAN  
           ,@PLOTS = @QTY_PLOTS  
           ,@CODTAX_ASS = @CODTX  
           ,@CODAC = NULL  
           ,@CODETR = @TRCODE  
           ,@COMMENT = '012 - PRIVATE LABELS ESTABLISHMENTS CAN NOT HAVE SPLIT'  
           ,@TERMINALDATE = @TERMINALDATE  
           ,@TYPE = @TYPE  
           ,@COD_COMP = @COD_COMP  
           ,@COD_AFFILIATOR = @COD_AFFILIATOR  
           ,@SOURCE_TRAN = 2  
           ,@CODE_SPLIT = @CODE_SPLIT  
           ,@COD_EC = @EC_TRANS  
           ,@CREDITOR_DOC = @CREDITOR_DOC  
           ,@HOLDER_NAME = @HOLDER_NAME  
           ,@HOLDER_DOC = @HOLDER_DOC  
           ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
           ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
           ,@LINK_MODE = @LINK_MODE  
           ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
           ,@BILLCODE = @BILLCODE  
           ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  
   THROW 60002, '012', 1;  
  END;  
  
  EXECUTE [SP_REG_TRANSACTION] @AMOUNT  
         ,@PAN  
         ,@BRAND  
         ,@CODASS_DEPTO_TERMINAL = @CODASS  
         ,@COD_TTYPE = @TYPETRAN  
         ,@PLOTS = @QTY_PLOTS  
         ,@CODTAX_ASS = @CODTX  
         ,@CODAC = @CODAC  
         ,@CODETR = @TRCODE  
         ,@TERMINALDATE = @TERMINALDATE  
         ,@COD_ASS_TR_ACQ = @CODAC  
         ,@CODPROD_ACQ = @CODPROD_ACQ  
         ,@TYPE = @TYPE  
         ,@COD_COMP = @COD_COMP  
         ,@COD_AFFILIATOR = @COD_AFFILIATOR  
         ,@SOURCE_TRAN = 1  
         ,@POSWEB = 0  
         ,@CODE_SPLIT = @CODE_SPLIT  
         ,@EC_TRANS = @EC_TRANS  
         ,@CREDITOR_DOC = @CREDITOR_DOC  
         ,@TRACKING_DESCRIPTION = @TRACKING  
         ,@DESCRIPTION = @DESCRIPTION_TRAN  
         ,@HOLDER_NAME = @HOLDER_NAME  
         ,@HOLDER_DOC = @HOLDER_DOC  
         ,@LOGICAL_NUMBER = @LOGICAL_NUMBER  
         ,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL  
         ,@LINK_MODE = @LINK_MODE  
         ,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION  
         ,@BILLCODE = @BILLCODE  
         ,@BILLEXPIREDATE = @BILLEXPIREDATE;  
  --SELECT                                                  
  --  'ADQ'  AS ACQUIRER,                                 
  --  '1234567489' AS TRAN_CODE,                                                
  --  'ESTABLISHMENT COMMERCIAL TEST' AS EC                                              
  SELECT  
   EXTERNAL_DATA_EC_ACQ.[VALUE] AS EC  
     ,@TRCODE AS TRAN_CODE  
     ,ACQUIRER.NAME AS ACQUIRER  
  --,@CODPROD_ACQ AS PRODUCT              
  FROM ASS_TR_TYPE_COMP  
  INNER JOIN ACQUIRER  
   ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC  
  LEFT JOIN EXTERNAL_DATA_EC_ACQ  
   ON EXTERNAL_DATA_EC_ACQ.COD_AC = ASS_TR_TYPE_COMP.COD_AC  
  WHERE  
  --ISNULL(EXTERNAL_DATA_EC_ACQ.[NAME],'MID') = 'MID' AND                                           
  ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = @CODAC  
 END;  
  

  GO 

IF OBJECT_ID('SP_GEN_SPLIT_TRANSACTION_PRG') IS NOT NULL
DROP PROCEDURE SP_GEN_SPLIT_TRANSACTION_PRG

GO
CREATE PROCEDURE SP_GEN_SPLIT_TRANSACTION_PRG              
/**************************************************************************************************************                              
------------------------------------------------------------------------------------------------------------                               
    Project.......: TKPP                                                    
------------------------------------------------------------------------------------------------------------                                 
    Author                 VERSION        Date                  Description                                                
------------------------------------------------------------------------------------------------------------                                 
    Kennedy Alef             V1       27/07/2018                Creation                                                   
    Caike Ucha              V2       06/05/2020                Add Cod_split_tran na titles                               
    Luiz Aquino              V3       29/06/2020                ET-895 PlanDZero             
	Caike Uchoa              v4      17/11/2020                 add valid limit ec
	Caike Uchoa              v5       17/11/2020                Add Reprocessamento relatório
**************************************************************************************************************/ (@ITEM ITEM_SPLIT READONLY,        
                                                                                                                 @NSU VARCHAR(100),        
                                                                                                                 @MERCHANT VARCHAR(100))        
AS        
BEGIN        
        
    DECLARE @EC_SOURCE_COD INT        
    DECLARE @AFF_SOURCE_COD INT;        
    DECLARE @EC_SOURCE VARCHAR(100);        
    DECLARE @BRAND VARCHAR(100);        
    DECLARE @COD_BRAND INT;        
    DECLARE @QTY_PLOT INT;        
    DECLARE @SOURCE_TRAN INT;        
    DECLARE @TYPE_TRAN INT;        
    DECLARE @AFFILIATOR VARCHAR(100);        
    DECLARE @AMOUNT_TR DECIMAL(22, 6);        
    DECLARE @AMOUNT_SPLIT DECIMAL(22, 6);        
    DECLARE @AFF_DATA TR_AFF_COST_DATA;        
    DECLARE @QTY INT = 0;        
    DECLARE @COD_TRAN INT;        
    DECLARE @COD_SITUATION INT;        
    DECLARE @CODASS_EQUIP INT        
    DECLARE @TRAN_DATE DATETIME        
    DECLARE @TX_ACQ DECIMAL(22, 6);        
    DECLARE @INTERVAL_ACQ INT;        
    DECLARE @CONT INT = 1;        
    DECLARE @CODE_EC VARCHAR(100);        
    DECLARE @COD_PLANDZERO_SERVICE INT = NULL        
    DECLARE @PLANDZEROTODAY BIT = 0;        
    DECLARE @CURRENTHOUR INT;        
    DECLARE @PREVISION_RECEIVEDATE DATETIME;        
    DECLARE @TOMORROW_MORNING DATETIME;        
    DECLARE @PlanDZeroHour INT = 0;        
    DECLARE @PAYDAY DATETIME;        
    DECLARE @OUTPUT_TITTLE TABLE        
                           (        
                               COD_TITTLE INT,        
                               COD_BRAND  INT,        
                               COD_TTYPE  INT,        
                               COD_AC     INT,        
                               ANTECIP    DECIMAL(22, 6) ,      
          COD_EC   INT,      
          PREVISION_PAYMENT DATE      
                           );        
    DECLARE @COD_AC INT;       
 DECLARE @COD_MODEL INT;      
      
    DECLARE @OK INT = 1;  
        
    SELECT @COD_TRAN = [TRANSACTION].COD_TRAN        
         , @EC_SOURCE_COD = COMMERCIAL_ESTABLISHMENT.COD_EC        
         , @EC_SOURCE = COMMERCIAL_ESTABLISHMENT.CPF_CNPJ        
         , @BRAND = [TRANSACTION].BRAND        
         , @QTY_PLOT = [TRANSACTION].PLOTS        
         , @SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN        
         , @TYPE_TRAN = [TRANSACTION].COD_TTYPE        
         , @AFFILIATOR = AFFILIATOR.CPF_CNPJ        
         , @AMOUNT_TR = [TRANSACTION].AMOUNT        
         , @AFF_SOURCE_COD = AFFILIATOR.COD_AFFILIATOR        
         , @COD_BRAND = BRAND.COD_BRAND        
         , @COD_SITUATION = [TRANSACTION].COD_SITUATION                 , @TRAN_DATE = dbo.FN_FUS_UTF([TRANSACTION].CREATED_AT)        
         , @CODASS_EQUIP = [TRANSACTION].COD_ASS_DEPTO_TERMINAL        
         , @TX_ACQ = ASS_TR_TYPE_COMP.TAX_VALUE        
         , @INTERVAL_ACQ = ASS_TR_TYPE_COMP.INTERVAL        
         , @CODE_EC = COMMERCIAL_ESTABLISHMENT.CODE        
 , @COD_AC = PRODUCTS_ACQUIRER.COD_AC        
   ,@COD_MODEL = EQUIPMENT_MODEL.COD_MODEL      
      
    FROM [TRANSACTION] WITH (NOLOCK)        
             JOIN ASS_DEPTO_EQUIP        
                  ON ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL        
             JOIN DEPARTMENTS_BRANCH        
                  ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH        
             JOIN BRANCH_EC        
                  ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH        
             JOIN COMMERCIAL_ESTABLISHMENT        
                  ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC        
             INNER JOIN ASS_TR_TYPE_COMP        
                        ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = [TRANSACTION].COD_ASS_TR_COMP        
             JOIN AFFILIATOR        
                  ON AFFILIATOR.COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR        
             JOIN BRAND        
                  ON BRAND.NAME = [TRANSACTION].BRAND        
                      AND BRAND.COD_TTYPE = [TRANSACTION].COD_TTYPE        
             JOIN PRODUCTS_ACQUIRER ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ       
     JOIN EQUIPMENT       
     ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP      
   JOIN EQUIPMENT_MODEL       
 ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL      
    WHERE [TRANSACTION].CODE = @NSU        
        
    IF @COD_SITUATION <> 22        
        SET @OK = 0;--THROW 60000, '300 - Invalid situation for transaction', 1;        
        
    IF @CODE_EC <> @MERCHANT        
        SET @OK = 0;--THROW 60000, '301 - Invalid Merchant source', 1        
        
    SELECT @AMOUNT_SPLIT = SUM(AMOUNT)        
    FROM @ITEM        
        
    IF @AMOUNT_TR <> @AMOUNT_SPLIT        
        SET @OK = 0;--THROW 60000, '303 - Invalid amount for split ', 1;        
        
    SELECT @QTY = COUNT(*)        
    FROM @ITEM        
    WHERE [DOC_AFFILIATOR] <> @AFFILIATOR        
    IF @QTY > 0        
        SET @OK = 0;--THROW 60000, '304 -Invalid Affiliator between Merchant and transaction', 1;        
        
    SELECT @COD_PLANDZERO_SERVICE = COD_ITEM_SERVICE        
    FROM ITEMS_SERVICES_AVAILABLE        
    WHERE NAME = 'PlanDZero'        
        
    SET @CURRENTHOUR = DATEPART(HOUR, @TRAN_DATE);        
    IF EXISTS(SELECT COD_SCH_PLANDZERO        
              FROM PlanDZeroSchedule        
              WHERE WindowMaxHour > @CURRENTHOUR)        
        BEGIN        
            SET @PLANDZEROTODAY = 1        
            SET @PlanDZeroHour = (SELECT TOP 1 WindowMaxHour        
                                  FROM PlanDZeroSchedule        
                                  WHERE WindowMaxHour > @CURRENTHOUR        
                                  ORDER BY WindowMaxHour)        
        END        
        
    SET @TOMORROW_MORNING = CAST(DATEADD(DAY, 1, @TRAN_DATE) AS DATE)        
        
    SELECT ASS_TAX_DEPART.COD_ASS_TX_DEP          AS                                               COD_TX_MERCHANT        
         , COMMERCIAL_ESTABLISHMENT.ACTIVE        AS                                               ACTIVE_MERCHANT        
         , COMMERCIAL_ESTABLISHMENT.COD_EC                                                         MERCHANT        
         , COMMERCIAL_ESTABLISHMENT.CPF_CNPJ      AS                                               DOC_MERCHANT        
         , AFFILIATOR.COD_AFFILIATOR              AS                                               AFFILIATOR        
         , AFFILIATOR.CPF_CNPJ                    AS                                               DOC_AFFILIATOR        
         , ASS_TAX_DEPART.PARCENTAGE              AS                                               MDR        
         , ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE AS                                               ANTICIP        
         , ASS_TAX_DEPART.INTERVAL        
         , ASS_TAX_DEPART.RATE        
         , [PLAN].COD_T_PLAN        
         , ITEM.AMOUNT        
         , NULL            AS                                               COD_SPLIT_PROD        
         , IIF(SA.COD_SERVICE IS NULL OR @PLANDZEROTODAY = 0 OR (SELECT COD_T_PLAN        
                                                                 FROM DEPARTMENTS_BRANCH db        
                                  WHERE db.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH)        
        = 1, NULL, CAST(JSON_VALUE(SA.CONFIG_JSON,        
                                   IIF(@TYPE_TRAN = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))) [PLANDZERO_MDR]        
    INTO #EC        
    FROM @ITEM ITEM        
             JOIN COMMERCIAL_ESTABLISHMENT        
                  ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ =        
                     REPLACE(REPLACE(REPLACE(ITEM.[DOC_MERCHANT], '/', ''), '-', ''), '.', '')        
             LEFT JOIN AFFILIATOR        
                       ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR        
             JOIN BRANCH_EC        
                  ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC        
             JOIN DEPARTMENTS_BRANCH        
                  ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH        
             JOIN ASS_TAX_DEPART        
                  ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH        
       AND isnull(ASS_TAX_DEPART.COD_MODEL,  @COD_MODEL) = @COD_MODEL      
             JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN        
             LEFT JOIN BRAND        
                       ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND        
             LEFT JOIN SERVICES_AVAILABLE SA        
                       ON COMMERCIAL_ESTABLISHMENT.COD_EC = SA.COD_EC        
                           AND [SA].ACTIVE = 1        
                           AND SA.COD_ITEM_SERVICE = @COD_PLANDZERO_SERVICE        
         
    WHERE ASS_TAX_DEPART.ACTIVE = 1        
      AND ASS_TAX_DEPART.COD_TTYPE = @TYPE_TRAN        
      AND @QTY_PLOT BETWEEN ASS_TAX_DEPART.QTY_INI_PLOTS AND ASS_TAX_DEPART.QTY_FINAL_PLOTS        
      AND ASS_TAX_DEPART.COD_SOURCE_TRAN = @SOURCE_TRAN        
      AND (BRAND.COD_BRAND = @COD_BRAND        
        OR BRAND.COD_BRAND IS NULL)        
      AND AFFILIATOR.CPF_CNPJ = ITEM.DOC_AFFILIATOR        
        
    IF (SELECT COUNT(*)        
        FROM #EC        
        WHERE ACTIVE_MERCHANT = 0)        
        > 0        
        SET @OK = 0;--THROW 60000, '305 - One or More Merchants are inactive', 1;        
        
      
    IF (SELECT COUNT(*)        
        FROM #EC)        
        <> (SELECT COUNT(*)        
            FROM @ITEM)        
        SET @OK = 0;--THROW 60000, '306 - One or More Merchants don''t have plan available to receive this transaction', 1;        
 IF @OK = 1  
 BEGIN  
    INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)        
    SELECT @COD_TRAN        
         , @NSU        
         , 3        
         , ''        
        
    UPDATE [TRANSACTION]        
    SET COD_SITUATION = 3        
      , MODIFY_DATE   = GETDATE()        
      , COMMENT       = ''        
      , CODE_ERROR    = 200        
    FROM [TRANSACTION] WITH (NOLOCK)        
    WHERE [TRANSACTION].COD_TRAN = @COD_TRAN;        
        
    IF @@rowcount < 1        
        THROW 60001, 'COULD NOT UPDATE [TRANSACTION] ', 1;        
        
    UPDATE PROCESS_BG_STATUS        
    SET STATUS_PROCESSED = 0        
    WHERE CODE = @COD_TRAN        
        
    IF @AFFILIATOR IS NOT NULL        
        BEGIN        
            INSERT INTO @AFF_DATA (COD_TRAN,        
                                   [COD_AFFILIATOR],        
                              [NSU],        
                                   [COD_OPER_COST_AFF],        
                                   [PERCENTAGE_COST],        
                                   [COD_PLAN_TAX_AFF],        
                                   [PERCENTAGE],        
                                   [RATE],        
                                   [ANTICIPATION_PERCENTAGE])        
            SELECT @COD_TRAN        
                 , @AFF_SOURCE_COD        
                 , @NSU        
                 , OP_COST.COD_OPER_COST_AFF        
               , OP_COST.PERCENTAGE_COST        
                 , PLAN_TAX_AFFILIATOR.COD_PLAN_TAX_AFF        
                 , PLAN_TAX_AFFILIATOR.[PERCENTAGE]        
                 , PLAN_TAX_AFFILIATOR.RATE        
                 , PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE        
            FROM AFFILIATOR        
                     INNER JOIN OPERATION_COST_AFFILIATOR OP_COST        
                                ON OP_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR        
                     INNER JOIN PROGRESSIVE_COST_AFFILIATOR PROG_COST        
                                ON PROG_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR        
                     INNER JOIN PLAN_TAX_AFFILIATOR        
                                ON PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR        
     AND isnull(PLAN_TAX_AFFILIATOR.COD_MODEL,  @COD_MODEL) = @COD_MODEL      
      
                     INNER JOIN [PLAN] ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN        
                AND [PLAN].COD_PLAN_CATEGORY <> 3        
    --AND (PLAN_TAX_AFFILIATOR.COD_MODEL= @COD_MODEL OR PLAN_TAX_AFFILIATOR.COD_MODEL IS NULL)      
      
            WHERE [PLAN_TAX_AFFILIATOR].COD_TTYPE = @TYPE_TRAN        
              AND [PLAN_TAX_AFFILIATOR].QTY_INI_PLOTS <= @QTY_PLOT        
              AND [PLAN_TAX_AFFILIATOR].QTY_FINAL_PLOTS >= @QTY_PLOT        
              AND [PLAN_TAX_AFFILIATOR].ACTIVE = 1        
              AND [OP_COST].ACTIVE = 1        
              AND PROG_COST.ACTIVE = 1        
   AND AFFILIATOR.COD_AFFILIATOR = @AFF_SOURCE_COD        
              AND AFFILIATOR.ACTIVE = 1        
              AND ([PLAN_TAX_AFFILIATOR].COD_BRAND = @COD_BRAND        
                OR PLAN_TAX_AFFILIATOR.COD_BRAND IS NULL)        
              AND [PLAN_TAX_AFFILIATOR].COD_SOURCE_TRAN = @SOURCE_TRAN        
        END;        
        
    -- TITTLE                      
        
    SET @PAYDAY = CAST(@TRAN_DATE AS DATE)        
        
    WHILE @CONT <= @QTY_PLOT        
        BEGIN        
            -- PLAN WITHOUT ANTICIPATION                      
            SET @PREVISION_RECEIVEDATE = DATEADD(DAY, (@INTERVAL_ACQ * @CONT), @TRAN_DATE)        
        
            INSERT INTO [TRANSACTION_TITLES] (CODE,        
                                              COD_TRAN,        
                                              PLOT,        
                                              AMOUNT,        
                                              COD_ASS_DEPTO_TERMINAL,        
                                              TAX_INITIAL,        
                                              RATE,        
                                              PREVISION_PAY_DATE,        
                                              COD_SITUATION,        
                                              ACQ_TAX,        
                                              INTERVAL_INITIAL,        
                                              PREVISION_RECEIVE_DATE,        
                                              COD_SITUATION_RECEIVE,        
                                              COD_TYPE_TRAN_TITLE,        
                                              ANTICIP_PERCENT,        
                                              COD_EC,        
                                              COD_ASS_TX_DEP,        
                                              QTY_DAYS_ANTECIP,        
                                          COD_SPLIT_PROD,        
                                              TAX_PLANDZERO)        
            OUTPUT inserted.COD_TITLE , @COD_BRAND, @TYPE_TRAN, @COD_AC , inserted.ANTICIP_PERCENT , inserted.COD_EC , inserted.PREVISION_PAY_DATE INTO @OUTPUT_TITTLE        
            SELECT CONCAT(NEXT VALUE FOR SEQ_TRANSACTION_TITLE, MERCHANT)        
                 , @COD_TRAN        
                 , @CONT        
                 , (AMOUNT / @QTY_PLOT)        
                 , @CODASS_EQUIP        
                 , MDR        
                 , RATE        
                 , IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY),        
                   IIF(@PLANDZEROTODAY = 1, DATEADD(HOUR, @PlanDZeroHour, @PAYDAY), @TOMORROW_MORNING))        
                 , 4        
                 , @TX_ACQ        
                 , INTERVAL        
                 , @PREVISION_RECEIVEDATE        
                 , 4        
                 , 1        
                 , IIF((PLANDZERO_MDR IS NOT NULL AND @TYPE_TRAN != 1) OR        
                       CAST(@PREVISION_RECEIVEDATE AS DATE) <= DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY), 0, ANTICIP)        
                 , MERCHANT        
                 , COD_TX_MERCHANT        
  , ((@CONT * 30) - DATEDIFF(DAY, CAST([dbo].[FN_FUS_UTF](GETDATE()) AS DATE),        
                                            IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY),        
                                                IIF(@PLANDZEROTODAY = 1, @PAYDAY, @TOMORROW_MORNING))))        
                 , COD_SPLIT_PROD        
                 , PLANDZERO_MDR        
            FROM #EC        
            WHERE COD_T_PLAN = 1        
        
            IF @@rowcount < (SELECT COUNT(*)        
                             FROM #EC        
                             WHERE COD_T_PLAN = 1)        
                THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;        
        
        
      
         INSERT INTO ASS_UR_TITTLE            
  (            
  COD_TITLE,            
  COD_UR,            
  PREVISION_PAYMENT_DATE,            
  COD_SOURCE_TRAN ,        
  COD_EC ,        
  COD_SITUATION        
  )               
  SELECT            
  OUTP.COD_TITTLE,            
  RECEIVABLE_UNITS.COD_UR,            
  OUTP.PREVISION_PAYMENT,            
  @SOURCE_TRAN ,        
  OUTP.COD_EC,        
  4        
  FROM             
  RECEIVABLE_UNITS        
  JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR            
  JOIN ACQUIRER ON ACQUIRER.COD_AC = @COD_AC            
  JOIN ACQUIRER_GROUP ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP        
  JOIN BRAND ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND      
  JOIN @OUTPUT_TITTLE OUTP ON OUTP.COD_AC = ACQUIRER.COD_AC      
   AND OUTP.COD_BRAND = BRAND.COD_BRAND      
  LEFT JOIN ASS_UR_TITTLE ON ASS_UR_TITTLE.COD_TITLE = OUTP.COD_TITTLE            
  where            
   TYPE_ARR_SLC.COD_TTYPE = OUTP.COD_TTYPE AND            
   TYPE_ARR_SLC.ANTICIP =             
   (            
   CASE            
   WHEN OUTP.ANTECIP > 0 AND OUTP.COD_TTYPE = 1 THEN 1            
   ELSE 0            
   END            
  )            
   AND            
 RECEIVABLE_UNITS.COD_BRAND = OUTP.COD_BRAND AND            
   RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP            
  AND ASS_UR_TITTLE.COD_TITLE IS NULL            
           
      
      
        
            DELETE FROM @OUTPUT_TITTLE;        
        
            -- PLAN WITH ANTICIPATION                                 
        
            INSERT INTO [TRANSACTION_TITLES] (CODE,        
                                              COD_TRAN,        
                                              PLOT,        
                                              AMOUNT,        
                                              COD_ASS_DEPTO_TERMINAL,        
                                              TAX_INITIAL,        
                         RATE,        
                                              PREVISION_PAY_DATE,        
                                              COD_SITUATION,        
                                              ACQ_TAX,        
                                              INTERVAL_INITIAL,        
                                              PREVISION_RECEIVE_DATE,        
                                              COD_SITUATION_RECEIVE,        
                                              COD_TYPE_TRAN_TITLE,        
                                              ANTICIP_PERCENT,        
                                              COD_EC,        
                                              COD_ASS_TX_DEP,        
                                              QTY_DAYS_ANTECIP,        
                                              COD_SPLIT_PROD,        
                                           TAX_PLANDZERO)        
            OUTPUT inserted.COD_TITLE , @COD_BRAND, @TYPE_TRAN, @COD_AC , inserted.ANTICIP_PERCENT,  inserted.COD_EC , inserted.PREVISION_PAY_DATE  INTO @OUTPUT_TITTLE        
        
            SELECT CONCAT(NEXT VALUE FOR SEQ_TRANSACTION_TITLE, MERCHANT)        
                 , @COD_TRAN        
                 , @CONT        
                 , (AMOUNT / @QTY_PLOT)        
                 , @CODASS_EQUIP        
                 , MDR        
                 , RATE        
                 , IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, INTERVAL, @PAYDAY),        
                       IIF(@PLANDZEROTODAY = 1, DATEADD(HOUR, @PlanDZeroHour, @PAYDAY), @TOMORROW_MORNING))        
                 , 4        
     , @TX_ACQ        
                 , INTERVAL        
                 , @PREVISION_RECEIVEDATE        
                 , 4        
                 , 1        
                 , IIF((PLANDZERO_MDR IS NOT NULL AND @TYPE_TRAN != 1) OR        
                       CAST(@PREVISION_RECEIVEDATE AS DATE) <= IIF(PLANDZERO_MDR IS NULL,        
                                                                   DATEADD(DAY, INTERVAL, @PAYDAY), @TRAN_DATE), 0,        
                       ANTICIP)        
                 , MERCHANT        
                 , COD_TX_MERCHANT        
                 , ((@CONT * 30) - DATEDIFF(DAY, CAST([dbo].[FN_FUS_UTF](GETDATE()) AS DATE),        
                                            IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, INTERVAL, @PAYDAY),        
                                                IIF(@PLANDZEROTODAY = 1, @PAYDAY, @TOMORROW_MORNING))))        
                 , COD_SPLIT_PROD        
                 , PLANDZERO_MDR        
            FROM #EC        
            WHERE COD_T_PLAN = 2        
        
            IF @@rowcount < (SELECT COUNT(*)        
                             FROM #EC        
                             WHERE COD_T_PLAN = 2)        
                THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;        
        
                INSERT INTO ASS_UR_TITTLE            
  (            
  COD_TITLE,            
  COD_UR,            
  PREVISION_PAYMENT_DATE,            
  COD_SOURCE_TRAN ,        
  COD_EC ,        
  COD_SITUATION        
  )               
  SELECT            
  OUTP.COD_TITTLE,            
  RECEIVABLE_UNITS.COD_UR,            
  OUTP.PREVISION_PAYMENT,            
  @SOURCE_TRAN ,        
  OUTP.COD_EC,        
  4        
  FROM             
  RECEIVABLE_UNITS        
  JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR            
  JOIN ACQUIRER ON ACQUIRER.COD_AC = @COD_AC            
  JOIN ACQUIRER_GROUP ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP        
  JOIN BRAND ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND      
  JOIN @OUTPUT_TITTLE OUTP ON OUTP.COD_AC = ACQUIRER.COD_AC      
   AND OUTP.COD_BRAND = BRAND.COD_BRAND      
  LEFT JOIN ASS_UR_TITTLE ON ASS_UR_TITTLE.COD_TITLE = OUTP.COD_TITTLE            
  where            
   TYPE_ARR_SLC.COD_TTYPE = OUTP.COD_TTYPE AND            
   TYPE_ARR_SLC.ANTICIP =             
   (            
   CASE            
   WHEN OUTP.ANTECIP > 0 AND OUTP.COD_TTYPE = 1 THEN 1            
   ELSE 0            
   END            
  )            
   AND            
 RECEIVABLE_UNITS.COD_BRAND = OUTP.COD_BRAND AND            
   RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP            
  AND ASS_UR_TITTLE.COD_TITLE IS NULL            
           
            DELETE FROM @OUTPUT_TITTLE;        
        
        
            SET @CONT = @CONT + 1;        
        END;        
        
    IF @AFF_SOURCE_COD IS NOT NULL        
        BEGIN        
            SELECT AFF.[COD_AFFILIATOR]        
                 , AFF.COD_TRAN        
                 , COD_TITLE        
                 , [TRANSACTION_TITLES].PREVISION_PAY_DATE        
                 , AFF.[COD_OPER_COST_AFF]        
                 , AFF.[PERCENTAGE_COST]        
                 , AFF.[COD_PLAN_TAX_AFF]        
                 , AFF.[PERCENTAGE]        
                 , AFF.[RATE]        
                 , IIF(SA.COD_ITEM_SERVICE IS NOT NULL OR [TRANSACTION_TITLES].ANTICIP_PERCENT = 0, 0,        
                       AFF.[ANTICIPATION_PERCENTAGE]) AS                                                                             ANTICIP_PERCENT        
                 , IIF(SA.COD_SERVICE IS NULL, NULL, CAST(JSON_VALUE(SA.CONFIG_JSON,        
                                                                     IIF(@TYPE_TRAN = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))) [PLANDZERO_MDR]        
            INTO #COST        
            FROM [TRANSACTION_TITLES]        
                     JOIN @AFF_DATA AFF        
                          ON AFF.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN        
                     LEFT JOIN SERVICES_AVAILABLE SA        
                               ON SA.COD_AFFILIATOR = AFF.COD_AFFILIATOR        
                                   AND SA.ACTIVE = 1        
                                   AND SA.COD_ITEM_SERVICE = @COD_PLANDZERO_SERVICE        
        AND SA.COD_EC IS NULL        
            WHERE [TRANSACTION_TITLES].COD_TRAN = @COD_TRAN        
        
            INSERT INTO TRANSACTION_TITLES_COST (COD_AFFILIATOR,        
                                                 COD_TITLE,        
                                                 COD_OPER_COST_AFF,        
                                                 OPER_VALUE,        
                                                 [PERCENTAGE],        
                                                 PREVISION_PAY_DATE,        
                                                 COD_SITUATION,        
                                                 RATE_PLAN,        
                                                 ANTICIP_PERCENT,        
                                                 TAX_PLANDZERO)        
            SELECT COD_AFFILIATOR        
                 , COD_TITLE        
                 , [COD_OPER_COST_AFF]        
                 , [PERCENTAGE_COST]        
                 , [PERCENTAGE]        
                 , PREVISION_PAY_DATE        
                 , 4        
                 , [RATE]        
                 , ANTICIP_PERCENT        
                 , PLANDZERO_MDR        
            FROM #COST        
        END;        
        
    IF (SELECT COUNT(*)        
        FROM #EC        
        WHERE COD_T_PLAN = 2        
          AND PLANDZERO_MDR IS NOT NULL)        
        > 0        
        BEGIN        
        
            INSERT INTO TRANSACTION_SERVICES (CREATED_AT, COD_ITEM_SERVICE, COD_TRAN, TAX_PLANDZERO_EC,        
                                              TAX_PLANDZERO_AFF, COD_EC)        
            SELECT DISTINCT current_timestamp        
                          , @COD_PLANDZERO_SERVICE        
                          , @COD_TRAN        
                          , e.PLANDZERO_MDR        
                         , IIF(e.PLANDZERO_MDR = 0 OR e.PLANDZERO_MDR IS NULL, NULL, (SELECT TOP 1 c.PLANDZERO_MDR        
                                                              FROM #COST c        
                                                                                       WHERE c.COD_AFFILIATOR = e.AFFILIATOR)        
                )        
                          , e.MERCHANT        
            FROM #EC e        
            WHERE COD_T_PLAN = 2        
              AND e.PLANDZERO_MDR IS NOT NULL        
        END;        
 END  

    EXEC [SP_VAL_LIMIT_EC] @CODETR = @NSU;

 	UPDATE PROCESS_BG_STATUS      
    SET STATUS_PROCESSED = 0      
    WHERE CODE = @COD_TRAN    


END;


GO

IF OBJECT_ID('SP_GEN_SPLIT_TRANSACTION') IS NOT NULL
DROP PROCEDURE [SP_GEN_SPLIT_TRANSACTION];

GO
CREATE PROCEDURE SP_GEN_SPLIT_TRANSACTION      
/**************************************************************************************************************                            
------------------------------------------------------------------------------------------------------------                             
    Project.......: TKPP                                                  
------------------------------------------------------------------------------------------------------------                               
    Author                 VERSION        Date                  Description                                              
------------------------------------------------------------------------------------------------------------                               
    Kennedy Alef             V1       27/07/2018                Creation                                                 
    Caike Ucha              V2       06/05/2020                Add Cod_split_tran na titles                             
    Luiz Aquino             V3       29/06/2020                ET-895 PlanDZero           
	 Caike uchoa            V4       17/11/2020                add valid limit ec   
	 Caike Uchoa            v5       17/11/2020                alter reprocessamento relatório
**************************************************************************************************************/ (@ITEM ITEM_SPLIT READONLY,      
                                                                                                                 @NSU VARCHAR(100),      
                                                                                                                 @MERCHANT VARCHAR(100))      
AS      
BEGIN      
      
    DECLARE @EC_SOURCE_COD INT      
    DECLARE @AFF_SOURCE_COD INT;      
    DECLARE @EC_SOURCE VARCHAR(100);      
    DECLARE @BRAND VARCHAR(100);      
    DECLARE @COD_BRAND INT;      
    DECLARE @QTY_PLOT INT;      
    DECLARE @SOURCE_TRAN INT;      
    DECLARE @TYPE_TRAN INT;      
    DECLARE @AFFILIATOR VARCHAR(100);      
    DECLARE @AMOUNT_TR DECIMAL(22, 6);      
    DECLARE @AMOUNT_SPLIT DECIMAL(22, 6);      
    DECLARE @AFF_DATA TR_AFF_COST_DATA;      
    DECLARE @QTY INT = 0;      
    DECLARE @COD_TRAN INT;      
    DECLARE @COD_SITUATION INT;      
    DECLARE @CODASS_EQUIP INT      
    DECLARE @TRAN_DATE DATETIME      
    DECLARE @TX_ACQ DECIMAL(22, 6);      
    DECLARE @INTERVAL_ACQ INT;      
    DECLARE @CONT INT = 1;      
    DECLARE @CODE_EC VARCHAR(100);      
    DECLARE @COD_PLANDZERO_SERVICE INT = NULL      
    DECLARE @PLANDZEROTODAY BIT = 0;      
    DECLARE @CURRENTHOUR INT;      
    DECLARE @PREVISION_RECEIVEDATE DATETIME;      
    DECLARE @TOMORROW_MORNING DATETIME;      
    DECLARE @PlanDZeroHour INT = 0;      
    DECLARE @PAYDAY DATETIME;      
    DECLARE @OUTPUT_TITTLE TABLE      
                           (      
                               COD_TITTLE INT,      
                               COD_BRAND  INT,      
                               COD_TTYPE  INT,      
                               COD_AC     INT,      
                               ANTECIP    DECIMAL(22, 6) ,    
          COD_EC   INT,    
          PREVISION_PAYMENT DATE    
                           );      
    DECLARE @COD_AC INT;     
 DECLARE @COD_MODEL INT;    
    
    
      
    SELECT @COD_TRAN = [TRANSACTION].COD_TRAN      
         , @EC_SOURCE_COD = COMMERCIAL_ESTABLISHMENT.COD_EC      
         , @EC_SOURCE = COMMERCIAL_ESTABLISHMENT.CPF_CNPJ      
         , @BRAND = [TRANSACTION].BRAND      
         , @QTY_PLOT = [TRANSACTION].PLOTS      
         , @SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN      
         , @TYPE_TRAN = [TRANSACTION].COD_TTYPE      
         , @AFFILIATOR = AFFILIATOR.CPF_CNPJ      
         , @AMOUNT_TR = [TRANSACTION].AMOUNT      
         , @AFF_SOURCE_COD = AFFILIATOR.COD_AFFILIATOR      
         , @COD_BRAND = BRAND.COD_BRAND      
         , @COD_SITUATION = [TRANSACTION].COD_SITUATION      
         , @TRAN_DATE = dbo.FN_FUS_UTF([TRANSACTION].CREATED_AT)      
         , @CODASS_EQUIP = [TRANSACTION].COD_ASS_DEPTO_TERMINAL      
         , @TX_ACQ = ASS_TR_TYPE_COMP.TAX_VALUE      
         , @INTERVAL_ACQ = ASS_TR_TYPE_COMP.INTERVAL      
         , @CODE_EC = COMMERCIAL_ESTABLISHMENT.CODE      
 , @COD_AC = PRODUCTS_ACQUIRER.COD_AC      
   ,@COD_MODEL = EQUIPMENT_MODEL.COD_MODEL    
    
    FROM [TRANSACTION] WITH (NOLOCK)      
             JOIN ASS_DEPTO_EQUIP      
                  ON ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL      
             JOIN DEPARTMENTS_BRANCH      
                  ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH      
             JOIN BRANCH_EC      
                  ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH      
             JOIN COMMERCIAL_ESTABLISHMENT      
                  ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC      
             INNER JOIN ASS_TR_TYPE_COMP      
                        ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = [TRANSACTION].COD_ASS_TR_COMP      
             JOIN AFFILIATOR      
                  ON AFFILIATOR.COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR      
             JOIN BRAND      
                  ON BRAND.NAME = [TRANSACTION].BRAND      
                      AND BRAND.COD_TTYPE = [TRANSACTION].COD_TTYPE      
             JOIN PRODUCTS_ACQUIRER ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ     
     JOIN EQUIPMENT     
     ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP    
   JOIN EQUIPMENT_MODEL     
 ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL    
    WHERE [TRANSACTION].CODE = @NSU      
      
    IF @COD_SITUATION <> 22      
        THROW 60000, '300 - Invalid situation for transaction', 1;      
      
    IF @CODE_EC <> @MERCHANT      
        THROW 60000, '301 - Invalid Merchant source', 1      
      
    SELECT @AMOUNT_SPLIT = SUM(AMOUNT)      
    FROM @ITEM      
      
    IF @AMOUNT_TR <> @AMOUNT_SPLIT      
        THROW 60000, '303 - Invalid amount for split ', 1;      
      
    SELECT @QTY = COUNT(*)      
    FROM @ITEM      
    WHERE [DOC_AFFILIATOR] <> @AFFILIATOR      
    IF @QTY > 0      
        THROW 60000, '304 -Invalid Affiliator between Merchant and transaction', 1;      
      
    SELECT @COD_PLANDZERO_SERVICE = COD_ITEM_SERVICE      
    FROM ITEMS_SERVICES_AVAILABLE      
    WHERE NAME = 'PlanDZero'      
      
    SET @CURRENTHOUR = DATEPART(HOUR, @TRAN_DATE);      
    IF EXISTS(SELECT COD_SCH_PLANDZERO      
              FROM PlanDZeroSchedule      
              WHERE WindowMaxHour > @CURRENTHOUR)      
        BEGIN      
            SET @PLANDZEROTODAY = 1      
            SET @PlanDZeroHour = (SELECT TOP 1 WindowMaxHour      
                                  FROM PlanDZeroSchedule      
                                  WHERE WindowMaxHour > @CURRENTHOUR      
                                  ORDER BY WindowMaxHour)      
        END      
      
    SET @TOMORROW_MORNING = CAST(DATEADD(DAY, 1, @TRAN_DATE) AS DATE)      
      
    SELECT ASS_TAX_DEPART.COD_ASS_TX_DEP          AS                                               COD_TX_MERCHANT      
         , COMMERCIAL_ESTABLISHMENT.ACTIVE        AS                                               ACTIVE_MERCHANT      
         , COMMERCIAL_ESTABLISHMENT.COD_EC                                                         MERCHANT      
         , COMMERCIAL_ESTABLISHMENT.CPF_CNPJ      AS                                               DOC_MERCHANT      
         , AFFILIATOR.COD_AFFILIATOR              AS                                               AFFILIATOR      
         , AFFILIATOR.CPF_CNPJ                    AS                                               DOC_AFFILIATOR      
         , ASS_TAX_DEPART.PARCENTAGE              AS                                               MDR      
         , ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE AS                                               ANTICIP      
         , ASS_TAX_DEPART.INTERVAL      
         , ASS_TAX_DEPART.RATE      
         , [PLAN].COD_T_PLAN      
         , ITEM.AMOUNT      
         , NULL            AS                                               COD_SPLIT_PROD      
         , IIF(SA.COD_SERVICE IS NULL OR @PLANDZEROTODAY = 0 OR (SELECT COD_T_PLAN      
                                                                 FROM DEPARTMENTS_BRANCH db      
                                  WHERE db.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH)      
        = 1, NULL, CAST(JSON_VALUE(SA.CONFIG_JSON,      
                                   IIF(@TYPE_TRAN = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))) [PLANDZERO_MDR]      
    INTO #EC      
    FROM @ITEM ITEM      
             JOIN COMMERCIAL_ESTABLISHMENT      
                  ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ =      
                     REPLACE(REPLACE(REPLACE(ITEM.[DOC_MERCHANT], '/', ''), '-', ''), '.', '')      
             LEFT JOIN AFFILIATOR      
                       ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR      
             JOIN BRANCH_EC      
                  ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC      
             JOIN DEPARTMENTS_BRANCH      
                  ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH      
             JOIN ASS_TAX_DEPART      
                  ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH      
       AND isnull(ASS_TAX_DEPART.COD_MODEL,  @COD_MODEL) = @COD_MODEL    
             JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN      
             LEFT JOIN BRAND      
                       ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND      
             LEFT JOIN SERVICES_AVAILABLE SA      
                       ON COMMERCIAL_ESTABLISHMENT.COD_EC = SA.COD_EC      
                           AND [SA].ACTIVE = 1      
                           AND SA.COD_ITEM_SERVICE = @COD_PLANDZERO_SERVICE      
       
    WHERE ASS_TAX_DEPART.ACTIVE = 1      
      AND ASS_TAX_DEPART.COD_TTYPE = @TYPE_TRAN      
      AND @QTY_PLOT BETWEEN ASS_TAX_DEPART.QTY_INI_PLOTS AND ASS_TAX_DEPART.QTY_FINAL_PLOTS      
      AND ASS_TAX_DEPART.COD_SOURCE_TRAN = @SOURCE_TRAN      
      AND (BRAND.COD_BRAND = @COD_BRAND      
        OR BRAND.COD_BRAND IS NULL)      
      AND AFFILIATOR.CPF_CNPJ = ITEM.DOC_AFFILIATOR      
      
    IF (SELECT COUNT(*)      
        FROM #EC      
        WHERE ACTIVE_MERCHANT = 0)      
        > 0      
        THROW 60000, '305 - One or More Merchants are inactive', 1;      
      
    
    IF (SELECT COUNT(*)      
        FROM #EC)      
        <> (SELECT COUNT(*)      
            FROM @ITEM)      
        THROW 60000, '306 - One or More Merchants don''t have plan available to receive this transaction', 1;      
      
    INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)      
    SELECT @COD_TRAN      
         , @NSU      
         , 3      
         , ''      
      
    UPDATE [TRANSACTION]      
    SET COD_SITUATION = 3      
      , MODIFY_DATE   = GETDATE()      
      , COMMENT       = ''      
      , CODE_ERROR    = 200      
    FROM [TRANSACTION] WITH (NOLOCK)      
    WHERE [TRANSACTION].COD_TRAN = @COD_TRAN;      
      
    IF @@rowcount < 1      
        THROW 60001, 'COULD NOT UPDATE [TRANSACTION] ', 1;      
     
      
    IF @AFFILIATOR IS NOT NULL      
        BEGIN      
            INSERT INTO @AFF_DATA (COD_TRAN,      
                                   [COD_AFFILIATOR],      
                                   [NSU],      
                                   [COD_OPER_COST_AFF],      
                                   [PERCENTAGE_COST],      
                                   [COD_PLAN_TAX_AFF],      
                                   [PERCENTAGE],      
                                   [RATE],      
                                   [ANTICIPATION_PERCENTAGE])      
            SELECT @COD_TRAN      
                 , @AFF_SOURCE_COD      
                 , @NSU      
                 , OP_COST.COD_OPER_COST_AFF      
               , OP_COST.PERCENTAGE_COST      
                 , PLAN_TAX_AFFILIATOR.COD_PLAN_TAX_AFF      
                 , PLAN_TAX_AFFILIATOR.[PERCENTAGE]      
                 , PLAN_TAX_AFFILIATOR.RATE      
                 , PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE      
            FROM AFFILIATOR      
                     INNER JOIN OPERATION_COST_AFFILIATOR OP_COST      
                                ON OP_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
                     INNER JOIN PROGRESSIVE_COST_AFFILIATOR PROG_COST      
                                ON PROG_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
                     INNER JOIN PLAN_TAX_AFFILIATOR      
                                ON PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
     AND isnull(PLAN_TAX_AFFILIATOR.COD_MODEL,  @COD_MODEL) = @COD_MODEL    
    
                     INNER JOIN [PLAN] ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN      
                AND [PLAN].COD_PLAN_CATEGORY <> 3      
    --AND (PLAN_TAX_AFFILIATOR.COD_MODEL= @COD_MODEL OR PLAN_TAX_AFFILIATOR.COD_MODEL IS NULL)    
    
            WHERE [PLAN_TAX_AFFILIATOR].COD_TTYPE = @TYPE_TRAN      
              AND [PLAN_TAX_AFFILIATOR].QTY_INI_PLOTS <= @QTY_PLOT      
              AND [PLAN_TAX_AFFILIATOR].QTY_FINAL_PLOTS >= @QTY_PLOT      
              AND [PLAN_TAX_AFFILIATOR].ACTIVE = 1      
              AND [OP_COST].ACTIVE = 1      
              AND PROG_COST.ACTIVE = 1      
   AND AFFILIATOR.COD_AFFILIATOR = @AFF_SOURCE_COD      
              AND AFFILIATOR.ACTIVE = 1      
              AND ([PLAN_TAX_AFFILIATOR].COD_BRAND = @COD_BRAND      
                OR PLAN_TAX_AFFILIATOR.COD_BRAND IS NULL)      
              AND [PLAN_TAX_AFFILIATOR].COD_SOURCE_TRAN = @SOURCE_TRAN      
        END;      
      
    -- TITTLE                    
      
    SET @PAYDAY = CAST(@TRAN_DATE AS DATE)      
      
    WHILE @CONT <= @QTY_PLOT      
        BEGIN      
            -- PLAN WITHOUT ANTICIPATION                    
            SET @PREVISION_RECEIVEDATE = DATEADD(DAY, (@INTERVAL_ACQ * @CONT), @TRAN_DATE)      
      
            INSERT INTO [TRANSACTION_TITLES] (CODE,      
                                              COD_TRAN,      
                                              PLOT,      
                                              AMOUNT,      
                                              COD_ASS_DEPTO_TERMINAL,      
                                              TAX_INITIAL,      
                                              RATE,      
                                              PREVISION_PAY_DATE,      
                                              COD_SITUATION,      
                                              ACQ_TAX,      
                                              INTERVAL_INITIAL,      
                                              PREVISION_RECEIVE_DATE,      
                                              COD_SITUATION_RECEIVE,      
                                              COD_TYPE_TRAN_TITLE,      
                                              ANTICIP_PERCENT,      
                                              COD_EC,      
                                              COD_ASS_TX_DEP,      
                                              QTY_DAYS_ANTECIP,      
                                              COD_SPLIT_PROD,      
                                              TAX_PLANDZERO)      
            OUTPUT inserted.COD_TITLE , @COD_BRAND, @TYPE_TRAN, @COD_AC , inserted.ANTICIP_PERCENT , inserted.COD_EC , inserted.PREVISION_PAY_DATE INTO @OUTPUT_TITTLE      
            SELECT CONCAT(NEXT VALUE FOR SEQ_TRANSACTION_TITLE, MERCHANT)      
                 , @COD_TRAN      
                 , @CONT      
                 , (AMOUNT / @QTY_PLOT)      
                 , @CODASS_EQUIP      
                 , MDR      
                 , RATE      
                 , IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY),      
                   IIF(@PLANDZEROTODAY = 1, DATEADD(HOUR, @PlanDZeroHour, @PAYDAY), @TOMORROW_MORNING))      
                 , 4      
                 , @TX_ACQ      
                 , INTERVAL      
                 , @PREVISION_RECEIVEDATE      
                 , 4      
                 , 1      
                 , IIF((PLANDZERO_MDR IS NOT NULL AND @TYPE_TRAN != 1) OR      
                       CAST(@PREVISION_RECEIVEDATE AS DATE) <= DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY), 0, ANTICIP)      
                 , MERCHANT      
                 , COD_TX_MERCHANT      
  , ((@CONT * 30) - DATEDIFF(DAY, CAST([dbo].[FN_FUS_UTF](GETDATE()) AS DATE),      
                                            IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY),      
                                                IIF(@PLANDZEROTODAY = 1, @PAYDAY, @TOMORROW_MORNING))))      
                 , COD_SPLIT_PROD      
                 , PLANDZERO_MDR      
            FROM #EC      
            WHERE COD_T_PLAN = 1      
      
            IF @@rowcount < (SELECT COUNT(*)      
                             FROM #EC      
                             WHERE COD_T_PLAN = 1)      
                THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;      
      
      
    
         INSERT INTO ASS_UR_TITTLE          
  (          
  COD_TITLE,          
  COD_UR,          
  PREVISION_PAYMENT_DATE,          
  COD_SOURCE_TRAN ,      
  COD_EC ,      
  COD_SITUATION      
  )             
  SELECT          
  OUTP.COD_TITTLE,          
  RECEIVABLE_UNITS.COD_UR,          
  OUTP.PREVISION_PAYMENT,          
  @SOURCE_TRAN ,      
  OUTP.COD_EC,      
  4      
  FROM           
  RECEIVABLE_UNITS      
  JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR          
  JOIN ACQUIRER ON ACQUIRER.COD_AC = @COD_AC          
  JOIN ACQUIRER_GROUP ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP      
  JOIN BRAND ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND    
  JOIN @OUTPUT_TITTLE OUTP ON OUTP.COD_AC = ACQUIRER.COD_AC    
   AND OUTP.COD_BRAND = BRAND.COD_BRAND    
  LEFT JOIN ASS_UR_TITTLE ON ASS_UR_TITTLE.COD_TITLE = OUTP.COD_TITTLE          
  where          
   TYPE_ARR_SLC.COD_TTYPE = OUTP.COD_TTYPE AND          
   TYPE_ARR_SLC.ANTICIP =           
   (          
   CASE          
   WHEN OUTP.ANTECIP > 0 AND OUTP.COD_TTYPE = 1 THEN 1          
   ELSE 0          
   END          
  )          
   AND          
 RECEIVABLE_UNITS.COD_BRAND = OUTP.COD_BRAND AND          
   RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP          
  AND ASS_UR_TITTLE.COD_TITLE IS NULL          
         
    
    
      
            DELETE FROM @OUTPUT_TITTLE;      
      
            -- PLAN WITH ANTICIPATION                               
      
            INSERT INTO [TRANSACTION_TITLES] (CODE,      
                                              COD_TRAN,      
                                              PLOT,      
                                              AMOUNT,      
                                              COD_ASS_DEPTO_TERMINAL,      
                                              TAX_INITIAL,      
                                              RATE,      
                                              PREVISION_PAY_DATE,      
                                              COD_SITUATION,      
                                              ACQ_TAX,      
                                              INTERVAL_INITIAL,      
                                              PREVISION_RECEIVE_DATE,      
                                              COD_SITUATION_RECEIVE,      
                                              COD_TYPE_TRAN_TITLE,      
                                              ANTICIP_PERCENT,      
                                              COD_EC,      
                                              COD_ASS_TX_DEP,      
                                              QTY_DAYS_ANTECIP,      
                                              COD_SPLIT_PROD,      
                                           TAX_PLANDZERO)      
            OUTPUT inserted.COD_TITLE , @COD_BRAND, @TYPE_TRAN, @COD_AC , inserted.ANTICIP_PERCENT,  inserted.COD_EC , inserted.PREVISION_PAY_DATE  INTO @OUTPUT_TITTLE      
      
            SELECT CONCAT(NEXT VALUE FOR SEQ_TRANSACTION_TITLE, MERCHANT)      
                 , @COD_TRAN      
                 , @CONT      
                 , (AMOUNT / @QTY_PLOT)      
                 , @CODASS_EQUIP      
                 , MDR      
                 , RATE      
                 , IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, INTERVAL, @PAYDAY),      
                       IIF(@PLANDZEROTODAY = 1, DATEADD(HOUR, @PlanDZeroHour, @PAYDAY), @TOMORROW_MORNING))      
                 , 4      
     , @TX_ACQ      
                 , INTERVAL      
                 , @PREVISION_RECEIVEDATE      
                 , 4      
                 , 1      
                 , IIF((PLANDZERO_MDR IS NOT NULL AND @TYPE_TRAN != 1) OR      
                       CAST(@PREVISION_RECEIVEDATE AS DATE) <= IIF(PLANDZERO_MDR IS NULL,      
                                                                   DATEADD(DAY, INTERVAL, @PAYDAY), @TRAN_DATE), 0,      
                       ANTICIP)      
                 , MERCHANT      
                 , COD_TX_MERCHANT      
                 , ((@CONT * 30) - DATEDIFF(DAY, CAST([dbo].[FN_FUS_UTF](GETDATE()) AS DATE),      
                                            IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, INTERVAL, @PAYDAY),      
                                                IIF(@PLANDZEROTODAY = 1, @PAYDAY, @TOMORROW_MORNING))))      
                 , COD_SPLIT_PROD      
                 , PLANDZERO_MDR      
            FROM #EC      
            WHERE COD_T_PLAN = 2      
      
            IF @@rowcount < (SELECT COUNT(*)      
                             FROM #EC      
                             WHERE COD_T_PLAN = 2)      
                THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;      
      
                INSERT INTO ASS_UR_TITTLE          
  (          
  COD_TITLE,          
  COD_UR,          
  PREVISION_PAYMENT_DATE,          
  COD_SOURCE_TRAN ,      
  COD_EC ,      
  COD_SITUATION      
  )             
  SELECT          
  OUTP.COD_TITTLE,          
  RECEIVABLE_UNITS.COD_UR,          
  OUTP.PREVISION_PAYMENT,          
  @SOURCE_TRAN ,      
  OUTP.COD_EC,      
  4      
  FROM           
  RECEIVABLE_UNITS      
  JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR          
  JOIN ACQUIRER ON ACQUIRER.COD_AC = @COD_AC          
  JOIN ACQUIRER_GROUP ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP      
  JOIN BRAND ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND    
  JOIN @OUTPUT_TITTLE OUTP ON OUTP.COD_AC = ACQUIRER.COD_AC    
   AND OUTP.COD_BRAND = BRAND.COD_BRAND    
  LEFT JOIN ASS_UR_TITTLE ON ASS_UR_TITTLE.COD_TITLE = OUTP.COD_TITTLE          
  where          
   TYPE_ARR_SLC.COD_TTYPE = OUTP.COD_TTYPE AND          
   TYPE_ARR_SLC.ANTICIP =           
   (          
   CASE          
   WHEN OUTP.ANTECIP > 0 AND OUTP.COD_TTYPE = 1 THEN 1          
   ELSE 0          
   END          
  )          
   AND          
 RECEIVABLE_UNITS.COD_BRAND = OUTP.COD_BRAND AND          
   RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP          
  AND ASS_UR_TITTLE.COD_TITLE IS NULL          
         
            DELETE FROM @OUTPUT_TITTLE;      
      
      
            SET @CONT = @CONT + 1;      
        END;      
      
    IF @AFF_SOURCE_COD IS NOT NULL      
        BEGIN      
            SELECT AFF.[COD_AFFILIATOR]      
                 , AFF.COD_TRAN      
                 , COD_TITLE      
                 , [TRANSACTION_TITLES].PREVISION_PAY_DATE      
                 , AFF.[COD_OPER_COST_AFF]      
                 , AFF.[PERCENTAGE_COST]      
                 , AFF.[COD_PLAN_TAX_AFF]      
                 , AFF.[PERCENTAGE]      
                 , AFF.[RATE]      
                 , IIF(SA.COD_ITEM_SERVICE IS NOT NULL OR [TRANSACTION_TITLES].ANTICIP_PERCENT = 0, 0,      
                       AFF.[ANTICIPATION_PERCENTAGE]) AS                                                                             ANTICIP_PERCENT      
                 , IIF(SA.COD_SERVICE IS NULL, NULL, CAST(JSON_VALUE(SA.CONFIG_JSON,      
                                                                     IIF(@TYPE_TRAN = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))) [PLANDZERO_MDR]      
            INTO #COST      
            FROM [TRANSACTION_TITLES]      
                     JOIN @AFF_DATA AFF      
                          ON AFF.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN      
                     LEFT JOIN SERVICES_AVAILABLE SA      
                               ON SA.COD_AFFILIATOR = AFF.COD_AFFILIATOR      
                                   AND SA.ACTIVE = 1      
                                   AND SA.COD_ITEM_SERVICE = @COD_PLANDZERO_SERVICE      
        AND SA.COD_EC IS NULL      
            WHERE [TRANSACTION_TITLES].COD_TRAN = @COD_TRAN      
      
            INSERT INTO TRANSACTION_TITLES_COST (COD_AFFILIATOR,      
                                                 COD_TITLE,      
                                                 COD_OPER_COST_AFF,      
                                                 OPER_VALUE,      
                                                 [PERCENTAGE],      
                                                 PREVISION_PAY_DATE,      
                                                 COD_SITUATION,      
                                                 RATE_PLAN,      
                                                 ANTICIP_PERCENT,      
                                                 TAX_PLANDZERO)      
            SELECT COD_AFFILIATOR      
                 , COD_TITLE      
                 , [COD_OPER_COST_AFF]      
                 , [PERCENTAGE_COST]      
                 , [PERCENTAGE]      
                 , PREVISION_PAY_DATE      
                 , 4      
                 , [RATE]      
                 , ANTICIP_PERCENT      
                 , PLANDZERO_MDR      
            FROM #COST      
        END;      
      
    IF (SELECT COUNT(*)      
        FROM #EC      
        WHERE COD_T_PLAN = 2      
          AND PLANDZERO_MDR IS NOT NULL)      
        > 0      
        BEGIN      
      
            INSERT INTO TRANSACTION_SERVICES (CREATED_AT, COD_ITEM_SERVICE, COD_TRAN, TAX_PLANDZERO_EC,      
                                              TAX_PLANDZERO_AFF, COD_EC)      
            SELECT DISTINCT current_timestamp      
                          , @COD_PLANDZERO_SERVICE      
                          , @COD_TRAN      
                          , e.PLANDZERO_MDR      
                         , IIF(e.PLANDZERO_MDR = 0 OR e.PLANDZERO_MDR IS NULL, NULL, (SELECT TOP 1 c.PLANDZERO_MDR      
                                                                                       FROM #COST c      
                                                                                       WHERE c.COD_AFFILIATOR = e.AFFILIATOR)      
                )      
                          , e.MERCHANT      
            FROM #EC e      
            WHERE COD_T_PLAN = 2      
              AND e.PLANDZERO_MDR IS NOT NULL      
        END;    
	
		EXEC [SP_VAL_LIMIT_EC] @CODETR = @NSU;

	    UPDATE PROCESS_BG_STATUS      
        SET STATUS_PROCESSED = 0      
        WHERE CODE = @COD_TRAN     

END;    

GO 



SELECT REPORT_TRANSACTIONS_EXP.COD_TRAN 
INTO #TEMP_TRAN
FROM REPORT_TRANSACTIONS_EXP 
JOIN [TRANSACTION_TITLES] WITH(NOLOCK) ON TRANSACTION_TITLES.COD_TRAN = REPORT_TRANSACTIONS_EXP.COD_TRAN
WHERE COD_REP_TRANS_EXP > 6735736
AND NET_VALUE = 0 
GROUP BY REPORT_TRANSACTIONS_EXP.COD_TRAN

    SELECT     
   TRANSACTION_TITLES.COD_EC,  
      [TRANSACTION].COD_TRAN,  
      TRANSACTION_SERVICES.TAX_PLANDZERO_EC    
   INTO #TEMP_DZERO  
     FROM TRANSACTION_SERVICES      
     INNER JOIN ITEMS_SERVICES_AVAILABLE      
      ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE  
  JOIN #TEMP_TRAN   
   ON #TEMP_TRAN.COD_TRAN = TRANSACTION_SERVICES.COD_TRAN  
  JOIN TRANSACTION_TITLES WITH (NOLOCK)  
   ON TRANSACTION_TITLES.COD_TRAN = TRANSACTION_SERVICES.COD_TRAN  
   AND TRANSACTION_TITLES.COD_EC =  TRANSACTION_SERVICES.COD_EC  
  JOIN [TRANSACTION] WITH (NOLOCK)
   ON [TRANSACTION].COD_TRAN = TRANSACTION_SERVICES.COD_TRAN
     WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'      
  GROUP BY    
  TRANSACTION_TITLES.COD_EC,
  [TRANSACTION].COD_TRAN, 
   TRANSACTION_SERVICES.TAX_PLANDZERO_EC  
    
  
  SELECT  
    [TRANSACTION].COD_TRAN,  
      CASE      
   WHEN (  
    #TEMP_DZERO.TAX_PLANDZERO_EC
    )    
    > 0 THEN SUM(dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.TAX_INITIAL, TRANSACTION_TITLES.ANTICIP_PERCENT,   
 (  
  #TEMP_DZERO.TAX_PLANDZERO_EC  
  )      
    , [TRANSACTION].COD_TTYPE))      
   ELSE     
  CASE   
  WHEN [TRANSACTION_TITLES].COD_TRAN IS NOT NULL THEN  
  SUM(dbo.[FNC_ANT_VALUE_LIQ_DAYS](    
  TRANSACTION_TITLES.AMOUNT,    
  TRANSACTION_TITLES.TAX_INITIAL,    
  TRANSACTION_TITLES.PLOT,    
  TRANSACTION_TITLES.ANTICIP_PERCENT,    
  (CASE    
  WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)  
  ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP    
  END)))  
  ELSE 0 END  
 END AS NET_VALUE  
  INTO #TEMP_NET_VALUE  
  FROM [TRANSACTION] WITH (NOLOCK)     
LEFT JOIN [TRANSACTION_TITLES] WITH (NOLOCK)  
 ON [TRANSACTION_TITLES].COD_TRAN = [TRANSACTION].COD_TRAN  
LEFT JOIN #TEMP_DZERO ON #TEMP_DZERO.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
   AND #TEMP_DZERO.COD_EC = TRANSACTION_TITLES.COD_EC
WHERE [TRANSACTION].COD_TRAN IN (SELECT COD_TRAN FROM #TEMP_TRAN)  
GROUP BY  
    TRANSACTION_TITLES.COD_TRAN  
    ,[TRANSACTION].COD_TRAN  
 ,#TEMP_DZERO.TAX_PLANDZERO_EC


GO

CREATE TABLE #DELETE
(
NET_VALUE_EC DECIMAL(22,6),
COD_TRAN INT
)

DECLARE @CONT INT;

SET @CONT = 0;

WHILE @CONT < 5
BEGIN 

INSERT INTO #DELETE
SELECT TOP 1000 NET_VALUE,COD_TRAN FROM #TEMP_NET_VALUE


UPDATE REPORT_TRANSACTIONS_EXP SET NET_VALUE= #DELETE.NET_VALUE_EC
FROM REPORT_TRANSACTIONS_EXP
JOIN #DELETE ON #DELETE.COD_TRAN = REPORT_TRANSACTIONS_EXP.COD_TRAN
WHERE REPORT_TRANSACTIONS_EXP.COD_TRAN IN (SELECT COD_TRAN FROM #DELETE) 

DELETE FROM #TEMP_NET_VALUE WHERE COD_TRAN IN (SELECT COD_TRAN FROM #DELETE)

DELETE FROM #DELETE

SELECT @CONT AS QTY;

SET @CONT = @CONT + 1;

END

DROP TABLE #TEMP_NET_VALUE
DROP TABLE #DELETE
DROP TABLE #TEMP_TRAN
DROP TABLE #TEMP_DZERO

GO
--ST-1612 / ST-1614

GO

--ST-1635

IF OBJECT_ID('SP_REPORT_TRANSACTIONS_PAGE') IS NOT NULL
    DROP PROCEDURE [SP_REPORT_TRANSACTIONS_PAGE];
GO  
CREATE PROCEDURE [dbo].[SP_REPORT_TRANSACTIONS_PAGE]  
/***********************************************************************************************************************************************      
----------------------------------------------------------------------------------------                                                            
Procedure Name: [SP_REPORT_TRANSACTIONS_PAGE]                                                            
Project.......: TKPP                                                            
------------------------------------------------------------------------------------------                                                            
Author                          VERSION        Date                            Description                                                            
------------------------------------------------------------------------------------------                                                            
Fernando                           V1        24/01/2019                          Creation                                                            
Lucas Aguiar                       v2        26-04-2019                      Add split service                       
Elir Ribeiro                       v2        24-06-2019               
Caike Uchôa                        v4        31-08-2020      Add EC_PROD e Arrumar porquisse Total_tran e qtd_tran  
Elir Ribeiro                       v5        24-08-2020    alter lenght terminal to 100 
------------------------------------------------------------------------------------------      
***********************************************************************************************************************************************/ (@CODCOMP VARCHAR(10),  
@INITIAL_DATE DATETIME,  
@FINAL_DATE DATETIME,  
@EC VARCHAR(10),  
@BRANCH VARCHAR(10) = NULL,  
@DEPART VARCHAR(10) = NULL,  
@TERMINAL VARCHAR(100),  
@STATE VARCHAR(100) = NULL,  
@CITY VARCHAR(100) = NULL,  
@TYPE_TRAN INT,  
@SITUATION VARCHAR(10),  
@NSU VARCHAR(100) = NULL,  
@NSU_EXT VARCHAR(100) = NULL,  
@BRAND VARCHAR(50) = NULL,  
@PAN VARCHAR(50) = NULL,  
@CODAFF INT = NULL,  
@TRACKING_TRANSACTION VARCHAR(100) = NULL,  
@DESCRIPTION VARCHAR(100) = NULL,  
@SPOT_ELEGIBLE INT = NULL,  
@COD_ACQ VARCHAR(10) = NULL,  
@SOURCE_TRAN INT = NULL,  
@POSWEB INT = 0,  
@INITIAL_VALUE DECIMAL(22, 6) = NULL,  
@FINAL_VALUE DECIMAL(22, 6) = NULL,  
@QTD_BY_PAGE INT,  
@NEXT_PAGE INT,  
@SPLIT INT = NULL,  
@COD_SALES_REP INT = NULL,  
@COD_EC_PROD INT = NULL,  
@TOTAL_REGS INT OUTPUT,  
@TOTAL_AMOUNT DECIMAL(22, 6) OUTPUT)  
AS  
BEGIN  
  
 DECLARE @QUERY_BASIS_PARAMETERS NVARCHAR(MAX) = '';  
 DECLARE @QUERY_BASIS_SELECT NVARCHAR(MAX) = '';  
 DECLARE @QUERY_BASIS_COUNT NVARCHAR(MAX) = '';  
  
 DECLARE @TIME_FINAL_DATE TIME;  
 DECLARE @CNT INT;  
 DECLARE @TAMOUNT DECIMAL(22, 6);  
 --DECLARE @PARAMS nvarchar(max);              
  
 SET NOCOUNT ON;  
 SET ARITHABORT ON;  
  
 BEGIN  
  
  SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');  
  
  --SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                      
  --SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                 )                        
  
  SET @FINAL_DATE = DATEADD([MILLISECOND], 999, @FINAL_DATE);  
  
  
  IF (@TIME_FINAL_DATE = '00:00:00')  
   SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'));  
  
  
  SET @QUERY_BASIS_SELECT = '                                                      
   SELECT                                                         
    [REPORT_TRANSACTIONS].TRANSACTION_CODE AS TRANSACTION_CODE,                                     
    [REPORT_TRANSACTIONS].AMOUNT,         
    [REPORT_TRANSACTIONS].PLOTS,                                                        
    [REPORT_TRANSACTIONS].TRANSACTION_DATE AS TRANSACTION_DATE,                                                        
    [REPORT_TRANSACTIONS].TRANSACTION_TYPE,                                                        
    [REPORT_TRANSACTIONS].CPF_CNPJ,                                            
    [REPORT_TRANSACTIONS].NAME,                                                        
    [REPORT_TRANSACTIONS].SERIAL_EQUIP,                                                        
    [REPORT_TRANSACTIONS].TID,                                                        
    [REPORT_TRANSACTIONS].SITUATION,                                                        
    [REPORT_TRANSACTIONS].BRAND,                                      
    [REPORT_TRANSACTIONS].NSU_EXT,                                                    
    [REPORT_TRANSACTIONS].PAN,                                              
    [REPORT_TRANSACTIONS].COD_AFFILIATOR,                                  
    [REPORT_TRANSACTIONS].NAME_AFFILIATOR AS NAME_AFFILIATOR ,                                                 
    [REPORT_TRANSACTIONS].TRACKING_TRANSACTION AS COD_RAST,                                          
    [REPORT_TRANSACTIONS].DESCRIPTION AS DESCRIPTION,      
    REPORT_TRANSACTIONS.LINK_PAYMENT_SERVICE,      
    REPORT_TRANSACTIONS.CUSTOMER_EMAIL,      
    REPORT_TRANSACTIONS.CUSTOMER_IDENTIFICATION,      
    REPORT_TRANSACTIONS.PAYMENT_LINK_TRACKING,  
 REPORT_TRANSACTIONS.NAME_PROD,  
 REPORT_TRANSACTIONS.EC_PROD,  
 REPORT_TRANSACTIONS.EC_PROD_CPF_CNPJ  
   FROM [REPORT_TRANSACTIONS]                
   LEFT JOIN TRANSACTION_SERVICES ON TRANSACTION_SERVICES.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN    
          AND [TRANSACTION_SERVICES].COD_ITEM_SERVICE = 4    
   WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                      
      --AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)        
   ';  
  
  
  SET @QUERY_BASIS_COUNT = '                                                      
   SELECT   
   @CNT=COUNT(COD_REPORT_TRANS),  
   @TAMOUNT = SUM([REPORT_TRANSACTIONS].AMOUNT)  
   FROM [REPORT_TRANSACTIONS]                   
   LEFT JOIN TRANSACTION_SERVICES ON TRANSACTION_SERVICES.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN    
    AND [TRANSACTION_SERVICES].COD_ITEM_SERVICE = 4    
      
   WHERE REPORT_TRANSACTIONS.COD_COMP =  @CODCOMP                                                         
      --AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)        
   ';  
  
  
  SET @QUERY_BASIS_PARAMETERS = '';  
  
  IF (@INITIAL_DATE IS NOT NULL  
   AND @FINAL_DATE IS NOT NULL)  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, 'AND CAST([REPORT_TRANSACTIONS].TRANSACTION_DATE AS DATETIME) BETWEEN  CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)');  
  
  IF @EC IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_EC = @EC ');  
  
  IF @BRANCH IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '  AND [REPORT_TRANSACTIONS].COD_BRANCH =  @BRANCH ');  
  
  IF @DEPART IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_DEPTO_BRANCH =  @DEPART ');  
  
  IF LEN(@TERMINAL) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '  AND [REPORT_TRANSACTIONS].SERIAL_EQUIP = @TERMINAL');  
  
  IF LEN(@STATE) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, '  AND [REPORT_TRANSACTIONS].STATE_NAME = @STATE ');  
  
  IF LEN(@CITY) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].CITY_NAME = @CITY ');  
  
  IF @TYPE_TRAN IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND EXISTS( SELECT CODE FROM TRANSACTION_TYPE tt WHERE tt.COD_TTYPE = @TYPE_TRAN AND [REPORT_TRANSACTIONS].TRANSACTION_TYPE = tt.CODE ) ');  
  
  IF @SITUATION IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_SITUATION = @SITUATION ');  
  
  IF LEN(@BRAND) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].BRAND = @BRAND ');  
  
  IF LEN(@NSU) > 0  
  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].TRANSACTION_CODE = @NSU ');  
  
  IF LEN(@NSU_EXT) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].NSU_EXT = @NSU_EXT ');  
  
  IF @PAN IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].PAN = @PAN ');  
  
  IF (@CODAFF IS NOT NULL)  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_AFFILIATOR = @CodAff ');  
  
  IF LEN(@TRACKING_TRANSACTION) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].TRACKING_TRANSACTION  = @TRACKING_TRANSACTION ');  
  
  IF LEN(@DESCRIPTION) > 0  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND  [REPORT_TRANSACTIONS].DESCRIPTION  LIKE  %@DESCRIPTION%');  
  
  IF @SPOT_ELEGIBLE = 1  
  BEGIN  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND  [REPORT_TRANSACTIONS].PLOTS > 1       
    AND EXISTS(SELECT title.COD_TRAN FROM TRANSACTION_TITLES title JOIN [TRANSACTION] title_tran ON title_tran.COD_TRAN = title.COD_TRAN WHERE [REPORT_TRANSACTIONS].COD_TRAN = title_tran.COD_TRA       
    AND title.PREVISION_PAY_DATE > @FINAL_DATE and title.cod_situation = 4 and isnull(title.ANTICIP_PERCENT,0) <= 0  ) ');  
  END;  
  
  IF @COD_ACQ IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_AC = @COD_ACQ');  
  
  IF @SOURCE_TRAN IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_SOURCE_TRAN = @SOURCE_TRAN');  
  
  IF @POSWEB = 1  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].POSWEB = @POSWEB');  
  
  IF (@INITIAL_VALUE > 0)  
   AND (@FINAL_VALUE >= @INITIAL_VALUE)  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].AMOUNT BETWEEN @INITIAL_VALUE AND @FINAL_VALUE');  
  
  IF @SPLIT = 1  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, 'AND TRANSACTION_SERVICES.COD_ITEM_SERVICE = 4');  
  
  IF @COD_SALES_REP IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_SALE_REP = @COD_SALES_REP ');  
  
  IF @COD_EC_PROD IS NOT NULL  
   SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' AND [REPORT_TRANSACTIONS].COD_EC_PROD = @COD_EC_PROD ');  
  
  
  SET @QUERY_BASIS_COUNT = CONCAT(@QUERY_BASIS_COUNT, @QUERY_BASIS_PARAMETERS);  
  
  
  
  EXEC [sp_executesql] @QUERY_BASIS_COUNT  
       ,N'                                                                
   @CODCOMP VARCHAR(10),                                          
   @INITIAL_DATE DATETIME,                                                                
   @FINAL_DATE DATETIME,                                         
   @EC int,                                                                
   @BRANCH int,                                                                
   @DEPART int,                                                                 
   @TERMINAL varchar(100),                                                                
   @STATE varchar(25),                                                                
   @CITY varchar(40),                                                             
   @TYPE_TRAN int,                                                                
   @SITUATION int,                                                       
   @NSU varchar(100),                                                                
   @NSU_EXT varchar(100),                                                                
   @BRAND varchar(50) ,                                                              
   @PAN VARCHAR(50),         
   @CodAff INT,                                          
   @TRACKING_TRANSACTION  VARCHAR(100),                                                  
   @DESCRIPTION  VARCHAR(100),                                      
   @COD_ACQ  VARCHAR(10),                                      
   @SOURCE_TRAN VARCHAR(12),                                      
   @POSWEB int,                                        
   @INITIAL_VALUE DECIMAL(22,6),                                          
   @FINAL_VALUE DECIMAL(22,6),              
   @CNT INT OUTPUT,      
   @TAMOUNT DECIMAL(22,6) OUTPUT,   
   @COD_SALES_REP INT,   
   @COD_EC_PROD INT  
   '  
       ,@CODCOMP = @CODCOMP  
       ,@INITIAL_DATE = @INITIAL_DATE  
       ,@FINAL_DATE = @FINAL_DATE  
       ,@EC = @EC  
       ,@BRANCH = @BRANCH  
       ,@DEPART = @DEPART  
       ,@TERMINAL = @TERMINAL  
       ,@STATE = @STATE  
       ,@CITY = @CITY  
       ,@TYPE_TRAN = @TYPE_TRAN  
       ,@SITUATION = @SITUATION  
       ,@NSU = @NSU  
       ,@NSU_EXT = @NSU_EXT  
       ,@BRAND = @BRAND  
       ,@PAN = @PAN  
       ,@CODAFF = @CODAFF  
       ,@TRACKING_TRANSACTION = @TRACKING_TRANSACTION  
       ,@DESCRIPTION = @DESCRIPTION  
       ,@COD_ACQ = @COD_ACQ  
       ,@SOURCE_TRAN = @SOURCE_TRAN  
       ,@POSWEB = @POSWEB  
       ,@INITIAL_VALUE = @INITIAL_VALUE  
       ,@FINAL_VALUE = @FINAL_VALUE  
       ,@CNT = @CNT OUTPUT  
       ,@TAMOUNT = @TAMOUNT OUTPUT  
       ,@COD_SALES_REP = @COD_SALES_REP  
       ,@COD_EC_PROD = @COD_EC_PROD;  
  
  SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' ORDER BY [REPORT_TRANSACTIONS].TRANSACTION_DATE DESC ');  
  SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' OFFSET (@NEXT_PAGE - 1) * @QTD_BY_PAGE ROWS');  
  SET @QUERY_BASIS_PARAMETERS = CONCAT(@QUERY_BASIS_PARAMETERS, ' FETCH NEXT @QTD_BY_PAGE ROWS ONLY');  
  
  SET @TOTAL_AMOUNT = @TAMOUNT;  
  SET @TOTAL_REGS = @CNT;  
  SET @QUERY_BASIS_SELECT = CONCAT(@QUERY_BASIS_SELECT, @QUERY_BASIS_PARAMETERS);  
  
  
  EXEC [sp_executesql] @QUERY_BASIS_SELECT  
       ,N'                                                                
   @CODCOMP VARCHAR(10),                                  
   @INITIAL_DATE DATETIME,                                                                
   @FINAL_DATE DATETIME,                                         
   @EC int,                                                                
   @BRANCH int,                                                                
   @DEPART int,                                                                 
   @TERMINAL varchar(100),                                                                
   @STATE varchar(25),                                                                
   @CITY varchar(40),                                                             
   @TYPE_TRAN int,                                                                
   @SITUATION int,                                                       
   @NSU varchar(100),                                                                
   @NSU_EXT varchar(100),                                                                
   @BRAND varchar(50) ,                                                              
   @PAN VARCHAR(50),                                                        
   @CodAff INT,                                          
   @TRACKING_TRANSACTION  VARCHAR(100),                                                  
   @DESCRIPTION  VARCHAR(100),                                      
   @COD_ACQ  VARCHAR(10),                                      
   @SOURCE_TRAN VARCHAR(12),                                      
   @POSWEB int,                                        
   @INITIAL_VALUE DECIMAL(22,6),                                                                
   @FINAL_VALUE DECIMAL(22,6),              
   @QTD_BY_PAGE INT,               
   @NEXT_PAGE INT,            
   @COD_SALES_REP INT,  
   @COD_EC_PROD INT  
   '  
       ,@CODCOMP = @CODCOMP  
       ,@INITIAL_DATE = @INITIAL_DATE  
       ,@FINAL_DATE = @FINAL_DATE  
       ,@EC = @EC  
       ,@BRANCH = @BRANCH  
       ,@DEPART = @DEPART  
       ,@TERMINAL = @TERMINAL  
       ,@STATE = @STATE  
       ,@CITY = @CITY  
       ,@TYPE_TRAN = @TYPE_TRAN  
       ,@SITUATION = @SITUATION  
       ,@NSU = @NSU  
       ,@NSU_EXT = @NSU_EXT  
       ,@BRAND = @BRAND  
       ,@PAN = @PAN  
       ,@CODAFF = @CODAFF  
       ,@TRACKING_TRANSACTION = @TRACKING_TRANSACTION  
       ,@DESCRIPTION = @DESCRIPTION  
       ,@COD_ACQ = @COD_ACQ  
       ,@SOURCE_TRAN = @SOURCE_TRAN  
       ,@POSWEB = @POSWEB  
       ,@INITIAL_VALUE = @INITIAL_VALUE  
       ,@FINAL_VALUE = @FINAL_VALUE  
       ,@QTD_BY_PAGE = @QTD_BY_PAGE  
       ,@NEXT_PAGE = @NEXT_PAGE  
       ,@COD_SALES_REP = @COD_SALES_REP  
       ,@COD_EC_PROD = @COD_EC_PROD;  
  
 END;  
END;

GO

IF OBJECT_ID('SP_REPORT_TRANSACTIONS_EXP') IS NOT NULL
    DROP PROCEDURE [SP_REPORT_TRANSACTIONS_EXP];
GO  
CREATE PROCEDURE [dbo].[SP_REPORT_TRANSACTIONS_EXP]  
/***************************************************************************************                
----------------------------------------------------------------------------------------                
Procedure Name: [SP_REPORT_TRANSACTIONS_EXP]                
Project.......: TKPP                
------------------------------------------------------------------------------------------                
Author               VERSION         Date                     Description                
------------------------------------------------------------------------------------------                
Fernando Henrique F.   V1         13/12/2018               Creation                
Kennedy Alef           V2         16/01/2018               Modify                
Lucas Aguiar           V2         23/04/2019               ROTINA DE SPLIT                
Caike Uch�a            V3         15/08/2019               inserting coluns                
Marcus Gall            V4         28/11/2019               Add Model_POS, Segment, Location EC                
Caike Uch�a            V5         20/01/2020               ADD CNAE                
Kennedy Alef           v3         08/04/2020               add link de pagamento                
Caike Uch�a            v4         30/04/2020               insert ec prod                
Caike Uch�a            v5         17/08/2020               Add SALES_TYPE              
Luiz Aquino            v6         01/07/2020                 add PlanDzero    
Caike Uchoa            v7         31/08/2020               Add cod_ec_prod    
 Caike Uchoa           v12        28/09/2020               Add branch business  
Elir Ribeiro           v13        24/11/2020              terminal length to 100
---------------------------------------------           ---------------------------------------------                
********************************************************************************************/ (@CODCOMP VARCHAR(10),  
@INITIAL_DATE DATETIME,  
@FINAL_DATE DATETIME,  
@EC VARCHAR(10),  
@BRANCH VARCHAR(10),  
@DEPART VARCHAR(10),  
@TERMINAL VARCHAR(100),  
@STATE VARCHAR(100),  
@CITY VARCHAR(100),  
@TYPE_TRAN VARCHAR(10),  
@SITUATION VARCHAR(10),  
@NSU VARCHAR(100) = NULL,  
@NSU_EXT VARCHAR(100) = NULL,  
@BRAND VARCHAR(50) = NULL,  
@PAN VARCHAR(50) = NULL,  
@COD_AFFILIATOR INT = NULL,  
@TRACKING_TRANSACTION VARCHAR(100) = NULL,  
@DESCRIPTION VARCHAR(100) = NULL,  
@SPOT_ELEGIBLE INT = 0,  
@COD_ACQ INT = NULL,  
@SOURCE_TRAN INT = NULL,  
@POSWEB INT = 0,  
@SPLIT INT = NULL,  
@INITIAL_VALUE DECIMAL(22, 6) = NULL,  
@FINAL_VALUE DECIMAL(22, 6) = NULL,  
@COD_SALES_REP INT = NULL,  
@COD_EC_PROD INT = NULL)  
AS  
BEGIN  
 DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';  
 DECLARE @TIME_FINAL_DATE TIME;  
 SET NOCOUNT ON;  
 SET ARITHABORT ON;  
 BEGIN  
  SET @TIME_FINAL_DATE = FORMAT(CAST(@FINAL_DATE AS TIME), N'hh\:mm\:ss');  
  --SET @INITIAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0));                
  --SET @FINAL_DATE = CAST(@INITIAL_DATE AS DATETIME2(0)); )                
  SET @FINAL_DATE = DATEADD([MILLISECOND], 999, @FINAL_DATE);  
  IF (@TIME_FINAL_DATE = '00:00:00')  
   SET @FINAL_DATE = CONCAT(CAST(@FINAL_DATE AS DATE), ' ', FORMAT(CAST('23:59:59' AS TIME), N'hh\:mm\:ss'));  
  SET @QUERY_BASIS = '                
   SELECT [REPORT_TRANSACTIONS_EXP].TRANSACTION_CODE                
      ,[REPORT_TRANSACTIONS_EXP].AMOUNT                
      ,[REPORT_TRANSACTIONS_EXP].PLOTS                
      ,[REPORT_TRANSACTIONS_EXP].TRANSACTION_DATE                
      ,[REPORT_TRANSACTIONS_EXP].TRANSACTION_TYPE                
      ,[REPORT_TRANSACTIONS_EXP].CPF_CNPJ                
      ,[REPORT_TRANSACTIONS_EXP].NAME                
      ,[REPORT_TRANSACTIONS_EXP].SERIAL_EQUIP                
      ,[REPORT_TRANSACTIONS_EXP].TID                
      ,[REPORT_TRANSACTIONS_EXP].SITUATION                
      ,[REPORT_TRANSACTIONS_EXP].BRAND                
      ,[REPORT_TRANSACTIONS_EXP].PAN                
      ,COALESCE([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT_VALUE, '''') AS TRAN_DATA_EXT_VALUE                
      ,COALESCE([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT, '''') AS TRAN_DATA_EXT                
   ,(      
      SELECT TRANSACTION_DATA_EXT.[VALUE] FROM TRANSACTION_DATA_EXT                
   WHERE TRANSACTION_DATA_EXT.[NAME]= ''AUTHCODE'' AND TRANSACTION_DATA_EXT.COD_TRAN = REPORT_TRANSACTIONS_EXP.COD_TRAN                
      ) AS [AUTH_CODE]                
      ,[REPORT_TRANSACTIONS_EXP].COD_AC                
      ,[REPORT_TRANSACTIONS_EXP].NAME_ACQUIRER                
      ,[REPORT_TRANSACTIONS_EXP].COMMENT                
  ,[REPORT_TRANSACTIONS_EXP].TAX                
      ,[REPORT_TRANSACTIONS_EXP].ANTICIPATION                
      ,[REPORT_TRANSACTIONS_EXP].COD_AFFILIATOR                
      ,[REPORT_TRANSACTIONS_EXP].NAME_AFFILIATOR                
      ,[REPORT_TRANSACTIONS_EXP].NET_VALUE                
      ,[REPORT_TRANSACTIONS_EXP].GROSS_VALUE_AGENCY                
      ,[REPORT_TRANSACTIONS_EXP].NET_VALUE_AGENCY                
      ,[REPORT_TRANSACTIONS_EXP].TYPE_TRAN                
      ,[REPORT_TRANSACTIONS_EXP].POSWEB                
      ,[REPORT_TRANSACTIONS_EXP].CITY_NAME                
      ,[REPORT_TRANSACTIONS_EXP].STATE_NAME                
      ,[REPORT_TRANSACTIONS_EXP].SEGMENTS_NAME                
      ,[REPORT_TRANSACTIONS_EXP].COD_EC_TRANS                
      ,[REPORT_TRANSACTIONS_EXP].TRANS_EC_NAME                
      ,[REPORT_TRANSACTIONS_EXP].TRANS_EC_CPF_CNPJ                
      ,[REPORT_TRANSACTIONS_EXP].SPLIT                
      ,[REPORT_TRANSACTIONS_EXP].[SALES_REP]                
      ,[REPORT_TRANSACTIONS_EXP].CREDITOR_DOCUMENT                
      ,REPORT_TRANSACTIONS_EXP.COD_SALES_REP                
      ,[REPORT_TRANSACTIONS_EXP].MODEL_POS                
      ,[REPORT_TRANSACTIONS_EXP].CARD_NAME                
      ,[REPORT_TRANSACTIONS_EXP].CNAE                
      ,[REPORT_TRANSACTIONS_EXP].LINK_PAYMENT_SERVICE                
      ,[REPORT_TRANSACTIONS_EXP].CUSTOMER_EMAIL                
      ,[REPORT_TRANSACTIONS_EXP].CUSTOMER_IDENTIFICATION                
      ,[REPORT_TRANSACTIONS_EXP].PAYMENT_LINK_TRACKING                
      ,[REPORT_TRANSACTIONS_EXP].[NAME_PRODUCT_EC]                
      ,[REPORT_TRANSACTIONS_EXP].[EC_PRODUCT]                
      ,[REPORT_TRANSACTIONS_EXP].[EC_PRODUCT_CPF_CNPJ]                
   ,[REPORT_TRANSACTIONS_EXP].[SALES_TYPE]              
   ,ISNULL([REPORT_TRANSACTIONS_EXP].DZERO_EC_TAX, 0) AS DZERO_EC_TAX      
   ,ISNULL([REPORT_TRANSACTIONS_EXP].DZERO_AFF_TAX, 0)       AS DZERO_AFF_TAX    
   ,[REPORT_TRANSACTIONS_EXP].[COD_EC_PROD]    
   ,[REPORT_TRANSACTIONS_EXP].[BRANCH_BUSINESS]  
   FROM [dbo].[REPORT_TRANSACTIONS_EXP]                
   WHERE [REPORT_TRANSACTIONS_EXP].COD_COMP = @CODCOMP                
    ';  
  IF @INITIAL_DATE IS NOT NULL  
   AND @FINAL_DATE IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND CAST([REPORT_TRANSACTIONS_EXP].TRANSACTION_DATE AS DATETIME) BETWEEN CAST(@INITIAL_DATE AS DATETIME) AND CAST(@FINAL_DATE AS DATETIME)');  
  IF @EC IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_EC = @EC ');  
  IF @BRANCH IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND[REPORT_TRANSACTIONS_EXP].COD_BRANCH = @BRANCH ');  
  IF @DEPART IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_DEPTO_BRANCH = @DEPART ');  
  IF LEN(@TERMINAL) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].SERIAL_EQUIP = @TERMINAL');  
  IF LEN(@STATE) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].STATE_NAME = @STATE ');  
  IF LEN(@CITY) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].CITY_NAME = @CITY ');  
  IF LEN(@TYPE_TRAN) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND EXISTS( SELECT tt.CODE FROM TRANSACTION_TYPE tt WHERE tt.COD_TTYPE = @TYPE_TRAN AND [REPORT_TRANSACTIONS_EXP].TRANSACTION_TYPE = tt.CODE )');  
  IF LEN(@SITUATION) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND EXISTS( SELECT tt.SITUATION_TR FROM [TRADUCTION_SITUATION] tt WHERE tt.COD_SITUATION = @SITUATION AND [REPORT_TRANSACTIONS_EXP].SITUATION = tt.SITUATION_TR )');  
  IF LEN(@BRAND) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].BRAND = @BRAND ');  
  IF LEN(@PAN) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].PAN = @PAN ');  
  IF LEN(@NSU) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRANSACTION_CODE = @NSU ');  
  IF LEN(@NSU_EXT) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT_VALUE = @NSU_EXT ');  
  --ELSE                
  -- SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,' AND ([REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''RCPTTXID'' OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT IS NULL                
  -- OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''AUTO'' OR [REPORT_TRANSACTIONS_EXP].TRAN_DATA_EXT = ''NSU'' ) ');                
  IF @COD_AFFILIATOR IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_AFFILIATOR = @COD_AFFILIATOR ');  
  IF LEN(@TRACKING_TRANSACTION) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].TRACKING_TRANSACTION = @TRACKING_TRANSACTION ');  
  IF LEN(@DESCRIPTION) > 0  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].DESCRIPTION LIKE %@DESCRIPTION%');  
  IF @SPOT_ELEGIBLE = 1  
  BEGIN  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].PLOTS > 1 AND (SELECT COUNT(*) FROM TRANSACTION_TITLES title JOIN [TRANSACTION] title_tran ON title_tran.COD_TRAN = title.COD_TRAN WHERE [VW_REPORT_TRANSACTIONS].TRANSACTION_CODE  
 
     
      
        
          
            
              
        = title_tran.CODE AND title.PREVISION_PAY_DATE > @FINAL_DATE ) > 0 AND TRANSACTION_TITLES.COD_SITUATION = 4 ');  
  END;  
  IF @COD_ACQ IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_AC = @COD_ACQ');  
  IF @SOURCE_TRAN IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_SOURCE_TRAN = @SOURCE_TRAN');  
  IF @POSWEB = 1  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].POSWEB = @POSWEB');  
  IF (@INITIAL_VALUE > 0)  
   AND (@FINAL_VALUE >= @INITIAL_VALUE)  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].AMOUNT BETWEEN @INITIAL_VALUE AND @FINAL_VALUE');  
  IF (@SPLIT = 1)  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND [REPORT_TRANSACTIONS_EXP].SPLIT = 1');  
  IF @COD_SALES_REP IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_SALES_REP = @COD_SALES_REP');  
  
  IF @COD_EC_PROD IS NOT NULL  
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND [REPORT_TRANSACTIONS_EXP].COD_EC_PROD = @COD_EC_PROD');  
  
  SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY [REPORT_TRANSACTIONS_EXP].CREATED_AT DESC');  
  --SELECT @QUERY_BASIS                
  EXEC [sp_executesql] @QUERY_BASIS  
       ,N'                
   @CODCOMP VARCHAR(10),                
   @INITIAL_DATE DATETIME,                
   @FINAL_DATE DATETIME,                
   @EC int,                
   @BRANCH int,                
   @DEPART int,                
   @TERMINAL varchar(100),                
   @STATE varchar(25),                
   @CITY varchar(40),                
   @TYPE_TRAN VARCHAR(10),                
   @SITUATION VARCHAR(10),                
   @NSU varchar(100),                
   @NSU_EXT varchar(100),                
   @BRAND varchar(50),                
   @COD_AFFILIATOR INT,                
   @PAN VARCHAR(50),                
   @SOURCE_TRAN INT,                
   @POSWEB INT,                
   @INITIAL_VALUE DECIMAL(22,6),                
   @FINAL_VALUE DECIMAL(22,6),                
   @COD_SALES_REP INT,                
   @COD_ACQ INT,    
   @COD_EC_PROD INT    
   '  
       ,@CODCOMP = @CODCOMP  
       ,@INITIAL_DATE = @INITIAL_DATE  
       ,@FINAL_DATE = @FINAL_DATE  
       ,@EC = @EC  
       ,@BRANCH = @BRANCH  
       ,@DEPART = @DEPART  
       ,@TERMINAL = @TERMINAL  
       ,@STATE = @STATE  
       ,@CITY = @CITY  
       ,@TYPE_TRAN = @TYPE_TRAN  
       ,@SITUATION = @SITUATION  
       ,@NSU = @NSU  
       ,@NSU_EXT = @NSU_EXT  
       ,@BRAND = @BRAND  
       ,@PAN = @PAN  
       ,@COD_AFFILIATOR = @COD_AFFILIATOR  
       ,@SOURCE_TRAN = @SOURCE_TRAN  
       ,@POSWEB = @POSWEB  
       ,@INITIAL_VALUE = @INITIAL_VALUE  
       ,@FINAL_VALUE = @FINAL_VALUE  
       ,@COD_SALES_REP = @COD_SALES_REP  
       ,@COD_ACQ = @COD_ACQ  
       ,@COD_EC_PROD = @COD_EC_PROD;  
 END;  
END;

--ST-1635

GO

--ST-1655
IF OBJECT_ID('SP_GW_LS_DETAILS_PLAN') IS NOT NULL DROP PROCEDURE SP_GW_LS_DETAILS_PLAN
GO
CREATE PROCEDURE [dbo].[SP_GW_LS_DETAILS_PLAN]         
/*----------------------------------------------------------------------------------------        
Procedure Name: [SP_GW_LS_DETAILS_PLAN]      Project.......: TKPP        
    
Description: Same as SP_GW_LS_DETAILS_PLAN, but bundling online and face-to-face fees together    
    
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Marcus Gall                       V1         17/06/2020                          Creation        
------------------------------------------------------------------------------------------*/       
(    
 @COD_PLAN INT,    
 @COD_AFFILIATOR INT    
)    
AS    
BEGIN
    
 DECLARE @COD_AFF_PLAN INT;

SELECT
	@COD_AFF_PLAN = COD_AFFILIATOR
FROM [PLAN]
WHERE COD_PLAN = @COD_PLAN
AND ACTIVE = 1;

IF (@COD_AFF_PLAN <> @COD_AFFILIATOR)
THROW 61064, 'INVALID PLAN FOR THIS AFFILIATOR OR PLAN IS INACTIVE', 1;



SELECT
	PLANS.COD_PLAN
   ,PLANS.[NAME_PLAN]
   ,PLANS.[DESCRIPTION]
   ,PLANS.CATEGORY
   ,PLANS.TYPE_PLAN
   ,PLANS.BRAND_GROUP
   ,PLANS.TRANSACTION_TYPE
   ,PLANS.QTY_INI_PLOTS
   ,PLANS.QTY_FINAL_PLOTS
   ,SUM(PLANS.ANTICIPATION_PERCENTAGE) AS ANTICIPATION_PERCENTAGE
   ,SUM(INTERVAL_DEBIT) AS INTERVAL_DEBIT
   ,SUM(INTERVAL_CREDIT_A_VISTA) AS INTERVAL_CREDIT_A_VISTA
   ,SUM(INTERVAL_CREDIT_PARCELADO) AS INTERVAL_CREDIT_PARCELADO
   ,SUM(INTERVAL_ONLINE) AS INTERVAL_ONLINE
   ,SUM(PLANS.PARCENTAGE) AS PARCENTAGE
   ,SUM(PLANS.RATE) AS RATE
   ,PLANS.PLAN_OPTION AS PLAN_OPTION
   ,PLANS.EQUIPMENT_MODEL
FROM (SELECT
		[PLAN].COD_PLAN
	   ,[PLAN].CODE AS [NAME_PLAN]
	   ,[PLAN].[DESCRIPTION]
	   ,PLAN_CATEGORY.CATEGORY
	   ,TYPE_PLAN.CODE AS TYPE_PLAN
	   ,BRAND.[GROUP] AS BRAND_GROUP
	   ,TRANSACTION_TYPE.CODE AS TRANSACTION_TYPE
	   ,TAX_PLAN.QTY_INI_PLOTS
	   ,TAX_PLAN.QTY_FINAL_PLOTS
	   ,CASE
			WHEN (SOURCE_TRANSACTION.COD_SOURCE_TRAN = 1) THEN 'SITE'
			ELSE EQUIPMENT_MODEL.CODIGO
		END AS EQUIPMENT_MODEL
	   ,TAX_PLAN.ANTICIPATION_PERCENTAGE
	   ,CASE

			WHEN TAX_PLAN.QTY_INI_PLOTS = 1 AND
				TAX_PLAN.QTY_FINAL_PLOTS = 1 AND
				TAX_PLAN.COD_TTYPE = 2 AND
				SOURCE_TRANSACTION.COD_SOURCE_TRAN = 2 THEN TAX_PLAN.INTERVAL

			ELSE 0
		END AS [INTERVAL_DEBIT]
	   ,CASE
			WHEN TAX_PLAN.QTY_INI_PLOTS = 1 AND
				TAX_PLAN.QTY_FINAL_PLOTS = 1 AND
				TAX_PLAN.COD_TTYPE = 1 AND

				SOURCE_TRANSACTION.COD_SOURCE_TRAN = 2 THEN TAX_PLAN.INTERVAL
			ELSE 0
		END AS [INTERVAL_CREDIT_A_VISTA]
	   ,CASE
			WHEN TAX_PLAN.QTY_INI_PLOTS >= 1 AND
				TAX_PLAN.QTY_FINAL_PLOTS > 1 AND
				TAX_PLAN.COD_TTYPE = 1 AND
				SOURCE_TRANSACTION.COD_SOURCE_TRAN = 2 THEN TAX_PLAN.INTERVAL
			ELSE 0
		END AS [INTERVAL_CREDIT_PARCELADO]
	   ,CASE

			WHEN SOURCE_TRANSACTION.COD_SOURCE_TRAN = 1 THEN TAX_PLAN.INTERVAL
			ELSE 0
		END AS [INTERVAL_ONLINE]
	   ,PARCENTAGE
	   ,RATE
	   ,CASE
			WHEN TAX_PLAN.COD_MODEL IS NOT NULL THEN 'TERMINAL_PLAN'
			ELSE NULL
		END AS PLAN_OPTION
	FROM [PLAN]
	JOIN TAX_PLAN
		ON TAX_PLAN.COD_PLAN = [PLAN].COD_PLAN
	JOIN PLAN_CATEGORY
		ON PLAN_CATEGORY.COD_PLAN_CATEGORY = [PLAN].COD_PLAN_CATEGORY

	JOIN TYPE_PLAN
		ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN
	JOIN TRANSACTION_TYPE
		ON TRANSACTION_TYPE.COD_TTYPE = TAX_PLAN.COD_TTYPE
	JOIN BRAND
		ON BRAND.COD_BRAND = TAX_PLAN.COD_BRAND

	JOIN SOURCE_TRANSACTION
		ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = TAX_PLAN.COD_SOURCE_TRAN
	JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = [PLAN].COD_AFFILIATOR
	LEFT JOIN EQUIPMENT_MODEL
		ON EQUIPMENT_MODEL.COD_MODEL = TAX_PLAN.COD_MODEL
	--LEFT JOIN PLAN_OPTION
	--    ON PLAN_OPTION.COD_PLAN_OPT = [PLAN].COD_PLAN_OPT
	WHERE TAX_PLAN.ACTIVE = 1) AS PLANS
WHERE PLANS.COD_PLAN = @COD_PLAN
GROUP BY PLANS.COD_PLAN
		,PLANS.[NAME_PLAN]
		,PLANS.[DESCRIPTION]
		,PLANS.CATEGORY
		,PLANS.TYPE_PLAN
		,PLANS.BRAND_GROUP
		,PLANS.TRANSACTION_TYPE
		,PLANS.QTY_INI_PLOTS
		,PLANS.QTY_FINAL_PLOTS
		,PLANS.PLAN_OPTION
		,PLANS.EQUIPMENT_MODEL
END

GO

GO
 

IF OBJECT_ID('SP_GW_LS_DETAILS_PLAN_ESTABLISHMENT') IS NOT NULL
DROP PROCEDURE [SP_GW_LS_DETAILS_PLAN_ESTABLISHMENT];

GO
CREATE PROCEDURE [dbo].[SP_GW_LS_DETAILS_PLAN_ESTABLISHMENT]
/*----------------------------------------------------------------------------------------          
Procedure Name: [SP_GW_LS_DETAILS_PLAN_ESTABLISHMENT]    Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author                          VERSION        Date                            Description          
------------------------------------------------------------------------------------------          
Marcus Gall                       V1         19/06/2020                          Creation        
Caike uchoa                       v2         25/11/2020                        add corre??o cod_opt_plan
------------------------------------------------------------------------------------------*/ (@COD_EC INT,
@COD_AFFILIATOR INT)
AS
BEGIN

 



    IF ( SELECT
		COUNT(*)
	FROM [PLAN]
	JOIN ASS_TAX_DEPART
		ON ASS_TAX_DEPART.COD_PLAN = [PLAN].COD_PLAN
	JOIN PLAN_CATEGORY
		ON PLAN_CATEGORY.COD_PLAN_CATEGORY = [PLAN].COD_PLAN_CATEGORY
	JOIN TYPE_PLAN
		ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN
	JOIN TRANSACTION_TYPE
		ON TRANSACTION_TYPE.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE
	JOIN BRAND
		ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
	JOIN SOURCE_TRANSACTION
		ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = ASS_TAX_DEPART.COD_SOURCE_TRAN
	JOIN DEPARTMENTS_BRANCH
		ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH
	JOIN BRANCH_EC
		ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
	JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC
	AND ASS_TAX_DEPART.ACTIVE = 1)
= 0
THROW 61067, 'THIS ESTABLISHMENT DOES NOT HAVE AN ASSOCIATED PLAN', 1;




SELECT
	PLANS.COD_PLAN
   ,PLANS.[NAME_PLAN]
   ,PLANS.[DESCRIPTION]
   ,PLANS.CATEGORY
   ,PLANS.TYPE_PLAN
   ,PLANS.BRAND_GROUP
   ,PLANS.TRANSACTION_TYPE
   ,PLANS.QTY_INI_PLOTS
   ,PLANS.QTY_FINAL_PLOTS
   ,SUM(PLANS.ANTICIPATION_PERCENTAGE) AS ANTICIPATION_PERCENTAGE
   ,SUM(INTERVAL_DEBIT) AS INTERVAL_DEBIT
   ,SUM(INTERVAL_CREDIT_A_VISTA) AS INTERVAL_CREDIT_A_VISTA
   ,SUM(INTERVAL_CREDIT_PARCELADO) AS INTERVAL_CREDIT_PARCELADO
   ,SUM(INTERVAL_ONLINE) AS INTERVAL_ONLINE
   ,SUM(PLANS.PARCENTAGE) AS PARCENTAGE
   ,SUM(PLANS.RATE) AS RATE
   ,PLANS.PLAN_OPTION AS PLAN_OPTION
   ,PLANS.EQUIPMENT_MODEL
FROM (SELECT
		COMMERCIAL_ESTABLISHMENT.COD_EC
	   ,[PLAN].COD_PLAN
	   ,[PLAN].CODE AS [NAME_PLAN]
	   ,[PLAN].[DESCRIPTION]
	   ,PLAN_CATEGORY.CATEGORY
	   ,TYPE_PLAN.CODE AS TYPE_PLAN
	   ,BRAND.[GROUP] AS BRAND_GROUP
	   ,TRANSACTION_TYPE.CODE AS TRANSACTION_TYPE
	   ,ASS_TAX_DEPART.QTY_INI_PLOTS
	   ,ASS_TAX_DEPART.QTY_FINAL_PLOTS
	   ,CASE
			WHEN (SOURCE_TRANSACTION.COD_SOURCE_TRAN = 1) THEN 'SITE'
			ELSE EQUIPMENT_MODEL.CODIGO
		END AS EQUIPMENT_MODEL
	   ,ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE
	   ,CASE
			WHEN ASS_TAX_DEPART.QTY_INI_PLOTS = 1 AND
				ASS_TAX_DEPART.QTY_FINAL_PLOTS = 1 AND
				ASS_TAX_DEPART.COD_TTYPE = 2 AND
				SOURCE_TRANSACTION.COD_SOURCE_TRAN = 2 THEN ASS_TAX_DEPART.INTERVAL
			ELSE 0
		END AS [INTERVAL_DEBIT]
	   ,CASE
			WHEN ASS_TAX_DEPART.QTY_INI_PLOTS = 1 AND
				ASS_TAX_DEPART.QTY_FINAL_PLOTS = 1 AND
				ASS_TAX_DEPART.COD_TTYPE = 1 AND
				SOURCE_TRANSACTION.COD_SOURCE_TRAN = 2 THEN ASS_TAX_DEPART.INTERVAL
			ELSE 0
		END AS [INTERVAL_CREDIT_A_VISTA]
	   ,CASE
			WHEN ASS_TAX_DEPART.QTY_INI_PLOTS >= 1 AND
				ASS_TAX_DEPART.QTY_FINAL_PLOTS > 1 AND
				ASS_TAX_DEPART.COD_TTYPE = 1 AND
				SOURCE_TRANSACTION.COD_SOURCE_TRAN = 2 THEN ASS_TAX_DEPART.INTERVAL
			ELSE 0
		END AS [INTERVAL_CREDIT_PARCELADO]
	   ,CASE
			WHEN SOURCE_TRANSACTION.COD_SOURCE_TRAN = 1 THEN ASS_TAX_DEPART.INTERVAL
			ELSE 0
		END AS [INTERVAL_ONLINE]
	   ,PARCENTAGE
	   ,RATE
	   ,CASE
			WHEN ASS_TAX_DEPART.COD_MODEL IS NOT NULL THEN 'TERMINAL_PLAN'
			ELSE NULL
		END AS PLAN_OPTION
	FROM [PLAN]
	JOIN ASS_TAX_DEPART
		ON ASS_TAX_DEPART.COD_PLAN = [PLAN].COD_PLAN
	JOIN PLAN_CATEGORY
		ON PLAN_CATEGORY.COD_PLAN_CATEGORY = [PLAN].COD_PLAN_CATEGORY
	JOIN TYPE_PLAN
		ON TYPE_PLAN.COD_T_PLAN = [PLAN].COD_T_PLAN
	JOIN TRANSACTION_TYPE
		ON TRANSACTION_TYPE.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE
	JOIN BRAND
		ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
	JOIN SOURCE_TRANSACTION
		ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = ASS_TAX_DEPART.COD_SOURCE_TRAN
	JOIN DEPARTMENTS_BRANCH
		ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH
	JOIN BRANCH_EC
		ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
	JOIN COMMERCIAL_ESTABLISHMENT
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
	JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	LEFT JOIN EQUIPMENT_MODEL
		ON EQUIPMENT_MODEL.COD_MODEL = ASS_TAX_DEPART.COD_MODEL
	--LEFT JOIN PLAN_OPTION
	--    ON PLAN_OPTION.COD_PLAN_OPT = [PLAN].COD_PLAN_OPT
	WHERE ASS_TAX_DEPART.ACTIVE = 1) AS PLANS
WHERE PLANS.COD_EC = @COD_EC
GROUP BY PLANS.COD_PLAN
		,PLANS.[NAME_PLAN]
		,PLANS.[DESCRIPTION]
		,PLANS.CATEGORY
		,PLANS.TYPE_PLAN
		,PLANS.BRAND_GROUP
		,PLANS.TRANSACTION_TYPE
		,PLANS.QTY_INI_PLOTS
		,PLANS.QTY_FINAL_PLOTS
		,PLANS.PLAN_OPTION
		,PLANS.EQUIPMENT_MODEL
END
--ST-1655
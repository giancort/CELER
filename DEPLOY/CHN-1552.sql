--ET-1347


IF OBJECT_ID('SP_FD_PARTNER_B2E') IS NOT NULL DROP PROCEDURE SP_FD_PARTNER_B2E;
GO
CREATE PROCEDURE SP_FD_PARTNER_B2E(
    @COD_EC INT
)
AS
BEGIN
    select COD_EC, RESEARCH_RISK_RESPONSE_DETAILS.CPF_PARTNER_EC, count(*)
    from RESEARCH_RISK
             join RESEARCH_RISK_RESPONSE on RESEARCH_RISK.COD_RESEARCH_RISK = RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK
             join RESEARCH_RISK_RESPONSE_DETAILS on RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE =
                                                    RESEARCH_RISK_RESPONSE_DETAILS.COD_RESEARCH_RISK_RESPONSE
    where COD_RESEARCH_RISK_TYPE = 4
      and CPF_PARTNER_EC is not null
      and COD_EC = @COD_EC
    group by CPF_PARTNER_EC, COD_EC
END

--ET-1347

GO

--ST-1960


GO

IF OBJECT_ID('SP_GEN_TITLES_TRANS') IS NOT NULL
DROP PROCEDURE [SP_GEN_TITLES_TRANS]

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
	Caike Uch�a                 v9          2021-03-18      add cod_model titles_cost
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
DECLARE @COD_MODEL INT;
DECLARE @OUTPUT_TITLE AS TABLE  
(  
COD_TITLE INT,  
COD_EC INT,  
COD_TRAN INT,  
PLOT INT,  
AMOUNT DECIMAL(22,6),  
MDR DECIMAL(22,6),  
ANTECIP DECIMAL(22,6),  
RATE DECIMAL(22,6),  
PREVISION DATE,  
COD_PLAN INT,  
QTY_DAYS INT,  
COD_ASS_PLAN INT  
)  
  
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
          
--********************* SELECT DATA FROM [TRANSACTION] TO GENERATE TITTLES ************************  
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
				 , @COD_MODEL = ASS_TAX_DEPART.COD_MODEL
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
     , @COD_TRAN = [TRANSACTION].CODE
	 ,@COD_MODEL = ASS_TAX_DEPART.COD_MODEL
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
    
--------- VERIFY SITUATIONS TO GENERATE TITLES  
  
    SELECT @COD_AWAIT_SPLIT = COD_SITUATION          
    FROM SITUATION          
    WHERE [NAME] = 'WAITING FOR SPLIT OF FINANCE SCHEDULE'          
    SELECT @COD_AWAIT_PAY = COD_SITUATION          
    FROM SITUATION          
    WHERE [NAME] = 'AWAITING PAYMENT'          
    SELECT @COD_EXTERNAL_PROCESSING = COD_SITUATION          
    FROM SITUATION          
    WHERE [NAME] = 'LIQUIDACAO PROCESSADORA'        
   
 --- SPLIT OF SCHEDULE  
          
    SELECT @LEDGER_RETENTION = COUNT(*)          
    FROM SERVICES_AVAILABLE s          
             JOIN ITEMS_SERVICES_AVAILABLE item          
                  ON item.COD_ITEM_SERVICE = s.COD_ITEM_SERVICE          
    WHERE s.COD_EC = @COD_EC          
      AND item.CODE = '8'          
      AND s.ACTIVE = 1          
          
  -------  D+0 PLAN  
  
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
   
 ---------  *************** VERIFY IF TRANSACTION HAVE AFF TITLES ******************************  
          
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
			  AND ([PLAN_TAX_AFFILIATOR].COD_MODEL = @COD_MODEL OR [PLAN_TAX_AFFILIATOR].COD_MODEL IS NULL)
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
     
  --**************************** INSERT TITTLE *****************************  
    
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
  
OUTPUT INSERTED.COD_TITLE,      
INSERTED.COD_EC,      
INSERTED.COD_TRAN,      
INSERTED.PLOT,      
INSERTED.AMOUNT,      
INSERTED.TAX_INITIAL,      
INSERTED.ANTICIP_PERCENT,  
INSERTED.PREVISION_PAY_DATE,  
INSERTED.QTY_DAYS_ANTECIP,  
INSERTED.COD_ASS_TX_DEP,  
INSERTED.RATE  
INTO @OUTPUT_TITLE (  
COD_TITLE,   
COD_EC,      
COD_TRAN,  
PLOT,   
AMOUNT,  
MDR,  
ANTECIP,  
PREVISION,  
QTY_DAYS,  
COD_ASS_PLAN,  
RATE  
)    
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
   
-- ***********************  GET TITLE INSERTED ******************************  
  
                 SELECT @COD_TITTLE_INSERTED = COD_TITLE FROM @OUTPUT_TITLE         
      
--- ******************** INSERTE TITLE UR  *********************************  
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
       
--- ************** INSERT INTO WEBHOOK QUEUE ************  
  
INSERT INTO TRANSACTION_TITTLE_QUEUE  
(  
COD_TITLE  
,COD_TRAN  
,NSU  
,COD_EC  
,EC_NAME  
,COD_PLAN  
,PLAN_NAME  
,AMOUNT  
,NET_AMOUNT  
,PLOT  
,SITUATION  
,MDR  
,ANTICIP  
,RATE  
,PREVISION_PAYMENT  
,COD_AFFILIATOR  
)  
SELECT   
OUP.COD_TITLE,  
OUP.COD_TRAN,  
@COD_TRAN,  
OUP.COD_EC,  
COMMERCIAL_ESTABLISHMENT.[NAME],  
[PLAN].COD_PLAN,  
[PLAN].[CODE],  
OUP.AMOUNT,  
 CAST((((OUP.AMOUNT * (1 - (OUP.MDR / 100))) *    
  IIF(OUP.ANTECIP IS NULL, 1,    
  1 - (((OUP.ANTECIP / 30) * COALESCE(OUP.QTY_DAYS,    
  (OUP.[PLOT] * 30) - 1)) /    
  100))) - (IIF(OUP.PLOT = 1, OUP.[RATE], 0))) AS DECIMAL(22, 6)) ,  
OUP.PLOT,  
'AGUARDANDO PAGAMENTO',  
OUP.MDR,  
OUP.ANTECIP,  
OUP.RATE,  
OUP.PREVISION,  
@COD_AFFILIATOR  
 FROM @OUTPUT_TITLE OUP  
 JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = OUP.COD_EC  
 JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_ASS_TX_DEP = OUP.COD_ASS_PLAN  
 JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN  
  
 -------********** END WEBHOOK QUEUE  
  
          
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
    
 --- *********** INSERT TITTLE  
   
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
     OUTPUT INSERTED.COD_TITLE,      
INSERTED.COD_EC,      
INSERTED.COD_TRAN,      
INSERTED.PLOT,      
INSERTED.AMOUNT,      
INSERTED.TAX_INITIAL,      
INSERTED.ANTICIP_PERCENT,  
INSERTED.PREVISION_PAY_DATE,  
INSERTED.QTY_DAYS_ANTECIP,  
INSERTED.COD_ASS_TX_DEP,  
INSERTED.RATE  
INTO @OUTPUT_TITLE (  
COD_TITLE,   
COD_EC,      
COD_TRAN,  
PLOT,   
AMOUNT,  
MDR,  
ANTECIP,  
PREVISION,  
QTY_DAYS,  
COD_ASS_PLAN,  
RATE  
)    
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
          
                 SELECT @COD_TITTLE_INSERTED = COD_TITLE FROM @OUTPUT_TITLE         
       
          
          
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
  
-- ************** INSERT UR DATA  
  
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
           
--- ************** INSERT INTO WEBHOOK QUEUE ************  
  
INSERT INTO TRANSACTION_TITTLE_QUEUE  
(  
COD_TITLE  
,COD_TRAN  
,NSU  
,COD_EC  
,EC_NAME  
,COD_PLAN  
,PLAN_NAME  
,AMOUNT  
,NET_AMOUNT  
,PLOT  
,SITUATION  
,MDR  
,ANTICIP  
,RATE  
,PREVISION_PAYMENT  
,COD_AFFILIATOR  
)  
SELECT   
OUP.COD_TITLE,  
OUP.COD_TRAN,  
@COD_TRAN,  
OUP.COD_EC,  
COMMERCIAL_ESTABLISHMENT.[NAME],  
[PLAN].COD_PLAN,  
[PLAN].[CODE],  
OUP.AMOUNT,  
 CAST((((OUP.AMOUNT * (1 - (OUP.MDR / 100))) *    
  IIF(OUP.ANTECIP IS NULL, 1,    
  1 - (((OUP.ANTECIP / 30) * COALESCE(OUP.QTY_DAYS,    
  (OUP.[PLOT] * 30) - 1)) /    
  100))) - (IIF(OUP.PLOT = 1, OUP.[RATE], 0))) AS DECIMAL(22, 6)) ,  
OUP.PLOT,  
'AGUARDANDO PAGAMENTO',  
OUP.MDR,  
OUP.ANTECIP,  
OUP.RATE,  
OUP.PREVISION,  
@COD_AFFILIATOR  
 FROM @OUTPUT_TITLE OUP  
 JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = OUP.COD_EC  
 JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_ASS_TX_DEP = OUP.COD_ASS_PLAN  
 JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN  
  
 -------********** END WEBHOOK QUEUE  
          
          
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

SELECT 
COD_TITLE,
MDR_CURRENT_AFF,
COD_AFFILIATOR
INTO #TEMP_TITLE_MDR
FROM REPORT_CONSOLIDATED_TRANS_SUB WITH(NOLOCK)
WHERE COD_REP_CONSO_TRANS_SUB BETWEEN 23766334 AND 24230038


SELECT COD_TITLE
INTO #TEMP_TITLE
FROM #TEMP_TITLE_MDR
WHERE MDR_CURRENT_AFF = 0 OR MDR_CURRENT_AFF IS NULL



UPDATE TRANSACTION_TITLES_COST SET [PERCENTAGE]= PLAN_TAX_AFFILIATOR.[PERCENTAGE]
FROM TRANSACTION_TITLES_COST 
JOIN TRANSACTION_TITLES ON TRANSACTION_TITLES.COD_TITLE = TRANSACTION_TITLES_COST.COD_TITLE
JOIN [TRANSACTION] ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
LEFT JOIN PLAN_TAX_AFFILIATOR ON PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = TRANSACTION_TITLES_COST.COD_AFFILIATOR
JOIN [PLAN] ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN
JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_ASS_TX_DEP = [TRANSACTION].COD_ASS_TX_DEP
AND PLAN_TAX_AFFILIATOR.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE
AND  PLAN_TAX_AFFILIATOR.QTY_INI_PLOTS BETWEEN ASS_TAX_DEPART.QTY_INI_PLOTS AND ASS_TAX_DEPART.QTY_FINAL_PLOTS
AND PLAN_TAX_AFFILIATOR.QTY_FINAL_PLOTS BETWEEN ASS_TAX_DEPART.QTY_INI_PLOTS AND ASS_TAX_DEPART.QTY_FINAL_PLOTS 
AND PLAN_TAX_AFFILIATOR.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
AND (PLAN_TAX_AFFILIATOR.COD_MODEL = ASS_TAX_DEPART.COD_MODEL OR PLAN_TAX_AFFILIATOR.COD_MODEL IS NULL)
AND PLAN_TAX_AFFILIATOR.COD_SOURCE_TRAN = ASS_TAX_DEPART.COD_SOURCE_TRAN
AND PLAN_TAX_AFFILIATOR.ACTIVE= 1
 AND [PLAN].COD_PLAN_CATEGORY <> 3 
 AND PLAN_TAX_AFFILIATOR.[PERCENTAGE] > 0
 --AND (TRANSACTION_TITLES_COST.[PERCENTAGE] = 0 OR TRANSACTION_TITLES_COST.[PERCENTAGE] IS NULL) 
WHERE 
 TRANSACTION_TITLES.COD_TITLE IN (SELECT * FROM #TEMP_TITLE)



SELECT 
  IIF([TRANSACTION].PLOTS = 1, dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE] +    
  IIF((SELECT    
    COUNT(*)    
   FROM TRANSACTION_SERVICES    
   INNER JOIN ITEMS_SERVICES_AVAILABLE    
    ON TRANSACTION_SERVICES.COD_ITEM_SERVICE =    
    ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE    
   WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'    
   AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN    
   AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC  
   ) > 0,    
  TRANSACTION_TITLES_COST.TAX_PLANDZERO,    
  0), TRANSACTION_TITLES.AMOUNT),    
  dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE], TRANSACTION_TITLES.AMOUNT)) AS LIQUID_MDR_AFF,
  TRANSACTION_TITLES.COD_TITLE
INTO #TEMP_MDR_AFF
FROM [TRANSACTION_TITLES] WITH(NOLOCK)
JOIN [TRANSACTION] 
WITH(NOLOCK)
ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
LEFT JOIN [TRANSACTION_TITLES_COST]     
WITH (NOLOCK)      
ON [TRANSACTION_TITLES].COD_TITLE = TRANSACTION_TITLES_COST.COD_TITLE 
LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = TRANSACTION_TITLES_COST.COD_AFFILIATOR
JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = TRANSACTION_TITLES.COD_EC
JOIN AFFILIATOR AFF ON AFF.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
WHERE TRANSACTION_TITLES.COD_TITLE IN (SELECT * FROM #TEMP_TITLE)


GO

CREATE TABLE #DELETE
(
MDR_CURRENT_AFF DECIMAL(22,6),
COD_TITLE INT
)

DECLARE @CONT INT;

SET @CONT = 0;

WHILE @CONT < 4
BEGIN 

INSERT INTO #DELETE
SELECT TOP 10000 LIQUID_MDR_AFF,COD_TITLE FROM #TEMP_MDR_AFF


UPDATE REPORT_CONSOLIDATED_TRANS_SUB SET MDR_CURRENT_AFF= #DELETE.MDR_CURRENT_AFF
FROM REPORT_CONSOLIDATED_TRANS_SUB
JOIN #DELETE ON #DELETE.COD_TITLE = REPORT_CONSOLIDATED_TRANS_SUB.COD_TITLE
WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_TITLE IN (SELECT COD_TITLE FROM #DELETE) 

DELETE FROM #TEMP_MDR_AFF WHERE COD_TITLE IN (SELECT COD_TITLE FROM #DELETE)

DELETE FROM #DELETE

SELECT @CONT AS QTY;

SET @CONT = @CONT + 1;

END


DROP TABLE #DELETE
DROP TABLE #TEMP_TITLE
DROP TABLE #TEMP_MDR_AFF
DROP TABLE #TEMP_TITLE_MDR

GO

--ST-1960

GO

--ET-1354

GO

IF OBJECT_ID('SP_REPORT_TARIFF') IS NOT NULL
DROP PROCEDURE [SP_REPORT_TARIFF];

GO
CREATE PROCEDURE [dbo].[SP_REPORT_TARIFF]    
    
/***********************************************************************************************      
----------------------------------------------------------------------------------------            
Procedure Name: [SP_REPORT_TARIFF]            
Project.......: TKPP            
------------------------------------------------------------------------------------------            
Author                          VERSION        Date                            Description            
------------------------------------------------------------------------------------------            
Kennedy Alef                       V1        27/07/2018                       Creation            
Caike Uchôa                        V2        14/09/2020                    Add Representante    
Caike Uchoa                        v6        13/11/2020         add join arrang_to_pay com a protocols  
Caike Uchoa                        v7        18/03/2021                   add filtros por data
------------------------------------------------------------------------------------------      
***********************************************************************************************/ (
@INITIAL_DATE DATETIME = NULL,    
@FINAL_DATE DATETIME = NULL,    
@CODCOMP INT,    
@CPFEC VARCHAR(100),    
@CODAFF INT = NULL,
@INITIAL_DATE_PAY DATETIME = NULL,    
@FINAL_DATE_PAY DATETIME = NULL,
@INITIAL_DATE_CREATED DATETIME = NULL,
@FINAL_DATE_CREATED DATETIME = NULL
)    

AS    
BEGIN    
 DECLARE @QUERY_BASIS NVARCHAR(MAX);    
    
 BEGIN    
    
  SET @QUERY_BASIS = '            
SELECT [TARIFF_EC].[PLOT],       
   [TARIFF_EC].[CREATED_AT],       
   [TARIFF_EC].[PAYMENT_DAY] AS [PREVISION_PAY_DAY],       
   [TARIFF_EC].VALUE,       
   [TFF_PARTIAL].VALUE AS [ORIGINAL_VALUE],       
   [FINANCE_CALENDAR].[EC_NAME] AS [NAME],       
   [FINANCE_CALENDAR].[EC_CPF_CNPJ] AS [CPF_CNPJ],       
   ISNULL([PROTOCOLS].[PROTOCOL], ''-'') AS [PROTOCOL],       
   [TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION],       
   [PROTOCOLS].[CREATED_AT] AS [PAYMENT_DAY],       
   [FINANCE_CALENDAR].[COD_AFFILIATOR],       
   [FINANCE_CALENDAR].[AFFILIATOR_NAME] AS [NAME_AFFILIATOR],      
   [TARIFF_EC].[IS_PARTIAL],      
   TFF_PARTIAL.COD_TARIFF_EC as COD_TARIFF_EC_PARTIAL,      
   TARIFF_EC.COD_TARIFF_EC,      
   TARIFF_EC.COMMENT,      
   USER_SALES.IDENTIFICATION AS SALES_REPRESENTATIVE,    
   USER_SALES.CPF_CNPJ AS CPF_CNPJ_REPRESENTATIVE,    
   USER_SALES.EMAIL AS EMAIL_REPRESENTATIVE
FROM [FINANCE_CALENDAR]      
 JOIN [TARIFF_EC] ON [TARIFF_EC].[COD_FIN_CALENDAR] = [FINANCE_CALENDAR].[COD_FIN_CALENDAR]        
 LEFT JOIN [TARIFF_EC] AS [TFF_PARTIAL] ON [TFF_PARTIAL].[COD_TARIFF_EC] = [TARIFF_EC].[COD_ORIGIN]     
 JOIN DETAILS_ARRANG_TO_PAY ON DETAILS_ARRANG_TO_PAY.COD_TARIFF_EC = TARIFF_EC.COD_TARIFF_EC  
 JOIN ARRANG_TO_PAY ON ARRANG_TO_PAY.COD_ARR_PAY = DETAILS_ARRANG_TO_PAY.COD_ARR_PAY  
  AND ARRANG_TO_PAY.COD_FIN_CALENDAR = TARIFF_EC.COD_FIN_CALENDAR  
  LEFT JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = ARRANG_TO_PAY.COD_PAY_PROT  
 JOIN [TRADUCTION_SITUATION] ON [TRADUCTION_SITUATION].[COD_SITUATION] = [FINANCE_CALENDAR].[COD_SITUATION]      
 LEFT JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = TARIFF_EC.COD_EC    
 LEFT JOIN SALES_REPRESENTATIVE SP ON SP.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP    
 LEFT JOIN USERS USER_SALES ON USER_SALES.COD_USER = SP.COD_USER    
WHERE [FINANCE_CALENDAR].[ACTIVE] = 1 AND FINANCE_CALENDAR.COD_COMP = ''' + CAST(@CODCOMP AS VARCHAR) + ''' ';


   IF @INITIAL_DATE IS NOT NULL AND @FINAL_DATE IS NOT NULL
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND TARIFF_EC.PAYMENT_DAY BETWEEN ''' + CAST(@INITIAL_DATE AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE AS VARCHAR) + ''' ');           
   

   IF @INITIAL_DATE_PAY IS NOT NULL AND @FINAL_DATE_PAY IS NOT NULL
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND PROTOCOLS.CREATED_AT BETWEEN ''' + CAST(@INITIAL_DATE_PAY AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE_PAY AS VARCHAR) + ''' ');         
   
      IF @INITIAL_DATE_CREATED IS NOT NULL AND @FINAL_DATE_CREATED IS NOT NULL
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND TARIFF_EC.CREATED_AT BETWEEN ''' + CAST(@INITIAL_DATE_CREATED AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE_CREATED AS VARCHAR) + ''' ');         
      
 
  IF @CPFEC IS NOT NULL    
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.EC_CPF_CNPJ  = @CPFEC ');    
    
  IF @CODAFF IS NOT NULL    
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND FINANCE_CALENDAR.COD_AFFILIATOR  = @CodAff ');    
    
  SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY TARIFF_EC.PAYMENT_DAY DESC, FINANCE_CALENDAR.cod_ec');    
    
    
  --EXECUTE (@QUERY_BASIS);            
  EXEC [sp_executesql] @QUERY_BASIS    
       ,N'            
    @CPFEC varchar(14),            
    @CodAff INT,
    @INITIAL_DATE DATETIME = NULL,    
    @FINAL_DATE DATETIME = NULL,    
    @INITIAL_DATE_PAY DATETIME = NULL,    
    @FINAL_DATE_PAY DATETIME = NULL,
	@INITIAL_DATE_CREATED DATETIME = NULL,
    @FINAL_DATE_CREATED DATETIME = NULL
     '
	 
   ,@CPFEC = @CPFEC    
   ,@CODAFF = @CODAFF
    ,@INITIAL_DATE =@INITIAL_DATE
    ,@FINAL_DATE = @FINAL_DATE 
    ,@INITIAL_DATE_PAY = @INITIAL_DATE_PAY 
    ,@FINAL_DATE_PAY = @FINAL_DATE_PAY
	,@INITIAL_DATE_CREATED= @INITIAL_DATE_CREATED
	,@FINAL_DATE_CREATED = @FINAL_DATE_CREATED;    
    
 END;    
END;


GO

IF OBJECT_ID('SP_REPORT_TARIFF_AFL') IS NOT NULL
DROP PROCEDURE [SP_REPORT_TARIFF_AFL];

GO
CREATE PROCEDURE [dbo].[SP_REPORT_TARIFF_AFL]    
/*----------------------------------------------------------------------------------------          
Procedure Name: [SP_REPORT_TARIFF_AFL]          
Project.......: TKPP          
------------------------------------------------------------------------------------------          
Author                          VERSION        Date                            Description          
------------------------------------------------------------------------------------------          
Gian Luca Dalle Cort                V1       02/08/2018                         CREATION          
Caike Uchoa Almeida                 V2       05/08/2019               inser��o de colunas no relat�rio        
Caike Uchoa                         V3       15/09/2020                        Add Representante    
Caike Uchoa                         v4       06/01/2021         add join arrang_to_pay com a protocols    
Caike Uchoa                         v5       18/03/2021                   add filtros por data
------------------------------------------------------------------------------------------*/ (  
@INITIAL_DATE DATETIME = NULL,    
@FINAL_DATE DATETIME = NULL,    
@COD_AFFILIATOR INT,    
@CPFEC VARCHAR(100),
@INITIAL_DATE_PAY DATETIME = NULL,    
@FINAL_DATE_PAY DATETIME = NULL,
@INITIAL_DATE_CREATED DATETIME = NULL,
@FINAL_DATE_CREATED DATETIME = NULL
)    
AS    
 DECLARE @QUERY_BASIS NVARCHAR(MAX);  
    
    
 BEGIN  
  
SET @QUERY_BASIS = '          
SELECT           
TARIFF_EC.PLOT AS PLOT,          
TARIFF_EC.CREATED_AT,            
CAST(TARIFF_EC.PAYMENT_DAY AS DATE) AS PREVISION_PAY_DAY,              
TARIFF_EC.VALUE,          
COMMERCIAL_ESTABLISHMENT.NAME,          
COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,          
ISNULL(PROTOCOLS.PROTOCOL,''-'') AS PROTOCOL,          
TRADUCTION_SITUATION.SITUATION_TR AS SITUATION,        
PROTOCOLS.CREATED_AT AS PAYMENT_DAY,       
USER_SALES.IDENTIFICATION AS SALES_REPRESENTATIVE,    
USER_SALES.CPF_CNPJ AS CPF_CNPJ_REPRESENTATIVE,    
USER_SALES.EMAIL AS EMAIL_REPRESENTATIVE    
FROM TARIFF_EC      
JOIN [FINANCE_CALENDAR] ON [FINANCE_CALENDAR].[COD_FIN_CALENDAR] = [TARIFF_EC].[COD_FIN_CALENDAR]          
JOIN DETAILS_ARRANG_TO_PAY ON DETAILS_ARRANG_TO_PAY.COD_TARIFF_EC = TARIFF_EC.COD_TARIFF_EC    
JOIN ARRANG_TO_PAY ON ARRANG_TO_PAY.COD_ARR_PAY = DETAILS_ARRANG_TO_PAY.COD_ARR_PAY    
  AND ARRANG_TO_PAY.COD_FIN_CALENDAR = TARIFF_EC.COD_FIN_CALENDAR    
LEFT JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = ARRANG_TO_PAY.COD_PAY_PROT    
INNER JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = TARIFF_EC.COD_EC          
INNER JOIN COMPANY ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP          
INNER JOIN SITUATION ON SITUATION.COD_SITUATION = TARIFF_EC.COD_SITUATION           
INNER JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = TARIFF_EC.COD_SITUATION          
LEFT JOIN SALES_REPRESENTATIVE SP ON SP.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP    
LEFT JOIN USERS USER_SALES ON USER_SALES.COD_USER = SP.COD_USER    
WHERE COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = ''' + CAST(@COD_AFFILIATOR AS VARCHAR) + ''' ';  
    
    
   IF @INITIAL_DATE IS NOT NULL AND @FINAL_DATE IS NOT NULL
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND TARIFF_EC.PAYMENT_DAY BETWEEN ''' + CAST(@INITIAL_DATE AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE AS VARCHAR) + ''' ');           
   

   IF @INITIAL_DATE_PAY IS NOT NULL AND @FINAL_DATE_PAY IS NOT NULL
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND PROTOCOLS.CREATED_AT BETWEEN ''' + CAST(@INITIAL_DATE_PAY AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE_PAY AS VARCHAR) + ''' ');         
   
      IF @INITIAL_DATE_CREATED IS NOT NULL AND @FINAL_DATE_CREATED IS NOT NULL
   SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND TARIFF_EC.CREATED_AT BETWEEN ''' + CAST(@INITIAL_DATE_CREATED AS VARCHAR) + ''' AND ''' + CAST(@FINAL_DATE_CREATED AS VARCHAR) + ''' ');        

    
  IF @CPFEC IS NOT NULL  
--SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,' AND COMMERCIAL_ESTABLISHMENT.CPF_CNPJ  = '''+@CPFEC+''' ');          
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COMMERCIAL_ESTABLISHMENT.CPF_CNPJ  = @CPFEC ');  
  
SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY TARIFF_EC.PAYMENT_DAY DESC')  
  
  

	    EXEC [sp_executesql] @QUERY_BASIS    
       ,N'            
    @CPFEC varchar(14),            
    @INITIAL_DATE DATETIME = NULL,    
    @FINAL_DATE DATETIME = NULL,    
    @INITIAL_DATE_PAY DATETIME = NULL,    
    @FINAL_DATE_PAY DATETIME = NULL,
	@INITIAL_DATE_CREATED DATETIME = NULL,
    @FINAL_DATE_CREATED DATETIME = NULL

'    
   ,@CPFEC = @CPFEC   
    ,@INITIAL_DATE =@INITIAL_DATE
    ,@FINAL_DATE = @FINAL_DATE 
    ,@INITIAL_DATE_PAY = @INITIAL_DATE_PAY 
    ,@FINAL_DATE_PAY = @FINAL_DATE_PAY
	,@INITIAL_DATE_CREATED= @INITIAL_DATE_CREATED
	,@FINAL_DATE_CREATED = @FINAL_DATE_CREATED;    
    

END;  
GO  
--ET-1354

GO

--ST-1967

GO 

IF OBJECT_ID('SP_REG_PROV_PASS_USER') IS NOT NULL
DROP PROCEDURE [SP_REG_PROV_PASS_USER];

GO
CREATE PROCEDURE [dbo].[SP_REG_PROV_PASS_USER]      
/*----------------------------------------------------------------------------------------      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                VERSION            Date             Description      
------------------------------------------------------------------------------------------      
Kennedy Alef             V1           27/07/2018           Creation      
Caike Uchoa              V2           07/07/2020            NOT RETURN  
Caike Uchoa              v3           04/03/2021             corre��o 
------------------------------------------------------------------------------------------*/      
(   @CODACESS VARCHAR(100),      
     @ACCESS_KEY VARCHAR(200),      
     @VALUE VARCHAR(200),      
     @REQUIRED INT,      
     @COD_AFFILIATOR INT = NULL,    
  @NOT_RETURN INT = NULL)      
AS      
DECLARE @LOGIN VARCHAR(250);  
    
      
DECLARE @NAME VARCHAR(250);  
    
      
DECLARE @EMAIL VARCHAR(250) = NULL;  
    
      
DECLARE @PASSPROV VARCHAR(100) = NULL;  
    
      
DECLARE @CODUSER INT = NULL;  
    
      
DECLARE @SUBDOMAIN VARCHAR(100);  
    
      
DECLARE @COD_AFF_FIND INT = NULL;  
    
      
DECLARE @COLOR VARCHAR(16) = NULL;  
    
      
DECLARE @LOG_AF VARCHAR (256) = NULL;  
    
      
BEGIN  
    
      
    IF @COD_AFFILIATOR IS NULL  
SET @COD_AFFILIATOR = 0;  
  
SELECT  
 @PASSPROV = PROVISORY_PASS_USER.value  
   ,@EMAIL = EMAIL  
   ,@NAME = IDENTIFICATION  
   ,@LOGIN = USERS.COD_ACCESS  
   ,@SUBDOMAIN = AFFILIATOR.SUBDOMAIN  
FROM PROVISORY_PASS_USER  
INNER JOIN USERS  
 ON USERS.COD_USER = PROVISORY_PASS_USER.COD_USER  
INNER JOIN COMPANY  
 ON COMPANY.COD_COMP = USERS.COD_COMP  
LEFT JOIN AFFILIATOR  
 ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR  
WHERE COD_ACCESS = @CODACESS  
AND COMPANY.ACCESS_KEY = @ACCESS_KEY  
AND PROVISORY_PASS_USER.ACTIVE = 1  
AND DATEDIFF(DAY, PROVISORY_PASS_USER.CREATED_AT, GETDATE()) < 1  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
OR USERS.CPF_CNPJ = @CODACESS  
AND COMPANY.ACCESS_KEY = @ACCESS_KEY  
AND PROVISORY_PASS_USER.ACTIVE = 1  
AND DATEDIFF(DAY, PROVISORY_PASS_USER.CREATED_AT, GETDATE()) < 1  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
OR USERS.EMAIL = @CODACESS  
AND COMPANY.ACCESS_KEY = @ACCESS_KEY  
AND PROVISORY_PASS_USER.ACTIVE = 1  
AND DATEDIFF(DAY, PROVISORY_PASS_USER.CREATED_AT, GETDATE()) < 1  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
  
IF @PASSPROV IS NOT NULL  
 AND @NOT_RETURN IS NULL  
BEGIN  
SELECT  
 @PASSPROV AS PASS  
   ,@EMAIL AS EMAIL  
   ,@NAME AS NAME  
   ,@LOGIN AS login  
END;  
ELSE  
BEGIN  

SELECT  
 @COD_AFF_FIND = COD_AFFILIATOR  
FROM USERS  
WHERE COD_ACCESS = @CODACESS
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
OR USERS.CPF_CNPJ = @CODACESS  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
OR USERS.EMAIL = @CODACESS 
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  


IF @COD_AFF_FIND IS NOT NULL  
SET @COD_AFFILIATOR = @COD_AFF_FIND  
SELECT  
 @CODUSER = USERS.COD_USER  
   ,@EMAIL = EMAIL  
   ,@NAME = IDENTIFICATION  
   ,@LOGIN = USERS.COD_ACCESS  
   ,@SUBDOMAIN = AFFILIATOR.SUBDOMAIN  
   ,@COLOR = T.COLOR_HEADER  
   ,@LOG_AF = T.LOGO_AFFILIATE  
FROM USERS  
INNER JOIN COMPANY  
 ON COMPANY.COD_COMP = USERS.COD_COMP  
LEFT JOIN AFFILIATOR  
 ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR  
LEFT JOIN THEMES T  
 ON AFFILIATOR.COD_AFFILIATOR = T.COD_AFFILIATOR  
  AND T.ACTIVE = 1  
WHERE COD_ACCESS = @CODACESS  
AND COMPANY.ACCESS_KEY = @ACCESS_KEY  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
OR USERS.CPF_CNPJ = @CODACESS  
AND COMPANY.ACCESS_KEY = @ACCESS_KEY  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
OR USERS.EMAIL = @CODACESS  
AND COMPANY.ACCESS_KEY = @ACCESS_KEY  
AND (ISNULL(USERS.COD_AFFILIATOR, 0) = @COD_AFFILIATOR)  
  
IF @EMAIL IS NULL  
 OR @CODUSER IS NULL  
THROW 61006, 'USER NOT FOUND', 1;  
  
UPDATE USERS  
SET LOGGED = 0  
   ,LOCKED_UP = NULL  
WHERE COD_USER = @CODUSER  
INSERT INTO PROVISORY_PASS_USER (VALUE, COD_USER)  
 VALUES (@VALUE, @CODUSER)  
IF @@rowcount < 1  
THROW 60000, 'COULD NOT REGISTER PROVISORY_PASS_USER', 1  
IF (@REQUIRED = 1)  
BEGIN  
EXEC [SP_REG_HISTORY_PASS] @COD_USER = @CODUSER  
        ,@PASS = NULL  
END  
  
IF @NOT_RETURN IS NULL  
BEGIN  
SELECT  
 ISNULL(@PASSPROV, @VALUE) AS PASS  
   ,@EMAIL AS EMAIL  
   ,@NAME AS NAME  
   ,@LOGIN AS login  
   ,@CODUSER AS INSIDE_CODE  
   ,@SUBDOMAIN AS SUBDOMAIN  
   ,@COLOR AS AFF_COLOR  
   ,@LOG_AF AS LOG_AFF  
END  
END;  
END;

GO

--ST-1967

GO

--ST-1969

GO 

IF OBJECT_ID('SP_GEN_SPLIT_TRANSACTION')IS NOT NULL
DROP PROCEDURE SP_GEN_SPLIT_TRANSACTION

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
  Caike Uchoa            v5       17/11/2020                alter reprocessamento relat�rio    
  Kennedy Alef          v14       04/03/2021    registrar fila de webhook     
  Caike uchoa           v15       23/03/2021                 Alter calculo qtd days para date_tran        
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
          PREVISION_PAYMENT DATE,  
          MDR   DECIMAL(22,6),  
          COD_ASS_PLAN INT,  
          RATE    DECIMAL(22,6),  
          PLOT  INT,  
          COD_TRAN  INT,  
          AMOUNT DECIMAL(22,6),  
          QTY_DAYS INT  
                           );    
  
  
            
    DECLARE @COD_AC INT;    
           
 DECLARE @COD_MODEL INT;    
      
 DECLARE            
    @DATA_TRANSACTION TABLE            
                      (            
                          TRANSACTION_AMOUNT     DECIMAL(22, 6),            
                          COD_TTYPE              INT,            
                          BRAND                  VARCHAR(255),            
        PLOTS                 INT,            
                          NSU                    VARCHAR(255),            
                          PAN                    VARCHAR(255),            
                          COD_ASS_DEPTO_TERMINAL INT,            
                          TRANSACTION_DATE       DATETIME            
                      );    
    
    
    
    
SELECT    
 @COD_TRAN = [TRANSACTION].COD_TRAN    
   ,@EC_SOURCE_COD = COMMERCIAL_ESTABLISHMENT.COD_EC    
   ,@EC_SOURCE = COMMERCIAL_ESTABLISHMENT.CPF_CNPJ    
   ,@BRAND = [TRANSACTION].BRAND    
   ,@QTY_PLOT = [TRANSACTION].PLOTS    
   ,@SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN    
   ,@TYPE_TRAN = [TRANSACTION].COD_TTYPE    
   ,@AFFILIATOR = AFFILIATOR.CPF_CNPJ    
   ,@AMOUNT_TR = [TRANSACTION].AMOUNT    
   ,@AFF_SOURCE_COD = AFFILIATOR.COD_AFFILIATOR    
   ,@COD_BRAND = BRAND.COD_BRAND    
   ,@COD_SITUATION = [TRANSACTION].COD_SITUATION    
   ,@TRAN_DATE = dbo.FN_FUS_UTF([TRANSACTION].CREATED_AT)    
   ,@CODASS_EQUIP = [TRANSACTION].COD_ASS_DEPTO_TERMINAL    
   ,@TX_ACQ = ASS_TR_TYPE_COMP.TAX_VALUE    
   ,@INTERVAL_ACQ = ASS_TR_TYPE_COMP.INTERVAL    
   ,@CODE_EC = COMMERCIAL_ESTABLISHMENT.CODE    
   ,@COD_AC = PRODUCTS_ACQUIRER.COD_AC    
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
JOIN PRODUCTS_ACQUIRER    
 ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ    
JOIN EQUIPMENT    
 ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP    
JOIN EQUIPMENT_MODEL    
 ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL    
WHERE [TRANSACTION].CODE = @NSU    
    
IF @COD_SITUATION <> 22    
THROW 60000, '300 - Invalid situation for transaction', 1;    
    
IF @CODE_EC <> @MERCHANT    
THROW 60000, '301 - Invalid Merchant source', 1    
    
SELECT    
 @AMOUNT_SPLIT = SUM(AMOUNT)    
FROM @ITEM    
    
IF @AMOUNT_TR <> @AMOUNT_SPLIT    
THROW 60000, '303 - Invalid amount for split ', 1;    
    
SELECT    
 @QTY = COUNT(*)    
FROM @ITEM    
WHERE [DOC_AFFILIATOR] <> @AFFILIATOR    
IF @QTY > 0    
THROW 60000, '304 -Invalid Affiliator between Merchant and transaction', 1;    
    
SELECT    
 @COD_PLANDZERO_SERVICE = COD_ITEM_SERVICE    
FROM ITEMS_SERVICES_AVAILABLE    
WHERE NAME = 'PlanDZero'    
    
SET @CURRENTHOUR = DATEPART(HOUR, @TRAN_DATE);    
            
    IF EXISTS (SELECT    
  COD_SCH_PLANDZERO    
 FROM PlanDZeroSchedule    
 WHERE WindowMaxHour > @CURRENTHOUR)    
BEGIN    
SET @PLANDZEROTODAY = 1    
SET @PlanDZeroHour = (SELECT TOP 1    
  WindowMaxHour    
 FROM PlanDZeroSchedule    
 WHERE WindowMaxHour > @CURRENTHOUR    
 ORDER BY WindowMaxHour)    
            
        END    
    
SET @TOMORROW_MORNING = CAST(DATEADD(DAY, 1, @TRAN_DATE) AS DATE)    
    
SELECT    
 ASS_TAX_DEPART.COD_ASS_TX_DEP AS COD_TX_MERCHANT    
   ,COMMERCIAL_ESTABLISHMENT.ACTIVE AS ACTIVE_MERCHANT    
   ,COMMERCIAL_ESTABLISHMENT.COD_EC MERCHANT    
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS DOC_MERCHANT    
   ,AFFILIATOR.COD_AFFILIATOR AS AFFILIATOR    
   ,AFFILIATOR.CPF_CNPJ AS DOC_AFFILIATOR    
   ,ASS_TAX_DEPART.PARCENTAGE AS MDR    
   ,ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE AS ANTICIP    
   ,ASS_TAX_DEPART.INTERVAL    
   ,ASS_TAX_DEPART.RATE    
   ,[PLAN].COD_T_PLAN    
   ,ITEM.AMOUNT    
   ,NULL AS COD_SPLIT_PROD    
   ,IIF(SA.COD_SERVICE IS NULL OR @PLANDZEROTODAY = 0 OR (SELECT    
   COD_T_PLAN    
  FROM DEPARTMENTS_BRANCH db    
  WHERE db.COD_DEPTO_BRANCH = ASS_TAX_DEPART.COD_DEPTO_BRANCH)    
 = 1, NULL, CAST(JSON_VALUE(SA.CONFIG_JSON,    
 IIF(@TYPE_TRAN = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))) [PLANDZERO_MDR] INTO #EC    
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
  AND ISNULL(ASS_TAX_DEPART.COD_MODEL, @COD_MODEL) = @COD_MODEL    
JOIN [PLAN]    
 ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN    
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
    
IF (SELECT    
   COUNT(*)    
  FROM #EC    
  WHERE ACTIVE_MERCHANT = 0)    
 > 0    
THROW 60000, '305 - One or More Merchants are inactive', 1;    
    
    
IF (SELECT    
   COUNT(*)    
  FROM #EC)    
 <> (SELECT    
   COUNT(*)    
  FROM @ITEM)    
THROW 60000, '306 - One or More Merchants don''t have plan available to receive this transaction', 1;    
    
INSERT INTO [TRANSACTION_HISTORY] (COD_TRAN, CODE, COD_SITUATION, COMMENT)    
 SELECT    
  @COD_TRAN    
    ,@NSU    
    ,3    
    ,''    
    
UPDATE [TRANSACTION]    
SET COD_SITUATION = 3    
   ,MODIFY_DATE = GETDATE()    
   ,COMMENT = ''    
   ,CODE_ERROR = 200    
OUTPUT INSERTED.AMOUNT,    
INSERTED.COD_TTYPE,    
INSERTED.BRAND,    
INSERTED.PLOTS,    
INSERTED.CODE,    
INSERTED.PAN,    
INSERTED.COD_ASS_DEPTO_TERMINAL,    
INSERTED.BRAZILIAN_DATE INTO @DATA_TRANSACTION (TRANSACTION_AMOUNT, COD_TTYPE,    
BRAND, PLOTS, NSU, PAN,    
COD_ASS_DEPTO_TERMINAL, TRANSACTION_DATE)    
FROM [TRANSACTION] WITH (NOLOCK)    
WHERE [TRANSACTION].COD_TRAN = @COD_TRAN;    
    
IF @@rowcount < 1    
THROW 60001, 'COULD NOT UPDATE [TRANSACTION] ', 1;    
  
  
    
INSERT INTO TRANSACTION_AUTH_QUEUE (TRANSACTION_DATE, NSU, AUTH_CODE, NSU_EXT, AMOUNT, TRANSACTION_TYPE,    
BRAND, PLOTS, PAN,    
COD_TRAN, MERCHANT_NAME, MERCHANT_DOC, COD_EC, COD_EQUIP,    
COD_AFFILIATOR, MODEL_EQUIP, SITUATION, COMMENT)    
 SELECT    
  DT.TRANSACTION_DATE    
    ,DT.NSU    
    ,(SELECT TOP 1    
    TRANSACTION_DATA_EXT.[VALUE]    
   FROM TRANSACTION_DATA_EXT WITH (NOLOCK)    
   WHERE TRANSACTION_DATA_EXT.COD_TRAN = @COD_TRAN    
   AND TRANSACTION_DATA_EXT.[NAME] = 'AUTHCODE')    
    ,(SELECT TOP 1    
    [TRANSACTION_DATA_EXT].[VALUE]    
   FROM TRANSACTION_DATA_EXT    
   WHERE COD_TRAN = @COD_TRAN    
   AND [TRANSACTION_DATA_EXT].[NAME] IN ('NSU', 'RCPTTXID', 'AUTO', '0'))    
    ,DT.TRANSACTION_AMOUNT    
    ,TRANSACTION_TYPE.CODE    
    ,DT.BRAND    
    ,DT.PLOTS    
    ,DT.PAN    
    ,@COD_TRAN    
    ,CE.NAME    
    ,CE.CPF_CNPJ    
    ,CE.COD_EC    
    ,ASS_DEPTO_EQUIP.COD_EQUIP    
    ,CE.COD_AFFILIATOR    
    ,EQUIPMENT_MODEL.CODIGO    
    ,'CONFIRMADA'    
    ,'200-CONFIRMADA'    
 FROM @DATA_TRANSACTION DT    
 JOIN TRANSACTION_TYPE    
  ON TRANSACTION_TYPE.COD_TTYPE = DT.COD_TTYPE    
 JOIN ASS_DEPTO_EQUIP    
  ON ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = DT.COD_ASS_DEPTO_TERMINAL    
 JOIN DEPARTMENTS_BRANCH    
  ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH    
 JOIN BRANCH_EC    
  ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH    
 JOIN COMMERCIAL_ESTABLISHMENT CE    
  ON BRANCH_EC.COD_EC = CE.COD_EC    
 JOIN EQUIPMENT    
  ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP    
 JOIN EQUIPMENT_MODEL    
  ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL    
    
    
    
    
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
 SELECT    
  @COD_TRAN    
    ,@AFF_SOURCE_COD    
    ,@NSU    
    ,OP_COST.COD_OPER_COST_AFF    
    ,OP_COST.PERCENTAGE_COST    
    ,PLAN_TAX_AFFILIATOR.COD_PLAN_TAX_AFF    
    ,PLAN_TAX_AFFILIATOR.[PERCENTAGE]    
    ,PLAN_TAX_AFFILIATOR.RATE    
    ,PLAN_TAX_AFFILIATOR.ANTICIPATION_PERCENTAGE    
 FROM AFFILIATOR    
 INNER JOIN OPERATION_COST_AFFILIATOR OP_COST    
  ON OP_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR    
 INNER JOIN PROGRESSIVE_COST_AFFILIATOR PROG_COST    
  ON PROG_COST.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR    
 INNER JOIN PLAN_TAX_AFFILIATOR    
  ON PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR    
   AND ISNULL(PLAN_TAX_AFFILIATOR.COD_MODEL, @COD_MODEL) = @COD_MODEL    
    
 INNER JOIN [PLAN]    
  ON [PLAN].COD_PLAN = PLAN_TAX_AFFILIATOR.COD_PLAN    
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
OUTPUT   
INSERTED.COD_TITLE,   
@COD_BRAND,   
@TYPE_TRAN,   
@COD_AC,   
INSERTED.ANTICIP_PERCENT,   
INSERTED.COD_EC,   
INSERTED.PREVISION_PAY_DATE,  
INSERTED.TAX_INITIAL,  
INSERTED.COD_ASS_TX_DEP,  
INSERTED.RATE,  
INSERTED.PLOT,  
INSERTED.COD_TRAN,  
INSERTED.AMOUNT,  
INSERTED.QTY_DAYS_ANTECIP  
INTO @OUTPUT_TITTLE    
 SELECT    
  CONCAT(NEXT VALUE FOR SEQ_TRANSACTION_TITLE, MERCHANT)    
    ,@COD_TRAN    
    ,@CONT    
    ,(AMOUNT / @QTY_PLOT)    
    ,@CODASS_EQUIP    
    ,MDR    
    ,RATE    
    ,IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY),    
  IIF(@PLANDZEROTODAY = 1, DATEADD(HOUR, @PlanDZeroHour, @PAYDAY), @TOMORROW_MORNING))    
    ,4    
    ,@TX_ACQ    
    ,INTERVAL    
    ,@PREVISION_RECEIVEDATE    
    ,4    
    ,1    
    ,IIF((PLANDZERO_MDR IS NOT NULL AND @TYPE_TRAN != 1) OR    
  CAST(@PREVISION_RECEIVEDATE AS DATE) <= DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY), 0, ANTICIP)    
    ,MERCHANT    
    ,COD_TX_MERCHANT    
    ,((@CONT * 30) - DATEDIFF(DAY, CAST(@TRAN_DATE AS DATE),    
  IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, (INTERVAL * @CONT), @PAYDAY),    
  IIF(@PLANDZEROTODAY = 1, @PAYDAY, @TOMORROW_MORNING))))    
    ,COD_SPLIT_PROD    
    ,PLANDZERO_MDR    
 FROM #EC    
 WHERE COD_T_PLAN = 1    
    
IF @@rowcount < (SELECT    
   COUNT(*)    
  FROM #EC    
  WHERE COD_T_PLAN = 1)    
THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;    
    
-- ********** INSERT ON UNITS RECEIVABLE DATA  
    
    
INSERT INTO ASS_UR_TITTLE (COD_TITLE,    
COD_UR,    
PREVISION_PAYMENT_DATE,    
COD_SOURCE_TRAN,    
COD_EC,    
COD_SITUATION)    
 SELECT    
  OUTP.COD_TITTLE    
    ,RECEIVABLE_UNITS.COD_UR    
    ,OUTP.PREVISION_PAYMENT    
    ,@SOURCE_TRAN    
    ,OUTP.COD_EC    
    ,4    
 FROM RECEIVABLE_UNITS    
 JOIN TYPE_ARR_SLC    
  ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR    
 JOIN ACQUIRER    
  ON ACQUIRER.COD_AC = @COD_AC    
 JOIN ACQUIRER_GROUP    
  ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP    
 JOIN BRAND    
  ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND    
 JOIN @OUTPUT_TITTLE OUTP    
  ON OUTP.COD_AC = ACQUIRER.COD_AC    
   AND OUTP.COD_BRAND = BRAND.COD_BRAND    
 LEFT JOIN ASS_UR_TITTLE    
  ON ASS_UR_TITTLE.COD_TITLE = OUTP.COD_TITTLE    
 WHERE TYPE_ARR_SLC.COD_TTYPE = OUTP.COD_TTYPE    
 AND TYPE_ARR_SLC.ANTICIP =    
 (    
 CASE    
  WHEN OUTP.ANTECIP > 0 AND    
   OUTP.COD_TTYPE = 1 THEN 1    
  ELSE 0    
 END    
 )    
 AND RECEIVABLE_UNITS.COD_BRAND = OUTP.COD_BRAND    
 AND RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP    
 AND ASS_UR_TITTLE.COD_TITLE IS NULL    
    
---- END  
  
--- ************** INSERT INTO WEBHOOK QUEUE ************  
  
INSERT INTO TRANSACTION_TITTLE_QUEUE  
(  
COD_TITLE  
,COD_TRAN  
,NSU  
,COD_EC  
,EC_NAME  
,COD_PLAN  
,PLAN_NAME  
,AMOUNT  
,NET_AMOUNT  
,PLOT  
,SITUATION  
,MDR  
,ANTICIP  
,RATE  
,PREVISION_PAYMENT  
,COD_AFFILIATOR  
)  
SELECT   
OUP.COD_TITTLE,  
OUP.COD_TRAN,  
@NSU,  
OUP.COD_EC,  
COMMERCIAL_ESTABLISHMENT.[NAME],  
[PLAN].COD_PLAN,  
[PLAN].[CODE],  
OUP.AMOUNT,  
 CAST((((OUP.AMOUNT * (1 - (OUP.MDR / 100))) *    
  IIF(OUP.ANTECIP IS NULL, 1,    
  1 - (((OUP.ANTECIP / 30) * COALESCE(OUP.QTY_DAYS,    
  (OUP.[PLOT] * 30) - 1)) /    
  100))) - (IIF(OUP.PLOT = 1, OUP.[RATE], 0))) AS DECIMAL(22, 6)) ,  
OUP.PLOT,  
'AGUARDANDO PAGAMENTO',  
OUP.MDR,  
OUP.ANTECIP,  
OUP.RATE,  
OUP.PREVISION_PAYMENT,  
@AFF_SOURCE_COD  
 FROM @OUTPUT_TITTLE OUP  
 JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = OUP.COD_EC  
 JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_ASS_TX_DEP = OUP.COD_ASS_PLAN  
 JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN  
  
 -------********** END WEBHOOK QUEUE  
    
    
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
OUTPUT   
INSERTED.COD_TITLE,   
@COD_BRAND,   
@TYPE_TRAN,   
@COD_AC,   
INSERTED.ANTICIP_PERCENT,   
INSERTED.COD_EC,   
INSERTED.PREVISION_PAY_DATE,  
INSERTED.TAX_INITIAL,  
INSERTED.COD_ASS_TX_DEP,  
INSERTED.RATE,  
INSERTED.PLOT,  
INSERTED.COD_TRAN,  
INSERTED.AMOUNT,  
INSERTED.QTY_DAYS_ANTECIP  
INTO @OUTPUT_TITTLE    
    
 SELECT    
  CONCAT(NEXT VALUE FOR SEQ_TRANSACTION_TITLE, MERCHANT)    
    ,@COD_TRAN    
    ,@CONT    
    ,(AMOUNT / @QTY_PLOT)    
    ,@CODASS_EQUIP    
    ,MDR    
    ,RATE    
    ,IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, INTERVAL, @PAYDAY),    
  IIF(@PLANDZEROTODAY = 1, DATEADD(HOUR, @PlanDZeroHour, @PAYDAY), @TOMORROW_MORNING))    
    ,4    
    ,@TX_ACQ    
    ,INTERVAL    
    ,@PREVISION_RECEIVEDATE    
    ,4    
    ,1    
    ,IIF((PLANDZERO_MDR IS NOT NULL AND @TYPE_TRAN != 1) OR    
  CAST(@PREVISION_RECEIVEDATE AS DATE) <= IIF(PLANDZERO_MDR IS NULL,    
  DATEADD(DAY, INTERVAL, @PAYDAY), @TRAN_DATE), 0,    
  ANTICIP)    
    ,MERCHANT    
    ,COD_TX_MERCHANT    
    ,((@CONT * 30) - DATEDIFF(DAY, CAST(@TRAN_DATE AS DATE),    
  IIF(PLANDZERO_MDR IS NULL, DATEADD(DAY, INTERVAL, @PAYDAY),    
  IIF(@PLANDZEROTODAY = 1, @PAYDAY, @TOMORROW_MORNING))))    
    ,COD_SPLIT_PROD    
    ,PLANDZERO_MDR    
 FROM #EC    
 WHERE COD_T_PLAN = 2    
    
IF @@rowcount < (SELECT    
   COUNT(*)    
  FROM #EC    
  WHERE COD_T_PLAN = 2)    
THROW 60001, 'COULD NOT REGISTER [TRANSACTION_TITLES] ', 1;    
  
-- ********** INSERT ON UNITS RECEIVABLE DATA  
    
INSERT INTO ASS_UR_TITTLE (COD_TITLE,    
COD_UR,    
PREVISION_PAYMENT_DATE,    
COD_SOURCE_TRAN,    
COD_EC,    
COD_SITUATION)    
 SELECT    
  OUTP.COD_TITTLE    
    ,RECEIVABLE_UNITS.COD_UR    
    ,OUTP.PREVISION_PAYMENT    
    ,@SOURCE_TRAN    
    ,OUTP.COD_EC    
    ,4    
 FROM RECEIVABLE_UNITS    
 JOIN TYPE_ARR_SLC    
  ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR    
 JOIN ACQUIRER    
  ON ACQUIRER.COD_AC = @COD_AC    
 JOIN ACQUIRER_GROUP    
  ON ACQUIRER_GROUP.COD_AC_GP = ACQUIRER.COD_AC_GP    
 JOIN BRAND    
  ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND    
 JOIN @OUTPUT_TITTLE OUTP    
  ON OUTP.COD_AC = ACQUIRER.COD_AC    
   AND OUTP.COD_BRAND = BRAND.COD_BRAND    
 LEFT JOIN ASS_UR_TITTLE    
  ON ASS_UR_TITTLE.COD_TITLE = OUTP.COD_TITTLE    
 WHERE TYPE_ARR_SLC.COD_TTYPE = OUTP.COD_TTYPE    
 AND TYPE_ARR_SLC.ANTICIP =    
 (    
 CASE    
  WHEN OUTP.ANTECIP > 0 AND    
   OUTP.COD_TTYPE = 1 THEN 1    
  ELSE 0    
 END    
 )    
 AND RECEIVABLE_UNITS.COD_BRAND = OUTP.COD_BRAND    
 AND RECEIVABLE_UNITS.COD_AC_GP = ACQUIRER.COD_AC_GP    
 AND ASS_UR_TITTLE.COD_TITLE IS NULL    
  
 --******* END  
  
 --- ************** INSERT INTO WEBHOOK QUEUE ************  
  
INSERT INTO TRANSACTION_TITTLE_QUEUE  
(  
COD_TITLE  
,COD_TRAN  
,NSU  
,COD_EC  
,EC_NAME  
,COD_PLAN  
,PLAN_NAME  
,AMOUNT  
,NET_AMOUNT  
,PLOT  
,SITUATION  
,MDR  
,ANTICIP  
,RATE  
,PREVISION_PAYMENT  
,COD_AFFILIATOR  
)  
SELECT   
OUP.COD_TITTLE,  
OUP.COD_TRAN,  
@NSU,  
OUP.COD_EC,  
COMMERCIAL_ESTABLISHMENT.[NAME],  
[PLAN].COD_PLAN,  
[PLAN].[CODE],  
OUP.AMOUNT,  
 CAST((((OUP.AMOUNT * (1 - (OUP.MDR / 100))) *    
  IIF(OUP.ANTECIP IS NULL, 1,    
  1 - (((OUP.ANTECIP / 30) * COALESCE(OUP.QTY_DAYS,    
  (OUP.[PLOT] * 30) - 1)) /    
  100))) - (IIF(OUP.PLOT = 1, OUP.[RATE], 0))) AS DECIMAL(22, 6)) ,  
OUP.PLOT,  
'AGUARDANDO PAGAMENTO',  
OUP.MDR,  
OUP.ANTECIP,  
OUP.RATE,  
OUP.PREVISION_PAYMENT,  
@AFF_SOURCE_COD  
 FROM @OUTPUT_TITTLE OUP  
 JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = OUP.COD_EC  
 JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_ASS_TX_DEP = OUP.COD_ASS_PLAN  
 JOIN [PLAN] ON [PLAN].COD_PLAN = ASS_TAX_DEPART.COD_PLAN  
  
 -------********** END WEBHOOK QUEUE  
    
  
  
    
DELETE FROM @OUTPUT_TITTLE;    
    
    
SET @CONT = @CONT + 1;    
            
        END;    
    
IF @AFF_SOURCE_COD IS NOT NULL    
BEGIN    
SELECT    
 AFF.[COD_AFFILIATOR]    
   ,AFF.COD_TRAN    
   ,COD_TITLE    
   ,[TRANSACTION_TITLES].PREVISION_PAY_DATE    
   ,AFF.[COD_OPER_COST_AFF]    
   ,AFF.[PERCENTAGE_COST]    
   ,AFF.[COD_PLAN_TAX_AFF]    
   ,AFF.[PERCENTAGE]    
   ,AFF.[RATE]    
   ,IIF(SA.COD_ITEM_SERVICE IS NOT NULL OR [TRANSACTION_TITLES].ANTICIP_PERCENT = 0, 0,    
 AFF.[ANTICIPATION_PERCENTAGE]) AS ANTICIP_PERCENT    
   ,IIF(SA.COD_SERVICE IS NULL, NULL, CAST(JSON_VALUE(SA.CONFIG_JSON,    
 IIF(@TYPE_TRAN = 1, '$.credit', '$.debit')) AS DECIMAL(22, 6))) [PLANDZERO_MDR] INTO #COST    
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
 SELECT    
  COD_AFFILIATOR    
    ,COD_TITLE    
    ,[COD_OPER_COST_AFF]    
    ,[PERCENTAGE_COST]    
    ,[PERCENTAGE]    
    ,PREVISION_PAY_DATE    
    ,4    
    ,[RATE]    
    ,ANTICIP_PERCENT    
    ,PLANDZERO_MDR    
 FROM #COST    
END;    
    
IF (SELECT    
   COUNT(*)    
  FROM #EC    
  WHERE COD_T_PLAN = 2    
  AND PLANDZERO_MDR IS NOT NULL)    
 > 0    
BEGIN    
    
INSERT INTO TRANSACTION_SERVICES (CREATED_AT, COD_ITEM_SERVICE, COD_TRAN, TAX_PLANDZERO_EC,    
TAX_PLANDZERO_AFF, COD_EC)    
 SELECT DISTINCT    
  current_timestamp    
    ,@COD_PLANDZERO_SERVICE    
    ,@COD_TRAN    
    ,e.PLANDZERO_MDR    
    ,IIF(e.PLANDZERO_MDR = 0 OR e.PLANDZERO_MDR IS NULL, NULL, (SELECT TOP 1    
    c.PLANDZERO_MDR    
   FROM #COST c    
   WHERE c.COD_AFFILIATOR = e.AFFILIATOR)    
  )    
    ,e.MERCHANT    
 FROM #EC e    
 WHERE COD_T_PLAN = 2    
 AND e.PLANDZERO_MDR IS NOT NULL    
END;    
    
EXEC [SP_VAL_LIMIT_EC] @CODETR = @NSU;    
    
UPDATE PROCESS_BG_STATUS    
SET STATUS_PROCESSED = 0    
WHERE CODE = @COD_TRAN    
    
END;

--ST-1969

GO

IF OBJECT_ID('SP_FD_EC_PLAN_WEBHOOK') IS NOT NULL DROP PROCEDURE SP_FD_EC_PLAN_WEBHOOK;
GO
CREATE PROCEDURE SP_FD_EC_PLAN_WEBHOOK(
@COD_AFF INT
) AS
BEGIN

 

SELECT COD_EC INTO #TMP FROM PLAN_EC_QUEUE WHERE COD_AFFILIATOR = @COD_AFF AND ACTIVE = 1 AND SENDED = 0;

 

with PLANS AS (
SELECT COMMERCIAL_ESTABLISHMENT.COD_EC
, [PLAN].COD_PLAN
, [PLAN].CODE AS [NAME_PLAN]
, [PLAN].[DESCRIPTION]
, PLAN_CATEGORY.CATEGORY
, TYPE_PLAN.CODE AS TYPE_PLAN
, BRAND.[GROUP] AS BRAND_GROUP
, TRANSACTION_TYPE.CODE AS TRANSACTION_TYPE
, ASS_TAX_DEPART.QTY_INI_PLOTS
, ASS_TAX_DEPART.QTY_FINAL_PLOTS
, IIF((SOURCE_TRANSACTION.COD_SOURCE_TRAN = 1), 'SITE', EQUIPMENT_MODEL.CODIGO) AS EQUIPMENT_MODEL
, ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE

 

, (select INTERVAL
from ASS_TAX_DEPART
where ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
and ASS_TAX_DEPART.QTY_INI_PLOTS = 1
AND ASS_TAX_DEPART.QTY_FINAL_PLOTS = 1
AND ASS_TAX_DEPART.COD_TTYPE = 2
AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 2
AND ASS_TAX_DEPART.ACTIVE = 1
group by INTERVAL) AS [INTERVAL_DEBIT]

 

, (select INTERVAL
from ASS_TAX_DEPART
where ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
and ASS_TAX_DEPART.QTY_INI_PLOTS = 1
AND ASS_TAX_DEPART.QTY_FINAL_PLOTS = 1
AND ASS_TAX_DEPART.COD_TTYPE = 1
AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 2
AND ASS_TAX_DEPART.ACTIVE = 1
group by INTERVAL) AS [INTERVAL_CREDIT_A_VISTA]

 

, (select INTERVAL
from ASS_TAX_DEPART
where ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
and ASS_TAX_DEPART.QTY_INI_PLOTS >= 1
AND ASS_TAX_DEPART.QTY_FINAL_PLOTS > 1
AND ASS_TAX_DEPART.COD_TTYPE = 1
AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 2
AND ASS_TAX_DEPART.ACTIVE = 1
group by INTERVAL) AS [INTERVAL_CREDIT_PARCELADO]

 

, (select INTERVAL
from ASS_TAX_DEPART
where ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 1
AND ASS_TAX_DEPART.ACTIVE = 1
group by INTERVAL) AS [INTERVAL_ONLINE]

 

, PARCENTAGE
, RATE
, IIF(ASS_TAX_DEPART.COD_MODEL IS NOT NULL, 'TERMINAL_PLAN', NULL) AS PLAN_OPTION
, USERS.COD_ACCESS AS USER_IDENTIFICATION
, PLAN_EC_QUEUE.CODE as MODIFY_IDENTIFICATION
, PLAN_EC_QUEUE.CREATED_AT AS MODIFY_DATE
, PLAN_EC_QUEUE.SENDED
FROM [PLAN]
JOIN ASS_TAX_DEPART
ON ASS_TAX_DEPART.COD_PLAN = [PLAN].COD_PLAN
JOIN PLAN_EC_QUEUE ON ASS_TAX_DEPART.COD_PLAN_EC_QUEUE = PLAN_EC_QUEUE.COD_PLAN_EC_QUEUE
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
LEFT JOIN USERS
ON USERS.COD_USER = ASS_TAX_DEPART.COD_USER
WHERE COMMERCIAL_ESTABLISHMENT.COD_EC IN (SELECT COD_EC FROM #TMP)
and ASS_TAX_DEPART.ACTIVE = 1
and PLAN_EC_QUEUE.SENDED = 0
and PLAN_EC_QUEUE.ACTIVE = 1
)
SELECT PLANS.COD_EC
, PLANS.COD_PLAN
, PLANS.[NAME_PLAN]
, PLANS.[DESCRIPTION]
, PLANS.CATEGORY
, PLANS.TYPE_PLAN
, PLANS.BRAND_GROUP
, PLANS.TRANSACTION_TYPE
, PLANS.QTY_INI_PLOTS
, PLANS.QTY_FINAL_PLOTS
, SUM(PLANS.ANTICIPATION_PERCENTAGE) AS ANTICIPATION_PERCENTAGE
, SUM(INTERVAL_DEBIT) AS INTERVAL_DEBIT
, SUM(INTERVAL_CREDIT_A_VISTA) AS INTERVAL_CREDIT_A_VISTA
, SUM(INTERVAL_CREDIT_PARCELADO) AS INTERVAL_CREDIT_PARCELADO
, SUM(INTERVAL_ONLINE) AS INTERVAL_ONLINE
, SUM(PLANS.PARCENTAGE) AS PARCENTAGE
, SUM(PLANS.RATE) AS RATE
, PLANS.PLAN_OPTION AS PLAN_OPTION
, PLANS.EQUIPMENT_MODEL
, USER_IDENTIFICATION
, PLANS.MODIFY_IDENTIFICATION
, PLANS.MODIFY_DATE
, PLANS.SENDED
FROM PLANS
GROUP BY PLANS.COD_PLAN
, PLANS.[NAME_PLAN]
, PLANS.[DESCRIPTION]
, PLANS.CATEGORY
, PLANS.TYPE_PLAN
, PLANS.BRAND_GROUP
, PLANS.TRANSACTION_TYPE
, PLANS.QTY_INI_PLOTS
, PLANS.QTY_FINAL_PLOTS
, PLANS.PLAN_OPTION
, PLANS.EQUIPMENT_MODEL
, USER_IDENTIFICATION, PLANS.MODIFY_IDENTIFICATION, PLANS.MODIFY_DATE, PLANS.SENDED, PLANS.COD_EC

 

END
go
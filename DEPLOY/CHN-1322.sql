--SAP

alter PROCEDURE SP_LIST_PARTNER_EXTERNAL(@COD_EXT INT,
                                         @COD_AFF INT = NULL,
                                         @ECS CODE_TYPE READONLY)
AS
BEGIN

    INSERT INTO EXTERNAL_PARTN_UP (COD_EXT_CLI, UPDATED, COD_EC, COD_EXTERNAL)
    SELECT 1
         , 0
         , CE.COD_EC
         , NULL
    FROM COMMERCIAL_ESTABLISHMENT CE
             LEFT JOIN EXTERNAL_PARTN_UP EPU
                       ON CE.COD_EC = EPU.COD_EC
    WHERE EPU.COD_EXTERNAL_PART IS NULL

    SELECT *
    FROM (SELECT COMMERCIAL_ESTABLISHMENT.COD_EC                                                               [COD_PTN]
               , COMMERCIAL_ESTABLISHMENT.[NAME]                                                               [CardName]
               , COMMERCIAL_ESTABLISHMENT.TRADING_NAME                                                         [ForeignName]
               , 'A'                                                                                           [Type]
               , COMMERCIAL_ESTABLISHMENT.EMAIL                                                                [MailAddress]
               , COALESCE(contact.[NUMBER], cellphone.[NUMBER])                                                [NUMBER]
               , COALESCE(contact.[DDD], cellphone.[DDD])                                                      [DDD]
               , COALESCE(contact.[COD_CONT], cellphone.COD_CONT)                                              [COD_CONT]
               , (cellphone.DDD + cellphone.NUMBER)                                                            [Cellphone]
               , 'BR'                                                                                          [BankCountry]
               , BANKS.CODE                                                                                    [BankCode]
               , BANK_DETAILS_EC.ACCOUNT
               , BANK_DETAILS_EC.DIGIT_ACCOUNT
               , BANK_DETAILS_EC.AGENCY
               , BANK_DETAILS_EC.DIGIT_AGENCY
               , ACCOUNT_TYPE.[NAME]                                                                           [ACCOUNT_TYPE]
               , OPERATION.CODE                                                                                [OPERATION]
               , EXTERNAL_PARTN_UP.COD_EXTERNAL                                                                OldCode
               , '*'                                                                                           [ADDRESS_NAME]
               , CASE
                     WHEN dbo.FN_EXTRACT_PUBLIC_PLACE(dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_BRANCH.[ADDRESS]))) LIKE '#'
                         THEN dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_BRANCH.[ADDRESS]))
                     ELSE REPLACE(REPLACE(dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_BRANCH.[ADDRESS]))
                                      , dbo.FN_EXTRACT_PUBLIC_PLACE(
                                                  dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_BRANCH.[ADDRESS])))
                                      , ''), '  ', ' ')
            END      AS                                                                                        [Street]
               , ADDRESS_BRANCH.NUMBER                                                                         [ADDRESS_NUMBER]
               , NEIGHBORHOOD.[NAME]                                                                           Neighborhood
               , ADDRESS_BRANCH.CEP
               , dbo.FN_EXTRACT_PUBLIC_PLACE(dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_BRANCH.[ADDRESS])))         [TYPE_ADDRESS]
               , CITY.[NAME]                                                                                   [CITY]
               , [STATE].UF                                                                                    [STATE]
               , COUNTRY.INITIALS                                                                              [COUNTRY]
               , ADDRESS_BRANCH.COMPLEMENT
               , (IIF(LEN(COMMERCIAL_ESTABLISHMENT.CPF_CNPJ) = 11, NULL, COMMERCIAL_ESTABLISHMENT.CPF_CNPJ))   [CNPJ]
               , CASE
                     WHEN COMMERCIAL_ESTABLISHMENT.STATE_REGISTRATION IS NOT NULL AND
                          COMMERCIAL_ESTABLISHMENT.STATE_REGISTRATION <> 'ISENTO'
                         THEN COMMERCIAL_ESTABLISHMENT.STATE_REGISTRATION
                     ELSE 'Isento'
            END      AS                                                                                        STATE_REGISTRATION
               , CASE
                     WHEN COMMERCIAL_ESTABLISHMENT.MUNICIPAL_REGISTRATION IS NOT NULL AND
                          COMMERCIAL_ESTABLISHMENT.MUNICIPAL_REGISTRATION <> 'ISENTO'
                         THEN COMMERCIAL_ESTABLISHMENT.MUNICIPAL_REGISTRATION
                     ELSE NULL
            END      AS                                                                                        MUNICIPAL_REGISTRATION
               , (IIF(LEN(COMMERCIAL_ESTABLISHMENT.CPF_CNPJ) = 11, COMMERCIAL_ESTABLISHMENT.CPF_CNPJ, NULL))   [CPF]
               , isnull((select top 1 CNAE from SEGMENTS s where SEGMENTS.CODE = s.CODE and s.CNAE is not null), '0')           [CNAE]
               , COMMERCIAL_ESTABLISHMENT.BIRTHDATE
               , ROW_NUMBER()
                OVER (PARTITION BY COMMERCIAL_ESTABLISHMENT.CPF_CNPJ ORDER BY COMMERCIAL_ESTABLISHMENT.COD_EC) [ROW_ID]
               , CASE
                     WHEN COMMERCIAL_ESTABLISHMENT.STATE_REGISTRATION IS NOT NULL AND
                          COMMERCIAL_ESTABLISHMENT.STATE_REGISTRATION <> 'ISENTO' THEN '1'
                     ELSE '2'
            END      AS                                                                                        CONTRIBUITOR
               , CASE
                     WHEN COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB = 1 THEN '3'
                     ELSE '1'
            END      AS                                                                                        SIMPLE_TAXATION
               , '1' AS                                                                                        CONSUMER_OPERATION
          FROM COMMERCIAL_ESTABLISHMENT
                   JOIN BRANCH_EC
                        ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                            AND BRANCH_EC.ACTIVE = 1
                   JOIN CONTACT_BRANCH cellphone
                        ON cellphone.COD_BRANCH = BRANCH_EC.COD_BRANCH
                            AND cellphone.ACTIVE = 1
                            AND (SELECT COUNT(*)
                                 FROM TYPE_CONTACT tp
                                 WHERE tp.COD_TP_CONT = cellphone.COD_TP_CONT
                                   AND tp.[NAME] = 'CELULAR')
                               > 0
                   JOIN BANK_DETAILS_EC
                        ON BANK_DETAILS_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                            AND BANK_DETAILS_EC.ACTIVE = 1
                            AND BANK_DETAILS_EC.IS_CERC = 0
                   JOIN BANKS
                        ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK
                   JOIN ACCOUNT_TYPE
                        ON ACCOUNT_TYPE.COD_TYPE_ACCOUNT = BANK_DETAILS_EC.COD_TYPE_ACCOUNT
                   JOIN ADDRESS_BRANCH
                        ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
                            AND ADDRESS_BRANCH.ACTIVE = 1
                   JOIN NEIGHBORHOOD
                        ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
                   JOIN CITY
                        ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
                   JOIN [STATE] ON [STATE].COD_STATE = CITY.COD_STATE
                   JOIN [COUNTRY] ON COUNTRY.COD_COUNTRY = [STATE].COD_COUNTRY
                   JOIN EXTERNAL_PARTN_UP
                        ON EXTERNAL_PARTN_UP.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                            AND EXTERNAL_PARTN_UP.COD_EXT_CLI = @COD_EXT
                            AND EXTERNAL_PARTN_UP.UPDATED = 0
                   LEFT JOIN OPERATION_BANK
                             ON OPERATION_BANK.COD_OPER_BANK = BANK_DETAILS_EC.COD_OPER_BANK
                   LEFT JOIN OPERATION
                             ON OPERATION.COD_OPER = OPERATION_BANK.COD_OPER
                   LEFT JOIN CONTACT_BRANCH contact
                             ON contact.COD_BRANCH = BRANCH_EC.COD_BRANCH
                                 AND contact.ACTIVE = 1
                                 AND (SELECT COUNT(*)
                                      FROM TYPE_CONTACT tp
                                      WHERE tp.COD_TP_CONT = contact.COD_TP_CONT
                                        AND tp.[NAME] = 'COMERCIAL')
                                    > 0
                   JOIN SEGMENTS
                        ON COMMERCIAL_ESTABLISHMENT.COD_SEG = SEGMENTS.COD_SEG
          WHERE COMMERCIAL_ESTABLISHMENT.ACTIVE = 1
            AND (((SELECT COUNT(*) FROM @ECS) <= 0) OR COMMERCIAL_ESTABLISHMENT.COD_EC IN (SELECT CODE FROM @ECS))
            AND (@COD_AFF IS NULL
              OR COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFF)) PN
    WHERE PN.ROW_ID = 1

    UPDATE EXTERNAL_PARTN_UP
    SET UPDATED = 0
    WHERE COD_EXTERNAL LIKE 'C%'
      AND (COD_AFFILIATOR IS NOT NULL
        OR COD_EC IS NOT NULL)

END
go

ALTER PROCEDURE SP_LIST_PARTNER_EXTERNAL_AFF(
    @COD_EXT INT,
    @AFFS CODE_TYPE READONLY
)
AS
BEGIN

    INSERT INTO EXTERNAL_PARTN_UP (COD_EXT_CLI, UPDATED, COD_AFFILIATOR, COD_EXTERNAL)
    SELECT @COD_EXT
         , 0
         , AFFILIATOR.COD_AFFILIATOR
         , NULL
    FROM AFFILIATOR
             LEFT JOIN EXTERNAL_PARTN_UP
                       ON AFFILIATOR.COD_AFFILIATOR = EXTERNAL_PARTN_UP.COD_AFFILIATOR
                           AND COD_EC IS NULL
    WHERE ACTIVE = 1
      AND EXTERNAL_PARTN_UP.COD_EXTERNAL_PART IS NULL

    SELECT AFFILIATOR.COD_AFFILIATOR                                                                 [COD_PTN]
         , AFFILIATOR.[NAME]                                                                         [CardName]
         , AFFILIATOR.[NAME]                                                                         [ForeignName]
         , 'A'                                                                                       [Type]
         , ''                                                                                        [MailAddress]
         , COALESCE(contact.[NUMBER], cellphone.[NUMBER])                                            [NUMBER]
         , COALESCE(contact.[DDD], cellphone.[DDD])                                                  [DDD]
         , COALESCE(contact.COD_CONTACT_AFL, cellphone.COD_CONTACT_AFL)                              [COD_CONT]
         , (cellphone.DDD + cellphone.NUMBER)                                                        [Cellphone]
         , 'BR'                                                                                      [BankCountry]
         , BANKS.CODE                                                                                [BankCode]
         , BANK_DETAILS_EC.ACCOUNT
         , BANK_DETAILS_EC.DIGIT_ACCOUNT
         , BANK_DETAILS_EC.AGENCY
         , BANK_DETAILS_EC.DIGIT_AGENCY
         , ACCOUNT_TYPE.[NAME]                                                                       [ACCOUNT_TYPE]
         , OPERATION.CODE                                                                            [OPERATION]
         , EXTERNAL_PARTN_UP.COD_EXTERNAL                                                            OldCode
         , '*'                                                                                       [ADDRESS_NAME]
         , CASE
               WHEN dbo.FN_EXTRACT_PUBLIC_PLACE(dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_AFFILIATOR.[ADDRESS]))) LIKE '#'
                   THEN dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_AFFILIATOR.[ADDRESS]))
               ELSE REPLACE(REPLACE(dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_AFFILIATOR.[ADDRESS]))
                                , dbo.FN_EXTRACT_PUBLIC_PLACE(
                                            dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_AFFILIATOR.[ADDRESS])))
                                , ''), '  ', ' ')
        END    AS                                                                                    [Street]
         , ADDRESS_AFFILIATOR.NUMBER                                                                 [ADDRESS_NUMBER]
         , NEIGHBORHOOD.[NAME]                                                                       Neighborhood
         , ADDRESS_AFFILIATOR.CEP
         , dbo.FN_EXTRACT_PUBLIC_PLACE(dbo.FNC_REMOV_CARAC_ESP(LTRIM(ADDRESS_AFFILIATOR.[ADDRESS]))) [TYPE_ADDRESS]
         , CITY.[NAME]                                                                               [CITY]
         , [STATE].UF                                                                                [STATE]
         , COUNTRY.INITIALS                                                                          [COUNTRY]
         , ADDRESS_AFFILIATOR.COMPLEMENT
         , (IIF(LEN(AFFILIATOR.CPF_CNPJ) = 11, NULL, AFFILIATOR.CPF_CNPJ))                           [CNPJ]
         , CASE
               WHEN AFFILIATOR.STATE_REGISTRATION IS NOT NULL AND
                    AFFILIATOR.STATE_REGISTRATION <> 'ISENTO' THEN AFFILIATOR.STATE_REGISTRATION
               ELSE 'Isento'
        END    AS                                                                                    STATE_REGISTRATION
         , CASE
               WHEN AFFILIATOR.MUNICIPAL_REGISTRATION IS NOT NULL AND
                    AFFILIATOR.MUNICIPAL_REGISTRATION <> 'ISENTO' THEN AFFILIATOR.MUNICIPAL_REGISTRATION
               ELSE NULL
        END    AS                                                                                    MUNICIPAL_REGISTRATION
         , (IIF(LEN(AFFILIATOR.CPF_CNPJ) = 11, AFFILIATOR.CPF_CNPJ, NULL))                           [CPF]
         , '7319002'                                                                                 [CNAE]
         , AFFILIATOR.CREATED_AT                                                                     BIRTHDATE
         , CASE
               WHEN AFFILIATOR.STATE_REGISTRATION IS NOT NULL AND
                    AFFILIATOR.STATE_REGISTRATION <> 'ISENTO' THEN '1'
               ELSE '2'
        END    AS                                                                                    CONTRIBUITOR
         , '2' AS                                                                                    SIMPLE_TAXATION
         , '1' AS                                                                                    CONSUMER_OPERATION
    FROM AFFILIATOR
             JOIN AFFILIATOR_CONTACT cellphone
                  ON cellphone.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
                      AND cellphone.ACTIVE = 1
                      AND (SELECT COUNT(*)
                           FROM TYPE_CONTACT tp
                           WHERE tp.COD_TP_CONT = cellphone.COD_TP_CONT
                             AND tp.[NAME] = 'CELULAR')
                         > 0
             JOIN BANK_DETAILS_EC
                  ON BANK_DETAILS_EC.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
                      AND BANK_DETAILS_EC.COD_EC IS NULL
                      AND BANK_DETAILS_EC.ACTIVE = 1
                      AND BANK_DETAILS_EC.IS_CERC = 0
             JOIN BANKS
                  ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK
             JOIN ACCOUNT_TYPE
                  ON ACCOUNT_TYPE.COD_TYPE_ACCOUNT = BANK_DETAILS_EC.COD_TYPE_ACCOUNT
             JOIN ADDRESS_AFFILIATOR
                  ON ADDRESS_AFFILIATOR.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
                      AND ADDRESS_AFFILIATOR.ACTIVE = 1
             JOIN NEIGHBORHOOD
                  ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_AFFILIATOR.COD_NEIGH
             JOIN CITY
                  ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
             JOIN [STATE] ON [STATE].COD_STATE = CITY.COD_STATE
             JOIN [COUNTRY] ON COUNTRY.COD_COUNTRY = [STATE].COD_COUNTRY
             JOIN EXTERNAL_PARTN_UP
                  ON EXTERNAL_PARTN_UP.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
                      AND EXTERNAL_PARTN_UP.COD_EXT_CLI = @COD_EXT
             LEFT JOIN OPERATION_BANK
                       ON OPERATION_BANK.COD_OPER_BANK = BANK_DETAILS_EC.COD_OPER_BANK
             LEFT JOIN OPERATION
                       ON OPERATION.COD_OPER = OPERATION_BANK.COD_OPER
             LEFT JOIN AFFILIATOR_CONTACT contact
                       ON contact.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
                           AND contact.ACTIVE = 1
                           AND (SELECT COUNT(*)
                                FROM TYPE_CONTACT tp
                                WHERE tp.COD_TP_CONT = contact.COD_TP_CONT
                                  AND tp.[NAME] = 'COMERCIAL')
                              > 0
             LEFT JOIN COMMERCIAL_ESTABLISHMENT
                       ON COMMERCIAL_ESTABLISHMENT.CPF_CNPJ = AFFILIATOR.CPF_CNPJ
                           AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1
    WHERE AFFILIATOR.ACTIVE = 1 AND (((SELECT COUNT(*) FROM @AFFS) <= 0) OR AFFILIATOR.COD_AFFILIATOR IN (SELECT CODE FROM @AFFS))
      AND EXTERNAL_PARTN_UP.UPDATED = 0
      AND COMMERCIAL_ESTABLISHMENT.CPF_CNPJ IS NULL
END
go
ALTER PROCEDURE SP_UP_EXTERNAL_PAYMENTS
/*----------------------------------------------------------------------------------------          
   Project.......: TKPP          
------------------------------------------------------------------------------------------          
   Author             VERSION     Date            Description          
------------------------------------------------------------------------------------------          
   Luiz Aquino        V1          2020-07-13      CREATED    
   Lucas Aguiar       v2          2020-11-18      Agenda v2
------------------------------------------------------------------------------------------*/
AS
BEGIN

    DECLARE @Default_SAP_CODE VARCHAR(64)

    SELECT TOP 1 @Default_SAP_CODE = SAP_CODE
    FROM ASSOCIATE_GENERATE_CNAB
    WHERE SAP_CODE IS NOT NULL

    SELECT FC.PAYMENT_DATE
         , ARR.PLOT_VALUE_PAYMENT                                         AMOUNT
         , E.COD_EXTERNAL                                                 [PN_CODE]
         , 0                                                              ORIGIN_BANK
         , P.PROTOCOL                                                     FILE_SEQUENCE
         , E.COD_EC
         , ARR.COD_PAY_PROT
         , IIF(AGC.SAP_CODE IS NOT NULL, AGC.SAP_CODE, @Default_SAP_CODE) [SAP_CODE]
    INTO #toGroup
    FROM FINANCE_CALENDAR FC
             JOIN ARRANG_TO_PAY ARR ON FC.COD_FIN_CALENDAR = ARR.COD_FIN_CALENDAR
             JOIN EXTERNAL_PARTN_UP E
                  ON E.COD_EC = FC.COD_EC
                      AND E.COD_EXTERNAL IS NOT NULL
             JOIN PROTOCOLS P
                  ON ARR.COD_PAY_PROT = P.COD_PAY_PROT
             LEFT JOIN ASSOCIATE_GENERATE_CNAB AGC
                       ON AGC.COD_ASS_CNAB = P.COD_ASS_CNAB
    WHERE FC.COD_SITUATION = 8
      AND FC.ACTIVE = 1
      AND SAP_NOTIFIED = 0

    SELECT PAYMENT_DATE,
           SUM(AMOUNT) AS AMOUNT,
           PN_CODE,
           ORIGIN_BANK,
           FILE_SEQUENCE,
           SAP_CODE,
           COD_EC,
           COD_PAY_PROT
    into #Payments
    FROM #toGroup
    GROUP BY PAYMENT_DATE,
             PN_CODE,
             ORIGIN_BANK,
             FILE_SEQUENCE,
             SAP_CODE,
             COD_EC,
             COD_PAY_PROT

    UPDATE NTE
    SET NTE.AMOUNT         = P.AMOUNT
      , NTE.ORIGIN_PAYMENT = P.SAP_CODE
      , NTE.UPDATED        = 1
    FROM NOTIFY_EXT_PAY_INFO NTE
             JOIN #Payments P
                  ON NTE.PAYMENT_DATE = P.PAYMENT_DATE
                      AND NTE.COD_EC = P.COD_EC
                      AND (NTE.AMOUNT != P.AMOUNT
                          OR P.SAP_CODE != COALESCE(NTE.ORIGIN_PAYMENT, ''))

    INSERT INTO NOTIFY_EXT_PAY_INFO (PAYMENT_DATE, AMOUNT, COD_PAY_PROT, COD_EC, ORIGIN_PAYMENT, PROTOCOL)
    SELECT P.PAYMENT_DATE
         , P.AMOUNT
         , P.COD_PAY_PROT
         , P.COD_EC
         , P.SAP_CODE
         , P.FILE_SEQUENCE
    FROM #Payments P
             LEFT JOIN NOTIFY_EXT_PAY_INFO NTE
                       ON NTE.PAYMENT_DATE = P.PAYMENT_DATE
                           AND NTE.COD_EC = P.COD_EC
    WHERE NTE.COD_EXT_PAY_INFO IS NULL

    UPDATE FINANCE_CALENDAR
    SET SAP_NOTIFIED = 1
    FROM FINANCE_CALENDAR
             join ARRANG_TO_PAY on FINANCE_CALENDAR.COD_FIN_CALENDAR = ARRANG_TO_PAY.COD_FIN_CALENDAR
             JOIN #Payments P ON FINANCE_CALENDAR.COD_EC = P.COD_EC AND ARRANG_TO_PAY.COD_PAY_PROT = P.COD_PAY_PROT

END;

GO


IF NOT EXISTS (SELECT
                   1
               FROM sys.columns
               WHERE Name = N'CREATED_AT'
                 AND Object_ID = OBJECT_ID(N'OPEN_LEDGER_ESTABLISHMENT'))
    BEGIN

        ALTER TABLE OPEN_LEDGER_ESTABLISHMENT ADD CREATED_AT DATETIME;

    END

GO


IF NOT EXISTS (SELECT
                   1
               FROM sys.columns
               WHERE Name = N'ALTER_DATE'
                 AND Object_ID = OBJECT_ID(N'OPEN_LEDGER_ESTABLISHMENT'))
    BEGIN

        ALTER TABLE OPEN_LEDGER_ESTABLISHMENT ADD ALTER_DATE DATETIME;

    END

GO


IF OBJECT_ID('VW_LIST_OPEN_LEDGER_EC') IS NOT NULL
    DROP VIEW VW_LIST_OPEN_LEDGER_EC
GO
CREATE VIEW VW_LIST_OPEN_LEDGER_EC AS
/*  
EM CASO DE PAGAMENTOS EM D0, PODE ACONTECER DE TEREM PAGAMENTOS COMO CONFIRMAÇÃO  OU PAGOS NO DIA, DEPENDENDO DO HORÁRIO.  
  
DENTRO DA SITUAÇÃO DO TÍTULO, EXISTEM DOIS IFF'S QUE VALIDAM ISSO  
*/
SELECT
    title.COD_EC
     ,(YEAR([T].BRAZILIAN_DATE) * 10000 + MONTH([T].BRAZILIAN_DATE) * 100 + DAY([T].BRAZILIAN_DATE)) AS CREATED_AT
     ,(YEAR(title.PREVISION_PAY_DATE) * 10000 + MONTH(title.PREVISION_PAY_DATE) * 100 + DAY(title.PREVISION_PAY_DATE)) AS PREVISION_PAY_DATE
     ,title.[AMOUNT] AS PLOT_VALUE_PAYMENT
     ,'TITLE' AS TYPE_RELEASE
     ,CAST(((title.AMOUNT * ([title].[TAX_INITIAL] + IIF(title.TAX_PLANDZERO IS NULL, 0, title.TAX_PLANDZERO)) / 100) + IIF(title.PLOT = 1, title.RATE, 0)) AS DECIMAL(22, 6)) [MDR]
     ,IIF(title.ANTICIP_PERCENT IS NULL, 0,
          title.[AMOUNT] * (1 - (([title].[TAX_INITIAL] + IIF(title.TAX_PLANDZERO IS NULL, 0, title.TAX_PLANDZERO)) / 100)) *
          ((([title].[ANTICIP_PERCENT] / 30) * IIF([title].[IS_SPOT] = 0, IIF([title].[QTY_DAYS_ANTECIP] IS NULL, ([title].[PLOT] * 30) - 1, [title].[QTY_DAYS_ANTECIP]), DATEDIFF(DAY, [title].[PREVISION_PAY_DATE], [title].[ORIGINAL_RECEIVE_DATE]))) / 100)
    ) ANTICIPATION
     ,title.COD_TITLE [COD_RELEASE]
     ,title.COD_LEDGER_ESTAB
FROM dbo.TRANSACTION_TITLES title WITH (NOLOCK)
         INNER JOIN [TRANSACTION] T (NOLOCK)
                    ON [T].COD_TRAN = title.COD_TRAN
         INNER JOIN dbo.COMMERCIAL_ESTABLISHMENT(NOLOCK)
                    ON COMMERCIAL_ESTABLISHMENT.COD_EC = title.COD_EC
                        AND COMMERCIAL_ESTABLISHMENT.COD_SITUATION != 24
         LEFT JOIN AFFILIATOR(NOLOCK)
                   ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
WHERE title.COD_SITUATION IN (4, IIF(ISNULL(title.TAX_PLANDZERO, 0) > 0, 8, 0), IIF(ISNULL(title.TAX_PLANDZERO, 0) > 0, 17, 0))
  AND (AFFILIATOR.COD_SITUATION IS NULL
    OR AFFILIATOR.COD_SITUATION != 24)

UNION ALL

SELECT
    RA.COD_EC
     ,(YEAR(RA.CREATED_AT) * 10000 + MONTH(RA.CREATED_AT) * 100 + DAY(RA.CREATED_AT)) AS CREATED_AT
     ,(YEAR(RA.PREVISION_PAY_DATE) * 10000 + MONTH(RA.PREVISION_PAY_DATE) * 100 + DAY(RA.PREVISION_PAY_DATE)) AS PREVISION_PAY_DATE
     ,RA.[VALUE] AS PLOT_VALUE_PAYMENT
     ,'AJUSTE' AS TYPE_RELEASE
     ,0 AS [MDR]
     ,0 AS [ANTICIPATION]
     ,RA.COD_REL_ADJ AS [COD_RELEASE]
     ,RA.COD_LEDGER_ESTAB
FROM dbo.RELEASE_ADJUSTMENTS RA (NOLOCK)
         INNER JOIN COMMERCIAL_ESTABLISHMENT(NOLOCK) EC
                    ON EC.COD_EC = RA.COD_EC
                        AND EC.COD_SITUATION != 24
         LEFT JOIN AFFILIATOR(NOLOCK)
                   ON AFFILIATOR.COD_AFFILIATOR = EC.COD_AFFILIATOR
WHERE (RA.COD_SITUATION = 4)
  AND (AFFILIATOR.COD_SITUATION IS NULL
    OR AFFILIATOR.COD_SITUATION != 24)
UNION ALL

SELECT
    t.COD_EC
     ,CASE
          WHEN t.CREATED_AT < '2020-10-01' THEN 20201001
          ELSE (YEAR(t.CREATED_AT) * 10000 + MONTH(t.CREATED_AT) * 100 + DAY(t.CREATED_AT))
    END AS CREATED_AT
     ,(YEAR(t.PAYMENT_DAY) * 10000 + MONTH(t.PAYMENT_DAY) * 100 + DAY(t.PAYMENT_DAY)) AS PREVISION_PAY_DATE
     ,t.[VALUE] AS PLOT_VALUE_PAYMENT
     ,'TARIFA' AS TYPE_RELEASE
     ,0 AS [MDR]
     ,0 AS [ANTICIPATION]
     ,t.COD_TARIFF_EC AS [COD_RELEASE]
     ,t.COD_LEDGER_ESTAB
FROM dbo.TARIFF_EC t (NOLOCK)
         INNER JOIN dbo.COMMERCIAL_ESTABLISHMENT(NOLOCK) AS EC
                    ON EC.COD_EC = t.COD_EC
                        AND EC.COD_SITUATION != 24
         LEFT JOIN AFFILIATOR(NOLOCK)
                   ON AFFILIATOR.COD_AFFILIATOR = EC.COD_AFFILIATOR
WHERE (t.COD_SITUATION = 4)
  AND (AFFILIATOR.COD_SITUATION IS NULL
    OR AFFILIATOR.COD_SITUATION != 24)

GO
IF OBJECT_ID('SP_SET_OPEN_LEDGER_UPDATE') IS NOT NULL
    DROP PROCEDURE SP_SET_OPEN_LEDGER_UPDATE
GO
CREATE PROCEDURE SP_SET_OPEN_LEDGER_UPDATE
/*---------------------------------r-------------------------------------------------------      
    Project.......: TKPP      
------------------------------------------------------------------------------------------      
    Author              VERSION     Date            Description      
------------------------------------------------------------------------------------------      
    Luiz Aquino            V1        23/09/2019      CREATED  
------------------------------------------------------------------------------------------*/
(
    @REF_SMARTDATE INT,
    @COD_EXT INT = 1 -- EXT 1 = SAP  
)
AS
BEGIN


    DECLARE @TODAY INT = (YEAR(GETDATE()) * 10000 + MONTH(GETDATE()) * 100)


    CREATE TABLE #Temp_Open_Ledger (
                                       COD_EC INT NOT NULL
        ,CREATED_AT INT NOT NULL
        ,PREVISION_PAY_DATE INT NOT NULL
        ,PLOT_VALUE_PAYMENT DECIMAL(22, 6) NOT NULL
        ,TYPE_RELEASE VARCHAR(16)
        ,TRAN_TYPE INT NOT NULL
        ,MDR DECIMAL(22, 6) NOT NULL
        ,[ANTICIPATION] DECIMAL(22, 6) NOT NULL
        ,[COD_RELEASE] INT NOT NULL
        ,COD_OPEN_LEDGER BIGINT NULL
    )


    CREATE CLUSTERED INDEX IDX_TEMP_LEDGER ON #Temp_Open_Ledger (COD_EC, CREATED_AT, PREVISION_PAY_DATE)


    CREATE NONCLUSTERED INDEX IDX_TEMP_LEDGER_COD ON #Temp_Open_Ledger (TYPE_RELEASE) INCLUDE ([COD_RELEASE], COD_OPEN_LEDGER)

    INSERT INTO #Temp_Open_Ledger (COD_EC, CREATED_AT, PREVISION_PAY_DATE, PLOT_VALUE_PAYMENT, TYPE_RELEASE, TRAN_TYPE, [MDR], [ANTICIPATION], [COD_RELEASE], COD_OPEN_LEDGER)
    SELECT
        COD_EC
         ,CREATED_AT
         ,PREVISION_PAY_DATE
         ,PLOT_VALUE_PAYMENT
         ,TYPE_RELEASE
         ,IIF((PREVISION_PAY_DATE - @TODAY) < 100, 1, 2) [TRAN_TYPE]
         ,[MDR]
         ,[ANTICIPATION]
         ,[COD_RELEASE]
         ,COD_LEDGER_ESTAB
    FROM VW_LIST_OPEN_LEDGER_EC
    WHERE PREVISION_PAY_DATE BETWEEN 20201117 AND (20201117 + 10000)
       OR (TYPE_RELEASE = 'TARIFA'
        AND PREVISION_PAY_DATE BETWEEN 20180609 AND (20201117 + 10000))

    SELECT
        1 [COD_EXT_CLI]
         ,ldg.COD_EC
         ,ldg.CREATED_AT
         ,ldg.PREVISION_PAY_DATE
         ,ldg.TRAN_TYPE
         ,SUM(ldg.ANTICIPATION) [ANTICIPATION]
         ,SUM(ldg.MDR) [MDR]
         ,SUM(IIF(ldg.PLOT_VALUE_PAYMENT > 0, ldg.PLOT_VALUE_PAYMENT, 0)) [TPV]
         ,SUM(IIF(ldg.PLOT_VALUE_PAYMENT < 0, (ldg.PLOT_VALUE_PAYMENT * -1), 0)) [TARIFF] INTO #temp_grouped
    FROM #Temp_Open_Ledger ldg
    GROUP BY ldg.COD_EC
           ,ldg.CREATED_AT
           ,ldg.PREVISION_PAY_DATE
           ,ldg.TRAN_TYPE

-------------------------------UPDATE ---------------------------------------------------------  

    UPDATE OPEN_LEDGER_ESTABLISHMENT
    SET TPV = grpd.[TPV]
      ,MDR = grpd.[MDR]
      ,ANTECIPATION = grpd.[ANTICIPATION]
      ,PAY_TYPE = grpd.TRAN_TYPE
      ,TARIFF = grpd.TARIFF
      ,UPDATED = 1
      ,ALTER_DATE = CURRENT_TIMESTAMP
    FROM #temp_grouped grpd
             JOIN OPEN_LEDGER_ESTABLISHMENT ldger
                  ON grpd.COD_EC = ldger.COD_EC
                      AND grpd.CREATED_AT = ldger.DATE_TRANSACTION
                      AND grpd.PREVISION_PAY_DATE = ldger.PAY_DATE
                      AND grpd.[COD_EXT_CLI] = ldger.[COD_EXT_CLI]
    WHERE grpd.[ANTICIPATION] != ldger.ANTECIPATION
       OR grpd.[MDR] != ldger.[MDR]
       OR grpd.TPV != ldger.[TPV]
       OR grpd.TRAN_TYPE != ldger.PAY_TYPE
       OR ldger.TARIFF != grpd.TARIFF

    UPDATE OPEN_LEDGER_ESTABLISHMENT
    SET TPV = 0
      ,MDR = 0
      ,ANTECIPATION = 0
      ,TARIFF = 0
      ,UPDATED = 1
      ,ALTER_DATE = CURRENT_TIMESTAMP
    FROM OPEN_LEDGER_ESTABLISHMENT ldger
             LEFT JOIN #temp_grouped grpd
                       ON grpd.COD_EC = ldger.COD_EC
                           AND grpd.CREATED_AT = ldger.DATE_TRANSACTION
                           AND grpd.PREVISION_PAY_DATE = ldger.PAY_DATE
                           AND grpd.[COD_EXT_CLI] = ldger.[COD_EXT_CLI]
    WHERE ldger.PAY_DATE > @REF_SMARTDATE
      AND (ldger.TPV > 0
        OR ldger.TARIFF > 0)
      AND grpd.COD_EC IS NULL

-----------------------------INSERT-------------------------------------------------------------  

    INSERT INTO OPEN_LEDGER_ESTABLISHMENT (COD_EXT_CLI, COD_EC, DATE_TRANSACTION, PAY_DATE, PAY_TYPE, ANTECIPATION, MDR, TPV, TARIFF, CREATED_AT)
    SELECT
        grpd.[COD_EXT_CLI]
         ,grpd.COD_EC
         ,grpd.CREATED_AT
         ,grpd.PREVISION_PAY_DATE
         ,grpd.TRAN_TYPE
         ,grpd.[ANTICIPATION]
         ,grpd.[MDR]
         ,grpd.[TPV]
         ,grpd.TARIFF
         ,CURRENT_TIMESTAMP
    FROM #temp_grouped grpd
             LEFT JOIN OPEN_LEDGER_ESTABLISHMENT ldger
                       ON grpd.COD_EC = ldger.COD_EC
                           AND grpd.CREATED_AT = ldger.DATE_TRANSACTION
                           AND grpd.PREVISION_PAY_DATE = ldger.PAY_DATE
                           AND grpd.TRAN_TYPE = ldger.PAY_TYPE
                           AND grpd.[COD_EXT_CLI] = ldger.[COD_EXT_CLI]
    WHERE ldger.COD_LEDGER_ESTAB IS NULL

--------------------------------UPDATE Entities-----------------------------------------------------------  
    UPDATE RELEASE_ADJUSTMENTS
    SET COD_LEDGER_ESTAB = ldger.COD_LEDGER_ESTAB
    FROM #Temp_Open_Ledger temp_ldg
             JOIN OPEN_LEDGER_ESTABLISHMENT ldger
                  ON temp_ldg.COD_EC = ldger.COD_EC
                      AND temp_ldg.CREATED_AT = ldger.DATE_TRANSACTION
                      AND temp_ldg.PREVISION_PAY_DATE = ldger.PAY_DATE
                      AND temp_ldg.TRAN_TYPE = ldger.PAY_TYPE
                      AND ldger.[COD_EXT_CLI] = @COD_EXT
                      AND UPDATED = 1
             JOIN RELEASE_ADJUSTMENTS
                  ON RELEASE_ADJUSTMENTS.COD_REL_ADJ = temp_ldg.COD_RELEASE
    WHERE temp_ldg.TYPE_RELEASE = 'AJUSTE'

    UPDATE TRANSACTION_TITLES
    SET COD_LEDGER_ESTAB = ldger.COD_LEDGER_ESTAB
    FROM #Temp_Open_Ledger temp_ldg
             JOIN OPEN_LEDGER_ESTABLISHMENT ldger
                  ON temp_ldg.COD_EC = ldger.COD_EC
                      AND temp_ldg.CREATED_AT = ldger.DATE_TRANSACTION
                      AND temp_ldg.PREVISION_PAY_DATE = ldger.PAY_DATE
                      AND temp_ldg.TRAN_TYPE = ldger.PAY_TYPE
                      AND ldger.[COD_EXT_CLI] = @COD_EXT
                      AND UPDATED = 1
             JOIN [TRANSACTION_TITLES]
                  ON TRANSACTION_TITLES.COD_TITLE = temp_ldg.COD_RELEASE
    WHERE temp_ldg.TYPE_RELEASE = 'TITLE'

    UPDATE TARIFF_EC
    SET COD_LEDGER_ESTAB = ldger.COD_LEDGER_ESTAB
    FROM #Temp_Open_Ledger temp_ldg
             JOIN OPEN_LEDGER_ESTABLISHMENT ldger
                  ON temp_ldg.COD_EC = ldger.COD_EC
                      AND temp_ldg.CREATED_AT = ldger.DATE_TRANSACTION
                      AND temp_ldg.PREVISION_PAY_DATE = ldger.PAY_DATE
                      AND temp_ldg.TRAN_TYPE = ldger.PAY_TYPE
                      AND ldger.[COD_EXT_CLI] = @COD_EXT
                      AND UPDATED = 1
             JOIN TARIFF_EC
                  ON TARIFF_EC.COD_TARIFF_EC = temp_ldg.COD_RELEASE
    WHERE temp_ldg.TYPE_RELEASE = 'TARIFA'

END

GO

IF OBJECT_ID('SP_LIST_OPEN_LEDGER_EC') IS NOT NULL
    DROP PROCEDURE SP_LIST_OPEN_LEDGER_EC
GO
CREATE PROCEDURE SP_LIST_OPEN_LEDGER_EC
/*---------------------------------r-------------------------------------------------------      
    Project.......: TKPP      
------------------------------------------------------------------------------------------      
    Author              VERSION     Date            Description      
------------------------------------------------------------------------------------------      
    Luiz Aquino            V1        23/09/2019      CREATED  
------------------------------------------------------------------------------------------*/ (@REF_SMARTDATE INT,
                                                                                              @COD_EXT INT = 1 -- EXT 1 = SAP  
)
AS
BEGIN
    SELECT
        OPEN_LEDGER_ESTABLISHMENT.COD_LEDGER_ESTAB
         ,DATE_TRANSACTION
         ,PAY_DATE
         ,PAY_TYPE
         ,ANTECIPATION
         ,LCM
         ,CASE
              WHEN OPEN_LEDGER_ESTABLISHMENT.PAY_TYPE = 1 THEN 0
              ELSE OPEN_LEDGER_ESTABLISHMENT.MDR
        END AS MDR
         ,TPV
         ,EXTERNAL_PARTN_UP.COD_EXTERNAL
         ,TARIFF
    FROM OPEN_LEDGER_ESTABLISHMENT
             JOIN EXTERNAL_PARTN_UP
                  ON EXTERNAL_PARTN_UP.COD_EC = OPEN_LEDGER_ESTABLISHMENT.COD_EC
                      AND EXTERNAL_PARTN_UP.COD_EXT_CLI = @COD_EXT
    WHERE OPEN_LEDGER_ESTABLISHMENT.PAY_DATE >= @REF_SMARTDATE
      AND OPEN_LEDGER_ESTABLISHMENT.UPDATED = 1

      AND OPEN_LEDGER_ESTABLISHMENT.COD_EXT_CLI = @COD_EXT
END

GO

IF OBJECT_ID('dbo.SEQ_INVOICE_ORDER', 'SO') IS NULL
    BEGIN
        create sequence SEQ_INVOICE_ORDER
            minvalue 10000;
    END
GO

IF OBJECT_ID('SP_GET_SEQ_INVOICE') IS NOT NULL
    DROP PROCEDURE SP_GET_SEQ_INVOICE
GO
create procedure SP_GET_SEQ_INVOICE AS
SELECT NEXT VALUE FOR SEQ_INVOICE_ORDER
           SP_GET_SEQ_INVOICE

go


IF NOT EXISTS
    (SELECT 1
     FROM [SYS].[COLUMNS]
     WHERE name = N'COD_INVOICE_ORDER'
       AND object_id = OBJECT_ID(N'OPEN_LEDGER_ESTABLISHMENT'))
    BEGIN

        alter table OPEN_LEDGER_ESTABLISHMENT
            add COD_INVOICE_ORDER int foreign key (COD_INVOICE_ORDER) references INVOICE_ORDER (COD_INVOICE_ORDER)

    END;

GO

IF NOT EXISTS
    (SELECT 1
     FROM [SYS].[COLUMNS]
     WHERE name = N'CODE_INVOICE'
       AND object_id = OBJECT_ID(N'OPEN_LEDGER_ESTABLISHMENT'))
    BEGIN

        alter table OPEN_LEDGER_ESTABLISHMENT
            add CODE_INVOICE  VARCHAR(255)

    END;
GO

IF OBJECT_ID('SP_UP_SEQ_INVOICE' ) IS NOT NULL
    DROP PROCEDURE SP_UP_SEQ_INVOICE
GO
create procedure SP_UP_SEQ_INVOICE(@TP CODE_UQ_TYPE readonly,
                                   @SEQ int)
as
begin
    update OPEN_LEDGER_ESTABLISHMENT
    set CODE_INVOICE = @SEQ
    where COD_LEDGER_ESTAB in (select code from @TP)
end

GO
alter PROCEDURE [dbo].[SP_REG_INVOICE_ORDER]
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_REG_INVOICE_ORDER]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author                          VERSION			Date                            Description  
------------------------------------------------------------------------------------------  
Lucas Aguiar					V1				2019-09-19						Creation  
------------------------------------------------------------------------------------------*/ (@INVOICE INVOICE_ORDER READONLY)
AS

BEGIN
    DECLARE @TO_UP TABLE
                   (
                       [COD_INVOICE_ORDER] INT,
                       [CODE_INVOICE]      INT
                   );

    INSERT INTO INVOICE_ORDER (INVOICE_NUMBER,
                               INVOICE_DATE,
                               INVOICE_VALUE,
                               EC_NAME,
                               COD_PARTNER,
                               DOC_NUM)
    OUTPUT [INSERTED].[COD_INVOICE_ORDER], [INSERTED].[INVOICE_NUMBER] INTO @TO_UP ([COD_INVOICE_ORDER],
                                                                                    [CODE_INVOICE])
    SELECT INVOICE.INVOICE_NUMBER
         , INVOICE.INVOICE_DATE
         , INVOICE.INVOICE_VALUE
         , INVOICE.CARD_NAME
         , EXTERNAL_PARTN_UP.COD_EXTERNAL_PART
         , INVOICE.DOC_NUM
    FROM @INVOICE INVOICE
             JOIN EXTERNAL_PARTN_UP
                  ON EXTERNAL_PARTN_UP.COD_EXTERNAL = INVOICE.CARD_CODE

    IF @@rowcount < 1
        THROW 60000, 'INVALID CARD CODE. PARTNER NOT FOUND.', 1

    update OPEN_LEDGER_ESTABLISHMENT
    set COD_INVOICE_ORDER = toUp.COD_INVOICE_ORDER,
        SENT_ON_INVOICE   = 1
    from OPEN_LEDGER_ESTABLISHMENT
             join @TO_UP as toUp on OPEN_LEDGER_ESTABLISHMENT.CODE_INVOICE = toUp.CODE_INVOICE
    where SENT_ON_INVOICE = 0
      and OPEN_LEDGER_ESTABLISHMENT.CODE_INVOICE is not null


END;
go

--SAP

GO

IF OBJECT_ID('SP_SET_UPDATED_LEDGER_EC') IS NOT NULL
    DROP PROCEDURE SP_SET_UPDATED_LEDGER_EC;

go
CREATE PROCEDURE SP_SET_UPDATED_LEDGER_EC    
/*---------------------------------r-------------------------------------------------------        
    Project.......: TKPP        
------------------------------------------------------------------------------------------        
    Author              VERSION     Date            Description        
------------------------------------------------------------------------------------------        
    Luiz Aquino            V1        23/09/2019      CREATED   
	Kennedy Alef		   V2		 16/12/2020		Update to 0 when success to send Provision	
------------------------------------------------------------------------------------------*/ (@Ledgers TP_UP_OPEN_LEDGER READONLY)    
AS    
BEGIN    
    
 UPDATE OPEN_LEDGER_ESTABLISHMENT    
 SET UPDATED = 0   
    ,LCM = ldg.LCM    
 FROM @Ledgers ldg    
 JOIN OPEN_LEDGER_ESTABLISHMENT    
  ON OPEN_LEDGER_ESTABLISHMENT.COD_LEDGER_ESTAB = ldg.COD_LEDGER_ESTAB;    
END

GO

--ET-1171

ALTER PROCEDURE [dbo].[SP_GW_LS_EC_COMPANY]    
/*----------------------------------------------------------------------------------------             
Procedure Name: [SP_LS_EC_COMPANY]        Project.......: TKPP             
------------------------------------------------------------------------------------------             
Author        Version  Date                       Description             
------------------------------------------------------------------------------------------     
            
Kennedy Alef     V1  27/07/2018      Creation             
Elir Ribeiro     V2  05/08/2019  Changed Cod Risk Situation           
Marcus Gall   V3  2020-07-08  ET-957: Address and Bank Details on return       
Marcus Gall   V4  2020-11-05  ET-1153: Add CSC, Segment, Type EC and others info    
Caio Vitalino V5 2020-12-01   ET-1171: Add Risk Situation and justification, Filter by inactive and Email.  
Caio Vitalino V6 2020-12-03   SD-59: Add Code SEG.  
------------------------------------------------------------------------------------------*/     
(    
 @COD_COMP INT,    
 @SEARCH VARCHAR(100) = NULL,    
 @CODESAFF CODE_TYPE READONLY,    
 @QTD_BY_PAGE INT,    
 @NEXT_PAGE INT    
)    
AS    
BEGIN    
     
 SELECT    
     COMMERCIAL_ESTABLISHMENT.COD_EC      AS [COD_EC]    
    ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ     AS [CPF_CNPJ]    
    ,COMMERCIAL_ESTABLISHMENT.[NAME]     AS [NAME]    
    ,COMMERCIAL_ESTABLISHMENT.TRADING_NAME    AS [TRADING_NAME]    
    ,BRANCH_EC.COD_BRANCH        AS [COD_BRANCH]    
    ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION  AS [COD_RISK_SITUATION]    
    ,COMMERCIAL_ESTABLISHMENT.IS_PROVIDER    AS [IS_PROVIDER]    
    ,AFFILIATOR.[NAME]         AS [AFF_NAME]    
    ,ADDRESS_BRANCH.[ADDRESS]       AS [STREET]    
    ,ADDRESS_BRANCH.[NUMBER]       AS [STREET_NUMBER]    
    ,ADDRESS_BRANCH.COMPLEMENT       AS [COMPLEMENT]    
    ,ADDRESS_BRANCH.REFERENCE_POINT      AS [REFERENCE_POINT]    
    ,ADDRESS_BRANCH.CEP         AS [CEP]    
    ,NEIGHBORHOOD.[NAME]        AS [NEIGHBORHOOD]    
    ,CITY.[NAME]          AS [CITY]    
    ,[STATE].[NAME]          AS [STATE]    
    ,[COUNTRY].[NAME]         AS [COUNTRY]    
    ,BANKS.CODE           AS [BANK_CODE]    
    ,BANKS.[NAME]          AS [BANK_NAME]    
    ,BANK_DETAILS_EC.AGENCY        AS [AGENCY]    
    ,BANK_DETAILS_EC.DIGIT_AGENCY      AS [AGENCY_DIGIT]    
    ,BANK_DETAILS_EC.ACCOUNT       AS [ACCOUNT]    
    ,BANK_DETAILS_EC.DIGIT_ACCOUNT      AS [ACCOUNT_DIGIT]    
    ,ACCOUNT_TYPE.[NAME]        AS [ACCOUNT_TYPE]    
 -- ET-1153    
 ,TYPE_ESTAB.CODE         AS [TYPE_ESTABLISHMENT]    
 ,SEGMENTS.CODE          AS [MCC]    
 ,COMMERCIAL_ESTABLISHMENT.BIRTHDATE     AS [BIRTHDATE]    
 ,COMMERCIAL_ESTABLISHMENT.CREATED_AT    AS [CREATED_AT]    
 ,COMMERCIAL_ESTABLISHMENT.MODIFY_DATE    AS [MODIFY_DATE]    
 ,COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY AS [LIMIT_TRANSACTION_MONTHLY]    
 ,COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY AS [LIMIT_TRANSACTION_DIALY]    
 ,COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT   AS [TRANSACTION_LIMIT]    
 ,MEET_COSTUMER.QTY_EMPLOYEES      AS [QTY_EMPLOYEES]    
 ,MEET_COSTUMER.URL_SITE        AS [URL_SITE]    
 ,MEET_COSTUMER.INSTAGRAM       AS [INSTAGRAM]    
 ,MEET_COSTUMER.FACEBOOK        AS [FACEBOOK]    
 ,MEET_COSTUMER.CNPJ         AS [MEET_COSTUMER_CNPJ]    
 ,MEET_COSTUMER.AVERAGE_BILLING      AS [AVERAGE_BILLING]    
 ,MEET_COSTUMER.STREET        AS [MEET_COSTUMER_STREET]    
 ,MEET_COSTUMER.NUMBER        AS [MEET_COSTUMER_STREET_NUMBER]    
 ,MEET_COSTUMER.COMPLEMENT       AS [MEET_COSTUMER_COMPLEMENT]    
 ,MEET_COSTUMER.NEIGHBORHOOD       AS [MEET_COSTUMER_NEIGHBORHOOD]    
 ,MEET_COSTUMER.CITY         AS [MEET_COSTUMER_CITY]    
 ,MEET_COSTUMER.STATES         AS [MEET_COSTUMER_STATE]    
 ,MEET_COSTUMER.REFERENCEPOINT      AS [MEET_COSTUMER_REFERENCE_POINT]    
 ,MEET_COSTUMER.ZIPCODE        AS [MEET_COSTUMER_ZIPCODE]    
 -- ET-1171  
 ,COMMERCIAL_ESTABLISHMENT.ACTIVE AS [ACTIVE]  
 ,RISK_SITUATION.[NAME] AS [RISK_SITUATION]  
 ,COMMERCIAL_ESTABLISHMENT.RISK_REASON AS [RISK_REASON]  
 ,COMMERCIAL_ESTABLISHMENT.EMAIL AS [EMAIL]  
 ,SEGMENTS.COD_SEG AS [COD_SEG]  
 FROM COMMERCIAL_ESTABLISHMENT     
 INNER JOIN COMPANY ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP    
 INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC    
 LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR    
 LEFT JOIN ADDRESS_BRANCH ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH    
 LEFT JOIN NEIGHBORHOOD ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH    
 LEFT JOIN CITY ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY    
 LEFT JOIN [STATE] ON [STATE].COD_STATE = CITY.COD_STATE    
 LEFT JOIN [COUNTRY] ON [COUNTRY].COD_COUNTRY = [STATE].COD_COUNTRY    
 LEFT JOIN BANK_DETAILS_EC ON BANK_DETAILS_EC.COD_BRANCH = BRANCH_EC.COD_BRANCH    
 LEFT JOIN BANKS ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK    
 LEFT JOIN ACCOUNT_TYPE ON ACCOUNT_TYPE.COD_TYPE_ACCOUNT = BANK_DETAILS_EC.COD_TYPE_ACCOUNT    
 -- ET-1153    
 LEFT JOIN TYPE_ESTAB ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB     
 LEFT JOIN SEGMENTS ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG    
 LEFT JOIN MEET_COSTUMER ON MEET_COSTUMER.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
 -- ET-1171  
 INNER JOIN RISK_SITUATION ON RISK_SITUATION.COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION  
    
 WHERE COMPANY.COD_COMP = 8     
 --ET - 1171  
 -- AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1  
 AND ADDRESS_BRANCH.ACTIVE = 1    
 AND BANK_DETAILS_EC.ACTIVE = 1    
 AND BRANCH_EC.TYPE_BRANCH = 'PRINCIPAL'    
 AND (@SEARCH IS NULL    
  OR (COMMERCIAL_ESTABLISHMENT.[NAME] LIKE ('%' + @SEARCH + '%'))    
  OR (COMMERCIAL_ESTABLISHMENT.CPF_CNPJ LIKE ('%' + @SEARCH + '%'))    
 )    
 AND ((SELECT COUNT(*) FROM @CODESAFF) = 0     
  OR COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR IN (SELECT [CODE] FROM @CODESAFF)    
 )    
 ORDER BY 1 DESC OFFSET (@NEXT_PAGE - 1) * @QTD_BY_PAGE     
 ROWS FETCH NEXT @QTD_BY_PAGE ROWS ONLY    
END  
  
GO

--ET-1194

CREATE TABLE [dbo].[REPORT_PREFERENCES](
	[COD_REPORT_ID] [int] IDENTITY(1,1) NOT NULL,
	[COD_USER] [int] NULL,
	[CREATED_AT] [datetime] NULL,
	[MODIFY_DATE] [datetime] NULL,
	[COD_USER_ALT] [int] NULL,
	[COLUMNS_REPORT] [varchar](500) NULL,
	[ACTIVE] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_REPORT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[REPORT_PREFERENCES]  WITH CHECK ADD FOREIGN KEY([COD_USER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[REPORT_PREFERENCES]  WITH CHECK ADD FOREIGN KEY([COD_USER_ALT])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

IF OBJECT_ID('SP_REG_REPORT_PREFERENCES') IS NOT NULL
    DROP PROCEDURE [SP_REG_REPORT_PREFERENCES];
GO  
CREATE PROCEDURE SP_REG_REPORT_PREFERENCES    
/*******************************************************************************************************************************************        
----------------------------------------------------------------------------------------                                                          
Procedure Name: [SP_REG_REPORT_PREFERENCES]                                                          
Project.......: TKPP                                                          
------------------------------------------------------------------------------------------                                                          
Author                VERSION         Date         Description                                                          
------------------------------------------------------------------------------------------                                                          
Elir Ribeiro            v1         2020-12-09      ADD REFERENCES     
------------------------------------------------------------------------------------------        
*******************************************************************************************************************************************/    
    
(    
@COD_USER INT,    
@REPORT NVARCHAR(max)    
)    
AS    
DECLARE @NAME VARCHAR(200)  
DECLARE COLUMNS_CS  CURSOR FOR    
SELECT  VALUE FROM STRING_SPLIT(@REPORT, '|')  WHERE RTRIM(LTRIM(VALUE)) <> ''    
  
OPEN COLUMNS_CS  
  
FETCH NEXT FROM COLUMNS_CS  
INTO @NAME  
UPDATE REPORT_PREFERENCES SET ACTIVE = 0, MODIFY_DATE = GETDATE(), COD_USER_ALT = @COD_USER WHERE COD_USER = @COD_USER 
WHILE @@FETCH_STATUS = 0  
 BEGIN  
	INSERT INTO REPORT_PREFERENCES (CREATED_AT,COD_USER,COLUMNS_REPORT,ACTIVE) VALUES (GETDATE(),@COD_USER,@NAME,1) 
  FETCH NEXT FROM COLUMNS_CS INTO @NAME  
 END  
CLOSE COLUMNS_CS  
DEALLOCATE COLUMNS_CS  

GO

IF OBJECT_ID('SP_LIST_REPORT_PREFERENCES') IS NOT NULL
    DROP PROCEDURE [SP_LIST_REPORT_PREFERENCES];
GO  

CREATE PROCEDURE SP_LIST_REPORT_PREFERENCES
/*******************************************************************************************************************************************      
----------------------------------------------------------------------------------------                                                        
Procedure Name: [SP_LIST_REPORT_PREFERENCES]                                                        
Project.......: TKPP                                                        
------------------------------------------------------------------------------------------                                                        
Author                VERSION         Date         Description                                                        
------------------------------------------------------------------------------------------                                                        
Elir Ribeiro            v1         2020-12-11      ADD LIST REFERENCES   
------------------------------------------------------------------------------------------      
*******************************************************************************************************************************************/  

(
@COD_USER INT
)
AS 
SELECT COLUMNS_REPORT FROM REPORT_PREFERENCES WHERE COD_USER = @COD_USER AND ACTIVE = 1

GO

--ST-1694


IF NOT EXISTS (SELECT *  FROM sys.indexes  WHERE name='IX_ARR_PAY_PROT_AMOUNT_PREV_UR_FIN_CALENDAR' 
			AND object_id = OBJECT_ID('[dbo].[RRANG_TO_PAY]'))
  begin

CREATE NONCLUSTERED INDEX [IX_ARR_PAY_PROT_AMOUNT_PREV_UR_FIN_CALENDAR]
ON [dbo].[ARRANG_TO_PAY] ([COD_PAY_PROT])
INCLUDE ([PLOT_VALUE_PAYMENT],[PREV_PAYMENT],[COD_UR],[COD_FIN_CALENDAR])
END
GO



IF OBJECT_ID('SP_REPORT_FINANCE_SLC') IS NOT NULL
    DROP PROCEDURE SP_REPORT_FINANCE_SLC;
GO


CREATE PROCEDURE SP_REPORT_FINANCE_SLC
(
@DATE_REF DATE,
@TP CODE_TYPE READONLY
)
AS
BEGIN


--DECLARE @DATE_REF DATETIME = GETDATE();
--DECLARE @TP CODE_TYPE;

--INSERT INTO @TP VALUES (14206)

SELECT 
TYPE_ARR_SLC.TYPE_ARRANG,
TRANSACTION_TYPE.CODE as TRANSACTION_TYPE,
BRAND.[NAME] AS BRAND,
ARRANG_TO_PAY.PLOT_VALUE_PAYMENT,
ARRANG_TO_PAY.PREV_PAYMENT AS DATE_REF,
FINANCE_CALENDAR.EC_NAME MERCHANT_NAME ,
FINANCE_CALENDAR.EC_CPF_CNPJ AS MERCHANT_DOC,
FINANCE_CALENDAR.AFFILIATOR_CPF_CNPJ AS AFF_DOC,
FINANCE_CALENDAR.AFFILIATOR_NAME AS AFF_NAME
FROM ARRANG_TO_PAY
JOIN FINANCE_CALENDAR  ON FINANCE_CALENDAR.COD_FIN_CALENDAR = ARRANG_TO_PAY.COD_FIN_CALENDAR
JOIN RECEIVABLE_UNITS ON RECEIVABLE_UNITS.COD_UR = ARRANG_TO_PAY.COD_UR
JOIN BRAND ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND
JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR
JOIN TRANSACTION_TYPE ON TRANSACTION_TYPE.COD_TTYPE = BRAND.COD_TTYPE
WHERE 
FINANCE_CALENDAR.ACTIVE=1 AND
FINANCE_CALENDAR.COD_SITUATION=4 AND
FINANCE_CALENDAR.PREVISION_PAY_DATE <= @DATE_REF AND
FINANCE_CALENDAR.COD_EC IN 
(
SELECT CODE FROM @TP


)

END;

go


IF OBJECT_ID('SP_REPORT_FINANCE_SLC_PAID') IS NOT NULL
    DROP PROCEDURE SP_REPORT_FINANCE_SLC_PAID;
GO


CREATE PROCEDURE SP_REPORT_FINANCE_SLC_PAID
(
@TP CODE_TYPE READONLY
)
as
BEGIN
select 
TYPE_ARR_SLC.TYPE_ARRANG,
TRANSACTION_TYPE.CODE as TRANSACTION_TYPE,
BRAND.[NAME] AS BRAND,
ARRANG_TO_PAY.PLOT_VALUE_PAYMENT,
ARRANG_TO_PAY.PREV_PAYMENT AS DATE_REF,
FINANCE_CALENDAR.EC_NAME MERCHANT_NAME ,
FINANCE_CALENDAR.EC_CPF_CNPJ AS MERCHANT_DOC,
FINANCE_CALENDAR.AFFILIATOR_CPF_CNPJ AS AFF_DOC,
FINANCE_CALENDAR.AFFILIATOR_NAME AS AFF_NAME,
PROTOCOLS.PROTOCOL
from ARRANG_TO_PAY
JOIN FINANCE_CALENDAR  ON FINANCE_CALENDAR.COD_FIN_CALENDAR = ARRANG_TO_PAY.COD_FIN_CALENDAR
JOIN PROTOCOLS ON PROTOCOLS.COD_PAY_PROT = ARRANG_TO_PAY.COD_PAY_PROT
JOIN RECEIVABLE_UNITS ON RECEIVABLE_UNITS.COD_UR = ARRANG_TO_PAY.COD_UR
JOIN TYPE_ARR_SLC ON TYPE_ARR_SLC.COD_TYPE_ARR = RECEIVABLE_UNITS.COD_TYPE_ARR
JOIN BRAND ON BRAND.COD_BRAND = RECEIVABLE_UNITS.COD_BRAND
JOIN TRANSACTION_TYPE ON TRANSACTION_TYPE.COD_TTYPE = BRAND.COD_TTYPE
where 
PROTOCOLS.COD_PAY_PROT IN
(
SELECT CODE FROM @TP


)


END;

GO

--ST-1700

GO
SELECT 
COD_EC,
COD_DEPTO_BR INTO #TMP
FROM VW_COMPANY_EC_BR_DEP
WHERE COD_AFFILIATOR = 303
AND CPF_CNPJ_EC IN 
(
'37112328000100',
'40836837835',
'25442962830',
'11763393895',
'19075258828',
'05192475740',
'49886324821',
'24590793890',
'72986638520',
'44021835881',
'32929768800',
'27832638826',
'39044398806',
'37833249807',
'49861391851',
'33018975847',
'30195139000107',
'10134800826',
'68193165420',
'15409326806',
'38332358884',
'68796080515',
'44914178818',
'31884315895',
'04625143314',
'10340741805',
'02373284537',
'36158912000133',
'43234398810',
'11765230829',
'02077852445',
'24804648810',
'40423862880',
'31031805869',
'28313603828',
'38300294899',
'38540195801',
'01308795840',
'08789907809',
'40408218827',
'85197076453',
'38359286515',
'02272507450',
'16886249886',
'16099590862',
'45392572855',
'51360338861',
'37574048000113',
'45535075876',
'54185904134',
'41947772805',
'10718743814',
'26727846472',
'14681818828',
'34926497000195',
'05759933833',
'24647895858',
'36200658889',
'38659960866',
'37996194000137',
'38424901000183',
'27718910857',
'42347019805',
'70771669372',
'23885204878',
'02737972809',
'02180202369',
'41348236841',
'36473570000146',
'14354521865',
'31891650840',
'36657288867',
'08398434961',
'33667224877',
'39274908814',
'40112015883',
'39546858846',
'39183541802',
'39150099892',
'49517248806',
'24133155000164',
'03054024393',
'03267190673',
'30595735000176',
'28085848813',
'50450451801',
'36398698851',
'41524719803',
'28876277838',
'24764840839',
'29796339846',
'28058792870',
'37829351000110',
'06370966819',
'38730540860',
'44824454875',
'17707680847',
'30526425881',
'45853954822',
'23271519889',
'36746039854',
'02898579530',
'39981577863',
'32949583822',
'39613325000185',
'32181452873',
'35818820866',
'25978855854',
'27279739857',
'39163552876',
'24647895858',
'22663628875',
'34521466850',
'43163867863',
'35256967878',
'30679343857',
'31943409803',
'32838711830',
'30128646870',
'40894249843',
'28626266863',
'05272806310',
'47258735860',
'48485138805',
'91550394568',
'00586711538',
'23027942000169',
'43384219830',
'37345523896',
'37029301838',
'38037805867',
'40351375880',
'16700132860',
'34664848000137',
'30154081000145',
'16696269894',
'38115993808',
'35490045833',
'46985400892',
'08944133760',
'13688329899',
'05765868541'
)


DECLARE @COD_DEPTO INT;
DECLARE @COD_PLAN INT = 8419;

 DECLARE cursor_ CURSOR FOR   
    SELECT 
COD_DEPTO_BR 

    FROM #TMP
  
    OPEN cursor_  
    FETCH NEXT FROM cursor_ INTO @COD_DEPTO  
    
  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
  
        
        EXEC SP_ASS_DEPTO_PLAN @COD_PLAN, @COD_DEPTO, 5472
		FETCH NEXT FROM cursor_ INTO @COD_DEPTO  

        END  
  
    CLOSE cursor_  
    DEALLOCATE cursor_ 
	GO

--ST-1680

ALTER PROCEDURE [DBO].[SP_LS_AFFILIATOR_COMP]                                  
          
/*****************************************************************************************************************          
----------------------------------------------------------------------------------------                                  
Procedure Name: SP_LS_AFFILIATOR_COMP                                  
Project.......: TKPP                                  
------------------------------------------------------------------------------------------                                  
Author                          VERSION       Date              Description                                  
------------------------------------------------------------------------------------------                                  
Gian Luca Dalle Cort              V1        01/08/2018            CREATION                           
Luiz Aquino                       V2        01/10/2018            UPDATE                          
Luiz Aquino                       v3        18/12/2018            ADD SPOT_TAX                          
Lucas Aguiar                      v4        01/07/2019            Rotina de bloqueio bancario                   
Caike Uchôa                       v5        26/02/2020            add OperationAff                
Elir Ribeiro                      v6        16/04/2020           add tax and deadline billet              
Caike Uchôa                       v7        17/04/2020           add busca por cnpj          
Caike Uchoa                       v8        16/09/2020           add correcao billetTax      
Caike uchoa                       v9        21/10/2020           add email    
Caike Uchoa                       v10       10/11/2020           Add Program Manager  
Caio Vitalino					  v11       08/12/2020	         Remove the filter active 
------------------------------------------------------------------------------------------          
*****************************************************************************************************************/          
                                  
(          
 @ACCESS_KEY          VARCHAR(300),           
 @NAME                VARCHAR(100) = NULL,           
 @ACTIVE              INT          = 1,           
 @CODAFF              INT          = NULL,           
 @WAS_BLOCKED_FINANCE INT          = NULL)          
AS          
BEGIN  
        
          
          
    DECLARE @QUERY_ NVARCHAR(MAX);  
        
          
          
    DECLARE @COD_BLOCK_SITUATION INT;  
        
          
          
    DECLARE @BUSCA VARCHAR(255);  
  
  
  
  
SET @BUSCA = '%' + @NAME + '%';  
  
SELECT  
 @COD_BLOCK_SITUATION = [COD_SITUATION]  
FROM [SITUATION]  
WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';  
  
SET @QUERY_ = '                          
                          
  SELECT                                   
  AFFILIATOR.COD_AFFILIATOR,                                  
  AFFILIATOR.CREATED_AT,                                  
  AFFILIATOR.ACTIVE,                                  
  AFFILIATOR.NAME AS NAME,                                  
  AFFILIATOR.CODE,                                  
  AFFILIATOR.CPF_CNPJ AS CPF_CNPJ,                                  
  AFFILIATOR.COD_USER_CAD,                          
  u.IDENTIFICATION AFF_USER,                          
  AFFILIATOR.ACCESS_KEY_AFL,                                  
  AFFILIATOR.SECRET_KEY_AFL,                                  
  AFFILIATOR.CLIENT_ID_AFL,                                  
  AFFILIATOR.FIREBASE_NAME,                                  
  AFFILIATOR.MODIFY_DATE,                                  
  AFFILIATOR.COD_USER_ALT,                                  
  AFFILIATOR.GUID AS GUID,                                  
  COMPANY.COD_COMP,                                  
  COMPANY.NAME AS COMPANY_NAME,                                  
  COMPANY.CODE AS COMPANY_CODE,                                   
  COMPANY.CPF_CNPJ AS CNPJ_COMPANY,                                  
  AFFILIATOR.SUBDOMAIN SUB_DOMAIN,                                
  THEMES.LOGO_AFFILIATE,                                
  THEMES.LOGO_HEADER_AFFILIATE,                                
  THEMES.COLOR_HEADER,                          
  THEMES.BACKGROUND_IMAGE,                          
  THEMES.SECONDARY_COLOR,                          
  THEMES.SELF_REG_IMG_INITIAL,                          
  THEMES.SELF_REG_IMG_FINAL,                          
  AFFILIATOR.SPOT_TAX,                
  CASE                          
   WHEN AFFILIATOR.COD_SITUATION = @COD_BLOCK_SITUATION THEN 1                          
   ELSE 0                           
  END [FINANCE_BLOCK],                          
  AFFILIATOR.NOTE_FINANCE_SCHEDULE  ,                  
  TRADUCTION_SITUATION.SITUATION_TR,                  
  AFFILIATOR.PLATFORM_NAME PlatformName,                                
  AFFILIATOR.PROPOSED_NUMBER  ProposedNumber,                  
  AFFILIATOR.STATE_REGISTRATION  StateRegistration,                  
  AFFILIATOR.MUNICIPAL_REGISTRATION  MunicipalRegistration,                  
  AFFILIATOR.COMPANY_NAME  CompanyTraddingName,                
  AFFILIATOR.OPERATION_AFF,         
  COMPANY_DOMAIN.DOMAIN,        
  (      
  SELECT TOP 1 SERVICE_AMOUNT FROM SERVICES_AVAILABLE      
  WHERE COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR      
  AND ACTIVE = 1      
  AND COD_EC IS NULL       
  AND COD_ITEM_SERVICE = 11      
  ) AS [billet_tax],    
 AFFILIATOR_CONTACT.MAIL AS EMAIL,  
 AFFILIATOR.PROGRAM_MANAGER   
 FROM AFFILIATOR                                   
  INNER JOIN COMPANY ON AFFILIATOR.COD_COMP = COMPANY.COD_COMP         
  JOIN COMPANY_DOMAIN ON COMPANY_DOMAIN.COD_COMP = COMPANY.COD_COMP AND COMPANY_DOMAIN.ACTIVE = 1        
  LEFT JOIN THEMES ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR AND THEMES.ACTIVE = 1                          
  LEFT JOIN USERS u ON u.COD_USER = AFFILIATOR.COD_USER_CAD                          
  LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = AFFILIATOR.COD_SITUATION           
  LEFT JOIN AFFILIATOR_CONTACT ON AFFILIATOR_CONTACT.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR    
  AND AFFILIATOR_CONTACT.ACTIVE =1    
 WHERE COMPANY.ACCESS_KEY = @ACCESS_KEY ';  
        
          
          
          
          
          
    IF @NAME IS NOT NULL  
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.NAME LIKE @BUSCA OR AFFILIATOR.CPF_CNPJ LIKE @BUSCA';  
  
IF (@CODAFF IS NOT NULL)  
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_AFFILIATOR = @CodAff ';  
  
IF @WAS_BLOCKED_FINANCE = 1  
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_SITUATION = @COD_BLOCK_SITUATION ';  
ELSE  
IF @WAS_BLOCKED_FINANCE = 0  
SET @QUERY_ = @QUERY_ + ' AND AFFILIATOR.COD_SITUATION <> @COD_BLOCK_SITUATION';  
  
  
EXEC [sp_executesql] @QUERY_  
     ,N'                            
  @ACCESS_KEY VARCHAR(300),                          
  @Name VARCHAR(100) ,                          
  @Active INT,                          
  @CodAff INT,                          
  @COD_BLOCK_SITUATION INT,                        
  @BUSCA VARCHAR(255)                        
  '  
     ,@ACCESS_KEY = @ACCESS_KEY  
     ,@NAME = @NAME  
     ,@ACTIVE = @ACTIVE  
     ,@CODAFF = @CODAFF  
     ,@COD_BLOCK_SITUATION = @COD_BLOCK_SITUATION  
     ,@BUSCA = @BUSCA;  
  
  
  
END;

-- ST-1692

--SELECT * FROM ASS_TR_TYPE_COMP 
--JOIN  BRAND ON BRAND.COD_BRAND = ASS_TR_TYPE_COMP.COD_BRAND
--JOIN TRANSACTION_TYPE ON TRANSACTION_TYPE.COD_TTYPE = ASS_TR_TYPE_COMP.COD_TTYPE
--WHERE COD_AC = 27

--VISA / MASTERCARD
-- Debito MAESTRO e VISA ELECTRON
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 0.66 
WHERE COD_AC = 27 AND COD_TTYPE = 2 AND COD_BRAND IN (1,4)
GO
-- Crédito à vista MASTERCARD e Visa
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.14 
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND IN (2,3) AND PLOT_INI = 1 AND PLOT_END = 1
GO
-- Parcelado 2 a 6 MASTERCARD e Visa
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.58 
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND IN (2,3) AND PLOT_INI = 2 AND PLOT_END = 6
GO
-- Parcelado 7 a 12 MASTERCARD e VISA
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.88
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND IN (2,3) AND PLOT_INI = 7 AND PLOT_END = 12
GO
-- ELO/CABAL
--Débito ELO DEBITO/ CABAL DEBITO
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 0.76
WHERE COD_AC = 27 AND COD_TTYPE = 2 AND COD_BRAND IN (6,16)
GO
--Crédito à vista ELO Crédito / CABAL Crédito
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.18
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND IN (5,15) AND PLOT_INI = 1 AND PLOT_END = 1
GO
-- Parcelado 2 a 6 ELO CREDITO / CABAL CRÉDITO
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.68
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND IN (5,15) AND PLOT_INI = 2 AND PLOT_END = 6
GO
-- Parcelado 7 a 12 ELO CRÉDITO / CABAL CRÉDITO
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.98
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND IN (5,15) AND PLOT_INI = 7 AND PLOT_END = 12
-- HiperCard
-- Crédito à vista HiperCard
GO
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.59
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND = 7 AND PLOT_INI = 1 AND PLOT_END = 1
GO
-- Parcelado 2 a 6 HiperCard
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.89
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND = 7 AND PLOT_INI = 2 AND PLOT_END = 6
GO
-- Parcelado 7 a 12 HiperCard
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 2.19
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND = 7 AND PLOT_INI = 7 AND PLOT_END = 12
GO
--AMEX
-- Crédito à vista AMEX
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.58
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND = 14 AND PLOT_INI = 1 AND PLOT_END = 1
GO
-- Parcelado 2 a 6 AMEX
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 1.88
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND = 14 AND PLOT_INI = 2 AND PLOT_END = 6
GO
-- Parcelado 7 a 12 AMEX
UPDATE ASS_TR_TYPE_COMP SET
TAX_VALUE = 2.18
WHERE COD_AC = 27 AND COD_TTYPE = 1 AND COD_BRAND = 14 AND PLOT_INI = 7 AND PLOT_END = 12

GO

--merge

ALTER PROCEDURE [dbo].[SP_GW_LS_DETAILS_PLAN_MODEL_EQUIPMENT]      
/*----------------------------------------------------------------------------------------                  
Procedure Name: [SP_GW_LS_DETAILS_PLAN_MODEL_EQUIPMENT]                  
Project.......: TKPP                  
------------------------------------------------------------------------------------------                  
Author                          VERSION        Date                            Description                  
------------------------------------------------------------------------------------------                  
Marcus Gall      V1   2020-07-13  ET-921: Handle Plan by Equipment         
Caio Vitalino    V2   2020-12-04  SD-60 : Incluir a informação da alteração do plano na API   
Caio Vitalino    V3   2020-12-11  SD-18: Add the active field plan
------------------------------------------------------------- -----------------------------*/ (@COD_PLAN INT,      
@COD_AFFILIATOR INT)      
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
      
 SELECT DISTINCT      
  PLANS.COD_PLAN      
    ,PLANS.[NAME_PLAN]      
    ,PLANS.[DESCRIPTION]      
    ,PLANS.CATEGORY      
    ,PLANS.TYPE_PLAN      
    ,PLANS.PLAN_OPTION      
    ,PLANS.BRAND_GROUP      
    ,PLANS.TRANSACTION_TYPE      
    ,PLANS.QTY_INI_PLOTS      
    ,PLANS.QTY_FINAL_PLOTS      
    ,PLANS.EQUIPMENT_MODEL    
 -- SD - 60  
    ,PLANS.MODIFY_DATE   
 -- SD - 18
	,PLANS.ACTIVE
    ,SUM(PLANS.ANTICIPATION_PERCENTAGE) AS ANTICIPATION_PERCENTAGE      
    ,SUM(PLANS.INTERVAL_DEBIT) AS INTERVAL_DEBIT      
    ,SUM(INTERVAL_CREDIT_A_VISTA) AS INTERVAL_CREDIT_A_VISTA      
    ,SUM(INTERVAL_CREDIT_PARCELADO) AS INTERVAL_CREDIT_PARCELADO      
    ,SUM(INTERVAL_ONLINE) AS INTERVAL_ONLINE      
    ,SUM(PLANS.PARCENTAGE) AS PARCENTAGE      
    ,SUM(PLANS.RATE) AS RATE      
 FROM (SELECT      
   [PLAN].COD_PLAN      
     ,[PLAN].CODE AS [NAME_PLAN]      
     ,[PLAN].[DESCRIPTION]      
     ,PLAN_CATEGORY.CATEGORY      
     ,TYPE_PLAN.CODE AS TYPE_PLAN      
     ,PLAN_OPTION.CODE AS PLAN_OPTION      
     ,BRAND.[GROUP] AS BRAND_GROUP      
     ,TRANSACTION_TYPE.CODE AS TRANSACTION_TYPE      
     ,TAX_PLAN.QTY_INI_PLOTS      
     ,TAX_PLAN.QTY_FINAL_PLOTS  
--SD-18
	,[PLAN].ACTIVE AS ACTIVE
  --SD - 60  
  ,[dbo].[FN_FUS_UTF] ([PLAN].MODIFY_DATE) AS [MODIFY_DATE]  
    --,[PLAN].MODIFY_DATE     
     ,CASE      
    WHEN (SOURCE_TRANSACTION.COD_SOURCE_TRAN = 1) THEN 'SITE'      
    ELSE EQUIPMENT_MODEL.CODIGO      
   END AS EQUIPMENT_MODEL      
     ,TAX_PLAN.ANTICIPATION_PERCENTAGE      
     ,(SELECT TOP 1      
     ISNULL(INTERVAL, 0)      
    FROM TAX_PLAN ASS      
    WHERE ASS.COD_PLAN = [PLAN].COD_PLAN      
    AND ASS.ACTIVE = 1      
    AND ASS.COD_TTYPE = 2)      
   AS [INTERVAL_DEBIT]      
     ,(SELECT TOP 1      
     ISNULL(INTERVAL, 0)      
    FROM TAX_PLAN ASS      
    WHERE ASS.COD_PLAN = [PLAN].COD_PLAN      
    AND ASS.ACTIVE = 1      
    AND ASS.COD_TTYPE = 1      
    AND ASS.QTY_INI_PLOTS = 1      
    AND ASS.QTY_FINAL_PLOTS = 1      
    AND ASS.COD_SOURCE_TRAN = 2)      
   AS [INTERVAL_CREDIT_A_VISTA]      
     ,(SELECT TOP 1      
     ISNULL(INTERVAL, 0)      
    FROM TAX_PLAN ASS      
    WHERE ASS.COD_PLAN = [PLAN].COD_PLAN      
    AND ASS.ACTIVE = 1      
    AND ASS.COD_TTYPE = 1      
    AND ASS.QTY_INI_PLOTS > 1      
    AND ASS.QTY_FINAL_PLOTS > 1      
    AND ASS.COD_SOURCE_TRAN = 2)      
   AS [INTERVAL_CREDIT_PARCELADO]      
     ,(SELECT TOP 1      
     ISNULL(INTERVAL, 0)      
    FROM TAX_PLAN ASS      
    WHERE ASS.COD_PLAN = [PLAN].COD_PLAN      
    AND ASS.ACTIVE = 1      
    AND ASS.COD_SOURCE_TRAN = 1)      
   AS [INTERVAL_ONLINE]      
     ,PARCENTAGE      
     ,RATE      
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
  LEFT JOIN PLAN_OPTION      
   ON PLAN_OPTION.COD_PLAN_OPT = [PLAN].COD_PLAN_OPT      
  LEFT JOIN EQUIPMENT_MODEL      
   ON EQUIPMENT_MODEL.COD_MODEL = TAX_PLAN.COD_MODEL      
  WHERE TAX_PLAN.ACTIVE = 1) AS PLANS      
 WHERE PLANS.COD_PLAN = @COD_PLAN      
 GROUP BY PLANS.COD_PLAN      
   ,PLANS.[NAME_PLAN]      
   ,PLANS.[DESCRIPTION]      
   ,PLANS.CATEGORY      
   ,PLANS.TYPE_PLAN      
   ,PLANS.PLAN_OPTION      
   ,PLANS.BRAND_GROUP      
   ,PLANS.TRANSACTION_TYPE      
   ,PLANS.QTY_INI_PLOTS      
   ,PLANS.QTY_FINAL_PLOTS      
   ,PLANS.EQUIPMENT_MODEL    
   --SD -60  
   ,PLANS.MODIFY_DATE
   --SD -18
  ,PLANS.ACTIVE;
      
END

GO

--
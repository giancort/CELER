IF OBJECT_ID('ADDRESS_COMPANY') IS NOT NULL DROP TABLE ADDRESS_COMPANY;
GO
CREATE TABLE ADDRESS_COMPANY
(
    COD_ADR_COMP INT PRIMARY KEY IDENTITY,
    CREATED_AT DATETIME,
    COD_USER_CAD INT FOREIGN KEY (COD_USER_CAD)  REFERENCES USERS(COD_USER),
    NAME VARCHAR(50),
    CPF_CNPJ VARCHAR(50),
    ADDRESS varchar(250),
    EMAIL VARCHAR(50),
    NOME_RESPONSAVEL VARCHAR(50),
    TELEFONE VARCHAR(50),
    NUMBER INT,
    COMPLEMENT VARCHAR(50),
    CEP VARCHAR(10),
    COD_NEIGH INT FOREIGN KEY (COD_NEIGH) REFERENCES NEIGHBORHOOD(COD_NEIGH),
    ACTIVE INT,
    MODIFY_DATE DATETIME,
    COD_USER_ALT INT FOREIGN KEY (COD_USER_CAD)  REFERENCES USERS(COD_USER),
    REFERENCE_POINT VARCHAR(100),
    COD_MUN INT,
    UF VARCHAR(50),
    COD_COMP INT FOREIGN KEY (COD_COMP) REFERENCES COMPANY(COD_COMP),
    COD_COUNTRY INT NOT NULL DEFAULT(1) FOREIGN KEY (COD_COUNTRY) REFERENCES COUNTRY (COD_COUNTRY)
)
GO

IF (SELECT COUNT(*) FROM ADDRESS_COMPANY) = 0
BEGIN
    INSERT INTO ADDRESS_COMPANY
    VALUES (GETDATE(), 172,
            'CELER PROCESSAMENTO COMERCIO E SERVICO LTDA',
            '22347623000178',
            'RUA FERNANDO DE ALBUQUERQUE, 155, ANDAR 7 SALA 01, CONSOLACAO, SAO PAULO ',
            'leticia.santana@paxbr.com.br', 'LETICIA SANTANA',
            '1131978090',
            155, 'PINHEIROS', '01309030', 5343, 1, NULL, NULL, NULL, 3550308, 'SP', 8, 1)
END
GO
IF NOT EXISTS (SELECT 1
               FROM sys.columns
               WHERE NAME = N'ACQ_DOCUMENT' AND object_id = OBJECT_ID(N'ACQUIRER'))
    BEGIN
        ALTER TABLE ACQUIRER
            ADD ACQ_DOCUMENT VARCHAR(100)
    END
GO
UPDATE ACQUIRER SET ACQ_DOCUMENT = '01027058000191' WHERE [NAME] LIKE '%cielo%'
GO
UPDATE ACQUIRER SET ACQ_DOCUMENT = '04494979000152' WHERE [NAME] LIKE '%softcred%'
GO
UPDATE ACQUIRER SET ACQ_DOCUMENT = '16501555000157' WHERE [NAME] LIKE '%stone%'
GO
UPDATE ACQUIRER SET ACQ_DOCUMENT = '25165266000115' WHERE [NAME] LIKE '%its%'
GO
UPDATE ACQUIRER SET ACQ_DOCUMENT = '08561701000101' WHERE [NAME] LIKE '%Pagseguro%'

GO
IF (SELECT COUNT(*)
    FROM SOURCE_PROCESS
    WHERE CODE = '10') = 0
    INSERT SOURCE_PROCESS
    (CREATED_AT,[DESCRIPTION],CODE)
    VALUES
    (GETDATE(), 'TXT_EXPORTDIMP', 'GERAÇÃO DE ARQUIVO DIMP')
GO

GO
IF OBJECT_ID('SP_LS_MAIL_FINANCIAL_DIMP') IS NOT NULL DROP PROCEDURE SP_LS_MAIL_FINANCIAL_DIMP;
GO
CREATE PROCEDURE SP_LS_MAIL_FINANCIAL_DIMP
/********************************************************************************************    
----------------------------------------------------------------------------------------       
  Procedure Name: [SP_LS_MAIL_FINANCIAL_DIMP]  Project.......: TKPP       
------------------------------------------------------------------------------------------       
  Author              VERSION        Date         Description       
------------------------------------------------------------------------------------------       
  Elir Ribeiro             v1           30-06-2020   to list mail financial 
------------------------------------------------------------------------------------------    
********************************************************************************************/
AS
SELECT USERS.EMAIL
FROM USERS
         INNER JOIN PROFILE_ACCESS ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE
WHERE PROFILE_ACCESS.COD_PROFILE = 17 AND USERS.ACTIVE = 1 AND PROFILE_ACCESS.ACTIVE = 1
GO

IF OBJECT_ID('SP_LS_READED_NOTIFY_MESSAGES_FINANCE') IS NOT NULL DROP PROCEDURE SP_LS_READED_NOTIFY_MESSAGES_FINANCE;
GO
CREATE PROCEDURE SP_LS_READED_NOTIFY_MESSAGES_FINANCE
AS
BEGIN

    DELETE FROM NOTIFICATION_MESSAGES WHERE DATEDIFF(DAY, NOTIFICATION_MESSAGES.CREATED_AT, current_timestamp) > 1;

    WITH
        CTE
            AS
            (
                SELECT TOP 15
                    NOTIFICATION_MESSAGES.COD_NOTIFY_MESSAGE
                            , NOTIFICATION_MESSAGES.COD_USER
                            , dbo.FN_FUS_UTF(NOTIFICATION_MESSAGES.CREATED_AT) AS CREATED_AT
                            , NOTIFICATION_MESSAGES.EXPIRED
                            , NOTIFICATION_MESSAGES.CONTENT_MESSAGE
                            , NOTIFICATION_MESSAGES.LINK_REPORT
                            , NOTIFICATION_MESSAGES.COD_SOURCE_PROCESS
                            , NOTIFICATION_MESSAGES.NOTIFY_READ
                            , NOTIFICATION_MESSAGES.CODE
                            , NOTIFICATION_MESSAGES.NOTIFY_SENT
                            , SOURCE_PROCESS.CODE AS REPORT_NAME
                            , NOTIFICATION_MESSAGES.GENERATE_STATUS
                FROM NOTIFICATION_MESSAGES
                         INNER JOIN SOURCE_PROCESS
                                    ON SOURCE_PROCESS.COD_SOURCE_PROCESS = NOTIFICATION_MESSAGES.COD_SOURCE_PROCESS
                ORDER BY 1 DESC
            )
    SELECT *
    FROM CTE
    ORDER BY 1;

END;

GO
IF OBJECT_ID('SEQ_DIMP_FILE') IS NOT NULL
    DROP SEQUENCE [SEQ_DIMP_FILE];
GO
CREATE SEQUENCE [dbo].[SEQ_DIMP_FILE]
    AS [bigint]
    START WITH 0008
    INCREMENT BY 1
    MINVALUE -9223372036854775808
    MAXVALUE 9223372036854775807
    CACHE
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'BRAND_EXT_CODE' AND object_id = OBJECT_ID(N'BRAND')) BEGIN
        ALTER TABLE BRAND ADD BRAND_EXT_CODE INT
END
GO
UPDATE BRAND SET BRAND_EXT_CODE = 02 WHERE COD_BRAND = 2
GO
UPDATE BRAND SET BRAND_EXT_CODE = 01 WHERE COD_BRAND = 3
GO
UPDATE BRAND SET BRAND_EXT_CODE = 03 WHERE COD_BRAND = 14
GO
UPDATE BRAND SET BRAND_EXT_CODE = 03 WHERE COD_BRAND = 18
GO
UPDATE BRAND SET BRAND_EXT_CODE = 99 WHERE COD_BRAND NOT IN(2,3,14,18)
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('REPORT_TRANSACTIONS_EXP') AND name='IX_REPORT_TRANSACTIONS_EXP_TRAN_DATE')  BEGIN
    CREATE NONCLUSTERED INDEX IX_REPORT_TRANSACTIONS_EXP_TRAN_DATE
        ON [dbo].[REPORT_TRANSACTIONS_EXP] ([TRANSACTION_DATE])
        INCLUDE (COD_EC, [COD_TRAN],[MODIFY_DATE],[TRANSACTION_CODE])
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('REPORT_TRANSACTIONS_EXP') AND name='IX_REPORT_TRANSACTIONS_EXP_DIMP')  BEGIN
    CREATE NONCLUSTERED INDEX IX_REPORT_TRANSACTIONS_EXP_DIMP
    ON [dbo].[REPORT_TRANSACTIONS_EXP] (COD_SITUATION, TRANSACTION_DATE)
    INCLUDE (COD_EC, [COD_TRAN],[AMOUNT],[MODIFY_DATE],[COD_SOURCE_TRAN],[COD_AC],[TRANSACTION_CODE],[TRANSACTION_TYPE],[BRAND],[TRAN_DATA_EXT_VALUE],[SPLIT],[CPF_CNPJ],STATE_NAME)
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('REPORT_TRANSACTIONS_EXP') AND name='IX_REPORT_DIMP_COD_SITUATION')  BEGIN
    CREATE NONCLUSTERED INDEX IX_REPORT_DIMP_COD_SITUATION
    ON [dbo].[REPORT_TRANSACTIONS_EXP] ([COD_SITUATION])
    INCLUDE (COD_EC, [COD_TRAN],[MODIFY_DATE],[TRANSACTION_CODE], TRANSACTION_DATE)
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('BRAND') AND name='IX_BRAND_NAME')  BEGIN
    CREATE NONCLUSTERED INDEX IX_BRAND_NAME
    ON [dbo].[BRAND] ([NAME])
    INCLUDE (BRAND_EXT_CODE)
END
GO

UPDATE BRAND SET BRAND_EXT_CODE = 1 WHERE COD_BRAND = 4
GO

IF OBJECT_ID('SP_LS_DIMP_STATE_INFO') IS NOT NULL DROP PROCEDURE SP_LS_DIMP_STATE_INFO;
GO
CREATE PROCEDURE [dbo].[SP_LS_DIMP_STATE_INFO]
/*----------------------------------------------------------------------------------------                                  
   Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
   Author                   VERSION        Date             Description                                  
------------------------------------------------------------------------------------------                                  
   Luiz Aquino              V1             2021-02-04       CREATED   
------------------------------------------------------------------------------------------*/

AS BEGIN

    DECLARE @SEQUENCE_FILE NVARCHAR(MAX)
    SET @SEQUENCE_FILE = dbo.LPAD(NEXT VALUE FOR SEQ_DIMP_FILE, 5, '0')

    --Tipo 1 Producao, Tipo 2 = Homologacao
    
    SELECT  DISTINCT
         [STATE].[UF] AS [UF_FISCO]
       , [ADDRESS_COMPANY].[CPF_CNPJ] AS CPF_CNPJ
       , [ADDRESS_COMPANY].[NOME_RESPONSAVEL] AS [NOME_FANTASIA]
       , [ADDRESS_COMPANY].[ADDRESS] AS ENDERECO
       , [ADDRESS_COMPANY].[CEP] AS CEP
       , [ADDRESS_COMPANY].[COD_MUN] AS MUNICIPIO
       , [ADDRESS_COMPANY].[UF] AS UF
       , [ADDRESS_COMPANY].[TELEFONE] AS NUMBER
       , [ADDRESS_COMPANY].[EMAIL] AS EMAIL
       , '06' AS [VERSAO_LAYOUT]
       , '1' AS [FINALIDADE_ARQUIVO]
       , [ADDRESS_COMPANY].[NAME] AS [RAZAO_SOCIAL]
       , '1' AS TIPO
       , @SEQUENCE_FILE AS [SEQUENCE]
       , [STATE].NAME [STATE_NAME]
       , '1' Iden
    FROM ADDRESS_COMPANY
        INNER JOIN [STATE] ON [STATE].COD_COUNTRY = ADDRESS_COMPANY.COD_COUNTRY

END
GO

IF OBJECT_ID('SP_LS_DIMP_EC_INFO') IS NOT NULL DROP PROCEDURE SP_LS_DIMP_EC_INFO;
GO
CREATE PROCEDURE [dbo].[SP_LS_DIMP_EC_INFO]
/*----------------------------------------------------------------------------------------                                  
   Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
   Author                   VERSION        Date             Description                                  
------------------------------------------------------------------------------------------                                  
   Luiz Aquino              V1             2021-02-04       CREATED   
------------------------------------------------------------------------------------------*/
(
    @DATAINITIAL DATETIME,
    @FINALDATE DATETIME
)
AS BEGIN
    
    SET @DATAINITIAL = CAST(@DATAINITIAL AS DATE);
    SET @FINALDATE = CAST(CAST(@FINALDATE AS DATE) AS DATETIME) + ' 23:59:59';

    DECLARE @UTCZERO_START DATETIME = DATEADD(HOUR, 3, @DATAINITIAL), @UTCZERO_END DATETIME = DATEADD(HOUR, 3, @FINALDATE);

    CREATE TABLE #TMP_ECS
    (
        COD_EC INT
    )

    INSERT INTO #TMP_ECS (COD_EC)
    SELECT DISTINCT COD_EC
    FROM (
             SELECT DISTINCT RTE.COD_EC
             FROM REPORT_TRANSACTIONS_EXP RTE
             WHERE RTE.TRANSACTION_DATE BETWEEN @DATAINITIAL AND @FINALDATE AND RTE.COD_SITUATION IN (3,14,22)

             UNION

             SELECT DISTINCT RTE.COD_EC
             FROM REPORT_TRANSACTIONS_EXP RTE
             WHERE RTE.COD_SITUATION = 6 AND TRANSACTION_DATE < @DATAINITIAL AND
                 RTE.MODIFY_DATE BETWEEN @UTCZERO_START AND @UTCZERO_END

             UNION

             SELECT DISTINCT RTE.COD_EC
             FROM REPORT_TRANSACTIONS_EXP RTE
             WHERE RTE.COD_SITUATION = 6 AND RTE.TRANSACTION_DATE BETWEEN @DATAINITIAL AND @FINALDATE AND
                     RTE.MODIFY_DATE > @FINALDATE
         ) tmp


    SELECT
        COMMERCIAL_ESTABLISHMENT.COD_EC
         , IIF(LEN(COMMERCIAL_ESTABLISHMENT.CPF_CNPJ) > 11, COMMERCIAL_ESTABLISHMENT.CPF_CNPJ, '') AS CNPJ
         , IIF(LEN(COMMERCIAL_ESTABLISHMENT.CPF_CNPJ) = 11, COMMERCIAL_ESTABLISHMENT.CPF_CNPJ, '') AS CPF
         , COMMERCIAL_ESTABLISHMENT.TRADING_NAME                                                                                            AS NOME_FANTASIA
         , RTRIM(LTRIM(AB.ADDRESS))+','+RTRIM(LTRIM(AB.NUMBER))+'-'+RTRIM(LTRIM(N.NAME))+'-'+RTRIM(LTRIM(C.NAME))+'-'+RTRIM(LTRIM(S.NAME))  AS ENDERECO
         , AB.CEP
         , C.CITY_CODE                                                                                                                      AS MUNICIPIO
         , S.UF                                                                                                                             AS UF
         , USERS.IDENTIFICATION                                                                                                             AS REPRESENTANTE
         , (SELECT TOP 1 CONCAT(CONTACT_BRANCH.DDD, CONTACT_BRANCH.NUMBER)
            FROM CONTACT_BRANCH
            WHERE CONTACT_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH AND CONTACT_BRANCH.ACTIVE = 1)                                           AS NUMBER
         , COMMERCIAL_ESTABLISHMENT.EMAIL
         , CONVERT(VARCHAR(10), COMMERCIAL_ESTABLISHMENT.CREATED_AT, 112)                                                                   AS DATA_REGISTRO
         , (SELECT COUNT(*) FROM REPORT_TRANSACTIONS_EXP RTE WHERE RTE.TRANSACTION_DATE BETWEEN @DATAINITIAL AND @FINALDATE AND RTE.COD_SITUATION IN (3,14,22) AND RTE.COD_EC = TE.COD_EC) [MONTH_TRANSACTIONS]
    FROM COMMERCIAL_ESTABLISHMENT
             INNER JOIN #TMP_ECS TE ON TE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
             INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
             INNER JOIN SALES_REPRESENTATIVE ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
             INNER JOIN USERS ON USERS.COD_USER = SALES_REPRESENTATIVE.COD_USER
             INNER JOIN BRANCH_EC BE ON BE.COD_EC = TE.COD_EC
             INNER JOIN ADDRESS_BRANCH AB ON AB.COD_BRANCH = BE.COD_BRANCH AND AB.ACTIVE = 1
             INNER JOIN NEIGHBORHOOD N ON N.COD_NEIGH = AB.COD_NEIGH
             INNER JOIN CITY C ON C.COD_CITY = N.COD_CITY
             INNER JOIN [STATE] S ON [S].COD_STATE = C.COD_STATE
    WHERE LEN(COMMERCIAL_ESTABLISHMENT.CPF_CNPJ) >= 11

END
GO

IF OBJECT_ID('SP_LS_DIMP_INFO') IS NOT NULL DROP PROCEDURE SP_LS_DIMP_INFO;
GO
CREATE PROCEDURE [dbo].[SP_LS_DIMP_INFO]
/*----------------------------------------------------------------------------------------                                  
   Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
   Author                   VERSION        Date             Description                                  
------------------------------------------------------------------------------------------                                  
   Luiz Aquino              V1             2021-02-04       CREATED   
------------------------------------------------------------------------------------------*/
(
    @DATAINITIAL DATETIME,
    @FINALDATE DATETIME
) WITH RECOMPILE
AS BEGIN

    DECLARE @DATE_PARAM_INIT DATETIME
    DECLARE @DATE_PARAM_FINAL DATETIME

    SET @DATE_PARAM_INIT = @DATAINITIAL
    SET @DATE_PARAM_FINAL = @FINALDATE

    SET @DATAINITIAL = CAST(@DATAINITIAL AS DATE);
    SET @FINALDATE = CAST(CAST(@FINALDATE AS DATE) AS DATETIME) + ' 23:59:59';

    SELECT
        RTE.COD_EC
        , IIF(LEN(RTE.CPF_CNPJ) > 11, RTE.CPF_CNPJ, '') AS CNPJ
        , IIF(LEN(RTE.CPF_CNPJ) = 11, RTE.CPF_CNPJ, '') AS CPF
        , RTE.STATE_NAME
        , CASE WHEN [RTE].COD_SOURCE_TRAN = 1 THEN '2' WHEN [RTE].COD_SOURCE_TRAN = 2 THEN '1' END AS [COD_MEIO_CAPTURA]
        , '0' AS [NUMERO_LOGICO_CAPTURA]
        , CASE WHEN [RTE].COD_SOURCE_TRAN = 1 THEN '4' WHEN [RTE].COD_SOURCE_TRAN = 2 THEN '3' END AS [TIPO_TECNOLOGIA]
        , '1' AS [TERM_PROPRIO]
        , 'AFILIADOR' AS [MARCA]
        , '123' AS [COD_IP_PARCEIRO]
        , @DATE_PARAM_INIT AS [DATA_INICIO]
        , @DATE_PARAM_FINAL AS [DATA_FIM]
        , 0 AS [IND_COMEX]
        , 0 AS [IND_EXTEMP]
        , RTE.AMOUNT
        , RTE.COD_AC
        , RTE.TRANSACTION_CODE [NSU]
        , RTE.TRAN_DATA_EXT_VALUE AS [COD_AUTH]
        , RTE.COD_TRAN AS [ID_TRAN]
        , RTE.SPLIT AS [IND_SPLIT]
        , RTE.BRAND
        , REPLACE(CONVERT(VARCHAR, RTE.TRANSACTION_DATE, 108), ':', '') AS [HORA]
        , CASE WHEN RTE.TRANSACTION_TYPE = 'CREDITO' THEN 1 WHEN RTE.TRANSACTION_TYPE = 'DEBITO' THEN 2 ELSE 9 END AS [NAT_OPE]
        , DAY(RTE.TRANSACTION_DATE) AS [DIA_OPERACAO]
        , CONVERT(VARCHAR, RTE.TRANSACTION_DATE, 112) AS [DATA_TRANSACAO]
    FROM REPORT_TRANSACTIONS_EXP RTE WITH (NOLOCK)
    WHERE TRANSACTION_DATE BETWEEN @DATAINITIAL AND @FINALDATE AND RTE.COD_SITUATION IN (3,14,22)

END
GO

IF OBJECT_ID('SP_LS_ACQUIRER') IS NOT NULL DROP PROCEDURE SP_LS_ACQUIRER;
GO
CREATE PROCEDURE [dbo].[SP_LS_ACQUIRER]
/*----------------------------------------------------------------------------------------            
    Project.......: BACKOFFICE            
------------------------------------------------------------------------------------------            
    Author                      VERSION        Date            Description            
------------------------------------------------------------------------------------------            
    Elir Ribeiro                V1              12/09/2018      Creation            
    Amós Corcino dos Santos     v2              24/10/2018      Update
    Luiz Aquino                 V3              05/02/2021      Add Acq Document (ET-1301)
------------------------------------------------------------------------------------------*/
(
    @ONLY_ACTIVE BIT,
    @LOGICAL_NUMBER INT = NULL
)
AS BEGIN
    DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';
        
    
    SET @QUERY_BASIS =  '
        SELECT      
            COD_AC  
            ,CREATED_AT  
            ,CODE  
            ,NAME AS ACQUIRER_NAME  
            ,COD_USER  
            ,ALIAS  
            ,SUBTITLE  
            ,INTEGRATION  
            ,ACTIVE  
            ,[GROUP]  
            ,LOGICAL_NUMBER  
            ,COD_SEG_GROUP
            ,ACQ_DOCUMENT
        FROM ACQUIRER      
        WHERE ((ACTIVE = 1) OR (ACTIVE = @ONLY_ACTIVE))      
     ';


    IF @LOGICAL_NUMBER IS NOT NULL
        SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND LOGICAL_NUMBER = @LOGICAL_NUMBER ');

    SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' ORDER BY ACQUIRER_NAME ');

    EXEC sp_executesql @QUERY_BASIS
        , N'            
         @ONLY_ACTIVE BIT,            
         @LOGICAL_NUMBER INT      
         '
        , @ONLY_ACTIVE = @ONLY_ACTIVE
        , @LOGICAL_NUMBER = @LOGICAL_NUMBER

END;
go

IF OBJECT_ID('SP_LS_BRAND') IS NOT NULL DROP PROCEDURE SP_LS_BRAND;
GO
CREATE PROCEDURE [dbo].[SP_LS_BRAND]
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author                      VERSION         Date                Description    
------------------------------------------------------------------------------------------    
    Kennedy Alef                V1              27/07/2018          Creation    
------------------------------------------------------------------------------------------*/ 
(
    @COD_COMP INT
)
AS
BEGIN
    SELECT BRAND.[NAME]    AS BRAND
         , COD_BRAND       AS BRANDINSIDECODE
         , COD_TTYPE       AS TRANSACTIONTYPEINSIDECODE
         , [GROUP]         AS BRAND_GROUP
         , TYPE_BRAND.NAME AS 'TYPE_BRAND'
         , AVAILABLE_ONLINE   [AvailableOnline]
         , BRAND.BRAND_EXT_CODE
    FROM BRAND
         INNER JOIN TYPE_BRAND ON TYPE_BRAND.COD_TYPE_BRAND = BRAND.COD_TYPE_BRAND
    WHERE BRAND.VISIBLE = 1;
END
go

IF OBJECT_ID('SP_LS_DIMP_CANCEL_INFO') IS NOT NULL DROP PROCEDURE SP_LS_DIMP_CANCEL_INFO;
GO
CREATE PROCEDURE [dbo].[SP_LS_DIMP_CANCEL_INFO]
/*----------------------------------------------------------------------------------------                                  
   Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
   Author                   VERSION        Date             Description                                  
------------------------------------------------------------------------------------------                                  
   Luiz Aquino              V1             2021-02-04       CREATED   
------------------------------------------------------------------------------------------*/
(
    @DATAINITIAL DATETIME,
    @FINALDATE DATETIME
)
AS BEGIN

    DECLARE @DATE_PARAM_INIT DATETIME
    DECLARE @DATE_PARAM_FINAL DATETIME

    SET @DATE_PARAM_INIT = @DATAINITIAL
    SET @DATE_PARAM_FINAL = @FINALDATE

    SET @DATAINITIAL = DATEADD(HOUR, 3, CAST(CAST(@DATAINITIAL AS DATE) AS DATETIME));
    SET @FINALDATE = DATEADD(HOUR, 3, CAST(CAST(@FINALDATE AS DATE) AS DATETIME) + ' 23:59:59');

    SELECT
        RTE.COD_EC
         , IIF(LEN(RTE.CPF_CNPJ) > 11, RTE.CPF_CNPJ, '') AS CNPJ
         , IIF(LEN(RTE.CPF_CNPJ) = 11, RTE.CPF_CNPJ, '') AS CPF
         , RTE.STATE_NAME
         , CASE WHEN [RTE].COD_SOURCE_TRAN = 1 THEN '2' WHEN [RTE].COD_SOURCE_TRAN = 2 THEN '1' END AS [COD_MEIO_CAPTURA]
         , '0' AS [NUMERO_LOGICO_CAPTURA]
         , CASE WHEN [RTE].COD_SOURCE_TRAN = 1 THEN '4' WHEN [RTE].COD_SOURCE_TRAN = 2 THEN '3' END AS [TIPO_TECNOLOGIA]
         , '1' AS [TERM_PROPRIO]
         , 'AFILIADOR' AS [MARCA]
         , '123' AS [COD_IP_PARCEIRO]
         , @DATE_PARAM_INIT AS [DATA_INICIO]
         , @DATE_PARAM_FINAL AS [DATA_FIM]
         , 0 AS [IND_COMEX]
         , 0 AS [IND_EXTEMP]
         , RTE.AMOUNT
         , RTE.COD_AC
         , RTE.TRANSACTION_CODE [NSU]
         , RTE.TRAN_DATA_EXT_VALUE AS [COD_AUTH]
         , RTE.COD_TRAN AS [ID_TRAN]
         , RTE.SPLIT AS [IND_SPLIT]
         , RTE.BRAND
         , REPLACE(CONVERT(VARCHAR, RTE.TRANSACTION_DATE, 108), ':', '') AS [HORA]
         , CASE WHEN RTE.TRANSACTION_TYPE = 'CREDITO' THEN 1 WHEN RTE.TRANSACTION_TYPE = 'DEBITO' THEN 2 ELSE 9 END AS [NAT_OPE]
         , DAY(RTE.TRANSACTION_DATE) AS [DIA_OPERACAO]
         , CONVERT(VARCHAR, RTE.TRANSACTION_DATE, 112) AS [DATA_TRANSACAO]
         , IIF(RTE.COD_SITUATION = 6, CONVERT(VARCHAR, RTE.MODIFY_DATE, 112), NULL )AS [DATA_CANCELAMENTO]
         , IIF(RTE.COD_SITUATION = 6, RTE.AMOUNT, NULL)  AS [VALOR_CANCELAMENTO]
         , '1' AS [TIPO_CANCELAMENTO]
         , IIF(MONTH(RTE.MODIFY_DATE) <> MONTH(RTE.TRANSACTION_DATE) AND RTE.COD_SITUATION = 6, 3, [RTE].COD_SITUATION) AS [SITUACAO]
         , RTE.COD_SITUATION
    FROM REPORT_TRANSACTIONS_EXP RTE WITH (NOLOCK)
    WHERE TRANSACTION_DATE < @DATE_PARAM_INIT AND RTE.COD_SITUATION = 6 AND MODIFY_DATE BETWEEN @DATAINITIAL AND @FINALDATE

END
GO

IF OBJECT_ID('SP_LS_DIMP_CANCELED_LATER_INFO') IS NOT NULL 
    DROP PROCEDURE SP_LS_DIMP_CANCELED_LATER_INFO;
GO
CREATE PROCEDURE [dbo].[SP_LS_DIMP_CANCELED_LATER_INFO]
/*----------------------------------------------------------------------------------------                                  
   Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
   Author                   VERSION        Date             Description                                  
------------------------------------------------------------------------------------------                                  
   Luiz Aquino              V1             2021-02-23       CREATED   
------------------------------------------------------------------------------------------*/
(
    @DATAINITIAL DATETIME,
    @FINALDATE DATETIME
)
AS BEGIN
    --Transações que foram canceladas depois da data final
    
    DECLARE @DATE_PARAM_INIT DATETIME, @DATE_PARAM_FINAL DATETIME

    SET @DATE_PARAM_INIT = @DATAINITIAL
    SET @DATE_PARAM_FINAL = @FINALDATE

    SET @DATAINITIAL = CAST(@DATAINITIAL AS DATE);
    SET @FINALDATE = CAST(CAST(@FINALDATE AS DATE) AS DATETIME) + ' 23:59:59';
    
    SELECT
        RTE.COD_EC
         , IIF(LEN(RTE.CPF_CNPJ) > 11, RTE.CPF_CNPJ, '') AS CNPJ
         , IIF(LEN(RTE.CPF_CNPJ) = 11, RTE.CPF_CNPJ, '') AS CPF
         , RTE.STATE_NAME
         , CASE WHEN [RTE].COD_SOURCE_TRAN = 1 THEN '2' WHEN [RTE].COD_SOURCE_TRAN = 2 THEN '1' END AS [COD_MEIO_CAPTURA]
         , '0' AS [NUMERO_LOGICO_CAPTURA]
         , CASE WHEN [RTE].COD_SOURCE_TRAN = 1 THEN '4' WHEN [RTE].COD_SOURCE_TRAN = 2 THEN '3' END AS [TIPO_TECNOLOGIA]
         , '1' AS [TERM_PROPRIO]
         , 'AFILIADOR' AS [MARCA]
         , '123' AS [COD_IP_PARCEIRO]
         , @DATE_PARAM_INIT AS [DATA_INICIO]
         , @DATE_PARAM_FINAL AS [DATA_FIM]
         , 0 AS [IND_COMEX]
         , 0 AS [IND_EXTEMP]
         , RTE.AMOUNT
         , RTE.COD_AC
         , RTE.TRANSACTION_CODE [NSU]
         , RTE.TRAN_DATA_EXT_VALUE AS [COD_AUTH]
         , RTE.COD_TRAN AS [ID_TRAN]
         , RTE.SPLIT AS [IND_SPLIT]
         , RTE.BRAND
         , REPLACE(CONVERT(VARCHAR, RTE.TRANSACTION_DATE, 108), ':', '') AS [HORA]
         , CASE WHEN RTE.TRANSACTION_TYPE = 'CREDITO' THEN 1 WHEN RTE.TRANSACTION_TYPE = 'DEBITO' THEN 2 ELSE 9 END AS [NAT_OPE]
         , DAY(RTE.TRANSACTION_DATE) AS [DIA_OPERACAO]
         , CONVERT(VARCHAR, RTE.TRANSACTION_DATE, 112) AS [DATA_TRANSACAO]
    FROM REPORT_TRANSACTIONS_EXP RTE WITH (NOLOCK)
    WHERE TRANSACTION_DATE BETWEEN @DATAINITIAL AND @FINALDATE AND RTE.COD_SITUATION = 6 AND MODIFY_DATE > @FINALDATE

END
GO

IF OBJECT_ID('DIMP_HISTORY') IS NULL BEGIN
    CREATE TABLE DIMP_HISTORY
    (
        COD_DIMP_HIST INT NOT NULL PRIMARY KEY IDENTITY,
        CREATED_AT DATETIME NOT NULL DEFAULT(GETDATE()),
        STATUS VARCHAR(128) NOT NULL DEFAULT ('Na fila de processamento'),
        REFERENCE_DATE DATE NOT NULL,
        SUCCESS INT NOT NULL DEFAULT(0),
        FILE_LINK VARCHAR(128) NULL,
        COD_USER INT NULL REFERENCES USERS(COD_USER),
        ERROR_MESSAGE VARCHAR(256) NULL
    )
END

IF OBJECT_ID('SP_REG_DIMP_HIST') IS NOT NULL DROP PROCEDURE SP_REG_DIMP_HIST;
GO
CREATE PROCEDURE [dbo].[SP_REG_DIMP_HIST]
(
   @RefDate DATE,
   @CodUser INT   
) AS BEGIN

    INSERT INTO DIMP_HISTORY (REFERENCE_DATE, COD_USER)
    VALUES(@RefDate, @CodUser)
    
    DECLARE @CODHIST INT = SCOPE_IDENTITY()
    
    SELECT
        DH.COD_DIMP_HIST,
        DH.CREATED_AT,
        DH.STATUS,
        DH.REFERENCE_DATE,
        DH.SUCCESS,
        DH.FILE_LINK,
        DH.COD_USER,
        DH.ERROR_MESSAGE,
        U.COD_ACCESS
    FROM DIMP_HISTORY DH (NOLOCK )
        LEFT JOIN USERS U (NOLOCK ) ON DH.COD_USER = U.COD_USER
    WHERE DH.COD_DIMP_HIST = @CODHIST
END
GO


IF OBJECT_ID('SP_UP_DIMP_HIST') IS NOT NULL DROP PROCEDURE SP_UP_DIMP_HIST;
GO
CREATE PROCEDURE [dbo].[SP_UP_DIMP_HIST]
(
    @CodHist INT,
    @Status VARCHAR(128),
    @Success INT,
    @FileLink VARCHAR(128),
    @ErrorMessage VARCHAR(256)    
) AS BEGIN

    UPDATE DIMP_HISTORY
    SET STATUS = @Status,
        SUCCESS = @Success,
        FILE_LINK = @FileLink,
        ERROR_MESSAGE = @ErrorMessage
    WHERE COD_DIMP_HIST = @CodHist
END
GO

IF OBJECT_ID('SP_DIMP_HIST') IS NOT NULL DROP PROCEDURE SP_DIMP_HIST;
GO
CREATE PROCEDURE [dbo].[SP_DIMP_HIST]
(
    @Page INT = 1,
    @PageSize INT = 10,
    @Total INT OUTPUT 
) AS BEGIN
  
    DECLARE @SKIP INT = (@Page -1) * @PageSize;
    
    SELECT @Total = COUNT(*) FROM DIMP_HISTORY 
    
    SELECT
        DH.COD_DIMP_HIST,
        DH.CREATED_AT,
        DH.STATUS,
        DH.REFERENCE_DATE,
        DH.SUCCESS,
        DH.FILE_LINK,
        DH.COD_USER,
        DH.ERROR_MESSAGE,
        U.COD_ACCESS
    FROM DIMP_HISTORY DH (NOLOCK )
        LEFT JOIN USERS U (NOLOCK ) ON DH.COD_USER = U.COD_USER
    ORDER BY COD_DIMP_HIST DESC
    OFFSET @SKIP ROWS FETCH NEXT @PageSize ROWS ONLY
        
END
GO

IF OBJECT_ID('SP_LS_ALL_BRANDS') IS NOT NULL
    DROP PROCEDURE SP_LS_ALL_BRANDS
GO
CREATE PROCEDURE [dbo].[SP_LS_ALL_BRANDS]
/*----------------------------------------------------------------------------------------    
    Project.......: TKPP    
------------------------------------------------------------------------------------------    
    Author                      VERSION         Date                Description    
------------------------------------------------------------------------------------------    
    Kennedy Alef                V1              27/07/2018          Creation    
------------------------------------------------------------------------------------------*/
(
    @COD_COMP INT
)
AS
BEGIN
    SELECT BRAND.[NAME]    AS BRAND
         , COD_BRAND       AS BRANDINSIDECODE
         , COD_TTYPE       AS TRANSACTIONTYPEINSIDECODE
         , [GROUP]         AS BRAND_GROUP
         , TYPE_BRAND.NAME AS 'TYPE_BRAND'
         , AVAILABLE_ONLINE   [AvailableOnline]
         , BRAND.BRAND_EXT_CODE
    FROM BRAND
             INNER JOIN TYPE_BRAND ON TYPE_BRAND.COD_TYPE_BRAND = BRAND.COD_TYPE_BRAND
    ;
END
go


ALTER SEQUENCE SEQ_DIMP_FILE RESTART WITH 26

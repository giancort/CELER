
IF OBJECT_ID('TEF_CONCILIATE_FILE') IS NOT NULL
	DROP TABLE TEF_CONCILIATE_FILE
GO
CREATE TABLE TEF_CONCILIATE_FILE
(
    COD_TEF_CONC_FILE           INT             PRIMARY KEY IDENTITY(1,1),
    FILE_NAME                   VARCHAR(255),
    INSERT_DATE                 DATETIME,
    PROCESS_INITIAL             DATETIME,
    PROCESS_FINAL               DATETIME,
    COD_SITUATION               INT             FOREIGN KEY REFERENCES SITUATION (COD_SITUATION),
    DATES_TRANSACTIONS          VARCHAR(200),
    QTY_TRANSACTIONS_INSERT     INT,
    QTY_TRANSACTIONS_CANCELED   INT,
    COD_USER                    INT             FOREIGN KEY REFERENCES USERS (COD_USER)
)

GO

IF OBJECT_ID('TEF_TRANSACTIONS_CONCILIATE') IS NOT NULL
	DROP TABLE TEF_TRANSACTIONS_CONCILIATE
GO
CREATE TABLE TEF_TRANSACTIONS_CONCILIATE (
	COD_TEF_TRANSACTIONS_CONC INT PRIMARY KEY IDENTITY(1,1),
    COD_TEF_CONC_FILE INT FOREIGN KEY REFERENCES TEF_CONCILIATE_FILE (COD_TEF_CONC_FILE),
    [SERIAL] VARCHAR(200),
    TRAN_TYPE VARCHAR(200),
    AMOUNT DECIMAL(22,6),
    INSTALLMENTS INT,
    BRAND VARCHAR(200),
    PAN VARCHAR(255),
    CARD_HOLDER_NAME VARCHAR(200),
    AUTH_CODE VARCHAR(100),
    NSU_EXT VARCHAR(200),
    [STATUS] VARCHAR(200),
    COD_AFFILIATOR INT FOREIGN KEY REFERENCES AFFILIATOR (COD_AFFILIATOR),
    COD_AC INT FOREIGN KEY REFERENCES ACQUIRER (COD_AC),
    COD_COMP INT FOREIGN KEY REFERENCES COMPANY (COD_COMP),
    [TYPE] VARCHAR(150),
    COD_USER INT FOREIGN KEY REFERENCES USERS (COD_USER),
    CONCILIATED INT DEFAULT 0,
    COD_SITUATION FOREIGN KEY REFERENCES SITUATION (COD_SITUATION)
);

GO

IF OBJECT_ID('SP_REG_TEF_CONCILIATE_FILE') IS NOT NULL DROP PROCEDURE SP_REG_TEF_CONCILIATE_FILE
GO
CREATE PROCEDURE SP_REG_TEF_CONCILIATE_FILE
(                
    @FILE_NAME                   VARCHAR(255),
    @DATES_TRANSACTIONS          VARCHAR(200),
    @QTY_TRANSACTIONS_INSERT     INT,
    @QTY_TRANSACTIONS_CANCELED   INT,
)
AS
BEGIN

    INSERT INTO TEF_CONCILIATE_FILE
    (
        [FILE_NAME],
        DATES_TRANSACTIONS,
        QTY_TRANSACTIONS_INSERT,
        QTY_TRANSACTIONS_CANCELED
    )
    VALUES
    (
        @FILE_NAME,
        @DATES_TRANSACTIONS,
        @QTY_TRANSACTIONS_INSERT,
        QTY_TRANSACTIONS_CANCELED
    );

    IF @@rowcount < 1
		THROW 70020, 'COULD NOT REGISTER TEF_CONCILIATE_FILE. Parameter name: 70020', 1;


END;

GO

GO
CREATE PROCEDURE GLOBAL_EDI_REPORT
/*----------------------------------------------------------------------------------------                        
    Project.......: TKPP                        
-------------------------------------------------------------------------------------------                        
    Author              VERSION       Date                Description                        
------------------------------------------  ------------------------------------------------                        
    Luiz Aquino           v1          2020-12-02          CREATED                        
 ------------------------------------------------------------------------------------------*/
(
    @Filters GFilterType READONLY
) AS BEGIN

    SET NOCOUNT ON;
    SET ARITHABORT ON;
    
    DECLARE @EC_DATE AS TABLE(COD_EC INT, TRAN_DATE DATETIME, TRAN_DATE_END DATETIME, COD_COMP INT )

    INSERT INTO @EC_DATE (COD_EC, TRAN_DATE, TRAN_DATE_END, COD_COMP)
    SELECT COD_EC,
           CAST(F.TRAN_DATE AS DATETIME) TRAN_DATE, DATEADD(SECOND , -1, DATEADD(DAY, 1, CAST(F.TRAN_DATE AS DATETIME))) TRAN_DATE_END,
           CE.COD_COMP
    FROM COMMERCIAL_ESTABLISHMENT CE
             JOIN @Filters F ON f.CPF_CNPJ = CE.CPF_CNPJ

    SELECT CPF_CNPJ,
           AUTH_CODE,
           TRANSACTION_CODE [NSU],
           TRAN_DATA_EXT_VALUE [NSU_EXT],
           PAN,
           BRAND,
           TRANSACTION_TYPE,
           TRANSACTION_DATE,
           AMOUNT,
           PLOTS,
           SITUATION,
           COD_TRAN
    FROM @EC_DATE ED
             JOIN [REPORT_TRANSACTIONS_EXP] RTE ON RTE.COD_COMP = ED.COD_COMP AND
                                                   RTE.COD_EC = ED.COD_EC AND
                                                   RTE.TRANSACTION_DATE BETWEEN TRAN_DATE AND TRAN_DATE_END
    ORDER BY RTE.COD_EC, TRAN_DATE
END
GO

INSERT INTO EQUIPMENT_MODEL (CODIGO, TIPO, COD_MODEL_GROUP, ONLINE) 
VALUES('TEF', 'TEF', 3, 1)
GO

UPDATE E
SET COD_MODEL = 9
FROM COMMERCIAL_ESTABLISHMENT CE
JOIN BRANCH_EC BE ON BE.COD_EC = CE.COD_EC 
JOIN DEPARTMENTS_BRANCH DB ON BE.COD_BRANCH = DB.COD_BRANCH
JOIN ASS_DEPTO_EQUIP ADE ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH AND ADE.ACTIVE = 1
JOIN EQUIPMENT E ON E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1 AND LEN(E.SERIAL) = 15
where CE.COD_AFFILIATOR in (308, 303) 
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('SERVICES_AVAILABLE') AND name='IX_SERVICE_ACTIVE_AFF_EC')  BEGIN
    CREATE NONCLUSTERED INDEX IX_SERVICE_ACTIVE_AFF_EC ON [dbo].[SERVICES_AVAILABLE] ([COD_AFFILIATOR],[COD_EC],[ACTIVE])
END
GO


IF OBJECT_ID('SP_GLOBAL_TEF_CONSOLIDATE') IS NOT NULL
    DROP PROCEDURE  SP_GLOBAL_TEF_CONSOLIDATE
GO
IF TYPE_ID('TEF_CONSOLIDATE_TP') IS NOT NULL
    DROP TYPE TEF_CONSOLIDATE_TP
GO
CREATE TYPE TEF_CONSOLIDATE_TP AS TABLE
(
    DOCUMENT VARCHAR(15) NOT NULL ,
    NSU VARCHAR (12) NOT NULL ,
    TRAN_DATE DATETIME NOT NULL ,
    TRAN_TYPE VARCHAR(8) NOT NULL ,
    AMOUNT DECIMAL(11,2) NOT NULL ,
    PAN VARCHAR(19) NOT NULL ,
    INSTALLMENTS INT NOT NULL ,
    AUTH_CODE VARCHAR(12) NOT NULL ,
    BRAND VARCHAR(12) NOT NULL,
    TerminalId VARCHAR(8) NOT NULL
)
GO
IF OBJECT_ID('SP_GLOBAL_TEF_CONSOLIDATE') IS NOT NULL DROP PROCEDURE SP_GLOBAL_TEF_CONSOLIDATE
GO
CREATE PROCEDURE SP_GLOBAL_TEF_CONSOLIDATE
/*----------------------------------------------------------------------------------------                        
    Project.......: TKPP                        
-------------------------------------------------------------------------------------------                        
    Author              VERSION       Date                Description                        
-------------------------------------------------------------------------------------------                        
    Luiz Aquino           v1          2020-12-02          CREATED                        
------------------------------------------------------------------------------------------*/
(
    @ToUpdate TEF_CONSOLIDATE_TP READONLY 
)
AS BEGIN
    
    SET NOCOUNT ON;
    SET ARITHABORT ON;

    DECLARE @Transactions REG_TEF_TP, @CodTefModel INT;
    
    SELECT @CodTefModel=  COD_MODEL FROM EQUIPMENT_MODEL WHERE CODIGO = 'TEF'

    SELECT T.TerminalId,
           (SELECT TOP 1 E.SERIAL FROM ASS_DEPTO_EQUIP ADE
                                           JOIN EQUIPMENT E ON E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1 AND E.COD_MODEL = @CodTefModel
            WHERE DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH AND ADE.ACTIVE = 1) SERIAL,
           T.TRAN_TYPE,
           T.AMOUNT,
           T.INSTALLMENTS,
           T.BRAND,
           T.PAN,
           T.AUTH_CODE,
           T.NSU,
           'Authorized' [Status],
           CE.COD_AFFILIATOR,
           (SELECT COD_AC FROM ACCESS_TEF_API ATP WHERE ATP.COD_AFFILIATOR = CE.COD_AFFILIATOR) COD_AC,
           CE.COD_COMP,
           'TRANSACTION' [Type],
           ROW_NUMBER() OVER (PARTITION BY AUTH_CODE, CE.CPF_CNPJ ORDER BY CE.COD_AFFILIATOR DESC) RNUM
    INTO #Processed
    FROM COMMERCIAL_ESTABLISHMENT CE
             JOIN @ToUpdate T ON T.DOCUMENT = CE.CPF_CNPJ
             JOIN BRANCH_EC BE ON BE.COD_EC = CE.COD_EC
             JOIN DEPARTMENTS_BRANCH DB ON BE.COD_BRANCH = DB.COD_BRANCH
             LEFT JOIN ACCESS_TEF_API ATP ON ATP.COD_AFFILIATOR = CE.COD_AFFILIATOR
    WHERE EXISTS(SELECT E.COD_EQUIP FROM ASS_DEPTO_EQUIP ADE
                                             JOIN EQUIPMENT E ON E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1 AND E.COD_MODEL = @CodTefModel
                 WHERE DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH AND ADE.ACTIVE = 1)
        
    INSERT INTO @Transactions (TerminalId, MerchantId, TransactionType, Amount, Installments, Brand, CardNumber, CardHolderName, AuthCode, ExternalNSU, Status, CodAffiliated, CodAc, CodComp, Type)
    SELECT TerminalId,
           SERIAL,
           TRAN_TYPE, 
           AMOUNT,
           INSTALLMENTS,
           BRAND,
           PAN, 
           NULL [CardHolderName],
           AUTH_CODE,
           NSU,
           Status,
           COD_AFFILIATOR,
           COD_AC,
           COD_COMP,
           Type
    FROM #Processed P
    WHERE P.RNUM = 1
       
    DECLARE @Result TABLE (ExternalNSU VARCHAR(64), COD_TRAN INT, VALID INT, ERROR_CODE VARCHAR(64), DUPLICATED INT)
    
    INSERT INTO @Result EXEC SP_REG_TEF_TRANSACTION @Transactions = @Transactions
    
    UPDATE T    
    SET CREATED_AT =  CONVERT(DATETIME, SWITCHOFFSET(U.TRAN_DATE, 180)),
        BRAZILIAN_DATE = U.TRAN_DATE
    FROM [TRANSACTION] T
        JOIN @Result R ON T.COD_TRAN = R.COD_TRAN
        JOIN @ToUpdate U ON U.NSU = R.ExternalNSU
    
    SELECT ExternalNSU, COD_TRAN, VALID, ERROR_CODE, DUPLICATED FROM @Result
    
END
GO


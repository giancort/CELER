-----------------------------
-- ET-465 Gestão de Risco
-----------------------------


IF NOT EXISTS (SELECT
		1
	FROM [sys].[COLUMNS]
	WHERE [NAME] = N'OPERATION_AFF'
	AND object_id = OBJECT_ID(N'[AFFILIATOR]'))
BEGIN
ALTER TABLE AFFILIATOR
ADD OPERATION_AFF INT DEFAULT 0;
END;

UPDATE AFFILIATOR
SET OPERATION_AFF = 0
WHERE OPERATION_AFF IS NULL
GO

IF OBJECT_ID('SP_VAL_OPERATION_AFF') IS NOT NULL DROP PROCEDURE SP_VAL_OPERATION_AFF;
GO
CREATE PROCEDURE SP_VAL_OPERATION_AFF
(
@COD_AFILIATOR INT
)
AS
BEGIN

SELECT
	OPERATION_AFF
FROM AFFILIATOR
WHERE COD_AFFILIATOR = @COD_AFILIATOR;

END;

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'REQUESTED_PRESENTIAL_TRANSACTION' AND [OBJECT_ID] = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT'))
BEGIN
    ALTER TABLE COMMERCIAL_ESTABLISHMENT
    ADD REQUESTED_PRESENTIAL_TRANSACTION INT NOT NULL DEFAULT 1
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'REQUESTED_ONLINE_TRANSACTION' AND [OBJECT_ID] = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT'))
BEGIN
    ALTER TABLE COMMERCIAL_ESTABLISHMENT
    ADD REQUESTED_ONLINE_TRANSACTION INT NOT NULL DEFAULT 1
END

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'COD_USER_MODIFY' AND [OBJECT_ID] = OBJECT_ID(N'DOCS_BRANCH'))
BEGIN
	ALTER TABLE DOCS_BRANCH
	ADD COD_USER_MODIFY INT NULL REFERENCES USERS (COD_USER)
END
GO

IF (OBJECT_ID('[FNC_REG_DENIED_TRAN]') IS NOT NULL)
    DROP function [FNC_REG_DENIED_TRAN]
GO

CREATE FUNCTION [dbo].[FNC_REG_DENIED_TRAN]
(
    @TRAN_ONLINE INT,
    @TRAN_LIMIT DECIMAL(22, 6),
    @TRAN_AMOUNT DECIMAL(22, 6),
    @COD_TAX_DEP INT,
    @EQUIP_ACTIVE INT,
    @EC_ACTIVE INT,
    @COD_EC INT
)
RETURNS VARCHAR(200)
AS
BEGIN
    DECLARE @MSG VARCHAR(200) = null

    IF @TRAN_ONLINE = 0
        BEGIN
            SET @MSG = '402;Transaction Online is disable'
            RETURN @MSG;
        END

    IF @TRAN_AMOUNT > @TRAN_LIMIT
        BEGIN
            SET @MSG = '402;Transaction limit value exceeded"d'
            RETURN @MSG;
        END

    IF @COD_TAX_DEP IS NULL
        BEGIN
            SET @MSG = '404;Plan tax/Not found '
            RETURN @MSG;
        END;

    IF @EQUIP_ACTIVE = 0
        BEGIN
            SET @MSG = '003;Blocked terminal'
            RETURN @MSG;
        END;

    IF @EC_ACTIVE = 0
        BEGIN
            SET @MSG = '009;Blocked commercial establishment'
            RETURN @MSG;
        END;

    SELECT @MSG = dbo.[SP_VAL_LIMIT_EC_FNC](@COD_EC, @TRAN_AMOUNT)
    return @MSG;


END;
GO


IF OBJECT_ID('ESTABLISHMENT_CONDITIONS') IS NOT NULL
    DROP TABLE [ESTABLISHMENT_CONDITIONS];
GO
CREATE TABLE [ESTABLISHMENT_CONDITIONS](
	[COD_EC_CONDIT]          INT IDENTITY PRIMARY KEY, 
	[COD_COMP]               INT NOT NULL, 
	[COD_USER]               INT NOT NULL, 
	[COD_EC]                 INT NOT NULL, 
	[CREATED_AT]             DATETIME DEFAULT CURRENT_TIMESTAMP, 
	[MODIFY_DATE]            DATETIME, 
	[ACTIVE]                 INT DEFAULT 1, 
	[PRESENCIAL_TRANSACTION] INT NOT NULL, 
	[ONLINE_TRANSACTION]     INT NOT NULL, 
	[DOCUMENT]               INT NOT NULL, 
	FOREIGN KEY([COD_COMP]) REFERENCES [COMPANY]([COD_COMP]), 
	FOREIGN KEY([COD_USER]) REFERENCES [USERS]([COD_USER]), 
	FOREIGN KEY([COD_EC]) REFERENCES [COMMERCIAL_ESTABLISHMENT]([COD_EC]));

GO

IF OBJECT_ID('ESTABLISHMENT_CONDITIONS_HIST') IS NOT NULL
    DROP TABLE [ESTABLISHMENT_CONDITIONS_HIST];
GO
CREATE TABLE [ESTABLISHMENT_CONDITIONS_HIST](
	[COD_EC_CONDIT]          INT PRIMARY KEY, 
	[COD_COMP]               INT NOT NULL, 
	[COD_USER]               INT NOT NULL, 
	[COD_EC]                 INT NOT NULL, 
	[CREATED_AT]             DATETIME DEFAULT CURRENT_TIMESTAMP, 
	[MODIFY_DATE]            DATETIME, 
	[ACTIVE]                 INT DEFAULT 1, 
	[PRESENCIAL_TRANSACTION] INT NOT NULL, 
	[ONLINE_TRANSACTION]     INT NOT NULL, 
	[DOCUMENT]               INT NOT NULL, 
	FOREIGN KEY([COD_COMP]) REFERENCES [COMPANY]([COD_COMP]), 
	FOREIGN KEY([COD_USER]) REFERENCES [USERS]([COD_USER]), 
	FOREIGN KEY([COD_EC]) REFERENCES [COMMERCIAL_ESTABLISHMENT]([COD_EC]));
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('ESTABLISHMENT_CONDITIONS') AND name='IDX_ESTAB_COND_EC')
BEGIN    
    CREATE NONCLUSTERED INDEX IDX_ESTAB_COND_EC ON ESTABLISHMENT_CONDITIONS ( COD_EC, ACTIVE ) INCLUDE (PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION)    
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('ESTABLISHMENT_CONDITIONS') AND name='IDX_ESTAB_COND_COMP_EC')
BEGIN
    CREATE NONCLUSTERED INDEX IDX_ESTAB_COND_COMP_EC ON ESTABLISHMENT_CONDITIONS ( COD_COMP, COD_EC, ACTIVE ) INCLUDE (PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION)
END
GO

IF OBJECT_ID('SP_REG_ESTABLISHMENT_CONDITIONS') IS NOT NULL
    DROP PROCEDURE [SP_REG_ESTABLISHMENT_CONDITIONS];
GO
CREATE PROCEDURE [DBO].[SP_REG_ESTABLISHMENT_CONDITIONS]

/************************************************************************************************
---------------------------------------------------------------------------------------------
    Project.......: TKPP
-----------------------------------------------------------------------------------------------
    Author                      VERSION         Date                        Description
-----------------------------------------------------------------------------------------------
    Lucas Aguiar			    v1		     2020-02-12			 Procedure para o registro das condições
    Luiz Aquino                 V2           2020-03-16          Adicionar bloqueio da agenda
    Luiz Aquino                 V2           2020-03-17          Adicionar campos
    Marcus Gall					v3 			 2020-04-28			 Aprovação/Envio para Análise de todos os docs
************************************************************************************************/

(
	@COD_EC                 INT,
	@COD_COMP               INT,
	@COD_USER               INT,
	@PRESENCIAL_TRANSACTION INT,
	@ONLINE_TRANSACTION     INT,
	@DOCUMENT               INT,
    @RequestedOnlineTransaction INT = NULL,
    @RequestedPresentialTransaction INT = NULL,
    @KEEP_SITUATION INT = NULL
)
AS
BEGIN
    DECLARE @COD_RISK INT
    DECLARE @COD_SIT INT
    DECLARE @JUSTIFY_FINANCE VARCHAR(500)
    DECLARE @JUSTIFY_RISC VARCHAR(500)
    DECLARE @COD_SIT_FIN_BLOCK INT
    DECLARE @COD_SIT_RELEASED INT
    DECLARE @DEFAULT_BLOCK_MESSAGE VARCHAR(64) = 'Pendente aprovação dos documentos'
    DECLARE @COD_BRANCH INT
    DECLARE @COD_SIT_DOC INT
    DECLARE @COMMENT VARCHAR(500)

    SELECT @COD_SIT_FIN_BLOCK = COD_SITUATION FROM SITUATION WHERE NAME = 'LOCKED FINANCIAL SCHEDULE'
    SELECT @COD_SIT_RELEASED = COD_SITUATION FROM SITUATION WHERE NAME = 'RELEASED'

    IF @KEEP_SITUATION IS NULL
    BEGIN
	    IF @DOCUMENT = 0 AND EXISTS(SELECT TOP 1 COD_EC FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC AND COD_SITUATION = @COD_SIT_RELEASED ) BEGIN
	        SELECT @COD_RISK = COD_RISK_SITUATION, @COD_SIT = COD_SITUATION, @JUSTIFY_FINANCE= NOTE_FINANCE_SCHEDULE, @JUSTIFY_RISC = RISK_REASON
	        FROM COMMERCIAL_ESTABLISHMENT
	        WHERE COD_EC = @COD_EC AND COD_COMP = @COD_COMP

	        EXEC SP_UP_EC_SITUATION @COD_EC, @COD_USER, @COD_RISK, 1, @DEFAULT_BLOCK_MESSAGE, @JUSTIFY_RISC
	    END
	    ELSE IF EXISTS(SELECT TOP 1 COD_EC FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC AND COD_SITUATION = @COD_SIT_FIN_BLOCK AND NOTE_FINANCE_SCHEDULE = @DEFAULT_BLOCK_MESSAGE ) BEGIN
	        SELECT @COD_RISK = COD_RISK_SITUATION, @COD_SIT = COD_SITUATION, @JUSTIFY_FINANCE= NOTE_FINANCE_SCHEDULE, @JUSTIFY_RISC = RISK_REASON
	        FROM COMMERCIAL_ESTABLISHMENT
	        WHERE COD_EC = @COD_EC AND COD_COMP = @COD_COMP

	        EXEC SP_UP_EC_SITUATION @COD_EC, @COD_USER, @COD_RISK, 0, NULL, @JUSTIFY_RISC
	    END

		IF @RequestedPresentialTransaction IS NOT NULL
		BEGIN
			UPDATE COMMERCIAL_ESTABLISHMENT SET REQUESTED_PRESENTIAL_TRANSACTION = @RequestedPresentialTransaction
			WHERE COD_EC = @COD_EC
		END

		IF @RequestedOnlineTransaction IS NOT NULL
		BEGIN
			UPDATE COMMERCIAL_ESTABLISHMENT SET REQUESTED_ONLINE_TRANSACTION = @RequestedOnlineTransaction
			WHERE COD_EC = @COD_EC
		END
	END

    INSERT INTO ESTABLISHMENT_CONDITIONS_HIST (COD_EC_CONDIT, COD_COMP, COD_USER, COD_EC, CREATED_AT, MODIFY_DATE, ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT)
    SELECT COD_EC_CONDIT, COD_COMP, COD_USER, COD_EC, CREATED_AT, CURRENT_TIMESTAMP, ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT
    FROM ESTABLISHMENT_CONDITIONS
    WHERE [COD_EC] = @COD_EC
		AND [COD_COMP] = @COD_COMP
		AND [ACTIVE] = 1;

    DELETE FROM ESTABLISHMENT_CONDITIONS
    WHERE [COD_EC] = @COD_EC
		AND [COD_COMP] = @COD_COMP
		AND [ACTIVE] = 1;

    INSERT INTO [ESTABLISHMENT_CONDITIONS]
    (
        [COD_USER],
        [COD_COMP],
        [COD_EC],
        [PRESENCIAL_TRANSACTION],
        [ONLINE_TRANSACTION],
        [DOCUMENT]
    )
    VALUES
    (
	    @COD_USER,
	    @COD_COMP,
	    @COD_EC,
	    @PRESENCIAL_TRANSACTION,
	    @ONLINE_TRANSACTION,
	    @DOCUMENT
     );

	-- APROVAR / ANALISAR TODOS DOCUMENTOS
    IF @KEEP_SITUATION IS NOT NULL
    BEGIN
		SELECT @COD_BRANCH = COD_BRANCH FROM BRANCH_EC WHERE COD_EC = @COD_EC;

		IF @DOCUMENT = 0 AND EXISTS(SELECT TOP 1 COD_DOC_BR FROM DOCS_BRANCH WHERE ACTIVE = 1 AND COD_BRANCH = @COD_BRANCH) BEGIN
			SELECT @COD_SIT_DOC = COD_SIT_REQ FROM SITUATION_REQUESTS WHERE TYPE = 'DOC' AND NAME = 'EM ANÁLISE';
			SELECT @COMMENT = 'Todos os documentos enviados para análise';
		END
		ELSE IF EXISTS(SELECT 1 COD_DOC_BR FROM DOCS_BRANCH WHERE ACTIVE = 1 AND COD_BRANCH = @COD_BRANCH AND PATH_DOC IS NOT NULL) BEGIN
			SELECT @COD_SIT_DOC = COD_SIT_REQ FROM SITUATION_REQUESTS WHERE TYPE = 'DOC' AND NAME = 'APROVADO';
			SELECT @COMMENT = 'Todos os documentos foram aprovados';
		END

		INSERT INTO HIST_SIT_DOCS_BRANCH (COD_DOC_BR, COD_USER, COD_SIT_REQ) 
		SELECT COD_DOC_BR, COD_USER, COD_SIT_REQ FROM DOCS_BRANCH WHERE ACTIVE = 1 AND COD_BRANCH = @COD_BRANCH AND PATH_DOC IS NOT NULL;
		IF @@rowcount < 1
			THROW 60000, 'COULD NOT REGISTER HIST_SIT_DOCS_BRANCH', 1;
    
		UPDATE DOCS_BRANCH SET COD_SIT_REQ = @COD_SIT_DOC, MODIFY_DATE = GETDATE(), COD_USER_MODIFY = @COD_USER, COMMENT = @COMMENT 
		WHERE ACTIVE = 1 AND COD_BRANCH = @COD_BRANCH AND PATH_DOC IS NOT NULL;
		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE DOCS_BRANCH', 1;
	END
	-- APROVAR / ANALISAR TODOS DOCUMENTOS

END;

GO

IF OBJECT_ID('[SP_FD_ESTABLISHMENT_CONDITIONS]') IS NOT NULL
    DROP PROCEDURE [SP_FD_ESTABLISHMENT_CONDITIONS];
GO

CREATE PROCEDURE [DBO].[SP_FD_ESTABLISHMENT_CONDITIONS]  

/************************************************************************************************
---------------------------------------------------------------------------------------------  
    Project.......: TKPP  
-----------------------------------------------------------------------------------------------  
    Author                        VERSION         Date                        Description  
-----------------------------------------------------------------------------------------------  
    Lucas Aguiar			    v1		     2020-02-12			 Procedure para o busca das condições
************************************************************************************************/

(
	@COD_EC   INT, 
	@COD_COMP INT)
AS
BEGIN

    SELECT [ESTABLISHMENT_CONDITIONS].[COD_EC_CONDIT], 
		 [ESTABLISHMENT_CONDITIONS].[COD_EC], 
		 [ESTABLISHMENT_CONDITIONS].[DOCUMENT], 
		 [ESTABLISHMENT_CONDITIONS].[ONLINE_TRANSACTION], 
		 [ESTABLISHMENT_CONDITIONS].[PRESENCIAL_TRANSACTION]
    FROM [ESTABLISHMENT_CONDITIONS]
    WHERE [COD_COMP] = @COD_COMP
		AND [COD_EC] = @COD_EC
		AND [ACTIVE] = 1;

END;  

GO



IF OBJECT_ID('[SP_LS_DOCS]') IS NOT NULL
    DROP PROCEDURE [SP_LS_DOCS];
GO

CREATE PROCEDURE [DBO].[SP_LS_DOCS]          

/*************************************************************************************************
----------------------------------------------------------------------------------------        
Procedure Name: [SP_LS_DOCS]        
Project.......: TKPP        
------------------------------------------------------------------------------------------        
Author                          VERSION        Date                            Description        
------------------------------------------------------------------------------------------        
Lucas Aguiar     V1    05/10/2018      Creation        
Gian Luca Dalle Cort   V1    15/10/2018      Changed        
------------------------------------------------------------------------------------------
*************************************************************************************************/
        
(
	@COD_BRANCH INT, 
	@COD_EC     INT = NULL)
AS
BEGIN

    IF @COD_EC IS NOT NULL
	   SELECT @COD_BRANCH = [COD_BRANCH]
	   FROM [BRANCH_EC]
	   WHERE [COD_EC] = @COD_EC
		    AND [TYPE_BRANCH] = 'PRINCIPAL';


    SELECT [DOC].[COD_DOC_BR] AS 'COD_DOC_BR', 
		 [DOC].[COD_USER] AS 'COD_USER', 
		 [DOC].[COD_BRANCH] AS 'COD_BRANCH', 
		 [DOC].[COD_SIT_REQ] AS 'COD_SIT_REQ', 
		 [DOC].[COD_DOC_TYPE] AS 'COD_DOC_TYPE', 
		 [D_TYPE].[NAME] AS 'NAME', 
		 [DOC].[PATH_DOC] AS 'PATH_DOC', 
		 [DOC].[ACTIVE] AS 'ACTIVE', 
		 [DOC].[COMMENT] AS 'COMMENT', 
		 [DOC].[MODIFY_DATE] AS 'MODIFY_DATE', 
		 [DOC].[COD_SUP_TIC] AS 'COD_SUP_TIC', 
		 [SITUATION_REQUESTS].[NAME] AS 'SITUATION'
    FROM [DOCS_BRANCH] AS [DOC]
	    INNER JOIN [DOC_TYPES] AS [D_TYPE] ON [D_TYPE].[COD_DOC_TYPE] = [DOC].[COD_DOC_TYPE]
	    INNER JOIN [SITUATION_REQUESTS] ON [SITUATION_REQUESTS].[COD_SIT_REQ] = [DOC].[COD_SIT_REQ]
    WHERE [ACTIVE] = 1
		AND [COD_BRANCH] = @COD_BRANCH
		AND [DOC].[PATH_DOC] IS NOT NULL
    ORDER BY [D_TYPE].[NAME];

END;  

go

update SITUATION_REQUESTS set TYPE = null  where [TYPE] = 'DOC';

GO

UPDATE [SITUATION_REQUESTS]
  SET 
	 [TYPE] = 'DOC'
WHERE [COD_SIT_REQ] IN(12, 13, 21, 16, 14);

go

IF
(SELECT COUNT(*)
 FROM [SITUATION_REQUESTS]
 WHERE [CODE] = 'PENDING ON ANALYSIS') = 0
    INSERT INTO [SITUATION_REQUESTS]
    ([CODE], 
	[NAME], 
	[TYPE]
    )
    VALUES
		(
	    'PENDING ON ANALYSIS', 
	    'PENDENTE DE ANÁLISE', 
	    'DOC'
		 );

GO

IF OBJECT_ID('LS_DOC_SITUATION') IS NOT NULL
    DROP PROCEDURE [LS_DOC_SITUATION];
GO

CREATE PROCEDURE [LS_DOC_SITUATION]
AS
BEGIN
    SELECT [COD_SIT_REQ], 
		 [NAME]
    FROM [SITUATION_REQUESTS]
    WHERE [TYPE] = 'DOC';
END;
GO


IF (OBJECT_ID('SP_UP_DOC_BRANCH') IS NOT NULL)
    DROP PROCEDURE [SP_UP_DOC_BRANCH];
GO
CREATE PROCEDURE [dbo].[SP_UP_DOC_BRANCH]
/*************************************************************************************************
----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date             Description
------------------------------------------------------------------------------------------
Lucas Aguiar                     V1             2018-10-05      Creation
Gian Luca Dalle Cort             V2             2018-10-15      Changed
Luiz Aquino                      v3             2020-03-04      Add Cod User Modify
------------------------------------------------------------------------------------------
*************************************************************************************************/
(@COD_DOC INT,  @COD_SIT INT, @COD_USER INT = null, @COMMENT VARCHAR(100) = null)
AS
BEGIN

    INSERT INTO HIST_SIT_DOCS_BRANCH
    (COD_DOC_BR, COD_USER, COD_SIT_REQ)
    SELECT @COD_DOC, COD_USER, COD_SIT_REQ
    FROM DOCS_BRANCH
    WHERE COD_DOC_BR = @COD_DOC

    IF @@rowcount < 1
        THROW 60000, 'COULD NOT REGISTER HIST_SIT_DOCS_BRANCH', 1;

    UPDATE DOCS_BRANCH SET COD_SIT_REQ = @COD_SIT, MODIFY_DATE = GETDATE(), COD_USER_MODIFY = @COD_USER, COMMENT = @COMMENT
    where COD_DOC_BR = @COD_DOC;

    IF @@rowcount < 1
        THROW 60000, 'COULD NOT UPDATE DOCS_BRANCH', 1;

	DECLARE @COD_BRANCH INT;
	DECLARE @COD_SIT_DOC_APROVED INT;
	DECLARE @COD_EC INT;
	DECLARE @COD_COMP INT;

	SELECT TOP 1 @COD_BRANCH = COD_BRANCH FROM DOCS_BRANCH WHERE COD_DOC_BR = @COD_DOC;
	SELECT @COD_SIT_DOC_APROVED = COD_SIT_REQ FROM SITUATION_REQUESTS WHERE TYPE = 'DOC' AND NAME = 'APROVADO';
	SELECT @COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC, @COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP FROM COMMERCIAL_ESTABLISHMENT
	INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC WHERE BRANCH_EC.COD_BRANCH = @COD_BRANCH;

	IF NOT EXISTS(SELECT TOP 1 COD_DOC_BR FROM DOCS_BRANCH WHERE COD_BRANCH = @COD_BRANCH AND ACTIVE = 1 AND COD_SIT_REQ != @COD_SIT_DOC_APROVED AND PATH_DOC IS NOT NULL)
	BEGIN
		UPDATE ESTABLISHMENT_CONDITIONS SET [DOCUMENT] = 1 WHERE [COD_EC] = @COD_EC	AND [COD_COMP] = @COD_COMP AND [ACTIVE] = 1;
		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE ESTABLISHMENT_CONDITIONS', 1;
	END
	ELSE IF EXISTS(SELECT TOP 1 COD_EC_CONDIT FROM ESTABLISHMENT_CONDITIONS WHERE [COD_EC] = @COD_EC AND [COD_COMP] = @COD_COMP AND ACTIVE = 1 AND DOCUMENT = 1)
	BEGIN
		UPDATE ESTABLISHMENT_CONDITIONS SET [DOCUMENT] = 0 WHERE [COD_EC] = @COD_EC	AND [COD_COMP] = @COD_COMP AND [ACTIVE] = 1;
		IF @@rowcount < 1
			THROW 60000, 'COULD NOT UPDATE ESTABLISHMENT_CONDITIONS', 1;
	END
END;
go

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'COD_RISK_SITUATION' AND [OBJECT_ID] = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT_LOG'))
BEGIN
    ALTER TABLE COMMERCIAL_ESTABLISHMENT_LOG
    ADD COD_RISK_SITUATION INT NULL REFERENCES RISK_SITUATION (COD_RISK_SITUATION)
END

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'NOTE_FINANCE_SCHEDULE' AND [OBJECT_ID] = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT_LOG'))
BEGIN
    ALTER TABLE COMMERCIAL_ESTABLISHMENT_LOG
    ADD NOTE_FINANCE_SCHEDULE varchar(500)
END

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'RISK_REASON' AND [OBJECT_ID] = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT_LOG'))
BEGIN
    ALTER TABLE COMMERCIAL_ESTABLISHMENT_LOG
    ADD RISK_REASON varchar(500)
END

IF (OBJECT_ID('[SP_UP_EC_SITUATION]') IS NOT NULL)
    DROP PROCEDURE [SP_UP_EC_SITUATION]
GO
CREATE PROCEDURE [dbo].[SP_UP_EC_SITUATION]
/*************************************************************************************************
----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date             Description
------------------------------------------------------------------------------------------
Luiz Aquino                      v3             2020-03-04      Created
------------------------------------------------------------------------------------------
*************************************************************************************************/
(@COD_EC INT, @COD_USER INT, @COD_RISK_SITUATION INT, @FINANCE_BLOCKED INT, @JUSTIFY_FINANCE VARCHAR(500), @JUSTIFY_RISC VARCHAR(500))
AS
BEGIN

    INSERT INTO COMMERCIAL_ESTABLISHMENT_LOG (CODE, NAME, TRADING_NAME, CPF_CNPJ, DOCUMENT_TYPE, EMAIL, STATE_REGISTRATION, MUNICIPAL_REGISTRATION, COD_SEG, TRANSACTION_LIMIT, LIMIT_TRANSACTION_DIALY, BIRTHDATE, COD_USER, COD_COMP, MODIFY_DATE, COD_USER_MODIFY, SEC_FACTOR_AUTH_ACTIVE, COD_TYPE_ESTAB, COD_SEX, DOCUMENT, COD_SALES_REP, COD_EC, NOTE, COD_SIT_REQ, COD_SITUATION, COD_REQ, COD_AFFILIATOR, TRANSACTION_ONLINE, USER_ONLINE, PWD_ONLINE, DEFAULT_EC, NOTE_FINANCE_SCHEDULE, COD_RISK_SITUATION, RISK_REASON)
    SELECT CODE, NAME, TRADING_NAME, CPF_CNPJ, DOCUMENT_TYPE, EMAIL, STATE_REGISTRATION, MUNICIPAL_REGISTRATION, COD_SEG, TRANSACTION_LIMIT, LIMIT_TRANSACTION_DIALY, BIRTHDATE, COD_USER, COD_COMP, MODIFY_DATE, COD_USER_MODIFY, SEC_FACTOR_AUTH_ACTIVE, COD_TYPE_ESTAB, COD_SEX, DOCUMENT, COD_SALES_REP, COD_EC,NOTE, COD_SIT_REQ, COD_SITUATION, COD_REQ,  COD_AFFILIATOR, TRANSACTION_ONLINE, USER_ONLINE, PWD_ONLINE, DEFAULT_EC, NOTE_FINANCE_SCHEDULE, COD_RISK_SITUATION, RISK_REASON FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC

    DECLARE @COD_SITUATION INT
    DECLARE @BlockedSituation INT

    SELECT @COD_SITUATION = COD_SITUATION FROM COMMERCIAL_ESTABLISHMENT
    WHERE COD_EC = @COD_EC

    SELECT @BlockedSituation = COD_SITUATION FROM SITUATION
    WHERE NAME = 'LOCKED FINANCIAL SCHEDULE'

    IF @FINANCE_BLOCKED = 1 BEGIN
       SET  @COD_SITUATION = @BlockedSituation
    END
    IF @FINANCE_BLOCKED = 0 AND @COD_SITUATION = @BlockedSituation BEGIN
        SELECT @COD_SITUATION = COD_SITUATION FROM SITUATION
        WHERE NAME = 'RELEASED'
    END

    UPDATE COMMERCIAL_ESTABLISHMENT
    SET
        COD_USER_MODIFY = @COD_USER,
        COD_RISK_SITUATION = @COD_RISK_SITUATION,
        NOTE_FINANCE_SCHEDULE = @JUSTIFY_FINANCE,
        RISK_REASON = @JUSTIFY_RISC,
        COD_SITUATION = @COD_SITUATION
    WHERE COD_EC = @COD_EC

END;
go

INSERT INTO MESSAGING_CATEGORY([DESCRIPTION], [SECONS_ON_SCREEN], [TRANSLATE_DESCRIPTION], [CLASS_STYLE]) 
VALUES ('WARNING', 30, 'AVISO', 'warning')
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [Name] = N'REDIRECT_URL' AND [OBJECT_ID] = OBJECT_ID(N'MESSAGING'))
BEGIN
	ALTER TABLE MESSAGING
	ADD REDIRECT_URL VARCHAR(128) NULL
END
GO

IF (OBJECT_ID('[SP_REG_MESSAGING]') IS NOT NULL)
    DROP PROCEDURE [SP_REG_MESSAGING]
GO
CREATE PROCEDURE [dbo].[SP_REG_MESSAGING]
/*************************************************************************************************
----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date             Description
------------------------------------------------------------------------------------------
Luiz Aquino                      v2             2020-03-09      Add Redirect Url
------------------------------------------------------------------------------------------
*************************************************************************************************/
(
    @EXPIRATION_TIME INT = 1,
    @COD_USER_ORIGIN INT,
    @COD_USER CODE_TYPE READONLY,
    @COD_EC CODE_TYPE READONLY,
    @COD_AFFILIATOR CODE_TYPE READONLY,
    @COD_MES_CAT INT,
    @CONTENT_MESSAGE VARCHAR(MAX),
    @LINK_MESSAGE VARCHAR(250) = NULL,
    @COD_SHIPPING_OPT INT,
    @TITLE VARCHAR(255),
    @REDIRECT_URL VARCHAR(128) = NULL
)
AS
BEGIN

    DECLARE @USERS CODE_TYPE;

    DECLARE @TABLE_ID TABLE ( ID INT );

    DECLARE @SEQ_GROUP INT = NEXT VALUE FOR SEQ_MESSAGE_GROUP;

    IF @COD_SHIPPING_OPT = 1
        BEGIN
            INSERT INTO @USERS
            SELECT COD_USER
            FROM USERS
            WHERE ACTIVE = 1
              AND ((SELECT COUNT(*) FROM @COD_AFFILIATOR) = 0 OR (COD_AFFILIATOR IN (SELECT * FROM @COD_AFFILIATOR)))
              AND COD_MODULE = 5;
        END
    ELSE
        IF @COD_SHIPPING_OPT = 2
            BEGIN
                INSERT INTO @USERS
                SELECT COD_USER
                FROM USERS
                WHERE COD_AFFILIATOR IN (SELECT * FROM @COD_AFFILIATOR)
                  AND ((SELECT COUNT(*) FROM @COD_EC) = 0 OR COD_EC IN (SELECT * FROM @COD_EC))
                  AND ACTIVE = 1
                  AND COD_MODULE = 2;
            END
        ELSE
            IF @COD_SHIPPING_OPT = 3
                BEGIN
                    INSERT INTO @USERS
                    SELECT COD_USER
                    FROM USERS
                    WHERE ACTIVE = 1 AND (COD_EC IN (SELECT * FROM @COD_EC)) AND COD_MODULE = 2;
                END
            ELSE
                IF @COD_SHIPPING_OPT = 4
                    BEGIN
                        INSERT INTO @USERS
                        SELECT COD_USER
                        FROM USERS
                        WHERE ACTIVE = 1 AND (COD_USER IN (SELECT * FROM @COD_USER))
                    END
                ELSE
                    THROW 60001, 'SHIPPING OPTION NOT FOUND', 1;

    IF (SELECT COUNT(*) FROM @USERS) = 0
        THROW 61006, 'USER NOT FOUND', 1;

    INSERT INTO MESSAGING (TITLE, CREATED_AT, EXPIRATION_DATE, COD_USER_ORIGIN, COD_USER, COD_EC, COD_AFFILIATOR,
                           COD_MES_CAT, CONTENT_MESSAGE, LINK_MESSAGE, CODE_GROUP, COD_SHIPPING_OPT, REDIRECT_URL)
    OUTPUT INSERTED.COD_MESSAGING INTO @TABLE_ID
    SELECT @TITLE
        , current_timestamp
        , DATEADD(DAY, 30, current_timestamp)
        , @COD_USER_ORIGIN
        , CODE
        , COD_EC
        , COD_AFFILIATOR
        , @COD_MES_CAT
        , @CONTENT_MESSAGE
        , @LINK_MESSAGE
        , @SEQ_GROUP
        , @COD_SHIPPING_OPT
        , @REDIRECT_URL
    FROM @USERS U
             JOIN USERS
                  ON USERS.COD_USER = U.CODE

    SELECT tbl.ID
         , MESSAGING.COD_USER
    FROM @TABLE_ID tbl
             JOIN MESSAGING
                  ON MESSAGING.COD_MESSAGING = tbl.ID

END;
GO

IF (OBJECT_ID('[SP_LS_EC_USER_ONLINE]') IS NOT NULL)
    DROP PROCEDURE [SP_LS_EC_USER_ONLINE]
GO
CREATE PROCEDURE [dbo].[SP_LS_EC_USER_ONLINE]
/*----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date          Description
------------------------------------------------------------------------------------------
Caike Uchoa                      V1         2018-10-29        Creation
Luiz Aquino                      V2         2020-03-10        Add Cof affiliator
------------------------------------------------------------------------------------------*/
    @COD_COMP INT,
    @COD_EC INT
AS
SELECT [COMMERCIAL_ESTABLISHMENT].[NAME]
     , [COMMERCIAL_ESTABLISHMENT].PWD_ONLINE
     , [COMMERCIAL_ESTABLISHMENT].USER_ONLINE
     , [COMMERCIAL_ESTABLISHMENT].TRADING_NAME
     , [COMMERCIAL_ESTABLISHMENT].CPF_CNPJ
     , [COMMERCIAL_ESTABLISHMENT].COD_EC
     , [COMMERCIAL_ESTABLISHMENT].COD_AFFILIATOR
FROM COMMERCIAL_ESTABLISHMENT
         INNER JOIN COMPANY
                    ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
WHERE COMMERCIAL_ESTABLISHMENT.COD_COMP = @COD_COMP
  AND COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC

GO

IF (OBJECT_ID('[SP_LS_USER_PENDING_MESSAGING]') IS NOT NULL)
    DROP PROCEDURE [SP_LS_USER_PENDING_MESSAGING]
GO
CREATE PROCEDURE SP_LS_USER_PENDING_MESSAGING
/*************************************************************************************************
----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date             Description
------------------------------------------------------------------------------------------
Luiz Aquino                      v2             2020-03-10      Add Redirect Url
------------------------------------------------------------------------------------------
*************************************************************************************************/
(
    @COD_USER INT
)
AS
BEGIN

    SELECT MESSAGING.COD_MESSAGING
         , MESSAGING.CREATED_AT
         , MESSAGING.TITLE
         , MESSAGING.EXPIRATION_DATE
         , MESSAGING.COD_USER_ORIGIN
         , MESSAGING.COD_USER
         , MESSAGING.COD_EC
         , MESSAGING.COD_AFFILIATOR
         , MESSAGING.COD_MES_CAT
         , MESSAGING.CONTENT_MESSAGE
         , MESSAGING.LINK_MESSAGE
         , MESSAGING.HAS_READED
         , MESSAGING_CATEGORY.COD_MES_CAT
         , MESSAGING_CATEGORY.DESCRIPTION
         , MESSAGING_CATEGORY.SECONS_ON_SCREEN
         , MESSAGING_CATEGORY.CLASS_STYLE
         , MESSAGING.REDIRECT_URL
    FROM MESSAGING
             INNER JOIN MESSAGING_CATEGORY
                        ON MESSAGING.COD_MES_CAT = MESSAGING_CATEGORY.COD_MES_CAT
    WHERE COD_USER = @COD_USER
      AND HAS_READED = 0;

    UPDATE MESSAGING SET HAS_READED = 1 WHERE COD_USER = @COD_USER AND HAS_READED = 0;
END;
GO


IF (OBJECT_ID('[SP_MESSAGES_USER]') IS NOT NULL)
    DROP PROCEDURE [SP_MESSAGES_USER]
GO
CREATE PROCEDURE SP_MESSAGES_USER
/*----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author          ERSION        Date            Description
------------------------------------------------------------------------------------------
Lucas Aguiar     V1         2019-10-21        Creation
Luiz Aquino      V2         2020-03-10         Add redirect url
------------------------------------------------------------------------------------------*/
(
    @COD_USER INT
)
AS

BEGIN
    SELECT TITLE
         , CONTENT_MESSAGE
         , MESSAGING_CATEGORY.TRANSLATE_DESCRIPTION
         , LINK_MESSAGE
         , VIEWER_NOTIFY
         , REDIRECT_URL
    FROM MESSAGING
             JOIN MESSAGING_CATEGORY
                  ON MESSAGING_CATEGORY.COD_MES_CAT = MESSAGING.COD_MES_CAT
    WHERE COD_USER = @COD_USER
      AND current_timestamp <= EXPIRATION_DATE
    ORDER BY CREATED_AT DESC
END;
GO

IF (OBJECT_ID('[SP_FD_DATA_EC]') IS NOT NULL)
    DROP PROCEDURE [SP_FD_DATA_EC]
GO
CREATE PROCEDURE SP_FD_DATA_EC
/*----------------------------------------------------------------------------------------
Project.......: TKPP
Procedure Name: [SP_FD_DATA_EC]
------------------------------------------------------------------------------------------
Author              VERSION        Date   Description
------------------------------------------------------------------------------------------
Kennedy Alef  V1   2018-07-27  Creation
Elir Ribeiro  V2   2018-11-07  Changed
Lucas Aguiar  V3   2019-04-22  Add split
Lucas Aguiar  V4   2019-07-01  rotina de travar agenda do ec
Luiz Aquino   V5   2019-07-03  Is_Cerc
Elir Ribeiro  V6   2019-10-01  changed Limit transaction monthy
Caike Uchoa   V7   2019-10-03  add case split pelo afiliador
Luiz Aquino   V8   2019-10-16  Add reten��o de agenda
Lucas Aguiar  V9   2019-10-28  Conta Cess�o
Marcus Gall   V10   2019-11-11  Add FK with BRANCH BUSINESS
Marcus Gall   V11   2019-12-06  Add field HAS_CREDENTIALS
Elir Ribeiro  V12   2020-01-08  trazendo dados meet consumer
Elir Ribeiro  V13   2020-01-15  ajustando procedure
Marcus Gall   V14   2020-01-22  Add Translate service
Luiz Aquino   v15   2020-03-11  Add requested transaction type
------------------------------------------------------------------------------------------*/
(
    @COD_EC INT
)
AS
BEGIN

    DECLARE @CodSpotService INT

    DECLARE @COD_SPLIT_SERVICE INT;

    DECLARE @COD_BLOCK_SITUATION INT;

    DECLARE @COD_CUSTOMERINSTALLMENT INT;

    DECLARE @CodSchRetention INT;

    DECLARE @COD_TRANSLATE_SERVICE INT;

    SELECT @CodSpotService = COD_ITEM_SERVICE
    FROM ITEMS_SERVICES_AVAILABLE
    WHERE CODE = '1';

    SELECT @COD_SPLIT_SERVICE = COD_ITEM_SERVICE
    FROM ITEMS_SERVICES_AVAILABLE
    WHERE [NAME] = 'SPLIT';

    SELECT @COD_BLOCK_SITUATION = COD_SITUATION
    FROM SITUATION
    WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';

    SELECT @COD_CUSTOMERINSTALLMENT = COD_ITEM_SERVICE
    FROM ITEMS_SERVICES_AVAILABLE
    WHERE NAME = 'PARCELADOCLIENTE';

    SELECT @CodSchRetention = COD_ITEM_SERVICE
    FROM ITEMS_SERVICES_AVAILABLE
    WHERE [NAME] = 'SCHEDULEDRETENTION';

    SELECT @COD_TRANSLATE_SERVICE = COD_ITEM_SERVICE
    FROM ITEMS_SERVICES_AVAILABLE
    WHERE [NAME] = 'TRANSLATE';

    SELECT BRANCH_EC.[NAME]
         , BRANCH_EC.TRADING_NAME
         , BRANCH_EC.CPF_CNPJ
         , BRANCH_EC.DOCUMENT
         , BRANCH_EC.BIRTHDATE
         , COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT
         , COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY
         , COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY
         , BRANCH_EC.EMAIL
         , BRANCH_EC.STATE_REGISTRATION
         , BRANCH_EC.MUNICIPAL_REGISTRATION
         , BRANCH_EC.NOTE                              AS NOTE
         , TYPE_ESTAB.CODE                             AS TYPE_ESTAB_CODE
         , SEGMENTS.COD_SEG                            AS SEGMENT
         , BRANCH_EC.ACTIVE
         , ADDRESS_BRANCH.[ADDRESS]
         , ADDRESS_BRANCH.NUMBER                       AS NUMBER_ADDRESS
         , ADDRESS_BRANCH.COMPLEMENT
         , ADDRESS_BRANCH.CEP
         , ADDRESS_BRANCH.REFERENCE_POINT
         , NEIGHBORHOOD.COD_NEIGH
         , NEIGHBORHOOD.[NAME]                         AS NEIGHBORHOOD
         , CITY.COD_CITY
         , CITY.[NAME]                                 AS CITY
         , [STATE].COD_STATE
         , [STATE].[NAME]                              AS [STATE]
         , COUNTRY.COD_COUNTRY
         , COUNTRY.[NAME]                              AS COUNTRY
         , BANKS.COD_BANK                              AS BANK_INSIDECODE
         , BANKS.[NAME]                                AS BANK
         , BANK_DETAILS_EC.DIGIT_AGENCY
         , BANK_DETAILS_EC.AGENCY
         , BANK_DETAILS_EC.DIGIT_ACCOUNT
         , BANK_DETAILS_EC.ACCOUNT
         , ACCOUNT_TYPE.COD_TYPE_ACCOUNT               AS ACCOUNT_TYPE_INSIDECODE
         , ACCOUNT_TYPE.[NAME]                         AS ACCOUNT_TYPE
         , SALES_REPRESENTATIVE.COD_SALES_REP
         , COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE
         , BRANCH_EC.COD_SEX
         , BRANCH_EC.COD_BRANCH                        AS COD_BRANCH
         , BANK_DETAILS_EC.AGENCY                      AS AGENCY
         , BANK_DETAILS_EC.DIGIT_AGENCY                AS AGENCY_DIGIT
         , BANK_DETAILS_EC.ACCOUNT                     AS ACCOUNT
         , BANK_DETAILS_EC.DIGIT_ACCOUNT               AS DIGIT_ACCOUNT
         , BANK_DETAILS_EC.COD_OPER_BANK
         , TYPE_RECEIPT.COD_TYPE_REC
         , TYPE_RECEIPT.CODE                           AS TYPE_RECEIPT
         , CARDS_TOBRANCH.CARDNUMBER
         , CARDS_TOBRANCH.ACCOUNTID                    AS 'ACCOUNTID'
         , CARDS_TOBRANCH.COD_CARD_BRANCH              AS 'COD_CARD_BRANCH'
         , COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE AS 'TRANSACTION_ONLINE'
         , COMMERCIAL_ESTABLISHMENT.SPOT_TAX
         , CASE
               WHEN COMMERCIAL_ESTABLISHMENT.COD_SITUATION = @COD_BLOCK_SITUATION THEN 1
               ELSE 0
        END                                               [FINANCE_BLOCK]
         , COMMERCIAL_ESTABLISHMENT.NOTE_FINANCE_SCHEDULE
         , CASE
               WHEN (SELECT COUNT(*)
                     FROM SERVICES_AVAILABLE
                     WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodSpotService
                       AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                       AND SERVICES_AVAILABLE.ACTIVE = 1)
                   > 0 THEN 1
               ELSE 0
        END                                               [HAS_SPOT]
         , COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
         , CASE
               WHEN (SELECT COUNT(*)
                     FROM SERVICES_AVAILABLE
                     WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_SPLIT_SERVICE
                       AND SERVICES_AVAILABLE.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
                       AND SERVICES_AVAILABLE.ACTIVE = 1
                       AND SERVICES_AVAILABLE.COD_OPT_SERV = 4
                       AND SERVICES_AVAILABLE.COD_EC IS NULL)
                   > 0 THEN 1
               WHEN (SELECT COUNT(*)
                     FROM SERVICES_AVAILABLE
                     WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_SPLIT_SERVICE
                       AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                       AND SERVICES_AVAILABLE.ACTIVE = 1)
                   > 0 THEN 1
               ELSE 0
        END                                               [HAS_SPLIT]
         , CASE
               WHEN (SELECT COUNT(*)
                     FROM SERVICES_AVAILABLE
                     WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_CUSTOMERINSTALLMENT
                       AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                       AND SERVICES_AVAILABLE.ACTIVE = 1)
                   > 0 THEN 1
               ELSE 0
        END                                               [HAS_CUSTOMERINSTALLMENT]
         , CASE
               WHEN (SELECT COUNT(*)
                     FROM SERVICES_AVAILABLE
                     WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodSchRetention
                       AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
                       AND SERVICES_AVAILABLE.ACTIVE = 1)
                   > 0 THEN 1
               ELSE 0
        END                                               [HAS_SCHRETENTION]
         , COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
         , COMMERCIAL_ESTABLISHMENT.RISK_REASON
         , COMMERCIAL_ESTABLISHMENT.IS_PROVIDER
         , BANK_DETAILS_EC.IS_ASSIGNMENT
         , BANK_DETAILS_EC.ASSIGNMENT_NAME
         , BANK_DETAILS_EC.ASSIGNMENT_IDENTIFICATION
         , BRANCH_BUSINESS.COD_BRANCH_BUSINESS         AS BRANCH_BUSINESS
         , COMMERCIAL_ESTABLISHMENT.HAS_CREDENTIALS
         , MEET_COSTUMER.CNPJ                             [ACCEPTANCE]
         , ISNULL(MEET_COSTUMER.QTY_EMPLOYEES, 0)         QTY_EMPLOYEES
         , ISNULL(MEET_COSTUMER.AVERAGE_BILLING, 0)       AVERAGE_BILLING
         , MEET_COSTUMER.URL_SITE
         , MEET_COSTUMER.FACEBOOK
         , MEET_COSTUMER.INSTAGRAM
         , MEET_COSTUMER.STREET
         , MEET_COSTUMER.COMPLEMENT                       [COMPLEMENTO]
         , MEET_COSTUMER.ANOTHER_INFO
         , MEET_COSTUMER.NUMBER
         , MEET_COSTUMER.NEIGHBORHOOD                  AS MEET_NEIGH
         , MEET_COSTUMER.CITY                          AS MEET_CITY
         , MEET_COSTUMER.STATES
         , MEET_COSTUMER.REFERENCEPOINT
         , MEET_COSTUMER.ZIPCODE
         , CASE
               WHEN (SELECT COUNT(*)
                     FROM SERVICES_AVAILABLE
                     WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_TRANSLATE_SERVICE
                       AND SERVICES_AVAILABLE.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
                       AND SERVICES_AVAILABLE.ACTIVE = 1)
                   > 0 THEN 1
               ELSE 0
         END                                               [HAS_TRANSLATE]
         ,[REQUESTED_PRESENTIAL_TRANSACTION]
         ,[REQUESTED_ONLINE_TRANSACTION]
    FROM COMMERCIAL_ESTABLISHMENT
             INNER JOIN BRANCH_EC
                        ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
             INNER JOIN TYPE_ESTAB
                        ON TYPE_ESTAB.COD_TYPE_ESTAB = BRANCH_EC.COD_TYPE_ESTAB
             INNER JOIN ADDRESS_BRANCH
                        ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
                            AND ADDRESS_BRANCH.ACTIVE = 1
             INNER JOIN NEIGHBORHOOD
                        ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
             INNER JOIN CITY
                        ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
             INNER JOIN [STATE] ON [STATE].COD_STATE = CITY.COD_STATE
             INNER JOIN COUNTRY
                        ON [STATE].COD_COUNTRY = COUNTRY.COD_COUNTRY
             INNER JOIN TYPE_RECEIPT
                        ON TYPE_RECEIPT.COD_TYPE_REC = BRANCH_EC.COD_TYPE_REC
             LEFT JOIN BANK_DETAILS_EC
                       ON BANK_DETAILS_EC.COD_BRANCH = BRANCH_EC.COD_BRANCH
                           AND BANK_DETAILS_EC.ACTIVE = 1
                           AND BANK_DETAILS_EC.IS_CERC = 0
             LEFT JOIN BANKS
                       ON BANKS.COD_BANK = BANK_DETAILS_EC.COD_BANK
             LEFT JOIN ACCOUNT_TYPE
                       ON ACCOUNT_TYPE.COD_TYPE_ACCOUNT = BANK_DETAILS_EC.COD_TYPE_ACCOUNT
             INNER JOIN SEGMENTS
                        ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
             INNER JOIN SALES_REPRESENTATIVE
                        ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
             LEFT JOIN CARDS_TOBRANCH
                       ON CARDS_TOBRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
             INNER JOIN BRANCH_BUSINESS
                        ON BRANCH_BUSINESS.COD_BRANCH_BUSINESS = COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS
             LEFT JOIN MEET_COSTUMER
                       ON MEET_COSTUMER.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
    WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC
      AND (CARDS_TOBRANCH.COD_SITUATION = 15
        OR CARDS_TOBRANCH.COD_SITUATION IS NULL)

END;
go


IF (OBJECT_ID('[SP_UP_DATA_BR]') IS NOT NULL)
    DROP PROCEDURE [SP_UP_DATA_BR]
GO
CREATE PROCEDURE [dbo].[SP_UP_DATA_BR]
/*----------------------------------------------------------------------------------------
Procedure Name: [SP_UP_DATA_BR]
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION   Date                            Description
------------------------------------------------------------------------------------------
Kennedy Alef					V1		27/07/2018			Creation
Elir Ribeiro					V2		07/11/2018			Changed
Elir Ribeiro					V3		08/11/2018			Changed
Kennedy Alef					V1		10/12/2018			Changed
Luiz Aquino						V3		13/12/2018			Add Has_SPOT SPOT_TAX
Lucas Aguiar					V6		14/12/2018			Add  TRANSACTION_DIGITED
Lucas Aguiar					V7		01/07/2019			Desabilitar a agenda financeira do ec
Elir Ribeiro					V8		24/07/2019			Data Ofac = null
Lucas Aguiar					V9		06/08/2019			add servi?o parcelado cliente
Elir Ribeiro					V9		02/08/2019			add RiskSituation and Reason Risck
Elir Ribeiro					V10		21-08-2019			changed Active  de acordo com o RiskSituation
Elir Ribeiro					V11		01-10-2019			changed Limit Transaction Monthly
Marcus Gall						V12		11-11-2019			Add Branch Business
Luiz Aquino                     v13     11-03-2020          Add permissoes de transacao (ET-465)
------------------------------------------------------------------------------------------*/
(
    @NAME VARCHAR(100),
    @TRADING_NAME VARCHAR(100),
    @EMAIL VARCHAR(100),
    @STATE_REG VARCHAR(30),
    @MUN_REG VARCHAR(30),
    @LIMIT_TRANSACTION_DIALY DECIMAL(22, 6),
    @LIMIT_TRANSACTION DECIMAL(22, 6),
    @LIMIT_TRANSACTION_MONTHLY DECIMAL(22, 6),
    @BIRTHDATE DATETIME,
    @COD_USER INT,
    @TYPE_BRANCH VARCHAR(100),
    @TYPE_ESTAB INT,
    @DOCUMENT VARCHAR(100),
    @SEX INT,
    @COD_SALES_REP INT,
    @ACTIVE INT,
    @COD_BR INT,
    @COD_EC INT,
    @ADDRESS VARCHAR(400),
    @NUMBER VARCHAR(10),
    @COMPLEMENT VARCHAR(300),
    @CEP VARCHAR(12),
    @COD_NEIGH INT,
    @REFERENCE_POINT VARCHAR(200),
    @SEC_FACTOR_AUTH_ACTIVE INT,
    @COD_SEG INT,
    @NOTE VARCHAR(400) = null,
    @CPF_CNPJ varchar(30),
    @WAS_BLOCKED INT = NULL,
    @COD_SITUATION INT = NULL,
    @NOTE_FINANCE VARCHAR(MAX) = NULL,
    @COD_RISK_SITUATION INT = NULL,
    @RISK_REASON VARCHAR(500) = NULL,
    @BRANCH_BUSINESS INT = NULL,
    @REQUEST_ONLINE_TRANSACTION INT = 0,
    @REQUEST_PRESENTIAL_TRANSACTION INT = 0
 )
AS

DECLARE @REGISTRO VARCHAR(100)
DECLARE @COD_ACTIVE_SITUATION_EC INT
DECLARE @CURRENT_ACTIVE INT;
DECLARE @CURRENT_CPF_CNPJ varchar(30);

BEGIN

    IF @COD_RISK_SITUATION IS NULL
        SET @COD_RISK_SITUATION = 1

    SELECT @COD_ACTIVE_SITUATION_EC = SITUATION_EC
    FROM RISK_SITUATION
    WHERE COD_RISK_SITUATION = @COD_RISK_SITUATION

    IF @WAS_BLOCKED = 1
        SELECT @COD_SITUATION = COD_SITUATION
        FROM SITUATION
        WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';
    ELSE IF @WAS_BLOCKED = 0
        SELECT @COD_SITUATION = COD_SITUATION
        FROM SITUATION
        WHERE [NAME] = 'RELEASED';
    ELSE
        SELECT @COD_SITUATION = COD_SITUATION
        FROM COMMERCIAL_ESTABLISHMENT
        WHERE COD_EC = @COD_EC;

    SELECT @REGISTRO = CPF_CNPJ
    FROM COMMERCIAL_ESTABLISHMENT
    WHERE COD_EC = @COD_EC

    SELECT @CURRENT_CPF_CNPJ = CPF_CNPJ
         , @CURRENT_ACTIVE = ACTIVE
    FROM COMMERCIAL_ESTABLISHMENT
    WHERE COD_EC = @COD_EC;

    IF (@CURRENT_CPF_CNPJ <> @CPF_CNPJ)
        OR (@CURRENT_ACTIVE <> @ACTIVE)
        UPDATE ASS_CERC_EC
        SET ACTIVE      = @ACTIVE
          , MODIFY_DATE = current_timestamp
          , PROCESSED   = 0
        WHERE COD_EC = @COD_EC;

    UPDATE BRANCH_EC
        SET [NAME]                  = @NAME
          , TRADING_NAME            = @TRADING_NAME
          , EMAIL                   = @EMAIL
          , STATE_REGISTRATION      = @STATE_REG
          , MUNICIPAL_REGISTRATION  = @MUN_REG
          , TRANSACTION_LIMIT       = @LIMIT_TRANSACTION
          , LIMIT_TRANSACTION_DIALY = @LIMIT_TRANSACTION_DIALY
          , BIRTHDATE               = @BIRTHDATE
          , COD_USER                = @COD_USER
          , COD_TYPE_ESTAB          = @TYPE_ESTAB
          , DOCUMENT                = @DOCUMENT
          , COD_SEX                 = @SEX
          , COD_SALES_REP           = @COD_SALES_REP
          , ACTIVE                  = @ACTIVE
          , [NOTE]                  = @NOTE
          , CPF_CNPJ                = @CPF_CNPJ
        WHERE COD_BRANCH = @COD_BR

    IF @@rowcount < 1
        THROW 60001, 'COULD NOT UPDATE BRANCH_EC', 1

    UPDATE ADDRESS_BRANCH
    SET ACTIVE      = 0
      , MODIFY_DATE = GETDATE()
    WHERE ACTIVE = 1
      AND COD_BRANCH = @COD_BR

    INSERT INTO ADDRESS_BRANCH (ADDRESS, NUMBER, COMPLEMENT, CEP, COD_NEIGH, COD_BRANCH, REFERENCE_POINT)
    VALUES (@ADDRESS, @NUMBER, @COMPLEMENT, @CEP, @COD_NEIGH, @COD_BR, @REFERENCE_POINT)

    IF @@rowcount < 1
        THROW 60000, 'COULD NOT REGISTER ADDRESS_BRANCH ', 1

    IF @TYPE_BRANCH = 'PRINCIPAL'
    BEGIN
        EXEC SP_LOG_MERC_REG @COD_EC, @COD_USER

        -- UPDATE MERCHANT TABLE

        UPDATE COMMERCIAL_ESTABLISHMENT
        SET [NAME]                    = @NAME
          , TRADING_NAME              = @TRADING_NAME
          , EMAIL                     = @EMAIL
          , STATE_REGISTRATION        = @STATE_REG
          , MUNICIPAL_REGISTRATION    = @MUN_REG
          , TRANSACTION_LIMIT         = @LIMIT_TRANSACTION
          , LIMIT_TRANSACTION_DIALY   = @LIMIT_TRANSACTION_DIALY
          , LIMIT_TRANSACTION_MONTHLY = @LIMIT_TRANSACTION_MONTHLY
          , BIRTHDATE                 = @BIRTHDATE
          , COD_USER                  = @COD_USER
          , COD_TYPE_ESTAB            = @TYPE_ESTAB
          , DOCUMENT                  = @DOCUMENT
          , COD_SEX                   = @SEX
          , COD_SALES_REP             = @COD_SALES_REP
          , ACTIVE                    = @COD_ACTIVE_SITUATION_EC
          , SEC_FACTOR_AUTH_ACTIVE    = @SEC_FACTOR_AUTH_ACTIVE
          , COD_SEG                   = @COD_SEG
          , COD_USER_MODIFY           = @COD_USER
          , MODIFY_DATE               = GETDATE()
          , [NOTE]                    = @NOTE
          , CPF_CNPJ                  = @CPF_CNPJ
          , COD_SITUATION             = @COD_SITUATION
          , NOTE_FINANCE_SCHEDULE     = @NOTE_FINANCE
          , DATE_OFAC                 = NULL
          , COD_RISK_SITUATION        = @COD_RISK_SITUATION
          , RISK_REASON               = @RISK_REASON
          , COD_BRANCH_BUSINESS       = @BRANCH_BUSINESS
          , REQUESTED_ONLINE_TRANSACTION = @REQUEST_ONLINE_TRANSACTION
          , REQUESTED_PRESENTIAL_TRANSACTION = @REQUEST_PRESENTIAL_TRANSACTION
        WHERE COD_EC = @COD_EC
    END
END;
go

IF (OBJECT_ID('[SP_FD_EC]') IS NOT NULL)
    DROP PROCEDURE [SP_FD_EC]
GO
CREATE PROCEDURE [dbo].[SP_FD_EC]
/*----------------------------------------------------------------------------------------
Project.......: TKPP
------------------------------------------------------------------------------------------
Author                          VERSION        Date                            Description
------------------------------------------------------------------------------------------
Kennedy Alef					V1			27/07/2018			Creation
Gian Luca Dalle Cort			V2			04/10/2018			Changed
Lucas Aguiar					V3			15/10/2018			Changed
Elir Ribeiro					V4			14/11/2018			Changed
Luiz Aquino						V5			26/12/2018			Add Column Spot_tax
Lucas Aguiar					V6			01/07/2019			Add Rotina de travar agenda
Elir Ribeiro					V7			02/08/2019			Add Situa��o Risco
Lucas Aguiar					V8			04-09-2019			IS_PROVIDER
Marcus Gall Barreira			V9			11-11-2019			Add parameter Branch Business
Marcus Gall Barreira			V10			19-11-2019			Add informações de endereço do EC
Marcus Gall						v11			06-05-2020			Add ModifyDate
------------------------------------------------------------------------------------------*/
(
    @CPF_CNPJ VARCHAR(14),
    @COD_REP INT,
    @ID_EC INT,
    @SEGMENT INT,
    @COMP INT,
    @TYPE VARCHAR(100),
    @COD_PLAN INT = null,
    @COD_AFF INT = null,
    @Active BIT = null,
    @PersonType VARCHAR(100) = NULL,
    @CODSIT INT = null,
    @WAS_BLOCKED_FINANCE INT = null,
    @COD_SITUATION_RISK INT = NULL,
    @IS_PROVIDER INT = NULL,
    @BRANCH_BUSINESS INT = NULL,
    @RISK_SITUATION_LIST [CODE_TYPE] READONLY,
    @CREATED_FROM DATETIME = NULL,
    @CREATED_UNTIL DATETIME = NULL
 )
AS

    DECLARE @QUERY_ NVARCHAR(MAX);
    DECLARE @COD_BLOCKED_FINANCE INT;

BEGIN
    SET @QUERY_ = N'
        SELECT
			 BRANCH_EC.COD_EC,
			 BRANCH_EC.CODE,
			 dbo.FN_FUS_UTF(BRANCH_EC.CREATED_AT) AS CREATED_AT,
			 BRANCH_EC.NAME,
			 BRANCH_EC.TRADING_NAME,
			 BRANCH_EC.COD_BRANCH,
			 BRANCH_EC.CPF_CNPJ,
			 BRANCH_EC.DOCUMENT_TYPE,
			 BRANCH_EC.EMAIL,
			 BRANCH_EC.STATE_REGISTRATION,
			 BRANCH_EC.MUNICIPAL_REGISTRATION,
			 BRANCH_EC.TRANSACTION_LIMIT,
			 BRANCH_EC.LIMIT_TRANSACTION_DIALY,
			 BRANCH_EC.BIRTHDATE,
			 TYPE_ESTAB.CODE AS TYPE_EC,
			 BRANCH_EC.TYPE_BRANCH AS TYPE_BR,
			 SEGMENTS.NAME AS SEGMENTS,
			 BRANCH_EC.ACTIVE,
			 USERS.IDENTIFICATION AS SALES_REP,
			 ASS_TAX_DEPART.COD_PLAN,
			 TYPE_RECEIPT.[CODE] AS ACCOUNT_TYPE,
			 COUNT(*) AS QTY,
			 AFFILIATOR.COD_AFFILIATOR,
			 ISNULL(AFFILIATOR.NAME, ''CELER'')  AS NAME_AFFILIATOR,
			 SITUATION_REQUESTS.NAME AS SIT_REQUEST,
			 ISNULL(COMMERCIAL_ESTABLISHMENT.DEFAULT_EC, 0) AS DEFAULT_EC,
			 COMMERCIAL_ESTABLISHMENT.SPOT_TAX,
			 TRADUCTION_SITUATION.SITUATION_TR,
			 TRADUCTION_RISK_SITUATION.RISK_SITUATION_TR
			 , COMMERCIAL_ESTABLISHMENT.IS_PROVIDER
			 , BRANCH_BUSINESS.NAME AS BRANCH_BUSINESS
			 , NEIGHBORHOOD.[NAME] AS NEIGHBORHOOD
			 , CITY.[NAME] AS CITY
			 , STATE.[NAME] AS STATE
			 , dbo.FN_FUS_UTF(COMMERCIAL_ESTABLISHMENT.MODIFY_DATE) AS MODIFY_DATE 
        FROM COMMERCIAL_ESTABLISHMENT
			INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
			INNER JOIN SEGMENTS ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
			INNER JOIN TYPE_ESTAB ON COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB = TYPE_ESTAB.COD_TYPE_ESTAB
			INNER JOIN SALES_REPRESENTATIVE ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
			INNER JOIN USERS ON USERS.COD_USER = SALES_REPRESENTATIVE.COD_USER
			INNER JOIN DEPARTMENTS_BRANCH ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
			INNER JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH AND ASS_TAX_DEPART.ACTIVE = 1
			INNER JOIN TYPE_RECEIPT ON TYPE_RECEIPT.COD_TYPE_REC = BRANCH_EC.COD_TYPE_REC
			INNER JOIN SITUATION_REQUESTS ON SITUATION_REQUESTS.COD_SIT_REQ = COMMERCIAL_ESTABLISHMENT.COD_SIT_REQ
			LEFT JOIN BRANCH_BUSINESS ON BRANCH_BUSINESS.COD_BRANCH_BUSINESS = COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS
			LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
			LEFT JOIN TRADUCTION_SITUATION ON TRADUCTION_SITUATION.COD_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_SITUATION
			LEFT JOIN TRADUCTION_RISK_SITUATION ON TRADUCTION_RISK_SITUATION.COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
			INNER JOIN ADDRESS_BRANCH  ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH AND ADDRESS_BRANCH.ACTIVE = 1
			INNER JOIN NEIGHBORHOOD	 ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
			INNER JOIN CITY			 ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
			INNER JOIN STATE		 ON STATE.COD_STATE = CITY.COD_STATE
        WHERE
			COMMERCIAL_ESTABLISHMENT.COD_COMP = @COMP'

    SELECT @COD_BLOCKED_FINANCE = COD_SITUATION
    FROM SITUATION
    WHERE NAME = 'LOCKED FINANCIAL SCHEDULE';

    IF @ID_EC IS NOT NULL
        BEGIN
            IF @TYPE = 'BRANCH'
                SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.COD_BRANCH = @ID_EC ';
            ELSE
                SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_EC = @ID_EC ';
        END;

    IF @SEGMENT IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SEG = @SEGMENT ';

    IF @COD_REP IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SALES_REP = @COD_REP ';

    IF @TYPE IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.TYPE_BRANCH = @TYPE ';

    IF @CPF_CNPJ IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.CPF_CNPJ = @CPF_CNPJ ';

    IF @COD_PLAN IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND  ASS_TAX_DEPART.COD_PLAN = @COD_PLAN ';

    IF @COD_AFF IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = @COD_AFF';

    IF @Active IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND BRANCH_EC.ACTIVE = @Active';

    IF @IS_PROVIDER IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.IS_PROVIDER = @IS_PROVIDER';

    IF @PersonType IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND TYPE_ESTAB.CODE = @PersonType';

    IF @CODSIT IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SIT_REQ = @CODSIT';

    IF @WAS_BLOCKED_FINANCE = 1
        BEGIN
            SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SITUATION = @COD_BLOCKED_FINANCE';
        END
    ELSE
        IF @WAS_BLOCKED_FINANCE = 0
            SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SITUATION <> @COD_BLOCKED_FINANCE';

    IF @COD_SITUATION_RISK IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION = @COD_SITUATION_RISK';

    IF @BRANCH_BUSINESS IS NOT NULL
        SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_BRANCH_BUSINESS = @BRANCH_BUSINESS'

	IF EXISTS(SELECT TOP 1 CODE FROM @RISK_SITUATION_LIST)
		 SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION IN (SELECT CODE FROM @RISK_SITUATION_LIST)'

    SET @QUERY_ = CONCAT(@QUERY_,
                         ' GROUP BY
                              BRANCH_EC.CREATED_AT,
							  BRANCH_EC.COD_EC,
                              BRANCH_EC.CODE,
                              BRANCH_EC.NAME,
                              BRANCH_EC.TRADING_NAME,
                              BRANCH_EC.COD_BRANCH,
                              BRANCH_EC.CPF_CNPJ,
                              BRANCH_EC.DOCUMENT_TYPE,
                              BRANCH_EC.EMAIL,
                              BRANCH_EC.STATE_REGISTRATION,
                              BRANCH_EC.MUNICIPAL_REGISTRATION,
                              BRANCH_EC.TRANSACTION_LIMIT,
                              BRANCH_EC.LIMIT_TRANSACTION_DIALY,
                              BRANCH_EC.BIRTHDATE,
                              TYPE_ESTAB.CODE,
                              BRANCH_EC.TYPE_BRANCH,
                              SEGMENTS.NAME,
                              BRANCH_BUSINESS.NAME,
                              BRANCH_EC.ACTIVE,
                              USERS.IDENTIFICATION,
                              ASS_TAX_DEPART.COD_PLAN,
                              TYPE_RECEIPT.[CODE],
                              AFFILIATOR.COD_AFFILIATOR,
                              AFFILIATOR.NAME,
                              SITUATION_REQUESTS.NAME,
                              COMMERCIAL_ESTABLISHMENT.DEFAULT_EC,
                              COMMERCIAL_ESTABLISHMENT.SPOT_TAX ,
                              TRADUCTION_SITUATION.SITUATION_TR,
                              TRADUCTION_RISK_SITUATION.RISK_SITUATION_TR,
                              COMMERCIAL_ESTABLISHMENT.IS_PROVIDER
                              , NEIGHBORHOOD.[NAME]
                              , CITY.[NAME]
                              , STATE.[NAME]
							  , COMMERCIAL_ESTABLISHMENT.MODIFY_DATE
                              ');

    EXEC sp_executesql @QUERY_ ,N'
		@CPF_CNPJ VARCHAR(14),
		@COD_REP INT,
		@ID_EC INT,
		@SEGMENT INT,
		@COMP INT,
		@TYPE VARCHAR(100),
		@COD_PLAN INT,
		@COD_AFF INT,
		@Active BIT,
		@PersonType VARCHAR(100),
		@CODSIT INT,
		@WAS_BLOCKED_FINANCE INT,
		@COD_SITUATION_RISK INT,
		@IS_PROVIDER INT,
		@BRANCH_BUSINESS INT,
		@RISK_SITUATION_LIST [CODE_TYPE] READONLY
	',
	@CPF_CNPJ = @CPF_CNPJ,
	@COD_REP = @COD_REP,
	@ID_EC = @ID_EC,
	@SEGMENT = @SEGMENT,
	@COMP = @COMP,
	@TYPE = @TYPE,
	@COD_PLAN = @COD_PLAN,
	@COD_AFF = @COD_AFF,
	@Active = @Active,
	@PersonType = @PersonType,
	@CODSIT = @CODSIT,
	@WAS_BLOCKED_FINANCE = @WAS_BLOCKED_FINANCE,
	@COD_SITUATION_RISK = @COD_SITUATION_RISK,
	@IS_PROVIDER = @IS_PROVIDER,
	@BRANCH_BUSINESS = @BRANCH_BUSINESS,
	@RISK_SITUATION_LIST = @RISK_SITUATION_LIST

END;
go

IF (OBJECT_ID('[SP_VALIDATE_TRANSACTION]') IS NOT NULL)
    DROP PROCEDURE [SP_VALIDATE_TRANSACTION]
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION]
/*------------------------------------------------------------------------------------------------------------------------------------------------
    Project.......: TKPP
--------------------------------------------------------------------------------------------------------------------------------------------------
Author                      VERSION        Date         Description
--------------------------------------------------------------------------------------------------------------------------------------------------
    Kennedy Alef            V1          27/07/2018      Creation
    Gian Luca Dalle Cort    V1          14/08/2018      Changed
    Lucas Aguiar            v3          17-04-2019      Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções
    Lucas Aguiar            v4          23-04-2019      Parametro opc cod ec
    Kennedy Alef	        v5	        12-11-2019      Card holder name, doc holder, logical number
    Luiz Aquino             V6          17-03-2020      Adicionaar validações de risco (ET-465)
--------------------------------------------------------------------------------------------------------------------------------------------------*/
  (
    @TERMINALID      INT,
    @TYPETRANSACTION VARCHAR(100),
    @AMOUNT          DECIMAL(22,6),
    @QTY_PLOTS       INT,
    @PAN             VARCHAR(100),
    @BRAND           VARCHAR(200),
    @TRCODE          VARCHAR(200),
    @TERMINALDATE    DATETIME,
    @CODPROD_ACQ     INT,
    @TYPE            VARCHAR(100),
    @COD_BRANCH      INT,
	@CODE_SPLIT		 INT = NULL,
	@COD_EC          INT = NULL,
	@HOLDER_NAME     VARCHAR(100) = NULL,
	@HOLDER_DOC		 VARCHAR(100) = NULL,
	@LOGICAL_NUMBER  VARCHAR(100) = NULL
  )
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
  DECLARE @LIMIT DECIMAL(22,6);
  DECLARE @COD_AFFILIATOR INT;
  DECLARE @PLAN_AFF INT;
  DECLARE @CODTR_RETURN INT;
  DECLARE @EC_TRANS INT;
  DECLARE @GEN_TITLES INT;
  DECLARE @ALLOWED_TRANSACTION  INT;

BEGIN

    SELECT
    TOP 1
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
       ,@GEN_TITLES = BRAND.GEN_TITLES
       ,@ALLOWED_TRANSACTION = (CASE WHEN EQUIPMENT_MODEL.ONLINE = 1
            THEN CASE WHEN ESTABLISHMENT_CONDITIONS.ONLINE_TRANSACTION = 1 AND COMMERCIAL_ESTABLISHMENT.REQUESTED_ONLINE_TRANSACTION = 1
                      THEN 1
                       ELSE 0
                 END
            ELSE CASE WHEN ESTABLISHMENT_CONDITIONS.PRESENCIAL_TRANSACTION = 1 AND COMMERCIAL_ESTABLISHMENT.REQUESTED_PRESENTIAL_TRANSACTION = 1
                        THEN 1
                        ELSE 0
                END
           END)
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
    LEFT JOIN ESTABLISHMENT_CONDITIONS
        ON COMMERCIAL_ESTABLISHMENT.COD_EC = ESTABLISHMENT_CONDITIONS.COD_EC AND ESTABLISHMENT_CONDITIONS.ACTIVE= 1
    WHERE ASS_TAX_DEPART.ACTIVE = 1
    AND [ASS_DEPTO_EQUIP].ACTIVE = 1
    AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 2
    AND EQUIPMENT.COD_EQUIP = @TERMINALID
    AND LOWER(TRANSACTION_TYPE.NAME) = @TYPETRANSACTION
    AND ASS_TAX_DEPART.QTY_INI_PLOTS <= @QTY_PLOTS
    AND ASS_TAX_DEPART.QTY_FINAL_PLOTS >= @QTY_PLOTS
    AND (BRAND.[NAME] = @BRAND
    OR BRAND.COD_BRAND IS NULL)

    IF (@COD_EC IS NOT NULL)
        SET @EC_TRANS = @COD_EC;
    ELSE
        SET @EC_TRANS = @CODEC;


    IF @AMOUNT > @LIMIT
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
                                    ,@COMMENT = '402 - Transaction limit value exceeded"d'
                                    ,@TERMINALDATE = @TERMINALDATE
                                    ,@TYPE = @TYPE
                                    ,@COD_COMP = @COD_COMP
                                    ,@COD_AFFILIATOR = @COD_AFFILIATOR
                                    ,@SOURCE_TRAN = 2
                                    ,@CODE_SPLIT = @CODE_SPLIT
                                    ,@COD_EC = @EC_TRANS
                                    ,@HOLDER_NAME=@HOLDER_NAME
                                    ,@HOLDER_DOC=@HOLDER_DOC
                                    ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;


            THROW 60002, '402', 1;

    END;

    IF @CODTX IS NULL
    /* PROCEDURE DE REGISTRO DE TRANSAÇÕES NEGADAS*/
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
                                    ,@HOLDER_NAME=@HOLDER_NAME
                                    ,@HOLDER_DOC=@HOLDER_DOC
                                    ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;

        THROW 60002, '404', 1;
    END;

    IF @COD_AFFILIATOR IS NOT NULL
    BEGIN

        SELECT TOP 1
            @PLAN_AFF = COD_PLAN_TAX_AFF
        FROM PLAN_TAX_AFFILIATOR
        INNER JOIN AFFILIATOR
            ON AFFILIATOR.COD_AFFILIATOR = PLAN_TAX_AFFILIATOR.COD_AFFILIATOR
        WHERE PLAN_TAX_AFFILIATOR.COD_AFFILIATOR = @COD_AFFILIATOR
        AND @QTY_PLOTS BETWEEN QTY_INI_PLOTS AND QTY_FINAL_PLOTS
        AND COD_TTYPE = @TYPETRAN
        AND PLAN_TAX_AFFILIATOR.ACTIVE = 1

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
                                        ,@HOLDER_NAME=@HOLDER_NAME
                                        ,@HOLDER_DOC=@HOLDER_DOC
                                        ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;

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
                                    ,@HOLDER_NAME=@HOLDER_NAME
                                    ,@HOLDER_DOC=@HOLDER_DOC
                                    ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;


    THROW 60002, '003', 1;

    END

    IF @ACTIVE_EC = 0  OR @ALLOWED_TRANSACTION = 0
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
                                    ,@HOLDER_NAME=@HOLDER_NAME
                                    ,@HOLDER_DOC=@HOLDER_DOC
                                    ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;


        THROW 60002, '009', 1;
    END

    EXEC SP_VAL_LIMIT_EC @CODEC
					,@AMOUNT
					,@PAN = @PAN
					,@BRAND = @BRAND
					,@CODASS_DEPTO_TERMINAL = @CODASS
					,@COD_TTYPE = @TYPETRAN
					,@PLOTS = @QTY_PLOTS
					,@CODTAX_ASS = @CODTX
					,@CODETR = @TRCODE
					,@TYPE = @TYPE
					,@TERMINALDATE = @TERMINALDATE
					,@COD_COMP = @COD_COMP
					,@COD_AFFILIATOR = @COD_AFFILIATOR
					,@CODE_SPLIT = @CODE_SPLIT
					,@EC_TRANS = @EC_TRANS
					,@HOLDER_NAME=@HOLDER_NAME
					,@HOLDER_DOC=@HOLDER_DOC
					,@LOGICAL_NUMBER=@LOGICAL_NUMBER
					,@SOURCE_TRAN=2;



    EXEC @CODAC = SP_DEFINE_ACQ @TR_TYPE = @TYPETRAN
						   ,@COMPANY = @COMPANY
						   ,@QTY_PLOTS = @QTY_PLOTS
						   ,@BRAND = @BRAND
						   ,@COD_PR = @CODPROD_ACQ

    IF @CODAC = 0  BEGIN
        EXEC [SP_REG_TRANSACTION_DENIED]
            @AMOUNT = @AMOUNT
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
            ,@HOLDER_NAME=@HOLDER_NAME
            ,@HOLDER_DOC=@HOLDER_DOC
            ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;

    THROW 60002, '004', 1;

    END;

    IF @GEN_TITLES = 0
        AND @CODE_SPLIT IS NOT NULL
    BEGIN
        EXEC [SP_REG_TRANSACTION_DENIED]
            @AMOUNT = @AMOUNT
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
            ,@HOLDER_NAME=@HOLDER_NAME
            ,@HOLDER_DOC=@HOLDER_DOC
            ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;

    THROW 60002, '012', 1;
    END;



    EXECUTE [SP_REG_TRANSACTION]
        @AMOUNT
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
        ,@HOLDER_NAME=@HOLDER_NAME
        ,@HOLDER_DOC=@HOLDER_DOC
        ,@LOGICAL_NUMBER=@LOGICAL_NUMBER;

    SELECT
        @CODAC AS ACQUIRER
       ,@TRCODE AS TRAN_CODE
       ,@CODTR_RETURN AS COD_TRAN


END;
GO

IF (OBJECT_ID('[SP_VALIDATE_TRANSACTION_ON]') IS NOT NULL)
    DROP PROCEDURE [SP_VALIDATE_TRANSACTION_ON]
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION_ON]
    /*------------------------------------------------------------------------------------------------------------------------------------------                                        
   Procedure Name: [SP_VALIDATE_TRANSACTION]                                        
   Project.......: TKPP                                        
   ------------------------------------------------------------------------------------------------------------------------------------------------                                        
   Author			VERSION        Date                            Description                                        
   -------------------------------------------------------------------------------------------------------------------------------------------------                                        
   Kennedy Alef     V1			20/08/2018    Creation                                        
   Lucas Aguiar     v2			17-04-2019    Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções                            
   Lucas Aguiar     v4			23-04-2019    Parametro opc cod ec 
   Luiz Aquino      V6          17-03-2020      Adicionaar validações de risco (ET-465)
   ------------------------------------------------------------------------------------------------------------------------------------------------*/
(@TERMINALID VARCHAR(100)
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
, @LOGICAL_NUMBER VARCHAR(100) = NULL)
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

  DECLARE @ALLOWED_TRANSACTION  INT;

--DECLARE @PRODUCT_ACQ INT;                                
BEGIN
    SELECT @CODTX = ASS_TAX_DEPART.COD_ASS_TX_DEP
         , @CODPLAN = ASS_TAX_DEPART.COD_ASS_TX_DEP
         , @INTERVAL = ASS_TAX_DEPART.INTERVAL
         , @TERMINALACTIVE = EQUIPMENT.ACTIVE
         , @CODEC = COMMERCIAL_ESTABLISHMENT.COD_EC
         , @CODASS = [ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL
         , @COMPANY = COMPANY.COD_COMP
         , @TYPETRAN = TRANSACTION_TYPE.COD_TTYPE
         , @ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE
         , @BRANCH = BRANCH_EC.COD_BRANCH
         , @COD_COMP = COMPANY.COD_COMP
         , @LIMIT = COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT
         , @COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
         , @ONLINE = COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE
         , @GEN_TITLES = BRAND.GEN_TITLES
		 ,@ALLOWED_TRANSACTION = (CASE WHEN EQUIPMENT_MODEL.ONLINE = 1
            THEN CASE WHEN ESTABLISHMENT_CONDITIONS.ONLINE_TRANSACTION = 1 AND COMMERCIAL_ESTABLISHMENT.REQUESTED_ONLINE_TRANSACTION = 1
                      THEN 1
                       ELSE 0
                 END
            ELSE CASE WHEN ESTABLISHMENT_CONDITIONS.PRESENCIAL_TRANSACTION = 1 AND COMMERCIAL_ESTABLISHMENT.REQUESTED_PRESENTIAL_TRANSACTION = 1
                        THEN 1
                        ELSE 0
                END
           END)
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
			LEFT JOIN ESTABLISHMENT_CONDITIONS
				ON COMMERCIAL_ESTABLISHMENT.COD_EC = ESTABLISHMENT_CONDITIONS.COD_EC AND ESTABLISHMENT_CONDITIONS.ACTIVE= 1
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
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '402 - TRANSACTION ONLINE NOT ENABLE'
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 1
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002
                , '402'
                , 1;
        END;

    IF @AMOUNT > @LIMIT
        BEGIN
            EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '402 - Transaction limit value exceeded"d'
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 1
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002
                , '402'
                , 1;
        END;

    IF @CODTX IS NULL
/* PROCEDURE DE REGISTRO DE TRANSAÇÕES NEGADAS*/
        BEGIN
            EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '404 - PLAN/TAX NOT FOUND'
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 1
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002
                , '404'
                , 1;
        END;

    IF @TERMINALACTIVE = 0
        BEGIN
            EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '003 - Blocked terminal  '
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 1
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002
                , '003'
                , 1;
        END

    IF @ACTIVE_EC = 0 OR @ALLOWED_TRANSACTION = 0
        BEGIN
            EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '009 - Blocked commercial establishment'
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 1
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002
                , '009'
                , 1;
        END

    EXEC SP_VAL_LIMIT_EC @CODEC
        , @AMOUNT
        , @PAN = @PAN
        , @BRAND = @BRAND
        , @CODASS_DEPTO_TERMINAL = @CODASS
        , @COD_TTYPE = @TYPETRAN
        , @PLOTS = @QTY_PLOTS
        , @CODTAX_ASS = @CODTX
        , @CODETR = @TRCODE
        , @TYPE = @TYPE
        , @TERMINALDATE = @TERMINALDATE
        , @COD_COMP = @COD_COMP
        , @COD_AFFILIATOR = @COD_AFFILIATOR
        , @CODE_SPLIT = @CODE_SPLIT
        , @EC_TRANS = @EC_TRANS
        , @HOLDER_NAME=@HOLDER_NAME
        , @HOLDER_DOC=@HOLDER_DOC
        , @LOGICAL_NUMBER=@LOGICAL_NUMBER
        , @SOURCE_TRAN = 1;

    EXEC @CODAC = SP_DEFINE_ACQ @TR_TYPE = @TYPETRAN
        , @COMPANY = @COMPANY
        , @QTY_PLOTS = @QTY_PLOTS
        , @BRAND = @BRAND
        , @DOC_CREDITOR = @CREDITOR_DOC

-- DEFINIR SE PARCELA > 1 ENTAO , CREDITO PARCELADO                              
    IF @QTY_PLOTS > 1
        SET @TYPE_CREDIT = 2;
    ELSE
        SET @TYPE_CREDIT = 1;

    IF (@CREDITOR_DOC IS NOT NULL)
        BEGIN
            SELECT @CODPROD_ACQ = [PRODUCTS_ACQUIRER].COD_PR_ACQ
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
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '004 - Acquirer key not found for terminal '
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 1
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002
                , '004'
                , 1;
        END;
                          


    IF @GEN_TITLES = 0
        AND @CODE_SPLIT IS NOT NULL
        BEGIN
            EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
                , @PAN = @PAN
                , @BRAND = @BRAND
                , @CODASS_DEPTO_TERMINAL = @CODASS
                , @COD_TTYPE = @TYPETRAN
                , @PLOTS = @QTY_PLOTS
                , @CODTAX_ASS = @CODTX
                , @CODAC = NULL
                , @CODETR = @TRCODE
                , @COMMENT = '012 - PRIVATE LABELS ESTABLISHMENTS CAN NOT HAVE SPLIT'
                , @TERMINALDATE = @TERMINALDATE
                , @TYPE = @TYPE
                , @COD_COMP = @COD_COMP
                , @COD_AFFILIATOR = @COD_AFFILIATOR
                , @SOURCE_TRAN = 2
                , @CODE_SPLIT = @CODE_SPLIT
                , @COD_EC = @EC_TRANS
                , @CREDITOR_DOC = @CREDITOR_DOC
                , @HOLDER_NAME=@HOLDER_NAME
                , @HOLDER_DOC=@HOLDER_DOC
                , @LOGICAL_NUMBER=@LOGICAL_NUMBER;

            THROW 60002, '012', 1;
        END;

    EXECUTE [SP_REG_TRANSACTION] @AMOUNT
        , @PAN
        , @BRAND
        , @CODASS_DEPTO_TERMINAL = @CODASS
        , @COD_TTYPE = @TYPETRAN
        , @PLOTS = @QTY_PLOTS
        , @CODTAX_ASS = @CODTX
        , @CODAC = @CODAC
        , @CODETR = @TRCODE
        , @TERMINALDATE = @TERMINALDATE
        , @COD_ASS_TR_ACQ = @CODAC
        , @CODPROD_ACQ = @CODPROD_ACQ
        , @TYPE = @TYPE
        , @COD_COMP = @COD_COMP
        , @COD_AFFILIATOR = @COD_AFFILIATOR
        , @SOURCE_TRAN = 1
        , @POSWEB = 0
        --,@DESCRIPTION = @DESCRIPTION                      
        , @CODE_SPLIT = @CODE_SPLIT
        , @EC_TRANS = @EC_TRANS
        , @CREDITOR_DOC = @CREDITOR_DOC
        , @TRACKING_DESCRIPTION = @TRACKING
        , @DESCRIPTION = @DESCRIPTION_TRAN
        , @HOLDER_NAME=@HOLDER_NAME
        , @HOLDER_DOC=@HOLDER_DOC
        , @LOGICAL_NUMBER=@LOGICAL_NUMBER;
    --SELECT                                        
--  'ADQ'  AS ACQUIRER,                       
--  '1234567489' AS TRAN_CODE,                                      
--  'ESTABLISHMENT COMMERCIAL TEST' AS EC                                    
    SELECT EXTERNAL_DATA_EC_ACQ.[VALUE] AS EC
         , @TRCODE                      AS TRAN_CODE
         , ACQUIRER.NAME                AS ACQUIRER
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


IF (OBJECT_ID('[SP_VALIDATE_TRANSACTION_POSWEB]') IS NOT NULL)
    DROP PROCEDURE [SP_VALIDATE_TRANSACTION_POSWEB]
GO

CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION_POSWEB]
	/*---------------------------------------------------------------------------------------------------------------------------------------------                            
Project.......: TKPP                            
---------------------------------------------------------------------------------------------------------------------------------------------------                            
Author           VERSION        Date          Description                            
---------------------------------------------------------------------------------------------------------------------------------------------------                            
Kennedy Alef	  V1		  13/11/2018	  Creation                            
Lucas Aguiar	  v2		  17-04-2019	  Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções
Lucas Aguiar	  v4		  23-04-2019	  Parametro opc cod ec                
 Luiz Aquino      V6          17-03-2020      Adicionaar validações de risco (ET-465)
---------------------------------------------------------------------------------------------------------------------------------------------------*/
(
	@TERMINALID VARCHAR(100)
	,@TYPETRANSACTION VARCHAR(100)
	,@AMOUNT DECIMAL(22, 6)
	,@QTY_PLOTS INT
	,@PAN VARCHAR(100)
	,@BRAND VARCHAR(200)
	,@TRCODE VARCHAR(200)
	,@TERMINALDATE DATETIME = NULL
	,@CODPROD_ACQ INT = NULL
	,@TYPE VARCHAR(100)
	,@COD_BRANCH INT = NULL
	,@MID VARCHAR(100)
	,
	-- NEWS                
	 @COD_EC_AFFILIATOR INT
	,@COD_EQUIP_AFFILIATOR INT = NULL
	,@IDENTIFI_TRANSACTION VARCHAR(400) = NULL
	,@TRAN_DESCRIPTION VARCHAR(MAX)
	,@TRAN_DESC_ID INT = NULL
	,@TARIFF_MERCHANT_DEFAULT DECIMAL(22, 6)
	,@CODE_SPLIT INT = NULL
	,@COD_EC INT = NULL
)
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
DECLARE @FOUND INT;
DECLARE @MSG_ERRO VARCHAR(100);
-- POSWEB VALUES             
DECLARE @COD_TX_POSWEB INT;
DECLARE @COD_DEPTO_TERM_POSWEB INT;
DECLARE @INTERVAL_POSWEB INT;
DECLARE @MDR_POSWEB DECIMAL(22, 6);
DECLARE @ANTICIP_POSWEB DECIMAL(22, 6)
DECLARE @RATE_POSWEB DECIMAL(22, 6);
DECLARE @VALIDATE VARCHAR(200);
DECLARE @FOUND_POSWEB INT;
DECLARE @EC_TRANS INT;

BEGIN
          
	WITH CTE
	AS (
		SELECT ASS_TAX_DEPART.COD_ASS_TX_DEP
			,ASS_TAX_DEPART.INTERVAL
			,ASS_TAX_DEPART.PARCENTAGE AS [MDR]
			,ASS_TAX_DEPART.ANTICIPATION_PERCENTAGE AS [ANTICIPATION]
			,ASS_TAX_DEPART.RATE
			,EQUIPMENT.ACTIVE AS EQUIP_ACTIVE
			,COMMERCIAL_ESTABLISHMENT.COD_EC
			,[ASS_DEPTO_EQUIP].COD_ASS_DEPTO_TERMINAL
			,TRANSACTION_TYPE.COD_TTYPE
			,COMMERCIAL_ESTABLISHMENT.ACTIVE
			,BRANCH_EC.COD_BRANCH
			,COMPANY.COD_COMP
			,COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT
			,COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
			,COMMERCIAL_ESTABLISHMENT.ACTIVE AS EC_ACTIVE
			,EQUIPMENT.COD_EQUIP
			,COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE
			,(CASE WHEN EQUIPMENT_MODEL.ONLINE = 1
            THEN CASE WHEN ESTABLISHMENT_CONDITIONS.ONLINE_TRANSACTION = 1 AND COMMERCIAL_ESTABLISHMENT.REQUESTED_ONLINE_TRANSACTION = 1
                      THEN 1
                       ELSE 0
                 END
            ELSE CASE WHEN ESTABLISHMENT_CONDITIONS.PRESENCIAL_TRANSACTION = 1 AND COMMERCIAL_ESTABLISHMENT.REQUESTED_PRESENTIAL_TRANSACTION = 1
                        THEN 1
                        ELSE 0
                END
           END) ALLOWED_TRANSACTION
		--INTO #TRAN_TEMP                           
		FROM [ASS_DEPTO_EQUIP]
		LEFT JOIN EQUIPMENT ON EQUIPMENT.COD_EQUIP = [ASS_DEPTO_EQUIP].COD_EQUIP
		LEFT JOIN EQUIPMENT_MODEL ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL
		LEFT JOIN DEPARTMENTS_BRANCH ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = [ASS_DEPTO_EQUIP].COD_DEPTO_BRANCH
		LEFT JOIN BRANCH_EC ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
		LEFT JOIN DEPARTMENTS ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
		LEFT JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
		LEFT JOIN COMPANY ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
		LEFT JOIN ASS_TAX_DEPART ON ASS_TAX_DEPART.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
		LEFT JOIN BRAND ON BRAND.COD_BRAND = ASS_TAX_DEPART.COD_BRAND
		LEFT JOIN TRANSACTION_TYPE ON TRANSACTION_TYPE.COD_TTYPE = ASS_TAX_DEPART.COD_TTYPE
		LEFT JOIN ESTABLISHMENT_CONDITIONS ON COMMERCIAL_ESTABLISHMENT.COD_EC = ESTABLISHMENT_CONDITIONS.COD_EC AND ESTABLISHMENT_CONDITIONS.ACTIVE= 1
		WHERE ASS_TAX_DEPART.ACTIVE = 1
			AND [ASS_DEPTO_EQUIP].ACTIVE = 1
			AND EQUIPMENT.SERIAL = @TERMINALID
			AND LOWER(TRANSACTION_TYPE.NAME) = @TYPETRANSACTION
			AND ASS_TAX_DEPART.QTY_INI_PLOTS <= @QTY_PLOTS
			AND ASS_TAX_DEPART.QTY_FINAL_PLOTS >= @QTY_PLOTS
			AND ASS_TAX_DEPART.COD_SOURCE_TRAN = 1
			AND (
				BRAND.[NAME] = @BRAND
				OR BRAND.COD_BRAND IS NULL
				)
		)
	--AND (BRAND.[NAME] = NULL            
	--OR BRAND.COD_BRAND IS NULL))            
	SELECT @VALIDATE = dbo.FNC_REG_DENIED_TRAN(CTE.TRANSACTION_ONLINE, CTE.TRANSACTION_LIMIT, @AMOUNT, COD_ASS_TX_DEP, CTE.EQUIP_ACTIVE, IIF(CTE.EC_ACTIVE = 1 AND CTE.ALLOWED_TRANSACTION = 1, 1, 0), COD_EC)
		,@FOUND = COUNT(*)
		,@CODTX = CTE.COD_ASS_TX_DEP
		,@INTERVAL = CTE.INTERVAL
		,@CODASS = cte.COD_ASS_DEPTO_TERMINAL
		,@COMPANY = CTE.COD_COMP
		,@TYPETRAN = cte.COD_TTYPE
		,@BRANCH = cte.COD_BRANCH
		,@COD_AFFILIATOR = CTE.COD_AFFILIATOR
		,@INTERVAL_POSWEB = cte.INTERVAL
		,@MDR_POSWEB = cte.MDR
		,@ANTICIP_POSWEB = cte.ANTICIPATION
		,@RATE_POSWEB = cte.RATE		
	FROM CTE
	GROUP BY CTE.TRANSACTION_ONLINE
		,CTE.TRANSACTION_LIMIT
		,COD_ASS_TX_DEP
		,CTE.EQUIP_ACTIVE
		,CTE.EC_ACTIVE
		,CTE.COD_EC
		,CTE.COD_ASS_TX_DEP
		,CTE.INTERVAL
		,CTE.COD_ASS_DEPTO_TERMINAL
		,CTE.COD_COMP
		,CTE.COD_TTYPE
		,CTE.COD_BRANCH
		,CTE.COD_AFFILIATOR
		,CTE.MDR
		,CTE.ANTICIPATION
		,cte.RATE
		,ALLOWED_TRANSACTION

	IF(@COD_EC IS NULL)
		SET @EC_TRANS = @COD_EC;
	ELSE
		SET @EC_TRANS = @COD_EC_AFFILIATOR;

	IF @FOUND IS NULL
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
			,@COMMENT = '450 - Plan/tax not found for default EC'
			,@TERMINALDATE = @TERMINALDATE
			,@TYPE = @TYPE
			,@COD_COMP = @COD_COMP
			,@COD_AFFILIATOR = @COD_AFFILIATOR
			,@POSWEB = 1
			,@SOURCE_TRAN = 1
			,@CODE_SPLIT = @CODE_SPLIT
			,@COD_EC = @EC_TRANS;

		THROW 60002
			,'450'
			,1;
	END
	ELSE IF @VALIDATE IS NOT NULL
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
			,@COMMENT = @VALIDATE
			,@TERMINALDATE = @TERMINALDATE
			,@TYPE = @TYPE
			,@COD_COMP = @COD_COMP
			,@COD_AFFILIATOR = @COD_AFFILIATOR
			,@POSWEB = 1
			,@SOURCE_TRAN = 1
			,@CODE_SPLIT = @CODE_SPLIT
			,@COD_EC = @EC_TRANS;

		SELECT @MSG_ERRO = dbo.[FNC_DEFINE_ERRROR](@VALIDATE);

		THROW 60002
			,@MSG_ERRO
			,1;
	END;

	EXEC @CODAC = SP_DEFINE_ACQ @TR_TYPE = @TYPETRAN
		,@COMPANY = @COMPANY
		,@QTY_PLOTS = @QTY_PLOTS
		,@BRAND = @BRAND

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
			,@POSWEB = 1
			,@SOURCE_TRAN = 1
			,@CODE_SPLIT = @CODE_SPLIT
			,@COD_EC = @EC_TRANS;

		THROW 60002
			,'004'
			,1;
	END;

	-- DEFINIR SE PARCELA > 1 ENTAO , CREDITO PARCELADO                  
	IF @QTY_PLOTS > 1
		SET @TYPE_CREDIT = 2;
	ELSE
		SET @TYPE_CREDIT = 1;

	SELECT @CODPROD_ACQ = [PRODUCTS_ACQUIRER].COD_PR_ACQ
	FROM [PRODUCTS_ACQUIRER]
	INNER JOIN BRAND ON BRAND.COD_BRAND = PRODUCTS_ACQUIRER.COD_BRAND
	INNER JOIN ASS_TR_TYPE_COMP ON ASS_TR_TYPE_COMP.COD_AC = PRODUCTS_ACQUIRER.COD_AC
		AND ASS_TR_TYPE_COMP.COD_BRAND = ASS_TR_TYPE_COMP.COD_BRAND
	WHERE ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = @CODAC
		AND [PRODUCTS_ACQUIRER].PLOT_VALUE = @TYPE_CREDIT
		AND BRAND.NAME = @BRAND
		AND ASS_TR_TYPE_COMP.COD_SOURCE_TRAN = 1
		
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
		,@POSWEB = 1
		,@COD_EC = @COD_EC_AFFILIATOR
		,@COD_DESCRIPTION = @TRAN_DESC_ID
		,@DESCRIPTION = @TRAN_DESCRIPTION
		,@VALUE = @TARIFF_MERCHANT_DEFAULT
		,@TRACKING_DESCRIPTION = @IDENTIFI_TRANSACTION
		,@COD_EQUIP = @COD_EQUIP_AFFILIATOR
		,@MDR = @MDR_POSWEB
		,@ANTICIP = @ANTICIP_POSWEB
		,@TARIFF = @RATE_POSWEB
		,@SOURCE_TRAN = 1
		,@CODE_SPLIT = @CODE_SPLIT
		,@EC_TRANS = @EC_TRANS;

	SELECT EXTERNAL_DATA_EC_ACQ.[VALUE] AS EC
		,@TRCODE AS TRAN_CODE
		,ACQUIRER.NAME AS ACQUIRER
	FROM ASS_TR_TYPE_COMP
	INNER JOIN ACQUIRER ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
	LEFT JOIN EXTERNAL_DATA_EC_ACQ ON EXTERNAL_DATA_EC_ACQ.COD_AC = ASS_TR_TYPE_COMP.COD_AC
	WHERE
		--ISNULL(EXTERNAL_DATA_EC_ACQ.[NAME],'MID') = 'MID' AND                     
		ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = @CODAC
END;
GO


-----------------------------
-- Atualizar legado 

-- FAVOR REVISAR
-----------------------------

IF OBJECT_ID('tempdb..#ecs') IS NOT NULL
    DROP TABLE #ecs

CREATE TABLE #ecs
(
    COD_DEPTO_BRANCH INT,
    COD_BRANCH INT,
    COD_EC INT,
    COD_USER INT,
    COD_COMP INT
)

INSERT INTO #ecs (COD_DEPTO_BRANCH, COD_BRANCH, COD_EC, COD_USER, COD_COMP)
select ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH,  bec.COD_BRANCH, ce.COD_EC, CE.COD_USER, ce.COD_COMP
from ASS_DEPTO_EQUIP
inner join DEPARTMENTS_BRANCH DB on ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DB.COD_DEPTO_BRANCH
inner join BRANCH_EC BEC on BEC.COD_BRANCH = DB.COD_BRANCH
inner join COMMERCIAL_ESTABLISHMENT CE on BEC.COD_EC = CE.COD_EC
where ASS_DEPTO_EQUIP.ACTIVE = 1
group by ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH, bec.COD_BRANCH, ce.COD_EC, ce.COD_USER,ce.COD_COMP


IF OBJECT_ID('tempdb..#ecs_info') IS NOT NULL
    DROP TABLE #ecs_info

CREATE TABLE #ecs_info
(
    COD_DEPTO_BRANCH INT,
    COD_BRANCH INT,
    COD_EC INT,
    COD_USER INT,
    COD_COMP INT,
    [ONLINE] INT,
    [OFFLINE] INT
)

INSERT INTO #ecs_info (COD_DEPTO_BRANCH, COD_BRANCH, COD_EC, COD_USER, COD_COMP, [ONLINE], [OFFLINE])
SELECT e.COD_DEPTO_BRANCH
     , e.COD_BRANCH
     , e.COD_EC
     , e.COD_USER
     , e.COD_COMP
     , CASE WHEN EXISTS(SELECT top 1 1
            from ASS_DEPTO_EQUIP a
            join EQUIPMENT  eq on eq.COD_EQUIP = a.COD_EQUIP
            join EQUIPMENT_MODEL EM on eq.COD_MODEL = EM.COD_MODEL
            where a.COD_DEPTO_BRANCH = e.COD_DEPTO_BRANCH AND a.ACTIVE = 1 AND EM.ONLINE = 1
      )  THEN 1 ELSE 0 END ONLINE
      , CASE WHEN EXISTS(SELECT top 1 1
                from ASS_DEPTO_EQUIP a
                join EQUIPMENT  eq on eq.COD_EQUIP = a.COD_EQUIP
                join EQUIPMENT_MODEL EM on eq.COD_MODEL = EM.COD_MODEL
                where a.COD_DEPTO_BRANCH = e.COD_DEPTO_BRANCH AND a.ACTIVE = 1 AND (EM.ONLINE IS NULL OR EM.ONLINE = 0)
          ) THEN 1 ELSE 0 END [OFFLINE]
FROM #ecs e
order by e.COD_EC

INSERT INTO ESTABLISHMENT_CONDITIONS_HIST (COD_EC_CONDIT, COD_COMP, COD_USER, COD_EC, CREATED_AT, MODIFY_DATE, ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT)
SELECT COD_EC_CONDIT, COD_COMP, COD_USER, COD_EC, CREATED_AT, GETDATE(), ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT FROM ESTABLISHMENT_CONDITIONS

DELETE FROM ESTABLISHMENT_CONDITIONS

INSERT INTO ESTABLISHMENT_CONDITIONS (COD_COMP, COD_USER, COD_EC, CREATED_AT, MODIFY_DATE, ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT)
SELECT COD_COMP, COD_USER, COD_EC, GETDATE(), GETDATE(), 1, 0, 0, 0 FROM COMMERCIAL_ESTABLISHMENT
WHERE ACTIVE = 1 AND COD_RISK_SITUATION IN (SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE [NAME] IN ('Pending risk Analysis', 'Denied for Risk', 'In Analysis'))

INSERT INTO ESTABLISHMENT_CONDITIONS (COD_COMP, COD_USER, COD_EC, CREATED_AT, MODIFY_DATE, ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT)
SELECT COMMERCIAL_ESTABLISHMENT.COD_COMP, COMMERCIAL_ESTABLISHMENT.COD_USER, COMMERCIAL_ESTABLISHMENT.COD_EC, GETDATE(), GETDATE(), 1, 0, 0, 1 FROM COMMERCIAL_ESTABLISHMENT
WHERE ACTIVE = 1 AND COD_COMP IS NOT NULL AND COD_RISK_SITUATION IN (SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE [NAME] IN ('Released by Risk'))

UPDATE COMMERCIAL_ESTABLISHMENT
SET COD_SITUATION = (SELECT COD_SITUATION FROM SITUATION WHERE SITUATION.NAME = 'LOCKED FINANCIAL SCHEDULE'),
    NOTE_FINANCE_SCHEDULE = 'Pendente aprovação dos documentos'
WHERE ACTIVE = 1 AND COD_COMP IS NOT NULL AND COD_RISK_SITUATION IN (SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE [NAME] IN ('Pending risk Analysis', 'Denied for Risk', 'In Analysis'))

INSERT INTO ESTABLISHMENT_CONDITIONS (COD_COMP, COD_USER, COD_EC, CREATED_AT, MODIFY_DATE, ACTIVE, PRESENCIAL_TRANSACTION, ONLINE_TRANSACTION, DOCUMENT)
SELECT COD_COMP, COD_USER, cod_ec, GETDATE(), GETDATE(), 1, [OFFLINE], [ONLINE], 1 FROM #ecs_info

GO

-----------------------------
-- ET-648 Pesquisa de Risco B2e
-----------------------------
IF NOT EXISTS (SELECT 1	FROM sys.columns WHERE NAME = N'CLAIMS' AND object_id = OBJECT_ID(N'ACCESS_APPAPI'))
BEGIN
	ALTER TABLE ACCESS_APPAPI ADD CLAIMS VARCHAR(30)
END
GO

IF (SELECT COUNT(*) FROM ACCESS_APPAPI WHERE APPNAME = 'B2E') = 0
	INSERT INTO ACCESS_APPAPI (APPNAME,CLIENT_ID,[NAME],COD_COMP,SECRETKEY,COD_AFFILIATOR,ACTIVE,CLAIMS) VALUES ('B2E','kug-w-er=f+-chgfdFIUREIRGJIFJ','B2E',8,'hfbhvbhGTrewScVRetYYdeEdDfgfGghFDE4wiHuiuOJOPIJE3EWde653wrsedt56rG-09876657&_KIFDR%',NULL,1,'8.7');
GO

IF OBJECT_ID('SP_VAL_USER_APP_ACESS_CLAIM') IS NOT NULL DROP PROCEDURE SP_VAL_USER_APP_ACESS_CLAIM;
GO
CREATE PROCEDURE SP_VAL_USER_APP_ACESS_CLAIM
/*--------------------------------------------------------------------------------------------
    Procedure Name: [SP_VAL_USER_APP_ACESS_CLAIM]
    Project.......: TKPP
    ------------------------------------------------------------------------------------------
    Author                          VERSION        Date                            Description
    ------------------------------------------------------------------------------------------
    Luiz Aquino                     V1         	2020-02-13 				Creation
    Caike Uchoa						V2			2020-03-12				Add field CLAIMS
----------------------------------------------------------------------------------------------*/
(
	@Username VARCHAR(200)
 	, @Password VARCHAR(500)
) AS

BEGIN
	SELECT COD_COMP, COD_AFFILIATOR, CLAIMS, COD_ACCESS_APP FROM ACCESS_APPAPI WHERE [NAME] = @Username AND SECRETKEY = @Password AND CLAIMS IS NOT NULL
END
GO

IF OBJECT_ID('RESEARCH_RISK_TYPE') IS NOT NULL DROP TABLE RESEARCH_RISK_TYPE;
GO
	CREATE TABLE RESEARCH_RISK_TYPE (
		COD_RESEARCH_RISK_TYPE 	INT IDENTITY(1,1) PRIMARY KEY,
		CODE 					VARCHAR(20),
		CODE_POLICY				VARCHAR(100) NULL,
		ACTIVE					INT DEFAULT 1,
		DOCUMENT_TYPE			VARCHAR(5)
	);
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'values=[INITIAL,MONTHLY,YEARLY]' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_TYPE', @level2type=N'COLUMN',@level2name=N'CODE';
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'CodigoInstituicao on JSON request B2e' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_TYPE', @level2type=N'COLUMN',@level2name=N'CODE_POLICY';
GO

IF (SELECT COUNT(*)	FROM RESEARCH_RISK_TYPE WHERE CODE IN ('INITIAL', 'MONTHLY', 'YEARLY')) > 0 DELETE FROM RESEARCH_RISK_TYPE;
GO

-- PF
INSERT INTO RESEARCH_RISK_TYPE VALUES ('INITIAL', '0181E3C6-0C2F-4719-B117-04398A47CBC2', 1, 'CPF');
INSERT INTO RESEARCH_RISK_TYPE VALUES ('MONTHLY', '0181E3C6-0C2F-4719-B117-04398A47CBC2', 1, 'CPF');
INSERT INTO RESEARCH_RISK_TYPE VALUES ('YEARLY',  '0181E3C6-0C2F-4719-B117-04398A47CBC2', 1, 'CPF');
-- PJ e MEI
INSERT INTO RESEARCH_RISK_TYPE VALUES ('INITIAL', 'E3A03047-9BA6-4A68-AF81-741F4382AFA9', 1, 'CNPJ');
INSERT INTO RESEARCH_RISK_TYPE VALUES ('MONTHLY', 'E3A03047-9BA6-4A68-AF81-741F4382AFA9', 1, 'CNPJ');
INSERT INTO RESEARCH_RISK_TYPE VALUES ('YEARLY',  'E3A03047-9BA6-4A68-AF81-741F4382AFA9', 1, 'CNPJ');

IF OBJECT_ID('RESEARCH_RISK') IS NOT NULL DROP TABLE RESEARCH_RISK;
GO
	CREATE TABLE RESEARCH_RISK (
		COD_RESEARCH_RISK		INT IDENTITY(1,1) NOT NULL,
		COD_EC 					INT NULL,
		COD_USER				INT NULL,
		COD_RESEARCH_RISK_TYPE	INT NULL,
		CREATED_AT				DATETIME DEFAULT dbo.FN_FUS_UTF(GETDATE()),
		SEND_AT					DATETIME NULL,
		MODIFY_AT				DATETIME NULL,
		COD_STATUS				INT DEFAULT((0)),
		CONSTRAINT [PK_RESEARCH_RISK] PRIMARY KEY CLUSTERED( [COD_RESEARCH_RISK] ASC) WITH (
			STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF
		) ON [PRIMARY]
	) ON [PRIMARY]
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'using CodigoPropostaCliente on JSON response and request' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK', @level2type=N'COLUMN',@level2name=N'COD_RESEARCH_RISK';
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0: Não enviado, 1: Enviado, 2: Recebido, 3:Falha' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK', @level2type=N'COLUMN',@level2name=N'COD_STATUS';
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'COD_EC' AND object_id = OBJECT_ID(N'RESEARCH_RISK'))
BEGIN
	ALTER TABLE [dbo].[RESEARCH_RISK] WITH CHECK ADD  CONSTRAINT [FK_RESEARCH_RISK_EC] FOREIGN KEY([COD_EC]) REFERENCES [dbo].[COMMERCIAL_ESTABLISHMENT] ([COD_EC])
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'COD_USER' AND object_id = OBJECT_ID(N'RESEARCH_RISK'))
BEGIN
	ALTER TABLE [dbo].[RESEARCH_RISK] WITH CHECK ADD  CONSTRAINT [FK_RESEARCH_RISK_USERS] FOREIGN KEY([COD_USER]) REFERENCES [dbo].[USERS] ([COD_USER])
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'COD_RESEARCH_RISK_TYPE' AND object_id = OBJECT_ID(N'RESEARCH_RISK'))
BEGIN
	ALTER TABLE [dbo].[RESEARCH_RISK] WITH CHECK ADD  CONSTRAINT [FK_RESEARCH_RISK_RRT] FOREIGN KEY([COD_RESEARCH_RISK_TYPE]) REFERENCES [dbo].[RESEARCH_RISK_TYPE] ([COD_RESEARCH_RISK_TYPE])
END
GO

--IF (SELECT COUNT(*)	FROM RESEARCH_RISK) = 0
	-- #3 TEST INITIAL RESEARCH PJ
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (427, 4683, 4, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (433, 4683, 4, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (1172, 4683, 4, 0);
	---- #3 TEST INITIAL RESEARCH PF
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (10, 4683, 1, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (11, 4683, 1, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (16, 4683, 1, 0);
	--
	---- #1 TEST MONTHLY RESEARCH PJ
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS, CREATED_AT) VALUES (440, 4683, 5, 0, '2020-02-10 10:15:43.453');
	---- #1 TEST MONTHLY RESEARCH PF
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS, CREATED_AT) VALUES (411, 4683, 5, 0, '2020-02-06 13:15:43.453');
	--
	---- #1 TEST YEARLY RESEARCH PJ
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS, CREATED_AT) VALUES (474, 4683, 6, 0, '2019-03-10 10:15:43.453');
	---- #1 TEST YEARLY RESEARCH PF
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS, CREATED_AT) VALUES (578, 4683, 6, 0, '2020-02-06 13:15:43.453');
	--
	--INSERT INTO RESEARCH_RISK (COD_EC,COD_USER,COD_RESEARCH_RISK_TYPE,CREATED_AT,COD_STATUS) VALUES	(2192	,474 ,4,CURRENT_TIMESTAMP,0);
	--INSERT INTO RESEARCH_RISK (COD_EC,COD_USER,COD_RESEARCH_RISK_TYPE,CREATED_AT,COD_STATUS) VALUES	(13		,474 ,1,CURRENT_TIMESTAMP,0);
	--INSERT INTO RESEARCH_RISK (COD_EC,COD_USER,COD_RESEARCH_RISK_TYPE,CREATED_AT,COD_STATUS) VALUES	(40		,474 ,1,CURRENT_TIMESTAMP,0);
	--INSERT INTO RESEARCH_RISK (COD_EC,COD_USER,COD_RESEARCH_RISK_TYPE,CREATED_AT,COD_STATUS) VALUES	(42		,474 ,1,CURRENT_TIMESTAMP,0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (2262, 4683, 4, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (2162, 4683, 4, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (2192, 4683, 4, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (2435, 4683, 4, 0);
	--INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (2599, 4683, 4, 0);
--GO

IF OBJECT_ID('RESEARCH_RISK_RESPONSE') IS NOT NULL DROP TABLE RESEARCH_RISK_RESPONSE;
GO
	CREATE TABLE RESEARCH_RISK_RESPONSE (
		COD_RESEARCH_RISK_RESPONSE	INT IDENTITY(1,1) NOT NULL,
		COD_RESEARCH_RISK 			INT NULL,
		BID_ID						VARCHAR(100),
		SITUATION_RISK				VARCHAR(50),
		MESSAGE_SITUATION			VARCHAR(500),
		CODE_POLICY					VARCHAR(100),
		CNAE						VARCHAR(10),
		STATE_REGISTRATION			VARCHAR(20),
		CPF_CNPJ					VARCHAR(20),
		NAME_EC						VARCHAR(200),
		ACTIVE						INT DEFAULT((1)),
		CREATED_AT					DATETIME DEFAULT dbo.FN_FUS_UTF(GETDATE()),
		CONSTRAINT [PK_RESEARCH_RISK_RESPONSE] PRIMARY KEY CLUSTERED( [COD_RESEARCH_RISK_RESPONSE] ASC) WITH (
			STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF
		) ON [PRIMARY]
	) ON [PRIMARY]
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'B2e ID research' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_RESPONSE', @level2type=N'COLUMN',@level2name=N'BID_ID';
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Situacao on JSON response' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_RESPONSE', @level2type=N'COLUMN',@level2name=N'SITUATION_RISK';
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mensagem on JSON response' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_RESPONSE', @level2type=N'COLUMN',@level2name=N'MESSAGE_SITUATION';
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'COD_RESEARCH_RISK' AND object_id = OBJECT_ID(N'RESEARCH_RISK_RESPONSE'))
BEGIN
	ALTER TABLE [dbo].[RESEARCH_RISK_RESPONSE] WITH CHECK ADD  CONSTRAINT [FK_RESEARCH_RISK_RESPONSE_RR] FOREIGN KEY([COD_RESEARCH_RISK]) REFERENCES [dbo].[RESEARCH_RISK] ([COD_RESEARCH_RISK])
END
GO

IF OBJECT_ID('RESEARCH_RISK_RESPONSE_DETAILS') IS NOT NULL DROP TABLE RESEARCH_RISK_RESPONSE_DETAILS;
GO
	CREATE TABLE RESEARCH_RISK_RESPONSE_DETAILS (
		COD_RESEARCH_RISK_RESPONSE_DETAILS 	INT IDENTITY(1,1) NOT NULL,
		COD_RESEARCH_RISK_RESPONSE 			INT NULL,
		CODE 								VARCHAR(20),
		COD_SITUATION						VARCHAR(10),
		SITUATION_DESCRIPTION 				VARCHAR(200),
		COD_PARTNER_EC						INT NULL,
		CPF_PARTNER_EC						VARCHAR(20) NULL,
		CONSTRAINT [PK_RESEARCH_RISK_RESPONSE_DETAILS] PRIMARY KEY CLUSTERED( [COD_RESEARCH_RISK_RESPONSE_DETAILS] ASC) WITH (
			STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF
		) ON [PRIMARY]
	) ON [PRIMARY]
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'FK with ADITIONAL_DATA_TYPE_EC, referencia as sócios de um PJ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_RESPONSE_DETAILS', @level2type=N'COLUMN',@level2name=N'COD_PARTNER_EC';
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'values=[PEP, RECEITA FEDERAL, OFAC]' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RESEARCH_RISK_RESPONSE_DETAILS', @level2type=N'COLUMN',@level2name=N'CODE';
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'COD_RESEARCH_RISK_RESPONSE' AND object_id = OBJECT_ID(N'RESEARCH_RISK_RESPONSE_DETAILS'))
BEGIN
	ALTER TABLE [dbo].[RESEARCH_RISK_RESPONSE_DETAILS] WITH CHECK ADD  CONSTRAINT [FK_RESEARCH_RISK_RESPONSE_DETAILS_RRR] FOREIGN KEY([COD_RESEARCH_RISK_RESPONSE]) REFERENCES [dbo].[RESEARCH_RISK_RESPONSE] ([COD_RESEARCH_RISK_RESPONSE])
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE NAME = N'COD_PARTNER_EC' AND object_id = OBJECT_ID(N'RESEARCH_RISK_RESPONSE_DETAILS'))
BEGIN
	ALTER TABLE [dbo].[RESEARCH_RISK_RESPONSE_DETAILS] WITH CHECK ADD  CONSTRAINT [FK_RESEARCH_RISK_RESPONSE_DETAILS_PARTNER] FOREIGN KEY([COD_PARTNER_EC]) REFERENCES [dbo].[ADITIONAL_DATA_TYPE_EC] ([COD_ADT_DATA])
END
GO

IF OBJECT_ID('VW_DATA_RESEARCH_RISK_EC') IS NOT NULL DROP VIEW VW_DATA_RESEARCH_RISK_EC;
GO
	CREATE VIEW [dbo].[VW_DATA_RESEARCH_RISK_EC]
	/*---------------------------------------------------------------------------------------- 
		View Name: [VW_DATA_RESEARCH_RISK_EC]		Project.......: TKPP 
	------------------------------------------------------------------------------------------ 
		Author              VERSION        Date         Description 
	------------------------------------------------------------------------------------------ 
		Marcus Gall			V1			04/03/2020		Create
	------------------------------------------------------------------------------------------*/ 
	AS
	SELECT
		COMMERCIAL_ESTABLISHMENT.COD_EC
		, COMMERCIAL_ESTABLISHMENT.NAME
		, COMMERCIAL_ESTABLISHMENT.DOCUMENT_TYPE
		, TYPE_ESTAB.CODE AS TYPE_ESTAB
   		, COMMERCIAL_ESTABLISHMENT.TRADING_NAME
   		, COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   		, COMMERCIAL_ESTABLISHMENT.DOCUMENT
   		, COMMERCIAL_ESTABLISHMENT.BIRTHDATE
		, ADDRESS_BRANCH.CEP
		, ADDRESS_BRANCH.ADDRESS AS STREET
		, ADDRESS_BRANCH.NUMBER
		, ADDRESS_BRANCH.COMPLEMENT
		, NEIGHBORHOOD.NAME AS NEIGHBORHOOD
   		, CITY.NAME AS CITY
   		, STATE.UF
		, SEX_TYPE.NAME AS SEX
		, (CASE WHEN COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB = 3 THEN 'R' ELSE 'C' END) AS TYPE_ADDRESS
		, CONTACT_BRANCH.DDD
		, CONTACT_BRANCH.NUMBER AS PHONE_NUMBER
		, (CASE 
			WHEN CONTACT_BRANCH.COD_TP_CONT = 1 THEN 'M' 
			WHEN CONTACT_BRANCH.COD_TP_CONT = 2 THEN 'R' 
			WHEN CONTACT_BRANCH.COD_TP_CONT = 3 THEN 'C' 
		  ELSE '' END) AS TYPE_CONTACT
	FROM COMMERCIAL_ESTABLISHMENT
	INNER JOIN TYPE_ESTAB ON TYPE_ESTAB.COD_TYPE_ESTAB = COMMERCIAL_ESTABLISHMENT.COD_TYPE_ESTAB
	INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
	INNER JOIN ADDRESS_BRANCH ON ADDRESS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH AND ADDRESS_BRANCH.ACTIVE = 1
	INNER JOIN NEIGHBORHOOD ON NEIGHBORHOOD.COD_NEIGH = ADDRESS_BRANCH.COD_NEIGH
	INNER JOIN CITY ON CITY.COD_CITY = NEIGHBORHOOD.COD_CITY
	INNER JOIN STATE ON STATE.COD_STATE = CITY.COD_STATE
	LEFT JOIN SEX_TYPE ON SEX_TYPE.COD_SEX = COMMERCIAL_ESTABLISHMENT.COD_SEX

	-- PELA NECESSIDADE DE RESGATAR CONTATOS MAIS RELEVANTES PARA A PESQUISA DE RISCO
	OUTER APPLY (SELECT TOP 1 * FROM CONTACT_BRANCH WHERE COD_BRANCH = BRANCH_EC.COD_BRANCH AND ACTIVE = 1 AND NUMBER IS NOT NULL ORDER BY NUMBER ASC, COD_TP_CONT ) AS CONTACT_BRANCH
GO

IF OBJECT_ID('SP_LS_EC_RESEARCH_RISK') IS NOT NULL DROP PROCEDURE SP_LS_EC_RESEARCH_RISK;
GO
CREATE PROCEDURE [dbo].[SP_LS_EC_RESEARCH_RISK]
/*----------------------------------------------------------------------------------------
    Procedure Name: [SP_FD_LS_RESEARCH_RISK]		Project.......: TKPP
------------------------------------------------------------------------------------------
    Author              VERSION        Date         Description
------------------------------------------------------------------------------------------
    Marcus Gall        V1          04/03/2020      Creation
------------------------------------------------------------------------------------------*/
(
    @RESEARCH_RISK_TYPE VARCHAR(20) = NULL
)
AS

DECLARE @QUERY_ NVARCHAR(MAX) = '';

BEGIN
	SET @QUERY_ = CONCAT(@QUERY_, '
	SELECT RESEARCH_RISK.COD_RESEARCH_RISK, RESEARCH_RISK_TYPE.CODE_POLICY
	, VW_DATA_RESEARCH_RISK_EC.COD_EC
	, VW_DATA_RESEARCH_RISK_EC.NAME
	, VW_DATA_RESEARCH_RISK_EC.DOCUMENT_TYPE
	, VW_DATA_RESEARCH_RISK_EC.TYPE_ESTAB
   	, VW_DATA_RESEARCH_RISK_EC.TRADING_NAME
   	, VW_DATA_RESEARCH_RISK_EC.CPF_CNPJ
   	, VW_DATA_RESEARCH_RISK_EC.DOCUMENT
   	, VW_DATA_RESEARCH_RISK_EC.BIRTHDATE
	, VW_DATA_RESEARCH_RISK_EC.CEP
	, VW_DATA_RESEARCH_RISK_EC.STREET
	, VW_DATA_RESEARCH_RISK_EC.NUMBER
	, VW_DATA_RESEARCH_RISK_EC.COMPLEMENT
	, VW_DATA_RESEARCH_RISK_EC.NEIGHBORHOOD
   	, VW_DATA_RESEARCH_RISK_EC.CITY
   	, VW_DATA_RESEARCH_RISK_EC.UF
	, VW_DATA_RESEARCH_RISK_EC.SEX
	, VW_DATA_RESEARCH_RISK_EC.TYPE_ADDRESS
	, VW_DATA_RESEARCH_RISK_EC.DDD
	, VW_DATA_RESEARCH_RISK_EC.PHONE_NUMBER
	, VW_DATA_RESEARCH_RISK_EC.TYPE_CONTACT
	, ADITIONAL_DATA_TYPE_EC.NAME AS PARTNER_NAME, ADITIONAL_DATA_TYPE_EC.CPF PARTNER_CPF, ADITIONAL_DATA_TYPE_EC.BIRTH_DATA AS PARTNER_BIRTHDATE
	, TYPE_PARTNER.NAME AS PARTNER_TYPE 
	FROM RESEARCH_RISK
	INNER JOIN RESEARCH_RISK_TYPE ON RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE = RESEARCH_RISK.COD_RESEARCH_RISK_TYPE
	INNER JOIN VW_DATA_RESEARCH_RISK_EC ON VW_DATA_RESEARCH_RISK_EC.COD_EC = RESEARCH_RISK.COD_EC
	LEFT JOIN ADITIONAL_DATA_TYPE_EC ON ADITIONAL_DATA_TYPE_EC.COD_EC = RESEARCH_RISK.COD_EC
	LEFT JOIN TYPE_PARTNER ON TYPE_PARTNER.COD_TYPE_PARTNER = ADITIONAL_DATA_TYPE_EC.COD_TYPE_PARTNER 
	WHERE RESEARCH_RISK.COD_STATUS = 0');

	IF @RESEARCH_RISK_TYPE IS NOT NULL
	BEGIN
		SET @QUERY_ = CONCAT(@QUERY_, ' AND RESEARCH_RISK_TYPE.CODE =''' + @RESEARCH_RISK_TYPE + '''');
	END
	
	IF @RESEARCH_RISK_TYPE = 'MONTHLY'
	BEGIN
		SET @QUERY_ = CONCAT(@QUERY_, ' AND DATEADD(MONTH, 1, RESEARCH_RISK.CREATED_AT) < GETDATE()');
	END
	
	IF @RESEARCH_RISK_TYPE = 'YEARLY'
	BEGIN
		SET @QUERY_ = CONCAT(@QUERY_, ' AND DATEADD(YEAR, 1, RESEARCH_RISK.CREATED_AT) < GETDATE()');
	END

	SET @QUERY_ = CONCAT(@QUERY_, ' ORDER BY RESEARCH_RISK.CREATED_AT');
	EXEC sp_executesql @QUERY_, N' @RESEARCH_RISK_TYPE VARCHAR(20)', @RESEARCH_RISK_TYPE = @RESEARCH_RISK_TYPE;
END
GO

IF OBJECT_ID('SP_UP_RESEARCH_RISK') IS NOT NULL DROP PROCEDURE SP_UP_RESEARCH_RISK;
GO
CREATE PROCEDURE [dbo].[SP_UP_RESEARCH_RISK]
/*----------------------------------------------------------------------------------------
    Procedure Name: [SP_UP_RESEARCH_RISK]		Project.......: TKPP
------------------------------------------------------------------------------------------
    Author              VERSION        Date         Description
------------------------------------------------------------------------------------------
    Marcus Gall        V1          04/03/2020      Creation
------------------------------------------------------------------------------------------*/
(
	@COD_RESEARCH_RISK INT
	, @COD_STATUS INT
)
AS

BEGIN
	IF @COD_STATUS = 1
		UPDATE RESEARCH_RISK SET SEND_AT = current_timestamp, COD_STATUS = @COD_STATUS WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;
		IF @@ROWCOUNT < 1
			THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK', 1;
END
GO

IF TYPE_ID('TP_RESEARCH_RISK_RESPONSE_DETAILS') IS NOT NULL DROP TYPE TP_RESEARCH_RISK_RESPONSE_DETAILS;
GO
CREATE TYPE [dbo].[TP_RESEARCH_RISK_RESPONSE_DETAILS]
/*----------------------------------------------------------------------------------------
	Type Name: [TP_RESEARCH_RISK_RESPONSE_DETAILS]						Project.......: TKPP
------------------------------------------------------------------------------------------
	Author			Version		Date        	Description
------------------------------------------------------------------------------------------
	Marcus Gall		V1			05/03/2020		Creation
------------------------------------------------------------------------------------------*/
AS TABLE(
	[CODE] [varchar](20) NOT NULL
	, [COD_SITUATION] [varchar](10) NULL
	, [SITUATION_DESCRIPTION] [varchar](200) NULL
	, [CPF_PARTNER_EC] [varchar](20) NULL
)
GO

IF OBJECT_ID('SP_REG_RESEARCH_RISK_RESPONSE') IS NOT NULL DROP PROCEDURE SP_REG_RESEARCH_RISK_RESPONSE;
GO
CREATE PROCEDURE [dbo].[SP_REG_RESEARCH_RISK_RESPONSE]
/*----------------------------------------------------------------------------------------
	Procedure Name: [SP_REG_RESEARCH_RISK_RESPONSE]					Project.......: TKPP
------------------------------------------------------------------------------------------
	Author			Version		Date        	Description
------------------------------------------------------------------------------------------
	Marcus Gall		V1			05/03/2020		Creation
------------------------------------------------------------------------------------------*/
(
	@COD_RESEARCH_RISK INT
	, @BID_ID VARCHAR(100) = NULL
	, @SITUATION_RISK VARCHAR(50) = NULL
	, @MESSAGE VARCHAR(500) = NULL
	, @CODE_POLICY VARCHAR(100) = NULL
	, @CNAE VARCHAR(10) = NULL
	, @STATE_REGISTRATION VARCHAR(20) = NULL
	, @CPF_CNPJ VARCHAR(20) = NULL
	, @NAME VARCHAR(200) = NULL
	, @LINES_RESEARCH_RISK_DETAILS TP_RESEARCH_RISK_RESPONSE_DETAILS READONLY
)
AS

	DECLARE @COD_RESEARCH_RISK_RESPONSE INT;
	DECLARE @COD_EC INT;
	DECLARE @DOCUMENT_TYPE VARCHAR(5);
	DECLARE @COD_RESEARCH_RISK_TYPE INT;

BEGIN
	-- BEGIN > REGISTRANDO O RESULTADO DA PESQUISA RECEBIDA
	IF (SELECT COUNT(RESEARCH_RISK.COD_RESEARCH_RISK) FROM RESEARCH_RISK WHERE RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK) = 0
		THROW 60001, 'BAD REQUEST, NOT FOUND RESEARCH_RISK REGISTER WITH PARAMETER >> @COD_RESEARCH_RISK', 1;

	UPDATE RESEARCH_RISK SET MODIFY_AT = current_timestamp, COD_STATUS = 2 WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;
	IF @@ROWCOUNT < 1
		THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK', 1;

	UPDATE RESEARCH_RISK_RESPONSE SET ACTIVE = 0 WHERE COD_RESEARCH_RISK = @COD_RESEARCH_RISK;
	INSERT INTO RESEARCH_RISK_RESPONSE (COD_RESEARCH_RISK, BID_ID, SITUATION_RISK, MESSAGE_SITUATION, CODE_POLICY, CNAE, STATE_REGISTRATION, CPF_CNPJ, NAME_EC) 
	VALUES (@COD_RESEARCH_RISK, @BID_ID, @SITUATION_RISK, @MESSAGE, @CODE_POLICY, @CNAE, @STATE_REGISTRATION, @CPF_CNPJ, @NAME);
	SET @COD_RESEARCH_RISK_RESPONSE = @@IDENTITY;
	IF @@ROWCOUNT < 1
		THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK_RESPONSE', 1;

	INSERT INTO RESEARCH_RISK_RESPONSE_DETAILS(COD_RESEARCH_RISK_RESPONSE, CODE, COD_SITUATION, SITUATION_DESCRIPTION, COD_PARTNER_EC, CPF_PARTNER_EC)
	SELECT @COD_RESEARCH_RISK_RESPONSE, LINES.[CODE], LINES.[COD_SITUATION], LINES.[SITUATION_DESCRIPTION], EC_PARTNERS.COD_ADT_DATA, LINES.[CPF_PARTNER_EC]
	FROM @LINES_RESEARCH_RISK_DETAILS AS LINES
	INNER JOIN RESEARCH_RISK ON RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK
	LEFT JOIN ADITIONAL_DATA_TYPE_EC AS EC_PARTNERS ON EC_PARTNERS.COD_EC = RESEARCH_RISK.COD_EC AND LINES.[CPF_PARTNER_EC] = EC_PARTNERS.CPF;
		IF @@ROWCOUNT < 1
		THROW 60001, 'COULD NOT UPDATE RESEARCH_RISK_RESPONSE', 1;
	

	-- BEGIN > AGENDAMENTO DE NOVAS PESQUISAS PROGRAMADAS (MONTHLY, YEARLY)
	SELECT TOP 1 @COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC, @DOCUMENT_TYPE = COMMERCIAL_ESTABLISHMENT.DOCUMENT_TYPE FROM COMMERCIAL_ESTABLISHMENT 
		INNER JOIN RESEARCH_RISK ON RESEARCH_RISK.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
		WHERE RESEARCH_RISK.COD_RESEARCH_RISK = @COD_RESEARCH_RISK;

	-- > YEARLY
	IF (SELECT COUNT(RESEARCH_RISK.COD_RESEARCH_RISK) FROM RESEARCH_RISK 
		INNER JOIN RESEARCH_RISK_TYPE ON RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE = RESEARCH_RISK.COD_RESEARCH_RISK_TYPE 
		WHERE RESEARCH_RISK_TYPE.CODE = 'YEARLY' AND RESEARCH_RISK.COD_STATUS IN (0, 1) AND RESEARCH_RISK.COD_EC = @COD_EC) = 0
	BEGIN
		SET @COD_RESEARCH_RISK_TYPE = (SELECT TOP 1 RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE FROM RESEARCH_RISK_TYPE WHERE RESEARCH_RISK_TYPE.CODE = 'YEARLY' AND RESEARCH_RISK_TYPE.DOCUMENT_TYPE = @DOCUMENT_TYPE AND RESEARCH_RISK_TYPE.ACTIVE = 1);
		INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (@COD_EC, NULL, @COD_RESEARCH_RISK_TYPE, 0);
	END

	SET @COD_RESEARCH_RISK_TYPE = 0;
			
	-- > MONTHLY
	IF (SELECT COUNT(RESEARCH_RISK.COD_RESEARCH_RISK) FROM RESEARCH_RISK 
		INNER JOIN RESEARCH_RISK_TYPE ON RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE = RESEARCH_RISK.COD_RESEARCH_RISK_TYPE 
		WHERE RESEARCH_RISK.COD_EC = @COD_EC 
		AND ((RESEARCH_RISK_TYPE.CODE = 'MONTHLY' AND RESEARCH_RISK.COD_STATUS IN (0, 1)) OR (RESEARCH_RISK_TYPE.CODE = 'YEARLY' AND RESEARCH_RISK.COD_STATUS IN (0, 1) AND DATEADD(YEAR, 1, RESEARCH_RISK.CREATED_AT) < GETDATE()))) = 0
	BEGIN
		SET @COD_RESEARCH_RISK_TYPE = (SELECT TOP 1 RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE FROM RESEARCH_RISK_TYPE WHERE RESEARCH_RISK_TYPE.CODE = 'MONTHLY' AND RESEARCH_RISK_TYPE.DOCUMENT_TYPE = @DOCUMENT_TYPE AND RESEARCH_RISK_TYPE.ACTIVE = 1);
		INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (@COD_EC, NULL, @COD_RESEARCH_RISK_TYPE, 0);
	END
END
GO

-----------------------------
-- ET-649 Agendar pesquisa de Risco ao criar EC
-----------------------------

IF OBJECT_ID('SP_REG_COMMERCIAL_ESTAB') IS NOT NULL DROP PROCEDURE [SP_REG_COMMERCIAL_ESTAB];
GO

CREATE PROCEDURE [dbo].[SP_REG_COMMERCIAL_ESTAB]                                                
/*----------------------------------------------------------------------------------------                                                
Procedure Name: [SP_REG_COMMERCIAL_ESTAB]                                                
Project.......: TKPP                                                
------------------------------------------------------------------------------------------                                                
Author					VERSION        Date         Description                                                
------------------------------------------------------------------------------------------                                                
Kennedy Alef            V1          27/07/2018      Creation                                                
Elir Ribeiro            V2          13/09/2018      Changed                                            
Elir Ribeiro            V3          17/09/2018      Changed                                        
Fernando Henrique       V5          05/1/2018       Changed                                      
Elir Ribeiro            v6          09/11/2018      Changed                                  
Luiz Aquino				v7			13/12/2018      ADD HAS_SPOT and SPOT_TAX                      
Lucas Aguiar			v8			14/12/2018      ADD TRANSACTION_DIGITED                      
Lucas Aguiar			v9			2019-04-18      ADD ROTINA DE SPLIT                  
Elir Ribeiro			v10			2019-08-01      ADD SITUATION ANALYSE RISK              
Elir Ribeiro			v11			2019-10-01      ADD @TRANS_LIMIT_MONTHLY                
Lucas Aguiar			v12			2019-10-28      Conta Cess�o          
Marcus Gall				v13			2019-11-06      ADD FK BRANCH_BUSINESS      
Marcus Gall				v14			2019-12-06      When enabling online transaction, create credentials and flag true in field HAS_CREDENTIALS      
Elir Ribeiro			v15			2020-01-08      add type Consumer
Marcus Gall				v16			2020-03-12		Scheduling risk research in table RESEARCH_RISK
------------------------------------------------------------------------------------------*/                                                
(                                                
 @CODE VARCHAR(100),                                                
 @NAME VARCHAR(200),                                   
 @TRADING_NAME VARCHAR(100),                                                
 @CPF_CNPJ VARCHAR(100),                                                
 @DOCUMENT VARCHAR(100),                                                
 @DOCUMENT_TYPE VARCHAR(100),                                                
 @EMAIL VARCHAR(100),                                                
 @STATE_REG VARCHAR(100),                                                
 @MUN_REG VARCHAR(100),                                                
 @CODSEG INT,          
 @TRANS_LIMIT DECIMAL(22,6),                                                
 @TRANS_LIMIT_DIALY DECIMAL(22,6),             
 @TRANS_LIMIT_MONTHLY DECIMAL(22,6) = NULL,             
 @BIRTHDATE  DATE,                                                
 @TYPE_EC INT,                                                
 @CODUSER INT,                                                
 @COMPANY INT,                                                
 @AGENCY VARCHAR(100),                                                
 @DIGIT VARCHAR(100),                                                
 @ACCOUNT VARCHAR(100),                                                
 @DIGIT_ACCOUNT VARCHAR(100) = null,                                                
 @BANK INT,                                                
 @ACCOUNT_TYPE INT,                                                
 @SEC_FACT_AUTH INT,                                                
 @ADDRESS VARCHAR(300),              
 @NUMBER VARCHAR(100),                                                
 @COMPLEMENT VARCHAR(200),                                                
 @REFPOINT VARCHAR(100),                                                
 @CEP VARCHAR(12),                                   
 @COD_NEIGH INT,                                                
 @CODSEX INT,                                                
 @CODREP INT,                                                
 @COD_OPER VARCHAR(50) = NULL,                                                
 @COD_REQ INT = NULL,                             
 @COD_SIT INT = NULL,                                                
 @COD_RECEIPT INT = NULL,                                                
 @COD_AFFILIATOR INT = NULL,                                             
 @TRANSACTION_ONLINE INT   = NULL,                                      
 @REGISTERNEWTICKET INT = NULL,                                  
 @REQUESTCARD INT = NULL,                                  
 @COD_CARD_PRD INT = NULL,                              
 @DEFAULT_EC INT = NULL,                      
 @HAS_SPOT INT = 0,                      
 @SPOT_TAX DECIMAL(6,2) = 0,                  
 @HAS_SPLIT INT = 0,          
 @IS_ASSIGNMENT INT = 0,          
 @ASSIGNMENT_NAME VARCHAR(255) = NULL,          
 @ASSIGNMENT_IDENTIFICATION VARCHAR(14) = NULL,        
 @CODBRANCHBUSINESS INT = NULL,    
 @TypeClient TP_MEET_COSTUMER READONLY     
)                                               
AS                  
          
DECLARE @TYPEBR VARCHAR(100);
DECLARE @IDEC INT;
DECLARE @IDDEPART INT;
DECLARE @IDBR INT;
DECLARE @SEQ INT;
DECLARE @CONT INT;
DECLARE @USER_ONLINE VARCHAR(100) = NULL;
DECLARE @PWD_ONLINE uniqueidentifier;
DECLARE @TRANSACTION_LIMIT DECIMAL(22,6);
DECLARE @TRANSACTION_DAILY DECIMAL(22,6);
DECLARE @COD_RISK INT = NULL;
DECLARE @COD_OPT_SERV INT;
DECLARE @HAS_CREDENTIALS BIT = 0;
      
                  
BEGIN

SET @TYPEBR = 'PRINCIPAL'

SELECT
	@CONT = COUNT(*)
FROM COMMERCIAL_ESTABLISHMENT
WHERE COD_COMP = @COMPANY
AND CPF_CNPJ = @CPF_CNPJ
AND (COD_AFFILIATOR = @COD_AFFILIATOR
OR @COD_AFFILIATOR IS NULL);

IF @CONT > 0
THROW 61002, 'COMMERCIAL ESTABLISHMENT ALREADY REGISTERED', 1;

DECLARE @CodSpotService INT
DECLARE @COD_SPLIT_SERVICE INT;

SELECT
	@CodSpotService = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE CODE = '1';

SELECT
	@COD_SPLIT_SERVICE = COD_ITEM_SERVICE
FROM ITEMS_SERVICES_AVAILABLE
WHERE [NAME] = 'SPLIT';

IF (@HAS_SPOT = 1
	AND @COD_AFFILIATOR IS NOT NULL
	AND (SELECT
			COUNT(*)
		FROM SERVICES_AVAILABLE
		WHERE COD_ITEM_SERVICE = @CodSpotService
		AND COD_AFFILIATOR = @COD_AFFILIATOR
		AND COD_EC IS NULL
		AND ACTIVE = 1)
	= 0)
THROW 61039, 'Affiliated is not allowed to give advance (SPOT)', 1;

SELECT
	@SEQ = NEXT VALUE FOR [SEQ_ECCODE];

IF (@TRANSACTION_ONLINE = 1)
BEGIN
SET @USER_ONLINE = NEXT VALUE FOR [SEQ_TR_ON_EC]
SET @PWD_ONLINE = CONVERT(VARCHAR(255), NEWID())
SET @HAS_CREDENTIALS = 1
      
END

SELECT
	@TRANSACTION_LIMIT = TRANSACTION_LIMIT
   ,@TRANSACTION_DAILY = LIMIT_TRANSACTION_DIALY
   ,@TRANS_LIMIT_MONTHLY = (SELECT
			LIMIT_TRANSACTION_MONTHLY
		FROM SEGMENTS
		WHERE COD_SEG = @CODSEG)
FROM TRANSACTION_LIMIT
WHERE ACTIVE = 1
AND COD_TYPE_ESTAB = @TYPE_EC
AND COD_COMP = @COMPANY;

INSERT INTO COMMERCIAL_ESTABLISHMENT (CODE,
NAME,
TRADING_NAME,
CPF_CNPJ,
DOCUMENT,
DOCUMENT_TYPE,
EMAIL,
STATE_REGISTRATION,
MUNICIPAL_REGISTRATION,
COD_SEG,
COD_BRANCH_BUSINESS,
TRANSACTION_LIMIT,
LIMIT_TRANSACTION_DIALY,
LIMIT_TRANSACTION_MONTHLY,
BIRTHDATE,
COD_COMP,
COD_TYPE_ESTAB,
COD_USER,
SEC_FACTOR_AUTH_ACTIVE,
COD_SEX,
COD_SALES_REP,
COD_REQ,
COD_SIT_REQ,
COD_AFFILIATOR,
TRANSACTION_ONLINE,
USER_ONLINE,
PWD_ONLINE,
DEFAULT_EC,
--HAS_SPOT,                      
SPOT_TAX,
COD_SITUATION,
COD_RISK_SITUATION,
HAS_CREDENTIALS)
	VALUES (@SEQ, @NAME, @TRADING_NAME, @CPF_CNPJ, @DOCUMENT, @DOCUMENT_TYPE, @EMAIL, @STATE_REG, @MUN_REG, @CODSEG, @CODBRANCHBUSINESS, @TRANSACTION_LIMIT, @TRANSACTION_DAILY, @TRANS_LIMIT_MONTHLY, @BIRTHDATE, @COMPANY, @TYPE_EC, @CODUSER, @SEC_FACT_AUTH, @CODSEX, @CODREP, @COD_REQ, ISNULL(@COD_SIT, 1), @COD_AFFILIATOR, ISNULL(@TRANSACTION_ONLINE, 0), @USER_ONLINE, @PWD_ONLINE, @DEFAULT_EC,
	--@HAS_SPOT,                      
	@SPOT_TAX, (SELECT COD_SITUATION FROM SITUATION WHERE [NAME] = 'RELEASED'), 1, @HAS_CREDENTIALS);

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER COMMERCIAL_ESTABLISHMENT', 1;

SET @IDEC = SCOPE_IDENTITY();
      
                    
IF(@COD_AFFILIATOR IS NOT NULL AND @HAS_SPOT = 1)                 
 BEGIN
INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)
	VALUES (current_timestamp, @CODUSER, @CodSpotService, NULL, @COD_AFFILIATOR, @IDEC, 1, NULL)
END
ELSE
BEGIN
INSERT INTO SERVICES_AVAILABLE (CREATED_AT, COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, MODIFY_DATE)
	VALUES (current_timestamp, @CODUSER, @CodSpotService, NULL, @COD_AFFILIATOR, @IDEC, 0, NULL)
END

IF (@HAS_SPLIT = 1)
BEGIN
SELECT
	@COD_OPT_SERV = COD_OPT_SERV
FROM OPTIONS_SERVICES
WHERE [DESCRIPTION] = 'ALGUNS';

INSERT INTO SERVICES_AVAILABLE (COD_USER, COD_ITEM_SERVICE, COD_COMP, COD_AFFILIATOR, COD_EC, ACTIVE, COD_OPT_SERV, MODIFY_DATE)
	VALUES (@CODUSER, @COD_SPLIT_SERVICE, @COMPANY, @COD_AFFILIATOR, @IDEC, 1, @COD_OPT_SERV, current_timestamp);
END;

SELECT
	@SEQ = NEXT VALUE FOR [SEQ_BRANCHCODE];

INSERT INTO [BRANCH_EC] (CODE,
NAME,
TRADING_NAME,
CPF_CNPJ,
DOCUMENT,
DOCUMENT_TYPE,
EMAIL,
STATE_REGISTRATION,
MUNICIPAL_REGISTRATION,
TRANSACTION_LIMIT,
LIMIT_TRANSACTION_DIALY,
BIRTHDATE,
COD_EC,
TYPE_BRANCH,
COD_USER,
COD_SEX,
COD_SALES_REP,
COD_TYPE_ESTAB,
COD_REQ,
COD_SITUATION,
COD_TYPE_REC)
	VALUES (@SEQ, @NAME, @TRADING_NAME, @CPF_CNPJ, @DOCUMENT, @DOCUMENT_TYPE, @EMAIL, @STATE_REG, @MUN_REG, @TRANSACTION_LIMIT, @TRANSACTION_DAILY, @BIRTHDATE, @IDEC, @TYPEBR, @CODUSER, @CODSEX, @CODREP, @TYPE_EC, @COD_REQ, @COD_SIT, @COD_RECEIPT)

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER BRANCH_EC', 1;

SELECT
	@IDBR = @@identity;

-- TODO: Defina valores de par?metros aqui.                                                

IF @COD_RECEIPT = 2
BEGIN
IF @@rowcount < 1
THROW 60000, 'COULD NOT CARD REQUEST', 1
END;

IF @COD_RECEIPT = 1
	OR @COD_RECEIPT IS NULL
BEGIN
INSERT INTO BANK_DETAILS_EC (AGENCY, DIGIT_AGENCY, COD_TYPE_ACCOUNT, COD_EC, COD_BANK, ACCOUNT, DIGIT_ACCOUNT, COD_USER, COD_OPER_BANK, COD_BRANCH
, IS_ASSIGNMENT, ASSIGNMENT_NAME, ASSIGNMENT_IDENTIFICATION)
	VALUES (@AGENCY, ISNULL(REPLACE(@DIGIT, '-', ''), ''), @ACCOUNT_TYPE, @IDEC, @BANK, @ACCOUNT, @DIGIT_ACCOUNT, @CODUSER, @COD_OPER, @IDBR, @IS_ASSIGNMENT, @ASSIGNMENT_NAME, @ASSIGNMENT_IDENTIFICATION)

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER BANK_DETAILS_EC', 1;
END;

UPDATE ADDRESS_BRANCH
SET ACTIVE = 0
   ,MODIFY_DATE = GETDATE()
WHERE ACTIVE = 1
AND COD_BRANCH = @IDBR

INSERT INTO ADDRESS_BRANCH (ADDRESS, NUMBER, COMPLEMENT, CEP, COD_NEIGH, REFERENCE_POINT, COD_BRANCH)
	VALUES (@ADDRESS, @NUMBER, @COMPLEMENT, @CEP, @COD_NEIGH, @REFPOINT, @IDBR)

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER ADDRESS_BRANCH ', 1;

INSERT INTO DEPARTMENTS_BRANCH (COD_BRANCH, COD_DEPARTS, COD_USER)
	VALUES (@IDBR, 1, @CODUSER)

IF @@rowcount < 1
THROW 60000, 'COULD NOT REGISTER DEPARTMENTS_BRANCH', 1;

SELECT
	@IDDEPART = @@identity;

EXEC SP_REG_EXTERNAL_DATA_EC_ACQ @IDEC
								,@CODUSER

SET @COD_RISK = (SELECT
		COD_RISK_PERSON
	FROM RISK_PERSON
	WHERE CPF_CNPJ = @CPF_CNPJ);
      
        
          
                  
                
IF ISNULL(@REGISTERNEWTICKET,0) = 1
EXEC SP_REG_SUPPORT_TICKET 1
						  ,@NAME
						  ,'AGUARDANDO ANALISE DE RISCO'
						  ,@COD_RISK
						  ,1
						  ,1
						  ,63
IF @REQUESTCARD = 1
EXEC SP_REG_FFILIATOR_CARD_PROVIDER @COD_CARD_PRD
								   ,@CODUSER
								   ,@COD_AFFILIATOR
ELSE
IF @REQUESTCARD = 0
BEGIN
INSERT INTO CARDSTOBRANCH_REQUESTS (COD_BRANCH,
COD_SIT_REQ,
COD_USER_CAD,
COD_PRD)
	VALUES (@IDBR, 1, @CODUSER, @COD_CARD_PRD)

EXEC SP_REG_FFILIATOR_CARD_PROVIDER @COD_CARD_PRD
								   ,@CODUSER
								   ,@COD_AFFILIATOR;
END

SELECT
	@IDEC AS COD_EC
   ,@IDBR AS COD_BR
   ,@IDDEPART AS COD_DEPART

-- conhe�a seu cliente    

IF (SELECT
			COUNT(*)
		FROM @TypeClient)
	> 0
BEGIN

	INSERT INTO MEET_COSTUMER (COD_EC,
	QTY_EMPLOYEES,
	AVERAGE_BILLING,
	URL_SITE,
	INSTAGRAM,
	FACEBOOK,
	COD_NEIGH,
	STREET,
	NUMBER,
	COMPLEMENT,
	ANOTHER_INFO,
	CNPJ,
	NEIGHBORHOOD,
	CITY,
	STATES,
	REFERENCEPOINT,
	ZIPCODE)
		SELECT
			@IDEC
		   ,QTY_EMPLOYEES
		   ,AVERAGE_BILLING
		   ,URL_SITE
		   ,INSTAGRAM
		   ,FACEBOOK
		   ,COD_NEIGH
		   ,STREET
		   ,NUMBER
		   ,COMPLEMENT
		   ,ANOTHER_INFO
		   ,CNPJ
		   ,NEIGHBORHOOD
		   ,CITY
		   ,STATES
		   ,REFERENCEPOINT
		   ,ZIPCODE
		FROM @TypeClient


		IF @@rowcount < (SELECT
					COUNT(*)
				FROM @TypeClient)
		THROW 70020, 'COULD NOT REGISTER [MEET_COSTUMER]. Parameter name: 70020', 1;
	END

	-- BEGIN > Scheduling risk research 
	DECLARE @COD_RESEARCH_RISK_TYPE INT;
	SET @COD_RESEARCH_RISK_TYPE = (SELECT TOP 1 RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE FROM RESEARCH_RISK_TYPE WHERE RESEARCH_RISK_TYPE.CODE = 'INITIAL' AND RESEARCH_RISK_TYPE.DOCUMENT_TYPE = @DOCUMENT_TYPE AND RESEARCH_RISK_TYPE.ACTIVE = 1);

	INSERT INTO RESEARCH_RISK (COD_EC, COD_USER, COD_RESEARCH_RISK_TYPE, COD_STATUS) VALUES (@IDEC, @CODUSER, @COD_RESEARCH_RISK_TYPE, 0);
	-- BEGIN > Scheduling risk research 

	-- FIM --    
END;
GO

-----------------------------
-- ET-650 Relatório de Pesquisa de Risco
-----------------------------

IF OBJECT_ID('SP_REPORT_RESEARCH_RISK') IS NOT NULL DROP PROCEDURE [SP_REPORT_RESEARCH_RISK];
GO

CREATE PROCEDURE [dbo].[SP_REPORT_RESEARCH_RISK]                                    
/*----------------------------------------------------------------------------------------                                                                      
Procedure Name: [SP_REPORT_RESEARCH_RISK]                                                                      
Project.......: TKPP                                                                      
------------------------------------------------------------------------------------------                                                                      
Author                          VERSION         Date                        Description                                                                      
------------------------------------------------------------------------------------------                                                                      
Caike Uchôa                       v1          2020-03-23                      CREATION                
------------------------------------------------------------------------------------------*/                                                                                    
(                      
@COD_EC INT = NULL,  
@TYPE_RESEARCH VARCHAR(20) = NULL,  
@DATE_RESEARCH DATETIME = NULL,
@LAST_LINE_RESEARCH INT = NULL
)                      
AS          
  
DECLARE @QUERY NVARCHAR(MAX);  
  
BEGIN    
  
SET @QUERY = CONCAT(@QUERY, 'SELECT 
COMMERCIAL_ESTABLISHMENT.TRADING_NAME,  
COMMERCIAL_ESTABLISHMENT.[NAME],  
COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,  
COMMERCIAL_ESTABLISHMENT.BIRTHDATE,  
SEX_TYPE.[NAME] AS [SEXO],  
RESEARCH_RISK_RESPONSE.STATE_REGISTRATION,  
RESEARCH_RISK_RESPONSE.CNAE,  
RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK,  
RESEARCH_RISK_RESPONSE.BID_ID,  
RESEARCH_RISK_TYPE.CODE_POLICY,   
CASE
WHEN RESEARCH_RISK_TYPE.CODE = ''INITIAL'' THEN ''Inicial''
WHEN RESEARCH_RISK_TYPE.CODE = ''MONTHLY'' THEN ''Mensal''
WHEN RESEARCH_RISK_TYPE.CODE = ''YEARLY'' THEN ''Anual''
END
AS [TYPE_POLICY],  
RESEARCH_RISK_RESPONSE.SITUATION_RISK,  
RESEARCH_RISK_RESPONSE.MESSAGE_SITUATION,  
CASE
WHEN TRIM(RESEARCH_RISK_RESPONSE_DETAILS.CODE) LIKE ''receita%'' THEN ''Receita Federal''
ELSE RESEARCH_RISK_RESPONSE_DETAILS.CODE
END AS [CODE],
CASE   
WHEN RESEARCH_RISK_RESPONSE_DETAILS.SITUATION_DESCRIPTION = ''Não Consultado'' THEN ''Erro''
WHEN RESEARCH_RISK_RESPONSE_DETAILS.COD_SITUATION = ''1'' THEN ''Negado''  
WHEN RESEARCH_RISK_RESPONSE_DETAILS.COD_SITUATION = ''0'' THEN ''Aprovado''
END AS [SITUATION_DESCRIPTION],
RESEARCH_RISK_RESPONSE_DETAILS.COD_SITUATION,
RESEARCH_RISK_RESPONSE_DETAILS.SITUATION_DESCRIPTION AS SITUATION_DESCRIPTION_DETAILS,
RESEARCH_RISK_RESPONSE_DETAILS.CPF_PARTNER_EC,  
RESEARCH_RISK_RESPONSE.CREATED_AT, 
RESEARCH_RISK.SEND_AT,
RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE,
TYPE_PARTNER.NAME AS PARTNER_TYPE, 
ADITIONAL_DATA_TYPE_EC.PERCENTEGE_QUOTAS AS PERCENTAGE_QUOTAS,
ADITIONAL_DATA_TYPE_EC.NAME AS PARTNER_NAME 
FROM RESEARCH_RISK_RESPONSE_DETAILS ');

IF @LAST_LINE_RESEARCH IS NOT NULL   
	BEGIN   
	  SET @QUERY = CONCAT(@QUERY, ' 
		JOIN (
			SELECT MAX(TOP_RRR.COD_RESEARCH_RISK_RESPONSE) AS COD_RESEARCH_RISK_RESPONSE, TOP_RR.COD_EC FROM RESEARCH_RISK_RESPONSE AS TOP_RRR
			JOIN RESEARCH_RISK AS TOP_RR ON TOP_RRR.COD_RESEARCH_RISK = TOP_RR.COD_RESEARCH_RISK
			GROUP BY TOP_RR.COD_EC
		) AS MOST_RECENT_RESEARCH_RISK_RESPONSE ON MOST_RECENT_RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE = RESEARCH_RISK_RESPONSE_DETAILS.COD_RESEARCH_RISK_RESPONSE 
		INNER JOIN RESEARCH_RISK_RESPONSE ON RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE = MOST_RECENT_RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE ');
	END
ELSE
	BEGIN   
	  SET @QUERY = CONCAT(@QUERY, ' INNER JOIN RESEARCH_RISK_RESPONSE ON RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE = RESEARCH_RISK_RESPONSE_DETAILS.COD_RESEARCH_RISK_RESPONSE ');
	END

SET @QUERY = CONCAT(@QUERY, ' 
INNER JOIN RESEARCH_RISK ON RESEARCH_RISK.COD_RESEARCH_RISK = RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK  
INNER JOIN RESEARCH_RISK_TYPE ON RESEARCH_RISK_TYPE.COD_RESEARCH_RISK_TYPE = RESEARCH_RISK.COD_RESEARCH_RISK_TYPE  
INNER JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = RESEARCH_RISK.COD_EC  
INNER JOIN SEX_TYPE ON SEX_TYPE.COD_SEX = COMMERCIAL_ESTABLISHMENT.COD_SEX  
LEFT JOIN ADITIONAL_DATA_TYPE_EC ON ADITIONAL_DATA_TYPE_EC.COD_ADT_DATA = RESEARCH_RISK_RESPONSE_DETAILS.COD_PARTNER_EC
LEFT JOIN TYPE_PARTNER ON TYPE_PARTNER.COD_TYPE_PARTNER = ADITIONAL_DATA_TYPE_EC.COD_TYPE_PARTNER
WHERE RESEARCH_RISK_RESPONSE.ACTIVE = 1');   
  
IF @COD_EC IS NOT NULL   
BEGIN   
  SET @QUERY = CONCAT(@QUERY, ' AND RESEARCH_RISK.COD_EC = @COD_EC');  
END  
  
IF @TYPE_RESEARCH IS NOT NULL   
BEGIN   
  SET @QUERY = CONCAT(@QUERY, ' AND RESEARCH_RISK_TYPE.CODE = @TYPE_RESEARCH');  
END  
  
IF @DATE_RESEARCH IS NOT NULL   
BEGIN   
  SET @QUERY = CONCAT(@QUERY, ' AND CAST(RESEARCH_RISK_RESPONSE.CREATED_AT AS DATE) = CAST(@DATE_RESEARCH AS DATE)');  
END  
  
SET @QUERY = CONCAT(@QUERY, ' 
GROUP BY   
COMMERCIAL_ESTABLISHMENT.TRADING_NAME,  
COMMERCIAL_ESTABLISHMENT.[NAME],  
COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,  
COMMERCIAL_ESTABLISHMENT.BIRTHDATE,  
SEX_TYPE.[NAME],
RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK_RESPONSE,
RESEARCH_RISK_RESPONSE.STATE_REGISTRATION,  
RESEARCH_RISK_RESPONSE.CNAE,  
RESEARCH_RISK_RESPONSE.COD_RESEARCH_RISK,  
RESEARCH_RISK_RESPONSE.BID_ID,  
RESEARCH_RISK_TYPE.CODE_POLICY,  
RESEARCH_RISK_TYPE.CODE,  
RESEARCH_RISK_RESPONSE.SITUATION_RISK,  
RESEARCH_RISK_RESPONSE.MESSAGE_SITUATION,  
RESEARCH_RISK_RESPONSE_DETAILS.CODE,  
RESEARCH_RISK_RESPONSE_DETAILS.COD_SITUATION,
RESEARCH_RISK_RESPONSE_DETAILS.SITUATION_DESCRIPTION,
RESEARCH_RISK_RESPONSE_DETAILS.CPF_PARTNER_EC,  
RESEARCH_RISK_RESPONSE.CREATED_AT,
RESEARCH_RISK.SEND_AT,
TYPE_PARTNER.NAME, 
ADITIONAL_DATA_TYPE_EC.PERCENTEGE_QUOTAS,
ADITIONAL_DATA_TYPE_EC.NAME');
  
EXEC sp_executesql @QUERY,  
N' @COD_EC INT,  
@TYPE_RESEARCH VARCHAR(20),  
@DATE_RESEARCH DATETIME,
@LAST_LINE_RESEARCH INT
', 
@COD_EC = @COD_EC,  
@TYPE_RESEARCH = @TYPE_RESEARCH,  
@DATE_RESEARCH = @DATE_RESEARCH,
@LAST_LINE_RESEARCH = @LAST_LINE_RESEARCH
;  
  
END 
GO 

-----------------------------
-- ET-829 Ajuste de Gestão de Risco em Documentos
-----------------------------

IF (OBJECT_ID('[SP_REG_DOC_EC]') IS NOT NULL) DROP PROCEDURE [SP_REG_DOC_EC]
GO

CREATE PROCEDURE [dbo].[SP_REG_DOC_EC]                
/*----------------------------------------------------------------------------------------                                                                      
Project.......: TKPP								Procedure Name: [SP_REG_DOC_EC]                                                                      
------------------------------------------------------------------------------------------                                                                      
Author                 VERSION      Date            Description                                                                      
------------------------------------------------------------------------------------------                                                                      
Desconhecido			v1          00-00-0000      CREATION                
Marcus Gall				v2			05-05-2020		Alterar a situação de Risco ou ModifyDate alterar um documento.
------------------------------------------------------------------------------------------*/    
(                
@DOC VARCHAR(300) ,                 
@TYPE_INSIDECODE INT,                
@COD_BRANCH INT,                
@COD_USER INT                
)                
AS                
                
DECLARE @COD_STATUS_EC INT;                
DECLARE @NAME VARCHAR;                
DECLARE @COD_RISK INT;                
DECLARE @TICKET INT;                
DECLARE @COD_DOC INT;                
DECLARE @COD_EC INT;   
DECLARE @RISK INT;  
DECLARE @DETAIL_DESCRIPTION VARCHAR(255);
DECLARE @COD_EC_RISK INT;
                
BEGIN                
                
	UPDATE DOCS_BRANCH SET ACTIVE = 0 WHERE COD_BRANCH = @COD_BRANCH AND COD_DOC_TYPE = @TYPE_INSIDECODE AND ACTIVE =1;

	SELECT @COD_EC_RISK = COMMERCIAL_ESTABLISHMENT.COD_EC FROM COMMERCIAL_ESTABLISHMENT 
	INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC 
	WHERE BRANCH_EC.COD_BRANCH = @COD_BRANCH;

	IF ((SELECT COUNT(COD_EC) FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC_RISK AND COD_RISK_SITUATION = (SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE [NAME] = 'Released by Risk')) = 1) 
	BEGIN
		INSERT INTO COMMERCIAL_ESTABLISHMENT_LOG (CODE, NAME, TRADING_NAME, CPF_CNPJ, DOCUMENT_TYPE, EMAIL, STATE_REGISTRATION, MUNICIPAL_REGISTRATION, COD_SEG, TRANSACTION_LIMIT, LIMIT_TRANSACTION_DIALY, BIRTHDATE, COD_USER, COD_COMP, MODIFY_DATE, COD_USER_MODIFY, SEC_FACTOR_AUTH_ACTIVE, COD_TYPE_ESTAB, COD_SEX, DOCUMENT, COD_SALES_REP, COD_EC, NOTE, COD_SIT_REQ, COD_SITUATION, COD_REQ, COD_AFFILIATOR, TRANSACTION_ONLINE, USER_ONLINE, PWD_ONLINE, DEFAULT_EC, NOTE_FINANCE_SCHEDULE, COD_RISK_SITUATION, RISK_REASON)
		SELECT CODE, NAME, TRADING_NAME, CPF_CNPJ, DOCUMENT_TYPE, EMAIL, STATE_REGISTRATION, MUNICIPAL_REGISTRATION, COD_SEG, TRANSACTION_LIMIT, LIMIT_TRANSACTION_DIALY, BIRTHDATE, COD_USER, COD_COMP, MODIFY_DATE, COD_USER_MODIFY, SEC_FACTOR_AUTH_ACTIVE, COD_TYPE_ESTAB, COD_SEX, DOCUMENT, COD_SALES_REP, COD_EC,NOTE, COD_SIT_REQ, COD_SITUATION, COD_REQ,  COD_AFFILIATOR, TRANSACTION_ONLINE, USER_ONLINE, PWD_ONLINE, DEFAULT_EC, NOTE_FINANCE_SCHEDULE, COD_RISK_SITUATION, RISK_REASON FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC;
		UPDATE COMMERCIAL_ESTABLISHMENT SET COD_RISK_SITUATION = (SELECT COD_RISK_SITUATION FROM RISK_SITUATION WHERE [NAME] = 'In Analysis'), RISK_REASON = 'Pendencia de análise em novo documento enviado', MODIFY_DATE = GETDATE() WHERE COD_EC = @COD_EC_RISK;
	END
	ELSE
	BEGIN
		INSERT INTO COMMERCIAL_ESTABLISHMENT_LOG (CODE, NAME, TRADING_NAME, CPF_CNPJ, DOCUMENT_TYPE, EMAIL, STATE_REGISTRATION, MUNICIPAL_REGISTRATION, COD_SEG, TRANSACTION_LIMIT, LIMIT_TRANSACTION_DIALY, BIRTHDATE, COD_USER, COD_COMP, MODIFY_DATE, COD_USER_MODIFY, SEC_FACTOR_AUTH_ACTIVE, COD_TYPE_ESTAB, COD_SEX, DOCUMENT, COD_SALES_REP, COD_EC, NOTE, COD_SIT_REQ, COD_SITUATION, COD_REQ, COD_AFFILIATOR, TRANSACTION_ONLINE, USER_ONLINE, PWD_ONLINE, DEFAULT_EC, NOTE_FINANCE_SCHEDULE, COD_RISK_SITUATION, RISK_REASON)
		SELECT CODE, NAME, TRADING_NAME, CPF_CNPJ, DOCUMENT_TYPE, EMAIL, STATE_REGISTRATION, MUNICIPAL_REGISTRATION, COD_SEG, TRANSACTION_LIMIT, LIMIT_TRANSACTION_DIALY, BIRTHDATE, COD_USER, COD_COMP, MODIFY_DATE, COD_USER_MODIFY, SEC_FACTOR_AUTH_ACTIVE, COD_TYPE_ESTAB, COD_SEX, DOCUMENT, COD_SALES_REP, COD_EC,NOTE, COD_SIT_REQ, COD_SITUATION, COD_REQ,  COD_AFFILIATOR, TRANSACTION_ONLINE, USER_ONLINE, PWD_ONLINE, DEFAULT_EC, NOTE_FINANCE_SCHEDULE, COD_RISK_SITUATION, RISK_REASON FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC;
		UPDATE COMMERCIAL_ESTABLISHMENT SET MODIFY_DATE = GETDATE() WHERE COD_EC = @COD_EC_RISK;
	END
      
	SELECT @COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC, @COD_STATUS_EC = COMMERCIAL_ESTABLISHMENT.COD_SIT_REQ, @COD_RISK = RISK_PERSON.COD_RISK_PERSON                
	FROM COMMERCIAL_ESTABLISHMENT 
	INNER JOIN BRANCH_EC ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC                
	INNER JOIN RISK_PERSON ON RISK_PERSON.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC                
	WHERE BRANCH_EC.COD_BRANCH = @COD_BRANCH AND BRANCH_EC.TYPE_BRANCH = 'PRINCIPAL' AND BRANCH_EC.ACTIVE = 1 AND RISK_PERSON.ACTIVE = 1;          
    
	SET @TICKET = (SELECT TOP 1 ST.COD_SUP_TIC FROM SUPPORT_TICKET ST 
		INNER JOIN RISK_PERSON RP ON ST.COD_RISK_PERSON = RP.COD_RISK_PERSON                
		INNER JOIN  COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC                
		INNER JOIN BRANCH_EC BEC ON CE.COD_EC  = BEC.COD_EC                
		WHERE BEC.COD_BRANCH = @COD_BRANCH AND BEC.TYPE_BRANCH = 'PRINCIPAL' AND CE.ACTIVE = 1                 
		--AND ST.COD_SUP_TIC_STA = 1                
		--OR  ST.COD_SUP_TIC_STA = 4                
		--ORDER BY 1 DESC
		);      
      
	IF (@DOC = '') SET @DOC = NULL;          
      
	INSERT INTO DOCS_BRANCH(COD_USER, COD_BRANCH, COD_SIT_REQ, COD_DOC_TYPE, PATH_DOC, COD_SUP_TIC, MODIFY_DATE) 
	VALUES (@COD_USER, @COD_BRANCH, 16, @TYPE_INSIDECODE, @DOC, @TICKET, dbo.FN_FUS_UTF(GETDATE()));        
      
	IF @@rowcount < 1 
		THROW 60000, 'COULD NOT REGISTER DOCS_BRANCH' , 1;            

	SET @COD_DOC = @@identity;          
   
	IF (@COD_STATUS_EC = 5)      
	BEGIN      
		--SET @TICKET =       
		--(                
		-- SELECT TOP       
		--  1 ST.COD_SUP_TIC                 
		-- FROM                 
		-- SUPPORT_TICKET ST                
		-- INNER JOIN RISK_PERSON RP ON ST.COD_RISK_PERSON = RP.COD_RISK_PERSON                
		-- INNER JOIN  COMMERCIAL_ESTABLISHMENT CE ON RP.COD_EC = CE.COD_EC                
		-- INNER JOIN BRANCH_EC BEC ON CE.COD_EC  = BEC.COD_EC                
		-- WHERE BEC.COD_BRANCH = @COD_BRANCH                 
		-- AND BEC.TYPE_BRANCH = 'PRINCIPAL'                 
		-- AND CE.ACTIVE = 1                 
		----AND ST.COD_SUP_TIC_STA = 1                
		----OR  ST.COD_SUP_TIC_STA = 4               
		--  --ORDER BY 1 DESC                
		--);       
        
		UPDATE DOCS_BRANCH SET COD_SUP_TIC = @TICKET WHERE DOCS_BRANCH.COD_DOC_BR = @COD_DOC;   
        
		IF @@ROWCOUNT < 1                            
			THROW 60000,'COULD NOT UPDATE DOCUMENT TICKET',1;        
  
		IF (SELECT COUNT(COD_DOC_BR) FROM VW_DOCS_BRANCH_BY_EC WHERE COD_EC = @COD_EC AND PATH_DOC IS NULL) = 0  
		BEGIN  
     
			--INSERT INTO COMMERCIAL_ESTABLISHMENT_LOG     
			--SELECT         
			-- CREATED_AT,         
			-- CODE,         
			-- NAME,         
			-- TRADING_NAME,         
			-- CPF_CNPJ,         
			-- DOCUMENT_TYPE,         
			-- EMAIL,         
			-- STATE_REGISTRATION,         
			-- MUNICIPAL_REGISTRATION,         
			-- COD_SEG,        
			-- TRANSACTION_LIMIT,         
			-- LIMIT_TRANSACTION_DIALY,         
			-- BIRTHDATE,         
			-- COD_USER,         
			-- COD_COMP,         
			-- ACTIVE,         
			-- MODIFY_DATE,         
			-- COD_USER_MODIFY,         
			-- SEC_FACTOR_AUTH_ACTIVE,         
			-- COD_TYPE_ESTAB,         
			-- COD_SEX,         
			-- DOCUMENT,         
			-- COD_SALES_REP,         
			-- COD_EC, NOTE,         
			-- COD_SIT_REQ        
			--FROM COMMERCIAL_ESTABLISHMENT WHERE COD_EC = @COD_EC;        
       
			UPDATE COMMERCIAL_ESTABLISHMENT        
			SET COD_SIT_REQ = 9        
			WHERE COD_EC = @COD_EC;    
  
			SELECT @RISK = COD_RISK_PERSON FROM RISK_PERSON WHERE COD_EC = @COD_EC;   
       
			SELECT TOP(1) @DETAIL_DESCRIPTION=CONCAT('REPROVADO; ',SOURCES_CONSULT_RISK.NAME_SOURCES,'.')  FROM DETAIL_RISK     
			INNER JOIN SOURCES_CONSULT_RISK ON (SOURCES_CONSULT_RISK.COD_CONSULT_RISK = DETAIL_RISK.COD_CONSULT_RISK)  
			WHERE DETAIL_RISK.SUCCESS <> 'A' AND DETAIL_RISK.COD_RISK_PERSON = @RISK   
			ORDER BY COD_DETAIL_RISK DESC  
  
			EXEC [SP_UP_SUPPORT_TICKET]  
				@COD_SUP_TIC = @TICKET,  
				@COD_SUP_TIC_STA = 1,  
				@COD_SUP_TIC_QUE = 9,  
				@DESCRIPTION= @DETAIL_DESCRIPTION,  
				@COMMENT= NULL,  
				@COD_USER = 63;  
		END;    
	END;
END;
GO
IF OBJECT_ID('SP_LOGIN_USER') IS NOT NULL DROP PROCEDURE SP_LOGIN_USER;
GO
CREATE PROCEDURE [dbo].[SP_LOGIN_USER]                  
/*----------------------------------------------------------------------------------------                  
    Procedure Name: SP_LOGIN_USER                  
    Project.......: TKPP            
      
    ------------------------------------------------------------------------------------------                  
    Author                          VERSION        Date                            Description                  
    ------------------
------------------------------------------------------------------------                  
    Kennedy Alef     V1      31/07/2018        Creation                  
    Gian Luca Dalle Cort   V2      31/07/2018        Changed                  
    Lucas A
guiar   v3  26/11/2018  changed          
       
*/
          
(                 
@ACESSKEY VARCHAR(300),                  
@USER VARCHAR(100) ,                 
@COD_AFFILIATOR INT                   
)                  
AS                  
DECLARE @LOCK DATETIME;
                  
DECLARE @ACTIVE_USER INT;
                  
DECLARE @CODUSER INT;
                  
DECLARE @ACTIVE_EC INT;
                  
DECLARE @DATEPASS DATETIME
                  
DECLARE @LOGGED INT;
                  
DECLARE @PASS_TMP VARCHAR(MAX);
                  
DECLARE @RETURN VARCHAR(200);
                  
DECLARE @ACTIVE_AFL INT;
                  
DECLARE @COD_AFF INT;
                   
DECLARE @COD_MODULE_ INT;
               
DECLARE @COD_SALES_REP INT;
          
BEGIN


SELECT
	@LOCK = LOCKED_UP
   ,@ACTIVE_USER = USERS.ACTIVE
   ,@CODUSER = USERS.COD_USER
   ,@ACTIVE_EC = COMMERCIAL_ESTABLISHMENT.ACTIVE
   ,@DATEPASS = PASS_HISTORY.CREATED_AT
   ,@LOGGED = USERS.LOGGED
   ,@PASS_TMP = PASS_HISTORY.PASS
   ,@ACTIVE_AFL = AFFILIATOR.ACTIVE
   ,@COD_AFF = AFFILIATOR.COD_AFFILIATOR
   ,@COD_SALES_REP = SALES_REPRESENTATIVE.COD_SALES_REP
FROM USERS
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = USERS.COD_COMP
INNER JOIN PROFILE_ACCESS
	ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE

INNER JOIN PASS_HISTORY
	ON PASS_HISTORY.COD_USER = USERS.COD_USER
LEFT JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = USERS.COD_EC
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR =
		USERS.COD_AFFILIATOR --BUSCA SE USU�RIO POSSUI C�DIGO DE AFILIADOR                  
LEFT JOIN SALES_REPRESENTATIVE
	ON SALES_REPRESENTATIVE.COD_USER = USERS.COD_USER
WHERE COD_ACCESS = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY

AND PASS_HISTORY.ACTUAL = 1
OR USERS.EMAIL = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1

IF @CODUSER IS NULL
	OR @CODUSER = 0
BEGIN

SET @RETURN = CONCAT('USER NOT FOUND', ';') + ISNULL(@PASS_TMP, 0);
                  
THROW 61006,@RETURN,1;
                  
END
                  
                
IF ISNULL(@COD_AFF,0) <> ISNULL(@COD_AFFILIATOR,0)              
BEGIN

SET @RETURN = CONCAT('USER NOT FOUND r', ';') + ISNULL(@PASS_TMP, 0);
                  
THROW 61006,@RETURN,1;
                  
END
                 
                
   
               
IF DATEDIFF(MINUTE,@LOCK,GETDATE()) < 30                  
BEGIN

SET @RETURN = CONCAT(CONCAT('USER BLOCKED', ';'), @PASS_TMP);
                  
THROW 61008,@RETURN,1;
                  
END
               
   
                  
IF @ACTIVE_USER = 0                  
BEGIN
SET @RETURN = CONCAT(CONCAT('USER INACTIVE', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('USER INACTIVE',CONCAT('-',@PASS_TMP))                  
THROW 61007,@RETURN,1;
                  
END
                  
                  
IF @ACTIVE_EC = 0                  
BEGIN
SET @RETURN = CONCAT(CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE',CONCAT('-',@PASS_TMP))                  
THROW 61009,@RETURN,1;
                  
END
                  
                  
IF @ACTIVE_AFL = 0                  
BEGIN
SET @RETURN = CONCAT(CONCAT('AFFILIATOR INACTIVE', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('COMMERCIAL ESTABLISHMENT INACTIVE',CONCAT('-',@PASS_TMP))                  
THROW 61009,@RETURN,1;
                  
END
                  
                  
IF DATEDIFF(DAY,@DATEPASS
,GETDATE()) >= 30                  
BEGIN
SET @RETURN = CONCAT(CONCAT('PASSWORD EXPIRED', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('PASSWORD EXPIRED',CONCAT('-',@PASS_TMP))                  
THROW 61010,@RETURN,1;
                
  
END
                  
IF @LOGGED = 1                  
BEGIN
UPDATE USERS
SET LOGGED = 0
WHERE USERS.COD_USER = @CODUSER;
DELETE FROM TEMP_TOKEN
WHERE TEMP_TOKEN.COD_USER = @CODUSER;
SET @RETURN =
CONCAT(CONCAT('USER ALREADY LOGGED', ';'), @PASS_TMP);
                  
--SET @RETURN = CONCAT('USER ALREADY LOGGED',CONCAT('-',@PASS_TMP))                  
THROW 61011,@RETURN,1;
                  
END
                  
IF @PASS_TMP IS NULL               
  
THROW 61029,'TEMPORARY ACCESS',1;



SELECT
	USERS.COD_ACCESS AS USERNAME
   ,USERS.COD_USER
   ,USERS.IDENTIFICATION
   ,PASS_HISTORY.PASS
   ,USERS.CPF_CNPJ AS CPF_CNPJ_USER
   ,USERS.EMAIL
   ,COMPANY.COD_COMP AS COD_COMP
   ,AFFILIATOR.COD_AFFILIATOR AS INSIDECODE_AFL
   ,PROFILE_ACCESS.CODE AS COD_PROFILE
   ,COMMERCIAL_ESTABLISHMENT.COD_EC
   ,MODULES.CODE AS MODULE
   ,MODULES.COD_MODULE AS COD_MODULE
   ,@COD_AFFILIATOR AS PAR_AFFILIATOR
   ,@COD_AFF AS AFF_RET
   ,CASE COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE
		WHEN 1 THEN AUTHENTICATION_FACTOR.NAME
		WHEN 0 THEN NULL
		ELSE AUTHENTICATION_FACTOR.NAME

	END
	AS AUTHENTICATION_FACTOR
   ,CASE
		WHEN FIRST_LOGIN_DATE IS NULL THEN 1
		ELSE 0
	END
	AS FIRST_ACCESS
   ,AUTHENTICATION_FACTOR.COD_FACT
   ,(-1 * (DATEDIFF(DAY, ((DATEADD(DAY, 30, GETDATE()) + GETDATE()) - GETDATE()), @DATEPASS))) AS DAYSTO_EXPIRE
   ,THEMES.COD_THEMES AS 'ThemeCode'
   ,THEMES.CREATED_AT AS 'CreatedDate'
   ,THEMES.LOGO_AFFILIATE AS 'PathLogo'
   ,THEMES.LOGO_HEADER_AFFILIATE AS 'PathLogoHeader'
   ,THEMES.COD_AFFILIATOR AS 'AffiliatorCode'
   ,THEMES.MODIFY_DATE AS 'ModifyDate'
   ,THEMES.COLOR_HEADER AS 'ColorHeader'
   ,THEMES.Active AS 'Active'
   ,AFFILIATOR.SubDomain AS 'SubDomain'
   ,AFFILIATOR.Guid AS 'Guid'
   ,THEMES.BACKGROUND_IMAGE AS 'BackgroundImage'
   ,THEMES.SECONDARY_COLOR AS 'SecondaryColor'
   ,[POS_AVAILABLE].[AVAILABLE] AS 'AvailablePOS'
   ,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC AS 'DefaultEc'
   ,SALES_REPRESENTATIVE.COD_SALES_REP
   ,USERS.LAST_LOGIN
FROM USERS
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = USERS.COD_COMP
INNER JOIN PROFILE_ACCESS
	ON PROFILE_ACCESS.COD_PROFILE = USERS.COD_PROFILE

LEFT JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = USERS.COD_EC
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = USERS.COD_AFFILIATOR
INNER JOIN PASS_HISTORY
	ON PASS_HISTORY.COD_USER = USERS.COD_USER

INNER JOIN MODULES
	ON MODULES.COD_MODULE = USERS.COD_MODULE
LEFT JOIN ASS_FACTOR_AUTH_COMPANY
	ON ASS_FACTOR_AUTH_COMPANY.COD_COMP = COMPANY.COD_COMP
LEFT JOIN AUTHENTICATION_FACTOR
	ON AUTHENTICATION_FACTOR.COD_FACT = ASS_FACTOR_AUTH_COMPANY.COD_FACT
LEFT JOIN THEMES
	ON THEMES.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
LEFT JOIN POS_AVAILABLE
	ON POS_AVAILABLE.COD_AFFILIATOR = AFFILIATOR.COD_AFFILIATOR
LEFT JOIN SALES_REPRESENTATIVE
	ON SALES_REPRESENTATIVE.COD_USER = USERS.COD_USER
WHERE COD_ACCESS = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1
AND (THEMES.Active = 1
OR THEMES.Active IS NULL)
OR USERS.EMAIL = @USER
AND COMPANY.ACCESS_KEY = @ACESSKEY
AND PASS_HISTORY.ACTUAL = 1
AND (THEMES.Active = 1
OR THEMES.Active IS NULL)

END;
GO
IF OBJECT_ID('ORDER_STEPS') IS NOT NULL DROP TABLE ORDER_STEPS
GO
IF OBJECT_ID('DELIVERY_ADDRESS') IS NOT NULL DROP TABLE DELIVERY_ADDRESS;
GO
IF OBJECT_ID('SELL_ORDER') IS NOT NULL DROP TABLE SELL_ORDER;
GO
IF OBJECT_ID('PRODUCTS_COMPANY') IS NOT NULL DROP TABLE PRODUCTS_COMPANY;
GO
IF OBJECT_ID('ORDER_STEPS') IS NOT NULL DROP TABLE ORDER_STEPS;
GO
IF OBJECT_ID('ORDER_STEPS') IS NOT NULL DROP TABLE ORDER_STEPS;
GO
IF OBJECT_ID('TRANSIRE_PRODUCT') IS NOT NULL DROP TABLE TRANSIRE_PRODUCT;
GO
IF OBJECT_ID('ORDER_ITEM') IS NOT NULL DROP TABLE ORDER_ITEM;
GO
IF OBJECT_ID('[PRODUCTS]') IS NOT NULL DROP TABLE [PRODUCTS];
GO
IF OBJECT_ID('PRODUCTS') IS NULL
CREATE TABLE [dbo].[PRODUCTS](
	[COD_PRODUCT] [int] IDENTITY(1,1) NOT NULL,
	[CREATED_AT] [datetime] NULL,
	[PRODUCT_NAME] [varchar](200) NULL,
	[NICKNAME] [varchar](200) NULL,
	[DESCRIPTION] [nvarchar](max) NULL,
	[SKU] [varchar](255) NULL,
	[PRICE] [decimal](22, 8) NULL,
	[ACTIVE] [int] NULL,
	[COD_AFFILIATOR] [int] NULL,
	[COD_MODEL] [int] NULL,
	[COD_USER] [int] NULL,
	[ALTER_DATE] [datetime] NULL,
	[COD_USER_ALTER] [int] NULL,
	[COD_SITUATION] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_PRODUCT] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[PRODUCTS] ADD  DEFAULT (getdate()) FOR [CREATED_AT]
GO

ALTER TABLE [dbo].[PRODUCTS] ADD  CONSTRAINT [DF_CONSTRAINT_PROD_ACTIVE]  DEFAULT ((1)) FOR [ACTIVE]
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_AFFILIATOR])
REFERENCES [dbo].[AFFILIATOR] ([COD_AFFILIATOR])
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_MODEL])
REFERENCES [dbo].[EQUIPMENT_MODEL] ([COD_MODEL])
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD  CONSTRAINT [FK__PRODUCTS__COD_SI__08D61451] FOREIGN KEY([COD_SITUATION])
REFERENCES [dbo].[SITUATION] ([COD_SITUATION])
GO

ALTER TABLE [dbo].[PRODUCTS] CHECK CONSTRAINT [FK__PRODUCTS__COD_SI__08D61451]
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_USER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

ALTER TABLE [dbo].[PRODUCTS]  WITH CHECK ADD FOREIGN KEY([COD_USER_ALTER])
REFERENCES [dbo].[USERS] ([COD_USER])
GO

GO

/****** Object:  Table [dbo].[ORDER_ITEM]    Script Date: 27/04/2020 09:30:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TRANSIRE_PRODUCT](
	[COD_TRANSIRE_PRD] [int] IDENTITY(1,1) NOT NULL,
	[SKU] [varchar](255) NULL,
	[AMOUNT] [decimal](22, 6) NULL,
	[ACTIVE] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[COD_TRANSIRE_PRD] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TRANSIRE_PRODUCT] ADD  DEFAULT ((1)) FOR [ACTIVE]
GO
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('238472398', 900.000000, 1);
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('23423423', 900.000000, 1);
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('6077324STELO', 900.000000, 1);
INSERT INTO TRANSIRE_PRODUCT (SKU, AMOUNT, ACTIVE)
	VALUES ('6068334STELO', 900.000000, 1);

IF OBJECT_ID('ORDER_ITEM') IS NULL
CREATE TABLE [dbo].[ORDER_ITEM](
	[COD_ODR_ITEM] [int] IDENTITY(1,1) NOT NULL,
	[PRICE] [decimal](22, 6) NOT NULL,
	[QUANTITY] [int] NOT NULL,
	[COD_ODR] [int] NOT NULL,
	[CHIP] [varchar](256) NOT NULL,
	[COD_PRODUCT] [int] NULL,
	[COD_OPERATOR] [int] NULL,
	[COD_TRANSIRE_PRD] [int] NULL,
 CONSTRAINT [PK_ORDER_ITEM] PRIMARY KEY NONCLUSTERED 
(
	[COD_ODR_ITEM] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ORDER_ITEM]  WITH CHECK ADD FOREIGN KEY([COD_OPERATOR])
REFERENCES [dbo].[CELL_OPERATOR] ([COD_OPER])
GO

ALTER TABLE [dbo].[ORDER_ITEM]  WITH CHECK ADD FOREIGN KEY([COD_PRODUCT])
REFERENCES [dbo].[PRODUCTS] ([COD_PRODUCT])
GO

ALTER TABLE [dbo].[ORDER_ITEM]  WITH CHECK ADD FOREIGN KEY([COD_TRANSIRE_PRD])
REFERENCES [dbo].[TRANSIRE_PRODUCT] ([COD_TRANSIRE_PRD])
GO
/****** Object:  Table [dbo].[TRANSIRE_PRODUCT]    Script Date: 27/04/2020 09:39:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  UserDefinedTableType [dbo].[TP_ORDER_ITEM]    Script Date: 27/04/2020 10:25:31 ******/
CREATE TYPE [dbo].[TP_ORDER_ITEM] AS TABLE(
	[COD_PR_AFF] [int] NOT NULL,
	[PRICE] [decimal](22, 6) NOT NULL,
	[QUANTITY] [int] NOT NULL,
	[CHIP] [varchar](256) NOT NULL,
	[CELL_OPERATOR] [varchar](40) NULL
)
GO



IF OBJECT_ID('[SP_REG_ORDER]') IS NOT NULL
    DROP PROCEDURE [SP_REG_ORDER];
GO

CREATE PROCEDURE [DBO].[SP_REG_ORDER]                        
            
/***************************************************************************************************************************
----------------------------------------------------------------------------------------                       
    Procedure Name: [SP_UP_BANK_DETAILS_EC]                       
    Project.......: TKPP                       
    ------------------------------------------------------------------------------------------                       
    Author                          VERSION        Date                            Description                              
    ------------------------------------------------------------------------------------------                       
    Lucas Aguiar     V1      2019-10-28         Creation                             
    ------------------------------------------------------------------------------------------        
***************************************************************************************************************************/        
                       
(
	@CPF_EC           VARCHAR(50), 
	@CPF_AFF          VARCHAR(50), 
	@ACCESS_USER      VARCHAR(50), 
	@ADDRESS_ORDER    VARCHAR(300), 
	@NUMBER_ORDER     VARCHAR(100), 
	@COMPLEMENT_ORDER VARCHAR(200)    = NULL, 
	@REFPOINT_ORDER   VARCHAR(100)    = NULL, 
	@CEP_ORDER        VARCHAR(12), 
	@COD_NEIGH_ORDER  INT, 
	@AMOUNT           DECIMAL(22, 6), 
	@CODE             VARCHAR(128)    = NULL, 
	@TP_ORDER_ITEM    [TP_ORDER_ITEM] READONLY)
AS
BEGIN

    DECLARE @COD_EC INT;

    DECLARE @COD_AFF INT;

    DECLARE @COD_USER INT;

    DECLARE @COD_ORDER INT;



    SELECT @COD_AFF = [COD_AFFILIATOR]
    FROM [AFFILIATOR]
    WHERE [CPF_CNPJ] = @CPF_AFF AND [ACTIVE] = 1;

    IF @COD_AFF IS NULL
	   THROW 66600, 'AFFILIATOR NOT FOUND', 0;

    SELECT @COD_EC = [COD_EC]
    FROM [COMMERCIAL_ESTABLISHMENT]
    WHERE [CPF_CNPJ] = @CPF_EC AND [COD_AFFILIATOR] = @COD_AFF AND [ACTIVE] = 1;

    IF @COD_EC IS NULL
	   THROW 66601, 'EC NOT FOUND', 0;

    SELECT [ORDER].[COD_ODR], 
		 [ORDER].[CREATED_AT], 
		 [ORDER].[AMOUNT], 
		 [ORDER].[CODE], 
		 [ORDER].[COD_EC] AS [EC], 
		 [ORDER].[COD_USER], 
		 [ORDER].[COD_SITUATION], 
		 [ORDER].[COD_TRAN], 
		 [ORDER_ADDRESS].[COD_ODR_ADDR], 
		 [ORDER].[COD_ORDER_SIT], 
		 [ORDER_SITUATION].[CODE] AS [ORDER_SIT], 
		 [ORDER_ADDRESS].[CEP], 
		 [ORDER_ADDRESS].[ADDRESS], 
		 [ORDER_ADDRESS].[NUMBER], 
		 [NEIGHBORHOOD].[NAME] AS [NEIGH], 
		 [CITY].[NAME] AS [CITY], 
		 STATE.[UF], 
		 [COUNTRY].[INITIALS], 
		 [ORDER_ADDRESS].[COMPLEMENT], 
		 [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL], 
		 [EQUIPMENT].[SERIAL] AS 'SITE',  
		 --,[ORDER].[AMOUNT]   
		 [GENERIC_EC].[COD_EC], 
		 [GENERIC_EC].[USER_ONLINE] AS [USER_ONLINE], 
		 [GENERIC_EC].[PWD_ONLINE]
    INTO [#PENDENT_ORDER]
    FROM [ORDER]
	    INNER JOIN [ORDER_SITUATION] ON [ORDER].[COD_ORDER_SIT] = [ORDER].[COD_ORDER_SIT]
	    INNER JOIN [COMMERCIAL_ESTABLISHMENT] ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [ORDER].[COD_EC]
	    INNER JOIN [ORDER_ADDRESS] ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR] AND [ORDER_ADDRESS].[ACTIVE] = 1
	    INNER JOIN [NEIGHBORHOOD] ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
	    INNER JOIN [CITY] ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
	    INNER JOIN STATE ON STATE.[COD_STATE] = [CITY].[COD_STATE]
	    INNER JOIN [COUNTRY] ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
	    INNER JOIN [COMMERCIAL_ESTABLISHMENT] AS [GENERIC_EC] ON [GENERIC_EC].[COD_AFFILIATOR] = @COD_AFF AND [GENERIC_EC].[GENERIC_EC] = 1
	    INNER JOIN [BRANCH_EC] ON [BRANCH_EC].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
	    INNER JOIN [DEPARTMENTS_BRANCH] ON [DEPARTMENTS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
	    INNER JOIN [ASS_DEPTO_EQUIP] ON [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH] = [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] AND [ASS_DEPTO_EQUIP].[ACTIVE] = 1
	    INNER JOIN [EQUIPMENT] ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP] AND [EQUIPMENT].[ACTIVE] = 1
    WHERE [AMOUNT] = 250 AND [ORDER_SITUATION].[CODE] = 'PAGAMENTO PENDENTE' AND [COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ] = @CPF_EC AND [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR] = @COD_AFF AND DATEDIFF(HOUR, [ORDER].[CREATED_AT], current_timestamp) < 24;

    IF(@@ROWCOUNT > 0)
    BEGIN

	   SELECT *
	   FROM [#PENDENT_ORDER];

    END;
	   ELSE
    BEGIN

	   SELECT @COD_NEIGH_ORDER = [COD_NEIGH]
	   FROM [NEIGHBORHOOD]
	   WHERE [COD_NEIGH] = @COD_NEIGH_ORDER;

	   IF @COD_NEIGH_ORDER IS NULL
		  THROW 66602, 'NEIGHBORHOOD NOT FOUND', 0;

	   SELECT @COD_USER = [COD_USER]
	   FROM [USERS]
	   WHERE [COD_ACCESS] = @ACCESS_USER AND [ACTIVE] = 1 AND [COD_EC] = @COD_EC;

	   IF @COD_USER IS NULL
		  THROW 66603, 'USER NOT FOUND', 0;

	   INSERT INTO [ORDER]
	   ([CREATED_AT], 
	    [AMOUNT], 
	    [COD_EC], 
	    [COD_USER], 
	    [COD_SITUATION], 
	    [COD_ORDER_SIT], 
	    [COMMENT], 
	    [CODE]
	   )
	   VALUES ( 
		   current_timestamp, @AMOUNT, @COD_EC, @COD_USER, 1, 1, NULL, NEXT VALUE FOR [SEQ_ORDERCODE] );

	   IF @@ROWCOUNT < 1
		  THROW 66604, 'INSERT ORDER ERROR', 0;

	   SET @COD_ORDER = SCOPE_IDENTITY();

	   INSERT INTO [ORDER_ADDRESS]
	   ([ADDRESS], 
	    [NUMBER], 
	    [COMPLEMENT], 
	    [CEP], 
	    [COD_NEIGH], 
	    [COD_EC], 
	    [ACTIVE], 
	    [COD_ODR]
	   )
	   VALUES ( 
		   @ADDRESS_ORDER, @NUMBER_ORDER, @COMPLEMENT_ORDER, @CEP_ORDER, @COD_NEIGH_ORDER, @COD_EC, 1, @COD_ORDER );

	   IF @@ROWCOUNT < 1
		  THROW 66605, 'INSERT ORDER ADDRESS ERROR', 0;

	   INSERT INTO [ORDER_ITEM]
	   ([PRICE], 
	    [QUANTITY], 
	    [COD_ODR], 
	    [CHIP], 
	    [COD_PRODUCT], 
	    [COD_OPERATOR], 
	    [COD_TRANSIRE_PRD]
	   )
	   SELECT [TP].[PRICE], 
			[TP].[QUANTITY], 
			@COD_ORDER, 
			[TP].[CHIP], 
			[TP].[COD_PR_AFF], 
			[CELL_OPERATOR].[COD_OPER], 
			[TRANSIRE_PRODUCT].[COD_TRANSIRE_PRD]
	   FROM @TP_ORDER_ITEM AS [TP]
		   JOIN [CELL_OPERATOR] ON [CELL_OPERATOR].[CODE] = [TP].[CELL_OPERATOR]
		   JOIN [PRODUCTS] ON [PRODUCTS].[COD_PRODUCT] = [TP].[COD_PR_AFF]
		   JOIN [TRANSIRE_PRODUCT] ON [TRANSIRE_PRODUCT].[SKU] = [PRODUCTS].[SKU] AND [TRANSIRE_PRODUCT].[ACTIVE] = 1;


	   IF @@ROWCOUNT <
	   (SELECT COUNT(*)
	    FROM @TP_ORDER_ITEM)
		  THROW 66606, 'INSERT ORDER ITEMS ERROR', 0;



	   SELECT [ORDER].[COD_ODR], 
			[ORDER].[CREATED_AT], 
			[ORDER].[AMOUNT], 
			[ORDER].[CODE], 
			[ORDER].[COD_EC] AS [EC], 
			[ORDER].[COD_USER], 
			[ORDER].[COD_SITUATION], 
			[ORDER].[COD_TRAN], 
			[ORDER_ADDRESS].[COD_ODR_ADDR], 
			[ORDER].[COD_ORDER_SIT], 
			[ORDER_SITUATION].[CODE] AS [ORDER_SIT], 
			[ORDER_ADDRESS].[CEP], 
			[ORDER_ADDRESS].[ADDRESS], 
			[ORDER_ADDRESS].[NUMBER], 
			[NEIGHBORHOOD].[NAME] AS [NEIGH], 
			[CITY].[NAME] AS [CITY], 
			STATE.[UF], 
			[COUNTRY].[INITIALS], 
			[ORDER_ADDRESS].[COMPLEMENT], 
			[ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL], 
			[EQUIPMENT].[SERIAL] AS 'SITE', 
			[GENERIC_EC].[COD_EC], 
			[GENERIC_EC].[USER_ONLINE] AS [USER_ONLINE], 
			[GENERIC_EC].[PWD_ONLINE]
	   FROM [ORDER]
		   INNER JOIN [ORDER_ADDRESS] ON [ORDER_ADDRESS].[COD_ODR] = [ORDER].[COD_ODR] AND [ORDER_ADDRESS].[ACTIVE] = 1
		   INNER JOIN [NEIGHBORHOOD] ON [NEIGHBORHOOD].[COD_NEIGH] = [ORDER_ADDRESS].[COD_NEIGH]
		   INNER JOIN [CITY] ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
		   INNER JOIN STATE ON STATE.[COD_STATE] = [CITY].[COD_STATE]
		   INNER JOIN [COUNTRY] ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
		   INNER JOIN [ORDER_SITUATION] ON [ORDER].[COD_ORDER_SIT] = [ORDER_SITUATION].[COD_ORDER_SIT]
		   INNER JOIN [COMMERCIAL_ESTABLISHMENT] AS [GENERIC_EC] ON [GENERIC_EC].[COD_AFFILIATOR] = @COD_AFF AND [GENERIC_EC].[GENERIC_EC] = 1
		   INNER JOIN [BRANCH_EC] ON [BRANCH_EC].[COD_EC] = [GENERIC_EC].[COD_EC]
		   INNER JOIN [DEPARTMENTS_BRANCH] ON [DEPARTMENTS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
		   INNER JOIN [ASS_DEPTO_EQUIP] ON [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH] = [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] AND [ASS_DEPTO_EQUIP].[ACTIVE] = 1
		   INNER JOIN [EQUIPMENT] ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP] AND [EQUIPMENT].[ACTIVE] = 1
	   WHERE [ORDER].[COD_ODR] = @COD_ORDER;
    END;
END;

GO


IF OBJECT_ID('[SP_LS_PENDING_ORDER]') IS NOT NULL
    DROP PROCEDURE [SP_LS_PENDING_ORDER];
GO

CREATE PROCEDURE [DBO].[SP_LS_PENDING_ORDER]                          
              
/*****************************************************************************************************************************
----------------------------------------------------------------------------------------                         
    Procedure Name: [SP_LS_PENDING_ORDER]                         
    Project.......: TKPP                         
    ------------------------------------------------------------------------------------------                         
    Author                          VERSION        Date                            Description                                
    ------------------------------------------------------------------------------------------                         
    Lucas Aguiar     V1    2020-02-03       Creation                               
    ------------------------------------------------------------------------------------------          
*****************************************************************************************************************************/          
                         
AS
BEGIN


    SELECT [CE].[NAME] AS [EC_NAME], 
		 [CE].[EMAIL], 
		 [CE].[CPF_CNPJ], 
		 [SEX_TYPE].[CODE] AS [SEX], 
		 [TE].[CODE] AS [TYPE_EC], 
		 [CE].[MUNICIPAL_REGISTRATION], 
		 [CE].[STATE_REGISTRATION], 
		 [CONTACT_BRANCH].[DDI], 
		 [CONTACT_BRANCH].[DDD], 
		 [CONTACT_BRANCH].[NUMBER], 
		 [ODR].[CODE] AS [ORDER_NUMBER], 
		 [ODR].[CREATED_AT] AS [ORDER_DATE], 
		 [ODR_ADD].[CEP], 
		 [ODR_ADD].[COMPLEMENT], 
		 [ODR_ADD].[ADDRESS], 
		 [ODR_ADD].[NUMBER] AS [ADDR_NUMBER], 
		 [NEIGHBORHOOD].[NAME] AS [NEIGHBORHOOD], 
		 STATE.[UF] AS [UF], 
		 [CITY].[NAME] AS [CITY], 
		 [COUNTRY].[INITIALS], 
		 [ORDER_ITEM].[PRICE], 
		 [ORDER_ITEM].[QUANTITY], 
		 [PRODUCTS].[SKU], 
		 [CELL_OPERATOR].[CODE] AS [OPERATOR], 
		 SUBSTRING([COMPANY].[NAME], 0, 6) AS [COMPANY], 
		 [TRANSACTION].[PLOTS] AS [PLOTS], 
		 IIF([EQUIPMENT_MODEL].[COD_MODEL_GROUP] = 1, 1, 0) AS [HAS_CHIP], 
		 [TRANSACTION].[BRAND], 
		 [TRANSIRE_PRODUCT].[AMOUNT] AS [TRANSIRE_AMOUNT], 
		 [TRANSACTION].[CODE] AS [NSU]
    FROM [COMMERCIAL_ESTABLISHMENT] AS [CE]
	    JOIN [TYPE_ESTAB] AS [TE] ON [TE].[COD_TYPE_ESTAB] = [CE].[COD_TYPE_ESTAB]
	    JOIN [BRANCH_EC] ON [BRANCH_EC].[COD_EC] = [CE].[COD_EC] AND [BRANCH_EC].[ACTIVE] = 1
	    JOIN [CONTACT_BRANCH] ON [CONTACT_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH] AND [CONTACT_BRANCH].[ACTIVE] = 1 AND [CONTACT_BRANCH].[COD_CONT] =
    (SELECT TOP 1 [COD_CONT]
	FROM [CONTACT_BRANCH]
	WHERE [CONTACT_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH] AND [CONTACT_BRANCH].[ACTIVE] = 1
	ORDER BY 1 DESC)
	    JOIN [ORDER] AS [ODR] ON [ODR].[COD_EC] = [CE].[COD_EC] AND [ODR].[COD_ORDER_SIT] = 2 AND [ODR].[COD_TRAN] IS NOT NULL
	    JOIN [ORDER_ADDRESS] AS [ODR_ADD] ON [ODR_ADD].[COD_ODR] = [ODR].[COD_ODR] AND [ODR_ADD].[ACTIVE] = 1
	    JOIN [NEIGHBORHOOD] ON [NEIGHBORHOOD].[COD_NEIGH] = [ODR_ADD].[COD_NEIGH]
	    JOIN [CITY] ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
	    JOIN STATE ON STATE.[COD_STATE] = [CITY].[COD_STATE]
	    JOIN [COUNTRY] ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
	    JOIN [ORDER_ITEM] ON [ORDER_ITEM].[COD_ODR] = [ODR].[COD_ODR]
	    JOIN [PRODUCTS] ON [PRODUCTS].[COD_PRODUCT] = [ORDER_ITEM].[COD_PRODUCT]
	    JOIN [CELL_OPERATOR] ON [CELL_OPERATOR].[COD_OPER] = [ORDER_ITEM].[COD_OPERATOR]
	    JOIN [SEX_TYPE] ON [SEX_TYPE].[COD_SEX] = [CE].[COD_SEX]
	    JOIN [COMPANY] ON [COMPANY].[COD_COMP] = [CE].[COD_COMP]
	    JOIN [TRANSACTION] WITH(NOLOCK) ON [TRANSACTION].[COD_TRAN] = [ODR].[COD_TRAN]
	    JOIN [EQUIPMENT_MODEL] ON [EQUIPMENT_MODEL].[COD_MODEL] = [PRODUCTS].[COD_MODEL]
	    JOIN [TRANSIRE_PRODUCT] ON [TRANSIRE_PRODUCT].[COD_TRANSIRE_PRD] = [ORDER_ITEM].[COD_TRANSIRE_PRD] AND [TRANSIRE_PRODUCT].[ACTIVE] = 1
    GROUP BY [CE].[NAME], 
		   [CE].[EMAIL], 
		   [CE].[CPF_CNPJ], 
		   [SEX_TYPE].[CODE], 
		   [TE].[CODE], 
		   [CE].[MUNICIPAL_REGISTRATION], 
		   [CE].[STATE_REGISTRATION], 
		   [CONTACT_BRANCH].[DDI], 
		   [CONTACT_BRANCH].[DDD], 
		   [CONTACT_BRANCH].[NUMBER], 
		   [ODR].[CODE], 
		   [ODR].[CREATED_AT], 
		   [ODR_ADD].[CEP], 
		   [ODR_ADD].[COMPLEMENT], 
		   [ODR_ADD].[ADDRESS], 
		   [ODR_ADD].[NUMBER], 
		   [NEIGHBORHOOD].[NAME], 
		   STATE.[UF], 
		   [CITY].[NAME], 
		   [COUNTRY].[INITIALS], 
		   [ORDER_ITEM].[PRICE], 
		   [ORDER_ITEM].[QUANTITY], 
		   [PRODUCTS].[SKU], 
		   [CELL_OPERATOR].[CODE], 
		   [COMPANY].[NAME], 
		   [TRANSACTION].[PLOTS], 
		   IIF([EQUIPMENT_MODEL].[COD_MODEL_GROUP] = 1, 1, 0), 
		   [TRANSACTION].[BRAND], 
		   [TRANSIRE_PRODUCT].[AMOUNT], 
		   [TRANSACTION].[CODE]
    ORDER BY [ODR].[CREATED_AT] ASC;


END;

GO



IF TYPE_ID('[TP_SKU]') IS NOT NULL
    DROP TYPE [TP_SKU];
GO

CREATE TYPE [TP_SKU] AS TABLE(
	[SKU] VARCHAR(255));

GO


IF OBJECT_ID('[SP_VERIFY_SKU]') IS NOT NULL
    DROP PROCEDURE [SP_VERIFY_SKU];
GO

CREATE PROCEDURE [SP_VERIFY_SKU](
	@CODE [TP_SKU] READONLY)
AS
BEGIN

    SELECT [CODE].[SKU]
    FROM @CODE AS [CODE]
	    LEFT JOIN [TRANSIRE_PRODUCT] ON [CODE].[SKU] = [TRANSIRE_PRODUCT].[SKU] and [TRANSIRE_PRODUCT].ACTIVE = 1
    WHERE [TRANSIRE_PRODUCT].[COD_TRANSIRE_PRD] IS NULL;

END;

go


IF OBJECT_ID('[SP_FD_INFO_TO_REVERSE_LOGISTIC]') IS NOT NULL
    DROP PROCEDURE [SP_FD_INFO_TO_REVERSE_LOGISTIC];
GO

CREATE PROCEDURE [SP_FD_INFO_TO_REVERSE_LOGISTIC]  
--'celer_20232'  
(
	@ORDER_NUMBER VARCHAR(255))
AS
BEGIN
    SELECT '(' + [CONTACT_BRANCH].[DDI] + ') ' + [CONTACT_BRANCH].[DDD] + ' ' + [CONTACT_BRANCH].[NUMBER] AS 'PHONE_NUMBER', 
		 [COMMERCIAL_ESTABLISHMENT].[STATE_REGISTRATION], 
		 [COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ], 
		 [COMMERCIAL_ESTABLISHMENT].[EMAIL], 
		 [COMMERCIAL_ESTABLISHMENT].[TRADING_NAME], 
		 [COMMERCIAL_ESTABLISHMENT].[NAME] AS 'EC_NAME', 
		 [TYPE_ESTAB].[CODE] AS 'TYPE_EC', 
		 [SEX_TYPE].[CODE] AS 'SEX_EC', 
		 [ADDRESS_BRANCH].[ADDRESS], 
		 [NEIGHBORHOOD].[NAME], 
		 [ADDRESS_BRANCH].[CEP], 
		 [COMPLEMENT], 
		 STATE.[UF], 
		 [ADDRESS_BRANCH].[ADDRESS], 
		 [CITY].[NAME] AS [CITY], 
		 [ADDRESS_BRANCH].[NUMBER], 
		 [COUNTRY].[INITIALS], 
		 [ORDER].[AMOUNT], 
		 [TRANSACTION].[CODE] AS [NSU]
    FROM [COMMERCIAL_ESTABLISHMENT]
	    INNER JOIN [ORDER] ON [ORDER].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
	    INNER JOIN [BRANCH_EC] ON [BRANCH_EC].[COD_EC] = [COMMERCIAL_ESTABLISHMENT].[COD_EC]
	    INNER JOIN [CONTACT_BRANCH] ON [CONTACT_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH] AND [CONTACT_BRANCH].[ACTIVE] = 1
	    INNER JOIN [TYPE_CONTACT] ON [TYPE_CONTACT].[COD_TP_CONT] = [CONTACT_BRANCH].[COD_TP_CONT]
	    INNER JOIN [ADDRESS_BRANCH] ON [ADDRESS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH] AND [ADDRESS_BRANCH].[ACTIVE] = 1
	    INNER JOIN [SEX_TYPE] ON [SEX_TYPE].[COD_SEX] = [COMMERCIAL_ESTABLISHMENT].[COD_SEX]
	    INNER JOIN [TYPE_ESTAB] ON [TYPE_ESTAB].[COD_TYPE_ESTAB] = [COMMERCIAL_ESTABLISHMENT].[COD_TYPE_ESTAB]
	    INNER JOIN [NEIGHBORHOOD] ON [NEIGHBORHOOD].[COD_NEIGH] = [ADDRESS_BRANCH].[COD_NEIGH]
	    INNER JOIN [CITY] ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
	    INNER JOIN [STATE] ON STATE.[COD_STATE] = [CITY].[COD_STATE]
	    INNER JOIN [COUNTRY] ON [COUNTRY].[COD_COUNTRY] = STATE.[COD_COUNTRY]
	    JOIN [TRANSACTION] WITH(NOLOCK) ON [TRANSACTION].[COD_TRAN] = [ORDER].[COD_TRAN]
    WHERE [ORDER].[PICKING_ORDER] = @ORDER_NUMBER AND [TYPE_CONTACT].[NAME] = 'CELULAR';  
    --SELECT * FROM TYPE_CONTACT
END;
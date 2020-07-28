/****** Object:  UserDefinedTableType [dbo].[TP_THEMES_IMG]    Script Date: 27/04/2020 11:19:14 ******/
CREATE TYPE [dbo].[TP_THEMES_IMG] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[COD_WL_CONT_TYPE] [int] NULL,
	[PATH_CONTENT] [varchar](400) NULL,
	[COD_MODEL] [int] NULL
)
GO

/****** Object:  UserDefinedTableType [dbo].[WL_PRODUCTS]    Script Date: 27/04/2020 11:19:31 ******/
CREATE TYPE [dbo].[WL_PRODUCTS] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_AFF] [int] NULL,
	[PRODUCT_NAME] [varchar](255) NULL,
	[SKU] [varchar](255) NULL,
	[PRICE] [decimal](22, 8) NULL,
	[COD_MODEL] [int] NULL
)
GO

/****** Object:  UserDefinedTableType [dbo].[TP_REG_EQUIP_PICKING]    Script Date: 27/04/2020 11:20:15 ******/
CREATE TYPE [dbo].[TP_REG_EQUIP_PICKING] AS TABLE(
	[COD_USER] [int] NULL,
	[COD_DEPTO] [int] NULL,
	[COD_COMP] [int] NULL,
	[SERIAL] [varchar](100) NULL,
	[CHIP] [varchar](100) NULL,
	[PUK] [varchar](100) NULL,
	[OPERATOR] [int] NULL,
	[CODMODEL] [int] NULL,
	[COMPANY] [int] NULL,
	[ORDER_NUMBER] [varchar](150) NULL,
	[ORDER_CODE] [int] NULL,
	[PARTNUMBER] [varchar](150) NULL
)
GO




INSERT INTO ACQUIRER (CREATED_AT, CODE, NAME, COD_USER, ALIAS, SUBTITLE, INTEGRATION, ACTIVE, [GROUP], LOGICAL_NUMBER, COD_SEG_GROUP, ONLINE)
	VALUES (current_timestamp, 'GLOBAL PAYMENTS', 'GLOBALPAYMENTS', NULL, NULL, 'GLOBALPAYMENTS', 0, CONVERT(BIT, 'True'), 'GLOBALPAYMENTS', 0, NULL, NULL)
GO

INSERT INTO PRODUCTS_ACQUIRER (COD_TTYPE, COD_AC, NAME, EXTERNALCODE, COD_BRAND, PLOT_VALUE, IS_SIMULATED, COD_SOURCE_TRAN, VISIBLE)
	SELECT
		COD_TTYPE
	   ,(SELECT TOP 1
				COD_AC
			FROM ACQUIRER
			ORDER BY 1 DESC)
	   ,NAME
	   ,EXTERNALCODE
	   ,COD_BRAND
	   ,PLOT_VALUE
	   ,IS_SIMULATED
	   ,COD_SOURCE_TRAN
	   ,VISIBLE
	FROM PRODUCTS_ACQUIRER pa
	WHERE COD_AC = 10


GO

INSERT INTO ASS_TR_TYPE_COMP (CREATED_AT, COD_USER, COD_TTYPE, COD_AC, COD_COMP, ACTIVE, MODIFY_DATE, CODE, TAX_VALUE, PLOT_INI, PLOT_END, INTERVAL, COD_BRAND, AVAILABLE, COD_SOURCE_TRAN)
	SELECT
		CREATED_AT
	   ,COD_USER
	   ,COD_TTYPE
	   ,(SELECT TOP 1
				COD_AC
			FROM ACQUIRER
			ORDER BY 1 DESC)
	   ,COD_COMP
	   ,ACTIVE
	   ,MODIFY_DATE
	   ,CODE
	   ,TAX_VALUE
	   ,PLOT_INI
	   ,PLOT_END
	   ,INTERVAL
	   ,COD_BRAND
	   ,AVAILABLE
	   ,COD_SOURCE_TRAN
	FROM ASS_TR_TYPE_COMP attc
	WHERE attc.COD_AC = 10

GO

ALTER PROCEDURE [dbo].[SP_DATA_COMP_ACQ]
/*----------------------------------------------------------------------------------------               
Procedure Name: [SP_DATA_COMP_ACQ]               
Project.......: TKPP               
------------------------------------------------------------------------------------------               
Author           VERSION           Date               Description               
------------------------------------------------------------------------------------------               
Kennedy Alef        V1           27/07/2018             Creation               
Caike Uch�a         V2           15/01/2020         Tirar join segments            
------------------------------------------------------------------------------------------*/ (@TERMINALID INT,
@ACQUIRER_NAME VARCHAR(100),
@SERVICE INT = NULL,
@COD_PRD_TRAN INT = NULL,
@COD_PRD_ACQ_OLD INT = NULL,
@NSU VARCHAR(400) = NULL)
AS

	DECLARE @ACQ INT;
	DECLARE @TID_NUMBER VARCHAR(400);
	BEGIN


		IF UPPER(@ACQUIRER_NAME) = 'PAGSEGURO'
		BEGIN

			IF (@NSU IS NOT NULL)
				SELECT
					@TID_NUMBER = t.LOGICAL_NUMBER_ACQ
				FROM [TRANSACTION] t WITH (NOLOCK)
				WHERE CODE = @NSU

			IF @COD_PRD_TRAN IS NOT NULL
			BEGIN


				WITH CTE
				AS
				(SELECT
						--MERCHANT_LOGICALNUMBERS_ACQ.[NAME]       
						MERCHANT_LOGICALNUMBERS_ACQ.COD_EC AS [VALUE]
					   ,ISNULL(@TID_NUMBER, MERCHANT_LOGICALNUMBERS_ACQ.LOGICAL_NUMBER_ACQ) TID_VALUE
					   ,'' ALIAS
					   ,'PagSeguro' SUBTITLE
					   ,(SELECT
								(SELECT
										PRD_NEW.COD_PR_ACQ
									FROM PRODUCTS_ACQUIRER PRD_NEW
									WHERE COD_AC = ACQUIRER.COD_AC
									AND PRODUCTS_ACQUIRER.[COD_TTYPE] = PRD_NEW.[COD_TTYPE]
									AND PRODUCTS_ACQUIRER.[NAME] = PRD_NEW.[NAME]
									AND PRODUCTS_ACQUIRER.[EXTERNALCODE] = PRD_NEW.[EXTERNALCODE]
									AND PRODUCTS_ACQUIRER.[COD_BRAND] = PRD_NEW.COD_BRAND
									AND PRODUCTS_ACQUIRER.[PLOT_VALUE] = PRD_NEW.PLOT_VALUE
									AND ISNULL(PRODUCTS_ACQUIRER.[IS_SIMULATED], 0) = ISNULL(PRD_NEW.IS_SIMULATED, 0)
									AND PRODUCTS_ACQUIRER.[COD_SOURCE_TRAN] = PRD_NEW.COD_SOURCE_TRAN
									AND PRODUCTS_ACQUIRER.[VISIBLE] = PRD_NEW.VISIBLE)
							FROM PRODUCTS_ACQUIRER
							WHERE PRODUCTS_ACQUIRER.COD_PR_ACQ = @COD_PRD_ACQ_OLD)
						AS COD_PRD_ACQ
					   ,MERCHANT_LOGICALNUMBERS_ACQ.COD_EC AS MERCHANT
					FROM MERCHANT_LOGICALNUMBERS_ACQ
					JOIN TRANSACTION_PRODUCTS
						ON TRANSACTION_PRODUCTS.COD_EC = MERCHANT_LOGICALNUMBERS_ACQ.COD_EC
					JOIN ACQUIRER
						ON ACQUIRER.COD_AC = MERCHANT_LOGICALNUMBERS_ACQ.COD_AC
					WHERE TRANSACTION_PRODUCTS.COD_TRAN_PROD = @COD_PRD_TRAN)
				SELECT
					'PAGSEGUROCODE' AS NAME_DATA
				   ,CTE.*
				FROM CTE
				UNION
				SELECT
					'SOFTDESCRIPTOR' AS NAME_DATA
				   ,CTE.*
				FROM CTE


			END
			ELSE
			BEGIN

				SELECT
					DADOS_COMP_ACQ.NAME AS NAME_DATA
				   ,CASE
						WHEN @SERVICE IS NULL THEN CONVERT(VARCHAR(100), [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC)
						ELSE 2
					END AS VALUE
				   ,ISNULL(@TID_NUMBER, (SELECT TOP 1
							DATA_EQUIPMENT_AC.CODE
						FROM DATA_EQUIPMENT_AC
						JOIN ACQUIRER
							ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
						WHERE DATA_EQUIPMENT_AC.ACTIVE = 1
						AND UPPER(ACQUIRER.[GROUP]) = 'pagseguro'
						AND DATA_EQUIPMENT_AC.COD_EQUIP = [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
					--AND ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP            
					)
					)
					AS TID_VALUE
				   ,ACQUIRER.ALIAS
				   ,ACQUIRER.SUBTITLE
				   ,CASE
						WHEN @SERVICE IS NOT NULL THEN 2
						ELSE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
					END AS MERCHANT
				FROM DADOS_COMP_ACQ
				INNER JOIN ASS_TR_TYPE_COMP
					ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = DADOS_COMP_ACQ.COD_ASS_TR_COMP
				INNER JOIN [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ]
					ON [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_COMP = ASS_TR_TYPE_COMP.COD_COMP
				INNER JOIN ACQUIRER
					ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
				WHERE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP = @TERMINALID
				AND ASS_TR_TYPE_COMP.ACTIVE = 1
				AND ACQUIRER.COD_AC = 10
				GROUP BY DADOS_COMP_ACQ.NAME
						,DADOS_COMP_ACQ.VALUE
						,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
						,ACQUIRER.ALIAS
						,ACQUIRER.SUBTITLE
						,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
			END;
		END;

		IF UPPER(@ACQUIRER_NAME) = 'ADIQ'
		BEGIN

			SELECT
				DADOS_COMP_ACQ.NAME AS NAME_DATA
			   ,DADOS_COMP_ACQ.value
			   ,DATA_EQUIPMENT_AC.CODE AS TID_VALUE
			   ,ACQUIRER.ALIAS
			   ,ACQUIRER.SUBTITLE
			   ,CASE
					WHEN @SERVICE IS NOT NULL THEN 2
					ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
				END AS MERCHANT
			FROM DADOS_COMP_ACQ
			INNER JOIN ASS_TR_TYPE_COMP
				ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = DADOS_COMP_ACQ.COD_ASS_TR_COMP
			INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
				ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_COMP = ASS_TR_TYPE_COMP.COD_COMP
			INNER JOIN ACQUIRER
				ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
			LEFT JOIN DATA_EQUIPMENT_AC
				ON DATA_EQUIPMENT_AC.COD_AC = ACQUIRER.COD_AC
			WHERE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
			AND ASS_TR_TYPE_COMP.ACTIVE = 1
			AND ACQUIRER.NAME = @ACQUIRER_NAME
			GROUP BY DADOS_COMP_ACQ.NAME
					,DADOS_COMP_ACQ.value
					,VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
					,DATA_EQUIPMENT_AC.CODE
					,ACQUIRER.ALIAS
					,ACQUIRER.SUBTITLE
			UNION
			SELECT
				'BONSUCESSOCODE' AS NAME_DATA
			   ,EXTERNAL_DATA_EC_ACQ.[VALUE] AS VALUE
			   ,'1' AS TID_VALUE
			   ,ACQUIRER.ALIAS
			   ,ACQUIRER.SUBTITLE
			   ,CASE
					WHEN @SERVICE IS NOT NULL THEN 2
					ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
				END AS MERCHANT
			FROM EXTERNAL_DATA_EC_ACQ
			INNER JOIN ACQUIRER
				ON ACQUIRER.COD_AC = EXTERNAL_DATA_EC_ACQ.COD_AC
			INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
				ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC = EXTERNAL_DATA_EC_ACQ.COD_EC
			WHERE EXTERNAL_DATA_EC_ACQ.ACTIVE = 1
			AND VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
			AND ACQUIRER.NAME = @ACQUIRER_NAME
			AND EXTERNAL_DATA_EC_ACQ.[NAME] = 'MID'
		--AND EXTERNAL_DATA_EC_ACQ.[NAME]= 'TID';               


		END;

		IF UPPER(@ACQUIRER_NAME) = 'STONE'

		BEGIN

			SELECT
				DADOS_COMP_ACQ.NAME AS NAME_DATA
			   ,DADOS_COMP_ACQ.[VALUE] AS VALUE
			   ,(SELECT
						DATA_EQUIPMENT_AC.CODE
					FROM DATA_EQUIPMENT_AC
					INNER JOIN ACQUIRER
						ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
					WHERE DATA_EQUIPMENT_AC.COD_EQUIP =
					[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
					AND DATA_EQUIPMENT_AC.ACTIVE = 1
					AND UPPER(ACQUIRER.NAME) = UPPER(@ACQUIRER_NAME))
				AS TID_VALUE
			   ,ACQUIRER.ALIAS
			   ,ACQUIRER.SUBTITLE
			   ,CASE
					WHEN @SERVICE IS NOT NULL THEN 2
					ELSE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
				END AS MERCHANT
			FROM DADOS_COMP_ACQ
			INNER JOIN ASS_TR_TYPE_COMP
				ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP =
					DADOS_COMP_ACQ.COD_ASS_TR_COMP
			INNER JOIN [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ]
				ON [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_COMP =
					ASS_TR_TYPE_COMP.COD_COMP
			INNER JOIN ACQUIRER
				ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
			WHERE [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP = @TERMINALID
			AND ASS_TR_TYPE_COMP.ACTIVE = 1
			AND ACQUIRER.NAME = @ACQUIRER_NAME
			GROUP BY DADOS_COMP_ACQ.NAME
					,DADOS_COMP_ACQ.VALUE
					,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC
					,ACQUIRER.ALIAS
					,ACQUIRER.SUBTITLE
					,[VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP


		END;

		IF UPPER(@ACQUIRER_NAME) LIKE '%SOFTCRED%'

		BEGIN


			SELECT
				DADOS_COMP_ACQ.NAME AS NAME_DATA
			   ,DADOS_COMP_ACQ.value
			   ,DATA_EQUIPMENT_AC.CODE AS TID_VALUE
			   ,ACQUIRER.ALIAS
			   ,ACQUIRER.SUBTITLE
			   ,CASE
					WHEN @SERVICE IS NOT NULL THEN 2
					ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
				END AS MERCHANT
			FROM DADOS_COMP_ACQ
			INNER JOIN ASS_TR_TYPE_COMP
				ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = DADOS_COMP_ACQ.COD_ASS_TR_COMP
			INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
				ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_COMP = ASS_TR_TYPE_COMP.COD_COMP
			INNER JOIN ACQUIRER
				ON ACQUIRER.COD_AC = ASS_TR_TYPE_COMP.COD_AC
			LEFT JOIN DATA_EQUIPMENT_AC
				ON DATA_EQUIPMENT_AC.COD_AC = ACQUIRER.COD_AC
			WHERE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
			AND ASS_TR_TYPE_COMP.ACTIVE = 1
			AND ACQUIRER.NAME = @ACQUIRER_NAME
			GROUP BY DADOS_COMP_ACQ.NAME
					,DADOS_COMP_ACQ.value
					,VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
					,DATA_EQUIPMENT_AC.CODE
					,ACQUIRER.ALIAS
					,ACQUIRER.SUBTITLE
			UNION
			SELECT
				EXTERNAL_DATA_EC_ACQ.NAME AS NAME_DATA
			   ,EXTERNAL_DATA_EC_ACQ.[VALUE] AS VALUE
			   ,'1' AS TID_VALUE
			   ,ACQUIRER.ALIAS
			   ,ACQUIRER.SUBTITLE
			   ,CASE
					WHEN @SERVICE IS NOT NULL THEN 2
					ELSE VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC
				END AS MERCHANT
			FROM EXTERNAL_DATA_EC_ACQ
			INNER JOIN ACQUIRER
				ON ACQUIRER.COD_AC = EXTERNAL_DATA_EC_ACQ.COD_AC
			INNER JOIN VW_COMPANY_EC_BR_DEP_EQUIP
				ON VW_COMPANY_EC_BR_DEP_EQUIP.COD_EC = EXTERNAL_DATA_EC_ACQ.COD_EC
			WHERE EXTERNAL_DATA_EC_ACQ.ACTIVE = 1
			AND VW_COMPANY_EC_BR_DEP_EQUIP.COD_EQUIP = @TERMINALID
			AND ACQUIRER.NAME = @ACQUIRER_NAME;


		END;

		IF UPPER(@ACQUIRER_NAME) = 'ITSPAY'
		BEGIN

			SELECT
				'260200000000000' AS LOGICAL_NUMBER
		END;

		IF @ACQUIRER_NAME = 'Cielo Presencial'
			OR @ACQUIRER_NAME = 'Cielo'

			SELECT
				'Cielo' AS ALIAS
			   ,'Cielo' AS SUBTITLE
			   ,'' AS NAME_DATA
			   ,'' AS [VALUE]

		IF @ACQUIRER_NAME = 'GLOBAL PAYMENTS'
			OR @ACQUIRER_NAME = 'GLOBALPAYMENTS'

			SELECT
				'GLOBALPAYMENTS' AS ALIAS
			   ,'GLOBALPAYMENTS' AS SUBTITLE
			   ,'MID' AS NAME
			   ,'012043412506001' AS [value]


	END;


GO

ALTER PROCEDURE [dbo].[SP_DATA_EQUIP_AC]
/*----------------------------------------------------------------------------------------                   
Procedure Name: [SP_DATA_EQUIP_AC]                   
Project.......: TKPP                   
------------------------------------------------------------------------------------------                   
Author                          VERSION        Date                            Description                   
------------------------------------------------------------------------------------------                   
Kennedy Alef                      V1         27/07/2018                         Creation                   
Lucas Aguiar                      v2         01/04/2019              Alterao nome do acquire pelo group              
Kennedy Alef                      v3         14/08/2019                      Rollback - Stone                 
Kenendy Alef                      v4         26/09/2019                         Erro 015 PS            
Caike Uch�a                       v5         15/01/2020                  tirar join segments_group        
------------------------------------------------------------------------------------------*/ (@TERMINALID INT,
@ACQUIRER_NAME VARCHAR(100),
@COD_PRD_TRAN INT = NULL,
@COD_PRD_ACQ_OLD INT = NULL,
@NSU VARCHAR(400) = NULL)
AS
	DECLARE @ACQ VARCHAR(100);


	BEGIN


		IF UPPER(@ACQUIRER_NAME) = 'PAGSEGURO'
		BEGIN

			IF (@NSU IS NOT NULL)
			BEGIN
				SELECT
					'TID' AS 'NAME'
				   ,(SELECT
							t.LOGICAL_NUMBER_ACQ
						FROM [TRANSACTION] t
						WHERE CODE = @NSU)
					AS 'CODE'
				   ,a.NAME AS 'ACQ_NAME'
				   ,@TERMINALID AS 'COD_EQUIP'
				FROM ACQUIRER a
				WHERE a.COD_AC = 10

			END
			ELSE
			BEGIN
				IF @COD_PRD_TRAN IS NOT NULL
				BEGIN

					SELECT
						MERCHANT_LOGICALNUMBERS_ACQ.[NAME]
					   ,MERCHANT_LOGICALNUMBERS_ACQ.LOGICAL_NUMBER_ACQ CODE
					   ,ACQUIRER.COD_AC
					   ,ACQUIRER.[NAME] ACQ_NAME
					   ,(SELECT
								(SELECT
										PRD_NEW.COD_PR_ACQ
									FROM PRODUCTS_ACQUIRER PRD_NEW
									WHERE COD_AC = ACQUIRER.COD_AC
									AND PRODUCTS_ACQUIRER.[COD_TTYPE] = PRD_NEW.[COD_TTYPE]
									AND PRODUCTS_ACQUIRER.[NAME] = PRD_NEW.[NAME]
									AND PRODUCTS_ACQUIRER.[EXTERNALCODE] = PRD_NEW.[EXTERNALCODE]
									AND PRODUCTS_ACQUIRER.[COD_BRAND] = PRD_NEW.COD_BRAND
									AND PRODUCTS_ACQUIRER.[PLOT_VALUE] = PRD_NEW.PLOT_VALUE
									AND ISNULL(PRODUCTS_ACQUIRER.[IS_SIMULATED], 0) = ISNULL(PRD_NEW.IS_SIMULATED, 0)
									AND PRODUCTS_ACQUIRER.[COD_SOURCE_TRAN] = PRD_NEW.COD_SOURCE_TRAN
									AND PRODUCTS_ACQUIRER.[VISIBLE] = PRD_NEW.VISIBLE)
							FROM PRODUCTS_ACQUIRER
							WHERE PRODUCTS_ACQUIRER.COD_PR_ACQ = @COD_PRD_ACQ_OLD)
						AS COD_PRD_ACQ
					FROM MERCHANT_LOGICALNUMBERS_ACQ
					JOIN TRANSACTION_PRODUCTS
						ON TRANSACTION_PRODUCTS.COD_EC = MERCHANT_LOGICALNUMBERS_ACQ.COD_EC
					JOIN ACQUIRER
						ON ACQUIRER.COD_AC = MERCHANT_LOGICALNUMBERS_ACQ.COD_AC
					WHERE TRANSACTION_PRODUCTS.COD_TRAN_PROD = @COD_PRD_TRAN


				END;
				ELSE
				BEGIN
					SELECT
						DATA_EQUIPMENT_AC.NAME
					   ,DATA_EQUIPMENT_AC.CODE
					   ,ACQUIRER.[GROUP] AS ACQ_NAME
					   ,DATA_EQUIPMENT_AC.COD_EQUIP
					FROM [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ]
					JOIN DATA_EQUIPMENT_AC
						ON DATA_EQUIPMENT_AC.COD_EQUIP = [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EQUIP
					JOIN ACQUIRER
						ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
					--JOIN COMMERCIAL_ESTABLISHMENT              
					-- ON COMMERCIAL_ESTABLISHMENT.COD_EC = [VW_COMPANY_EC_BR_DEP_EQUIP_ACQ].COD_EC              
					--JOIN SEGMENTS              
					-- ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG              
					--LEFT JOIN SEGMENTS_GROUP              
					-- ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP              
					WHERE DATA_EQUIPMENT_AC.ACTIVE = 1
					AND UPPER(ACQUIRER.[GROUP]) = 'PAGSEGURO'
					AND DATA_EQUIPMENT_AC.COD_EQUIP = @TERMINALID
				--AND ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP            
				END
			END
		END
		ELSE
		IF @ACQUIRER_NAME = 'Cielo'
			OR @ACQUIRER_NAME = 'Cielo Presencial'
		BEGIN


			CREATE TABLE #TMP_RETURN_CIELO (
				[NAME] VARCHAR(100)
			   ,CODE VARCHAR(100)
			)

			INSERT INTO #TMP_RETURN_CIELO
				VALUES ('CIELO_CLIENTID', 'dbd6cb1a-4075-4745-a8cb-164311b90bbf')
			INSERT INTO #TMP_RETURN_CIELO
				VALUES ('CIELO_CLIENTSECRET', 'IKwWlQ2SpmYBUvlIFe/gTomjyA7AYSgPHlCSZDC+F3c=')
			INSERT INTO #TMP_RETURN_CIELO
				VALUES ('SUBORDINATEDMERCHANTID', 'dbd6cb1a-4075-4745-a8cb-164311b90bbf')
			INSERT INTO #TMP_RETURN_CIELO
				VALUES ('TERMINALID', '00000001')


			SELECT
				@ACQUIRER_NAME AS ACQ_NAME
			   ,@TERMINALID AS COD_EQUIP
			   ,#TMP_RETURN_CIELO.*
			FROM #TMP_RETURN_CIELO


		END
		IF @ACQUIRER_NAME = 'GLOBAL PAYMENTS'
			OR @ACQUIRER_NAME = 'GLOBALPAYMENTS'
		BEGIN

			SELECT
				'MID' AS 'NAME'
			   ,'012043412506001' AS 'CODE'
			   ,'GLOBAL PAYMENTS' AS 'ACQ_NAME'
			   ,@TERMINALID AS 'COD_EQUIP'


		END
		ELSE
		BEGIN
			SELECT
				@ACQ = ACQUIRER.[NAME]
			FROM DATA_EQUIPMENT_AC
			JOIN ACQUIRER
				ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
			WHERE COD_EQUIP = @TERMINALID
			AND [GROUP] = UPPER(@ACQUIRER_NAME);

			SELECT
				DATA_EQUIPMENT_AC.NAME
			   ,DATA_EQUIPMENT_AC.CODE
			   ,ACQUIRER.NAME AS ACQ_NAME
			   ,DATA_EQUIPMENT_AC.COD_EQUIP
			   ,@NSU
			FROM DATA_EQUIPMENT_AC
			INNER JOIN ACQUIRER
				ON ACQUIRER.COD_AC = DATA_EQUIPMENT_AC.COD_AC
			WHERE DATA_EQUIPMENT_AC.COD_EQUIP = @TERMINALID
			AND ACQUIRER.[GROUP] = @ACQ
			AND DATA_EQUIPMENT_AC.ACTIVE = 1
		END
	END


GO

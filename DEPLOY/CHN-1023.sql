--ET-886

IF OBJECT_ID('SP_RGW_LOAD_ALL_TABLES_EQUIP') IS NOT NULL
    DROP PROCEDURE SP_RGW_LOAD_ALL_TABLES_EQUIP
GO
CREATE PROCEDURE [DBO].[SP_RGW_LOAD_ALL_TABLES_EQUIP](@COD_AF CODE_TYPE READONLY, @COD_EC CODE_TYPE READONLY, @COD_EQP CODE_TYPE READONLY)
AS
BEGIN

    CREATE TABLE #EQPs (
       COD_AFFILIATOR INT,
       COD_COMP INT,
       COD_DEPTO_BR INT,
       COD_EC INT,
       DATE_PLAN DATETIME,
       COD_EQUIP INT,
       DT DATETIME,
       COD_MODEL INT
    )

    INSERT INTO #EQPs (COD_AFFILIATOR, COD_COMP, COD_DEPTO_BR, COD_EC, DATE_PLAN, COD_EQUIP, DT, COD_MODEL)
    SELECT ISNULL(CE.COD_AFFILIATOR, 0) AS COD_AFFILIATOR
         , E.COD_COMP
         , DB.COD_DEPTO_BRANCH AS COD_DEPTO_BR
         , BE.COD_EC
         , MAX (ATD.CREATED_AT) AS DATE_PLAN
         , E.COD_EQUIP
         , CAST(CONVERT(VARCHAR, GETDATE(), 101)  AS DATETIME) [DT]
         , E.COD_MODEL
    FROM ASS_DEPTO_EQUIP ADE
             JOIN EQUIPMENT E on E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1
             JOIN DEPARTMENTS_BRANCH DB ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
             JOIN BRANCH_EC BE ON BE.COD_BRANCH = DB.COD_BRANCH
             JOIN COMMERCIAL_ESTABLISHMENT CE on BE.COD_EC = CE.COD_EC
             JOIN ASS_TAX_DEPART ATD on DB.COD_DEPTO_BRANCH = ATD.COD_DEPTO_BRANCH AND ATD.ACTIVE = 1
    WHERE ADE.ACTIVE = 1
    GROUP BY E.COD_COMP, DB.COD_DEPTO_BRANCH, ISNULL(CE.COD_AFFILIATOR, 0), BE.COD_EC, E.COD_EQUIP, E.COD_MODEL

    IF EXISTS(SELECT CODE FROM @COD_AF)
        DELETE FROM #Eqps WHERE COD_AFFILIATOR IS NULL OR COD_AFFILIATOR NOT IN (SELECT CODE FROM @COD_AF)

    IF EXISTS(SELECT CODE FROM @COD_EC)
        DELETE FROM #Eqps WHERE COD_EC IS NULL OR COD_EC NOT IN (SELECT CODE FROM @COD_EC)

    IF EXISTS(SELECT CODE FROM @COD_EQP)
        DELETE FROM #Eqps WHERE COD_EQUIP IS NULL OR COD_EQUIP NOT IN (SELECT CODE FROM @COD_EQP)

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
         , IIF(eqp.DATE_PLAN > eqp.[DT], dbo.FN_FUS_UTF(eqp.DATE_PLAN), eqp.[DT])  DATE_PLAN
         , eqp.COD_MODEL
         , eqp.COD_AFFILIATOR
    INTO #CTE_EQUIP_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EQUIP = eqp.COD_EQUIP AND RA.CONF_TYPE = 1 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2

    SELECT  RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
         , IIF(eqp.DATE_PLAN > eqp.[DT], dbo.FN_FUS_UTF(eqp.DATE_PLAN), eqp.[DT])  DATE_PLAN
         , eqp.COD_MODEL
         , eqp.COD_AFFILIATOR
    INTO #CTE_EC_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EC = eqp.COD_EC AND RA.CONF_TYPE = 2 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL

    SELECT  RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
         , IIF(eqp.DATE_PLAN > eqp.[DT], dbo.FN_FUS_UTF(eqp.DATE_PLAN), eqp.[DT])  DATE_PLAN
         , eqp.COD_MODEL
         , eqp.COD_AFFILIATOR
    INTO #CTE_AFF_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND RA.CONF_TYPE = 3 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             LEFT JOIN #CTE_EC_RT EC_RT ON EC_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EC_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL AND EC_RT.COD_AC IS NULL

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
         , IIF(eqp.DATE_PLAN > eqp.[DT], dbo.FN_FUS_UTF(eqp.DATE_PLAN), eqp.[DT])  DATE_PLAN
         , eqp.COD_MODEL
         , eqp.COD_AFFILIATOR
    INTO #CTE_SUB_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON CONF_TYPE = 4 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2 AND RA.COD_COMP = eqp.COD_COMP
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             LEFT JOIN #CTE_EC_RT EC_RT ON EC_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EC_RT.COD_BRAND
             LEFT JOIN #CTE_AFF_RT AF_RT ON AF_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = AF_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL AND EC_RT.COD_AC IS NULL AND AF_RT.COD_AC IS NULL

    SELECT ACQUIRER.[GROUP]              AS AcquireName
         , PA.COD_PR_ACQ                  AS ProductId
         , PA.NAME                        AS ProductName
         , PA.EXTERNALCODE                AS ProductExtCode
         , [TRAN_TYPE].COD_TTYPE          AS TranType
         , [TRAN_TYPE].NAME               AS TranTypeName
         , '0'                            AS CodeEcAcq
         , BRAND.NAME                     AS Brand
         , eqp.CONF_TYPE                  AS ConfType
         , PA.IS_SIMULATED                AS IsSimulated
         , eqp.DATE_PLAN                  AS DatePlan
         , eqp.COD_EQUIP                  AS CodEquip
         , 'EQP'                          AS RouteType
    FROM #CTE_EQUIP_RT eqp
             JOIN dbo.BRAND ON BRAND.COD_BRAND = eqp.COD_BRAND
             JOIN [TRANSACTION_TYPE] TRAN_TYPE ON [TRAN_TYPE].COD_TTYPE = BRAND.COD_TTYPE
             JOIN ACQUIRER ON ACQUIRER.COD_AC = eqp.COD_AC AND ACQUIRER.ACTIVE = 1
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             LEFT JOIN PRODUCT_UNAVAILABLE_MODEL PUM ON PUM.COD_MODEL = eqp.COD_MODEL AND PUM.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND PUM.COD_PR_ACQ = PA.COD_PR_ACQ
    WHERE PUM.COD_PRD_UN_MODEL IS NULL

    UNION

    SELECT ACQUIRER.[GROUP]              AS AcquireName
         , PA.COD_PR_ACQ                  AS ProductId
         , PA.NAME                        AS ProductName
         , PA.EXTERNALCODE                AS ProductExtCode
         , [TRAN_TYPE].COD_TTYPE          AS TranType
         , [TRAN_TYPE].NAME               AS TranTypeName
         , '0'                            AS CodeEcAcq
         , BRAND.NAME                     AS Brand
         , eqp.CONF_TYPE                  AS ConfType
         , PA.IS_SIMULATED                AS IsSimulated
         , eqp.DATE_PLAN                  AS DatePlan
         , eqp.COD_EQUIP                  AS CodEquip
         , 'EC'                           AS RouteType
    FROM #CTE_EC_RT eqp
             JOIN dbo.BRAND ON BRAND.COD_BRAND = eqp.COD_BRAND
             JOIN [TRANSACTION_TYPE] TRAN_TYPE ON [TRAN_TYPE].COD_TTYPE = BRAND.COD_TTYPE
             JOIN ACQUIRER ON ACQUIRER.COD_AC = eqp.COD_AC
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             LEFT JOIN PRODUCT_UNAVAILABLE_MODEL PUM ON PUM.COD_MODEL = eqp.COD_MODEL AND PUM.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND PUM.COD_PR_ACQ = PA.COD_PR_ACQ
    WHERE PUM.COD_PRD_UN_MODEL IS NULL
    
    UNION

    SELECT ACQUIRER.[GROUP]              AS AcquireName
         , PA.COD_PR_ACQ                  AS ProductId
         , PA.NAME                        AS ProductName
         , PA.EXTERNALCODE                AS ProductExtCode
         , [TRAN_TYPE].COD_TTYPE          AS TranType
         , [TRAN_TYPE].NAME               AS TranTypeName
         , '0'                            AS CodeEcAcq
         , BRAND.NAME                     AS Brand
         , eqp.CONF_TYPE                  AS ConfType
         , PA.IS_SIMULATED                AS IsSimulated
         , eqp.DATE_PLAN                  AS DatePlan
         , eqp.COD_EQUIP                  AS CodEquip
         , 'AFF'                          AS RouteType
    FROM #CTE_AFF_RT eqp
             JOIN dbo.BRAND ON BRAND.COD_BRAND = eqp.COD_BRAND
             JOIN [TRANSACTION_TYPE] TRAN_TYPE ON [TRAN_TYPE].COD_TTYPE = BRAND.COD_TTYPE
             JOIN ACQUIRER ON ACQUIRER.COD_AC = eqp.COD_AC
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             LEFT JOIN PRODUCT_UNAVAILABLE_MODEL PUM ON PUM.COD_MODEL = eqp.COD_MODEL AND PUM.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND PUM.COD_PR_ACQ = PA.COD_PR_ACQ
    WHERE PUM.COD_PRD_UN_MODEL IS NULL
    
    UNION

    SELECT ACQUIRER.[GROUP]              AS AcquireName
         , PA.COD_PR_ACQ                  AS ProductId
         , PA.NAME                        AS ProductName
         , PA.EXTERNALCODE                AS ProductExtCode
         , [TRAN_TYPE].COD_TTYPE          AS TranType
         , [TRAN_TYPE].NAME               AS TranTypeName
         , '0'                            AS CodeEcAcq
         , BRAND.NAME                     AS Brand
         , eqp.CONF_TYPE                  AS ConfType
         , PA.IS_SIMULATED                AS IsSimulated
         , eqp.DATE_PLAN                  AS DatePlan
         , eqp.COD_EQUIP                  AS CodEquip
         , 'SUB'                          AS RouteType
    FROM #CTE_SUB_RT eqp
             JOIN dbo.BRAND ON BRAND.COD_BRAND = eqp.COD_BRAND
             JOIN [TRANSACTION_TYPE] TRAN_TYPE ON [TRAN_TYPE].COD_TTYPE = BRAND.COD_TTYPE
             JOIN ACQUIRER ON ACQUIRER.COD_AC = eqp.COD_AC
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             LEFT JOIN PRODUCT_UNAVAILABLE_MODEL PUM ON PUM.COD_MODEL = eqp.COD_MODEL AND PUM.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND PUM.COD_PR_ACQ = PA.COD_PR_ACQ
    WHERE PUM.COD_PRD_UN_MODEL IS NULL
END


GO


IF OBJECT_ID('SP_RGW_ALL_PARAM_PROD_ACQ') IS NOT NULL
    DROP PROCEDURE SP_RGW_ALL_PARAM_PROD_ACQ
GO
CREATE PROCEDURE [DBO].[SP_RGW_ALL_PARAM_PROD_ACQ](@COD_AF CODE_TYPE READONLY, @COD_EC CODE_TYPE READONLY, @COD_EQP CODE_TYPE READONLY)
AS
BEGIN

    CREATE TABLE #EQPs (
                           COD_AFFILIATOR INT,
                           COD_COMP INT,
                           COD_DEPTO_BR INT,
                           COD_EC INT,
                           COD_EQUIP INT
    )

    INSERT INTO #EQPs (COD_AFFILIATOR, COD_COMP, COD_DEPTO_BR, COD_EC, COD_EQUIP)
    SELECT ISNULL(CE.COD_AFFILIATOR, 0) AS COD_AFFILIATOR
         , E.COD_COMP
         , DB.COD_DEPTO_BRANCH AS COD_DEPTO_BR
         , BE.COD_EC
         , E.COD_EQUIP
    FROM ASS_DEPTO_EQUIP ADE
             JOIN EQUIPMENT E on E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1
             JOIN DEPARTMENTS_BRANCH DB ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
             JOIN BRANCH_EC BE ON BE.COD_BRANCH = DB.COD_BRANCH
             JOIN COMMERCIAL_ESTABLISHMENT CE on BE.COD_EC = CE.COD_EC
    WHERE ADE.ACTIVE = 1
    GROUP BY E.COD_COMP, DB.COD_DEPTO_BRANCH, ISNULL(CE.COD_AFFILIATOR, 0), BE.COD_EC, E.COD_EQUIP;

    IF EXISTS(SELECT CODE FROM @COD_AF)
        DELETE FROM #Eqps WHERE COD_AFFILIATOR IS NULL OR COD_AFFILIATOR NOT IN (SELECT CODE FROM @COD_AF)

    IF EXISTS(SELECT CODE FROM @COD_EC)
        DELETE FROM #Eqps WHERE COD_EC IS NULL OR COD_EC NOT IN (SELECT CODE FROM @COD_EC)

    IF EXISTS(SELECT CODE FROM @COD_EQP)
        DELETE FROM #Eqps WHERE COD_EQUIP IS NULL OR COD_EQUIP NOT IN (SELECT CODE FROM @COD_EQP)


    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_EQUIP_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EQUIP = eqp.COD_EQUIP AND RA.CONF_TYPE = 1 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2;

    SELECT  RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_EC_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EC = eqp.COD_EC AND RA.CONF_TYPE = 2 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL;

    SELECT  RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_AFF_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND RA.CONF_TYPE = 3 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             LEFT JOIN #CTE_EC_RT EC_RT ON EC_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EC_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL AND EC_RT.COD_AC IS NULL;

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_SUB_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON CONF_TYPE = 4 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2 AND RA.COD_COMP = eqp.COD_COMP
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             LEFT JOIN #CTE_EC_RT EC_RT ON EC_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EC_RT.COD_BRAND
             LEFT JOIN #CTE_AFF_RT AF_RT ON AF_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = AF_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL AND EC_RT.COD_AC IS NULL AND AF_RT.COD_AC IS NULL;

    SELECT eqp.COD_EQUIP [CodEquip],
           PA.COD_PR_ACQ [ProdId],
           Pa.COD_AC [AcquirerId],
           PP.NAME [ParamName],
           PP.TAGNAME [ParamTagName],
           APP.VALUE [ParamsValue]
    FROM #CTE_EQUIP_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             JOIN ASS_PARAMS_PRODUCTS APP ON PA.COD_PR_ACQ = APP.COD_PR_ACQ
             JOIN PARAMETERS_PRODUCTS PP on APP.COD_PARAMETER = PP.COD_PARAMETER

    UNION

    SELECT eqp.COD_EQUIP [CodEquip],
           PA.COD_PR_ACQ [ProdId],
           Pa.COD_AC [AcquirerId],
           PP.NAME [ParamName],
           PP.TAGNAME [ParamTagName],
           APP.VALUE [ParamsValue]
    FROM #CTE_EC_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             JOIN ASS_PARAMS_PRODUCTS APP ON PA.COD_PR_ACQ = APP.COD_PR_ACQ
             JOIN PARAMETERS_PRODUCTS PP on APP.COD_PARAMETER = PP.COD_PARAMETER

    UNION

    SELECT eqp.COD_EQUIP [CodEquip],
           PA.COD_PR_ACQ [ProdId],
           Pa.COD_AC [AcquirerId],
           PP.NAME [ParamName],
           PP.TAGNAME [ParamTagName],
           APP.VALUE [ParamsValue]
    FROM #CTE_AFF_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             JOIN ASS_PARAMS_PRODUCTS APP ON PA.COD_PR_ACQ = APP.COD_PR_ACQ
             JOIN PARAMETERS_PRODUCTS PP on APP.COD_PARAMETER = PP.COD_PARAMETER

    UNION

    SELECT eqp.COD_EQUIP [CodEquip],
           PA.COD_PR_ACQ [ProdId],
           Pa.COD_AC [AcquirerId],
           PP.NAME [ParamName],
           PP.TAGNAME [ParamTagName],
           APP.VALUE [ParamsValue]
    FROM #CTE_SUB_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2  AND PA.VISIBLE = 1
             JOIN ASS_PARAMS_PRODUCTS APP ON PA.COD_PR_ACQ = APP.COD_PR_ACQ
             JOIN PARAMETERS_PRODUCTS PP on APP.COD_PARAMETER = PP.COD_PARAMETER

END
GO

IF OBJECT_ID('SP_RGW_ALL_CARD_RULES_PROD') IS NOT NULL
    DROP PROCEDURE SP_RGW_ALL_CARD_RULES_PROD
GO
CREATE PROCEDURE [DBO].[SP_RGW_ALL_CARD_RULES_PROD](@COD_AF CODE_TYPE READONLY, @COD_EC CODE_TYPE READONLY, @COD_EQP CODE_TYPE READONLY)
AS
BEGIN

    CREATE TABLE #EQPs
    (
        COD_AFFILIATOR INT,
        COD_COMP       INT,
        COD_DEPTO_BR   INT,
        COD_EC         INT,
        COD_EQUIP      INT,
    )

    INSERT INTO #EQPs (COD_AFFILIATOR, COD_COMP, COD_DEPTO_BR, COD_EC, COD_EQUIP)
    SELECT ISNULL(CE.COD_AFFILIATOR, 0) AS                    COD_AFFILIATOR
         , E.COD_COMP
         , DB.COD_DEPTO_BRANCH          AS                    COD_DEPTO_BR
         , BE.COD_EC
         , E.COD_EQUIP
    FROM ASS_DEPTO_EQUIP ADE
             JOIN EQUIPMENT E on E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1
             JOIN DEPARTMENTS_BRANCH DB ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
             JOIN BRANCH_EC BE ON BE.COD_BRANCH = DB.COD_BRANCH
             JOIN COMMERCIAL_ESTABLISHMENT CE on BE.COD_EC = CE.COD_EC
    WHERE ADE.ACTIVE = 1
    GROUP BY E.COD_COMP, DB.COD_DEPTO_BRANCH, ISNULL(CE.COD_AFFILIATOR, 0), BE.COD_EC, E.COD_EQUIP;

    IF EXISTS(SELECT CODE FROM @COD_AF)
        DELETE FROM #Eqps WHERE COD_AFFILIATOR IS NULL OR COD_AFFILIATOR NOT IN (SELECT CODE FROM @COD_AF)

    IF EXISTS(SELECT CODE FROM @COD_EC)
        DELETE FROM #Eqps WHERE COD_EC IS NULL OR COD_EC NOT IN (SELECT CODE FROM @COD_EC)

    IF EXISTS(SELECT CODE FROM @COD_EQP)
        DELETE FROM #Eqps WHERE COD_EQUIP IS NULL OR COD_EQUIP NOT IN (SELECT CODE FROM @COD_EQP)

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_EQUIP_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EQUIP = eqp.COD_EQUIP AND RA.CONF_TYPE = 1 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2;

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_EC_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EC = eqp.COD_EC AND RA.CONF_TYPE = 2 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL;

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_AFF_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND RA.CONF_TYPE = 3 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             LEFT JOIN #CTE_EC_RT EC_RT ON EC_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EC_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL AND EC_RT.COD_AC IS NULL;

    SELECT RA.COD_BRAND
         , eqp.COD_EQUIP
         , RA.CONF_TYPE
         , RA.COD_AC
    INTO #CTE_SUB_RT
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON CONF_TYPE = 4 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2 AND RA.COD_COMP = eqp.COD_COMP
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             LEFT JOIN #CTE_EC_RT EC_RT ON EC_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EC_RT.COD_BRAND
             LEFT JOIN #CTE_AFF_RT AF_RT ON AF_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = AF_RT.COD_BRAND
    WHERE EQP_RT.COD_AC IS NULL AND EC_RT.COD_AC IS NULL AND AF_RT.COD_AC IS NULL;


    SELECT eqp.COD_EQUIP  AS CodEquip,
           RPA.COD_PR_ACQ AS ProdId,
           CR.TAG_NAME    AS TagName
    FROM #CTE_EQUIP_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2 AND PA.VISIBLE = 1
             JOIN RULES_PRODUCTS_ACQ RPA (NOLOCK) ON RPA.COD_PR_ACQ = PA.COD_PR_ACQ
             JOIN CARD_RULES CR on RPA.COD_CARD_RULES = CR.COD_CARD_RULES

    UNION

    SELECT eqp.COD_EQUIP  AS CodEquip,
           RPA.COD_PR_ACQ AS ProdId,
           CR.TAG_NAME    AS TagName
    FROM #CTE_EC_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2 AND PA.VISIBLE = 1
             JOIN RULES_PRODUCTS_ACQ RPA (NOLOCK) ON RPA.COD_PR_ACQ = PA.COD_PR_ACQ
             JOIN CARD_RULES CR on RPA.COD_CARD_RULES = CR.COD_CARD_RULES

    UNION

    SELECT eqp.COD_EQUIP  AS CodEquip,
           RPA.COD_PR_ACQ AS ProdId,
           CR.TAG_NAME    AS TagName
    FROM #CTE_AFF_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2 AND PA.VISIBLE = 1
             JOIN RULES_PRODUCTS_ACQ RPA (NOLOCK) ON RPA.COD_PR_ACQ = PA.COD_PR_ACQ
             JOIN CARD_RULES CR on RPA.COD_CARD_RULES = CR.COD_CARD_RULES

    UNION

    SELECT eqp.COD_EQUIP  AS CodEquip,
           RPA.COD_PR_ACQ AS ProdId,
           CR.TAG_NAME    AS TagName
    FROM #CTE_SUB_RT eqp
             JOIN PRODUCTS_ACQUIRER PA ON PA.COD_BRAND = eqp.COD_BRAND AND PA.COD_AC = eqp.COD_AC AND PA.COD_SOURCE_TRAN = 2 AND PA.VISIBLE = 1
             JOIN RULES_PRODUCTS_ACQ RPA (NOLOCK) ON RPA.COD_PR_ACQ = PA.COD_PR_ACQ
             JOIN CARD_RULES CR on RPA.COD_CARD_RULES = CR.COD_CARD_RULES

END
GO

IF OBJECT_ID('SP_RGW_DATA_COMP_ACQ') IS NOT NULL
    DROP PROCEDURE SP_RGW_DATA_COMP_ACQ
GO
CREATE PROCEDURE [DBO].[SP_RGW_DATA_COMP_ACQ](@COD_AF CODE_TYPE READONLY, @COD_EC CODE_TYPE READONLY, @COD_EQP CODE_TYPE READONLY)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-09          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    CREATE TABLE #EQPs
    (
        COD_AFFILIATOR INT,
        COD_COMP       INT,
        COD_DEPTO_BR   INT,
        COD_EC         INT,
        COD_EQUIP      INT,
    )

    INSERT INTO #EQPs (COD_AFFILIATOR, COD_COMP, COD_DEPTO_BR, COD_EC, COD_EQUIP)
    SELECT ISNULL(CE.COD_AFFILIATOR, 0) AS COD_AFFILIATOR
         , E.COD_COMP
         , DB.COD_DEPTO_BRANCH          AS COD_DEPTO_BR
         , BE.COD_EC
         , E.COD_EQUIP
    FROM ASS_DEPTO_EQUIP ADE
             JOIN EQUIPMENT E on E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1
             JOIN DEPARTMENTS_BRANCH DB ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
             JOIN BRANCH_EC BE ON BE.COD_BRANCH = DB.COD_BRANCH
             JOIN COMMERCIAL_ESTABLISHMENT CE on BE.COD_EC = CE.COD_EC
    WHERE ADE.ACTIVE = 1
    GROUP BY E.COD_COMP, DB.COD_DEPTO_BRANCH, ISNULL(CE.COD_AFFILIATOR, 0), BE.COD_EC, E.COD_EQUIP;

    IF EXISTS(SELECT CODE FROM @COD_AF)
        DELETE FROM #Eqps WHERE COD_AFFILIATOR IS NULL OR COD_AFFILIATOR NOT IN (SELECT CODE FROM @COD_AF)

    IF EXISTS(SELECT CODE FROM @COD_EC)
        DELETE FROM #Eqps WHERE COD_EC IS NULL OR COD_EC NOT IN (SELECT CODE FROM @COD_EC)

    IF EXISTS(SELECT CODE FROM @COD_EQP)
        DELETE FROM #Eqps WHERE COD_EQUIP IS NULL OR COD_EQUIP NOT IN (SELECT CODE FROM @COD_EQP)

    CREATE TABLE #CTE_EQUIP_RT
    (
        COD_BRAND INT,
        COD_EQUIP INT,
        CONF_TYPE INT,
        COD_AC    INT,
        COD_EC    INT,
        GROUP_AC VARCHAR(64)
    )

    INSERT INTO #CTE_EQUIP_RT (COD_BRAND, COD_EQUIP, CONF_TYPE, COD_AC, [GROUP_AC], COD_EC)
    SELECT RA.COD_BRAND, eqp.COD_EQUIP, RA.CONF_TYPE, RA.COD_AC, A.[GROUP], eqp.COD_EC
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EQUIP = eqp.COD_EQUIP AND RA.CONF_TYPE = 1 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             JOIN ACQUIRER A on RA.COD_AC = A.COD_AC

    INSERT INTO #CTE_EQUIP_RT (COD_BRAND, COD_EQUIP, CONF_TYPE, COD_AC, [GROUP_AC], COD_EC)
    SELECT RA.COD_BRAND, eqp.COD_EQUIP, RA.CONF_TYPE, RA.COD_AC, A.[GROUP], eqp.COD_EC
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_EC = eqp.COD_EC AND RA.CONF_TYPE = 2 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             JOIN ACQUIRER A on RA.COD_AC = A.COD_AC
    WHERE EQP_RT.COD_AC IS NULL

    INSERT INTO #CTE_EQUIP_RT (COD_BRAND, COD_EQUIP, CONF_TYPE, COD_AC, [GROUP_AC], COD_EC)
    SELECT RA.COD_BRAND, eqp.COD_EQUIP, RA.CONF_TYPE, RA.COD_AC, A.[GROUP], eqp.COD_EC
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON RA.COD_AFFILIATOR = eqp.COD_AFFILIATOR AND RA.CONF_TYPE = 3 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             JOIN ACQUIRER A on  RA.COD_AC = A.COD_AC
    WHERE EQP_RT.COD_AC IS NULL

    INSERT INTO #CTE_EQUIP_RT (COD_BRAND, COD_EQUIP, CONF_TYPE, COD_AC, [GROUP_AC], COD_EC)
    SELECT RA.COD_BRAND, eqp.COD_EQUIP, RA.CONF_TYPE, RA.COD_AC, A.[GROUP], eqp.COD_EC
    FROM #EQPs eqp
             JOIN ROUTE_ACQUIRER RA ON CONF_TYPE = 4 AND RA.ACTIVE = 1 AND RA.COD_SOURCE_TRAN = 2 AND RA.COD_COMP = eqp.COD_COMP
             LEFT JOIN #CTE_EQUIP_RT EQP_RT ON EQP_RT.COD_EQUIP = eqp.COD_EQUIP AND RA.COD_BRAND = EQP_RT.COD_BRAND
             JOIN ACQUIRER A on RA.COD_AC = A.COD_AC
    WHERE EQP_RT.COD_AC IS NULL

    CREATE TABLE #EquipAc
    (
        COD_EQUIP INT,
        COD_AC    INT,
        GROUP_AC VARCHAR(64),
        COD_EC    INT
    )

    INSERT INTO #EquipAc (COD_EQUIP, COD_AC, GROUP_AC, COD_EC)
    select COD_EQUIP, COD_AC, GROUP_AC, COD_EC
    FROM #CTE_EQUIP_RT
    GROUP BY COD_EQUIP, COD_AC, GROUP_AC, COD_EC

    SELECT dca.NAME AS NameData
         , CAST(eqp.COD_EC AS VARCHAR(100)) AS Value -- OR 2 IF SERVICE HAS VALUE
         , (SELECT TOP 1 [DEA].CODE FROM DATA_EQUIPMENT_AC [DEA]
                                             JOIN ACQUIRER [DEA_ACQ] ON [DEA_ACQ].COD_AC = [DEA].COD_AC
            WHERE [DEA].ACTIVE = 1 AND [DEA_ACQ].[GROUP] = 'PagSeguro' AND [DEA].COD_EQUIP = eqp.COD_EQUIP) AS TidValue
         , A.ALIAS [Alias]
         , A.SUBTITLE [SubTitle]
         , eqp.COD_EC AS Merchant -- OR 2 IF SERVICE HAS VALUE
         , eqp.COD_EQUIP [CodEquip]
         , A.[GROUP] [AcquirerGroup]
         , CAST(NULL AS VARCHAR(100)) AS LogicalNumber
    FROM DADOS_COMP_ACQ dca
             JOIN ASS_TR_TYPE_COMP ATTC ON ATTC.COD_ASS_TR_COMP = dca.COD_ASS_TR_COMP
             JOIN ACQUIRER A ON A.COD_AC = ATTC.COD_AC
             JOIN #EquipAc eqp ON eqp.GROUP_AC = A.[GROUP]
    WHERE ATTC.ACTIVE = 1 AND A.COD_AC = 10 --AND COD_EQUIP = 9293
    GROUP BY dca.NAME, dca.VALUE, eqp.COD_EC, A.ALIAS, A.SUBTITLE, eqp.COD_EQUIP, A.[GROUP]

    UNION

    SELECT dca.NAME AS NameData
         , dca.Value
         , dea.CODE AS TidValue
         , A.Alias
         , A.Subtitle
         , eqp.COD_EC AS Merchant-- OR 2 IF SERVICE HAS VALUE
         , eqp.COD_EQUIP AS CodEquip
         , A.[GROUP] AS AcquirerGroup
         , CAST(NULL AS VARCHAR(100)) AS LogicalNumber
    FROM DADOS_COMP_ACQ dca
             JOIN ASS_TR_TYPE_COMP ATTC ON ATTC.COD_ASS_TR_COMP = dca.COD_ASS_TR_COMP
             JOIN ACQUIRER A ON A.COD_AC = ATTC.COD_AC
             JOIN #EquipAc eqp ON eqp.GROUP_AC = A.[GROUP]
             LEFT JOIN DATA_EQUIPMENT_AC dea ON dea.COD_AC = A.COD_AC
    WHERE ATTC.ACTIVE = 1 AND A.NAME = 'ADIQ'
    GROUP BY dca.NAME, dca.value, eqp.COD_EC, dea.CODE, A.ALIAS, A.SUBTITLE, eqp.COD_EQUIP, A.[GROUP]

    UNION

    SELECT 'BONSUCESSOCODE' AS NameData
         , edea.Value
         , '1' AS TidValue
         , A.Alias
         , A.Subtitle
         , eqp.COD_EC AS Merchant-- OR 2 IF SERVICE HAS VALUE
         , eqp.COD_EQUIP [CodEquip]
         , A.[GROUP] [AcquirerGroup]
         , CAST(NULL AS VARCHAR(100)) AS LogicalNumber
    FROM EXTERNAL_DATA_EC_ACQ edea
             JOIN ACQUIRER A ON A.COD_AC = edea.COD_AC
             JOIN #EquipAc eqp ON eqp.GROUP_AC = A.[GROUP] AND eqp.COD_EC = edea.COD_EC
    WHERE edea.ACTIVE = 1 AND A.NAME = 'ADIQ' AND edea.[NAME] = 'MID'

    UNION

    SELECT dca.NAME  AS NameData
         , dca.Value
         , (SELECT top 1 dea.CODE FROM DATA_EQUIPMENT_AC dea
                                           INNER JOIN ACQUIRER ON ACQUIRER.COD_AC = dea.COD_AC
            WHERE dea.COD_EQUIP = eqp.COD_EQUIP AND dea.ACTIVE = 1 AND ACQUIRER.NAME = 'STONE') AS TidValue
         , A.Alias
         , A.Subtitle
         , eqp.COD_EC AS Merchant-- OR 2 IF SERVICE HAS VALUE
         , eqp.COD_EQUIP AS CodEquip
         , A.[GROUP] As AcquirerGroup
         , CAST(NULL AS VARCHAR(100)) AS LogicalNumber
    FROM DADOS_COMP_ACQ dca
             JOIN ASS_TR_TYPE_COMP ON ASS_TR_TYPE_COMP.COD_ASS_TR_COMP = dca.COD_ASS_TR_COMP
             JOIN ACQUIRER A ON A.COD_AC = ASS_TR_TYPE_COMP.COD_AC
             JOIN #EquipAc eqp ON eqp.GROUP_AC = A.[GROUP]
    WHERE ASS_TR_TYPE_COMP.ACTIVE = 1 AND A.NAME = 'STONE'
    GROUP BY dca.NAME, dca.VALUE, eqp.COD_EC, A.ALIAS, A.SUBTITLE, eqp.COD_EQUIP, A.[GROUP]

    UNION

    SELECT dca.NAME AS NameData
         , dca.Value
         , dea.CODE AS TidValue
         , A.Alias
         , A.Subtitle
         , eqp.COD_EC AS Merchant-- OR 2 IF SERVICE HAS VALUE
         , eqp.COD_EQUIP [CodEquip]
         , A.[GROUP] [AcquirerGroup]
         , CAST(NULL AS VARCHAR(100)) AS LogicalNumber
    FROM DADOS_COMP_ACQ dca
             JOIN ASS_TR_TYPE_COMP attc ON attc.COD_ASS_TR_COMP = dca.COD_ASS_TR_COMP
             JOIN ACQUIRER A ON A.COD_AC = attc.COD_AC
             JOIN #EquipAc eqp ON eqp.GROUP_AC = A.[GROUP]
             LEFT JOIN DATA_EQUIPMENT_AC dea ON dea.COD_AC = A.COD_AC
    WHERE attc.ACTIVE = 1 AND A.NAME like 'Softcred%'
    GROUP BY dca.NAME, dca.value, eqp.COD_EC, dea.CODE, A.ALIAS, A.SUBTITLE, eqp.COD_EQUIP, A.[GROUP]

    UNION

    SELECT edea.NAME  AS NameData
         , edea.Value
         , '1' AS TidValue
         , A.Alias
         , A.Subtitle
         , edea.COD_EC AS Merchant
         , eqp.COD_EQUIP [CodEquip]
         , A.[GROUP] [AcquirerGroup]
         , CAST(NULL AS VARCHAR(100)) AS LogicalNumber
    FROM EXTERNAL_DATA_EC_ACQ edea-- OR 2 IF SERVICE HAS VALUE
             JOIN ACQUIRER A ON A.COD_AC = edea.COD_AC
             JOIN #EquipAc eqp ON eqp.GROUP_AC = A.[GROUP] AND edea.COD_EC = eqp.COD_EC
    WHERE edea.ACTIVE = 1 AND A.NAME like 'Softcred%'

    UNION

    SELECT NULL [NameData]
         , NULL [Value]
         , NULL [TidValue]
         , NULL [Alias]
         , NULL [Subtitle]
         , NULL [Merchant]
         , eqp.COD_EQUIP [CodEquip]
         , A.[GROUP] [AcquirerGroup]
         , '260200000000000' AS LogicalNumber
    FROM #EquipAc eqp
             JOIN ACQUIRER A on eqp.COD_AC = A.COD_AC
    WHERE A.[GROUP] = 'ItsPay'

END
GO

IF OBJECT_ID('SP_RGW_EQUIPMENT_DATA') IS NOT NULL
    DROP PROCEDURE SP_RGW_EQUIPMENT_DATA
GO
CREATE PROCEDURE [DBO].[SP_RGW_EQUIPMENT_DATA](@COD_AF CODE_TYPE READONLY, @COD_EC CODE_TYPE READONLY, @COD_EQP CODE_TYPE READONLY)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-10          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    CREATE TABLE #Eqps
    (
        COD_AFFILIATOR INT,
        COD_COMP INT,
        COD_DEPTO_BR INT,
        COD_EC INT,
        COD_EQUIP INT,
        COD_BRANCH INT,
        FIREBASE_NAME VARCHAR(128),
        ACTIVE INT,
        Serial VARCHAR(300),
        COD_ASS_DEPTO_TERMINAL INT
    )

    INSERT INTO #Eqps (COD_AFFILIATOR, COD_COMP, COD_DEPTO_BR, COD_EC, COD_EQUIP, COD_BRANCH, FIREBASE_NAME, ACTIVE, Serial, COD_ASS_DEPTO_TERMINAL)
    SELECT DISTINCT ISNULL(CE.COD_AFFILIATOR, 0)                 AS COD_AFFILIATOR
                  , E.COD_COMP
                  , ADE.COD_DEPTO_BRANCH                         AS COD_DEPTO_BR
                  , BE.COD_EC
                  , E.COD_EQUIP
                  , BE.COD_BRANCH
                  , C.FIREBASE_NAME
                  , e.ACTIVE
                  , e.SERIAL
                  , ADE.COD_ASS_DEPTO_TERMINAL
    FROM EQUIPMENT E
             JOIN COMPANY C ON C.COD_COMP = e.COD_COMP
             LEFT JOIN ASS_DEPTO_EQUIP ADE on E.COD_EQUIP = ADE.COD_EQUIP AND ADE.ACTIVE = 1
             LEFT JOIN DEPARTMENTS_BRANCH DB ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
             LEFT JOIN BRANCH_EC BE ON BE.COD_BRANCH = DB.COD_BRANCH
             LEFT JOIN COMMERCIAL_ESTABLISHMENT CE on BE.COD_EC = CE.COD_EC
             LEFT JOIN AFFILIATOR A on CE.COD_AFFILIATOR = A.COD_AFFILIATOR;

    IF EXISTS(SELECT CODE FROM @COD_AF)
        DELETE FROM #Eqps WHERE COD_AFFILIATOR IS NULL OR COD_AFFILIATOR NOT IN (SELECT CODE FROM @COD_AF)

    IF EXISTS(SELECT CODE FROM @COD_EC)
        DELETE FROM #Eqps WHERE COD_EC IS NULL OR COD_EC NOT IN (SELECT CODE FROM @COD_EC)

    IF EXISTS(SELECT CODE FROM @COD_EQP)
        DELETE FROM #Eqps WHERE COD_EQUIP IS NULL OR COD_EQUIP NOT IN (SELECT CODE FROM @COD_EQP)


    SELECT DISTINCT
        eqp.COD_AFFILIATOR                                        [CodAfiliator]
                  , eqp.COD_COMP                                  [CodComp]
                  , eqp.COD_DEPTO_BR                              [CodDeptoBranch]
                  , eqp.COD_EC                                    [CodEc]
                  , eqp.COD_EQUIP                                 [CodEquip]
                  , AB.COD_BRANCH                                 [CodBranch]
                  , eqp.FIREBASE_NAME                             [FirebaseName]
                  , eqp.ACTIVE                                    [Active]
                  , CE.Active                                     [EcActive]
                  , BE.CPF_CNPJ                                   [CpfCnpjBr]
                  , A.CPF_CNPJ                                    [CpfCnpjAff]
                  , CE.CPF_CNPJ                                   [CpfCnpjEc]
                  , BE.TRADING_NAME                               [TradingNameBr]
                  , BE.NAME                                       [BranchName]
                  , IIF(TE.CODE = 'PF', '8999', S.CODE)           [Mcc]
                  , CE.CODE                                       [MerchantCode]
                  , AB.Address
                  , AB.[Number]
                  , AB.Cep
                  , ISNULL(AB.COMPLEMENT, ' ')                   Complement
                  , [dbo].FN_REMOVE_SPECIAL_CHAR(N.NAME) Neighborhood
                  , CITY.NAME                                    City
                  , STATE.UF                                     State
                  , COUNTRY.Initials
                  , CONTACT_BRANCH.Ddi
                  , CONTACT_BRANCH.Ddd
                  , CONTACT_BRANCH.[NUMBER]                      AS TelNumber
                  , TYPE_CONTACT.NAME                            AS TypeContact
                  , CASE
                        WHEN (SELECT COUNT(*) FROM SERVICES_AVAILABLE
                              WHERE COD_ITEM_SERVICE = 4 AND ACTIVE = 1 AND COD_AFFILIATOR = A.COD_AFFILIATOR AND COD_EC IS NULL AND COD_OPT_SERV = 4)
                            > 0 THEN 1
                        WHEN (SELECT COUNT(*) FROM SERVICES_AVAILABLE
                              WHERE COD_ITEM_SERVICE = 4 AND ACTIVE = 1 AND COD_AFFILIATOR = A.COD_AFFILIATOR AND COD_EC IS NULL AND COD_OPT_SERV = 2)
                            > 0 THEN 0
                        WHEN (SELECT COUNT(*) FROM SERVICES_AVAILABLE
                              WHERE COD_ITEM_SERVICE = 4 AND ACTIVE = 1 AND COD_AFFILIATOR = A.COD_AFFILIATOR AND COD_EC = CE.COD_EC)
                            > 0 THEN 1
                        ELSE 0
        END AS [Split]
                  , eqp.Serial
                  , eqp.COD_ASS_DEPTO_TERMINAL [CodAssDeptoTerminal]
    FROM #Eqps eqp
             LEFT JOIN BRANCH_EC BE ON BE.COD_BRANCH = eqp.COD_BRANCH
             LEFT JOIN COMMERCIAL_ESTABLISHMENT CE on eqp.COD_EC = CE.COD_EC
             LEFT JOIN AFFILIATOR A on CE.COD_AFFILIATOR = A.COD_AFFILIATOR
             LEFT JOIN ADDRESS_BRANCH AB ON AB.COD_BRANCH = eqp.COD_BRANCH AND AB.ACTIVE = 1
             LEFT JOIN NEIGHBORHOOD N ON N.COD_NEIGH = AB.COD_NEIGH
             LEFT JOIN CITY ON CITY.COD_CITY = N.COD_CITY
             LEFT JOIN STATE ON STATE.COD_STATE = CITY.COD_STATE
             LEFT JOIN COUNTRY ON COUNTRY.COD_COUNTRY = STATE.COD_COUNTRY
             LEFT JOIN CONTACT_BRANCH ON CONTACT_BRANCH.COD_BRANCH = eqp.COD_BRANCH AND CONTACT_BRANCH.ACTIVE = 1
             LEFT JOIN TYPE_CONTACT ON TYPE_CONTACT.COD_TP_CONT = CONTACT_BRANCH.COD_TP_CONT
             LEFT JOIN TYPE_ESTAB TE ON TE.COD_TYPE_ESTAB = CE.COD_TYPE_ESTAB
             LEFT JOIN SEGMENTS S ON S.COD_SEG = CE.COD_SEG
END
GO

IF OBJECT_ID('SP_RGW_EQUIP_INITIALIZED') IS NOT NULL
    DROP PROCEDURE SP_RGW_EQUIP_INITIALIZED
GO
CREATE PROCEDURE [dbo].[SP_RGW_EQUIP_INITIALIZED]
/*----------------------------------------------------------------------------------------
    Project.......: TKPP
------------------------------------------------------------------------------------------
    Author              VERSION        Date            Description
------------------------------------------------------------------------------------------
    Luiz Aquino			V1			  2020-06-11		Created
------------------------------------------------------------------------------------------*/
(
    @TERMINALID INT
)
AS BEGIN
    UPDATE EQUIPMENT
    SET INITIALIZATION_DATE = GETDATE()
    WHERE COD_EQUIP = @TERMINALID
    IF @@ROWCOUNT < 1
        THROW 60002, '002', 1;
END
GO

IF OBJECT_ID('SP_RGW_DATA_EQP_ACQ') IS NOT NULL
    DROP PROCEDURE SP_RGW_DATA_EQP_ACQ
GO
CREATE PROCEDURE [DBO].[SP_RGW_DATA_EQP_ACQ](@COD_AF CODE_TYPE READONLY, @COD_EC CODE_TYPE READONLY, @COD_EQP CODE_TYPE READONLY)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-11          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    CREATE TABLE #EQPs
    (
        COD_AFFILIATOR INT,
        COD_COMP       INT,
        COD_DEPTO_BR   INT,
        COD_EC         INT,
        COD_EQUIP      INT,
    )

    INSERT INTO #EQPs (COD_AFFILIATOR, COD_COMP, COD_DEPTO_BR, COD_EC, COD_EQUIP)
    SELECT ISNULL(CE.COD_AFFILIATOR, 0) AS COD_AFFILIATOR
         , E.COD_COMP
         , DB.COD_DEPTO_BRANCH          AS COD_DEPTO_BR
         , BE.COD_EC
         , E.COD_EQUIP
    FROM ASS_DEPTO_EQUIP ADE
             JOIN EQUIPMENT E on E.COD_EQUIP = ADE.COD_EQUIP AND E.ACTIVE = 1
             JOIN DEPARTMENTS_BRANCH DB ON DB.COD_DEPTO_BRANCH = ADE.COD_DEPTO_BRANCH
             JOIN BRANCH_EC BE ON BE.COD_BRANCH = DB.COD_BRANCH
             JOIN COMMERCIAL_ESTABLISHMENT CE on BE.COD_EC = CE.COD_EC
    WHERE ADE.ACTIVE = 1
    GROUP BY E.COD_COMP, DB.COD_DEPTO_BRANCH, ISNULL(CE.COD_AFFILIATOR, 0), BE.COD_EC, E.COD_EQUIP;

    IF EXISTS(SELECT CODE FROM @COD_AF)
        DELETE FROM #Eqps WHERE COD_AFFILIATOR IS NULL OR COD_AFFILIATOR NOT IN (SELECT CODE FROM @COD_AF)

    IF EXISTS(SELECT CODE FROM @COD_EC)
        DELETE FROM #Eqps WHERE COD_EC IS NULL OR COD_EC NOT IN (SELECT CODE FROM @COD_EC)

    IF EXISTS(SELECT CODE FROM @COD_EQP)
        DELETE FROM #Eqps WHERE COD_EQUIP IS NULL OR COD_EQUIP NOT IN (SELECT CODE FROM @COD_EQP)

    SELECT dea.Name
         , dea.Code
         , a.[GROUP] AS AcqName
         , dea.COD_EQUIP [CodEquip]
    FROM #EQPs eqp
        JOIN DATA_EQUIPMENT_AC dea ON dea.COD_EQUIP = eqp.COD_EQUIP AND dea.ACTIVE = 1
        JOIN ACQUIRER A on dea.COD_AC = A.COD_AC

END
GO

IF OBJECT_ID('SP_RGW_LIST_EC_PLANS') IS NOT NULL
    DROP PROCEDURE SP_RGW_LIST_EC_PLANS
GO
CREATE PROCEDURE [DBO].[SP_RGW_LIST_EC_PLANS](@COD_EC INT = NULL)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-11          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN
  
    IF @COD_EC IS NULL BEGIN
        SELECT   ATD.COD_ASS_TX_DEP [CodAssTxDep]
             , ATD.Interval
             , CE.COD_EC [CodEc]
             , TT.COD_TTYPE [CodTType]
             , CE.ACTIVE [EcActive]
             , BE.COD_BRANCH [CodBranch]
             , CE.COD_COMP [CodComp]
             , CAST(CE.TRANSACTION_LIMIT AS decimal(22, 2)) [TransactionLimit]
             , CAST(CE.LIMIT_TRANSACTION_DIALY AS decimal(22, 2)) [LimitTransactionDaily]
             , CAST(CE.LIMIT_TRANSACTION_MONTHLY AS decimal(22, 2)) [LimitTransactionMonthly]
             , CE.COD_AFFILIATOR [CodAffiliator]
             , B.GEN_TITLES [GenTitles]
             , TT.NAME [TransactionType]
             , ATD.QTY_INI_PLOTS [QtyIniPlots]
             , ATD.QTY_FINAL_PLOTS [QtyFinalPlots]
             , CAST(ATD.Rate AS decimal(22, 2)) [Rate]
             , CAST(ATD.ANTICIPATION_PERCENTAGE AS decimal(22, 2)) [AnticipationPercentage]
             , CAST(ATD.PARCENTAGE AS decimal(22, 2)) [Percentage]
             , CAST(ATD.EFFECTIVE_PERCENTAGE AS decimal(22, 2)) [EffectivePercentage]
             , B.NAME [BrandName]
             , B.COD_BRAND [CodBrand]
             , ATD.COD_SOURCE_TRAN [CodSourceTran]
        FROM COMMERCIAL_ESTABLISHMENT CE
                 LEFT JOIN BRANCH_EC BE ON CE.COD_EC = BE.COD_EC
                 LEFT JOIN DEPARTMENTS_BRANCH DB ON DB.COD_BRANCH = BE.COD_BRANCH
                 LEFT JOIN ASS_TAX_DEPART ATD ON ATD.COD_DEPTO_BRANCH = DB.COD_DEPTO_BRANCH AND ATD.ACTIVE = 1
                 LEFT JOIN TRANSACTION_TYPE TT ON TT.COD_TTYPE = ATD.COD_TTYPE
                 LEFT JOIN BRAND B ON B.COD_BRAND = ATD.COD_BRAND AND B.COD_TTYPE = TT.COD_TTYPE
        WHERE CE.ACTIVE = 1 
    END ELSE BEGIN
        SELECT   ATD.COD_ASS_TX_DEP [CodAssTxDep]
             , ATD.Interval
             , CE.COD_EC [CodEc]
             , TT.COD_TTYPE [CodTType]
             , CE.ACTIVE [EcActive]
             , BE.COD_BRANCH [CodBranch]
             , CE.COD_COMP [CodComp]
             , CAST(CE.TRANSACTION_LIMIT AS decimal(22, 2)) [TransactionLimit]
             , CAST(CE.LIMIT_TRANSACTION_DIALY AS decimal(22, 2)) [LimitTransactionDaily]
             , CAST(CE.LIMIT_TRANSACTION_MONTHLY AS decimal(22, 2)) [LimitTransactionMonthly]
             , CE.COD_AFFILIATOR [CodAffiliator]
             , B.GEN_TITLES [GenTitles]
             , TT.NAME [TransactionType]
             , ATD.QTY_INI_PLOTS [QtyIniPlots]
             , ATD.QTY_FINAL_PLOTS [QtyFinalPlots]
             , CAST(ATD.Rate AS decimal(22, 2)) [Rate]
             , CAST(ATD.ANTICIPATION_PERCENTAGE AS decimal(22, 2)) [AnticipationPercentage]
             , CAST(ATD.PARCENTAGE AS decimal(22, 2)) [Percentage]
             , CAST(ATD.EFFECTIVE_PERCENTAGE AS decimal(22, 2)) [EffectivePercentage]
             , B.NAME [BrandName]
             , B.COD_BRAND [CodBrand]
             , ATD.COD_SOURCE_TRAN [CodSourceTran]
        FROM COMMERCIAL_ESTABLISHMENT CE
                 LEFT JOIN BRANCH_EC BE ON CE.COD_EC = BE.COD_EC
                 LEFT JOIN DEPARTMENTS_BRANCH DB ON DB.COD_BRANCH = BE.COD_BRANCH
                 LEFT JOIN ASS_TAX_DEPART ATD ON ATD.COD_DEPTO_BRANCH = DB.COD_DEPTO_BRANCH AND ATD.ACTIVE = 1
                 LEFT JOIN TRANSACTION_TYPE TT ON TT.COD_TTYPE = ATD.COD_TTYPE
                 LEFT JOIN BRAND B ON B.COD_BRAND = ATD.COD_BRAND AND B.COD_TTYPE = TT.COD_TTYPE
        WHERE CE.ACTIVE = 1 AND CE.COD_EC = @COD_EC
    END
END
GO

IF OBJECT_ID('RGW_USER') IS NULL BEGIN
    CREATE TABLE RGW_USER
    (
        COD_RGW_USER INT NOT NULL IDENTITY,
        USERNAME VARCHAR(64) NOT NULL,
        PASSWORD VARCHAR(64) NOT NULL,
        CREATE_AT DATETIME NOT NULL DEFAULT (GETDATE()),
        COD_USER INT REFERENCES USERS(COD_USER),
        PROFILE VARCHAR(64),
    )
END
GO

IF OBJECT_ID('SP_RGW_LIST_ASSOCIATION_EQUIP_ID') IS NOT NULL
    DROP PROCEDURE SP_RGW_LIST_ASSOCIATION_EQUIP_ID
GO
CREATE PROCEDURE [DBO].[SP_RGW_LIST_ASSOCIATION_EQUIP_ID](@ASSOCIATION_ID CODE_TYPE READONLY)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-16          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN
   
    SELECT COD_EQUIP [CodEquip], COD_DEPTO_BRANCH [CodDeptoBranch], ACTIVE [Active] FROM ASS_DEPTO_EQUIP WHERE COD_ASS_DEPTO_TERMINAL IN (SELECT CODE FROM @ASSOCIATION_ID)
    
END
GO

IF OBJECT_ID('SP_RGW_LIST_EQP_SERIAL') IS NOT NULL
    DROP PROCEDURE SP_RGW_LIST_EQP_SERIAL
GO
CREATE PROCEDURE [DBO].[SP_RGW_LIST_EQP_SERIAL](@SERIALS TP_STRING_CODE READONLY)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-17          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    SELECT COD_EQUIP [CodEquip], COD_MODEL [CodModel], Active FROM EQUIPMENT WHERE SERIAL IN (SELECT CODE FROM @SERIALS)

END
GO

IF OBJECT_ID('SP_RGW_LIST_EQP_ROUTE') IS NOT NULL
    DROP PROCEDURE SP_RGW_LIST_EQP_ROUTE
GO
CREATE PROCEDURE [DBO].[SP_RGW_LIST_EQP_ROUTE](@ROUTES CODE_TYPE READONLY)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-17          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    SELECT DISTINCT COD_EQUIP [CodEquip], COD_EC [CodEc], Active FROM ROUTE_ACQUIRER WHERE COD_ROUTE IN (SELECT CODE FROM @ROUTES)

END
GO
IF OBJECT_ID('SP_RGW_USERS') IS NOT NULL
    DROP PROCEDURE SP_RGW_USERS
GO
CREATE PROCEDURE [DBO].[SP_RGW_USERS]
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-19          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    SELECT Username, PROFILE [Role], COD_RGW_USER [CodRgwUser], Password FROM RGW_USER

END
GO
IF OBJECT_ID('SP_RGW_REG_USERS') IS NOT NULL
    DROP PROCEDURE SP_RGW_REG_USERS
GO
CREATE PROCEDURE [DBO].[SP_RGW_REG_USERS](@Username VARCHAR(64), @Pwd VARCHAR(64), @User INT, @Profile VARCHAR(64) = NULL)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-19          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    IF EXISTS(SELECT COD_RGW_USER FROM RGW_USER WHERE USERNAME = @Username) BEGIN
        SELECT 'Usuário duplicado' [Message], 0 [CodRgwUser]
        RETURN;
    END
    
    INSERT INTO RGW_USER(USERNAME, PASSWORD, COD_USER, PROFILE) VALUES (@Username, @Pwd, @User, @Profile)
    
    SELECT 'Sucesso'[Message], CAST(@@identity AS INT ) [CodRgwUser]

END
GO

IF OBJECT_ID('SP_RGW_RM_USERS') IS NOT NULL
    DROP PROCEDURE SP_RGW_RM_USERS
GO
CREATE PROCEDURE [DBO].[SP_RGW_RM_USERS](@CodRgwUser INT)
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-19          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    DELETE FROM RGW_USER WHERE COD_RGW_USER = @CodRgwUser

END
GO


IF OBJECT_ID('SP_RGW_UP_USER_PASS') IS NOT NULL
    DROP PROCEDURE SP_RGW_UP_USER_PASS
GO
CREATE PROCEDURE [DBO].[SP_RGW_UP_USER_PASS](@CodRgwUser INT, @PWD VARCHAR(64))
/*----------------------------------------------------------------------------------------   
    Project.......: TKPP   
------------------------------------------------------------------------------------------   
    Author          VERSION           Date             Description   
------------------------------------------------------------------------------------------   
    Luiz Aquino     v1              2020-06-19          CREATED
------------------------------------------------------------------------------------------*/
AS BEGIN

    UPDATE RGW_USER SET PASSWORD = @PWD WHERE COD_RGW_USER = @CodRgwUser

END
GO


--/ET-886


GO

--ET-1033

IF OBJECT_ID('SP_LS_EC_AFFILIATOR') IS NOT NULL
	DROP PROCEDURE SP_LS_EC_AFFILIATOR;
GO
CREATE PROCEDURE [dbo].[SP_LS_EC_AFFILIATOR]
/*----------------------------------------------------------------------------------------    
Procedure Name: [SP_LS_EC_AFFILIATOR]    
Project.......: TKPP    
------------------------------------------------------------------------------------------    
Author VERSION Date Description    
------------------------------------------------------------------------------------------    
Gian Luca Dalle Cort V1 02/08/2018 CREATION    
LUCAS AGUIAR V2 08/04/2019 PEGAR O SERVIÇO CERTO E ADD GROUP BY    
Caike Uchôa V3 31/05/2019 Ajuste no Left join da service_avaliable    
Caike Uchôa V4 23/09/2019 pegar o COD_RISK_SITUATION    
---------------------------------------- --------------------------------------------------*/ (@COD_AFFILIATOR INT,
@HAS_SPOT INT = NULL,
@COD_SALES_REP INT = NULL)
AS
	DECLARE @QUERY_ VARCHAR(MAX)
	BEGIN
		SET @QUERY_ = '    
 SELECT    
 COMMERCIAL_ESTABLISHMENT.COD_EC,    
 COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,    
 COMMERCIAL_ESTABLISHMENT.NAME,    
 COMMERCIAL_ESTABLISHMENT.TRADING_NAME,    
 BRANCH_EC.COD_BRANCH,    
 AFFILIATOR.NAME AS ''AFL_NAME'',    
 AFFILIATOR.COD_AFFILIATOR,    
  ISNULL(SERVICES_AVAILABLE.ACTIVE, 0) AS HAS_SPOT    
 ,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC    
 ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION    
 ,RISK_SITUATION.SITUATION_EC  
  FROM COMMERCIAL_ESTABLISHMENT    
 INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC    
 LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR    
 LEFT JOIN SERVICES_AVAILABLE ON COMMERCIAL_ESTABLISHMENT.COD_EC = SERVICES_AVAILABLE.COD_EC AND SERVICES_AVAILABLE.COD_ITEM_SERVICE = 1 AND SERVICES_AVAILABLE.ACTIVE= 1    
 JOIN RISK_SITUATION ON RISK_SITUATION.COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION  
 WHERE    
 COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = ' + CAST(@COD_AFFILIATOR AS VARCHAR) + '    
 AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1    
 AND BRANCH_EC.TYPE_BRANCH = ''PRINCIPAL''';
		IF @HAS_SPOT IS NOT NULL
			SET @QUERY_ = @QUERY_ + ' AND SERVICES_AVAILABLE.ACTIVE = ' + CAST(@HAS_SPOT AS VARCHAR)
		IF @COD_SALES_REP IS NOT NULL
			SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SALES_REP = ' + CAST(@COD_SALES_REP AS VARCHAR)
		SET @QUERY_ = @QUERY_ + 'GROUP BY COMMERCIAL_ESTABLISHMENT.COD_EC,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,COMMERCIAL_ESTABLISHMENT.NAME,COMMERCIAL_ESTABLISHMENT.TRADING_NAME,    
 BRANCH_EC.COD_BRANCH,AFFILIATOR.NAME,AFFILIATOR.COD_AFFILIATOR,SERVICES_AVAILABLE.ACTIVE,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION, RISK_SITUATION.SITUATION_EC'
		EXEC (@QUERY_);
	END;


	SELECT
		COMMERCIAL_ESTABLISHMENT.COD_EC
	   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
	   ,COMMERCIAL_ESTABLISHMENT.NAME
	   ,COMMERCIAL_ESTABLISHMENT.TRADING_NAME
	   ,BRANCH_EC.COD_BRANCH
	   ,AFFILIATOR.NAME AS 'AFL_NAME'
	   ,AFFILIATOR.COD_AFFILIATOR
	   ,ISNULL(SERVICES_AVAILABLE.ACTIVE, 0) AS HAS_SPOT
	   ,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC
	   ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
	   ,RISK_SITUATION.SITUATION_EC
	FROM COMMERCIAL_ESTABLISHMENT
	INNER JOIN BRANCH_EC
		ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
	LEFT JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	LEFT JOIN SERVICES_AVAILABLE
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = SERVICES_AVAILABLE.COD_EC
			AND SERVICES_AVAILABLE.COD_ITEM_SERVICE = 1
			AND SERVICES_AVAILABLE.ACTIVE = 1
	JOIN RISK_SITUATION
		ON RISK_SITUATION.COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
	WHERE COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = 304
	--AND COMMERCIAL_ESTABLISHMENT.NAME LIKE '%HOTEL DALE%'
	ORDER BY BRANCH_EC.COD_EC


GO


IF OBJECT_ID('SP_LS_EC_COMPANY') IS NOT NULL
	DROP PROCEDURE SP_LS_EC_COMPANY;
GO
CREATE  PROCEDURE [dbo].[SP_LS_EC_COMPANY]
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_LS_EC_COMPANY]      
Project.......: TKPP      
------------------------------------------------------------------------------------------      
Author                          VERSION        Date                            Description      
------------------------------------------------------------------------------------------      
Kennedy Alef     V1    27/07/2018      Creation      
Elir Ribeiro     V2    05/08/2019     Changed Cod Risk Situation    
------------------------------------------------------------------------------------------*/ (@COD_COMP INT,
@Search VARCHAR(100) = NULL,
@CodesAff CODE_TYPE READONLY)
AS
BEGIN

	SELECT
		COMMERCIAL_ESTABLISHMENT.COD_EC
	   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
	   ,COMMERCIAL_ESTABLISHMENT.[NAME]
	   ,COMMERCIAL_ESTABLISHMENT.TRADING_NAME
	   ,BRANCH_EC.COD_BRANCH
	   ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
	   ,COMMERCIAL_ESTABLISHMENT.IS_PROVIDER
	   ,AFFILIATOR.NAME AS [AFF_NAME]
	   ,rs.SITUATION_EC
	FROM COMMERCIAL_ESTABLISHMENT
	INNER JOIN COMPANY
		ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
	INNER JOIN BRANCH_EC
		ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
	LEFT JOIN AFFILIATOR
		ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	INNER JOIN RISK_SITUATION rs
		ON COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION = rs.COD_RISK_SITUATION
	WHERE COMPANY.COD_COMP = 8
	AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1
	AND BRANCH_EC.TYPE_BRANCH = 'PRINCIPAL'
	AND (@Search IS NULL
	OR (COMMERCIAL_ESTABLISHMENT.[NAME] LIKE ('%' + @Search + '%'))
	OR (COMMERCIAL_ESTABLISHMENT.CPF_CNPJ LIKE ('%' + @Search + '%')))
	AND ((SELECT
			COUNT(*)
		FROM @CodesAff)
	= 0
	OR COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR IN (SELECT
			[CODE]
		FROM @CodesAff)
	)
	ORDER BY 1 DESC
END;


GO

ALTER PROCEDURE SP_FD_DATA_EC
/*----------------------------------------------------------------------------------------      
Procedure Name: [SP_FD_DATA_EC]      
------------------------------------------------------------------------------------------      
Author        VERSION     Date      Description      
------------------------------------------------------------------------------------------      
Kennedy Alef  V1        2018-07-27  Creation      
Elir Ribeiro  V2        2018-11-07  Changed      
Lucas Aguiar  V3        2019-04-22  Add split      
Lucas Aguiar  V4        2019-07-01  rotina de travar agenda do ec      
Luiz Aquino   V5        2019-07-03  Is_Cerc      
Elir Ribeiro  V6        2019-10-01  changed Limit transaction monthy      
Caike Uchoa   V7        2019-10-03  add case split pelo afiliador      
Luiz Aquino   V8        2019-10-16  Add retencao de agenda      
Lucas Aguiar  V9        2019-10-28  Conta Cessao      
Marcus Gall   V10       2019-11-11  Add FK with BRANCH BUSINESS      
Marcus Gall   V11       2019-12-06  Add field HAS_CREDENTIALS      
Elir Ribeiro  V12       2020-01-08  trazendo dados meet consumer      
Elir Ribeiro  V13       2020-01-15  ajustando procedure      
Marcus Gall   V14       2020-01-22  Add Translate service      
Luiz Aquino   v15       2020-03-11  (ET-465) Add requested transaction type      
Elir Ribeiro  v16       2020-04-15  add serviço de boleto      
Elir Ribeiro  v17       2020-04-17  add split boleto      
Caike Uchôa   v18       2020-04-22  add Multi EC      
Luiz Aquino   v19       2020-05-18  ET--598 Termo de aceite      
Elir Ribeiro  v20       2020-07-18  ET- 932 Integracao Visa    
------------------------------------------------------------------------------------------*/ (@COD_EC INT)
AS
BEGIN

	DECLARE @CodSpotService INT

	DECLARE @COD_SPLIT_SERVICE INT;

	DECLARE @COD_BLOCK_SITUATION INT;

	DECLARE @COD_CUSTOMERINSTALLMENT INT;

	DECLARE @CodSchRetention INT;

	DECLARE @COD_TRANSLATE_SERVICE INT;
	DECLARE @CodBillet INT;
	DECLARE @CODSPLITBILLET INT;
	DECLARE @COD_MULTIEC_SERVICE INT;

	SELECT
		@CodSpotService = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE CODE = '1';

	SELECT
		@COD_SPLIT_SERVICE = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE [NAME] = 'SPLIT';

	SELECT
		@CodBillet = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE [NAME] = 'BOLETO'
	AND ACTIVE = 1;

	SELECT
		@CODSPLITBILLET = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE [NAME] = 'SPLIT BOLETO ONLINE'
	AND ACTIVE = 1;

	SELECT
		@COD_BLOCK_SITUATION = COD_SITUATION
	FROM SITUATION
	WHERE [NAME] = 'LOCKED FINANCIAL SCHEDULE';

	SELECT
		@COD_CUSTOMERINSTALLMENT = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE NAME = 'PARCELADOCLIENTE';

	SELECT
		@CodSchRetention = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE [NAME] = 'SCHEDULEDRETENTION';

	SELECT
		@COD_TRANSLATE_SERVICE = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE [NAME] = 'TRANSLATE';

	SELECT
		@COD_MULTIEC_SERVICE = COD_ITEM_SERVICE
	FROM ITEMS_SERVICES_AVAILABLE
	WHERE [NAME] = 'MULTI EC';

	SELECT
		BRANCH_EC.[NAME]
	   ,BRANCH_EC.TRADING_NAME
	   ,COMMERCIAL_ESTABLISHMENT.CODE AS CODE_EC
	   ,BRANCH_EC.CPF_CNPJ
	   ,BRANCH_EC.DOCUMENT
	   ,BRANCH_EC.BIRTHDATE
	   ,COMMERCIAL_ESTABLISHMENT.TRANSACTION_LIMIT
	   ,COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_DIALY
	   ,COMMERCIAL_ESTABLISHMENT.LIMIT_TRANSACTION_MONTHLY
	   ,BRANCH_EC.EMAIL
	   ,BRANCH_EC.STATE_REGISTRATION
	   ,BRANCH_EC.MUNICIPAL_REGISTRATION
	   ,BRANCH_EC.NOTE AS NOTE
	   ,TYPE_ESTAB.CODE AS TYPE_ESTAB_CODE
	   ,SEGMENTS.COD_SEG AS SEGMENT
	   ,BRANCH_EC.ACTIVE
	   ,ADDRESS_BRANCH.[ADDRESS]
	   ,ADDRESS_BRANCH.NUMBER AS NUMBER_ADDRESS
	   ,ADDRESS_BRANCH.COMPLEMENT
	   ,ADDRESS_BRANCH.CEP
	   ,ADDRESS_BRANCH.REFERENCE_POINT
	   ,NEIGHBORHOOD.COD_NEIGH
	   ,NEIGHBORHOOD.[NAME] AS NEIGHBORHOOD
	   ,CITY.COD_CITY
	   ,CITY.[NAME] AS CITY
	   ,[STATE].COD_STATE
	   ,[STATE].[NAME] AS [STATE]
	   ,COUNTRY.COD_COUNTRY
	   ,COUNTRY.[NAME] AS COUNTRY
	   ,BANKS.COD_BANK AS BANK_INSIDECODE
	   ,BANKS.[NAME] AS BANK
	   ,BANK_DETAILS_EC.DIGIT_AGENCY
	   ,BANK_DETAILS_EC.AGENCY
	   ,BANK_DETAILS_EC.DIGIT_ACCOUNT
	   ,BANK_DETAILS_EC.ACCOUNT
	   ,ACCOUNT_TYPE.COD_TYPE_ACCOUNT AS ACCOUNT_TYPE_INSIDECODE
	   ,ACCOUNT_TYPE.[NAME] AS ACCOUNT_TYPE
	   ,SALES_REPRESENTATIVE.COD_SALES_REP
	   ,COMMERCIAL_ESTABLISHMENT.SEC_FACTOR_AUTH_ACTIVE
	   ,BRANCH_EC.COD_SEX
	   ,BRANCH_EC.COD_BRANCH AS COD_BRANCH
	   ,BANK_DETAILS_EC.AGENCY AS AGENCY
	   ,BANK_DETAILS_EC.DIGIT_AGENCY AS AGENCY_DIGIT
	   ,BANK_DETAILS_EC.ACCOUNT AS ACCOUNT
	   ,BANK_DETAILS_EC.DIGIT_ACCOUNT AS DIGIT_ACCOUNT
	   ,BANK_DETAILS_EC.COD_OPER_BANK
	   ,TYPE_RECEIPT.COD_TYPE_REC
	   ,TYPE_RECEIPT.CODE AS TYPE_RECEIPT
	   ,CARDS_TOBRANCH.CARDNUMBER
	   ,CARDS_TOBRANCH.ACCOUNTID AS 'ACCOUNTID'
	   ,CARDS_TOBRANCH.COD_CARD_BRANCH AS 'COD_CARD_BRANCH'
	   ,COMMERCIAL_ESTABLISHMENT.TRANSACTION_ONLINE AS 'TRANSACTION_ONLINE'
	   ,COMMERCIAL_ESTABLISHMENT.SPOT_TAX
	   ,COMMERCIAL_ESTABLISHMENT.BILLET_TAX
		--  , COMMERCIAL_ESTABLISHMENT.BILLET_DEAD      
	   ,CASE
			WHEN COMMERCIAL_ESTABLISHMENT.COD_SITUATION = @COD_BLOCK_SITUATION THEN 1
			ELSE 0
		END [FINANCE_BLOCK]
	   ,COMMERCIAL_ESTABLISHMENT.NOTE_FINANCE_SCHEDULE
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodSpotService
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_SPOT]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodBillet
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_BILLET]

	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CODSPLITBILLET
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_SPLIT_BILLET]

	   ,COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_SPLIT_SERVICE
					AND SERVICES_AVAILABLE.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
					AND SERVICES_AVAILABLE.ACTIVE = 1
					AND SERVICES_AVAILABLE.COD_OPT_SERV = 4
					AND SERVICES_AVAILABLE.COD_EC IS NULL)
				> 0 THEN 1
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_SPLIT_SERVICE
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_SPLIT]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_CUSTOMERINSTALLMENT
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_CUSTOMERINSTALLMENT]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @CodSchRetention
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_SCHRETENTION]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_MULTIEC_SERVICE
					AND SERVICES_AVAILABLE.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_MULTI_EC]

	   ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
	   ,COMMERCIAL_ESTABLISHMENT.RISK_REASON
	   ,COMMERCIAL_ESTABLISHMENT.IS_PROVIDER
	   ,BANK_DETAILS_EC.IS_ASSIGNMENT
	   ,BANK_DETAILS_EC.ASSIGNMENT_NAME
	   ,BANK_DETAILS_EC.ASSIGNMENT_IDENTIFICATION
	   ,BRANCH_BUSINESS.COD_BRANCH_BUSINESS AS BRANCH_BUSINESS
	   ,COMMERCIAL_ESTABLISHMENT.HAS_CREDENTIALS
	   ,MEET_COSTUMER.CNPJ [ACCEPTANCE]
	   ,ISNULL(MEET_COSTUMER.QTY_EMPLOYEES, 0) QTY_EMPLOYEES
	   ,ISNULL(MEET_COSTUMER.AVERAGE_BILLING, 0) AVERAGE_BILLING
	   ,MEET_COSTUMER.URL_SITE
	   ,MEET_COSTUMER.FACEBOOK
	   ,MEET_COSTUMER.INSTAGRAM
	   ,MEET_COSTUMER.STREET
	   ,MEET_COSTUMER.COMPLEMENT [COMPLEMENTO]
	   ,MEET_COSTUMER.ANOTHER_INFO
	   ,MEET_COSTUMER.NUMBER
	   ,MEET_COSTUMER.NEIGHBORHOOD AS MEET_NEIGH
	   ,MEET_COSTUMER.CITY AS MEET_CITY
	   ,MEET_COSTUMER.STATES
	   ,MEET_COSTUMER.REFERENCEPOINT
	   ,MEET_COSTUMER.ZIPCODE
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM SERVICES_AVAILABLE
					WHERE SERVICES_AVAILABLE.COD_ITEM_SERVICE = @COD_TRANSLATE_SERVICE
					AND SERVICES_AVAILABLE.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
					AND SERVICES_AVAILABLE.ACTIVE = 1)
				> 0 THEN 1
			ELSE 0
		END [HAS_TRANSLATE]
	   ,IIF(COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION = 2, 1, 0) AS [REQUESTED_PRESENTIAL_TRANSACTION]
	   ,IIF(COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION = 2, 1, 0) AS [REQUESTED_ONLINE_TRANSACTION]
	   ,COMMERCIAL_ESTABLISHMENT.TCU_ACCEPTED
	   ,REQ_LANGUAGE_COMERCIAL.COD_COUNTRY
	   ,REQ_LANGUAGE_COMERCIAL.COD_CURRRENCY
	   ,REQ_LANGUAGE_COMERCIAL.COD_LANGUAGE
	   ,rs.SITUATION_EC
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
	INNER JOIN [STATE]
		ON [STATE].COD_STATE = CITY.COD_STATE
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
	LEFT JOIN REQ_LANGUAGE_COMERCIAL
		ON REQ_LANGUAGE_COMERCIAL.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC
			AND REQ_LANGUAGE_COMERCIAL.ACTIVE = 1
	INNER JOIN RISK_SITUATION rs
		ON COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION = rs.COD_RISK_SITUATION
	WHERE COMMERCIAL_ESTABLISHMENT.COD_EC = @COD_EC
	AND (CARDS_TOBRANCH.COD_SITUATION = 15
	OR CARDS_TOBRANCH.COD_SITUATION IS NULL)


END;

GO

IF OBJECT_ID('SP_LS_EC_AFFILIATOR') IS NOT NULL
	DROP PROCEDURE SP_LS_EC_AFFILIATOR;
GO
CREATE PROCEDURE [dbo].[SP_LS_EC_AFFILIATOR]
/*----------------------------------------------------------------------------------------  
Procedure Name: [SP_LS_EC_AFFILIATOR]  
Project.......: TKPP  
------------------------------------------------------------------------------------------  
Author VERSION Date Description  
------------------------------------------------------------------------------------------  
Gian Luca Dalle Cort V1 02/08/2018 CREATION  
LUCAS AGUIAR V2 08/04/2019 PEGAR O SERVIÇO CERTO E ADD GROUP BY  
Caike Uchôa V3 31/05/2019 Ajuste no Left join da service_avaliable  
Caike Uchôa V4 23/09/2019 pegar o COD_RISK_SITUATION  
---------------------------------------- --------------------------------------------------*/ (@COD_AFFILIATOR INT,
@HAS_SPOT INT = NULL,
@COD_SALES_REP INT = NULL)
AS
	DECLARE @QUERY_ VARCHAR(MAX)
	BEGIN
		SET @QUERY_ = '  
 SELECT  
 COMMERCIAL_ESTABLISHMENT.COD_EC,  
 COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,  
 COMMERCIAL_ESTABLISHMENT.NAME,  
 COMMERCIAL_ESTABLISHMENT.TRADING_NAME,  
 BRANCH_EC.COD_BRANCH,  
 AFFILIATOR.NAME AS ''AFL_NAME'',  
 AFFILIATOR.COD_AFFILIATOR,  
  ISNULL(SERVICES_AVAILABLE.ACTIVE, 0) AS HAS_SPOT  
 ,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC  
 ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION  
 ,RISK_SITUATION.SITUATION_EC
  FROM COMMERCIAL_ESTABLISHMENT  
 INNER JOIN BRANCH_EC ON BRANCH_EC.COD_EC = COMMERCIAL_ESTABLISHMENT.COD_EC  
 LEFT JOIN AFFILIATOR ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR  
 LEFT JOIN SERVICES_AVAILABLE ON COMMERCIAL_ESTABLISHMENT.COD_EC = SERVICES_AVAILABLE.COD_EC AND SERVICES_AVAILABLE.COD_ITEM_SERVICE = 1 AND SERVICES_AVAILABLE.ACTIVE= 1  
 JOIN RISK_SITUATION ON RISK_SITUATION.COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
 WHERE  
 COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR = ' + CAST(@COD_AFFILIATOR AS VARCHAR) + '  
 AND COMMERCIAL_ESTABLISHMENT.ACTIVE = 1  
 AND BRANCH_EC.TYPE_BRANCH = ''PRINCIPAL''';
		IF @HAS_SPOT IS NOT NULL
			SET @QUERY_ = @QUERY_ + ' AND SERVICES_AVAILABLE.ACTIVE = ' + CAST(@HAS_SPOT AS VARCHAR)
		IF @COD_SALES_REP IS NOT NULL
			SET @QUERY_ = @QUERY_ + ' AND COMMERCIAL_ESTABLISHMENT.COD_SALES_REP = ' + CAST(@COD_SALES_REP AS VARCHAR)
		SET @QUERY_ = @QUERY_ + 'GROUP BY COMMERCIAL_ESTABLISHMENT.COD_EC,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ,COMMERCIAL_ESTABLISHMENT.NAME,COMMERCIAL_ESTABLISHMENT.TRADING_NAME,  
 BRANCH_EC.COD_BRANCH,AFFILIATOR.NAME,AFFILIATOR.COD_AFFILIATOR,SERVICES_AVAILABLE.ACTIVE,COMMERCIAL_ESTABLISHMENT.DEFAULT_EC,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION, RISK_SITUATION.SITUATION_EC'
		EXEC (@QUERY_);
	END;

GO

IF OBJECT_ID('SP_VALIDATE_TRANSACTION') IS NOT NULL
	DROP PROCEDURE SP_VALIDATE_TRANSACTION;
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION]

/***********************************************************************************************************************************************************************      
------------------------------------------------------------------------------------------------------------------------------------------------                            
Procedure Name: [SP_VALIDATE_TRANSACTION]                            
Project.......: TKPP                            
--------------------------------------------------------------------------------------------------------------------------------------------------                            
Author                          VERSION        Date                            Description                            
--------------------------------------------------------------------------------------------------------------------------------------------------                            
Kennedy Alef     V1   27/07/2018       Creation                            
Gian Luca Dalle Cort   V1   14/08/2018        Changed            
Lucas Aguiar     v3   17-04-2019    Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções              
Lucas Aguiar     v4   23-04-2019    Parametro opc cod ec        
Kennedy Alef  v5   12-11-2019    Card holder name, doc holder, logical number                         
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
											,@HOLDER_NAME = @HOLDER_NAME
											,@HOLDER_DOC = @HOLDER_DOC
											,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
			THROW 60002, '402', 1;

		END;

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
			WHERE [PLAN_TAX_AFFILIATOR].[COD_AFFILIATOR] = @COD_AFFILIATOR
			AND @QTY_PLOTS BETWEEN [QTY_INI_PLOTS] AND [QTY_FINAL_PLOTS]
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

		EXEC [SP_VAL_LIMIT_EC] @CODEC
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
							  ,@HOLDER_NAME = @HOLDER_NAME
							  ,@HOLDER_DOC = @HOLDER_DOC
							  ,@LOGICAL_NUMBER = @LOGICAL_NUMBER
							  ,@SOURCE_TRAN = 2;



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
		--	EXEC [SP_REG_TRANSACTION_DENIED] @AMOUNT = @AMOUNT
		--									,@PAN = @PAN
		--									,@BRAND = @BRAND
		--									,@CODASS_DEPTO_TERMINAL = @CODASS
		--									,@COD_TTYPE = @TYPETRAN
		--									,@PLOTS = @QTY_PLOTS
		--									,@CODTAX_ASS = @CODTX
		--									,@CODAC = NULL
		--									,@CODETR = @TRCODE
		--									,@COMMENT = '020 - PENDING RISK RELEASE ESTABLISHMENT'
		--									,@TERMINALDATE = @TERMINALDATE
		--									,@TYPE = @TYPE
		--									,@COD_COMP = @COD_COMP
		--									,@COD_AFFILIATOR = @COD_AFFILIATOR
		--									,@SOURCE_TRAN = 2
		--									,@CODE_SPLIT = @CODE_SPLIT
		--									,@COD_EC = @EC_TRANS
		--									,@HOLDER_NAME = @HOLDER_NAME
		--									,@HOLDER_DOC = @HOLDER_DOC
		--									,@LOGICAL_NUMBER = @LOGICAL_NUMBER;
		--	THROW 60002, '020', 1;

		--END


		IF @COD_TRAN_PROD IS NOT NULL
		BEGIN

			EXEC [SP_VAL_SPLIT_MULT_EC] @COD_TRAN_PROD = @COD_TRAN_PROD
									   ,@COD_EC = @EC_TRANS
									   ,@QTY_PLOTS = @QTY_PLOTS
									   ,@BRAND = @BRAND
									   ,@COD_ERROR = @COD_ERROR OUTPUT
									   ,@ERROR_DESCRIPTION = @ERROR_DESCRIPTION OUTPUT;

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

GO
IF OBJECT_ID('SP_VALIDATE_TRANSACTION_ON') IS NOT NULL
	DROP PROCEDURE [SP_VALIDATE_TRANSACTION_ON]
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TRANSACTION_ON]
/*------------------------------------------------------------------------------------------------------------------------------------------                                                
Procedure Name: [SP_VALIDATE_TRANSACTION]                                                
Project.......: TKPP                                                
------------------------------------------------------------------------------------------------------------------------------------------------                                                
Author                          VERSION        Date                            Description                                                
-------------------------------------------------------------------------------------------------------------------------------------------------                                                
Kennedy Alef     V1   20/08/2018    Creation                                                
Lucas Aguiar     v2   17-04-2019    Passar parâmetro opcional (CODE_SPLIT) e fazer suas respectivas inserções                                    
Lucas Aguiar     v4   23-04-2019    Parametro opc cod ec                                   
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
	DECLARE @COD_RISK_SITUATION INT;




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
		   ,@COD_RISK_SITUATION = COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
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
											,@COMMENT = '402 - TRANSACTION ONLINE NOT ENABLE'
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
			, '402'
			, 1;
		END;

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
											,@COMMENT = '402 - Transaction limit value exceeded'
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
			, '402'
			, 1;
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
							,@HOLDER_NAME = @HOLDER_NAME
							,@HOLDER_DOC = @HOLDER_DOC
							,@LOGICAL_NUMBER = @LOGICAL_NUMBER
							,@SOURCE_TRAN = 1
							,@CUSTOMER_EMAIL = @CUSTOMER_EMAIL
							,@LINK_MODE = @LINK_MODE
							,@CUSTOMER_IDENTIFICATION = @CUSTOMER_IDENTIFICATION;


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

IF OBJECT_ID('VW_COMPANY_EC_BR_DEP') IS NOT NULL
	DROP VIEW VW_COMPANY_EC_BR_DEP
GO
CREATE VIEW [dbo].[VW_COMPANY_EC_BR_DEP]
AS
SELECT
	ISNULL(AFFILIATOR.[NAME], COMPANY.NAME) AS COMPANY
   ,COMPANY.COD_COMP AS COD_COMP
   ,COMPANY.FIREBASE_NAME AS FIREBASE_NAME
   ,COMMERCIAL_ESTABLISHMENT.NAME AS EC
   ,COMMERCIAL_ESTABLISHMENT.COD_EC
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS CPF_CNPJ_EC
   ,COMMERCIAL_ESTABLISHMENT.ACTIVE AS SITUATION_EC
   ,BRANCH_EC.NAME AS BRANCH_NAME
   ,BRANCH_EC.TRADING_NAME AS TRADING_NAME_BR
   ,BRANCH_EC.COD_BRANCH
   ,BRANCH_EC.CPF_CNPJ AS CPF_CNPJ_BR
   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH AS COD_DEPTO_BR
   ,DEPARTMENTS.NAME AS DEPARTMENT
   ,SEGMENTS.NAME AS SEGMENTS
   ,RIGHT('0' + CAST(SEGMENTS.CODE AS VARCHAR(4)), 4) AS MCC
   ,AFFILIATOR.COD_AFFILIATOR AS COD_AFFILIATOR
   ,AFFILIATOR.CPF_CNPJ AS DOC_AFFILIATOR
   ,COMMERCIAL_ESTABLISHMENT.CODE AS MERCHANT_CODE
   ,COMMERCIAL_ESTABLISHMENT.COD_RISK_SITUATION
FROM BRANCH_EC
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
INNER JOIN COMPANY
	ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
INNER JOIN DEPARTMENTS_BRANCH
	ON DEPARTMENTS_BRANCH.COD_BRANCH = BRANCH_EC.COD_BRANCH
INNER JOIN DEPARTMENTS
	ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
LEFT JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR

GO


IF OBJECT_ID('SP_VALIDATE_TERMINAL') IS NOT NULL
	DROP PROCEDURE SP_VALIDATE_TERMINAL
GO
CREATE PROCEDURE [dbo].[SP_VALIDATE_TERMINAL]
/*----------------------------------------------------------------------------------------     
Procedure Name: [SP_VALIDATE_TERMINAL]     
Project.......: TKPP     
------------------------------------------------------------------------------------------     
Author VERSION Date Description     
------------------------------------------------------------------------------------------     
Kennedy Alef V1 27/07/2018 Creation     
------------------------------------------------------------------------------------------*/ (@TERMINALID INT,
@COD_BRANCH INT,
@SERVICE INT = NULL)
AS
	DECLARE @TERMINALACTVE INT;
	DECLARE @DEPTO INT;
	DECLARE @ECACTIVE INT;
	DECLARE @BRANCH INT;
	DECLARE @COD_EC INT;
	DECLARE @DOC_EC_SOURCE VARCHAR(100);
	DECLARE @DOC_AFF_SOURCE VARCHAR(100);
	DECLARE @COD_EC_SOURCE INT;
	DECLARE @COD_RISK_SITUATION INT;

	BEGIN
		SELECT
			@TERMINALACTVE = EQUIPMENT.ACTIVE
		   ,@DEPTO = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
		   ,@ECACTIVE = VW_COMPANY_EC_BR_DEP.SITUATION_EC
		   ,@BRANCH = VW_COMPANY_EC_BR_DEP.COD_BRANCH
		   ,@DOC_EC_SOURCE = VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC
		   ,@DOC_AFF_SOURCE = VW_COMPANY_EC_BR_DEP.DOC_AFFILIATOR
		   ,@COD_EC_SOURCE = VW_COMPANY_EC_BR_DEP.MERCHANT_CODE
		   ,@COD_EC = VW_COMPANY_EC_BR_DEP.COD_EC
		   ,@COD_RISK_SITUATION = VW_COMPANY_EC_BR_DEP.COD_RISK_SITUATION
		FROM EQUIPMENT
		LEFT JOIN ASS_DEPTO_EQUIP
			ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
		LEFT JOIN VW_COMPANY_EC_BR_DEP
			ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR

		WHERE EQUIPMENT.COD_EQUIP = @TERMINALID

		IF @TERMINALACTVE IS NULL
			THROW 60002, '006', 1;

		IF @TERMINALACTVE = 0
			THROW 60002, '003', 1;

		IF @DEPTO IS NULL
			THROW 60002, '008', 1;
		IF @COD_RISK_SITUATION <> 2
			THROW 60002, '009', 1;
		--IF @COD_RISK_SITUATION <> 2
		--	THROW 60002, '020', 1;			
		IF @BRANCH != @COD_BRANCH
			THROW 60002, '010', 1;

		SELECT
			@DOC_EC_SOURCE AS DOC_MERCHANT
		   ,@COD_EC AS MERCHANT
		   ,@DOC_AFF_SOURCE AS DOC_AFFILIATOR
		   ,@COD_EC_SOURCE AS MID
	END;
	
	
	
GO



IF OBJECT_ID('VW_COMPANY_EC_BR_DEP_EQUIP_MODEL') IS NOT NULL
	DROP VIEW VW_COMPANY_EC_BR_DEP_EQUIP_MODEL
GO
CREATE VIEW [dbo].[VW_COMPANY_EC_BR_DEP_EQUIP_MODEL]
AS
SELECT
	ISNULL(ASS_DEPTO_EQUIP.DEFAULT_EQUIP, 0) AS DEFAULT_EQUIP
   ,VW_COMPANY_EC_BR_DEP.COMPANY
   ,VW_COMPANY_EC_BR_DEP.COD_COMP
   ,VW_COMPANY_EC_BR_DEP.FIREBASE_NAME
   ,VW_COMPANY_EC_BR_DEP.EC
   ,VW_COMPANY_EC_BR_DEP.COD_EC
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC
   ,VW_COMPANY_EC_BR_DEP.SITUATION_EC
   ,VW_COMPANY_EC_BR_DEP.BRANCH_NAME
   ,VW_COMPANY_EC_BR_DEP.TRADING_NAME_BR
   ,VW_COMPANY_EC_BR_DEP.COD_BRANCH
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_BR
   ,VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
   ,VW_COMPANY_EC_BR_DEP.DEPARTMENT
   ,VW_COMPANY_EC_BR_DEP.SEGMENTS
   ,VW_COMPANY_EC_BR_DEP.MCC
   ,VW_COMPANY_EC_BR_DEP.COD_AFFILIATOR
   ,VW_COMPANY_EC_BR_DEP.DOC_AFFILIATOR
   ,VW_COMPANY_EC_BR_DEP.MERCHANT_CODE
   ,VW_COMPANY_EC_BR_DEP.COD_RISK_SITUATION
   ,ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL
   ,EQUIPMENT.COD_EQUIP
   ,EQUIPMENT.SERIAL
   ,EQUIPMENT_MODEL.CODIGO AS MODEL
   ,MODEL_GROUP.CODE AS MODEL_GROUP
   ,EQUIPMENT.TID
   ,CELL_OPERATOR.NAME AS OPERATOR
   ,EQUIPMENT.PUK
   ,EQUIPMENT.CHIP
FROM VW_COMPANY_EC_BR_DEP
INNER JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
INNER JOIN EQUIPMENT
	ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
INNER JOIN EQUIPMENT_MODEL
	ON EQUIPMENT_MODEL.COD_MODEL = EQUIPMENT.COD_MODEL
INNER JOIN MODEL_GROUP
	ON MODEL_GROUP.COD_MODEL_GROUP = EQUIPMENT_MODEL.COD_MODEL_GROUP
LEFT JOIN CELL_OPERATOR
	ON CELL_OPERATOR.COD_OPER = EQUIPMENT.COD_OPER
WHERE ASS_DEPTO_EQUIP.ACTIVE = 1   
  
--/ET-1033

GO

--ET-887

GO
IF NOT EXISTS (SELECT
		1
	FROM sys.columns
	WHERE NAME = N'SHORT_URL_TCU'
	AND object_id = OBJECT_ID(N'COMMERCIAL_ESTABLISHMENT'))
BEGIN
ALTER TABLE COMMERCIAL_ESTABLISHMENT 
ADD SHORT_URL_TCU VARCHAR(200)
END

GO 

IF OBJECT_ID('SP_REG_SHORT_URL') IS NOT NULL
DROP PROCEDURE [SP_REG_SHORT_URL];

GO
CREATE PROCEDURE [SP_REG_SHORT_URL]
/*----------------------------------------------------------------------------------------              
Procedure Name: [SP_REG_SHORT_URL]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION        Date                            Description              
------------------------------------------------------------------------------------------              
Caike Uchoa                       V1         09/09/2020                          Creation             
------------------------------------------------------------------------------------------*/     
(
@SHORT_URL VARCHAR(200),
@COD_EC INT
)
AS
BEGIN 

UPDATE COMMERCIAL_ESTABLISHMENT SET SHORT_URL_TCU = @SHORT_URL WHERE COD_EC = @COD_EC

END

  
  GO

IF OBJECT_ID('SP_GET_SHORT_URL') IS NOT NULL 
DROP PROCEDURE [SP_GET_SHORT_URL];

GO
CREATE PROCEDURE SP_GET_SHORT_URL
/*----------------------------------------------------------------------------------------              
Procedure Name: [SP_GET_SHORT_URL]              
Project.......: TKPP              
------------------------------------------------------------------------------------------              
Author                          VERSION        Date                            Description              
------------------------------------------------------------------------------------------              
Caike Uchoa                       V1         08/09/2020                          Creation             
------------------------------------------------------------------------------------------*/     
(
@CODE_TERM VARCHAR(100)
)
AS
BEGIN 


SELECT 
COMMERCIAL_ESTABLISHMENT.SHORT_URL_TCU
FROM TERM_TOKEN
JOIN USERS ON USERS.COD_USER = TERM_TOKEN.COD_USER
JOIN COMMERCIAL_ESTABLISHMENT ON COMMERCIAL_ESTABLISHMENT.COD_EC = USERS.COD_EC
WHERE TERM_TOKEN.CODE = @CODE_TERM


END

GO

-- /ET-887

go


--ST-1308 / ST-1317

GO

IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'COD_EC_PROD'
		AND object_id = OBJECT_ID(N'REPORT_CONSOLIDATED_TRANS_SUB'))
BEGIN

	ALTER TABLE REPORT_CONSOLIDATED_TRANS_SUB
	ADD COD_EC_PROD INT

END

GO

IF OBJECT_ID('VW_REPORT_FULL_CASH_FLOW') IS NOT NULL
	DROP VIEW [VW_REPORT_FULL_CASH_FLOW];

GO

CREATE VIEW [dbo].[VW_REPORT_FULL_CASH_FLOW]
/*----------------------------------------------------------------------------------------                                                
View Name: [VW_REPORT_FULL_CASH_FLOW]                                                
Project.......: TKPP                                                
----------------------------------------------------------------------------------------                                                
Author                          VERSION        Date                        Description                                                
---------------------------------------------------------------------------------------                                                 
Caike Uch?a                       V1         30/03/2020            mdr afiliador-pela parcela                                 
Caike Uch?a                       V2         30/04/2020               add colunas produto ec                          
Caike Uch?a                       V3         03/08/2020                   add QTY_DAYS_ANTECIP                        
Caike Uch?a                       V4         20/08/2020                Corre??o val liquid afiliador   
Luiz Aquino                       v5         01/09/2020                    Plan DZero
Caike Uchoa                       v6         01/09/2020                   Add cod_ec_prod
Caike Uchoa                       V7         04/09/2020               Add correção qtd_days quando spot
---------------------------------------------------------------------------------------*/
AS
WITH CTE
AS
(SELECT --TOP(1000)                                                             
		TRANSACTION_TITLES.TAX_INITIAL
	   ,TRANSACTION_TITLES.ANTICIP_PERCENT AS ANTECIP_EC
	   ,COALESCE(AFFILIATOR.[NAME], 'CELER') AS AFFILIATOR
	   ,[TRANSACTION_TYPE].CODE AS TRAN_TYPE
	   ,TRANSACTION_TITLES.PLOT
	   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].CREATED_AT) AS DATETIME) AS TRANSACTION_DATE
	   ,COMMERCIAL_ESTABLISHMENT.[NAME] AS MERSHANT
	   ,[TRANSACTION_TITLES].ACQ_TAX
	   ,[TRANSACTION_TITLES].PREVISION_PAY_DATE
	   ,[TRANSACTION_TITLES].PREVISION_RECEIVE_DATE
	   ,[TRANSACTION_TITLES].AMOUNT
	   ,[TRANSACTION].AMOUNT AS TRANSACTION_AMOUNT
	   ,[TRANSACTION].CODE AS NSU
	   ,[TRANSACTION].BRAND AS BRAND
	   ,ACQUIRER.[NAME] AS ACQUIRER
	   ,(CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END) AS RATE
	   ,dbo.FNC_CALC_LIQUID(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.ACQ_TAX) AS LIQUID_SUB
	   ,COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, 0) AS ANTECIP_AFF
	   ,COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], 0) AS MDR_AFF
	   ,(CASE
			WHEN (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				> 0 THEN dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.TAX_INITIAL, TRANSACTION_TITLES.ANTICIP_PERCENT, (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, [TRANSACTION].COD_TTYPE)
			ELSE dbo.[FNC_ANT_VALUE_LIQ_DAYS](
				TRANSACTION_TITLES.AMOUNT,
				TRANSACTION_TITLES.TAX_INITIAL,
				TRANSACTION_TITLES.PLOT,
				TRANSACTION_TITLES.ANTICIP_PERCENT,
				(CASE
					WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

					ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
				END))
		END) AS EC
	   ,0 AS '0'
	   ,(CASE
			WHEN (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				> 0 THEN dbo.FNC_CALC_DZERO_NET_VALUE_CONSOLIDATED(TRANSACTION_TITLES.AMOUNT, TRANSACTION_TITLES.PLOT, TRANSACTION_TITLES.TAX_INITIAL, TRANSACTION_TITLES.ANTICIP_PERCENT, (SELECT

						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, [TRANSACTION].COD_TTYPE)
			ELSE (dbo.[FNC_ANT_VALUE_LIQ_DAYS](
				TRANSACTION_TITLES.AMOUNT,
				TRANSACTION_TITLES.TAX_INITIAL,
				TRANSACTION_TITLES.PLOT,
				TRANSACTION_TITLES.ANTICIP_PERCENT,
				(CASE
					WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
					ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
				END)
				) - (CASE
					WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
					ELSE 0
				END))
		END) AS EC_TARIFF
	   ,[TRANSACTION].PLOTS AS TOTAL_PLOTS
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)) AS AFF_DISCOUNT
	   ,dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL),
		TRANSACTION_TITLES.PLOT,
		COALESCE([TRANSACTION_TITLES_COST].ANTICIP_PERCENT,
		TRANSACTION_TITLES.ANTICIP_PERCENT)
		, (CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END
		)) AS AFF_DISCOUNT_TARIFF
	   ,(
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		(
		TRANSACTION_TITLES.AMOUNT,
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE],
		TRANSACTION_TITLES.TAX_INITIAL) +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		TRANSACTION_TITLES.PLOT,
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		)
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		TRANSACTION_TITLES.AMOUNT,
		TRANSACTION_TITLES.TAX_INITIAL + (CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT + (CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END))
		) AS AFF
	   ,((
		dbo.[FNC_ANT_VALUE_LIQ_DAYS]
		((TRANSACTION_TITLES.AMOUNT),
		COALESCE([TRANSACTION_TITLES_COST].[PERCENTAGE], TRANSACTION_TITLES.TAX_INITIAL)
		+
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		TRANSACTION_TITLES.PLOT,
		COALESCE(
		[TRANSACTION_TITLES_COST].ANTICIP_PERCENT, TRANSACTION_TITLES.ANTICIP_PERCENT)
		+
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END
		))
		-
		dbo.[FNC_ANT_VALUE_LIQ_DAYS](
		(TRANSACTION_TITLES.AMOUNT),
		TRANSACTION_TITLES.TAX_INITIAL
		+ (CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		TRANSACTION_TITLES.PLOT,
		TRANSACTION_TITLES.ANTICIP_PERCENT
		+ (CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = TRANSACTION_TITLES.COD_EC)
				, 0)
			ELSE 0
		END)
		,
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END))
		)
		+ (CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN TRANSACTION_TITLES.RATE
			ELSE 0
		END)
		-
		(CASE
			WHEN TRANSACTION_TITLES.PLOT = 1 THEN ISNULL([TRANSACTION_TITLES_COST].RATE_PLAN, 0)
			ELSE 0
		END)
		)
		AS AFF_TARIFF
	   ,[TRANSACTION].COD_ASS_TR_COMP
	   ,TRANSACTION_TITLES.COD_TITLE
	   ,CE_DESTINY.COD_EC
	   ,COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
	   ,BRANCH_EC.COD_BRANCH
	   ,DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
	   ,[TRANSACTION].PAN
	   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ AS 'CPF_CNPJ_ORIGINATOR'
	   ,CE_DESTINY.[NAME] AS 'EC_NAME_DESTINY'
	   ,CE_DESTINY.CPF_CNPJ AS 'CPF_CNPJ_DESTINY'
	   ,AFFILIATOR.CPF_CNPJ AS 'CPF_AFF'
	   ,(SELECT
				EQUIPMENT.SERIAL
			FROM ASS_DEPTO_EQUIP
			INNER JOIN EQUIPMENT
				ON EQUIPMENT.COD_EQUIP = ASS_DEPTO_EQUIP.COD_EQUIP
			WHERE ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL)
		AS SERIAL
	   ,[TRANSACTION_DATA_EXT].[VALUE] AS 'EXTERNAL_NSU'
	   ,[TRANSACTION].CODE
	   ,[TRANSACTION].COD_TRAN
	   ,[COMPANY].COD_COMP
	   ,[REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN AS REP_COD_TRAN
	   ,[TRANSACTION].COD_SITUATION
	   ,dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES.TAX_INITIAL +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 2 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
				, 0)
			ELSE 0
		END)

		, [TRANSACTION_TITLES].AMOUNT) AS LIQUID_MDR_EC
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES.ANTICIP_PERCENT +
		(CASE
			WHEN [TRANSACTION].COD_TTYPE = 1 THEN ISNULL((SELECT
						TRANSACTION_SERVICES.TAX_PLANDZERO_EC
					FROM TRANSACTION_SERVICES
					INNER JOIN ITEMS_SERVICES_AVAILABLE
						ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = ITEMS_SERVICES_AVAILABLE.COD_ITEM_SERVICE
					WHERE ITEMS_SERVICES_AVAILABLE.NAME = 'PlanDZero'
					AND TRANSACTION_SERVICES.COD_TRAN = TRANSACTION_TITLES.COD_TRAN
					AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION_TITLES].COD_EC)
				, 0)
			ELSE 0
		END), 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT, [TRANSACTION_TITLES].TAX_INITIAL),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		) AS ANTECIP_DISCOUNT_EC
	   ,CASE
			WHEN [TRANSACTION].PLOTS = 1 THEN dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE] + IIF([TRANSACTION].COD_TTYPE = 2, TRANSACTION_TITLES_COST.TAX_PLANDZERO, 0), TRANSACTION_TITLES.AMOUNT)
			ELSE dbo.FNC_CALC_LIQ_MDR(TRANSACTION_TITLES_COST.[PERCENTAGE], TRANSACTION_TITLES.AMOUNT)
		END AS LIQUID_MDR_AFF
	   ,dbo.FNC_CALC_LIQ_ANTICIP_DAYS
		(
		COALESCE(TRANSACTION_TITLES_COST.ANTICIP_PERCENT, 0) + IIF([TRANSACTION].COD_TTYPE = 1, TRANSACTION_TITLES_COST.TAX_PLANDZERO, 0),
		[TRANSACTION_TITLES].PLOT,
		dbo.FNC_CALC_LIQUID([TRANSACTION_TITLES].AMOUNT,
		[TRANSACTION_TITLES_COST].[PERCENTAGE]),
		(CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)

			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END)
		) AS ANTECIP_DISCOUNT_AFF
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM TRANSACTION_SERVICES WITH (NOLOCK)
					WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
					AND TRANSACTION_SERVICES.COD_ITEM_SERVICE = 4)
				> 0 THEN 1
			ELSE 0
		END AS SPLIT
	   ,EC_TRAN.COD_EC AS COD_EC_TRANS
	   ,EC_TRAN.NAME AS TRANS_EC_NAME
	   ,EC_TRAN.CPF_CNPJ AS TRANS_EC_CPF_CNPJ
	   ,[TRANSACTION_TITLES].[ASSIGNED]
	   ,[ASSIGN_FILE_TITLE].RETAINED_AMOUNT
	   ,[ASSIGN_FILE_TITLE].[ORIGINAL_DATE]
	   ,CAST([TRANSACTION_TITLES].CREATED_AT AS DATE) TRAN_TITTLE_DATE
	   ,CAST([TRANSACTION_TITLES].CREATED_AT AS TIME) TRAN_TITTLE_TIME
	   ,(SELECT TOP 1
				[NAME]
			FROM ACQUIRER(NOLOCK)
			JOIN ASSIGN_FILE_ACQUIRE(NOLOCK) fType
				ON fType.COD_AC = ACQUIRER.COD_AC
				AND fType.COD_ASSIGN_FILE_MODEL = assignModel.COD_ASSIGN_FILE_MODEL)
		[ASSIGNEE]
	   ,(SELECT
				TRANSACTION_DATA_EXT.[VALUE]
			FROM TRANSACTION_DATA_EXT WITH (NOLOCK)
			WHERE TRANSACTION_DATA_EXT.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_DATA_EXT.[NAME] = 'AUTHCODE')
		AS [AUTH_CODE]
	   ,[TRANSACTION].CREDITOR_DOCUMENT
	   ,(SELECT
				TRANSACTION_DATA_EXT.[VALUE]
			FROM TRANSACTION_DATA_EXT WITH (NOLOCK)
			WHERE TRANSACTION_DATA_EXT.COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
			AND TRANSACTION_DATA_EXT.[NAME] = 'COUNT')
		AS ORDER_CODE
	   ,TRANSACTION_TITLES.COD_SITUATION [COD_SITUATION_TITLE]
	   ,[EQUIPMENT_MODEL].CODIGO AS MODEL_POS
	   ,[SEGMENTS].[NAME] AS SEGMENT_EC
	   ,[STATE].UF AS STATE_EC
	   ,[CITY].[NAME] AS CITY_EC
	   ,[NEIGHBORHOOD].[NAME] AS NEIGHBORHOOD_EC
	   ,[ADDRESS_BRANCH].COD_ADDRESS
	   ,SOURCE_TRANSACTION.DESCRIPTION AS TYPE_TRAN
	   ,EC_PROD.[NAME] AS [EC_PROD]
	   ,EC_PROD.CPF_CNPJ AS [EC_PROD_CPF_CNPJ]
	   ,TRAN_PROD.[NAME] AS [NAME_PROD]
	   ,SPLIT_PROD.[PERCENTAGE] AS [PERCENT_PARTICIP_SPLIT]
	   ,[TRANSACTION_TITLES_COST].RATE_PLAN
	   ,CASE
			WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
			ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
		END AS QTY_DAYS_ANTECIP
	   ,IIF([TRANSACTION_TITLES].TAX_PLANDZERO IS NULL, 0, 1) AS IS_PLANDZERO
	   ,COALESCE([TRANSACTION_TITLES].TAX_PLANDZERO, 0) TAX_PLANDZERO
	   ,ISNULL((SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES WITH (NOLOCK)
			INNER JOIN ITEMS_SERVICES_AVAILABLE isa
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = isa.COD_ITEM_SERVICE
			WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
			AND TRANSACTION_SERVICES.COD_EC = [TRANSACTION].COD_EC
			AND isa.NAME = 'PlanDZero')
		, 0)
		AS TAX_PLANDZEROAFF
	   ,USER_REPRESENTANTE.IDENTIFICATION AS SALES_REPRESENTANTE
	   ,USER_REPRESENTANTE.CPF_CNPJ AS CPF_CNPJ_REPRESENTANTE
	   ,USER_REPRESENTANTE.EMAIL AS EMAIL_REPRESENTANTE
	   ,EC_PROD.COD_EC AS [COD_EC_PROD]
	FROM [TRANSACTION_TITLES] WITH (NOLOCK)
	INNER JOIN [TRANSACTION] WITH (NOLOCK)
		ON [TRANSACTION].COD_TRAN = TRANSACTION_TITLES.COD_TRAN
	LEFT JOIN [TRANSACTION_TITLES_COST] WITH (NOLOCK)
		ON [TRANSACTION_TITLES].COD_TITLE = TRANSACTION_TITLES_COST.COD_TITLE
	INNER JOIN [TRANSACTION_TYPE] WITH (NOLOCK)
		ON TRANSACTION_TYPE.COD_TTYPE = [TRANSACTION].COD_TTYPE
	LEFT JOIN AFFILIATOR WITH (NOLOCK)
		ON AFFILIATOR.COD_AFFILIATOR = [TRANSACTION].COD_AFFILIATOR
	INNER JOIN ASS_DEPTO_EQUIP WITH (NOLOCK)
		ON ASS_DEPTO_EQUIP.COD_ASS_DEPTO_TERMINAL = [TRANSACTION].COD_ASS_DEPTO_TERMINAL
	INNER JOIN DEPARTMENTS_BRANCH WITH (NOLOCK)
		ON DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH = ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
	INNER JOIN DEPARTMENTS WITH (NOLOCK)
		ON DEPARTMENTS.COD_DEPARTS = DEPARTMENTS_BRANCH.COD_DEPARTS
	INNER JOIN BRANCH_EC WITH (NOLOCK)
		ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
	INNER JOIN COMMERCIAL_ESTABLISHMENT WITH (NOLOCK)
		ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
	INNER JOIN COMMERCIAL_ESTABLISHMENT CE_DESTINY WITH (NOLOCK)
		ON CE_DESTINY.COD_EC = TRANSACTION_TITLES.COD_EC
	INNER JOIN PRODUCTS_ACQUIRER WITH (NOLOCK)
		ON PRODUCTS_ACQUIRER.COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ
	INNER JOIN ACQUIRER WITH (NOLOCK)
		ON ACQUIRER.COD_AC = PRODUCTS_ACQUIRER.COD_AC
	LEFT JOIN [TRANSACTION_DATA_EXT] WITH (NOLOCK)
		ON [TRANSACTION_DATA_EXT].COD_TRAN = [TRANSACTION].COD_TRAN
	INNER JOIN [dbo].[PROCESS_BG_STATUS] WITH (NOLOCK)
		ON ([PROCESS_BG_STATUS].CODE = [TRANSACTION].COD_TRAN)
	LEFT JOIN COMPANY WITH (NOLOCK)
		ON COMPANY.COD_COMP = COMMERCIAL_ESTABLISHMENT.COD_COMP
	LEFT JOIN [dbo].[REPORT_CONSOLIDATED_TRANS_SUB] WITH (NOLOCK)
		ON ([REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN = [TRANSACTION].COD_TRAN)
	LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_TRAN WITH (NOLOCK)
		ON EC_TRAN.COD_EC = [TRANSACTION].COD_EC
	LEFT JOIN [ASSIGN_FILE_TITLE](NOLOCK)
		ON [ASSIGN_FILE_TITLE].COD_TITLE = [TRANSACTION_TITLES].COD_TITLE
		AND [ASSIGN_FILE_TITLE].ACTIVE = 1
	LEFT JOIN ASSIGN_FILE(NOLOCK)
		ON ASSIGN_FILE.COD_ASSIGN_FILE = [ASSIGN_FILE_TITLE].COD_ASSIGN_FILE
	LEFT JOIN ASSIGN_FILE_MODEL assignModel (NOLOCK)
		ON assignModel.COD_ASSIGN_FILE_MODEL = ASSIGN_FILE.COD_ASSIGN_FILE_MODEL
	INNER JOIN [EQUIPMENT] WITH (NOLOCK)
		ON [EQUIPMENT].COD_EQUIP = [ASS_DEPTO_EQUIP].COD_EQUIP
	INNER JOIN [EQUIPMENT_MODEL] WITH (NOLOCK)
		ON [EQUIPMENT_MODEL].COD_MODEL = [EQUIPMENT].COD_MODEL
	INNER JOIN [SEGMENTS] WITH (NOLOCK)
		ON [SEGMENTS].COD_SEG = [COMMERCIAL_ESTABLISHMENT].COD_SEG
	INNER JOIN [ADDRESS_BRANCH] WITH (NOLOCK)
		ON [ADDRESS_BRANCH].COD_BRANCH = [BRANCH_EC].COD_BRANCH
		AND [ADDRESS_BRANCH].ACTIVE = 1
	INNER JOIN [NEIGHBORHOOD] WITH (NOLOCK)
		ON [NEIGHBORHOOD].COD_NEIGH = [ADDRESS_BRANCH].COD_NEIGH
	INNER JOIN [CITY] WITH (NOLOCK)
		ON [CITY].COD_CITY = [NEIGHBORHOOD].COD_CITY
	INNER JOIN [STATE] WITH (NOLOCK)
		ON [STATE].COD_STATE = [CITY].COD_STATE
	INNER JOIN SOURCE_TRANSACTION WITH (NOLOCK)
		ON SOURCE_TRANSACTION.COD_SOURCE_TRAN = [TRANSACTION].COD_SOURCE_TRAN
	LEFT JOIN TRANSACTION_PRODUCTS AS [TRAN_PROD] WITH (NOLOCK)
		ON [TRAN_PROD].COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
		AND [TRAN_PROD].ACTIVE = 1
	LEFT JOIN SPLIT_PRODUCTS SPLIT_PROD WITH (NOLOCK)
		ON SPLIT_PROD.COD_SPLIT_PROD = TRANSACTION_TITLES.COD_SPLIT_PROD
	LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PROD WITH (NOLOCK)
		ON EC_PROD.COD_EC = [TRAN_PROD].COD_EC
	LEFT JOIN SALES_REPRESENTATIVE
		ON SALES_REPRESENTATIVE.COD_SALES_REP = COMMERCIAL_ESTABLISHMENT.COD_SALES_REP
	LEFT JOIN USERS USER_REPRESENTANTE
		ON USER_REPRESENTANTE.COD_USER = SALES_REPRESENTATIVE.COD_USER
	WHERE
	--[TRANSACTION].COD_SITUATION IN (3, 6, 10)                                  
	[TRANSACTION].COD_SITUATION = 3
	AND [TRANSACTION_TITLES].COD_SITUATION != 26
	AND COALESCE([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
	AND PROCESS_BG_STATUS.STATUS_PROCESSED = 0
	AND PROCESS_BG_STATUS.COD_SOURCE_PROCESS = 3
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION].CREATED_AT
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION_TITLES].CREATED_AT
	AND DATEPART(YEAR, [TRANSACTION].CREATED_AT) = DATEPART(YEAR, GETDATE())
	AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN IS NULL)
SELECT
	AFFILIATOR
   ,MERSHANT
   ,SERIAL
   ,CAST(TRANSACTION_DATE AS DATE) AS TRANSACTION_DATE
   ,CAST(TRANSACTION_DATE AS TIME) AS TRANSACTION_TIME
   ,NSU
   ,EXTERNAL_NSU
   ,TRAN_TYPE
   ,TRANSACTION_AMOUNT
   ,TOTAL_PLOTS AS QUOTA_TOTAL
   ,AMOUNT AS 'QUOTA_AMOUNT'
   ,PLOT AS QUOTA
   ,ACQUIRER
   ,ACQ_TAX AS 'MDR_ACQ'
   ,BRAND
   ,CTE.TAX_INITIAL AS 'MDR_EC'
   ,ANTECIP_EC AS 'ANTICIP_EC'
   ,MDR_AFF AS 'MDR_AFF'
   ,ANTECIP_AFF AS 'ANTICIP_AFF'
   ,LIQUID_SUB AS 'TO_RECEIVE_ACQ'
   ,CAST(PREVISION_RECEIVE_DATE AS DATE) AS 'PREDICTION_RECEIVE_DATE'
   ,(LIQUID_SUB - AFF_DISCOUNT) AS 'NET_WITHOUT_FEE_SUB'
   ,RATE_PLAN AS 'FEE_AFFILIATOR'
   ,(LIQUID_SUB - AFF_DISCOUNT_TARIFF) AS 'NET_SUB'
   ,AFF AS 'NET_WITHOUT_FEE_AFF'
   ,AFF_TARIFF AS 'NET_AFF'
   ,EC AS 'MERCHANT_WITHOUT_FEE'
   ,CTE.RATE AS 'FEE_MERCHANT'
   ,EC_TARIFF AS 'MERCHANT_NET'
   ,CAST(PREVISION_PAY_DATE AS DATE) AS 'PREDICTION_PAY_DATE'
   ,CASE
		WHEN TRAN_TYPE = 'CREDITO' AND
			(CAST(PREVISION_RECEIVE_DATE AS DATE) != CAST(PREVISION_PAY_DATE AS DATE)) THEN 1
		ELSE 0
	END AS ANTECIPATED
   ,COD_EC
   ,CTE.COD_AFFILIATOR
   ,COD_BRANCH
   ,CTE.COD_DEPTO_BRANCH
   ,PAN
   ,CPF_CNPJ_ORIGINATOR
   ,EC_NAME_DESTINY
   ,CPF_CNPJ_DESTINY
   ,CPF_AFF
   ,CTE.CODE
   ,CTE.COD_TRAN
   ,CTE.COD_COMP
   ,CTE.REP_COD_TRAN
   ,CTE.COD_SITUATION
   ,CTE.LIQUID_MDR_EC
   ,CTE.ANTECIP_DISCOUNT_EC
   ,CTE.LIQUID_MDR_AFF
   ,CTE.ANTECIP_DISCOUNT_AFF
   ,CTE.SPLIT
   ,CTE.COD_EC_TRANS
   ,CTE.TRANS_EC_NAME
   ,CTE.TRANS_EC_CPF_CNPJ
   ,CTE.[ASSIGNED]
   ,CTE.RETAINED_AMOUNT
   ,CTE.[ORIGINAL_DATE]
   ,CTE.[ASSIGNEE]
   ,CTE.TRAN_TITTLE_DATE
   ,CTE.TRAN_TITTLE_TIME
   ,CTE.AUTH_CODE
   ,CTE.CREDITOR_DOCUMENT
   ,CTE.ORDER_CODE
   ,CTE.COD_TITLE
   ,CTE.[COD_SITUATION_TITLE]
   ,CTE.MODEL_POS
   ,CTE.SEGMENT_EC
   ,CTE.STATE_EC
   ,CTE.CITY_EC
   ,CTE.NEIGHBORHOOD_EC
   ,CTE.COD_ADDRESS
   ,CTE.TYPE_TRAN
   ,CTE.NAME_PROD
   ,CTE.EC_PROD
   ,CTE.EC_PROD_CPF_CNPJ
   ,CTE.PERCENT_PARTICIP_SPLIT
   ,CTE.QTY_DAYS_ANTECIP
   ,CTE.IS_PLANDZERO
   ,CTE.TAX_PLANDZERO
   ,CTE.EC_TARIFF
   ,CTE.AFF_TARIFF
   ,AFF
   ,CTE.TAX_PLANDZEROAFF
   ,CTE.SALES_REPRESENTANTE
   ,CTE.CPF_CNPJ_REPRESENTANTE
   ,CTE.EMAIL_REPRESENTANTE
   ,CTE.COD_EC_PROD
FROM CTE


GO

IF OBJECT_ID('SP_REG_REPORT_CONSOLIDATED_TRANS_SUB') IS NOT NULL
	DROP PROCEDURE [SP_REG_REPORT_CONSOLIDATED_TRANS_SUB];

GO

CREATE PROCEDURE [dbo].[SP_REG_REPORT_CONSOLIDATED_TRANS_SUB] WITH RECOMPILE
/*----------------------------------------------------------------------------------------                                
    Project.......: TKPP                                
------------------------------------------------------------------------------------------                                
    Author                          VERSION        Date             Description                                
------------------------------------------------------------------------------------------                                
    Fernando Henrique F. de O       V1              28/12/2018      Creation                              
    Fernando Henrique F. de O       V2              07/02/2019      Changed                          
    Luiz Aquino                     V3              22/02/2019      Remove Incomplete Installments                             
    Lucas Aguiar                    V4              22-04-2019      add originador e destino                         
    Caike Ucha                     V5              16/08/2019      add columns AUTH_CODE e CREDITOR_DOCUMENT                     
    Caike Ucha                     V6              11/09/2019      add column ORDER_CODE                      
    Marcus Gall                     V7              27/11/2019      Add Model_POS, Segment, Location_EC              
    Ana Paula Liick                 V8              31/01/2020      Add Origem_Trans            
    Caike Ucha                      V9              30/04/2020      add produto ec    
	Caike Uchoa                     V10             03/08/2020      add QTY_DAYS_ANTECIP    
    Caike Uchoa                     V11             06/08/2020      Add AMOUNT_NEW  
    Caike Uchoa                     V12             27/08/2020      add representante 
    Luiz Aquino                    V10            02/07/2020      PlanDZero (ET-895)      
	Caike Uchoa                     v12             01/09/2020      Add cod_ec_prod
------------------------------------------------------------------------------------------*/
AS
	DECLARE @COUNT INT = 0;
	BEGIN

		---------------------------------------------                              
		--------------RECORDS INSERT-----------------                              
		---------------------------------------------                                
		SELECT
			--TOP (1000)                  
			[VW_REPORT_FULL_CASH_FLOW].COD_TRAN
		   ,[VW_REPORT_FULL_CASH_FLOW].AFFILIATOR
		   ,[VW_REPORT_FULL_CASH_FLOW].MERSHANT
		   ,[VW_REPORT_FULL_CASH_FLOW].TRANSACTION_DATE
		   ,[VW_REPORT_FULL_CASH_FLOW].TRANSACTION_TIME
		   ,[VW_REPORT_FULL_CASH_FLOW].NSU
		   ,[VW_REPORT_FULL_CASH_FLOW].QUOTA_TOTAL
		   ,[VW_REPORT_FULL_CASH_FLOW].TRAN_TYPE
		   ,[VW_REPORT_FULL_CASH_FLOW].QUOTA
		   ,[VW_REPORT_FULL_CASH_FLOW].QUOTA_AMOUNT AMOUNT
		   ,[VW_REPORT_FULL_CASH_FLOW].TRANSACTION_AMOUNT
		   ,[VW_REPORT_FULL_CASH_FLOW].ACQUIRER
		   ,[VW_REPORT_FULL_CASH_FLOW].MDR_ACQ
		   ,[VW_REPORT_FULL_CASH_FLOW].BRAND
		   ,[VW_REPORT_FULL_CASH_FLOW].MDR_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].ANTICIP_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].ANTICIP_AFF
		   ,[VW_REPORT_FULL_CASH_FLOW].MDR_AFF
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_SUB AS NET_SUB_RATE
		   ,[VW_REPORT_FULL_CASH_FLOW].ANTECIPATED
		   ,[VW_REPORT_FULL_CASH_FLOW].PREDICTION_PAY_DATE
		   ,[VW_REPORT_FULL_CASH_FLOW].TO_RECEIVE_ACQ
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_AFF
			--,COALESCE([VW_REPORT_FULL_CASH_FLOW].RATE_CURRENT_EC, 0) AS RATE_EC                                         
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_WITHOUT_FEE_AFF AS NET_WITHOUT_FEE_AFF_RATE
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_SUB AS NET_SUB_ACQ
		   ,[VW_REPORT_FULL_CASH_FLOW].PREDICTION_RECEIVE_DATE
		   ,[VW_REPORT_FULL_CASH_FLOW].FEE_MERCHANT AS RATE
		   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].ANTECIP_DISCOUNT_AFF, 0) AS ANTECIP_DISCOUNT_AFF
		   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].ANTECIP_DISCOUNT_EC, 0) AS ANTECIP_DISCOUNT_EC
			--,COALESCE([VW_REPORT_FULL_CASH_FLOW].MDR_CURRENT_ACQ, 0) AS MDR_CURRENT_ACQ                                    
		   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].LIQUID_MDR_AFF, 0) AS LIQUID_MDR_AFF
			--,COALESCE([VW_REPORT_FULL_CASH_FLOW].RATE_CURRENT_AFF, 0) AS RATE_CURRENT_AFF                               
			--,COALESCE([VW_REPORT_FULL_CASH_FLOW].RATE_CURRENT_EC, 0) AS RATE_CURRENT_EC                                
		   ,COALESCE([VW_REPORT_FULL_CASH_FLOW].LIQUID_MDR_EC, 0) AS LIQUID_MDR_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].MERCHANT_WITHOUT_FEE
		   ,[VW_REPORT_FULL_CASH_FLOW].FEE_AFFILIATOR
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_SUB
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_WITHOUT_FEE_SUB
		   ,[VW_REPORT_FULL_CASH_FLOW].NET_WITHOUT_FEE_AFF
		   ,[VW_REPORT_FULL_CASH_FLOW].MERCHANT_NET
		   ,[VW_REPORT_FULL_CASH_FLOW].CPF_CNPJ_ORIGINATOR AS 'CPF_EC'
		   ,[VW_REPORT_FULL_CASH_FLOW].EC_NAME_DESTINY AS 'ECNAME_DESTINY'
		   ,[VW_REPORT_FULL_CASH_FLOW].CPF_CNPJ_DESTINY AS 'DESTINY'
		   ,[VW_REPORT_FULL_CASH_FLOW].CPF_AFF AS CPF_AFF
		   ,[VW_REPORT_FULL_CASH_FLOW].SERIAL
		   ,[VW_REPORT_FULL_CASH_FLOW].EXTERNAL_NSU
		   ,[VW_REPORT_FULL_CASH_FLOW].PAN
		   ,[VW_REPORT_FULL_CASH_FLOW].CODE
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_COMP
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_BRANCH
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_DEPTO_BRANCH
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_AFFILIATOR
		   ,[VW_REPORT_FULL_CASH_FLOW].SPLIT
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_EC_TRANS
		   ,[VW_REPORT_FULL_CASH_FLOW].TRANS_EC_NAME
		   ,[VW_REPORT_FULL_CASH_FLOW].TRANS_EC_CPF_CNPJ
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_SITUATION
		   ,[VW_REPORT_FULL_CASH_FLOW].[ASSIGNED]
		   ,[VW_REPORT_FULL_CASH_FLOW].[RETAINED_AMOUNT]
		   ,[VW_REPORT_FULL_CASH_FLOW].[ORIGINAL_DATE]
		   ,[VW_REPORT_FULL_CASH_FLOW].[ASSIGNEE]
		   ,[VW_REPORT_FULL_CASH_FLOW].TRAN_TITTLE_TIME
		   ,[VW_REPORT_FULL_CASH_FLOW].TRAN_TITTLE_DATE
		   ,[VW_REPORT_FULL_CASH_FLOW].AUTH_CODE
		   ,[VW_REPORT_FULL_CASH_FLOW].CREDITOR_DOCUMENT
		   ,[VW_REPORT_FULL_CASH_FLOW].ORDER_CODE
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_TITLE
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_SITUATION_TITLE
		   ,[VW_REPORT_FULL_CASH_FLOW].MODEL_POS
		   ,[VW_REPORT_FULL_CASH_FLOW].SEGMENT_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].STATE_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].CITY_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].NEIGHBORHOOD_EC
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_ADDRESS
		   ,[VW_REPORT_FULL_CASH_FLOW].TYPE_TRAN
		   ,[VW_REPORT_FULL_CASH_FLOW].NAME_PROD
		   ,[VW_REPORT_FULL_CASH_FLOW].EC_PROD
		   ,[VW_REPORT_FULL_CASH_FLOW].EC_PROD_CPF_CNPJ
		   ,[VW_REPORT_FULL_CASH_FLOW].PERCENT_PARTICIP_SPLIT
		   ,[VW_REPORT_FULL_CASH_FLOW].IS_PLANDZERO
		   ,[VW_REPORT_FULL_CASH_FLOW].TAX_PLANDZERO
		   ,[VW_REPORT_FULL_CASH_FLOW].TAX_PLANDZEROAFF
		   ,dbo.VW_REPORT_FULL_CASH_FLOW.QTY_DAYS_ANTECIP
		   ,[VW_REPORT_FULL_CASH_FLOW].SALES_REPRESENTANTE
		   ,[VW_REPORT_FULL_CASH_FLOW].CPF_CNPJ_REPRESENTANTE
		   ,[VW_REPORT_FULL_CASH_FLOW].EMAIL_REPRESENTANTE
		   ,[VW_REPORT_FULL_CASH_FLOW].COD_EC_PROD INTO #TB_REPORT_FULL_CASH_FLOW_INSERT
		FROM [dbo].[VW_REPORT_FULL_CASH_FLOW]
		ORDER BY COD_TRAN, QUOTA
		OFFSET 0 ROWS FETCH FIRST 500 ROWS ONLY;

		WITH TRANINFO
		AS
		(SELECT
				COUNT(COD_TRAN) AVAILABLE_INSTALLMENTS
			   ,COD_TRAN
			   ,QUOTA_TOTAL
			FROM #TB_REPORT_FULL_CASH_FLOW_INSERT installments
			GROUP BY COD_TRAN
					,QUOTA_TOTAL)
		DELETE INSTALLMENT
			FROM #TB_REPORT_FULL_CASH_FLOW_INSERT INSTALLMENT
			JOIN TRANINFO
				ON TRANINFO.COD_TRAN = INSTALLMENT.COD_TRAN
		WHERE TRANINFO.QUOTA_TOTAL > TRANINFO.AVAILABLE_INSTALLMENTS

		SELECT
			@COUNT = COUNT(*)
		FROM #TB_REPORT_FULL_CASH_FLOW_INSERT;

		IF @COUNT > 0
		BEGIN
			INSERT INTO [dbo].[REPORT_CONSOLIDATED_TRANS_SUB] ([COD_TRAN],
			[AFFILIATOR],
			[COMMERCIALESTABLISHMENT],
			[TRANSACTION_DATE],
			[TRANSACTION_TIME],
			[NSU],
			[QUOTA_TOTAL],
			[TRANSACTION_TYPE],
			[PLOT],
			[AMOUNT],
			[TRANSACTION_AMOUNT],
			[ACQUIRER],
			[MDR_ACQUIRER],
			[BRAND],
			[MDR_EC],
			[ANTECIP_PERCENT],
			[ANTECIP_AFFILIATOR],
			[MDR_AFFILIATOR],
			[LIQUID_VALUE_SUB],
			[ANTECIPATED],
			[PREVISION_PAY_DATE],
			[TO_RECEIVE_ACQ],
			[LIQUID_VALUE_AFFILIATOR],
			[LIQUID_AFF_RATE],
			[LIQUID_SUB_RATE],
			[PREVISION_RECEIVE_DATE],
			[RATE],
			[ANTECIP_CURRENT_AFF],
			[ANTECIP_CURRENT_EC],
			[MDR_CURRENT_AFF],
			[MDR_CURRENT_EC],
			[LIQUID_VALUE_EC],
			[FEE_AFFILIATOR],
			[NET_SUB_AQUIRER],
			[NET_WITHOUT_FEE_SUB],
			[NET_WITHOUT_FEE_AFF], [MERCHANT_NET],
			[CPF_EC],
			[DESTINY],
			[CPF_AFF],
			[SERIAL],
			[EXTERNALNSU],
			[PAN],
			[CODE],
			[COD_COMP],
			[COD_EC],
			[COD_BRANCH],
			[COD_DEPTO_BRANCH],
			[COD_AFFILIATOR],
			[COD_SITUATION],
			[SPLIT],
			[COD_EC_TRANS],
			[TRANS_EC_NAME],
			[TRANS_EC_CPF_CNPJ]
			, [ASSIGNED]
			, [RETAINED_AMOUNT]
			, [ORIGINAL_DATE]
			, [ASSIGNEE]
			, [MODIFY_DATE]
			, EC_NAME_DESTINY
			, TRANSACTION_TITTLE_DATE
			, TRANSACTION_TITTLE_TIME
			, AUTH_CODE
			, CREDITOR_DOCUMENT
			, ORDER_CODE
			, COD_TITLE
			, COD_SITUATION_TITLE
			, MODEL_POS
			, SEGMENT_EC
			, STATE_EC
			, CITY_EC
			, NEIGHBORHOOD_EC
			, COD_ADDRESS
			, TYPE_TRAN
			, NAME_PROD
			, EC_PROD
			, EC_PROD_CPF_CNPJ
			, PERCENT_PARTICIP_SPLIT
			, IS_PLANDZERO
			, TAX_PLANDZERO
			, QTY_DAYS_ANTECIP
			, TAX_PLANDZERO_AFF
			, SALES_REPRESENTANTE
			, CPF_CNPJ_REPRESENTANTE
			, EMAIL_REPRESENTANTE
			, COD_EC_PROD)
				(SELECT
					TEMP.[COD_TRAN]
				   ,TEMP.[AFFILIATOR]
				   ,TEMP.[MERSHANT]
				   ,TEMP.[TRANSACTION_DATE]
				   ,TEMP.[TRANSACTION_TIME]
				   ,TEMP.[NSU]
				   ,TEMP.[QUOTA_TOTAL]
				   ,TEMP.[TRAN_TYPE]
				   ,TEMP.[QUOTA]
				   ,TEMP.[AMOUNT]
				   ,TEMP.[TRANSACTION_AMOUNT]
				   ,TEMP.[ACQUIRER]
				   ,TEMP.[MDR_ACQ]
				   ,TEMP.[BRAND]
				   ,TEMP.[MDR_EC]
				   ,TEMP.[ANTICIP_EC]
				   ,TEMP.[ANTICIP_AFF]
				   ,TEMP.[MDR_AFF]
				   ,TEMP.[NET_SUB_RATE]
				   ,TEMP.[ANTECIPATED]
				   ,TEMP.[PREDICTION_PAY_DATE]
				   ,TEMP.[TO_RECEIVE_ACQ]
				   ,TEMP.[NET_AFF]
				   ,TEMP.[NET_WITHOUT_FEE_AFF_RATE]
				   ,TEMP.[NET_SUB_ACQ]
				   ,TEMP.[PREDICTION_RECEIVE_DATE]
				   ,TEMP.[RATE]
				   ,TEMP.[ANTECIP_DISCOUNT_AFF]
				   ,TEMP.[ANTECIP_DISCOUNT_EC]
				   ,TEMP.[LIQUID_MDR_AFF]
				   ,TEMP.[LIQUID_MDR_EC]
				   ,TEMP.[MERCHANT_WITHOUT_FEE]
				   ,TEMP.[FEE_AFFILIATOR]
				   ,TEMP.[NET_SUB]
				   ,TEMP.[NET_WITHOUT_FEE_SUB]
				   ,TEMP.[NET_WITHOUT_FEE_AFF]
				   ,TEMP.[MERCHANT_NET]
				   ,TEMP.[CPF_AFF]
				   ,TEMP.[DESTINY]
				   ,TEMP.[CPF_EC]
				   ,TEMP.[SERIAL]
				   ,TEMP.[EXTERNAL_NSU]
				   ,TEMP.[PAN]
				   ,TEMP.[CODE]
				   ,TEMP.[COD_COMP]
				   ,TEMP.[COD_EC]
				   ,TEMP.[COD_BRANCH]
				   ,TEMP.[COD_DEPTO_BRANCH]
				   ,TEMP.[COD_AFFILIATOR]
				   ,TEMP.[COD_SITUATION]
				   ,TEMP.[SPLIT]
				   ,TEMP.[COD_EC_TRANS]
				   ,TEMP.[TRANS_EC_NAME]
				   ,TEMP.[TRANS_EC_CPF_CNPJ]
				   ,TEMP.[ASSIGNED]
				   ,TEMP.[RETAINED_AMOUNT]
				   ,TEMP.[ORIGINAL_DATE]
				   ,TEMP.[ASSIGNEE]
				   ,GETDATE()
				   ,TEMP.ECNAME_DESTINY
				   ,TRAN_TITTLE_DATE
				   ,TRAN_TITTLE_TIME
				   ,TEMP.AUTH_CODE
				   ,TEMP.CREDITOR_DOCUMENT
				   ,TEMP.ORDER_CODE
				   ,TEMP.COD_TITLE
				   ,TEMP.COD_SITUATION_TITLE
				   ,TEMP.MODEL_POS
				   ,TEMP.SEGMENT_EC
				   ,TEMP.STATE_EC
				   ,TEMP.CITY_EC
				   ,TEMP.NEIGHBORHOOD_EC
				   ,TEMP.COD_ADDRESS
				   ,TEMP.TYPE_TRAN
				   ,TEMP.NAME_PROD
				   ,TEMP.EC_PROD
				   ,TEMP.EC_PROD_CPF_CNPJ
				   ,TEMP.PERCENT_PARTICIP_SPLIT
				   ,TEMP.IS_PLANDZERO
				   ,TEMP.TAX_PLANDZERO
				   ,TEMP.QTY_DAYS_ANTECIP
				   ,TEMP.TAX_PLANDZEROAFF
				   ,TEMP.SALES_REPRESENTANTE
				   ,TEMP.CPF_CNPJ_REPRESENTANTE
				   ,TEMP.EMAIL_REPRESENTANTE
				   ,TEMP.COD_EC_PROD
				FROM #TB_REPORT_FULL_CASH_FLOW_INSERT TEMP
				)

			IF @@rowcount < 1
				THROW 60000, 'COULD NOT REGISTER [REPORT_CONSOLIDATED_TRANS_SUB] ', 1;

			UPDATE [PROCESS_BG_STATUS]
			SET STATUS_PROCESSED = 1
			   ,MODIFY_DATE = GETDATE()
			FROM [PROCESS_BG_STATUS]
			INNER JOIN #TB_REPORT_FULL_CASH_FLOW_INSERT
				ON (PROCESS_BG_STATUS.CODE = #TB_REPORT_FULL_CASH_FLOW_INSERT.COD_TRAN)
			WHERE [PROCESS_BG_STATUS].COD_SOURCE_PROCESS = 3;

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](INSERT)', 1;
		END;

		---------------------------------------------                                
		--------------RECORDS UPDATE-----------------                                
		---------------------------------------------                                  
		SELECT
			[VW_REPORT_FULL_CASH_FLOW_UP].COD_TRAN
		   ,[VW_REPORT_FULL_CASH_FLOW_UP].COD_SITUATION
		   ,[VW_REPORT_FULL_CASH_FLOW_UP].TRANSACTION_AMOUNT INTO #TB_REPORT_FULL_CASH_FLOW_UPDATE
		FROM [dbo].[VW_REPORT_FULL_CASH_FLOW_UP]


		SELECT
			@COUNT = COUNT(*)
		FROM #TB_REPORT_FULL_CASH_FLOW_UPDATE;

		IF @COUNT > 0
		BEGIN
			UPDATE [REPORT_CONSOLIDATED_TRANS_SUB]
			SET [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = #TB_REPORT_FULL_CASH_FLOW_UPDATE.COD_SITUATION
			   ,[REPORT_CONSOLIDATED_TRANS_SUB].MODIFY_DATE = GETDATE()
			   ,[REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_AMOUNT = #TB_REPORT_FULL_CASH_FLOW_UPDATE.TRANSACTION_AMOUNT
			FROM [REPORT_CONSOLIDATED_TRANS_SUB]
			INNER JOIN #TB_REPORT_FULL_CASH_FLOW_UPDATE
				ON ([REPORT_CONSOLIDATED_TRANS_SUB].COD_TRAN = #TB_REPORT_FULL_CASH_FLOW_UPDATE.COD_TRAN);

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [REPORT_CONSOLIDATED_TRANS_SUB]', 1;

			UPDATE [PROCESS_BG_STATUS]
			SET STATUS_PROCESSED = 1
			   ,MODIFY_DATE = GETDATE()
			FROM [PROCESS_BG_STATUS]
			INNER JOIN #TB_REPORT_FULL_CASH_FLOW_UPDATE
				ON (PROCESS_BG_STATUS.CODE = #TB_REPORT_FULL_CASH_FLOW_UPDATE.COD_TRAN)
			WHERE [PROCESS_BG_STATUS].COD_SOURCE_PROCESS = 3;

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](UPDATE)', 1;
		END;
	END;



GO

IF OBJECT_ID('SP_REPORT_CONSOLIDATED_TRANSACTION_SUB') IS NOT NULL
	DROP PROCEDURE [SP_REPORT_CONSOLIDATED_TRANSACTION_SUB];
GO

CREATE PROCEDURE [dbo].[SP_REPORT_CONSOLIDATED_TRANSACTION_SUB]

/**************************************************************************************************************              
    Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
     Author                          VERSION        Date                            Description                                  
 ------------------------------------------------------------------------------------------                                  
    Fernando Henrique F. de O       V1         28/12/2018                          Creation                                
    Fernando Henrique F. de O       V2         07/02/2019                          Changed                                    
    Elir Ribeiro                    V3         29/07/2019                          Changed date                          
    Caike Ucha Almeida             V4         16/08/2019                        Inserting columns                         
    Caike Ucha Almeida             V5         11/09/2019                        Inserting column                        
    Marcus Gall                     V6         27/11/2019               Add Model_POS, Segment, Location_EC                
    Ana Paula Liick                 V8         31/01/2020                       Add Origem_Trans                
    Caike Ucha                     V9         30/04/2020                       add produto ec            
    Luiz Aquino                     V10        02/07/2020                   PlanoDZero (ET-895)   
	 Caike Uchôa                     V10        03/08/2020                       add QTY_DAYS_ANTECIP    
     Caike Uchôa                     V11        07/08/2020                       ISNULL na RATE_PLAN  
     Caike Uchoa                     v12        01/09/2020                       Add cod_ec_prod
**************************************************************************************************************/ (@CODCOMP VARCHAR(10),
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
@CODAFF INT = NULL,
@SPLIT INT = NULL,
@CODACQUIRER INT = NULL,
@ISPlanDZero INT = NULL,
@COD_EC_PROD INT = NULL)
AS
BEGIN


	DECLARE @QUERY_BASIS NVARCHAR(MAX) = '';


	DECLARE @AWAITINGSPLIT INT = NULL;
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	SELECT TOP 1
		@AWAITINGSPLIT = [COD_SITUATION]
	FROM [SITUATION]
	WHERE [NAME] = 'WAITING FOR SPLIT OF FINANCE SCHEDULE';

	SET @QUERY_BASIS = 'SELECT                                      
        [REPORT_CONSOLIDATED_TRANS_SUB].AFFILIATOR AS AFFILIATOR,                     
        [REPORT_CONSOLIDATED_TRANS_SUB].COMMERCIALESTABLISHMENT AS MERCHANT,                                          
        [REPORT_CONSOLIDATED_TRANS_SUB].SERIAL  AS SERIAL,                                    
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE  AS TRANSACTION_DATE,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TIME  AS TRANSACTION_TIME,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].NSU  AS NSU ,                  
        [REPORT_CONSOLIDATED_TRANS_SUB].EXTERNALNSU  AS EXTERNAL_NSU,                                    
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TYPE  AS TRAN_TYPE,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_AMOUNT  AS TRANSACTION_AMOUNT,                                      
        [REPORT_CONSOLIDATED_TRANS_SUB].QUOTA_TOTAL  AS QUOTA_TOTAL,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].AMOUNT  AS  AMOUNT,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].PLOT  AS QUOTA,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].ACQUIRER  AS ACQUIRER,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_ACQUIRER  AS MDR_ACQ,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].BRAND  AS BRAND,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_EC  AS MDR_EC,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_PERCENT  AS ANTICIP_EC,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_AFFILIATOR  AS MDR_AFF,                   
      [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_AFFILIATOR  AS ANTICIP_AFF,                  
        [REPORT_CONSOLIDATED_TRANS_SUB].TO_RECEIVE_ACQ  AS TO_RECEIVE_ACQ,                            
        [REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_RECEIVE_DATE  AS PREDICTION_RECEIVE_DATE,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].NET_WITHOUT_FEE_SUB  AS NET_WITHOUT_FEE_SUB,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].FEE_AFFILIATOR  AS FEE_AFFILIATOR,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].NET_SUB_AQUIRER  AS NET_SUB,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].NET_WITHOUT_FEE_AFF  AS NET_WITHOUT_FEE_AFF,                                    
        [REPORT_CONSOLIDATED_TRANS_SUB].LIQUID_VALUE_AFFILIATOR  AS NET_AFF,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].LIQUID_VALUE_EC  AS MERCHANT_WITHOUT_FEE,                  
        [REPORT_CONSOLIDATED_TRANS_SUB].MERCHANT_NET  AS MERCHANT_NET,                   
        IIF([REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED] = 1, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE] ,[REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE )  AS PREDICTION_PAY_DATE,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIPATED  AS ANTECIPATED,                                
        [REPORT_CONSOLIDATED_TRANS_SUB].RATE,                                
        --[REPORT_CONSOLIDATED_TRANS_SUB].MDR_CURRENT_ACQ  AS MDR_CURRENT_ACQ,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_CURRENT_EC  AS MDR_CURRENT_EC,                  
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_CURRENT_EC  AS ANTICIP_CURRENT_EC,                                        
        --[REPORT_CONSOLIDATED_TRANS_SUB].RATE_CURRENT_EC  AS RATE_CURRENT_EC,                                      
        [REPORT_CONSOLIDATED_TRANS_SUB].MDR_CURRENT_AFF  AS MDR_CURRENT_AFF,                                        
        [REPORT_CONSOLIDATED_TRANS_SUB].ANTECIP_CURRENT_AFF  AS ANTICIP_CURRENT_AFF,                                   
        --[REPORT_CONSOLIDATED_TRANS_SUB].RATE_CURRENT_AFF  AS RATE_CURRENT_AFF,                  
        [REPORT_CONSOLIDATED_TRANS_SUB].CPF_EC  AS CPF_AFF,                              
        [REPORT_CONSOLIDATED_TRANS_SUB].DESTINY  AS DESTINY,                   
        [REPORT_CONSOLIDATED_TRANS_SUB].COD_AFFILIATOR  AS COD_AFFILIATOR,                                        
        [REPORT_CONSOLIDATED_TRANS_SUB].COD_BRANCH  AS COD_BRANCH,                                        
        [REPORT_CONSOLIDATED_TRANS_SUB].COD_DEPTO_BRANCH  AS COD_DEPTO_BRANCH,                                        
        [REPORT_CONSOLIDATED_TRANS_SUB].PAN  AS PAN,                                    
        [REPORT_CONSOLIDATED_TRANS_SUB].CPF_AFF AS ORIGINATOR,                                
        [REPORT_CONSOLIDATED_TRANS_SUB].CODE  AS CODE,                                   
        [REPORT_CONSOLIDATED_TRANS_SUB].SPLIT,                              
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANS_EC_NAME,                              
        [REPORT_CONSOLIDATED_TRANS_SUB].TRANS_EC_CPF_CNPJ                              
        ,[REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED]                              
        ,[REPORT_CONSOLIDATED_TRANS_SUB].[RETAINED_AMOUNT]                                 
        --, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE]                  
        ,IIF( [REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNED] = 1, [REPORT_CONSOLIDATED_TRANS_SUB].PREVISION_PAY_DATE, [REPORT_CONSOLIDATED_TRANS_SUB].[ORIGINAL_DATE] ) [ORIGINAL_DATE]              
        ,[REPORT_CONSOLIDATED_TRANS_SUB].[ASSIGNEE]                              
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_NAME_DESTINY                            
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TITTLE_DATE                            
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_TITTLE_TIME                         
        ,[REPORT_CONSOLIDATED_TRANS_SUB].AUTH_CODE                        
        ,[REPORT_CONSOLIDATED_TRANS_SUB].CREDITOR_DOCUMENT                        
       ,[REPORT_CONSOLIDATED_TRANS_SUB].ORDER_CODE                      
        ,CASE WHEN [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION_TITLE = @AwaitingSplit THEN 1 ELSE 0 END [AWAITINGSPLIT]                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].MODEL_POS                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].SEGMENT_EC                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].STATE_EC                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].CITY_EC                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].NEIGHBORHOOD_EC                  
        ,[REPORT_CONSOLIDATED_TRANS_SUB].COD_ADDRESS                
        ,[REPORT_CONSOLIDATED_TRANS_SUB].COD_ADDRESS                
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TYPE_TRAN                
        ,[REPORT_CONSOLIDATED_TRANS_SUB].NAME_PROD            
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_PROD            
        ,[REPORT_CONSOLIDATED_TRANS_SUB].EC_PROD_CPF_CNPJ            
        ,ISNULL([REPORT_CONSOLIDATED_TRANS_SUB].PERCENT_PARTICIP_SPLIT,0) PERCENT_PARTICIP_SPLIT           
        ,[REPORT_CONSOLIDATED_TRANS_SUB].IS_PLANDZERO          
        ,[REPORT_CONSOLIDATED_TRANS_SUB].TAX_PLANDZERO            
  ,[REPORT_CONSOLIDATED_TRANS_SUB].QTY_DAYS_ANTECIP          
  ,isnull([REPORT_CONSOLIDATED_TRANS_SUB].TAX_PLANDZERO_AFF, 0) TAX_PLANDZERO_AFF        
  ,[REPORT_CONSOLIDATED_TRANS_SUB].SALES_REPRESENTANTE      
  ,[REPORT_CONSOLIDATED_TRANS_SUB].CPF_CNPJ_REPRESENTANTE      
  ,[REPORT_CONSOLIDATED_TRANS_SUB].EMAIL_REPRESENTANTE      
  FROM [REPORT_CONSOLIDATED_TRANS_SUB]                                         
   WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_COMP = @CODCOMP                                                              
   AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_SITUATION = 3                                  
';


	IF @INITIAL_DATE IS NOT NULL
		AND @FINAL_DATE IS NOT NULL
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS,
		' AND [REPORT_CONSOLIDATED_TRANS_SUB].TRANSACTION_DATE BETWEEN @INITIAL_DATE AND @FINAL_DATE  ');

	IF @EC IS NOT NULL
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COD_EC = @EC ');
	IF @BRANCH IS NOT NULL
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, '  AND COD_BRANCH =  @BRANCH ');
	IF @DEPART IS NOT NULL
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COD_DEPTO_BRANCH =  @DEPART ');
	IF (@CODAFF IS NOT NULL)
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND COD_AFFILIATOR = @CodAff ');
	IF LEN(@BRAND) > 0
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND BRAND = @BRAND ');
	IF LEN(@NSU) > 0
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND CODE = @NSU ');
	IF @PAN IS NOT NULL
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND PAN = @PAN ');
	IF (@SPLIT = 1)
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND SPLIT = 1');

	IF (@ISPlanDZero = 1)
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, ' AND IS_PLANDZERO = 1');

	IF @COD_EC_PROD IS NOT NULL
		SET @QUERY_BASIS = CONCAT(@QUERY_BASIS, 'AND [REPORT_CONSOLIDATED_TRANS_SUB].COD_EC_PROD = @COD_EC_PROD');

	IF @CODACQUIRER IS NOT NULL
		SET @QUERY_BASIS =
		CONCAT(@QUERY_BASIS, ' AND ACQUIRER = (SELECT [NAME] FROM ACQUIRER WHERE COD_AC = @CODACQUIRER ) ');

	EXEC [sp_executesql] @QUERY_BASIS
						,N'                                 
           @CODCOMP VARCHAR(10),                         
           @INITIAL_DATE DATE,                         
           @FINAL_DATE DATE,                        
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
           @CODACQUIRER INT,                  
           @AwaitingSplit INT = NULL,
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
						,@CODACQUIRER = @CODACQUIRER
						,@AWAITINGSPLIT = @AWAITINGSPLIT
						,@COD_EC_PROD = @COD_EC_PROD;

END;


GO

SELECT
	[TRANSACTION_PRODUCTS].COD_EC
   ,TRANSACTION_TITLES.COD_TRAN AS COD_TITLE INTO #TEMP_PROD_CONSOLID
FROM [TRANSACTION] WITH (NOLOCK)
JOIN [TRANSACTION_PRODUCTS]
	ON TRANSACTION_PRODUCTS.COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
JOIN TRANSACTION_TITLES
	ON TRANSACTION_TITLES.COD_TRAN = [TRANSACTION].COD_TRAN


UPDATE REPORT_CONSOLIDATED_TRANS_SUB
SET COD_EC_PROD = #TEMP_PROD_CONSOLID.COD_EC
FROM REPORT_CONSOLIDATED_TRANS_SUB
JOIN #TEMP_PROD_CONSOLID
	ON #TEMP_PROD_CONSOLID.COD_TITLE = REPORT_CONSOLIDATED_TRANS_SUB.COD_TITLE


DROP TABLE #TEMP_PROD_CONSOLID

GO

IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'COD_EC_PROD'
		AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS'))
BEGIN
	ALTER TABLE REPORT_TRANSACTIONS
	ADD COD_EC_PROD INT
END


GO


IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'NAME_PROD'
		AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS'))
BEGIN
	ALTER TABLE REPORT_TRANSACTIONS
	ADD NAME_PROD VARCHAR(100)
END

GO


IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'EC_PROD'
		AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS'))
BEGIN
	ALTER TABLE REPORT_TRANSACTIONS
	ADD EC_PROD VARCHAR(100)
END

GO

IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'EC_PROD_CPF_CNPJ'
		AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS'))
BEGIN
	ALTER TABLE REPORT_TRANSACTIONS
	ADD EC_PROD_CPF_CNPJ VARCHAR(100)
END


GO

IF OBJECT_ID('VW_REPORT_TRANSACTIONS_PRCS') IS NOT NULL
	DROP VIEW [VW_REPORT_TRANSACTIONS_PRCS];
GO

CREATE VIEW [dbo].[VW_REPORT_TRANSACTIONS_PRCS]
/***********************************************************************************************************************************************          
----------------------------------------------------------------------------------------                                                                
Procedure Name: [VW_REPORT_TRANSACTIONS_PRCS]                                                                
Project.......: TKPP                                                                
------------------------------------------------------------------------------------------                                                                
Author                          VERSION        Date                            Description                                                                
------------------------------------------------------------------------------------------                                                                
Caike Uchôa                       v4         31-08-2020                        Add EC_PROD,CPF/CNPJ...     
------------------------------------------------------------------------------------------          
***********************************************************************************************************************************************/
AS
SELECT TOP (1000)
	[TRANSACTION].[COD_TRAN]
   ,[TRANSACTION].[CODE] AS [TRANSACTION_CODE]
   ,[TRANSACTION].[AMOUNT] AS [AMOUNT]
   ,[TRANSACTION].[PLOTS] AS [PLOTS]
   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].[CREATED_AT]) AS DATETIME) AS [TRANSACTION_DATE]
   ,[TRANSACTION_TYPE].[CODE] AS [TRANSACTION_TYPE]
   ,[TRANSACTION_TYPE].[COD_TTYPE] AS [TYPE_TRAN]
   ,[COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ]
   ,[COMMERCIAL_ESTABLISHMENT].[NAME]
   ,[EQUIPMENT].[SERIAL] AS [SERIAL_EQUIP]
   ,[EQUIPMENT].[TID] AS [TID]
   ,[TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION]
   ,[TRADUCTION_SITUATION].[COD_SITUATION]
   ,[TRANSACTION].[BRAND]
   ,[TRANSACTION_DATA_EXT].[VALUE] AS [NSU_EXT]
   ,[TRANSACTION].[PAN]
   ,[AFFILIATOR].[COD_AFFILIATOR]
   ,[AFFILIATOR].[NAME] AS [NAME_AFFILIATOR]
   ,[POSWEB_DATA_TRANSACTION].[TRACKING_TRANSACTION]
   ,[POSWEB_DATA_TRANSACTION].[DESCRIPTION] AS [DESCRIPTION]
   ,[REPORT_TRANSACTIONS].[COD_TRAN] AS [REP_COD_TRAN]
   ,[TRANSACTION].[COD_SOURCE_TRAN]
   ,[TRANSACTION].[CREATED_AT]
   ,[REPORT_TRANSACTIONS].[MODIFY_DATE]
   ,[COMPANY].[COD_COMP]
   ,[PRODUCTS_ACQUIRER].[COD_AC]
   ,[BRANCH_EC].[COD_EC]
   ,[TRANSACTION].[POSWEB]
   ,[BRANCH_EC].[COD_BRANCH]
   ,[EC_TRAN].[COD_EC] AS [COD_EC_TRANS]
   ,[EC_TRAN].[NAME] AS [TRANS_EC_NAME]
   ,[EC_TRAN].[CPF_CNPJ] AS [TRANS_EC_CPF_CNPJ]
   ,[SR].[COD_SALES_REP]
   ,[U].[IDENTIFICATION] AS [SALES_REP_NAME]
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM [TRANSACTION_SERVICES]
				WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
				AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
			> 0 THEN 1
		ELSE 0
	END AS [LINK_PAYMENT_SERVICE]
   ,[TRANSACTION].[CUSTOMER_EMAIL]
   ,[TRANSACTION].[CUSTOMER_IDENTIFICATION]
   ,CASE
		WHEN (SELECT
					COUNT(*)
				FROM [TRANSACTION_SERVICES]
				WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
				AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
			> 0 THEN [TRANSACTION].[TRACKING_TRANSACTION]
		ELSE NULL
	END AS [PAYMENT_LINK_TRACKING]
   ,TRAN_PROD.[NAME] AS [NAME_PROD]
   ,EC_PROD.[NAME] AS EC_PRODUTO
   ,EC_PROD.CPF_CNPJ AS [EC_PROD_CPF_CNPJ]
   ,EC_PROD.COD_EC AS COD_EC_PROD
FROM [TRANSACTION] WITH (NOLOCK)
INNER JOIN [dbo].[PROCESS_BG_STATUS]
	ON ([PROCESS_BG_STATUS].[CODE] = [TRANSACTION].[COD_TRAN])
INNER JOIN [ASS_DEPTO_EQUIP]
	ON [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL] = [TRANSACTION].[COD_ASS_DEPTO_TERMINAL]
INNER JOIN [EQUIPMENT]
	ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
INNER JOIN [DEPARTMENTS_BRANCH]
	ON [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] = [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH]
INNER JOIN [BRANCH_EC]
	ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
INNER JOIN [ASS_TAX_DEPART]
	ON [ASS_TAX_DEPART].[COD_ASS_TX_DEP] = [TRANSACTION].[COD_ASS_TX_DEP]
INNER JOIN [PLAN]
	ON [PLAN].[COD_PLAN] = [ASS_TAX_DEPART].[COD_PLAN]
INNER JOIN [COMMERCIAL_ESTABLISHMENT]
	ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [BRANCH_EC].[COD_EC]
INNER JOIN [COMPANY]
	ON [COMPANY].[COD_COMP] = [COMMERCIAL_ESTABLISHMENT].[COD_COMP]
INNER JOIN [TRANSACTION_TYPE]
	ON [TRANSACTION_TYPE].[COD_TTYPE] = [TRANSACTION].[COD_TTYPE]
INNER JOIN [SITUATION]
	ON [SITUATION].[COD_SITUATION] = [TRANSACTION].[COD_SITUATION]
INNER JOIN [TRADUCTION_SITUATION]
	ON [TRADUCTION_SITUATION].[COD_SITUATION] = [SITUATION].[COD_SITUATION]
LEFT JOIN [dbo].[REPORT_TRANSACTIONS]
	ON ([REPORT_TRANSACTIONS].[COD_TRAN] = [TRANSACTION].[COD_TRAN])
LEFT JOIN [TRANSACTION_DATA_EXT]
	ON [TRANSACTION_DATA_EXT].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
LEFT JOIN [AFFILIATOR]
	ON [AFFILIATOR].[COD_AFFILIATOR] = [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR]
LEFT JOIN [POSWEB_DATA_TRANSACTION]
	ON [POSWEB_DATA_TRANSACTION].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
LEFT JOIN [PRODUCTS_ACQUIRER]
	ON [PRODUCTS_ACQUIRER].[COD_PR_ACQ] = [TRANSACTION].[COD_PR_ACQ]
LEFT JOIN [COMMERCIAL_ESTABLISHMENT] AS [EC_TRAN] WITH (NOLOCK)
	ON [EC_TRAN].[COD_EC] = [TRANSACTION].[COD_EC]
LEFT JOIN [SALES_REPRESENTATIVE] AS [SR]
	ON [EC_TRAN].[COD_SALES_REP] = [SR].[COD_SALES_REP]
LEFT JOIN [USERS] AS [U]
	ON [SR].[COD_USER] = [U].[COD_USER]
LEFT JOIN TRANSACTION_PRODUCTS AS TRAN_PROD
	ON TRAN_PROD.COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
LEFT JOIN COMMERCIAL_ESTABLISHMENT EC_PROD
	ON EC_PROD.COD_EC = TRAN_PROD.COD_EC
WHERE [PROCESS_BG_STATUS].[STATUS_PROCESSED] = 0
AND [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 4
AND ISNULL([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
AND DATEADD(MINUTE, -2, GETDATE()) > [TRANSACTION].[CREATED_AT];


GO

IF OBJECT_ID('SP_REG_REPORT_TRANSACTIONS_PRCS') IS NOT NULL
	DROP PROCEDURE [SP_REG_REPORT_TRANSACTIONS_PRCS]
GO
CREATE PROCEDURE [dbo].[SP_REG_REPORT_TRANSACTIONS_PRCS]

/*****************************************************************************************************************    
----------------------------------------------------------------------------------------                            
Procedure Name: [SP_REG_REPORT_TRANSACTIONS_PRCS]                            
Project.......: TKPP                            
------------------------------------------------------------------------------------------                            
Author                          VERSION        Date                            Description                            
------------------------------------------------------------------------------------------                            
LUCAS AGUIAR                      V1        16/01/2019                          Creation                    
LUCAS AGUIAR                      V2        23-04-2019                         ROTINA SPLIT       
Caike Uchôa                       V3        12-08-2020                         ADD AMOUNT_NEW  
Caike Uchôa                       V4        31-08-2020                         Add EC_PROD, CPF_CNPJ...  
------------------------------------------------------------------------------------------    
*****************************************************************************************************************/

AS
BEGIN
	DECLARE @COUNT INT = 0;




	BEGIN

		---------------------------------------------                          
		--------------RECORDS INSERT-----------------                          
		---------------------------------------------                         

		SELECT
			[VW_REPORT_TRANSACTIONS_PRCS].[COD_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_AC]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_COMP]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SOURCE_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[POSWEB]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANSACTION_CODE]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[AMOUNT]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[PLOTS]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANSACTION_DATE]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANSACTION_TYPE]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TYPE_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[CPF_CNPJ]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[NAME]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_EC]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[SERIAL_EQUIP]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TID]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[BRAND]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[NSU_EXT]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[PAN]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_AFFILIATOR]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[NAME_AFFILIATOR]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRACKING_TRANSACTION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[DESCRIPTION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_EC_TRANS]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANS_EC_NAME]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[TRANS_EC_CPF_CNPJ]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SALES_REP]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[CREATED_AT]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[SALES_REP_NAME]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[LINK_PAYMENT_SERVICE]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[CUSTOMER_EMAIL]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[CUSTOMER_IDENTIFICATION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[PAYMENT_LINK_TRACKING]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[NAME_PROD]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].EC_PRODUTO
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[EC_PROD_CPF_CNPJ]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].COD_EC_PROD INTO [#TB_REPORT_TRANSACTIONS_PRCS_INSERT]
		FROM [dbo].[VW_REPORT_TRANSACTIONS_PRCS]
		WHERE [VW_REPORT_TRANSACTIONS_PRCS].[REP_COD_TRAN] IS NULL;

		SELECT
			@COUNT = COUNT(*)
		FROM [#TB_REPORT_TRANSACTIONS_PRCS_INSERT];

		IF @COUNT > 0
		BEGIN
			INSERT INTO [dbo].[REPORT_TRANSACTIONS] ([COD_TRAN],
			[COD_AC],
			[COD_COMP],
			[COD_SOURCE_TRAN],
			[POSWEB],
			[TRANSACTION_CODE],
			[TYPE_TRAN],
			[AMOUNT],
			[PLOTS],
			[TRANSACTION_DATE],
			[TRANSACTION_TYPE],
			[CPF_CNPJ],
			[NAME],
			[COD_EC],
			[SERIAL_EQUIP],
			[TID],
			[SITUATION],
			[COD_SITUATION],
			[BRAND],
			[NSU_EXT],
			[PAN],
			[COD_AFFILIATOR],
			[NAME_AFFILIATOR],
			[TRACKING_TRANSACTION],
			[DESCRIPTION],
			[COD_EC_TRANS],
			[TRANS_EC_NAME],
			[TRANS_EC_CPF_CNPJ],
			[CREATED_AT],
			[MODIFY_DATE],
			[COD_SALE_REP],
			[SALES_REPRESENTATIVE],
			[LINK_PAYMENT_SERVICE],
			[CUSTOMER_EMAIL], [CUSTOMER_IDENTIFICATION],
			[PAYMENT_LINK_TRACKING],
			[NAME_PROD],
			[EC_PROD],
			[EC_PROD_CPF_CNPJ],
			[COD_EC_PROD])
				SELECT
					[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_TRAN]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_AC]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_COMP]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_SOURCE_TRAN]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[POSWEB]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANSACTION_CODE]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TYPE_TRAN]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[AMOUNT]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[PLOTS]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANSACTION_DATE]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANSACTION_TYPE]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CPF_CNPJ]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NAME]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_EC]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[SERIAL_EQUIP]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TID]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[SITUATION]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_SITUATION]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[BRAND]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NSU_EXT]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[PAN]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_AFFILIATOR]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NAME_AFFILIATOR]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRACKING_TRANSACTION]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[DESCRIPTION]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_EC_TRANS]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANS_EC_NAME]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[TRANS_EC_CPF_CNPJ]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CREATED_AT]
				   ,GETDATE()
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_SALES_REP]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[SALES_REP_NAME]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[LINK_PAYMENT_SERVICE]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CUSTOMER_EMAIL]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[CUSTOMER_IDENTIFICATION]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[PAYMENT_LINK_TRACKING]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[NAME_PROD]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[EC_PRODUTO]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[EC_PROD_CPF_CNPJ]
				   ,[#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_EC_PROD]
				FROM [#TB_REPORT_TRANSACTIONS_PRCS_INSERT];

			IF @@rowcount < 1
				THROW 60000, 'COULD NOT REGISTER [REPORT_TRANSACTIONS_EXP] ', 1;

			UPDATE [PROCESS_BG_STATUS]
			SET [STATUS_PROCESSED] = 1
			   ,[MODIFY_DATE] = GETDATE()
			FROM [PROCESS_BG_STATUS]
			INNER JOIN [#TB_REPORT_TRANSACTIONS_PRCS_INSERT]
				ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_PRCS_INSERT].[COD_TRAN])
			WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 4;

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](INSERT)', 1;
		END;


		---------------------------------------------                          
		--------------RECORDS UPDATE-----------------                          
		---------------------------------------------                            
		SELECT
			[VW_REPORT_TRANSACTIONS_PRCS].[COD_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[COD_SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_PRCS].[AMOUNT] INTO [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
		FROM [dbo].[VW_REPORT_TRANSACTIONS_PRCS]
		WHERE [VW_REPORT_TRANSACTIONS_PRCS].[REP_COD_TRAN] IS NOT NULL;

		SELECT
			@COUNT = COUNT(*)
		FROM [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE];

		IF @COUNT > 0
		BEGIN
			UPDATE [REPORT_TRANSACTIONS]
			SET [REPORT_TRANSACTIONS].[SITUATION] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[SITUATION]
			   ,[REPORT_TRANSACTIONS].[COD_SITUATION] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[COD_SITUATION]
			   ,[REPORT_TRANSACTIONS].[MODIFY_DATE] = GETDATE()
			   ,[REPORT_TRANSACTIONS].AMOUNT = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[AMOUNT]
			FROM [REPORT_TRANSACTIONS]
			INNER JOIN [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
				ON ([REPORT_TRANSACTIONS].[COD_TRAN] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[COD_TRAN]);

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [REPORT_TRANSACTIONS_EX]', 1;

			UPDATE [PROCESS_BG_STATUS]
			SET [STATUS_PROCESSED] = 1
			   ,[MODIFY_DATE] = GETDATE()
			FROM [PROCESS_BG_STATUS]
			INNER JOIN [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE]
				ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_PRCS_UPDATE].[COD_TRAN])
			WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 4;

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](UPDATE)', 1;
		END;


	END;
END;


GO

IF OBJECT_ID('[SP_REPORT_TRANSACTIONS_PAGE]') IS NOT NULL
	DROP PROCEDURE [SP_REPORT_TRANSACTIONS_PAGE]
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
   @TERMINAL varchar(14),                                                              
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
   @TERMINAL varchar(14),                                                              
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


SELECT
	COMMERCIAL_ESTABLISHMENT.[NAME] AS EC
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,TRANSACTION_PRODUCTS.[NAME] AS TRAN_PROD
   ,COMMERCIAL_ESTABLISHMENT.COD_EC
   ,[TRANSACTION].COD_TRAN AS COD_TRAN INTO #TEMP_PRODS
FROM [TRANSACTION] WITH (NOLOCK)
JOIN [TRANSACTION_PRODUCTS]
	ON TRANSACTION_PRODUCTS.COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = TRANSACTION_PRODUCTS.COD_EC


UPDATE REPORT_TRANSACTIONS
SET NAME_PROD = #TEMP_PRODS.TRAN_PROD
   ,EC_PROD_CPF_CNPJ = #TEMP_PRODS.CPF_CNPJ
   ,EC_PROD = #TEMP_PRODS.EC
   ,COD_EC_PROD = #TEMP_PRODS.COD_EC
FROM REPORT_TRANSACTIONS
JOIN #TEMP_PRODS
	ON #TEMP_PRODS.COD_TRAN = REPORT_TRANSACTIONS.COD_TRAN


DROP TABLE #TEMP_PRODS


GO

IF NOT EXISTS (SELECT
			1
		FROM sys.columns
		WHERE NAME = N'COD_EC_PROD'
		AND object_id = OBJECT_ID(N'REPORT_TRANSACTIONS_EXP'))
BEGIN
	ALTER TABLE REPORT_TRANSACTIONS_EXP
	ADD COD_EC_PROD INT
END


GO

IF OBJECT_ID('VW_REPORT_TRANSACTIONS_EXP') IS NOT NULL
	DROP VIEW [VW_REPORT_TRANSACTIONS_EXP]
GO
CREATE VIEW [dbo].[VW_REPORT_TRANSACTIONS_EXP]
AS
/*----------------------------------------------------------------------------------------                                      
Procedure Name: [VW_REPORT_TRANSACTIONS_EXP]                                      
Project.......: TKPP                                      
------------------------------------------------------------------------------------------                                      
Author                          VERSION        Date                            Description                                      
------------------------------------------------------------------------------------------                                      
Marcus Gall                        V1       28/11/2019             Add Model_POS, Segment, Location EC                            
Caike Uch�a                        v2       10/01/2020                         add CNAE                  
Kennedy Alef                       v3       08/04/2020                      add link de pagamento            
Caike Uch�a                        v4       30/04/2020                        insert ec prod            
Caike Uch�a                        v5       17/08/2020                        Add SALES_TYPE 
Luiz Aquino                        v6       01/07/2020                        Add PlanDZero
Caike Uchoa                        v7       31/08/2020                        Add cod_ec_prod
Kennedy Alef                       v8       02/09/2020                        Add change calculations       
------------------------------------------------------------------------------------------*/
WITH CTE
AS
(SELECT TOP (1000)
		[TRANSACTION].[COD_TRAN]
	   ,[TRANSACTION].[CODE] AS [TRANSACTION_CODE]
	   ,[TRANSACTION].[AMOUNT] AS [AMOUNT]
	   ,[TRANSACTION].[PLOTS] AS [PLOTS]
	   ,CAST([dbo].[FN_FUS_UTF]([TRANSACTION].[CREATED_AT]) AS DATETIME) AS [TRANSACTION_DATE]
	   ,[TRANSACTION_TYPE].[CODE] AS [TRANSACTION_TYPE]
	   ,[COMMERCIAL_ESTABLISHMENT].[CPF_CNPJ]
	   ,[COMMERCIAL_ESTABLISHMENT].[NAME]
	   ,[EQUIPMENT].[SERIAL] AS [SERIAL_EQUIP]
	   ,[EQUIPMENT].[TID] AS [TID]
	   ,[TRADUCTION_SITUATION].[SITUATION_TR] AS [SITUATION]
	   ,[TRANSACTION].[BRAND]
	   ,[TRANSACTION].[PAN]
	   ,[TRANSACTION_DATA_EXT].[NAME] AS [TRAN_DATA_EXT]
	   , --TRANSACTION_DATA_EXT.NAME                                          
		[TRANSACTION_DATA_EXT].[VALUE] AS [TRAN_DATA_EXT_VALUE]
	   , --TRANSACTION_DATA_EXT.VALUE                                         
		(SELECT
				[TRANSACTION_DATA_EXT].[VALUE]
			FROM [TRANSACTION_DATA_EXT] WITH (NOLOCK)
			WHERE [TRANSACTION_DATA_EXT].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
			AND [TRANSACTION_DATA_EXT].[NAME] = 'AUTHCODE')
		AS [AUTH_CODE]
	   ,[ACQUIRER].[COD_AC]
	   ,[ACQUIRER].[NAME] AS [NAME_ACQUIRER]
	   ,[TRANSACTION].[COMMENT] AS [COMMENT]
	   ,[ASS_TAX_DEPART].[PARCENTAGE] AS [TAX]
	   ,COALESCE([ASS_TAX_DEPART].[ANTICIPATION_PERCENTAGE], 0) AS [ANTICIPATION]
	   ,[AFFILIATOR].[COD_AFFILIATOR]
	   ,[AFFILIATOR].[NAME] AS [NAME_AFFILIATOR]
	   ,(CASE
			WHEN [SITUATION].[COD_SITUATION] = 3 AND
				[PLAN].[COD_T_PLAN] = 2 THEN ([dbo].[FNC_ANT_VALUE_LIQ_TRAN]([TRANSACTION].[AMOUNT], [ASS_TAX_DEPART].[PARCENTAGE], [TRANSACTION].[PLOTS], [ASS_TAX_DEPART].[ANTICIPATION_PERCENTAGE]) - [ASS_TAX_DEPART].[RATE])
			WHEN [SITUATION].[COD_SITUATION] = 3 AND
				[PLAN].[COD_T_PLAN] = 1 THEN ([dbo].[FNC_ANT_VALUE_LIQ_TRAN]([TRANSACTION].[AMOUNT], [ASS_TAX_DEPART].[PARCENTAGE], [TRANSACTION].[PLOTS], 0) - [ASS_TAX_DEPART].[RATE])
			ELSE 0
		END) AS [NET_VALUE]
	   ,
		--  ,        
		--------------******------------                                          
		[TRANSACTION].[COD_TTYPE]
	   ,[COMPANY].[COD_COMP]
	   ,[BRANCH_EC].[COD_EC]
	   ,[BRANCH_EC].[COD_BRANCH]
	   ,[STATE].[NAME] AS [STATE_NAME]
	   ,[CITY].[NAME] AS [CITY_NAME]
	   ,[SITUATION].[COD_SITUATION]
	   ,[DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH]
	   ,COALESCE([POSWEB_DATA_TRANSACTION].[AMOUNT], 0) AS [GROSS_VALUE_AGENCY]
	   ,COALESCE([dbo].[FNC_ANT_VALUE_LIQ_TRAN]([POSWEB_DATA_TRANSACTION].[AMOUNT], [POSWEB_DATA_TRANSACTION].[MDR], [POSWEB_DATA_TRANSACTION].[PLOTS], [POSWEB_DATA_TRANSACTION].[ANTICIPATION]) - [POSWEB_DATA_TRANSACTION].[TARIFF], 0) AS [NET_VALUE_AGENCY]



	   ,[SOURCE_TRANSACTION].[DESCRIPTION] AS [TYPE_TRAN]
	   ,[TRANSACTION].[COD_SOURCE_TRAN]
	   ,COALESCE([TRANSACTION].[POSWEB], 0) AS [POSWEB]
	   ,[SEGMENTS].[NAME] AS [SEGMENTS_NAME]
	   ,[TRANSACTION].[CREATED_AT]
	   ,[REPORT_TRANSACTIONS_EXP].[COD_TRAN] AS [REP_COD_TRAN]
	   ,[EC_TRAN].[COD_EC] AS [COD_EC_TRANS]
	   ,[EC_TRAN].[NAME] AS [TRANS_EC_NAME]
	   ,[EC_TRAN].[CPF_CNPJ] AS [TRANS_EC_CPF_CNPJ]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM [TRANSACTION_SERVICES]
					WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
					AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 4)
				> 0 THEN 1
			ELSE 0
		END AS [SPLIT]
	   ,[USERS].[IDENTIFICATION] AS [SALES_REP]
	   ,[USERS].[COD_USER] AS [COD_USER_REP]
	   ,COALESCE([TRANSACTION].[CREDITOR_DOCUMENT], 'NOT CREDITOR_DOCUMENT') AS [CREDITOR_DOCUMENT]
	   ,[SALES_REPRESENTATIVE].[COD_SALES_REP]
	   ,[EQUIPMENT_MODEL].[CODIGO] AS [MODEL_POS]
	   ,[TRANSACTION].[CARD_HOLDER_NAME] AS [CARD_NAME]
	   ,[SEGMENTS].[CNAE]
	   ,[TRANSACTION].[COD_USER]
	   ,[USER_TRAN].[IDENTIFICATION] AS [NAME_USER]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM [TRANSACTION_SERVICES]
					WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
					AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
				> 0 THEN 1
			ELSE 0
		END AS [LINK_PAYMENT]
	   ,[TRANSACTION].[CUSTOMER_EMAIL]
	   ,[TRANSACTION].[CUSTOMER_IDENTIFICATION]
	   ,CASE
			WHEN (SELECT
						COUNT(*)
					FROM [TRANSACTION_SERVICES]
					WHERE [TRANSACTION_SERVICES].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
					AND [TRANSACTION_SERVICES].[COD_ITEM_SERVICE] = 10)
				> 0 THEN [TRANSACTION].[TRACKING_TRANSACTION]
			ELSE NULL
		END AS [PAYMENT_LINK_TRACKING]
	   ,[TRAN_PROD].[NAME] AS [NAME_PRODUCT_EC]
	   ,[EC_PROD].[NAME] AS [EC_PRODUCT]
	   ,[EC_PROD].CPF_CNPJ AS [EC_PRODUCT_CPF_CNPJ]
	   ,[PROD_ACQ].[NAME] AS [SALES_TYPE]
	   ,(SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_EC
			FROM TRANSACTION_SERVICES WITH (NOLOCK)
			INNER JOIN ITEMS_SERVICES_AVAILABLE isa
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = isa.COD_ITEM_SERVICE
			WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
			AND isa.NAME = 'PlanDZero')
		AS PLAN_DZEROEC
	   ,(SELECT
				TRANSACTION_SERVICES.TAX_PLANDZERO_AFF
			FROM TRANSACTION_SERVICES WITH (NOLOCK)
			INNER JOIN ITEMS_SERVICES_AVAILABLE isa
				ON TRANSACTION_SERVICES.COD_ITEM_SERVICE = isa.COD_ITEM_SERVICE
			WHERE TRANSACTION_SERVICES.COD_TRAN = [TRANSACTION].COD_TRAN
			AND isa.NAME = 'PlanDZero')
		AS PLAN_DZEROAFF
	   ,[EC_PROD].COD_EC AS [COD_EC_PROD]
	FROM [TRANSACTION] WITH (NOLOCK)
	LEFT JOIN [dbo].[PROCESS_BG_STATUS]
		ON ([PROCESS_BG_STATUS].[CODE] = [TRANSACTION].[COD_TRAN])
	LEFT JOIN [ASS_DEPTO_EQUIP]
		ON [ASS_DEPTO_EQUIP].[COD_ASS_DEPTO_TERMINAL] = [TRANSACTION].[COD_ASS_DEPTO_TERMINAL]
	LEFT JOIN [EQUIPMENT]
		ON [EQUIPMENT].[COD_EQUIP] = [ASS_DEPTO_EQUIP].[COD_EQUIP]
	LEFT JOIN [DEPARTMENTS_BRANCH]
		ON [DEPARTMENTS_BRANCH].[COD_DEPTO_BRANCH] = [ASS_DEPTO_EQUIP].[COD_DEPTO_BRANCH]
	LEFT JOIN [DEPARTMENTS]
		ON [DEPARTMENTS].[COD_DEPARTS] = [DEPARTMENTS_BRANCH].[COD_DEPARTS]
	LEFT JOIN [BRANCH_EC]
		ON [BRANCH_EC].[COD_BRANCH] = [DEPARTMENTS_BRANCH].[COD_BRANCH]
	LEFT JOIN [ADDRESS_BRANCH]
		ON [ADDRESS_BRANCH].[COD_BRANCH] = [BRANCH_EC].[COD_BRANCH]
	LEFT JOIN [NEIGHBORHOOD]
		ON [NEIGHBORHOOD].[COD_NEIGH] = [ADDRESS_BRANCH].[COD_NEIGH]
	LEFT JOIN [ASS_TAX_DEPART]
		ON [ASS_TAX_DEPART].[COD_ASS_TX_DEP] = [TRANSACTION].[COD_ASS_TX_DEP]
	LEFT JOIN [PLAN]
		ON [PLAN].[COD_PLAN] = [ASS_TAX_DEPART].[COD_PLAN]
	LEFT JOIN [CITY]
		ON [CITY].[COD_CITY] = [NEIGHBORHOOD].[COD_CITY]
	LEFT JOIN [STATE]
		ON [STATE].[COD_STATE] = [CITY].[COD_STATE]
	LEFT JOIN [COMMERCIAL_ESTABLISHMENT]
		ON [COMMERCIAL_ESTABLISHMENT].[COD_EC] = [BRANCH_EC].[COD_EC]
	LEFT JOIN [COMPANY]
		ON [COMPANY].[COD_COMP] = [COMMERCIAL_ESTABLISHMENT].[COD_COMP]
	LEFT JOIN [TRANSACTION_TYPE]
		ON [TRANSACTION_TYPE].[COD_TTYPE] = [TRANSACTION].[COD_TTYPE]
	LEFT JOIN [SITUATION]
		ON [SITUATION].[COD_SITUATION] = [TRANSACTION].[COD_SITUATION]
	LEFT JOIN [TRADUCTION_SITUATION]
		ON [TRADUCTION_SITUATION].[COD_SITUATION] = [SITUATION].[COD_SITUATION]
	LEFT JOIN [SEGMENTS]
		ON [SEGMENTS].[COD_SEG] = [COMMERCIAL_ESTABLISHMENT].[COD_SEG]
	LEFT JOIN [dbo].[REPORT_TRANSACTIONS_EXP]
		ON ([REPORT_TRANSACTIONS_EXP].[COD_TRAN] = [TRANSACTION].[COD_TRAN])
	LEFT JOIN [TRANSACTION_DATA_EXT] WITH (NOLOCK)
		ON [TRANSACTION_DATA_EXT].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
	LEFT JOIN [AFFILIATOR]
		ON [AFFILIATOR].[COD_AFFILIATOR] = [COMMERCIAL_ESTABLISHMENT].[COD_AFFILIATOR]
	LEFT JOIN [POSWEB_DATA_TRANSACTION]
		ON [POSWEB_DATA_TRANSACTION].[COD_TRAN] = [TRANSACTION].[COD_TRAN]
	LEFT JOIN [dbo].[SOURCE_TRANSACTION] WITH (NOLOCK)
		ON ([SOURCE_TRANSACTION].[COD_SOURCE_TRAN] = [TRANSACTION].[COD_SOURCE_TRAN])
	LEFT JOIN [COMMERCIAL_ESTABLISHMENT] AS [EC_TRAN] WITH (NOLOCK)
		ON [EC_TRAN].[COD_EC] = [TRANSACTION].[COD_EC]
	LEFT JOIN [SALES_REPRESENTATIVE]
		ON [SALES_REPRESENTATIVE].[COD_SALES_REP] = [COMMERCIAL_ESTABLISHMENT].[COD_SALES_REP]
	LEFT JOIN [USERS]
		ON [USERS].[COD_USER] = [SALES_REPRESENTATIVE].[COD_USER]
	LEFT JOIN [USERS] AS [USER_TRAN]
		ON [USER_TRAN].[COD_USER] = [TRANSACTION].[COD_USER]
	LEFT JOIN [ASS_TR_TYPE_COMP]
		ON [ASS_TR_TYPE_COMP].[COD_ASS_TR_COMP] = [TRANSACTION].[COD_ASS_TR_COMP]
	LEFT JOIN [ACQUIRER]
		ON [ACQUIRER].[COD_AC] = [ASS_TR_TYPE_COMP].[COD_AC]
	LEFT JOIN [EQUIPMENT_MODEL] WITH (NOLOCK)
		ON [EQUIPMENT_MODEL].[COD_MODEL] = [EQUIPMENT].[COD_MODEL]
	LEFT JOIN TRANSACTION_PRODUCTS AS [TRAN_PROD] WITH (NOLOCK)
		ON [TRAN_PROD].COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
	LEFT JOIN COMMERCIAL_ESTABLISHMENT AS [EC_PROD] WITH (NOLOCK)
		ON [EC_PROD].COD_EC = [TRAN_PROD].COD_EC
	LEFT JOIN PRODUCTS_ACQUIRER AS [PROD_ACQ] WITH (NOLOCK)
		ON [PROD_ACQ].COD_PR_ACQ = [TRANSACTION].COD_PR_ACQ
	WHERE [ADDRESS_BRANCH].[ACTIVE] = 1
	AND [PROCESS_BG_STATUS].[STATUS_PROCESSED] = 0
	AND [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 1
	AND COALESCE([TRANSACTION_DATA_EXT].[NAME], '0') IN ('NSU', 'RCPTTXID', 'AUTO', '0')
	AND DATEADD(MINUTE, -5, GETDATE()) > [TRANSACTION].[CREATED_AT])

SELECT
	CTE.COD_TRAN
   ,CTE.TRANSACTION_CODE
   ,CTE.AMOUNT
   ,CTE.PLOTS
   ,CTE.TRANSACTION_DATE
   ,CTE.TRANSACTION_TYPE
   ,CTE.CPF_CNPJ
   ,CTE.[NAME]
   ,CTE.SERIAL_EQUIP
   ,CTE.TID
   ,CTE.SITUATION
   ,CTE.BRAND
   ,CTE.PAN
   ,CTE.TRAN_DATA_EXT
   ,CTE.TRAN_DATA_EXT_VALUE
   ,CTE.AUTH_CODE
   ,CTE.COD_AC
   ,CTE.NAME_ACQUIRER
   ,CTE.COMMENT
   ,CTE.TAX
   ,CTE.ANTICIPATION
   ,CTE.COD_AFFILIATOR
   ,CTE.NAME_AFFILIATOR
   ,CTE.COD_TTYPE
   ,CTE.COD_COMP
   ,CTE.COD_EC
   ,CTE.COD_BRANCH
   ,CTE.STATE_NAME
   ,CTE.CITY_NAME
   ,CTE.COD_SITUATION
   ,CTE.COD_DEPTO_BRANCH
   ,CTE.GROSS_VALUE_AGENCY
   ,CTE.NET_VALUE_AGENCY
   ,CTE.TYPE_TRAN
   ,CTE.COD_SOURCE_TRAN
   ,CTE.POSWEB
   ,CTE.SEGMENTS_NAME
   ,CTE.CREATED_AT
   ,CTE.REP_COD_TRAN
   ,CTE.COD_EC_TRANS
   ,CTE.TRANS_EC_NAME
   ,CTE.TRANS_EC_CPF_CNPJ
   ,CTE.SPLIT
   ,CTE.SALES_REP
   ,CTE.COD_USER_REP
   ,CTE.CREDITOR_DOCUMENT
   ,CTE.COD_SALES_REP
   ,CTE.MODEL_POS
   ,CTE.CARD_NAME
   ,CTE.CNAE
   ,CTE.COD_USER
   ,CTE.NAME_USER
   ,CTE.LINK_PAYMENT
   ,CTE.CUSTOMER_EMAIL
   ,CTE.CUSTOMER_IDENTIFICATION
   ,CTE.PAYMENT_LINK_TRACKING
   ,CTE.NAME_PRODUCT_EC
   ,CTE.EC_PRODUCT
   ,CTE.EC_PRODUCT_CPF_CNPJ
   ,CTE.SALES_TYPE
   ,CTE.PLAN_DZEROEC
   ,CTE.PLAN_DZEROAFF
   ,CTE.NET_VALUE
   ,CTE.COD_EC_PROD

FROM CTE

GO


IF OBJECT_ID('SP_REG_REPORT_TRANSACTIONS_EXP') IS NOT NULL
	DROP PROCEDURE [SP_REG_REPORT_TRANSACTIONS_EXP]
GO


CREATE PROCEDURE [dbo].[SP_REG_REPORT_TRANSACTIONS_EXP]

/*****************************************************************************************************************            
----------------------------------------------------------------------------------------                                  
 Procedure Name: [SP_REG_REPORT_TRANSACTIONS_EXP]                                  
 Project.......: TKPP                                  
 ------------------------------------------------------------------------------------------                                  
 Author                          VERSION        Date                            Description                                  
 ------------------------------------------------------------------------------------------                                  
 Fernando Henrique F.             V1       13/12/2018                          Creation                                   
 Lucas Aguiar                     V2       23-04-2019                      ROTINA DE SPLIT                            
 Caike Uch�a                      V3       15/08/2019                       inserting coluns                          
 Marcus Gall                      V4       28/11/2019              Add Model_POS, Segment, Location EC                        
 Caike Uch�a                      V5       20/01/2020                            ADD CNAE            
 Kennedy Alef                     v6       08/04/2020                      add link de pagamento          
 Caike Uch�a                      v7       30/04/2020                        insert ec prod          
 Caike Uch�a                      V8       06/08/2020                    Add [AMOUNT] to reprocess        
 Caike Uch�a                      V9       17/08/2020                        Add SALES_TYPE    
 Luiz Aquino                      v10      01/07/2020                         add PlanDzero
 Caike Uchoa                      V10      31/08/2020                        Add Cod_ec_prod
 ------------------------------------------------------------------------------------------            
*****************************************************************************************************************/

AS
BEGIN

	DECLARE @COUNT INT = 0;





	BEGIN

		---------------------------------------------                                
		--------------RECORDS INSERT-----------------                                
		---------------------------------------------                                  
		SELECT
			[VW_REPORT_TRANSACTIONS_EXP].[COD_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANSACTION_CODE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[AMOUNT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[PLOTS]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANSACTION_DATE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANSACTION_TYPE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CPF_CNPJ]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SERIAL_EQUIP]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TID]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[BRAND]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[PAN]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRAN_DATA_EXT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRAN_DATA_EXT_VALUE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[AUTH_CODE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_AC]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_ACQUIRER]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COMMENT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TAX]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[ANTICIPATION]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_AFFILIATOR]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_AFFILIATOR]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NET_VALUE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_COMP]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_EC]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_BRANCH]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[STATE_NAME]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CITY_NAME]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_DEPTO_BRANCH]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[GROSS_VALUE_AGENCY]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NET_VALUE_AGENCY]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TYPE_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SOURCE_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[POSWEB]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SEGMENTS_NAME]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_EC_TRANS]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANS_EC_NAME]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[TRANS_EC_CPF_CNPJ]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SPLIT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CREATED_AT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SALES_REP]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_USER_REP]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CREDITOR_DOCUMENT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SALES_REP]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[MODEL_POS]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CARD_NAME]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CNAE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_USER]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_USER]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[LINK_PAYMENT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CUSTOMER_EMAIL]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[CUSTOMER_IDENTIFICATION]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[PAYMENT_LINK_TRACKING]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_PRODUCT_EC]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[EC_PRODUCT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[EC_PRODUCT_CPF_CNPJ]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SALES_TYPE]
		   ,[VW_REPORT_TRANSACTIONS_EXP].PLAN_DZEROEC
		   ,[VW_REPORT_TRANSACTIONS_EXP].PLAN_DZEROAFF
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_EC_PROD] INTO [#TB_REPORT_TRANSACTIONS_EXP_INSERT]
		FROM [dbo].[VW_REPORT_TRANSACTIONS_EXP]
		WHERE [VW_REPORT_TRANSACTIONS_EXP].[REP_COD_TRAN] IS NULL;

		SELECT
			@COUNT = COUNT(*)
		FROM [#TB_REPORT_TRANSACTIONS_EXP_INSERT];

		IF @COUNT > 0
		BEGIN
			INSERT INTO [dbo].[REPORT_TRANSACTIONS_EXP] ([COD_TRAN],
			[TRANSACTION_CODE],
			[AMOUNT],
			[PLOTS],
			[TRANSACTION_DATE],
			[TRANSACTION_TYPE],
			[CPF_CNPJ],
			[NAME],
			[SERIAL_EQUIP],
			[TID],
			[SITUATION],
			[BRAND],
			[PAN],
			[TRAN_DATA_EXT],
			[TRAN_DATA_EXT_VALUE],
			[AUTH_CODE],
			[COD_AC],
			[NAME_ACQUIRER],
			[COMMENT],
			[TAX],
			[ANTICIPATION],
			[COD_AFFILIATOR],
			[NAME_AFFILIATOR],
			[NET_VALUE],
			[COD_COMP],
			[COD_EC],
			[COD_BRANCH],
			[STATE_NAME],
			[CITY_NAME],
			[COD_SITUATION],
			[COD_DEPTO_BRANCH],
			[GROSS_VALUE_AGENCY],
			[NET_VALUE_AGENCY],
			[TYPE_TRAN],
			[COD_SOURCE_TRAN],
			[POSWEB],
			[SEGMENTS_NAME],
			[CREATED_TRANSACTION_DATE],
			[COD_EC_TRANS],
			[TRANS_EC_NAME],
			[TRANS_EC_CPF_CNPJ],
			[SPLIT],
			[SALES_REP],
			[COD_USER_REP],
			[MODIFY_DATE],
			[CREDITOR_DOCUMENT],
			[COD_SALES_REP],
			[MODEL_POS],
			[CARD_NAME],
			[CNAE],
			[COD_USER],
			[NAME_USER],
			[LINK_PAYMENT_SERVICE],
			[CUSTOMER_EMAIL],
			[CUSTOMER_IDENTIFICATION],
			[PAYMENT_LINK_TRACKING],
			[NAME_PRODUCT_EC],
			[EC_PRODUCT],
			[EC_PRODUCT_CPF_CNPJ],
			[SALES_TYPE],
			DZERO_EC_TAX,
			DZERO_AFF_TAX,
			[COD_EC_PROD])
				(SELECT
					[TEMP].[COD_TRAN]
				   ,[TEMP].[TRANSACTION_CODE]
				   ,[TEMP].[AMOUNT]
				   ,[TEMP].[PLOTS]
				   ,[TEMP].[TRANSACTION_DATE]
				   ,[TEMP].[TRANSACTION_TYPE]
				   ,[TEMP].[CPF_CNPJ]
				   ,[TEMP].[NAME]
				   ,[TEMP].[SERIAL_EQUIP]
				   ,[TEMP].[TID]
				   ,[TEMP].[SITUATION]
				   ,[TEMP].[BRAND]
				   ,[TEMP].[PAN]
				   ,[TEMP].[TRAN_DATA_EXT]
				   ,[TEMP].[TRAN_DATA_EXT_VALUE]
				   ,[TEMP].[AUTH_CODE]
				   ,[TEMP].[COD_AC]
				   ,[TEMP].[NAME_ACQUIRER]
				   ,[TEMP].[COMMENT]
				   ,[TEMP].[TAX]
				   ,[TEMP].[ANTICIPATION]
				   ,[TEMP].[COD_AFFILIATOR]
				   ,[TEMP].[NAME_AFFILIATOR]
				   ,[TEMP].[NET_VALUE]
				   ,[TEMP].[COD_COMP]
				   ,[TEMP].[COD_EC]
				   ,[TEMP].[COD_BRANCH]
				   ,[TEMP].[STATE_NAME]
				   ,[TEMP].[CITY_NAME]
				   ,[TEMP].[COD_SITUATION]
				   ,[TEMP].[COD_DEPTO_BRANCH]
				   ,[TEMP].[GROSS_VALUE_AGENCY]
				   ,[TEMP].[NET_VALUE_AGENCY]
				   ,[TEMP].[TYPE_TRAN]
				   ,[TEMP].[COD_SOURCE_TRAN]
				   ,[TEMP].[POSWEB]
				   ,[TEMP].[SEGMENTS_NAME]
				   ,[TEMP].[CREATED_AT]
				   ,[TEMP].[COD_EC_TRANS]
				   ,[TEMP].[TRANS_EC_NAME]
				   ,[TEMP].[TRANS_EC_CPF_CNPJ]
				   ,[TEMP].[SPLIT]
				   ,[SALES_REP]
				   ,[COD_USER_REP]
				   ,GETDATE()
				   ,[CREDITOR_DOCUMENT]
				   ,[COD_SALES_REP]
				   ,[TEMP].[MODEL_POS]
				   ,[CARD_NAME]
				   ,[CNAE]
				   ,[COD_USER]
				   ,[NAME_USER]
				   ,[LINK_PAYMENT]
				   ,[CUSTOMER_EMAIL]
				   ,[CUSTOMER_IDENTIFICATION]
				   ,[TEMP].[PAYMENT_LINK_TRACKING]
				   ,[TEMP].[NAME_PRODUCT_EC]
				   ,[TEMP].[EC_PRODUCT]
				   ,[TEMP].[EC_PRODUCT_CPF_CNPJ]
				   ,[TEMP].[SALES_TYPE]
				   ,[TEMP].PLAN_DZEROEC
				   ,[TEMP].PLAN_DZEROAFF
				   ,[TEMP].[COD_EC_PROD]
				FROM [#TB_REPORT_TRANSACTIONS_EXP_INSERT] AS [TEMP]);

			IF @@rowcount < 1
				THROW 60000, 'COULD NOT REGISTER [REPORT_TRANSACTIONS_EXP] ', 1;

			UPDATE [PROCESS_BG_STATUS]
			SET [STATUS_PROCESSED] = 1
			   ,[MODIFY_DATE] = GETDATE()
			FROM [PROCESS_BG_STATUS]
			INNER JOIN [#TB_REPORT_TRANSACTIONS_EXP_INSERT]
				ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_EXP_INSERT].[COD_TRAN])
			WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 1;

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](INSERT)', 1;
		END;


		---------------------------------------------                                
		--------------RECORDS UPDATE-----------------                                
		---------------------------------------------                                  
		SELECT
			[VW_REPORT_TRANSACTIONS_EXP].[COD_TRAN]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COMMENT]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_SITUATION]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[COD_USER]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[NAME_USER]
		   ,[VW_REPORT_TRANSACTIONS_EXP].[AMOUNT] INTO [#TB_REPORT_TRANSACTIONS_EXP_UPDATE]
		FROM [dbo].[VW_REPORT_TRANSACTIONS_EXP]
		WHERE [VW_REPORT_TRANSACTIONS_EXP].[REP_COD_TRAN] IS NOT NULL;

		SELECT
			@COUNT = COUNT(*)
		FROM [#TB_REPORT_TRANSACTIONS_EXP_UPDATE];

		IF @COUNT > 0
		BEGIN
			UPDATE [REPORT_TRANSACTIONS_EXP]
			SET [REPORT_TRANSACTIONS_EXP].[SITUATION] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[SITUATION]
			   ,[REPORT_TRANSACTIONS_EXP].[COD_SITUATION] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_SITUATION]
			   ,[REPORT_TRANSACTIONS_EXP].[COMMENT] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COMMENT]
			   ,[REPORT_TRANSACTIONS_EXP].[MODIFY_DATE] = GETDATE()
			   ,[REPORT_TRANSACTIONS_EXP].[COD_USER] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_USER]
			   ,[REPORT_TRANSACTIONS_EXP].[NAME_USER] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[NAME_USER]
			   ,[REPORT_TRANSACTIONS_EXP].[AMOUNT] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[AMOUNT]
			FROM [REPORT_TRANSACTIONS_EXP]
			INNER JOIN [#TB_REPORT_TRANSACTIONS_EXP_UPDATE]
				ON ([REPORT_TRANSACTIONS_EXP].[COD_TRAN] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_TRAN]);

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [REPORT_TRANSACTIONS_EX]', 1;

			UPDATE [PROCESS_BG_STATUS]
			SET [STATUS_PROCESSED] = 1
			   ,[MODIFY_DATE] = GETDATE()
			FROM [PROCESS_BG_STATUS]
			INNER JOIN [#TB_REPORT_TRANSACTIONS_EXP_UPDATE]
				ON ([PROCESS_BG_STATUS].[CODE] = [#TB_REPORT_TRANSACTIONS_EXP_UPDATE].[COD_TRAN])
			WHERE [PROCESS_BG_STATUS].[COD_SOURCE_PROCESS] = 1;

			IF @@rowcount < 1
				THROW 60001, 'COULD NOT UPDATE [PROCESS_BG_STATUS](UPDATE)', 1;
		END;
	END;
END;


GO

IF OBJECT_ID('SP_REPORT_TRANSACTIONS_EXP') IS NOT NULL
	DROP PROCEDURE [SP_REPORT_TRANSACTIONS_EXP]
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
   @TERMINAL varchar(14),            
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

GO

SELECT
	COMMERCIAL_ESTABLISHMENT.COD_EC
   ,[TRANSACTION].COD_TRAN AS COD_TRAN INTO #TEMP_PROD
FROM [TRANSACTION] WITH (NOLOCK)
JOIN [TRANSACTION_PRODUCTS]
	ON TRANSACTION_PRODUCTS.COD_TRAN_PROD = [TRANSACTION].COD_TRAN_PROD
JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = TRANSACTION_PRODUCTS.COD_EC


UPDATE REPORT_TRANSACTIONS_EXP
SET COD_EC_PROD = #TEMP_PROD.COD_EC
FROM REPORT_TRANSACTIONS_EXP
JOIN #TEMP_PROD
	ON #TEMP_PROD.COD_TRAN = REPORT_TRANSACTIONS_EXP.COD_TRAN


DROP TABLE #TEMP_PROD



GO


--begin tran
--SELECT @@trancount

SELECT
	[TRANSACTION_TITLES].COD_TITLE
   ,CASE
		WHEN TRANSACTION_TITLES.IS_SPOT = 1 THEN DATEDIFF(DAY, TRANSACTION_TITLES.PREVISION_PAY_DATE, TRANSACTION_TITLES.ORIGINAL_RECEIVE_DATE)
		ELSE TRANSACTION_TITLES.QTY_DAYS_ANTECIP
	END AS QTY_DAYS_ANTECIP
   ,TRANSACTION_TITLES.COD_TRAN
   ,TRANSACTION_TITLES.COD_EC
   ,TRANSACTION_TITLES.PLOT INTO #TEMP_CONSOLID_TOTAL
FROM [TRANSACTION_TITLES] WITH (NOLOCK)
JOIN [TRANSACTION] WITH (NOLOCK)
	ON [TRANSACTION].COD_TRAN = [TRANSACTION_TITLES].COD_TRAN
WHERE [TRANSACTION].COD_SITUATION = 3
AND [TRANSACTION].CREATED_AT > '2020-01-01 00:00:00'
AND [TRANSACTION_TITLES].IS_SPOT = 1

--DROP TABLE #TEMP_CONSOLID_TOTAL
--DROP TABLE #DELETE
GO

CREATE TABLE #DELETE (
	COD_TITLE INT
   ,QTY_DAYS_ANTECIP INT
   ,COD_TRAN INT
   ,COD_EC INT
   ,PLOT INT
)

DECLARE @COD_TITLE INT;
DECLARE @QTY_DAYS_ANTECIP INT;
DECLARE @CONT INT;

SET @CONT = 0;

WHILE @CONT < 20
BEGIN
--DROP TABLE #DELETE
INSERT INTO #DELETE
	SELECT TOP 3000
		COD_TITLE
	   ,QTY_DAYS_ANTECIP
	   ,COD_TRAN
	   ,COD_EC
	   ,PLOT
	FROM #TEMP_CONSOLID_TOTAL

--UPDATE REPORT_CONSOLIDATED_TRANS_SUB SET QTY_DAYS_ANTECIP = 


UPDATE REPORT_CONSOLIDATED_TRANS_SUB
SET QTY_DAYS_ANTECIP = #DELETE.QTY_DAYS_ANTECIP
FROM REPORT_CONSOLIDATED_TRANS_SUB
JOIN #DELETE
	ON #DELETE.COD_TRAN = REPORT_CONSOLIDATED_TRANS_SUB.COD_TRAN
	AND REPORT_CONSOLIDATED_TRANS_SUB.COD_EC = #DELETE.COD_EC
	AND REPORT_CONSOLIDATED_TRANS_SUB.PLOT = #DELETE.PLOT
WHERE REPORT_CONSOLIDATED_TRANS_SUB.COD_TRAN IN (SELECT
		COD_TRAN
	FROM #DELETE)
--AND REPORT_CONSOLIDATED_TRANS_SUB.COD_TITLE = #DELETE.COD_TITLE

DELETE FROM #TEMP_CONSOLID_TOTAL
WHERE COD_TITLE IN (SELECT
			COD_TITLE
		FROM #DELETE)

DELETE FROM #DELETE

SELECT
	@CONT AS QTY;

SET @CONT = @CONT + 1;

END



DROP TABLE #TEMP_CONSOLID_TOTAL

DROP TABLE #DELETE

GO

--/ST-1308 / ST-1317

GO

--ST-1334


IF OBJECT_ID('SP_REG_FINANCIAL_FILE_SEQ_DISSOCIATION_PRC') IS NOT NULL
	DROP PROCEDURE SP_REG_FINANCIAL_FILE_SEQ_DISSOCIATION_PRC;
GO
CREATE PROCEDURE [DBO].[SP_REG_FINANCIAL_FILE_SEQ_DISSOCIATION_PRC] (@DISS_INFO [TP_FIN_FILE_SEQ_DISSOCIATE] READONLY)
AS
BEGIN

	INSERT INTO [FINANCE_SCHEDULE_HISTORY] ([COD_FIN_SCH_FILE_TITLE],
	[COD_SITUATION_TITLE],
	[COD_FIN_CALENDAR],
	[COD_USER_CREAT],
	[MODIFY_DATE],
	[COD_USER_MODIFY])
		SELECT
			[INFO].[COD_FILE]
		   ,[FINANCE_CALENDAR].[COD_SITUATION]
		   ,[FINANCE_CALENDAR].[COD_FIN_CALENDAR]
		   ,[INFO].[COD_USER]
		   ,GETDATE()
		   ,[INFO].[COD_USER]
		FROM [FINANCE_CALENDAR]
		JOIN @DISS_INFO AS [INFO]
			ON [INFO].[COD_FILE] = [FINANCE_CALENDAR].[COD_FIN_SCH_FILE]
		WHERE [FINANCE_CALENDAR].[COD_SITUATION] = 17
		AND [FINANCE_CALENDAR].[ACTIVE] = 1;

	INSERT INTO [FINANCE_CALENDAR_HIST] ([COD_FIN_CALENDAR],
	[COD_USER],
	[PREVISION_PAY_DATE],
	[PLOT_VALUE_PAYMENT],
	[COD_SITUATION],
	[COD_BK_EC],
	[COD_BANK],
	[CODE_BANK],
	[PRIORITY],
	[BANK],
	[AGENCY],
	[DIGIT_AGENCY],
	[ACCOUNT],
	[DIGIT_ACCOUNT],
	[COD_TYPE_ACCOUNT],
	[ACCOUNT_TYPE],
	[COD_OPER_BANK],
	[OPERATION_CODE],
	[OPERATION_DESC],
	[ACTIVE],
	[IS_LOCK],
	[IS_ASSIGNMENT],
	[ASSIGNMENT_NAME],
	[ASSIGNMENT_IDENTIFICATION],
	[COD_EC],
	[COD_COMP],
	[COMMERCIAL_CODE],
	[EC_CPF_CNPJ],
	[EC_NAME],
	[TYPE_ESTAB],
	[TRADING_NAME],
	[COD_AFFILIATOR],
	[AFFILIATOR_NAME],
	[AFFILIATOR_CPF_CNPJ],
	[COD_FIN_SCH_FILE],
	[COD_PAY_PROT],
	[PAYMENT_DATE],
	[HAS_UNLINK])
		SELECT
			[COD_FIN_CALENDAR]
		   ,[INFO].[COD_USER]
		   ,[PREVISION_PAY_DATE]
		   ,[PLOT_VALUE_PAYMENT]
		   ,[COD_SITUATION]
		   ,[COD_BK_EC]
		   ,[COD_BANK]
		   ,[CODE_BANK]
		   ,[PRIORITY]
		   ,[BANK]
		   ,[AGENCY]
		   ,[DIGIT_AGENCY]
		   ,[ACCOUNT]
		   ,[DIGIT_ACCOUNT]
		   ,[COD_TYPE_ACCOUNT]
		   ,[ACCOUNT_TYPE]
		   ,[COD_OPER_BANK]
		   ,[OPERATION_CODE]
		   ,[OPERATION_DESC]
		   ,[ACTIVE]
		   ,[IS_LOCK]
		   ,[IS_ASSIGNMENT]
		   ,[ASSIGNMENT_NAME]
		   ,[ASSIGNMENT_IDENTIFICATION]
		   ,[FINANCE_CALENDAR].[COD_EC]
		   ,[COD_COMP]
		   ,[COMMERCIAL_CODE]
		   ,[EC_CPF_CNPJ]
		   ,[EC_NAME]
		   ,[TYPE_ESTAB]
		   ,[TRADING_NAME]
		   ,[COD_AFFILIATOR]
		   ,[AFFILIATOR_NAME]
		   ,[AFFILIATOR_CPF_CNPJ]
		   ,[FINANCE_CALENDAR].[COD_FIN_SCH_FILE]
		   ,[COD_PAY_PROT]
		   ,[PAYMENT_DATE]
		   ,1
		FROM [FINANCE_CALENDAR]
		JOIN @DISS_INFO AS [INFO]
			ON [INFO].[COD_FILE] = [FINANCE_CALENDAR].[COD_FIN_SCH_FILE]
		WHERE FINANCE_CALENDAR.ACTIVE = 1


	UPDATE [FINANCE_CALENDAR]
	SET [COD_SITUATION] = 4
	   ,[PAYMENT_DATE] = NULL
	   ,[COD_FIN_SCH_FILE] = NULL
	FROM [FINANCE_CALENDAR]
	JOIN @DISS_INFO [INFO]
		ON [INFO].[COD_FILE] = [FINANCE_CALENDAR].[COD_FIN_SCH_FILE]
	WHERE [FINANCE_CALENDAR].[COD_SITUATION] = 17
	AND [FINANCE_CALENDAR].[ACTIVE] = 1;


	INSERT INTO [FINANCE_FILE_DISSOCIATED] ([file_name],
	[FILE_SEQUENCE],
	[AMOUNT],
	[REASON],
	[COD_USER],
	[COD_EC],
	[DISS_FILE_PATH])
		SELECT
			[INFO].[file_name]
		   ,[INFO].[FILE_SEQUENCE]
		   ,[INFO].[AMOUNT]
		   ,[INFO].[REASON]
		   ,[INFO].[COD_USER]
		   ,[INFO].[COD_EC]
		   ,[INFO].[DISS_FILE_PATH]
		FROM @DISS_INFO AS [INFO];

END;

GO

--/ST-1334
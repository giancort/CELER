SELECT 
 details.COD_PAY_PROT 
   ,details.PROTOCOL 
   ,details.COD_EC 
   ,REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), details.[Prot Value], 1), ',', '|'), '.', ','), '|', ',') AS [Prot Value] 
   ,REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), (details.[Ec Liq Value] + details.[Adjust Value] + details.[Tariff]), 1), ',', '|'), '.', ','), '|', ',') AS [Recalculated value] 
   ,REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), details.[Ec Liq Value], 1), ',', '|'), '.', ','), '|', ',') AS [Ec Liq Value] 
   ,REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), details.[Adjust Value], 1), ',', '|'), '.', ','), '|', ',') AS [Adjust Value] 
   ,REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), details.[Tariff], 1), ',', '|'), '.', ','), '|', ',') AS [Tariff] 
   ,details.[Protocol Date] 
FROM (SELECT 
  p.COD_PAY_PROT 
    ,p.PROTOCOL 
    ,p.[VALUE] [Prot Value] 
    ,p.COD_EC 
    ,p.CREATED_AT [Protocol Date] 
    ,(SELECT 
    CAST(SUM((dbo.[FNC_ANT_VALUE_LIQ_DAYS](title.AMOUNT, title.TAX_INITIAL, title.PLOT, title.ANTICIP_PERCENT, (CASE 
     WHEN title.IS_SPOT = 1 THEN DATEDIFF(DAY, title.PREVISION_PAY_DATE, title.ORIGINAL_RECEIVE_DATE) 
     ELSE title.QTY_DAYS_ANTECIP 
    END))) - (CASE 
     WHEN title.PLOT = 1 THEN title.RATE 
     ELSE 0 
    END)) AS DECIMAL(22, 6)) 
   FROM TRANSACTION_TITLES(NOLOCK) title 
   WHERE title.COD_PAY_PROT = p.COD_PAY_PROT 
   AND title.COD_SITUATION = 8) 
  [Ec Liq Value] 
    ,ISNULL((SELECT 
    SUM(adjust.[VALUE]) 
   FROM RELEASE_ADJUSTMENTS(NOLOCK) adjust 
   WHERE adjust.COD_PAY_PROT = p.COD_PAY_PROT) 
  , 0) [Adjust Value] 
    ,ISNULL((SELECT 
    SUM(TARIFF_EC.value) 
   FROM TARIFF_EC(NOLOCK) 
   WHERE TARIFF_EC.COD_PAY_PROT = p.COD_PAY_PROT) 
  , 0) [Tariff] 
 FROM PROTOCOLS p 
 WHERE (SELECT 
   COUNT(*) 
  FROM TRANSACTION_TITLES t (NOLOCK) 
  WHERE t.COD_PAY_PROT = p.COD_PAY_PROT 
  AND t.COD_SITUATION = 8 
  AND t.COD_FIN_SCH_FILE IS NOT NULL) 
 > 0) details 
WHERE ABS(details.[Prot Value] - (details.[Ec Liq Value] + details.[Adjust Value] + details.[Tariff])) > 0.15 

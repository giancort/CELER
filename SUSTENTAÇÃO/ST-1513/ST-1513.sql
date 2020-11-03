SELECT
	ASS_DEPTO_EQUIP.DATA_REGISTRO
   ,AFFILIATOR.NAME
   ,EQUIPMENT.SERIAL
   ,COMMERCIAL_ESTABLISHMENT.NAME
   ,COMMERCIAL_ESTABLISHMENT.CPF_CNPJ
   ,ASS_DEPTO_EQUIP.COD_EQUIP
   --,USERS.COD_ACCESS
   ,BRANCH_EC.COD_BRANCH
   ,ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
--,USERS1.COD_ACCESS
FROM ASS_DEPTO_EQUIP
JOIN EQUIPMENT
	ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
JOIN DEPARTMENTS_BRANCH
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = DEPARTMENTS_BRANCH.COD_DEPTO_BRANCH
JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DEPARTMENTS_BRANCH.COD_BRANCH
JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
JOIN AFFILIATOR
	ON AFFILIATOR.COD_AFFILIATOR = COMMERCIAL_ESTABLISHMENT.COD_AFFILIATOR
--JOIN USERS
--	ON USERS.COD_USER = ASS_DEPTO_EQUIP.COD_USER
--JOIN users USERS1
--	ON USERS1.COD_USER = ASS_DEPTO_EQUIP.COD_USER_MODIFY
WHERE SERIAL = '6M057259'
ORDER BY DATA_REGISTRO

GO

exec SP_VALIDATE_TERMINAL @TERMINALID = 51312, @COD_BRANCH = 13158 

GO
SELECT
	EQUIPMENT.ACTIVE
   ,ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH
   ,VW_COMPANY_EC_BR_DEP.SITUATION_EC
   ,VW_COMPANY_EC_BR_DEP.COD_BRANCH
   ,VW_COMPANY_EC_BR_DEP.CPF_CNPJ_EC
   ,VW_COMPANY_EC_BR_DEP.DOC_AFFILIATOR
   ,VW_COMPANY_EC_BR_DEP.MERCHANT_CODE
   ,VW_COMPANY_EC_BR_DEP.COD_EC
   ,VW_COMPANY_EC_BR_DEP.COD_RISK_SITUATION
FROM EQUIPMENT
LEFT JOIN ASS_DEPTO_EQUIP
	ON ASS_DEPTO_EQUIP.COD_EQUIP = EQUIPMENT.COD_EQUIP
LEFT JOIN VW_COMPANY_EC_BR_DEP
	ON ASS_DEPTO_EQUIP.COD_DEPTO_BRANCH = VW_COMPANY_EC_BR_DEP.COD_DEPTO_BR
WHERE EQUIPMENT.COD_EQUIP = 51312
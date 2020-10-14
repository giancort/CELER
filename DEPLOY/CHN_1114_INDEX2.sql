alter index IX_PROCESS_BD_STATUS_CODE_SOURCE	on dbo.PROCESS_BG_STATUS rebuild
alter index IX_ASS_TAX_CREATED_DEPTO	on dbo.ASS_TAX_DEPART rebuild
alter index IX_ASS_TAX_DEPART_COD_INCL_COD_TTYPE_INTERVAL_BRAND	on dbo.ASS_TAX_DEPART rebuild
alter index PK_TAX_PLAN	on dbo.TAX_PLAN rebuild
alter index IX_TAX_PLAN_ACTIVE_COD_PLAN_BRAND_SOURCE	on dbo.TAX_PLAN rebuild
alter index PK_DOCS_BRANCH	on dbo.DOCS_BRANCH rebuild
alter index PK_BANK_DETAILS_EC	on dbo.BANK_DETAILS_EC rebuild
alter index PK_COMMERCIAL_ESTABLISHMENT	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_ADDRESS_BRANCH	on dbo.ADDRESS_BRANCH rebuild
alter index PK_CONTACT_BRANCH	on dbo.CONTACT_BRANCH rebuild
alter index PK_PLAN_TAX_AFILIATOR	on dbo.PLAN_TAX_AFFILIATOR rebuild
alter index nci_wi_PLAN_TAX_AFFILIATOR_AF54D12650DDE6688EC2DBD3BB6B1EF9	on dbo.PLAN_TAX_AFFILIATOR rebuild
alter index IX_BANK_DETAILS_ACTIVE_IS_CERC	on dbo.BANK_DETAILS_EC rebuild
alter index PK_BRANCH_COMPANY	on dbo.BRANCH_EC rebuild
alter index IX_BK_DETAILS_EC_AGENCY	on dbo.BANK_DETAILS_EC rebuild
alter index nci_wi_ADDRESS_BRANCH_06BB142B547165CED1ADC834D253E538	on dbo.ADDRESS_BRANCH rebuild
alter index nci_wi_BANK_DETAILS_EC_9DAA9ACE6BEABC7D2BE9DDB0D8842A96	on dbo.BANK_DETAILS_EC rebuild
alter index IX_ADDRESS_BRANCH_COD_BRANCH_ACTIVE	on dbo.ADDRESS_BRANCH rebuild
alter index IX_EC_ACTIVE_IS_CERC	on dbo.BANK_DETAILS_EC rebuild
alter index IX_EC_CREATED_TRADING	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_CONTACT_USERS	on dbo.CONTACT_USERS rebuild
alter index PK__REQ_LANG__96BF8266FFFEE34F	on dbo.REQ_LANGUAGE_COMERCIAL rebuild
alter index PK__ESTABLIS__7E1F331C2A0F8760	on dbo.ESTABLISHMENT_CONDITIONS rebuild
alter index IX_BK_DTLS_EC_ACTIVE	on dbo.BANK_DETAILS_EC rebuild
alter index PK_RESEARCH_RISK	on dbo.RESEARCH_RISK rebuild
alter index IX_EC_COD_AFF_INC_NAME_CPF_COMP	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_PLAN	on dbo."PLAN" rebuild
alter index IDX_ESTAB_COND_EC	on dbo.ESTABLISHMENT_CONDITIONS rebuild
alter index IDX_ESTAB_COND_COMP_EC	on dbo.ESTABLISHMENT_CONDITIONS rebuild
alter index IX_COMMERCIAL_ESTABLISHMENT_ACTIVE_CPF_CNPJ	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_ADITIONAL_DATA_TYPE_EC	on dbo.ADITIONAL_DATA_TYPE_EC rebuild
alter index nci_wi_DEPARTMENTS_BRANCH_CB3868EBC1057182011738E614B24519	on dbo.DEPARTMENTS_BRANCH rebuild
alter index IX_EC_COD_SITUATION	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index UQ_COD_ACCESS_USER	on dbo.USERS rebuild
alter index PK__THEMES__BE79979864F2D058	on dbo.THEMES rebuild
alter index PK__ESTABLIS__7E1F331CEFF34BC1	on dbo.ESTABLISHMENT_CONDITIONS_HIST rebuild
alter index IX_BR_COD_EC	on dbo.BRANCH_EC rebuild
alter index IX_BRANCH_EC_COD_EC	on dbo.BRANCH_EC rebuild
alter index PK__ADDRESS___7EBBDED2F7781468	on dbo.ADDRESS_AFFILIATOR rebuild
alter index UQ__RISK_PER__5A6A29479882C342	on dbo.RISK_PERSON rebuild
alter index UQ__RISK_PER__5A6A29472366A3AA	on dbo.RISK_PERSON rebuild
alter index PK__AFFILIAT__7EB6778CAF733F06	on dbo.AFFILIATOR_CONTACT rebuild
alter index PK_ADDRESS_SALES_REP	on dbo.ADDRESS_SALES_REP rebuild
alter index PK_CONTACT_SALES_REP	on dbo.CONTACT_SALES_REP rebuild
alter index PK_SALES_REPRESENTATIVE	on dbo.SALES_REPRESENTATIVE rebuild
alter index PK__DOCS_AFF__C6DEEA4D3978B7C0	on dbo.DOCS_AFFILIATOR rebuild
alter index PK_ADDRESS_ADT_EC	on dbo.ADDRESS_ADT_EC rebuild
alter index PK__CONTRACT__66EC43BAD92B51F0	on dbo.CONTRACTS_AFFILIATOR rebuild


update statistics ASS_TAX_DEPART
update statistics TAX_PLAN
update statistics BANK_DETAILS_EC
update statistics COMMERCIAL_ESTABLISHMENT
update statistics ADDRESS_BRANCH
update statistics CONTACT_BRANCH
update statistics PLAN_TAX_AFFILIATOR
update statistics BRANCH_EC
update statistics ESTABLISHMENT_CONDITIONS
update statistics PROVISORY_PASS_USER
update statistics CONTACT_USERS


--teste
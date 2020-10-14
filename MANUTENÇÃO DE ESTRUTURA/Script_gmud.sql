--Rebuild

--Dia 1 (1-50)

alter index PK_REPORT_CONSOLIDATED_TRANS_SUB	on dbo.REPORT_CONSOLIDATED_TRANS_SUB rebuild
alter index PK_REPORT_TRANSACTIONS_EXP	on dbo.REPORT_TRANSACTIONS_EXP rebuild
alter index IX_TRANSACTION_DATA_EXT_COD_TRAN	on dbo.TRANSACTION_DATA_EXT rebuild


alter index IX_REPORT_EXP_AFFILIATOR_COMP_TRANDATE	on dbo.REPORT_TRANSACTIONS_EXP rebuild
alter index PK_TRANSACTION	on dbo."TRANSACTION" rebuild
alter index PK__REPORT_T__2C11B0EC53FB1C5D	on dbo.REPORT_TRANSACTIONS rebuild

alter index IX_PROCESS_BD_STATUS_CODE_SOURCE	on dbo.PROCESS_BG_STATUS rebuild

alter index IDX_TRAN_EXP_COD_TTYPE	on dbo."TRANSACTION" rebuild
alter index IX_ASS_TAX_CREATED_DEPTO	on dbo.ASS_TAX_DEPART rebuild

alter index IX_ASS_TAX_DEPART_COD_INCL_COD_TTYPE_INTERVAL_BRAND	on dbo.ASS_TAX_DEPART rebuild
alter index IX_REP_CONS_REPORT_ACQUIRER	on dbo.REPORT_CONSOLIDATED_TRANS_SUB rebuild

alter index IX_TRAN_SITUATION_CREATED_AT_CONS	on dbo."TRANSACTION" rebuild


alter index IX_TRANSACTION_COD_SITUATION_CREATED_AT	on dbo."TRANSACTION" rebuild

alter index un_report_consolidated_trans_sub	on dbo.REPORT_CONSOLIDATED_TRANS_SUB rebuild
alter index nci_wi_REPORT_TRANSACTIONS_3C4B13980B5C3EE0DE0E4E618820CA82	on dbo.REPORT_TRANSACTIONS rebuild

alter index IX_REP_DIARY_STONE	on dbo.REPORT_CONSOLIDATED_TRANS_SUB rebuild
alter index IX_REPORT_EC_SITUATION_TRAN_DATE	on dbo.REPORT_TRANSACTIONS rebuild
alter index IX_REPORT_EC_SITUATION_TRAN_DATE2	on dbo.REPORT_TRANSACTIONS rebuild
alter index IX_TR_SIT_BR_DATE	on dbo."TRANSACTION" rebuild
alter index IX_VALUE_SIT_TRANDATE_REP_EXP	on dbo.REPORT_TRANSACTIONS_EXP rebuild
alter index IX_REPORT_CONSOLIDATED_TRANS_SUB_COD_TRAN	on dbo.REPORT_CONSOLIDATED_TRANS_SUB rebuild

alter index IX_TRANSACTION_TO_AMOUNT	on dbo."TRANSACTION" rebuild



update statistics REPORT_CONSOLIDATED_TRANS_SUB
update statistics REPORT_TRANSACTIONS_EXP

update statistics "TRANSACTION"
update statistics REPORT_TRANSACTIONS

update statistics REPORT_STATUS_TRANSACTION
update statistics ASS_TAX_DEPART







--Dia 2 (51-100)

alter index IX_REP_TRAN_EXP_COMP_EC_TRANDATE	on dbo.REPORT_TRANSACTIONS_EXP rebuild
alter index PK_TAX_PLAN	on dbo.TAX_PLAN rebuild

alter index IX_REP_TRAN_PAGE_COMP_AFF_TRANDATE	on dbo.REPORT_TRANSACTIONS rebuild
alter index IX_TRANSACTION_COD_TYPE_BRAND	on dbo.TRANSACTION rebuild

alter index IX_TAX_PLAN_ACTIVE_COD_PLAN_BRAND_SOURCE	on dbo.TAX_PLAN rebuild
alter index IX_REPORT_CONSOLID_COD_TITLE	on dbo.REPORT_CONSOLIDATED_TRANS_SUB rebuild
alter index PK_ROUTE_ACQUIRER	on dbo.ROUTE_ACQUIRER rebuild
alter index PK_TEMP_TOKEN	on dbo.TEMP_TOKEN rebuild
alter index PK_DOCS_BRANCH	on dbo.DOCS_BRANCH rebuild
alter index PK__MESSAGIN__5BED5CBC5348CEA8	on dbo.MESSAGING rebuild

alter index PK_ROUTE_ACQUIRER_HIST	on dbo.ROUTE_ACQUIRER_HIST rebuild

alter index PK_DATA_EQUIPMENT_AC	on dbo.DATA_EQUIPMENT_AC rebuild
alter index PK_BANK_DETAILS_EC	on dbo.BANK_DETAILS_EC rebuild

alter index PK_COMMERCIAL_ESTABLISHMENT	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_ADDRESS_BRANCH	on dbo.ADDRESS_BRANCH rebuild
alter index PK_CONTACT_BRANCH	on dbo.CONTACT_BRANCH rebuild
alter index IX_DATA_EQUIP_AC_EQUIP_CODE_NAME	on dbo.DATA_EQUIPMENT_AC rebuild
alter index PK_PLAN_TAX_AFILIATOR	on dbo.PLAN_TAX_AFFILIATOR rebuild
alter index nci_wi_PLAN_TAX_AFFILIATOR_AF54D12650DDE6688EC2DBD3BB6B1EF9	on dbo.PLAN_TAX_AFFILIATOR rebuild
alter index PK_EQUIPMENT	on dbo.EQUIPMENT rebuild
alter index PK_DENIED_ACESS_USER	on dbo.DENIED_ACCESS_USER rebuild
alter index IX_BANK_DETAILS_ACTIVE_IS_CERC	on dbo.BANK_DETAILS_EC rebuild
alter index PK_BRANCH_COMPANY	on dbo.BRANCH_EC rebuild
alter index IX_BK_DETAILS_EC_AGENCY	on dbo.BANK_DETAILS_EC rebuild

alter index nci_wi_ADDRESS_BRANCH_06BB142B547165CED1ADC834D253E538	on dbo.ADDRESS_BRANCH rebuild
alter index nci_wi_BANK_DETAILS_EC_9DAA9ACE6BEABC7D2BE9DDB0D8842A96	on dbo.BANK_DETAILS_EC rebuild
alter index IX_ADDRESS_BRANCH_COD_BRANCH_ACTIVE	on dbo.ADDRESS_BRANCH rebuild
alter index IX_EC_ACTIVE_IS_CERC	on dbo.BANK_DETAILS_EC rebuild
alter index nci_wi_DATA_EQUIPMENT_AC_6D33476A6C3684006D5214B2DCA2946A	on dbo.DATA_EQUIPMENT_AC rebuild

alter index PK_ASS_DEPTO_EQUIP	on dbo.ASS_DEPTO_EQUIP rebuild


update statistics TAX_PLAN

update statistics ROUTE_ACQUIRER
update statistics TEMP_TOKEN


update statistics DOCS_BRANCH
update statistics MESSAGING
update statistics PROTOCOLS
update statistics ROUTE_ACQUIRER_HIST
update statistics DATA_EQUIPMENT_AC
update statistics BANK_DETAILS_EC
update statistics COMMERCIAL_ESTABLISHMENT
update statistics ADDRESS_BRANCH
update statistics CONTACT_BRANCH
update statistics PLAN_TAX_AFFILIATOR
update statistics EQUIPMENT
update statistics DENIED_ACCESS_USER
update statistics BRANCH_EC
update statistics ASS_DEPTO_EQUIP



--Dia 3 (101 - 212)


alter index PK_HangFire_State	on HangFire."State" rebuild
alter index PK_PROVISORY_PASS_USER	on dbo.PROVISORY_PASS_USER rebuild
alter index PK_DATA_TID_AVAILABLE_EC	on dbo.DATA_TID_AVAILABLE_EC rebuild

alter index PK_SERVICE_AVAILABLE_	on dbo.SERVICES_AVAILABLE rebuild


alter index IX_EC_CREATED_TRADING	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_CONTACT_USERS	on dbo.CONTACT_USERS rebuild
alter index PK__REQ_LANG__96BF8266FFFEE34F	on dbo.REQ_LANGUAGE_COMERCIAL rebuild
alter index PK__ESTABLIS__7E1F331C2A0F8760	on dbo.ESTABLISHMENT_CONDITIONS rebuild
alter index IX_BK_DTLS_EC_ACTIVE	on dbo.BANK_DETAILS_EC rebuild
alter index PK_RESEARCH_RISK	on dbo.RESEARCH_RISK rebuild
alter index nci_wi_ASS_DEPTO_EQUIP_27AD443B42362E9A30CAB5D1C28CBE3B	on dbo.ASS_DEPTO_EQUIP rebuild
alter index PK__ASS_CERC__7E1A8F539109A84A	on dbo.ASS_CERC_EC rebuild
alter index UK_SERIAL_COMP_EQUIP	on dbo.EQUIPMENT rebuild
alter index PK_HangFire_Job	on HangFire.Job rebuild
alter index nci_wi_ASS_DEPTO_EQUIP_AF6D7B1A3482A45F80F3343243E9AD65	on dbo.ASS_DEPTO_EQUIP rebuild
alter index IX_EC_COD_AFF_INC_NAME_CPF_COMP	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index nci_wi_SERVICES_AVAILABLE_F1E1D450B47D770F66FABF18E90E25E1	on dbo.SERVICES_AVAILABLE rebuild
alter index IX_ASS_DEPTO_EQUIP_COD_EQUIP_ACTIVE	on dbo.ASS_DEPTO_EQUIP rebuild
alter index PK_PLAN	on dbo."PLAN" rebuild
alter index PK_HangFire_Set	on Schedule."Set" rebuild
alter index IX_HangFire_Set_Score	on Schedule."Set" rebuild
alter index IDX_ESTAB_COND_COMP_EC	on dbo.ESTABLISHMENT_CONDITIONS rebuild

alter index PK_HangFire_JobParameter	on HangFire.JobParameter rebuild
alter index IDX_ESTAB_COND_EC	on dbo.ESTABLISHMENT_CONDITIONS rebuild

alter index PK_HangFire_State	on Services.State rebuild

alter index IX_COMMERCIAL_ESTABLISHMENT_ACTIVE_CPF_CNPJ	on dbo.COMMERCIAL_ESTABLISHMENT rebuild
alter index PK_ADITIONAL_DATA_TYPE_EC	on dbo.ADITIONAL_DATA_TYPE_EC rebuild

alter index nci_wi_DEPARTMENTS_BRANCH_CB3868EBC1057182011738E614B24519	on dbo.DEPARTMENTS_BRANCH rebuild
alter index IX_ASS_CERC_EC_PROCESSED	on dbo.ASS_CERC_EC rebuild
alter index PK__BANK_DET__102412BB2BC3AE3F	on dbo.BANK_DETAILS_CERC_INFO rebuild

alter index IX_EC_COD_SITUATION	on dbo.COMMERCIAL_ESTABLISHMENT rebuild

alter index UQ_COD_ACCESS_USER	on dbo.USERS rebuild
alter index PK_HangFire_Set	on HangFire.Set rebuild
alter index IX_HangFire_Set_Score	on HangFire.Set rebuild
alter index nci_wi_BANK_DETAILS_CERC_INFO_FF4C2D49DB98B791DE05200D90118012	on dbo.BANK_DETAILS_CERC_INFO rebuild
alter index PK_HangFire_Hash	on HangFire.Hash rebuild
alter index PK__PAYMENT___056F1DBFD8EAD04D	on dbo.PAYMENT_LINK rebuild
alter index PK_HangFire_Hash	on Schedule.Hash rebuild
alter index PK__THEMES__BE79979864F2D058	on dbo.THEMES rebuild
alter index PK_HangFire_Job	on Schedule.Job rebuild
alter index PK__ESTABLIS__7E1F331CEFF34BC1	on dbo.ESTABLISHMENT_CONDITIONS_HIST rebuild
alter index IX_BR_COD_EC	on dbo.BRANCH_EC rebuild
alter index IX_BRANCH_EC_COD_EC	on dbo.BRANCH_EC rebuild
alter index PK__CERC_FIL__75CCD2737B76866A	on dbo.CERC_FILE rebuild

alter index IX_HangFire_Set_ExpireAt	on Schedule.Set rebuild
alter index PK_HangFire_State	on Schedule.State rebuild
alter index IX_BILLET_BARCODE	on dbo.BILLET_TRANSACTION rebuild
alter index PK__ASS_EC_E__FD55B814ED1DF4DD	on dbo.ASS_EC_EXTERNAL_API rebuild
alter index UQ__PAYMENT___AA1D4379E4BB8096	on dbo.PAYMENT_LINK rebuild
alter index PK__ADDRESS___7EBBDED2F7781468	on dbo.ADDRESS_AFFILIATOR rebuild
alter index UQ__RISK_PER__5A6A29479882C342	on dbo.RISK_PERSON rebuild
alter index UQ__RISK_PER__5A6A29472366A3AA	on dbo.RISK_PERSON rebuild
alter index PK__AFFILIAT__7EB6778CAF733F06	on dbo.AFFILIATOR_CONTACT rebuild
alter index IX_HangFire_Job_StateName	on HangFire.Job rebuild
alter index PK_ADDRESS_SALES_REP	on dbo.ADDRESS_SALES_REP rebuild
alter index PK_CONTACT_SALES_REP	on dbo.CONTACT_SALES_REP rebuild
alter index PK_ITENS_PROG_COST_AFF	on dbo.ITENS_PROG_COST_AFF rebuild
alter index PK__AFFILIAT__E779B969A70A0E6C	on dbo.AFFILIATOR rebuild
alter index IX_HangFire_Job_ExpireAt	on HangFire.Job rebuild
alter index PK_ACCESS_APPAPI	on dbo.ACCESS_APPAPI rebuild
alter index PK_SALES_REPRESENTATIVE	on dbo.SALES_REPRESENTATIVE rebuild
alter index PK_PRODUCTS_ACQUIRER	on dbo.PRODUCTS_ACQUIRER rebuild
alter index PK_ASS_TR_TYPE_COMP	on dbo.ASS_TR_TYPE_COMP rebuild
alter index PK__TMP_PROM__6A7B03B34BF959A4	on dbo.TMP_PROMOCODE rebuild

alter index PK_HangFire_JobParameter	on Services.JobParameter rebuild
alter index PK_HangFire_JobParameter	on Services.JobParameter rebuild
alter index IX_ACCESS_COMP_LOGIN	on dbo.ACCESS_APPAPI rebuild
alter index PK_HangFire_Job	on Services.Job rebuild
alter index PK__CUSTOMER__1B9850919E675986	on dbo.CUSTOMER_LINK rebuild


alter index IX_HangFire_Job_StateName	on Schedule.Job rebuild
alter index IX_HangFire_Job_ExpireAt	on Schedule.Job rebuild
alter index UQ_CLIENT_ID	on dbo.ACCESS_APPAPI rebuild
alter index PK__DOCS_AFF__C6DEEA4D3978B7C0	on dbo.DOCS_AFFILIATOR rebuild

alter index PK_MERCHANTS_INTEGRATION	on dbo.MERCHANTS_INTEGRATION rebuild
alter index PK_PROGRESSIVE_COST_AFFILIATOR	on dbo.PROGRESSIVE_COST_AFFILIATOR rebuild
alter index PK__ASS_PLAN__29EC734A96212CDF	on dbo.ASS_PLAN_TYPE_ESTAB rebuild
alter index PK__ASS_EC_T__579DD62836211A16	on dbo.ASS_EC_TRAN_PRODUCT rebuild
alter index PK_BANKS	on dbo.BANKS rebuild
alter index PK__SPLIT_PR__952E68B1F73C85C5	on dbo.SPLIT_PRODUCTS rebuild
alter index IX_HangFire_AggregatedCounter_ExpireAt	on HangFire.AggregatedCounter rebuild
alter index PK_ASS_PARAMS_PRODUCTS	on dbo.ASS_PARAMS_PRODUCTS rebuild
alter index PK__NOTIFICA__23C61893E3389221	on dbo.NOTIFICATION_MESSAGES rebuild
alter index PK_REGISTER_ARCHIVEELO	on dbo.REGISTER_ARCHIVE_EC_ELO rebuild
alter index IX_HangFire_Server_LastHeartbeat	on Schedule.Server rebuild
alter index IX_HangFire_Server_LastHeartbeat	on HangFire.Server rebuild
alter index PK_ADDRESS_ADT_EC	on dbo.ADDRESS_ADT_EC rebuild
alter index PK__CONTRACT__66EC43BAD92B51F0	on dbo.CONTRACTS_AFFILIATOR rebuild
alter index IX_HangFire_Server_LastHeartbeat	on Services.Server rebuild
alter index PK__BRANCH_B__CC5737418C5B6F7D	on dbo.BRANCH_BUSINESS rebuild


update statistics "State"
update statistics PROVISORY_PASS_USER
update statistics DATA_TID_AVAILABLE_EC
update statistics SERVICES_AVAILABLE
update statistics CONTACT_USERS
update statistics REQ_LANGUAGE_COMERCIAL
update statistics ESTABLISHMENT_CONDITIONS
update statistics RESEARCH_RISK
update statistics ASS_CERC_EC
update statistics "Job"
update statistics "PLAN"
update statistics "Set"

update statistics JobParameter
update statistics ADITIONAL_DATA_TYPE_EC
update statistics DEPARTMENTS_BRANCH
update statistics BANK_DETAILS_CERC_INFO
update statistics USERS
update statistics "Hash"
update statistics PAYMENT_LINK
update statistics THEMES
update statistics ESTABLISHMENT_CONDITIONS_HIST
update statistics CERC_FILE
update statistics BILLET_TRANSACTION
update statistics ASS_EC_EXTERNAL_API
update statistics ADDRESS_AFFILIATOR
update statistics RISK_PERSON
update statistics AFFILIATOR_CONTACT
update statistics ADDRESS_SALES_REP
update statistics CONTACT_SALES_REP
update statistics ITENS_PROG_COST_AFF
update statistics AFFILIATOR
update statistics ACCESS_APPAPI
update statistics SALES_REPRESENTATIVE
update statistics PRODUCTS_ACQUIRER
update statistics ASS_TR_TYPE_COMP
update statistics TMP_PROMOCODE
update statistics FINANCE_FILE_DISSOCIATED
update statistics CUSTOMER_LINK
update statistics CELER_PAY_REQUEST_HISTORY
update statistics DOCS_AFFILIATOR
update statistics TYPE_TARIFF
update statistics TRANSACTION_TITLES_DUPLICATED
update statistics MERCHANTS_INTEGRATION
update statistics PROGRESSIVE_COST_AFFILIATOR
update statistics ASS_PLAN_TYPE_ESTAB
update statistics ASS_EC_TRAN_PRODUCT
update statistics BANKS
update statistics SPLIT_PRODUCTS
update statistics AggregatedCounter
update statistics ASS_PARAMS_PRODUCTS
update statistics NOTIFICATION_MESSAGES
update statistics REGISTER_ARCHIVE_EC_ELO
update statistics Server
update statistics ADDRESS_ADT_EC
update statistics CONTRACTS_AFFILIATOR
update statistics BRANCH_BUSINESS


--Reorganinze

alter index PK__CELER_PA__21CAFB2C4D087E0B	on dbo.CELER_PAY_REQUEST_HISTORY reorganize
alter index PK_EQUIPMENT_LOG	on dbo.EQUIPMENT_LOG reorganize
alter index PK__PRODUCTS__AC16B1ED62550BC2	on dbo.PRODUCTS_LINK reorganize

alter index PK_PASS_HISTORY	on dbo.PASS_HISTORY reorganize
alter index PK__SHIPPING__6B977C668B292B0B	on dbo.SHIPPING_LINK reorganize
alter index PK_OPERATION_COST_AFFILIATOR	on dbo.OPERATION_COST_AFFILIATOR reorganize
alter index IX_HangFire_Hash_ExpireAt	on HangFire."Hash" reorganize
alter index PK_USERS	on dbo.USERS reorganize
alter index UQ_TID_EQUIPMENT	on dbo.EQUIPMENT reorganize
alter index IX_HangFire_Set_ExpireAt	on dbo."Set" reorganize
alter index un_report_transactions_exp	on dbo.REPORT_TRANSACTIONS_EXP reorganize
alter index UQ_CODE_BRANCH_COMPANY	on dbo.BRANCH_EC reorganize
alter index IX_REP_TRAN_EXP_COD_TRAN	on dbo.REPORT_TRANSACTIONS_EXP reorganize
alter index IX_BRANCH_COD_TYPE_RECEIVE	on dbo.BRANCH_EC reorganize
alter index IX_REP_EXP_ON_SIT_IC_TRANCODE_CANCEL	on dbo.REPORT_TRANSACTIONS_EXP reorganize
alter index UQ_CODE_COMMERCIAL_ESTABLISHMENT	on dbo.COMMERCIAL_ESTABLISHMENT reorganize
alter index UQ_SEGMENTS	on dbo.SEGMENTS reorganize
alter index un_report_transactions	on dbo.REPORT_TRANSACTIONS reorganize

alter index IX_TRAN_CREATED_COD_SIT	on dbo.TRANSACTION reorganize
alter index PK__SPLIT_PE__338DFC40958CAB62	on dbo.SPLIT_PENDING reorganize
alter index PK_ASS_TAX_DEPART	on dbo.ASS_TAX_DEPART reorganize
alter index PK__ASS_TRAN__AC3553138B8E1164	on dbo.ASS_TRANSACTION_LINK reorganize
alter index PK_USERS_LOG	on dbo.USERS_LOG reorganize
alter index PK_RESEARCH_RISK_RESPONSE	on dbo.RESEARCH_RISK_RESPONSE reorganize
alter index IX_REPORT_CONS_TRAN_CODE_COMP_SITUATION	on dbo.REPORT_CONSOLIDATED_TRANS_SUB reorganize
alter index PK_DEPARTMENTS_BRANCH	on dbo.DEPARTMENTS_BRANCH reorganize
alter index PK_POSWEB_DATA_TRANSACTION	on dbo.POSWEB_DATA_TRANSACTION reorganize
alter index IX_PROTOCOLS_CREATED_IC_PROTOCOL	on dbo.PROTOCOLS reorganize
alter index UQ_CODE_TRANSACTION	on dbo.TRANSACTION reorganize
alter index PK_PROCESS_BG_STATUS_ERROR	on dbo.PROCESS_BG_STATUS_ERROR reorganize
alter index PK__RISK_PER__DAA18818FA36C982	on dbo.RISK_PERSON reorganize
alter index IX_REPORT_TRAN_COD_TRAN	on dbo.REPORT_TRANSACTIONS reorganize
alter index PK_FINANCIAL_BILLET	on dbo.FINANCIAL_BILLET reorganize
alter index PK_HIST_SIT_DOCS_BRANCH	on dbo.HIST_SIT_DOCS_BRANCH reorganize
alter index UK_TRAN_BILLET_CODE	on dbo.BILLET_TRANSACTION reorganize
alter index PK__DETAIL_R__7252D5EE11EED00C	on dbo.DETAIL_RISK reorganize
alter index IX_REPORT_CONS_TRAN_DATE_ON_CONSOLIDADED	on dbo.REPORT_CONSOLIDATED_TRANS_SUB reorganize
alter index IX_SERVICES_USING_TRAN	on dbo.TRANSACTION_SERVICES reorganize
alter index PK_BILLET_TRANSACTION	on dbo.BILLET_TRANSACTION reorganize
alter index IX_BRANCH_DEPART_COD_BRANCH	on dbo.DEPARTMENTS_BRANCH reorganize
alter index IX_REPORT_TRANS_DATA_COMP_EC	on dbo.REPORT_TRANSACTIONS_EXP reorganize
alter index IX_TRAN_SERIVCES_CODTRAN	on dbo.TRANSACTION_SERVICES reorganize
alter index PK_TRANSACTION_SERVICES	on dbo.TRANSACTION_SERVICES reorganize
alter index PK_NEIGHBORDHOOD	on dbo.NEIGHBORHOOD reorganize
alter index PK_COD_EQUIP_MIGRATE	on dbo.EQUIPMENTS_TOMIGRATE reorganize
alter index PK_COD_FIN_SCH_HISTORY	on dbo.FINANCE_SCHEDULE_HISTORY reorganize


----Release unused space an update stats

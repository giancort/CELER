IF OBJECT_ID('SP_REG_BILLS_TO_PAY') IS NOT NULL DROP PROCEDURE SP_REG_BILLS_TO_PAY
GO
IF OBJECT_ID('SP_LS_PROCESSING_BILLS_TO_PAY') IS NOT NULL DROP PROCEDURE SP_LS_PROCESSING_BILLS_TO_PAY
GO
IF OBJECT_ID('SP_LS_PROCESSING_SEND_RECEIVABLE_UNITS') IS NOT NULL DROP PROCEDURE SP_LS_PROCESSING_SEND_RECEIVABLE_UNITS
GO
IF OBJECT_ID('SP_REG_PROCESSING_SEND_RECEIVE_UNITS') IS NOT NULL DROP PROCEDURE SP_REG_PROCESSING_SEND_RECEIVE_UNITS
GO
IF OBJECT_ID('SP_CONFIRM_SEND_RECEIVE_UNITS') IS NOT NULL DROP PROCEDURE SP_CONFIRM_SEND_RECEIVE_UNITS
GO
IF TYPE_ID('TP_PROCESSING_SEND_RECEIVE_UNITS') IS NOT NULL DROP TYPE TP_PROCESSING_SEND_RECEIVE_UNITS
GO
IF TYPE_ID('TP_BILLS_TO_PAY') IS NOT NULL DROP TYPE TP_BILLS_TO_PAY
GO
IF OBJECT_ID('PROCESSING_SEND_RECEIVABLE_UNITS') IS NOT NULL DROP TABLE PROCESSING_SEND_RECEIVABLE_UNITS
GO
IF OBJECT_ID('BILLS_TO_PAY') IS NOT NULL DROP TABLE BILLS_TO_PAY
GO
IF OBJECT_ID('PROCESSING_RECEIVE_UNITS') IS NOT NULL DROP TABLE PROCESSING_RECEIVE_UNITS
GO
CREATE TABLE PROCESSING_RECEIVE_UNITS
(
	COD_PROCESSING_RECEIVE_UNITS INT PRIMARY KEY IDENTITY(1,1),
	PROCESSING_DATE DATETIME,
	PROCESS_STATUS INT DEFAULT NULL
)
GO
CREATE TABLE PROCESSING_SEND_RECEIVABLE_UNITS
(
	COD_PROC_SEND_RECEIVE_UNIT INT PRIMARY KEY IDENTITY(1,1),
	COD_PROCESSING_RECEIVE_UNITS INT FOREIGN KEY REFERENCES PROCESSING_RECEIVE_UNITS (COD_PROCESSING_RECEIVE_UNITS),
	OperationType VARCHAR(255),
	ExternalReference VARCHAR(255),
	AccreditationCnpj VARCHAR(255),
	ArrangementCnpj VARCHAR(255),
	PaymentArrangement VARCHAR(255),
	SettlementDate VARCHAR(255),
	Document VARCHAR(255),
	TotalGrossvalue DECIMAL(22,6),
	TotalConstitutedValue DECIMAL(22,6),
	PreContractedAmount DECIMAL(22,6),
	BlockedValue DECIMAL(22,6),
	ValueTransactionRiskUserFinalReceiverTotal DECIMAL(22,6),
	ValueTransactionRiskEmitterTotal DECIMAL(22,6),
	Paid INT,
	CodEc INT,
	Payments NVARCHAR(MAX),
	[Status] INT DEFAULT NULL
)
GO
CREATE TABLE BILLS_TO_PAY
(
	COD_BILLS_TO_PAY INT PRIMARY KEY IDENTITY(1,1),
	COD_PROCESSING_RECEIVE_UNITS INT FOREIGN KEY REFERENCES PROCESSING_RECEIVE_UNITS (COD_PROCESSING_RECEIVE_UNITS),
	PrevisionPaymentDate DATETIME,
	Amount DECIMAL(22,6),
	CodUr INT DEFAULT NULL,
	CodSituation INT,
	CodSourceTran INT,
	Domicile NVARCHAR(MAX),
	CompanyDoc VARCHAR(255),
	AcquirerDocument VARCHAR(255),
	BrandCode VARCHAR(255),
	MerchantDoc VARCHAR(255),
	PaymentDate DATETIME,
	Anteciped INT,
	ExternalRef VARCHAR(255),
	CodEc INT,
	OperationType VARCHAR(255)
)
GO
CREATE TYPE TP_PROCESSING_SEND_RECEIVE_UNITS AS TABLE
(
	OperationType VARCHAR(255),
	ExternalReference VARCHAR(255),
	AccreditationCnpj VARCHAR(255),
	ArrangementCnpj VARCHAR(255),
	PaymentArrangement VARCHAR(255),
	SettlementDate VARCHAR(255),
	Document VARCHAR(255),
	TotalGrossvalue DECIMAL(22,6),
	TotalConstitutedValue DECIMAL(22,6),
	PreContractedAmount DECIMAL(22,6),
	BlockedValue DECIMAL(22,6),
	ValueTransactionRiskUserFinalReceiverTotal DECIMAL(22,6),
	ValueTransactionRiskEmitterTotal DECIMAL(22,6),
	Paid INT,
	CodEc INT,
	Payments NVARCHAR(MAX),
	[Status] INT DEFAULT NULL
);

GO

CREATE TYPE TP_BILLS_TO_PAY AS TABLE
(
	COD_PROCESSING_RECEIVE_UNITS INT,
	PrevisionPaymentDate DATETIME,
	Amount DECIMAL(22,6),
	CodUr INT DEFAULT NULL,
	CodSituation INT,
	CodSourceTran INT,
	Domicile NVARCHAR(MAX),
	CompanyDoc VARCHAR(255),
	AcquirerDocument VARCHAR(255),
	BrandCode VARCHAR(255),
	MerchantDoc VARCHAR(255),
	PaymentDate DATETIME,
	Anteciped INT,
	ExternalRef VARCHAR(255),
	CodEc INT,
	OperationType VARCHAR(255)
)

GO

CREATE PROCEDURE SP_REG_PROCESSING_SEND_RECEIVE_UNITS
(
	@TP_PROCESSING_SEND_RECEIVE_UNITS TP_PROCESSING_SEND_RECEIVE_UNITS READONLY
)
AS
BEGIN

DECLARE @COD_PROCESSING_RECEIVE_UNITS INT

INSERT INTO PROCESSING_RECEIVE_UNITS (PROCESSING_DATE,
PROCESS_STATUS)
	VALUES (CURRENT_TIMESTAMP, 0)

SET @COD_PROCESSING_RECEIVE_UNITS = @@identity


INSERT INTO PROCESSING_SEND_RECEIVABLE_UNITS (COD_PROCESSING_RECEIVE_UNITS,
OperationType,
ExternalReference,
AccreditationCnpj,
ArrangementCnpj,
PaymentArrangement,
SettlementDate,
Document,
TotalGrossvalue,
TotalConstitutedValue,
PreContractedAmount,
BlockedValue,
ValueTransactionRiskUserFinalReceiverTotal,
ValueTransactionRiskEmitterTotal,
Paid,
CodEc,
Payments)
	SELECT
		@COD_PROCESSING_RECEIVE_UNITS
	   ,TP.OperationType
	   ,TP.ExternalReference
	   ,TP.AccreditationCnpj
	   ,TP.ArrangementCnpj
	   ,TP.PaymentArrangement
	   ,TP.SettlementDate
	   ,TP.Document
	   ,TP.TotalGrossvalue
	   ,TP.TotalConstitutedValue
	   ,TP.PreContractedAmount
	   ,TP.BlockedValue
	   ,TP.ValueTransactionRiskUserFinalReceiverTotal
	   ,TP.ValueTransactionRiskEmitterTotal
	   ,TP.Paid
	   ,TP.CodEc
	   ,TP.Payments
	FROM @TP_PROCESSING_SEND_RECEIVE_UNITS TP
	LEFT JOIN PROCESSING_SEND_RECEIVABLE_UNITS
		ON TP.ExternalReference = PROCESSING_SEND_RECEIVABLE_UNITS.ExternalReference
	WHERE PROCESSING_SEND_RECEIVABLE_UNITS.COD_PROC_SEND_RECEIVE_UNIT IS NULL

SELECT
	@COD_PROCESSING_RECEIVE_UNITS AS COD_PROCESSING_RECEIVE_UNITS

END

GO

CREATE PROCEDURE SP_CONFIRM_SEND_RECEIVE_UNITS
(
	@TP_PROCESSING_SEND_RECEIVE_UNITS TP_PROCESSING_SEND_RECEIVE_UNITS READONLY
)
AS
BEGIN

INSERT INTO PROCESSING_SEND_RECEIVABLE_UNITS (OperationType,
ExternalReference,
AccreditationCnpj,
ArrangementCnpj,
PaymentArrangement,
SettlementDate,
Document,
TotalGrossvalue,
TotalConstitutedValue,
PreContractedAmount,
BlockedValue,
ValueTransactionRiskUserFinalReceiverTotal,
ValueTransactionRiskEmitterTotal,
Paid,
CodEc,
Payments)
	SELECT
		TP.OperationType
	   ,TP.ExternalReference
	   ,TP.AccreditationCnpj
	   ,TP.ArrangementCnpj
	   ,TP.PaymentArrangement
	   ,TP.SettlementDate
	   ,TP.Document
	   ,TP.TotalGrossvalue
	   ,TP.TotalConstitutedValue
	   ,TP.PreContractedAmount
	   ,TP.BlockedValue
	   ,TP.ValueTransactionRiskUserFinalReceiverTotal
	   ,TP.ValueTransactionRiskEmitterTotal
	   ,TP.Paid
	   ,TP.CodEc
	   ,TP.Payments
	FROM @TP_PROCESSING_SEND_RECEIVE_UNITS TP
	LEFT JOIN PROCESSING_SEND_RECEIVABLE_UNITS
		ON TP.ExternalReference = PROCESSING_SEND_RECEIVABLE_UNITS.ExternalReference
	WHERE PROCESSING_SEND_RECEIVABLE_UNITS.COD_PROC_SEND_RECEIVE_UNIT IS NULL

END

GO

CREATE PROCEDURE SP_LS_PROCESSING_SEND_RECEIVABLE_UNITS
(
	@TP_CODE TP_STRING_CODE READONLY
)
AS

SELECT
	COD_PROCESSING_RECEIVE_UNITS
   ,OperationType
   ,ExternalReference
   ,AccreditationCnpj
   ,ArrangementCnpj
   ,PaymentArrangement
   ,SettlementDate
   ,Document
   ,TotalGrossvalue
   ,TotalConstitutedValue
   ,PreContractedAmount
   ,BlockedValue
   ,ValueTransactionRiskUserFinalReceiverTotal
   ,ValueTransactionRiskEmitterTotal
   ,Paid
   ,CodEc
   ,Payments
   ,[status]
FROM PROCESSING_SEND_RECEIVABLE_UNITS
JOIN @TP_CODE TP_CODE ON
	TP_CODE.CODE = PROCESSING_SEND_RECEIVABLE_UNITS.ExternalReference
WHERE ISNULL([Status], 0) = 0

GO

CREATE PROCEDURE SP_REG_BILLS_TO_PAY
(
	@TP_BILLS_TO_PAY TP_BILLS_TO_PAY READONLY
)
AS
BEGIN

INSERT INTO BILLS_TO_PAY (COD_PROCESSING_RECEIVE_UNITS,
PrevisionPaymentDate,
Amount,
CodUr,
CodSituation,
CodSourceTran,
Domicile,
CompanyDoc,
AcquirerDocument,
BrandCode,
MerchantDoc,
PaymentDate,
Anteciped,
ExternalRef,
CodEc,
OperationType)
	SELECT
		COD_PROCESSING_RECEIVE_UNITS
	   ,PrevisionPaymentDate
	   ,Amount
	   ,CodUr
	   ,CodSituation
	   ,CodSourceTran
	   ,Domicile
	   ,CompanyDoc
	   ,AcquirerDocument
	   ,BrandCode
	   ,MerchantDoc
	   ,PaymentDate
	   ,Anteciped
	   ,ExternalRef
	   ,CodEc
	   ,OperationType
	FROM @TP_BILLS_TO_PAY


END

GO
  
CREATE PROCEDURE SP_LS_PROCESSING_BILLS_TO_PAY  
(  
 @ExternalRef VARCHAR(255)
)  
AS
SELECT
	COD_PROCESSING_RECEIVE_UNITS
   ,PrevisionPaymentDate
   ,Amount
   ,CodUr
   ,CodSituation
   ,CodSourceTran
   ,Domicile
   ,CompanyDoc
   ,AcquirerDocument
   ,BrandCode
   ,MerchantDoc
   ,PaymentDate
   ,Anteciped
   ,ExternalRef
   ,CodEc
   ,OperationType
FROM BILLS_TO_PAY
WHERE BILLS_TO_PAY.ExternalRef = @ExternalRef

GO

IF OBJECT_ID('SP_CLEAN_RECEIVABLE_UNITS') IS NOT NULL DROP PROCEDURE SP_CLEAN_RECEIVABLE_UNITS
GO
CREATE PROCEDURE SP_CLEAN_RECEIVABLE_UNITS
(
	@TP_CODE TP_STRING_CODE READONLY
)
AS
BEGIN

DELETE FROM PROCESSING_SEND_RECEIVABLE_UNITS
WHERE ExternalReference IN (SELECT
			CODE
		FROM @TP_CODE)

DELETE FROM BILLS_TO_PAY
WHERE BILLS_TO_PAY.ExternalRef IN (SELECT
			CODE
		FROM @TP_CODE)

END
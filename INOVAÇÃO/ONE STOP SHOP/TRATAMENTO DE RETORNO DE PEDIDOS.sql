IF OBJECT_ID('TRANSACTION_RETURN_CODE') IS NOT NULL DROP TABLE TRANSACTION_RETURN_CODE;
GO
CREATE TABLE TRANSACTION_RETURN_CODE
(
	COD_TR_CODE INT,
	CODE_GW VARCHAR(50),
	TITLE VARCHAR(150),
	ERROR_DETAIL NVARCHAR(MAX),
	COD_AC INT,
	ACTIVE INT
);

GO

IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '701') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('701', 'Transa��o Negada', 'Por algum motivo, a transa��o n�o foi aprovada. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente utilizar um cart�o de cr�dito diferente', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '001') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('001', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '002') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('002', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '003') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('003', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '004') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('004', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '005') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('005', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '006') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('006', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '007') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('007', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '999') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('999', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '999') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('999', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '200') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('200', 'Transa��o Confirmada', 'Pagamento realizado. Agora que seu pedido foi finalizado, voc� ser� redirecionado para a tela de acompanhamento de pedido, onde ter� mais detalhes dos processos que ser�o realizados.', NULL, 1);

IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '201') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('201', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '202') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('202', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '203') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('203', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '204') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('204', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);

IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '301') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('301', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '302') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('302', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '303') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('303', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '304') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('304', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '305') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('305',  'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);

IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '801') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('801', 'Condi��es de pagamento inv�lidas', 'As condi��es de pagamento escolhidas s�o inv�lidas. Por favor, selecione outra formae tente novamente.', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '802') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('802', 'Quantidade de parcelas inv�lida', 'O valor m�nimo por parcela foi excedido. Por favor, selecione um n�mero inferior de parcelas e tente novamente.', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '901') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('901', 'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '902') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('902', 'Transa��o Negada', 'Por algum motivo, a transa��o foi negada. Por favor, tente utilizar um cart�o de cr�dito diferente para finalizar a compra.', NULL, 1);

IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '950') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('950',  'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);
IF ( SELECT COUNT(*) FROM TRANSACTION_RETURN_CODE WHERE CODE_GW = '951') = 0
INSERT INTO TRANSACTION_RETURN_CODE (CODE_GW, TITLE, ERROR_DETAIL, COD_AC, ACTIVE) VALUES ('951',  'Erro ao realizar transa��o', 'Estamos com dificuldades em finalizar o pagamento. Por favor, entre em contato com o administrador do sistema atrav�s dos contatos disponibilizados na aba de suporte, ou tente novamente mais tarde', NULL, 1);

GO
IF OBJECT_ID('SP_LS_TRANSACTION_RETURN_CODE') IS NOT NULL
DROP PROCEDURE SP_LS_TRANSACTION_RETURN_CODE;
GO
CREATE PROCEDURE SP_LS_TRANSACTION_RETURN_CODE
AS
BEGIN
SELECT
	CODE_GW
   ,TITLE
   ,ERROR_DETAIL
   ,COD_AC
   ,ACTIVE
FROM TRANSACTION_RETURN_CODE
END
USE [TKPP-NC-ONESTOPSHOP]
GO
SET IDENTITY_INSERT [dbo].[ORDER_SITUATION] ON 

INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (1, N'PAYMENT PENDING', N'PAGAMENTO PENDENTE', N'Pedido inserido na base de dados, aguardando a transação de pagamento ser realizada para seguir o processo de faturamento.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (2, N'PAYMENT MADE', N'PAGAMENTO EFETUADO', N'Transação de pagamento dos produtos realizada e confirmada. ', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (3, N'PAYMENT DENIED', N'PAGAMENTO NEGADO', N'Forma de pagamento utilizada não aprovada pela adquirente. Necessário refazer o pedido.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (4, N'PENDING ANALYSIS RISK', N'EM ANÁLISE DE RISCO', N'Etapa em que o estabelecimento comercial passa por um processo de prevenção a fraude e golpes.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (5, N'APPROVED AFTER RISK ANALYSIS', N'APROVADO PELA ÁREA DE RISCO', N'Não foram encontrados riscos de fraude por parte do estabelecimento comercial.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (6, N'FAILED AFTER RISK ANALYSIS', N'NEGADO PELA ÁREA DE RISCO', N'Foram encontrados riscos de fraude por parte do estabelecimento comercial. Por isso, a compra foi reprovada.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (7, N'PREPARING', N'EM PREPARAÇÃO', N'Após a liberação da área de risco, os produtos foram enviados para preparação de envio.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (8, N'LOGISTICS UNDER ANALYSIS', N'LOGÍSTICA EM ANÁLISE', NULL, 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (9, N'DISPATCHED', N'DESPACHADO', N'Produto(s) enviado(s) ao endereço de entrega.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (10, N'DELIVERED', N'ENTREGUE', N'Produto(s) recebido(s) no endereço de entrega.', 1, NULL)
INSERT [dbo].[ORDER_SITUATION] ([COD_ORDER_SIT], [NAME], [CODE], [DESCRIPTION], [VISIBLE], [ORDER_SIT_RESUME]) VALUES (11, N'UNDELIVERABLE', N'NÃO ENTREGUE', N'Produto(s) não recebido(s) no endereço de entrega.', 1, NULL)
SET IDENTITY_INSERT [dbo].[ORDER_SITUATION] OFF

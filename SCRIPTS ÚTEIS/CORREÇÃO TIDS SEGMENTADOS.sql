UPDATE SEGMENTS
SET COD_SEG_GROUP = (CASE
	WHEN NAME LIKE '%D30%' THEN (SELECT
				COD_SEG_GROUP
			FROM SEGMENTS_GROUP
			WHERE [GROUP] = 'COMERCIO')
	WHEN NAME LIKE '%D1%' THEN (SELECT
				COD_SEG_GROUP
			FROM SEGMENTS_GROUP
			WHERE [GROUP] = 'COMERCIO - D1')
END)
FROM SEGMENTS
WHERE LTRIM(REPLACE(REPLACE(SEGMENTS.NAME, 'D30 -', ''), 'D1 -', '')) IN
('COM�RCIO VAREJISTA DE MATERIAIS DE CONSTRU��O N�O ESPECIFICADOS ANTERIORMENTE, HIDR�ULICO, EL�TRICO,'
, 'LIVROS / DISCOS - CLUBES/LOJAS DE ENCOMENDAS POR CAT�LOGO/CLUBES DE DISCOS/ENCOMENDAS POSTAIS - ESTA'
, 'Servi�os Gerais'
, 'MANUTEN��O E REPARA��O DE EMBARCA��ES'
, 'COM�RCIO VAREJISTA DE MATERIAIS DE CONSTRU��O N�O ESPECIFICADOS ANTERIORMENTE, HIDR�ULICO, EL�TRICO'
, 'LIVROS / DISCOS - CLUBES/LOJAS DE ENCOMENDAS POR CAT�LOGO/CLUBES DE DISCOS/ENCOMENDAS POSTAIS - ESTA'
, 'Servi�os Gerais'
, 'D1 -MANUTEN��O E REPARA��O DE EMBARCA��ES'
, 'Administra��o de obras, restaura��o, constru��es de edificios, empreiteiros em geral - residencial e comercial'
, 'Ag�ncias de viagens / operadoras de turismo'
, 'Ag�ncias matrimoniais'
, 'Alojamento, higiene e embelezamento de animais / pet shop'
, 'Aluguel de objetos do vestu�rio, j�ias e acess�rios'
, 'Ambul�ncias - servi�os'
, 'Apart-hot�is, Hot�es, Mot�is, Albergues'
, 'Arte - marchands/Arte - galerias'
, 'Artes para publicidade - Artes Gr�ficas/Fotografia, Artes e Artes Gr�ficas - para publicidade/Artes Gr�ficas - para publicidade'
, 'Artesanato - lojas/Artigos para Pintura - lojas'
, 'Artigos para o lar - lojas'
, 'Artigos religiosos - lojas'
, 'Atividade m�dica ambulatorial com recursos para realiza��o de procedimentos cir�rgicos e exames complementares'
, 'Atividade odontol�gica / servi�os de pr�teses dentaria'
, 'Atividades auxiliares dos seguros, da previd�ncia complementar e dos planos de sa�de n�o especificadas anteriormente'
, 'Atividades auxiliares dos transportes a�reos, exceto opera��o dos aeroportos e campos de aterrissagem'
, 'Atividades de acupuntura'
, 'Atividades de apoio � agricultura , pecu�ria, pesca, apiculturan�o especificadas anteriormente'
, 'Atividades de assist�ncia psicossocial e � sa�de a portadores de dist�rbios ps�quicos, defici�ncia mental e depend�ncia qu�mica n�o especificadas anteriormente'
, 'Atividades de associa��es de defesa de direitos sociais / associa��es sociais'
, 'Atividades de aten��o ambulatorial n�o especificadas anteriormente'
, 'Atividades de atendimento em pronto-socorro e unidades hospitalares para atendimento a urg�ncias'
, 'Atividades de condicionamento f�sico'
, 'Atividades de consultoria e auditoria cont�bil e tribut�ria / contadores auditores'
, 'Atividades de consultoria em gest�o empresarial, exceto consultoria t�cnica espec�fica'
, 'Atividades de design n�o especificadas anteriormente / leiloeiros / web desing'
, 'Atividades de exibi��o cinematogr�fica, cinemas'
, 'Atividades de fisioterapia e fonoaudiologia'
, 'Atividades de organiza��es pol�ticas'
, 'Atividades de organiza��es religiosas ou filos�ficas'
, 'Atividades de podologia'
, 'Atividades de produ��o cinematogr�fica, de v�deos e de programas de televis�o n�o especificadas anteriormente'
, 'Atividades de produ��o de fotografias, filmagens'
, 'Atividades de psicologia e psican�lise'
, 'Atividades funer�rias e servi�os relacionados n�o especificados anteriormente, gest�o de servi�os funerarios'
, 'Atividades paisag�sticas / horticultura - servi�os'
, 'Atividades t�cnicas relacionadas � engenharia e arquitetura n�o especificadas anteriormente'
, 'Autom�veis - lojas de tintas automotivas/Pintura em autom�veis - oficinas'
, 'Autom�veis novos e usados - Revendedores Autorizados - ser/Caminh�es novos e usados - Revendedores Autorizados - serv'
, 'Bares e outros estabelecimentos especializados em servir bebidas'
, 'Cabeleireiros, manicure e pedicure, sal�es de beleza, barbearias'
, 'Campings'
, 'Casas lot�ricas'
, 'Casas-m�veis ( mobile homes) - revendedores'
, 'Chaveiros'
, 'Cl�nicas de est�tica e similares'
, 'Cl�nicas e resid�ncias geri�tricas'
, 'Com�rcio a varejo de pneum�ticos e c�maras-de-ar'
, 'Com�rcio atacadista de artigos de armarinho, tecidos, tape�aria, costuras e aviamentos em geral'
, 'Com�rcio atacadista de artigos de escrit�rio e de papelaria embalagem, papelarias'
, 'Com�rcio atacadista de artigos do vestu�rio e acess�rios, exceto profissionais e de seguran�a'
, 'Com�rcio atacadista de bicicletas, triciclos e outros ve�culos recreativos'
, 'Com�rcio atacadista de componentes eletr�nicos e equipamentos de telefonia e comunica��o'
, 'Com�rcio atacadista de cosm�ticos e produtos de perfumaria'
, 'Com�rcio atacadista de equipamentos e suprimentos de inform�tica'
, 'Com�rcio atacadista de equipamentos el�tricos de uso pessoal e dom�stico / lustres / luminarias'
, 'Com�rcio atacadista de ferragens e ferramentas, serralherias'
, 'Com�rcio atacadista de filmes, CDs, DVDs, fitas e discos'
, 'Com�rcio atacadista de m�quinas e equipamentos para uso comercial; partes e pe�as'
, 'Com�rcio atacadista de m�quinas, aparelhos e equipamentos para uso agropecu�rio; partes e pe�as'
, 'Com�rcio atacadista de m�quinas, aparelhos e equipamentos para uso odonto-m�dico-hospitalar; partes e pe�as, pr�teses e artigos de ortopedia, opticos'
, 'Com�rcio atacadista de massas aliment�cias'
, 'Com�rcio atacadista de materiais de constru��o em geral / marmores granitos vidros / pisos e azuleijos'
, 'Com�rcio atacadista de mercadorias em geral, com predomin�ncia de produtos aliment�cios'
, 'Com�rcio atacadista de m�veis e artigos de colchoaria / m�veis escritorio / madeira / metal / marcenaria'
, 'Com�rcio atacadista de outras m�quinas e equipamentos n�o especificados anteriormente; partes e pe�as'
, 'Com�rcio atacadista de p�es, bolos, biscoitos e similares, padarias'
, 'Com�rcio atacadista de papel e papel�o em bruto, residuos'
, 'Com�rcio atacadista de pescados e frutos do mar, peixes'
, 'Com�rcio atacadista de produtos de higiene, limpeza e conserva��o domiciliar'
, 'Com�rcio atacadista de res�duos e sucatas met�licos'
, 'Com�rcio atacadista de roupas e acess�rios para uso profissional e de seguran�a do trabalho'
, 'Com�rcio atacadista de sementes, flores, plantas e gramas'
, 'Com�rcio atacadista e representantes de com�rcio de livros, jornais e outras publica��es'
, 'Com�rcio atacadista especializado de materiais de constru��o n�o especificados anteriormente'
, 'Com�rcio de Auto Pe�as - Servi�os de manuten��o e reparo de acess�rios v�iculos automotores'
, 'Com�rcio varejista de animais vivos e de artigos e alimentos para animais de estima��o'
, 'Comercio varejista de artigos de armarinho e tecidos'
, 'Com�rcio varejista de artigos de ca�a, pesca e camping'
, 'Com�rcio varejista de artigos de joalheria e relojoaria'
, 'Com�rcio varejista de artigos de �ptica'
, 'Com�rcio varejista de artigos de tape�aria, cortinas e persianas'
, 'Com�rcio varejista de artigos de viagem'
, 'Com�rcio varejista de artigos do vestu�rio e acess�rios'
, 'Com�rcio varejista de artigos fotogr�ficos e para filmagem'
, 'Com�rcio varejista de artigos m�dicos e ortop�dicos'
, 'Com�rcio varejista de brinquedos e artigos recreativos'
, 'Com�rcio varejista de cal�ados, sapatarias'
, 'Com�rcio varejista de carnes - a�ougues, peixarias, congelados e resfriados'
, 'Com�rcio varejista de combust�veis para ve�culos automotores, postos de gasolina'
, 'Com�rcio varejista de cosm�ticos, produtos de perfumaria e de higiene pessoal'
, 'Com�rcio varejista de doces, balas, bombons e semelhantes'
, 'Com�rcio varejista de ferragens e ferramentas'
, 'Com�rcio varejista de jornais e revistas'
, 'Com�rcio varejista de materiais de constru��o n�o especificados anteriormente, hidr�lico, el�trico, serrarias'
, 'Com�rcio varejista de mercadorias em geral, com predomin�ncia de produtos aliment�cios - minimercados, mercearias e armaz�ns'
, 'Com�rcio varejista de outros produtos n�o especificados anteriormente'
, 'Com�rcio varejista de plantas e flores naturais, floricultura'
, 'Com�rcio varejista de produtos farmac�uticos, sem manipula��o de f�rmulas, farmacias e drogarias'
, 'Com�rcio varejista de suvenires, bijuterias e artesanatos'
, 'Com�rcio varejista de tintas e materiais para pintura, vidros, vidra�arias, papeis de parede - lojas'
, 'Com�rcio varejista especializado de eletrodom�sticos e equipamentos de �udio e v�deo'
, 'Com�rcio varejista especializado de equipamentos de telefonia e comunica��o'
, 'Com�rcio varejista especializado de equipamentos softwares e suprimentos de inform�tica'
, 'Com�rcio varejista especializado de instrumentos musicais e acess�rios'
, 'Com�rcio varejista especializado de pe�as e acess�rios para aparelhos eletroeletr�nicos para uso dom�stico, exceto inform�tica e comunica��o'
, 'Concession�rias de rodovias, pontes, t�neis, ped�gios e servi�os relacionados'
, 'Corretagem na compra e venda e avalia��o de im�veis'
, 'Cria��o de estandes para feiras e exposi��es, consultoria publicidade, agencias de publicidade'
, 'Dep�sito de mercadorias, p�blico/Armazenagem / guarda-m�veis'
, 'Design de interiores'
, 'Edi��o de cadastros, listas e outros produtos gr�ficos / publica��o e impress�o'
, 'Edi��o de jornais / livros / revistas'
, 'Edi��o integrada � impress�o de cadastros, listas e outros produtos gr�ficos'
, 'Empreiteiros- Instala��o e manuten��o el�trica'
, 'Empresas de saneamento/Empresas de energia el�trica/Empresas de fornecimento de g�s/Empresas de servi�os p�blicos - eletricidade, g�s, �gua, t/Empresas p�blicas de fornecimento de �gua'
, 'Entregas locais - servi�os/Companhias de mudan�a e guarda-m�veis/Transportadores de cargas/Transporte de carga rodovi�rio/Transporte por caminh�o - local/interestadual / carga e descarga'
, 'Equipamentos - vendas/Mobili�rio - lojas de mob�lia e artigos para o lar (exceto/Artigos e equipamentos para o lar, exceto eletrodom�sticos'
, 'Estabelecimento de vendas combinadas a varejo e por cat�logo'
, 'Estacionamento de ve�culos'
, 'Fabrica��o de letras, letreiros e placas de qualquer material, exceto luminosos, pr�-impress�o'
, 'Fabrica��o de perif�ricos para equipamentos de inform�tica / computadores, perif�ricos e softwares'
, 'Fabrica��o e Com�rcio atacadista de cal�ados'
, 'Fabrica��o e Com�rcio atacadista de j�ias, rel�gios e bijuterias, inclusive pedras preciosas e semipreciosas lapidadas'
, 'Fabrica��o e Com�rcio atacadista de tintas, vernizes e similares'
, 'Fabrica��o e Com�rcio por atacado de pe�as e acess�rios novos para ve�culos automotores'
, 'Gest�o de espa�os para artes c�nicas, espet�culos e outras atividades art�sticas'
, 'Gest�o de instala��es de esportes / Agenciamento de profissionais para atividades esportivas, culturais e art�sticas'
, 'Gest�o e administra��o da propriedade imobili�ria'
, 'Impress�o de material para uso publicit�rio'
, 'Imuniza��o e controle de pragas urbanas'
, 'Incorpora��o de empreendimentos imobili�rios'
, 'Instala��o de pain�is publicit�rios'
, 'Instala��o de portas, janelas, tetos, divis�rias e arm�rios embutidos de qualquer material - carpinteiros'
, 'Instala��o e manuten��o de sistemas centrais de ar condicionado, de ventila��o e refrigera��o, sanit�rias , hidr�ulicas e g�s'
, 'J�ias - consertos/Consertos em rel�gios/Rel�gios - consertos'
, 'Laborat�rios cl�nicos'
, 'Lanchonetes, casas de ch�, de sucos e similares redes fast food'
, 'Lavanderias, Tinturarias'
, 'Limpeza de carpetes/tapetes/Estofados - limpeza'
, 'Livros / discos - clubes/Lojas de encomendas por cat�logo/Clubes de discos/Encomendas postais - Estabelecimento'
, 'Loca��o de autom�veis sem condutor'
, 'Loca��o de embarca��es sem tripula��o, exceto para fins recreativos'
, 'Lojas de alimentos finos e especialidades/Frutos do mar - mercados/Mercados de verduras e frutas/Alimentos finos - lojas/A�ougues/Delicatessens/Lojas de conveni�ncia'
, 'Lojas de departamentos, variedades ou magazines'
, 'Lojas de �culos/Artigos �ticos'
, 'Manuten��o e repara��o de embarca��es e estruturas flutuantes'
, 'Oficinas de consertos e servi�os similares - diversos'
, 'Oftalmologistas/Optometristas'
, 'Opera��o dos aeroportos e campos de aterrissagem'
, 'Operadoras de televis�o por assinatura por microondas / sat�lite / servi�os de TV a cabo'
, 'Orquestras/Bandas - conjuntos musicais/Animadores / produ��o musical'
, 'Outras atividades de ensino n�o especificadas anteriormente'
, 'Outras atividades de publicidade n�o especificadas anteriormente'
, 'Outras atividades de recrea��o e lazer n�o especificadas anteriormente'
, 'Outras atividades profissionais, cient�ficas e t�cnicas n�o especificadas anteriormente'
, 'Outras obras de instala��es em constru��es n�o especificadas anteriormente'
, 'Outros representantes comerciais e agentes do com�rcio especializado em produtos n�o especificados anteriormente'
, 'Outros servi�os de acabamento em fios, tecidos, artefatos t�xteis e pe�as do vestu�rio'
, 'Parques de divers�o/Circos/Cartomantes, videntes e outros leitores da sorte/Feiras de Divers�o'
, 'Passes para transporte urbano e suburbano/Barcas, transporte aqu�tico local/Transporte de passageiros urbanos/suburbanos'
, 'Piscinas - vendas, servi�os e suprimentos'
, 'Planos de aux�lio-funeral, planos de saude'
, 'Portais, provedores de conte�do e outros servi�os de informa��o na internet'
, 'Prepara��o de documentos e servi�os especializados de apoio administrativo n�o especificados anteriormente'
, 'Presta��o de servi�os relacionados com viagens, atrav�s de'
, 'Previd�ncia complementar aberta e fechada'
, 'Promo��o de Vendas'
, 'Quiropr�ticos'
, 'Recupera��o de materiais met�licos, exceto alum�nio, sucatas de alum�nio, ferro-velho'
, 'Reformas e consertos - alfaiates e costureiras/Alfaiates e costureiras - consertos e reformas'
, 'Repara��o de artigos do mobili�rio, reformas de estofados'
, 'Repara��o de cal�ados, bolsas e artigos de viagem, sapateiros'
, 'Repara��o e manuten��o de computadores e de equipamentos perif�ricos'
, 'Repara��o e manuten��o de equipamentos de comunica��o, tvs radiosrefrigera��o ar condicionado'
, 'Repara��o e manuten��o de equipamentos eletroeletr�nicos de uso pessoal e dom�stico'
, 'Representantes comerciais e agentes do com�rcio de m�quinas, equipamentos, embarca��es e aeronaves'
, 'Representantes comerciais e agentes do com�rcio de medicamentos, cosm�ticos e produtos de perfumaria'
, 'Representantes comerciais e agentes do com�rcio de mercadorias em geral n�o especializado'
, 'Representantes comerciais e agentes do com�rcio de motocicletas e motonetas, pe�as e acess�rios'
, 'Representantes comerciais e agentes do com�rcio de pe�as e acess�rios novos e usados para ve�culos automotores'
, 'Representantes comerciais e agentes do com�rcio de produtos aliment�cios, bebidas e fumo'
, 'Representantes comerciais e agentes do com�rcio de t�xteis, vestu�rio, roupascal�ados e artigos de viagem'
, 'Restaurantes e Cantinas - servi�os de alimenta��o'
, 'Revendedores de madeiras/Revendedores de �leo combust�vel/Revendedores de petr�leo liq�efeito/Carv�o mineral - revendedores'
, 'Servi�o de t�xi'
, 'Servi�o de t�xi a�reo e loca��o de aeronaves com tripula��o / transporte a�reo de carga'
, 'Servi�os advocat�cios'
, 'Servi�os ambulantes de alimenta��o'
, 'Servi�os combinados de escrit�rio e apoio administrativo'
, 'Servi�os de adestramento de c�es de guarda'
, 'Servi�os de alimenta��o para eventos e recep��es - buf�'
, 'Servi�os de alinhamento e balanceamento de ve�culos automotores, auto eletrico'
, 'Servi�os de bab� ( babysitting)'
, 'Servi�os de borracharia para ve�culos automotores'
, 'Servi�os de confec��o de arma��es met�licas para a constru��o'
, 'Servi�os de encaderna��o e plastifica��o, acabamento grafico, gr�ficas, fotoc�pias'
, 'Servi�os de lanternagem ou funilaria e pintura de ve�culos automotores'
, 'Servi�os de lavagem, lubrifica��o e polimento de ve�culos automotores, lava-jatos'
, 'Servi�os de limpeza de janelas'
, 'Servi�os de malote n�o realizados pelo Correio Nacional / entregas rapidas / agenciamento de cargas'
, 'Servi�os de manuten��o e repara��o mec�nica de ve�culos automotores'
, 'Servi�os de organiza��o de feiras, congressos, exposi��es e festas, atra��es tur�sticas, eventos'
, 'Servi�os de pintura de edif�cios em geral'
, 'Servi�os de reservas e outros servi�os de turismo n�o especificados anteriormente'
, 'Servi�os de seguro por Marketing Direto'
, 'Servi�os de tatuagem e coloca��o de piercing'
, 'Servi�os de tradu��o, interpreta��o e similares'
, 'Servi�os de usinagem, solda, tratamento e revestimento em metais'
, 'Servi�os veterin�rios'
, 'Sociedade seguradora de seguros n�o vida, vida e saude'
, 'Suporte t�cnico, manuten��o e outros servi�os em tecnologia da informa��o'
, 'Tabacaria'
, 'Terminais rodovi�rios e ferrovi�rios'
, 'Transporte escolar'
, 'Transporte rodovi�rio coletivo de passageiros, sob regime de fretamento, intermunicipal, interestadual e internacional'
, 'Tratamento de dados, provedores de servi�os de aplica��o e servi�os de hospedagem na internet'
, 'Tratamentos t�rmicos, ac�sticos ou de vibra��o, obras de alvenaria'
, 'Trens tur�sticos, telef�ricos e similares'
, 'Ve�culos para recrea��o - aluguel/Motor-homes - aluguel'
, 'Vendas porta a porta/Estabelecimentos de vendas diretas'
, 'Vendedores por cat�logo'
, 'Vestu�rio esportivo - lojas/Roupas - esportivas e de equita��o/Lojas de artigos para equita��o'
, 'Viveiros de plantas - lojas de artigos para jardins e gram/Jardins e gramados / viveiros de plantas - lojas de artigo'
);

GO

UPDATE SEGMENTS
SET COD_SEG_GROUP = (CASE
	WHEN NAME LIKE '%D30%' THEN (SELECT
				COD_SEG_GROUP
			FROM SEGMENTS_GROUP
			WHERE [GROUP] = 'CURSOS')
	WHEN NAME LIKE '%D1%' THEN (SELECT
				COD_SEG_GROUP
			FROM SEGMENTS_GROUP
			WHERE [GROUP] = 'CURSOS - D1')
END)

FROM SEGMENTS
WHERE LTRIM(REPLACE(REPLACE(SEGMENTS.NAME, 'D30 -', ''), 'D1 -', '')) IN
(
'Artes c�nicas, espet�culos e atividades complementares n�o especificados anteriormente'
, 'Educa��o infantil - creche / pr� escola / maternal / day care'
, 'Educa��o superior - gradua��o / p�s-gradua��o / escolas profissionalizantes'
, 'Ensino de dan�a'
, 'Ensino de idiomas / m�sica / esportes / preparat�rio para concursos'
, 'Escolas secund�rias/Escolas prim�rias e jardins de inf�ncia/Escolas - prim�ria e secund�ria'
, 'Treinamento em desenvolvimento profissional e gerencial'
);

GO
UPDATE COMMERCIAL_ESTABLISHMENT
SET COD_SEG = (SELECT
		SEGMENTS_NEW.COD_SEG
	FROM SEGMENTS
	INNER JOIN SEGMENTS SEGMENTS_NEW
		ON LTRIM(REPLACE(REPLACE(SEGMENTS_NEW.NAME, 'D30 -', ''), 'D1 -', '')) = LTRIM(REPLACE(REPLACE(SEGMENTS.NAME, 'D30 -', ''), 'D1 -', ''))
		AND SEGMENTS_NEW.NAME LIKE 'D1%'
	WHERE SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG)
FROM COMMERCIAL_ESTABLISHMENT
WHERE CPF_CNPJ
IN
(
'28090700000133'
, '27502561000145'
, '30997007000190'
, '06982591000126'
, '53294997000104'
, '15299965000102'
, '32060866000184'
, '30549213000138'
, '08924886000171'
, '19578397000121'
, '28026279000100'
, '18558605000168'
, '34383796000120'
, '28236906000129'
, '64498355000135'
, '33191588000167'
, '14629959000103'
, '22181773000154'
, '08704266000127'
, '17547236000145'
, '30286076000196'
, '21210181000150'
, '29979170000141'
, '27208913000154'
, '31685180000116'
, '17097053000175'
, '12605769000112'
, '12266945000139'
, '09615853000102'
, '17385839000198'
, '07317865000125'
, '05643915000139'
, '07881588000189'
, '11929751000103'
, '33924949000137'
, '31325281000186'
, '32866528000134'
, '09570595000195'
, '52594355000150'
, '12366680000140'
, '19287509000195'
, '17783574000186'
, '33590706000100'
, '30669930000101'
);


GO


GO

DECLARE @COD_EQUIP INT;
DECLARE @COD_AC_CORRECT INT;
DECLARE @COD_DATA_TID_AVAILABLE INT;
DECLARE @TID VARCHAR(200);

DECLARE @SERIAL_NEW_TID AS CURSOR;


SET @SERIAL_NEW_TID = CURSOR FOR SELECT DISTINCT
	VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EQUIP
	--,DATA_EQUIPMENT_AC.COD_AC
   ,ACQUIRER.COD_AC
FROM VW_COMPANY_EC_AFF_BR_DEP_EQUIP
INNER JOIN DATA_EQUIPMENT_AC
	ON DATA_EQUIPMENT_AC.COD_EQUIP = VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EQUIP
	AND DATA_EQUIPMENT_AC.ACTIVE = 1
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EC
INNER JOIN SEGMENTS
	ON SEGMENTS.COD_SEG = COMMERCIAL_ESTABLISHMENT.COD_SEG
INNER JOIN SEGMENTS_GROUP
	ON SEGMENTS_GROUP.COD_SEG_GROUP = SEGMENTS.COD_SEG_GROUP
INNER JOIN ACQUIRER
	ON ACQUIRER.COD_SEG_GROUP = SEGMENTS_GROUP.COD_SEG_GROUP
WHERE DATA_EQUIPMENT_AC.COD_AC <> ACQUIRER.COD_AC
GROUP BY VW_COMPANY_EC_AFF_BR_DEP_EQUIP.COD_EQUIP
		,ACQUIRER.COD_AC
 


OPEN @SERIAL_NEW_TID;

FETCH NEXT FROM @SERIAL_NEW_TID INTO @COD_EQUIP, @COD_AC_CORRECT;

WHILE @@fetch_status = 0
BEGIN

SELECT
	@COD_DATA_TID_AVAILABLE = COD_DATA_EQUIP
   ,@TID = TID
FROM DATA_TID_AVAILABLE_EC
WHERE ACTIVE = 1
AND AVAILABLE = 1
AND COD_AC = @COD_AC_CORRECT;

IF (@TID IS NOT NULL)
BEGIN

IF (SELECT
			COUNT(*)
		FROM DATA_EQUIPMENT_AC
		WHERE COD_EQUIP = @COD_EQUIP
		AND COD_AC = @COD_AC_CORRECT
		AND ACTIVE = 1)
	= 0
BEGIN

INSERT INTO DATA_EQUIPMENT_AC (CREATED_AT, COD_EQUIP, COD_COMP, COD_AC, NAME, CODE, ACTIVE)
	VALUES (current_timestamp, @COD_EQUIP, 8, @COD_AC_CORRECT, 'TID', @TID, 1);

UPDATE DATA_TID_AVAILABLE_EC
SET ACTIVE = 0
   ,AVAILABLE = 0
WHERE COD_DATA_EQUIP = @COD_DATA_TID_AVAILABLE

END

FETCH NEXT FROM @SERIAL_NEW_TID INTO @COD_EQUIP, @COD_AC_CORRECT;
END;


END;

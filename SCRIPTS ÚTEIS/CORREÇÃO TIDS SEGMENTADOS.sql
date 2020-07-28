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
('COMÉRCIO VAREJISTA DE MATERIAIS DE CONSTRUÇÃO NÃO ESPECIFICADOS ANTERIORMENTE, HIDRÁULICO, ELÉTRICO,'
, 'LIVROS / DISCOS - CLUBES/LOJAS DE ENCOMENDAS POR CATÁLOGO/CLUBES DE DISCOS/ENCOMENDAS POSTAIS - ESTA'
, 'Serviços Gerais'
, 'MANUTENÇÃO E REPARAÇÃO DE EMBARCAÇÕES'
, 'COMÉRCIO VAREJISTA DE MATERIAIS DE CONSTRUÇÃO NÃO ESPECIFICADOS ANTERIORMENTE, HIDRÁULICO, ELÉTRICO'
, 'LIVROS / DISCOS - CLUBES/LOJAS DE ENCOMENDAS POR CATÁLOGO/CLUBES DE DISCOS/ENCOMENDAS POSTAIS - ESTA'
, 'Serviços Gerais'
, 'D1 -MANUTENÇÃO E REPARAÇÃO DE EMBARCAÇÕES'
, 'Administração de obras, restauração, construções de edificios, empreiteiros em geral - residencial e comercial'
, 'Agências de viagens / operadoras de turismo'
, 'Agências matrimoniais'
, 'Alojamento, higiene e embelezamento de animais / pet shop'
, 'Aluguel de objetos do vestuário, jóias e acessórios'
, 'Ambulâncias - serviços'
, 'Apart-hotéis, Hotíes, Motéis, Albergues'
, 'Arte - marchands/Arte - galerias'
, 'Artes para publicidade - Artes Gráficas/Fotografia, Artes e Artes Gráficas - para publicidade/Artes Gráficas - para publicidade'
, 'Artesanato - lojas/Artigos para Pintura - lojas'
, 'Artigos para o lar - lojas'
, 'Artigos religiosos - lojas'
, 'Atividade médica ambulatorial com recursos para realização de procedimentos cirúrgicos e exames complementares'
, 'Atividade odontológica / serviços de próteses dentaria'
, 'Atividades auxiliares dos seguros, da previdência complementar e dos planos de saúde não especificadas anteriormente'
, 'Atividades auxiliares dos transportes aéreos, exceto operação dos aeroportos e campos de aterrissagem'
, 'Atividades de acupuntura'
, 'Atividades de apoio à agricultura , pecuária, pesca, apiculturanão especificadas anteriormente'
, 'Atividades de assistência psicossocial e à saúde a portadores de distúrbios psíquicos, deficiência mental e dependência química não especificadas anteriormente'
, 'Atividades de associações de defesa de direitos sociais / associações sociais'
, 'Atividades de atenção ambulatorial não especificadas anteriormente'
, 'Atividades de atendimento em pronto-socorro e unidades hospitalares para atendimento a urgências'
, 'Atividades de condicionamento físico'
, 'Atividades de consultoria e auditoria contábil e tributária / contadores auditores'
, 'Atividades de consultoria em gestão empresarial, exceto consultoria técnica específica'
, 'Atividades de design não especificadas anteriormente / leiloeiros / web desing'
, 'Atividades de exibição cinematográfica, cinemas'
, 'Atividades de fisioterapia e fonoaudiologia'
, 'Atividades de organizações políticas'
, 'Atividades de organizações religiosas ou filosóficas'
, 'Atividades de podologia'
, 'Atividades de produção cinematográfica, de vídeos e de programas de televisão não especificadas anteriormente'
, 'Atividades de produção de fotografias, filmagens'
, 'Atividades de psicologia e psicanálise'
, 'Atividades funerárias e serviços relacionados não especificados anteriormente, gestão de serviços funerarios'
, 'Atividades paisagísticas / horticultura - serviços'
, 'Atividades técnicas relacionadas à engenharia e arquitetura não especificadas anteriormente'
, 'Automóveis - lojas de tintas automotivas/Pintura em automóveis - oficinas'
, 'Automóveis novos e usados - Revendedores Autorizados - ser/Caminhões novos e usados - Revendedores Autorizados - serv'
, 'Bares e outros estabelecimentos especializados em servir bebidas'
, 'Cabeleireiros, manicure e pedicure, salões de beleza, barbearias'
, 'Campings'
, 'Casas lotéricas'
, 'Casas-móveis ( mobile homes) - revendedores'
, 'Chaveiros'
, 'Clínicas de estética e similares'
, 'Clínicas e residências geriátricas'
, 'Comércio a varejo de pneumáticos e câmaras-de-ar'
, 'Comércio atacadista de artigos de armarinho, tecidos, tapeçaria, costuras e aviamentos em geral'
, 'Comércio atacadista de artigos de escritório e de papelaria embalagem, papelarias'
, 'Comércio atacadista de artigos do vestuário e acessórios, exceto profissionais e de segurança'
, 'Comércio atacadista de bicicletas, triciclos e outros veículos recreativos'
, 'Comércio atacadista de componentes eletrônicos e equipamentos de telefonia e comunicação'
, 'Comércio atacadista de cosméticos e produtos de perfumaria'
, 'Comércio atacadista de equipamentos e suprimentos de informática'
, 'Comércio atacadista de equipamentos elétricos de uso pessoal e doméstico / lustres / luminarias'
, 'Comércio atacadista de ferragens e ferramentas, serralherias'
, 'Comércio atacadista de filmes, CDs, DVDs, fitas e discos'
, 'Comércio atacadista de máquinas e equipamentos para uso comercial; partes e peças'
, 'Comércio atacadista de máquinas, aparelhos e equipamentos para uso agropecuário; partes e peças'
, 'Comércio atacadista de máquinas, aparelhos e equipamentos para uso odonto-médico-hospitalar; partes e peças, próteses e artigos de ortopedia, opticos'
, 'Comércio atacadista de massas alimentícias'
, 'Comércio atacadista de materiais de construção em geral / marmores granitos vidros / pisos e azuleijos'
, 'Comércio atacadista de mercadorias em geral, com predominância de produtos alimentícios'
, 'Comércio atacadista de móveis e artigos de colchoaria / móveis escritorio / madeira / metal / marcenaria'
, 'Comércio atacadista de outras máquinas e equipamentos não especificados anteriormente; partes e peças'
, 'Comércio atacadista de pães, bolos, biscoitos e similares, padarias'
, 'Comércio atacadista de papel e papelão em bruto, residuos'
, 'Comércio atacadista de pescados e frutos do mar, peixes'
, 'Comércio atacadista de produtos de higiene, limpeza e conservação domiciliar'
, 'Comércio atacadista de resíduos e sucatas metálicos'
, 'Comércio atacadista de roupas e acessórios para uso profissional e de segurança do trabalho'
, 'Comércio atacadista de sementes, flores, plantas e gramas'
, 'Comércio atacadista e representantes de comércio de livros, jornais e outras publicações'
, 'Comércio atacadista especializado de materiais de construção não especificados anteriormente'
, 'Comércio de Auto Peças - Serviços de manutenção e reparo de acessórios véiculos automotores'
, 'Comércio varejista de animais vivos e de artigos e alimentos para animais de estimação'
, 'Comercio varejista de artigos de armarinho e tecidos'
, 'Comércio varejista de artigos de caça, pesca e camping'
, 'Comércio varejista de artigos de joalheria e relojoaria'
, 'Comércio varejista de artigos de óptica'
, 'Comércio varejista de artigos de tapeçaria, cortinas e persianas'
, 'Comércio varejista de artigos de viagem'
, 'Comércio varejista de artigos do vestuário e acessórios'
, 'Comércio varejista de artigos fotográficos e para filmagem'
, 'Comércio varejista de artigos médicos e ortopédicos'
, 'Comércio varejista de brinquedos e artigos recreativos'
, 'Comércio varejista de calçados, sapatarias'
, 'Comércio varejista de carnes - açougues, peixarias, congelados e resfriados'
, 'Comércio varejista de combustíveis para veículos automotores, postos de gasolina'
, 'Comércio varejista de cosméticos, produtos de perfumaria e de higiene pessoal'
, 'Comércio varejista de doces, balas, bombons e semelhantes'
, 'Comércio varejista de ferragens e ferramentas'
, 'Comércio varejista de jornais e revistas'
, 'Comércio varejista de materiais de construção não especificados anteriormente, hidrúlico, elétrico, serrarias'
, 'Comércio varejista de mercadorias em geral, com predominância de produtos alimentícios - minimercados, mercearias e armazéns'
, 'Comércio varejista de outros produtos não especificados anteriormente'
, 'Comércio varejista de plantas e flores naturais, floricultura'
, 'Comércio varejista de produtos farmacêuticos, sem manipulação de fórmulas, farmacias e drogarias'
, 'Comércio varejista de suvenires, bijuterias e artesanatos'
, 'Comércio varejista de tintas e materiais para pintura, vidros, vidraçarias, papeis de parede - lojas'
, 'Comércio varejista especializado de eletrodomésticos e equipamentos de áudio e vídeo'
, 'Comércio varejista especializado de equipamentos de telefonia e comunicação'
, 'Comércio varejista especializado de equipamentos softwares e suprimentos de informática'
, 'Comércio varejista especializado de instrumentos musicais e acessórios'
, 'Comércio varejista especializado de peças e acessórios para aparelhos eletroeletrônicos para uso doméstico, exceto informática e comunicação'
, 'Concessionárias de rodovias, pontes, túneis, pedágios e serviços relacionados'
, 'Corretagem na compra e venda e avaliação de imóveis'
, 'Criação de estandes para feiras e exposições, consultoria publicidade, agencias de publicidade'
, 'Depósito de mercadorias, público/Armazenagem / guarda-móveis'
, 'Design de interiores'
, 'Edição de cadastros, listas e outros produtos gráficos / publicação e impressão'
, 'Edição de jornais / livros / revistas'
, 'Edição integrada à impressão de cadastros, listas e outros produtos gráficos'
, 'Empreiteiros- Instalação e manutenção elétrica'
, 'Empresas de saneamento/Empresas de energia elétrica/Empresas de fornecimento de gás/Empresas de serviços públicos - eletricidade, gás, água, t/Empresas públicas de fornecimento de água'
, 'Entregas locais - serviços/Companhias de mudança e guarda-móveis/Transportadores de cargas/Transporte de carga rodoviário/Transporte por caminhão - local/interestadual / carga e descarga'
, 'Equipamentos - vendas/Mobiliário - lojas de mobília e artigos para o lar (exceto/Artigos e equipamentos para o lar, exceto eletrodomésticos'
, 'Estabelecimento de vendas combinadas a varejo e por catálogo'
, 'Estacionamento de veículos'
, 'Fabricação de letras, letreiros e placas de qualquer material, exceto luminosos, pré-impressão'
, 'Fabricação de periféricos para equipamentos de informática / computadores, periféricos e softwares'
, 'Fabricação e Comércio atacadista de calçados'
, 'Fabricação e Comércio atacadista de jóias, relógios e bijuterias, inclusive pedras preciosas e semipreciosas lapidadas'
, 'Fabricação e Comércio atacadista de tintas, vernizes e similares'
, 'Fabricação e Comércio por atacado de peças e acessórios novos para veículos automotores'
, 'Gestão de espaços para artes cênicas, espetáculos e outras atividades artísticas'
, 'Gestão de instalações de esportes / Agenciamento de profissionais para atividades esportivas, culturais e artísticas'
, 'Gestão e administração da propriedade imobiliária'
, 'Impressão de material para uso publicitário'
, 'Imunização e controle de pragas urbanas'
, 'Incorporação de empreendimentos imobiliários'
, 'Instalação de painéis publicitários'
, 'Instalação de portas, janelas, tetos, divisórias e armários embutidos de qualquer material - carpinteiros'
, 'Instalação e manutenção de sistemas centrais de ar condicionado, de ventilação e refrigeração, sanitárias , hidráulicas e gás'
, 'Jóias - consertos/Consertos em relógios/Relógios - consertos'
, 'Laboratórios clínicos'
, 'Lanchonetes, casas de chá, de sucos e similares redes fast food'
, 'Lavanderias, Tinturarias'
, 'Limpeza de carpetes/tapetes/Estofados - limpeza'
, 'Livros / discos - clubes/Lojas de encomendas por catálogo/Clubes de discos/Encomendas postais - Estabelecimento'
, 'Locação de automóveis sem condutor'
, 'Locação de embarcações sem tripulação, exceto para fins recreativos'
, 'Lojas de alimentos finos e especialidades/Frutos do mar - mercados/Mercados de verduras e frutas/Alimentos finos - lojas/Açougues/Delicatessens/Lojas de conveniência'
, 'Lojas de departamentos, variedades ou magazines'
, 'Lojas de óculos/Artigos óticos'
, 'Manutenção e reparação de embarcações e estruturas flutuantes'
, 'Oficinas de consertos e serviços similares - diversos'
, 'Oftalmologistas/Optometristas'
, 'Operação dos aeroportos e campos de aterrissagem'
, 'Operadoras de televisão por assinatura por microondas / satélite / serviços de TV a cabo'
, 'Orquestras/Bandas - conjuntos musicais/Animadores / produção musical'
, 'Outras atividades de ensino não especificadas anteriormente'
, 'Outras atividades de publicidade não especificadas anteriormente'
, 'Outras atividades de recreação e lazer não especificadas anteriormente'
, 'Outras atividades profissionais, científicas e técnicas não especificadas anteriormente'
, 'Outras obras de instalações em construções não especificadas anteriormente'
, 'Outros representantes comerciais e agentes do comércio especializado em produtos não especificados anteriormente'
, 'Outros serviços de acabamento em fios, tecidos, artefatos têxteis e peças do vestuário'
, 'Parques de diversão/Circos/Cartomantes, videntes e outros leitores da sorte/Feiras de Diversão'
, 'Passes para transporte urbano e suburbano/Barcas, transporte aquático local/Transporte de passageiros urbanos/suburbanos'
, 'Piscinas - vendas, serviços e suprimentos'
, 'Planos de auxílio-funeral, planos de saude'
, 'Portais, provedores de conteúdo e outros serviços de informação na internet'
, 'Preparação de documentos e serviços especializados de apoio administrativo não especificados anteriormente'
, 'Prestação de serviços relacionados com viagens, através de'
, 'Previdência complementar aberta e fechada'
, 'Promoção de Vendas'
, 'Quiropráticos'
, 'Recuperação de materiais metálicos, exceto alumínio, sucatas de alumínio, ferro-velho'
, 'Reformas e consertos - alfaiates e costureiras/Alfaiates e costureiras - consertos e reformas'
, 'Reparação de artigos do mobiliário, reformas de estofados'
, 'Reparação de calçados, bolsas e artigos de viagem, sapateiros'
, 'Reparação e manutenção de computadores e de equipamentos periféricos'
, 'Reparação e manutenção de equipamentos de comunicação, tvs radiosrefrigeração ar condicionado'
, 'Reparação e manutenção de equipamentos eletroeletrônicos de uso pessoal e doméstico'
, 'Representantes comerciais e agentes do comércio de máquinas, equipamentos, embarcações e aeronaves'
, 'Representantes comerciais e agentes do comércio de medicamentos, cosméticos e produtos de perfumaria'
, 'Representantes comerciais e agentes do comércio de mercadorias em geral não especializado'
, 'Representantes comerciais e agentes do comércio de motocicletas e motonetas, peças e acessórios'
, 'Representantes comerciais e agentes do comércio de peças e acessórios novos e usados para veículos automotores'
, 'Representantes comerciais e agentes do comércio de produtos alimentícios, bebidas e fumo'
, 'Representantes comerciais e agentes do comércio de têxteis, vestuário, roupascalçados e artigos de viagem'
, 'Restaurantes e Cantinas - serviços de alimentação'
, 'Revendedores de madeiras/Revendedores de óleo combustível/Revendedores de petróleo liqüefeito/Carvão mineral - revendedores'
, 'Serviço de táxi'
, 'Serviço de táxi aéreo e locação de aeronaves com tripulação / transporte aéreo de carga'
, 'Serviços advocatícios'
, 'Serviços ambulantes de alimentação'
, 'Serviços combinados de escritório e apoio administrativo'
, 'Serviços de adestramento de cães de guarda'
, 'Serviços de alimentação para eventos e recepções - bufê'
, 'Serviços de alinhamento e balanceamento de veículos automotores, auto eletrico'
, 'Serviços de babá ( babysitting)'
, 'Serviços de borracharia para veículos automotores'
, 'Serviços de confecção de armações metálicas para a construção'
, 'Serviços de encadernação e plastificação, acabamento grafico, gráficas, fotocópias'
, 'Serviços de lanternagem ou funilaria e pintura de veículos automotores'
, 'Serviços de lavagem, lubrificação e polimento de veículos automotores, lava-jatos'
, 'Serviços de limpeza de janelas'
, 'Serviços de malote não realizados pelo Correio Nacional / entregas rapidas / agenciamento de cargas'
, 'Serviços de manutenção e reparação mecânica de veículos automotores'
, 'Serviços de organização de feiras, congressos, exposições e festas, atrações turísticas, eventos'
, 'Serviços de pintura de edifícios em geral'
, 'Serviços de reservas e outros serviços de turismo não especificados anteriormente'
, 'Serviços de seguro por Marketing Direto'
, 'Serviços de tatuagem e colocação de piercing'
, 'Serviços de tradução, interpretação e similares'
, 'Serviços de usinagem, solda, tratamento e revestimento em metais'
, 'Serviços veterinários'
, 'Sociedade seguradora de seguros não vida, vida e saude'
, 'Suporte técnico, manutenção e outros serviços em tecnologia da informação'
, 'Tabacaria'
, 'Terminais rodoviários e ferroviários'
, 'Transporte escolar'
, 'Transporte rodoviário coletivo de passageiros, sob regime de fretamento, intermunicipal, interestadual e internacional'
, 'Tratamento de dados, provedores de serviços de aplicação e serviços de hospedagem na internet'
, 'Tratamentos térmicos, acústicos ou de vibração, obras de alvenaria'
, 'Trens turísticos, teleféricos e similares'
, 'Veículos para recreação - aluguel/Motor-homes - aluguel'
, 'Vendas porta a porta/Estabelecimentos de vendas diretas'
, 'Vendedores por catálogo'
, 'Vestuário esportivo - lojas/Roupas - esportivas e de equitação/Lojas de artigos para equitação'
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
'Artes cênicas, espetáculos e atividades complementares não especificados anteriormente'
, 'Educação infantil - creche / pré escola / maternal / day care'
, 'Educação superior - graduação / pós-graduação / escolas profissionalizantes'
, 'Ensino de dança'
, 'Ensino de idiomas / música / esportes / preparatório para concursos'
, 'Escolas secundárias/Escolas primárias e jardins de infância/Escolas - primária e secundária'
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

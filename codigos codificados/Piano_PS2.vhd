LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY Piano_PS2 IS
	PORT (
		onboard_clk , keyboard_clk , data_in : in std_logic;
		buzzer : out std_logic
		
	);

	-- onboard_clk é para o clock da Max II
	-- keyboard_clk é para o clk que o teclado conectado fornece
	-- data_in é a linha de comunicação entre o teclado e a Max II
	-- buzzer é a saída de audio
	
END Piano_PS2;

ARCHITECTURE Main OF Piano_PS2 IS

SIGNAL CLKCOUNT : integer RANGE 0 TO 50000000 := 0;
SIGNAL BFREQ : integer RANGE 0 TO 50000000 := 5952;
SIGNAL SEGUNDO : integer RANGE 0 TO 50000000 := 0;
SIGNAL BUZZ : std_logic := '0';

-- CLKCOUNT é usado na geração de audio, para gerar uma frequência eu preciso fazer conversões com o clock da Max II
-- BFREQ é usado como parametro para gerar a frequência
-- SEGUNDO é usado para contar o tempo de um segundo (1 clock de 50 Mhz na Max II)
-- BUZZ a linha interna que sera usada para fazer interface entre o pino físico e o sinal gerado

-- OBS:
-- para gerar um tom de 440Hz no buzzer, preciso que o código use o clock da placa
-- portanto faço ( ( 50000000 / 440 ) / 2 ) = 56818 (dividido por 2 por que um sinal é formado metade por uma subida e metade uma decida)

TYPE estados IS (first , data , parity , final); -- usamos uma maquina de estados, o vdhl não é uma linguagem sequencial, por isso precisamos garantir que partes do código só sejam executadas em um estado especifico

-- first = primeiro bit, se preparando para receber um comando
-- data = lê e decodifica o comando recebido
-- parity = não faz nada, mas precisa ser seu estado próprio porque o teclado ainda manda...
-- final = fim da comunicação, verifica se o comando é valido, volta a máquina ao inicio caso outro comando chegue

SIGNAL maquina : estados := first; -- por padrão iniciamos a maquina no estado final
-- isso porque o estado final serve também como um modo de espera, já que no código desse estado qualquer nova comunicação vai voltar a máquina para o ínicio "first"

SIGNAL i : integer RANGE 0 TO 10 := 0; -- usada pelo programa para marcar qual bit esta sendo lido no estado "data"
SIGNAL code : std_logic_vector (7 downto 0) := "00000000"; -- local onde o comando decodificado é armazenado

BEGIN

-- processos relacionados a audio ------------------------------------------------------------------------------------------------------
	
	PROCESS(onboard_clk)
	BEGIN
	
	-- gerador de tom
	
	IF RISING_EDGE(onboard_clk) THEN -- gera uma onda quadrada, alternando entre ALTO e BAIXO a cada meio tempo da frequência desejada
	
		IF CLKCOUNT < BFREQ THEN -- espera meio tempo
		
			CLKCOUNT <= CLKCOUNT + 1;
			
		ELSE -- alterna ao oposto do estado atual da linha
		
			BUZZ <= NOT BUZZ;
			CLKCOUNT <= 0;
		
		END IF;
	END IF;
	
	END PROCESS;
	
	PROCESS(onboard_clk)
	BEGIN
	
	-- controla a saida do buzzer para liberar o som
	
	IF RISING_EDGE(onboard_clk) THEN

	-- como só vamos usar algumas das teclas, usamos um case, já que ele tem um comando chamado "WHEN OTHERS"
	-- em português "qualquer outro", isso facilita tudo pois podemos usar esse comando para fazer com que
	-- qualquer outra tecla indesejada / não especificada simplesmente não faça nada
		
	CASE code IS -- analisando o bus com o ultimo comando recebido do teclado
		WHEN "00011100" => -- se o ultimo comando recebido for "00011100" ou "1C" em hexadecimal, então a tecla "A" foi apertada

			BFREQ <= 23900; -- muda a frequência para a desejada para a tecla "a"
			buzzer <= BUZZ; -- libera o tom gerado para o buzzer
			
		WHEN "00110011" => -- "H"

			BFREQ <= 15954; 
			buzzer <= BUZZ;
		
		WHEN "00100011" => -- "s"

			BFREQ <= 18968; 
			buzzer <= BUZZ; 
		
		WHEN "00011011" => -- "D"

			BFREQ <= 21294; 
			buzzer <= BUZZ; 
		
		WHEN "00101011" => -- "F"

			BFREQ <= 17908; 
			buzzer <= BUZZ; 
		
		WHEN "00111011" => -- "J"

			BFREQ <= 14204; 
			buzzer <= BUZZ; 
		
		WHEN "01000010" => -- "K"

			BFREQ <= 12658; 
			buzzer <= BUZZ; 
		
		WHEN "01001011" => -- "L"

			BFREQ <= 11944; 
			buzzer <= BUZZ; 
		
		WHEN OTHERS =>

	-- esses "scan codes" que o teclado envia correspondem a uma tecla, isso é tabelado
	-- você pode encontrar esses códigos em algum documento da IBM, ou você pode usar um osciloscópio e verificar manualmente
			
	END CASE;
	
	END IF;
	
	END PROCESS;

-----------------------------------------------------------------------------------------------------------------------------------------
-- processos relacionados a INPUT ------------------------------------------------------------------------------------------------------
	
	PROCESS(keyboard_clk)
	BEGIN
	
	IF rising_edge(keyboard_clk) THEN 
	
		CASE maquina IS
		
			WHEN first =>	
				
				IF ( data_in = '0' ) THEN -- (esse primeiro bit tem que ser baixo e ele confirma que SIM o teclado esta tentando dizer algo)

					i <= 0; -- i = 0 pois essa variavel sera usada na leitura, antes de iniciar a leitura já nos preparamos zerando ela
					maquina <= data; -- agora as coisas ficam interessantes
					
				END IF;
			WHEN data =>
				
				IF i < 8 THEN
					
					code(i) <= data_in; -- o bit na posição "i" do bus saída recebe o bit atual da entrada
					i <= i + 1;
					
				END IF;

				-- um comando do teclado contem 8 bits, como nossa contagem começou em 0
				-- no momento "i = 7" teremos recebido toda a informação, portanto mudamos para o próximo estado
				-- para leitura do bit de paridade
					
				IF i = 7 THEN
					
						maquina <= parity; 
						
				END IF;
			WHEN parity =>
			
				-- vou ignorar o bit de paridade pois ele é opcional ¯\_(ツ)_/¯
				
				maquina <= final; -- vai direto pro bit final ao proximo clock
			
		
			WHEN final =>

				-- no estado de bit final, a máquina valida e salva o comando recebido
				-- ela permanece nesse estado até que uma nova comunicação seja iniciada
				-- jogando a máquina de volta para o estado de inicio "first" assim que outro tempo de clock for detectado
				-- (isso funciona porque o clock do teclado só funciona quando ele está enviando algo
				-- portanto quando ele termina um comando é garantido que a máquina só vai continuar quando outra comunicação começar)
					
				test <= code;
				maquina <= first; 	
			
			WHEN OTHERS =>
		END CASE;
		
	END IF;
	
	END PROCESS;

END Main;
	

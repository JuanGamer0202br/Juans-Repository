LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY Piano_PS2 IS
	PORT (
		onboard_clk , keyboard_clk , data_in : in std_logic;
		buzzer : out std_logic;
		test : out std_logic_vector (7 downto 0)
	);

	-- onboard_clk é para o clock da Max II
	-- keyboard_clk é para o clk que o teclado conectado fornece
	-- data_in é a linha de comunicação entre o teclado e a Max II
	-- buzzer é a saída de audio
	-- test é usado apenas para fins de simulação IGNORAR POR TODA A EXTENSÃO DO CÓDIGO
	
END Piano_PS2;

ARCHITECTURE Main OF Piano_PS2 IS

SIGNAL CLKCOUNT : integer RANGE 0 TO 50000000 := 0;
SIGNAL BFREQ : integer RANGE 0 TO 50000000 := 5952;
-- para gerar um tom de 440Hz no buzzer, preciso que o código use o clock da placa
-- portanto faço ( ( 50000000 / 440 ) / 2 ) = 56818 (dividido por 2 por que um sinal é formado metade por uma subida e metade uma decida)

SIGNAL SEGUNDO : integer RANGE 0 TO 50000000 := 0;
SIGNAL BUZZ : std_logic := '0';

-- CLKCOUNT é usado na geração de audio, para gerar uma frequência eu preciso fazer conversões com o clock da Max II
-- BFREQ é usado como parametro para gerar a frequência
-- SEGUNDO é usado para contar o tempo de um segundo (1 clock de 50 Mhz na Max II)
-- BUZZ a linha interna que sera usada para fazer interface entre o pino físico e o sinal gerado

TYPE estados IS (standby , first , data , parity , final); -- usamos uma maquina de estados, o vdhl não é uma linguagem sequencial, por isso precisamos garantir que partes do código só sejam executadas em um estado especifico
-- standby = em espera de comunicação
-- first = primeiro bit, se preparando para receber um comando
-- data = le e decodifica o comando recebido
-- parity = não faz nada, mas precisa ser seu estado próprio porque o teclado ainda manda...
-- final = fim da comunicação, verifica se o comando é valido

SIGNAL maquina : estados := standby; -- por padrão iniciamos a maquina no estado de espera, isso é, esperando até que uma transferencia seja iniciada
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
	
		IF code = "00011100" THEN -- se o ultimo comando recebido for "00011100" ou "1C" em hexadecimal, então a tecla "a" foi apertada

			BFREQ <= "5952"; -- muda a frequência para a desejada para a tecla "a"
			buzzer <= BUZZ; -- libera o tom gerado para o buzzer
		
		END IF;
	END IF;
	
	END PROCESS;

-----------------------------------------------------------------------------------------------------------------------------------------
-- processos relacionados a INPUT ------------------------------------------------------------------------------------------------------
	
	PROCESS(keyboard_clk)
	BEGIN
	
	IF rising_edge(keyboard_clk) THEN 
	
		CASE maquina IS
		
			WHEN standby =>
				
				test <= "00000000";	
				maquina <= first; -- se preparando para receber o primeiro bit!!!!

			WHEN first =>
			
				code <= "00000000"; -- certifica que o bus de saída ta limpo mesmo
						
				IF ( data_in = '0' ) THEN -- (esse primeiro bit tem que ser baixo e ele confirma que SIM o teclado esta tentando dizer algo)

					maquina <= data; -- agora as coisas ficam interessantes
					
				END IF;
			WHEN data =>
				
				i <= 0; -- i = 0 que dizer que ainda não lemos nenhum bit
				
				IF i < 8 THEN
					
					code(i) <= data_in; -- o bit "i" do bus saída recebe o bit atual da entrada
					i <= i + 1;
								
				ELSE -- se já se passaram 8 bits, quer dizer que a mensagem foi recebida
					
					maquina <= parity; 
						
				END IF;
			WHEN parity =>
			
				--vou ignorar o bit de paridade pois ele é opcional ¯\_(ツ)_/¯
				
				maquina <= final; -- vai direto pro bit final ao proximo clock
			
		
			WHEN final =>
			
				IF data_in = '1' THEN -- bit final obrigatorio de valor ALTO FOI recebido, aceitar os dados e voltar a espera
					
					test <= code;
					maquina <= standby; 	
			
				ELSE -- bit final obrigatorio de valor ALTO NÃO foi recebido, rejeitar os dados e voltar a espera
					
					code <= "00000000";
					maquina <= standby;
				
				END IF;
			
			WHEN OTHERS =>
		END CASE;
		
	END IF;
	
	END PROCESS;

END Main;
	

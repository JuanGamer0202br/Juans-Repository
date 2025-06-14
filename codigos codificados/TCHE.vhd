library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TCHE is
	port (
		clk, inicio, entrada: in std_logic;
		tx: out std_logic;
    		saida : out std_logic_vector(7 downto 0)
	);
end entity;

--tx -> indica se está tendo uma transmisão
--saida -> transmissão da informação em um BUS de 8 bits


architecture uart_buz of TCHE is
-- clk = 50Mhz
-- baudrate da comunicação -> 9600
-- valor a ser contado =
-- (50000000)/(9600) = ~5208 (valor calculado que um processador de 50Mhz deve usar para se comunicar em 9.6Khz)
-- Para simulação usar 50

	COMPONENT BAH -- estou chamando BAH (o meu outro código vhdl que gera sinais seriais uart) ai eu recebo a saída de BAH aqui
		port(LetsTalk, Serial : out std_logic; relogiows: in std_logic);
	END COMPONENT;
	
	signal contagem : integer range 0 to 5208 := 0;

	signal i : integer range 0 to 8 := 0; -- o processador vai usar esse sinal para lembrar qual dos 8 bits ele está lendo

	TYPE estados IS (em_espera,primeiro_bit,dados,bit_final); -- usamos uma maquina de estados, o vdhl não é uma linguagem sequencial, por isso precisamos garantir que partes do código só sejam executadas em um estado especifico

	signal maquina : estados := em_espera; -- por padrão iniciamos a maquina no estado de espera, isso é, esperando até que uma transferencia seja iniciada
	signal inicio_old : std_logic := '0'; -- inicio old armazena o estado anterior ao atual da variavel "inicio" na entidade, usamos isso para detectar se houve uma mudança em "inicio" sem usar "process()" já que não pode ter um "process" dentro de outro...  poxa vhdl
begin
	process(clk)
	begin
		IF rising_edge(clk) THEN
				case maquina is
					when em_espera =>
						tx <= '0';
						if inicio = '1' and inicio_old = '0' then -- o processador recebeu um pedido de comunicação 
							i <= 0; -- i = 0 que dizer que ainda não lemos nenhum bit
							maquina <= primeiro_bit; -- se preparando para receber o primeiro bit!!!! (esse primeiro bit tem que ser baixo e ele confirma que SIM queremos nos comunicar)
						end if;
						inicio_old <= inicio; -- atualiza inicio pra essa primeira condição não rodar mais não cara ta bom já a gente já tendeu que começou a comunicação
					when primeiro_bit =>
						saida <= "00000000"; -- certifica que o bus de saída ta limpo mesmo
						tx <= '1'; -- tx fica ativo para confirmar que estamos nos comunicando
						maquina <= dados; -- agora as coisas ficam interessantes
					when dados =>
						IF CONTAGEM < 5208 then --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0; 
							if i < 8 then
								saida(i) <= entrada; -- o bit "i" do bus saída recebe o bit atual da entrada
								i <= i + 1;	
							else -- se já se passaram 8 bits, quer dizer que a mensagem foi recebida
								maquina <= bit_final; 
							end if;
						end if; 
					when bit_final =>
						IF CONTAGEM < 5208 THEN --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE
							contagem <= 0;
							maquina <= em_espera; -- o bit final de stop foi recebido e portanto a comunicação acabou, voltar ao estado de espera caso algo novo chegue
						end if;
				end case;
		end if;
	end process;
end uart_buz;

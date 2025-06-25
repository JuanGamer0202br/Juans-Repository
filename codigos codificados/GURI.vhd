library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GURI is
	port (
		clock , inicio , reciever : in std_logic;
		Talk , result : out std_logic
	);
end entity;

-- Talk fica em ALTO enquanto recebemos uma mensagem
-- reciever sera a porta de comunicação
-- clock é só o clock mesmo
-- result é a saída

architecture uart_generator2 of GURI is
-- clk = 50Mhz
-- baudrate da comunicação -> 9600
-- valor a ser contado =
-- (50000000)/(4800) = ~10417 (valor calculado que um processador de 50Mhz deve usar para se comunicar em 4.8Khz)
-- Para simulação usar 100

	signal temporizador : integer range 0 to 50000000 := 0; 
	signal contagem : integer range 0 to 10417 := 0;
	signal inicio_old : std_logic;
	signal i : integer range 0 to 8 := 0; -- o processador vai usar esse sinal para lembrar qual dos 8 bits ele está lendo
	signal mensagem : std_logic_vector (7 downto 0); -- armazena a sequencia recebida

	TYPE estados IS ( afk , start96 , start48 , lendo , enviando , stop96 , stop48 ); -- usamos uma maquina de estados, o vdhl não é uma linguagem sequencial, por isso precisamos garantir que partes do código só sejam executadas em um estado especifico
	
	signal maquina : estados := afk; -- por padrão iniciamos a maquina em away from keyboard

begin
	process(clock)
	begin
		IF rising_edge(clock) THEN
				case maquina is
					when afk =>
						
						result <= '1'; -- em quanto nada é executado, a linha de saída é mantida ALTA
						Talk <= '0';
						
						if inicio = '1' and inicio_old = '0' then -- o processador recebeu um pedido de comunicação 
							i <= 0; -- i = 0 que dizer que ainda não lemos nenhum bit
							maquina <= start96; -- se preparando para receber o primeiro bit!!!! (esse primeiro bit tem que ser baixo e ele confirma que SIM queremos nos comunicar)
							contagem <= 0; 
						end if;
						inicio_old <= inicio; -- atualiza inicio pra essa primeira condição não rodar mais não cara ta bom já a gente já tendeu que começou a comunicação
					when start96 =>
								-- esse é o start de receber dados, baud aqui é 9600!!!!!!!
						i <= 0;
						Talk <= '1'; 
						
						contagem <= 0;

						IF CONTAGEM < 25 then --usar metade do baud original
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0; 
							maquina <= lendo; -- agora as coisas ficam interessantes
						end if;
					when start48 =>
								-- esse é o start de enviar dados, baud aqui é 4800!!!!!!!
						i <= 0;
						
						contagem <= 0;
						result <= '0';
						
						maquina <= enviando; -- agora as coisas ficam interessantes
						
					when lendo =>
						IF CONTAGEM < 50 then --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0; 
							if i < 8 then
								mensagem(i) <= reciever; -- o bit "i" do bus mensagem recebe o bit atual da entrada
								i <= i + 1;
								
							else -- se já se passaram 8 bits, quer dizer que a mensagem foi recebida
								maquina <= stop96; 
							end if;
						end if; 
					when enviando =>
							-- aqui o baud é 4800!!!!!!
						IF CONTAGEM < 100 then --para simulação usar 100
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0;
								
							if i < 8 then
								result <= mensagem(i); -- o bit "i" da sequencia atual
								i <= i + 1;	
							else -- se já se passaram 8 bits, quer dizer que a mensagem foi enviada
								maquina <= stop48; 
							end if;
						end if;
					when stop96 =>

						IF CONTAGEM < 25 then -- metade do baud 9600
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0;
								
							maquina <= start48;
						end if;
					when stop48 =>
								
						IF CONTAGEM < 100 then -- metade do baud 9600
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0;
							maquina <= afk;
						end if;
				end case;
		end if;
	end process;
end uart_generator2;

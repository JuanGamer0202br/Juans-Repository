library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BAH is
	port (
		relogiows : in std_logic;
		LetsTalk, Serial : out std_logic
	);
end entity;

-- LetsTalk emite um sinal para avisar TCHE que BAH quer se comunicar!!!!
-- Serial sera a porta de comunicação
-- relogiows é só o clock mesmo

architecture uart_generator of BAH is
-- clk = 50Mhz
-- baudrate da comunicação -> 9600
-- valor a ser contado =
-- (50000000)/(9600) = ~5208 (valor calculado que um processador de 50Mhz deve usar para se comunicar em 9.6Khz)
-- Para simulação usar 50

	signal temporizador : integer range 0 to 50000000 := 0; -- vou querer trocar entre os modos da maquina de 1 em 1 segundo
	signal contagem : integer range 0 to 5208 := 0;
	signal qual_das_duas : integer range 0 to 1 := 0;

	signal i : integer range 0 to 8 := 0; -- o processador vai usar esse sinal para lembrar qual dos 8 bits ele está enviando
	signal seq_1 : integer range 0 to 99999999 := 01000001; -- a sequencia 1 a ser enviada é a letra A de hex = 41, ali esta em binario
	signal seq_2 : integer range 0 to 99999999 := 01000010; -- a sequencia 2 a ser enviada é a letra B de hex = 42, ali esta em binario

	TYPE estados IS ( afk , sequencia_1 , sequencia_2 ); -- usamos uma maquina de estados, o vdhl não é uma linguagem sequencial, por isso precisamos garantir que partes do código só sejam executadas em um estado especifico
	
	signal maquina : estados := afk; -- por padrão iniciamos a maquina em away from keyboard

begin
	process(clk)
	begin
		IF rising_edge(clk) THEN
				case maquina is
					when afk =>
						
						Serial <= '0';
						LetsTalk <= '0';
						i <= 0;
					
						IF temporizador < 50000000 then --para simulação usar 5000
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo 1 segundo
							if qual_das_duas = 0 then
								maquina <= sequencia_1;
								LetsTalk <= '1';
								qual_das_duas <= 1;
							else
								maquina <= sequencia_2;
								LetsTalk <= '1';
								qual_das_duas <= 0;
							end if; 
						end if;
					when sequencia_1 =>
						IF CONTAGEM < 5208 then --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0;
								
							if i < 8 then
								Serial <= seq_1(i); -- o bit "i" da sequencia atual
								i <= i + 1;	
							else -- se já se passaram 8 bits, quer dizer que a mensagem foi recebida
								maquina <= afk; 
							end if;
						end if; 
					when sequencia_2 =>
						IF CONTAGEM < 5208 then --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE -- já se passou o tempo de 1 bit
							contagem <= 0;
								
							if i < 8 then
								Serial <= seq_2(i); -- o bit "i" da sequencia atual
								i <= i + 1;	
							else -- se já se passaram 8 bits, quer dizer que a mensagem foi recebida
								maquina <= afk; 
							end if;
						end if;
				end case;
		end if;
	end process;
end uart_generator;


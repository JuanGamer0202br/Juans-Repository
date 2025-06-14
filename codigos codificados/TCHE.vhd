library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TCHE is
	port (
		clk, inicio: in std_logic;
		entrada, tx: out std_logic;
    saida : in std_logic_vector(7 downto 0)
		);
end entity;

--tx -> indica se está tendo uma transmisão
--saida -> transmissão da informação em um BUS de 8 bits


architecture conversor of TCHE is
-- clk = 50Mhz
-- baudrate da comunicação -> 9600
-- valor a ser contado =
-- (50000000)/(9600) = ~5208 (valor calculado que um processador de 50Mhz deve usar para se comunicar em 9.6Khz)
-- Para simulação usar 50

	signal contagem : integer range 0 to 5208 := 0;
	
	signal i : integer range 0 to 8 := 0; -- o processador vai usar esse sinal para lembrar qual dos 8 bits ele está lendo
	
	TYPE estados IS (em_espera,primeiro_bit,dados,bit_final); -- usamos uma maquina de estados, o vdhl não é uma linguagem sequencial, por isso precisamos garantir que partes do código só sejam executadas em um estado especifico
	signal maquina : estados := em_espera; -- por padrão iniciamos a maquina no estado de espera, isso é, esperando até que uma transferencia seja iniciada
	signal inicio_old : std_logic := '0'; -- inicio old armazena o estado anterior ao atual da variavel "inicio" na entidade, usamos isso para fins de contagem, não se preocupe em saber doq se trata
	
begin
	process(clk)
	begin
		IF rising_edge(clk) THEN
				case maquina is
					when em_espera =>
						saida <= '00000000';
						tx <= '0';
						if inicio = '1' and inicio_old = '0' then
							i <= 0;
							maquina <= primeiro_bit;
						end if;
						inicio_old <= inicio;
					when primeiro_bit =>
						saida <= '0';
						tx <= '1';
						maquina <= dados;
					when dados =>
						IF CONTAGEM < 5208 then --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE
							contagem <= 0;
							if i < 8 then
								saida <= entrada(i);
								i <= i + 1;	
							else
								maquina <= bit_final;
							end if;
						end if; 
					when bit_final =>
						saida <= '1';
						IF CONTAGEM < 5208 THEN --para simulação usar 50
							CONTAGEM <= CONTAGEM + 1;
						ELSE
							contagem <= 0;
							maquina <= em_espera;
						end if;
				end case;
		end if;
	end process;
end conversor;

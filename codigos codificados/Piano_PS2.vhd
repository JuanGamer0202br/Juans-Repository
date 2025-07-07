LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY Piano_PS2 IS
	PORT (
		onboard_clk , keyboard_clk : in std_logic;
		buzzer : out std_logic
	);
	
END Piano_PS2;

ARCHITECTURE Main OF Piano_PS2 IS

SIGNAL CLKCOUNT : integer RANGE 0 TO 50000000 := 0;
SIGNAL BFREQ : integer RANGE 0 TO 50000000 := 5952;
SIGNAL SEGUNDO : integer RANGE 0 TO 50000000 := 0;
SIGNAL BUZZ : std_logic := '0';

-- para gerar um tom de 440Hz no buzzer, preciso que o código use o clock da placa
-- portanto faço ( ( 50000000 / 440 ) / 2 ) = 56818 (dividido por 2 por que um sinal é formado metade por uma subida e metade uma decida)

BEGIN
	
	PROCESS(onboard_clk)
	BEGIN
	
	-- gerador de tom
	
	IF RISING_EDGE(onboard_clk) THEN
	
		IF CLKCOUNT < BFREQ THEN
		
			CLKCOUNT <= CLKCOUNT + 1;
			
		ELSE
		
			BUZZ <= NOT BUZZ;
			CLKCOUNT <= 0;
		
		END IF;
	END IF;
	
	END PROCESS;
	
	PROCESS(onboard_clk)
	BEGIN
	
	-- controla a saida do buzzer para liberar o som
	
	IF RISING_EDGE(onboard_clk) THEN
	
		IF SEGUNDO < 50000000 THEN
	
			SEGUNDO <= SEGUNDO + 1;
			buzzer <= BUZZ;
		
		ELSE
		
			SEGUNDO <= 0;
		
		END IF;
	END IF;
	
	END PROCESS;
	
END Main;
	

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY Piano_PS2 IS
	PORT (
		clk : in std_logic;
		buzzer : out std_logic
	);
	
END Piano_PS2;

ARCHITECTURE Main OF Piano_PS2 IS

SIGNAL CLKCOUNT : integer RANGE 0 TO 50000000 := 0;
SIGNAL SEGUNDO : integer RANGE 0 TO 100000000 := 0;
SIGNAL BEEP : integer RANGE 0 TO 25000000 := 0;
SIGNAL BUZZ : std_logic := '0';

-- para gerar um tom de 440Hz no buzzer, preciso que o código use o clock da placa
-- portanto faço (50000000 / 440) / 2 = 56818 (dividido por 2 por que o sinal precisa subir e decer)

BEGIN
	
	PROCESS(clk)
	BEGIN
	
	-- gerador de tom
	
	IF RISING_EDGE(clk) THEN
	
		IF CLKCOUNT < 5952 THEN
		
			CLKCOUNT <= CLKCOUNT + 1;
			
		ELSE
		
			BUZZ <= NOT BUZZ;
			CLKCOUNT <= 0;
		
		END IF;
	END IF;
	
	END PROCESS;
	
	PROCESS(clk)
	BEGIN
	
	-- controla a saida do buzzer para criar pquenos beeps
	
	IF RISING_EDGE(clk) THEN
	
		IF SEGUNDO < 50000000 THEN
	
			SEGUNDO <= SEGUNDO + 1;
	
		ELSIF BEEP < 12500000 THEN
		
			buzzer <= BUZZ;
			BEEP <= BEEP + 1;
		
		ELSE
		
			BEEP <= 0;
			SEGUNDO <= 0;
		
		END IF;
	END IF;
	
	END PROCESS;
	
END Main;
	
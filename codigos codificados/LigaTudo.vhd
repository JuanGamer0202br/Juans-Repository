LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.STD_LOGIC_ARITH.all;

ENTITY LigaTudo IS
PORT (
		CKL : in std_logic;
		sinal2 : out std_logic;
		tx: out std_logic;
    	saida : out std_logic_vector(7 downto 0)
		);
END LigaTudo;

ARCHITECTURE sysmain of LigaTudo is
			
	SIGNAL comum : std_logic;
	SIGNAL sinal : std_logic;
			
	COMPONENT BAH
		port(relogiows : in std_logic; LetsTalk, Serial : out std_logic);
	END COMPONENT;
	
	COMPONENT TCHE
		port(clk, inicio, entrada: in std_logic; tx: out std_logic; saida : out std_logic_vector(7 downto 0));
	END COMPONENT;
	
	BEGIN
		Gerador : BAH PORT MAP (CKL, comum, sinal);
		Leitor : TCHE PORT MAP (CKL, comum, sinal, tx, saida);
		
		sinal2 <= sinal;
		
END sysmain;
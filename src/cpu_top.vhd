----------------------------------------------------------------------------------
-- CPU Top -- synthesis wrapper with PicoBlaze-style bus interface
--
-- Author: Mahdi Bazzoun
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.io_types_pkg.all;

entity cpu_top is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        port_id      : out std_logic_vector(7 downto 0);
        in_port      : in  std_logic_vector(7 downto 0);
        out_port     : out std_logic_vector(7 downto 0);
        write_strobe : out std_logic;
        read_strobe  : out std_logic
    );
end entity;

architecture rtl of cpu_top is
    signal in_ports_s  : port_array := (others => (others => '0'));
    signal out_ports_s : port_array := (others => (others => '0'));

    -- Component (not direct entity) instantiation so testbench configurations
    -- can bind the ROM architecture inside the CPU (see cpu_wrapper_cfg)
    component cpu is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            in_ports     : in  port_array;
            out_ports    : out port_array;
            port_id      : out std_logic_vector(7 downto 0);
            out_port     : out std_logic_vector(7 downto 0);
            write_strobe : out std_logic;
            read_strobe  : out std_logic
        );
    end component;
begin

    -- Broadcast in_port to all indices; the IO unit selects the right one
    in_ports_s <= (others => in_port);

    inner: cpu port map (
        clk          => clk,
        reset        => reset,
        in_ports     => in_ports_s,
        out_ports    => out_ports_s,
        port_id      => port_id,
        out_port     => out_port,
        write_strobe => write_strobe,
        read_strobe  => read_strobe
    );

end architecture;

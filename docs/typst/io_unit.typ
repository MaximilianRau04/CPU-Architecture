The IO unit connects the processor to external ports. It translates INPUT and OUTPUT instructions into read and write operations within a fixed 256-port address space, keeping the core independent of device details. Inputs are combinational signals, while outputs are stored in clocked registers.

It uses the io_types_pkg.port_array type (256×8‑bit vectors) for in_ports and out_ports, allowing direct connection of external devices without modifying the unit.

=== Interface

#table(
  columns: (auto, auto, auto, 1fr),
  table.header("Port", "Direction", "Width", "Description"),
  `clk`, "in", "1", "System clock",
  `rst`, "in", "1", "Synchronous reset",
  `io_rd`, "in", "1", "Read enable (active high)",
  `io_wr`, "in", "1", "Write enable (active high)",
  `port_pp`, "in", "8", "Port address (0–255)",
  `cpu_data_in`, "in", "8", "Data from datapath for OUTPUT",
  `io_data_out`, "out", "8", "Data to datapath for INPUT",
  `in_ports`, "in", "256×8", "External input port values",
  `out_ports`, "out", "256×8", "Registered output port values",
)

=== Internal Architecture

The IO Unit consists of two independent paths:

- **Output path**: a register array (`out_ports_reg`) storing the current values of all output ports.
- **Input path**: a combinational multiplexer selecting one input port based on `port_pp`.

=== Output Operation

```vhdl
process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            out_ports_reg <= (others => (others => '0'));
        elsif io_wr = '1' then
            out_ports_reg(to_integer(unsigned(port_pp))) <= cpu_data_in;
        end if;
    end if;
end process;

out_ports <= out_ports_reg;
```
On every rising clock edge:
- ** If rst is asserted, all output registers are cleared.
- **If io_wr is active, the value on cpu_data_in is written into the addressed port register, while other ports retain their previous values.
The external out_ports bus is continuously driven by out_ports_reg, so each output port reflects the last written value immediately after the clock edge.

==== Input Operation
```vhdl
io_data_out <= in_ports(to_integer(unsigned(port_pp))) when io_rd = '1' 
  else (others => '0');
```

The input path is purely combinational:
- **When io_rd is asserted, the value of the selected input port appears on io_data_out without any clock delay.
- **When io_rd is deasserted, io_data_out is driven to zero to prevent stale data from propagating into the datapath.

=== Reset Behavior

A synchronous reset (rst) clears all output registers to x"00". The input path is unaffected by reset, as it only responds to io_rd. This guarantees a defined initial state for all external connections.

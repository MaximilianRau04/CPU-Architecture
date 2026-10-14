#!/usr/bin/env dotnet run

#:package TUnit@0.*

using System.Diagnostics;
using System.Runtime.CompilerServices;

class Tests
{
    public static IEnumerable<byte> Registers => Enumerable.Range(0, 0x10).Select(static i => (byte)i);
    public static IEnumerable<byte> Ports => Enumerable.Range(0, 0x10).Select(static i => (byte)i);
    public static IEnumerable<(byte reg, byte port)> RegisterXPort => from reg in Registers from port in Ports select (reg, port);
    public static byte[] ImmediateValues { get; } = [.. Enumerable.Range(0, byte.MaxValue + 1).Select(static i => (byte)i)];
    public static (byte a, byte b)[][] ImmediateValuePairChunks { get; } = [.. (from a in ImmediateValues from b in ImmediateValues select (a, b)).Chunk(TestHelper.MaxROM / 8)];

    [Test]
    [MethodDataSource(nameof(Registers))]
    public async Task OpLoad(byte reg)
    {
        byte reg2 = (byte)((reg + 1) % 0x10);

        using TestHelper test = new();
        foreach (byte a in ImmediateValues)
        {
            // Test immediate load
            test.Asm($"LOAD r{reg:X}, 0x{a:X2}");
            test.AssertStall();
            test.AssertOutputOf(reg, eq: a);

            // Test copy
            test.Asm($"LOAD r{reg2:X}, 0");
            test.AssertStall();
            test.AssertOutputOf(reg2, eq: 0);

            test.Asm($"LOAD r{reg2:X}, r{reg:X}");
            test.AssertStall();
            test.AssertOutputOf(reg2, eq: a);
        }
        await test.Execute();
    }

    [Test]
    [MethodDataSource(nameof(RegisterXPort))]
    public async Task OpOutput(byte reg, byte port)
    {
        using TestHelper test = new();
        foreach (byte a in ImmediateValues)
        {
            test.Asm($"LOAD r{reg:X}, 0x{a:X2}");
            test.AssertStall();
            test.AssertOutputOf(reg, eq: a, port);
        }
        await test.Execute();
    }

    [Test]
    [MethodDataSource(nameof(RegisterXPort))]
    public async Task OpInput(byte reg, byte port)
    {
        using TestHelper test = new();
        foreach (byte a in ImmediateValues)
        {
            test.SetInput(port, a);
            test.Asm($"INPUT r{reg:X}, {port}");
            test.AssertStall();
            test.AssertOutputOf(reg, eq: a, port: (byte)((port + 1) % 0x10));
        }
        await test.Execute();
    }

    public static IEnumerable<(string instruction, Func<byte, byte> logic)> OneArgArithmeticData()
    {
        yield return ("RL", (a) => (byte)((a << 1) | (a >> 7)));
        yield return ("RR", (a) => (byte)((a >> 1) | (a << 7)));
        yield return ("SL0", (a) => (byte)(a << 1));
        yield return ("SL1", (a) => (byte)((a << 1) | 1));
        yield return ("SLX", (a) => (byte)((a << 1) | (a & 1)));
        yield return ("SR0", (a) => (byte)(a >> 1));
        yield return ("SR1", (a) => (byte)((a >> 1) | 0b1000_0000));
        yield return ("SRX", (a) => unchecked((byte)((sbyte)a >> 1)));
    }

    [Test]
    [MethodDataSource(nameof(OneArgArithmeticData))]
    public async Task OneArgArithmetic(string instruction, Func<byte, byte> logic)
    {
        using TestHelper test = new();
        foreach (byte a in ImmediateValues)
        {
            test.Asm($"LOAD r1, {a}");
            test.AssertStall();
            test.AssertOutputOf(reg: 1, eq: a);

            // Test logic
            test.Asm($"{instruction} r1");
            test.AssertStall();
            test.AssertOutputOf(reg: 1, eq: logic(a));

            // Test pipelining
            test.Asm($"{instruction} r1");
            test.AssertStall();
            test.AssertOutputOf(reg: 1, eq: logic(logic(a)));
        }
        await test.Execute();
    }

    [Test]
    public async Task OpSra()
    {
        using TestHelper test = new();
        byte carry = 0;
        foreach (byte a in ImmediateValues)
        {
            test.Asm($"LOAD r1, {a}");
            test.AssertStall();
            test.AssertOutputOf(reg: 1, eq: a);

            byte first = (byte)((carry << 7) | (a >> 1));
            carry = (byte)(a & 1);
            byte second = (byte)((carry << 7) | (first >> 1));
            carry = (byte)(first & 1);
            test.Asm("SRA r1");
            test.AssertStall();
            test.AssertOutputOf(reg: 1, eq: first);
            test.Asm("SRA r1");
            test.AssertStall();
            test.AssertOutputOf(reg: 1, eq: second);
        }
        await test.Execute();
    }

    public static IEnumerable<(string instruction1, string instruction2, bool leftToRight, Func<ushort, ushort> logic)> OneArgArithmeticInt16Data()
    {
        // ToDo: What about other combinations?
        yield return ("SL0", "SLA", leftToRight: false, (a) => (ushort)(a << 1));
        yield return ("SR0", "SRA", leftToRight: true, (a) => (ushort)(a >> 1));
        yield return ("SRX", "SRA", leftToRight: true, (a) => unchecked((ushort)((short)a >> 1)));
    }

    [Test]
    [MethodDataSource(nameof(OneArgArithmeticInt16Data))]
    public async Task OneArgArithmeticInt16(string instruction1, string instruction2, bool leftToRight, Func<ushort, ushort> logic)
    {
        foreach (var chunk in ImmediateValuePairChunks)
        {
            using TestHelper test = new();
            foreach (var (a1, a2) in chunk)
            {
                test.Asm($"LOAD r1, {a1}");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: a1);

                test.Asm($"LOAD r2, {a2}");
                test.AssertStall();
                test.AssertOutputOf(reg: 2, eq: a2);

                if (leftToRight)
                {
                    test.Asm($"{instruction1} r1");
                    test.Asm($"{instruction2} r2");
                }
                else
                {
                    test.Asm($"{instruction1} r2");
                    test.Asm($"{instruction2} r1");
                    test.AssertStall();
                }

                ushort arg = (ushort)((ushort)(a1 << 8) | a2);
                test.AssertOutputOf(reg: 1, eq: (byte)(logic(arg) >> 8), message: $"a1={a1}, a2={a2}");
                test.AssertOutputOf(reg: 2, eq: (byte)(logic(arg) & byte.MaxValue), message: $"a1={a1}, a2={a2}");
            }
            await test.Execute();
        }
    }

    public static IEnumerable<(string instruction, Func<byte, byte, byte> logic)> TwoArgArithmeticData()
    {
        yield return ("ADD", (a, b) => (byte)(a + b));
        yield return ("SUB", (a, b) => (byte)(a - b));
        yield return ("AND", (a, b) => (byte)(a & b));
        yield return ("OR", (a, b) => (byte)(a | b));
        yield return ("XOR", (a, b) => (byte)(a ^ b));
    }

    [Test]
    [MethodDataSource(nameof(TwoArgArithmeticData))]
    public async Task TwoArgArithmetic(string instruction, Func<byte, byte, byte> logic)
    {
        foreach (var chunk in ImmediateValuePairChunks)
        {
            using TestHelper test = new();
            foreach (var (a, b) in chunk)
            {
                // Test with registers
                test.Asm($"LOAD r1, 0x{a:X2}");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: a);

                test.Asm($"LOAD r2, 0x{b:X2}");
                test.AssertStall();
                test.AssertOutputOf(reg: 2, eq: b);

                // Test logic
                test.Asm($"{instruction} r1, r2");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: logic(a, b));

                // Test pipelining
                test.Asm($"{instruction} r1, r2");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: logic(logic(a, b), b));
            }
            await test.Execute();
        }
    }

    [Test]
    [MethodDataSource(nameof(TwoArgArithmeticData))]
    public async Task TwoArgArithmeticImmediate(string instruction, Func<byte, byte, byte> logic)
    {
        foreach (var chunk in ImmediateValuePairChunks)
        {
            using TestHelper test = new();
            foreach (var (a, b) in chunk)
            {
                // Test with immediate values
                test.Asm($"LOAD r1, 0x{a:X2}");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: a);

                // Test logic
                test.Asm($"{instruction} r1, 0x{b:X2}");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: logic(a, b));

                // Test pipelining
                test.Asm($"{instruction} r1, 0x{b:X2}");
                test.AssertStall();
                test.AssertOutputOf(reg: 1, eq: logic(logic(a, b), b));
            }
            await test.Execute();
        }
    }

    public static IEnumerable<(string instruction, Func<byte, byte, byte, byte> logic)> TwoArgArithmeticWithCarryData()
    {
        yield return ("ADDCY", (a, b, c) => (byte)(a + b + c));
        yield return ("SUBCY", (a, b, c) => (byte)(a - b - c));
    }

    [Test]
    [MethodDataSource(nameof(TwoArgArithmeticWithCarryData))]
    public async Task TwoArgArithmeticWithCarry(string instruction, Func<byte, byte, byte, byte> logic)
    {
        foreach (var carry in (byte[])[0, 1])
        {
            foreach (var chunk in ImmediateValuePairChunks)
            {
                using TestHelper test = new();
                test.Asm($"LOAD r2, 1");
                test.AssertStall();
                foreach (var (a, b) in chunk)
                {
                    // Setup carry flag
                    test.Asm($"TEST r2, {carry}");

                    // Test logic
                    test.Asm($"LOAD r1, {a}");
                    test.AssertStall();
                    test.Asm($"{instruction} r1, {b}");
                    test.AssertStall();
                    test.AssertOutputOf(reg: 1, eq: logic(a, b, carry), message: $"a={a}, b={b}, c={carry}");
                }
                await test.Execute();
            }
        }
    }

    [Test]
    public async Task OpTestImmediate()
    {
        foreach (var chunk in ImmediateValuePairChunks)
        {
            using TestHelper test = new();
            foreach (var (a, b) in chunk)
            {
                var result = (byte)(a & b);
                var zero = result == 0 ? 1u : 0;
                var carry = (byte.PopCount(result) % 2) == 1 ? 1u : 0;

                // Test with immediate values
                test.Asm($"LOAD r1, 0x{a:X2}");
                test.Asm($"LOAD r2, 0");
                test.Asm($"TEST r1, 0x{b:X2}");
                test.Asm($"SLA r2"); // Write carry to r2
                test.AssertStall();
                test.AssertOutputOf(reg: 2, eq: carry, message: $"a={a}, b={b}");
                // ToDo: Test zero flag as well
            }
            await test.Execute();
        }
    }

    static readonly byte[] FlagTestValues = [0x00, 0x01, 0x02, 0x03, 0x0F, 0x10, 0x33, 0x55, 0x7E, 0x7F, 0x80, 0x81, 0xAA, 0xCC, 0xFE, 0xFF];

    static IEnumerable<(string instruction, Func<byte, byte, bool, bool, (bool carry, bool zero)> flags)> FlagInstructions()
    {
        yield return ("COMPARE", (a, b, c, z) => (a < b, a == b));
        yield return ("COMPARECY", (a, b, c, z) =>
        {
            int result = a - b - (c ? 1 : 0);
            return (result < 0, (byte)result == 0 && z);
        });
        yield return ("TEST", (a, b, c, z) =>
        {
            var result = (byte)(a & b);
            return (byte.PopCount(result) % 2 == 1, result == 0);
        });
        yield return ("TESTCY", (a, b, c, z) =>
        {
            var result = (byte)(a & b);
            return ((byte.PopCount(result) % 2 == 1) ^ c, result == 0 && z);
        });
    }

    public static IEnumerable<(string instruction, bool immediate, bool jumpIfSet, Func<byte, byte, bool, bool, (bool carry, bool zero)> flags)> FlagInstructionData()
    {
        foreach (var (instruction, flags) in FlagInstructions())
            foreach (var immediate in (bool[])[false, true])
                foreach (var jumpIfSet in (bool[])[false, true])
                    yield return (instruction, immediate, jumpIfSet, flags);
    }

    // Flag-only instructions are observed through conditional jumps:
    // carry ends up in r2 and zero in r4. jumpIfSet selects JUMP C/Z vs. JUMP NC/NZ.
    [Test]
    [MethodDataSource(nameof(FlagInstructionData))]
    public async Task FlagInstruction(string instruction, bool immediate, bool jumpIfSet, Func<byte, byte, bool, bool, (bool carry, bool zero)> flags)
    {
        var cases = from a in FlagTestValues
                    from b in FlagTestValues
                    from carryIn in (bool[])[false, true]
                    from zeroIn in (bool[])[false, true]
                    select (a, b, carryIn, zeroIn);

        foreach (var chunk in cases.Chunk(TestHelper.MaxROM / 16))
        {
            using TestHelper test = new();
            int label = 0;
            foreach (var (a, b, carryIn, zeroIn) in chunk)
            {
                var (carry, zero) = flags(a, b, carryIn, zeroIn);
                var message = $"a={a}, b={b}, c_in={carryIn}, z_in={zeroIn}";

                // SR0 on this value sets C = bit 0 and Z = (value >> 1 == 0)
                test.Asm($"LOAD r6, {(carryIn ? 1 : 0) | (zeroIn ? 0 : 2)}");
                test.Asm($"LOAD r1, 0x{a:X2}");
                if (!immediate)
                    test.Asm($"LOAD r3, 0x{b:X2}");
                test.Asm("LOAD r2, 0");
                test.Asm("LOAD r4, 0");
                test.Asm("SR0 r6");

                test.Asm(immediate ? $"{instruction} r1, 0x{b:X2}" : $"{instruction} r1, r3");

                // Fall-through path loads 1, so r2/r4 hold "jump not taken"
                bool carryJumpTaken = jumpIfSet ? carry : !carry;
                test.Asm($"JUMP {(jumpIfSet ? "C" : "NC")} carry{label}");
                if (carryJumpTaken)
                    test.Skip("LOAD r2, 1");
                else
                    test.Asm("LOAD r2, 1");
                test.Label($"carry{label}");

                bool zeroJumpTaken = jumpIfSet ? zero : !zero;
                test.Asm($"JUMP {(jumpIfSet ? "Z" : "NZ")} zero{label}");
                if (zeroJumpTaken)
                    test.Skip("LOAD r4, 1");
                else
                    test.Asm("LOAD r4, 1");
                test.Label($"zero{label}");

                test.AssertOutputOf(reg: 2, eq: carryJumpTaken ? 0u : 1u, port: 1, message: $"carry, {message}");
                test.AssertOutputOf(reg: 4, eq: zeroJumpTaken ? 0u : 1u, port: 2, message: $"zero, {message}");
                label++;
            }
            await test.Execute();
        }
    }

    [Test]
    public async Task OpJump()
    {
        using TestHelper test = new();
        int label = 0;
        foreach (byte a in ImmediateValues)
        {
            // Forward jump, backward jump, forward jump again.
            // Every skipped LOAD would overwrite r1 with the wrong value.
            test.Asm($"JUMP forward{label}");
            test.Skip($"LOAD r1, 0x{(byte)~a:X2}");
            test.Label($"back{label}");
            test.Asm($"LOAD r1, 0x{a:X2}");
            test.Asm($"JUMP done{label}");
            test.Skip($"LOAD r1, 0x{(byte)~a:X2}");
            test.Label($"forward{label}");
            test.Asm($"JUMP back{label}");
            test.Skip($"LOAD r1, 0x{(byte)~a:X2}");
            test.Label($"done{label}");
            test.AssertOutputOf(reg: 1, eq: a);
            label++;
        }
        await test.Execute();
    }

    [Test]
    [Arguments(true)]
    [Arguments(false)]
    public async Task OpStoreFetch(bool immediate)
    {
        static byte ValueFor(byte address) => (byte)(address ^ 0xA5);

        using TestHelper test = new();

        // Write every address first, then read all of them back,
        // so a write landing on the wrong address is caught.
        foreach (byte address in ImmediateValues)
        {
            if (!immediate)
                test.Asm($"LOAD r3, 0x{address:X2}");
            test.Asm($"LOAD r1, 0x{ValueFor(address):X2}");
            test.AssertStall();
            test.Asm(immediate ? $"STORE r1, 0x{address:X2}" : "STORE r1, r3");
        }

        foreach (byte address in ImmediateValues)
        {
            if (!immediate)
            {
                test.Asm($"LOAD r3, 0x{address:X2}");
                test.AssertStall();
            }
            test.Asm(immediate ? $"FETCH r2, 0x{address:X2}" : "FETCH r2, r3");
            test.AssertStall();
            test.AssertOutputOf(reg: 2, eq: ValueFor(address), message: $"address={address}");
        }
        await test.Execute();
    }
}

class TestHelper : IDisposable
{
    public static readonly int MaxROM = (int)Math.Pow(2, 12);

    readonly TestContext _ctx = TestContext.Current ?? throw new InvalidOperationException("No TestContext available");
    UInt128 Id => Unsafe.BitCast<Guid, UInt128>(_ctx.Id);

    readonly StreamWriter asmWriter, assertWriter;
    readonly DirectoryInfo _workDir;
    public TestHelper()
    {
        _workDir = Directory.CreateDirectory($"artifacts-{Id}");
        asmWriter = new($"{_workDir.Name}/instructions.asm", options: new() { Mode = FileMode.Create, Access = FileAccess.ReadWrite, Share = FileShare.ReadWrite });

        assertWriter = new($"{_workDir.Name}/test.vhdl");
        assertWriter.WriteLine(
            $$"""
            library IEEE;
            use IEEE.STD_LOGIC_1164.ALL;
            use IEEE.NUMERIC_STD.ALL;
            use work.io_types_pkg.all;
            use std.env.all;

            entity generated_test is
            end entity;

            architecture sim of generated_test is
                constant CLK_PERIOD : time := 5 ns;

                signal clock_s: std_logic := '0';
                signal reset: std_logic := '0';

                signal in_ports: port_array := (others => (others => '0'));
                signal out_ports: port_array;

                component cpu is
                    Port (
                        clk       : in  std_logic;
                        reset     : in  std_logic;
                        in_ports  : in  port_array;
                        out_ports : out port_array
                    );
                end component;

            begin

                uut: cpu port map (
                    clk => clock_s,
                    reset => reset,
                    in_ports => in_ports,
                    out_ports => out_ports
                );

                clock_s <= not clock_s after CLK_PERIOD / 2;

                -- Fail instead of silently passing if the test never reaches `stop`
                -- (a full 4096-entry ROM needs ~60us)
                watchdog: process
                begin
                    wait for 100 us;
                    report "Testbench timeout: did not reach end of test" severity failure;
                end process;

                process
                begin
                    reset <= '1';
                    wait until rising_edge(clock_s);
                    reset <= '0';
                    wait until rising_edge(clock_s); -- Wait for first instruction to execute

            """
        );
    }

    public void Asm(string line)
    {
        asmWriter.WriteLine(line);
        assertWriter.WriteLine($"wait until rising_edge(clock_s); -- Wait for {line}");
    }

    // Instruction that is in the ROM but jumped over, so it takes no cycle
    public void Skip(string line)
    {
        asmWriter.WriteLine(line);
    }

    public void Label(string name)
    {
        asmWriter.WriteLine($"{name}:");
    }

    public void AssertStall()
    {
        assertWriter.WriteLine("wait until rising_edge(clock_s); -- stall");
    }

    public void AssertOutputOf(byte reg, uint eq, byte port = 1, [CallerLineNumber] int line = 0, string? message = null)
    {
        asmWriter.WriteLine($"OUTPUT r{reg:X}, {port}");
        assertWriter.WriteLine(
            $"""
            wait until rising_edge(clock_s); -- Wait for output
            wait until falling_edge(clock_s); -- Ensure output is stable
            assert (out_ports({port}) = x"{eq:X2}") report "Expected '0x{eq:X2}' in r{reg:X}, got '" & integer'image(to_integer(unsigned(out_ports({port})))) & "' at system-tests.cs line {line} ({message ?? "no extra info"})" severity error;
            """
        );
    }

    public void SetInput(byte port, byte value)
    {
        assertWriter.WriteLine(
            $"""
            in_ports({port}) <= x"{value:X2}";
            """
        );
    }

    public async Task Execute()
    {
        assertWriter.WriteLine(
            """
                
                stop;
                wait;
            
                end process;
            end architecture;

            architecture TestRom of InstructionMemory is
                type rom_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

                constant ROM: rom_type := (
            """
        );

        await asmWriter.FlushAsync();
        _ctx.Output.AttachArtifact(new Artifact
        {
            DisplayName = "Assembly instructions",
            File = new FileInfo(asmWriter.FileName),
        });

        _ctx.OutputWriter.WriteLine("Launching assembler");
        using (var assemblerProcess = StartProcess("PicoAsm", [asmWriter.FileName]))
        {
            await Task.WhenAll(
                assemblerProcess.StandardOutput >> assertWriter,
                assemblerProcess.StandardError >> _ctx.OutputWriter
            );

            await assemblerProcess.AssertSuccess();
        }

        assertWriter.WriteLine(
            """
                    others => (others => '0')
                );
            begin
                Instruction <= ROM(to_integer(unsigned(Address)));
            end architecture;

            configuration test_config of generated_test is
                for sim
                    for uut: cpu
                        use entity work.cpu(rtl);
                        for rtl
                            for rom: InstructionMemory
                                use entity work.InstructionMemory(TestRom);
                            end for;
                        end for;
                    end for;
                end for;
            end configuration;
            """
        );

        await assertWriter.FlushAsync();
        _ctx.Output.AttachArtifact(new Artifact
        {
            DisplayName = "Assertions vhdl",
            File = new FileInfo(assertWriter.FileName),
        });

        _ctx.OutputWriter.WriteLine(_workDir.FullName);

        var appDir = (string?)AppContext.GetData("EntryPointFileDirectoryPath") ?? throw new InvalidOperationException("Failed to get application directory");
        var srcPath = Path.GetFullPath(Path.Combine(appDir, "../", "src"));

        _ctx.OutputWriter.WriteLine("Importing sources");
        await RunAsync("ghdl", ["import", "--std=08", assertWriter.FileName, .. Directory.GetFiles(srcPath, "*.vhd", SearchOption.AllDirectories)]);
        _ctx.OutputWriter.WriteLine("Elaborating Test");
        await RunAsync("ghdl", ["make", "--std=08", "test_config"]);
        _ctx.OutputWriter.WriteLine("Simulating Test");
        await RunAsync("ghdl", ["elab-run", "--std=08", "test_config", "--assert-level=error"]);
    }

    public void Dispose()
    {
        asmWriter.Dispose();
        assertWriter.Dispose();
    }

    async Task RunAsync(string fileName, string[] arguments)
    {
        _ctx.OutputWriter.WriteLine($"> {fileName} {string.Join(' ', arguments)}");

        using var process = StartProcess(fileName, arguments);
        await Task.WhenAll(
            process.StandardOutput >> _ctx.OutputWriter,
            process.StandardError >> _ctx.OutputWriter
        );
        await process.AssertSuccess();
    }

    Process StartProcess(string fileName, string[] arguments)
    {
        var process = Process.Start(startInfo: new(fileName, arguments)
        {
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            WorkingDirectory = _workDir.FullName,
        }) ?? throw new InvalidOperationException($"Failed to start process '{fileName}'");
        _ctx.Execution.CancellationToken.Register(() =>
        {
            try
            {
                if (!process.HasExited)
                    process.Kill(entireProcessTree: true);
            }
            catch (Exception ex)
            {
                _ctx.OutputWriter.WriteLine($"Failed to kill process '{fileName}': {ex}");
            }
        });
        return process;
    }
}

static class Extensions
{
    extension(StreamWriter writer)
    {
        public string FileName => (writer.BaseStream as FileStream)?.Name ?? throw new InvalidOperationException("StreamWriter is not writing to a file");
    }

    extension(StreamReader)
    {
        public static Task operator >>(StreamReader reader, StreamWriter writer)
            => reader.ReadToEndAsync().ContinueWith(t => writer.Write(t.Result));

        // ToDo: This is not streaming
        public static Task operator >>(StreamReader reader, TextWriter writer)
            => reader.ReadToEndAsync().ContinueWith(t => writer.Write(t.Result));
    }

    extension(Process process)
    {
        public async Task AssertSuccess()
        {
            await process.WaitForExitAsync();
            if (process.ExitCode != 0)
                throw new InvalidOperationException($"Process '{process.StartInfo.FileName}' exited with code {process.ExitCode:X}");
        }
    }
}

using System.Text;
using System.Text.RegularExpressions;

namespace PicoAsm.Tests;

public partial class MachineCodeGeneratorTests
{
    [Test]
    public async Task Halt_ShouldJumpToItself()
    {
        var rom = AssembleVhdl("""
            NOP
            NOP
            HALT
            """);

        await Assert.That(rom).IsEquivalentTo((List<string>)[
            "000000000000000000",
            "000000000000000000",
            "110000000000000010", // JUMP 2
        ]);
    }

    [Test]
    public async Task Jump_ShouldReachLabelsBeyond255()
    {
        StringBuilder program = new();
        for (int i = 0; i < 300; i++)
            program.AppendLine("NOP");
        program.AppendLine("far:");
        program.AppendLine("JUMP far");

        var rom = AssembleVhdl(program.ToString());

        await Assert.That(rom[300]).IsEqualTo("110000000100101100"); // JUMP 300
    }

    [Test]
    public async Task CarryCompareAndTest_ShouldEncode()
    {
        var rom = AssembleVhdl("""
            COMPARECY r1, r2
            COMPARECY r1, 0x0F
            TESTCY r3, r4
            TESTCY r3, 0x0F
            """);

        await Assert.That(rom).IsEquivalentTo((List<string>)[
            "011110000100100000",
            "011111000100001111",
            "101100001101000000",
            "101101001100001111",
        ]);
    }

    [Test]
    public async Task WriteTo_ShouldIncludeTrailingPartialChunk()
    {
        var generator = Assemble("""
            LOAD r1, 1
            LOAD r2, 2
            LOAD r3, 3
            LOAD r4, 4
            LOAD r5, 5
            """);

        using MemoryStream stream = new();
        generator.WriteTo(stream);
        var bytes = stream.ToArray();

        await Assert.That(bytes.Length).IsEqualTo(18);

        // 5th instruction sits at the start of the second 9-byte chunk
        uint fifth = (uint)(bytes[9] | (bytes[10] << 8) | ((bytes[11] & 0b11) << 16));
        await Assert.That(fifth).IsEqualTo(0b010101_0101_00000101u);
    }

    static MachineCodeGenerator Assemble(string program)
    {
        Parser<MachineCodeGenerator> parser = new(new());
        Tokenizer tokenizer = new(program);
        while (tokenizer.MoveNext(ref parser)) ;
        return parser.Visitor;
    }

    static List<string> AssembleVhdl(string program)
    {
        var generator = Assemble(program);

        using MemoryStream stream = new();
        generator.WriteVhdlTo(stream);
        var vhdl = Encoding.UTF8.GetString(stream.ToArray());

        return [.. Regex.Matches(vhdl, "\"([01]+)\"").Select(static m => m.Groups[1].Value)];
    }
}

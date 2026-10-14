using ShortDev.Parsing;

namespace PicoAsm.Tests;

public partial class ParserTest
{
    [Test]
    public async Task SingleArgStatements()
    {
        string program = """
        rl r0
        rr r1
        sl0 r2
        sl1 r3
        sla r4
        slx r5
        sr0 r6
        sr1 r7
        sra r8
        srx r9
        """;

        List<string?> nodes = [];
        Tokenizer tokenizer = new(program);
        Parser<ToStringListVisitor> parser = new(visitor: new(nodes));

        while (tokenizer.MoveNext(ref parser)) ;

        await Assert.That(nodes).IsEquivalentTo((string?[])[
            "OpReg { OperationId = RL, Register = Register { Id = 0 } }",
            "OpReg { OperationId = RR, Register = Register { Id = 1 } }",
            "OpReg { OperationId = SL0, Register = Register { Id = 2 } }",
            "OpReg { OperationId = SL1, Register = Register { Id = 3 } }",
            "OpReg { OperationId = SLA, Register = Register { Id = 4 } }",
            "OpReg { OperationId = SLX, Register = Register { Id = 5 } }",
            "OpReg { OperationId = SR0, Register = Register { Id = 6 } }",
            "OpReg { OperationId = SR1, Register = Register { Id = 7 } }",
            "OpReg { OperationId = SRA, Register = Register { Id = 8 } }",
            "OpReg { OperationId = SRX, Register = Register { Id = 9 } }",
        ]);
    }

    [Test]
    public async Task Fibonacci()
    {
        string program = """
        main:
            LOAD R0, 5      ; i = 5

        ; Fibonacci sequence generator
        fibonacci:
            LOAD RA, 1      ; current = 1
            LOAD RB, 1      ; next = 1
        .LOOP:
            COMPARE R0, 0   ; i - 0
            JUMP Z END      ; If i == 0, goto end
            OUTPUT RA, 0    ; print(current)
            LOAD RC, RA     ; tmp = current
            LOAD RA, RB     ; current = next
            ADD RB, RC      ; next += tmp
            SUB R0, 1       ; i--
            JUMP LOOP
        .END:
            HALT
        """;

        List<string?> nodes = [];
        Tokenizer tokenizer = new(program);
        Parser<ToStringListVisitor> parser = new(visitor: new(nodes));

        while (tokenizer.MoveNext(ref parser)) ;

        await Assert.That(nodes).IsEquivalentTo((string?[])[
            "Label { Name = main, Private = False }",
            "OpRegConst { OperationId = Load, Destination = Register { Id = 0 }, Value = 5 }",
            "Label { Name = fibonacci, Private = False }",
            "OpRegConst { OperationId = Load, Destination = Register { Id = 10 }, Value = 1 }",
            "OpRegConst { OperationId = Load, Destination = Register { Id = 11 }, Value = 1 }",
            "Label { Name = LOOP, Private = True }",
            "OpRegConst { OperationId = Compare, Destination = Register { Id = 0 }, Value = 0 }",
            "Jump { Condition = Zero, Target = END }",
            "OpRegConst { OperationId = Output, Destination = Register { Id = 10 }, Value = 0 }",
            "OpRegReg { OperationId = Load, Destination = Register { Id = 12 }, Source = Register { Id = 10 } }",
            "OpRegReg { OperationId = Load, Destination = Register { Id = 10 }, Source = Register { Id = 11 } }",
            "OpRegReg { OperationId = Add, Destination = Register { Id = 11 }, Source = Register { Id = 12 } }",
            "OpRegConst { OperationId = Sub, Destination = Register { Id = 0 }, Value = 1 }",
            "Jump { Condition = Always, Target = LOOP }",
            "Label { Name = END, Private = True }",
            "Halt { }",
        ]);
    }

    [Test]
    [Arguments("LOAD r1, 256")]
    [Arguments("ADD r1, 0x100")]
    [Arguments("OUTPUT r1, 300")]
    public async Task ConstantOutOfRange_ShouldThrow(string program)
    {
        await Assert.That(() => Parse(program)).Throws<SyntaxError>();
    }

    [Test]
    public async Task ConstantAtUpperBound_ShouldParse()
    {
        await Assert.That(Parse("LOAD r1, 0xFF")).IsEquivalentTo((List<string?>)[
            "OpRegConst { OperationId = Load, Destination = Register { Id = 1 }, Value = 255 }",
        ]);
    }

    static List<string?> Parse(string program)
    {
        List<string?> nodes = [];
        Tokenizer tokenizer = new(program);
        Parser<ToStringListVisitor> parser = new(visitor: new(nodes));

        while (tokenizer.MoveNext(ref parser)) ;
        return nodes;
    }

    static int Fibonacci(int n)
    {
        int current = 1, next = 1;
        for (int i = n; i > 0; i--)
        {
            Console.WriteLine(current);
            (current, next) = (next, current + next);
        }
        return current;
    }

    readonly ref struct ToStringListVisitor(List<string?> nodes) : IAstVisitor
    {
        private readonly List<string?> _nodes = nodes;

        public void Visit<Node>(in Node node) where Node : struct, IAstNode
        {
            _nodes.Add(node.ToString());
        }
    }
}

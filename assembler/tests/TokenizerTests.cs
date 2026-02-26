using ShortDev.Parsing;

namespace PicoAsm.Tests;

public partial class TokenizerTests
{
    [Test]
    public async Task Tokenizer_ShouldParseDecimalNumbers()
    {
        var input = """

              42 0  10
              27 100

            """;

        List<string?> tokens = [];

        Tokenizer tokenizer = new(input);
        ToStringListVisitor visitor = new(tokens);
        while (tokenizer.MoveNext(ref visitor)) ;

        await Assert.That(tokens).IsEquivalentTo((List<string?>)[
            $"Number {{ Value = {42} }}",
            $"Number {{ Value = {0} }}",
            $"Number {{ Value = {10} }}",
            $"Number {{ Value = {27} }}",
            $"Number {{ Value = {100} }}",
        ]);
    }

    [Test]
    public async Task Tokenizer_ShouldParseHexNumbers()
    {
        var input = """

              0x2a 0x2A  0x0
              0xFF 0x7f

            """;

        List<string?> tokens = [];

        Tokenizer tokenizer = new(input);
        ToStringListVisitor visitor = new(tokens);
        while (tokenizer.MoveNext(ref visitor)) ;

        await Assert.That(tokens).IsEquivalentTo((List<string?>)[
            $"Number {{ Value = {0x2a} }}",
            $"Number {{ Value = {0x2A} }}",
            $"Number {{ Value = {0x0} }}",
            $"Number {{ Value = {0xFF} }}",
            $"Number {{ Value = {0x7f} }}",
        ]);
    }

    [Test]
    public async Task Tokenizer_ShouldIgnoreWhiteSpaceAndComments()
    {
        var input = $"""
            ; This is a comment
            ; This is too

            {"\t \r\n \n \r \n\r"}

            ;Another comment
            """;

        List<string?> tokens = [];

        Tokenizer tokenizer = new(input);
        ToStringListVisitor visitor = new(tokens);
        while (tokenizer.MoveNext(ref visitor)) ;

        await Assert.That(tokens).IsEmpty();
    }

    [Test]
    public async Task Tokenizer_ShouldParseSimpleProgram()
    {
        var input = """
        ; This is a sample assembly code
        ; https://kevinpt.github.io/opbasm/rst/tutorial.html
            INPUT s5, 0 ; Load a local register to work with
            COMPARE s5, 42    ; Subtract 42 from s5 and update C and Z flags
            JUMP Z , equal    ; If s5 == 42 the Z flag is set
        ; Not equal (false block)
            LOAD sE, N
            JUMP end_if
        equal: ; (true block)
            LOAD sE, E
        end_if:
            OUTPUT sE, 1
        """;

        List<string?> tokens = [];

        Tokenizer tokenizer = new(input);
        ToStringListVisitor visitor = new(tokens);
        while (tokenizer.MoveNext(ref visitor)) ;

        // ToDo: Assertion
    }

    readonly ref struct ToStringListVisitor(List<string?> tokens) : ITokenVisitor
    {
        private readonly List<string?> _tokens = tokens;

        public void Visit<Tokenizer, Token>(ref Tokenizer tokenizer, in Token token)
            where Tokenizer : struct, ITokenizer, allows ref struct
            where Token : struct, IToken
        {
            _tokens.Add(token.ToString());
        }
    }
}

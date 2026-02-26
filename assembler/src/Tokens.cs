using ShortDev.Parsing;

namespace PicoAsm;

internal static class Tokens
{
    // Character tokens
    public readonly record struct Dot : IToken;
    public readonly record struct Colon : IToken;
    public readonly record struct Comma : IToken;

    // Complex tokens
    public readonly record struct Identifier(string Name) : IToken;
    public readonly record struct Register(int Id) : IToken;
    public readonly record struct Number(int Value) : IToken;

    // Instruction tokens
    public readonly record struct Keyword(PicoOps Operation) : IToken;

    // Flag tokens
    public readonly record struct C : IToken;
    public readonly record struct NC : IToken;
    public readonly record struct Z : IToken;
    public readonly record struct NZ : IToken;
}

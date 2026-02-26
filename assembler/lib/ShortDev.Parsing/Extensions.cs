namespace ShortDev.Parsing;

public static class Extensions
{
    extension<Tokenizer>(ref Tokenizer tokenizer) where Tokenizer : struct, ITokenizer, allows ref struct
    {
        public void Expect<Token>()
            where Token : IToken
        {
            _ = tokenizer.Accept<Tokenizer, Token>();
        }

        public Token Accept<Token>()
            where Token : IToken
        {
            ExpectTokenVisitor<Token> visitor = new();
            if (!tokenizer.MoveNext(ref visitor))
                throw new SyntaxError($"Expected token of type {typeof(Token).Name}, but got `EOF`") { Offset = tokenizer.Position };

            return visitor.Token;
        }
    }

    delegate void VisitDelegate<TState, Token>(ref TState state, in Token token)
        where Token : IToken;

    ref struct ExpectTokenVisitor<TExpectedToken> : ITokenVisitor where TExpectedToken : IToken
    {
        public TExpectedToken Token { get; private set; }

        public void Visit<Tokenizer, TActualToken>(ref Tokenizer tokenizer, in TActualToken token)
            where Tokenizer : struct, ITokenizer, allows ref struct
            where TActualToken : struct, IToken
        {
            if (token is not TExpectedToken convertedToken)
                throw new SyntaxError($"Expected token of type {typeof(TExpectedToken).Name}, but got `{token}`") { Offset = tokenizer.Position };

            Token = convertedToken;
        }
    }
}

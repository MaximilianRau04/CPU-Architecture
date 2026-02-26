namespace ShortDev.Parsing;

public interface ITokenVisitor
{
    void Visit<Tokenizer, Token>(ref Tokenizer tokenizer, in Token token)
        where Tokenizer : struct, ITokenizer, allows ref struct
        where Token : struct, IToken;
}

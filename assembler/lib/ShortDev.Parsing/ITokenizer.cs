namespace ShortDev.Parsing;

public interface ITokenizer
{
    bool MoveNext<TVisitor>(ref TVisitor visitor) where TVisitor : struct, ITokenVisitor, allows ref struct;

    public int Position { get; }
}

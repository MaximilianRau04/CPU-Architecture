namespace ShortDev.Parsing;

public sealed class SyntaxError(string message) : Exception(message)
{
    public required int Offset { get; init; }
}

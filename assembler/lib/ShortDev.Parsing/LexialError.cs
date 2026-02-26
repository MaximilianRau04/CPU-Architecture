namespace ShortDev.Parsing;

public sealed class LexialError(string message) : Exception(message)
{
    public required int Offset { get; init; }
}

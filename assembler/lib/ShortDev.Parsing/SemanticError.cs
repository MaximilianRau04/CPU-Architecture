namespace ShortDev.Parsing;

public sealed class SemanticError(string message) : Exception(message);

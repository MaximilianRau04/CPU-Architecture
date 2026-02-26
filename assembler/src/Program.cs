using PicoAsm;
using ShortDev.Parsing;

if (args is not [var fileName])
{
    Console.Error.WriteLine("Usage: pico-asm <file-name>");
    return -1;
}

fileName = Path.GetFullPath(fileName);

if (!File.Exists(fileName))
{
    Console.Error.WriteLine($"File not found: {fileName}");
    return -1;
}

var input = File.ReadAllText(fileName);

Parser<MachineCodeGenerator> parser = new(new());

Tokenizer tokenizer = new(input);
try
{
    while (tokenizer.MoveNext(ref parser)) ;

    parser.Visitor.Complete();
}
catch (LexialError ex)
{
    PrintError(fileName, GetPosition(input.AsSpan(), ex.Offset), type: "lexical", ex.Message);
    return -1;
}
catch (SyntaxError ex)
{
    PrintError(fileName, GetPosition(input.AsSpan(), ex.Offset), type: "syntax", ex.Message);
    return -1;
}
catch (SemanticError ex)
{
    PrintError(fileName, GetPosition(input.AsSpan(), 0), type: "semantic", ex.Message);
    return -1;
}

using var stdout = Console.OpenStandardOutput();
parser.Visitor.WriteVhdlTo(stdout);

return 0;

static (int line, int column) GetPosition(ReadOnlySpan<char> buffer, int offset)
{
    offset = Math.Min(offset, buffer.Length - 1);

    int line = 1, lastNewLine = 0;
    for (int i = 0; i < offset; i++)
    {
        var c = buffer[i];
        if (c is '\n' or '\r')
        {
            line++;
            lastNewLine = i;
        }

        if (c is '\r' && i + 1 <= offset && buffer[i + 1] is '\n')
            i++;
    }
    return (line, offset - lastNewLine + 1);
}

static void PrintError(string fileName, (int line, int column) position, string type, string message)
{
    var previousColor = Console.ForegroundColor;

    Console.ForegroundColor = ConsoleColor.DarkGray;
    Console.Error.Write($"{fileName}({position.line},{position.column}): ");

    Console.ForegroundColor = ConsoleColor.Red;
    Console.Error.Write($"{type} error");

    Console.ForegroundColor = ConsoleColor.White;
    Console.Error.WriteLine($": {message}");

    Console.ForegroundColor = previousColor;
}

using ShortDev.Parsing;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace PicoAsm;

internal ref struct Tokenizer(ReadOnlySpan<char> buffer) : ITokenizer
{
    readonly ref readonly char _start = ref MemoryMarshal.GetReference(buffer);
    ref readonly char _current = ref MemoryMarshal.GetReference(buffer);
    readonly ref readonly char _end = ref Unsafe.Add(ref MemoryMarshal.GetReference(buffer), buffer.Length);

    public bool MoveNext<TVisitor>(ref TVisitor visitor) where TVisitor : struct, ITokenVisitor, allows ref struct
    {
        while (true)
        {
            if (!TrySkipWhitespace())
                return false;

            if (_current is not ';')
                break;

            if (!TrySkipLine())
                return false;
        }

        if (_current is '.')
        {
            _current = ref Next();

            visitor.Visit(ref this, new Tokens.Dot());
            return true;
        }

        if (_current is ':')
        {
            _current = ref Next();

            visitor.Visit(ref this, new Tokens.Colon());
            return true;
        }

        if (_current is ',')
        {
            _current = ref Next();

            visitor.Visit(ref this, new Tokens.Comma());
            return true;
        }

        static bool IsValidTokenChar(char c) => char.IsAsciiLetterOrDigit(c) || c is '_';

        if (!IsValidTokenChar(_current))
            Throw($"Unexpected token `{_current}`.");

        ReadToken(IsValidTokenChar, out var token);

        // Register
        if (token is ['s' or 'S' or 'r' or 'R', var regIdStr])
        {
            if (regIdStr is >= '0' and <= '9')
            {
                visitor.Visit(ref this, new Tokens.Register(regIdStr - '0'));
                return true;
            }
            else if (regIdStr is >= 'A' and <= 'F')
            {
                visitor.Visit(ref this, new Tokens.Register(regIdStr - 'A' + 0xA));
                return true;
            }
        }

        // hex number
        if (token is ['0', 'x', .. var hexString])
        {
            if (!int.TryParse(hexString, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out var number))
                Throw($"Invalid hex number `{token}`.");

            visitor.Visit(ref this, new Tokens.Number(number));
            return true;
        }

        // decimal number
        if (token is [_, ..] && char.IsAsciiDigit(token[0]))
        {
            if (!int.TryParse(token, NumberStyles.Integer, CultureInfo.InvariantCulture, out var number))
                Throw($"Invalid decimal number `{token}`.");

            visitor.Visit(ref this, new Tokens.Number(number));
            return true;
        }

        // Keyword or identifier
        switch (token)
        {
            case "nop":
            case "NOP":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Nop));
                return true;

            case "input":
            case "INPUT":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Input));
                return true;

            case "output":
            case "OUTPUT":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Output));
                return true;

            case "add":
            case "ADD":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Add));
                return true;

            case "addcy":
            case "ADDCY":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.AddCarry));
                return true;

            case "sub":
            case "SUB":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Sub));
                return true;

            case "subcy":
            case "SUBCY":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SubCarry));
                return true;

            case "and":
            case "AND":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.And));
                return true;

            case "or":
            case "OR":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Or));
                return true;

            case "xor":
            case "XOR":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.XOr));
                return true;

            case "compare":
            case "COMPARE":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Compare));
                return true;

            case "comparecy":
            case "COMPARECY":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.CompareCarry));
                return true;

            case "test":
            case "TEST":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Test));
                return true;

            case "testcy":
            case "TESTCY":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.TestCarry));
                return true;

            case "jump":
            case "JUMP":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Jump));
                return true;

            case "load":
            case "LOAD":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Load));
                return true;

            case "fetch":
            case "FETCH":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Fetch));
                return true;

            case "store":
            case "STORE":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Store));
                return true;

            case "rl":
            case "RL":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.RL));
                return true;

            case "rr":
            case "RR":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.RR));
                return true;

            case "sl0":
            case "SL0":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SL0));
                return true;

            case "sl1":
            case "SL1":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SL1));
                return true;

            case "sla":
            case "SLA":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SLA));
                return true;

            case "slx":
            case "SLX":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SLX));
                return true;

            case "sr0":
            case "SR0":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SR0));
                return true;

            case "sr1":
            case "SR1":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SR1));
                return true;

            case "sra":
            case "SRA":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SRA));
                return true;

            case "srx":
            case "SRX":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.SRX));
                return true;

            case "c":
            case "C":
                visitor.Visit(ref this, new Tokens.C());
                return true;

            case "nc":
            case "NC":
                visitor.Visit(ref this, new Tokens.NC());
                return true;

            case "z":
            case "Z":
                visitor.Visit(ref this, new Tokens.Z());
                return true;

            case "nz":
            case "NZ":
                visitor.Visit(ref this, new Tokens.NZ());
                return true;

            case "halt":
            case "HALT":
                visitor.Visit(ref this, new Tokens.Keyword(PicoOps.Halt));
                return true;

            default:
                visitor.Visit(ref this, new Tokens.Identifier(token.ToString()));
                return true;
        }
    }

    public readonly int Position => (int)Unsafe.ByteOffset(in _start, in _current) / sizeof(char);

    [DoesNotReturn]
    readonly void Throw(string message)
    {
        throw new LexialError(message)
        {
            Offset = Position
        };
    }

    bool TrySkipWhitespace() => TrySkip(static c => char.IsWhiteSpace(c));
    bool TrySkipLine() => TrySkip(static c => c is not ('\r' or '\n'));

    bool TrySkip(Func<char, bool> predicate)
    {
        while (true)
        {
            if (Unsafe.IsAddressGreaterThanOrEqualTo(in _current, in _end))
                return false;

            if (!predicate(_current))
                return true;

            _current = ref Next();
        }
    }

    void ReadToken(Func<char, bool> predicate, out ReadOnlySpan<char> token)
    {
        ref readonly char start = ref _current;
        _ = TrySkip(predicate);
        token = MemoryMarshal.CreateReadOnlySpan(in start, (int)Unsafe.ByteOffset(in start, in _current) / sizeof(char));
    }

    readonly ref readonly char Next() => ref Unsafe.Add(ref Unsafe.AsRef(in _current), 1);
}

using ShortDev.Parsing;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace PicoAsm;

internal struct MachineCodeGenerator() : IAstVisitor
{
    readonly List<uint> _instructions = [];
    readonly List<string> _instructionStr = [];
    readonly List<(int instructionIndex, string targetName, Scope scope)> _jumps = [];

    readonly Scope _toplevelScope = new(address: 0) { Parent = null };

    Scope CurrentScope
    {
        get => field ??= _toplevelScope;
        set;
    }

    public void Visit<Node>(in Node statement) where Node : struct, IAstNode
    {
        switch (statement)
        {
            case Statements.Label(var name, var isPrivate):
                var address = _instructions.Count;
                if (!isPrivate)
                    _toplevelScope.Add(name, CurrentScope = new(address) { Parent = _toplevelScope });
                else
                    CurrentScope.Add(name, new(address) { Parent = CurrentScope });
                break;

            case Statements.Nop:
                _instructionStr.Add("Nop");
                _instructions.Add(0);
                break;

            case Statements.Halt:
                // The CPU has no halt opcode, so HALT is an unconditional jump to itself
                _instructionStr.Add("Halt");
                _instructions.Add(((uint)PicoOps.Jump << 12) | ((uint)_instructions.Count & 0xFFF));
                break;

            case Statements.OpReg(var operationId, var register):
                _instructionStr.Add($"{operationId} r{register.Id:X}");
                _instructions.Add((((uint)operationId & 0b111111) << 12) | (((uint)register.Id & 0xF) << 8));
                break;

            case Statements.OpRegReg(var operationId, var destination, var source):
                _instructionStr.Add($"{operationId} r{destination.Id:X} r{source.Id:X}");
                _instructions.Add((((uint)operationId & 0b111111) << 12) | (((uint)destination.Id & 0xF) << 8) | (((uint)source.Id & 0xF) << 4));
                break;

            case Statements.OpRegConst(var operationId, var destination, var value):
                _instructionStr.Add($"{operationId} r{destination.Id:X} {value}");

                operationId |= (PicoOps)1;
                _instructions.Add((((uint)operationId & 0b111111) << 12) | (((uint)destination.Id & 0xF) << 8) | ((uint)value & 0xFF));
                break;

            case Statements.Jump(var condition, var target):
                var opCode = (uint)((byte)PicoOps.Jump | (byte)condition);
                _instructionStr.Add($"Jump {condition} {target}");
                _instructions.Add((opCode & 0b111111) << 12);
                _jumps.Add((instructionIndex: _instructions.Count - 1, target, CurrentScope));
                break;
        }
    }

    public readonly void Complete()
    {
        if (_instructions.Count > Math.Pow(2, 12))
            throw new SemanticError($"Program is too large to fit into ROM: {_instructions.Count} > {(int)Math.Pow(2, 12)} instructions");

        foreach (var (i, targetName, scope) in _jumps)
        {
            Scope? targetScope = null;
            for (var currentScope = scope; currentScope?.TryGetValue(targetName, out targetScope) == false; currentScope = currentScope.Parent) ;

            if (targetScope is null)
                throw new SemanticError($"Could not find jump target '{targetName}'");

            _instructions[i] |= (uint)targetScope.Address & 0xFFF;
        }
        _jumps.Clear();
    }

    sealed class Scope(int address) : Dictionary<string, Scope>
    {
        public int Address { get; } = address;

        public required Scope? Parent { get; init; }
    }

    public void WriteVhdlTo(Stream stream)
    {
        Complete();

        Debug.Assert(_instructions.Count == _instructionStr.Count);

        using StreamWriter writer = new(stream, leaveOpen: true);
        for (int i = 0; i < _instructions.Count; i++)
        {
            var instr = _instructions[i];
            var instrStr = _instructionStr[i];
            writer.WriteLine($"{i,3} => \"{instr:b18}\", -- {instrStr}");
        }
        writer.Flush();
    }

    public void WriteTo(Stream stream)
    {
        Complete();

        // Instructions are 18bit wide, so we pack 4 instructions into 9 bytes
        Span<byte> buffer = new byte[16];

        int i, count = _instructions.Count;
        for (i = 0; i < count; i++)
        {
            packed(buffer) |= (UInt128)_instructions[i] << ((i % 4) * 18);

            if (i % 4 < 3)
                continue;

            stream.Write(buffer[..9]);
            packed(buffer) = 0;
        }

        if (count % 4 != 0)
            stream.Write(buffer[..9]);

        stream.Flush();

        static ref UInt128 packed(Span<byte> buffer) => ref Unsafe.As<byte, UInt128>(ref MemoryMarshal.GetReference(buffer));
    }
}

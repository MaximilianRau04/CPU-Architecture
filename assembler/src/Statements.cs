using ShortDev.Parsing;

namespace PicoAsm;

internal static class Statements
{
    public readonly record struct Label(string Name, bool Private = false) : IAstNode;
    public readonly record struct Nop : IAstNode;
    public readonly record struct Halt : IAstNode;
    public readonly record struct OpReg(PicoOps OperationId, Tokens.Register Register) : IAstNode;
    public readonly record struct OpRegConst(PicoOps OperationId, Tokens.Register Destination, int Value) : IAstNode;
    public readonly record struct OpRegReg(PicoOps OperationId, Tokens.Register Destination, Tokens.Register Source) : IAstNode;
    public readonly record struct Jump(JumpCondition Condition, string Target) : IAstNode;
}

internal enum JumpCondition
{
    Always = 0b000,
    Zero = 0b001,
    NotZero = 0b010,
    Carry = 0b011,
    NotCarry = 0b100,
}

using ShortDev.Parsing;
using System.Diagnostics.CodeAnalysis;

namespace PicoAsm;

internal ref struct Parser<TAstVisitor>(TAstVisitor visitor) : ITokenVisitor where TAstVisitor : IAstVisitor, allows ref struct
{
    TAstVisitor _visitor = visitor;

    [UnscopedRef]
    public ref TAstVisitor Visitor => ref _visitor;

    public void Visit<Tokenizer, Token>(ref Tokenizer tokenizer, in Token token)
        where Tokenizer : struct, ITokenizer, allows ref struct
        where Token : struct, IToken
    {
        switch (token)
        {
            case Tokens.Identifier(var labelName):
                tokenizer.Expect<Tokenizer, Tokens.Colon>();
                _visitor.Visit(new Statements.Label(labelName));
                break;
            case Tokens.Dot:
                var privateLabelName = tokenizer.Accept<Tokenizer, Tokens.Identifier>().Name;
                tokenizer.Expect<Tokenizer, Tokens.Colon>();
                _visitor.Visit(new Statements.Label(privateLabelName, Private: true));
                break;

            case Tokens.Keyword(PicoOps.Nop):
                _visitor.Visit(new Statements.Nop());
                break;

            case Tokens.Keyword(PicoOps.Halt):
                _visitor.Visit(new Statements.Halt());
                break;

            case Tokens.Keyword(PicoOps.Jump):
                JumpVisitor jumpVisitor = new();
                if (!tokenizer.MoveNext(ref jumpVisitor))
                    throw new SyntaxError("Unexpected end of tokens while expecting jump condition or address.") { Offset = tokenizer.Position };

                _visitor.Visit(jumpVisitor.Result);
                break;

            case Tokens.Keyword(var opCode):
                var destRegister = tokenizer.Accept<Tokenizer, Tokens.Register>();

                if (opCode.IsShiftOrRotate)
                {
                    _visitor.Visit(new Statements.OpReg(opCode, destRegister));
                    break;
                }

                tokenizer.Expect<Tokenizer, Tokens.Comma>();
                ConstOrRegisterVisitor tokenVisitor = new();
                if (!tokenizer.MoveNext(ref tokenVisitor))
                    throw new SyntaxError("Unexpected end of tokens while expecting register or constant.") { Offset = tokenizer.Position };

                switch (tokenVisitor.Result)
                {
                    case (isRegister: true, var sourceRegId):
                        _visitor.Visit(new Statements.OpRegReg(opCode, destRegister, new Tokens.Register(sourceRegId)));
                        break;

                    case (isRegister: false, var constantValue):
                        _visitor.Visit(new Statements.OpRegConst(opCode, destRegister, constantValue));
                        break;
                }
                break;

            default:
                throw new SyntaxError($"Unexpected token: {token}") { Offset = tokenizer.Position };
        }
    }

    ref struct ConstOrRegisterVisitor : ITokenVisitor
    {
        public (bool isRegister, int value) Result { get; private set; }
        public void Visit<Tokenizer, Token>(ref Tokenizer tokenizer, in Token token)
            where Tokenizer : struct, ITokenizer, allows ref struct
            where Token : struct, IToken
        {
            Result = token switch
            {
                Tokens.Register(var registerNumber) => (isRegister: true, value: registerNumber),
                Tokens.Number(var numberValue) when numberValue is >= 0 and <= 0xFF => (isRegister: false, value: numberValue),
                Tokens.Number(var numberValue) => throw new SyntaxError($"Constant {numberValue} does not fit into 8 bits (0..255)") { Offset = tokenizer.Position },
                _ => throw new SyntaxError($"Expected register or constant, got: {token}") { Offset = tokenizer.Position }
            };
        }
    }

    ref struct JumpVisitor : ITokenVisitor
    {
        public Statements.Jump Result { get; private set; }
        public void Visit<Tokenizer, Token>(ref Tokenizer tokenizer, in Token token)
            where Tokenizer : struct, ITokenizer, allows ref struct
            where Token : struct, IToken
        {
            if (token is Tokens.Identifier(var targetName))
            {
                Result = new Statements.Jump(JumpCondition.Always, targetName);
                return;
            }

            var condition = token switch
            {
                Tokens.C => JumpCondition.Carry,
                Tokens.NC => JumpCondition.NotCarry,
                Tokens.Z => JumpCondition.Zero,
                Tokens.NZ => JumpCondition.NotZero,
                _ => throw new SyntaxError($"Expected flag or address, got: {token}") { Offset = tokenizer.Position }
            };
            Result = new Statements.Jump(condition, tokenizer.Accept<Tokenizer, Tokens.Identifier>().Name);
        }
    }
}

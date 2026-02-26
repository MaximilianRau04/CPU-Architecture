namespace ShortDev.Parsing;

public interface IAstVisitor
{
    void Visit<Node>(in Node node)
        where Node : struct, IAstNode;
}

public interface IAstNode;

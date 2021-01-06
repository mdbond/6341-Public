package ast;

import java.io.PrintStream;

public class ReturnStmt extends Stmt {

    final Expr expr;

    public ReturnStmt(Expr expr, Location loc) {
        super(loc);
        this.expr = expr;
    }

    @Override
    public void println(PrintStream ps, String indent) {
        ps.println(indent + "return " + expr + ";");
    }

    @Override
    Object exec() {
        return expr.eval();
    }
}

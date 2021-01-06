package ast;

import java.io.PrintStream;

public class Program extends ASTNode {

    final Stmt stmt;

    public Program(Stmt stmt, Location loc) {
        super(loc);
        this.stmt = stmt;
    }

    public void println(PrintStream ps) {
        stmt.println(ps, "");
    }

    public Object exec(long argument) {
        return stmt.exec();
    }
}

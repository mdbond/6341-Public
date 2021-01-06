package ast;

import java.io.PrintStream;

abstract public class Stmt extends ASTNode {

    Stmt(Location loc) {
        super(loc);
    }

    abstract void println(PrintStream ps, String indent);

    abstract Object exec();
}

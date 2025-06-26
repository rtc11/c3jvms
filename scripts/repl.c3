module repl;

import std::io;
import lexer;

fn void main()
{
    while (true)
    {
        io::printf("$ ");
        String input = io::readline(allocator::heap())!!;
        Lexer lexer = lexer::new(input);

        while(lexer.has_next())
        {
            Token token = lexer.next();
            io::printfn("%s", token);
            if (token.type == ILLEGAL) break;
        }
    }
}

import std.stdio;

import desutil;
import desmath;
import desil;
import desgl;
import desphys;

void main() 
{ 
    version(unittest)
    {
        writeln( "\n------------------------" ); 
        writeln( "DES unittesting complite" ); 
        writeln( "------------------------\n" ); 
    }
    else
    {
        stderr.writeln( "build with -unittest flag to test DES" );
    }
}

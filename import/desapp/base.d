module desapp.base;

class AppException : Exception
{
    @safe pure nothrow this( string msg, string file = __FILE__, size_t line = __LINE__ )
    { super( msg, file, line ); }
}

interface App
{
protected:
    void delay();
    bool step();

    @property bool isRuning();

public:
    final void run() { while( isRuning && step() ) delay(); }

    void quit();
}


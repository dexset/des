module tests.buffer;

import tests.iface;

class BufferTest : AutoTestWithCases
{
    void init()
    {
        addSubTest( "set/get data",
        {
            logger.error( "empty test case" );
            return false;
        });
    }

    wstring name() @property { return "buffer test"w; }
}

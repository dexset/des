module tests;

public import tests.iface;

import tests.buffer;
import tests.bufferPRWCM;
import tests.multidrawelementsindirect;

Test[] getAllTests()
{
    Test[] ret;

    ret ~= new BufferTest;
    ret ~= new BufferPRWCM;
    ret ~= new MultiDrawElementsIndirectTest;

    return ret;
}

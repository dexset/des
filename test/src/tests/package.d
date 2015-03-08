module tests;

public import tests.iface;

import tests.buffer;
import tests.bufferPRWCM;

Test[] getAllTests()
{
    Test[] ret;

    ret ~= new BufferTest;
    ret ~= new BufferPRWCM;

    return ret;
}

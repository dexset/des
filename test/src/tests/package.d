module tests;

public import tests.iface;

import tests.buffer;

Test[] getAllTests()
{
    Test[] ret;

    ret ~= new BufferTest;

    return ret;
}

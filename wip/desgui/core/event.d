/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desgui.core.event;

public import desmath.linear.vector;

/++
 события клавиатуры
 +/
struct DiKeyboardEvent
{
    /++ модификаторы (SHIFT, ALT etc) +/
    enum Mod
    {
        NONE = 0x0000,
        LSHIFT = 0x0001,
        RSHIFT = 0x0002,
        LCTRL = 0x0040,
        RCTRL = 0x0080,
        LALT = 0x0100,
        RALT = 0x0200,
        LGUI = 0x0400,
        RGUI = 0x0800,
        NUM = 0x1000,
        CAPS = 0x2000,
        MODE = 0x4000,
        CTRL = (LCTRL|RCTRL),
        SHIFT = (LSHIFT|RSHIFT),
        ALT = (LALT|RALT),
        GUI = (LGUI|RGUI),
    }
    /++ нажата или отпущена клавиша +/
    bool pressed;
    /++ если нажата и удерживается +/
    bool repeat;
    /++ код клавиши +/
    uint scan;
    uint key;
    /++ модификатор +/
    uint mod;
}

/++
 событие ввода текста
 +/
struct DiTextEvent { dchar ch; }

/++
 событие мыши
 +/
struct DiMouseEvent
{
    enum Type { PRESSED, RELEASED, MOTION, WHEEL };
    enum Button
    {
        LEFT   = 1<<0,
        MIDDLE = 1<<1,
        RIGHT  = 1<<2,
        X1     = 1<<3,
        X2     = 1<<4,
    }
    /++ тип события +/
    Type type; 

    /++ mask for motion, button for pressed/released, 0 for wheel+/
    uint btn; 

    ivec2 data;
}

/++
 событие джостика
 +/
struct DiJoyEvent
{
    /++ номер джостика +/
    uint joy;

    /++ тип события +/
    enum Type { AXIS, BUTTON, BALL, HAT };
    Type type;

    /++ номер изменившегося элемента +/
    size_t no;

    /++ состояние всех осей +/
    float[] axis;
    /++ состояние всех кнопок ( true - нажата, false - нет ) +/
    bool[] buttons;
    /++ состояние всех трэкболов +/
    ivec2[] balls;
    /++ состояние всех шляпок +/
    byte[] hats;
}

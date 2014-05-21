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

module desgui.core.context;

public import desgui.core.except;
public import desgui.core.draw;
public import desgui.core.textrender;

interface DiContext
{
    @property DiDrawStack drawStack();
    @property DiGlyphRender baseGlyphRender();
    @property DiDrawFactory draw();
}

version(unittest)
{
    import desil;
    package
    {
        class TestDrawStack : DiDrawStack
        {
        private:
            const(DiViewport)[] cur;
            irect[] work;

        public:

            irect push( in DiViewport w )
            {
                cur ~= w;
                if( work.length == 0 )
                    work ~= w.rect;

                work ~= work[$-1].overlapLocal( w.rect );

                return work[$-1];
            }

            void pull()
            {
                cur = cur[0 .. $-1];
                work = work[0 .. $-1];
            }
        }

        class TestDrawFactory : DiDrawFactory
        {
            @property DiDrawRect rect() { return new TestDrawRect; }
        }

        class TestSubstrate : DiSubstrate
        {
            void draw() {}
            void idle( float dt ) {}
            void reshape( in irect r ) {}
        }

        class TestStyle : DiStyle
        {
            DiSubstrate getSubstrate( string name )
            { return new TestSubstrate(); }
        }

        class TestContext : DiContext
        {
            DiDrawStack ds;
            DiGlyphRender gr;
            DiDrawFactory df;

            this() 
            { 
                ds = new TestDrawStack; 
                gr = new TestGlyphRender;
                df = new TestDrawFactory;
            }

            @property DiDrawStack drawStack() { return ds; }
            @property DiGlyphRender baseGlyphRender() { return gr; }
            @property DiDrawFactory draw() { return df; }
        }

        static Image screen;
        void clearScreen(){ screen = Image( imsize_t(100, 20), ImageType( ImCompType.UBYTE, 1 ) ); }
        static this(){ clearScreen(); }

        class TestDrawRect: DiDrawRect
        {
        private: 
            Image tex;
            UseTexture ut;
            irect rr;
            col4 clr;
        public:
            this( irect r=irect(0,0,1,1) )
            {
                rr = r;
                tex = Image( imsize_t(r.size), ImageType( ImCompType.UBYTE, 1 ) );
            }

            @property
            {
                ref UseTexture useTexture() { return ut; }
                ref const(UseTexture) useTexture() const { return ut; }

                irect rect() const{ return rr; }

                col4 color() const { return clr; }
                void color( in col4 c ){ clr = c; }
            }

            void draw(){ screen.paste( rr.pos, tex ); }

            void reshape( in irect r ){ rr = r; }

            void image( in Image im ){ tex = Image(im); }
            void image( in ImageReadAccess im ){ tex = Image(im.selfImage()); }
        }
    }
}

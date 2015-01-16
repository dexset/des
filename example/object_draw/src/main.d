import des.app;

import window;

void main()
{
    auto app = new DesApp;
    app.addWindow({ return new MainWindow; });
    while( app.isRuning ) app.step();
}

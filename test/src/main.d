module main;

import des.app;
import des.util.logsys;

import window;

void main()
{
    logrule.setLevel( LogLevel.INFO );
    logger.info( "app start" );
    auto app = new DesApp;
    app.addWindow({ return new MainWindow(); });
    while( app.isRunning )
    {
        app.step();
        SDL_Delay(15);
    }
    app.destroy();
    logger.info( "app finish" );
}

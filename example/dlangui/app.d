module app;

import dlangui;
import plot2d;

mixin APP_ENTRY_POINT;

class PlotWidget : Widget
{
    override void onDraw(DrawBuf buf)
    {
        super.onDraw(buf);
    }
}

extern (C) int UIAppMain(string[] args)
{
    Window window = Platform.instance.createWindow(
        "example", null, WindowFlag.Resizable, 800, 400);

    window.mainWidget = new PlotWidget();

    window.show();

    return Platform.instance.enterMessageLoop();
}
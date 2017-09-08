import std.stdio;

import gtk.Main;
import gtk.Window;
import gtk.Widget;
import gtk.DrawingArea;

import plot2d;

version = with_tre;
version = fix_viewport;

void main(string[] args)
{
    Main.init(args);

    auto win = new Window("example");
    auto da = new DrawingArea();

    auto plot = new Plot(null);

    import std.math : sin;
    import std.range : iota;
    import std.random;
    import std.datetime;
    auto uu() { return uniform!"[]"(-1.0, 1.0); }
    auto ct() { return Clock.currStdTime / 1e7; }

    version (with_line)
    {
        plot.charts ~= new LineChart(Color(1,0,0,1),
            (ref Appender!(Point[]) buf)
            {
                auto line = iota(0, 1.02, 0.02).map!(i=>Point(i, 3 * sin(i*PI*2 + ct())));
                buf.put(line);
            }
        );

        (cast(LineChart)plot.charts[0]).dash = [2, 5];
    }

    version (fix_viewport)
    {
        plot.settings.viewport = Viewport(DimSeg(-2,2), DimSeg(-1, 2));
        plot.settings.autoFit = false;
        plot.settings.padding = Border(0);
    }

    version (with_tre)
    {
        auto tre = iota(-2, 2.02, 0.02).map!(i=>TreStat(i, sin(i*sin(i+ct()*0.5)*PI*2) + 0.4 + sin(i*PI*2+ct*3) * 0.3,
                                                        sin(i*sin(i+ct()*0.5)*PI*2),
                                                        sin(i*sin(i+ct()*0.5)*PI*2) - 0.4 - sin(i*PI*2+ct*5) * 0.3));
        plot.charts ~= new TreChart(
            Color(0,0.5,0,0.8),

            Color(1,1,0,.3),
            Color(1,1,0,.2),

            Color(0,1,1,.3),
            Color(0,1,1,.2),
            (ref Appender!(TreStat[]) buf) { buf.put(tre.save); }
        );
    }

    da.addOnDraw((Scoped!Context cr, Widget w)
    {
        plot.draw(cr, Point(w.getAllocatedWidth(),
                            w.getAllocatedHeight()));
        return false;
    });

    win.add(da);
    win.setDefaultSize(800, 400);
    win.showAll();

    import glib.Idle;
    auto idle = new Idle({
        plot.update();
        da.queueDraw();
        return true;
    }, true);
    win.addOnHide((w){ Main.quit(); });
    Main.run();
}
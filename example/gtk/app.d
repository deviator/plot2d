import std.stdio;

import gtk.Main;
import gtk.Window;
import gtk.Widget;
import gtk.DrawingArea;

import plot2d;

void main(string[] args)
{
    Main.init(args);

    auto win = new Window("example");
    auto da = new DrawingArea();

    auto plot = new Plot(null);

    import std.math : sin;
    import std.range : iota;
    auto arr = iota(0, 1.01, 0.01).map!(i=>Point(i, sin(i*PI*4)));

    plot.charts ~= new LineChart(Color(0,1,0,1),
        (ref Appender!(Point[]) buf) { buf.put(arr.save); }
    );

    da.addOnDraw((Scoped!Context c, Widget w)
    {
        auto cr = c.Scoped_payload;
        plot.draw(cr, Point(w.getAllocatedWidth(),
                            w.getAllocatedHeight()));
        return false;
    });
    plot.update();

    win.add(da);
    win.setDefaultSize(800, 400);
    win.showAll();
    win.addOnHide((w){ Main.quit(); });

    Main.run();
}
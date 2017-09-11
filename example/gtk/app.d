import std.stdio;
import std.math : sin;
import std.range : iota;
import std.random;
import std.datetime;

import gtk.Main;
import gtk.Window;
import gtk.Widget;
import gtk.DrawingArea;
import gtk.Box;
import cairo.Context;

import plot2d;

version = with_tre;
version = fix_viewport;

auto uu(double v=1) { return uniform!"[]"(-v, v); }
auto ct() { return Clock.currStdTime / 1e7; }

class ChartWH
{
    import glib.Idle;
    DrawingArea da;
    Plot plot;
    CairoCtx ctx;
    Idle idle;
    bool interactive = true;

    this()
    {
        da = new DrawingArea;
        plot = new Plot;
        ctx = new CairoCtx;

        setupPlot();

        da.addOnDraw((Scoped!Context cr, Widget w)
        {
            ctx.cr = cr;
            plot.draw(ctx, Point(w.getAllocatedWidth(),
                                 w.getAllocatedHeight()));
            return false;
        });

        idle = new Idle({
            if (!interactive) return true;
            plot.updateCharts();
            da.queueDraw();
            return true;
        }, true);
    }

    abstract void setupPlot();
}

class Ex1 : ChartWH
{
    this() { super(); }

    override void setupPlot()
    {
        version (with_line)
        {
            plot.charts ~= new LineChart(Color(1,0,0,1),
            (ref Appender!(Point[]) buf) {
                auto line = iota(0, 1.02, 0.02)
                        .map!(i=>Point(i, 3 * sin(i*PI*2 + ct())));
                buf.put(line);
            });

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
            auto sf(float i) { return sin(i*sin(i+ct()*0.5)*PI*2); }
            auto up(float i) { return 0.4 + sin(i*PI*2+ct*3) * 0.3; }
            auto down(float i) { return -0.4 - sin(i*PI*3+ct*5) * 0.3; }
            auto tre = iota(-2, 2.02, 0.02)
                .map!(i=>TreStat(i, sf(i) + up(i), sf(i), sf(i) + down(i)));

            plot.add(new TreChart(
                Color(0,0.5,0,0.8),

                Color(1,1,0,.3),
                Color(1,1,0,.2),

                Color(0,1,1,.3),
                Color(0,1,1,.2),
                (ref Appender!(TreStat[]) buf) { buf.put(tre.save); }
            ));
        }
    }
}

class Ex2 : ChartWH
{
    this() { super(); }

    override void setupPlot()
    {
        enum N = 300;
        enum step = 0.001;

        auto data = iota(0, 3.14*2, step)
            .map!(i=>Point(i, sin(i) + uu(2+sin(i*3.14))));

        plot.add(new BoxChart(
            Color(.8,.8,.8,.8),
            Color(1,1,0,.3),
            Color(0,1,1,.3),
            (ref Appender!(BoxStat[]) buf)
            {
                foreach (c; data.chunks(N))
                {
                    auto tm = c.front.x;
                    buf.put(BoxStat.Set(tm, step*N, c.map!"a.y"));
                }
            }
        ));
    }
}

void main(string[] args)
{
    Main.init(args);

    auto win = new Window("example");
    auto box = new Box(GtkOrientation.VERTICAL, 6);

    auto ex1 = new Ex1;
    auto ex2 = new Ex2;
    ex2.interactive = false;

    box.packStart(ex1.da, true, true, 0);
    box.packStart(ex2.da, true, true, 0);

    win.add(box);
    win.setDefaultSize(800, 800);
    win.showAll();

    win.addOnHide((w){ Main.quit(); });
    Main.run();
}
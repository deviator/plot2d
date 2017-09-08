module plot2d.chart.line;

import plot2d.chart.base;

///
class LineChart : BaseChart!Point
{
protected:
    override void expandViewport(size_t i, ref const Point val)
    {
        if (i == 0) vp = Viewport.initial(val);
        else vp.expand(val);
    }

public:
    ///
    Color stroke;
    ///
    double[] dash = [];
    ///
    double dashOffset = 0;

    ///
    this(Color stroke, void delegate(ref Appender!(Point[])) fd)
    {
        this.stroke = stroke;
        super(fd);
    }

    override void draw(Ctx cr, Trtor tr, Style style)
    {
        if (buffer.data.length == 0) return;

        cr.setLineWidth(style.number.get("linewidth", 2));    
        cr.setDash(dash, dashOffset);
        cr.setColor(stroke);
        
        cr.clipViewport(tr.inPadding);

        cr.moveToP(tr.toDA(buffer.data.front));
        foreach (val; buffer.data[1..$])
            cr.lineToP(tr.toDA(val));

        cr.stroke();
    }
}
module plot2d.chart.box;

public import plot2d.chart.base;

class BoxChart : BaseChart!BoxStat
{
protected:
    override void expandViewport(size_t i, ref const Elem val)
    {
        if (i == 0)
            vp = Viewport.initial(Point(val.tm - val.dtm/2, val.min));
        else
        {
            vp.expand(Point(val.tm - val.dtm/2, val.min));
            vp.expand(Point(val.tm + val.dtm/2, val.max));
        }
    }

public:
    float boxWidth = 0.8;
    bool strokeBox = false;
    Color fillUp, fillDown, stroke;

    this(Color stroke, Color fillUp,
         Color fillDown, BufferFiller fd)
    {
        this.stroke = stroke;
        this.fillUp = fillUp;
        this.fillDown = fillDown;
        super(fd);
    }

    override void draw(Ctx cr, Trtor tr)
    {
        auto linewidth = style.number.get("linewidth", 1.0);
        cr.setLineWidth(linewidth);

        if (buffer.data.length == 0) return;

        cr.clipViewport(tr.inPadding);


        foreach (val; buffer.data)
        {
            auto bw = Point(val.dtm/2 * boxWidth, 0);

            cr.setColor(fillUp);
            cr.lineP2P(
                tr.toDA(val.q1Pnt  - bw),
                tr.toDA(val.q1Pnt  + bw),
                tr.toDA(val.medPnt + bw),
                tr.toDA(val.medPnt - bw),
            );
            cr.fill();

            cr.setColor(fillDown);
            cr.lineP2P(
                tr.toDA(val.medPnt - bw),
                tr.toDA(val.medPnt + bw),
                tr.toDA(val.q3Pnt  + bw),
                tr.toDA(val.q3Pnt  - bw),
            );
            cr.fill();

            cr.setColor(stroke);
            if (strokeBox)
            {
                cr.lineP2P(
                    tr.toDA(val.q3Pnt - bw),
                    tr.toDA(val.q1Pnt - bw),
                    tr.toDA(val.q1Pnt + bw),
                    tr.toDA(val.q3Pnt + bw),
                    tr.toDA(val.q3Pnt - bw),
                );
            }
            cr.lineP2P(
                tr.toDA(val.medPnt - bw),
                tr.toDA(val.medPnt + bw),
            );
            cr.lineP2P(
                tr.toDA(val.q1Pnt),
                tr.toDA(val.minPnt)
            );
            cr.lineP2P(
                tr.toDA(val.q3Pnt),
                tr.toDA(val.maxPnt)
            );
            cr.stroke();
        }
    }
}
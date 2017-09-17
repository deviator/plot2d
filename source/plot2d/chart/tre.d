module plot2d.chart.tre;

public import plot2d.chart.base;

///
class TreChart : BaseChart!TreStat
{
protected:
    override void expandViewport(ref const Elem val, ref bool inited)
    {
        if (val.tm == val.tm)
        {
            import plot2d.util;
            vp.w.min.set!min(val.tm);
            vp.w.max.set!max(val.tm);
        }
        if (!val.check) return;
        if (!inited)
        {
            vp.h.min = val.min;
            vp.h.max = val.max;
            inited = true;
        }
        else
        {
            vp.expand(val.minPnt);
            vp.expand(val.maxPnt);
            vp.expand(val.valPnt);
        }
    }

public:

    Color fillUp, fillDown, stroke, strokeLimUp, strokeLimDown;

    bool skipNaN = true;
    double disaster;
    double disasterCoef = 3; // must be > 1

    this(Color stroke,
         Color strokeLimUp, Color fillUp,
         Color strokeLimDown, Color fillDown,
         BufferFiller fd)
    {
        this.stroke = stroke;
        this.fillUp = fillUp;
        this.fillDown = fillDown;
        this.strokeLimUp = strokeLimUp;
        this.strokeLimDown = strokeLimDown;
        super(fd);
    }

    override
    {
        void update()
        {
            super.update();
            if (buffer.data.length == 0) return;

            auto avg_diff = 0.0;
            foreach (a, b; lockstep(buffer.data[0..$-1], buffer.data[1..$]))
                avg_diff += b.tm - a.tm;
            avg_diff /= buffer.data.length;
            disaster = avg_diff * disasterCoef;
        }

        void draw(Ctx cr, Trtor tr)
        {
            auto limlinewidth = style.number.get("limlinewidth", 1);
            auto linewidth = style.number.get("linewidth", 2);

            bool fnc(Elem e)
            {
                if (skipNaN) return e.check;
                else return true;
            }

            auto buf = buffer.data.filter!fnc;

            if (buf.empty) return;

            cr.clipViewport(tr.inPadding);

            auto lst = buf.front;
            buf.popFront;

            foreach (val; buf)
            {
                if (!skipNaN && !(val.check && lst.check))
                {
                    lst = val;
                    continue;
                }
                //if (val.tm - lst.tm > disaster)
                //{ lst = val; continue; }

                cr.setColor(fillUp);
                cr.lineP2P(tr.toDA(lst.maxPnt),
                           tr.toDA(lst.valPnt),
                           tr.toDA(val.maxPnt));
                cr.fill();
                cr.lineP2P(tr.toDA(lst.valPnt),
                           tr.toDA(val.maxPnt),
                           tr.toDA(val.valPnt));
                cr.fill();

                cr.setColor(fillDown);
                cr.lineP2P(tr.toDA(lst.valPnt),
                           tr.toDA(lst.minPnt),
                           tr.toDA(val.valPnt));
                cr.fill();
                cr.lineP2P(tr.toDA(lst.minPnt),
                           tr.toDA(val.valPnt),
                           tr.toDA(val.minPnt));
                cr.fill();

                cr.setLineWidth(limlinewidth);

                cr.setColor(strokeLimUp);
                cr.lineP2P(tr.toDA(lst.maxPnt), tr.toDA(val.maxPnt));
                cr.stroke();

                cr.setColor(strokeLimDown);
                cr.lineP2P(tr.toDA(lst.minPnt), tr.toDA(val.minPnt));
                cr.stroke();

                cr.setLineWidth(linewidth);    
                cr.setColor(stroke);
                cr.lineP2P(tr.toDA(lst.valPnt), tr.toDA(val.valPnt));
                cr.stroke();

                lst = val;
            }
        }
    }
}
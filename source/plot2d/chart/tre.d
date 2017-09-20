module plot2d.chart.tre;

public import plot2d.chart.base;

///
class TreChart : BaseChart!TreStat
{
protected:
    override void expandViewport(ref const Elem val, ref bool[2] inited)
    {
        if (val.tm == val.tm)
        {
            if (inited[0])
            {
                vp.w.min.set!min(val.tm);
                vp.w.max.set!max(val.tm);
            }
            else
            {
                vp.w.min = val.tm;
                vp.w.max = val.tm;
                inited[0] = true;
            }
        }
        if (val.min == val.min && val.max == val.max)
        {
            if (inited[1])
            {
                vp.h.min.set!min(val.min);
                vp.h.max.set!max(val.max);
            }
            else
            {
                vp.h.min = val.min;
                vp.h.max = val.max;
                inited[1] = true;
            }
        }
    }

public:

    Color fillUp, fillDown, stroke, strokeLimUp, strokeLimDown;

    bool skipNaN = true;
    bool verticalCap = true;

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

            auto buf = buffer.data.filter!(a=>skipNaN?a.check:true);

            if (buf.empty) return;

            cr.clipViewport(tr.inPadding);

            auto lst = buf.front;
            buf.popFront;

            void vcap(typeof(lst) p)
            {
                cr.setLineWidth(limlinewidth);
                cr.setColor(strokeLimUp);
                cr.lineP2P(tr.toDA(p.valPnt), tr.toDA(p.maxPnt));
                cr.stroke();

                cr.setColor(strokeLimDown);
                cr.lineP2P(tr.toDA(p.valPnt), tr.toDA(p.minPnt));
                cr.stroke();

                cr.setLineWidth(linewidth);    
                cr.setColor(stroke);
                cr.lineP2P(tr.toDA(p.valPnt)-Point(1,0),
                           tr.toDA(p.valPnt)+Point(1,0));
                cr.stroke();
            }

            foreach (val; buf)
            {
                if (verticalCap)
                {
                    if (!lst.check && val.check) vcap(val);
                    else
                    if (lst.check && !val.check) vcap(lst);
                }

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
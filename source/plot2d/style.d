/// Plot style handler
module plot2d.style;

import plot2d.types;

///
interface ValueHandler(Key, Value)
{
    ///
    Value opIndex(Key);
    ///
    void opIndexAssign(Key, Value);
    ///
    Value get(Key, lazy Value);
    ///
    void set(Key, Value);
}

///
interface Style
{
    ///
    alias SVH(T) = ValueHandler!(string, T);
    ///
    Style getSubstyle(string name);

    @property
    {
        ///
        SVH!double number();
        ///
        SVH!Color  color();
        ///
        SVH!string strval();
    }
}

///
class PlainStyle : Style
{
protected:
    ///
    Style parent;

    ///
    string trName(string parameter)
    { return parameter; }

    class SVHP(Value, string fld) : SVH!Value
    {
        Value defaultValue;
        Value[string] data;

        this(Value dv) { defaultValue = dv; }

    override:
        ///
        Value opIndex(string p)
        {
            if (this.outer.parent !is null)
                mixin("return this.outer.parent."
                        ~fld~".opIndex(trName(p));");
            else return data.get(p, defaultValue);
        }
        ///
        void opIndexAssign(string p, Value val)
        {
            if (this.outer.parent !is null)
                mixin("this.outer.parent."~fld~
                        ".opIndexAssign(trName(p), val);");
            else data[p] = val;
        }
        ///
        Value get(string p, lazy Value val)
        {
            if (this.outer.parent !is null)
                mixin("return this.outer.parent."
                        ~fld~".get(trName(p), val);");
            else return data.get(p, val);
        }
        ///
        void set(string p, Value val)
        {
            if (this.outer.parent !is null)
                mixin("this.outer.parent."
                        ~fld~".set(trName(p), val);");
            else data[p] = val;
        }
    }

    SVH!double _number;
    SVH!Color _color;
    SVH!string _strval;

public:

    ///
    this(Style p)
    {
        parent = p;
        _number = new SVHP!(double, "number")(0.0);
        _color = new SVHP!(Color, "color")(Color.init);
        _strval = new SVHP!(string, "strval")("");
    }

    override
    {
        ///
        Style getSubstyle(string name)
        { return new PlainStyle(this); }

        @property
        {
            SVH!double number() { return _number; }
            SVH!Color color() { return _color; }
            SVH!string strval() { return _strval; }
        }
    }
}

///
class NSStyle : PlainStyle
{
protected:
    /// namespace
    string ns;

    ///
    override string trName(string p)
    {
        if (p[0] == '.')
        {
            if (parent !is null) return p;
            else return p[1..$];
        }
        else return ns ~ "." ~ p;
    }

public:

    ///
    this() { super(null); }

    ///
    this(NSStyle p, string n)
    {
        super(p);
        ns = n;
    }

    ///
    override Style getSubstyle(string name)
    { return new NSStyle(this, name); }
}

/+ TODO parser
`
gridlabel:
    fontsize: 15
    fontface: Monospace
    color: rgba(0,0,0,.8)

axis:
    linewidth: 1.5
    color: rgba(0,0,0,.7)

grid:
    linewidth: 1
    color: rgba(0,0,0,.2)

chart:
    linewidth: 2

trechart > chart:
    limlinewidth: 1
    limlinealpha: 0.4
    limfillalpha: 0.3
`
+/
module render.box;

import std.math;

import render.shapes;
import sparse;


/// Describes a unicode box-drawing symbol
class BoxSymbol {
    enum LineWidth : ubyte {
        NULL = 0,
        NONE,
        LIGHT,         // ┌──┬──╴ ~ light
        HEAVY,         // ┏━━╈━━╸ ~ heavy
        DOUBLE,        // ╔══╩══╸ ~ double
        LIGHT_ROUNDED, // ╭──┬──╴ ~ light, but with rounded corners
        LIGHT_DOUBLE_DASH,    // ╌ ╌ ╌
        HEAVY_DOUBLE_DASH,    // ╍ ╍ ╍
        LIGHT_TRIPLE_DASH,    // ┄ ┄ ┄
        HEAVY_TRIPLE_DASH,    // ┅ ┅ ┅
        LIGHT_QUADRUPLE_DASH, // ┈ ┈ ┈
        HEAVY_QUADRUPLE_DASH, // ┉ ┉ ┉
    }

    /// Stores descriptive information about the displayed symbol
    union Edges {
        struct Widths {
            LineWidth top;
            LineWidth bottom;
            LineWidth left;
            LineWidth right;
        }

        uint _uint;
        ubyte[4] _ubyte4;
        Widths _widths;
    } // I got a little carried away with this union :p

    unittest {
        Edges e1;
        e1._widths.left = LineWidth.HEAVY;
        Edges e2;
        e2._uint = e1._uint;
        assert(e2._widths.left == e1._widths.left);
        assert(e2._ubyte4 == e1._ubyte4);

        Edges edges;
        edges._widths = Edges.Widths(LineWidth.LIGHT, LineWidth.LIGHT, LineWidth.NONE, LineWidth.NONE);
        assert(BoxSymbol.byEdges[edges].symbol == '│');
    }

    dchar symbol;
    Edges edges;

    /// Private constructor, static instanciation only
    private this(dchar symbol, LineWidth top, LineWidth bottom, LineWidth left, LineWidth right) {
        this.symbol = symbol;
        this.edges._widths = Edges.Widths(top, bottom, left, right);
    }

    /// Special none-type symbol used in the drawing algorithm
    static BoxSymbol none;

    /// All supported symbols as a immutable list
    static BoxSymbol[] list;

    /// Efficient lookup (hash) table using edges as keys
    static BoxSymbol[Edges] byEdges;

    /// Returns the unicode symbol that matches the edges, will fallbacks
    static dchar getSymbolByEdges(Edges edges) {
        if (edges in byEdges) {
            return byEdges[edges].symbol;
        } else {
            // try for fallback, some combinations of double do not exist
            // replace doubles with thick and try again:
            auto fallback = (LineWidth search, LineWidth replace) {
                auto inplace = (ref LineWidth width) {
                    width = (width == search) ? replace : width;
                };
                // replace all edges by this rule:
                inplace(edges._widths.top);
                inplace(edges._widths.bottom);
                inplace(edges._widths.left);
                inplace(edges._widths.right);
            };
            fallback(LineWidth.DOUBLE, LineWidth.HEAVY);
            fallback(LineWidth.LIGHT_ROUNDED, LineWidth.LIGHT);
            fallback(LineWidth.LIGHT_DOUBLE_DASH, LineWidth.LIGHT);
            fallback(LineWidth.HEAVY_DOUBLE_DASH, LineWidth.HEAVY);
            fallback(LineWidth.LIGHT_TRIPLE_DASH, LineWidth.LIGHT);
            fallback(LineWidth.LIGHT_QUADRUPLE_DASH, LineWidth.LIGHT);
            fallback(LineWidth.HEAVY_TRIPLE_DASH, LineWidth.HEAVY);
            fallback(LineWidth.HEAVY_QUADRUPLE_DASH, LineWidth.HEAVY);

            // then try again:
            if (edges in byEdges) {
                return byEdges[edges].symbol;
            }
        }
        return 0;
    }

    static this() {
        alias LineWidth.NONE NONE;
        alias LineWidth.LIGHT LIGHT;
        alias LineWidth.HEAVY HEAVY;
        alias LineWidth.DOUBLE DOUBLE;
        alias LineWidth.LIGHT_ROUNDED LIGHT_ROUNDED;
        alias LineWidth.LIGHT_TRIPLE_DASH LIGHT_TRIPLE_DASH;
        alias LineWidth.LIGHT_QUADRUPLE_DASH LIGHT_QUADRUPLE_DASH;
        alias LineWidth.HEAVY_TRIPLE_DASH HEAVY_TRIPLE_DASH;
        alias LineWidth.HEAVY_QUADRUPLE_DASH HEAVY_QUADRUPLE_DASH;
        alias LineWidth.LIGHT_DOUBLE_DASH LIGHT_DOUBLE_DASH;
        alias LineWidth.HEAVY_DOUBLE_DASH HEAVY_DOUBLE_DASH;

        // Character Reference:
        // http://www.utf8-chartable.de/unicode-utf8-table.pl?start=9472&number=128

        none = new BoxSymbol('¤', NONE, NONE, NONE, NONE);
        list = [ // this needs to be aligned!!!! OMG :(

            none,
            //                  TOP     BOTTOM   LEFT     RIGHT

            new BoxSymbol('╴',   NONE,   NONE,   LIGHT,   NONE  ),
            new BoxSymbol('╶',   NONE,   NONE,   NONE,   LIGHT  ),
            new BoxSymbol('╵', LIGHT,   NONE,   NONE,   NONE  ),
            new BoxSymbol('╷',   NONE,   LIGHT,   NONE,   NONE  ),
            new BoxSymbol('╸',   NONE,   NONE,   HEAVY, NONE  ),
            new BoxSymbol('╺',   NONE,   NONE,   NONE,   HEAVY),   
            new BoxSymbol('╹', HEAVY, NONE,   NONE,   NONE  ),
            new BoxSymbol('╻',   NONE,   HEAVY, NONE,   NONE  ),

            new BoxSymbol('│',  LIGHT,   LIGHT,   NONE,   NONE  ),
            new BoxSymbol('╿', HEAVY, LIGHT,   NONE,   NONE  ),
            new BoxSymbol('╽', LIGHT,   HEAVY, NONE,   NONE  ),
            new BoxSymbol('║', DOUBLE, DOUBLE, NONE,   NONE  ),
            new BoxSymbol('┃', HEAVY, HEAVY, NONE,   NONE  ),

            new BoxSymbol('─',   NONE,   NONE,   LIGHT,   LIGHT  ),
            new BoxSymbol('━', NONE,   NONE,   HEAVY, HEAVY),
            new BoxSymbol('═', NONE, NONE, DOUBLE,   DOUBLE  ),
            new BoxSymbol('╼', NONE,   NONE,   LIGHT,   HEAVY),
            new BoxSymbol('╾', NONE,   NONE,   HEAVY, LIGHT  ),


            new BoxSymbol('┌', NONE,   LIGHT,   NONE,   LIGHT  ),
            new BoxSymbol('┏', NONE,   HEAVY, NONE,   HEAVY),
            new BoxSymbol('╔', NONE,   DOUBLE, NONE,   DOUBLE),
            new BoxSymbol('┍', NONE,   LIGHT,   NONE,   HEAVY),
            new BoxSymbol('┎', NONE,   HEAVY, NONE,   LIGHT  ),
            new BoxSymbol('╒', NONE,   LIGHT,   NONE,   DOUBLE),
            new BoxSymbol('╓', NONE,   DOUBLE, NONE,   LIGHT  ),

            new BoxSymbol('╕', NONE,   LIGHT,   DOUBLE, NONE  ),
            new BoxSymbol('╖', NONE,   DOUBLE, LIGHT,   NONE  ),
            new BoxSymbol('┑', NONE,   LIGHT,   HEAVY, NONE  ),
            new BoxSymbol('┒', NONE,   HEAVY, LIGHT,   NONE  ),
            new BoxSymbol('┐', NONE,   LIGHT,   LIGHT,   NONE  ),
            new BoxSymbol('┓', NONE,   HEAVY, HEAVY, NONE  ),
            new BoxSymbol('╗', NONE,   DOUBLE, DOUBLE, NONE  ),

            new BoxSymbol('└', LIGHT,   NONE,   NONE,   LIGHT  ),
            new BoxSymbol('╚', DOUBLE, NONE,   NONE,   DOUBLE),
            new BoxSymbol('┗', HEAVY, NONE,   NONE,   HEAVY),
            new BoxSymbol('╘', LIGHT,   NONE,   NONE,   DOUBLE),
            new BoxSymbol('╙', DOUBLE, NONE,   NONE,   LIGHT  ),
            new BoxSymbol('┕', LIGHT,   NONE,   NONE,   HEAVY),
            new BoxSymbol('┖', HEAVY, NONE,   NONE,   LIGHT  ),

            new BoxSymbol('╛', LIGHT,   NONE,   DOUBLE, NONE  ),
            new BoxSymbol('╜', DOUBLE, NONE,   LIGHT,   NONE  ),
            new BoxSymbol('┙', LIGHT,   NONE,   HEAVY, NONE  ),
            new BoxSymbol('┚', HEAVY, NONE,   LIGHT,   NONE  ),
            new BoxSymbol('┘', LIGHT,   NONE,   LIGHT,   NONE  ),
            new BoxSymbol('┛', HEAVY, NONE,   HEAVY, NONE  ),
            new BoxSymbol('╝', DOUBLE, NONE,   DOUBLE, NONE  ),

            new BoxSymbol('├', LIGHT,   LIGHT,   NONE,   LIGHT  ),
            new BoxSymbol('┝', LIGHT,   LIGHT,   NONE,   HEAVY),
            new BoxSymbol('┞', HEAVY, LIGHT,   NONE,   LIGHT  ),
            new BoxSymbol('┟', LIGHT,   HEAVY, NONE,   LIGHT  ),
            new BoxSymbol('┠', HEAVY, HEAVY, NONE,   LIGHT  ),
            new BoxSymbol('┡', HEAVY, LIGHT,   NONE,   HEAVY),
            new BoxSymbol('┢', LIGHT,   HEAVY, NONE,   HEAVY),
            new BoxSymbol('┣', HEAVY, HEAVY, NONE,   HEAVY),
            new BoxSymbol('╞', LIGHT,   LIGHT,   NONE,   DOUBLE),
            new BoxSymbol('╟', DOUBLE, DOUBLE, NONE,   LIGHT  ),
            new BoxSymbol('╠', DOUBLE, DOUBLE, NONE,   DOUBLE),

            new BoxSymbol('┤', LIGHT,   LIGHT,   LIGHT,   NONE  ),
            new BoxSymbol('┥', LIGHT,   LIGHT,   HEAVY, NONE  ),
            new BoxSymbol('┦', HEAVY, LIGHT,   LIGHT,   NONE  ),
            new BoxSymbol('┧', LIGHT,   HEAVY, LIGHT,   NONE  ),
            new BoxSymbol('┨', HEAVY, HEAVY, LIGHT,   NONE  ),
            new BoxSymbol('┩', HEAVY, LIGHT,   HEAVY, NONE  ),
            new BoxSymbol('┪', LIGHT,   HEAVY, HEAVY, NONE  ),
            new BoxSymbol('┫', HEAVY, HEAVY, HEAVY, NONE  ),
            new BoxSymbol('╡', LIGHT,   LIGHT,   DOUBLE, NONE  ),
            new BoxSymbol('╢', DOUBLE, DOUBLE, LIGHT,   NONE  ),
            new BoxSymbol('╣', DOUBLE, DOUBLE, DOUBLE, NONE  ),

            new BoxSymbol('┬', NONE,   LIGHT,   LIGHT,   LIGHT  ),
            new BoxSymbol('┭', NONE,   LIGHT,   HEAVY, LIGHT  ),
            new BoxSymbol('┮', NONE,   LIGHT,   LIGHT,   HEAVY),
            new BoxSymbol('┯', NONE,   LIGHT,   HEAVY, HEAVY),
            new BoxSymbol('┰', NONE,   HEAVY, LIGHT,   LIGHT  ),
            new BoxSymbol('┱', NONE,   HEAVY, HEAVY, LIGHT  ),
            new BoxSymbol('┲', NONE,   HEAVY, LIGHT,   HEAVY),
            new BoxSymbol('┳', NONE,   HEAVY, HEAVY, HEAVY),
            new BoxSymbol('╤', NONE,   LIGHT,   DOUBLE, DOUBLE),
            new BoxSymbol('╥', NONE,   DOUBLE, LIGHT,   LIGHT  ),
            new BoxSymbol('╦', NONE,   DOUBLE, DOUBLE, DOUBLE),

            new BoxSymbol('┴', LIGHT,   NONE,   LIGHT,   LIGHT  ),
            new BoxSymbol('┵', LIGHT,   NONE,   HEAVY, LIGHT  ),
            new BoxSymbol('┶', LIGHT,   NONE,   LIGHT,   HEAVY),
            new BoxSymbol('┷', LIGHT,   NONE,   HEAVY, HEAVY),
            new BoxSymbol('┸', HEAVY, NONE,   LIGHT,   LIGHT  ),
            new BoxSymbol('┹', HEAVY, NONE,   HEAVY, LIGHT  ),
            new BoxSymbol('┺', HEAVY, NONE,   LIGHT,   HEAVY),
            new BoxSymbol('┻', HEAVY, NONE,   HEAVY, HEAVY),
            new BoxSymbol('╧', LIGHT,   NONE,   DOUBLE, DOUBLE),
            new BoxSymbol('╨', DOUBLE, NONE,   LIGHT,   LIGHT  ),
            new BoxSymbol('╩', DOUBLE, NONE,   DOUBLE, DOUBLE),

            new BoxSymbol('┼', LIGHT,   LIGHT,   LIGHT,   LIGHT  ),
            new BoxSymbol('┽', LIGHT,   LIGHT,   HEAVY, LIGHT  ),
            new BoxSymbol('┾', LIGHT,   LIGHT,   LIGHT,   HEAVY),
            new BoxSymbol('┿', LIGHT,   LIGHT,   HEAVY, HEAVY),
            new BoxSymbol('╀', HEAVY, LIGHT,   LIGHT,   LIGHT  ),
            new BoxSymbol('╁', LIGHT,   HEAVY, LIGHT,   LIGHT  ),
            new BoxSymbol('╂', HEAVY, HEAVY, LIGHT,   LIGHT  ),
            new BoxSymbol('╃', HEAVY, LIGHT,   HEAVY, LIGHT  ),
            new BoxSymbol('╄', HEAVY, LIGHT,   LIGHT,   HEAVY),
            new BoxSymbol('╅', LIGHT,   HEAVY, HEAVY, LIGHT  ),
            new BoxSymbol('╆', LIGHT,   HEAVY, LIGHT,   HEAVY),
            new BoxSymbol('╇', HEAVY, LIGHT,   HEAVY, HEAVY),
            new BoxSymbol('╈', LIGHT,   HEAVY, HEAVY, HEAVY),
            new BoxSymbol('╉', HEAVY, HEAVY, HEAVY, LIGHT  ),
            new BoxSymbol('╊', HEAVY, HEAVY, LIGHT,   HEAVY),
            new BoxSymbol('╋', HEAVY, HEAVY, HEAVY, HEAVY),
            new BoxSymbol('╪', LIGHT,   LIGHT,   DOUBLE, DOUBLE),
            new BoxSymbol('╫', DOUBLE, DOUBLE, LIGHT,   LIGHT  ),
            new BoxSymbol('╬', DOUBLE, DOUBLE, DOUBLE, DOUBLE),

            new BoxSymbol('╮', NONE,   LIGHT_ROUNDED,   LIGHT_ROUNDED,   NONE  ), 
            new BoxSymbol('╭', NONE,   LIGHT_ROUNDED,   NONE,   LIGHT_ROUNDED  ), 
            new BoxSymbol('╯', LIGHT_ROUNDED,   NONE,   LIGHT_ROUNDED,   NONE  ), 
            new BoxSymbol('╰', LIGHT_ROUNDED,   NONE,   NONE,   LIGHT_ROUNDED  ), 

            new BoxSymbol('╌', NONE, NONE, LIGHT_DOUBLE_DASH, LIGHT_DOUBLE_DASH),
            new BoxSymbol('╎', LIGHT_DOUBLE_DASH, LIGHT_DOUBLE_DASH, NONE, NONE),
            new BoxSymbol('╍', NONE, NONE, HEAVY_DOUBLE_DASH, HEAVY_DOUBLE_DASH),
            new BoxSymbol('╏', HEAVY_DOUBLE_DASH, HEAVY_DOUBLE_DASH, NONE, NONE),

            new BoxSymbol('┄', NONE, NONE, LIGHT_TRIPLE_DASH, LIGHT_TRIPLE_DASH ),  
            new BoxSymbol('┆', LIGHT_TRIPLE_DASH, LIGHT_TRIPLE_DASH, NONE, NONE ),  
            new BoxSymbol('┅', NONE, NONE, HEAVY_TRIPLE_DASH, HEAVY_TRIPLE_DASH ),  
            new BoxSymbol('┇', HEAVY_TRIPLE_DASH, HEAVY_TRIPLE_DASH, NONE, NONE ),  

            new BoxSymbol('┈', NONE, NONE, LIGHT_QUADRUPLE_DASH, LIGHT_QUADRUPLE_DASH ),  
            new BoxSymbol('┊', LIGHT_QUADRUPLE_DASH, LIGHT_QUADRUPLE_DASH, NONE, NONE ),  
            new BoxSymbol('┉', NONE, NONE, HEAVY_QUADRUPLE_DASH, HEAVY_QUADRUPLE_DASH ),  
            new BoxSymbol('┋', HEAVY_QUADRUPLE_DASH, HEAVY_QUADRUPLE_DASH, NONE, NONE ),  

        ];

        foreach (symbol; list) {
            if (symbol.edges in byEdges) {
                throw new Exception("Box-drawing symbol duplicate list entry!");
            }
            byEdges[symbol.edges] = symbol;
        }
    }
}

/// Drawing engine for lines and rects, note that the canvas is infinitely sized
class BoxCanvas {

    // alias SparseArray!(BoxSymbol.Edges, 1024) SparseSurfaceArray;
    alias SparseArray!(BoxSymbol.Edges) SparseSurfaceArray;

    SparseSurfaceArray surface;

    this() {
        surface = new SparseSurfaceArray;
    }

    void clear() {
        surface.clear();
    }

    void addLine(int x0, int y0, int x1, int y1, BoxSymbol.LineWidth lineWidth) {

        // the line can be horizontal or vertical to determine this:
        bool horizontal = (y0 == y1);
        bool vertical = (x0 == x1);

        if (vertical && horizontal || !vertical && !horizontal) {
            throw new Exception("Invalid line plotting 90deg only!");
        }

        auto none = BoxSymbol.LineWidth.NONE;

        Line(x0, y0, x1, y1, (int x, int y) {

                // Do this for each point on the line at (x, y) ...

                auto current = surface[x, y];
                if (!current._uint) {

                // If its an empty spot, mark it using the none symbol
                current = BoxSymbol.none.edges; //none;

                }

                // Modify the adjecent symbols to connect with current

                auto top = &surface[x, y-1], bottom = &surface[x, y+1], 
                left = &surface[x-1, y], right = &surface[x+1, y];

                if (horizontal) {
                    if (left._widths.right == none)  {
                        left._widths.right = lineWidth;
                        current._widths.left = lineWidth;
                    }
                    if (right._widths.left == none) {
                        right._widths.left = lineWidth;
                        current._widths.right = lineWidth;
                    }
                }
                if (vertical) {
                    if (top._widths.bottom == none) {
                        top._widths.bottom = lineWidth;
                        current._widths.top = lineWidth;
                    }
                    if (bottom._widths.top == none) {
                        bottom._widths.top = lineWidth;
                        current._widths.bottom = lineWidth;
                    }
                }

                surface[x, y] = current;
        });
    }

    void addRect(int x, int y, int width, int height, BoxSymbol.LineWidth lineWidth) {
        addLine(x, y, x + width - 1, y, lineWidth);
        addLine(x, y, x, y + height - 1, lineWidth);
        addLine(x + width - 1, y, x + width - 1, y + height - 1, lineWidth);
        addLine(x, y + height - 1, x + width - 1, y + height - 1, lineWidth);
    }

    /// calls the putchar function for each character in the specified area of the canvas
    void plot(int x, int y, int width, int height, void delegate (int x, int y, dchar symbol) putchar) {
        for (int iy = x; iy < height; iy++) {
            for (int ix = y; ix < width; ix++) {
                auto symbol = BoxSymbol.getSymbolByEdges(surface[ix, iy]);
                if (symbol) putchar(ix, iy, symbol);
            }
        }
    }

    /// override with 0,0 as origin
    void plot(int width, int height, void delegate (int x, int y, dchar symbol) putchar) {
        plot(0, 0, width, height, putchar);
    }

}

unittest {
    import std.conv, std.stdio;
    auto canvas = new BoxCanvas;
    // only 90 degree lines are allowed
    try {
        canvas.addLine(0, 0, 3, 3, BoxSymbol.LineWidth.LIGHT);
        assert(false); // <- runtime error, should never get reached
    } catch (Exception e) {
    }

    canvas.addLine(0, 0, 3, 0, BoxSymbol.LineWidth.LIGHT);
    auto assertPlotting = delegate (string expect) {
        auto line = "";
        canvas.plot(10,10,(int x, int y, dchar symbol) {
                line ~= to!string(symbol);
                });
        assert(line == expect, "Line was: '" ~ line ~ "' Expected: '" ~ expect ~ "'");
    };
    assertPlotting("╶──╴");

    canvas.clear();
    assertPlotting("");

    canvas.addLine(0, 0, 3, 0, BoxSymbol.LineWidth.LIGHT);
    canvas.addLine(4, 0, 6, 0, BoxSymbol.LineWidth.HEAVY);
    assertPlotting("╶──╼━━╸");

    canvas.clear();

    // test fallback for heavy
    canvas.addLine(0, 0, 3, 0, BoxSymbol.LineWidth.DOUBLE);
    canvas.addLine(4, 0, 6, 0, BoxSymbol.LineWidth.HEAVY);
    assertPlotting("╺══━━━╸");

    canvas.clear();

    // rect drawing:
    canvas.addRect(0, 0, 4, 4, BoxSymbol.LineWidth.LIGHT_ROUNDED);
    assertPlotting("╭──╮││││╰──╯");
}


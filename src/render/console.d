module render.console;

import std.typetuple;
import std.algorithm;
import std.container;
import std.conv;
import std.c.locale;
import std.string;
import std.stdio;
import std.datetime;
import deimos.ncurses;

class Keyboard {

    class Handler {
        /// Different keycodes including escape sequences to trigger the handler
        string[] keycodes;

        /// Gets called when the handler triggers
        void delegate() callback;

        /// Remove itself, stops propagation of this event handler.
        void cancel() {
            handlers = handlers.remove(countUntil(handlers, this));
        }
    }

    private Handler[] handlers;
    
    /// String to buffer escape sequences into
    string escBuffer;

    /// Stop watch to measure the esc sequence timeout
    private StopWatch escTimer;

    private int escTimeout = 1000 / 30; // ms for escape 

    enum isString(A) = is(A == string);
    Handler register(A...)(A keycodes, void delegate() f) if (allSatisfy!(isString, A)) {
        auto h = new Handler;
        h.keycodes = [keycodes];
        h.callback = f;
        handlers ~= h;
        return h;
    }

    /// Polls for keyboard input, assumes getch in non-blocking mode
    void poll() {
        if (escTimer.running() && escTimer.peek().msecs > escTimeout) {
            escTimer.stop();
            keypress(escBuffer);
            escBuffer = "";
        } else if (escBuffer != "^[") { // bypass timeout, try to delegate as soon as possible
            if (keypress(escBuffer)) {
                escTimer.stop();
                escBuffer = "";
            }
        }

        int key = getch();
        if (key == 27) { // ESCAPE
            escTimer.reset();
            escTimer.start();
            escBuffer = "^[";
        } else if (key != -1) {
            if (escTimer.running()) {
                escBuffer ~= to!string(cast(dchar) key);
            } else {
                keypress(to!string(cast(dchar) key));
            }
        }
    }

    bool keypress(string keycode) {
        foreach (handler; handlers) {
            if (find(handler.keycodes, keycode).length > 0) {
                handler.callback();
                return true;
            }
        }
        return false;
    }

}


interface Printer {
    void print(int x, int y, string text);
    void print(string text);
}


class Console : Printer {
    Keyboard input = new Keyboard;
    int width;
    int height;

    this() {
        setlocale(LC_CTYPE,"");
        initscr();
        cbreak();
        noecho();
        curs_set(0); // hide cursor
        timeout(0);
        //keypad(stdscr, true);
        width = getmaxx(stdscr);
        height = getmaxy(stdscr);
    }

    ~this() {
        endwin();
    } 

    void clear() {
        width = getmaxx(stdscr);
        height = getmaxy(stdscr);
        .clear();
    }

    override void print(int x, int y, string text) {
        wmove(stdscr, y, x);
        print(text);
    }

    override void print(string text) {
        printw(toStringz(text));
    }
}

void PrintRect(Printer w, int x, int y, int width, int height) {
    for (int ix = 1; ix < width; ix++) {
        w.print(x + ix, y, "\u2550"); // top
        w.print(x + ix, y + height, "\u2550"); // bottom
    }
    for (int iy = 1; iy < height; iy++) {
        w.print(x, y + iy, "\u2551"); // left
        w.print(x + width, y + iy, "\u2551"); // right
    }
    // corners
    w.print(x, y, "\u2554");
    w.print(x + width, y, "\u2557");
    w.print(x, y + height, "\u255A");
    w.print(x + width, y + height, "\u255D");




}




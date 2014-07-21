import std.stdio;
import std.conv;
import std.math;
import std.string;
import std.datetime;
import core.thread;
import std.random;

import deimos.ncurses;

import render.console;
import render.box;

void delegate () Demo(Console console) {
    BoxCanvas canvas = new BoxCanvas;
    /*

    int FPS_LIMIT = 60;
    auto FPS_LIMIT_MS = 1000 / FPS_LIMIT;
    int tick = 0;

    double cursorX = console.width / 2;
    double cursorY = console.height / 2;
    console.input.register(KEY_UP, () { cursorY--; });
    console.input.register(KEY_DOWN, () { cursorY++; });
    console.input.register(KEY_LEFT, () { cursorX--; });
    console.input.register(KEY_RIGHT, () { cursorX++; });

    StopWatch sw;
    sw.start();
    */

    enum Direction : ubyte { UP = 0, DOWN, LEFT, RIGHT }
    class Snake {
        int x;
        int y;
        int newX;
        int newY;

        Direction stepDirection; // the step direction
        int stepsLeft; // the steps to go still in the direction
        int stepsLeftInitial; // the steps to go still in the direction

        BoxSymbol.LineWidth lineWidth;

        bool dead;

        this(int x, int y) {
            this.x = x;
            this.y = y;

            // set step parameters in some random direction in a random length
            randomStep();

            // randomize line width:
            switch (uniform(0, 4)) {
                case 0:
                    lineWidth = BoxSymbol.LineWidth.LIGHT;
                    break;
                case 1:
                    lineWidth = BoxSymbol.LineWidth.HEAVY;
                    break;
                case 2:
                    lineWidth = BoxSymbol.LineWidth.DOUBLE;
                    break;
                default:
                    lineWidth = BoxSymbol.LineWidth.DOUBLE;
                    break;
            }

            dead = false;
        }

        void randomStep() {
            switch (uniform(0, 4)) {
                case 0:
                    this.stepDirection = Direction.UP;
                    break;
                case 1:
                    this.stepDirection = Direction.DOWN;
                    break;
                case 2:
                    this.stepDirection = Direction.LEFT;
                    break;
                default:
                    this.stepDirection = Direction.RIGHT;
                    break;
            }
            // random length:
            this.stepsLeft = this.stepsLeftInitial = uniform(3, 12);
        }

        void tick() {
            //stderr.writef("tick! x=%d y=%d stepsLeft=%d", x, y, stepsLeft);
            // draw current step:
            if (stepsLeft > 0) {
                auto l = stepsLeftInitial - stepsLeft;
                if (l >= 1) {
                    final switch (this.stepDirection) {
                        case Direction.UP:
                            newX = x;
                            newY = y - l;
                            break;
                        case Direction.DOWN:
                            newX = x;
                            newY = y + l;
                            break;
                        case Direction.LEFT:
                            newX = x - l;
                            newY = y;
                            break;
                        case Direction.RIGHT:
                            newX = x + l;
                            newY = y;
                            break;
                    }
                    canvas.addLine(x, y, newX, newY, lineWidth);
                }
            }

            // update step
            stepsLeft--;
            if (stepsLeft <= 0) {
                x = newX;
                y = newY;

                if ((x < 0 || x > console.width) || (y < 0 || y > console.height)) {
                    dead = true;
                }

                randomStep();
            }
        }
    }

    Snake[] snakes;
    auto spawnSnakes = () {
        for (int i = 0; i < uniform(10, 30); i++) {
            snakes ~= new Snake(uniform(0, console.width), uniform(0, console.height));
        }
    };
    spawnSnakes();

    auto i = 0;

    return () {
        //console.print(cast(int) floor(cursorX), cast(int) floor(cursorY), "⌬");

        foreach(s; snakes) {

            if (s.dead) {
                snakes ~= new Snake(uniform(0, console.width), uniform(0, console.height)); 
            } else {
                s.tick();
            }
        }

        i++;
        if (i > 100) {
            canvas.clear();
            snakes = [];
            spawnSnakes();
            i = 0;
        }

        canvas.plot(0, 0, console.width, console.height + 1, (int x, int y, dchar symbol) {
            console.print(x, y, to!string(symbol));
        });
    };
}

void main() {
    auto console = new Console;
    scope(exit) endwin();

    bool running = true;

    // for a list of possible keys:
    // https://www.gnu.org/software/guile-ncurses/manual/html_node/Getting-characters-from-the-keyboard.html
    console.input.register("^[", "q", "Q", () {
        running = false;
    });

    auto demo = Demo(console);

/*
    int cursorX = cast(int) (console.width / 2);
    int cursorY = cast(int) (console.height / 2);

    console.input.register("^[[A", () { cursorY--; });
    console.input.register("^[[B", () { cursorY++; });
    console.input.register("^[[C", () { cursorX++; });
    console.input.register("^[[D", () { cursorX--; });

    console.input.register("^[[1;3A", () { cursorY-=10; });
    console.input.register("^[[1;3B", () { cursorY+=10; });
    console.input.register("^[[1;3C", () { cursorX+=10; });
    console.input.register("^[[1;3D", () { cursorX-=10; });
*/

    StopWatch timer;
    timer.start();
    auto last = timer.peek().msecs;

    auto limit = 1000 / 60;

    /*
    auto canvas = new BoxCanvas;


    canvas.addRect(1, 11, 15, 7, BoxSymbol.LineWidth.HEAVY);
    canvas.addRect(1, 1, 15, 7, BoxSymbol.LineWidth.HEAVY_TRIPLE_DASH);

    */
    while (running) {

        auto frame = timer.peek().msecs - last;
        if (frame > limit) {
            console.clear();

demo();
/*
            console.print(cursorX, cursorY, "x");

        canvas.plot(100,100,(int x, int y, dchar symbol) {
            console.print(x, y, to!string(symbol));
                });

            console.print(0, 0, console.input.escBuffer);
*/
            refresh();
            last = timer.peek().msecs;
        } else {
            Thread.sleep( dur!("msecs")( limit - frame ) );
        }
        console.input.poll();
    }
}


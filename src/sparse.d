import std.math;

static const CHUNK_SIZE = 256;

class Chunk(T) {
    // fixed-length array
    T[CHUNK_SIZE][CHUNK_SIZE] cells;
    ref T opIndex(size_t x, size_t y) {
        return cells[x][y];
    }
}

class ChunkCoord {
    // global world coordinates
    long x, y;
    // global chunk coordinates
    long chunkX, chunkY;
    // local chunk coordinates
    size_t localX, localY;

    this(long x, long y) {
        this.x = x;
        this.y = y;
        chunkX = cast(long) floor(x / cast(float) CHUNK_SIZE);
        chunkY = cast(long) floor(y / cast(float) CHUNK_SIZE);
        if (chunkX >= 0) {
            localX = cast(size_t) ( x - (chunkX * CHUNK_SIZE) );
        } else {
            localX = cast(size_t) ( x + abs(chunkX) * CHUNK_SIZE );
        }
        if (chunkY >= 0) {
            localY = cast(size_t) ( y - (chunkY * CHUNK_SIZE) );
        } else {
            localY = cast(size_t) ( y + abs(chunkY) * CHUNK_SIZE );
        }
    }

    override hash_t toHash() {
        // https://en.wikipedia.org/wiki/Cantor_pairing_function
        return 1/2*(chunkX+chunkY)*(chunkX+chunkY+1)+chunkY;
    }

    override bool opEquals(Object o) {
        ChunkCoord coord = cast(ChunkCoord) o;
        return coord && chunkX == coord.chunkX && chunkY == coord.chunkY;
    }

    override int opCmp(Object o) {
        return opEquals(o) ? 0 : 1; // wtf?
    }
}

class SparseArray(T) {
    Chunk!(T)[ChunkCoord] chunks;

    ref T opIndex(long x, long y) {
        auto coord = new ChunkCoord(x, y);
        if (coord !in chunks) {
            chunks[coord] = new Chunk!T;
        }
        auto chunk = chunks[coord];

        return chunk[coord.localX, coord.localY];
    }

    void clear() {
        chunks.clear();
    }
}

unittest {
    auto array = new SparseArray!(uint)();
    assert(array.chunks.length == 0);
    array[3000, 1000] = 42;
    assert(array.chunks.length == 1);
    array[1, 1] = 42;
    assert(array.chunks.length == 2);
    assert(array[3000, 1000] == 42);
    auto empty = array[0, 0];
    assert(is(typeof(empty) : uint));
    assert(empty == uint.init);

    // not quite sure about the limitations but I think its fine for now
    array[long.max, long.max] = 1;
    assert(array[long.max, long.max] == 1);

    auto strings = new SparseArray!(string)();
    auto s = strings[0, 0];
    assert(is(typeof(s) : string));
    assert(s == string.init);
}


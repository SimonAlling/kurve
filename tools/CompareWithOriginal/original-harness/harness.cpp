// Runs the reconstructed source code of the original game (zatacka.cpp from zatacka-decomp) natively and headlessly,
// with scripted players, and prints a JSON Lines trace of every round.
//
// The game's own main() is run as is. It thinks it's talking to BGI and DOS, but it's talking to the stand-ins below.
// Everything the harness does happens in callbacks the game makes anyway:
//
//   * The first sin() call of a round marks the start of the round (all players have spawned).
//   * delay(15 - alive_count / 2) marks the end of a tick.
//   * delay(1000) marks the end of a round.
//
// Usage: harness [--players 0,1,3] [--rounds N] [--seed N] [--bot-seed N] [--holes on|off] [--steering bots|none] [--max-ticks N] [--dump R:T]…
//
//   --players    Player IDs (0 = Red, …, 5 = Blue). Default: 0,1
//   --rounds     Number of rounds to play. Default: 1
//   --seed       Initial value of Borland's RNG seed. The original game never seeds it, so 1 is authentic. Default: 1
//   --bot-seed   Seed for the bots' own RNG (does not affect the game's RNG). Default: 1
//   --holes      "off" keeps every player solid all the time. Default: on
//   --steering   "bots", "none" (nobody ever presses anything) or "replay:FILE". Default: bots
//                FILE has one line per button press: "ROUND TICK ID L|R", meaning that ID holds L or R in tick TICK of round ROUND.
//   --max-ticks  After this many ticks, bots stop steering so that the round eventually ends. Default: 20000
//   --dump R:T   Print the whole canvas (BGI colors) after tick T (0 = at spawn) in round R. Can be repeated.

#include <cstdint>
#include <cstring>
#include <math.h> // C headers that zatacka.cpp includes too, so that its #includes become no-ops.
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>

#include <conio.h>
#include <dos.h>
#include <graphics.h>

// ---- Things that must be in place before the game's source code is included ----

// Borland's random(), which is not the same thing as glibc's random().
int borland_random(int num);
#define random borland_random

// itoa() is not standard C.
char *itoa(int value, char *str, int radix);

// The original runs its float math on the x87 FPU (or Borland's emulator, which uses the FPU if present), with 64-bit mantissas.
// To model that, we compile with -mfpmath=387 -fexcess-precision=standard and let sin/cos return long double.
// (sin is also our hook for detecting the start of a round.)
static long double harness_sin(long double a);
static inline long double harness_cos(long double a) { return cosl(a); }
#define sin harness_sin
#define cos harness_cos

// The game assumes that fresh heap memory is zeroed (see the "BUG" comment about img_bg in zatacka.cpp).
#define malloc(size) calloc(1, (size))

#include "zatacka.generated.cpp"

#undef sin
#undef cos
#undef malloc
#undef random

// ---- Options ----

static std::vector<int> opt_players = {0, 1};
static int opt_rounds = 1;
static uint32_t opt_seed = 1;
static uint64_t opt_bot_seed = 1;
static bool opt_holes = true;
static bool opt_bots = true;
static std::vector<std::vector<int>> opt_replay; // (round, tick, id, 'L' or 'R')
static int opt_max_ticks = 20000;
static std::vector<std::pair<int, int>> opt_dumps; // (round, tick)

// ---- Borland C++ 3.1 runtime ----

static uint32_t borland_seed = 1;

static int borland_rand(void)
{
    borland_seed = borland_seed * 0x015A4E35u + 1;
    return (int)((borland_seed >> 16) & 0x7FFF);
}

int borland_random(int num)
{
    // Verified against the disassembly of ZATACKA.EXE (CS:1296).
    return (int)(((long)borland_rand() * num) / 0x8000);
}

char *itoa(int value, char *str, int radix)
{
    (void)radix;
    snprintf(str, 10, "%d", value); // zatacka.cpp uses a 10-char buffer
    return str;
}

int getch(void) { return 0; }

// ---- BGI ----

static unsigned char framebuffer[SCREEN_HEIGHT][SCREEN_WIDTH];
static int current_color = 15;
static int current_fill_color = 0;
static long out_of_bounds_getpixel_count = 0; // should stay 0; otherwise, results depend on what our getpixel returns outside the screen (see original.mjs)

// The game resets dead[] before we get to see the outcome of the round, so we keep our own copy.
// Every death is followed by bar() calls (when the scoreboard is updated), which is when we take it.
static bool in_round = false;
static int dead_snapshot[PLAYER_COUNT];

struct Image {
    uint16_t width_minus_one;
    uint16_t height_minus_one;
    unsigned char pixels[1]; // actually width * height
};

static void put_pixel(int x, int y, int color)
{
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT)
        framebuffer[y][x] = (unsigned char)color;
}

void initgraph(int *, int *, const char *) {}
int graphresult(void) { return grOk; }
const char *grapherrormsg(int) { return "no error"; }
void closegraph(void) {}

void getpalette(struct palettetype *palette)
{
    palette->size = 16;
    for (int i = 0; i < 16; i++)
        palette->colors[i] = (signed char)i;
}

void setrgbpalette(int, int, int, int) {}

unsigned imagesize(int left, int top, int right, int bottom)
{
    return 4 + (right - left + 1) * (bottom - top + 1);
}

void getimage(int left, int top, int right, int bottom, void *bitmap)
{
    Image *image = (Image *)bitmap;
    int width = right - left + 1;
    image->width_minus_one = (uint16_t)(width - 1);
    image->height_minus_one = (uint16_t)(bottom - top);
    for (int y = top; y <= bottom; y++)
        for (int x = left; x <= right; x++)
            image->pixels[(y - top) * width + (x - left)] = (unsigned char)getpixel(x, y);
}

void putimage(int left, int top, void *bitmap, int op)
{
    if (op != COPY_PUT) {
        fprintf(stderr, "putimage: unsupported op %d\n", op);
        exit(2);
    }
    Image *image = (Image *)bitmap;
    int width = image->width_minus_one + 1;
    int height = image->height_minus_one + 1;
    for (int y = 0; y < height; y++)
        for (int x = 0; x < width; x++)
            put_pixel(left + x, top + y, image->pixels[y * width + x]);
}

void setfillstyle(int pattern, int color)
{
    if (pattern != SOLID_FILL) {
        fprintf(stderr, "setfillstyle: unsupported pattern %d\n", pattern);
        exit(2);
    }
    current_fill_color = color;
}

void bar(int left, int top, int right, int bottom)
{
    if (in_round) memcpy(dead_snapshot, dead, sizeof dead);
    for (int y = top; y <= bottom; y++)
        for (int x = left; x <= right; x++)
            put_pixel(x, y, current_fill_color);
}

void setcolor(int color) { current_color = color; }

void line(int x1, int y1, int x2, int y2)
{
    // Bresenham; the game only draws vertical lines.
    int dx = abs(x2 - x1), sx = x1 < x2 ? 1 : -1;
    int dy = -abs(y2 - y1), sy = y1 < y2 ? 1 : -1;
    int err = dx + dy;
    for (;;) {
        put_pixel(x1, y1, current_color);
        if (x1 == x2 && y1 == y2) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x1 += sx; }
        if (e2 <= dx) { err += dx; y1 += sy; }
    }
}

unsigned getpixel(int x, int y)
{
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT)
        return framebuffer[y][x];
    out_of_bounds_getpixel_count++;
    return 0;
}

// Text is only drawn outside the canvas (scoreboard) or on screens that are cleared before each round.
void settextstyle(int, int, int) {}
void setusercharsize(int, int, int, int) {}
void outtextxy(int, int, const char *) {}

// ---- DOS ----

unsigned _AX, _BX;

static bool mouse_button_left = false;
static bool mouse_button_right = false;

static void dummy_isr(...) {}

isr_t getvect(int) { return dummy_isr; }
void setvect(int, isr_t) {}
unsigned char inportb(int) { return 0; }

void geninterrupt(int interruptno)
{
    if (interruptno == MOUSE_INTERRUPT && _AX == MOUSE_GET_STATUS)
        _BX = (mouse_button_left ? MOUSE_BUTTON_LEFT : 0) | (mouse_button_right ? MOUSE_BUTTON_RIGHT : 0);
}

// ---- Players' input ----

static void set_buttons(int id, bool left, bool right)
{
    if (id < KEYBOARD_PLAYER_COUNT) {
        keyL[id] = left;
        keyR[id] = right;
    } else {
        mouse_button_left = left;
        mouse_button_right = right;
    }
}

static bool get_left(int id) { return id < KEYBOARD_PLAYER_COUNT ? keyL[id] != 0 : mouse_button_left; }
static bool get_right(int id) { return id < KEYBOARD_PLAYER_COUNT ? keyR[id] != 0 : mouse_button_right; }

// ---- Bots ----

static uint64_t bot_rng_state;

static uint32_t bot_rand(void)
{
    // xorshift64*
    bot_rng_state ^= bot_rng_state >> 12;
    bot_rng_state ^= bot_rng_state << 25;
    bot_rng_state ^= bot_rng_state >> 27;
    return (uint32_t)((bot_rng_state * 0x2545F4914F6CDD1DULL) >> 32);
}

enum Action { STRAIGHT = 0, LEFT = 1, RIGHT = 2 };

struct Bot {
    Action action;
    int ticks_until_reconsidering;
};

static Bot bots[PLAYER_COUNT];

#define LOOKAHEAD 70

// Same collision logic as move_or_die (without the side effects).
static bool would_die(int xi, int yi, int old_xi, int old_yi)
{
    int dx = xi - old_xi;
    int dy = yi - old_yi;
    if (xi <= -1 || xi >= CANVAS_WIDTH - TWO || yi <= -1 || yi >= SCREEN_HEIGHT - TWO) return true;
    if (dx < 0) return crashes_when_dx_is_not_zero(xi, yi, dy);
    if (dx > 0) return crashes_when_dx_is_not_zero(xi + TWO, yi, dy);
    if (dy == -1) return is_obstacle(xi, yi) || is_obstacle(xi + TWO, yi);
    if (dy == 1) return is_obstacle(xi, yi + TWO) || is_obstacle(xi + TWO, yi + TWO);
    return false;
}

// How many ticks the player would survive (up to LOOKAHEAD) if it kept doing the given action.
static int free_ticks(int id, Action action)
{
    double bx = x[id], by = y[id], bdir = dir[id];
    int old_xi = px[id], old_yi = py[id];
    double turn = action == LEFT ? TURN_RATE : action == RIGHT ? -TURN_RATE : 0;
    for (int t = 0; t < LOOKAHEAD; t++) {
        bdir += turn;
        bx += sin(bdir);
        by += cos(bdir);
        int xi = (int)bx, yi = (int)by;
        if (would_die(xi, yi, old_xi, old_yi)) return t;
        old_xi = xi;
        old_yi = yi;
    }
    return LOOKAHEAD;
}

static void steer_bot(int id, int tick)
{
    Bot *bot = &bots[id];
    if (tick > opt_max_ticks) {
        set_buttons(id, false, false); // Let the round end eventually.
        return;
    }
    int free[3];
    for (int a = 0; a < 3; a++)
        free[a] = free_ticks(id, (Action)a);
    bot->ticks_until_reconsidering--;
    bool current_is_safe = free[bot->action] == LOOKAHEAD;
    if (!current_is_safe || bot->ticks_until_reconsidering <= 0) {
        int best = 0;
        for (int a = 0; a < 3; a++)
            if (free[a] > best) best = free[a];
        // Pick randomly among the best actions, so that bots wander around instead of being predictable.
        // Only consider actions that are clearly worse than the best if everything is safe.
        int candidates[3], count = 0;
        for (int a = 0; a < 3; a++)
            if (free[a] == best) candidates[count++] = a;
        bot->action = (Action)candidates[bot_rand() % count];
        bot->ticks_until_reconsidering = 1 + (int)(bot_rand() % 60);
    }
    set_buttons(id, bot->action == LEFT, bot->action == RIGHT);
}

static void set_replayed_buttons(int round, int tick)
{
    for (int id : opt_players)
        set_buttons(id, false, false);
    for (auto &press : opt_replay)
        if (press[0] == round && press[1] == tick)
            set_buttons(press[2], press[3] == 'L', press[3] == 'R');
}

// ---- Tracing ----

static void print_player_states(const int *dead)
{
    printf("[");
    bool first = true;
    for (int id : opt_players) {
        printf(
            "%s{\"id\":%d,\"x\":%.17g,\"y\":%.17g,\"dir\":%.17g,\"px\":%d,\"py\":%d,\"dead\":%s,\"countdown\":%d,\"holeTicks\":%d}",
            first ? "" : ",", id, (double)x[id], (double)y[id], (double)dir[id], px[id], py[id], dead[id] ? "true" : "false",
            holecycle_countdown[id], hole_ticks[id]);
        first = false;
    }
    printf("]");
}

static void print_inputs(void)
{
    printf("[");
    bool first = true;
    for (int id : opt_players) {
        printf("%s{\"id\":%d,\"left\":%s,\"right\":%s}", first ? "" : ",", id, get_left(id) ? "true" : "false",
            get_right(id) ? "true" : "false");
        first = false;
    }
    printf("]");
}

static void print_canvas(void)
{
    // Run-length encoding of obstacle pixels (as defined by the game) in the canvas, row by row, starting with a run of non-obstacles.
    printf("[");
    bool current = false;
    int run = 0;
    bool first = true;
    for (int yy = 0; yy < SCREEN_HEIGHT; yy++)
        for (int xx = 0; xx < CANVAS_WIDTH; xx++) {
            bool obstacle = is_obstacle(xx, yy);
            if (obstacle != current) {
                printf("%s%d", first ? "" : ",", run);
                first = false;
                current = obstacle;
                run = 0;
            }
            run++;
        }
    printf("%s%d]", first ? "" : ",", run);
}

static void dump_canvas_if_requested(int round, int tick)
{
    for (auto dump : opt_dumps)
        if (dump.first == round && dump.second == tick) {
            printf("{\"type\":\"canvasDump\",\"round\":%d,\"tick\":%d,\"pixels\":\"", round, tick);
            for (int yy = 0; yy < SCREEN_HEIGHT; yy++)
                for (int xx = 0; xx < CANVAS_WIDTH; xx++)
                    putchar("0123456789abcdef"[framebuffer[yy][xx] & 0xF]);
            printf("\"}\n");
        }
}

// ---- Harness state machine ----

static int rounds_played = 0;
static int tick = 0; // number of completed ticks in the current round

static void force_solid_if_holes_off(void)
{
    if (opt_holes) return;
    for (int id = 0; id < PLAYER_COUNT; id++) {
        holecycle_countdown[id] = 30000;
        hole_ticks[id] = 0;
    }
}

static void start_round(void)
{
    in_round = true;
    tick = 0;
    memcpy(dead_snapshot, dead, sizeof dead);
    for (int id = 0; id < PLAYER_COUNT; id++) {
        score[id] = 0; // so that the game never ends (the original would go back to the splash screen)
        set_buttons(id, false, false); // release the buttons used for joining in the lobby
        bots[id].action = STRAIGHT;
        bots[id].ticks_until_reconsidering = 0;
    }
    force_solid_if_holes_off();
    if (!opt_bots) set_replayed_buttons(rounds_played + 1, 1);
    printf("{\"type\":\"roundStart\",\"round\":%d,\"players\":", rounds_played + 1);
    print_player_states(dead);
    // Whether the head drawn at the spawn position is erased (by restoring a 3x3 background) in the first tick (see README.md#stale-spawn-background):
    printf(",\"spawnErasedInFirstTick\":[");
    bool first = true;
    for (int id : opt_players) {
        bool hole_branch = !(holecycle_countdown[id] > hole_ticks[id]);
        Image *bg = (Image *)img_bg[id];
        bool restores_full_square = bg->width_minus_one == TWO && bg->height_minus_one == TWO;
        printf("%s%s", first ? "" : ",", hole_branch && restores_full_square ? "true" : "false");
        first = false;
    }
    printf("]}\n");
    dump_canvas_if_requested(rounds_played + 1, 0);
}

static void end_tick(void)
{
    tick++;
    printf("{\"type\":\"tick\",\"tick\":%d,\"inputs\":", tick);
    print_inputs();
    printf(",\"players\":");
    print_player_states(dead);
    printf("}\n");
    dump_canvas_if_requested(rounds_played + 1, tick);
    force_solid_if_holes_off();
    if (opt_bots)
        for (int id : opt_players)
            if (!dead[id]) steer_bot(id, tick);
    if (!opt_bots) set_replayed_buttons(rounds_played + 1, tick + 1);
}

static void end_round(void)
{
    in_round = false;
    rounds_played++;
    printf("{\"type\":\"roundEnd\",\"round\":%d,\"tick\":%d,\"inputs\":", rounds_played, tick + 1);
    print_inputs();
    printf(",\"players\":");
    print_player_states(dead_snapshot);
    printf(",\"scores\":[");
    bool first = true;
    for (int id : opt_players) {
        printf("%s%d", first ? "" : ",", score[id]);
        first = false;
    }
    printf("],\"outOfBoundsGetpixelCount\":%ld,\"canvas\":", out_of_bounds_getpixel_count);
    print_canvas();
    printf("}\n");
    dump_canvas_if_requested(rounds_played, tick + 1);
    fflush(stdout);
    for (int id = 0; id < PLAYER_COUNT; id++)
        set_buttons(id, false, false);
    if (rounds_played >= opt_rounds) exit(0);
}

void delay(unsigned milliseconds)
{
    if (!in_round) return;
    if (milliseconds == 1000)
        end_round();
    else if (milliseconds < 50)
        end_tick();
    // 50 ms: spawn flickering, which happens before start_round.
}

// The first sin() call of a round happens right before the first move.
static long double harness_sin(long double a)
{
    if (!in_round) start_round();
    return sinl(a);
}

// ---- Main ----

static std::vector<int> parse_int_list(const char *s)
{
    std::vector<int> result;
    std::string str(s);
    size_t start = 0;
    while (start <= str.size()) {
        size_t comma = str.find(',', start);
        if (comma == std::string::npos) comma = str.size();
        result.push_back(atoi(str.substr(start, comma - start).c_str()));
        start = comma + 1;
    }
    return result;
}

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        const char *value = i + 1 < argc ? argv[i + 1] : "";
        if (arg == "--players") opt_players = parse_int_list(value);
        else if (arg == "--rounds") opt_rounds = atoi(value);
        else if (arg == "--seed") opt_seed = (uint32_t)strtoul(value, nullptr, 10);
        else if (arg == "--bot-seed") opt_bot_seed = strtoull(value, nullptr, 10);
        else if (arg == "--holes") opt_holes = std::string(value) != "off";
        else if (arg == "--steering") {
            std::string steering = value;
            opt_bots = steering == "bots";
            if (steering.rfind("replay:", 0) == 0) {
                FILE *file = fopen(steering.c_str() + 7, "r");
                if (file == nullptr) {
                    fprintf(stderr, "Can't open %s\n", steering.c_str() + 7);
                    return 2;
                }
                int r, t, id;
                char button;
                while (fscanf(file, "%d %d %d %c", &r, &t, &id, &button) == 4)
                    opt_replay.push_back({r, t, id, button});
                fclose(file);
            }
        }
        else if (arg == "--max-ticks") opt_max_ticks = atoi(value);
        else if (arg == "--dump") {
            int dump_round, dump_tick;
            if (sscanf(value, "%d:%d", &dump_round, &dump_tick) != 2) {
                fprintf(stderr, "Invalid --dump value: %s\n", value);
                return 2;
            }
            opt_dumps.push_back({dump_round, dump_tick});
        }
        else {
            fprintf(stderr, "Unknown argument: %s\n", argv[i]);
            return 2;
        }
        i++;
    }
    if (opt_players.size() < 2) {
        fprintf(stderr, "At least 2 players are needed.\n");
        return 2;
    }
    borland_seed = opt_seed;
    bot_rng_state = opt_bot_seed * 0x9E3779B97F4A7C15ULL + 1;

    // Make the game join the players and start right away:
    key_space = 1;
    for (int id : opt_players)
        set_buttons(id, true, false);

    zatacka_main();
    return 0;
}

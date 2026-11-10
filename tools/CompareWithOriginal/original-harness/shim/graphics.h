// Minimal stand-in for Borland's graphics.h (BGI), just enough to compile zatacka.cpp natively.
// The functions are implemented in harness.cpp on top of an in-memory 640x480 framebuffer.
#pragma once

#define VGA 9
#define VGAHI 2
#define grOk 0
#define SOLID_FILL 1
#define COPY_PUT 0
#define DEFAULT_FONT 0
#define TRIPLEX_SCR_FONT 7
#define HORIZ_DIR 0
#define USER_CHAR_SIZE 0
#define MAXCOLORS 15

struct palettetype {
    unsigned char size;
    signed char colors[MAXCOLORS + 1];
};

void initgraph(int *graphdriver, int *graphmode, const char *pathtodriver);
int graphresult(void);
const char *grapherrormsg(int errorcode);
void closegraph(void);
void getpalette(struct palettetype *palette);
void setrgbpalette(int colornum, int red, int green, int blue);
unsigned imagesize(int left, int top, int right, int bottom);
void getimage(int left, int top, int right, int bottom, void *bitmap);
void putimage(int left, int top, void *bitmap, int op);
void setfillstyle(int pattern, int color);
void bar(int left, int top, int right, int bottom);
void setcolor(int color);
void line(int x1, int y1, int x2, int y2);
unsigned getpixel(int x, int y);
void settextstyle(int font, int direction, int charsize);
void setusercharsize(int multx, int divx, int multy, int divy);
void outtextxy(int x, int y, const char *textstring);

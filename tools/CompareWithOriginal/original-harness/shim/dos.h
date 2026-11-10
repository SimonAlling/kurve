// Minimal stand-in for Borland's dos.h, just enough to compile zatacka.cpp natively.
#pragma once

#define interrupt // Borland keyword for interrupt handlers; meaningless here.

typedef void (*isr_t)(...);

extern unsigned _AX, _BX;

isr_t getvect(int interruptno);
void setvect(int interruptno, isr_t isr);
unsigned char inportb(int portid);
void geninterrupt(int interruptno);
void delay(unsigned milliseconds);

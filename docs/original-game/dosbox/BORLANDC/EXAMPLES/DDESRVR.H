// Borland C++ - (C) Copyright 1991 by Borland International

// ddesrvr.h

# define WMU_DDE_CLOSED WM_USER + 100

// Routines in ddesrvr.c
extern HWND            DDEServerInit(HWND hParentWnd, HWND hClientWnd,
                                     LONG lParam, char *szApp, char *szTopic);
extern int             DDEServerClose(HWND hChannel);
extern LONG FAR PASCAL DDEServerWndProc(HWND hWnd, WORD message,
                                        WORD wParam, LONG lParam);

// Routines supplied by application to do actual work.
extern int             DDEExecuteCommand(LPSTR lpCommand);
extern int             DDEData(char *szItem, HANDLE *hData);

// end ddesrvr.h


//+------------------------------------------------------------------+
//|                                                  IsCrossHair.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

//2022.05.22 13:10:24.283 IsCrossHair AUDNZD,M5: GetCursor0 = 473563465

#define DIB_RGB_COLORS  0x00
#define DIB_PAL_COLORS  0x01
#define DIB_PAL_INDICES 0x02

struct WIN32_POINT {
  int   x;
  int   y;
};

struct ICONINFO {
  int fIcon;
  int xHotspot;
  int yHotspot;
  int hbmMask;
  int hbmColor;
};

struct CURSORINFO {
  int  cbSize;
  int  flags;
  int  hCursor;
  WIN32_POINT  ptScreenPos;
};

struct BITMAP {
  int    bmType;
  int   bmWidth;
  int   bmHeight;
  int   bmWidthBytes;
  short   bmPlanes;
  short   bmBitsPixel;
  int bmBits;
};

struct RGBQUAD {
  char rgbBlue;
  char rgbGreen;
  char rgbRed;
  char rgbReserved;
};

struct BITMAPINFOHEADER {
  unsigned int biSize;
  int  biWidth;
  int  biHeight;
  short biPlanes;
  short biBitCount;
  unsigned int biCompression;
  unsigned int biSizeImage;
  int  biXPelsPerMeter;
  int  biYPelsPerMeter;
  unsigned int biClrUsed;
  unsigned int biClrImportant;
} ;

//struct BITMAPINFOHEADER {
//  DWORD biSize;  unsigned 32bit
//  LONG  biWidth;
//  LONG  biHeight;
//  WORD  biPlanes;
//  WORD  biBitCount;
//  DWORD biCompression;
//  DWORD biSizeImage;
//  LONG  biXPelsPerMeter;
//  LONG  biYPelsPerMeter;
//  DWORD biClrUsed;
//  DWORD biClrImportant;
//}

//struct BITMAPINFO
struct BITMAPINFO {
  BITMAPINFOHEADER bmiHeader;
  RGBQUAD bmiColors[1];
};

#import "user32.dll"
  //int  RegisterWindowMessageW(string MessageName); // For Start custom indicator
  //int  PostMessageW(int hwnd,int msg,int wparam,uchar &Name[]); // For Start custom indicator
  //int  FindWindowW(string lpszClass,string lpszWindow); // For Start custom indicator
  // int  keybd_event(int bVk, int bScan, int dwFlags, int dwExtraInfo); // For Start custom indicator
  int GetCursor(void);
  int GetCursorInfo(CURSORINFO &CursorInfo);
  int GetIconInfo(int hIcon, ICONINFO& piconinfo);
  
  //+------------------------------------------------------------------+
  //|                                                                  |
  //+------------------------------------------------------------------+
  int PostMessageA(int hWnd,int Msg,int wParam,int lParam);
  //uint SendInput(uint cInputs, LPINPUT pInputs, int cbSize);
  int GetDC(int);
  int ReleaseDC(int hWnd, int hDC);
#import "Gdi32.dll"
  int GetObjectA(int h, int c,BITMAP &pv);
  int CreateCompatibleDC(int hdc);
  int SelectObject(int hdc, int h);
  int GetDIBits(int hdc, int hbm, unsigned int start, unsigned int cLines, char &lpvBits[], BITMAPINFO &lpbmi, unsigned int usage);
  int DeleteDC(int hdc);
#import "kernel32.dll"
  void Sleep(int dwMilliseconds);
#import

int bMouseMoveEvent=0;
char gCursorinfoArray[sizeof(CURSORINFO)];
CURSORINFO gCursorinfo;
ICONINFO gIconInfo;

char bits[];
int total_pre=0;
int hCursor_pre = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
  ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE,0, true);
//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---

//--- return value of prev_calculated for next call
  return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---

  //https://www.ne.jp/asahi/krk/kct/programming/saveimagefile.htm
  if(id == CHARTEVENT_MOUSE_MOVE) {
    switch(IsCrosshairCursor()){
    case -1:
      break;
    case 0:
      Print("The cursor is NOT crosshair");
      break;
    case 1:
      Print("The cursor is crosshair");
      break;
    default:
      break;
    }
  }
}
//+------------------------------------------------------------------+
int IsCrosshairCursor(void)
// return value yes = 1, no = 0, no change = -1;
{
  BITMAP bmp;
  int bpp;             // 画素数
  int imageSize;
  int hdc;              // デバイスコンテキスト
  int hdc_mem;          // デバイスコンテキスト・メモリ
  BITMAPINFO bitmapinfo;
  int byte_sum=0;
  int return_value = 0;

  gCursorinfo.cbSize = sizeof(CURSORINFO);
  GetCursorInfo(gCursorinfo);
  //Print("GetCursorInfo = "+gCursorinfo.hCursor);
  if(hCursor_pre == gCursorinfo.hCursor){
    return -1;
  }else{
    hCursor_pre = gCursorinfo.hCursor;
  }

  GetIconInfo(gCursorinfo.hCursor, gIconInfo);

  bool isColorShape   = (gIconInfo.hbmColor != NULL);
  bool isMaskShape    = (gIconInfo.hbmMask != NULL);

  //Print("isColorShape = "+isColorShape);
  //Print("isMaskShape = "+isMaskShape);
  if(isMaskShape) {
    GetObjectA(gIconInfo.hbmMask, sizeof(bmp), bmp);
    //Print("hIconLocal gIconInfo.hbmMask = "+gIconInfo.hbmMask);
    //Print("GetIconInfo fIcon = "+gIconInfo.fIcon);
    //Print("GetIconInfo hbmMask = "+gIconInfo.hbmMask);
    //Print("GetIconInfo hbmColor = "+gIconInfo.hbmColor);
    //Print("bmp.bmWidthBytes, bmHeight = "+bmp.bmWidthBytes+" : "+bmp.bmHeight);
    imageSize = bmp.bmWidthBytes * bmp.bmHeight;

    switch (bmp.bmBitsPixel) {
    case 2:
      bpp = 2;
      break;
    case 4:
      bpp = 16;
      break;
    case 8:
      bpp = 256;
      break;
    default:
      bpp = 0;
    }
    imageSize += (sizeof(RGBQUAD) * bpp);
    //Print("bpp = "+bpp);
    //Print("imageSize = "+imageSize);

    ArrayResize(bits, imageSize);

    hdc = GetDC(0);
    hdc_mem = CreateCompatibleDC(hdc);
    ReleaseDC(0, hdc);
    SelectObject(hdc_mem, gIconInfo.hbmMask);

    bitmapinfo.bmiHeader.biSize=sizeof(BITMAPINFOHEADER);

    bitmapinfo.bmiHeader.biWidth = bmp.bmWidth;
    bitmapinfo.bmiHeader.biHeight = bmp.bmHeight;
    bitmapinfo.bmiHeader.biPlanes = 1;
    bitmapinfo.bmiHeader.biBitCount = bmp.bmBitsPixel;
    bitmapinfo.bmiHeader.biCompression = 0; // no compress
    if (bpp != 0) {
      //GetDIBColorTable(hdc_mem, 0, bpp, pbi->bmiColors);
    }

    GetDIBits(hdc_mem, gIconInfo.hbmMask, 0, bmp.bmHeight, bits, bitmapinfo, DIB_RGB_COLORS);

    byte_sum=0;

    for(int i = 0 ; i < imageSize ; i++) {
      byte_sum+=bits[i];
    }

    // sum is 1822 for cross hair
    if(total_pre != byte_sum) {
      //Print("hCursor, byte_sum = "+gCursorinfo.hCursor+" : "+byte_sum);
      total_pre = byte_sum;
    }
    if(byte_sum == 1822){
      // sum is 1822 for cross hair
      return_value=1;
    }
    DeleteDC(hdc_mem);
    //Print("GetCursor0 = "+GetCursor());
    //for(int i= 0 ; i < sizeof(CURSORINFO) ; i++){
    //  Print("GetCursor "+i+" = "+gCursorinfo[i]);
    //}
    //Print("GetCursorInfo = "+gCursorinfo.hCursor);
    //Print("GetCursor = "+GetCursor());
    if(bMouseMoveEvent % 20) {
      //Print("mouse move event="+bMouseMoveEvent);
      bMouseMoveEvent++;
      //Print("Cross hair = "+ChartGetInteger(0,CHART_CROSSHAIR_TOOL, 0));
    }
  }
  return return_value;
}
//+------------------------------------------------------------------+

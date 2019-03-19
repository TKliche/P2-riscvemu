// automatically generated by spin2cpp v3.9.23-beta-adfe23d5 on Wed Mar 13 05:15:33 2019
// command line: /home/ersmith/Parallax/spin2cpp/build/spin2cpp --ccode --p2 vgatext.spin2 

/* 
'******************************
'*  VGA tiled image driver
'******************************

Runs in its own COG. See README.txt for theory of operation.

Quick configuration: change basepin to the appropriate base pin for your VGA setup.

 */
#ifdef __riscv
#include "../lib/riscv.h"
#else
#include <propeller.h>
#endif
#include "vga_tile_driver.h"

#ifdef __GNUC__
#define INLINE__ static inline
#else
#define INLINE__ static
#define waitcnt(n) _waitcnt(n)
#define coginit(id, code, par) _coginit((unsigned)(par)>>2, (unsigned)(code)>>2, id)
#define cognew(code, par) coginit(0x8, (code), (par))
#define cogstop(i) _cogstop(i)
#endif

INLINE__ int32_t Shr__(uint32_t a, uint32_t b) { return (a>>b); }
static char dat[] = {
  0x61, 0x01, 0x04, 0xfb, 0x61, 0x03, 0x04, 0xfb, 0x61, 0x05, 0x04, 0xfb, 0x61, 0x07, 0x04, 0xfb, 
  0x61, 0x09, 0x04, 0xfb, 0x61, 0x0b, 0x04, 0xfb, 0x61, 0x0d, 0x04, 0xfb, 0x61, 0x0f, 0x04, 0xfb, 
  0x61, 0x11, 0x04, 0xfb, 0x61, 0x13, 0x04, 0xfb, 0x61, 0x15, 0x04, 0xfb, 0x61, 0x17, 0x04, 0xfb, 
  0x61, 0x19, 0x04, 0xfb, 0x61, 0x1b, 0x04, 0xfb, 0x61, 0x1d, 0x04, 0xfb, 0x02, 0xe6, 0x00, 0xf6, 
  0x08, 0xe6, 0x04, 0xfa, 0x73, 0xe8, 0x00, 0xf6, 0x3f, 0xe8, 0x04, 0xf1, 0x06, 0xe8, 0x44, 0xf0, 
  0x02, 0xea, 0x00, 0xf6, 0x05, 0xea, 0x00, 0xfa, 0x03, 0xec, 0x00, 0xf6, 0x06, 0xec, 0x00, 0xfa, 
  0x05, 0xdc, 0x00, 0xf1, 0x6e, 0xda, 0x00, 0xf6, 0x08, 0xd2, 0x00, 0xf1, 0x09, 0xd4, 0x00, 0xf1, 
  0x0a, 0xd6, 0x00, 0xf1, 0x75, 0xd8, 0x00, 0xf1, 0x01, 0xf8, 0x60, 0xfd, 0x08, 0xf8, 0x64, 0xf0, 
  0x7c, 0xce, 0x40, 0xf5, 0x7c, 0xd0, 0x40, 0xf5, 0x1d, 0x0e, 0x60, 0xfd, 0x00, 0x00, 0x01, 0xf6, 
  0x04, 0x00, 0x05, 0xf1, 0x02, 0x1c, 0xd4, 0xf7, 0x5a, 0x00, 0x61, 0xfd, 0x01, 0x1c, 0xd4, 0xf7, 
  0x01, 0xe0, 0x84, 0xf5, 0x00, 0x00, 0xa8, 0xff, 0x38, 0x00, 0x64, 0xfd, 0x00, 0x28, 0x80, 0xff, 
  0x39, 0x00, 0x64, 0xfd, 0x28, 0x00, 0x80, 0xff, 0x3a, 0x00, 0x64, 0xfd, 0x3c, 0xe0, 0x60, 0xfd, 
  0x00, 0xce, 0x00, 0xfc, 0x41, 0x00, 0x60, 0xfd, 0x01, 0x00, 0x04, 0xf1, 0x00, 0xd0, 0x00, 0xfc, 
  0x41, 0x00, 0x60, 0xfd, 0x01, 0x00, 0x04, 0xf1, 0x00, 0xd0, 0x00, 0xfc, 0x41, 0x00, 0x60, 0xfd, 
  0x01, 0x00, 0x04, 0xf1, 0x00, 0xd0, 0x00, 0xfc, 0x41, 0x00, 0x60, 0xfd, 0x0b, 0xf4, 0x00, 0xf6, 
  0x80, 0x00, 0xb0, 0xfd, 0x01, 0xee, 0x00, 0xf6, 0x04, 0xf0, 0x00, 0xf6, 0x06, 0xfe, 0x00, 0xf6, 
  0x76, 0xf4, 0x00, 0xf6, 0x78, 0x00, 0xb0, 0xfd, 0x77, 0xe8, 0x70, 0xfc, 0x01, 0xfe, 0x8c, 0xf1, 
  0x06, 0xfe, 0x00, 0xa6, 0x04, 0xf0, 0x00, 0xa6, 0x73, 0xee, 0x00, 0xa1, 0x6e, 0xda, 0x00, 0xf6, 
  0x02, 0x18, 0xd8, 0xfc, 0x12, 0xfc, 0x60, 0xfd, 0x12, 0xfa, 0x60, 0xfd, 0x7e, 0xf6, 0xe0, 0xf8, 
  0xff, 0xfc, 0x24, 0xf5, 0x81, 0xf6, 0x6c, 0xf9, 0x00, 0xf6, 0xe0, 0xf8, 0x7b, 0xda, 0xc0, 0xfc, 
  0x71, 0xfa, 0x30, 0xfc, 0x01, 0xe2, 0x04, 0xf1, 0x71, 0xfc, 0x30, 0xfc, 0x72, 0xe2, 0x60, 0xf5, 
  0x6f, 0xda, 0x60, 0xf5, 0xeb, 0xf5, 0x6c, 0xfb, 0x0d, 0xf4, 0x00, 0xf6, 0x14, 0x00, 0xb0, 0xfd, 
  0x5f, 0x00, 0x61, 0xfd, 0x0c, 0xf4, 0x00, 0xf6, 0x08, 0x00, 0xb0, 0xfd, 0x5f, 0x00, 0x61, 0xfd, 
  0x78, 0xff, 0x9f, 0xfd, 0x08, 0x00, 0xb0, 0xfd, 0x00, 0xd8, 0xc4, 0xfc, 0xfd, 0xf5, 0x6c, 0x0b, 
  0x00, 0xd2, 0xc4, 0xfc, 0x01, 0xd4, 0xc4, 0xfc, 0x00, 0xd6, 0xc4, 0xfc, 0x28, 0x7e, 0x64, 0xfd, 
  0x78, 0x02, 0x01, 0xfb, 0x00, 0xf1, 0x04, 0xf1, 0x2d, 0x00, 0x64, 0xfd, 0x40, 0x00, 0x16, 0x00, 
  0x40, 0x00, 0x17, 0x00, 0x00, 0x00, 0x00, 0xcf, 0x00, 0x00, 0x00, 0xcf, 0x00, 0x00, 0x00, 0xcf, 
  0x00, 0x00, 0x00, 0xcf, 0x00, 0x00, 0x00, 0x8f, 0x00, 0x00, 0x00, 0x8f, 0x00, 0x00, 0x01, 0x00, 
  0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00, 
};
int32_t vga_tile_driver_start(vga_tile_driver *self, int32_t params)
{
  self->mycog = cognew((int32_t)(((int32_t *)&dat[0])), params) + 1;
  return self->mycog;
}

void vga_tile_driver_stop(vga_tile_driver *self)
{
  if (self->mycog) {
    cogstop(self->mycog - 1);
    self->mycog = 0;
  }
}

int32_t vga_tile_driver_calcscale(int32_t a, int32_t b)
{
  int32_t 	shiftcnt;
  shiftcnt = VGA_TILE_DRIVER_PIXSHIFT;
  // remove factors of 5 (will be pretty common)
  while ((0 == (a % 5)) && (0 == (b % 5))) {
    a = a / 5;
    b = b / 5;
  }
  // scale a up as much as we can
  while (((a & 0x40000000) == 0) && (shiftcnt > 0)) {
    a = a << 1;
    (shiftcnt--);
  }
  while (((b & 0x1) == 0) && (shiftcnt > 0)) {
    b = Shr__(b, 1);
    (shiftcnt--);
  }
  return ((a / b) << shiftcnt);
}


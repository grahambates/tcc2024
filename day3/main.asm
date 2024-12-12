                incdir  "../include"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

W = 640
H = 256

_start:
                ; BCPL trick to current screen without OpenLibrary
                move.l  $170(a2),a6     ; intuitionbase from globvec
                move.l  ib_ActiveScreen(a6),a5 ; Store pointer to active screen that we're going to hijack

                ; Doesn't matter what the start frame is!
                ; moveq   #0,d2           ; frame
.frame:
                ; Get bitplane pointer
                move.l  sc_BitMap+bm_Planes+4(a5),a0

                ; Move to end of bitplane - can skip this by getting second bitplane (+4 above) because we know they're
                ; sequential in memory
                ; lea     W/8*H(a0),a0

                move.w  #H-1,d7         ; y desc
.y:
                moveq   #0,d0           ; x
                move.w  #W/16-1,d6      ; x bit desc
.xbyte:
                moveq   #0,d4           ; word value
                moveq   #1,d3           ; current bit
                moveq   #16-1,d5
.xbit:
                ; plot if:
                ; ((y + t) ~ x) % 256 > y
                move.w  d7,d1           
                add.w   d2,d1
                eor.w   d0,d1 
                cmp.b   d7,d1
                bhs.s   .noPlot
                or.w    d3,d4
.noPlot:
                add.w   d3,d3
                addq    #1,d0
                dbf     d5,.xbit
                move.w  d4,-(a0)
                dbf     d6,.xbyte
                dbf     d7,.y

                add.w   #16,d2
                bra.b   .frame

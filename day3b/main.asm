                incdir  "../include"
                include "hw.i"

DIW_W = 256
DIW_H = 220
DIW_BW = DIW_W/8
BPLS = 1
DIW_SIZE = DIW_BW*DIW_H*BPLS
DIW_XSTRT = ($242-DIW_W)/2
DIW_YSTRT = ($158-DIW_H)/2
DIW_XSTOP = DIW_XSTRT+DIW_W
DIW_YSTOP = DIW_YSTRT+DIW_H

DIW_STRT = DIW_YSTRT<<8!DIW_XSTRT
DIW_STOP = (DIW_YSTOP-256-1)<<8!(DIW_XSTOP-256)
DDF_STRT = (DIW_XSTRT-17)>>1&$fc
DDF_STOP = (DIW_XSTRT-17+(DIW_W>>4-1)<<4)>>1&$fc

C = dmacon

                code_c
_start:
                lea     custom+diwstrt,a6
                move.l  #DIW_STRT<<16!DIW_STOP,(a6)+
                move.l  #DDF_STRT<<16!DDF_STOP,(a6)+
                move.w  #$7fff,intena-C(a6)
                lea     Cop(pc),a0
                move.l  a0,cop1lc-C(a6)
                lea     BplE-DIW_BW(pc),a4
                move.w  a4,CopBPl0L-Cop(a0)
                move.l  a4,CopBPl0H-Cop(a0)

                moveq   #0,d3           ; clear value

                move.l  #$0040f08,color00-C(a6)
.frame:
                move.l  a4,a0

; Alternate plot method:
                move.w  #DIW_H/2-1,d7   ; y desc
.y:
                move.w  d7,d4
                add.w   d4,d4
                suba.w  #DIW_BW,a0
                moveq   #0,d0           ; x
                move.w  #DIW_W/8-1,d6   ; x bit desc
.xbyte:
                move.b  d3,-(a0)
                moveq   #4-1,d5
.xbit:
                ; plot if:
                ; ((y + t) ~ x) % 256 > y
                move.w  d4,d1           
                add.w   d2,d1
                eor.w   d0,d1 
                cmp.b   d7,d1
                bhs.s   .noPlot
                bset    d0,(a0)
.noPlot:
                addq    #2,d0
                dbf     d5,.xbit
                dbf     d6,.xbyte
                dbf     d7,.y

                addq    #2,d2
                bra.b   .frame

Cop:
                dc.w    dmacon,DMAF_SPRITE
                dc.w    bplcon0,(1<<12)!$200
                dc.w    bpl1mod,-DIW_BW*2
                dc.w    bpl0ptl 
CopBPl0L:       dc.w    0
                dc.w    bpl0pt
CopBPl0H:       
                ; dc.w    0
                ; dc.l    -2

                printt  "code bytes:"
                printv  *

                dc.w    0
                ds.b    DIW_SIZE/2
Bpl:            ds.b    DIW_SIZE
BplE:

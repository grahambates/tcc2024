                incdir  "../include"
                include "hw.i"

SIN_LEN = 128

DIW_W = 288
DIW_H = 180
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

PrecalcRadius:
                lea     RadiusTbl(pc),a0
                move.l  a0,a3
                move.w  #DIW_H/2-1,d7
.preY:
                move.w  #DIW_W/2-1,d6
.preX:
                move.w  d7,d0
                sub.w   #DIW_H/3,d0
                move.w  d6,d1
                sub.w   #DIW_W/3,d1
                muls    d0,d0
                muls    d1,d1
                add.w   d0,d1
                lsr.w   #3,d1
                move.w  d1,(a0)+
                dbf     d6,.preX
                dbf     d7,.preY

PrecalcSin:
                ; lea     Sin(pc),a0
                move.l  a0,a7
                moveq   #0,d0
                move.w  #SIN_LEN/2+1,a1
.sin:           subq.l  #2,a1
                move.l  d0,d1
                asr.l   #2,d1           ; this determines the amplitude
                move.w  d1,SIN_LEN*2(a0)
                move.w  d1,(a0)+
                neg.w   d1
                move.w  d1,SIN_LEN*2+SIN_LEN-2(a0)
                move.w  d1,SIN_LEN-2(a0)
                add.l   a1,d0
                bne.b   .sin

                moveq   #1<<6,d4

                move.l  #$0040f08,color00-C(a6)
Frame:
                move.w  d2,d0
                and.w   #(SIN_LEN-1)*2,d0
                lea     (a7,d0),a2      ; sin offset
                move.l  a3,a5           ; radius
                move.l  a4,a0           ; bitplane

; Alternate plot method:
                move.w  #DIW_H/2-1,d7   ; y desc
.y:
                move.w  (a2)+,d3
                suba.w  #DIW_BW,a0
                moveq   #0,d0           ; x
                move.w  #DIW_W/8-1,d6   ; x bit desc
.xbyte:
                clr.b   -(a0)
                moveq   #4-1,d5
.xbit:
                move.w  (a5)+,d1
                add.w   d3,d1
                and.w   d4,d1

                bne.s   .noPlot
                bset    d0,(a0)
.noPlot:
                addq    #2,d0
                dbf     d5,.xbit
                dbf     d6,.xbyte
                dbf     d7,.y

                addq    #2,d2
                bra.b   Frame

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

RadiusTbl:
                ds.w    DIW_W*DIW_H
Sin:
                ds.w    SIN_LEN*2

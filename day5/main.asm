                incdir  "../include"
                include "hw.i"

DIW_W = 256
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

; Constants (Q8.8 format)
TURN_1_8        equ     $0020           ; 1/8 turn (0.125)
TURN_3_8        equ     $0060           ; 3/8 turn (0.375)
TURN_1_2        equ     $0080           ; 1/2 turn (0.5)
TURN_1          equ     $0100           ; 1 full turn (1.0)

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

Precalc:
                move.w  #DIW_W/4,d3
                lea     Tbl(pc),a0
                move.l  a0,a3
                move.w  #DIW_H/2-1,d7
.preY:
                move.w  #DIW_W/2-1,d6
.preX:
                move.w  d7,d0           ; dy
                sub.w   #DIW_H/4,d0
                bgt     .posY   
                neg.w   d0              
.posY:
                move.w  d6,d1           dx
                sub.w   d3,d1
                bgt     .posX   
                neg.w   d1              
.posX:

; Radius
                move.w  d0,d4
                move.w  d1,d5
                muls    d4,d4
                muls    d5,d5
                add.w   d4,d5
                moveq   #2,d2           ; $20000
                swap    d2
                addq    #1,d5
                divu    d5,d2
                move.w  d2,(a0)+

; Atan2 approx:
                moveq   #0,d2 
                ; (dy<<8) / (dx+dy)
                move.w  d0,d2
                add.w   d1,d0          
                addq    #1,d0
                lsl.l   #8,d2
                divu    d0,d2
; Fix quadrant
                cmp.w   #DIW_H/4,d7
                ble     .posYq
                cmp.w   d3,d6
                bge     .d
                neg.w   d2
.posYq:         cmp.w   d3,d6
                ble     .d
                neg.w   d2
.d:

                move.w  d2,(a0)+

                dbf     d6,.preX
                dbf     d7,.preY

                moveq   #1<<5,d4

                ; move.l  #$8000fff,color00-C(a6)
Frame:
                move.l  a3,a5           ; radius
                move.l  a4,a0           ; bitplane

; Alternate plot method:
                move.w  #DIW_H/2-1,d7   ; y desc
.y:
                suba.w  #DIW_BW,a0
                moveq   #0,d0           ; x
                move.w  #DIW_W/8-1,d6   ; x bit desc
.xbyte:
                clr.b   -(a0)
                moveq   #4-1,d5
.xbit:
                movem.w (a5)+,d1/d3
                add.w   d2,d1
                add.w   d2,d3
                eor.w   d3,d1
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

********************************************************************************
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
                ds.b    DIW_SIZE
Bpl:            ds.b    DIW_SIZE
BplE:

Tbl:
                ds.w    (DIW_W/2)*(DIW_H/2)*2

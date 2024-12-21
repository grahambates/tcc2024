********************************************************************************
; Double buffered display using custom RastPort
; Allows use of graphics library draw routines, and custom screen geometry

                incdir  "../include"
                include "hw.i"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

; Can specify our own display window and screen sizes:
DIW_W = 256
DIW_H = 256
DIW_BW = DIW_W/8

BPLS = 1
SCREEN_W = DIW_W
SCREEN_BW = SCREEN_W/8
SCREEN_H = DIW_H

DIW_SIZE = DIW_BW*DIW_H*BPLS
DIW_XSTRT = ($242-DIW_W)/2
DIW_YSTRT = ($158-DIW_H)/2
DIW_XSTOP = DIW_XSTRT+DIW_W
DIW_YSTOP = DIW_YSTRT+DIW_H

DIW_STRT = DIW_YSTRT<<8!DIW_XSTRT
DIW_STOP = (DIW_YSTOP-256-1)<<8!(DIW_XSTOP-256)
DDF_STRT = (DIW_XSTRT-17)>>1&$fc
DDF_STOP = (DIW_XSTRT-17+(DIW_W>>4-1)<<4)>>1&$fc

; Fixed address for screen buffer
SCREEN_ADDR = $60000

; Custom register offset
C = dmacon

SIN_LEN = 256 


********************************************************************************
                code_c
********************************************************************************

; Initial registers:
; d0.l = 1 (as long as no CLI params)
; d4.l = 1
; a1 - base of the current BCPL stack frame (http://megaburken.net/~patrik/BCPL/ramlib.doc.txt)
; a2 - pointer to the BCPL Global Vector
; a3 - return address of the caller
; a4 - entry address
; a5 - pointer to a "caller" service routine
; a6 - pointer to a "returner" service routine
_start:
                lea     Sin(pc),a0
PrecalcSin:
                moveq   #0,d0
                move.w  #SIN_LEN/2+1,d2
.sin:           subq    #2,d2
                move.w  d0,d1
                move.w  d1,SIN_LEN*2(a0)
                move.w  d1,(a0)+
                neg.w   d1
                move.w  d1,SIN_LEN-2(a0)
                add.w   d2,d0
                bne.b   .sin

                move.l  #SCREEN_ADDR,(a3)

                lea     custom+diwstrt,a6
                ; Set window size (smaller than setting in copper)
                move.l  #DIW_STRT<<16!DIW_STOP,(a6)+
                move.l  #DDF_STRT<<16!DDF_STOP,(a6)+
                ; install copper
                lea     Copper(pc),a0
                move.l  a0,cop1lc-C(a6)

                lea     CopperGrad(pc),a1
                move.l  #$2cdffffe,(a4)
                move.w  #SCREEN_H-32-1,d7
.copl:
                move.l  (a4),(a1)+
                move.w  #color00,(a1)+
                move.w  d7,d3
                move.w  d7,d5
                and.w   d4,d5
                lsl.w   #3,d5
                add.w   d5,d3
                lsr.w   #4,d3
                move.w  d3,(a1)+
                addq.b  #1,(a4)
                dbf     d7,.copl

Frame:
.vsync:         cmp.b   #$ff,vhposr-C(a6)
                bne.b   .vsync

                ; XOR screen buffer pointer to toggle upper word for double buffering
                eor.w   #1,(a3)         ; $60000 or $70000

                ; clear
                move.l  (a3),a0
                move.w  #SCREEN_BW*SCREEN_H/4-1,d6
.clr:           clr.l   (a0)+
                dbf     d6,.clr

                lea     SCREEN_BW/2-SCREEN_BW*240(a0),a0

                lea     Sin(pc),a2
                lea     SIN_LEN/2(a2),a4 ; cos
                move.w  d7,d1           ; angle
                moveq   #15,d5          ; multiplier
                move.w  #224-1,d6
.l:
                and.w   #(SIN_LEN-1)*2,d1
                move.w  (a2,d1),d2
                muls    d5,d2
                swap    d2
                move.w  d2,d3
                asr.w   #3,d3
                move.w  (a4,d1),d4
                muls    d5,d4
                swap    d4
                asr.w   #3,d4
                lsl.w   #5,d4           ; mulu    #SCREEN_BW,d4
                add.w   d4,d3
                not.w   d2
                bset    d2,(a0,d3)
                add.w   #20,d1
                addq    #8,d5
                lea     SCREEN_BW(a0),a0
                dbf     d6,.l

                ; CPU sets upper word of bpl ptr to flip buffer
                move.w  (a3),bpl0pt-C(a6)
                dbf     d7,Frame

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                ; dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0ptl,SCREEN_ADDR&$ffff ; Copper sets lower word of bpl ptr
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    color01,$0f0
CopperGrad:
                ds.w    SCREEN_H*4

Sin:            ds.w    SIN_LEN*3


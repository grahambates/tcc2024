********************************************************************************
; Double buffered display using custom RastPort
; Allows use of graphics library draw routines, and custom screen geometry

                incdir  "../include"
                include "hw.i"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

; Can specify our own display window and screen sizes:
DIW_W = 320
DIW_H = 256
DIW_BW = DIW_W/8

BPLS = 3
SCREEN_W = DIW_W
SCREEN_BW = SCREEN_W/8
SCREEN_H = DIW_H

DIW_SIZE = DIW_BW*DIW_H*BPLS
DIW_XSTRT = ($242-DIW_W)/2
DIW_YSTRT = ($158-DIW_H)/2
DIW_XSTOP = DIW_XSTRT+DIW_W
DIW_YSTOP = DIW_YSTRT+DIW_H

DIW_STRT = DIW_YSTRT<<8!DIW_XSTRT
DIW_STOP = (DIW_YSTOP-256-1-11)<<8!(DIW_XSTOP-256) ; stop early
DDF_STRT = (DIW_XSTRT-17)>>1&$fc
DDF_STOP = (DIW_XSTRT-17+(DIW_W>>4-1)<<4)>>1&$fc

; Fixed address for screen buffer
SCREEN_ADDR0 = $50000
SCREEN_ADDR = $60000

; Custom register offset
; By Setting a6 to a specific register, rather than $dff000, we save 4 bytes accessing that register without an offset.
C = dmacon

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
                lea     custom+diwstrt,a5
                ; Set window size (smaller than setting in copper)
                move.l  #DIW_STRT<<16!DIW_STOP,(a5)+
                move.l  #DDF_STRT<<16!DDF_STOP,(a5)+
                ; install copper
                lea     Copper(pc),a4
                move.l  a4,cop1lc-C(a5)

                lea     SCREEN_ADDR0+SCREEN_BW*212-10,a0

                moveq.l #-1,d4

                lea     color00-C(a5),a3

                moveq   #6-1,d7
.treeSegment:
                move.l  d4,(a3)+        ; clear palette to white

                moveq   #-1,d0
                moveq   #-1,d1
                moveq   #32-1,d6
.treeLine:
                ; right tri
                move.l  d1,(a0)

                move.l  d4,SCREEN_BW*128-6(a0) ; trunk

                move.w  #SCREEN_BW,d3

                ; fill
                move.l  d7,d5
                move.l  a0,a1
.treeLineFill:
                move.l  d4,-(a1)
                dbf     d5,.treeLineFill

                ; left tri
                move.l  d0,(a1)

                lsr.l   d0
                lsl.l   d1
                suba.w  d3,a0
                dbf     d6,.treeLine
                subq    #2,a0
                dbf     d7,.treeSegment

                lea     SCREEN_ADDR,a0

                move.w  #SCREEN_H-1,d7
.snowLine:            
                lea     SCREEN_BW*SCREEN_H(a0),a1 ; repeated
                add.b   d0,d0
                eor.b   d7,d0
                bset    d0,(a0,d0)
                bset    d0,(a1,d0)
                adda.w  d3,a0
                dbf     d7,.snowLine

Frame:
.vsync:         tst.b   vhposr-C(a5)
                bne.b   .vsync

                moveq   #0,d1
                move.b  d7,d1
                mulu    d3,d1
                move.w  d1,Bpl2L-Copper(a4)

                move.w  d7,d1
                asr     d1
                and.w   #255,d1
                mulu    d3,d1
                move.w  d1,Bpl1L-Copper(a4)

                dbf     d7,Frame

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0pt,SCREEN_ADDR0>>16
                dc.w    bpl0ptl,SCREEN_ADDR0&$ffff
                dc.w    bpl1pt,SCREEN_ADDR>>16
                dc.w    bpl1ptl
Bpl1L:          dc.w    0
                dc.w    bpl2pt,SCREEN_ADDR>>16
                dc.w    bpl2ptl
Bpl2L:          dc.w    0
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    color00,$012    ; blue bg
                dc.w    color01,$052    ; tree - green
                dc.w    color03,$052    ; tree - green
                dc.w    $ffdf,$fffe
                dc.w    color01,$321    ; trunk - brown
                dc.w    color03,$321    ; trunk - brown
                dc.w    $2007,$fffe
                dc.w    color00,$fff    ; floor - white
                ; dc.w    -1

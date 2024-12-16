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
                lea     Copper(pc),a0
                move.l  a0,cop1lc-C(a5)

                lea     SCREEN_ADDR+SCREEN_BW*212-10,a0

                moveq.l #-1,d4
                moveq   #6-1,d7
.l0:
                moveq   #-1,d0
                moveq   #-1,d1
                moveq   #32-1,d6
.l1:
                ; right tri
                move.l  d1,(a0)

                move.l  d4,SCREEN_BW*128-6(a0) ; trunk

                ; fill
                move.l  d7,d5
                move.l  a0,a1
.l2:
                move.l  d4,-(a1)
                dbf     d5,.l2

                ; left tri
                move.l  d0,(a1)

                lsr.l   d0
                lsl.l   d1
                lea     -SCREEN_BW(a0),a0
                dbf     d6,.l1
                subq    #2,a0
                dbf     d7,.l0

                bra.b   *

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                ; dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0pt,SCREEN_ADDR>>16
                dc.w    bpl0ptl,SCREEN_ADDR&$ffff
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    color00,$006
                dc.w    color01,$0a0
                dc.w    $ffdf,$fffe
                dc.w    color01,$840
                dc.w    $2007,$fffe
                dc.w    color00,$fff
                dc.w    color01,$fff
                ; dc.w    -1

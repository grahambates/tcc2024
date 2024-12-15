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
                move.l  #SCREEN_ADDR,(a3)

                lea     custom+diwstrt,a6
                ; Set window size (smaller than setting in copper)
                move.l  #DIW_STRT<<16!DIW_STOP,(a6)+
                move.l  #DDF_STRT<<16!DDF_STOP,(a6)+
                ; install copper
                lea     Copper(pc),a0
                move.l  a0,cop1lc-C(a6)

                ; Can set palette now OS copper is killed
                move.l  #$04040880,color-C(a6)

                moveq   #0,d0           ; y var for example

Frame:
.vsync:         cmp.b   #$ff,vhposr-C(a6)
                bne.b   .vsync

                ; XOR screen buffer pointer to toggle upper word for double buffering
                ; This gives us two 64k aligned buffers, so we only need to change the upper word of the address, and 
                ; can use a fixed value for the lower word in the copper.
                eor.w   #1,(a3)         ; $60000 or $70000

                move.l  (a3),a0

                ; clear
                move.l  a0,a1
                move.w  #SCREEN_BW*SCREEN_H/4-1,d7
.clr:           clr.l   (a1)+
                dbf     d7,.clr

                ;-------------------------------------------------------------------------------
                ; Draw something:
                moveq   #16-1,d7
.l:
                move.w  #-1,(a0,d0)
                lea     SCREEN_BW(a0),a0
                dbf     d7,.l
                add.w   #SCREEN_BW,d0
                ;-------------------------------------------------------------------------------

                ; CPU sets upper word of bpl ptr to flip buffer
                move.w  (a3),bpl0pt-C(a6)
                bra.b   Frame

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0ptl,SCREEN_ADDR&$ffff ; Copper sets lower word of bpl ptr
                dc.w    bplcon0,BPLS<<12!$200
                ; dc.w    -1

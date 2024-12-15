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
; By Setting a5 to a specific register, rather than $dff000, we save 4 bytes accessing that register without an offset.
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
                move.l  $4.w,a6         ; execbase
                move.l  156(a6),a6      ; graphicsbase (ExecBase->IntVects[6].iv_Data)

                ; Create a new rastport struct over the top of BCPL global vector!
                move.l  a2,a1           ; a2 = rastport
                jsr     _LVOInitRastPort(a6)

                ; Use stack pointer to build bitmap struct:
                pea     SCREEN_ADDR     ; single bitplane buffer to bm_Planes
                move.l  a7,a3           ; a3 = screen buffer ptr
                swap    d4              ; d4 is always 1, swap to upper word for flags and blitplanes
                                        ; 00,         01,         XXXX
                move.l  d4,-(a7)        ; bm_Flags B, bm_Depth B, bm_Pad W
                move.l  #(SCREEN_BW<<16)+SCREEN_H,-(a7) ; bm_BytesPerRow W, bm_Rows W

                move.l  a7,rp_BitMap-RastPort(a2) ; Set bitpmap ptr in our rastport struct

                lea     custom+diwstrt,a5
                ; Set window size (smaller than setting in copper)
                move.l  #DIW_STRT<<16!DIW_STOP,(a5)+
                move.l  #DDF_STRT<<16!DDF_STOP,(a5)+
                ; install copper
                lea     Copper(pc),a0
                move.l  a0,cop1lc-C(a5)

                ; Can set palette now OS copper is killed
                move.l  #$04040880,color-C(a5)

Frame:
.vsync:         cmp.b   #$ff,vhposr-C(a5)
                bne.b   .vsync

                ; XOR screen buffer pointer to toggle upper word for double buffering
                ; This gives us two 64k aligned buffers, so we only need to change the upper word of the address, and 
                ; can use a fixed value for the lower word in the copper.
                eor.w   #1,(a3)         ; $60000 or $70000

                move.l  a2,a1
                jsr     _LVOClearScreen(a6)

                ;-------------------------------------------------------------------------------
                ; Draw something:
                lea     Points(pc),a0
                movem.w (a0),d0-d3
                addq.b  #1,d1
                addq.b  #1,d3
                movem.w d0-d3,(a0)
                jsr     _LVORectFill(a6)
                ;-------------------------------------------------------------------------------

                ; CPU sets upper word of bpl ptr to flip buffer
                move.w  (a3),bpl0pt-C(a5)
                bra.b   Frame

;-------------------------------------------------------------------------------
Points:
                dc.w    SCREEN_W/2-10   ; x1
                dc.w    0               ; y1
                dc.w    SCREEN_W/2+10   ; x2
                dc.w    20              ; y2

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0ptl,SCREEN_ADDR&$ffff ; Copper sets lower word of bpl ptr
                dc.w    bplcon0,BPLS<<12!$200
                ; dc.w    -1

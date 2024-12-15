********************************************************************************
; Double buffered display using active screen and existing RastPort
; Allows use of graphics library draw routines with default hires screen

                incdir  "../include"
                include "hw.i"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

BPLS = 1

; Match existing screen geometry
SCREEN_W = 640
SCREEN_BW = SCREEN_W/8
SCREEN_H = 256

; Fixed address for screen buffer
SCREEN_ADDR = $60000

; Custom register offset
; By Setting a5 to a specific register, rather than $dff000, we save 4 bytes accessing that register without an offset.
C = vhposr

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
                ; Here we're going to use the active screen and replace the bitplane pointer(s) with our own fixed
                ; address for double buffering.
                ; Once we've done this we can take over the system, and display the screen using our own copperlist, but
                ; the graphics lib drawing routines will still work
                ; For this to work we need to use the same screen geometry as the existing screen. We could patch these 
                ; in the existing RastPort too, but it would be more efficient to initialise a new one at this point.

                move.l  $170(a2),a6     ; intuitionbase from globvec
                move.l  ib_ActiveScreen(a6),a5 ; Store pointer to active screen that we're going to hijack
                move.l  $4.w,a6         ; execbase
                move.l  156(a6),a6      ; graphicsbase (ExecBase->IntVects[6].iv_Data)

                lea     sc_RastPort(a5),a2 ; a2 = RastPort (use existing from active screen)
                lea     sc_BitMap+bm_Planes(a5),a3 ; a3 = Screen buffer pointer

                move.l  #SCREEN_ADDR,(a3) ; Set first bm_Planes ptr to fixed address
                ; move.w  d4,bm_Flags-bm_Planes(a3) ; You could patch other bitmap properties if you want

                ; install copper
                lea     custom+C,a5
                lea     Copper(pc),a0
                move.l  a0,cop1lc-C(a5)

                ; Can set palette directly in registers now OS copper is killed
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
                dc.w    SCREEN_W/2-20   ; x1
                dc.w    0               ; y1
                dc.w    SCREEN_W/2+20   ; x2
                dc.w    20              ; y2

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0ptl,SCREEN_ADDR&$ffff ; Copper sets lower word of bpl ptr
                dc.w    bplcon0,BPLS<<12!$200!(1<<15) ; Screen mode
                ; dc.w    -1

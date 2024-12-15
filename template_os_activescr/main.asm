********************************************************************************
; Single buffered, OS manged display using active screen and existing RastPort
; Allows use of graphics library draw routines with default hires screen

                incdir  "../include"
                include "hw.i"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

; Match existing screen geometry
SCREEN_W = 640
SCREEN_BW = SCREEN_W/8
SCREEN_H = 256

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
                move.l  $170(a2),a6     ; intuitionbase from globvec
                move.l  ib_ActiveScreen(a6),a5 ; Store pointer to active screen that we're going to hijack
                move.l  $4.w,a6         ; execbase
                move.l  156(a6),a6      ; graphicsbase (ExecBase->IntVects[6].iv_Data)

                lea     sc_RastPort(a5),a2 ; a2 = RastPort (use existing from active screen)

Frame:
.vsync:         cmp.b   #$ff,custom+vhposr
                bne.b   .vsync
                ; or...
                ; jsr     _LVOWaitTOF(a6)

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

                bra.b   Frame

;-------------------------------------------------------------------------------
Points:
                dc.w    SCREEN_W/2-20   ; x1
                dc.w    0               ; y1
                dc.w    SCREEN_W/2+20   ; x2
                dc.w    20              ; y2

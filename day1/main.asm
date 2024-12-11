                incdir  "include"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

                ifnd    BSS
BSS = 1
                endc
W = 640
H = 256

TREE_TRIH = 50
TREE_TRIS = 5
TREE_VSTEP = 25
TREE_HSTEP = 7

                ; Ensure all data in in chip RAM
                code_c

_start:
                ; BCPL trick to get a ponter to graphics library and current screen without OpenLibrary
                move.l  $170(a2),a6     ; intuitionbase from globvec
                move.l  ib_ActiveScreen(a6),a5 ; Store pointer to active screen that we're going to hijack
                move.l  $4.w,a6         ; execbase
                move.l  156(a6),a6      ; graphicsbase (ExecBase->IntVects[6].iv_Data)

                ; Set palette
                lea     sc_ViewPort(a5),a0
                lea     Colors(pc),a1
                moveq   #3,d0           ; leave 4th color default KS1.X orange
                jsr     _LVOLoadRGB4(a6)

                ; Set pointer to TmpRas on viewport:
                ; This is a temporary buffer required for flood fill to work, and the active screen doesn't have one :-(
                ; nor does it have an AreaInfo struct required for filled draw routines, but this is too much setup
                ; so we have to make do without.
                lea     Tmp(pc),a2
                lea     TmpBuffer(pc),a3
                move.l  a3,(a2)
                lea     sc_RastPort(a5),a1
                move.l  a1,a4           ; stack rastport for quick restore
                move.l  a2,rp_TmpRas(a1)

                jsr     _LVOClearScreen(a6)

.frame:
                ; Tree trunk
                ; Pen is orange on start
                movem.w Trunk(pc),d0-d3
                jsr     _LVORectFill(a6)

                ; Green pen
                move.l  a4,a1           ; restore rastport
                moveq   #1,d0
                jsr     _LVOSetAPen(a6)

                ; Tree triangle loop
                moveq   #0,d6           ; y offset
                move.w  #W/2,d5         ; x center
                move.w  #TREE_TRIH,d3   ; vertical step size
                move.w  d3,d4           ; initial width
                moveq   #TREE_TRIS-1,d7
.l:
                ; Outline triangle path
                move.w  d5,d0           ; x
                move.w  d6,d1           ; y
                jsr     _LVOMove(a6)
                move.w  d5,d0
                sub.w   d4,d0
                move.w  d3,d1
                add.w   d6,d1
                jsr     _LVODraw(a6)
                move.w  d5,d0
                add.w   d4,d0
                move.w  d3,d1
                add.w   d6,d1
                jsr     _LVODraw(a6)
                move.w  d5,d0
                move.w  d6,d1
                jsr     _LVODraw(a6)

                ; Fill triangle 
                move.w  d5,d0
                move.w  #TREE_TRIH-1,d1
                add.w   d6,d1
                moveq   #1,d2
                jsr     _LVOFlood(a6)

                add.w   #TREE_VSTEP,d6
                addq    #TREE_HSTEP,d4
                move.l  a4,a1           ; restore rastport
                dbf     d7,.l

                ; White pen
                moveq   #2,d0
                jsr     _LVOSetAPen(a6)

                ; Draw snow
                ; moveq   #0,d6
                move.w  #200,d7
.snow:
                move.w  d6,d0           ; x
                lsl.w   #2,d0
                move.w  d7,d1           ; y
                jsr     _LVOWritePixel(a6)
                add.b   d1,d6           ; increment x with trashed Y value for randomishness
                dbf     d7,.snow

                ; Floor
                movem.w Floor(pc),d1-d3
                jsr     _LVORectFill(a6)

                bra.b   *

; Coordinates:
Floor:
                ; dc.w    0               ; x1
                dc.w    170             ; y1
                dc.w    W               ; x2
                dc.w    H               ; y2
Trunk:
                dc.w    W/2-10          ; x1
                dc.w    150             ; y1
                dc.w    W/2+10          ; x2
                dc.w    170             ; y2

; TmpRas struct
; Use color value for size property!
Tmp:            dc.l    0               ; buffer ptr
Colors:
                dc.w    $000,$0f0,$fff
TmpBuffer:      
                ; Uses header hack on final build
                ifne    BSS
                ds.b    1024*64
                endc

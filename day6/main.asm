                incdir  "../include"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

W = 640
H = 256
SIN_LEN = 64

_start:
                ; BCPL trick to current screen without OpenLibrary
                move.l  $170(a2),a6     ; intuitionbase from globvec
                move.l  ib_ActiveScreen(a6),a5 ; Store pointer to active screen that we're going to hijack
                move.l  $4.w,a6         ; execbase
                move.l  156(a6),a6      ; graphicsbase (ExecBase->IntVects[6].iv_Data)

                lea     Sin(pc),a0
                move.l  a0,a2
PrecalcSin:
                moveq   #0,d0
                move.w  #SIN_LEN/2+1,d2
.sin:           subq    #2,d2
                move.w  d0,d1
                asr.w   #3,d1           ; this determines the amplitude
                move.w  d1,(a0)+
                neg.w   d1
                move.w  d1,SIN_LEN-2(a0)
                add.w   d2,d0
                bne.b   .sin

.frame:
                moveq   #0,d7           ; x pos
                lea     String,a4
                move.w  #64-1,d5        ; screen character width
.l:
                lea     sc_RastPort(a5),a1

                move.w  d7,d0
                move.w  #H/2,d1
                move.w  d4,d6           ; character offset
                add.w   d6,d6
                and.w   #(SIN_LEN-1)*2,d6
                add.w   (a2,d6),d1
                jsr     _LVOMove(a6)

                move.w  d4,d6           ; character offset
                and.w   #$f,d6          ; mod string length
                lea     (a4,d6),a0      ; string ptr
                moveq   #1,d0           ; string length
                jsr     _LVOText(a6)

                addq    #1,d4
                add.w   #10,d7          ; next x
                dbf     d5,.l

                jsr     _LVOWaitTOF(a6)

                ; need to move back before clear
                lea     sc_RastPort(a5),a1
                moveq   #0,d0
                moveq   #0,d1
                jsr     _LVOMove(a6)
                jsr     _LVOClearScreen(a6)

                addq    #1,d4           ; scroll speed
                bra.b   .frame

String:         dc.b    "Tiny Code Xmas! "
Sin:            ds.w    SIN_LEN*2


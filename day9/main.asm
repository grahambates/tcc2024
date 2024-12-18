********************************************************************************
; LSFR
; shift left, xor previous bit 0 with carry
; Produces a looping sequence of numbers. Use these as indexes in scrambled palette order.
;
; 15:  1 1 1 1     start with filled buffer
; 14:  1 1 1 0
; 13:  1 1 0 1 
; 10:  1 0 1 0 
; 05:  0 1 0 1 
; 11:  1 0 1 1 
; 06:  0 1 1 0 
; 12:  1 1 0 0 
; 09:  1 0 0 1 
; 02:  0 0 1 0 
; 04:  0 1 0 0 
; 08:  1 0 0 0 
; 01:  0 0 0 1 
; 03:  0 0 1 1
; 07:  0 1 1 1

; 332/368
                incdir  "../include"
                include "hw.i"
                include "graphics/graphics_lib.i"
                include "graphics/rastport.i"
                include "intuition/screens.i"

BLT_H = 16
BLT_BW = 4

SIN_LEN = 512 
SIN_SHIFT = 7

; Can specify our own display window and screen sizes:
DIW_W = 320
DIW_H = 256
DIW_BW = DIW_W/8

BPLS = 4
SCREEN_W = DIW_W
SCREEN_BW = SCREEN_W/8
SCREEN_H = DIW_H

SCREEN_SIZE = SCREEN_BW*SCREEN_H*(BPLS+1) ; extra bitplane for shift

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
C = bltsize

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
                asr.w   #SIN_SHIFT,d1   ; this determines the amplitude
                move.w  d1,(a0)+
                neg.w   d1
                move.w  d1,SIN_LEN-2(a0)
                add.w   d2,d0
                bne.b   .sin

                lea     custom+C,a6
                ; install copper
                lea     Copper(pc),a1
                move.l  a1,cop1lc-C(a6)

                lea     SCREEN_ADDR,a0

                ; Build palette using table
                ; PalIndexes backwards from Copper address in a1
                lea     color00-C(a6),a2
                lea     bpl0pt-C-4(a6),a3 ; reuse this loop to set upper word of bplXpt
                moveq   #16-1,d7
.col:           move.b  -(a1),d0
                move.w  d7,(a2,d0)      ; write color index, use loop index for blue shade
                move.l  a0,(a3)+        ; write bplpt
                dbf     d7,.col

                move.w  #DMAF_SETCLR!DMAF_BLITHOG,dmacon-C(a6) ; Blitter priority to avoid waits

                ; fill buffer for intial state
                move.w  #$1ff,bltcon0-C(a6)
                clr.w   bltdmod-C(a6)
                move.l  a0,bltdpt-C(a6)
                move.w  #SCREEN_H*3*64+SCREEN_BW,bltsize-C(a6)

                ; moveq   #0,d6           ; frame

Frame:
.vsync:         cmp.b   #$ff,vhposr-C(a6)
                bne.b   .vsync

                lea     (SCREEN_BW*(BPLS+1)*(SCREEN_H-BLT_H)/2)+(SCREEN_BW-BLT_BW)/2(a0),a1 ; src/dest byte offset

                ; x sin
                lea     Sin(pc),a2
                move.w  d6,d0
                mulu    #11,d0
                and.w   #(SIN_LEN-1)*2,d0
                move.w  (a2,d0),d5
                move.w  d5,d2
                asr.w   #4,d2
                add.w   d2,d2
                adda.w  d2,a1

                ; y sin
                move.w  d6,d0
                mulu    #5,d0
                and.w   #(SIN_LEN-1)*2,d0
                move.w  (a2,d0),d0
                mulu    #SCREEN_BW*(BPLS+1),d0
                adda.l  d0,a1

                moveq   #-1,d1
                clr.w   d1              ; #$ffff0000 mask to be shifted
                and.w   #$f,d5
                lsr.l   d5,d1
                move.l  d1,bltafwm-C(a6)

                ; Shift all bpls into tmp:
                move.l  #(SCREEN_BW-BLT_BW)<<16!(SCREEN_BW-BLT_BW),d4
                lea     SCREEN_BW(a1),a2
                lea     BlitTmp(pc),a3
                move.w  #$9f0,bltcon0-C(a6) ; bltcon1 ok?
                move.l  d4,bltamod-C(a6)
                movem.l a2/a3,bltapt-C(a6)
                move.w  #BLT_H*(BPLS+1)*64+BLT_BW/2,bltsize-C(a6)

                ; XOR carry:
                ; b[4] = b[0]~b[3]
                lea     SCREEN_BW*3(a3),a4 ; src b
                lea     SCREEN_BW*4(a3),a5 ; dest
                move.w  #$d3c,bltcon0-C(a6)
                move.w  #(SCREEN_BW*(BPLS+1)-BLT_BW),bltbmod-C(a6)
                move.l  #(SCREEN_BW*(BPLS+1)-BLT_BW)<<16!(SCREEN_BW*(BPLS+1)-BLT_BW),bltamod-C(a6)
                movem.l a3-a5,bltbpt-C(a6)
                move.w  #BLT_H*64+BLT_BW/2,bltsize-C(a6)

                ; Masked copy from tmp
                move.w  #$7ca,bltcon0-C(a6) ; bltcon1 ok?
                move.w  d7,bltadat-C(a6) ; -1 (ish)
                move.l  d4,bltcmod-C(a6)
                move.l  d4,bltamod-C(a6)
                movem.l a1/a3,bltcpt-C(a6)
                move.l  a1,bltdpt-C(a6)
                move.w  #BLT_H*(BPLS+1)*64+BLT_BW/2,bltsize-C(a6)

                addq    #1,d6
                bra     Frame

; Scrambled palette order
PalIndexes:
                dc.b    0,15*2,14*2,13*2,10*2,5*2,11*2,6*2,12*2,9*2,2*2,4*2,8*2,1*2,3*2,7*2

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                ; dc.w    intena,$7fff    ; all interrupts off
                dc.w    diwstrt,DIW_STRT
                dc.w    diwstop,DIW_STOP
                ; dc.w    ddfstrt,DDF_STRT
                ; dc.w    ddfstop,DDF_STOP
                dc.w    bpl0ptl,SCREEN_BW*4
                dc.w    bpl1ptl,SCREEN_BW*3
                dc.w    bpl2ptl,SCREEN_BW*2
                dc.w    bpl3ptl,SCREEN_BW*1
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    bpl1mod,SCREEN_BW*BPLS
                dc.w    bpl2mod,SCREEN_BW*BPLS
                ; dc.w    -1

Sin:            ds.w    SIN_LEN*2
BlitTmp:
                ds.b    SCREEN_SIZE

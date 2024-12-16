********************************************************************************
; Double buffered display using custom RastPort
; Allows use of graphics library draw routines, and custom screen geometry

                incdir  "../include"
                include "hw.i"
                include "graphics/gfxbase.i"
                include "graphics/text.i"

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

FONT_MOD = $c0
FONT_START = $20
FONT_HEIGHT = 8

SIN_LEN = 32

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
                move.l  $4.w,a1         ; execbase
                move.l  156(a1),a1      ; graphics.library

                move.l  gb_TextFonts+LH_HEAD(a1),a1 ; a1 = font
                cmp.w   #8,tf_YSize(a1) ; if the first font is not topaz/8, the next one is, or we fail
                beq.b   .ok
                move.l  (a1),a1
.ok:
                move.l  tf_CharData(a1),a1 ; a1 = font char data

                lea     Sin(pc),a0
PrecalcSin:
                moveq   #0,d0
                move.w  #SIN_LEN/2+1,d2
.sin:           subq    #2,d2
                move.w  d0,d1
                muls    #SCREEN_BW,d1
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
                lea     Copper(pc),a5   ; Also Data ptr for later
                move.l  a5,cop1lc-C(a6)

Frame:
.vsync:         cmp.b   #$ff,vhposr-C(a6)
                bne.b   .vsync

                ; XOR screen buffer pointer to toggle upper word for double buffering
                ; This gives us two 64k aligned buffers, so we only need to change the upper word of the address, and 
                ; can use a fixed value for the lower word in the copper.
                eor.w   #1,(a3)         ; $60000 or $70000

                move.l  (a3),a0         ; a0 = draw buffer

                ; clear
                move.w  #SCREEN_BW*SCREEN_H/4-1,d7
.clr:           clr.l   (a0)+
                dbf     d7,.clr

                ; back to center
                lea     -SCREEN_BW*(SCREEN_H-FONT_HEIGHT)/2(a0),a0

                ;-------------------------------------------------------------------------------
                move.w  d4,d5           ; d5 = char index
                move.w  d4,d3           ; d3 = sin offset
                asr.w   #3,d5
                moveq   #SCREEN_BW-1,d7
.char:
                and.w   #15,d5          ; mod string length
                move.b  Text-Data(a5,d5),d0 ; d0 = ASCII code for current char
                and.w   #(SIN_LEN-1)*2,d3 ; mod sin length
                move.w  Sin-Data(a5,d3),d1 ; d1 = screen offset

                moveq   #FONT_HEIGHT-1,d6
.fontLine:
                move.b  -FONT_START(a1,d0),(a0,d1)
                lea     SCREEN_BW(a0),a0 ; next line in bitplane
                lea     FONT_MOD(a1),a1
                dbf     d6,.fontLine

                lea     1-SCREEN_BW*FONT_HEIGHT(a0),a0 ; next char left and back to top
                lea     -FONT_MOD*FONT_HEIGHT(a1),a1
                addq    #1,d5
                addq    #2,d3
                dbf     d7,.char
                ;-------------------------------------------------------------------------------

                addq    #1,d4           ; inc frame count

                ; CPU sets upper word of bpl ptr to flip buffer
                move.w  (a3),bpl0pt-C(a6)
                bra.b   Frame

Data:

;-------------------------------------------------------------------------------
Copper:
                dc.w    dmacon,DMAF_SPRITE ; sprites off
                dc.w    intena,$7fff    ; all interrupts off
                dc.w    bpl0ptl,SCREEN_ADDR&$ffff ; Copper sets lower word of bpl ptr
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    color00
                ; dc.w    -1


Text:           dc.b    "Tiny code Xmas! "

Sin:            ds.w    SIN_LEN*2

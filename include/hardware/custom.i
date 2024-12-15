                ifnd    HARDWARE_CUSTOM_I
HARDWARE_CUSTOM_I set   1
**
**	$VER: custom.i 39.1 (18.9.1992)
**	Includes Release 45.1
**
**	Offsets of Amiga custom chip registers
**
**	(C) Copyright 1985-2001 Amiga, Inc.
**	    All Rights Reserved
**

*:
* do this to get base of custom registers:
*  XREF _custom;
*:

bltddat         equ     $000
dmaconr         equ     $002
vposr           equ     $004
vhposr          equ     $006
dskdatr         equ     $008
joy0dat         equ     $00a
joy1dat         equ     $00c
clxdat          equ     $00e

adkconr         equ     $010
pot0dat         equ     $012
pot1dat         equ     $014
potinp          equ     $016
serdatr         equ     $018
dskbytr         equ     $01a
intenar         equ     $01c
intreqr         equ     $01e

dskpt           equ     $020
dsklen          equ     $024
dskdat          equ     $026
refptr          equ     $028
vposw           equ     $02a
vhposw          equ     $02c
copcon          equ     $02e
serdat          equ     $030
serper          equ     $032
potgo           equ     $034
joytest         equ     $036
strequ          equ     $038
strvbl          equ     $03a
strhor          equ     $03c
strlong         equ     $03e

bltcon0         equ     $040
bltcon1         equ     $042
bltafwm         equ     $044
bltalwm         equ     $046
bltcpt          equ     $048
bltbpt          equ     $04c
bltapt          equ     $050
bltdpt          equ     $054
bltsize         equ     $058
bltcon0l        equ     $05b            ; note: byte access only
bltsizv         equ     $05c
bltsizh         equ     $05e

bltcmod         equ     $060
bltbmod         equ     $062
bltamod         equ     $064
bltdmod         equ     $066

bltcdat         equ     $070
bltbdat         equ     $072
bltadat         equ     $074

deniseid        equ     $07c
dsksync         equ     $07e

cop1lc          equ     $080
cop2lc          equ     $084
copjmp1         equ     $088
copjmp2         equ     $08a
copins          equ     $08c
diwstrt         equ     $08e
diwstop         equ     $090
ddfstrt         equ     $092
ddfstop         equ     $094
dmacon          equ     $096
clxcon          equ     $098
intena          equ     $09a
intreq          equ     $09c
adkcon          equ     $09e

aud             equ     $0a0
aud0            equ     $0a0
aud1            equ     $0b0
aud2            equ     $0c0
aud3            equ     $0d0

* AudChannel
ac_ptr          equ     $00             ; ptr to start of waveform data
ac_len          equ     $04             ; length of waveform in words
ac_per          equ     $06             ; sample period
ac_vol          equ     $08             ; volume
ac_dat          equ     $0a             ; sample pair
ac_SIZEOF       equ     $10

bplpt           equ     $0e0

bplcon0         equ     $100
bplcon1         equ     $102
bplcon2         equ     $104
bplcon3         equ     $106
bpl1mod         equ     $108
bpl2mod         equ     $10a
bplcon4         equ     $10c
clxcon2         equ     $10e

bpldat          equ     $110

sprpt           equ     $120

spr             equ     $140

* SpriteDef
sd_pos          equ     $00
sd_ctl          equ     $02
sd_dataa        equ     $04
sd_dataB        equ     $06
sd_SIZEOF       equ     $08

color           equ     $180

htotal          equ     $1c0
hsstop          equ     $1c2
hbstrt          equ     $1c4
hbstop          equ     $1c6
vtotal          equ     $1c8
vsstop          equ     $1ca
vbstrt          equ     $1cc
vbstop          equ     $1ce
sprhstrt        equ     $1d0
sprhstop        equ     $1d2
bplhstrt        equ     $1d4
bplhstop        equ     $1d6
hhposw          equ     $1d8
hhposr          equ     $1da
beamcon0        equ     $1dc
hsstrt          equ     $1de
vsstrt          equ     $1e0
hcenter         equ     $1e2
diwhigh         equ     $1e4
fmode           equ     $1fc

                endc                    !HARDWARE_CUSTOM_I

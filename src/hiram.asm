.include	"x16.inc"
.include	"zsm.inc"
.include	"macros.inc"

; IMPORTS / EXPORTS:

.segment "ZEROPAGE"
IMPORT_TAGGED "data"


.segment "CODE"
IMPORT_TAGGED	"stopmusic"
EXPORT_TAGGED	"nextdata"

;-----------------------------------------------------------------------
; nextdata
;
; no args. returns carry flag: 0=no error, 1=error
;
; affects: Accumulator
;
; Advances the ZP pointer "data" by one byte through the HIRAM window.
; It is necessary to call this routine instead of the typical
; (ZP),Y method, as the data pointer could be pointing at the end of
; the bank window at any given time, and if it advances past the end,
; it must be wrapped back to $A000 and the next bank selected.
;

.segment "CODE"
.proc nextdata: near
			; advance the data pointer, with bank-wrap if necessary
			inc	data
			beq	nextpage
			rts				; pointer remained in the same page. Done.
nextpage:	lda data+1		; advance the "page" address
			inc
			cmp	#$c0		; Check for bank wrap.
			bcc nobankwrap
			; bank wrapped.
			lda #$a0		; return to page $a000
			inc RAM_BANK	; bank in the next RAM bank
			inc data + SONGPTR::bank
			
			; TODO: Make this a cmp w/ actual # of avail banks.
			;       (don't assume 2MB of HIRAM installed)
			beq	die			; out-of-memory error
nobankwrap:
			sta	data+1		; store the new "page" address
			clc
			rts				; done
die:
			; stop the music and return error (carry bit = 1)
			jsr stopmusic
			sec
			rts
.endproc

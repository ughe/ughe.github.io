;=======================================================================
; .emacs: The Emacs initialization file.
; Emacs executes this file whenever it is launched.
; Excerpt of COS217 Emacs initialization file relevant to GDB.
;=======================================================================

;-----------------------------------------------------------------------

; Set gud-gdb command to run gdb-multiarch instead of gdb
(defcustom gud-gud-gdb-command-name "gdb-multiarch --fullname"
  "Default command to run an executable under GDB in text command mode.
The option \"--fullname\" must be included in this value."
   :type 'string
   :group 'gud)

;-----------------------------------------------------------------------

; Define gdb as an alias for gud-gdb. See the emacs manual for details.
(defalias 'gdb 'gud-gdb)

;-----------------------------------------------------------------------

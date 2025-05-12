#lang racket
;; lolcat.scm - A Scheme implementation of lolcat
;; 
;; This is a Scheme (Racket) implementation of the popular lolcat utility,
;; which displays text with rainbow colors in the terminal.
;;
;; Usage: racket lolcat.scm [options] [file...]
;;
;; Options:
;;   -p, --spread <f>     Rainbow spread (default: 3.0)
;;   -F, --freq <f>       Rainbow frequency (default: 0.1)
;;   -S, --seed <i>       Rainbow seed, 0 = random (default: 0)
;;   -a, --animate       Enable psychedelics
;;   -d, --duration <i>   Animation duration (default: 12)
;;   -s, --speed <f>      Animation speed (default: 20.0)
;;   -i, --invert         Invert fg and bg
;;   -f, --force          Force color even when stdout is not a tty
;;
;; Examples:
;;   racket lolcat.scm file.txt
;;   racket lolcat.scm -a -p 3.0 -F 0.1 file.txt
;;   cat file.txt | racket lolcat.scm

(require racket/cmdline)
(require racket/port)

;; Generate rainbow RGB values based on frequency and position
(define (rainbow-rgb freq i)
  (let* ((red (inexact->exact (round (+ (* (sin (+ (* freq i) 0)) 127) 128))))
         (green (inexact->exact (round (+ (* (sin (+ (* freq i) (/ (* 2 pi) 3))) 127) 128))))
         (blue (inexact->exact (round (+ (* (sin (+ (* freq i) (/ (* 4 pi) 3))) 127) 128)))))
    (values red green blue)))

;; Convert RGB to hex color string
(define (rgb->hex r g b)
  (format "#~2,'0a~2,'0a~2,'0a" 
          (number->string r 16)
          (number->string g 16)
          (number->string b 16)))

;; Process a single character with color
(define (process-char c i)
  (let-values (((r g b) (rainbow-rgb freq (+ os i))))
    (let ((color-code (format "\033[38;5;~am" (ansi-color-from-rgb r g b))))
      (display color-code)
      (display c)
      (display "\033[0m"))))

;; Process a line of text with rainbow colors
(define (process-line line i)
  (for ([c (in-string line)]
        [j (in-naturals)])
    (process-char c (+ i j)))
  (newline))

;; Process text with animation if enabled
(define (process-text-animated text i)
  (unless (string=? text "")
    (display "\033[7") ;; Save cursor position
    (let ((real-os os))
      (for ([j (in-range duration)])
        (display "\033[8") ;; Restore cursor position
        (set! os (+ os spread))
        (for ([line (string-split text "\n")]
              [k (in-naturals)])
          (process-line line (+ i k)))
        (sleep (/ 1.0 speed)))
      (set! os real-os))))

;; Process text normally (no animation)
(define (process-text text i)
  (for ([line (string-split text "\n")]
        [j (in-naturals)])
    (process-line line (+ i j))))

;; Cat function to read and process file content
(define (cat fd opts)
  ;; Hide cursor if animate is enabled
  (when animate
    (display "\033[?25l"))
  
  (let loop ((buf "") (i 0))
    (let ((chunk (read-bytes 4096 fd)))
      (if (eof-object? chunk)
          (begin
            ;; Show cursor if animate was enabled
            (when animate
              (display "\033[?25h"))
            (void))
          (begin
            (set! buf (string-append buf (bytes->string/utf-8 chunk #\?)))
            
            ;; Process the text
            (if animate
                (process-text-animated buf i)
                (process-text buf i))
            
            (when animate
              (sleep (/ 1.0 speed)))
            (loop "" (+ i (string-length buf))))))))

;; Convert RGB values to ANSI 256-color code
(define (ansi-color-from-rgb r g b)
  (+ 16 (* (quotient r 51) 36) (* (quotient g 51) 6) (quotient b 51)))

;; Function to clear the screen if animation is enabled
(define (maybe-clear-screen)
  (when animate
    (display "\033[2J\033[H")))

(define (process-file file)
  (with-input-from-file file
    (lambda ()
      (cat (current-input-port) '()))))

;; Global variables for configuration
(define os 0)          ;; Color offset
(define spread 3.0)    ;; Rainbow spread
(define freq 0.1)      ;; Rainbow frequency
(define seed 0)        ;; Rainbow seed
(define animate #f)    ;; Enable animation
(define duration 12)   ;; Animation duration
(define speed 20.0)    ;; Animation speed
(define invert #f)     ;; Invert foreground and background
(define force #f)      ;; Force color even when stdout is not a tty

;; Main function to handle command-line arguments and process files
(define (main)
  (define files-to-process
    (command-line
     #:program "lolcat"
     #:once-each
     [("-p" "--spread") spread-arg "Rainbow spread" 
      (set! spread (string->number spread-arg))
      (when (< spread 0.1) (error "spread must be >= 0.1"))]
     [("-F" "--freq") freq-arg "Rainbow frequency" 
      (set! freq (string->number freq-arg))]
     [("-S" "--seed") seed-arg "Rainbow seed, 0 = random" 
      (set! seed (string->number seed-arg))
      (when (= seed 0) (set! seed (random 256)))]
     [("-a" "--animate") "Enable psychedelics" 
      (set! animate #t)]
     [("-d" "--duration") duration-arg "Animation duration" 
      (set! duration (string->number duration-arg))
      (when (< duration 0.1) (error "duration must be >= 0.1"))]
     [("-s" "--speed") speed-arg "Animation speed" 
      (set! speed (string->number speed-arg))
      (when (< speed 0.1) (error "speed must be >= 0.1"))]
     [("-i" "--invert") "Invert fg and bg" 
      (set! invert #t)]
     [("-f" "--force") "Force color even when stdout is not a tty" 
      (set! force #t)]
     #:args files
     (if (null? files) '("-") files)))
  
  ;; Set the os (offset) to seed value
  (set! os seed)
  
  ;; Process each file
  (for-each (lambda (file)
              (if (or (string=? file "-") (string=? file ":stdin"))
                  ;; Process stdin
                  (cat (current-input-port) '())
                  ;; Process file
                  (with-handlers ([(lambda (e) (and (exn:fail? e) (string-contains? (exn-message e) "No such file or directory")))
                                  (lambda (e) (printf "lolcat: ~a: No such file or directory\n" file))]
                                 [(lambda (e) (and (exn:fail? e) (string-contains? (exn-message e) "Permission denied")))
                                  (lambda (e) (printf "lolcat: ~a: Permission denied\n" file))]
                                 [(lambda (e) (and (exn:fail? e) (string-contains? (exn-message e) "is a directory")))
                                  (lambda (e) (printf "lolcat: ~a: Is a directory\n" file))]
                                 [exn:fail?
                                  (lambda (e) (printf "lolcat: ~a: Error reading file\n" file))])
                    (with-input-from-file file
                      (lambda ()
                        (cat (current-input-port) '()))))))
            files-to-process))

;; Call the main function
(main)

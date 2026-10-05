;; Input format: one line containing a string of distinct characters.
;; Run as an R7RS Scheme program. For an empty string, one empty
;; permutation is printed as a blank line.

(import (scheme base)
        (scheme read)
        (scheme write))

(define (insert-everywhere character characters)
  (define (insert-recursively prefix suffix)
    (cons (append (reverse prefix) (cons character suffix))
          (if (null? suffix)
              '()
              (insert-recursively
               (cons (car suffix) prefix)
               (cdr suffix)))))
  (insert-recursively '() characters))

(define (permutations characters)
  (if (null? characters)
      (list '())
      (apply append
             (map (lambda (permutation)
                    (insert-everywhere (car characters) permutation))
                  (permutations (cdr characters))))))

(define input (read-line))

(if (eof-object? input)
    (set! input "")
    #f)

(for-each
 (lambda (permutation)
   (display (list->string permutation))
   (newline))
 (permutations (string->list input)))

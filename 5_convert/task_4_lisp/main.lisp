(defun command-line-arguments ()
  #+sbcl (cdr sb-ext:*posix-argv*)
  #+clisp ext:*args*
  #-(or sbcl clisp) nil)

(defun trim-whitespace (text)
  (string-trim '(#\Space #\Tab #\Newline #\Return) text))

(defun parse-decimal-integer (text)
  (let ((trimmed (trim-whitespace text)))
    (when (> (length trimmed) 0)
      (handler-case
          (multiple-value-bind (number position)
              (parse-integer trimmed :junk-allowed t)
            (when (and number (= position (length trimmed)))
              number))
        (error () nil)))))

(defun signed-representation (number radix)
  (let* ((magnitude (abs number))
         (digits (format nil (if (= radix 2) "~B" "~X") magnitude)))
    (if (minusp number)
        (concatenate 'string "-" digits)
        digits)))

(defun convert-file (input-path output-path)
  (with-open-file (input input-path :direction :input)
    (with-open-file (output output-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (loop for line = (read-line input nil nil)
            for line-number from 1
            while line
            do (let ((number (parse-decimal-integer line)))
                 (if number
                     (format output "~D;~A;~A~%"
                             number
                             (signed-representation number 2)
                             (signed-representation number 16))
                     (format *error-output*
                             "Skipped invalid line ~D: ~A~%"
                             line-number
                             line)))))))

(defun main ()
  (let* ((arguments (command-line-arguments))
         (input-path (if arguments (first arguments) "input.txt"))
         (output-path (if (rest arguments) (second arguments) "output.txt")))
    (convert-file input-path output-path)
    (format t "Conversion completed: ~A~%" output-path)))

(handler-case
    (main)
  (error (condition)
    (format *error-output* "Error: ~A~%" condition)
    #+sbcl (sb-ext:exit :code 1)
    #+clisp (ext:exit 1)))

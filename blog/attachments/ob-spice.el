;;; ob-spice.el --- org-babel functions for spice evaluation

;; Author: Tiago Oliveira Weber
;; Version: 0.5
;; 2016-2018
;; Homepage: http://tiagoweber.github.io

;; Org-Babel support for evaluating spice script.
;; Inspired by Ian Yang's org-export-blocks-format-plantuml (http://www.emacswiki.org/emacs/org-export-blocks-format-plantuml.el)

;;; Requirements:
;; ngspice


;; Updates from version 0.4
;;    use org-babel--get-vars params instead of org-babel-get-header (which is no longer present in org-mode)

;;; Code:
(require 'ob)

(add-to-list 'org-babel-tangle-lang-exts '("spice" . "cir"))

(defun ob-spice-concat (wordlist)
  "Concat elements of a list of string into a string separated by spaces"
  ;; example of usage
  ;; (ob-spice-concat '("This" "is" "a" "long" "journey"))  
  (setq newtext (car wordlist)) ; first word is without space before
  (setq wordlist (rest wordlist)) ; exclude the first word from the list
  (dolist (word wordlist newtext) (setq newtext (concat newtext " " word)) )  ;loop through the list and concatenate the values
  )



(defun org-babel-expand-body:spice (body params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let* (
	 ;;(vars (mapcar #'cdr (org-babel-get-header params :var)))
	 ;;(vars (mapcar #'cdr (org-babel--get-vars params)))
	 (vars (org-babel--get-vars params))
	 )

    (setq newbody "");
    (setq bodylinelist (split-string body "\n"))
    (dolist (line bodylinelist newbody) (progn  ;loop through list of lines
					  (setq wordlist (split-string line " "))
					  (setq firstword 1)
					  (dolist (word wordlist) (progn  ;loop through the words
								    (if (string-match "\\$\\(.*\\)\\[\\(.*\\)\\]" word)
									(progn 
									  ;; if matchs a vector variable format
									  (setq varname (match-string 1 word))
									  (setq varindex (match-string 2 word))
									  ;; search varname in vars and use the value of varindex to word
									  (setq newword (nth (string-to-number varindex)
											   (car
											    (assoc-default varname vars
													   (lambda (key candidate)
													     (string= key candidate))))))

									  (if (not (eq newword nil))
									       (if (not (stringp newword))
										   (setq word (number-to-string newword))
										 (setq word newword)
										 ))
									   )
								      ) ;; end of (if (string-match "\\$\\(.*\\)\\[\\(.*\\)\\]" word))
								    (if (string-match "\\$\\(.*\\)\\." word) ;; if variable has a dot in the end
									(progn
									  ;; if matchs a non-vector variable format
									    (setq varname (match-string 1 word))
									    (setq newword
										  (assoc-default varname vars
												 (lambda (key candidate)
												   (string= key candidate))))
									    (if (not (eq newword nil))
										(progn 
										  (if (not (stringp newword))
										      (setq newword (number-to-string newword)))
										  (setq word (replace-match (concat newword ".")  nil nil word))
										  ;(setq word word)
										  )
									      ))
								      );; end of (if (string-match "\\$\\(.*\\)\\." word)
								    (if (string-match "\\$\\(.*\\)" word)
								    	(progn
								    	  ;; if matchs a non-vector variable format
								    	    (setq varname (match-string 1 word))
								    	    (setq newword
								    		  (assoc-default varname vars
								    				 (lambda (key candidate)
								    				   (string= key candidate))))
								    	    (if (not (eq newword nil))
								    		(if (not (stringp newword))
								    		    (setq word (number-to-string newword))
								    		  (setq word newword)
								    		  ))
								    	    )
								      );; end of (if (string-match "\\$\\(.*\\)" word)

								    
						  (setq newbody (concat newbody
									(if (not (eq firstword 1)) " ")
									word))
						  (setq firstword 0)
						  ) ;; end of (progn
						  ) ;; end of (dolist (word wordlist))
						  
					  (setq newbody (concat newbody "\n"))
					  ) ;; end of (progn ;; loop through list of lines ... )
	    ) ;; end of (dolist (line bodylinelist)  ...function ...)

    ))

(defun org-babel-execute:spice (body params)
  "Execute a block of Spice code with org-babel."
  (let ((body (org-babel-expand-body:spice body params))
	;;(vars (mapcar #'cdr (org-babel-get-header params :var)))

	;;(vars (mapcar #'cdr (org-babel--get-vars params)))
	(vars
	 ;(mapcar #'cdr
	         (org-babel--get-vars params)
	 ;	 )
	 )

	
	)
    
    ;;(isoctave (cdr (car (org-babel-get-header params :isoctave))))
	

    ;;******************************
    ;; CLEAN temporary files
    (mapc (lambda (pair)
	    (when (string= (car pair) "file")
	      (setq textfile (concat (cdr pair) ".txt"))
	      (setq imagefile (concat (cdr pair) ".png"))
	      )
	    )
	  vars)
;;    (if (file-readable-p textfile)    (delete-file textfile))
;;    (if (file-readable-p imagefile)    (delete-file imagefile))
    ;;*******************************

    (if 1;;(eq isoctave nil)
	(let ((exec_string "ngspice -b "))
	  ;;(org-babel-eval "ngspice -b " body)
	  (org-babel-eval exec_string body)
	  (message (concat exec_string body))
	  )
      (let ((exec_string "ngspice_octave tempfile"))
	;;(org-babel-eval "ngspice -b " body)
	(with-temp-file "tempfile"
	  (progn
	    (insert body)
	    )
	  )
	(org-babel-eval exec_string "")
	(message exec_string)
	)
      ) ;; end of if
    
    ;; loop through all pairs (elements) of the list vars and set text and image file if finds "file" var
    (mapc (lambda (pair)
	    (when (string= (car pair) "file")
	      (setq textfile (concat (cdr pair) ".txt"))
	      (setq imagefile (concat (cdr pair) ".png"))	      
	      )
	    )
	  vars)
    ;; produce results
    (makunbound 'result)
    
    ;; THE FOLLOWING WAS COMMENTED TEMPORARILY
    ;; (concat
    ;;  (if (file-readable-p textfile)
    ;; 	 (get-string-from-file textfile))
    ;;  (if (file-readable-p imagefile)
    ;; 	 (concat '"#+ATTR_HTML: :width 600px \n [[file:./" imagefile "]]")
    ;;    )
    ;;  )

    ;; ;; Get measurement values from text-file by splitting comma separated values   
    (if (file-readable-p textfile)
	(progn	  
	  (setq rawtext (get-string-from-file textfile))
	  ;;(setq rawtext (replace-regexp-in-string "\n" "" rawtext))
	  (setq rawtext (replace-regexp-in-string "\n" "" rawtext))
	  (setq result (split-string rawtext ","))
	  )      
      )    
    (if (file-readable-p imagefile)
	(progn
	  ;; test if result exist already
	  (if (boundp 'result)
	      (add-to-list 'result (concat '"[[file:./" imagefile "]]") t)    ;; add imagefile to last entry
	    (setq result (concat '"[[file:./" imagefile "]]")) ;; else
	    )
	    ;;(concat '"[[file:./" imagefile "]]")
	    ;;)  
	  )
      )
  result
    ;; Produce output like     '(test test2)
    ;;'(test test2)
    
    )
  )

(provide 'ob-spice)
;;; ob-spice.el ends here

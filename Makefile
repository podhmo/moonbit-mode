EMACS ?= emacs

.PHONY: test

test:
	$(EMACS) --batch \
	  -l moonbit-mode.el \
	  -l test/test-moonbit-mode.el \
	  -f ert-run-tests-batch-and-exit

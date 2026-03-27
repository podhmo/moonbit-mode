EMACS ?= emacs

.PHONY: test format

test:
	$(EMACS) --batch \
	  -l moonbit-mode.el \
	  -l test/test-moonbit-mode.el \
	  -f ert-run-tests-batch-and-exit

format:
	moon fmt

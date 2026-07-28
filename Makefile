VENV       := .venv
RENDERCV   := $(VENV)/bin/rendercv
RESUME_SRC := resume/resume.yaml
RESUME_PDF := static/resume.pdf

.PHONY: resume serve clean-resume

# Without this, a failed page check leaves the oversized PDF in place and the
# next `make resume` reports success without rebuilding it.
.DELETE_ON_ERROR:

resume: $(RESUME_PDF)

# Hugo watches static/, so a PDF rebuilt mid-session is picked up, but it never
# runs make: editing $(RESUME_SRC) while the server is up leaves the served PDF
# stale until the next `make serve`. --disableFastRender because fast render
# skips pages it believes an edit did not affect.
serve: $(RESUME_PDF)
	hugo server --disableFastRender

$(RENDERCV):
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install --quiet 'rendercv[full]==2.8'

# rendercv resolves --pdf-path and -o relative to the input file, hence the ../
$(RESUME_PDF): $(RESUME_SRC) | $(RENDERCV)
	@mkdir -p $(@D)
	$(RENDERCV) render $(RESUME_SRC) \
		--pdf-path ../$(RESUME_PDF) \
		-o ../build/rendercv \
		-nomd -nohtml -nopng -q
	@pages=$$(pdfinfo $(RESUME_PDF) | awk '/^Pages/{print $$2}'); \
	  [ "$$pages" = "1" ] || { echo "$(RESUME_PDF): $$pages pages, expected 1" >&2; exit 1; }

clean-resume:
	rm -rf build/rendercv $(RESUME_PDF)

VENV        := .venv
RENDERCV    := $(VENV)/bin/rendercv
RESUME_SRC  := resume/resume.yaml
RESUME_PDF  := static/resume.pdf
FAVICON_SVG := assets/favicon.svg
FAVICON_ICO := static/favicon.ico
FAVICON_PNG := $(foreach px,16 32 48,build/favicon/$(px).png)

.PHONY: resume favicon serve clean-resume clean-favicon

# Without this, a failed page check leaves the oversized PDF in place and the
# next `make resume` reports success without rebuilding it.
.DELETE_ON_ERROR:

resume: $(RESUME_PDF)

favicon: $(FAVICON_ICO)

# Hugo watches static/, so a PDF rebuilt mid-session is picked up, but it never
# runs make: editing $(RESUME_SRC) while the server is up leaves the served PDF
# stale until the next `make serve`. --disableFastRender because fast render
# skips pages it believes an edit did not affect.
serve: $(RESUME_PDF) $(FAVICON_ICO)
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

# The head inlines $(FAVICON_SVG), but routes with no head to declare an icon
# (/resume.pdf) send browsers to /favicon.ico, so the same mark ships rasterized.
build/favicon/%.png: $(FAVICON_SVG)
	@mkdir -p $(@D)
	rsvg-convert -w $* -h $* $< -o $@

$(FAVICON_ICO): $(FAVICON_PNG) scripts/pack-ico.py
	@mkdir -p $(@D)
	python3 scripts/pack-ico.py $@ $(FAVICON_PNG)

# The PNGs are a means to the .ico, which is committed. Without this, a clone
# with no build/ rebuilds them (and so needs rsvg-convert) to reach a target
# that is already current.
.INTERMEDIATE: $(FAVICON_PNG)

clean-resume:
	rm -rf build/rendercv $(RESUME_PDF)

clean-favicon:
	rm -rf build/favicon $(FAVICON_ICO)

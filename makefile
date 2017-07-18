## LaTeX Makefile
## define shorthand file names for text
TEXT=./src/HIO_microinjection_protocol
FINALTEXT=HIO_microinjection_protocol

## output to PDF
pdf: $(FINALTEXT).pdf
$(FINALTEXT).pdf: $(TEXT).tex \
	./src/bibliography.bib \
	./results/figure4.pdf \
	./img/figure1.pdf \
	./img/figure2.pdf \
	./img/figure3.pdf
	sed -i 's/{\\bfseries\\sffamily }/{\\sffamily }/g' $(TEXT).tex
	sed -i 's/ / /g' ./src/bibliography.bib #eliminates a common unicode space character bib file
	pdflatex -output-directory src $(TEXT)
	pdflatex -output-directory src $(TEXT)
	cp ./src/bibliography.bib ./
	biber $(TEXT)
	pdflatex -output-directory src $(TEXT)
	pdflatex -output-directory src $(TEXT)
	mv $(TEXT).pdf $(FINALTEXT).pdf
	rm *.bib

## output to DOCX
docx: $(FINALTEXT).docx
$(FINALTEXT).docx: $(TEXT).tex
	cp $(TEXT).tex $(TEXT)_docx_reformat.tex
	sed -i 's/pdf/png/g' $(TEXT)_docx_reformat.tex # use png versions of figures
	sed -i 's/\\(\\kappa\\)/κ/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(\\beta\\)/β/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(\\alpha\\)/α/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(\\mu\\)/μ/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(\\gamma\\)/γ/g' $(TEXT)_docx_reformat.tex
	sed -i 's/{\"i}/ï/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\pm/±/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\num{//g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(_{\\text{2}}\\)/₂/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(^{\\text{2}}\\)/²/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(^{\\text{1}}\\)/¹/g' $(TEXT)_docx_reformat.tex
	sed -i 's/\\(^{\\text{3}}\\)/³/g' $(TEXT)_docx_reformat.tex	
	pandoc --bibliography=./src/bibliography.bib --filter pandoc-citeproc  --csl=./src/nature-no-et-al.csl --number-section $(TEXT)_docx_reformat.tex -o $(FINALTEXT).docx

## unarchive example images
./data/raw_img: ./data/raw_img.tar.gz
	tar -xvzf ./data/raw_img.tar.gz -C ./data/

## image processing
./results/threshold_results.txt: ./src/thresholdmeasure.ijm \
	./data/raw_img \
	./src/imagej-threshold-quant.sh
	cd src && ./imagej-threshold-quant.sh

## R analysis
./results/figure4.pdf: ./src/image_analysis.R ./results/threshold_results.txt
	R -e "setwd('./src/'); source('image_analysis.R')"

.PHONY: clean
clean:
	cd src && rm *.aux *.blg *.out *.bbl *.log

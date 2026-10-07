SRC=	hitachi2
TGT=	19991001-interrim

all:: ${TGT}.pdf

${TGT}.pdf: ${TGT}.ps
	fixeucfont < ${TGT}.ps > tmp.ps
	cjkps2pdf.pl tmp.ps ${TGT}.pdf
	rm -f tmp.ps

${TGT}.ps: ${SRC}.mgp
	mgp2ps -c ${SRC}.mgp > ${TGT}.ps

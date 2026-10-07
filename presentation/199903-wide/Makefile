SRC=	wide
TGT=	19990326-wide

all:: ${TGT}.pdf

${TGT}.pdf: ${TGT}.ps
	fixeucfont < ${TGT}.ps | sed -e "s/Ryumin-Light/GothicBBB-Medium/" > tmp.ps
	cjkps2pdf.pl tmp.ps ${TGT}.pdf
	rm -f tmp.ps

${TGT}.ps: ${SRC}.mgp
	mgp2ps -c ${SRC}.mgp > ${TGT}.ps

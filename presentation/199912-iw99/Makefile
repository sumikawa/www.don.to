SRC=	hitachi
TGT=	19991215-iw99

all:: ${TGT}.pdf

${TGT}.pdf: ${TGT}.ps
	fixeucfont < ${TGT}.ps | sed -e "s/Ryumin-Light/GothicBBB-Medium/" > tmp.ps
	cjkps2pdf.pl tmp.ps ${TGT}.pdf
	rm -f tmp.ps ${TGT}.ps

${TGT}.ps: ${SRC}.mgp
	mgp2ps -c ${SRC}.mgp > ${TGT}.ps

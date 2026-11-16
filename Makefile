target/release/xyrrhak: src/main.asm web/khesh.css web/xyrrhak.woff web/vyrr.js web/khaarn.html web/hrrghaz.html web/skrath.html web/vhess.html web/vrrshkal.html
	mkdir -p target/release
	nasm -f elf64 -o target/release/xyrrhak.o src/main.asm
	ld -s -static -o $@ target/release/xyrrhak.o

clean:
	rm -f target/release/xyrrhak target/release/xyrrhak.o

.PHONY: clean

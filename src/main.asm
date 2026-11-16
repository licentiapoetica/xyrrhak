default rel
bits 64

%define MAXV 8192
%define REC 4480
%define R_SIZE 0
%define R_MT 8
%define R_UP 16
%define R_EXT 24
%define R_FLEN 32
%define R_PLEN 40
%define R_IDLEN 48
%define R_NMLEN 56
%define R_ID 64
%define R_NM 96
%define R_FN 128
%define R_PATH 384

%macro S 2+
%1: db %2
%1_len equ $ - %1
%endmacro

%macro BIN 2
%1: incbin %2
%1_len equ $ - %1
%endmacro

%macro PUT 1
    lea rsi, [%1]
    mov ecx, %1_len
    rep movsb
%endmacro

%macro JWS 2
    cmp %1, 32
    je %2
    lea r11d, [%1 - 9]
    cmp r11d, 4
    jbe %2
%endmacro

%macro LOWER 1
    lea r11d, [%1 - 'A']
    cmp r11d, 25
    ja %%s
    add %1, 32
%%s:
%endmacro

%macro ROUTE 2
    cmp r13, %1_len
    jne %%n
    mov rdi, r12
    lea rsi, [%1]
    mov edx, %1_len
    call memeq
    test eax, eax
    jnz %2
%%n:
%endmacro

%macro PAGE 2
    lea rdi, [%1]
    mov esi, %1_len
    lea rdx, [%2]
    mov ecx, %2_len
    lea r8, [pbuf]
    call page
%endmacro

%macro SENDHTML 1
    lea r8, [pbuf]
    mov r9, rax
    sub r9, r8
    lea rdi, [%1]
    mov esi, %1_len
    lea rdx, [ct_html]
    mov ecx, ct_html_len
    call send
%endmacro

%macro EXTRA 1
    lea rax, [%1]
    mov [xp], rax
    mov qword [xl], %1_len
%endmacro

section .rodata

BIN tpl_css, "web/khesh.css"
BIN font, "web/xyrrhak.woff"
BIN js, "web/vyrr.js"
BIN tpl_layout, "web/khaarn.html"
BIN tpl_video, "web/hrrghaz.html"
BIN tpl_empty, "web/skrath.html"
BIN tpl_vhess, "web/vhess.html"
BIN tpl_nf, "web/vrrshkal.html"

S s_videos, "videos", 0
S s_defaddr, "127.0.0.1:8080"
S s_localhost, "localhost"
S s_serving, "xyrrhak: serving "
S s_on, " on http://"
S s_cannot, "cannot listen on "
S s_badaddr, "invalid socket address"
S s_e98, "Address already in use"
S s_e13, "Permission denied"
S s_e99, "Cannot assign requested address"
S s_oserr, "os error "
S s_oserr2, " (os error "
S s_procfd, "/proc/self/fd/"
S s_empty, 0
S s_webm, "webm"
S s_mp4, "mp4"
S s_range, "range"
S s_bytes, "bytes="
S s_get, "GET"
S s_head, "HEAD"
S s_slash, "/"
S s_405, "405"
S s_404, "404"

S s_http, "HTTP/1.1 "
S s_ctype, 13, 10, "Content-Type: "
S s_clen, 13, 10, "Content-Length: "
S s_close, 13, 10, "Connection: close", 13, 10
S s_ar, 13, 10, "Accept-Ranges: bytes", 13, 10, "Connection: close", 13, 10
S s_allow, "Allow: GET, HEAD", 13, 10
S s_cache, "Cache-Control: public, max-age=31536000, immutable", 13, 10
S s_loc, "Location: /v/"
S s_nostore, 13, 10, "Cache-Control: no-store", 13, 10
S s_crange, "Content-Range: bytes "

S st200, "200 OK"
S st206, "206 Partial Content"
S st302, "302 Found"
S st404, "404 Not Found"
S st405, "405 Method Not Allowed"
S st416, "416 Range Not Satisfiable"

S ct_html, "text/html; charset=utf-8"
S ct_css, "text/css; charset=utf-8"
S ct_font, "font/woff"
S ct_js, "text/javascript; charset=utf-8"
S ct_plain, "text/plain"
S mime_webm, "video/webm"
S mime_mp4, "video/mp4"

S r_css, "/khesh.css"
S r_font, "/xyrrhak.woff"
S r_js, "/vyrr.js"
S r_vhess, "/vhess"
S r_root, "/"
S r_ksh, "/kshvaar"
S r_v, "/v/"
S r_f, "/f/"

S t_vhess, "vhess"
S t_empty, "skra'th"
S t_nf, "vrrsh'kal"

S s_kss, " kss"
S s_mhss, " mhss"
S s_ghss, " ghss"

S e_amp, "&amp;"
S e_lt, "&lt;"
S e_gt, "&gt;"
S e_quot, "&quot;"
S e_apos, "&#39;"

S k_khor, "khor"
S k_ssukh, "ssukh"
S k_dhrum, "dhrum"
S k_kheshdrun, "kheshdrun"
S k_kaidrun, "kaidrun"
S k_vyrrdrun, "vyrrdrun"
S k_ssa, "ssa"
S k_ssahak, "ssahak"
S k_ssyr, "ssyr"
S k_thruk, "thruk"
S k_zhaal, "zhaal"
S k_vraakith, "vraakith"
S k_ssen, "ssen"
S k_thal, "thal"

hexd: db "0123456789abcdef"

onsets: db 2,"kh",0, 2,"vr",0, 2,"sk",0, 2,"th",0, 2,"zh",0, 2,"hr",0, 2,"ks",0, 2,"ss",0
        db 2,"gh",0, 2,"dr",0, 1,"x",0,0, 1,"v",0,0, 1,"k",0,0, 1,"z",0,0, 1,"h",0,0, 2,"sh",0
nuclei: db 1,"a",0,0, 2,"aa",0, 2,"ae",0, 1,"i",0,0, 1,"o",0,0, 1,"u",0,0, 1,"y",0,0, 1,"e",0,0
codas:  db 0,0,0,0, 1,"r",0,0, 2,"rr",0, 1,"k",0,0, 2,"sh",0, 2,"th",0, 1,"l",0,0, 1,"z",0,0

ts100: dq 0, 100000000

section .data

curbuf: dq scanA
lastbuf: dq scanB
curp: dq pA
lastp: dq pB
sigact: dq 1, 0, 0, 0
one: dd 1
tv60: dq 60, 0
sa: dw 2
sa_port: dw 0
sa_addr: dd 0
        dq 0
pfd: dd 0
     dw 1, 0

ctab:
    dq k_kaidrun, k_kaidrun_len, fonth, 8

ptab:
    dq k_khor, k_khor_len, ttlbuf, 0
    dq k_ssukh, k_ssukh_len, ttlbuf, 0
    dq k_dhrum, k_dhrum_len, 0, 0
    dq k_kheshdrun, k_kheshdrun_len, cssh, 8
    dq k_kaidrun, k_kaidrun_len, fonth, 8
    dq k_vyrrdrun, k_vyrrdrun_len, jsh, 8

vtab:
    dq k_ssa, k_ssa_len, 0, 0
    dq k_ssahak, k_ssahak_len, 0, 0
    dq k_ssyr, k_ssyr_len, 0, 0
    dq k_thruk, k_thruk_len, 0, 0
    dq k_zhaal, k_zhaal_len, 0, 0
    dq k_vraakith, k_vraakith_len, szbuf, 0
    dq k_ssen, k_ssen_len, n1buf, 0
    dq k_thal, k_thal_len, n2buf, 0

section .bss

alignb 16
scanA: resb MAXV*REC
scanB: resb MAXV*REC
sigr: resb MAXV*REC
pA: resq MAXV
pB: resq MAXV
readyp: resq MAXV
idxp: resq MAXV
poolp: resq MAXV
dents: resb 65536
pathbuf: resb 8192
procbuf: resb 64
stx: resb 256
stbuf: resb 256
numtmp: resb 32
reqbuf: resb 16384
obuf: resb 262144
pbuf: resb 131072
cbuf: resb 65536
cssbuf: resb 16384
ttlbuf: resb 512
szbuf: resb 32
n1buf: resb 32
n2buf: resb 32
xbuf: resb 256
fonth: resb 8
cssh: resb 8
jsh: resb 8
ts: resq 2
dirp: resq 1
dirl: resq 1
addrp: resq 1
addrl: resq 1
lfd: resq 1
cfd: resq 1
active: resq 1
nextscan: resq 1
curn: resq 1
lastn: resq 1
sign: resq 1
nvid: resq 1
efd: resq 1
rp: resq 1
cssl: resq 1
meth_p: resq 1
meth_l: resq 1
tgt_p: resq 1
tgt_l: resq 1
rng_set: resq 1
rng_p: resq 1
rng_l: resq 1
not_set: resq 1
not_p: resq 1
not_l: resq 1
xp: resq 1
xl: resq 1
stl: resq 1
off: resq 1
pa: resq 1
rnd: resq 1
head: resb 1

section .text
global _start

_start:
    mov r12, [rsp]
    lea r13, [rsp+8]
    lea rax, [s_videos]
    mov [dirp], rax
    mov qword [dirl], s_videos_len - 1
    lea rax, [s_defaddr]
    mov [addrp], rax
    mov qword [addrl], s_defaddr_len
    cmp r12, 2
    jb .args
    mov rdi, [r13+8]
    mov [dirp], rdi
    call strlen
    mov [dirl], rax
    cmp r12, 3
    jb .args
    mov rdi, [r13+16]
    mov [addrp], rdi
    call strlen
    mov [addrl], rax
.args:
    mov edi, 13
    lea rsi, [sigact]
    xor edx, edx
    mov r10d, 8
    mov eax, 13
    syscall

    mov rcx, [dirl]
    cmp rcx, 4000
    ja .mkdone
    lea rdi, [pathbuf]
    mov rsi, [dirp]
    rep movsb
    mov byte [rdi], 0
    lea rbx, [pathbuf]
    mov r12, [dirl]
    mov r13, 1
.mk:
    cmp r13, r12
    jae .mklast
    cmp byte [rbx+r13], '/'
    jne .mknext
    mov byte [rbx+r13], 0
    mov rdi, rbx
    mov esi, 511
    mov eax, 83
    syscall
    mov byte [rbx+r13], '/'
.mknext:
    inc r13
    jmp .mk
.mklast:
    mov rdi, rbx
    mov esi, 511
    mov eax, 83
    syscall
.mkdone:

    lea rdi, [font]
    mov esi, font_len
    lea rdx, [fonth]
    call hashstr
    lea rdi, [js]
    mov esi, js_len
    lea rdx, [jsh]
    call hashstr
    lea rdi, [tpl_css]
    mov esi, tpl_css_len
    lea rdx, [ctab]
    mov ecx, 1
    lea r8, [cssbuf]
    call render
    lea rsi, [cssbuf]
    sub rax, rsi
    mov [cssl], rax
    lea rdi, [cssbuf]
    mov rsi, rax
    lea rdx, [cssh]
    call hashstr

    call parse_addr
    test rax, rax
    js listen_fail
    mov edi, 2
    mov esi, 0x80001
    xor edx, edx
    mov eax, 41
    syscall
    test rax, rax
    js listen_fail
    mov [lfd], rax
    mov rdi, rax
    mov esi, 1
    mov edx, 2
    lea r10, [one]
    mov r8d, 4
    mov eax, 54
    syscall
    mov rdi, [lfd]
    lea rsi, [sa]
    mov edx, 16
    mov eax, 49
    syscall
    test rax, rax
    js listen_fail
    mov rdi, [lfd]
    mov esi, 128
    mov eax, 50
    syscall
    test rax, rax
    js listen_fail

    lea rdi, [obuf]
    PUT s_serving
    mov rsi, [dirp]
    mov rcx, [dirl]
    rep movsb
    PUT s_on
    mov rsi, [addrp]
    mov rcx, [addrl]
    rep movsb
    mov byte [rdi], 10
    inc rdi
    lea rsi, [obuf]
    mov rdx, rdi
    sub rdx, rsi
    mov edi, 1
    mov eax, 1
    syscall

    mov edi, 1
    call poll
    call now_ms
    add rax, 250
    mov [nextscan], rax
    mov rax, [lfd]
    mov [pfd], eax

mainloop:
    call now_ms
    cmp rax, [nextscan]
    jl .reap
    xor edi, edi
    call poll
    call now_ms
    add rax, 250
    mov [nextscan], rax
.reap:
    mov rdi, -1
    xor esi, esi
    mov edx, 1
    xor r10d, r10d
    mov eax, 61
    syscall
    test rax, rax
    jle .reaped
    dec qword [active]
    jmp .reap
.reaped:
    call now_ms
    mov rdx, [nextscan]
    sub rdx, rax
    jge .wait
    xor edx, edx
.wait:
    lea rdi, [pfd]
    mov esi, 1
    mov eax, 7
    syscall
    test rax, rax
    jle mainloop
    mov rdi, [lfd]
    xor esi, esi
    xor edx, edx
    mov r10d, 0x80000
    mov eax, 288
    syscall
    test rax, rax
    js .afail
    mov rbx, rax
    cmp qword [active], 256
    jae .drop
    mov eax, 57
    syscall
    test rax, rax
    jz child
    js .drop
    inc qword [active]
.drop:
    mov rdi, rbx
    mov eax, 3
    syscall
    jmp mainloop
.afail:
    lea rdi, [ts100]
    xor esi, esi
    mov eax, 35
    syscall
    jmp mainloop

listen_fail:
    neg rax
    mov rbx, rax
    lea rdi, [obuf]
    PUT s_cannot
    mov rsi, [addrp]
    mov rcx, [addrl]
    rep movsb
    mov word [rdi], ': '
    add rdi, 2
    cmp rbx, 1
    jne .e98
    PUT s_badaddr
    jmp .out
.e98:
    cmp rbx, 98
    jne .e13
    PUT s_e98
    jmp .num
.e13:
    cmp rbx, 13
    jne .e99
    PUT s_e13
    jmp .num
.e99:
    cmp rbx, 99
    jne .eany
    PUT s_e99
.num:
    PUT s_oserr2
    mov rax, rbx
    call utoa
    mov byte [rdi], ')'
    inc rdi
    jmp .out
.eany:
    PUT s_oserr
    mov rax, rbx
    call utoa
.out:
    mov byte [rdi], 10
    inc rdi
    lea rsi, [obuf]
    mov rdx, rdi
    sub rdx, rsi
    mov edi, 2
    mov eax, 1
    syscall
    mov edi, 1
    mov eax, 231
    syscall

parse_addr:
    mov rsi, [addrp]
    mov rcx, [addrl]
    mov rdx, rcx
.fc:
    test rdx, rdx
    jz .bad
    dec rdx
    cmp byte [rsi+rdx], ':'
    jne .fc
    lea rdi, [rsi+rdx+1]
    mov r8, rcx
    sub r8, rdx
    dec r8
    jz .bad
    cmp r8, 5
    ja .bad
    xor eax, eax
.pd:
    movzx r9d, byte [rdi]
    sub r9d, '0'
    cmp r9d, 9
    ja .bad
    imul eax, eax, 10
    add eax, r9d
    inc rdi
    dec r8
    jnz .pd
    cmp eax, 65535
    ja .bad
    xchg al, ah
    mov [sa_port], ax
    cmp rdx, s_localhost_len
    jne .ip
    push rsi
    push rdx
    mov rdi, rsi
    lea rsi, [s_localhost]
    call memeq
    pop rdx
    pop rsi
    test eax, eax
    jz .ip
    mov dword [sa_addr], 0x0100007f
    xor eax, eax
    ret
.ip:
    xor r10d, r10d
    mov rdi, rsi
    lea r11, [rsi+rdx]
.oct:
    xor r8d, r8d
    xor r9d, r9d
.od:
    cmp rdi, r11
    jae .oend
    movzx ecx, byte [rdi]
    cmp ecx, '.'
    je .oend
    sub ecx, '0'
    cmp ecx, 9
    ja .bad
    imul r8d, r8d, 10
    add r8d, ecx
    inc r9d
    cmp r9d, 3
    ja .bad
    inc rdi
    jmp .od
.oend:
    test r9d, r9d
    jz .bad
    cmp r8d, 255
    ja .bad
    lea rcx, [sa_addr]
    mov [rcx+r10], r8b
    inc r10d
    cmp rdi, r11
    jae .odone
    inc rdi
    cmp r10d, 4
    jae .bad
    jmp .oct
.odone:
    cmp r10d, 4
    jne .bad
    xor eax, eax
    ret
.bad:
    mov rax, -1
    ret

now_ms:
    mov edi, 1
    lea rsi, [ts]
    mov eax, 228
    syscall
    mov rax, [ts+8]
    xor edx, edx
    mov ecx, 1000000
    div rcx
    mov rcx, [ts]
    imul rcx, rcx, 1000
    add rax, rcx
    ret

strlen:
    mov rax, rdi
.l:
    cmp byte [rax], 0
    je .d
    inc rax
    jmp .l
.d:
    sub rax, rdi
    ret

memeq:
    mov rcx, rdx
    mov eax, 1
    test rcx, rcx
    jz .r
    repe cmpsb
    sete al
.r:
    ret

lexcmp:
    mov r8, rcx
    sub r8, rdx
    cmp rcx, rdx
    cmova rcx, rdx
    test rcx, rcx
    jz .len
    repe cmpsb
    je .len
    movzx eax, byte [rdi-1]
    movzx edx, byte [rsi-1]
    sub rax, rdx
    ret
.len:
    mov rax, r8
    ret

cmp_name:
    mov rdx, [rsi+R_FLEN]
    lea rsi, [rsi+R_FN]
    mov rcx, [rdi+R_FLEN]
    lea rdi, [rdi+R_FN]
    jmp lexcmp

cmp_up:
    mov rax, [rdi+R_UP]
    cmp rax, [rsi+R_UP]
    jl .lt
    jg .gt
    mov rcx, [rdi+R_IDLEN]
    mov rdx, [rsi+R_IDLEN]
    lea rdi, [rdi+R_ID]
    lea rsi, [rsi+R_ID]
    jmp lexcmp
.lt:
    mov rax, -1
    ret
.gt:
    mov eax, 1
    ret

sortp:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov rbp, rsi
    mov r12, rdx
    mov rax, rbp
    xor edx, edx
    mov ecx, 3
    div rcx
    mov r14, rax
    mov r13, 1
.hl:
    cmp r13, r14
    jae .gap
    lea r13, [r13+r13*2+1]
    jmp .hl
.gap:
    mov r14, r13
.il:
    cmp r14, rbp
    jae .nexth
    mov rax, [rbx+r14*8]
    mov [rsp], rax
    mov r15, r14
.jl:
    cmp r15, r13
    jb .put
    mov rax, r15
    sub rax, r13
    mov rdi, [rbx+rax*8]
    mov rsi, [rsp]
    call r12
    test rax, rax
    jle .put
    mov rax, r15
    sub rax, r13
    mov rcx, [rbx+rax*8]
    mov [rbx+r15*8], rcx
    mov r15, rax
    jmp .jl
.put:
    mov rax, [rsp]
    mov [rbx+r15*8], rax
    inc r14
    jmp .il
.nexth:
    cmp r13, 1
    je .done
    lea rax, [r13-1]
    xor edx, edx
    mov ecx, 3
    div rcx
    mov r13, rax
    jmp .gap
.done:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

fnv:
    mov rax, 0xcbf29ce484222325
    mov rcx, 0x100000001b3
    test rsi, rsi
    jz .d
.l:
    movzx edx, byte [rdi]
    xor rax, rdx
    imul rax, rcx
    inc rdi
    dec rsi
    jnz .l
.d:
    ret

mix:
    mov rdx, rax
    shr rdx, 30
    xor rax, rdx
    mov rdx, 0xbf58476d1ce4e5b9
    imul rax, rdx
    mov rdx, rax
    shr rdx, 27
    xor rax, rdx
    mov rdx, 0x94d049bb133111eb
    imul rax, rdx
    mov rdx, rax
    shr rdx, 31
    xor rax, rdx
    ret

hex8:
    mov ecx, 8
.l:
    rol eax, 4
    mov edx, eax
    and edx, 15
    lea rsi, [hexd]
    movzx edx, byte [rsi+rdx]
    mov [rdi], dl
    inc rdi
    dec ecx
    jnz .l
    ret

hashstr:
    push rdx
    call fnv
    mov rdx, rax
    shr rdx, 32
    xor rax, rdx
    pop rdi
    jmp hex8

utoa:
    lea r8, [numtmp+24]
    mov rcx, r8
    mov r9d, 10
.l:
    xor edx, edx
    div r9
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .l
    mov rsi, rcx
    mov rcx, r8
    sub rcx, rsi
    rep movsb
    ret

vext:
    mov rcx, rsi
.f:
    test rcx, rcx
    jz .no
    dec rcx
    cmp byte [rdi+rcx], '.'
    jne .f
    test rcx, rcx
    jz .no
    lea r8, [rdi+rcx+1]
    sub rsi, rcx
    dec rsi
    cmp rsi, 4
    je .w
    cmp rsi, 3
    jne .no
    mov eax, 1
    lea r9, [s_mp4]
    jmp .cmp
.w:
    xor eax, eax
    lea r9, [s_webm]
.cmp:
    xor ecx, ecx
.c:
    movzx edx, byte [r8+rcx]
    LOWER edx
    cmp dl, [r9+rcx]
    jne .no
    inc rcx
    cmp rcx, rsi
    jb .c
    ret
.no:
    mov rax, -1
    ret

basename:
    lea rax, [rdi+rsi]
    mov rcx, rax
.l:
    cmp rcx, rdi
    je .d
    cmp byte [rcx-1], '/'
    je .d
    dec rcx
    jmp .l
.d:
    mov rdi, rcx
    mov rsi, rax
    sub rsi, rcx
    ret

scan:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov qword [curn], 0
    mov rdi, [dirp]
    mov esi, 0x90000
    mov eax, 2
    syscall
    test rax, rax
    js .ret
    mov r15, rax
.rd:
    mov rdi, r15
    lea rsi, [dents]
    mov edx, 65536
    mov eax, 217
    syscall
    test rax, rax
    jle .close
    lea rbx, [dents]
    lea rbp, [rbx+rax]
.ent:
    cmp rbx, rbp
    jae .rd
    movzx eax, word [rbx+16]
    lea r14, [rbx+rax]
    cmp qword [curn], MAXV
    jae .next
    lea r12, [rbx+19]
    mov rdi, r12
    call strlen
    mov r13, rax
    cmp r13, 255
    ja .next
    mov rcx, [dirl]
    cmp rcx, 3800
    ja .next
    mov rdi, r12
    mov rsi, r13
    call vext
    test rax, rax
    js .next
    mov rcx, [curn]
    imul rcx, rcx, REC
    add rcx, [curbuf]
    mov [rp], rcx
    mov [rcx+R_EXT], rax
    mov [rcx+R_FLEN], r13
    lea rdi, [rcx+R_FN]
    mov rsi, r12
    mov rcx, r13
    rep movsb
    mov byte [rdi], 0
    lea rdi, [pathbuf]
    mov rsi, [dirp]
    mov rcx, [dirl]
    rep movsb
    mov byte [rdi], '/'
    inc rdi
    mov rsi, r12
    mov rcx, r13
    rep movsb
    mov byte [rdi], 0
    lea rdi, [pathbuf]
    mov esi, 0x280000
    mov eax, 2
    syscall
    test rax, rax
    js .next
    mov [efd], rax
    lea rdi, [procbuf]
    PUT s_procfd
    mov rax, [efd]
    call utoa
    mov byte [rdi], 0
    mov rdx, [rp]
    lea rdi, [procbuf]
    lea rsi, [rdx+R_PATH]
    mov edx, 4095
    mov eax, 89
    syscall
    test rax, rax
    jle .cl
    mov rdx, [rp]
    mov [rdx+R_PLEN], rax
    mov byte [rdx+R_PATH+rax], 0
    lea rdi, [rdx+R_PATH]
    mov rsi, rax
    call basename
    call vext
    mov rdx, [rp]
    cmp rax, [rdx+R_EXT]
    jne .cl
    mov rdi, [efd]
    lea rsi, [s_empty]
    mov edx, 0x1000
    mov r10d, 0xfff
    lea r8, [stx]
    mov eax, 332
    syscall
    test rax, rax
    jnz .cl
    movzx eax, word [stx+28]
    and eax, 0xf000
    cmp eax, 0x8000
    jne .cl
    mov rdx, [rp]
    mov rax, [stx+40]
    mov [rdx+R_SIZE], rax
    mov rax, [stx+112]
    imul rax, rax, 1000000000
    mov ecx, [stx+120]
    add rax, rcx
    mov [rdx+R_MT], rax
    mov r8, rax
    test dword [stx], 0x800
    jz .nob
    mov rax, [stx+80]
    imul rax, rax, 1000000000
    mov ecx, [stx+88]
    add rax, rcx
    mov r8, rax
.nob:
    mov [rdx+R_UP], r8
    mov rcx, [curn]
    mov rax, [curp]
    mov [rax+rcx*8], rdx
    inc qword [curn]
.cl:
    mov rdi, [efd]
    mov eax, 3
    syscall
.next:
    mov rbx, r14
    jmp .ent
.close:
    mov rdi, r15
    mov eax, 3
    syscall
.ret:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

poll:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r15d, edi
    call scan
    mov rdi, [curp]
    mov rsi, [curn]
    lea rdx, [cmp_name]
    call sortp
    xor r12d, r12d
    xor r13d, r13d
    xor r14d, r14d
.l:
    cmp r12, [curn]
    jae .ld
    mov rax, [curp]
    mov rbx, [rax+r12*8]
    test r15d, r15d
    jnz .stable
.adv:
    cmp r13, [lastn]
    jae .unst
    mov rax, [lastp]
    mov rbp, [rax+r13*8]
    mov rdi, rbp
    mov rsi, rbx
    call cmp_name
    test rax, rax
    js .advj
    jnz .unst
    mov rax, [rbp+R_SIZE]
    cmp rax, [rbx+R_SIZE]
    jne .unst
    mov rax, [rbp+R_MT]
    cmp rax, [rbx+R_MT]
    jne .unst
    jmp .stable
.advj:
    inc r13
    jmp .adv
.stable:
    cmp qword [rbx+R_SIZE], 0
    je .unst
    lea rax, [readyp]
    mov [rax+r14*8], rbx
    inc r14
.unst:
    inc r12
    jmp .l
.ld:
    mov rax, [curbuf]
    mov rcx, [lastbuf]
    mov [curbuf], rcx
    mov [lastbuf], rax
    mov rax, [curp]
    mov rcx, [lastp]
    mov [curp], rcx
    mov [lastp], rax
    mov rax, [curn]
    mov [lastn], rax
    test r15d, r15d
    jnz .rebuild
    cmp r14, [sign]
    jne .rebuild
    xor r12d, r12d
.sc:
    cmp r12, r14
    jae .same
    lea rax, [readyp]
    mov rdi, [rax+r12*8]
    mov rsi, r12
    imul rsi, rsi, REC
    lea rax, [sigr]
    add rsi, rax
    mov rax, [rdi+R_SIZE]
    cmp rax, [rsi+R_SIZE]
    jne .rebuild
    mov rax, [rdi+R_MT]
    cmp rax, [rsi+R_MT]
    jne .rebuild
    mov rax, [rdi+R_UP]
    cmp rax, [rsi+R_UP]
    jne .rebuild
    call cmp_name
    test rax, rax
    jnz .rebuild
    inc r12
    jmp .sc
.same:
    xor eax, eax
    jmp .ret
.rebuild:
    xor r12d, r12d
.cp:
    cmp r12, r14
    jae .cpd
    lea rax, [readyp]
    mov rsi, [rax+r12*8]
    mov rdi, r12
    imul rdi, rdi, REC
    lea rax, [sigr]
    add rdi, rax
    mov ecx, R_PATH + 1
    add rcx, [rsi+R_PLEN]
    rep movsb
    inc r12
    jmp .cp
.cpd:
    mov [sign], r14
    call build
    mov eax, 1
.ret:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

putpart:
    movzx ecx, byte [rsi]
    test ecx, ecx
    jz .d
    inc rsi
.l:
    mov dl, [rsi]
    mov [rdi], dl
    mov [r8], dl
    inc rsi
    inc rdi
    inc r8
    dec ecx
    jnz .l
.d:
    ret

genname:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    lea rdi, [rbx+R_FN]
    mov rsi, [rbx+R_FLEN]
    call fnv
    mov rcx, 0x9e3779b97f4a7c15
    imul rcx, r12
    add rax, rcx
    call mix
    lea rdi, [rbx+R_ID]
    lea r8, [rbx+R_NM]
    mov r9d, 3
.p:
    mov rdx, rax
    and edx, 15
    lea rcx, [onsets]
    lea rsi, [rcx+rdx*4]
    call putpart
    mov rdx, rax
    shr rdx, 4
    and edx, 7
    lea rcx, [nuclei]
    lea rsi, [rcx+rdx*4]
    call putpart
    mov rdx, rax
    shr rdx, 7
    and edx, 7
    lea rcx, [codas]
    lea rsi, [rcx+rdx*4]
    call putpart
    shr rax, 10
    dec r9d
    jz .d
    mov byte [r8], 39
    inc r8
    jmp .p
.d:
    lea rcx, [rbx+R_ID]
    sub rdi, rcx
    mov [rbx+R_IDLEN], rdi
    lea rcx, [rbx+R_NM]
    sub r8, rcx
    mov [rbx+R_NMLEN], r8
    add rsp, 8
    pop r12
    pop rbx
    ret

build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    xor r12d, r12d
.l:
    cmp r12, [sign]
    jae .sort
    mov rbx, r12
    imul rbx, rbx, REC
    lea rax, [sigr]
    add rbx, rax
    xor r13d, r13d
.try:
    mov rdi, rbx
    mov rsi, r13
    call genname
    xor r14d, r14d
    lea r15, [sigr]
.u:
    cmp r14, r12
    jae .ok
    mov rcx, [rbx+R_IDLEN]
    cmp rcx, [r15+R_IDLEN]
    jne .un
    lea rsi, [rbx+R_ID]
    lea rdi, [r15+R_ID]
    repe cmpsb
    je .dup
.un:
    inc r14
    add r15, REC
    jmp .u
.dup:
    inc r13
    jmp .try
.ok:
    lea rax, [idxp]
    mov [rax+r12*8], rbx
    inc r12
    jmp .l
.sort:
    mov rsi, [sign]
    mov [nvid], rsi
    lea rdi, [idxp]
    lea rdx, [cmp_up]
    call sortp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

render:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    lea rbp, [rdi+rsi]
    mov r12, rdx
    shl rcx, 5
    lea r13, [rdx+rcx]
    mov rdi, r8
.loop:
    mov rsi, rbx
.f1:
    lea rax, [rsi+1]
    cmp rax, rbp
    jae .tail
    cmp word [rsi], '{{'
    je .open
    inc rsi
    jmp .f1
.open:
    mov r14, rsi
    mov rcx, rsi
    sub rcx, rbx
    mov rsi, rbx
    rep movsb
    lea r15, [r14+2]
    mov rsi, r15
.f2:
    lea rax, [rsi+1]
    cmp rax, rbp
    jae .unclosed
    cmp word [rsi], '}}'
    je .close
    inc rsi
    jmp .f2
.unclosed:
    mov rbx, r14
    jmp .tail
.close:
    mov r8, rsi
    mov r9, r15
    mov r10, r8
.t1:
    cmp r9, r10
    jae .tdone
    movzx eax, byte [r9]
    JWS eax, .t1i
    jmp .t3
.t1i:
    inc r9
    jmp .t1
.t3:
    movzx eax, byte [r10-1]
    JWS eax, .t3d
    jmp .tdone
.t3d:
    dec r10
    jmp .t3
.tdone:
    sub r10, r9
    push rdi
    mov r11, r12
.vl:
    cmp r11, r13
    jae .vnone
    cmp [r11+8], r10
    jne .vnext
    mov rsi, [r11]
    mov rdi, r9
    mov rcx, r10
    test rcx, rcx
    jz .vhit
    repe cmpsb
    je .vhit
.vnext:
    add r11, 32
    jmp .vl
.vhit:
    pop rdi
    mov rsi, [r11+16]
    mov rcx, [r11+24]
    rep movsb
    jmp .after
.vnone:
    pop rdi
    mov rsi, r14
    lea rcx, [r8+2]
    sub rcx, r14
    rep movsb
.after:
    lea rbx, [r8+2]
    jmp .loop
.tail:
    mov rsi, rbx
    mov rcx, rbp
    sub rcx, rbx
    rep movsb
    mov rax, rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

esc:
    mov rax, rdx
    lea r8, [rdi+rsi]
.l:
    cmp rdi, r8
    jae .d
    movzx ecx, byte [rdi]
    inc rdi
    lea rsi, [e_amp]
    mov edx, e_amp_len
    cmp cl, '&'
    je .p
    lea rsi, [e_lt]
    mov edx, e_lt_len
    cmp cl, '<'
    je .p
    lea rsi, [e_gt]
    cmp cl, '>'
    je .p
    lea rsi, [e_quot]
    mov edx, e_quot_len
    cmp cl, '"'
    je .p
    lea rsi, [e_apos]
    mov edx, e_apos_len
    cmp cl, 39
    je .p
    mov [rax], cl
    inc rax
    jmp .l
.p:
    movzx ecx, byte [rsi]
    mov [rax], cl
    inc rsi
    inc rax
    dec edx
    jnz .p
    jmp .l
.d:
    ret

page:
    push rbx
    push r12
    push r13
    mov rbx, rdx
    mov r12, rcx
    mov r13, r8
    lea rdx, [ttlbuf]
    call esc
    lea rcx, [ttlbuf]
    sub rax, rcx
    mov [ptab+24], rax
    mov [ptab+64+16], rbx
    mov [ptab+64+24], r12
    lea rdi, [tpl_layout]
    mov esi, tpl_layout_len
    lea rdx, [ptab]
    mov ecx, 6
    mov r8, r13
    call render
    pop r13
    pop r12
    pop rbx
    ret

fmtsize:
    cmp rax, 1 << 30
    jae .g
    cmp rax, 1 << 20
    jb .k
    mov ecx, 10
    mul rcx
    mov r8, rax
    and r8, 0xfffff
    shrd rax, rdx, 20
    cmp r8, 0x80000
    jb .m1
    ja .mup
    test al, 1
    jz .m1
.mup:
    inc rax
.m1:
    xor edx, edx
    mov ecx, 10
    div rcx
    push rdx
    call utoa
    mov byte [rdi], '.'
    inc rdi
    pop rax
    add al, '0'
    stosb
    PUT s_mhss
    ret
.g:
    mov ecx, 100
    mul rcx
    mov r8, rax
    and r8, 0x3fffffff
    shrd rax, rdx, 30
    cmp r8, 0x20000000
    jb .g1
    ja .gup
    test al, 1
    jz .g1
.gup:
    inc rax
.g1:
    xor edx, edx
    mov ecx, 100
    div rcx
    push rdx
    call utoa
    mov byte [rdi], '.'
    inc rdi
    pop rax
    mov cl, 10
    div cl
    add al, '0'
    add ah, '0'
    mov [rdi], al
    mov [rdi+1], ah
    add rdi, 2
    PUT s_ghss
    ret
.k:
    add rax, 1023
    shr rax, 10
    call utoa
    PUT s_kss
    ret

vpage:
    push rbx
    push r12
    push r13
    mov r12, rdi
    lea rax, [idxp]
    mov rbx, [rax+r12*8]
    lea rax, [rbx+R_ID]
    mov [vtab+16], rax
    mov rax, [rbx+R_IDLEN]
    mov [vtab+24], rax
    lea rax, [rbx+R_NM]
    mov [vtab+48], rax
    mov rax, [rbx+R_NMLEN]
    mov [vtab+56], rax
    lea rax, [s_webm]
    mov ecx, s_webm_len
    lea rdx, [s_mp4]
    mov esi, s_mp4_len
    cmp qword [rbx+R_EXT], 0
    cmovne rax, rdx
    cmovne ecx, esi
    mov [vtab+80], rax
    mov [vtab+88], rcx
    mov rax, r12
    add rax, [nvid]
    dec rax
    xor edx, edx
    div qword [nvid]
    lea rax, [idxp]
    mov rax, [rax+rdx*8]
    lea rcx, [rax+R_ID]
    mov [vtab+112], rcx
    mov rcx, [rax+R_IDLEN]
    mov [vtab+120], rcx
    lea rax, [r12+1]
    xor edx, edx
    div qword [nvid]
    lea rax, [idxp]
    mov rax, [rax+rdx*8]
    lea rcx, [rax+R_ID]
    mov [vtab+144], rcx
    mov rcx, [rax+R_IDLEN]
    mov [vtab+152], rcx
    mov rax, [rbx+R_SIZE]
    lea rdi, [szbuf]
    call fmtsize
    lea rax, [szbuf]
    sub rdi, rax
    mov [vtab+184], rdi
    lea rax, [r12+1]
    lea rdi, [n1buf]
    call utoa
    lea rax, [n1buf]
    sub rdi, rax
    mov [vtab+216], rdi
    mov rax, [nvid]
    lea rdi, [n2buf]
    call utoa
    lea rax, [n2buf]
    sub rdi, rax
    mov [vtab+248], rdi
    lea rdi, [tpl_video]
    mov esi, tpl_video_len
    lea rdx, [vtab]
    mov ecx, 8
    lea r8, [cbuf]
    call render
    lea rcx, [cbuf]
    sub rax, rcx
    lea rdi, [rbx+R_NM]
    mov rsi, [rbx+R_NMLEN]
    lea rdx, [cbuf]
    mov rcx, rax
    lea r8, [pbuf]
    call page
    pop r13
    pop r12
    pop rbx
    ret

findid:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    xor ebx, ebx
.l:
    cmp rbx, [nvid]
    jae .no
    lea rax, [idxp]
    mov rax, [rax+rbx*8]
    cmp r13, [rax+R_IDLEN]
    jne .n
    lea rdi, [rax+R_ID]
    mov rsi, r12
    mov rdx, r13
    call memeq
    test eax, eax
    jnz .y
.n:
    inc rbx
    jmp .l
.y:
    mov rax, rbx
    jmp .r
.no:
    mov rax, -1
.r:
    pop r13
    pop r12
    pop rbx
    ret

writeall:
.l:
    test rdx, rdx
    jz .d
    mov eax, 1
    syscall
    test rax, rax
    jle cexit
    add rsi, rax
    sub rdx, rax
    jmp .l
.d:
    ret

send:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov rbp, r9
    lea rdi, [obuf]
    PUT s_http
    mov rsi, rbx
    mov rcx, r12
    rep movsb
    PUT s_ctype
    mov rsi, r13
    mov rcx, r14
    rep movsb
    PUT s_clen
    mov rax, rbp
    call utoa
    PUT s_close
    mov rsi, [xp]
    mov rcx, [xl]
    rep movsb
    mov word [rdi], 0x0a0d
    add rdi, 2
    cmp byte [head], 0
    jne .w
    mov rsi, r15
    mov rcx, rbp
    rep movsb
.w:
    lea rsi, [obuf]
    mov rdx, rdi
    sub rdx, rsi
    mov rdi, [cfd]
    call writeall
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

lineend:
    mov rax, rdi
.l:
    cmp rax, r12
    jae .d
    cmp byte [rax], 10
    je .d
    inc rax
    jmp .l
.d:
    ret

trim:
.a:
    cmp rsi, rdx
    jae .d
    movzx eax, byte [rsi]
    JWS eax, .ai
.b:
    movzx eax, byte [rdx-1]
    JWS eax, .bd
    ret
.ai:
    inc rsi
    jmp .a
.bd:
    dec rdx
    jmp .b
.d:
    ret

parsereq:
    push rbx
    push r12
    push r13
    lea rbx, [reqbuf]
    lea r12, [rbx+rdi]
    mov qword [rng_set], 0
    mov rdi, rbx
    call lineend
    mov r13, rax
    mov rsi, rbx
    call .skipws
    mov [meth_p], rsi
    call .skipnws
    mov rax, rsi
    sub rax, [meth_p]
    mov [meth_l], rax
    call .skipws
    mov [tgt_p], rsi
    call .skipnws
    mov rax, rsi
    sub rax, [tgt_p]
    mov [tgt_l], rax
    jnz .hdrs
    lea rax, [s_slash]
    mov [tgt_p], rax
    mov qword [tgt_l], 1
.hdrs:
    cmp r13, r12
    jae .inc
    lea rbx, [r13+1]
.hl:
    cmp rbx, r12
    jae .inc
    mov rdi, rbx
    call lineend
    mov r13, rax
    mov rcx, r13
.te:
    cmp rcx, rbx
    jbe .empty
    movzx eax, byte [rcx-1]
    JWS eax, .ted
    jmp .full
.ted:
    dec rcx
    jmp .te
.empty:
    cmp r13, r12
    jae .inc
    mov eax, 1
    jmp .ret
.full:
    mov rdi, rbx
.fc:
    cmp rdi, rcx
    jae .nextline
    cmp byte [rdi], ':'
    je .colon
    inc rdi
    jmp .fc
.colon:
    mov rsi, rbx
    mov rdx, rdi
    call trim
    mov rax, rdx
    sub rax, rsi
    cmp rax, s_range_len
    jne .nextline
    xor r8d, r8d
.ci:
    movzx eax, byte [rsi+r8]
    LOWER eax
    lea r9, [s_range]
    cmp al, [r9+r8]
    jne .nextline
    inc r8
    cmp r8, s_range_len
    jb .ci
    lea rsi, [rdi+1]
    mov rdx, rcx
    call trim
    mov [rng_p], rsi
    sub rdx, rsi
    mov [rng_l], rdx
    mov qword [rng_set], 1
.nextline:
    lea rbx, [r13+1]
    jmp .hl
.inc:
    xor eax, eax
.ret:
    pop r13
    pop r12
    pop rbx
    ret
.skipws:
    cmp rsi, r13
    jae .sd
    movzx eax, byte [rsi]
    JWS eax, .si
    ret
.si:
    inc rsi
    jmp .skipws
.skipnws:
    cmp rsi, r13
    jae .sd
    movzx eax, byte [rsi]
    JWS eax, .sd
    inc rsi
    jmp .skipnws
.sd:
    ret

pu64:
    cmp rdi, rsi
    jae .e
    cmp byte [rdi], '+'
    jne .s
    inc rdi
    cmp rdi, rsi
    jae .e
.s:
    xor eax, eax
.l:
    movzx ecx, byte [rdi]
    sub ecx, '0'
    cmp ecx, 9
    ja .e
    mov edx, 10
    mul rdx
    jc .e
    add rax, rcx
    jc .e
    inc rdi
    cmp rdi, rsi
    jb .l
    clc
    ret
.e:
    stc
    ret

prange:
    cmp qword [rng_set], 0
    je .full
    mov rsi, [rng_p]
    mov rcx, [rng_l]
    cmp rcx, s_bytes_len
    jb .full
    lea r9, [rsi+rcx]
    lea r8, [rsi+s_bytes_len]
    mov rdi, rsi
    lea rsi, [s_bytes]
    mov edx, s_bytes_len
    call memeq
    test eax, eax
    jz .full
    mov rax, r8
.c:
    cmp rax, r9
    jae .cd
    cmp byte [rax], ','
    je .cut
    inc rax
    jmp .c
.cut:
    mov r9, rax
.cd:
    mov rsi, r8
    mov rdx, r9
    call trim
    mov r8, rsi
    mov r9, rdx
    mov rax, r8
.dsh:
    cmp rax, r9
    jae .full
    cmp byte [rax], '-'
    je .dd
    inc rax
    jmp .dsh
.dd:
    mov r10, rax
    test r13, r13
    jz .bad
    cmp r10, r8
    jne .astart
    lea rdi, [r10+1]
    mov rsi, r9
    call pu64
    jc .full
    test rax, rax
    jz .bad
    mov rdx, r13
    sub rdx, rax
    jae .s1
    xor edx, edx
.s1:
    lea rcx, [r13-1]
    jmp .chk
.astart:
    mov rdi, r8
    mov rsi, r10
    call pu64
    jc .full
    mov [pa], rax
    lea rdi, [r10+1]
    lea rcx, [r13-1]
    cmp rdi, r9
    je .ae
    mov rsi, r9
    call pu64
    jc .full
    lea rcx, [r13-1]
    cmp rax, rcx
    cmovb rcx, rax
.ae:
    mov rdx, [pa]
.chk:
    cmp rdx, rcx
    ja .bad
    cmp rdx, r13
    jae .bad
    mov eax, 1
    ret
.full:
    xor eax, eax
    ret
.bad:
    mov eax, 2
    ret

serve:
    mov rbx, rdi
    lea rdi, [rbx+R_PATH]
    mov esi, 0x80000
    mov eax, 2
    syscall
    test rax, rax
    js cexit
    mov r12, rax
    mov rdi, r12
    lea rsi, [stbuf]
    mov eax, 5
    syscall
    test rax, rax
    js cexit
    mov r13, [stbuf+48]
    call prange
    cmp eax, 2
    je .bad
    mov qword [xl], 0
    test eax, eax
    jnz .part
    xor r14d, r14d
    mov rbp, r13
    lea r15, [st200]
    mov qword [stl], st200_len
    jmp .hdr
.part:
    mov r14, rdx
    mov rbp, rcx
    sub rbp, rdx
    inc rbp
    push rcx
    push rcx
    lea rdi, [xbuf]
    PUT s_crange
    mov rax, r14
    call utoa
    mov byte [rdi], '-'
    inc rdi
    pop rax
    pop rax
    call utoa
    mov byte [rdi], '/'
    inc rdi
    mov rax, r13
    call utoa
    mov word [rdi], 0x0a0d
    add rdi, 2
    lea rax, [xbuf]
    mov [xp], rax
    sub rdi, rax
    mov [xl], rdi
    lea r15, [st206]
    mov qword [stl], st206_len
.hdr:
    lea rdi, [obuf]
    PUT s_http
    mov rsi, r15
    mov rcx, [stl]
    rep movsb
    PUT s_ctype
    lea rsi, [mime_webm]
    mov ecx, mime_webm_len
    cmp qword [rbx+R_EXT], 0
    je .mm
    lea rsi, [mime_mp4]
    mov ecx, mime_mp4_len
.mm:
    rep movsb
    PUT s_clen
    mov rax, rbp
    call utoa
    PUT s_ar
    mov rsi, [xp]
    mov rcx, [xl]
    rep movsb
    mov word [rdi], 0x0a0d
    add rdi, 2
    lea rsi, [obuf]
    mov rdx, rdi
    sub rdx, rsi
    mov rdi, [cfd]
    call writeall
    cmp byte [head], 0
    jne cexit
    mov [off], r14
.sf:
    test rbp, rbp
    jz cexit
    mov rdi, [cfd]
    mov rsi, r12
    lea rdx, [off]
    mov r10, rbp
    mov eax, 0x40000000
    cmp r10, rax
    cmova r10, rax
    mov eax, 40
    syscall
    test rax, rax
    jle cexit
    sub rbp, rax
    jmp .sf
.bad:
    lea rdi, [xbuf]
    PUT s_crange
    mov word [rdi], '*/'
    add rdi, 2
    mov rax, r13
    call utoa
    mov word [rdi], 0x0a0d
    add rdi, 2
    lea rax, [xbuf]
    mov [xp], rax
    sub rdi, rax
    mov [xl], rdi
    lea rdi, [st416]
    mov esi, st416_len
    lea rdx, [ct_plain]
    mov ecx, ct_plain_len
    lea r8, [xbuf]
    xor r9d, r9d
    call send
    jmp cexit

cexit:
    xor edi, edi
    mov eax, 231
    syscall

child:
    mov [cfd], rbx
    mov rdi, [lfd]
    mov eax, 3
    syscall
    mov edi, 10
    mov eax, 37
    syscall
    mov rdi, [cfd]
    mov esi, 1
    mov edx, 21
    lea r10, [tv60]
    mov r8d, 16
    mov eax, 54
    syscall
    xor r12d, r12d
.rl:
    mov rdi, [cfd]
    lea rsi, [reqbuf]
    add rsi, r12
    mov edx, 16384
    sub rdx, r12
    xor eax, eax
    syscall
    test rax, rax
    js cexit
    jz .eof
    add r12, rax
    mov rdi, r12
    call parsereq
    test eax, eax
    jnz .got
    cmp r12, 16384
    jb .rl
.eof:
    mov rdi, r12
    call parsereq
.got:
    xor edi, edi
    mov eax, 37
    syscall
    mov byte [head], 0
    mov qword [xl], 0
    mov r12, [meth_p]
    mov r13, [meth_l]
    cmp r13, 3
    jne .h4
    mov rdi, r12
    lea rsi, [s_get]
    mov edx, 3
    call memeq
    test eax, eax
    jnz .mok
    jmp .m405
.h4:
    cmp r13, 4
    jne .m405
    mov rdi, r12
    lea rsi, [s_head]
    mov edx, 4
    call memeq
    test eax, eax
    jz .m405
    mov byte [head], 1
    jmp .mok
.m405:
    EXTRA s_allow
    lea rdi, [st405]
    mov esi, st405_len
    lea rdx, [ct_plain]
    mov ecx, ct_plain_len
    lea r8, [s_405]
    mov r9d, s_405_len
    call send
    jmp cexit
.mok:
    mov r12, [tgt_p]
    mov rcx, [tgt_l]
    lea r14, [r12+rcx]
    mov rax, r12
.q:
    cmp rax, r14
    jae .nq
    cmp byte [rax], '?'
    je .hq
    inc rax
    jmp .q
.nq:
    mov r13, rcx
    xor r15d, r15d
    jmp .route
.hq:
    mov r13, rax
    sub r13, r12
    lea rdx, [rax+1]
    mov r15, r14
    sub r15, rdx
    mov r14, rdx
.route:
    ROUTE r_css, .css
    ROUTE r_font, .font
    ROUTE r_js, .js
    ROUTE r_vhess, .vhess
    ROUTE r_root, .rand
    ROUTE r_ksh, .rand
    cmp r13, 3
    jb .nf
    mov rdi, r12
    lea rsi, [r_v]
    mov edx, 3
    call memeq
    test eax, eax
    jnz .vid
    mov rdi, r12
    lea rsi, [r_f]
    mov edx, 3
    call memeq
    test eax, eax
    jnz .file
.nf:
    PAGE t_nf, tpl_nf
    SENDHTML st404
    jmp cexit
.css:
    EXTRA s_cache
    lea rdi, [st200]
    mov esi, st200_len
    lea rdx, [ct_css]
    mov ecx, ct_css_len
    lea r8, [cssbuf]
    mov r9, [cssl]
    call send
    jmp cexit
.font:
    EXTRA s_cache
    lea rdi, [st200]
    mov esi, st200_len
    lea rdx, [ct_font]
    mov ecx, ct_font_len
    lea r8, [font]
    mov r9d, font_len
    call send
    jmp cexit
.js:
    EXTRA s_cache
    lea rdi, [st200]
    mov esi, st200_len
    lea rdx, [ct_js]
    mov ecx, ct_js_len
    lea r8, [js]
    mov r9d, js_len
    call send
    jmp cexit
.vhess:
    PAGE t_vhess, tpl_vhess
    SENDHTML st200
    jmp cexit
.rand:
    mov qword [not_set], 0
    mov rsi, r14
    lea r9, [r14+r15]
.pc:
    mov rax, rsi
.pe:
    cmp rax, r9
    jae .pend
    cmp byte [rax], '&'
    je .pend
    inc rax
    jmp .pe
.pend:
    mov rdx, rax
    sub rdx, rsi
    cmp rdx, 4
    jb .pn
    cmp dword [rsi], 'not='
    jne .pn
    lea rcx, [rsi+4]
    mov [not_p], rcx
    sub rdx, 4
    mov [not_l], rdx
    mov qword [not_set], 1
    jmp .pool
.pn:
    cmp rax, r9
    jae .pool
    lea rsi, [rax+1]
    jmp .pc
.pool:
    xor ebx, ebx
    xor r12d, r12d
.pl:
    cmp rbx, [nvid]
    jae .pd
    lea rax, [idxp]
    mov r13, [rax+rbx*8]
    cmp qword [not_set], 0
    je .padd
    mov rdx, [not_l]
    cmp rdx, [r13+R_IDLEN]
    jne .padd
    lea rdi, [r13+R_ID]
    mov rsi, [not_p]
    call memeq
    test eax, eax
    jnz .pskip
.padd:
    lea rax, [poolp]
    mov [rax+r12*8], r13
    inc r12
.pskip:
    inc rbx
    jmp .pl
.pd:
    test r12, r12
    jnz .pick
    mov r12, [nvid]
    test r12, r12
    jz .empty
    lea rsi, [idxp]
    lea rdi, [poolp]
    mov rcx, r12
    rep movsq
.pick:
    lea rdi, [rnd]
    mov esi, 8
    xor edx, edx
    mov eax, 318
    syscall
    cmp rax, 8
    je .rok
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [rnd], rax
.rok:
    mov rax, [rnd]
    xor edx, edx
    div r12
    lea rax, [poolp]
    mov rbx, [rax+rdx*8]
    lea rdi, [xbuf]
    PUT s_loc
    lea rsi, [rbx+R_ID]
    mov rcx, [rbx+R_IDLEN]
    rep movsb
    PUT s_nostore
    lea rax, [xbuf]
    mov [xp], rax
    sub rdi, rax
    mov [xl], rdi
    lea rdi, [st302]
    mov esi, st302_len
    lea rdx, [ct_plain]
    mov ecx, ct_plain_len
    lea r8, [xbuf]
    xor r9d, r9d
    call send
    jmp cexit
.empty:
    PAGE t_empty, tpl_empty
    SENDHTML st200
    jmp cexit
.vid:
    lea rdi, [r12+3]
    lea rsi, [r13-3]
    call findid
    test rax, rax
    js .nf
    mov rdi, rax
    call vpage
    SENDHTML st200
    jmp cexit
.file:
    lea rdi, [r12+3]
    lea rcx, [r12+r13]
    mov rax, rdi
.fd:
    cmp rax, rcx
    jae .fdd
    cmp byte [rax], '.'
    je .fdd
    inc rax
    jmp .fd
.fdd:
    mov rsi, rax
    sub rsi, rdi
    call findid
    test rax, rax
    js .f404
    lea rcx, [idxp]
    mov rdi, [rcx+rax*8]
    call serve
    jmp cexit
.f404:
    lea rdi, [st404]
    mov esi, st404_len
    lea rdx, [ct_plain]
    mov ecx, ct_plain_len
    lea r8, [s_404]
    mov r9d, s_404_len
    call send
    jmp cexit

unit fli2;

interface

procedure show_fli(spd:word);

implementation
uses dos,crt,drk_vga,drk_pcx;
type start_struc=record
      startx:word;starty:byte;
      stopx:word;stopy:byte;
      bytes:word;
     end;
     {8 bytes}
     com_struc=record
      startx:word;starty:byte;
      stopx:word;stopy:byte;
      bytes:word;
      bc: word;
     end;
type buf_struc=record
      s:word;
      l:byte
     end;
var s: start_struc;
    t: array[1..75] of com_struc;
    f: file of start_struc;
    i: file of com_struc;
    g: file of byte;
    h,j: file;
    a:string;c,z:word;
    buf: array[0..14000] of byte;
    com: array[0..6000] of byte;
    {mem}
    m1,m2,m3,m4:pointer;
    ind:word;
    buf_ind:byte;
    cur_buf:word;
    change: array[1..5] of buf_struc;
    idc: string[54];
    k,k1,k2: com_struc;
const id:string[54]='K-Boom vid file,format by M.Richtarsky,anim by unknown';

procedure show_vid2(spd:word);
var bb,e,f,a,b,d,a1,b1,d1: word;
    m:byte;
    s1,s2: word;

procedure decompress_com;
var b: word;

begin
b:=t[z].bc;
asm
 mov si, offset com
 mov di, offset buf
 xor bx, bx
 xor ch, ch
 mov dx,[b]
@loop:
 mov al, [si+bx]
 cmp al, 253
 je @sp
 mov [di], al
 inc bx
 inc di
 dec dx
 jnz @loop
 jmp @end
@sp:
 mov al, [si+bx+1]
 mov cl, [si+bx+2]
 add bx, 3
 rep stosb
 sub dx, 3
 jnz @loop
@end:
end;
end;

begin
k.startx:=0;k.stopx:=0;k.starty:=0;k.stopy:=0;
s1:=16000;s2:=0;
buf_ind:=1;
for z:=1 to 75 do begin
 if change[buf_ind].l=z then begin
  cur_buf:=change[buf_ind].s;
  ind:=0;
  inc(buf_ind);
 end;
 k2:=k1;
 k1:=k;
 k:=t[z];
 asm
  push ds
  mov si, offset k
  add si, 8
  mov cx, [si]
  mov si, ind
  mov di, offset com
  mov ax, ds
  mov es, ax
  mov ax, cur_buf
  mov ds, ax
  shr cx, 1
  jnc @w
  movsb
 @w:
  rep movsw
  pop ds
 end;
 move(mem[cur_buf:ind],com[0],k.bc);
 ind:=ind+k.bc;
 decompress_com;
 a:=k2.starty*320+k2.startx;
 b:=k2.stopx-k2.startx+1;
 d:=k2.stopy-k2.starty;

 a1:=k.starty*320+k.startx;
 {startofs}
 b1:=k.stopx-k.startx+1;
 bb:=b1;
 {width}
 d1:=k.stopy-k.starty;
 {height}
 port[$3c4]:=2;
 port[$3c5]:=$f;
 asm
  mov ax, $a000
  mov es, ax
  mov di, a
  shr di, 2
  add di, s1
  mov dx, 320
  sub dx, [b]
  shr dx, 2
  xor ax, ax
  mov bx, [b]
  shr bx, 2
 @ll:
  mov cx, bx
  shr cx, 1
  jnc @t
  stosb
 @t:
  rep stosw
  add di, dx
  dec [d]
  jnz @ll
  mov m, 1
  mov cx, a1
  and cx, 3
  shl m, cl

  mov ax, $a000
  mov es, ax
  mov si, offset buf
  mov di, s1
  mov ax, [a1]
  shr ax, 2
  add di, ax
  mov dx, $3c4
  mov al, 2
  out dx, al
  mov al, m
  and al, 15
  inc dx
  out dx, al
  mov bx, [d1]

  mov dx, 320
  sub dx, [bb]
  shr dx, 2
  mov cx, [bb]
  shr cx, 2
  push cx
 @l:
  movsb
  add si, 3
  dec cx
  jnz @l
  pop cx
  push cx
  add di, dx
  dec bx
  jnz @l
  pop cx

  shl m, 1
  and m, 15
  cmp m, 0
  jne @w1
  inc m
  add a1, 4
 @w1:
  mov si, offset buf
  inc si
  mov di, s1
  mov ax, [a1]
  shr ax, 2
  add di, ax
  mov dx, $3c4
  mov al, 2
  out dx, al
  mov al, m
  and al, 15
  inc dx
  out dx, al
  mov bx, [d1]

  mov dx, 320
  sub dx, [bb]
  shr dx, 2
  mov cx, [bb]
  shr cx, 2
  push cx
 @l1:
  movsb
  add si, 3
  dec cx
  jnz @l1
  pop cx
  push cx
  add di, dx
  dec bx
  jnz @l1
  pop cx

  shl m, 1
  and m, 15
  cmp m, 0
  jne @w2
  inc m
  add a1, 4
 @w2:
  mov si, offset buf
  add si, 2
  mov di, s1
  mov ax, [a1]
  shr ax, 2
  add di, ax
  mov dx, $3c4
  mov al, 2
  out dx, al
  mov al, m
  and al, 15
  inc dx
  out dx, al
  mov bx, [d1]

  mov dx, 320
  sub dx, [bb]
  shr dx, 2
  mov cx, [bb]
  shr cx, 2
  push cx
 @l2:
  movsb
  add si, 3
  dec cx
  jnz @l2
  pop cx
  push cx
  add di, dx
  dec bx
  jnz @l2
  pop cx

  shl m, 1
  and m, 15
  cmp m, 0
  jne @w3
  inc m
  add a1, 4
 @w3:
  mov si, offset buf
  add si, 3
  mov di, s1
  mov ax, [a1]
  shr ax, 2
  add di, ax
  mov dx, $3c4
  mov al, 2
  out dx, al
  mov al, m
  and al, 15
  inc dx
  out dx, al
  mov bx, [d1]

  mov dx, 320
  sub dx, [bb]
  shr dx, 2
  mov cx, [bb]
  shr cx, 2
  push cx
 @l3:
  movsb
  add si, 3
  dec cx
  jnz @l3
  pop cx
  push cx
  add di, dx
  dec bx
  jnz @l3
  pop cx
end;
 set_start(s1);
 if spd>0 then begin
  delay(spd);
  waitretrace;
 end;
 asm
  push s1
  push s2
  pop s1
  pop s2
 end;
end;
end;

procedure show_fli(spd:word);
begin
getmem(m1,65000);change[1].s:=seg(m1^);
getmem(m2,65000);change[2].s:=seg(m2^);
getmem(m3,65000);change[3].s:=seg(m3^);
getmem(m4,65000);change[4].s:=seg(m4^);
change[1].l:=1;
change[2].l:=16;
change[3].l:=27;
change[4].l:=45;
change[5].l:=255;
setmode($13);
port[$3c4]:=4;port[$3c5]:=port[$3c5] and not $08;
port[$3d4]:=$14;port[$3d5]:=port[$3d5] and not $40;
port[$3d4]:=$17;port[$3d5]:=port[$3d5] or $40;
fillchar(mem[$a000:0],$ffff,0);
assign(h,'fish.dat');
reset(h,1);
{check id}
blockread(h,idc[1],54);
idc[0]:=chr(54);
if idc<>id then exit;
{pal}
blockread(h,buf[0],768);
for c:=0 to 255 do
 setreg(c,buf[c*3],buf[c*3+1],buf[c*3+2]);
{data ids}
for c:=1 to 75 do
 blockread(h,t[c],10);
{data}
buf_ind:=1;
for c:=1 to 75 do begin
 if change[buf_ind].l=c then begin
  cur_buf:=change[buf_ind].s;
  inc(buf_ind);
  ind:=0;
 end;
 blockread(h,mem[cur_buf:ind],t[c].bc);
 ind:=ind+t[c].bc;
end;
close(h);
show_vid2(spd);
end;

begin
end.
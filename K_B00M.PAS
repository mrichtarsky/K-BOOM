unit k_b00m;

interface
procedure setmode(mode: word);
procedure waitretrace;
procedure setreg (dacreg,r,g,b: byte);
procedure getreg (dacreg: byte; var r,g,b: byte);
procedure setpix_13h (x,y: word;col: byte;dest:word);
function getpix_13h (x,y,dest: word):byte;
procedure line_13h(x1,y1,x2,y2:word;color:byte;base:word);
procedure clear_13h (col: byte;dest:word);
procedure loadpcx(n:string;e:word);
procedure fadeout;
procedure show64(n:string;d:word);

const m=10000;
type pal_struc = array[0..255,1..3] of byte;
var d:array[1..m] of byte;
    c: pal_struc;
const keycodes: array[1..102] of string[12]=
      (('Escape'),
       ('1'),
       ('2'),
       ('3'),
       ('4'),
       ('5'),
       ('6'),
       ('7'),
       ('8'),
       ('9'),
       ('0'),
       ('á'),
       ('`'),
       ('Backspace'),
       ('Tab'),
       ('Q'),
       ('W'),
       ('E'),
       ('R'),
       ('T'),
       ('Z'),
       ('U'),
       ('I'),
       ('O'),
       ('P'),
       ('š'),
       ('+'),
       ('Enter'),
       ('STRG links'),
{30}   ('A'),
       ('S'),
       ('D'),
       ('F'),
       ('G'),
       ('H'),
       ('J'),
       ('K'),
       ('L'),
       ('™'),
{40}   ('Ž'),
       ('^'),
       ('Shift links'),
       ('#'),
       ('Y'),
       ('X'),
       ('C'),
       ('V'),
       ('B'),
       ('N'),
{50}   ('M'),
       (','),
       ('.'),
       ('-'),
       ('Shift rechts'),
       ('Keypad *'),
       ('ALT links'),
       ('Space'),
       ('Caps'),
       ('F1'),
{60}   ('F2'),
       ('F3'),
       ('F4'),
       ('F5'),
       ('F6'),
       ('F7'),
       ('F8'),
       ('F9'),
       ('F10'),
       ('NUM Lock'),
{70}   ('Scroll Lock'),
       ('Keypad 7'),
       ('Keypad 8'),
       ('Keypad 9'),
       ('Keypad -'),
       ('Keypad 4'),
       ('Keypad 5'),
       ('Keypad 6'),
       ('Keypad +'),
       ('Keypad 1'),
{80}   ('Keypad 2'),
       ('Keypad 3'),
       ('Keypad 0'),
       ('Keypad ,'),
       ('Bild ab'),
       ('Bild auf'),
       ('<'),
       ('F11'),
       ('F12'),
       ('Numpad Enter'),
       ('STRG rechts'),
       ('Printscreen'),
       ('Numpad /'),
       ('ALT Gr'),
       ('POS1'),
       ('CRSR oben'),
       ('CRSR links'),
       ('CRSR rechts'),
       ('ENDE'),
       ('CRSR unten'),
       ('EINFG'),
       ('ENTF'),
       ('Pause')
       );
const charset:array[0..9,1..7,1..5] of byte=
      (
       ((0,1,1,0,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,0,0)),

       ((0,0,1,0,0),
        (0,1,1,0,0),
        (0,0,1,0,0),
        (0,0,1,0,0),
        (0,0,1,0,0),
        (0,0,1,0,0),
        (0,0,1,0,0)),

       ((0,1,1,0,0),
        (1,0,0,1,0),
        (0,0,0,1,0),
        (0,1,1,0,0),
        (1,0,0,0,0),
        (1,0,0,0,0),
        (1,1,1,1,0)),

       ((0,1,1,0,0),
        (1,0,0,1,0),
        (0,0,0,1,0),
        (0,0,1,0,0),
        (0,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,0,0)),

       ((0,0,0,1,0),
        (0,0,1,1,0),
        (0,1,0,1,0),
        (1,0,0,1,0),
        (1,1,1,1,0),
        (0,0,0,1,0),
        (0,0,0,1,0)),

       ((1,1,1,1,0),
        (1,0,0,0,0),
        (1,1,1,0,0),
        (0,0,0,1,0),
        (0,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,0,0)),

       ((0,1,1,0,0),
        (1,0,0,0,0),
        (1,1,1,0,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,0,0)),

       ((1,1,1,1,0),
        (0,0,0,1,0),
        (0,0,0,1,0),
        (0,0,1,0,0),
        (0,1,0,0,0),
        (0,1,0,0,0),
        (0,1,0,0,0)),

       ((0,1,1,0,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,0,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,0,0)),

       ((0,1,1,0,0),
        (1,0,0,1,0),
        (1,0,0,1,0),
        (0,1,1,1,0),
        (0,0,0,1,0),
        (0,0,0,1,0),
        (0,1,1,0,0))
                    );

implementation
procedure setmode(mode: word);assembler;
asm
 mov ax, mode
 int 10h
end;

procedure waitretrace;assembler;
asm
 mov dx, $3da
@loop:
 in ax, dx
 and ax, 8
 jnz @loop
@loop2:
 in ax, dx
 and ax, 8
 jz @loop2
end;

procedure setreg (dacreg,r,g,b: byte);assembler;
asm
 mov dx, 3c8h
 mov al, dacreg
 out dx, al
 inc dx
 mov al, r
 out dx, al
 mov al, g
 out dx, al
 mov al, b
 out dx, al
end;

procedure getreg (dacreg: byte; var r,g,b: byte);
var x,y,z: byte;
begin
asm
 mov al, dacreg
 mov dx, 3c7h
 out dx, al
 mov dx, 3c9h
 in  al, dx
 mov x, al
 in  al, dx
 mov y, al
 in  al, dx
 mov z, al
end;
r:=x;g:=y;b:=z;
end;

procedure setpix_13h (x,y: word;col: byte;dest:word); assembler;
asm
 mov di, y
 mov ax, x
 cmp di, 199
 jg @end
 cmp di, 0
 jl @end
 cmp ax, 319
 jg @end
 cmp ax, 0
 jl @end
 shl di, 8
 shl y, 6
 add di, y
 add di, ax
 mov ax, dest
 mov es, ax
 mov al, col
 mov es:[di], al
@end:
end;

function getpix_13h (x,y,dest: word):byte;assembler;
asm
 mov di, y
 mov ax, x
 shl di, 8
 shl y, 6
 add di, y
 add di, ax
 mov ax, dest
 mov es, ax
 mov al, es:[di]
 xor ah, ah
end;


procedure line_13h(x1,y1,x2,y2:word;color:byte;base:word);assembler;
var add1,add2,deltax,deltay: word;
    yinc,xinc: integer;

asm
 mov xinc, -1
 mov ax, x1
 mov di, ax
 mov dx, x2
 mov cx, dx
 cmp ax, dx
 ja @weiter
 xchg ax, dx
 mov xinc, 1
@weiter:
 sub ax, dx
 mov deltax, ax

 mov yinc,-320
 mov ax, y1
 mov dx, ax
 shl dx, 6
 add di, dx
 mov dx, ax
 shl dx, 8
 add di, dx

 mov dx, y2
 mov bx, dx
 shl bx, 8
 add cx, bx
 mov bx, dx
 shl bx, 6
 add cx, bx
 cmp ax, dx
 ja @weiter2
 xchg ax, dx
 mov yinc, 320
@weiter2:
 sub ax, dx

 mov deltay, ax
 cmp deltax, 0
 jne @goon
 cmp deltay, 0
 je @end_ppx
@goon:

 mov ax, base
 mov es, ax

 mov dx, deltax
 cmp dx, deltay
 ja @setpix_2
 mov bx, dx
 shl dx, 1
 mov add1, dx
 sub dx, deltay
 mov ax, dx
 sub bx, deltay
 shl bx, 1
 mov add2, bx
 mov bl, color
@loop_1:
 mov es:[di], bl
@end_pp:
 cmp ax,0
 jl @add1
 add ax, add2
 add di, xinc
 jmp @cont1
@add1:
 add ax, add1
@cont1:
 add di, yinc
 cmp di, cx
 jne @loop_1
 jmp @end_ppx
@setpix_2:
 mov si, deltay
 mov bx, si
 shl si, 1
 mov ax, si
 sub ax, dx
 mov add1, si
 sub bx, dx
 shl bx, 1
 mov add2, bx
 mov bl, color
@loop_2:
 mov es:[di],bl
@end_pp2:
 cmp ax,0
 jl @add1_2
 add ax, add2
 add di, yinc
 jmp @cont1_2
@add1_2:
 add ax, add1
@cont1_2:
 add di, xinc
 cmp di, cx
 jne @loop_2
@end_ppx:
 mov es:[di],bl
end;

procedure clear_13h (col: byte;dest:word);assembler;
asm
 mov ax, dest
 mov es, ax
 xor di, di
 mov cx, 32000
 mov ah, col
 mov al, ah
 cld
 rep stosw
end;

procedure loadpcx(n:string;e:word);
var t,z,p,x,y,xi,xa,yi,ya:word;
    f:file;

procedure rm;
begin
p:=1;
if filesize(f)-filepos(f)>=m then blockread(f,d,m) else blockread(f,d,filesize(f)-filepos(f));
end;

procedure putp;
begin
{asm
 mov ax,[e]
 mov es, ax
 mov ax, [y]
 mov bx, 320
 mul bx
 add ax,[x]
 mov di, offset d
 add di, p
 mov si, ax
 mov al, [di]
 mov es:[si], al
{ inc x
end;}
mem[e:x+y*320]:=d[p];
inc(x);
if x<=xa then exit;inc(y);x:=xi
end;

procedure sr(n,r,g,b:word);assembler;
asm
 mov dx,3c8h
 mov ax,n
 out dx,al
 inc dx
 mov ax,r
 out dx,al
 mov ax,g
 out dx,al
 mov ax,b
 out dx,al
end;

begin
assign(f,n);
reset(f,1);
blockread(f,d,16);
xi:=(319-d[9]-d[10]shl 8)div 2;
xa:=319-xi;
yi:=(199-d[11]-d[12]shl 8)div 2;
ya:=199-yi;
x:=xi;y:=yi;
seek(f,filesize(f)-768);
rm;
for z:=0to 255 do
 sr(z,d[z*3+1]div 4,d[z*3+2]div 4,d[z*3+3]div 4);
seek(f,$80);rm;
 repeat
  if (d[p]and 192=192) then begin
   t:=d[p] and 63;
   inc(p);
   if p>m then rm;
   for z:=1 to t do putp
  end else
   putp;
  inc(p);
  if p>m then rm;
 until(y>ya);
close(f);
end;

procedure fadeout;
var a,b: byte;
begin
for a:=0 to 255 do
 getreg(a,c[a,1],c[a,2],c[a,3]);
for a:=0 to 63 do begin
 for b:=0 to 255 do begin
  if c[b,1]>0 then dec(c[b,1]);
  if c[b,2]>0 then dec(c[b,2]);
  if c[b,3]>0 then dec(c[b,3]);
 end;
 waitretrace;
 for b:=0 to 255 do
  setreg(b,c[b,1],c[b,2],c[b,3]);
end;
end;

procedure show64(n:string;d:word);
var a: file;
    c:word;
    p: array[0..767] of byte;

begin
assign(a,n);
reset(a,1);
blockread(a,p,768);
for c:=0 to 255 do
 setreg(c,p[c*3] div 4,p[c*3+1] div 4,p[c*3+2] div 4);
blockread(a,mem[d:0],64000);
close(a);
end;

begin
end.
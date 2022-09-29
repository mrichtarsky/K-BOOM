unit drk_vga;
interface
type palette=array[0..255,1..3] of byte;
var pal,palbuf,destpal: palette;

function vga_inst: boolean;
procedure setmode(mode: word);
procedure setreg (dacreg,r,g,b: byte);
procedure getreg (dacreg: byte; var r,g,b: byte);
procedure waitretrace;
procedure waitendretrace;
procedure setpal(p:palette;first,no:word);
procedure getpal(p:palette;first,no:word);
procedure savepal;
procedure restorepal;
procedure fadein;
procedure fadeout;
procedure set_split(n:integer);
procedure set_start(off:word);
procedure set_curshape(a,b:byte);
procedure set_overscan(n:byte);

implementation
function vga_inst: boolean;
begin
asm
 mov @result, false
 mov ax, 1a00h
 int 10h
 cmp al, 1ah
 jne @end
 mov @result, true
@end:
end;
end;

procedure setmode(mode: word);assembler;
asm
 mov ax, mode
 int 10h
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

procedure waitendretrace;assembler;
asm
 mov dx, $3da
@loop2:
 in ax, dx
 and ax, 8
 jz @loop2
end;

procedure setpal(p:palette;first,no:word);assembler;
asm
 mov ax, 1012h
 mov bx, first
 mov cx, no
 mov dx, seg p
 mov es, dx
 mov dx, offset p
 int 10h
end;

procedure getpal(p:palette;first,no:word);assembler;
asm
 mov ax, 1017h
 mov bx, first
 mov cx, no
 mov dx, seg p
 mov es, dx
 mov dx, offset p
 int 10h
end;

procedure savepal;
var x:byte;
begin
 getpal(palbuf,0,255);
end;

procedure restorepal;
var x: byte;
begin
 setpal(palbuf,0,255);
end;

procedure fadein;
var x: array[1..3] of byte;
    y,z: byte;
begin
getpal(pal,0,255);
 for z:=0 to 63 do
  begin
   for y:=0 to 255 do
   begin
    if pal[y,1]<destpal[y,1] then inc (pal[y,1]);
    if pal[y,2]<destpal[y,2] then inc (pal[y,2]);
    if pal[y,3]<destpal[y,3] then inc (pal[y,3]);
   end;
  setpal(pal,0,255);
  end;
end;

procedure fadeout;
var x: array[1..3] of byte;
    y,z: byte;
    temp: array[0..255,1..3] of real;
begin
for y:=0 to 255 do
begin
 getreg(y,x[1],x[2],x[3]);
 temp[y,1]:=x[1]/63;
 temp[y,2]:=x[2]/63;
 temp[y,3]:=x[3]/63;
end;
 for z:=63 downto 0 do
 begin

  for y:=0 to 255 do
   begin
   x[1]:=round(z*temp[y,1]);
   x[2]:=round(z*temp[y,2]);
   x[3]:=round(z*temp[y,3]);
   setreg(y,x[1],x[2],x[3]);
   end;
 end;
end;

procedure set_split(n:integer);
begin
 port[$3d4]:=$18;
 port[$3d5]:=lo(n);
 port[$3d4]:=07;
 if (n and $100=$100) then
  port[$3d5]:=port[$3d5] or $10
 else
  port[$3d5]:=port[$3d5] and not $10;
 port[$3d4]:=9;
 if (n and $200=$200) then
  port[$3d5]:=port[$3d5] or $40
 else
  port[$3d5]:=port[$3d5] and not $40;
end;

procedure set_start(off:word);
begin
 portw[$3d4]:=hi(off) shl 8 + $0c;
 portw[$3d4]:=lo(off) shl 8 + $0d;
end;

procedure set_curshape(a,b:byte);assembler;
asm
 mov ah,1
 mov ch, a
 mov cl, b
 int 10h
end;

procedure set_overscan(n:byte);assembler;
asm
 mov ax,1001h
 {101h}
 mov bh, n
 int 10h
end;

begin
end.
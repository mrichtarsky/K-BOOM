unit drk_pcx;

interface

const maxmem=10000;
var filename: string;
    pcx_file: string;
    bytes,w1,w2,filehandle: word;
    w3: longint;
    error: boolean;
    data: array[1..maxmem] of byte;
    palette: array[0..767] of byte;

procedure loadpcx(dest:word;colors:boolean);
procedure setcolors;

implementation
procedure movepointer (movh,movl:word;mode: byte);assembler;
 asm
  mov ah, 42h
  mov al, mode
  mov bx, filehandle
  mov dx, movl
  mov cx, movh
  int 21h
  jnc @wentok
  mov error, true
  mov w1, ax
  jmp @end
@wentok:
  mov [w1], dx
  mov [w2], ax
@end:
 end;


procedure fileopen(access:byte);
begin
  asm
     mov ah, 3dh
     mov al, access
     lea dx, filename+1
     int 21h
     jnc @wentok
     mov error, 1
@wentok:
     mov filehandle, ax
        end;
end;

procedure fileclose;
begin
  asm
     mov ah, 3eh
     mov bx, filehandle
     int 21h
     jnc @wentok
     mov error, 1
@wentok:
  end;
end;

procedure fileread (xy:word);assembler;
  asm
     mov ah, 3fh
     mov bx, filehandle
     mov cx, xy
     lea dx, data
     int 21h
     mov bytes, ax
     cmp ax, xy
     je  @wentok
     mov error, true
@wentok:
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

procedure setcolors;
var a: word;
begin
for a:=0 to 255 do
 setreg(a, palette[a*3],palette[a*3+1],palette[a*3+2]);
end;

procedure loadpcx(dest:word;colors:boolean);
var pos,xco, yco: word;
    c1,times: byte;
    ymin,bytesperline,xmin,xmax,ymax: word;

begin
 error:=false;
 fileopen(0);
 if error=true then exit;
 movepointer(0,4,0);
 fileread(8);
 xmin:=data[1]+data[2]shl 8;
 ymin:=data[3]+data[4]shl 8;
 xmax:=data[5]+data[6]shl 8;
 ymax:=data[7]+data[8]shl 8;
 movepointer(0,66,0);
 fileread(2);
 bytesperline:=data[1]+data[2]*255;
 xmin:=((319-xmax) div 2);
 xmax:=319-xmin;
 ymin:=((199-ymax) div 2);
 ymax:=199-ymin;

 movepointer(0,0,2);
 w3:=w1*65536+w2;
 dec(w3,768);
 w1:=w3 div 65536;
 w2:=w3 mod 65536;
 movepointer(w1,w2,0);
 fileread(768);
 if colors then
 for w3:=0 to 255 do
   setreg(w3,data[w3*3+1] shr 2,data[w3*3+2] shr 2,data[w3*3+3] shr 2)
 else
 for w3:=0 to 767 do
   palette[w3]:=data[w3+1] shr 2;

 if error=true then exit;
 movepointer(0,$80,0);
 fileread(maxmem);
asm
 push di
 push es
 mov ax, dest
 mov es, ax
 mov cx, xmin
 mov dx, ymin
 xor di, di
@goto:
 mov al, ds:[offset data+di]
 mov ah, al
 and al, 192
 cmp al, 192
 jne @nopack
 inc di
 cmp di, maxmem-1
 ja @load1
@cont:
 mov al, ds:[offset data+di]
 and ah, 63
@cont1:
 dec ah
 push di
 mov di, dx
 mov bx, dx
 shl di, 8
 shl bx, 6
 add di, bx
 add di, cx
 mov es:[di], al
 pop di

 inc cx
 cmp cx, xmax
 ja @incdx1
@cont2:
 cmp ah,0
 ja @cont1
 jmp @nextbyte

@nopack:
 push di
 mov di, dx
 mov bx, dx
 shl di, 8
 shl bx, 6
 add di, cx
 add di, bx
 mov es:[di], ah
 pop di

 inc cx
 cmp cx, xmax
 jna @nextbyte
 mov cx, xmin
 inc dx
@nextbyte:
 cmp dx, ymax
 jae @end
 inc di
 cmp di, maxmem-1
 jna @goto
 push cx
 push dx
 mov ah, 3fh
 mov bx, filehandle
 mov cx, maxmem
 lea dx, data
 int 21h
 mov di, 0
 pop dx
 pop cx
 jmp @goto

@load1:
 push dx
 push cx
 push ax
 mov ah, 3fh
 mov bx, filehandle
 mov cx, maxmem
 lea dx, data
 int 21h
 mov di, 0
 pop ax
 pop cx
 pop dx
 jmp @cont

@incdx1:
 inc dx
 mov cx, xmin
 jmp @cont2
@end:
 pop es
 pop di
 mov ah, 3eh
 mov bx, filehandle
 int 21h
 jnc @wentok
 mov error, 1
@wentok:
end;
end;

begin
end.
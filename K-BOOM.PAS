uses crt,dos,k_b00m,fli2;
type
     sprite_struc=record
      x,y,step,typ,player:byte;
      active: boolean;
     end;

     player_struc=record
      left,right,up,down,drop,kick: byte;
      x,y:byte;
      adir:byte;
      amov: byte;
      acnt: byte;
      range,maxbombs,curbombs:byte;
      dead,red: boolean;
      wins: byte;
     end;

     bomb_struc=record
      active:boolean;
      blew: boolean;
      count:integer;
      x,y:byte;
      player:byte;
      range:byte;
      red: boolean;
     end;

     numb_struc = array[1..9,0..15,0..6] of byte;

const texts: array[1..3] of byte=
      (39,94,149);
      feldx=12;
      feldy=10;
      fx=16;
      fy=15;
      px=11;
      py=9;
      maxkeys=40;
      maxx=(feldx+1)*fx;
      maxy=(feldy+1)*fy;
      maxrange=9;
      maxbombs=9;
      bmb_max=50;
      spr_max=600;
      players=3;
      sprites:word=0;
      p:array[1..3,0..3,0..2,0..1] of word=
      ((((224,30),(208,30),(240,30)),
        ((224,15),(208,15),(240,15)),
        ((224,45),(208,45),(240,45)),
        ((224,60),(208,60),(240,60))),

       (((288,30),(272,30),(304,30)),
        ((288,15),(272,15),(304,15)),
        ((288,45),(272,45),(304,45)),
        ((288,60),(272,60),(304,60))),

       (((224,105),(208,105),(240,105)),
        ((224, 90),(208, 90),(240, 90)),
        ((224,120),(208,120),(240,120)),
        ((224,135),(208,135),(240,135))));
      nilspr: sprite_struc=
       (x:0;y:0;step:0;typ:0;player:0;active:false);
      move_time=8;

var seg1,seg2,seg3: word;p1,p2,p3: pointer;
    _exit:boolean;
    movec,count,a,b: word;
    c: longint;
    feld: array[0..feldx,0..feldy] of byte;
    {0..leer
     1..mauer
     2..wand}
    smap: array[0..feldx,0..feldy] of byte;
    {76543210
     |      |
     1:bomb |
            1:sprite(feuer)}
    alive:byte;
    bombs: byte;
    maxwins: byte;
    ch: char;

    player: array[1..3] of player_struc;
    spr: array[1..spr_max] of sprite_struc;
    bmb: array[1..bmb_max] of bomb_struc;
    pressed: array[1..102] of boolean;

    k: boolean;
    key_start,key_end: word;
    keypuf: array[0..maxkeys+1] of byte;
    oldtimer,oldbios:procedure;
    cfg: file;

    numbers: numb_struc;
    numb_file: file of numb_struc;

procedure write_number(no: byte;x,y:word;col,bg:byte;dest: word);
var a,b: word;
begin
for a:=1 to 7 do
 for b:=1 to 5 do
  if charset[no,a,b]=1 then setpix_13h(x+b-1,y+a-1,col,dest)
                       else setpix_13h(x+b-1,y+a-1, bg,dest);

end;

procedure maskcursor;assembler;
asm
 mov dx, $3d4
 mov al, $0a
 out dx, al
 inc dx
 in al, dx
 xor al, 32
 out dx, al
end;

procedure set_overscan(n:byte);assembler;
asm
 mov ah,10h
 mov al, 1
 mov bh, n
 int 10h
end;

procedure draw_sprite2(x,y,seg_dest,xb,yb,seg_base,xsize,ysize:word);assembler;
asm
 push ds
 mov bx, 320
 mov ax, [y]
 mul bx
 add ax, [x]
 mov di, ax

 mov ax, [yb]
 mul bx
 add ax, [xb]
 mov si, ax

 mov ax, [seg_dest]
 mov es, ax
 mov ax, [seg_base]
 mov ds, ax

 mov dx, 320
 sub dx, [xsize]
 mov bx, [ysize]
@l:
 mov cx, [xsize]
@w:
 mov al, ds:[si]
 or al, al
 jz @skip
 mov es:[di], al
@skip:
 inc si
 inc di
 dec cx
 jnz @w
 add si, dx
 add di, dx
 dec bx
 jns @l
 pop ds
end;

procedure int9handler;interrupt;assembler;
asm
 in al, $60
 mov di, offset [keypuf]
 add di, key_end
 mov [di], al
 inc key_end
 cmp key_end, 40
 jng @weiter
 mov key_end,0
@weiter:
 mov al, $20
 out $20, al
end;

procedure copypcx(src,dest:word);assembler;
asm
 push ds
 mov ax, src
 mov ds, ax
 mov ax, dest
 mov es, ax
 mov di, 0
 mov si, 0
 mov cx, 32000
 rep movsw
 pop ds
end;

procedure copy_block(x1,y1,seg1,x2,y2,seg2,xsize,ysize:word);assembler;
asm
 push ds
 mov bx, 320
 mov ax, [y1]
 mul bx
 add ax, [x1]
 mov si, ax

 mov ax, [y2]
 mul bx
 add ax, [x2]
 mov di, ax

 mov ax, [seg1]
 mov ds, ax
 mov ax, [seg2]
 mov es, ax

 mov dx, 320
 sub dx, [xsize]
 mov bx, [ysize]
 shr [xsize], 1
@loop:
 mov cx, [xsize]
 rep movsw
 add si, dx
 add di, dx
 dec bx
 jnz @loop
 pop ds
end;

procedure draw_screen1;
var a,b:word;

begin
for a:=0 to 19 do begin
 draw_sprite2(a*16,0,$a000,16,15,seg3,fx,fy-1);
 draw_sprite2(a*16,180,$a000,16,15,seg3,fx,fy-1);
end;
for a:=1 to 11 do begin
 draw_sprite2(0,a*15,$a000,16,15,seg3,fx,fy-1);
 draw_sprite2(224,a*15,$a000,16,15,seg3,fx,fy-1);
 draw_sprite2(304,a*15,$a000,16,15,seg3,fx,fy-1);
end;
for a:=15 to 18 do
 for b:=1 to 11 do
  draw_sprite2(a*fx,b*fy,$a000,144,15,seg3,fx,fy-1);

draw_sprite2(245,20,$a000,224,60,seg3,fx-1,fy-2);
draw_sprite2(245,75,$a000,288,60,seg3,fx-1,fy-2);
draw_sprite2(245,130,$a000,224,135,seg3,fx-1,fy-2);

draw_sprite2(245,35,$a000,80,15,seg3,fx,fy-1);
write_number(1,265,39,green,253,$a000);
draw_sprite2(277,35,$a000,48,15,seg3,fx,fy-1);
write_number(1,297,39,green,253,$a000);

draw_sprite2(245,90,$a000,80,15,seg3,fx,fy-1);
write_number(1,265,94,green,253,$a000);
draw_sprite2(277,90,$a000,48,15,seg3,fx,fy-1);
write_number(1,297,94,green,253,$a000);

draw_sprite2(245,145,$a000,80,15,seg3,fx,fy-1);
write_number(1,265,149,green,253,$a000);
draw_sprite2(277,145,$a000,48,15,seg3,fx,fy-1);
write_number(1,297,149,green,253,$a000);

clear_13h(blue,seg1);clear_13h(0,seg2);
{for a:=0 to 9 do
 write_number(a,250+a*5,50,10,$a000);}
end;

procedure draw_screen2;
{map only}
var a,b:word;

procedure draw_wand;
begin
draw_sprite2(a*fx,b*fy,seg1,16,15,seg3,fx,fy-1);
end;

procedure draw_mauer;
begin
draw_sprite2(a*fx,b*fy,seg1,16,0,seg3,fx,fy-1);
end;

begin
for a:=0 to feldx do
 for b:=0 to feldy do
  case feld[a,b] and 3 of
   2: draw_wand;
   1: draw_mauer;
  end;
end;

procedure fade_screen;
var a:word;
begin
for a:=1 to 82 do begin
 waitretrace;
 fillchar(mem[$a000:4816+2*a*320], 208,0);
 fillchar(mem[$a000:57616-2*a*320],208,0);
end;
fillchar(mem[$a000:4816],208,0);
{delay(1000);}
end;

procedure draw_player(no:byte);
var x,y,a,b:byte;
const fz=20;
begin
x:=player[no].x;y:=player[no].y;
b:=player[no].adir;
a:=player[no].amov and 3;
if player[no].dead=false then
 draw_sprite2(x,y,seg2,p[no,b,a,0],p[no,b,a,1],seg3,fx-1,fy-2);
end;

procedure getkeys;
var key,tmp,t,l:byte;
begin
while key_start<>key_end do begin
 key:=keypuf[key_start];
 if key=255 then for tmp:=1 to 102 do pressed[tmp]:=false;
 if key=$E0 then begin
  inc(key_start);if key_start>maxkeys then key_start:=0;
  repeat until key_start<>key_end;
  key:=keypuf[key_start];
  l:=key;
  key:=key and 127;
  case key of
   28: t:=89;
   29: t:=90;
   42: begin
        inc(key_start);if key_start>maxkeys then key_start:=0;
        repeat until key_start<>key_end;
        inc(key_start);if key_start>maxkeys then key_start:=0;
        repeat until key_start<>key_end;
        key:=keypuf[key_start];
        l:=key;
        key:=key and 127;
        case key of
         55: t:=91;
         75: t:=96;
         77: t:=97;
         71: t:=94;
         72: t:=95;
         73: t:=85;
         79: t:=98;
         80: t:=99;
         81: t:=84;
         82: t:=100;
         83: t:=101;
        end;
       end;
   53: t:=92;
   56: t:=93;
   71: t:=94;
   72: t:=95;
   73: t:=85;
   75: t:=96;
   77: t:=97;
   79: t:=98;
   80: t:=99;
   81: t:=84;
   82: t:=100;
   83: t:=101;
  end;
  if l>127 then t:=t+128;
 end else
  t:=keypuf[key_start];

 inc(key_start);if key_start>maxkeys then key_start:=0;

 tmp:=t;t:=t and 127;
 if tmp<128 then pressed[t]:=true else
  pressed[t]:=false;
end;
end;

procedure searchfreesprite(var t:byte);
begin
t:=1;
while spr[t].active do
 inc(t);
end;

procedure issue_sprite(x,y,typ,player:byte);
var tt:byte;
begin
searchfreesprite(tt);
spr[tt].x:=x;
spr[tt].y:=y;
spr[tt].typ:=typ;
spr[tt].player:=player;
spr[tt].step:=0;
spr[tt].active:=true;
smap[x div fx,y div fy]:=smap[x div fx,y div fy] or 1;
inc(sprites);
end;

procedure deinit_sprite(t:word);
begin
smap[spr[t].x div fx,spr[t].y div fy]:=smap[spr[t].x div fx,spr[t].y div fy] and 254;
spr[t]:=nilspr;
dec(sprites);
end;

procedure find_sprite(a,b:byte);
var t:word;
begin
a:=a*fx;
b:=b*fy;
for t:=1 to spr_max do
 if (spr[t].x=a) and (spr[t].y=b) then deinit_sprite(t);
end;

procedure searchfreebomb(var t:byte);
begin
t:=1;
while bmb[t].active do inc(t);
end;

procedure moveplayer(no:byte);
var tx,ty,tmp,a:byte;

begin
a:=movec*3;
if pressed[player[no].left ] then begin
 if player[no].adir = 0 then begin
  if player[no].acnt=move_time then begin
   player[no].acnt:=0;
   case player[no].amov of
    129: player[no].amov:=128;
    128: player[no].amov:=  2;
      2: player[no].amov:=  0;
      0: player[no].amov:=129;
   end;
  end else inc(player[no].acnt);
 end else begin
  player[no].acnt:=0;
  player[no].amov:=129;
  player[no].adir:=0;
 end;

 if player[no].x>3 then begin
  tx :=(player[no].x) div fx;
  ty :=(player[no].y+py shr 1) div fy;
  tmp:=(player[no].x-a) div fx;
  if tmp=tx then dec(player[no].x,a) else
   if (feld[tmp,ty] and 3=0) and (smap[tmp,ty] and 128=0) then begin
    dec(player[no].x,a);
   player[no].y:=((player[no].y+py shr 1) div fy)*fy;
   end;
 end;
end;
if pressed[player[no].right] then begin
 if player[no].adir = 1 then begin
  if player[no].acnt=move_time then begin
   player[no].acnt:=0;
   case player[no].amov of
    129: player[no].amov:=128;
    128: player[no].amov:=  2;
      2: player[no].amov:=  0;
      0: player[no].amov:=129;
   end;
  end else inc(player[no].acnt);
 end else begin
  player[no].acnt:=0;
  player[no].amov:=129;
  player[no].adir:=1;
 end;

 if (player[no].x+fx)<maxx then begin
  tx :=(player[no].x+px) div fx;
  ty :=(player[no].y+py shr 1) div fy;
  tmp:=(player[no].x+px+a) div fx;
  if tmp=tx then inc(player[no].x,a) else
   if (feld[tmp,ty] and 3=0) and (smap[tmp,ty] and 128=0) then begin
    inc(player[no].x,a);
    player[no].y:=((player[no].y+py shr 1) div fy)*fy;
   end;

 end;
end;
if pressed[player[no].up   ] then begin
 if player[no].adir = 2 then begin
  if player[no].acnt=move_time then begin
   player[no].acnt:=0;
   case player[no].amov of
    129: player[no].amov:=128;
    128: player[no].amov:=  2;
      2: player[no].amov:=  0;
      0: player[no].amov:=129;
   end;
  end else inc(player[no].acnt);
 end else begin
  player[no].acnt:=0;
  player[no].amov:=129;
  player[no].adir:=2;
 end;

 if player[no].y>0 then begin
  tx :=(player[no].x+px shr 1) div fx;
  ty :=(player[no].y) div fy;
  tmp:=(player[no].y-a) div fy;
  if tmp=ty then dec(player[no].y,a) else
   if (feld[tx,tmp] and 3=0) and (smap[tx,tmp] and 128=0) then begin
    dec(player[no].y,a);
    player[no].x:=((player[no].x+px shr 1) div fx)*fx;
   end;
 end;
end;
if pressed[player[no].down ] then begin
 if player[no].adir = 3 then begin
  if player[no].acnt=move_time then begin
   player[no].acnt:=0;
   case player[no].amov of
    129: player[no].amov:=128;
    128: player[no].amov:=  2;
      2: player[no].amov:=  0;
      0: player[no].amov:=129;
   end;
  end else inc(player[no].acnt);
 end else begin
  player[no].acnt:=0;
  player[no].amov:=129;
  player[no].adir:=3;
 end;

 if (player[no].y+fy)<maxy then begin
  tx:= (player[no].x+px shr 1) div fx;
  ty:= (player[no].y+py) div fy;
  tmp:=(player[no].y+py+a) div fy;
  if tmp=ty then inc(player[no].y,a) else
   if (feld[tx,tmp] and 3=0) and (smap[tx,tmp] and 128=0) then begin
    inc(player[no].y,a);
    player[no].x:=((player[no].x+px shr 1) div fx)*fx;
   end;
 end;
end;
if pressed[player[no].drop ] then begin
 tx:=((player[no].x+fx shr 1) div fx);
 ty:=((player[no].y+fy shr 1) div fy);
 if (player[no].curbombs<player[no].maxbombs) and (smap[tx,ty] and 128=0) then begin
  inc(bombs);
  inc(player[no].curbombs);
  searchfreebomb(tmp);
  bmb[tmp].player:=no;
  bmb[tmp].active:=true;
  bmb[tmp].x:=tx*fx;
  bmb[tmp].y:=ty*fy;
  bmb[tmp].range:=player[no].range;
  bmb[tmp].count:=90;
  bmb[tmp].blew:=false;
  bmb[tmp].red:=player[no].red;
{  issue_sprite(tx*fx,ty*fy,8,1);}
  smap[tx,ty]:=smap[tx,ty] or 128;
 end;
end;
if (pressed[player[no]. left]=false) and
   (pressed[player[no].right]=false) and
   (pressed[player[no].   up]=false) and
   (pressed[player[no]. down]=false) then
   player[no].amov:=0;
end;

procedure find_bomb(c,d:byte);
var t: byte;
begin
c:=c*fx;
d:=d*fy;
for t:=1 to bmb_max do
 if (bmb[t].x=c) and (bmb[t].y=d) then bmb[t].blew:=true;
end;

procedure blow_bomb(t:byte);
var a,b,c,d,r: shortint;
    re: boolean;

begin
dec(player[bmb[t].player].curbombs);
dec(bombs);
bmb[t].active:=false;
bmb[t].blew  :=false;
a:=bmb[t].x div fx;
b:=bmb[t].y div fy;
smap[a,b]:=smap[a,b] and 127;
issue_sprite(bmb[t].x,bmb[t].y,1,1);
{left}
c:=a;d:=b;r:=bmb[t].range;
if bmb[t].red then re:=false else re:=true;
 while (r>0) and (c>0) do begin
  dec(c);dec(r);
  if feld[c,d] and 2=0 then begin
   if smap[c,d] and 128=128 then find_bomb(c,d);
   smap[c,d]:=smap[c,d] and 127;
   if feld[c,d] and 1=1 then begin if re then r:=0;feld[c,d]:=feld[c,d] or 4;issue_sprite(c*fx,d*fy,9,1) end
    else if feld[c,d]>7 then feld[c,d]:=4;
   if r>1 then issue_sprite(c*fx,d*fy,2,1) else issue_sprite(c*fx,d*fy,7,1);
  end
  else c:=0;
 end;
 {right}
 c:=a;d:=b;r:=bmb[t].range;
 while (r>0) and (c<feldx) do begin
  inc(c);dec(r);
  if feld[c,d] and 2=0 then begin
   if smap[c,d] and 128=128 then find_bomb(c,d);
   smap[c,d]:=smap[c,d] and 127;
   if feld[c,d] and 1=1 then begin if re then r:=0;feld[c,d]:=feld[c,d] or 4;issue_sprite(c*fx,d*fy,9,1) end
    else if feld[c,d]>7 then feld[c,d]:=4;
   if r>1 then issue_sprite(c*fx,d*fy,2,1) else issue_sprite(c*fx,d*fy,6,1);
  end
  else c:=feldx;
 end;
 {up}
 c:=a;d:=b;r:=bmb[t].range;
 while (r>0) and (d>0) do begin
  dec(d);dec(r);
  if feld[c,d] and 2=0 then begin
   if smap[c,d] and 128=128 then find_bomb(c,d);
   smap[c,d]:=smap[c,d] and 127;
   if feld[c,d] and 1=1 then begin if re then r:=0;feld[c,d]:=feld[c,d] or 4;issue_sprite(c*fx,d*fy,9,1) end
    else if feld[c,d]>7 then feld[c,d]:=4;
   if r>1 then issue_sprite(c*fx,d*fy,3,1) else issue_sprite(c*fx,d*fy,4,1);
  end
  else d:=0;
 end;
{down}
 c:=a;d:=b;r:=bmb[t].range;
 while (r>0) and (d<feldy) do begin
  inc(d);dec(r);
  if feld[c,d] and 2=0 then begin
   if smap[c,d] and 128=128 then find_bomb(c,d);
   smap[c,d]:=smap[c,d] and 127;
   if feld[c,d] and 1=1 then begin if re then r:=0;feld[c,d]:=feld[c,d] or 4;issue_sprite(c*fx,d*fy,9,1) end
    else if feld[c,d]>7 then feld[c,d]:=4;
   if r>1 then issue_sprite(c*fx,d*fy,3,1) else issue_sprite(c*fx,d*fy,5,1);
  end
  else d:=feldy;
 end
end;

procedure check_bombs;
var a,b,t:byte;
begin
for t:=1 to bmb_max do
 if (bmb[t].blew) and (bmb[t].active) then blow_bomb(t);
for a:=0 to feldx do
 for b:=0 to feldy do
  if feld[a,b] and 4=4 then begin
{   find_sprite(a,b);}
   feld[a,b]:=feld[a,b] and 248;
   case (feld[a,b] shr 3) of
    0: draw_sprite2(a*fx,b*fy,seg1,32,0,seg3,fx,fy-1);
    1: draw_sprite2(a*fx,b*fy,seg1,48,15,seg3,fx,fy-1);
    2: draw_sprite2(a*fx,b*fy,seg1,64,15,seg3,fx,fy-1);
    3: draw_sprite2(a*fx,b*fy,seg1,80,15,seg3,fx,fy-1);
    4: draw_sprite2(a*fx,b*fy,seg1,32,15,seg3,fx,fy-1);
   end;
  end;
for t:=1 to bmb_max do
 if bmb[t].active then
 if bmb[t].red=false then
  case bmb[t].count div 15 of
   5,6: draw_sprite2(bmb[t].x,bmb[t].y,seg2,0,30,seg3,fx-1,fy-1);
     4: draw_sprite2(bmb[t].x,bmb[t].y,seg2,16,30,seg3,fx-1,fy-1);
     3: draw_sprite2(bmb[t].x,bmb[t].y,seg2,32,30,seg3,fx-1,fy-1);
     2: draw_sprite2(bmb[t].x,bmb[t].y,seg2,48,30,seg3,fx-1,fy-1);
     1: draw_sprite2(bmb[t].x,bmb[t].y,seg2,64,30,seg3,fx-1,fy-1);
     0: draw_sprite2(bmb[t].x,bmb[t].y,seg2,80,30,seg3,fx-1,fy-1);
  end else
  case bmb[t].count div 15 of
   5,6: draw_sprite2(bmb[t].x,bmb[t].y,seg2,0,105,seg3,fx-1,fy-1);
     4: draw_sprite2(bmb[t].x,bmb[t].y,seg2,16,105,seg3,fx-1,fy-1);
     3: draw_sprite2(bmb[t].x,bmb[t].y,seg2,32,105,seg3,fx-1,fy-1);
     2: draw_sprite2(bmb[t].x,bmb[t].y,seg2,48,105,seg3,fx-1,fy-1);
     1: draw_sprite2(bmb[t].x,bmb[t].y,seg2,64,105,seg3,fx-1,fy-1);
     0: draw_sprite2(bmb[t].x,bmb[t].y,seg2,80,105,seg3,fx-1,fy-1);
  end end;

procedure countdown_bombs;assembler;
asm
 mov ax, bmb_max
 mov di, offset bmb
 mov bl, 1
 xor bh, bh
@a:
 cmp [di], bl
 jne @w
 cmp [di+2], bh
 jne @w2
 mov [di+1], bl
 jmp @w
@w2:
 dec word ptr [di+2]
@w:
 add di,9
 dec ax
 jnz @a
end;

procedure draw_sprites;
var a,x,y,c: word;
begin
for a:=1 to spr_max do
 if spr[a].active then begin
  x:=spr[a].x;y:=spr[a].y;
  case spr[a].typ of
   1: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2, 0,90,seg3,fx,fy-1);
         2: draw_sprite2(x,y,seg2,16,90,seg3,fx,fy-1);
         3: draw_sprite2(x,y,seg2,32,90,seg3,fx,fy-1);
         4: draw_sprite2(x,y,seg2,48,90,seg3,fx,fy-1);
         5: draw_sprite2(x,y,seg2,64,90,seg3,fx,fy-1);
         6: draw_sprite2(x,y,seg2,80,90,seg3,fx,fy-1);
      end;
   2: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2, 0,44,seg3,fx,fy-1);
         2: draw_sprite2(x,y,seg2,16,44,seg3,fx,fy-1);
         3: draw_sprite2(x,y,seg2,32,44,seg3,fx,fy-1);
         4: draw_sprite2(x,y,seg2,48,44,seg3,fx,fy-1);
         5: draw_sprite2(x,y,seg2,64,44,seg3,fx,fy-1);
         6: draw_sprite2(x,y,seg2,80,44,seg3,fx,fy-1);
      end;
   3: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2,95, 0,seg3,fx,fy-1);
         2: draw_sprite2(x,y,seg2,95,15,seg3,fx,fy-1);
         3: draw_sprite2(x,y,seg2,95,30,seg3,fx,fy-1);
         4: draw_sprite2(x,y,seg2,95,45,seg3,fx,fy-1);
         5: draw_sprite2(x,y,seg2,95,60,seg3,fx,fy-1);
         6: draw_sprite2(x,y,seg2,95,75,seg3,fx,fy-1);
      end;
   4: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2,111, 0,seg3,fx,fy-1);
         2: draw_sprite2(x,y,seg2,111,15,seg3,fx,fy-1);
         3: draw_sprite2(x,y,seg2,111,30,seg3,fx,fy-1);
         4: draw_sprite2(x,y,seg2,111,45,seg3,fx,fy-1);
         5: draw_sprite2(x,y,seg2,111,60,seg3,fx,fy-1);
         6: draw_sprite2(x,y,seg2,111,75,seg3,fx,fy-1);
      end;
   5: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2,126, 0,seg3,fx,fy-1);
         2: draw_sprite2(x,y,seg2,126,15,seg3,fx,fy-1);
         3: draw_sprite2(x,y,seg2,126,30,seg3,fx,fy-1);
         4: draw_sprite2(x,y,seg2,126,45,seg3,fx,fy-1);
         5: draw_sprite2(x,y,seg2,126,60,seg3,fx,fy-1);
         6: draw_sprite2(x,y,seg2,126,75,seg3,fx,fy-1);
      end;
   6: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2, 0,74,seg3,fx-1,fy-1);
         2: draw_sprite2(x,y,seg2,16,74,seg3,fx-1,fy-1);
         3: draw_sprite2(x,y,seg2,32,74,seg3,fx-1,fy-1);
         4: draw_sprite2(x,y,seg2,48,74,seg3,fx-1,fy-1);
         5: draw_sprite2(x,y,seg2,64,74,seg3,fx-1,fy-1);
         6: draw_sprite2(x,y,seg2,80,74,seg3,fx-1,fy-1);
      end;
   7: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2,0, 59,seg3,fx-1,fy-1);
         2: draw_sprite2(x,y,seg2,16,59,seg3,fx-1,fy-1);
         3: draw_sprite2(x,y,seg2,32,59,seg3,fx-1,fy-1);
         4: draw_sprite2(x,y,seg2,48,59,seg3,fx-1,fy-1);
         5: draw_sprite2(x,y,seg2,64,59,seg3,fx-1,fy-1);
         6: draw_sprite2(x,y,seg2,80,59,seg3,fx-1,fy-1);
      end;
{   8: case spr[a].step of
       5,6: draw_sprite2(x,y,seg2,0,30,seg3,fx-1,fy-1);
         4: draw_sprite2(x,y,seg2,16,30,seg3,fx-1,fy-1);
         3: draw_sprite2(x,y,seg2,32,30,seg3,fx-1,fy-1);
         2: draw_sprite2(x,y,seg2,48,30,seg3,fx-1,fy-1);
         1: draw_sprite2(x,y,seg2,64,30,seg3,fx-1,fy-1);
         0: draw_sprite2(x,y,seg2,80,30,seg3,fx-1,fy-1);
      end;}
   9: case spr[a].step of
       0,1: draw_sprite2(x,y,seg2, 0,120,seg3,fx,fy-1);
         2: draw_sprite2(x,y,seg2,16,120,seg3,fx,fy-1);
         3: draw_sprite2(x,y,seg2,32,120,seg3,fx,fy-1);
         4: draw_sprite2(x,y,seg2,48,120,seg3,fx,fy-1);
         5: draw_sprite2(x,y,seg2,64,120,seg3,fx,fy-1);
         6: draw_sprite2(x,y,seg2,80,120,seg3,fx,fy-1);
      end;
 end;
 end;
end;

procedure animate_sprites;
var a:word;

begin
for a:=1 to spr_max do
 if (spr[a].active) then
  if spr[a].step<7 then inc(spr[a].step) else deinit_sprite(a);
end;

procedure create_map;
var x,y,a,b: word;

begin
for a:=0 to feldx do
 for b:=0 to feldy do begin
  feld[a,b]:=1;
  smap[a,b]:=0;
 end;
for a:=0 to 5 do
 for b:=0 to 4 do
  feld[a*2+1,b*2+1]:=2;
a:=20+random(6);
repeat
 x:=random(feldx);
 y:=random(feldy);
 if feld[x,y] shr 1=0 then begin
  feld[x,y]:=feld[x,y]+1 shl 3;
  dec(a);
 end;
until a=0;
a:=20+random(6);
repeat
 x:=random(feldx);
 y:=random(feldy);
 if feld[x,y] shr 1=0 then begin
  feld[x,y]:=feld[x,y]+3 shl 3;
  dec(a);
 end;
until a=0;
a:=8+random(2);
repeat
 x:=random(feldx);
 y:=random(feldy);
 if feld[x,y] shr 1=0 then begin
  feld[x,y]:=feld[x,y]+2 shl 3;
  dec(a);
 end;
until a=0;
a:=5+random(2);
repeat
 x:=random(feldx);
 y:=random(feldy);
 if feld[x,y] shr 1=0 then begin
  feld[x,y]:=feld[x,y]+4 shl 3;
  dec(a);
 end;
until a=0;
feld[0,0]:=0;feld[feldx,feldy]:=0;
feld[feldx,0]:=0;feld[0,feldy]:=0;
feld[1,0]:=0;feld[feldx-1,0]:=0;
feld[0,1]:=0;feld[feldx,1]:=0;
feld[0,feldy-1]:=0;feld[1,feldy]:=0;
feld[feldx,feldy-1]:=0;feld[feldx-1,feldy]:=0;
end;

procedure check_collision(no:byte);
var tx,ty: shortint;
begin
tx:=(player[no].x+px shr 1) div fx;
ty:=(player[no].y+py shr 1) div fy;
case feld[tx,ty] shr 3 of
 1: if player[no].range<maxrange then begin
     inc(player[no].range);write_number(player[no].range,297,texts[no],green,253,$a000)
    end;
 2: if player[no].range>1        then begin
     dec(player[no].range);write_number(player[no].range,297,texts[no],green,253,$a000)
    end;
 3: if player[no].maxbombs<maxbombs then begin
     inc(player[no].maxbombs);write_number(player[no].maxbombs,265,texts[no],green,253,$a000)
    end;
 4: begin
     player[no].red:=true;
     draw_sprite2(245,texts[no]+11,$a000,32,15,seg3,fx,fy-1);
    end;
end;
feld[tx,ty]:=0;
draw_sprite2(tx*16,ty*15,seg1,32,0,seg3,fx,fy-1);
if (smap[tx,ty] and 1=1) and (tx>=0) and (ty>=0) and (tx<=feldx) and (ty<=feldy)
then begin dec(alive);player[no].dead:=true end;
end;

procedure newtimer;interrupt;assembler;
asm
 inc [count]
 inc [movec]
 pushf
 call oldtimer
end;

procedure init_timer;
begin
c:=$1234DD div 10;
Port[$43] := $34;
Port[$40] := c mod 256;
Port[$40] := c div 256;
getintvec($9, @oldbios);
setintvec($9, addr(int9handler));
getintvec(8, @oldtimer);
setintvec(8, addr(newtimer));
key_start:=0;key_end:=0;
end;

procedure restore_timer;
begin
setintvec($9,@oldbios);
setintvec(8, @oldtimer);
Port[$43] := $34;
Port[$40] := 0;
Port[$40] := 0;
end;

procedure choose_start;
var u: array[0..3] of boolean;
    a,no: byte;
const p: array[0..3,1..2]of byte=
      ((0,0),(0,150),(192,0),(192,150));

begin
randomize;
no:=1;
for a:=0 to 3 do
 u[a]:=false;
repeat
 repeat
  a:=random(4);
 until u[a]=false;
 u[a]:=true;
 player[no].x:=p[a,1];
 player[no].y:=p[a,2];
 inc(no);
until no=4;
end;

procedure play_round;
label weiter;

begin
setmode($13);
loadpcx('music.dat',seg3);
setreg(0,  0,0,0);
setreg(253,40,0,0);
init_timer;
for a:=1 to 3 do
 player[a].wins:=0;
draw_screen1;
weiter:
repeat
 randomize;
 create_map;
 for a:=0 to feldx do
  for b:=0 to feldy do
   smap[a,b]:=0;
 for a:=1 to bmb_max do
  bmb[a].active:=false;
 for a:=1 to players do begin
  player[a].range:=1;
  player[a].maxbombs:=1;
  player[a].curbombs:=0;
  player[a].red:=false;
  player[a].dead:=false;
  player[a].adir:=3;
  player[a].amov:=0;
  player[a].acnt:=0;
 end;
 write_number(1,265,39,green,253,$a000);
 write_number(1,297,39,green,253,$a000);
 write_number(1,265,94,green,253,$a000);
 write_number(1,297,94,green,253,$a000);
 write_number(1,265,149,green,253,$a000);
 write_number(1,297,149,green,253,$a000);
 draw_screen2;
 for a:=1 to players do
  write_number(player[a].wins,268,texts[a]-16,green,253,$a000);
 for a:=1 to 102 do pressed[a]:=false;
 alive:=players;
 bombs:=0;
 for a:=1 to spr_max do
  spr[a]:=nilspr;
 choose_start;
 { player[3].dead:=true;}
 key_start:=0;key_end:=0;
 repeat
  getkeys;
  for b:=1 to players do
   if player[b].dead=false then moveplayer(b);
  movec:=0;
  copy_block(0,0,seg1,0,0,seg2,maxx,maxy);
  while count>0 do begin
   animate_sprites;
   countdown_bombs;
   dec(count);
  end;
  check_bombs;
  for b:=1 to players do
   if player[b].dead=false then check_collision(b);
  draw_sprites;
  for b:=1 to players do
   if player[b].dead=false then draw_player(b);
  waitretrace;
  copy_block(0,0,seg2,16,15,$a000,maxx,maxy);
 until (pressed[1]) or ((((alive=1) and (bombs=0)) or (alive=0)) and (sprites=0));
 fade_screen;
 if alive=1 then
  if (player[1].dead) and (player[2].dead) then inc(player[3].wins) else
   if (player[2].dead) and (player[3].dead) then inc(player[1].wins) else
    inc(player[2].wins);
until (player[1].wins=maxwins) or (player[2].wins=maxwins) or (player[3].wins=maxwins) or pressed[1];
restore_timer;
delay(90);
if keypressed then ch:=readkey;
if not ((player[1].wins=maxwins) or (player[2].wins=maxwins) or (player[3].wins=maxwins)) then
 if ch<>#27 then begin init_timer;goto weiter end;
if player[1].wins=maxwins then writeln('Player 1 wins') else
 if player[2].wins=maxwins then writeln('Player 2 wins') else
  if player[3].wins=maxwins then writeln('Player 3 wins') else
   writeln('No winner');
fillchar(mem[$a000:0],64000,0);
end;

procedure load_config;
begin
{$i-}
assign(cfg,'k-boom.cfg');
reset(cfg,1);
blockread(cfg,player[1],6);
blockread(cfg,player[2],6);
blockread(cfg,player[3],6);
blockread(cfg,maxwins,1);
close(cfg);
{$i+}
end;

procedure save_config;
begin
assign(cfg,'k-boom.cfg');
rewrite(cfg,1);
blockwrite(cfg,player[1],6);
blockwrite(cfg,player[2],6);
blockwrite(cfg,player[3],6);
blockwrite(cfg,maxwins,1);
close(cfg);
end;

procedure setup_keys;
var x,no: byte;

function getkeys: byte;
var key,tmp,t,l:byte;
begin
repeat
 while key_start=key_end do;
 key:=keypuf[key_start];
 if key=$E0 then begin
  inc(key_start);if key_start>maxkeys then key_start:=0;
  repeat until key_start<>key_end;
  key:=keypuf[key_start];
  l:=key;
  key:=key and 127;
  case key of
   28: t:=89;
   29: t:=90;
   42: begin
        inc(key_start);if key_start>maxkeys then key_start:=0;
        repeat until key_start<>key_end;
        inc(key_start);if key_start>maxkeys then key_start:=0;
        repeat until key_start<>key_end;
        key:=keypuf[key_start];
        l:=key;
        key:=key and 127;
        case key of
         55: t:=91;
         75: t:=96;
         77: t:=97;
         71: t:=94;
         72: t:=95;
         73: t:=85;
         79: t:=98;
         80: t:=99;
         81: t:=84;
         82: t:=100;
         83: t:=101;
        end;
       end;
   53: t:=92;
   56: t:=93;
   71: t:=94;
   72: t:=95;
   73: t:=85;
   75: t:=96;
   77: t:=97;
   79: t:=98;
   80: t:=99;
   81: t:=84;
   82: t:=100;
   83: t:=101;
  end;
  if l>127 then t:=t+128;
 end else
  t:=keypuf[key_start];

 inc(key_start);if key_start>maxkeys then key_start:=0;

 tmp:=t;t:=t and 127;
 getkeys:=tmp;
until tmp<128;
end;

begin
repeat
textcolor(white);
writeln;
writeln;
writeln('<1>....Player 1');
writeln('<2>....Player 2');
writeln('<3>....Player 3');
writeln('<ESC>..fertig');
ch:=readkey;
case ch of
 '1': no:=1;
 '2': no:=2;
 '3': no:=3;
 else no:=0;
end;
if no>0 then begin
 textcolor(lightgray);
 init_timer;
 writeln;
 writeln('Tasten fÅr Spieler ',no);
 writeln;
 write('Oben  : ');
 x:=getkeys;
 writeln(keycodes[x]);
 player[no].up:=x;

 write('Unten : ');
 x:=getkeys;
 writeln(keycodes[x]);
 player[no].down:=x;

 write('Links : ');
 x:=getkeys;
 writeln(keycodes[x]);
 player[no].left:=x;

 write('Rechts: ');
 x:=getkeys;
 writeln(keycodes[x]);
 player[no].right:=x;

 write('Bombe : ');
 x:=getkeys;
 writeln(keycodes[x]);
 player[no].drop:=x;

 write('Kicken: ');
 x:=getkeys;
 writeln(keycodes[x]);
 player[no].kick:=x;

 restore_timer;
 writeln;
 write('<Taste>');readkey;
end;
until ch=#27;
end;

var oldcur,cur:byte;

procedure write_number2(no:byte);
var a,b: byte;
begin
for b:=0 to 15 do
 for a:=0 to 6 do
  if numbers[no,b,a]=1 then setpix_13h(a+210,b+103,234,$a000)
                       else setpix_13h(a+210,b+103,getpix_13h(a+210,b+103,seg3),$a000);
end;

procedure doom_startup;
var a: byte;

begin
writeln('DOS/4GW Professional Protected Mode Run-time  Version 1.94');
writeln('Copyright (c) Rational Systems Inc. 1990-1993');
delay(3000);
textbackground(black);textcolor(lightgray);clrscr;
textbackground(blue);textcolor(yellow);
writeln('                          K-BOOM Operating System v1.1                         ');
textbackground(black);textcolor(lightgray);
writeln('V_Init: allocate screens.');
writeln('M_LoadDefaults: Load system defaults.');delay(200);
writeln('Z_Init: Init zone memory allocation daemon.');
writeln('heap size: 0x3ab000');
writeln('W_Init: Init WADfiles.');
writeln('        commercial version.');delay(300);
writeln('===============================================================================');
writeln('             This version is NOT SHAREWARE, do not distribute!');
writeln('         Please report software piracy to the SPA: 1-800-388-PIR8');
writeln('===============================================================================');
writeln('M_Init: Init miscellaneous info.');
write  ('R_Init: Init K-BOOM refresh daemon......');
delay(2000);
for a:=1 to 14 do begin
 write('.');delay(100-a*10+300+random(200))
end;
writeln;writeln;writeln;
end;

procedure dias;
begin
loadpcx('s1.dat',seg1);
move(mem[seg1:0],mem[$a000:0],64000);
delay(4000);
fadeout;
fillchar(mem[$a000:0],64000,0);
loadpcx('s2.dat',seg1);
move(mem[seg1:0],mem[$a000:0],64000);
delay(4000);
fadeout;
fillchar(mem[$a000:0],64000,0);
loadpcx('s3.dat',seg1);
move(mem[seg1:0],mem[$a000:0],64000);
delay(4000);
fadeout;
fillchar(mem[$a000:0],64000,0);
loadpcx('s4.dat',seg1);
move(mem[seg1:0],mem[$a000:0],64000);
delay(4000);
fadeout;
fillchar(mem[$a000:0],64000,0);
loadpcx('s5.dat',seg1);
move(mem[seg1:0],mem[$a000:0],64000);
delay(4000);
fadeout;
fillchar(mem[$a000:0],64000,0);
end;

begin
{mem}
getmem(p1,64000);seg1:=seg(p1^);
getmem(p2,64000);seg2:=seg(p2^);
getmem(p3,64000);seg3:=seg(p3^);
{keybd}
load_config;
a:=ioresult;
doom_startup;
a:=0;
write('Tastatur konfigurieren?  ');
textcolor(white);
maskcursor;
repeat
gotoxy(25,16);
if a=0 then begin
 textbackground(black);
 write('  Ja   ');
 textbackground(blue);
 write(' NEIN ')
end else begin
 textbackground(blue);
 write('  JA   ');
 textbackground(black);
 write(' Nein ')
end;
ch:=readkey;
case ch of
 #0: begin
      ch:=readkey;
      case ch of
       #72,#75,#77,#80: a:=a xor 1;
      end;
     end;
end;
until ch=#13;
maskcursor;
if a=1 then setup_keys;;
{gfx}
assign(numb_file,'numbers.dat');
reset(numb_file);read(numb_file,numbers);close(numb_file);
setmode($13);
dias;
setreg(11,0,0,0);
set_overscan(11);
show64('video.dat',seg3);
move(mem[seg3:0],mem[$a000:0],64000);
write_number2(maxwins);
setreg(233,60,60,60);
setreg(234,20,20,20);
setreg(235,20,20,20);
cur:=1;oldcur:=1;
for a:=0 to 40 do begin
 waitretrace;
 setreg(255-cur,20+a,20+a,20+a);
end;
repeat
write_number2(maxwins);
{if cur<>oldcur then
for a:=0 to 40 do begin
 waitretrace;
 setreg(232+cur,20+a,20+a,20+a);
end;}
oldcur:=cur;
ch:=readkey;
case ch of
 #0: begin
  ch:=readkey;
  case ch of
   #72: if cur>1 then dec(cur);
   #80: if cur<3 then inc(cur);
   #77: if (cur=2) and (maxwins<9) then inc(maxwins);
   #75: if (cur=2) and (maxwins>1) then dec(maxwins);
  end;
 end;
 #13: case cur of
       1: begin
           play_round;
           {setmode($13);}
           show64('video.dat',seg3);
           set_overscan(11);
           move(mem[seg3:0],mem[$a000:0],64000);
           setreg(233,60,60,60);
           setreg(234,20,20,20);
           setreg(235,20,20,20);
           cur:=1;
          end;
       2: if maxwins<9 then begin inc(maxwins) end;
       3: _exit:=true;
      end;
end;
if cur<>oldcur then
for a:=0 to 40 do begin
 waitretrace;
 setreg(232+oldcur,60-a,60-a,60-a);
 setreg(232+cur,20+a,20+a,20+a);
end;
until _exit;
save_config;
fillchar(mem[$a000:0],64000,0);
set_overscan(0);
loadpcx('mpeg.dat',$a000);
delay(6000);
fadeout;
freemem(p1,64000);
freemem(p2,64000);
freemem(p3,64000);
fillchar(mem[$a000:0],64000,0);
show_fli(30);
{fillchar(mem[$a000:0],64000,0);
loadpcx('c:\kaboom\mmx.dat',seg1);
move(mem[seg1:0],mem[$a000:0],64000);}
{delay(8000);}
setmode(3)
end.

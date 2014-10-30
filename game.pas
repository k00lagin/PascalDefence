program game;
uses crt, keyboard;
type
	coord = 1..30;
	mob = record
		letter : char;
		x : coord;
		y : coord;
		hp : integer;
		damage : byte;
		speed : byte;
	end;
var a:char;
b:integer;
x,y,i,j,f,counter:shortint;
map,prevmap: array[1..30,1..20] of char;
money:Longint;
hp:Byte;
isHpChanged,isMoneyChanged:Boolean;
mobs: array of mob;
K : TKeyEvent;
input: file of char;
procedure frite(tclr,bclr:byte; text:string);
begin
	textcolor(tclr);
	textbackground(bclr);
	write(text);
end;
function isAvailable(val:char):Boolean;
begin
	if (val=' ') or (val='f') then isAvailable:=true
	else isAvailable:=false;
end;
procedure removeMob(var a: array of mob; n: integer);
var i:byte;
begin
  for i := n to 99 do
    a[i] := a[i+1];
    with (a[100]) do
    begin
    	x:= 1;
    	y:= 1;
    	hp:= 0;
    	damage:= 0;
    	speed:= 0;
    end;
end;
procedure spawnMob(letter:char; x,y:coord; hp:integer; damage,speed:byte);
var a:Integer;
begin
	a:=high(mobs);
	setlength(mobs,a + 2);
	inc(a);
	mobs[a].letter:=letter;
	mobs[a].x:=x;
	mobs[a].y:=y;
	mobs[a].hp:=hp;
	mobs[a].damage:=damage;
	mobs[a].speed:=speed;
end;
procedure draw();
var i,j:integer;
begin
	for i:=1 to 30 do
	  for j:=1 to 20 do
	  	if ((map[i,j]<>prevmap[i,j]) or (map[i,j]='±'))  then begin
	  		gotoxy(i,j);
	    	case map[i,j] of
	    		' ': begin frite(0,15,' '); end;
	    		'f': begin frite(10,2,'°'); end; //field
	    		'#': begin frite(8,7,'#'); end; //rocks
	    		's': begin frite(15,6,'°'); end; //sand
	    		'h': begin frite(2,7,'h'); end; //small tower
	    		'H': begin frite(2,7,'H'); end; //big tower
	    		'²','±','°': begin if odd(i) then frite(8,7,'ά') else frite(8,7,'ί'); end //exit,entrance,path
	    		else frite(7,0,map[i,j]);
	    	end;
	    end;
	prevmap:=map;
///////////////////
	if (high(mobs)>=0) then
	for counter:=0 to high(mobs) do begin
		gotoxy(mobs[counter].x,mobs[counter].y);
		write(mobs[counter].letter);
	end;
///////////////////
	if (isMoneyChanged) then begin textbackground(0); textcolor(7); gotoxy(17,24); write(money:3); isMoneyChanged:=false; end;
	if (isHpChanged) then begin textbackground(0); textcolor(7); gotoxy(6,24); write(hp:3);	isHpChanged:=false; end;
	gotoxy(x,y);
end;
procedure gameOver();
begin
	window(3,3,10,5);
	gotoxy(2,3);
	write('Game Over');
	window(1,1,80,25);
end;
procedure decHP(damage:integer);
begin
	isHpChanged:=true;
	if (hp>=damage) then dec(hp,damage)
	else hp:=0;
	if (hp=0) then gameOver;
end;
procedure update();
begin
	if (high(mobs)>=0) then
	for counter:=0 to high(mobs) do begin
		if (map[mobs[counter].x,mobs[counter].y]='°') then begin decHP(10); end;
		if (mobs[counter].x<30) then mobs[counter].x:=mobs[counter].x+1;
	end;
end;
begin
	clrscr;
	assign(input, '1.map'); reset(input);
	for j:=1 to 20 do
	for i:= 1 to 30 do begin
		read(input,map[i,j]);
		if (map[i,j]=#13) then read(input,map[i,j],map[i,j]);
	end;
	close(input);
	InitKeyBoard;
	hp:=200;
	money:=100;
	spawnMob('',1,8,1,2,3);
gotoxy(1,22);
write('ΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝΝ');
gotoxy(2,24); write('HP: ',hp:3,'     $: ',money:3);
x:=1; y:=1;
repeat
	K:=GetKeyEvent;
	K:=TranslateKeyEvent(K);
	case GetKeyEventChar(K) of
	'd': if (x<30) then x:=x+1;
	'a': if (x>1) then x:=x-1;
	's': if (y<20) then y:=y+1;
	'w': if (y>1) then y:=y-1;
	'h': if ((money>=10) and isAvailable(map[x,y])) then begin map[x,y]:='h'; isMoneyChanged:=true; money:=money-10; end;
	'j': if ((money>=20) and isAvailable(map[x,y])) then begin map[x,y]:='H'; isMoneyChanged:=true; money:=money-20; end;
	'k': map[x,y]:='0';
	'l': map[x,y]:='1';
	//'g': gameOver();
	end;
	draw();
	update();
Until (GetKeyEventChar(K)='q');
DoneKeyBoard;
end.
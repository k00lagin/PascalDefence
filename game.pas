program game;
uses crt, keyboard;
type
	coord = 1..30;
	mob = record
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
money,prevmoney:Longint;
hp,prevhp:Byte;
mobs: array[1..100] of mob;
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
procedure draw();
var i,j:integer;
begin
	for i:=1 to 30 do
	  for j:=1 to 20 do
	  	if ((map[i,j]<>prevmap[i,j]) or (map[i,j]='�'))  then begin
	  		gotoxy(i,j);
	    	case map[i,j] of
	    		' ': begin frite(0,15,' '); end;
	    		'f': begin frite(10,2,'�'); end; //field
	    		'#': begin frite(8,7,'#'); end; //rocks
	    		's': begin frite(15,6,'�'); end; //sand
	    		'h': begin frite(2,7,'h'); end; //small tower
	    		'H': begin frite(2,7,'H'); end; //big tower
	    		'�': begin if odd(i) then frite(8,7,'�') else frite(8,7,'�'); end; //exit
	    		'�': begin if odd(i) then frite(8,7,'�') else frite(8,7,'�'); end; //entrance
	    		'�': begin if odd(i) then frite(8,7,'�') else frite(8,7,'�'); end //path
	    		else frite(7,0,map[i,j]);
	    	end;
	    end;
	prevmap:=map;
{
	for counter:=1 to 1 do begin
		if (map[mobs[counter].x,mobs[counter].y]='�') then hp:=hp-10;
		gotoxy(mobs[counter].x,mobs[counter].y);
		write('q');
		if (mobs[counter].x<30) then mobs[counter].x:=mobs[counter].x+1;
	end;	
	if (money<>prevmoney) then begin textbackground(0); textcolor(7); gotoxy(17,24); write(money:3); end;
	gotoxy(x,y);}
end;
procedure update();
begin
	
end;
begin
	clrscr;
	assign(input, '1.map'); reset(input);
	for j:=1 to 20 do
		for i := 1 to 30 do begin
			//while (not eoln( input )) do read;
			read(input,map[i,j]);
			if (map[i,j]=#13) then read(input,map[i,j],map[i,j]);
			//gotoxy(i,j);
			//write(map[i,j]);
		end;
	close(input);

	InitKeyBoard;
	hp:=200;
	money:=100;
	//mobs[1].x:=1;
	//mobs[1].y:=10;
gotoxy(1,22);
write('��������������������������������������������������������������������������������');
gotoxy(2,24); write('HP: ',hp:3,'     $: ',money:3);
x:=1; y:=1; //map[1,3]:='1';
repeat
	K:=GetKeyEvent;
	K:=TranslateKeyEvent(K);
	if (keypressed) then begin
	a:=readkey;
	case GetKeyEventChar(K) of
	'd': if (x<30) then x:=x+1;
	'a': if (x>1) then x:=x-1;
	's': if (y<20) then y:=y+1;
	'w': if (y>1) then y:=y-1;
	'h': if ((money>=10) and isAvailable(map[x,y])) then begin map[x,y]:='h'; prevmoney:=money; money:=money-10; end;
	'j': if ((money>=20) and isAvailable(map[x,y])) then begin map[x,y]:='H'; prevmoney:=money; money:=money-20; end;
	'k': map[x,y]:='0';
	'l': map[x,y]:='1';
	'g': map[x,y]:='2';
	#27: ;
	end;	
	end;
	draw();
Until (GetKeyEventChar(K)='q');
DoneKeyBoard;
end.
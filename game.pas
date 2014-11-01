program game;
uses crt,keyboard,sysutils,DateUtils;
type
	coord = 1..30;
	mob = record
		x : coord;
		y : coord;
		hp : integer;
		number: byte;
	end;
	dot = record
		x : coord;
		y : coord;		
	end;
	specie = record
		letter : char;
		maxHp: word;
		damage: word;
		speed: byte;
	end;
	tower = record
		x : coord;
		y : coord;
		number : byte;
		lastShoot: TDateTime;
	end;
	kind = record
		letter : char;
		damage : word;
		range : byte;
		cooldown : word;
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
toRedraw: array of dot;
//TIMERS
lastRedraw,lastUpdate: TDateTime;
/////
species: array of specie;
towers: array of tower;
kinds: array of kind;
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
procedure removeMob(n: integer);
var i:integer;
begin
	if (n<high(mobs)) then for i:= n to high(mobs)-1 do mobs[i]:= mobs[i+1];
	setlength(mobs,high(mobs));
end;
procedure spawnMob(number:byte; x,y:coord);
var a:Integer;
begin
	a:=high(mobs);
	setlength(mobs,a + 2);
	inc(a);
	mobs[a].x:=x;
	mobs[a].y:=y;
	mobs[a].number:=number;
	mobs[a].hp:=species[number].maxHp;
end;
procedure buildTower(number:byte; x,y:coord);
var a:Integer;
begin
	a:=Length(towers);
	setlength(towers,a + 1);
	towers[a].x:=x;
	towers[a].y:=y;
	towers[a].number:=number;
	towers[a].lastShoot:=now;
	map[x,y]:=kinds[number].letter;
end;
procedure destroyTower(n: integer);
var i:byte;
begin
end;
procedure draw();
var i,j:integer;
begin
	for i:=1 to 30 do
	  for j:=1 to 20 do
	  	if (map[i,j]<>prevmap[i,j])  then begin
	  		gotoxy(i,j);
	  		case map[i,j] of
	  			' ': frite(0,15,' ');
	  			'f': frite(10,2,'ฐ');  //field
	  			'#': frite(8,7,'#');  //rocks
	  			's': frite(15,6,'ฐ');  //sand
	  			'h': frite(2,7,'h');  //small tower
	  			'H': frite(2,7,'H');  //big tower
	  			'ฒ','ฑ','ฐ': begin if odd(i) then frite(8,7,'Ü') else frite(8,7,'฿'); end //exit,entrance,path
	  			else frite(7,0,map[i,j]);
	  		end;
	    end;
	 for i:=high(toRedraw) downto 0 do begin
	 	gotoxy(toRedraw[i].x,toRedraw[i].y);
	    case map[toRedraw[i].x,toRedraw[i].y] of
	    	' ': frite(0,15,' ');
	    	'f': frite(10,2,'ฐ');  //field
	    	'#': frite(8,7,'#');  //rocks
	    	's': frite(15,6,'ฐ');  //sand
	    	'h': frite(2,7,'h');  //small tower
	    	'H': frite(2,7,'H');  //big tower
	    	'ฒ','ฑ','ฐ': begin if odd(toRedraw[i].x) then frite(8,7,'Ü') else frite(8,7,'฿'); end //exit,entrance,path
	    	else frite(7,0,map[toRedraw[i].x,toRedraw[i].y]);
	    end;
	    setlength(toRedraw,high(toRedraw));
	 end;
	prevmap:=map;
///////////////////
	if (high(mobs)>=0) then
	for counter:=0 to high(mobs) do begin
		gotoxy(mobs[counter].x,mobs[counter].y);
		if (mobs[counter].hp=species[mobs[counter].number].maxHp) then frite(8,7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.8) then frite(10,7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.6) then frite(2, 7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.4) then frite(14,7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.2) then frite(12,7,species[mobs[counter].number].letter)
		else frite(4,7,species[mobs[counter].number].letter);
	end;
{	if (high(towers)>=0) then
	for counter:=0 to high(towers) do begin
		gotoxy(towers[counter].x,towers[counter].y);
		frite(8,7,kinds[towers[counter].number].letter)
	end;}
///////////////////
	if (isMoneyChanged) then begin textbackground(0); textcolor(7); gotoxy(17,24); write(money:3); isMoneyChanged:=false; end;
	if (isHpChanged) then begin textbackground(0); textcolor(7); gotoxy(6,24); write(hp:3);	isHpChanged:=false; end;
	gotoxy(x,y);
	lastRedraw:=now;
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
var a,i,j:Integer;
begin
	if (high(mobs)>=0) then
	for counter:=high(mobs) downto 0 do begin
		if (mobs[counter].x<30) then begin
			a:=high(toRedraw);
			setlength(toRedraw,a + 2);
			inc(a);
			toRedraw[a].x:=mobs[counter].x;
			toRedraw[a].y:=mobs[counter].y;
			mobs[counter].x:=mobs[counter].x+1;
		end;
		if (map[mobs[counter].x,mobs[counter].y]='ฐ') then begin decHP(species[mobs[counter].number].damage); removeMob(counter); end
		else if (mobs[counter].hp=0) then begin money:=money+10; isMoneyChanged:=true; removeMob(counter); end;
	end;
	if (high(towers)>=0) then
	for i:=0 to high(towers) do
		for j:=0 to high(mobs) do begin
			if (MilliSecondsBetween(towers[i].lastShoot,now)>=kinds[towers[i].number].cooldown) then
			if ((abs(towers[i].x - mobs[j].x) <= kinds[towers[i].number].range) and (abs(towers[i].y - mobs[j].y) <= kinds[towers[i].number].range)) then begin
				if (mobs[j].hp>=kinds[towers[i].number].damage) then mobs[j].hp:=mobs[j].hp - kinds[towers[i].number].damage
				else mobs[j].hp:= 0;
				towers[i].lastShoot:=now;
				break;
			end;
	end;
	if (random(100)<=10) then spawnMob(0,1,8);
	lastUpdate:=now;
end;
////////////////////
////////////////////
////////////////////

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
	setlength(species,1);
	species[0].letter:='W';
	species[0].maxHp:=200;
	species[0].speed:=10;
	species[0].damage:=10;
	setlength(kinds,2);
	kinds[0].letter:='h';
	kinds[0].damage:=5;
	kinds[0].range:=1;
	kinds[0].cooldown:=200;
	kinds[1].letter:='H';
	kinds[1].damage:=15;
	kinds[1].range:=2;
	kinds[1].cooldown:=600;
	//buildTower(0,8,7);
	//buildTower(0,16,9);
	//buildTower(0,20,7);
	spawnMob(0,1,8);
gotoxy(1,22);
write('ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
gotoxy(2,24); write('HP: ',hp:3,'     $: ',money:3);
x:=1; y:=1;
lastUpdate:=now; lastRedraw:=now;
repeat
	if KeyPressed then begin
		K:=GetKeyEvent;
		K:=TranslateKeyEvent(K);
		case GetKeyEventChar(K) of
		'd': if (x<30) then x:=x+1;
		'a': if (x>1) then x:=x-1;
		's': if (y<20) then y:=y+1;
		'w': if (y>1) then y:=y-1;
		'h': if ((money>=10) and isAvailable(map[x,y])) then begin buildTower(0,x,y); isMoneyChanged:=true; money:=money-10; end;
		'j': if ((money>=20) and isAvailable(map[x,y])) then begin buildTower(1,x,y); isMoneyChanged:=true; money:=money-20; end;
		'k': map[x,y]:='0';
		'l': map[x,y]:='1';
		//'g': gameOver();
		end;
	end;
	if (MilliSecondsBetween(lastRedraw,now)>40) then draw();
	if (MilliSecondsBetween(lastUpdate,now)>300) then update();
Until (GetKeyEventChar(K)='q');
DoneKeyBoard;
end.

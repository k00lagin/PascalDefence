program game;
uses crt,keyboard,sysutils,DateUtils;
type
	coord = 1..30;
	mob = record
		x : coord;
		y : coord;
		dir: byte;
		hp : integer;
		number: byte;
		lastStep : TDateTime;
	end;
	dot = record
		x : coord;
		y : coord;		
	end;
	specie = record
		letter : char;
		maxHp: word;
		damage: word;
		stepDelay: word;
		reward : byte;
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
		price : byte;
	end;
	spawnPoint = record
		x,y : coord;
		dir : byte;
	end;
var a:char;

b:integer;
x,y,tx,ty,i,j,f,counter:shortint;
map,prevmap: array[1..30,1..20] of char;
money:Longint;
hp:Byte;
isHpChanged,isMoneyChanged,paused,isPauseChanged,isInfoVis:Boolean;
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
spawnPoints: array of spawnPoint;
procedure frite(tclr,bclr:byte; text:string);
begin
	textcolor(tclr);
	textbackground(bclr);
	write(text);
end;
function isAvailable(val:char):Boolean;
begin
	if (val=' ') or (val='f') or (val='b') then isAvailable:=true
	else isAvailable:=false;
end;
procedure removeMob(n: integer);
var i,a:integer; x,y:coord;
begin
	x:=mobs[n].x; y:=mobs[n].y;
	a:=high(toRedraw); setlength(toRedraw,a + 2); inc(a); toRedraw[a].x:=x; toRedraw[a].y:=y;
	if (n<high(mobs)) then for i:= n to high(mobs)-1 do mobs[i]:= mobs[i+1];
	setlength(mobs,high(mobs));
end;
procedure spawnMob(number,point:byte);
var a:Integer;
begin
	a:=high(mobs);
	setlength(mobs,a + 2);
	inc(a);
	mobs[a].x:=spawnPoints[point].x;
	mobs[a].y:=spawnPoints[point].y;
	mobs[a].dir:=spawnPoints[point].dir;
	mobs[a].number:=number;
	mobs[a].lastStep:=now;
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
	isMoneyChanged:=true;
	money:=money - kinds[towers[a].number].price;
end;
procedure destroyTower(x,y: coord);
var i,j:byte;
begin
	if (high(towers)>=0) then
	for i:=high(towers) downto 0 do if ((towers[i].x=x) and (towers[i].y=y)) then begin
		map[x,y]:='b';
		isMoneyChanged:=true;
		money:=money + kinds[towers[i].number].price div 2;
		if (i<high(towers)) then for j:= i to high(towers)-1 do towers[j]:= towers[j+1];
		setlength(towers,high(towers));
	end;
end;
procedure drawInfo();
var i:word;
begin
	for i:=2 to 24 do begin gotoxy(66,i); frite(8,0,'Û'); end;
	textcolor(7);
	textbackground(0);
	gotoxy(68,3);
	write('"P": pause');
end;
procedure hideInfo();
var i:word;
begin
	//for i:=2 to 24 do begin gotoxy(66,i); frite(0,0,' '); end;
	window(66,2,79,24);
	textbackground(0);
	clrscr;
	window(1,1,80,25);
end;
procedure draw();
var i,j:integer;
begin
	for i:=1 to 30 do
	  for j:=1 to 20 do
	  	if (map[i,j]<>prevmap[i,j])  then begin
	  		gotoxy(i+tx,j+ty);
	  		case map[i,j] of
	  			' ': frite(0,15,' ');
	  			'f': frite(10,2,'°');  //field
	  			'#': frite(8,7,'#');  //rocks
	  			's': frite(15,6,'°');  //sand
	  			'h': frite(2,7,'h');  //small tower
	  			'H': frite(2,7,'H');  //big tower
	 	    	'b': frite(8,6,'°'); //black ground
	  			'²','±','°','<','>','^','v': begin if odd(i) then frite(8,7,'Ü') else frite(8,7,'ß'); end //exit,entrance,path
	  			else frite(7,0,map[i,j]);
	  		end;
	    end;
	 for i:=high(toRedraw) downto 0 do begin
	 	gotoxy(toRedraw[i].x+tx,toRedraw[i].y+ty);
	    case map[toRedraw[i].x,toRedraw[i].y] of
	    	' ': frite(0,15,' ');
	    	'f': frite(10,2,'°');  //field
	    	'#': frite(8,7,'#');  //rocks
	    	's': frite(15,6,'°');  //sand
	    	'h': frite(2,7,'h');  //small tower
	    	'H': frite(2,7,'H');  //big tower
	    	'b': frite(8,6,'°'); //black ground
	    	'²','±','°','<','>','^','v': begin if odd(toRedraw[i].x) then frite(8,7,'Ü') else frite(8,7,'ß'); end //exit,entrance,path
	    	else frite(7,0,map[toRedraw[i].x,toRedraw[i].y]);
	    end;
	    setlength(toRedraw,high(toRedraw));
	 end;
	prevmap:=map;
///////////////////
	if (high(mobs)>=0) then
	for counter:=0 to high(mobs) do begin
		gotoxy(mobs[counter].x+tx,mobs[counter].y+ty);
		if (mobs[counter].hp=species[mobs[counter].number].maxHp) then frite(8,7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.8) then frite(10,7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.6) then frite(2, 7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.4) then frite(14,7,species[mobs[counter].number].letter)
		else if (mobs[counter].hp / species[mobs[counter].number].maxHp > 0.2) then frite(12,7,species[mobs[counter].number].letter)
		else frite(4,7,species[mobs[counter].number].letter);
	end;
///////////////////
	if (isMoneyChanged) then begin textcolor(0); textbackground(7); gotoxy(20,25); write(money:4,' '); isMoneyChanged:=false; end;
	if (isHpChanged) then begin textcolor(0); textbackground(7); gotoxy(8,25); write(hp:3);	isHpChanged:=false; end;
	if (isPauseChanged) then if paused then begin gotoxy(33,1); frite(0,7,'['); gotoxy(48,1); frite(0,7,']'); isPauseChanged:=false; end else begin gotoxy(33,1); frite(0,7,' '); gotoxy(48,1); frite(0,7,' '); isPauseChanged:=false; end;
	gotoxy(x+tx,y+ty);
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
		if (MilliSecondsBetween(mobs[counter].lastStep,now)>species[mobs[counter].number].stepDelay) then begin
			a:=high(toRedraw);
			setlength(toRedraw,a + 2);
			inc(a);
			toRedraw[a].x:=mobs[counter].x;
			toRedraw[a].y:=mobs[counter].y;
			case map[mobs[counter].x,mobs[counter].y] of
				'>': mobs[counter].dir:=0;
				'^': mobs[counter].dir:=1;
				'<': mobs[counter].dir:=2;
				'v': mobs[counter].dir:=3;
			end;
			case mobs[counter].dir of
				0: mobs[counter].x:=mobs[counter].x+1;
				1: mobs[counter].y:=mobs[counter].y-1;
				2: mobs[counter].x:=mobs[counter].x-1;
				3: mobs[counter].y:=mobs[counter].y+1;
			end;
			mobs[counter].lastStep:=now;
		end;
		if (map[mobs[counter].x,mobs[counter].y]='°') then begin decHP(species[mobs[counter].number].damage); removeMob(counter); end;
	end;
	if (high(towers)>=0) then
	for i:=0 to high(towers) do
		for j:=0 to high(mobs) do begin
			if (MilliSecondsBetween(towers[i].lastShoot,now)>=kinds[towers[i].number].cooldown) then
			if ((abs(towers[i].x - mobs[j].x) <= kinds[towers[i].number].range) and (abs(towers[i].y - mobs[j].y) <= kinds[towers[i].number].range)) then begin
				if (mobs[j].hp>=kinds[towers[i].number].damage) then mobs[j].hp:=mobs[j].hp - kinds[towers[i].number].damage
				else mobs[j].hp:= 0;
				if (mobs[j].hp=0) then begin money:=money+10; isMoneyChanged:=true; removeMob(j); end;
				towers[i].lastShoot:=now;
				break;
			end;
	end;
	if (random(1400)<=15) then if (random(10)<2) then spawnMob(1,0) else spawnMob(0,0);
	lastUpdate:=now;
end;
////////////////////
////////////////////
////////////////////

begin
	paused:=false;
	isInfoVis:=false;
	window(1,1,80,25);
	clrscr;
	gotoxy(1,25); textcolor(8); textbackground(7); write('ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ');
	//gotoxy(80,25); write('Û',#13);
	tx:=25; ty:=2;
	gotoxy(1,1); textcolor(8); textbackground(7); write('ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ');
	gotoxy(50,1); write('ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ');
	for j:=2 to 24 do begin
		gotoxy(1,j);
		frite(8,0,'Û');
		gotoxy(80,j);
		frite(8,0,'Û');
	end;
	
	gotoxy(32,1); textcolor(0); textbackground(7); write('  Pascal Defence  ');
	assign(input, '1.map'); reset(input);
	for j:=1 to 20 do begin
		for i:= 1 to 30 do begin
			read(input,map[i,j]);
			if (map[i,j]='²') then begin
				setlength(spawnPoints,Length(spawnPoints)+1);
				spawnPoints[high(spawnPoints)].x:=i;
				spawnPoints[high(spawnPoints)].y:=j;
				if (i= 1) then spawnPoints[high(spawnPoints)].dir:=0
				else if (j=20) then spawnPoints[high(spawnPoints)].dir:=1
				else if (i=30) then spawnPoints[high(spawnPoints)].dir:=2
				else if (j= 1) then spawnPoints[high(spawnPoints)].dir:=3;
			end;
		end;
		//read(input,map[i,j],map[i,j]);
	end;
	close(input);
	InitKeyBoard;
	hp:=200;
	money:=100;
	setlength(species,2);
	species[0].letter:='W';
	species[0].maxHp:=200;
	species[0].stepDelay:=400;
	species[0].damage:=10;
	species[1].letter:='S';
	species[1].maxHp:=160;
	species[1].stepDelay:=100;
	species[1].damage:=10;
	setlength(kinds,2);
	kinds[0].letter:='h';
	kinds[0].damage:=5;
	kinds[0].range:=1;
	kinds[0].cooldown:=200;
	kinds[0].price:=10;
	kinds[1].letter:='H';
	kinds[1].damage:=15;
	kinds[1].range:=2;
	kinds[1].cooldown:=600;
	kinds[1].price:=20;
	spawnMob(0,0);
//gotoxy(1,22);
//write('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ');
gotoxy(3,25); write(' HP:     ');
gotoxy(16,25); write(' $:      ');
isMoneyChanged:=true; isHpChanged:=true;
x:=1; y:=1;
lastUpdate:=now; lastRedraw:=now;
repeat
	if KeyPressed then begin
		K:=GetKeyEvent;
		K:=TranslateKeyEvent(K);
		case GetKeyEventChar(K) of
			'd','¢': if (x<30) then x:=x+1;
			'a','ä': if (x>1) then x:=x-1;
			's','ë': if (y<20) then y:=y+1;
			'w','æ': if (y>1) then y:=y-1;
			'h','à': if ((money>=10) and isAvailable(map[x,y])) then begin buildTower(0,x,y); end;
			'j','®': if ((money>=20) and isAvailable(map[x,y])) then begin buildTower(1,x,y); end;
			'k','«': map[x,y]:=' ';
			'l','¤': map[x,y]:='f';
			'i','è': begin isInfoVis:=not isInfoVis; if isInfoVis then drawInfo else hideInfo; end;
			'p','§': begin paused:=not paused; isPauseChanged:=true end;
			'r','ª': destroyTower(x,y);
			//'g': gameOver();
		end;
		case k of
			33619713: begin isInfoVis:=not isInfoVis; if isInfoVis then drawInfo else hideInfo; end;
			33619745: if (y>1) then y:=y-1;
			33619751: if (y<20) then y:=y+1;
			33619749: if (x<30) then x:=x+1;
			33619747: if (x>1) then x:=x-1;
		end
	end;
	if (MilliSecondsBetween(lastRedraw,now)>40) then draw();
	if ((MilliSecondsBetween(lastUpdate,now)>40) and not paused) then update();
Until (GetKeyEventChar(K)='q');
DoneKeyBoard;
end.

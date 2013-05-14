{   hra-had - an simple pascal game called 'hra-had' simmilar to snake
    Copyright (C) 2009-2013 Matej Ridzon

    This file is part of hra-had.

    Hra-had is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.}

program Had;
{$mode objfpc}
uses graph,wincrt,pohyb;

const P=1; H=2; L=3; D=4;              //definicia smerov (P - pravá, LP - Ľavá-Pravá)
      LD=5; LP=6; LH=7; DP=8; DH=9; PH=10;
      DL=5; PL=6; HL=7; PD=8; HD=9; HP=10;
      NazovHry='Hra HAD :)';
      Menu1='ZACNI HRU!'; Menu2='NASTAVENIA'; Menu3='POMOC'; Menu4='NAJLEPSIE VYSLEDKY'; Menu5='KONIEC';
      MenuN3='Rychlost: '; MenuN2='Maximalne Y: '; MenuN1='Maximalne X: '; MenuN='Nastavenia hry:';
      MenuN4='Uroven AI: ';
      Help1='Opustis stlacenim klavesy ESC'; Help2='Editujes a potvrdis klavesom ENTER';
      Srychlost=700; Qrychlost=0.799630916025;  //Pre pocitanie delayu geometrickou postupnostou
      Zrus1='Sam si to chcel O_o'; Zrus2='Narazil si do steny!!!'; Zrus3='Zjedol si si telo...';
      Zrus4='Obsadil si cele uzemie...';
      Vypisskore='Tvoje skore: ';

type THskore=record              //Highskore
             skore:longint;
             meno:string[12];
             end;
     Tsubor=record               //nastavenia hry
            KoniecX,KoniecY:longint;
            rychlost,AI:longint;
            skore:array[1..17] of THskore;
            end;
     Tfile= file of Tsubor;

var gd,gm:smallint;                                               //graf
    StartX,StartY,KoniecX,KoniecY:longint;                        //rozmery pola
    CurX,CurY,LastX,LastY,CurSmer,LastSmer:longint;               //smer hada 1
    Atyp,skore,priznak,rychlost,Arychlost,vyber,Hdlzka:longint;
    MenuX1,MenuY1,MenuX2,MenuY2:longint;                          //pozicia menu
    c,c2:char;                                                    //nacitany klaves
    s:string;
    f:Tfile;                                                      //subor s nastaveniami
    subor:Tsubor;
    subtmp:THskore;
    AIpole:TAIpole;                                               //AI

function XnaY(x:extended;y:longint):extended;        //pre vypocet highskore
var Ri:longint;
begin
XnaY:=1;
for Ri:=1 to y do
 begin
 XnaY:=XnaY*x;
 end;
end;

procedure vymazblok(x1,y1:longint);                  //vymaze blok (7x7)
begin
setfillstyle(solidfill,black);
setcolor(black);
Bar(x1-3,y1-3,x1+3,y1+3);
end;

function zistismer(x1,y1:longint):byte;              //zisti smer hada (aktualnej casti tela)
var t1,t2,t3,t4,ts:longint;
begin                           //white=15
t1:=GetPixel(x1-3,y1);
t2:=GetPixel(x1,y1+3);
t3:=GetPixel(x1+3,y1);
t4:=GetPixel(x1,y1-3);
ts:=t1+t2+t3+t4;
if ts=30 then
 begin
 if (t1=15) and (t2=15) then zistismer:=LD
 else if (t1=15) and (t3=15) then zistismer:=LP
 else if (t1=15) and (t4=15) then zistismer:=LH
 else if (t2=15) and (t3=15) then zistismer:=DP
 else if (t2=15) and (t4=15) then zistismer:=DH
 else if (t2=15) and (t1=15) then zistismer:=DL
 else if (t3=15) and (t4=15) then zistismer:=PH
 else if (t3=15) and (t1=15) then zistismer:=PL
 else if (t3=15) and (t2=15) then zistismer:=PD
 else if (t4=15) and (t1=15) then zistismer:=HL
 else if (t4=15) and (t2=15) then zistismer:=HD
 else if (t4=15) and (t3=15) then zistismer:=HP;
 end
else
 begin
 if t1=15 then zistismer:=L
 else if t2=15 then zistismer:=D
 else if t3=15 then zistismer:=P
 else if t4=15 then zistismer:=H;
 end;
end;

procedure jedlo;                   //vygenerovanie jedla
var tx,ty:longint;
    ok:boolean;
begin
ok:=false;
if Hdlzka=(((subor.KoniecX-StartX) div 7)*((subor.KoniecY-StartY) div 7)) then
 begin            //ak je had uz v celom poli a neda sa generovat jedlo
 ok:=true;
 priznak:=4;
 end;
repeat
tx:=((Random((subor.KoniecX-StartX) div 7)*7))+StartX+3;
ty:=((Random((subor.KoniecY-StartY) div 7)*7))+StartY+3;
if Getpixel(tx,ty)=black then       //zisti ci je mozne na dane policko polozit jedlo
 begin
 setfillstyle(solidfill,green);
 setcolor(green);
 Bar(tx-1,ty-1,tx+1,ty+1);
 line(tx-2,ty,tx+2,ty);
 line(tx,ty-2,tx,ty+2);
 ok:=true;
 end;
until ok;
end;

procedure telohada(x1,y1:longint;typ:byte);  //vykreslovanie casti tela hada
begin
Setcolor(white);
setfillstyle(solidfill,white);
Bar(x1-2,y1-2,x1+2,y1+2);
case typ of
 1:begin
   setcolor(white);
   line(x1-3,y1-1,x1-3,y1+1); //lava
   line(x1+3,y1-1,x1+3,y1+1); //prava
   end;
 2:begin
   setcolor(white);
   line(x1-1,y1-3,x1+1,y1-3); //horna
   line(x1-1,y1+3,x1+1,y1+3); //dolna
   end;
 3:begin
   setcolor(white);
   line(x1-3,y1-1,x1-3,y1+1);
   line(x1-1,y1+3,x1+1,y1+3);
   putpixel(x1+2,y1-2,black);  //prava horna
   end;
 4:begin
   setcolor(white);
   line(x1-1,y1+3,x1+1,y1+3);
   line(x1+3,y1-1,x1+3,y1+1);
   putpixel(x1-2,y1-2,black);  //lava horna
   end;
 5:begin
   setcolor(white);
   line(x1+3,y1-1,x1+3,y1+1);
   line(x1-1,y1-3,x1+1,y1-3);
   putpixel(x1-2,y1+2,black);  //lava dolna
   end;
 6:begin
   setcolor(white);
   line(x1-1,y1-3,x1+1,y1-3);
   line(x1-3,y1-1,x1-3,y1+1);
   putpixel(x1+2,y1+2,black);  //prava dolna
   end;
 7:begin
   setcolor(black);
   line(x1+2,y1-2,x1+2,y1+2);
   putpixel(x1+1,y1-2,black);
   putpixel(x1+1,y1,black);
   putpixel(x1+1,y1+2,black);
   setcolor(white);
   line(x1-3,y1-1,x1-3,y1+1);
   end;
 8:begin
   setcolor(black);
   line(x1-2,y1-2,x1+2,y1-2);
   putpixel(x1-2,y1-1,black);
   putpixel(x1,y1-1,black);
   putpixel(x1+2,y1-1,black);
   setcolor(white);
   line(x1-1,y1+3,x1+1,y1+3);
   end;
 9:begin
   setcolor(black);
   line(x1-2,y1-2,x1-2,y1+2);
   putpixel(x1-1,y1-2,black);
   putpixel(x1-1,y1,black);
   putpixel(x1-1,y1+2,black);
   setcolor(white);
   line(x1+3,y1-1,x1+3,y1+1);
   end;
 10:begin
    setcolor(black);
    line(x1-2,y1+2,x1+2,y1+2);
    putpixel(x1-2,y1+1,black);
    putpixel(x1,y1+1,black);
    putpixel(x1+2,y1+1,black);
    setcolor(white);
    line(x1-1,y1-3,x1+1,y1-3);
    end;
 11:begin
    setcolor(black);
    line(x1+2,y1-1,x1+2,y1+1);
    putpixel(x1+1,y1,black);
    setcolor(white);
    line(x1-3,y1-1,x1-3,y1+1);
    end;
 12:begin
    setcolor(black);
    line(x1-1,y1-2,x1+1,y1-2);
    putpixel(x1,y1-1,black);
    setcolor(white);
    line(x1-1,y1+3,x1+1,y1+3);
    end;
 13:begin
    setcolor(black);
    line(x1-2,y1-1,x1-2,y1+1);
    putpixel(x1-1,y1,black);
    setcolor(white);
    line(x1+3,y1-1,x1+3,y1+1);
    end;
 14:begin
    setcolor(black);
    line(x1-1,y1+2,x1+1,y1+2);
    putpixel(x1,y1+1,black);
    setcolor(white);
    line(x1-1,y1-3,x1+1,y1-3);
    end;
end;
end;

procedure upravhada(typ,x1,y1:longint;var Smer1:longint;x2,y2,Smer2:longint);  //posun hada
var tsmer,t2smer:longint;
begin
Smer1:=zistismer(x1,y1);
if typ=0 then
 begin
  vymazblok(x1,y1);
  case Smer1 of
   P:begin
     tsmer:=zistismer(x1+7,y1);
     vymazblok(x1+7,y1);
     if tsmer=LH then telohada(x1+7,y1,14)
     else if tsmer=LP then telohada(x1+7,y1,13)
     else if tsmer=LD then telohada(x1+7,y1,12);
     end;
   H:begin
     tsmer:=zistismer(x1,y1-7);
     vymazblok(x1,y1-7);
     if tsmer=DL then telohada(x1,y1-7,11)
     else if tsmer=DH then telohada(x1,y1-7,14)
     else if tsmer=DP then telohada(x1,y1-7,13);
     end;
   L:begin
     tsmer:=zistismer(x1-7,y1);
     vymazblok(x1-7,y1);
     if tsmer=PD then telohada(x1-7,y1,12)
     else if tsmer=PL then telohada(x1-7,y1,11)
     else if tsmer=PH then telohada(x1-7,y1,14);
     end;
   D:begin
     tsmer:=zistismer(x1,y1+7);
     vymazblok(x1,y1+7);
     if tsmer=HP then telohada(x1,y1+7,13)
     else if tsmer=HD then telohada(x1,y1+7,12)
     else if tsmer=HL then telohada(x1,y1+7,11);
     end;
  end;
 end;
if (typ=0) or (typ=1) then
  begin
  t2smer:=zistismer(x2,y2);
  vymazblok(x2,y2);
  case Smer2 of
   P:begin
     case t2smer of
     H:begin
       telohada(x2,y2,5);
       telohada(x2+7,y2,7);
       end;
     L:begin
       telohada(x2,y2,1);
       telohada(x2+7,y2,7);
       end;
     D:begin
       telohada(x2,y2,4);
       telohada(x2+7,y2,7);
       end;
     end;
     end;
   H:begin
     case t2smer of
     P:begin
       telohada(x2,y2,5);
       telohada(x2,y2-7,8);
       end;
     L:begin
       telohada(x2,y2,6);
       telohada(x2,y2-7,8);
       end;
     D:begin
       telohada(x2,y2,2);
       telohada(x2,y2-7,8);
       end;
     end;
     end;
   L:begin
     case t2smer of
     P:begin
       telohada(x2,y2,1);
       telohada(x2-7,y2,9);
       end;
     H:begin
       telohada(x2,y2,6);
       telohada(x2-7,y2,9);
       end;
     D:begin
       telohada(x2,y2,3);
       telohada(x2-7,y2,9);
       end;
     end;
     end;
   D:begin
     case t2smer of
     P:begin
       telohada(x2,y2,4);
       telohada(x2,y2+7,10);
       end;
     H:begin
       telohada(x2,y2,2);
       telohada(x2,y2+7,10);
       end;
     L:begin
       telohada(x2,y2,3);
       telohada(x2,y2+7,10);
       end;
     end;
     end;
  end;
  end;
if typ=2 then
 begin
 priznak:=2;
 setcolor(red);
 setfillstyle(solidfill,red);
 floodfill(x2,y2,black);
 end
else if typ=3 then
 begin
 setcolor(red);
 setfillstyle(solidfill,red);
 priznak:=3;
 floodfill(x2,y2,black);
 end;
end;

procedure inicializuj;     //inicializacia hry
begin
Assign(f,'data.dat');
{$i-}                         //lokalny fpc compiler prepinac pre IOresult
Reset(f);
{$i+}
if IOresult<>0 then         //ak neexistuje subor, vytvori novy
 begin
 Rewrite(f);
 subor.KoniecX:=470;
 subor.KoniecY:=260;
 subor.rychlost:=10;
 subor.AI:=0;
 Write(f,subor);
 end
else Read(f,subor);
Close(f);
StartX:=50;                   //nastavi aktualnu poziciu
StartY:=50;
KoniecX:=750;
KoniecY:=400;
end;

procedure ohranic;         //vytvorenie siveho okna hry
var Ri:longint;
begin
setcolor(lightgray);
for Ri:=-7 to -1 do
 begin                     //podla premennych StartX/Y a KoniecX/Y zavisi velkost pola
 Rectangle(StartX+Ri,StartY+Ri,KoniecX-Ri-1,KoniecY-Ri-1);
 end;
end;

procedure zobrazskore;     //vypise aktualne skore hraca
begin
setcolor(black);
setfillstyle(solidfill,black);
Bar(StartX,StartY-10,StartX+length('Skore: '+s)*8,StartY-22);
setcolor(lightgreen);
Settextstyle(DefaultFont,HorizDir,1);
settextjustify(LeftText,BottomText);
str(skore,s);
OutTextXY(StartX,StartY-10,'Skore: '+s);
end;

procedure zjedol;
begin
Hdlzka:=Hdlzka+1;
if subor.AI=0 then skore:=skore+rychlost*2
 else skore:=skore+1;
atyp:=1;
jedlo;
zobrazskore;
end;

procedure Ozjedol(x:longint);   //otestovanie, ci nenarazil do seba
var tl:longint;
begin
case x of
 P:begin
   tl:=zistismer(CurX+7,CurY);
   if tl<5 then atyp:=0
   else atyp:=3;
   end;
 H:begin
   tl:=zistismer(CurX,CurY-7);
   if tl<5 then atyp:=0
   else atyp:=3;
   end;
 L:begin
   tl:=zistismer(CurX-7,CurY);
   if tl<5 then atyp:=0
   else atyp:=3;
   end;
 D:begin
   tl:=zistismer(CurX,CurY+7);
   if tl<5 then atyp:=0
   else atyp:=3;
   end;
end;
end;

procedure vyciernimenu;        //vymaze menu (okrem ohranicenia)
begin
setfillstyle(solidfill,black);
setcolor(black);
Bar(StartX,StartY,KoniecX,KoniecY);
end;

procedure upravhraciepole;     //prekresli hracie pole na mensie
var Ri:longint;
begin
setcolor(black);
for Ri:=-7 to -1 do
 begin
 Rectangle(StartX+Ri,StartY+Ri,KoniecX-Ri-1,KoniecY-Ri-1);
 end;
setcolor(lightgray);
for Ri:=-7 to -1 do
 begin
 Rectangle(StartX+Ri,StartY+Ri,subor.KoniecX-Ri-1,subor.KoniecY-Ri-1);
 end;
end;

procedure highscores;           //vypisovanie najlepsieho skore
var Ri,Rj,Ls1,Ls2:longint;
    c1:char;
    s1:string;
begin
vyciernimenu;
SetTextJustify(CenterText,TopText);
setfillstyle(solidfill,lightblue);
setcolor(lightblue);
settextstyle(SmallFont,0,3);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+10,NazovHry);
settextstyle(DefaultFont,0,1);
setcolor(red);
for Ri:=1 to 16 do
 begin
 str(Ri,s);
 if length(s)=1 then s:=' '+s;
 s:=s+'. '+subor.skore[Ri].meno+' ';
 str(subor.skore[Ri].skore,s1);
 Ls1:=length(subor.skore[Ri].meno);
 Ls2:=length(s1);
 for Rj:=Ls1+Ls2 to 24 do s:=s+'.';
 s:=s+' '+s1;
 OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+52+(Ri-1)*12,s);
 end;
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+52+(Ri+1)*12,Help1);
c1:=readkey;
while ord(c1)<>27 do c1:=readkey;
end;

procedure pomoc;              //menu - ponuka Pomoc
var c1:char;
begin
vyciernimenu;
SetTextJustify(CenterText,TopText);
setfillstyle(solidfill,lightblue);
setcolor(lightblue);
settextstyle(SmallFont,0,3);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+10,NazovHry);
settextstyle(DefaultFont,0,1);
setcolor(red);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+40,'Ovladanie: SIPKAMI');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+52,'Opustenie aktualnej hry: klavesom ESC');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+64,'Pauza medzernikom');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+76,'AI 0 az 5 0=vypnuty');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+88,'AI 1 - rychla simulacia AI 2 - simulacia podla rychlosti');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+100,'AI 3-5 zrychlena simulacia (ale pomalsia ako 1 - s urcitym delayom)');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+112,'AI funguje len pri parnej dlzke pola.');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+124,'Skore: Skore zavisi od aktualnej rychlosti HADA (rychlost * 2)');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+136,'Rychlost moze byt od 1 po 20. 20 je najvyssia.');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+148,'Maximalne X: 100   Maximalne Y: 50');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+160,'Autori: Matej Ridzon');
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+184,Help1);
c1:=readkey;
while ord(c1)<>27 do c1:=readkey;
end;

procedure uprav(var cislo:longint;x1,y1:longint;ts:string);  //upravenie nastaveni - parametre hry (iba cisla)
var tmp:longint;
    c1:char;
    tmps:string;
    code:integer;
begin
settextstyle(DefaultFont,0,1);
setcolor(black);
SetTextJustify(CenterText,TopText);
str(cislo,tmps);
OuttextXY(x1,y1,ts+tmps);
setcolor(red);
OuttextXY(x1,y1,ts);
tmps:='';
tmp:=0;
repeat
c1:=readkey;
case ord(c1) of
 13:begin
    break;
    end;
 8:begin
    if (tmps<>'') and (length(tmps)<5) then
     begin
     setcolor(black);
     OuttextXY(x1,y1,ts+tmps);
     Delete(tmps,length(tmps),1);
     setcolor(red);
     val(tmps,tmp,code);
     OuttextXY(x1,y1,ts+tmps);
     end;
    end;
  48..57:begin
    if length(tmps)<4 then
     begin
     setcolor(black);
     OuttextXY(x1,y1,ts+tmps);
     tmps:=tmps+c1;
     val(tmps,tmp,code);
     setcolor(red);
     OuttextXY(x1,y1,ts+tmps);
     end;
    end;
end;
until false;
setcolor(black);
OuttextXY(x1,y1,ts+tmps);
if tmp<0 then tmp:=cislo;
cislo:=tmp;
end;

function zapisskore(x1,y1,celkom:longint):boolean;   //test, ci nahral skore hodne zapisu, ak ano zapise
var tmps:string;
    Ri,Rj,ltmp,maxprvok:longint;
    c1:char;
begin
zapisskore:=false;
ltmp:=maxlongint;
tmps:='';
for Ri:=1 to 16 do
 begin
 if subor.skore[Ri].skore<ltmp then ltmp:=subor.skore[Ri].skore;
 end;
if celkom>ltmp then
 begin
 setfillstyle(solidfill,black);
 Bar((x1-62),y1-2,(x1+62),y1+8);
 Bar((x1-62),y1+13,(x1+62),y1+23);
 setcolor(lightblue);
 zapisskore:=true;
 OuttextXY(x1,y1,'ANO! Zadaj meno:');
 repeat
 c1:=readkey;
 case ord(c1) of
  13:begin
     if tmps<>'' then break;
     end;
  8:begin
     if (tmps<>'') and (length(tmps)<13) then
      begin
      setcolor(black);
      OuttextXY(x1,y1+15,tmps);
      Delete(tmps,length(tmps),1);
      setcolor(lightblue);
      OuttextXY(x1,y1+15,tmps);
      end;
     end;
  32..126:begin
     if length(tmps)<12 then
      begin
      setcolor(black);
      OuttextXY(x1,y1+15,tmps);
      tmps:=tmps+c1;
      setcolor(lightblue);
      OuttextXY(x1,y1+15,tmps);
      end;
     end;
 end;
 until false;
 subtmp.meno:=tmps;
 subtmp.skore:=celkom;
 subor.skore[17]:=subtmp; //vlozenie skore do suboru
 for Ri:=1 to 17 do //zotriedenie pola
  begin
  maxprvok:=17;
  for Rj:=Ri to 17 do
   begin
   if subor.skore[Rj].skore>subor.skore[maxprvok].skore then maxprvok:=Rj;
   end;
  subtmp:=subor.skore[Ri];
  subor.skore[Ri]:=subor.skore[maxprvok];
  subor.skore[maxprvok]:=subtmp;
  end;
 Rewrite(f);
 Write(f,subor);
 Close(f);
 end;
end;

procedure nastavenia;  //menu - nastavenia
var c1:char;
    ts:string;
    hodnota,vyber,dlzka:longint;
begin
vyciernimenu;
SetTextJustify(CenterText,TopText);
setfillstyle(solidfill,lightblue);
setcolor(lightblue);
settextstyle(SmallFont,0,3);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+10,NazovHry);
settextstyle(DefaultFont,0,1);
setcolor(red);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+40,MenuN);
str((subor.KoniecX-StartX) div 7,ts);
dlzka:=length(MenuN1+ts);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+64,MenuN1+ts);
str((subor.KoniecY-StartY) div 7,ts);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+76,MenuN2+ts);
str(subor.rychlost,ts);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+88,MenuN3+ts);
str(subor.AI,ts);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+100,MenuN4+ts);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+124,Help2);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+136,Help1);
vyber:=1;
setcolor(yellow);
MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
MenuY1:=StartY+61;
MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
MenuY2:=StartY+73;
Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
repeat
C1:=readkey;         //enter=13
case ord(C1) of
13:begin
   Rewrite(f);
   case vyber of
    1:begin    //maximalne X
      setcolor(black);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      hodnota:=(subor.koniecx-startx) div 7;
      uprav(hodnota,((KoniecX-StartX) div 2)+StartX,StartY+64,MenuN1);
      hodnota:=hodnota*7;
      setcolor(red);
      if hodnota<126 then hodnota:=126;
      if hodnota>700 then hodnota:=700;
      if hodnota<>subor.koniecX-startX then subor.koniecX:=StartX+hodnota;
      str((subor.KoniecX-StartX) div 7,ts);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+64,MenuN1+ts);
      end;
    2:begin     //maximalne Y
      setcolor(black);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      hodnota:=(subor.koniecY-startY) div 7;
      uprav(hodnota,((KoniecX-StartX) div 2)+StartX,StartY+76,MenuN2);
      hodnota:=hodnota*7;
      setcolor(red);
      if hodnota<63 then hodnota:=63;
      if hodnota>350 then hodnota:=350;
      if not ((hodnota mod 7)=0) then hodnota:=hodnota-(hodnota mod 7);
      if hodnota<>subor.koniecY-startY then subor.koniecY:=StartY+hodnota;
      str((subor.KoniecY-StartY) div 7,ts);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+76,MenuN2+ts);
      end;
    3:begin     //rychlost
      setcolor(black);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      hodnota:=subor.rychlost;
      uprav(hodnota,((KoniecX-StartX) div 2)+StartX,StartY+88,MenuN3);
      setcolor(red);
      if (hodnota>20) or (hodnota=0) then hodnota:=subor.rychlost;
      subor.rychlost:=hodnota;
      str(subor.rychlost,ts);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+88,MenuN3+ts);
      end;
     4:begin    //uroven AI
      setcolor(black);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      hodnota:=subor.AI;
      uprav(hodnota,((KoniecX-StartX) div 2)+StartX,StartY+100,MenuN4);
      setcolor(red);
      if (hodnota>5) or (hodnota<0) then hodnota:=subor.AI;
      subor.AI:=hodnota;
      str(subor.AI,ts);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+100,MenuN4+ts);
      end;
   end;
   Write(f,subor);
   Close(f);
   end;
72:begin
   setcolor(black);
   Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
   setcolor(yellow);
   vyber:=vyber-1;
   if vyber=0 then vyber:=4;
   end;
80:begin
   setcolor(black);
   Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
   setcolor(yellow);
   vyber:=vyber+1;
   if vyber=5 then vyber:=1;
   end;
27:begin
   vyber:=0;
   end;
end;
case vyber of
    1:begin
      str((subor.KoniecX-StartX) div 7,ts);
      dlzka:=length(MenuN1+ts);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+61;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+73;
      setcolor(yellow);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    2:begin
      str((subor.KoniecY-StartY) div 7,ts);
      dlzka:=length(MenuN2+ts);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+73;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+85;
      setcolor(yellow);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    3:begin
      str(subor.rychlost,ts);
      dlzka:=length(MenuN3+ts);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+85;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+97;
      setcolor(yellow);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    4:begin
      str(subor.AI,ts);
      dlzka:=length(MenuN4+ts);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+97;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+109;
      setcolor(yellow);
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
   end;
until vyber=0;
end;

procedure menu;
var Ri,dlzka:longint;
    tc:char;
begin
ohranic;
vyciernimenu;
priznak:=0;
skore:=0;
Arychlost:=round(Srychlost*XnaY(Qrychlost,(subor.rychlost-1)));
case subor.AI of
1:begin    //AI
  AIvypln((subor.KoniecX-StartX) div 7,(subor.KoniecY-StartY) div 7,AIpole,1);
  end;
2:begin    //mozne pridanie dalsich urovni AI
  AIvypln((subor.KoniecX-StartX) div 7,(subor.KoniecY-StartY) div 7,AIpole,2);
  end;
3:begin
  AIvypln((subor.KoniecX-StartX) div 7,(subor.KoniecY-StartY) div 7,AIpole,3);
  end;
4:begin
  AIvypln((subor.KoniecX-StartX) div 7,(subor.KoniecY-StartY) div 7,AIpole,4);
  end;
5:begin
  AIvypln((subor.KoniecX-StartX) div 7,(subor.KoniecY-StartY) div 7,AIpole,5);
  end;
else
 begin
 end;
end;
rychlost:=subor.rychlost;
CurX:=StartX+3;
CurY:=StartY+3;
LastX:=CurX;
LastY:=CurY;
zobrazskore;
SetTextJustify(CenterText,TopText);
setfillstyle(solidfill,lightblue);
setcolor(lightblue);
settextstyle(SmallFont,0,3);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+10,NazovHry);
settextstyle(DefaultFont,0,1);
setcolor(red);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+40,Menu1);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+52,Menu2);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+64,Menu3);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+76,Menu4);
OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+88,Menu5);
vyber:=1;
setcolor(yellow);
dlzka:=length(Menu1);
MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
MenuY1:=StartY+37;
MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
MenuY2:=StartY+49;
Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
repeat
tc:=readkey;         //enter=13
case ord(tc) of
13:begin
   case vyber of
    1:begin
      vyciernimenu;
      setcolor(red);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+40,Menu1);
      delay(500);
      vyber:=-1;
      end;
    2:begin
      vyciernimenu;
      setcolor(red);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+52,Menu2);
      delay(500);
      nastavenia;
      break;
      end;
    3:begin
      vyciernimenu;
      setcolor(red);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+64,Menu3);
      delay(500);
      pomoc;
      break;
      end;
    4:begin
      vyciernimenu;
      setcolor(red);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+76,Menu4);
      delay(500);
      highscores;
      break;
      end;
    5:begin
      vyciernimenu;
      setcolor(red);
      OuttextXY(((KoniecX-StartX) div 2)+StartX,StartY+88,Menu5);
      delay(500);
      Halt;
      end;
   end;
   end;
72:begin
   setcolor(black);
   Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
   setcolor(yellow);
   vyber:=vyber-1;
   if vyber=0 then vyber:=5;
   end;
80:begin
   setcolor(black);
   Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
   setcolor(yellow);
   vyber:=vyber+1;
   if vyber=6 then vyber:=1;
   end;
end;
case vyber of
    1:begin
      dlzka:=length(Menu1);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+37;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+49;
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    2:begin
      dlzka:=length(Menu2);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+49;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+61;
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    3:begin
      dlzka:=length(Menu3);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+61;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+73;
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    4:begin
      dlzka:=length(Menu4);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+73;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+85;
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
    5:begin
      dlzka:=length(Menu5);
      MenuX1:=((KoniecX-StartX) div 2)+StartX-3-(dlzka*4);
      MenuY1:=StartY+85;
      MenuX2:=((KoniecX-StartX) div 2)+StartX+1+(dlzka*4);
      MenuY2:=StartY+97;
      Rectangle(MenuX1,MenuY1,MenuX2,MenuY2);
      end;
   end;
until vyber=-1;
vyciernimenu;
upravhraciepole;
//zaciatok hry :)
telohada(CurX,CurY,13);
Hdlzka:=1;
for Ri:=1 to 1 do
 begin
 Hdlzka:=Hdlzka+1;
 CurX:=CurX+7;
 telohada(CurX,CurY,1);
 end;
Curx:=CurX+7;
telohada(CurX,CurY,7);
Hdlzka:=Hdlzka+1;
CurSmer:=P;
LastSmer:=P;
end;

procedure pauza;     //pauzne priebeh hry
var pc:char;
    txtmp:TextSettingsType;
begin
pc:=chr(0);
gettextsettings(txtmp);
Settextjustify(RightText,BottomText);
Setcolor(blue);
OuttextXY(subor.KoniecX,StartY-12,'PAUZA');
while ord(pc)<>32 do
begin
pc:=readkey;
end;
Setcolor(black);
OuttextXY(subor.KoniecX,StartY-12,'PAUZA');
Settextstyle(txtmp.font,txtmp.direction,txtmp.charsize);
settextjustify(txtmp.horiz,txtmp.vert);
end;

label 1,2,3;

{$R *.res}

begin
Randomize;
detectgraph(gd,gm);
gm:=m800x600;          //nastavenie rozlisenia na 800x600
initgraph(gd,gm,'');
inicializuj;
3:
repeat
menu;
until vyber=-1;
c2:=chr(77);         //nastavenie aktualneho smeru
c:=c2;
jedlo;
repeat
 1:                     //nacitanie POSLEDNEHO stlaceneho klavesu
 if keypressed then
  begin
   c:=readkey;
   goto 1;
  end;
 2:
 case ord(c) of
 72:begin                   //hore
    case GetPixel(CurX,CurY-7) of
    black:atyp:=0;
    green:zjedol;
    lightgray:atyp:=2;
    white:Ozjedol(H);
    end;
    CurSmer:=H;
    if not (ord(c2)=80) then
     begin
     upravhada(atyp,LastX,LastY,LastSmer,CurX,CurY,CurSmer);
     c2:=c;
     CurY:=CurY-7;
     end
    else
     begin
     c:=c2;
     goto 2;
     end;
    end;
 75:begin                 //vlavo
    case GetPixel(CurX-7,CurY) of
    black:atyp:=0;
    green:zjedol;
    lightgray:atyp:=2;
    white:Ozjedol(L);
    end;
    CurSmer:=L;
    if not(ord(c2)=77) then
     begin
     upravhada(atyp,LastX,LastY,LastSmer,CurX,CurY,CurSmer);
     c2:=c;
     CurX:=CurX-7;
     end
    else
     begin
     c:=c2;
     goto 2;
     end;
    end;
 77:begin                   //vpravo
    case GetPixel(CurX+7,CurY) of
    black:atyp:=0;
    green:zjedol;
    lightgray:atyp:=2;
    white:Ozjedol(P);
    end;
    CurSmer:=P;
    if not (ord(c2)=75) then
     begin
     upravhada(atyp,LastX,LastY,LastSmer,CurX,CurY,CurSmer);
     c2:=c;
     CurX:=CurX+7;
     end
    else
     begin
     c:=c2;
     goto 2;
     end;
    end;
 80:begin                  //dole
    case GetPixel(CurX,CurY+7) of
    black:atyp:=0;
    green:zjedol;
    lightgray:atyp:=2;
    white:Ozjedol(D);
    end;
    CurSmer:=D;
    if not (ord(c2)=72) then
     begin
     upravhada(atyp,LastX,LastY,LastSmer,CurX,CurY,CurSmer);
     c2:=c;
     CurY:=CurY+7;
     end
    else
     begin
     c:=c2;
     goto 2;
     end;
    end;
 27:begin
    priznak:=1;
    end;
 32:begin
    pauza;
    c:=c2;
    goto 2;
    end
 else
  begin
  c:=c2;
  goto 2;
  end;
 end;
 if atyp=0 then
 case LastSmer of
 P:LastX:=LastX+7;
 H:LastY:=LastY-7;
 L:LastX:=LastX-7;
 D:LastY:=LastY+7;
 end;
 case subor.AI of
 1:begin        //AI
   c:=chr(AIzisti((CurX-46) div 7,(CurY-46) div 7,AIpole));
   //delay(Archlost) je odstraneny pre rychlu simulaciu
   end;
 2:begin
   c:=chr(AIzisti((CurX-46) div 7,(CurY-46) div 7,AIpole));
   Delay(Arychlost);  //pre pozeranie simulacie nesmrtelneho hada
   end;
 3:begin                  //pre kazdu uroven sa mozu pridat dalsie testovacie logaritmy
   c:=chr(AIzisti((CurX-46) div 7,(CurY-46) div 7,AIpole));
   Delay(10);
   end;
 4:begin
   c:=chr(AIzisti((CurX-46) div 7,(CurY-46) div 7,AIpole));
   Delay(5);
   end;
 5:begin
   c:=chr(AIzisti((CurX-46) div 7,(CurY-46) div 7,AIpole));
   Delay(1);
   end;
 else
  begin
  delay(Arychlost);    //prestavka medzi posunom
  end;
 end;
until priznak<>0;      //ziadna zmena v hre
case priznak of
 1:begin               //zrusenie Esc-om
   setcolor(yellow);
   setfillstyle(solidfill,yellow);
   SettextStyle(DefaultFont,HorizDir,1);
   SetTextJustify(CenterText,TopText);
   if s='' then s:='0';
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus1);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   if not zapisskore(((subor.KoniecX-StartX) div 2)+StartX,StartY+36,skore) then Delay(1000);
   setcolor(black);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus1);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   goto 3;
   end;
 2:begin            //Narazenie so steny
   setcolor(yellow);
   setfillstyle(solidfill,yellow);
   SettextStyle(DefaultFont,HorizDir,1);
   SetTextJustify(CenterText,TopText);
   if s='' then s:='0';
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus2);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   if not zapisskore(((subor.KoniecX-StartX) div 2)+StartX,StartY+36,skore) then Delay(1000);
   setcolor(black);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus2);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   goto 3;
   end;
 3:begin           //Narazenie do seba
   setcolor(yellow);
   setfillstyle(solidfill,yellow);
   SettextStyle(DefaultFont,HorizDir,1);
   SetTextJustify(CenterText,TopText);
   if s='' then s:='0';
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus3);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   if not zapisskore(((subor.KoniecX-StartX) div 2)+StartX,StartY+36,skore)then Delay(1000);
   setcolor(black);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus3);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   goto 3;
   end;
 4:begin          //vyplnenie celej plochy hadom
   upravhada(3,LastX,LastY,LastSmer,CurX,CurY,CurSmer);
   setcolor(yellow);
   setfillstyle(solidfill,yellow);
   SettextStyle(DefaultFont,HorizDir,1);
   SetTextJustify(CenterText,TopText);
   if s='' then s:='0';
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus4);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   if not zapisskore(((subor.KoniecX-StartX) div 2)+StartX,StartY+36,skore)then Delay(1000);
   setcolor(black);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+10,Zrus4);
   OuttextXY(((subor.KoniecX-StartX) div 2)+StartX,StartY+24,Vypisskore+s);
   goto 3;
   end;
end;
closegraph;
end.


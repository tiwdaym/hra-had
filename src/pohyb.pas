{This file is part of hra-had.

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

unit pohyb;

{$mode objfpc}{$H+}

interface

const P=1; L=2; H=3; D=4;

type TAIpole=array[1..50,1..100] of longint;

procedure AIvypln(y,x:longint;var AIpole:TAIpole;typ:longint);  //typ - pre vyssie urovne AI
function AIzisti(y,x:longint;AIpole:TAIpole):longint;

implementation

procedure AIvypln(y,x:longint;var AIpole:TAIpole;typ:longint);
var Ri,Rj:longint;
begin
if (x mod 2)=0  then
for Ri:=1 to x do
 begin
 if Ri=1 then
  begin
  for Rj:=1 to y do
   begin
   if Rj=y then AIpole[Ri,Rj]:=D
   else AIpole[Ri,Rj]:=P;
   end;
  end
 else if Ri=2 then
  begin
  for Rj:=1 to y do
   begin
   if Rj=1 then AIpole[Ri,Rj]:=H
   else if Rj=y then AIpole[Ri,Rj]:=D
   else if (Rj mod 2)=0 then AIpole[Ri,Rj]:=D
   else AIpole[Ri,Rj]:=L;
   end;
  end
 else if Ri=x then
  begin
  for Rj:=1 to y do
   begin
   if (Rj mod 2)=0 then AIpole[Ri,Rj]:=L
   else AIpole[Ri,Rj]:=H;
   end;
  end
 else
  begin
  for Rj:=1 to y do
   begin
   if (Rj mod 2)=0 then AIpole[Ri,Rj]:=D
   else AIpole[Ri,Rj]:=H;
   end;
  end;
 end
else
 begin
 for Ri:=1 to x do
  for Rj:=1 to y do AIpole[Ri,Rj]:=P;
 end;
end;

function AIzisti(y,x:longint;AIpole:TAIpole):longint;
begin
if AIpole[x,y]=H then AIzisti:=72
else if AIpole[x,y]=L then AIzisti:=75
else if AIpole[x,y]=P then AIzisti:=77
else if AIpole[x,y]=D then AIzisti:=80;
end;

end.


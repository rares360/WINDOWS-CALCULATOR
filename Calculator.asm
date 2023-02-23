.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern printf: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "CalculatorFurtosRares",0
area_width EQU 350
area_height EQU 500
area DD 0
rezultat DW 0
counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

variabilatemporara DD 0
verificator DD 0
operator1 DD 0
operator2 DD 0
operator3 DD 0
operatormax DD 0
numarcifre DD 0
pozitia DD 30
pozitiafinala DD 30
numarfinal DD 0
numar1 DD -1
numar2 DD -1
format DB " %d " ,0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
;declaram numerele
cifra_zero DD 0
cifra_unu DD 1
cifra_doi DD 2
cifra_trei DD 3
cifra_patru DD 4
cifra_cinci DD 5
cifra_sase DD 6
cifra_sapte DD 7
cifra_opt DD 8
cifra_noua DD 9

;declaram pozitiile +,-,/,*
button_size EQU 80
egal_x EQU 260
egal_y EQU 80
div_x EQU 260
div_y EQU 160
inm_x EQU 260
inm_y EQU 240
plus_x EQU 260
plus_y EQU 320
minus_x EQU 260
minus_y EQU 400

;pozitiile numerelor
sapte_x EQU 10
sapte_y EQU 160
opt_x EQU 90
opt_y EQU 160
noua_x EQU 170
noua_y EQU 160

patru_x EQU 10
patru_y EQU 240
cinci_x EQU 90
cinci_y EQU 240
sase_x EQU 170
sase_y EQU 240

unu_x EQU 10
unu_y EQU 320
doi_x EQU 90
doi_y EQU 320
trei_x EQU 170
trei_y EQU 320

zero_x EQU 90
zero_y EQU 400
sterge_x EQU 10
sterge_y EQU 400
backspace_x EQU 170
backspace_y EQU 400

.code

horizontal_line macro x,y,len,color
local bucla_line
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
bucla_line:
	mov dword ptr[eax],color
	add eax,4
	loop bucla_line
endm
verical_line macro x,y,len,color
local bucla_line
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
bucla_line:
	mov dword ptr[eax],color
	add eax,area_width*4
	loop bucla_line
endm

;verificam simbolurile
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	cmp eax, ' '
	jne make_symbols
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	jmp draw_text
make_symbols:
	cmp eax, '-'
	jne not_minus
	mov eax, 27
	lea esi, letters
	jmp draw_text
not_minus:
	cmp eax, '+' ; - + / * =
	jne not_plus
	mov eax, 28
	lea esi, letters
	jmp draw_text
not_plus:
	cmp eax, '/'
	jne not_div
	mov eax, 29
	lea esi, letters
	jmp draw_text
not_div:
	cmp eax, '*'
	jne not_mul
	mov eax, 30
	lea esi, letters
	jmp draw_text
not_mul:
	mov eax, 31
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; desenam simbolul
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx 
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
;construim numerele
event_numere macro poz1,poz2,x,y,dimensiune,numarul,operator
	local fail,nr0,nr1,nr2,nr3,nr4,nr5,nr6,nr7,nr8,nr9,sare_peste,sare_aici
	local compararea,numarul1,numarul2,adauga,pune,sarimpeste,parcurgere23
	mov ebx,0
	mov eax,poz1
	cmp eax,x
	jl fail
	cmp eax,x + dimensiune
	jg fail
	mov eax,poz2
	cmp eax,y
	jl fail
	cmp eax,y + dimensiune
	jg fail
	mov ebx,1
	mov ecx,numarul
	;verificam operatorii
	cmp operator,0
	jne numarul2
numarul1:
	cmp numar1,-1
	jne adauga
	mov edx,numar1
	add ecx,edx
	inc ecx
	mov numar1,ecx
	jmp sare_aici
adauga:
	mov ecx,eax
	mov eax,numar1
	mov edx,10
	mul edx
	add eax,numarul
	mov numar1,eax
	mov eax,ecx
	jmp sare_aici
numarul2:
	cmp numar2,-1
	jne pune
	mov edx,numar2
	add ecx,edx
	inc ecx
	mov numar2,ecx
	jmp sare_aici
pune:
	mov ecx,eax
	mov eax,numar2
	mov edx,10
	mul edx
	add eax,numarul
	mov numar2,eax
	mov eax,ecx
	jmp sare_aici
sare_aici:
	sare_peste:
	afisarea numarul,pozitia
fail:
endm

;afisarea cifrei/verificam ce cifra este si o afisam la o pozitie apelata
afisarea macro nr,poz
local nr0,nr1,nr2,nr3,nr4,nr5,nr6,nr7,nr8,nr9,fail,fail2,fail3
	cmp nr,0
	je nr0
	cmp nr,1
	je nr1
	cmp nr,2
	je nr2
	cmp nr,3
	je nr3
	cmp nr,4
	je nr4
	cmp nr,5
	je nr5
	cmp nr,6
	je nr6
	cmp nr,7
	je nr7
	cmp nr,8
	je nr8
	cmp nr,9
	je nr9
	jmp fail
nr0:make_text_macro ' ', area, poz, 50
	make_text_macro '0', area, poz, 50
	jmp fail
nr1:make_text_macro ' ', area, poz, 50
	make_text_macro '1', area, poz, 50
	jmp fail
nr2:make_text_macro ' ', area, poz, 50
	make_text_macro '2', area, poz, 50
	jmp fail
nr3:make_text_macro ' ', area, poz, 50
	make_text_macro '3', area, poz, 50
	jmp fail
nr4:make_text_macro ' ', area, poz, 50
	make_text_macro '4', area, poz, 50
	jmp fail
nr5:make_text_macro ' ', area, poz, 50
	make_text_macro '5', area, poz, 50
	jmp fail
nr6:make_text_macro ' ', area, poz, 50
	make_text_macro '6', area, poz, 50
	jmp fail
nr7:make_text_macro ' ', area, poz, 50
	make_text_macro '7', area, poz, 50
	jmp fail
nr8:make_text_macro ' ', area, poz, 50
	make_text_macro '8', area, poz, 50
	jmp fail
nr9:make_text_macro ' ', area, poz, 50
	make_text_macro '9', area, poz, 50
	jmp fail
fail:
	cmp operator2,5
	je fail2
	add poz,10
	jmp fail3
fail2:
	sub poz,10
fail3:
endm

;facem operatiile dintre numerele trimise
rezultate proc
	push ebp
	mov ebp,esp
	
	;mov edx,[ebp+8] ->nr1
	;mov ebx,[ebp+12] -> operator
	mov edx,0
minus:
	mov ebx,1
	cmp [ebp+12],ebx
	jne plus
	mov eax,[ebp+8]
	cmp eax,[ebp+16]
	jl nr_negativ
	mov eax,[ebp+8]
	sub eax,[ebp+16]
	jmp terminare
plus:
	mov ebx,2
	cmp [ebp+12],ebx
	jne impartire
	mov eax,[ebp+8]
	add eax,[ebp+16]
	jmp terminare
impartire:
	mov ebx,3
	cmp [ebp+12],ebx
	jne inmultire
	mov eax,[ebp+8]
	mov ecx,[ebp+16]
	cmp ecx,0
	je terminare
	div ecx
	jmp terminare	
inmultire:
	mov ebx,4
	cmp [ebp+12],ebx
	jne finalparcc
	mov eax,[ebp+8]
	mov ecx,[ebp+16]
	mul ecx
	jmp terminare
nr_negativ:
	mov eax,-5
terminare:
	mov numar1,eax
	mov numar2,-1
	mov operator1,0
finalparcc:
	push eax
	push offset format
	call printf
	mov ESP, EBP
    pop EBP
	ret 12 
rezultate endp
;afisam rezultatul final
rezultatfinal macro nr
	local parcurgerefinala,finalulparc,final,final2,parcurgere
	mov ecx,10
	mov pozitiafinala,20
	mov ebx,nr
	mov eax,nr 
begin:   
    cmp eax,0
    jz final
    inc numarcifre
    mov edx,0
    div ecx
    jmp begin
final:
	mov eax,numarcifre
	mul ecx
	add eax,pozitiafinala
	mov pozitiafinala,eax
	mov eax,ebx
	mov edx,0
	mov eax,pozitiafinala
	mov pozitia,eax
	add pozitia,10
	mov eax,nr
parcurgerefinala:
	cmp eax,0
	jz final2
	mov edx,0
	div ecx
	mov numarfinal,edx
	afisarea numarfinal,pozitiafinala
	jmp parcurgerefinala
	parcurgere:
final2:
endm

;verificam butoanele
evt_click:
event_egal:
	mov eax,[ebp+arg2]
	cmp eax,egal_x
	jl event_div
	cmp eax,egal_x+ button_size
	jg event_div
	mov eax,[ebp+arg3]
	cmp eax,egal_y
	jl event_div
	cmp eax,egal_y + button_size
	jg event_div
	cmp numar1,-1
	je event_div
	mov operator2,5
termina_egal:
	mov pozitia,20
	mov ebx,20
parcurgere:
	make_text_macro ' ', area, ebx, 50
	add ebx,10
	cmp ebx,340
	jl parcurgere
	add esp,8
	;event div
event_div:
	mov eax,[ebp+arg2]
	cmp eax,div_x
	jl event_inm
	cmp eax,div_x+ button_size
	jg event_inm
	mov eax,[ebp+arg3]
	cmp eax,div_y
	jl event_inm
	cmp eax,div_y + button_size
	jg event_inm
	cmp numar1,-1
	je event_inm
	cmp operator1,0
	jne event_sterge
	mov operator1,3
termina_div:
	make_text_macro ' ', area, pozitia, 50
	make_text_macro '/', area, pozitia, 50
	add pozitia,10
event_inm:
	mov eax,[ebp+arg2]
	cmp eax,inm_x
	jl event_plus
	cmp eax,inm_x+ button_size
	jg event_plus
	mov eax,[ebp+arg3]
	cmp eax,inm_y
	jl event_plus
	cmp eax,inm_y + button_size
	jg event_plus
	cmp numar1,-1
	je event_plus
	cmp operator1,0
	jne event_sterge
	mov operator1,4
termina_inm:
	make_text_macro ' ', area, pozitia, 50
	make_text_macro '*', area, pozitia, 50
	add pozitia,10
event_plus:
	mov eax,[ebp+arg2]
	cmp eax,plus_x
	jl event_minus
	cmp eax,plus_x+ button_size
	jg event_minus
	mov eax,[ebp+arg3]
	cmp eax,plus_y
	jl event_minus
	cmp eax,plus_y + button_size
	jg event_minus
	cmp numar1,-1
	je event_minus
	cmp operator1,0
	jne event_sterge
	mov operator1,2
termina_plus:
	make_text_macro ' ', area, pozitia, 50
	make_text_macro '+', area, pozitia, 50
	add pozitia,10
event_minus:
	mov eax,[ebp+arg2]
	cmp eax,minus_x
	jl event_pornit
	cmp eax,minus_x+ button_size
	jg event_pornit
	mov eax,[ebp+arg3]
	cmp eax,minus_y
	jl event_pornit
	cmp eax,minus_y + button_size
	jg event_pornit
	cmp numar1,-1
	je event_pornit
	cmp operator1,0
	jne event_sterge
	mov operator1,1
	termina_minus:
	make_text_macro ' ', area, pozitia, 50
	make_text_macro '-', area, pozitia, 50
	add pozitia,10
event_pornit:
	mov eax,[ebp+arg2]
	cmp eax,backspace_x
	jl event_stergere
	cmp eax,backspace_x+ button_size
	jg event_stergere
	mov eax,[ebp+arg3]
	cmp eax,backspace_y
	jl event_stergere
	cmp eax,backspace_y + button_size
	jg event_sterge
	termina_pornit:
	cmp verificator,0
	jne zboarapeste
	make_text_macro 'P', area, 40, 100
	make_text_macro 'R', area, 50, 100
	make_text_macro 'O', area, 60, 100
	make_text_macro 'I', area, 70, 100
	make_text_macro 'E', area, 80, 100
	make_text_macro 'C', area, 90, 100
	make_text_macro 'T', area, 100, 100
	make_text_macro ' ', area, 110, 100
	make_text_macro 'A', area, 120, 100
	make_text_macro 'S', area, 130, 100
	make_text_macro 'A', area, 140, 100
	make_text_macro 'M', area, 150, 100
	make_text_macro 'B', area, 160, 100
	make_text_macro 'L', area, 170, 100
	make_text_macro 'A', area, 180, 100
	make_text_macro 'R', area, 190, 100
	make_text_macro 'E', area, 200, 100
	
	make_text_macro 'F', area, 50, 120
	make_text_macro 'U', area, 60, 120
	make_text_macro 'R', area, 70, 120
	make_text_macro 'T', area, 80, 120
	make_text_macro 'O', area, 90, 120
	make_text_macro 'S', area, 100, 120
	make_text_macro ' ', area, 110, 120
	make_text_macro 'R', area, 120, 120
	make_text_macro 'A', area, 130, 120
	make_text_macro 'R', area, 140, 120
	make_text_macro 'E', area, 150, 120
	make_text_macro 'S', area, 160, 120
	make_text_macro 'M', area, 180, 120
	make_text_macro 'I', area, 190, 120
	make_text_macro 'H', area, 200, 120
	make_text_macro 'A', area, 210, 120
	make_text_macro 'I', area, 220, 120
	mov verificator,1
	jmp event_sterge
	zboarapeste:
	mov ebx,30
parcurgere22:
	make_text_macro ' ', area, ebx, 100
	make_text_macro ' ', area, ebx, 120
	add ebx,10
	cmp ebx,340
	jl parcurgere22
	mov verificator,0
event_stergere:
	mov eax,[ebp+arg2]
	cmp eax,sterge_x
	jl iese_afara
	cmp eax,sterge_x+ button_size
	jg iese_afara
	mov eax,[ebp+arg3]
	cmp eax,sterge_y
	jl iese_afara
	cmp eax,sterge_y + button_size
	jg iese_afara
	mov ebx,20
	parcurgere1:
	make_text_macro ' ', area, ebx, 50
	add ebx,10
	cmp ebx,340
	jl parcurgere1
	;event div
	make_text_macro ' ', area, 30, 50
	make_text_macro '0', area, 30, 50
	mov pozitia,30
	mov numarcifre,0
	mov operator1,0
	mov operator2,0
	mov numar1,-1
	mov numar2,-1
iese_afara:
;verificam cifrele
event_numere [ebp+arg2],[ebp+arg3],zero_x,zero_y,button_size,cifra_zero,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],unu_x,unu_y,button_size,cifra_unu,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],doi_x,doi_y,button_size,cifra_doi,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],trei_x,trei_y,button_size,cifra_trei,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],patru_x,patru_y,button_size,cifra_patru,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],cinci_x,cinci_y,button_size,cifra_cinci,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],sase_x,sase_y,button_size,cifra_sase,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],sapte_x,sapte_y,button_size,cifra_sapte,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],opt_x,opt_y,button_size,cifra_opt,operator1
cmp ebx,1
je event_sterge
event_numere [ebp+arg2],[ebp+arg3],noua_x,noua_y,button_size,cifra_noua,operator1
je event_sterge

event_sterge:
	cmp operator2,5
	jne asteapta
	push numar2
	push operator1
	push numar1
	call rezultate
	mov numarcifre,0
	cmp numar1,-5
	je mesaj_error
	rezultatfinal numar1
	cmp numar1,0
	jne sarepeste
	make_text_macro ' ', area, 30, 50
	make_text_macro '0', area, 30, 50
	mov pozitia,30
	mov numarcifre,0
	mov operator1,0
	mov operator2,0
	mov numar1,-1
	mov numar2,-1
	jmp sarepeste
mesaj_error:
	make_text_macro 'E', area, 30, 80
	make_text_macro 'R', area, 40, 80
	make_text_macro 'R', area, 50, 80
	make_text_macro 'O', area, 60, 80
	make_text_macro 'R', area, 70, 80
	mov pozitia,30
	mov numarcifre,0
	mov operator1,0
	mov operator2,0
	mov numar1,-1
	mov numar2,-1
sarepeste:
	
	mov operator2,0
	push numarcifre
	push offset format
	call printf
asteapta:
button_fail:
	jmp afisare_litere
evt_timer:
	inc counter
	make_text_macro ' ', area, 30, 80
	make_text_macro ' ', area, 40, 80
	make_text_macro ' ', area, 50, 80
	make_text_macro ' ', area, 60, 80
	make_text_macro ' ', area, 70, 80
	
;facem macro pt box urile din calculator
box_create macro x,y,dimensiune,culoare
	horizontal_line x,y,dimensiune,culoare
	horizontal_line x,y + dimensiune,dimensiune,culoare
	verical_line x,y,dimensiune,culoare
	verical_line x + dimensiune,y,dimensiune,culoare
endm
afisare_litere:
	make_text_macro 'C', area, 125, 0
	make_text_macro 'A', area, 135, 0
	make_text_macro 'L', area, 145, 0
	make_text_macro 'C', area, 155, 0
	make_text_macro 'U', area, 165, 0
	make_text_macro 'L', area, 175, 0
	make_text_macro 'A', area, 185, 0
	make_text_macro 'T', area, 195, 0
	make_text_macro 'O', area, 205, 0
	make_text_macro 'R', area, 215, 0
	make_text_macro '7', area, 45,190
	make_text_macro '4', area, 45,270
	make_text_macro '1', area, 45,350
	make_text_macro 'C', area, 40,430
	make_text_macro 'E', area, 50,430
	make_text_macro '8', area, 125,190
	make_text_macro '5', area, 125,270
	make_text_macro '2', area, 125,350
	make_text_macro '0', area, 125,430
	make_text_macro '9', area, 205,190
	make_text_macro '6', area, 205,270
	make_text_macro '3', area, 205,350
	make_text_macro 'O', area, 200,430
	make_text_macro 'N', area, 210,430
	make_text_macro '-', area, 295,430
	make_text_macro '+', area, 295,350
	make_text_macro '*', area, 295,270
	make_text_macro '/', area, 295,190
	make_text_macro '=', area, 295,110
	
	;linie orizontala sus
	horizontal_line 10, 0, 330, 00000
	;linie orizontala tabel
	horizontal_line 10, 30, 330, 00000
	horizontal_line 10, 80, 330, 00000
	;linie orizontala jos
	horizontal_line 10, 480, 330, 00000
	verical_line	10,0,480,00000
	verical_line	250,80,200,00000
	verical_line	340,0,480,00000
	;facem +,-,*,/
	;facem box +
	box_create plus_x,plus_y,button_size,0
	;facem box -
	box_create minus_x,minus_y,button_size,0
	;facem box *
	box_create inm_x,inm_y,button_size,0
	;facem box div
	box_create div_x,div_y,button_size,0
	;facem box egal
	box_create egal_x,egal_y,button_size,0
	;facem box_cifre
	box_create zero_x,zero_y,button_size,0
	box_create sapte_x,sapte_y,button_size,0
	box_create opt_x,opt_y,button_size,0
	box_create noua_x,noua_y,button_size,0
	box_create patru_x,patru_y,button_size,0
	box_create cinci_x,cinci_y,button_size,0
	box_create noua_x,noua_y,button_size,0
	box_create patru_x,patru_y,button_size,0
	box_create cinci_x,cinci_y,button_size,0
	box_create sase_x,sase_y,button_size,0
	box_create unu_x,unu_y,button_size,0
	box_create doi_x,doi_y,button_size,0
	box_create trei_x,trei_y,button_size,0
	;facem box_sterge
	box_create sterge_x,sterge_y,button_size,0
	box_create backspace_x,backspace_y,button_size,0
sfarsit:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start

.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc
extern rand: proc
extern srand: proc
extern time: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
real_board DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)
	DD 10 dup(0)

player_board DD 100 dup('-')

cells_remain DD 90
number_of_mines EQU 10
game_in_progress DD 1

format_interg DB "%d ",0
format_caracter DB "%c ",0
linie_noua DB " ",13,10,0

zece DD 10
cinci DD 5
treizeci DD 30

x DD 0
y DD 0

window_title DB "Minesweeper Proiect PLA",0
area_width EQU 300
area_height EQU 340
area DD 0

counter DD 0 ; numara evenimentele de tip timer
total_time DD 0 ; numara secundele

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
cell_width EQU 30
cell_height EQU 30

include letters.inc
include cells.inc
include counter_digits.inc

.code
;Macroul table_value pune in EDX valoarea matricei in punctul x,y
table_value MACRO x,y
	lea ESI,real_board
	mov EAX,10
	mov EBX,x
	mul EBX
	add EAX,y
	shl EAX,2
	mov EDX,[ESI+EAX] 
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Macroul is_mine pune in ECX 1 daca valoarea matricei in real_board[EAX][EBX] este '*' ,altfel 0
is_mine MACRO
local nu_apartine,continue
	
	;se va compara daca poz_x si poz_y apartine [0,9]
	cmp eax,0
	jl nu_apartine
	cmp ebx,0
	jl nu_apartine
	cmp eax,9
	jg nu_apartine
	cmp ebx,9
	jg nu_apartine
	
	mov x,eax
	mov y,ebx
	table_value x,y
		
	cmp EDX,'*'
	JNE nu_apartine
	
	mov ECX,1
	jmp continue
	
	nu_apartine:
	mov ECX,0
	
	continue:
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Procedura generate_mines genereaza mine random in matricea reala
generate_mines PROC
	push EBP
	mov EBP, ESP
	sub ESP, 12
	
	push 0
	call time
	add esp,4
	push eax
	call srand
	add esp,4
	
	; int random = rand() % (nr_linii*nr_coloane)
	; SIDE = number_of_lines * number_of_colums
	; int x = random / SIDE
    ; int y = random % SIDE
	; board[x][y] = '*'

	mov ECX,number_of_mines ;Registrul ECX retine numarul total de mine ce trebuie plasate
bucla:
	push ECX
	call rand
	
	mov EDX,0 ;random=rand mod side*side
	mov EBX,100
	div EBX
	mov [EBP-12],EDX  ; variabila locala 3 retine un numar intre 0 si 99
	
	mov EAX,[EBP-12] ;x=random / side
	mov EDX,0
	div zece
	mov [EBP-4],EAX
	
	mov EAX,[EBP-12] ;y = random % side
	mov EDX,0
	div zece
	mov [EBP-8],EDX
	
	table_value [EBP-4],[EBP-8]
	
	pop ECX
	;se verifica daca board[i][j] contine deja valoarea '*'
	cmp EDX,'*'
	JE bucla ;daca board[i][j] este deja '*' atunci se reia procesul pentru generarea minei 
	mov [ESI+EAX], dword ptr '*'
	loop bucla
	
	mov ESP, EBP
	pop EBP
	ret 0
generate_mines endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Procedura initialize_board initializeaza matricea reala cu valorile corespunzatoare celulelor care au ca vecini mine
initialize_board PROC
	push EBP
	mov EBP, ESP
	sub ESP, 12
	
	mov [EBP-4],dword ptr 0
	bucla_linii:
	
	mov [EBP-8],dword ptr 0
	bucla_coloane:
	
	mov [EBP-12],dword ptr 0 ;variabila locala 3 retine numar total de vecini care au ca valori '*'
	
	table_value [ebp-4],[ebp-8]
	cmp EDX,'*'
	JE continue
	
	;edx!='*'
	mov eax,[ebp-4]
	dec eax
	mov ebx,[ebp-8]
	dec ebx
	is_mine 
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	dec eax
	mov ebx,[ebp-8]
	is_mine
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	dec eax
	mov ebx,[ebp-8]
	inc ebx
	is_mine
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	mov ebx,[ebp-8]
	dec ebx
	is_mine
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	mov ebx,[ebp-8]
	inc ebx
	is_mine
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	inc eax
	mov ebx,[ebp-8]
	dec ebx
	is_mine
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	inc eax
	mov ebx,[ebp-8]
	is_mine
	add [ebp-12],ecx
	
	mov eax,[ebp-4]
	inc eax
	mov ebx,[ebp-8]
	inc ebx
	is_mine
	add [ebp-12],ecx

	lea ESI,real_board
	mov EAX,10
	mov EBX,[ebp-4]
	mul EBX
	add EAX,[ebp-8]
	shl EAX,2
	
	mov ebx,[ebp-12]
	mov [esi+eax],ebx
	
	continue:
	inc dword ptr [EBP-8]
	
	cmp [ebp-8],dword ptr 10
	JNE bucla_coloane
	
	inc dword ptr [EBP-4]
	
	cmp [ebp-4],dword ptr 10
	JNE bucla_linii
	
	mov ESP, EBP
	pop EBP
	ret 0
initialize_board ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Procedura print_real_board afiseaza in consola matricea reala
print_real_board PROC
	push EBP
	mov EBP, ESP
	sub ESP, 8
	
	mov [EBP-4],dword ptr 0
bucla_linii:

	mov [EBP-8],dword ptr 0
bucla_coloane:
	table_value [EBP-4],[EBP-8]
	
	cmp EDX,'*'
	JE mina
	
	push EDX
	push offset format_interg
	call printf
	add esp,8
	jmp continua
	
	mina:
	push EDX
	push offset format_caracter
	call printf
	add esp,8
	
	continua:
	inc dword ptr [EBP-8]
	cmp [ebp-8],dword ptr 10
	JNE bucla_coloane
	
	push offset linie_noua
	call printf
	add esp,4
	
	inc dword ptr [EBP-4]
	cmp [EBP-4],dword ptr 10
	jne bucla_linii
	
	mov ESP, EBP
	pop EBP
	ret 0
print_real_board ENDP

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ;se citeste simbolul de afisat
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
	lea esi, counter_digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	shl eax,2 ;se inmulteste cu 4 din cauza ca fiecare valoarea este un DD
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
	shl eax, 2 ;se inmulteste cu 4 din cauza ca fiecare pixel ocupa un DD
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp dword ptr [esi], 0 ;0 pt negru si alta valoare pentru o culoare specifica
	je simbol_pixel_negru

	mov eax,dword ptr [esi] ;;;;;;;;;;;;;;;;;;;se copiaza in eax culoarea
	mov dword ptr [edi],eax ;;;;;;;;;;;;;;;;;;;se pune in EDI culoarea
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0h
simbol_pixel_next:
	add esi,4 ;se incrementeaza cu 4 din cauza DD per pixel
	add edi,4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;Macroul make_text_macro pentru apelarea functiei make_text
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


; procedura draw_cell afiseaza o celula la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
draw_cell proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ;se citeste simbolul de afisat
	
	sub eax,'0' ;48 din cauza ca se citeste codul ASSCI
	lea esi,cells
	
draw_text:
	mov ebx, cell_width
	mul ebx
	mov ebx, cell_height
	mul ebx
	shl eax,2 
	add esi, eax
	mov ecx, cell_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, cell_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, cell_width
bucla_simbol_coloane:
	cmp dword ptr [esi], 0 ;0 pt alb si alta valoare pentru simbol 
	je simbol_pixel_negru

	mov eax,dword ptr [esi] ;;;;;;;;;;;;;;;;;;;culoarea
	mov dword ptr [edi],eax ;;;;;;;;;;;;;;;;;;;edi retine culoarea
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0h
simbol_pixel_next:
	add esi,4
	add edi,4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	
	mov esp, ebp
	pop ebp
	ret
draw_cell endp

;Macroul draw_cell_macro apeleaza functia de scriere a unei celule
draw_cell_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call draw_cell
	add esp, 16
endm

show_score MACRO
	make_text_macro 'Y',area, 160,10
	make_text_macro 'O',area, 170,10
	make_text_macro 'U',area, 180,10
	make_text_macro 'R',area, 190,10
	
	make_text_macro 'S',area, 205,10
	make_text_macro 'C',area, 215,10
	make_text_macro 'O',area, 225,10
	make_text_macro 'R',area, 235,10
	make_text_macro 'E',area, 245,10
	
	;se va afisa scorul
	;score = 100 - cells_remain
	mov ebx, 10
	mov eax, 100
	sub eax,cells_remain
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro EDX,area, 280,10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro EDX,area, 270,10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro EDX,area, 260,10
	
ENDM

show_real_table PROC

show_real_table endp

game_over macro
	make_text_macro 'G',area, 50,10
	make_text_macro 'A',area, 60,10
	make_text_macro 'M',area, 70,10
	make_text_macro 'E',area, 80,10
	
	make_text_macro 'O',area, 95,10
	make_text_macro 'V',area, 105,10
	make_text_macro 'E',area, 115,10
	make_text_macro 'R',area, 125,10
	
	show_score
ENDM

you_win macro
	make_text_macro 'Y',area, 65,10
	make_text_macro 'O',area, 75,10
	make_text_macro 'U',area, 85,10
	
	make_text_macro 'W',area, 100,10
	make_text_macro 'I',area, 110,10
	make_text_macro 'N',area, 120,10
	
	show_score
ENDM


verifica_recursivitate_macro macro
local opreste_recursivitate,continue, continua_recursivitate
	
	;se va compara daca poz_x si poz_y apartine [0,9]
	cmp eax,0
	jl opreste_recursivitate
	cmp ebx,0
	jl opreste_recursivitate
	cmp eax,9
	jg opreste_recursivitate
	cmp ebx,9
	jg opreste_recursivitate
	
	mov x,eax
	mov y,ebx
	table_value x,y
	
	;recursivitatea se opreste daca board[x+?][y+?] este un numar, adica valoarea este mai mare ca 0
	cmp EDX,0
	Jg opreste_recursivitate

	mov ecx,0
	jmp continue
	
	opreste_recursivitate:
	mov EcX,1
	
	continue:
endm

; arg1 - x  arg2 - y
recursivitate proc
	push ebp
	mov ebp,esp
	sub esp,16
	
	;int x = arg1, y=arg2
	;arg3, arg4 retine valoriel pixelilor de unde va incepe afisarea
	mov eax,[ebp+arg1]
	mov [ebp-4],eax
	mov eax,[ebp+arg2]
	mov [ebp-8],eax
	mov eax, [ebp+arg3]
	mov [ebp-12],eax
	mov eax, [ebp+arg4]
	mov [ebp-16],eax
	
	;se verifica daca celula nu a fost desfacuta pt a evita vizitarea celulerlor deja vizitate
	lea ESI,player_board
	mov EAX,10
	mov EBX,[ebp-4]
	mul EBX
	add EAX,[ebp-8]
	shl EAX,2
	
	cmp [esi+eax],dword ptr 0
	je conditie_oprire_recursivitate_indeplinita
	mov [esi+eax],dword ptr 0 ;marcam celula ca a fost desfacuta
	dec cells_remain
	
	table_value [ebp-4],[ebp-8]
	add edx,48
	draw_cell_macro edx, area, [ebp-12], [ebp-16]
	
	;se verifica daca vecinii lui board[x][y] este celula goala si se apeleaza pe ele recursivitate
	;ii luam pe rand si verificam daca sunt in intervale valide si daca da, aplicam recursivitate

	;sus stanga
	mov eax,[ebp-4]
	dec eax
	mov ebx,[ebp-8]
	dec ebx
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_sus
	
	mov eax,[ebp-16]
	sub eax,30
	push eax
	mov eax,[ebp-12]
	sub eax,30
	push eax
	mov eax,[ebp-8]
	dec eax
	push eax
	mov eax,[ebp-4]
	dec eax
	push eax
	call recursivitate
	add esp,16
	
	;sus
verifica_sus:
	mov eax,[ebp-4]
	dec eax
	mov ebx,[ebp-8]
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_sus_dreapta
	
	mov eax,[ebp-16]
	sub eax,30
	push eax
	mov eax,[ebp-12]
	push eax
	mov eax,[ebp-8]
	push eax
	mov eax,[ebp-4]
	dec eax
	push eax
	call recursivitate
	add esp,16
	
	;sus dreapta
verifica_sus_dreapta:
	mov eax,[ebp-4]
	dec eax
	mov ebx,[ebp-8]
	inc ebx
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_stanga
	
	mov eax,[ebp-16]
	sub eax,30
	push eax
	mov eax,[ebp-12]
	add eax,30
	push eax
	mov eax,[ebp-8]
	inc eax
	push eax
	mov eax,[ebp-4]
	dec eax
	push eax
	call recursivitate
	add esp,16

	;stanga
verifica_stanga:
	mov eax,[ebp-4]
	mov ebx,[ebp-8]
	dec ebx
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_dreapta
	
	mov eax,[ebp-16]
	push eax
	mov eax,[ebp-12]
	sub eax, 30
	push eax
	mov eax,[ebp-8]
	dec eax
	push eax
	mov eax,[ebp-4]
	push eax
	call recursivitate
	add esp,16

	;dreapta
verifica_dreapta:
	mov eax,[ebp-4]
	mov ebx,[ebp-8]
	inc ebx
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_jos_stanga
	
	mov eax,[ebp-16]
	push eax
	mov eax,[ebp-12]
	add eax, 30
	push eax
	mov eax,[ebp-8]
	inc eax
	push eax
	mov eax,[ebp-4]
	push eax
	call recursivitate
	add esp,16

	;jos stanga
verifica_jos_stanga:
	mov eax,[ebp-4]
	inc eax
	mov ebx,[ebp-8]
	dec ebx
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_jos
	
	mov eax,[ebp-16]
	add eax,30
	push eax
	mov eax,[ebp-12]
	sub eax, 30
	push eax
	mov eax,[ebp-8]
	dec eax
	push eax
	mov eax,[ebp-4]
	inc eax
	push eax
	call recursivitate
	add esp,16

	;jos
verifica_jos:	
	mov eax,[ebp-4]
	inc eax
	mov ebx,[ebp-8]
	verifica_recursivitate_macro
	cmp ecx,1
	je verifica_jos_dreapta
	
	mov eax,[ebp-16]
	add eax,30
	push eax
	mov eax,[ebp-12]
	push eax
	mov eax,[ebp-8]
	push eax
	mov eax,[ebp-4]
	inc eax
	push eax
	call recursivitate
	add esp,16
	
	;jos dreapta
verifica_jos_dreapta:
	mov eax,[ebp-4]
	inc eax
	mov ebx,[ebp-8]
	inc ebx
	verifica_recursivitate_macro
	cmp ecx,1
	je conditie_oprire_recursivitate_indeplinita
	
	mov eax,[ebp-16]
	add eax,30
	push eax
	mov eax,[ebp-12]
	add eax, 30
	push eax
	mov eax,[ebp-8]
	inc eax
	push eax
	mov eax,[ebp-4]
	inc eax
	push eax
	call recursivitate
	add esp,16
	
conditie_oprire_recursivitate_indeplinita:
	mov esp,ebp
	pop ebp
	ret
recursivitate endp 

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
; in caz de click, arg2 si arg3 este pozitia unde s-a dat click
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	; evt = 0 => se initializeaza fereastra
	
	
	;initializarea ferestrei
	;pana la linia 40 este zona de afisare date
	mov eax, area_width
	mov ebx, 40
	mul ebx
	shl eax, 2
	push eax
	push 200 ;culoarea fundalului zonei de informatii
	push area
	call memset
	add esp, 12
	
	;dupa linia 40 se afiseaza celulele nedesfacute
	;despre cells.inc
	;contine 11 imagini dintre care:
	;primele 9 contine celulele cu numere , imaginea 10 este celula nedesfacuta , imaginea 11 este celula care contine mina
	mov EAX,0
	bucla_linii:
	mov EBX,40
	bucla_coloana:
	draw_cell_macro '9', area, eax, ebx 
	add EBX,30
	cmp EBX,340
	jne bucla_coloana
	
	add EAX,30
	cmp EAX,300
	jne bucla_linii
	jmp afisare_counter
	
evt_click:
	;se verifica daca zona unde s-a apasat click este zona de celule
	mov eax,[ebp+arg3]
	cmp eax,40
	jl evt_timer
	
	;scad din locatia cursorului in vertical 10 din cauza ca zona de celule este de la 40 iar locatia cursorului trebuie sa fie multimplu de 30
	sub [ebp+arg3],dword ptr 10
	;se va determina locatia celulei in multiplu de 30 unde a fost apasat cursorul
	mov eax,30
	gaseste_poz_x:
	cmp eax,[ebp+arg2]
	JG poz_x
	add eax,30
	jmp gaseste_poz_x
	poz_x:
	sub eax,30
	
	mov ebx,30
	gaseste_poz_y:
	cmp ebx,[ebp+arg3]
	JG poz_y
	add ebx,30
	jmp gaseste_poz_y
	poz_y:
	sub ebx,20
	;eax retine linia iar ebx coloana de unde se va incepe afisarea
	
	;eax si ebx se salveaza pe stiva pt a fi folosite la afisare
	push eax
	push ebx
	
	;eax si ebx se imparte la 30 pt a obtine indicii matricei 
	mov edx,0
	div treizeci
	mov y,eax
	
	mov eax,ebx
	mov edx,0
	div treizeci
	sub eax,1
	mov x,eax
	
	table_value x,y
	;edx retine valoarea matricei
	pop ebx
	pop eax
	
	cmp edx,'*'
	je mina
	
	cmp edx,0
	jne sari_peste_recursivitate
	
	pusha
	push ebx
	push eax
	push y
	push x
	call recursivitate
	add esp,16
	popa
	
sari_peste_recursivitate:
	add edx,48 ;se aduna codul ASSCI al caracterului '0'
	jmp continua
	
	mina:
	mov edx,58 ;10 + '0' ;in cells.inc de la 0 la 8 sunt numerele, 9 este celula nedesfacuta iar 10 este celula cu mina
	draw_cell_macro edx, area, eax, ebx ;se afiseaza o mina
	;Jocul a luat sfarsit
	game_over
	mov dword ptr game_in_progress,0
	
	;Se va afisa zona de celule cu valorile respective valorii matricei
	mov eax,0
	linie:
	push eax
	
	mov ebx,0
	coloana:
	push ebx

	push eax
	
	push eax
	push ebx
	mov y,eax
	mov x,ebx
	table_value x,y
	pop ebx
	pop eax
	push edx
	
	push eax
	mov eax,30
	mul ebx
	mov ebx,eax
	add ebx,40
	pop eax
	mul treizeci
	
	pop edx
	cmp edx,'*'
	
	je este_mina
	add edx,48
	draw_cell_macro EDX,area,eax,ebx
	jmp nu_este_mina
	
	este_mina:
	draw_cell_macro 58,area,eax,ebx
	
	nu_este_mina:
	pop eax
	
	pop ebx
	inc ebx
	cmp ebx,10
	JNE coloana
	
	pop eax
	inc eax
	cmp eax,10
	JNE linie
	
	jmp evt_timer
	
	;Daca jocul nu a luat inca sfarsit
	continua:
	draw_cell_macro edx, area, eax, ebx ;se afiseaza celula unda s-a dat click
	;se memoreaza in player_board[x][y] valoarea 0 pentru ca celula respectiva a fost desfacuta
	lea ESI,player_board
	mov EAX,10
	mov EBX,x
	mul EBX
	add EAX,y
	shl EAX,2
	
	cmp [esi+eax],dword ptr 0
	JE evt_timer
	
	mov [esi+eax],dword ptr 0
	dec cells_remain
	
	cmp cells_remain,0
	JNE evt_timer
	;Dupa ce nu a mai ramas celule normale de desfacut jocul a luat sfarsit, jucatorul a castigat
	you_win
	mov dword ptr game_in_progress,0
	
evt_timer:
	cmp game_in_progress,0
	JE final_draw
	inc counter ; la fiecare 200 ms se incrementeaza
	mov EDX,0
	mov EAX,counter
	div cinci ;EDX = EAX % 5
	
	cmp EDX,0 ;la fiecare multiplu de 5, adica 5 * 200 ms => 1 secunda
	JE incrementeaza_timp_total
	jmp afisare_counter
	
	incrementeaza_timp_total:
	inc total_time ;la fiecare secunda se incrementeaza
	
afisare_counter:
	;se afiseaza valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, total_time
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;se initializeaza matricea
	call generate_mines
	call initialize_board
	call print_real_board ;se scrie in consola matricea
	
	;se aloca memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	
	;se apeleaza functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
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

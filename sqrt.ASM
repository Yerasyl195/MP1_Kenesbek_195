format PE GUI 4.0
entry start
include 'include\win32ax.inc'
;Секция данных содержит строковые переменные и константы, доступна только для чтения
section '.data' data readable
errmsg	db 'Ошибка командной строки',0
hlpmsg	db 'Программа должна запускаться в формате: sqrt a',13,10
	db 'Где a - действительное положительное число',13,10
	db 'Пример: sqrt 2.5',0

capt	db 'Вычисление квадратного корня по формуле Герона',0
fmt1	db '%lg',0
fmt	db 'x = %lg',13,10
	db 'Точное значние: %lg',13,10
	db 'Значение, полученное по итерационной формуле: %lg',0
e	dd 0.0005	;точность 0.05%
c2	dd 2
;секция кода
section '.code' code readable executable
start:	;начало программы
	call main		;вызов функции main
	invoke ExitProcess,0	;выход
;Главная функция программы
;Входных параметров нет (stdcall)
;Ничего не возвращает
main:
	push ebp		;пролог функции
	mov ebp,esp		;создание кадра стека
	sub esp,408h		;создание локальных переменных
;локальные переменные
a	equ ebp-408h
s	equ ebp-400h		;результирующая строка
	push ebx		;сохранить регистры по соглашению stdcall
	push esi
	push edi
	stdcall [GetCommandLine]	;получаем командную строку
	mov edi,eax		;адрес командной строки
	ccall [lstrlen],eax		;длина командной строки
	mov ebx,eax		;длина командной строки
	cmp byte [edi],'"'	;если строка начинаеся с "
	jz quotes		;то переход
	mov al,' '		;иначе имя запускаемого файла отделено пробелом
	mov ecx,ebx		;длина строки
	repne scasb		;ищем пробел или конец строки
	jmp fnd			;продолжить
quotes:	mov al,'"'		;ищем две пары кавычек
	mov ecx,ebx		;длина строки
	repne scasb		;первую
	repne scasb		;и вторую
fnd:	lea eax,[a]		;адрес переменой в стеке
	ccall [sscanf],edi,fmt1,eax	;распознаем в число
	test eax,eax	;проверить результат
	jg calc
;если ошибка, вывести сообщение
er:	stdcall [MessageBox],0,hlpmsg,errmsg,0	;вывод ошибки
	jmp ex		;выход
er1:	fstp st		;удалить число из сопроцессора
	jmp er		;вывести сообщение об ошибке
calc:	fld qword [a]	;a
	ftst		;сравнить а с 0
        fstsw ax	;перенести флаги сравнения в ах
        sahf		;занести ah в флаги процессора
	jbe er1		;если x<=0, значит неправильный аргумент

	fld [e]		;
	sub esp,8	;выделить в стеке место под double
	fstp qword [esp];записать в стек double число     
	sub esp,8	;выделить в стеке место под double
	fstp qword [esp];записать в стек double число     
	call mysqrt	;Вычислить mysqrt(x)
	add esp,16	;удалить переданные параметры     
	
	sub esp,8		;передать значение (s)
	fstp qword [esp]        ;функции через стек
	fld qword [a]		;a
	fsqrt			;вычисление точного значения
	sub esp,8		;передать значение (sqrt(a))
	fstp qword [esp]        ;функции через стек
	fld qword [a]		;a
	sub esp,8		;передать значение (a)
	fstp qword [esp]        ;функции через стек
	push fmt		;формат сообщения
	lea ebx,[s]		;адрес формируемого сообщения
	push ebx
	call [sprintf]		;сформировать результат
	add esp,32		;коррекция стека
	invoke MessageBox,0,ebx,capt,MB_OK ;вывести результат
ex:	pop edi 		;восстановить регистры
	pop esi
	pop ebx
	leave			;эпилог функции
	ret			;выход из функции

;double mysqrt(double a,double eps)
;вычисление sqrt(a) с точностью eps
;соглашение вызова cdecl
mysqrt:
	push ebp		;создать кадр стека
	mov ebp,esp
	sub esp,08h		;создание локальных переменных
;локальные переменные
xp	equ ebp-8h		;значение х на предыдущем шаге		
	fld qword [ebp+8]	;x=a

lp:	fst qword [xp]		;xp=x
	fld qword [ebp+8]	;a
	fld st1			;x
	fdivp st1,st		;a/x
	faddp st1,st		;x+a/x
	fidiv [c2]		;x=(x+a/x)/2
	fld st			;x
	fsub qword [xp]		;x-xp
	fabs			;|x-xp|
	fcomp [e]	;сравнить |x-xp| с xp
        fstsw ax	;перенести флаги сравнения в ах
        sahf		;занести ah в флаги процессора
	jae lp		;если |x-xp| >= xp, продолжаем цикл

	leave			;эпилог функции
	ret

section '.idata' import data readable writeable
  library kernel,'KERNEL32.DLL',\
	msvcrt,'MSVCRT.DLL',\
	user32,'USER32.DLL'

  import kernel,\
         lstrlen,'lstrlenA',\
	 GetCommandLine,'GetCommandLineA',\
         ExitProcess,'ExitProcess'

  import user32,\
	MessageBox,'MessageBoxA'

  import msvcrt,\
	sprintf,'sprintf',\
	sscanf,'sscanf'


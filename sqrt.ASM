format PE GUI 4.0
entry start
include 'include\win32ax.inc'
;������ ������ �������� ��������� ���������� � ���������, �������� ������ ��� ������
section '.data' data readable
errmsg	db '������ ��������� ������',0
hlpmsg	db '��������� ������ ����������� � �������: sqrt a',13,10
	db '��� a - �������������� ������������� �����',13,10
	db '������: sqrt 2.5',0

capt	db '���������� ����������� ����� �� ������� ������',0
fmt1	db '%lg',0
fmt	db 'x = %lg',13,10
	db '������ �������: %lg',13,10
	db '��������, ���������� �� ������������ �������: %lg',0
e	dd 0.0005	;�������� 0.05%
c2	dd 2
;������ ����
section '.code' code readable executable
start:	;������ ���������
	call main		;����� ������� main
	invoke ExitProcess,0	;�����
;������� ������� ���������
;������� ���������� ��� (stdcall)
;������ �� ����������
main:
	push ebp		;������ �������
	mov ebp,esp		;�������� ����� �����
	sub esp,408h		;�������� ��������� ����������
;��������� ����������
a	equ ebp-408h
s	equ ebp-400h		;�������������� ������
	push ebx		;��������� �������� �� ���������� stdcall
	push esi
	push edi
	stdcall [GetCommandLine]	;�������� ��������� ������
	mov edi,eax		;����� ��������� ������
	ccall [lstrlen],eax		;����� ��������� ������
	mov ebx,eax		;����� ��������� ������
	cmp byte [edi],'"'	;���� ������ ��������� � "
	jz quotes		;�� �������
	mov al,' '		;����� ��� ������������ ����� �������� ��������
	mov ecx,ebx		;����� ������
	repne scasb		;���� ������ ��� ����� ������
	jmp fnd			;����������
quotes:	mov al,'"'		;���� ��� ���� �������
	mov ecx,ebx		;����� ������
	repne scasb		;������
	repne scasb		;� ������
fnd:	lea eax,[a]		;����� ��������� � �����
	ccall [sscanf],edi,fmt1,eax	;���������� � �����
	test eax,eax	;��������� ���������
	jg calc
;���� ������, ������� ���������
er:	stdcall [MessageBox],0,hlpmsg,errmsg,0	;����� ������
	jmp ex		;�����
er1:	fstp st		;������� ����� �� ������������
	jmp er		;������� ��������� �� ������
calc:	fld qword [a]	;a
	ftst		;�������� � � 0
        fstsw ax	;��������� ����� ��������� � ��
        sahf		;������� ah � ����� ����������
	jbe er1		;���� x<=0, ������ ������������ ��������

	fld [e]		;
	sub esp,8	;�������� � ����� ����� ��� double
	fstp qword [esp];�������� � ���� double �����     
	sub esp,8	;�������� � ����� ����� ��� double
	fstp qword [esp];�������� � ���� double �����     
	call mysqrt	;��������� mysqrt(x)
	add esp,16	;������� ���������� ���������     
	
	sub esp,8		;�������� �������� (s)
	fstp qword [esp]        ;������� ����� ����
	fld qword [a]		;a
	fsqrt			;���������� ������� ��������
	sub esp,8		;�������� �������� (sqrt(a))
	fstp qword [esp]        ;������� ����� ����
	fld qword [a]		;a
	sub esp,8		;�������� �������� (a)
	fstp qword [esp]        ;������� ����� ����
	push fmt		;������ ���������
	lea ebx,[s]		;����� ������������ ���������
	push ebx
	call [sprintf]		;������������ ���������
	add esp,32		;��������� �����
	invoke MessageBox,0,ebx,capt,MB_OK ;������� ���������
ex:	pop edi 		;������������ ��������
	pop esi
	pop ebx
	leave			;������ �������
	ret			;����� �� �������

;double mysqrt(double a,double eps)
;���������� sqrt(a) � ��������� eps
;���������� ������ cdecl
mysqrt:
	push ebp		;������� ���� �����
	mov ebp,esp
	sub esp,08h		;�������� ��������� ����������
;��������� ����������
xp	equ ebp-8h		;�������� � �� ���������� ����		
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
	fcomp [e]	;�������� |x-xp| � xp
        fstsw ax	;��������� ����� ��������� � ��
        sahf		;������� ah � ����� ����������
	jae lp		;���� |x-xp| >= xp, ���������� ����

	leave			;������ �������
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


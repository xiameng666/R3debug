.386
.model flat, stdcall
option casemap:none

include windows.inc
include kernel32.inc
include msvcrt.inc
include linkedlistdll.inc


includelib kernel32.lib
includelib msvcrt.lib
includelib linkedlistdll.lib 

.const
; ��־����
LOG_DEBUG   equ 0
LOG_INFO    equ 1
LOG_WARNING equ 2
LOG_ERROR   equ 3
szDebug   db "[DEBUG] ", 0
szInfo    db "[INFO] ", 0
szWarning db "[WARN] ", 0
szError   db "[ERROR] ", 0

; ��������
PUBLIC LogInit
PUBLIC LogSetLevel
PUBLIC LogFilter
PUBLIC LogMsg

.data
g_nLogLevel dd 0
g_ModuleFilterList dd 0 ;ģ�����������

szLogBuffer db 1024 dup(0)  ; ���������ڸ�ʽ���ַ���
.code

; ��־��ʼ��
LogInit proc
    invoke LinkedList_Create
    mov g_ModuleFilterList, eax
    ret
LogInit endp

; ������־����
LogSetLevel proc nLevel:DWORD
    mov eax, nLevel
    mov g_nLogLevel, eax
    ret
LogSetLevel endp

; ������־���� 
LogFilter proc szModule:DWORD
    invoke LinkedList_AddPtr, g_ModuleFilterList, szModule
    ret
LogFilter endp

; �����־
LogMsg proc c uses esi nLevel:DWORD, szFormat:DWORD, args:VARARG ;VARARG parameter requires C calling convention
    LOCAL @szPrefix:DWORD;
    LOCAL @nFlag:DWORD;���˱�־
    LOCAL @index:DWORD;��������
    LOCAL @pModuleName:DWORD
    
    ; �����־����
    ;if (nLevel < g_nLogLevel) return;
    mov eax,nLevel
    cmp eax,g_nLogLevel
    jl done
    
;��ȡ��ǰģ����������Ƿ��ڹ����б���
    
    ; ��ʽ����־����
	lea esi,args
	invoke crt__vsnprintf,offset szLogBuffer,sizeof szLogBuffer,szFormat,esi
	
	mov @nFlag, 1
	mov @index,0

	;��������
	.while TRUE
		invoke LinkedList_GetPtr,g_ModuleFilterList,@index
		test eax,eax;��������
		jz check_output
		
		
		;�ַ����Ա��Ƿ����ģ����
		mov @pModuleName,eax
		invoke crt_strstr,offset szLogBuffer,@pModuleName
		test eax,eax
		;�ҵ�
		.if !ZERO?
			mov @nFlag,0
			jmp done
		.endif
		
		inc @index
		
	.endw
	
check_output:;�Ƿ���Ҫ�����־
	cmp @nFlag, 0
    je done
	
	; ������־����ѡ��ǰ׺
    .if nLevel == LOG_DEBUG
        mov @szPrefix, offset szDebug
    .elseif nLevel == LOG_INFO
        mov @szPrefix, offset szInfo
    .elseif nLevel == LOG_WARNING
        mov @szPrefix, offset szWarning
    .else
        mov @szPrefix, offset szError
    .endif
    
	; �����ǰ׺
    invoke crt_printf, @szPrefix
	; �����ʽ���������
    invoke crt_printf, offset szLogBuffer
done:
    ret
LogMsg endp

end	
section .text

global _start

_start:
    ; Входное сообщение
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, inMes
    mov rdx, inMesLen
    syscall

    cmp rax, 0 ; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)

    ; Считываем строку
    mov rax, 0
    mov rdi, 0
    mov rsi, string
    mov rdx, 101
    syscall
    
    cmp rax, 0
    JL errorSection; 0 символов - не ошибка. Значит ошибка только отрицательное число
    JE exitSection

    mov [str_len], rax
    mov rbx, string
    mov rsi, reversed_str
    mov rdx, [str_len]
    call reverse_string

    ; Выходное сообщение
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, outMes
    mov rdx, outMesLen
    syscall

    cmp rax, 0; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)

    ; Выводим перевернутую строку
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, reversed_str
    mov rdx, [str_len]
    syscall
    
    cmp rax, 0 ; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)
 
    ; Новая строка
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, newLine
    mov rdx, newLineLen
    syscall

    cmp rax, 0; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)   
    
    ; Завершаем работу
    JMP exitSection


reverse_string:
    ; rdx хранит длину строки
    ; rbx - ссылку на исходную строку (на входе), 
    ; rsi - сслыку на перевернутую строку
    ; rcx - счётчик
    
    mov rcx, 0 ; обнуляем счетчик (на всякий случай)

    mov r8, rbx ; сохраняем начало исходной строки в r8, чтобы не съехал указатель
    add rbx, rdx ; rdi указывает на конец исходной строки
    dec rbx ; корректируем на последний символ
  
    ; Проверяем и удаляем \n если есть
    cmp byte [rbx], 10
    jne .loop
    mov byte [rbx], 0
    dec rdx           ; уменьшаем длину строки
    dec rbx           ; переходим к предыдущему символу
    
.loop:
    mov al, [rbx] ; символ с текущего конца исходной строки 
    mov [rsi + rcx], al ; помещаем символ в перевернутую строку (движемся с начала) 
    dec rbx ; смещаем конец исходной строки
    inc rcx ; увеличиваем счётчик
    cmp rcx, rdx ; проврека на выход за границы
    jb .loop
    
    ret


errorSection:
    ; Вывелись не все символы на экран или есть ошибка
    ; Код ошибки лежим в rax, здесь возможна какая-то дополнительная логика
    mov rax, 0x1
    mov rdi, 0x2
    mov rsi, erMsg
    mov rdx, erMsgLen
    syscall
    
    mov rax, 0x3c
    mov rdi, 0x1
    syscall

exitSection:
    mov rax, 0x3c
    mov rdi, 0x0
    syscall

section .data
    inMes db "Enter string:"
    inMesLen equ $ - inMes
    outMes db "Reversed string:"
    outMesLen equ $ - outMes
    newLine db 10
    newLineLen equ $ - newLine
    string times 101 db 0     ; Исходная строка (100 символов + \n)
    str_len dd 0            ; Длина введенной строки
    erMsg db "Error happed during writing!", 10
    erMsgLen equ $ - erMsg

section .bss
    reversed_str resb 101  ; Буфер для перевернутой строки (100 символов + \n)


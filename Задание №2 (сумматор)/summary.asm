section .text

global _start

_start:

    ; Сообщение о первом числе
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, firstMes
    mov rdx, firstMesLen
    syscall
    
    cmp rax, firstMesLen ; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)

    ; Считываем первое число
    mov rax, 0
    mov rdi, 0
    mov rsi, firstNum
    mov rdx, 256
    syscall
    
    cmp rax, 0
    JLE errorSection; Ошибка - и 0, и отрицательное число

    mov [firstNumLen], rax
    mov rdi, firstNum
    mov rbx, [firstNumLen]

    call stringToNumberSection
    
    mov r10, rsi ; В r10 храним первое число
    
    ; Сообщение о втором числе
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, secondMes
    mov rdx, secondMesLen
    syscall
    
    cmp rax, secondMesLen ; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)

    ; Считываем второе число
    mov rax, 0
    mov rdi, 0
    mov rsi, secondNum
    mov rdx, 256
    syscall
    
    cmp rax, 0
    JLE errorSection; Ошибка - и 0, и отрицательное число

    mov [secondNumLen], rax
    mov rdi, secondNum
    mov rbx, [secondNumLen]

    call stringToNumberSection
    
    mov r11, rsi ; В r11 храним второе число
    
    add r10, r11
    mov r12, r10 ; в r12 храним сумму чисел
    
    mov rax, [firstNumLen]
    cmp [secondNumLen], rax
    jbe .secondIsBigger
    mov rdi, [firstNumLen]
    jmp .pre_convert

    .secondIsBigger:
        mov rdi, [secondNumLen]

    .pre_convert:
        ; длина суммы может быть больше максимального числа только на 1 символ
        add rdi, 2
        mov [sumLen], rdi
        mov rbx, sum
    
    call numberToStringSection
    ; Результат лежит в sum
    
    ; Сообщение о сумме
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, resultMes
    mov rdx, resultMesLen
    syscall
    
    cmp rax, resultMesLen ; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)

    ; Сумма
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, sum
    mov rdx, [sumLen]
    syscall
    
    cmp rax, [sumLen] ; rax не меняется, код ошибки не теряем, если она есть
    JL errorSection ; % Выведено меньше символов, чем ожидалось (если есть ошибка, то результат автоматически будет отрицательным)

    jmp exitSection
    


stringToNumberSection:
    ; rdi хранит указатель на число
    ; rbx хранит длину введённого числа
    ; r8 - 10, основание системы счисления
    ; r9 - множитель (степень 10)
    ; r12 - знак;
    ; rsi - результат расчёта
    
    mov r8, 10
    mov r9, 1 ; начинаем с 1, потом 10 и т.д.
    mov rcx, 0 ; счётчик цикла
    mov rsi, 0 ; обнуляем результат
    mov r12, 0 ; обнуляем знак
    
    ; Проверяем и убираем символ переноса строки
    cmp byte [rdi + rbx - 1], 10
    jne .check_sign
    ; Убираем \n, он же 10
    mov byte [rdi + rbx - 1], 0
    dec rbx
    
.check_sign:
    ; Проверяем первый символ на знак минус
    mov al, [rdi]
    cmp al, '-'
    jne .start_convert
    ; Устанавливаем флаг отрицательности и пропускаем знак
    mov r12, 1
    inc rdi ; пропускаем знак минус
    dec rbx ; уменьшаем длину

.start_convert:
    ; Начинаем с конца строки
    mov rcx, rbx
    dec rcx
    
.loopStrNum:
    cmp rcx, 0
    jl .check_negative  ; если счётчик 0, значит мы дошли до первого символа
    
    mov al, [rdi + rcx] ; текущий символ(считываем только 1 , если бы считывали в rax, то 8 байт бы считывали)
    
    ; Проверяем, что ввели цифру (символ в ASCII лежит выше символа 0 и ниже символа 9)
    cmp al, '0'
    jl nanSection
    cmp al, '9'
    jg nanSection
    
    ; Преобразуем символ в цифру путем вычетания ASCII кода из 0
    sub al, '0'
    
    movzx rax, al ; расшариваем 1 байт на 8
    imul rax, r9 ; умножаем на текущий разряд (1, 10, 100)
    add rsi, rax ; добавялем к результату
    
    ; Увеличиваем текущий разряд в "разрядность системы" раз
    mov rax, r9
    imul rax, r8
    mov r9, rax
    
    dec rcx ; сдвигаем иднекс в сторону начала строки
    jmp .loopStrNum

 .check_negative:
    ; Если был знак минус, инвертируем результат и заканчиваем
    cmp r12, 1
    jne .doneStrNum
    neg rsi
 
    
.doneStrNum:
    ret
    
numberToStringSection:
    ; r12 содержит исходное число(делимое)
    ; rbx хранит указатель на число
    ; rdi хранит длину результата числа
    ; rsi будет хранить целую часть от деления
    ; r9 - 10, основание системы счисления
    ; r13 - флаг отрицательности
    
    mov r9, 10
    mov rsi, 0 ; обнуляем результат
    mov r13, 0 ; флаг отрицательности
    
    ; Проверяем, отрицательное ли число
    cmp r12, 0
    jns .positive
    ; Если отрицательное, устанавливаем флаг и берем модуль
    mov r13, 1
    neg r12

.positive:
    mov rcx, rdi
    dec rcx ; Указываем на последний символ (резервируем под \n)
    dec rcx ; Указываем на последную цифру
    
.loopNumStr:
    mov rdx, 0 ; Обнуляем остаток от деления
    mov rax, r12 ; Записываем в rax делимое
    div r9 ; в rax - целая часть, в rdx - остаток от деления
    mov r12, rax

    mov rsi, rax ; запоминаем целую часть
    add rdx, '0'  ; сдвигаем на символ 0, чтобы преобразовать в число
    mov byte [rbx + rcx], dl; записываем цифру в итоговый результат

    cmp rsi, 0 ; если целая часть от деления 0, значит все число перенесено
    JE .add_sign
    dec rcx
    jmp .loopNumStr

.add_sign:
    ; Если число было отрицательным, добавляем знак минус
    cmp r13, 1
    jne .doneNumStr
    dec rcx
    mov byte [rbx + rcx], '-'

.doneNumStr:
    ; Добавляем \n, он же 10
    mov byte [rbx + rdi - 1], 10
    ret

nanSection:
    ; Если пользователь ввел не число, нужно вывести ему ошибку
    ; Вывелись не все символы на экран или есть ошибка
    ; Код ошибки лежим в rax, здесь возможна какая-то дополнительная логика
    mov rax, 0x1
    mov rdi, 0x2
    mov rsi, nanMsg
    mov rdx, nanMsgLen
    syscall
    
    mov rax, 0x3c
    mov rdi, 0x1
    syscall


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
    firstMes db "Enter first number:", 10
    firstMesLen equ $ - firstMes
    secondMes db "Enter second number:", 10
    secondMesLen equ $ - secondMes
    resultMes db "Sum is ", 10
    resultMesLen equ $ - resultMes
    erMsg db "Error happed during writing!", 10
    erMsgLen equ $ - erMsg
    nanMsg db "You entered not a number!", 10
    nanMsgLen equ $ - nanMsg

section .bss
    firstNum resb 8  ; Буфер для первого числа
    firstNumLen resq 1 ; Длина первого числа
    secondNum resb 8 ; Буфер для второго числа
    secondNumLen resq 1 ; Длина второго числа
    sum resb 8  ; Буфер для суммы числа
    sumLen resq 1 ; Длина второго числа


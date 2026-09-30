default rel

global WinMain
global WndProc
extern RegisterClassExA
extern CreateWindowExA
extern DefWindowProcA
extern ShowWindow
extern UpdateWindow
extern GetMessageA
extern TranslateMessage
extern DispatchMessageA
extern PostQuitMessage
extern LoadCursorA
extern BeginPaint
extern EndPaint
extern GetClientRect
extern CreateSolidBrush
extern DeleteObject
extern FillRect
extern DrawTextA
extern SetBkMode
extern SetTextColor
extern InvalidateRect
extern SetCapture
extern ReleaseCapture
extern DestroyWindow
extern PlaySoundA
extern MessageBoxA

%define WM_DESTROY       2
%define WM_PAINT         15
%define WM_ERASEBKGND    20
%define WM_KEYDOWN       256
%define WM_KEYUP         257
%define WM_LBUTTONDOWN   513
%define WM_LBUTTONUP     514
%define WM_CAPTURECHANGED 533
%define CS_HREDRAW       2
%define CS_VREDRAW       1
%define WS_OVERLAPPEDWINDOW 00CF0000h
%define CW_USEDEFAULT    80000000h
%define IDC_ARROW        32512
%define COLOR_BG         171A2Bh
%define COLOR_PANEL      22263Bh
%define COLOR_WHITE_KEY  0F4F1E8h
%define COLOR_BLACK_KEY  25283Ah
%define COLOR_ACCENT     0F4B942h
%define COLOR_PRESSED    51D6B0h
%define COLOR_TEXT       0F4F1E8h
%define COLOR_MUTED      0A8AEC4h
%define SAMPLE_RATE      22050
%define SAMPLE_COUNT     6615

section .data
    class_name db "NasmPianoWindow", 0
    window_title db "Piano em Assembly - NASM", 0
    heading db "PIANO", 0
    subtitle db "Clique nas teclas ou use o teclado do computador", 0
    footer db "A W S E D F T G Y H U J K    |    ESC para sair", 0
    msg_register db "Nao foi possivel registrar a janela do piano.", 0
    msg_window db "Nao foi possivel criar a janela do piano.", 0
    key_map db "awsedftgyhujk"
    note_names:
        dq note_c4, note_cs4, note_d4, note_ds4, note_e4
        dq note_f4, note_fs4, note_g4, note_gs4, note_a4
        dq note_as4, note_b4, note_c5
    note_c4  db "C4", 0
    note_cs4 db "C#4", 0
    note_d4  db "D4", 0
    note_ds4 db "D#4", 0
    note_e4  db "E4", 0
    note_f4  db "F4", 0
    note_fs4 db "F#4", 0
    note_g4  db "G4", 0
    note_gs4 db "G#4", 0
    note_a4  db "A4", 0
    note_as4 db "A#4", 0
    note_b4  db "B4", 0
    note_c5  db "C5", 0
    note_phase_steps dd 50960238, 53990491, 57200933, 60602278, 64205876
                     dd 68023757, 72068660, 76354085, 80894335, 85704563
                     dd 90800821, 96200119, 101920476
    white_note_indices db 0, 2, 4, 5, 7, 9, 11, 12
    black_note_indices db 1, 3, 6, 8, 10
    black_key_positions dd 102, 186, 354, 438, 522
    sine_table:
        db 128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158, 162, 165, 167, 170, 173
        db 176, 179, 182, 185, 188, 190, 193, 196, 198, 201, 203, 206, 208, 211, 213, 215
        db 218, 220, 222, 224, 226, 228, 230, 232, 234, 235, 237, 238, 240, 241, 243, 244
        db 245, 246, 248, 249, 250, 250, 251, 252, 253, 253, 254, 254, 254, 255, 255, 255
        db 255, 255, 255, 255, 254, 254, 254, 253, 253, 252, 251, 250, 250, 249, 248, 246
        db 245, 244, 243, 241, 240, 238, 237, 235, 234, 232, 230, 228, 226, 224, 222, 220
        db 218, 215, 213, 211, 208, 206, 203, 201, 198, 196, 193, 190, 188, 185, 182, 179
        db 176, 173, 170, 167, 165, 162, 158, 155, 152, 149, 146, 143, 140, 137, 134, 131
        db 128, 124, 121, 118, 115, 112, 109, 106, 103, 100, 97, 93, 90, 88, 85, 82
        db 79, 76, 73, 70, 67, 65, 62, 59, 57, 54, 52, 49, 47, 44, 42, 40
        db 37, 35, 33, 31, 29, 27, 25, 23, 21, 20, 18, 17, 15, 14, 12, 11
        db 10, 9, 7, 6, 5, 5, 4, 3, 2, 2, 1, 1, 1, 0, 0, 0
        db 0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 5, 6, 7, 9
        db 10, 11, 12, 14, 15, 17, 18, 20, 21, 23, 25, 27, 29, 31, 33, 35
        db 37, 40, 42, 44, 47, 49, 52, 54, 57, 59, 62, 65, 67, 70, 73, 76
        db 79, 82, 85, 88, 90, 93, 97, 100, 103, 106, 109, 112, 115, 118, 121, 124

section .bss
    audio_buffer resb 44 + SAMPLE_COUNT
    active_note resd 1
    window_class resb 80

section .text
WinMain:
    sub rsp, 0B8h
    mov [rsp + 96], rcx
    mov [rsp + 104], r9d
    mov dword [rel active_note], -1

    mov dword [rel window_class], 80
    mov dword [rel window_class + 4], CS_HREDRAW | CS_VREDRAW
    lea rax, [rel WndProc]
    mov [rel window_class + 8], rax
    mov rax, [rsp + 96]
    mov [rel window_class + 24], rax
    xor ecx, ecx
    mov edx, IDC_ARROW
    call LoadCursorA
    mov [rel window_class + 40], rax
    mov dword [rel window_class + 48], 6
    lea rax, [rel class_name]
    mov [rel window_class + 64], rax
    lea rcx, [rel window_class]
    call RegisterClassExA
    test ax, ax
    jz .register_error

    xor ecx, ecx
    lea rdx, [rel class_name]
    lea r8, [rel window_title]
    mov r9d, WS_OVERLAPPEDWINDOW
    mov dword [rsp + 32], CW_USEDEFAULT
    mov dword [rsp + 40], CW_USEDEFAULT
    mov dword [rsp + 48], 790
    mov dword [rsp + 56], 490
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov rax, [rsp + 96]
    mov [rsp + 80], rax
    mov qword [rsp + 88], 0
    call CreateWindowExA
    test rax, rax
    jz .window_error
    mov [rsp + 112], rax

    mov rcx, rax
    mov edx, dword [rsp + 104]
    call ShowWindow
    mov rcx, [rsp + 112]
    call UpdateWindow

    lea rcx, [rsp + 120]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
.message_loop:
    call GetMessageA
    test eax, eax
    jle .exit
    lea rcx, [rsp + 120]
    call TranslateMessage
    lea rcx, [rsp + 120]
    call DispatchMessageA
    lea rcx, [rsp + 120]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    jmp .message_loop

.register_error:
    xor ecx, ecx
    lea rdx, [rel msg_register]
    lea r8, [rel window_title]
    xor r9d, r9d
    call MessageBoxA
    jmp .exit
.window_error:
    xor ecx, ecx
    lea rdx, [rel msg_window]
    lea r8, [rel window_title]
    xor r9d, r9d
    call MessageBoxA
.exit:
    xor eax, eax
    add rsp, 0B8h
    ret

WndProc:
    sub rsp, 0C8h
    mov [rsp + 32], rcx
    mov [rsp + 40], edx
    mov [rsp + 48], r8
    mov [rsp + 56], r9

    cmp edx, WM_ERASEBKGND
    je .erased
    cmp edx, WM_PAINT
    je .paint
    cmp edx, WM_KEYDOWN
    je .key_down
    cmp edx, WM_KEYUP
    je .key_up
    cmp edx, WM_LBUTTONDOWN
    je .mouse_down
    cmp edx, WM_LBUTTONUP
    je .mouse_up
    cmp edx, WM_CAPTURECHANGED
    je .capture_changed
    cmp edx, WM_DESTROY
    je .destroy

.default:
    mov rcx, [rsp + 32]
    mov edx, [rsp + 40]
    mov r8, [rsp + 48]
    mov r9, [rsp + 56]
    call DefWindowProcA
    jmp .return

.erased:
    mov eax, 1
    jmp .return

.key_down:
    cmp dword [rsp + 48], 27
    je .close_window
    test dword [rsp + 56], 40000000h
    jnz .handled
    mov eax, dword [rsp + 48]
    or eax, 20h
    call find_note_for_key
    cmp eax, -1
    je .default
    mov [rsp + 64], eax
    mov ecx, eax
    call play_note
    mov eax, [rsp + 64]
    mov [rel active_note], eax
    mov rcx, [rsp + 32]
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    jmp .handled

.key_up:
    mov eax, dword [rsp + 48]
    or eax, 20h
    call find_note_for_key
    cmp eax, -1
    je .default
    cmp eax, [rel active_note]
    jne .default
    mov dword [rel active_note], -1
    mov rcx, [rsp + 32]
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    jmp .handled

.mouse_down:
    mov rcx, [rsp + 32]
    call SetCapture
    mov ecx, dword [rsp + 56]
    call mouse_note_at_position
    cmp eax, -1
    je .handled
    mov [rsp + 64], eax
    mov ecx, eax
    call play_note
    mov eax, [rsp + 64]
    mov [rel active_note], eax
    mov rcx, [rsp + 32]
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    jmp .handled

.mouse_up:
    call ReleaseCapture
    mov dword [rel active_note], -1
    mov rcx, [rsp + 32]
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    jmp .handled

.capture_changed:
    mov dword [rel active_note], -1
    mov rcx, [rsp + 32]
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    jmp .handled

.close_window:
    mov rcx, [rsp + 32]
    call DestroyWindow
    jmp .handled

.destroy:
    xor ecx, ecx
    call PostQuitMessage

.handled:
    xor eax, eax
    jmp .return

.paint:
    mov rcx, [rsp + 32]
    lea rdx, [rsp + 64]
    call BeginPaint
    mov [rsp + 152], rax

    mov rcx, COLOR_BG
    call CreateSolidBrush
    mov [rsp + 160], rax
    mov rcx, COLOR_PANEL
    call CreateSolidBrush
    mov [rsp + 168], rax
    mov rcx, COLOR_WHITE_KEY
    call CreateSolidBrush
    mov [rsp + 176], rax

    mov rcx, [rsp + 32]
    lea rdx, [rsp + 136]
    call GetClientRect
    mov rcx, [rsp + 152]
    lea rdx, [rsp + 136]
    mov r8, [rsp + 160]
    call FillRect

    mov dword [rsp + 136], 42
    mov dword [rsp + 140], 128
    mov dword [rsp + 144], 748
    mov dword [rsp + 148], 374
    mov rcx, [rsp + 152]
    lea rdx, [rsp + 136]
    mov r8, [rsp + 168]
    call FillRect

    mov rcx, [rsp + 152]
    lea rdx, [rel heading]
    lea r8, [rsp + 136]
    mov dword [rsp + 136], 70
    mov dword [rsp + 140], 34
    mov dword [rsp + 144], 280
    mov dword [rsp + 148], 82
    mov r9d, COLOR_ACCENT
    call draw_text_left

    mov rcx, [rsp + 152]
    lea rdx, [rel subtitle]
    lea r8, [rsp + 136]
    mov dword [rsp + 136], 70
    mov dword [rsp + 140], 78
    mov dword [rsp + 144], 650
    mov dword [rsp + 148], 108
    mov r9d, COLOR_MUTED
    call draw_text_centered

    mov dword [rsp + 72], 0
.white_loop:
    mov eax, [rsp + 72]
    imul eax, 84
    add eax, 44
    mov [rsp + 136], eax
    mov dword [rsp + 140], 155
    add eax, 82
    mov [rsp + 144], eax
    mov dword [rsp + 148], 350
    mov eax, [rsp + 72]
    lea r11, [rel white_note_indices]
    movzx eax, byte [r11 + rax]
    cmp eax, [rel active_note]
    jne .white_normal
    mov rcx, COLOR_ACCENT
    jmp .white_brush
.white_normal:
    mov rcx, COLOR_WHITE_KEY
.white_brush:
    call CreateSolidBrush
    mov [rsp + 184], rax
    mov rcx, [rsp + 152]
    lea rdx, [rsp + 136]
    mov r8, [rsp + 184]
    call FillRect
    mov rcx, [rsp + 184]
    call DeleteObject

    mov eax, [rsp + 72]
    lea r11, [rel white_note_indices]
    movzx eax, byte [r11 + rax]
    mov [rsp + 80], eax
    mov eax, [rsp + 80]
    lea rdx, [rel note_names]
    mov rdx, [rdx + rax*8]
    mov rcx, [rsp + 152]
    lea r8, [rsp + 136]
    mov eax, [rsp + 136]
    mov [rsp + 136], eax
    mov dword [rsp + 140], 310
    mov eax, [rsp + 144]
    mov [rsp + 144], eax
    mov dword [rsp + 148], 348
    mov r9d, COLOR_BLACK_KEY
    call draw_text_centered

    inc dword [rsp + 72]
    cmp dword [rsp + 72], 8
    jl .white_loop

    mov dword [rsp + 72], 0
.black_loop:
    mov eax, [rsp + 72]
    lea r11, [rel black_key_positions]
    mov eax, [r11 + rax*4]
    mov [rsp + 136], eax
    mov dword [rsp + 140], 155
    add eax, 48
    mov [rsp + 144], eax
    mov dword [rsp + 148], 273
    mov eax, [rsp + 72]
    lea r11, [rel black_note_indices]
    movzx eax, byte [r11 + rax]
    cmp eax, [rel active_note]
    jne .black_normal
    mov rcx, COLOR_PRESSED
    jmp .black_brush
.black_normal:
    mov rcx, COLOR_BLACK_KEY
.black_brush:
    call CreateSolidBrush
    mov [rsp + 184], rax
    mov rcx, [rsp + 152]
    lea rdx, [rsp + 136]
    mov r8, [rsp + 184]
    call FillRect
    mov rcx, [rsp + 184]
    call DeleteObject

    mov eax, [rsp + 72]
    lea r11, [rel black_note_indices]
    movzx eax, byte [r11 + rax]
    lea rdx, [rel note_names]
    mov rdx, [rdx + rax*8]
    mov rcx, [rsp + 152]
    mov eax, [rsp + 136]
    mov [rsp + 136], eax
    mov dword [rsp + 140], 230
    mov eax, [rsp + 144]
    mov [rsp + 144], eax
    mov dword [rsp + 148], 270
    lea r8, [rsp + 136]
    mov r9d, COLOR_TEXT
    call draw_text_centered

    inc dword [rsp + 72]
    cmp dword [rsp + 72], 5
    jl .black_loop

    mov rcx, [rsp + 152]
    lea rdx, [rel footer]
    mov dword [rsp + 136], 70
    mov dword [rsp + 140], 392
    mov dword [rsp + 144], 720
    mov dword [rsp + 148], 426
    lea r8, [rsp + 136]
    mov r9d, COLOR_MUTED
    call draw_text_centered

    mov rcx, [rsp + 176]
    call DeleteObject
    mov rcx, [rsp + 168]
    call DeleteObject
    mov rcx, [rsp + 160]
    call DeleteObject
    mov rcx, [rsp + 32]
    lea rdx, [rsp + 64]
    call EndPaint
    xor eax, eax

.return:
    add rsp, 0C8h
    ret

draw_text_centered:
    sub rsp, 72
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx
    mov [rsp + 56], r8
    mov [rsp + 64], r9d
    mov rcx, [rsp + 40]
    mov edx, 1
    call SetBkMode
    mov rcx, [rsp + 40]
    mov edx, [rsp + 64]
    call SetTextColor
    mov rcx, [rsp + 40]
    mov rdx, [rsp + 48]
    mov r8d, -1
    mov r9, [rsp + 56]
    mov dword [rsp + 32], 25h
    call DrawTextA
    add rsp, 72
    ret

draw_text_left:
    sub rsp, 72
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx
    mov [rsp + 56], r8
    mov [rsp + 64], r9d
    mov rcx, [rsp + 40]
    mov edx, 1
    call SetBkMode
    mov rcx, [rsp + 40]
    mov edx, [rsp + 64]
    call SetTextColor
    mov rcx, [rsp + 40]
    mov rdx, [rsp + 48]
    mov r8d, -1
    mov r9, [rsp + 56]
    mov dword [rsp + 32], 24h
    call DrawTextA
    add rsp, 72
    ret

find_note_for_key:
    xor ecx, ecx
    lea r11, [rel key_map]
.find_loop:
    cmp ecx, 13
    jge .not_found
    cmp al, byte [r11 + rcx]
    je .found
    inc ecx
    jmp .find_loop
.found:
    mov eax, ecx
    ret
.not_found:
    mov eax, -1
    ret

mouse_note_at_position:
    sub rsp, 40
    mov dword [rsp + 8], ecx
    mov eax, ecx
    mov edx, eax
    and eax, 0FFFFh
    shr edx, 16
    cmp eax, 42
    jl .no_note
    cmp eax, 716
    jge .no_note
    cmp edx, 155
    jl .no_note
    cmp edx, 350
    jge .no_note
    mov [rsp + 16], eax
    mov [rsp + 20], edx
    cmp edx, 273
    jge .white
    xor ecx, ecx
.black_test:
    cmp ecx, 5
    jge .white
    mov edx, [rsp + 16]
    lea r11, [rel black_key_positions]
    mov eax, [r11 + rcx*4]
    cmp edx, eax
    jl .next_black
    add eax, 48
    cmp edx, eax
    jl .black_found
.next_black:
    inc ecx
    jmp .black_test
.black_found:
    lea r11, [rel black_note_indices]
    movzx eax, byte [r11 + rcx]
    add rsp, 40
    ret
.white:
    mov eax, [rsp + 16]
    sub eax, 42
    xor edx, edx
    mov ecx, 84
    div ecx
    cmp eax, 8
    jge .no_note
    lea r11, [rel white_note_indices]
    movzx eax, byte [r11 + rax]
    add rsp, 40
    ret
.no_note:
    mov eax, -1
    add rsp, 40
    ret

play_note:
    sub rsp, 40
    mov [rsp + 32], ecx
    xor ecx, ecx
    xor edx, edx
    xor r8d, r8d
    call PlaySoundA

    mov eax, [rsp + 32]
    lea r11, [rel note_phase_steps]
    mov eax, [r11 + rax*4]
    mov r9d, eax
    xor r8d, r8d
    xor r10d, r10d
.sample_loop:
    mov eax, r8d
    shr eax, 24
    lea r11, [rel audio_buffer]
    lea rdx, [rel sine_table]
    mov al, [rdx + rax]
    mov byte [r11 + r10 + 44], al
    add r8d, r9d
    inc r10d
    cmp r10d, SAMPLE_COUNT
    jl .sample_loop

    mov dword [rel audio_buffer], 46464952h
    mov dword [rel audio_buffer + 4], 36 + SAMPLE_COUNT
    mov dword [rel audio_buffer + 8], 45564157h
    mov dword [rel audio_buffer + 12], 20746D66h
    mov dword [rel audio_buffer + 16], 16
    mov word [rel audio_buffer + 20], 1
    mov word [rel audio_buffer + 22], 1
    mov dword [rel audio_buffer + 24], SAMPLE_RATE
    mov dword [rel audio_buffer + 28], SAMPLE_RATE
    mov word [rel audio_buffer + 32], 1
    mov word [rel audio_buffer + 34], 8
    mov dword [rel audio_buffer + 36], 61746164h
    mov dword [rel audio_buffer + 40], SAMPLE_COUNT
    lea rcx, [rel audio_buffer]
    xor edx, edx
    mov r8d, 7
    call PlaySoundA
    add rsp, 40
    ret

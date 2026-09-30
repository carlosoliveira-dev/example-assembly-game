@echo off
setlocal

nasm -f win64 piano.asm -o piano.obj
if errorlevel 1 exit /b 1

gcc -mwindows piano.obj -o piano.exe -lwinmm -lgdi32 -luser32 -lkernel32
if errorlevel 1 exit /b 1

del piano.obj
echo Piano compilado com sucesso: piano.exe

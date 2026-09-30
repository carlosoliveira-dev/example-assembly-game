# Piano gráfico em Assembly com NASM

Piano gráfico para Windows 64-bit, escrito em NASM. A janela tem um teclado
de uma oitava, aceita cliques e também toca as notas digitadas no teclado do
computador. O som é sintetizado e reproduzido sem bloquear a interface.

## Compilar

Com `nasm` e `gcc` (MinGW-w64) disponíveis no `PATH`, execute:

```bat
build.bat
```

## Usar

Compile e execute `piano.exe`. Clique nas teclas do piano ou use:

| Tecla | Nota |
|---|---|
| A | C4 |
| W | C#4 |
| S | D4 |
| E | D#4 |
| D | E4 |
| F | F4 |
| T | F#4 |
| G | G4 |
| Y | G#4 |
| H | A4 |
| U | A#4 |
| J | B4 |
| K | C5 |

Mantenha uma tecla pressionada para destacá-la na interface. Pressione `Esc`
para fechar a janela.

As notas usam afinação temperada com referência A4 = 440 Hz e são sintetizadas
com uma onda senoidal para manter a altura precisa e evitar a distorção da
forma de onda anterior.

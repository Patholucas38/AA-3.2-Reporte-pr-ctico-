PROCESSOR 16F877A
#include <xc.inc>

; == CONFIGURACIÓN DEL MICROCONTROLADOR ==
CONFIG FOSC = HS     ; Oscilador de alta velocidad (4MHz)
CONFIG WDTE = OFF    ; Watchdog Timer desactivado
CONFIG PWRTE = ON    ; Timer de encendido habilitado
CONFIG BOREN = ON    ; Habilita el reinicio por bajo voltaje
CONFIG LVP = OFF     ; Desactiva programación de bajo voltaje
CONFIG CPD = OFF     ; Protección del área de datos desactivada
CONFIG WRT = OFF     ; Protección de escritura desactivada
CONFIG CP = OFF      ; Protección de código desactivada

; == DEFINICIÓN DE PINES PARA LCD ==
#define LCD_RS PORTC, 0   ; RS del LCD conectado a RC0
#define LCD_RW PORTC, 1   ; RW del LCD conectado a RC1
#define LCD_EN PORTC, 2   ; EN del LCD conectado a RC2

; == VARIABLES EN RAM ==
PSECT udata_bank0
TIMER_1: DS 1           ; Temporizador externo para delay
TIMER_2: DS 1           ; Temporizador interno para delay
VALUE_TEMP: DS 1        ; Valor leído del ADC
CALCULATED: DS 1        ; Resultado del procesamiento del ADC
DIV_RESULT: DS 1        ; Cociente de la división para mostrar el número
DIV_REMAINDER: DS 1     ; Residuo de la división

; == VECTOR DE REINICIO ==
PSECT resetVec, class=CODE, delta=2
reset_vector:
    GOTO main           ; Salta al inicio del programa

; == PROGRAMA PRINCIPAL ==
PSECT code, delta=2
main:
    BANKSEL TRISA
    MOVLW 0x01
    MOVWF TRISA         ; RA0 como entrada (sensor)

    BANKSEL ADCON1
    MOVLW 0x0E
    MOVWF ADCON1        ; RA0 analógica, los demás digitales

    BANKSEL ADCON0
    MOVLW 0x41
    MOVWF ADCON0        ; ADC encendido, canal 0 (RA0)

    MOVLW 50
    CALL Delay_ms       ; Pequeño retardo inicial

    BANKSEL TRISB
    CLRF TRISB          ; Puerto B como salida
    BANKSEL TRISC
    CLRF TRISC          ; Puerto C como salida (control LCD)
    BANKSEL TRISD
    CLRF TRISD          ; Puerto D como salida (datos LCD)
    BANKSEL PORTA

    CALL LCD_Setup      ; Inicializa el LCD

    ; == MENSAJE DE BIENVENIDA ==
    MOVLW 0x80
    CALL LCD_Command    ; Posición cursor línea 1
    MOVLW 'B'
    CALL LCD_PrintChar
    MOVLW 'I'
    CALL LCD_PrintChar
    MOVLW 'E'
    CALL LCD_PrintChar
    MOVLW 'N'
    CALL LCD_PrintChar
    MOVLW 'V'
    CALL LCD_PrintChar
    MOVLW 'E'
    CALL LCD_PrintChar
    MOVLW 'N'
    CALL LCD_PrintChar
    MOVLW 'I'
    CALL LCD_PrintChar
    MOVLW 'D'
    CALL LCD_PrintChar
    MOVLW 'O'
    CALL LCD_PrintChar

    MOVLW 0xC0
    CALL LCD_Command    ; Posición cursor línea 2
    MOVLW 'I'
    CALL LCD_PrintChar
    MOVLW 'S'
    CALL LCD_PrintChar
    MOVLW 'C'
    CALL LCD_PrintChar
    MOVLW ' '
    CALL LCD_PrintChar
    MOVLW '6'
    CALL LCD_PrintChar
    MOVLW 'A'
    CALL LCD_PrintChar

    MOVLW 60000
    CALL Delay_ms       ; Espera 60 segundos

    MOVLW 5000
    CALL Delay_ms       ; Espera 5 segundos más

    MOVLW 0x01
    CALL LCD_Command    ; Limpia la pantalla del LCD

; == BUCLE PRINCIPAL ==
loop:
    MOVLW 30
    CALL Delay_ms       ; Espera para siguiente lectura

    BSF ADCON0, 2       ; Inicia conversión ADC

adc_wait:
    BTFSC ADCON0, 2     ; Espera a que ADC termine
    GOTO adc_wait

    BANKSEL ADRESH
    MOVF ADRESH, W
    MOVWF VALUE_TEMP    ; Guarda valor del ADC (8 bits)
    MOVF VALUE_TEMP, W
    ADDWF VALUE_TEMP, W ; Doble del valor
    MOVWF CALCULATED    ; Guarda valor procesado

    ; == MUESTRA TEMPERATURA ==
    MOVLW 0x80
    CALL LCD_Command
    MOVLW 'T'
    CALL LCD_PrintChar
    MOVLW 'e'
    CALL LCD_PrintChar
    MOVLW 'm'
    CALL LCD_PrintChar
    MOVLW 'p'
    CALL LCD_PrintChar
    MOVLW ':'
    CALL LCD_PrintChar
    MOVLW ' '
    CALL LCD_PrintChar

    CALL LCD_ShowValue  ; Convierte y muestra el valor en °C

    ; == MUESTRA "ISC 6A" EN LÍNEA 2 ==
    MOVLW 0xC0
    CALL LCD_Command
    MOVLW 'I'
    CALL LCD_PrintChar
    MOVLW 'S'
    CALL LCD_PrintChar
    MOVLW 'C'
    CALL LCD_PrintChar
    MOVLW ' '
    CALL LCD_PrintChar
    MOVLW '6'
    CALL LCD_PrintChar
    MOVLW 'A'
    CALL LCD_PrintChar

    MOVLW 200
    CALL Delay_ms       ; Espera antes de siguiente ciclo

    BSF ADCON0, 0       ; Habilita módulo ADC
    GOTO loop           ; Vuelve a leer y mostrar


;==RETARDO EN MILISEGUNDOS==

Delay_ms:
    MOVWF TIMER_1
Delay_Outer:
    MOVLW 250
    MOVWF TIMER_2
Delay_Inner:
    NOP
    NOP
    DECFSZ TIMER_2, F
    GOTO Delay_Inner
    DECFSZ TIMER_1, F
    GOTO Delay_Outer
    RETURN

;==INICIALIZACIÓN DE LCD

LCD_Setup:
    MOVLW 50
    CALL Delay_ms

    MOVLW 0x30
    CALL LCD_Command_Init
    MOVLW 10
    CALL Delay_ms

    MOVLW 0x30
    CALL LCD_Command_Init
    MOVLW 5
    CALL Delay_ms

    MOVLW 0x30
    CALL LCD_Command_Init
    MOVLW 5
    CALL Delay_ms

    MOVLW 0x38         ;lcd 8 Bits. 2 Lineas
    CALL LCD_Command
    MOVLW 5
    CALL Delay_ms

    MOVLW 0x08        ;Display OFF
    CALL LCD_Command
    MOVLW 5
    CALL Delay_ms

    MOVLW 0x01          ;Limpa el LCD
    CALL LCD_Command
    MOVLW 20
    CALL Delay_ms

    MOVLW 0x06           ;Modo de entrada (cursos derecha)
    CALL LCD_Command
    MOVLW 5
    CALL Delay_ms

    MOVLW 0x0C           ;Display ON, Sin cursos
    CALL LCD_Command
    MOVLW 5
    CALL Delay_ms

    RETURN

;== ENVÍA COMANDO AL LCD SIN ESPERA=0

LCD_Command_Init:
    BCF LCD_RS
    BCF LCD_RW
    MOVWF PORTD
    BSF LCD_EN
    NOP
    NOP
    NOP
    NOP
    BCF LCD_EN
    RETURN

;== ENVÍA COMANDO AL LCD==

LCD_Command:
    BCF LCD_RS
    BCF LCD_RW
    MOVWF PORTD
    BSF LCD_EN
    NOP
    NOP
    NOP
    NOP
    BCF LCD_EN
    MOVLW 2
    CALL Delay_ms
    RETURN

;==IMPRIMER UN CARÁCTER EN LCD==

LCD_PrintChar:
    BSF LCD_RS
    BCF LCD_RW
    MOVWF PORTD
    BSF LCD_EN
    NOP
    NOP
    NOP
    NOP
    BCF LCD_EN
    MOVLW 1
    CALL Delay_ms
    RETURN

;==CONVIERTE Y MUESTRA LA PANTALLA==

LCD_ShowValue:
    MOVF CALCULATED, W
    MOVWF DIV_REMAINDER
    CLRF DIV_RESULT

    MOVLW 10
    SUBWF DIV_REMAINDER, W
    BTFSS STATUS, 0
    GOTO ShowOutput

DivideLoop:
    MOVLW 10
    SUBWF DIV_REMAINDER, W
    BTFSS STATUS, 0
    GOTO ShowOutput
    INCF DIV_RESULT, F
    MOVLW 10
    SUBWF DIV_REMAINDER, F
    GOTO DivideLoop

ShowOutput:
    MOVF DIV_RESULT, W
    ADDLW '0'
    CALL LCD_PrintChar

    MOVF DIV_REMAINDER, W
    ADDLW '0'
    CALL LCD_PrintChar

    MOVLW 0xDF                 ; caracter ° (Grados)
    CALL LCD_PrintChar
    MOVLW 'C'                   ; Letra C (Celsius)
    CALL LCD_PrintChar
    RETURN

END  ; final del programa



# Password hacking
This task is considered to implement DOS password checker in Turbo Assembler. However, I should have left some weak places in such a way that it would be possible to hack it and pass a check successfully.

<img src="first.png">

> There is a silenced moment that I don't want to stop at: hash. It's really primitive and has (I suppose) many collisions, so unusable in real application. However, it seems suitable for this task. (At least I didn't manage to find out a password by hash without brute force with exponential growth). See C analogue in `hash.c` file.

First of all, let's have a look at a main loop code:
```asm
Start:      mov byte ptr [input], 255 ; Set max input length = 255.

.ReadLoop:  ; Print "Enter password".

            mov ah, 0ah               ; Read password.
            lea dx, [input]           ; Note that input[1] = input length.
            int 21h

            HASH input+2				      ; Count input hash.

            lea di, [input+2]         ; Input starts from 2nd position.
            lea si, [password]
            xor cx, cx
            mov cl, [passw_len]
            MEMCMP di, si, cx         ; Compare `cx` bytes of memory lexicographically.
            cmp ax, 0                 ; ax = 0 if they are equal.
            jne .Fail
            ; Success.
```
And at `.data` segment:
```asm
.data
passw_len   db 10
input       db 30 dup(?)              ; Note that input[0] = max input length.
canary1     db 1                      ; And input[1] = input length.
password    db 115,60,236,253,132,181,220,21,152,62 ; Hashed password.
canary2     db 1
```

Have you found a weak place? Password almost says: "Hey, I'm a vulnerable password, therefore I'm protected by canaries".

In fact, a hack idea is pretty simple and well known: buffer overflow. Pay attention at these lines:
```asm
Start:      mov byte ptr [input], 255 ; Set max input length = 255.
...
input       db 30 dup(?)              
canary1     db 1                      
password    db 115,60,236,253,132,181,220,21,152,62
canary2     db 1
```
Here we see that input is supposed to be under 30 symbols. From the other side, maximum input length is 255. So what happens if we enter 60 chars? We fill `input`, then we fill `canary1`, then `password`... Stop, what?! We've changed password with input?!

However, 50 identical symbols would not break a password, for `input != hash(input)`. So what why not to fill `input` with random bytes and `passoword` with its hash?..

The only thing we have to do is to count `hash(input)`, which is not a rocket science if you have `.COM` file and Turbo Debugger. Let's take ten ones: `1111111111` as a password. Then decimal representation of a hash is `29 217 190 17 195 35 36 148 116 217`. Next, since 20 bytes between password and hash are not important, fill them with any characters.

Let's give it a try:
<img src="hack_without_hash.png">

Eh... What about `29 217 190 17 195 35 36 148 116 217`? There is a hack: almost any symbol in range of `[1..255]` [can be entered](https://kb.iu.edu/d/afcy) via `Alt + sym_decimal_code` (though there are few exceptions).
 
Here what we get:
<img src="hack_no_can.png">

Output:
<img src="you_shall_not_pass.png">

Now have a look at this part of a loop:
```asm
.Success:   mov al, [canary1]
            add al, [canary2]
            cmp al, 2               ; equal iif canary1 = canary2 = 1
            jne .Alarm              
            PRINT success_msg
            PRINT newline
            jmp .ExitProg
.Alarm:     PRINT alarm
            jmp .Alarm
```
Seems like we've forgotten about canaries, aren't we? Let's fix it by surrounding hash part with `Alt+1`:

<img src="success.png">

**Welcome!**

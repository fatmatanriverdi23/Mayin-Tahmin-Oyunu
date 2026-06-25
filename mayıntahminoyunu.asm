org 100h

mov ax, 0003h
int 10h
jmp start

; DATA
; =======================

cursorX db 0
cursorY db 0
oldX db 0
oldY db 0

X_OFF equ 20
Y_OFF equ 2
HEART_X equ 2
HEART_Y equ 4
HUD_X equ 64
SCORE_Y equ 3
MINE_Y equ 10 
gridX db 0
gridY db 0
WIDTH  equ 10
HEIGHT equ 7

grid db 70 dup(0)
seed dw 0
lives db 3           
score dw 0 
mine_count db 14 
backup dw 2000 dup(0)         

; CODE
; =======================

start:
    
    mov ah, 00h
    int 1Ah
    mov seed, dx
    mov ax, 0003h
    int 10h
    call place_mines
    call calc_numbers
    mov ax, 0B800h
    mov es, ax
    call draw_grid
    call draw_hearts
    call draw_hud_boxes
    call draw_controls 
    call update_score_display  
    call update_mine_display 
    push ds
    push es
    mov ax, 0B800h     
    mov ds, ax
    mov si, 0
    mov ax, cs         
    mov es, ax
    lea di, backup
    mov cx, 2000        
    rep movsw           
    pop es
    pop ds
    mov al, cursorX
    mov oldX, al
    mov al, cursorY
    mov oldY, al

main_loop:
    call get_input
    call update_cursor
    jmp main_loop

draw_grid:
    mov bx, 0

row_loop:
    mov cx, 0

col_loop:
   
    mov ah, 5Fh
    mov dh, bl
    add dh, Y_OFF
    mov dl, cl
    add dl, X_OFF
    call set_pos
    mov al, 218
    call write_char
    mov al, 196
    call write_char
    call write_char
    mov al, 191
    call write_char
    mov dh, bl
    inc dh
    add dh, Y_OFF
    mov dl, cl
    add dl, X_OFF
    call set_pos
    mov al, 179
    call write_char
    mov al, 219
    call write_char
    call write_char
    mov al, 179
    call write_char
    mov dh, bl
    add dh, 2
    add dh, Y_OFF
    mov dl, cl
    add dl, X_OFF
    call set_pos
    mov al, 192
    call write_char
    mov al, 196
    call write_char
    call write_char
    mov al, 217
    call write_char
    add cl, 4
    cmp cl, 40
    jl col_loop
    add bl, 3
    cmp bl, 21
    jl row_loop

    ret


get_input:
    mov ah, 00h
    int 16h
    cmp ah, 48h
    je move_up
    cmp ah, 50h
    je move_down
    cmp ah, 4Bh
    je move_left
    cmp ah, 4Dh
    je move_right
    cmp ah, 1Ch    
    je open_cell
    cmp al, 'f'
    je place_flag
    cmp al, 'F'
    je place_flag
    
    ret

move_up:
    cmp cursorY, 0
    je end_input
    sub cursorY, 3
    jmp end_input

move_down:
    cmp cursorY, 18
    je end_input
    add cursorY, 3
    jmp end_input

move_left:
    cmp cursorX, 0
    je end_input
    sub cursorX, 4
    jmp end_input

move_right:
    cmp cursorX, 36
    je end_input
    add cursorX, 4

end_input:
    ret

update_cursor:
    mov al, cursorX
    cmp al, oldX
    jne do_update
    mov al, cursorY
    cmp al, oldY
    jne do_update
    ret

do_update:
    mov al, oldX
    mov cl, al
    mov al, oldY
    mov bl, al
    call draw_cell_normal
    mov al, cursorX
    mov cl, al
    mov al, cursorY
    mov bl, al
    call draw_cell_highlight
    mov al, cursorX
    mov oldX, al
    mov al, cursorY
    mov oldY, al
    ret


draw_cell_normal:
    mov ah, 5Fh
    jmp draw_cell

draw_cell_highlight:
    mov ah, 07h

draw_cell:
    
    mov dh, bl
    add dh, Y_OFF
    mov dl, cl
    add dl, X_OFF
    call set_pos
    mov al, 218
    call write_char
    mov al, 196
    call write_char
    call write_char
    mov al, 191
    call write_char
    mov dh, bl
    inc dh
    add dh, Y_OFF
    mov dl, cl
    add dl, X_OFF
    call set_pos
    mov al, 179
    call write_char
    add di, 4        
    mov al, 179
    call write_char
    mov dh, bl
    add dh, 2
    add dh, Y_OFF
    mov dl, cl
    add dl, X_OFF
    call set_pos
    mov al, 192
    call write_char
    mov al, 196
    call write_char
    call write_char
    mov al, 217
    call write_char
    ret  
    
count_mines:
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov bp, 0              
    mov si, bx             
    mov ax, si
    mov cl, 10
    div cl                 
    mov ch, al            
    mov cl, ah             
    mov bl, 0              
loop_y:
    mov bh, 0              
loop_x:
   
    cmp bl, 1
    jne check_limits
    cmp bh, 1
    je next_sub_cell

check_limits:
    mov al, ch
    add al, bl
    dec al                 
    cmp al, HEIGHT
    jae next_sub_cell      
    mov dl, cl
    add dl, bh
    dec dl                 
    cmp dl, WIDTH
    jae next_sub_cell      
    mov dh, 10
    mul dh                
    add al, dl           
    mov di, ax
    and di, 00FFh         
    cmp grid[di], 9
    jne next_sub_cell      
    inc bp                 

next_sub_cell:
    inc bh
    cmp bh, 3
    jl loop_x             
    inc bl
    cmp bl, 3
    jl loop_y              
    mov ax, bp             
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
    
calc_numbers:
    push ax
    push bx
    push si
    mov bx, 0
calc_loop:
    cmp grid[bx], 9  
    je skip_calc
    call count_mines 
    mov grid[bx], al
    
skip_calc:
    inc bx
    cmp bx, 70
    jl calc_loop
    pop si
    pop bx
    pop ax
    ret 
    
random:
    push dx
    push bx
    mov ax, seed
    mov dx, 25173          
    mul dx
    add ax, 13849         
    mov seed, ax           
    pop bx
    pop dx
    ret

place_mines:
    push ax
    push bx
    push cx
    push dx
    push si
    mov cx, 14            

place_loop:
    call random            
    xor dx, dx
    mov bx, 70
    div bx                 
    mov si, dx
    cmp grid[si], 9        
    je place_loop          
    mov grid[si], 9
    loop place_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret   
set_pos:
    push ax
    push bx
    push cx
    mov ax, 0
    mov al, dh
    mov bl, 80
    mul bl 
    mov ch, 0
    mov cl, dl
    add ax, cx
    shl ax, 1
    mov di, ax
    pop cx
    pop bx
    pop ax
    ret

write_char:
    mov es:[di], al
    inc di
    mov es:[di], ah
    inc di
    ret

draw_hearts:
    mov cl, 0

heart_loop:
    mov al, cl
    mov bl, 3
    mul bl
    add al, HEART_Y
    mov dh, al
    mov dl, HEART_X
    call set_pos
    cmp cl, lives
    jl draw_h
    mov ah, 0Ch
    mov al, ' '
    jmp print_h

draw_h:
    mov ah, 0Ch      
    mov al, 03h      

print_h:
    call write_char
    inc cl
    cmp cl, 3
    jl heart_loop
    ret
draw_hud_boxes:

    mov dh, SCORE_Y
    mov dl, HUD_X
    call set_pos
    mov ah, 1Eh
    mov al, '['
    call write_char
    mov al, 'S'
    call write_char
    mov al, 'C'
    call write_char
    mov al, 'O'
    call write_char
    mov al, 'R'
    call write_char
    mov al, 'E'
    call write_char
    mov al, ']'
    call write_char
    mov dh, MINE_Y
    mov dl, HUD_X
    call set_pos
    mov ah, 1Eh
    mov al, '['
    call write_char
    mov al, 'M'
    call write_char
    mov al, 'A'
    call write_char
    mov al, 'Y'
    call write_char
    mov al, 'I'
    call write_char
    mov al, 'N'
    call write_char
    mov al, ']'
    call write_char

    ret 
    
draw_controls: 

    mov dh, MINE_Y
    add dh, 8        
    mov dl, HUD_X
    call set_pos
    mov ah, 0Ch      
    mov al, 16       
    call write_char
    mov ah, 0Fh     
    mov al, ' '
    call write_char
    mov al, 'F'
    call write_char
    mov dh, MINE_Y
    add dh, 10
    mov dl, HUD_X
    call set_pos
    mov ah, 0Fh     
    mov al, 219
    call write_char
    mov al, ' '
    call write_char
    mov al, 'E'
    call write_char
    mov al, 'N'
    call write_char
    mov al, 'T'
    call write_char
    mov al, 'E'
    call write_char
    mov al, 'R'
    call write_char

    ret
    
get_grid_pos:
    
    mov ax, 0
    mov al, cursorX
    mov bl, 4
    div bl
    mov gridX, al
    mov ax, 0
    mov al, cursorY
    mov bl, 3
    div bl
    mov gridY, al 
    
    ret 

open_cell:
    call get_grid_pos   

    mov ax, 0
    mov al, gridY
    mov bl, WIDTH
    mul bl
    mov bx, 0
    mov bl, gridX
    add ax, bx
    mov si, ax
    mov al, gridY
    mov bl, 3
    mul bl
    mov dh, al
    inc dh              
    add dh, Y_OFF       
    mov al, gridX
    mov bl, 4
    mul bl
    mov dl, al
    inc dl              
    add dl, X_OFF       
    call set_pos
    mov al, es:[di]
    cmp al, 219
    jne skip_open       
    cmp grid[si], 9
    je boom            
    mov ch, gridY
    mov cl, gridX
    call open_recursive

skip_open:
    ret

open_recursive:
    cmp ch, 0
    jl open_rec_end
    cmp ch, HEIGHT
    jge open_rec_end
    cmp cl, 0
    jl open_rec_end
    cmp cl, WIDTH
    jge open_rec_end
    
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov al, ch
    mov bl, WIDTH
    mul bl
    add al, cl
    mov ah, 0
    mov si, ax
    mov al, ch
    mov bl, 3
    mul bl
    mov dh, al
    inc dh
    add dh, Y_OFF
    mov al, cl
    mov bl, 4
    mul bl
    mov dl, al
    inc dl
    add dl, X_OFF
    call set_pos
    mov al, es:[di]
    cmp al, 219
    jne open_rec_pop         
    cmp grid[si], 9
    je open_rec_pop          
    add score, 50
    call update_score_display
    mov al, grid[si]
    cmp al, 0
    je ff_num_0
    cmp al, 1
    je ff_num_1
    cmp al, 2
    je ff_num_2
    cmp al, 3
    je ff_num_3
    mov ah, 74h
    add al, 30h
    jmp ff_draw_num

ff_num_0:
    mov ah, 70h         
    mov al, ' '         
    jmp ff_draw_num
ff_num_1:
    mov ah, 79h         
    mov al, '1'
    jmp ff_draw_num
ff_num_2:
    mov ah, 72h         
    mov al, '2'
    jmp ff_draw_num
ff_num_3:
    mov ah, 7Eh         
    mov al, '3'
    jmp ff_draw_num

ff_draw_num:
    push ax
    mov al, ch
    mov bl, 3
    mul bl
    mov dh, al
    inc dh              
    add dh, Y_OFF       
    mov al, cl
    mov bl, 4
    mul bl
    mov dl, al
    inc dl              
    add dl, X_OFF       
    call set_pos
    mov ah, 70h         
    mov al, ' '         
    call write_char
    pop ax              
    call write_char     
    cmp grid[si], 0
    jne open_rec_pop
    dec ch
    call open_recursive
    inc ch
    inc ch
    call open_recursive
    dec ch
    dec cl
    call open_recursive
    inc cl
    inc cl
    call open_recursive
    dec cl
    dec ch
    dec cl
    call open_recursive
    inc cl
    inc ch
    dec ch
    inc cl
    call open_recursive
    dec cl
    inc ch
    inc ch
    dec cl
    call open_recursive
    inc cl
    dec ch
    inc ch
    inc cl
    call open_recursive
    dec cl
    dec ch

open_rec_pop:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
open_rec_end:
    ret
    
place_flag:
    mov dh, cursorY
    inc dh              
    add dh, Y_OFF       
    mov dl, cursorX
    inc dl             
    add dl, X_OFF      
    call set_pos       
    mov al, es:[di]     
    mov ah, es:[di+2]   
    cmp ah, 16
    je remove_flag      
    cmp al, 219
    jne skip_flag      

do_flag:
    mov ah, 7Ch         
    mov al, ' '         
    call write_char
    mov al, 16          
    call write_char
    dec mine_count     
    call update_mine_display
    cmp mine_count, 0
    jne skip_win_check   
    call check_win_condition 
    cmp al, 1               
    je game_win             

skip_win_check:
    jmp skip_flag
    
skip_flag:
    ret

remove_flag:
    mov ah, 0Fh         
    mov al, 219         
    call write_char
    mov al, 219         
    call write_char
    inc mine_count      
    call update_mine_display
    ret
    
boom:
    
    dec lives           
    sub score, 100      
    call draw_hearts    
    call update_score_display
    dec mine_count      
    call update_mine_display
    push ax             
    push bx
    push dx
    mov ax, si
    mov bl, 10
    div bl             
    mov bh, ah          
    mov ah, 0           
    mov bl, 3
    mul bl
    mov dh, al
    inc dh              
    add dh, Y_OFF       
    mov al, bh          
    mov bl, 4
    mul bl
    mov dl, al
    inc dl              
    add dl, X_OFF       
    call set_pos
    mov ah, 74h         
    mov al, ' '         
    call write_char
    mov al, 15          
    call write_char
    pop dx
    pop bx
    pop ax              
    cmp lives, 0
    jle game_over_reveal 
    cmp mine_count, 0
    jne skip_boom_win_check
    call check_win_condition
    cmp al, 1
    je game_win

skip_boom_win_check:
    ret
                   
game_over_reveal:
    mov cx, 0           

boom_loop:
    mov si, cx
    cmp grid[si], 9
    jne next_boom
    mov ax, si
    mov bl, 10
    div bl
    mov bh, ah
    mov ah, 0           
    mov bl, 3
    mul bl
    mov dh, al
    inc dh
    add dh, Y_OFF       
    mov al, bh
    mov bl, 4
    mul bl
    mov dl, al
    inc dl
    add dl, X_OFF       
    call set_pos
    mov ah, 70h         
    mov al, ' '         
    call write_char
    mov al, 15          
    call write_char

next_boom:
    inc cx
    cmp cx, 70
    jl boom_loop
    mov dh, 14          
    mov dl, 4
    call set_pos
    mov ah, 0Fh         
    mov al, 'G'
    call write_char
    mov al, 'A'
    call write_char
    mov al, 'M'
    call write_char
    mov al, 'E'
    call write_char
    mov al, ' '
    call write_char
    mov al, 'O'
    call write_char
    mov al, 'V'
    call write_char
    mov al, 'E'
    call write_char
    mov al, 'R'
    call write_char
    mov al, '!'
    call write_char 
    jmp print_restart_prompt 

game_win:
    mov dh, 14          
    mov dl, 4
    call set_pos
    mov ah, 0Ah         
    mov al, 'Y'
    call write_char
    mov al, 'O'
    call write_char
    mov al, 'U'
    call write_char
    mov al, ' '
    call write_char
    mov al, 'W'
    call write_char
    mov al, 'I'
    call write_char
    mov al, 'N'
    call write_char
    mov al, '!'
    call write_char
    mov al, ' '
    call write_char
    mov al, 1           
    call write_char

check_win_condition:
    push bx
    push cx
    push dx
    push si
    push di
    mov cx, 0 
    
win_check_loop:

    mov si, cx
    cmp grid[si], 9         
    jne check_next_win_cell 
    mov ax, si
    mov bl, 10
    div bl                  
    mov bh, ah              
    mov ah, 0
    mov bl, 3
    mul bl
    mov dh, al
    inc dh
    add dh, Y_OFF
    mov al, bh
    mov bl, 4
    mul bl
    mov dl, al
    inc dl
    add dl, X_OFF
    call set_pos
    mov al, es:[di+2]       
    cmp al, 16            
    je check_next_win_cell  
    cmp al, 15             
    je check_next_win_cell  
    mov al, 0              
    jmp end_win_check

check_next_win_cell:
    inc cx
    cmp cx, 70
    jl win_check_loop
    mov al, 1 
                  
end_win_check:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
    
print_restart_prompt: 

    mov dh, HEART_Y
    mov dl, HEART_X
    call set_pos
    mov ah, 0Fh
    mov al, 'R'
    call write_char
    mov al, 'E'
    call write_char
    mov al, 'S'
    call write_char
    mov al, 'T'
    call write_char
    mov al, 'A'
    call write_char
    mov al, 'R'
    call write_char
    mov al, 'T'
    call write_char
    mov al, '['
    call write_char
    mov ah, 0Ch               
    mov al, 'R'
    call write_char
    mov ah, 0Fh
    mov al, ']'
    call write_char
   
wait_for_restart:
    mov ah, 00h
    int 16h
    cmp al, 'r'
    je execute_restart
    cmp al, 'R'
    je execute_restart
    jmp wait_for_restart
     
    
execute_restart:
    mov lives, 3
    mov score, 0
    mov mine_count, 14
    mov cx, 70
    mov bx, 0 
     
clear_memory_loop:
    mov grid[bx], 0
    inc bx
    loop clear_memory_loop
    call place_mines
    call calc_numbers
    push ds
    push es
    mov ax, cs          
    mov ds, ax
    lea si, backup
    mov ax, 0B800h      
    mov es, ax
    mov di, 0
    mov cx, 2000
    rep movsw         
    pop es
    pop ds
    mov cursorX, 0
    mov cursorY, 0
    mov oldX, 0
    mov oldY, 0
    jmp main_loop    
    
update_score_display:
    push ax
    push bx
    push cx
    push dx
    mov dh, SCORE_Y
    add dh, 2
    mov dl, HUD_X
    add dl, 2
    call set_pos
    mov ax, score
    cmp ax, 0
    jge score_ok
    mov ax, 0         
    mov score, 0
    
score_ok:
    
    xor dx, dx         
    mov cx, 1000
    div cx             
    add al, 30h
    mov ah, 0Ch        
    call write_char
    mov ax, dx         
    xor dx, dx         
    mov cx, 100
    div cx
    add al, 30h
    mov ah, 0Ch
    call write_char
    mov ax, dx
    xor dx, dx
    mov cx, 10
    div cx
    add al, 30h
    mov ah, 0Ch
    call write_char
    mov ax, dx
    add al, 30h
    mov ah, 0Ch
    call write_char
    pop dx
    pop cx
    pop bx
    pop ax
    ret

update_mine_display:
    push ax
    push bx
    push dx
    mov dh, MINE_Y
    add dh, 2
    mov dl, HUD_X
    add dl, 2
    call set_pos
    mov al, mine_count
    cmp al, 0
    jge mine_ok
    mov al, 0
    
mine_ok:
    xor ah, ah         
    mov bl, 10
    div bl            
    mov bx, ax         
    mov ah, 0Ch
    add al, 30h
    call write_char     
    mov al, bh          
    add al, 30h
    call write_char                                                     
    pop dx
    pop bx
    pop ax
    ret 
	AREA data, DATA, READWRITE
		
unsorted_list 	DCD 3,1,6,5,2,4,NEGMAXINT 	; Define unsorted list of integers, terminated by negative max int (NEGMAXINT)
sorted_list 	SPACE 24 								; Allocate space for the result sorted list (10 32bit integers)
NEGMAXINT 		EQU 0x80000001 							; Define negative maximum integer value
HEAP_BASE 		SPACE 24 								; Allocate space for heap base address (10 32bit integers)
HEAP_CAPACITY 	EQU 24 									; Define heap capacity (10 32bit integers)
	
	AREA Nouredeen_HAMMAD, CODE, READONLY
	
		ENTRY
		EXPORT main
		
; Main function to test the procedures
main	PROC	
		ldr r0, =unsorted_list 		; Load address of unsorted list
		ldr r1, =HEAP_BASE 			; Load address of heap base
		bl build					; Call build procedure to construct a min-heap from the unsorted list
		
		; Testing the find procedure
		mov r0, #10				 	; Set target value to find
		ldr r1, =HEAP_BASE			; Load address of heap base A[0]
		;add r1, r1, #4				; Move to address of A[1], the first real element
		bl find						; Call find procedure
		
		; Testing the sort procedure
		ldr r1, =HEAP_BASE			; Load address of heap base
		ldr r0, [r1]				; Load heap size (value)
		add r1, r1, #4				; Move to address of A[1], the first real element
		ldr r2, =sorted_list		; Load address of (currently empty) sorted list
		bl sort						; Call the sort procedure
		
final	b final						; Program finished
		

; 1- BUILD
; Parameters (r0 = List, r1 = Heap)
; Procedure to construct a min-heap data structure from a list of integers
build		ldr r2, [r0], #4        ; Load the first integer from the list
			mov r3, #0              ; Initialize heap size to 0
			str r3, [r1]            ; Store heap size at heap address (A[0])
			
			ldr r4, =NEGMAXINT		; Load NEGMAXINT
			cmp r2, r4        		; Check if the current integer equals NEGMAXINT
			beq build_done          ; If yes, terminate the build process			
			push {lr}				; Push the link register value onto the stack to store it
			
build_loop	bl heap_insert          ; Insert the integer into the heap
			ldr r2, [r0], #4        ; Load the next integer from the list
			ldr r4, =NEGMAXINT		; Load NEGMAXINT
			cmp r2, r4         		; Check if the current integer equals NEGMAXINT
			bne build_loop          ; If not, continue inserting integers into the heap
			
build_done	mov r0, r1              ; Return the address of the heap into r0
			pop {lr}				; Pop the previously stored link register value
			bx lr					; Branch exchange back to main function


;2- FIND
; Parameters (r0 = Target, r1 = Heap)
; Find a target value in the min-heap
find    	mov r2, #0              ; Initialize search result to 0
			mov r3, #0              ; Initialize index to 1 (start from root)	
			ldr r5, [r1], #4		; Store the size of the heap
			
find_loop	cmp r5, r3              ; Check if reached the end of the heap
			beq find_exit           ; If yes, exit the loop
			ldr r4, [r1], #4        ; Load value of the current node
			cmp r4, r0              ; Compare current node value with the target value
			moveq r2, #1            ; If equal, set search result to 1 (found)
			addeq r1, r1, #-4       ; If equal, store address of the current node in r1
			add r3, r3, #1          ; Increment index
			b find_loop             ; Repeat the loop
			
find_exit   mov r0, r2              ; Store search result in r0
			bx lr					; Branch exchange back to main function
 
 
;3- SORT
; Parameters (r0 = heap, r1 = heap size, r2 = sorted list address)
; Sort the elements of the min-heap in ascending order
sort		push {lr}				; Push the link register value onto the stack to store it
sort_loop	bl extract_min			; Extract the minimum element from the heap (into r0)
			str r0, [r2]			; Store the extracted element in the sorted list
			
			add r2, r2, #4			; Move to the next position in the sorted list
			ldr r0, =HEAP_BASE		; Load heap base
			ldr r0, [r0]			; Load heap size value
			cmp r0, #0				; Check if the heap is empty (size = 0)
			beq sort_done			; Exits the loop if the heap is empty
			b sort_loop				; Repeats the loop if the heap is not empty
			
sort_done	pop {lr}				; Pop the previously stored link register value
			ldr r0, =sorted_list	; Load the address of the sorted list into r0 to return it
			bx lr					; Branch exchange back to main function
	
	
; Insert new value into heap
heap_insert	ldr r6, =HEAP_CAPACITY    	; Load heap capacity
			ldr r12, [r1]               ; Load heap size value
			
			; Check if heap is full
			cmp r12, r6                 ; Compare heap size with heap capacity
			bge heap_full               ; If heap is full, exit

			; Increment heap size
			add r12, r12, #1
			str r12, [r1]

			; Insert the new element at the end of the heap
			add r5, r1, r12, LSL #2   	; Calculate address of the new element
			str r2, [r5]                ; Store the new element

			; Heapify up
			mov r6, r12                 ; Initialize index of the inserted element
			mov r7, r6, ASR #1         	; Calculate parent index
			cmp r7, #0                  ; Check if the inserted element is the first element
			beq heapify_up_done        	; If yes, skip heapify-up

heapify_up_loop	cmp r6, #1                  ; Check if reached the root
				ble heapify_up_done         ; If inserted element is at the root, break the loop

				ldr r8, [r1, r6, LSL #2]   	; Load value of the inserted element
				ldr r9, [r1, r7, LSL #2]   	; Load value of the parent element
				cmp r8, r9                  ; Compare inserted element with parent element
				bge heapify_up_done         ; If inserted element is greater than or equal to parent element, break the loop

				; Swap elements
				str r9, [r1, r6, LSL #2]    ; Store parent element at the index of inserted element
				str r8, [r1, r7, LSL #2]    ; Store inserted element at the index of parent element

				; Update indices
				mov r6, r7                  ; Update index of inserted element
				mov r7, r6, ASR #1          ; Calculate new parent index
				b heapify_up_loop           ; Repeat the loop

heapify_up_done	bx lr		                ; Branch exchange back to heap_insert function


heap_full		mov r0, #0                 	; Return null pointer to indicate failure
				bx lr                      	; Branch exchange back to heap_insert function
			
; Returns the root of the heap to r0
extract_min    	; R0 = size (val)
				ldr r1, =HEAP_BASE
				ldr r3, [r1]
				
				; Check if the heap is empty
				cmp r0, #0
				beq heap_empty
				
				; Load the root element (minimum element)
				ldr r0, [r1, #4]   						; Load the value at A[1] (root)

				; Replace the root element with the last element
				ldr r4, [r1, r3, LSL #2]   				; Load the value of the last element
				str r4, [r1, #4]           				; Store the last element at the root position
				mov r5, #0
				str r5, [r1, r3, LSL #2]

				; Decrement heap size
				sub r3, r3, #1
				str r3, [r1]

				; Heapify down from the root
				mov r5, #1                				; Initialize index of the root
				mov r6, #2                				; Initialize index of the left child
				mov r7, #3                				; Initialize index of the right child

heapify_down_loop	cmp r6, r3 							; Check if left child exists
					bgt heapify_down_done   			; If left child does not exist, break the loop

					; Determine the index of the smaller child
					ldr r8, [r1, r6, LSL #2]   			; Load the value of the left child
					ldr r9, [r1, r7, LSL #2]   			; Load the value of the right child
					cmp r7, r3                 			; Check if right child exists
					ble check_right_child
					mov r7, r6                 			; If right child does not exist, choose left child as the smaller child
					b check_smaller_child

; Check if the right child is smaller than the left child
check_right_child		cmp r8, r9
						bge check_smaller_child    		; If the right child is smaller, choose it as the smaller child
						mov r7, r6                 		; Otherwise, choose the left child as the smaller child

; Compare the smaller child with the parent
check_smaller_child		ldr r10, [r1, r5, LSL #2]  		; Load the value of the parent
						ldr r11, [r1, r7, LSL #2]  		; Load the value of the smaller child
						cmp r10, r11
						ble heapify_down_done      		; If the parent is smaller than or equal to the smaller child, break the loop

						; Swap elements
						str r11, [r1, r5, LSL #2]  		; Store the smaller child at the parent position
						str r10, [r1, r7, LSL #2]  		; Store the parent at the smaller child position

						; Update indices for the next iteration
						mov r5, r7
						add r6, r5, r5             		; Calculate the index of the left child
						add r7, r6, #1             		; Calculate the index of the right child
						b heapify_down_loop        		; Repeat the loop

heapify_down_done	    bx lr							; Branch exchange back to extract_min function

heap_empty			    mov r0, #0                 		; Return null pointer to indicate heap is empty
						bx lr							; Branch exchange back to extract_min function
	
	ENDP
	END
	.text
start:
	# perform whatever setup we need
	mv	x1, x0
	mv	x3, x0	
	mv	x4, x0	
	mv	x5, x0	
	mv	x6, x0	
	mv	x7, x0	
	mv	x8, x0	
	mv	x9, x0	
	mv	x10, x0
	mv	x11, x0	
	mv	x12, x0	
	mv	x13, x0	
	mv	x14, x0	
	mv	x15, x0	
	mv	x16, x0	
	mv	x17, x0	
	mv	x18, x0	
	mv	x19, x0	
	mv	x20, x0
	mv	x21, x0	
	mv	x22, x0	
	mv	x23, x0	
	mv	x24, x0	
	mv	x25, x0	
	mv	x26, x0	
	mv	x27, x0	
	mv	x28, x0	
	mv	x29, x0
	mv	x30, x0
	mv	x31, x0
	
	# zero the bss
	la	t0, _bssstart
	# la	t1, _bssend
	mv	t1, x2
	beq	t0,t1,.endlp
.lp:
	sw	x0,0(t0)
	addi	t0,t0,4
	bne	t0,t1,.lp
.endlp:
	
	# call main
	call	main

	# now hang
done:
	j	done

	


hello.mips:     file format elf32-tradbigmips


Disassembly of section .init:

004003e4 <_init>:
  4003e4:	3c1c0002 	lui	gp,0x2
  4003e8:	279c838c 	addiu	gp,gp,-31860
  4003ec:	0399e021 	addu	gp,gp,t9
  4003f0:	27bdffe0 	addiu	sp,sp,-32
  4003f4:	afbf001c 	sw	ra,28(sp)
  4003f8:	afbc0010 	sw	gp,16(sp)
  4003fc:	8f828034 	lw	v0,-32716(gp)
  400400:	10400003 	beqz	v0,400410 <_init+0x2c>
  400404:	8f998034 	lw	t9,-32716(gp)
  400408:	0320f809 	jalr	t9
  40040c:	00000000 	nop
  400410:	04110001 	bal	400418 <_init+0x34>
  400414:	00000000 	nop
  400418:	0c10014f 	jal	40053c <frame_dummy>
  40041c:	00000000 	nop
  400420:	04110001 	bal	400428 <_init+0x44>
  400424:	00000000 	nop
  400428:	0c1001a4 	jal	400690 <__do_global_ctors_aux>
  40042c:	00000000 	nop
  400430:	8fbf001c 	lw	ra,28(sp)
  400434:	03e00008 	jr	ra
  400438:	27bd0020 	addiu	sp,sp,32

Disassembly of section .text:

00400440 <__start>:
  400440:	03e00021 	move	zero,ra
  400444:	04110001 	bal	40044c <__start+0xc>
  400448:	00000000 	nop
  40044c:	3c1c0042 	lui	gp,0x42
  400450:	279c8770 	addiu	gp,gp,-30864
  400454:	0000f821 	move	ra,zero
  400458:	8f848018 	lw	a0,-32744(gp)
  40045c:	8fa50000 	lw	a1,0(sp)
  400460:	27a60004 	addiu	a2,sp,4
  400464:	2401fff8 	li	at,-8
  400468:	03a1e824 	and	sp,sp,at
  40046c:	27bdffe0 	addiu	sp,sp,-32
  400470:	8f87801c 	lw	a3,-32740(gp)
  400474:	8f888020 	lw	t0,-32736(gp)
  400478:	afa80010 	sw	t0,16(sp)
  40047c:	afa20014 	sw	v0,20(sp)
  400480:	afbd0018 	sw	sp,24(sp)
  400484:	8f998030 	lw	t9,-32720(gp)
  400488:	0320f809 	jalr	t9
  40048c:	00000000 	nop

00400490 <hlt>:
  400490:	1000ffff 	b	400490 <hlt>
  400494:	00000000 	nop
	...

004004a0 <__do_global_dtors_aux>:
  4004a0:	27bdffd0 	addiu	sp,sp,-48
  4004a4:	afb30028 	sw	s3,40(sp)
  4004a8:	3c130041 	lui	s3,0x41
  4004ac:	926207b0 	lbu	v0,1968(s3)
  4004b0:	afbf002c 	sw	ra,44(sp)
  4004b4:	afb20024 	sw	s2,36(sp)
  4004b8:	afb10020 	sw	s1,32(sp)
  4004bc:	14400018 	bnez	v0,400520 <__do_global_dtors_aux+0x80>
  4004c0:	afb0001c 	sw	s0,28(sp)
  4004c4:	3c120041 	lui	s2,0x41
  4004c8:	3c110041 	lui	s1,0x41
  4004cc:	26520754 	addiu	s2,s2,1876
  4004d0:	3c100041 	lui	s0,0x41
  4004d4:	26310758 	addiu	s1,s1,1880
  4004d8:	02328823 	subu	s1,s1,s2
  4004dc:	8e0207b4 	lw	v0,1972(s0)
  4004e0:	00118883 	sra	s1,s1,0x2
  4004e4:	2631ffff 	addiu	s1,s1,-1
  4004e8:	0051182b 	sltu	v1,v0,s1
  4004ec:	1060000a 	beqz	v1,400518 <__do_global_dtors_aux+0x78>
  4004f0:	24420001 	addiu	v0,v0,1
  4004f4:	00021880 	sll	v1,v0,0x2
  4004f8:	02431821 	addu	v1,s2,v1
  4004fc:	8c790000 	lw	t9,0(v1)
  400500:	0320f809 	jalr	t9
  400504:	ae0207b4 	sw	v0,1972(s0)
  400508:	8e0207b4 	lw	v0,1972(s0)
  40050c:	0051182b 	sltu	v1,v0,s1
  400510:	1460fff8 	bnez	v1,4004f4 <__do_global_dtors_aux+0x54>
  400514:	24420001 	addiu	v0,v0,1
  400518:	24020001 	li	v0,1
  40051c:	a26207b0 	sb	v0,1968(s3)
  400520:	8fbf002c 	lw	ra,44(sp)
  400524:	8fb30028 	lw	s3,40(sp)
  400528:	8fb20024 	lw	s2,36(sp)
  40052c:	8fb10020 	lw	s1,32(sp)
  400530:	8fb0001c 	lw	s0,28(sp)
  400534:	03e00008 	jr	ra
  400538:	27bd0030 	addiu	sp,sp,48

0040053c <frame_dummy>:
  40053c:	3c040041 	lui	a0,0x41
  400540:	8c82075c 	lw	v0,1884(a0)
  400544:	10400006 	beqz	v0,400560 <frame_dummy+0x24>
  400548:	3c190000 	lui	t9,0x0
  40054c:	27390000 	addiu	t9,t9,0
  400550:	13200003 	beqz	t9,400560 <frame_dummy+0x24>
  400554:	00000000 	nop
  400558:	03200008 	jr	t9
  40055c:	2484075c 	addiu	a0,a0,1884
  400560:	03e00008 	jr	ra
  400564:	00000000 	nop
	...

00400570 <main>:
  400570:	27bdffe8 	addiu	sp,sp,-24
  400574:	afbe0014 	sw	s8,20(sp)
  400578:	03a0f021 	move	s8,sp
  40057c:	afc40018 	sw	a0,24(s8)
  400580:	afc5001c 	sw	a1,28(s8)
  400584:	afc0000c 	sw	zero,12(s8)
  400588:	afc00008 	sw	zero,8(s8)
  40058c:	0810016c 	j	4005b0 <main+0x40>
  400590:	00000000 	nop
  400594:	8fc30008 	lw	v1,8(s8)
  400598:	8fc2000c 	lw	v0,12(s8)
  40059c:	00621021 	addu	v0,v1,v0
  4005a0:	afc20008 	sw	v0,8(s8)
  4005a4:	8fc2000c 	lw	v0,12(s8)
  4005a8:	24420001 	addiu	v0,v0,1
  4005ac:	afc2000c 	sw	v0,12(s8)
  4005b0:	8fc2000c 	lw	v0,12(s8)
  4005b4:	28420064 	slti	v0,v0,100
  4005b8:	1440fff6 	bnez	v0,400594 <main+0x24>
  4005bc:	00000000 	nop
  4005c0:	8fc20008 	lw	v0,8(s8)
  4005c4:	03c0e821 	move	sp,s8
  4005c8:	8fbe0014 	lw	s8,20(sp)
  4005cc:	27bd0018 	addiu	sp,sp,24
  4005d0:	03e00008 	jr	ra
  4005d4:	00000000 	nop
	...

004005e0 <__libc_csu_fini>:
  4005e0:	03e00008 	jr	ra
  4005e4:	00000000 	nop

004005e8 <__libc_csu_init>:
  4005e8:	3c1c0002 	lui	gp,0x2
  4005ec:	279c8188 	addiu	gp,gp,-32376
  4005f0:	0399e021 	addu	gp,gp,t9
  4005f4:	27bdffc8 	addiu	sp,sp,-56
  4005f8:	afbf0034 	sw	ra,52(sp)
  4005fc:	afb50030 	sw	s5,48(sp)
  400600:	afb4002c 	sw	s4,44(sp)
  400604:	afb30028 	sw	s3,40(sp)
  400608:	afb20024 	sw	s2,36(sp)
  40060c:	afb10020 	sw	s1,32(sp)
  400610:	afb0001c 	sw	s0,28(sp)
  400614:	afbc0010 	sw	gp,16(sp)
  400618:	8f998024 	lw	t9,-32732(gp)
  40061c:	00809821 	move	s3,a0
  400620:	00a0a021 	move	s4,a1
  400624:	0320f809 	jalr	t9
  400628:	00c0a821 	move	s5,a2
  40062c:	8fbc0010 	lw	gp,16(sp)
  400630:	8f918028 	lw	s1,-32728(gp)
  400634:	8f928028 	lw	s2,-32728(gp)
  400638:	02519023 	subu	s2,s2,s1
  40063c:	00129083 	sra	s2,s2,0x2
  400640:	1240000a 	beqz	s2,40066c <__libc_csu_init+0x84>
  400644:	00008021 	move	s0,zero
  400648:	8e390000 	lw	t9,0(s1)
  40064c:	26100001 	addiu	s0,s0,1
  400650:	02602021 	move	a0,s3
  400654:	02802821 	move	a1,s4
  400658:	0320f809 	jalr	t9
  40065c:	02a03021 	move	a2,s5
  400660:	0212102b 	sltu	v0,s0,s2
  400664:	1440fff8 	bnez	v0,400648 <__libc_csu_init+0x60>
  400668:	26310004 	addiu	s1,s1,4
  40066c:	8fbf0034 	lw	ra,52(sp)
  400670:	8fb50030 	lw	s5,48(sp)
  400674:	8fb4002c 	lw	s4,44(sp)
  400678:	8fb30028 	lw	s3,40(sp)
  40067c:	8fb20024 	lw	s2,36(sp)
  400680:	8fb10020 	lw	s1,32(sp)
  400684:	8fb0001c 	lw	s0,28(sp)
  400688:	03e00008 	jr	ra
  40068c:	27bd0038 	addiu	sp,sp,56

00400690 <__do_global_ctors_aux>:
  400690:	3c020041 	lui	v0,0x41
  400694:	8c59074c 	lw	t9,1868(v0)
  400698:	27bdffd8 	addiu	sp,sp,-40
  40069c:	2402ffff 	li	v0,-1
  4006a0:	afbf0024 	sw	ra,36(sp)
  4006a4:	afb10020 	sw	s1,32(sp)
  4006a8:	13220009 	beq	t9,v0,4006d0 <__do_global_ctors_aux+0x40>
  4006ac:	afb0001c 	sw	s0,28(sp)
  4006b0:	3c100041 	lui	s0,0x41
  4006b4:	2610074c 	addiu	s0,s0,1868
  4006b8:	2411ffff 	li	s1,-1
  4006bc:	0320f809 	jalr	t9
  4006c0:	2610fffc 	addiu	s0,s0,-4
  4006c4:	8e190000 	lw	t9,0(s0)
  4006c8:	1731fffc 	bne	t9,s1,4006bc <__do_global_ctors_aux+0x2c>
  4006cc:	00000000 	nop
  4006d0:	8fbf0024 	lw	ra,36(sp)
  4006d4:	8fb10020 	lw	s1,32(sp)
  4006d8:	8fb0001c 	lw	s0,28(sp)
  4006dc:	03e00008 	jr	ra
  4006e0:	27bd0028 	addiu	sp,sp,40
	...

Disassembly of section .MIPS.stubs:

004006f0 <.MIPS.stubs>:
  4006f0:	8f998010 	lw	t9,-32752(gp)
  4006f4:	03e07821 	move	t7,ra
  4006f8:	0320f809 	jalr	t9
  4006fc:	24180008 	li	t8,8
	...

Disassembly of section .fini:

00400710 <_fini>:
  400710:	3c1c0002 	lui	gp,0x2
  400714:	279c8060 	addiu	gp,gp,-32672
  400718:	0399e021 	addu	gp,gp,t9
  40071c:	27bdffe0 	addiu	sp,sp,-32
  400720:	afbf001c 	sw	ra,28(sp)
  400724:	afbc0010 	sw	gp,16(sp)
  400728:	04110001 	bal	400730 <_fini+0x20>
  40072c:	00000000 	nop
  400730:	0c100128 	jal	4004a0 <__do_global_dtors_aux>
  400734:	00000000 	nop
  400738:	8fbf001c 	lw	ra,28(sp)
  40073c:	03e00008 	jr	ra
  400740:	27bd0020 	addiu	sp,sp,32

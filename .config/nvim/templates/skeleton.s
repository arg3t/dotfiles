#
# [:VIM_EVAL:]expand('%:t')[:END_EVAL:]
# [:VIM_EVAL:]expand('%:p:h:t')[:END_EVAL:]
#
# Created by Yigit Colakoglu on [:VIM_EVAL:]strftime('%m/%d/%y')[:END_EVAL:].
# Copyright [:VIM_EVAL:]strftime('%Y')[:END_EVAL:]. Yigit Colakoglu. All rights reserved.
#

# ************************************************
# * Program: <PROGRAM_NAME>                      *
# * Description: <PROGRAM_DESCRIPTION>           *
# ************************************************

.text


.global main

main:
  # prologue
  pushq %rbp
  movq %rsp, %rbp 


  # epilogue
  movq %rbp, $rsp
  popq %rbp

end:
  movq $0, %rdi # Return code 0
  call exit

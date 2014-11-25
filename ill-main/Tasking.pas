{ "Internal MultiTasking Unit" - 1997 Mag69. Private use on Illusion BBS!

    To add a new procedure just go "AddTask(procedure_name, stack);"
    Example :
                      AddTask(UpdateTime, 1024);

    now assuming "UpdateTime" is a procedure to get the system time, your
    program will switch between Tasks and do whatever is nessesary. To
    keep the UpdateTime procedure going, you need to use the Repeat-Until
    on the procedure.

    Procedure UpdateTime;
    Var
     H,M,S,Hund : Word;
    Begin
     Repeat
      GetTime(H,M,S,Hund);
      WriteLn(H,':',M,':',S,':',Hund);
      Transfer;
     Until False;
    End;

    Or to call the process one time just remove the Repeat-Until. You must
    also call the "Transfer;" function in your Procedure to allow other
    procedures to run at the same time...
}
{G+}
Unit tasking;
Interface
Type
 StartProc = Procedure;
Procedure AddTask (Start:StartProc;StackSize:Word);
Procedure Transfer;
Implementation
Uses DOS;
Type
 TaskPtr = ^TaskRec;
 TaskRec =  Record
 StackSize : Word;
 Stack     : Pointer;
 SPSave    : Word;
 SSSave    : Word;
 BPSave    : Word;
 Next      : TaskPtr;
End;
Const
 MinStack = 1024;
 MaxStack = 32768;
Var
 Tasks    : TaskPtr;
 AktTask  : TaskPtr;
 OldExit  : Pointer;
Procedure AddTask (Start:StartProc;StackSize:Word);
Type
 OS = Record
 O,S : Word;
End;
Var
 W  : ^TaskPtr;
 SS : Word;
 SP : Word;
Begin
 W := @Tasks;
 While Assigned (W^) Do W := @W^^.Next;
 New (W^);
 If (StackSize<MinStack) Then StackSize := MinStack;
 If (StackSize>MaxStack) Then StackSize := MaxStack;
 W^^.StackSize := StackSize;
 GetMem (W^^.Stack,StackSize);
 SS := OS(W^^.Stack).S;
 SP := OS(W^^.Stack).O+StackSize-4;
 Move(Start,Ptr(SS,SP)^,4);
 W^^.SPSave := SP;
 W^^.SSSave := SS;
 W^^.BPSave := W^^.SPSave;
 W^^.Next := Nil;
End;
Procedure Transfer; Assembler;
Asm
 LES SI,AktTask
 MOV ES:[SI].TaskRec.SPSave,SP
 MOV ES:[SI].TaskRec.SSSave,SS
 MOV ES:[SI].TaskRec.BPSave,BP
 MOV AX,Word Ptr ES:[SI].TaskRec.Next
 OR  AX,Word Ptr ES:[SI].TaskRec.Next+2
 JE  @InitNew
 LES SI,ES:[SI].TaskRec.Next
 JMP @DoJob
@InitNew:
 LES SI,Tasks
@DoJob:
 MOV Word Ptr AktTask,SI
 MOV Word Ptr AktTask+2,ES
 CLI
 MOV SP,ES:[SI].TaskRec.SPSave
 MOV SS,ES:[SI].TaskRec.SSSave
 STI
 MOV BP,ES:[SI].TaskRec.BPSave
End;
Begin
 New (Tasks);
 Tasks^.StackSize := 0;
 Tasks^.Stack := Nil;
 Tasks^.Next := Nil;
 AktTask := Tasks;
End.

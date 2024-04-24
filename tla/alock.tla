---- MODULE alock ----
EXTENDS Integers, Sequences, TLC
CONSTANTS NumProcesses, InitialBudget
ASSUME NumProcesses > 0
ASSUME InitialBudget > 0
NP == NumProcesses
B == InitialBudget

(*--algorithm alock
variables 
    (* Global *)
    victim \in {1, 2},
    cohort = [x \in {1, 2} |-> 0],
    descriptor = [x \in ProcSet |-> [budget |-> -1, next |-> 0]],
    (* Process-local *)
    passed = [x \in ProcSet |-> FALSE],

define
    Us(pid) == (pid % 2) + 1
    Them(pid) == ((pid + 1) % 2) + 1
    Budget(pid) == descriptor[pid].budget
end define;

procedure AcquireGlobal()
begin
    g1: victim := self;
    gwait: while TRUE do
            g2: if cohort[Them(self)] = 0 then
                    goto g4; 
                end if;
            g3: if victim /= self then
                    goto g4; 
                end if;
        end while;
    g4: return
end procedure;

procedure AcquireCohort()
variables pred
begin
    c1: descriptor[self] := [budget |-> -1, next |-> 0];
    swap: pred := cohort[Us(self)]; cohort[Us(self)] := self;
    cwait: if ~(pred = 0) then
        c2: descriptor[pred].next := self;
        c3: await Budget(self) >= 0;
        c4: if Budget(self) = 0 then
                c5: call AcquireGlobal();
                c6: descriptor[self].budget := B;
            end if;
        c7: passed[self] := TRUE;
    else 
        c8: descriptor[self].budget := B;
        c9: passed[self] := FALSE;
    end if;
    c10: return;
end procedure;

procedure ReleaseCohort()
variables size, next
begin
    cas: if cohort[Us(self)] = self then
        cohort[Us(self)] := 0;
    else
        r1: await ~(descriptor[self].next = 0);
        r2: descriptor[descriptor[self].next].budget := Budget(self) - 1;
    end if;
    r3: return;
end procedure;

fair process p \in 1..NP
begin 
    p1: while TRUE do
        (* Non-critical section *)
        ncs:- skip;

        (* Acquire the cohort lock *)
        enter: call AcquireCohort();

        (* Acquire the global lock, maybe *)
        p2: if ~passed[self] then 
                call AcquireGlobal();
            end if;

        (* Critical section *)
        cs: skip; 

        (* Release the cohort lock *)
        exit: call ReleaseCohort();
    end while;
end process; 
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "aadb13a0" /\ chksum(tla) = "aa456e95")
CONSTANT defaultInitValue
VARIABLES victim, cohort, descriptor, passed, pc, stack

(* define statement *)
Us(pid) == (pid % 2) + 1
Them(pid) == ((pid + 1) % 2) + 1
Budget(pid) == descriptor[pid].budget

VARIABLES pred, size, next

vars == << victim, cohort, descriptor, passed, pc, stack, pred, size, next >>

ProcSet == (1..NP)

Init == (* Global variables *)
        /\ victim \in {1, 2}
        /\ cohort = [x \in {1, 2} |-> 0]
        /\ descriptor = [x \in ProcSet |-> [budget |-> -1, next |-> 0]]
        /\ passed = [x \in ProcSet |-> FALSE]
        (* Procedure AcquireCohort *)
        /\ pred = [ self \in ProcSet |-> defaultInitValue]
        (* Procedure ReleaseCohort *)
        /\ size = [ self \in ProcSet |-> defaultInitValue]
        /\ next = [ self \in ProcSet |-> defaultInitValue]
        /\ stack = [self \in ProcSet |-> << >>]
        /\ pc = [self \in ProcSet |-> "p1"]

g1(self) == /\ pc[self] = "g1"
            /\ victim' = self
            /\ pc' = [pc EXCEPT ![self] = "gwait"]
            /\ UNCHANGED << cohort, descriptor, passed, stack, pred, size, 
                            next >>

gwait(self) == /\ pc[self] = "gwait"
               /\ pc' = [pc EXCEPT ![self] = "g2"]
               /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                               size, next >>

g2(self) == /\ pc[self] = "g2"
            /\ IF cohort[Them(self)] = 0
                  THEN /\ pc' = [pc EXCEPT ![self] = "g4"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "g3"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

g3(self) == /\ pc[self] = "g3"
            /\ IF victim /= self
                  THEN /\ pc' = [pc EXCEPT ![self] = "g4"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "gwait"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

g4(self) == /\ pc[self] = "g4"
            /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
            /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
            /\ UNCHANGED << victim, cohort, descriptor, passed, pred, size, 
                            next >>

AcquireGlobal(self) == g1(self) \/ gwait(self) \/ g2(self) \/ g3(self)
                          \/ g4(self)

c1(self) == /\ pc[self] = "c1"
            /\ descriptor' = [descriptor EXCEPT ![self] = [budget |-> -1, next |-> 0]]
            /\ pc' = [pc EXCEPT ![self] = "swap"]
            /\ UNCHANGED << victim, cohort, passed, stack, pred, size, next >>

swap(self) == /\ pc[self] = "swap"
              /\ pred' = [pred EXCEPT ![self] = cohort[Us(self)]]
              /\ cohort' = [cohort EXCEPT ![Us(self)] = self]
              /\ pc' = [pc EXCEPT ![self] = "cwait"]
              /\ UNCHANGED << victim, descriptor, passed, stack, size, next >>

cwait(self) == /\ pc[self] = "cwait"
               /\ IF ~(pred[self] = 0)
                     THEN /\ pc' = [pc EXCEPT ![self] = "c2"]
                     ELSE /\ pc' = [pc EXCEPT ![self] = "c8"]
               /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                               size, next >>

c2(self) == /\ pc[self] = "c2"
            /\ descriptor' = [descriptor EXCEPT ![pred[self]].next = self]
            /\ pc' = [pc EXCEPT ![self] = "c3"]
            /\ UNCHANGED << victim, cohort, passed, stack, pred, size, next >>

c3(self) == /\ pc[self] = "c3"
            /\ Budget(self) >= 0
            /\ pc' = [pc EXCEPT ![self] = "c4"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

c4(self) == /\ pc[self] = "c4"
            /\ IF Budget(self) = 0
                  THEN /\ pc' = [pc EXCEPT ![self] = "c5"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "c7"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

c5(self) == /\ pc[self] = "c5"
            /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "AcquireGlobal",
                                                     pc        |->  "c6" ] >>
                                                 \o stack[self]]
            /\ pc' = [pc EXCEPT ![self] = "g1"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, pred, size, 
                            next >>

c6(self) == /\ pc[self] = "c6"
            /\ descriptor' = [descriptor EXCEPT ![self].budget = B]
            /\ pc' = [pc EXCEPT ![self] = "c7"]
            /\ UNCHANGED << victim, cohort, passed, stack, pred, size, next >>

c7(self) == /\ pc[self] = "c7"
            /\ passed' = [passed EXCEPT ![self] = TRUE]
            /\ pc' = [pc EXCEPT ![self] = "c10"]
            /\ UNCHANGED << victim, cohort, descriptor, stack, pred, size, 
                            next >>

c8(self) == /\ pc[self] = "c8"
            /\ descriptor' = [descriptor EXCEPT ![self].budget = B]
            /\ pc' = [pc EXCEPT ![self] = "c9"]
            /\ UNCHANGED << victim, cohort, passed, stack, pred, size, next >>

c9(self) == /\ pc[self] = "c9"
            /\ passed' = [passed EXCEPT ![self] = FALSE]
            /\ pc' = [pc EXCEPT ![self] = "c10"]
            /\ UNCHANGED << victim, cohort, descriptor, stack, pred, size, 
                            next >>

c10(self) == /\ pc[self] = "c10"
             /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
             /\ pred' = [pred EXCEPT ![self] = Head(stack[self]).pred]
             /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
             /\ UNCHANGED << victim, cohort, descriptor, passed, size, next >>

AcquireCohort(self) == c1(self) \/ swap(self) \/ cwait(self) \/ c2(self)
                          \/ c3(self) \/ c4(self) \/ c5(self) \/ c6(self)
                          \/ c7(self) \/ c8(self) \/ c9(self) \/ c10(self)

cas(self) == /\ pc[self] = "cas"
             /\ IF cohort[Us(self)] = self
                   THEN /\ cohort' = [cohort EXCEPT ![Us(self)] = 0]
                        /\ pc' = [pc EXCEPT ![self] = "r3"]
                   ELSE /\ pc' = [pc EXCEPT ![self] = "r1"]
                        /\ UNCHANGED cohort
             /\ UNCHANGED << victim, descriptor, passed, stack, pred, size, 
                             next >>

r1(self) == /\ pc[self] = "r1"
            /\ ~(descriptor[self].next = 0)
            /\ pc' = [pc EXCEPT ![self] = "r2"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

r2(self) == /\ pc[self] = "r2"
            /\ descriptor' = [descriptor EXCEPT ![descriptor[self].next].budget = Budget(self) - 1]
            /\ pc' = [pc EXCEPT ![self] = "r3"]
            /\ UNCHANGED << victim, cohort, passed, stack, pred, size, next >>

r3(self) == /\ pc[self] = "r3"
            /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
            /\ size' = [size EXCEPT ![self] = Head(stack[self]).size]
            /\ next' = [next EXCEPT ![self] = Head(stack[self]).next]
            /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
            /\ UNCHANGED << victim, cohort, descriptor, passed, pred >>

ReleaseCohort(self) == cas(self) \/ r1(self) \/ r2(self) \/ r3(self)

p1(self) == /\ pc[self] = "p1"
            /\ pc' = [pc EXCEPT ![self] = "ncs"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

ncs(self) == /\ pc[self] = "ncs"
             /\ TRUE
             /\ pc' = [pc EXCEPT ![self] = "enter"]
             /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                             size, next >>

enter(self) == /\ pc[self] = "enter"
               /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "AcquireCohort",
                                                        pc        |->  "p2",
                                                        pred      |->  pred[self] ] >>
                                                    \o stack[self]]
               /\ pred' = [pred EXCEPT ![self] = defaultInitValue]
               /\ pc' = [pc EXCEPT ![self] = "c1"]
               /\ UNCHANGED << victim, cohort, descriptor, passed, size, next >>

p2(self) == /\ pc[self] = "p2"
            /\ IF ~passed[self]
                  THEN /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "AcquireGlobal",
                                                                pc        |->  "cs" ] >>
                                                            \o stack[self]]
                       /\ pc' = [pc EXCEPT ![self] = "g1"]
                  ELSE /\ pc' = [pc EXCEPT ![self] = "cs"]
                       /\ stack' = stack
            /\ UNCHANGED << victim, cohort, descriptor, passed, pred, size, 
                            next >>

cs(self) == /\ pc[self] = "cs"
            /\ TRUE
            /\ pc' = [pc EXCEPT ![self] = "exit"]
            /\ UNCHANGED << victim, cohort, descriptor, passed, stack, pred, 
                            size, next >>

exit(self) == /\ pc[self] = "exit"
              /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "ReleaseCohort",
                                                       pc        |->  "p1",
                                                       size      |->  size[self],
                                                       next      |->  next[self] ] >>
                                                   \o stack[self]]
              /\ size' = [size EXCEPT ![self] = defaultInitValue]
              /\ next' = [next EXCEPT ![self] = defaultInitValue]
              /\ pc' = [pc EXCEPT ![self] = "cas"]
              /\ UNCHANGED << victim, cohort, descriptor, passed, pred >>

p(self) == p1(self) \/ ncs(self) \/ enter(self) \/ p2(self) \/ cs(self)
              \/ exit(self)

Next == (\E self \in ProcSet:  \/ AcquireGlobal(self) \/ AcquireCohort(self)
                               \/ ReleaseCohort(self))
           \/ (\E self \in 1..NP: p(self))

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in 1..NP : /\ WF_vars((pc[self] # "ncs") /\ p(self))
                               /\ WF_vars(AcquireCohort(self))
                               /\ WF_vars(AcquireGlobal(self))
                               /\ WF_vars(ReleaseCohort(self))

\* END TRANSLATION 

(* Safety *)
MutualExclusion == (\A i, k \in ProcSet: (i /= k) => ~(pc[i] = "cs" /\ pc[k] = "cs"))

(* Liveness *)
ExecsCriticalSectionInfinitelyOften == \A i \in ProcSet : []<>(pc[i] = "cs")
StarvationFree == \A i \in ProcSet : (pc[i] = "enter") ~> (pc[i] = "cs")
DeadAndLivelockFree == (\E i \in ProcSet : pc[i] = "enter") ~> (\E i \in ProcSet : pc[i] = "cs")

(* Fairness *)
CohortFairness == \A i, j \in ProcSet : (pc[i] = "cwait" /\ pc[j] = "enter") => (pc[i] = "cs" ~> pc[j] = "cs")
GlobalFairness == \A i, j \in ProcSet : (pc[i] = "gwait" /\ pc[j] = "enter") => (pc[i] = "cs" ~> pc[j] = "cs")
====

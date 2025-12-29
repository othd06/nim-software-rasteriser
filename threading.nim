import std/locks
import std/typedthreads

var
    lockA, lockB: Lock
    condA, condB: Cond
    jobReadyA, jobReadyB: bool
    jobDoneA, jobDoneB: bool

proc doWorkA() =
    discard
    # your function here

proc doWorkB() =
    discard
    # your function here

proc workerA(arg: pointer) {.thread.} =
    while true:
        lockA.acquire()
        while not jobReadyA:
            condA.wait(lockA)
        jobReadyA = false
        lockA.release()

        doWorkA()

        lockA.acquire()
        jobDoneA = true
        condA.signal()
        lockA.release()

proc workerB(arg: pointer) {.thread.} =
    while true:
        lockB.acquire()
        while not jobReadyB:
            condB.wait(lockB)
        jobReadyB = false
        lockB.release()

        doWorkB()

        lockB.acquire()
        jobDoneB = true
        condB.signal()
        lockB.release()

# --- Initialization ---
initLock(lockA)
initLock(lockB)
initCond(condA)
initCond(condB)

var tA, tB: Thread[pointer]
createThread(tA, workerA, nil)
createThread(tB, workerB, nil)

# --- Main loop ---
while true:
    # Wake workers
    lockA.acquire()
    jobDoneA = false
    jobReadyA = true
    condA.signal()
    lockA.release()

    lockB.acquire()
    jobDoneB = false
    jobReadyB = true
    condB.signal()
    lockB.release()

    # Wait for both
    lockA.acquire()
    while not jobDoneA:
        condA.wait(lockA)
    lockA.release()

    lockB.acquire()
    while not jobDoneB:
        condB.wait(lockB)
    lockB.release()

    # Continue main loop...

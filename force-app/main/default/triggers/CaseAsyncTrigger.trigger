trigger CaseAsyncTrigger on CaseChangeEvent (after insert) {
    AsyncTriggerDispatcher.run(new CaseAsyncTriggerHandler());
}
trigger HandoverAsyncTrigger on Handover__ChangeEvent (after insert) {
    AsyncTriggerDispatcher.run(new HandoverAsyncTriggerHandler());
}
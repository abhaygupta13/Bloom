trigger LeadAsyncTrigger on LeadChangeEvent (after insert) {
    AsyncTriggerDispatcher.run(new LeadAsyncTriggerHandler());
}
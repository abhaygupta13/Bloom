trigger SalesOrderAsyncTrigger on SalesOrder__ChangeEvent (after insert) {
    AsyncTriggerDispatcher.run(new SalesOrderAsyncTriggerHandler());
}
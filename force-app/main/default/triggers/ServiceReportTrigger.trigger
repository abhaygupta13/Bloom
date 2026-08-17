trigger ServiceReportTrigger on ServiceReport (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ServiceReportHandler());
}
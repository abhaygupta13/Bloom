trigger OnlinePaymentTrigger on OnlinePayment__c (after update) {
    TriggerDispatcher.run(new OnlinePaymentTriggerHandler());
}
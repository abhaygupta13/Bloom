public without sharing class ReceiptTriggerHelper {
	/**
     * Filters newly-inserted receipts to those that are Posted and linked to an OnlinePayment,
     * then enqueues the SendReceiptEmailsQueueable job with those Ids.
     */
    public static void enqueuePostedReceiptEmails(List<Receipt__c> newReceipts) {
        
        /*List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        Set<Id> paymentIds = new Set<Id>();
        for (Receipt__c r : receipts) {
            if (r.OnlinePayment__c != null) paymentIds.add(r.OnlinePayment__c);
        }

        Map<Id, OnlinePayment__c> paymentMap = new Map<Id, OnlinePayment__c>(
            [SELECT Id, Account__r.PersonEmail, Account__r.Name, Unit__r.Name, Invoice__c, Invoice__r.SAPInvoiceNumber__c
             FROM OnlinePayment__c WHERE Id IN :paymentIds]
        );

        Map<Id, Case> caseMap = new Map<Id, Case>();
        for (OnlinePaymentLineItem__c item : [SELECT Id, OnlinePayment__c, Case__r.Service_Catalog__r.Name FROM OnlinePaymentLineItem__c WHERE OnlinePayment__c IN :paymentIds]) {
            caseMap.put(item.OnlinePayment__c, item.Case__r);
        }

        for (Receipt__c receipt : receipts) {
            if (receipt.Status__c != 'Posted') continue;

            OnlinePayment__c payment = paymentMap.get(receipt.OnlinePayment__c);
            if (payment == null || String.isBlank(payment.Account__r.PersonEmail)) continue;

            String serviceName = 'Service Charge';
            if (caseMap.containsKey(payment.Id)) {
                Case relatedCase = caseMap.get(payment.Id);
                if (relatedCase != null && relatedCase.Service_Catalog__r != null){
                    serviceName = relatedCase.Service_Catalog__r.Name;
                }
            } else if(payment.Invoice__c != null && payment.Invoice__r.SAPInvoiceNumber__c != null){
                serviceName = 'Invoice '+payment.Invoice__r.SAPInvoiceNumber__c;
            }else {
                serviceName = payment.RequestSource__c;
            }

            String unit = payment.Unit__r != null ? payment.Unit__r.Name : 'your unit';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { payment.Account__r.PersonEmail });
            email.setSubject('Your payment for ' + serviceName + ' was successful');
            email.setPlainTextBody(
                'Dear ' + payment.Account__r.Name + ',\n\n' +
                'Your payment for ' + serviceName + ' has been successfully completed.\n' +
                'Unit: ' + unit + '\n' +
                'Amount Paid: ' + receipt.AmountReceived__c + '\n' +
                'Receipt No: ' + receipt.Name + '\n\n' +
                'You can download the receipt from your app or portal.\n\n' +
                'Regards,\nCommunity Finance Team'
            );
            emailsToSend.add(email);
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }*/
        
        
        
        if (newReceipts == null || newReceipts.isEmpty()) return;

        List<Id> postedReceiptIds = new List<Id>();
        for (Receipt__c r : newReceipts) {
            if (r.Status__c == 'Posted' && r.OnlinePayment__c != null) {
                postedReceiptIds.add(r.Id);
            }
        }
        if (!postedReceiptIds.isEmpty()) {
            System.enqueueJob(new BCAPP_SendReceiptEmailsQueueable(postedReceiptIds));
        }
    }
}
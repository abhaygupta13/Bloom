public class OnlinePaymentTriggerHelper {
    /**
     * Sends failure emails when Status__c transitions to 'Failed'.
     * - Filters only records that changed to Failed in this update.
     * - Uses selector services for queries (no SOQL here).
     * - Email subject/body preserved exactly as original implementation.
     */
    public static void sendFailureEmails(List<OnlinePayment__c> newList, Map<Id, OnlinePayment__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> paymentIds = new Set<Id>();
        for (OnlinePayment__c p : newList) {
            OnlinePayment__c oldRow = oldMap != null ? oldMap.get(p.Id) : null;
            if (p.Status__c == 'Failed' && (oldRow == null || oldRow.Status__c != 'Failed')) {
                paymentIds.add(p.Id);
            }
        }
        if (paymentIds.isEmpty()) return;

        // Selector calls (SOQL moved to services)
        Map<Id, OnlinePayment__c> paymentMap =
            OnlinePaymentService.getInstance().getByIdsForEmail(paymentIds);

        Map<Id, Case> caseMap =
            OnlinePaymentLineItemService.getInstance().getPrimaryCaseByPaymentIds(paymentIds);

        List<Messaging.SingleEmailMessage> failureEmails = new List<Messaging.SingleEmailMessage>();

        for (Id pid : paymentIds) {
            OnlinePayment__c p = paymentMap.get(pid);
            if (p == null || p.Account__r == null || String.isBlank(p.Account__r.PersonEmail)) continue;

            // Determine service name (same logic as original)
            String serviceName = 'Service Charge';
            if (caseMap.containsKey(pid)) {
                Case relatedCase = caseMap.get(pid);
                if (relatedCase != null && relatedCase.Service_Catalog__r != null) {
                    serviceName = relatedCase.Service_Catalog__r.Name;
                }
            } else if (p.Invoice__c != null && p.Invoice__r != null && p.Invoice__r.SAPInvoiceNumber__c != null) {
                serviceName = 'Invoice ' + p.Invoice__r.SAPInvoiceNumber__c;
            } else {
                serviceName = p.RequestSource__c;
            }

            String unit = (p.Unit__r != null && String.isNotBlank(p.Unit__r.Name)) ? p.Unit__r.Name : 'your unit';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { p.Account__r.PersonEmail });
            email.setSubject('Payment Failed for ' + serviceName);
            email.setPlainTextBody(
                'Dear ' + p.Account__r.Name + ',\n\n' +
                'Unfortunately, your payment for ' + serviceName + ' (Unit: ' + unit + ') has failed.\n' +
                'Please try again from the app or contact support.\n\n' +
                'Regards,\nCommunity Finance Team'
            );
            failureEmails.add(email);
        }

        if (!failureEmails.isEmpty()) {
            Messaging.sendEmail(failureEmails);
        }
    }
}
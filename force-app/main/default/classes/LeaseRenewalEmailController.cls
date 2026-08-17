public class LeaseRenewalEmailController {

   /* @AuraEnabled
    public static String sendRenewalEmail(Id leasingOrderId) {

        LeasingOrder__c orderRec = [
            SELECT Id,
                   LeasingOrderNumber__c,
                   Account__r.Name,
                   Account__r.PersonEmail
            FROM LeasingOrder__c
            WHERE Id = :leasingOrderId
            LIMIT 1
        ];

        if(String.isBlank(orderRec.Account__r.PersonEmail)){
            throw new AuraHandledException('No email found on Account.');
        }

        // Create Reminder
        Reminder__c reminder = new Reminder__c(
            LeasingOrder__c = leasingOrderId,
            Stage__c = 'Sent to Tenant',
            SendToTenantDate__c = Date.today()
        );

        insert reminder;

        // Read Formula Token
        reminder = [
            SELECT Id,
                   ReminderToken__c
            FROM Reminder__c
            WHERE Id = :reminder.Id
        ];

        String renewalUrl =
            'https://bloomholding--uat.sandbox.my.site.com/renewal-response?token='
            + EncodingUtil.urlEncode(reminder.ReminderToken__c,'UTF-8');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setToAddresses(
            new List<String>{orderRec.Account__r.PersonEmail}
        );

        email.setSubject(
            'Lease Renewal Notice - ' +
            orderRec.LeasingOrderNumber__c
        );

        String htmlBody =
            'Dear Customer,<br/><br/>' +
            'Your lease is going to expire soon.<br/><br/>' +
            'Please click the link below to submit your renewal decision.<br/><br/>' +
            '<a href="' + renewalUrl + '">Submit Response</a><br/><br/>' +
            'Regards,<br/>Bloom Team';

        email.setHtmlBody(htmlBody);

        Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{email}
        );

        return 'Renewal email sent successfully.';
    }

    @AuraEnabled(cacheable=true)
    public static Reminder__c getReminder(String token){

        Reminder__c reminder = [
            SELECT Id,
                   Name,
                   Stage__c,
                   SendToTenantDate__c,
                   ReminderToken__c,
                   LeasingOrder__c,
                   LeasingOrder__r.Id,
                   LeasingOrder__r.LeasingOrderNumber__c,
                   LeasingOrder__r.LeasingStartDate__c,
                   LeasingOrder__r.LeasingEndDate__c,
                   LeasingOrder__r.AppliedAnnualRent__c,
                   LeasingOrder__r.Renewal_Response__c,
                   LeasingOrder__r.Account__r.Name
            FROM Reminder__c
            WHERE ReminderToken__c = :token
            LIMIT 1
        ];

        return reminder;
    }

    @AuraEnabled
    public static void saveResponse(
        String token,
        String response
    ){

        Reminder__c reminder = [
            SELECT Id,
                   Stage__c,
                   LeasingOrder__c
            FROM Reminder__c
                                WHERE ReminderToken__c = :token

            LIMIT 1
        ];

        if(reminder.Stage__c == 'Responded'){
            throw new AuraHandledException(
                'Response has already been submitted.'
            );
        }

        LeasingOrder__c leasingOrder = new LeasingOrder__c(
            Id = reminder.LeasingOrder__c,
            Renewal_Response__c = response
        );

        update leasingOrder;

        reminder.Stage__c = 'Responded';

        update reminder;
    }*/
}
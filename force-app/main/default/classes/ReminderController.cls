public without sharing class ReminderController {
    
    private static final String RENEWAL_CONFIRMATION_TEMPLATE_NAME {get { return 'LeaseRenewalConfirmationtoManager'; }}
    private static final String NON_RENEWAL_TEMPLATE_NAME {get { return 'NoticeOfNonRenewalToLeasingManager'; }}
    private static final String BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID {get { return 'BloomNoReplyLeasingOWEmailId'; }}

    @AuraEnabled(cacheable=false)
    public static Reminder__c getReminder(String token){

        List<Reminder__c> reminder = [
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
                   LeasingOrder__r.RenewalResponse__c
            FROM Reminder__c
            WHERE ReminderToken__c = :token
            LIMIT 1
        ];
        if(reminder.size() > 0)
            return reminder[0];
        else{
            return null;
        }
    }

    @AuraEnabled
    public static void saveResponse(
        String token,
        String response
    ){

        List<Reminder__c> reminders = [ 
            SELECT Id, Stage__c, LeasingOrder__c, LeasingOrder__r.Account__r.Name, LeasingOrder__r.Owner.Name, LeasingOrder__r.Owner.Email, LeasingOrder__r.OwnerId
            FROM Reminder__c 
            WHERE ReminderToken__c = :token 
            WITH SYSTEM_MODE
            LIMIT 1 
        ];


        if(reminders.isEmpty()){
            return;
        }

        Reminder__c reminder = reminders[0];

        if(reminder.Stage__c == 'Responded'){
            throw new AuraHandledException(
                'Response has already been submitted.'
            );
        }

        if(reminder.Stage__c == 'Expired' || reminder.Stage__c == 'Cancelled' ){
            throw new AuraHandledException(
                'Response has been Expired.'
            );
        }

        LeasingOrder__c leasingOrder = new LeasingOrder__c(
            Id = reminder.LeasingOrder__c,
            RenewalResponse__c = response
        );

        reminder.Stage__c = 'Responded';
        
        MetadataService metaService = MetadataService.getInstance(); //Send Confirmation Email to Manager
        Id templateId = response == 'Renew'
            ? metaService.getAppSettingTextValue(RENEWAL_CONFIRMATION_TEMPLATE_NAME)
            : metaService.getAppSettingTextValue(NON_RENEWAL_TEMPLATE_NAME);
        System.debug('template Id : '+ templateId);
		System.debug('reminder.LeasingOrder__r.Owner.Email : '+ reminder.LeasingOrder__r.Owner.Email);
        if (templateId != null && reminder.LeasingOrder__r.Owner.Email != null) {
        
            Messaging.SingleEmailMessage renderedMail =
                Messaging.renderStoredEmailTemplate(
                    templateId,
                    reminder.LeasingOrder__r.OwnerId,
                    reminder.LeasingOrder__c
                );
        
            String subject = renderedMail.getSubject();
            String body = renderedMail.getHtmlBody();
        
            body = body.replace('{[LeasingOrder__c.Owner.Name]}', reminder.LeasingOrder__r.Owner.Name != null ? reminder.LeasingOrder__r.Owner.Name : 'Manager');
            body = body.replace('{[LeasingOrder__c.Account__r.Name]}', reminder.LeasingOrder__r.Account__r.Name != null ? reminder.LeasingOrder__r.Account__r.Name: '');
        
            Id orgWideEmailId = metaService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
            Messaging.SingleEmailMessage mail =
                EmailService.getInstance().getSingleEmailMessage(
                    new List<String>{ reminder.LeasingOrder__r.Owner.Email },
                    reminder.LeasingOrder__c,
                    null,
                    subject,
                    body,
                    orgWideEmailId, 
                    null,
                    null
                );
            mail.setSaveAsActivity(true);
            for (Messaging.SendEmailResult r : Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }, false)) {
                System.debug(r.isSuccess());
                if (!r.isSuccess()) {
                    System.debug(r.getErrors());
                }
            }
        }

        Database.update(leasingOrder, System.AccessLevel.SYSTEM_MODE);
        Database.update(reminder, System.AccessLevel.SYSTEM_MODE);
    }
}
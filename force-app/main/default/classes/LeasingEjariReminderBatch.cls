/***
Class       : LeasingEjariReminderBatch
Author      : 
Description : Batch class to send weekly reminders to Leasing team to update Ejari details on leasing order
                Batch size should be 1.
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              21/10/2025           Initial Version 
****************************************************************************************************************/
public class LeasingEjariReminderBatch implements Database.Batchable<SObject>, Schedulable  {

    private static final String EJARI_REMINDER_TEMPLATE { get { return 'LeasingOrderReminderEmail'; } }
    private static final String BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final String LEASING_MANAGER_EMAIL { get { return 'LeasingManagerEmailV1'; } }
    private static final String BATCH_SIZE_METADATA {get {return 'EjariReminderBatchSize';}}

    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM User 
            WHERE Id IN (
                SELECT OwnerId
                FROM LeasingOrder__c
                WHERE RERANumber__c = NULL
                    AND Owner.Email != NULL
                    AND Status__c NOT IN ('Cancelled','Terminated','Leased')
                    AND LeasingSAPContractId__c != NULL
                    AND IntegrationStatus__c = 'Success'
                    AND PropertyUsage__c = 'Residential'
                    AND LeasingStartDate__c <= TODAY)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        EmailService emlService = EmailService.getInstance();
        MetadataService meta = MetadataService.getInstance();

        Id ejariReminderTemplateId = meta.getAppSettingTextValue(EJARI_REMINDER_TEMPLATE);
        Id noReplyEmailId = meta.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        String managerEmail = meta.getAppSettingTextValue(LEASING_MANAGER_EMAIL) != Null ? meta.getAppSettingTextValue(LEASING_MANAGER_EMAIL) : '';

        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        String orderListHtml = '';
        orderListHtml += '<table align="center" style="border-collapse:collapse;width:100%;font-size:13px;border:1px solid #ccc;margin:0 auto;">';
        orderListHtml += '<thead style="background-color:#f4f4f4;text-align:left;">';
        orderListHtml += '<tr>';
        orderListHtml += '<th style="border:1px solid #ccc;padding:6px;width:40px;text-align:center;">#</th>';
        orderListHtml += '<th style="border:1px solid #ccc;padding:6px;">Name</th>';
        orderListHtml += '<th style="border:1px solid #ccc;padding:6px;text-align:center;">Unit</th>';
        orderListHtml += '<th style="border:1px solid #ccc;padding:6px;text-align:center;">Owner</th>';
        orderListHtml += '</tr>';
        orderListHtml += '</thead><tbody>';
        Integer count = 1;
        String toAddress;
        String toName;
        LeasingOrderService service = LeasingOrderService.getInstance();
        List<User> u = (List<User>) scope;
        for (LeasingOrder__c lo : service.getPendingEjariOrdersByOwners(New Set<Id>{u[0].Id})) {
            String link = baseUrl + '/lightning/r/LeasingOrder__c/' + lo.Id + '/view';
            orderListHtml += '<tr>';
            orderListHtml += '<td style="border:1px solid #ccc;padding:6px;text-align:center;">' + count + '</td>';
            orderListHtml += '<td style="border:1px solid #ccc;padding:6px;"> <a href="' + link + '" target="_blank" style="color:#0070d2;text-decoration:none;">'+ lo.Name + '</a></td>';
            orderListHtml += '<td style="border:1px solid #ccc;padding:6px;text-align:center;">'
                        + (lo.Unit__c != null ? (lo.Unit__r.UnitNumber__c) : '')
                        + '</td>';
            orderListHtml += '<td style="border:1px solid #ccc;padding:6px;text-align:center;">'
                        + (lo.Owner != null ? (lo.Owner.Name) : '')
                        + '</td>';
            orderListHtml += '</tr>';
            toAddress = lo.Owner.Email;
            toName = lo.Owner.Name;
            count++;
        }
        orderListHtml += '</tbody></table>';
        if(toAddress != Null){
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(
                ejariReminderTemplateId, null, null
            );

            mail.setOrgWideEmailAddressId(noReplyEmailId);
            mail.setToAddresses(new List<String>{ toAddress });
            if(!String.isEmpty(managerEmail))
            mail.setCcAddresses(new List<string>{managerEmail});

            mail.setHtmlBody(
                mail.getHtmlBody()
                    .replace('{LeasingOfficerName}', toName)
                    .replace('{LeasingOrders}', orderListHtml)
            );

            emailsToSend.add(mail);
            

            if (!emailsToSend.isEmpty() && !Test.isRunningTest()) {
                emlService.sendEmail(emailsToSend);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public void execute(SchedulableContext sc) {
        MetadataService mtdtService = MetadataService.getInstance();
        LeasingEjariReminderBatch batchJob = new LeasingEjariReminderBatch();
        Database.executeBatch(batchJob, mtdtService.getAppSettingNumberValue(BATCH_SIZE_METADATA) != Null ? mtdtService.getAppSettingNumberValue(BATCH_SIZE_METADATA) : 1); 
    }
}
public class LeasingOrderTaskReminderBatch implements Database.Batchable<SObject> {
    private static final string MTD_NO_REPLY_LEASING_OWEID_SETTING { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string TASK_REMINDER_EMAIL_TEMPLATE_ID { get { return 'LeasingReminderEmailTemplateId'; } }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Datetime twentyFourHoursAgo = System.now().addHours(-24);

        return Database.getQueryLocator([
            SELECT Id,
                   Name,
                   OwnerId,
                   Owner.Email,
                   LeasingContractSignedDate__c
            FROM LeasingOrder__c
            WHERE LeasingContractSignedDate__c != NULL
            AND LeasingContractSignedDate__c <= :twentyFourHoursAgo
            AND Status__c NOT IN ('Cancelled', 'Terminated')
            AND LeasingOrderDataMigrationUniqueKey__c = Null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<LeasingOrder__c> scope) {

        Set<Id> leasingOrderIds = new Set<Id>();

        for(LeasingOrder__c lo : scope){
            leasingOrderIds.add(lo.Id);
        }

        // Get all leasing orders having tasks
        Map<Id, Integer> taskCountMap = new Map<Id, Integer>();

        for(AggregateResult ar : [
            SELECT WhatId whatId,
                   COUNT(Id) total
            FROM Task
            WHERE WhatId IN :leasingOrderIds
            AND TaskSubtype = 'Task'
            GROUP BY WhatId
        ]){
            taskCountMap.put(
                (Id)ar.get('whatId'),
                (Integer)ar.get('total')
            );
        }

        // Id emailTemplateId = [
        //     SELECT Id
        //     FROM EmailTemplate
        //     WHERE Name = 'Leasing Order Task Reminder'
        //     LIMIT 1
        // ].Id;

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id noReplySalesITOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_LEASING_OWEID_SETTING );
        Id taskReminderEmailTemplateId = objMetadataService.getAppSettingTextValue(TASK_REMINDER_EMAIL_TEMPLATE_ID);

        for(LeasingOrder__c lo : scope){

            if(!taskCountMap.containsKey(lo.Id)){

                Messaging.SingleEmailMessage email = EmailService.getInstance().getSingleEmailMessageWithoutTargetObjectId(
                                                                taskReminderEmailTemplateId,
                                                                noReplySalesITOWDId,
                                                                lo.Id,
                                                                new List<String>{lo.owner.email},
                                                                null,
                                                                null
                                                            );
                emails.add(email);
            }
        }

        if(!emails.isEmpty() && !test.isRunningTest()){
            Messaging.sendEmail(emails);
        }
    }

    public void finish(Database.BatchableContext bc){

    }
}
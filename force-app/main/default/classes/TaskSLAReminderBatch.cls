/*****************************************************************************************
* @Author        : Prashant Sahu
* @CreatedDate   : 14 Apr 2026
* @Description   : First Contact SLA Batch 
*                 - SLA duration: 3 Working Hours
*                 - Reminder: 1 hour before breach
*****************************************************************************************/
public class TaskSLAReminderBatch implements Database.Batchable<SObject>, Schedulable {
    
    // private static final Integer REMINDER_BEFORE_60_MINUTES = 60;
    private static final Integer TIME_WINDOW_MINUTES = 15;
    private static final string MTD_SLA_Reminder_Email_Template_ID { get { return 'SLAReminderEmailTemplate'; } }
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }
    private static final String MTD_SLA_BREACH_EMAIL_TEMPLATE_ID { get { return 'SLABreachEmailTemplate'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([ SELECT Id, OwnerId, Subject, AssignedDateTime__c, SLADateTime__c, Status, WhatId, CreatedDate, SLAReminderSent__c, SLABreachSent__c,ReminderBeforeHours__c, Owner.Email, ManagerEmail__c FROM Task
                                         WHERE Status != 'Completed' AND AssignedDateTime__c != NULL AND SLADateTime__c != NULL and (SLAReminderSent__c = FALSE or SLABreachSent__c = False)  LIMIT 5 ]);
        
    }
    
    public void execute(Database.BatchableContext bc, List<Task> scope) {
        ActivityService objActivityService = ActivityService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Task> updateTasks = new List<Task>();
        Id slaEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SLA_Reminder_Email_Template_ID);
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        
        Id breachEmailTemplateId = objMetadataService.getAppSettingTextValue( MTD_SLA_BREACH_EMAIL_TEMPLATE_ID );
        
        try {
            // Recipients:
            // *  - Task Owner (Agent)
            // *  - Manager (if available)
            // Reminder email should be sent only once.
            
            for (Task taskRecord : scope) {
                if(taskRecord.SLAReminderSent__c == False && taskRecord.ReminderBeforeHours__c  != null){
                    Datetime slaEndTime = taskRecord.SLADateTime__c;
                    Integer reminderHours =  Integer.valueOf(taskRecord.ReminderBeforeHours__c);
                    Datetime reminderTime = slaEndTime.addHours(-reminderHours);
                    
                    //  need to know   
                    //  To: Agent CC: Assistant Manager,CX Manager
                    //  To: Leasing Agent CC: Leasing Manager
                    //  To: Sales Manager CC: Head of Sales, Lead Management
                    //  
                    // Reminder Email
                    if (!taskRecord.SLAReminderSent__c && System.now() >= reminderTime && System.now() <= reminderTime.addMinutes(TIME_WINDOW_MINUTES)) {
                        
                        List<String> emailListAddr = new List<String>();
                        
                        if(taskRecord.Owner.Email != null){
                            emailListAddr.add(taskRecord.Owner.Email);
                        }
                        if (taskRecord.ManagerEmail__c != null) {
                            emailListAddr.add(taskRecord.ManagerEmail__c);
                        }
                        
                        if (taskRecord.OwnerId != null) { 
                            emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( slaEmailTemplateId, noReplyOWDId, null, taskRecord.WhatId, emailListAddr, null, null ) );
                        }
                        taskRecord.SLAReminderSent__c = true;
                        updateTasks.add(taskRecord);
                    }
                    // Breach Email - send only once
                }
                
                if(taskRecord.SLABreachSent__c == False &&  System.now() > taskRecord.SLADateTime__c )  {
                    
                    List<String> breachEmailList = new List<String>();
                    
                    if (taskRecord.ManagerEmail__c != null) {
                        breachEmailList.add(taskRecord.ManagerEmail__c);
                    }
                    if ( taskRecord.OwnerId != null && !breachEmailList.isEmpty() ) {
                        emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(breachEmailTemplateId,noReplyOWDId,null,taskRecord.WhatId,breachEmailList,null,null));
                        taskRecord.SLABreachSent__c = true;
                        updateTasks.add(taskRecord);
                    }
                }
            }
            objEmailService.sendEmail(emailList);
            objActivityService.updateTasksWithoutTrigger(updateTasks);
            
        } 
        catch (Exception ex) {
            System.debug('Error in FirstContactSLABatch: ' + ex.getMessage());
        }
    }
    public void execute(SchedulableContext sc){
        Database.executeBatch(new TaskSLAReminderBatch(), 200);
    }
    public void finish(Database.BatchableContext bc) {
        //  System.debug('First Contact SLA Batch Completed');
    }
    
}
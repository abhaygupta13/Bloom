/*****************************************************************************************
* Class         : LeadSLAReminderBatch
* Author        : Prashant Sahu
* Created Date  : 07/06/2026
*
* Description   : Lead SLA Reminder & Notification Batch
* This batch is responsible for processing all SLA reminder and breach
* notifications for Lead-related activities as per the Bloom Holding BRD.
* ---------------------------------------------------------------
* 1   : Contact Center SLA - Reminder, Breach, Day 2 Reminder, Day 3 Reminder

* 2  : Leasing SLA   - Reminder, Breach

* 3 : Sales SLA (3-Hour Lead Action / Reshuffling)
*          - Reminder #1, Reminder #2, Breach,
*            Head of Sales Escalation,
*            Executive Director Escalation

* 4: Sales SLA (3-Day Lead Follow-up)
*          - Reminder, Breach,
*            Head of Sales Escalation,
*            Executive Director Escalation
*****************************************************************************************/
/* Note: This batch sends reminder and escalation emails only.
*****************************************************************************************/
public class LeadSLAReminderBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final string CONTACT_CENTER_PROFILE_ID { get { return 'ContactCentreProfileId'; } }
    private static final string LEAD_STATUS_INPROGRESS { get { return 'In Progress'; } }
    private static final string LEAD_CC_STATUS_QUALIFIED { get { return 'Qualified'; } }
    private static final string LEAD_TEAM { get { return 'Sales'; } }
    //  private static final string SALES_TASK_SUBJECT { get { return 'SM'; } }
    //  private static final string LEASING_TASK_SUBJECT { get { return 'LO'; } }
    private static final string LEAD_LM_STATUS_CONVERTED { get { return 'Converted'; } }
    private static final string LEAD_LM_STATUS_RETIRED { get { return 'Retired'; } }
    private static final string LEAD_LM_STATUS_FOLLOWUP { get { return 'Follow Up'; } }
    private static final string LEAD_LM_STATUS_WAITINGLIST { get { return 'Waiting List'; } }
    
    // private static final Integer REMINDER_BEFORE_60_MINUTES = 60; 
    private static final Integer TIME_WINDOW_MINUTES = 15;
    //private static final string MTD_SLA_Reminder_Email_Template_ID { get { return 'SLAReminderEmailTemplate'; } }  
    private static final string MTD_SLA_Reminder_Email_Template_ID { get { return 'SLAReminderEmailTemplateV2'; } } 
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }
    private static final String MTD_SLA_BREACH_EMAIL_TEMPLATE_ID { get { return 'SLABreachEmailTemplate'; } }
    private static final String MTD_DAY2_REMINDER_EMAIL_TEMPLATE_ID {get { return 'Day2CallAttemptReminderTemplate'; }} //
    private static final String MTD_DAY3_REMINDER_EMAIL_TEMPLATE_ID { get { return 'Day3ReminderEmailTemplate'; } } //
    private static final String MTD_SALES_BREACH_TEMPLATE {get { return 'LeadSLABreachEmailTemplate'; } } //
    private static final String MTD_SALES_REMINDER1_TEMPLATE{get{ return 'SalesReminder1EmailTemplate'; } }
    private static final String MTD_SALES_REMINDER2_TEMPLATE{ get{ return 'SalesReminder2EmailTemplate'; }}
    private static final String MTD_EXECUTIVE_DIRECTOR_TEMPLATE{get{ return 'ExecutiveDirectorEscalationTemplate'; } }
    private static final String MTD_SALES_3DAY_REMINDER_TEMPLATE { get { return 'Sales3DayReminderTemplate'; } }
    private static final String MTD_SALES_3DAY_BREACH_TEMPLATE { get { return 'Sales3DayBreachTemplate'; } }
    private static final String Lead_Management_Email { get { return 'prashantsahu.sf@gmail.com'; } }
    private static final String head_Of_Sales_Email { get { return 'prashantsahu.sf@gmail.com'; } }
    private static final String executive_Director_Email { get { return 'prashantsahu.sf@gmail.com'; } }
    
    
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        /*return Database.getQueryLocator([ SELECT Id, OwnerId, Subject, AssignedDateTime__c, SLADateTime__c, Status, WhatId, CreatedDate, SLAReminderSent__c, SLABreachSent__c,ReminderBeforeHours__c, Owner.Email, ManagerEmail__c, ActivityDate,
Description FROM Task WHERE Status != 'Completed' AND AssignedDateTime__c != NULL AND SLADateTime__c != NULL and (SLAReminderSent__c = FALSE or SLABreachSent__c = False)  LIMIT 5 ]);*/
        
        /*return Database.getQueryLocator([SELECT Id, Subject, Status, ActivityDate, Description, OwnerId, Owner.Email, WhoId, WhatId, AssignedDateTime__c, SLADateTime__c, ReminderBeforeHours__c, SLAReminderSent__c, SLABreachSent__c, ManagerEmail__c,HoSDecisionSent__c,ExecutiveDirectorSent__c,SLAStatus__c,BusinessHours__c
                                         FROM Task WHERE id ='00TFV009FigVFYC2I4' OR (Status != 'Completed' AND SLADateTime__c != NULL)]); */
        
        /*return Database.getQueryLocator([ SELECT Id, Subject, Status, ActivityDate, Description, OwnerId, Owner.Email, WhoId, WhatId, AssignedDateTime__c, SLADateTime__c, ReminderBeforeHours__c, SLAReminderSent__c, SLABreachSent__c, ManagerEmail__c, HoSDecisionSent__c, ExecutiveDirectorSent__c, SLAStatus__c, BusinessHours__c 
                                         FROM Task WHERE Id = '00TFV009FigVFYC2I4' ]);*/
        
        return Database.getQueryLocator([ SELECT Id, Subject, Status, ActivityDate, Description, OwnerId, Owner.Email, WhoId, WhatId, AssignedDateTime__c, SLADateTime__c, ReminderBeforeHours__c, SLAReminderSent__c, SLABreachSent__c, Day2ReminderSent__c, Day3ReminderSent__c, SalesReminder1Sent__c, SalesReminder2Sent__c, ManagerEmail__c, HoSDecisionSent__c, ExecutiveDirectorSent__c, HoSEscalationSent__c, ExecutiveDirectorEscalationSent__c, SLAStatus__c, BusinessHours__c FROM
                                                                                                            Task WHERE Id = '00TFV009n8rn0ai2AA']);    //00TFV009FigVFYC2I4  //00TFV009UvE3sZo2IJ    //00TFV009UvE3sZo2IJ  //'00TFV000qw1HRVs2AO'
        
    }
    
    
    public void execute(Database.BatchableContext bc, List<Task> scope) {
        system.debug('execute');
        ActivityService objActivityService = ActivityService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
      
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Task> updateTasks = new List<Task>();
   
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        List<Id> contactCentreProfileIdList = contactCentreProfileIds.split(',');
        
        Id slaEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SLA_Reminder_Email_Template_ID);
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        Id breachEmailTemplateId = objMetadataService.getAppSettingTextValue( MTD_SLA_BREACH_EMAIL_TEMPLATE_ID );
        Id day2ReminderTemplateId = objMetadataService.getAppSettingTextValue( MTD_DAY2_REMINDER_EMAIL_TEMPLATE_ID );//
        Id day3ReminderTemplateId = objMetadataService.getAppSettingTextValue(MTD_DAY3_REMINDER_EMAIL_TEMPLATE_ID);//
        Id salesBreachTemplateId = objMetadataService.getAppSettingTextValue(MTD_SALES_BREACH_TEMPLATE);
        Id salesReminder1TemplateId = objMetadataService.getAppSettingTextValue(MTD_SALES_REMINDER1_TEMPLATE);
        Id salesReminder2TemplateId = objMetadataService.getAppSettingTextValue(MTD_SALES_REMINDER2_TEMPLATE);
        Id executiveDirectorTemplateId =objMetadataService.getAppSettingTextValue(MTD_EXECUTIVE_DIRECTOR_TEMPLATE);
        Id salesReminder3DayTemplateId = objMetadataService.getAppSettingTextValue(MTD_SALES_3DAY_REMINDER_TEMPLATE);
        Id sales3DayBreachTemplateId = objMetadataService.getAppSettingTextValue(MTD_SALES_3DAY_BREACH_TEMPLATE);
        
        
        //try {
        Set<Id> leadIds = new Set<Id>();
        for(Task taskRecord : scope){
            if(taskRecord.WhoId != null ){
                leadIds.add(taskRecord.WhoId);
            }
        }
        
        Map<Id, Lead> leadMap = objLeadService.getLeadSLAByIds(leadIds);
        for(Task taskRecord : scope){
            Lead objLead = leadMap.get(taskRecord.WhoId);
            if(objLead == null){
                continue;
            }
            
            System.debug('Lead Owner Profile : ' + objLead.Owner.Profile.Name);
            System.debug('Lead Status        : ' + objLead.Status);
            System.debug('CC Status          : ' + objLead.ContactCentreLeadStatus__c);
            System.debug('Owner Profile Id   : ' + objLead.Owner.ProfileId);
            System.debug('Metadata ProfileIds: ' + contactCentreProfileIdList);
            
            // CONTACT CENTER SLA (BRD Section 5)
            if(objLead.Owner.profileId != null && objLead.Status == LEAD_STATUS_INPROGRESS && contactCentreProfileIdList.contains(objLead.Owner.profileId) ){
                
                // Common Email Recipients
                List<String> ownerAndManagerEmails = new List<String>();
                List<String> managerEmails = new List<String>();
                
                if(taskRecord.Owner.Email != null){
                    ownerAndManagerEmails.add(taskRecord.Owner.Email);
                }
                
                if(taskRecord.ManagerEmail__c != null){
                    ownerAndManagerEmails.add(taskRecord.ManagerEmail__c);
                    managerEmails.add(taskRecord.ManagerEmail__c);
                }
                
                // BRD 5.4 - Reminder
                if(!taskRecord.SLAReminderSent__c){
                    //Datetime reminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, taskRecord.SLADateTime__c, -1 );   //
                    Datetime reminderTime = taskRecord.SLADateTime__c.addHours(-1);
                     
                    
                    System.debug('===== CC Reminder Test =====');
                  /*  System.debug('Task Id            = ' + taskRecord.Id);
                    System.debug('Task Subject       = ' + taskRecord.Subject);
                    System.debug('Reminder Sent      = ' + taskRecord.SLAReminderSent__c);
                    System.debug('Owner Email        = ' + taskRecord.Owner.Email);
                    System.debug('Manager Email      = ' + taskRecord.ManagerEmail__c);
                    System.debug('Owner+Manager List = ' + ownerAndManagerEmails);
                    System.debug('List Empty?        = ' + ownerAndManagerEmails.isEmpty());
                    System.debug('Now                = ' + System.now());
                    System.debug('Reminder Time      = ' + reminderTime);
                    System.debug('Window End         = ' + reminderTime.addMinutes(TIME_WINDOW_MINUTES));*/
                    

                    if(taskRecord.Subject == 'CC - Day 1 Call 1 - Follow Up' && System.now() >= reminderTime && System.now() <= reminderTime.addMinutes(TIME_WINDOW_MINUTES) && !ownerAndManagerEmails.isEmpty()){
                          System.debug('********** REMINDER EMAIL CONDITION PASSED **********');
                            System.debug('******** EMAIL SHOULD SEND ********');
                        emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(slaEmailTemplateId, noReplyOWDId, null , taskRecord.WhoId, ownerAndManagerEmails, null, null));
                        taskRecord.SLAReminderSent__c = true;
                        System.debug('Reminder flag changed = ' + taskRecord.SLAReminderSent__c);
                        
                        updateTasks.add(taskRecord);
                        System.debug('Update Task List Size = ' + updateTasks.size());
                    }
                }
                
                // BRD 5.4 - Breach
                if(!taskRecord.SLABreachSent__c && taskRecord.Subject == 'CC - Day 1 Call 1 - Follow Up' && System.now() > taskRecord.SLADateTime__c && !managerEmails.isEmpty() && taskRecord.SLAStatus__c.contains('Breached')){
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(breachEmailTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{taskRecord.ManagerEmail__c}, null, null));
                    taskRecord.SLABreachSent__c = true;
                    updateTasks.add(taskRecord);
                }
                
                // BRD 5.4 - Day 2 Reminder 
                if(!taskRecord.Day2ReminderSent__c && taskRecord.Subject == 'CC - Day 2 Call 1 - Follow Up' && System.now() > taskRecord.SLADateTime__c && !managerEmails.isEmpty()){
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(day2ReminderTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{taskRecord.ManagerEmail__c}, null, null));
                    taskRecord.Day2ReminderSent__c = true;
                    updateTasks.add(taskRecord);
                }
                  
                // BRD 5.4 - Day 3 Reminder (FIXED — apna separate flag)
                if(taskRecord.Subject == 'CC - Day 3 Call 1 - Follow Up' && taskRecord.ActivityDate == Date.today() && !managerEmails.isEmpty() && !taskRecord.Day3ReminderSent__c){
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(day3ReminderTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{taskRecord.ManagerEmail__c}, null, null));
                    taskRecord.Day3ReminderSent__c = true;
                    updateTasks.add(taskRecord);
                }
                
            }
            
            // LEASING SLA (BRD Section 6)
            if(objLead.ContactCentreLeadStatus__c == LEAD_CC_STATUS_QUALIFIED ){
                System.debug('===== LEASING SLA DEBUG START =====');
               /* System.debug('Lead Id                : ' + objLead.Id);
                System.debug('LeadManagerStatus      : ' + objLead.LeadManagerStatus__c);
                System.debug('LeadManagerAssigned    : ' + objLead.LeadManagerAssignedDate__c);
                System.debug('Task Id                : ' + taskRecord.Id);
                System.debug('Task Subject           : ' + taskRecord.Subject);*/
                if(taskRecord.Subject.startsWith('LO -')){
                      System.debug('Entered LO Task Block');
                    // BRD 6.2 - Reminder // Trigger : 8 Working Hours Before SLA Breach // To : Leasing Agent // CC : Leasing Manager
                    if(objLead.LeadManagerAssignedDate__c != null){
                        
                        Datetime reminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, taskRecord.AssignedDateTime__c, 8 ); 
                      /*  System.debug('Business Hours         : ' + taskRecord.BusinessHours__c);
                        System.debug('AssignedDateTime       : ' + taskRecord.AssignedDateTime__c);
                        System.debug('SLA DateTime           : ' + taskRecord.SLADateTime__c);
                        System.debug('Reminder Time          : ' + reminderTime);
                        System.debug('Current Time           : ' + System.now());
                        System.debug('Reminder Window End    : ' + reminderTime.addMinutes(TIME_WINDOW_MINUTES));
                        System.debug('Reminder Already Sent? : ' + taskRecord.SLAReminderSent__c);*/
                        if(System.now() >= reminderTime && System.now() <= reminderTime.addMinutes(TIME_WINDOW_MINUTES) && !taskRecord.SLAReminderSent__c ){
                            System.debug('***** Reminder Condition PASSED *****');
                            List<String> emailAddresses = new List<String>();
                            
                            if(taskRecord.Owner.Email != null){
                                emailAddresses.add(taskRecord.Owner.Email);
                            }
                            
                            if(taskRecord.ManagerEmail__c != null){
                                emailAddresses.add(taskRecord.ManagerEmail__c);
                            }

                            if(!emailAddresses.isEmpty()){
                                emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(slaEmailTemplateId,noReplyOWDId,null,taskRecord.WhoId,emailAddresses,null,null));    //taskRecord.WhoId  //taskRecord.WhatId
                               System.debug('Reminder Email Added Successfully');
                                taskRecord.SLAReminderSent__c = true;
                                updateTasks.add(taskRecord);
                            }
                        }
                    }
                    
                  
                    // BRD 6.2 - Breach // Trigger : 24 Working Hours // To : Leasing Manager
                    if(!taskRecord.SLABreachSent__c && System.now() > taskRecord.SLADateTime__c && taskRecord.ManagerEmail__c != null && taskRecord.SLAStatus__c.contains('Breached')){
                        System.debug('***** Breach Condition PASSED *****');
                        emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(breachEmailTemplateId,noReplyOWDId,null,taskRecord.WhoId,new List<String>{taskRecord.ManagerEmail__c},null,null));
                        taskRecord.SLABreachSent__c = true;
                        updateTasks.add(taskRecord);
                    }
                }  
            }
            
            // SALES SLA (BRD Section 7) 
            if((objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP || objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST)){
                //    if(taskRecord.Subject.startsWith('SM -')){
                
                // BRD 7.1 - Reminder #1 // Trigger : 1 Hour After Assignment // To : Sales Manager // CC : Head of Sales, Lead Management
                
                if(objLead.LeadManagerAssignedDate__c != null){
                    
                    Datetime firstReminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, taskRecord.AssignedDateTime__c, 1 );   //
                    if(System.now() >= firstReminderTime && System.now() <= firstReminderTime.addMinutes(TIME_WINDOW_MINUTES)){
                        List<String> emailAddresses = new List<String>();
                        
                        if(taskRecord.Owner.Email != null){
                            emailAddresses.add(taskRecord.Owner.Email);
                        }
                        if(taskRecord.ManagerEmail__c != null){
                            emailAddresses.add(taskRecord.ManagerEmail__c);
                        }
                        emailAddresses.add(Lead_Management_Email);
                        emailAddresses.add(head_Of_Sales_Email);
                        
                        if(!emailAddresses.isEmpty()){
                            emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(salesReminder1TemplateId,noReplyOWDId,null,taskRecord.WhoId,emailAddresses,null,null));
                        }
                    }
                }
                
                /*// BRD 7.1 - Reminder #1 (FIXED — flag add kiya)
                    if(objLead.LeadManagerAssignedDate__c != null){
                    
                    Datetime firstReminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, taskRecord.AssignedDateTime__c, 1 );
                    if(!taskRecord.SalesReminder1Sent__c && System.now() >= firstReminderTime && System.now() <= firstReminderTime.addMinutes(TIME_WINDOW_MINUTES)){
                    List<String> emailAddresses = new List<String>();
                    
                    if(taskRecord.Owner.Email != null){
                    emailAddresses.add(taskRecord.Owner.Email);
                    }
                    if(taskRecord.ManagerEmail__c != null){
                    emailAddresses.add(taskRecord.ManagerEmail__c);
                    }
                    emailAddresses.add(Lead_Management_Email);
                    emailAddresses.add(head_Of_Sales_Email);
                    
                    if(!emailAddresses.isEmpty()){
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(salesReminder1TemplateId,noReplyOWDId,null,taskRecord.WhoId,emailAddresses,null,null));
                    taskRecord.SalesReminder1Sent__c = true;
                    updateTasks.add(taskRecord);
                    }
                    }
                    }*/
                
                // BRD 7.1 - Reminder #2 // Trigger : 30 Minutes Before Breach // To : Head of Sales
                
                if(head_Of_Sales_Email != null){
                    Datetime secondReminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, objLead.LeadManagerAssignedDate__c, 0.5 );   //
                    System.debug('========== SALES TASK ==========');
                    System.debug('Task Id: ' + taskRecord.Id);
                    System.debug('Subject: ' + taskRecord.Subject);
                    System.debug('SLA: ' + taskRecord.SLADateTime__c);
                    System.debug('Manager: ' + taskRecord.ManagerEmail__c);
                    
                    if(System.now() >= secondReminderTime && System.now() <= secondReminderTime.addMinutes(TIME_WINDOW_MINUTES)){
                        emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(salesReminder2TemplateId,noReplyOWDId,null,taskRecord.WhoId,new List<String>{head_Of_Sales_Email},null,null));
                    }
                }
                
                
                // BRD 7.1 - Reminder #2 (FIXED — flag add kiya + timing corrected)
                 /*if(head_Of_Sales_Email != null){
                        Datetime secondReminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, objLead.LeadManagerAssignedDate__c, 2.5 ); // was 0.5, corrected to 2.5 (3hr SLA - 0.5hr before)
                        
                        System.debug('========== SALES TASK ==========');
                        System.debug('Task Id: ' + taskRecord.Id);
                        System.debug('Subject: ' + taskRecord.Subject);
                        System.debug('SLA: ' + taskRecord.SLADateTime__c);
                        System.debug('Manager: ' + taskRecord.ManagerEmail__c);
                        
                        if(!taskRecord.SalesReminder2Sent__c && System.now() >= secondReminderTime && System.now() <= secondReminderTime.addMinutes(TIME_WINDOW_MINUTES)){
                            emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(salesReminder2TemplateId,noReplyOWDId,null,taskRecord.WhoId,new List<String>{head_Of_Sales_Email},null,null));
                            taskRecord.SalesReminder2Sent__c = true;
                            updateTasks.add(taskRecord);
                        }
                    }*/
                                    
             
                // BRD 7.1 - SLA Breach // Trigger : 3 Working Hours // To : Sales Manager // CC : Head of Sales, Lead Management
              if(!taskRecord.SLABreachSent__c && System.now() > taskRecord.SLADateTime__c && taskRecord.SLAStatus__c.contains('Breached')){
                    
                    List<String> emailAddresses = new List<String>();
                    if(taskRecord.Owner.Email != null){
                        emailAddresses.add(taskRecord.Owner.Email);
                    }
                    if(taskRecord.ManagerEmail__c != null){
                        emailAddresses.add(taskRecord.ManagerEmail__c);
                    }
                    
                    emailAddresses.add(Lead_Management_Email);
                    
                    if(!emailAddresses.isEmpty())
                        emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(salesBreachTemplateId,noReplyOWDId,null,taskRecord.WhoId,emailAddresses,null,null));
                }
                     
                // BRD 7.1 - Head of Sales Decision SLA
                if(objLead.ReshuffleCount__c != null && objLead.ReshuffleCount__c >= 2){
                       
                       // Send Head of Sales email once
                       if(!taskRecord.HoSDecisionSent__c){
                           emailList.add( objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( salesBreachTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{head_Of_Sales_Email}, null, null ) );
                                                                                                            // Better: create HoSDecisionTemplate noReplyOWDId, null, taskRecord.WhatId, new List<String>{head_Of_Sales_Email}, null, null ) );
                           taskRecord.HoSDecisionSent__c = true;
                           updateTasks.add(taskRecord);
                       }
                       
                       // Wait 1 Business Hour
                       else if(!taskRecord.ExecutiveDirectorSent__c){
                          Datetime hosDeadline = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, objLead.LeadManagerAssignedDate__c, 1 );
                           if(System.now() > hosDeadline){
                              emailList.add( objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( executiveDirectorTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{executive_Director_Email}, null, null ) );
                               taskRecord.ExecutiveDirectorSent__c = true;
                               updateTasks.add(taskRecord);
                           }
                       }
                   }
                
                // BRD 7.2 - 3 Day Lead Follow Up SLA
                if(taskRecord.Subject == 'SM - Day 2 Call 1 - Follow Up'|| taskRecord.Subject == 'SM - Day 3 Call 1 - Follow Up'){
                    
                    // Stop SLA if Lead is already completed
                    Set<String> validClosingStatuses = new Set<String>{ 'Waiting Customer Feedback', 'Waiting Next Launch', 'Closed', 'Converted' };
                        if (validClosingStatuses.contains(objLead.Status)) {
                            continue;
                        }
                    
                    // BRD 7.2 - Reminder
                    if(!taskRecord.SLAReminderSent__c && objLead.LeadManagerAssignedDate__c != null){
                        
                        Datetime reminderTime = objBHService.getBusinessReminderTime( taskRecord.BusinessHours__c, taskRecord.AssignedDateTime__c, 8 );
                        
                        System.debug('===== BRD 7.2 DEBUG =====');
                        System.debug('AssignedDateTime = ' + taskRecord.AssignedDateTime__c);
                        System.debug('ReminderTime     = ' + reminderTime);
                        System.debug('CurrentTime      = ' + System.now());
                        System.debug('WindowEnd        = ' + reminderTime.addMinutes(TIME_WINDOW_MINUTES));
                        System.debug('Condition1 (Now >= Reminder) = ' + (System.now() >= reminderTime));
                        System.debug('Condition2 (Now <= Window)   = ' + (System.now() <= reminderTime.addMinutes(TIME_WINDOW_MINUTES)));
                        System.debug('===========================');

                        //N TEST
                        if(System.now() >= reminderTime && System.now() <= reminderTime.addMinutes(TIME_WINDOW_MINUTES)){
                            List<String> emailAddresses = new List<String>();

                            if(taskRecord.Owner.Email != null){
                                emailAddresses.add(taskRecord.Owner.Email);
                            }
                            if(taskRecord.ManagerEmail__c != null){
                                emailAddresses.add(taskRecord.ManagerEmail__c);
                            }
                            
                            // TODO
                            // emailAddresses.add(leadManagementEmail);
                            
                            if(!emailAddresses.isEmpty()){
                                
                                emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(salesReminder3DayTemplateId,noReplyOWDId,null,taskRecord.WhoId,emailAddresses,null,null));
                                taskRecord.SLAReminderSent__c = true;
                                updateTasks.add(taskRecord);
                            }
                        }
                    }
                    
                    // BRD 7.2 - Breach
                    if(!taskRecord.SLABreachSent__c && System.now() > taskRecord.SLADateTime__c && taskRecord.SLAStatus__c.contains('Breached')){
                        
                        List<String> emailAddresses = new List<String>();
                        
                        if(taskRecord.Owner.Email != null)
                            emailAddresses.add(taskRecord.Owner.Email);
                        
                           /* if(taskRecord.ManagerEmail__c != null){
                            emailAddresses.add(taskRecord.ManagerEmail__c);
                            }*/
                        
                        // TODO
                        // emailAddresses.add(leadManagementEmail);
                        
                        emailAddresses.add(head_Of_Sales_Email);
                        emailAddresses.add(Lead_Management_Email);
                        
                        if(!emailAddresses.isEmpty()){
                            
                            emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(sales3DayBreachTemplateId,noReplyOWDId,null,taskRecord.WhoId,emailAddresses,null,null));
                            taskRecord.SLABreachSent__c = true;
                            updateTasks.add(taskRecord);
                        }
                    }
                     
                    // BRD 7.2 - Head of Sales 1 Hour SLA
                    if(taskRecord.SLABreachSent__c && !taskRecord.HoSEscalationSent__c){
                        Datetime hosDeadline = taskRecord.SLADateTime__c.addHours(1);
                        if(System.now() > hosDeadline){
                            emailList.add( objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( sales3DayBreachTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{head_Of_Sales_Email}, null, null ));
                            taskRecord.HoSEscalationSent__c = true;
                            updateTasks.add(taskRecord);
                        }
                    }
                   
                    // BRD 7.2 - Executive Director Escalation
                    if(taskRecord.HoSEscalationSent__c && !taskRecord.ExecutiveDirectorEscalationSent__c){
                        Datetime executiveDeadline = taskRecord.SLADateTime__c.addHours(2);
                        if(System.now() > executiveDeadline){
                            emailList.add( objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( executiveDirectorTemplateId, noReplyOWDId, null, taskRecord.WhoId, new List<String>{executive_Director_Email}, null, null ));
                            taskRecord.ExecutiveDirectorEscalationSent__c = true;
                            updateTasks.add(taskRecord);
                        }
                    }
                }
                
            }
            //}
        } 
        
        // Send Emails
        if(!emailList.isEmpty()){
            objEmailService.sendEmail(emailList);
        }
        
        // Update Tasks
        if(!updateTasks.isEmpty()){
            objActivityService.updateTasksWithoutTrigger(updateTasks);
        }
        /* }
catch (Exception ex) {
System.debug('Error in FirstContactSLABatch: ' + ex.getMessage());
}*/
    }
    public void execute(SchedulableContext sc){
        Database.executeBatch(new LeadSLAReminderBatch(), 200);
    }
    public void finish(Database.BatchableContext bc) {
        //  System.debug('First Contact SLA Batch Completed');
    }
    
}
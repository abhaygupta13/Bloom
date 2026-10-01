/*
* @Author: Biswajeet Samal
* @CreatedDate: 13th AUG 2024
* @Description: Utility
*/
/*****************************************************************************************************
* Version       Author        Date             Comment                                           METHOD Name                              
* 1.0           Biswajeet     24NOV2024        Initial draft 
* 1.1           Shruti        04OCTOMBER2025   Check if a record exists in org based on Id
* 1.2			Dhanraj		  20NOV2025		   Added 2 new methods for date and currency
* 1.3           Prashant Sahu 16march2026      Added 1 new Method for  SLA Calculation /        handleBeforeUpdate 
*****************************************************************************************************/
public  without sharing class TaskTriggerHelper {
    
    public static DateTime getduedateTime;
    private static final string TASK_SUBJECT_CC_DAY_1_CALL_1 { get { return 'CC - Day 1 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_SM_DAY_1_CALL_1 { get { return 'SM - Day 1 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_LO_DAY_1_CALL_1 { get { return 'LO - Day 1 Call 1 - Follow Up'; } }
    private static final string CUSTOMER_NOT_REACHABLE { get { return 'Customer Not Reachable'; } }
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }
    private static final string MTD_ADHA_NOT_ANSWERING_EMAIL_TEMPLATE { get { return 'ADHACustomerNotAnsweringBloomCalls'; } }
    
    public static void updatLeadStatusOnTaskComplete(List<Task>newTasks){
        Set<Id>leadIds = new Set<Id>();
        Map<Id,Task> mapCompletedCCTask = new Map<Id,Task>();
        Map<Id,Task> mapCompletedSMTask = new Map<Id,Task>();
        LeadService objLeadService = LeadService.getInstance();
        
        for(Task tsk:newTasks){
            if(tsk.Status == 'Completed' && tsk.WhoId != NULL && tsk.WhoId.getSObjectType() == Lead.SobjectType){
                leadIds.add(tsk.WhoId);
                if(tsk.Subject.contains(TASK_SUBJECT_CC_DAY_1_CALL_1)){
                    mapCompletedCCTask.put(tsk.WhoId,tsk);
                }
                if((tsk.Subject.contains(TASK_SUBJECT_SM_DAY_1_CALL_1) || tsk.Subject.contains(TASK_SUBJECT_LO_DAY_1_CALL_1))){
                    mapCompletedSMTask.put(tsk.WhoId,tsk);
                }
            }
        }
        if(!leadIds.isEmpty()){
            List<Lead> leadList = objLeadService.getLeadByIds(leadIds);
            for(Lead objLead:leadList){
                if(mapCompletedCCTask != null && mapCompletedCCTask.containsKey(objLead.Id) && (objLead.ContactCentreLeadStatus__c == 'New' || String.isBlank(objLead.ContactCentreLeadStatus__c))){
                    objLead.ContactCentreLeadStatus__c = 'In Progress';
                }
                if(mapCompletedSMTask != null && mapCompletedSMTask.containsKey(objLead.Id) && (objLead.LeadManagerStatus__c == 'New' || String.isBlank(objLead.LeadManagerStatus__c))){
                    objLead.LeadManagerStatus__c = 'In Progress';
                }
            }
            objLeadService.updateLeadsWithoutTrigger(leadList);
        }
    }
    
    public static void handleBeforeInsert(List<Task> newList){
        UserService objUserService = UserService.getInstance();
        Set<Id> relatedCaseIds = new Set<Id>();
        Id tempBussinessHoursId;
        Id defaultBHId = MetadataService.getInstance().getAppSettingTextValue('DefaultBusinessHoursId');
        Set<Id> userOwnerIds = new Set<Id>();
        Map<Id, User> ownerIdToUserMap = new Map<Id, User>();
        
        for (Task tsk : newList) {
            if (tsk.OwnerId != Null && ( tsk.BusinessHours__c == null || tsk.BusinessHours__c == defaultBHId) && tsk.OwnerId.getSObjectType() == User.SObjectType) {
                userOwnerIds.add(tsk.OwnerId);
            }
        }
        if(!userOwnerIds.isEmpty()){
            ownerIdToUserMap = new Map<Id, User>(objUserService.getUsersByIds(userOwnerIds));
        }
        for (Task tsk : newList) {
            tsk.AssignedDateTime__c = System.now();
            
            // Identify Task records related to Cases
            if (tsk.WhatId != null && tsk.WhatId.getSObjectType() == Case.SObjectType) {
                relatedCaseIds.add(tsk.WhatId);
            }
            if(tsk.SLADateTime__c == Null && tsk.OwnerId.getSObjectType() == User.SObjectType){
                tempBussinessHoursId = tsk.BusinessHours__c != null && tsk.BusinessHours__c != defaultBHId ? tsk.BusinessHours__c : ownerIdToUserMap != null && ownerIdToUserMap.containskey(tsk.OwnerId) && ownerIdToUserMap.get(tsk.OwnerId).BusinessHour__c != null ? ownerIdToUserMap.get(tsk.OwnerId).BusinessHour__c : defaultBHId;
                if(tsk.AssignedDateTime__c != null && tempBussinessHoursId != null){
                    tsk.SLADateTime__c = Utility.calculateSLAEndDate( tempBussinessHoursId, tsk.AssignedDateTime__c, tsk.SLAHours__c);
                    tsk.BusinessHours__c = tempBussinessHoursId;
                }
            }
        }
        
        if (relatedCaseIds.isEmpty()) return;
        populateCaseFields(newList,relatedCaseIds);
        
    }
    public static void handleBeforeUpdate(List<Task> newList, Map<Id,Task> oldMap){
        UserService objUserService = UserService.getInstance();
        Id tempBussinessHoursId;
        Id defaultBHId = MetadataService.getInstance().getAppSettingTextValue('DefaultBusinessHoursId');
        Set<Id> userOwnerIds = new Set<Id>();
        Map<Id, User> ownerIdToUserMap = new Map<Id, User>();
        
        for (Task tsk : newList) {
            Task oldTask = oldMap.get(tsk.Id);
            if ((tsk.OwnerId != Null && ( tsk.BusinessHours__c == null || tsk.BusinessHours__c == defaultBHId) && tsk.OwnerId.getSObjectType() == User.SObjectType) && (tsk.AssignedDateTime__c != oldTask.AssignedDateTime__c || tsk.SLAHours__c != oldTask.SLAHours__c || (tsk.OwnerId != oldTask.OwnerId && oldTask.OwnerId.getSObjectType() != User.SObjectType) ) ){ 
                userOwnerIds.add(tsk.OwnerId);
            }
            if(tsk.Status == 'Completed' && tsk.Status != oldTask.Status){
                tsk.CompletedDateTime__c = System.now();
            }
        }

        if(!userOwnerIds.isEmpty()){
            ownerIdToUserMap = new Map<Id, User>(objUserService.getUsersByIds(userOwnerIds));
        }

        for(Task tsk : newList){
            Task oldTask = oldMap.get(tsk.Id);
            Id ownerBussinessHoursId = ownerIdToUserMap != null && ownerIdToUserMap.containskey(tsk.OwnerId) && ownerIdToUserMap.get(tsk.OwnerId).BusinessHour__c != null ? ownerIdToUserMap.get(tsk.OwnerId).BusinessHour__c : null;
            tempBussinessHoursId = tsk.BusinessHours__c != null ? tsk.BusinessHours__c : ownerIdToUserMap != null && ownerIdToUserMap.containskey(tsk.OwnerId) && ownerIdToUserMap.get(tsk.OwnerId).BusinessHour__c != null ? ownerIdToUserMap.get(tsk.OwnerId).BusinessHour__c : defaultBHId;
            Boolean reProccessSLAEndTime = false;
            if( tsk.BusinessHours__c != oldTask.BusinessHours__c && tsk.BusinessHours__c != defaultBHId){
                    reProccessSLAEndTime = true;
            }
            if(  ( tsk.BusinessHours__c == null || tsk.BusinessHours__c == defaultBHId) &&  ownerBussinessHoursId != null && ownerBussinessHoursId != defaultBHId ){
                tempBussinessHoursId = ownerBussinessHoursId;
                tsk.BusinessHours__c = ownerBussinessHoursId;
                reProccessSLAEndTime = true;
            }
            if( reProccessSLAEndTime || tsk.AssignedDateTime__c != oldTask.AssignedDateTime__c || tsk.SLAHours__c != oldTask.SLAHours__c || (tsk.OwnerId != oldTask.OwnerId  && tsk.OwnerId.getSObjectType() == User.SObjectType && oldTask.OwnerId.getSObjectType() != User.SObjectType) ){ 
                if(tsk.AssignedDateTime__c != null && tsk.SLAHours__c != null && tempBussinessHoursId != null){      
                    tsk.SLADateTime__c = Utility.calculateSLAEndDate( tempBussinessHoursId, tsk.AssignedDateTime__c, tsk.SLAHours__c );
                }
            }
        }
    }
    
    public static void populateCaseFields(List<Task> newList,Set<Id> caseIds) {
        // Query relevant Case records
        CaseService caseServiceObj = CaseService.getInstance();
        Map<Id, Case> caseMap = new Map<Id, Case>(caseServiceObj.getCaseByIds(caseIds));
        
        // Populate Task fields using related Case values
        for (Task newTsk : newList) {
            if (newTsk.WhatId != null && caseMap.containsKey(newTsk.WhatId)) {
                Case caseObj = caseMap.get(newTsk.WhatId);
                newTsk.ServiceRequestType__c = caseObj.RecordType != null ? caseObj.RecordType.Name : null;
                newTsk.Unit__c = caseObj.Unit__c;
            }
        }
    }

/**
 * @description Handles Task records after insert and identifies ADHA Lead-related activities
 *              where the customer response is marked as not reachable.
 *              The related Lead Ids are collected and passed for creation of the first follow-up task.
 *
 * @param newTaskList List of newly inserted Task records.
 */
    public static void handleAfterInsert(List<Task> newTaskList) {
        List<Id> leadIds = new List<Id>();
        for (Task objTask : newTaskList) {
            if(objTask.CustomerResponse__c == CUSTOMER_NOT_REACHABLE && objTask.WhoId.getSObjectType() == Lead.SObjectType) {
                leadIds.add(objTask.WhoId);
            }
        }

        if(!leadIds.isEmpty()) {
            sendADHAUnreachableNotifications(leadIds);
        }
    }

    /**
 * @description Creates the first follow-up Task for ADHA Leads.
 * The Task is created as an SM or LO follow-up based on the Lead Team, with the Task Owner set same as Lead Owner. Business Hours, SLA,
 * due date, subject, and subtype are calculated and assigned accordingly.
 *
 * @param leadIds List of ADHA Lead record IDs for which the first follow-up Task needs to be created.
 */
    private static void sendADHAUnreachableNotifications(List<Id> leadIds) {

        List<Lead> adhaLeads = LeadService.getInstance().getADHALeadByIds(new Set<Id>(leadIds));
        Set<Id> adhaLeadIds = new Set<Id>();

        if (!adhaLeads.isEmpty()) {
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();

            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
            Id notAnsweringEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_ADHA_NOT_ANSWERING_EMAIL_TEMPLATE);

            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            EmailTemplate et = objEmailService.getEmailTemplateById(notAnsweringEmailTemplateId);

            for (Lead objADHALead : adhaLeads) {
                adhaLeadIds.add(objADHALead.Id);

                if (String.isNotBlank(objADHALead.Email)) {
                    String body = et.HtmlValue;
                    body = body.replace('[AM Name]', objADHALead.OwnerId != null ? objADHALead.Owner.Name : '');
                    body = body.replace('[AM Number]', objADHALead.OwnerId != null && String.isNotBlank(objADHALead.Owner.Phone) ? objADHALead.Owner.Phone : '');
                    
                    EmailService.EmailWrapper wrapper = new EmailService.EmailWrapper(false, false, false, true, true, false, false, true, false, true, true);
                    wrapper.subject = et.Subject;
                    wrapper.htmlBody = body;
                    wrapper.orgWideEmailAddressId = noReplyOWDId;
                    wrapper.shoudlSaveAsActivity = true;
                    wrapper.targetObjectId = objADHALead.Id;
                    wrapper.shouldSetTreatTargetObjectAsRecipient = true;
                    wrapper.shouldTreatTargetObjectAsRecipient = true;
                    emailList.add(objEmailService.buildSingleEmailMessage(wrapper));
                }
            }

            if (!emailList.isEmpty()) {
                objEmailService.sendEmail(emailList);
            }
            if (!adhaLeadIds.isEmpty()) {
                LeadAsyncTriggerHelper.sendADHALeadSMSNotification(adhaLeadIds, 'ADHA Lead Not Answering Bloom Calls SMS Notification');
            }   
        }
    }
    
}
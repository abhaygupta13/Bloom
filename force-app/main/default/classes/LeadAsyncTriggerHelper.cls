/***
Class       : LeadAsyncTriggerHandler
Author      : Smaartt
Description : 
TestClass   : LeadAsyncTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
* 1.1       prashant Sahu      30April2026      leadEmailNotificationToCustomer 
****************************************************************************************************************/
public without sharing class LeadAsyncTriggerHelper {
    
    private static final string CONTACT_CENTER_PROFILE_ID { get { return 'ContactCentreProfileId'; } }
    //private static final string SALES_MANAGER_PROFILE_ID { get { return 'SalesManagerProfileIds'; } }
    //private static final string LEASING_TEAM_PROFILE_ID { get { return 'LeasingTeamProfileIds'; } }
    private static final string DEFAULT_BUSINESS_HOURS_ID { get { return 'DefaultBusinessHoursId'; } }
    private static final string LEAD_STATUS_INPROGRESS { get { return 'In Progress'; } }
    private static final string TASK_SUBJECT_CC_DAY_1_CALL_1 { get { return 'CC - Day 1 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_1_CALL_1 { get { return 'Day 1 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_2_CALL_1 { get { return 'Day 2 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_3_CALL_1 { get { return 'Day 3 Call 1 - Follow Up'; } }
    private static final string TASK_DESCRIPTION { get { return 'Follow up with this lead to qualify their interest.'; } }
    private static final string TASK_COMPLETED_DESCRIPTION { get { return 'Completed Task by automation'; } }
    private static final string TASK_STATUS { get { return 'Open'; } }
    private static final string TASK_COMPLETED_STATUS { get { return 'Completed'; } }
    private static final string TASK_TYPE { get { return 'Call'; } }
    private static final string TASK_PRIORITY { get { return 'Normal'; } }
    private static final string LEAD_CC_STATUS_QUALIFIED { get { return 'Qualified'; } }
    private static final string LEAD_TEAM { get { return 'Sales'; } }
    private static final string SALES_TASK_SUBJECT { get { return 'SM'; } }
    private static final string LEASING_TASK_SUBJECT { get { return 'LO'; } }
    private static final string LEAD_LM_STATUS_CONVERTED { get { return 'Converted'; } }
    private static final string LEAD_LM_STATUS_RETIRED { get { return 'Retired'; } }
    private static final string LEAD_LM_STATUS_FOLLOWUP { get { return 'Follow Up'; } }
    private static final string LEAD_LM_STATUS_WAITINGLIST { get { return 'Waiting List'; } }
    
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }
    private static final string MTD_Default_Lead_Email_Notification{ get { return 'DefaultLeadEmailNotification'; } }
    
    private static final String MTD_Reception_With_Broker { get { return 'LeadReceptionWithBrokerEmailTemplate'; } }
    private static final String MTD_Reception_Without_Broker { get { return 'LeadEmailTemplateReceptionistTeam'; } }
    private static final String MTD_SalesManager_With_Broker { get { return 'LeadSalesManagerWithBrokerEmailTemplate'; } }
    private static final String MTD_SalesManager_Without_Broker { get { return 'LeadSalesManagerEmailTemplate'; } }
    private static final String MTD_ContactCenter_Sales { get { return 'SalesLeadContactCenterTeamEmailTemplate'; } }
    private static final String MTD_ContactCenter_Leasing { get { return 'LeasingLeadContactCenterTeamEmailTemp'; } }
    
    private static final String MTD_SLA_FIRST_CONTACT_HOURS { get { return 'SLAFirstContactHours'; } }
    
    public static void leadEmailNotificationToCustomer(List<Id> leadIds){
       
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        Id emailTemplateDefaultIds= objMetadataService.getAppSettingTextValue(MTD_Default_Lead_Email_Notification); 
        Id receptionWithBrokerId = objMetadataService.getAppSettingTextValue(MTD_Reception_With_Broker);
        Id receptionWithoutBrokerId = objMetadataService.getAppSettingTextValue(MTD_Reception_Without_Broker);
        Id salesManagerWithBrokerId = objMetadataService.getAppSettingTextValue(MTD_SalesManager_With_Broker);
        Id salesManagerWithoutBrokerId = objMetadataService.getAppSettingTextValue(MTD_SalesManager_Without_Broker);
        Id contactCenterSalesId = objMetadataService.getAppSettingTextValue(MTD_ContactCenter_Sales);
        Id contactCenterLeasingId = objMetadataService.getAppSettingTextValue(MTD_ContactCenter_Leasing);
       
        List<Lead> leadList = objLeadService.getLeadByIds(new Set<Id>(leadIds));
        for(Lead objLead :leadList){
            String emailTemplateId;
            if (objLead.CreatedBy.Profile.Name == 'Reception Team') {
                emailTemplateId = (objLead.BrokerAgency__c != null && objLead.BrokerAgent__c != null) ? receptionWithBrokerId :receptionWithoutBrokerId;
            } 
            else if (objLead.CreatedBy.Profile.Name == 'Sales Manager') {
                emailTemplateId = (objLead.BrokerAgency__c != null && objLead.BrokerAgent__c != null)  ? salesManagerWithBrokerId :salesManagerWithoutBrokerId;
            } 
            else if (objLead.CreatedBy.Profile.Name == 'Contact Centre Team') {
                if (objLead.LeadTeam__c == 'Sales') {
                    emailTemplateId = contactCenterSalesId;
                } 
                else if (objLead.LeadTeam__c == 'Leasing') {
                    emailTemplateId = contactCenterLeasingId;
                } 
            }else{
                System.debug('emailTemplateDefaultIds'+emailTemplateDefaultIds);
                emailTemplateId=emailTemplateDefaultIds;
            }
            
            if(emailTemplateId != null){
               emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( emailTemplateId, noReplyOWDId, null, objLead.Id, Null, Null, Null )); 
            }
        }
        objEmailService.sendEmail(emailList);

    }
    
    public static void createContactCenterLeadTask(List<Id> leadIds){
        MetadataService objMetadataService = MetadataService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        UserService objUserService = UserService.getInstance();
        
        LeadService objLeadService = LeadService.getInstance();
        List<Lead> leadNewList = objLeadService.getLeadByIds(new Set<Id>(leadIds));
        if(!leadNewList.isEmpty()){
            Id defaultBHId = objMetadataService.getAppSettingTextValue(DEFAULT_BUSINESS_HOURS_ID);
            Date nextBusinessDate = objBHService.getNextBusinessDate(defaultBHId, System.now());
            Integer slaHours = objMetadataService.getAppSettingNumberValue(MTD_SLA_FIRST_CONTACT_HOURS);
            Integer reminderBeforeHours =   1;  // objMetadataService.getAppSettingNumberValue(MTD_SLA_FIRST_CONTACT_HOURS);  // 3 hours
            String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
            List<Id> contactCentreProfileIdList = contactCentreProfileIds.split(',');
            Set<Id> leadIdSet = new Set<Id>();
            Map<Id, Task> taskMap = new Map<Id, Task>();
            Set<Id> userOwnerIds = new Set<Id>();
            
            for (Lead objLead : leadNewList) {
                if(objLead.Owner.profileId != null && objLead.Status == LEAD_STATUS_INPROGRESS && contactCentreProfileIdList.contains(objLead.Owner.profileId) ){
                    leadIdSet.add(objLead.Id);
                }
            }
            
            if(!leadIdSet.isEmpty()){
                taskMap = objActivityService.getTasksBySubjectAndWhoId(leadIdSet, TASK_SUBJECT_CC_DAY_1_CALL_1);
            }
            
            List<Task> taskList = new List<Task>();
            Task objTask;
            for(Lead objLead :leadNewList){
                system.debug('leadNewList data ---'+leadNewList);
                if(objLead.Owner.profileId != null && objLead.Status == LEAD_STATUS_INPROGRESS  && !taskMap.containsKey(objLead.Id) && contactCentreProfileIdList.contains(objLead.Owner.profileId) ){
                    Id tempBussinessHourId =  objLead.BusinessHour__c != null ? objLead.BusinessHour__c : defaultBHId;
                    DateTime slaDateTime = Utility.calculateSLAEndDate( tempBussinessHourId, DateTime.now(), slaHours);
                    objTask = objActivityService.getActivityWithSLA(TASK_SUBJECT_CC_DAY_1_CALL_1, System.today(), 
                                                                    Date.today(), TASK_DESCRIPTION, 
                                                                    TASK_STATUS, TASK_TYPE, TASK_PRIORITY, 1, objLead.OwnerId, objLead.Id, slaDateTime, tempBussinessHourId, slaHours, reminderBeforeHours);  
                    taskList.add(objTask);
                }
            }
                 objActivityService.insertTasks(taskList);
            //objActivityService.insertTasksWithoutTrigger(taskList);
            
        }
    }
    
    public static void createQualifiedSMAndLOLeadTask(List<Id> leadIds){
        System.debug('createQualifiedLeadTask method is Runing');
        System.debug('leadIds'+leadIds);
        MetadataService objMetadataService = MetadataService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        Id defaultBHId = objMetadataService.getAppSettingTextValue(DEFAULT_BUSINESS_HOURS_ID);
        Date nextBusinessDate = objBHService.getNextBusinessDate(defaultBHId,System.now());
        Integer slaHours = 24 ;// objMetadataService.getAppSettingNumberValue(MTD_SLA_FIRST_CONTACT_HOURS);
        Integer reminderBeforeHours = 8 ;//objMetadataService.getAppSettingNumberValue(MTD_SLA_FIRST_CONTACT_HOURS);  // 8 hours
            
        LeadService objLeadService = LeadService.getInstance();
        List<Lead> qualifiedLeads = new List<Lead>();
        qualifiedLeads = objLeadService.getLeadByIds(new Set<Id>(leadIds));
        if(!qualifiedLeads.isEmpty()){
            List<Task> taskList = new List<Task>();
            for(Lead newLead: qualifiedLeads){
                if(newLead.ContactCentreLeadStatus__c == LEAD_CC_STATUS_QUALIFIED ){
                    Id tempBussinessHourId =  newLead.BusinessHour__c != null ? newLead.BusinessHour__c : defaultBHId;
                    DateTime slaDateTime = Utility.calculateSLAEndDate( tempBussinessHourId, DateTime.now(), slaHours);
                    System.debug('### Calculated SLA = ' + slaDateTime);
                    Task objTask = objActivityService.getActivityWithSLA(newLead.LeadTeam__c == LEAD_TEAM ? SALES_TASK_SUBJECT+' - '+TASK_SUBJECT_DAY_1_CALL_1 : LEASING_TASK_SUBJECT+' - '+TASK_SUBJECT_DAY_1_CALL_1, System.today(), 
                                                                         nextBusinessDate , TASK_DESCRIPTION, 
                                                                         TASK_STATUS, TASK_TYPE, TASK_PRIORITY, 1, newLead.OwnerId, newLead.Id, slaDateTime, tempBussinessHourId, slaHours, reminderBeforeHours);
                    System.debug('objTask------'+objTask);
                    System.debug('newLead.CreatedById'+newLead.CreatedById);
                    System.debug('CreatedByName: ' + newLead.CreatedBy.Name);
                    System.debug('### Task SLA Before Insert = ' + objTask.SLADateTime__c);
                    taskList.add(objTask);
                }
            }
                        objActivityService.insertTasks(taskList);
            //objActivityService.insertTasksWithoutTrigger(taskList);
            
        }
    }
    public static void createSMAndLOLeadTask(List<Id> leadIds){
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        Id defaultBHId = objMetadataService.getAppSettingTextValue(DEFAULT_BUSINESS_HOURS_ID);
        //Integer slaHours = objMetadataService.getAppSettingNumberValue(MTD_SLA_FIRST_CONTACT_HOURS);
        Integer slaHours = 3;
        Integer reminderBeforeHours = 1  ; ///objMetadataService.getAppSettingNumberValue(MTD_SLA_FIRST_CONTACT_HOURS); // 1 hour
        
        Set<Id> setLeadIds = new Set<Id>();
        List<Task> taskList = new List<Task>();
        
        List<Lead> leadList = new List<Lead>();
        leadList = objLeadService.getLeadByIds(new Set<Id>(leadIds));
        if(!leadList.isEmpty()){
            for(Lead objLead : leadList){
                if((objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP || objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST)){
                    setLeadIds.add(objLead.Id);
                }
            }
            Map<Id,Lead> mapLeadWithOpenActivity = new Map<Id,Lead>();
            Map<Id,Lead> mapLeadWithClosedActivity = new Map<Id,Lead>();
            if(!setLeadIds.isEmpty()){
                mapLeadWithOpenActivity = new Map<Id,Lead>(objLeadService.getLeadWithOpenActivity(setLeadIds));
                mapLeadWithClosedActivity = new Map<Id,Lead>(objLeadService.getLeadWithClosedActivity(setLeadIds));
            }    
            List<Task> lstOpenTask;
            List<Task> lstClosedTask;
            for(Lead objLead : leadList){
                if( objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP || objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST ){
                    lstOpenTask = new List<Task>();
                    lstClosedTask = new List<Task>();
                    if(mapLeadWithOpenActivity != NULL && mapLeadWithOpenActivity.containsKey(objLead.Id)){
                        if (mapLeadWithOpenActivity.get(objLead.Id).Tasks != null) {
                            lstOpenTask.addAll(mapLeadWithOpenActivity.get(objLead.Id).Tasks);
                        } 
                    }
                    if(mapLeadWithClosedActivity != NULL && mapLeadWithClosedActivity.containsKey(objLead.Id)){
                        if (mapLeadWithClosedActivity.get(objLead.Id).Tasks != null) {
                            lstClosedTask.addAll(mapLeadWithClosedActivity.get(objLead.Id).Tasks);
                        } 
                    }
                    if(!lstOpenTask.isEmpty()){
                        for(Task objTask : lstOpenTask){
                            if(objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP){
                                if (objTask.Subject.contains('LO - Day') || objTask.Subject.contains('SM - Day')){
                                    objTask.ActivityDate = objLead.FollowUpDate__c;
                                    objTask.SLABreached__c = true;
                                    objTask.Description = TASK_COMPLETED_DESCRIPTION;
                                    objTask.Status = TASK_COMPLETED_STATUS;
                                    taskList.add(objTask);
                                    break;
                                }
                            }else if(objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST){
                                if (objTask.Subject.contains('LO - Day') || objTask.Subject.contains('SM - Day')){
                                    objTask.ActivityDate = objLead.WaitingListDate__c;
                                    taskList.add(objTask); 
                                    objTask.SLABreached__c = true;
                                    objTask.Description = TASK_COMPLETED_DESCRIPTION;
                                    objTask.Status = TASK_COMPLETED_STATUS;
                                    
                                    break;
                                }
                            }
                        }
                    }
                    else if(!lstClosedTask.isEmpty()){
                        String subject = null;
                        for(Task objTask : lstClosedTask){
                            if(objTask.subject.contains(TASK_SUBJECT_DAY_1_CALL_1) || objTask.subject.contains(TASK_SUBJECT_DAY_2_CALL_1) || objTask.subject.contains(TASK_SUBJECT_DAY_3_CALL_1)){
                                subject = objTask.subject.contains(TASK_SUBJECT_DAY_1_CALL_1)? TASK_SUBJECT_DAY_2_CALL_1 
                                    : objTask.subject.contains(TASK_SUBJECT_DAY_2_CALL_1)? TASK_SUBJECT_DAY_3_CALL_1: null;
                            }
                        }
                        if(subject != null){
                            Date activityDateVal = (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP) ? objLead.FollowUpDate__c     : (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST ? objLead.WaitingListDate__c : null);
                                Integer reshuffleCount = objLead.ReshuffleCount__c == null ? 0 : Integer.valueOf(objLead.ReshuffleCount__c);
                            
                            if (reshuffleCount < 2) {
                                slaHours = 1;
                                reminderBeforeHours = null ;
                            }
                            Id tempBussinessHourId =  objLead.BusinessHour__c != null ? objLead.BusinessHour__c : defaultBHId;
                            DateTime slaDateTime = Utility.calculateSLAEndDate( tempBussinessHourId, DateTime.now(), slaHours);
                            Task objNewTask = objActivityService.getActivityWithSLA(objLead.LeadTeam__c == LEAD_TEAM ? SALES_TASK_SUBJECT+' - '+subject : LEASING_TASK_SUBJECT+' - '+subject, 
                                                                                    activityDateVal, activityDateVal, TASK_DESCRIPTION, 
                                                                                    TASK_STATUS, TASK_TYPE, TASK_PRIORITY, 1, objLead.OwnerId, objLead.Id, slaDateTime, tempBussinessHourId, slaHours, reminderBeforeHours);
                            taskList.add(objNewTask);  
                        }
                    }
                }  
            }
                 objActivityService.upsertTasks(taskList);
            //objActivityService.upsertTasksWithoutTrigger(taskList);
            
        }
    }
    
    /*
    public static void updateAssignedDate(List<Id> leadIds) {
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        List<Id> contactCentreProfileIdList = contactCentreProfileIds.split(',');
        String salesManagerProfileIds = objMetadataService.getAppSettingTextValue(SALES_MANAGER_PROFILE_ID);
        List<Id> salesManagerProfileIdList = salesManagerProfileIds.split(',');
        String leasingTeamProfileIds = objMetadataService.getAppSettingTextValue(LEASING_TEAM_PROFILE_ID);
        List<Id> leasingTeamProfileIdList = leasingTeamProfileIds.split(',');
        List<Lead> leadNewList = new List<Lead>();
        
        List<Lead> leadList = objLeadService.getLeadByIds(new Set<Id>(leadIds));
        
        for(Lead objLead :leadList){
            String profileId = (objLead.Owner.profileId != null ? String.valueOf(objLead.Owner.profileId).substring(0, 15) : null);
            if(profileId != null){
                if(contactCentreProfileIdList.contains(profileId)){
                    objLead.ContactCenterAssignedDate__c = System.now();
                    leadNewList.add(objLead);
                }
                if(salesManagerProfileIdList.contains(profileId) || leasingTeamProfileIdList.contains(profileId)){
                    objLead.LeadManagerAssignedDate__c = System.now();
                    leadNewList.add(objLead);
                }
            }
        }
        
        objLeadService.updateLeadsWithoutDuplicateRule(leadNewList);
    }
    */
    
}
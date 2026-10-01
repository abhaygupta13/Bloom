/*****************************************************************************************
Class       : LeadService
Author      : Biswajeet
Description :Lead Trigger Helper class
test Class: LeadTriggerHandlerTest
Created Date: 29 AUG 2024
*****************************************************************************************/

public without sharing class LeadTriggerHelper {
    
    private static final string LEAD_SOURCE_SOCIAL_MEDIA_CAMPAIGN { get { return 'Social Media'; } }
    private static final string MARKETING_LEAD_CREATED_BY_IDS { get { return 'MarketingLeadCreatedByIds'; } }
    private static final string CONTACT_CENTER_LEAD_QUEUE_ID { get { return 'ContactCenterLeadQueueId'; } }
    private static final string CONTACT_CENTER_PROFILE_ID { get { return 'ContactCentreProfileId'; } }
    private static final string LEASING_TEAM_PROFILE_ID { get { return 'LeasingTeamProfileIds'; } }
    private static final string SALES_MANAGER_PROFILE_ID { get { return 'SalesManagerProfileIds'; } }
    private static final string MTD_NO_REPLY_SALESIT_OWEID_SETTING { get { return 'NoReplySalesIT'; } }
    private static final string MTD_NO_REPLY_LEASING_OWEID_SETTING { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string MTD_LEAD_ASSIGNED_EMAIL_TEMPLATE_ID { get { return 'LeadAssignedEmailTemplateId'; } }
    private static final string MTD_LEAD_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'LeadCreatedEmailTemplateId'; } }
    
    private static final string TASK_SUBJECT_CC_DAY_1_CALL_1 { get { return 'CC - Day 1 Call 1 - Follow Up'; } }
    private static final string LEAD_STATUS_NEW { get { return 'New'; } }
    private static final string LEAD_STATUS_INPROGRESS { get { return 'In Progress'; } }
    private static final string LEAD_CC_STATUS_QUALIFIED { get { return 'Qualified'; } }
    private static final string LEAD_CC_STATUS_DISQUALIFIED { get { return 'Disqualified'; } }
    private static final string LEAD_LM_STATUS_CONVERTED { get { return 'Converted'; } }
    private static final string LEAD_LM_STATUS_RETIRED { get { return 'Retired'; } }
    private static final string LEAD_LM_STATUS_FOLLOWUP { get { return 'Follow Up'; } }
    private static final string LEAD_LM_STATUS_WAITINGLIST { get { return 'Waiting List'; } }
    private static final string TASK_DESCRIPTION { get { return 'Follow up with this lead to qualify their interest.'; } }
    private static final string TASK_COMPLETED_DESCRIPTION { get { return 'Completed Task'; } }
    private static final string TASK_STATUS { get { return 'Open'; } }
    private static final string TASK_COMPLETED_STATUS { get { return 'Completed'; } }
    private static final string TASK_TYPE { get { return 'Call'; } }
    private static final string TASK_PRIORITY { get { return 'Normal'; } }
    private static final string LEAD_TEAM { get { return 'Sales'; } }
    private static final string SALES_TASK_SUBJECT { get { return 'SM'; } }
    private static final string LEASING_TASK_SUBJECT { get { return 'LO'; } }
    private static final string DEFAULT_BUSINESS_HOURS_ID { get { return 'DefaultBusinessHoursId'; } }
    private static final string DUPLICATE_CHECK_EXCLUDE_VALUE { get { return 'Yes'; } }
    private static final string EXCLUDE_DUPLICATE_LEAD_STATUS { get { return 'ExcludeDuplicateLeadStatusValue'; } }
    private static final string DIGITAL_LEAD_CREATED_BY_PROFILE_ID { get { return 'DigitalLeadCreatedByProfileIds'; } }
    private static final string TASK_SUBJECT_DAY_1_CALL_1 { get { return 'Day 1 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_2_CALL_1 { get { return 'Day 2 Call 1 - Follow Up'; } }
    private static final string TASK_SUBJECT_DAY_3_CALL_1 { get { return 'Day 3 Call 1 - Follow Up'; } }
    private static final string LEAD_WAITING_LIST_UPDATE_EMAIL {get { return 'LeasingLeadWaitingListEmail';}}
    private static final string LEASING_LEAD_TEAM {get { return 'Leasing';}}
    
    public static DateTime getduedateTime;
    private static Map<Id, Id> unitAvailabilityLastValidatedFor = new Map<Id, Id>();
    
    public static void createNewContactCenterLeadTask(List<Lead> newList, Map<Id, Lead> oldMap){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        UserService objUserService = UserService.getInstance();
        
        Id defaultBHId = objMetadataService.getAppSettingTextValue(DEFAULT_BUSINESS_HOURS_ID);
        Date nextBusinessDate = objBHService.getNextBusinessDate(defaultBHId, System.now());
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        List<Id> contactCentreProfileIdList = contactCentreProfileIds.split(',');
        Set<Id> leadIdSet = new Set<Id>();
        Map<Id, Task> taskMap = new Map<Id, Task>();
        Set<Id> userOwnerIds = new Set<Id>();
        Map<Id, User> ownerIdToUserMap = new Map<Id, User>();
        
        for(Lead objLead : newList){
            if (objLead.OwnerId != oldMap.get(objLead.Id).OwnerId && objLead.OwnerId.getSObjectType() == User.SObjectType) {
                userOwnerIds.add(objLead.OwnerId);
            }
        }
        
        if(!userOwnerIds.isEmpty()){
            ownerIdToUserMap = new Map<Id, User>(objUserService.getUsersByIds(userOwnerIds));
        }
        
        String profileId;
        String profileIdNew;
        for (Lead objLead : newList) {
            if (ownerIdToUserMap.containsKey(objLead.OwnerId)) {
                profileId = String.valueOf(ownerIdToUserMap.get(objLead.OwnerId).ProfileId);
                profileIdNew = profileId.substring(0,15);
                if(objLead.Status == LEAD_STATUS_INPROGRESS && objLead.OwnerId != oldMap.get(objLead.Id).OwnerId &&
                   objLead.OwnerId.getsObjectType() == User.SobjectType && contactCentreProfileIdList.contains(profileIdNew)){
                       leadIdSet.add(objLead.Id);
                   }
            }
        }
        
        if(!leadIdSet.isEmpty()){
            taskMap = objActivityService.getTasksBySubjectAndWhoId(leadIdSet, TASK_SUBJECT_CC_DAY_1_CALL_1);
        }
        
        List<Task> taskList = new List<Task>();
        Task objTask;
        for(Lead objLead :newList){
            Boolean isADHALead = objLead.Lead_Channel__c == 'API Integration' && objLead.LeadSource == 'Government Entity' && objLead.leadsubsource__c == 'ADHA' && objLead.ApplicationNumber__c != null;
            if(objLead.Status == LEAD_STATUS_INPROGRESS && objLead.OwnerId != oldMap.get(objLead.Id).OwnerId
               && !taskMap.containsKey(objLead.Id) && objLead.OwnerId.getsObjectType() == User.SobjectType && !isADHALead){
                   objTask = objActivityService.getActivity(TASK_SUBJECT_CC_DAY_1_CALL_1, System.today(), 
                                                            Date.today(), TASK_DESCRIPTION, 
                                                            TASK_STATUS, TASK_TYPE, TASK_PRIORITY, 1, objLead.OwnerId, objLead.Id); 
                   taskList.add(objTask);
               }
        }
        objActivityService.insertTasksWithoutTrigger(taskList);
    }
    
    public static void createQualifiedLeadTask(List<Lead>updatedLeadList,Map<id,Lead>updatedLeadMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        Id defaultBHId = objMetadataService.getAppSettingTextValue(DEFAULT_BUSINESS_HOURS_ID);
        Date nextBusinessDate = objBHService.getNextBusinessDate(defaultBHId,System.now());
        List<Lead> qualifiedLeads = new List<Lead>();    
        List<Task> taskList = new List<Task>();
        for(Lead newLead:updatedLeadList){
            if(newLead.ContactCentreLeadStatus__c == LEAD_CC_STATUS_QUALIFIED && updatedLeadMap.get(newLead.id).ownerId!= newLead.OwnerId  && newLead.OwnerId.getsObjectType() == User.SobjectType){
                qualifiedLeads.add(newLead);
            }
        }
        // Create a task for each qualified Lead
        for (Lead l : qualifiedLeads) {
            Task objTask = objActivityService.getActivity(l.LeadTeam__c == LEAD_TEAM ? SALES_TASK_SUBJECT+' - '+TASK_SUBJECT_DAY_1_CALL_1 : LEASING_TASK_SUBJECT+' - '+TASK_SUBJECT_DAY_1_CALL_1, System.today(), 
                                                          nextBusinessDate , TASK_DESCRIPTION, 
                                                          TASK_STATUS, TASK_TYPE, TASK_PRIORITY, 1, l.OwnerId, l.Id); 
            taskList.add(objTask);
        }
        objActivityService.insertTasksWithoutTrigger(taskList);
    }
    
    public static void handleBeforeInsertFieldUpdates(List<Lead> newList) {
        MetadataService objMetadataService = MetadataService.getInstance();
        String marketingLeadCreatedByIds = objMetadataService.getAppSettingTextValue(MARKETING_LEAD_CREATED_BY_IDS);
        Id contactCenterLeadQueueId = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_LEAD_QUEUE_ID);
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        String leasingTeamProfileIds = objMetadataService.getAppSettingTextValue(LEASING_TEAM_PROFILE_ID);
        String salesManagerProfileIds = objMetadataService.getAppSettingTextValue(SALES_MANAGER_PROFILE_ID);
        List<Id> marketingLeadCreatedByUserIds = marketingLeadCreatedByIds.split(',');
        List<Id> contactCentreProfileIdsList = contactCentreProfileIds.split(',');
        List<Id> leasingTeamProfileIdsList = leasingTeamProfileIds.split(',');
        List<Id> salesmanagerProfileIdsList = salesManagerProfileIds.split(',');
        Map<String, LeadCategoryMapping__mdt> mappingData = objMetadataService.getLeadCategoryMapping();
        Id currentUserId = UserInfo.getUserId();
        String currentUserProfileId = UserInfo.getProfileId().substring(0,15);
        for(Lead objLead :newList){
            objLead.Emirates_Id__c = Utility.formatEmiratesId(objLead.Emirates_Id__c);
            Boolean isADHALead = objLead.Lead_Channel__c == 'API Integration' && objLead.LeadSource == 'Government Entity' && objLead.leadsubsource__c == 'ADHA' && objLead.ApplicationNumber__c != null;
            if(marketingLeadCreatedByUserIds.contains(currentUserId) && objLead.lead_channel__c != 'Broker Portal' && !isADHALead){
                objLead.OwnerId = contactCenterLeadQueueId;
            }
            if(marketingLeadCreatedByUserIds.contains(currentUserId) && String.IsBlank(objLead.leadTeam__c)){
                objLead.LeadTeam__c = 'Sales';
            }
            if(String.isNotEmpty(objLead.Email) || String.isNotEmpty(objLead.MobilePhone)){
                objLead.Sync_With_Marketing__c = true;
            }
             if(String.isEmpty(objLead.FirstName) && String.isNotEmpty(objLead.LastName)){
                objLead.FirstName = objLead.LastName;
            }
             if(String.isNotEmpty(objLead.FirstName)){
                objLead.FirstName = Utility.doStandardizeText(objLead.FirstName);
            }
            if(String.isNotEmpty(objLead.MiddleName)){
                objLead.MiddleName = Utility.doStandardizeText(objLead.MiddleName);
            }
            if(String.isNotEmpty(objLead.LastName)){
                objLead.LastName = Utility.doStandardizeText(objLead.LastName);
            }
           
            if(String.isNotBlank(objLead.MobilePhoneNumber__c)){
                objLead.MobilePhoneNumber__c = Utility.doStandardizePhoneNumber(objLead.MobilePhoneNumber__c);
            }
            if(String.isNotBlank(objLead.MobilePhone)){
                objLead.MobilePhone = Utility.doStandardizePhoneNumber(objLead.MobilePhone);
            }
            if(String.isNotBlank(objLead.mobile_country_code__c)){
                objLead.MobilePhone = Utility.formatPhoneNumber(objLead.mobile_country_code__c, objLead.MobilePhone);
                objLead.MobileCountryCode__c = objLead.mobile_country_code__c;
            }
            if(String.isNotBlank(objLead.MobilePhone)){
                objLead.MobilePhoneNumber__c = objLead.MobilePhone;
            }else if(String.isNotBlank(objLead.MobilePhoneNumber__c)){
                objLead.MobilePhone = Utility.formatPhoneNumber(objLead.MobileCountryCode__c, objLead.MobilePhoneNumber__c);
            }
            if(leasingTeamProfileIdsList.contains(currentUserProfileId)){
                objLead.LeadTeam__c = 'Leasing'; 
            }else if(salesmanagerProfileIdsList.contains(currentUserProfileId)){
                objLead.LeadTeam__c = 'Sales'; 
            }
            if(contactCentreProfileIdsList.contains(currentUserProfileId)){
                objLead.Status = 'In Progress';
                objLead.ContactCentreLeadStatus__c = 'In Progress';
                objLead.ContactCenterAssignedDate__c = System.now();
            }else if(leasingTeamProfileIdsList.contains(currentUserProfileId) || salesmanagerProfileIdsList.contains(currentUserProfileId)){
                objLead.Status = 'In Progress';
                objLead.LeadManagerStatus__c = 'In Progress';
                objLead.LeadManagerAssignedDate__c = System.now();
            }
            objLead.Phone = Utility.formatPhoneNumber(objLead.PhoneCountryCode__c, objLead.PhoneNumber__c);
            
            if(String.isNotBlank(objLead.sm_campaign_name__c)){
                if(objLead.sm_campaign_name__c.contains('Leasing')){
                    objLead.LeadTeam__c = 'Leasing';
                }
            }
            
            if(String.isNotBlank(objLead.LeadTeam__c) && String.isNotBlank(objLead.LeadSource)){
                if(!mappingData.isEmpty() && mappingData.containsKey(objLead.LeadTeam__c + '|' + objLead.LeadSource)){
                    LeadCategoryMapping__mdt objLeadCategoryMapping = mappingData.get(objLead.LeadTeam__c + '|' + objLead.LeadSource);
                    objLead.LeadCategory__c = objLeadCategoryMapping.LeadCategory__c;
                    objLead.Lead_Type__c = objLeadCategoryMapping.LeadType__c;
                } else {
                    objLead.LeadCategory__c = 'Direct';
                    objLead.Lead_Type__c = 'Company Lead';
                }
            }
        }
    }
    
    public static void handleBeforeUpdateFieldUpdates(List<Lead> newList, Map<Id, Lead> oldMap) {
        MetadataService objMetadataService = MetadataService.getInstance();
        String excludeDuplicateLeadStatus = objMetadataService.getAppSettingTextValue(EXCLUDE_DUPLICATE_LEAD_STATUS);
        List<String> excludeDuplicateLeadStatusList = excludeDuplicateLeadStatus.split(',');
        String contactCentreProfileIds = objMetadataService.getAppSettingTextValue(CONTACT_CENTER_PROFILE_ID);
        String leasingTeamProfileIds = objMetadataService.getAppSettingTextValue(LEASING_TEAM_PROFILE_ID);
        String salesManagerProfileIds = objMetadataService.getAppSettingTextValue(SALES_MANAGER_PROFILE_ID);
        List<Id> contactCentreProfileIdsList = contactCentreProfileIds.split(',');
        List<Id> leasingTeamProfileIdsList = leasingTeamProfileIds.split(',');
        List<Id> salesmanagerProfileIdsList = salesManagerProfileIds.split(',');
        Set<Id> userOwnerIds = new Set<Id>();
        Map<String, LeadCategoryMapping__mdt> mappingData = objMetadataService.getLeadCategoryMapping();
        
        Set<Id> unitIds = new Set<Id>();

        for (Lead objLead : newList) {
            if (objLead.Unit__c != oldMap.get(objLead.Id).Unit__c && objLead.Unit__c != null) {
                unitIds.add(objLead.Unit__c);
            }
        }
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>();
        if (!unitIds.isEmpty()) {
            unitMap = new Map<Id, Unit__c>(UnitService.getInstance().getUnitsByIds(unitIds));
        }
        
        for(Lead objLead :newList){
            if(objLead.Emirates_Id__c != oldMap.get(objLead.Id).Emirates_Id__c){
                objLead.Emirates_Id__c = Utility.formatEmiratesId(objLead.Emirates_Id__c);
            }
            if(String.isNotEmpty(objLead.FirstName) && objLead.FirstName != oldMap.get(objLead.Id).FirstName){
                objLead.FirstName = Utility.doStandardizeText(objLead.FirstName);
            }
            if(String.isNotEmpty(objLead.MiddleName) && objLead.MiddleName != oldMap.get(objLead.Id).MiddleName){
                objLead.MiddleName = Utility.doStandardizeText(objLead.MiddleName);
            }
            if(String.isNotEmpty(objLead.LastName) && objLead.LastName != oldMap.get(objLead.Id).LastName){
                objLead.LastName = Utility.doStandardizeText(objLead.LastName);
            }
            
            if(String.isNotBlank(objLead.MobilePhoneNumber__c) && objLead.MobilePhoneNumber__c != oldMap.get(objLead.Id).MobilePhoneNumber__c){
                objLead.MobilePhoneNumber__c = Utility.doStandardizePhoneNumber(objLead.MobilePhoneNumber__c);
            }
            if(String.isNotBlank(objLead.MobilePhone) && objLead.MobilePhone != oldMap.get(objLead.Id).MobilePhone){
                objLead.MobilePhone = Utility.doStandardizePhoneNumber(objLead.MobilePhone);
            }
            if((objLead.MobilePhoneNumber__c != oldMap.get(objLead.Id).MobilePhoneNumber__c)
               || (objLead.MobileCountryCode__c != oldMap.get(objLead.Id).MobileCountryCode__c)){
                   objLead.MobilePhone = Utility.formatPhoneNumber(objLead.MobileCountryCode__c, objLead.MobilePhoneNumber__c);
               }
            if((objLead.PhoneNumber__c != oldMap.get(objLead.Id).PhoneNumber__c)
               || (objLead.PhoneCountryCode__c != oldMap.get(objLead.Id).PhoneCountryCode__c)){
                   objLead.Phone = Utility.formatPhoneNumber(objLead.PhoneCountryCode__c, objLead.PhoneNumber__c);
               }
            if(objLead.Status != oldMap.get(objLead.Id).Status && objLead.Status == 'Retired'){
                objLead.Retried_Date__c = System.today();
            }
            if(objLead.Status != oldMap.get(objLead.Id).Status && excludeDuplicateLeadStatusList.contains(objLead.Status)){
                objLead.ExcludeDuplicateCheck__c = 'Yes';
            }else if(objLead.Status != oldMap.get(objLead.Id).Status && !excludeDuplicateLeadStatusList.contains(objLead.Status)){
                objLead.ExcludeDuplicateCheck__c = 'No';
            }
            if(objLead.IsConverted && oldMap.get(objLead.Id).IsConverted == false) {
                objLead.LeadManagerStatus__c = LEAD_LM_STATUS_CONVERTED;
            }
            if(String.isNotBlank(objLead.LeadTeam__c) && String.isNotBlank(objLead.LeadSource) && (objLead.LeadSource != oldMap.get(objLead.Id).LeadSource || objLead.LeadTeam__c != oldMap.get(objLead.Id).LeadTeam__c)){
                if(!mappingData.isEmpty() && mappingData.containsKey(objLead.LeadTeam__c + '|' + objLead.LeadSource)){
                    LeadCategoryMapping__mdt objLeadCategoryMapping = mappingData.get(objLead.LeadTeam__c + '|' + objLead.LeadSource);
                    objLead.LeadCategory__c = objLeadCategoryMapping.LeadCategory__c;
                    objLead.Lead_Type__c = objLeadCategoryMapping.LeadType__c;
                } else {
                    objLead.LeadCategory__c = 'Direct';
                    objLead.Lead_Type__c = 'Company Lead';
                }
            }

            Boolean alreadyValidatedForThisUnit = unitAvailabilityLastValidatedFor.containsKey(objLead.Id) && unitAvailabilityLastValidatedFor.get(objLead.Id) == objLead.Unit__c;

            if(objLead.Unit__c != oldMap.get(objLead.Id).Unit__c && !alreadyValidatedForThisUnit){
                unitAvailabilityLastValidatedFor.put(objLead.Id, objLead.Unit__c);

                if (objLead.Unit__c != null && unitMap.containsKey(objLead.Unit__c) && unitMap.get(objLead.Unit__c).Status__c != 'Available') {
                    objLead.addError( 'The selected Unit is no longer available for booking.' );
                } else {
                    if(objLead.Unit__c != null){
                        objLead.LastUnitBookedDate__c = System.now();
                    }
                    objLead.BookingStatus__c = objLead.Unit__c != null ? 'Booked' : null;
                }
            }
        }
    }
    
    public static void createLeadManagerTask(List<Lead> leadList, Map<Id, Lead> oldMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        Set<Id> setLeadIds = new Set<Id>();
        List<Task> taskList = new List<Task>();
        
        for(Lead objLead : leadList){
            if((objLead.FollowUpDate__c != oldMap.get(objLead.Id).FollowUpDate__c || objLead.WaitingListDate__c != oldMap.get(objLead.Id).WaitingListDate__c) && (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP || objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST)){
                setLeadIds.add(objLead.Id);
            }
        }
        Map<Id,Lead> mapLeadWithOpenActivity = new Map<Id,Lead>(objLeadService.getLeadWithOpenActivity(setLeadIds));
        Map<Id,Lead> mapLeadWithClosedActivity = new Map<Id,Lead>(objLeadService.getLeadWithClosedActivity(setLeadIds));
        List<Task> lstOpenTask;
        List<Task> lstClosedTask;
        for(Lead objLead : leadList){
            if((objLead.FollowUpDate__c != oldMap.get(objLead.Id).FollowUpDate__c || objLead.WaitingListDate__c != oldMap.get(objLead.Id).WaitingListDate__c) && (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP || objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST)){
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
                                taskList.add(objTask);
                                break;
                            }
                        }else if(objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST){
                            if (objTask.Subject.contains('LO - Day') || objTask.Subject.contains('SM - Day')){
                                objTask.ActivityDate = objLead.WaitingListDate__c;
                                taskList.add(objTask); 
                                break;
                            }
                        }
                    }
                }
                else if(!lstClosedTask.isEmpty()){
                    String subject = null;
                    for(Task objTask : lstClosedTask){
                        if(objTask.subject.contains(TASK_SUBJECT_DAY_1_CALL_1) || objTask.subject.contains(TASK_SUBJECT_DAY_2_CALL_1)){
                            subject = objTask.subject.contains(TASK_SUBJECT_DAY_1_CALL_1)? TASK_SUBJECT_DAY_2_CALL_1
                                : objTask.subject.contains(TASK_SUBJECT_DAY_2_CALL_1)? TASK_SUBJECT_DAY_3_CALL_1: null;
                        }
                        else if(objTask.subject.contains(TASK_SUBJECT_DAY_3_CALL_1)){
                            subject = null;
                        }
                    }
                    if(subject != null){
                        Date activityDateVal = (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_FOLLOWUP) ? objLead.FollowUpDate__c 
                            : (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST ? objLead.WaitingListDate__c : null);
                                
                                Task objNewTask = objActivityService.getActivity(objLead.LeadTeam__c == LEAD_TEAM ? SALES_TASK_SUBJECT+' - '+subject : LEASING_TASK_SUBJECT+' - '+subject, 
                                                                                 activityDateVal, activityDateVal, TASK_DESCRIPTION, 
                                                                                 TASK_STATUS, TASK_TYPE, TASK_PRIORITY, 1, objLead.OwnerId, objLead.Id); 
                        taskList.add(objNewTask);  
                    }
                }
            }  
            objActivityService.upsertTasksWithoutTrigger(taskList);
        }
    }
    
    public static void markTaskComplete(List<Lead> leadList, Map<Id, Lead> oldMap){
        Set<Id> setLeadIds = new Set<Id>();
        List<Task> taskList = new List<Task>();
        List<Task> taskUpdateList = new List<Task>();
        LeadService objLeadService = LeadService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        
        List<Lead> leadWithTaskList = objLeadService.getLeadWithOpenActivity(oldMap.keySet());
        for(Lead objLead : leadWithTaskList){
            for(Task objTask : objLead.Tasks){
                if(objTask != null){
                    if(objTask.Subject != null && objTask.Subject.contains('CC - Day') && (objLead.ContactCentreLeadStatus__c == LEAD_CC_STATUS_QUALIFIED || objLead.ContactCentreLeadStatus__c == LEAD_CC_STATUS_DISQUALIFIED)){
                        objTask.Description = TASK_COMPLETED_DESCRIPTION;
                        objTask.Status = TASK_COMPLETED_STATUS;
                        taskUpdateList.add(objTask);
                    } 
                    else if ((objTask.Subject != null && (objTask.Subject.contains('LO - Day') || objTask.Subject.contains('SM - Day'))) && (objLead.LeadManagerStatus__c == LEAD_LM_STATUS_CONVERTED || objLead.LeadManagerStatus__c == LEAD_LM_STATUS_RETIRED)){
                        objTask.Description = TASK_COMPLETED_DESCRIPTION;
                        objTask.Status = TASK_COMPLETED_STATUS;
                        taskUpdateList.add(objTask);    
                    }
                }
            }
        }
        objActivityService.updateTasks(taskUpdateList);
    }    
    
    public static void blockLeadUnit(List<Lead> newList, Map<Id, Lead> oldMap){
        UnitService objUnitService = UnitService.getInstance();
        List<Unit__c> unitsToUpdate = new List<Unit__c>();

        for(Lead objLead : newList){
            Id oldUnitId = oldMap.get(objLead.Id).Unit__c;

            if(objLead.Unit__c != oldUnitId){
                if(objLead.Unit__c != null){
                    Unit__c unitObj = new Unit__c(Id = objLead.Unit__c);
                    unitObj.Status__c = 'Blocked';
                    unitObj.BlockedForLead__c = objLead.Id;
                    unitObj.BlockedReason__c = 'ADHA Customer';
                    unitObj.BlockedDate__c = System.now();
                    unitObj.Block_Till__c = System.now().addDays(14);
                    unitObj.BlockedBy__c = (objLead.OwnerId != null && objLead.OwnerId.getSObjectType() == User.SObjectType) ? objLead.OwnerId : null;
                    unitsToUpdate.add(unitObj);
                }

                if(oldUnitId != null){
                    unitsToUpdate.add(new Unit__c(
                        Id = oldUnitId,
                        Status__c = 'Available',
                        BlockedForLead__c = null,
                        BlockedReason__c = null,
                        BlockedDate__c = null,
                        Block_Till__c = null,
                        BlockedBy__c = null
                    ));
                }
            }
        }

        objUnitService.updateUnits(unitsToUpdate);
    }
}
/*****************************************************************************************
Class       : CaseAssignmentBatch
Author      : Sonali S
Description : Case Assignment Batch 
Created Date: 9 JAN 2025
*****************************************************************************************/
public without sharing class CaseAssignmentBatch implements Database.Batchable<sObject>, Schedulable{
    
    private static final string MTD_CONTACT_CENTER_DIGITAL_QUEUE_ID { get { return 'ContactCenterDigitalQueueId'; } }
    private static final string MTD_COMPLAINT_CASES_QUEUE_ID { get { return 'ComplaintCasesQueueId'; } }
    private static final string MTD_BFM_CASES_QUEUE_ID { get { return 'BFMCasesQueueId'; } }
    private static final string MTD_CRM_TEAM_QUEUE_ID { get { return 'CRMQueueId'; } }
    private static final string MTD_SUPER_APP_OPERATION_TEAM_QUEUE_ID { get { return 'SuperAppOperationTeamQueueId'; } }
    private static final string RESALE_RT_DEV_NAME { get { return 'Resale_Master'; } }
    private static final string KYC_UPDATE_REQUEST_RT { get { return 'KYCUpdateRequest'; } }
    private static final String SUPER_APP_STR = 'Super App';
    private static final String SUPER_APP_OPERATION_TEAM_CASE_ASSIGNMENT { get { return 'Super App Operation Team Case Assignment'; } }
    private static final String SALES_STR { get { return 'Sales'; } }
    private static final List<String> COMPLAINT_SR_RECORD_TYPES = new List<String>{'ComplaintRequest','Customer_Service','Defect_liability','Leasing_Complaint','Maintenance_Complaint','Property_Handover','Sales_Complaint'};
    @TestVisible
    private static Boolean isBeforeTenAm;



    public Database.QueryLocator start(Database.BatchableContext BC) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Id contactCenterDigitalQueueId = objMetadataService.getAppSettingTextValue(MTD_CONTACT_CENTER_DIGITAL_QUEUE_ID);
        Id complaintCasesQueueId =  objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_CASES_QUEUE_ID);
        Id bfmCasesQueueId =  objMetadataService.getAppSettingTextValue(MTD_BFM_CASES_QUEUE_ID);
        Id crmTeamQueueId =  objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_QUEUE_ID);
        Id superAppOperationTeamQueueId =  objMetadataService.getAppSettingTextValue(MTD_SUPER_APP_OPERATION_TEAM_QUEUE_ID);
        Set<Id> ownerIds = new Set<Id>{contactCenterDigitalQueueId, complaintCasesQueueId, bfmCasesQueueId, crmTeamQueueId, superAppOperationTeamQueueId};
        String query = 'SELECT Id, RecordTypeId, RecordType.DeveloperName, RoundRobinNumber__c, OwnerId, CreatedById FROM Case WHERE OwnerId IN :ownerIds';
        return Database.getQueryLocator(query); 
    }
    
    public void execute(Database.BatchableContext BC, List<Case> scope){
        Set<Id> digitalcaseIds = new Set<ID>();
        Set<Id> complaintcaseIds = new Set<ID>();
        Set<Id> bfmCaseIds = new Set<ID>();
        Set<Id> crmCaseIds = new Set<ID>();
        Set<Id> resaleCaseIds = new Set<ID>();
        Set<Id> allCRMCaseIds = new Set<ID>();
        Set<Id> superAppCRMCaseIds = new Set<ID>();
        Set<Id> superAppOperationCaseIds = new Set<ID>();
        
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id resaleRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_RT_DEV_NAME);
        Id KYCUpdateRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, KYC_UPDATE_REQUEST_RT);

        Id contactCenterDigitalQueueId = objMetadataService.getAppSettingTextValue(MTD_CONTACT_CENTER_DIGITAL_QUEUE_ID);
        Id complaintCasesQueueId =  objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_CASES_QUEUE_ID);
        Id bfmCasesQueueId =  objMetadataService.getAppSettingTextValue(MTD_BFM_CASES_QUEUE_ID);
        Id crmTeamQueueId =  objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_QUEUE_ID);
        Id superAppOperationTeamQueueId =  objMetadataService.getAppSettingTextValue(MTD_SUPER_APP_OPERATION_TEAM_QUEUE_ID);
        
        for(Case objCase : scope){

            Boolean isAfterTenAM;

            if(Test.isRunningTest() && isBeforeTenAm != null){
                isAfterTenAM = !isBeforeTenAm;
            }
            else{
                Time currentTime = System.now().time();
                //Time tenAM = Time.newInstance(10, 0, 0, 0);
                Time tenAM = Time.newInstance(19, 0, 0, 0);
                isAfterTenAM = currentTime >= tenAM;
            }

            if(isAfterTenAM){
                if(objCase.OwnerId == contactCenterDigitalQueueId){
                    digitalcaseIds.add(objCase.id); 
                }
                else if(objCase.OwnerId == complaintCasesQueueId){
                    complaintcaseIds.add(objCase.id);
                }
                else if(objCase.OwnerId == bfmCasesQueueId){
                    bfmCaseIds.add(objCase.id);
                }
                
            }else{
                if(objCase.OwnerId == complaintCasesQueueId && COMPLAINT_SR_RECORD_TYPES.contains(objCase.RecordType.DeveloperName)){
                    complaintcaseIds.add(objCase.id);
                    allCRMCaseIds.add(objCase.id);
                }
                else if(objCase.RecordTypeId == KYCUpdateRequestRTId && objCase.OwnerId == crmTeamQueueId){
                    superAppCRMCaseIds.add(objCase.id);
                    allCRMCaseIds.add(objCase.id);
                }
                else if(objCase.OwnerId == crmTeamQueueId && objCase.RecordTypeId != resaleRecordTypeId ){
                    crmCaseIds.add(objCase.id);
                    allCRMCaseIds.add(objCase.id);
                }
                else if(objCase.RecordTypeId == resaleRecordTypeId && objCase.OwnerId == crmTeamQueueId){
                    resaleCaseIds.add(objCase.id);
                    allCRMCaseIds.add(objCase.id);
                }
                else if(objCase.RecordTypeId == KYCUpdateRequestRTId && objCase.OwnerId == superAppOperationTeamQueueId){
                    superAppOperationCaseIds.add(objCase.id);
                }
                
            }
        }
        
        if(!digitalcaseIds.isEmpty()){
            AssignmentRuleHandler.salesDigitalCaseAssignment(new List<Id>(digitalcaseIds));  
        }
        
        if(!complaintcaseIds.isEmpty()){
            AssignmentRuleHandler.salesComplaintCaseAssignment(new List<Id>(complaintcaseIds));  
        }
        
        if(!bfmCaseIds.isEmpty()){
            AssignmentRuleHandler.bfmEmailToCaseCaseAssignment(new List<Id>(bfmCaseIds));  
        }
        
        if(!crmCaseIds.isEmpty()){
            System.debug('in if'+crmCaseIds);
            AssignmentRuleHandler.crmCaseAssignment(new List<Id>(crmCaseIds));  
        }
        
        if(!resaleCaseIds.isEmpty()){
            AssignmentRuleHandler.crmResaleCaseAssignment(new List<Id>(resaleCaseIds));
        }

        if(!superAppCRMCaseIds.isEmpty()){
            AssignmentRuleHandler.superAppCaseAssignment(new List<Id>(superAppCRMCaseIds));
            ServiceRequestHandler.getInstance().serviceRequestAssignmentEmailNotification(new Set<Id> (superAppCRMCaseIds));
        }

        if(!superAppOperationCaseIds.isEmpty()){
            AssignmentRuleHandler.assignCasesToNextOwner(new Set<Id>(superAppOperationCaseIds), SUPER_APP_OPERATION_TEAM_CASE_ASSIGNMENT, SALES_STR);
            ServiceRequestHandler.getInstance().serviceRequestAssignmentEmailNotification(new Set<Id> (superAppOperationCaseIds));
        }
        
        if(!allCRMCaseIds.isEmpty()|| Test.isRunningTest()){
            ActivityService objActivityService = ActivityService.getInstance();
            Map<Id, Case> caseMap = new Map<Id, Case>(CaseService.getInstance().getCaseByIds(allCRMCaseIds));
            List<Task> objTaskList = new List<Task>();
            for(Task objTask :objActivityService.getOpenTasksBywhatIds(allCRMCaseIds)){
                if(caseMap.containsKey(objTask.WhatId)){
                    if(objTask.OwnerId == crmTeamQueueId){
                        objTask.OwnerId = caseMap.get(objTask.WhatId).OwnerId;
                        objTaskList.add(objTask);
                    }
                }
            }
            objActivityService.updateTasks(objTaskList);
        }
        if(!superAppOperationCaseIds.isEmpty()){
            ActivityService objActivityService = ActivityService.getInstance();
            Map<Id, Case> caseMap = new Map<Id, Case>(CaseService.getInstance().getCaseByIds(superAppOperationCaseIds));
            List<Task> objTaskList = new List<Task>();
            for(Task objTask :objActivityService.getOpenTasksBywhatIds(superAppOperationCaseIds)){
                if(caseMap.containsKey(objTask.WhatId)){
                    if(objTask.OwnerId == superAppOperationTeamQueueId){
                        objTask.OwnerId = caseMap.get(objTask.WhatId).OwnerId;
                        objTaskList.add(objTask);
                    }
                }
            }
            objActivityService.updateTasks(objTaskList);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new CaseAssignmentBatch(), 100);
    }
}
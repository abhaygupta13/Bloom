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
****************************************************************************************************************/
public without sharing class LeadAsyncTriggerHandler implements IAsyncTriggerHandler{
    
    private static final string DIGITAL_LEAD_CREATED_BY_IDS { get { return 'DigitalLeadCreatedByIds'; } }
    private static final string LEASING_LEAD_CREATED_BY_IDS { get { return 'LeasingLeadCreatedByIds'; } }
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isAsyncTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isAsyncTriggerDisabled;
    }
    
    public void changeEventCapture(List<sObject> newList) {
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        
        String digitalLeadCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_LEAD_CREATED_BY_IDS);
        List<Id> digitalLeadCreatedByUserIdList = digitalLeadCreatedByIds.split(',');
        String leasingLeadCreatedByIds = objMetadataService.getAppSettingTextValue(LEASING_LEAD_CREATED_BY_IDS);
        List<Id> leasingLeadCreatedByUserIdList = leasingLeadCreatedByIds.split(',');
        List<LeadChangeEvent> objLeadChangeEventList =  (List<LeadChangeEvent>)newList;
        
        List<Id> digitalLeadIds = new List<Id>();
        List<Id> qualifiedLeadIds = new List<Id>();
        List<Id> leasingLeadIds = new List<Id>();
        List<Id> leadEmailNotificationIds = new List<Id>();
        List<Id> adhaLeadIds = new List<Id>();
        for (LeadChangeEvent event : objLeadChangeEventList) {
            //Get event header fields
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            switch on header.changeType {
                when 'CREATE'{
                    if(digitalLeadCreatedByUserIdList.contains(event.CreatedById) && event.get('Status') == 'New' && event.get('LeadSource') != 'Government Entity' && event.get('Lead_Channel__c') != 'Broker Portal'){
                        digitalLeadIds.addAll(header.getRecordIds());
                    } else if(event.get('LeadTeam__c') != 'Leasing' && event.get('Lead_Channel__c') == 'API Integration' && event.get('LeadSource') == 'Government Entity' &&  event.get('leadsubsource__c') == 'ADHA' && String.isNotBlank((String)event.get('ApplicationNumber__c'))){
                        adhaLeadIds.addAll(header.getRecordIds());  
                    }
                    if(event.get('Email') != Null){
                        leadEmailNotificationIds.addAll(header.getRecordIds()); 
                    }
                }
                when 'UPDATE'{
                    if(event.get('ContactCentreLeadStatus__c') != NULL && event.get('ContactCentreLeadStatus__c') == 'Qualified'){
                        qualifiedLeadIds.addAll(header.getRecordIds());
                    }
                   
                }
                when 'DELETE'{
                    
                }
                when 'UNDELETE'{
                    
                }
            }
        }
        if(!leadEmailNotificationIds.isEmpty()){
            LeadAsyncTriggerHelper.leadEmailNotificationToCustomer(leadEmailNotificationIds);
        }
        if(!digitalLeadIds.isEmpty()){
            AssignmentRuleHandler.salesDigitalLeadAssignment(digitalLeadIds);
        }    
        if(!qualifiedLeadIds.isEmpty()){
            AssignmentRuleHandler.qualifiedLeadAssignment(qualifiedLeadIds);
        }
         if(!adhaLeadIds.isEmpty()){
            AssignmentRuleHandler.adhaLeadAssignment(adhaLeadIds);
        }
    }
}
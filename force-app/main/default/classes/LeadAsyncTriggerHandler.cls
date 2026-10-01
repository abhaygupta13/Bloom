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
public without sharing class LeadAsyncTriggerHandler implements IAsyncTriggerHandler {
    
    private static final string DIGITAL_LEAD_CREATED_BY_IDS { get { return 'DigitalLeadCreatedByIds'; } }
    private static final string LEASING_LEAD_CREATED_BY_IDS { get { return 'LeasingLeadCreatedByIds'; } }
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isAsyncTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled() {
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
        List<Id> adhaLeadIds = new List<Id>();
        List<Id> leasingLeadIds = new List<Id>();
        List<Id> contactCentreAndQualifiedLeadIds = new List<Id>();
         List<Id> createdLeadIds = new List<Id>();
        List<Id> adhaClosedLeadIds = new List<Id>();
        List<Id> adhaLeadClosurPushNotificationIds = new List<Id>();
        List<Id> ownerChangedLeadIds = new List<Id>();
        List<Id> leadWaitingListUpdateEmailIds = new List<Id>();
        
        List<Id> adhaLeadClosurePushNotificationIds = new List<Id>();
        List<Id> leadBookingStatusPushNotificationIds = new List<Id>();
        List<Id> adhaBankLoanTopUpLeadIds = new List<Id>();
        List<Id> adhaUnitReservedLeadIds = new List<Id>();
        List<Id> adhaUnitRemovedLeadIds = new List<Id>();
        Set<String> pushNotificationTemplateNames = new Set<String>{'Lead Created', 'Lead Closure', 'Booking Cancelled', 'Opportunity Created'};

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
                    createdLeadIds.addAll(header.getRecordIds());  
                }
                when 'UPDATE'{
                    if(event.get('ContactCentreLeadStatus__c') != NULL && event.get('ContactCentreLeadStatus__c') == 'Qualified'){
                        qualifiedLeadIds.addAll(header.getRecordIds());
                    }
                    if(event.get('OwnerId') != null) {
                        Id recOwnerId = String.valueOf(event.get('OwnerId'));
                        if(recOwnerId.getsObjectType() == User.SobjectType) {
                            contactCentreAndQualifiedLeadIds.addAll(header.getRecordIds());
                        }
                    }
                    if(header.getChangedFields().contains('Status') && event.get('Status') == 'Closed') {
                        adhaClosedLeadIds.addAll(header.getRecordIds());
                        adhaLeadClosurPushNotificationIds.addAll(header.getRecordIds());
                    }
                    if(header.getChangedFields().contains('OwnerId') && event.get('OwnerId') != null) {
                        ownerChangedLeadIds.addAll(header.getRecordIds());
                    }
                    if(header.getChangedFields().contains('LeadManagerStatus__c') && event.get('LeadManagerStatus__c') == 'Waiting List') {
                        leadWaitingListUpdateEmailIds.addAll(header.getRecordIds());
                    }
                    if(header.getChangedFields().contains('TopUpType__c') && event.get('TopUpType__c') == 'Bank Loan Top-up') {
                        adhaBankLoanTopUpLeadIds.addAll(header.getRecordIds());
                    }
                    if(header.getChangedFields().contains('Unit__c') && event.get('Unit__c') != null) {
                        adhaUnitReservedLeadIds.addAll(header.getRecordIds());
                    }
                    if(header.getChangedFields().contains('Unit__c') && event.get('Unit__c') == null) {
                        adhaUnitRemovedLeadIds.addAll(header.getRecordIds()); 
                    }
                   
                }

                when 'DELETE'{
                    
                }

                when 'UNDELETE' {
                    
                }
            }
        }
        if(!digitalLeadIds.isEmpty()){
            AssignmentRuleHandler.salesDigitalLeadAssignment(digitalLeadIds);
        }
        if(!adhaLeadIds.isEmpty()) {
            AssignmentRuleHandler.adhaLeadAssignment(adhaLeadIds);
            LeadAsyncTriggerHelper.sendMobilAppPushNotification(new Set<Id>(adhaLeadIds), 'Lead Created', pushNotificationTemplateNames);
            LeadAsyncTriggerHelper.sendADHALeadSMSNotification(new Set<Id>(adhaLeadIds), 'Lead Created');
        } 
        if(!createdLeadIds.isEmpty()) {
            LeadAsyncTriggerHelper.leadInternalEmailNotification(createdLeadIds, false, false, false);
            LeadAsyncTriggerHelper.leadCustomerEmailNotification(createdLeadIds, false, false, true);
            LeadAsyncTriggerHelper.leadCustomNotification(createdLeadIds);
        }
        if(!qualifiedLeadIds.isEmpty()) {
            AssignmentRuleHandler.qualifiedLeadAssignment(qualifiedLeadIds);
        }
        if(!ownerChangedLeadIds.isEmpty()) {
            LeadAsyncTriggerHelper.leadInternalEmailNotification(ownerChangedLeadIds, true, false, false);
            LeadAsyncTriggerHelper.leadCustomerEmailNotification(ownerChangedLeadIds, true, false, false);
            LeadAsyncTriggerHelper.leadCustomNotification(ownerChangedLeadIds);
        }
        if(!adhaClosedLeadIds.isEmpty()) {
            LeadAsyncTriggerHelper.leadCustomerEmailNotification(adhaClosedLeadIds, false, false, false);
            LeadAsyncTriggerHelper.sendMobilAppPushNotification(new Set<Id>(adhaLeadClosurPushNotificationIds), 'Lead Closure', pushNotificationTemplateNames);
            LeadAsyncTriggerHelper.sendADHALeadSMSNotification(new Set<Id>(adhaLeadClosurPushNotificationIds), 'Lead Closure');
        }
        if(!leadWaitingListUpdateEmailIds.isEmpty()) {
            LeadAsyncTriggerHelper.leadInternalEmailNotification(leadWaitingListUpdateEmailIds, false, true, false);
        }
        if(!leadBookingStatusPushNotificationIds.isEmpty()) {
            LeadAsyncTriggerHelper.sendMobilAppPushNotification(new Set<Id>(leadBookingStatusPushNotificationIds), null, pushNotificationTemplateNames);
        }
        if(!adhaBankLoanTopUpLeadIds.isEmpty()) {
            LeadAsyncTriggerHelper.sendADHALeadSMSNotification(new Set<Id>(adhaBankLoanTopUpLeadIds), 'Lead TopUp Bank Loan');
            LeadAsyncTriggerHelper.leadCustomerEmailNotification(adhaBankLoanTopUpLeadIds, false, true, false);
        }
        if(!adhaUnitReservedLeadIds.isEmpty()) {
            LeadAsyncTriggerHelper.leadCustomerEmailNotification(adhaUnitReservedLeadIds, false, false, false);
            LeadAsyncTriggerHelper.leadInternalEmailNotification(adhaUnitReservedLeadIds, false, false, false);
            LeadAsyncTriggerHelper.sendADHALeadSMSNotification(new Set<Id>(adhaUnitReservedLeadIds), 'ADHA Customer Unit Reservation SMS Notification');
        }
        if(!adhaUnitRemovedLeadIds.isEmpty()) {
            LeadAsyncTriggerHelper.leadInternalEmailNotification(adhaUnitRemovedLeadIds, false, false, true);
        }
    }
}
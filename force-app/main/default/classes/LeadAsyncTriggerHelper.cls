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
public without Sharing class LeadAsyncTriggerHelper {
    
    private static final string CONTACT_CENTER_PROFILE_ID { get { return 'ContactCentreProfileId'; } }
    private static final string SALES_MANAGER_PROFILE_ID { get { return 'SalesManagerProfileIds'; } }
    private static final string LEASING_TEAM_PROFILE_ID { get { return 'LeasingTeamProfileIds'; } }
    
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }
    private static final string MTD_Default_Lead_Email_Notification{ get { return 'DefaultLeadEmailNotification'; } }
    private static final String MTD_Reception_With_Broker { get { return 'LeadReceptionWithBrokerEmailTemplate'; } }
    private static final String MTD_Reception_Without_Broker { get { return 'LeadEmailTemplateReceptionistTeam'; } }
    private static final String MTD_SalesManager_With_Broker { get { return 'LeadSalesManagerWithBrokerEmailTemplate'; } }
    private static final String MTD_SalesManager_Without_Broker { get { return 'LeadSalesManagerEmailTemplate'; } }
    private static final String MTD_ContactCenter_Sales { get { return 'SalesLeadContactCenterTeamEmailTemplate'; } }
    private static final String MTD_ContactCenter_Leasing { get { return 'LeasingLeadContactCenterTeamEmailTemp'; } }
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
            } 
            // Skip default template if Lead Channel is Broker Portal
            else if (objLead.Lead_Channel__c != 'Broker Portal') {
                emailTemplateId = emailTemplateDefaultIds;
            }
            
            if(emailTemplateId != null){
               emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient( emailTemplateId, noReplyOWDId, null, objLead.Id, Null, Null, Null )); 
            }
        }
        objEmailService.sendEmail(emailList);
    }    
}
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
    private static final string SALES_MANAGER_PROFILE_ID { get { return 'SalesManagerProfileIds'; } }
    private static final string LEASING_TEAM_PROFILE_ID { get { return 'LeasingTeamProfileIds'; } }

    private static final string LEAD_LM_STATUS_WAITINGLIST { get { return 'Waiting List'; } }
    
    private static final string LEAD_LM_STATUS_CLOSED { get { return 'Closed'; } }
    
  	private static final string LC_API_INTEGRATION { get { return 'API Integration'; } }
    private static final string LS_GOVT_ENTITY { get { return 'Government Entity'; } }
    private static final string TOPUP_TYPE_BANK_LOAN { get { return 'Bank Loan Top-up'; } }
    private static final string LEAD_SUBUSOURCE_ADHA { get { return 'ADHA'; } }
    
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'BloomNoReplyOWEmailId'; } }
    private static final string MTD_Default_Lead_Email_Notification{ get { return 'DefaultLeadEmailNotification'; } }
    
    private static final String MTD_Reception_With_Broker { get { return 'LeadReceptionWithBrokerEmailTemplate'; } }
    private static final String MTD_Reception_Without_Broker { get { return 'LeadEmailTemplateReceptionistTeam'; } }
    private static final String MTD_SalesManager_With_Broker { get { return 'LeadSalesManagerWithBrokerEmailTemplate'; } }
    private static final String MTD_SalesManager_Without_Broker { get { return 'LeadSalesManagerEmailTemplate'; } }
    private static final String MTD_ContactCenter_Sales { get { return 'SalesLeadContactCenterTeamEmailTemplate'; } }
    private static final String MTD_ContactCenter_Leasing { get { return 'LeasingLeadContactCenterTeamEmailTemp'; } }
    
    private static final String MTD_SLA_FIRST_CONTACT_HOURS { get { return 'SLAFirstContactHours'; } }
    private static final String MTD_CUSTOMER_WELCOME_EMAIL_TEMPLATE { get { return 'CustomerWelcomeEmailTemplateId'; } } 
    private static final String MTD_ADHA_CLOSURE_NOTIFICATION_EMAIL { get { return 'ADHALeadClosureNotificationEmail'; } }
    private static final String MTD_ADHA_NOTIFICATION_EMAIL_TEMPLATE { get { return 'ADHALeadNotificationEmailTemplateId'; } }
    private static final String MTD_LEAD_ASSIGNED_EMAIL_TEMPLATE_ID { get { return 'LeadAssignedEmailTemplateId'; } }//
    private static final String MTD_ADHA_CLOSURE_EMAIL_TEMPLATE = 'ADHAClosureEmailTemplateId';
    private static final String LEAD_OWNER_CUSTOM_NOTIFICATION_TYPE = 'Bloom_Custom_Notifications';
    private static final String LEAD_OWNER_CUSTOM_NOTIFICATION_TITLE = 'Lead Assigned'; 
    private static final String MTD_LEASING_QUALIFIED_EMAIL_TEMPLATE = 'LeasingQualifiedEmailTemplateId'; 
    private static final String MTD_ADHA_CUSTOMER_WELCOME_EMAIL_TEMPLATE = 'ADHAWelcomeLeadNotiEmailTemplateId';
    private static final String MTD_ADHA_BANKLOAN_OPTION_EMAIL_TEMPLATE = 'AdhaBankLoanOptionEmailTempId';
    private static final String MTD_ADHA_UNIT_RESERVATION_EMAIL_TEMPLATE = 'ADHAUnitReservationEmailTemplateId';
    private static final String MTD_ADHA_LEAD_CREATED_EMAIL_TEMPLATE_ID = 'ADHALeadCreatedEmailTemplateId';
    
    private static final String MTD_NO_REPLY_SALESIT_OWEID_SETTING = 'NoReplySalesIT';
    private static final String MTD_NO_REPLY_LEASING_OWEID_SETTING = 'BloomNoReplyLeasingOWEmailId';
    private static final String MTD_ADHA_CC_EMAIL_ADDRESSES = 'ADHALeadCCEmailAddresses';
    private static final String MTD_LEAD_CREATED_EMAIL_TEMPLATE_ID = 'LeadCreatedEmailTemplateId';
    private static final String MTD_LEASING_LEAD_WAITING_LIST_EMAIL_TEMPLATE = 'LeasingLeadWaitingListEmail';
    private static final String MARKETING_LEAD_CREATED_BY_IDS = 'MarketingLeadCreatedByIds';
    private static final String MTD_LEAD_Unit_Assigned_EMAIL_TEMPLATE_ID = 'LeadUnitAssignedEmailTemplateId';
    private static final String MTD_LEAD_Unit_Cancelled_EMAIL_TEMPLATE_ID = 'LeadUnitCancelledEmailTemplateId';

    private static final string ADHA_CUSTOMER_CREATE_SMS_NOTIFICATION { get { return 'ADHA Customer Welcome SMS Notification'; } }
    private static final string ADHA_LEAD_CLOSURE_SMS_NOTIFICATION { get { return 'ADHA Lead Closure Confirmation SMS Notification'; } }
    private static final string ADHA_LEAD_TOPUP_BANK_LOAN_SMS_NOTIFICATION { get { return 'ADHA Lead Bank Loan Options SMS'; } }
    private static final string ADHA_LEAD_NOT_RESPONDING_BLOOM_CALLS_SMS_NOTIFICATION { get { return 'ADHA Lead Not Answering Bloom Calls SMS Notification'; } }
    private static final string ADHA_LEAD_UNIT_RESERVATION_SMS_NOTIFICATION { get { return 'ADHA Customer Unit Reservation SMS Notification'; } }
   
    public static void leadCustomerEmailNotification(List<Id> leadIds, Boolean isOwnerChangeEvent, Boolean isBankLoanTopUpEvent, Boolean isNewLead) {
        MetadataService objMetadataService  = MetadataService.getInstance();
        EmailService objEmailService        = EmailService.getInstance();
        LeadService objLeadService          = LeadService.getInstance();
 
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Lead> leadList = objLeadService.getLeadByIds(new Set<Id>(leadIds));
 
        Id noReplyOWDId                     = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String adhaCCEMailAddressTextValue  = objMetadataService.getAppSettingTextValue(MTD_ADHA_CC_EMAIL_ADDRESSES);
        Id welcomeEmailTemplateDefaultId    = objMetadataService.getAppSettingTextValue(MTD_Default_Lead_Email_Notification);
        Id receptionWithBrokerId            = objMetadataService.getAppSettingTextValue(MTD_Reception_With_Broker);
        Id receptionWithoutBrokerId         = objMetadataService.getAppSettingTextValue(MTD_Reception_Without_Broker);
        Id salesManagerWithBrokerId         = objMetadataService.getAppSettingTextValue(MTD_SalesManager_With_Broker);
        Id salesManagerWithoutBrokerId      = objMetadataService.getAppSettingTextValue(MTD_SalesManager_Without_Broker);
        Id contactCenterSalesId             = objMetadataService.getAppSettingTextValue(MTD_ContactCenter_Sales);
        Id contactCenterLeasingId           = objMetadataService.getAppSettingTextValue(MTD_ContactCenter_Leasing);
        Id adhaWelcomeEmailTemplateId       = objMetadataService.getAppSettingTextValue(MTD_ADHA_CUSTOMER_WELCOME_EMAIL_TEMPLATE);
        Id leasingQualifiedLeadEmailTempId  = objMetadataService.getAppSettingTextValue(MTD_LEASING_QUALIFIED_EMAIL_TEMPLATE);
        Id adhaBankLoanOptionEmailTempId    = objMetadataService.getAppSettingTextValue(MTD_ADHA_BANKLOAN_OPTION_EMAIL_TEMPLATE);
        Id adhaClosureEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_ADHA_CLOSURE_EMAIL_TEMPLATE);
        Id adhaUnitReservationEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_ADHA_UNIT_RESERVATION_EMAIL_TEMPLATE);
        List<String> adhaCCEmailAddressList = String.isNotBlank(adhaCCEMailAddressTextValue) ? adhaCCEMailAddressTextValue.trim().split(',') : new List<String>();
        Set<Id> dynamicBodyEmailTemplateIds = new Set<Id>{ adhaWelcomeEmailTemplateId, adhaBankLoanOptionEmailTempId, adhaUnitReservationEmailTemplateId, adhaClosureEmailTemplateId };
        Map<Id, EmailTemplate> emailTemplateMap = objEmailService.getEmailTemplatesByIds(dynamicBodyEmailTemplateIds);

        for(Lead objLead :leadList){
            Id emailTemplateId;
 			
            Boolean isADHALead = objLead.Lead_Channel__c == LC_API_INTEGRATION && objLead.LeadSource == LS_GOVT_ENTITY && objLead.leadsubsource__c == LEAD_SUBUSOURCE_ADHA;
            String profileName = objLead.CreatedBy.Profile.Name;
            if(String.isNotBlank(objLead.Email)) {
                if(isBankLoanTopUpEvent) {
                    if(isADHALead && objLead.TopUpType__c == TOPUP_TYPE_BANK_LOAN && String.isNotBlank(objLead.Email)){
                        emailTemplateId = adhaBankLoanOptionEmailTempId;
                        
                        EmailTemplate bankLoanOptionEmailTemplate = emailTemplateMap.get(adhaBankLoanOptionEmailTempId);
                        Messaging.SingleEmailMessage mail = objEmailService.getSingleEmailMessage(null, null, objLead.Id, bankLoanOptionEmailTemplate.Subject, getDynamicBody(bankLoanOptionEmailTemplate.HtmlValue, objLead, true), noReplyOWDId, adhaCCEmailAddressList, null);
                        mail.setTreatTargetObjectAsRecipient(true);
                        mail.setSaveAsActivity(true);
                        emailList.add(mail);
                    }
                    
                } else if(isOwnerChangeEvent) {
                    if(objLead.OwnerId != null && objLead.OwnerId.getSObjectType() == User.SObjectType && objLead.Status == 'Qualified' && objLead.LeadTeam__c == 'Leasing' && String.isNotBlank(objLead.Email)){
                        emailTemplateId = leasingQualifiedLeadEmailTempId;
                    }
                    
                } else if (profileName == 'Reception Team') {
                    emailTemplateId = (objLead.BrokerAgency__c != null && objLead.BrokerAgent__c != null) ? receptionWithBrokerId :receptionWithoutBrokerId;
                    
                } else if (profileName == 'Sales Manager') {
                    emailTemplateId = (objLead.BrokerAgency__c != null && objLead.BrokerAgent__c != null)  ? salesManagerWithBrokerId :salesManagerWithoutBrokerId;
                    
                } else if (profileName == 'Contact Centre Team') {
                    emailTemplateId = (objLead.LeadTeam__c == 'Sales') ? contactCenterSalesId : (objLead.LeadTeam__c == 'Leasing') ? contactCenterLeasingId : null;
                    
                } else if(isADHALead && objLead.Status == LEAD_LM_STATUS_CLOSED) {
                    emailTemplateId = adhaClosureEmailTemplateId;
                    
                    EmailTemplate adhaLeadClosureTemplate = emailTemplateMap.get(adhaClosureEmailTemplateId);
                    Messaging.SingleEmailMessage mail = objEmailService.getSingleEmailMessage(null, null, objLead.Id, adhaLeadClosureTemplate.Subject, adhaLeadClosureTemplate.HtmlValue, noReplyOWDId, adhaCCEmailAddressList, null);
                    mail.setTreatTargetObjectAsRecipient(true);
                    mail.setSaveAsActivity(true);
                    emailList.add(mail);
                    
                } else if(isADHALead && objLead.Unit__c != null) {
                    emailTemplateId = adhaUnitReservationEmailTemplateId;
                    
                    EmailTemplate unitReservationTemplate = emailTemplateMap.get(adhaUnitReservationEmailTemplateId);
                    Messaging.SingleEmailMessage mail = objEmailService.getSingleEmailMessage(null, null, objLead.Id, unitReservationTemplate.Subject, getDynamicBody(unitReservationTemplate.HtmlValue, objLead, false), noReplyOWDId, adhaCCEmailAddressList, null);
                    mail.setTreatTargetObjectAsRecipient(true);
                    mail.setSaveAsActivity(true);
                    emailList.add(mail);
                    
                } else if (objLead.ApplicationNumber__c != null && isADHALead) {
                    emailTemplateId = adhaWelcomeEmailTemplateId;
                    
                    EmailTemplate welcomeEmailTemplate = emailTemplateMap.get(adhaWelcomeEmailTemplateId);
                    Messaging.SingleEmailMessage mail = objEmailService.getSingleEmailMessage(null, null, objLead.Id, welcomeEmailTemplate.Subject, getDynamicBody(welcomeEmailTemplate.HtmlValue, objLead, false), noReplyOWDId, adhaCCEmailAddressList, null);
                    mail.setTreatTargetObjectAsRecipient(true);
                    mail.setSaveAsActivity(true);
                    emailList.add(mail);
                    
                } else if(isNewLead && objLead.Lead_Channel__c != 'Broker Portal') {
                    emailTemplateId = welcomeEmailTemplateDefaultId;
                }
                
                if(emailTemplateId != null && !dynamicBodyEmailTemplateIds.contains(emailTemplateId)){
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId, null, objLead.Id, null, null, null ));
                }
            }
        }
        objEmailService.sendEmail(emailList);
    }

    // FOR Internal Email Notification to the Lead Owner
    public static void leadInternalEmailNotification(List<Id> leadIds, Boolean isOwnerChangeEvent, Boolean isWaitingListEvent, Boolean isUnitCancelled) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        LeadService objLeadService = LeadService.getInstance();

        Id noReplySalesITOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_SALESIT_OWEID_SETTING);
        Id noReplyLeasingOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_LEASING_OWEID_SETTING);
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        
        Id leadAssignedEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_LEAD_ASSIGNED_EMAIL_TEMPLATE_ID);
        Id leadCreatedEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_LEAD_CREATED_EMAIL_TEMPLATE_ID);
        Id adhaLeadCreatedEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_ADHA_LEAD_CREATED_EMAIL_TEMPLATE_ID);
        Id waitingListEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_LEASING_LEAD_WAITING_LIST_EMAIL_TEMPLATE);
        Id leadUnitAssignedEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_LEAD_Unit_Assigned_EMAIL_TEMPLATE_ID);
        Id leadUnitCancelledEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_LEAD_Unit_Cancelled_EMAIL_TEMPLATE_ID);
        
        String marketingLeadCreatedByIds = objMetadataService.getAppSettingTextValue(MARKETING_LEAD_CREATED_BY_IDS);
        List<Id> marketingLeadCreatedByUserIds = String.isNotBlank(marketingLeadCreatedByIds) ? marketingLeadCreatedByIds.split(',') : new List<Id>();

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Lead> leadList = objLeadService.getLeadByIds(new Set<Id>(leadIds));

        if(leadList != null && !leadList.isEmpty()) {
            for(Lead objLead :leadList) {
                Boolean isADHALead = objLead.Lead_Channel__c == LC_API_INTEGRATION && objLead.LeadSource == LS_GOVT_ENTITY && objLead.leadsubsource__c == LEAD_SUBUSOURCE_ADHA && objLead.ApplicationNumber__c != null;
                
                if(String.isNotBlank(objLead.Email) && objLead.OwnerId != null && objLead.OwnerId.getSObjectType() == User.SobjectType && objLead.Owner.Email != null) {
                    Messaging.SingleEmailMessage internalEmail;
                    String ownerName = String.isNotBlank(objLead.Owner.Name) ? objLead.Owner.Name : '';
                    String leadNumber = String.isNotBlank(objLead.LeadNumber__c) ? objLead.LeadNumber__c : '';

                    if(isWaitingListEvent) {
                        if(objLead.LeadTeam__c == 'Leasing' && objLead.LeadManagerStatus__c == LEAD_LM_STATUS_WAITINGLIST) {
                            String orgUrl = System.Url.getOrgDomainUrl().toExternalForm();
                            internalEmail = Messaging.renderStoredEmailTemplate(waitingListEmailTemplateId, objLead.Id, null);
                            configureEmail(internalEmail, noReplyLeasingOWDId, objLead.Owner.Email);
                            internalEmail = objEmailService.replaceTokens(internalEmail, new Map<String, String>{ '{LeadOwner}' => ownerName,
                                                                                                    '{LeadName}' => '<a href="' + orgUrl + '/' + objLead.Id + '">' + (String.isNotBlank(objLead.Name) ? objLead.Name : '') + '</a>'
                                                                                                });
                        }

                    } else if(isOwnerChangeEvent && isADHALead) {
                        internalEmail = Messaging.renderStoredEmailTemplate(adhaLeadCreatedEmailTemplateId, objLead.Id, null);
                        configureEmail(internalEmail, noReplySalesITOWDId, objLead.Owner.Email);
                        internalEmail = objEmailService.replaceTokens(internalEmail, new Map<String, String>{'[LeadOwner]' => ownerName });

                    } else if(isOwnerChangeEvent && !isADHALead) {
                        internalEmail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(leadAssignedEmailTemplateId, noReplySalesITOWDId, null, objLead.Id, new List<String>{ objLead.Owner.Email }, null, null );
                        internalEmail.setTreatTargetObjectAsRecipient(false);

                    } else if(!marketingLeadCreatedByUserIds.contains(objLead.CreatedById)) {
                        internalEmail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(leadCreatedEmailTemplateId, noReplySalesITOWDId, null, objLead.Id, new List<String>{ objLead.Owner.Email }, null, null );
                        internalEmail.setTreatTargetObjectAsRecipient(false);

                    } else if(isADHALead && objLead.Unit__c != null) {
                        String unitName = (objLead.Unit__r != null && String.isNotBlank(objLead.Unit__r.Name)) ? objLead.Unit__r.Name : '';
                        internalEmail = Messaging.renderStoredEmailTemplate(leadUnitAssignedEmailTemplateId, objLead.Id, null);
                        configureEmail(internalEmail, noReplyLeasingOWDId, objLead.Owner.Email);
                        internalEmail = objEmailService.replaceTokens(internalEmail, new Map<String, String>{'{LeadOwner}' => ownerName, '{UnitNumber}'  => unitName });

                    } else if(isADHALead && isUnitCancelled) {
                        internalEmail = Messaging.renderStoredEmailTemplate(leadUnitCancelledEmailTemplateId, objLead.Id, null);
                        configureEmail(internalEmail, noReplyLeasingOWDId, objLead.Owner.Email);
                        internalEmail = objEmailService.replaceTokens(internalEmail, new Map<String, String>{'{LeadOwner}' => ownerName, '{LeadNumber}' => leadNumber });

                    }

                    if(internalEmail != null) {
                        emailList.add(internalEmail);
                    }
                }
            }
            objEmailService.sendEmail(emailList);
        }
    }

    private static void configureEmail(Messaging.SingleEmailMessage email, Id oweaId, String toEmail) {
        if (email != null) {
            email.setTreatTargetObjectAsRecipient(false);
            email.setSaveAsActivity(true);
            if (oweaId != null) {
                email.setOrgWideEmailAddressId(oweaId);
            }
            email.setToAddresses(new List<String>{ toEmail });
        }
    }

    // Custom notification on Owner change (From Flow record create and update) Internal
    public static void leadCustomNotification(List<Id> leadIds){
        if(leadIds == null || leadIds.isEmpty()){
            return;
        }
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        
        List<Lead> leadList = objLeadService.getLeadByIds(new Set<Id>(leadIds));
        CustomNotificationType notificationType = CustomNotificationService.getInstance().getCustomNotificationTypeByName(LEAD_OWNER_CUSTOM_NOTIFICATION_TYPE);
        
        for (Lead objLead : leadList) {            
            if (objLead.OwnerId != null && objLead.OwnerId.getSObjectType() == User.SObjectType) {
                Set<String> recipientIds = new Set<String>{ String.valueOf(objLead.OwnerId) };
                String notificationBody = 'A new lead has been assigned to you. Lead Number: ' + objLead.LeadNumber__c;
                CustomNotificationService.sendCustomNotification(recipientIds,String.valueOf(objLead.Id),notificationType,LEAD_OWNER_CUSTOM_NOTIFICATION_TITLE,notificationBody);
            }
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


     public static void sendLeadOwnerCustomNotification(List<Lead> leadList) {
        if (leadList == null || leadList.isEmpty()) {
            return;
        }
        CustomNotificationType notificationType = CustomNotificationService.getInstance().getCustomNotificationTypeByName(LEAD_OWNER_CUSTOM_NOTIFICATION_TYPE);
        
        for (Lead objLead : leadList) {            
            if (objLead.OwnerId != null && objLead.OwnerId.getSObjectType() == User.SObjectType) {
                Set<String> recipientIds = new Set<String>{ String.valueOf(objLead.OwnerId) };
                    String notificationBody = 'A new lead has been assigned to you. Lead Number: ' + objLead.LeadNumber__c;
                CustomNotificationService.sendCustomNotification(recipientIds,String.valueOf(objLead.Id),notificationType,LEAD_OWNER_CUSTOM_NOTIFICATION_TITLE,notificationBody);
            }
        }
    } 
    
    /**
* Handles push notifications for the provided Leads based on the specified notification type.
* Fetches the required Leads and push notification template, creates notification records with the Lead name as the template value, and inserts them in bulk.
*
* @param leadIds    Set of Lead record IDs for which notifications need to be sent.
* @param pushNotificationTemplateNames Set of push notification template names used to retrieve the corresponding PushNotificationTemplate__c records.
*/
    public static void sendMobilAppPushNotification(Set<Id> leadIds, String notificationType, Set<String> pushNotificationTemplateNames){
        
        LeadService objLeadService = LeadService.getInstance();
        List<Lead> leadList = objLeadService.getADHALeadByIds(new Set<Id>(leadIds));

        PushNotificationService objPushNotificationService = PushNotificationService.getInstance();
        List<PushNotification__c> pushNotificationRecords = new List<PushNotification__c>();
        NotificationService objNotificationService = NotificationService.getInstance();
        
        Map<String, PushNotificationTemplate__c> templateMap = objNotificationService.getPushNotificationTemplates(pushNotificationTemplateNames);
    
        for (Lead lead : leadList) {
            PushNotificationTemplate__c notificationTemplate = null;

            if (notificationType == 'Lead Created' || notificationType == 'Lead Closure') {
                notificationTemplate = templateMap.get(notificationType);
            } else if (pushNotificationTemplateNames.contains(lead.BookingStatus__c)) {
                notificationTemplate = templateMap.get(lead.BookingStatus__c);
            }

            if(notificationTemplate != null) {
               List<String> notificationValues = getPushNotificationValues(lead, notificationType);
                pushNotificationRecords.add(objPushNotificationService.getPushNotificationRecord(lead, notificationTemplate, notificationValues));  
            } 
        }
        objPushNotificationService.insertPushNotifications(pushNotificationRecords);
    }

    /**
 * Returns the dynamic values required for the selected push notification template.
 * The order of the values must match the placeholder order configured in PushNotificationTemplate__c.
 */
    private static List<String> getPushNotificationValues(Lead lead, String notificationType) {
        List<String> notificationValues = new List<String>();

        if (notificationType !=null) {
            notificationValues.add(lead.Name);
        } 

        return notificationValues;
    }

/**
 * @description Sends SMS notifications for ADHA Leads based on the specified notification type.
 * Retrieves the corresponding SMS template, creates IntegrationRecord__c records for each Lead, and inserts the integration records for further SMS processing.
 *
 * @param leadIds          Set of Lead record IDs for which SMS notifications need to be sent.
 * @param notificationType Type of notification to send. Supported values are 'Lead Created', 'Lead Closure', 'Lead TopUp Bank Loan'.
 */
    public static void sendADHALeadSMSNotification(Set<Id> leadIds, String notificationType) {
        NotificationService objNotificationService = NotificationService.getInstance();

        List<Lead> leadList = LeadService.getInstance().getADHALeadByIds(new Set<Id>(leadIds));
        List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
        Set<String> templateNames = new Set<String>{ADHA_CUSTOMER_CREATE_SMS_NOTIFICATION, ADHA_LEAD_CLOSURE_SMS_NOTIFICATION, ADHA_LEAD_TOPUP_BANK_LOAN_SMS_NOTIFICATION, ADHA_LEAD_NOT_RESPONDING_BLOOM_CALLS_SMS_NOTIFICATION, ADHA_LEAD_UNIT_RESERVATION_SMS_NOTIFICATION};
        Map<String, SMSTemplate__c> smsTemplateMap = objNotificationService.getSMSTemplates(templateNames);
       
        for(Lead leadObj : leadList) {
            String templateName;
            List<String> notificationValues = new List<String>();
 
            if (notificationType == 'Lead Created') {
                templateName = ADHA_CUSTOMER_CREATE_SMS_NOTIFICATION;
            } else if (notificationType == 'Lead Closure') {
                templateName = ADHA_LEAD_CLOSURE_SMS_NOTIFICATION;
            } else if (notificationType == 'Lead TopUp Bank Loan') {
                templateName = ADHA_LEAD_TOPUP_BANK_LOAN_SMS_NOTIFICATION;
            } else if (notificationType == 'ADHA Lead Not Answering Bloom Calls SMS Notification') {
                templateName = ADHA_LEAD_NOT_RESPONDING_BLOOM_CALLS_SMS_NOTIFICATION;
                notificationValues.add(leadObj.Owner.Phone);
            } else if (notificationType == 'ADHA Customer Unit Reservation SMS Notification') {
                templateName = ADHA_LEAD_UNIT_RESERVATION_SMS_NOTIFICATION;
                String unitName = leadObj.Unit__r != null && String.isNotBlank(leadObj.Unit__r.Name) ? leadObj.Unit__r.Name : '';
                notificationValues.add(unitName);
            }
 
            integrationRecords.add(objNotificationService.getSMSIntegrationRecord(leadObj, smsTemplateMap.get(templateName), notificationValues));
        }
        IntegrationRecordService.getInstance().insertIntegrationRecords(integrationRecords);
    }
    
    public static String getDynamicBody(String body, Lead objLead, Boolean shouldFetchBankDetails) {
        Map<String, String> bankDetails = new Map<String, String>{ 'bank_name' => '', 'beneficiary_name' => '', 'account_number' => '', 'IBAN_number' => '', 'swift_code' => '' };

        if(shouldFetchBankDetails && objLead.ProjectLookup__c != null) {
            List<BuildingSection__c> buildingSections = BuildingSectionService.getInstance().getBuildingSectionWithBankDetailsByProjectId(objLead.ProjectLookup__c);
            
            if(buildingSections != null && !buildingSections.isEmpty() && buildingSections[0].Primary_Account_Installment__r != null) {
                BankAccount__c objBankAccount = buildingSections[0].Primary_Account_Installment__r;
                bankDetails.put('bank_name', String.valueOf(objBankAccount.BankNameCorporate__c));
                bankDetails.put('beneficiary_name', String.valueOf(objBankAccount.BeneficiaryNameCorporate__c));
                bankDetails.put('account_number', String.valueOf(objBankAccount.AccountNumberCorporate__c));
                bankDetails.put('IBAN_number', String.valueOf(objBankAccount.IBANNoCorporate__c));
                bankDetails.put('swift_code', String.valueOf(objBankAccount.SwiftCodeCorporate__c));
            }
        }

        if(objLead.OwnerId != null) {
            body = body.replace('[Account Manager\'s Name]', objLead.OwnerId != null && objLead.Owner.Name != null ? objLead.Owner.Name : '');
            body = body.replace('[Account Manager\'s Phone Number]', String.isNotBlank(objLead.Owner.Phone) ? objLead.Owner.Phone : '');
            body = body.replace('[AccountManagersName]', objLead.OwnerId != null && objLead.Owner.Name != null ? objLead.Owner.Name : '');
            body = body.replace('[AccountManagersPhoneNumber]', String.isNotBlank(objLead.Owner.Phone) ? objLead.Owner.Phone : '');
        }

        String unitName = objLead.Unit__r != null && String.isNotBlank(objLead.Unit__r.Name) ? objLead.Unit__r.Name : '';
        body = body.replace('[bank_name]', bankDetails.get('bank_name'));
        body = body.replace('[beneficiary_name]', bankDetails.get('beneficiary_name'));
        body = body.replace('[account_number]', bankDetails.get('account_number'));
        body = body.replace('[IBAN_number]', bankDetails.get('IBAN_number'));
        body = body.replace('[swift_code]', bankDetails.get('swift_code'));
        body = body.replace('[Unit_Code]', unitName);
        body = body.replace('[Unit_Number]', unitName);
        return body;
    }
}
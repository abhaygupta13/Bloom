/*
* @Author : Akshay Khairnar
* @CreatedDate : 11 June 2025
* @Description : AzureUserTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Akshay      11JUN2025        Initial draft 
*****************************************************************************************************/

public without sharing class AzureUserTriggerHelper {
    
    private static final String MTD_SUPER_APP_WELCOME_EMAIL_TEMPLATE_ID { get { return 'SuperAppWelcomeEmailTemplateId'; } }
    private static final String MTD_SUPER_APP_ORG_WIDE_EMAIL_ADDRESS_ID { get { return 'SuperAppOrgWideEmailAddressId'; } }
    private static final String MTD_BAPP_WELCOME_EMAIL_TEMPLATE_ID { get { return 'BAPPAppWelcomeEmailTemplateId'; } }
    private static final String COMM_APP_WELCOME_EMAIL_TEMPLATE_ID { get { return 'CommunityAppWelcomeEmailTemplateId'; } }
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string BLOOM_APP_PASSWORD_CHANGE_EMAIL_TEMP_ID { get { return 'BloomAppPasswordChangeEmailTempId'; } }
    
    private static final String USER_INTEGRATION_SUB_ACTION_NAME_UPDATE { get { return 'NameUpdate'; } }
    private static final String USER_INTEGRATION_SUB_ACTION_USER_DEACTIVATE { get { return 'UserDeactivate'; } }
    private static final String USER_INTEGRATION_SUB_ACTION_EMAIL_UPDATE { get { return 'EmailUpdate'; } }
    private static final String USER_INTEGRATION_SUB_ACTION_ACTIVATE { get { return 'UserActivate'; } }
    private static final String SUPER_APP_STR { get { return 'Super App'; } }
    private static final String COMMUNITY_APP_STR { get { return 'Community App'; } }
    
    public static void handleBeforeInsert(List<User__c> newList) {
        for(User__c objUser : newList){
            objUser.Temporary_Password__c = Utility.generateRandomPassword();
        }
    }
    
    public static void sendWelcomeEmail(List<User__c> newList, Map<Id, User__c> oldMap) {
        EmailService objEmailService = EmailService.getInstance();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id superAppOWEId = objMetadataService.getAppSettingTextValue(MTD_SUPER_APP_ORG_WIDE_EMAIL_ADDRESS_ID);
        Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
        Id superAppWelcomeEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SUPER_APP_WELCOME_EMAIL_TEMPLATE_ID);
        Id orgWideEmail = objMetadataService.getAppSettingTextValue('BAPPOrgWideEmailAddress');
        Id BAPPWelcomeEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_BAPP_WELCOME_EMAIL_TEMPLATE_ID);
        Id CommAppWelcomeEmailTemplateId = objMetadataService.getAppSettingTextValue(COMM_APP_WELCOME_EMAIL_TEMPLATE_ID);
        EmailTemplate superAppEmailTemplate = objEmailService.getEmailTemplateById(superAppWelcomeEmailTemplateId);
        EmailTemplate BappAppEmailTemplate = objEmailService.getEmailTemplateById(BAPPWelcomeEmailTemplateId);
        EmailTemplate CommAppAppEmailTemplate = objEmailService.getEmailTemplateById(CommAppWelcomeEmailTemplateId);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        
        for (User__c userObj : newList) {
            String tempPassword = userObj.Temporary_Password__c;
            if (userObj.User_Type__c == 'Broker Agent' && String.isNotBlank(userObj.Email__c) && userObj.Azure_UserId__c != NULL && userObj.Azure_UserId__c != oldMap.get(userObj.Id).Azure_UserId__c) {
                String htmlBody = BappAppEmailTemplate.HtmlValue;
                htmlBody = htmlBody
                    .replace('{{{User__c.Name}}}', userObj.Name != null ? userObj.Name : '')
                    .replace('{{{User__c.Email__c}}}', userObj.Email__c != null ? userObj.Email__c : '')
                    .replace('{{{User__c.Temporary_Password__c}}}', tempPassword != null ? tempPassword : '');

            objEmailService.sendMailWithActivityHtmlBody( new List<String>{ userObj.Email__c }, BappAppEmailTemplate.Subject,htmlBody,userObj.Id, null,orgWideEmail);
            
            //For Super App 
            }else if (userObj.AppType__c == SUPER_APP_STR && userObj.User_Type__c == 'Owner' && String.isNotBlank(userObj.Email__c) && userObj.Azure_UserId__c != NULL && userObj.Azure_UserId__c != oldMap.get(userObj.Id).Azure_UserId__c) {
                String htmlBody = superAppEmailTemplate.HtmlValue;
                
                htmlBody = htmlBody
                    .replace('{User__c.Name__c}', userObj.Name != null ? userObj.Name : '')
                    .replace('{User__c.Email__c}', userObj.Email__c != null ? userObj.Email__c : '')
                    .replace('{User__c.Temporary_Password__c}', tempPassword != null ? tempPassword : '');

                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setOrgWideEmailAddressId(superAppOWEId);
                mail.setToAddresses(new String[] { userObj.Email__c });
                mail.setSubject(superAppEmailTemplate.Subject);
                mail.setWhatID(userObj.Id);
                mail.setHtmlBody(htmlBody);
                
                emails.add(mail); 
            }
            //for community App
            else if(String.isNotBlank(userObj.Email__c) && userObj.Azure_UserId__c != NULL && userObj.Azure_UserId__c != oldMap.get(userObj.Id).Azure_UserId__c){
                String htmlBody = CommAppAppEmailTemplate.HtmlValue;
                
                htmlBody = htmlBody
                    .replace('{User__c.Name__c}', userObj.Name != null ? userObj.Name : '')
                    .replace('{User__c.Email__c}', userObj.Email__c != null ? userObj.Email__c : '')
                    .replace('{User__c.Temporary_Password__c}', tempPassword != null ? tempPassword : '');

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setOrgWideEmailAddressId(superAppOWEId);
                mail.setToAddresses(new String[] { userObj.Email__c });
                mail.setSubject(CommAppAppEmailTemplate.Subject);
                mail.setWhatID(userObj.Id);
                mail.setHtmlBody(htmlBody); 
                emails.add(mail); 
            }
        }
        objEmailService.sendEmail(emails);
    }
    
    public static void handleAfterInsert(List<User__c> newList) {
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
        List<Contact> contactList = new List<Contact>();
        for(User__c objUser : newList){
             integrationRecordsToInsert.add(objCustomUserService.getIntegrationRecord(objUser, ''));
            if(objUser.Contact__c != NULL){
                contactList.add(new Contact(Id = objUser.Contact__c, User__c = objUser.Id));
            }
        }
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        integService.insertIntegrationRecords(integrationRecordsToInsert);
        
        ContactService.getInstance().updateContactsWithoutTrigger(contactList);
    }

    public static void handleBeforeUpdate(List<User__c> newList, Map<Id, User__c> oldMap) {
        for(User__c objUser : newList){
            if(oldMap.get(objUser.Id).isActive__c != objUser.isActive__c ||
            (oldMap.get(objUser.Id).Contact__c != objUser.Contact__c && objUser.Contact__c != null) || 
            (oldMap.get(objUser.Id).User_Account__c != objUser.User_Account__c && objUser.User_Account__c != null)){
                objUser.IsSendToAB2C__c = true;
            }
        }
    }
    
    public static void handleAfterUpdate(List<User__c> newList, Map<Id, User__c> oldMap) {
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(User__c objUser : newList){
            if (!oldMap.get(objUser.Id).IsSendToAB2C__c && objUser.IsSendToAB2C__c) {
                if(String.isBlank(objUser.Azure_UserId__c)){
                    integrationRecordsToInsert.add(objCustomUserService.getIntegrationRecord(objUser, ''));
                }else if(String.isNotBlank(objUser.Azure_UserId__c) && oldMap.get(objUser.Id).isActive__c != objUser.isActive__c && !objUser.isActive__c && oldMap.get(objUser.Id).isActive__c){
				 	integrationRecordsToInsert.add(objCustomUserService.getIntegrationRecord(objUser, USER_INTEGRATION_SUB_ACTION_USER_DEACTIVATE));
                }else if(String.isNotBlank(objUser.Azure_UserId__c) && oldMap.get(objUser.Id).UserName__c != objUser.UserName__c && String.isNotBlank(objUser.UserName__c)){
                    integrationRecordsToInsert.add(objCustomUserService.getIntegrationRecord(objUser, USER_INTEGRATION_SUB_ACTION_EMAIL_UPDATE));
                }else if(String.isNotBlank(objUser.Azure_UserId__c) && (oldMap.get(objUser.Id).Name != objUser.Name && String.isNotBlank(objUser.Name) || oldMap.get(objUser.Id).Contact__c != objUser.Contact__c || oldMap.get(objUser.Id).User_Account__c != objUser.User_Account__c)){
                    integrationRecordsToInsert.add(objCustomUserService.getIntegrationRecord(objUser, USER_INTEGRATION_SUB_ACTION_NAME_UPDATE));
                }else if(String.isNotBlank(objUser.Azure_UserId__c) && oldMap.get(objUser.Id).isActive__c != objUser.isActive__c && objUser.isActive__c && !oldMap.get(objUser.Id).isActive__c){
                    integrationRecordsToInsert.add(objCustomUserService.getIntegrationRecord(objUser, USER_INTEGRATION_SUB_ACTION_ACTIVATE));
                }
            }

            if(objUser.LastPasswordChangedDate__c != oldMap.get(objUser.Id).LastPasswordChangedDate__c && objUser.Contact__c != null && objUser.AppType__c == SUPER_APP_STR){
                Id bloomAppPassChangeEmailTemplateId = objMetadataService.getAppSettingTextValue(BLOOM_APP_PASSWORD_CHANGE_EMAIL_TEMP_ID);
                Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
                Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(bloomAppPassChangeEmailTemplateId, noReplyBloomSalesOWDId, objUser.Id, objUser.Contact__c, null, null, null);
                emailList.add(objMail); 
            }
        }
        IntegrationRecordService.getInstance().insertIntegrationRecords(integrationRecordsToInsert);
        objEmailService.sendEmail(emailList);
    }
}
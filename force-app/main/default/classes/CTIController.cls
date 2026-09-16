/***
Class       : CTIController
    Author      : Aman Bharti
    Description :
    TestClass   :
    ----------------------------------------------------------------------------------------------------------------
    -- History --
    ----------------------------------------------------------------------------------------------------------------
    Sr.No.  version              Date                Details
    1.          V1.0            13/05/26           Initial Version
     ****************************************************************************************************************/

public without sharing class CTIController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPhoneDetails(Id recordId) {
        Map<String, String> phoneMap = new Map<String, String>();
        Utility objUtility = Utility.getInstance();
        
        if (recordId == null) {
            return phoneMap;
        }
        
        try {
            if (recordId.getSObjectType() == Contact.SObjectType) {
                ContactService objContactService = ContactService.getInstance();
                Contact contact = objContactService.getContactById(recordId);
                
                if (contact != null) {
                    phoneMap.put('Mobile Phone', objUtility.maskPhoneNumber(contact.MobilePhone));
                    phoneMap.put('Home Phone', objUtility.maskPhoneNumber(contact.HomePhone));
                    phoneMap.put('Other Phone', objUtility.maskPhoneNumber(contact.OtherPhone));
                }
            }
            else if (recordId.getSObjectType() == Account.SObjectType) {
                AccountService objAccountService = AccountService.getInstance();
                Account account = objAccountService.getAccountById(recordId);
                
                if (account != null) {
                    phoneMap.put('Phone',  objUtility.maskPhoneNumber(account.Phone));
                    phoneMap.put('Home Phone',  objUtility.maskPhoneNumber(account.PersonHomePhone));
                    phoneMap.put('Mobile Phone',  objUtility.maskPhoneNumber(account.PersonMobilePhone));
                    phoneMap.put('Other Phone',  objUtility.maskPhoneNumber(account.PersonOtherPhone));
                }
            }
            else if (recordId.getSObjectType() == Lead.SObjectType) {
                LeadService objLeadService = LeadService.getInstance();
                Lead lead = objLeadService.getLeadById(recordId);
                
                if (lead != null) {
                    phoneMap.put('Mobile Phone',  objUtility.maskPhoneNumber(lead.MobilePhone));
                    phoneMap.put('Phone',  objUtility.maskPhoneNumber(lead.Phone));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Unable to retrieve phone details: ' + e.getMessage());
        }
        
        return phoneMap;
    }
    
    @AuraEnabled
    public static void createIntegrationRecord(Id recordId, String label, String skill) {
        
        try {
            String phoneNumber;
            
            if (recordId.getSObjectType() == Contact.SObjectType) {
                ContactService objContactService = ContactService.getInstance();
                Contact contact = objContactService.getContactById(recordId);
                
                if (contact != null) {
                    if (label == 'Mobile Phone') {
                        phoneNumber = contact.MobilePhone;
                    } else if (label == 'Home Phone') {
                        phoneNumber = contact.HomePhone;
                    } else if (label == 'Other Phone') {
                        phoneNumber = contact.OtherPhone;
                    }
                }
                
            } else if (recordId.getSObjectType() == Account.SObjectType) {
                AccountService objAccountService = AccountService.getInstance();
                Account account = objAccountService.getAccountById(recordId);
                
                if (account != null) {
                    if (label == 'Mobile Phone') {
                        phoneNumber = account.PersonMobilePhone;
                    } else if (label == 'Home Phone') {
                        phoneNumber = account.PersonHomePhone;
                    } else if (label == 'Other Phone') {
                        phoneNumber = account.PersonOtherPhone;
                    } else if (label == 'Phone') {
                        phoneNumber = account.Phone;
                    }
                }
                
            } else if (recordId.getSObjectType() == Lead.SObjectType) {
                LeadService objLeadService = LeadService.getInstance();
                Lead leadRecord = objLeadService.getLeadById(recordId);
                
                if (leadRecord != null) {
                    if (label == 'Mobile Phone') {
                        phoneNumber = leadRecord.MobilePhone;
                    } else if (label == 'Phone') {
                        phoneNumber = leadRecord.Phone;
                    }
                }
            }
            
            CTIHandler.getInstance().getIntegrationRecord(recordId, phoneNumber, skill);
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create integration record: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getSkillOptions() {
        
        MetadataService objMetadataService = MetadataService.getInstance();
        UserService userService = UserService.getInstance();
        String skills = objMetadataService.getAppSettingTextValue('ClickToDialSkills');
        User user = userService.getUsersById(UserInfo.getUserId());
        if(!String.isBlank(user.ClickToDialSkill__c)){
            return new List<String>{ user.ClickToDialSkill__c };
        }
        
        return String.isBlank(skills) ? new List<String>() : skills.split(',');
    }
}
/***
Class       : NICEIntegrationController
Author      : Aman Bharti
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0            13/05/26           Initial Version 
****************************************************************************************************************/

public without sharing class NICEIntegrationController {//CTIController// CTIHandler

    public class PhoneDetail {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String phoneNumber;

        public PhoneDetail(String label, String value, String phoneNumber) {
            this.label = label;
            this.value = value;
            this.phoneNumber = phoneNumber;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PhoneDetail> getPhoneDetails(Id recordId) {
        if (recordId == null){ 
            return new List<PhoneDetail>();
        }
        Utility objUtility = Utility.getInstance();
        List<PhoneDetail> phoneList = new List<PhoneDetail>();
        String objectName = recordId.getSObjectType().getDescribe().getName();

        if (objectName == 'Contact') {
            ContactService objContactService = ContactService.getInstance();
            List<Contact> conList = objContactService.getContactsByIds(new Set<Id>{recordId}).values();
            
            if (!conList.isEmpty()) {
                Contact con = conList[0];
                addPhoneToList(phoneList, 'Mobile Phone', con.MobilePhone);
                addPhoneToList(phoneList, 'Home Phone', con.HomePhone);
                addPhoneToList(phoneList, 'Other Phone', con.OtherPhone);
            }
        }
        else if (objectName == 'Account') {
            AccountService objAccountService = AccountService.getInstance();
            List<Account> accountList = objAccountService.getAccountByIds(new Set<Id>{recordId});
            
            if (!accountList.isEmpty()) {
                Account accRecord = accountList[0];
                addPhoneToList(phoneList, 'Phone', accRecord.Phone);
                addPhoneToList(phoneList, 'Home Phone', accRecord.PersonHomePhone);
                addPhoneToList(phoneList, 'Mobile Phone', accRecord.PersonMobilePhone);
                addPhoneToList(phoneList, 'Other Phone', accRecord.PersonOtherPhone);
            }
        }
        else if (objectName == 'Lead') {
            LeadService objLeadService = LeadService.getInstance();
            List<Lead> leadList = objLeadService.getLeadByIds(new Set<Id>{recordId});
            
            if (!leadList.isEmpty()) {
                Lead leadRec = leadList[0];
                addPhoneToList(phoneList, 'Mobile Phone', leadRec.MobilePhone);
                addPhoneToList(phoneList, 'Phone', leadRec.Phone);
            }
        }
        return phoneList;
    }

    private static void addPhoneToList(List<PhoneDetail> phoneList, String label, String rawValue) {
        if (String.isNotBlank(rawValue)) {
            Utility objUtility = Utility.getInstance();
            phoneList.add(new PhoneDetail(label, objUtility.maskPhoneNumber(rawValue), rawValue));
        }
    }

    @AuraEnabled
    public static void createIntegrationRecord(Id recordId, String phoneNumber, String maskedValue, String skill) {
        String objectName = recordId.getSObjectType().getDescribe().getName();
        NICEIntegrationHandler.getInstance().getIntegrationRecordObj(objectName, recordId, phoneNumber, maskedValue, skill);//
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSkillOptions() {

        MetadataService objMetadataService = MetadataService.getInstance();
        String skills = objMetadataService.getAppSettingTextValue('ClickToDialSkills');

        List<Map<String, String>> options = new List<Map<String, String>>();

        if (String.isBlank(skills)) {
            return options;
        }

        for (String skill : skills.split(',')) {
            skill = skill.trim();

            options.add(new Map<String, String>{
                'label' => skill,
                'value' => skill
            });//
        }
        return options;
    }
}
/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : ContactTriggerHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public class ContactTriggerHandler  implements ITriggerHandler{
    
    private static final string CONTACT_RT_DEV_NAME_BROKER { get { return 'Broker'; } }
    private static final String CASE_RT_DEV_NAME_BROKER_REGISTRATION { get { return 'BrokerAgentRegistrationAndUpdate'; } }
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        ContactTriggerHelper.handleBeforeInsertFieldUpdates((List<Contact>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        Id brokerContactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, CONTACT_RT_DEV_NAME_BROKER);

        List<Contact> contacts = (List<Contact>)newList;
        List<Contact> contactList = new List<Contact>();
        
        ContactTriggerHelper.createDocuments(contacts);

        // BAPP Copies documents from BrokerApplicant__c or Case__c to Contact
        BrokerApplicationTriggerHelper.copyDocumentsFromApplicantOrCase(contacts);
        
        List<Contact> brokerContacts = new List<Contact>();
        // Collect AccountIds of broker contacts
        //Set<Id> accountIds = new Set<Id>();
        for (Contact con : contacts) {
            if (con.RecordTypeId == brokerContactRecordTypeId && con.AccountId != null) {
                brokerContacts.add(con);
            }
            if (con.RecordTypeId == brokerContactRecordTypeId) {
                contactList.add(con);
            }
            
        }
        
        // Call Azure user creation if we found any
        if (!brokerContacts.isEmpty()) {
            ContactTriggerHelper.createAzureUser(brokerContacts);
        }
        if (!contactList.isEmpty()) {
        	ContactTriggerHelper.updateCaseWithContactLookup(contactList);
        }
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        ContactTriggerHelper.handleBeforeUpdateFieldUpdates((List<Contact>)newList,(Map<Id,Contact>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        ContactTriggerHelper.handleAfterUpdateFieldUpdates(newList,(Map<Id, Contact>) oldMap);    
        ContactTriggerHelper.handleContactUpdates(newList,(Map<Id, Contact>) oldMap);    
        Set<Id> caseIds = new Set<Id>();
        Set<Id> applicantIds = new Set<Id>();
        for (Contact con : (List<Contact>) newList) {
            if (con.CaseId__c != null) {
                caseIds.add(con.CaseId__c);
            }
            if (con.BrokerApplicant__c != null) {
                applicantIds.add(con.BrokerApplicant__c);
            }
        }
        Set<Id> validCaseIds = CaseService.getValidBrokerCaseIds(caseIds, CASE_RT_DEV_NAME_BROKER_REGISTRATION);
        if (!validCaseIds.isEmpty()) {
            system.debug('validCaseIds-->'+validCaseIds);
            //ContactTriggerHelper.syncCaseDocumentsToContact((List<Contact>) newList,(Map<Id, Contact>) oldMap,validCaseIds);
             ContactTriggerHelper.syncDocumentsToContact((List<Contact>) newList, validCaseIds, 'CASE');
        }
        if (!applicantIds.isEmpty()) {
            //ContactTriggerHelper.syncApplicantDocumentsToContact((List<Contact>) newList,(Map<Id, Contact>) oldMap,applicantIds);
             ContactTriggerHelper.syncDocumentsToContact((List<Contact>) newList, applicantIds, 'APPLICANT');
        }
        
        // Document Update Support
        Id brokerContactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, CONTACT_RT_DEV_NAME_BROKER);
        List<Contact> contacts = (List<Contact>)newList;
    
        // Collect only broker contacts
        List<Contact> brokerContacts = new List<Contact>();
        for (Contact con : contacts) {
            if (con.RecordTypeId == brokerContactRecordTypeId) {
                brokerContacts.add(con);
            }
        }
    
        // --- 1. Call updateContactDocuments only if BrokerContactRole__c is updated ---
        Boolean isBrokerContactRoleUpdated = false;
        for (Contact newCon : contacts) {
            Contact oldCon = (Contact) oldMap.get(newCon.Id); // FIXED CAST
            if (oldCon != null && newCon.BrokerContactRole__c != oldCon.BrokerContactRole__c) {
                isBrokerContactRoleUpdated = true;
                break;
            }
        }
    
        if (isBrokerContactRoleUpdated) {
            ContactTriggerHelper.updateContactDocuments(
                (List<Contact>)newList,
                (Map<Id, Contact>)newMap,
                (List<Contact>)oldList,
                (Map<Id, Contact>)oldMap
            );
        }
    
      
    }
    
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}
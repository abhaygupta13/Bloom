/***
Class       : ContactService
Author      : Biswajeet
Description : 
TestClass   : ContactService
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/

public inherited sharing class ContactService {
    
    private static ContactService instance;
    
    private ContactService() {
    }
    
    public static ContactService getInstance() {
        if (instance == null) {
            instance = new ContactService();
        }
        return instance;
    }
    
    public List<Contact> getContactEmail(List<Case> caseList){
        Set<Id> contactIds = new  Set<Id>();
        for(Case caseObj : caseList){
            contactIds.add(caseObj.contactId);
        }
        return getContactByIds(new List<Id>(contactIds));
    }
    
    //Insert Contacts
    public List<Contact> insertContacts(List<Contact> contactList) {
        if (contactList != null && !contactList.isEmpty()) {
            insert contactList;
        }
        return contactList;
    }
    
    //Insert Contacts
    public Contact insertContact(Contact con) {
        return insertContacts(new List<Contact>{ con })[0];
    }
    
    // Update Contacts
    public List<contact> updateContacts(List<contact> contactList){
        if(contactList != NULL && !contactList.isEmpty()){
            update contactList;
        }
        return contactList;
    }
    
    //Update Contacts without trigger
    public List<Contact> updateContactsWithoutTrigger(List<Contact> conList) {
        if (conList != null && !conList.isEmpty()) {
            ContactTriggerHandler.isTriggerDisabled = true;
            update conList;
            ContactTriggerHandler.isTriggerDisabled = false;
        }
        return conList;
    }
    
    //Update Contact without trigger
    public Contact updateContactWithoutTrigger(Contact con) {
        return updateContactsWithoutTrigger(new List<Contact>{ con })[0];
    }
    
    public List<Contact> getPrimaryContactByAccountId(Id accountId,Boolean isPrimary) {
        return [
            SELECT Id, Email, Phone, MobilePhone, Name
            FROM Contact
            WHERE AccountId = :accountId AND PrimaryContact__c = TRUE
        ];
    }
    
    public List<Contact> getContactByAccountId(Id accountId) {
        return [ SELECT Id, FirstName, MiddleName, LastName, Email, PassportNumber__c, Emirates_Id__c, EID_Expiry_Date__c, Name,Phone FROM Contact WHERE accountID = :accountId ORDER BY CreatedDate ASC];
    }
    
    public List<Contact> getActiveContactByAccountId(Set <Id> accountId) {
        return [SELECT Id, FirstName,AccountId,MiddleName, LastName, Email, PassportNumber__c, Emirates_Id__c, EID_Expiry_Date__c, Name,Phone,IsActive__c FROM Contact WHERE accountID = :accountId AND IsActive__c = true];
    }
    
    public List<Contact> getContactByIds(List<Id> ContactIds) {
        return [SELECT id, FirstName, LastName, Email, MobilePhone, PassportNumber__c, Emirates_Id__c, EID_Expiry_Date__c, AccountId FROM Contact WHERE Id = :ContactIds];
    }
    
    public Contact getContactById(Id ContactId) {
        return [SELECT id, MobilePhone, PassportExpiryDate__c, BRN_RERA_Expiry_Date__c, BrokerContactRole__c, FirstName, LastName, Name, Email, PrimaryMobilePhone__c, Account.TypeOfEstablishment__c, PassportNumber__c, Emirates_Id__c, Account.Name, EID_Expiry_Date__c, AccountId, MobileCountryCode__c FROM Contact WHERE Id = :ContactId];
    }
    
    public List<Contact> getContactByAccountIdNReceiveInvoiceCommunication(Set<Id> accIdSet){
        return [SELECT Id,Name,Email,ReceiveInvoiceCommunication__c 
                FROM Contact WHERE accountId IN :accIdSet AND ReceiveInvoiceCommunication__c = true AND Email != null];
    }

    public List<Contact> getBrokerAgentByRoles(Set<Id> accIdSet){
        return [SELECT Id,Name,Email,AccountId 
                FROM Contact WHERE AccountId IN :accIdSet AND BrokerContactRole__c INCLUDES ('Admin','SuperAdmin','FinancialAdmin','AuthorizedSignatoryOfficer') AND Email != null];
    }
    
    public List<Contact> getContactByEmails(Set<String> emailSet){
        return [SELECT Id, AccountId, Email FROM Contact WHERE PrimaryContact__c = true AND Email IN :emailSet];
    }

    public List<Contact> getContactByEmail(Set<String> emailSet){
        return [SELECT Id, Name,AccountId FROM Contact WHERE Email IN :emailSet];
    }
    
    //BAPP : 
    public Map<Id, Contact> getContactsByIds(Set<Id> contactIds) {
        return new Map<Id, Contact>(
            [SELECT Id, Email, Name, BrokerContactRole__c, AccountId,
             MobilePhone, HomePhone, OtherPhone, SecondaryEmail__c, TertiaryEmail__c
             FROM Contact WHERE Id IN :contactIds]
        );
    }
    
    public List<Contact> getActiveContactsByAccount(Id accountId) {
        return [SELECT Id, Name FROM Contact WHERE AccountId = :accountId AND IsActive__c = true];
    }
    //Get ASO Contacts
    public List<Contact> getASOContactsByAccountIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) return new List<Contact>();
        
        return [SELECT Id, Name, Email, BrokerContactRole__c, AccountId FROM Contact WHERE AccountId IN :accountIds AND BrokerContactRole__c INCLUDES ('AuthorizedSignatoryOfficer','FinancialAdmin')];
    }
    
    public List<Contact> getBrokerAuthSignContactsByAccount(String agencyId) {
        return [SELECT Id, Name, Title, Designation__c
                FROM Contact 
                WHERE AccountId = :agencyId
                AND BrokerContactRole__c INCLUDES ('AuthorizedSignatoryOfficer')
                LIMIT 1];
    }
    /**
* Get Agent Contacts for a set of Account IDs who have not received the email yet
*/
    public List<Contact> getAgentContactsByAccountIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) return new List<Contact>();
        
        return [ SELECT Id, Email, IsSendEmail__c, AccountId FROM Contact WHERE AccountId IN :accountIds AND BrokerContactRole__c INCLUDES ('Agent') AND IsSendEmail__c = false AND Email != null];
    }

    public List<Contact> getContactByEmiratesId(string emiratesId){
        return [SELECT Id, Name, Email, Account.RecordTypeId,
                UniqueIdentifierNumber__c, AccountId, Birthdate, Nationality__c,
                PrimaryMobileCountryCode__c, SecondaryMobileCountryCode__c, TertiaryMobileCountryCode__c,
                PrimaryMobilePhone__c, SecondaryMobilePhone__c, TertiaryMobilePhone__c, PassportNumber__c,
                SecondaryEmail__c, TertiaryEmail__c,
                Emirates_Id__c FROM Contact WHERE Emirates_Id__c = :emiratesId];
    }
    
    public List<Contact> getContactByActiveDirectoryId(string activeDirectoryId){
        return [SELECT Id, Name, Email, AccountId, UniqueIdentifierNumber__c, 
                Birthdate, Nationality__c, Account.RecordTypeId, User__r.Azure_UserId__c,
                PrimaryMobileCountryCode__c, SecondaryMobileCountryCode__c, TertiaryMobileCountryCode__c,
                PrimaryMobilePhone__c, SecondaryMobilePhone__c, TertiaryMobilePhone__c, PassportNumber__c,
                SecondaryEmail__c, TertiaryEmail__c,
                Emirates_Id__c FROM Contact WHERE User__r.Azure_UserId__c = :activeDirectoryId];
    }
    
    // BAPP Fetch Contacts By Ids - Static Method
    public static Map<Id, Contact> fetchContactsByIds(Set<Id> contactIds) {
        return new Map<Id, Contact>([SELECT Id, RecordTypeId, BrokerContactRole__c,EID_Expiry_Date__c, PassportExpiryDate__c, CaseId__c, BRN_RERA_Expiry_Date__c, AccountId FROM Contact WHERE Id IN :contactIds]);
    }
    
    // BAPP Update Contact
    public static void updateExistingContacts(List<Contact> contactList){
        if(contactList != null && !contactList.isEmpty()){
            update contactList;
        }
    }
    
    //BAPP
    public List<Contact> getContactsByNationalIds(Set<String> nationalIds, Set<Id> accountIds) {
        if (nationalIds == null || nationalIds.isEmpty()) {
            return new List<Contact>();
        }
        return [SELECT Id,Emirates_Id__c, AccountId,PassportNumber__c FROM Contact WHERE Emirates_Id__c IN :nationalIds AND AccountId IN :accountIds];
    }
    public List<Contact> getContactByAccountIds(Set <Id> accountId) {
        return [SELECT Id, AccountId,FirstName, MiddleName, LastName, Email, PassportNumber__c,IsSuspended__c, Emirates_Id__c, EID_Expiry_Date__c, Name,Phone,IsActive__c FROM Contact WHERE accountID = :accountId];
    }

    public List<Contact> getPrimaryContactsByAccountIds(Set<Id> accountIds) {
        return [
            SELECT Id, Email, Phone, MobilePhone, Name, AccountId
            FROM Contact
            WHERE AccountId in :accountIds AND PrimaryContact__c = TRUE
        ];
    }
}
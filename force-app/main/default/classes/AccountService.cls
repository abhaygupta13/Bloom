/***
Class       : AccountService
Author      : Smaartt
Description : 
TestClass   : AccountServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
1.1         V1.1              29/04/25          Added new method for evaluate SAP Integration Fields
****************************************************************************************************************/

public inherited sharing class AccountService {
    
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT { get { return 'Broker_Agency'; } }
    private static final string INTEGRATION_ACTION_UPDATE { get { return 'Update'; } }
    private static final string INTEGRATION_ACTION_INSERT { get { return 'Insert'; } }
    private static final string ACCOUNT_OBJECT_API_NAME { get { return 'Account'; } }
    private static final string INTEGRATION_TYPE_ACCOUNT_SAP_INTEGRATION { get { return 'ACCOUNT_SAP_INTEGRATION'; } }
    private static final string Broker_Agency { get { return 'Broker_Agency'; } }
    
    private static AccountService instance;
    
    private AccountService() {
        
    }
    
    public static AccountService getInstance() { 
        if(instance == null) {
            instance = new AccountService();
        }
        return instance;
    }
    
    /*
* Method to fetch all the relationships
*/
    public static List<AccountRelationship__c> getRelatedAccountsForAccountId(Id accountId){
        List<AccountRelationship__c> allRelationships = new List<AccountRelationship__c>();
        allRelationships = [SELECT Id,Account__c,RelatedAccount__c,RelationshipType__c,RelatedAccount__r.Name FROM AccountRelationship__c WHERE Account__c=:accountId]; // AND RelatedAccount__r.AMLScreeningResult__c=:Constants.AML_SCREENING_RESULT
        return allRelationships;
    }
    
    public List<Account> getDuplicatePersonAccounts(String emiratesId, string passportNumber, string nationality){
        List<Account> accountList = new List<Account>();
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        if(String.isNotBlank(emiratesId)){
            accountList = [SELECT Id, Name, Emirates_Id__pc, Legal_Status__c, PassportNumber__pc, Nationality__pc,
                           Nationality__c, IsPersonAccount
                           FROM Account WHERE RecordTypeId = :personAccountRecordTypeId
                           AND Emirates_Id__pc = :emiratesId ORDER BY CreatedDate DESC];
        }
        if(String.isNotBlank(passportNumber) && String.isNotBlank(nationality) && accountList.isEmpty()){
            accountList = [SELECT Id, Legal_Status__c,Name, Emirates_Id__pc, PassportNumber__pc, Nationality__pc,
                           Nationality__c, IsPersonAccount
                           FROM Account WHERE RecordTypeId = :personAccountRecordTypeId
                           AND PassportNumber__pc = :passportNumber AND Nationality__c = :nationality ORDER BY CreatedDate DESC];
        }
        return accountList;
    }
    
    public  Id getRelatedContact(Id accId){
        
        Account accObj= getAccountById(accId);
        
        if(accObj.IsPersonAccount){
            return  accObj.PersonContactId;   
        }
        else{
            List<Contact> conList = [Select id from Contact where PrimaryContact__c = true and AccountId =:accId];
            return !conList.isEmpty() ? conList[0].Id : null;    
        }
    }
    public String getRelatedContactName(Id accId){
        String contactName = '';
        Account accObj = getAccountById(accId);
        
        if (accObj.IsPersonAccount) {
            contactName = (accObj.FirstName != null ? accObj.FirstName + ' ' : '') + (accObj.LastName != null ? accObj.LastName : '');
        }
        else {
            List<Contact> conList = [SELECT Id, FirstName, LastName FROM Contact WHERE PrimaryContact__c = true AND AccountId = :accId LIMIT 1];
            if (!conList.isEmpty()) {
                contactName = (conList[0].FirstName != null ? conList[0].FirstName + ' ' : '') + (conList[0].LastName != null ? conList[0].LastName : '');
            }
        }
        if (String.isBlank(contactName)) {
            contactName = accObj.Name;
        }
        
        return contactName;
    }
    public String getRelatedContactNameArabic(Id accId){
        String contactName = '';
        Account accObj = getAccountById(accId);
        
        if (accObj.IsPersonAccount) {
            contactName = accObj.NameinArabic__c;
        }
        else {
            List<Contact> conList = [SELECT Id, FirstName, LastName FROM Contact WHERE PrimaryContact__c = true AND AccountId = :accId LIMIT 1];
            if (!conList.isEmpty()) {
                contactName = (conList[0].FirstName != null ? conList[0].FirstName + ' ' : '') + (conList[0].LastName != null ? conList[0].LastName : '');
            }
        }
        if (String.isBlank(contactName)) {
            contactName = accObj.NameinArabic__c;
        }
        
        return contactName;
    }
    public  String getRelatedContactEmail(Id accId){
        
        Account accObj= getAccountById(accId);
        
        if(accObj.IsPersonAccount){
            return  accObj.PersonEmail;   
        }
        else{
            List<Contact> conList = [Select id,email  from Contact where PrimaryContact__c = true and AccountId =:accId];
            return !conList.isEmpty() ? conList[0].email : null;    
        }
        
        
    }
    
    public List<Account> getDuplicateOrganizationAccounts(String tradeLicenseNumber, string registrationAuthority){
        List<Account> accountList = new List<Account>();
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        if(String.isNotBlank(tradeLicenseNumber) && String.isNotBlank(registrationAuthority)){
            accountList = [SELECT Id, Name,Legal_Status__c, Trade_License_No__c, Registration_Authority__c,
                           IsPersonAccount
                           FROM Account WHERE RecordTypeId = :organizationAccountRecordTypeId
                           AND Trade_License_No__c = :tradeLicenseNumber
                           AND Registration_Authority__c = :registrationAuthority];
        }
        return accountList;
    }
    
    public List<Account> getAccountByIds(Set<Id> accountIds){
        return [SELECT Id, RecordType.DeveloperName,RecordTypeId , Salutation, FirstName__pc, MiddleName__pc, LastName__pc,AgreementRenewalStatus__c, 
                Nationality__pc, NameinArabic__c, PersonLeadSource, PersonMailingCity, PersonMailingCountry, PersonMailingCountryCode,AgreementExpiryDate__c,
                PersonMailingLatitude, PersonMailingLongitude,PersonMailingPostalCode, PersonMailingState,PersonMailingStateCode,PersonMailingStreet, 
                Gender__pc , PersonBirthdate, Registration_Authority__pc, CountryOfResidence__pc, Emirates_Id__pc, EID_Expiry_Date__pc, EID_Issue_Date__pc, 
                EmploymentStatus__pc, LanguagePreference__pc, MobileCountryCode__pc, PassportExpiryDate__pc, PassportIssueDate__pc, PassportNumber__pc,
                PlaceofIssue__pc, Position__pc, Religion__pc, ResidentStatus__pc, FirstName, MiddleName, LastName, Name, Phone, Nationality__c,
                Registration_Authority__c, Trade_License_Expiry_Date__c, Trade_License_Issue_Date__c, Trade_License_No__c, Percentage_of_Share_Purchased__c,
                PlaceofRegistration__c, PoaExist__c, BloomStaffEmail__c, CompanyEmail__c, CustomerClassification__c, CustomerSubType__c, CustomerType__c,
                MobileCountryCode__c,Place_of_Issuance__c,Broker_Application__c, WarningCounter__c,  WarningReason1__c, WarningReason2__c, WarningReason3__c, 
                SuspensionReason__c, Blacklist_Reason__c,  ApprovalStatus__c, Scenarios__c,  ExecutiveSalesDirector__c, LineManager__c,  isSuspended__c, 
                Blacklisted__c, BBMId__c,  Broker_Application__r.ApplicationNumber__c,PersonHomePhone,PersonMobilePhone,PersonOtherPhone
                FROM Account WHERE Id IN :accountIds ORDER BY CreatedDate DESC];
        
    }
    
    public List<Account> getAccountsByIds(Set<Id> accountIds){
        return [SELECT Id, IsPersonAccount, PersonEmail,AgreementRenewalStatus__c
                FROM Account WHERE Id IN :accountIds ORDER BY CreatedDate DESC];
        
    }
    
    public List<Account> getAccountWithLatesetContact(Set<Id> accountIds){
        return [SELECT Id, IsPersonAccount, PersonContactId, 
                (SELECT Id FROM Contacts ORDER BY CreatedDate DESC LIMIT 1) 
                FROM Account WHERE Id IN :accountIds];
        
    }
    
    public Account getAccountById(Id accountId){
        return [SELECT Id, IsPersonAccount,PersonContactId, RecordType.DeveloperName,RecordTypeId , Salutation, FirstName__pc, MiddleName__pc, LastName__pc, 
                Nationality__pc, NameinArabic__c, PersonLeadSource, PersonMailingCity, PersonMailingCountry, PersonMailingCountryCode,
                PersonMailingLatitude, PersonMailingLongitude,PersonMailingPostalCode, PersonMailingState,PersonMailingStateCode,PersonMailingStreet, 
                Gender__pc , PersonBirthdate, Registration_Authority__pc, CountryOfResidence__pc, Emirates_Id__pc, EID_Expiry_Date__pc, EID_Issue_Date__pc, 
                EmploymentStatus__pc, LanguagePreference__pc, MobileCountryCode__pc, PassportExpiryDate__pc, PassportIssueDate__pc, PassportNumber__pc,
                PlaceofIssue__pc, Position__pc, Religion__pc, ResidentStatus__pc, FirstName, MiddleName, LastName, Name, Phone, Nationality__c,
                Registration_Authority__c, Trade_License_Expiry_Date__c, Trade_License_Issue_Date__c, Trade_License_No__c, Percentage_of_Share_Purchased__c,
                PlaceofRegistration__c, PoaExist__c, BloomStaffEmail__c, CompanyEmail__c, CustomerClassification__c, CustomerSubType__c, CustomerType__c,
                MobileCountryCode__c, PersonEmail,PersonMobilePhone,Rating,SourceofFunds__pc,Place_of_Issuance__c,PersonGenderIdentity,
                IsBFMVIPCustomer__c, NumberOfPets__c,Drawloop_Next_1__c,SAP_Company_Code__c,Joint_Buyer__c,Main_Buyer__c,SAP_BP_No__c,
                //BH Mobile APP Fields
                MobilePhone__pc,Operator_License_Number__c,Operator_license_Exp_Dtae__c,Operator_Office_Number__c,Operator_Name__c,EJARI_Tawteeq_start_date__c,EJARI_Tawteeq_end_date__c,EJARI_Tawteeq_number__c,
                Move_In_Date__c,Emirates_ID_number__c,Emirates_ID_expiry_date__c,Emergency_contact_01__c,Emergency_contact_02__c,
                Total_Number_of_Adults_Occupants__c,Special_Needs_Comments__c,Total_Number_of_Child_Occupants__c,Occupant_with_special_needs__c
                ,Representative_Contact_Number__c,Representative_Email__c,Representative_Name__c, VATUndertakingIssueDate__c, AddressLine01__c, AddressLine02__c
                ,Owner__c,Tenant__c,BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStateCode
                FROM Account WHERE Id = :accountId];
    }
    
    public List<Account> getAccountWithJointOwner(Id accountId){
        return [SELECT Id,Name,(SELECT Name,First_Name__c,Last_Name__c FROM Joint_Owners__r) FROM Account WHERE Id = :accountId LIMIT 1];
    }
    
    public Map<Id, Account> getAccountWithJointOwners(Set<Id> accountIds){
        return new Map<Id, Account>([SELECT Id,Name,(SELECT Name,First_Name__c,Last_Name__c FROM Joint_Owners__r) FROM Account WHERE Id IN :accountIds]);
    }
    
    public List<Account> getAccountByEmails(Set<String> emailSet){
        return [SELECT Id, PersonEmail FROM Account WHERE PersonEmail IN :emailSet];
    }
    
    //Update Accounts
    public List<Account> updateAccounts(List<Account> accountList){
        if(accountList != NULL && !accountList.isEmpty()){
            update accountList;
        }
        return accountList;
    }
    
    //Update Account
    public Account updateAccount(Account acc){
        try{return updateAccounts(new List<Account>{acc})[0];
           }catch (Exception e) {

        System.debug(LoggingLevel.ERROR,
            '===== AccountService.updateAccount FAILED =====');

        System.debug(LoggingLevel.ERROR,
            'Message : ' + e.getMessage());

        System.debug(LoggingLevel.ERROR,
            'Stack   : ' + e.getStackTraceString());

        throw e;
    }
    }
    
    
    //Update Accounts without trigger
    public List<Account> updateAccountsWithoutTrigger(List<Account> accountList){
        if(accountList != NULL && !accountList.isEmpty()){
            AccountTriggerHandler.isTriggerDisabled = true;
            update accountList;
            AccountTriggerHandler.isTriggerDisabled = false;
        }
        return accountList;
    }
    
    public List<Database.SaveResult> updateAccountsWithoutTriggerDB(List<Account> accountList) {
        List<Database.SaveResult> processResult =new List<Database.SaveResult>();
        if(accountList != NULL && !accountList.isEmpty()){
            try {
                AccountTriggerHandler.isTriggerDisabled = true;
                processResult = Database.update(accountList, false);
            } finally {
                AccountTriggerHandler.isTriggerDisabled = false;
            }
        }
        return processResult;
    }
    
    //Update Account without trigger
    public Account updateAccountWithoutTrigger(Account acc){
        return updateAccountsWithoutTrigger(new List<Account>{acc})[0];
    }
    
    public static List<Account> getAccounts(Set<Id> accountIds) {
        return [SELECT Id, Name, (SELECT Id, Email FROM Contacts) FROM Account WHERE Id IN :accountIds];
    }
    
    public void createAccount(Account objAcc){
        if(objAcc != NULL ){
            insert objAcc;
        }
    }
    
    public List<Account> getAccountsWithPrimrayContact(Set<Id> accountIds) {
        return [
            SELECT Id, IsPersonAccount, PersonContactId, RecordType.DeveloperName, Salutation, FirstName, MiddleName, LastName,
            NameinArabic__c, Nationality__c, PersonGenderIdentity, PersonEmail, PersonMobilePhone, PersonBirthdate,BPType__c,
            PassportNumber__pc, Emirates_Id__pc, PassportIssueDate__pc, PassportExpiryDate__pc, EID_Issue_Date__pc,
            EID_Expiry_Date__pc, SAP_BP_No__c, SAP_Company_Code__c, PersonMailingStreet, PersonMailingCity, PersonMailingCountry,
            PersonMailingPostalCode, PersonMailingState, PersonMailingStateCode, Trade_License_No__c, Trade_License_Issue_Date__c,
            Trade_License_Expiry_Date__c, Main_Buyer__c, Joint_Buyer__c, Name,Phone,RecordTypeId,Owner__c,Tenant__c,
            BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStateCode,CompanyEmail__c, MobilePhone__pc,
            (SELECT Id, Phone, Email, Gender__c, MobilePhone
             FROM Contacts
             WHERE PrimaryContact__c = true
             LIMIT 1)
            FROM Account
            WHERE Id IN :accountIds
        ];
    }
    
    public IntegrationRecord__c getIntegrationRecord(Account acc){
        Map<String,String> paramsMap = new Map<String,String>();
        Id brokerAgencyAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT);
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        Contact con = null;
        if (!acc.IsPersonAccount) {
            if (acc.Contacts != null && !acc.Contacts.isEmpty()) {
                con = acc.Contacts[0]; 
            }
        }
        paramsMap.put('Param1', acc.RecordType.DeveloperName);
        paramsMap.put('Param2',acc.SAP_Company_Code__c);
        
        if(acc.IsPersonAccount) {
            paramsMap.put('Param5',  acc.PersonMailingStreet);
            paramsMap.put('Param6',  acc.PersonMailingCity);
            paramsMap.put('Param7',  acc.PersonMailingCountry);
            paramsMap.put('Param8',  acc.PersonMailingPostalCode);
            paramsMap.put('Param9',  acc.PersonMailingState);
            paramsMap.put('Param10', acc.PersonMailingStateCode);
            paramsMap.put('Param19',acc.Salutation);
            paramsMap.put('Param20',acc.MiddleName);
            paramsMap.put('Param3',acc.FirstName);
            paramsMap.put('Param4',acc.LastName);
        }else {
            paramsMap.put('Param5',  acc.BillingStreet);
            paramsMap.put('Param6',  acc.BillingCity);
            paramsMap.put('Param7',  acc.BillingCountry);
            paramsMap.put('Param8',  acc.BillingPostalCode);
            paramsMap.put('Param9',  acc.BillingState);
            paramsMap.put('Param10', acc.BillingStateCode);
        } 
        if (acc.IsPersonAccount) {
            paramsMap.put('Param11', acc.PersonMobilePhone);
            paramsMap.put('Param12', acc.PersonEmail);
            paramsMap.put('Param14', acc.PersonGenderIdentity == 'Female' ? 'F' : 'M');
            String fullName = String.join(new List<String>{
                acc.Salutation,
                    acc.FirstName,
                    acc.MiddleName,
                    acc.LastName
                    }, ' ').trim();
            paramsMap.put('Param22', fullName);
            paramsMap.put('Param23', String.valueOf(Utility.formatDateToYYYYMMDD(acc.PersonBirthdate)));
            paramsMap.put('Param24', acc.PassportNumber__pc);
            paramsMap.put('Param25', acc.Emirates_Id__pc);
            paramsMap.put('Param26', String.valueOf(Utility.formatDateToYYYYMMDD(acc.PassportIssueDate__pc)));
            paramsMap.put('Param27', String.valueOf(Utility.formatDateToYYYYMMDD(acc.PassportExpiryDate__pc)));
            paramsMap.put('Param28', String.valueOf(Utility.formatDateToYYYYMMDD(acc.EID_Issue_Date__pc)));
            paramsMap.put('Param29', String.valueOf(Utility.formatDateToYYYYMMDD(acc.EID_Expiry_Date__pc)));
        } else {
            String phoneVal;
            String emailVal;
            if (acc.recordTypeId == brokerAgencyAccountRecordTypeId) {
                phoneVal = (String) acc.get('MobilePhone__pc'); 
                emailVal = (String) acc.get('CompanyEmail__c');
            } else {
                phoneVal = (con != null) ? con.MobilePhone : null;
                emailVal = (con != null) ? con.Email : null;
            }
            paramsMap.put('Param11', phoneVal);
            paramsMap.put('Param12', emailVal);
            paramsMap.put('Param14', con != null ? con.Gender__c == 'Female' ? 'F' : 'M' : null);
            paramsMap.put('Param22', acc.Name);
            paramsMap.put('Param31', acc.Trade_License_No__c);
            paramsMap.put('Param32', String.valueOf(Utility.formatDateToYYYYMMDD(acc.Trade_License_Issue_Date__c)));
            paramsMap.put('Param33', String.valueOf(Utility.formatDateToYYYYMMDD(acc.Trade_License_Expiry_Date__c)));
        }
        paramsMap.put('Param13',acc.Nationality__c);
        paramsMap.put('Param16',String.valueOf(acc.Joint_Buyer__c));
        paramsMap.put('Param17',String.valueOf(acc.Main_Buyer__c));
        paramsMap.put('Param18',acc.SAP_BP_No__c);
        paramsMap.put('Param21',acc.NameinArabic__c);
        paramsMap.put('Param15',UserInfo.getUserEmail());
        
        String param34;
        
        if (acc.recordTypeId == brokerAgencyAccountRecordTypeId) {
            param34 = 'Broker';
        } else {
            param34 = acc.BPType__c;
            if (String.isBlank(param34)) {
                param34 = 'Tenant';
            }
        }
        
        paramsMap.put('Param34', param34);
        
        String actionType = String.isBlank(acc.SAP_BP_No__c) ? INTEGRATION_ACTION_INSERT : INTEGRATION_ACTION_UPDATE;
        return integService.getIntegrationRecord(INTEGRATION_TYPE_ACCOUNT_SAP_INTEGRATION, actionType,'','', ACCOUNT_OBJECT_API_NAME, acc.Id,paramsMap);
    }
    
    //Insert Accounts 
    public List<Account> insertAccounts(List<Account> accList){
        if(accList != NULL && !accList.isEmpty()){
            insert accList;
        }
        return accList; 
    }  
    
    /**
* Returns map AccountNumber → Account.Id for provided numbers.
*/
    public static Map<String, Id> byAccountNumber(Set<String> accountNumbers) {
        Map<String, Id> out = new Map<String, Id>();
        if (accountNumbers == null || accountNumbers.isEmpty()) return out;
        
        for (Account a : [SELECT Id, AccountNumber, SAP_BP_No__c FROM Account WHERE SAP_BP_No__c IN :accountNumbers]) {
            if (String.isNotBlank(a.SAP_BP_No__c) && !out.containsKey(a.SAP_BP_No__c)) {
                out.put(a.SAP_BP_No__c, a.Id);
            }
        }
        return out;
    }
    /** Fetch by external number used in QuickPay (AccountNumber). */
    public Account getByAccountNumber(String acctNumber) {
        return [ SELECT Id, Name, AccountNumber, SAP_BP_No__c FROM Account WHERE SAP_BP_No__c = :acctNumber LIMIT 1 ];
    }
    /** Lightweight fetch by Id (kept for other callers). */
    public Account getLightweightById(Id accountId) {
        return [ SELECT Id, Name, PersonEmail, PersonContactId, AccountNumber, SAP_BP_No__c FROM Account WHERE Id = :accountId LIMIT 1 ];
    }
    
    public List<Database.SaveResult> updateAccountsWithoutDuplicateRule(List<Account> accList){
        Database.DMLOptions objDML = new Database.DMLOptions();
        objDML.DuplicateRuleHeader.allowSave = true;
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        if(!accList.isEmpty()){
            srList = Database.update(accList, objDML);
        }
        return srList;
    }
    
    public List<Database.SaveResult> updateAccountWithoutDuplicateRule(Account acc){
        return updateAccountsWithoutDuplicateRule(new List<Account>{acc});
    }
    
    public List<Account> getRelatedContactForAccountId(Id AccountId){
        return [ SELECT Id, Name, (SELECT Id, Name, Email FROM Contacts WHERE BrokerContactRole__c INCLUDES ('AuthorizedSignatoryOfficer') AND IsActive__c = true LIMIT 1) FROM Account WHERE Id = :AccountId];
    }
    
    public List<Account> getPersonAccounts(String emiratesId, string passportNumber, string nationality){
        List<Account> accountList = new List<Account>();
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        if(String.isNotBlank(emiratesId)){
            accountList = [SELECT Id, PersonContactId, FirstName, MiddleName, LastName, Name, Emirates_Id__pc, PassportNumber__pc, Nationality__pc,Legal_Status__c,
                           Nationality__c, IsPersonAccount, PrimaryMobileCountryCode__pc, PrimaryMobilePhone__pc, PersonEmail
                           FROM Account WHERE RecordTypeId = :personAccountRecordTypeId
                           AND Emirates_Id__pc = :emiratesId];
        }else if(String.isNotBlank(passportNumber) && String.isNotBlank(nationality)){
            accountList = [SELECT Id, PersonContactId, FirstName, MiddleName, LastName, Name, Emirates_Id__pc, PassportNumber__pc, Nationality__pc,
                           Nationality__c, IsPersonAccount, PrimaryMobileCountryCode__pc, PrimaryMobilePhone__pc, PersonEmail
                           FROM Account WHERE RecordTypeId = :personAccountRecordTypeId
                           AND PassportNumber__pc = :passportNumber AND Nationality__c = :nationality];
        }
        return accountList;
    }
    public List<Account> getAccountByTradeLicenseNumber(Set<String> tradeLicenseSet){
        return [SELECT Id, Name, Trade_License_No__c FROM Account WHERE Trade_License_No__c  IN :tradeLicenseSet];
        
    }
    public List<Account> getAccountByCommercialLicenseNumber(Set<String> commercialLicenseSet){
        return [SELECT Id, Name, CommercialLicenseNumber__c FROM Account WHERE CommercialLicenseNumber__c IN :commercialLicenseSet];
        
    }
    
    // BAPP Get Accounts Map By Ids
    public static Map<Id, Account> getAccountsMapByIds(Set<Id> accountIds) {
        
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }
        return new Map<Id, Account>([SELECT Id,AgreementRenewalStatus__c,AgreementExpiryDate__c, Trade_License_Expiry_Date__c, VATUndertakingIssueDate__c, CommercialLicenseExpiryDate__c, TaxRegistrationNumber__c, AddressLine01__c, AddressLine02__c, BillingStreet, Phone__c, BankAccount__c, BankAccount__r.Id, BankAccount__r.AccountNumberCorporate__c, BankAccount__r.BankNameCorporate__c, BankAccount__r.BankAddress__c, BankAccount__r.IBANNoCorporate__c, BankAccount__r.SwiftCodeCorporate__c FROM Account WHERE Id IN :accountIds]);
    }
    
    // BAPP Update Account
    public static void updateExistingAccounts(List<Account> accountList){
        if(accountList != null && !accountList.isEmpty()){
            update accountList;
        }
    }
}
/*
* @Author : Raza Chandankeri
* @CreatedDate : 11th JUN 2025
* @Description : BrokerApplicationTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Raza        11JUN2025        Initial draft 
*****************************************************************************************************/
public class BrokerApplicationTriggerHelper {
    
    private static final string ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT { get { return 'Broker_Agency'; } }
    private static final String BROKER { get { return 'Broker'; } }

    
    /**
     * @description Creates documents for BrokerApplication records
     * @param newList List of BrokerApplication__c records
     */
    public static void createDocuments(List<BrokerApplication__c> newList){     
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> brokerAppDocTypeList = objDocumentService.getDocTypes('Broker Application');
        List<Document__c> documentList = new List<Document__c>();
        
        for(BrokerApplication__c brokerApp : newList){
            for(DocumentType__c objDocumentType : brokerAppDocTypeList){
                if (objDocumentType.TypeofEstablishment__c != null && brokerApp.TypeofEstablishment__c != null) {
                    String docTypeEst = ';' + objDocumentType.TypeofEstablishment__c + ';';
                    String brokerAppEst = ';' + brokerApp.TypeofEstablishment__c + ';';
                    if (docTypeEst.contains(brokerAppEst)) {
                        documentList.add(new Document__c(
                            BrokerApplication__c = brokerApp.Id, 
                            DocumentType__c = objDocumentType.Id, 
                            Document_Name__c = objDocumentType.Type__c
                        ));
                    }
                }
            }
        }        
        
        if(!documentList.isEmpty()){
            objDocumentService.insertDocuments(documentList);   
        }
    }
    
    public static void checkExistingAndCreateAccount(List<BrokerApplication__c> newList) {
        
        Set<String> tradeLicenseSet = new Set<String>();
        Set<String> commercialLicenseSet = new Set<String>();
        
        // STEP 1: Collect license numbers
        for (BrokerApplication__c bApp : newList) {
            if (bApp.TypeofEstablishment__c == 'Domestic' && String.isNotBlank(bApp.TradeLicenseNumber__c)){
                tradeLicenseSet.add(bApp.TradeLicenseNumber__c);
            }
            else if (bApp.TypeofEstablishment__c == 'International' && String.isNotBlank(bApp.CommercialLicenseNumber__c)){
                commercialLicenseSet.add(bApp.CommercialLicenseNumber__c);
            }
        }
        
        // STEP 2: Query Accounts only once, key by license number
        Map<String, Account> domesticAccMap = new Map<String, Account>();
        if (!tradeLicenseSet.isEmpty()) {
            for (Account acc : AccountService.getInstance().getAccountByTradeLicenseNumber(tradeLicenseSet)) {
                domesticAccMap.put(acc.Trade_License_No__c, acc);
            }
        }
        
        Map<String, Account> internationalAccMap = new Map<String, Account>();
        if (!commercialLicenseSet.isEmpty()) {
            for (Account acc : AccountService.getInstance().getAccountByCommercialLicenseNumber(commercialLicenseSet)) {
                internationalAccMap.put(acc.CommercialLicenseNumber__c, acc);
            }
        }
        
        // STEP 3: Identify BrokerApplications that do NOT have matching Accounts
        List<BrokerApplication__c> appsToCreate = new List<BrokerApplication__c>();
        Map<BrokerApplication__c, Account> bAppToUpdateMap = new Map<BrokerApplication__c, Account>();// Added by Ashish Rana
        for (BrokerApplication__c bApp : newList) {
            if (bApp.TypeofEstablishment__c == 'Domestic') {
                //if (!domesticAccMap.containsKey(bApp.TradeLicenseNumber__c)) {
                   // appsToCreate.add(bApp);
                //}
                if (domesticAccMap.containsKey(bApp.TradeLicenseNumber__c)) {
                    bAppToUpdateMap.put(bApp, domesticAccMap.get(bApp.TradeLicenseNumber__c));
                } else {
                    appsToCreate.add(bApp);
                }
            }
            else if (bApp.TypeofEstablishment__c == 'International') {
                //if (!internationalAccMap.containsKey(bApp.CommercialLicenseNumber__c)) {
                   // appsToCreate.add(bApp);
                //}
                if (internationalAccMap.containsKey(bApp.CommercialLicenseNumber__c)) {
                    bAppToUpdateMap.put(bApp, internationalAccMap.get(bApp.CommercialLicenseNumber__c));
                } else {
                    appsToCreate.add(bApp);
                }
            }
        }
                
        // STEP 4: Create Bank Account records only once
        if (!appsToCreate.isEmpty()) {
            createBankAccount(appsToCreate);
        }
        // Added by Ashish Rana
        if (!bAppToUpdateMap.isEmpty()) {
            updateExistingAccounts(bAppToUpdateMap);
        }

    }

    // Added by Ashish Rana
    public static void updateExistingAccounts(Map<BrokerApplication__c, Account> bAppToUpdateMap) {
        
        List<Account> accListToUpdate = new List<Account>();
        Id brokerAgencyAccountRecordTypeId = Utility.getRecordTypeIdByDevName(
            Account.SObjectType, 
            ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT
        );
        
        for (BrokerApplication__c bApp : bAppToUpdateMap.keySet()) {
            
            if (bApp.approvalStatus__c != 'Approved' || bApp.TypeofEstablishment__c == null) {
                continue;
            }
            
            Account acc = bAppToUpdateMap.get(bApp);
            
            String BillingStateValue;
            if (bApp.TypeofEstablishment__c == 'Domestic') {
                BillingStateValue = bApp.Emirate__c;
            } else {
                BillingStateValue = bApp.State__c;
            }
            
            acc.BillingCity = bApp.City__c;
            acc.BillingCountry = bApp.Country__c;
            acc.BillingPostalCode = bApp.ZipCodePOBoxNumber__c;
            acc.BillingState = BillingStateValue;
            acc.BillingStreet = 
                (bApp.AddressLine01__c != null ? bApp.AddressLine01__c : '') + '\n' +
                (bApp.AddressLine02__c != null ? bApp.AddressLine02__c : '');
            
            acc.Broker_Application__c = bApp.Id;
            acc.Broker_Registration_Expiry_Date__c = bApp.AgreementExpiryDate__c;
            acc.Broker_Registration_Issue_Date__c = bApp.AgreementInitiationdate__c;
            acc.Brokerage_Agreement_Number__c = bApp.AgreementNumber__c;
            acc.CommercialLicenseExpiryDate__c = bApp.CommercialLicenseExpiryDate__c;
            acc.CommercialLicenseNumber__c = bApp.CommercialLicenseNumber__c;
            acc.CompanyEmail__c = bApp.AgencyEmail__c;
            acc.CompanyName__c = bApp.CompanyName__c;
            acc.IsActive__c = true;
            acc.Is_VAT_Registered__c = bApp.IsVATRegistered__c;
            acc.LicenseType__c = bApp.LicenseType__c;
            acc.ORNADM__c = bApp.ORNADM__c;
            acc.ADMORNExpiryDate__c = bApp.ADMORNExpiryDate__c;
            acc.PhoneCountryCode__c = bApp.CountryCode__c;
            acc.Phone__c = bApp.CompanyPhone_Number__c;
            acc.RecordTypeId = brokerAgencyAccountRecordTypeId;
            acc.RegisteredEmirate__c = bApp.RegisteredEmirate__c;
            acc.ShippingCity = bApp.RegisteredCity__c;
            acc.ShippingCountry = bApp.RegisteredCountry__c;                
            acc.ShippingState = bApp.RegisteredState__c;
            acc.TaxRegistrationExpiryDate__c = bApp.TaxRegistrationExpiryDate__c;
            acc.Trade_License_Expiry_Date__c = bApp.TradeLicenseExpiryDate__c;
            acc.Trade_License_No__c = bApp.TradeLicenseNumber__c;
            acc.Type__c = bApp.AgencyType__c;
            acc.TypeofEstablishment__c = bApp.TypeofEstablishment__c;
            acc.UAEVATRegisterNumber__c = bApp.TaxRegistrationNumber__c;
            acc.VATUndertakingIssueDate__c = bApp.VATUndertakingIssueDate__c;
            
            accListToUpdate.add(acc);
        }
        
        if (!accListToUpdate.isEmpty()) {
            AccountService accService = AccountService.getInstance();
            List<Account> updatedAccList = accService.updateAccountsWithoutTrigger(accListToUpdate);
            
            // Calling to copy the Documents from Broker Application To Account
            copyDocuments(updatedAccList);
            
            // Calling to copy Files from Broker Application To Account
            copyFilesFromBrokerAppToAccount (updatedAccList);
            createContactsFromApplicants(updatedAccList);
            
        }
    }
    // Added by ashish rana
    public static void createContactsFromApplicants(List<Account> updatedAccList) {
        
        Map<Id, Account> appToAccountMap = new Map<Id, Account>();
        Set<Id> accountIds = new Set<Id>();
        
        for (Account acc : updatedAccList) {
            if (acc.Broker_Application__c != null) {
                appToAccountMap.put(acc.Broker_Application__c, acc);
                accountIds.add(acc.Id);
            }
        }
        
        if (appToAccountMap.isEmpty()) return;
        
        // Fetch Applicants
        List<BrokerApplicant__c> applicants = BrokerApplicantService.getInstance().getApplicantsByApplicationIds(appToAccountMap.keySet());
        
        // Fetch existing Contacts
        List<Contact> contacts = ContactService.getInstance().getActiveContactByAccountId(accountIds);
        
        // Maps for matching
        Map<Id, Map<String, Contact>> accToEmailContactMap = new Map<Id, Map<String, Contact>>();
        Map<Id, Map<String, Contact>> accToEmiratesIdContactMap = new Map<Id, Map<String, Contact>>();
        
        for (Contact c : contacts) {
            
            if (!accToEmailContactMap.containsKey(c.AccountId)) {
                accToEmailContactMap.put(c.AccountId, new Map<String, Contact>());
                accToEmiratesIdContactMap.put(c.AccountId, new Map<String, Contact>());
            }
            
            if (c.Email != null) {
                accToEmailContactMap.get(c.AccountId).put(c.Email.toLowerCase(), c);
            }
            
            if (c.Emirates_Id__c != null) {
                accToEmiratesIdContactMap.get(c.AccountId).put(c.Emirates_Id__c, c);
            }
        }
        
        Id contactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, BROKER);
        
        List<Contact> contactsToInsert = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (BrokerApplicant__c ba : applicants) {
            
            Account acc = appToAccountMap.get(ba.BrokerApplication__c);
            if (acc == null) continue;
            
            String email = ba.Email__c != null ? ba.Email__c.toLowerCase() : null;
            String emiratesId = ba.NationalID__c;
            
            Contact existingContact;
            
            //Match by Email
            if (email != null && accToEmailContactMap.containsKey(acc.Id) && accToEmailContactMap.get(acc.Id).containsKey(email)) {
                
                existingContact = accToEmailContactMap.get(acc.Id).get(email);
            }
            //Match by Emirates ID
            else if (emiratesId != null && accToEmiratesIdContactMap.containsKey(acc.Id) && accToEmiratesIdContactMap.get(acc.Id).containsKey(emiratesId)) {
                
                existingContact = accToEmiratesIdContactMap.get(acc.Id).get(emiratesId);
            }
            
            if (existingContact != null) {
                existingContact.FirstName = ba.FirstName__c;
                existingContact.LastName = ba.LastName__c;
                existingContact.MiddleName__c = ba.MiddleName__c;
                existingContact.Email = ba.Email__c;
                existingContact.PrimaryMobilePhone__c = ba.PhoneNumber__c;
                existingContact.PrimaryMobileCountryCode__c = ba.CountryCode__c;
                existingContact.Birthdate = ba.DateOfBirth__c;
                existingContact.BrokerApplicant__c = ba.Id;
                existingContact.BrokerApplication__c = ba.BrokerApplication__c;
                existingContact.Nationality__c  = ba.Country__c;
                existingContact.CountryOfResidence__c = 'United Arab Emirates';
                //existingContact.CountryOfResidence__c = ba.Country__c;
                existingContact.BrokerContactRole__c = ba.BrokerContactRole__c;
                existingContact.ShareHoldingPercentage__c = ba.ShareHoldingPercentage__c;
                existingContact.PassportNumber__c = ba.PassportNumber__c;
                existingContact.PassportExpiryDate__c = ba.PassportExpiryDate__c;
                existingContact.Emirates_Id__c = ba.NationalID__c;
                existingContact.EID_Expiry_Date__c = ba.NationalIDExpiryDate__c;
                existingContact.Title = ba.Title__c;
                existingContact.IsActive__c = true;
                existingContact.Designation__c = ba.Designation__c;
                existingContact.IsOwner__c = ba.IsOwner__c;
                existingContact.IsCEO__c = ba.IsCEO__c;
                existingContact.IsAdmin__c = ba.IsAdmin__c;
                existingContact.IsAgent__c = ba.IsAgent__c;
                existingContact.IsPartner__c = ba.IsPartner__c;
                existingContact.IsSuperAdmin__c = ba.IsSuperAdmin__c;
                existingContact.IsFinancialAdmin__c = ba.isFinancialAdmin__c;
                existingContact.IsAuthorizedSignatory__c = ba.IsAuthorizedSignatory__c;
                existingContact.TypeofEstablishment__c = ba.TypeofEstablishment__c;
                existingContact.LeadConversionAllowed__c = ba.LeadConversionallowed__c;
                
                contactsToUpdate.add(existingContact);
                
            } else {
                Contact con = new Contact();
                con.AccountId = acc.Id;
                con.RecordTypeId = contactRecordTypeId;
                
                con.FirstName = ba.FirstName__c;
                con.LastName = ba.LastName__c;
                con.MiddleName__c = ba.MiddleName__c;
                con.Email = ba.Email__c;
                con.PrimaryMobilePhone__c = ba.PhoneNumber__c;
                con.PrimaryMobileCountryCode__c = ba.CountryCode__c;
                con.Birthdate = ba.DateOfBirth__c;
                con.BrokerApplicant__c = ba.Id;
                con.BrokerApplication__c = ba.BrokerApplication__c;
                con.Nationality__c  = ba.Country__c;
                con.CountryOfResidence__c = 'United Arab Emirates';
                //con.CountryOfResidence__c = ba.Country__c;
                con.BrokerContactRole__c = ba.BrokerContactRole__c;
                con.ShareHoldingPercentage__c = ba.ShareHoldingPercentage__c;
                con.PassportNumber__c = ba.PassportNumber__c;
                con.PassportExpiryDate__c = ba.PassportExpiryDate__c;
                con.Emirates_Id__c = ba.NationalID__c;
                con.EID_Expiry_Date__c = ba.NationalIDExpiryDate__c;
                con.Title = ba.Title__c;
                con.IsActive__c = true;
                con.Designation__c = ba.Designation__c;
                con.IsOwner__c = ba.IsOwner__c;
                con.IsCEO__c = ba.IsCEO__c;
                con.IsAdmin__c = ba.IsAdmin__c;
                con.IsAgent__c = ba.IsAgent__c;
                con.IsPartner__c = ba.IsPartner__c;
                con.IsSuperAdmin__c = ba.IsSuperAdmin__c;
                con.IsFinancialAdmin__c = ba.isFinancialAdmin__c;
                con.IsAuthorizedSignatory__c = ba.IsAuthorizedSignatory__c;
                con.TypeofEstablishment__c = ba.TypeofEstablishment__c;
                con.LeadConversionAllowed__c = ba.LeadConversionallowed__c;
                
                contactsToInsert.add(con);
            }
        }
        
        if (!contactsToInsert.isEmpty()) {
            ContactService.getInstance().insertContacts(contactsToInsert);
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    } 
    
    // Create Bank Accounts Related to the Broker Accounts
    public static Map<Id,Id> createBankAccount(List<BrokerApplication__c> newList){ 
        List<BankAccount__c> bnkAccListToInsert = New List<BankAccount__c>();
        Map<Id, Id> appToBankAccMap = new Map<Id, Id>();
        BankAccount__c bnkAccObj;
        for (BrokerApplication__c bApp : newList) {
            bnkAccObj = New BankAccount__c();
            bnkAccObj.AccountNumberCorporate__c = bApp.Account_Number__c;
            bnkAccObj.BankAddress__c = bApp.BankBranchAddress__c;
            bnkAccObj.BankCountry__c = bApp.BankCountry__c;
            bnkAccObj.BeneficiaryNameCorporate__c = bApp.BeneficiaryName__c;
            bnkAccObj.BranchCorporate__c = bApp.BankBranch__c;
            bnkAccObj.CurrencyIsoCode = bApp.CurrencyIsoCode;
            bnkAccObj.IBANNoCorporate__c = bApp.IBAN__c;
            bnkAccObj.Name = bApp.BankNameValue__c;
            bnkAccObj.SwiftCodeCorporate__c = bApp.SwiftCode__c;
            bnkAccObj.BrokerApplication__c = bApp.Id;
            bnkAccListToInsert.add(bnkAccObj);  
            
        }
        BankAccountService bnkAccService = BankAccountService.getInstance();
        bnkAccService.insertBankAccounts(bnkAccListToInsert);
        // Map broker application to created bank account
        for (BankAccount__c ba : bnkAccListToInsert) {
            appToBankAccMap.put(ba.BrokerApplication__c, ba.Id);
        }
        createBrokerAccount(newList, appToBankAccMap);
        return appToBankAccMap;
    }
    public static void createBrokerAccount(List<BrokerApplication__c> newList, Map<Id, Id> appToBankAccMap){ 
        List<BrokerApplication__c> bAppList = (List<BrokerApplication__c>)newList;
        List<Account> accListToInsert = New List<Account>();
        String BillingStateValue ;
        Id brokerAgencyAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT);
        
        for (BrokerApplication__c bApp : bAppList) {
            if (bApp.approvalStatus__c == 'Approved' && bApp.TypeofEstablishment__c != Null) {
                if(bApp.TypeofEstablishment__c == 'Domestic'){
                    BillingStateValue = bApp.Emirate__c;
                } else if (bApp.TypeofEstablishment__c == 'International'){
                    BillingStateValue = bApp.State__c;
                }
                Account acc = New Account();
                acc.BankAccount__c = appToBankAccMap.get(bApp.Id); 
                acc.BillingCity = bApp.City__c;
                acc.BillingCountry = bApp.Country__c;
                acc.BillingPostalCode = bApp.ZipCodePOBoxNumber__c;
                acc.BillingState = BillingStateValue;
                acc.BillingStreet = (bApp.AddressLine01__c != null ? bApp.AddressLine01__c : '') + '\n' + (bApp.AddressLine02__c != null ? bApp.AddressLine02__c : '');
                acc.Broker_Application__c = bApp.Id;
                acc.Broker_Registration_Expiry_Date__c = bApp.AgreementExpiryDate__c;
                acc.Broker_Registration_Issue_Date__c = bApp.AgreementInitiationdate__c;
                acc.Brokerage_Agreement_Number__c = bApp.AgreementNumber__c;
                acc.CommercialLicenseExpiryDate__c = bApp.CommercialLicenseExpiryDate__c;
                acc.CommercialLicenseNumber__c = bApp.CommercialLicenseNumber__c;
                acc.CompanyEmail__c = bApp.AgencyEmail__c;
                acc.CompanyName__c = bApp.CompanyName__c;
                acc.IsActive__c = true;
                acc.Is_VAT_Registered__c = bApp.IsVATRegistered__c;
                acc.LicenseType__c = bApp.LicenseType__c;
                acc.Name = bApp.Name;
                acc.ORNADM__c = bApp.ORNADM__c;
                acc.ADMORNExpiryDate__c = bApp.ADMORNExpiryDate__c;
                acc.PhoneCountryCode__c = bApp.CountryCode__c;
                acc.Phone__c = bApp.CompanyPhone_Number__c;
                acc.RecordTypeId = brokerAgencyAccountRecordTypeId;
                acc.RegisteredEmirate__c = bApp.RegisteredEmirate__c;
                acc.ShippingCity = bApp.RegisteredCity__c;
                acc.ShippingCountry = bApp.RegisteredCountry__c;                
                acc.ShippingState = bApp.RegisteredState__c;
                acc.TaxRegistrationExpiryDate__c = bApp.TaxRegistrationExpiryDate__c;
                acc.Trade_License_Expiry_Date__c = bApp.TradeLicenseExpiryDate__c;
                acc.Trade_License_No__c = bApp.TradeLicenseNumber__c;
                acc.Type__c = bApp.AgencyType__c;
                acc.TypeofEstablishment__c = bApp.TypeofEstablishment__c;
                acc.UAEVATRegisterNumber__c = bApp.TaxRegistrationNumber__c;
                acc.VATUndertakingIssueDate__c = bApp.VATUndertakingIssueDate__c;
                accListToInsert.add(acc);
                
            }
        }
        AccountService accService = AccountService.getInstance();
        List<Account> insertedAccList = accService.insertAccounts(accListToInsert);
        
        // Calling to copy the Documents from Broker Application To Account
        copyDocuments(insertedAccList);
        
        // Calling to copy Files from Broker Application To Account
        copyFilesFromBrokerAppToAccount (insertedAccList);
        
        createBrokerContacts (insertedAccList);
        
    }
    
    public static void createBrokerContacts (List<Account> insertedAccList){
        
        Map<Id, Account> appToAccountMap = new Map<Id, Account>();
        List<Account> accListToUpdateAccountLookup = New List<Account>();
        
        // ------------------------------
        // MAP BrokerApplication → Account and update Account Lookup on Broker Application 
        // ------------------------------
        for (Account acc : insertedAccList) {
            if (acc.Broker_Application__c != null) {
                appToAccountMap.put(acc.Broker_Application__c, acc);
                accListToUpdateAccountLookup.add(acc);
            }
        }
        
        // ------------------------------
        // CREATE CONTACTS FOR EACH BROKER APPLICANT
        // ------------------------------
        List<BrokerApplicant__c> applicants = BrokerApplicantService.getInstance()
            .getApplicantsByApplicationIds(appToAccountMap.keySet());
        
        Id contactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Broker').getRecordTypeId();
        
        List<Contact> contactsToInsert = new List<Contact>();
        
        for (BrokerApplicant__c ba : applicants) {
            Account acc = appToAccountMap.get(ba.BrokerApplication__c);
            if (acc == null) continue;
            
            Contact con = new Contact();
            con.AccountId = acc.Id;
            con.RecordTypeId = contactRecordTypeId;
            
            con.FirstName = ba.FirstName__c;
            con.LastName = ba.LastName__c;
            con.MiddleName__c = ba.MiddleName__c;
            con.Email = ba.Email__c;
            con.PrimaryMobilePhone__c = ba.PhoneNumber__c;
            con.PrimaryMobileCountryCode__c = ba.CountryCode__c;
            con.Birthdate = ba.DateOfBirth__c;
            con.BrokerApplicant__c = ba.Id;
            con.BrokerApplication__c = ba.BrokerApplication__c;
            con.Nationality__c  = ba.Country__c;
            con.CountryOfResidence__c = 'United Arab Emirates';
            //con.CountryOfResidence__c = ba.Country__c;
            con.BrokerContactRole__c = ba.BrokerContactRole__c;
            con.ShareHoldingPercentage__c = ba.ShareHoldingPercentage__c;
            con.PassportNumber__c = ba.PassportNumber__c;
            con.PassportExpiryDate__c = ba.PassportExpiryDate__c;
            con.Emirates_Id__c = ba.NationalID__c;
            con.EID_Expiry_Date__c = ba.NationalIDExpiryDate__c;
            con.Title = ba.Title__c;
            con.IsActive__c = true;
            con.Designation__c = ba.Designation__c;
            con.IsOwner__c = ba.IsOwner__c;
            con.IsCEO__c = ba.IsCEO__c;
            con.IsAdmin__c = ba.IsAdmin__c;
            con.IsAgent__c = ba.IsAgent__c;
            con.IsPartner__c = ba.IsPartner__c;
            con.IsSuperAdmin__c = ba.IsSuperAdmin__c;
            con.IsFinancialAdmin__c = ba.isFinancialAdmin__c;
            con.IsAuthorizedSignatory__c = ba.IsAuthorizedSignatory__c;
            con.TypeofEstablishment__c = ba.TypeofEstablishment__c;
            con.LeadConversionAllowed__c = ba.LeadConversionallowed__c;
            
            contactsToInsert.add(con);
        }
        
        List<Contact>insertedConList = ContactService.getInstance().insertContacts(contactsToInsert);
        
    }
    
    // BAPP to copy the document from Broker Applicaton to Account 
    public static void copyDocuments(List<Account> newAccounts) {
        // Step 1: Map Accounts → BrokerApplications
        Map<Id, Id> accountToBrokerAppMap = new Map<Id, Id>();
        for (Account acc : newAccounts) {
            if (acc.Broker_Application__c != null) {
                accountToBrokerAppMap.put(acc.Id, acc.Broker_Application__c);
            }
        }
        if (accountToBrokerAppMap.isEmpty()) return;
        
        Set<Id> brokerAppIds = new Set<Id>(accountToBrokerAppMap.values());
        Set<Id> accountIds   = new Set<Id>(accountToBrokerAppMap.keySet());
        
        // Step 2: Query BrokerApplication documents
        Map<String, Document__c> brokerAppDocMap = new Map<String, Document__c>();
        Set<Id> brokerVersionIds = new Set<Id>();
        
        for (Document__c doc : DocumentService.getInstance().getDocumentsByBrokerApplicationIds(brokerAppIds)) {
            if (doc.BrokerApplication__c != null && doc.Document_Name__c != null) {
                brokerAppDocMap.put(doc.BrokerApplication__c + '##' + doc.Document_Name__c, doc);
                if (doc.Content_Version_Id__c != null) {
                    brokerVersionIds.add(doc.Content_Version_Id__c);
                }
            }
        }
        
        if (brokerAppDocMap.isEmpty()) return;
        
        // Step 3: Query the ContentVersions for broker docs
        // Include FileExtension
        Map<Id, ContentVersion> brokerVersionMap = new Map<Id, ContentVersion>(
            DocumentService.getInstance().getContentVersionsByIds(brokerVersionIds)
        );
        
        // Step 4: Prepare new versions for Account documents
        List<ContentVersion> newVersions = new List<ContentVersion>();
        Map<Id, Document__c> tempKeyToAccDocMap = new Map<Id, Document__c>();
        List<Document__c> docsToUpdate = new List<Document__c>();
        
        for (Document__c accDoc : DocumentService.getInstance().getDocumentsByAccountIds(accountIds)) {
            Id brokerAppId = accountToBrokerAppMap.get(accDoc.Account__c);
            String key = brokerAppId + '##' + accDoc.Document_Name__c;
            
            if (brokerAppDocMap.containsKey(key)) {
                Document__c brokerDoc = brokerAppDocMap.get(key);
                ContentVersion brokerVersion = brokerVersionMap.get(brokerDoc.Content_Version_Id__c);
                
                if (brokerVersion != null) {
                    
                    //  Determine dynamic extension
                    String extension = brokerVersion.FileExtension != null ? '.' + brokerVersion.FileExtension : '';

                    // Create new ContentVersion for the Account's doc
                    ContentVersion newVersion = new ContentVersion();
                    newVersion.Title = brokerVersion.Title;
                    // Use dynamic extension instead of ".pdf"
                    newVersion.PathOnClient = accDoc.Id + '##' + brokerVersion.Title + extension;
                    newVersion.VersionData = brokerVersion.VersionData;
                    newVersion.FirstPublishLocationId = accDoc.Account__c; // Link to Account
                    newVersions.add(newVersion);
                    
                    // Prepare for later doc update
                    accDoc.FileName__c   = brokerDoc.FileName__c;
                    accDoc.FileSizeMB__c = brokerDoc.FileSizeMB__c;
                    // Set real file type
                    accDoc.FileType__c = brokerVersion.FileExtension != null ? brokerVersion.FileExtension.toUpperCase() : brokerDoc.FileType__c;

                    docsToUpdate.add(accDoc);
                    
                    tempKeyToAccDocMap.put(accDoc.Id, accDoc);
                }
            }
        }
        
        // Step 5: Insert ContentVersions & update docs
        if (!newVersions.isEmpty()) {
            //insert newVersions;
            newVersions = DocumentService.getInstance().insertContentVersions(newVersions);
            
            // Get the IDs explicitly
            Set<Id> newVersionIds = new Map<Id, ContentVersion>(newVersions).keySet();
            
            for (ContentVersion cv : ContentService.getInstance().getContentVersionsByIds(newVersionIds)) {
                String[] parts = cv.PathOnClient.split('##');
                if (parts.size() > 1) {
                    Id docId = (Id) parts[0];
                    Document__c relatedDoc = tempKeyToAccDocMap.get(docId);
                    if (relatedDoc != null) {
                        relatedDoc.ContentDocumentId__c = cv.ContentDocumentId;
                        relatedDoc.Content_Version_Id__c = cv.Id;
                    }
                }
            }
        }
        
        if (!docsToUpdate.isEmpty()) {
            //update docsToUpdate;
            DocumentService.getInstance().updateDocuments(docsToUpdate);
        }
    }
    
    // BAPP Copy Broker Application Files to Account Files 
    public static void copyFilesFromBrokerAppToAccount(List<Account> newAccounts) {
        Map<Id, Id> accountToBrokerAppMap = new Map<Id, Id>();
        for (Account acc : newAccounts) {
            if (acc.Broker_Application__c != null) {
                accountToBrokerAppMap.put(acc.Id, acc.Broker_Application__c);
            }
        }
        
        if (accountToBrokerAppMap.isEmpty()) return;
        
        Set<Id> brokerAppIds = new Set<Id>(accountToBrokerAppMap.values());
        Set<Id> brokerAccIds = new Set<Id>(accountToBrokerAppMap.keySet());
        
        // Step 1: Query files linked to Broker Applications
        List<ContentDocumentLink> brokerFileLinks = ContentDocumentLinkService.getInstance().getBrokerFileLinksByBrokerAppIds(brokerAppIds);
        
        // Step 2: Prepare ContentDocumentLink records for Account
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        Set<String> existingLinksKeySet = new Set<String>();
        
        // Query existing Account links to avoid duplicates
        
        List<ContentDocumentLink> existingAccountLinks = ContentDocumentLinkService.getInstance().getExistingAccountLinks(accountToBrokerAppMap.keySet());
        
        
        for (ContentDocumentLink link : existingAccountLinks) {
            existingLinksKeySet.add(link.LinkedEntityId + '-' + link.ContentDocumentId);
        }
        
        for (ContentDocumentLink brokerLink : brokerFileLinks) {
            for (Id accountId : accountToBrokerAppMap.keySet()) {
                if (accountToBrokerAppMap.get(accountId) == brokerLink.LinkedEntityId) {
                    String key = accountId + '-' + brokerLink.ContentDocumentId;
                    if (!existingLinksKeySet.contains(key)) {
                        newLinks.add(new ContentDocumentLink(
                            ContentDocumentId = brokerLink.ContentDocumentId,
                            LinkedEntityId = accountId,
                            ShareType = brokerLink.ShareType,
                            Visibility = brokerLink.Visibility
                        ));
                    }
                }
            }
        }
        
        ContentDocumentLinkService.getInstance().insertContentDocumentLinkWithTrigger(newLinks);
    }

        // BAPP Copies documents from BrokerApplicant__c or Case__c to Contact
    public static void copyDocumentsFromApplicantOrCase(List<Contact> newContacts) {
        // Step 1: Map Contacts → BrokerApplicants or Cases
        Map<Id, Id> contactToBrokerAppMap = new Map<Id, Id>();
        Map<Id, Id> contactToCaseMap = new Map<Id, Id>();   //  NEW: Case mapping
        
        for (Contact con : newContacts) {
            if (con.BrokerApplicant__c != null) {
                contactToBrokerAppMap.put(con.Id, con.BrokerApplicant__c);
            } else if (con.CaseId__c != null) {             //  NEW: Case support
                contactToCaseMap.put(con.Id, con.CaseId__c);
            }
        }
        if (contactToBrokerAppMap.isEmpty() && contactToCaseMap.isEmpty()) return;
        
        Set<Id> brokerAppIds = new Set<Id>(contactToBrokerAppMap.values());
        Set<Id> caseIds      = new Set<Id>(contactToCaseMap.values());  //  NEW Case Support
        Set<Id> contactIds   = new Set<Id>();
        contactIds.addAll(contactToBrokerAppMap.keySet());
        contactIds.addAll(contactToCaseMap.keySet());
        
        // Step 2a: Query BrokerApplicant documents
        Map<String, Document__c> brokerAppDocMap = new Map<String, Document__c>();
        Set<Id> brokerVersionIds = new Set<Id>();
        for (Document__c doc : DocumentService.getInstance().getDocumentsByBrokerApplicantIds(brokerAppIds)) {
            if (doc.BrokerApplicant__c != null && doc.Document_Name__c != null) {
                brokerAppDocMap.put(doc.BrokerApplicant__c + '##' + doc.Document_Name__c, doc);
                if (doc.Content_Version_Id__c != null) {
                    brokerVersionIds.add(doc.Content_Version_Id__c);
                }
            }
        }
        
        // Step 2b: Query Case documents // NEW Case Support
        Map<String, Document__c> caseDocMap = new Map<String, Document__c>();
        Set<Id> caseVersionIds = new Set<Id>();
        if (!caseIds.isEmpty()) {
            for (Document__c doc : DocumentService.getInstance().getDocumentsByCaseIds(caseIds)) {
                if (doc.Case__c != null && doc.Document_Name__c != null) {
                    caseDocMap.put(doc.Case__c + '##' + doc.Document_Name__c, doc);
                    if (doc.Content_Version_Id__c != null) {
                        caseVersionIds.add(doc.Content_Version_Id__c);
                    }
                }
            }
        }
        
        // Merge version Ids
        Set<Id> allVersionIds = new Set<Id>();
        allVersionIds.addAll(brokerVersionIds);
        allVersionIds.addAll(caseVersionIds);
        
        if (allVersionIds.isEmpty()) return;
        
        // Step 3: Query the ContentVersions for source docs
        // Include FileExtension
        Map<Id, ContentVersion> sourceVersionMap = new Map<Id, ContentVersion>(DocumentService.getInstance().getContentVersionsByIds(allVersionIds));
        
        // Step 4: Prepare new versions for Contact documents
        List<ContentVersion> newVersions = new List<ContentVersion>();
        Map<Id, Document__c> tempKeyToConDocMap = new Map<Id, Document__c>();
        List<Document__c> docsToUpdate = new List<Document__c>();
        
        for (Document__c conDoc : DocumentService.getInstance().getDocumentsByContactIds(contactIds)) {
            system.debug('conDoc-->'+conDoc);
            Id brokerAppId = contactToBrokerAppMap.get(conDoc.Contact__c);
            Id caseId      = contactToCaseMap.get(conDoc.Contact__c);
            
            String key;
            Document__c srcDoc;
            if (brokerAppId != null) {
                key = brokerAppId + '##' + conDoc.Document_Name__c;
                srcDoc = brokerAppDocMap.get(key);
            } else if (caseId != null) {   // NEW: Case support
                key = caseId + '##' + conDoc.Document_Name__c;
                srcDoc = caseDocMap.get(key);
            } else {
                continue;
            }
            
            if (srcDoc != null) {
                ContentVersion srcVersion = sourceVersionMap.get(srcDoc.Content_Version_Id__c);
                if (srcVersion != null) {

                    // Determine dynamic extension
                String extension = srcVersion.FileExtension != null ? '.' + srcVersion.FileExtension : '';

                    // Create new ContentVersion for the Contact's doc
                    ContentVersion newVersion = new ContentVersion();
                    newVersion.Title = srcVersion.Title;
                    // Use dynamic extension instead of ".pdf"
                    newVersion.PathOnClient = conDoc.Id + '##' + srcVersion.Title + extension;
                    newVersion.VersionData = srcVersion.VersionData;
                    newVersion.FirstPublishLocationId = conDoc.Contact__c;
                    newVersions.add(newVersion);
                    
                    // Copy metadata
                    conDoc.FileName__c   = srcDoc.FileName__c;
                    conDoc.FileSizeMB__c = srcDoc.FileSizeMB__c;
                    // Set real file type 
                    conDoc.FileType__c = srcVersion.FileExtension != null ? srcVersion.FileExtension.toUpperCase() : srcDoc.FileType__c;
                    docsToUpdate.add(conDoc);
                    tempKeyToConDocMap.put(conDoc.Id, conDoc);
                }
            }
        }
        
        // Step 5: Insert ContentVersions & update docs
        if (!newVersions.isEmpty()) {
            //insert newVersions;
            newVersions = DocumentService.getInstance().insertContentVersions(newVersions);
            
            Set<Id> newVersionIds = new Map<Id, ContentVersion>(newVersions).keySet();
            List<ContentVersion> versionRecords = DocumentService.getInstance().getInsertedContentVersions(newVersionIds);
            
            for (ContentVersion cv : versionRecords) {
                String[] parts = cv.PathOnClient.split('##');
                if (parts.size() > 1) {
                    Id docId = (Id) parts[0];
                    Document__c relatedDoc = tempKeyToConDocMap.get(docId);
                    if (relatedDoc != null) {
                        relatedDoc.ContentDocumentId__c = cv.ContentDocumentId;
                        relatedDoc.Content_Version_Id__c = cv.Id;
                    }
                }
            }
        }
        
        if (!docsToUpdate.isEmpty()) {
            system.debug('docsToUpdate-->'+docsToUpdate);
            DocumentService docService = DocumentService.getInstance();
            docService.updateDocuments(docsToUpdate);
        }
    }
}
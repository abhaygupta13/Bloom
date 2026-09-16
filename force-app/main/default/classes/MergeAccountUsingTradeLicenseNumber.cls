public class MergeAccountUsingTradeLicenseNumber {
    
    // Update Accounts
    
    public static void updateAccountsFromBrokerApps(Set<Id> accountIds) {
        
        if(accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        List<Account> accounts = [
            SELECT Id, Trade_License_No__c,BankAccount__c
            FROM Account
            WHERE Trade_License_No__c != null AND Id IN :accountIds
        ];
        
        // Collect Trade License Numbers
        Set<String> tradeLicenses = new Set<String>();
        for (Account acc : accounts) {
            tradeLicenses.add(acc.Trade_License_No__c);
        }
        
        // Step 2: Fetch Approved Broker Applications
        Map<String, BrokerApplication__c> licenseToAppMap = new Map<String, BrokerApplication__c>();
        
        for (BrokerApplication__c bApp : [
            SELECT
            Id,
            Name,
            City__c,
            Country__c,
            ZipCodePOBoxNumber__c,
            AddressLine01__c,
            AddressLine02__c,
            AgreementExpiryDate__c,
            AgreementInitiationdate__c,
            AgreementNumber__c,
            CommercialLicenseExpiryDate__c,
            CommercialLicenseNumber__c,
            AgencyEmail__c,
            CompanyName__c,
            IsVATRegistered__c,
            LicenseType__c,
            ORNADM__c,
            CountryCode__c,
            CompanyPhone_Number__c,
            RegisteredEmirate__c,
            RegisteredCity__c,
            RegisteredCountry__c,
            RegisteredState__c,
            TaxRegistrationExpiryDate__c,
            TradeLicenseExpiryDate__c,
            AgencyType__c,
            TypeofEstablishment__c,
            TaxRegistrationNumber__c,
            VATUndertakingIssueDate__c,
            TradeLicenseNumber__c
            FROM BrokerApplication__c
            WHERE ApprovalStatus__c = 'Approved'
            AND TradeLicenseNumber__c IN :tradeLicenses
        ]) {
            // Keep first approved application per Trade License
            if (!licenseToAppMap.containsKey(bApp.TradeLicenseNumber__c)) {
                licenseToAppMap.put(bApp.TradeLicenseNumber__c, bApp);
            }
        }
        
        // Step 3: Map fields and prepare Account updates
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account acc : accounts) {
            BrokerApplication__c bApp = licenseToAppMap.get(acc.Trade_License_No__c);
            if (bApp != null) {
                
                String billingState = bApp.RegisteredState__c;
                acc.BillingCity = bApp.City__c;
                acc.BillingCountry = bApp.Country__c;
                acc.BillingPostalCode = bApp.ZipCodePOBoxNumber__c;
                acc.BillingState = billingState;
                acc.BillingStreet =
                    (bApp.AddressLine01__c != null ? bApp.AddressLine01__c : '') +
                    '\n' +
                    (bApp.AddressLine02__c != null ? bApp.AddressLine02__c : '');
                
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
                acc.PhoneCountryCode__c = bApp.CountryCode__c;
                acc.Phone__c = bApp.CompanyPhone_Number__c;
                acc.RegisteredEmirate__c = bApp.RegisteredEmirate__c;
                acc.ShippingCity = bApp.RegisteredCity__c;
                acc.ShippingCountry = bApp.RegisteredCountry__c;
                acc.ShippingState = bApp.RegisteredState__c;
                acc.TaxRegistrationExpiryDate__c = bApp.TaxRegistrationExpiryDate__c;
                acc.Trade_License_Expiry_Date__c = bApp.TradeLicenseExpiryDate__c;
                acc.Type__c = bApp.AgencyType__c;
                acc.TypeofEstablishment__c = bApp.TypeofEstablishment__c;
                acc.UAEVATRegisterNumber__c = bApp.TaxRegistrationNumber__c;
                acc.VATUndertakingIssueDate__c = bApp.VATUndertakingIssueDate__c;
                acc.Broker_Application__c = bApp.Id;
                acc.Send_To_SAP__c = true;
                
                accountsToUpdate.add(acc);
            }
        }
        
        // Step 4: Update Accounts
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
            System.debug('Accounts updated: ' + accountsToUpdate.size());
        } else {
            System.debug('No matching accounts found to update.');
        }
        
        Set<Id> updatedAccountIds = new Set<Id>();
        for (Account acc : accountsToUpdate) {
            updatedAccountIds.add(acc.Id);
        }
        createOrUpdateAndMapBankAccount(updatedAccountIds);
        
    }
    
    // Create Or Update Bank Account on the Account Object

    Public static void createOrUpdateAndMapBankAccount(Set<Id> accountIds){
        
       
        List<Account> accounts = [
            SELECT Id, Trade_License_No__c, BankAccount__c
            FROM Account
            WHERE Trade_License_No__c != null
            AND Id IN :accountIds 
        ];
        
        if (accounts.isEmpty()) {
            System.debug('No Accounts found');
            return;
        }

        Set<String> tradeLicenses = new Set<String>();
        for (Account acc : accounts) {
            tradeLicenses.add(acc.Trade_License_No__c);
        }

        Map<String, BrokerApplication__c> licenseToAppMap = new Map<String, BrokerApplication__c>();
        
        for (BrokerApplication__c bApp : [
            SELECT Id,
            TradeLicenseNumber__c,
            Account_Number__c,
            BankNameValue__c,
            BankBranchAddress__c,
            BankCountry__c,
            BeneficiaryName__c,
            BankBranch__c,
            CurrencyIsoCode,
            IBAN__c,
            SwiftCode__c
            FROM BrokerApplication__c
            WHERE ApprovalStatus__c = 'Approved'
            AND TradeLicenseNumber__c IN :tradeLicenses
        ]) {
            if (!licenseToAppMap.containsKey(bApp.TradeLicenseNumber__c)) {
                licenseToAppMap.put(bApp.TradeLicenseNumber__c, bApp);
            }
        }

        Set<Id> existingBankAccountIds = new Set<Id>();
        for (Account acc : accounts) {
            if (acc.BankAccount__c != null) {
                existingBankAccountIds.add(acc.BankAccount__c);
            }
        }

        Map<Id, BankAccount__c> existingBankAccountMap = new Map<Id, BankAccount__c>();
        if (!existingBankAccountIds.isEmpty()) {
            existingBankAccountMap = new Map<Id, BankAccount__c>([
                SELECT Id,
                AccountNumberCorporate__c,
                BankAddress__c,
                BankCountry__c,
                BeneficiaryNameCorporate__c,
                BranchCorporate__c,
                CurrencyIsoCode,
                IBANNoCorporate__c,
                SwiftCodeCorporate__c,
                Name
                FROM BankAccount__c
                WHERE Id IN :existingBankAccountIds
            ]);
        }

        List<BankAccount__c> bankAccountsToInsert = new List<BankAccount__c>();
        List<BankAccount__c> bankAccountsToUpdate = new List<BankAccount__c>();

        Map<Id, Id> appIdToAccountIdMap = new Map<Id, Id>();
        
        for (Account acc : accounts) {
            
            BrokerApplication__c bApp = licenseToAppMap.get(acc.Trade_License_No__c);
            if (bApp == null || bApp.Account_Number__c == null) continue;

            if (acc.BankAccount__c != null && existingBankAccountMap.containsKey(acc.BankAccount__c)) {
                
                BankAccount__c ba = existingBankAccountMap.get(acc.BankAccount__c);
                
                ba.Name = bApp.BankNameValue__c;
                ba.AccountNumberCorporate__c = bApp.Account_Number__c;
                ba.BankAddress__c = bApp.BankBranchAddress__c;
                ba.BankCountry__c = bApp.BankCountry__c;
                ba.BeneficiaryNameCorporate__c = bApp.BeneficiaryName__c;
                ba.BranchCorporate__c = bApp.BankBranch__c;
                ba.CurrencyIsoCode = bApp.CurrencyIsoCode;
                ba.IBANNoCorporate__c = bApp.IBAN__c;
                ba.SwiftCodeCorporate__c = bApp.SwiftCode__c;
                
                bankAccountsToUpdate.add(ba);
            }

            if (acc.BankAccount__c == null) {
                
                BankAccount__c ba = new BankAccount__c(
                    Name = bApp.BankNameValue__c,
                    AccountNumberCorporate__c = bApp.Account_Number__c,
                    BankAddress__c = bApp.BankBranchAddress__c,
                    BankCountry__c = bApp.BankCountry__c,
                    BeneficiaryNameCorporate__c = bApp.BeneficiaryName__c,
                    BranchCorporate__c = bApp.BankBranch__c,
                    CurrencyIsoCode = bApp.CurrencyIsoCode,
                    IBANNoCorporate__c = bApp.IBAN__c,
                    SwiftCodeCorporate__c = bApp.SwiftCode__c,
                    BrokerApplication__c = bApp.Id
                );
                
                bankAccountsToInsert.add(ba);
                appIdToAccountIdMap.put(bApp.Id, acc.Id);
            }
        }

        if (!bankAccountsToInsert.isEmpty()) {
            insert bankAccountsToInsert;
        }
        
        if (!bankAccountsToUpdate.isEmpty()) {
            update bankAccountsToUpdate;
        }

        Map<Id, Id> accountToBankMap = new Map<Id, Id>();
        
        for (BankAccount__c ba : bankAccountsToInsert) {
            if (ba.BrokerApplication__c != null &&
                appIdToAccountIdMap.containsKey(ba.BrokerApplication__c)) {
                    
                    accountToBankMap.put(
                        appIdToAccountIdMap.get(ba.BrokerApplication__c),
                        ba.Id
                    );
                }
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accounts) {
            if (accountToBankMap.containsKey(acc.Id)) {
                acc.BankAccount__c = accountToBankMap.get(acc.Id);
                accountsToUpdate.add(acc);
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
        
        // 🔚 DEBUG SUMMARY
        System.debug('BankAccounts Inserted: ' + bankAccountsToInsert.size());
        System.debug('BankAccounts Updated: ' + bankAccountsToUpdate.size());
        System.debug('Accounts Linked: ' + accountsToUpdate.size());
        
        copyDocumentsBAppToAcc(accountIds);
    }
    
    Public static void copyDocumentsBAppToAcc(Set <Id> accountIdstoUpdate){   
        //Copy Documents From Broker Application To Account with file Override and Filtype handling 
        
        List<Account> accounts = [
            SELECT Id, Trade_License_No__c
            FROM Account
            WHERE Id IN :accountIdstoUpdate   
            AND Trade_License_No__c != null
        ];

        Set<String> tradeLicenses = new Set<String>();
        Map<String, Id> tradeLicToAccountMap = new Map<String, Id>();
        
        for (Account acc : accounts) {
            tradeLicenses.add(acc.Trade_License_No__c);
            tradeLicToAccountMap.put(acc.Trade_License_No__c, acc.Id);
        }

        Map<String, Id> tradeLicToBrokerAppMap = new Map<String, Id>();
        
        for (BrokerApplication__c ba : [
            SELECT Id, TradeLicenseNumber__c
            FROM BrokerApplication__c
            WHERE ApprovalStatus__c = 'Approved'
            AND TradeLicenseNumber__c IN :tradeLicenses
        ]) {
            if (!tradeLicToBrokerAppMap.containsKey(ba.TradeLicenseNumber__c)) {
                tradeLicToBrokerAppMap.put(ba.TradeLicenseNumber__c, ba.Id);
            }
        }
        
        if (tradeLicToBrokerAppMap.isEmpty()) {
            System.debug(' No Approved Broker Applications found');
            return;
        }

        Map<Id, Id> accountToBrokerAppMap = new Map<Id, Id>();
        
        for (String lic : tradeLicToBrokerAppMap.keySet()) {
            accountToBrokerAppMap.put(
                tradeLicToAccountMap.get(lic),
                tradeLicToBrokerAppMap.get(lic)
            );
        }
        
        Set<Id> brokerAppIds = new Set<Id>(accountToBrokerAppMap.values());
        Set<Id> accountIds   = accountToBrokerAppMap.keySet();

        Map<String, Document__c> brokerDocKeyMap = new Map<String, Document__c>();
        Set<Id> brokerVersionIds = new Set<Id>();
        
        for (Document__c doc : [
            SELECT Id, BrokerApplication__c, Document_Name__c,
            Content_Version_Id__c, FileName__c,
            FileSizeMB__c, FileType__c
            FROM Document__c
            WHERE BrokerApplication__c IN :brokerAppIds
        ]) {
            if (doc.Document_Name__c != null &&
                doc.Content_Version_Id__c != null) {
                    
                    String key = doc.BrokerApplication__c + '##' + doc.Document_Name__c;
                    brokerDocKeyMap.put(key, doc);
                    brokerVersionIds.add(doc.Content_Version_Id__c);
                }
        }
        
        if (brokerDocKeyMap.isEmpty()) {
            System.debug('No Broker documents found');
            return;
        }

        Map<Id, ContentVersion> brokerVersionMap =
            new Map<Id, ContentVersion>([
                SELECT Id, Title, VersionData, FileExtension
                FROM ContentVersion
                WHERE Id IN :brokerVersionIds
            ]);

        List<Document__c> accountDocs = [
            SELECT Id, Account__c, Document_Name__c,
            ContentDocumentId__c, Content_Version_Id__c
            FROM Document__c
            WHERE Account__c IN :accountIds
        ];

        List<ContentVersion> newVersions = new List<ContentVersion>();
        List<Document__c> docsToUpdate   = new List<Document__c>();
        Map<Id, Document__c> tempDocMap  = new Map<Id, Document__c>();
        
        for (Document__c accDoc : accountDocs) {
            
            Id brokerAppId = accountToBrokerAppMap.get(accDoc.Account__c);
            if (brokerAppId == null) continue;
            
            String key = brokerAppId + '##' + accDoc.Document_Name__c;
            if (!brokerDocKeyMap.containsKey(key)) continue;
            
            Document__c brokerDoc = brokerDocKeyMap.get(key);
            ContentVersion srcVer =
                brokerVersionMap.get(brokerDoc.Content_Version_Id__c);
            
            if (srcVer == null) continue;
            
            // 🔹 Determine correct file extension
            String extension = srcVer.FileExtension != null
                ? '.' + srcVer.FileExtension
                : '';
            
            // 🔹 Create NEW file (replace behavior)
            ContentVersion cv = new ContentVersion();
            cv.Title = srcVer.Title;
            cv.PathOnClient = accDoc.Id + '##' + srcVer.Title + extension;
            cv.VersionData = srcVer.VersionData;
            cv.FirstPublishLocationId = accDoc.Account__c;
            
            newVersions.add(cv);
            
            // 🔹 Update Document__c metadata using real file type
            accDoc.FileName__c   = brokerDoc.FileName__c;
            accDoc.FileSizeMB__c = brokerDoc.FileSizeMB__c;
            accDoc.FileType__c   = srcVer.FileExtension != null
                ? srcVer.FileExtension.toUpperCase()
                : brokerDoc.FileType__c;
            
            docsToUpdate.add(accDoc);
            tempDocMap.put(accDoc.Id, accDoc);
        }

        if (!newVersions.isEmpty()) {
            
            insert newVersions;
            
            Map<Id, ContentVersion> insertedVersions =
                new Map<Id, ContentVersion>([
                    SELECT Id, ContentDocumentId, PathOnClient
                    FROM ContentVersion
                    WHERE Id IN :newVersions
                ]);
            
            for (ContentVersion cv : insertedVersions.values()) {
                String[] parts = cv.PathOnClient.split('##');
                if (parts.size() > 1) {
                    Id docId = (Id) parts[0];
                    if (tempDocMap.containsKey(docId)) {
                        Document__c d = tempDocMap.get(docId);
                        d.ContentDocumentId__c = cv.ContentDocumentId;
                        d.Content_Version_Id__c = cv.Id;
                    }
                }
            }
        }
        
        if (!docsToUpdate.isEmpty()) {
            update docsToUpdate;
        }

        System.debug('Documents copied successfully with correct FileType handling');
        
        copyFilesBAppToAcc(accountIdstoUpdate);        
        
    }
    
    Public static void copyFilesBAppToAcc( Set<Id> accountIdSet){
        //Copy Files From Broker Applications To Account

        List<Account> accounts = [
            SELECT Id, Trade_License_No__c
            FROM Account
            WHERE Id IN :accountIdSet   // CHANGE FILTER
            AND Trade_License_No__c != null
        ];
        
        if (accounts.isEmpty()) {
            System.debug('No Accounts found');
            return;
        }

        Set<String> tradeLicenses = new Set<String>();
        Map<String, Id> tradeLicToAccountMap = new Map<String, Id>();
        
        for (Account acc : accounts) {
            tradeLicenses.add(acc.Trade_License_No__c);
            tradeLicToAccountMap.put(acc.Trade_License_No__c, acc.Id);
        }

        Map<Id, Id> brokerAppToAccountMap = new Map<Id, Id>();
        
        for (BrokerApplication__c ba : [
            SELECT Id, TradeLicenseNumber__c
            FROM BrokerApplication__c
            WHERE TradeLicenseNumber__c IN :tradeLicenses
            AND ApprovalStatus__c = 'Approved'
        ]) {
            if (tradeLicToAccountMap.containsKey(ba.TradeLicenseNumber__c)) {
                brokerAppToAccountMap.put(
                    ba.Id,
                    tradeLicToAccountMap.get(ba.TradeLicenseNumber__c)
                );
            }
        }
        
        if (brokerAppToAccountMap.isEmpty()) {
            System.debug('No Approved Broker Applications found');
            return;
        }
        
        Set<Id> brokerAppIds = brokerAppToAccountMap.keySet();
        Set<Id> accountIds   = new Set<Id>(brokerAppToAccountMap.values());

        List<ContentDocumentLink> brokerFileLinks = [
            SELECT ContentDocumentId, LinkedEntityId,
            ShareType, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :brokerAppIds
        ];
        
        if (brokerFileLinks.isEmpty()) {
            System.debug('No files found on Broker Applications');
            return;
        }

        Set<String> existingKeys = new Set<String>();
        
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :accountIds
        ]) {
            existingKeys.add(
                link.LinkedEntityId + '-' + link.ContentDocumentId
            );
        }

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        
        for (ContentDocumentLink brokerLink : brokerFileLinks) {
            
            if (!brokerAppToAccountMap.containsKey(brokerLink.LinkedEntityId)) {
                continue;
            }
            
            Id accountId = brokerAppToAccountMap.get(brokerLink.LinkedEntityId);
            String key = accountId + '-' + brokerLink.ContentDocumentId;
            
            if (existingKeys.contains(key)) {
                continue;
            }
            
            newLinks.add(new ContentDocumentLink(
                ContentDocumentId = brokerLink.ContentDocumentId,
                LinkedEntityId    = accountId,
                ShareType         = brokerLink.ShareType,
                Visibility        = brokerLink.Visibility
            ));
        }

        if (!newLinks.isEmpty()) {
            insert newLinks;
            System.debug('Files copied to Accounts: ' + newLinks.size());
        } else {
            System.debug('No new files copied (duplicates skipped)');
        }
    }
    
    Public static void createContactfromApplicant(Set <Id> accountIds){
        // Create Contact From Applicant

        List<Account> accounts = [
            SELECT Id, Trade_License_No__c
            FROM Account
            WHERE Id IN :accountIds   // 🔴 CHANGE FILTER
            AND Trade_License_No__c != null
        ];

        Map<Id, Id> appIdToAccountIdMap = new Map<Id, Id>();
        Map<String, Id> tradeLicenseToAccountMap = new Map<String, Id>();
        
        for (Account acc : accounts) {
            tradeLicenseToAccountMap.put(acc.Trade_License_No__c, acc.Id);
        }
        
        List<BrokerApplication__c> approvedApplications = [
            SELECT Id, TradeLicenseNumber__c
            FROM BrokerApplication__c
            WHERE TradeLicenseNumber__c IN :tradeLicenseToAccountMap.keySet()
            AND ApprovalStatus__c = 'Approved'
        ];
        
        for (BrokerApplication__c app : approvedApplications) {
            Id accountId = tradeLicenseToAccountMap.get(app.TradeLicenseNumber__c);
            if (accountId != null) {
                appIdToAccountIdMap.put(app.Id, accountId);
            }
        }
        
        if (appIdToAccountIdMap.isEmpty()) {
            System.debug(' No matching approved Broker Applications found');
            return;
        }

        List<BrokerApplicant__c> applicants =
            BrokerApplicantService.getInstance()
            .getApplicantsByApplicationIds(appIdToAccountIdMap.keySet());
        
        if (applicants.isEmpty()) return;
        
        Id contactRecordTypeId =
            Schema.SObjectType.Contact
            .getRecordTypeInfosByDeveloperName()
            .get('Broker')
            .getRecordTypeId();
        
        List<Contact> contactsToInsert = new List<Contact>();
        List<Contact> insertedContacts = new List<Contact>();
        
        for (BrokerApplicant__c ba : applicants) {
            
            Id accountId = appIdToAccountIdMap.get(ba.BrokerApplication__c);
            if (accountId == null) continue;
            
            Contact con = new Contact();
            con.AccountId = accountId;
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
            con.CountryOfResidence__c = ba.Country__c;
            con.BrokerContactRole__c = ba.BrokerContactRole__c;
            con.ShareHoldingPercentage__c = ba.ShareHoldingPercentage__c;
            con.PassportNumber__c = ba.PassportNumber__c;
            con.PassportExpiryDate__c = ba.PassportExpiryDate__c;
            con.NationalIdNumber__c = ba.NationalID__c;
            con.NationalIdExpiryDate__c = ba.NationalIDExpiryDate__c;
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
            con.TypeofEstablishment__c = 'Domestic';
            con.LeadConversionAllowed__c = ba.LeadConversionallowed__c;
            
            contactsToInsert.add(con);
        }
        
        insert contactsToInsert;
        System.debug ('Countacts Count--->'+contactsToInsert.size());
    }
}
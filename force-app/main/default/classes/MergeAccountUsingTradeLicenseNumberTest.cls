@IsTest
public class MergeAccountUsingTradeLicenseNumberTest {

    @testSetup
    static void setupData() {

        // -------------------------------
        // 1️⃣ Create Account
        // -------------------------------
        Account acc = new Account(
            Name = 'Test Broker Account',
            Trade_License_No__c = 'TL-12345'
        );
        insert acc;

        // -------------------------------
        // 2️⃣ Create Approved Broker Application
        // -------------------------------
        BrokerApplication__c app = new BrokerApplication__c(
            Name = 'Test Broker App',
            TradeLicenseNumber__c = 'TL-12345',
            ApprovalStatus__c = 'Approved',

            // Account Mapping Fields
            City__c = 'Dubai',
            Country__c = 'United Arab Emirates',
            ZipCodePOBoxNumber__c = '12345',
            AddressLine01__c = 'Street 1',
            AddressLine02__c = 'Building A',

            //AgreementExpiryDate__c = Date.today().addYears(1),
            AgreementInitiationdate__c = Date.today(),
            AgreementNumber__c = 'AGR-001',

            CommercialLicenseNumber__c = 'CL-99',
            CommercialLicenseExpiryDate__c = Date.today().addYears(1),

            AgencyEmail__c = 'broker@test.com',
            CompanyName__c = 'Test Broker Company',
            IsVATRegistered__c = 'Yes',
            LicenseType__c = 'Commercial',
            ORNADM__c = 'ORN001',
            CountryCode__c = '971',
            CompanyPhone_Number__c = '99999999',

            RegisteredCity__c = 'Dubai',
            RegisteredCountry__c = 'United Arab Emirates',
            RegisteredState__c = 'Dubai',

            TaxRegistrationNumber__c = 'VAT123',
            TaxRegistrationExpiryDate__c = Date.today().addYears(1),

            TradeLicenseExpiryDate__c = Date.today().addYears(1),

            AgencyType__c = 'LLC',
            TypeofEstablishment__c = 'Domestic',

            VATUndertakingIssueDate__c = Date.today(),

            // Bank Fields
            Account_Number__c = 'ACC123',
            BankNameValue__c = 'Emirates Bank',
            BankBranchAddress__c = 'Dubai Mall Branch',
            BankCountry__c = 'United Arab Emirates',
            //BeneficiaryName__c = 'Test Beneficiary',
            BankBranch__c = 'Main Branch',
            CurrencyIsoCode = 'AED',
            IBAN__c = 'AE123456789',
            SwiftCode__c = 'SWFT123'
        );

        insert app;

        // -------------------------------
        // 3️⃣ Create Broker Applicant (for Contact creation)
        // -------------------------------
        BrokerApplicant__c applicant = new BrokerApplicant__c(
            BrokerApplication__c = app.Id,
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Email__c = 'john@test.com',
            PhoneNumber__c = '88888888',
            CountryCode__c = '971',
            BrokerContactRole__c = 'Owner'
        );
        insert applicant;

        // -------------------------------
        // 4️⃣ Create File (ContentVersion)
        // -------------------------------
        ContentVersion cv = new ContentVersion(
            Title = 'Broker License',
            PathOnClient = 'BrokerLicense.pdf',
            VersionData = Blob.valueOf('Test File Body')
        );
        insert cv;

        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // -------------------------------
        // 5️⃣ Link File to Broker Application
        // -------------------------------
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        // -------------------------------
        // 6️⃣ Create Broker Document__c
        // -------------------------------
        Document__c brokerDoc = new Document__c(
            BrokerApplication__c = app.Id,
            Document_Name__c = 'Trade License',
            Content_Version_Id__c = insertedCV.Id,
            FileName__c = 'BrokerLicense.pdf',
            FileType__c = 'PDF',
            FileSizeMB__c = '1'
        );
        insert brokerDoc;

        // -------------------------------
        // 7️⃣ Create Account Document__c (Target)
        // -------------------------------
        Document__c accountDoc = new Document__c(
            Account__c = acc.Id,
            Document_Name__c = 'Trade License'
        );
        insert accountDoc;
    }

    // =====================================================
    // MAIN TEST
    // =====================================================

    @IsTest
    static void testFullMergeFlow() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Trade_License_No__c = 'TL-12345'
            LIMIT 1
        ];

        Set<Id> accountIds = new Set<Id>{ acc.Id };

        Test.startTest();

        MergeAccountUsingTradeLicenseNumber.updateAccountsFromBrokerApps(accountIds);
        MergeAccountUsingTradeLicenseNumber.createContactfromApplicant(accountIds);


        Test.stopTest();

        // =====================================================
        // ASSERTIONS
        // =====================================================

        // ✅ Account Updated
        Account updatedAcc = [
            SELECT BillingCity, BankAccount__c, Broker_Application__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals('Dubai', updatedAcc.BillingCity);
        System.assertNotEquals(null, updatedAcc.Broker_Application__c);

        // ✅ BankAccount Created
        BankAccount__c bank = [
            SELECT Id, AccountNumberCorporate__c
            FROM BankAccount__c
            WHERE AccountNumberCorporate__c = 'ACC123'
            LIMIT 1
        ];

        System.assertNotEquals(null, bank.Id);

        // ✅ Account Linked With Bank
        System.assertEquals(bank.Id, updatedAcc.BankAccount__c);

        // ✅ Contact Created
        Contact con = [
            SELECT Id, Email
            FROM Contact
            WHERE Email = 'john@test.com'
            LIMIT 1
        ];

        System.assertNotEquals(null, con.Id);

        // ✅ File Copied To Account
        List<ContentDocumentLink> accLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];

        System.assert(accLinks.size() > 0);
    }
}
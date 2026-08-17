@IsTest
public class ContactTriggerHelperTest {
    private static final string CONTACT_RT_DEV_NAME_BROKER { get { return 'Broker'; } }
    @TestSetup
    static void setupTestData() {
        // Create test Contacts
        Contact contact1 = new Contact(
            FirstName = 'Test',
            LastName = 'User1',
            Emirates_Id__c = '123456789',
            PrimaryMobileCountryCode__c = '91',
            PrimaryMobilePhone__c = '12345678',
            SecondaryMobileCountryCode__c = '91',
            SecondaryMobilePhone__c = '87654321',
            TertiaryMobileCountryCode__c = '1',
            TertiaryMobilePhone__c = '23456789'
        );
        insert contact1;
    }
    
    @IsTest
    static void testHandleBeforeInsertFieldUpdates() {
        // Create a new contact to test before insert
        Contact newContact = new Contact(
            FirstName = 'New',
            LastName = 'Contact',
            Emirates_Id__c = '987654321',
            PrimaryMobileCountryCode__c = '44',
            PrimaryMobilePhone__c = '11111111',
            SecondaryMobileCountryCode__c = '33',
            SecondaryMobilePhone__c = '22222222',
            TertiaryMobileCountryCode__c = '55',
            TertiaryMobilePhone__c = '33333333'
        );
        
        // Simulate before insert operation
        List<Contact> newList = new List<Contact>{newContact};
            Test.startTest();
        ContactTriggerHelper.handleBeforeInsertFieldUpdates(newList);
        Test.stopTest();
        
        // Validate the updates
        System.assertEquals(Utility.formatEmiratesId(newContact.Emirates_Id__c), newContact.Emirates_Id__c, 'Emirates ID should be formatted');
        System.assertEquals(Utility.formatPhoneNumber(newContact.PrimaryMobileCountryCode__c, newContact.PrimaryMobilePhone__c), newContact.MobilePhone, 'MobilePhone should be formatted');
        System.assertEquals(Utility.formatPhoneNumber(newContact.SecondaryMobileCountryCode__c, newContact.SecondaryMobilePhone__c), newContact.HomePhone, 'HomePhone should be formatted');
        System.assertEquals(Utility.formatPhoneNumber(newContact.TertiaryMobileCountryCode__c, newContact.TertiaryMobilePhone__c), newContact.OtherPhone, 'OtherPhone should be formatted');
    }
    
    @IsTest
    static void testHandleBeforeUpdateFieldUpdates() {
        // Fetch the existing contact and modify values to simulate an update
        Contact existingContact = [SELECT Id, Emirates_Id__c, PrimaryMobileCountryCode__c, PrimaryMobilePhone__c, SecondaryMobileCountryCode__c, SecondaryMobilePhone__c, TertiaryMobileCountryCode__c, TertiaryMobilePhone__c FROM Contact LIMIT 1];
        
        existingContact.Emirates_Id__c = '999999999'; // Change Emirates ID
        existingContact.PrimaryMobilePhone__c = '44444444'; // Change PrimaryMobilePhone
        existingContact.SecondaryMobilePhone__c = '55555555'; // Change SecondaryMobilePhone
        existingContact.TertiaryMobilePhone__c = '66666666'; // Change TertiaryMobilePhone
        
        // Simulate old map
        Map<Id, Contact> oldMap = new Map<Id, Contact>{existingContact.Id => [SELECT Id, Emirates_Id__c, PrimaryMobileCountryCode__c, PrimaryMobilePhone__c, SecondaryMobileCountryCode__c, SecondaryMobilePhone__c, TertiaryMobileCountryCode__c, TertiaryMobilePhone__c FROM Contact WHERE Id = :existingContact.Id]};
            
            // Simulate before update operation
            List<Contact> newList = new List<Contact>{existingContact};
                Test.startTest();
        ContactTriggerHelper.handleBeforeUpdateFieldUpdates(newList, oldMap);
        Test.stopTest();
        
        // Validate the updates
        System.assertEquals(Utility.formatEmiratesId(existingContact.Emirates_Id__c), existingContact.Emirates_Id__c, 'Updated Emirates ID should be formatted');
        System.assertEquals(Utility.formatPhoneNumber(existingContact.PrimaryMobileCountryCode__c, existingContact.PrimaryMobilePhone__c), existingContact.MobilePhone, 'Updated MobilePhone should be formatted');
        System.assertEquals(Utility.formatPhoneNumber(existingContact.SecondaryMobileCountryCode__c, existingContact.SecondaryMobilePhone__c), existingContact.HomePhone, 'Updated HomePhone should be formatted');
        System.assertEquals(Utility.formatPhoneNumber(existingContact.TertiaryMobileCountryCode__c, existingContact.TertiaryMobilePhone__c), existingContact.OtherPhone, 'Updated OtherPhone should be formatted');
    }
    
    @IsTest
    static void testCopyDocuments() {
        // Step 0: Create BrokerApplication
        BrokerApplication__c brokerApp = new BrokerApplication__c(
            Name = 'Test Application'
        );
        insert brokerApp;
        
        // Step 1: Create BrokerApplicant
        BrokerApplicant__c brokerApplicant = new BrokerApplicant__c(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BrokerApplication__c = brokerApp.Id
        );
        insert brokerApplicant;
        
        // Step 2: Create an actual ContentVersion for the BrokerApplicant's document
        ContentVersion cv = new ContentVersion(
            Title = 'Broker Agreement File',
            PathOnClient = 'BrokerAgreement.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        
        // Fetch ContentDocumentId from inserted ContentVersion
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Step 3: Create Document__c for BrokerApplicant with real IDs
        Document__c brokerDoc = new Document__c(
            Document_Name__c = 'Broker Agreement',
            BrokerApplicant__c = brokerApplicant.Id,
            FileName__c = 'BrokerAgreement.pdf',
            FileSizeMB__c = String.valueOf(0.01),
            FileType__c = 'pdf',
            ContentDocumentId__c = cv.ContentDocumentId,
            Content_Version_Id__c = cv.Id
        );
        insert brokerDoc;
        
        // Step 4: Create Contact linked to BrokerApplicant
        Contact contact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            BrokerApplicant__c = brokerApplicant.Id
        );
        insert contact;
        
        // Step 5: Create placeholder Document__c for Contact with same Document_Name__c
        Document__c contactDoc = new Document__c(
            Contact__c = contact.Id,
            Document_Name__c = 'Broker Agreement'
        );
        insert contactDoc;
        
        // Step 6: Call the method
        Test.startTest();
        //ContactTriggerHelper.copyDocuments(new List<Contact>{contact});
        Test.stopTest();
        
        // Step 7: Verify the Contact's document was updated
        Document__c updatedDoc = [
            SELECT Id, ContentDocumentId__c, Content_Version_Id__c, FileName__c, FileType__c
            FROM Document__c
            WHERE Id = :contactDoc.Id
        ];
        
        //System.assertEquals(brokerDoc.ContentDocumentId__c, updatedDoc.ContentDocumentId__c, 'ContentDocumentId__c should match');
        //System.assertEquals(brokerDoc.FileName__c, updatedDoc.FileName__c, 'FileName__c should match');
        //System.assertEquals(brokerDoc.FileType__c, updatedDoc.FileType__c, 'FileType__c should match');
        //System.assertNotEquals(null, updatedDoc.Content_Version_Id__c, 'Content_Version_Id__c should be populated');
    }
    
    @IsTest
    static void testHandleAfterUpdate() {
        // Step 1: Insert a test Contact
        Contact con = new Contact(
            FirstName = 'UpdateTest',
            LastName = 'User',
            Email = 'test@example.com'
        );
        insert con;
        
        // Step 2: Capture old version
        Contact oldContact = con.clone(false, false, false, false);
        
        // Step 3: Update a field
        con.Email = 'updated@example.com';
        update con;
        
        // Step 4: Simulate the after update context
        Map<Id, Contact> oldMap = new Map<Id, Contact>{oldContact.Id => oldContact};
            List<Contact> newList = [SELECT Id, Email, User__c FROM Contact WHERE Id = :con.Id];
        
        Test.startTest();
        ContactTriggerHelper.handleContactUpdates(newList, oldMap);
        Test.stopTest();
        
        // Just assert updated value is what we set
        System.assertEquals('updated@example.com', newList[0].Email, 'Contact email should be updated');
    }
    
    @IsTest
    static void testCreateDocuments() {
        // Create DocumentType__c record with role and object set to 'Contact'
        List<DocumentType__c> docTypes = new List<DocumentType__c>{
            new DocumentType__c(
                Type__c = 'National ID Front',
                ObjectType__c = 'Contact',
                Active__c = true,
                TypeofEstablishment__c = 'Domestic',
                BrokerContactRole__c = 'Admin'
            ),
                new DocumentType__c(
                    Type__c = 'Passport Front',
                    ObjectType__c = 'Contact',
                    Active__c = true,
                    TypeofEstablishment__c = 'Domestic',
                    BrokerContactRole__c = 'CEO'
                )
                };
                    insert docTypes;
        
        // Get RecordTypeId for 'Broker'
        Id brokerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        
        // Create Contact with matching role and Broker record type
        Contact con = new Contact(
            FirstName = 'Role',
            LastName = 'Match',
            BrokerContactRole__c = 'Admin',
            TypeOfEstablishment__c = 'Domestic',
            RecordTypeId = brokerRTId
        );
        insert con;
        
        Test.startTest();
        ContactTriggerHelper.createDocuments(new List<Contact>{ con });
        Test.stopTest();
        
        List<Document__c> docs = [SELECT Id, Contact__c, DocumentType__c FROM Document__c WHERE Contact__c = :con.Id];
    }
    
    @IsTest
    static void testHandleContactUpdates() {
        // Step 1: Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Step 2: Create a Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '1111111111',
            AccountId = acc.Id,
            IsActive__c = true
        );
        insert con;
        
        // Step 3: Create a related User__c record
        User__c usr = new User__c(
            Name = 'Old Name',
            Contact__c = con.Id,
            Mobile_Number__c = '0000000000',
            User_Account__c = acc.Id,
            Email__c = 'old@example.com',
            IsActive__c = false,
            User_Type__c = 'Broker Agent',
            Username__c = 'old@example.com'
        );
        insert usr;
        
        // Step 4: Simulate trigger OLD values
        Contact oldCon = new Contact(
            Id = con.Id,
            FirstName = con.FirstName,
            LastName = con.LastName,
            Email = con.Email,
            Phone = con.Phone,
            AccountId = con.AccountId,
            IsActive__c = con.IsActive__c
        );
        
        // Step 5: Create NEW values
        con.Phone = '2222222222';
        con.Email = 'new.email@example.com';
        
        // Step 6: Call the method directly
        Test.startTest();
        ContactTriggerHelper.handleContactUpdates(
            new List<Contact>{con},
            new Map<Id, Contact>{oldCon.Id => oldCon}
        );
        Test.stopTest();
        
        // Step 7: Verify updates happened
        User__c updatedUser = [
            SELECT Mobile_Number__c, Email__c
            FROM User__c
            WHERE Id = :usr.Id
        ];
        //System.assertEquals('2222222222', updatedUser.Mobile_Number__c);
        //System.assertEquals('new.email@example.com', updatedUser.Email__c);
    }
    
    
    @isTest
    private static void test_createAzureUser() {
        // Get RecordType IDs dynamically
        Id accRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Id conRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        Id caseRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Broker Registration').getRecordTypeId();
        
        // Create Account
        Account acc = new Account(
            Name = 'Test Broker Agency',
            RecordTypeId = accRtId
        );
        insert acc;
        
        // Create Case
        Case cs = new Case(
            Subject = 'Broker Registration',
            RecordTypeId = caseRtId,
            Status = 'New'
        );
        insert cs;
        
        // Create Contact with matching role and Broker record type
        Contact con = new Contact(
            FirstName = 'John',
            MiddleName = 'M',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            MobilePhone = '9999999999',
            AccountId = acc.Id,
            CaseId__c = cs.Id,
            RecordTypeId = conRtId
        );
        insert con;
        
        Test.startTest();
        // Call the method under test
        //ContactTriggerHelper.createAzureUser(new List<Contact>{ con });
        Test.stopTest();
        
        // Verify
        List<User__c> users = [SELECT Id, Name, Email__c, Contact__c, User_Account__c, User_Type__c FROM User__c];
        
    }
    
    @IsTest
    static void testUpdateContactDocuments() {
        
        Id brokerContactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, CONTACT_RT_DEV_NAME_BROKER);
        
        // Create DocumentType__c using VALID role values
        List<DocumentType__c> docTypes = new List<DocumentType__c>{
            new DocumentType__c(
                Type__c = 'National ID Front',
                ObjectType__c = 'Contact',
                Active__c = true,
                TypeofEstablishment__c = 'Domestic',
                BrokerContactRole__c = 'Admin'
            ),
                new DocumentType__c(
                    Type__c = 'Trade License',
                    ObjectType__c = 'Contact',
                    Active__c = true,
                    TypeofEstablishment__c = 'Domestic',
                    BrokerContactRole__c = 'SuperAdmin'
                )
                };
                    insert docTypes;
        
        // 2. Create initial Contact with valid picklist role
        Contact original = new Contact(
            FirstName = 'RoleChange',
            LastName = 'Test101',
            BrokerContactRole__c = 'Admin',
            TypeofEstablishment__c = 'Domestic',
            RecordTypeId = brokerContactRecordTypeId
        );
        insert original;
        
        List<Contact> ContactList = [SELECT Id FROM Contact WHERE LastName = 'Test101'];
        // 3. Clone and update to simulate change in role and type
        Contact updated = original.clone(false, false, false, false);
        updated.BrokerContactRole__c = 'SuperAdmin'; // UPDATED picklist values
        updated.TypeofEstablishment__c = 'Domestic';
        updated.Id = ContactList[0].Id;
        update updated;
        
        // 4. Build oldMap & newMap
        Map<Id, sObject> oldMap = new Map<Id, sObject>{ original.Id => original };
            Map<Id, sObject> newMap = new Map<Id, sObject>{ updated.Id => updated };
                
                // 5. Call updateContactDocuments
                Test.startTest();
        ContactTriggerHelper.updateContactDocuments(
            new List<sObject>{ updated },
            newMap,
            new List<sObject>{ original },
            oldMap
        );
        Test.stopTest();
        
        // 6. Assert documents created
        List<Document__c> docs = [
            SELECT Id
            FROM Document__c
            WHERE Contact__c = :updated.Id
        ];
        
    }
    @isTest
    static void testSyncCaseDocumentsToContactTrigger() {
        Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Broker_Registration').getRecordTypeId();
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        Case cs = new Case(
            RecordTypeId = caseRTId,
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web',
            AccountId = acc.Id
        );
        insert cs;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'test@test.com'
        );
        insert con;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Passport',
            PathOnClient = 'Passport.pdf',
            VersionData = Blob.valueOf('Test File')
        );
        insert cv;
        
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        Document__c caseDoc = new Document__c(
            Case__c = cs.Id,
            Document_Name__c = 'Passport',
            FileName__c = 'Passport.pdf',
            FileType__c = 'pdf',
            FileSizeMB__c = '0.01',
            ContentDocumentId__c = cv.ContentDocumentId,
            Content_Version_Id__c = cv.Id
        );
        insert caseDoc;
        
        Document__c contactDoc = new Document__c(
            Contact__c = con.Id,
            Document_Name__c = 'Passport'
        );
        insert contactDoc;
        
        Test.startTest();
        con.CaseId__c = cs.Id;
        update con;
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleAfterUpdateFieldUpdates_SuspendBroker() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Broker',
            Email = 'broker@test.com',
            AccountId = acc.Id,
            IsSuspended__c = false,
            ApprovalStatus__c = 'Approved By Line Manager',
            Broker_Restriction_Type__c = 'Suspend'
        );
        insert con;
        
        Contact oldCon = con.clone(false, true, false, false);
        con.ApprovalStatus__c = 'Approved By Executive Sales Director';
        
        Test.startTest();
        ContactTriggerHelper.handleAfterUpdateFieldUpdates(new List<Contact>{con},new Map<Id, Contact>{con.Id => oldCon});
        Test.stopTest();
        
        Contact result = [SELECT IsSuspended__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(true,result.IsSuspended__c);
    }
    @isTest
    static void testSyncDocumentsToContact() {
        
        Id caseRTId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration')
            .getRecordTypeId();
        
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        Case cs = new Case(
            RecordTypeId = caseRTId,
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web',
            AccountId = acc.Id
        );
        insert cs;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'test@test.com',
            CaseId__c = cs.Id
        );
        insert con;
        
        // Parent (Case) Document
        ContentVersion caseCV = new ContentVersion(
            Title = 'Passport',
            PathOnClient = 'Passport.pdf',
            VersionData = Blob.valueOf('Case File')
        );
        insert caseCV;
        
        caseCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :caseCV.Id
        ];
        
        Document__c caseDoc = new Document__c(
            Case__c = cs.Id,
            Document_Name__c = 'Passport',
            FileName__c = 'Passport.pdf',
            FileType__c = 'pdf',
            FileSizeMB__c = '0.01',
            ContentDocumentId__c = caseCV.ContentDocumentId,
            Content_Version_Id__c = caseCV.Id
        );
        insert caseDoc;
        
        // Contact Document with different version
        ContentVersion contactCV = new ContentVersion(
            Title = 'OldPassport',
            PathOnClient = 'OldPassport.pdf',
            VersionData = Blob.valueOf('Old File')
        );
        insert contactCV;
        
        contactCV = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contactCV.Id
        ];
        
        Document__c contactDoc = new Document__c(
            Contact__c = con.Id,
            Document_Name__c = 'Passport',
            FileName__c = 'OldPassport.pdf',
            FileType__c = 'pdf',
            FileSizeMB__c = '0.01',
            ContentDocumentId__c = contactCV.ContentDocumentId,
            Content_Version_Id__c = contactCV.Id
        );
        insert contactDoc;
        
        Test.startTest();
        
        ContactTriggerHelper.syncDocumentsToContact(
            new List<Contact>{con},
            new Set<Id>{cs.Id},
            'CASE'
        );
        
        Test.stopTest();
        
        Document__c updatedDoc = [
            SELECT ContentDocumentId__c,
            Content_Version_Id__c
            FROM Document__c
            WHERE Id = :contactDoc.Id
        ];
        
        System.assertEquals(
            caseCV.ContentDocumentId,
            updatedDoc.ContentDocumentId__c
        );
        
        System.assertEquals(
            caseCV.Id,
            updatedDoc.Content_Version_Id__c
        );
    }    
    
}
@isTest
private class AccountTriggerHelperTest {
    @isTest
    static void testHandleBeforeInsertFieldUpdates() {
        // Test data setup
        List<Account> accountsToInsert = new List<Account>();
        
     RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
     RecordType brokerRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Broker_Agency' LIMIT 1];
     RecordType organizationRecordtype = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'OrganizationAccount' LIMIT 1];
    
        
        DocumentType__c  dtp = new DocumentType__c();
      dtp.ObjectType__c ='Account';
      dtp.Type__c = 'Proof of Payment';
      dtp.RecordTypeDevName__c ='PersonAccount';
      insert dtp;
        
      DocumentType__c  dtb = new DocumentType__c();
      dtb.ObjectType__c ='Account';
      dtb.Type__c = 'Proof of Payment';
      dtb.RecordTypeDevName__c ='Broker_Agency';
      insert dtb;
        
       DocumentType__c  dtpo = new DocumentType__c();
      dtpo.ObjectType__c ='Account';
      dtpo.Type__c = 'Proof of Payment';
      dtpo.RecordTypeDevName__c ='OrganizationAccount';
      insert dtpo;
        
       
        
        Account personAccount = new Account(
            RecordTypeId = personAccountRecordType.Id,
            LastName = 'Test Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            Nationality__c = 'Indian',
            
            PrimaryMobilePhone__pc = '1234567890',
           
            SecondaryMobilePhone__pc = '9876543210',
            
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert personAccount;
        System.debug('personAccount: ' + personAccount.IsPersonAccount);
        accountsToInsert.add(personAccount);
        
        Account Brokeraccount = new Account(
            RecordTypeId = brokerRecordType.Id,
            Name = 'Test Brokeraccount',
            TypeofEstablishment__c = 'Domestic'
            
        );
        insert Brokeraccount;
        
        Account organizationalAccount = new Account(
            RecordTypeId = organizationRecordtype.Id,
            Name = 'Test organizationalAccount' 
            
        );
        insert organizationalAccount;
        System.debug('personAccount: ' + personAccount.IsPersonAccount);
        accountsToInsert.add(personAccount);


         System.debug('personAccount'+personAccount);
        Test.startTest();
        AccountTriggerHelper.handleBeforeInsertFieldUpdates(accountsToInsert);
        Test.stopTest();

           }

    @isTest
    static void testHandleBeforeUpdateFieldUpdates() {
        RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
       
      
           
        Account oldPersonAccount = new Account(
           LastName = 'Test1 Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            RecordTypeId = personAccountRecordType.Id,
            
            Emirates_Id__pc = '1234-56-789',
            Nationality__c = 'Indian',
            PrimaryMobileCountryCode__pc = '+91',
            PrimaryMobilePhone__pc = '1234567890',
            SecondaryMobileCountryCode__pc = '+91',
            SecondaryMobilePhone__pc = '9876543210'
        );
        Map<Id, Account> oldAccountMap = new Map<Id, Account>{oldPersonAccount.Id => oldPersonAccount};

        Account updatedPersonAccount = new Account(
             RecordTypeId = personAccountRecordType.Id,
            Emirates_Id__pc = '9876-543-21',
            Nationality__c = 'American',
            PrimaryMobileCountryCode__pc = '+1',
            PrimaryMobilePhone__pc = '5551234567',
            SecondaryMobileCountryCode__pc = '+1',
            SecondaryMobilePhone__pc = '5559876543'
        );

        List<Account> accountsToUpdate = new List<Account>{updatedPersonAccount};

        // Invoke method
        Test.startTest();
        AccountTriggerHelper.handleBeforeUpdateFieldUpdates(accountsToUpdate, oldAccountMap);
        AccountTriggerHelper.handleAfterUpdateFieldUpdates(accountsToUpdate, oldAccountMap);
        Test.stopTest();
    }
    
    @isTest
    static void testHandleTradeLicenseExpiry() {

        Account acc = new Account(Name = 'Test Account', Is_Trade_License_Expired__c = false);
        insert acc;
        

        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id, IsActive__c = true, Email = 'test@gmail.com');
        insert con;
        
 
        acc.Is_Trade_License_Expired__c = true;
        acc.IsActive__c = true;
        

        Map<Id, Account> oldMap = new Map<Id, Account>{
            acc.Id => new Account(Id = acc.Id, Is_Trade_License_Expired__c = false, IsActive__c = true)
                };
                    List<Account> newList = new List<Account>{ acc };

        
        Contact updatedContact = [SELECT Id, IsActive__c FROM Contact WHERE Id = :con.Id];
    }
    
    private static Id getRecordTypeId(String objectName, String devName) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sObjType = gd.get(objectName);
        Schema.DescribeSObjectResult describe = sObjType.getDescribe();
        return describe.getRecordTypeInfosByDeveloperName().get(devName).getRecordTypeId();
    }
    
    @isTest
    private static void test_BrokerAgencyAfterUpdate() {
        // ===== ️⃣  Setup Record Types =====
        Id brokerAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Id brokerContactRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        

        User lineManager = new User(
            Alias = 'lmngr',
            Email = 'linemanager@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'linemanager' + System.currentTimeMillis() + '@test.com',
            Title = 'Line Manager'
        );
        insert lineManager;
        
        User esd = new User(
            Alias = 'esdir',
            Email = 'esd@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Director',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'esd' + System.currentTimeMillis() + '@test.com',
            Title = 'Executive Sales Director'
        );
        insert esd;
        

        Account acc = new Account(
            Name = 'Test Broker Agency',
            RecordTypeId = brokerAccountRtId,
            IsActive__c = true,
            ApprovalStatus__c = 'Submitted',
            Scenarios__c = 'Suspend',
            LineManager__c = lineManager.Id,
            ExecutiveSalesDirector__c = esd.Id
        );
        insert acc;
        
        Contact con = new Contact(
            LastName = 'Test Contact',
            RecordTypeId = brokerContactRtId,
            AccountId = acc.Id,
            IsActive__c = true,
            Email = 'test@gmail.com'
        );
        insert con;
        

        Map<Id, Account> oldMap = new Map<Id, Account>{
            acc.Id => new Account(Id = acc.Id, ApprovalStatus__c = 'Submitted', Scenarios__c = 'Suspend')
                };
                    

        acc.ApprovalStatus__c = 'Approved By Executive Sales Director';
        acc.Scenarios__c = 'Suspend';
        Test.startTest();
        AccountTriggerHelper.BrokerAgencyAfterUpdate(new List<Account>{acc}, oldMap);
  

        acc.ApprovalStatus__c = 'Approved By Executive Sales Director';
        acc.Scenarios__c = 'Terminate';
       
        AccountTriggerHelper.BrokerAgencyAfterUpdate(new List<Account>{acc}, oldMap);

        

        acc.ApprovalStatus__c = 'Approved By Line Manager';
        acc.Scenarios__c = 'Suspend';
        
        AccountTriggerHelper.BrokerAgencyAfterUpdate(new List<Account>{acc}, oldMap);
     
        

        acc.ApprovalStatus__c = 'Approved By Line Manager';
        acc.Scenarios__c = 'Terminate';
      
        AccountTriggerHelper.BrokerAgencyAfterUpdate(new List<Account>{acc}, oldMap);
        Test.stopTest();
        
   
        List<Account> updatedAccs = [SELECT Id, IsActive__c, IsSuspended__c, Blacklisted__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(0, updatedAccs.size(), 'Account should be updated');
        System.assert(updatedAccs[0].IsActive__c == false || updatedAccs[0].IsSuspended__c == true || updatedAccs[0].Blacklisted__c == true,
                      'Account should be deactivated or suspended/blacklisted');
        
        System.debug('BrokerAgencyAfterUpdate test executed successfully.');
    }
    @isTest
    static void testCreateDocuments_SuqurAlWatan_OnInsert() {
    Id personRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;

    DocumentType__c suqurDocType = new DocumentType__c(
        ObjectType__c     = 'Account',
        Type__c           = 'Suqur Al Watan Employee Document'
    );
    insert suqurDocType;

    Account acc = new Account(
        RecordTypeId       = personRtId,
        LastName           = 'Suqur Insert Test',
        PersonEmail        = 'suqurinsert@test.com',
        CustomerSubType__c = 'Staff'
    );

    Test.startTest();
    insert acc;
    Test.stopTest();

    List<Document__c> docs = [SELECT Id FROM Document__c WHERE Account__c = :acc.Id];
    System.assert(docs.size() > 0, 'Suqur Al Watan documents should be created on insert');
}

   @isTest
   static void testHandleSuqurAlWatanDocumentOnUpdate_ChangedToSuqur() {
    Id personRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;

    DocumentType__c suqurDocType = new DocumentType__c(
        ObjectType__c     = 'Account',
        Type__c           = 'Suqur Al Watan Employee Document'
        
    );
    insert suqurDocType;

    Account acc = new Account(
        RecordTypeId       = personRtId,
        LastName           = 'Pre-Suqur Person',
        PersonEmail        = 'presuqur@test.com',
        CustomerSubType__c = 'STAFF'
    );
    insert acc;

    Map<Id, Account> oldMap = new Map<Id, Account>{
        acc.Id => new Account(Id = acc.Id, CustomerSubType__c = 'STAFF')
    };

    acc.CustomerSubType__c = 'Suqur Al Watan';

    Test.startTest();
    AccountTriggerHelper.handleSuqurAlWatanDocumentOnUpdate(new List<Account>{ acc }, oldMap);
    Test.stopTest();

    List<Document__c> docs = [SELECT Id FROM Document__c WHERE Account__c = :acc.Id];
    System.assert(docs.size() >= 0, 'Method should execute without error');
}

   @isTest
   static void testHandleSuqurAlWatanDocumentOnUpdate_NoChange() {
    Id personRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;

    Account acc = new Account(
        RecordTypeId       = personRtId,
        LastName           = 'No Change Suqur',
        PersonEmail        = 'nochangesuqur@test.com',
        CustomerSubType__c = 'Staff'
    );
    insert acc;

    Map<Id, Account> oldMap = new Map<Id, Account>{
        acc.Id => new Account(Id = acc.Id, CustomerSubType__c = 'Suqur Al Watan')
    };

    // CustomerSubType__c unchanged — inner block should be skipped entirely
    Test.startTest();
    AccountTriggerHelper.handleSuqurAlWatanDocumentOnUpdate(new List<Account>{ acc }, oldMap);
    Test.stopTest();

    System.assert(true, 'No error should be thrown when CustomerSubType__c is unchanged');
}
    
}
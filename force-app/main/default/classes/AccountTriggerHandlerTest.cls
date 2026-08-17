@isTest
public class AccountTriggerHandlerTest {
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    @isTest
    static void accountTriggerTestMethod() {
        
        AccountService AccSer = AccountService.getInstance();
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        Account tempAcc=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            Nationality__c =  'Indian',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com'
        );
        Test.startTest();
        insert tempAcc;
        Test.stoptest();
        tempAcc.Salutation = 'H.H.';
        tempAcc.PhoneCountryCode__c = '91';
        tempAcc.Nationality__c =  'Syrian';
        tempAcc.Phone__c = '1234567890';
        tempAcc.PrimaryMobilePhone__pc = '1234567890';
        tempAcc.SecondaryMobilePhone__pc = '123456789';
        update tempAcc;
        AccountService.getRelatedAccountsForAccountId(tempAcc.id);
        AccountService.getRelatedAccountsForAccountId(tempAcc.id);
        AccSer.getAccountById(tempAcc.id);
        AccSer.getDuplicatePersonAccounts('1234', '5678', 'india');
        
        tempAcc.BloomStaffEmail__c='staff@bloom.com';
        AccSer.updateAccountsWithoutTrigger(new List<Account>{tempAcc});
        AccSer.updateAccountWithoutTrigger(tempAcc);
        
        Account tempAccOrg=new Account(
            Name= 'test1',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno1',
            Registration_Authority__c ='athority'
        );
        insert tempAccOrg;
        AccSer.getDuplicateOrganizationAccounts('trandeno1', 'athority');
        Date today = Date.today();
        Date thirtyDaysFromToday = today.addDays(30);
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Account tempAcc1=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test',
            Broker_Registration_Expiry_Date__c = thirtyDaysFromToday
            
        );
        insert tempAcc1;
        Id BrokerContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc1.id,
            Email='test@gmail.com',
            RecordTypeId = BrokerContactRecTypeId, 
            BrokerType__c ='Agency Admin'
        );
        insert tempContact;
    }
    
    @isTest
    static void TestMethod2() {
        
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Schema.Account.sObjectType, 'OrganizationAccount');
        Account tempAccOrg=new Account(
            Name= 'test12',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno1',
            Registration_Authority__c ='athority',
            Trade_License_Issue_Date__c = Date.newInstance(2021,03,13)
        );
        insert tempAccOrg;
        
        Contact contact = new contact();
        contact.AccountId =tempAccOrg.Id;
        contact.PrimaryContact__c = true;
        contact.LastName='lastNAme';
        contact.Emirates_Id__c='Emirates_Id';
        contact.Email = 'test@gmail.com';
        insert contact;
        tempAccOrg.Trade_License_No__c='trandeno12';
        update tempAccOrg;
    }
    
    @isTest
    static void testAfterInsertEligibleAccounts() {
        // Get Broker_Agency Record Type Id
        Id brokerAgencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency').getRecordTypeId();
        
        // Create an account with TypeofEstablishment__c populated and correct Record Type
        Account acc = new Account(
            Name = 'Eligible Broker Agency Account',
            RecordTypeId = brokerAgencyRTId,
            TypeofEstablishment__c = 'Domestic'
           
        );
        
        Test.startTest();
        insert acc; // This fires afterInsert and enters the eligibleAccounts block
        Test.stopTest();
        
        // Optional assert to confirm insert worked
        Account insertedAcc = [SELECT Id, TypeofEstablishment__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Domestic', insertedAcc.TypeofEstablishment__c);
    }

}
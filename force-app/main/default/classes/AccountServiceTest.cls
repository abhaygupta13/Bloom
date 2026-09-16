@isTest
public class AccountServiceTest {
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT { get { return 'Broker_Agency'; } }
    
    @isTest
    static void AccountServiceTestMethod() {
        
        AccountService AccSer = AccountService.getInstance();
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        Id brokerRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT);

        Account tempAcc=new Account(
            LastName= 'test',
            Emirates_Id__pc ='1234',
            PassportNumber__pc='5678',
            Nationality__pc='india',
            Nationality__c='Indian',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone  = '12345678',
            PersonEmail = 'test@gmail.com',
            Phone__c = '12345678',
            Owner__c = true,
            Tenant__c = true,
            SAP_BP_No__c = 'BP001',
            SAP_Company_Code__c = '1234'
        );
        
        insert tempAcc;
        AccountService.getRelatedAccountsForAccountId(tempAcc.id);
        AccountService.getRelatedAccountsForAccountId(tempAcc.id);
        AccSer.getDuplicatePersonAccounts('1234', '5678', 'india');
        
        // Contact related (Person branch)
        AccSer.getRelatedContact(tempAcc.id);
        AccSer.getRelatedContactName(tempAcc.id);
        AccSer.getRelatedContactEmail(tempAcc.id);
        AccSer.getRelatedContactNameArabic(tempAcc.id);

        // Person Accounts search
        AccSer.getPersonAccounts('1234', null, null);
        AccSer.getPersonAccounts(null, '5678', 'india');

        // Account fetch
        AccSer.getAccountById(tempAcc.id);
        AccSer.getLightweightById(tempAcc.id);
        AccSer.getAccountsByIds(new Set<Id>{tempAcc.Id});
        AccSer.getAccountByIds(new Set<Id>{tempAcc.Id});
        //AccSer.getAccountsMapByIds(new Set<Id>{tempAcc.Id});

        // By Account Number
        AccountService.byAccountNumber(new Set<String>{'BP001'});
        AccSer.getByAccountNumber('BP001');
        
        tempAcc.BloomStaffEmail__c='staff@bloom.com';
        AccSer.updateAccountsWithoutTrigger(new List<Account>{tempAcc});
        AccSer.updateAccountWithoutTrigger(tempAcc);
        AccSer.updateAccount(tempAcc);
        AccSer.updateAccounts(new List<Account>{tempAcc});
        //AccSer.updateExistingAccounts(new List<Account>{tempAcc});
        AccSer.updateAccountsWithoutDuplicateRule(new List<Account>{tempAcc});
        AccSer.updateAccountWithoutDuplicateRule(tempAcc);
        
        Account fullPerson = AccSer.getAccountById(tempAcc.Id);
        AccSer.getIntegrationRecord(fullPerson);
        
        Account tempAccOrg=new Account(
            Name= 'test2',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno2',
            Registration_Authority__c ='athority',
            SAP_BP_No__c = 'BP002'	
        );
        insert tempAccOrg;
        
        Contact con = new Contact(
            AccountId = tempAccOrg.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'primary@test.com',
            Phone = '99999999',
            PrimaryContact__c = true,
            Gender__c = 'Female',
            IsActive__c = true);
            insert con; 
        
        // Contact related (Org branch)
        AccSer.getRelatedContact(tempAccOrg.id);
        AccSer.getRelatedContactName(tempAccOrg.id);
        AccSer.getRelatedContactEmail(tempAccOrg.id);
        AccSer.getRelatedContactNameArabic(tempAccOrg.id);

        // With primary contact
        AccSer.getAccountsWithPrimrayContact(new Set<Id>{tempAccOrg.Id});
        AccSer.getRelatedContactForAccountId(tempAccOrg.Id);

        // Trade & Commercial
        AccSer.getAccountByTradeLicenseNumber(new Set<String>{'trandeno2'});
        AccSer.getAccountByCommercialLicenseNumber(new Set<String>{'CL123'});

        // Integration record (Org branch)
        Account fullOrg = AccSer.getAccountsWithPrimrayContact(new Set<Id>{tempAccOrg.Id})[0];
        AccSer.getIntegrationRecord(fullOrg);
        
        // ---------------- BROKER ACCOUNT ----------------
        Account brokerAcc=new Account(
            Name= 'BrokerAcc',
            recordTypeId= brokerRecordTypeId,
            Phone = '7777777',
            CompanyEmail__c = 'broker@test.com'
        );
        insert brokerAcc;

        Account fullBroker = AccSer.getAccountById(brokerAcc.Id);
        AccSer.getIntegrationRecord(fullBroker);
        
        Account tempAccOrg2=new Account(
            Name= 'test2',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno1',
            Registration_Authority__c ='athority'
        );
        Account tempAccOrg3=new Account(
            Name= 'test3',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno3',
            Registration_Authority__c ='athority'
        );
        Account tempAccOrg4=new Account(
            Name= 'test4',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno4',
            Registration_Authority__c ='athority'
        );
        AccSer.getDuplicateOrganizationAccounts('trandeno1', 'athority');
        AccSer.getRelatedContact(tempAccOrg.id);
        AccSer.getRelatedContactName(tempAccOrg.id);
        AccSer.getRelatedContactEmail(tempAccOrg.id);
        AccSer.getAccountById(tempAccOrg.id);
        AccSer.getAccountByEmails(new Set<String>{'test@gmail.com'});
        AccSer.updateAccount(tempAccOrg);
        AccountService.getAccounts(new Set<Id>{tempAccOrg.Id});
        AccSer.createAccount(tempAccOrg2);
        //AccSer.insertAccountsWithoutTrigger(new List<Account>{tempAccOrg3});
        AccSer.insertAccounts(new List<Account>{tempAccOrg4});
        
    }
}
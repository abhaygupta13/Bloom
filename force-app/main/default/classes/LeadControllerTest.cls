@isTest
public class LeadControllerTest {
    
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    
    @TestSetup static void testDataSetup() {
        
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Account testAccount=new Account(
            LastName= 'test',
            Emirates_Id__pc ='222-1211-1234321-1',
            PassportNumber__pc='5678',
            recordTypeId= personAccountRecordTypeId,
            PersonMobilePhone = '12345678',
            PersonEmail = 'test@gmail.com'
        );        
        insert testAccount;
        
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        Account tempAccOrg=new Account(
            Name= 'test11',
            recordTypeId= organizationAccountRecordTypeId,
            Trade_License_No__c='trandeno',
            Registration_Authority__c ='Fujairah Municipality'
        );
        insert tempAccOrg;
        
        Contact con = new contact();
        con.lastname ='lastname';
        con.Email='coneamil@email.com';
        con.MobilePhone='0551234567';
        con.accountID=tempAccOrg.id;
        con.Emirates_Id__c = '111-1211-1234321-1';
        insert con;    
    }
    
    
    @isTest static void CreateLeadFromPersonalAccountTestMethod(){
        test.startTest();
        Account acc= [Select id from account where PassportNumber__pc='5678'];
        LeadController.createLeadFromAccount(acc.id);
        test.stopTest();
    }
    
    @isTest 
    static void CreateLeadFromAccountOrgnizationTestMethod(){
        
        Account acc= [Select id from account where  Trade_License_No__c='trandeno'];
        LeadController.createLeadFromAccount(acc.id);
        // To cover exception
        LeadController.createLeadFromAccount(acc.id);
    }
    
    @isTest static void handleLeadUnHoldTestMethod(){
        test.startTest();
        Account acc= [Select id from account where PassportNumber__pc='5678'];
        Id leadId= LeadController.createLeadFromAccount(acc.id);
        String result = LeadController.validateBeforeLeadCreation(acc.Id);
        LeadController.handleLeadUnHold(leadId);
        String jsonData = LeadController.vaidateLead(leadId);
        LeadController.qualifyLead(leadId);
        test.stopTest();
    }
    
    @isTest static void corporateCustomerTestMethod(){
        test.startTest();
        Account acc= [Select Id FROM account WHERE Trade_License_No__c='trandeno'];
        Id leadId= LeadController.createLeadFromAccount(acc.id);
        String result = LeadController.validateBeforeLeadCreation(acc.Id);
        LeadController.handleLeadUnHold(leadId);
        String jsonData = LeadController.vaidateLead(leadId);
        LeadController.qualifyLead(leadId);
        test.stopTest();
    }
    
    @isTest static void TestMethodOne(){
        test.startTest();   
        LeadController.getSalutation();
        LeadController.getNationality();
        LeadController.getMobileCountryCode();
        LeadController.getMaritalStatus();
        LeadController.getGenderIdentity();
        test.stopTest();   
    }
    
    
    @isTest static void TestMethodcreateLeadFromEID(){
        test.startTest();   
        
        String saluation ='Mr.';
            String firstName= 'Test';
            String middleName = 'Test';
            String lastName= 'Test';
            String fullNameInArabic= 'Test';
                                          
            Date birthdate =Date.Today(); 
            String gender= 'Male';
            String maritalStatus= 'Single'; 
            String mobileCountryCode= '+971';
            String mobile= '11111111';
            String email= 'Test@gmail.com';
                                          
            String nationality= 'India';
            String passport= '111111111';
            Date passportExpiryDate =Date.Today(); 
            String placeOfIssue= 'Test'; 
            String eid= 'Test';
            Date eidExpiryDate =Date.Today();
    
    LeadController.createLeadFromEID(saluation, firstName, middleName, lastName, fullNameInArabic,
                                          birthdate, gender, maritalStatus, mobileCountryCode, mobile, email,
                                          nationality, passport, passportExpiryDate, placeOfIssue, eid, eidExpiryDate);
         test.stopTest();   
    }
    
}
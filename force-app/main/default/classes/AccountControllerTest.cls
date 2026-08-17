@isTest
public class AccountControllerTest {
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    
    @TestSetup
    static void testDataSetup(){
        // getOrganizationAccount
    }
    
    @isTest
    static void AccountTestMethod() {
        
        AccountService AccSer = AccountService.getInstance();
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        Account tempAcc=new Account( LastName= 'test');
        tempAcc.recordTypeId= personAccountRecordTypeId;
        
        tempAcc.PersonEmail = 'test@gmail.com';

        
        tempAcc.PersonEmail =null;
        tempAcc.Emirates_Id__pc ='1234';

        
        tempAcc.PersonEmail =null;
        tempAcc.Emirates_Id__pc =null;
        tempAcc.PassportNumber__pc='5678';
        tempAcc.Nationality__pc='india';

        
        tempAcc.PersonEmail =null;
        tempAcc.Emirates_Id__pc =null;
        tempAcc.PassportNumber__pc=null;
        tempAcc.Nationality__pc=null;
        tempAcc.PersonMobilePhone  = '12345678';
        tempAcc.MobileCountryCode__c  = '+971';
        
        Account tempAccOrg=new Account( LastName= 'test');
        tempAccOrg.recordTypeId= organizationAccountRecordTypeId;
        tempAccOrg.Trade_License_No__c='Trade_License_No__c';
        tempAccOrg.Registration_Authority__c ='Registration_Authority__c';
    }
    @isTest
    static void AccountTestMethodTwo() {
        
        AccountController.getNationality();
        AccountController.getMobileCountryCode();
        AccountController.getRegistrationAuthority();
        
        AccountService AccSer = AccountService.getInstance();
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        
        Account tempAccOrg=new Account( LastName= 'test');
        tempAccOrg.recordTypeId= organizationAccountRecordTypeId;
        tempAccOrg.Trade_License_No__c='Trade_License_No__c';
        tempAccOrg.Registration_Authority__c ='Registration_Authority__c';
        AccountController.getOrganizationAccount(tempAccOrg.Trade_License_No__c,tempAccOrg.Registration_Authority__c );
        
        String email='uaya@hmaol.com';
        String countryCode='+91';
        String phoneNumber='90898797';
        String eid = '3456789';
        String passportNumber='234567890'; 
        String nationality='India';            
        AccountController.getIndividualAccount(email,null, null,null,null,null);
        AccountController.getIndividualAccount(null,countryCode, phoneNumber,null,null,null);
        AccountController.getIndividualAccount(null,null, null,eid,null,null);
        AccountController.getIndividualAccount(null,null, null,null,passportNumber,nationality);
    }
}
@IsTest
public class BCAPP_AccessPermitHelperTest {

    
    @isTest
    static void testgetRelatedAccountsForAccountId() {
       
        RestResponse res = new RestResponse();
        RestContext.response = res;
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c='34242@saddas.com';
        userRecord.Account__c=accountRecord.id;
        userRecord.User_Account__c=accountRecord.id;
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        
        
        map<string,string> mapReturn =new  map<string,string>();
        mapReturn.put('accountId',accountRecord.id);
        mapReturn.put('category','Maintenance');
        mapReturn.put('preferredDate','01-Jan-2026');
        mapReturn.put('permitValidity','2');
        mapReturn.put('description','description');
        mapReturn.put('company','UAE Services');
        BCAPP_AccessPermitHelper inst=new BCAPP_AccessPermitHelper();
        inst.createAccessPermitRequest(JSON.serialize(mapReturn));
    }
    
     @isTest
    static void testgetCategoryOptions() {
        BCAPP_AccessPermitHelper inst=new BCAPP_AccessPermitHelper();
        inst.getCategoryOptions('Case','Access_Permit_Category__c');
     
    }
    
    
     @isTest
    static void testgetDependentPicklistValues() {
        BCAPP_AccessPermitHelper inst=new BCAPP_AccessPermitHelper();
        inst.getDependentPicklistValues('Service_Types__c','Case','Access_Permit_Category__c');
     
    }

    @isTest
    static void testgetFieldFromApiName() {
        BCAPP_AccessPermitHelper inst=new BCAPP_AccessPermitHelper();
        inst.getFieldFromApiName('Case','Access_Permit_Category__c');
     
    }

    
    
    
    
    
    
}
@isTest
public class UnitDataTableControllerTest {   
    @TestSetup
    static void setupTestData(){
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Unit__c un = new Unit__c();
        un.Name = 'test unit';
        insert un;
        
        SalesOrder__c sO = new SalesOrder__c();
        sO.Account__c = acc.Id;
        sO.Status__c = 'Sold';
        sO.Unit__c = un.Id;
        insert sO;
        
        
    }
    
    @isTest
    static void geRelatedtAccount_Test(){
        Unit__c unt = [SELECT Id, Name FROM Unit__c];
        List<SalesOrder__c> soList = UnitDataTableController.geRelatedtAccount(unt.Id);
        //System.assertEquals(1, soList.Size());
    }
    
    @isTest
    static void getRelatedUnits_Test(){
        Account acc = [SELECT Id, Name FROM Account];
        List<SalesOrder__c> soList = UnitDataTableController.getRelatedUnits(acc.Id);
        System.assertEquals(1, soList.Size());
    }
}
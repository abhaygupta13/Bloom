@isTest
public class UnitTriggerTest {
    @isTest
    static void testAfterUpdate() {
        List<Unit__c> units = new List<Unit__c>();
        units.add(new Unit__c(Name = 'testUnit1', Status__c = 'Booked'));
        units.add(new Unit__c(Name = 'testUnit2', Status__c = 'Booked'));  //Booked      
        
        Test.startTest();
        insert units;
        Test.stopTest();     
        
        List<Unit__c> unitList = [SELECT Id, Name, Status__c FROM Unit__c WHERE Id IN :units];
        for (Unit__c un : unitList) {
            un.Status__c = 'Sold';
            //System.assertEquals( ho.Status__c, 'In Progress');
        }
        
        //Test.startTest();
       	update unitList;
        //Test.stopTest();       
    }

}
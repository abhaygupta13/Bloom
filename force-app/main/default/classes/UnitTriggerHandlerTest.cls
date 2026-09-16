/*
* @Author : Jayprakash Bharti
* @CreatedDate : 20th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
*****************************************************************************************************/
@isTest
private class UnitTriggerHandlerTest {
    
    @TestSetup static void testDataSetup() {
        Test.startTest();
        Project__c objProject = TestDataFactory.createProject('Test Project');
        objProject.GIS_Service_URL__c='URL';
        insert objProject;
        
        List<unit__c> unitLst = new List<unit__c>();
        for(integer i =0;i<20;i++){          
            unitLst.add(TestDataFactory.createUnit(objProject.Id, 'J1A1-G01'+i,'Booked'));  
        }
        insert unitLst;
        Test.stopTest();
    }
    
    @isTest static void TestMethod1(){
        Test.startTest();
        unit__c unit= [Select id,name from Unit__c limit 1];
        unit.Send_to_GIS__c=true;
        update unit;
        unit.SaleableArea__c = 502;
        update unit;
        
        List<unit__c> unitLst = [select id,name,Send_to_GIS__c from unit__c limit 11];
        for(Unit__c ut:unitLst){
            ut.Send_to_GIS__c=true;
        }
        update unitLst;
        delete unit;
        Test.stopTest();
    }
    
    @isTest static void TestMethod2(){
        Test.startTest();
        unit__c unit= [Select id,name from Unit__c limit 1];
        unit.IsInactive__c = true;
        update unit;
        unit.IsInactive__c = false;
        unit.Send_to_GIS__c=true;
        update unit;
        unit.SaleableArea__c = 502;
        update unit;
        
        List<unit__c> unitLst = [select id,name,Send_to_GIS__c from unit__c limit 11];
        for(Unit__c ut:unitLst){
            ut.Send_to_GIS__c=true;
        }
        update unitLst;
        delete unit;
        undelete unit;
        Test.stopTest();
    }
    
}
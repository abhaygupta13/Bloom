/*
* @Author : Jayprakash Bharti
* @CreatedDate : 30th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  30AUG2024        Test  
*****************************************************************************************************/
@IsTest
public class DuplicateRecordSetTriggerTest {
    
    @TestSetup static void testDataSetup() {
        test.startTest();
        Lead lead= TestDataFactory.createLead('leadName', '1234567890','emailID@xyz.com');
        insert lead;
    }
    
    @IsTest
    static void testFirstMethod(){
        
        DuplicateRule dR = [select id from DuplicateRule where DeveloperName = 'Lead_Duplicate_Rule' LIMIT 1];
        DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.id);
        insert dupRS;
        
        Test.startTest();
        Lead lead= TestDataFactory.createLead('leadName', '1234567890','emailID@xyz.com');
        Database.DMLOptions insertDML = new Database.DMLOptions(); 
        insertDML.DuplicateRuleHeader.AllowSave = true; 
        Database.SaveResult sr = Database.insert(lead, insertDML);
        DuplicateRecordItem dup = new DuplicateRecordItem(DuplicateRecordSetId = dupRS.id, RecordId=lead.id);
        insert dup;
        
        Lead lead1= TestDataFactory.createLead('leadName1', '1234567890','emailID@xyz.com');
        Database.DMLOptions insertDML1 = new Database.DMLOptions(); 
        insertDML1.DuplicateRuleHeader.AllowSave = true; 
        Database.SaveResult sr1 = Database.insert(lead1, insertDML1);
        DuplicateRecordItem dup1 = new DuplicateRecordItem(DuplicateRecordSetId = dupRS.id, RecordId=lead1.id);
        insert dup1;
        
        delete dupRS;
        Test.stopTest();
    }
}
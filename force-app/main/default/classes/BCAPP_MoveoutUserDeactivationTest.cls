//============================ BCAPP_MoveoutUserDeactivationTest =============================
/*
* @Author : Eagles  
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_MoveoutUserDeactivationTest
* @Description : Test class for BCAPP_MoveoutUserDeactivationSchedule
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               28 OCT 2024        Initial draft 
*****************************************************************************************************/
@isTest
public class BCAPP_MoveoutUserDeactivationTest {
    
    public static void testData(){

        Service_Catalog__c serviceCatalog = new Service_Catalog__c(Name = 'Move Out');
        Service_Catalog__c ren_serviceCatalog = new Service_Catalog__c(Name = 'Renewal');
        List<Service_Catalog__c> lstSC = new List<Service_Catalog__c>();
        lstSC.add(serviceCatalog);
        lstSC.add(ren_serviceCatalog);
        insert lstSC;
        
        Project__c testProject = new Project__c(Name = 'Test Project');
        insert testProject;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name = 'Test Building',
            BuildingSectionCode__c = 'BL-CAS',
            Project__c = testProject.Id
        );
        insert testBuilding;
        
        List<Service_Catalog_Fields__c> fieldsList = new List<Service_Catalog_Fields__c>();
        
        // Adding multiple Service_Catalog_Fields__c records to the list
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'unitId',
            Field_API_Name__c = 'Unit__c',
            User_Type__c = 'Tenant;Holiday Homes',
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'leaseExpDate',
            Field_API_Name__c = 'EJARI_Tawteeq_end_date__c',
            User_Type__c = 'Tenant;Holiday Homes',
            is_Date__c = true,
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'childOccupants',
            Field_API_Name__c = 'Total_Number_of_Child_Occupants__c',
            User_Type__c = 'Tenant;Holiday Homes',
            is_Decimal__c = true,
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'adultOccupants',
            Field_API_Name__c = 'Total_Number_of_Adults_Occupants__c',
            User_Type__c = 'Tenant;Holiday Homes',
            is_Decimal__c = true,
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        fieldsList.add(new Service_Catalog_Fields__c(
            Name = 'accountId',
            Field_API_Name__c = 'AccountId',
            User_Type__c = 'Tenant;Holiday Homes',
            Service_Catalog__c = ren_serviceCatalog.Id
        ));
        
        // Insert all records at once
        insert fieldsList;
        
        // Create a Unit record (Unit__c)
        Unit__c unit = new Unit__c(Name = 'Unit 1', Project__c = testProject.Id, BuildingSectionName__c = testBuilding.Id, Is_Chiller_Enabled__c = true);
        insert unit;
        
        Account acc = new Account(Name = 'Test Account',Tenant__c=true);
        insert acc;
        
        // Create a custom User record (user__c)
        user__c customUser = new user__c(
            Name = 'Test User', 
            Email__c = 'testuser@example.com', 
            user_account__c = acc.Id,
            Account__c = acc.Id,
             isActive__c = true,
            Azure_UserId__c='1234-123343-4454'
        );
        insert customUser;
        acc.User__c = customUser.Id;
        UPDATE acc;
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move Out').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= acc.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
       
        insert testCase;
        system.debug('@@##$$'+testCase.RecordType.Name);
    }
    static testmethod void Positivetest1(){
        testData();
        BCAPP_MoveoutUserDeactivationSchedule sch = new BCAPP_MoveoutUserDeactivationSchedule();
        String sc ='0 48 * * * ?'; 
        System.schedule('Test Bloom Job', sc,sch);
    }
  static testmethod void Positivetest2(){
    testData();

    Test.startTest();
    BCAPP_MoveoutUserDeactivationBatch batch = new BCAPP_MoveoutUserDeactivationBatch();
    database.executebatch(batch,10);
    Test.stopTest();
  }
}
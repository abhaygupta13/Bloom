@isTest
public class sendBCCControllerTest {
    @TestSetup
    static void setupTestData() {
        User u = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='HO Agent'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_HO_Agent'];
            
            u = new User(FirstName = 'Ho Agent', LastName='User', Alias = 'op', Email='hoagent@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                         LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='hoagent@bloom.com.u1');
            insert u;
            
            insert new PermissionSetAssignment(AssigneeId = u.Id,PermissionSetId = ps.Id);
        }

        
        Project__c pr = new Project__c();
        pr.Name = 'testProject';        
        insert pr;     
     
        BuildingSection__c bld = new BuildingSection__c();
        bld.Name = 'testBuilding';
        bld.BuildingSectionCode__c = '1234567890';
        bld.Project__c = pr.Id; 
        insert bld;        
            
        Unit__c unt = new Unit__c();
        unt.Name = 'testUnit';
        unt.BuildingSectionName__c = bld.Id;
        unt.Status__c = 'Booked';
        insert unt;
        
         Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@example.com';
        insert acc;
        
        Handover__c hand = new Handover__c();
        hand.Customer_Email__c = 'test@gmail.com';
        hand.Status__c = 'In Progress';
        hand.Unit__c = unt.Id;
        hand.Account__c = acc.id;
        hand.Is_BCC_Announcement_Sent__c = false;
        hand.Unit_is_Ready__c = false;
        hand.Is_Orientation_Letter_Sent__c = false;
        hand.HO_Agent_Assigned_User__c = u.Id;
        insert hand;

		Unit__c unt1 = new Unit__c();
        unt1.Name = 'testUnit1';
        unt1.BuildingSectionName__c = bld.Id;
        unt1.Status__c = 'Booked';
        insert unt1;
        
        Handover__c hand1 = new Handover__c();
        hand1.Customer_Email__c = 'test@gmail.com';
        hand1.Status__c = 'In Progress';
        hand1.Unit__c = unt1.Id;     
        hand1.Account__c = acc.id;
        hand1.Is_BCC_Announcement_Sent__c = true;
        hand1.Unit_is_Ready__c = false;
        hand1.Is_Orientation_Letter_Sent__c = false;
        hand1.HO_Agent_Assigned_User__c = u.Id;
        hand1.Sub_Status__c = Constants.Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED;
        insert hand1;     
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Full Guideline Document';
        contentVersion.PathOnClient = 'FullGuidelineDocument.pdf';
        contentVersion.VersionData = Blob.valueOf('Full Guideline Document');
        insert contentVersion;
        
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
        Document__c dc = new Document__c();
        dc.Document_Name__c = Constants.HO_CHO_DeSnagging_Report;
        dc.Handover__c = hand1.Id;
        dc.ContentDocumentId__c = con.ContentDocumentId;
        dc.Content_Version_Id__c = con.Id;
        insert dc;
        
        Document__c dcm = new Document__c();
        dcm.Document_Name__c = Constants.HO_SOA;
        dcm.Handover__c = hand1.Id;
        dcm.ContentDocumentId__c = con.ContentDocumentId;
        dcm.Content_Version_Id__c = con.Id;
        insert dcm;
    }
    
    @isTest
    static void getProjectsTest(){
        List<Map<String, String>> projectList = sendBCCController.getProjects();
        System.assertEquals(1, projectList.size(), 'The project list should contain exactly one project.');
    }
    
    @isTest
    static void getBuildingsTest(){       
        List<Project__c> projectList = [SELECT Id, Name FROM Project__c LIMIT 1];
        List<Map<String, String>> buildingList = sendBCCController.getBuildings(projectList[0].Id);
        System.assertEquals(1, buildingList.size(), 'The building list should contain exactly one building.');
    }
     
    @isTest
    static void getUnitsTest(){ 
        Project__c project = [SELECT Id, Name FROM Project__c WHERE Name ='testProject'];
        List<Unit__c> unitList = [SELECT Id, Name, BuildingSectionName__c, Status__c FROM Unit__c LIMIT 1];
        Test.startTest();
        List<sendBCCController.UnitWrap> getUnitList = sendBCCController.getUnits(project.Id, unitList[0].BuildingSectionName__c);
        Handover__c handover = [SELECT Id,CustomerEmail__c, Is_BCC_Announcement_Sent__c FROM Handover__c WHERE Unit__c = :unitList[0].Id];
        handover.Is_BCC_Announcement_Sent__c = true;
        update handover;
        List<sendBCCController.HandoverWrap> handoverWrapList1 = sendBCCController.getUnitToMakeReady('', '');
        List<sendBCCController.HandoverWrap> handoverWrapList2 = sendBCCController.getUnitToMakeReady(project.Id, '');
        List<sendBCCController.HandoverWrap> handoverWrapList3 = sendBCCController.getUnitToMakeReady('', unitList[0].BuildingSectionName__c);
        Test.stopTest();
        System.assertEquals(1, getUnitList.size());
    }
    
	@isTest
    static void getNOCUnitsTest(){ 
        Project__c project = [SELECT Id, Name FROM Project__c WHERE Name ='testProject'];
        List<Unit__c> unitList = [SELECT Id, Name, BuildingSectionName__c, Status__c FROM Unit__c WHERE Name = 'testUnit1' LIMIT 1];
        Test.startTest();
        List<sendBCCController.HandoverNOCWrap> getNOCUnitList = sendBCCController.getNOCUnits(project.Id, unitList[0].BuildingSectionName__c);
        List<sendBCCController.HandoverNOCWrap> getNOCUnitList1 = sendBCCController.getNOCUnits('', '');
        List<sendBCCController.HandoverNOCWrap> getNOCUnitList2 = sendBCCController.getNOCUnits(project.Id, '');
        Handover__c handover = [SELECT Id, Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c FROM Handover__c WHERE Unit__c = :unitList[0].Id];
        handover.Is_Notice_of_Completion_Sent__c = true;
        update handover;
        List<sendBCCController.HandoverWrap> handoverWrapList1 = sendBCCController.getUnitToMakeReady('', '');
        List<sendBCCController.HandoverWrap> handoverWrapList2 = sendBCCController.getUnitToMakeReady(project.Id, '');
        List<sendBCCController.HandoverWrap> handoverWrapList3 = sendBCCController.getUnitToMakeReady('', unitList[0].BuildingSectionName__c);
        Test.stopTest();
    }
    
    @isTest
    static void getCHOUnitsTest(){ 
        Project__c project = [SELECT Id, Name FROM Project__c WHERE Name ='testProject'];
        List<Unit__c> unitList = [SELECT Id, Name, BuildingSectionName__c, Status__c FROM Unit__c WHERE Name = 'testUnit1' LIMIT 1];
        Test.startTest();
        List<sendBCCController.HandoverWrap> getNOCUnitList = sendBCCController.getUnitToMakeReady(project.Id, unitList[0].BuildingSectionName__c);
        Handover__c handover = [SELECT Id, CustomerEmail__c,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c FROM Handover__c WHERE Unit__c = :unitList[0].Id];
        handover.Is_Notice_of_Completion_Sent__c = true;
        update handover;
        List<sendBCCController.HandoverWrap> handoverWrapList1 = sendBCCController.getUnitToMakeReady('', '');
        List<sendBCCController.HandoverWrap> handoverWrapList2 = sendBCCController.getUnitToMakeReady(project.Id, '');
        List<sendBCCController.HandoverWrap> handoverWrapList3 = sendBCCController.getUnitToMakeReady('', unitList[0].BuildingSectionName__c);
        Test.stopTest();
    }
    
    
    @isTest
    static void sendBCCMailToCustomerTest(){      
      Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
        
        
        // Create a Unit
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;


        
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@example.com';
        insert acc;
        
   
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = acc.Id;
        insert sc;
        
        
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        update unit;
        
        
        Profile profileCRM = [SELECT Id FROM Profile WHERE Name = 'CRM Operations'];
        
        User userRecord = new User(
            Alias = 'zaki',
            Email = 'zakial@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki.al.bakri@example.com'
        );
        insert userRecord;
        
        // Create a Handover record
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            account__c = acc.id,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = userRecord.Id,
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false
        );
        insert handover;
        String result = sendBCCController.sendOrientationMailToCustomer(new List<Id>{handover.Id});
         String batchId1 = sendBCCController.sendBCCMailToCustomer(new List<Id>{ unit.Id});
        String result1 = sendBCCController.sendNOCMailToCustomer(new List<Id>{handover.Id});
        System.assertEquals('Records submitted successfully. We will send you a mail once the record will be completely processed.', result);
    }
    
 /*   @isTest
    static void sendNOCMailToCustomerTest(){      
        Project__c project = [SELECT Id, Name FROM Project__c WHERE Name ='testProject'];
        List<Unit__c> unitList = [SELECT Id, Name, BuildingSectionName__c, Status__c FROM Unit__c WHERE Name = 'testUnit1' LIMIT 1];
        Handover__c handover = [SELECT Id,CustomerEmail__c, Is_BCC_Announcement_Sent__c FROM Handover__c WHERE Unit__c = :unitList[0].Id];
        System.debug('handover'+handover);
        String batchId1 = sendBCCController.sendBCCMailToCustomer(new List<Id>{unitList[0].Id});
        String result = sendBCCController.sendNOCMailToCustomer(new List<Id>{handover.Id});
        System.assertEquals('Records submitted successfully. We will send you a mail once the record will be completely processed.', result);
    }*/
}
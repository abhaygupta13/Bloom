@isTest
public class CustomDocManageControllerTest {

    @TestSetup
    static void setupTestData() {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
                
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.LeadChannel__c = 'Call';
       // opp.LeadSubSource__c = 'Broker';
        opp.StageName = 'New';
        opp.WinReason__c = 'Price';
        opp.CloseDate = Date.today();
        insert opp;
                
        Project__c pr = new Project__c();
        pr.Name = 'testProject';        
        insert pr;
        
        BuildingSection__c bld = new BuildingSection__c();
        bld.Name = 'testBuilding';
        bld.BuildingSectionCode__c = '1234567890';
        bld.Project__c = pr.Id; 
        insert bld;
        
        
        Unit__c unit = new Unit__c();
        unit.Name = 'Unit001';
        unit.SAP_Unit_Number__c = '123';
        unit.RelatedOpportunity__c = opp.Id;
        unit.BuildingSectionName__c = bld.Id;
        insert unit;        
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = acc.Id;
        insert sc;
                
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        update unit;
                        
        Schema.RecordTypeInfo handoverRecordTypeInfo = Schema.getGlobalDescribe().get('Handover__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Handover');
            Handover__c ho = new Handover__c();
            ho.Sub_Status__c ='Created';
            ho.Is_Manual__c = 'Yes';
            ho.unit__c = unit.Id;
            ho.Sales_Order__c = sc.Id;
            ho.Customer_Email__c ='test@gmail.com';
            ho.RecordTypeId = handoverRecordTypeInfo.getRecordTypeId();
            insert ho;

        
        Project__c testProject = new Project__c(Name = 'Test Project');
        insert testProject;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name = 'Test Building',
            BuildingSectionCode__c = 'BL-CAS',
            Project__c = testProject.Id
        );
        insert testBuilding;
        
        Unit__c testUnit = new Unit__c(
            Name = 'test Unit',
            Status__c = 'Available',
            UnitType__c = 'Townhouse',
            BuildingSectionName__c = testBuilding.Id,
            Project__c = testProject.Id,
            PropertyUsage__c = 'Residential',
            UnitView__c = 'Beach Side',
            FloorNumber__c = '01',
            NumberOfBedrooms__c = '3',
            UnitModel__c = '1BHK'
        );
        insert testUnit;
        
        User crmUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_CRM_Team'];
            
            crmUser = new User(FirstName = 'CRM', LastName='User', Alias = 'op', Email='crmUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                               LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='crmUser@bloom.com.u1');
            insert crmUser;
            
            insert new PermissionSetAssignment(AssigneeId = crmUser.Id,PermissionSetId = ps.Id);
        }
        
        User collectionUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Collection Team'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_Collection_Team'];
            
            collectionUser = new User(FirstName = 'Collection', LastName='User', Alias = 'op', Email='collectionUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                               LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='collectionUser@bloom.com.u1');
            insert collectionUser;
            
            insert new PermissionSetAssignment(AssigneeId = collectionUser.Id,PermissionSetId = ps.Id);
        }
        
        User operationUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Operations Team'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_Operation_Team'];
            
            operationUser = new User(FirstName = 'Operation', LastName='User', Alias = 'op', Email='operationUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                                     LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='operationUser@bloom.com.u1');
            insert operationUser;
            
            insert new PermissionSetAssignment(AssigneeId = operationUser.Id,PermissionSetId = ps.Id);
        }
        
        User financeUser = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Finance Team'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_FInance_Team'];
            
            financeUser = new User(FirstName = 'Finance', LastName='User', Alias = 'op', Email='financeUser@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                                   LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='financeUser@bloom.com.u1');
            insert financeUser;
            
            insert new PermissionSetAssignment(AssigneeId = financeUser.Id,PermissionSetId = ps.Id);
        }
        
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(testUser) {
            Group hoOperationQueue = new Group(Name = Constants.HO_OPERATION_QUEUE, Type = 'Queue');
            insert hoOperationQueue;

            GroupMember hoOperationQueueMember = new GroupMember(GroupId = hoOperationQueue.Id, UserOrGroupId = operationUser.Id);
            insert hoOperationQueueMember;

            Group hoCollectionQueue = new Group(Name = Constants.HO_COLLECTION_QUEUE, Type = 'Queue');
            insert hoCollectionQueue;

            GroupMember hoCollectionQueueMember = new GroupMember(GroupId = hoCollectionQueue.Id, UserOrGroupId = collectionUser.Id);
            insert hoCollectionQueueMember;

            Group financeQueue = new Group(Name = Constants.FINANCE_QUEUE, Type = 'Queue');
            insert financeQueue;

            GroupMember financeQueueMember = new GroupMember(GroupId = financeQueue.Id, UserOrGroupId = financeUser.Id);
            insert financeQueueMember;
        }
        
        Document__c documentObj = new Document__c();
        insert documentObj;
        
        Round_Robins__c rr = new Round_Robins__c();
        rr.Name = 'Handover CRM';
        rr.Sobject__c = 'Handover__c';
        rr.Team__c = 'CRM';
        insert rr;
        
        Round_Robin_User__c rrUser = new Round_Robin_User__c();
        rrUser.User__c = crmUser.Id;
        rrUser.Round_Robin__c = rr.Id;
        rrUser.Round_Robin_ID__c = 1;
        insert rrUser;

        Test.stopTest();
    }
    
    @istest
    private static void testMethod1(){
        
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        
        Unit__c testUnit = [SELECT Id,Name,Status__c,UnitType__c,BuildingSectionName__c,Project__c,PropertyUsage__c, 
                            UnitView__c,FloorNumber__c,NumberOfBedrooms__c FROM Unit__c LIMIT 1];
        
        Document__c documentObj = [SELECT Id from Document__c LIMIT 1];
        
        CustomDocManageController.getDocMetaDataInfo(testUnit.Id);
        CustomDocManageController.getDocumentList(testUnit.Id, 'Unit__c');
        
        CustomDocManageController.downloadDocument(handover.Id);
        CustomDocManageController.getHandoverTeamUsersList(handover.Id);
        CustomDocManageController.addFilesonRecord('base64', 'filename', documentObj);
        CustomDocManageController.addFilesonRecordCreate('base64', 'filename', documentObj);
        
        try{
            CustomDocManageController.addFilesonRecord('base64', 'filename', null);
        }catch(Exception ex){}
        try{
            CustomDocManageController.addFilesonRecordCreate('base64', 'filename', null);
        }catch(Exception ex){}
        
        Test.startTest();
        
        CustomDocManageController.deleteFile(documentObj.Id);
        
        CustomDocManageController.createContentVersion('InvalidBase64', 'filename');
        
        ContentVersion cv = CustomDocManageController.createContentVersion('ValidBase64', 'filename');
        CustomDocManageController.createContentLink(cv.Id, null); 

        Document__c emptyDocument = new Document__c();
        insert emptyDocument;
        CustomDocManageController.addFilesonRecord('base64', 'filename', emptyDocument);
        CustomDocManageController.deleteFile(emptyDocument.Id);
        Test.stopTest();
    }
   /*     @istest
    private static void testMethod2(){
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        CustomDocManageController.getHandoverLeasingDocName(handover.Id);

    }*/
      @istest
    private static void testMethod3(){
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        CustomDocManageController.getFiles(handover.Id);

    }
    @istest
    private static void testMethod4(){
        Handover__c handover = [Select ID,Name,Customer_Email__c,Is_Manual__c,Sub_Status__c,Sales_Order__c,unit__c,OwnerId from Handover__c WHERE Customer_Email__c ='test@gmail.com' LIMIT 1];
        CustomDocManageController.getPdfFilesWithIdsAsBase64(handover.Id);

    }
}
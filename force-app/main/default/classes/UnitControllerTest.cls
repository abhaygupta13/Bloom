@istest 
public class UnitControllerTest {
    
    @istest
    static void Testmethod1() {
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000
            
        );
        insert testUnit;
        
        
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='SampleTitle.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_1;
        
         ContentVersion contentVersion_3 = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='SampleTitle.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_3;
        
         ContentVersion contentVersion_4 = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='SampleTitle.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_4;
        
        
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                                           FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        
        ContentVersion contentVersion_2_1 = [SELECT Id, Title, ContentDocumentId 
                                           FROM ContentVersion WHERE Id = :contentVersion_3.Id LIMIT 1];
        
        ContentVersion contentVersion_2_2 = [SELECT Id, Title, ContentDocumentId 
                                           FROM ContentVersion WHERE Id = :contentVersion_4.Id LIMIT 1];
        
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = testUnit.id;
        contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = testUnit.id;
        contentlink1.contentdocumentid = contentVersion_2_1.contentdocumentid;
        contentlink1.ShareType = 'V';
        insert contentlink1;
        
        ContentDocumentLink contentlink2 = new ContentDocumentLink();
        contentlink2.LinkedEntityId = testUnit.id;
        contentlink2.contentdocumentid = contentVersion_2_2.contentdocumentid;
        contentlink2.ShareType = 'V';
        insert contentlink2;
        
        System.assertEquals(contentlink.ContentDocumentId,contentVersion_2.ContentDocumentId );
        
        String floorPlanFileData = 'Test floorPlan' ;
        String floorPlanFileType = 'PDF';
        String marketingPlanFileData = 'Test MarketingPlan';
        String marketingPlanFileType = 'PDF';
        String affectionPlanFileData = 'Test affectionplan';
        String affectionPlanFileType = 'PDF';
        
        Test.startTest();
        UnitController.uploadUnitLayouts(testUnit.id,contentlink.ContentDocumentId,contentlink1.ContentDocumentId,contentlink2.ContentDocumentId);
        Test.stopTest();
    }
}
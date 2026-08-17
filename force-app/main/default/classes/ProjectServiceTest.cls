@isTest
public class ProjectServiceTest {
    
    @TestSetup
    static void creatingData() {
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        INSERT account;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('TEST');
        project.ProjectRegistrationDate__c = Date.today() - 1;
        project.ProjectNameArabic__c = 'Test Arabic name';
        //project.IsActive__c = true;
        project.ADHAProjectID__c = 'H-42-41-01';
        insert project;
        
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = new SalesOrder__c();
        salesOrder.Unit__c = u.Id;
        salesOrder.Account__c = account.Id;
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        insert salesOrder;
        
        u.Active_Sales_Order__c = salesOrder.Id;
        update u;
        
        // Create test Document__c record
        Document__c testDocument = TestDataFactory.createDoc(null, salesOrder.Id, null);
        testDocument.Document_Name__c = 'Test';
        testDocument.ContentDocumentId__c = null;
        insert testDocument;
        
    }
    // Test methods 
    
    @isTest
    static void testMethods() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'TEST' Limit 1];
        Test.startTest();
        //ProjectService Obj = new ProjectService();
        
        ProjectService Obj = ProjectService.getInstance();
        Obj.updateProject(proj);
        Obj.updateProjects(new List<Project__c>{proj});
        Obj.getProjects();
        Obj.getActiveProjects();
        Obj.getProjectDetailsWithUnitsAndDocuments(proj.Id,'Test','Sold');
        Obj.getProjectsByIds(new set<Id>{proj.Id});
        Obj.getProjectWithUnits(proj.Id,'');
        Obj.getProjectWithSoldUnits(proj.Id,'');
        //Obj.fetchProjects();
        Obj.getCommunityAppProjects();
        // --- Static methods ---
        ProjectService.fetchProjectsByIds(new Set<Id>{proj.Id});
        ProjectService.fetchProjectsByIds(new Set<Id>()); // empty set check
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testGetADHAProjectById() {
        
        Test.startTest();
        
        ProjectService obj = ProjectService.getInstance();
        
        Project__c project = obj.getADHAProjectById('H-42-41-01');
        
        Test.stopTest();
        
        System.assertNotEquals(null, project);
        System.assertEquals('H-42-41-01', project.ADHAProjectID__c);
        System.assertEquals('TEST', project.Name);
    }
}
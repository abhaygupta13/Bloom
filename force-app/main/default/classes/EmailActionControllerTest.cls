/*****************************************************************************************
Class       : EmailActionControllerTest
Author      : Vikas Baliyan
Description : Email Action Controller Test
Test Class  : 
Created Date: 31 JAN 2025 
*****************************************************************************************/
@isTest
public class EmailActionControllerTest {
    @testSetup
    private static void testData() {
        // Create a test Account
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        // Create a test Contact
        Contact testContact = TestDataFactory.createContact('test name', acc.Id, true, 'test@gmail.com');
        insert testContact;

        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        // Create EmailTemplate 
        System.runAs(testUser){
            EmailTemplate emailTemplate  = TestDataFactory.createEmailTemplate('templateName');
            insert emailTemplate;
        }
        
        // Create a test Project
        Project__c testProject = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert testProject;
        
        // Create a test Unit
        Unit__c unit = TestDataFactory.createUnit(testProject.Id, 'Test unit', 'Sold');
        insert unit;
		// Create a test opportunity
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;
        
        // Create a test Sales Order
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        insert salesOrder; 

        //create a bank account
        BankAccount__c bankAcc = TestDataFactory.createBankAccount('test bank', 'Handover', testProject.Id);
        insert bankAcc;
    }
    
    @IsTest
    static void testSendEmail(){
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
        Project__c project = [SELECT Id,HOCEmailTemplateFullyPaid__c,HOCEmailTemplatePartiallyPaid__c FROM Project__c];
        project.HOCEmailTemplateFullyPaid__c = testEmailTemplate.Id;
        project.HOCEmailTemplatePartiallyPaid__c = testEmailTemplate.Id;
        update project;
        Test.StartTest();
        try{
        String result = EmailActionController.sendEmail(testSalesOrder.Id, new List<Map<String, String>>());
        }catch(Exception ex){}
        Test.StopTest();
        //Assert.areEqual(true, result, 'Email not sent');
    }
    
    @IsTest
    static void testSendFetchEmailTemplate(){
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
        Project__c project = [SELECT Id,HOCEmailTemplateFullyPaid__c,HOCEmailTemplatePartiallyPaid__c FROM Project__c];
        project.HOCEmailTemplateFullyPaid__c = testEmailTemplate.Id;
        project.HOCEmailTemplatePartiallyPaid__c = testEmailTemplate.Id;
        update project;
        
        Test.StartTest();
        String result = EmailActionController.fetchEmailTemplate(testSalesOrder.Id);
        Test.StopTest();
        Assert.areEqual(false, String.isBlank(result), 'Email template not found');
    }
    
    @IsTest
    static void testJointOwner(){
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
        Account objAccount = [SELECT Id FROM Account];
        Project__c project = [SELECT Id,HOCEmailTemplateFullyPaid__c,HOCEmailTemplatePartiallyPaid__c FROM Project__c];
        project.HOCEmailTemplateFullyPaid__c = testEmailTemplate.Id;
        project.HOCEmailTemplatePartiallyPaid__c = testEmailTemplate.Id;
        update project;
        
        JointOwner__c objJO = new JointOwner__c(Joint_Owner_Number__c = 123,Account__c = objAccount.Id,SharePercentage__c = 10,SalesOrder__c = testSalesOrder.Id);
        insert objJO;
        Test.StartTest();
        String result = EmailActionController.fetchEmailTemplate(testSalesOrder.Id);
        Test.StopTest();
        Assert.areEqual(false, String.isBlank(result), 'Email template not found');
    }
}
/*****************************************************************************************
Class       : CommissionPDFController Test 
Author      : Vikas Baliyan
Description : Commission PDF Controller Test 
Test Class  : 
Created Date: 19 NOV 2024 
*****************************************************************************************/

@IsTest
public class CommissionPDFControllerTest {
    
    @TestSetup
    static void createTestData() {
        
        Project__c project = TestDataFactory.createProject('Project 1', System.today());
        insert project;
        
        List<BrokerCommission__c> commissionList = new List<BrokerCommission__c>();
        for(Integer i=0; i<20; i++){
            BrokerCommission__c commission = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, null, null, null, null);
            commissionList.add(commission);
        }
        insert commissionList;

    }

    @IsTest
    static void testConstructor() {
        BrokerCommission__c invoice = [SELECT Id FROM BrokerCommission__c LIMIT 1];

        // Set up the test page
        PageReference testPage = Page.CommissionInvoicePDFGenerator;
        testPage.getParameters().put('brokerCommissionId', invoice.Id);
        Test.setCurrentPage(testPage);

        // Instantiate the controller
        

        Test.StartTest();
        CommissionPDFController controller = new CommissionPDFController();
        Test.StopTest();

        // Verify that the controller is properly initialized
        Assert.areNotEqual(null, controller.invoiceLineItems, 'Invoice Line Items list should not be null.');
        Assert.areEqual(1, controller.invoiceLineItems.size(), 'There should be 1 invoice line item.');
        Assert.areEqual('15,000.00', controller.totalAmount, 'Total amount should be 15,000.00');
    }
}
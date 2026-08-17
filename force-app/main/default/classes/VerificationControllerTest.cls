/*****************************************************************************************
Class       : VerificationController Test
Author      : Vikas Baliyan
Description : Verification Controller Test
Test Class  : 
Created Date: 23 Jan 2025 
*****************************************************************************************/
@isTest
public class VerificationControllerTest {
    @testSetup
    private static void testData() {
        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        insert salesOrder;

        BrokerCommission__c bc = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, null, null, null, null);
        insert bc;

        ReceiptAcknowledgement__c receiptAcknowledgement = TestDataFactory.createReceiptAcknowledgement(opp.Id, 'Cash', 10000, null, null, null, salesOrder.Id);
        insert receiptAcknowledgement;
    }

    @IsTest
    static void testVerifyRecordBrokerCommission(){
        BrokerCommission__c broker = [SELECT Id,InvoiceVerified__c FROM BrokerCommission__c LIMIT 1];
        Test.startTest();
        VerificationController.verifyRecord(broker.Id);
        Test.stopTest();
        BrokerCommission__c updatedBroker = [SELECT Id,InvoiceVerified__c FROM BrokerCommission__c WHERE Id =: broker.Id];
        Assert.areEqual(true, updatedBroker.InvoiceVerified__c, 'Record not updated');
    }

    @IsTest
    static void testVerifyRecordReceiptAcknowledgement(){
        ReceiptAcknowledgement__c receiptAcknowledgement = [SELECT Id,Finance_Verified__c FROM ReceiptAcknowledgement__c LIMIT 1];
        Test.startTest();
        VerificationController.verifyRecord(receiptAcknowledgement.Id);
        Test.stopTest();
        ReceiptAcknowledgement__c updatedreceiptAcknowledgement = [SELECT Id,Finance_Verified__c FROM ReceiptAcknowledgement__c WHERE Id =: receiptAcknowledgement.Id];
        Assert.areEqual(true, updatedreceiptAcknowledgement.Finance_Verified__c, 'Record not updated');
    }
}
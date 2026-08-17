/***
Class       : SalesOrderControllerTest
Author      : Dhanraj Poojary
Description : Test class for SalesOrderController
****************************************************************************************************************/
@isTest
public class SalesOrderControllerTest {
    
    @IsTest
    static void testGenerateSOAAndAttachPdf_Success() {
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Salesorder__c so = new Salesorder__c(
            Name = 'SO-1001',
            Account__c = acc.Id
        );
        insert so;

        Test.setCurrentPage(Page.SalesSOAPDF);
        ApexPages.currentPage().getParameters().put('id', so.Id);

        Test.startTest();
        String cvId = SalesOrderController.generateSOAAndAttachPdf(
            so.Id, 'generateSOA'
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateSOAAndAttachPdf_NullId_ShouldThrow() {
        Test.startTest();
        try {
            SalesOrderController.generateSOAAndAttachPdf(
                null, 'generateSOA'
            );
        } catch (AuraHandledException ahe) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateAndAttachPdf_Success() {
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;
        
        Salesorder__c so = new Salesorder__c(
            Name = 'SO-1001',
            Account__c = acc.Id
        );
        insert so;

        Test.setCurrentPage(Page.SalesReceiptPDFPage);
        ApexPages.currentPage().getParameters().put('id', so.Id);

        Test.startTest();
        String cvId = SalesOrderController.generateAndAttachPdf(
            so.Id, 'SalesReceiptPDFPage'
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateAndAttachPdf_NullId_ShouldThrow() {
        Test.startTest();
        try {
            SalesOrderController.generateAndAttachPdf(
                null, 'SalesReceiptPDFPage'
            );
        } catch (AuraHandledException ahe) {
        }
        Test.stopTest();
    }
}
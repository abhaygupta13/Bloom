/***
Class       : SalesOrderController
Author      : Dhanraj Poojary
Description : 
TestClass   : SalesOrderControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/

public class SalesOrderController {
    
    @AuraEnabled
    public static String generateAndAttachPdf(Id salesOrderId, String identifier) {
        ContentService objContentService = ContentService.getInstance();
        
        if (salesOrderId == null) {
            throw new AuraHandledException('Sales Order Id is required.');
        }
        
        SalesOrderService service = SalesOrderService.getInstance();
        List<Salesorder__c> salesOrders = service.getSalesOrderWithInstallmentLinesReceiptAllocation(salesOrderId);
        
        if (salesOrders.isEmpty()) {
            throw new AuraHandledException('No Sales Order found for the provided Id.');
        }
        
        String soNumber = salesOrders[0].Name;
        PageReference pdfPage = (identifier == 'SalesReceiptPDFPage') ? Page.ReceiptAcknowledgementPDF : null;
        
        if (pdfPage == null) {
            throw new AuraHandledException('Invalid PDF identifier.');
        }
        
        pdfPage.getParameters().put('id', salesOrderId);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test PDF Content') : pdfPage.getContent();
        
        ContentVersion objContentVersion = objContentService.createContentVersion(pdfBlob, 'ReceiptAcknowledgment.pdf', 'Receipt Acknowledgment - ' + soNumber);
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        
        ContentDocumentLink objCDL = objContentService.createContentDocumentLink(insertedCV.ContentDocumentId, salesOrderId, 'V', 'AllUsers');
        
        return objContentVersion.Id;
    }
    
    @AuraEnabled
    public static String generateSOAAndAttachPdf(Id salesOrderId, String identifier) {
        ContentService objContentService = ContentService.getInstance();
        if (salesOrderId == null) {
            throw new AuraHandledException('Sales Order Id is required.');
        }
        
        SalesOrderService service = SalesOrderService.getInstance();
        Salesorder__c objSalesOrder = service.getSalesOrderWithInstallmentAndReceiptAllocation(salesOrderId);
        
        String soNumber = objSalesOrder.Name;
        String statementFileName = 'Statement-' + soNumber;
        
        PageReference pdfPage;
        pdfPage = Page.SalesSOAPDF;
        pdfPage.getParameters().put('id', salesOrderId);
        
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test PDF Content') : pdfPage.getContent();
        ContentVersion cv = new ContentVersion();
        cv.Title = statementFileName;
        cv.PathOnClient = cv.Title + '.pdf';
        cv.VersionData = pdfBlob;
        cv.IsMajorVersion = true;
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = salesOrderId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        return cv.Id;
    }
}
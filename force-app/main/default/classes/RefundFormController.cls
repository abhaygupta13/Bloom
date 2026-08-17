/*****************************************************************************************
Class       : RefundFormController
Author      : Kalpana
Description : Controller Class for Generate Refund Form Requiremenet.
Created Date: 20/07/26
*****************************************************************************************/
public with sharing class RefundFormController {
    
    @AuraEnabled
    public static String generateRefundForm(
        Id leasingOrderId,
        String notes,
        Date waterElectricityDate,
        Date maintenanceCheckoutDate
    ) {
        
        if (leasingOrderId == null) {
            throw new AuraHandledException('Leasing Order Id is required.');
        }
        
        RefundFormWrapper wrapper = RefundFormService.getRefundForm(
            leasingOrderId,
            notes,
            waterElectricityDate,
            maintenanceCheckoutDate
        );
        
        saveRefundPDF(
            leasingOrderId,
            wrapper,
            notes,
            waterElectricityDate,
            maintenanceCheckoutDate
        );
        
        return 'Success';
    }
    
    
    private static void saveRefundPDF(
        Id leasingOrderId,
        RefundFormWrapper wrapper,
        String notes,
        Date waterElectricityDate,
        Date maintenanceCheckoutDate
    ) {
        
        PageReference pdfPage = Page.RefundFormPDF;
        
        pdfPage.getParameters().put('id', leasingOrderId);
        pdfPage.getParameters().put('notes', notes);
        
        if (waterElectricityDate != null) {
            pdfPage.getParameters().put(
                'waterDate',
                String.valueOf(waterElectricityDate)
            );
        }
        
        if (maintenanceCheckoutDate != null) {
            pdfPage.getParameters().put(
                'maintenanceDate',
                String.valueOf(maintenanceCheckoutDate)
            );
        }
        Document__c refundDocument = [
            SELECT Id, Document_Name__c
            FROM Document__c
            WHERE LeasingOrder__c = :leasingOrderId
            AND Document_Name__c = 'Refund form'
            LIMIT 1
        ];
        
        List<ContentDocumentLink> existingLinks = [
            
            SELECT Id,
            ContentDocumentId
            
            FROM ContentDocumentLink
            
            WHERE LinkedEntityId = :refundDocument.Id
            
        ];
        
        if (!existingLinks.isEmpty()) {
            
            Set<Id> contentDocumentIds = new Set<Id>();
            
            for (ContentDocumentLink link : existingLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
            }
            
            delete existingLinks;
            
            delete [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN :contentDocumentIds
            ];
        }
        
        
        Blob pdfBlob;
        
        if (Test.isRunningTest()) {
            
            pdfBlob = Blob.valueOf('Refund PDF');
            
        } else {
            
            pdfBlob = pdfPage.getContentAsPDF();
            
        }
        
        ContentVersion cv = new ContentVersion();
        
        cv.Title = 'Refund Form';
        
        cv.PathOnClient = 'Refund Form.pdf';
        
        cv.VersionData = pdfBlob;
        
        insert cv;
        
        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.LinkedEntityId = refundDocument.Id;
        
        cdl.ContentDocumentId = cv.ContentDocumentId;
        
        cdl.ShareType = 'V';
        
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
    }
    
}
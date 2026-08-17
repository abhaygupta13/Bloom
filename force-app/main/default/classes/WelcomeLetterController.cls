/*****************************************************************************************
Class       : WelcomeLetterController
Author      : Kalpana
Description : Controller for generating Mandatory Requirements Welcome Letter.
*****************************************************************************************/
public with sharing class WelcomeLetterController {
    
    @AuraEnabled
    public static String generateWelcomeLetter(Id leasingOrderId) {
        
        if (leasingOrderId == null) {
            throw new AuraHandledException('Leasing Order Id is required.');
        }
        
        saveWelcomeLetterPDF(leasingOrderId);
        
        return 'Success';
    }
    
    private static void saveWelcomeLetterPDF(Id leasingOrderId) {
        
        LeasingOrder__c leasingOrder = [
            SELECT Id, PropertyUsage__c
            FROM LeasingOrder__c
            WHERE Id = :leasingOrderId
            LIMIT 1
        ];
        
        PageReference pdfPage = Page.WelcomeLetterPDF;
        
        if (leasingOrder.PropertyUsage__c == 'Commercial') {
            pdfPage = Page.WelcomeLetterPDFCom;
        }
        
        pdfPage.getParameters().put('id', leasingOrderId);
        
        Document__c documentRecord = [
            SELECT Id,
            Document_Name__c
            FROM Document__c
            WHERE LeasingOrder__c = :leasingOrderId
            AND Document_Name__c = 'Welcome Letter'
            LIMIT 1
        ];
        
        List<ContentDocumentLink> existingLinks = [
            SELECT Id,
            ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :documentRecord.Id
        ];
        
        if (!existingLinks.isEmpty()) {
            
            Set<Id> contentDocumentIds = new Set<Id>();
            
            for (ContentDocumentLink cdl : existingLinks) {
                contentDocumentIds.add(cdl.ContentDocumentId);
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
            
            pdfBlob = Blob.valueOf('Welcome Letter');
            
        } else {
            
            pdfBlob = pdfPage.getContentAsPDF();
            
        }
        
        ContentVersion cv = new ContentVersion();
        
        cv.Title = 'Welcome Letter';
        cv.PathOnClient = 'Welcome Letter.pdf';
        cv.VersionData = pdfBlob;
        
        insert cv;
        
        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.LinkedEntityId = documentRecord.Id;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
    }
}
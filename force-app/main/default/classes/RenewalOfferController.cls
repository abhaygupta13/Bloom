/*****************************************************************************************
Class       : RenewalOfferController
Author      : Kalpana
Description : Controller Class for Generate Renewal Offer PDF.
Created Date: 03/08/26
*****************************************************************************************/
public with sharing class RenewalOfferController {

    @AuraEnabled
    public static String generateRenewalOffer(Id leasingOrderId) {

        if (leasingOrderId == null) {
            throw new AuraHandledException(
                'Leasing Order Id is required.'
            );
        }

        RenewalOfferWrapper wrapper =
            RenewalOfferService.getRenewalOffer(leasingOrderId);

        saveRenewalOfferPDF(
            leasingOrderId,
            wrapper
        );

        return 'Success';
    }


    private static void saveRenewalOfferPDF(
        Id leasingOrderId,
        RenewalOfferWrapper wrapper
    ) {

        PageReference pdfPage = Page.RenewalOfferPDF;

        pdfPage.getParameters().put(
            'id',
            leasingOrderId
        );


        /*
         * Get existing Document__c record.
         * This assumes the Document record is already created
         * for the Leasing Order.
         */
        Document__c renewalDocument = [
            SELECT Id,
                   Document_Name__c
            FROM Document__c
            WHERE LeasingOrder__c = :leasingOrderId
            AND Document_Name__c = 'Offer Template for Renewal'
            LIMIT 1
        ];


        /*
         * Delete existing files linked to this Document.
         * This keeps only the latest Renewal Offer PDF.
         */
        List<ContentDocumentLink> existingLinks = [

            SELECT Id,
                   ContentDocumentId

            FROM ContentDocumentLink

            WHERE LinkedEntityId = :renewalDocument.Id

        ];


        if (!existingLinks.isEmpty()) {

            Set<Id> contentDocumentIds =
                new Set<Id>();

            for (ContentDocumentLink link : existingLinks) {

                contentDocumentIds.add(
                    link.ContentDocumentId
                );

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

            pdfBlob =
                Blob.valueOf(
                    'Renewal Offer PDF'
                );

        } else {

            pdfBlob =
                pdfPage.getContentAsPDF();

        }


        ContentVersion cv =
            new ContentVersion();

        cv.Title =
            'Offer Template for Renewal';

        cv.PathOnClient =
            'Offer Template for Renewal.pdf';

        cv.VersionData =
            pdfBlob;

        insert cv;


        cv = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];


        ContentDocumentLink cdl =
            new ContentDocumentLink();

        cdl.LinkedEntityId =
            renewalDocument.Id;

        cdl.ContentDocumentId =
            cv.ContentDocumentId;

        cdl.ShareType =
            'V';

        cdl.Visibility =
            'AllUsers';

        insert cdl;

    }

}
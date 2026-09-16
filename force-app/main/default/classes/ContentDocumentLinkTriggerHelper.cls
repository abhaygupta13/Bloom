/*
* @Author : Biswajeet Samal
* @CreatedDate : 
* @Description : ContentDocumentLinkTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 1.1			Akshay		11Aug24
*****************************************************************************************************/

public without sharing class ContentDocumentLinkTriggerHelper {
    private static final List<String> leasingDocumentList = new List<String>{'Leasing Offer - Signed','Leasing Contract - Signed'};
    
    public static void handleFileBeforeInsert(List<ContentDocumentLink> newList) {
        Set<Id> documentIds = new Set<Id>();
        
        // Collect LinkedEntityId values for Document__c
        for (ContentDocumentLink link : newList) {
            if ( link.LinkedEntityId != null && link.LinkedEntityId.getSObjectType() == Document__c.SObjectType && link.ShareType == 'V') {
                documentIds.add(link.LinkedEntityId);
            }
        }
        
        if (!documentIds.isEmpty()) {
            ContentDocumentLinkService objContentDocumentLinkService = ContentDocumentLinkService.getInstance();
            List<ContentDocumentLink> existingCDLinkList = objContentDocumentLinkService.getcontentDocumentLinksByIds(documentIds);
            objContentDocumentLinkService.deleteContentDocumentLinks(existingCDLinkList);
        }
    }
    
    
    public static void handleAfterFileInsert(List<ContentDocumentLink> newList) {
        List<Document__c> documentsToUpdate = new List<Document__c>();
        Set<Id> contentDocIds = new Set<Id>();
        Map<Id, Id> docIdToContentDocId = new Map<Id, Id>();
        
        for (ContentDocumentLink link : newList) {
            if (link.LinkedEntityId != null &&
                link.LinkedEntityId.getSObjectType() == Document__c.SObjectType &&
                link.ShareType == 'V') {
                    
                    docIdToContentDocId.put(link.LinkedEntityId, link.ContentDocumentId);
                    contentDocIds.add(link.ContentDocumentId);
                }
        }
        
        Map<Id, ContentVersion> contentDocIdToVersion = new Map<Id, ContentVersion>();
        Map<Id, Id> contentDocIdToLatestVersionId = new Map<Id, Id>();
        
        if (!contentDocIds.isEmpty()) {
            // Get latest content versions
            for (ContentVersion cv : ContentService.getInstance()
                 .getLatestContentVersionsByDocumentIds(contentDocIds)) {
                     contentDocIdToVersion.put(cv.ContentDocumentId, cv);
                 }
            
            // Get ContentDocument latest published version IDs
            for (ContentDocument cd : ContentDocumentLinkService.getInstance()
                 .getContentDocumentsByIds(contentDocIds)) {
                     contentDocIdToLatestVersionId.put(cd.Id, cd.LatestPublishedVersionId);
                 }
        }
        
        // To collect BrokerApplication IDs to update
        Set<Id> brokerAppIdsToUpdate = new Set<Id>();
        
        // Get Document__c records to fetch related BrokerApplication__c
        
        Map<Id, Document__c> docMap = new Map<Id, Document__c>(
            DocumentService.getInstance().getDocumentsByIds(docIdToContentDocId.keySet())
        );
        
        BrokerApplicationService BAService = BrokerApplicationService.getInstance();
        for (Id docId : docIdToContentDocId.keySet()) {
            Id cdId = docIdToContentDocId.get(docId);
            ContentVersion fullCV = contentDocIdToVersion.get(cdId);
            Id contentVersionId = contentDocIdToLatestVersionId.get(cdId);
            Document__c docRecord = docMap.get(docId);
            
            if (fullCV != null && contentVersionId != null) {
                Document__c docUpdate = new Document__c();
                docUpdate.Id = docId;
                docUpdate.ContentDocumentId__c = cdId;
                docUpdate.Content_Version_Id__c = contentVersionId;
                //Applicable for Broker Implementation
                if (docRecord.BrokerApplication__c != null || docRecord.BrokerApplicant__c != null) {
                    docUpdate.FileName__c = fullCV.Title;
                    docUpdate.FileType__c = fullCV.FileType;
                    docUpdate.FileSizeMB__c = String.valueOf(
                        Decimal.valueOf(fullCV.ContentSize).divide(1048576, 2, RoundingMode.HALF_UP)
                    );
                }
                
                documentsToUpdate.add(docUpdate);
                
                // NEW LOGIC: If IsRFIUpdateTrue__c is true, collect related BrokerApplication__c ID
                
                if (fullCV.IsRFIUpdated__c && docMap.containsKey(docId)) {
                    if ((docRecord.BrokerApplication__c != null || docRecord.BrokerApplicant__c != null)) {
                        Id brokerAppId = docRecord.BrokerApplication__c;
                        if (brokerAppId != null) {
                            brokerAppIdsToUpdate.add(brokerAppId);
                        }
                    }
                }
            }
        }
    
        DocumentService.getInstance().updateDocuments(documentsToUpdate);
        
        // Update BrokerApplication__c records
        if (!brokerAppIdsToUpdate.isEmpty()) {
            List<BrokerApplication__c> appsToUpdate = new List<BrokerApplication__c>();
            for (Id appId : brokerAppIdsToUpdate) {
                appsToUpdate.add(new BrokerApplication__c(
                    Id = appId,
                    IsRFIUpdated__c  = true
                ));
            }
            //update appsToUpdate;
            BAService.updateBrokerApplications(appsToUpdate);
        }
    }
    
    // This method handles the logic after ContentDocumentLink records are inserted
    public static void createContentDitributionForNotification(
        List<ContentDocumentLink> contentDocumentLinks
    ) {
        List<ContentDistribution> contentDistributionsToCreate = new List<ContentDistribution>();
        
        Set<Id> contentDocumentIds = new Set<Id>();
        
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            // Only process files linked to MyCustomObject__c
            if (
                cdl.LinkedEntityId != null &&
                cdl.LinkedEntityId.getSObjectType() == Notifications__c.SObjectType
            ) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
        }
        if (!contentDocumentIds.isEmpty()) {
            // Query ContentDocuments to ensure the records exist and have the proper IDs
            Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>(
                 // [
                //     SELECT Id, Title, LatestPublishedVersionId
                //     FROM ContentDocument
                //     WHERE Id IN :contentDocumentIds
                // ]
                new ContentDocumentService().getContentDocuments(contentDocumentIds)
            );
            
            // Loop through the incoming ContentDocumentLinks
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                // Only process files linked to Notifications__c
                if (
                    cdl.LinkedEntityId != null &&
                    cdl.LinkedEntityId.getSObjectType() == Notifications__c.SObjectType
                ) {
                    ContentDistribution cd = new ContentDistribution();
                    cd.Name = contentDocumentMap.get(cdl.ContentDocumentId).Title;
                    cd.ContentVersionId = contentDocumentMap.get(cdl.ContentDocumentId)
                        .LatestPublishedVersionId;
                    cd.PreferencesAllowViewInBrowser = true;
                    cd.PreferencesLinkLatestVersion = true;
                    cd.PreferencesNotifyOnVisit = false;
                    cd.PreferencesPasswordRequired = false;
                    cd.PreferencesAllowOriginalDownload = true;
                    contentDistributionsToCreate.add(cd);
                }
            }
            // Insert ContentDistribution records if any were created
            if (!contentDistributionsToCreate.isEmpty()) {
                insert contentDistributionsToCreate;
            }
        }
    }
    
    public static void moveLeasingSignedFilesToDocument(List<ContentDocumentLink> newLinks) {
        if (newLinks.isEmpty()) return;
        
        // Step 1: Collect all Leasing Order IDs and ContentDocument IDs
        Set<Id> leasingOrderIds = new Set<Id>();
        Set<Id> contentDocIds = new Set<Id>();
        DocumentService docService = DocumentService.getInstance();
        
        for (ContentDocumentLink link : newLinks) {
            //if (link.LinkedEntityId != null && String.valueOf(link.LinkedEntityId).startsWith('a4i')) { 
            if (link.LinkedEntityId != null && link.LinkedEntityId.getSObjectType() == LeasingOrder__c.SObjectType) { 
                leasingOrderIds.add(link.LinkedEntityId);
                contentDocIds.add(link.ContentDocumentId);
            }
        }
        
        if (leasingOrderIds.isEmpty() || contentDocIds.isEmpty()) return;
        
        // Step 2: Get latest ContentVersion for each ContentDocument
        Map<Id, ContentVersion> latestVersions = new Map<Id, ContentVersion>();
        
        // for (ContentVersion ver : [
        //     SELECT Id, ContentDocumentId, Title, IsLatest
        //     FROM ContentVersion
        //     WHERE ContentDocumentId IN :contentDocIds
        //     AND IsLatest = true
        // ]) {
        for (ContentVersion ver :ContentService.getInstance().getContentVersionsByCDIds(contentDocIds)){
            latestVersions.put(ver.ContentDocumentId, ver);
        }
        
        if (latestVersions.isEmpty()) return;
        
        // Step 3: Fetch related Document__c records
        Map<Id, Id> offerDocMap = new Map<Id, Id>();
        Map<Id, Id> contractDocMap = new Map<Id, Id>();
        
        // for (Document__c doc : [
        //     SELECT Id, LeasingOrder__c, Document_Name__c
        //     FROM Document__c
        //     WHERE LeasingOrder__c IN :leasingOrderIds
        //     AND Document_Name__c IN ('Leasing Offer - Signed', 'Leasing Contract - Signed')
        // ]) {
        for (Document__c doc : docService.getLeasingSignDocuments(leasingOrderIds, leasingDocumentList)) {
            if (doc.Document_Name__c == 'Leasing Offer - Signed') {
                offerDocMap.put(doc.LeasingOrder__c, doc.Id);
            } else if (doc.Document_Name__c == 'Leasing Contract - Signed') {
                contractDocMap.put(doc.LeasingOrder__c, doc.Id);
            }
        }
        
        if (offerDocMap.isEmpty() && contractDocMap.isEmpty()) return;
        
        // Step 4: Prepare list of ContentDocumentLinks to update
        List<ContentDocumentLink> newLinksToInsert = new List<ContentDocumentLink>();
        
        for (ContentDocumentLink link : newLinks) {
            ContentVersion ver = latestVersions.get(link.ContentDocumentId);
            if (ver == null || String.isBlank(ver.Title)) continue;
            
            String title = ver.Title;
            Id leasingOrderId = link.LinkedEntityId;
            Id newParentId;
            
            // Match based on latest version title keywords
            if (title.contains('Offer Letter')) {
                newParentId = offerDocMap.get(leasingOrderId);
            } else if (title.contains('Leasing Contract')) {
                newParentId = contractDocMap.get(leasingOrderId);
            }
            
            if (newParentId != null) {
                newLinksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = link.ContentDocumentId,
                    LinkedEntityId = newParentId,
                    ShareType = 'V', // Viewer
                    Visibility = 'AllUsers'
                ));
            }
        }
        
        // Step 5: Update the links
        if (!newLinksToInsert.isEmpty()) {
           
            //insert newLinksToInsert;
            ContentService.getInstance().insertContentDocumentLink(newLinksToInsert);
            // Optional: Delete old links (must clone, not delete Trigger.new)
            List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
            for (ContentDocumentLink link : newLinks) {
                for (ContentDocumentLink created : newLinksToInsert) {
                    if (link.ContentDocumentId == created.ContentDocumentId) {
                        linksToDelete.add(new ContentDocumentLink(Id = link.Id));
                    }
                }
            }
            if (!linksToDelete.isEmpty()) {
                //delete linksToDelete;
                ContentService.getInstance().deleteContentDocumentLink(linksToDelete);
            }
        }
    }
      public static void moveSignedKYCFilesToDocument(List<ContentDocumentLink> newLinks) {
    if (newLinks.isEmpty()) {
        return;
    }

    Set<Id> caseIds = new Set<Id>();
    Set<Id> contentDocIds = new Set<Id>();

    for (ContentDocumentLink link : newLinks) {
        if (link.LinkedEntityId != null &&
            link.LinkedEntityId.getSObjectType() == Case.SObjectType) {

            caseIds.add(link.LinkedEntityId);
            contentDocIds.add(link.ContentDocumentId);
        }
    }

    if (caseIds.isEmpty() || contentDocIds.isEmpty()) {
        return;
    }

    // Get latest ContentVersion
    Map<Id, ContentVersion> latestVersions = new Map<Id, ContentVersion>();

    for (ContentVersion ver : ContentService.getInstance().getContentVersionsByCDIds(contentDocIds)) {
        latestVersions.put(ver.ContentDocumentId, ver);
    }

    if (latestVersions.isEmpty()) {
        return;
    }

    // Get Signed KYC placeholder
    Map<Id, Id> signedKycDocMap = new Map<Id, Id>();

    for (Document__c doc : [
        SELECT Id,
               Case__c,
               Document_Name__c,
               DocumentType__r.Type__c
        FROM Document__c
        WHERE Case__c IN :caseIds
        AND DocumentType__r.Type__c = 'Signed KYC'
    ]) {
        signedKycDocMap.put(doc.Case__c, doc.Id);
    }

    if (signedKycDocMap.isEmpty()) {
        return;
    }

    // Existing links to Document__c (avoid duplicates)
    Set<String> existingLinks = new Set<String>();

    for (ContentDocumentLink cdl : [
        SELECT LinkedEntityId,
               ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :signedKycDocMap.values()
    ]) {
        existingLinks.add(cdl.LinkedEntityId + '-' + cdl.ContentDocumentId);
    }

    List<ContentDocumentLink> newLinksToInsert = new List<ContentDocumentLink>();

    for (ContentDocumentLink link : newLinks) {

        ContentVersion ver = latestVersions.get(link.ContentDocumentId);

        if (ver == null || String.isBlank(ver.Title)) {
            continue;
        }

        String title = ver.Title;

        // Ignore Certificate of Completion
        if (title.contains('CertificateOfCompletion')) {
            continue;
        }

        // Match the signed Client Information Sheet
        if (title.startsWith('CIS -')) {

            Id documentId = signedKycDocMap.get(link.LinkedEntityId);

            if (documentId != null) {

                String key = documentId + '-' + link.ContentDocumentId;

                if (!existingLinks.contains(key)) {

                    newLinksToInsert.add(
                        new ContentDocumentLink(
                            ContentDocumentId = link.ContentDocumentId,
                            LinkedEntityId    = documentId,
                            ShareType         = 'V',
                            Visibility        = 'AllUsers'
                        )
                    );

                    existingLinks.add(key);
                }
            }
        }
    }

    if (!newLinksToInsert.isEmpty()) {
        ContentService.getInstance().insertContentDocumentLink(newLinksToInsert);
    }
} 
}
/*
* @Author : Akshay Khairnar
* @CreatedDate : 26th October 2025
* @Description : Copying Document
*/
/*****************************************************************************************************/

public class BAPPCopyDocumentsJob implements Queueable, Database.AllowsCallouts {

    private Map<Id, Id> caseToAccountMap; 
    private Map<Id, Id> caseToContactMap; 
    private String jobType; // 'Account' or 'Contact'
    
    public BAPPCopyDocumentsJob(Map<Id, Id> EntityMap, String type) {
        if (type == 'Account') {
            this.caseToAccountMap = EntityMap;
        } else if (type == 'Contact') {
            this.caseToContactMap = EntityMap;
        }
        this.jobType = type;
    }

    // Execute
    public void execute(QueueableContext qc) {
        
        if (jobType == 'Account' && caseToAccountMap != null && !caseToAccountMap.isEmpty()) {
            copyDocumentsFromCases(caseToAccountMap, 'Account');
        } else if (jobType == 'Contact' && caseToContactMap != null && !caseToContactMap.isEmpty()) {
            copyDocumentsFromCases(caseToContactMap, 'Contact');
        }
        
    }
    
    // ACCOUNT OR CONTACT COPY
    private static void copyDocumentsFromCases(Map<Id, Id> caseToTargetMap, String targetType) {

    if (caseToTargetMap == null || caseToTargetMap.isEmpty()) return;

    Set<Id> caseIds = caseToTargetMap.keySet();
    Set<Id> targetIds = new Set<Id>(caseToTargetMap.values());

    // Query Case Documents
    DocumentService objDocumentService = DocumentService.getInstance();
    List<Document__c> caseDocs = objDocumentService.getDocumentsByCaseIds(caseIds);

    Map<String, Document__c> caseDocMap = new Map<String, Document__c>();
    Set<Id> versionIds = new Set<Id>();
    for (Document__c doc : caseDocs) {
        if (doc.Case__c != null && doc.Document_Name__c != null) {
            caseDocMap.put(doc.Case__c + '##' + doc.Document_Name__c, doc);
            if (doc.Content_Version_Id__c != null) versionIds.add(doc.Content_Version_Id__c);
        }
    }

    if (caseDocMap.isEmpty()) {
        return;
    }

    // Fetch ContentVersions
    Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([SELECT Id, Title, VersionData FROM ContentVersion WHERE Id IN :versionIds]);

    // Fetch existing Documents for all target records (Account or Contact)
    String targetField = (targetType == 'Account') ? 'Account__c' : 'Contact__c';  
    List<Document__c> targetDocs = objDocumentService.getDocumentsByObjectIds(targetIds, targetField);

    List<ContentVersion> newVersions = new List<ContentVersion>();
    List<Document__c> docsToUpdate = new List<Document__c>();
    Map<Id, Document__c> tempDocLinkMap = new Map<Id, Document__c>();
    Integer copyCount = 0;

    // Step 4: Process each Case → Target pair
    for (Id caseId : caseToTargetMap.keySet()) {
        Id targetId = caseToTargetMap.get(caseId);
        if (targetId == null) continue;

        for (Document__c tgtDoc : targetDocs) {
            Id currentTarget = (targetType == 'Account') ? tgtDoc.Account__c : tgtDoc.Contact__c;
            if (currentTarget != targetId) continue;

            String key = caseId + '##' + tgtDoc.Document_Name__c;
            if (!caseDocMap.containsKey(key)) continue;

            Document__c caseDoc = caseDocMap.get(key);
            ContentVersion caseVersion = versionMap.get(caseDoc.Content_Version_Id__c);
            if (caseVersion == null) continue;

            // Create new ContentVersion
            ContentVersion newVersion = new ContentVersion();
            newVersion.Title = caseVersion.Title;
            newVersion.PathOnClient = tgtDoc.Id + '##' + caseVersion.Title + '.pdf';
            newVersion.VersionData = caseVersion.VersionData;
            newVersion.FirstPublishLocationId = targetId;
            newVersions.add(newVersion);

            // Update target Document fields
            tgtDoc.FileName__c = caseDoc.FileName__c;
            tgtDoc.FileSizeMB__c = caseDoc.FileSizeMB__c;
            tgtDoc.FileType__c = caseDoc.FileType__c;
            docsToUpdate.add(tgtDoc);
            tempDocLinkMap.put(tgtDoc.Id, tgtDoc);
            copyCount++;

            if (newVersions.size() >= 40) {
                insertChunk(newVersions, tempDocLinkMap, docsToUpdate);
            }
        }
    }
        
        insertChunk(newVersions, tempDocLinkMap, docsToUpdate);
    }

    private static void insertChunk(List<ContentVersion> newVersions,Map<Id, Document__c> tempDocLinkMap, List<Document__c> docsToUpdate) {
        if (newVersions.isEmpty()) return;

        try {
            insert newVersions;
            Set<Id> newVersionIds = new Map<Id, ContentVersion>(newVersions).keySet();

            Map<Id, ContentVersion> insertedVersions = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId, PathOnClient FROM ContentVersion WHERE Id IN :newVersionIds]
            );

            for (ContentVersion cv : insertedVersions.values()) {
                String[] parts = cv.PathOnClient.split('##');
                if (parts.size() > 1) {
                    Id docId = (Id) parts[0];
                    Document__c relatedDoc = tempDocLinkMap.get(docId);
                    if (relatedDoc != null) {
                        relatedDoc.ContentDocumentId__c = cv.ContentDocumentId;
                        relatedDoc.Content_Version_Id__c = cv.Id;
                    }
                }
            }

            if (!docsToUpdate.isEmpty()) {
                try {
                    Map<Id, Document__c> uniqueMap = new Map<Id, Document__c>();
                    for (Document__c d : docsToUpdate)
                        if (d.Id != null) uniqueMap.put(d.Id, d);
                            update uniqueMap.values();
                } catch (DmlException e) {
                    System.debug('InsertChunk Failed to update Document__c: ' + e.getMessage());
                }
            }

        } catch (Exception e) {
            System.debug('InsertChunk Failed chunk insert: ' + e.getMessage());
        } finally {
            newVersions.clear();
            tempDocLinkMap.clear();
            docsToUpdate.clear();
        }
    }
}
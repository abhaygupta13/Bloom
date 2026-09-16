/*
* @Author : Raza Chandankeri
* @CreatedDate : 11th JUN 2025
* @Description : BrokerApplicantTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Raza        11JUN2025        Initial draft 
*****************************************************************************************************/
public class BrokerApplicantTriggerHelper {
    
    /**
* Create Document__c records for applicants that are missing them
*/
    public static void createDocuments(List<BrokerApplicant__c> applicantList) {
        if (applicantList.isEmpty()) return;
        
        DocumentService objDocumentService = DocumentService.getInstance();
        
        // Get all document types for Broker Applicant
        List<DocumentType__c> allDocTypes = objDocumentService.getDocTypes('Broker Applicant');
        
        // Fetch existing documents for these applicants to avoid duplicates
        Set<Id> applicantIds = new Set<Id>();
        for (BrokerApplicant__c ba : applicantList) {
            applicantIds.add(ba.Id);
        }
        
        // First fetch the flat list of existing docs
        List<Document__c> existingDocs = objDocumentService.getBappDocuments(applicantIds);
        
        // Group them into a Map<BrokerApplicantId, List<Document__c>>
        Map<Id, List<Document__c>> existingDocsMap = new Map<Id, List<Document__c>>();
        for (Document__c doc : existingDocs) {
            if (doc.BrokerApplicant__c != null) {
                if (!existingDocsMap.containsKey(doc.BrokerApplicant__c)) {
                    existingDocsMap.put(doc.BrokerApplicant__c, new List<Document__c>());
                }
                existingDocsMap.get(doc.BrokerApplicant__c).add(doc);
            }
        }
        
        List<Document__c> documentsToInsert = new List<Document__c>();
        
        for (BrokerApplicant__c ba : applicantList) {
            if (!String.isBlank(ba.BrokerContactRole__c)) {
                Set<String> applicantRoles = new Set<String>();
                for (String role : ba.BrokerContactRole__c.split(';')) {
                    applicantRoles.add(role.trim());
                }
                
                // Get existing doc type Ids for this applicant
                Set<Id> existingDocTypeIds = new Set<Id>();
                if (existingDocsMap.containsKey(ba.Id)) {
                    for (Document__c existingDoc : existingDocsMap.get(ba.Id)) {
                        existingDocTypeIds.add(existingDoc.DocumentType__c);
                    }
                }
                
                for (DocumentType__c dt : allDocTypes) {
                    if (String.isBlank(dt.BrokerContactRole__c)) {
                        continue; // skip doc types without roles
                    }
                    
                    Set<String> docRoles = new Set<String>();
                    for (String role : dt.BrokerContactRole__c.split(';')) {
                        docRoles.add(role.trim());
                    }
                    
                    Set<String> intersection = new Set<String>(applicantRoles);
                    intersection.retainAll(docRoles);
                    
                    if (!intersection.isEmpty() && !existingDocTypeIds.contains(dt.Id)) {
                        if (!intersection.isEmpty() &&
                            dt.TypeofEstablishment__c == ba.TypeofEstablishment__c) {
                                documentsToInsert.add(new Document__c(
                                    BrokerApplicant__c = ba.Id,
                                    DocumentType__c = dt.Id,
                                    Document_Name__c = dt.Type__c
                                ));
                            }
                    }
                }
            }
        }
        
        if (!documentsToInsert.isEmpty()) {
            objDocumentService.insertDocuments(documentsToInsert);
        }
    }
    
    /**
* Handle updates to BrokerApplicant__c records
*/
    public static void updateDocument(
        List<sObject> newList, Map<Id, sObject> newMap,
        List<sObject> oldList, Map<Id, sObject> oldMap
    ) {
        List<BrokerApplicant__c> updatedApplicants = new List<BrokerApplicant__c>();
        
        for (BrokerApplicant__c newRec : (List<BrokerApplicant__c>) newList) {
            BrokerApplicant__c oldRec = (BrokerApplicant__c) oldMap.get(newRec.Id);
            
            String newRole = String.isBlank(newRec.BrokerContactRole__c) ? '' : newRec.BrokerContactRole__c.trim();
            String oldRole = String.isBlank(oldRec.BrokerContactRole__c) ? '' : oldRec.BrokerContactRole__c.trim();
            
            if (newRole != oldRole) {
                updatedApplicants.add(newRec);
            }
        }
        
        if (!updatedApplicants.isEmpty()) {
            createDocuments(updatedApplicants);
        }
    }
}
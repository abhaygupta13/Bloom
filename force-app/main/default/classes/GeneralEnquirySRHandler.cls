/*****************************************************************************************
Class       : GeneralEnquirySRHandler
Author      :  Jhilik
Description : 
test Class  : GeneralEnquirySRHandlerTest
Created Date: 29-Sept-2025
*****************************************************************************************/
public inherited sharing class GeneralEnquirySRHandler {
    
    private static GeneralEnquirySRHandler instance;
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    List<String> requiredDocTypesFP = new List<String>{'Floor Plan'};
        List<String> requiredDocTypesSPA = new List<String>{'SPA Pre Registration'};
            List<String> requiredDocTypesCD = new List<String>{'Buyer Emirates ID','Passport'};
                List<String> requiredDocTypesTD = new List<String>{'Title Deed'};
                    List<String> requiredDocTypesRDR = new List<String>{'Title Deed','IBAN Letter','Buyer Emirates ID','Passport','Debit Advice'};
                        List<String> requiredDocTypesRR = new List<String>{'Title Deed','IBAN Letter','Debit Advice'};
                                List<String> requiredDocTypesKYC = new List<String>{'Signed KYC'};
                                     List<String> requiredDocTypesSuqur = new List<String>{'Suqur Al Watan Employee Document'};
                            
                            public GeneralEnquirySRHandler() {
                            }
    
    public static GeneralEnquirySRHandler getInstance() { 
        if(instance == null) {
            instance = new GeneralEnquirySRHandler();
        }
        return instance;
    }
    
    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }
    
    public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        return message;
    }
    
    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, Id accountId, Id unitId, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.SubType__c = sc.SubCategory__c;    
        newCase.Status = 'New';
        
        Map<String, String> subTypeToSubject = new Map<String, String>{
            'General Payment Enquiry' => 'General Payment Enquiry',
                'Floor Plan Copy' => 'Floor Plan Copy',
                'Contact Details' => 'Contact Details',
                'SPA Pre-Registration' => 'SPA Pre-Registration',
                'Title Deed/Mortgage Deed' => 'Title Deed/Mortgage Deed',
                'Rent Security Deposit Refund' => 'Rent Security Deposit Refund',
                'Rent Refund' => 'Rent Refund',
                'Customer Type Update' => 'Customer Type Update'
                };
                    
                    String subjectPrefix = subTypeToSubject.containsKey(newCase.SubType__c) ? subTypeToSubject.get(newCase.SubType__c)  : 'General Enquiry';
        
        if (salesOrderObj != null ) {
            newCase.Subject = subjectPrefix + ' - ' + salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }       
        else if(salesOrderObj == null){
            Datetime todaysDateTime = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day());
            String formattedinstallmentDate = todaysDateTime.format('dd-MM-yyyy');
            newCase.Subject = subjectPrefix + ' - ' + formattedinstallmentDate;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        newCase = CaseService.getInstance().insertCase(newCase);
        return newCase; 
    }
    
    public  Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        CaseService caseServiceObj = CaseService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Case has been updated successfully');
        
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        
        if(caseRecord.Step__c !='Final'){
            if(Integer.valueOf(caseRecord.Step__c) < 1){
                response.put('status', 'error');
                response.put('message', 'Invalid Case Step.');
                return response;
            }
        }
        
        if (caseRecord.Step__c == 'Final' && caseRecord.isNotRegistered__c == false) {
            
            List<Document__c> allDocs = DocumentService.getInstance().getDocumentsByCaseIds(
                new Set<Id>{ caseRecord.Id }
            );
            
            Map<String, Document__c> docMap = new Map<String, Document__c>();
            
            for (Document__c doc : allDocs) {
                if (doc.Document_Name__c != null) {
                    docMap.put(doc.Document_Name__c.trim().toLowerCase(), doc);
                }
            }
            
            List<String> requiredDocs;
            
            if (caseRecord.SubType__c == 'Rent Security Deposit Refund' || caseRecord.SubType__c == 'Rent Refund') {
                
                requiredDocs = new List<String>{ 'Debit Advice' };
                    
                    } else {
                        
                        requiredDocs = new List<String>();
                        
                        for (Document__c d : allDocs) {
                            if (d.Document_Name__c != null) {
                                requiredDocs.add(d.Document_Name__c);
                            }
                        }
                    }
            
            for (String req : requiredDocs) {
                
                Document__c doc = docMap.get(req.trim().toLowerCase());
                
                if (doc == null || doc.ContentDocumentId__c == null) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload all required documents before closing the case.');
                    return response;
                }
            }
        }
        
        if(caseRecord.IsDocumentAvailable__c == true || caseRecord.isNotRegistered__c == true){
            processDocumentRequest(caseRecord);
            return response;
        }
        
        if(response.get('status') == 'success'){
            handleNextSteps(caseRecord); 
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        return response;
    }
    
    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }
    
    public void processDocumentRequest(Case caseRec){
        if(caseRec.isNotRegistered__c == false){
            List<Document__c> allDocs = DocumentService.getInstance().getDocumentsByCaseIds(new Set<Id>{caseRec.Id});   
            
            for(Document__c doc : allDocs){
                if(doc.ContentDocumentId__c == null){
                    AuraHandledException ex = new AuraHandledException('');
                    ex.setMessage('Please upload all required documents before closing the case.');
                    throw ex;
                }
            }
        }
        caseRec.Step__c = 'Final';
        ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }
    
    public void createDocumentPlaceholder(List<Case> caseList) {
        
        if (caseList == null || caseList.isEmpty()) return;
        
        DocumentService docService = DocumentService.getInstance();
        
        Map<String, List<String>> subTypeToDocs = new Map<String, List<String>>{
            'Floor Plan Copy' => requiredDocTypesFP,
                'SPA Pre-Registration' => requiredDocTypesSPA,
                'Title Deed/Mortgage Deed' => requiredDocTypesTD,
                'Rent Security Deposit Refund' => requiredDocTypesRDR,
                'Rent Refund' => requiredDocTypesRR,
                'Contact Details' => requiredDocTypesCD,
                'KYC Update Request' => requiredDocTypesKYC,
                'Customer Type Update' => requiredDocTypesSuqur
                };
                    
                    Map<Id, List<String>> caseToDocNames = new Map<Id, List<String>>();
        Set<String> allDocNames = new Set<String>();
        
        for (Case c : caseList) {
            if (subTypeToDocs.containsKey(c.SubType__c)) {
                List<String> docNames = subTypeToDocs.get(c.SubType__c);
                caseToDocNames.put(c.Id, docNames);
                allDocNames.addAll(docNames);
            }
        }
        
        if (allDocNames.isEmpty()) return;
        
        List<DocumentType__c> docTypes = docService.getDocTypesByTypeNames('Case', new List<String>(allDocNames));
        
        Map<String, Id> docNameToId = new Map<String, Id>();
        for (DocumentType__c dt : docTypes) {
            docNameToId.put(dt.Type__c, dt.Id);
        }
        
        List<Document__c> docsToInsert = new List<Document__c>();
        
        for (Case c : caseList) {
            
            if (!caseToDocNames.containsKey(c.Id)) continue;
            
            for (String docName : caseToDocNames.get(c.Id)) {
                docsToInsert.add(new Document__c(
                    Case__c = c.Id,
                    DocumentType__c = docNameToId.get(docName),
                    Document_Name__c = docName
                ));
            }
        }
        
        if (!docsToInsert.isEmpty()) {
            docService.insertDocuments(docsToInsert);
        }
        autoPopulateFloorPlanFromUnitFiles(caseList);  
        salesOrderDocumentsToCase(caseList);
    }
    
    public void salesOrderDocumentsToCase(List<Case> caseList) {
        
        Map<Id, Id> caseToSO = new Map<Id, Id>();
        Set<Id> soIds = new Set<Id>();
        
        for (Case c : caseList) {
            if (c.Sales_Order__c != null) {
                caseToSO.put(c.Id, c.Sales_Order__c);
                soIds.add(c.Sales_Order__c);
            }
        }
        
        if (soIds.isEmpty()) return;
        
        DocumentService docService = DocumentService.getInstance();
        
        Map<Id, List<Document__c>> soDocsMap = new Map<Id, List<Document__c>>();
        for (Id soId : soIds) {
            soDocsMap.put(soId, docService.getSalesOrderDocuments(soId));
        }
        
        List<Document__c> caseDocs =
            docService.getDocumentsByCaseIds(caseToSO.keySet());
        
        Map<String, Document__c> caseDocMap = new Map<String, Document__c>();
        
        for (Document__c d : caseDocs) {
            if (d.Case__c != null && d.Document_Name__c != null) {
                caseDocMap.put(
                    d.Case__c + '_' + d.Document_Name__c.toLowerCase().trim(),
                    d
                );
            }
        }
        
        Map<Id, Document__c> docsToUpdateMap = new Map<Id, Document__c>();
        
        for (Case c : caseList) {
            
            Id soId = caseToSO.get(c.Id);
            if (soId == null) continue;
            
            List<Document__c> soDocs = soDocsMap.get(soId);
            if (soDocs == null) continue;
            
            Boolean isSPA = (c.SubType__c == 'SPA Pre-Registration');
            
            for (Document__c soDoc : soDocs) {
                
                String docName = soDoc.Document_Name__c;
                if (String.isBlank(docName)) continue;
                
                String normalizedName = docName.toLowerCase().trim();
                
                // SPA logic
                if (isSPA) {
                    if (normalizedName != 'unit registration') continue;
                    docName = 'SPA Pre Registration';
                }
                
                Id contentDocId = soDoc.ContentDocumentId__c;
                if (contentDocId == null) continue;
                
                String key = c.Id + '_' + docName.toLowerCase().trim();
                Document__c target = caseDocMap.get(key);
                
                if (target == null) continue;
                
                docService.insertContentDocumentLink(contentDocId, target.Id);
                
                target.ContentDocumentId__c = contentDocId;
                docsToUpdateMap.put(target.Id, target);
            }
        }
        
        if (!docsToUpdateMap.isEmpty()) {
            docService.updateDocuments(docsToUpdateMap.values());
        }
    }
    
    public void autoPopulateFloorPlanFromUnitFiles(List<Case> caseList) {
        
        if (caseList == null || caseList.isEmpty()) return;
        
        List<Case> filtered = new List<Case>();
        Set<Id> unitIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        UnitService unitObj = UnitService.getInstance();
        
        for (Case c : caseList) {
            if (c.SubType__c == 'Floor Plan Copy' && c.Unit__c != null) {
                filtered.add(c);
                unitIds.add(c.Unit__c);
                caseIds.add(c.Id);
            }
        }
        
        if (filtered.isEmpty()) return;
        
        
        Map<Id, Unit__c> unitMap = unitObj.getUnitsWithFloorPlan(unitIds);
        
        
        DocumentService docService = DocumentService.getInstance();
        Map<Id, Document__c> caseToDoc = new Map<Id, Document__c>();
        
        for (Document__c d : docService.getDocumentsByCaseIds(caseIds)) {
            if (d.Document_Name__c == 'Floor Plan') {
                caseToDoc.put(d.Case__c, d);
            }
        }
        
        Set<Id> docIds = new Set<Id>();
        for (Document__c d : caseToDoc.values()) {
            if (d.Id != null) {
                docIds.add(d.Id);
            }
        }
        
        Map<Id, Set<Id>> existingLinks = new Map<Id, Set<Id>>();
        
        if (!docIds.isEmpty()) {
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :docIds
            ]) {
                if (!existingLinks.containsKey(cdl.LinkedEntityId)) {
                    existingLinks.put(cdl.LinkedEntityId, new Set<Id>());
                }
                existingLinks.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            }
        }
        
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        List<Document__c> docsToUpdate = new List<Document__c>();
        
        
        for (Case c : filtered) {
            
            Unit__c unitRec = unitMap.get(c.Unit__c);
            Document__c caseDoc = caseToDoc.get(c.Id);
            
            if (unitRec == null || caseDoc == null || caseDoc.Id == null) {
                continue;
            }
            
            String docIdStr = unitRec.WebFloorPlanCDId__c;
            
            
            if (String.isBlank(docIdStr) || !docIdStr.startsWith('069')) {
                continue;
            }
            
            Id contentDocId = (Id) docIdStr;
            
            List<ContentDocument> cds = [
                SELECT Id FROM ContentDocument WHERE Id = :contentDocId LIMIT 1
            ];
            
            if (cds.isEmpty()) {
                continue;
            }
            
            
            if (existingLinks.containsKey(caseDoc.Id) &&
                existingLinks.get(caseDoc.Id).contains(contentDocId)) {
                    continue;
                }
            
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocId;
            cdl.LinkedEntityId = caseDoc.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            
            linksToInsert.add(cdl);
            
            
            caseDoc.ContentDocumentId__c = contentDocId;
            docsToUpdate.add(caseDoc);
        }
        
        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
        
        if (!docsToUpdate.isEmpty()) {
            update docsToUpdate;
        }
    }
      public void syncCaseDocumentsToAccount(List<Case> caseList) {
        
        Map<Id, Id> caseToAccount = new Map<Id, Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        
        for (Case c : caseList) {
            if (c.SubType__c == 'Customer Type Update' &&c.AccountId != null) {
                caseToAccount.put(c.Id, c.AccountId);
                caseIds.add(c.Id);
                accountIds.add(c.AccountId);
            }
        }
        
        
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> caseDocs = docService.getDocumentsByCaseIds(caseIds);
        
        List<Document__c> accountDocs = docService.getDocumentsByAccountIds(accountIds);
        
        Map<String, Document__c> accountDocMap = new Map<String, Document__c>();
        
        for (Document__c accDoc : accountDocs) {
            if (String.isNotBlank(accDoc.Document_Name__c)) {
                accountDocMap.put(
                    accDoc.Account__c + '_' +
                    accDoc.Document_Name__c.toLowerCase().trim(),
                    accDoc
                );
            }
        }
        
        Map<Id, Document__c> docsToUpdate = new Map<Id, Document__c>();
        
        for (Document__c caseDoc : caseDocs) {
            if (caseDoc.ContentDocumentId__c == null ||
                String.isBlank(caseDoc.Document_Name__c)) {
                    continue;
                }
            
            Id accountId = caseToAccount.get(caseDoc.Case__c);
            String key = accountId + '_' + caseDoc.Document_Name__c.toLowerCase().trim();
            Document__c accountDoc = accountDocMap.get(key);
            docService.insertContentDocumentLink(caseDoc.ContentDocumentId__c,accountDoc.Id);
            accountDoc.ContentDocumentId__c =caseDoc.ContentDocumentId__c;
            docsToUpdate.put(accountDoc.Id, accountDoc);
        }
        
        docService.updateDocuments(docsToUpdate.values());
    }
}
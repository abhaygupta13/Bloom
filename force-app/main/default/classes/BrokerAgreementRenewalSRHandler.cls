public class BrokerAgreementRenewalSRHandler{
    private static final String Broker_Agreement_Renewal_RT {get { return 'BrokerAgreementRenewal'; }}
    private static final String Broker_Agreement_Renewal_Sub_Category {get { return 'Broker Agreement Renewal'; }}
    private static final List<String> caseDocumentList = new List<String>{'Broker Agreement - Signed'};
        private static final List<String> accountDocumentList = new List<String>{'Broker Agreement'};
            
            private static BrokerAgreementRenewalSRHandler instance;
    private BrokerAgreementRenewalSRHandler() {
        
    }
    
    public static BrokerAgreementRenewalSRHandler getInstance() { 
        if(instance == null) {
            instance = new BrokerAgreementRenewalSRHandler();
        }
        return instance;
    }
    
    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }
    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases); 
    }
    public Map<String,Object> validateCaseForNextReview(Case caseRecord) {
        
        Map<String,Object> response = new Map<String,Object>();
        
        if(caseRecord == null){
            response.put('status','error');
            response.put('message','Invalid Case record.');
            return response;
        }
        
        if(caseRecord.Status == 'Closed'){
            response.put('status','error');
            response.put('message','Cannot proceed. Case is already Closed.');
            return response;
        }
        
        if(caseRecord.ServiceCatalog__c == null){
            response.put('status','error');
            response.put('message','Service Catalog is missing.');
            return response;
        }
        
        if(caseRecord.Step__c == null){
            response.put('status','error');
            response.put('message','Step value is missing.');
            return response;
        }
        
        Case latestCase = CaseService.getInstance().getCaseById(caseRecord.Id);
        
        if(latestCase.ApprovalStatus__c == 'Pending' || latestCase.ApprovalStatus__c == 'Not Approved') {
            latestCase.ApprovalStatus__c = 'Approved';
            latestCase.Status = 'Closed';
        }
        
        CaseService.getInstance().updateCases(new List<Case>{ latestCase });
        
        response.put('status','success');
        response.put('message','Validation successful. Processing next step.');
        
        handleNextSteps(caseRecord);
        
        return response;
    }
    
    public static void generateBrokerAgreement(List<Case> cases) {
        
        if (cases == null || cases.isEmpty()) {
            return;
        }
        
        List<DocumentType__c> docGenSetups = [SELECT Id,DeliveryOption__c,DocGenPackage__c,ObjectType__c,Active__c,Type__c, Project__r.Name,
                                              Project__c, ProcessType__c,Customer_Type__c,Docusign_Envelope_Docusign_Id__c,Docusign_Envelope_Template__c,
                                              Docusign_Envelope_Template__r.dfsle__DocuSignId__c,Document_Digital_Name__c,Document_Output_Name__c,Docusign_Envelope__c
                                              FROM DocumentType__c WHERE Active__c = true AND DigitalSignature__c = true AND ObjectType__c = 'Case'LIMIT 1];
        
        DocumentType__c docGenSetup = docGenSetups[0];
        
        Set<Id> caseIds = new Set<Id>();
        
        for (Case cs : cases) {
            caseIds.add(cs.Id);
        }
        
        Map<Id, Document__c> caseDocumentMap = new Map<Id, Document__c>();
        
        for (Document__c doc : [SELECT Id,Case__c, Document_Name__c FROM Document__c WHERE Case__c IN :caseIds
                                AND Document_Name__c = :docGenSetup.Type__c]) {
                                    caseDocumentMap.put(doc.Case__c, doc);
                                }
        
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case cs : cases) {
            
            if (!caseDocumentMap.containsKey(cs.Id)) {
                continue;
            }
            
            Document__c doc = caseDocumentMap.get(cs.Id);
            
            String drawloopNextVal =
                'SFCase:' + cs.Id +
                ';SFDocument__c:' + doc.Id +
                ';DDPId:' + docGenSetup.DocGenPackage__c +
                ';Deploy:' + docGenSetup.DeliveryOption__c;
            
            casesToUpdate.add(new Case(Id = cs.Id,Drawloop_Next_1__c = drawloopNextVal));
        }
        
        if (!casesToUpdate.isEmpty()) {
            CaseService.getInstance().updateCaseWithoutTrigger(casesToUpdate);
            system.debug('casesToUpdate-->'+casesToUpdate);
        }
    }
    
    public static void createChildCases(List<Case> parentCases){
        system.debug('parentCases-->'+parentCases);
        Id brokerAgreementRenewalRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, Broker_Agreement_Renewal_RT);
        ServiceCatalog__c sc = ServiceCatalogService.getInstance().getBySubCategory(Broker_Agreement_Renewal_RT, Broker_Agreement_Renewal_Sub_Category);
        List<Case> caseToInsert = new List<Case>();
        for (Case cs : parentCases) {
            if (cs.PostApprovalAction__c == 'Generate Renewal Agreement'&&
                (cs.SubType__c == 'Bank Details Update' || cs.SubType__c == 'VAT Details Update' || cs.SubType__c == 'Legal Documents Update' ||
                    cs.SubType__c == 'Trade License Expiry Update')){
                    Case newCase = new Case();
                    newCase.AccountId = cs.AccountId;
                    newCase.RecordTypeId = brokerAgreementRenewalRecordTypeId;
                    newCase.Status = 'New';
                    newCase.Draft__c = true;
                    newCase.ParentId = cs.Id;
                    newCase.Type = cs.Type;
                    newCase.ServiceCatalog__c   = sc.Id;
                    newCase.ApprovalStatus__c = 'Not Approved';
                    newCase.Subject = 'Broker Agreement Renewal';
                    newCase.Origin = 'System Generated';
                    caseToInsert.add(newCase);
                }
            //if (cs.SubType__c == 'Agency Name Update' || cs.SubType__c == 'Agency Type Update'){
            if (cs.SubType__c == 'Agency Name or Type Update' || cs.SubType__c == 'Broker Agreement Renewal Complete Details Update'){   
                Case newCase = new Case();
                newCase.AccountId = cs.AccountId;
                newCase.RecordTypeId = brokerAgreementRenewalRecordTypeId;
                newCase.Status = 'New';
                newCase.Draft__c = true;
                newCase.ParentId = cs.Id;
                newCase.Type = cs.Type;
                newCase.ServiceCatalog__c   = sc.Id;
                newCase.ApprovalStatus__c = 'Not Approved';
                newCase.Subject = 'Broker Agreement Renewal';
                newCase.Origin = 'System Generated';
                caseToInsert.add(newCase);
            }
        }
        
        If(!caseToInsert.isEmpty()){
            CaseService.getInstance().insertCaseWithTrigger(caseToInsert);
        }
    }
    
    public static void moveSignedAgreementdToAccount(List<Case> cases){
        DocumentService docService = DocumentService.getInstance();
        AccountService accountService = AccountService.getInstance();
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> caseDocIds = new Set<Id>();
        for(Case cs : cases){
            caseIds.add(cs.Id);
            accountIds.add(cs.AccountId);
        }
        //Update AgreementExpiryDate__c when case approved
        for(Account acc : AccountService.getAccountByIds(accountIds)){
            if (acc.AgreementExpiryDate__c != null) {
                acc.AgreementExpiryDate__c = acc.AgreementExpiryDate__c.addYears(1);
            } else {
                acc.AgreementExpiryDate__c = Date.today().addYears(1);
            }
            accountsToUpdate.add(acc);
        }
        
        List<Document__c> caseDocs = docService.getCaseSignDocuments(caseIds, caseDocumentList);
        List<Document__c> accountDocs = docService.getAccountsDocuments(accountIds, accountDocumentList);
        
        Map<Id, Document__c> caseDocByCaseId = new Map<Id, Document__c>();
        Map<Id, Document__c> accountDocByAccountId = new Map<Id, Document__c>();
        
        for (Document__c doc : caseDocs) {
            caseDocByCaseId.put(doc.Case__c, doc);
            caseDocIds.add(doc.Id);
        }
        
        for (Document__c doc : accountDocs) {
            accountDocByAccountId.put(doc.Account__c, doc);
        }
        
        List<ContentDocumentLink> caseLinks = ContentDocumentLinkService.getInstance().getExistingCasesLinks(caseDocIds);
        
        system.debug('accountDocByAccountId-->'+accountDocByAccountId);
        Map<Id, Id> contentDocByCaseDocId = new Map<Id, Id>();
        for (ContentDocumentLink cdl : caseLinks) {
            contentDocByCaseDocId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
        }
        
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        
        for (Case cs : cases) {
            
            Document__c caseDoc = caseDocByCaseId.get(cs.Id);
            Document__c accountDoc = accountDocByAccountId.get(cs.AccountId);

            Id contentDocumentId = contentDocByCaseDocId.get(caseDoc.Id);
            if(contentDocumentId!=null && accountDoc!=null){
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = contentDocumentId,
                    LinkedEntityId    = accountDoc.Id,
                    ShareType         = 'V',
                    Visibility        = 'AllUsers'
                ));
            }
        }
        
        if (!linksToInsert.isEmpty()) {
            ContentService.getInstance().insertContentDocumentLink(linksToInsert);
        }
        if (!accountsToUpdate.isEmpty()) {
            AccountService.updateAccountsWithoutTrigger(accountsToUpdate);
        }
        
    }
    
    public static Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, String selectedType, String description, String origin, String typeOfEstablishment) {
        
        Case newCase;
        try {
            If (newCase == null){
                newCase = new Case();
                newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
                newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
                newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
                newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
                newCase.Status = 'New';
                newCase.Draft__c = true;
                newCase.ApprovalStatus__c = 'Not Approved';
                newCase.Origin = origin;
                newCase.ServiceCatalog__c = sc.Id;
                newCase.CaseType__c = selectedType;
                newCase.Description = description;
                //newCase.SubType__c = sc.SubCategory__c;
                newCase.Type = sc.Category__c;
                newCase.Subject = 'Broker Agreement Renewal';
                newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id : null;
                newCase.TypeofEstablishment__c = typeOfEstablishment;
                
                
                List<Case> inserted = CaseService.getInstance().insertCaseWithTrigger(new List<Case>{ newCase });
                
                Case caseToUpdate = new Case(
                    Id = inserted[0].Id,
                    ApprovalStatus__c = 'Pending',
                    Draft__c = false
                );
                
                CaseService.getInstance().updateCase(caseToUpdate);
                
                newCase.Id = inserted[0].Id;
            }
        } catch (Exception e) {
            throw e;
        }
        return newCase; 
    }
}
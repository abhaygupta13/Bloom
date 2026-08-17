public with sharing class BrokerCommissionDocuSignHandler {
    
    // Fetch DocumentType__c records relevant for Broker Commission
    @AuraEnabled(cacheable=true)
    public static List<DocumentType__c> getCommissionDocumentTypes() {
        // filter DocumentType__c by Object__c = 'BrokerCommission__c'
        DocumentTypeService dtService = DocumentTypeService.getInstance();
        List<DocumentType__c> docTypeList = dtService.getDocumentTypeRecords('Broker Commission');
        return docTypeList;
    }
    
    @AuraEnabled
    public static void sendForCommissionSignature(Id commissionId, List<Id> documentTypeIds) {
        if (commissionId == null || documentTypeIds == null || documentTypeIds.isEmpty()) {
            throw new AuraHandledException('Commission Id and Document Types are required.');
        }
        // Fetch the Broker Commission record
        BrokerCommissionService bcService = BrokerCommissionService.getInstance();
        BrokerCommission__c commission = bcService.getBrokerCommissionById(commissionId);
        
        
        if (commission.Agency__c == null) {
            throw new AuraHandledException('Broker Commission has no Agency set.');
        }
        String AgencyId = commission.Agency__c;
        ContactService conService = ContactService.getInstance();
        List<Contact> contacts = conService.getBrokerAuthSignContactsByAccount(AgencyId);
        // Fetch signer contact (Authorized Signatory Officer)
        
        if (contacts.isEmpty()) {
            throw new AuraHandledException('No Authorized Signatory Officer found for this Commission.');
        }
        Id signerContactId = contacts[0].Id;
        
        // Fetch selected document types
       
        DocumentTypeService dtSerivce  = DocumentTypeService.getInstance();
        List<DocumentType__c> documentTypeRecords = dtSerivce.getDocumentTypeByIds(documentTypeIds);
        
        // Build Map<Id, String> → maps DocumentType__c.Id to its Type__c
        Map<Id, String> documentTypeIdToNameMap = new Map<Id, String>();
        for (DocumentType__c dtRec : documentTypeRecords) {
            documentTypeIdToNameMap.put(dtRec.Id, dtRec.Type__c);
        }
        
        // Fetch already-generated docs for this Commission, filtered by names
        
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> documentsList = docService.getCommissionDocumentsByName(commission.Id, New List<String>(documentTypeIdToNameMap.values()));
        
        // Build a reverse map for quick lookup: Document_Name__c → Document__c.Id
        Map<String, Id> documentNameToDocId = new Map<String, Id>();
        for (Document__c docRec : documentsList) {
            documentNameToDocId.put(docRec.Document_Name__c, docRec.Id);
        }
        
        // Loop through each DocumentType__c and send for signature
        for (DocumentType__c dtRec : documentTypeRecords) {
            Id docId = documentNameToDocId.get(dtRec.Type__c);
            if (docId == null) {
                System.debug('⚠ No matching document found for type ' + dtRec.Type__c);
                continue;
            }
            
            String docusignTemplateId = dtRec.Docusign_Envelope_Template__r.dfsle__DocuSignId__c;
            String emailSubject       = 'Broker Commission Invoice for Your Signature';
            
            // Call sendBrokerCommissionEnvelope
            sendBrokerCommissionEnvelope(
                docusignTemplateId,              // DocuSign Template
                dtRec.Document_Digital_Name__c,  // Description
                docId,                           // Document record Id
                commission.Id,                   // Parent record Id
                dtRec.Document_Output_Name__c,   // Output name
                emailSubject                     // Email subject
            );
        }
    }
    
    public static List<dfsle.Recipient>  getRecipients(Id recordid, String documentoutputname) 
    {
        // Add Authorised Signatory Recipient for Broker Commission Invoice
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        String authSignatoryEmail = null;
        String authSignatoryName = null;
        
        BrokerCommissionService bcService = BrokerCommissionService.getInstance();
        BrokerCommission__c commission = bcService.getBrokerCommissionById(recordId);

        //List<BrokerCommission__c> brokerCommissionIdList = [SELECT SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c FROM BrokerCommission__c WHERE Id = :recordId];
        String AccountId = commission.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c;

        // Query Accounts related to the given BrokerCommission
        
        
        AccountService accService = AccountService.getInstance();
        List<Account> accList = accService.getRelatedContactForAccountId(AccountId);
        
        if (!accList.isEmpty()) {
            Account acc = accList[0];
            if (!acc.Contacts.isEmpty()) {
                Contact signer = acc.Contacts[0]; // take the first one if multiple
                authSignatoryEmail = signer.Email;
                authSignatoryName =signer.Name; 
            }
        }
        
        System.debug('Authorized Signatory Email ---> ' + authSignatoryEmail);
        System.debug('Authorized Signatory Name ---> ' + authSignatoryName);
        
        if (String.isBlank(authSignatoryEmail)) {
            throw new AuraHandledException('No valid Authorized Signatory email found.');
        }
        
        
        // Add Stamp Tab
        dfsle.SignHereTab.Stamp AuthStamp = new dfsle.SignHereTab.Stamp('stamp', null, null, null, null, null, null, null);
        dfsle.Tab myAuthStampTab = new dfsle.SignHereTab()
            .withStamp(AuthStamp)
            .withScale(1.5)
            .withRequired(true)
            .withAnchor(new dfsle.Tab.Anchor(
                'Company Stamp:',
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                190,
                0));
        
        dfsle.Tab bloomSignHereTab = new dfsle.SignHereTab()
            .withScale(1.25)
            .withRequired(true)
            .withAnchor(new dfsle.Tab.Anchor(
                'Signature:', // Anchor text in the PDF
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                160,
                0))
            .withPosition(new dfsle.Tab.Position(
                1,
                null,
                null,
                null,
                null,
                null));
        System.debug('bloomSignHereTab added');
        
        dfsle.Tab bloomDateSignedTab = new dfsle.DateSignedTab()
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSignedDate:',
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                0,
                0))
            .withPosition(new dfsle.Tab.Position(
                1,
                null,
                null,
                null,
                null,
                null));
        System.debug('bloomDateSignedTab added');
        
        // Create a TextTab 
        dfsle.Tab myTextTab = new dfsle.TextTab()
            .withReadOnly(false) // Make it editable for the recipient
            .withAnchor(new dfsle.Tab.Anchor(
                'Invoice Number:', // The text string in your document to anchor to
                true, // Anchor is case sensitive
                true, // Anchor is match whole word
                null,
                true, // Anchor is horizontal
                true, // Anchor is relative
                'pixels', // Unit for offsets
                100, // X offset (right)
                0 // Y offset (up)
            ))
            .withDataLabel('Invoice Number'); // Label for the text field
            
        
        // Create a Date Input Tab as TextTab (editable by signer)
        dfsle.Tab myDateInputTab = new dfsle.TextTab()
            .withReadOnly(false)   // signer can edit
            .withRequired(true)    // make it mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'Invoice Date:', // anchor text in the PDF
                false,  // case sensitive = false
                false,  // match whole word = false
                'right',
                true,
                true,
                'pixels',
                40,     // X offset
                -3       // Y offset
            ))
            .withDataLabel('SignerInputInvoiceDate'); // identifier in DocuSign
                    
        
        dfsle.Recipient authSignatory = dfsle.Recipient.fromSource(
            authSignatoryName,
            authSignatoryEmail,
            null,
            'Bloom Signatory:',
            null
        ).withTabs(new List<dfsle.Tab> {
            bloomSignHereTab,
                bloomDateSignedTab,
                myAuthStampTab,
                myTextTab,
                myDateInputTab
                }).withRoutingOrder(1); // Assuming second signer
        
        
        allrecipients.add(authSignatory);
        return allrecipients;
    }
    
    
    @future(callout=true)
    public static void sendBrokerCommissionEnvelope(String template, String description, Id recordId, Id bappId, String documentoutputname,String emailSubject) {
        if (String.isBlank(description)) {
            description = 'Generated Document';
        }
        
        documentoutputname = '%'+ documentoutputname + '%';
        
        
        dfsle.Notifications notifySigner = new dfsle.Notifications(
            true,
            2,
            1,
            true,
            999,
            10,
            false
        );
        
        // Prevent external callouts during tests
        if (Test.isRunningTest()) {
            System.debug('Skipping DocuSign envelope creation during test');
            return;
        }
        
        // Actual DocuSign logic
        dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(bappId)
        );
        system.debug('new envelope');
        
        dfsle.UUID myTemplateId = dfsle.UUID.parse(template); 
        dfsle.Document myDocument = dfsle.Document.fromTemplate(
            myTemplateId,
            description);
        
        
        ContentDocumentLink cdl = ContentDocumentLinkService.getLatestContentDocumentLinkByRecordAndName(recordId, documentoutputname);
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];
        myDocument = myDocument.withReplacement(dfsle.Document.fromFile(cv));
        
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        myEnvelope = myEnvelope.withEmail(emailSubject,'Sign In Document');
        myEnvelope = myEnvelope.withNotifications(notifySigner);
        
        List<dfsle.Recipient> allrecipients = getRecipients(bappId, documentoutputname); 
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        system.debug('add recipients to envelope');
        
        if (Test.isRunningTest()) {
            return; //  Skip the actual call during tests
        }
        
        myEnvelope = dfsle.EnvelopeService.sendEnvelope(
            myEnvelope,
            true
        );
        
    } 
    
    
    
}
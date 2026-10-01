/**
* @File Name : LeasingDocGenController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 3, 2025 |   | Initial Version
**/

public class LeasingDocGenController {
    private static final string LEASING_MANAGER_DOCSIGN_EMAIL { get { return 'LeasingManagerEmail'; } }
    private static final string LEASING_MANAGER_DOCSIGN_NAME { get { return 'LeasingManagerName'; } }
    private static final string BLOOM_CEO_DOCSIGN_NAME { get { return 'BloomCEOName'; } }
    private static final string BLOOM_CEO_DOCSIGN_EMAIL { get { return 'BloomCEOEmail'; } }
    private static final string LEASING_SIGNING_EMAIL_TEMPLATE_ID { get { return 'LeasingOrderInitiatedEmailTemplateId'; } }
    private static final string MTD_OWE_NO_REPLY_SALES_IT_ID { get { return 'NoReplySalesIT'; } }
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    
    
    @AuraEnabled
    public static void generateDocument(Id deliveryOptionId, Id templateId, Id recordId, String documentName) {
        
        try {
            // Validate input parameters
            if (deliveryOptionId == null || templateId == null || recordId == null || documentName == null) {
                throw new IllegalArgumentException('Required parameters cannot be null.');
            }
            
            if(recordId != null && recordId.getSObjectType() == LeasingOrder__c.SObjectType){
                LeasingOrderService leaseOrderService = LeasingOrderService.getInstance();
                Leasingorder__c lo = leaseOrderService.getLeasingOrderById(recordId);
                if(lo.MasterLeasingOrder__c != null && documentName != 'Leasing Exit Letter' && documentName != 'Move Out Request Form'){
                    DocumentType__c doctype = [Select Id, DeliveryOption__c, DocGenPackage__c from Documenttype__c where ObjectType__c = 'LeasingOrder__c' and Type__c='Leasing Contract' and Customer_Type__c= null];
                    deliveryOptionId = doctype.DeliveryOption__c;
                    templateId = doctype.DocGenPackage__c;
                }
                DocumentService docService = DocumentService.getInstance();
                List<Document__c> docList = docService.getRequiredLeasingOrderDocument(recordId,documentName);
                if(docList != NULL && docList.size() > 0){
                    leaseOrderService.updateLeasingOrderswithOutTrigger(new List<LeasingOrder__c>{new LeasingOrder__c(Id = recordId, Drawloop_Next__c = '')});
                    String drawloopNextVal =  'SFLeasingOrder__c:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    LeasingOrder__c leaseOrder = new LeasingOrder__c(Id= recordId, Drawloop_Next__c = drawloopNextVal);
                    
                    leaseOrderService.updateLeasingOrders(new List<LeasingOrder__c>{leaseOrder});
                }
                
            }
            if(recordId != null && recordId.getSObjectType() == LeasingReceiptAcknowledgment__c.SObjectType){
                LeasingReceiptAcknowledgementService leaseOrderService = LeasingReceiptAcknowledgementService.getInstance();
                DocumentService docService = DocumentService.getInstance();
                List<Document__c> docList = docService.getRequiredLeasingReceiptAckDocument(recordId,documentName);
                if(docList != NULL && docList.size() > 0){
                    leaseOrderService.updateReceiptACknowledgementsWithoutTrigger(new List<LeasingReceiptAcknowledgment__c>{new LeasingReceiptAcknowledgment__c(Id = recordId, Drawloop_Next__c = '')});
                    String drawloopNextVal =  'SFLeasingReceiptAcknowledgment__c:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    LeasingReceiptAcknowledgment__c leaseReceipt = new LeasingReceiptAcknowledgment__c(Id= recordId, Drawloop_Next__c = drawloopNextVal);
                    
                    leaseOrderService.updateLeasingReceiptAcknowledgement(new List<LeasingReceiptAcknowledgment__c>{leaseReceipt});
                }
                
            }
        } catch (Exception ex) {
            // Catch-all for any other exceptions
            System.debug('Exception: ' + ex.getMessage() + '  '+ ex.getLineNumber());
            throw new AuraHandledException('An unexpected error occurred. Please contact your administrator.');
        }
    }
    @AuraEnabled(cacheable=true)
    public static LeasingOrder__c getLeasingOrderRec(Id recordId){
        LeasingOrderService service = LeasingOrderService.getInstance();
        LeasingOrder__c leasingorder = service.getLeasingOrderById(recordId);
        return leasingorder;
    }
    @AuraEnabled(cacheable=true)
    public static List<DocumentType__c> getDocgenSetupRecords(Id recordId) {
        return  DocumentTypeService.getInstance().getActiveDocuGenDocumentTypeRecords('LeasingOrder__c');
    }
    @AuraEnabled(cacheable=true)
    public static List<DocumentType__c> getLeasingAckDocgenSetupRecords(Id recordId) {
        return  DocumentTypeService.getInstance().getActiveDocuGenDocumentTypeRecords('LeasingReceiptAcknowledgment__c');
    }
    @AuraEnabled(cacheable=true)
    public static List<DocumentType__c> getDocSignSetupRecords(Id recordId) {
        return DocumentTypeService.getInstance().getActiveDocusignDocumentTypeRecords('LeasingOrder__c');
    }
    @AuraEnabled
    public static void sendForSignature(LeasingOrder__c leasingOrderRec, DocumentType__c documentTypeRecord) {
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> doclist = docService.getRequiredLeasingOrderDocument(leasingOrderRec.Id,documentTypeRecord.Type__c);
        String docusignenvid = documentTypeRecord.Docusign_Envelope_Template__r?.dfsle__DocuSignId__c; //dtRec.Docusign_Envelope__c; //dtRec.Docusign_Envelope_Template__c;
        Id documentRecId = doclist[0].Id; 
        Id leasingOrderid = leasingOrderRec.Id;
        String PropertyName = leasingOrderRec.PropertyName__c;
        String unitNumber = leasingOrderRec.Unit__r.LeasingUnitNumber__c;
        String emailSubject = 'Documents for your Signature |'+' '+PropertyName+'-'+unitNumber+'|'+doclist[0].Document_Name__c;
        string docoutputname = documentTypeRecord.Document_Output_Name__c;
        string descrip = documentTypeRecord.Document_Digital_Name__c; // Needs to be changed.
        
        if(documentTypeRecord.Type__c == 'Leasing Offer'){
            sendLeasingEnvelope(docusignenvid,descrip,documentRecId,leasingOrderid,docoutputname,emailSubject); 
            notifyLeasingOfficerDocSignInitiated(new List<LeasingOrder__c>{leasingOrderRec});
        }else if(documentTypeRecord.Type__c == 'Leasing Contract'){
            sendLeasingContractEnvelopeFuture(docusignenvid,descrip,documentRecId,leasingOrderid,docoutputname,emailSubject); 
        }else if(documentTypeRecord.Type__c == 'Move Out Request Form'){
            if(System.isBatch()){
                sendLeasingContractEnvelope(docusignenvid,descrip,documentRecId,leasingOrderid,docoutputname,emailSubject);
            }
            else{
                sendLeasingContractEnvelopeFuture(docusignenvid,descrip,documentRecId,leasingOrderid,docoutputname,emailSubject); 
            }
            
        }
    }
    
    @future(callout=true)
    public static void sendLeasingContractEnvelopeFuture(String template, String description, Id recordId,
                                                         Id leasingOrderId, String documentoutputname,String emailSubject){
                                                             sendLeasingContractEnvelope(template, description, recordId, leasingOrderId, documentoutputname, emailSubject);
                                                         }
    
    @future(callout=true)
    public static void sendLeasingEnvelope(String template, String description, Id recordId,
                                           Id leasingOrderId, String documentoutputname,String emailSubject) 
    {
        
        
        
        dfsle.Notifications notifySigner = new dfsle.Notifications(
            true, // Indicates that the recipient should be reminded to sign
            10, // Number of days to wait before sending a reminder
            10, // Number of days between reminders
            true, // Whether or not the envelope expires and is voided
            999, // How many days before the envelope expires
            10, // Number of days before expiration to remind the recipient
            false // Placeholder for deprecated field
        );
        
        dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(leasingOrderId)
        );
        
        // Include DocuSign template & document
        dfsle.UUID myTemplateId = dfsle.UUID.parse(template); 
        dfsle.Document myDocument = dfsle.Document.fromTemplate(
            myTemplateId, // templateId in dfsle.UUID format
            description); // name of the template
        
        ContentDocumentLink cdl = [select id, ContentDocument.title, ContentDocumentId 
                                   from ContentDocumentLink where 
                                   LinkedEntityId = :recordId and 
                                   ContentDocument.Title like '%Offer Letter'
                                   Order by SystemModstamp desc LIMIT 1];
        
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];
        
        myDocument.withReplacement(dfsle.Document.fromFile(cv));
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        myEnvelope = myEnvelope.withEmail(emailSubject,null);
        myEnvelope =  myEnvelope.withNotifications(notifySigner);
        
        List<dfsle.Recipient> allrecipients = getCustomerRecipients(leasingOrderId, documentoutputname) ; 
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        if (Test.isRunningTest()) {
            return; //  Skip the actual call during tests
        }
        myEnvelope = dfsle.EnvelopeService.sendEnvelope(
            myEnvelope,
            true
        );
    } 
    public static List<dfsle.Recipient> getCustomerRecipients(Id recordid, String documentoutputname)
    {
        
        String TenantName;
        String  TenantEmail;
        String   Tenantmobilenum ;
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        LeasingOrder__c contract = LeasingOrderService.getInstance().getLeasingOrderById(recordId);
        
        if(contract.Account__r.IsPersonAccount){
            
            TenantName = contract.Account__r.Name ;
            TenantEmail = contract.Account__r.PersonEmail;
            Tenantmobilenum = contract.Account__r.PersonMobilePhone;
        }else{
            Contact primaryContact = ContactService.getInstance().getPrimaryContactByAccountId(contract.Account__c,TRUE)[0];
            //primaryContact.email;
            TenantName = primaryContact.Name ;
            TenantEmail = primaryContact.Email ;
            Tenantmobilenum = primaryContact.MobilePhone;
        }
        
        dfsle.Tab mainbuyerSignHereTab = new dfsle.SignHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'MainBuyer:', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'left', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0))// Y offset
            .withPosition(new dfsle.Tab.Position(
                1, 
                null,
                null,
                null,
                null,
                null));
        
        dfsle.Tab initialHereTab = new dfsle.InitialHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'MBIni:', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'left', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0))// Y offset
            ;
        
        dfsle.Tab mainCustomerDateSignedTab = new dfsle.DateSignedTab()
            .withAnchor(new dfsle.Tab.Anchor(
                'MainBuyerSignedDate:',
                false,
                false,
                'left',
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
        
        // Create a list to hold all the tabs
        List<dfsle.Tab> occupantTabs = new List<dfsle.Tab>();
        
        dfsle.Tab EmergencyContactPersontab = new dfsle.TextTab()
            .withReadOnly(false)
            .withRequired(false)
            .withAnchor(new dfsle.Tab.Anchor(
                'EmergencyContactPerson',
                false,  // Do not allow white space
                false,  // Not case sensitive
                'left', // Horizontal alignment
                true,   // Ignore if anchor text not found
                true,   // Match entire string
                'pixels',
                0,
                0
            ))
            .withDataLabel('EmergencyContactPersontab');
        
        dfsle.Tab EmergencyMobileNumbertab = new dfsle.TextTab()
            .withReadOnly(false)
            .withRequired(false)
            .withAnchor(new dfsle.Tab.Anchor(
                'EmergencyMobileNumber',
                false,  // Do not allow white space
                false,  // Not case sensitive
                'left', // Horizontal alignment
                true,   // Ignore if anchor text not found
                true,   // Match entire string
                'pixels',
                0,
                0
            ))
            .withDataLabel('EmergencyMobileNumberTab');
        
        dfsle.Tab EmergencyRelationshiptab = new dfsle.TextTab()
            .withReadOnly(false)
            .withRequired(false)
            .withAnchor(new dfsle.Tab.Anchor(
                'EmergencyRelationship',
                false,  // Do not allow white space
                false,  // Not case sensitive
                'left', // Horizontal alignment
                true,   // Ignore if anchor text not found
                true,   // Match entire string
                'pixels',
                0,
                0
            ))
            .withDataLabel('EmergencyRelationshiptab');
        occupantTabs.add(EmergencyRelationshiptab);
        occupantTabs.add(EmergencyMobileNumberTab);
        occupantTabs.add(EmergencyContactPersontab);
        // Define the 3 field suffixes
        List<String> fieldTypes = new List<String>{'Name', 'Age', 'Relationship'};
            
            // Loop through 1 to 6 Occupants
            for (Integer i = 1; i <= 6; i++) {
                for (String field : fieldTypes) {
                    // Build anchor string like 'Occupant1Name', 'Occupant2Age', etc.
                    String anchorText = 'Occupant' + i + field;
                    
                    // Create the TextTab dynamically
                    dfsle.Tab tab = new dfsle.TextTab()
                        .withReadOnly(false)
                        .withRequired(false)
                        .withAnchor(new dfsle.Tab.Anchor(
                            anchorText,
                            false,  // Do not allow white space
                            false,  // Not case sensitive
                            'left', // Horizontal alignment
                            true,   // Ignore if anchor text not found
                            true,   // Match entire string
                            'pixels',
                            0,
                            0
                        ))
                        .withDataLabel('Occupant' + i + field + 'Label');
                    
                    // Add to the list
                    occupantTabs.add(tab);
                }
            }
        
        // Now you can attach occupantTabs to your signer or envelope as needed
        // Example: signer.withTabs(occupantTabs);
        List<dfsle.Tab> allTabs = new List<dfsle.Tab>{
            mainbuyerSignHereTab,
                mainCustomerDateSignedTab,
                initialHereTab
                };
                    
                    // Merge all occupant tabs
                    allTabs.addAll(occupantTabs);
        
        dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
            TenantName,
            TenantEmail,
            Tenantmobilenum , 
            'MainBuyer:',
            null)
            .withTabs(allTabs).withRoutingOrder(2);
        
        
        dfsle.Tab leasingManagerSignHereTab = new dfsle.SignHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'leasingManagerSignHere', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'left', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0))// Y offset
            .withPosition(new dfsle.Tab.Position(
                1, 
                null,
                null,
                null,
                null,
                null));
        
        
        dfsle.Recipient leasingOrderOwner = dfsle.Recipient.fromSource(
            contract.Owner.Name,
            contract.Owner.Email,
            Tenantmobilenum , 
            'leasingOfficer',
            null).withType(dfsle.Recipient.TYPE_CARBON_COPY)  
            .withRoutingOrder(3);
        
        
        
        String leasingMangerName = MetadataService.getInstance().getAppSettingTextValue(LEASING_MANAGER_DOCSIGN_NAME);
        String leasingManagerEmail = MetadataService.getInstance().getAppSettingTextValue(LEASING_MANAGER_DOCSIGN_EMAIL);
        dfsle.Recipient leasingManagerRecipient = dfsle.Recipient.fromSource(
            leasingMangerName,
            leasingManagerEmail,
            '0000000000', 
            'leasingManagerSignHere',
            null)
            .withTabs(new List<dfsle.Tab> {
                leasingManagerSignHereTab
                    }).withRoutingOrder(1);
       
        if(contract.AppliedAnnualRent__c >= 350000.00){
            
            dfsle.Tab bloomCEOSignHereTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'bloomCEOSignHere', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'left', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0))// Y offset
                .withPosition(new dfsle.Tab.Position(
                    1, 
                    null,
                    null,
                    null,
                    null,
                    null));
             String CEO_Name = MetadataService.getInstance().getAppSettingTextValue(BLOOM_CEO_DOCSIGN_NAME);
        String CEO_Email = MetadataService.getInstance().getAppSettingTextValue(BLOOM_CEO_DOCSIGN_EMAIL);
            dfsle.Recipient bloomCEORecipient = dfsle.Recipient.fromSource(
                CEO_Name,
                CEO_Email,
                '0000000000', 
                'bloomHoldingCEOSignHere',
                null)
                .withTabs(new List<dfsle.Tab> {
                    bloomCEOSignHereTab
                        }).withRoutingOrder(2);
            
            allrecipients.add(bloomCEORecipient);
        }
        
        allrecipients.add(leasingManagerRecipient);
        allrecipients.add(leasingOrderOwner);
        allrecipients.add(mainbuyerRecipient);
        
        
        return allrecipients;
    } 
    
    public static void sendLeasingContractEnvelope(String template, String description, Id recordId,
                                                   Id leasingOrderId, String documentoutputname,String emailSubject) 
    {
        
        
        
        dfsle.Notifications notifySigner = new dfsle.Notifications(
            true, // Indicates that the recipient should be reminded to sign
            10, // Number of days to wait before sending a reminder
            10, // Number of days between reminders
            true, // Whether or not the envelope expires and is voided
            999, // How many days before the envelope expires
            10, // Number of days before expiration to remind the recipient
            false // Placeholder for deprecated field
        );
        
        dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(leasingOrderId)
        );
        
        // Include DocuSign template & document
        dfsle.UUID myTemplateId = dfsle.UUID.parse(template); 
        dfsle.Document myDocument = dfsle.Document.fromTemplate(
            myTemplateId, // templateId in dfsle.UUID format
            description); // name of the template
        
        ContentDocumentLink cdl = [select id, ContentDocument.title, ContentDocumentId 
                                   from ContentDocumentLink where 
                                   LinkedEntityId = :recordId and 
                                   ContentDocument.Title like '%Leasing Contract.pdf'
                                   Order by SystemModstamp desc LIMIT 1];
        
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];
        
        myDocument.withReplacement(dfsle.Document.fromFile(cv));
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        myEnvelope = myEnvelope.withEmail(emailSubject,null);
        myEnvelope =  myEnvelope.withNotifications(notifySigner);
        
        List<dfsle.Recipient> allrecipients = getCustomerRecipientsForContract(leasingOrderId, documentoutputname) ; 
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        if (Test.isRunningTest()) {
            return; //  Skip the actual call during tests
        }
        myEnvelope = dfsle.EnvelopeService.sendEnvelope(
            myEnvelope,
            true
        );
    } 
    public static List<dfsle.Recipient>  getCustomerRecipientsForContract(Id recordid, String documentoutputname)
    { 
        String TenantName;
        String TenantEmail;
        String Tenantmobilenum ;
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        LeasingOrder__c contract = LeasingOrderService.getInstance().getLeasingOrderById(recordId);
        
        if(contract.Account__r.IsPersonAccount){
            TenantName = contract.Account__r.Name ;
            TenantEmail = contract.Account__r.PersonEmail;
            Tenantmobilenum = contract.Account__r.PersonMobilePhone;
        }else{
            Contact primaryContact = ContactService.getInstance().getPrimaryContactByAccountId(contract.Account__c,TRUE)[0];
            //primaryContact.email;
            TenantName = primaryContact.Name ;
            TenantEmail = primaryContact.Email ;
            Tenantmobilenum = primaryContact.MobilePhone;
        }
        
        dfsle.Tab mainbuyerSignHereTab = new dfsle.SignHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'LeasingCustomerSign', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'left', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0))// Y offset
            .withPosition(new dfsle.Tab.Position(
                1, 
                null,
                null,
                null,
                null,
                null));
        
        dfsle.Tab initialHereTab = new dfsle.InitialHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'LeasingCustomerSignInitial', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'left', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0))// Y offset
            ;
        
        dfsle.Tab mainCustomerDateSignedTab = new dfsle.DateSignedTab()
            .withAnchor(new dfsle.Tab.Anchor(
                'LeasingCustomerSignedDate',
                false,
                false,
                'left',
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
        List<dfsle.Tab> occupantTabs = new List<dfsle.Tab>();
        for (Integer i = 1; i <= 6; i++) {
            String anchorText = 'Occupant' + i + 'Name';
            
            
            dfsle.Tab tab = new dfsle.TextTab()
                .withReadOnly(false)
                .withRequired(false)
                .withAnchor(new dfsle.Tab.Anchor(
                    anchorText,
                    false,  // Allow white space
                    false,  // Not case sensitive
                    'left', // Horizontal alignment
                    true,   // Ignore if not found
                    true,   // Match entire string
                    'pixels',
                    0,
                    0
                ))
                .withDataLabel('Occupant' + i + 'NameLabel');
            
            occupantTabs.add(tab);
        }
        
        dfsle.Tab MovingDateTenantTab = new dfsle.TextTab()
            .withReadOnly(false)
            .withRequired(false)
            .withAnchor(new dfsle.Tab.Anchor(
                'MovingDateTenant',
                false,  // Allow white space
                false,  // Not case sensitive
                'left', // Horizontal alignment
                true,   // Ignore if not found
                true,   // Match entire string
                'pixels',
                0,
                0
            ))
            .withDataLabel('MovingDateTenantLabel');
        occupantTabs.add(MovingDateTenantTab);
        
        dfsle.Tab MovingCompanyTenantTab = new dfsle.TextTab()
            .withReadOnly(false)
            .withRequired(false)
            .withAnchor(new dfsle.Tab.Anchor(
                'MovingCompanyTenant',
                false,  // Allow white space
                false,  // Not case sensitive
                'left', // Horizontal alignment
                true,   // Ignore if not found
                true,   // Match entire string
                'pixels',
                0,
                0
            ))
            .withDataLabel('MovingCompanyTenantLabel');
        occupantTabs.add(MovingCompanyTenantTab);
        
        occupantTabs.add(mainbuyerSignHereTab);
        occupantTabs.add(mainCustomerDateSignedTab);
        occupantTabs.add(initialHereTab);
        
        
        
        dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
            TenantName,
            TenantEmail,
            Tenantmobilenum , 
            'LeasingCustomerSign',
            null)
            .withTabs(occupantTabs).withRoutingOrder(1);
        
        
        dfsle.Tab leasingManagerSignHereTab = new dfsle.SignHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'LeasingManagerSign', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'left', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0))// Y offset
            .withPosition(new dfsle.Tab.Position(
                1, 
                null,
                null,
                null,
                null,
                null));
        
        dfsle.Recipient leasingOrderOwner = dfsle.Recipient.fromSource(
            contract.Owner.Name,
            contract.Owner.Email,
            Tenantmobilenum , 
            'leasingOfficer',
            null).withType(dfsle.Recipient.TYPE_CARBON_COPY)  
            .withRoutingOrder(3);
        
        String leasingMangerName = MetadataService.getInstance().getAppSettingTextValue(LEASING_MANAGER_DOCSIGN_NAME);
        String leasingManagerEmail = MetadataService.getInstance().getAppSettingTextValue(LEASING_MANAGER_DOCSIGN_EMAIL);
        dfsle.Recipient leasingManagerRecipient = dfsle.Recipient.fromSource(
            leasingMangerName,
            leasingManagerEmail,
            '0000000000', 
            'LeasingManagerSign',
            null)
            .withTabs(new List<dfsle.Tab> {
                leasingManagerSignHereTab
                    }).withRoutingOrder(2);
        allrecipients.add (leasingManagerRecipient);
        allrecipients.add (mainbuyerRecipient);
        allrecipients.add (leasingOrderOwner);
        return allrecipients;
    } 
    private static void notifyLeasingOfficerDocSignInitiated(List<LeasingOrder__c> leasingOrders) {
        
        if (leasingOrders == null || leasingOrders.isEmpty()) {
            return;
        }
        
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        Id emailTemplateId = objMetadataService.getAppSettingTextValue(LEASING_SIGNING_EMAIL_TEMPLATE_ID);
        Id noReplyOWDId   = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID );
        
        for (LeasingOrder__c order : leasingOrders) {
           
            if (String.isNotBlank(order.Owner.Email)) {
                
                Messaging.SingleEmailMessage email =
                    objEmailService.getSingleEmailMessageWithoutTargetObjectId(
                        emailTemplateId,noReplyOWDId,order.Id,  new List<String>{ order.Owner.Email },null,null );
                emailList.add(email);
            }
        }
        
        if (!emailList.isEmpty()) {
            objEmailService.sendEmail(emailList);
        }
    }
}
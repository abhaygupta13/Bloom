/*****************************************************************************************
Class       : BrokerCommissionController
Author      : Vikas Baliyan
Description : Commission Controller
Test Class  : 
Created Date: 15 Dec 2024 
*****************************************************************************************/
public without sharing class BrokerCommissionController {
    
    private static final string INVOICE_ATTACHMENT_EMAIL_TEMPLATE_ID { get { return 'CommissionInvoiceAttachmentTempId'; } }
    private static final string BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_BROKER_COMMISSION_DOC_MERGE_ORDER { get { return 'BrokerCommissionDocsMergeOrder'; } }
    private static final string MTD_BC_BROKER_CONTACT_ROLE_VALUE { get { return 'BrokerCommissionBrokerContactRoleValue'; } }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(Id recordId){
        try {
            ContactService objContactService = ContactService.getInstance();
            BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            BrokerCommission__c broker = objBrokerCommissionServ.getBrokerCommissionById(recordId);
            String brokerContactRole = objMetadataService.getAppSettingTextValue(MTD_BC_BROKER_CONTACT_ROLE_VALUE);
            List<String> brokerContactRoleValueList = brokerContactRole.split(',');
            List<Contact> conList = objContactService.getActiveBrokerContactByAccountId(broker.Agency__c,brokerContactRoleValueList);
            return conList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String shareCommissionInvoice(Id recordId, Id contactId){ 
        DocumentService docService = DocumentService.getInstance();
        ContentService contentService = ContentService.getInstance();
        BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
        EmailMessageService objEmailMessageService = EmailMessageService.getInstance();
        Boolean isSuccess = false;
        try{
            if(recordId.getSObjectType() == BrokerCommission__c.getSObjectType()){
                MetadataService objMetadataService = MetadataService.getInstance();
                //Fetch Email Template id
                Id invoiceEmailTemplateId = objMetadataService.getAppSettingTextValue(INVOICE_ATTACHMENT_EMAIL_TEMPLATE_ID);
                
                // Fetch Broker Commission record
                BrokerCommission__c broker = objBrokerCommissionServ.getBrokerCommissionById(recordId);
                ContactService objContactService = ContactService.getInstance();
                Contact agent = objContactService.getContactById(contactId);
                if(agent.Email == null){
                    return 'The selected contact does not have an email address.';
                }
                
                //Fetch Document record
                List<Document__c> docList = docService.getBrokerCommissionDocuments(recordId, Constants.GENERATED_INVOICE);
                // Fetch content document link
                List<ContentDocumentLink> cdLinkList = contentService.getContentDocumentLinkByEntityId(docList[0].Id);
                // Fetch content version
                List<ContentVersion> cvList = contentService.getContentVersionsByCDIds(new Set<Id>{cdLinkList[0].ContentDocumentId});
                
                //Fetch Email
                Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
                EmailService objEmailService = EmailService.getInstance();
                
                //EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(invoiceEmailTemplateId);
                Messaging.SingleEmailMessage result = Messaging.renderStoredEmailTemplate(invoiceEmailTemplateId, null, recordId);
                String emailBody = result.getHtmlBody();
                emailBody = emailBody.replace('{AgentName}', agent.Name);
                emailBody = emailBody.replace('{CommissionAmount}', String.valueOf(broker.CommissionAmount__c));
                emailBody = emailBody.replace('{TotalCommissionAmountWithVAT}', String.valueOf(broker.TotalCommissionAmountWithVAT__c));
                // Email to send    
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(new List<String>{agent.Id}, recordId, null,result.Subject, emailBody, noReplyBloomSalesOWDId);     
                Messaging.EmailFileAttachment emailFileAttachment = objEmailService.getEmailAttachment(cvList[0].Title + '.pdf', cvList[0].VersionData, 'application/pdf');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { emailFileAttachment});
                
                // Sending email
                Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                
                if(results[0].success){
                    // Fetch the EmailMessage
                    EmailMessage emailMsg = objEmailMessageService.getLatestEmailMessageByRelatedToId(recordId);

                    if (emailMsg != null) {
                        ContentDocumentLink cdl = contentService.CreateContentDocumentLinkObj(cdLinkList[0].ContentDocumentId, emailMsg.Id,  'V' , 'AllUsers');
                        contentService.createContentDocumentLink(new List<ContentDocumentLink>{cdl});
                    }
                    // Updating Status to Shared
                    broker.Status__c = Constants.COMMISSION_INVOICE_STATUS_SHARED;
                    
                    // Update Broker Commission 
                    objBrokerCommissionServ.updateBrokerCommissions(new List<BrokerCommission__c>{broker});          
                }  
                isSuccess = results[0].success;
            }
            return isSuccess ? 'true' : 'false';
        }
        catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
    }
    
    
    @AuraEnabled
    public static List<ContentVersionWrapper> getBrokerCommissionDocuments(String recordId){
        try{
            MetadataService objMetadataService = MetadataService.getInstance();
            BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
            List<ContentVersionWrapper> wrappers = new List<ContentVersionWrapper>();
            DocumentService docService = DocumentService.getInstance();
            
            // fetch broker commission documents
            List<Document__c> documentList = DocumentService.getDocuments(recordId);
            
            Map<Id, String> mapOfContentDocIdAndDocName = new Map<Id, String>();
            BrokerCommission__c bc = objBrokerCommissionServ.getBrokerCommissionById(recordId);
            //fetch broker agency documents
            if(bc.Agency__c != null){
                documentList.addAll(DocumentService.getDocuments(bc.Agency__c));
            }
            if(bc.SalesOrder__c != null){
                documentList.addAll(docService.getSalesOrderDocumentsByName(new List<String>{bc.SalesOrder__c}, 'Booking Form - Signed'));
                documentList.addAll(docService.getSalesOrderDocumentsByName(new List<String>{bc.SalesOrder__c}, 'Broker Acknowledgement Form'));
            }
            Set<String> documentNameSet = new Set<String>{'Broker Shared Invoice','Broker Form','Trade License','Rera Certificate','Bank confirmation letter','Booking Form - Signed','Broker Acknowledgement Form'};
            if(bc.Agency__r.Is_VAT_Registered__c == 'Yes'){
                documentNameSet.add('Tax Registration Number');
            }
            else{
                documentNameSet.add('Non-VAT declaration document if not registered for VAT');
            }
            for(Document__c document : documentList) {
                if(document.ContentDocumentId__c != null && document.Document_Name__c != null && documentNameSet.contains(document.Document_Name__c)) {
                    mapOfContentDocIdAndDocName.put(document.ContentDocumentId__c, document.Document_Name__c);
                }
            }
            List<String> documentsName = new List<String>();
            
            // fetch document merge order form metadata
            String mtdDownloadOrderString = objMetadataService.getAppSettingTextValue(MTD_BROKER_COMMISSION_DOC_MERGE_ORDER);
            if(mtdDownloadOrderString != null) documentsName.addAll(mtdDownloadOrderString.split(','));
            
            //map of document name to merge order
            Map<String, Integer> documentNameWithDownloadOrderMap = new Map<String, Integer>();
            
            // get the broker form pdf data
            Blob brokerFormpdfBlob;
            if (Test.isRunningTest()){
                // Return a mock blob during tests
                brokerFormpdfBlob = Blob.valueOf('Mock PDF Content');
            } else {
                PageReference vfPage = Page.BrokerFormInitialPDFGenerator;
                vfPage.getParameters().put('brokerCommissionId', bc.Id);
                brokerFormpdfBlob = vfPage.getContent();
            }
            
            Integer order = 1;
            for(String docName : documentsName){
                documentNameWithDownloadOrderMap.put(docName, order);
                order++;
            }
            ContentService objContentService = ContentService.getInstance();
            List<ContentVersion> versions = objContentService.getContentVersionsByCDIds(mapOfContentDocIdAndDocName.KeySet());
            
            for(ContentVersion cv : versions){
                String docName = mapOfContentDocIdAndDocName.get(cv.ContentDocumentId);
                Integer docOrder = documentNameWithDownloadOrderMap.containsKey(mapOfContentDocIdAndDocName.get(cv.ContentDocumentId)) 
                    ? documentNameWithDownloadOrderMap.get(mapOfContentDocIdAndDocName.get(cv.ContentDocumentId)) : 10;
                if(mapOfContentDocIdAndDocName.containsKey(cv.ContentDocumentId) && mapOfContentDocIdAndDocName.get(cv.ContentDocumentId) == 'Broker Form' && bc.FinalApprovalStatus__c != 'Approved'){
                    wrappers.add(new ContentVersionWrapper(EncodingUtil.base64Encode(brokerFormpdfBlob),docOrder,docName));
                }else{
                    wrappers.add(new ContentVersionWrapper(EncodingUtil.base64Encode(cv.VersionData),docOrder,docName));
                }
            }
            // Sort by order before returning 
            wrappers.sort();
            return wrappers;
        }catch(Exception e){ 
            throw new AuraHandledException('Error: '+ e.getMessage()); 
        }
    }
    
    @AuraEnabled
    public static String attachCombinedDocument(String mergedPdf, String recordId){
        try{
            ContentService objContentService = ContentService.getInstance();
            Blob pdfBlob = EncodingUtil.base64Decode(mergedPdf);
            ContentVersion cv = objContentService.CreateContentVersionObj('Broker Invoice Combined Document - ' + DateTime.now().format('yyyyMMdd_HHmmss'), 'Broker Invoice Combined Document - ' + DateTime.now().format('yyyyMMdd_HHmmss') + '.pdf', pdfBlob, 'H');
            
            attachDocument(recordId, null, 'Broker Invoice Combined Document', null, new List<ContentVersion>{cv});
            return 'Combined document generated successfully!';
         } catch (Exception e) {
            throw new AuraHandledException('Error: '+ e.getMessage());
         }
    }

    public static void attachDocument(String recordId, List<BrokerCommission__c> bcList, String docType,  Map<String, String> cvTitleToInvoiceIdMap, List<ContentVersion> cvList){
        Savepoint sp;
        try {
            DocumentService objDocumentService = DocumentService.getInstance();
            ContentService objContentService = ContentService.getInstance();
            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
            Map<String, String> brokerIDToDocId = new Map<String, String>();
            sp = Database.setSavePoint();
            if(bcList != null){
                for(Document__c doc : objDocumentService.getBrokerCommissionDocuments(bcList, docType)){
                    brokerIDToDocId.put(doc.BrokerCommission__c , doc.Id);
                }
            }
            else{
                for(Document__c doc : objDocumentService.getBrokerCommissionDocuments(recordId, docType)){
                    brokerIDToDocId.put(doc.BrokerCommission__c , doc.Id);
                }
            }
            objContentService.createContentVersion(cvList);
            List<ContentVersion> contentVersionList = objContentService.getContentVersionByIds(cvList);
            // fetch Contetnt Document link from content version
            
            List<Document__c> docList = new List<Document__c>();
            // Iterate through content version
            for(contentVersion conVer : contentVersionList){
                cdList.add(objContentService.CreateContentDocumentLinkObj(conVer.contentDocumentId ,brokerIDToDocId.get(cvTitleToInvoiceIdMap != null ? cvTitleToInvoiceIdMap.get(conVer.Title) : recordId), 'V' , 'AllUsers'));
                // list of Document to update
                docList.add(addFile(brokerIDToDocId.get(cvTitleToInvoiceIdMap != null ? cvTitleToInvoiceIdMap.get(conVer.Title) : recordId), conVer.ContentDocumentId));
            }
            // Insert Content Document link
            objContentService.createContentDocumentLink(cdList); 

            //update Document records
            objDocumentService.updateDocuments(docList);
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error: '+ e.getMessage());
         }
        
    }

    private static Document__c addFile(Id documentId, Id contentDocId){ 
        DocumentService objDocumentService = DocumentService.getInstance();
        Document__c objDocument = objDocumentService.getDocumentById(documentId);
        if(String.isNotBlank(objDocument.ContentDocumentId__c)){
            objDocumentService.deleteContentDocument(new ContentDocument(Id = objDocument.ContentDocumentId__c));
        }
        objDocument.ContentDocumentId__c = contentDocId;
        return objDocument;
    }

    public class ContentVersionWrapper implements Comparable {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public Integer order {get;set;}
        @AuraEnabled public String fileName {get;set;}
        
        public ContentVersionWrapper(String base64Data, Integer order, String fileName) {
            this.base64Data = base64Data;
            this.order = order;
            this.fileName = fileName;
        }
        public Integer compareTo(Object ObjectToCompare) {
            ContentVersionWrapper compareToWrapperCls = (ContentVersionWrapper)ObjectToCompare;  
            if (order == compareToWrapperCls.order) return 0;  
            if (order > compareToWrapperCls.order) return 1;
            return -1;  
        }  
    }
}
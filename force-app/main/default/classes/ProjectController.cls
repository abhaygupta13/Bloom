/***
Class       : ProjectController
Author      : Jayesh
Description : Using this class as controller of project and unit registration process
TestClass   : ProjectControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0               05-DEC-24            Initial Version 
****************************************************************************************************************/
public without sharing class ProjectController {
    
    private static final String UNIT_REG_DOC_FILE_NAME = 'Unit Registration'; 
    private static final string MTD_NO_REPLY_OWEID_SETTING { get { return 'NoReplySalesIT'; } }
    private static final string MTD_PROP_REG_CUST_EMAIL_TEMPLATE_ID { get { return 'PropertyRegCustEmailTemplateId'; } }
    private static final string MTD_UNIT_PROP_REG_EMAIL_TEMPLATE_ID { get { return 'UnitPropRegistrationETId'; } }
    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();
    private static final String SALES_ORDER_OBJECT_NAME = 'Sales Order';
    private static final String ADM_REG_DOC_FILE_NAME = 'ADM Registration Document';
    private static final string MTD_PROJECT_REG_EMAIL_TEMPLATE_ID { get { return 'ProjectRegEmailTemplateId'; } } 
    private static final string MTD_PROJECT_REG_WITH_UNITS_EMAIL_TEMPLATE_ID { get { return 'ProjectRegWithUnitsETId'; } }
    private static final string MTD_OPT_TEAM_EMAIL_ADDSS { get { return 'OperationTeamEmailAddresses'; } }
    private static final string MTD_CRM_TEAM_EMAIL_ADDSS { get { return 'CRMTeamEmailAddresses'; } }
    private static final string MTD_PUBLIC_REL_TEAM_EMAIL_ADDSS { get { return 'PublicRelationTeamEmailAddresses'; } }
    private static final string MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS { get { return 'SalesFinanceTeamEmailAddresses'; } }
    private static final string MTD_GR_TEAM_EMAIL_ADDSS { get { return 'GRTeamEmailAddresses'; } }
    private static final string MTD_PROJ_UNIT_REG_BCC_EMAIL_ADDS { get { return 'ProjectUnitRegBCCEmailAddresses'; } }
    private static final string SO_SOLD_STATUS { get { return 'Sold'; } }
    private static final string MTD_PAYMENT_PLAN_INVALID_SALES_ORDER_STATUS_VALUE { get { return 'PaymentPlanInvalidSalesOrderStatus'; } }
    //private static final string RESIDENT_CUST_TYPE { get { return 'Resident'; } }
    //private static final string INTERNATIONAL_CUST_TYPE { get { return 'International'; } }
    //private static final string GCC_CUST_TYPE { get { return 'GCC'; } }
    //private static final string UAE_NATIONAL_CUST_TYPE { get { return 'UAE National'; } }
    private static final string MTD_SALESORDER_DOC_DOWNLOAD_ORDER { get { return 'SalesOrderDocsDownloadOrder'; } }
    //private static final string SPA_SIGNED_DOC_TYPE { get { return 'SPA - Signed'; } }
    //private static final string PASSPORT_DOC_TYPE { get { return 'Passport'; } }
    //private static final string EID_DOC_TYPE { get { return 'Emirates ID'; } }
    //private static final string NOC_DOC_TYPE { get { return 'NOC'; } }
    private static final string PROJ_UNIT_REG_DOC_NAME { get { return 'Project-Unit Registration Document'; } }
    
    @AuraEnabled
    public static Project__c getProjectRecord(String projectRecordId){
        ProjectService ps = ProjectService.getInstance();
        return ps.getProjectDetailsWithUnitsAndDocuments(projectRecordId, SO_SOLD_STATUS, ADM_REG_DOC_FILE_NAME);
    }
    
    @AuraEnabled
    public static Project__c getProjectAndSoldUnits(String projectRecordId){
        ProjectService ps = ProjectService.getInstance();
        return ps.getProjectWithSoldUnits(projectRecordId, SO_SOLD_STATUS);
    }
    
    @AuraEnabled
    public static Project__c getProjectRecordWithUnits(String projectRecordId){
        ProjectService ps = ProjectService.getInstance();
        return ps.getProjectWithUnits(projectRecordId, SO_SOLD_STATUS);
    }
    
    /*@AuraEnabled
public static List<Unit__c> getUnitsBasedOnProject(String projectRecordId){
UnitService us = UnitService.getInstance();
return us.getSoldUnitsOfProject(projectRecordId, SO_SOLD_STATUS);
}*/
    
    @AuraEnabled
    public static Map<String, Document__c> getSalesOrderUnitDocument(List<String> salesOrderIds){
        Map<String, Document__c> salesOrderIdAndDocument = new Map<String, Document__c>();
        DocumentService ds = DocumentService.getInstance();
        List<Document__c> documents = ds.getSalesOrderDocumentsByName(salesOrderIds, UNIT_REG_DOC_FILE_NAME);
        for(Document__c doc : documents){
            salesOrderIdAndDocument.put(doc.SalesOrder__c, doc);
        }
        return salesOrderIdAndDocument;
    }
    
    @AuraEnabled
    public static Map<String, Document__c> getUnitDocuments(List<String> unitIds){
        Map<String, Document__c> unitIdAndDocument = new Map<String, Document__c>();
        DocumentService ds = DocumentService.getInstance();
        List<Document__c> documents = ds.getUnitDocumentsByName(unitIds, PROJ_UNIT_REG_DOC_NAME);
        for(Document__c doc : documents){
            unitIdAndDocument.put(doc.Unit__c, doc);
        }
        return unitIdAndDocument;
    }
    
    @AuraEnabled
    public static void updateUnitRegDateOnSalesOrder(List<SalesOrder__c> selectedRecords){
        Savepoint sp = Database.setSavePoint();
        try{
            if(!selectedRecords.isEmpty()) {
                SalesOrderService service = SalesOrderService.getInstance();
                service.updateSalesOrders(selectedRecords);
                Set<Id> soIds = new Set<Id>();
                System.debug('selectedRecords'+selectedRecords);
                for(SalesOrder__c so : selectedRecords) soIds.add(so.Id);
                List<SalesOrder__c> salesOrders = service.getUnitRegisteredSalesOrders(soIds);
                System.debug('salesOrders'+salesOrders);
                sendUnitPropRegistrationEmailToCustomer(salesOrders);
                sendUnitPropRegistrationEmail(salesOrders);
            }
        }catch(Exception e){
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR,'Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString()); 
            throw e;
        }
    }  
    
    //Using this method to download Sales Order Document
    //Except Unit Registration document
    @AuraEnabled
    public static String getSalesOrderDocuments(String salesOrderId){
        try{
            List<ContentVersionWrapper> wrappers = new List<ContentVersionWrapper>();
            List<Document__c> documentList = DocumentService.getDocuments(salesOrderId);
            Map<String, String> mapOfContentDocIdAndDocName = new Map<String, String>();
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            String mtdDownloadOrderString = objMetadataService.getAppSettingTextValue(MTD_SALESORDER_DOC_DOWNLOAD_ORDER);
            List<String> documentsName = new List<String>();
            if(mtdDownloadOrderString != null) documentsName.addAll(mtdDownloadOrderString.split(','));
            Map<String, Integer> documentNameWithDownloadOrderMap = new Map<String, Integer>();
            //System.debug('documentsName=====>'+documentsName);
            Integer order = 1;
            for(String docName : documentsName){
                documentNameWithDownloadOrderMap.put(docName, order);
                order++;
            }
            //Map<String, ContentVersion> mapOfDocNameAndCV = new Map<String, ContentVersion>();
            for(Document__c document : documentList) {
                if(document.ContentDocumentId__c != null && document.Document_Name__c != UNIT_REG_DOC_FILE_NAME) {//Except Unit Registration file
                    mapOfContentDocIdAndDocName.put(document.ContentDocumentId__c, document.Document_Name__c);
                }
            }
            
            List<ContentVersion> versions = [
                SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                FROM ContentVersion 
                WHERE ContentDocumentId IN :mapOfContentDocIdAndDocName.KeySet() 
                ORDER BY CreatedDate DESC
            ];
            for(ContentVersion cv : versions){
                //mapOfDocNameAndCV.put(mapOfContentDocIdAndDocName.get(cv.ContentDocumentId), cv);
                Integer docOrder = documentNameWithDownloadOrderMap.containsKey(mapOfContentDocIdAndDocName.get(cv.ContentDocumentId)) 
                    ? documentNameWithDownloadOrderMap.get(mapOfContentDocIdAndDocName.get(cv.ContentDocumentId)) : 10; // Default order for unrecognized files
                wrappers.add(new ContentVersionWrapper(
                    mapOfContentDocIdAndDocName.get(cv.ContentDocumentId),
                    EncodingUtil.base64Encode(cv.VersionData),
                    docOrder
                ));
            }
            // Sort by order before returning 
            wrappers.sort();
            return JSON.serialize(wrappers);
        }catch(Exception e){
            throw new AuraHandledException('Error: '+ e.getMessage());   
        }
    }
    
    public class ContentVersionWrapper implements Comparable {
        public String title { get; set; }
        public String base64Data { get; set; }
        public Integer order {get;set;}
        
        public ContentVersionWrapper(String title, String base64Data, Integer order) {
            this.title = title;
            this.base64Data = base64Data;
            this.order = order;
        }
        public Integer compareTo(Object ObjectToCompare) {
            ContentVersionWrapper compareToWrapperCls = (ContentVersionWrapper)ObjectToCompare;  
            if (order == compareToWrapperCls.order) return 0;  
            if (order > compareToWrapperCls.order) return 1;
            return -1;  
        }  
    }
    
    @AuraEnabled
    public static List<String> getSalesOrderRecordWithNoDocuments(List<String> salesOrderIds){
        // Step 1: Query documents grouped by SalesOrder__c
        Map<Id, Integer> salesOrderBlankCount = new Map<Id, Integer>();
        DocumentTypeService dtService = DocumentTypeService.getInstance();
        List<DocumentType__c> salesOrderDocumentType = dtService.getDocumentTypeRecords(SALES_ORDER_OBJECT_NAME); //Exclude to download Unit Registration Document
        Integer count = 0;
        for(DocumentType__c dt : salesOrderDocumentType){
            if(dt.Type__c != UNIT_REG_DOC_FILE_NAME) count++;
        }
        for (AggregateResult ar : [
            SELECT SalesOrder__c salesOrderId, COUNT(Id) recordCount
            FROM Document__c
            WHERE ContentDocumentId__c = NULL AND Document_Name__c != :UNIT_REG_DOC_FILE_NAME AND SalesOrder__c IN :salesOrderIds
            GROUP BY SalesOrder__c
        ]) {
            Id salesOrderId = (Id)ar.get('salesOrderId');
            Integer blankCount = (Integer)ar.get('recordCount');
            salesOrderBlankCount.put(salesOrderId, blankCount);
        }
        List<Id> resultSalesOrders = new List<Id>();
        
        for (Id salesOrderId : salesOrderBlankCount.keySet()) {
            if (salesOrderBlankCount.get(salesOrderId) == count) {
                resultSalesOrders.add(salesOrderId);
            }
        }
        List<String> salesOrderIdsList = new List<String>();
        salesOrderIdsList.addAll(resultSalesOrders);
        return salesOrderIdsList;
    }
    
    /*@AuraEnabled
public static List<String> getSalesOrdersWithMandatoryDocuments(List<String> salesOrderIds){
List<String> salesOrderIdList = new List<String>();
SalesOrderService sos = SalesOrderService.getInstance();
List<SalesOrder__c> salesOrders = sos.getSalesOrdersWithDocuments(salesOrderIds);
// Iterate through Sales Orders
for (SalesOrder__c salesOrder : salesOrders) {
Boolean hasSPA = false;
Boolean hasEID = false;
Boolean hasPassport = false;

// Check document types
for (Document__c doc : salesOrder.Documents__r) {
if (doc.DocumentType__r.Type__c == SPA_SIGNED_DOC_TYPE) hasSPA = true;
if (doc.DocumentType__r.Type__c == EID_DOC_TYPE) hasEID = true;
if (doc.DocumentType__r.Type__c == PASSPORT_DOC_TYPE) hasPassport = true;
}

// Apply logic based on Customer Type
if (hasSPA) {
if ((salesOrder.Account__r.CustomerType__c == RESIDENT_CUST_TYPE || salesOrder.Account__r.CustomerType__c == UAE_NATIONAL_CUST_TYPE) && hasEID) {
salesOrderIdList.add(salesOrder.Id);
} else if ((salesOrder.Account__r.CustomerType__c == GCC_CUST_TYPE || salesOrder.Account__r.CustomerType__c == INTERNATIONAL_CUST_TYPE) && hasPassport) {
salesOrderIdList.add(salesOrder.Id);
}
}
}
return salesOrderIdList;
}*/
    
    @AuraEnabled
    public static String uploadUnitRegDocument(String unitRegistrationDocument){
        try{
            if(unitRegistrationDocument != null){
                DocumentService documentService = DocumentService.getInstance();
                UnitRegDocumentWrapper deserializedData = (UnitRegDocumentWrapper) JSON.deserialize(unitRegistrationDocument, UnitRegDocumentWrapper.class);
                if(deserializedData != null){
                    if(deserializedData.recordId.getSObjectType() == SalesOrder__c.SobjectType){
                        List<Document__c> unitRegDocument = documentService.getDocumentBasedonType(deserializedData.recordId, UNIT_REG_DOC_FILE_NAME);
                        return saveDocument(deserializedData.base64, deserializedData.fileName, unitRegDocument[0].Id);
                    }else if(deserializedData.recordId.getSObjectType() == Unit__c.SobjectType){
                        List<Document__c> unitRegDocument = documentService.getDocumentBasedonType(deserializedData.recordId, 'Project-Unit Registration Document');
                        return saveDocument(deserializedData.base64, deserializedData.fileName, unitRegDocument[0].Id);
                    }
                }
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException('Error: '+ e.getMessage());   
        }
    }
    
    public class UnitRegDocumentWrapper{
        public Id recordId;
        public string base64;
        public string fileName;
    }
    
    private static String saveDocument(String base64, String filename, Id documentId){       
        DocumentService objDocumentService = DocumentService.getInstance();
        Document__c objDocument = objDocumentService.getDocumentById(documentId);
        if(String.isNotBlank(objDocument.ContentDocumentId__c)){
            objDocumentService.deleteContentDocument(new ContentDocument(Id = objDocument.ContentDocumentId__c));
        }
        ContentVersion cv = objDocumentService.insertContentVersion(base64, fileName);
        Id contentDocumentId = objDocumentService.getContentDocumentId(cv.Id);
        ContentDocumentLink cdl = objDocumentService.insertContentDocumentLink(contentDocumentId, documentId);
        objDocument.ContentDocumentId__c = contentDocumentId;
        objDocumentService.updateDocument(objDocument);
        return objDocument.ContentDocumentId__c;
    }
    
    //update the unit and project record based on user selection reg date
    @AuraEnabled
    public static void updateProjectRegistration(Project__c updateProjectRecord, Boolean isProjectAlreadyRegistered){
        try {
            ProjectService ps = ProjectService.getInstance();
            
            ps.updateProject(updateProjectRecord);
            
            if(!isProjectAlreadyRegistered){
                sendProjectRegEmail(updateProjectRecord);
            }
            
        } catch(Exception e){
            throw new AuraHandledException('Error: ' + e.getMessage());   
        }
    }
    
    @AuraEnabled
    public static void updateUnitRegistration(List<Unit__c> selectedUnits, Project__c projectRecord){
        System.debug('selectedUnits'+selectedUnits);
        System.debug('projectRecord'+projectRecord);
        try {
            UnitService us = UnitService.getInstance();
            System.debug('selectedUnits'+selectedUnits);
            if(selectedUnits != null && !selectedUnits.isEmpty()){
                us.updateUnits(selectedUnits);
                sendProjectRegistrationWithUnitsEmail(projectRecord, selectedUnits);
            }
            
        } catch(Exception e){
            System.debug(e.getStackTraceString());
         System.debug(e.getLineNumber());
            throw new AuraHandledException('Error: ' + e.getMessage());   
        }
    }
    
    //update the unit and project record based on user selection reg date
    @AuraEnabled
    public static void updateADMRegDateOnUnits(List<Unit__c> selectedUnits, Project__c updateProjectRecord, Boolean isProjectAlreadyRegistered){
        try{
            ProjectService ps = ProjectService.getInstance();
            UnitService us = UnitService.getInstance();
            if(!isProjectAlreadyRegistered && selectedUnits.size() == 0) {
                ps.updateProject(updateProjectRecord);
                sendProjectRegEmail(updateProjectRecord);
            } else if(!isProjectAlreadyRegistered && selectedUnits.size() > 0) {
                ps.updateProject(updateProjectRecord);
                us.updateUnits(selectedUnits);
                sendProjectRegistrationWithUnitsEmail(updateProjectRecord, selectedUnits);
            } else if(isProjectAlreadyRegistered && selectedUnits.size() > 0) {
                us.updateUnits(selectedUnits);
                sendProjectRegistrationWithUnitsEmail(updateProjectRecord, selectedUnits);
            }
        }catch(Exception e){
            throw new AuraHandledException('Error: '+ e.getMessage());   
        }
    }
    
    //function to be used to upload registration document on the project
    @AuraEnabled
    public static void uploadFile(String base64, String filename, String recordId) {
        Savepoint sp = Database.setSavePoint();
        try{
            DocumentService documentService = DocumentService.getInstance();
            List<Document__c> unitRegDocument = documentService.getDocumentBasedonType(recordId, ADM_REG_DOC_FILE_NAME);
            saveDocument(base64, filename, unitRegDocument[0].Id);
        }catch(Exception e){
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR,'Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString()); 
            throw e;   
        }
    }
    
    @AuraEnabled
    public static void updateSalesOrderRecords(List<SalesOrder__c> selectedRecords){
        Savepoint sp = Database.setSavePoint();
        try{
            SalesOrderService service = SalesOrderService.getInstance();
            service.updateSalesOrders(selectedRecords);
        }catch(Exception e){
            Database.rollback(sp);
            throw new AuraHandledException('Error: '+ e.getMessage());   
        }
    } 
    
    //Send email when unit registration date has been added
    private static void sendUnitPropRegistrationEmail(List<SalesOrder__c> salesOrders){
        //Internal Team Members
        List<String> toAddress = new List<String>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String optTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_OPT_TEAM_EMAIL_ADDSS);
        String crmTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_EMAIL_ADDSS);
        String salesFinanceTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS);
        if(optTeamEmailAddress != null) toAddress.addAll(optTeamEmailAddress.split(','));
        if(crmTeamEmailAddress != null) toAddress.addAll(crmTeamEmailAddress.split(','));
        if(salesFinanceTeamEmailAddress != null) toAddress.addAll(salesFinanceTeamEmailAddress.split(','));
        EmailTemplate unitPropRegistrationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_UNIT_PROP_REG_EMAIL_TEMPLATE_ID));
        String emailBody = unitPropRegistrationET.HtmlValue;
        String emailSubject = unitPropRegistrationET.Subject;
        emailSubject = emailSubject.replace('[Project_Name]', salesOrders[0].Unit__r.Project__r.Name);
        String projectLink = '<a href="'+BASE_URL+ '/' + salesOrders[0].Unit__r.Project__c + '">'+salesOrders[0].Unit__r.Project__r.Name+'</a>';
        emailBody = emailBody.replace('[Project_Link]', projectLink);
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        String registrationTable = objEmailService.customUnitTableHeader();
        for(SalesOrder__c so: salesOrders){
            registrationTable += objEmailService.makeTable(so);
        }
        registrationTable += '</table>';
        emailBody = emailBody.replace('{{UNITS_TABLE}}', registrationTable);
        emailList.add(objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, noReplyOWDId)); 
        objEmailService.sendEmail(emailList);
        //List<Messaging.SendEmailResult> result = objEmailService.sendEmail(emailList);
        //System.debug('result==>'+result);
    }
    
    //Send email to customer when uni property has been registered
    private static void sendUnitPropRegistrationEmailToCustomer(List<SalesOrder__c> salesOrders){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        EmailTemplate unitPropRegistrationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_PROP_REG_CUST_EMAIL_TEMPLATE_ID));
        String emailBody = unitPropRegistrationET.HtmlValue;
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        List<String> bccAddress = new List<String>();
        String bccEmails = objMetadataService.getAppSettingTextValue(MTD_PROJ_UNIT_REG_BCC_EMAIL_ADDS);
        if(bccEmails != null) bccAddress.addAll(bccEmails.split(','));
        Map<String, List<Messaging.EmailFileAttachment>> mapOfSoIdAndAttachment = objEmailService.getAttachments(salesOrders, UNIT_REG_DOC_FILE_NAME);
        for(SalesOrder__c so: salesOrders){
            if(so.Contact__c != NULL){
                //emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(unitPropRegistrationET.Id, noReplyOWDId, so.Id, so.Contact__c, null, null, bccAddress));
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(unitPropRegistrationET.Id, noReplyOWDId, so.Id, so.Contact__c, null, null, bccAddress);
                if(mapOfSoIdAndAttachment.containsKey(so.Id)) email.setFileAttachments(mapOfSoIdAndAttachment.get(so.Id));
                emailList.add(email);
            }else if(so.Account__r.PersonContactId != null){
                //emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(unitPropRegistrationET.Id, noReplyOWDId, so.Id, so.Account__r.PersonContactId, null, null, bccAddress));
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(unitPropRegistrationET.Id, noReplyOWDId, so.Id, so.Account__r.PersonContactId, null, null, bccAddress);
                if(mapOfSoIdAndAttachment.containsKey(so.Id)) email.setFileAttachments(mapOfSoIdAndAttachment.get(so.Id));
                emailList.add(email);
            }  
        }
        objEmailService.sendEmail(emailList);
        //List<Messaging.SendEmailResult> result = objEmailService.sendEmail(emailList);
        //System.debug('result==>'+result);
    }
    
    //Send email when project registration date has been added
    private static void sendProjectRegEmail(Project__c projectRecord){
        List<String> toAddress = new List<String>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        String optTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_OPT_TEAM_EMAIL_ADDSS);
        String crmTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_EMAIL_ADDSS);
        String publicRelTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_PUBLIC_REL_TEAM_EMAIL_ADDSS);
        String salesFinanceTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS);
        if(optTeamEmailAddress != null) toAddress.addAll(optTeamEmailAddress.split(','));
        if(crmTeamEmailAddress != null) toAddress.addAll(crmTeamEmailAddress.split(','));
        if(publicRelTeamEmailAddress != null) toAddress.addAll(publicRelTeamEmailAddress.split(','));
        if(salesFinanceTeamEmailAddress != null) toAddress.addAll(salesFinanceTeamEmailAddress.split(','));
        Id projectRegEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_PROJECT_REG_EMAIL_TEMPLATE_ID);
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        emailList.add(objEmailService.getSingleEmailMessageWithoutTargetObjectId(projectRegEmailTemplateId, noReplyOWDId, projectRecord.Id, toAddress, null, null));         
        objEmailService.sendEmail(emailList);
        //List<Messaging.SendEmailResult> result = objEmailService.sendEmail(emailList);
        //System.debug('result==>'+result);
    }
    
    //Send email when project registration date and unit registration date has been added
    private static void sendProjectRegistrationWithUnitsEmail(Project__c projectRecord, List<Unit__c> registeredUnits){
        UnitService uService = UnitService.getInstance();
        List<Unit__c> units = uService.getRegisteredUnitById(registeredUnits);
        List<String> toAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();    
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String optTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_OPT_TEAM_EMAIL_ADDSS);
        String crmTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_EMAIL_ADDSS);
        String publicRelTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_PUBLIC_REL_TEAM_EMAIL_ADDSS);
        String salesFinanceTeamEmailAddress = objMetadataService.getAppSettingTextValue(MTD_SALES_FINANCE_TEAM_EMAIL_ADDSS);
        if(optTeamEmailAddress != null) toAddress.addAll(optTeamEmailAddress.split(','));
        if(crmTeamEmailAddress != null) toAddress.addAll(crmTeamEmailAddress.split(','));
        if(salesFinanceTeamEmailAddress != null) toAddress.addAll(salesFinanceTeamEmailAddress.split(','));
        if(publicRelTeamEmailAddress != null) toAddress.addAll(publicRelTeamEmailAddress.split(','));
        //Send email as a unit registration table
        EmailTemplate projectRegWithUnitsEmailTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_PROJECT_REG_WITH_UNITS_EMAIL_TEMPLATE_ID));
        if(projectRegWithUnitsEmailTemplate == null){
            throw new AuraHandledException('Project registration email template not found.');
        }
        if(units == null || units.isEmpty()) {
            System.debug('No registered units found to send email.');
            return;
        }
        String registrationTable = objEmailService.customUnitTableHeader();
        for(Unit__c unit : units) {
            try {
                if(unit != null) {
                    registrationTable += objEmailService.makeTable(unit);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,'Skipping Unit ' + (unit != null ? unit.Id : 'NULL') +'. Error: ' + e.getMessage());
                continue;
            }
        }
        projectRecord = getProjectRecord(projectRecord.Id);
        System.debug('projectRecord'+projectRecord);
        if(projectRecord == null){
            throw new AuraHandledException('Project record not found.');
        }
        String projectLink = '<a href="'+BASE_URL+ '/' + projectRecord.Id + '">'+projectRecord.Name+'</a>';
        String emailSubject = projectRegWithUnitsEmailTemplate.Subject;
        emailSubject = emailSubject.replace('[Project_Name]', projectRecord.Name);
        String emailBody = projectRegWithUnitsEmailTemplate.HtmlValue;
        registrationTable += '</table>';
        emailBody = emailBody.replace('{{UNIT_REGISTRATION_TABLE}}', registrationTable);
        emailBody = emailBody.replace('[Project_Name]', projectRecord.Name);
        emailBody = emailBody.replace('[Project_Link]', projectLink);
        emailBody = emailBody.replace('[Project_Registration_Date]', (projectRecord.ProjectRegistrationDate__c != null ? String.valueOf(projectRecord.ProjectRegistrationDate__c): ''));
        emailList.add(objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, noReplyOWDId)); 
        objEmailService.sendEmail(emailList);
        //List<Messaging.SendEmailResult> result = objEmailService.sendEmail(emailList);
        //System.debug('result==>'+result);
    }
    
    @AuraEnabled
    public static Project__c getUnitsByProject(Id projectId) {
        //return [SELECT Id, Name, IsMortgageReleased__c FROM Unit__c WHERE Project__c = :projectId AND IsMortgageReleased__c = false ];
        /* return [SELECT Id, Name, ProjectRegistrationDate__c, ProjectRegistrationRemark__c, (SELECT),
(SELECT Id, Name, RegistrationDate__c, Active_Sales_Order__c, ADM_Fee_Included__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.SoldDate__c, 
Status__c, Active_Sales_Order__r.UnitRegistrationDate__c, Active_Sales_Order__r.DocumentUploadedDate__c, ADMPlotNumber__c,
Active_Sales_Order__r.FundMovedToGRDate__c, Active_Sales_Order__r.Status__c,
Active_Sales_Order__r.Account__r.IsPersonAccount, Active_Sales_Order__r.Account__r.FirstName, Active_Sales_Order__r.Account__r.LastName, Active_Sales_Order__r.Account__r.Name, IsMortgageReleased__c
FROM UnitsProject__r 
WHERE Active_Sales_Order__c != null AND IsMortgageReleased__c = false)
FROM Project__c 
WHERE Id = :projectId ]; */
        
        return [SELECT Id, Name, ProjectRegistrationDate__c, ProjectRegistrationRemark__c, 
                (SELECT Id, Unit__c, Unit__r.Name, Unit__r.RegistrationDate__c, Unit__r.Active_Sales_Order__c, Unit__r.ADM_Fee_Included__c, 
                 Unit__r.Active_Sales_Order__r.Name, Unit__r.Active_Sales_Order__r.SoldDate__c, Unit__r.Status__c, 
                 Unit__r.Active_Sales_Order__r.UnitRegistrationDate__c, Unit__r.Active_Sales_Order__r.DocumentUploadedDate__c, 
                 Unit__r.ADMPlotNumber__c, Unit__r.Active_Sales_Order__r.FundMovedToGRDate__c, Unit__r.Active_Sales_Order__r.Status__c,
                 Unit__r.Active_Sales_Order__r.Account__r.IsPersonAccount, Unit__r.Active_Sales_Order__r.Account__r.FirstName, 
                 Unit__r.Active_Sales_Order__r.Account__r.LastName, Unit__r.Active_Sales_Order__r.Account__r.Name, Unit__r.IsMortgageReleased__c 
                 FROM Handovers__r 
                 WHERE Unit__r.Active_Sales_Order__c != null 
                 //AND Unit__r.IsMortgageReleased__c = false
                 AND IsADRECApproved__c = false
                 ORDER BY Unit__r.Name) 
                FROM Project__c 
                WHERE Id = :projectId];
    }
    
    /* @AuraEnabled
public static void updateUnits(List<Unit__c> unitsToUpdate) {
System.debug('unitsToUpdate'+unitsToUpdate);
if(unitsToUpdate != null && !unitsToUpdate.isEmpty()) {
update unitsToUpdate;
}
} */
    
    @AuraEnabled
    public static void updateUnits(List<Handover__c> handoversToUpdate) {
        if(handoversToUpdate != null && !handoversToUpdate.isEmpty()) {
            update handoversToUpdate;
        }
    }
    
    @AuraEnabled
    public static List<InstallmentLines__c> getAllInstallmentLine(Id projectId, Date dueDate) {
        InstallmentLineService service = InstallmentLineService.getInstance();
        List<InstallmentLines__c> lstInstallmentLine = new List<InstallmentLines__c>();
        lstInstallmentLine = service.getInstallmentLinesByProjectAndDueDate(projectId, dueDate);
        if (lstInstallmentLine.isEmpty()) {
            throw new AuraHandledException('No Installment Line found for the Project.');
        }
        return lstInstallmentLine;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getProjectClassifications(Id projectId){
        PaymentPlanService objPaymentPlanService = PaymentPlanService.getInstance();
        List<String> classifications = new List<String>();
        List<PaymentPlan__c> lstPaymentPlan = objPaymentPlanService.getClassificationFromPaymentPlan(projectId);
        for(PaymentPlan__c pp : lstPaymentPlan){
            if(!classifications.contains(pp.Classification__c)){
                classifications.add(pp.Classification__c);
            }
        }
        return classifications;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PaymentPlan__c> getPaymentPlans(Id projectId, String classification){
        PaymentPlanService objPaymentPlanService = PaymentPlanService.getInstance();
        return objPaymentPlanService.getPaymentPlansClassification(projectId,classification);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PaymentInstallments__c> getInstallmentsByPlan(Id paymentPlanId){
        PaymentInstallmentService objPaymentInstallmentService = PaymentInstallmentService.getInstance();
        return objPaymentInstallmentService.getPaymentInstallmentsByPaymentPlanId(paymentPlanId);
    }
    
    @AuraEnabled(cacheable=true)
    public static Integer getActiveSalesOrderCount(Id paymentPlanId) {
		SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String invalidSalesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_PAYMENT_PLAN_INVALID_SALES_ORDER_STATUS_VALUE);
        List<String> invalidSalesOrderStatusValueList = invalidSalesOrderStatusValue.split(',');
        return objSalesOrderService.getActiveSalesOrdersByPaymentPlanIds(paymentPlanId,invalidSalesOrderStatusValueList);
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean isPaymentPlanPendingApproval(Id paymentPlanId){  
        if (paymentPlanId == null) {
            return false;
        }
        List<ProcessInstance> pendingApprovals = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :paymentPlanId AND Status = 'Pending' LIMIT 1];
        return !pendingApprovals.isEmpty();
    }
    
    @AuraEnabled
    public static void updateInstallmentLineRecords(List<PaymentInstallments__c> selectedRecords, Id paymentPlanId){
        PaymentPlanService objPaymentPlanService = PaymentPlanService.getInstance();
        PaymentInstallmentService objPaymentInstService = PaymentInstallmentService.getInstance();
        ContentService objContentService = ContentService.getInstance();
        ContentDocumentLinkService objContentDocumentLinkService = ContentDocumentLinkService.getInstance();
        Savepoint sp = Database.setSavePoint();
        try{
            List<PaymentInstallments__c> lstUpdatePaymentInstallments = new List<PaymentInstallments__c>();
            for(PaymentInstallments__c rec : selectedRecords){
                PaymentInstallments__c updRec = new PaymentInstallments__c(Id = rec.Id);
                if(rec.RevisedDate__c != null){
                    updRec.RevisedDate__c = rec.RevisedDate__c;
                    updRec.RevisedDateUpdated__c = true;
                    updRec.ChequeReplacement__c = rec.ChequeReplacement__c;
                }
                lstUpdatePaymentInstallments.add(updRec);
            }
            objPaymentInstService.updatepaymentInstallmentLists(lstUpdatePaymentInstallments);
            
            PaymentPlan__c paymentPlan =new PaymentPlan__c(Id = paymentPlanId,ApprovalStatus__c = 'Pending for Approval');
            objPaymentPlanService.updatePaymentPlan(paymentPlan);
            
            // Submit for Approval
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(paymentPlanId);
            Approval.ProcessResult result = Approval.process(req);
            if(!result.isSuccess()){
                String approvalError = 'Approval submission failed.';
                if(result.getErrors() != null && result.getErrors().size() > 0){
                    approvalError = result.getErrors()[0].getMessage();
                }
                throw new AuraHandledException(approvalError);
            }
        }
        catch(Exception e){
            Database.rollback(sp);
            String errorMessage = e.getMessage();
            if(errorMessage != null){
                if(errorMessage.contains('ALREADY_IN_PROCESS')){
                    errorMessage = 'This Payment Plan is already submitted for approval.';
                }
                else if(errorMessage.contains('ENTITY_IS_LOCKED')){
                    errorMessage = 'This Payment Plan is locked due to an approval process.';
                }
                else if(errorMessage.contains('NO_APPLICABLE_PROCESS')){
                    errorMessage = 'No approval process found for this Payment Plan.';
                }
            }
            throw new AuraHandledException(errorMessage);
        }
    }
}
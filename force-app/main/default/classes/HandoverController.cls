/***
Class       : HandoverController
Author      : Antriksh 
Description : Class used for mainly send the bulk emails for handover.
TestClass   : HandoverControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version    ¯          Date                Details
1.          V1.0              21/11/25           Initial Version 
2.          V1.0              26/03/2026         optimised the data loading related methods and made faster.
****************************************************************************************************************/
public without sharing class HandoverController {
    
    private static final string DOCUMENT_TYPE_HO_SOA { get { return 'SOA'; } }
    private static final string DOCUMENT_TYPE_PROJECT_BCC { get { return 'BCC Announcement'; } }
    private static final string DOCUMENT_TYPE_CHO_DeSnagging_Report { get { return 'CHO Desnagging Report'; } }
    private static final string DOCUMENT_TYPE_GUIDELINES_ARABIC { get { return 'Guideline 1 Arabic'; } }
    private static final string DOCUMENT_TYPE_GUIDELINES_ENGLISH { get { return 'Guideline 1'; } }
    private static final string MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string NOC_EMAIL_TEMPLATE_NAME { get { return 'Notice of Completion Template'; } }
    private static final string NOC_CHO_EMAIL_TEMPLATE_NAME { get { return 'NOC_CHO Email Template'; } }
    private static final String EMAIL_PPROGRESS_MSG = 'Records submitted successfully. We will send you a mail once the record will be completely processed.';
    private static final string HANDOVER_DOORNUMBER_EMAIL_TEMPLATE_NAME { get { return 'Handover Notice Door Number email communication'; } }
    
    
    @AuraEnabled
    public static String sendBCCEmails(List<Id> recordIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            HandoverService objHandoverService = HandoverService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            MetadataService handoverMetadataService = MetadataService.getInstance();
            DocumentService objDocumentService = DocumentService.getInstance();
            ContentService objContentService = ContentService.getInstance();
            
            EmailMessageService objEmailMessageService = EmailMessageService.getInstance();
            
            Id orgWideEmailAddressId = handoverMetadataService.getAppSettingTextValue(MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID);
            List<Handover__c> handoverUpdateList = new List<Handover__c>();
            List<Attachment> attachmentListOnActivity = new List<Attachment>();
            List<Messaging.SendEmailResult> emailResultList = new List<Messaging.SendEmailResult>();
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            Map<Id, List<Id>> HandoverPhaseToHandoverMap = new Map<Id, List<Id>>();
            Map<Id, Handover__c> handoverMap = new Map<Id, Handover__c>(objHandoverService.getHandoverRecordsByUnitId(new Set<Id>(recordIds)));
            Set<Id> templateIds = new Set<Id>();
            System.debug('handovermap'+handoverMap.values());
            for(Handover__c ho : handoverMap.values()) {
                if(ho.Handover_Phase__r.BCCEmailTemplateId__c != null) {
                    templateIds.add(ho.Handover_Phase__r.BCCEmailTemplateId__c);
                }
            }
            
            Map<Id, EmailTemplate> templateMap = new Map<Id, EmailTemplate>();
            if(!templateIds.isEmpty()){
                templateMap = objEmailService.getEmailTemplatesByIds(templateIds);
            }
            Set<Id> handoverPhaseIds = new Set<Id>();
            Map<Id, List<Document__c>> documentMap = new Map<Id, List<Document__c>>();
            
            if(!handoverMap.isEmpty()){
                for (Handover__c ho : handoverMap.values()) {
                    if (ho.Handover_Phase__c != null) {
                        handoverPhaseIds.add(ho.Handover_Phase__c);
                        if (!HandoverPhaseToHandoverMap.containsKey(ho.Handover_Phase__c)) {
                            HandoverPhaseToHandoverMap.put(ho.Handover_Phase__c, new List<Id>());
                        }
                        HandoverPhaseToHandoverMap.get(ho.Handover_Phase__c).add(ho.Id);
                    }
                }
                
                
                List<Document__c> docList = new List<Document__c>();
                if (!handoverPhaseIds.isEmpty()) { 
                    docList = objDocumentService.getDocumentsByParentIdsAndType(handoverPhaseIds, DOCUMENT_TYPE_PROJECT_BCC, HandoverPhase__c.SobjectType);
                    
                }
                
                Set<Id> contentDocumentIds = new Set<Id>();
                for(Document__c docRec : docList){
                    if (docRec.HandoverPhase__c != null && docRec.DocumentType__r.Type__c == DOCUMENT_TYPE_PROJECT_BCC) {
                        List<Id> hoIds = HandoverPhaseToHandoverMap.get(docRec.HandoverPhase__c);
                        
                        for (Id hoId : hoIds) {
                            if (!documentMap.containsKey(hoId)) {
                                documentMap.put(hoId, new List<Document__c>());
                            }
                            documentMap.get(hoId).add(docRec);
                        }
                        contentDocumentIds.add(docRec.ContentDocumentId__c);
                    }
                }
                
                Map<Id, ContentVersion> cvMap = objContentService.getContentVersionsByContentDocumentIds(contentDocumentIds);
                
                for(Handover__c objHandover :handoverMap.values()){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                    
                    Id targetTempId = objHandover.Handover_Phase__r.BCCEmailTemplateId__c;
                    if(targetTempId == null || !templateMap.containsKey(targetTempId)) continue;
                    
                    EmailTemplate mailTemplate = templateMap.get(targetTempId);
                    List<Document__c> docs = documentMap.get(objHandover.Id);
                    
                    if (docs != null) {
                        
                        for (Document__c objDocument : docs) {
                            
                            ContentVersion objCV = cvMap.get(objDocument.ContentDocumentId__c);
                            if (objCV != null) {
                                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                                attachment.setFileName(objCV.Title);
                                attachment.setBody(objCV.VersionData);
                                attachment.setInline(false);
                                if(objCV.FileExtension == 'pdf'){
                                    attachment.setContentType('application/pdf');
                                }else if(objCV.FileExtension == 'png'){
                                    attachment.setContentType('image/png');
                                }else if(objCV.FileExtension == 'jpeg' || objCV.FileExtension == 'jpg'){
                                    attachment.setContentType('image/jpeg');
                                }
                                attachmentList.add(attachment);
                            }
                        }}
                    
                    mail.setToAddresses(new List<String>{objHandover.Contact__c});
                    mail.setSubject(getDynamicSubject(mailTemplate.Subject, objHandover));
                    mail.setUseSignature(true);
                    mail.setHtmlBody(getDynamicBody(mailTemplate.HtmlValue, objHandover,null));
                    mail.setWhatId(objHandover.Id);
                    mail.setSaveAsActivity(true);
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressId); 
                    mail.setFileAttachments(attachmentList);
                    mailList.add(mail);
                }
                
                emailResultList = objEmailService.sendEmail(mailList);
                
                for (Messaging.SendEmailResult res : emailResultList) {
                    if (!res.isSuccess()) {
                        String locErr = res.getErrors()[0].getMessage();
                        throw new AuraHandledException('Email failed: ' + locErr);
                    }
                }
                
                Map<Id, EmailMessage> objEmailMessageMap = objEmailMessageService.getLatestEmailMessageByRelatedIds(handoverMap.keyset());
                if(!emailResultList.isEmpty()){
                    for(Integer i = 0; i < emailResultList.size(); i++){
                        if(emailResultList[i].isSuccess()){
                            Id handoverId = mailList[i].whatId;
                            if(objEmailMessageMap.containsKey(handoverId) && !objEmailMessageMap.isEmpty() ){
                                EmailMessage objEmailMessage = objEmailMessageMap.get(handoverId);
                                
                                List<Document__c> docs = documentMap.get(handoverId);
                                if (docs != null) {
                                    
                                    for (Document__c objDocument : docs) {
                                        ContentVersion objCV = cvMap.get(objDocument.ContentDocumentId__c);
                                        if (objCV != null) {
                                            Attachment att = new Attachment();
                                            att.ParentId = objEmailMessage.Id;
                                            String baseName = objCV.Title;
                                            String ext = objContentService.mimeTypeToFileExtensionsMap.get(objCV.FileExtension);                               
                                            String extension = (objCV.FileExtension != null) ? objCV.FileExtension.toLowerCase() : 'pdf';
                                            
                                            // Repeatedly remove the extension if it's duplicated
                                            while (baseName.toLowerCase().endsWith('.' + extension + '.' + extension)) {
                                                baseName = baseName.substring(0, baseName.length() - (extension.length() + 1));
                                            }
                                            
                                            // If it ends with extension once, leave it. If not, add it.
                                            if (!baseName.toLowerCase().endsWith('.' + extension)) {
                                                baseName += '.' + extension;
                                            }
                                            
                                            att.Name = baseName;
                                            
                                            att.Body = objCV.VersionData;
                                            attachmentListOnActivity.add(att);
                                        }
                                    }}
                                handoverUpdateList.add(new Handover__c(Id = handoverId, Is_BCC_Announcement_Sent__c = true));
                            }
                            
                        }
                    }
                }
                objEmailMessageService.insertEmailAttachment(attachmentListOnActivity);
                HandoverService.getInstance().updateHandoversWithoutTrigger(handoverUpdateList);
                
            }
            
            return EMAIL_PPROGRESS_MSG;
        } catch (Exception e) {
            
            Database.rollback(sp); 
            throw new AuraHandledException('Error sending emails: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String sendNOCCHOEmail(List<Id> recordIds, Id ProjectId, List<Id> salesorderIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            HandoverService objHandoverService = HandoverService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            MetadataService handoverMetadataService = MetadataService.getInstance();
            DocumentService objDocumentService = DocumentService.getInstance();
            ContentService objContentService = ContentService.getInstance();
            UnitService objUnitService = UnitService.getInstance();
            EmailMessageService objEmailMessageService = EmailMessageService.getInstance();
            
            Id orgWideEmailAddressId = handoverMetadataService.getAppSettingTextValue(MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID);
            //  EmailTemplate mailTemplate = objEmailService.getEmailTemplateByName(NOC_CHO_EMAIL_TEMPLATE_NAME);
            
            List<Handover__c> handoverUpdateList = new List<Handover__c>();
            List<Attachment> attachmentListOnActivity = new List<Attachment>();
            List<Messaging.SendEmailResult> emailResultList = new List<Messaging.SendEmailResult>();
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            List<Handover__c> successfulHandovers = new List<Handover__c>();
            List<Unit__c> unitsToUpdate = new List<Unit__c>();
            Set<Id> templateIds = new Set<Id>();
            Map<Id, Handover__c> handoverMap = new Map<Id, Handover__c>(objHandoverService.getNOCHOByHandoverIds(new Set<Id>(recordIds)));
            for(Handover__c ho : handoverMap.values()) {
                if(ho.Handover_Phase__r.NOCCHOEmailtemplateId__c != null) {
                    templateIds.add(ho.Handover_Phase__r.NOCCHOEmailtemplateId__c);
                }
            }
            Map<Id, EmailTemplate> templateMap = new Map<Id, EmailTemplate>();
            if(!templateIds.isEmpty()){
                templateMap = objEmailService.getEmailTemplatesByIds(templateIds);
            }
            System.debug('templateMap'+templateMap);
            // 1. Convert incoming List to Set
            Set<Id> salesOrderIdsSet = new Set<Id>(salesorderIds);
            List<InstallmentLines__c> allInstallments = objHandoverService.getSOInstallmentPendingAmt(salesOrderIdsSet);
            Map<Id, Decimal> soToPendingAmountMap = new Map<Id, Decimal>();
            
            for(InstallmentLines__c line : allInstallments) {
                Decimal pending = (line.PendingAmount__c != null) ? line.PendingAmount__c : 0;
                soToPendingAmountMap.put(line.SalesOrder__c, pending);
            }
            
            // 2. Fetch Shared Project Documents (Guidelines) into the correct variable
            List<Document__c> projectDocList = new List<Document__c>();
            if (ProjectId != null) {
                projectDocList = objDocumentService.getDocumentsByParentIdsAndType(new Set<Id>{ProjectId}, DOCUMENT_TYPE_GUIDELINES_ARABIC, Project__c.SobjectType);
                projectDocList.addAll(objDocumentService.getDocumentsByParentIdsAndType(new Set<Id>{ProjectId}, DOCUMENT_TYPE_GUIDELINES_ENGLISH, Project__c.SobjectType));
            }
            System.debug('projectDocList'+projectDocList);
            // 3. Fetch and Map Handover-Specific Documents (SOA)
            List<Document__c> handoverDocList = objDocumentService.getDocumentsByParentIdsAndType(handoverMap.keySet(), DOCUMENT_TYPE_HO_SOA, Handover__c.SobjectType);
            Map<Id, List<Document__c>> handoverToDocsMap = new Map<Id, List<Document__c>>();
            for (Document__c docRec : handoverDocList) {
                if (!handoverToDocsMap.containsKey(docRec.Handover__c)) {
                    handoverToDocsMap.put(docRec.Handover__c, new List<Document__c>());
                }
                handoverToDocsMap.get(docRec.Handover__c).add(docRec);
            }
            
            // 4. Build Content Document ID Set for Mass Querying Content Versions
            Set<Id> contentDocumentIds = new Set<Id>();
            for (Document__c d : projectDocList) {
                contentDocumentIds.add(d.ContentDocumentId__c);
            }
            for (Document__c d : handoverDocList) {
                contentDocumentIds.add(d.ContentDocumentId__c);
            }
            
            Map<Id, ContentVersion> cvMap = objContentService.getContentVersionsByContentDocumentIds(contentDocumentIds);
            
            mailList = buildNOCCHOandoverEmails(handoverMap.values(), projectDocList,handoverToDocsMap,cvMap, soToPendingAmountMap,templateMap, orgWideEmailAddressId);
            
            // 6. Send Emails
            emailResultList = objEmailService.sendEmail(mailList);
            for (Messaging.SendEmailResult res : emailResultList) {
                if (!res.isSuccess()) {
                    String locErr = res.getErrors()[0].getMessage();
                    throw new AuraHandledException('Email failed: ' + locErr);
                }
            }
            
            
            Map<Id, EmailMessage> objEmailMessageMap = objEmailMessageService.getLatestEmailMessageByRelatedIds(handoverMap.keyset());
            
            if(!emailResultList.isEmpty()){ 
                for(Integer i = 0; i < emailResultList.size(); i++){
                    if(emailResultList[i].isSuccess()){
                        Id handoverId = mailList[i].whatId;
                        
                        Handover__c currentHandover = handoverMap.get(handoverId);
                        successfulHandovers.add(currentHandover);
                        
                        if(objEmailMessageMap.containsKey(handoverId)){
                            EmailMessage objEmailMessage = objEmailMessageMap.get(handoverId);
                            
                            
                            List<Document__c> docsForActivity = new List<Document__c>();
                            docsForActivity.addAll(projectDocList);
                            if (handoverToDocsMap.containsKey(handoverId)) {
                                docsForActivity.addAll(handoverToDocsMap.get(handoverId));
                            }
                            
                            for (Document__c objDocument : docsForActivity) {
                                ContentVersion objCV = cvMap.get(objDocument.ContentDocumentId__c);
                                if (objCV == null) continue;
                                
                                Attachment att = new Attachment();
                                att.ParentId = objEmailMessage.Id;
                                att.Body = objCV.VersionData;
                                
                                String baseName = objCV.Title;
                                String extension = (objCV.FileExtension != null) ? objCV.FileExtension.toLowerCase() : 'pdf';
                                
                                while (baseName.toLowerCase().endsWith('.' + extension + '.' + extension)) {
                                    baseName = baseName.substring(0, baseName.length() - (extension.length() + 1));
                                }
                                
                                if (!baseName.toLowerCase().endsWith('.' + extension)) {
                                    baseName += '.' + extension;
                                }
                                
                                att.Name = baseName;
                                attachmentListOnActivity.add(att);
                            }
                        }
                        
                        handoverUpdateList.add(new Handover__c(
                            Id = handoverId,
                            Is_Notice_of_Completion_Sent__c = true,
                            Is_Orientation_Letter_Sent__c = true,
                            Home_Orientation_Invitation_Date__c = Date.today(),
                            HomeOrientationInvitationDate__c = Date.today().addDays(14),
                            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,            
                            Notice_of_Completion_Date__c = Date.today(),
                            Unit_is_Ready__c = true,
                            NOC_Date__c = Date.today().addDays(30)
                        ));
                        
                        if(currentHandover.Unit__c != null) {
                            unitsToUpdate.add(new Unit__c(Id = currentHandover.Unit__c, NOCExpiryDate__c = Date.today().addYears(1)));
                        }
                    } 
                }
            }
            
            
            if (!successfulHandovers.isEmpty()) {
                sendHandoverNoticeDoorEmails(successfulHandovers, handoverUpdateList, orgWideEmailAddressId);
            }
            
            
            objEmailMessageService.insertEmailAttachment(attachmentListOnActivity);
            objHandoverService.updateHandovers(handoverUpdateList);
            objUnitService.updateUnitsWithoutTrigger(unitsToUpdate);
            
            
            return EMAIL_PPROGRESS_MSG;
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Failed to send orientation emails: ' + e.getLineNumber()+ ' ' + e.getMessage());
        }
    }
    
    public static String getDynamicSubject(String subject, Handover__c handover){
        subject = subject.replace('{{{Handover__c.Unit_Code__c}}}',String.isNotBlank(handover.Unit_Code__c) ? handover.Unit_Code__c :'N/A');
        subject = subject.replace('{{{Handover__c.Name}}}', String.isNotBlank(handover.Name)?handover.Name : 'N/A');
        subject = subject.replace('{{{Handover__c.Project_Name_Arabic__c}}}',String.isNotBlank(handover.ProjectNameArabic__c)? handover.ProjectNameArabic__c : String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        subject = subject.replace('{{{Handover__c.Project_Name__c}}}',String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        
        
        return subject;
    }
    
    public static String getDynamicBody(String body, Handover__c handover,Decimal pendingAmount){
        
        body = body.replace('{{{Handover__c.Name}}}', String.isNotBlank(handover.Name)?handover.Name : 'N/A');//Done
        body = body.replace('{{{Handover__c.Customer_Name__c}}}',String.isNotBlank(handover.Customer_Name__c) ? handover.Customer_Name__c : 'N/A');// Done
        body = body.replace('{{{Handover__c.customerNameWOTitle}}}',String.isNotBlank(handover.Account__r.Name) ? handover.Account__r.Name : 'N/A');// Done
        body = body.replace('{!Handover__c.Sub_Status__c}', String.isNotBlank(handover.Sub_Status__c) ? handover.Sub_Status__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Unit_Code__c}}}',String.isNotBlank(handover.Unit_Code__c) ? handover.Unit_Code__c :'N/A');
        body = body.replace('{{{Handover__c.Project_Name__c}}}',String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Name__c}}}',String.isNotBlank(handover.Account_Manager_Name__c)? handover.Account_Manager_Name__c : 'N/A');// Done
        body = body.replace('{{{Handover__c.AccountManagerEmail__c}}}',String.isNotBlank(handover.Account_Manager_Email__c)? handover.Account_Manager_Email__c : 'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Phone__c}}}',String.isNotBlank(handover.Account_Manager_Phone__c)? handover.Account_Manager_Phone__c : 'N/A');// done
        body = body.replace('{{{Handover__c.HO_DD_MM_YYYY__c}}}', handover.HO_DD_MM_YYYY__c != null ? String.valueOf(handover.HO_DD_MM_YYYY__c) : 'N/A');
        body = body.replace('{{{Handover__c.Location__c}}}',String.isNotBlank(handover.Location__c) ? handover.Location__c : 'N/A');
        body = body.replace('{{{Handover__c.Location_Name__c}}}', String.isNotBlank(handover.Location_Name__c) ? handover.Location_Name__c : 'N/A'); 
        body = body.replace('{{{Handover__c.Date__c}}}', handover.Date__c != null ? String.valueOf(handover.Date__c) : 'N/A');
        body = body.replace('{{{Handover__c.Customer_Email__c}}}', String.isNotBlank(handover.CustomerEmail__c)? handover.CustomerEmail__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Promise_to_Pay_Date__c}}}',handover.Promise_to_Pay_Date__c != null ? String.valueOf(handover.Promise_to_Pay_Date__c) : 'N/A');
        body = body.replace('{{{Handover__c.Customer_Number__c}}}',handover.Customer_Number__c  != null ? String.valueOf(handover.Customer_Number__c) : 'N/A');
        body = body.replace('{{{Handover__c.Address__c}}}',handover.Address__c != null ? String.valueOf(handover.Address__c) : 'N/A');
        body = body.replace('{{{Handover__c.Project__r.Handover_Community_Guidelines_English__c}}}',handover.Project__r.Handover_Community_Guidelines_English__c != null ? String.valueOf(handover.Project__r.Handover_Community_Guidelines_English__c) : 'N/A');
        body = body.replace('{{{Handover__c.Project__r.Handover_Community_Guidelines_Arabic__c}}}',handover.Project__r.Handover_Community_Guidelines_Arabic__c != null ? String.valueOf(handover.Project__r.Handover_Community_Guidelines_Arabic__c) : 'N/A');
        
        body = body.replace('{{{Handover__c.NOC_Expiry_Date__c}}}',handover.NOC_Expiry_Date__c != null ? String.valueOf(handover.NOC_Expiry_Date__c) : 'N/A');
        body = body.replace('{{{Handover__c.Purchase_Price__c}}}',handover.Purchase_Price__c != null ? String.valueOf(handover.Purchase_Price__c) : 'N/A');
        body = body.replace('{{{Handover__c.Unit_Plot_Number__c}}}',handover.Unit_Plot_Number__c != null ? String.valueOf(handover.Unit_Plot_Number__c) : 'N/A');
        body = body.replace('{{{Handover__c.Unit__r.DoorNumber__c}}}',handover.Unit__r.DoorNumber__c != null ? String.valueOf(handover.Unit__r.DoorNumber__c) : 'N/A');
        body = body.replace('{{{Handover__c.Unit__r.Name}}}',handover.Unit__r.Name != null ? String.valueOf(handover.Unit__r.Name) : 'N/A');
        body = body.replace('{{{Handover__c.unit__r.UnitNumber__c}}}',handover.unit__r.UnitNumber__c != null ? String.valueOf(handover.unit__r.UnitNumber__c) : 'N/A');
        
        
        if(handover.SettlementFollowUpDate__c != null){
            body = body.replace('{{{Handover__c.SettlementFollowUpDate__c}}}', String.valueOf(handover.SettlementFollowUpDate__c) != null ? String.valueOf(handover.SettlementFollowUpDate__c) : 'N/A');
        }
        if(handover.NOC_Date__c != null){
            body = body.replace('{{{Handover__c.NOC_Date__c}}}', String.valueOf(handover.NOC_Date__c) != null ? String.valueOf(handover.NOC_Date__c) : 'N/A');
            
        }
        if(handover.HomeOrientationInvitationDate__c != null){
            body = body.replace('{{{Handover__c.HomeOrientationInvitationDate__c}}}', String.valueOf(handover.HomeOrientationInvitationDate__c) != null ? String.valueOf(handover.HomeOrientationInvitationDate__c) : 'N/A');
        }
        
        // arabic
        body = body.replace('{{{Handover__c.Customer_Name_Arabic__c}}}',String.isNotBlank(handover.Customer_Name_Arabic__c) ? handover.Customer_Name_Arabic__c :  String.isNotBlank(handover.Customer_Name__c) ? handover.Customer_Name__c : 'N/A');// done
        body = body.replace('{{{Handover__c.CustomNameArabicWOTitle}}}',String.isNotBlank(handover.Account__r.NameinArabic__c) ? handover.Account__r.NameinArabic__c :  String.isNotBlank(handover.Account__r.Name) ? handover.Account__r.Name : 'N/A');// done
        body = body.replace('{{{Handover__c.Project_Name_Arabic__c}}}',String.isNotBlank(handover.ProjectNameArabic__c)? handover.ProjectNameArabic__c : String.isNotBlank(handover.ProjectbyFormula__c)? handover.ProjectbyFormula__c : 'N/A');
        body = body.replace('{{{Handover__c.Unit_Code__c}}}',String.isNotBlank(handover.Unit_Code__c) ? handover.Unit_Code__c :'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Name_Arabic__c}}}',String.isNotBlank(handover.Account_Manager_Name_Arabic__c)? handover.Account_Manager_Name_Arabic__c : String.isNotBlank(handover.Account_Manager_Name__c)? handover.Account_Manager_Name__c : 'N/A');// done
        body = body.replace('{{{Handover__c.AccountManagerEmail__c}}}', String.isNotBlank(handover.Account_Manager_Email__c)? handover.Account_Manager_Email__c : 'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Phone__c}}}',String.isNotBlank(handover.Account_Manager_Phone__c)? handover.Account_Manager_Phone__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Location__c}}}',String.isNotBlank(handover.LocationName__c) ? handover.LocationName__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Bloom_Phone__c}}}', String.isNotBlank(handover.BloomPhone__c) ? handover.BloomPhone__c : 'N/A');
        body = body.replace('{{{Handover__c.Bloom_Email__c}}}', String.isNotBlank(handover.BloomEmail__c) ? handover.BloomEmail__c : 'N/A');
        
        // format() adds thousand separators (commas) and follows locale settings
        String formattedAmount = (pendingAmount != null) ? pendingAmount.setScale(2).format() : '0.00';
        
        body = body.replace('{{{Handover__c.Pending_Amount}}}', formattedAmount);
        
        return body;
    }
    
    @AuraEnabled
    public static Map<String, String> getProjects() {
        Map<String, String> projectsMap = new Map<String, String>();
        
        for (Project__c project : ProjectService.getInstance().getAvailableHandoverProject()) {      
            projectsMap.put(project.Id, project.Name);            
        }
        return projectsMap;
    }
    
    @AuraEnabled
    public static Map<String, String> getHandoverPhase(Id projectId) {
        Map<String, String> handoverPhasesMap = new Map<String, String>();
        
        for (HandoverPhase__c handoverPhase : HandoverPhaseService.getInstance().getHandoverPhase(projectId)) {
            handoverPhasesMap.put(handoverPhase.Id, handoverPhase.Name);
        }
        return handoverPhasesMap;
    }
    
    @AuraEnabled
    public static String getHandoverData(Id projectId, Id handoverPhaseId, String type) {
        String data;
        HandoverService objHandoverService = HandoverService.getInstance();
        List<HandoverDataWrapper> wrapList = new List<HandoverDataWrapper>();
        
        try {
            List<Handover__c> handoverList = new List<Handover__c>();
            
            if (type == 'BCC') {
                
                handoverList = objHandoverService.getBCCWithHandoverPhaseAndProjectId(projectId, handoverPhaseId);
                
            }
            else if (type == 'NOC-CHO') {
                handoverList = objHandoverService.getNOCCHOHandoversBasedOnProjectAndHandoverPhaseId(projectId, handoverPhaseId);
            }
            System.debug('handoverList'+handoverList);   
            if (!handoverList.isEmpty()){
                Set<Id> handoverIds = new Map<Id, Handover__c>(handoverList).keySet();
                Map<Id, Map<String, Id>> docMapByHandover = new Map<Id, Map<String, Id>>();
                
                List<Document__c> docList = DocumentService.getInstance().getDocumentWithContentVersion(
                    handoverIds, 
                    new String[]{DOCUMENT_TYPE_HO_SOA}
                );
                
                for(Document__c doc : docList) {
                    if(!docMapByHandover.containsKey(doc.Handover__c)) {
                        docMapByHandover.put(doc.Handover__c, new Map<String, Id>());
                    }
                    docMapByHandover.get(doc.Handover__c).put(doc.Document_Name__c, doc.Id);
                }
                
                for (Handover__c ho : handoverList) {
                    HandoverDataWrapper wrap = new HandoverDataWrapper();
                    wrap.Id = ho.Id; 
                    wrap.handoverName = ho.Name;
                    wrap.handoverCustomerEmail = String.isNotBlank(ho.CustomerEmail__c) ? ho.CustomerEmail__c : '';
                    wrap.unitName = ho.Unit__r.Name;
                    wrap.unitStatus = String.isNotBlank(ho.Unit__r.Status__c) ? ho.Unit__r.Status__c : '';
                    wrap.activeSalesOrder = (ho.Sales_Order__r != null) ? ho.Sales_Order__r.Name : '';
                    wrap.salesorder = ho.Sales_Order__c;
                    wrap.projectId = ho.Project__c;
                    wrap.buildingName = (ho.Building_Phase__r != null) ? ho.Building_Phase__r.Name : '';
                    wrap.OwnerName = String.isNotBlank(ho.Owner_Name__c) ? ho.Owner_Name__c : '';
                    wrap.createdDate = String.valueOf(ho.CreatedDate);
                    wrap.SOADocId = '';
                    wrap.QASnagDocId = '';
                    
                    if(docMapByHandover.containsKey(ho.Id)) {
                        Map<String, Id> nameToIdMap = docMapByHandover.get(ho.Id);
                        wrap.SOADocId = nameToIdMap.get(DOCUMENT_TYPE_HO_SOA);
                        
                    }
                    
                    wrapList.add(wrap);
                }
            }
            data = JSON.serialize(wrapList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return data;
    }
    // it will check the next substatus of handover(when click complete my task)
    @AuraEnabled
    public static Map<String, Object> validateForNextReview(Id recordId){
        
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Handover Status Updated.');
        
        try {
            HandoverService serviceObj = HandoverService.getInstance();
            Handover__c handoverRecord = serviceObj.getHandoverRecordById(recordId);
            
            response = HandoverHandler.getInstance().validateHandoverNextStep(handoverRecord, false);
            
        } catch (Exception ex) {
            response.put('status', 'error');
            response.put('message', 'Unable to move to next step: ' + ex.getMessage());
        }
        return response;
    }
    // Assign to me button for assing of record owner.
    @AuraEnabled
    public static Map<String, Object> updateHandoverOwner(Id handoverId) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Handover Status Updated.');
        
        HandoverService objHandoverService = HandoverService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        
        try {
            Id currentUserId = UserInfo.getUserId();
            Handover__c handoverObj = objHandoverService.getHandoverById(handoverId);
            Boolean handoverReassigned = false;
            
            Set<Id> ownerIds = new Set<Id>();
            ownerIds.add(currentUserId);
            ownerIds.add(handoverObj.OwnerId);
            
            List<Task> openTaskList = objActivityService.getOpenTasksBywhatIds(new Set<Id>{handoverObj.Id});
            for (Task t : openTaskList) {
                ownerIds.add(t.OwnerId);
            }
            
            Map<Id, User> ownersMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]);
            User currentUser = ownersMap.get(currentUserId);
            // Handle Handover reassignment
            if (handoverObj.OwnerId.getSObjectType() == Group.sObjectType) {
                if (isUserMemberOfQueue(currentUserId, handoverObj.OwnerId)) {
                    Handover__c handoverToUpdate = new Handover__c(Id = handoverId, OwnerId = currentUserId);
                    objHandoverService.updateHandovers(new List<Handover__c>{handoverToUpdate});
                    handoverReassigned = true;
                } else {
                    response.put('status', 'error');
                    response.put('message', 'You are not a member of the queue that owns this Handover.');
                    return response;
                }
            } else if (ownersMap.containsKey(handoverObj.OwnerId)) {
                User handoverOwner = ownersMap.get(handoverObj.OwnerId);
                if (handoverOwner.Profile.Name == 'CRM Operations' && currentUser.Profile.Name == 'CRM Operations') {
                    Handover__c handoverToUpdate = new Handover__c(Id = handoverId, OwnerId = currentUserId);
                    objHandoverService.updateHandovers(new List<Handover__c>{handoverToUpdate});
                    handoverReassigned = true;
                }
            }
            
            // Handle Task reassignment
            List<Task> tasksToUpdate = new List<Task>();
            for (Task t : openTaskList) {
                if (t.OwnerId.getSObjectType() == Group.sObjectType) {
                    if (isUserMemberOfQueue(currentUserId, t.OwnerId)) {
                        t.OwnerId = currentUserId;
                        tasksToUpdate.add(t);
                    }
                } else if (ownersMap.containsKey(t.OwnerId)) {
                    User taskOwner = ownersMap.get(t.OwnerId);
                    if (taskOwner.Profile.Name == 'CRM Operations' && currentUser.Profile.Name == 'CRM Operations') {
                        t.OwnerId = currentUserId;
                        tasksToUpdate.add(t);
                    }
                }
            }
            
            objActivityService.updateTasks(tasksToUpdate);
            // Build success message
            String message = '';
            if (handoverReassigned) {
                message += 'Handover assigned to you. ';
            }
            if (!tasksToUpdate.isEmpty()) {
                message += tasksToUpdate.size() + ' Task(s) assigned to you.';
            }
            if (!handoverReassigned && tasksToUpdate.isEmpty()) {
                message = 'Records are not owned by a queue or you are not a queue member. Please contact admin for clarifications.';
            }
            
            response.put('message', message);
            return response;
            
        } catch (Exception e) {
            response.put('status', 'error');
            response.put('message', e.getMessage());
            return response;
        }
    }
    
    
    
    //Checks if a user is a member of a specific Queue
    private static Boolean isUserMemberOfQueue(Id userId, Id queueId) { 
        GroupService ObjGroupService = GroupService.getInstance();
        List<GroupMember> members = new List<GroupMember>();
        if (userId == null || queueId == null) {
            return false;
        }
        members = ObjGroupService.getMemberInfoFromGroup(userId,queueId);
        
        return !members.isEmpty();
    }
    
    
    private static List<Messaging.SingleEmailMessage> buildNOCCHOandoverEmails(List<Handover__c> handovers,List<Document__c> projectDocList,Map<Id, List<Document__c>> handoverToDocsMap, Map<Id, ContentVersion> cvMap,Map<Id, Decimal> soToPendingAmountMap, Map<Id, EmailTemplate> templateMap,Id orgWideEmailAddressId) {
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        
        for (Handover__c objHandover : handovers) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
            Id targetTempId = objHandover.Handover_Phase__r.NOCCHOEmailtemplateId__c;
            if(targetTempId == null || !templateMap.containsKey(targetTempId)) continue;
            
            EmailTemplate mailTemplate = templateMap.get(targetTempId);
            
            List<Document__c> docsForThisEmail = new List<Document__c>();
            docsForThisEmail.addAll(projectDocList); 
            
            if (handoverToDocsMap.containsKey(objHandover.Id)) {
                docsForThisEmail.addAll(handoverToDocsMap.get(objHandover.Id));
            }
            if(docsForThisEmail!=null){
                for (Document__c objDocument : docsForThisEmail) {
                    ContentVersion objCV = cvMap.get(objDocument.ContentDocumentId__c);
                    if (objCV == null) continue;
                    
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(objCV.Title);
                    attachment.setBody(objCV.VersionData);
                    attachment.setInline(false);
                    
                    if (objCV.FileExtension == 'pdf') {
                        attachment.setContentType('application/pdf');
                    } else if (objCV.FileExtension == 'png') {
                        attachment.setContentType('image/png');
                    } else if (objCV.FileExtension == 'jpeg' || objCV.FileExtension == 'jpg') {
                        attachment.setContentType('image/jpeg');
                    }
                    
                    attachmentList.add(attachment);
                }
            }
            if (String.isNotBlank(objHandover.Contact__c)) {
                mail.setToAddresses(new List<String>{objHandover.Contact__c});
            } else if (String.isNotBlank(objHandover.CustomerEmail__c)) {
                mail.setToAddresses(new List<String>{objHandover.CustomerEmail__c});
            }
            
            if(objHandover.HO_Agent_Assigned_User__c!=null){
                mail.setBccAddresses(new List<String>{objHandover.HO_Agent_Assigned_User__c}); 
            }
            Decimal amt = soToPendingAmountMap.containsKey(objHandover.Sales_Order__c) ? soToPendingAmountMap.get(objHandover.Sales_Order__c) : 0;
            mail.setHtmlBody(getDynamicBody(mailTemplate.HtmlValue, objHandover, amt));
            mail.setSubject(getDynamicSubject(mailTemplate.Subject, objHandover));
            mail.setUseSignature(true);
            mail.setWhatId(objHandover.Id);
            mail.setSaveAsActivity(true);
            mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
            mail.setFileAttachments(attachmentList);
            
            mailList.add(mail);
        }
        
        return mailList;
    }
    
    private static void sendHandoverNoticeDoorEmails(List<Handover__c> handovers, List<Handover__c> handoverUpdateList, Id orgWideEmailAddressId) {
        
        EmailService objEmailService = EmailService.getInstance();
        HandoverService objHandoverService = HandoverService.getInstance();
        MetadataService handoverMetadataService = MetadataService.getInstance();
        
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        
        EmailTemplate mailTemplate = objEmailService.getEmailTemplateByName(HANDOVER_DOORNUMBER_EMAIL_TEMPLATE_NAME);
        
        Map<Id, Handover__c> updateHandover = new Map<Id, Handover__c>(handoverUpdateList);
        
        for (Handover__c ho : handovers) {
            if (ho.Handover_Phase__r.DoorNumberClarificationrequired__c == true) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            String customSubject = getDynamicSubject(mailTemplate.Subject, ho);
            String customBody = getDynamicBody(mailTemplate.HtmlValue, ho, null);
            
            mail.setSubject(customSubject);
            mail.setHtmlBody(customBody);
            mail.setToAddresses(new List<String>{ ho.CustomerEmail__c });
            mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
            mail.setWhatId(ho.Id);
            mail.setSaveAsActivity(true);
            
            mailList.add(mail);
            
            // Stage the update for this record
            if (updateHandover.containsKey(ho.Id)) {
                updateHandover.get(ho.Id).HasDoorNumberEmailSent__c = true;
            }
        }
        }
        
        if (!mailList.isEmpty()) {
            List<Messaging.SendEmailResult> emailResultList = Messaging.sendEmail(mailList);
            
            for (Messaging.SendEmailResult res : emailResultList) {
                if (!res.isSuccess()) {
                    String locErr = res.getErrors()[0].getMessage();
                    throw new AuraHandledException('Email  transmission failure: ' + locErr);
                }
            }
            
        }
    }
    
    private class HandoverDataWrapper {
        private String Id {get;set;}
        private String handoverName {get;set;}
        private String contentDocId {get;set;}
        private String handoverCustomerEmail {get;set;}
        private String unitName {get;set;}
        private String unitStatus {get;set;}
        private String activeSalesOrder {get;set;}
        private String buildingName {get;set;}
        private String OwnerName {get;set;}
        private String createdDate {get;set;}
        private String SPADocId {get;set;}
        private String SOADocId {get;set;}
        private String QASnagDocId {get;set;}
        private String ProjectId {get;set;}
        private String salesorder {get;set;}
    }
}
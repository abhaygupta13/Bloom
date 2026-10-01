/***
Class       : LeasingOrderTriggerHelper
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public class LeasingOrderTriggerHelper {
    private static final string LEASING_STATUS_QUALIIED { get { return 'Leasing Offer'; } } 
    private static final string LEASING_SUB_STATUS_OFFER_GENERATED { get { return 'Offer Generated';}} 
    private static final Set<String> INPROGRESS_LEASING_STATUSES = new Set<String>{ 'Leasing Offer', 'Pending','Approve Pending'};
        private static final string ORGANIZATION_TYPE { get { return 'Organization'; } } 
    private static final string INDIVIDUAL_TYPE { get { return 'Individual'; } } 
    private static final string COMMON_DOCS { get { return 'Common'; } } 
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string LEASING_ORDER_SURVEY_TEMPLATE_ID { get { return 'GenerateSurveyLinkRequest'; } }
    private static final string LEASING_STATUS_LEASED { get { return 'Leased'; } } 
    private static final string LEASING_STATUS_OCCUPIED { get { return 'Occupied'; } } 
    private static final string LEASING_STATUS_CANCELLED { get { return 'Cancelled'; } } 
    private static final string LEASING_STATUS_AVAILABLE { get { return 'Available'; } } 
    private static final string LEASING_STATUS_BOOKED { get { return 'Booked'; } } 
    private static final string APPROVAL_STATUS_APPROVED { get { return 'Approved'; } } 
    private static final string LEASING_STATUS_TERMINATE { get { return 'Terminated'; } } 
    private static final string LEASING_ORDER { get { return 'LeasingOrder__c'; } } 
    private static final string LEASING_WELCOME_EMAIL { get { return 'LeasingWelcomeEmailTemplate'; } }
    private static final string LEASING_CONTRACT_SAP_EMAIL_TEMPLATE_ID { get { return 'LeasingContractSAPEmailTemplateId'; } }
    
    //Helper Method to create the document record placeholder
    public static void createDocuments(List<LeasingOrder__c> newList , Map<Id,LeasingOrder__c> newMap){
        
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> leasingContractDocTypeList = objDocumentService.getDocTypes(LEASING_ORDER);
        List<Document__c> documentList = new List<Document__c>();
        List<LeasingOrder__c> leasingContracts = LeasingOrderService.getInstance().getLeasingOrdersByIds(newMap.keySet());
        for(LeasingOrder__c leasingContract :leasingContracts)
        {
            for(DocumentType__c objDocumentType :leasingContractDocTypeList)
            {
                if(objDocumentType.Customer_Type__c == COMMON_DOCS){
                    documentList.add(new Document__c(LeasingOrder__c = leasingContract.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Account__c = leasingContract.Account__c));
                }
                if(objDocumentType.Customer_Type__c == INDIVIDUAL_TYPE && leasingContract.Opportunity__r.Account.IsPersonAccount ){
                    documentList.add(new Document__c(LeasingOrder__c = leasingContract.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Account__c = leasingContract.Account__c));
                }else if (objDocumentType.Customer_Type__c == ORGANIZATION_TYPE && !leasingContract.Opportunity__r.Account.IsPersonAccount){
                    documentList.add(new Document__c(LeasingOrder__c = leasingContract.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Account__c = leasingContract.Account__c));
                }
            }
        }
        objDocumentService.insertDocuments(documentList);   
    } 
    public static void beforeFieldUpdates(List<LeasingOrder__c> newList , Map<id,LeasingOrder__c> oldMap){
        List<Schema.FieldSetMember> sapFieldSetFields = Schema.SObjectType.LeasingOrder__c.fieldSets.getMap().get('SAP_Integration_Fields').getFields();
        ProjectService projService = ProjectService.getInstance();
        Map<Id, Project__c> projectByProjectIdMap = new Map<Id, Project__c>(ProjectService.getInstance().getLeasingProjects());
        
        for(LeasingOrder__c contract  : newList ){
            if(oldMap == null){
                contract.Status__c =  LEASING_STATUS_QUALIIED ;
                contract.SubStatus__c =  LEASING_SUB_STATUS_OFFER_GENERATED ;
            }
            if(oldMap != null){
                //Set the SendToSAP__c field to true based on changes made in the FieldSet SAP_Integration_Fields.
                for (FieldSetMember member : sapFieldSetFields){
                    String field = member.getFieldPath();
                    if (contract.get(field) != oldMap.get(contract.Id).get(field)){
                        contract.SendToSAP__c = true;
                        break;
                    }
                }
                if(!oldMap.get(contract.Id).SendToSAP__c && contract.SendToSAP__c){
                    contract.IntegrationStatus__c = 'In Progress';
                }
                
                if(oldMap.get(contract.Id).LeasingSAPContractId__c  != contract.LeasingSAPContractId__c 
                   && contract.IntegrationStatus__c == 'Success'){
                       contract.Status__c = LEASING_STATUS_LEASED;
                   }
                
                // Added for Termination Amendment Requirement
                if (oldMap.get(contract.Id).IntegrationStatus__c != contract.IntegrationStatus__c &&
                    contract.IntegrationStatus__c == 'Success' &&
                    contract.LeaseType__c == 'Termination') {
                        contract.Status__c = 'Terminated';
                    }
            }
            contract.SAPCompanyCode__c = projectByProjectIdMap.containsKey(contract.Project__c) ?
                projectByProjectIdMap.get(contract.Project__c).Leasing_Company__r.LeasingSAPCompanyCode__c : null ;
            
            // Calculate ContractPeriod__c dynamically from LeasingStartDate__c and LeasingEndDate__c
            if (contract.LeasingStartDate__c != null && contract.LeasingEndDate__c != null) {
                Date nextDayAfterEndDate = contract.LeasingEndDate__c.addDays(1);
                Integer calcMonths = contract.LeasingStartDate__c.monthsBetween(nextDayAfterEndDate);
                Date fixedMonthEndDate = contract.LeasingStartDate__c.addMonths(calcMonths);
                
                if (fixedMonthEndDate > nextDayAfterEndDate) {
                    calcMonths--;
                    fixedMonthEndDate = contract.LeasingStartDate__c.addMonths(calcMonths);
                }
                
                Integer calcDays = fixedMonthEndDate.daysBetween(nextDayAfterEndDate);
                
                // Set Bilingual Fields
                String enText = '';
                String arText = '';
                
                if (calcMonths > 0) {
                    enText += calcMonths + (calcMonths == 1 ? ' month' : ' months');
                    arText += calcMonths + ' شهر';
                }
                if (calcDays > 0) {
                    enText += (calcMonths > 0 ? ' ' : '') + calcDays + (calcDays == 1 ? ' day' : ' days');
                    arText += (calcMonths > 0 ? ' و ' : '') + calcDays + ' يوم';
                }
                
                contract.ContractPeriodEN__c = enText.trim();
                contract.ContractPeriodAR__c = arText.trim();
            }
        }
    }
    
    public static void afterFieldUpdates(List<LeasingOrder__c> newList , Map<id,LeasingOrder__c> oldMap){
        List<Unit__c> unitListToUpdate =  new List<Unit__c>();
        Set<Id> contractsRegenOffSet = new Set<Id>();
        Set<Id> leasingOrderIds = new Set<Id>();
        Set<Id> updatedLeasingOrderIds = new Set<Id>();
        Set<Id> leasedOrderIds = new Set<Id>();
        Set<Id> welcomeLetterIds = new Set<Id>();
        
        Map<Id, Integer> unitCountMap = new Map<Id, Integer>();
        
        Set<Id> accountIdsToUpdate = new Set<Id>();
        Map<Id, String> accountToSAPCodeMap = new Map<Id, String>();
        
        //Set<Id> accountIds = new Set<Id>();
        
        for(LeasingOrder__c contract : newList){
            if(oldMap?.get(contract.id).Status__c != contract.Status__c && 
               contract.Status__c == LEASING_STATUS_LEASED){
                   Unit__c leasedUnit = new Unit__c();
                   leasedUnit.id = contract.Unit__c ;
                   leasedUnit.LeasingUnitStatus__c = LEASING_STATUS_OCCUPIED;
                   leasedUnit.LeasingCustomer__c = contract.Account__c;
                   leasedUnit.LeasingOffer__c = contract.id;
                   unitListToUpdate.add(leasedUnit);
                   unitCountMap.put(contract.Project__c, unitCountMap.containsKey(contract.project__c) ? unitCountMap.get(contract.project__c)+1 : 1);
               }
            if(oldMap?.get(contract.id).Status__c != contract.Status__c && 
               contract.Status__c == LEASING_STATUS_CANCELLED){
                   Unit__c cancelledUnit = new Unit__c();
                   cancelledUnit.id = contract.Unit__c ;
                   cancelledUnit.LeasingUnitStatus__c = LEASING_STATUS_AVAILABLE;
                   unitListToUpdate.add(cancelledUnit);
                   unitCountMap.put(contract.Project__c, unitCountMap.containsKey(contract.project__c) ? unitCountMap.get(contract.project__c)-1 : -1);
               }
            if( (oldMap?.get(contract.id).Status__c != contract.Status__c &&
                 INPROGRESS_LEASING_STATUSES.contains( contract.Status__c)) || oldMap == null  ){
                     Unit__c inprogressUnit = new Unit__c();
                     inprogressUnit.id = contract.Unit__c ;
                     inprogressUnit.LeasingUnitStatus__c = LEASING_STATUS_BOOKED;
                     unitListToUpdate.add(inprogressUnit);
                     unitCountMap.put(contract.Project__c, unitCountMap.containsKey(contract.project__c) ? unitCountMap.get(contract.project__c)+1 : 1);
                 }
            if(oldMap?.get(contract.id).Status__c != contract.Status__c && 
               contract.Status__c == LEASING_STATUS_TERMINATE){
                   Unit__c cancelledUnit = new Unit__c();
                   cancelledUnit.id = contract.Unit__c ;
                   cancelledUnit.LeasingUnitStatus__c = LEASING_STATUS_AVAILABLE;
                   unitListToUpdate.add(cancelledUnit);
                   unitCountMap.put(contract.Project__c, unitCountMap.containsKey(contract.project__c) ? unitCountMap.get(contract.project__c)-1 : -1);
               }
            if( (oldMap?.get(contract.id).BloomTeamApprovalStatus__c != contract.BloomTeamApprovalStatus__c) &&
               contract.BloomTeamApprovalStatus__c == APPROVAL_STATUS_APPROVED
              ){
                  contractsRegenOffSet.add(contract.Id);   
              }
            if(oldMap != null){
                
                if (!oldMap.get(contract.Id).SendToSAP__c && contract.SendToSAP__c) {
                    leasingOrderIds.add(contract.Id);
                    //if (contract.Account__c != null) accountIds.add(contract.Account__c);
                }
                
                
                if ((oldMap.get(contract.Id).LeasingSAPContractId__c != contract.LeasingSAPContractId__c &&
                     String.isNotBlank(contract.LeasingSAPContractId__c)) || (oldMap.get(contract.Id).IntegrationStatus__c  != contract.IntegrationStatus__c  &&
                                                                              contract.IntegrationStatus__c  == 'Success' && String.isNotBlank(contract.LeasingSAPContractId__c) && contract.IntegrationMessage__c != null &&
                                                                              (contract.IntegrationMessage__c.toLowerCase().contains('renewed') ||
                                                                               contract.IntegrationMessage__c.contains('Data Migration')) ) ) {
                                                                                   updatedLeasingOrderIds.add(contract.Id);
                                                                               }
            }
            
            if (oldMap != null && oldMap.get(contract.Id).Status__c != contract.Status__c && contract.Status__c == LEASING_STATUS_LEASED) {
                leasedOrderIds.add(contract.Id);
            }
            if (oldMap == null && contract.Account__c != null && String.isNotBlank(contract.SAPCompanyCode__c)) {
                accountIdsToUpdate.add(contract.Account__c);
                accountToSAPCodeMap.put(contract.Account__c, contract.SAPCompanyCode__c);
            }
            
            if (oldMap != null && contract.Account__c != null) {
                LeasingOrder__c oldRec = oldMap.get(contract.Id);
                
                if (oldRec.SAPCompanyCode__c != contract.SAPCompanyCode__c &&
                    String.isNotBlank(contract.SAPCompanyCode__c)) {
                        
                        accountIdsToUpdate.add(contract.Account__c);
                        accountToSAPCodeMap.put(contract.Account__c, contract.SAPCompanyCode__c);
                    }
            }
            
            if(oldMap != null &&
               !oldMap.get(contract.Id).isLeasingContractSigned__c  &&
               contract.isLeasingContractSigned__c ){
                   
                   welcomeLetterIds.add(contract.Id);
                   
               }
        }
        
        if (!welcomeLetterIds.isEmpty()) {
            System.enqueueJob(
                new WelcomeLetterQueueable(welcomeLetterIds)
            );
        }
        
        if (!accountIdsToUpdate.isEmpty()) {
            List<Account> accountsToUpdate = new List<Account>();
            
            for (Id accId : accountIdsToUpdate) {
                accountsToUpdate.add(new Account(
                    Id = accId,
                    SAP_Company_Code__c = accountToSAPCodeMap.get(accId)
                ));
            }
            
            if (!accountsToUpdate.isEmpty()) {
                AccountService.getInstance().updateAccountsWithoutTrigger(accountsToUpdate);
            }
        }
        if(!unitCountMap.isEmpty()){
            //List<Project__c> projectToUpdate = [Select Id, OccupiedLeasingUnits__c from Project__c where Id IN : unitCountMap.keySet()]
            List<Project__c> projectToUpdate = ProjectService.fetchProjectsByIds(unitCountMap.keySet());
            for(Project__c project : projectToUpdate){
                if(project.OccupiedLeasingUnits__c != Null)
                    project.OccupiedLeasingUnits__c +=  unitCountMap.get(project.Id);
            }
            if(!projectToUpdate.isEmpty()){
                ProjectService.getInstance().updateProjects(projectToUpdate);
            }
            
        }
        
        if (!leasedOrderIds.isEmpty()) {
            LeasingOrderService LeasingOrderService = LeasingOrderService.getInstance();
            List<LeasingOrder__c> leasedOrdersToEmail = LeasingOrderService.getLeasingOrdersByIds(leasedOrderIds);
            MetadataService objMetadataService = MetadataService.getInstance();
            
            Id templateId = objMetadataService.getAppSettingTextValue(LEASING_ORDER_SURVEY_TEMPLATE_ID);
            Id orgWideEmailId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
            Id contractSAPEmailTemplateId = objMetadataService.getAppSettingTextValue(LEASING_CONTRACT_SAP_EMAIL_TEMPLATE_ID);
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (LeasingOrder__c order : leasedOrdersToEmail) {
                Messaging.SingleEmailMessage renderedMail = Messaging.renderStoredEmailTemplate(templateId, null, order.Id);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail = EmailService.getInstance().getSingleEmailMessage(new List<String>{ order.Owner.Email },order.Id,
                                                                        null,renderedMail.getSubject(),renderedMail.getHtmlBody(),
                                                                        orgWideEmailId,null,null);
                mail.setSaveAsActivity(false);
                emails.add(mail);
            }
            
            Map<Id, List<String>> orderToFinanceEmails = new Map<Id, List<String>>();
            for(Task t : [SELECT Owner.Email, WhatId FROM Task WHERE WhatId IN :leasedOrderIds AND Subject LIKE '%Finance Task%']) {
                if(String.isNotBlank(t.Owner.Email)) {
                    if(!orderToFinanceEmails.containsKey(t.WhatId)) orderToFinanceEmails.put(t.WhatId, new List<String>());
                    orderToFinanceEmails.get(t.WhatId).add(t.Owner.Email);
                }
            }
            
            for (LeasingOrder__c order : leasedOrdersToEmail) {
                Messaging.SingleEmailMessage sapMail = Messaging.renderStoredEmailTemplate(contractSAPEmailTemplateId, order.OwnerId, order.Id);
                sapMail.setTreatTargetObjectAsRecipient(false); 
                sapMail.setToAddresses(new List<String>{ order.Owner.Email });
                sapMail.setOrgWideEmailAddressId(orgWideEmailId);
                if (orderToFinanceEmails.containsKey(order.Id)) {
                    sapMail.setCcAddresses(orderToFinanceEmails.get(order.Id));
                }
                emails.add(sapMail);
            }
            
            EmailService.getInstance().sendEmail(emails);
        }
        
        /* if (!accountIds.isEmpty()) {
List<Account> accountsToUpdate = new List<Account>();
for (Id accId : accountIds) {
accountsToUpdate.add(new Account(Id = accId, Send_To_SAP__c = true));
}
AccountService.getInstance().updateAccounts(accountsToUpdate);
}*/
        
        if (!updatedLeasingOrderIds.isEmpty()) {
            sendLeasingOrderToSAPFromTrigger(updatedLeasingOrderIds);
        }
        
        if (!leasingOrderIds.isEmpty()) {
            LeasingOrderService LeasingOrderService = LeasingOrderService.getInstance();
            List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
            List<LeasingOrder__c> leasingOrderList = LeasingOrderService.getLeasingOrdersByIds(leasingOrderIds);
            for(LeasingOrder__c leasingOrder : leasingOrderList ){
                integrationRecordsToInsert.add(LeasingOrderService.getIntegrationRecord(leasingOrder));
            }
            IntegrationRecordService integService = IntegrationRecordService.getInstance();
            integService.insertIntegrationRecords(integrationRecordsToInsert);
        }
        System.debug('unitList>>'+unitListToUpdate);
        if(!unitListToUpdate.isEmpty() && unitListToUpdate.size()>0)
            UnitService.getInstance().updateUnitsWithoutTrigger(unitListToUpdate);
        
        if(!contractsRegenOffSet.isEmpty() && contractsRegenOffSet != null){
            System.enqueueJob(new LeasingOfferHandler(contractsRegenOffSet));
        }
    }
    public static void sendLeasingOrderToSAPFromTrigger(Set<Id> leasingOrderIds) {
        if (leasingOrderIds == null || leasingOrderIds.isEmpty()) return;
        
        try {
            LeasingPaymentScheduleService leasingPaymentPlanScheduleService = LeasingPaymentScheduleService.getInstance();
            List<PaymentPlanSchedule__c> paymentPlans = leasingPaymentPlanScheduleService.getPaymentSchedulesByLeasingOrders(leasingOrderIds);
            for (PaymentPlanSchedule__c p : paymentPlans) {
                p.SendToSAP__c = true;
            }
            if (!paymentPlans.isEmpty()) {
                leasingPaymentPlanScheduleService.updatePaymentPlanSchedules(paymentPlans);
            }
            LeasingOtherChargesService leasingOtherChargesService = LeasingOtherChargesService.getInstance();
            List<LeasingOrdersOtherCharges__c> otherCharges = leasingOtherChargesService.getOtherChargesByLeasingOrderIds(leasingOrderIds);
            
            for (LeasingOrdersOtherCharges__c oc : otherCharges) {
                oc.SendToSAP__c = true;
            }
            if (!otherCharges.isEmpty()) {
                leasingOtherChargesService.updateLeasingOtherCharges(otherCharges);
            }
            LeasingOfficerCommissionService leasingOfficerCommissionService = LeasingOfficerCommissionService.getInstance();
            List<LeasingOfficerCommission__c> leasingOfficerCommissions = leasingOfficerCommissionService.getLOCByLeasingOrderIds(leasingOrderIds);
            
            for (LeasingOfficerCommission__c loc : leasingOfficerCommissions) {
                loc.SendToSAP__c = true;
            }
            if (!leasingOfficerCommissions.isEmpty()) {
                leasingOfficerCommissionService.updateLOCs(leasingOfficerCommissions);
            }
            
        } catch (Exception ex) {
            System.debug('Error while sending Leasing Orders to SAP: ' + ex.getMessage());
        }
    }
    public static void applyVatOnCreate(List<LeasingOrder__c> newList) {
        
        Set<Id> unitIds = new Set<Id>();
        for (LeasingOrder__c order : newList) {
            if (order.Unit__c != null) {
                unitIds.add(order.Unit__c);
            }
        }
        
        if (unitIds.isEmpty()) return;
        
        LeasingOrderService service = LeasingOrderService.getInstance();
        Map<Id, Unit__c> unitMap = service.getUnitsWithPropertyUsage(unitIds);
        
        for (LeasingOrder__c order : newList) {
            Unit__c unitRec = unitMap.get(order.Unit__c);
            
            if (unitRec != null && unitRec.PropertyUsage__c == 'Commercial' && !order.RelatedPartyBloomHolding__c) {
                order.isVATApplied__c = true;
            }
        }
    }
    public static void sendWelcomeEmail(List<LeasingOrder__c> newList,Map<Id, LeasingOrder__c> oldMap) {
        Set<Id> changedOrderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for (LeasingOrder__c contract : newList) {
            if (oldMap != null
                && oldMap.containsKey(contract.Id)
                && contract.LeasingContractSignedDate__c
                != oldMap.get(contract.Id).LeasingContractSignedDate__c
               ) {
                   changedOrderIds.add(contract.Id);
                   
                   if (contract.Account__c != null) {
                       accountIds.add(contract.Account__c);
                   }
               }
        }
        
        if (changedOrderIds.isEmpty() || accountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>();
        List<Account> accounts = AccountService.getInstance().getAccountsByIds(new Set<Id>(accountIds));
        for (Account acc : accounts) {
            accountMap.put(acc.Id, acc);
        }
        
        MetadataService objMetadataService = MetadataService.getInstance();
        Id leaseOfferEmailTemplateId =
            objMetadataService.getAppSettingTextValue(LEASING_WELCOME_EMAIL);
        
        Id noReplyBloomLeasingOWDId =
            objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        
        if (leaseOfferEmailTemplateId == null || noReplyBloomLeasingOWDId == null) {
            return;
        }
        
        Map<Id, Document__c> orderToDocMap = new Map<Id, Document__c>();
        Set<Id> contentVersionIds = new Set<Id>();
        
        List<Document__c> leasingDocuments = DocumentService.getInstance().getLeasingSignedDocumentsByContractIds(changedOrderIds);
        
        
        for (Document__c doc : leasingDocuments) {
            orderToDocMap.put(doc.LeasingOrder__c, doc);
            
            if (doc.Content_Version_Id__c != null) {
                contentVersionIds.add(doc.Content_Version_Id__c);
            }
        }
        
        if (contentVersionIds.isEmpty()) {
            return;
        }
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        List<ContentVersion> leasingContentVersions = ContentService.getInstance().getContentVersionByIds(contentVersionIds);
        for (ContentVersion cv : leasingContentVersions) {
            contentVersionMap.put(cv.Id, cv);
        }
        
        EmailService objEmailService = EmailService.getInstance();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (LeasingOrder__c contract : newList) {
            
            if (!changedOrderIds.contains(contract.Id)) {
                continue;
            }
            
            Account acc = accountMap.get(contract.Account__c);
            if (acc == null ||
                !acc.IsPersonAccount ||
                String.isBlank(acc.PersonEmail)) {
                    continue;
                }
            
            Document__c doc = orderToDocMap.get(contract.Id);
            if (doc == null) {
                continue;
            }
            
            ContentVersion version = contentVersionMap.get(doc.Content_Version_Id__c);
            if (version == null) {
                continue;
            }
            
            List<String> toAddress = new List<String>{ acc.PersonEmail };
                
                Messaging.SingleEmailMessage objMail =
                objEmailService.getSingleEmailMessageWithoutTargetObjectId(
                    leaseOfferEmailTemplateId,
                    noReplyBloomLeasingOWDId,
                    contract.Id,
                    toAddress,
                    null,
                    null
                );
            
            Messaging.EmailFileAttachment objFileAttachment =
                objEmailService.getEmailAttachment(
                    version.Title + '.' + version.FileExtension,
                    version.VersionData,
                    'application/pdf'
                );
            
            objMail.setFileAttachments(
                new Messaging.EmailFileAttachment[] { objFileAttachment }
            );
            
            emails.add(objMail);
        }
        
        if (!emails.isEmpty()) {
            objEmailService.sendEmail(emails);
        }
    }
    public static void sendApprovedLeasingOfferForSigning(List<LeasingOrder__c> newList , Map<Id,LeasingOrder__c> oldMap){
        LeasingOrder__c leasingOrderToSend ;
        for(LeasingOrder__c order : newList ){
            LeasingOrder__c oldOrder = oldMap.get(order.Id);
            Boolean isApprovedNow = (order.BloomTeamApprovalStatus__c == 'Approved' && order.BloomTeamApprovalStatus__c != oldOrder.BloomTeamApprovalStatus__c);
            Boolean isInitiateCheckedNow = (order.InitiateOfferSignature__c == true && order.InitiateOfferSignature__c != oldOrder.InitiateOfferSignature__c && order.BloomTeamApprovalStatus__c == 'Approved');
            
            // Only send Offer Letter for New Leases when approved and not already signed
            if(order.InitiateOfferSignature__c == true && 
               order.BloomTeamApprovalStatus__c == 'Approved' && 
               order.LeaseType__c == 'New' && 
               order.isLeasingOfferSigned__c != true && 
               (isApprovedNow || isInitiateCheckedNow)){
                   leasingOrderToSend = order ;
                   break;// Break because it process only one record - as docusign bulk signing allows only Single signer
                   // Ref : https://developers.docusign.com/docs/salesforce/apex-toolkit-reference/bulksendservice.html
               }
        }
        if(leasingOrderToSend != null){
            DocumentType__c leasingOfferDocType ;
            List<DocumentType__c> docTypeList = DocumentTypeService.getInstance().getActiveDocusignDocumentTypeRecords('LeasingOrder__c');
            for(DocumentType__c docTyp : docTypeList){
                if( docTyp.Type__c == 'Leasing Offer'){
                    leasingOfferDocType = docTyp ; 
                    break;
                }
            }
            if(leasingOfferDocType != null){
                //LeasingDocGenController.sendForSignature(leasingOrderToSend,leasingOfferDocType);   
                LeasingDocGenController.sendForSignature(LeasingOrderService.getInstance().getLeasingOrderById(leasingOrderToSend.Id),leasingOfferDocType);   
            }
        }
    }
    
    public static void createSalesEntries(List<LeasingOrder__c> leasingOrders) {
        
        List<SalesEntrie__c> salesEntries = new List<SalesEntrie__c>();
        
        for (LeasingOrder__c order : leasingOrders) {
            
            if (order.LeasingStartDate__c == null || order.LeasingEndDate__c == null || (order.PropertyUsage__c != 'Retail' && order.PropertyUsage__c != 'Commercial')) {
                continue;
            }
            
            Date currentMonth = Date.newInstance(
                order.LeasingStartDate__c.year(),
                order.LeasingStartDate__c.month(),
                1
            );
            
            Date endMonth = Date.newInstance(
                order.LeasingEndDate__c.year(),
                order.LeasingEndDate__c.month(),
                1
            );
            
            while (currentMonth <= endMonth) {
                
                salesEntries.add(new SalesEntrie__c(
                    LeasingOrder__c = order.Id,
                    Year__c = currentMonth.year(),
                    Month__c = currentMonth.month()
                ));
                
                currentMonth = currentMonth.addMonths(1);
            }
        }
        
        if (!salesEntries.isEmpty()) {
            insert salesEntries;
        }
    }
    
    public static void adjustSalesEntries(
        List<LeasingOrder__c> newList,
        Map<Id, LeasingOrder__c> oldMap
    ) {
        
        Set<Id> changedOrderIds = new Set<Id>();
        
        for (LeasingOrder__c order : newList) {
            
            LeasingOrder__c oldOrder = oldMap.get(order.Id);
            
            if (order.LeasingStartDate__c != oldOrder.LeasingStartDate__c ||
                order.LeasingEndDate__c != oldOrder.LeasingEndDate__c) {
                    
                    changedOrderIds.add(order.Id);
                }
        }
        
        if (changedOrderIds.isEmpty()) {
            return;
        }
        
        Map<Id, List<SalesEntrie__c>> existingMap =
            new Map<Id, List<SalesEntrie__c>>();
        
        for (SalesEntrie__c se : [
            SELECT Id,
            LeasingOrder__c,
            Year__c,
            Month__c
            FROM SalesEntrie__c
            WHERE LeasingOrder__c IN :changedOrderIds
        ]) {
            
            if (!existingMap.containsKey(se.LeasingOrder__c)) {
                existingMap.put(se.LeasingOrder__c, new List<SalesEntrie__c>());
            }
            
            existingMap.get(se.LeasingOrder__c).add(se);
        }
        
        List<SalesEntrie__c> toInsert = new List<SalesEntrie__c>();
        List<SalesEntrie__c> toDelete = new List<SalesEntrie__c>();
        
        for (LeasingOrder__c order : newList) {
            
            if (!changedOrderIds.contains(order.Id)) {
                continue;
            }
            
            Set<String> requiredMonths = new Set<String>();
            
            Date current = Date.newInstance(
                order.LeasingStartDate__c.year(),
                order.LeasingStartDate__c.month(),
                1
            );
            
            Date enddate = Date.newInstance(
                order.LeasingEndDate__c.year(),
                order.LeasingEndDate__c.month(),
                1
            );
            
            while (current <= enddate) {
                
                requiredMonths.add(current.year() + '-' + current.month());
                
                current = current.addMonths(1);
            }
            
            Set<String> existingMonths = new Set<String>();
            
            if (existingMap.containsKey(order.Id)) {
                
                for (SalesEntrie__c se : existingMap.get(order.Id)) {
                    
                    String key = se.Year__c + '-' + se.Month__c;
                    
                    existingMonths.add(key);
                    
                    if (!requiredMonths.contains(key)) {
                        toDelete.add(se);
                    }
                }
            }
            
            for (String key : requiredMonths) {
                
                if (!existingMonths.contains(key)) {
                    
                    List<String> parts = key.split('-');
                    
                    toInsert.add(new SalesEntrie__c(
                        LeasingOrder__c = order.Id,
                        Year__c = Integer.valueOf(parts[0]),
                        Month__c = Decimal.valueOf(parts[1])
                    ));
                }
            }
        }
        
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
        
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
    
    public static void validateSalesEntriesOnLeaseDateChange(
        List<LeasingOrder__c> newList,
        Map<Id, LeasingOrder__c> oldMap
    ) {
        
        Set<Id> orderIds = new Set<Id>();
        
        for (LeasingOrder__c order : newList) {
            
            LeasingOrder__c oldOrder = oldMap.get(order.Id);
            
            if (order.LeasingStartDate__c != oldOrder.LeasingStartDate__c ||
                order.LeasingEndDate__c != oldOrder.LeasingEndDate__c) {
                    
                    orderIds.add(order.Id);
                }
        }
        
        if (orderIds.isEmpty()) {
            return;
        }
        
        Map<Id, LeasingOrder__c> newOrders =
            new Map<Id, LeasingOrder__c>(newList);
        
        for (SalesEntrie__c se : [
            SELECT Id,
            LeasingOrder__c,
            Year__c,
            Month__c,
            ActualSales__c,
            AuditedSales__c
            FROM SalesEntrie__c
            WHERE LeasingOrder__c IN :orderIds
        ]) {
            
            LeasingOrder__c order = newOrders.get(se.LeasingOrder__c);
            
            Date startMonth = Date.newInstance(
                order.LeasingStartDate__c.year(),
                order.LeasingStartDate__c.month(),
                1
            );
            
            Date endMonth = Date.newInstance(
                order.LeasingEndDate__c.year(),
                order.LeasingEndDate__c.month(),
                1
            );
            
            Date salesMonth = Date.newInstance(
                Integer.valueOf(se.Year__c),
                Integer.valueOf(se.Month__c),
                1
            );
            
            if ((salesMonth < startMonth || salesMonth > endMonth) &&
                (se.ActualSales__c != null || se.AuditedSales__c != null)) {
                    
                    order.addError(
                        'Lease dates cannot be modified because sales data exists for month '
                        + se.Month__c + '/' + se.Year__c + '.'
                    );
                }
        }
    }
    
}
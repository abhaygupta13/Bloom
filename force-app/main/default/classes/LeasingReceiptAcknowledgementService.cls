/*******************************************************************************************************
Class       : LeasingReceiptAcknowledgementService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1        1.0                14-10-2025             Initial draft
****************************************************************************************************************/
public inherited sharing class LeasingReceiptAcknowledgementService {
    private static LeasingReceiptAcknowledgementService instance;
    private static final string INTEGRATION_ACTION_UPDATE { get { return 'U'; } }
    private static final string INTEGRATION_ACTION_INSERT { get { return 'C'; } }
    private static final string LEASINGORDER_OBJECT_API_NAME { get { return 'LeasingReceiptAcknowledgment__c '; } }
    private static final string INTEGRATION_TYPE_LEASINGRECPT_SAP_INTEGRATION { get { return 'LEASINGRECEIPTACKNOWLEDGEMENT_SAP_INTEGRATION'; } }
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string LEASING_RECEIPT_EMAIL_TEMPLATE_ID { get { return 'LeasingReceiptEmailTemplateId'; } }
    private static final String LContractDoc {get{ return 'Leasing Receipt document';} }

    public static Boolean bypassIntegration = false;
    
    private LeasingReceiptAcknowledgementService() {
        
    }
    
    public static LeasingReceiptAcknowledgementService getInstance() { 
        if(instance == null) {
            instance = new LeasingReceiptAcknowledgementService();
        }
        return instance;
    }


    public static List<LeasingReceiptAcknowledgment__c> getLeasingReceiptAcknowledgementByIds(Set<Id> receiptAcknowledgementIdSet){
        return [Select id, LeasingOrder__r.Id, LeasingOrder__r.Name, LeasingOrder__r.Unit__c, LeasingOrder__r.SAPBPNumber__c,LeasingOrder__r.LeasingOrderNumber__c,LeasingOrder__r.Owner.Email, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c,IsIntercompanyTransaction__c,ChequeNumber__c,
        /*LeasingOrder__r.Project__r.LeasingCompany__r.ProfitCenter__c*/
        LeasingOrder__r.Unit__r.LeasingProfitCenter__c,LeasingOrder__r.Unit__r.LeasingIntercompanyProfitCenter__c, LeasingOrder__r.Project__r.LeasingBankAccount__c,
        LeasingOrder__r.Project__r.LeasingBankAccount__r.SAP_Cheque_GL_Sub_Account__c, LeasingOrder__r.Project__r.LeasingBankAccount__r.SAP_Wire_GL_Sub_Account__c,
        LeasingOrder__r.LeasingSAPContractId__c, Name, ReceiptDate__c, VerifyDate__c, UnitNumber__c, PaymentType__c, BankCharges__c, /*Intercompanyprofitcenter__c,*/
        Amount__c, ReferenceNumber__c, BankName__c, LeasingOrder__r.Account__r.SAP_BP_No__c/*, FundingEntity__c*/, ReceivingEntity__c,
        BankAccount__r.SAP_Cheque_GL_Sub_Account__c, BankAccount__r.SAP_Wire_GL_Sub_Account__c, 
        SAPSpecialGLIndicator__c, MarkDeleteReverse__c, ActualBounceReversalDate__c, ReversalStatusReason__c,ChequeBounced__c, 
        ReversalComments__c, ReceiptReversalCategory__c, SAPReversalDocumentNumber__c,ChequeDate__c,SAPDocumentNumber__c,
        (Select Id, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c, LeasingOrder__r.LeasingSAPContractId__c,  
        LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPContractTypeCode__c, TypeofInvoice__c, AmountApplied__c, 
        LeasingOrder__r.ExtraChequeFee__c,/* SAPDocumentNoI__c,*/ SAPReversalDocumentNumber__c  
        FROM LeasingReceiptAllocations__r) 
        FROM LeasingReceiptAcknowledgment__c 
        WHERE Id IN : receiptAcknowledgementIdSet];
    }

    public void createReceiptAckIntegrationRecord(String action, Set<Id> ReceiptAckUpdateActionIds, String Type){
        //LeasingReceiptAcknowledgementService objReceiptAcknowledgementService = LeasingReceiptAcknowledgementService.getInstance();
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        List<LeasingReceiptAcknowledgment__c> receiptAckList = getLeasingReceiptAcknowledgementByIds(ReceiptAckUpdateActionIds);
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        for(LeasingReceiptAcknowledgment__c receiptAck :receiptAckList){
            if((bypassIntegration && receiptAck.SAPDocumentNumber__c != Null) || (receiptAck.VerifyDate__c > Date.Today() && !receiptAck.MarkDeleteReverse__c))
            continue;
            objIntegrationRecordList.add(createReceiptAckIntegrationRecObj(action, receiptAck, Type));
        }
        objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
    }
    
    public static IntegrationRecord__c createReceiptAckIntegrationRecObj(String action, LeasingReceiptAcknowledgment__c receiptAck, String Type){
        String Splglind = '';
        String receipttype;
        // for(LeasingReceiptAllocation__c allocation : receiptAck.LeasingReceiptAllocations__r){
        //     if(allocation.LeasingOrder__r.Project__r.LeasingCompany__r.SAPContractTypeCode__c == 'R006'){
        //         Splglind = 'D';
        //         break;
        //     }
        // }
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('Param1', receiptAck.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c);
        paramMap.put('Param2', receiptAck.LeasingOrder__r.LeasingSAPContractId__c!= Null ? receiptAck.LeasingOrder__r.LeasingSAPContractId__c : '');
        paramMap.put('Param3', receiptAck.Name);
        paramMap.put('Param4', receiptAck.ReceiptDate__c != Null ? String.valueOf(receiptAck.ReceiptDate__c) : '');
        paramMap.put('Param5', receiptAck.VerifyDate__c != Null ? String.valueOf(receiptAck.VerifyDate__c) : '');
        paramMap.put('Param6', receiptAck.UnitNumber__c);
        paramMap.put('Param7', String.valueOf(receiptAck.Amount__c));
        paramMap.put('Param8', receiptAck.LeasingOrder__r.Unit__r.LeasingProfitCenter__c != null ? receiptAck.LeasingOrder__r.Unit__r.LeasingProfitCenter__c : '');
        paramMap.put('Param9', receiptAck.PaymentType__c == 'Cheque' && receiptAck.ChequeNumber__c != null ? receiptAck.ChequeNumber__c : receiptAck.ReferenceNumber__c != Null ? receiptAck.ReferenceNumber__c : '');
        paramMap.put('Param10', receiptAck.BankName__c);
        paramMap.put('Param11', receiptAck.LeasingOrder__r.Account__r.SAP_BP_No__c);
        // paramMap.put('Param12', receiptAck.PaymentType__c == 'Cheque' ? receiptAck.LeasingOrder__r.Project__r.LeasingBankAccount__r.SAP_Cheque_GL_Sub_Account__c :'');
        // paramMap.put('Param13', receiptAck.PaymentType__c != 'Cheque' ? receiptAck.LeasingOrder__r.Project__r.LeasingBankAccount__r.SAP_Wire_GL_Sub_Account__c : '');
        paramMap.put('Param12', receiptAck.PaymentType__c == 'Cheque' ? receiptAck.BankAccount__r.SAP_Cheque_GL_Sub_Account__c :'');
        paramMap.put('Param13', receiptAck.PaymentType__c != 'Cheque' ? receiptAck.BankAccount__r.SAP_Wire_GL_Sub_Account__c : '');
        paramMap.put('Param14', 'D');
        paramMap.put('Param15', receiptAck.ChequeBounced__c ? 'X' : receiptAck.MarkDeleteReverse__c ? 'X' : '');
        paramMap.put('Param16', receiptAck.ActualBounceReversalDate__c != Null ? String.valueOf(receiptAck.ActualBounceReversalDate__c) : '');
        paramMap.put('Param17', receiptAck.ReversalStatusReason__c != Null ? receiptAck.ReversalStatusReason__c : '');
        paramMap.put('Param18', receiptAck.ReversalComments__c != Null ? receiptAck.ReversalComments__c : '');
        paramMap.put('Param19', receiptAck.ReceiptReversalCategory__c != Null ? receiptAck.ReceiptReversalCategory__c : '');
        paramMap.put('Param20', receiptAck.SAPReversalDocumentNumber__c != Null ? receiptAck.SAPReversalDocumentNumber__c : '');
        if(receiptAck.ChequeDate__c != Null && receiptAck.ChequeDate__c > Date.today())
        receipttype = 'PDC';
        paramMap.put('Param21', receipttype != Null ? receipttype : '');
        paramMap.put('Param22', receiptAck.ChequeDate__c != Null ? String.valueOf(receiptAck.ChequeDate__c) : '');
        paramMap.put('Param23', '');
        paramMap.put('Param24', '');
        paramMap.put('Param25',receiptAck.SAPDocumentNumber__c != Null ? String.valueOf(receiptAck.SAPDocumentNumber__c) : '');
        //paramMap.put('Param26',receiptAck.FundingEntity__c != Null ? receiptAck.FundingEntity__c : receiptAck.ReceivingEntity__c != Null ? receiptAck.ReceivingEntity__c : '');
        paramMap.put('Param26',receiptAck.ReceivingEntity__c != Null ? receiptAck.ReceivingEntity__c : '');
        paramMap.put('Param27',receiptAck.BankCharges__c != Null ? String.valueOf(receiptAck.BankCharges__c) : '');
        //paramMap.put('Param28',receiptAck.IsIntercompanyTransaction__c ? receiptAck.LeasingOrder__r.Unit__r.LeasingIntercompanyProfitCenter__c : '');
        paramMap.put('Param28',receiptAck.IsIntercompanyTransaction__c  && receiptAck.ReceivingEntity__c != Null ? receiptAck.ReceivingEntity__c+'1000' : '');
        paramMap.put('Param29',UserInfo.getUserEmail());
        // return objIntegrationRecordService.getIntegrationRecord(action, 'LeasingReceiptAcknowledgement__c', String.valueOf(receiptAck.Id), paramMap);
        return objIntegrationRecordService.getIntegrationRecord(Type, action,'','', LEASINGORDER_OBJECT_API_NAME, receiptAck.Id,paramMap);
    }

    public List<LeasingReceiptAcknowledgment__c> updateLeasingReceiptAcknowledgement(List<LeasingReceiptAcknowledgment__c> receiptList) {
        if (receiptList != null && !receiptList.isEmpty()) {
            update receiptList;
        }
        return receiptList;
    }
      //Update Receipts Acknowledgemnts without trigger
    public List<LeasingReceiptAcknowledgment__c> updateReceiptACknowledgementsWithoutTrigger(List<LeasingReceiptAcknowledgment__c> receiptList){
        if(receiptList != NULL && !receiptList.isEmpty()){
            LeasingRATriggerHandler.isTriggerDisabled = true;
            update receiptList;
            LeasingRATriggerHandler.isTriggerDisabled = false;
        }
        return receiptList;
    }

    public LeasingReceiptAcknowledgment__c updateOtherCharge(LeasingReceiptAcknowledgment__c receipt){
        if(receipt != NULL ){
            receipt = updateLeasingReceiptAcknowledgement(new List<LeasingReceiptAcknowledgment__c>{receipt})[0];
        }
        return receipt;
    }

    public static void sendEmailAlertToFinanceOwnerOnDocumentUpdate(Set<Id> ackIds){
       
        if(ackIds.isEmpty()) return;
        
        //  Single SOQL (Ack + Parent fields)
        Map<Id,LeasingReceiptAcknowledgment__c> ackMap=new Map<Id,LeasingReceiptAcknowledgment__c>(
            getLeasingReceiptAcknowledgementByIds(ackIds)
        );
        
        // Collect LeasingOrder Ids
        Set<Id> leasingOrderIds=new Set<Id>();
        for(LeasingReceiptAcknowledgment__c rec:ackMap.values()){
            if(rec.LeasingOrder__c!=null) leasingOrderIds.add(rec.LeasingOrder__c);
        }
        if(leasingOrderIds.isEmpty()) return;
        
        // Finance Emails (CC)
        Map<Id,List<String>> orderToFinanceEmails=new Map<Id,List<String>>();
        for(Task t:[SELECT Owner.Email,WhatId FROM Task WHERE WhatId IN :leasingOrderIds AND Subject LIKE '%Finance Task%']){
            if(String.isNotBlank(t.Owner.Email)){
                if(!orderToFinanceEmails.containsKey(t.WhatId)) orderToFinanceEmails.put(t.WhatId,new List<String>());
                orderToFinanceEmails.get(t.WhatId).add(t.Owner.Email);
            }
        }
        
        // Template + Metadata
        MetadataService objMetadataService=MetadataService.getInstance();
        Id noReplyOWDId= objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        Id emailTemplateId= objMetadataService.getAppSettingTextValue(LEASING_RECEIPT_EMAIL_TEMPLATE_ID);
        
        List<Messaging.SingleEmailMessage> emailList=new List<Messaging.SingleEmailMessage>();

        Map<Id, List<Messaging.EmailFileAttachment>> ackAttachments = getAttachmentsByAckId(ackMap.keySet(),new List<String>{LContractDoc});

        for(LeasingReceiptAcknowledgment__c rec:ackMap.values()){
            if(rec.LeasingOrder__c==null || String.isBlank(rec.LeasingOrder__r.Owner.Email)) continue;
            
            Messaging.SingleEmailMessage renderedMail = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), rec.LeasingOrder__r.Id);

            String subject= renderedMail.getSubject();
            subject = subject.replace('[{ReferenceNumber__c}]',String.isNotBlank(rec.ReferenceNumber__c) ? rec.ReferenceNumber__c : 'N/A');
            
            String body= renderedMail.getHtmlBody();
            body = body.replace('[{ReferenceNumber__c}]',String.isNotBlank(rec.ReferenceNumber__c) ? rec.ReferenceNumber__c : 'N/A');
        
            Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setToAddresses(new List<String>{rec.LeasingOrder__r.Owner.Email});
            
            List<String> ccEmails=orderToFinanceEmails.get(rec.LeasingOrder__c);
            if(ccEmails!=null && !ccEmails.isEmpty()) mail.setCcAddresses(ccEmails);
            
            //mail.setWhatId(rec.Id);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setOrgWideEmailAddressId(noReplyOWDId);
            if(ackAttachments.containsKey(rec.Id))
                mail.setFileAttachments(ackAttachments.get(rec.Id));
            
            emailList.add(mail);
        }
        
        if(!emailList.isEmpty() && !Test.isRunningTest()) Messaging.sendEmail(emailList);
    }

    public static Map<Id, List<Messaging.EmailFileAttachment>> getAttachmentsByAckId(Set<Id> ackIds, List<String> documentNameList) {
        Map<Id, List<Messaging.EmailFileAttachment>> ackToFilesMap = new Map<Id, List<Messaging.EmailFileAttachment>>();
        Map<Id, Id> contentDocToAckIdMap = new Map<Id, Id>();
        Map<Id, String> docIdNameMap = new Map<Id, String>();

        for (Document__c doc : [SELECT ContentDocumentId__c, Document_Name__c, LeasingReceiptAcknowledgment__c 
                                FROM Document__c 
                                WHERE LeasingReceiptAcknowledgment__c IN :ackIds 
                                AND ContentDocumentId__c != null 
                                AND Document_Name__c IN :documentNameList]) {
            contentDocToAckIdMap.put(doc.ContentDocumentId__c, doc.LeasingReceiptAcknowledgment__c);
            docIdNameMap.put(doc.ContentDocumentId__c, doc.Document_Name__c);
        }

        if (contentDocToAckIdMap.isEmpty()) return ackToFilesMap;

        for (ContentVersion cv : [SELECT VersionData, FileExtension, ContentDocumentId FROM ContentVersion 
                                WHERE ContentDocumentId IN :contentDocToAckIdMap.keySet() AND IsLatest = true]) {
            
            Id parentAckId = contentDocToAckIdMap.get(cv.ContentDocumentId);
            
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(docIdNameMap.get(cv.ContentDocumentId) + '.' + cv.FileExtension);
            efa.setBody(cv.VersionData);

            if (!ackToFilesMap.containsKey(parentAckId)) {
                ackToFilesMap.put(parentAckId, new List<Messaging.EmailFileAttachment>());
            }
            ackToFilesMap.get(parentAckId).add(efa);
        }

        return ackToFilesMap;
    }

    public static List<LeasingReceiptAcknowledgment__c> getDuplicateReceipt(LeasingReceiptAcknowledgment__c receipt) {
        String bankName = receipt.BankName__c;
        
        String refNum = receipt.ReferenceNumber__c != null ? receipt.ReferenceNumber__c : '';
        String chequeNum = receipt.ChequeNumber__c != null ? receipt.ChequeNumber__c : '';

        if (bankName == null || (refNum == '' && chequeNum == '')) {
            return new List<LeasingReceiptAcknowledgment__c>();
        }

        List<String> conditions = new List<String>();
        
        if (refNum != '') {
            conditions.add('ReferenceNumber__c = :refNum');
        }
        if (chequeNum != '') {
            conditions.add('ChequeNumber__c = :chequeNum');
        }

       if (!conditions.isEmpty()) {
            String queryString = 'SELECT Id, ReferenceNumber__c, ChequeNumber__c, LeasingOrder__r.Account__r.SAP_BP_No__c ' +
                                'FROM LeasingReceiptAcknowledgment__c ' +
                                'WHERE BankName__c = :bankName ' +
                                'AND LeasingOrder__c = \''+receipt.LeasingOrder__c+'\' '+
                                'AND (' + String.join(conditions, ' OR ') + ') ' +
                                'LIMIT 1';
            return Database.query(queryString);
        }

        return new List<LeasingReceiptAcknowledgment__c>();
    }

    public static List<LeasingReceiptAcknowledgment__c> getChildLeasingReceiptForIntegration(Set<Id> otherChargePaymentPlanIds) {

        return [
            SELECT Id, Name, VerifyDate__c, SendToSAP__c, SAPDocumentNumber__c
            FROM LeasingReceiptAcknowledgment__c
            WHERE VerifyDate__c <= TODAY
            AND (SAPDocumentNumber__c = '' OR SAPDocumentNumber__c = null)
            AND IntegrationTriggeredDate__c = null
            AND Id IN (
                SELECT LeasingReceiptAcknowledgment__c
                FROM LeasingReceiptAllocation__c
                WHERE LeasingOrderOtherCharges__c IN :otherChargePaymentPlanIds
                OR PaymentPlanSchedule__c IN :otherChargePaymentPlanIds
            )
        ];
    }

    public List<LeasingReceiptAcknowledgment__c> getLRAByLeasingOrderId(Id leasingOrderId ){
            return [SELECT Id, LeasingOrder__c, VerifyDate__c FROM LeasingReceiptAcknowledgment__c WHERE LeasingOrder__c = :leasingOrderId];
    }
}
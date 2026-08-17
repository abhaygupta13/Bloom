/*****************************************************************************************
Class       : PostSalePaymentDeferalCaseHandler
Author      :  Sonali S
Description : 
test Class  : PostSalePaymentDeferalCaseHandlerTest
Created Date: 2/25/2025
*****************************************************************************************/
public inherited sharing class PostSalePaymentDeferalCaseHandler { 
    private static final string POST_SALE_PAYMENT_DEFERRAL { get { return 'Post Sale Payment Deferral'; } }
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string INSTALLMENT_POSTPONEMENT_EMAIL_TEMPLATE_ID { get { return 'InstallmentPostponementEmailTemplateId'; } }
    
    private static PostSalePaymentDeferalCaseHandler instance;
    private PostSalePaymentDeferalCaseHandler() {
        
    }
    
    public static PostSalePaymentDeferalCaseHandler getInstance() { 
        if(instance == null) {
            instance = new PostSalePaymentDeferalCaseHandler();
        }
        return instance;
    } 
    
    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases); 
    }
    
    public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        if(salesOrderObj != null && salesOrderObj.Status__c != 'Sold'){
            message = 'This unit is not eligible for the selected service request';
        }
        else if(salesOrderObj !=null && salesOrderObj.IsDefaulted__c == true){
            message = 'A payment deferral request cannot be created for a defaulted unit';
        }
        else if(caseObj != null){
            List<String> missingFields = new List<String>();
            if (caseObj.AccountId == null) {missingFields.add('Account Name');}
            if (caseObj.Unit__c == null) {missingFields.add('Unit');}
            
            if (!missingFields.isEmpty()) {
                return 'Conversion is not allowed. The following fields are required: ' + String.join(missingFields, ', ') + '.';
            }
        }
        return message;
    }
    
    public void sendNewServiceRequestAssignmnmentEmailNotification(List<Case> caseList){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        
        Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID);
        if(emailTemplateId!=null){
            for(Case caseObj : caseList){
                if(!caseObj.StopEmailsToCustomer__c){
                    Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId,  caseobj.Id, caseObj.ContactId, null,null,null);
                    emailList.add(email);
                }
            }
        }
        if(!emailList.isEmpty()){
            objEmailService.sendEmail(emailList);  
        }
    }
    
    public  Map<String, String> convertToComplaint(Id recordID,ServiceCatalog__c sc, String account, String unit,String selectedType,String description,String origin) {
        Map<String, String> response = new Map<String, String>();
        try {
            SalesOrderService salesOrderObj = SalesOrderService.getInstance();
            SalesOrder__c order = salesOrderObj.getSalesOrderByUnit(unit);
            if(order.IsDefaulted__c == true){
                response.put('status', 'error');
                response.put('message', 'Conversion is not allowed. A payment deferral request cannot be created for a defaulted unit.');
                return response;
            }
            Case caseObj = new Case();
            caseObj.id = recordID;
            caseObj.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,sc.RecordTypeDevName__c);
            caseObj.ServiceCatalog__c = sc.id;
            if(account != null){caseObj.AccountId = account;}
            if(unit != null){caseObj.Unit__c = unit;}
            if(selectedType != null){caseObj.CaseType__c = selectedType;}
            if(description !=null){caseObj.Description = description;}
            if(origin !=null){caseObj.Origin = origin;}
            
            CaseService caseServiceObj = CaseService.getInstance(); 
            case updatedCase = caseServiceObj.updateAndReturnCase(caseObj);
            if(updatedCase != null){
                response.put('status', 'success');
                response.put('message', 'Case Record updated successfully.');     
            }
        } catch (Exception e) {
            response.put('status', 'error');
            response.put('message', 'Error updating case: ' + e.getMessage()); 
        }
        return response;
    }   
    public Case createCaseRecord(
        SalesOrder__c salesOrderObj,
        ServiceCatalog__c sc,
        String accountId,
        String unitId,
        String selectedType,
        String description,
        String origin,
        Boolean stopEmailsToCustomer
    ) {
        AccountService accService = AccountService.getInstance();
        
        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Status = 'New';
        newCase.Origin = String.isNotBlank(origin) ? origin : 'Walk-In';
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        
        if (salesOrderObj != null) {
            newCase.Subject = sc.SubCategory__c + ' - ' + salesOrderObj.Unit__r.Name;
            newCase.IsDPCleared__c = evaluateDPClearance(new List<SalesOrder__c>{salesOrderObj}).get(salesOrderObj.Id);
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        return newCase; 
    } 
    
    public  Map<Id, String> evaluateDPClearance(List<SalesOrder__c> salesOrderList) {
        Map<Id, String> orderWiseDPInfo = new Map<Id, String>();
        
        // Collect all sales order IDs
        Set<Id> salesOrderIds = new Set<Id>();
        for (SalesOrder__c order : salesOrderList) {
            salesOrderIds.add(order.Id);
        }
        
        // Query all related Installment Lines in bulk
        Map<Id, InstallmentLines__c> installmentsBySO = new Map<Id, InstallmentLines__c>();
        if (!salesOrderIds.isEmpty()) {
            InstallmentLineService installServiceObj = InstallmentLineService.getInstance();
            List<InstallmentLines__c> installments = installServiceObj.getDPInstallmentLinesBySalesOrder(salesOrderIds);
            for (InstallmentLines__c line : installments) {
                installmentsBySO.put(line.SalesOrder__c,line);
            }
        }
        
        // Iterate through the Sales Orders and determine DP status
        for (SalesOrder__c order : salesOrderList) {
            String isDpCleared = 'No';
            InstallmentLines__c dpInstallment = installmentsBySO.get(order.Id);
            
            // If dp installment exist, check for pending amount
            if (dpInstallment != null) {
                
                if (dpInstallment.PendingAmount__c <=1) {
                    isDpCleared = 'Yes';
                }
                orderWiseDPInfo.put(order.Id, isDpCleared);
            }
        }
        
        return orderWiseDPInfo;
    }
    
    //Logic to add CaseInstallments based on Installment lines on related Sales order
    public  void createCaseInstallments(List<Case> listOfCases) {
        
        Set<Id> salesOrderIds = new Set<Id>();
        Map<Id, List<InstallmentLines__c>> orderVsInstallmentLines = new Map<Id, List<InstallmentLines__c>>(); 
        List<CaseInstallment__c> caseInstallmentToCreate = new List<CaseInstallment__c>();
        InstallmentLineService servObj = InstallmentLineService.getInstance();
        
        // Step 1: Filter cases with valid SalesOrder and ServiceCatalog and collect SalesOrder IDs
        for (Case caseObj : listOfCases) {
            if (caseObj.Sales_Order__c != null && caseObj.ServiceCatalog__c != null) {
                salesOrderIds.add(caseObj.Sales_Order__c);
            }
        }
        
        // Step 2: Fetch related InstallmentLines in one bulk query
        List<InstallmentLines__c> installmentsRelatedToSO = new List<InstallmentLines__c>();
        
        if (!salesOrderIds.isEmpty()) {
            installmentsRelatedToSO =servObj.getInstallmentLinesBySalesOrder(salesOrderIds);
        }
        
        // Step 3: Prepare a map of SalesOrder ID to InstallmentLines
        for (InstallmentLines__c installmentObj : installmentsRelatedToSO) {
            if (!orderVsInstallmentLines.containsKey(installmentObj.SalesOrder__c)) {
                orderVsInstallmentLines.put(installmentObj.SalesOrder__c, new List<InstallmentLines__c>());
            }
            orderVsInstallmentLines.get(installmentObj.SalesOrder__c).add(installmentObj);
        }
        
        // Step 4: Create CaseInstallment records for each valid case and its related installments
        for (Case validCase : listOfCases) {
            if (orderVsInstallmentLines.containsKey(validCase.Sales_Order__c)) {
                for (InstallmentLines__c line : orderVsInstallmentLines.get(validCase.Sales_Order__c)) {
                    CaseInstallment__c caseInstallment = new CaseInstallment__c();
                    caseInstallment.Case__c = validCase.Id;
                    caseInstallment.Installment__c = line.Id;
                    caseInstallmentToCreate.add(caseInstallment);
                }
            }
        }
        // Step 5: Insert CaseInstallment records in bulk if any
        if (!caseInstallmentToCreate.isEmpty()) {
            CaseInstallmentService caseInsService = CaseInstallmentService.getInstance();
            caseInsService.insertCaseInstallments(caseInstallmentToCreate);
        }
    }
    public void createDocuments(List<Case> listOfCases){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getDocTypes('Case',POST_SALE_PAYMENT_DEFERRAL_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    public  Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        if(caseRecord.Step__c !='Final' 
           && Integer.valueOf(caseRecord.Step__c) <1){
               response.put('status', 'error');
               response.put('message', 'Invalid Case Step.');
               return response;
           }
        if(caseRecord.OwnerId.getSObjectType() == Group.SObjectType){
            response.put('status', 'error');
            response.put('message', 'Please assign the case to yourself before proceeding.');
            return response; 
        }
        response = checkRequiredFields(caseRecord);
        if (response.get('status') == 'error') {
            return response;
        }
        if (caseRecord.Step__c == '1') {
            response = validateForDeferralApproval(caseRecord);
        }
        if(response.get('status')=='success'){
            if(caseRecord.Step__c == '2'){
              evaluateDeferralFeeAndCalculateOtherCharges(caseRecord);    
            }
          
            handleNextSteps(caseRecord); 
        }
        
        return response;
    } 

   public void evaluateDeferralFeeAndCalculateOtherCharges(Case caseRec) {
    List<SalesOrderOtherCharges__c> otherChargesToInsert = new List<SalesOrderOtherCharges__c>();
    
    CaseInstallmentService caseInstallServiceObj = CaseInstallmentService.getInstance();
    List<CaseInstallment__c> caseInstallments = caseInstallServiceObj.getCaseInstallments(caseRec.Id); 
    Double deferralFee = 0;

    Double shortTermFee = 0;
    Double longTermFee = 0;

    if (caseRec.Unit__r != null && caseRec.Unit__r.Project__r != null) {
        shortTermFee = caseRec.Unit__r.Project__r.chequePostponeFeeShortTerm__c;
        longTermFee = caseRec.Unit__r.Project__r.chequePostponeFeeLongTerm__c;
    }

    for (CaseInstallment__c ins : caseInstallments) {
        if (ins.NewInstallmentDate__c != null && ins.InstallmentDate__c != null) {
            Integer deferralDays = ins.InstallmentDate__c.daysBetween(ins.NewInstallmentDate__c);

            if (deferralDays <= 15) {
                deferralFee += shortTermFee;
            } else if (deferralDays <= 30) {
                deferralFee += longTermFee;
            }
        }
    }

    // Update the case
    Case caseToUpdate = new Case(
        Id = caseRec.Id,
        DeferralFee__c = deferralFee
    );

    CaseService caseServiceObj = CaseService.getInstance();
    List<Case> updatedCaseList = caseServiceObj.updateCasesWithoutTrigger(new List<Case>{ caseToUpdate });

    // Build charge wrapper
    List<ResaleServiceRequestHandler.ChargeWrapper> charges = new List<ResaleServiceRequestHandler.ChargeWrapper>{
        new ResaleServiceRequestHandler.ChargeWrapper(updatedCaseList[0].DeferralFee__c, 'Cheque Postponement Fee')
    };

    for (ResaleServiceRequestHandler.ChargeWrapper c : charges) {
        if (c.amount != null) {
            otherChargesToInsert.add(new SalesOrderOtherCharges__c(
                Amount__c = c.amount,
                Due_Date__c = System.today(),
                SalesOrder__c = caseRec.Sales_Order__c,
                Account__c = caseRec.AccountId,
                TypeOfCharge__c = c.chargeType
            ));
        }
    }

    if (!otherChargesToInsert.isEmpty()) {
        SalesOrderOtherChargesService.getInstance().insertSalesOrderOtherCharges(otherChargesToInsert);
    }
}

    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    } 
    
    public Map<String, Object> checkRequiredFields(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        CaseInstallmentService caseInstallServiceObj = CaseInstallmentService.getInstance();
        if(caseRecord.Step__c == '1'){
            if (String.isEmpty(caseRecord.PaymentDeferralReason__c) || 
                String.isEmpty(caseRecord.Deferral_Fee_Paid__c) 
               ) {
                   response.put('status', 'error');
                   response.put('message', 'The case is not valid to move to next step, please fill all the necessary details before proceeding.');
                   return response;
               }else if (caseInstallServiceObj.getCaseInstallments(caseRecord.Id).isEmpty()){
                   response.put('status', 'error');
                   response.put('message', 'Please enter new dates for Installment.');
                   return response; 
               }
            else if(validatePOPDocument(caseRecord).isEmpty()){
                response.put('status', 'error');
                response.put('message', 'Please upload Proof of Payment before proceeding to submit for next review.');
                return response; 
            }
        }else if(caseRecord.Step__c == 'Final'){
            if (String.isEmpty(caseRecord.ChequeScanned__c) ||
                String.isEmpty(caseRecord.WithdrawlRequestInitiated__c) 
                || String.isEmpty(caseRecord.PostponementFeesBooked__c) 
                || String.isEmpty(caseRecord.PostponeApproved__c)
               ) {
                   response.put('status', 'error');
                   response.put('message', 'The case is not valid to move to next step, please fill all the necessary details before proceeding.');
                   return response;
               }
        }
        if(caseRecord.Step__c == 'Final'){
            response.put('message', 'Case closed successfully.');   
        }
        else{
            response.put('message', 'Case moved to next review successfully.');    
        }
        response.put('status', 'success');
        return response;
    }
    public static List<ContentDocumentLink> validatePOPDocument(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        DocumentService docServiceObj = DocumentService.getInstance();
        Document__c popDocument = docServiceObj.getCaseDocumentByName(caseRecord.Id,'Proof of Payment');
        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :popDocument.id];
        return cdl;
    }
    
    public static Map<String, Object> validateForDeferralApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (caseRecord.Deferral_Within_1_Month__c == 'NO') {
            response = handleDeferralApproval(caseRecord);
        } else {
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        }
        return response;
    }
    
    public static Map<String, Object> handleDeferralApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (String.isEmpty(caseRecord.DeferralApprovalStatus__c)) {
            response.put('status', 'error');
            response.put('message', 'Please submit for Deferral approval.');
        } else if (caseRecord.DeferralApprovalStatus__c == 'Approved') {
            
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        } else {
            response.put('status', 'error');
            response.put('message', 'Cannot move to next review since the Deferral approval is Rejected/Pending.');
        }
        
        return response;
    }
    
    public Map<String, Object> validateCaseEligibility(String caseId){
        Map<String, Object> response = new Map<String, Object>();
        CaseService serviceObj = CaseService.getInstance();
        Case caseRec = serviceObj.getCaseById(caseId);
        List<CaseInstallment__c> caseInstallmentLines = serviceObj.getCaseInstallmentByRecordId(caseId);
        
        if (caseInstallmentLines.isEmpty()) { 
            response.put('status', 'error');
            response.put('message', 'There are no new dates to populate');
            return response;
        }
        else{
            return copyNewInstallmentDates(caseInstallmentLines,caseRec);
        }
        
    }
    /*
* Purpose: Updates the maturity date on receipt acknowledgements
*          related to postponed installments using the revised installment date.
*
* Updated by: Sonali Sengar 
* Date: 2025-07-30
*/
    public Map<String, Object>  copyNewInstallmentDates(List<CaseInstallment__c> caseInstallmentLines,Case caseRec) {
        Map<String, Object> response = new Map<String, Object>();
        List<InstallmentLines__c>  installmentsToUpdate = new  List<InstallmentLines__c> ();
        Map<Id,ReceiptAcknowledgement__c> acknowledgementsToUpdate = new Map<Id,ReceiptAcknowledgement__c>();
        Set<Id> actualInstallmentIds = new Set<Id>();
        
        InstallmentLineService installServiceObj = InstallmentLineService.getInstance();
        
        for (CaseInstallment__c caseInstallment : caseInstallmentLines) {
            InstallmentLines__c lineToUpdate = new InstallmentLines__c(
                Id = caseInstallment.Installment__c,
                RevisedDate__c = caseInstallment.NewInstallmentDate__c,
                Send_to_SAP__c = true
            );
            actualInstallmentIds.add(caseInstallment.Installment__c);
            installmentsToUpdate.add(lineToUpdate);
        }
        
        
        installServiceObj.updateInstallmentLines(installmentsToUpdate);
        
        
        List<InstallmentLines__c> actualInstallments = new List<InstallmentLines__c>();
        if(!actualInstallmentIds.isEmpty()){
            actualInstallments = installServiceObj.getInstallmentLinesByIds(actualInstallmentIds);
            for(InstallmentLines__c ins : actualInstallments){
                if(!ins.Receipt_Allocations__r.isEmpty()){
                    for(ReceiptAllocation__c reciept : ins.Receipt_Allocations__r){
                        ReceiptAcknowledgement__c ackToUpdate = new ReceiptAcknowledgement__c();
                        ackToUpdate.id =reciept.ReceiptAcknowledgement__c;
                        ackToUpdate.New_Maturity_Date__c = ins.RevisedDate__c;
                        acknowledgementsToUpdate.put(reciept.ReceiptAcknowledgement__c,ackToUpdate);
                    } 
                }
            }
        }
        if (!acknowledgementsToUpdate.isEmpty()) {  
            ReceiptAcknowledgementService servObj = ReceiptAcknowledgementService.getInstance();
            servObj.updateReceiptAcknowledgements(acknowledgementsToUpdate.values());
        }
        response.put('status', 'success');
        response.put('message', 'Installments successfully updated');
        sendEmailForUpdatedPaymentInstallment(caseRec);
        return response;
    }
    public  void sendEmailForUpdatedPaymentInstallment(Case caseRecord) { 
        MetadataService objMetadataService = MetadataService.getInstance();
        CaseService servObj =  CaseService.getInstance();
        BankAccountService bnkServObj = BankAccountService.getInstance();
        Case caseRec = new Case();
        caseRec = servObj.getCaseById(caseRecord.Id);
        if(caseRec.StopEmailsToCustomer__c){
            return;
        }
        AccountService accService = AccountService.getInstance();
        String customerEmail =  accService.getRelatedContactEmail(caseRec.AccountId);
        
        List<CaseInstallment__c> installments = servObj.getCaseInstallmentByRecordId(caseRecord.Id);
        List<BankAccount__c> bankAccounts = bnkServObj.getBankAccountByProject('Escrow',caseRecord.Sales_Order__r.Project__c);
        
        if (installments.isEmpty()) {
            return;
        }
        EmailService objEmailService = EmailService.getInstance();
        EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(INSTALLMENT_POSTPONEMENT_EMAIL_TEMPLATE_ID));
        String emailBody = emailTemplate.HtmlValue;
        List<String> toAddresses = new List<String>{customerEmail};             
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        String subject = 'Installment Postponement Approved for SO# ' + caseRec.Sales_Order__r.Sales_Order_Number__c;
        String htmlBody = objEmailService.buildInstallmentPostponementEmailBody(caseRec, installments,bankAccounts);
        emailBody=emailBody.replace('{{INSTALLMENTTABLE}}', htmlBody);
        Messaging.SingleEmailMessage mail = objEmailService.getSingleEmailMessage(toAddresses, subject, emailBody, bloomNoReplySalesOWEId);
        mail.setSaveAsActivity(true); 
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {mail};
        Messaging.SendEmailResult[] results =  objEmailService.sendEmail(messages);
    }  
    
    public  Map<String, Object> postponeApprovalUpdate(Id caseId, String selectedValue) {
        Map<String, Object> response = new Map<String, Object>();
        if (String.isBlank(selectedValue)) {
            response.put('status', 'error');
            response.put('message', 'Please Select an option.');
        }
        if(caseId != null ){
            CaseService caseServiceObj = CaseService.getInstance(); 
            Case caseToUpdate = new Case();
            caseToUpdate.id = caseId;
            caseToUpdate.PostponeApproved__c = selectedValue;
            Case updatedCase = caseServiceObj.updateCase(caseToUpdate);
            response.put('status', 'Success');
            response.put('message', 'The Case is Updated Successfully');
            if(selectedValue =='Yes'){
                response = validateCaseEligibility(caseId);
            }
        }
        else {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
        }
        return response;
    }  
}
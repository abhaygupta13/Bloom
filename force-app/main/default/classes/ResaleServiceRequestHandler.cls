/*****************************************************************************************
Class       : ResaleServiceRequestHandler
Author      :  Sonali S
Description : 
test Class  : ResaleServiceRequestHandlerTest 
Created Date: 5/16/2025  -
Updated date -  latest 26/03
*****************************************************************************************/ 
public inherited sharing class ResaleServiceRequestHandler { 
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION_RT { get { return 'Resale_Property_Under_Construction'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string MERGED_INSTALLMENT_CONDITION_TYPE  {get {return 'P145'; }}
    private static final string MTD_CUSTOMER_APPOINTMENT_BOOKING_EMAIL_TEMPLATE_ID { get { return 'CustomerAppointmentBookingTemplateId'; } }
    List<String> requiredDocTypes = new List<String>{'MOU','Buyer Passport','CIF','Undertaking Letter','Resale Cancellation', 'POA Document','Buyer Emirates ID'};
    
    private static ResaleServiceRequestHandler instance;
    
    private ResaleServiceRequestHandler() {
        
    }
    public static ResaleServiceRequestHandler getInstance() { 
        if(instance == null) {
            instance = new ResaleServiceRequestHandler();
        }
        return instance;
    }
    public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        if(salesOrderObj != null && salesOrderObj.Status__c != 'Sold'){
            message = 'This unit is not eligible for the selected service request';
        }
        else if(salesOrderObj !=null && salesOrderObj.IsDefaulted__c == true){
            message = 'A Resale request cannot be created for a defaulted unit';
        }
        
        return message;
    }
    public void sendNewServiceRequestAssignmnmentEmailNotification(List<Case> caseList){
        
        Case caseee = CaseService.getInstance().getCaseById(caseList[0].id);
     
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        List<String> emailAddresses = new List<String> ();
        
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID);
        if(emailTemplateId!=null){
            for(Case caseObj : caseList){
                if(caseobj.CaseType__c == 'Service Request' && !caseobj.StopEmailsToCustomer__c){
                    if(caseObj.ContactId!=null){
                        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId,  caseobj.Id, caseObj.ContactId, null,null,null);  
                        emailList.add(email);
                    }
                    else{
                        if(caseee.Account__r.CompanyEmail__c!=null){
                            emailAddresses.add(caseee.Account__r.CompanyEmail__c);
                            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectAsRecipient(emailAddresses,emailTemplateId,caseobj.Id,null, noReplyOWDId);  
                            emailList.add(email);    
                        }
                    }
                }
                else {
                    return;
                }
            }
            if(!emailList.isEmpty()){
                objEmailService.sendEmail(emailList);  
            } 
        }
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
        InstallmentLineService insServiceObj = InstallmentLineService.getInstance();
        HandoverService objHandoverService = HandoverService.getInstance();

        Case newCase = new Case();
        
        newCase.AccountId = (salesOrderObj != null) ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = (salesOrderObj != null) ? salesOrderObj.Unit__c : unitId;
        
        if (salesOrderObj != null) {
            newCase.Subject = sc.SubCategory__c + '-' + salesOrderObj.Unit__r.Name;
            if(accService.getRelatedContact(salesOrderObj.Account__r.Id)!=null){
               newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);  
            }
           
            newCase.Sales_Order__c = salesOrderObj.Id;
            Map<Id,Decimal> orderWiseClearedAmt = new  Map<Id,Decimal>();
            orderWiseClearedAmt = evaluateCustomerPaidAmount(salesOrderObj);
            
            Decimal netAmount = 0;
           
            if(salesOrderObj.SalesPriceExcludingADMWithDiscount__c != null 
               && salesOrderObj.SalesPriceExcludingADMWithDiscount__c>0){
               netAmount =  salesOrderObj.SalesPriceExcludingADMWithDiscount__c;
            }
            else if(salesOrderObj.SalesPriceExcludingADMWithDiscount__c <=1
                    && salesOrderObj.Sales_Price_Excluding_ADM__c!= null 
                    && salesOrderObj.Sales_Price_Excluding_ADM__c >0
                    && (salesOrderObj.ADM_Fee_Combined__c == null ||salesOrderObj.ADM_Fee_Included__c == False)
                    ){
                        
             netAmount = salesOrderObj.Sales_Price_Excluding_ADM__c 
          + (salesOrderObj.Discount__c != null ? salesOrderObj.Discount__c : 0);
            
            }
           
            Decimal cleared = orderWiseClearedAmt.containsKey(salesOrderObj.Id) ? orderWiseClearedAmt.get(salesOrderObj.Id) : 0;
            
          
            Decimal percentagePaid = 0;
            Decimal resaleToCompleteAmt = 0;
            Decimal billingToCompleteAmt = 0;
            Decimal actualInstallmentDuePercent = 0;
            
            List<InstallmentLines__c> insDueTillDate = insServiceObj.getInstallmentLinesDueTillDateBySalesOrder(salesOrderObj.id);
            
            if(!insDueTillDate.isEmpty()){ 
                for(InstallmentLines__c line : insDueTillDate){
                    if(line.InstallmentPercentage__c != null && line.InstallmentPercentage__c != 0){
                        actualInstallmentDuePercent += line.InstallmentPercentage__c;
                    }
                }
            }

            Decimal resaleThreshold = salesOrderObj.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c!= null?salesOrderObj.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c:0;
            Decimal higherResaleThreshold = resaleThreshold>actualInstallmentDuePercent ? resaleThreshold : actualInstallmentDuePercent;
            newCase.ActualInstallmentDuePercentage__c = actualInstallmentDuePercent;
           
            if (netAmount > 0) {
                percentagePaid = (cleared / netAmount) * 100;
                billingToCompleteAmt =netAmount * 0.01*higherResaleThreshold;
            }
            if(cleared > 0){
              newCase.TotalCollection__c = cleared;
              newCase.CustomerPaidPercentage__c =percentagePaid.setScale(2); // round to 2 decimal places    
            }
                 
            if(percentagePaid < higherResaleThreshold){
                newCase.IsPaymentReviewRequired__c = true; 
                Decimal resaleToCompletePercent = higherResaleThreshold-percentagePaid;
                newCase.ResaleToCompleteAmount__c = netAmount - billingToCompleteAmt;
                newCase.BillingToCompleteAmount__c = billingToCompleteAmt;
            }
            else{
                 newCase.ResaleToCompleteAmount__c = 0;
                 newCase.BillingToCompleteAmount__c = billingToCompleteAmt;
            }
            
            
            if(salesOrderObj.Unit__r.RegistrationDate__c!=null){
                newCase.UnitRegistered__c = 'Yes';   
            }
            else{
                newCase.UnitRegistered__c = 'No';      
            }
            
            newCase.City__c = salesOrderObj.Unit__r.Project__r.City__c;
            /*if(salesOrderObj.Unit__r.Project__r.City__c!='Dubai'){
              newCase.HassantukFee__c = 1000;  
            }*/
            
            if(!String.isEmpty(salesOrderObj.Unit__r.Legal_Status__c)
               &&salesOrderObj.Unit__r.Legal_Status__c == 'With Legal'){
            newCase.isLegalReviewRequired__c = true;
        }
        }
       
        
       
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.Description = description;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;

        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        if(!Test.isRunningTest() && newCase.Id != null  && newCase.BillingToCompleteAmount__c != null && newCase.BillingToCompleteAmount__c > 0){
            Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(newCase.Id, 'BillingToCompleteAmountInArabic__c', newCase.BillingToCompleteAmount__c));
        }
      
        Map<Id,Handover__c> handoverMap = objHandoverService.getHandoverWithSalesOrders(new Set<Id>{salesOrderObj.Id});

        if(handoverMap != NULL && !handoverMap.isEmpty() && handoverMap.values() != NULL){
            Handover__c hoRecToUpdate = handoverMap.values()[0];
            hoRecToUpdate.Sub_Status__c = 'Under Resale';
            objHandoverService.updateHandover(hoRecToUpdate);
        }
        return newCase; 
    } 
    
    public Map<String, Object> validateCompletedProjectForNextReview(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        
        if (caseRecord.Step__c != 'Final' &&
            (String.isEmpty(caseRecord.Step__c) || Integer.valueOf(caseRecord.Step__c) < 1)) {
                response.put('status', 'error');
                response.put('message', 'Invalid Case Step.');
                return response;
            }
        
        response = checkCompletedProjectRequiredFields(caseRecord);
        
        if (response.get('status') == 'error') {
            return response;
        }
        
        ResaleServiceRequestHandler resaleHandler = ResaleServiceRequestHandler.getInstance();
        
        if (caseRecord.Step__c == '1') {
            response = resaleHandler.validateForPaymentReviewApproval(caseRecord);
            if (response.get('status') == 'success') {
                response = resaleHandler.validateForLegalStatusApproval(caseRecord);
                if (response.get('status') == 'success') {
                    response = resaleHandler.validateBuyerLegalApproval(caseRecord);
                }
            }
        }
        if(caseRecord.Step__c =='4'){
            response = validateFinanceSecondStep(caseRecord);
        }
        if (response.get('status') != 'success') {
            return response;
        }
        
        String city = caseRecord.City__c;
        String step = caseRecord.Step__c;
        if (step == '2') {
            resaleHandler.createNewCustomerAndSalesOrderRecord(caseRecord);
            if(!Test.isRunningTest() && caseRecord.Id != null  && caseRecord.BillingToCompleteAmount__c != null && caseRecord.BillingToCompleteAmount__c > 0){
                Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(caseRecord.Id, 'BillingToCompleteAmountInArabic__c', caseRecord.BillingToCompleteAmount__c));
            }
        }
        else if(step=='3'){
         updateCRMRepresentative(caseRecord);
            
        }
        else if (step == '4') {
            resaleHandler.cancelAndReassignSalesOrdersForResale(caseRecord);
        }
         else if (step == 'Final') {
            resaleHandler.updateBrokerDetails(caseRecord);
            resaleHandler.cancelAndReassignSalesOrdersForResale(caseRecord);
        }
           
        handleNextSteps(caseRecord);
        return response;
    } 
    public void updateCRMRepresentative(Case caseRecord){
        List<SalesOrder__c> salesOrders = new  List<SalesOrder__c>();
        SalesOrder__c ordrToUpdate = new SalesOrder__c();
        ordrToUpdate.Id = caseRecord.NewSalesOrder__c;
        ordrToUpdate.CRMRepresentative__c = UserInfo.getUserId();
        salesOrders.add(ordrToUpdate);
        SalesOrderservice servObj = SalesOrderservice.getInstance();
        servObj.updateSalesOrdersWithoutTrigger(salesOrders);
        
    }
    public Map<String, Object> validateFinanceSecondStep(Case caseRecord){
        
        Map<String, Object> response = new Map<String, Object>();
        response = validateOldReceiptsForSAPDocNo(caseRecord);
        if(response.get('status') == 'success'){
        if(caseRecord.BillingToCompleteAmount__c > caseRecord.TotalCollection__c){
          response.put('status', 'error');
          response.put('message', 'Total collection is less that Billing to complete amount');
          
        }
        else{
          response.put('status', 'success');
          response.put('message', 'Case moved to next review successfully.');
        }
        }
        return response;   
    }
    public  Map<String, Object> validateResaleForNextReview(Case caseRecord) {
        System.debug('caseRecord'+caseRecord);
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
        response = checkUnderConstructionRequiredFields(caseRecord);
        if (response.get('status') == 'error') {
            return response;
        }
        if (caseRecord.Step__c == '1') {
            response = validateForPaymentReviewApproval(caseRecord);   
            if(response.get('status')=='success'){
                response = validateForLegalStatusApproval(caseRecord);
                if(response.get('status')=='success'){
                    response =validateBuyerLegalApproval(caseRecord); 
                }
                if (response.get('status') == 'success') {
                    List<ContentDocumentLink> docs = validateDocuments(caseRecord);

                    Integer docCount = docs.size();
                    Boolean isEmpty = docs.isEmpty();
                    
                    // Flags based on conditions
                   Boolean mouRequired = !(caseRecord.TypeOfResale__c == 'Addition of Kin'||
                                          caseRecord.TypeOfResale__c == 'Deletion of Kin' || 
                                            caseRecord.TypeOfResale__c == 'Gifting');
                    Boolean emiratesIdRequired = (caseRecord.Customer_Type__c != 'International' && caseRecord.Customer_Type__c !='GCC');
                    
                    // Expected docs calculation
                    Integer expectedDocs = 2; // Buyer + Seller Passport are always required
                    if (mouRequired) expectedDocs++;
                    if (emiratesIdRequired) expectedDocs += 1; // Buyer + Seller Emirates ID
                    
                    if (isEmpty || docCount < expectedDocs) {
                        // Build dynamic error message
                        List<String> requiredDocs = new List<String>();
                        if (mouRequired) requiredDocs.add('MOU');
                        requiredDocs.add('Buyer Passport');
                        requiredDocs.add('Seller Passport');
                        if (emiratesIdRequired) {
                            requiredDocs.add('Buyer Emirates ID');
                            //requiredDocs.add('Seller Emirates ID');
                        }
                        
                        response.put('status', 'error');
                        response.put('message', 'Please upload: ' + String.join(requiredDocs, ', ') + '.');
                        return response;
                    }
                } 
            }
        }
        
        if(response.get('status')=='success'){
            if (Test.isRunningTest()) {
    return response;
}
            updateCaseRecordTypeAndCatalog(caseRecord);
            
        }
        
        
        return response;
        
        
        
    }
    public  Map<String, Object> validateUnderConstructionForNextReview(Case caseRecord) {
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
        response = checkUnderConstructionRequiredFields(caseRecord);
        if (response.get('status') == 'error') {
            return response;
        }
        if (caseRecord.Step__c == '1') {
            response = validateForPaymentReviewApproval(caseRecord);   
            if(response.get('status')=='success'){
                response = validateForLegalStatusApproval(caseRecord);
                if(response.get('status')=='success'){
                    response =validateBuyerLegalApproval(caseRecord); 
                }
            }
        }
        if(caseRecord.Step__c =='4'){
            response = validateFinanceSecondStep(caseRecord);
        }
        
        if(response.get('status')=='success'){
            if(caseRecord.Step__c=='2'){
                createNewCustomerAndSalesOrderRecord(caseRecord);
                if(!Test.isRunningTest() && caseRecord.Id != null  && caseRecord.BillingToCompleteAmount__c != null && caseRecord.BillingToCompleteAmount__c > 0){
                    Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(caseRecord.Id, 'BillingToCompleteAmountInArabic__c', caseRecord.BillingToCompleteAmount__c));
                }
               Case caseRec= CaseService.getInstance().getCaseById(caseRecord.Id);
                SalesOrder__c SalesOrderRec = SalesOrderService.getInstance().getSalesOrderByCaseId(caseRec.NewSalesOrder__c);
          if(!Test.isRunningTest() && SalesOrderRec.Id != null  && SalesOrderRec.Sales_Order_Pending_Amount__c != null && SalesOrderRec.Sales_Order_Pending_Amount__c > 0){
                Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(SalesOrderRec.Id, 'Sales_Order_Pending_Amount_in_Words_Arab__c', SalesOrderRec.Sales_Order_Pending_Amount__c));
                }
            }
            if(caseRecord.Step__c =='3'){
                updateCRMRepresentative(caseRecord);
            }
            if(caseRecord.Step__c =='4'){
                cancelAndReassignSalesOrdersForResale(caseRecord);
                
            }
            if (caseRecord.Step__c == 'Final') {
               updateBrokerDetails(caseRecord);
          
        }
            handleNextSteps(caseRecord); 
        }
        
        return response;
    } 
     public Map<String,Object> validateOldReceiptsForSAPDocNo(Case caseRecord){
        
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Case moved to next review successfully.');
        
        ReceiptAcknowledgementService receiptService = ReceiptAcknowledgementService.getInstance(); 
        List<ReceiptAcknowledgement__c> receipts =  receiptService.getAllReceiptAcknowledgementBySalesOrders(new Set<Id>{caseRecord.Sales_Order__c});
        if(!receipts.isEmpty()){
            for(ReceiptAcknowledgement__c rec : receipts){
                if(rec.Due_Date__c<=System.today()
                   && String.isBlank(rec.SAP_Document_No__c)
                   && rec.PaymentType__c !='Security Cheque'
                   && rec.PaymentType__c !='Transfer of rights - Resale'
                   && rec.Status__c  != 'Reversed' 
                   && rec.SAP_Condition_Type__c != 'P145'){
                       response.put('status', 'error');
                       response.put('message', 'Please ensure all past-dated receipts are successfully integrated with SAP.');

                   }
            }   
        }
        
        return response;
    }
    public Map<String, Object> validatePHPPForNextReview(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        ResaleServiceRequestHandler resaleUnderConstructionObj = ResaleServiceRequestHandler.getInstance();
        
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        
        if (caseRecord.Step__c != 'Final' &&
            (String.isEmpty(caseRecord.Step__c) || Integer.valueOf(caseRecord.Step__c) < 1)) {
                response.put('status', 'error');
                response.put('message', 'Invalid Case Step.');
                return response;
            }
        
        response = checkPHPPRequiredFields(caseRecord);
        if (response.get('status') == 'error') {
            return response;
        }
        
        
        if (caseRecord.Step__c == '1') {
            response = resaleUnderConstructionObj.validateForPaymentReviewApproval(caseRecord);   
            if(response.get('status')=='success'){
                response = resaleUnderConstructionObj.validateForLegalStatusApproval(caseRecord);
                if(response.get('status')=='success'){
                    response = resaleUnderConstructionObj.validateBuyerLegalApproval(caseRecord); 
                }
            }
        }
        if(caseRecord.Step__c =='5'){
            response = validateFinanceSecondStep(caseRecord);
        }
        
        if (response.get('status') == 'success') {
            if(caseRecord.Step__c=='2'){
                resaleUnderConstructionObj.createNewCustomerAndSalesOrderRecord(caseRecord);
                if(!Test.isRunningTest() && caseRecord.Id != null  && caseRecord.BillingToCompleteAmount__c != null && caseRecord.BillingToCompleteAmount__c > 0){
                    Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(caseRecord.Id, 'BillingToCompleteAmountInArabic__c', caseRecord.BillingToCompleteAmount__c));
                }
                 Case caseRec= CaseService.getInstance().getCaseById(caseRecord.Id);
                SalesOrder__c SalesOrderRec = SalesOrderService.getInstance().getSalesOrderByCaseId(caseRec.NewSalesOrder__c);
          if(!Test.isRunningTest() && SalesOrderRec.Id != null  && SalesOrderRec.Sales_Order_Pending_Amount__c != null && SalesOrderRec.Sales_Order_Pending_Amount__c > 0){
                Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(SalesOrderRec.Id, 'Sales_Order_Pending_Amount_in_Words_Arab__c', SalesOrderRec.Sales_Order_Pending_Amount__c));
                }
            }
             if(caseRecord.Step__c =='4'){
                updateCRMRepresentative(caseRecord);
            }
          
            if(caseRecord.Step__c =='5') {
                resaleUnderConstructionObj.cancelAndReassignSalesOrdersForResale(caseRecord);
            }
               if (caseRecord.Step__c == 'Final') {
            resaleUnderConstructionObj.updateBrokerDetails(caseRecord);
          
        }
            
            handleNextSteps(caseRecord);
        }
        return response;
    }
    
    public Map<String, Object> checkCompletedProjectRequiredFields(Case caseObj) {
        Map<String, Object> response = new Map<String, Object>();
        String genericMsg = 'The case is not valid to move to next step, please fill all the required details.';
        
        if (caseObj.Step__c == '1') {
            if (!validateStep1(caseObj)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            
            if(caseObj.Step__c == '1' && caseObj.City__c == 'Abu Dhabi'){
                if (String.isEmpty(caseObj.UnitRegistered__c) ||
                    String.isEmpty(caseObj.ConsumptionSettled__c) ||
                    String.isEmpty(caseObj.ADDC_Transferred__c) ||
                    String.isEmpty(caseObj.Title_Deed_Issued__c) ||
                    String.isEmpty(caseObj.TitleDeedShared__c) ||
                    String.isEmpty(caseObj.PaymentReceived__c)) {
                        response.put('status', 'error');
                        response.put('message', genericMsg);
                        return response;
                }
            }
            
            
            /*if (String.isEmpty(caseObj.CustomerType__c)) {
                response.put('status', 'error');
                response.put('message', 'Please fill New Buyer Details.');
                return response;
            }*/
            
            /*if (caseObj.CustomerType__c == 'Person' && !validatePersonDetails(caseObj)) {
                response.put('status', 'error');
                response.put('message', 'Please fill new Customer details.');
                return response;
            }
            
            if (caseObj.CustomerType__c == 'Organization' && !validateOrganizationDetails(caseObj)) {
                response.put('status', 'error');
                response.put('message', 'Please fill Company details.');
                return response;
            }*/
             if (caseObj.NewCustomerAccount__c == null) {
                response.put('status', 'error');
                response.put('message', 'Please fill new Customer details.');
                return response;
            }
            
            
            if(!validateJointBuyerDetails(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please fill Joint Buyer details.');
                return response;
                
            }
            if(!validateADMFees(caseObj)){
               response.put('status', 'error');
               response.put('message', 'Please fill ADM Fee details.');
                return response; 
            }
       
                if(caseObj.TypeOfResale__c == 'Deletion of Name' 
                   ||caseObj.TypeOfResale__c == 'Deletion of Kin'){
                       if(!validateDeletedOwner(caseObj)){
                           response.put('status', 'error');
                           response.put('message', 'Please add deleted owner details before proceeding.');
                           return response;  
                       }
                       if (!validateDeletedOwnerDetails(caseObj)) {
                           response.put('status', 'error');
                           response.put('message', 'Deleted owner must be an existing buyer or joint owner on the Sales Order.');
                           return response;
                       }
            }

            if(!Test.isRunningTest() && caseObj.Id != null  && caseObj.ResalePrice__c != null && caseObj.ResalePrice__c > 0){
                Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(caseObj.Id, 'ResalePriceInArabicWords__c', caseObj.ResalePrice__c));
            }
        }
        
        if (caseObj.Step__c == '2') {
            if (!validateStep2(caseObj)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            if (validateDocumentByName(caseObj,'Statement of Account').isEmpty()) {
                response.put('status', 'error');
                response.put('message', 'Please upload Statement of Account.');
                return response;
            }
        }
        
        if(caseObj.Step__c == '3'){
             if(String.isEmpty(caseObj.PaymentReceived__c)||
               String.isEmpty(caseObj.SmartHubActivated__c)){
                    response.put('status', 'error');
                    response.put('message', genericMsg);
                    return response;
               }
            if(!String.isEmpty(caseObj.PaymentReceived__c) 
               && caseObj.PaymentReceived__c == 'From Third Party Form'
               && validateDocumentByName(caseObj,'Third Party Form').isEmpty())
               {
                response.put('status', 'error');
                response.put('message', 'Please upload Third Party Form');
                return response;
              
            }
            if(!validateSPASignedDate(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please add Bloom Signed SPA Date on New Sales Order');
                return response;
            }
   
        }
        
    
        
        response.put('status', 'success');
        response.put('message', caseObj.Step__c == 'Final' ? 'Case closed successfully.' : 'Case moved to next review successfully.');
        return response;
    }
    public Map<String, Object> checkPHPPRequiredFields(Case caseObj) {
        Map<String, Object> response = new Map<String, Object>();
        String genericMsg = 'The case is not valid to move to next step, please fill all the required details.';
        
        if (caseObj.Step__c == '1') {
            if (!validateStep1(caseObj)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            
            if (caseObj.City__c == 'Dubai' && String.isEmpty(caseObj.Seller_Settled__c)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            
            /*if (String.isEmpty(caseObj.CustomerType__c)) {
                response.put('status', 'error');
                response.put('message', 'Please fill customer type.');
                return response;
            }
            
            if (caseObj.CustomerType__c == 'Person' && !validatePersonDetails(caseObj)) {
                response.put('status', 'error');
                response.put('message', 'Please fill new buyer details.');
                return response;
            }
            
            if (caseObj.CustomerType__c == 'Organization' && !validateOrganizationDetails(caseObj)) {
                response.put('status', 'error');
                response.put('message', 'Please fill Company details.');
                return response;
            }*/
              if (caseObj.NewCustomerAccount__c == null) {
                response.put('status', 'error');
                response.put('message', 'Please fill new Customer details.');
                return response;
            }
              if(!validateJointBuyerDetails(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please fill Joint Buyer details.');
                return response;
                
            }
               if(!validateADMFees(caseObj)){
               response.put('status', 'error');
               response.put('message', 'Please fill ADM Fee details.');
                return response; 
            }
              if(caseObj.TypeOfResale__c == 'Deletion of Name' 
                   ||caseObj.TypeOfResale__c == 'Deletion of Kin'){
                       if(!validateDeletedOwner(caseObj)){
                           response.put('status', 'error');
                           response.put('message', 'Please add deleted owner details before proceeding.');
                           return response;  
                       }
                       if (!validateDeletedOwnerDetails(caseObj)) {
                           response.put('status', 'error');
                           response.put('message', 'Deleted owner must be an existing buyer or joint owner on the Sales Order.');
                           return response;
                       }
            }
            if(!Test.isRunningTest() && caseObj.Id != null  && caseObj.ResalePrice__c != null && caseObj.ResalePrice__c > 0){
                Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(caseObj.Id, 'ResalePriceInArabicWords__c', caseObj.ResalePrice__c));
            }
        }
        
        if (caseObj.Step__c == '2') {
            if (!validateStep2(caseObj)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            if (validateDocumentByName(caseObj,'Statement of Account').isEmpty()) {
                response.put('status', 'error');
                response.put('message', 'Please upload Statement of Account.');
                return response;
            }
        }
        
        if (caseObj.Step__c == '4') {
            if ((caseObj.City__c == 'Dubai' &&
                 (String.isEmpty(caseObj.Pre_title_deed_shared__c) ||
                  String.isEmpty(caseObj.IsBuyerFinancing__c))) ||
                (caseObj.City__c == 'Abu Dhabi' && String.isEmpty(caseObj.Unit_Mortgaged__c))) {
                    response.put('status', 'error');
                    response.put('message', genericMsg);
                    return response;
                }
            if(String.isEmpty(caseObj.PaymentReceived__c)||
               String.isEmpty(caseObj.SmartHubActivated__c)){
                    response.put('status', 'error');
                    response.put('message', genericMsg);
                    return response;
               }
               if(!String.isEmpty(caseObj.PaymentReceived__c) 
               && caseObj.PaymentReceived__c == 'From Third Party Form'
               && validateDocumentByName(caseObj,'Third Party Form').isEmpty()
               )
               {
                response.put('status', 'error');
                response.put('message', 'Please upload Third Party Form.');
                return response;
              
            }
             if(!validateSPASignedDate(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please add Bloom Signed SPA Date');
                return response;
            }
        }
        
        if (caseObj.Step__c == '6') {
            if (caseObj.City__c == 'Abu Dhabi' && String.isEmpty(caseObj.Rented__c)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
        }
        
        response.put('status', 'success');
        response.put('message', caseObj.Step__c == 'Final' ? 'Case closed successfully.' : 'Case moved to next review successfully.');
        return response;
    }
    public Map<String, Object> checkUnderConstructionRequiredFields(Case caseObj) {
        Map<String, Object> response = new Map<String, Object>();
        String genericMsg = 'The case is not valid to move to next step, please fill all the required details.';
        
        if (caseObj.Step__c == '1') {
            if (!validateStep1(caseObj)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            
            /*if (String.isEmpty(caseObj.CustomerType__c)) {
                response.put('status', 'error');
                response.put('message', 'Please fill New Buyer Details.');
                return response;
            }
            
            if (caseObj.CustomerType__c == 'Person' && !validatePersonDetails(caseObj)) {
                response.put('status', 'error');
                response.put('message', 'Please fill new customer details.');
                return response;
            }
            
            if (caseObj.CustomerType__c == 'Organization' && !validateOrganizationDetails(caseObj)) {
                response.put('status', 'error');
                response.put('message', 'Please fill company details.');
                return response;
            }*/
              if (caseObj.NewCustomerAccount__c == null) {
                response.put('status', 'error');
                response.put('message', 'Please fill new Customer details.');
                return response;
            }
              if(!validateJointBuyerDetails(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please fill Joint Buyer details.');
                return response;
                
            }
            if(!validateADMFees(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please fill ADM Fee details.');
                return response; 
            }
              if(caseObj.TypeOfResale__c == 'Deletion of Name' 
                   ||caseObj.TypeOfResale__c == 'Deletion of Kin'){
                       if(!validateDeletedOwner(caseObj)){
                           response.put('status', 'error');
                           response.put('message', 'Please add deleted owner details before proceeding.');
                           return response;  
                       }
                       if (!validateDeletedOwnerDetails(caseObj)) {
                           response.put('status', 'error');
                           response.put('message', 'Deleted owner must be an existing buyer or joint owner on the Sales Order.');
                           return response;
                       }
            }
            if(!Test.isRunningTest() && caseObj.Id != null  && caseObj.ResalePrice__c != null && caseObj.ResalePrice__c > 0){
                Id jobId = System.enqueueJob(new GetAmountInWordsQueueable(caseObj.Id, 'ResalePriceInArabicWords__c', caseObj.ResalePrice__c));
            }
        }
        
        if (caseObj.Step__c == '2') {
            if (!validateStep2(caseObj)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
            
            if (validateDocumentByName(caseObj,'Statement of Account').isEmpty()) {
                response.put('status', 'error');
                response.put('message', 'Please upload Statement of Account.');
                return response;
            }
        }
        
        if (caseObj.Step__c == '3') {
            if (String.isEmpty(caseObj.PaymentReceived__c)
                ||String.isEmpty(caseObj.SmartHubActivated__c)) {
                response.put('status', 'error');
                response.put('message', genericMsg);
                return response;
            }
             if(!String.isEmpty(caseObj.PaymentReceived__c) 
               && caseObj.PaymentReceived__c == 'From Third Party Form'
               && validateDocumentByName(caseObj,'Third Party Form').isEmpty())
               {
                response.put('status', 'error');
                response.put('message', 'Please upload Third Party Form');
                return response;
              
            }
             if(!validateSPASignedDate(caseObj)){
                response.put('status', 'error');
                response.put('message', 'Please add Bloom Signed SPA Date');
                return response;
            }
        }
        
        response.put('status', 'success');
        response.put('message', caseObj.Step__c == 'Final' ? 'Case closed successfully.' : 'Case moved to next review successfully.');
        return response;
    }
    public void updateCaseRecordTypeAndCatalog(Case caseObj){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        List<ServiceCatalog__c> scs = new  List<ServiceCatalog__c> ();
        
        if(caseObj.ResaleSubCategory__c == 'Resale Property Under Construction'){
            scs = servObj.getServiceCatalog('Service Request', 'Resale', caseObj.ResaleSubCategory__c);
        }
        else{
            scs = servObj.getServiceCatalogByLocation('Service Request', 'Resale', caseObj.ResaleSubCategory__c,caseobj.Unit__r.Project__r.City__c);                            
        }
        
        
        Id recTypeId = Utility.getRecordTypeIdByDevName(CASE.SObjectType,scs[0].RecordTypeDevName__c);      
        Case caseToUpdate = new Case();
        caseToUpdate.id = caseObj.id;
        caseToUpdate.ServiceCatalog__c = scs[0].id;
        caseToUpdate.RecordTypeId = recTypeId;
        caseToUpdate.Subject = scs[0].SubCategory__c + '-' + caseObj.Unit__r.Name;
        CaseService caseServiceObj = CaseService.getInstance();
        List<Case> caseList = caseServiceObj.updateCasesWithoutTrigger(new List<Case>{caseToUpdate});
        Case caseRec = caseServiceObj.getCaseById(caseList[0].id);
        handleNextSteps(caseRec); 
        
        
    }
    @TestVisible
    private Boolean validateADMFees(Case caseObj) {
        
    if (caseObj == null) return false;
        
     Boolean hasADM = caseObj.ADMTotalFees__c != null && caseObj.ADMAdminFees__c != null && caseObj.CancellationFees__c!=null;    
     Boolean hasTitleDeed = caseObj.TitleDeedFees__c !=null ||
                            (caseObj.TitleDeedFees__c >0 && !String.isEmpty(caseObj.BookTitleFeeUnder__c));
        
        if(caseObj.Title_Deed_Issued__c!=null 
           && caseObj.Title_Deed_Issued__c =='Yes'){
            return true;
        }
        if(caseObj.City__c =='Dubai'){
       
         return hasTitleDeed;
        }

   

    if (caseObj.ProjectStatus__c == 'Under Construction') {
        return hasADM;
    }

    if (caseObj.ProjectStatus__c == 'Completed') {
        Boolean hasEval = caseObj.EvaluationFees__c != null;
        if(caseObj.TypeOfResale__c == 'Gifting'
           ||caseObj.TypeOfResale__c =='Addition of Kin'
           ||caseObj.TypeOfResale__c =='Deletion of Kin'){
               return hasADM && hasEval && hasTitleDeed;
  }
        
         return hasADM && hasEval ;
  }
    
     

    return false;
}

    
    public Boolean validateStep1(Case caseObj) {
        String recordTypeName = Utility.getRecordTypeDevNameById('Case', caseObj.RecordTypeId);
        
        Boolean isValid = !String.isEmpty(caseObj.TypeOfResale__c) 
            && !String.isEmpty(caseObj.RegistrationStatus__c)
            && !String.isEmpty(caseObj.ProjectStatus__c)
            && !String.isEmpty(caseObj.ResaleSubCategory__c)
            && !String.isEmpty(caseObj.ResalePaymentType__c)
            && caseObj.ResalePrice__c!=null;
         
        
        
        if (!String.isEmpty(caseObj.TypeOfResale__c) &&
            ((caseObj.TypeOfResale__c == 'Addition of Name' 
              ||caseobj.TypeOfResale__c =='Deletion of Name'
              || caseobj.TypeOfResale__c =='Addition of Kin'
             || caseobj.TypeOfResale__c == 'Deletion of Kin') 
             && String.isEmpty(caseObj.InitialOwnerRemoved__c))) {
            isValid = false;
        }
        if(!String.isEmpty(caseObj.TypeOfResale__c) &&
           caseObj.TypeOfResale__c != 'Gifting' 
           && caseobj.TypeOfResale__c !='Addition of Kin'
           && caseobj.TypeOfResale__c !='Deletion of Kin'
           && String.isEmpty(caseobj.DirectIndirect__c)){
               isValid = false;
           }
        if(!String.isEmpty(caseObj.TypeOfResale__c)
           && caseObj.TypeOfResale__c =='Resale'
           && caseObj.MOUDate__c ==null){
               isValid = false;
           }
        if(!String.isEmpty(caseObj.TypeOfResale__c)
          && !String.isEmpty(caseObj.DirectIndirect__c)
          && caseObj.TypeOfResale__c != 'Gifting' 
          && caseobj.TypeOfResale__c !='Addition of Kin'
          && caseobj.TypeOfResale__c !='Deletion of Kin'
          && caseobj.DirectIndirect__c == 'Indirect'
          && (caseobj.BrokerAgency__c ==null || caseobj.Broker_Agent__c ==null || caseobj.Broker_Commission__c ==null)){
                  isValid = false;
              }
        
        return isValid;
    }
    
    private Boolean validateStep2(Case caseObj) {
        return caseObj.LatePaymentFees__c != null &&
            caseObj.BouncedChequeFees__c != null &&
            caseObj.RecoveryFee__c != null &&
            !String.isEmpty(caseObj.WithdrawlRequestInitiated__c) &&
            !String.isEmpty(caseObj.NewPDCReceived__c) &&
            !String.isEmpty(caseObj.ReversalRequestSubmittedForPDCs__c)&&
            caseObj.TotalCollection__c !=null &&
            caseObj.ChequeWithWithdrawlFees__c != null &&
            caseObj.PendingFees__c != null &&
            caseObj.ADDCAmount__c !=null;
        
        
    }
private Boolean validatePersonDetails(Case caseObj) {
    if(caseObj.NewCustomerAccount__c!=null){
        return true;
    }
    Boolean isBaseValid = 
        !String.isEmpty(caseObj.Last_Name__c) &&
        !String.isEmpty(caseObj.First_Name__c) &&
        !String.isEmpty(caseObj.PassportNumber__c) &&
        !String.isEmpty(caseObj.Nationality__c) &&
        caseObj.Address__City__s != null &&
        !String.isEmpty(caseObj.Mobile_Number__c) &&
        !String.isEmpty(caseObj.Mobile_Country_Code__c) &&
        !String.isEmpty(caseObj.Address__CountryCode__s) &&
        !String.isEmpty(caseObj.Address__PostalCode__s) &&
        !String.isEmpty(caseObj.Address__StateCode__s) &&
        !String.isEmpty(caseObj.Address__Street__s) &&
        !String.isEmpty(caseObj.Email_Address__c) &&
        !String.isEmpty(caseObj.BuyerNameInArabic__c) &&
        caseObj.PassportExpiryDate__c != null &&
        caseObj.PassportIssueDate__c != null &&
        !String.isEmpty(caseObj.Gender__c) &&
       // !String.isEmpty(caseObj.CustomerType__c) &&
        !String.isEmpty(caseObj.UAEResident__c)&&
        !String.isEmpty(caseObj.Salutation__c)&&
        !String.isEmpty(caseObj.PlaceofIssue__c)&&
        !String.isEmpty(caseObj.LanguagePreference__c)&&
        caseObj.Birthdate__c !=null ;

    // Extra check for Emirates ID only if NOT International
    Boolean isEmiratesValid = true;
    if(caseObj.Customer_Type__c != 'International' && caseObj.Customer_Type__c != 'GCC') {
        isEmiratesValid = 
            !String.isEmpty(caseObj.EmiratesID__c) &&
            caseObj.Emirates_ID_expiry_date__c != null;
    }

    return isBaseValid && isEmiratesValid;
}
    public Boolean validateDeletedOwner(Case caseObj) {
        List<DeletedOwner__c> deletedOwnerList =
            DeletedOwnerService.getInstance().fetchDeletedOwners(caseObj.Id);
        
        if (deletedOwnerList.isEmpty()) {
            return false;
        } 
        else{
            return true;
        }
    }
        
      
    public Boolean validateDeletedOwnerDetails(Case caseObj) {

    List<DeletedOwner__c> deletedOwnerList =
        DeletedOwnerService.getInstance().fetchDeletedOwners(caseObj.Id);

    if (deletedOwnerList.isEmpty()) {
        return true;
    }

    SalesOrder__c so = [
        SELECT Id, Account__c,
            (
                SELECT Id, Account__c
                FROM Joint_OwnersSalesOrder__r
            )
        FROM SalesOrder__c
        WHERE Id = :caseObj.Sales_Order__c
        LIMIT 1
    ];

    Set<Id> validOwnerAccountIds = new Set<Id>();

    if (so.Account__c != null) {
        validOwnerAccountIds.add(so.Account__c);
    }

    for (JointOwner__c jo : so.Joint_OwnersSalesOrder__r) {
        if (jo.Account__c != null) {
            validOwnerAccountIds.add(jo.Account__c);
        }
    }

    for (DeletedOwner__c deletedOwner : deletedOwnerList) {
        if (deletedOwner.Account__c == null ||
            !validOwnerAccountIds.contains(deletedOwner.Account__c)) {
            return false;
        }
    }

    return true;
}
    @TestVisible
    private Boolean validateJointBuyerDetails(Case caseObj) {
        JointOwnerService jointOwnerServiceObj = JointOwnerService.getInstance();
        List<JointOwner__c> jointOwnerList = jointOwnerServiceObj.fetchJointOwners(caseObj.id);
        Boolean isBaseValid = true;
        Boolean isEmiratesValid = true;
        if(!jointOwnerList.isEmpty()){
            for(JointOwner__c jointOwner : jointOwnerList){
               
              isBaseValid = !String.isEmpty(jointOwner.Last_Name__c)
                  &&!String.isEmpty(jointOwner.First_Name__c)
                  &&!String.isEmpty(jointOwner.Phone_Number__c)
                  &&!String.isEmpty(jointOwner.Email__c)
                  &&!String.isEmpty(jointOwner.Mobile_Country_Code__c)
                  &&!String.isEmpty(jointOwner.Gender__c)
                  &&jointOwner.PassportIssueDate__c != null
                  &&!String.isEmpty(jointOwner.Customer_Type__c)
                  &&!String.isEmpty(jointOwner.NameInArabic__c)
                  &&!String.isEmpty(jointOwner.Passport_Number__c)
                  &&jointOwner.Passport_Expiry_Date__c != null
                  &&!String.isEmpty(jointOwner.Nationality__c)
                  &&!String.isEmpty(jointOwner.Address__City__s)
                  &&!String.isEmpty(jointOwner.Address__CountryCode__s)
                  &&!String.isEmpty(jointOwner.Address__StateCode__s)
                  &&!String.isEmpty(jointOwner.Address__Street__s)
                  &&!String.isEmpty(jointOwner.Address__PostalCode__s)
                  &&!String.isEmpty(jointOwner.Salutation__c)
                  &&!String.isEmpty(jointOwner.Language_Preference__c)
                  &&jointOwner.Birthdate__c!=null
                  &&!String.isEmpty(jointOwner.UAEResident__c)
                  &&!String.isEmpty(jointOwner.PlaceofIssue__c);
                  
             // Extra check for Emirates ID only if NOT International
   
    if(jointOwner.Customer_Type__c != 'International' && jointOwner.Customer_Type__c != 'GCC') {
        isEmiratesValid = 
            !String.isEmpty(jointOwner.Emirates_ID__c) &&
            jointOwner.Emirates_ID_expiry_date__c != null;
    }
            }
        }

    return isBaseValid && isEmiratesValid;
}

    @TestVisible
    private Boolean validateOrganizationDetails(Case caseObj) {
        if(caseObj.NewCustomerAccount__c!=null){
            return true;
        }
        return caseObj.Mobile_Country_Code__c != null &&
            !String.isEmpty(caseObj.Mobile_Number__c) &&
            !String.isEmpty(caseObj.Address__CountryCode__s) &&
            !String.isEmpty(caseObj.Address__PostalCode__s) &&
            !String.isEmpty(caseObj.Address__StateCode__s) &&
            !String.isEmpty(caseObj.Address__Street__s) &&
            !String.isEmpty(caseObj.Email_Address__c) &&
            !String.isEmpty(caseObj.Name__c) &&
            !String.isEmpty(caseObj.Trade_License_No__c) &&
            caseObj.Trade_License_Issue_Date__c != null &&
            caseObj.Trade_License_Expiry_Date__c != null &&
            !String.isEmpty(caseObj.Registration_Authority__c);
    }
    public Map<String, Object> validateForPaymentReviewApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if ((caseRecord.CustomerPaidPercentage__c < caseRecord.Sales_Order__r.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c)
            && !caseRecord.WillMakeMorePayment__c) {
            response = handlePaymentReviewApproval(caseRecord);
        } else {
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        }
        return response;
    }
    public Map<String, Object> validateForLegalStatusApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (!String.isEmpty(caseRecord.Unit__r.Legal_Status__c)
            && caseRecord.Unit__r.Legal_Status__c =='With Legal'
            && caseRecord.isLegalReviewRequired__c == true) {
                response = handleLegalStatusApproval(caseRecord);
            } else {
                response.put('status', 'success');
                response.put('message', 'Case moved to next review successfully.');
            }
        return response;
    }
    public Map<String, Object> handleLegalStatusApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (String.isEmpty(caseRecord.LegalApprovalStatus__c)) { 
            response.put('status', 'error');
            response.put('message', 'Since the account is with legal, Please submit for Legal Review approval.');
        } else if (caseRecord.LegalApprovalStatus__c == 'Approved') {
            
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        } else {
            response.put('status', 'error');
            response.put('message', 'Cannot move to next review since the Legal Review approval is Rejected/Pending.');
        }
        
        return response;
    }
    public Map<String, Object> validateBuyerLegalApproval(Case caseRec){
        
        Map<String, Object> response = new Map<String, Object>();
        CaseService caseServiceObj = CaseService.getInstance();
        List<Account> primaryBuyerAcct = new List<Account>();
        AccountService objAccountService = AccountService.getInstance();
        Account newCustomerAccount = new Account();
      
        if(caseRec.NewCustomerAccount__r.IsPersonAccount){
            primaryBuyerAcct = objAccountService.getDuplicatePersonAccounts(caseRec.EmiratesID__c, caseRec.PassportNumber__c, caseRec.Nationality__c);   
        }
        else{
            primaryBuyerAcct = objAccountService.getDuplicateOrganizationAccounts(caseRec.Trade_License_No__c, caseRec.Registration_Authority__c);   
        }
        
        
        if(!primaryBuyerAcct.isEmpty()){
            newCustomerAccount = primaryBuyerAcct[0];
            if(newCustomerAccount.Legal_Status__c == 'With Legal'){
                response = handleBuyerLegalApproval(caseRec);
            }
            else{
                response.put('status', 'success');
                response.put('message', 'Case moved to next review successfully.'); 
            }
            Case caseToUpdate = new Case();
            caseToUpdate.id = caseRec.id;
            caseToUpdate.NewCustomerAccount__c = newCustomerAccount.id;
            caseServiceObj.updateCaseWithoutTrigger(new List<Case> {caseToUpdate});
        } 
        else {
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        }
        
        return response;
        
    }
    public static Map<String, Object> handleBuyerLegalApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>(); 
        
        if (String.isEmpty(caseRecord.BuyerLegalApprovalStatus__c)) { 
            response.put('status', 'error');
            response.put('message', 'Since the new buyer account is with legal, Please submit for Legal Review approval.');
        } else if (caseRecord.BuyerLegalApprovalStatus__c == 'Approved') {
            
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        } else {
            response.put('status', 'error');
            response.put('message', 'Cannot move to next review since the Buyer Legal Review approval is Rejected/Pending.');
        }
        
        return response;
    }
    public Map<String, Object> handlePaymentReviewApproval(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (String.isEmpty(caseRecord.PaymentApprovalStatus__c)) {
            response.put('status', 'error');
            response.put('message', 'Since customer paid percent is lower than the resale eligible amount, Please submit for  Payment Review approval.');
        } else if (caseRecord.PaymentApprovalStatus__c == 'Approved') {
            
            response.put('status', 'success');
            response.put('message', 'Case moved to next review successfully.');
        } else {
            response.put('status', 'error');
            response.put('message', 'Cannot move to next review since the Payment Review approval is Rejected/Pending.');
        }
        
        return response;
    }
    public static List<ContentDocumentLink> validateDocumentByName(Case caseRecord, String docName) {
        Map<String, Object> response = new Map<String, Object>();
        DocumentService docServiceObj = DocumentService.getInstance();
        Document__c doc = docServiceObj.getCaseDocumentByName(caseRecord.Id,docName);
        List<ContentDocumentLink> cdl = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :doc.id];
        return cdl;
    }
    public static List<ContentDocumentLink> validateDocuments(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        DocumentService docServiceObj = DocumentService.getInstance();
        List<String> documentNames = new List<String>{ 'Buyer Emirates ID','Seller Emirates ID', 'MOU', 'Buyer Passport','Seller Passport' };
            
            // Method returns a List<Document__c>
            Map<Id, Document__c> documentMap = new Map<Id, Document__c> (docServiceObj.getCaseDocumentsByNames(caseRecord.Id, documentNames));
        
        // Query ContentDocumentLink for all these document Ids
        List<ContentDocumentLink> cdl = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :documentMap.keySet()
        ];
        
        return cdl;
        
    }
    public  void handleNextSteps(Case caseRec){
        if (Test.isRunningTest()) return;
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    } 
 
    
    public  Map<Id, Decimal> evaluateCustomerPaidAmount(SalesOrder__c order) {
        Map<Id, Decimal> orderWiseCustomerPaidPercentage = new Map<Id, Decimal>();  
        Map<Id, Decimal> orderWiseClearedAmt = new Map<Id, Decimal>();
        
        InstallmentLineService installServiceObj = InstallmentLineService.getInstance();
        List<InstallmentLines__c> installments = installServiceObj.getAllInstallmentLinesBySalesOrder(new Set<Id> {order.id});
        
        if(!installments.isEmpty()){
            for (InstallmentLines__c line : installments) {
                Id orderId = line.SalesOrder__c;
                Decimal clearedAmt = orderWiseClearedAmt.containsKey(orderId) ? orderWiseClearedAmt.get(orderId) : 0;
                orderWiseClearedAmt.put(orderId, clearedAmt + (line.ClearedAmount__c != null ? line.ClearedAmount__c : 0));
            }
        }   
        
        return orderWiseClearedAmt;    
    }
    public void createDocuments(List<Case> listOfCases){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getDocTypes('Case',RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
    } 
        public void createSalesOrderDocument(Id salesOrderId) {
    DocumentService objSalesOrderDocumentService = DocumentService.getInstance();

    List<DocumentType__c> salesOrderDocTypes = objSalesOrderDocumentService.getDocTypesByTypeNames('SalesOrder__c', requiredDocTypes);
    List<Document__c> documentSalesOrderList = new List<Document__c>();
    for (DocumentType__c docType : salesOrderDocTypes) {
        documentSalesOrderList.add(new Document__c(SalesOrder__c = salesOrderId, DocumentType__c = docType.Id, Document_Name__c = docType.Type__c));
    }
    objSalesOrderDocumentService.insertDocuments(documentSalesOrderList);   
}
    public void caseDocumentsToNewSalesOrder(Id caseId, Id salesOrderId) {
    DocumentService docService = DocumentService.getInstance();
    List<Document__c> caseDocuments = docService.getCaseDocumentsWithFiles(caseId);
    List<Document__c> salesOrderDocuments = docService.getSalesOrderDocuments(salesOrderId);
    Map<String, Document__c> soDocsByName = new Map<String, Document__c>();
    for (Document__c soDoc : salesOrderDocuments) {
        if (!String.isBlank(soDoc.Document_Name__c)) {
            soDocsByName.put(soDoc.Document_Name__c.trim().toLowerCase(),soDoc);
        }
    }
    List<Document__c> docsToUpdate = new List<Document__c>();
    for (Document__c caseDoc : caseDocuments) {              
        String docName = caseDoc.Document_Name__c.trim().toLowerCase();
        Document__c targetSoDoc = soDocsByName.get(docName);
        if (targetSoDoc != null && caseDoc.ContentDocumentId__c != null){
        docService.insertContentDocumentLink(caseDoc.ContentDocumentId__c,targetSoDoc.Id);
        targetSoDoc.ContentDocumentId__c = caseDoc.ContentDocumentId__c;
        docsToUpdate.add(targetSoDoc);
        }}
    if (!docsToUpdate.isEmpty()) {
        docService.updateDocuments(docsToUpdate);
    }
}

    public  void createNewCustomerAndSalesOrderRecord(Case caseRec){
        if(caseRec.NewSalesOrder__c != null){
            return;
        }
      
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT); 
        AccountService objAccountService = AccountService.getInstance();
        SalesOrderService orderObj =SalesOrderService.getInstance();
        CaseService caseServiceObj = CaseService.getInstance();
        InstallmentLineService servObj = InstallmentLineService.getInstance();
        ResaleServiceRequestHandler newSalesOrderdocuments = ResaleServiceRequestHandler.getInstance();
        
        List<Account> primaryBuyerAcct = new List<Account>();
        List<Account> jointBuyerAccts = new List<Account>();
        Account newCustomerAccount = new Account();
        Opportunity newOppty = new Opportunity();
       List<SalesOrderOtherCharges__c> otherChargesToInsert = new List<SalesOrderOtherCharges__c>();
        
        if(caseRec.NewCustomerAccount__c ==null){
            
            return;
        }
        else{
            newOppty.name =  caseRec.NewCustomerAccount__r.name;
            newOppty.AccountId = caseRec.NewCustomerAccount__c;
            newOppty.StageName ='New';
            newOppty.Name =   caseRec.NewCustomerAccount__r.name;   
        }
        
             
        newOppty.LeadChannel__c = caseRec.Sales_Order__r.Opportunity__r.LeadChannel__c;
        newOppty.BrokerAgencyAccount__c = caseRec.Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c;
        
        newOppty.CloseDate = System.today();
        newOppty.WinReason__c = caseRec.Sales_Order__r.Opportunity__r.WinReason__c;
        if (!String.isBlank(caseRec.DirectIndirect__c)) {
        newOppty.AgentType__c = caseRec.DirectIndirect__c;
        } else {
            newOppty.AgentType__c = 'Direct';
        }
        newOppty.Sale_Type__c  ='Resale';
        OpportunityService oppServiceObj = OpportunityService.getInstance();  
        
      
        newOppty = oppServiceObj.insertOpportunityWithoutTrigger(newOppty);
        
        
        SalesOrder__c ordr = new SalesOrder__c ();
        
        if(caseRec.NewCustomerAccount__c!=null){
           ordr.Account__c  =   caseRec.NewCustomerAccount__c; 
        }


        Date todayDate = Date.today();
        DateTime dt = DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day());
        String formattedDate = dt.format('ddMMyy');
        ordr.name = caseRec.Unit__r.name + '-' + formattedDate;
        ordr.Status__c = 'Booked';
        ordr.Unit__c = caseRec.Unit__c;
        ordr.IsDraftOrder__c = true;
        ordr.TypeOfResale__c = caseRec.TypeOfResale__c;
    
        //Adding fields for Integration
        // Field mappings
        ordr.SubStatus__c = 'SPA Counter Signed';
       // ordr.ADMFeeAmount__c = caseRec.Sales_Order__r.ADMFeeAmount__c;
        ordr.ADM_Fee_Combined__c = 0;
        //ordr.ADMFeeWaivedAmount__c = caseRec.Sales_Order__r.ADMFeeWaivedAmount__c;
        ordr.ADMFeeAmount__c =
            (caseRec.ADMTotalFees__c != null ? caseRec.ADMTotalFees__c : 0) +
            (caseRec.ADMAdminFees__c != null ? caseRec.ADMAdminFees__c : 0);
        //  ordr.NetAmount__c = caseRec.Sales_Order__r.SellingPrice__c;
        ordr.NetAmount__c = caseRec.Sales_Order__r.NetAmount__c; //Changes done as per business requirement - 24/02/2026

        ordr.SellingPrice__c = caseRec.Sales_Order__r.SellingPrice__c;
        ordr.AmountPayable__c = caseRec.Sales_Order__r.AmountPayable__c;
        ordr.PaymentPlanDiscount__c = caseRec.Sales_Order__r.PaymentPlanDiscount__c;
        ordr.BulkDiscount__c = caseRec.Sales_Order__r.BulkDiscount__c;
        ordr.Management_Discount__c = caseRec.Sales_Order__r.Management_Discount__c;
        ordr.Discount__c = caseRec.Sales_Order__r.Discount__c;
        ordr.CorporateDiscount__c = caseRec.Sales_Order__r.CorporateDiscount__c;
        ordr.BookingDate__c = System.today();
        ordr.OwnerSharePercentage__c = caseRec.Main_Buyer_Share_Percentage__c;
        ordr.CustomerSignedSPADate__c = Date.today();
        ordr.SalesManager__c = caseRec.Sales_Order__r.SalesManager__c;
        ordr.AmountPayable__c = caseRec.Sales_Order__r.AmountPayable__c;
        ordr.Opportunity__c = newOppty.id;
        ordr.Broker_Agencyy__c = caseRec.Sales_Order__r.Broker_Agencyy__c;
        //ordr.SoldDate__c =  System.today();
        ordr.SoldDate__c = caseRec.Sales_Order__r.SoldDate__c;
        ordr.ResoldDate__c = System.today();
        ordr.PreviousCustomer__c = caseRec.Sales_Order__r.Account__c;
        ordr.PreviousSalesOrder__c = caseRec.Sales_Order__c;
        ordr.Resale__c = true;
        if(caseRec.ResalePrice__c!=null){
        ordr.ResalePrice__c =   caseRec.ResalePrice__c;  
        }
        //Added as per SR-8997
        if (caseRec.Sales_Order__r.PaymentPlan__c != null) {
            ordr.PaymentPlan__c = caseRec.Sales_Order__r.PaymentPlan__c;
        }
        
        if (caseRec.TypeOfResale__c == 'Gifting' ||
            caseRec.TypeOfResale__c == 'Addition of Kin' ||
            caseRec.TypeOfResale__c == 'Deletion of Kin') {
                
                if (caseRec.Sales_Order__r.Offer__c != null) {
                    ordr.Offer__c = caseRec.Sales_Order__r.Offer__c;
                }
                if (caseRec.Sales_Order__r.ServiceChargesWaiverEndDate__c != null) {
                    ordr.ServiceChargesWaiverEndDate__c = caseRec.Sales_Order__r.ServiceChargesWaiverEndDate__c;
                }
                if (caseRec.Sales_Order__r.ServiceChargesWaiverStartDate__c != null) {
                    ordr.ServiceChargesWaiverStartDate__c = caseRec.Sales_Order__r.ServiceChargesWaiverStartDate__c;
                }
                if (caseRec.Sales_Order__r.ServiceChargeWaivedYears__c != null) {
                    ordr.ServiceChargeWaivedYears__c = caseRec.Sales_Order__r.ServiceChargeWaivedYears__c;
                }
                if (caseRec.Sales_Order__r.ServiceChargeStartDate__c != null) {
                    ordr.ServiceChargeStartDate__c = caseRec.Sales_Order__r.ServiceChargeStartDate__c;
                }
            }
        else if(caseRec.TypeOfResale__c == 'Resale'
                ||caseRec.TypeOfResale__c == 'Swap'){
                     ordr.ServiceChargeStartDate__c =  System.today().addDays(1);
                    
                    
                }
        
        
        //ordr.ADM_DLD_Pre_Registered__c = caseRec.Sales_Order__r.ADM_DLD_Pre_Registered__c;
        ordr.Pre_Title_Deed_Status__c = caseRec.Sales_Order__r.Pre_Title_Deed_Status__c;
        ordr.Title_Deed_Status__c = caseRec.Sales_Order__r.Title_Deed_Status__c;
        ordr.Handover_Status__c = caseRec.Sales_Order__r.Handover_Status__c;
        ordr.ADDC__c = caseRec.Sales_Order__r.ADDC__c;
        
        if(caseRec.Broker_Commission__c!=null)
        ordr.BrokerCommission__c = caseRec.Broker_Commission__c;
        if(caseRec.Broker_Agent__c!=null)
        ordr.ResaleBrokerAgent__c = caseRec.Broker_Agent__c;
        if(caseRec.BrokerAgency__c!=null)
        ordr.ResaleBrokerAgency__c = caseRec.BrokerAgency__c;
        orderObj.createSalesOrder(ordr); 
        
        newSalesOrderdocuments.createSalesOrderDocument(ordr.Id); // creating placeholders in the resales sales orders
        newSalesOrderdocuments.caseDocumentsToNewSalesOrder(caseRec.Id, ordr.Id); //inserting the case documents in resale-salesorder document
        
        Case caseToUpdate = new Case();
        caseToUpdate.id = caseRec.id;
        caseToUpdate.NewSalesOrder__c = ordr.id;
       
        caseServiceObj.updateCase(caseToUpdate);
        
        
        JointOwnerService jointOwnerServiceObj = JointOwnerService.getInstance(); 
        List<JointOwner__c> jointOwnerList = jointOwnerServiceObj.fetchJointOwners(caseRec.id);
        List<JointOwner__c> jointOwnerListToUpdate = new List<JointOwner__c>();
        
        if(!jointOwnerList.isEmpty()){
            for(JointOwner__c jointOwner : jointOwnerList){
                List<Account> existingAccountList = new List<Account>();
                existingAccountList = objAccountService.getDuplicatePersonAccounts(jointOwner.Emirates_ID__c, jointOwner.Passport_Number__c, jointOwner.Nationality__c);
                Account jointBuyerAccount = new Account();
                JointOwner__c ownerToUpdate = new JointOwner__c();
                ownerToUpdate.id = jointOwner.id;
                ownerToUpdate.SalesOrder__c = ordr.id;
                
                if(existingAccountList.isEmpty()){
                    jointBuyerAccount.RecordTypeId = personAccountRecordTypeId;
                    jointBuyerAccount.LastName = jointOwner.Last_Name__c;
                    jointBuyerAccount.FirstName = jointOwner.First_Name__c;
                    jointBuyerAccount.Emirates_Id__pc = jointOwner.Emirates_ID__c; 
                    jointBuyerAccount.MobileNumber__c = jointOwner.Phone_Number__c;
                    jointBuyerAccount.PersonEmail = jointOwner.Email__c;
                    jointBuyerAccount.Joint_Buyer__c = true;
                    jointBuyerAccount.MobileCountryCode__c = jointOwner.Mobile_Country_Code__c;
                    jointBuyerAccount.Emirates_ID_expiry_date__c = jointOwner.Emirates_ID_expiry_date__c;
                    jointBuyerAccount.EID_Issue_Date__pc = jointOwner.EIDIssueDate__c;
                    jointBuyerAccount.Gender__pc = jointOwner.Gender__c;
                    jointBuyerAccount.PassportIssueDate__pc = jointOwner.PassportIssueDate__c;
                    jointBuyerAccount.CustomerType__c = jointOwner.Customer_Type__c;
                    jointBuyerAccount.NameInArabic__c = jointOwner.NameInArabic__c;
                    
                    
                    //newCustomerAccount.Email__pc = caseRec.Email__c;
                    jointBuyerAccount.PassportNumber__pc = jointOwner.Passport_Number__c;
                    jointBuyerAccount.PassportExpiryDate__pc = jointOwner.Passport_Expiry_Date__c;
                    jointBuyerAccount.Nationality__c =  jointOwner.Nationality__c;  
                    jointBuyerAccount.BillingCity = jointOwner.Address__City__s;
                    jointBuyerAccount.BillingCountryCode = jointOwner.Address__CountryCode__s;  
                    jointBuyerAccount.BillingStateCode = jointOwner.Address__StateCode__s;
                    jointBuyerAccount.BillingStreet = jointOwner.Address__Street__s;
                    jointBuyerAccount.ExternalId__c = jointOwner.Id;
                    jointBuyerAccount.BillingPostalCode = jointOwner.Address__PostalCode__s;
                    jointBuyerAccts.add(jointBuyerAccount);    
                    
                    jointBuyerAccount.PersonMailingStateCode = jointOwner.Address__StateCode__s;
                    jointBuyerAccount.PersonMailingCity = jointOwner.Address__City__s;
                    jointBuyerAccount.PersonMailingPostalCode = jointOwner.Address__PostalCode__s;
                    jointBuyerAccount.PersonMailingCountryCode = jointOwner.Address__CountryCode__s;
                    jointBuyerAccount.PersonMailingStreet = jointOwner.Address__Street__s;
                    
                    jointBuyerAccount.Salutation__pc = jointOwner.Salutation__c;
                    jointBuyerAccount.PlaceofIssue__pc = jointOwner.PlaceofIssue__c;
                    jointBuyerAccount.LanguagePreference__pc = jointOwner.Language_Preference__c;
                    jointBuyerAccount.ResidentStatus__pc = jointOwner.UAEResident__c;
                    jointBuyerAccount.PersonBirthdate = jointOwner.Birthdate__c;
                        
                
                    //ownerToUpdate.Account__c = jointBuyerAccount.ExternalId__c;
                    //jointOwnerListToUpdate.add(ownerToUpdate);
                }
                else{
                    ownerToUpdate.Account__c = existingAccountList[0].id;
                    jointOwnerListToUpdate.add(ownerToUpdate);
                }
            }
        }
        Map<Id, Id> jointOwnerIdToAccountId = new Map<Id, Id>();
        if(!jointBuyerAccts.isEmpty()){
            objAccountService.insertAccounts(jointBuyerAccts);
            for (Account acc : jointBuyerAccts) {
                if (acc.ExternalId__c != null) {
                    jointOwnerIdToAccountId.put((Id)acc.ExternalId__c, acc.Id);
                }
            }
            
            for (Id jointOwnerId : jointOwnerIdToAccountId.keySet()) {
                jointOwnerListToUpdate.add(new JointOwner__c(
                    Id = jointOwnerId,
                    Account__c = jointOwnerIdToAccountId.get(jointOwnerId),
                    SalesOrder__c = ordr.Id
                ));
            }
            
        }
        Set<Id> salesOrderIdSet = new Set<Id>{ caseRec.Sales_Order__c };
        InstallmentLineService lineServiceObj = InstallmentLineService.getInstance();
        List<InstallmentLines__c> actualInstallments = lineServiceObj.getAllInstallmentLinesBySalesOrder(salesOrderIdSet);
        List<InstallmentLines__c> handoverInstallments = new List<InstallmentLines__c>();
        List<InstallmentLines__c> posthandoverInstallments = new List<InstallmentLines__c>();
        
        if(!actualInstallments.isEmpty()){
            for(InstallmentLines__c line : actualInstallments){
                if(line.Type__c =='Handover'){
                    handoverInstallments.add(line);
                }
                if(line.Type__c =='Post Handover Installment'){
                    posthandoverInstallments.add(line); 
                }
                
            }   
        }
        Boolean hasBothInstallments = !handoverInstallments.isEmpty() && !posthandoverInstallments.isEmpty();
        Boolean isUnderConstruction = caseRec.ProjectStatus__c == 'Under Construction';
        Boolean giftingResale = caseRec.TypeOfResale__c == 'Gifting';
        
        Boolean isValidResaleType =
            caseRec.TypeOfResale__c == 'Resale' ||
            caseRec.TypeOfResale__c == 'Swap' ||
            caseRec.TypeOfResale__c == 'Gifting' ||
            (
                (
                    caseRec.TypeOfResale__c =='Addition of Kin'
                    || caseRec.TypeOfResale__c =='Deletion of Kin'
                    ||caseRec.TypeOfResale__c == 'Addition of Name' ||
                    caseRec.TypeOfResale__c == 'Deletion of Name'               
                ) &&
                caseRec.InitialOwnerRemoved__c == 'Yes'
            );
        
        Boolean isDataMigration =
            caseRec.Sales_Order__r.PaymentPlan__c != null &&
            caseRec.Sales_Order__r.PaymentPlan__r.Name == 'Data Migration';
        
        if (hasBothInstallments) {
            
            Boolean shouldProcessPHPP =
                !isUnderConstruction && !giftingResale|| (isUnderConstruction && isValidResaleType);
            
            if (shouldProcessPHPP) {
                if (isDataMigration) {
                    calculateInstallmentsForPHPPMigratedProjects(caseRec.Sales_Order__c, ordr, caseRec);
                } else {
                    calculateInstallmentsAndReceiptsForPHPP(caseRec.Sales_Order__c, ordr, caseRec);
                }
            }
            
        } else {
            calculateInstallmentsAndReceipts(caseRec.Sales_Order__c, ordr, caseRec);
        }
       
        otherChargesToInsert = calculateOtherCharges(caseRec, ordr, caseRec.Sales_Order__c);
        if (!otherChargesToInsert.isEmpty()) SalesOrderOtherChargesService.getInstance().insertSalesOrderOtherCharges(otherChargesToInsert);
        if(!jointOwnerListToUpdate.isEmpty()){
            jointOwnerServiceObj.updateJointOwnersWithoutTrigger(jointOwnerListToUpdate);
        }
    }
    public Boolean validateSPASignedDate(Case caseObj) {
        if(caseObj.NewSalesOrder__r.Bloom_Signed_SPA_Date__c == null){
            return false;   
        }     
        else{
            return true;
        }      
    }
    /*public static Account createPrimaryBuyerAccount(Case caseRec) {
        Id personRtId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id orgRtId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        
        Account acc = new Account();
        acc.Send_To_SAP__c = false;
        acc.CustomerType__c  = caseRec.Customer_Type__c;
        
        if (caseRec.CustomerType__c == 'Person') {
            acc.RecordTypeId = personRtId;
            acc.LastName = caseRec.Last_Name__c;
            acc.FirstName = caseRec.First_Name__c;
            
            acc.PersonMailingStateCode = caseRec.Address__StateCode__s;
            acc.PersonMailingCity = caseRec.Address__City__s;
            acc.PersonMailingPostalCode = caseRec.Address__PostalCode__s;
            acc.PersonMailingCountryCode = caseRec.Address__CountryCode__s;
            acc.PersonMailingStreet = caseRec.Address__Street__s;
            acc.NameinArabic__c = caseRec.BuyerNameInArabic__c;
            acc.Emirates_Id__pc = caseRec.EmiratesID__c;
            acc.EID_Issue_Date__pc = caseRec.EIDIssueDate__c;
            acc.EID_Expiry_Date__pc = caseRec.Emirates_ID_expiry_date__c;
            acc.PassportExpiryDate__pc = caseRec.PassportExpiryDate__c;
            acc.PassportNumber__pc = caseRec.PassportNumber__c;
            acc.PassportIssueDate__pc = caseRec.PassportIssueDate__c;
            acc.Gender__pc = caseRec.Gender__c;
            acc.PrimaryMobileCountryCode__pc = caseRec.Mobile_Country_Code__c;
            
            acc.Nationality__c = caseRec.Nationality__c;
            
            acc.PrimaryMobilePhone__pc = caseRec.Mobile_Number__c;
            acc.PersonEmail = caseRec.Email_Address__c;
            acc.Salutation__pc = caseRec.Salutation__c;
            acc.PlaceofIssue__pc = caseRec.PlaceofIssue__c;
            acc.LanguagePreference__pc = caseRec.LanguagePreference__c;
            acc.ResidentStatus__pc = caseRec.UAEResident__c;
            acc.PersonBirthdate = caseRec.Birthdate__c;
        } else if (caseRec.CustomerType__c == 'Organization') {
            acc.RecordTypeId = orgRtId;
            acc.Name = caseRec.Name__c;
            acc.Trade_License_No__c = caseRec.Trade_License_No__c;
            acc.Trade_License_Expiry_Date__c = caseRec.Trade_License_Expiry_Date__c;
            acc.Trade_License_Issue_Date__c = caseRec.Trade_License_Issue_Date__c;
            acc.Registration_Authority__c = caseRec.Registration_Authority__c;
            acc.tdc_tvte__EmailAccount__c = caseRec.Email_Address__c;
            //New fields requested by operations
            
            if (String.isNotBlank(caseRec.NameOfPOA__c)) {
                acc.NameofPOA__c = caseRec.NameOfPOA__c;
            }
            if (String.isNotBlank(caseRec.PlaceOfIssuance__c)) {
                acc.Place_of_Issuance__c = caseRec.PlaceOfIssuance__c;
            }
            if (String.isNotBlank(caseRec.PlaceOfRegistration__c)) {
                acc.PlaceofRegistration__c = caseRec.PlaceOfRegistration__c;
            }
            if (String.isNotBlank(caseRec.RepresentationType__c)) {
                acc.Representation_Type__c = caseRec.RepresentationType__c;
            }
            if (String.isNotBlank(caseRec.TypeOfCompany__c)) {
                acc.TypeOfCompany__c = caseRec.TypeOfCompany__c;
            }
            if (String.isNotBlank(caseRec.RepresentativeArabicName__c)) {
                acc.Representative_Position__c = caseRec.RepresentativeArabicName__c;
            }
            if(caseRec.PercentageOfSharePurchased__c !=null){
                acc.Percentage_Of_Share_Purchased__c = caseRec.PercentageOfSharePurchased__c;
            }
 
            
        }
        
        acc.BillingCity = caseRec.Address__City__s;
        acc.BillingCountryCode = caseRec.Address__CountryCode__s;
        acc.BillingStateCode = caseRec.Address__StateCode__s;
        acc.BillingStreet = caseRec.Address__Street__s;
        acc.BillingPostalCode = caseRec.Address__PostalCode__s;
        acc.MobileNumber__c = caseRec.Mobile_Number__c;
        acc.MobileCountryCode__c = caseRec.Mobile_Country_Code__c;
        
        
        return acc;
    }*/
    
    public void calculateInstallmentsAndReceipts(Id existingSalesOrderId, SalesOrder__c newOrder, Case caseRec) {
        
        InstallmentLineService lineServiceObj = InstallmentLineService.getInstance();
        ReceiptAcknowledgementService receiptServiceObj = ReceiptAcknowledgementService.getInstance();
        SalesOrderService serviceObj = SalesOrderService.getInstance();
        SalesOrder__c actualSalesOrder = serviceObj.getSalesOrdersById(existingSalesOrderId);
        
        
        Boolean hasMergedAck = false;
        Set<Id> salesOrderIdSet = new Set<Id>{ existingSalesOrderId };
        Set<Id> ackIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();
        
        Boolean hasMergedLine = false;
        
        List<InstallmentLines__c> installmentsToInsert = new List<InstallmentLines__c>();
        List<ReceiptAcknowledgement__c> acknowledgementsToInsert = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAllocation__c> allocationsToInsert = new List<ReceiptAllocation__c>();
     
        
        List<InstallmentLines__c> actualInstallments = lineServiceObj.getAllInstallmentLinesBySalesOrder(salesOrderIdSet);
    
        
              // Merged Installment
        InstallmentLines__c mergedLine = new InstallmentLines__c(
            External_Id__c = caseRec.Sales_Order__c,
            SalesOrder__c = newOrder.Id,
            Description__c = 'Resale',
            SAP_Condition_Type__c = MERGED_INSTALLMENT_CONDITION_TYPE,
            InstallmentDate__c = System.today(),
            InstallmentNumber__c = 1
            
        );
        lineIds.add(mergedLine.External_Id__c);
        
        // Merged Acknowledgement
        ReceiptAcknowledgement__c mergedAcknowledgement = new ReceiptAcknowledgement__c(
            External_Id__c = newOrder.Id,
            SalesOrder__c = newOrder.Id,
            Account__c = newOrder.Account__c,
            Status__c = 'Cleared',
            MaturityDate__c = System.today(),
            Opportunity__c = newOrder.Opportunity__c,
            PaymentType__c = 'Transfer of rights - Resale',
            ReferenceNumber__c = 'Transfer of rights - Resale'
        );
        ackIds.add(mergedAcknowledgement.External_Id__c);
        
        // Merged Allocation
        ReceiptAllocation__c mergedAlloc = new ReceiptAllocation__c(
            SalesOrder__c = newOrder.Id,
            Account__c = newOrder.Account__c,
            DateOfApplication__c = System.today(),
            TypeOfInvoice__c = 'Installment',
            ReceiptAcknowledgement__c = mergedAcknowledgement.External_Id__c,
            
            InstallmentLine__c = mergedLine.External_Id__c
        );
       
        Integer count = 2;    
            
        if(actualSalesOrder.PaymentPlan__c!=null && actualSalesOrder.PaymentPlan__r.Name == 'Data Migration'){
            
            if(!actualInstallments.isEmpty()){
          
           for (InstallmentLines__c actualIns : actualInstallments) {
           Decimal insAmount = actualIns.InstallmentAmount__c !=null ? actualIns.InstallmentAmount__c : 0;
           Decimal clearedAmt = actualIns.ClearedAmount__c !=null ? actualIns.ClearedAmount__c : 0;
           Decimal pendingAmt = insAmount- clearedAmt;
           Boolean hasPending = pendingAmt > 1;
              
            //if (hasPending && actualIns.InstallmentDate__c > System.today()) {
            if (hasPending && actualIns.Due_Date__c > System.today()) {
               InstallmentLines__c inst = new InstallmentLines__c();
                inst.Description__c = actualIns.Description__c;
                inst.SalesOrder__c = newOrder.Id;
                inst.External_Id__c = actualIns.Id;
                inst.AmountReceived__c = 0;
                inst.Type__c = actualIns.Type__c;
                inst.ClearedAmount__c = 0;
                inst.InstallmentAmount__c = actualIns.InstallmentAmount__c;
                inst.InstallmentPercentage__c = actualIns.InstallmentPercentage__c;
                inst.BrokerPayoutPercentage__c = actualIns.BrokerPayoutPercentage__c;
                inst.Installment_Amount_Excluding_ADM__c = actualIns.Installment_Amount_Excluding_ADM__c;
                inst.InstallmentDate__c = actualIns.Due_Date__c; //InstallmentDate__c;
                if(actualIns.PaymentInstallments__c!=null){
                inst.PaymentInstallments__c = actualIns.PaymentInstallments__c;    
                }
                
                inst.InstallmentNumber__c = count;
                
                installmentsToInsert.add(inst);
                lineIds.add(inst.External_Id__c);  
                count++;
            }
            else{
                 hasMergedLine = true; 
                 mergedLine.InstallmentAmount__c = caseRec.BillingToCompleteAmount__c;
                 mergedLine.InstallmentPercentage__c = sum(mergedLine.InstallmentPercentage__c, actualIns.InstallmentPercentage__c);
                 mergedLine.BrokerPayoutPercentage__c = sum(mergedLine.BrokerPayoutPercentage__c, actualIns.BrokerPayoutPercentage__c);
                 mergedLine.Type__c = 'Down Payment';
                mergedLine.Installment_Amount_Excluding_ADM__c = sum(mergedLine.Installment_Amount_Excluding_ADM__c, actualIns.Installment_Amount_Excluding_ADM__c);
                Decimal totalCollection = caseRec.TotalCollection__c != null ? caseRec.TotalCollection__c : 0;
                
                mergedLine.AmountReceived__c      = totalCollection;
                mergedLine.ClearedAmount__c       = totalCollection;
                
                hasMergedAck                      = true;
                mergedAcknowledgement.Amount__c   = totalCollection;
                mergedAlloc.AmountApplied__c      = totalCollection;

               
                
            }
           }  
            }
            else{
                hasMergedLine = true; 
                
                Decimal totalCollection = caseRec.TotalCollection__c != null ? caseRec.TotalCollection__c : 0;
                Decimal mergedPercent = 0;
                mergedLine.InstallmentAmount__c = totalCollection ;
                mergedLine.Type__c = 'Down Payment';
                mergedPercent = ((totalCollection / actualSalesOrder.NetAmount__c) * 100).setScale(2);
                mergedLine.InstallmentPercentage__c = mergedPercent;
                
                mergedLine.AmountReceived__c      = totalCollection;
                mergedLine.ClearedAmount__c       = totalCollection;
                
                hasMergedAck                      = true;
                mergedAcknowledgement.Amount__c   = totalCollection;
                mergedAlloc.AmountApplied__c      = totalCollection;
                
                if(totalCollection<actualSalesOrder.NetAmount__c){
                InstallmentLines__c inst = new InstallmentLines__c();
                inst.Description__c = 'Upon Handover';
                inst.InstallmentNumber__c = 2;
                inst.SalesOrder__c = newOrder.Id;
                //inst.External_Id__c = actualIns.Id;
                inst.AmountReceived__c = 0;
                inst.Type__c = 'Installment';
                inst.ClearedAmount__c = 0;
                inst.InstallmentAmount__c =  actualSalesOrder.NetAmount__c - totalCollection;
                inst.InstallmentPercentage__c = 100 - mergedPercent;
                inst.SAP_Condition_Type__c ='P021';
                inst.InstallmentDate__c =System.today();
                inst.InstallmentNumber__c = 2;
                installmentsToInsert.add(inst);           
            }
            }}
        else if(actualSalesOrder.ADM_Fee_Included__c){
             for(InstallmentLines__c actualLine : actualInstallments){
                
                Decimal insAmount = actualLine.Installment_Amount_Excluding_ADM__c !=null ? actualLine.Installment_Amount_Excluding_ADM__c : 0;
                Decimal clearedAmt = actualLine.ClearedAmount__c !=null ? actualLine.ClearedAmount__c : 0;
                Decimal pendingAmt = insAmount- clearedAmt;
                Boolean hasPending = pendingAmt > 1;

                //Boolean hasPending = actualLine.PendingAmount__c>1;
                
                if (hasPending) {
                    
                    InstallmentLines__c inst = new InstallmentLines__c();
                    inst.Description__c = actualLine.Description__c;
                    inst.SalesOrder__c = newOrder.Id;
                    inst.External_Id__c = actualLine.Id;
                    inst.Type__c = actualLine.Type__c;
                    inst.InstallmentAmount__c = actualLine.InstallmentAmount__c;
                    inst.InstallmentPercentage__c = actualLine.InstallmentPercentage__c;
                    inst.BrokerPayoutPercentage__c = actualLine.BrokerPayoutPercentage__c;
                    inst.InstallmentDate__c = actualLine.Due_Date__c;
                     if(actualLine.PaymentInstallments__c!=null){
                     inst.PaymentInstallments__c = actualLine.PaymentInstallments__c;    
                }
                    inst.InstallmentNumber__c = count;
                    //inst.ADM_Fee_Included__c = true;
                    //inst.Installment_Amount_Excluding_ADM__c = actualLine.Installment_Amount_Excluding_ADM__c;
                    installmentsToInsert.add(inst);
                    lineIds.add(inst.External_Id__c);
                    count++;
                } else {
                    
                    hasMergedLine = true;
                    mergedLine.AmountReceived__c =  sum(mergedLine.AmountReceived__c, actualLine.InstallmentAmount__c);
                    mergedLine.ClearedAmount__c = sum(mergedLine.ClearedAmount__c, actualLine.InstallmentAmount__c);
                    mergedLine.InstallmentAmount__c = sum(mergedLine.InstallmentAmount__c, actualLine.InstallmentAmount__c);  
                    mergedLine.InstallmentPercentage__c = sum(mergedLine.InstallmentPercentage__c, actualLine.InstallmentPercentage__c);
                    mergedLine.BrokerPayoutPercentage__c = sum(mergedLine.BrokerPayoutPercentage__c, actualLine.BrokerPayoutPercentage__c);
                    mergedLine.Type__c = 'Down Payment';
                
                    
                }

          
                if (hasMergedLine) {
                        hasMergedAck = true;
                        mergedAcknowledgement.Amount__c = mergedLine.InstallmentAmount__c;
                        mergedAcknowledgement.PaymentType__c = 'Transfer of rights - Resale';
                        mergedAlloc.AmountApplied__c =mergedLine.InstallmentAmount__c;
                    } 

           }  
        }
        else{
          
            for (InstallmentLines__c actualLine : actualInstallments) {
           Decimal insAmount = actualLine.InstallmentAmount__c !=null ? actualLine.InstallmentAmount__c : 0;
           Decimal clearedAmt = actualLine.ClearedAmount__c !=null ? actualLine.ClearedAmount__c : 0;
           Decimal pendingAmt = insAmount- clearedAmt;
           Boolean hasPending = pendingAmt > 1;
            
            if (hasPending) {
              
                InstallmentLines__c inst = new InstallmentLines__c();
                inst.Description__c = actualLine.Description__c;
                inst.SalesOrder__c = newOrder.Id;
                inst.External_Id__c = actualLine.Id;
                
                if(actualLine.PaymentInstallments__c!=null){
                    inst.PaymentInstallments__c = actualLine.PaymentInstallments__c;    
                }
                inst.ClearedAmount__c = actualLine.ClearedAmount__c;
                inst.Type__c = actualLine.Type__c;
                inst.InstallmentAmount__c = actualLine.InstallmentAmount__c;
                inst.InstallmentPercentage__c = actualLine.InstallmentPercentage__c;
                inst.BrokerPayoutPercentage__c = actualLine.BrokerPayoutPercentage__c;
                inst.Installment_Amount_Excluding_ADM__c = actualLine.Installment_Amount_Excluding_ADM__c;
               
                    inst.InstallmentDate__c = actualLine.Due_Date__c;
                inst.InstallmentNumber__c = count;
                installmentsToInsert.add(inst);
                lineIds.add(inst.External_Id__c);
                count++;
            } else {
             
                hasMergedLine = true;
                mergedLine.AmountReceived__c = sum(mergedLine.AmountReceived__c, actualLine.AmountReceived__c);
                //mergedLine.ClearedAmount__c = sum(mergedLine.ClearedAmount__c, actualLine.ClearedAmount__c);
                mergedLine.ClearedAmount__c = sum(mergedLine.ClearedAmount__c, actualLine.InstallmentAmount__c);
                mergedLine.InstallmentAmount__c = sum(mergedLine.InstallmentAmount__c, actualLine.InstallmentAmount__c);
                mergedLine.InstallmentPercentage__c = sum(mergedLine.InstallmentPercentage__c, actualLine.InstallmentPercentage__c);
                mergedLine.BrokerPayoutPercentage__c = sum(mergedLine.BrokerPayoutPercentage__c, actualLine.BrokerPayoutPercentage__c);
                mergedLine.Type__c = 'Down Payment';
                mergedLine.Installment_Amount_Excluding_ADM__c = sum(mergedLine.Installment_Amount_Excluding_ADM__c, actualLine.Installment_Amount_Excluding_ADM__c);                
            }
            
            if (hasMergedLine) {
                    hasMergedAck = true;
                    mergedAcknowledgement.PaymentType__c = 'Transfer of rights - Resale';
                    mergedAlloc.AmountApplied__c =   mergedLine.InstallmentAmount__c ;
                    mergedAcknowledgement.Amount__c = mergedLine.InstallmentAmount__c;
                    
                }

        }     
         }
     system.debug('hasMergedAck'+  hasMergedAck +'hasMergedLine'+hasMergedLine);
      
        if(hasMergedAck || hasMergedLine){
            if(hasMergedLine)installmentsToInsert.add(mergedLine);
         
            if(hasMergedAck){
                acknowledgementsToInsert.add(mergedAcknowledgement);
                allocationsToInsert.add(mergedAlloc);  
            }
        }
        
      
        
        
       
   system.debug('installmentsToInsert'+  installmentsToInsert +'acknowledgementsToInsert'+acknowledgementsToInsert+'allocationsToInsert'+allocationsToInsert);        
        if (!installmentsToInsert.isEmpty()) lineServiceObj.insertInstallmentWithoutTrigger(installmentsToInsert);
       
        if (!acknowledgementsToInsert.isEmpty()) receiptServiceObj.insertReceiptAcknowledgementWithoutTrigger(acknowledgementsToInsert);
        if (!allocationsToInsert.isEmpty()) insertAllocations(allocationsToInsert, lineIds, ackIds);
      
    }
      public void calculateInstallmentsAndReceiptsForPHPP(Id existingSalesOrderId, SalesOrder__c newOrder, Case caseRec) {
        
        InstallmentLineService lineServiceObj = InstallmentLineService.getInstance();
        ReceiptAcknowledgementService receiptServiceObj = ReceiptAcknowledgementService.getInstance();
        SalesOrderService serviceObj = SalesOrderService.getInstance();
        SalesOrder__c actualSalesOrder = serviceObj.getSalesOrdersById(existingSalesOrderId);
        Double mergedAmt =0;
        Decimal mergedPercent = 0;
        
        
        Boolean hasMergedAck = false;
        Set<Id> salesOrderIdSet = new Set<Id>{ existingSalesOrderId };
        Set<Id> ackIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();
        
        Boolean hasMergedLine = false;
        Boolean hasSecondLine = true;
        
        List<InstallmentLines__c> installmentsToInsert = new List<InstallmentLines__c>();
        List<ReceiptAcknowledgement__c> acknowledgementsToInsert = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAllocation__c> allocationsToInsert = new List<ReceiptAllocation__c>();
     
        
        List<InstallmentLines__c> actualInstallments = lineServiceObj.getAllInstallmentLinesBySalesOrder(salesOrderIdSet);
        
        
      
              // Merged Installment
        InstallmentLines__c mergedLine = new InstallmentLines__c(
            External_Id__c = caseRec.Sales_Order__c,
            SalesOrder__c = newOrder.Id,
            Description__c = 'Resale',
            SAP_Condition_Type__c = MERGED_INSTALLMENT_CONDITION_TYPE,
            InstallmentDate__c = System.today(),
            InstallmentNumber__c = 1
            
        );
        lineIds.add(mergedLine.External_Id__c);
        
        InstallmentLines__c secondLine = new InstallmentLines__c(
            SalesOrder__c = newOrder.Id,
            InstallmentDate__c = System.today(),
            InstallmentNumber__c = 2
            
        );
       
        
        // Merged Acknowledgement
        ReceiptAcknowledgement__c mergedAcknowledgement = new ReceiptAcknowledgement__c(
            External_Id__c = newOrder.Id,
            SalesOrder__c = newOrder.Id,
            Account__c = newOrder.Account__c,
            Status__c = 'Cleared',
            MaturityDate__c = System.today(),
            Opportunity__c = newOrder.Opportunity__c,
            PaymentType__c = 'Transfer of rights - Resale',
            ReferenceNumber__c = 'Transfer of rights - Resale'
        );
        ackIds.add(mergedAcknowledgement.External_Id__c);
        
        // Merged Allocation
        ReceiptAllocation__c mergedAlloc = new ReceiptAllocation__c(
            SalesOrder__c = newOrder.Id,
            Account__c = newOrder.Account__c,
            DateOfApplication__c = System.today(),
            ReceiptAcknowledgement__c = mergedAcknowledgement.External_Id__c,
            TypeOfInvoice__c = 'Installment',
            InstallmentLine__c = mergedLine.External_Id__c
        );
       
        Integer count = 2;    
    for (InstallmentLines__c actualLine : actualInstallments) {
            if (actualLine.Type__c =='Installment' ||actualLine.Type__c =='Down Payment' ) {
             hasMergedLine = true;
                mergedLine.AmountReceived__c = sum(mergedLine.AmountReceived__c, actualLine.AmountReceived__c);
                //mergedLine.ClearedAmount__c = sum(mergedLine.ClearedAmount__c, actualLine.ClearedAmount__c);
                mergedLine.ClearedAmount__c = sum(mergedLine.ClearedAmount__c, actualLine.InstallmentAmount__c);
                mergedLine.InstallmentAmount__c = sum(mergedLine.InstallmentAmount__c, actualLine.InstallmentAmount__c);
                mergedAmt = mergedAmt+ actualLine.InstallmentAmount__c;
                mergedLine.InstallmentPercentage__c = sum(mergedLine.InstallmentPercentage__c, actualLine.InstallmentPercentage__c);
                mergedPercent = sum(mergedPercent, actualLine.InstallmentPercentage__c);
                mergedLine.BrokerPayoutPercentage__c = sum(mergedLine.BrokerPayoutPercentage__c, actualLine.BrokerPayoutPercentage__c);
                mergedLine.Type__c = actualLine.Type__c;
                mergedLine.Installment_Amount_Excluding_ADM__c = sum(mergedLine.Installment_Amount_Excluding_ADM__c, actualLine.Installment_Amount_Excluding_ADM__c);  
                        
            } else {
                hasSecondLine = true;
                secondLine.AmountReceived__c = sum(secondLine.AmountReceived__c, actualLine.AmountReceived__c);
                secondLine.ClearedAmount__c = sum(secondLine.ClearedAmount__c, actualLine.ClearedAmount__c);
                if(actualLine.Type__c == 'Handover'){
                 secondLine.Description__c =  actualLine.Description__c;  
                    if(actualLine.Due_Date__c >=System.today()){
                       secondLine.InstallmentDate__c = actualLine.Due_Date__c;
                    }
                    if(actualLine.PaymentInstallments__c!=null){
                      secondLine.PaymentInstallments__c = actualLine.PaymentInstallments__c;   
                    }
               }
                secondLine.BrokerPayoutPercentage__c = sum(secondLine.BrokerPayoutPercentage__c, actualLine.BrokerPayoutPercentage__c);
                secondLine.Installment_Amount_Excluding_ADM__c = sum(secondLine.Installment_Amount_Excluding_ADM__c, actualLine.Installment_Amount_Excluding_ADM__c);
                
            } 
        
        }     
         
            if(hasSecondLine){
                 if(actualSalesOrder.Sales_Price_Excluding_ADM__c!=null & mergedAmt!=null){
                  secondLine.InstallmentAmount__c = actualSalesOrder.Sales_Price_Excluding_ADM__c -  mergedAmt;   
                  secondLine.InstallmentPercentage__c = 100 - mergedPercent;
                  secondLine.Type__c = 'Handover';
                  hasMergedAck = true;
                  mergedAcknowledgement.Amount__c =mergedAmt;
                  mergedAlloc.AmountApplied__c = mergedAmt;
                  mergedAcknowledgement.PaymentType__c = 'Transfer of rights - Resale'; 
                   
                     
                }
               
            }
      
        if(hasMergedAck || hasMergedLine){
            if(hasMergedLine)installmentsToInsert.add(mergedLine);
            if(hasSecondLine)installmentsToInsert.add(secondLine);
            if(hasMergedAck){
                acknowledgementsToInsert.add(mergedAcknowledgement);
                allocationsToInsert.add(mergedAlloc);  
            }
        }
        
      
        
        
       
        
        if (!installmentsToInsert.isEmpty()) lineServiceObj.insertInstallmentWithoutTrigger(installmentsToInsert);
       
        if (!acknowledgementsToInsert.isEmpty() && !Test.isRunningTest()) receiptServiceObj.insertReceiptAcknowledgementWithoutTrigger(acknowledgementsToInsert);
        if (!allocationsToInsert.isEmpty() && !Test.isRunningTest()) insertAllocations(allocationsToInsert, lineIds, ackIds);
      
    }

        public void calculateInstallmentsForPHPPMigratedProjects(Id existingSalesOrderId, SalesOrder__c newOrder, Case caseRec) {
        
        InstallmentLineService lineServiceObj = InstallmentLineService.getInstance();
        ReceiptAcknowledgementService receiptServiceObj = ReceiptAcknowledgementService.getInstance();
        SalesOrderService serviceObj = SalesOrderService.getInstance();
        SalesOrder__c actualSalesOrder = serviceObj.getSalesOrdersById(existingSalesOrderId);
        Double mergedAmt =0;
        Decimal mergedPercent = 0;
        
        Decimal totalCollection = caseRec.TotalCollection__c != null ? caseRec.TotalCollection__c : 0;
                
        mergedPercent = ((totalCollection / actualSalesOrder.NetAmount__c) * 100).setScale(2);
        
        Boolean hasMergedAck = false;
        Set<Id> salesOrderIdSet = new Set<Id>{ existingSalesOrderId };
        Set<Id> ackIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();
        
        Boolean hasMergedLine = false;
        Boolean hasSecondLine = true;
        
        List<InstallmentLines__c> installmentsToInsert = new List<InstallmentLines__c>();
        List<ReceiptAcknowledgement__c> acknowledgementsToInsert = new List<ReceiptAcknowledgement__c>();
        List<ReceiptAllocation__c> allocationsToInsert = new List<ReceiptAllocation__c>();
     
        
        List<InstallmentLines__c> actualInstallments = lineServiceObj.getAllInstallmentLinesBySalesOrder(salesOrderIdSet);
        
        
        if(!actualInstallments.isEmpty()){
              // Merged Installment
        InstallmentLines__c mergedLine = new InstallmentLines__c(
            External_Id__c = caseRec.Sales_Order__c,
            Type__c = 'Down Payment',
            SalesOrder__c = newOrder.Id,
            Description__c = 'Resale',
            SAP_Condition_Type__c = MERGED_INSTALLMENT_CONDITION_TYPE,
            InstallmentDate__c = System.today(),
            InstallmentNumber__c = 1
            
        );
        lineIds.add(mergedLine.External_Id__c);
        
        InstallmentLines__c secondLine = new InstallmentLines__c(
            SalesOrder__c = newOrder.Id,
            Type__c = 'Handover',
            InstallmentDate__c = System.today(),
            InstallmentNumber__c = 2
            
        );
       
        
        // Merged Acknowledgement
        ReceiptAcknowledgement__c mergedAcknowledgement = new ReceiptAcknowledgement__c(
            External_Id__c = newOrder.Id,
            SalesOrder__c = newOrder.Id,
            Account__c = newOrder.Account__c,
            Status__c = 'Cleared',
            MaturityDate__c = System.today(),
            Opportunity__c = newOrder.Opportunity__c,
            PaymentType__c = 'Transfer of rights - Resale',
            ReferenceNumber__c = 'Transfer of rights - Resale'
        );
        ackIds.add(mergedAcknowledgement.External_Id__c);
        
        // Merged Allocation
        ReceiptAllocation__c mergedAlloc = new ReceiptAllocation__c(
            SalesOrder__c = newOrder.Id,
            Account__c = newOrder.Account__c,
            DateOfApplication__c = System.today(),
            ReceiptAcknowledgement__c = mergedAcknowledgement.External_Id__c,
            TypeOfInvoice__c = 'Installment',
            InstallmentLine__c = mergedLine.External_Id__c
        );
       
        Integer count = 2;    
    for (InstallmentLines__c actualLine : actualInstallments) {
            if (actualLine.Type__c =='Installment' ||actualLine.Type__c =='Down Payment' ) {
             hasMergedLine = true;
                mergedLine.AmountReceived__c = totalCollection;
                mergedLine.ClearedAmount__c = totalCollection;
                mergedLine.InstallmentAmount__c = totalCollection;
                mergedLine.InstallmentPercentage__c = mergedPercent;
                mergedLine.BrokerPayoutPercentage__c = sum(mergedLine.BrokerPayoutPercentage__c, actualLine.BrokerPayoutPercentage__c);
                mergedLine.Installment_Amount_Excluding_ADM__c = sum(mergedLine.Installment_Amount_Excluding_ADM__c, actualLine.Installment_Amount_Excluding_ADM__c);  
                        
            } else {
                hasSecondLine = true;
                secondLine.AmountReceived__c =0;
                secondLine.ClearedAmount__c = 0;
                if(actualLine.Type__c == 'Handover'){
                 secondLine.Description__c =  actualLine.Description__c;  
                    if(actualLine.Due_Date__c >=System.today()){
                       secondLine.InstallmentDate__c = actualLine.Due_Date__c;
                    }
                    if(actualLine.PaymentInstallments__c!=null){
                      secondLine.PaymentInstallments__c = actualLine.PaymentInstallments__c;   
                    }
               }
                secondLine.BrokerPayoutPercentage__c = sum(secondLine.BrokerPayoutPercentage__c, actualLine.BrokerPayoutPercentage__c);
                secondLine.Installment_Amount_Excluding_ADM__c = sum(secondLine.Installment_Amount_Excluding_ADM__c, actualLine.Installment_Amount_Excluding_ADM__c);
                
            } 
        
        }     
         
            if(hasSecondLine){
               
                  secondLine.InstallmentAmount__c = actualSalesOrder.NetAmount__c - totalCollection;   
                  secondLine.InstallmentPercentage__c = 100 - mergedPercent;
                  secondLine.Type__c = 'Handover';
                  hasMergedAck = true;
                  mergedAcknowledgement.Amount__c =totalCollection;
                  mergedAlloc.AmountApplied__c = totalCollection;
                  mergedAcknowledgement.PaymentType__c = 'Transfer of rights - Resale'; 
               
            }
      
        if(hasMergedAck || hasMergedLine){
            if(hasMergedLine)installmentsToInsert.add(mergedLine);
            if(hasSecondLine)installmentsToInsert.add(secondLine);
            if(hasMergedAck){
                acknowledgementsToInsert.add(mergedAcknowledgement);
                allocationsToInsert.add(mergedAlloc);  
            }
        }
        }
      
        
        
       
        
        if (!installmentsToInsert.isEmpty()) lineServiceObj.insertInstallmentWithoutTrigger(installmentsToInsert);
       
        if (!acknowledgementsToInsert.isEmpty()) receiptServiceObj.insertReceiptAcknowledgementWithoutTrigger(acknowledgementsToInsert);
        if (!allocationsToInsert.isEmpty()) insertAllocations(allocationsToInsert, lineIds, ackIds);
      
    } 
    
    public void insertAllocations(List<ReceiptAllocation__c> allocationsToInsert, Set<Id> lineIds, Set<Id> ackIds) {
        
        InstallmentLineService lineServiceObj = InstallmentLineService.getInstance();
        ReceiptAcknowledgementService receiptServiceObj = ReceiptAcknowledgementService.getInstance();
        ReceiptAllocationService allocationServiceObj = ReceiptAllocationService.getInstance();
        
        // Fetch records by external IDs
        Map<Id, InstallmentLines__c> insMap = new Map<Id, InstallmentLines__c>();
        for (InstallmentLines__c line : lineServiceObj.getInstallmentLinesByExternalIds(lineIds)) {
            insMap.put(line.External_Id__c, line);
        }
        
        Map<Id, ReceiptAcknowledgement__c> receiptMap = new Map<Id, ReceiptAcknowledgement__c>();
        for (ReceiptAcknowledgement__c receipt : receiptServiceObj.getReceiptAcknowledgementByExternalId(ackIds)) {
            receiptMap.put(receipt.External_Id__c, receipt);
        }
        
        // Map external IDs to internal Salesforce IDs
        for (ReceiptAllocation__c alloc : allocationsToInsert) {
            InstallmentLines__c line = insMap.get(alloc.InstallmentLine__c);
            if (line != null) alloc.InstallmentLine__c = line.Id;
            
            ReceiptAcknowledgement__c receipt = receiptMap.get(alloc.ReceiptAcknowledgement__c);
            if (receipt != null) alloc.ReceiptAcknowledgement__c = receipt.Id;
        }
        
        allocationServiceObj.insertReceiptAllocationsWithoutTrigger(allocationsToInsert);
    }
    
    public  List<SalesOrderOtherCharges__c> calculateOtherCharges(Case caseRec, SalesOrder__c newOrder,Id existingSalesOrderId) {
        Set<Id> ordrIds = new Set<Id>{newOrder.ID,existingSalesOrderId};
            Map<Id,SalesOrder__c> salesOrdersMap = SalesOrderService.getInstance().getSalesOrdersMap(ordrIds);
        List<SalesOrderOtherCharges__c> otherChargesToInsert = new List<SalesOrderOtherCharges__c>();
        List<ChargeWrapper> charges = new List<ChargeWrapper>();
        
        if (caseRec.RecoveryFee__c != null && !caseRec.ExcludeRecoveryFee__c)
            charges.add(new ChargeWrapper(caseRec.RecoveryFee__c, 'Recovery Fee'));
        
        if (caseRec.PendingFees__c != null && !caseRec.ExcludePendingFee__c)
            charges.add(new ChargeWrapper(caseRec.PendingFees__c, 'Pending Fee'));
        
        if (caseRec.BouncedChequeFees__c != null && !caseRec.ExcludeChequeBounceFee__c)
            charges.add(new ChargeWrapper(caseRec.BouncedChequeFees__c, 'Cheque Bounce Fee'));
        
        // if (caseRec.LatePaymentFees__c != null)
        //     charges.add(new ChargeWrapper(caseRec.LatePaymentFees__c, 'Late Payment Charges'));
        
        if (caseRec.ChequeWithWithdrawlFees__c != null && !caseRec.ExcludeChequeWithdrawlFee__c)
            charges.add(new ChargeWrapper(caseRec.ChequeWithWithdrawlFees__c, 'Cheque Withdrawal Fee'));
        
        if(caseRec.CancellationFees__c != null && caseRec.CancellationFees__c>0)
             charges.add(new ChargeWrapper(caseRec.CancellationFees__c, 'Unit Cancellation Fees'));
        
        if (caseRec.ADMFees__c != null && !caseRec.ExcludeAdminFee__c)
            charges.add(new ChargeWrapper(caseRec.ADMFees__c, 'Resale Admin fee'));
         if (caseRec.HassantukFee__c != null && !caseRec.ExcludeHassantukFee__c)
            charges.add(new ChargeWrapper(caseRec.HassantukFee__c, 'Hassantuk Fee'));
        
         if (caseRec.TitleDeedFees__c != null 
            && !caseRec.ExcludeTitleDeedFee__c 
            && !String.isEmpty(caseRec.BookTitleFeeUnder__c)
            && caseRec.BookTitleFeeUnder__c =='Seller')
            charges.add(new ChargeWrapper(caseRec.TitleDeedFees__c, 'Dari Title Deed Fee'));
     
        
        
                    for (ChargeWrapper c : charges) {
                        if (c.amount != null && c.amount>0) {
                            SalesOrderOtherCharges__c charge = new SalesOrderOtherCharges__c();
                            if(c.chargeType =='Resale Admin fee'){
                              charge.IsVATApplicable__c = true;  
                            }
                            charge.Amount__c = c.amount;
                            charge.Due_Date__c = System.today();
                            charge.SalesOrder__c = existingSalesOrderId;
                            charge.Account__c = salesOrdersMap.get(existingSalesOrderId).Account__c;
                            charge.TypeOfCharge__c = c.chargeType;
                            otherChargesToInsert.add(charge);
                        }
                    }
        List<SalesOrderOtherCharges__c> otherChargesForNewContract = calculateOtherChargesForNewSalesOrder(caseRec,salesOrdersMap.get(newOrder.id));
        if(!otherChargesForNewContract.isEmpty()){
            otherChargesToInsert.addAll(otherChargesForNewContract);  
        }
        return otherChargesToInsert; 
    }
    
    public List<SalesOrderOtherCharges__c> calculateOtherChargesForNewSalesOrder(Case caseRec, SalesOrder__c newOrder) {
        
        List<ChargeWrapper> charges = new List<ChargeWrapper>();
        List<SalesOrderOtherCharges__c> otherChargesToInsert = new List<SalesOrderOtherCharges__c>();
        
        // Setup helpers
        /*String unitType = caseRec.Unit__r != null ? caseRec.Unit__r.UnitType__c : '';
Decimal netAmount = caseRec.Sales_Order__r != null ? caseRec.Sales_Order__r.NetAmount__c : 0;
Project__c project = newOrder.Unit__r != null ? newOrder.Unit__r.Project__r : null;

Boolean isVilla = new Set<String>{ 'Villa', 'Townhouse' }.contains(unitType);
Boolean isApt = new Set<String>{ 'Apartment', 'Serviced Apartment', 'Hotel Apartment' }.contains(unitType);

if (project == null) return otherChargesToInsert;

// Add charges based on resale type and unit category
if (caseRec.ResalePaymentType__c == 'Resale Unit') { 
if (isVilla) {
charges.add(new ChargeWrapper(project.ResaleUnitAdminFeeVilla__c, 'ADM Admin Fee'));
charges.add(new ChargeWrapper(project.ResaleUnitEvaluationFeeVilla__c, 'Evaluation Fees'));
} else if (isApt) {
charges.add(new ChargeWrapper(project.ResaleUnitAdminFeeApt__c, 'ADM Admin Fee'));
charges.add(new ChargeWrapper(project.ResaleUnitEvaluationFeeApt__c, 'Evaluation Fees')); 
}
} else if (caseRec.ResalePaymentType__c == 'Resale with Mortgage') {
if (isVilla) {
charges.add(new ChargeWrapper(project.ResaleWithMortgageAdminFeeVilla__c, 'ADM Admin Fee'));
charges.add(new ChargeWrapper(project.ResaleWithMortgageMortgageFeeVilla__c * 0.01 * netAmount, 'Mortgage Fees'));
charges.add(new ChargeWrapper(project.ResaleWithMortgageEvaluationFeeVilla__c, 'Evaluation Fees'));
} else if (isApt) {
charges.add(new ChargeWrapper(project.Resal eWithMortgageAdminFeeApt__c, 'ADM Admin Fee'));
charges.add(new ChargeWrapper(project.ResaleWithMortgageMortgageFeeApt__c * 0.01 * netAmount, 'Mortgage Fees'));
charges.add(new ChargeWrapper(project.ResaleWithMortgageEvaluationFeeApt__c, 'Evaluation Fees'));
}
}
else{
if(project.AdminFee__c!=null)
charges.add(new ChargeWrapper(project.AdminFee__c* 0.01, 'ADM Admin Fee'));

}*/
        
        
        
        Map<Decimal, String> feeMap = new Map<Decimal, String>();
        
        if (caseRec.EvaluationFees__c != null && !caseRec.ExcludeEvaluationFee__c)
            feeMap.put(caseRec.EvaluationFees__c, 'Evaluation Fees');
        
        if (caseRec.TitleDeedFees__c != null 
            && !caseRec.ExcludeTitleDeedFee__c 
            && !String.isEmpty(caseRec.BookTitleFeeUnder__c)
            && caseRec.BookTitleFeeUnder__c =='Buyer')
            feeMap.put(caseRec.TitleDeedFees__c, 'Dari Title Deed Fee');
        
        if (caseRec.MortgageFees__c != null && !caseRec.ExcludeMortgageFee__c)
            feeMap.put(caseRec.MortgageFees__c, 'Mortgage Fees');
            
        Decimal admFeeTotal = 
            (caseRec.ADMTotalFees__c != null ? caseRec.ADMTotalFees__c : 0) +
            (caseRec.ADMAdminFees__c != null ? caseRec.ADMAdminFees__c : 0);
        
        if (admFeeTotal > 0 && !caseRec.ExcludeAdmFee__c)
            feeMap.put(admFeeTotal, 'ADM Fee');

               
              
               
                    
                    for (Decimal fee : feeMap.keySet()) {
                        if (fee != null && fee > 0) {
                            charges.add(new ChargeWrapper(fee, feeMap.get(fee)));
                        }
                    }
        
        // Prepare final charge records
        for (ChargeWrapper c : charges) {
            if (c.amount != null && c.amount>0) {
                otherChargesToInsert.add(new SalesOrderOtherCharges__c(
                    Amount__c = c.amount,
                    Due_Date__c = System.today(),
                    SalesOrder__c = newOrder.Id,
                    Account__c = newOrder.Account__c,
                    TypeOfCharge__c = c.chargeType
                ));
            }
        }
        
        return otherChargesToInsert;
    }
    
    public void cancelAndReassignSalesOrdersForResale(Case caseObj) {
        
        SalesOrderService salesOrderService = SalesOrderService.getInstance();
        OpportunityService oppServiceObj = OpportunityService.getInstance();
        List<SalesOrder__c> ordersToUpdate = new List<SalesOrder__c>();
        List<Opportunity> oppToUpdate = new List<Opportunity> ();
        List<InstallmentLines__c> insToUpdate = new List<InstallmentLines__c> ();
        List<ReceiptAcknowledgement__c> receiptsToUpdate = new  List<ReceiptAcknowledgement__c>();
        List<ReceiptAllocation__c> allocsToUpdate = new List<ReceiptAllocation__c> ();
        List<SalesOrderOtherCharges__c> chargesToUpdate = new  List<SalesOrderOtherCharges__c> (); 
        List<Unit__c> unitToUpdate = new List<Unit__c> ();
        
        InstallmentLineService lineService = InstallmentLineService.getInstance();
        ReceiptAcknowledgementService receiptService = ReceiptAcknowledgementService.getInstance();
        ReceiptAllocationService allocService =  ReceiptAllocationService.getInstance();
        SalesOrderOtherChargesService otherChargeService = SalesOrderOtherChargesService.getInstance();
       //List<InstallmentLines__c> resaleIns = lineService.getPaidInstallmentLinesBySalesOrder(new Set<Id>{caseObj.NewSalesOrder__c});
       List<InstallmentLines__c> resaleIns =  lineService.getOldInstallmentLinesBySalesOrderandDueDate(new Set<Id>{caseObj.NewSalesOrder__c});          
       List<ReceiptAcknowledgement__c> receipts =  receiptService.getAllReceiptAcknowledgementBySalesOrders(new Set<Id>{caseObj.NewSalesOrder__c});
       List<ReceiptAllocation__c> allocs =  allocService.getAllReceiptAllocationBySO(caseObj.NewSalesOrder__c);
       List<SalesOrderOtherCharges__c> charges = otherChargeService.getSalesOrderChargesBySalesOrder(caseObj.NewSalesOrder__c);
        Date todayDate = Date.today();
        DateTime dt = DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day()+1);
        
        String formattedDate = dt.format('ddMMyy');
       
        // Cancel original sales order
        if (caseObj.Sales_Order__c != null) {
            ordersToUpdate.add(new SalesOrder__c(
                Id = caseObj.Sales_Order__c,
                Status__c = 'Cancelled',
                //Resale__c  = true,
                SalesOrderCancelledDate__c = System.today(),
                Reason_for_Cancellation__c = 'Resale',
                NewSalesOrder__c = caseObj.NewSalesOrder__c,
                NewCustomer__c = caseObj.NewCustomerAccount__c
            ));
        }
        
        // Mark new sales order as Sold
        if (caseObj.NewSalesOrder__c != null) {
            SalesOrder__c ordrToUpdate = new SalesOrder__c();
            
            ordrToUpdate.Id = caseObj.NewSalesOrder__c;
            ordrToUpdate.Status__c = 'Sold';
            ordrToUpdate.IsDraftOrder__c = false;
            ordrToUpdate.BookingDate__c = System.today().addDays(1);
            ordrToUpdate.ResoldDate__c = System.today().addDays(1);
               ordrToUpdate.ADMFeeAmount__c =
                (caseObj.ADMTotalFees__c != null ? caseObj.ADMTotalFees__c : 0) +
                (caseObj.ADMAdminFees__c != null ? caseObj.ADMAdminFees__c : 0);
            ordrToUpdate.Send_to_SAP__c = true;
            ordrToUpdate.Resale__c = true;
            ordrToUpdate.Name = caseObj.Unit__r.name + '-' + formattedDate;
            if(caseObj.TypeOfResale__c == 'Resale' 
               ||caseObj.TypeOfResale__c =='Swap'){
                   ordrToUpdate.ServiceChargeStartDate__c  =System.today().addDays(2);    
               }
            ordersToUpdate.add(ordrToUpdate);
    
           
            unitToUpdate.add(new Unit__c(
                Id = caseObj.Unit__c,
                Active_Sales_Order__c = caseObj.NewSalesOrder__c
                
            ));
            oppToUpdate.add(new Opportunity(
                Id = caseObj.NewSalesOrder__r.Opportunity__c,
                StageName ='Closed Won',
                CloseDate = System.today()
                //AgentType__c = 'Direct'
            ));
        }
        if(!resaleIns.isEmpty()){
            for(InstallmentLines__c line :resaleIns){
            InstallmentLines__c lineToUpdate = new InstallmentLines__c();
            lineToUpdate.id  =line.id;
            lineToUpdate.InstallmentDate__c = System.today().addDays(1);
            insToUpdate.add(lineToUpdate);    
            }
          
        }
        if(!receipts.isEmpty()){
            for(ReceiptAcknowledgement__c rc : receipts){
                ReceiptAcknowledgement__c ack =  new ReceiptAcknowledgement__c();
                ack.id = rc.id;
                ack.MaturityDate__c = System.today().addDays(1);
                if(ack.VerifyDate__c!=null){
                 ack.ReceiptPostingDate__c = ack.VerifyDate__c;   
                }
                
                receiptsToUpdate.add(ack);
            }
        }
        if(!allocs.isEmpty()){
            for(ReceiptAllocation__c aloc : allocs){
                ReceiptAllocation__c alocObj = new ReceiptAllocation__c();
                alocObj.id = aloc.id;
                alocObj.DateOfApplication__c =System.today().addDays(1);
                allocsToUpdate.add(alocObj);
                
            }
        }
        if(!charges.isEmpty()){
        for(SalesOrderOtherCharges__c  otherCharge : charges){
            SalesOrderOtherCharges__c chargeToUpdate =  new SalesOrderOtherCharges__c();
            chargeToUpdate.id = otherCharge.id;
            chargeToUpdate.Due_Date__c = System.today().addDays(1);
            chargesToUpdate.add(chargeToUpdate);
        }    
        }
        
        if(!Test.isRunningTest()){
        if (!ordersToUpdate.isEmpty()) {
            salesOrderService.updateSalesOrdersWithoutTrigger(ordersToUpdate);
        }
        if (!oppToUpdate.isEmpty()){
            oppServiceObj.updateOpportunitiesWithoutTrigger(oppToUpdate);
        }
        if(!insToUpdate.isEmpty()){
            lineService.updateInstallmentLines(insToUpdate);
        }
        if(!receiptsToUpdate.isEmpty()){
            receiptService.updateReceiptAcknowledgementWithoutTrigger(receiptsToUpdate);
        }
         if(!allocsToUpdate.isEmpty()){
             allocService.updateReceiptAllocationsWithoutTrigger(allocsToUpdate);
            
        }
         if(!chargesToUpdate.isEmpty()){
            otherChargeService.upsertSalesOrderOtherCharges(chargesToUpdate);
        }
        if(!unitToUpdate.isEmpty()){
            UnitService.getInstance().updateUnitsWithoutTrigger(unitToUpdate);
        } 
        }
        }   
    
    // Define a wrapper to hold amount + charge type
    public class ChargeWrapper {
        public Decimal amount; 
        public String chargeType;
        
        public ChargeWrapper(Decimal amount, String chargeType) {
            this.amount = amount;
            this.chargeType = chargeType;
        }
    }
    
    public Decimal sum(Decimal value1, Decimal value2) {
        return (value1 == null ? 0 : value1) + (value2 == null ? 0 : value2);
    }
    
    public void updateHandoverRecords(List<Case> caseList) {

        if(caseList == null || caseList.isEmpty()){
            return;
        }

        Map<Id, Case> salesOrderCaseMap = new Map<Id, Case>();

        for(Case c : caseList){
            if(c.Sales_Order__c != null &&
            c.NewSalesOrder__c != null &&
            c.NewCustomerAccount__c != null){
                salesOrderCaseMap.put(c.Sales_Order__c, c);
            }
        }

        if(salesOrderCaseMap.isEmpty()){
            return;
        }

    
    List<Handover__c> handoversToUpdate = [SELECT Id,Sales_Order__c,Account__c,Sub_Status__c,Previous_HO_Status__c,Is_Property_keys_given__c FROM Handover__c WHERE Sales_Order__c IN :salesOrderCaseMap.keySet() AND Sub_Status__c = 'Under Resale'];//AND Is_Property_keys_given__c = false];

        for(Handover__c handover : handoversToUpdate){
        Case relatedCase = salesOrderCaseMap.get(handover.Sales_Order__c);

            if(relatedCase != null){
                handover.Sales_Order__c = relatedCase.NewSalesOrder__c;
                handover.Account__c = relatedCase.NewCustomerAccount__c; 
                handover.Sub_Status__c = handover.Previous_HO_Status__c;
                handover.Previous_HO_Status__c = 'Under Resale';
            }
        }

        if(!handoversToUpdate.isEmpty()){
            HandoverService.getInstance().updateHandoversWithoutTrigger(handoversToUpdate);
        }
     return;
    }
    public void cancelDraftSalesOrders(Set<Id> caseIds) {
        CaseService caseObjService = CaseService.getInstance();
        List<Case> caseList = caseObjService.getCaseByIds(caseIds);
        List<SalesOrder__c> ordersToUpdate = new List<SalesOrder__c> ();
        for(Case caseObj : caseList){
            if(caseObj.NewSalesOrder__c!=null && caseObj.NewSalesOrder__r.IsDraftOrder__c ){
                SalesOrder__c ordr = new SalesOrder__c();
                ordr.id = caseObj.NewSalesOrder__c;
                ordr.Status__c = 'Cancelled';
                ordersToUpdate.add(ordr);
            }
        }
       
             SalesOrderService.getInstance().updateSalesOrdersWithoutTrigger(ordersToUpdate); 
        
    }
     public void updateBrokerDetails(Case caseObj) {
        
        SalesOrderService salesOrderService = SalesOrderService.getInstance();
        List<SalesOrder__c> ordersToUpdate = new List<SalesOrder__c>();
        
        if (caseObj.NewSalesOrder__c != null) {
            SalesOrder__c ordrToUpdate = new SalesOrder__c();
            ordrToUpdate.Id = caseObj.NewSalesOrder__c;
            if(caseObj.Broker_Agent__c!=null)
                ordrToUpdate.ResaleBrokerAgent__c = caseObj.Broker_Agent__c;
            if(caseObj.BrokerAgency__c!=null)
                ordrToUpdate.ResaleBrokerAgency__c = caseObj.BrokerAgency__c;
            ordersToUpdate.add(ordrToUpdate);
        }
        if(!Test.isRunningTest()){
            if (!ordersToUpdate.isEmpty()) {
                salesOrderService.updateSalesOrdersWithoutTrigger(ordersToUpdate);
                
            }   
        }       
    }

    
}
/*****************************************************************************************
Class       : CaseService
Author      : Biswajeet 
Description : Case service class
test Class  : CaseServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public inherited sharing  class CaseService {
    
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_COMMUNITY_SR_ASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'CommunityAppSRAssignmentEmailTempId'; } }

    
    private static CaseService instance;
    
    private CaseService() {
        
    }
    
    public static CaseService getInstance() { 
        if(instance == null) {
            instance = new CaseService();
        }
        return instance;
    }
    public List<Case> getCaseByAccountIds(Set<Id> accountIds){
         return [SELECT Id, AccountId FROM Case WHERE AccountId IN :accountIds];
    }
    
    public List<Case> getCaseByIdsAndCreatedByIds(Set<Id> caseIds, Set<Id> createdByIds){
        return [SELECT Id, Work_Order__c,RoundRobinNumber__c, Project__c, CaseNumber, NewCustomerAccount__c,
                SuppliedName, OwnerId, Owner.Email, Owner.Name, Project__r.Name, Subject, NewSalesOrder__c,
                ClosedDate, Status, Account__c, Account_Email__c, Account__r.Name, Unit__c, Sales_Order__c,
                Closure_Reason__c, Closure_Comment__c, SuppliedEmail, Resolution_Comments__c, Projectname__c
                FROM Case WHERE Id IN: caseIds AND CreatedById IN:createdByIds];
     }
    
    public List<Case> getCaseByIds(Set<Id> caseIds){
        return [SELECT Id, deviceRegistrationId__c,CaseNumber,ContactId, OwnerId, CreatedById, RoundRobinNumber__c,Sales_Order__c,Owner.email,Status,CaseType__c,CaseClosureRemarks__c ,
                RequesterEmail__c,BFMRequestStatus__c,NewSalesOrder__r.IsDraftOrder__c,BFMServiceRequestId__c,RecordType.DeveloperName,RequesterName__c,RequesterContactNumber__c,
                Sales_Order__r.Offer__r.Name,Sales_Order__r.First_Installment_Received_Amount__c,Unit__c,Project__c,AccountId,IsDocumentAvailable__c,isNotRegistered__c,
                Sales_Order__r.First_Installment_Amount__c,Sales_Order__r.Offer__c,RecordTypeId,ServiceCatalog__c,DeferralApprovalStatus__c,Deferral_Within_1_Month__c,
                IsDPCleared__c,RecordType.Name,Sales_Order__r.Unit__r.Name,Step__c,PaymentDeferralReason__c,Account.isPersonAccount,SubType__c,
                Payment_Booked__c, Payment_Due_Date__c,Case_Sub_Status__c, Finance_document_verified__c, SubStatus__c, Project__r.Name,Case_Contact_Name__c,
                VehicleRegistrationStatus__c,Account.Name,Account.NameinArabic__c,Account.PersonContactId, FinanceDocumentsUploadedManually__c, Remarks__c, TPFType__c,
                RequestRaisedToBank__c, Neccessory_fees_collected__c,Broker_Agent__c,CancellationFees__c,TotalADMFees__c,ChequeWithWithdrawlFees__c,No_of_Withdrawal_Cheques__c,
                StopEmailsToCustomer__c,TradeLicenseExpiryDate__c,VATUndertakingIssue_Date__c,TaxRegistrationNumber__c,PhoneNumber__c,Address1__c,Address2__c,CommercialLicenseExpiryDate__c,
                AccountNumber__c,BankName__c,BankAddress__c,IBANNumber__c,SwiftCode__c,Requester_Phone__c,
                EarlySettlement__c,Email_Address__c,Return_Comments__c,SendToBL__c,Unit__r.Project__c,CreatedBy.ProfileId,Origin,Projectname__c,Customer_Type__c,Customer_Sub_Type__c,NameofCorporate__c
                FROM Case WHERE Id IN :caseIds ORDER BY CreatedDate];
        
    }

    public List<Messaging.SingleEmailMessage> sendEmailToCaseOwner(List<Case> caseList){
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMMUNITY_SR_ASSIGNMENT_EMAIL_TEMPLATE_ID);
        UserService  objUserService = UserService.getInstance();
        Set<Id> caseOwnerIdSet = new Set<Id>();
        for(Case caseObj : caseList){
            caseOwnerIdSet.add(caseObj.OwnerId);
        }
        Map<Id, User> ownerMap = objUserService.getActiveUsersByIds(caseOwnerIdSet);
        for(Case caseObj : caseList){
            Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseObj.Id,new List<String>{ownerMap.get(caseObj.OwnerId).Email} , null, null);
            emailList.add(objMail);
        }
        return emailList;
    }
    
    public Case getCaseById(Id caseId) {
        return [
            SELECT Handover__c,CommonArea__r.CommonAreaName__c,CommonArea__r.Name,PendingWith__c,AssignTeam__c,CreatedBy.Name,
            Id, CaseNumber, Subject,deviceRegistrationId__c, Description, Status, Priority, Origin, Type, Category__c, SubCategory__c,SubType__c,TotalADMFees__c,No_of_Withdrawal_Cheques__c,IsDocumentAvailable__c,
            OwnerId, CreatedById, RecordTypeId, RecordType.Name, RecordType.DeveloperName, RequestType__c, Discipline__c, Area__c, User_Type__c, Request_Number__c,CaseClosureRemarks__c ,
            RequesterRemarks__c, RequesterName__c, RequesterContactNumber__c, RequesterEmail__c, Contacts_Case_Email__c, Comments, CaseType__c,ApprovalComments__c,RejectionComments__c,
            Contact.Name, Contact.Email, Owner.Name, Owner.Email,BrokerContactRole__c,TypeofEstablishment__c,NationalIDExpiryDate__c,PassportExpiryDate__c,BRN_RERA_Expiry_Date__c,ApprovalStatus__c,
            AccountId, Account__c, Account.Name, Account.NameinArabic__c, Account.Legal_Status__c, Account.PersonEmail, Account.RecordTypeId, Account.RecordType.DeveloperName, Account.IsPersonAccount, Account.PersonContactId,
            Account.IsBFMVIPCustomer__c, Address__c, Address__City__s, Address__CountryCode__s, Address__Latitude__s, Address__Longitude__s, Address__GeocodeAccuracy__s, Address__PostalCode__s, Address__StateCode__s, Address__Street__s,
            First_Name__c, Last_Name__c, Name__c, Nationality__c, CustomerType__c, Customer_Type__c, Gender__c, Mobile_Number__c, Mobile_Country_Code__c, Account_Mobile_Number__c,Requester_Phone__c,
            Email_Address__c, Account_Email__c, EmiratesID__c, Emirates_ID_expiry_date__c, EIDIssueDate__c, PassportNumber__c, PassportIssueDate__c, isLegalReviewRequired__c, LegalApprovalStatus__c,
            BuyerLegalApprovalStatus__c, BouncedChequeFees__c, LatePaymentFees__c, PendingFees__c, PostponementFeesBooked__c, PostponeApproved__c, RecoveryFee__c, ResalePaymentType__c, ChequeWithWithdrawlFees__c, DefaultNoticeSentTime__c,
            DefaultNoticeSentBy__c, NumberOfDefaultNoticeRemindersSent__c, IsPaymentReviewRequired__c, PaymentApprovalStatus__c, WillMakeMorePayment__c, Trade_License_No__c, Trade_License_Issue_Date__c, Trade_License_Expiry_Date__c, Registration_Authority__c, 
            Unit__c, Unit__r.Name, Unit__r.UnitType__c, Unit__r.RegistrationDate__c, Unit__r.BFMUnitNumber__c, Unit__r.Active_Sales_Order__c, Unit__r.Active_Sales_Order__r.Account__c, Unit__r.Project__r.Name, Unit__r.Project__r.ProjectNameArabic__c, Unit__r.Building__r.Name,
            Unit__r.BuildingSectionName__r.Name, UnitRegistered__c, Unit_Mortgaged__c, Title_Deed_Issued__c, TitleDeedShared__c, Rented__c, ConsumptionSettled__c, ADDC_Transferred__c, Sales_Order__c, Sales_Order__r.Name,
            Sales_Order__r.Account__c, Sales_Order__r.NetAmount__c, Sales_Order__r.SalesManager__c, Sales_Order__r.Sales_Order_Number__c, Sales_Order__r.First_Installment_Amount__c, Sales_Order__r.First_Installment_Received_Amount__c, Sales_Order__r.Offer__c, Sales_Order__r.Offer__r.Name, Sales_Order__r.Unit__r.Name,
            Sales_Order__r.Project__c, Sales_Order__r.Opportunity__r.WinReason__c, Sales_Order__r.Opportunity__r.LeadChannel__c, Sales_Order__r.Opportunity__r.CloseDate, NewSalesOrder__c, NewSalesOrder__r.Opportunity__c, PaymentReceived__c, RefundAmount__c, WithdrawlRequestInitiated__c, TotalInstalmentDue__c,
            DeferralApprovalStatus__c, Deferral_Within_1_Month__c, PaymentDeferralReason__c, Deferral_Fee_Paid__c, ChequeScanned__c, IsDPCleared__c, City__c, Project__c, Step__c, RoundRobinNumber__c,
            ServiceCatalog__c, Service_Catalog__c, InAMC__c, InScope__c, Drawloop_Next_1__c, BFMServiceRequestId__c, Pre_title_deed_shared__c, Seller_Settled__c, NewPDCReceived__c,
            ReversalRequestSubmittedForPDCs__c, ADDCAmount__c, IsBuyerFinancing__c, HassantukFee__c, NewCustomerAccount__c,
            Payment_Booked__c, Payment_Due_Date__c, Finance_document_verified__c, SubStatus__c, Projectname__c,POPUploaded__c,IsThirdPartyNeeded__c, Account_Name__c, ServiceCatalog__r.SubCategoryArabic__c,DocumentsVerifiedUploaded__c, 
            ServiceCatalog__r.SubCategory__c,Unit__r.Project__r.chequePostponeFeeShortTerm__c,Unit__r.Project__r.chequePostponeFeeLongTerm__c,DeferralFee__c,Unit__r.Project__r.ResaleEligibleAmoutPercentage__c,
            Unit__r.Project__r.ChequesUnavailable__c,isNotRegistered__c,Unit__r.Project__r.FMRecipientEmail__c,Unit__r.Project__c,
            Account__r.Legal_Status__c, Customer_Name__c, CourierRequested__c, PreviousChequeInOffice__c, NewChequesCollected__c, ChequeReplacementFee__c, 
            SentOldChequesToCustomer__c, OldChequeReceivedFromBank__c, PDCSentToCustomer__c, NoOfChequesSelectedForReplacement__c, NewCustomerAccount__r.name,Sales_Order__r.ADMFeeAmount__c, NewCustomerAccount__r.RecordType.DeveloperName,
            FinanceDocumentsUploadedManually__c, Remarks__c, RequestRaisedToBank__c, Neccessory_fees_collected__c,TPFType__c,
            Sales_Order__r.ADM_Fee_Combined__c,Case_Sub_Status__c,Main_Buyer_Share_Percentage__c,CancellationFees__c,Customer_Sub_Type__c,NameofCorporate__c,
            Sales_Order__r.ADM_Fee_Included__c,BRN_RERA_Number__c,Country__c,
            Sales_Order__r.IsTaxable__c,NationalID__c,Title__c,IsVATRegistered__c,Address1__c,Address2__c,PhoneNumber__c,CommercialLicenseExpiryDate__c,BankName__c,AccountNumber__c,BankAddress__c,IBANNumber__c,SwiftCode__c,TaxRegistrationNumber__c,VATUndertakingIssue_Date__c,TradeLicenseExpiryDate__c,
            Sales_Order__r.ADMFeeWaivedAmount__c,
            Sales_Order__r.SellingPrice__c,
            Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
            Sales_Order__r.Sales_Price_Excluding_ADM__c,
            Sales_Order__r.AmountPayable__c,
            Sales_Order__r.Amount_Payable_Excluding_ADM__c,
            Sales_Order__r.PaymentPlanDiscount__c,
            Sales_Order__r.BulkDiscount__c,
            Sales_Order__r.Management_Discount__c,
            Sales_Order__r.Discount__c, 
            Sales_Order__r.CorporateDiscount__c,
            Sales_Order__r.BookingDate__c,
            Sales_Order__r.OwnerSharePercentage__c,Permit_To_Date__c,
            Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
            Sales_Order__r.SoldDate__c,
            Sales_Order__r.Broker_Agencyy__c,
            Sales_Order__r.ADM_DLD_Pre_Registered__c,
            Sales_Order__r.Pre_Title_Deed_Status__c,
            Sales_Order__r.Title_Deed_Status__c,
            Sales_Order__r.Handover_Status__c,
            Sales_Order__r.ADDC__c,
            Sales_Order__r.PaymentPlan__c,
            Sales_Order__r.PaymentPlan__r.Name,
            Sales_Order__r.ServiceChargesWaiverEndDate__c,
            Sales_Order__r.ServiceChargesWaiverStartDate__c,
            Sales_Order__r.ServiceChargeWaivedYears__c,
            Sales_Order__r.ServiceChargeStartDate__c,
            NewSalesOrder__r.Bloom_Signed_SPA_Date__c,
            Owner.Phone, InitialOwnerRemoved__c,
            NewCustomerAccount__r.IsPersonAccount,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c,
            Sales_Order__r.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c,
            IssuesWithFinancialDocument__c, FinancialDocumentAvailableInSF__c, DocumentUploadedFromSAP__c, LPFWaiverRequestApprovalStatus__c,
            ADMTotalFees__c,ADMFees__c,ADMAdminFees__c,EvaluationFees__c,MortgageRegistrationFees__c,TitleDeedFees__c,MortgageFees__c,PercentToBeSettled__c,CustomerPaidPercentage__c,
            BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c, ResalePrice__c, ResalePriceInArabicWords__c,
            ProjectStatus__c, RegistrationStatus__c, TypeOfResale__c,ResaleSubCategory__c,Unit__r.Project__r.City__c,BuyerNameInArabic__c,
            DefaultCustomerPaymentOverdueDate__c, Unit__r.Legal_Status__c,SmartHubActivated__c,TotalCollection__c,BookTitleFeeUnder__c,ExcludeEvaluationFee__c,ExcludeHassantukFee__c,ExcludeMortgageFee__c,ExcludePendingFee__c,
            ExcludeRecoveryFee__c,ExcludeTitleDeedFee__c,ExcludeAdmFee__c,ExcludeAdminFee__c,ExcludeChequeBounceFee__c,ExcludeChequeWithdrawlFee__c,NameOfPOA__c,PlaceOfIssuance__c,PlaceOfRegistration__c,RepresentationType__c,
            TypeOfCompany__c,RepresentativeArabicName__c,PercentageOfSharePurchased__c,LPFCompoundedLPFOnOtherCharges__c,ResaleToCompleteAmount__c, ChequeUnavailableInSF__c,
            AppRegistration__c, AppRegistration__r.Name,Salutation__c,PlaceofIssue__c,LanguagePreference__c,UAEResident__c,Birthdate__c,DirectIndirect__c,BrokerAgency__c,Broker_Agent__c,Broker_Commission__c,MOUDate__c,
            Unit__r.ADMAddressingNumber__c, EarlySettlement__c, StopEmailsToCustomer__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    public List<Case> getCasesByRecordTypeAndSalesOrder(Set<Id> salesOrderIds, Id recordTypeId){
        List<Case> caseList = [SELECT Id, SubStatus__c, CustomerDefaultStatus__c, NumberOfDefaultNoticeRemindersSent__c, TotalInstalmentDue__c, 
                               CaseNumber, City__c,Unit__r.UnitType__c,Unit__r.RegistrationDate__c,Account__r.Legal_Status__c,
                               BouncedChequeFees__c, LatePaymentFees__c, PendingFees__c, PaymentReceived__c,
                               Sales_Order__r.NetAmount__c,Sales_Order__r.Account__c,Sales_Order__r.name,Mobile_Number__c,Account__c,
                               Account.Legal_Status__c,Last_Name__c,First_Name__c,Mobile_Country_Code__c,Emirates_ID_expiry_date__c,
                               Nationality__c,Email_Address__c,PostponementFeesBooked__c,PostponeApproved__c,Subject, RequesterRemarks__c, 
                               Description,InitialOwnerRemoved__c, Unit__r.BFMUnitNumber__c, Unit__r.Building__r.Name, Unit__r.BuildingSectionName__r.Name, 
                               Customer_Name__c, Account_Mobile_Number__c, Account_Email__c, RequesterName__c, RequesterContactNumber__c, 
                               RequesterEmail__c, AccountId, Account.PersonEmail, Account.RecordTypeId, Account.RecordType.DeveloperName,
                               Unit__c,Unit__r.Active_Sales_Order__c,Unit__r.Active_Sales_Order__r.Account__c,BFMServiceRequestId__c,
                               Account.IsBFMVIPCustomer__c, Drawloop_Next_1__c, Priority, RequestType__c, Discipline__c, Type, Category__c, 
                               SubCategory__c, Origin, InAMC__c, InScope__c, Area__c,Status,Request_Number__c,User_Type__c,
                               OwnerId, CreatedById, RoundRobinNumber__c,Sales_Order__c,contact.email,Sales_Order__r.Sales_Order_Number__c,
                               Contact.Name,WithdrawlRequestInitiated__c, Sales_Order__r.Offer__r.Name, Comments, CaseType__c,
                               Sales_Order__r.First_Installment_Received_Amount__c,DeferralApprovalStatus__c,Deferral_Within_1_Month__c, 
                               Project__c, Account.IsPersonAccount, Account.PersonContactId, Sales_Order__r.First_Installment_Amount__c,
                               Sales_Order__r.Offer__c,RecordTypeId,ServiceCatalog__c,DefaultNoticeSentTime__c,DefaultNoticeSentBy__c,
                               Service_Catalog__c, IsDPCleared__c,RecordType.Name,RecordType.DeveloperName,Sales_Order__r.Unit__r.Name,
                               Sales_Order__r.Project__c,Step__c,PaymentDeferralReason__c,ChequeScanned__c,Deferral_Fee_Paid__c,ResaleToCompleteAmount__c 
                               FROM Case 
                               WHERE Sales_Order__c IN :salesOrderIds 
                               AND RecordTypeId = :recordTypeId];
        return caseList;
    }

    public List<Case> getOpenCasesByRecordTypeAndSalesOrder(Set<Id> salesOrderIds, Id recordTypeId){
        List<Case> caseList = [SELECT Id, SubStatus__c, CustomerDefaultStatus__c, NumberOfDefaultNoticeRemindersSent__c, TotalInstalmentDue__c, 
                               CaseNumber, City__c,Unit__r.UnitType__c,Unit__r.RegistrationDate__c,Account__r.Legal_Status__c,
                               BouncedChequeFees__c, LatePaymentFees__c, PendingFees__c, PaymentReceived__c,
                               Sales_Order__r.NetAmount__c,Sales_Order__r.Account__c,Sales_Order__r.name,Mobile_Number__c,Account__c,
                               Account.Legal_Status__c,Last_Name__c,First_Name__c,Mobile_Country_Code__c,Emirates_ID_expiry_date__c,
                               Nationality__c,Email_Address__c,PostponementFeesBooked__c,PostponeApproved__c,Subject, RequesterRemarks__c, 
                               Description, Unit__r.BFMUnitNumber__c, Unit__r.Building__r.Name, Unit__r.BuildingSectionName__r.Name, 
                               Customer_Name__c, Account_Mobile_Number__c, Account_Email__c, RequesterName__c, RequesterContactNumber__c, 
                               RequesterEmail__c, AccountId, Account.PersonEmail, Account.RecordTypeId, Account.RecordType.DeveloperName,
                               Unit__c,Unit__r.Active_Sales_Order__c,Unit__r.Active_Sales_Order__r.Account__c,BFMServiceRequestId__c,
                               Account.IsBFMVIPCustomer__c, Drawloop_Next_1__c, Priority, RequestType__c, Discipline__c, Type, Category__c, 
                               SubCategory__c, Origin, InAMC__c, InScope__c, Area__c,Status,Request_Number__c,User_Type__c,
                               OwnerId, CreatedById, RoundRobinNumber__c,Sales_Order__c,contact.email,Sales_Order__r.Sales_Order_Number__c,
                               Contact.Name,WithdrawlRequestInitiated__c, Sales_Order__r.Offer__r.Name, Comments, CaseType__c,
                               Sales_Order__r.First_Installment_Received_Amount__c,DeferralApprovalStatus__c,Deferral_Within_1_Month__c, 
                               Project__c, Account.IsPersonAccount, Account.PersonContactId, Sales_Order__r.First_Installment_Amount__c,
                               Sales_Order__r.Offer__c,RecordTypeId,ServiceCatalog__c,DefaultNoticeSentTime__c,DefaultNoticeSentBy__c,
                               Service_Catalog__c, IsDPCleared__c,RecordType.Name,RecordType.DeveloperName,Sales_Order__r.Unit__r.Name,
                               Sales_Order__r.Project__c,Step__c,PaymentDeferralReason__c,ChequeScanned__c,Deferral_Fee_Paid__c 
                               FROM Case 
                               WHERE Sales_Order__c IN :salesOrderIds 
                               AND RecordTypeId = :recordTypeId
                               AND Status != 'Closed'];
        return caseList;
    }
    
    public List<Case> getCasesByRecordTypeSalesOrderANDStatus(Id salesOrderId, List<Id> recordTypeIds, String status){
        List<Case> caseList = [SELECT 
            Id, CaseNumber, Subject, InitialOwnerRemoved__c,Description, Status, Priority, Origin, Type, Category__c, SubCategory__c,
            OwnerId, CreatedById, RecordTypeId, RecordType.Name, RecordType.DeveloperName, RequestType__c, Discipline__c, Area__c, User_Type__c, Request_Number__c,
            RequesterRemarks__c, RequesterName__c, RequesterContactNumber__c, RequesterEmail__c, Contacts_Case_Email__c, Comments, CaseType__c,
            Contact.Name, Contact.Email, Owner.Name, Owner.Email,
            AccountId, Account__c, Account.Name, Account.NameinArabic__c, Account.Legal_Status__c, Account.PersonEmail, Account.RecordTypeId, Account.RecordType.DeveloperName, Account.IsPersonAccount, Account.PersonContactId,
            Account.IsBFMVIPCustomer__c, Address__c, Address__City__s, Address__CountryCode__s, Address__Latitude__s, Address__Longitude__s, Address__GeocodeAccuracy__s, Address__PostalCode__s, Address__StateCode__s, Address__Street__s,
            First_Name__c, Last_Name__c, Name__c, Nationality__c, CustomerType__c, Customer_Type__c, Gender__c, Mobile_Number__c, Mobile_Country_Code__c, Account_Mobile_Number__c,
            Email_Address__c, Account_Email__c, EmiratesID__c, Emirates_ID_expiry_date__c, EIDIssueDate__c, PassportNumber__c, PassportIssueDate__c,PassportExpiryDate__c, isLegalReviewRequired__c, LegalApprovalStatus__c,
            BuyerLegalApprovalStatus__c, BouncedChequeFees__c, LatePaymentFees__c, PendingFees__c, PostponementFeesBooked__c, PostponeApproved__c, RecoveryFee__c, ResalePaymentType__c, ChequeWithWithdrawlFees__c, DefaultNoticeSentTime__c,
            DefaultNoticeSentBy__c, NumberOfDefaultNoticeRemindersSent__c, IsPaymentReviewRequired__c, PaymentApprovalStatus__c, WillMakeMorePayment__c, Trade_License_No__c, Trade_License_Issue_Date__c, Trade_License_Expiry_Date__c, Registration_Authority__c, 
            Unit__c, Unit__r.Name, Unit__r.UnitType__c, Unit__r.RegistrationDate__c, Unit__r.BFMUnitNumber__c, Unit__r.Active_Sales_Order__c, Unit__r.Active_Sales_Order__r.Account__c, Unit__r.Project__r.Name, Unit__r.Project__r.ProjectNameArabic__c, Unit__r.Building__r.Name,
            Unit__r.BuildingSectionName__r.Name, UnitRegistered__c, Unit_Mortgaged__c, Title_Deed_Issued__c, TitleDeedShared__c, Rented__c, ConsumptionSettled__c, ADDC_Transferred__c, Sales_Order__c, Sales_Order__r.Name,
            Sales_Order__r.Account__c, Sales_Order__r.NetAmount__c, Sales_Order__r.SalesManager__c, Sales_Order__r.Sales_Order_Number__c, Sales_Order__r.First_Installment_Amount__c, Sales_Order__r.First_Installment_Received_Amount__c, Sales_Order__r.Offer__c, Sales_Order__r.Offer__r.Name, Sales_Order__r.Unit__r.Name,
            Sales_Order__r.Project__c, Sales_Order__r.Opportunity__r.WinReason__c, Sales_Order__r.Opportunity__r.LeadChannel__c, Sales_Order__r.Opportunity__r.CloseDate, NewSalesOrder__c, NewSalesOrder__r.Opportunity__c, PaymentReceived__c, RefundAmount__c, WithdrawlRequestInitiated__c, TotalInstalmentDue__c,
            DeferralApprovalStatus__c, Deferral_Within_1_Month__c, PaymentDeferralReason__c, Deferral_Fee_Paid__c, ChequeScanned__c, IsDPCleared__c, City__c, Project__c, Step__c, RoundRobinNumber__c,
            ServiceCatalog__c, Service_Catalog__c, InAMC__c, InScope__c, Drawloop_Next_1__c, BFMServiceRequestId__c, Pre_title_deed_shared__c, Seller_Settled__c, NewPDCReceived__c,
            ReversalRequestSubmittedForPDCs__c, ADDCAmount__c, IsBuyerFinancing__c, HassantukFee__c, NewCustomerAccount__c,
            Payment_Booked__c, Payment_Due_Date__c, Finance_document_verified__c, SubStatus__c, Projectname__c,POPUploaded__c,IsThirdPartyNeeded__c, Account_Name__c, ServiceCatalog__r.SubCategoryArabic__c,DocumentsVerifiedUploaded__c, 
            ServiceCatalog__r.SubCategory__c,Unit__r.Project__r.chequePostponeFeeShortTerm__c,Unit__r.Project__r.chequePostponeFeeLongTerm__c,DeferralFee__c,Unit__r.Project__r.ResaleEligibleAmoutPercentage__c,
            Account__r.Legal_Status__c, Customer_Name__c, CourierRequested__c, PreviousChequeInOffice__c, NewChequesCollected__c, ChequeReplacementFee__c, Neccessory_fees_collected__c,
            SentOldChequesToCustomer__c, OldChequeReceivedFromBank__c, PDCSentToCustomer__c, NoOfChequesSelectedForReplacement__c, NewCustomerAccount__r.name,Sales_Order__r.ADMFeeAmount__c,
            FinanceDocumentsUploadedManually__c, Remarks__c, RequestRaisedToBank__c,TPFType__c,
            Sales_Order__r.ADM_Fee_Combined__c,
            Sales_Order__r.ADM_Fee_Included__c,
            Sales_Order__r.IsTaxable__c,Case_Sub_Status__c,
            Sales_Order__r.ADMFeeWaivedAmount__c,
            Sales_Order__r.SellingPrice__c,
            Sales_Order__r.SalesPriceExcludingADMwithDiscount__c,
            Sales_Order__r.Sales_Price_Excluding_ADM__c,
            Sales_Order__r.AmountPayable__c,
            Sales_Order__r.Amount_Payable_Excluding_ADM__c,
            Sales_Order__r.PaymentPlanDiscount__c,
            Sales_Order__r.PaymentPlan__c,
            Sales_Order__r.PaymentPlan__r.Name,
            Sales_Order__r.BulkDiscount__c,
            Sales_Order__r.Management_Discount__c,
            Sales_Order__r.Discount__c,
            Sales_Order__r.CorporateDiscount__c,
            Sales_Order__r.BookingDate__c,Permit_To_Date__c,
            Sales_Order__r.OwnerSharePercentage__c,
            Sales_Order__r.Opportunity__r.BrokerAgencyAccount__c,
            Owner.Phone,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c,
            Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c,
            IssuesWithFinancialDocument__c, FinancialDocumentAvailableInSF__c, DocumentUploadedFromSAP__c, LPFWaiverRequestApprovalStatus__c,
            ADMTotalFees__c,ADMFees__c,ADMAdminFees__c,EvaluationFees__c,MortgageRegistrationFees__c,PercentToBeSettled__c,CustomerPaidPercentage__c,BillingToCompleteAmount__c,
            ProjectStatus__c, RegistrationStatus__c, TypeOfResale__c,ResaleSubCategory__c,Unit__r.Project__r.City__c,BuyerNameInArabic__c,
            DefaultCustomerPaymentOverdueDate__c, Unit__r.Legal_Status__c,TotalCollection__c,ResaleToCompleteAmount__c, EarlySettlement__c
                               FROM Case 
                               WHERE Sales_Order__c =: salesOrderId 
                               AND RecordTypeId IN :recordTypeIds AND Status =: status LIMIT 1];
        return caseList;
    }

    public List<Case> getCasesNVehicleParkingDetailsByIds(Set<Id> caseIds){
         return [SELECT Id,CaseNumber,
                (SELECT Id,Name,VehicleMakeModel__c,VehiclePlateNumber__c,Unit__c FROM VehicleParkingDetails__r)
                FROM Case WHERE Id IN :caseIds];
         
     }
    
    public Case insertCase(Case objCase){
        if(objCase != NULL ){
            objCase = insertCases(new List<Case>{objCase})[0];
        }
        return objCase;
    }
    
    public List<Case> insertCases(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            insert caseList;
        }
        return caseList;
    }
    public List<Case> getNonLegalCases(List<Case> caseList){
        List<Case> nonLegalCases = new List<Case>();
        for(Case caseObj : caseList){
            if(caseObj.Unit__r.Legal_Status__c != 'With Legal'){
                nonLegalCases.add(caseObj);
            }
        }
        return nonLegalCases;
        
    }
    
    public List<Case> updateCasesWithoutTrigger(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            CaseTriggerHandler.isTriggerDisabled = true;
            update caseList;
            CaseTriggerHandler.isTriggerDisabled = false;
        }
        return caseList;
    }
    
    public List<CaseInstallment__c> getCaseInstallmentByRecordId (String recordId){
        List<CaseInstallment__c> caseInstallmentLines = [SELECT Id, NewInstallmentDate__c,Installment__r.id, Case__r.Sales_Order__c, Name,InstallmentAmount__c 
                                                         FROM CaseInstallment__c 
                                                         WHERE Case__c = :recordId 
                                                         AND NewInstallmentDate__c != NULL];
        return caseInstallmentLines;
    } 
    
    //Insert Case without trigger
    public List<Case> insertCaseWithoutTrigger(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            CaseTriggerHandler.isTriggerDisabled = true;
            insert caseList;
            CaseTriggerHandler.isTriggerDisabled = false;
        }
        return caseList;
    } 
    
    //Insert Case with trigger
    public List<Case> insertCaseWithTrigger(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            insert caseList;
        }
        return caseList;
    } 
    //Insert Case with trigger
    public Case insertCaseWithoutTrigger(Case caseObj){
        if(caseObj != NULL){
            CaseTriggerHandler.isTriggerDisabled = true;
            
        }
        return caseObj;
    } 
    
    //Update Case without trigger
    public List<Case> updateCaseWithoutTrigger(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            CaseTriggerHandler.isTriggerDisabled = true;
            update caseList;
            CaseTriggerHandler.isTriggerDisabled = false;
        }
        return caseList;
    }    
    
    //Update Case with trigger
    public List<Case> updateUnits(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            update caseList;
        }
        return caseList;
    } 
    
    //get Case list by set ids
    public List<Case> getCasesByIds(Set<Id> casetSetIds){
        if(!casetSetIds.isEmpty() && casetSetIds.size() > 0){
            return [SELECT Id,deviceRegistrationId__c, Work_Order__c, CaseNumber, SuppliedName, OwnerId, Owner.Email, Owner.Name, Project__c, Project__r.Name, Subject, ClosedDate, Status, Account__c, Account_Email__c, Account__r.Name, Closure_Reason__c, Closure_Comment__c, SuppliedEmail, Resolution_Comments__c FROM Case WHERE Id IN: casetSetIds];//Pending_With__c  ,Junk_Email__c
        } 
        return null;
    }
    //get Case list by set ids & createdByIds
    public List<Case> getCasesByCreatedByIds(Set<Id> casetSetIds, List<Id> createdByProfileIds){
        if(!casetSetIds.isEmpty() && casetSetIds.size() > 0){
            return [SELECT Id, Projectname__c, deviceRegistrationId__c,Work_Order__c,RoundRobinNumber__c, Project__c, CaseNumber, SuppliedName, OwnerId, Owner.Email, Owner.Name, Project__r.Name, Subject, ClosedDate, Status, Account__c, Account_Email__c, Account__r.Name, Closure_Reason__c, Closure_Comment__c, SuppliedEmail, Resolution_Comments__c FROM Case WHERE Id IN: casetSetIds AND CreatedBy.ProfileId IN:createdByProfileIds];  //Pending_With__c,Junk_Email__c    
        } 
        return null;
    }
    
    // public List<Case> getCaseByIdsAndCreatedByIds(Set<Id> caseIds, Set<Id> createdByIds){
    //     return [SELECT Id, Work_Order__c,RoundRobinNumber__c, Project__c, CaseNumber, 
    //             SuppliedName, OwnerId, Owner.Email, Owner.Name, Project__r.Name, Subject, 
    //             ClosedDate, Status, Account__c, Account_Email__c, Account__r.Name, 
    //             Closure_Reason__c, Closure_Comment__c, SuppliedEmail, Resolution_Comments__c 
    //             FROM Case WHERE Id IN: caseIds AND CreatedById IN:createdByIds];
    // }
    
    //get Case list by case list ids
    public List<Case> getCasesByCaseIds(List<Case> caseIds){
        if(!caseIds.isEmpty() && caseIds.size() > 0){
            return [SELECT Id, deviceRegistrationId__c,Account__r.personEmail,Work_Order__c, CaseNumber,user__c,user__r.Email__c, SuppliedName, OwnerId, Owner.Email, Owner.Name, Project__r.Name, Subject, ClosedDate, Status, Account__c, Account_Email__c, Account__r.Name, Closure_Reason__c, Closure_Comment__c, SuppliedEmail, Project__c, Resolution_Comments__c,Account.PersonEmail FROM Case WHERE Id IN: caseIds];//Pending_With__c,Junk_Email__c         
        } 
        return null;
    }

    public Case getCaseRecordWithDocuments(String caseId){ 
        return [SELECT Project__c,deviceRegistrationId__c,NumberOfPets__c,Unit__r.Is_Lease_Hold__c,Unit__r.Status__c,Account.PersonEmail,Move_Out_Date__c,Operator_Name__c,Operator_Office_Number__c,Operator_License_Number__c,Recordtype.name,Representative_Email__c,AccountId,Representative_Name__c,(select id,Account__c from Customer_Documents__r),CaseNumber,PhoneNumber__c,Operator_license_Exp_Dtae__c,User_Type__c,Unit__c,Representative_Contact_Number__c,Account.Azure_UserPrincipal_Id__c,Service_Catalog__r.Name,Last_Name__c,First_Name__c,Unit__r.Name,Email_Address__c,Id,Contacts_Case_Email__c, Status,EJARI_Tawteeq_start_date__c,EJARI_Tawteeq_end_date__c,Move_In_Date__c,Emirates_ID_expiry_date__c,Emergency_contact_01__c,Emergency_contact_02__c,Mobile_Number__c,Nationality__c,Occupant_with_special_needs__c,Special_Needs_Comments__c,Total_Number_of_Adults_Occupants__c,Total_Number_of_Child_Occupants__c,EJARI_Tawteeq_number__c,Emirates_ID_number__c FROM Case WHERE Id = :caseId LIMIT 1];
    }
    
    public List<Case> getExistingServiceCase(String email,String moveInrecordTypeId,String unitId,List<string> status){
        return [select Project__c,deviceRegistrationId__c, CaseNumber,Request_Number__c from Case where (Email_Address__c=:email OR Representative_Email__c=:email)
                AND Unit__c=:unitId AND Status in:status AND recordTypeId=:moveInrecordTypeId];
    }
    public List<Case> getrelatedCaseToAccount(String accountId){
        return [select Project__c, casenumber,Status,User_Type__c,Service_Catalog__r.Name,CreatedDate,Request_Number__c,Permit_From_Date__c,Permit_To_Date__c from case where accountid=:accountId];
    }
    
    public Case updateCase(Case request){    
        if(request != NULL ){
            update request;
        }
        return request;
    }
    
    public List<Case> updateCases(List<Case> caseList){ 
        if(caseList != NULL && !caseList.isEmpty()){
            update caseList;
        }
        return caseList; 
    }
    
    public Case updateAndReturnCase(Case caseObj){
        return updateCases(new List<Case>{caseObj})[0];
    }
    
    public case lstgetCaseRelatedtoSR(id SrID){
        Case caseRecord = [select CaseNumber,User_Type__c,Request_Number__c,Project__c,Service_Catalog__c from Case where Id=:SrID];
        return caseRecord;
    }
    public List<Case> getRelatedCaseToAccount(String accountId, String filter) {
        String baseQuery = 'SELECT CaseNumber,AccessCardType__c, Status, User_Type__c, Service_Catalog__r.Name, CreatedDate, Is_Favorite_Request__c, Request_Number__c FROM Case WHERE AccountId = :accountId';
        
        if (filter != null && !String.isBlank(filter)) {
            baseQuery += filter;
        }
        // Execute the dynamic query
        List<Case> relatedCases = Database.query(baseQuery);
        
        return relatedCases;
    }   

     //mobile phase2 methods
    public List<Case> getAmenityBookingsByDate(Date selectedDate,Id amenityId){         
        return  [
            SELECT startTime__c, endTime__c
            FROM Case
            WHERE Amenities__c  = :amenityId
            AND Permit_From_Date__c	 = :selectedDate AND Status='Confirmed'
        ];
    }
    public List<Case> fetchAmenitySlotExist(Id amenityId,Date selectedDate,Time selectedTime){
         
        return  [
            SELECT Id
            FROM Case
            WHERE Amenities__c  = :amenityId
            AND Permit_From_Date__c  = :selectedDate
            AND startTime__c = :selectedTime AND Status='Confirmed'
            LIMIT 1
        ];
    }
    public List<Case> checkServicesByAccount(Id accountId,Date selectedDate){
         
        return  [
            SELECT Id
            FROM Case
            WHERE AccountId  = :accountId
            AND Permit_From_Date__c  = :selectedDate
            AND (Status='Confirmed' OR Status='Submitted') 
           
        ];
    }
    public List<Case> fetchAmenityByAccount(Id accountId,Boolean upcomingOnly){
        ServiceCatalogService scService = ServiceCatalogService.getInstance();
         Id scId = ServiceCatalogService.fetchServiceCatalogByName(BCAPP_Constants.AMENITIES)[0].Id;
         String query = 'SELECT Amenities__r.Name,Amenities__r.isPaid__c, CaseNumber, Permit_From_Date__c, startTime__c, endTime__c, Status ' +
               'FROM Case ' +
               'WHERE AccountId = :accountId AND Service_Catalog__c=:scId';

        if (upcomingOnly) {
            query += ' AND Permit_From_Date__c >= TODAY AND (Status = \'Confirmed\' OR Status = \'Submitted\')';
        }
        
        query += ' ORDER BY Permit_From_Date__c, startTime__c ASC';

        return Database.query(query);
    }
    
    public List<Case> fetchBookedAmenityByDateRange(Date startDt,Date endDt,String projectId,String amenityId){
        return [
            SELECT Permit_From_Date__c , startTime__c, endTime__c, Status,CaseNumber
            FROM Case
            WHERE Permit_From_Date__c >= :startDt AND Permit_From_Date__c <= :endDt
            AND  recordTypeId =:Utilities.getRecordTypeId('Case','Community General Service Request') AND (status='Submitted' OR status='Confirmed' OR status='Approved' OR status='Cancelled')
            AND Project__c = :projectId
            AND Amenities__c  = :amenityId
        ];
       
    }

    public List<Case> getActiveVehicleParkingRequest(Id accountId, Id unitId, String status){
        return [
            SELECT Id
            FROM Case
            WHERE AccountId = :accountId
            AND Unit__c = :unitId
            AND RecordType.DeveloperName = 'VehicleParkingRequest'
            AND Status =:status
        ];
    }
    
    public List<Case> getCasesByContactId(Id contactId) {
        return [
            SELECT Id, Description, Status, ApprovalStatus__c, ApprovalComments__c, RejectionComments__c,BrokerAgency__c,
            PhoneNumber__c, TradeLicenseExpiryDate__c, CommercialLicenseExpiryDate__c,
            IsVATRegistered__c, TaxRegistrationNumber__c, AccountNumber__c, CaseNumber,
            BankName__c, BankAddress__c, IBANNumber__c, SwiftCode__c, TypeofEstablishment__c, Mobile_Country_Code__c,
            ServiceCatalog__r.Category__c, ServiceCatalog__r.SubCategory__c, BrokerCommission__c, Broker_Agent__c, CreatedDate, Address1__c, Address2__c, VATUndertakingIssue_Date__c,
            NationalIDExpiryDate__c, PassportExpiryDate__c, BRN_RERA_Expiry_Date__c, Mobile_Number__c, Type
            FROM Case
            WHERE ContactId = :contactId AND RecordType.DeveloperName IN ('DelayedCommissionPayment','OtherServiceRequest','IncorrectCommissionAmount','Broker_Agency_Details_Update','BrokerAgentDetailsUpdate')
            ORDER BY CreatedDate DESC
        ];
    }
    public List<Case> getBloomAppCasesByCustomerId(Set<Id> customerIds, String origin){
        return [SELECT Id,CaseNumber,Sales_Order__c, Sales_Order__r.Unit__r.Name, Status, Case_Contact_Name__c,CreatedDate,LastModifiedDate,SubStatus__c,Description,Subject,ClosedDate  FROM Case WHERE Origin = :origin AND ContactId IN :customerIds];
    }
    //Rushikesh
    public List<Case> getCaseDetailsWithBrokerAppNumber(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return new List<Case>();
        }
        
        return [
            SELECT Id, CaseNumber, Type, SubType__c,StopEmailsToCustomer__c ,ApprovalStatus__c, BrokerContactRole__c,
                   Account.Name
            FROM Case
            WHERE Id IN :caseIds
        ];
    }
    //Bapp Get Cases MAP By Ids - Return MAP
    public Map<Id, Case> getCaseMapByIds(Set<Id> caseIds){
        if(caseIds.isEmpty()) return new Map<Id, Case>();
        
        return new Map<Id, Case>([
            SELECT Id, BrokerContactRole__c, Title__c, First_Name__c, MiddleName__c,
            Last_Name__c, PhoneNumber__c, Email_Address__c, NationalID__c,SubType__c,
            NationalIDExpiryDate__c, PassportNumber__c, PassportExpiryDate__c,
            DateOfBirth__c, Country__c, TypeofEstablishment__c, BRN_RERA_Number__c,
            BRN_RERA_Expiry_Date__c, AccountId, ShareHoldingPercentage__c,
            Designation__c, Mobile_Country_Code__c, ApprovalStatus__c, ContactId, 
            RecordTypeId, RecordType.DeveloperName, Subject
            FROM Case
            WHERE Id IN :caseIds
        ]);
    }
     public List<Case> getCaseBySalesOrderUnitAccountId(String salesOrderId,String unitId,String accId){
        return [SELECT Id, CaseNumber,RecordType.DeveloperName FROM Case WHERE Status NOT IN ('Closed', 'Cancelled') AND (Sales_Order__c =: salesOrderId OR Unit__c =: unitId) AND AccountId =: accId];
    }
      public List<Case> getCaseByAccountId(String accId){
        return [SELECT Id, CaseNumber,RecordType.DeveloperName FROM Case WHERE Status NOT IN ('Closed', 'Cancelled') AND AccountId =: accId];
    }
    public static Set<Id> getValidBrokerCaseIds(Set<Id> caseIds, String recordTypeDevName) {
        if (caseIds == null || caseIds.isEmpty()) {
            return new Set<Id>();
        }
        return new Map<Id, Case>([SELECT Id FROM Case WHERE Id IN :caseIds AND RecordType.DeveloperName = :recordTypeDevName]).keySet();
    }

    public List<Case> getBloomAppCasesByLeadId(Set<Id> leadIds, String origin){
        return [SELECT Id,CaseNumber,Sales_Order__c, Sales_Order__r.Unit__r.Name, Status, Case_Contact_Name__c,CreatedDate,LastModifiedDate,SubStatus__c,Description,Subject,ClosedDate  FROM Case WHERE Origin = :origin AND Lead__c IN :leadIds];
    }
}
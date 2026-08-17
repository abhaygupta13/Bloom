/*****************************************************************************************
Class       : ResaleEmailActionController
Author      : Sonali Sengar
Description : Class to send appropriate selected notification of Resale
Test Class  : ResaleEmailActionControllerTest
Created Date: 29 AUG 2025
*****************************************************************************************/

public with sharing class ResaleEmailActionController {
    private static final String MTD_BLOOM_CUSTOMER_SERVICE_OWE_ID { get { return 'BloomCustomerServiceOWEmailId'; } }
    private static final String MTD_CRM_TEAM_PROFILE_ID { get { return 'CRMTeamProfileId'; } }
    private static final string MTD_RESALE_COMPLETED_TD_TEMPLATE_ID { get { return 'CompletedTDResaleId'; } }
    private static final string MTD_RESALE_DXB_TEMPLATE_ID { get { return 'DXBResaleId'; } }
    private static final string MTD_RESALE_UNDERCONSTRUCTION_TEMPLATE_ID { get { return 'UnderConstructionResaleId'; } }
    private static final string MTD_RESALE_COMPLETED_REG_NOT_REG_TEMPLATE_ID { get { return 'CompletedRegNotRegResaleId'; } }
    private static final string MTD_RESALE_DOCUMENTS_REQUIRED_TEMPLATE_ID { get { return 'DocumentsRequiredId'; } }
    private static final string MTD_RESALE_APPOINTMENT_BOOKING_TEMPLATE_ID { get { return 'AppointmentBookingResaleId'; } }
    private static final string MTD_RESALE_COMPLETED_REG_NOT_REG_TEMPLATE_ID_WITH_FEES { get { return 'CompletedWithFeesResale'; } }
    
    @AuraEnabled(cacheable=true)
    public static String getCaseLegalStatus(Id caseId) {
        List<Case> caseList = [SELECT Unit__r.Legal_Status__c FROM Case WHERE Id = :caseId LIMIT 1];
        if(!caseList.isEmpty()){
            return caseList[0].Unit__r != null ? caseList[0].Unit__r.Legal_Status__c : null;   
        }
        else{
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplateInfo> getEmailTemplates() {
        MetadataService objMetadataService = MetadataService.getInstance();
        List<EmailTemplateInfo> templates = new List<EmailTemplateInfo>();
        Id resaleCompletedTdId = objMetadataService.getAppSettingTextValue(MTD_RESALE_COMPLETED_TD_TEMPLATE_ID);
        Id resaleDxbId = objMetadataService.getAppSettingTextValue(MTD_RESALE_DXB_TEMPLATE_ID);
        Id resaleUnderConstId = objMetadataService.getAppSettingTextValue(MTD_RESALE_UNDERCONSTRUCTION_TEMPLATE_ID);
        Id resaleCompletedRegNotRegId = objMetadataService.getAppSettingTextValue(MTD_RESALE_COMPLETED_REG_NOT_REG_TEMPLATE_ID);
        Id resaleDocumentRequiredId = objMetadataService.getAppSettingTextValue(MTD_RESALE_DOCUMENTS_REQUIRED_TEMPLATE_ID);
        Id resaleAppointmentBookingId = objMetadataService.getAppSettingTextValue(MTD_RESALE_APPOINTMENT_BOOKING_TEMPLATE_ID);
        Id resaleCompletedRegNotRegIdWithFees = objMetadataService.getAppSettingTextValue(MTD_RESALE_COMPLETED_REG_NOT_REG_TEMPLATE_ID_WITH_FEES);
        Set<Id> templateIds = new Set<Id>{resaleCompletedTdId, resaleDxbId, resaleUnderConstId, resaleCompletedRegNotRegId, resaleDocumentRequiredId, resaleAppointmentBookingId,resaleCompletedRegNotRegIdWithFees};
            for (EmailTemplate et : [
                SELECT Id, Name 
                FROM EmailTemplate 
                WHERE IsActive = TRUE 
                AND Id IN: templateIds
            ]) {
                templates.add(new EmailTemplateInfo(et.Id, et.Name));
            }
        return templates;
    }
    
    @AuraEnabled
    public static Map<String, String> getEmailBody(Id templateId, Id caseId) {
        UserService objUserService = UserService.getInstance();
        AccountService objAccountService = AccountService.getInstance();
        CaseService objCaseService = CaseService.getInstance();
        SalesOrderOtherChargesService objSOCService = SalesOrderOtherChargesService.getInstance();
        InstallmentLineService objILService = InstallmentLineService.getInstance();
        BankAccountService objBankAccountService = BankAccountService.getInstance();
        JointOwnerService objJointOwnerService = JointOwnerService.getInstance();
        EmailTemplate template = [SELECT Id, Subject, HtmlValue, Body 
                                  FROM EmailTemplate 
                                  WHERE Id = :templateId LIMIT 1];
        
        String emailBody = template.HtmlValue;
        String subject = template.Subject;
        if(caseId != null){
            Decimal aDMAdminFee = 0;
            Decimal chequeBounceFee = 0;
            Decimal latePaymentCharges = 0;
            String installmentsText = '';
            User objUser = objUserService.getUsersById(UserInfo.getUserId());
            Case objCase = objCaseService.getCaseById(caseId);
            String accountName = (objCase.AccountId != null ? objAccountService.getRelatedContactName(objCase.AccountId) : '');
            String accountName2 = (objCase.NewCustomerAccount__c != null ? objAccountService.getRelatedContactName(objCase.NewCustomerAccount__c) : '');
            String accountNameArabic = (objCase.AccountId != null ? objAccountService.getRelatedContactNameArabic(objCase.AccountId) : '');
            String accountName2Arabic = (objCase.NewCustomerAccount__c != null ? objAccountService.getRelatedContactNameArabic(objCase.NewCustomerAccount__c) : '');
            List<JointOwner__c> lstJointOwner = objJointOwnerService.fetchJointOwners(caseId);
            List<String> jointOwnerNames = new List<String>();
            List<String> jointOwnerNamesArabic = new List<String>();
            Decimal resaleValue = ((objCase.Sales_Order__r.NetAmount__c != null ? objCase.Sales_Order__r.NetAmount__c : 0) * (objCase.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c != null ? objCase.Unit__r.Project__r.ResaleEligibleAmoutPercentage__c : 0)) / 100;
            Decimal customerValue = ((objCase.Sales_Order__r.NetAmount__c != null ? objCase.Sales_Order__r.NetAmount__c : 0) * (objCase.CustomerPaidPercentage__c != null ? objCase.CustomerPaidPercentage__c : 0)) / 100;
            Decimal fullOutstandingAmount = resaleValue > customerValue ? resaleValue : customerValue;
            List<SalesOrderOtherCharges__c> lstSOCCharges = objSOCService.getSalesOrderChargesBySalesOrder(objCase.NewSalesOrder__c);
            for(SalesOrderOtherCharges__c objSOC : lstSOCCharges){
                if(objSOC.TypeOfCharge__c == 'Cheque Bounce Fee'){
                    chequeBounceFee += objSOC.Amount__c;
                }
                if(objSOC.TypeOfCharge__c == 'Late Payment Charges'){
                    latePaymentCharges += objSOC.Amount__c;
                }
            }
            List<BankAccount__c> lstBankAccount= objBankAccountService.getBankAccountByProjectIds('Escrow',objCase.Project__c);
            subject = subject.replace('[Project_Name]', objCase.Unit__r.Project__r.Name != null ? objCase.Unit__r.Project__r.Name : '');
            subject = subject.replace('[Unit_Number]', objCase.Sales_Order__r.Unit__r.Name != null ? objCase.Sales_Order__r.Unit__r.Name : '');
            List<InstallmentLines__c> lstInstallmentLines = objILService.getAllInstallmentLinesBySalesOrderandDueDate(new Set<Id>{objCase.NewSalesOrder__c});
            for(InstallmentLines__c objIL : lstInstallmentLines){
                installmentsText += '<b>- AED ' + objIL.InstallmentAmount__c.setScale(2).format() +
                    '</b> – on <b>' + objIL.Due_Date__c.format() + '</b><br/>';
            }
            if(objCase.TypeOfResale__c != 'Add/Del of Kin' && objCase.TypeOfResale__c != 'Addition/Deletion') {
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_TD_RESALE_REQUIRED_DOCS_BUYER</span>.*?<span style="display:none">END_COMPLETED_TD_RESALE_REQUIRED_DOCS_BUYER</span>','');
            }
            if(!(objCase.TypeOfResale__c == 'Add/Del of Kin' || objCase.TypeOfResale__c == 'Addition/Deletion')) {
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_UNDER_CONSTRUCTION_RESALE_NOTES_MASTER_BUYER</span>.*?<span style="display:none">END_UNDER_CONSTRUCTION_RESALE_NOTES_MASTER_BUYER</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_UNDER_CONSTRUCTION_RESALE_REQUIRED_DOCS_BUYER</span>.*?<span style="display:none">END_UNDER_CONSTRUCTION_RESALE_REQUIRED_DOCS_BUYER</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_UNDER_CONSTRUCTION_RESALE_NOTES_NOC2</span>.*?<span style="display:none">END_UNDER_CONSTRUCTION_RESALE_NOTES_NOC2</span>','');
                
            }
            if(objCase.Title_Deed_Issued__c == 'Yes') {
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_SPA</span>.*?<span style="display:none">END_DXB_RESALE_SPA</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_REQUIRED_DOCS_BUYER</span>.*?<span style="display:none">END_DXB_RESALE_REQUIRED_DOCS_BUYER</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_REQUIRED_PAYMENTS</span>.*?<span style="display:none">END_DXB_RESALE_REQUIRED_PAYMENTS</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_FULL_OUTSTANDING_AMOUNT</span>.*?<span style="display:none">END_DXB_RESALE_FULL_OUTSTANDING_AMOUNT</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_NOTES_TITLE_DEED_NOT_ISSUED</span>.*?<span style="display:none">END_DXB_RESALE_NOTES_TITLE_DEED_NOT_ISSUED</span>','');
            }
            if(objCase.Title_Deed_Issued__c == 'No' || String.isBlank(objCase.Title_Deed_Issued__c)) {
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_TITLE_DEED_COPY</span>.*?<span style="display:none">END_DXB_RESALE_TITLE_DEED_COPY</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_NOTES_TITLE_DEED</span>.*?<span style="display:none">END_DXB_RESALE_NOTES_TITLE_DEED</span>','');
            }
            if(!((objCase.Title_Deed_Issued__c == 'No' || String.isBlank(objCase.Title_Deed_Issued__c)) && objCase.TypeOfResale__c == 'Gifting')) {
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_NOTES_GIFTING</span>.*?<span style="display:none">END_DXB_RESALE_NOTES_GIFTING</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_DXB_RESALE_NOTES_POST_HANDOVER</span>.*?<span style="display:none">END_DXB_RESALE_NOTES_POST_HANDOVER</span>','');
            }
            if(!(objCase.TypeOfResale__c == 'Add/Del of Kin' || objCase.TypeOfResale__c == 'Gifting' || objCase.TypeOfResale__c == 'Addition/Deletion')){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_UNDER_CONSTRUCTION_RESALE_NOTES_NOC</span>.*?<span style="display:none">END_UNDER_CONSTRUCTION_RESALE_NOTES_NOC</span>','');  
            }
            if (!(objCase.RegistrationStatus__c == 'Registered' && objCase.TypeOfResale__c == 'Gifting')) {
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_NOTES_GIFTING</span>.*?<span style="display:none">END_COMPLETED_RESALE_NOTES_GIFTING</span>','');
            }
            if(objCase.TypeOfResale__c == 'Addition/Deletion'){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_NOTES_ADD_DEL</span>.*?<span style="display:none">END_COMPLETED_RESALE_NOTES_ADD_DEL</span>','');
            }
            if(objCase.TypeOfResale__c != 'Addition/Deletion'){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_NOTES_ADD_DEL_NAME</span>.*?<span style="display:none">END_COMPLETED_RESALE_NOTES_ADD_DEL_NAME</span>','');
            }
            if(objCase.TypeOfResale__c == 'Addition/Deletion' || objCase.TypeOfResale__c == 'Add/Del of Kin' || objCase.TypeOfResale__c == 'Gifting'){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_UNDER_CONSTRUCTION_RESALE_NOTES_GIFTING</span>.*?<span style="display:none">END_UNDER_CONSTRUCTION_RESALE_NOTES_GIFTING</span>','');
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_UNDER_CONSTRUCTION_RESALE_NOTES_POST_HANDOVER</span>.*?<span style="display:none">END_UNDER_CONSTRUCTION_RESALE_NOTES_POST_HANDOVER</span>','');
            }
            if(objCase.BouncedChequeFees__c == null || objCase.BouncedChequeFees__c <= 0){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_BOUNCED_CHEQUE_FEE</span>.*?<span style="display:none">END_BOUNCED_CHEQUE_FEE</span>','');
            }
            if(objCase.LatePaymentFees__c == null || objCase.LatePaymentFees__c <= 0){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_LATE_PAYMENT_FEE</span>.*?<span style="display:none">END_LATE_PAYMENT_FEE</span>','');
            }
            if(objCase.ADMFees__c <= 0){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_ADMFEE</span>.*?<span style="display:none">END_COMPLETED_RESALE_ADMFEE</span>','');
            }
            if(lstInstallmentLines.size() <= 0 || lstInstallmentLines.size() == null){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_TOTAL</span>.*?<span style="display:none">END_COMPLETED_RESALE_TOTAL</span>','');
            }
             if(objCase.ResaleToCompleteAmount__c <= 0 || objCase.ResaleToCompleteAmount__c == null){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_FULLAMOUNT</span>.*?<span style="display:none">END_COMPLETED_RESALE_FULLAMOUNT</span>','');
            }
             if(objCase.EvaluationFees__c <= 0 || objCase.EvaluationFees__c == null){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_COMPLETED_RESALE_EVALUATIONFEES</span>.*?<span style="display:none">END_COMPLETED_RESALE_EVALUATIONFEES</span>','');
            }
            if(objCase.CancellationFees__c <= 0 || objCase.CancellationFees__c == null){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_RESALE_CANCELLATION_FEES</span>.*?<span style="display:none">END_RESALE_CANCELLATION_FEES</span>','');
            }
               if(objCase.ADDCAmount__c <= 0 || objCase.ADDCAmount__c == null){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_ADDC_FEES</span>.*?<span style="display:none">END_ADDC_FEES</span>','');
            }
             if(objCase.ChequeWithWithdrawlFees__c <= 0 || objCase.ChequeWithWithdrawlFees__c == null){
                emailBody = emailBody.replaceAll('(?s)<span style="display:none">START_CHEQUE_WITHDRAWAL_FEES</span>.*?<span style="display:none">END_CHEQUE_WITHDRAWAL_FEES</span>','');
            }
            if (!lstJointOwner.isEmpty()) {
                for (JointOwner__c jo : lstJointOwner) {
                    // English full name
                    String firstName = jo.First_Name__c != null ? jo.First_Name__c.trim() : '';
                    String lastName = jo.Last_Name__c != null ? jo.Last_Name__c.trim() : '';
                    String fullName = String.isNotBlank(firstName + ' ' + lastName) ? (firstName + ' ' + lastName).trim() : '';
                    if (String.isNotBlank(fullName)) {
                        jointOwnerNames.add(fullName);
                    }
                    if (String.isNotBlank(jo.NameInArabic__c)) {
                        jointOwnerNamesArabic.add(jo.NameInArabic__c);
                    }
                }
            }
            String salutation;
            String arabicSalutation;
            String salutation1;
            String arabicSalutation1;
            
            List<String> allEnglishNames = new List<String>();
            
            if (String.isNotBlank(accountName)) allEnglishNames.add(accountName);
            if (!jointOwnerNames.isEmpty()) allEnglishNames.addAll(jointOwnerNames);
            if (String.isNotBlank(accountName2)) allEnglishNames.add(accountName2);            
            
            // Join all English names with " and "
            salutation = 'Dear ' + String.join(allEnglishNames, ' and '); 
            salutation1 = String.join(allEnglishNames, ' and ');
            // Build Arabic salutation
            List<String> allArabicNames = new List<String>();
            
            if (String.isNotBlank(accountNameArabic)) allArabicNames.add(accountNameArabic);
            if (!jointOwnerNamesArabic.isEmpty()) allArabicNames.addAll(jointOwnerNamesArabic);
            if (String.isNotBlank(accountName2Arabic)) allArabicNames.add(accountName2Arabic);
            
            // Join all Arabic names with " و "
            arabicSalutation = 'السيد/السيدة ' + String.join(allArabicNames, ' و ') + ' ،';
            arabicSalutation1 = String.join(allArabicNames, ' و ');
            emailBody = emailBody.replace('[Seller_Name]', salutation1 != null ? salutation1 : '');
            emailBody = emailBody.replace('[Seller_Name_Arabic]', arabicSalutation1 != null ? arabicSalutation1 : '');
            emailBody = emailBody.replace('[Agent_Name]', objUser.Name != null ? objUser.Name : '')
                .replace('[Agent_Name_Arabic]', objUser.Name_In_Arabic__c  != null ? objUser.Name_In_Arabic__c  : '')
                .replace('[Agent_Email_Address]', objUser.Email != null ? objUser.Email : '')
                .replace('[Agent_Contact_Number]', objUser.Phone != null ? objUser.Phone : '')
                .replace('Dear [Customer_Name1] and [Customer_Name2]', + salutation)
                .replace('السيد/السيدة [Customer_Name1] و [Customer_Name2] ،', arabicSalutation)
                .replace('[Customer_Name1]', accountName != null ? accountName : '')
                .replace('[Customer_Name2]', accountName2 != null ? accountName2 : '')
                .replace('[Unit_Number]', objCase.Sales_Order__r.Unit__r.Name != null ? objCase.Sales_Order__r.Unit__r.Name : '')
                .replace('[Project_Name]', objCase.Unit__r.Project__r.Name != null ? objCase.Unit__r.Project__r.Name : '')
                .replace('[ADM_Total_Fees]',(objCase.ADMTotalFees__c != null && objCase.ADMAdminFees__c != null) ? formatCurrency(objCase.ADMTotalFees__c + objCase.ADMAdminFees__c, 'AED') : '')
                .replace('[ADM_Fees]', objCase.ADMFees__c != null ? formatCurrency(objCase.ADMFees__c, 'AED') : '')
                .replace('[Admin_Fees]', objCase.ADMFees__c != null ? formatCurrency(objCase.ADMFees__c, 'AED') : '')
                .replace('[Evaluation_Fees]', objCase.EvaluationFees__c != null ? formatCurrency(objCase.EvaluationFees__c, 'AED') : '')
                .replace('[Mortgage_Registration_Fees]', objCase.MortgageRegistrationFees__c != null ? formatCurrency(objCase.MortgageRegistrationFees__c, 'AED') : '')
                .replace('[Bank_Name]', objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c != null ? objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c : '')
                .replace('[Account_Name]', objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c != null ? objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c : '')
                .replace('[Account_Number]', objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c != null ? objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c : '')
                .replace('[IBAN_Number]', objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c != null ? objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c : '')
                .replace('[SWIFT_Code]', objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c != null ? objCase.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c : '')
                .replace('[Amount]',  objCase.ADMFees__c != null ? formatCurrency(objCase.ADMFees__c, 'AED') : '0')
                .replace('[Fees]',  objCase.ADMTotalFees__c != null ? formatCurrency(objCase.ADMTotalFees__c, 'AED') : '0')
                .replace('[ADM_TOTAL_FEES]',  objCase.ADMTotalFees__c != null ? formatCurrency(objCase.ADMTotalFees__c, 'AED') : '0')
                .replace('[Evaluation_Fees]',  objCase.EvaluationFees__c != null ? formatCurrency(objCase.EvaluationFees__c, 'AED') : '0')
                .replace('[Mortgage_Registration_Fees]',  objCase.MortgageRegistrationFees__c != null ? formatCurrency(objCase.MortgageRegistrationFees__c, 'AED') : '0')
                .replace('[LPF_Amount]',  objCase.LatePaymentFees__c != null ? formatCurrency(objCase.LatePaymentFees__c, 'AED') : '0')
                .replace('[Bounced_Cheque_Fees_Amount]',  objCase.BouncedChequeFees__c != null ? formatCurrency(objCase.BouncedChequeFees__c, 'AED') : '0')
                .replace('[Total]',  objCase.ChequeWithWithdrawlFees__c != null && objCase.ChequeWithWithdrawlFees__c > 0 ? formatCurrency(objCase.ChequeWithWithdrawlFees__c, 'AED') : '0')
                .replace('[Full_Outstanding_Amount]',  objCase.ResaleToCompleteAmount__c != null ? formatCurrency(objCase.ResaleToCompleteAmount__c, 'AED') : '0')
                .replace('[Percentage_Outstanding_Amount]',  objCase.ResaleToCompleteAmount__c != null ? formatCurrency(objCase.ResaleToCompleteAmount__c, 'AED') : '0')
                .replace('[Buyer_Seller]', objCase.RegistrationStatus__c == 'Registered' && objCase.TypeOfResale__c == 'Gifting' ? 'Seller' : 'Buyer')
                .replace('[No_Of_PDCs]', lstInstallmentLines.size() > 0 ? String.valueOf(lstInstallmentLines.size()) : '0')
                .replace('[Account_Name_Outstanding]', lstBankAccount.size() > 0 ? lstBankAccount[0].BeneficiaryNameCorporate__c : '')
                .replace('[EscrowAccount_Name]', lstBankAccount.size() > 0 ? lstBankAccount[0].BeneficiaryNameCorporate__c : '')
                .replace('[CancellationFees__c]',  objCase.CancellationFees__c != null ? formatCurrency(objCase.CancellationFees__c, 'AED') : '0')
                .replace('[Installments]',  installmentsText != null ? installmentsText : null)
                .replace('[ADDC_Amount]',  objCase.ADDCAmount__c != null ? formatCurrency(objCase.ADDCAmount__c, 'AED') : '0')
                .replace('[Total_Calculated_Amount]',  objCase.TotalADMFees__c != null ? formatCurrency(objCase.TotalADMFees__c, 'AED') : '0')
                .replace('[No_of_Withdrawal_Cheques]',  objCase.No_of_Withdrawal_Cheques__c != null ? formatCurrency(objCase.No_of_Withdrawal_Cheques__c, 'AED') : '0')
                .replace('[Cheque_Withdrwal_with_fees]',  objCase.ChequeWithWithdrawlFees__c != null ? formatCurrency(objCase.ChequeWithWithdrawlFees__c, 'AED') : '0');
        }
        return new Map<String, String>{
            'subject' => subject,
                'body' => emailBody
                };
                    }
    
    @AuraEnabled
    public static void sendEmailUsingTemplate(Id caseId, String subject, String body, String toAddress, String ccAddress) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id bloomCustomerServiceOWEId = objMetadataService.getAppSettingTextValue(MTD_BLOOM_CUSTOMER_SERVICE_OWE_ID);
        Id crmTeamProfileId = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_PROFILE_ID);
        List<String> toAddresses = new List<String>();
        // Get Case Contact
        Case c = [SELECT Id, OwnerId, Owner.Email, ContactId, CRMAgent__c,CRMAgent__r.Email,Contacts_Case_Email__c,Account_Email__c FROM Case WHERE Id = :caseId LIMIT 1];
        
        if (String.isNotBlank(toAddress)) {
            toAddresses.addAll(toAddress.split('[,]', 0));
        }
        
        Id currentUserProfileId = UserInfo.getProfileId();
        String strCurrentUserProfileId = String.valueOf(currentUserProfileId).substring(0, 15);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Boolean isCrmTeam = (crmTeamProfileId == strCurrentUserProfileId);
        Id orgWideEmailId = isCrmTeam ? null : bloomCustomerServiceOWEId;
        
        if (c.ContactId != null) {
            email = objEmailService.getSingleEmailMessage(toAddresses,caseId,c.ContactId,subject,body,orgWideEmailId);
            email.setSaveAsActivity(true);
        } else {
            if (String.isNotBlank(c.Account_Email__c)) {
                toAddresses.add(c.Account_Email__c);
                System.debug(toAddresses);
            }
            email = objEmailService.getSingleEmailMessage(toAddresses,caseId,null,subject,body,orgWideEmailId);
        }
        
        // Add reply-to only when not CRM team
        if (!isCrmTeam && String.isNotBlank(c.CRMAgent__r.Email)) {
            email.setReplyTo(c.CRMAgent__r.Email);
        }
        
        if (String.isNotBlank(ccAddress)) {
            email.setCcAddresses(ccAddress.split('[,]', 0));
        }
        Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
    }
    
    public static String formatCurrency(Decimal value, String currencyCode) {
        if (value == null) {
            return ' 0.00';
        }
        return value.setScale(2).format();
    }
    
    public class EmailTemplateInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        
        public EmailTemplateInfo(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }
}
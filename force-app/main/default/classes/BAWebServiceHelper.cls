/***
Class       : BAWebServiceHelper
Author      : Biswajeet
Description : 
TestClass   : BAWebServiceHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/
public class BAWebServiceHelper {
    
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final String SUPER_APP_STR { get { return 'Super App'; } }
    private static final String SERVICE_REQUEST_STR { get { return 'Service Request'; } }
    private static final string SALES_ORDER_STATUS_BOOKED { get { return 'Booked'; } }
    private static final string SALES_ORDER_STATUS_RESERVED { get { return 'Reserved'; } }
    private static final string SALES_ORDER_STATUS_SOLD { get { return 'Sold'; } }
    
    private static BAWebServiceHelper instance;
    
    private BAWebServiceHelper() {
        
    }
    
    public static BAWebServiceHelper getInstance() { 
        if(instance == null) {
            instance = new BAWebServiceHelper();
        }
        return instance;
    }
    
    public Map<String, Object> getCustomerDetailsForRegistration(String emiratesId, string passportNumber, string nationality) {
        Map<String, Object> data = new Map<String, Object>();
        List<Account> accList = AccountService.getInstance().getPersonAccounts(emiratesId, passportNumber, nationality);
        
        if(accList == NULL || accList.isEmpty()){
            return data;
        }

        List<SalesOrder__c> soList  = SalesOrderService.getInstance().getMobileAppActiveSalesOrdersByAccountId(accList[0].Id);

        if(soList == NULL || soList.isEmpty()){
            return data;
        }
        data.put('first_name', accList[0].FirstName);
        data.put('middle_name', accList[0].MiddleName);
        data.put('last_name', accList[0].LastName);
        data.put('country_code', accList[0].PrimaryMobileCountryCode__pc);
        data.put('phone_number', accList[0].PrimaryMobilePhone__pc);
        data.put('email', accList[0].PersonEmail);
        data.put('customer_id', accList[0].PersonContactId);
        
        List<AppRegistration__c> objAppRegistrationList = AppRegistrationService.getInstance().getAppRegistrationByContactId(accList[0].PersonContactId);
        if(objAppRegistrationList != NULL && !objAppRegistrationList.isEmpty()){
            data.put('registration_status', objAppRegistrationList[0].Status__c);
            data.put('registration_id', objAppRegistrationList[0].Id);
        }
        return data;
    }
    
    public Map<String, Object> createAppRegistrationRequest(string customerId, string firstName, string middleName, 
                                                            string lastName, string emiratesId, string passportNumber,
                                                            String nationality, string phoneCountryCode, string mobileNumber,
                                                            string email, String deviceId, String registrationType, string documentType,
                                                            String otpEmailTxnId, String otpSMSTxnId) {
                                                                AppRegistrationService objAppRegistrationService = AppRegistrationService.getInstance();
                                                                DocumentService objDocumentService = DocumentService.getInstance();
                                                                
                                                                Map<String, Object> data = new Map<String, Object>();
                                                                if(String.isBlank(customerId) || !isOtpVerified(customerId, otpEmailTxnId, otpSMSTxnId, email, phoneCountryCode + mobileNumber) || !isValidCustomer(customerId)){
                                                                    return data;
                                                                }
                                                                AppRegistration__c objAppRegistration = objAppRegistrationService.getAppRegistration(customerId, firstName, middleName,
                                                                                                                                                     lastName, emiratesId, passportNumber,
                                                                                                                                                     nationality, phoneCountryCode, mobileNumber,
                                                                                                                                                     email, deviceId, registrationType);
                                                                objAppRegistration = objAppRegistrationService.insertAppRegistration(objAppRegistration);
                                                                List<Document__c> documentList = objDocumentService.getDocumentsByParentId(objAppRegistration.Id);
                                                                
                                                                List<Object> docList = new List<Object>();
                                                                for(Document__c objDocument :documentList){
                                                                    Map<String, Object> docData = new Map<String, Object>();
                                                                    docData.put('doc_id', objDocument.Id);
                                                                    docData.put('doc_type', objDocument.DocumentType__r.Type__c);
                                                                    docList.add(docData);
                                                                }
                                                                data.put('registration_id', objAppRegistration.Id);
                                                                data.put('documents', docList);
                                                                return data;
                                                            }
    
    public Boolean isOtpVerified(String customerId,String otpEmailTxnId,String otpSMSTxnId, String email, String mobileNumber) {

        Set<String> txnIds = new Set<String>();
        if (String.isNotBlank(otpEmailTxnId)) txnIds.add(otpEmailTxnId);
        if (String.isNotBlank(otpSMSTxnId)) txnIds.add(otpSMSTxnId);

        if (txnIds.isEmpty()) {
            return false;
        }

        List<OTP__c> otpList = OTPService.getInstance().getVerifiedOTP('Bloom App Registration', customerId, txnIds);
        
        Boolean emailVerified = false;
        Boolean smsVerified   = false;

        for (OTP__c otp : otpList) {
            if (String.isNotBlank(otpEmailTxnId) && otp.CommunicationType__c != null && otp.CommunicationType__c.contains('Email') && otp.Id == otpEmailTxnId && otp.Email__c == email) {
                emailVerified = true;
            }
            if (String.isNotBlank(otpSMSTxnId) && otp.CommunicationType__c != null && otp.CommunicationType__c.contains('SMS') && otp.Id == otpSMSTxnId && otp.PhoneNumber__c == mobileNumber) {
                smsVerified = true;
            }   
        }
        if ((String.isNotBlank(otpEmailTxnId) && !emailVerified) || (String.isNotBlank(otpSMSTxnId) && !smsVerified)){
            return false;
        }
        return true;
    }

    public Boolean isValidCustomer(String customerId){
        Contact con = ContactService.getInstance().getContactById(customerId);
        if(con == NULL ||  con.AccountId == NULL){
            return false;
        }
        List<SalesOrder__c> soList  = SalesOrderService.getInstance().getMobileAppActiveSalesOrdersByAccountId(con.AccountId);
        if(soList == NULL || soList.isEmpty()){
            return false;
        }
        return true;
    }

    public List<AppRegistration__c> getExistingAppRegistration(string emiratesId, string passportNumber, String nationality) {
        return AppRegistrationService.getInstance().getExistingAppRegistration(emiratesId, passportNumber, nationality);
    }
    
    public Map<String, Object> getAppRegistrationStatus(Id recordId) {
        Map<String, Object> data = new Map<String, Object>();
        AppRegistrationService objAppRegistrationService = AppRegistrationService.getInstance();
        List<AppRegistration__c> objAppRegistrationList = objAppRegistrationService.getAppRegistrationById(recordId);
        if(!objAppRegistrationList.isEmpty() && objAppRegistrationList != NULL){
            data.put('registration_id', objAppRegistrationList[0].Id);
            data.put('customer_id', objAppRegistrationList[0].Contact__c);
            if(objAppRegistrationList[0].Contact__r.Account.Owner__c){
                data.put('customer_type', 'Owner');
            }else{
                data.put('customer_type', 'Tenant');
            }
            data.put('device_id', objAppRegistrationList[0].DeviceId__c);
            data.put('registration_status', objAppRegistrationList[0].Status__c);
            data.put('last_updated', objAppRegistrationList[0].LastModifiedDate);
            data.put('mobile_verified', objAppRegistrationList[0].Contact__r.IsPrimaryMobileVerified__c);
            data.put('email_verified', objAppRegistrationList[0].Contact__r.IsPrimaryEmailVerified__c);
            data.put('remarks', 'Your application status is ' + objAppRegistrationList[0].Status__c);
        }
        return data;
    }
    
    public Map<String, Object> updateCustomer(Id customerId, string communicationType, String countryCode, String mobile, String email) {
        Map<String, Object> data = new Map<String, Object>();
        Contact con = new Contact(Id = customerId);
        CaseService objCaseService = CaseService.getInstance();
        if(communicationType == 'Secondary'){
            con.SecondaryMobileCountryCode__c = countryCode;
            con.SecondaryMobilePhone__c = mobile;
            con.SecondaryEmail__c = email;
        }else if(communicationType == 'Primary'){
            List<AppRegistration__c> appRegistrationRec = AppRegistrationService.getInstance().getAppRegistrationByContactId(customerId);
            if (String.isNotBlank(countryCode)) {
                con.PrimaryMobileCountryCode__c = countryCode;
            }

            if (String.isNotBlank(mobile)) {
                con.PrimaryMobilePhone__c = mobile;
                con.IsPrimaryMobileVerified__c = true;
            }
            if (String.isNotBlank(email)) {
                con.Email = email;
                con.IsPrimaryEmailVerified__c = true;
            }       
        }
        ContactService.getInstance().updateContacts(new List<Contact>{con});
        data.put('customer_id', customerId);
        return data;
    }
    
    public Map<String, Object> getMyProfile(String idType, String idValue) {
        Map<String, Object> data = new Map<String, Object>();
        List<Object> salesOrderDataList = new List<Object>();
        ContactService objContactService = ContactService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        List<Document__c> customerDocList = new List<Document__c>();
        Id individualAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        
        List<Contact> objContactList = new List<Contact>();
        if(idType == 'EID'){
            objContactList = objContactService.getContactByEmiratesId(idValue);
        }else if (idType == 'AB2CID'){
            objContactList = objContactService.getContactByActiveDirectoryId(idValue);
        }else if (idType == 'UAEPASS'){
            objContactList = objContactService.getContactByEmiratesId(idValue);
        }
        
        if(!objContactList.isEmpty()){
            Contact objContact = objContactList[0];
            if(individualAccountRecordTypeId == objContact.Account.RecordTypeId){
                customerDocList = objDocumentService.getAppDocumentsByParentId(objContact.AccountId);
            }else{
                customerDocList = objDocumentService.getAppDocumentsByParentId(objContact.Id);
            }
            List<AppRegistration__c> objAppRegistrationList = AppRegistrationService.getInstance().getAppRegistrationByContactId(objContact.Id);
            List<SalesOrder__c> salesOrderList = objSalesOrderService.getMobileAppActiveSalesOrdersByAccountId(objContact.AccountId);
            Set<Id> unitIds = new Set<Id>();
            for(SalesOrder__c objSalesOrder :salesOrderList){
                if(objSalesOrder.Unit__c != null){
                    unitIds.add(objSalesOrder.Unit__c);
                }
            }
            UnitService objUnitService = UnitService.getInstance();
            Map<Id, List<Document__c>> unitVsDocumentsMap = objUnitService.getUnitDocumentsByUnitIds(unitIds);

            for(SalesOrder__c objSalesOrder :salesOrderList){
                Map<String, Object> soData = new Map<String, Object>();
                soData.put('salesorder_id',objSalesOrder.Id);
                soData.put('unit_id',objSalesOrder.Unit__c);
                soData.put('unit_number',objSalesOrder.Unit__r.Name);
                soData.put('addressing_number',objSalesOrder.Unit__r.ADMAddressingNumber__c);
                soData.put('project_name',objSalesOrder.Unit__r.Project__r.Name);
                soData.put('buyer_name',objSalesOrder.Account__r.Name);
                soData.put('building_name',objSalesOrder.Unit__r.BuildingSectionName__r.Name);
                soData.put('amenities', String.isNotBlank(objSalesOrder.Unit__r.Project__r.Amenities__c) ? objSalesOrder.Unit__r.Project__r.Amenities__c.split(';') : new List<String>());
                soData.put('handover_complete', objSalesOrder.Handover_Date__c != NULL ? true : false);
                soData.put('latitude', objSalesOrder.Unit__r.Location__Latitude__s);
                soData.put('longitude', objSalesOrder.Unit__r.Location__Longitude__s);
                soData.put('total_area', objSalesOrder.Unit__r.SaleableArea__c);
                soData.put('number_of_bedrooms', objSalesOrder.Unit__r.NumberOfBedrooms__c);
                soData.put('number_of_bathrooms', objSalesOrder.Unit__r.NumberOfBathrooms__c);
                soData.put('handover_date', objSalesOrder.Handover_Date__c);
                soData.put('spa_status', objSalesOrder.SPA_Collection_Status__c);
                soData.put('total_price', objSalesOrder.NetAmount__c);
                if(objSalesOrder.NetAmount__c != NULL && objSalesOrder.Sales_Order_Cleared_Amount__c != NULL){
                    soData.put('outstanding_amount', objSalesOrder.NetAmount__c - objSalesOrder.Sales_Order_Cleared_Amount__c);
                }else{
                    soData.put('outstanding_amount', objSalesOrder.NetAmount__c);
                }
                soData.put('paid_amount', objSalesOrder.Sales_Order_Cleared_Amount__c);
                List<Object> jointOwnerDataList = new List<Object>();
                for(JointOwner__c objJO :objSalesOrder.Joint_OwnersSalesOrder__r){
                    Map<String, Object> joData = new Map<String, Object>();
                    joData.put('name', objJO.Account__r.Name);
                    joData.put('share', objJO.SharePercentage__c);
                    jointOwnerDataList.add(joData);
                }
                soData.put('joint_owners',jointOwnerDataList);
                List<Object> docDataList = new List<Object>();
                for(Document__c objDoc :objSalesOrder.Documents__r){
                    Map<String, Object> docData = new Map<String, Object>();
                    docData.put('name', objDoc.DocumentType__r.Type__c);
                    docData.put('docId', objDoc.ContentDocumentId__c);
                    docDataList.add(docData);
                }
                // Unit Documents
                if(unitVsDocumentsMap.containsKey(objSalesOrder.Unit__c)){
                    for(Document__c unitDoc : unitVsDocumentsMap.get(objSalesOrder.Unit__c)){
                        Map<String, Object> docData = new Map<String, Object>();
                        docData.put('name', unitDoc.DocumentType__r.Type__c);
                        docData.put('docId', unitDoc.ContentDocumentId__c);
                        docDataList.add(docData);
                    }
                }
                soData.put('documents', docDataList);
                salesOrderDataList.add(soData);
            }

            data.put('customer_id', objContact.Id);
            data.put('customer_number', objContact.UniqueIdentifierNumber__c);
            if(objAppRegistrationList != NULL && !objAppRegistrationList.isEmpty()){
                data.put('registration_status', objAppRegistrationList[0].Status__c);
            }else{
                data.put('registration_status', null);
            }
            data.put('full_name', objContact.Name);
            data.put('date_of_birth', objContact.Birthdate);
            data.put('nationality', objContact.Nationality__c);
            data.put('primary_email', objContact.Email);
            data.put('secondary_email', objContact.SecondaryEmail__c);
            data.put('tertiary_email', objContact.TertiaryEmail__c);
            data.put('primary_country_code', objContact.PrimaryMobileCountryCode__c);
            data.put('secondary_country_code', objContact.SecondaryMobileCountryCode__c);
            data.put('tertiary_country_code', objContact.TertiaryMobileCountryCode__c);
            data.put('primary_phone', objContact.PrimaryMobilePhone__c);
            data.put('secondary_phone', objContact.SecondaryMobilePhone__c);
            data.put('tertiary_phone', objContact.TertiaryMobilePhone__c);
            data.put('passport_number', objContact.PassportNumber__c);
            data.put('emairates_id', objContact.Emirates_Id__c); 
            
            List<Object> docDataList = new List<Object>();
            for(Document__c objDoc :customerDocList){
                Map<String, Object> docData = new Map<String, Object>();
                docData.put('name', objDoc.DocumentType__r.Type__c);
                docData.put('docId', objDoc.ContentDocumentId__c);
                docData.put('docName', objDoc.Document_Name__c);
                docDataList.add(docData);
            }
            data.put('documents', docDataList);
            data.put('units', salesOrderDataList);
        }
        return data;
    }
    
    public Map<String, Object> getSalesOrderInstallmentsAndOtherCharges(Id salesOrderId, Id customerId) {
        Map<String, Object> data = new Map<String, Object>();
        List<Object> installmentDataList = new List<Object>();
        List<Object> saleOrderOtherChargeDataList = new List<Object>();

        Contact con = ContactService.getInstance().getContactById(customerId);
        if(con == NULL ||  con.AccountId == NULL){
            return data;
        }
        Set<String> statuses = new Set<String>{SALES_ORDER_STATUS_BOOKED, SALES_ORDER_STATUS_RESERVED, SALES_ORDER_STATUS_SOLD};
        SalesOrder__c so  = SalesOrderService.getInstance().getSalesOrderById(salesOrderId);
        if(so == NULL || so.Account__c != con.AccountId || !statuses.contains(so.Status__c)){
            return data;
        }

        List<InstallmentLines__c> objInstallmentLines = InstallmentLineService.getInstance().getInstallmentLinesBySalesOrderId(salesOrderId);
        Map<Id,InstallmentLines__c> objInstallmentLinesWithAllocationsMap = new Map<Id,InstallmentLines__c>(InstallmentLineService.getInstance().getInstallmentLinesNAllocationBySalesOrderId(salesOrderId));
        List<SalesOrderOtherCharges__c> objSalesOrderOtherCharges = SalesOrderOtherChargesService.getInstance().getSalesOrderChargesBySalesOrderId(salesOrderId);
        for(InstallmentLines__c objInstallmentLine :objInstallmentLines){
            Map<String, Object> soData = new Map<String, Object>();
            soData.put('id',objInstallmentLine.Id);
            soData.put('installment_number',objInstallmentLine.InstallmentNumber__c );
            soData.put('type',objInstallmentLine.Type__c);
            soData.put('percentage',objInstallmentLine.InstallmentPercentage__c);
            soData.put('amount',objInstallmentLine.InstallmentAmount__c);
            soData.put('paid_amount',objInstallmentLine.AmountReceived__c);
            soData.put('due_amount',objInstallmentLine.PendingAmount__c);
            soData.put('due_date',objInstallmentLine.Due_Date__c);
            soData.put('status', objInstallmentLine.Status__c);
            Boolean hasCheque = (objInstallmentLinesWithAllocationsMap != null && objInstallmentLinesWithAllocationsMap.containsKey(objInstallmentLine.Id) && objInstallmentLinesWithAllocationsMap.get(objInstallmentLine.Id).Receipt_Allocations__r != null && !objInstallmentLinesWithAllocationsMap.get(objInstallmentLine.Id).Receipt_Allocations__r.isEmpty());
            soData.put('has_cheque', hasCheque);
            Boolean proformaEligible = false;
            if (objInstallmentLine.Due_Date__c != null && objInstallmentLine.Due_Date__c > Date.today().addDays(15)) {
                proformaEligible = true;
            }
            soData.put('proforma_eligible', proformaEligible);
            soData.put('has_invoice', (objInstallmentLine.Due_Date__c != null && objInstallmentLine.Due_Date__c < Date.today()));
            
            String primaryMid = objInstallmentLine.SalesOrder__r?.Unit__r?.BuildingSectionName__r?.Primary_Account_Installment__r?.SalesMID__c;
            String mid = primaryMid;

            if (objInstallmentLine.Type__c == 'Post Handover Installment') {
                mid = objInstallmentLine.SalesOrder__r?.Unit__r?.BuildingSectionName__r?.PHPPAccountInstallment__r?.SalesMID__c;
            }
            else if (objInstallmentLine.Type__c == 'Installment' || objInstallmentLine.Type__c == 'Down Payment' || objInstallmentLine.Type__c == 'Handover') {
                String virtualMid = objInstallmentLine.SalesOrder__r?.Unit__r?.VirtualAccountMID__c;
                mid = String.isNotBlank(virtualMid) ? virtualMid : primaryMid;
            }

            soData.put('mid',  mid);
            installmentDataList.add(soData);
        }
        
        for(SalesOrderOtherCharges__c objSalesOrderOtherCharge :objSalesOrderOtherCharges){
            Map<String, Object> soData = new Map<String, Object>();
            soData.put('id',objSalesOrderOtherCharge.Id);
            soData.put('type',objSalesOrderOtherCharge.TypeOfCharge__c);
            soData.put('amount',objSalesOrderOtherCharge.Amount__c);
            soData.put('paid_amount',objSalesOrderOtherCharge.AmountReceived__c);
            soData.put('due_amount',objSalesOrderOtherCharge.Amount__c);
            soData.put('due_date',objSalesOrderOtherCharge.Due_Date__c);
            soData.put('status', objSalesOrderOtherCharge.Status__c);
            soData.put('mid', objSalesOrderOtherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SalesMID__c);
            soData.put('has_invoice', (objSalesOrderOtherCharge.Due_Date__c != null && objSalesOrderOtherCharge.Due_Date__c < Date.today()));
            saleOrderOtherChargeDataList.add(soData);
        }
        data.put('salesorder_id', salesOrderId);
        data.put('customer_id', customerId);
        data.put('unit_id', (objInstallmentLines != null && !objInstallmentLines.isEmpty()) ? objInstallmentLines[0].SalesOrder__r.Unit__c : null);
        data.put('unit_number', (objInstallmentLines != null && !objInstallmentLines.isEmpty()) ? objInstallmentLines[0].SalesOrder__r.Unit__r.Name : '');
        data.put('revenue_MID', (objInstallmentLines != null && !objInstallmentLines.isEmpty()) ? objInstallmentLines[0].SalesOrder__r.Unit__r.Project__r.Company__r.RevenueMID__c : '');
        data.put('revenue_percent', (objInstallmentLines != null && !objInstallmentLines.isEmpty()) ? String.valueOf(objInstallmentLines[0].SalesOrder__r.Unit__r.Project__r.Company__r.RevenuePercentage__c)  : '');
        data.put('installments', installmentDataList);
        data.put('othercharges', saleOrderOtherChargeDataList);
        return data;
    }
    
    public Map<String, Object> downloadDocument(String documentType, Id parentId, Id customerId, Boolean sendAsEmail) {
        Map<String, Object> data = new Map<String, Object>();
        Id documentId;
        String documentName;
        String docExtnType;
        DocumentService objDocumentService = DocumentService.getInstance();
        ContentService objContentService = ContentService.getInstance();
        
        if(documentType == 'SALES_SOA'){
            SalesOrder__c objSO = SalesOrderService.getInstance().getSalesOrderById(parentId);
            if(objSO.Account__r.PersonContactId == customerId || objSO.Contact__c == customerId){
                documentName = 'SOA-' + objSO.Unit__r.Name + '.pdf';
                ContentVersion cv = DocumentGenerationPDFHandler.generateAndAttachDocument(parentId, null, documentType, documentName);
                docExtnType = 'pdf';
                documentId = cv.Id;
            }
        }else if(documentType == 'SALES_RECEIPT'){
            SalesOrder__c objSO = SalesOrderService.getInstance().getSalesOrderById(parentId);
            if(objSO.Account__r.PersonContactId == customerId || objSO.Contact__c == customerId){
                documentName = 'RECEIPT-' + objSO.Unit__r.Name + '.pdf';
                ContentVersion cv = DocumentGenerationPDFHandler.generateAndAttachDocument(parentId, null, documentType, documentName);
                docExtnType = 'pdf';
                documentId = cv.Id;
            }
        }else if(documentType == 'TITLE_DEED'){
            List<Document__c> docsList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Title Deed');
            if (!docsList.isEmpty()) {
                List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(new Set<Id>{docsList[0].ContentDocumentId__c});
                documentName =docsList[0].DocumentType__r.Type__c;
                documentId = docsList[0].Content_Version_Id__c;
                docExtnType = !cvList.isEmpty() ? cvList[0].FileType : '';
            }
        }else if(documentType == 'SPA'){
            List<Document__c> docsList = objDocumentService.getDocumentByParentIdAndType(parentId, 'SPA - Signed');
            if (!docsList.isEmpty()) {
                List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(new Set<Id>{docsList[0].ContentDocumentId__c});
                documentName =docsList[0].DocumentType__r.Type__c;
                documentId = docsList[0].Content_Version_Id__c;
                docExtnType = !cvList.isEmpty() ? cvList[0].FileType : '';
            }
        }else if(documentType == 'COMMUNITY_SOA'){
            
        }else if(documentType == 'COMMUNITY_RECEIPT'){
            
        }else if(documentType == 'PASSPORT'){
            List<Document__c> docsList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Passport');
            if (!docsList.isEmpty()) {
                List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(new Set<Id>{docsList[0].ContentDocumentId__c});
                documentName =docsList[0].DocumentType__r.Type__c;
                documentId = docsList[0].Content_Version_Id__c;
                docExtnType = !cvList.isEmpty() ? cvList[0].FileType : '';
            }
        }else if(documentType == 'EID_FRONT'){
            List<Document__c> docsList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Emirates ID Front');
            if (!docsList.isEmpty()) {
                List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(new Set<Id>{docsList[0].ContentDocumentId__c});
                documentName =docsList[0].DocumentType__r.Type__c;
                documentId = docsList[0].Content_Version_Id__c;
                docExtnType = !cvList.isEmpty() ? cvList[0].FileType : '';
            }      
        }else if(documentType == 'EID_BACK'){
            List<Document__c> docsList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Emirates ID Back');
            if (!docsList.isEmpty()) {
                List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(new Set<Id>{docsList[0].ContentDocumentId__c});
                documentName =docsList[0].DocumentType__r.Type__c;
                documentId = docsList[0].Content_Version_Id__c;
                docExtnType = !cvList.isEmpty() ? cvList[0].FileType : '';
            }
        }else if(documentType == 'SALES_INVOICE'){
            List<InstallmentLines__c> objInstallmentList = InstallmentLineService.getInstance().getInstallmentLinesByIds(new Set<Id>{parentId});
            InstallmentLines__c objInstallment = objInstallmentList != null && !objInstallmentList.isEmpty() ?  objInstallmentList[0] : null;
            if(objInstallment.SalesOrder__r.Account__r.PersonContactId == customerId || objInstallment.SalesOrder__r.Contact__c == customerId){
                documentName = 'SALES INVOICE' + objInstallment.SalesOrder__r.Unit__r.Name + '.pdf';
                ContentVersion cv = DocumentGenerationPDFHandler.generateAndAttachDocument(parentId, null, documentType, documentName);
                docExtnType = 'pdf';
                documentId = cv.Id;
            }
        }else if(documentType == 'SALES_PORFORMA_INVOICE'){
            List<InstallmentLines__c> objInstallmentList = InstallmentLineService.getInstance().getInstallmentLinesByIds(new Set<Id>{parentId});
            InstallmentLines__c objInstallment = objInstallmentList != null && !objInstallmentList.isEmpty() ?  objInstallmentList[0] : null;
            if(objInstallment.SalesOrder__r.Account__r.PersonContactId == customerId || objInstallment.SalesOrder__r.Contact__c == customerId){
                documentName = 'PORFORMA INVOICE' + objInstallment.SalesOrder__r.Unit__r.Name + '.pdf';
                ContentVersion cv = DocumentGenerationPDFHandler.generateAndAttachDocument(parentId, null, documentType, documentName);
                docExtnType = 'pdf';
                documentId = cv.Id;
            }
        }else if(documentType == 'FLOOR_PLAN'){
            List<Document__c> docsList = objDocumentService.getDocumentBasedonType(parentId, 'Floor Plan');
            if (!docsList.isEmpty()) {
                List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(new Set<Id>{docsList[0].ContentDocumentId__c});
                documentName =docsList[0].Document_Name__c;
                documentId = docsList[0].Content_Version_Id__c;
                docExtnType = !cvList.isEmpty() ? cvList[0].FileType : '';
            }
        }
        data.put('doc_name', documentName);
        data.put('doc_id', documentId);
        data.put('doc_type', docExtnType);
        return data;
    }
    
    public Map<String, Object> uploadDocument(String documentType, Id parentId, Id customerId) {
        Map<String, Object> data = new Map<String, Object>();
        Id documentId;
        DocumentService objDocumentService = DocumentService.getInstance();
        ContactService objContactService = ContactService.getInstance();
        List<Document__c> objDocumentList = new List<Document__c>();
        
        if(documentType == 'PASSPORT'){
            List<Contact> conList = objContactService.getContactByIds(new List<Id>{customerId});
            if(!conList.isEmpty()){
                objDocumentList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Passport');
            }
        }else if(documentType == 'EID_FRONT'){
            List<Contact> conList = objContactService.getContactByIds(new List<Id>{customerId});
            if(!conList.isEmpty()){
                objDocumentList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Emirates ID Front');
            }
        }else if(documentType == 'EID_BACK'){
            List<Contact> conList = objContactService.getContactByIds(new List<Id>{customerId});
            if(!conList.isEmpty()){
                objDocumentList = objDocumentService.getDocumentByParentIdAndType(parentId, 'Emirates ID Back');
            }
        }
        if(!objDocumentList.isEmpty()){
            data.put('doc_id', objDocumentList[0].Id);
        }else {
            data.put('doc_id', null);
        }
        return data;
    }
    
    public Map<String, Object> sendOTP(String processType, String email, String mobile, string commType, String parentId) {
        Map<String, Object> data = new Map<String, Object>();
        OTPHandler objOTPHandler = OTPHandler.getInstance();
        OTP__c objOTP = objOTPHandler.generateSuperAppOTP(processType, email, mobile, commType, parentId);
        data.put('transactionId', objOTP.Id);
        return data;
    }
    
    public Map<String, Object> getListValues(String lisType) {
        Map<String, Object> data = new Map<String, Object>();
        ServiceCatalogService objServiceCatalogService = ServiceCatalogService.getInstance();
        if(lisType == 'SERVICE_REQUEST_LIST'){
            List<ServiceCatalog__c> bloomAppServiceCatalogList = objServiceCatalogService.getServiceCatalogForBloomApp();
            
            List<Object> serviceCatalogList = new List<Object>();
            for(ServiceCatalog__c objServiceCatlog :bloomAppServiceCatalogList){
                List<String> nameList = new List<String>();
                if (String.isNotBlank(objServiceCatlog.SuperAppName__c)) {
                    nameList = objServiceCatlog.SuperAppName__c.split(','); 
                }
                Map<String, Object> docData = new Map<String, Object>();
                for (String nameValue : nameList) {
                    Map<String, Object> objMap = new Map<String, Object>();
                    objMap.put('Id', objServiceCatlog.Id);
                    objMap.put('Name', nameValue);
                    serviceCatalogList.add(objMap);
                }
            }
            data.put('serviceRequestTypes', serviceCatalogList);
        }
        return data;
    }
    
    public Map<String, Object> getSRs(Id customerId) {
        Map<String, Object> data = new Map<String, Object>();
        CaseService objCaseService = CaseService.getInstance();
        List<Case> objCaseList = objCaseService.getBloomAppCasesByCustomerId(new Set<Id>{customerId}, SUPER_APP_STR);
        List<Object> serviceRequestList = new List<Object>();
        for (Case caseObj : objCaseList) {
            Map<String, Object> objMap = new Map<String, Object>();
            objMap.put('Id', caseObj.Id);
            objMap.put('caseNumber', caseObj.CaseNumber);
            objMap.put('salesOrder', caseObj.Sales_Order__c);
            objMap.put('unitName', caseObj.Sales_Order__r.Unit__r.Name);
            objMap.put('status', caseObj.Status);
            objMap.put('substatus', caseObj.SubStatus__c);
            objMap.put('description', caseObj.Description);
            objMap.put('subject', caseObj.Subject);
            objMap.put('created_on', caseObj.CreatedDate);
            objMap.put('last_updated_on', caseObj.LastModifiedDate);
            objMap.put('closed_on', caseObj.ClosedDate);
            serviceRequestList.add(objMap);
        }
        data.put('serviceRequests', serviceRequestList);
        return data;
    }
    
    public Map<String, Object> doCreateSR(String requestTypeId, String customerId, String parentId, String email, string mobileCountryCode, String mobile, String subject, String description) {
        Map<String, Object> data = new Map<String, Object>();
        ServiceCatalogService objServiceCatalogService = ServiceCatalogService.getInstance();
        ContactService objContactService = ContactService.getInstance();
        AccountService objAccountService = AccountService.getInstance();
        ServiceCatalog__c objServiceCatalog = objServiceCatalogService.getServiceCatalogById(requestTypeId);
        
        Case objCase = new Case();
        objCase.Origin = SUPER_APP_STR;
        objCase.ServiceCatalog__c = requestTypeId;
        objCase.RecordTypeId  = Utility.getRecordTypeIdByDevName(Case.SObjectType, objServiceCatalog.RecordTypeDevName__c);
        objCase.Subject = subject;
        objCase.Description = description;
        objCase.SuppliedEmail = email;
        objCase.SuppliedPhone = mobileCountryCode + mobile;
        objCase.CaseType__c = SERVICE_REQUEST_STR;
        
        List<Contact> conList = new List<Contact>();
        
        if(String.isNotBlank(customerId)){
            conList = objContactService.getContactByIds(new List<Id>{customerId});
            objCase.ContactId = customerId;
        }
        else if(String.isNotBlank(email)){
            conList = objContactService.getContactByEmail(new Set<String>{email});
            objCase.ContactId = conList[0].Id;
        }
        if(!conList.isEmpty() && conList[0].AccountId != null){
            objCase.AccountId = conList[0].AccountId;
            objCase.CustomerName__c = objAccountService.getRelatedContactName(conList[0].AccountId); 
        }
        
        
        if(String.isNotBlank(parentId)){
            objCase.Sales_Order__c = Id.valueOf(parentId).getSObjectType() == SalesOrder__c.SobjectType ? parentId : null;
            objCase.Unit__c = Id.valueOf(parentId).getSObjectType() == Unit__c.SobjectType ? parentId : null;
        }
        objCase = CaseService.getInstance().insertCase(objCase);
        data.put('srid', objCase.Id);
        data.put('srNumber', objCase.CaseNumber);
        return data;
    }
    
    public Map<String, Object> doPostSRFollowUp(Id customerId, Id srId, String remarks) {
        Map<String, Object> data = new Map<String, Object>();
        FollowUpService objFollowUpService = FollowUpService.getInstance();
        FollowUp__c objFollowUp = objFollowUpService.createFollowUpObj(srId, remarks);
        objFollowUpService.createFollowUp(objFollowUp);
        return data;
    }
    
    public Map<String, Object> verifyOTP(String parentId, string otp, String transactionId) {
        Map<String, Object> data = new Map<String, Object>();
        OTPHandler objOTPHandler = OTPHandler.getInstance();
        Boolean isValid = objOTPHandler.verifySuperAppOTP(parentId, otp, transactionId);
        data.put('isValid', isValid);
        return data;
    }
}
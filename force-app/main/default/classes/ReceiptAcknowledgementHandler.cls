/***
Class       : ReceiptAcknowledgementHandler
Author      : Smaartt
Description : 
TestClass   : ReceiptAcknowledgementHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0            31/07/23           Initial Version 
2.			V2.0			13/04/26		   Added methods and changes for On Account Receipts
****************************************************************************************************************/

public class ReceiptAcknowledgementHandler {
    private static final string MTD_TOR_CONDITION_TYPE_VALUE { get { return 'TransferOfRightsConditionType'; } }
    
    /*
    Get Current user profileName 
    */
    @AuraEnabled(cacheable=false)
    public static string fetchUserProfileName(){
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        Return PROFILE[0].Name;
    }
    
    /*
    * Get Installment & Sales Order Details by record Id
    */
    @AuraEnabled(cacheable=true)
    public static ReceiptAcknowlegment getDetailOfReceiptAcknowledgement(Id recordId){
        try {
            ReceiptAcknowlegment parentRecord ;
            MetadataService objMetadataService=MetadataService.getInstance();
            String conditionTypeValue = objMetadataService.getAppSettingTextValue(MTD_TOR_CONDITION_TYPE_VALUE);
            List<String> conditionTypeValueList = conditionTypeValue.split(',');
            if(recordId !=null){
                if(recordId.getSObjectType() == InstallmentLines__c.SObjectType){
                    InstallmentLines__c installmentLineRec = [SELECT Id,Installment_Type__c, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Cheque_from_Bank__c,SalesOrder__r.Account__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name, SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Unit__c ,SalesOrder__r.Name,SalesOrder__r.Contact__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c,
                                                              SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name,
                                                              SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name,Type__c,SAP_Condition_Type__c FROM InstallmentLines__c WHERE Id=:recordId];
                    if(conditionTypeValueList.contains(installmentLineRec.SAP_Condition_Type__c)){
                        parentRecord = new ReceiptAcknowlegment();
                        parentRecord.isRestricted = true;
                        parentRecord.restrictionMessage = 'Receipt Acknowledgement cannot be created because this installment has restricted condition type.';
                        return parentRecord;
                    }
                    parentRecord = new ReceiptAcknowlegment(installmentLineRec.PendingAmount__c,installmentLineRec.SalesOrder__r,installmentLineRec.InstallmentDate__c,'InstallmentLines__r');
                    parentRecord.installmentRec = installmentLineRec ;
                }
                else if(recordId.getSObjectType() == SalesOrderOtherCharges__c.SObjectType){
                    SalesOrderOtherCharges__c otherChargesRec = [SELECT Id, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Cheque_from_Bank__c,SalesOrder__r.Account__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c,
                                                                 SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name,
                                                                 SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name,SAP_Condition_Type__c FROM SalesOrderOtherCharges__c WHERE Id=:recordId];
                    if(conditionTypeValueList.contains(otherChargesRec.SAP_Condition_Type__c)){
                        parentRecord = new ReceiptAcknowlegment();
                        parentRecord.isRestricted = true;
                        parentRecord.restrictionMessage = 'Receipt Acknowledgement cannot be created because this record has restricted condition type.';
                        return parentRecord;
                    }
                    parentRecord = new ReceiptAcknowlegment(otherChargesRec.PendingAmount__c,otherChargesRec.SalesOrder__r,null,'SalesOrdersOtherCharges__r');
                    parentRecord.salesOrderOtherChargesRec = otherChargesRec ;
                }
                else if(recordId.getSObjectType() == SalesOrder__c.SObjectType){
                    SalesOrder__c objSalesOrder = [SELECT Id, Account__c, Opportunity__c,AccountName__c,Unit__c FROM SalesOrder__c WHERE Id =: recordId];
                    parentRecord = new ReceiptAcknowlegment(0,objSalesOrder,null,'SalesOrder__c');
                    
                    parentRecord.salesOrderRecord = objSalesOrder;
                }
                if(parentRecord!=null && parentRecord.salesOrderRecord !=null){
                    for(AccountRelationship__c acctRelationship : AccountService.getRelatedAccountsForAccountId(parentRecord.salesOrderRecord.Account__c)){
                        parentRecord.relatedAccounts.add(acctRelationship.RelatedAccount__r);
                    }
                }
            }          
            return parentRecord ; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<String> getRemitterNames(Id accountId){
        AccountService objAccountService = AccountService.getInstance();
        List<String> names = new List<String>();
        if (accountId == null) {	
            return names;
        }
        List<Account> lstAccount = objAccountService.getAccountWithJointOwner(accountId);
        
        // Primary Owner
        if (String.isNotBlank(lstAccount[0].Name)) {
            names.add(lstAccount[0].Name);
        }
        // Joint Owners
        if (lstAccount[0].Joint_Owners__r != null) {
            for (JointOwner__c jo : lstAccount[0].Joint_Owners__r) {
                String fullName = '';
                
                if (String.isNotBlank(jo.First_Name__c)) {
                    fullName = jo.First_Name__c;
                }
                
                if (String.isNotBlank(jo.Last_Name__c)) {
                    fullName = String.isBlank(fullName) ? jo.Last_Name__c : fullName + ' ' + jo.Last_Name__c;
                }
                
                if (String.isNotBlank(fullName)) {
                    names.add(fullName);
                }
            }
        }
        return names;
    }
    
    /*
* Get Installment & Sales Order Details by record Id
*/
    @AuraEnabled(cacheable=false)
    public static ReceiptAcknowledgement__c insertReceiptAcknowledgement(String base64, String filename,Document__c docRec,ReceiptAcknowledgement__c recieptRecord,Id parentRecord,String wrapperString,Boolean noAllocation){
        
        Savepoint savePoint = null ;
        try {
            ReceiptAcknowlegment receiptAcknowledgement;
            if(String.isNotBlank(wrapperString)){
                receiptAcknowledgement = (ReceiptAcknowlegment)JSON.deserialize(wrapperString, ReceiptAcknowlegment.class);
            }
            savePoint = Database.setSavepoint();
            insert recieptRecord ; 
            
            if(String.isNotBlank(base64) && String.isNotBlank(filename)){
                if (docRec != null && String.isNotBlank(base64) && String.isNotBlank(filename)) {
                    docRec.Receipt_Acknowledgement__c= recieptRecord.Id;
                    insert docRec;
                    
                    ContentVersion cv = createContentVersion(base64, filename);            
                    ContentDocumentLink cdl = createContentLink(cv.Id, docRec.Id);
                    docRec.Content_Version_Id__c= cv.id;
                    docRec.ContentDocumentId__c = cdl.ContentDocumentId;
                    update docRec;
                }
            }
            
            Decimal amountPending = 0 ;
            //--- Create Receipt Allocation
            System.debug(amountPending+'**Reciept Amount**'+recieptRecord.Amount__c);
            system.debug('parentRecord' + parentRecord);
            //Receipt allocation not required if paymentMode if Wire Transfer. 
            
            if(!noAllocation){
                if(recieptRecord.PaymentType__c != 'Wire Transfer' || fetchUserProfileName() == CONSTANTS.FINANCE_PROFILE ){
                    if(parentRecord !=null){
                        ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
                        if(parentRecord.getSObjectType() == InstallmentLines__c.SObjectType){
                            receiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT ;
                            receiptAllocation.InstallmentLine__c = parentRecord ;
                            amountPending = receiptAcknowledgement.installmentRec.PendingAmount__c ;
                        }
                        else{
                            receiptAllocation.TypeOfInvoice__c = [select id,TypeOfCharge__c from SalesOrderOtherCharges__c where id = :parentRecord].TypeOfCharge__c;
                            receiptAllocation.SalesOrderOtherCharges__c = parentRecord ;
                            amountPending = receiptAcknowledgement.salesOrderOtherChargesRec.PendingAmount__c ;
                        }
                        
                        if(amountPending >0){
                            receiptAllocation.ReceiptAcknowledgement__c = recieptRecord.Id ;
                            receiptAllocation.AmountApplied__c = (recieptRecord.Amount__c > amountPending ? amountPending : recieptRecord.Amount__c);
                            receiptAllocation.CurrencyIsoCode = recieptRecord.CurrencyIsoCode ;
                            receiptAllocation.DateOfApplication__c = Date.today();
                            receiptAllocation.Account__c = recieptRecord.Account__c ;
                            receiptAllocation.SalesOrder__c = recieptRecord.SalesOrder__c ;
                            insert receiptAllocation ;
                        }
                    }
                }
            }
            return recieptRecord ; 
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
            Database.rollback(savePoint); 
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.Origin = 'H';
        cv.PathOnClient = '/' + filename;
        
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    
    // used in file upload
    public static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;       
        cdl.ShareType = 'V';
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }
    
    public static List<ReceiptAcknowledgement__c> fetchAlldetailsofFields(List<Id> raIds) {
        
        Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(raFieldList);
        String fields = string.join(strList,',');
        
        Set<String> rallFieldList = Schema.getGlobalDescribe().get('ReceiptAllocation__c').getDescribe().fields.getMap().keySet();
        List<String> strRallList = new List<String>();
        strRallList.addAll(rallFieldList);
        String rallFields = string.join(strRallList,',');
        
        String raIdsStr = String.join(raIds, '\',\'');
        String query = 'SELECT ' + fields + ' , CreatedBy.Email, ChequeReceivedBy__r.Email, Account__r.Name, SalesOrder__r.Name, SalesOrder__r.PaymentPlan__c, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name, (SELECT ' + rallFields + ' , InstallmentLine__r.InstallmentNumber__c, InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.Installment_Type__c, Account__r.Name, SalesOrder__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name, SalesOrderOtherCharges__r.TypeOfCharge__c, SalesOrderOtherCharges__r.Amount__c FROM Receipt_Allocations__r) FROM ReceiptAcknowledgement__c WHERE Id IN (\'' + raIdsStr + '\')';
        List<ReceiptAcknowledgement__c> ReceiptAcknowledgements = Database.Query(query);
        return ReceiptAcknowledgements;
    }
    
    @AuraEnabled(cacheable=true)
    public static ReceiptAcknowlegment initialiseReceiptAcknowlegment(Id recordId){
        try {
            ReceiptAcknowlegment parentRecord ;
            
            if(recordId !=null){
                if(recordId.getSObjectType() == InstallmentLines__c.SObjectType){
                    InstallmentLines__c installmentLineRec = [SELECT Id, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,SalesOrder__r.Contact__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c FROM InstallmentLines__c WHERE Id=:recordId];
                    parentRecord = new ReceiptAcknowlegment(installmentLineRec.PendingAmount__c,installmentLineRec.SalesOrder__r,installmentLineRec.InstallmentDate__c,'InstallmentLines__r');
                    parentRecord.installmentRec = installmentLineRec ;
                }
                else if(recordId.getSObjectType() == SalesOrderOtherCharges__c.SObjectType){
                    SalesOrderOtherCharges__c otherChargesRec = [SELECT Id, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c FROM SalesOrderOtherCharges__c WHERE Id=:recordId];
                    parentRecord = new ReceiptAcknowlegment(otherChargesRec.PendingAmount__c,otherChargesRec.SalesOrder__r,null,'SalesOrdersOtherCharges__r');
                    parentRecord.salesOrderOtherChargesRec = otherChargesRec ;
                }
                
                if(parentRecord!=null && parentRecord.salesOrderRecord !=null){
                    for(AccountRelationship__c acctRelationship : AccountService.getRelatedAccountsForAccountId(parentRecord.salesOrderRecord.Account__c)){
                        parentRecord.relatedAccounts.add(acctRelationship.RelatedAccount__r);
                    }
                }
            }          
            return parentRecord ; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ReceiptAcknowlegment{
        @AuraEnabled
        public Decimal amount ;
        @AuraEnabled
        public SalesOrder__c salesOrderRecord ;
        @AuraEnabled
        public Date paymentDate ;
        @AuraEnabled
        public String objectName ;
        @AuraEnabled
        public Id salesOrderId ;
        @AuraEnabled
        public List<Account> relatedAccounts ;
        @AuraEnabled
        public InstallmentLines__c installmentRec ;
        @AuraEnabled
        public SalesOrderOtherCharges__c salesOrderOtherChargesRec ;
        @AuraEnabled
        public Boolean isRestricted = false;
		@AuraEnabled
        public String restrictionMessage;
        
        // Default constructor
        public ReceiptAcknowlegment(){
            this.relatedAccounts = new List<Account>();
            this.installmentRec = new InstallmentLines__c();
            this.salesOrderOtherChargesRec = new SalesOrderOtherCharges__c();
        }
        
        public ReceiptAcknowlegment(Decimal amount,SalesOrder__c salesOrderRecord,Date paymentDate,String objectName){
            this.amount = amount ;
            this.salesOrderRecord  = salesOrderRecord ;
            this.paymentDate = paymentDate ;
            this.objectName = objectName ;
            this.salesOrderId = salesOrderRecord.Id ;
            this.relatedAccounts = new List<Account>();
            this.installmentRec = new InstallmentLines__c();
            this.salesOrderOtherChargesRec = new SalesOrderOtherCharges__c();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<Id,String> getBankDetails(Id recordId){
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        SalesOrderOtherChargesService objSOCService = SalesOrderOtherChargesService.getInstance();
        BankAccountService objBankService = BankAccountService.getInstance();
        Map<Id,String> mapBankDetails = new Map<Id,String>();
        if(recordId !=null){
            if(recordId.getSObjectType() == InstallmentLines__c.SObjectType){
                InstallmentLines__c objIL = objInstallmentLineService.getInstallmentLinesByIdWithBank(recordId);
                if(objIL != null){
                    mapBankDetails.put(objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name);
                    mapBankDetails.put(objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name);
                    mapBankDetails.put(objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name);
                    mapBankDetails.put(objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name);
                    mapBankDetails.put(objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,objIL.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name);
                }
            }
            else if(recordId.getSObjectType() == SalesOrderOtherCharges__c.SObjectType){
                SalesOrderOtherCharges__c otherChargesRec = objSOCService.getSalesOrderChargesByIdWithBank(recordId);
                if(otherChargesRec != null){
                    mapBankDetails.put(otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name);
                    mapBankDetails.put(otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name);
                    mapBankDetails.put(otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name);
                    mapBankDetails.put(otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name);
                    mapBankDetails.put(otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,otherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name);
                }
            }
            List<BankAccount__c> lstBankApplicableForSales = objBankService.getBankAccountApplicableForSales();
            if(lstBankApplicableForSales.size() > 0){
                for(BankAccount__c objBank : lstBankApplicableForSales){
                    mapBankDetails.put(objBank.Id,objBank.Name);
                }
            }
        }
        return mapBankDetails;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Salesorder__c> getDetailOfInstallmentRecord(Id recordId,Integer overdueInDays,String invoiceTypes,Boolean acrossUnitsChecked,String installmentAccount){
        List<Salesorder__c> installmentLinesDetails = new List<Salesorder__c>();
        Date overDueDate;
        if(overDueDate!=null){
            overDueDate = date.today().addDays(overdueInDays);
        }
        if(recordId !=null && overdueInDays!=null  && invoiceTypes==null && acrossUnitsChecked==false){
            
            installmentLinesDetails = [select id ,(SELECT Id,Installment_Type__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c from InstallmentLines__r where InstallmentDate__c<=:overDueDate AND PendingAmount__c>0 ),(SELECT Id, AmountReceived__c,
                                                                                                                                                                                                                                                                                                                                    SalesOrder__c,Due_Date__c,
                                                                                                                                                                                                                                                                                                                                    SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c from SalesOrdersOtherCharges__r Where PendingAmount__c>0 AND Due_Date__c<=:overDueDate) from SalesOrder__c WHERE Id=:recordId];   
            return installmentLinesDetails;
        }else if(recordId !=null && overdueInDays==null && invoiceTypes!=null  && acrossUnitsChecked==false){
            
            installmentLinesDetails = [select id ,(SELECT Id,Installment_Type__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c from InstallmentLines__r where Installment_Type__c=:invoiceTypes AND PendingAmount__c>0 ),(SELECT Id, AmountReceived__c,
                                                                                                                                                                                                                                                                                                                                     SalesOrder__c,Due_Date__c,
                                                                                                                                                                                                                                                                                                                                     SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c from SalesOrdersOtherCharges__r Where PendingAmount__c>0 AND TypeOfCharge__c=:invoiceTypes) from SalesOrder__c WHERE Id=:recordId];   
            return installmentLinesDetails;
        }
        else if(recordId !=null && overdueInDays!=null && invoiceTypes!=null  && acrossUnitsChecked==false){
            
            installmentLinesDetails = [select id ,(SELECT Id,Installment_Type__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c from InstallmentLines__r where Installment_Type__c=:invoiceTypes AND PendingAmount__c>0  AND InstallmentDate__c<=:overDueDate),(SELECT Id, AmountReceived__c,
                                                                                                                                                                                                                                                                                                                                                                          SalesOrder__c,Due_Date__c,
                                                                                                                                                                                                                                                                                                                                                                          SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c from SalesOrdersOtherCharges__r Where PendingAmount__c>0 AND TypeOfCharge__c=:invoiceTypes  AND Due_Date__c<=:overDueDate) from SalesOrder__c WHERE Id=:recordId];   
            return installmentLinesDetails;
        }
        
        else if(acrossUnitsChecked==true && installmentAccount!=null && overdueInDays!=null  && invoiceTypes==null  ){
            installmentLinesDetails = [select id ,(SELECT Id,Installment_Type__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c from InstallmentLines__r where InstallmentDate__c<=:overDueDate AND PendingAmount__c>0 Order By InstallmentNumber__c ASC),(SELECT Id,AmountReceived__c,
                                                                                                                                                                                                                                                                                                                                                                     SalesOrder__c,Due_Date__c,
                                                                                                                                                                                                                                                                                                                                                                     SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c from SalesOrdersOtherCharges__r where PendingAmount__c>0 AND Due_Date__c<=:overDueDate ) from SalesOrder__c  Where Account__c=:installmentAccount];   
            return installmentLinesDetails;
        }
        else if(acrossUnitsChecked==true && installmentAccount!=null && overdueInDays==null  && invoiceTypes!=null  ){
            installmentLinesDetails = [select id ,(SELECT Id,Installment_Type__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c from InstallmentLines__r where Installment_Type__c=:invoiceTypes AND PendingAmount__c>0 Order By InstallmentNumber__c ASC),(SELECT Id,AmountReceived__c,
                                                                                                                                                                                                                                                                                                                                                                      SalesOrder__c,Due_Date__c,
                                                                                                                                                                                                                                                                                                                                                                      SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c from SalesOrdersOtherCharges__r where PendingAmount__c>0 AND TypeOfCharge__c=:invoiceTypes ) from SalesOrder__c  Where Account__c=:installmentAccount];   
            return installmentLinesDetails;
        }
        else if(acrossUnitsChecked==true && installmentAccount!=null && overdueInDays!=null  && invoiceTypes!=null  ){
            installmentLinesDetails = [select id ,(SELECT Id,Installment_Type__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c from InstallmentLines__r where Installment_Type__c=:invoiceTypes AND PendingAmount__c>0 AND InstallmentDate__c<=:overDueDate Order By InstallmentNumber__c ASC),(SELECT Id,AmountReceived__c,
                                                                                                                                                                                                                                                                                                                                                                                                           SalesOrder__c,Due_Date__c,
                                                                                                                                                                                                                                                                                                                                                                                                           SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c from SalesOrdersOtherCharges__r where PendingAmount__c>0 AND TypeOfCharge__c=:invoiceTypes AND Due_Date__c<=:overDueDate ) from SalesOrder__c  Where Account__c=:installmentAccount];   
            return installmentLinesDetails;
        }
        return null; 
    }
    
    @AuraEnabled(cacheable=false)
    public static void insertAllocatedReceiptWthAmt(List<InstallmentLines__c> updateInstallment,ReceiptAcknowledgement__c recpAck,List<SalesOrderOtherCharges__c>updateSalesorderOOther){
        Decimal amountPending = 0 ;
        List<ReceiptAllocation__c> recpAlc = new List<ReceiptAllocation__c>();
        
        if( recpAck!=null){
            insert  recpAck;
        }
        
        if(recpAck.PaymentType__c != 'Wire Transfer'){
            for(InstallmentLines__c ins:updateInstallment){
                ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
                receiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT ; 
                receiptAllocation.ReceiptAcknowledgement__c = recpAck.Id ;
                receiptAllocation.AmountApplied__c = ins.AmountReceived__c;
                receiptAllocation.CurrencyIsoCode = recpAck.CurrencyIsoCode ;
                receiptAllocation.DateOfApplication__c = Date.today();
                receiptAllocation.Account__c = recpAck.Account__c ;
                receiptAllocation.SalesOrder__c = recpAck.SalesOrder__c ;
                receiptAllocation.InstallmentLine__c =ins.id;
                // receiptAllocation.AmountApplied__c=  ins.AmountReceived__c ;
                recpAlc.add(receiptAllocation);
            }
            for(SalesOrderOtherCharges__c sOOth: updateSalesorderOOther){
                ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
                receiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT ; 
                receiptAllocation.ReceiptAcknowledgement__c = recpAck.Id ;
                receiptAllocation.AmountApplied__c = sOOth.AmountReceived__c;
                receiptAllocation.CurrencyIsoCode = recpAck.CurrencyIsoCode ;
                receiptAllocation.DateOfApplication__c = Date.today();
                receiptAllocation.Account__c = recpAck.Account__c ;
                receiptAllocation.SalesOrder__c = recpAck.SalesOrder__c ;
                receiptAllocation.SalesOrderOtherCharges__c =sOOth.id;
                // receiptAllocation.AmountApplied__c=  ins.AmountReceived__c ;
                recpAlc.add(receiptAllocation);  
            }
        }
        if(recpAlc.size()>0){
            insert recpAlc;
        }
        if(updateInstallment.size()>0){
            update updateInstallment;
        }
        if(updateSalesorderOOther.size()>0){
            update updateSalesorderOOther;
        }
    } 
}
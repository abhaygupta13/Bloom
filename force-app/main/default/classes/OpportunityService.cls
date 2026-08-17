/***
Class       : OpportunityService
Author      : Smaartt
Description : 

TestClass   : OpportunityServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/28/23           Initial Version 
****************************************************************************************************************/


public class OpportunityService {
    
    private static OpportunityService instance;
    
    private OpportunityService() {
        
    }
    
    public static OpportunityService getInstance() { 
        if(instance == null) {
            instance = new OpportunityService();
        }
        return instance;
    }
    
    @AuraEnabled(cacheable=false)
    public static void updateOpportunityStage(String opportunityId, String eventSubject){
        Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.Id = opportunityId;
        if (eventSubject.toLowerCase().contains(Constants.SALES_OFFER.toLowerCase())) {
            opportunityRecord.StageName= Constants.STAGE_PROPOSAL;
        } else if (eventSubject.toLowerCase().contains(Constants.MEETING.toLowerCase())) {
            opportunityRecord.StageName= Constants.MEETING;
        } else if (eventSubject.toLowerCase().contains(Constants.CLOSEDWON.toLowerCase())) {
            opportunityRecord.StageName= Constants.STAGE_CLOSEDWON;
        }
        update opportunityRecord;     
    }
    
    public static List<Opportunity> fetchOpportunityForAPIByUser(String userId) {
        return [SELECT Id, StageName, Amount, AgentType__c, CreatedDate, CloseDate  FROM Opportunity WHERE OwnerId =: userId AND CreatedDate = THIS_FISCAL_YEAR];
    }
    
    /**
* To get Opportunity present in account
*/
    public static Map<Id,Opportunity> getAllOpportunitys(Set<Id> accountsIDs, List<Account> accountList){
        
        List<Opportunity> allOpportunity = [select AccountId, Name, CloseDate, StageName, createdDate, OwnerId  from Opportunity where AccountId IN: accountsIDs order by createdDate asc ]                                                                                     ;
        
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        
        for(Opportunity oppRec : allOpportunity){
            for(Account accountRec : accountList){
                if(oppRec.AccountId == accountRec.Id && oppRec.createdDate >= accountRec.createdDate){
                    opportunityMap.put(oppRec.AccountId,oppRec);
                }
            }
        }
        return opportunityMap;
    }
    
    /**
* Get lastest Opportunity for an account
*/
    public static Map<Id,Opportunity> getOpportunityForAccount(Map<Id,Account> accountMap){
        
        List<Opportunity> allOpportunity = [SELECT AccountId, Name, CloseDate, StageName, createdDate, OwnerId  FROM Opportunity WHERE AccountId IN: accountMap.keySet() ORDER BY createdDate ASC];
        
        Map<Id,Opportunity> accountOpportunityMap = new Map<Id,Opportunity>();
        
        for(Opportunity oppRec : allOpportunity){
            Account accountRec = accountMap.get(oppRec.AccountId);
            if(oppRec.createdDate >= accountRec.createdDate){
                accountOpportunityMap.put(oppRec.AccountId,oppRec);
            }
        }
        return accountOpportunityMap;
    }
    
    @AuraEnabled(cacheable=false)
    public static Opportunity getOpportunityDetailsbyId(String opportunityID){
        
        Opportunity opportunityObj = [select AccountId, Name, CloseDate, StageName, createdDate, OwnerId, SaleType__c, DealType__c, BookingType__c, AgentType__c, ReferralType__c, BrokerAgentName__c,BrokerAgencyAccount__c, EmployeeName__c,CanAllowBooking__c  from Opportunity where Id =: opportunityID limit 1];
        
        return opportunityObj;
    }
    
    public static map<id,Opportunity> getOpportunityDetailsMapbyId(String opportunityID){
        map<id,Opportunity> opportunityMap = new map<id,Opportunity>();
        
        opportunityMap = new map<id,Opportunity>([select id,Name,StageName,AgentType__c,ReferralType__c,AccountId,Account.CustomerSubType__c,ContactId,ResidentStatus__c,LeadSource,Contact__r.MobilePhone,Contact__r.Email,Contact__r.Name,Contact__r.ResidentStatus__c,ownerId,owner.ManagerId,SaleType__c,BrokerAgentContact__c,BrokerAgencyAccount__c,Financing__c,Account.CustomerType__c from opportunity where id=:opportunityID  ]);
        
        return opportunityMap;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getOpportunityQuery(String query) {
        List<Opportunity> records = Database.query(query);
        return records;
    }
    
    @AuraEnabled(cacheable=false)
    public static String opportunityFieldsValidation(String opportunityId){ 
        
        return opportunityFieldsValidationmt(opportunityId);
    }
    /*
* Purpose : To validate Opportunity fields added in custom metadata(Validate fields)
* Created by : Ajay Thakur
*/
    @AuraEnabled(cacheable=false)
    public static String opportunityFieldsValidationmt(String opportunityId){ 
        System.debug('OppService opportunityFieldsValidationmt Log: Inside getUnitDetails 1');
        
        Set<String> oppFieldList = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(oppFieldList);
        String opptyfields = string.join(strList,',');
        String query = 'SELECT ' + opptyfields + ' FROM Opportunity WHERE Id = \'' + opportunityId + '\'';
        System.debug('***Opportunity query***'+query);
        List<Opportunity> opportunityList = Database.Query(query);
        System.debug('***Opportunity Record***'+opportunityList);
        
        
        Map<String,List<ValidationFields__mdt>> validationFieldsMap = Utilities.getValidationFields();
        System.debug('Log: igot validationFieldsMap map  ');
        
        String opportunityValdiation = '';
        
        Opportunity oppRec = opportunityList[0] ;
        System.debug('Log: got opprec  ');
        if (validationFieldsMap.size() > 0)
        {
            System.debug('inside if condition  ');    
            for(ValidationFields__mdt field : validationFieldsMap.get('Opportunity')){
                System.debug('inside for loop of validation  ');
                
                String fieldValue = (String) oppRec.get(field.FieldAPI__c);
                
                System.debug('FieldAPI-'+field.FieldAPI__c+'- FieldValue-'+fieldValue);
                opportunityValdiation += (String.isNotBlank((String) oppRec.get(field.FieldAPI__c)) ? '': (String.isNotBlank(opportunityValdiation) ? +', ' : '') + field.Label);
                
            }    
        }   
        System.debug('opportunityValdiation ending '+opportunityValdiation);
        return opportunityValdiation ;
    }
    
    public static List<Opportunity> fetchOpportunitiesByAccountId(String accountId) {
        return [select id, StageName from Opportunity where AccountId =: accountId];
    }
    
    public static Map<String,List<ValidationFields__mdt>> getValidationFields()
    {
        List<ValidationFields__mdt> valFieldList = ValidationFields__mdt.getall().values();
        
        Map<String,List<ValidationFields__mdt>> validationFieldsMap = new Map<String,List<ValidationFields__mdt>>();
        
        for(ValidationFields__mdt vf : valFieldList)
        {
            if(!validationFieldsMap.containsKey(vf.ObjectName__c))
                validationFieldsMap.put(vf.ObjectName__c, new List<ValidationFields__mdt>{vf});
            else
            {
                List<ValidationFields__mdt> valfldList = validationFieldsMap.get(vf.ObjectName__c);
                valfldList.add(vf);
                validationFieldsMap.put(vf.ObjectName__c, valfldList);
            }
            
        }
        
        return validationFieldsMap;
    }
    
    
    
    
    public static Map<id,String> fetchOpportunityNumber(Set<Id> opportunityIds){
        Map<id,String> opportunityIdNumberMap = new Map<id,String>();
        for(Opportunity opportunity : [select id,OpportunityNumber__c from Opportunity where id IN: opportunityIds])
        {
            opportunityIdNumberMap.put(opportunity.Id,'Opportunity-'+opportunity.OpportunityNumber__c);
        } 
        System.debug('opportunityIdNumberMap '+opportunityIdNumberMap);
        return opportunityIdNumberMap;
    }
    /*
*Fetch Lead by Id
*/
    public static Opportunity fetchOpportunityById(String opportunityId) {
        
        Set<String> oppFieldList = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(oppFieldList);
        //strList.add('​BrokerAgencyAccount__r.Name');
        //strList.add('​BrokerAgentContact__r.Name');
        String opptyfields = string.join(strList,',');
        
        Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
        List<String> strAccList = new List<String>();
        for(String accountField : accFieldList){
            strAccList.add('Account.'+accountField);
        }
        String accountFields = string.join(strAccList,',');
        
        Set<String> conFieldList = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().keySet();
        List<String> strConList = new List<String>();
        //strConList.addAll(conFieldList);
        for(String contactField : conFieldList){
            strConList.add('Contact__r.'+contactField);
        }
        String conFields = string.join(strConList,',');
        
        String query = 'SELECT (select id from OpportunityEOIsOpportunity__r), (select id, Name, ApprovalStatus__c, MemoSubject__c, MemoType__c, isApproved__c from Memos__r),' + opptyfields + ','+accountFields+','+conFields+' FROM Opportunity WHERE Id = \'' + opportunityId + '\'';
        System.debug('***Opportunity query***'+query);
        Opportunity opportunityRec = Database.Query(query);
        System.debug('***Opportunity Record***'+opportunityRec);
        return opportunityRec;
    }
    
    //----Fetch list of Leads based on condition
    public static List<Opportunity> fetchOpportunities(string whereCondition){
        List<Opportunity> opportunityList = new List<Opportunity>();
        try{ 
            String strQuery = 'Select Id, Account.NationalIdExpiryDate__pc, Name,CloseDate,OpportunityNumber__c,StageName,Account.Name,Project__c,LeadSource,SaleType__c,CreatedDate, CanAllowBooking__c FROM Opportunity WHERE Id != null AND Account.Blacklisted__c = False ';   
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            }
            strQuery += ' Order By CreatedDate DESC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
            System.debug('---Opportunity Query---'+strQuery);
            opportunityList =  Database.query(strQuery);
            System.debug('***opportunityList***'+opportunityList.size());
            return opportunityList;
        }
        catch(Exception e){
            System.debug('*** Exception e***'+e.getMessage());
            throw e;
        }
    }   
    
    public static map<id,Lead> getLeadDetailsMapbyId(String leadID){
        map<id,Lead> leadMap = new map<id,Lead>();
        
        leadMap= new map<id,Lead>([select id,CustomerSubType__c,Nationality__c,ResidentStatus__c,LeadSource from Lead where id=:leadID  WITH SECURITY_ENFORCED]);
        
        return leadMap;
    }
    @AuraEnabled(cacheable=false)
    public static List<OfferLines__c> getOfferLinesQuery(String query) {
        List<OfferLines__c> records = Database.query(query);
        return records;
    }
    
    @AuraEnabled(cacheable=false)
    public static void insertOfferLines(List<MemoLines__c> memoLinesList, Id offerId){
        
        List<OfferLines__c> offerLinesList = new List<OfferLines__c>();
        String offerPromotionId;
        String fieldApi;
        Map<String,OfferLinesService__mdt> OfferLineServiceMap = Utilities.getOfferLineService();
        
        
        for (Integer i = 0; i < memoLinesList.size(); i++) {
            offerPromotionId = PaymentPlanOffPromotionService.lastCreatedIdOffersPromotions(memoLinesList[i].BookingMemo__c,memoLinesList[i].Unit__c);
            
            if (memoLinesList[i].AdditionalDiscountPercentage__c > 0) {
                fieldApi = 'AdditionalDiscountPercentage__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);      
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].SCWaiverYears__c > 0) {
                fieldApi = 'SCWaiverYears__c';   
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);         
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].HomeMaintenanceYears__c > 0) {
                fieldApi = 'HomeMaintenanceYears__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].PMFeeYears__c > 0) {
                fieldApi = 'PMFeeYears__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].BrokerCommissionPercentage__c > 0) {
                fieldApi = 'BrokerCommissionPercentage__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].ADMFeePercentage__c > 0) {
                fieldApi = 'ADMFeePercentage__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].SubsidyPercentage__c > 0) {
                fieldApi = 'SubsidyPercentage__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].RebatePercentage__c > 0) {
                fieldApi = 'RebatePercentage__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            if (memoLinesList[i].IntCommissionPercentage__c > 0) {
                fieldApi = 'IntCommissionPercentage__c';
                OfferLines__c offerLinesRecord = getOfferLinesService(memoLinesList[i], fieldAPI, offerPromotionId, OfferLineServiceMap);
                offerLinesList.add(offerLinesRecord);
            }
            
        }
        insert offerLinesList;
    }
    
    public static OfferLines__c getOfferLinesService(MemoLines__c memoLine, String fieldAPI, String offerPromotionId, Map<String,OfferLinesService__mdt> OfferLineServiceMap)
    {
        String offerValue = String.valueOf(memoLine.get(fieldAPI));
        //Decimal offerValue = 
        OfferLines__c offerLinesRecord = new OfferLines__c();
        offerLinesRecord.OfferName__c = offerPromotionId;
        offerLinesRecord.OfferType__c = OfferLineServiceMap.get(fieldApi).OfferType__c;
        offerLinesRecord.DiscountType__c = OfferLineServiceMap.get(fieldApi).DiscountType__c;
        offerLinesRecord.OfferOn__c = OfferLineServiceMap.get(fieldApi).OfferOn__c;
        offerLinesRecord.OfferValue__c = Decimal.valueOf(offerValue); //Decimal.valueOf(memoLine.get(fieldAPI));
        offerLinesRecord.OfferValueType__c = OfferLineServiceMap.get(fieldApi).OfferValueType__c;
        offerLinesRecord.Unit__c = memoLine.Unit__c;
        offerLinesRecord.Nationality__c=null;
        offerLinesRecord.BudgetTaskName__c = OfferLineServiceMap.get(fieldApi).BudgetTaskName__c;
        
        return offerLinesRecord;
    }
    
    public static Boolean getMandatoryDocsStatus(salesorder__c SO){
        Boolean docsStatus = false;
        Boolean PassportCopyExists = false;
        Boolean eIdExists = false;
        Boolean ResidentCustomer = false;
        
        
        list<Account> acnt = [select id,ResidentStatus__pc from account where id= :SO.account__c ]; //commented by Jana(28/07/23)and RecordTypeid = :constants.PERSON_RECORD_TYPE_ID
        system.debug('acnt++'+acnt);
        
        if(!acnt.isempty()){
            if(acnt[0].ResidentStatus__pc == constants.RESIDENTSTATUS_RESIDENT){
                ResidentCustomer = True;
            }
        }
        
        
        map<Id,ContentDocumentLink> docFiles= new map<Id,ContentDocumentLink>();
        for(ContentDocumentLink docFile : [SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId in ( SELECT Id FROM Document__c where account__c = :SO.account__c)]) {
            docFiles.put(docFile.LinkedEntityId,docFile);
        }
        
        if(!docFiles.isempty()){
            //commented by Jana
            /* for(Document__c doc : [Select id,DocumentType__c from document__c where account__c = :SO.account__c ]) {
if(doc.DocumentType__c == 'Passport Copy'){
PassportCopyExists = docFiles.containskey(doc.id);
}
if(ResidentCustomer){
if(doc.DocumentType__c == 'National ID Front Copy') {
eIdExists = docFiles.containskey(doc.id);
}
}
} */
        }
        
        if(ResidentCustomer){
            if(PassportCopyExists & eIdExists){
                docsStatus=true;
            }    
        }
        else {
            if(PassportCopyExists){
                docsStatus=true;
            }
        }
        
        return docsStatus;
    }
    
    public static List<SalesOrder__c> getSalesOrderByAccountId(Set<Id> accountIds){
        return [SELECT Id,Name,Unit__c, Unit__r.Name,Account__c,Status__c FROM SalesOrder__c WHERE Account__c IN:accountIds];
    }
    
    @AuraEnabled
    public static List<SalesOrder__c> getSalesOrderRec(Id SalesOrderId){
        return [SELECT Id,Name,Account__c,Account__r.Name FROM SalesOrder__c WHERE Id =:SalesOrderId AND Account__c != null];
    }
    
    
    public static Map<Id,List<SalesOrder__c>> getAccountOpportunityUnitMap(Set<Id>accountIds){
        
        Map<Id,List<SalesOrder__c>> accountMap = new Map<Id,List<SalesOrder__c>>();
        for(SalesOrder__c opportunityUnitRec : getSalesOrderByAccountId(accountIds)){
            List<SalesOrder__c> opportunityUnitList ;
            Id accountId = opportunityUnitRec.Account__c ;
            opportunityUnitList = (accountMap.containsKey(accountId) ? accountMap.get(accountId) : new List<SalesOrder__c>());
            opportunityUnitList.add(opportunityUnitRec);
            accountMap.put(accountId,opportunityUnitList);
        }
        return accountMap;
    }
    
    public static Map<Id,List<SalesOrder__c>> getOpportunitySalesOrderMap(Set<Id> opportunityIds){
        
        Map<Id,List<SalesOrder__c>> opportunitySalesOrderMap = new Map<Id,List<SalesOrder__c>>();
        for(SalesOrder__c salesOrderRec : getSalesOrderByOpportunityIdSet(opportunityIds)){
            List<SalesOrder__c> salesOrderList ;
            Id opportunityId = salesOrderRec.Opportunity__c ;
            salesOrderList = (opportunitySalesOrderMap.containsKey(opportunityId) ? opportunitySalesOrderMap.get(opportunityId) : new List<SalesOrder__c>());
            salesOrderList.add(salesOrderRec);
            opportunitySalesOrderMap.put(opportunityId,salesOrderList);
        }
        return opportunitySalesOrderMap;
    }
    
    
    
    
    
    public static Set<Id> getSalesOrdersAccountIds(Id salesOrderId ){
        
        Set<Id> accountIds = new    Set<Id> ();
        List<SalesOrder__c> salAccounts =  [SELECT Name,Account__c from SalesOrder__c WHERE  Id=:salesOrderId];
        for(SalesOrder__c  sa : salAccounts){
            accountIds.add(sa.Account__c);
        }
        return accountIds;
    }
    
    
    public static Set<Id> getAllSalesOrdersAccountIds(Set<Id> salesOrderId ){
        
        Set<Id> accountIds = new    Set<Id> ();
        List<SalesOrder__c> salAccounts =  [SELECT Name,Account__c from SalesOrder__c WHERE  Id IN:salesOrderId];
        for(SalesOrder__c  sa : salAccounts){
            accountIds.add(sa.Account__c);
        }
        return accountIds;
    }
    
    
    /*
* Fetch list of Sales Order based on the condition
*/
    public static List<SalesOrder__c> fetchSalesOrders(string whereCondition){
        
        List<SalesOrder__c> salesOrderList= new List<SalesOrder__c    >();
        
        try{
            String strQuery = 'Select Id,Name,Status__c,SubStatus__c,Unit__c,Unit__r.Name,Opportunity__c,BookingDate__c,Account__r.Name,SellingPrice__c,NetAmount__c,Offer__r.Name,PaymentPlan__r.Name, ProjectName__c FROM SalesOrder__c WHERE Id != null ';
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            }
            strQuery += ' Order By Name ASC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
            system.debug('--Sales Order Query--'+strQuery);
            salesOrderList = Database.query(strQuery);
            return salesOrderList;
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
            throw e;
        }
    }
    
    
    
    public static List<SalesOrder__c> fetchSalesOrderByAccountId(String accountId) {
        return [SELECT id,Status__c FROM SalesOrder__c WHERE Account__c =: accountId];
    }
    
    public static List<SalesOrder__c> fetchSalesOrderForAPIByUser(String userId) {
        return [SELECT Id, NetAmount__c, Status__c, Opportunity__c, Opportunity__r.AgentType__c FROM SalesOrder__c WHERE SalesManager__c =: userId AND BookingDate__c = THIS_FISCAL_YEAR];
    }
    
    public static List<SalesOrder__c> queryAllFieldsWithExtraFields(List<Id> soIds) {
        Set<String> soFieldList = Schema.getGlobalDescribe().get('SalesOrder__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(soFieldList);
        String fields = string.join(strList, ',');
        
        Set<String> ilFieldList = Schema.getGlobalDescribe().get('InstallmentLines__c').getDescribe().fields.getMap().keySet();
        List<String> strILList = new List<String>();
        strILList.addAll(ilFieldList);
        String ilFields = string.join(strILList, ',');
        
        Set<String> socFieldList = Schema.getGlobalDescribe().get('SalesOrderOtherCharges__c').getDescribe().fields.getMap().keySet();
        List<String> strSOCList = new List<String>();
        strSOCList.addAll(socFieldList);
        String socFields = string.join(strSOCList, ',');
        
        Set<String> oolFieldList = Schema.getGlobalDescribe().get('OpportunityOfferLine__c').getDescribe().fields.getMap().keySet();
        List<String> strOOLList = new List<String>();
        strOOLList.addAll(oolFieldList);
        String oolFields = string.join(strOOLList, ',');
        
        Set<String> cliFieldList = Schema.getGlobalDescribe().get('CommissionLineItem__c').getDescribe().fields.getMap().keySet();
        List<String> strCLIList = new List<String>();
        strCLIList.addAll(cliFieldList);
        String cliFields = string.join(strCLIList, ',');
        
        Set<String> joFieldList = Schema.getGlobalDescribe().get('JointOwner__c').getDescribe().fields.getMap().keySet();
        List<String> strJOList = new List<String>();
        strJOList.addAll(joFieldList);
        String joFields = string.join(strJOList, ',');
        
        Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strRAList = new List<String>();
        strRAList.addAll(raFieldList);
        String raFields = string.join(strRAList, ',');
        
        Set<String> docFieldList = Schema.getGlobalDescribe().get('Document__c').getDescribe().fields.getMap().keySet();
        List<String> strDocList = new List<String>();
        strDocList.addAll(docFieldList);
        String docFields = string.join(strDocList, ',');
        
        String soIdsStr = String.join(soIds, '\',\'');
        // String externalStr = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
        //commented By Jana(28/07/23) ),(SELECT ' + docFields + ' FROM Documents__r ORDER BY DocumentType__c ASC
        String query = 'SELECT ' + fields + ', Account__r.Name,Account__r.id,Account__r.PersonEmail, Account__r.Phone, Account__r.PersonMobilePhone, Account__r.MobileNumber__c, Account__r.MobileCountryCode__c,Opportunity__r.CustomerResidentStatus__c, CreatedBy.Email, Owner.Email, Owner.Name, Unit__r.Name, PaymentPlan__r.Name, Unit__r.TotalArea__c,PaymentPlan__r.Classification__c, Opportunity__r.BrokerAgencyAccount__r.Name, Opportunity__r.BrokerAgentContact__r.Name, (SELECT ' + ilFields + ', PaymentPlan__r.Name, CreatedBy.Email FROM InstallmentLines__r), (SELECT Account__r.Name, ' + socFields + ' FROM SalesOrdersOtherCharges__r), (SELECT ' + oolFields + ', OfferLine__r.OfferOn__c, OfferLine__r.OfferType__c, OfferLine__r.OfferName__c, OfferLine__r.OfferName__r.OfferName__c FROM OpportunityOfferLines__r), (SELECT ' + cliFields + ', CreatedBy.Email, Owner.Email, BrokerAgency__r.Name, BrokerAgent__r.Name, SalesManager__r.Name, SalesManager__r.Email FROM CommissionLineItems__r), (SELECT ' + joFields + ' FROM Joint_OwnersSalesOrder__r),(SELECT Account__r.Name, ' + raFields + ' FROM Payments__r) FROM SalesOrder__c WHERE Id IN (\'' + soIdsStr + '\')';
        System.debug('***SalesOrder query***'+query);
        List<SalesOrder__c> SalesOrders = Database.Query(query);
        System.debug('***SalesOrder Queried***'+SalesOrders);
        return SalesOrders;
    }
    
    public static SalesOrder__c getAccountWithJointOwners(String soId) {
        SalesOrder__c so = [SELECT Id, Name, Account__c, Account__r.Name, Account__r.BillingStreet, Account__r.BillingCity, 
                            Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.ShippingStreet, 
                            Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry, 
                            (SELECT Id, Account__c, RelationshipType__c, Account__r.Name, Account__r.BillingStreet, Account__r.BillingCity, 
                             Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.ShippingStreet, 
                             Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry 
                             FROM Joint_OwnersSalesOrder__r) FROM SalesOrder__c WHERE Id =: soId];
        return so;
    }
    
    
    
    public static void newOpportunityUnitRecord(List<SalesOrder__c> newList){
        
        for(SalesOrder__c newSalesOrder : newList){
            OpportunityService.updateOpportunityStage(newSalesOrder.Opportunity__c,'meeting');
        }
    }
    
    public static Boolean cancelSalesOrderReservation(Set<String> idList) {
        
        system.debug('cancelSalesOrderReservation' + idList);
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        
        for(SalesOrder__c objSalesOrder : [Select id,Name from SalesOrder__c where id IN:idList]){
            objSalesOrder.Status__c = Constants.SALES_STATUS_CANCELLED;
            salesOrderList.add(objSalesOrder);
        }
        update salesOrderList;
        return true;     
    }
    
    /*
* Get all Sales Orders By AccountId
*/
    public static List<SalesOrder__c> getOpportunityUnitByAccountId(Set<Id> accountIds){
        return [SELECT Id,Name,Unit__c,Account__c FROM SalesOrder__c WHERE Account__c IN:accountIds];
    }
    
    /*
* Get all Sales Orders By opportunityId
*/
    public static List<SalesOrder__c> getSalesOrderByOpportunityId(String opportunityId){
        return [SELECT Id,Status__c,Name,Unit__c,Account__c,RAcknowledgementReservationAmount__c,Opportunity__c,NetAmount__c FROM SalesOrder__c WHERE Opportunity__c =:opportunityId];
    }
    
    /*
* Get all Sales Orders By opportunityId Set
*/
    public static List<SalesOrder__c> getSalesOrderByOpportunityIdSet(Set<Id> opportunityIds){
        return [SELECT Id,Status__c,Name,Unit__c,Account__c,RAcknowledgementReservationAmount__c,Opportunity__c,NetAmount__c FROM SalesOrder__c WHERE Opportunity__c in:opportunityIds];
    }
    
    /*
* Get Sales Order By unitId
*/
    public static SalesOrder__c getSalesOrderByUnitId(String unitId){
        return [SELECT Id,Status__c,Name,Unit__c,Account__c,RAcknowledgementReservationAmount__c,NetAmount__c FROM SalesOrder__c WHERE Unit__c =:unitId limit 1];
    }
    public List<Opportunity> getOpportunitiesByADHAApplicationNumber(String adhaApplicationNumber){
        return [SELECT Id, ADHAApplicationNumber__c, ADHAStatus__c,Lead__c FROM Opportunity 
                WHERE ADHAApplicationNumber__c =:adhaApplicationNumber];
    }
    
  
     public Opportunity getOpportunityById(Id oppId){
         System.debug('oppId--'+oppId);
        return  [SELECT Id, Name, LeadProject__c, UnitNumber__c, NumberOfBedrooms__c, Account.Name,AccountId,Account.Recordtype.DeveloperName,
                 UnitType__c,OpportunityType__c,Account.IsPersonAccount,Account.PersonEmail, 
                 OwnerId  FROM Opportunity WHERE Id = :oppId];
    }
    
    
    //Update Opportunities without trigger
    public List<Opportunity> updateOpportunitiesWithoutTrigger(List<Opportunity> oppList){
        if(oppList != NULL && !oppList.isEmpty()){
            OpportunityTriggerHandler.isTriggerDisabled = true;
            update oppList;
            OpportunityTriggerHandler.isTriggerDisabled = false;
        }
        return oppList;
    }
    //Update Opportunities with trigger
    public List<Opportunity> updateOpportunities(List<Opportunity> oppList){
        if(oppList != NULL && !oppList.isEmpty()){
            update oppList;
        }
        return oppList;
    }
    //Update Opportunity without trigger
    public Opportunity updateOpportunityWithoutTrigger(Opportunity opp){
        return updateOpportunitiesWithoutTrigger(new List<Opportunity>{opp})[0];
    }
    
    public List<Opportunity> getOpportunitiesWithAccountRecordType(List<Opportunity> opportunityIds) {
        return [
            SELECT Id, Account.RecordType.DeveloperName,OpportunityType__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];
    }
    public Opportunity insertOpportunityWithoutTrigger(Opportunity objOpportunity){
        if(objOpportunity != NULL ){
            objOpportunity = insertOpportunitiesWithoutTrigger(new List<Opportunity>{objOpportunity})[0];
        }
        return objOpportunity;
    }
    
    public List<Opportunity> insertOpportunitiesWithoutTrigger(List<Opportunity> oppList){
        if(oppList != NULL && !oppList.isEmpty()){
            OpportunityTriggerHandler.isTriggerDisabled = false;
            insert oppList;
            OpportunityTriggerHandler.isTriggerDisabled = true;
        }
        return oppList;
    }   
}
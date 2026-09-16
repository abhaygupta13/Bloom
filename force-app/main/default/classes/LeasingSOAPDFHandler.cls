/**
* @File Name : LeasingSOAPDFHandler.cls
* @Description : Controller class to create statement of account with respect to Leasing order
* @Test Class:
* @Last Modified By :
* @Last Modified On : 
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Nov 11, 2025 |   | Initial Version
**/
public class LeasingSOAPDFHandler {
    public String totalBalanceInstallment { get; set; }
    public String statementDate { get; set; }
    public String projectName {get; set;}
    public String unitNumber {get; set;}
    public String tenantId { get; set;}
    public String tenantName {get; set;}
    public String tenantAddress {get; set;}
    public String tenantEmail {get; set;}
    public String unitType {get; set;}
    public String leaseStartDate {get; set;}
    public String leaseEndDate {get; set;}
    public List<PaymentPlanWrapper> paymentPlans { get; set; }
    public List<OtherChargeWrapper> otherCharges { get; set; }
    public List<OtherChargeWrapper> ocPenalties { get; set; }
    public List<acknowledgementWrapper> prePayments { get; set; }
    public List<acknowledgementWrapper> pdcs { get; set; }
    public Decimal totalInstallmentCollection { get; set;}
    public Decimal totalInstallmentOutStanding { get; set; }
    public Decimal totalOCCollection { get; set;}
    public Decimal totalOCOutStanding { get; set; }
    public LeasingOrder__c leasingOrder { get; set; }
    public Decimal totalCharges { get; set; }
    public Decimal totalCollection { get; set; }
    public Decimal totalOutStanding { get; set; }
    public Decimal otherChargesTotal {get; set;}
    public Decimal installmentTotal {get; set;}
    public Decimal penaltyTotal {get; set;}
    public Decimal penaltyCollected {get; set;}
    public Decimal penaltyDue {get; set;}
    public Decimal ocTotal {get; set;}
    private static final string SOA { get { return 'Statement of Account'; } }  
    private static final string HYPHEN { get { return ' - '; } }
    public List<StatementRowWrapper> statementRows { get; set; }
    public List<StatementRowWrapper> sdRows { get; set; }
     //public LeasingOrder__c leasingOrder { get; set; }
    public Decimal totalPrePayment { get; set;}
    public Decimal totalPDcs { get; set;}
    public Boolean isRenewalLO {get; set;}
    public Decimal creditBalance {get; set;}
    public String creditBalanceWords {get; set;}
    public Boolean showDetails {get; set;}
    public Decimal totalInvoice {get; set;}
    public Decimal totalReceipt {get; set;}
    public Decimal totalBalance {get; set;}

    public class PaymentPlanWrapper{
        public String installmentDueDate {get; set;}
        public String installmentName {get; set;}
        public Decimal formattedAmount {get; set;}
        public Decimal formattedCollectedAmount {get; set;}
        public Decimal formattedOustandingAmount {get; set;}
        public String installmentDocNumber {get; set;}  
    }

    public class OtherChargeWrapper{
        public String otherChargeName {get; set;}
        public String otherChargeDueDate {get; set;}
        public Decimal formattedAmount {get; set;}
        public Decimal formattedCollectedAmount {get; set;} 
        public Decimal formattedPendingAmount {get; set;}
        public String ocDocNumber {get; set;}
    }

    public class acknowledgementWrapper{
        public String acknowledgementName {get; set;}
        public String acknowledgementDueDate {get; set;}
        public Decimal formattedAmount {get; set;}
        public String doqSeqNumber {get; set;} 
        // public Decimal formattedPendingAmount {get; set;}
        // public String ocDocNumber {get; set;}
    }
    

    public LeasingSOAPDFHandler() {
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        statementDate = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
        String leasingOrderId = ApexPages.currentPage().getParameters().get('id');
    	
        Boolean isPDC = Boolean.valueOf(ApexPages.currentPage().getParameters().get('PDC'));
        Boolean isSecurity = Boolean.valueOf(ApexPages.currentPage().getParameters().get('Security'));
        showDetails = Boolean.valueOf(ApexPages.currentPage().getParameters().get('Details'));
        totalInvoice = 0;
        totalReceipt = 0;
        totalBalance = 0;
        statementRows = prepareData(leasingOrderId, isPdc, isSecurity);//for Full SOA
        // if(isSecurity)
        // sdRows = prepareSDData(leasingOrderId); //For Security deposit

        
        leasingOrder = leasingService.getLeasingOrderById(leasingOrderId);
        
        creditBalance = leasingOrder.CreditBalance__c != Null && leasingOrder.CreditBalance__c != 0 ? leasingOrder.CreditBalance__c : 0;
        creditBalanceWords = AmountToWordsUtil.convert(creditBalance);
       
        //leasingOrder = leasingOrders[0];
        paymentPlans = new List<PaymentPlanWrapper>();
        otherCharges = new List<OtherChargeWrapper>();
        ocPenalties = new List<OtherChargeWrapper>();
        pdcs = new List<acknowledgementWrapper>();
        prePayments = new List<acknowledgementWrapper>();
        tenantId = leasingOrder.LeasingSAPContractId__c != Null ? leasingOrder.LeasingSAPContractId__c : '';
        Integer installmentNumber = 1;
        Decimal totalAmount = leasingOrder.RentalAmountAfterDiscount__c;
        totalInstallmentOutStanding = 0;
        totalInstallmentCollection = 0;
        totalOCCollection = 0;
        totalOCOutStanding = 0;
        totalCollection = 0;
        totalOutStanding = 0;
        otherChargesTotal = 0;
        installmentTotal = 0;
        ocTotal = 0;
        penaltyTotal = 0;
        penaltyDue = 0;
        penaltyCollected = 0;
        totalPrePayment = 0;
        totalPDcs = 0;
        projectName = leasingOrder.project__r.name;
        unitNumber = leasingOrder.Unit__r.UnitNumber__c;
        tenantName = leasingOrder.Account__r.Name;
        tenantAddress = leasingOrder.Account__r.PersonMailingStreet +', '+ leasingOrder.Account__r.PersonMailingCity+', '+leasingOrder.Account__r.PersonMailingState+', '+leasingOrder.Account__r.PersonMailingCountry;
        tenantEmail = leasingOrder.Account__r.PersonEmail;
        unitType = leasingOrder.Unit__r.PropertyUsage__c;
        leaseStartDate = DateTime.newInstance(leasingOrder.LeasingStartDate__c, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
        leaseEndDate = DateTime.newInstance(leasingOrder.LeasingEndDate__c, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
        
         
        for(PaymentPlanSchedule__c pps : leasingOrder.Payment_Plan_Schedules__r){
            PaymentPlanWrapper pp = new PaymentPlanWrapper();
            pp.installmentDueDate = formatDate(pps.DueDate__c);
            pp.installmentName = pps.Name;
            pp.installmentDocNumber = pps.RefDocno__c;
            pp.formattedAmount = pps.TotalInstallmentAmount__c;
            pp.formattedCollectedAmount = pps.ClearedAmount__c != Null ? pps.ClearedAmount__c : 0;
            pp.formattedOustandingAmount = pps.DueAmount__c;
            totalInstallmentCollection += pps.ClearedAmount__c != Null ? pps.ClearedAmount__c : 0;
            totalInstallmentOutStanding += pps.DueAmount__c;
            installmentTotal += pps.TotalInstallmentAmount__c;
            paymentPlans.add(pp);
        }

        for(LeasingOrdersOtherCharges__c loc : leasingOrder.Leasing_Orders_Other_Charges__r){
            OtherChargeWrapper oc = new OtherChargeWrapper();
            oc.otherChargeName = loc.Name;
            oc.ocDocNumber = loc.RefDocno__c;
            oc.otherChargeDueDate = formatDate(loc.DueDate__c);
            oc.formattedAmount = loc.TotalAmount__c;
            oc.formattedCollectedAmount = loc.ClearedAmount__c;
            oc.formattedPendingAmount = loc.DueAmount__c;
            totalOCCollection += loc.ClearedAmount__c != Null ? loc.ClearedAmount__c : 0;
            totalOCOutStanding += loc.DueAmount__c;
            ocTotal += loc.TotalAmount__c;
            otherCharges.add(oc);
            if(loc.Type__c == 'Penalty Charge'){
                ocPenalties.add(oc);
                penaltyTotal += loc.TotalAmount__c;
                penaltyDue += loc.DueAmount__c;
                penaltyCollected += loc.ClearedAmount__c;
            }
        }

        totalCollection = totalInstallmentCollection +  totalOCCollection;
        totalOutStanding = totalInstallmentOutStanding + totalOCOutStanding;
        totalCharges = totalCollection+totalOutStanding;
        
        for(LeasingReceiptAcknowledgment__c lra : leasingOrder.LeasingReceiptAcknowledgment_s__r){
            acknowledgementWrapper acw = new acknowledgementWrapper();
            acw.acknowledgementName = lra.Name;
            acw.doqSeqNumber = lra.SAPDocumentNumber__c;
            acw.acknowledgementDueDate = lra.ChequeDate__c != Null ? formatDate(lra.ChequeDate__c) : '';
            acw.formattedAmount = lra.Amount__c;
            acw.doqSeqNumber = lra.SAPDocumentNumber__c != Null ? lra.SAPDocumentNumber__c : '';

            if(lra.Amount__c == lra.UnappliedAmount__c){
                prePayments.add(acw);
                totalPrePayment += acw.formattedAmount;
            }
            if(lra.ChequeDate__c > Date.today()){
                pdcs.add(acw);
                totalPDcs += acw.formattedAmount;
            }
        }

    }
    public static String formatDate(Date inputDate) {
        if (inputDate != null) {
            return DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day()).format('dd.MM.yyyy');
        }
        return '';
    }
    @AuraEnabled
    public static String generateAndAttachPdf(Id leasingOrderId) {
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        LeasingOrder__c leasingOrder = leasingService.getLeasingOrderById(leasingOrderId);
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        String soNumber = leasingOrder.Name;
        String statementFileName = 'Statement'+'-'+leasingOrder.Name;
        PageReference pdfPage;
       
        pdfPage = Page.LeasingOrderSOAPDF; // Replace with your VF page name
        pdfPage.getParameters().put('id', leasingOrderId);
        pdfPage.getParameters().put('PDC', 'false');
        pdfPage.getParameters().put('Security', 'false');
        pdfPage.getParameters().put('Details', 'false');
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // Return a mock Blob in test context
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            // Actual getContent() call outside test context
            pdfBlob = pdfPage.getContent();
        }
        
        
        
        Map<Id, Document__c> docMap = new Map<Id, Document__c>();
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> leasingOfferDocs = docService.getDocumentsByLeasingOrderId(leasingOrderId);
        Id docId;
        for(Document__c doc : leasingOfferDocs){
            if(doc.Document_Name__c == 'Statement of Account - Invoice'){
                docId = doc.Id;
            }
        }
        
        if(docId != Null){
            ContentVersion file = new ContentVersion();
            file.Title = contract.Opportunity__r.Account.Name + HYPHEN+SOA;
            file.PathOnClient = contract.Opportunity__r.Account.Name + '_SOA.pdf';
            file.VersionData = pdfBlob;
            if(!test.isRunningTest()){file.FirstPublishLocationId = docId;}
            filesToInsert.add(file);

            ContentService conService = ContentService.getInstance();
            conService.createContentVersion(filesToInsert);

            return file.Id;
        } 
        return null;
    }
     @AuraEnabled
    public static String generateAndAttachPdfSOA_FULL(Id leasingOrderId, Boolean isPDC, Boolean isSecurity, Boolean Details) {
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        LeasingOrder__c leasingOrder = leasingService.getLeasingOrderById(leasingOrderId);
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        String soNumber = leasingOrder.Name;
        String statementFileName = 'Statement'+'-'+leasingOrder.Name;
        PageReference pdfPage;
       
        pdfPage = Page.LeasingOrderSOA_FullPDF; // Replace with your VF page name
        pdfPage.getParameters().put('id', leasingOrderId);
        
        pdfPage.getParameters().put('PDC', String.ValueOf(isPDC));
        
        
        pdfPage.getParameters().put('Security', String.ValueOf(isSecurity));
        pdfPage.getParameters().put('Details', String.ValueOf(Details));
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // Return a mock Blob in test context
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            // Actual getContent() call outside test context
            pdfBlob = pdfPage.getContent();
        }
        
        
        
        Map<Id, Document__c> docMap = new Map<Id, Document__c>();
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> leasingOfferDocs = docService.getDocumentsByLeasingOrderId(leasingOrderId);
        Id docId;
        for(Document__c doc : leasingOfferDocs){
            if(doc.Document_Name__c == 'Statement of Account - Full'){
                docId = doc.Id;
            }
        }
        
        if(docId != Null){
            ContentVersion file = new ContentVersion();
            file.Title = contract.Opportunity__r.Account.Name + HYPHEN+SOA;
            file.PathOnClient = contract.Opportunity__r.Account.Name + '_SOA.pdf';
            file.VersionData = pdfBlob;
            if(!test.isRunningTest()){file.FirstPublishLocationId = docId;}
            filesToInsert.add(file);

            ContentService conService = ContentService.getInstance();
            conService.createContentVersion(filesToInsert);

            return file.Id;
        } 
        return null;
    }
    // public static  List<StatementRowWrapper>  prepareData(Id leasingOrderId){
    public List<StatementRowWrapper>  prepareData(Id leasingOrderId, Boolean isPDC, Boolean isSecurity){
        String operator = isPDC ? '>' : '<=';
        Date todayDate = Date.today();

        String soql =
        'SELECT Id, Name, SAPDocumentNumber__c, ' +
        'LeasingOrder__r.LeasingSAPContractId__c, ReceiptDate__c, ' +
        'LeasingOrder__r.Project__r.SAPBusinessEntity__c, Amount__c, ChequeDate__c, ' +
        'LeasingOrder__r.Project__r.SAPEntityName__c, ' +
        'LeasingOrder__r.Unit__r.LeasingUnitNumber__c ' +
        'FROM LeasingReceiptAcknowledgment__c ' +
        'WHERE LeasingOrder__c ='+' \'' + leasingOrderId + '\' ' +
        'AND UnappliedAmount__c != 0' ;
        System.debug('qeury>>' + soql);

    
    

        List<StatementRowWrapper> statementRows = new List<StatementRowWrapper>();
        //  for (LeasingReceiptAcknowledgment__c ack : [SELECT Id, Name,SAPDocumentNumber__c,LeasingOrder__r.LeasingSAPContractId__c,ReceiptDate__c,
        //                                                     LeasingOrder__r.Project__r.SAPBusinessEntity__c ,Amount__c,ChequeDate__c, 
        //                                                     LeasingOrder__r.Project__r.SAPEntityName__c,
        //                                                     LeasingOrder__r.Unit__r.LeasingUnitNumber__c
        //                                                     FROM LeasingReceiptAcknowledgment__c WHERE LeasingOrder__c = :leasingOrderId]) 
        for (LeasingReceiptAcknowledgment__c ack : Database.query(soql))
        {  
            StatementRowWrapper row = new StatementRowWrapper();
            //row.postingDate     = ack.ReceiptDate__c;
            row.postingDateSort = ack.ReceiptDate__c;
            row.postingDate     = formatDate(ack.ReceiptDate__c);
            row.documentNumber  =  ack.SAPDocumentNumber__c != Null && ack.SAPDocumentNumber__c.length() > 11 ? ack.SAPDocumentNumber__c.substring(0, 11) +''+ack.SAPDocumentNumber__c.substring(11) : ack.SAPDocumentNumber__c;
            row.transactionType =  ack.ChequeDate__c > todayDate ? 'PDC' : 'Collection';
            row.invoiceAmount   =  null;
            row.receiptAmount   =  ack.Amount__c;
            totalReceipt += ack.Amount__c;
            row.balanceAmount   = null;
            
            row.contractNumber  = ack.LeasingOrder__r.LeasingSAPContractId__c;
            row.dueDate         = ack.ChequeDate__c != Null ? formatDate(ack.ChequeDate__c) : null;
            row.overdueDays     =  null;
            
            row.text            = null;
            
            row.kBusinessEntity = ack.LeasingOrder__r.Project__r.SAPBusinessEntity__c;
            row.kNameOfBE       = ack.LeasingOrder__r.Project__r.SAPEntityName__c;
            row.kObjectId       = ack.LeasingOrder__r.LeasingSAPContractId__c;
            row.kUnitNumber     = ack.LeasingOrder__r.Unit__r.LeasingUnitNumber__c;
            row.kConditionNo    = null;
            row.kConditionName  = null;
            
            statementRows.add(row);  
        }
        /*for (LeasingReceiptAllocation__c allocation : [SELECT Id, Name,LeasingOrderOtherCharges__c,LeasingOrderOtherCharges__r.PostingDate__c,PaymentPlanSchedule__r.PaymentStartDate__c,
                                                       SAPDocumentNoI__c,LeasingOrderOtherCharges__r.ChargeAmount__c,PaymentPlanSchedule__r.Amount__c ,LeasingReceiptAcknowledgment__r.Amount__c,
                                                       LeasingReceiptAcknowledgment__r.UnappliedAmount__c ,LeasingOrder__r.LeasingSAPContractId__c,LeasingOrderOtherCharges__r.DueDate__c,
                                                       LeasingOrderOtherCharges__r.Name,PaymentPlanSchedule__r.Name,PaymentPlanSchedule__r.DueDate__c,
                                                       LeasingOrder__r.Project__r.SAPBusinessEntity__c ,
                                                       LeasingOrder__r.Project__r.SAPEntityName__c,
                                                       LeasingOrder__r.Unit__r.LeasingUnitNumber__c,ConditionType__c
                                                       FROM LeasingReceiptAllocation__c
                                                       WHERE LeasingOrder__c = :leasingOrderId]) */

       for (PaymentPlanSchedule__c schedules : [SELECT Id,PaymentStartDate__c,PaymentStatus__c, RefDocno__c,Amount__c,LeasingOrder__r.LeasingSAPContractId__c,Schedule_End_Date__c,
                                                LeasingOrder__r.Project__r.SAPBusinessEntity__c,LeasingOrder__r.Project__r.SAPEntityName__c,DueAmount__c,TotalInstallmentAmount__c,
                                                LeasingOrder__r.Unit__r.LeasingUnitNumber__c,SAPConditionTypeCode__c,LeasingOrder__r.Unit__r.PropertyUsage__c
                                                FROM PaymentPlanSchedule__c 
                                                WHERE LeasingOrder__c = :leasingOrderId AND PaymentStatus__c='Un Paid'])
        {  
            StatementRowWrapper row = new StatementRowWrapper();
            //row.postingDate     = allocation.LeasingOrderOtherCharges__c != null ?  allocation.LeasingOrderOtherCharges__r.PostingDate__c : allocation.PaymentPlanSchedule__r.PaymentStartDate__c ;
            row.postingDateSort = schedules.PaymentStartDate__c;
            row.postingDate = schedules.PaymentStartDate__c != null ? formatDate(schedules.PaymentStartDate__c) : null;
            row.documentNumber  = schedules.RefDocno__c != Null && schedules.RefDocno__c.length() > 11 ? schedules.RefDocno__c.substring(0, 11)+''+schedules.RefDocno__c.substring(11) : schedules.RefDocno__c;//allocation.LeasingOrderOtherCharges__c != null ?  allocation.LeasingOrderOtherCharges__r.PostingDate__c : allocation.PaymentPlanSchedule__r.PaymentStartDate__c;
            row.transactionType = 'Invoice';//allocation.LeasingOrderOtherCharges__c != null ?  allocation.LeasingOrderOtherCharges__r.PostingDate__c : allocation.PaymentPlanSchedule__r.PaymentStartDate__c;
            row.invoiceAmount = schedules.TotalInstallmentAmount__c != null ? schedules.TotalInstallmentAmount__c : 0;
            totalInvoice += schedules.TotalInstallmentAmount__c != null ? schedules.TotalInstallmentAmount__c : 0;
            row.receiptAmount   = null;
            row.balanceAmount = schedules.DueAmount__c != null ? schedules.DueAmount__c : 0;
            totalBalance += schedules.DueAmount__c != null ? schedules.DueAmount__c : 0;
            
            row.contractNumber  = schedules.LeasingOrder__r.LeasingSAPContractId__c;
            //row.dueDate         = allocation.LeasingOrderOtherCharges__c != null ?  allocation.LeasingOrderOtherCharges__r.DueDate__c : allocation.PaymentPlanSchedule__r.DueDate__c ;
            //Date dt = allocation.LeasingOrderOtherCharges__c != null ?  (allocation.LeasingOrderOtherCharges__r.DueDate__c) : (allocation.PaymentPlanSchedule__r.DueDate__c) ;
            row.dueDate = schedules.PaymentStartDate__c != null ? formatDate(schedules.PaymentStartDate__c) : null;
            //row.overdueDays     = (row.dueDate < Date.today()) ? row.dueDate.daysBetween(Date.today()) : 0 ;
            row.overdueDays     = 0 ;
            row.text            = '*'+ formatDate(schedules.PaymentStartDate__c)+'-'+formatDate(schedules.Schedule_End_Date__c)+'-Base Rent ';
            row.text            += schedules.LeasingOrder__r.Unit__r.PropertyUsage__c == 'Residential' ? 'Residential' : 'Commercial';
            row.contractNumber  = schedules.LeasingOrder__r?.LeasingSAPContractId__c;
            row.kBusinessEntity = schedules.LeasingOrder__r?.Project__r?.SAPBusinessEntity__c;
            row.kNameOfBE       = schedules.LeasingOrder__r?.Project__r?.SAPEntityName__c;
            row.kUnitNumber     = schedules.LeasingOrder__r?.Unit__r?.LeasingUnitNumber__c;
            row.kConditionNo    = schedules.SAPConditionTypeCode__c ;
            row.kConditionName  = row.text;
            
            statementRows.add(row);  
        }
        String ocsoql = 'Select Id, RefDocno__c, LeasingOrder__r.LeasingSAPContractId__c, DueDate__c,Type__c,LeasingOrder__r.SecurityDeposit__c,'+
                        'LeasingOrder__r.Project__r.SAPBusinessEntity__c, LeasingOrder__r.Unit__r.LeasingUnitNumber__c,'+
                        'LeasingOrder__r.Project__r.SAPEntityName__c,TotalAmount__c,DueAmount__c'+
                        ' FROM LeasingOrdersOtherCharges__c WHERE LeasingOrder__c = '+' \'' + leasingOrderId + '\' '+
                        'AND PaymentStatus__c = \'Un Paid\'';
        if(!isSecurity){
            ocsoql +=  ' AND Type__c Not IN (\'Security Deposit Amount\', \'Additional Security Deposit Amount\', \'Securty Deposit\')';
        }
        // if(isSecurity){
        //     for (LeasingOrdersOtherCharges__c oc : [Select Id, RefDocno__c, LeasingOrder__r.LeasingSAPContractId__c, DueDate__c,Type__c,LeasingOrder__r.SecurityDeposit__c,
        //                                             LeasingOrder__r.Project__r.SAPBusinessEntity__c, LeasingOrder__r.Unit__r.LeasingUnitNumber__c,
        //                                             LeasingOrder__r.Project__r.SAPEntityName__c,TotalAmount__c,DueAmount__c
        //                                             //FROM LeasingOrdersOtherCharges__c WHERE LeasingOrder__c = :leasingOrderId AND Type__c IN ('Security Deposit Amount','Additional Security Deposit Amount', 'Securty Deposit') AND PaymentStatus__c='Unpaid'])
        //                                             FROM LeasingOrdersOtherCharges__c WHERE LeasingOrder__c = :leasingOrderId AND Type__c IN ('Security Deposit Amount','Additional Security Deposit Amount', 'Securty Deposit')])
        //     {  
        for (LeasingOrdersOtherCharges__c oc : Database.query(ocsoql)){
                StatementRowWrapper row = new StatementRowWrapper();
                //row.postingDate     = ack.ReceiptDate__c;
                row.postingDateSort = oc.DueDate__c;
                row.postingDate     = formatDate(oc.DueDate__c);
                row.documentNumber  =  oc.RefDocno__c != Null && oc.RefDocno__c.length() > 11 ? oc.RefDocno__c.substring(0, 11) + ''+oc.RefDocno__c.substring(11) : oc.RefDocno__c;
                //row.transactionType =  'Security Deposit';
                row.transactionType =  oc.Type__c;
                row.invoiceAmount   =  oc.Type__c == 'Additional Security Deposit Amount' ? oc.TotalAmount__c + oc.LeasingOrder__r.SecurityDeposit__c : oc.TotalAmount__c;
                totalInvoice += oc.Type__c == 'Additional Security Deposit Amount' ? oc.TotalAmount__c + oc.LeasingOrder__r.SecurityDeposit__c : oc.TotalAmount__c;
                row.receiptAmount   =  null;
                row.balanceAmount   = oc.DueAmount__c;
                totalBalance += oc.DueAmount__c;
                row.contractNumber  = oc.LeasingOrder__r.LeasingSAPContractId__c;
                row.dueDate         = formatDate(oc.DueDate__c);
                row.overdueDays     =  null;
                
                row.text            = '*'+ formatDate(oc.DueDate__c)+' - '+oc.Type__c;
                
                row.kBusinessEntity = oc.LeasingOrder__r.Project__r.SAPBusinessEntity__c;
                row.kNameOfBE       = oc.LeasingOrder__r.Project__r.SAPEntityName__c;
                row.kObjectId       = oc.LeasingOrder__r.LeasingSAPContractId__c;
                row.kUnitNumber     = oc.LeasingOrder__r.Unit__r.LeasingUnitNumber__c;
                row.kConditionNo    = null;
                row.kConditionName  = null;
                
                statementRows.add(row);  
            }
        

        statementRows.sort(new StatementRowComparator());
        return statementRows ;
    }

    // public static  List<StatementRowWrapper>  prepareSDData(Id leasingOrderId){
    //     List<StatementRowWrapper> statementRows = new List<StatementRowWrapper>();
    //     for (LeasingOrdersOtherCharges__c oc : [Select Id, RefDocno__c, LeasingOrder__r.LeasingSAPContractId__c, DueDate__c,Type__c,LeasingOrder__r.SecurityDeposit__c,
    //                                             LeasingOrder__r.Project__r.SAPBusinessEntity__c, LeasingOrder__r.Unit__r.LeasingUnitNumber__c,
    //                                             LeasingOrder__r.Project__r.SAPEntityName__c,TotalAmount__c,DueAmount__c
    //                                             //FROM LeasingOrdersOtherCharges__c WHERE LeasingOrder__c = :leasingOrderId AND Type__c IN ('Security Deposit Amount','Additional Security Deposit Amount', 'Securty Deposit') AND PaymentStatus__c='Unpaid'])
    //                                             FROM LeasingOrdersOtherCharges__c WHERE LeasingOrder__c = :leasingOrderId AND Type__c IN ('Security Deposit Amount','Additional Security Deposit Amount', 'Securty Deposit')])
    //     {  
    //         StatementRowWrapper row = new StatementRowWrapper();
    //         //row.postingDate     = ack.ReceiptDate__c;
    //         row.postingDateSort = oc.DueDate__c;
    //         row.postingDate     = formatDate(oc.DueDate__c);
    //         row.documentNumber  =  oc.RefDocno__c != Null && oc.RefDocno__c.length() > 11 ? oc.RefDocno__c.substring(0, 11) + ''+oc.RefDocno__c.substring(11) : oc.RefDocno__c;
    //         row.transactionType =  'Security Deposit';
    //         row.invoiceAmount   =  oc.Type__c == 'Additional Security Deposit Amount' ? oc.TotalAmount__c + oc.LeasingOrder__r.SecurityDeposit__c : oc.TotalAmount__c;
    //         row.receiptAmount   =  null;
    //         row.balanceAmount   = oc.DueAmount__c;
            
    //         row.contractNumber  = oc.LeasingOrder__r.LeasingSAPContractId__c;
    //         row.dueDate         = formatDate(oc.DueDate__c);
    //         row.overdueDays     =  null;
            
    //         row.text            = null;
            
    //         row.kBusinessEntity = oc.LeasingOrder__r.Project__r.SAPBusinessEntity__c;
    //         row.kNameOfBE       = oc.LeasingOrder__r.Project__r.SAPEntityName__c;
    //         row.kObjectId       = oc.LeasingOrder__r.LeasingSAPContractId__c;
    //         row.kUnitNumber     = oc.LeasingOrder__r.Unit__r.LeasingUnitNumber__c;
    //         row.kConditionNo    = null;
    //         row.kConditionName  = null;
            
    //         statementRows.add(row);  
    //     }
    //     statementRows.sort(new StatementRowComparator());
    //     return statementRows;
    // }

    public class StatementRowComparator implements Comparator<StatementRowWrapper> {
        public Integer compare(StatementRowWrapper a, StatementRowWrapper b) {

            if(a.postingDateSort == null && b.postingDateSort == null) return 0;
            if(a.postingDateSort == null) return -1;
            if(b.postingDateSort == null) return 1;

            if(a.postingDateSort < b.postingDateSort) return -1;
            if(a.postingDateSort > b.postingDateSort) return 1;

            return 0;
        }
    }

    public class StatementRowWrapper {
        //public Date    postingDate       { get; set; }
        public Date postingDateSort { get; set; } // for sorting
        public String    postingDate       { get; set; }
        public String  documentNumber    { get; set; }
     //   public String  documentType      { get; set; }    
        public String  transactionType   { get; set; }   
        public Decimal invoiceAmount     { get; set; }
        public Decimal receiptAmount     { get; set; }    
        public Decimal balanceAmount     { get; set; }    
        public String  contractNumber    { get; set; }
        //public Date    dueDate           { get; set; }
        public String    dueDate           { get; set; }
        public Integer overdueDays       { get; set; }
        public String  text              { get; set; }
        public String  kBusinessEntity   { get; set; }
        public String  kNameOfBE         { get; set; }
        public String  kObjectId         { get; set; }
        public String  kUnitNumber       { get; set; }
        public String  kConditionNo      { get; set; }
        public String  kConditionName    { get; set; }
    }
}
public class LeasingDocumentsPDFHandler {
    public String totalBalanceInstallment { get; set; }
    public List<PaymentPlanWrapper> paymentPlans { get; set; }
    public List<OtherChargeWrapper> otherCharges { get; set; }
    public Decimal totalInstallmentCollection { get; set;}
    public Decimal totalInstallmentOutStanding { get; set; }
    public Decimal totalOCCollection { get; set;}
    public Decimal totalOCOutStanding { get; set; }
    public String todayDate { get; set; }
    public LeasingOrder__c leasingOrder { get; set; }
    public Decimal totalCollection { get; set; }
    public Decimal totalOutStanding { get; set; }
    public Decimal otherChargesTotal {get; set;}
    private static final string SOA { get { return 'Statement of Account'; } }  
    private static final string HYPHEN { get { return ' - '; } }

    public class PaymentPlanWrapper{
        public String installmentDueDate {get; set;}
        public Integer installmentNumber {get; set;}
        public Decimal formattedAmount {get; set;}
        public String installmentStatus {get; set;}
        public Decimal formattedCollectedAmount {get; set;}
        public Decimal formattedOustandingAmount {get; set;}
        public Decimal installementPercentage {get; set;}
          
    }

    public class OtherChargeWrapper{
        public String otherChargeName {get; set;}
        public String otherChargeDueDate {get; set;}
        public String purpose {get; set;}
        public Decimal formattedAmount {get; set;}
        public String otherChargeStatus {get; set;}
        public Decimal formattedCollectedAmount {get; set;} 
        public Decimal formattedPendingAmount {get; set;}
    }
    

    public LeasingDocumentsPDFHandler() {
        String leasingOrderId = ApexPages.currentPage().getParameters().get('id');
        List<LeasingOrder__c> leasingOrders = getLeasingorderDetailIfo(leasingOrderId);
        leasingOrder = leasingOrders[0];
        paymentPlans = new List<PaymentPlanWrapper>();
        otherCharges = new List<OtherChargeWrapper>();
        Integer installmentNumber = 1;
        Decimal totalAmount = leasingOrders[0].RentalAmountAfterDiscount__c;
        totalInstallmentOutStanding = 0;
        totalInstallmentCollection = 0;
        totalOCCollection = 0;
        totalOCOutStanding = 0;
        totalCollection = 0;
        totalOutStanding = 0;
        otherChargesTotal = 0;
        for(PaymentPlanSchedule__c pps : leasingOrders[0].Payment_Plan_Schedules__r){
            PaymentPlanWrapper ppw = new PaymentPlanWrapper();
            ppw.installmentDueDate = formatDate(pps.DueDate__c);
            ppw.installmentNumber = installmentNumber;
            ppw.formattedAmount = pps.TotalInstallmentAmount__c;
            ppw.installmentStatus = '';
            ppw.formattedCollectedAmount = pps.ClearedAmount__c != Null ? pps.ClearedAmount__c : 0;
            ppw.formattedOustandingAmount = pps.DueAmount__c;
            if(pps.DueAmount__c == 0)
            ppw.installmentStatus = 'Cleared';
            ppw.installementPercentage = (pps.TotalInstallmentAmount__c/totalAmount)*100;
            totalInstallmentCollection += pps.ClearedAmount__c != Null ? pps.ClearedAmount__c : 0;
            totalInstallmentOutStanding += pps.DueAmount__c;
            paymentPlans.add(ppw);
            installmentNumber ++;
        }

        for(LeasingOrdersOtherCharges__c loc : leasingOrders[0].Leasing_Orders_Other_Charges__r){
            OtherChargeWrapper ocw = new OtherChargeWrapper();
            ocw.otherChargeName = loc.Name;
            ocw.otherChargeDueDate = formatDate(loc.Duedate__c);
            ocw.purpose = loc.Type__c;
            ocw.formattedAmount = loc.TotalAmount__c;
            ocw.otherChargeStatus = '';
          //  ocw.formattedCollectedAmount = loc.ClearedAmount__c != Null ? loc.ClearedAmount__c : 0;
            //ocw.formattedPendingAmount = loc.DueAmount__c;
            //if(loc.DueAmount__c == 0)
            ocw.otherChargeStatus = 'Cleared';
            
          //  totalOCCollection += loc.ClearedAmount__c != Null ? loc.ClearedAmount__c : 0;
            //totalOCOutStanding += loc.DueAmount__c;
            otherCharges.add(ocw);
            otherChargesTotal += loc.TotalAmount__c;
        }

        todayDate = DateTime.now().format('dd-MMM-yy');
        totalCollection = totalInstallmentCollection +  totalOCCollection;
        totalOutStanding = totalInstallmentOutStanding + totalOCOutStanding;


    }
    public static String formatDate(Date inputDate) {
        if (inputDate != null) {
            return DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day()).format('dd-MMM-yy');
        }
        return '';
    }

    public static List<LeasingOrder__c> getLeasingorderDetailIfo(Id leasingOrderId) {
        return [
            SELECT Id, LeasingOrderNumber__c,Unit__r.UnitModel__c,Unit__r.ProjectName__c,Unit__r.UnitNumber__c,
            Unit__r.UnitType__c,Account__r.PersonEmail,Account__r.PersonMailingPostalCode,
            Account__r.Name,Account__r.PersonMobilePhone,Account__r.AccountNumber__c,Account__r.MobileCountryCode__c,
            Account__r.PersonMailingCity,Account__r.PersonMailingCountry,Name,Account__r.PersonMailingState,
            Account__r.PersonMailingStreet,Unit__r.BuildingSectionName__r.Name,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BranchCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c, RentalAmountAfterDiscount__c,
            (SELECT Id, DueDate__c, ClearedAmount__c, DueAmount__c, TotalInstallmentAmount__c
            FROM Payment_Plan_Schedules__r 
            ORDER BY ID ASC),
            (SELECT Id, Duedate__c, ClearedAmount__c/*, DueAmount__c*/, Type__c,Name, TotalAmount__c
            FROM Leasing_Orders_Other_Charges__r
            ORDER BY ID ASC),
            (SELECT Id, PaymentPlanSchedule__c, PaymentPlanSchedule__r.DueDate__c, PaymentPlanSchedule__r.ClearedAmount__c, 
            PaymentPlanSchedule__r.DueAmount__c, LeasingOrderOtherCharges__c, LeasingOrderOtherCharges__r.ClearedAmount__c, 
            /*LeasingOrderOtherCharges__r.DueAmount__c,*/ LeasingOrderOtherCharges__r.DueDate__c
            FROM LeasingReceiptAllocations__r)
            FROM LeasingOrder__c  
            WHERE Id = :leasingOrderId
        ];
    }

    @AuraEnabled
    public static String generateAndAttachPdf(Id leasingOrderId) {
        List<LeasingOrder__c> leasingOrders = getLeasingorderDetailIfo(leasingOrderId);
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        String soNumber = leasingOrders[0].Name;
        String statementFileName = 'Statement'+'-'+leasingOrders[0].Name;
        PageReference pdfPage;
       
        pdfPage = Page.LeasingStatementOfAccountPDF; // Replace with your VF page name
        pdfPage.getParameters().put('id', leasingOrderId);
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // Return a mock Blob in test context
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            // Actual getContent() call outside test context
            pdfBlob = pdfPage.getContent();
        }
        
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        
        Map<Id, Document__c> docMap = new Map<Id, Document__c>();
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> leasingOfferDocs = docService.getDocumentsByLeasingOrderId(leasingOrderId);
        Id docId;
        for(Document__c doc : leasingOfferDocs){
            if(doc.Document_Name__c == 'Statement of Account'){
                docId = doc.Id;
            }
        }
        // ContentVersion cv = new ContentVersion();
        // cv.Title = statementFileName;
        // cv.PathOnClient = 'ReceiptAcknowledgment.pdf';
        // cv.VersionData = pdfBlob;
        // cv.IsMajorVersion = true;
        // insert cv;
        
        // ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        // ContentDocumentLink cdl = new ContentDocumentLink();
        // cdl.ContentDocumentId = insertedCV.ContentDocumentId;
        // cdl.LinkedEntityId = leasingOrderId;
        // cdl.ShareType = 'V';
        // cdl.Visibility = 'AllUsers';
        
        // insert cdl;
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
}
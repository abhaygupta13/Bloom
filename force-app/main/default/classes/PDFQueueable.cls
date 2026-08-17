/*****************************************************************************************
Class       : PDFQueueable
Author      : Vikas Baliyan
Description : Broker Form PDF Creation Queueable
Test Class  : 
Created Date: 12 DEC 2024 
*****************************************************************************************/
public without sharing class PDFQueueable implements Queueable, Database.AllowsCallouts {
    private static final string COMMISSION_INVOICE_BELL_NOTIFY_USERS { get { return 'CommissionInvoiceBellNotifyUsers'; } }
    private static final string GENERATED_INVOICE = 'Generated Invoice';
    private List<Sobject> sobjList;
    private Schema.SObjectType sObjType;
    private string documentType;
    
    public PDFQueueable(List<Sobject> sobjList, Schema.SObjectType sObjType, string documentType) {
        this.sobjList = sobjList;
        this.sObjType = sObjType;
        this.documentType = documentType;
    }
    
    public void execute(QueueableContext context) {
        if(BrokerCommission__c.SObjectType == this.sObjType && documentType == 'Broker Form'){
            createBrokerFormPDF((List<BrokerCommission__c>)this.sobjList);
        }else if(BrokerCommission__c.SObjectType == this.sObjType && documentType == 'Broker Invoice'){
            createInvoicePDF((List<BrokerCommission__c>)this.sobjList);
        }
    }

    private static void createInvoicePDF(List<BrokerCommission__c> brokerCommissionList) {  
        ContentService conService = ContentService.getInstance();
        BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
        List<ContentVersion> cvList = new List<ContentVersion>();
        //Content Version Title to Invoice Id Map
        Map<String, String> cvTitleToInvoiceIdMap = new Map<String, String>();
        List<BrokerCommission__c> brokerCommiList = objBrokerCommissionServ.getBrokerCommissionById(brokerCommissionList);
        
        try{
            for(BrokerCommission__c bc : brokerCommiList){
                Blob pdfBlob;      
                if (Test.isRunningTest()){
                    // Return a mock blob during tests
                    pdfBlob = Blob.valueOf('Mock PDF Content');
                } else {
                    PageReference vfPage = Page.CommissionInvoicePDFGenerator;
                    vfPage.getParameters().put('brokerCommissionId', bc.Id);
                    pdfBlob = vfPage.getContent();
                }
                // Create a new ContentVersion to store the PDF
                ContentVersion cv = conService.CreateContentVersionObj('Commission Invoice - '+bc.Name, 'CommissionInvoice_'+bc.Name + '.pdf', pdfBlob, 'H');
                cvTitleToInvoiceIdMap.put(cv.Title, bc.Id);
                cvList.add(cv);
            }    

            BrokerCommissionController.attachDocument(null, brokerCommiList,GENERATED_INVOICE, cvTitleToInvoiceIdMap, cvList);  
            
            //CommissionInvoiceBellNotifyUsers
            MetadataService objMetadataService = MetadataService.getInstance();
            String userToNotify = objMetadataService.getAppSettingTextValue(COMMISSION_INVOICE_BELL_NOTIFY_USERS);

            //Fetch users to send bell notification
            Set<String> userToNotifySet = new Set<String>();
            userToNotifySet.addAll(userToNotify.split(','));

            //Send bell notification 
            for(BrokerCommission__c bc : brokerCommiList){
                NotificationService.sendBellNotification(userToNotifySet, bc.Id); 
            }
        }
        catch(Exception ex){
            System.debug(ex);
            System.debug(ex.getMessage());
        }
    }

    private static void createBrokerFormPDF(List<BrokerCommission__c> brokerCommissionList){
        BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
        try{
            List<ContentVersion> cvList = new List<ContentVersion>();
            ContentService conService = ContentService.getInstance();
            List<BrokerCommission__c> brokerCommiList = objBrokerCommissionServ.getBrokerCommissionById(brokerCommissionList);
            //Content Version Title to Invoice Id Map
            Map<String, String> cvTitleToInvoiceIdMap = new Map<String, String>();
            for(BrokerCommission__c bc : brokerCommiList){
                Blob pdfBlob;      
                if (Test.isRunningTest()){
                    // Return a mock blob during tests
                    pdfBlob = Blob.valueOf('Mock PDF Content');
                } else {
                    PageReference vfPage = Page.BrokerFormPDFGenerator;
                    vfPage.getParameters().put('brokerCommissionId', bc.Id);
                    pdfBlob = vfPage.getContent();
                }
                // Create a new ContentVersion to store the PDF
                ContentVersion cv = conService.CreateContentVersionObj('Broker Form - '+bc.Name, 'Broker Form_'+bc.Name + '.pdf', pdfBlob, 'H');
                
                cvTitleToInvoiceIdMap.put(cv.Title, bc.Id);
                cvList.add(cv);
            }   

            BrokerCommissionController.attachDocument(null, brokerCommiList,Constants.BROKER_FORM, cvTitleToInvoiceIdMap, cvList);            
            
        }
        catch(Exception ex){
            System.debug(ex);
            System.debug(ex.getMessage()); 
        }
    }
}
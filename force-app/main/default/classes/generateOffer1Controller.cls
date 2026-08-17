public class generateOffer1Controller {
    private static final string OFFER_LETTER { get { return 'Offer Letter 1'; } }  
    private static final string HYPHEN { get { return ' - '; } }
    private static final string COMMERCIAL_TYPE { get { return 'Commercial'; } } 
    private static final string RESIDENTIAL_TYPE { get { return 'Residential'; } } 
    
    @AuraEnabled
    public static Id generatePDF(Id contractId) {
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        System.debug('145 generatePDF :- ' + contractId);
        PageReference pdfPage ;
        Set<Id> contractIds=new Set<Id>();
        contractIds.add(contractId);
        Map<Id, Document__c> docMap = new Map<Id, Document__c>();
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        
        Map<Id, LeasingOrder__c> contractMap = new Map<Id, LeasingOrder__c>(leasingService.getLeasingOrdersByIds(contractIds));
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> leasingOfferDocs = docService.getLeasingOfferDocumentsByContractIds(contractIds);
        for (Document__c doc : leasingOfferDocs){
            docMap.put(doc.LeasingOrder__c, doc);
        }
        for (Id contractIdss : contractIds) {
            LeasingOrder__c contract = contractMap.get(contractIdss);
            Document__c doc = docMap.get(contractIdss);
            if(contract.Unit__r.PropertyUsage__c == COMMERCIAL_TYPE){
                pdfPage = Page.CommercialGenrateOffer;
            }else if(contract.Unit__r.PropertyUsage__c == RESIDENTIAL_TYPE){
                pdfPage = Page.CommercialGenrateOffer;//ResidentialGenrateOffer
            }else {
                System.debug('80 generateApprovedLeasingOffer skipped usage :- ' + (contract != null ? contract.Unit__r?.PropertyUsage__c : 'null'));
                return null;
            }
            pdfPage.getParameters().put('id', contractId);
            System.debug('83 generateApprovedLeasingOffer page :- ' + pdfPage.getUrl());
            Blob pdfBlob;
            if(!Test.isRunningTest()){
                pdfBlob = pdfPage.getContent();
            }
            else{
                pdfBlob = blob.valueof('test');
            }
            ContentVersion file = new ContentVersion();
            file.Title = contract.Opportunity__r.Account.Name + HYPHEN+OFFER_LETTER;
            file.PathOnClient = contract.Opportunity__r.Account.Name + '_OfferLetter.pdf';
            file.VersionData = pdfBlob;
            if(!test.isRunningTest()){file.FirstPublishLocationId = doc.Id;}
            filesToInsert.add(file); 
        }
        if(!filesToInsert.isEmpty())
            insert filesToInsert;
        return contractId;
    }
}
/***
Class       : Class Name
Author      : Smaartt
Description : 
TestClass   : OfferDetailsPDFHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              20/07/23           Initial Version 
****************************************************************************************************************/

public with sharing class OfferDetailsPDFHandler {
    public SalesOfferUtilityHandler.SalesOfferDetails offerDetails {get; set;}
    public string todayDate {get; set;}
    public string customerName {get; set;}
    public string floorPlanLink {get; set;}
    public string WebfloorPlanLink {get; set;}
    public string affectionPlanLink {get; set;}
    public string markettingPlanLink {get; set;}
    public boolean showAffectionPlanLink {get; set;}
    public boolean showMarketingPlanLink {get; set;}
    public boolean showVatNote {get; set;}
    public string brochureURL {get; set;}
    public decimal sqftInternal {get; set;}
    public decimal sqftExternal {get; set;}
    public decimal sqftGross {get; set;}
    public List<Opportunity> OppList { get; set; }
    
    
    public OfferDetailsPDFHandler(){
        String currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
        String selectedDesign = ApexPages.currentPage().getParameters().get('selectedDesign');
        String opportunityId = ApexPages.currentPage().getParameters().get('id');
        String currentOffer = ApexPages.currentPage().getParameters().get('currentOffer');
        String otherUnits = ApexPages.currentPage().getParameters().get('otherUnits');
        String selectedPayments = ApexPages.currentPage().getParameters().get('selectedPayments');
        String multiPurposeAmount = ApexPages.currentPage().getParameters().get('multiPurposeAmount'); 
        String affectionPlan = ApexPages.currentPage().getParameters().get('affectionPlan');
        String marketingPlan = ApexPages.currentPage().getParameters().get('marketingPlan');
        customerName = ApexPages.currentPage().getParameters().get('customerName');
        String finishingtypeValue = ApexPages.currentPage().getParameters().get('finishingtypeValues');
        showVatNote = false;
        
        if(currentUnit!=null && currentUnit!=''){
            list<SalesOfferUtilityHandler.SaleOfferInputParam> params = new list<SalesOfferUtilityHandler.SaleOfferInputParam>();
            
            //Current Unit
            SalesOfferUtilityHandler.SaleOfferInputParam tempParamObj = new SalesOfferUtilityHandler.SaleOfferInputParam();
            tempParamObj.unitId = currentUnit;
            System.debug('currentOffer'+currentOffer);
            try {
                tempParamObj.offerId = (currentOffer != null && currentOffer.trim() != '' && currentOffer.length() == 15 || currentOffer.length() == 18) ? currentOffer : null;
            } catch (Exception e) {
                System.debug('Error assigning offerId: ' + e.getMessage());
                tempParamObj.offerId = null;
            }
            
            tempParamObj.designId=(selectedDesign!=null && selectedDesign!='' )? selectedDesign : null;
            tempParamObj.selectedPayments = new list<Id>();
            tempParamObj.finishingtypeValue = finishingtypeValue;
            tempParamObj.multiPurposeAmountApplicable = (multiPurposeAmount !=null &&  multiPurposeAmount!='' && multiPurposeAmount.equalsIgnoreCase('true'))?true:false; 
            showAffectionPlanLink = (affectionPlan !=null &&  affectionPlan!='' && affectionPlan.equalsIgnoreCase('false'))?false:true;
            showMarketingPlanLink = (marketingPlan !=null &&  marketingPlan!='' && marketingPlan.equalsIgnoreCase('false'))?false:true;
            if(selectedPayments!=null && selectedPayments!='' ){
                for(Id str: selectedPayments.split('\\|')){
                    if(str!=null){
                        tempParamObj.selectedPayments.add(str);
                    }
                }
            }
            params.add(tempParamObj);
            System.debug('params'+params);
            offerDetails = OpportunityUnitSearchHandler.generateSalesOffer(params,opportunityId,null).get(currentUnit);
            System.debug('testpayplan'+offerDetails);
            sqftInternal= offerDetails.unitRecord.Internal_Saleable_Area__c != NULL ? (offerDetails.unitRecord.Internal_Saleable_Area__c*10.764).setscale(2) : 0;
            sqftExternal= offerDetails.unitRecord.External_Saleable_Area__c != NULL ? (offerDetails.unitRecord.External_Saleable_Area__c*10.764).setscale(2) : 0;
            sqftGross= offerDetails.unitRecord.SaleableArea__c != NULL ? (offerDetails.unitRecord.SaleableArea__c*10.764).setscale(2) : 0;
            if (offerDetails.unitRecord.BuildingSectionName__r != null && offerDetails.unitRecord.BuildingSectionName__r.TaxPercentage__c != null) {
                showVatNote = offerDetails.unitRecord.BuildingSectionName__r.TaxPercentage__c > 0;
            }
            
            todayDate = System.today().format();
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+'Offer-'+offerDetails.unitRecord.Name+'-'+customerName+'-'+todayDate+'.pdf');
            getBrochureLink(); //call function to get the brochure URL
            getOppDetails();
            getDocumentInfo();
        }
        
    }
    
    public void getDocumentInfo(){  
        String currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
        List<Unit__c>unitList = [select id,AffectionPlanCVId__c,WebFloorPlanCVId__c,MarkettingPlanCVId__c from Unit__c where id =:currentUnit];  
        if(unitList[0].WebFloorPlanCVId__c!=null){
            WebfloorPlanLink = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId='+unitList[0].WebFloorPlanCVId__c;
            system.debug('web floor plan '+ WebfloorPlanLink);
        }
        if(unitList[0].MarkettingPlanCVId__c!=null){
            markettingPlanLink = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId='+unitList[0].MarkettingPlanCVId__c;
        }
        if(unitList[0].AffectionPlanCVId__c!=null){
            affectionPlanLink  = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId='+unitList[0].AffectionPlanCVId__c;
        }
        
    }
    
    
    //function to get Brochure URL
    public void getBrochureLink(){
        String currentUnit = ApexPages.currentPage().getParameters().get('currentUnit');
        list<Unit__c>unitList=new list<Unit__c>();
        unitList=[select id,name,BuildingSectionName__r.Brochure_URL__c from Unit__c where id=:currentUnit];
        if(unitList[0].BuildingSectionName__r.Brochure_URL__c!=null){
            brochureURL=unitList[0].BuildingSectionName__r.Brochure_URL__c;
        }
    }
    
    public void getOppDetails(){
        String opportunityId = ApexPages.currentPage().getParameters().get('id');
        OppList=[select id,name,Account.Name,Account.PassportNumber__pc,OpportunityNumber__c,Account.Nationality__c,Account.Emirates_Id__pc,Account.PersonMobilePhone,Account.PersonEmail,LeadSource,BrokerAgencyAccount__r.Name from Opportunity where id=:opportunityId];
        
    }
    
}
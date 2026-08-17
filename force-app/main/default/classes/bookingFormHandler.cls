/***
Class       : bookingFormHandler
Author      : Smaartt
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0           06/09/23           Initial Version 
****************************************************************************************************************/

public with sharing class bookingFormHandler {
    public SalesOfferUtilityHandler.SalesOfferDetails offerDetails {get; set;}
    public string todayDate {get; set;}
    public string customerName {get; set;}
    public decimal Total {get; set;}
    public List<Opportunity> OppList { get; set; }
    public List<Unit__c> UnitList { get; set; }
    public Map<id,String> paymentplanNameMap{ get; set; }
    public Map<id,String> paymentplanDescriptionMap{ get; set; }
    public Map<String,String>unitVspaymentMap{get; set;}
    
    
    public bookingFormHandler(){
        paymentplanNameMap = new Map<Id, String>();
        paymentplanDescriptionMap=new Map<Id, String>();
        unitVspaymentMap=new Map<String,String>();
        boolean isValueAlreadyAdded=false;
        String selectedUnits=ApexPages.currentPage().getParameters().get('selectedUnits');
        Total=0;
        List<Id>selectedUnitsList=new List<Id>();
        if(selectedUnits!=null && selectedUnits!='' ){
            for(Id str: selectedUnits.split(',')){
                if(str!=null){
                    selectedUnitsList.add(str);
                }
            }
        }
        String opportunityId = ApexPages.currentPage().getParameters().get('id');
        
        String currentOffer = ApexPages.currentPage().getParameters().get('currentOffer');
        List<Id>selectedOffers=new List<Id>();
        if(currentOffer!=null && currentOffer!='' ){
            for(Id str: currentOffer.split(',')){
                if(str!=null){
                    selectedOffers.add(str);
                }
            }
        }
        
        String selectedPayments = ApexPages.currentPage().getParameters().get('selectedPayments');
        customerName = ApexPages.currentPage().getParameters().get('customerName');
        
        String jsonString =ApexPages.currentPage().getParameters().get('unitVsPaymentMap'); 
        List<UnitVsPayment> unitVsPaymentList = (List<UnitVsPayment>)JSON.deserialize(jsonString, List<UnitVsPayment>.class);
        for(UnitVsPayment item:unitVsPaymentList){
            unitVspaymentMap.put(item.unitId,item.paymentId);
        }
        List<PaymentPlan__c>paymentPlanList=[select id,Name,Description__c from PaymentPlan__c where id IN:unitVspaymentMap.Values()];
        
        for(Id strUNitId: selectedUnitsList){
            
            list<SalesOfferUtilityHandler.SaleOfferInputParam> params = new list<SalesOfferUtilityHandler.SaleOfferInputParam>();
            String desiredPaymentPlanId=unitVspaymentMap.get(strUNitId);
            
            //Current Unit
            SalesOfferUtilityHandler.SaleOfferInputParam tempParamObj = new SalesOfferUtilityHandler.SaleOfferInputParam();
            tempParamObj.unitId =strUNitId;
            tempParamObj.offerId = selectedOffers.size()>0 ? selectedOffers[0] : null;
            tempParamObj.selectedPayments = new list<Id>();
            
            if(selectedPayments!=null && selectedPayments!='' ){
                for(Id str: selectedPayments.split('\\|')){
                    if(str!=null){
                        tempParamObj.selectedPayments.add(str);
                    }
                }
            }
            params.add(tempParamObj);
            offerDetails = OpportunityUnitSearchHandler.generateSalesOffer(params,opportunityId, 1).get(strUNitId);
            
            for (PaymentPlan__c paymentPlan : paymentPlanList) {
                if (paymentPlan.Id == desiredPaymentPlanId) {
                    
                    paymentplanNameMap.put(strUNitId,paymentPlan.Name);
                    paymentplanDescriptionMap.put(strUNitId,paymentPlan.Description__c);
                    break; 
                }
            }
            decimal Discount;
            decimal finalPrice;
            if(offerDetails.applicablePaymentPlansCalculated.size()>0){
                Discount=offerDetails.unitRecord.SellingPrice__c-offerDetails.applicablePaymentPlansCalculated[0].discountedUnitSalesPrice;
                finalPrice=offerDetails.unitRecord.SellingPrice__c-Discount;
                Total=Total+finalPrice;
            }    
            
            todayDate = System.today().format();
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+'BookingAgreement-'+offerDetails.unitRecord.Name+'-'+customerName+'-'+todayDate+'.pdf');
            getOppDetails();
            getUnitDetails(selectedUnitsList);
        }
        
    }
    
    public void getOppDetails(){
        String opportunityId = ApexPages.currentPage().getParameters().get('id');
        OppList=[select id,name,Account.Name,Account.PassportNumber__pc,Account.MobileCountryCode__pc,BrokerAgentContact__r.Name,OpportunityNumber__c,Account.Nationality__c,Account.Emirates_Id__pc,Account.PersonMobilePhone,Account.PersonEmail,LeadSource,BrokerAgencyAccount__r.Name from Opportunity where id=:opportunityId];
        
    }
    
    public void getUnitDetails(List<Id>selectedUnitsList){
        UnitList=[select id,name,NumberOfBedrooms__c,UnitNumber__c,currencyISOCOde,SellingPrice__c,UnitType__c from Unit__c where id IN:selectedUnitsList];
    }
    
    public class UnitVsPayment {
        public String unitId { get; set; }
        public String paymentId { get; set; }
    }
    
}
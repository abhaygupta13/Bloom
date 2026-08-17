/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Unit Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
* 3.0			Dhanraj		30MAR2026		 Added Direct/Indirect changes
*****************************************************************************************************/
public inherited sharing class OfferService {
    
    private static OfferService instance;
    
    public OfferService() {}
    
    public static OfferService getInstance() {
        if(instance == null) {
            instance = new OfferService();
        }
        return instance;
    }
    
    public List<OffersPromotions__c> getOffersByProjectId(Id projectId){
        return [SELECT Id, Name FROM OffersPromotions__c WHERE Project__c = :projectId ORDER BY Name];
    }
    
    public List<OffersPromotions__c> getOffers(Id projectId, String customerType, String directType){
        return [SELECT Id, Name FROM OffersPromotions__c WHERE Project__c = :projectId 
                AND Customer_Sub_Type__c = :customerType AND Direct_Indirect__c = :directType AND IsActive__c = true ORDER BY Name];
    }
}
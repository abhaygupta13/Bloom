/***
Class       : OfferLinesService 
Author      : Smaartt
Description : 
TestClass   : OfferLinesServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/

public with sharing class OfferLinesService {
  @AuraEnabled(cacheable=false)
  public static List<OfferLines__c> getOfferLinesQuery(String query) {
  List<OfferLines__c> records = Database.query(query);
  return records;
}
/*
@AuraEnabled(cacheable=false)
public static void insertOfferLines(List<MemoLines__c> memoLinesList, Id offerId){

  List<OfferLines__c> offerLinesList = new List<OfferLines__c>();
  String offerPromotionId;
  String fieldApi;
  Map<String,OfferLinesService__mdt> OfferLineServiceMap = Utilities.getOfferLineService();


  for (Integer i = 0; i < memoLinesList.size(); i++) {
    offerPromotionId = OffersPromotionsService.lastCreatedIdOffersPromotions(memoLinesList[i].BookingMemo__c,memoLinesList[i].Unit__c);
    
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
}*/
/* commented by antriksh
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
}*/
}
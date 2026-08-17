/*
* @Author: Shruti Kulkarni
* @CreatedDate: 4th Dec 2025
* @Description: Class created to build and utilize the generic methods needed for any RFI creation/updating/Query functionality
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Shruti Kulkarni    4th DEC 2025     Initial Draft
*****************************************************************************************************/
public class RFIService {
    
    private RFIService() {
        
    }
    
    private static RFIService instance;
    
    public static RFIService getInstance() {
        if (instance == null) {
            instance = new RFIService();
        }
        return instance;
    }
    
    /**
    * Update RFI record 
    * @param RFI record list to be updated
    * @return The updated RFI.
    */
    public List<RFI__c> updateRFIRecords(List<RFI__c> rfiList){
        if(rfiList != NULL && !rfiList.isEmpty()){
            update rfiList;
        }
        return rfiList;
    }

}
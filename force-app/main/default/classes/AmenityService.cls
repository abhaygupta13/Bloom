/**
 * AmenityService
 * Layer: Service / Selector
 * Purpose: Centralize SOQL for Amenities__c.
 *
 * Notes:
 *  - Logic preserved exactly as provided (dynamic SOQL assembly unchanged).
 *  - Singleton pattern for reuse.
 *  - Read-only selector; no DML.
 * Last Reviewed: 2025-09-01
 */
public inherited sharing class AmenityService {
    
    private static AmenityService instance;
    
    private AmenityService() {
    }
    
    public static AmenityService getInstance() {
        if (instance == null) {
            instance = new AmenityService();
        }
        return instance;
    }
    
    /**
     * Fetch amenities by Project Id and optional userType (INCLUDES).
     * Logic intentionally unchanged from original.
     */
    public List<Amenities__c> fetchAmenityByProjectId(Id projectId, String userType){
        
        String query = 'SELECT termsAndConditions__c, Name, userAccess__c,Type__c,bookingFee__c, isPaid__c  ' +
            'FROM Amenities__c';
        
        if(!String.isBlank(projectId)){
            query += ' WHERE Project__c = :projectId AND isReservation__c =true';
        }
        
        if(!String.isBlank(userType)){
            query += ' AND userAccess__c INCLUDES (\'' + String.escapeSingleQuotes(userType) + '\')';
        }
        query+=' ORDER BY Name';
        return Database.query(query);
    }

    /**
     * Fetch amenity by Id with booking config fields.
     * Logic intentionally unchanged from original.
     */
    public List<Amenities__c> fetchAmenityById(String amenityId){
        return [
            SELECT dailyStartTime__c,dailyEndTime__c, Name,slotDurationInMinutes__c,isPaid__c,bookingFee__c
            FROM Amenities__c  where Id=:amenityId
        ];
    }
}
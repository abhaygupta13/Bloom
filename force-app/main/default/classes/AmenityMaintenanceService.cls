/**
 * AmenityMaintenanceService
 * Layer: Service / Selector
 * Purpose: Centralize SOQL for AmenityMaintenance__c to fetch maintenance slots by date range.
 *
 * Key Behavior:
 *  - Returns maintenance windows for a single Amenity between today and the provided end date (inclusive).
 *
 * Sharing: without sharing (service-level selector; consumers control access).
 * SOQL/DML Location: Read-only SOQL here; no DML.
 * Bulkification: Single-amenity query; callers should invoke per amenity as needed.
 * Last Reviewed: 2025-09-01
 */
public inherited sharing class AmenityMaintenanceService {

    private static AmenityMaintenanceService instance;
    private AmenityMaintenanceService() {}
    public static AmenityMaintenanceService getInstance() {
        if (instance == null) instance = new AmenityMaintenanceService();
        return instance;
    }

    /**
     * Fetch maintenance entries for an Amenity__c between today and endDate (inclusive).
     * @param amenityId Amenity__c Id (required)
     * @param endDate   Upper-bound date (required). If null or before today, returns empty list.
     * @return List<AmenityMaintenance__c> with fields: maintenanceDate__c, startTime__c, durationHours__c
     */
    public List<AmenityMaintenance__c> fetchMaintenanceDateRange(Id amenityId, Date endDate) {
        Date today = Date.today();
        if (amenityId == null || endDate == null || endDate < today) {
            return new List<AmenityMaintenance__c>();
        }

        return [
            SELECT maintenanceDate__c, startTime__c, durationHours__c
            FROM AmenityMaintenance__c
            WHERE Amenities__c = :amenityId
              AND maintenanceDate__c >= :today
              AND maintenanceDate__c <= :endDate
            ORDER BY maintenanceDate__c ASC, startTime__c ASC
        ];
    }
}
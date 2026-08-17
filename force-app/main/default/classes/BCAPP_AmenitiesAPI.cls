/**
 * Class: BCAPP_AmenitiesAPI
 * Purpose: REST API controller for Amenity-related operations such as fetching amenities,
 *          available dates/slots, and booking/canceling amenity slots.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: /services/apexrest/v1/amenities/*
 * - Supports the following URIs:
 *      • /v1/amenities/get-request
 *      • /v1/amenities/booking-requests
 * - Expects JSON payload with a "requestType" key and other required parameters.
 * - No SOQL/DML here. Delegates all logic to BCAPP_AmenityBookingService.
 */
@RestResource(urlMapping='/v1/amenities/*')
global with sharing class BCAPP_AmenitiesAPI {
    
    /**
     * Entry point for POST requests to the Amenities API.
     * Routes requests based on the URI (get-request, booking-requests) and requestType.
     *
     * @requestBody JSON -> Map<String,Object> containing requestType and other parameters.
     * @behavior    Delegates to appropriate methods in BCAPP_AmenityBookingService.
     */
    @HttpPost
    global static void amenities() {
        RestRequest req = RestContext.request;
        Map<String, Object> reqMap = 
            (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());

        String requestType = (String) reqMap.get('requestType');

        switch on req.requestURI.substringAfterLast('/') {
            
            // ---- Fetch amenity details ----
            when 'get-request' {
                if (String.isBlank(requestType)) {
                    Map<String, Object> response = new Map<String, Object>{ 
                        'errorMessage' => 'Missing requestType' 
                    };
                    BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                    return;
                }
                
                if (requestType == 'aminities') {
                    BCAPP_AmenityBookingService.getAmenitiesByProject(reqMap);
                } else if (requestType == 'aminityDates') {
                    BCAPP_AmenityBookingService.getAvailableDatesByMonth(reqMap);
                } else if (requestType == 'amenitySlotsByDate') {
                    BCAPP_AmenityBookingService.getSlotsForDate(reqMap, false);
                } else if (requestType == 'bookings') {
                    BCAPP_AmenityBookingService.getAmenityBookings(reqMap);
                } else if(requestType == 'validateaminities') {
                    BCAPP_AmenityBookingService.validateAminities(reqMap);
                } else {
                    Map<String, Object> response = new Map<String, Object>{ 
                        'errorMessage' => 'Unsupported requestType: ' + requestType 
                    };
                    BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                }
            }

            // ---- Handle booking operations ----
            when 'booking-requests' {
                if (requestType == 'create') {
                    BCAPP_AmenityBookingService.bookAmenitySlot(reqMap, false);
                } else if (requestType == 'cancel') {
                    BCAPP_AmenityBookingService.cancelBlloking(reqMap);
                } else {
                    Map<String, Object> response = new Map<String, Object>{ 
                        'errorMessage' => 'Unsupported booking requestType: ' + requestType 
                    };
                    BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                }
            }
        }
    }
}
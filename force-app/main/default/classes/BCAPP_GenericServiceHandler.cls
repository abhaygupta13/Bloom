/**
 * Generic Service Handler to route based on service and serviceType
 */
public without sharing class BCAPP_GenericServiceHandler {
    
    public static void handleSubmitRequest(Map<String, Object> reqMap) {
        String requestType = (String) reqMap.get('requestType');
        if (String.isBlank(requestType)) {
            Map<String, Object> response = new Map<String, Object>{ 'errorMessage' => 'Missing requestType' };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }

        if (requestType == 'accesscardrequest') { BCAPP_AccessCardServiceHandler.handleSubmit(reqMap);
        } else if (requestType == 'guestrequest') { BCAPP_GeneralServiceRequestHelper.manageGuestRequest(JSON.serialize(reqMap)); 
        } else if (requestType == 'vacationrequest') { BCAPP_WebServiceHelper.createVacationRequest(JSON.serialize(reqMap));
        } else {
            Map<String, Object> response = new Map<String, Object>{ 'errorMessage' => 'Unsupported requestType: ' + requestType };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    public static void handleFetchRequest(Map<String, Object> reqMap) {
        try {
        String requestType = (String) reqMap.get('requestType');
            if (requestType == 'accesscardrequests') {BCAPP_WebServiceHelper.getUserRequests(JSON.serialize(reqMap));}
            if (requestType == 'guestrequests') {BCAPP_GeneralServiceRequestHelper.getAllGuestRequest(JSON.serialize(reqMap));}
            if (requestType == 'guestrequestdetails') {BCAPP_WebServiceHelper.getServiceRequestDetails(JSON.serialize(reqMap));}
       }
        catch (Exception e) {Map<String, Object> response = new Map<String, Object>{ 'errorMessage' => e.getMessage() };BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
        
    }
}
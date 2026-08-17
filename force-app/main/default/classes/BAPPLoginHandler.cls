/*
* @Author : Akshay Khairnar
* @CreatedDate : 
* @Description : BAPPLoginHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Akshay   	              Initial draft 
*****************************************************************************************************/
public class BAPPLoginHandler {
    
    public static void handleGetProfile(String requestBody) {
        try {
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            String userToken = (String) requestMap.get('userToken');
            String uuid = (String) requestMap.get('uaePassUuid');
            String email = (String) requestMap.get('email');
            String mobile = (String) requestMap.get('mobile');
            String emiratesId = (String) requestMap.get('emiratesId');
            
            CustomUserService userService = CustomUserService.getInstance();
            User__c user;
            
            // Existing login with token
            if (!String.isBlank(userToken)) {
                
                user = userService.getUserByAzureToken(userToken);
                
            } else if (!String.isBlank(uuid)) {
                
                // Step 1 : Check UUID already mapped
                List<User__c> uuidUsers = userService.getUserByUUID(uuid);
                
                if (!uuidUsers.isEmpty()) {
                    
                    user = uuidUsers[0];
                    
                    // Validate details with same user
                    if (
                        user.Contact__r == null ||
                        user.Contact__r.Email != email ||
                        user.Contact__r.MobilePhone != mobile ||
                        user.Contact__r.Emirates_Id__c != emiratesId
                    ) {
                        sendErrorResponse('UUID details mismatch.');
                        return;
                    }
                    
                } else {
                    
                    // Step 2 : UUID not mapped, find user using details
                    List<User__c> matchedUsers = userService.getUserByDetails(email,mobile,emiratesId);
                    if (matchedUsers.isEmpty()) {
                        sendErrorResponse('No user found for the provided UUID and user details.');
                        return;
                    }
                    
                    user = matchedUsers[0];
                    
                    // Tag UUID
                    user.UUID__c = uuid;
                    update user;
                }
                
            } else {                sendValidationError('request', 'userToken or UUID is required.');
                    return;
                   }
            
            if (user == null) {
                sendErrorResponse(Label.BAPP_NoUserFound);
                return;
            }
            
            Boolean isInactive = !user.Is_Azure_Active__c;
            Boolean isBlacklisted = user.Contact__r != null && user.Contact__r.Blacklisted__c;
            
            if (isInactive) {
                String errorMessage = Label.BAPP_UserInactive;
                if (isBlacklisted) {
                    errorMessage += ' ' + Label.BAPP_UserTerminated;
                }
                sendErrorResponse(errorMessage);
                return;
            }
            
            Contact contact = user.Contact__r;
            
            Map<String, Object> response = new Map<String, Object>{
                'status' => 'success',
                    'message' => Label.BAPP_ProfileFetchedSuccess,
                    'contactDetails' => new Map<String, Object>{
                        'Name' => user.Name,
                            'AccountId' => user.Contact__r.AccountId,
                            'ContactId' => user.Contact__c,
                            'Email' => user.Contact__r.Email,
                            'BrokerRole' => contact != null ? contact.BrokerContactRole__c : null,
                                'IsSuspended' => contact != null ? contact.IsSuspended__c : null,
                                    //'SuspensionTenure' => contact != null ? contact.SuspensionTenure__c : null,
                                    'SuspensionStartDate' => contact != null ? contact.SuspensionStartDate__c : null,
                                        'SuspensionEndDate' => contact != null ? contact.SuspensionEndDate__c : null,
                                            'TypeofEstablishment' => (contact != null && contact.Account != null) ? contact.Account.TypeofEstablishment__c : null,
                                                'Country' => (contact != null && contact.Account != null) ? contact.Account.ShippingCountry : null,
                                                    'restrictAccess' => (contact != null && contact.TerminationApprovalStatus__c == 'Approved')
                                                    //'isTerminated' => (contact != null ? contact.Blacklisted__c : false)
                                                    }
            };
                sendSuccessResponse(response);
        } catch (Exception ex) {
            sendServerError(ex.getMessage());
        }
    }
    
    // --- Response Helpers ---
    private static void sendSuccessResponse(Map<String, Object> response) {
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }
    
    private static void sendValidationError(String field, String message) {
        Map<String, Object> error = new Map<String, Object>{
            'status' => 'validation_error',
                // 'Validation Failed'
                'message' => Label.BAPP_ValidationFailed,
                'errors' => new List<Object>{
                    new Map<String, String>{ 'field' => field, 'message' => message }
                }
        };
            RestContext.response.statusCode = 400;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
    }
    
    private static void sendErrorResponse(String message) {
        Map<String, Object> error = new Map<String, Object>{
            'status' => 'error',
                'message' => message
                };
                    RestContext.response.statusCode = 400;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
    }
    
    private static void sendServerError(String message) {
        Map<String, Object> error = new Map<String, Object>{
            'status' => 'error',
                // 'Server error occurred: ' + message
                'message' => Label.BAPP_ServerErrorPrefix + message
                };
                    RestContext.response.statusCode = 500;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
    }
}
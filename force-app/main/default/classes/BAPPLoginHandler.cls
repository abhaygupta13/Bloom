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

            if (String.isBlank(userToken)) {
                // 'userToken is required.'
                sendValidationError('userToken', Label.BAPP_UserTokenRequired);
                return;
            }

            CustomUserService userService = CustomUserService.getInstance();
            User__c user = userService.getUserByAzureToken(userToken);

            if (user == null) {
                // 'No user found with provided token.'
                sendErrorResponse(Label.BAPP_NoUserFound);
                return;
            }

            // if (user.Is_Azure_Active__c != true || user.IsActive__c != true) {
            //     // 'User is not active.'
            //     String errorMessage = Label.BAPP_UserInactive;

            //     if (user.Contact__r != null && user.Contact__r.Blacklisted__c == true) {
            //         // ' User is terminated.'
            //         errorMessage += ' ' + Label.BAPP_UserTerminated;
            //     }

            //     sendErrorResponse(errorMessage);
            //     return;
            // }

            // New Logic for Inactive and Terminated
            if (!user.Is_Azure_Active__c && !user.Contact__r.IsSuspended__c && !user.Contact__r.Blacklisted__c) {
                // 'User is not active.'
                String errorMessage = Label.BAPP_UserInactive;

                if (!user.Is_Azure_Active__c && user.Contact__r.Blacklisted__c) {
                    // ' User is terminated.'
                    errorMessage += ' ' + Label.BAPP_UserTerminated;
                }
                sendErrorResponse(errorMessage);
                return;
            }

            Contact contact = user.Contact__r;

            Map<String, Object> response = new Map<String, Object>{
                'status' => 'success',
                // 'Profile fetched successfully.'
                'message' => Label.BAPP_ProfileFetchedSuccess,
                'contactDetails' => new Map<String, Object>{
                    'Name' => user.Name,
                    'AccountId' => user.Contact__r.AccountId,
                    'ContactId' => user.Contact__c,
                    'Email' => user.Contact__r.Email,
                    'BrokerRole' => contact != null ? contact.BrokerContactRole__c : null,
                    'IsSuspended' => contact != null ? contact.IsSuspended__c : null,
                    'SuspensionTenure' => contact != null ? contact.SuspensionTenure__c : null,
                    'TypeofEstablishment' => (contact != null && contact.Account != null) ? contact.Account.TypeofEstablishment__c : null,
                    'Country' => (contact != null && contact.Account != null) ? contact.Account.ShippingCountry : null
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
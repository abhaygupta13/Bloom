/**
 * Class: BCAPP_AccessCardServiceHandler
 * Purpose: Routes Access Card service operations (submit, fetch active cards, eligibility)
 *           to the corresponding request helper methods.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Lightweight dispatcher for access card–related operations invoked by API/controllers.
 * - Contains no SOQL/DML. Data access must reside in the AccessCard service class(es).
 * - Business logic remains in helpers; this class only orchestrates calls.
 */
public without sharing class BCAPP_AccessCardServiceHandler {

    /**
     * Submits an Access Card request (e.g., new/replacement) via helper.
     * @param request A Map<String, Object> containing request payload fields.
     *                Expected keys are defined by BCAPP_AccessCardRequestHelper.
     *                (No SOQL/DML here—helpers must call service classes.)
     */
    public static void handleSubmit(Map<String, Object> request) {
        Map<String, Object> response = new Map<String, Object>();
        BCAPP_AccessCardRequestHelper.handleCreateRequest(request, response);
    }

    /**
     * Retrieves active access cards for the given input context via helper.
     * @param request A Map<String, Object> containing filter parameters
     *                (e.g.,Access Card) as defined by the helper.
     *                (No SOQL/DML here—helpers must call service classes.)
     */
    public static void getActiveCards(Map<String, Object> request) {
        Map<String, Object> response = new Map<String, Object>();
        BCAPP_AccessCardRequestHelper.handleGetAccessCards(request, response);
    }

    /**
     * Checks eligibility to create an access card request via helper.
     * @param request A Map<String, Object> with necessary identifiers/context
     *                as defined by the helper.
     *                (No SOQL/DML here—helpers must call service classes.)
     */
    public static void checkEligibility(Map<String, Object> request) {
        Map<String, Object> response = new Map<String, Object>();
        BCAPP_AccessCardRequestHelper.handleCheckEligibility(request, response);
    }
}
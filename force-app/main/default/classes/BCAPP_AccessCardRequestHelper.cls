/**
 * Class: BCAPP_AccessCardRequestHelper
 * Purpose: Handles Access Card request flows (create, fetch cards, eligibility) for the Community App.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Orchestrates validation and request handling for Access Card operations.
 * - Contains no inline SOQL/DML: delegates all data access and DML to Service classes.
 * - Works with CaseService, AccessCardService, UnitService, UnitAllocationService, ServiceCatalogService, etc.
 */
public without sharing class BCAPP_AccessCardRequestHelper {
    private static final String REQUEST_TYPE = 'Access Card';
    private static final String RECORD_TYPE = 'Community General Service Request';
    private static final String ORIGIN = 'Community App';
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final Integer MAX_CARDS_PER_UNIT = 2;

    /**
     * Creates an Access Card replacement request Case after validating request data and context.
     * @param reqMap   Incoming request payload.
     * @param response Outgoing response map (success/error normalized via BCAPP_WebServiceHelper).
     */
    public static void handleCreateRequest(Map<String, Object> reqMap, Map<String, Object> response) {
        if (!validateRequestData(reqMap)) {
            response.put('errorMessage', 'Invalid request data');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        
        String accountId   = (String) reqMap.get('accountId');
        String unitId      = (String) reqMap.get('unitId');
        String requestType = (String) reqMap.get('requestType');
        String paymentId   = (String) reqMap.get('referenceId');
        
        CaseService caseService = CaseService.getInstance();
        
        // user validation
        List<User__c> customer = BCAPP_Utility.getInstance().getUserbyAccountId(accountId);
        if (customer == null || customer.isEmpty()) {
            response.put('errorMessage', 'Invalid User');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        
        // unit validation (same as original logic)
        Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
        if (unit == null || unit.Legal_Status__c == 'With Legal') {
            response.put('errorMessage', 'Unit is legally blocked or not found.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        
        // allocation via service
        UnitAllocationService uaSvc = UnitAllocationService.getInstance();
        Unit_Allocation__c alloc = uaSvc.getActiveAllocation(unit.Id, (Id)accountId, Date.today());
        if (alloc == null) {
            response.put('errorMessage', 'No active allocation found.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        
        // active card count via service
        AccessCardService cardSvc = AccessCardService.getInstance();
        Integer activeCardCount = cardSvc.countActiveByAccountUnit((Id)accountId, (Id)unitId);
        if (activeCardCount == 0) {
            response.put('isEligible', false);
            response.put('message', 'No active cards found to replace. Access Card module is unavailable.');
            BCAPP_WebServiceHelper.makeSuccessResponse(response);
            return;
        }
        
        String userType = alloc.User_Type__c;
        reqMap.put('userType', userType);
        
        // owner rule via service
        if (userType == 'Owner') {
            if (uaSvc.hasActiveResidents(unit.Id, Date.today())) {
                response.put('errorMessage', 'Owner cannot request when an active Tenant or Holiday Home exists.');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }
        }
        
        // card numbers from req
        List<Object> cardNumbersRaw = (List<Object>) reqMap.get('cardNumbers');
        if (cardNumbersRaw == null || cardNumbersRaw.isEmpty()) {
            response.put('errorMessage', 'At least one card number must be provided for replacement.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        List<String> cardNumbers = new List<String>();
        for (Object obj : cardNumbersRaw) cardNumbers.add((String) obj);
        
        // cards to replace via service (Activated only)
        List<AccessCard__c> cardsToReplace = cardSvc.getActivatedByNumbers(new Set<String>(cardNumbers));
        
        if (cardsToReplace.size() != cardNumbers.size()) {
            response.put('errorMessage', 'Some card numbers are invalid or do not exist.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        
        for (AccessCard__c card : cardsToReplace) {
            if (card.Unit__c != unit.Id || card.Account__c != accountId || card.Status__c != 'Activated') {
                response.put('errorMessage', 'All selected cards must be activated and belong to the same unit/account.');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }
        }
        
        
        
        // >>> NEW: Payment validation (status + amount) BEFORE creating Case <<<
        // Fetch service catalog to know the per-card charge
        Service_Catalog__c sc = ServiceCatalogService.fetchServiceCatalogByName(REQUEST_TYPE)[0];
        Integer cardsRequested = cardNumbers.size();
        Decimal perCardAmount  = (sc != null && sc.Amount__c != null) ? sc.Amount__c : 0;
        
        
        if (String.isBlank(paymentId)) {
            response.put('errorMessage', 'Missing payment reference.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }else{
            OnlinePaymentLineItemService opliService = OnlinePaymentLineItemService.getInstance();
            OnlinePaymentService opService = OnlinePaymentService.getInstance();
            paymentId = BCAPP_Utility.decryptId(paymentId);
            OnlinePayment__c op = opService.getPaymentById(paymentId);
            List<OnlinePaymentLineItem__c> opl = opliService.getOnlinePaymentLineItemsByPaymentId(paymentId);
            if(opl.isEmpty()){
                response.put('errorMessage', 'Missing payment reference.');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }else{
                if(!String.isBlank(opl[0].Case__c) || opl[0].Case__c != null || op.Status__c != 'Success'){
                    response.put('errorMessage', 'Missing payment reference.');
                    BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                    return;
                }
            }
        }
        
        // Prefer a dedicated OnlinePaymentService if available
        OnlinePaymentService paySvc = OnlinePaymentService.getInstance();
        OnlinePayment__c pay = paySvc.getPaymentById(paymentId);
        
        if (pay == null) {
            response.put('errorMessage', 'Invalid payment reference.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        
        // 1) Status must be 'Success'
        if (String.valueOf(pay.Status__c) != 'Success') {
            response.put('errorMessage', 'Payment is not completed. Status: ' + String.valueOf(pay.Status__c));
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        // 2) Amount must match (per-card price × number of cards)
        Decimal expected = (perCardAmount == null ? 0 : perCardAmount.setScale(2)) * cardsRequested;
        //expected+= expected * 0.0125;
        Decimal paid     = (pay.PaidAmount__c == null ? 0 : pay.PaidAmount__c.setScale(2));
        
        if (expected.setScale(2,RoundingMode.HALF_UP) != paid) {
            response.put('errorMessage',
                         'Payment amount mismatch. Expected ' + String.valueOf(expected) +
                         ', received ' + String.valueOf(paid) + '.');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
        // <<< END NEW PAYMENT VALIDATION >>>
        
        // Create Case (DML via CaseService)
        Case accessCase = createAccessCardCase(unit, accountId, reqMap);
        caseService.insertCase(accessCase);
        Case ar = caseService.getCaseById(accessCase.Id);
        
        // Link Case to payment line items (DML via OnlinePaymentLineItemService)
        attachCaseIdtoPayment(accessCase.Id, paymentId);
        
        response.put('srId', accessCase.Id);
        response.put('caseNumber', ar.caseNumber);
        response.put('message', 'Access Card replacement request created successfully');
        BCAPP_WebServiceHelper.makeSuccessResponse(response);
    }

    /**
     * Attaches the created Case Id to Online Payment Line Items for a given payment reference.
     * @param caseId    Case Id to attach.
     * @param paymentId OnlinePayment__c Id (reference) used to fetch line items.
     */
    public static void attachCaseIdtoPayment(String caseId, String paymentId){
        List<OnlinePaymentLineItem__c> oltColl = new List<OnlinePaymentLineItem__c>();
        OnlinePaymentLineItemService opliService = OnlinePaymentLineItemService.getInstance();
        for (OnlinePaymentLineItem__c olt : opliService.getOnlinePaymentLineItemsByPaymentId(paymentId)) {
            olt.Case__c = caseId;
            oltColl.add(olt);
        }
        if (!oltColl.isEmpty()) {
            // DML moved to service
            opliService.updateonlinePaymentLineItems(oltColl);
        }
    }

    /**
     * Validates the minimum request payload for Access Card operations.
     * @param reqMap Incoming request payload.
     * @return true if basic keys are present; otherwise false.
     */
    private static Boolean validateRequestData(Map<String, Object> reqMap) {
        return reqMap != null &&
            String.isNotBlank((String)reqMap.get('unitId')) &&
            String.isNotBlank((String)reqMap.get('accountId')) &&
            String.isNotBlank((String)reqMap.get('requestType'));
    }

    /**
     * Builds a Case record for Access Card requests.
     * @param unit     Target Unit__c (already validated).
     * @param accountId Account Id of requester.
     * @param reqMap   Incoming request payload with card details and context.
     * @return Unsaved Case record populated with required fields.
     */
    private static Case createAccessCardCase(Unit__c unit, String accountId, Map<String, Object> reqMap) {
        // Service Catalog via service
        Service_Catalog__c sc = ServiceCatalogService.fetchServiceCatalogByName(REQUEST_TYPE)[0];

        return new Case(
            AccountId = accountId,
            Origin = ORIGIN,
            Unit__c = unit.Id,
            Project__c = unit.Project__c,
            Service_Catalog__c = sc.Id,
            Status = STATUS_SUBMITTED,
            Subject = 'Access Card Request',
            RecordTypeId = Utilities.getRecordTypeId('Case', RECORD_TYPE),
            Request_Type__c = REQUEST_TYPE,
            RequestType__c = REQUEST_TYPE,
            User_Type__c = getUserType(reqMap),
            Description = generateCaseDescription(reqMap),
            CardNumbers__c = getCardNumbers(reqMap),
            AccessCardType__c = getCardTypes(reqMap),
            NumberOfCards__c = ((List<Object>) reqMap.get('cardNumbers')).size()
        );
    }

    /**
     * Returns comma-separated card numbers from the request map.
     * @param reqMap Incoming request payload.
     * @return CSV string of card numbers or blank.
     */
    private static String getCardNumbers(Map<String, Object> reqMap) {
        List<Object> cardNumbersRaw = (List<Object>) reqMap.get('cardNumbers');
        String cardDetails = '';
        if (cardNumbersRaw != null && !cardNumbersRaw.isEmpty()) {
            List<String> strList = new List<String>();
            for (Object obj : cardNumbersRaw) strList.add((String) obj);
            cardDetails = String.join(strList, ',');
        }
        return cardDetails;
    }

    /**
     * Derives the user type from any of the provided card numbers (first match).
     * @param reqMap Incoming request payload.
     * @return User type string or blank if not resolvable.
     */
    private static String getUserType(Map<String, Object> reqMap) {
        // Use first of selected cards to derive userType (unchanged behavior)
        List<Object> cardNumbersRaw = (List<Object>) reqMap.get('cardNumbers');
        String userType = '';
        if (cardNumbersRaw != null && !cardNumbersRaw.isEmpty()) {
            List<String> strList = new List<String>();
            for (Object obj : cardNumbersRaw) strList.add((String) obj);
            // Fetch any (no status filter) to be consistent with original logic using LIMIT 1
            List<AccessCard__c> cards = AccessCardService.getInstance().getByNumbers(new Set<String>(strList));
            if (!cards.isEmpty()) {
                userType = cards[0].UserType__c;
            }
        }
        return userType;
    }

    /**
     * Returns semicolon-separated card types for the provided card numbers.
     * @param reqMap Incoming request payload.
     * @return Semicolon-separated list of card types or blank.
     */
    private static String getCardTypes(Map<String, Object> reqMap) {
        List<Object> cardNumbersRaw = (List<Object>) reqMap.get('cardNumbers');
        String cardTypes = '';
        if (cardNumbersRaw != null && !cardNumbersRaw.isEmpty()) {
            List<String> strList = new List<String>();
            for (Object obj : cardNumbersRaw) strList.add((String) obj);
            Set<String> types = AccessCardService.getInstance().getCardTypesByNumbers(new Set<String>(strList));
            if (!types.isEmpty()) {
                cardTypes = String.join(new List<String>(types), ';');
            }
        }
        return cardTypes;
    }

    /**
     * Builds the Case.Description for audit and CSR context.
     * @param reqMap Incoming request payload.
     * @return Multiline description text for the Case.
     */
    private static String generateCaseDescription(Map<String, Object> reqMap) {
        String requestType = (String) reqMap.get('requestType');
        String userType = (String) reqMap.get('userType');

        List<Object> cardNumbersRaw = (List<Object>) reqMap.get('cardNumbers');
        String cardDetails = '';
        if (cardNumbersRaw != null && !cardNumbersRaw.isEmpty()) {
            List<String> strList = new List<String>();
            for (Object obj : cardNumbersRaw) strList.add((String) obj);
            cardDetails = 'Card Numbers to Replace: ' + String.join(strList, ', ');
        }

        return String.format(
            'Access Card Request Details:\n' +
            'Request Type: {0}\n' +
            'User Type: {1}\n' +
            '{2}',
            new List<String>{
                'Replace',
                userType,
                cardDetails
            }
        );
    }

    /**
     * Retrieves active Access Cards for account/unit and returns UI-ready payload.
     * @param reqMap   Incoming request payload (expects accountId, unitId).
     * @param response Outgoing response map with 'data' list or error.
     */
    public static void handleGetAccessCards(Map<String, Object> reqMap, Map<String, Object> response) {
        String accountId = (String) reqMap.get('accountId');
        String unitId = (String) reqMap.get('unitId');
        Service_Catalog__c sc = ServiceCatalogService.fetchServiceCatalogByName(REQUEST_TYPE)[0];

        if (String.isBlank(accountId) || String.isBlank(unitId)) {
            response.put('errorMessage', 'Missing required parameters: accountId and unitId');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }

        List<AccessCard__c> activeCards =
            AccessCardService.getInstance().getActiveByAccountUnit((Id)accountId, (Id)unitId);

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (AccessCard__c card : activeCards) {
            result.add(new Map<String, Object>{
                'cardId'       => card.Id,
                'cardNumber'   => card.CardNumber__c,
                'cardType'     => card.CardType__c,
                'userType'     => card.UserType__c,
                'residentName' => card.ResidentName__c,
                'status'       => card.Status__c,
                'Amount'       => sc.Amount__c
            });
        }
        response.put('data', result);
        BCAPP_WebServiceHelper.makeSuccessResponse(response);
    }

    /**
     * Validates whether the user/unit context is eligible to use the Access Card feature.
     * @param reqMap   Incoming request payload (expects accountId, unitId).
     * @param response Outgoing response map with isEligible flag and message.
     */
    public static void handleCheckEligibility(Map<String, Object> reqMap, Map<String, Object> response) {
        try {
            String accountId = (String) reqMap.get('accountId');
            String unitId    = (String) reqMap.get('unitId');

            if (String.isBlank(accountId) || String.isBlank(unitId)) {
                response.put('errorMessage', 'Missing required parameters: accountId and unitId');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }

            List<User__c> customer = BCAPP_Utility.getInstance().getUserbyAccountId(accountId);
            if (customer == null || customer.isEmpty()) {
                response.put('errorMessage', 'Invalid User');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }

            Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
            if (unit == null) {
                response.put('errorMessage', 'Invalid Unit');
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }

            if (unit.Legal_Status__c == 'With Legal') {
                response.put('isEligible', false);
                response.put('message', 'Unit is legally blocked. Cannot process request.');
                BCAPP_WebServiceHelper.makeSuccessResponse(response);
                return;
            }

            UnitAllocationService uaSvc = UnitAllocationService.getInstance();
            Unit_Allocation__c alloc = uaSvc.getActiveAllocation(unit.Id, (Id)accountId, Date.today());
            if (alloc == null) {
                response.put('isEligible', false);
                response.put('message', 'No active allocation found for the user');
                BCAPP_WebServiceHelper.makeSuccessResponse(response);
                return;
            }

            Integer activeCardCount = AccessCardService.getInstance()
                .countActiveByAccountUnit((Id)accountId, (Id)unitId);

            if (activeCardCount == 0) {
                response.put('isEligible', false);
                response.put('message', 'No active cards found to replace. Access Card module is unavailable.');
                BCAPP_WebServiceHelper.makeSuccessResponse(response);
                return;
            }

            String userType = alloc.User_Type__c;

            // Owner rule check — block if any active Tenant or HHO exists
            if (userType == 'Owner') {
                if (uaSvc.hasActiveResidents(unit.Id, Date.today())) {
                    response.put('isEligible', false);
                    response.put('message', 'Owner cannot request when an active Tenant or Holiday Home exists for this unit.');
                    BCAPP_WebServiceHelper.makeSuccessResponse(response);
                    return;
                }
            }

            response.put('isEligible', true);
            response.put('userType', userType);
            response.put('message', 'User is eligible to access card feature');
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception e) {
            response.put('errorMessage', e.getMessage());
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }
}
/**
 * Class: BCAPP_ServiceRequestPaymentHandler
 * Purpose: Handles Online Payment submission & status updates for Service Requests
 *          (e.g., Access Card / Amenity). Keeps controller/handler thin by delegating
 *          all SOQL/DML to service classes.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - submitPayment: Creates a pending OnlinePayment__c and its line items.
 * - updatePaymentStatus: Updates payment status and creates Receipt__c on success.
 * - Response payloads/messages remain unchanged.
 */
public without sharing class BCAPP_ServiceRequestPaymentHandler {

    /**
     * Creates a pending OnlinePayment__c and its OnlinePaymentLineItem__c rows for SR payments.
     * Expects: customerId (Account Id), unitId, paymentMethod, requestSource, serviceType, amount, requests[].
     * Returns: { paymentId } via BCAPP_WebServiceHelper.makeSuccessResponse(...)
     */
    public static void submitPayment(Map<String, Object> data) {
        try {
            String customerId     = (String) data.get('accountId');
            String unitId         = (String) data.get('unitId');
            String paymentMethod  = (String) data.get('paymentMethod');
            String serviceType    = (String) data.get('serviceType');     // AccessCard / Amenity
            String requestSource  = (String) data.get('requestSource');
            Decimal totalAmount   = (Decimal) data.get('amount');
            List<Object> requestObjs = (List<Object>) data.get('requests');

            if (String.isBlank(customerId) || String.isBlank(unitId)
                || totalAmount == null || requestObjs == null || requestObjs.isEmpty()) {
                throw new AuraHandledException('Invalid request. Required fields missing.');
            }
			 Decimal Percentage =  0.0125;
            Decimal base = totalAmount / (1 + percentage);
			
			Decimal technologyfee = totalAmount - base;
            // Header (DML via service)
            OnlinePayment__c payment = new OnlinePayment__c(
                PaidAmount__c     = base,
                Status__c         = 'Pending',
                RequestType__c    = serviceType,
                RequestSource__c  = requestSource,
                PaymentMethod__c  = paymentMethod,
                Account__c        = customerId,
                Unit__c           = unitId,
                TechnologyFee__c  = technologyfee
            );
            payment = OnlinePaymentService.getInstance().insertPayment(payment);
            Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
            BankAccount__c ba = fetchBankDetailsByCompanyCode(unit.Project__r.BankAccount__c);
            // Lines (amount per request) (DML via service)
            List<OnlinePaymentLineItem__c> lineItems = new List<OnlinePaymentLineItem__c>();
            for (Object obj : requestObjs) {
                Map<String, Object> req = (Map<String, Object>) obj;
                lineItems.add(new OnlinePaymentLineItem__c(
                    PlannedAmount__c = (Decimal) req.get('amount'),
                    OnlinePayment__c = payment.Id
                ));
            }
            OnlinePaymentLineItemService.getInstance().insertLineItems(lineItems);

            BCAPP_WebServiceHelper.makeSuccessResponse(new Map<String, Object>{ 'paymentId' =>  BCAPP_Utility.encryptId(payment.Id), 'mmid' =>ba.mmid__c });

        } catch (Exception ex) {
            BCAPP_WebServiceHelper.makeServerErrorResponse(new Map<String, Object>{
                'errorMessage' => 'Error in submitPayment: ' + ex.getMessage() + ' | Line: ' + ex.getLineNumber() + ' | Stack: ' + ex.getStackTraceString()
            });
        }
    }

    /**
     * Updates OnlinePayment__c status & (on Success) creates a Receipt__c.
     * Expects: paymentId, status (Success/Failed), message, paymentMethod.
     * Returns: { status, message, receiptId } via BCAPP_WebServiceHelper.makeSuccessResponse(...)
     */
    public static void updatePaymentStatus(Map<String, Object> data) {
        try {
            String paymentId     = (String) data.get('paymentId');
            String status        = (String) data.get('status');  // Success / Failed
            String message       = (String) data.get('message');
            String paymentMethod = (String) data.get('paymentMethod');
			//paymentId = BCAPP_Utility.decryptId(paymentId);
            // Fetch payment via service
            OnlinePayment__c payment =
                OnlinePaymentService.getInstance().getPaymentById((Id) paymentId);

            payment.Status__c           = status;
            payment.ResponseMessage__c  = message;
            payment.PaymentMethod__c    = paymentMethod;

            // DML via service
            OnlinePaymentService.getInstance().updatePayment(payment);

            Receipt__c receipt;
            if (status == 'Success') {
                // Create receipt (DML via service)
                receipt = new Receipt__c(
                    AmountReceived__c   = payment.PaidAmount__c,
                    PaymentDate__c      = System.today(),
                    PaymentMode__c      = 'Online',
                    GatewayReference__c = payment.GatewayReference__c,
                    Status__c           = 'Posted',
                    Account__c          = payment.Account__c,
                    Unit__c             = payment.Unit__c,
                    OnlinePayment__c    = payment.Id,
                    TechnologyFee__c  = payment.TechnologyFee__c
                );
                receipt = ReceiptService.getInstance().insertReceipt(receipt);
            }

            if (payment.Status__c == 'Success') {
                // External poster (no DML)
                BCAPP_SAPPaymentStatusPoster.postPaymentStatus(payment.Id, 'Misc');
            }

            BCAPP_WebServiceHelper.makeSuccessResponse(new Map<String, Object>{
                'status'    => payment.Status__c,
                'message'   => payment.ResponseMessage__c,
                'receiptId' => receipt != null ? receipt.Id : null
            });

        } catch (Exception ex) {
            BCAPP_WebServiceHelper.makeServerErrorResponse(new Map<String, Object>{
                'errorMessage' => 'Error in updatePaymentStatus: ' + ex.getMessage() + ' | Line: ' + ex.getLineNumber() + ' | Stack: ' + ex.getStackTraceString()
            });
        }
    }
    private static BankAccount__c fetchBankDetailsByCompanyCode(String companyCode) {
        if (String.isBlank(companyCode)) return null;
        // SOQL is supported on Custom Metadata Types
        List<BankAccount__c> rows = [
            SELECT Name,CompanyCode__c, AccountNumberCorporate__c, IBANNoCorporate__c, SwiftCodeCorporate__c, BankNameCorporate__c,MMID__c 
            FROM BankAccount__c
            WHERE Id = :companyCode
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }
}
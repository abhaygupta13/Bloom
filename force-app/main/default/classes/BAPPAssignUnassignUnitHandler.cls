/*
* @Author      : Akshay Khairnar
* @CreatedDate : 18th SEP 2025
* @Description : Handles assigning and unassigning units to high-level broker contacts (e.g., Admin, Super Admin, CEO) through API. 
			   : Including input validation, role checks, preventing duplicate assignments, and managing the assignment.
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Akshay Khairnar    18th SEP 2025    Initial Draft
*****************************************************************************************************/
public inherited sharing class BAPPAssignUnassignUnitHandler {

    // ---------- REQUEST WRAPPER ----------
    private class AssignUnassignRequest {
        public Id accountId;
        public Id contactId; // The user performing action
        public List<BrokerUnitAssignmentRequest> brokerUnitAssignments; // For assign
        public List<Id> unassignBrokerUnitAssignmentRecordIds;          // For unassign
    }

    private class BrokerUnitAssignmentRequest {
        public Id brokerUnitAllocationRecordId;
        public List<Id> contactIds;
    }

    // ---------- ENTRY POINT ----------
    public static void handleAssignUnassign(String requestBody) {
        try {
            AssignUnassignRequest req = 
                (AssignUnassignRequest) JSON.deserialize(requestBody, AssignUnassignRequest.class);

            Map<String, Object> finalResponse = processAssignUnassign(req);

            if (String.valueOf(finalResponse.get('status')) == 'success') {
                makeSuccessResponse(finalResponse);
            } else if (String.valueOf(finalResponse.get('status')) == 'partial_success') {
                makeSuccessResponse(finalResponse); // still 200 but partial
            } else {
                makeErrorResponse(finalResponse);
            }

        } catch (Exception e) {
            makeServerErrorResponse(new Map<String, Object>{
                'status' => 'error',
                'message' => e.getMessage()
            });
        }
    }

    // ---------- CORE LOGIC ----------
    private static Map<String, Object> processAssignUnassign(AssignUnassignRequest req) {
        if (req == null) {
            return new Map<String, Object>{
                'status' => 'error',
                'message' => Label.BAPP_Invalid_Request_Body
            };
        }

        // Validate top-level required fields
        if (req.accountId == null || req.contactId == null) {
            return new Map<String, Object>{
                'status' => 'error',
                'message' => Label.BAPP_Account_Contact_Required
            };
        }

        // Validate contact role
        Contact actingContact = ContactService.getInstance().getContactById(req.contactId); //optimize
        
        if (actingContact.AccountId != req.accountId) {
            return new Map<String, Object>{
                'status' => 'error',
                'message' => Label.BAPP_Contact_Not_Belong_To_Account
            };
        }
        
        // Validate contact role — allow if BrokerContactRole__c contains Admin, SuperAdmin, or CEO
        String roles = actingContact.BrokerContactRole__c != null ? actingContact.BrokerContactRole__c.toLowerCase() : '';
        if (!(roles.contains('admin') || roles.contains('superadmin') || roles.contains('ceo'))) {
            return new Map<String, Object>{
                'status' => 'error',
                    'message' => Label.BAPP_No_Access_Assign_Unassign
                    };
                        }


        List<Id> createdIds = new List<Id>();
        List<Id> updatedIds = new List<Id>();
        
        // -------------------------
        // ASSIGN BLOCK (if brokerUnitAssignments provided)
        // -------------------------
        if (req.brokerUnitAssignments != null && !req.brokerUnitAssignments.isEmpty()) {
            List<BrokerUnitAssignment__c> toInsert = new List<BrokerUnitAssignment__c>();
            List<BrokerUnitAssignment__c> toUpdate = new List<BrokerUnitAssignment__c>();
            
            // 1 Collect all allocation and contact Ids (only valid non-empty Id strings)
            Set<Id> allocationIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            for (BrokerUnitAssignmentRequest item : req.brokerUnitAssignments) {
                if (item != null && item.brokerUnitAllocationRecordId != null && item.contactIds != null) {
                    allocationIds.add(item.brokerUnitAllocationRecordId);
                    for (Id cId : item.contactIds) {
                        if (cId == null) continue;
                        String s = String.valueOf(cId).trim();
                        if (s.length() == 0) continue;
                        contactIds.add((Id)s);
                    }
                }
            }
            
            // 2 Query all existing BrokerUnitAssignment records and build normalized key map
            Map<String, BrokerUnitAssignment__c> existingMap = new Map<String, BrokerUnitAssignment__c>();
            if (!allocationIds.isEmpty() && !contactIds.isEmpty()) {
                List<BrokerUnitAssignment__c> existingAssignments = BrokerUnitAssignmentService.getInstance().getAssignmentsByAllocationAndContacts(allocationIds, contactIds); //optimize
                for (BrokerUnitAssignment__c existing : existingAssignments) {
                    String alloc = existing.BrokerUnitAllocation__c == null ? '' : String.valueOf(existing.BrokerUnitAllocation__c).trim().toUpperCase();
                    String cont  = existing.Contact__c == null ? '' : String.valueOf(existing.Contact__c).trim().toUpperCase();
                    String comboKey = alloc + '_' + cont;
                    existingMap.put(comboKey, existing);
                }
            }
            
            // 3 Process request items; ensure no duplicate processing in same request
            Set<String> processedCombos = new Set<String>();
            for (BrokerUnitAssignmentRequest item : req.brokerUnitAssignments) {
                if (item == null || item.brokerUnitAllocationRecordId == null || item.contactIds == null || item.contactIds.isEmpty()) {
                    continue;
                }
                
                String allocFromReq = String.valueOf(item.brokerUnitAllocationRecordId).trim().toUpperCase();
                for (Id contactId : item.contactIds) {
                    if (contactId == null) continue;
                    String contFromReq = String.valueOf(contactId).trim().toUpperCase();
                    if (contFromReq.length() == 0) continue;
                    
                    String comboKey = allocFromReq + '_' + contFromReq;
                    
                    // skip duplicates in same request
                    if (processedCombos.contains(comboKey)) {
                        continue;
                    }
                    processedCombos.add(comboKey);
                    
                    if (existingMap.containsKey(comboKey)) {
                        BrokerUnitAssignment__c existingRec = existingMap.get(comboKey);
                        // If record found and inactive → reactivate
                        if (existingRec.Active__c == false) {
                            existingRec.Active__c = true;
                            toUpdate.add(existingRec);
                        } else {
                            System.debug('Existing active mapping found, nothing to do: ' + existingRec.Id + ' key=' + comboKey);
                        }
                    } else {
                        // Else create new record (temporarily add to toInsert)
                        BrokerUnitAssignment__c bua = new BrokerUnitAssignment__c(
                            BrokerUnitAllocation__c = item.brokerUnitAllocationRecordId,
                            Contact__c = contactId,
                            Active__c = true
                        );
                        toInsert.add(bua);
                    }
                }
            }
            
            // 4 Reactivate existing inactive records
            if (!toUpdate.isEmpty()) {
                BrokerUnitAssignmentService.getInstance().updateBrokerUnitAssignments(toUpdate); //optimize
                for (BrokerUnitAssignment__c bua : toUpdate) {
                    updatedIds.add(bua.Id);
                }
            }
            
            // 5 Safety re-check before inserts — prevents duplicate creation if DB changed or key mismatch
            if (!toInsert.isEmpty()) {
                // Build set of alloc/contact pairs from toInsert
                Set<Id> recheckAllocIds = new Set<Id>();
                Set<Id> recheckContactIds = new Set<Id>();
                for (BrokerUnitAssignment__c t : toInsert) {
                    recheckAllocIds.add(t.BrokerUnitAllocation__c);
                    recheckContactIds.add(t.Contact__c);
                }
                
                Map<String, BrokerUnitAssignment__c> recheckMap = new Map<String, BrokerUnitAssignment__c>();
                List<BrokerUnitAssignment__c> existingAssignments = BrokerUnitAssignmentService.getInstance().getAssignmentsByAllocationAndContacts(recheckAllocIds, recheckContactIds); //optimize
                for (BrokerUnitAssignment__c existing : existingAssignments) {
                    String alloc = existing.BrokerUnitAllocation__c == null ? '' : String.valueOf(existing.BrokerUnitAllocation__c).trim().toUpperCase();
                    String cont  = existing.Contact__c == null ? '' : String.valueOf(existing.Contact__c).trim().toUpperCase();
                    recheckMap.put(alloc + '_' + cont, existing);
                }
                
                // Partition inserts into finalInserts (no record found) and toUpdate (reactivate found record)
                List<BrokerUnitAssignment__c> finalInserts = new List<BrokerUnitAssignment__c>();
                for (BrokerUnitAssignment__c candidate : toInsert) {
                    String key = String.valueOf(candidate.BrokerUnitAllocation__c).trim().toUpperCase() + '_' + String.valueOf(candidate.Contact__c).trim().toUpperCase();
                    if (recheckMap.containsKey(key)) {
                        BrokerUnitAssignment__c existing = recheckMap.get(key);
                        if (existing.Active__c == false) {
                            existing.Active__c = true;
                            toUpdate.add(existing);
                        } else {
                            System.debug('Record already active on recheck, skip insert: ' + existing.Id + ' key=' + key);
                        }
                    } else {
                        finalInserts.add(candidate);
                    }
                }
                
                // Apply any extra updates found during recheck
                if (!toUpdate.isEmpty()) {
                    BrokerUnitAssignmentService.getInstance().updateBrokerUnitAssignments(toUpdate); //optimize
                    for (BrokerUnitAssignment__c bua : toUpdate) {
                        updatedIds.add(bua.Id);
                    }
                }
                
                // Now insert remaining truly new records
                if (!finalInserts.isEmpty()) {
                    BrokerUnitAssignmentService.getInstance().insertBrokerUnitAssignments(finalInserts); //optimize
                    for (BrokerUnitAssignment__c bua : finalInserts) {
                        createdIds.add(bua.Id);
                    }
                }
            }
        }

        // -------------------------
        // UNASSIGN BLOCK (if unassignBrokerUnitAssignmentRecordIds provided)
        // -------------------------
        if (req.unassignBrokerUnitAssignmentRecordIds != null 
            && !req.unassignBrokerUnitAssignmentRecordIds.isEmpty()) {
            List<BrokerUnitAssignment__c> toUpdate = [
                SELECT Id, Active__c
                FROM BrokerUnitAssignment__c
                WHERE Id IN :req.unassignBrokerUnitAssignmentRecordIds
            ];
            for (BrokerUnitAssignment__c bua : toUpdate) {
                bua.Active__c = false;
            }
            if (!toUpdate.isEmpty()) {
                BrokerUnitAssignmentService.getInstance().updateBrokerUnitAssignments(toUpdate); //optimize
                for (BrokerUnitAssignment__c bua : toUpdate) {
                    updatedIds.add(bua.Id);
                }
            }
        }

        // -------------------------
        // RESPONSE
        // -------------------------
        if (!createdIds.isEmpty() && !updatedIds.isEmpty()) {
            return new Map<String, Object>{
                'status' => 'partial_success',
                'message' => Label.BAPP_Assign_Unassign_Partial_Success
            };
        } else if (!createdIds.isEmpty()) {
            return new Map<String, Object>{
                'status' => 'success',
                'message' => Label.BAPP_Assign_Success
            };
        } else if (!updatedIds.isEmpty()) {
            return new Map<String, Object>{
                'status' => 'success',
                'message' => Label.BAPP_Update_Success
            };
        } else {
            return new Map<String, Object>{
                'status' => 'error',
                'message' => Label.BAPP_No_Valid_Assignments
            };
        }
    }

    // ---------- RESPONSE HELPERS ----------
    public static void makeSuccessResponse(Map<String, Object> response) { 
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
        RestContext.response.statusCode = 200;
    }

    public static void makeErrorResponse(Map<String, Object> error) {
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 400;
    }

    public static void makeServerErrorResponse(Map<String, Object> error) {
        error.put('status', 'error');
        error.put('message', Label.BAPP_Server_Error);
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(error));
        RestContext.response.statusCode = 500;
    }
}
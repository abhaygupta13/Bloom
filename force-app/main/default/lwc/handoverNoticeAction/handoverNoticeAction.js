import { LightningElement, track, wire } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import getProjects from '@salesforce/apex/HandoverController.getProjects';
import getBuildings from '@salesforce/apex/HandoverController.getHandoverPhase';
// FIX 1: You must import the consolidated method to use it
import getHandoverData from '@salesforce/apex/HandoverController.getHandoverData';

import sendBCCMailToCustomer from '@salesforce/apex/HandoverController.sendBCCEmails';
//import sendOrientationMailToCustomer from '@salesforce/apex/HandoverController.sendOrientationEmails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendBCCLWCHeading1 from '@salesforce/label/c.sendBCCLWCHeading';
import noRecordFound from '@salesforce/label/c.noRecordFound';
import selectAtleastOneRecord from '@salesforce/label/c.selectAtleastOneRecord';
import bccEmailSent from '@salesforce/label/c.bccEmailSent';
import orientationEmailSent from '@salesforce/label/c.OrientationEmailSent';
import bccEmailError from '@salesforce/label/c.bccEmailError';
import unitButtonLabel from '@salesforce/label/c.unitButtonLabel';
import bccButtonL from '@salesforce/label/c.bccButtonLabel';
import sendNOCHeading from '@salesforce/label/c.sendNOCLWCHeading';
import nocButtonL from '@salesforce/label/c.nocButtonLabel';
import sendNOCMailToCustomer from '@salesforce/apex/HandoverController.sendNOCCHOEmail';
import sendCHOHeading from '@salesforce/label/c.sendCHOInviteHeading';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

const columns = [
    { label: 'Handover Name', fieldName: 'handoverName', sortable: "true" },
    { label: 'Unit Name', fieldName: 'unitName', sortable: "true" },
    { label: 'Unit Status', fieldName: 'unitStatus', sortable: "true" },
    { label: 'Active Sales Order', fieldName: 'activeSalesOrder', sortable: "true" },
    { label: 'Building Name', fieldName: 'buildingName', sortable: "true" },
    { label: 'Owner', fieldName: 'OwnerName', sortable: "true" },
    { label: 'Created Date', fieldName: 'createdDate', sortable: "true" }
];

export default class HandoverNoticeAction extends LightningElement {
 label = {
        sendBCCLWCHeading1,
        noRecordFound,
        selectAtleastOneRecord,
        bccEmailSent,
        orientationEmailSent,
        bccEmailError,
        unitButtonLabel,
        bccButtonL,
        sendNOCHeading,
        nocButtonL,
        sendCHOHeading
    };

    get noticeTypeOption() {
    return [
        { label: 'BCC', value: 'BCC' },
        { label: 'NOC-CHO', value: 'NOC-CHO' }
    ];
}

    @track flags = {
        isVisiableTable: false,
        isLoading: true,
        heading1: 'Select units to send BCC',
        projLabel: 'Project',
        buildLabel: 'Handover Phase',
        noticeLable : 'Notice Type',
        placeholder: 'Select Object',
        curntSelectedObjValue: '',
        projectObjOptions: [],
        buildingObjOptions: [],
        selectedProjectId: '',
        selectedBuildingId: '',
        noticeTypeName:'',
        handoverPhaseId:'',
        tableData: [],
        tableColumns: columns,
        sendBCCMailtoCustomers: false,
        makeUnitReady: false,
        batchJobId: '',
        sendNOCMailtoCustomers: false // FIX 2: Removed trailing comma here
    }
    
    selectedRecordCount = 0;
    sendBCCMailNotification=false;
    sendNOCCHOMailNotification=false;
   // sendCHONotification=false;
    showSearchButton=true;
    

    @track sortBy;
    @track sortDirection;

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.flags.tableData));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.flags.tableData = parseData;
    }

    connectedCallback() {
       getProjects()
        .then(data => {       
            if (data) {
            this.flags.projectObjOptions = Object.entries(data).map(([id, name]) => ({
    label: name,
    value: id
}));
        }
        this.flags.isLoading = false;
    })
            .catch(error => {
                this._showToastMessage('Error', this.label.noRecordFound, 'error');
                this.flags.isLoading = false;
            });
    }

    handleSObjectChange(event) {
        this.flags.isLoading = true;
        let comboxType = event.target.name;
        let selectedId = event.detail.value;
        if (comboxType === 'Choose_Project_Obj') {
            this.flags.selectedProjectId = '';
            this.flags.handoverPhaseId = '';
            this.flags.tableData = [];
            this.flags.isVisiableTable = false;
            this.flags.selectedProjectId = selectedId;

            getBuildings({ projectId: selectedId })
                .then(res => {
                if (res) {
                    this.flags.buildingObjOptions = Object.entries(res).map(([id, name]) => ({
    label: name,
    value: id
}));
                } else {
                    this._showToastMessage('Error', this.label.noRecordFound, 'error');
                }
            })
                .catch(err => {
                    this._showToastMessage('Error', err, 'error');
                })
        } else if (comboxType === 'Choose_Building_Object') {
            this.flags.handoverPhaseId = '';
            this.flags.tableData = [];
            this.flags.isVisiableTable = false;
            this.flags.handoverPhaseId = selectedId;
        }
        else if (comboxType === 'Choose_noticeType_Object') {
        this.sendBCCMailNotification=false;
        this.sendNOCCHOMailNotification=false;
       // this.sendCHONotification=false;
            this.flags.noticeTypeName = '';
            this.flags.tableData = [];
            this.flags.isVisiableTable = false;
            this.flags.noticeTypeName = selectedId;
        }
        this.flags.isLoading = false;
    }

    handleSearchClick(event) {
      const allValid = this._isInputValid();

    if (allValid) {
        const type = this.flags.noticeTypeName;
        this.flags.isLoading = true;
        if(type =='BCC'){
            this.sendBCCMailNotification=true;
            this.sendNOCCHOMailNotification=false;
           // this.sendCHONotification=false;
            this.getUnitsofHandover(type);
        }else if (type === 'NOC-CHO') {
            this.sendNOCCHOMailNotification = true; 
            this.getUnitsofNOCCHO(type);
        }
        
    }
        else {
        this._showToastMessage('Error', 'Please select the mandatory filters to proceed.', 'error');
    }
    }

    getUnitsofHandover(type) {
        getHandoverData({ projectId: this.flags.selectedProjectId, handoverPhaseId: this.flags.handoverPhaseId, type: type })
            .then(res => {
               const parsedData = res ? JSON.parse(res) : [];
            if (parsedData && parsedData.length > 0) {
                this.flags.isVisiableTable = true;
                this.flags.tableData = parsedData;
                this.flags.sendBCCMailtoCustomers = true;
            } 
            else {
                this.flags.isVisiableTable = false;
                this.flags.tableData = [];
                this.flags.sendBCCMailtoCustomers = false;
            }
        })
        .catch(err => {
            let message = err.body ? err.body.message : err;
            this._showToastMessage('Error', message, 'error');
        })
        .finally(() => {
            this.flags.isLoading = false;
        });
}

    getUnitsofNOCCHO(type) {
        getHandoverData({ projectId: this.flags.selectedProjectId, handoverPhaseId: this.flags.handoverPhaseId, type: type })
           .then(res => {
        const parsedData = (typeof res === 'string') ? JSON.parse(res) : res;
        if (parsedData && parsedData.length > 0) {
            this.flags.isVisiableTable = true;
            this.flags.tableData = parsedData;
            this.flags.sendNOCMailtoCustomers = true;
            this.flags.makeUnitReady = false;
            this.flags.sendBCCMailtoCustomers = false;
        } else {
           // this._showToastMessage('Info', 'No records found for NOC.', 'info');
            this.flags.isVisiableTable = false;
            this.flags.tableData = [];
            this.flags.sendNOCMailtoCustomers = false;
        }
    })
    .catch(err => {
        this._showToastMessage('Error', 'Failed to fetch NOC units', 'error');
    })
    .finally(() => {
        this.flags.isLoading = false;
    });
}

   
    
   handleSubmit() {
    if (this.selectedRecordCount > 20) {
this.flags.isLoading = false;
this._showToastMessage('Error', 'You cannot select more than 20 units at a time.', 'error');
return;
}

    if (this._isInputValid()) {
        this.flags.isLoading = true;
        let selectedIds = [];
        var customerEmailNotFound = '';
        var SOADocNotFound = '';
        let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log("selected Rows: ", selectedRows);
        let errorMessages = [];

        if (selectedRows && selectedRows.length === 0) {
            this.flags.isLoading = false;
            this._showToastMessage('Error', this.label.selectAtleastOneRecord, 'error');
        } else {
            selectedRows.forEach((row) => {
                if (row.handoverCustomerEmail === "") {
                    customerEmailNotFound = customerEmailNotFound + ', ' + row.handoverName;
                }
                /*  else if (row.contentDocId === "") {
                    SOADocNotFound = SOADocNotFound + ', ' + row.handoverName;
                } */
                    else {
                    selectedIds.push(row.Id);
                }
            });
            if (customerEmailNotFound.length > 0) {
            this.flags.isLoading = false;
            if (customerEmailNotFound.length > 0) {
                this._showToastMessage('Error', 'Customer Email not found for these Handover: ' + customerEmailNotFound, 'error');
            }
            /* if (SOADocNotFound.length > 0) {
                this._showToastMessage('Error', 'Please add SOA Document for these Handover: ' + SOADocNotFound, 'error');
            } */
            return;
    }

            if (selectedIds.length > 0) {
                console.log("Selected IDs: ", selectedIds);
                console.log('selectedIds - ', JSON.stringify(selectedIds));

                sendBCCMailToCustomer({ recordIds: selectedIds })
                    .then(result => {
                        if (result && !result.toLowerCase().includes('error')) {
        this._showToastMessage('Success', result, 'success');
        
        // --- SMOOTH REFRESH LOGIC START ---
        
        // 1. Clear datatable selection internally
        this.template.querySelector('lightning-datatable').selectedRows = [];
        this.selectedRecordCount = 0;
        this.previousValidSelectionIds = [];

        // 2. Notify LDS (if you were using wire, but good practice anyway)
        selectedIds.forEach(recordId => {
            notifyRecordUpdateAvailable([{ recordId: recordId }]);
        });

        // 3. Re-fetch the table data without reloading the page
        this.handleSearchClick(); 
        
        // --- SMOOTH REFRESH LOGIC END ---

    } else {
        this._showToastMessage('Error', result, errr.body.message);
        this.flags.isLoading = false;
    }
})
                    .catch(error => {
                        this.flags.isLoading = false; // Important: Stop the spinner!
    console.error('error: ', error);
    
    // Extract the error message from the fetchResponse object
    let message = 'Unknown error';
    if (error.body && typeof error.body.message === 'string') {
        message = error.body.message;
    } else if (typeof error.message === 'string') {
        message = error.message;
    }
    
    this._showToastMessage('Error', message, 'error');
});
            }
            else {
                this.flags.isLoading = false;
            }
        }

        if (errorMessages.length > 0) {
            this._showToastMessage('Error', errorMessages.join('\n'), 'error');
        }
    }
}

handleNOCCHOSubmit() {
    if (this.selectedRecordCount > 20) {
this.flags.isLoading = false;
this._showToastMessage('Error', 'You cannot select more than 30 units at a time.', 'error');
return;
}

    if (this._isInputValid()) {
        this.flags.isLoading = true;
        let selectedIds = [];
        var customerEmailNotFound = '';
        let projectIdsSet = new Set();
        let salesOrderIdsSet = new Set();
        var SOADocNotFound = '';
       // var QASnagDocNotFound = '';
        let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log("selected Rows: ", selectedRows);
        let errorMessages = [];
        console.log("selectedRows: ", JSON.stringify(selectedRows));
        if (selectedRows && selectedRows.length === 0) {
            this.flags.isLoading = false;
            this._showToastMessage('Error', this.label.selectAtleastOneRecord, 'error');
        } else {
            selectedRows.forEach((row) => {
                if (row.handoverCustomerEmail === "") {
                    console.log('Email Not Found');
                    customerEmailNotFound = customerEmailNotFound + ', ' + row.handoverName;
                } else if (row.SOADocId === "") {
                    console.log('SOADocNotFound Not Found');
                    SOADocNotFound = SOADocNotFound + ', ' + row.handoverName;
                }  else {
                    selectedIds.push(row.Id);
                    if (row.ProjectId) {
                        projectIdsSet.add(row.ProjectId);
                        console.log('projectIdsSet'+projectIdsSet);
                    }
                    if (row.salesorder) {
                        salesOrderIdsSet.add(row.salesorder);
                          console.log('salesOrderIdsSet'+salesOrderIdsSet);
                    }
                }
            });

            if (customerEmailNotFound || SOADocNotFound) {
        this.flags.isLoading = false; // Stop spinner
        
        if (customerEmailNotFound) {
            this._showToastMessage('Error', 'Customer Email not found for: ' + customerEmailNotFound, 'error');
        }
        if (SOADocNotFound) {
            this._showToastMessage('Error', 'Please add SOA Document for: ' + SOADocNotFound, 'error');
        }
       
        return; // STOP: Do not call Apex
    }
    if (projectIdsSet.size > 1) {
                this.flags.isLoading = false;
                this._showToastMessage('Error', 'All selected records must belong to the same Project.', 'error');
                return;
            }

            // Grab the single Project Id from our Set
            const singleProjectId = projectIdsSet.values().next().value || null;

            console.log("Selected NOC IDs: ", selectedIds);
            console.log('singleProjectId - ', JSON.stringify(singleProjectId));
             console.log(' Array.from(salesOrderIdsSet) - ', JSON.stringify( Array.from(salesOrderIdsSet)));
            if (selectedIds.length > 0) {
                sendNOCMailToCustomer({ recordIds: selectedIds,ProjectId: singleProjectId,
                salesorderIds: Array.from(salesOrderIdsSet) })
                    .then(result => {
                      if (result && !result.toLowerCase().includes('error')) {
            this._showToastMessage('Success', result, 'success');
            
            // 1. Clears selection
            this.template.querySelector('lightning-datatable').selectedRows = [];
            
            // 2. Notifies Salesforce cache (LDS)
            selectedIds.forEach(recordId => {
                notifyRecordUpdateAvailable([{ recordId: recordId,ProjectId: singleProjectId,
                salesorderIds: Array.from(salesOrderIdsSet) }]);
            });

            // 3. RE-FETCHES DATA (This updates the table without a full refresh)
            this.handleSearchClick(); 
        }
    })
                    .catch(error => {
                        console.log('error: ', error);
                    })
            } else {
                this.flags.isLoading = false;
            }
        }
        if (errorMessages.length > 0) {
            this._showToastMessage('Error', errorMessages.join('\n'), 'error');
        }
        //}
    }
}

_isInputValid() {
    let isValid = true;
    let inputFields = this.template.querySelectorAll('.validate');
    inputFields.forEach(inputField => {
        if (!inputField.checkValidity()) {
            inputField.reportValidity();
            isValid = false;
        }
    });
    return isValid;
}

previousValidSelection = [];

previousValidSelectionIds = [];

handleRowSelection(event) {
const selectedRows = event.detail.selectedRows;
const selectedIds = selectedRows.map(r => r.Id);

// Identify if it was a bulk "Select All" action
// Agar difference 1 se zyada hai, matlab user ne bulk select kiya hai
const isBulkSelection = (selectedIds.length - this.previousValidSelectionIds.length) > 1;

if (selectedIds.length > 20) {
    if (isBulkSelection) {
        // "Select All" Scenario: No error, just slice to 25
        const limitedIds = selectedIds.slice(0, 20);
        this.template.querySelector('lightning-datatable').selectedRows = limitedIds;
        
        this.previousValidSelectionIds = limitedIds;
        this.selectedRecordCount = 20;
    } else {
        // Manual Scenario: Show error for 26th record
        this._showToastMessage('Error', 'Manual selection is limited to 20 records.', 'error');

        // Reset to previous state
        this.template.querySelector('lightning-datatable').selectedRows = this.previousValidSelectionIds;
    }
    return;
}

// Standard valid selection
this.previousValidSelectionIds = selectedIds;
this.selectedRecordCount = selectedIds.length;
}


_showToastMessage(title, message, type) {
    const toastEvt = new ShowToastEvent({
        title: title,
        message: message,
        variant: type,
        mode: 'dismissible'
    });
    this.dispatchEvent(toastEvt);
};


}